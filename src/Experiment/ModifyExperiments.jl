#This is our inplace function for scaling. Division is done by multiplying by a fraction
"""
    scaleby!(data::Experiment{F,T}, val::T) where T <: Real
    scaleby!(data::Experiment{F,T}, val::Vector{T}) where T <: Real
Scale the data elements in the given `Experiment` object by a scalar value `val` in-place. 
If val is a vector of values, The length of the vector should match either the number of channels or the number of trials in the experiment.

# Arguments
- `data`: An `Experiment{F,T}` object containing the experimental data.
- `val`: A scalar value by which to scale the data.

# Example
```julia
exp = Experiment(data_array)
scaleby!(exp, 2.0)
```

"""
scaleby!(data::Experiment{F,T}, val::T) where {F, T <: Real} = data.data_array = data.data_array .* val 

function scaleby!(data::Experiment{F,T}, val::Vector{T}) where {F, T <: Real}
    #if the val is the same length of the channels then we can 
    if length(val) == size(data, 3) #Scale by the channel
        scale = reshape(val, 1,1,size(data,3))
        data.data_array = data.data_array .* scale 
    elseif length(val) == size(data,1) #Scale by trial
        scale = reshape(val, size(data,1),1,1)
        data.data_array = data.data_array .* scale
    else
        throw(DimensionMismatch("arrays could not be broadcast to a common size; experiment dimensions: $(size(data)) vs val length: $(length(val))"))
    end
end

function scaleby(data::Experiment{F,T}, val) where {F, T<:Real}
    data_copy = deepcopy(data)
    scaleby!(data_copy, val)
    return data_copy
end

"""
    pad(trace::Experiment{F,T}, n_add::Int64; position::Symbol=:post, val::T=0.0) where {T <: Real}
    pad!(trace::Experiment{F,T}, n_add::Int64; position::Symbol=:post, val::T=0.0) where {T <: Real}
Pad the data in a given `Experiment` object by adding elements with a specified value `val` either before or after the existing data. 
This function returns a new `Experiment` object with the padded data. pad! is the inplace version, while pad creates a new experiment

# Arguments
- `trace`: An `Experiment{F,T}` object containing the experimental data.
- `n_add`: The number of elements to add.
- `position`: (Optional) A symbol specifying where to add the elements. Can be `:pre` (before) or `:post` (after). Default is `:post`.
- `val`: (Optional) The value to use for padding. Default is 0.0.

# Example
```julia
exp = Experiment(data_array)
padded_exp = pad(exp, 100, position=:pre, val=0.0)
```
"""
function pad(trace::Experiment{F,T}, n_add::Int64; position::Symbol=:post, val::T=0.0) where {F, T<:Real}
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

function pad!(trace::Experiment{F,T}, n_add::Int64; position::Symbol=:post, val::T=0.0) where {F, T<:Real}
    addon_size = collect(size(trace))
    addon_size[2] = n_add
    addon = fill(val, addon_size...)
    if position == :post
        trace.data_array = [trace.data_array addon]
    elseif position == :pre
        trace.data_array = [addon trace.data_array]
    end
end

function pad_arr(arr::AbstractArray, pad_length; dims = 2, pad_val = 0.0)
    n, m, h = size(arr)
    if dims == 1
        pad = fill(pad_val, (pad_length, m, h))
    elseif dims == 2
        pad = fill(pad_val, (n, pad_length, h))
    elseif dims == 3
        pad = fill(pad_val, (n, m, pad_length))
    end
    cat(arr, pad; dims = dims)
end

"""
    chop(trace::Experiment, n_chop::Int64; position::Symbol=:post)
    chop!(trace::Experiment, n_chop::Int64; position::Symbol=:post)
Chop a specified number of elements from the data in a given `Experiment` object, either from the beginning or the end. This function returns a new `Experiment` object with the modified data.

# Arguments
- `trace`: An `Experiment` object containing the experimental data.
- `n_chop`: The number of elements to remove.
- `position`: (Optional) A symbol specifying where to remove the elements. Can be `:pre` (from the beginning) or `:post` (from the end). Default is `:post`.

# Example
```julia
exp = Experiment(data_array)
chopped_exp = chop(exp, 100, position=:pre)
```
"""
function chop(trace::Experiment{F, T}, n_chop::Int64; position::Symbol=:post) where {F, T<:Real}
    data = copy(trace)
    resize_size = collect(size(trace))
    resize_size[2] = (size(trace, 2) - n_chop)
    resize_size = map(x -> 1:x, resize_size)
    data.data_array = data.data_array[resize_size...]
    return data
end

function chop!(trace::Experiment{F, T}, n_chop::Int64; position::Symbol=:post) where {F, T<:Real}
    resize_size = collect(size(trace))
    resize_size[2] = (size(trace, 2) - n_chop)
    resize_size = map(x -> 1:x, resize_size)
    trace.data_array = trace.data_array[resize_size...]
end

function chop_arr(arr::AbstractArray, chop_length::Int64; dims = 2)
    if dims == 1
        return arr[:, :, 1:chop_length]
    elseif dims == 2
        return arr[:, 1:chop_length, :]
    elseif dims == 3
        return arr[:, :, 1:chop_length]
    end

end

"""
    drop!(data, dim = 3)

Removes a channel or trial
"""
function drop!(trace::Experiment{F, T}; dim=3, drop_idx=1) where {F, T<:Real}
    n_dims = collect(1:length(size(trace)))
    n_dims = [dim, n_dims[n_dims.!=dim]...]
    perm_data = permutedims(trace.data_array, n_dims)
    perm_data = perm_data[drop_idx.∉(1:size(trace, dim)), :, :]
    perm_data = permutedims(perm_data, sortperm(n_dims))
    trace.data_array = perm_data
end

function drop(trace::Experiment{F, T}; kwargs...) where {F, T<:Real}
    trace_copy = copy(trace)
    drop!(trace_copy; kwargs...)
    return trace_copy
end

"""
    truncate_data!(trace::Experiment; t_pre=1.0, t_post=4.0, t_begin=nothing, t_end=nothing, truncate_based_on=:stimulus_beginning)
    truncate_data(trace::Experiment; kwargs...)

Truncate data in the `Experiment` object, in-place, either based on the stimulus position or a specified time range.

# Arguments
- `trace`: An `Experiment` object containing the experimental data.
- `t_begin`: (Optional) Start time of the time range for truncation.
- `t_end`: (Optional) End time of the time range for truncation.
- `truncate_based_on`: (Optional) A symbol specifying the truncation method. Can be `:stimulus_beginning`, `:stimulus_end`, or `:time_range`. Default is `:stimulus_beginning`.

# Example
```julia
exp = Experiment(data_array)
truncate_data!(exp, t_pre=0.5, t_post=2.5)
```

```julia
exp = Experiment(data_array)
truncated_exp = truncate_data(exp, t_pre=0.5, t_post=2.5)
```
"""
function truncate_data!(trace::Experiment{F, T}, t_begin, t_end;
    truncate_based_on=:time_range, 
    stimulus_index = 1, #If :stimulus is selected for truncate_based_on, this is the index of the stimulus to truncate
    time_zero = false
) where {F, T<:Real}
    dt = trace.dt
    size_of_array = 0
    overrun_time = 0 #This is for if t_pre is set too far before the stimulus
    if truncate_based_on == :time_range
        #Use this if there is no stimulus, but rather you want to truncate according to time
        start_rng = round(Int64, t_begin / dt)+1
        end_rng = round(Int64, t_end / dt)
        trace.data_array = trace.data_array[:, start_rng:end_rng, :]
        trace.t = trace.t[start_rng:end_rng] .- trace.t[start_rng]
        
        try
            #Want to find only the stimulus that is within the (t_begin, t_end) range
            stim_protocol = getStimulusProtocol(trace)
            stim_in_range = findall(x -> x[1] >= t_begin && x[2] <= t_end, stim_protocol.timestamps)
            #Then assign the only stims in range to the new stim_protocl
            stim_protocol.timestamps = stim_protocol.timestamps[stim_in_range]
            #Now we need to subtract the t_begin from the stimulus timestamps
            for (idx, stim) in enumerate(stim_protocol.timestamps)
                new_start = stim[1] .- t_begin
                new_end = stim[2] .- t_begin
                stim_protocol.timestamps[idx] = (new_start, new_end)
            end
        catch error
            println(error)
            println("No stimulus protocol exists")
            throw(error)
        end

    elseif isnothing(getStimulusProtocol(trace))
        #println("No explicit stimulus has been set")
        size_of_array = round(Int64, t_post / dt)
        trace.data_array = trace.data_array[:, 1:size_of_array, :] #remake the array with only the truncated data
        trace.t = range(0.0, t_post, length=size_of_array)
    elseif truncate_based_on == :stimulus_beginning || truncate_based_on == :stimulus_end
        #We need to work on this a little bit. It no longer works the way I want it to. 
        try
            stim_protocol = getStimulusProtocol(trace)
            if truncate_based_on == :stimulus_beginning
                stimulus_time = stim_protocol[stimulus_index][1][1]
            elseif truncate_based_on == :stimulus_end
                stimulus_time = stim_protocol[stimulus_index][1][2]
            end
            #In this case, t_begin becomes relative to the stimulus and subtracted from it
            t_pre = max(0.0, stimulus_time - t_begin) #We want this to be positive however
            t_post = min(trace.t[end], stimulus_time + t_end) #We want this to be positive however

            start_rng = round(Int64, t_pre / dt)+1
            end_rng = round(Int64, t_post / dt)
            trace.data_array = trace.data_array[:, start_rng:end_rng, :]
            trace.t = trace.t[start_rng:end_rng] .- trace.t[start_rng]

            stim_in_range = findall(x -> x[1] >= t_pre && x[2] <= t_post, stim_protocol.timestamps)
            stim_protocol.timestamps = stim_protocol.timestamps[stim_in_range]
            for (idx, stim) in enumerate(stim_protocol.timestamps)
                new_start = stim[1] .- t_pre
                new_end = stim[2] .- t_pre
                stim_protocol.timestamps[idx] = (new_start, new_end)
            end
        catch error
            #println(error)
            println("No stimulus protocol exists")
            throw(error)
        end
    end
    return trace
end

function truncate_data(trace::Experiment{F, T}, t_begin, t_end; kwargs...) where {F, T<:Real} 
    data = deepcopy(trace)
    truncate_data!(data, t_begin, t_end; kwargs...)
    return data
end

"""
    average_trials(trace::Experiment)
    average_trials!(trace::Experiment)

Return a new `Experiment` object with the average of all trials of the input `Experiment` object.

# Arguments
- `trace`: An `Experiment` object containing the experimental data.

# Example
```julia
exp = Experiment(data_array)
averaged_exp = average_trials(exp)
```
```julia
exp = Experiment(data_array)
average_trials!(exp)
```
"""
function average_trials(trace::Experiment{F,T}) where {F, T<:Real}
    data = deepcopy(trace)
    average_trials!(data)
    return data
end

function average_trials!(trace::Experiment{F,T}) where {F, T<:Real}
    #trace.HeaderDict["stimulus_protocol"] = 
    new_stimulus_protocol = deepcopy(getStimulusProtocol(trace))
    new_stimulus_protocol.timestamps = [new_stimulus_protocol.timestamps[1]]
    new_stimulus_protocol.sweeps = [new_stimulus_protocol.sweeps[1]]
    trace.HeaderDict["StimulusProtocol"] = new_stimulus_protocol
    trace.data_array = sum(trace, dims=1) / size(trace, 1)
end
"""
    downsample(trace::Experiment, sample_rate::T) where {T<:Real}

Return a new `Experiment` object with the data downsampled to the specified `sample_rate`.

# Arguments
- `trace`: An `Experiment` object containing the experimental data.
- `sample_rate`: The desired new sample rate.

# Example
```julia
exp = Experiment(data_array)
downsampled_exp = downsample(exp, 1000.0)

```julia
exp = Experiment(data_array)
downsample!(exp, 1000.0)
```
```julia
exp = Experiment(data_array)
downsample!(exp, 1000.0)
```
"""
function downsample(trace::Experiment{F,T}, sample_rate::T) where {F, T<:Real}
    data = deepcopy(trace)
    downsample!(data, sample_rate)
    return data
end

function downsample!(trace::Experiment{F,T}, sample_rate::T) where {F, T<:Real}
    old_sample_rate = 1/trace.dt
    new_dt = 1 / sample_rate
    trace.dt = new_dt #set the new dt
    trace.t = trace.t[1]:new_dt:trace.t[end] #Set the new time array
    sample_idxs = 1:round(Int64, old_sample_rate/sample_rate):size(trace, 2)
    trace.data_array = trace.data_array[:, sample_idxs, :]
end

"""
    dyadic_downsample(trace::Experiment{F,T}) where {T<:Real}
    dyadic_downsample!(trace::Experiment{F,T}) where {T<:Real}

Return a new `Experiment` object with the data downsampled to the nearest dyadic length.

# Arguments
- `trace`: An `Experiment` object containing the experimental data.

# Example
```julia
exp = Experiment(data_array)
dyadic_downsampled_exp = dyadic_downsample(exp)
```
```julia
exp = Experiment(data_array)
dyadic_downsample!(exp)
```
"""
function dyadic_downsample!(trace::Experiment{F,T}) where {F, T<:Real}
    n_data = length(trace.t)
    n_dyad = 2^(trunc(log2(n_data))) |> Int64
    dyad_idxs = round.(Int64, LinRange(1, length(trace.t), n_dyad)) |> collect
    trace.t = LinRange(trace.t[1], trace.t[end], n_dyad) |> collect
    trace.dt = abs(trace.t[3] - trace.t[2])
    trace.data_array = trace.data_array[:, dyad_idxs, :]
end

function dyadic_downsample(trace::Experiment{F,T}) where {F, T<:Real}
    data = deepcopy(trace)
    dyadic_downsample!(data)
    return data
end

"""
    baseline_adjust(trace::Experiment{F,T}; kwargs...) where {T<:Real}
    baseline_adjust!(trace::Experiment{F,T}; kwargs...) where {T<:Real}

Return a new `Experiment` object with the baseline adjusted according to the specified mode and region.

# Arguments
- `trace`: An `Experiment` object containing the experimental data.

# Keyword Arguments
- `mode`: Baseline adjustment mode, either `:mean` or `:slope` (default: `:slope`).
- `polyN`: Polynomial order for the baseline fit (default: 1).
- `region`: Range for baseline adjustment, either `:prestim`, `:whole`, a tuple of time values or a tuple of indices.

# Example
```julia
exp = Experiment(data_array)
baseline_adjusted_exp = baseline_adjust(exp, mode=:mean, region=:prestim)
```
```julia
exp = Experiment(data_array)
baseline_adjust!(exp, mode=:mean, region=:prestim)
```
"""
function baseline_adjust(trace::Experiment{F,T}; kwargs...) where {F, T<:Real}
    data = deepcopy(trace)
    baseline_adjust!(data; kwargs...)
    return data
end

function baseline_adjust!(trace::Experiment{WHOLE_CELL,T};
    mode::Symbol=:slope, polyN=1, region=:whole
) where {T<:Real}

    for swp in axes(trace, 1)
        #if isnothing(getStimulusProtocol(trace))

        #else
        #idx_range = round.(Int64, tstamps ./ trace.dt)
        if isa(region, Tuple{Float64,Float64})
            rng_begin = round(Int, region[1] / trace.dt) + 1
            if region[2] > trace.t[end]
                rng_end = length(trace.t)
            else
                rng_end = round(Int, region[2] / trace.dt) + 1
            end
        elseif isa(region, Tuple{Int64,Int64})
                rng_begin, rng_end = region
        elseif region == :whole
            rng_begin = 1
            rng_end = length(trace)
        elseif region == :prestim
            #tstamps = getStimulusProtocol(trace)[swp].timestamps[1]
            rng_begin = 1
            rng_end = findfirst(trace.t .>= tstamps[1]) #Get the first stimulus index
        end


        for ch in axes(trace, 3)
            if mode == :mean
                if (rng_end - rng_begin) != 0
                    baseline_adjust = sum(trace.data_array[swp, rng_begin:rng_end, ch]) / (rng_end - rng_begin)
                    #Now subtract the baseline scaling value
                    trace.data_array[swp, :, ch] .= trace.data_array[swp, :, ch] .- baseline_adjust
                else
                    #println("no pre-stimulus range exists")
                end
            elseif mode == :slope
                if (rng_end - rng_begin) != 0 # && rng_begin != 1
                    pfit = PN.fit(trace.t[rng_begin:rng_end], trace[swp, rng_begin:rng_end, ch], polyN)
                    #Now offset the array by the linear range
                    trace.data_array[swp, :, ch] .= trace[swp, :, ch] - pfit.(trace.t)
                end
            end
        end
    end
end

"""
```julia
exp = readABF(data_filename)
offset::Float64 = 1.0 #seconds
time_offset!(exp, offset)
```

```julia
exp = readABF(data_filename)
offset = Millisecond(10.0) #converts automatically to seconds
time_offset!(exp, offset)
```

```julia
exp = readABF(data_filename)
offset::Float64 = 1.0 #seconds
offset_exp = time_offset(exp, offset) #Deepcopy of the experiment
```

This function changes the time of the data. Really simple function

"""
function time_offset!(exp::Experiment{FORMAT, T}, offset::T) where {FORMAT, T<:Real}
    exp.t .+= offset
    sps = getStimulusProtocol(exp)
    for (i, ts) in enumerate(sps.timestamps)
        sps.timestamps[i] = (ts[1] .+ offset, ts[2] .+ offset)
    end
end

function time_offset!(exp::Experiment{FORMAT, T}, time_offset::Millisecond) where {FORMAT, T<:Real} 
    exp.t .+= (time_offset.value)/1000 
end

function time_offset(exp::Experiment{FORMAT, T}, offset) where {FORMAT, T<:Real}
    new_exp = deepcopy(exp)
    time_offset!(new_exp, offset)
    new_exp
end

#%% 
#=
function create_episodes(expt::Experiment{FORMAT,T}, split_indices::Vector{Int}) where {FORMAT,T}
    # Check that all split_indices are within the valid range.
    for idx in split_indices
        if idx < 1 || idx >= length(expt.t)
            error("split_index out of range: must be between 1 and length(expt.t)-1.")
        end
    end

    # Sort split_indices to ensure they are in ascending order
    split_indices = sort(split_indices)

    # Split the time vector and data array based on split_indices
    start_idx = 1
    data_segments = Vector{Array{T,3}}()
    for idx in split_indices
        push!(data_segments, expt.data_array[:, start_idx:idx, :])
        start_idx = idx + 1
    end
    push!(data_segments, expt.data_array[:, start_idx:end, :])
    println(size(data_segments))

    # Find the maximum length among all data segments
    segment_lengths = 
    max_length = maximum(length.(data_segments))
    println(max_length)

    # Preallocate combined data array with `nothing` values
    num_channels = size(expt.data_array, 2)
    num_trials = length(data_segments)
    combined_data = fill(nothing, num_trials, max_length, num_channels)
    println(size(combined_data))
    # Assign each segment to the preallocated combined data array
    for (i, data) in enumerate(data_segments)
        println(size(data))
        combined_data[i, 1:size(data,2), :] .= data
    end

    # Combine all time segments into a single vector
    combined_t = vcat(time_segments...)

    # Create a new Experiment with combined episodes as trials
    new_expt = Experiment(
        expt.HeaderDict,
        expt.dt,
        combined_t,
        combined_data,
        expt.chNames,
        expt.chUnits,
        expt.chGains
    )

    return new_expt
end
=#