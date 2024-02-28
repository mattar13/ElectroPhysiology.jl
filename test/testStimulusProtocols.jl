@testset "Stimulus construction" begin
    @test !isnothing(StimulusProtocol())
    @test !isnothing(StimulusProtocol("TEST NAME"))
    @test !isnothing(StimulusProtocol(10))
    stim = StimulusProtocol("DAC1", 10)
    @test length(stim) == 10
    @test isa(stim[1], StimulusProtocol)
    @test stim[1].timestamps == [(0.0, 0.0)]
end

@testset "Modifying Stimulus protocols" begin

    stim = StimulusProtocol("DAC1", 10)
    stim[1] = (0.0, 1.0)
    @test isa(stim[1], StimulusProtocol)
    @test stim[1].timestamps == [(0.0, 1.0)]
    
    stim = extractStimulus(testfile)
    @test isa(stim[1], StimulusProtocol)
    @test stim[1,1].timestamps == [(3.65635, 3.65735)]

    a = StimulusProtocol()
    test = (0.0, 1.0)
    push!(a, test)
    @test length(a) == 2

    b = StimulusProtocol()
    push!(a, b)
    @test length(a) == 3
end