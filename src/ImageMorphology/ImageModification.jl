

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

"""
    project(exp::Experiment{TWO_PHOTON, T}; dims=3) where T<:Real

Project two-photon imaging data along specified dimensions using mean projection.

# Arguments
- `exp::Experiment{TWO_PHOTON, T}`: The experiment to project
- `dims::Int=3`: Dimension(s) along which to project

# Returns
- Array containing the projected data
"""
function project(exp::Experiment{TWO_PHOTON, T}; dims = 3) where T<:Real
    img_arr = get_all_frames(exp)
    project_arr = mean(img_arr, dims = dims)
end

"""
    adjustBC!(exp::Experiment{TWO_PHOTON}; kwargs...)

Adjust brightness and contrast of two-photon imaging data.

# Arguments
- `exp::Experiment{TWO_PHOTON}`: The experiment to adjust
- `channel=nothing`: Channel to adjust (nothing for all channels)
- `min_val_y=0.0`: Minimum output value
- `max_val_y=1.0`: Maximum output value
- `std_level=1`: Number of standard deviations for automatic scaling
- `min_val_x=:std`: Method for determining minimum input value (:auto, :std, :ci)
- `max_val_x=:std`: Method for determining maximum input value (:auto, :std, :ci)
- `contrast=:auto`: Contrast adjustment method or value
- `brightness=:auto`: Brightness adjustment method or value
- `n_vals=10`: Number of points for automatic contrast curve fitting

# Details
Adjusts brightness and contrast using various methods:
- `:auto`: Automatically determine scaling based on data statistics
- `:std`: Use mean ± standard deviation
- `:ci`: Use confidence intervals

# Returns
- Modified experiment with adjusted brightness and contrast
"""
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

"""
    bin!(fn, exp::Experiment{TWO_PHOTON}, dims::Tuple{Int, Int, Int})

Bin two-photon imaging data by applying a function over specified dimensions.

# Arguments
- `fn::Function`: Function to apply to each bin (e.g., mean, median)
- `exp::Experiment{TWO_PHOTON}`: The experiment to bin
- `dims::Tuple{Int,Int,Int}`: Binning dimensions (x, y, z)

# Details
Reduces data resolution by applying the specified function over bins of the given dimensions.
Common use cases include noise reduction and data size reduction.

# Example
```julia
# Bin data using mean with 2x2x2 bins
bin!(mean, exp, (2,2,2))
```
"""
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
    mapframe!(f, exp::Experiment{TWO_PHOTON, T}, window::Tuple{Int64, Int64}; channel=nothing, border="symmetric") where {T<:Real}

Apply a function over a sliding window for each frame in a two-photon experiment.

# Arguments
- `f::Function`: Function to apply to each window
- `exp::Experiment{TWO_PHOTON, T}`: The experiment to process
- `window::Tuple{Int64,Int64}`: Window size (height, width)
- `channel=nothing`: Channel to process (nothing for all channels)
- `border="symmetric"`: Border handling method

# Details
This function is useful for operations that require spatial context, such as:
- Local statistics (mean, median, std)
- Feature detection
- Noise reduction

# Example
```julia
# Apply median filter with 3x3 window
mapframe!(median, exp, (3,3), channel=1)
```

# Returns
- Modified experiment with processed frames
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

"""
    mapframe(f, exp::Experiment{TWO_PHOTON, T}, window::Tuple{Int64, Int64}; kwargs...) where {T<:Real}

Non-mutating version of mapframe! that returns a new experiment.

See [`mapframe!`](@ref) for details on arguments and usage.
"""
function mapframe(f, exp::Experiment{TWO_PHOTON, T}, window::Tuple{Int64, Int64}; kwargs...) where {T <: Real}
    exp_copy = deepcopy(exp)
    mapframe!(f, exp_copy, window; kwargs...)
    return exp_copy
end

"""
    mapdata!(f, exp::Experiment{TWO_PHOTON, T}, window::Int64; channel=nothing, border="symmetric") where {T<:Real}

Apply a function over a specified window of data in a two-photon experiment.

# Arguments
- `f::Function`: Function to apply to each window
- `exp::Experiment{TWO_PHOTON, T}`: The experiment to process
- `window::Int64`: Window size
- `channel=nothing`: Channel to process (nothing for all channels)
- `border="symmetric"`: Border handling method

# Details
This function is useful for operations that require spatial context, such as:
- Local statistics (mean, median, std)
- Feature detection
- Noise reduction

# Example
```julia
# Apply median filter with 3x3 window
mapdata!(median, exp, 3, channel=1)
```

# Returns
- Modified experiment with processed data
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