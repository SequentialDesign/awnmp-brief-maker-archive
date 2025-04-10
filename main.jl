module THINGY  # I'm fed up with namespace, so... yeah...
    include("src/SGenerate.jl")
end

const PATH = raw"./files/before.txt" # put the path of your file there
const TO = raw"./files/after.ahk"  # put where you want it to be written
const REPLACE = true # if `true`, it will replace the file "TO" value instead of appending to it DANGEROUS!!! I'm not keeping any responsability of wrecked dictionary (though, I'll share your sadness)

transform(x) = x |> THINGY.slex |> THINGY.sparse |> THINGY.sgenerate

touch(TO)

open(TO, REPLACE ? "w" : "a") do io
    txt = read(PATH) |> String
    if !REPLACE
        write(io, "\r\n")
    end
    for i in transform(txt)
        write(io, i)
	    write(io, "\r\n")
    end
end

const b = read(TO) == read("./files/ref.ahk")
if b
    println("Test succeed")
else
    throw("The tests aren't successful")
end
