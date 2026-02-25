using Revise
using ElectroPhysiology

erg_dir = raw"F:\ERG\Retinoschisis\2019_03_12_AdultWT\Mouse1_Adult_WT\BaCl_LAP4\Rods"
erg_files = parseABF(erg_dir)

data = openERGData(erg_files)
size(data)