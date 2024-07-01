#This can be used to test all packages and their compatibilities
using Revise
test_workspace_fn = raw"C:\Users\mtarc\.julia\dev\ElectroPhysiology\test"
using Pkg
Pkg.activate(test_workspace_fn)
Pkg.status(outdated = true)

#Test the ElectroPhysiology package
using ElectroPhysiology

using PhysiologyAnalysis
using XLSX, Query, DataFrames

using PhysiologyPlotting, GLMakie

#Test the requires packages for 
using Wavelets, ContinuousWavelets