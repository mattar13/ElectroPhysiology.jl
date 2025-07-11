#Types of experiments
abstract type EXPERIMENT end
abstract type ERG end
abstract type WHOLE_CELL end
abstract type TWO_PHOTON end

#Types of combination experiments
"""
    Experiment{FORMAT, T}

A mutable struct representing a physiological experiment.

## Fields

- `HeaderDict`: A dictionary containing header information for the experiment.
- `dt`: A `Real` value representing the time step between data points.
- `t`: A vector containing the time points of the experiment.
- `data_array`: A 3-dimensional array containing the experimental data.
- `chNames`: A vector of strings representing the names of the channels.
- `chUnits`: A vector of strings representing the units of the channels.
- `chGains`: A vector of `Real` values representing the Gains values of the channels.

## Constructors

- `Experiment(data_array::AbstractArray; data_idx = 2)`: Create an `Experiment` object from an input data array with an optional data index.
- `Experiment(time::Vector, data_array::Array{T, 3}) where T <: Real`: Create an `Experiment` object from an input time vector and data array.


NOTE stimulus protocols are now going into the HeaderDict Object
"""
mutable struct Experiment{FORMAT, T}
    HeaderDict::Dict{String,Any}
    dt::T
    t::Vector{T}
    data_array::Array{T,3}
    chNames::Vector{String}
    chUnits::Vector{String}
    chGains::Vector{T}
end

#This constructor accounts for the new format type
function Experiment(FORMAT::Type, HeaderDict::Dict{String,Any},
    dt::T, t::Vector{T}, data_array::Array{T,3},
    chNames::Vector{String}, chUnits::Vector{String}, chGains::Vector{T},
) where T<: Real
    return Experiment{FORMAT, T}(HeaderDict, dt, t, data_array, chNames, chUnits, chGains)
end

#The default behavior
function Experiment(HeaderDict::Dict{String,Any},
    dt::T, t::Vector{T}, data_array::Array{T,3},
    chNames::Vector{String}, chUnits::Vector{String}, chGains::Vector{T},
) where T<: Real
    return Experiment{EXPERIMENT, T}(HeaderDict, dt, t, data_array, chNames, chUnits, chGains)
end

#Make a basic constructor for the experiment
function Experiment(FORMAT::Type, data_array::AbstractArray{T}; data_idx = 2) where T <: Real
    Experiment{FORMAT, T}(
        Dict{String, Any}(), #Pass an empty header info
        1.0, 
        collect(1.0:size(data_array, data_idx)),
        data_array,
        ["Channel 1"],
        ["mV"],
        [1.0], 
    )
end

function Experiment(FORMAT::Type, time::Vector, data_array::Array{T, 3}) where T <: Real
    dt = time[2]-time[2]
    Experiment{FORMAT, T}(
        Dict{String, Any}(), #Pass an empty header info
        dt, 
        time,
        data_array,
        ["Channel 1"],
        ["mV"],
        [1.0], 
    )
end

#Make a basic constructor for the experiment
function Experiment(data_array::AbstractArray{T}; data_idx = 2) where T <: Real
    Experiment{EXPERIMENT, T}(
        Dict{String, Any}(), #Pass an empty header info
        1.0, 
        collect(1.0:size(data_array, data_idx)),
        data_array,
        ["Channel 1"],
        ["mV"],
        [1.0], 
    )
end

function Experiment(time::Vector, data_array::Array{T, 3}) where T <: Real
    dt = time[2]-time[2]
    Experiment{EXPERIMENT, T}(
        Dict{String, Any}(), #Pass an empty header info
        dt, 
        time,
        data_array,
        ["Channel 1"],
        ["mV"],
        [1.0], 
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

function /(exp::Experiment, exp2::Experiment)
    exp_copy = deepcopy(exp)
    exp_copy.data_array = exp.data_array ./ exp2.data_array
    return exp_copy
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

copy(nt::Experiment{F, T}) where {F, T}= Experiment{F, T}([getfield(nt, fn) for fn in fieldnames(nt |> typeof)]...)

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

import Statistics: mean

mean(exp::Experiment; dims = 2) = mean(exp.data_array, dims = dims)

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
"""
    getSampleFreq(exp::Experiment)

Get the sampling frequency of the experiment in Hz.

# Arguments
- `exp`: An `Experiment` object

# Returns
- The sampling frequency calculated as 1/dt where dt is the time step between data points

# Example
```julia
exp = Experiment(data_array)
fs = getSampleFreq(exp)  # Returns sampling frequency in Hz
```
"""
getSampleFreq(exp::Experiment) = 1/exp.dt

"""
    getChannelNames(exp::Experiment)

Get the names of all channels in the experiment.

# Arguments
- `exp`: An `Experiment` object

# Returns
- Vector of strings containing the names of all channels

# Example
```julia
exp = Experiment(data_array)
channel_names = getChannelNames(exp)
```
"""
getChannelNames(exp::Experiment) = exp.chNames

"""
    getChannelUnite(exp::Experiment)

Get the units of measurement for all channels in the experiment.

# Arguments
- `exp`: An `Experiment` object

# Returns
- Vector of strings containing the units for each channel

# Example
```julia
exp = Experiment(data_array)
channel_units = getChannelUnite(exp)
```
"""
getChannelUnite(exp::Experiment) = exp.chUnits

"""
    getGains(exp::Experiment)

Get the gain values for all channels in the experiment.

# Arguments
- `exp`: An `Experiment` object

# Returns
- Vector of real numbers containing the gain values for each channel

# Example
```julia
exp = Experiment(data_array)
channel_gains = getGains(exp)
```
"""
getGains(exp::Experiment) = exp.chGains

"""
    round_nanosecond(time::T) where {T<:Real}
    round_nanosecond(time_series::Vector{T}) where {T<:Real}

Round a time value or vector of time values to the nearest nanosecond.

# Arguments
- `time`: A real number representing time in seconds
- `time_series`: A vector of real numbers representing time points

# Returns
- A `Nanosecond` value or vector of `Nanosecond` values

# Example
```julia
time_ns = round_nanosecond(1.5)  # Returns Nanosecond(1500000000)
times_ns = round_nanosecond([1.5, 2.5])  # Returns [Nanosecond(1500000000), Nanosecond(2500000000)]
```
"""
round_nanosecond(time::T) where {T<:Real} = Nanosecond(round(Int64, time * 1e9))
round_nanosecond(time_series::Vector{T}) where {T<:Real} = map(time -> round_nanosecond(time), time_series)

"""
    getRealTime(exp::Experiment)

Get the real-world timestamps for all time points in the experiment.

# Arguments
- `exp`: An `Experiment` object

# Returns
- Vector of `DateTime` values representing the real-world time for each data point

# Example
```julia
exp = Experiment(data_array)
real_times = getRealTime(exp)
```
"""
getRealTime(exp::Experiment) = exp.HeaderDict["FileStartDateTime"] .+ round_nanosecond(exp.t)

