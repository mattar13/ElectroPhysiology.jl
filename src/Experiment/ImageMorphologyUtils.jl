#These functions are for the opening algorithim
function disk_se(radius)
    dims = (2*radius+1, 2*radius+1)
    center = (radius+1, radius+1)
    arr = [sqrt((i-center[1])^2 + (j-center[2])^2) <= radius for i in 1:dims[1], j in 1:dims[2]]
    return centered(arr)
end

function delta_f_opening(exp::Experiment{TWO_PHOTON, T}; stim_channel = 1, channel = 2) where T<:Real
    img_arr = get_all_frames(exp) #Extract
    cell_activity_arr = img_arr[:,:,1,stim_channel] #We may want to use this to narrow our approach

    img_zstack = img_arr[:,:,:,channel]
    se = disk_se(15) #This is a structured element array with a radius of 15
    background = opening(img_zstack[:,:,1], se) #remove the background from the first frame
    zstack_backsub = img_zstack .- background #Subtract the background from the img_zstack

    #This section will depend on us pulling out all of the frames we expect to be background
    baselineFrames = floor(Int64, 0.05 * size(zstack_backsub, 3)) #We might need to do better wit this
    #baselineFrames = size(zstack_backsub, 3)

    f0 = mean(zstack_backsub[:,:,1:baselineFrames], dims = 3)[:,:,1] #Take the to calculate F0
    dFstack = zstack_backsub .- f0 #delta f = stack - f0
    return dFstack
end

#Instead lets try the median algorithim

function delta_f(exp::Experiment; median_window = 41, channel = 1)
    f0 = mapwindow(median, exp, (1, 1, median_window), channel = channel)
    δ_f = (exp-f0)
    return δ_f
end

function delta_ff(exp::Experiment; median_window = 41, channel = 1)
    f0 = mapwindow(median, exp, (1, 1, median_window), channel = channel)
    δ_f = (exp-f0)
    δ_ff = δ_f / maximum(f0, dims = (1,2))[channel]
    return δ_ff
end


function find_boutons(exp::Experiment; algo = :opening)
    dFstack = delta_f_opening(exp)
    dFstackMax = maximum(dFstack, dims = 3)[:,:,1] #take the maximum value of the delta F
    dFstackMaxSmooth = mapwindow(median, dFstackMax, (3,3)) #Do a median filter
    dFstackMaxSmoothNorm = dFstackMaxSmooth/maximum(dFstackMaxSmooth) #normalize
    dFFstackMaxSmoothNorm = dFstackMaxSmoothNorm./f0
    return dFFstackMaxSmoothNorm
end