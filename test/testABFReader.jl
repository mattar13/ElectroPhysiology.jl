import ElectroPhysiology: Experiment, StimulusProtocol

@testset "Testing ABF reader" begin
    data = readABF(testfile)
    data2 = readABF(testfile2)
    @test isa(data, Experiment)
    @test isa(data2, Experiment)

    @test !isnothing(data)

    @test size(data) == (1, 200_000, 5)
    @test size(data,1) == 1
    @test size(data, 2) == 200_000
    @test size(data,3) == 5
    @test length(data) == 200_000
    data_push = copy(data)
    push!(data_push, rand(size(data_push)...))
    @test size(data_push, 1) == 2
end

@testset "Testing modification of stimulus in experiment" begin
    data = readABF(testfile, stimulus_name = "IN 7")
    data2 = readABF(testfile2, stimulus_name = "IN 7")
    stimulus_protocols = getStimulusProtocol(data)
    @test isa(stimulus_protocols, StimulusProtocol)
    @test isnothing(setIntensity(data.HeaderDict["StimulusProtocol"], 1.0))
    photons = rand(12)
    @test isnothing(setIntensity(data2.HeaderDict["StimulusProtocol"], photons))
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
    @test length(data_each_ch) == 5
end

@testset "Experiment Modification" begin
    println("Testing scaling functions")
    testfile = raw"to_analyze.abf"
    data = readABF(testfile)
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
    @test size(data_trunc, 2) == 100000 #5s*20000+1
    @test data.t[1] == 0.0
    @test data_trunc.t[1] == 0.0

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