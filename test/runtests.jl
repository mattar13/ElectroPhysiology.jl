using Test
using ElectroPhysiology

const test_single_trace = joinpath(@__DIR__, "raw_data", "24622008.abf")
const test_many_traces = joinpath(@__DIR__, "raw_data", "24622010.abf")
const testfile = test_single_trace

@testset "ElectroPhysiology.jl" begin
    include("testExperiments.jl")
    include("testABFReader.jl")
    include("testStimulusProtocols.jl")
    include("testFilters.jl")
    include("testImages.jl")
    include("revisions.jl")
end
