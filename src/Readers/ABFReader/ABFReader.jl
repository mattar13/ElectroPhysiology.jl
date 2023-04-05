function extract_channel_indices(channels, HeaderDict)
    if isa(channels, Vector{String})
         return findall(ch -> ch ∈ channels, HeaderDict["adcNames"])
    elseif isa(channels, Vector{Int64})
         return channels
    elseif channels == -1
         return HeaderDict["channelList"]
    else
         return channels
    end
end

function extract_channel_info(ch_idxs, HeaderDict)
    ch_names = Vector{String}(HeaderDict["adcNames"][ch_idxs])
    ch_units = Vector{String}(HeaderDict["adcUnits"][ch_idxs])
    ch_telegraph = Vector{Float64}(HeaderDict["fTelegraphAdditGain"][ch_idxs])
    return ch_names, ch_units, ch_telegraph
end

function extract_data(sweeps, channels, ch_names, HeaderDict, warn_bad_channel)
    if sweeps == -1 && channels == -1
         return HeaderDict["data"]
    elseif sweeps == -1 && channels != -1
         return getWaveform(HeaderDict, ch_names; warn_bad_channel=warn_bad_channel)
    elseif sweeps != -1 && channels == -1
         return HeaderDict["data"][sweeps, :, :]
    elseif sweeps != -1 && channels != -1
    data = getWaveform(HeaderDict, ch_names; warn_bad_channel=warn_bad_channel)
         return data[sweeps, :, :]
    end
end

function flatten_data(data)
    n_size = size(data)
    reshape_data = permutedims(data, (3, 2, 1))
    reshape_data = reshape(reshape_data, 1, n_size[3], :)
    return permutedims(reshape_data, (1, 3, 2))
end

function prepare_time_info(data, HeaderDict, time_unit)
    dt = HeaderDict["dataSecPerPoint"]
    idxs = collect(0:size(data,2)-1)
    t = idxs .* dt
    if time_unit == :ms
         dt = 1000
         t .= 1000
    end
    return dt, t
end

function extract_stimulus_protocol(HeaderDict, stimulus_name, stimulus_threshold)
    if isnothing(stimulus_name)
         return StimulusProtocol("Nothing")
    else
         return extractStimulus(HeaderDict; stimulus_name = stimulus_name, stimulus_threshold = stimulus_threshold)
    end
end

function average_data_and_protocol(data, stimulus_protocol)
    data = sum(data, dims=1) / size(data, 1)
    stimulus_protocol_first_vals = stimulus_protocol[1]
    stimulus_protocol = StimulusProtocol(stimulus_name)
    stimulus_protocol[1] = stimulus_protocol_first_vals
    return data, stimulus_protocol
end     

include("ByteMaps.jl") #These functions deal with the bytemap extractions
include("Epochs.jl") #These functions deal with the Epochs
include("WaveformExtraction.jl") #This imports the bytemaps for extracting the waveforms
include("ReadHeaders.jl")

#println("ABF utilites imported")
"""
    readABF(::Type{T}, abf_data::Union{String,Vector{UInt8}};
        sweeps::Union{Int64,Vector{Int64}}=-1,
        channels::Union{Int64, Vector{String}}=["Vm_prime", "Vm_prime4"],
        average_sweeps::Bool=false,
        stimulus_name::Union{String, Vector{String}, Nothing}="IN 7",
        stimulus_threshold::T=2.5,
        warn_bad_channel=false,
        flatten_episodic::Bool=false,
        time_unit=:s,
    ) where {T<:Real}

Read an Axon Binary File (ABF) and return an `Experiment` object. The function extracts data
for the specified sweeps and channels, and optionally averages sweeps or flattens episodic data.

# Arguments
- `abf_data`: A `String` representing the ABF file path or a `Vector{UInt8}` containing the ABF file content.
- `sweeps`: An `Int64` or a `Vector{Int64}` specifying the sweeps to extract. Default is -1 (all sweeps).
- `channels`: An `Int64` or a `Vector{String}` specifying the channels to extract. Default is ["Vm_prime", "Vm_prime4"].
- `average_sweeps`: A `Bool` specifying whether to average the sweeps. Default is `false`.
- `stimulus_name`: A `String`, `Vector{String}`, or `Nothing` specifying the stimulus name(s). Default is "IN 7".
- `stimulus_threshold`: A threshold value of type `T` for the stimulus. Default is 2.5.
- `warn_bad_channel`: A `Bool` specifying whether to warn if a channel is improper. Default is `false`.
- `flatten_episodic`: A `Bool` specifying whether to flatten episodic stimulation to be continuous. Default is `false`.
- `time_unit`: A `Symbol` specifying the time unit. Default is `:s` (seconds).

# Returns
- An `Experiment` object containing the extracted data, along with metadata.

# Example
```julia
exp = readABF(Float32, "path/to/abf_file.abf")
```
"""
function readABF(::Type{T}, abf_data::Union{String,Vector{UInt8}};
    sweeps::Union{Int64,Vector{Int64}}=-1,
    channels::Union{Int64, Vector{String}}=["Vm_prime", "Vm_prime4"],
    average_sweeps::Bool=false,
    stimulus_name::Union{String, Vector{String}, Nothing}="IN 7",  #One of the best places to store digital stimuli
    stimulus_threshold::T=2.5, #This is the normal voltage rating on digital stimuli
    warn_bad_channel=false, #This will warn if a channel is improper
    flatten_episodic::Bool=false, #If the stimulation is episodic and you want it to be continuous
    time_unit=:s, #The time unit is s, change to ms
) where {T<:Real}
    # Read ABF header information
    HeaderDict = readABFInfo(abf_data)

    # Extract channel indices based on the input
    ch_idxs = extract_channel_indices(channels, HeaderDict)

    # Extract channel information
    ch_names, ch_units, ch_telegraph = extract_channel_info(ch_idxs, HeaderDict)

    # Extract data based on the specified sweeps and channels
    data = extract_data(sweeps, channels, ch_names, HeaderDict, warn_bad_channel)

    # Flatten episodic data if requested
    if flatten_episodic
        data = flatten_data(data)
    end

    # Prepare time information
    dt, t = prepare_time_info(data, HeaderDict, time_unit)

    stimulus_protocol = extract_stimulus_protocol(HeaderDict, stimulus_name, stimulus_threshold)

    # Average sweeps if requested
    if average_sweeps
        data, stimulus_protocol = average_data_and_protocol(data, stimulus_protocol)
    end
    
    # Return Experiment object
    return Experiment(HeaderDict, dt, t, data, ch_names, ch_units, ch_telegraph, stimulus_protocol)end

readABF(abf_path::Union{String,Vector{UInt8}}; kwargs...) = readABF(Float64, abf_path; kwargs...)

function readABF(filenames::AbstractArray{String}; average_sweeps_inner=true, kwargs...)
    #println("Currently stable")
    #println("Data length is $(size(filenames, 1))")
    data = readABF(filenames[1]; average_sweeps=average_sweeps_inner, kwargs...)
    #IN this case we want to ensure that the stim_protocol is only 1 stimulus longer
    for filename in filenames[2:end]
        data_add = readABF(filename; average_sweeps=average_sweeps_inner, kwargs...)
        #println(size(data_add))
        concat!(data, data_add; kwargs...)
        #println(size(data, 1))
    end

    return data
end


"""
==================================================================
Parsing Function

This function finds all files with the suffix .abf 
==================================================================
    [abf_files] = parseABF(filename; KWARGS)


ARGS:
type::Type = The type in which all data will be converted to. Defaults to Float64. 
filename::String = The filename that will be read

KWARGS:
extenstion::String
    [DEFAULT, ".abf"]
    The name of the extension.

"""
function parseABF(super_folder::String; extension::String=".abf")
    file_list = String[]
    for (root, dirs, files) in walkdir(super_folder)
        for file in files
            if file[end-3:end] == extension
                path = joinpath(root, file)
                try
                    push!(file_list, path)
                catch
                    println(path)
                end
            end
        end
    end
    file_list
end

const BLOCKSIZE = 512
function saveABF(exp::Experiment{T}, filename;) where {T<:Real}
    println(exp.chNames)
    path = joinpath(exp.HeaderDict["abfFolder"], exp.HeaderDict["abfPath"]) #This is the path of one of the og files
    Header = exp.HeaderDict #Pull out header information
    dataPointCount = Header["dataPointCount"] #Read the datapoint count
    dataType = Header["dataType"]
    bytesPerPoint = sizeof(dataType)
    dataStart = Header["dataByteStart"]
    dataGain = Header["dataGain"]
    dataOffset = Header["dataOffset"]
    #Determine the dimensions of the data you are writing
    swpN, dataN, chN = size(exp)
    dataArray = exp.data_array
    dataArray = permutedims(dataArray, (3, 2, 1)) #Reorganize the data to ch, data, swp
    dataArray = reshape(dataArray, chN, dataN * swpN)
    dataArray = dataArray ./ dataGain
    dataArray = dataArray .- dataOffset
    try
        dataArray = vec(Int16.(dataArray)) #Sometimes the numbers won't accurately convert
        dataArray = reinterpret(UInt8, dataArray)
    catch
        #println("Numbers won't convert")
        dataArray = round.(Int64, dataArray)
        dataArray = vec(Int16.(dataArray)) #Sometimes the numbers won't accurately convert
        dataArray = reinterpret(UInt8, dataArray)
    end

    #get the channel order
    ABFINFO = readABFInfo(path)
    println(ABFINFO["adcNames"])
    
    dat = read(path)
    #dat[dataStart:dataStart+dataPointCount*bytesPerPoint-1]
    dat[dataStart:dataStart+dataPointCount*bytesPerPoint-1] = dataArray
    write(filename, dat)
    println("Data written")
end