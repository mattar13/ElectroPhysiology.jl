using ElectroPhysiology
using Test

@testset "Testing Experiement struct" begin
    time = collect(1:0.01:1000) #Create some time range
    data = rand(5, length(time), 1) #Create some dummy data

    exp = ElectroPhysiology.Experiment(data)
    @test !isnothing(exp)

    exp_w_time = ElectroPhysiology.Experiment(time, data)
    @test !isnothing(exp_w_time)
end

@testset "Testing ABF reader" begin
    testfile = raw"to_filter.abf"
    data = readABF(testfile)
    @test !isnothing(data)


end
