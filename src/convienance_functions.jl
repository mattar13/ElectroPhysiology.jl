function openData(fn; channel = 1, t_begin = 0.1, t_end = 2.0)
    dataERG = readABF(fn, flatten_episodic = false, stimulus_name = "IN 7", average_trials = true)
    baseline_adjust!(dataERG, region = (0.0, 1.0), mode = :mean)
    truncate_data!(dataERG, t_pre = t_begin, t_post = t_end, truncate_based_on=:stimulus_beginning, time_zero = true)

    #Average the trials
    downsample!(dataERG, 500.0)
    dataERG.t = dataERG.t*1000 #Convert this to the larger number
    dataERG.t = dataERG.t .- dataERG.t[1] #Shift the time to start at 0
    expERG = getchannel(dataERG, channel).data_array[1,:,1]

    return dataERG, expERG
end