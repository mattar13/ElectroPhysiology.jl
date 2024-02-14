

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

function getROIarr(exp::Experiment{TWO_PHOTON, T}, label::Int64; reshape_arr = true) where T <: Real
     mask = getROImask(exp, label; reshape_arr = false)
     ROI_arr = exp.data_array .* mask
     if reshape_arr
          px_x, px_y = exp.HeaderDict["framesize"]
          return reshape(ROI_arr, (px_x, px_y, size(exp, 2)))
     else
          return ROI_arr
     end
end

function getROIarr(exp::Experiment{TWO_PHOTON, T}; reshape_arr = true) where T<:Real
     ROI_mask = exp.HeaderDict["ROIs"] .!= 0
     ROI_arr = exp.data_array .* ROI_mask
     if reshape_arr
          px_x, px_y = exp.HeaderDict["framesize"]
          return reshape(ROI_arr, (px_x, px_y, size(exp, 2)))
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