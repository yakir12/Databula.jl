using Documenter, Databula

makedocs(
    modules = [Databula],
    format = :html,
    sitename = "Databula.jl",
    pages = Any["index.md"]
)

deploydocs(
    repo = "github.com/yakir12/Databula.jl.git",
    target = "build",
    julia = "1.0",
    deps = nothing,
    make = nothing,
)
