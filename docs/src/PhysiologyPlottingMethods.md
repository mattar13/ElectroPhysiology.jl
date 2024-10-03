## PhysiologyPlotting methods

To load PyPlot as a backend, export it with 
```
using PhysiologyPlotting
using PyPlot
```

```@docs
plot_experiment(axis::T, exp::Experiment;
    channels=1, sweeps = :all, 
    yaxes=true, xaxes=true, #Change this, this is confusing
    xlims = nothing, ylims = nothing,
    color = :black, cvals = nothing, clims = (0.0, 1.0), #still want to figure out how this wil work
    ylabel = nothing, xlabel = nothing,
    linewidth = 1.0, 
    kwargs...
) where T
```

```@docs
add_scalebar(axis, loc::Tuple{T,T}, dloc::Tuple{T,T};
    fontsize=10.0, lw=3.0,
    xlabeldist=30.0, ylabeldist=15.0,
    xunits="ms", yunits="μV",
    xconvert=1000.0, yconvert=1.0, #this converts the units from x and y labels. x should be in ms
    xround=true, yround=true,
    kwargs...
) where {T<:Real}
```

```@docs
add_sig_bar(axes, x::Real, y::Real; 
    level = "*", color = :black, 
    pointer = false,
    pointer_dx = 0.5,
    pointer_ylims = [2.0, 3.0], 
    lw = 1.0, fs = 12.0, ls = "solid"
)   
```

```@docs
draw_axes_border(ax; lw = 2.5, color = :black)
```


### Basic usage

~~~
#=====================================================================#
using ElectroPhysiology, PhysiologyPlotting
using GLMakie

#=[Point to filenames]================================================#
data_fn = "<DATA_FILEPATH.abf>"
save_fn = "<SAVE_FILEPATH.png>"

#=[Open data]=========================================================#
data = readABF(filename)

#=[Plot data]=========================================================#
fig, axs = experimentplot(data)
save(save_fn, fig)
~~~

data2P = readImage(data2P_fn);
deinterleave!(data2P) #This seperates the movies into two seperate movies

fig = Figure(figsize = (800, 800))
ax1 = Axis(fig[1,1], aspect = 1.0, title = "Frame 1")
ax2 = Axis(fig[1,2], aspect = 1.0, title = "Z projection)
frame = Observable(1)
tpf = twophotonframe!(ax1, data2P, frame, channel = 2, colorrange = (0.0, 0.02))
tpp = twophotonprojection!(ax2, data2P, dims = (1, 2), channel = 2)