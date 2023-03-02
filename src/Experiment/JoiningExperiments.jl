"""
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
        println(ch2in1)
        println(ch1in2)
        if any(isnothing.(ch1in2))
            hanging_channels = findall(isnothing.(ch1in2))
            data_dropped = drop(data, dim = 3, drop_idx = hanging_channels[1])
            push!(data_dropped, data_add)
            push!(data_dropped.stim_protocol, data_add.stim_protocol...)
        elseif any(isnothing.(ch2in1))
            hanging_channels = findall(isnothing.(ch2in1))
            data_dropped = drop(data_add, dim = 3, drop_idx = hanging_channels[1])
            push!(data, data_dropped)
            push!(data.stim_protocol, data_dropped.stim_protocol...)
        end
    else
        push!(data, data_add)
        push!(data.stimulus_protocol, data_add.stimulus_protocol)
    end
end

import Base.cat
function cat(data_cat::Vector{Experiment{T}}; dims = 1) where T <: Real
    println(data_cat |> length)
    data = deepcopy(data_cat[1])
    #data.data_array = cat(data)
    return data
end

"""
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
This is just a convinent way to write subtraction as a function
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