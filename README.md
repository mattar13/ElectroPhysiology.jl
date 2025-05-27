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

ElectroPhysiology.jl is a comprehensive Julia package for loading, analyzing, and plotting neuroscience and physiology data. It provides a robust framework for handling various types of electrophysiological experiments, including ERG (Electroretinogram), whole-cell recordings, and two-photon imaging data.

## Installation

To install ElectroPhysiology.jl, open the Julia REPL and enter:

```julia
using Pkg
Pkg.add("ElectroPhysiology")
```

Or add it to your project's dependencies:

```julia
pkg> add ElectroPhysiology
```

## Related Packages

This package is part of a larger ecosystem of physiology-related packages:

### PhysiologyAnalysis.jl
A package for advanced analysis of physiological data. See documentation [here](https://github.com/mattar13/PhysiologyAnalysis.jl)

### PhysiologyPlotting.jl
A package for creating publication-quality plots of physiological data. See documentation [here](https://github.com/mattar13/PhysiologyPlotting.jl)

## Basic Usage

```julia
using ElectroPhysiology

# Create a basic experiment
data_array = rand(10, 1000, 2)  # 10 trials, 1000 timepoints, 2 channels
exp = Experiment(data_array)

# Access data
data = exp[1, :, 1]  # Get first trial, all timepoints, first channel

# Basic operations
mean_response = mean(exp, dims=1)  # Average across trials
```

## Features

- Support for multiple experiment types (ERG, Whole-cell, Two-photon)
- Flexible data structure for handling multi-channel recordings
- Built-in functions for common analysis tasks
- Integration with stimulus protocols
- Time series manipulation and analysis
- Channel management and metadata handling

## Development

### Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Building Documentation

To build the documentation locally:

Is the core package for loading, analyzing and plotting neuroscience and physiology data in Julia. 
This package comes with several related packages which can be accessed at the links below. 

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
