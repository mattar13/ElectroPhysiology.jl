@testset "Testing data filtering" begin
     testfile = raw"to_analyze.abf"
     data = readABF(testfile)
     @test isa(data, ElectroPhysiology.Experiment)
     data_filtered = filter_data(data)
     @test !isnothing(data_filtered)
 
     data_normalized = normalize(data)
     @test !isnothing(data_normalized)
end

