"""
    concat(data::Experiment{T}, data_add::Experiment{T}; kwargs...) where {T}
    concat!(data::Experiment{T}, data_add::Experiment{T}; kwargs...) where {T}

Return a new `Experiment` object with `data` concatenated with `data_add` along the trials dimension.

# Arguments
- `data`: An `Experiment` object containing the experimental data.
- `data_add`: Another `Experiment` object to be concatenated with the `data`.

# Keyword Arguments
- `mode`: Specifies whether to pad or chop the data if the sizes do not match (default: `:pad`).
- `position`: Specifies the position to pad or chop (default: `:post`).
- `verbose`: Prints information if set to true (default: false).
- `channel_mode`: Specifies how to handle extra channels (default: `:remove_extra`).

# Example
```julia
exp1 = Experiment(data_array1)
exp2 = Experiment(data_array2)
concatenated_exp = concat(exp1, exp2)
```julia
exp1 = Experiment(data_array1)
exp2 = Experiment(data_array2)
concat!(exp1, exp2)
```
"""
function concat(data::Experiment{T}, data_add::Experiment{T}; mode::Symbol=:pad, position::Symbol=:post, kwargs...) where {T}
    new_data = deepcopy(data)
    concat!(new_data, data_add)
    return new_data
end

function concat!(data::Experiment{T}, data_add::Experiment{T}; 
        mode::Symbol=:pad, position::Symbol=:post, verbose=false, 
        channel_mode::Symbol = :remove_extra,
        kwargs...) where {T}
    if size(data, 2) > size(data_add, 2)
        #println("Original data larger $(size(data,2)) > $(size(data_add,2))")
        n_vals = abs(size(data, 2) - size(data_add, 2))
        if mode == :pad
            pad!(data_add, n_vals; position=position)
        elseif mode == :chop
            chop!(data, n_vals; position=position)
        end
    elseif size(data, 2) < size(data_add, 2)
        #println("Original data smaller $(size(data,2)) < $(size(data_add,2))")
        n_vals = abs(size(data, 2) - size(data_add, 2))
        if mode == :pad
            pad!(data, n_vals; position=position)
        elseif mode == :chop
            chop!(data_add, n_vals; position=position)
        end
    end

    if size(data, 3) != size(data_add, 3) #This means the cannels do not match
        if verbose
            println("Concatenated file has too many channels")
            println(data_add.chNames)
        end
        #We want to remove channels that are hanging. 
        ch1in2 = indexin(data.chNames, data_add.chNames)
        ch2in1 = indexin(data_add.chNames, data.chNames)
        if any(isnothing.(ch1in2))
            hanging_channels = findall(isnothing.(ch1in2))
            data_dropped = drop(data, dim = 3, drop_idx = hanging_channels[1])
            push!(data_dropped, data_add)
            push!(data_dropped.stimulus_protocol, data_add.stimulus_protocol)
        elseif any(isnothing.(ch2in1))
            hanging_channels = findall(isnothing.(ch2in1))
            data_dropped = drop(data_add, dim = 3, drop_idx = hanging_channels[1])
            push!(data, data_dropped)
            push!(data.stimulus_protocol, data_dropped.stimulus_protocol)
        end
    else
        push!(data, data_add)
        push!(data.stimulus_protocol, data_add.stimulus_protocol)
    end
end

"""
    match_channels(exp1::Experiment, exp2::Experiment)

Return two modified `Experiment` objects with their channels matched.

If the number of channels in `exp1` and `exp2` is not equal, this function will drop extra channels
from the `Experiment` object with more channels, making both objects have the same number of channels.

# Arguments
- `exp1`: An `Experiment` object containing the experimental data.
- `exp2`: Another `Experiment` object to be matched with `exp1`.

# Returns
- `(exp1_modified, exp2_modified)`: A tuple containing the two modified `Experiment` objects with matched channels.

# Example
```julia
exp1 = Experiment(data_array1)
exp2 = Experiment(data_array2)
exp1_modified, exp2_modified = match_channels(exp1, exp2)
```
"""
function match_channels(exp1::Experiment, exp2::Experiment)
    if size(exp1) != size(exp2)
        #we want to drop the extra channel
        match_ch = findall(exp1.chNames .== exp2.chNames)
        if size(exp1, 3) > size(exp2, 3)
            exp1 = drop(exp1, drop_idx=match_ch[1])
        else
            exp2 = drop(exp2, drop_idx=match_ch[1])
        end

    end
    return (exp1, exp2)
end

"""
    sub_exp(exp1::Experiment, exp2::Experiment)

Subtract the data of `exp2` from `exp1` and return a new `Experiment` object with the resulting data.

This function will automatically match the channels of both `Experiment` objects if they do not match. 
If the channels do not match, it will drop the unmatching channels by default.

# Arguments
- `exp1`: An `Experiment` object containing the experimental data.
- `exp2`: Another `Experiment` object containing the data to be subtracted from `exp1`.

# Returns
- `data`: A new `Experiment` object with the resulting data after the subtraction.

# Example
```julia
exp1 = Experiment(data_array1)
exp2 = Experiment(data_array2)
result_exp = sub_exp(exp1, exp2)
```
"""
function sub_exp(exp1::Experiment, exp2::Experiment)
    if size(exp1) == size(exp2)
        data = deepcopy(exp1)
        #return a new experiment? make a new exp
        data.data_array = exp1.data_array - exp2.data_array
        return data
    else #If the channels don't match, we will automatically drop the unmatching one by default
        exp1, exp2 = match_channels(exp1, exp2)
        data = deepcopy(exp1)
        #return a new experiment? make a new exp
        data.data_array = exp1.data_array - exp2.data_array
        return data
    end
end

-(exp1::Experiment, exp2::Experiment) = sub_exp(exp1, exp2)