function extract_channel_indices(channels, HeaderDict)
    if isa(channels, Vector{String})
         return findall(ch -> ch ∈ channels, HeaderDict["adcNames"])
    elseif isa(channels, String)
        return findall(ch -> ch == channels, HeaderDict["adcNames"])
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

function extract_data(trials, channels, ch_names, HeaderDict, warn_bad_channel)
    if trials == -1 && channels == -1
         return HeaderDict["data"]
    elseif trials == -1 && channels != -1
         return getWaveform(HeaderDict, ch_names; warn_bad_channel=warn_bad_channel)
    elseif trials != -1 && channels == -1
         return HeaderDict["data"][trials, :, :]
    elseif trials != -1 && channels != -1
    data = getWaveform(HeaderDict, ch_names; warn_bad_channel=warn_bad_channel)
         return data[trials, :, :]
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
    return data, stimulus_protocol[1]
end     

include("ByteMaps.jl") #These functions deal with the bytemap extractions
include("Epochs.jl") #These functions deal with the Epochs
include("WaveformExtraction.jl") #This imports the bytemaps for extracting the waveforms
include("ReadHeaders.jl")

#println("ABF utilites imported")
"""
    readABF(::Type{T}, FORMAT::Type, abf_data::Union{String,Vector{UInt8}};
        trials::Union{Int64,Vector{Int64}}=-1,
        channels::Union{Int64, String, Vector{String}, Nothing}=nothing,
        average_trials::Bool=false,
        stimulus_name::Union{String, Vector{String}, Nothing}=nothing,
        stimulus_threshold::T=2.5,
        warn_bad_channel=false,
        flatten_episodic::Bool=false,
        time_unit=:s
    ) where {T<:Real}

Read and parse Axon Binary Format (ABF) files, returning an Experiment object containing the electrophysiology data
and associated metadata.

# Arguments
- `T`: The numeric type for the data (e.g., Float32, Float64)
- `FORMAT`: The format type of the experiment
- `abf_data`: Either a file path to the ABF file or raw ABF data as a byte vector

# Optional Arguments
- `trials`: Trial selection
    - `-1`: All trials (default)
    - `Int64`: Single trial
    - `Vector{Int64}`: Multiple specific trials
- `channels`: Channel selection
    - `nothing`: All channels (default)
    - `Int64`: Single channel by index
    - `String`: Single channel by name
    - `Vector{String}`: Multiple channels by name
- `average_trials`: Whether to average across trials (default: false)
- `stimulus_name`: Name of stimulus channel(s)
    - `nothing`: No stimulus (default)
    - `String`: Single stimulus channel
    - `Vector{String}`: Multiple stimulus channels
- `stimulus_threshold`: Threshold for detecting digital stimulus events (default: 2.5)
- `warn_bad_channel`: Whether to warn about invalid channels (default: false)
- `flatten_episodic`: Whether to flatten episodic data into continuous data (default: false)
- `time_unit`: Time unit for the data
    - `:s`: Seconds (default)
    - `:ms`: Milliseconds

# Returns
- An Experiment object containing:
    - Raw data array
    - Time vector
    - Channel names and units
    - Stimulus protocol (if specified)
    - Original ABF metadata in HeaderDict

# Channel Naming Conventions
1. ADC channels: Use exact names from recording (e.g., "Vm_prime", "IN 7")
2. Analog channels: "A1", "A2", etc. or "Analog 1", "Analog 2", etc.
3. Digital channels: "D1", "D2", etc. or "Digital 1", "Digital 2", etc.

# Examples
```julia
# Basic usage - read all channels and trials
exp = readABF(Float32, "path/to/file.abf")

# Read specific channels and average trials
exp = readABF(Float32, "path/to/file.abf",
    channels=["Vm_prime", "IN 7"],
    average_trials=true)

# Read with stimulus extraction
exp = readABF(Float32, "path/to/file.abf",
    stimulus_name="Digital 1",
    stimulus_threshold=2.5)

# Read specific trials and flatten episodic data
exp = readABF(Float32, "path/to/file.abf",
    trials=1:5,
    flatten_episodic=true)

# Read with time in milliseconds
exp = readABF(Float32, "path/to/file.abf",
    time_unit=:ms)
```

See also: [`parseABF`](@ref), [`getWaveform`](@ref), [`extractStimulus`](@ref)
"""
function readABF(::Type{T}, FORMAT::Type, abf_data::Union{String,Vector{UInt8}};
    trials::Union{Int64,Vector{Int64}}=-1,
    channels::Union{Int64, String, Vector{String}, Nothing}=nothing,
    average_trials::Bool=false,
    stimulus_name::Union{String, Vector{String}, Nothing}=nothing,
    stimulus_threshold::T=2.5,
    warn_bad_channel=false,
    flatten_episodic::Bool=false,
    time_unit=:s
) where {T<:Real}
    # Read ABF header information
    HeaderDict = readABFInfo(abf_data, flatten_episodic = flatten_episodic)

    # Extract channel indices based on the input
    if isa(channels, Vector{String}) || isa(channels, String)
        ch_idxs = extract_channel_indices(channels, HeaderDict)
    elseif isnothing(channels)
        ch_idxs = eachindex(HeaderDict["adcNames"]) |> collect
    end
    # Extract channel information
    ch_names, ch_units, ch_telegraph = extract_channel_info(ch_idxs, HeaderDict)

    # Extract data based on the specified trials and channels
    data = extract_data(trials, channels, ch_names, HeaderDict, warn_bad_channel)

    # Flatten episodic data if requested
    #if flatten_episodic
    #    data = flatten_data(data)
    #end

    # Prepare time information
    dt, t = prepare_time_info(data, HeaderDict, time_unit)

    if !isnothing(stimulus_name)
        HeaderDict["StimulusProtocol"] = stimulus_protocol = extractStimulus(HeaderDict, stimulus_name; stimulus_threshold = stimulus_threshold)
        # Set flash intensity from the filename as early as possible
        if isa(stimulus_protocol.type, Vector{Flash}) && haskey(HeaderDict, "abfPath")
            try
                set_flash_intensity!(stimulus_protocol, basename(HeaderDict["abfPath"]))
            catch
            end
        end
    else
        #stimulus_protocol = StimulusProtocol() #I think there should be easier ways to do this but here we are
    end
    
    if average_trials
        if haskey(HeaderDict, "StimulusProtocol")
            new_stimulus_protocol = deepcopy(HeaderDict["StimulusProtocol"])
            if !isempty(new_stimulus_protocol.timestamps) && !isempty(new_stimulus_protocol.sweeps)
                first_sweep = new_stimulus_protocol.sweeps[1]
                idxs = findall(==(first_sweep), new_stimulus_protocol.sweeps)
                new_stimulus_protocol.timestamps = new_stimulus_protocol.timestamps[idxs]
                new_stimulus_protocol.sweeps = fill(1, length(idxs))
                if isa(new_stimulus_protocol.type, Vector)
                    new_stimulus_protocol.type = new_stimulus_protocol.type[idxs]
                end
            end
            HeaderDict["StimulusProtocol"] = new_stimulus_protocol
        end
        data = sum(data, dims=1) / size(data, 1)
    end
    # Average trials if requested
    
    # Return Experiment object
    return Experiment{FORMAT, T}(HeaderDict, dt, t, data, ch_names, ch_units, ch_telegraph)
end

readABF(abf_path::Union{String,Vector{UInt8}}; kwargs...) = readABF(Float64, WHOLE_CELL, abf_path; kwargs...)

function readABF(filenames::AbstractArray{String};
    average_trials_inner=true,
    sort_by_date=true,
    align_by_stimulus::Bool=false,
    t_pre::Union{Nothing,Real}=nothing,
    t_post::Union{Nothing,Real}=nothing,
    stimulus_index::Int64=1,
    pad_value=nothing,
    kwargs...
)
    if isempty(filenames)
        throw(ArgumentError("No ABF filenames were provided."))
    end

    #println("Currently stable")
    #println("Data length is $(size(filenames, 1))")
    data = readABF(filenames[1]; average_trials=average_trials_inner, kwargs...)
    all_dates = [data.HeaderDict["FileStartDateTime"]]
    all_paths = [data.HeaderDict["abfPath"]]
    file_trial_counts = [size(data, 1)]
    #IN this case we want to ensure that the stim_protocol is only 1 stimulus longer
    for filename in filenames[2:end]
        data_add = readABF(filename; average_trials=average_trials_inner, kwargs...)
        #println(size(data_add))
        concat!(data, data_add)
        if haskey(data.HeaderDict, "StimulusProtocol") && haskey(data_add.HeaderDict, "StimulusProtocol")
            push!(data.HeaderDict["StimulusProtocol"], data_add.HeaderDict["StimulusProtocol"])
        elseif !haskey(data.HeaderDict, "StimulusProtocol") && haskey(data_add.HeaderDict, "StimulusProtocol")
            data.HeaderDict["StimulusProtocol"] = deepcopy(data_add.HeaderDict["StimulusProtocol"])
        end
        push!(all_dates, data_add.HeaderDict["FileStartDateTime"])
        push!(all_paths, data_add.HeaderDict["abfPath"])
        push!(file_trial_counts, size(data_add, 1))
        #println(size(data, 1))
    end
    #Here we can add some things that might be useful across all experiments
    data.HeaderDict["FileStartDateTime"] = all_dates
    data.HeaderDict["abfPath"] = all_paths
    if sort_by_date
        #println("Sort idxs")
        date_idxs = sortperm(all_dates)

        trial_ranges = UnitRange{Int64}[]
        start_idx = 1
        for n_trials in file_trial_counts
            stop_idx = start_idx + n_trials - 1
            push!(trial_ranges, start_idx:stop_idx)
            start_idx = stop_idx + 1
        end
        trial_idxs = Int64[]
        for file_idx in date_idxs
            append!(trial_idxs, trial_ranges[file_idx])
        end
        data.data_array = data[trial_idxs, :, :]

        if haskey(data.HeaderDict, "StimulusProtocol")
            stim = data.HeaderDict["StimulusProtocol"]
            old_to_new_trial = Dict{Int64,Int64}(old => new for (new, old) in enumerate(trial_idxs))
            keep_idxs = findall(swp -> haskey(old_to_new_trial, swp), stim.sweeps)
            if !isempty(keep_idxs)
                stim.timestamps = stim.timestamps[keep_idxs]
                stim.sweeps = [old_to_new_trial[stim.sweeps[idx]] for idx in keep_idxs]
                sort_idxs = sortperm(eachindex(stim.sweeps), by=i -> (stim.sweeps[i], i))
                stim.timestamps = stim.timestamps[sort_idxs]
                stim.sweeps = stim.sweeps[sort_idxs]
            end
        end

        data.HeaderDict["FileStartDateTime"] = all_dates[date_idxs]
        data.HeaderDict["abfPath"] = all_paths[date_idxs]
    end

    if align_by_stimulus
        if isnothing(t_pre) || isnothing(t_post)
            throw(ArgumentError("When align_by_stimulus=true, both t_pre and t_post must be provided."))
        end
        pad_val = isnothing(pad_value) ? zero(eltype(data.data_array)) : eltype(data.data_array)(pad_value)
        align_to_stimulus!(data; t_pre=t_pre, t_post=t_post, stimulus_index=stimulus_index, pad_value=pad_val)
    end

    return data
end


"""
    parseABF(super_folder::String; extension::String=".abf")

Recursively search for ABF files in a directory and its subdirectories.

# Arguments
- `super_folder`: Root directory to start the search
- `extension`: File extension to search for (default: ".abf")

# Returns
- Vector of file paths to all found ABF files

# Examples
```julia
# Find all ABF files in current directory and subdirectories
files = parseABF(".")

# Find files with custom extension
files = parseABF("data/", extension=".dat")

# Process multiple files
for file in parseABF("experiment_data/")
    exp = readABF(Float32, file)
    process_experiment(exp)
end
```

# Throws
- `ArgumentError`: If no matching files are found in the directory

See also: [`readABF`](@ref)
"""
function parseABF(super_folder::String; extension::String=".abf")
    # Initialize an empty array to store the matching file paths
    file_list = String[]
    # Iterate through the directories and files in super_folder and its subdirectories
    for (root, dirs, files) in walkdir(super_folder)
        for file in files
            # Check if the file extension matches the desired extension
            if file[end-3:end] == extension
                # If it matches, join the root path and the file name to create the full path
                path = joinpath(root, file)
                try
                    # Add the file path to the file_list array
                    push!(file_list, path)
                catch
                    # Print the path in case of any errors while adding it to the file_list
                    println(path)
                end
            end
        end
    end

    # Check if the file_list is empty
    if isempty(file_list)
        # If it is empty, throw an error indicating no files were found
        throw(ArgumentError("No files found in directory $super_folder matching extension $extension"))
    else
        # If it is not empty, return the file_list
        return file_list
    end
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

function create_signal_waveform!(exp::Experiment, channel::String)
    wvform = getWaveform(exp.HeaderDict, channel)
    dac_idx = findall(x -> channel == x, exp.HeaderDict["dacNames"])
    push!(exp, wvform, dims = 3, newChName = channel, newChUnits = exp.HeaderDict["dacUnits"][dac_idx...])
    return
end

getABF_datetime(filename) = readABFInfo(filename)["FileStartDateTime"]
