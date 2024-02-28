using Pkg
#%% Do any revisions to the base package (without Requires) here
using Revise
using ElectroPhysiology
#Change how stimulus protocol


#%% If you want to test packages that are included in Requires (or any other package) test them here (Run above code)
test_workspace_fn = raw"C:\Users\mtarc\.julia\dev\ElectroPhysiology\test"
Pkg.activate(test_workspace_fn)
using MAT

#%% Now we can load the MAT package to look at the data
ElectroPhysiology.__init__()
readMAT("test\\eWT_PD.mat")

a = rand(1, 4500)
b = rand(1, 4500)
trials = [a, b]
cat(trials..., dims = 3)
#%% Now we want to load and run the 
#%% Run things in the testing environment


using GLMakie
using Statistics
