using Revise
using Pkg; Pkg.activate(".")
using ElectroPhysiology
using Pkg; Pkg.activate("test")
using GLMakie, PhysiologyPlotting
using StatsBase #Might need to add this to PhysiologyAnalysis as well
using ImageMorphology
using Dates
import ElectroPhysiology.getRealTime
ElectroPhysiology.__init__()

data_ic_fn = raw"G:\Data\Patching\2024_12_04_Slide_KPUFF\24d04000.abf"
data_2P_fn = raw"G:\Data\Two Photon\2024_12_04_SlidePuffs\da1mM_1-50_785001.tif"
#%%
dataIC = readABF(data_ic_fn, flatten_episodic = true)
data2P = readImage(data_2P_fn)
deinterleave!(data2P)

#%%
@time median_filtered = mapdata_median(data2P, 151, channel = 2);


fig = Figure()
ax1a = Axis(fig[1,1])
twophotonprojection!(ax1a, median_filtered, channel = 1)

ax1b = Axis(fig[1,2])
twophotonprojection!(ax1b, median_filtered, channel = 2)

ax2a = Axis(fig[2,1])
twophotonprojection!(ax2a, data2P, dims = (1,2), channel = 1, color = :red)
twophotonprojection!(ax2a, median_filtered, dims = (1,2), channel = 1)

ax2b = Axis(fig[2,2])
twophotonprojection!(ax2b, data2P, dims = (1,2), channel = 2, color = :red)
twophotonprojection!(ax2b, median_filtered, dims = (1,2), channel = 2)
fig

#%%
zproj = project(data2P, dims = (1,2))[1,1,:,:]
ic_vals = dataIC.data_array[1,:,3]

#Calculate the time sync between the start of the 2P and start of the pizo driver
start2P = data2P.HeaderDict["FileStartDateTime"]-Second(3.0) #The computer clocks are off by 3 seconds
startIC = dataIC.HeaderDict["FileStartDateTime"]
t_offset = Millisecond(startIC - start2P) 
time_offset!(dataIC, t_offset)

#program the time offset into a single function
t_episodes, eps_idx_IC = find_stim_index(dataIC)
#To convert the values from t_episodes into the data from data2P, divide the t_episodes by data2P.dt
eps_idxs_2P = round.(Int64, (t_episodes./data2P.dt))


#%% 
fig = Figure(title = "Testing delta F/F")
ax1 = Axis(fig[1,1])
twophotonprojection!(ax1, data2P)

ax2a = Axis(fig[2,1])
ax2b = Axis(fig[2,2])
ax2c = Axis(fig[2,3])

fig
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