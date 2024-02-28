@testset "Testing ABF reader" begin
    data = readABF(testfile)
    data2 = readABF(testfile2)
    @test isa(data, Experiment)
    @test isa(data2, Experiment)
    
    @test isa(data.stimulus_protocol[1], StimulusProtocol)
     
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