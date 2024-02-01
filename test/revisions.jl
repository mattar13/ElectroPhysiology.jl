using Revise
using ElectroPhysiology
import ElectroPhysiology as EP

#%% Now we begin a new venture. Opening images as files
using Pkg; Pkg.activate("test")
using FileIO, ImageView, Images
using GLMakie

#%%
root = raw"D:\Data\Calcium Images\2024_01_31_FRMD7_Cal590"
file = "2024_01_31_ROI003.tif"
filename = joinpath(root, file)
data = load(filename) |> Array{Float64}
data = permutedims(data, (2,1,3))
x_size = 1:size(data,1)
y_size = 1:size(data,2)
zavg = z_project(data, dims = 3)
zproj = z_project(data, dims = (1,2))

fig = GLMakie.Figure(size = (1500, 400))
ax11 = GLMakie.Axis(fig[1,1])
ax12 = GLMakie.Axis3(fig[1,2])
ax21 = GLMakie.Axis(fig[2,1])
ax22 = GLMakie.Axis3(fig[2,2])
ax3 = GLMakie.Axis(fig[3,1])

heatmap!(ax11, x_size, y_size, zavg, colormap = Reverse(:algae), colorrange = (0.0, 0.05))
surface!(ax12, x_size, y_size, zavg, colormap = Reverse(:algae), colorrange = (0.0, 0.05))
hm = heatmap!(ax21, x_size, y_size, data[:,:,1], colormap = Reverse(:algae), colorrange = (0.0, 0.05))
sf = surface!(ax22, x_size, y_size, data[:,:,1], colormap = Reverse(:algae), colorrange = (0.0, 0.05))
lines!(ax3, zproj)
ln_spot = lines!(ax3, fill(0.0, 2), [minimum(zproj), maximum(zproj)], color = :black)

record(fig, "$root/$(file[1:end-4])_ANIMATION.mp4", 2:size(data,3)) do i 
    println(i)
    frame = data[:,:,i]
    ln_spot[1] = fill(i, 2)
    hm[3] = frame
    sf[3] = frame
end
display(fig)

#%% This function just load the command 
root = raw"E:\Data\Patching"
file = "2024_01_25_ChAT-RFP_DSGC/Cell1/24125002.abf"
filename = joinpath(root, file)
data = readABF(filename)
create_signal_waveform!(data, "Cmd 0")
data.chNames
data.chUnits


