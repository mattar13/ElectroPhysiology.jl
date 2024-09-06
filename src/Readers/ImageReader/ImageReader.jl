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
     objective = 60, verbose = true
) where T <: Real
     data_array = load(filename) |> Array{T}
     if verbose
          println("data loaded")
     end

     properties = magickinfo(filename)
     println("1")
     HeaderDict = magickinfo(filename, properties)
     println("2")
     HeaderDict["date:create"] = DateTime(HeaderDict["date:create"][1:end-6], dateformat"yyyy-mm-ddTHH:MM:SS")
     println("3")
     HeaderDict["date:modify"] = DateTime(HeaderDict["date:modify"][1:end-6], dateformat"yyyy-mm-ddTHH:MM:SS")
     
     if verbose
          println("Header loaded")
     end
     px_x, px_y, n_frames = size(data_array)

     HeaderDict["framesize"] = (px_x, px_y)
     HeaderDict["detector_wavelength"] = [594]
     HeaderDict["ROIs"] = zeros(Int64, px_x*px_y) #Currently ROIs are empty
     
     #Extract and split the two photon information
     comment_string = HeaderDict["comment"]
     comment_substrings = split(comment_string, "\r")[1:end-1]
     for comment_string in comment_substrings
          further_substr = split(comment_string, "=")
          is_int = tryparse(Int64, further_substr[2] |> String)
          is_float = tryparse(Float64, further_substr[2] |> String)
          if !isnothing(is_int)
               HeaderDict[further_substr[1]] = is_int
          elseif !isnothing(is_float)
               HeaderDict[further_substr[1]] = is_float
          else
               HeaderDict[further_substr[1]] = further_substr[2] |> String
          end
     end
     HeaderDict["FileStartDateTime"] = DateTime(HeaderDict["state.internal.triggerTimeString"], "'m/d/Y H:M:S.s'")
     zoom = HeaderDict["state.acq.zoomFactor"]
     
     fov = objective_calibration[objective] #this returns the micron scale of one field of view
     HeaderDict["PixelsPerMicron"] = px_x/(fov/zoom) #This will need to be overhauled once we get info about size
     HeaderDict["xrng"] = LinRange(0, fov/zoom, px_x)
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

function get_frame(exp::Experiment{TWO_PHOTON, T}, frame::Int64) where T <: Real
     px, py = exp.HeaderDict["framesize"]
     data_frame = reshape(exp.data_array[:, frame, :], (px, py, 1, size(exp, 3)))
     return data_frame
end
 
get_frame(exp::Experiment{TWO_PHOTON, T}, frames::AbstractArray) where T<:Real = cat(map(frame -> get_frame(exp, frame), frames)..., dims = 3)
 
function get_all_frames(exp::Experiment{TWO_PHOTON, T}) where T <: Real
     n_frames = size(exp, 2)
     return get_frame(exp, 1:n_frames)
end

setScale(exp::Experiment{TWO_PHOTON, T}, pixels_per_micron) where T <: Real = exp.HeaderDict["PixelsPerMicron"] = pixels_per_micron

function getIMG_datetime(filename; timestamp_key = "date:create", fmt = dateformat"yyyy-mm-ddTHH:MM:SS") 
     properties = magickinfo(filename)
     HeaderDict = magickinfo(filename, properties)
     HeaderDict[timestamp_key] = DateTime(HeaderDict[timestamp_key][1:end-6], fmt)
     return HeaderDict[timestamp_key]
end