#=
Everything in this file is meant to segment and determine ROIs
=#


#Create new ROIs

"""
    pixel_splits(image_size::Tuple{Int, Int}, roi_size::Int) -> Matrix{Int64}

Creates a regular grid of rectangular ROIs by splitting an image into equal-sized regions.

# Arguments
- `image_size::Tuple{Int, Int}`: The dimensions of the image (width, height) in pixels
- `roi_size::Int`: The size of each rectangular ROI in pixels (both width and height)

# Returns
- `Matrix{Int64}`: A 2D matrix where each pixel contains the ROI label (1, 2, 3, etc.)

# Example
```julia
# Create a 100x100 image split into 10x10 ROIs
mask = pixel_splits((100, 100), 10)
# Result: 10x10 grid of ROIs, each labeled 1-100
```
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
    
"""
    pixel_splits_roi!(exp::Experiment{TWO_PHOTON, T}, roi_size) where T<:Real

Creates a regular grid of rectangular ROIs and assigns them to the experiment object.

# Arguments
- `exp::Experiment{TWO_PHOTON, T}`: The experiment object to modify
- `roi_size`: The size of each rectangular ROI in pixels

# Side Effects
- Modifies `exp.HeaderDict["ROIs"]` with the flattened ROI mask

# Example
```julia
# Create 10x10 ROIs for the experiment
pixel_splits_roi!(experiment, 10)
```
"""
function pixel_splits_roi!(exp::Experiment{TWO_PHOTON, T}, roi_size) where T<:Real
    x_pixels, y_pixels = exp.HeaderDict["framesize"]
    segment_mask = pixel_splits((x_pixels, y_pixels), roi_size) #Create the indexes of pixel splits
    roi_mask_flat = reshape(segment_mask, segment_mask.size[1] * segment_mask.size[2]) #Reshape the mask to the original size of the image
    exp.HeaderDict["ROIs"] = roi_mask_flat
end

"""
    make_circular_roi!(exp::Experiment{TWO_PHOTON, T}, center::Tuple{Int64, Int64}, radius::Int64) where T<:Real

Creates a circular ROI and assigns it to the experiment object.

# Arguments
- `exp::Experiment{TWO_PHOTON, T}`: The experiment object to modify
- `center::Tuple{Int64, Int64}`: The center coordinates of the circle (x, y) in pixels
- `radius::Int64`: The radius of the circle in pixels

# Side Effects
- Modifies `exp.HeaderDict["ROIs"]` with the flattened circular ROI mask

# Details
Uses the circle equation (x-h)² + (y-k)² = r² to determine which pixels fall within the circle.

# Example
```julia
# Create a circular ROI centered at (50, 50) with radius 20
make_circular_roi!(experiment, (50, 50), 20)
```
"""
function make_circular_roi!(exp::Experiment{TWO_PHOTON, T}, center::Tuple{Real, Real}, radius::Real) where T<:Real
    x_pixels, y_pixels = exp.HeaderDict["framesize"]
    #Eventually we want to make this a function of real image size vs pixel size
    xrng = exp.HeaderDict["xrng"]
    yrng = exp.HeaderDict["yrng"]
    dx = xrng[2] - xrng[1]
    dy = yrng[2] - yrng[1]

    #Convert the center to pixel coordinates
    center_x = round(Int, (center[1] - xrng[1]) / dx * x_pixels)
    center_y = round(Int, (center[2] - yrng[1]) / dy * y_pixels)

    #convert the radius to pixel coordinates
    radius_px = round(Int, radius / dx * x_pixels)

    #Create a mask of zeros
    roi_mask = zeros(Int64, x_pixels, y_pixels)
    
    #Create a circular ROI using the circle equation: (x-h)² + (y-k)² = r²
    #where (h,k) is the center and r is the radius
    
    #Iterate through all pixels in the image
    for x in 1:x_pixels
        for y in 1:y_pixels
            #Check if the pixel is within the circle using distance formula
            distance_squared = (x - center_x)^2 + (y - center_y)^2
            if distance_squared <= radius_px^2
                roi_mask[x, y] = 1
            end
        end
    end
    
    #Reshape the mask to the flattened format expected by the experiment
    roi_mask_flat = reshape(roi_mask, x_pixels * y_pixels)
    exp.HeaderDict["ROIs"] = roi_mask_flat
end

#Load a ROI

"""
    getROIindexes(exp::Experiment{TWO_PHOTON, T}, label::Int64) where T<:Real -> Vector{Int64}

Returns the linear indices of pixels belonging to a specific ROI.

# Arguments
- `exp::Experiment{TWO_PHOTON, T}`: The experiment object
- `label::Int64`: The ROI label to find

# Returns
- `Vector{Int64}`: Linear indices of pixels belonging to the specified ROI

# Example
```julia
# Get indices of ROI with label 1
indices = getROIindexes(experiment, 1)
```
"""
getROIindexes(exp::Experiment{TWO_PHOTON, T}, label::Int64) where T<:Real = findall(exp.HeaderDict["ROIs"] .== label)

"""
    getROImask(exp::Experiment{TWO_PHOTON, T}, label::Int64; reshape_arr = true) where T <: Real -> Union{Matrix{Int64}, Vector{Int64}}

Returns a binary mask for a specific ROI.

# Arguments
- `exp::Experiment{TWO_PHOTON, T}`: The experiment object
- `label::Int64`: The ROI label to extract
- `reshape_arr::Bool=true`: Whether to reshape the result to 2D matrix

# Returns
- If `reshape_arr=true`: `Matrix{Int64}` - 2D binary mask (1 for ROI pixels, 0 otherwise)
- If `reshape_arr=false`: `Vector{Int64}` - 1D binary mask

# Example
```julia
# Get 2D mask for ROI with label 1
mask_2d = getROImask(experiment, 1, reshape_arr=true)

# Get 1D mask for ROI with label 1
mask_1d = getROImask(experiment, 1, reshape_arr=false)
```
"""
function getROImask(exp::Experiment{TWO_PHOTON, T}, label::Int64; reshape_arr = true) where T <: Real
     if reshape_arr
          px_x, px_y = exp.HeaderDict["framesize"]
          return reshape(exp.HeaderDict["ROIs"] .== label, (px_x, px_y)) .|> Int64
     else
          return (exp.HeaderDict["ROIs"] .== label) .|> Int64
     end
end

"""
    getROImask(exp::Experiment{TWO_PHOTON, T}; reshape_arr = true) where T<:Real -> Union{Matrix{Int64}, Vector{Int64}}

Returns the complete ROI mask for all ROIs in the experiment.

# Arguments
- `exp::Experiment{TWO_PHOTON, T}`: The experiment object
- `reshape_arr::Bool=true`: Whether to reshape the result to 2D matrix

# Returns
- If `reshape_arr=true`: `Matrix{Int64}` - 2D ROI mask with labels
- If `reshape_arr=false`: `Vector{Int64}` - 1D ROI mask with labels

# Example
```julia
# Get 2D mask for all ROIs
all_rois_2d = getROImask(experiment, reshape_arr=true)

# Get 1D mask for all ROIs
all_rois_1d = getROImask(experiment, reshape_arr=false)
```
"""
function getROImask(exp::Experiment{TWO_PHOTON, T}; reshape_arr = true) where T<:Real
     if reshape_arr
          px_x, px_y = exp.HeaderDict["framesize"]
          return reshape(exp.HeaderDict["ROIs"], (px_x, px_y)) .|> Int64
     else
          return (exp.HeaderDict["ROIs"]) .|> Int64
     end
end

"""
    getROIarr(exp::Experiment{TWO_PHOTON, T}, label::Int64; reshape_arr = false) where T <: Real -> Array{T, 3}

Extracts the data array for a specific ROI.

# Arguments
- `exp::Experiment{TWO_PHOTON, T}`: The experiment object
- `label::Int64`: The ROI label to extract
- `reshape_arr::Bool=false`: Whether to reshape the result to include spatial dimensions

# Returns
- If `reshape_arr=false`: `Array{T, 3}` - ROI data with dimensions (n_pixels, n_channels, n_trials)
- If `reshape_arr=true`: `Array{T, 4}` - ROI data with dimensions (width, height, n_channels, n_trials)

# Example
```julia
# Get ROI data for label 1 without reshaping
roi_data = getROIarr(experiment, 1, reshape_arr=false)

# Get ROI data for label 1 with spatial dimensions
roi_data_spatial = getROIarr(experiment, 1, reshape_arr=true)
```
"""
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

function getROIarr(exp::Experiment{TWO_PHOTON, T}, labels::Vector{Int64}; reshape_arr = false) where T <: Real
    
    all_roi_arr = []
    for label in labels
        roi_arr = getROIarr(exp, label; reshape_arr = reshape_arr)
        push!(all_roi_arr, roi_arr)
    end
    return cat(all_roi_arr..., dims = 1)
end

"""
    getROIarr(exp::Experiment{TWO_PHOTON, T}; reshape_arr = true) where T<:Real -> Array{T, 4}

Extracts the data array for all ROIs combined.

# Arguments
- `exp::Experiment{TWO_PHOTON, T}`: The experiment object
- `reshape_arr::Bool=true`: Whether to reshape the result to include spatial dimensions

# Returns
- If `reshape_arr=true`: `Array{T, 4}` - All ROI data with dimensions (width, height, n_channels, n_trials)
- If `reshape_arr=false`: `Array{T, 3}` - All ROI data with dimensions (n_pixels, n_channels, n_trials)

# Details
This function masks the entire data array to only include pixels that belong to any ROI.

# Example
```julia
# Get all ROI data with spatial dimensions
all_roi_data = getROIarr(experiment, reshape_arr=true)

# Get all ROI data without spatial dimensions
all_roi_data_flat = getROIarr(experiment, reshape_arr=false)
```
"""
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
    recordROI(exp::Experiment{TWO_PHOTON, T}, roi_idxs::Vector{Int64}, label::Int64) where T <: Real

Records a new ROI by assigning a label to specific pixel indices.

# Arguments
- `exp::Experiment{TWO_PHOTON, T}`: The experiment object to modify
- `roi_idxs::Vector{Int64}`: Linear indices of pixels to include in the ROI
- `label::Int64`: The label to assign to these pixels

# Side Effects
- Modifies `exp.HeaderDict["ROIs"]` by setting the specified indices to the given label

# Example
```julia
# Create ROI with label 2 for pixels at indices [100, 101, 102, 200, 201, 202]
recordROI(experiment, [100, 101, 102, 200, 201, 202], 2)
```

# Notes
ROIs are masks where non-zero values indicate pixels belonging to ROIs, and the value represents the ROI label.
"""
function recordROI(exp::Experiment{TWO_PHOTON, T}, roi_idxs::Vector{Int64}, label::Int64) where T <: Real 
     exp.HeaderDict["ROIs"][roi_idxs] .= label
end

"""
    loadROIfn!(fn::String, exp::Experiment{TWO_PHOTON, T}) where T<:Real -> Vector{Int64}

Loads ROI masks from an image file and assigns them to the experiment.

# Arguments
- `fn::String`: Path to the image file containing ROI masks
- `exp::Experiment{TWO_PHOTON, T}`: The experiment object to modify

# Returns
- `Vector{Int64}`: The loaded ROI mask

# Side Effects
- Modifies `exp.HeaderDict["ROIs"]` with the loaded ROI labels

# Details
- Loads the image and converts it to grayscale
- Each unique non-zero value in the image becomes a separate ROI label
- The first unique value (typically 0) is ignored as it represents background

# Example
```julia
# Load ROIs from a PNG file
roi_mask = loadROIfn!("rois.png", experiment)
```

# Supported Formats
Supports all image formats supported by the `FileIO` and `Images` packages.
"""
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