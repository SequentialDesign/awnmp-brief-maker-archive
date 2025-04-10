include("SLexer.jl")

RecurseFuncParser(type, a) = a
RecurseFuncParsertype(a, b) = BinOp(type, a, b)
RecurseFuncParser(type, a, b, c...) = BinOp(type, a, RecurseFuncParser(type, b, c...))

function _sparse(lexed)::Node
    isempty(lexed) && return Str("")
    while any(kval("("), lexed)
        new = Node[]
        lpindex = findfirst(kval("("), lexed)
        for i in 1:lpindex-1
            push!(new, lexed[i])
        end
        rpindex = closing(lexed, lpindex+1, "(", ")", lexed[lpindex].startpos)
        if rpindex == (lpindex+1)
            for i in lpindex+1:lastindex(lexed)
                push!(new, lexed[i])
            end
            lexed = new
            continue
        end
        push!(new, _sparse(lexed[lpindex+1:rpindex-1]))
        for i in rpindex+1:lastindex(lexed)
            push!(new, lexed[i])
        end
        lexed = new
    end

    if any(kval(")"), lexed)
        throw("You have too many ')' for not that many '(' at $(lexed[findfirst(kval(")"), lexed)].startpos |> pos_to_string)")
    end

    if any(kval("{"), lexed)
        new = Node[]
        i = 1
        len = length(lexed)
        while i <= len
            v = lexed[i]
            if kval(v, "{")
                found = false
                j = i+1
                while j <= len && !found
                    if kval(lexed[j], "}")
                        if j == len
                            throw("Found closing '}' but has nothing to apply it to at $(lexed[j].startpos |> pos_to_string)")
                        end
                        found = true
                        try 
                            buffer = IOBuffer()
                            for id in (i+1):(j-1)
                                write(buffer, lexed[id].s)
                            end
                            restraint, provide, func, fallback = buffer |>
                                take! |>
                                String |>
                                Base.Fix2(split, ",") .|>
                                String
                            provides = split(provide, "|") .|> String
                            apply_to = lexed[j+1]
                            push!(new, Block(
                            isempty(restraint) ? Logic.FTRUE : Logic.create(restraint),
                            provides == [""] ? Symbol[] : Symbol.(provides),
                            isempty(func) ? FUNC.I : "FUNC."*func |> Meta.parse |> eval,
                            isempty(fallback) ? FUNC.NULL : "FUNC."*fallback |> Meta.parse |> eval,
                            apply_to
                            )
                        )
                        i = j+1
                        catch
                            throw("{...} block misformatted from $(v.startpos |> pos_to_string) to $(lexed[j].startpos |> pos_to_string)")
                        end
                    end
                    j += 1
                end
                if !found
                    throw("Missing closing '}' to opening '{' at $(v.startpos |> pos_to_string)")
                end
            else
                push!(new, v)
            end
            i += 1
        end
        lexed = new
    end

    if any(kval("}"), lexed)
        throw("You have too many '}' for not that many '{' at $(lexed[findfirst(kval("}"), lexed)].startpos |> pos_to_string)")
    end

    if any(kval("|"), lexed)
        bindexes = findall(kval("|"), lexed)
        if length(bindexes) == 1
            return BinOp(OR, _sparse(lexed[1:(bindexes[1]-1)]), _sparse(lexed[(bindexes[1]+1):end]))
        end
        i = bindexes[2]
        node = BinOp(OR, _sparse(lexed[1:bindexes[1]-1]), _sparse(lexed[(bindexes[1]+1):bindexes[2]-1]))
        for index in bindexes[3:end]
            node = BinOp(OR, node, _sparse(lexed[(i+1):(index-1)]))
            i = index
        end
        return BinOp(OR, node, _sparse(lexed[(i+1):end]))
    end
        
    if any(kval(":"), lexed)
        aindex = findfirst(kval(":"), lexed)
        try
            @assert length(findall(kval(":"), lexed)) == 1
        catch
            throw("Multiple ':' found in scope at $(lexed[aindex].startpos |> pos_to_string)")
        end
        return BinOp(ASSIGN, _sparse(lexed[1:aindex-1]), _sparse(lexed[aindex+1:end]))
    end

    if any(kval(","), lexed)
        bindexes = findall(kval(","), lexed)
        if length(bindexes) == 1
            return BinOp(OR, _sparse(lexed[1:(bindexes[1]-1)]), _sparse(lexed[(bindexes[1]+1):end]))
        end
        i = bindexes[2]
        node = BinOp(OR, _sparse(lexed[1:bindexes[1]-1]), _sparse(lexed[(bindexes[1]+1):bindexes[2]-1]))
        for index in bindexes[3:end]
            node = BinOp(OR, node, _sparse(lexed[(i+1):(index-1)]))
            i = index
        end
        return BinOp(OR, node, _sparse(lexed[(i+1):end]))
    end

    isempty(lexed) && return Str("")
    new = Node[]
    for l in lexed
        if l isa LexToken
            push!(new, Str(l.s))
        else
            push!(new, l)
        end
    end

    RecurseFuncParser(CONCAT, new...)
end
function sparse(lexed)
	t = time()
	println(stderr, "starting parsering")
	r = _sparse(lexed)
	println(stderr, "finished parsering in $(time()-t)s")
	return r
end
