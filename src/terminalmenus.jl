import REPL
using REPL.TerminalMenus

mutable struct Dialog
    selected::String
end
Dialog() = Dialog("")
function TerminalMenus.RadioMenu(options::Vector{String}, default::Int)
    m = RadioMenu(options)
    m.selected = default
    m
end
function TerminalMenus.MultiSelectMenu(options::Vector{String}, default::Set{Int})
    m = MultiSelectMenu(options)
    m.selected = default
    m
end
function simulateInput(n)
    for _ in 1:n-1
        write(stdin.buffer, "\e[B")
    end
end
function requestᵐ(msg::AbstractString, m::RadioMenu)
    simulateInput(m.selected)
    request(msg, m)
end
function requestᵐ(msg::AbstractString, m::MultiSelectMenu)
    simulateInput(reduce(min, m.selected))
    request(msg, m)
end
function TerminalMenus.request(msg::String, m::Dialog)
    println(msg)
    println("[there is no default]")
    strip(readline())
end
function requestᵐ(msg::String, m::Dialog)
    println(msg)
    println("[Enter for default, or type new value]")
    println("default> ", m.selected)
    ans = strip(readline())
    if !isempty(ans)
        m.selected = ans
    end
    return m.selected
end
