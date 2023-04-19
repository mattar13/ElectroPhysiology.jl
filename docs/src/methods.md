# Methods

## ElectroPhysiology Methods

These methods only become available after 
```
using ElectroPhysiology
```
is run.


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