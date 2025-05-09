# Function to compute baseline using a median filter across time

function baseline_median(data::Experiment{FORMAT, T}; kernel_size=51, channel = -1, border = "symmetric") where {FORMAT, T<:Real}
    if channel == -1
        #we want to iterate through each channel
        baselines = similar(data.data_array)
        for (idx, ch) in enumerate(eachchannel(data))
            #println("Channel $(ch.chNames[1])")
            baseline = compute_baseline(ch, kernel_size=kernel_size, channel = 1)
            #println("Baseline size: $(size(baseline)) $(typeof(baseline))")
            baselines[:, :, idx] .= baseline
        end
        return baselines
    else
        data_arr = getchannel(data, channel).data_array[:,:,1]
        pixels, timepoints = size(data_arr)
        baseline = similar(data_arr)
        radius = (kernel_size - 1) ÷ 2
        
        @showprogress desc = "Median Filtering" @threads for pix in 1:pixels
            baseline[pix, :] .= mapwindow(median, data[pix, :], radius; border=border)
        end

        return baseline
    end
end