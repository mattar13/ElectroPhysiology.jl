using Revise
using ElectroPhysiology
using Pkg; Pkg.activate("test")
using FileIO, ImageView, Images

data_root = raw"F:\Data"
ca_imaging_root = joinpath(data_root, "Calcium Images")
patching_root = joinpath(data_root, "Patching")
patch_fn = joinpath(patching_root, "2024_02_12_WT\\Cell1\\24212004.abf")
ca_img_fn = joinpath(ca_imaging_root, "2024_02_12_WT\\Cell1\\cell1001.tif")

data2P = readImage(ca_img_fn)
