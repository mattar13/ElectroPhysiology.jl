using Revise
using Pkg; Pkg.activate(".")
using ElectroPhysiology
using Pkg; Pkg.activate("test")
using GLMakie, PhysiologyPlotting
using StatsBase #Might need to add this to PhysiologyAnalysis as well
using ImageMorphology

ElectroPhysiology.__init__()

#%%
data2P_fn = raw"G:\Data\Two Photon\2024_10_01_VGGC6_P5_SWCNT\swcnt1b_0um_medium_4x_008.tif"
data2P = readImage(data2P_fn)
xlims = data2P.HeaderDict["xrng"]
ylims = data2P.HeaderDict["yrng"]
deinterleave!(data2P) #This seperates the movies into two seperate movies
δ_ff = delta_ff(data2P, window = 21, channel = 1)
delta_ff!(δ_ff, window = 101, channel = 2)

fig = Figure(figsize = (500, 500))
ax1a = Axis(fig[1,1], aspect = 1.0)
ax1b = Axis(fig[1,2], aspect = 1.0)
twophotonprojection!(ax1a, data2P, channel = 1, dims = (1,2))
twophotonprojection!(ax1b, δ_ff, channel = 1, dims = (1,2))

ax2a = Axis(fig[2,1], aspect = 1.0)
ax2b = Axis(fig[2,2], aspect = 1.0)
twophotonprojection!(ax2a, data2P, channel = 2, dims = (1,2))
twophotonprojection!(ax2b, δ_ff, channel = 2, dims = (1,2))
display(fig)