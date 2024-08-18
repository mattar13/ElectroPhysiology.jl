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
function imfilter!(exp::Experiment{TWO_PHOTON}, kernel; channel = nothing)
     img_arr = get_all_frames(exp)
     if isnothing(channel) #This means we want to filter both channels
          @assert ndims(kernel) == 4 "Kernel is size $(size(kernel)) and needs to be 4 dimensions"
          img_filt = imfilter(img_arr, kernel)
          reshape_img = reshape(img_filt, (size(img_filt,1)*size(img_filt,2), size(img_filt,3), size(img_filt,4)))
          exp.data_array = reshape_img       
     elseif ndims(kernel) == 4
          img_filt_ch = imfilter(img_arr[:,:,:,channel], kernel[:,:,:,1])
          reshape_img = reshape(img_filt_ch, (size(img_filt_ch,1)*size(img_filt_ch,2), size(img_filt_ch,3)))
          exp.data_array[:,:,channel] .= reshape_img
     elseif ndims(kernel) == 3
          img_filt_ch = imfilter(img_arr[:,:,:,channel], kernel)
          reshape_img = reshape(img_filt_ch, (size(img_filt_ch,1)*size(img_filt_ch,2), size(img_filt_ch,3)))
          exp.data_array[:,:,channel] .= reshape_img
     elseif ndims(kernel) == 2 #This usually means the kernel is frame by frame
          for frame_idx in 1:size(img_arr,3)
               frame = img_arr[:,:,frame_idx, channel]
               img_filt_frame = imfilter(frame, kernel)
               reshape_img = reshape(img_filt_frame, (size(img_filt_frame,1)*size(img_filt_frame,2)))
               exp.data_array[:,frame_idx, channel] .= reshape_img
          end
     end
end

#This is a good option for a rolling mean 
function imfilter(exp::Experiment{TWO_PHOTON}, kernel; channels = nothing)
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