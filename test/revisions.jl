using Revise
using Pkg; Pkg.activate(".")
using ElectroPhysiology
using Pkg; Pkg.activate("test")
using GLMakie, PhysiologyPlotting
using StatsBase #Might need to add this to PhysiologyAnalysis as well
using ImageMorphology

ElectroPhysiology.__init__()

data2P_fn = raw"D:\Data\Two Photon\2024_11_06_HB9-GFP\cell_fill3002.tif"
#data2P_fn = raw"D:\Data\Two Photon\2024_10_08_VGGC6_P12_SWCNT\swcnt_1b_spicy_0um011.tif"
data2P = readImage(data2P_fn)
xlims = data2P.HeaderDict["xrng"]
ylims = data2P.HeaderDict["yrng"]
deinterleave!(data2P) #This seperates the movies into two seperate movies
size(data2P, 3)
#We want to bin the data 
bin!(mean, data2P, (1,1,5))

img_arr = get_all_frames(data2P)
#%%
dff = delta_ff(data2P, window = 41)
mapdata(median, data2P, 21, border = "symmetric")

#%%
fig = Figure(size = (1200, 700), px_per_unit = 2)
ax1a = GLMakie.Axis(fig[1,1], aspect = 1.0)
twophotonprojection!(ax1a, dff, channel = 1, dims = 3)

ax1b = GLMakie.Axis(fig[1,2:4], yticklabelsize = 24, xticklabelsize = 24, ygridvisible = false); hidexdecorations!(ax1b)
twophotonprojection!(ax1b, dff, channel = 1, dims = (1,2), linewidth = 2.0)

ax2a = GLMakie.Axis(fig[2,1], aspect = 1.0)
twophotonprojection!(ax2a, dff, channel = 2, dims = 3)

ax2b = GLMakie.Axis(fig[2,2:4], yticklabelsize = 24, xticklabelsize = 24, ygridvisible = false, xgridvisible = false)
twophotonprojection!(ax2b, dff, channel = 2, dims = (1,2), linewidth = 2.0)

display(fig)