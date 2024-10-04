function disk_se(radius)
    dims = (2*radius+1, 2*radius+1)
    center = (radius+1, radius+1)
    arr = [sqrt((i-center[1])^2 + (j-center[2])^2) <= radius for i in 1:dims[1], j in 1:dims[2]]
    return centered(arr)
end