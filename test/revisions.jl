using Revise
using Pkg; Pkg.activate(".")
using ElectroPhysiology
using Pkg; Pkg.activate("test")
using GLMakie, PhysiologyPlotting
using StatsBase #Might need to add this to PhysiologyAnalysis as well
using ImageMorphology
import ElectroPhysiology.disk_se

file_loc = "D:/Data/Two Photon"
data2P_fn = "$(file_loc)/2024_09_03_SWCNT_VGGC6/swcntBATH_kpuff_nomf_20um001.tif"
data2P_fn = raw"D:\Data\Two Photon\2024_10_01_VGGC6_P5_SWCNT\swcnt1b_0um_medium_4x_008.tif"
data2P = readImage(data2P_fn);
xlims = data2P.HeaderDict["xrng"]
ylims = data2P.HeaderDict["yrng"]
deinterleave!(data2P) #This seperates the movies into two seperate movies

fig = Figure(figsize = (500, 500))
ax1a = Axis(fig[1,1], aspect = 1.0)
ax1b = Axis(fig[2,1], aspect = 1.0)
twophotonprojection!(ax1a, data2P, channel = 1)
mean(data2P, dims = (1,2))
delta_ff!(data2P; channel = nothing)
twophotonprojection!(ax1b, data2P, channel = 1)
mean(data2P, dims = (1,2))

δ_ff = delta_ff(data2P)
#%%



ax1c = Axis(fig[3,1], aspect = 1.0)
#ax2b = Axis(fig[2,2])#, aspect = 1.0)
#twophotonframe!(ax1a, data2P, 1, channel = 2) 
twophotonprojection!(ax1c, data2P, dims = 3, channel = 2, color = :red) 
twophotonprojection!(ax1b, data2P, dims = 3, channel = 2, color = :red) 
twophotonprojection!(ax2b, δ_ff, dims = (1,2), channel = 2) 
#twophotonprojection!(ax2a, δ_ff, dims = (1,2), channel = 1, color = :red) 