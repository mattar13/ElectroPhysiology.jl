objective_calibration = Dict(
     16 => 850, 
     60 => 195,
)

# For now we really don't have this function do anything else other than load
# We eventually want to load
# Zoom level
# FPS
#Size
#TODO: Remember that the images might be misaligned in plotting. Maybe we need to define this in Plotting
function readImage(::Type{T}, filename; 
     chName = "CalBryte590", chUnit = "px", chGain = 1.0,
     objective = 60, verbose = false, deinterleave = false
) where T <: Real
     data_array = load(filename) |> Array{T}
     if verbose
          println("data loaded")
     end

     HeaderDict = Dict{String,Any}()
     #properties = magickinfo(filename)
     #HeaderDict = magickinfo(filename, properties)
     
     px_x, px_y, n_frames = size(data_array)

     HeaderDict["framesize"] = (px_x, px_y)
     HeaderDict["detector_wavelength"] = [594]
     HeaderDict["ROIs"] = zeros(Int64, px_x*px_y) #Currently ROIs are empty
     
     #Extract and split the two photon information
     #HeaderDict["date:create"] = DateTime(magickinfo(filename, "date:create")[1:end-6], dateformat"yyyy-mm-ddTHH:MM:SS")
     #HeaderDict["date:modify"] = DateTime(magickinfo(filename, "date:modify")[1:end-6], dateformat"yyyy-mm-ddTHH:MM:SS")

     comment_string = magickinfo(filename, "comment")["comment"]
     for line in eachsplit(comment_string, '\r'; keepempty=false)
          key, value = split(line, "="; limit = 2)
          parsed_int = tryparse(Int64, value)
          parsed_float = isnothing(parsed_int) ? tryparse(Float64, value) : nothing
          HeaderDict[key] = if !isnothing(parsed_int)
               parsed_int
          elseif !isnothing(parsed_float)
               parsed_float
          else
               value
          end
     end
     HeaderDict["FileStartDateTime"] = DateTime(HeaderDict["state.internal.triggerTimeString"], "'m/d/Y H:M:S.s'")
     zoom = HeaderDict["state.acq.zoomFactor"]
     
     fov = objective_calibration[objective] #this returns the micron scale of one field of view
     HeaderDict["PixelsPerMicron"] = px_x/(fov/zoom) #This will need to be overhauled once we get info about size
     HeaderDict["x_pixels"] = px_y
     HeaderDict["y_pixels"] = px_x
     HeaderDict["xrng"] = LinRange(0, fov/zoom, px_y)
     HeaderDict["yrng"] = LinRange(0, fov/zoom, px_x)
     sampling_rate = HeaderDict["state.acq.frameRate"]
     #Resize the data so that all of the pixels are in single value
     resize_data_arr = reshape(data_array, px_x*px_y, n_frames, 1)
     if verbose
          println("Data sized")
     end

     dt = 1/sampling_rate
     t = (collect(1:n_frames).-1) .* dt
     return Experiment(
          TWO_PHOTON,
          HeaderDict, #Header and Metadata
          dt, t, 
          resize_data_arr,
          [chName], 
          [chUnit], 
          [chGain], #Gain is always 1.0
     )
end

readImage(filename; kwargs...) = readImage(Float64, filename; kwargs...)

function get_frame(exp::Experiment{TWO_PHOTON, T}, frame::Integer) where T <: Real
     px, py = exp.HeaderDict["framesize"]
     @views data_frame = reshape(exp.data_array[:, frame, :], (px, py, 1, size(exp, 3)))
     return data_frame
end
 
get_frame(exp::Experiment{TWO_PHOTON, T}, frames::AbstractVector{<:Integer}) where T<:Real = cat((get_frame(exp, frame) for frame in frames)..., dims = 3)
 
function get_all_frames(exp::Experiment{TWO_PHOTON, T}) where T <: Real
     px, py = exp.HeaderDict["framesize"]
     return reshape(exp.data_array, px, py, size(exp, 2), size(exp, 3))
end

setScale(exp::Experiment{TWO_PHOTON, T}, pixels_per_micron) where T <: Real = exp.HeaderDict["PixelsPerMicron"] = pixels_per_micron

function getIMG_datetime(filename; timestamp_key = "date:create", fmt = dateformat"yyyy-mm-ddTHH:MM:SS") 
     properties = magickinfo(filename)
     HeaderDict = magickinfo(filename, properties)
     HeaderDict[timestamp_key] = DateTime(HeaderDict[timestamp_key][1:end-6], fmt)
     return HeaderDict[timestamp_key]
end

"""
    getIMG_size(image::AbstractArray{T}) -> Tuple{Int, Int}

Returns the size of the image as a tuple (height, width).
"""
function getIMG_size(data2P::Experiment{TWO_PHOTON, T}) where T<:Real
    x_pixels = data2P.HeaderDict["xrng"] |> length
    y_pixels = data2P.HeaderDict["yrng"] |> length
    return (x_pixels, y_pixels)
end