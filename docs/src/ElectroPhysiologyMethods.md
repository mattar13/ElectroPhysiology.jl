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

### Image Processing

The package provides several methods for processing two-photon imaging data, including channel manipulation, projection, and filtering operations.

#### Channel Operations
```@docs
deinterleave!(exp::Experiment{TWO_PHOTON, T}; n_channels=2, new_ch_name="Alexa 594", new_ch_unit="px") where T<:Real
```

#### Image Projection and Statistics
```@docs
project(exp::Experiment{TWO_PHOTON, T}; dims=3) where T<:Real
```

#### Brightness and Contrast Adjustment
```@docs
adjustBC!(exp::Experiment{TWO_PHOTON}; channel=nothing, min_val_y=0.0, max_val_y=1.0, std_level=1, min_val_x=:std, max_val_x=:std, contrast=:auto, brightness=:auto, n_vals=10)
```

#### Data Binning
```@docs
bin!(fn, exp::Experiment{TWO_PHOTON}, dims::Tuple{Int, Int, Int})
```

#### Window Operations
```@docs
mapframe!(f, exp::Experiment{TWO_PHOTON, T}, window::Tuple{Int64, Int64}; channel=nothing, border="symmetric") where {T<:Real}
```

```@docs
mapframe(f, exp::Experiment{TWO_PHOTON, T}, window::Tuple{Int64, Int64}; kwargs...) where {T<:Real}
```

#### Example Usage

```julia
# Deinterleave channels in a two-photon experiment
deinterleave!(exp, n_channels=2)

# Project data along a specific dimension
projected_data = project(exp, dims=3)

# Adjust brightness and contrast
adjustBC!(exp, channel=1, min_val_x=:std, max_val_x=:std, std_level=2)

# Bin data using mean function
bin!(mean, exp, (2,2,2))

# Apply a custom function over a window
mapframe!(median, exp, (3,3), channel=1)
```

#### Suggested Reorganization

The current `imfilter!` functionality can be replaced with more specialized functions in DeltaFF.jl:

1. For temporal filtering:
   - Use `baseline_median` for median filtering
   - Use `moving_average` for mean filtering
   - Add new specialized temporal filters as needed

2. For spatial filtering:
   - Move spatial filtering operations to a new module (e.g., `SpatialFilters.jl`)
   - Implement common 2D filters (Gaussian, median, mean) as standalone functions
   - Consider using specialized image processing libraries for complex operations

3. For combined spatiotemporal filtering:
   - Create dedicated functions for specific use cases
   - Use `mapframe!` for custom window operations
   - Implement common operations (e.g., 3D Gaussian) as standalone functions

This reorganization would make the codebase more maintainable and easier to understand, while also providing more specialized and optimized implementations for common operations.

