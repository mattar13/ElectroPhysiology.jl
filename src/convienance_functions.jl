function openERGData(
    fn;
    channel=1,
    stimulus_name="IN 7",
    t_pre=0.1,
    t_post=2.0,
    baseline_region=(0.0, 1.0),
    downsample_rate=500.0,
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
    baseline_adjust!(dataERG, region=baseline_region, mode=:mean)
    align_to_stimulus!(dataERG, t_pre=t_pre, t_post=t_post)

    downsample!(dataERG, downsample_rate)
    dataERG.t = dataERG.t .* 1000 # ms
    dataERG.t = dataERG.t .- dataERG.t[1]
    expERG = getchannel(dataERG, channel).data_array[1, :, 1]

    return dataERG, expERG
end
