using ElectroPhysiology
using Test
testfile = "to_filter.abf"
testfile2 = "to_analyze.abf"

#We need to open this here to do most of the testing
include("testExperiments.jl")

include("testStimulusProtocols.jl")

include("testABFReader.jl")

include("testFilters.jl")