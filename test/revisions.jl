using Revise
using ElectroPhysiology
import ElectroPhysiology as EP
using DataFrames, XLSX

#%% Saving a data to an XLSX file
test_file = "test/to_filter.abf"
data = readABF(test_file) |> data_filter
test = writeXLSX("test.xlsx", data)
#run(`powershell start excel.exe test.xlsx`) #Autoopen the file in excel

#How do you convert a XLSX file back into a datafile
readXLSX("test.xlsx")

#Open the dataframe
XLSX.openxlsx("test.xlsx", mode = "r") do xf
     println(XLSX.sheetnames(xf))
     headerSheet = xf["Header"]
     #get the number of channels
     headerSheet["A!"]
end


#%% Section 1, Opening Matlab IRIS files
PhysiologyAnalysis.__init__()
using DataFrames, Query, XLSX
using MAT
file = raw"C:\Users\mtarc\OneDrive - The University of Akron\Data\MAT files\2022-Feb-26_RBC_SPR.mat"
data = matopen(file)
vars = matread(file)

#%% Saving a file as a .abf
file_open = raw"C:\Users\mtarc\The University of Akron\Renna Lab - General\Data\ERG\Paul\Cones\2019_07_23_WT_P14_m1\Cones\Drugs\Green\nd0.5_1p_1ms\19723190.abf"
file_save = raw"C:\Users\mtarc\The University of Akron\Renna Lab - General\Data\ERG\Paul\Cones\2019_07_23_WT_P14_m1\Cones\Drugs\Green\nd0.5_1p_1ms\test.abf"
data = readABF(file_open, channels=-1) #This is necessary for saving
saveABF(data, file_save)