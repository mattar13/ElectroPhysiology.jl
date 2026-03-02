function openERGData(
    fn;
    channel=1,
    stimulus_name="IN 7",
    t_pre=:stim_start,
    t_post = 6.0,
    baseline_region=(0.0, 1.0),
    downsample_rate=-1.0,
    time_unit = :s,
    time_zero = true
)
    abf_input = if isa(fn, AbstractString) && isdir(fn)
        parseABF(fn)
    else
        fn
    end

    dataERG = readABF(
        abf_input,
        flatten_episodic=false,
        stimulus_name=stimulus_name,
        average_trials=true,
    )
    if t_pre == :stim_end
        t_pre = getStimulusEndTime(dataERG)[1]
    elseif t_pre == :stim_start
        t_pre = getStimulusStartTime(dataERG)[1]
    elseif isa(t_pre, Number)
        t_pre = t_pre
    else
        error("Invalid t_pre value. Must be :stim_end, :stim_start, or a numeric value.")
    end
    baseline_adjust!(dataERG, region=baseline_region, mode=:mean)
    truncate_data!(dataERG, t_pre, t_post)

    if downsample_rate != -1.0
        downsample!(dataERG, downsample_rate)
    end
    if time_unit == :ms
        dataERG.t = dataERG.t .* 1000 # ms
    end
    if time_zero
        dataERG.t = dataERG.t .- dataERG.t[1]
    end
    # expERG = getchannel(dataERG, channel).data_array[1, :, 1]

    return dataERG#, expERG
end
