using Pkg; Pkg.activate("")
using Plots, Measures
using Colors

# Define a function to draw a spiral
function spiral(t, a, b; beg = 0)
     if t > beg
          r = a + b * t
          x = r * cos(t)
          y = r * sin(t)
          return x, y
     else
          return t, t
     end
end

# Define a function to draw an action potential
function action_potential(t)
    v = 0.0
    if t < 0.5
        v = -70.0
    elseif t < 1.0
        v = -55.0 + 120.0 * (t - 0.5)
    elseif t < 1.5
        v = 65.0 - 75.0 * (t - 1.0)
    elseif t < 2.0
        v = -10.0 - 60.0 * (t - 1.5)
    else
        v = -70.0
    end
    return v
end

#%%
# Define the parameters for the spiral and the action potential
a = 10.0 # initial radius of the spiral
b = 1.0 # growth rate of the spiral
tmin = 0.0 # minimum angle of the spiral
tmax = 10 * pi # maximum angle of the spiral
dt = 0.01 # step size for the angle
vmin = -80.0 # minimum voltage of the action potential
vmax = 80.0 # maximum voltage of the action potential

# Generate the data points for the spiral and the action potential
t = tmin:dt:tmax # angle vector
res = spiral.(t, a, b) # spiral coordinates
xs = map(x -> x[1], res)
ys = map(x -> x[2], res)
vs = action_potential.(mod.(t, 2 * pi).-2.00) # action potential values
minimum(vs)
plot(xs, ys, vs+randn(size(vs)), 
     line_z = vs, c = :julia_colorscheme, legend=false, lw = 5, 
     camera =(0,80), 
     showaxis = false, grid = false, size = (500.0, 500.0), 
     margin = -100.0mm
     )
#plot!(xs, ys, zeros(length(xs)).-70.0, c = :black, lw = 2.0)
title!("ElectroPhysiology.jl", titlefontsize = 25, titlefontfamily = "MN Latin", )
     #zlabel!("ElectroPhysiology.jl")
#ylabel!("A Julia package for electrophysiology")