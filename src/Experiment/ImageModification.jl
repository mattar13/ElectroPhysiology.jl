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

"""
This baseline adjust works specifically for TWO_PHOTON images. 
     this is the same thing as delta_f/f
"""
function baseline_adjust(exp::Experiment{TWO_PHOTON, T}; kwargs...) where {T<:Real}
     data = deepcopy(exp)
     baseline_adjust!(data; kwargs...)
     return data

end

function baseline_adjust!(exp::Experiment{TWO_PHOTON, T};
     mode::Symbol = :rolling_mean, polyN = 1, region = :whole,
     δf_f::Bool = true, voxel_size = (1,1,5), channel = nothing
) where {T<:Real}
     if isnothing(channel) #This means we do both
          for (i, ch) in enumerate(eachchannel(exp))
               baseline_adjust!(exp, channel = i)
          end
     else
          if mode == :rolling_mean #This method kinda fucks up
               background = getchannel(mapwindow(mean, exp, voxel_size, channel = channel), channel)
               delta_f = getchannel(exp, channel) - background
               if δf_f
                    delta_f_f = delta_f/background
                    exp.data_array[:,:,channel] = delta_f_f.data_array
               else
                    exp.data_array[:,:,channel] = delta_f.data_array
               end
          elseif mode == :mean
               background = project(data2P, dims = 3)[:,:,1,channel]
               delta_f = getchannel(exp, channel) - background
               if δf_f
                    delta_f_f = delta_f/background
                    exp.data_array[:,:,channel] = delta_f_f.data_array
               else
                    exp.data_array[:,:,channel] = delta_f.data_array
               end
          elseif mode == :slope

          end
          
     end
end