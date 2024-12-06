using Revise
using Pkg; Pkg.activate(".")
using ElectroPhysiology
using Pkg; Pkg.activate("test")
using GLMakie, PhysiologyPlotting
using StatsBase #Might need to add this to PhysiologyAnalysis as well
using ImageMorphology
import ElectroPhysiology.getRealTime
using Dates
ElectroPhysiology.__init__()

data_ic_fn = raw"G:\Data\Patching\2024_12_04_Slide_KPUFF\24d04000.abf"
data_2P_fn = raw"G:\Data\Two Photon\2024_12_04_SlidePuffs\da1mM_1-50_785001.tif"
dataIC = readABF(data_ic_fn, flatten_episodic = true)
data2P = readImage(data_2P_fn)
deinterleave!(data2P)

zproj = project(data2P, dims = (1,2))[1,1,:,:]
realtime_2P = getRealTime(data2P)

ic_vals = dataIC.data_array[1,:,3]
realtime_ic = getRealTime(dataIC)


#%%
fig = Figure(resolution = (800, 600))
ax1 = Axis(fig[1, 1])
ax2 = Axis(fig[2, 1])
ax3 = Axis(fig[3, 1])
linkxaxes!(ax1, ax2, ax3)
lines!(ax1, realtime_ic, ic_vals)
lines!(ax2, realtime_2P, zproj[:,1], color = :green)
lines!(ax3, realtime_2P, zproj[:,2], color = :red)
fig



#%%We want to bin the data 
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