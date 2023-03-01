using Revise, ElectroPhysiology
import ElectroPhysiology: drop, drop!

testroot = raw"C:\Users\mtarc\OneDrive - The University of Akron\Data\ERG\Retinoschisis\2023_02_23_MattR141C"
testfiles = testroot |> parseABF

testfile = raw"test\to_analyze.abf"
data = readABF(testfile)
datacopy = deepcopy(data)

concat(data, datacopy)