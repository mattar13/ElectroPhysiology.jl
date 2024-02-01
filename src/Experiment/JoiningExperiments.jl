import Base: cat, hcat, vcat
function push!(exp::Experiment, a::AbstractArray; 
    dims = 1, 
    newChName = "New channel", newChUnits = "New units", newchGains = 1.0
)
    exp.data_array = cat(exp.data_array, a; dims = dims)
    exp.chNames = [exp.chNames..., newChName]
    exp.chUnits = [exp.chUnits..., newChUnits]
    exp.chGains = [exp.chGains..., newchGains]
end

"""
    concat(exp::Experiment{T}, exp_add::Experiment{T}; kwargs...) where {T}
    concat!(exp::Experiment{T}, exp_add::Experiment{T}; kwargs...) where {T}
Return a new `Experiment` object with `exp` concatenated with `exp_add` along the trials dimension.

# Arguments
- `exp`: An `Experiment` object containing the experimental exp.
- `exp_add`: Another `Experiment` object to be concatenated with the `exp`.

# Keyword Arguments
- `mode`: Specifies whether to pad or chop the exp if the sizes do not match (default: `:pad`).
- `position`: Specifies the position to pad or chop (default: `:post`).
- `verbose`: Prints information if set to true (default: false).
- `channel_mode`: Specifies how to handle extra channels (default: `:remove_extra`).

# Example
```julia
exp1 = Experiment(exp_array1)
exp2 = Experiment(exp_array2)
concatenated_exp = concat(exp1, exp2)
```julia
exp1 = Experiment(exp_array1)
exp2 = Experiment(exp_array2)
concat!(exp1, exp2)
```
"""

function concat!(exp::Experiment, exp2::Experiment;
    dims = 1, mode = :pad, position::Symbol=:post,
)
    if mode == :strict
        @assert size(exp) == size(exp_add)
    elseif mode == :pad || mode == :chop
        if size(exp, 2) > size(exp2, 2)
            #println("Original exp larger $(size(exp,2)) > $(size(exp_add,2))")
            n_vals = abs(size(exp, 2) - size(exp_add, 2))
            if mode == :pad
                pad!(exp2, n_vals; position=position)
            elseif mode == :chop
                chop!(exp, n_vals; position=position)
            end
        elseif size(exp, 2) < size(exp2, 2)
            #println("Original exp smaller $(size(exp,2)) < $(size(exp_add,2))")
            n_vals = abs(size(exp, 2) - size(exp_add, 2))
            if mode == :pad
                pad!(exp, n_vals; position=position)
            elseif mode == :chop
                chop!(exp2, n_vals; position=position)
            end
        end
    end
    exp.data_array = cat(exp.data_array, exp2.data_array, dims = dims)
    exp.chNames = [exp.chNames..., exp2.chNames...]
    exp.chUnits = [exp.chUnits..., exp.chUnits...]
    exp.chGains = [exp.chGains..., exp.chGains...]
    return 
end

function concat(exp::Experiment{T}, exp_add::Experiment{T}; mode::Symbol=:pad, position::Symbol=:post, kwargs...) where {T}
    new_exp = deepcopy(exp)
    concat!(new_exp, exp_add)
    return new_exp
end


"""
    match_channels(exp1::Experiment, exp2::Experiment)

Return two modified `Experiment` objects with their channels matched.

If the number of channels in `exp1` and `exp2` is not equal, this function will drop extra channels
from the `Experiment` object with more channels, making both objects have the same number of channels.

# Arguments
- `exp1`: An `Experiment` object containing the experimental exp.
- `exp2`: Another `Experiment` object to be matched with `exp1`.

# Returns
- `(exp1_modified, exp2_modified)`: A tuple containing the two modified `Experiment` objects with matched channels.

# Example
```julia
exp1 = Experiment(exp_array1)
exp2 = Experiment(exp_array2)
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

Subtract the exp of `exp2` from `exp1` and return a new `Experiment` object with the resulting exp.

This function will automatically match the channels of both `Experiment` objects if they do not match. 
If the channels do not match, it will drop the unmatching channels by default.

# Arguments
- `exp1`: An `Experiment` object containing the experimental exp.
- `exp2`: Another `Experiment` object containing the exp to be subtracted from `exp1`.

# Returns
- `exp`: A new `Experiment` object with the resulting exp after the subtraction.

# Example
```julia
exp1 = Experiment(exp_array1)
exp2 = Experiment(exp_array2)
result_exp = sub_exp(exp1, exp2)
```
"""
function sub_exp(exp1::Experiment, exp2::Experiment)
    if size(exp1) == size(exp2)
        exp = deepcopy(exp1)
        #return a new experiment? make a new exp
        exp.exp_array = exp1.exp_array - exp2.exp_array
        return exp
    else #If the channels don't match, we will automatically drop the unmatching one by default
        exp1, exp2 = match_channels(exp1, exp2)
        exp = deepcopy(exp1)
        #return a new experiment? make a new exp
        exp.exp_array = exp1.exp_array - exp2.exp_array
        return exp
    end
end

-(exp1::Experiment, exp2::Experiment) = sub_exp(exp1, exp2)