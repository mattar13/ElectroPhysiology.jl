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

function bin!(fn, exp::Experiment{TWO_PHOTON}, dims::Tuple{Int, Int, Int})
    img_arr = get_all_frames(exp)
    n_ch = size(exp, 3)
    original_dims = size(img_arr)
    binned_x = Int(original_dims[1] / dims[1])
    binned_y = Int(original_dims[2] / dims[2])
    binned_z = Int(original_dims[3] / dims[3])
    binned_vol = zeros(Float32, binned_x, binned_y, binned_z, n_ch)
    for ch in n_ch
        for x in 1:binned_x
            for y in 1:binned_y
                for z in 1:binned_z
                    x_range = (x-1)*dims[1]+1 : min(x*dims[1], original_dims[1])
                    y_range = (y-1)*dims[2]+1 : min(y*dims[2], original_dims[2])
                    z_range = (z-1)*dims[3]+1 : min(z*dims[3], original_dims[3])
                    binned_vol[x, y, z, ch] = fn(img_arr[x_range, y_range, z_range, ch])
                end
            end
        end
    end
    
    println(size(binned_vol))
    binned_vol = reshape(binned_vol, binned_x*binned_y, binned_z, n_ch)
    println(size(binned_vol))
    exp.data_array = binned_vol
end

#=mapping functions====================================================================================================================#

import Images: mapwindow, mapwindow! #These will allow us to do arbitrary operations

"""
This function maps a given function `f` over a specific window in each frame of the `exp` Experiment.
It modifies the experiment in place and processes each frame of the data for the specified channel 
(or for all channels if none is provided).

Parameters:
- `f`: A function to be applied over the window of each frame.
- `exp::Experiment{TWO_PHOTON, T}`: The Experiment object containing the frames to be processed.
- `window::Tuple{Int64, Int64}`: The size of the moving window over which to apply the function, specified as a tuple `(height, width)`.
- `channel (optional)`: The specific channel to apply the function on. If not provided, the function is applied on all channels.

This function modifies the data array in `exp` in place by mapping the function over the specified window for each frame.
"""
function mapframe!(f, exp::Experiment{TWO_PHOTON, T}, window::Tuple{Int64, Int64}; channel = nothing, border = "symmetric") where {T <: Real}
    img_arr = get_all_frames(exp)
    if isnothing(channel)
        for ch in axes(exp, 3)
            mapframe!(f, exp, window; channel = ch, border = border)
        end
    else
        for frame_idx in axes(img_arr,3)
            frame = img_arr[:,:,frame_idx, channel]
            img_filt_frame = mapwindow(f, frame, window, border = border)
            reshape_img = reshape(img_filt_frame, (size(img_filt_frame,1)*size(img_filt_frame,2)))
            exp.data_array[:,frame_idx, channel] .= reshape_img
        end
    end
end

function mapframe(f, exp::Experiment{TWO_PHOTON, T}, window::Tuple{Int64, Int64}; kwargs...) where {T <: Real}
    exp_copy = deepcopy(exp)
    mapframe!(f, exp_copy, window; kwargs...)
    return exp_copy
end

"""
This function maps the given function `f` over a specified window of data in the `exp` Experiment.
The function modifies the experiment in place, applying the function `f` to each channel within the
specified window size.

Parameters:
- `f`: A function to be applied over the window of the data.
- `exp::Experiment{TWO_PHOTON, T}`: The Experiment object containing the data to be processed.
- `window::Int64`: The size of the moving window over which to apply the function.
- `channel (optional)`: The specific channel to apply the function on. If not provided, the function is applied on all channels.

This function modifies the data array in `exp` in place by mapping the function over the specified window.
"""
function mapdata!(f, exp::Experiment{TWO_PHOTON, T}, window::Int64; channel = nothing, border = "symmetric") where {T<:Real}
    if isnothing(channel)
        for ch in axes(exp, 3)
            mapdata!(f, exp, window, channel = ch, border = border)
        end
    else
        new_window = (1, window)
        arr = exp.data_array[:,:,channel]
        reshape_img = mapwindow(f, arr, new_window, border)
        exp.data_array[:,:,channel] .= reshape_img
    end
end

function mapdata(f, exp::Experiment{TWO_PHOTON, T}, window::Int64; kwargs...) where {T<:Real}
    exp_copy = deepcopy(exp)
    mapdata!(f, exp_copy, window; kwargs...)
    return exp_copy
end