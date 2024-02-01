#using Pkg; Pkg.activate("test")
using Revise
using ElectroPhysiology
import ElectroPhysiology as EP

root = raw"E:\Data\Patching"
file = "2024_01_25_ChAT-RFP_DSGC/Cell1/24125002.abf"
filename = joinpath(root, file)
data = readABF(filename)
create_signal_waveform!(data, "Cmd 0")
data.chNames
data.chUnits

#%% Now we begin a new venture. Opening images as files
using Pkg; Pkg.activate("test")
using FileIO, ImageView, Images