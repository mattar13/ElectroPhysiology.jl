using Revise
using ElectroPhysiology

erg_dir = raw"F:\ERG\Retinoschisis\2019_03_12_AdultWT\Mouse1_Adult_WT\BaCl_LAP4\Rods"
erg_files = parseABF(erg_dir)

stim_channel = "IN 7"  # Set this to your stimulus channel (e.g. "Digital 1")
data = readABF(
    erg_files;
    stimulus_name=stim_channel,
    align_by_stimulus=true,
    t_pre=0.1,   # seconds before stimulus onset
    t_post=0.4,  # seconds after stimulus onset
)

data.data_array