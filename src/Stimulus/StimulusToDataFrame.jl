function set_flash_intensity!(protocol::StimulusProtocol{T, Vector{Flash}}, stimulus_name::AbstractString) where T <: Real
    photons = calculate_photons(stimulus_name)
    for flash in protocol.type
        flash.intensity = photons
    end
    return protocol
end

function stimulus_to_table(protocol::StimulusProtocol{T}) where T <: Real
    n = length(protocol.timestamps)

    if isa(protocol.type, Vector{Flash})
        type_name = "UniformFlash"
        intensities = [Float64(f.intensity) for f in protocol.type]
    elseif isa(protocol.type, Flash)
        type_name = "UniformFlash"
        intensities = fill(Float64(protocol.type.intensity), n)
    elseif isa(protocol.type, Step)
        type_name = "Step"
        intensities = fill(0.0, n)
    elseif isa(protocol.type, Ramp)
        type_name = "Ramp"
        intensities = fill(0.0, n)
    elseif isa(protocol.type, Puff)
        type_name = "Puff"
        intensities = fill(0.0, n)
    else
        type_name = "Unknown"
        intensities = fill(0.0, n)
    end

    types = fill(type_name, n)
    durations = Float64[]
    starts = Float64[]
    ends = Float64[]

    for (start_time, end_time) in protocol.timestamps
        push!(durations, (end_time - start_time) * 1000.0)  # Convert to ms
        push!(starts, start_time)
        push!(ends, end_time * 1000.0)  # Convert to ms
    end

    durations = round.(durations, digits=1)
    ends = round.(ends, digits=1)
    cumulative_intensities = intensities .* durations

    return (Type = types, Intensity = intensities, Duration = durations, CumulativeIntensity = cumulative_intensities, TimeStart = starts, TimeEnd = ends)
end

function stimulus_to_table(exp::Experiment)
    protocol = getStimulusProtocol(exp)
    if isnothing(protocol)
        throw(ArgumentError("Experiment does not have a stimulus protocol"))
    end

    abf_paths = get(exp.HeaderDict, "abfPath", "")

    # Multi-file case: abfPath is a vector, compute per-sweep intensity from each file
    if isa(abf_paths, Vector{String}) && isa(protocol.type, Vector{Flash})
        n = min(length(protocol.type), length(protocol.sweeps))
        for i in 1:n
            sweep = protocol.sweeps[i]
            if sweep <= length(abf_paths)
                try
                    protocol.type[i].intensity = calculate_photons(basename(abf_paths[sweep]))
                catch
                end
            end
        end
    end

    return stimulus_to_table(protocol)
end

function save_stimulus_csv(filename::String, protocol::StimulusProtocol)
    nt = stimulus_to_table(protocol)
    open(filename, "w") do io
        println(io, "Type,Intensity,Duration,CumulativeIntensity,TimeStart,TimeEnd")
        for i in eachindex(nt.Type)
            println(io, "$(nt.Type[i]),$(nt.Intensity[i]),$(nt.Duration[i]),$(nt.CumulativeIntensity[i]),$(nt.TimeStart[i]),$(nt.TimeEnd[i])")
        end
    end
    return filename
end

function save_stimulus_csv(filename::String, exp::Experiment)
    nt = stimulus_to_table(exp)
    open(filename, "w") do io
        println(io, "Type,Intensity,Duration,CumulativeIntensity,TimeStart,TimeEnd")
        for i in eachindex(nt.Type)
            println(io, "$(nt.Type[i]),$(nt.Intensity[i]),$(nt.Duration[i]),$(nt.CumulativeIntensity[i]),$(nt.TimeStart[i]),$(nt.TimeEnd[i])")
        end
    end
    return filename
end
