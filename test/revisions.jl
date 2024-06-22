using Revise
using ElectroPhysiology
import ElectroPhysiology.convert_stimulus!
using Pkg; Pkg.activate("test")
using ImageView, FileIO, Images, ImageMagick
cell_img_fn = raw"D:\Data\Calcium Imaging\2024_05_23_MORF_ChATCre\ca_img_5011.tif"

ElectroPhysiology.__init__()
@time ca_img_exp = readImage(cell_img_fn);
@time getIMG_datetime(cell_img_fn);