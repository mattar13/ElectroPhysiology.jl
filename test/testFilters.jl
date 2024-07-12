@testset "Testing data filtering" begin
     data = readABF(test_single_trace)
     @test isa(data, ElectroPhysiology.Experiment)
     data_filtered = filter_data(data)
     @test !isnothing(data_filtered)
 
     data_normalized = normalize(data)
     @test !isnothing(data_normalized)
end

