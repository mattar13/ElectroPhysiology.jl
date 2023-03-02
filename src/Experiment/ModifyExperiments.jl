#This is our inplace function for scaling. Division is done by multiplying by a fraction
"""
    scaleby!(data::Experiment{T}, val::T)

Inplace scaling of the data experiment that scales the entire dataset by a value
"""
scaleby!(data::Experiment{T}, val::T) where T <: Real = data.data_array = data.data_array .* val 

function scaleby!(data::Experiment{T}, val::Vector{T}) where T <: Real
    #if the val is the same length of the channels then we can 
    if length(val) == size(data, 3) #Scale by the channel
        scale = reshape(val, 1,1,size(data,3))
        data.data_array = data.data_array .* scale 
    elseif length(val) == size(data,1) #Scale by sweep
        scale = reshape(val, size(data,1),1,1)
        data.data_array = data.data_array .* scale
    else
        throw(DimensionMismatch("arrays could not be broadcast to a common size; experiment dimensions: $(size(data)) vs val length: $(length(val))"))
    end
end

function scaleby(data::Experiment{T}, val) where T<:Real
    data_copy = deepcopy(data)
    scaleby!(data_copy, val)
    return data_copy
end

"""
"""
function pad(trace::Experiment{T}, n_add::Int64; position::Symbol=:post, val::T=0.0) where {T<:Real}
    data = deepcopy(trace)
    addon_size = collect(size(trace))
    addon_size[2] = n_add
    addon = fill(val, addon_size...)
    if position == :post
        data.data_array = [trace.data_array addon]
    elseif position == :pre
        data.data_array = [addon trace.data_array]
    end
    return data
end

function pad!(trace::Experiment{T}, n_add::Int64; position::Symbol=:post, val::T=0.0) where {T<:Real}
    addon_size = collect(size(trace))
    addon_size[2] = n_add
    addon = fill(val, addon_size...)
    if position == :post
        trace.data_array = [trace.data_array addon]
    elseif position == :pre
        trace.data_array = [addon trace.data_array]
    end
end

"""
    chop(data, n_chop)

Removes datapoints
"""
function chop(trace::Experiment, n_chop::Int64; position::Symbol=:post)
    data = copy(trace)
    resize_size = collect(size(trace))
    resize_size[2] = (size(trace, 2) - n_chop)
    resize_size = map(x -> 1:x, resize_size)
    data.data_array = data.data_array[resize_size...]
    return data
end

function chop!(trace::Experiment, n_chop::Int64; position::Symbol=:post)
    resize_size = collect(size(trace))
    resize_size[2] = (size(trace, 2) - n_chop)
    resize_size = map(x -> 1:x, resize_size)
    trace.data_array = trace.data_array[resize_size...]
end

"""
    drop!(data, dim = 3)

Removes a channel or sweep
"""
function drop!(trace::Experiment; dim=3, drop_idx=1)
    n_dims = collect(1:length(size(trace)))
    n_dims = [dim, n_dims[n_dims.!=dim]...]
    perm_data = permutedims(trace.data_array, n_dims)
    perm_data = perm_data[drop_idx.∉(1:size(trace, dim)), :, :]
    perm_data = permutedims(perm_data, sortperm(n_dims))
    trace.data_array = perm_data
end

function drop(trace::Experiment; kwargs...)
    trace_copy = copy(trace)
    drop!(trace_copy; kwargs...)
    return trace_copy
end

"""
    truncate_data
"""

function truncate_data!(trace::Experiment; 
    t_pre=1.0, t_post=4.0, 
    t_begin = nothing, t_end = nothing, 
    truncate_based_on=:stimulus_beginning
)
    dt = trace.dt
    size_of_array = 0
    overrun_time = 0 #This is for if t_pre is set too far before the stimulus
    if truncate_based_on == :time_range || !isnothing(t_begin) && !isnothing(t_end)
        #println("running here")
        #Use this if there is no stimulus, but rather you want to truncate according to time
        start_rng = round(Int64, t_begin / dt)
        end_rng = round(Int64, t_end / dt)
        #println(start_rng)
        #println(end_rng)
        #println(start_rng)
        #println(end_rng)
        trace.data_array = trace.data_array[:, start_rng:end_rng, :]
        trace.t = trace.t[start_rng:end_rng] .- trace.t[start_rng]
    elseif trace.stimulus_protocol.channelName == "Nothing"
        #println("No explicit stimulus has been set")
        size_of_array = round(Int64, t_post / dt)
        trace.data_array = trace.data_array[:, 1:size_of_array, :] #remake the array with only the truncated data
        trace.t = range(0.0, t_post, length=size_of_array)
    else
        for swp = axes(trace, 1)
            tstamps = trace.stimulus_protocol[swp]
            idx_range = round.(Int64, tstamps ./ dt)
            if truncate_based_on == :stimulus_beginning
                #This will set the beginning of the stimulus as the truncation location
                #tstamps = stimulus_protocol[swp]
                truncate_loc = idx_range[1]
                t_begin_adjust = 0.0
                t_end_adjust = tstamps[2] - tstamps[1]
            elseif truncate_based_on == :stimulus_end
                #This will set the beginning of the simulus as the truncation 
                truncate_loc = idx_range[2]
                t_begin_adjust = tstamps[1] - tstamps[2]
                t_end_adjust = 0.0
            end
            #println((t_begin_adjust, t_end_adjust))
            trace.stimulus_protocol[swp] = (t_begin_adjust, t_end_adjust)
            
            #First lets calculate how many indexes we need before the stimulus
            needed_before = round(Int, t_pre / dt)
            needed_after = round(Int, t_post / dt)
            
            #println("We need $needed_before and $needed_after indexes before and after")
            have_before = truncate_loc
            have_after = size(trace, 2) - truncate_loc
            #println("We have $have_before and $have_after indexes before and after")
            if needed_before > have_before
                #println("Not enough indexes preceed the stimulus point")
                extra_indexes = needed_before - have_before
                overrun_time = extra_indexes * dt
                #println("t_pre goes $extra_indexes indexes too far")
                idxs_begin = 1
                stim_begin_adjust = idx_range[1]
            else
                #println("Enough indexes preceed the stimulus point")
                idxs_begin = truncate_loc - round(Int, t_pre / dt) +1
                stim_begin_adjust = round(Int, t_pre / dt) 
            end

            if needed_after > have_after
                #println("Not enough indexes proceed the stimulus point")
                idxs_end = size(trace, 2)
            else
                #println("Enough indexes proceed the stimulus point")
                idxs_end = truncate_loc + round(Int, t_post / dt)+1
            end
            idxs_end = idxs_end < size(trace, 2) ? idxs_end : size(trace, 2)
            if size_of_array == 0
                size_of_array = (idxs_end - idxs_begin)+1
            end
            trace.data_array[swp, 1:size_of_array, :] .= trace.data_array[swp, idxs_begin:idxs_end, :]

            #println(size_of_array)
        end
        trace.data_array = trace.data_array[:, 1:size_of_array, :] #remake the array with only the truncated data
        trace.t = range(-t_pre + overrun_time, t_post, length=size_of_array)
    end
    return trace
end

function truncate_data(trace::Experiment; kwargs...) 
    data = deepcopy(trace)
    truncate_data!(data)
    return data
end

"""
"""
function average_sweeps(trace::Experiment{T}) where {T<:Real}
    data = deepcopy(trace)
    average_sweeps!(data)
    return data
end

average_sweeps!(trace::Experiment{T}) where {T<:Real} = trace.data_array = sum(trace, dims=1) / size(trace, 1)

function downsample(trace::Experiment{T}, sample_rate::T) where {T<:Real}
    data = deepcopy(trace)
    downsample!(data, sample_rate)
    return data
end

function downsample!(trace::Experiment{T}, sample_rate::T) where {T<:Real}
    old_sample_rate = 1/trace.dt
    new_dt = 1 / sample_rate
    trace.dt = new_dt #set the new dt
    trace.t = trace.t[1]:new_dt:trace.t[end] #Set the new time array
    sample_idxs = 1:round(Int64, old_sample_rate/sample_rate):size(trace, 2)
    trace.data_array = trace.data_array[:, sample_idxs, :]
end

function dyadic_downsample!(trace::Experiment{T}) where {T<:Real}
    n_data = length(trace.t)
    n_dyad = 2^(trunc(log2(n_data))) |> Int64
    dyad_idxs = round.(Int64, LinRange(1, length(trace.t), n_dyad)) |> collect
    trace.t = LinRange(trace.t[1], trace.t[end], n_dyad) |> collect
    trace.dt = abs(trace.t[3] - trace.t[2])
    trace.data_array = trace.data_array[:, dyad_idxs, :]
end

function dyadic_downsample(trace::Experiment{T}) where T<:Real
    data = deepcopy(trace)
    dyadic_downsample!(data)
    return data
end