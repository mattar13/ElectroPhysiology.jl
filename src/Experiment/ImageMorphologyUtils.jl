#These functions are for the opening algorithim
function disk_se(radius)
    dims = (2*radius+1, 2*radius+1)
    center = (radius+1, radius+1)
    arr = [sqrt((i-center[1])^2 + (j-center[2])^2) <= radius for i in 1:dims[1], j in 1:dims[2]]
    return centered(arr)
end

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

function adjustBC!(exp::Experiment{TWO_PHOTON}; channel = nothing,
    min_val_y = 0.0, max_val_y = 1.0, std_level = 1,
    min_val_x = :std, max_val_x = :std,
    contrast = :auto, brightness = :auto,
    n_vals = 10, 
)
    for (i, ch) in enumerate(eachchannel(exp))
         if isnothing(channel) || channel == i
              #println("BC this channel: $(ch.chNames[1])")
              if min_val_x == :auto
                   min_val_x = minimum(ch)
              elseif min_val_x == :std
                   mean_val = mean(ch, dims = (1,2))[1,1,1]
                   std_val = std_level*std(ch, dims = (1,2))[1,1,1]
                   min_val_x = mean_val - std_val
              elseif min_val_x == :ci
                   mean_val = mean(ch, dims = (1,2))[1,1,1]
                   std_val = std_level*std(ch, dims = (1,2))[1,1,1]
                   min_val_x = mean_val - std_val/sqrt(length(ch))
              end

              if max_val_x == :auto
                   max_val_x = maximum(ch)
              elseif max_val_x == :std
                   mean_val = mean(ch, dims = (1,2))[1,1,1]
                   std_val = std_level*std(ch, dims = (1,2))[1,1,1]
                   max_val_x = mean_val + std_val
              elseif max_val_x == :ci
                   mean_val = mean(ch, dims = (1,2))[1,1,1]
                   std_val = std_level*std(ch, dims = (1,2))[1,1,1]
                   max_val_x = mean_val + std_val/sqrt(length(ch))
              end

              if contrast == :auto
                   input_range = LinRange(min_val_x, max_val_x, n_vals)
                   output_range = LinRange(min_val_y, max_val_y, n_vals)
                   lin_fit = curve_fit(LinearFit, input_range, output_range)
              else
                   lin_fit(x) = contrast*x + brightness
              end
              exp.data_array[:,:,i] .= lin_fit.(ch.data_array)
         end
    end
    return exp
end

import Images: imfilter, imfilter!
function imfilter!(exp::Experiment{TWO_PHOTON}, kernel::OffsetArray{T, 2, Array{T, 2}}; channel = nothing) where T <: Real
    img_arr = get_all_frames(exp)
    @assert !isnothing(channel) "Channel needs to be specified"

    for frame_idx in axes(img_arr,3)
         frame = img_arr[:,:,frame_idx, channel]
         img_filt_frame = imfilter(frame, kernel)
         reshape_img = reshape(img_filt_frame, (size(img_filt_frame,1)*size(img_filt_frame,2)))
         exp.data_array[:,frame_idx, channel] .= reshape_img
    end
end

function imfilter!(exp::Experiment{TWO_PHOTON}, kernel::OffsetArray{T, 3, Array{T, 3}}; channel = nothing) where T <: Real
    img_arr = get_all_frames(exp)
    @assert !isnothing(channel) "Channel needs to be specified"
    img_filt_ch = imfilter(img_arr[:,:,:,channel], kernel)
    reshape_img = reshape(img_filt_ch, (size(img_filt_ch,1)*size(img_filt_ch,2), size(img_filt_ch,3)))
    exp.data_array[:,:,channel] .= reshape_img
end

function imfilter!(exp::Experiment{TWO_PHOTON}, kernel::Array{T, 3}; channel = nothing) where T<:Real
    img_arr = get_all_frames(exp)
    @assert !isnothing(channel) "Channel needs to be specified"
    img_filt_ch = imfilter(img_arr[:,:,:,channel], kernel)
    reshape_img = reshape(img_filt_ch, (size(img_filt_ch,1)*size(img_filt_ch,2), size(img_filt_ch,3)))
    exp.data_array[:,:,channel] .= reshape_img
end

function imfilter!(exp::Experiment{TWO_PHOTON}, kernel::Array{T, 4}; channel = nothing) where T<:Real
    img_arr = get_all_frames(exp)
    if isnothing(channel) #This means we want to filter both channels
         @assert ndims(kernel) == 4 "Kernel is size $(size(kernel)) and needs to be 4 dimensions"
         img_filt = imfilter(img_arr, kernel)
         reshape_img = reshape(img_filt, (size(img_filt,1)*size(img_filt,2), size(img_filt,3), size(img_filt,4)))
         exp.data_array = reshape_img       
    else
         img_filt_ch = imfilter(img_arr[:,:,:,channel], kernel[:,:,:,1])
         reshape_img = reshape(img_filt_ch, (size(img_filt_ch,1)*size(img_filt_ch,2), size(img_filt_ch,3)))
         exp.data_array[:,:,channel] .= reshape_img
    end
end

#This is a good option for a rolling mean 
function imfilter(exp::Experiment{TWO_PHOTON}, kernel; channel = nothing)
    exp_copy = deepcopy(exp)
    imfilter!(exp_copy, kernel; channel)
    return exp_copy
end

function bin!(exp::Experiment{TWO_PHOTON}, dims; operation = :mean)
    dim_trial, dim_data, dim_channel = dims
    size_trial, size_data, size_channel = size(exp)
    exp.data_array = exp.data_array[1:dim_trial:size_trial, 1:dim_data:size_data, 1:dim_channel:size_channel]
    exp.t = exp.t[1:dim_data:size_data]
end

#=mapping functions====================================================================================================================#

import Images: mapwindow, mapwindow! #These will allow us to do arbitrary operations
function mapwindow!(f, exp::Experiment{TWO_PHOTON, T}, window::Tuple{Int64, Int64}; channel = nothing) where T <: Real
    img_arr = get_all_frames(exp)
    @assert !isnothing(channel) "Channel needs to be specified"
    for frame_idx in axes(img_arr,3)
         frame = img_arr[:,:,frame_idx, channel]
         img_filt_frame = mapwindow(f, frame, window)
         reshape_img = reshape(img_filt_frame, (size(img_filt_frame,1)*size(img_filt_frame,2)))
         exp.data_array[:,frame_idx, channel] .= reshape_img
    end
end

#Not working properly. Need to adjust
function mapwindow!(f, exp::Experiment{TWO_PHOTON, T}, window::Tuple{Int64,Int64,Int64}; channel = nothing) where T<:Real
    if window[1] == 1 && window[2] == 1 #This is weird and throws a stackoverflow error
         new_window = (window[1], window[3])
         arr = exp.data_array[:,:,channel]
         reshape_img = mapwindow(f, arr, new_window)
    else
         img_arr = get_all_frames(exp)
         @assert !isnothing(channel) "Channel needs to be specified"
         img_filt_ch = mapwindow(f, img_arr[:,:,:,channel], window)
         reshape_img = reshape(img_filt_ch, (size(img_filt_ch,1)*size(img_filt_ch,2), size(img_filt_ch,3)))
    end
    exp.data_array[:,:,channel] .= reshape_img
end

function mapwindow!(f, exp::Experiment{TWO_PHOTON, T}, window::Tuple{Int64,Int64,Int64, Int64}; channel = nothing) where T<:Real
    img_arr = get_all_frames(exp)
    if isnothing(channel) #This means we want to filter both channels
         @assert ndims(kernel) == 4 "Kernel is size $(size(kernel)) and needs to be 4 dimensions"
         img_filt = mapwindow(f, img_arr, window)
         reshape_img = reshape(img_filt, (size(img_filt,1)*size(img_filt,2), size(img_filt,3), size(img_filt,4)))
         exp.data_array = reshape_img       
    end
end

function mapwindow(f, exp::Experiment{TWO_PHOTON, T}, kernel; channel = nothing) where {T<:Real}
    exp_copy = deepcopy(exp)
    mapwindow!(f, exp_copy, kernel; channel = channel)
    return exp_copy
end

function delta_f_opening(exp::Experiment{TWO_PHOTON, T}; stim_channel = 1, channel = 2) where T<:Real
    img_arr = get_all_frames(exp) #Extract
    cell_activity_arr = img_arr[:,:,1,stim_channel] #We may want to use this to narrow our approach

    img_zstack = img_arr[:,:,:,channel]
    se = disk_se(15) #This is a structured element array with a radius of 15
    background = opening(img_zstack[:,:,1], se) #remove the background from the first frame
    zstack_backsub = img_zstack .- background #Subtract the background from the img_zstack

    #This section will depend on us pulling out all of the frames we expect to be background
    baselineFrames = floor(Int64, 0.05 * size(zstack_backsub, 3)) #We might need to do better wit this
    #baselineFrames = size(zstack_backsub, 3)

    f0 = mean(zstack_backsub[:,:,1:baselineFrames], dims = 3)[:,:,1] #Take the to calculate F0
    dFstack = zstack_backsub .- f0 #delta f = stack - f0
    return dFstack
end

function delta_ff!(exp::Experiment; window = 41, fn = median, channel = nothing)
    if isnothing(channel)
        for (idx, ch) in enumerate(eachchannel(exp))
            println(idx)
            delta_ff!(exp, channel = idx, window = window, fn = fn)
        end
    else
        f0 = mapwindow(fn, exp, (1, 1, window), channel = channel)
        exp.data_array[:,:,channel] = exp[:,:,channel] - f0[:,:,channel] #delta f
        print(mean(exp, dims = (1,2)))
        exp.data_array[:,:,channel] = exp[:,:,channel] / maximum(f0, dims = (1,2))[channel]
    end
end

function delta_ff(exp::Experiment; kwargs...)
    exp_copy = deepcopy(exp)
    delta_ff!(exp_copy; kwargs...)
    return exp_copy
end


function find_boutons(exp::Experiment; algo = :opening)
    dFstack = delta_f_opening(exp)
    dFstackMax = maximum(dFstack, dims = 3)[:,:,1] #take the maximum value of the delta F
    dFstackMaxSmooth = mapwindow(median, dFstackMax, (3,3)) #Do a median filter
    dFstackMaxSmoothNorm = dFstackMaxSmooth/maximum(dFstackMaxSmooth) #normalize
    dFFstackMaxSmoothNorm = dFstackMaxSmoothNorm./f0
    return dFFstackMaxSmoothNorm
end