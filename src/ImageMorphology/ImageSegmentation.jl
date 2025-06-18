#=
Everything in this file is meant to segment and determine ROIs
=#


#Create new ROIs

"""
    pixel_splits(image_size::Tuple{Int, Int}, roi_size::Int) -> Tuple{Vector{Int}, Vector{Int}}

Determines the pixel splitting indices for the image based on `roi_size`.
"""
function pixel_splits(image_size::Tuple{Int, Int}, roi_size::Int)
    x_pixels, y_pixels = image_size

    #Initialize a ROI mask of zeros
    roi_mask = zeros(Int64, x_pixels, y_pixels)

    pixel_idx = 1
    for x_idx in 1:roi_size:x_pixels
        for y_idx in 1:roi_size:y_pixels
            #Set the ROI label to the current index
            roi_mask[x_idx:min(x_idx+roi_size-1, x_pixels), y_idx:min(y_idx+roi_size-1, y_pixels)] .= pixel_idx
            pixel_idx += 1
        end
    end

    return roi_mask
end
    
#Push the pixel splits to the ROI objects
function pixel_splits_roi!(exp::Experiment{TWO_PHOTON, T}, roi_size) where T<:Real
    x_pixels, y_pixels = exp.HeaderDict["framesize"]
    segment_mask = pixel_splits((x_pixels, y_pixels), roi_size) #Create the indexes of pixel splits
    roi_mask_flat = reshape(segment_mask, segment_mask.size[1] * segment_mask.size[2]) #Reshape the mask to the original size of the image
    exp.HeaderDict["ROIs"] = roi_mask_flat
end

#Make a function that will make a circular ROI
function make_circular_roi!(exp::Experiment{TWO_PHOTON, T}, center::Tuple{Int64, Int64}, radius::Int64) where T<:Real
    x_pixels, y_pixels = exp.HeaderDict["framesize"]
    
    #Create a mask of zeros
    roi_mask = zeros(Int64, x_pixels, y_pixels)
    
    #Create a circular ROI using the circle equation: (x-h)² + (y-k)² = r²
    #where (h,k) is the center and r is the radius
    center_x, center_y = center
    
    #Iterate through all pixels in the image
    for x in 1:x_pixels
        for y in 1:y_pixels
            #Check if the pixel is within the circle using distance formula
            distance_squared = (x - center_x)^2 + (y - center_y)^2
            if distance_squared <= radius^2
                roi_mask[x, y] = 1
            end
        end
    end
    
    #Reshape the mask to the flattened format expected by the experiment
    roi_mask_flat = reshape(roi_mask, x_pixels * y_pixels)
    exp.HeaderDict["ROIs"] = roi_mask_flat
end

#Load a ROI

getROIindexes(exp::Experiment{TWO_PHOTON, T}, label::Int64) where T<:Real = findall(exp.HeaderDict["ROIs"] .== label)

"""
This function gets the ROI label and returns the mask
"""
function getROImask(exp::Experiment{TWO_PHOTON, T}, label::Int64; reshape_arr = true) where T <: Real
     if reshape_arr
          px_x, px_y = exp.HeaderDict["framesize"]
          return reshape(exp.HeaderDict["ROIs"] .== label, (px_x, px_y)) .|> Int64
     else
          return (exp.HeaderDict["ROIs"] .== label) .|> Int64
     end
end

function getROImask(exp::Experiment{TWO_PHOTON, T}; reshape_arr = true) where T<:Real
     if reshape_arr
          px_x, px_y = exp.HeaderDict["framesize"]
          return reshape(exp.HeaderDict["ROIs"], (px_x, px_y)) .|> Int64
     else
          return (exp.HeaderDict["ROIs"]) .|> Int64
     end
end

function getROIarr(exp::Experiment{TWO_PHOTON, T}, label::Int64; reshape_arr = false) where T <: Real
     mask = getROImask(exp, label; reshape_arr = false)
     roi_indexs = findall(mask .== 1) #Get the indexes of the mask
     ROI_arr = exp.data_array[roi_indexs, :, :]
     if reshape_arr
          px_x, px_y = exp.HeaderDict["framesize"]
          return reshape(ROI_arr, (px_x, px_y, size(exp, 2), size(exp,3)))
     else
          return ROI_arr
     end
end

function getROIarr(exp::Experiment{TWO_PHOTON, T}; reshape_arr = true) where T<:Real
     ROI_mask = exp.HeaderDict["ROIs"] .!= 0
     ROI_arr = exp.data_array .* ROI_mask
     if reshape_arr
          px_x, px_y = exp.HeaderDict["framesize"]
          return reshape(ROI_arr, (px_x, px_y, size(exp, 2), size(exp,3)))
     else
          return ROI_arr
     end
end

"""
ROIs are masks. 
A ROI is a mask of falses (which are not included in the image) and trues (which are)

"""
function recordROI(exp::Experiment{TWO_PHOTON, T}, roi_idxs::Vector{Int64}, label::Int64) where T <: Real 
     exp.HeaderDict["ROIs"][roi_idxs] .= label
end

#Make a new function 
function loadROIfn!(fn::String, exp::Experiment{TWO_PHOTON, T}) where T<:Real
     ROI_mask_img = load(fn)
     ROI_mask_gray = Gray.(ROI_mask_img)
     ROI_mask_gray = reshape(ROI_mask_gray, length(ROI_mask_gray)) |> vec
     for (mask_idx, mask_val) in enumerate(unique(ROI_mask_gray)[2:end])
         ROI_mask_indexes = findall(ROI_mask_gray .== mask_val)
         recordROI(exp, ROI_mask_indexes, mask_idx)
     end
     exp.HeaderDict["ROIs"]
end