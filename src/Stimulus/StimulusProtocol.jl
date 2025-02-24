"""
    Stimulus

An abstract type representing a stimulus in a physiological experiment.

Subtypes of `Stimulus` should implement specific stimulus types and their corresponding parameters.
"""
abstract type Stimulus end #Define an empty Constructors
Stimulus() = Stimulus

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

mutable struct Step <: Stimulus
    amplitude::Real
end

mutable struct Ramp <: Stimulus
    amplitude::Real
    duration::Real
end

mutable struct Puff <: Stimulus
    duration::Real
    agent::String
    concentration::Real
    unit::String
end

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
    type::S
    channelName::String #We might need to change this to a vector
    sweeps::Vector{Int64}
    timestamps::Vector{Tuple{T,T}}
end

StimulusProtocol() = StimulusProtocol(Stimulus(), "Nothing", [(-Inf, Inf)])
StimulusProtocol(stimulus_channel::String) = StimulusProtocol(Stimulus(), stimulus_channel, [1], [(-Inf, Inf)])
StimulusProtocol(n_swp::Int64) = StimulusProtocol(Stimulus(), "Nothing", [1:swp], fill((0.0, 0.0), n_swp), 1:swp)
StimulusProtocol(timestamps::Tuple) = StimulusProtocol(Stimulus(), "Nothing", [1], [timestamps])
StimulusProtocol(type::S, channelName::Union{String,Int64}, timestamps::Tuple{T,T}) where {T<:Real,S} = 
    StimulusProtocol(type, channelName, [1], [timestamps])

function getindex(stimulus_protocol::StimulusProtocol{T}, ind::Int64) where T <: Real 
    idxs = findall(x -> x == ind, stimulus_protocol.sweeps)
    if isempty(idxs)
        throw(ArgumentError("Index $ind not in sweeps $(stimulus_protocol.sweeps)."))
    else
        return stimulus_protocol.timestamps[idxs]
    end
end

function getindex(stimulus_protocol::StimulusProtocol{T}, inds...) where T <: Real
    return map(x -> getindex(stimulus_protocol, x), inds)
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
    extract_events(stim::AbstractVector{<:Number}) -> Vector{Tuple{Int,Int}}

Extracts the start and end indices of stimulus events from a binary stimulus waveform.

A stimulus waveform is represented by a vector of 0s and 1s where 0 indicates no stimulus and 1 indicates 
the presence of a stimulus. An event is defined as a contiguous sequence of 1s. The function detects transitions 
from 0 to 1 (event start) and from 1 to 0 (event end), and returns a vector of tuples containing the start and end 
indices of each event.

# Arguments
- `stim`: A one-dimensional array (or vector) of numbers (typically 0s and 1s) representing the stimulus waveform.

# Returns
- A vector of tuples `(idx_start, idx_end)` where:
  - `idx_start` is the index at which a stimulus event starts (i.e. where the signal transitions from 0 to 1).
  - `idx_end` is the index at which that event ends (i.e. where the signal transitions from 1 to 0).
"""
function extract_events(stim::AbstractVector{<:Number})
    n = length(stim)
    if n == 0
        return Tuple{Int,Int}[]
    end

    # Compute differences between consecutive elements.
    # A value of 1 means a 0→1 transition, and -1 means a 1→0 transition.
    d = diff(stim)
    starts = [i + 1 for i in findall(x -> x == 1, d)]
    ends   = [i for i in findall(x -> x == -1, d)]

    # If the first element is already 1, then the event starts at index 1.
    if stim[1] == 1
        unshift!(starts, 1)
    end

    # If the last element is 1, then the event hasn’t closed—so end it at the last index.
    if stim[end] == 1
        push!(ends, n)
    end

    # Now pair up each start with the next end that comes after it.
    events = Tuple{Int,Int}[]
    i, j = 1, 1
    while i <= length(starts) && j <= length(ends)
        if starts[i] <= ends[j]
            push!(events, (starts[i], ends[j]))
            i += 1
            j += 1
        else
            j += 1
        end
    end

    return events
end

size(stimulus::StimulusProtocol) = size(stimulus.timestamps)

size(stimulus::StimulusProtocol, dim::Int64) = size(stimulus.timestamps, dim)

length(stimulus::StimulusProtocol) = size(stimulus, 1)

function push!(stimulus::StimulusProtocol, ts::Tuple)
    if stimulus.timestamps[1] == (-Inf, Inf)
        stimulus.timestamps = [ts]
    else
        push!(stimulus.sweeps, maximum(stimulus.sweeps)+1)
        push!(stimulus.timestamps, ts)
    end
end

function push!(stimulus::StimulusProtocol, ts::Tuple...)
    for t in ts
        push!(stimulus, t)
    end
end

function push!(stimulus::StimulusProtocol, sweep::Int64, ts::Tuple)
    if sweep > maximum(stimulus.sweeps)
        #We should warn the user that the next sweep number will be used instead
        @warn "The next sweep number will be used instead of $sweep"
        push!(stimulus.sweeps, maximum(stimulus.sweeps)+1)
        push!(stimulus.timestamps, ts)
    else
        push!(stimulus.sweeps, sweep)
        push!(stimulus.timestamps, ts)
    end
end

function push!(stimulusA::StimulusProtocol, stimulusB::StimulusProtocol)
    push!(stimulusA, stimulusB.timestamps...)
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

#I couldn't figure out where to put these functions, 
#   But I don't think they need to go elsewhere
function convert_stimulus!(exp, channel::String; kwargs...)
    stimulus_protocol = extractStimulus(exp.HeaderDict; stimulus_name = channel, kwargs...)
    #println(stimulus_protocol)
end
convert_stimulus!(exp, n_channel::Int64) = convert_stimulus!(exp, exp.chNames[n_channel])

#This is just a quick auxillary function to extract all points where the stimulus increases or decreases
"""
```julia
    exp = readABF(data_fn)
    t_episodes, idx_episodes = find_stim_index(exp)
```

This function takes a voltage range from an .abf file and calculates the interchange from high to low
    or low to high voltage.
Normally this should be done on a non-episodic range (so only a single trial)
Channel in the case of what I am doing normally is 3
The threshold is 2.5 which is telegraph limit
movement is going from a low voltage to high voltage
"""
function find_stim_index(exp; trial = 1, channel = 3, thresh = 2.5, movement = :increase)
    stimulus = exp.data_array[trial,:,channel]
    over_thresh = stimulus .< thresh #Label true all telegraph high values
    indexes = Int64[]
    for i in eachindex(over_thresh) #Iterate through each index of the stimulus
        if i+1>length(over_thresh) #If the index +1 is out of bounds no more
        
        else #Do the work here
            if movement == :increase &&  over_thresh[i] > over_thresh[i+1]
                push!(indexes, i)
            elseif movement == :decrease && over_thresh[i] < over_thresh[i+1]
                push!(indexes, i)
            else
                
            end
        end 
    end
    exp.t[indexes], indexes
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
function extractStimulus(abfInfo::Dict{String,Any}, stimulus_name::String;
    stimulus_threshold::Float64=2.5
)
    # Get the time interval between data points
    dt = abfInfo["dataSecPerPoint"]

    # Instantiate a StimulusProtocol object with the provided stimulus_name and the number of trials
    num_trials = size(abfInfo["data"], 1)
    stimuli = StimulusProtocol(stimulus_name)
    stimulus_waveform = getWaveform(abfInfo, stimulus_name)
    # Iterate over the trials
    for swp in axes(abfInfo["data"], 1)
        # Get the stimulus waveform for the current trial and apply the threshold
        stim_wave = stimulus_waveform[swp, :, 1] .> stimulus_threshold
        
        #Find the start and end timestamps of the stimulus event in the current trial
        events = extract_events(stim_wave)
        #Update the StimulusProtocol object with the timestamps for the current trial
        for event in events
            start_time = (event[1] - 1) * dt
            end_time = event[2] * dt
            push!(stimuli, (start_time, end_time))
        end
    end

    return stimuli
end

extractStimulus(abf_path::String, stimulus_name::String; flatten_episodic = false, kwargs...) = extractStimulus(readABFInfo(abf_path; flatten_episodic = flatten_episodic), stimulus_name; kwargs...)

getStimulusStartTime(stimulus::StimulusProtocol) = map(x -> x[1], stimulus.timestamps)
getStimulusEndTime(stimulus::StimulusProtocol) = map(x -> x[2], stimulus.timestamps)