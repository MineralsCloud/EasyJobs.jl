using EasyJobs
using Documenter

DocMeta.setdocmeta!(EasyJobs, :DocTestSetup, :(using EasyJobs); recursive=true)

makedocs(;
    modules=[EasyJobs],
    authors="singularitti <singularitti@outlook.com> and contributors",
    repo="https://github.com/MineralsCloud/EasyJobs.jl/blob/{commit}{path}#{line}",
    sitename="EasyJobs.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://MineralsCloud.github.io/EasyJobs.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=["Home" => "index.md"],
)

deploydocs(; repo="github.com/MineralsCloud/EasyJobs.jl", devbranch="main")
