# EasyJobsBase

|                                 **Documentation**                                  |                                                                                                 **Build Status**                                                                                                 |                                        **Others**                                         |
| :--------------------------------------------------------------------------------: | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: | :---------------------------------------------------------------------------------------: |
| [![Stable][docs-stable-img]][docs-stable-url] [![Dev][docs-dev-img]][docs-dev-url] | [![Build Status][gha-img]][gha-url] [![Build Status][appveyor-img]][appveyor-url] [![Build Status][cirrus-img]][cirrus-url] [![pipeline status][gitlab-img]][gitlab-url] [![Coverage][codecov-img]][codecov-url] | [![GitHub license][license-img]][license-url] [![Code Style: Blue][style-img]][style-url] |

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://MineralsCloud.github.io/EasyJobsBase.jl/stable
[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://MineralsCloud.github.io/EasyJobsBase.jl/dev
[gha-img]: https://github.com/MineralsCloud/EasyJobsBase.jl/workflows/CI/badge.svg
[gha-url]: https://github.com/MineralsCloud/EasyJobsBase.jl/actions
[appveyor-img]: https://ci.appveyor.com/api/projects/status/github/MineralsCloud/EasyJobsBase.jl?svg=true
[appveyor-url]: https://ci.appveyor.com/project/singularitti/EasyJobsBase-jl
[cirrus-img]: https://api.cirrus-ci.com/github/MineralsCloud/EasyJobsBase.jl.svg
[cirrus-url]: https://cirrus-ci.com/github/MineralsCloud/EasyJobsBase.jl
[gitlab-img]: https://gitlab.com/singularitti/EasyJobsBase.jl/badges/main/pipeline.svg
[gitlab-url]: https://gitlab.com/singularitti/EasyJobsBase.jl/-/pipelines
[codecov-img]: https://codecov.io/gh/MineralsCloud/EasyJobsBase.jl/branch/main/graph/badge.svg
[codecov-url]: https://codecov.io/gh/MineralsCloud/EasyJobsBase.jl
[license-img]: https://img.shields.io/github/license/MineralsCloud/EasyJobsBase.jl
[license-url]: https://github.com/MineralsCloud/EasyJobsBase.jl/blob/main/LICENSE
[style-img]: https://img.shields.io/badge/code%20style-blue-4495d1.svg
[style-url]: https://github.com/invenia/BlueStyle

The code is [hosted on GitHub](https://github.com/MineralsCloud/EasyJobsBase.jl),
with some continuous integration services to test its validity.

This repository is created and maintained by [@singularitti](https://github.com/singularitti).
You are very welcome to contribute.

## Installation

The package can be installed with the Julia package manager.
From the Julia REPL, type `]` to enter the Pkg REPL mode and run:

```
pkg> add EasyJobsBase
```

Or, equivalently, via the [`Pkg` API](https://pkgdocs.julialang.org/v1/getting-started/):

```julia
julia> import Pkg; Pkg.add("EasyJobsBase")
```

## Documentation

- [**STABLE**][docs-stable-url] — **documentation of the most recently tagged version.**
- [**DEV**][docs-dev-url] — _documentation of the in-development version._

## Project status

The package is tested against, and being developed for, Julia `1.6` and above on Linux,
macOS, and Windows.

## Questions and contributions

Usage questions can be posted on [our discussion page][discussions-url].

Contributions are very welcome, as are feature requests and suggestions. Please open an
[issue][issues-url] if you encounter any problems. The [contributing](@ref) page has
a few guidelines that should be followed when opening pull requests and contributing code.

[discussions-url]: https://github.com/MineralsCloud/EasyJobsBase.jl/discussions
[issues-url]: https://github.com/MineralsCloud/EasyJobsBase.jl/issues
