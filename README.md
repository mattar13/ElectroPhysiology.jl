# ElectroPhysiology.jl

[![License][license-img]](LICENSE)

[![][docs-stable-img]][docs-stable-url] 

[![][GHA-img]][GHA-url]

[license-img]: http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat-square
[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://mattar13.github.io/ElectroPhysiology.jl/dev

[GHA-img]: https://github.com/mattar13/ElectroPhysiology.jl/workflows/CI/badge.svg
[GHA-url]: https://github.com/mattar13/ElectroPhysiology.jl/actions?query=workflows/CI

## Overview

ElectroPhysiology.jl is the core data layer for electrophysiology workflows in Julia.
It provides:

- File readers for ABF and two-photon image stacks
- A shared `Experiment` container (`trial x time x channel`)
- Stimulus protocol extraction and attachment
- Core trial/time/channel manipulation utilities
- ROI and image utility methods for two-photon data

## Installation

Install from the Julia REPL:

```julia
using Pkg
Pkg.add("ElectroPhysiology")
```

Or in package mode:

```julia
pkg> add ElectroPhysiology
```

## Quick Start

### Read ABF data

```julia
using ElectroPhysiology

exp = readABF("example.abf"; stimulus_name = "IN 7")
println(size(exp))       # (n_trials, n_timepoints, n_channels)
println(getSampleFreq(exp))
```

### Basic processing

```julia
exp2 = downsample(exp, 1000.0)
exp3 = truncate_data(exp2, 0.0, 1.0)
avg = average_trials(exp3)
```

### Two-photon workflow

```julia
img = readImage("stack.tif")
deinterleave!(img, n_channels = 2)
pixel_splits_roi!(img, 16)
roi = getROIarr(img, 1)
```

## Related Packages

This package is part of a larger ecosystem of physiology-related packages:

### PhysiologyAnalysis.jl
A package for advanced analysis of physiological data. See documentation [here](https://github.com/mattar13/PhysiologyAnalysis.jl)

### PhysiologyPlotting.jl
A package for creating publication-quality plots of physiological data. See documentation [here](https://github.com/mattar13/PhysiologyPlotting.jl)

## Documentation

- Package docs: [mattar13.github.io/ElectroPhysiology.jl/dev](https://mattar13.github.io/ElectroPhysiology.jl/dev)
- API reference (source-aligned): `docs/src/API.md`

## Development

### Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Building Documentation

To build the documentation locally:
```julia
cd("docs")
using Pkg
Pkg.activate(".")
Pkg.instantiate()
include("make.jl")
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
