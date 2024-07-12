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
#Lets write some tests for physiology analysis


#Test plotting
using GLMakie, PhysiologyPlotting