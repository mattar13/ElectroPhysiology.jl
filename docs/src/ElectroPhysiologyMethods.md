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

### Signal Processing and Filtering

#### Baseline Correction
The package provides several methods for baseline correction and ΔF/F calculations, particularly useful for fluorescence imaging data.

```@docs
baseline_median
```

```@docs
baseline_als
```

```@docs
baseline_trace
```

```@docs
baseline_stack
```

```@docs
baseline_stack!
```

#### Moving Average Functions
Functions for smoothing data using moving averages.

```@docs
moving_average(::Vector)
```

```@docs
moving_average(::AbstractMatrix)
```

#### Example Usage

```julia
# Compute baseline using median filter
baselines = baseline_median(exp_data, kernel_size=51)

# Apply asymmetric least squares baseline correction
corrected = baseline_als(signal, lam=1e7, p=0.075)

# Compute ΔF/F for a stack of images
dff = baseline_stack(image_stack, window=15)

# Smooth data using moving average
smoothed = moving_average(data, window=31)
```

