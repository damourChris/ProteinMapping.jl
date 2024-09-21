using ProteinMapping
using Documenter

DocMeta.setdocmeta!(ProteinMapping, :DocTestSetup, :(using ProteinMapping); recursive=true)

makedocs(;
    modules=[ProteinMapping],
    authors="Chris Damour",
    sitename="ProteinMapping.jl",
    format=Documenter.HTML(;
        canonical="https://damourChris.github.io/ProteinMapping.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/damourChris/ProteinMapping.jl",
    devbranch="main",
)
