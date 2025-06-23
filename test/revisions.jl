using Revise
using Pkg; Pkg.activate(".")
using ElectroPhysiology

#Plots is added globally
using Plots
#Want to load the stimulus d

#Fix truncate so it cuts off stimulus not in the window
img_fn3 = raw"F:\Data\Two Photon\2025-05-15-GRAB-DA_STR\b5_grabda-nircat-300uA_pulse014.tif"
stim_fn3 = raw"F:\Data\Patching\2025-05-15-GRAB-DA-STR\25515021.abf"

data_img = readImage(img_fn3)
deinterleave!(data_img)
stimulus = readABF(stim_fn3, stimulus_name = "IN 3", stimulus_threshold = 0.5, flatten_episodic = true)
spike_train_group!(stimulus, 1.0)
addStimulus!(data_img, stimulus, "IN 3")
truncate_data!(data_img, 0.0, 400.0)

stimulus_idx = 2
main_t_stim = getStimulusEndTime(data_img)[stimulus_idx]
trunc_start = main_t_stim - 40
trunc_end = main_t_stim + 120

stim_2 = truncate_data(data_img, trunc_start, trunc_end)
t_stim = getStimulusEndTime(stim_2)[1]
stim_frame = round(Int, t_stim ./ stim_2.dt)

pixel_splits_roi!(stim_2, 8)

getROIarr(stim_2, [1,2, 3])
getROImask(stim_2, [1,2, 3])
#%%

img_fn = raw"F:\Data\Two Photon\2025-05-02-GRAB-DA-nirCAT-STR\grab-nircat-str-20hz-100uA001.tif"
stim_fn = raw"F:\Data\Patching\2025-05-02-GRAB-DA-STR\25502000.abf"

data2P = readImage(img_fn);
deinterleave!(data2P) #This seperates the movies into two seperate movies

#If we have a electrical stimulus we need to do the spike train analysis
addStimulus!(data2P, stim_fn, "IN 3", flatten_episodic = true, stimulus_threshold = 0.5)
stim_protocol = getStimulusProtocol(data2P)
#In the PhysiologyAnalysis package what we will do next is to iterate through the ROIs
stim_protocol
extractStimulus(stim_fn, "IN 3", flatten_episodic = true)


#%%
f = mean(data.data_array, dims = 1)[1,:,:]

#%% Make a multi-threading to do median filter
baselines = baseline_median(data, kernel_size = 500, channel = -1, border = NA())

#%%
fig = Figure()
ax1 = Axis(fig[1,1])
ax2 = Axis(fig[2,1])

d0 = mean(baselines, dims = 1)[1,:,:]
lines!(ax1, data.t, f[:,1])
lines!(ax1, data.t, d0[:,1])

lines!(ax2, data.t, f[:,2])
lines!(ax2, data.t, d0[:,2])

ax1b = Axis(fig[1,2])
ax2b = Axis(fig[2,2])
lines!(ax1b, data.t, f[:, 1] - d0[:,1])
lines!(ax2b, data.t, f[:, 2] - d0[:,2])

fig

#%% We have stimulus protocols that are a flicker response
fn = raw"F:\Data\Patching\2025-03-26-GRAB-DA_STR\25326048.abf"
dataStim = readABF(fn, flatten_episodic = true, stimulus_name = "IN 3", stimulus_threshold = 0.5);
spike_train_group!(stim_protocol, 3.0)
dataStim.chNames
stim_protocol = getStimulusProtocol(dataStim)

stim_protocol.timestamps


experimentplot(dataStim, channel = 3)

for (k, v) in dataStim.HeaderDict
    println("$k")
end
dataStim.HeaderDict["ProtocolSection"]["nActiveDACChannel"]
dataStim.HeaderDict["EpochSection"]["nEpochDigitalOutput"][3]
EpochTable = dataStim.HeaderDict["EpochTableByChannel"]
#In the epoch table, 15000 is the samples 
dataStim.dt

EpochTable[1].epochs[2].duration*dataStim.dt#This is the duration of the first epoch in seconds


#%% I would like to add flash intensity to the ERG data
fn = raw"E:\Data\ERG\Retinoschisis\2022_03_17_WTAdult\Mouse1_Adult_WT\NoDrugs\Rods\nd2_1p_0000.abf"
dataERG = readABF(fn, flatten_episodic = false, stimulus_name = "IN 7", average_trials = true);


#We have to edit the stimulus 
#addStimulus!(dataERG, "IN 7"); #Have to add this any time you add a stimulus
truncate_data!(dataERG, t_pre = 0.15, t_post = 3.0, time_zero = true, truncate_based_on=:stimulus_beginning);

fig = Figure()
ax1 = Axis(fig[1,1])
ax2 = Axis(fig[2,1])
experimentplot!(ax1, dataERG, channel = 1)
experimentplot!(ax2, dataERG, channel = 3)

fig

#%%
using StatsBase #Might need to add this to PhysiologyAnalysis as well
using ImageMorphology
using Dates
import ElectroPhysiology.getRealTime
ElectroPhysiology.__init__()

#%% I would like to extract this data as a stimulus object
data2P_fn = raw"G:\Data\Two Photon\2025-02-14-GRAB-DA\GRAB-DA2m-R1-R_da_puff_100um004.tif"
data2P = readImage(data2P_fn)

data_ic_fn = raw"G:\Data\Patching\2025-02-14-da_puffs\25214001.abf"
addStimulus!(data2P, data_ic_fn, "IN 2")

z_mean = project(data2P, dims = (1,2))[1,1,:,1]


data_2P_fn = raw"G:\Data\Two Photon\2024_12_04_SlidePuffs\da1mM_1-50_785001.tif"
#%%
data2P = readImage(data_2P_fn)
deinterleave!(data2P)

#Extract the data_ic_fn as a stimulus object

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