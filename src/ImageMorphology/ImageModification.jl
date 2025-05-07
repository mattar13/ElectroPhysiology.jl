

"""
    deinterleave!(exp::Experiment{TWO_PHOTON, T}; n_channels=2, new_ch_name="Alexa 594", new_ch_unit="px") where T<:Real

Separate interleaved channels in a two-photon experiment into separate channels.

# Arguments
- `exp::Experiment{TWO_PHOTON, T}`: The experiment containing interleaved channels
- `n_channels::Int=2`: Number of interleaved channels to separate
- `new_ch_name::String="Alexa 594"`: Name for the new channel
- `new_ch_unit::String="px"`: Unit for the new channel

# Details
This function is commonly used when channels are acquired in an interleaved fashion,
where frames alternate between different channels. The function separates these frames
into distinct channels within the experiment.

# Returns
- Modified experiment with deinterleaved channels
"""
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

"""
    process_image!(exp::Experiment{TWO_PHOTON}; operation=:map, window=nothing, channels=:all, function_handle=identity, params=Dict())

A unified interface for processing two-photon imaging data with various operations including mapping functions over windows,
filtering, brightness/contrast adjustments, channel deinterleaving, and data projection.

# Arguments
- `exp`: The two-photon experiment to process
- `operation`: Operation type (one of):
    - `:map`: Apply a function over a window (using mapframe! or mapdata!)
    - `:filter`: Apply image filtering
    - `:transform`: Apply brightness/contrast adjustments
    - `:deinterleave`: Separate interleaved channels
    - `:project`: Project data along specified dimensions
    - `:bin`: Bin data along specified dimensions
- `window`: Window size for operations (if applicable)
    - For mapframe!: Tuple{Int64,Int64} specifying (height, width)
    - For mapdata!: Int64 specifying window size
- `channels`: Channels to process (:all or specific channels)
- `function_handle`: Processing function for :map operation
- `params`: Additional parameters specific to each operation

# Operation-specific Parameters

## Map Operation (:map)
- Requires `window` parameter:
    - Tuple{Int64,Int64} for mapframe! (2D window)
    - Int64 for mapdata! (1D window)
- Uses `function_handle` to apply over window

## Filter Operation (:filter)
- `kernel`: Required filter kernel (OffsetArray or Array)

## Transform Operation (:transform)
- `min_val_x`: Minimum input value (:std, :auto, :ci, or numeric)
- `max_val_x`: Maximum input value (:std, :auto, :ci, or numeric)
- `std_level`: Standard deviation level for :std mode (default: 1)
- `min_val_y`: Minimum output value (default: 0.0)
- `max_val_y`: Maximum output value (default: 1.0)
- `contrast`: Contrast adjustment (:auto or numeric)
- `brightness`: Brightness adjustment (:auto or numeric)
- `n_vals`: Number of values for linear fit (default: 10)

## Deinterleave Operation (:deinterleave)
- `n_channels`: Number of channels to deinterleave (default: 2)
- `new_ch_name`: Name for new channel (default: "Alexa 594")
- `new_ch_unit`: Unit for new channel (default: "px")

## Project Operation (:project)
- `dims`: Dimension to project along (default: 3)

## Bin Operation (:bin)
- `dims`: Tuple of dimensions to bin (default: (2,2,1))
- `function`: Function to apply in binning (default: mean)

# Examples
```julia
# Apply median filter over 3x3 window
process_image!(exp, operation=:map, 
    window=(3,3), 
    function_handle=median)

# Apply Gaussian filter
using Images
kernel = Kernel.gaussian((3,3))
process_image!(exp, operation=:filter, 
    params=Dict(:kernel => kernel))

# Adjust brightness/contrast using standard deviation
process_image!(exp, operation=:transform, 
    params=Dict(
        :min_val_x => :std,
        :max_val_x => :std,
        :std_level => 2
    ))

# Deinterleave two channels
process_image!(exp, operation=:deinterleave,
    params=Dict(
        :n_channels => 2,
        :new_ch_name => "GFP"
    ))

# Project along z-axis
process_image!(exp, operation=:project,
    params=Dict(:dims => 3))

# Bin data with custom function
process_image!(exp, operation=:bin,
    params=Dict(
        :dims => (2,2,1),
        :function => maximum
    ))
```

# Returns
- The modified experiment object with processed image data
"""
function process_image!(exp::Experiment{TWO_PHOTON,T};
    operation=:map,
    window=nothing,
    channels=:all,
    function_handle=identity,
    params=Dict()
) where T<:Real
    # Convert channels specification
    process_channels = if channels == :all
        1:size(exp, 3)
    elseif isa(channels, Vector{String})
        findall(channels .== exp.chNames)
    else
        channels
    end

    if operation == :map
        if window isa Tuple{Int64,Int64}
            mapframe!(function_handle, exp, window; channel=process_channels)
        elseif window isa Int64
            mapdata!(function_handle, exp, window; channel=process_channels)
        else
            error("Window must be either Tuple{Int64,Int64} for mapframe! or Int64 for mapdata!")
        end

    elseif operation == :filter
        kernel = get(params, :kernel, nothing)
        if isnothing(kernel)
            error("Must provide kernel for filter operation")
        end
        imfilter!(exp, kernel; channel=process_channels)

    elseif operation == :transform
        min_val_x = get(params, :min_val_x, :std)
        max_val_x = get(params, :max_val_x, :std)
        std_level = get(params, :std_level, 1)
        min_val_y = get(params, :min_val_y, 0.0)
        max_val_y = get(params, :max_val_y, 1.0)
        contrast = get(params, :contrast, :auto)
        brightness = get(params, :brightness, :auto)
        n_vals = get(params, :n_vals, 10)

        adjustBC!(exp;
            channel=process_channels,
            min_val_x=min_val_x,
            max_val_x=max_val_x,
            std_level=std_level,
            min_val_y=min_val_y,
            max_val_y=max_val_y,
            contrast=contrast,
            brightness=brightness,
            n_vals=n_vals
        )

    elseif operation == :deinterleave
        n_channels = get(params, :n_channels, 2)
        new_ch_name = get(params, :new_ch_name, "Alexa 594")
        new_ch_unit = get(params, :new_ch_unit, "px")

        deinterleave!(exp;
            n_channels=n_channels,
            new_ch_name=new_ch_name,
            new_ch_unit=new_ch_unit
        )

    elseif operation == :project
        dims = get(params, :dims, 3)
        return project(exp; dims=dims)

    elseif operation == :bin
        dims = get(params, :dims, (2,2,1))
        fn = get(params, :function, mean)
        bin!(fn, exp, dims)
    end

    return exp
end

function process_image(exp::Experiment{TWO_PHOTON,T}; kwargs...) where T<:Real
    exp_copy = deepcopy(exp)
    process_image!(exp_copy; kwargs...)
    return exp_copy
end