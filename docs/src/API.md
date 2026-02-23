# ElectroPhysiology.jl API Reference

This page documents the API as it exists in the current source tree.
It is organized around the symbols exported from `src/ElectroPhysiology.jl`,
with a few important non-exported constructors/types included where needed.

## API Scope

- `using ElectroPhysiology` exposes the core Experiment, ABF, stimulus, image, and ROI workflow APIs.
- Several legacy/optional readers and filtering utilities exist in `src/Filtering` and optional reader files, but are not loaded by default in the current module initialization path.
- This reference focuses on the default loaded API first, then calls out caveats.

## Core Types

### `Experiment{FORMAT,T}`

Primary container for physiology data:

- `HeaderDict::Dict{String,Any}`
- `dt::T`
- `t::Vector{T}`
- `data_array::Array{T,3}` (`trial x time x channel`)
- `chNames::Vector{String}`
- `chUnits::Vector{String}`
- `chGains::Vector{T}`

Primary constructors in source:

```julia
Experiment(FORMAT::Type, HeaderDict::Dict{String,Any},
           dt::T, t::Vector{T}, data_array::Array{T,3},
           chNames::Vector{String}, chUnits::Vector{String}, chGains::Vector{T}) where T<:Real

Experiment(HeaderDict::Dict{String,Any},
           dt::T, t::Vector{T}, data_array::Array{T,3},
           chNames::Vector{String}, chUnits::Vector{String}, chGains::Vector{T}) where T<:Real

Experiment(FORMAT::Type, data_array::AbstractArray{T}; data_idx=2) where T<:Real
Experiment(data_array::AbstractArray{T}; data_idx=2) where T<:Real
```

Example:

```julia
arr = rand(4, 2000, 2)
exp = Experiment(arr)
```

### Stimulus Types

```julia
abstract type Stimulus end
mutable struct Flash <: Stimulus
    intensity::Real
end
```

### `StimulusProtocol{T,S}`

```julia
mutable struct StimulusProtocol{T,S}
    type::S
    channelName::String
    sweeps::Vector{Int64}
    timestamps::Vector{Tuple{T,T}}
end
```

Constructor forms defined in source:

```julia
StimulusProtocol()
StimulusProtocol(stimulus_channel::String)
StimulusProtocol(n_swp::Int64)
StimulusProtocol(timestamps::Tuple)
StimulusProtocol(type::S, channelName::Union{String,Int64}, timestamps::Tuple{T,T}) where {T<:Real,S}
```

## Base Overloads

### `Experiment` overloads

- `size(exp)`, `size(exp, dim)`
- `axes(exp, dim)`
- `length(exp)` (time axis length)
- `getindex(exp, ...)`
- `setindex!(exp, value, ...)`
- `sum(exp; kwargs...)`
- `mean(exp; dims=2)`
- `std(exp; kwargs...)`
- `minimum(exp; kwargs...)`
- `maximum(exp; kwargs...)`
- `cumsum(exp; kwargs...)`
- `argmin(exp; dims=2)`
- `argmax(exp; dims=2)`
- `abs(exp)`
- `reverse(exp; kwargs...)`, `reverse!(exp; kwargs...)`
- Arithmetic with scalars and experiments: `+`, `-`, `*`, `/`

Typical usage:

```julia
v = exp[1, :, 1]
exp[1, 1:100, 1] .= 0.0
m = mean(exp, dims=1)
```

### `StimulusProtocol` overloads

- `size(stim)`, `size(stim, dim)`
- `length(stim)`
- `getindex(stim, ind::Int64)`
- `getindex(stim, inds...)`
- `setindex!(stim, ...)`
- `push!(stim, ...)`
- `iterate(stim)`

## Exported API

### Metadata and Utilities

#### `getSampleFreq`

```julia
getSampleFreq(exp::Experiment)
```

Returns `1 / exp.dt`.

#### `capabilies`

`capabilies::Vector{Symbol}` is an exported module-level variable used to track optional capability loading state.

#### `std`, `mean`, `abs`

Exported overloads for `Experiment`.

### Stimulus Protocol API

#### Construction and extraction

```julia
extractStimulus(abfInfo::Dict{String,Any}, stimulus_name::String; stimulus_threshold::Float64=2.5)
extractStimulus(abf_path::String, stimulus_name::String; flatten_episodic=false, kwargs...)
```

Usage:

```julia
exp = readABF("file.abf", stimulus_name="IN 7")
stim = getStimulusProtocol(exp)
```

#### Accessors

```julia
getStimulusProtocol(exp::Experiment)
getStimulusStartTime(stimulus::StimulusProtocol)
getStimulusStartTime(exp::Experiment)
getStimulusEndTime(stimulus::StimulusProtocol)
getStimulusEndTime(exp::Experiment)
getStimulusStartIndex(exp::Experiment)
getStimulusEndIndex(exp::Experiment)
find_stim_index(exp; trial=1, channel=3, thresh=2.5, movement=:increase)
```

#### Intensity

```julia
setIntensity(stimulus_protocols::StimulusProtocol{T,Flash}, photons::Vector{T}) where T<:Real
setIntensity(stimulus_protocols::StimulusProtocol{T,Flash}, photon::T) where T<:Real
setIntensity(exp::Experiment, photons)

getIntensity(stimulus_protocols::StimulusProtocol{T,Flash}) where T<:Real
getIntensity(exp::Experiment)
```

#### Mutation and transfer

```julia
addStimulus!(exp::Experiment, protocol::StimulusProtocol)
addStimulus!(exp::Experiment, protocol_fn::String, stim_channel::String; align_timestamps=true, kwargs...)
addStimulus!(exp::Experiment, stim_channel::String; kwargs...)
addStimulus!(target_exp::Experiment, source_exp::Experiment, source_channel; threshold::Real=2.5, channel_name::String="Converted Stimulus")

spike_train_group!(stim_protocol::StimulusProtocol{T,S}, group_time) where {T<:Real,S}
spike_train_group!(exp::Experiment, group_time)
```

### Experiment Data Selection API

```julia
getdata(trace::Experiment, trials, timepoints, channels::Union{String,Vector{String}})
getdata(trace::Experiment, trials, timepoints, channels; verbose=false)

getchannel(trace::Experiment, ch_idx::Int64; verbose=false)
getchannel(trace::Experiment, ch_idxs::Vector{Int64}; kwargs...)
getchannel(trace::Experiment, ch_name::Union{String,Vector{String}}; kwargs...)

eachchannel(trace::Experiment; verbose=false)
eachtrial(trace::Experiment)
```

Usage:

```julia
ch1 = getchannel(exp, 1)
swp_iter = eachtrial(exp)
```

### Experiment Modification API

```julia
scaleby!(data::Experiment{F,T}, val::T) where {F,T<:Real}
scaleby!(data::Experiment{F,T}, val::Vector{T}) where {F,T<:Real}
scaleby(data::Experiment{F,T}, val) where {F,T<:Real}

pad(trace::Experiment{F,T}, n_add::Int64; position::Symbol=:post, val::T=0.0) where {F,T<:Real}
pad!(trace::Experiment{F,T}, n_add::Int64; position::Symbol=:post, val::T=0.0) where {F,T<:Real}

chop(trace::Experiment{F,T}, n_chop::Int64; position::Symbol=:post) where {F,T<:Real}
chop!(trace::Experiment{F,T}, n_chop::Int64; position::Symbol=:post) where {F,T<:Real}

drop!(trace::Experiment{F,T}; dim=3, drop_idx=1) where {F,T<:Real}
drop(trace::Experiment{F,T}; kwargs...) where {F,T<:Real}

truncate_data!(trace::Experiment{F,T}, t_begin, t_end; truncate_based_on=:time_range, stimulus_index=1, time_zero=false) where {F,T<:Real}
truncate_data(trace::Experiment{F,T}, t_begin, t_end; kwargs...) where {F,T<:Real}

average_trials(trace::Experiment{F,T}) where {F,T<:Real}
average_trials!(trace::Experiment{F,T}) where {F,T<:Real}

downsample(trace::Experiment{F,T}, sample_rate::T) where {F,T<:Real}
downsample!(trace::Experiment{F,T}, sample_rate::T) where {F,T<:Real}

dyadic_downsample(trace::Experiment{F,T}) where {F,T<:Real}
dyadic_downsample!(trace::Experiment{F,T}) where {F,T<:Real}

baseline_adjust(trace::Experiment{F,T}; kwargs...) where {F,T<:Real}
baseline_adjust!(trace::Experiment{WHOLE_CELL,T}; mode::Symbol=:slope, polyN=1, region=:whole) where {T<:Real}

time_offset!(exp::Experiment{FORMAT,T}, offset::T) where {FORMAT,T<:Real}
time_offset!(exp::Experiment{FORMAT,T}, time_offset::Millisecond) where {FORMAT,T<:Real}
time_offset(exp::Experiment{FORMAT,T}, offset) where {FORMAT,T<:Real}
```

Usage:

```julia
exp2 = downsample(exp, 1000.0)
exp3 = truncate_data(exp2, 0.0, 1.0)
```

### Experiment Joining API

```julia
concat!(exp::Experiment, exp2::Experiment; dims=1, mode=:pad, position::Symbol=:post)
concat(exp::Experiment{T}, exp_add::Experiment{T}; mode::Symbol=:pad, position::Symbol=:post, kwargs...) where {T}
create_signal_waveform!(exp::Experiment, channel::String)
```

### Export API

```julia
writeXLSX(filename::String, data::Experiment; columns=:trials, column_names=:auto, sheets=:channels,
          save_header=true, skips=[...], save_sections=true, save_stimulus=true,
          auto_open=false, verbose=true)
```

### ABF Reader API

```julia
readABF(::Type{T}, FORMAT::Type, abf_data::Union{String,Vector{UInt8}};
        trials::Union{Int64,Vector{Int64}}=-1,
        channels::Union{Int64,String,Vector{String},Nothing}=nothing,
        average_trials::Bool=false,
        stimulus_name::Union{String,Vector{String},Nothing}=nothing,
        stimulus_threshold::T=2.5,
        warn_bad_channel=false,
        flatten_episodic::Bool=false,
        time_unit=:s) where {T<:Real}

readABF(abf_path::Union{String,Vector{UInt8}}; kwargs...)
readABF(filenames::AbstractArray{String}; average_trials_inner=true, sort_by_date=true, kwargs...)

parseABF(super_folder::String; extension::String=".abf")
getABF_datetime(filename)
```

Usage:

```julia
exp = readABF("trace.abf", channels=["IN 0", "IN 1"], stimulus_name="IN 7")
files = parseABF("C:/data")
```

### Image Reader API (Two-Photon)

```julia
readImage(::Type{T}, filename; chName="CalBryte590", chUnit="px", chGain=1.0,
          objective=60, verbose=false, deinterleave=false) where T<:Real
readImage(filename; kwargs...)

get_frame(exp::Experiment{TWO_PHOTON,T}, frame::Int64) where T<:Real
get_frame(exp::Experiment{TWO_PHOTON,T}, frames::AbstractArray) where T<:Real
get_all_frames(exp::Experiment{TWO_PHOTON,T}) where T<:Real
getIMG_datetime(filename; timestamp_key="date:create", fmt=dateformat"yyyy-mm-ddTHH:MM:SS")
getIMG_size(data2P::Experiment{TWO_PHOTON,T}) where T<:Real
```

### Image Processing and ROI API

```julia
baseline_median(data::Experiment{FORMAT,T}; kernel_size=51, channel=-1, border="symmetric") where {FORMAT,T<:Real}

deinterleave!(exp::Experiment{TWO_PHOTON,T}; n_channels=2, new_ch_name="Alexa 594", new_ch_unit="px") where T<:Real
project(exp::Experiment{TWO_PHOTON,T}; dims=3) where T<:Real
adjustBC!(exp::Experiment{TWO_PHOTON}; channel=nothing, min_val_y=0.0, max_val_y=1.0,
          std_level=1, min_val_x=:std, max_val_x=:std, contrast=:auto, brightness=:auto, n_vals=10)
bin!(fn, exp::Experiment{TWO_PHOTON}, dims::Tuple{Int,Int,Int})
mapframe!(f, exp::Experiment{TWO_PHOTON,T}, window::Tuple{Int64,Int64}; channel=nothing, border="symmetric") where {T<:Real}
mapframe(f, exp::Experiment{TWO_PHOTON,T}, window::Tuple{Int64,Int64}; kwargs...) where {T<:Real}
mapdata!(f, exp::Experiment{TWO_PHOTON,T}, window::Int64; channel=nothing, border="symmetric") where {T<:Real}
mapdata(f, exp::Experiment{TWO_PHOTON,T}, window::Int64; kwargs...) where {T<:Real}

pixel_splits(image_size::Tuple{Int,Int}, roi_size::Int)
pixel_splits_roi!(exp::Experiment{TWO_PHOTON,T}, roi_size) where T<:Real
make_circular_roi!(exp::Experiment{TWO_PHOTON,T}, center::Tuple{Real,Real}, radius::Real) where T<:Real
recordROI(exp::Experiment{TWO_PHOTON,T}, roi_idxs::Vector{Int64}, label::Int64) where T<:Real
loadROIfn!(fn::String, exp::Experiment{TWO_PHOTON,T}) where T<:Real

getROIindexes(exp::Experiment{TWO_PHOTON,T}, label::Int64) where T<:Real
getROImask(exp::Experiment{TWO_PHOTON,T}, label::Int64; reshape_arr=true) where T<:Real
getROImask(exp::Experiment{TWO_PHOTON,T}; reshape_arr=true) where T<:Real
getROIarr(exp::Experiment{TWO_PHOTON,T}, label::Int64; reshape_arr=false) where T<:Real
getROIarr(exp::Experiment{TWO_PHOTON,T}, labels::Vector{Int64}; reshape_arr=false) where T<:Real
getROIarr(exp::Experiment{TWO_PHOTON,T}; reshape_arr=true) where T<:Real
```

Usage:

```julia
img = readImage("movie.tif")
deinterleave!(img, n_channels=2)
pixel_splits_roi!(img, 16)
roi_trace = getROIarr(img, 1)
```

## Exported Symbol Without Definition

- `find_boutons` is exported from `src/ElectroPhysiology.jl`, but no function definition is present in `src/`.

## Non-exported but Commonly Useful Functions

Accessible as `ElectroPhysiology.<name>`:

- `getChannelNames(exp)`
- `getChannelUnite(exp)`
- `getGains(exp)`
- `getRealTime(exp)`

## Optional/Legacy APIs (Not Loaded by Default Path)

The following source files define useful APIs but are currently behind the `OLD__init__` or not included from the module entrypoint:

- `readXLSX` (`src/Readers/XLSReader.jl`)
- `readMAT` (`src/Readers/MATReader/MATReader.jl`)
- `cwt_filter`, `cwt_filter!`, `dwt_filter`, `dwt_filter!` (`src/Filtering/wavelet_filtering.jl`)
- Additional filtering helpers in `src/Filtering/filtering.jl` and `src/Filtering/filteringPipelines.jl`

If you intend to make these public/stable, prefer moving their includes/exports into the normal module load path.

## Source-of-Truth

The authoritative API definitions are in:

- `src/ElectroPhysiology.jl`
- `src/Experiment/*.jl`
- `src/Stimulus/StimulusProtocol.jl`
- `src/Readers/ABFReader/*.jl`
- `src/Readers/ImageReader/ImageReader.jl`
- `src/ImageMorphology/*.jl`
