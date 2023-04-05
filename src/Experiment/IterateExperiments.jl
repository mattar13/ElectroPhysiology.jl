"""
    getdata(trace::Experiment, sweeps, timepoints, channels::Union{String,Vector{String}})
    getdata(trace::Experiment, sweeps, timepoints, channels; verbose=false)

Return a new `Experiment` object with a specified subset of data extracted from the input `trace` based on 
`sweeps`, `timepoints`, and `channels`.

# Arguments
- `trace`: An `Experiment` object containing the experimental data.
- `sweeps`: A selection of sweeps to include in the new data.
- `timepoints`: A selection of timepoints to include in the new data.
- `channels`: A `String` or `Vector{String}` specifying the channels to include in the new data.

# Returns
- `data`: A new `Experiment` object containing the specified subset of data.

# Example
```julia
data = getdata(trace, 1:5, 100:200, ["Ch1", "Ch2"])
```
"""
function getdata(trace::Experiment, sweeps, timepoints, channels::Union{String,Vector{String}})
    data = deepcopy(trace) #this copies the entire 
    data.data_array = trace[sweeps, timepoints, channels]
    data.chNames = channels
    return data
end

function getdata(trace::Experiment, sweeps, timepoints, channels; verbose=false) #I don't have an idea as to why this works differently
     data = deepcopy(trace)
     if isa(sweeps, Int64)
          sweeps = [sweeps]
     end
     if isa(timepoints, Int64)
          timepoints = [timepoints]
     end
     if isa(channels, Int64)
          channels = [channels]
     end     
     data.data_array = trace[sweeps, timepoints, channels]
     data.chNames = trace.chNames[channels]
     return data
end

"""
     getchannel(trace::Experiment, ch_idx::Int64; verbose=false)

Return a new Experiment object with data from a single channel specified by ch_idx.

# Arguments
     trace: An Experiment object containing the experimental data.
     ch_idx: The index of the channel to extract.
# Returns
     data: A new Experiment object containing the data from the specified channel.
# Examples
```julia
getchannel(trace::Experiment, ch_idx::Int64; verbose=false) = getdata(trace, :, :, ch_idx; verbose=verbose)
```
"""
getchannel(trace::Experiment, ch_idx::Int64; verbose=false) = getdata(trace, :, :, ch_idx; verbose=verbose)

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
    eachsweep(trace::Experiment)

Return an iterator that iterates over each sweep of the input `trace` as an `Experiment` object.

# Arguments
- `trace`: An `Experiment` object containing the experimental data.

# Returns
- An iterator that yields an `Experiment` object for each sweep in the input `trace`.

# Example
```julia
sweep_iter = eachsweep(trace)
for sweep in sweep_iter
    # Process each sweep
end
```
"""
eachsweep(trace::Experiment) = Iterators.map(idx -> getdata(trace, idx, :, :), 1:size(trace, 1))