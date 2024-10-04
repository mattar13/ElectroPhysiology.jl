using Revise
using Pkg; Pkg.activate(".")
using ElectroPhysiology
using ImageMagick
using Images
using Pkg; Pkg.activate("test")
using GLMakie, PhysiologyPlotting
using StatsBase #Might need to add this to PhysiologyAnalysis as well
using ImageMorphology
import ElectroPhysiology.disk_se

file_loc = "G:/Data/Two Photon"
data2P_fn = "$(file_loc)/2024_09_03_SWCNT_VGGC6/swcntBATH_kpuff_nomf_20um001.tif"
data2P_fn = raw"G:\Data\Two Photon\2024_10_01_VGGC6_P5_SWCNT\swcnt1b_0um_medium_4x_008.tif"
data2P = readImage(data2P_fn);
xlims = data2P.HeaderDict["xrng"]
ylims = data2P.HeaderDict["yrng"]
deinterleave!(data2P) #This seperates the movies into two seperate movies

img_arr = get_all_frames(data2P)
red_zstack = img_arr[:,:,:,2]
red_img = red_zstack[:,:,1]

function delta_ff(exp::Experiment{TWO_PHOTON, T}; stim_channel = 1, channel = 2) where T<:Real
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

     dFstackMax = maximum(dFstack, dims = 3)[:,:,1] #take the maximum value of the delta F
     dFstackMaxSmooth = mapwindow(median, dFstackMax, (3,3)) #Do a median filter
     dFstackMaxSmoothNorm = dFstackMaxSmooth/maximum(dFstackMaxSmooth) #normalize

     dFFstackMaxSmoothNorm = dFstackMaxSmoothNorm./f0
     return dFFstackMaxSmoothNorm
end

res = delta_ff(data2P)
heatmap(res[:,:]')


#%%
fig = Figure(figsize = (500, 500))
ax1a = Axis(fig[1,1], aspect = 1.0)
ax1b = Axis(fig[1,1], aspect = 1.0)
ax2a = Axis(fig[2,1], aspect = 1.0)
ax2b = Axis(fig[2,2], aspect = 1.0)
twophotonframe!(ax1a, data2P, 1, channel = 2) 
twophotonprojection!(ax1a, data2P, dims = 3, channel = 2) 

size(data2P)

for (k, d) in data2P.HeaderDict
     if k != "ROIs"
          println("$k => $d")
     else
          println("$k")
     end
end

baseline_adjust!(data2P, channel = 2)

#Extract the objects
grn_zstack = img_arr[:,:,:,1]
grn_zproj = project(data2P, dims = (3))[:,:,1,1]
grn_trace = project(data2P, dims = (1,2))[1,1,:,1]

red_zstack = img_arr[:,:,:,2]
red_zproj = project(data2P, dims = (3))[:,:,1,2]
red_trace = project(data2P, dims = (1,2))[1,1,:,2]

#%% Plot the figure
fig = Figure(size = (1000, 800))
ax1a = GLMakie.Axis(fig[1,1], title = "Green Channel", aspect = 1.0)
ax1b = GLMakie.Axis(fig[2,1], title = "Red Channel", aspect = 1.0)

ax2a = GLMakie.Axis(fig[1,2], title = "Green Trace")#, aspect = 1.0)
ax2b = GLMakie.Axis(fig[2,2], title = "Red Trace")#, aspect = 1.0)

mu_grn = mean(grn_zstack)
sig_grn = std(grn_zstack)*2

mu_red = mean(red_zstack)
sig_red = std(red_zstack)*2

hm2a = heatmap!(ax1a, xlims, ylims, grn_zstack[:,:,1], colormap = Reverse(:algae), colorrange = (0.0, mu_grn + sig_grn))
hm2b = heatmap!(ax1b, xlims, ylims, red_zstack[:,:,1], colormap = :gist_heat, colorrange = (0.0, mu_red + 2sig_red), alpha = 1.0)

lines!(ax2a, data2P.t, grn_trace, color = :green)
lines!(ax2b, data2P.t, red_trace, color = :red)

ticker1 = vlines!(ax2a, [0.0], color = :black)
ticker2 = vlines!(ax2b, [0.0], color = :black)
fig