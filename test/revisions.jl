using Revise
using Pkg; Pkg.activate(".")
using ElectroPhysiology
using Pkg; Pkg.activate("test")
using GLMakie, PhysiologyPlotting
using StatsBase #Might need to add this to PhysiologyAnalysis as well
using ImageMorphology

ElectroPhysiology.__init__()

data2P_fn = raw"G:\Data\Two Photon\2024_10_01_VGGC6_P5_SWCNT\swcnt1b_0um_medium_4x_008.tif"
data2P = readImage(data2P_fn);
xlims = data2P.HeaderDict["xrng"]
ylims = data2P.HeaderDict["yrng"]
deinterleave!(data2P) #This seperates the movies into two seperate movies
size(data2P)

@time mapwindow(median, data_arr, (1, 81, 1));
@time mapwindow(median, data_arr[:, :, 1], (1, 101));

#=
fig = Figure(figsize = (500, 500))
ax1a = Axis(fig[1,1], aspect = 1.0)
ax1b = Axis(fig[2,1], aspect = 1.0)
twophotonprojection!(ax1a, data2P, channel = 1)
mean(data2P, dims = (1,2))
delta_ff!(data2P; channel = nothing)
twophotonprojection!(ax1b, data2P, channel = 1)
mean(data2P, dims = (1,2))

δ_ff = delta_ff(data2P)
=#