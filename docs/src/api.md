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

### Experiment readers

```@docs
readABF(::Type{T}, abf_data::Union{String,Vector{UInt8}};
    trials::Union{Int64,Vector{Int64}}=-1,
    channels::Union{Int64, String, Vector{String}}=["Vm_prime", "Vm_prime4"],
    average_trials::Bool=false,
    stimulus_name::Union{String, Vector{String}, Nothing}="IN 7",  #One of the best places to store digital stimuli
    stimulus_threshold::T=2.5, #This is the normal voltage rating on digital stimuli
    warn_bad_channel=false, #This will warn if a channel is improper
    flatten_episodic::Bool=false, #If the stimulation is episodic and you want it to be continuous
    time_unit=:s, #The time unit is s, change to ms
) where {T<:Real}
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