@testset "Testing data filtering" begin
     test_single_traces = raw"to_analyze.abf"
     data = readABF(test_single_traces)
     @test isa(data, ElectroPhysiology.Experiment)
     data_filtered = filter_data(data)
     @test !isnothing(data_filtered)
 
     data_normalized = normalize(data)
     @test !isnothing(data_normalized)
end

