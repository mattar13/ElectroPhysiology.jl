"""
    getdata(trace::Experiment, trials, timepoints, channels)

Extract a subset of data from an Experiment object based on specified trials, timepoints, and channels.
Returns a new Experiment object containing only the selected data.

# Arguments
- `trace`: Source Experiment object
- `trials`: Trial selection, can be:
    - Integer for single trial
    - Vector{Int64} for multiple trials
    - : for all trials
- `timepoints`: Timepoint selection, can be:
    - Integer for single timepoint
    - Vector{Int64} for multiple timepoints
    - UnitRange for a range of timepoints
    - : for all timepoints
- `channels`: Channel selection, can be:
    - String for single channel name
    - Vector{String} for multiple channel names
    - Int64 for channel index
    - Vector{Int64} for multiple channel indices
    - : for all channels

# Returns
- A new Experiment object containing only the selected data, with all metadata preserved

# Examples
```julia
# Get data from first trial, all timepoints, first channel
data = getdata(exp, 1, :, 1)

# Get data from multiple trials, specific timepoints, multiple channels
data = getdata(exp, 1:3, 100:200, ["Ch1", "Ch2"])

# Get all trials for specific timepoints and channels
data = getdata(exp, :, 1:1000, ["Vm_prime"])
```
"""
function getdata(trace::Experiment, trials, timepoints, channels::Union{String,Vector{String}})
    data = deepcopy(trace) #this copies the entire 
    data.data_array = trace[trials, timepoints, channels]
    data.chNames = channels
    return data
end

function getdata(trace::Experiment, trials, timepoints, channels; verbose=false) #I don't have an idea as to why this works differently
     data = deepcopy(trace)
     if isa(trials, Int64)
          trials = [trials]
     end
     if isa(timepoints, Int64)
          timepoints = [timepoints]
     end
     if isa(channels, Int64)
          channels = [channels]
     end     
     data.data_array = trace[trials, timepoints, channels]
     data.chNames = trace.chNames[channels]
     return data
end

"""
    findChIdx(exp::Experiment, name::String)
    findChIdx(exp::Experiment, names::Vector{String})

Find the index or indices of channels in an Experiment by their names.

# Arguments
- `exp`: The Experiment object to search in
- `name`: Single channel name to find
- `names`: Vector of channel names to find

# Returns
- For single name: Vector of indices where the channel name matches
- For multiple names: Vector of indices for each channel name

# Examples
```julia
# Find index of a single channel
idx = findChIdx(exp, "Vm_prime")

# Find indices of multiple channels
idxs = findChIdx(exp, ["Vm_prime", "IN 7"])
```
"""
findChIdx(exp::Experiment, name::String) = findall(name .== exp.chNames)
findChIdx(exp::Experiment, names::Vector{String}) = map(n -> findfirst(n .== exp.chNames), names)

"""
    getchannel(trace::Experiment, ch_idx::Int64; verbose=false)
    getchannel(trace::Experiment, ch_idxs::Vector{Int64}; kwargs...)
    getchannel(trace::Experiment, ch_name::Union{String, Vector{String}}; kwargs...)

Extract data for specific channels from an Experiment object. Returns a new Experiment object
containing only the selected channels.

# Arguments
- `trace`: Source Experiment object
- `ch_idx`: Single channel index
- `ch_idxs`: Vector of channel indices
- `ch_name`: Channel name or vector of channel names
- `verbose`: Whether to print additional information (default: false)

# Returns
- For single channel: New Experiment object with data from the specified channel
- For multiple channels: Vector of Experiment objects, one for each channel

# Examples
```julia
# Get data for a single channel by index
ch_data = getchannel(exp, 1)

# Get data for multiple channels by indices
ch_data = getchannel(exp, [1, 3])

# Get data for channels by name
ch_data = getchannel(exp, "Vm_prime")
ch_data = getchannel(exp, ["Vm_prime", "IN 7"])
```
"""
getchannel(trace::Experiment, ch_idx::Int64; verbose=false) = getdata(trace, :, :, ch_idx; verbose=verbose)
getchannel(trace::Experiment, ch_idxs::Vector{Int64}; kwargs...) = map(c -> getchannel(trace, c; kwargs...), ch_idxs)
getchannel(trace::Experiment, ch_name::Union{String, Vector{String}}; kwargs...) = getchannel(trace, findChIdx(trace, ch_name); kwargs...)

"""
    eachchannel(trace::Experiment; verbose=false)

Create an iterator that yields each channel of the Experiment as a separate Experiment object.
This is useful for performing operations on each channel independently.

# Arguments
- `trace`: Source Experiment object
- `verbose`: Whether to print additional information (default: false)

# Returns
- An iterator that yields an Experiment object for each channel

# Examples
```julia
# Process each channel independently
for channel in eachchannel(exp)
    # Channel is an Experiment object with a single channel
    process_channel_data(channel)
end

# Using with map
results = map(eachchannel(exp)) do channel
    analyze_channel(channel)
end
```
"""
eachchannel(trace::Experiment; verbose=false) = Iterators.map(idx -> getchannel(trace, idx; verbose=verbose), 1:size(trace, 3))

"""
    eachtrial(trace::Experiment)

Create an iterator that yields each trial of the Experiment as a separate Experiment object.
This is useful for performing operations on each trial independently.

# Arguments
- `trace`: Source Experiment object

# Returns
- An iterator that yields an Experiment object for each trial

# Examples
```julia
# Process each trial independently
for trial in eachtrial(exp)
    # Trial is an Experiment object with a single trial
    process_trial_data(trial)
end

# Using with map
results = map(eachtrial(exp)) do trial
    analyze_trial(trial)
end
```
"""
eachtrial(trace::Experiment) = Iterators.map(idx -> getdata(trace, idx, :, :), 1:size(trace, 1))