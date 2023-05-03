using EasyJobsBase
using Documenter

DocMeta.setdocmeta!(EasyJobsBase, :DocTestSetup, :(using EasyJobsBase); recursive=true)

makedocs(;
    modules=[EasyJobsBase],
    authors="singularitti <singularitti@outlook.com> and contributors",
    repo="https://github.com/MineralsCloud/EasyJobsBase.jl/blob/{commit}{path}#{line}",
    sitename="EasyJobsBase.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://MineralsCloud.github.io/EasyJobsBase.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Manual" => [
            "Installation guide" => "installation.md",
        ],
        "Public API" => "public.md",
        "Developer Docs" => [
            "Contributing" => "developers/contributing.md",
            "Style Guide" => "developers/style-guide.md",
            "Design Principles" => "developers/design-principles.md",
        ],
        "Troubleshooting" => "troubleshooting.md",
    ],
)

deploydocs(;
    repo="github.com/MineralsCloud/EasyJobsBase.jl",
    devbranch="main",
)
