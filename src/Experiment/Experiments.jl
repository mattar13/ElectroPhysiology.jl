"""
    Experiment{T}

A mutable struct representing a physiological experiment.

## Fields

- `HeaderDict`: A dictionary containing header information for the experiment.
- `dt`: A `Real` value representing the time step between data points.
- `t`: A vector containing the time points of the experiment.
- `data_array`: A 3-dimensional array containing the experimental data.
- `chNames`: A vector of strings representing the names of the channels.
- `chUnits`: A vector of strings representing the units of the channels.
- `chTelegraph`: A vector of `Real` values representing the telegraph values of the channels.
- `stimulus_protocol`: A `StimulusProtocol{T}` object containing the stimulus protocol information.

## Constructors

- `Experiment(data_array::AbstractArray; data_idx = 2)`: Create an `Experiment` object from an input data array with an optional data index.
- `Experiment(time::Vector, data_array::Array{T, 3}) where T <: Real`: Create an `Experiment` object from an input time vector and data array.
"""
mutable struct Experiment{T}
    format::Symbol
    HeaderDict::Dict{String,Any}
    dt::T
    t::Vector{T}
    data_array::Array{T,3}
    chNames::Vector{String}
    chUnits::Vector{String}
    chTelegraph::Vector{T}
    stimulus_protocol::StimulusProtocol
end

#Make a basic constructor for the experiment
function Experiment(data_array::AbstractArray; data_idx = 2)
    Experiment(
        :Julia,
        Dict{String, Any}(), #Pass an empty header info
        1.0, 
        collect(1.0:size(data_array, data_idx)),
        data_array,
        ["Channel 1"],
        ["mV"],
        [1.0], 
        StimulusProtocol(size(data_array,1))
    )
end

function Experiment(time::Vector, data_array::Array{T, 3}) where T <: Real
    dt = time[2]-time[2]
    Experiment(
        :Julia,
        Dict{String, Any}(), #Pass an empty header info
        dt, 
        time,
        data_array,
        ["Channel 1"],
        ["mV"],
        [1.0], 
        StimulusProtocol(size(data_array,1))
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
    if size(exp, 1) == size(vals, 1) && size(exp, 3) == size(vals, 2) #trials and channels of divisor match
        println("Both trials and channels")
    elseif size(exp, 1) == size(vals, 1) && !(size(exp, 3) == size(vals, 2))# only channels match
        println("Only trials match")
    elseif !(size(exp, 1) == size(vals, 1)) && size(exp, 3) == size(vals, 2)# only channels match
        println("O")
    end
end

#Extending for Experiment
size(exp::Experiment) = size(exp.data_array)
size(exp::Experiment, dim::Int64) = size(exp.data_array, dim)

axes(exp::Experiment, dim::Int64) = axes(exp.data_array, dim)
length(exp::Experiment) = size(exp, 2)

#This is the basic functionality of getindex of experiments
getindex(exp::Experiment, trials::Union{Int64,UnitRange{Int64}}, timepoints::Union{Int64,UnitRange{Int64}}, channels::Union{Int64,UnitRange{Int64}}) = exp.data_array[trials, timepoints, channels]
#getindex(exp::Experiment, trials::StepRangeLen{Int64}, timepoints::StepRangeLen{Int64}, channels::StepRangeLen{Int64}) = exp[trials, timepoints, channels]

#This function allows you to enter in a timestamp and get the data value relating to it
function getindex(exp::Experiment, trials, timestamps::Union{Float64,StepRangeLen{Float64}}, channels)
    @assert timestamps[end] .< exp.t[end] "Highest timestamp too high"
    @assert timestamps[1] .>= exp.t[1] "Lowest timestamp too low"

    if length(timestamps) == 3 #This case may have happened if a full range was not provided. 
        timestamps = timestamps[1]:exp.dt:timestamps[end]
    end
    offset = -round(Int64, exp.t[1] / exp.dt)
    timepoints = (timestamps ./ exp.dt) .+ 1
    timepoints = (round.(Int64, timepoints))
    timepoints .+= offset
    exp[trials, timepoints, channels]
end

function getindex(exp::Experiment, trials, timestamps, channel::String)
    ch_idx = findall(exp.chNames .== channel)
    exp[trials, timestamps, ch_idx]
end

function getindex(exp::Experiment, trials, timestamps, channels::Vector{String})
    ch_idxs = map(channel -> findall(exp.chNames .== channel)[1], channels)
    exp[trials, timestamps, ch_idxs]
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

function abs(exp::Experiment)
    data_copy = deepcopy(exp)
    data_copy.data_array = abs.(exp.data_array) 
    return data_copy
end

function push!(nt::Experiment{T}, item::AbstractArray{T}; new_name="Unnamed") where {T<:Real}
    #All of these options assume the new data point length matches the old one
    if size(item, 2) == size(nt, 2) && size(item, 3) == size(nt, 3)
        #item = (new_trial, datapoints, channels)
        nt.data_array = cat(nt.data_array, item, dims=1)

    elseif size(item, 1) == size(nt, 2) && size(item, 2) == size(nt, 3)
        #item = (datapoints, channels) aka a single trial
        item = reshape(item, 1, size(item, 1), size(item, 2))
        nt.data_array = cat(nt.data_array, item, dims=1)

    elseif size(item, 1) == size(nt, 1) && size(item, 2) == size(nt, 2)
        #item = (trials, datapoints, new_channels) 
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

# These items all come from the channel properties
getSampleFreq(exp::Experiment) = 1/exp.dt

getChannelNames(exp::Experiment) = exp.chNames

getChannelUnite(exp::Experiment) = exp.chUnits

getTelegraph(exp::Experiment) = exp.chTelegraph


setIntensity(exp::Experiment, photons) = setIntensity(exp.stimulus_protocol, photons)

getIntensity(exp::Experiment) = getIntensity(exp.stimulus_protocol)
#these things can be found in the experiment header data if the data is in the .abf format
