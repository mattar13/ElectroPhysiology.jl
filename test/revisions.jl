using Revise
using ElectroPhysiology
import ElectroPhysiology.convert_stimulus!
using Pkg; Pkg.activate("test")
using ImageView, FileIO, Images
cell_img_fn = raw"D:\Data\Calcium Imaging\2024_05_23_MORF_ChATCre\ca_img_5011.tif"

data = readImage(cell_img_fn)
deinterleave!(data) #This seperates the movies into two seperate movies
ElectroPhysiology.__init__()

img_arr = get_all_frames(data)
green_ch = project(data, dims = 3)[:,:,1,1]
green_ch = project(data, dims = 3)[:,:,1,2]
fluo_project = project(data, dims = (1,2))[1,1,:,1]