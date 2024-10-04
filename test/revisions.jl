using Revise
using Pkg; Pkg.activate(".")
using ElectroPhysiology
using ImageMagick
using Images, .ImageMorphology
using Pkg; Pkg.activate("test")
using GLMakie, PhysiologyPlotting
using StatsBase #Might need to add this to PhysiologyAnalysis as well

file_loc = "D:/Data/Two Photon"
data2P_fn = "$(file_loc)/2024_09_03_SWCNT_VGGC6/swcntBATH_kpuff_nomf_20um001.tif"
data2P_fn = raw"D:\Data\Two Photon\2024_10_01_VGGC6_P5_SWCNT\swcnt1b_0um_medium_4x_008.tif"
data2P = readImage(data2P_fn);
xlims = data2P.HeaderDict["xrng"]
ylims = data2P.HeaderDict["yrng"]
deinterleave!(data2P) #This seperates the movies into two seperate movies

import ElectroPhysiology.disk_se
img_arr = get_all_frames(data2P)

red_zstack = img_arr[:,:,:,2]
red_img = red_zstack[:,:,1]
image(red_img)
se = disk_se(50) #Create a structured disc
out = opening(red_img, se)
image(out)

# Create a disk-shaped structuring element

#%%
using ImageMorphology
using TestImages
using ImageBase
using ImageShow

img = restrict(testimage_dip3e("fig0940")) # rice
img01 = @. Gray(img > 0.5)
mosaic(img, img01; nrow=1)

out1 = opening(img) # default: all spatial dimensions, r=1, a box-shape SE
out2 = opening(img; dims=(2,)) # only apply to the second dimension
out3 = opening(img; r=5) # half-size r=5

# also to the binary version
out1_01 = opening(img01)
out2_01 = opening(img01; dims=(2,))
out3_01 = opening(img01; r=5)

mosaic(out1, out2, out3, out1_01, out2_01, out3_01; nrow=2, rowmajor=true)
#%%
#truncate_data!(data2P, t_begin = 0.0, t_end = 100.0)

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