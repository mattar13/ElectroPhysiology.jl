# ElectroPhysiology.jl Tutorial

At the base of the ElectroPhysiology.jl package (PhysigologyAnalysis.jl, and PhysiologyModeling.jl). Is the Experiment object: [`Experiment`](@ref). This object contains all relevant information about the data. The easiest way to get your data into an Experiment is to extract it. 


## Opening Axon Binary Format files (.abf)
Currently, this package only opens this can only be done through 

```@example
test_file = "test\\to_filter.abf"
data = readABF(test_file)
println(size(data))

```

### Modification of Experiment files
Once the data is open. We can do several things to modify it. 