"""
    getWaveform(abfInfo::Dict{String, Any}, trial, channel; channel_type) 

extracts a waveform from the data, digital stimuli, or analog stimuli

...
#Arguments
    NEEDED: 
    -'abfInfo': A dictionary containing all info parsed from the the .abf file
    -'trial': trial/trials that will be read from the data or stimuli
        This is a Int64 number or a list of numbers that represents the index/indexes of the trial
    -'channel': The channel which is set to be the explicit stimulus 
        This can either be a channel index, or a string
    OPTIONS:
    -'channel_type': This represents where the waveform will come from. There are 3 options:
        data -> this is the actual data of the file
        analog -> this is the analog stimulus of the file
        digital -> this is the digital stimulus of the file
...
"""
function getWaveform(abf_info::Dict{String,Any}, trial::Int64, channel::Int64;
    channel_type = :analog
)
    if channel_type == :data
        #rather than extracting the digital or analog stimuli, we use the actual ADC
        return abf_info["data"][trial, :, channel]
    elseif channel_type == :analog
        epochTable = abf_info["EpochTableByChannel"][channel] #Load the channel
        epoch = epochTable.epochWaveformBytrial[trial] #Load the trial
        return getAnalogWaveform(epoch)
    elseif channel_type == :digital
        activeDACch = abf_info["ProtocolSection"]["nActiveDACChannel"] + 1
        epochTable = abf_info["EpochTableByChannel"][activeDACch] #Load the location of the digital stim
        epoch = epochTable.epochWaveformBytrial[trial] #Load the trial
        return getDigitalWaveform(epoch, channel) #Load the digital channel
        #the analog channel containing the data is located here
    end
end

function getWaveform(abf::Dict{String,Any}, trial::Union{Vector{Int64},Int64}, channel::String;
    warn_bad_channel = true
)
    #first we check to see if the channel name is in the adc names
    adc_idx = findall(x -> channel == x, abf["adcNames"])
    dac_idx = findall(x -> channel == x, abf["dacNames"])
    if !isempty(adc_idx)
        return getWaveform(abf, trial, adc_idx[1]; channel_type = :data)
    elseif !isempty(dac_idx)
        return getWaveform(abf, trial, dac_idx[1])
    else
        channel_ID = lowercase(channel[1:end-1])
        channel_ID = split(channel_ID, " ")[1] |> string
        channel_num = tryparse(Int64, channel[end] |> string)
        if channel_ID == "d" || channel_ID == "dig" || channel_ID == "digital"
            return getWaveform(abf, trial, channel_num + 1; channel_type = :digital)
        elseif channel_ID == "an" || channel_ID == "a" || channel_ID == "ana" || channel_ID == "analog"
            return getWaveform(abf, trial, channel_num + 1)
        elseif warn_bad_channel
            @warn begin
                "
    Format [$channel] is invalid
    
    Please use one of these formats:

    1) An ADC name from one of these: [$(map(x -> "$x, ", abf["adcNames"]) |>join)]   
    2) Analog: [A, An , Ana  , Analog ]
    3) A DAC name from one of these: [$(map(x -> "$x, ", abf["dacNames"]) |>join)]
    4) Digital: [D , Dig , Digital]

    "
            end
            #throw("Improper channel ID")
            return nothing #This may be because of a bad channel
        else
            return nothing
        end
    end
end

function getWaveform(abf::Dict{String,Any}, trial::Int64, channels::Vector{T}; kwargs...) where {T}
    waveforms = zeros(1, abf["trialPointCount"], channels |> length)
    for (i, channel) in enumerate(channels)
        waveforms[1, :, i] = getWaveform(abf, trial, channel; kwargs...)
    end
    return waveforms
end

function getWaveform(abf::Dict{String,Any}, trials::Vector{Int64}, channel::T; kwargs...) where {T}
    waveforms = zeros(trials |> length, abf["trialPointCount"], 1)
    for (i, trial) in enumerate(trials)
        waveforms[i, :, 1] = getWaveform(abf, trial, channel; kwargs...)
    end
    return waveforms
end

#In this case, channels can come as a string or a int, it will get passes to the correct place
function getWaveform(abf::Dict{String,Any}, trials::Vector{Int64}, channels::Vector{T}; kwargs...) where {T}
    waveforms = zeros(trials |> length, abf["trialPointCount"], channels |> length)
    for (i, trial) in enumerate(trials), (j, channel) in enumerate(channels)
        waveforms[i, :, j] .= getWaveform(abf, trial, channel; kwargs...)
    end
    return waveforms
end

function getWaveform(abf::Dict{String,Any}, channel::String; kwargs...)
    #This function gets called to iterate through all trials
    waveforms = zeros(abf["trialCount"], abf["trialPointCount"], 1)
    for i = 1:abf["trialCount"]
        waveforms[i, :, 1] .= getWaveform(abf, i, channel; kwargs...)
    end
    return waveforms
end

function getWaveform(abf::Dict{String,Any}, channels::Vector{String}; kwargs...)
    #This function gets called to iterate through all trials
    waveforms = zeros(abf["trialCount"], abf["trialPointCount"], length(channels))
    for i = 1:abf["trialCount"], (j, channel) in enumerate(channels)
        #we need to protect against mismatched channels
        waveform = getWaveform(abf, i, channel; kwargs...)
        if !isnothing(waveform)
            waveforms[i, :, j] .= waveform
        else
            println("our error lies here")
        end
    end
    return waveforms
end

function getWaveform(abf::Dict{String,Any}, channel::Int64; kwargs...)
    waveforms = zeros(abf["trialCount"], abf["trialPointCount"], 1)
    for i = 1:abf["trialCount"]
        waveforms[i, :, 1] = getWaveform(abf, i, channel; kwargs...)
    end
    return waveforms
end
