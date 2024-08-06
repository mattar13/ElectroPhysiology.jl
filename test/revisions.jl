using Revise
using Pkg; Pkg.activate(".")
using Dates, TimeZones
using ElectroPhysiology
using Pkg; Pkg.activate("test")
using GLMakie, PhysiologyPlotting
using StatsBase #Might need to add this to PhysiologyAnalysis as well

#%% There is something wrong with the timestamps
data2P_fn = raw"D:\Data\Calcium Imaging\2024_07_22_OPN4g_P7\cell_img1002.tif"
fig = Figure(size = (600, 600))
ax1a = GLMakie.Axis(fig[1,1], aspect = 1.0)
ax2a = GLMakie.Axis(fig[2,1])
ax1b = GLMakie.Axis(fig[1,2], aspect = 1.0)
ax2b = GLMakie.Axis(fig[2,2])

# ╔═╡Extract the image
data2P = readImage(data2P_fn);
deinterleave!(data2P)

red_zproj = project(data2P, dims = (3))[:,:,1,1]
red_img = RGBf.(red_zproj, zeros(size(red_zproj)), zeros(size(red_zproj)));
red_z_fit = fit(Histogram, red_zproj |> vec, LinRange(0.0, 1.0, 1000));

image!(ax1a, red_img)
lines!(ax2a, red_z_fit.edges[1][2:end], red_z_fit.weights)
xlims!(ax2a, 0.0, 1.0)

mu = mean(data2P, dims = (1,2))[1,1,1]
sig = std(data2P, dims = (1,2))[1,1,1]
adjustBC!(data2P, channel = 1, min_val_x = mu-0.05sig, max_val_x = mu+0.1sig)
#%%
red_zproj = project(data2P, dims = (3))[:,:,1,1]
red_img = RGBf.(red_zproj, zeros(size(red_zproj)), zeros(size(red_zproj)))
red_z_fit = fit(Histogram, red_zproj |> vec, LinRange(0.0, 1.0, 1000))

image!(ax1b, red_img)
lines!(ax2b, red_z_fit.edges[1][2:end], red_z_fit.weights)
xlims!(ax2a, 0.0, 1.0)

fig