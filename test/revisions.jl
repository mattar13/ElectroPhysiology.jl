#using Pkg; Pkg.activate("test")
using Revise
using ElectroPhysiology
import ElectroPhysiology as EP

#%% I want to try to see if we can add a channel for a stimulus waveform

#The data file exists here
root = raw"E:\Data\Patching"
file = "2024_01_25_ChAT-RFP_DSGC/Cell1/24125000.abf"
filename = joinpath(root, file)

#get the abf info first
data = readABF(filename)

wvform = EP.create_signal_waveform(data, "Analog 0")
wvform.chNames
wvform.t

EP.create_signal_waveform!(data, "Analog 0")
data.chNames
data.data_array


#%% Now we begin a new venture. Opening images as files