@testset "Constructing experiments" begin
     time = collect(1:0.01:1000) #Create some time range
     data_arr = rand(5, length(time), 5) #Create some dummy data
     experiment = ElectroPhysiology.Experiment(data_arr)
     @test isa(experiment, ElectroPhysiology.Experiment)
     
     experiment_w_time = ElectroPhysiology.Experiment(time, data_arr)
     @test isa(experiment_w_time, ElectroPhysiology.Experiment)
end

@testset "Iterating through experiments" begin
     time = collect(1:0.01:1000) #Create some time range     
     data_arr = rand(5, length(time), 5) #Create some dummy data
     experiment = ElectroPhysiology.Experiment(data_arr)
     @test isa(experiment, ElectroPhysiology.Experiment)

     println(experiment.chNames)
     exp_get_1 = getdata(experiment, 1, 1, 1)


end