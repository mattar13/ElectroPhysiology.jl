#=
This test set should be simple enough and test wether the basic ABF reader is failing or working

=#
@testset "Testing ABF reader" begin
    data_single = readABF(test_single_trace)
    data_many = readABF(test_many_traces)
    @test isa(data_single, Experiment)
    @test isa(data_many, Experiment)
    @test !isnothing(data_single)

    @test size(data_single, 1) == 1 #Data single should contain one trial
    @test size(data_single, 2) == 3_000_000 #300k datapoints
    @test size(data_single, 3) == 2 #and 2 channels

    @test size(data_many, 1) == 9 #Data many should contain 9 trials
    @test size(data_many, 2) == 20_000 #300k datapoints
    @test size(data_many, 3) == 2 #and 2 channels

    @test data_single.dt == 0.0001 #The time derivative is in 0.0001 for both 
    @test data_many.dt == 0.0001 #The time derivative is in 0.0001 for both 
    
    @test data_single.chNames == ["IN 0", "IN 1"]
    @test data_many.chNames == ["IN 0", "IN 1"]
end

@testset "Testing Experiment iterator" begin
    data_many = readABF(test_many_traces)
    
    #Get the first trial, datapoint, channel
    data_get = getdata(data_many, 1, 1, 1)
    @test size(data_get) == (1,1,1)

    data_ch1 = getchannel(data_many, 1)
    @test size(data_ch1, 1) == 9
    @test size(data_ch1, 2) == 20_000
    @test size(data_ch1, 3) == 1

    data_each_trial = collect(eachtrial(data_many))
    @test length(data_each_trial) == 9
    
    data_each_ch= collect(eachchannel(data_many))
    @test length(data_each_ch) == 2
end

@testset "Experiment Modification" begin
    #println("Testing scaling functions")
    data_single = readABF(test_single_trace)
    
    #Testing scaleby functions
    data_scaled = scaleby(data_single, 10.0) #Test the copy function
    @test data_scaled[1,1,1] == 10*data_single[1,1,1]
    
    data_modify = deepcopy(data_single)
    scaleby!(data_modify, 10.0) #Test the inplace function
    @test data_modify[1,1,1] == 10*data_single[1,1,1]
    
    #Testing padding functions
    data_padded = pad(data_single, 10)
    @test size(data_padded, 2) == 10 + size(data_single, 2)
    
    data_modify = deepcopy(data_single)
    pad!(data_modify, 10)
    @test size(data_modify, 2) == 10 + size(data_single, 2)

    #Testing chopping functions
    data_modify = deepcopy(data_single)
    chop!(data_modify, 10)
    data_chopped = chop(data_single, 10)
    @test size(data_chopped, 2) == size(data_single, 2) - 10
    @test size(data_modify, 2) == size(data_single, 2) - 10

    #println("Testing drop functions")
    data_drop_swp = drop(data_single, dim = 1)
    data_drop_ch = drop(data_single, dim = 3)
    @test size(data_drop_swp, 1) == size(data_single,1)-1
    @test size(data_drop_ch, 3) == size(data_single,3)-1

    #println("Testing truncate functions")
    data_trunc = truncate_data(data_single, t_begin = 0.0, t_end = 1.0)
    println(size(data_trunc))
    @test size(data_trunc, 2) == Int64(1/data_single.dt)
    @test data_single.t[1] == 0.0
    @test data_trunc.t[1] == 0.0

    data_concat = concat(data_single, data_single)
    @test size(data_concat,1) == size(data_single,1) * 2

    data_avg = average_trials(data_single)
    @test size(data_avg, 1) == 1

    sf = getSampleFreq(data_single)
    @test data_single.dt == 0.0001

    data_downsample = downsample(data_single, sf/10)
    downsample_sf = getSampleFreq(data_downsample)
    @test data_downsample.dt == 0.001
    
    @test sf == downsample_sf*10
    @test size(data_single, 2) == size(data_downsample, 2)*10
    
    data_dyad = dyadic_downsample(data_single)
    @test size(data_dyad, 2) == 2^21

    data_baseline = baseline_adjust(data_single)
    mean_data = mean(data_baseline)
    @test round(mean_data[1, 1, 1], digits = 1) == 0.0 #Checks to make sure the baseline is nearly 0.0
    @test round(mean_data[1, 1, 2], digits = 1) == 0.0 #Checks to make sure the baseline is nearly 0.0
end