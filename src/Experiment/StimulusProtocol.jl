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
struct Flash <: Stimulus
    intensity::Real #The flash intensity of the flash
end
Flash() = Flash(0.0)

"""
    StimulusProtocol{T}

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

"""
mutable struct StimulusProtocol{T}
    type::Stimulus
    channelName::Union{String,Int64}
    timestamps::Vector{Tuple{T,T}}
end

StimulusProtocol() = StimulusProtocol(Flash(), "Nothing", [(0.0, 0.0)])
StimulusProtocol(stimulus_channel::String) = StimulusProtocol(Flash(), stimulus_channel, [(0.0, 0.0)])
StimulusProtocol(swp::Int64) = StimulusProtocol(Flash(), "Nothing", fill((0.0, 0.0), swp))
StimulusProtocol(stimulus_channel::String, swp::Int64) = StimulusProtocol(Flash(), stimulus_channel, fill((0.0, 0.0), swp))

getindex(stimulus_protocol::StimulusProtocol{T}, inds...) where T <: Real = stimulus_protocol.timestamps[inds...]
function setindex!(stimulus_protocol::StimulusProtocol{T}, X, I...) where T <: Real 
     #println(X)
     stimulus_protocol.timestamps[I...] = X
end

#Initialize an empty stimulus protocol

"""
    extractStimulus(abfInfo::Dict{String, Any}; stimulus_name::String="IN 7", stimulus_threshold::Float64=2.5)
    extractStimulus(abf_path::String; kwargs...)

Extract the stimulus information from the given `abfInfo` dictionary and returns a `StimulusProtocol` object containing stimulus timestamps.

# Arguments
- `abfInfo`: A dictionary containing information about the physiological data.
- `stimulus_name`: (Optional) The name of the stimulus channel. Default is "IN 7".
- `stimulus_threshold`: (Optional) The threshold for detecting stimulus events in the waveform. Default is 2.5.

# Returns
- A `StimulusProtocol` object containing the stimulus timestamps for each sweep.

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

    # Instantiate a StimulusProtocol object with the provided stimulus_name and the number of sweeps
    num_sweeps = size(abfInfo["data"], 1)
    stimuli = StimulusProtocol(stimulus_name, num_sweeps)

    # Iterate over the sweeps
    for swp in axes(abfInfo["data"], 1)
        # Get the stimulus waveform for the current sweep and apply the threshold
        stim_wave = stimulus_waveform[swp, :, 1] .> stimulus_threshold

        # Find the start and end timestamps of the stimulus event in the current sweep
        start_time = findfirst(stim_wave) * dt
        end_time = (findlast(stim_wave) + 1) * dt

        # Update the StimulusProtocol object with the timestamps for the current sweep
        stimuli[swp] = (start_time, end_time)
    end

    return stimuli
end

extractStimulus(abf_path::String; kwargs...) = extractStimulus(readABFInfo(abf_path); kwargs...)

size(stimulus::StimulusProtocol) = size(stimulus.timestamps)

size(stimulus::StimulusProtocol, dim::Int64) = size(stimulus.timestamps, dim)

length(stimulus::StimulusProtocol) = size(stimulus, 1)

push!(stimulus::StimulusProtocol, ts) = push!(stimulus.timestamps, ts)

push!(stimulusA::StimulusProtocol, stimulusB::StimulusProtocol) = push!(stimulusA, stimulusB.timestamps...)