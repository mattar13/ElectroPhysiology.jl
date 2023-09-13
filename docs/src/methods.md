# Methods

## ElectroPhysiology Methods


```
using ElectroPhysiology
```
These methods become available after this command is run.

### Stimulus Protocols

```@docs
StimulusProtocol{T, S}
```

```@docs
extractStimulus
```

```@docs
setIntensity
```

```@docs
getIntensity
```

### Structs
```@docs
Experiment{T}
```

### Functions
```@docs
pad(trace::Experiment{T}, n_add::Int64; position::Symbol=:post, val::T=0.0) where {T <: Real}
```

## PhysiologyAnalysis Methods

These methods only become available after 
```
using PhysiologyAnalysis
```
is run.

## PhysiologyPlotting Methods

These methods only become available after 
```
using PhysiologyPlotting
```
is run.


To load PyPlot as a backend, export it with 
```
using PhysiologyPlotting
using PyPlot
```

To load GLMakie or CairoMakie as a backend, export it with 
```
using PhysiologyPlotting, 
using GLMakie
```

or 

```
using PhysiologyPlotting, 
using CairoMakie
```