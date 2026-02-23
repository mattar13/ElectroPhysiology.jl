# Installation

## Recommended: Use a Dedicated Environment

Using a dedicated environment avoids dependency conflicts.

```julia
using Pkg
Pkg.activate("Analysis")
```

Run `Pkg.activate("Analysis")` each session before loading packages.

## Install ElectroPhysiology.jl

```julia
using Pkg
Pkg.add("ElectroPhysiology")
```

## Optional Companion Packages

```julia
using Pkg
Pkg.add("PhysiologyAnalysis")
Pkg.add("PhysiologyPlotting")
```

See also: [Tutorial](tutorial.md), [API Reference](API.md).
