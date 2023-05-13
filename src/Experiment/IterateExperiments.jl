"""
    getdata(trace::Experiment, trials, timepoints, channels::Union{String,Vector{String}})
    getdata(trace::Experiment, trials, timepoints, channels; verbose=false)

Return a new `Experiment` object with a specified subset of data extracted from the input `trace` based on 
`trials`, `timepoints`, and `channels`.

# Arguments
- `trace`: An `Experiment` object containing the experimental data.
- `trials`: A selection of trials to include in the new data.
- `timepoints`: A selection of timepoints to include in the new data.
- `channels`: A `String` or `Vector{String}` specifying the channels to include in the new data.

# Returns
- `data`: A new `Experiment` object containing the specified subset of data.

# Example
```julia
data = getdata(trace, 1:5, 100:200, ["Ch1", "Ch2"])
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
A quick convienance function that returns the index of the channel that is named
"""
findChIdx(exp::Experiment, name::String) = findall(name .== exp.chNames)
findChIdx(exp::Experiment, names::Vector{String}) = map(n -> findfirst(n .== exp.chNames), names)

"""
     getchannel(trace::Experiment, ch_idx::Int64; verbose=false)

Return a new Experiment object with data from a single channel specified by ch_idx.

# Arguments
     trace: An Experiment object containing the experimental data.
     ch_idx: The index of the channel to extract.
     ch_name: The name of the channel to extract
# Returns
     data: A new Experiment object containing the data from the specified channel.
# Examples
```julia
getchannel(trace::Experiment, ch_idx::Int64; verbose=false) = getdata(trace, :, :, ch_idx; verbose=verbose)
```
"""
getchannel(trace::Experiment, ch_idx::Int64; verbose=false) = getdata(trace, :, :, ch_idx; verbose=verbose)
getchannel(trace::Experiment, ch_idxs::Vector{Int64}; kwargs...) = map(c -> getchannel(trace, c; kwargs...), ch_idxs)
getchannel(trace::Experiment, ch_name::Union{String, Vector{String}}; kwargs...) = getchannel(trace, findChIdx(trace, ch_name); kwargs...)

"""
    eachchannel(trace::Experiment; verbose=false)

Return an iterator that iterates over each channel of the input `trace` as an `Experiment` object.

# Arguments
- `trace`: An `Experiment` object containing the experimental data.

# Returns
- An iterator that yields an `Experiment` object for each channel in the input `trace`.

# Example
```julia
channel_iter = eachchannel(trace)
for channel in channel_iter
    # Process each channel
end
```
"""
eachchannel(trace::Experiment; verbose=false) = Iterators.map(idx -> getchannel(trace, idx; verbose=verbose), 1:size(trace, 3))

"""
    eachtrial(trace::Experiment)

Return an iterator that iterates over each trial of the input `trace` as an `Experiment` object.

# Arguments
- `trace`: An `Experiment` object containing the experimental data.

# Returns
- An iterator that yields an `Experiment` object for each trial in the input `trace`.

# Example
```julia
trial_iter = eachtrial(trace)
for trial in trial_iter
    # Process each trial
end
```
"""
eachtrial(trace::Experiment) = Iterators.map(idx -> getdata(trace, idx, :, :), 1:size(trace, 1))