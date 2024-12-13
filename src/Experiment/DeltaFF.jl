"""
Delta F over F function

'mode' = [mean, median, filter]
- mean
- median: utilized 
"""

function delta_ff!(exp::Experiment; window = 21, mode = :mean, channel = nothing)
    if isnothing(channel)
        for (idx, ch) in enumerate(eachchannel(exp))
            delta_ff!(exp, channel = idx, window = window, fn = fn)
        end
    else #The main analysis loop is contained here

    end
end

function delta_ff(exp::Experiment; kwargs...)
    exp_copy = deepcopy(exp)
    delta_ff!(exp_copy; kwargs...)
    return exp_copy
end


#=[Experimental localization functions]=================================================================================================#
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

function find_boutons(exp::Experiment; algo = :opening)
    dFstack = delta_f_opening(exp)
    dFstackMax = maximum(dFstack, dims = 3)[:,:,1] #take the maximum value of the delta F
    dFstackMaxSmooth = mapwindow(median, dFstackMax, (3,3)) #Do a median filter
    dFstackMaxSmoothNorm = dFstackMaxSmooth/maximum(dFstackMaxSmooth) #normalize
    dFFstackMaxSmoothNorm = dFstackMaxSmoothNorm./f0
    return dFFstackMaxSmoothNorm
end