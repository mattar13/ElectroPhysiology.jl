collapse_dims(a) = dropdims(a, dims = (findall(size(a) .== 1)...,))

function z_project(data; dims = [1,2], xy_roi = nothing)
    if isnothing(xy_roi)
        size_avg = map(d -> size(data, d), dims)
        zproj = (sum(data, dims = dims)) |> collapse_dims
        zproj ./= *(size_avg...)
        return zproj
    elseif isa(xy_roi, Tuple)
        println("Selecting a certain region")
    end
end

function get_frame(exp::Experiment{TWO_PHOTON, T}, frame::Int64) where T <: Real
    px, py = exp.HeaderDict["framesize"]
    data_frame = reshape(exp.data_array[:, frame], (px, py, 1))
    return data_frame
end

get_frame(exp::Experiment{TWO_PHOTON, T}, frames::AbstractArray) where T<:Real = cat(map(frame -> get_frame(exp, frame), frames)..., dims = 3)
