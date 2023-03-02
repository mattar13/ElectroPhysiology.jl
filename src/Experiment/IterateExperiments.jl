"""
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


getchannel(trace::Experiment, ch_idx::Int64; verbose=false) = getdata(trace, :, :, ch_idx; verbose=verbose)

"""
"""
eachchannel(trace::Experiment; verbose=false) = Iterators.map(idx -> getchannel(trace, idx; verbose=verbose), 1:size(trace, 3))

"""
"""
eachsweep(trace::Experiment) = Iterators.map(idx -> getdata(trace, idx, :, :), 1:size(trace, 1))