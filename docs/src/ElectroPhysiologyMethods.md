## ElectroPhysiology Methods


```
using ElectroPhysiology
```
These methods become available after this command is run.

### Stimulus Protocols

```@docs 
Stimulus
```

```@docs
Flash
```

```@docs
StimulusProtocol
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
Experiment
```

### Functions
```@docs
pad(trace::Experiment{T}, n_add::Int64; position::Symbol=:post, val::T=0.0) where {T <: Real}
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