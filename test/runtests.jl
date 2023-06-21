using ElectroPhysiology
using Test

testfile = raw"to_filter.abf"
data = readABF(testfile)
testfile2 = raw"to_analyze.abf"
data2 = readABF(testfile2)
@testset "Testing stimulus protocols" begin
    @test !isnothing(StimulusProtocol())
    @test !isnothing(StimulusProtocol("TEST NAME"))
    @test !isnothing(StimulusProtocol(10))

    stim = StimulusProtocol("DAC1", 10)
    @test length(stim) == 10
    @test isa(stim[1], StimulusProtocol)
    @test stim[1].timestamps == [(0.0, 0.0)]

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
    
    @test isa(data.stimulus_protocol[1], StimulusProtocol)
    @test isnothing(setIntensity(data.stimulus_protocol, 1.0))

    photons = rand(12)
    @test isnothing(setIntensity(data2.stimulus_protocol, photons))
end

@testset "Testing Experiement struct" begin
    time = collect(1:0.01:1000) #Create some time range
    data = rand(5, length(time), 1) #Create some dummy data

    exp = ElectroPhysiology.Experiment(data)
    @test !isnothing(exp)

    exp_w_time = ElectroPhysiology.Experiment(time, data)
    @test !isnothing(exp_w_time)
end


@testset "Testing ABF reader" begin
    @test !isnothing(data)

    @test size(data) == (1, 200000, 2)
    @test size(data,1) == 1
    @test size(data, 2) == 200_000
    @test size(data,3) == 2
    @test length(data) == 200_000

    @test data[1,1,1] == -0.89935302734375
    @test data[1,1:5,1] == [-0.89935302734375
        -0.89935302734375
        -0.89874267578125
        -0.89813232421875
        -0.8984375
    ]

    @test data[1, 1, "Vm_prime"] ==  [-0.89935302734375]

    @test sum(data) == -472925.8853149414
    @test std(data) == 0.26028433993035255

    @test argmax(data) == [CartesianIndex(1, 52831, 1);;; CartesianIndex(1, 35609, 2)]
    @test argmin(data) == [CartesianIndex(1, 74664, 1);;; CartesianIndex(1, 74558, 2)]

    #Lets test out push functions
    data_push = copy(data)
    push!(data_push, rand(size(data_push)...))
    @test size(data_push, 1) == 2
end

@testset "Testing stimulus making" begin
    println("Instantiate a empty stimulus protocol")
    stim = StimulusProtocol()

end

@testset "Testing modification of individual experiments" begin
    println("Testing scaling functions")
    data_modify = deepcopy(data)
    scaleby!(data_modify, 10.0) #Test the inplace function
    data_scaled = scaleby(data, 10.0) #Test the copy function
    @test data_modify[1,1,1] == 10*data[1,1,1]
    @test data_scaled[1,1,1] == 10*data[1,1,1]

    println("Testing padding functions")
    data_modify = deepcopy(data)
    pad!(data_modify, 10)
    data_padded = pad(data, 10)
    @test size(data_padded, 2) == 10 + size(data, 2)
    @test size(data_modify, 2) == 10 + size(data, 2)

    println("Testing chopping functions")
    data_modify = deepcopy(data)
    chop!(data_modify, 10)
    data_chopped = chop(data, 10)
    @test size(data_chopped, 2) == size(data, 2) - 10
    @test size(data_modify, 2) == size(data, 2) - 10

    println("Testing drop functions")
    data_drop_swp = drop(data, dim = 1)
    data_drop_ch = drop(data, dim = 3)
    @test size(data_drop_swp, 1) == size(data,1)-1
    @test size(data_drop_ch, 3) == size(data,3)-1

    println("Testing truncate functions")
    data_trunc = truncate_data(data)
    println(size(data_trunc))
    @test size(data_trunc, 2) == 120001 #5s*20000+1
    @test data.t[1] == 0.0
    @test data_trunc.t[1] == -1.0

    data_concat = concat(data, data)
    @test size(data_concat,1) == size(data,1) * 2

    data_avg = average_trials(data)
    @test size(data_avg, 1) == 1

    data_downsample = downsample(data, 1000.0)
    @test size(data_downsample, 2) == 10_000.0
    @test getSampleFreq(data_downsample) == 1000.0
    
    data_dyad = dyadic_downsample(data)
    @test size(data_dyad, 2) == 131072

    data_baseline = baseline_adjust(data)
    @test round(sum(data_baseline[:, 1, 1]), digits = 1) == 0.0 #Checks to make sure the baseline is nearly 0.0
end


@testset "Testing Experiment iterator" begin
    testfile = raw"to_analyze.abf"
    data = readABF(testfile)
    data_get = getdata(data, 1, 1, 1)
    @test size(data_get) == (1,1,1)
    data_ch1 = getchannel(data, 1)
    @test size(data_ch1, 3) == 1
    data_each_trial = collect(eachtrial(data))
    @test length(data_each_trial) == 12
    data_each_ch= collect(eachchannel(data))
    @test length(data_each_ch) == 2
end

@testset "Testing ABF reader" begin
    include("testABFReader.jl")
end

@testset "Testing data filtering" begin
    data_filtered = filter_data(data)
    @test !isnothing(data_filtered)

    data_normalized = normalize(data)
    @test !isnothing(data_normalized)
end
