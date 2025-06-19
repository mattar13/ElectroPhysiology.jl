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

function setindex!(stimulus_protocol::StimulusProtocol{T}, X::Tuple{T, T}, I...) where T <: Real 
    stimulus_protocol[I].timestamps = [X,]
end

function setindex!(stimulus_protocol::StimulusProtocol{T}, X::Vector{Tuple{T, T}}, I) where T <: Real 
    stimulus_protocol[I] = X
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

Extract start and end indices of stimulus events from a binary stimulus waveform.

# Details
A stimulus event is defined as a contiguous sequence of high values (typically 1s) in a binary waveform.
The function detects transitions from low to high (event start) and high to low (event end).

# Arguments
- `stim`: Binary stimulus waveform (typically 0s and 1s)

# Returns
- Vector of tuples `(start_idx, end_idx)` where:
    - `start_idx`: Index where stimulus transitions from low to high
    - `end_idx`: Index where stimulus transitions from high to low

# Examples
```julia
# Simple binary stimulus
stim = [0, 0, 1, 1, 1, 0, 0, 1, 1, 0]
events = extract_events(stim)
# Returns: [(3,5), (8,9)]

# From experiment data
stim_channel = exp.data_array[1,:,3] .> 2.5  # Threshold at 2.5V
events = extract_events(stim_channel)
```

See also: [`extractStimulus`](@ref)
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

    # If the last element is 1, then the event hasn't closed—so end it at the last index.
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

#This is just a quick auxillary function to extract all points where the stimulus increases or decreases
"""
    find_stim_index(exp::Experiment; trial=1, channel=3, thresh=2.5, movement=:increase)

Find indices where a stimulus signal crosses a threshold in either direction.

# Arguments
- `exp`: Experiment object containing the stimulus data
- `trial`: Trial number to analyze (default: 1)
- `channel`: Channel number containing stimulus (default: 3)
- `thresh`: Threshold voltage for detecting transitions (default: 2.5V)
- `movement`: Direction of threshold crossing
    - `:increase`: Low to high transitions
    - `:decrease`: High to low transitions

# Returns
- Tuple of (timestamps, indices) where threshold crossings occur

# Examples
```julia
# Find rising edges in stimulus
t, idx = find_stim_index(exp, movement=:increase)

# Find falling edges with custom threshold
t, idx = find_stim_index(exp, 
    channel=4, 
    thresh=3.0, 
    movement=:decrease
)
```

See also: [`extractStimulus`](@ref)
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
    extractStimulus(abfInfo::Dict{String, Any}, stimulus_name::String; stimulus_threshold::Float64=2.5)
    extractStimulus(abf_path::String, stimulus_name::String; kwargs...)

Extract stimulus information from ABF data and create a StimulusProtocol object.

# Details
The function analyzes a specified channel in the ABF data to detect stimulus events based on a threshold.
It creates a StimulusProtocol object containing the timing information for each detected stimulus event.

# Arguments
- `abfInfo`: Dictionary containing ABF file information
- `abf_path`: Path to ABF file
- `stimulus_name`: Name of the stimulus channel
- `stimulus_threshold`: Voltage threshold for detecting stimulus events (default: 2.5V)

# Additional Parameters
- `flatten_episodic`: Whether to treat episodic data as continuous (default: false)

# Returns
- StimulusProtocol object containing:
    - Stimulus name
    - Vector of (start_time, end_time) tuples for each stimulus event
    - Additional metadata about the stimulus

# Examples
```julia
# Extract from ABF info dictionary
stim = extractStimulus(abf_info, "Digital 1", stimulus_threshold=2.5)

# Extract directly from ABF file
stim = extractStimulus("path/to/file.abf", "Digital 1")

# Access stimulus timing
start_times = getStimulusStartTime(stim)
end_times = getStimulusEndTime(stim)
```

# Notes
- Digital channels typically use TTL signals with 2.5V threshold
- For analog channels, adjust threshold based on signal characteristics
- Time values are in the same units as the ABF file (typically seconds)

See also: [`extract_events`](@ref), [`StimulusProtocol`](@ref)
"""
function extractStimulus(abfInfo::Dict{String,Any}, stimulus_name::String;
    stimulus_threshold::Float64=2.5
)
    # Get the time interval between data points
    dt = abfInfo["dataSecPerPoint"]

    # Instantiate a StimulusProtocol object with the provided stimulus_name and the number of trials
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

function spike_train_group!(stim_protocol::StimulusProtocol{T,S}, group_time) where {T<:Real,S}
    # Create a new StimulusProtocol object to store the grouped events.
    # This uses the provided constructor that accepts a channel name.
    grouped_stimulus = StimulusProtocol(stim_protocol.channelName)
    
    # Get the current timestamps from the original protocol.
    current_timestamps = stim_protocol.timestamps
    
    grouped_timestamps = Tuple{T,T}[]
    
    # If there are no timestamps, just return the new (empty) protocol.
    if isempty(current_timestamps)
        return grouped_stimulus
    end

    # Initialize the first group using the first event.
    group_begin_time = current_timestamps[1][1]
    group_end_time   = current_timestamps[1][2]
    
    # Iterate over the remaining events (starting at the second).
    for (episode, (start_time, end_time)) in enumerate(current_timestamps)
        if episode == 1
            continue # Skip the first episode since it's already grouped.
        end
        # If adding this event would exceed the allowed group duration,
        # save the current group and start a new one.
        if end_time - group_begin_time > group_time
            push!(grouped_timestamps, (group_begin_time, group_end_time))
            #println("New group at episode $episode")
            group_begin_time = start_time
            group_end_time   = end_time
        else
            # Otherwise, extend the current group.
            group_end_time = max(group_end_time, end_time)
            #println("Group together at episode $episode")
        end
    end
    
    # Push the last group into the grouped timestamps.
    push!(grouped_timestamps, (group_begin_time, group_end_time))
    
    # Update the new protocol's timestamps.
    stim_protocol.timestamps = grouped_timestamps
    stim_protocol.sweeps = collect(1:length(grouped_timestamps)) # Update the sweep numbers
    #return grouped_stimulus
    nothing
end

"""
    addStimulus!(exp::Experiment, protocol::StimulusProtocol)

Add a stimulus protocol to the experiment.

# Arguments
- `exp`: An `Experiment` object
- `protocol`: A `StimulusProtocol` object containing the stimulus information

# Example
```julia
exp = Experiment(data_array)
protocol = StimulusProtocol()
addStimulus!(exp, protocol)
```
"""
addStimulus!(exp::Experiment, protocol::StimulusProtocol) = exp.HeaderDict["StimulusProtocol"] = protocol

"""
    addStimulus!(exp::Experiment, protocol_fn::String, stim_channel::String; kwargs...)

Add a stimulus protocol to the experiment from a file.

# Arguments
- `exp`: An `Experiment` object
- `protocol_fn`: Path to the file containing stimulus protocol
- `stim_channel`: Name of the stimulus channel
- `kwargs...`: Additional keyword arguments passed to `extractStimulus`

# Example
```julia
exp = Experiment(data_array)
addStimulus!(exp, "stimulus.abf", "IN 7")
```
"""
function addStimulus!(exp::Experiment, protocol_fn::String, stim_channel::String; 
    align_timestamps::Bool=true, kwargs...
)
    if haskey(exp.HeaderDict, "StimulusProtocol")
        throw(ArgumentError("Stimulus protocol already exists"))
    end
    #We have to configure the stimulus offset
    if align_timestamps
        stim = extractStimulus(protocol_fn, stim_channel; kwargs...)
    else
        stim = extractStimulus(protocol_fn, stim_channel; kwargs...)
    end
    addStimulus!(exp, stim)
end

"""
    addStimulus!(exp::Experiment, stim_channel::String; kwargs...)

Add a stimulus protocol to the experiment from the recording data.

# Arguments
- `exp`: An `Experiment` object
- `stim_channel`: Name of the stimulus channel in the recording
- `kwargs...`: Additional keyword arguments passed to `extractStimulus`

# Example
```julia
exp = Experiment(data_array)
addStimulus!(exp, "IN 7")
```
"""
function addStimulus!(exp::Experiment, stim_channel::String; kwargs...)
    if haskey(exp.HeaderDict, "StimulusProtocol")
        throw(ArgumentError("Stimulus protocol already exists"))
    end
    #We have to configure the stimulus offset
    stim = extractStimulus(exp.HeaderDict, stim_channel; kwargs...)
    
    addStimulus!(exp, stim)
end

"""
    setIntensity(exp::Experiment, photons)

Set the intensity of the stimulus protocol.

# Arguments
- `exp`: An `Experiment` object
- `photons`: The intensity value to set

# Example
```julia
exp = Experiment(data_array)
setIntensity(exp, 1.0)
```
"""
setIntensity(exp::Experiment, photons) = setIntensity(exp.HeaderDict["StimulusProtocol"], photons)

"""
    getIntensity(exp::Experiment)

Get the intensity of the stimulus protocol.

# Arguments
- `exp`: An `Experiment` object

# Returns
- The current intensity value of the stimulus protocol

# Example
```julia
exp = Experiment(data_array)
intensity = getIntensity(exp)
```
"""
getIntensity(exp::Experiment) = getIntensity(exp.HeaderDict["StimulusProtocol"])

"""
    getStimulusProtocol(exp::Experiment)

Get the stimulus protocol associated with the experiment.

# Arguments
- `exp`: An `Experiment` object

# Returns
- The `StimulusProtocol` object if one exists, `nothing` otherwise

# Example
```julia
exp = Experiment(data_array)
protocol = getStimulusProtocol(exp)
```
"""
getStimulusProtocol(exp::Experiment) = haskey(exp.HeaderDict, "StimulusProtocol") ? exp.HeaderDict["StimulusProtocol"] : nothing

"""
    getStimulusStartTime(exp::Experiment)

Get the start times of all stimulus events in the experiment.

# Arguments
- `exp`: An `Experiment` object

# Returns
- Vector of start times for each stimulus event

# Example
```julia
exp = Experiment(data_array)
start_times = getStimulusStartTime(exp)
```
"""
getStimulusStartTime(exp::Experiment) = getStimulusStartTime(getStimulusProtocol(exp))

"""
    getStimulusEndTime(exp::Experiment)

Get the end times of all stimulus events in the experiment.

# Arguments
- `exp`: An `Experiment` object

# Returns
- Vector of end times for each stimulus event

# Example
```julia
exp = Experiment(data_array)
end_times = getStimulusEndTime(exp)
```
"""
getStimulusEndTime(exp::Experiment) = getStimulusEndTime(getStimulusProtocol(exp))

getStimulusEndIndex(exp::Experiment) = round(Int64, getStimulusEndTime(exp) ./ exp.dt)
getStimulusStartIndex(exp::Experiment) = round(Int64, getStimulusStartTime(exp) ./ exp.dt)

"""
    addStimulus!(target_exp::Experiment, source_exp::Experiment, source_channel; 
        threshold::Real=2.5, channel_name::String="Converted Stimulus")

Convert a channel from a source experiment into a stimulus protocol for a target experiment.

# Arguments
- `target_exp`: The experiment to add the stimulus protocol to
- `source_exp`: The experiment containing the channel to convert
- `source_channel`: The channel to convert, can be either:
    - An integer index
    - A string channel name
    - A vector of indices or names for multiple channels

# Keyword Arguments
- `threshold`: The voltage threshold for detecting stimulus events (default: 2.5V)
- `channel_name`: Name to give the stimulus channel (default: "Converted Stimulus")

# Example
```julia
# Convert channel 3 from source experiment to stimulus protocol
addStimulus!(target_exp, source_exp, 3)

# Convert channel named "IN 7" with custom threshold
addStimulus!(target_exp, source_exp, "IN 7", threshold=3.0)

# Convert multiple channels
addStimulus!(target_exp, source_exp, ["IN 7", "IN 8"])
```
"""
function addStimulus!(target_exp::Experiment, source_exp::Experiment, source_channel; 
    threshold::Real=2.5, channel_name::String="Converted Stimulus")
    
    # Handle different types of source_channel input
    if isa(source_channel, String)
        ch_idx = findfirst(isequal(source_channel), source_exp.chNames)
        if isnothing(ch_idx)
            throw(ArgumentError("Channel name '$source_channel' not found in source experiment"))
        end
        channels = [ch_idx]
    elseif isa(source_channel, Vector{String})
        channels = map(ch -> findfirst(isequal(ch), source_exp.chNames), source_channel)
        if any(isnothing, channels)
            throw(ArgumentError("One or more channel names not found in source experiment"))
        end
    elseif isa(source_channel, Integer)
        channels = [source_channel]
    elseif isa(source_channel, Vector{<:Integer})
        channels = source_channel
    else
        throw(ArgumentError("source_channel must be a string, integer, or vector of strings/integers"))
    end

    # Create a new stimulus protocol
    protocol = StimulusProtocol(channel_name)
    
    # For each trial in the source experiment
    for trial in axes(source_exp, 1)
        # Get the stimulus waveform for the current trial
        stim_wave = source_exp[trial, :, channels] .> threshold
        
        # Find the start and end times of stimulus events
        start_events = getStimulusStartTime(source_exp)
        end_events = getStimulusEndTime(source_exp)
        
        # Add each event to the protocol
        for (i, start_time) in enumerate(start_events)
            end_time = end_events[i]
            push!(protocol, (start_time, end_time))
        end
    end
    
    # Add the protocol to the target experiment
    addStimulus!(target_exp, protocol)
end

"""
    addStimulus!(target_exp::Experiment, source_exp::Experiment, source_channel; kwargs...)

Non-mutating version of `addStimulus!`. Returns a new experiment with the converted stimulus protocol.

# Arguments
- `target_exp`: The experiment to add the stimulus protocol to
- `source_exp`: The experiment containing the channel to convert
- `source_channel`: The channel to convert (see `convert_channel_to_stimulus!` for details)

# Keyword Arguments
- `threshold`: The voltage threshold for detecting stimulus events (default: 2.5V)
- `channel_name`: Name to give the stimulus channel (default: "Converted Stimulus")

# Returns
- A new `Experiment` object with the converted stimulus protocol

# Example
```julia
# Convert channel 3 from source experiment to stimulus protocol
new_exp = addStimulus!(target_exp, source_exp, 3)
```
"""
function addStimulus(target_exp::Experiment, source_exp::Experiment, source_channel; kwargs...)
    new_exp = deepcopy(target_exp)
    addStimulus!(new_exp, source_exp, source_channel; kwargs...)
    return new_exp
end

spike_train_group!(exp::Experiment, group_time) = spike_train_group!(exp.HeaderDict["StimulusProtocol"], group_time)

# #Here we should alter the addStimulus! function to allow for file to be converted to a stimulus protocol
# function addStimulus!(target_exp::Experiment, source_fn::String, source_channel::String; kwargs...)
#     source_exp = readABF(source_fn)
#     addStimulus!(target_exp, source_exp, source_channel; kwargs...)
# end

# function addStimulus(target_exp::Experiment, source_fn::String, source_channel::String; kwargs...)
#     new_exp = deepcopy(target_exp)
#     addStimulus!(new_exp, source_fn, source_channel; kwargs...)
#     return new_exp
# end