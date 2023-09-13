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

## PhysiologyAnalysis methods

```@docs
calculate_threshold(x::Array{T, N}; Z = 4.0, dims = -1) where {T <: Real, N}
```

## PhysiologyPlotting methods

To load PyPlot as a backend, export it with 
```
using PhysiologyPlotting
using PyPlot
```

```@docs
plot_experiment(axis::T, exp::Experiment;
    channels=1, sweeps = :all, 
    yaxes=true, xaxes=true, #Change this, this is confusing
    xlims = nothing, ylims = nothing,
    color = :black, cvals = nothing, clims = (0.0, 1.0), #still want to figure out how this wil work
    ylabel = nothing, xlabel = nothing,
    linewidth = 1.0, 
    kwargs...
) where T
```