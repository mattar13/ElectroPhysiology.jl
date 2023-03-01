"""
The experiment data object. 
This contains all the data for the sweep. 
    ### DataType is defined by {T}
    ## The options are: 
        1) HeaderDict::Dict{String,Any} -> The information object that contains all the ABF info extracted from the binary file
        2) dt::T -> The time differential for the y axis. This is the inverse of the sampling rate collected by the digitizers
        3) t::Vector{T} -> The y axis and timestamps for each data point.
        4) data_array::Array{T,3} -> The data collected by the digitization process. The data array is sized by {sweeps, datapoints, channels}
        5) chNames::Vector{String} -> The names of each channel in string format
        6) chUnits::Vector{String} -> The units the data collected is in labeled by channel
        7) chTelegraph::Vector{T} -> The gain on each channel.
        8) stim_protocol::Vector{StimulusProtocol{T}} -> The stimulus protocols for each sweep. 
"""
mutable struct Experiment{T}
    HeaderDict::Dict{String,Any}
    dt::T
    t::Vector{T}
    data_array::Array{T,3}
    chNames::Vector{String}
    chUnits::Vector{String}
    chTelegraph::Vector{T}
    stim_protocol::Vector{StimulusProtocol{T}}
end

#Make a basic constructor for the experiment
function Experiment(data_array::AbstractArray; data_idx = 2)
    Experiment(
        Dict{String, Any}(), #Pass an empty header info
        1.0, 
        collect(1.0:size(data_array, data_idx)),
        data_array,
        ["Channel 1"],
        ["mV"],
        [1.0], 
        [StimulusProtocol()]
    )
end

function Experiment(time::Vector, data_array::Array{T, 3}) where T <: Real
    dt = time[2]-time[2]
    Experiment(
        Dict{String, Any}(), #Pass an empty header info
        dt, 
        time,
        data_array,
        ["Channel 1"],
        ["mV"],
        [1.0], 
        [StimulusProtocol()]
    )
end

import Base: +, -, *, / #Import these basic functions to help 
function +(exp::Experiment, val::Real) 
    data = deepcopy(exp)
    data.data_array = data.data_array .+ val
    return data
end

function -(exp::Experiment, val::Real)
    data = deepcopy(exp) 
    data.data_array = data.data_array .- val
    return data
end

function *(exp::Experiment, val::Real)
    data = deepcopy(exp) 
    data.data_array = data.data_array .* val
    return data
end

function /(exp::Experiment, val::Real)
    data = deepcopy(exp) 
    data.data_array = data.data_array ./ val
    return data
end



#if the value provided is different
function /(exp::Experiment{T}, vals::Matrix{T}) where {T<:Real}
    #This function has not been worked out yet
    if size(exp, 1) == size(vals, 1) && size(exp, 3) == size(vals, 2) #Sweeps and channels of divisor match
        println("Both Sweeps and channels")
    elseif size(exp, 1) == size(vals, 1) && !(size(exp, 3) == size(vals, 2))# only channels match
        println("Only sweeps match")
    elseif !(size(exp, 1) == size(vals, 1)) && size(exp, 3) == size(vals, 2)# only channels match
        println("O")
    end
end

#This is our inplace function for scaling. Division is done by multiplying by a fraction
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

import Base: size, axes, length, getindex, setindex, sum, copy, maximum, minimum, push!, cumsum, argmin, argmax
import Statistics.std

#Extending for Experiment
size(exp::Experiment) = size(exp.data_array)
size(exp::Experiment, dim::Int64) = size(exp.data_array, dim)

axes(exp::Experiment, dim::Int64) = axes(exp.data_array, dim)
length(exp::Experiment) = size(exp, 2)

#This is the basic functionality of getindex of experiments
getindex(exp::Experiment, sweeps::Union{Int64,UnitRange{Int64}}, timepoints::Union{Int64,UnitRange{Int64}}, channels::Union{Int64,UnitRange{Int64}}) = exp.data_array[sweeps, timepoints, channels]
#getindex(exp::Experiment, sweeps::StepRangeLen{Int64}, timepoints::StepRangeLen{Int64}, channels::StepRangeLen{Int64}) = exp[sweeps, timepoints, channels]

#This function allows you to enter in a timestamp and get the data value relating to it
function getindex(exp::Experiment, sweeps, timestamps::Union{Float64,StepRangeLen{Float64}}, channels)
    @assert timestamps[end] .< exp.t[end] "Highest timestamp too high"
    @assert timestamps[1] .>= exp.t[1] "Lowest timestamp too low"

    if length(timestamps) == 3 #This case may have happened if a full range was not provided. 
        timestamps = timestamps[1]:exp.dt:timestamps[end]
    end
    offset = -round(Int64, exp.t[1] / exp.dt)
    timepoints = (timestamps ./ exp.dt) .+ 1
    timepoints = (round.(Int64, timepoints))
    timepoints .+= offset
    exp[sweeps, timepoints, channels]
end

function getindex(exp::Experiment, sweeps, timestamps, channel::String)
    ch_idx = findall(exp.chNames .== channel)
    exp[sweeps, timestamps, ch_idx]
end

function getindex(exp::Experiment, sweeps, timestamps, channels::Vector{String})
    ch_idxs = map(channel -> findall(exp.chNames .== channel)[1], channels)
    exp[sweeps, timestamps, ch_idxs]
end

#Extending get index for Experiment
getindex(exp::Experiment, I...) = exp.data_array[I...]

setindex!(exp::Experiment, v, I...) = exp.data_array[I...] = v

sum(exp::Experiment; kwargs...) = sum(exp.data_array; kwargs...)

std(exp::Experiment; kwargs...) = std(exp.data_array; kwargs...)

copy(nt::Experiment) = Experiment([getfield(nt, fn) for fn in fieldnames(nt |> typeof)]...)

minimum(exp::Experiment; kwargs...) = minimum(exp.data_array; kwargs...)

maximum(exp::Experiment; kwargs...) = maximum(exp.data_array; kwargs...)

cumsum(exp::Experiment; kwargs...) = cumsum(exp.data_array; kwargs...)

argmin(exp::Experiment; dims=2) = argmin(exp.data_array, dims=dims)

argmax(exp::Experiment; dims=2) = argmax(exp.data_array, dims=dims)

function push!(nt::Experiment{T}, item::AbstractArray{T}; new_name="Unnamed") where {T<:Real}

    #All of these options assume the new data point length matches the old one
    if size(item, 2) == size(nt, 2) && size(item, 3) == size(nt, 3)
        #item = (new_sweep, datapoints, channels)
        nt.data_array = cat(nt.data_array, item, dims=1)

    elseif size(item, 1) == size(nt, 2) && size(item, 2) == size(nt, 3)
        #item = (datapoints, channels) aka a single sweep
        item = reshape(item, 1, size(item, 1), size(item, 2))
        nt.data_array = cat(nt.data_array, item, dims=1)

    elseif size(item, 1) == size(nt, 1) && size(item, 2) == size(nt, 2)
        #item = (sweeps, datapoints, new_channels) 
        nt.data_array = cat(nt.data_array, item, dims=3)
        #Because we are adding in a new channel, add the channel name
        push!(nt.chNames, new_name)

    else
        throw(error("File size incompatible with push!"))
    end
end

function push!(nt_push_to::Experiment, nt_added::Experiment)
    #push!(nt_push_to.filename, nt_added.filename...)
    push!(nt_push_to, nt_added.data_array)
end

import Base: reverse, reverse!

function reverse(exp::Experiment; kwargs...)
    data = deepcopy(exp)
    data.data_array = reverse(exp.data_array; kwargs...)
    return data
end

function reverse!(exp::Experiment; kwargs...)
    exp.data_array = reverse(exp.data_array; kwargs...)
end