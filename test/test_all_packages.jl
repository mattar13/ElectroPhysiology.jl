#This can be used to test all packages and their compatibilities
using Pkg
Pkg.test() #Firs test the ElectroPhysiology package

Pkg.activate("test")
Pkg.status(outdated = true)

#Test the ElectroPhysiology package
using ElectroPhysiology

#Test the requires packages for ca imaging
using FileIO, Images, ImageView

#Test the requires packages for 
using Wavelets, ContinuousWavelets