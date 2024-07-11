using Test
using ElectroPhysiology
import ElectroPhysiology: Experiment, StimulusProtocol

test_many_traces = "24622008.abf"
test_single_trace = "24622010.abf"

#We need to open this here to do most of the testing
include("testExperiments.jl")

include("testABFReader.jl")

#Not ready for this test yet I think
#include("testStimulusProtocols.jl")

include("testImages.jl")

include("testFilters.jl")

#Test analysis
using PhysiologyAnalysis

#Test plotting
using GLMakie, PhysiologyPlotting

data_single = readABF("test\\$(test_single_trace)")
data_many = readABF("test\\$(test_many_traces)")

data_many.chNames