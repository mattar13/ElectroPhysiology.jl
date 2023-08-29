# ElectroPhysiology.jl Tutorial

### A tutorial is provided in the github repo

https://github.com/mattar13/PhysiologyInterface.jl

## The experiment is the universal experiment container
At the base of the ElectroPhysiology.jl package (PhysigologyAnalysis.jl, and PhysiologyModeling.jl). Is the Experiment object: [`Experiment`](@ref). This object contains all relevant information about the data. The easiest way to get your data into an Experiment is to extract it. 


# Opening Axon Binary Format files (.abf)
Currently, this package only opens this can only be done through 

```@example
test_file = "test\\to_filter.abf"
data = readABF(test_file)
println(size(data))

```

# Modification of Experiment files
Once the data is open. We can do several things to modify it. 

# Extracting data and metadata from a system of file names

PhysiologyAnalysis.jl has some methods that make the extraction of file information easier. These are really just convienance functions. Because some experiments are really different, these may or may not be helpful. 

## Making a dataframe that includes all trials in a experiment