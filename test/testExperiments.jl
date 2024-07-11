@testset "Constructing experiments" begin
     time = collect(1:0.01:1000) #Create some time range
     data_arr = rand(5, length(time), 5) #Create some dummy data
     experiment = Experiment(data_arr)
     @test isa(experiment, Experiment)
     
     #Test the construction of Experiment with time
     experiment_w_time = Experiment(time, data_arr)
     @test isa(experiment_w_time, Experiment)

     experiment_push = copy(experiment)
     #Push adds trials to the experiment, test this
     push!(experiment_push, rand(size(experiment_push)...))
     @test size(experiment_push, 1) == size(experiment, 1) * 2
     @test size(experiment_push, 2) == size(experiment, 2)
     @test size(experiment_push, 3) == size(experiment, 3)
 end