using Revise, ElectroPhysiology
import ElectroPhysiology: drop, drop!

testfile = raw"test\to_analyze.abf"
data = readABF(testfile)