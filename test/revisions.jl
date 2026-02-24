@testset "Revision run case: stimulus + truncation workflow" begin
    data = readABF(test_many_traces, stimulus_name = "IN 1", stimulus_threshold = 0.5)
    @test isa(data, Experiment)


#Lets open a .abf file and see if we can revamp and improve anything. 

erg_file = raw"F:\ERG\Retinoschisis\2019_03_12_AdultWT\Mouse1_Adult_WT\BaCl_LAP4\Rods\nd0_1p_2ms.abf"
data = readABF(erg_file)