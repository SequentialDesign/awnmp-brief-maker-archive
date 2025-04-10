include("util.jl")

struct LexToken <: Node
    startpos::Vector{Tuple{Int, Int}}  # (line_number, current x)  # it's a vector for constants, so that it write the position of the constants, and where in the contant too
                                       # with (x₁, x₂, ..., xₙ) being the position of x₁ being the outer most scope, and xₙ being the most nested into constants
    keyword::Bool # return true if it's a keyword, false otherwise
    s::String
end

function _slex(s::String)
    V = LexToken[]
    do_write::Bool = true
    i = 1
    x = 1
    line = 1
    while i <= lastindex(s)
        pos = (line, x)
        c = s[i]
        if !do_write
            if c == '\n'
                line += 1
                x = 0
            end
            do_write = (c == TOK_CMT)
        elseif isspace(c)
            if (c) == '\n'
                line += 1
                x = 0
            end
        elseif c == TOK_DQ
            i = nextind(s, i)
            buffer_str = IOBuffer()
            while i <= lastindex(s) && s[i] != TOK_DQ
                if c == '\n'
                    line += 1
                    x = 0
                end
                if s[i] == '\\'
                    i = nextind(s, i)
                    write(buffer_str, eval(Meta.parse("\"\\$(s[i])\"")))
                else
                    write(buffer_str, s[i])
                end
                x += 1
                i = nextind(s, i)
            end
            sw = buffer_str |> take! |> String
            push!(V, LexToken([pos], false, sw))
            @goto CONT
        elseif c == TOK_CMT
            do_write = false
        elseif c == TOK_DL
            i = nextind(s, i)
            buffer_str = IOBuffer()
            while i <= lastindex(s) && s[i] != TOK_DL
                if c == '\n'
                    line += 1
                    x = 0
                end
                if s[i] == '\\'
                    i = nextind(s, i)
                    write(buffer_str, eval(Meta.parse("\"\\$(s[i])\"")))
                else
                    write(buffer_str, s[i])
                end
                x += 1
                i = nextind(s, i)
            end
            V2 = ("CONST." * take!(take!(buffer_str)) |> Meta.parse |> eval |> _slex)
            V2 = V2 .|> (x -> pushfirst!(x.pos, pos))
            append!(V, V2)
            @goto CONT
        elseif c in TOKENS
            push!(V, LexToken([pos], true, "$c"))
        else
            word = IOBuffer()
            while i <= lastindex(s) && !(isspace(s[i]) || s[i] in TOKENS)
                write(word, s[i])
                i = nextind(s, i)
                x += 1
            end
            sw = word |> take! |> String
            push!(V, LexToken([pos], false, sw))
            continue
        end
        @label CONT
        x += 1
        i = nextind(s, i)
    end
    V
end

function slex(s::String)
	t = time()
	println(stderr, "starting lexing")
	r = _slex(s)
	println(stderr, "ended lexing in $(time()-t)s")
	return r
end
