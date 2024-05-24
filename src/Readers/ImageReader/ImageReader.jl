objective_calibration = Dict(
     16 => 850, 
)

# For now we really don't have this function do anything else other than load
# We eventually want to load
# Zoom level
# FPS
#Size
#TODO: Remember that the images might be misaligned in plotting. Maybe we need to define this in Plotting
function readImage(::Type{T}, filename; 
     sampling_rate = 1.47, chName = "CalBryte590", chUnit = "px", chGain = 1.0,
     objective = 16, zoom = 1
) where T <: Real
     data_array = load(filename) |> Array{T}
     px_x, px_y, n_frames = size(data_array)

     scale = objective_calibration[objective] #this returns the micron scale of one field of view

     HeaderDict = Dict( 
          "framesize" => (px_x, px_y),
          "xrng" => 1:px_x, "yrng" => 1:px_y,
          "detector_wavelength" => [594],
          "ROIs" => zeros(Int64, px_x*px_y), #Currently ROIs are empty
          "PixelsPerMicron" => px_x/scale*zoom
     ) #We need to think of other important data aspects
     #Resize the data so that all of the pixels are in single value
     resize_data_arr = reshape(data_array, px_x*px_y, n_frames, 1)
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