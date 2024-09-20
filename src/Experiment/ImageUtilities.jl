function deinterleave!(exp::Experiment{TWO_PHOTON, T}; 
    n_channels = 2,
    new_ch_name = "Alexa 594", new_ch_unit = "px"
) where T<:Real 
    channel_arr = []
    for i in 1:n_channels
        new_ch = exp.data_array[:, i:n_channels:end, :]
        push!(channel_arr, new_ch)
    end
    new_time = exp.t[1:size(channel_arr[1], 2)]
    new_data_arr = cat(channel_arr..., dims = 3)
    exp.t = new_time
    exp.data_array = new_data_arr

    push!(exp.chNames, new_ch_name)
    push!(exp.chUnits, new_ch_unit)
    #println(size(exp.data_array))
    return exp
end

function project(exp::Experiment{TWO_PHOTON, T}; dims = 3) where T<:Real
    img_arr = get_all_frames(exp)
    project_arr = mean(img_arr, dims = dims)
end