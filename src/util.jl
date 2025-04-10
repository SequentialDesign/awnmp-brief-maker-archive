include("logic.jl")

module FUNC
    include("funcs.jl")
end

module CONST
    include("const.jl")
end

function pos_to_string(pos)
    str = IOBuffer()
    write(str, join(pos .|> p -> "x: $(p[2]), line: $(p[1])"), " inside ")
    str |> take! |> String
end

function closing(v, i, opening, closing, pos)
    depth = 0
    len = length(v)
    while i <= len
        c = v[i]
        if kval(c, opening)
            depth += 1
        elseif kval(c, closing)
            if depth == 0
                return i
            else
                depth -= 1
            end
        end
        i += 1
    end
    throw("Can't find $closing to $opening at $(pos_to_string(pos))")
end

const TOK_LP = '('
const TOK_RP = ')'
const TOK_RC = '{'
const TOK_LC = '}'
const TOK_OR = '|'
const TOK_SEP = ','
const TOK_ASSIGN = ':'
const TOK_PLUS = '+'
const TOK_TIME = '*'
const TOK_CMT = '#'
const TOK_DQ = '"'
const TOK_DL = '$'

TOKENS = [TOK_LP, TOK_RP, TOK_RC, TOK_LC, TOK_OR, TOK_SEP, TOK_ASSIGN, TOK_PLUS, TOK_TIME, TOK_CMT, TOK_DQ, TOK_DL]

@enum OP begin
    CONCAT
    REPEAT
    ASSIGN
    OR
end

abstract type Node end

struct BinOp <: Node
    op::OP
    left::Node
    right::Node
end

struct Block <: Node
    require::Logic.LNode
    provide::Vector{Symbol}
    func::Function
    fallback::Function
    val::Node
end

struct Str <: Node
    val::String
end


struct LexToken <: Node
    startpos::Vector{Tuple{Int, Int}}  # (line_number, current x)  # it's a vector for constants, so that it write the position of the constants, and where in the contant too
                                       # with (x₁, x₂, ..., xₙ) being the position of x₁ being the outer most scope, and xₙ being the most nested into constants
    keyword::Bool # return true if it's a keyword, false otherwise
    s::String
end

prettier_print(n) = prettier_print(n, 0)
prettier_print(n, t) = println("  "^t, n)

function prettier_print(n::Node, t)
    for nm in fieldnames(n |> typeof)
        println("  "^t, nm, ':')
        prettier_print(getfield(n, nm), t+1)
    end
end

function kval(tok::LexToken, s) # I think writing "x->lexed[x].s == s && lexed[x]" is error prone, stand for Keyword of Value : ...
    tok.s == s && tok.keyword
end
kval(_, _) = false
kval(s) = Base.Fix2(kval, s)