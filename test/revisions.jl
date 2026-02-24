using Revise
using Pkg; Pkg.activate(".")
using ElectroPhysiology


#Lets open a .abf file and see if we can revamp and improve anything. 

erg_file = raw"F:\ERG\Retinoschisis\2019_03_12_AdultWT\Mouse1_Adult_WT\BaCl_LAP4\Rods\nd0_1p_2ms.abf"
data = readABF(erg_file)