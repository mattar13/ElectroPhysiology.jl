using Revise
using Pkg; Pkg.activate(".")
using ElectroPhysiology
using Pkg; Pkg.activate("test")
using GLMakie, PhysiologyPlotting
using StatsBase #Might need to add this to PhysiologyAnalysis as well

using GLMakie, PhysiologyPlotting

data2P_fn = "D:/Data/Two Photon/2024_08_08_OPN4_P20_SWCNT/light_stim003.tif"#might be good

#╔═╡Extract the image
data2P = readImage(data2P_fn);
xlims = data2P.HeaderDict["xrng"]
ylims = data2P.HeaderDict["yrng"]
deinterleave!(data2P) #This seperates the movies into two seperate movies
truncate_data!(data2P, t_begin = 200.0, t_end = 400.0)

#Here we should adjust some filtering things
kernel = Kernel.gaussian(3)
imfilter!(data2P, kernel; channel = 2)
mapwindow!(mean, data2P, (1,1, 9), channel = 1)
img_arr = get_all_frames(data2P)

#Extract the objects
grn_zstack = img_arr[:,:,:,1]
grn_zproj = project(data2P, dims = (3))[:,:,1,1]
grn_trace = project(data2P, dims = (1,2))[1,1,:,1]

red_zstack = img_arr[:,:,:,2]
red_zproj = project(data2P, dims = (3))[:,:,1,2]
red_trace = project(data2P, dims = (1,2))[1,1,:,2]

#%% Plot the figure
fig = Figure(size = (1000, 800))
ax1a = GLMakie.Axis(fig[1,1], title = "Green Channel", aspect = 1.0)
ax1b = GLMakie.Axis(fig[2,1], title = "Red Channel", aspect = 1.0)

ax2a = GLMakie.Axis(fig[1,2], title = "Green Trace")#, aspect = 1.0)
ax2b = GLMakie.Axis(fig[2,2], title = "Red Trace")#, aspect = 1.0)

mu_grn = mean(grn_zstack)
sig_grn = std(grn_zstack)*2

mu_red = mean(red_zstack)
sig_red = std(red_zstack)*2

hm2a = heatmap!(ax1a, xlims, ylims, grn_zstack[:,:,1], colormap = Reverse(:algae), colorrange = (0.0, mu_grn + sig_grn))
hm2b = heatmap!(ax1b, xlims, ylims, red_zstack[:,:,1], colormap = :gist_heat, colorrange = (0.0, mu_red + 2sig_red), alpha = 1.0)

lines!(ax2a, data2P.t, grn_trace, color = :green)
lines!(ax2b, data2P.t, red_trace, color = :red)

ticker1 = vlines!(ax2a, [0.0], color = :black)
ticker2 = vlines!(ax2b, [0.0], color = :black)
fig

#%%
fps = (1/data2P.dt) #Increase speed 5x

GLMakie.record(fig, "animation.mp4", enumerate(data2P.t), framerate = 5fps) do (i, t) 
    println(t)

    hm2a[3] = grn_zstack[:,:,i]
    hm2b[3] = red_zstack[:,:,i]
    ticker1[1] = [t]
    ticker2[1] = [t] 

end
fig