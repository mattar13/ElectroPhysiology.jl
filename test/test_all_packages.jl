#This can be used to test all packages and their compatibilities
test_workspace_fn = raw"C:\Users\mtarc\.julia\dev\ElectroPhysiology\test"
using Pkg
Pkg.activate(test_workspace_fn)
Pkg.status(outdated = true)

#Test the ElectroPhysiology package
using ElectroPhysiology

#Test the requires packages for ca imaging
using FileIO, Images, ImageView

#Test the requires packages for 
using Wavelets, ContinuousWavelets