using Revise
using Dates, TimeZones
using ElectroPhysiology
import ElectroPhysiology.convert_stimulus!
using Pkg; Pkg.activate("test")
using ImageView, FileIO, Images, ImageMagick

#%% There is something wrong with the timestamps
ElectroPhysiology.__init__()
filename = raw"D:\Data\Calcium Imaging\2024_06_22_VCGC6s_P8\ca_img1001.tif"
img_data = readImage(filename)

img_data.HeaderDict["FileStartDateTime"]

for (k, v) in img_data.HeaderDict
    if occursin("state.internal", k)
        println("$k -> $v")
    end
end


