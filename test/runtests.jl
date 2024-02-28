using ElectroPhysiology
using Test



include("testStimulusProtocols.jl")

include("testABFReader.jl")

@testset "Testing Experiement struct" begin
    time = collect(1:0.01:1000) #Create some time range
    data = rand(5, length(time), 1) #Create some dummy data

    exp = ElectroPhysiology.Experiment(data)
    @test !isnothing(exp)

    exp_w_time = ElectroPhysiology.Experiment(time, data)
    @test !isnothing(exp_w_time)
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


