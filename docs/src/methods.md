# Methods

## ElectroPhysiology Methods

### Structs
```@docs
Experiment{T}
```

### Functions
```@docs
pad(trace::Experiment{T}, n_add::Int64; position::Symbol=:post, val::T=0.0) where {T <: Real}
```

## PhysiologyAnalysis Methods
