"""
    Stimulus

An abstract type representing a stimulus in a physiological experiment.

Subtypes of `Stimulus` should implement specific stimulus types and their corresponding parameters.
"""
abstract type Stimulus end

"""
    Flash <: Stimulus

A `Flash` is a subtype of `Stimulus` representing a flash stimulus in a physiological experiment.

## Fields

- `intensity`: A `Real` value indicating the intensity of the flash.

## Constructors

- `Flash()`: Creates a default `Flash` object with an intensity of 0.0.
- `Flash(intensity::Real)`: Creates a `Flash` object with the specified `intensity`.

"""
mutable struct Flash <: Stimulus
    intensity::Real #The flash intensity of the flash
end
Flash() = Flash(0.0)

import Base.string
string(flash::Flash) = "flash"

setIntensity(flash::Flash, val::T) where T <: Real = flash.intensity = val

"""
    StimulusProtocol{T, S} where {T <: Real, S <: Stimulus}

A mutable struct representing a stimulus protocol for physiological data.

## Fields

- `type`: A `Stimulus` object describing the type of stimulus applied during the experiment.
- `channelName`: A `Union{String, Int64}` representing the name or number of the channel where the stimulus is applied.
- `timestamps`: A `Vector{Tuple{T, T}}` storing the start and end timestamps of the stimulus events.

## Constructors

- `StimulusProtocol()`: Creates a default `StimulusProtocol` object with `Flash()` stimulus, "Nothing" channel, and a single (0.0, 0.0) timestamp.
- `StimulusProtocol(stimulus_channel::String)`: Creates a `StimulusProtocol` object with `Flash()` stimulus, the provided `stimulus_channel`, and a single (0.0, 0.0) timestamp.
- `StimulusProtocol(swp::Int64)`: Creates a `StimulusProtocol` object with `Flash()` stimulus, "Nothing" channel, and `swp` number of (0.0, 0.0) timestamps.
- `StimulusProtocol(stimulus_channel::String, swp::Int64)`: Creates a `StimulusProtocol` object with `Flash()` stimulus, the provided `stimulus_channel`, and `swp` number of (0.0, 0.0) timestamps.

## Examples

```julia
stim1 = StimululsProtocol()
stim_channel = StimulusProtocol("IN 3")
stim_sweep = StimulusProtocol(3)
stim_sweep_channel = StimululsProtocol(3, "IN 3")
stim_tstamp = StimululsProtocol((0.0, 0.01))
stim_type_time_channel = StimulusProtocol(Flash(), "IN 3", (0.00, 0.01))
```
"""
mutable struct StimulusProtocol{T, S}
    type::Vector{S}
    channelName::Union{Vector{String},Vector{Int64}} #We might need to change this to a vector
    timestamps::Vector{Tuple{T,T}}
end

StimulusProtocol() = StimulusProtocol([Flash()], ["Nothing"], [(0.0, 0.0)])
StimulusProtocol(stimulus_channel::String) = StimulusProtocol([Flash()], [stimulus_channel], [(0.0, 0.0)])
StimulusProtocol(n_swp::Int64) = StimulusProtocol(fill(Flash(), n_swp), fill("Nothing",n_swp), fill((0.0, 0.0), n_swp))
StimulusProtocol(stimulus_channel::String, n_swp::Int64) = StimulusProtocol(fill(Flash(), n_swp), fill(stimulus_channel, n_swp), fill((0.0, 0.0), n_swp))
StimulusProtocol(timestamps::Tuple) = StimulusProtocol([Flash()], ["Nothing"], [timestamps])
StimulusProtocol(type::S, channelName::Union{String,Int64}, timestamps::Tuple{T,T}) where {T<:Real,S} = StimulusProtocol([type], [channelName], [timestamps])

function getindex(stimulus_protocol::StimulusProtocol{T}, inds...) where T <: Real 
    stim_type = stimulus_protocol.type[inds...]
    stim_channel = stimulus_protocol.channelName[inds...]
    stim_timestamps = stimulus_protocol.timestamps[inds...]
    if isa(stim_timestamps, Vector)
        return StimulusProtocol(
            stim_type,
            stim_channel,
            stim_timestamps
        )
    elseif isa(stim_timestamps, Tuple{T, T})
        return StimulusProtocol(
            [stim_type],
            [stim_channel],
            [stim_timestamps]
        )
    end
end

function setindex!(stimulus_protocol::StimulusProtocol{T}, X::Tuple, I...) where T <: Real 
     stimulus_protocol.timestamps[I...] = X
end

function setindex!(stimulus_protocol::StimulusProtocol{T}, X::Union{String, Int64}, I...) where T <: Real 
    stimulus_protocol.channelName[I...] = X
end

function setindex!(stimulus_protocol::StimulusProtocol{T}, X::Stimulus, I...) where T <: Real 
    stimulus_protocol.type[I...] = X
end
#If you have a list of photon amounts, you can set the intensity of every stimulus
"""
    setIntensity(stimulus_protocols::StimulusProtocol{T, Flash}, photons::Vector{T}) where T<:Real
    setIntensity(stimulus_protocols::StimulusProtocol{T, Flash}, photon::T) where T<:Real

This allows the intensity of the stimulus protocol (or multiple stimulus protocols be set). 

## Arguments

- `stimulus_protocol::StimulusProtocol{T, S} where S <: Flash`: A stimulus protocol 
- `photons::Vector`: a vector of numbers representing the photon amount. 

# Examples
```julia

```
"""
function setIntensity(stimulus_protocols::StimulusProtocol{T, Flash}, photons::Vector{T}) where T<:Real
    @assert size(stimulus_protocols) == size(photons)
    for (idx, photon) in enumerate(photons)
        setIntensity(stimulus_protocols.type[idx], photon)
    end
end

function setIntensity(stimulus_protocols::StimulusProtocol{T, Flash}, photon::T) where T<:Real
    photons = fill(photon, size(stimulus_protocols))
    setIntensity(stimulus_protocols, photons)
end
"""
    setIntensity(stimulus_protocols::StimulusProtocol{T, Flash}, photons::Vector)

This allows the intensity of the stimulus protocol (or multiple stimulus protocols be set). 

## Arguments

- `stimulus_protocol::StimulusProtocol{T, S} where S <: Flash`: A stimulus protocol 
- `photons::Vector`: a vector of numbers representing the photon amount. 
"""
function getIntensity(stimulus_protocols::StimulusProtocol{T, Flash}) where T<:Real
    photon_list = T[]
    for stimulus in stimulus_protocols
        push!(photon_list, stimulus.type[1].intensity)
    end
    return photon_list
end

"""
    extractStimulus(abfInfo::Dict{String, Any}; stimulus_name::String="IN 7", stimulus_threshold::Float64=2.5)
    extractStimulus(abf_path::String; kwargs...)

Extract the stimulus information from the given `abfInfo` dictionary and returns a `StimulusProtocol` object containing stimulus timestamps.

# Arguments
- `abfInfo`: A dictionary containing information about the physiological data.
- `stimulus_name`: (Optional) The name of the stimulus channel. Default is "IN 7".
- `stimulus_threshold`: (Optional) The threshold for detecting stimulus events in the waveform. Default is 2.5.

# Returns
- A `StimulusProtocol` object containing the stimulus timestamps for each trial.

# Examples
```julia
abfInfo = loadABF("path/to/abf/file")
stimuli = extractStimulus(abfInfo)
```

```julia
stimuli = extractStimulus("path/to/abf/file")
```
"""
function extractStimulus(abfInfo::Dict{String,Any};
    stimulus_name::String="IN 7",
    stimulus_threshold::Float64=2.5)
    # Get the time interval between data points
    dt = abfInfo["dataSecPerPoint"]

    # Get the stimulus waveform for the given stimulus_name
    stimulus_waveform = getWaveform(abfInfo, stimulus_name)

    # Instantiate a StimulusProtocol object with the provided stimulus_name and the number of trials
    num_trials = size(abfInfo["data"], 1)
    stimuli = StimulusProtocol(stimulus_name, num_trials)

    # Iterate over the trials
    for swp in axes(abfInfo["data"], 1)
        # Get the stimulus waveform for the current trial and apply the threshold
        stim_wave = stimulus_waveform[swp, :, 1] .> stimulus_threshold

        # Find the start and end timestamps of the stimulus event in the current trial
        start_time = findfirst(stim_wave) * dt
        end_time = (findlast(stim_wave) + 1) * dt

        # Update the StimulusProtocol object with the timestamps for the current trial
        stimuli[swp] = (start_time, end_time)
    end

    return stimuli
end

extractStimulus(abf_path::String; kwargs...) = extractStimulus(readABFInfo(abf_path); kwargs...)

size(stimulus::StimulusProtocol) = size(stimulus.timestamps)

size(stimulus::StimulusProtocol, dim::Int64) = size(stimulus.timestamps, dim)

length(stimulus::StimulusProtocol) = size(stimulus, 1)

function push!(stimulusA::StimulusProtocol, stimulusB::StimulusProtocol)
    push!(stimulusA.timestamps, stimulusB.timestamps...)
    push!(stimulusA.channelName, stimulusB.channelName...)
    push!(stimulusA.type, stimulusB.type...)
end

function push!(stimulus::StimulusProtocol, ts::Tuple)
    newStim = StimulusProtocol(ts)
    println(newStim)
    push!(stimulus, newStim)
end


import Base.iterate
iterate(protocol::StimulusProtocol) = (protocol[1], 2)
function iterate(protocol::StimulusProtocol, state)
    if length(protocol) == state-1
        return nothing
    else
        return (protocol[state], state+1)
    end
end

import DataFrames.DataFrame
function DataFrame(protocol::StimulusProtocol{T}) where T <: Real
    StimulusDF = DataFrame(Type = String[], Intensity = T[], Channel = String[], TimeStart = T[], TimeEnd = T[])
    for stimulus in protocol
        #println(stimulus)
        push!(StimulusDF, (
            Type = string(stimulus.type[1]),
            Intensity = stimulus.type[1].intensity,
            Channel = stimulus.channelName[1], 
            TimeStart = stimulus.timestamps[1][1], 
            TimeEnd = stimulus.timestamps[1][2]        
            )
        )
    end
    return StimulusDF
end