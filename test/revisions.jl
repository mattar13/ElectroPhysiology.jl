#None at this time

using ElectroPhysiology

test_file = raw"test/to_analyze.abf"
data = readABF(test_file)
size(data)

data_avg = average_sweeps(data)
size(data_avg)
