
abstract type Stimulus end

struct Flash <: Stimulus
    intensity::Real #The flash intensity of the flash
end
Flash() = Flash(0.0)

"""
A stimulus protocol contains information about the stimulus. 
    ### T <: Real The type declaration is the type of floating point numbers
    ## Options are: 
        1) type::Symbol - This is the label or type of stimulus. TODO: This will be defined in stimulus types
        2) sweep::Int64 - The sweep number the stimulus is contained on
        3) channel::Union{String, Int64} - The channel name or number which contains stimulus data
        4) index_range::Tuple{Int64, Int64} - The indexes that thew stimulus starts at and the ends at
        5) timestamps::Tuple{T, T} - The timestamps which the stimulus starts at and ends at. 
"""
mutable struct StimulusProtocol{T}
    type::Stimulus
    channelName::Union{String,Int64}
    timestamps::Vector{Tuple{T,T}}
    #index_range::Tuple{Int64,Int64}
end

StimulusProtocol() = StimulusProtocol(Flash(), "Nothing", [(0.0, 0.0)])
StimulusProtocol(stimulus_channel::String) = StimulusProtocol(Flash(), stimulus_channel, [(0.0, 0.0)])
StimulusProtocol(swp::Int64) = StimulusProtocol(Flash(), "Nothing", fill((0.0, 0.0), swp))
StimulusProtocol(stimulus_channel::String, swp::Int64) = StimulusProtocol(Flash(), stimulus_channel, fill((0.0, 0.0), swp))

getindex(stimulus_protocol::StimulusProtocol{T}, inds...) where T <: Real = stimulus_protocol.timestamps[inds...]
function setindex!(stimulus_protocol::StimulusProtocol{T}, X, I...) where T <: Real 
     #println(X)
     stimulus_protocol.timestamps[I...] = X
end

#Initialize an empty stimulus protocol

"""
this function utilizes all julia to extract ABF file data
"""

function extractStimulus(abfInfo::Dict{String,Any}; stimulus_name::String="IN 7", stimulus_threshold::Float64=2.5)
    dt = abfInfo["dataSecPerPoint"]
    stimulus_waveform = getWaveform(abfInfo, stimulus_name)
    #instantiate stimulus item
    stimuli = StimulusProtocol(stimulus_name, (size(abfInfo["data"], 1)))
    for swp in axes(abfInfo["data"], 1)
        stim_wave = stimulus_waveform[swp, :, 1] .> stimulus_threshold
        t1 = findfirst(stim_wave) * dt
        t2 = (findlast(stim_wave)+1) * dt
        stimuli[swp] = (t1,t2)
    end
    return stimuli
end

extractStimulus(abf_path::String; kwargs...) = extractStimulus(readABFInfo(abf_path); kwargs...)
