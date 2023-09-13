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


```@docs
readABF(::Type{T}, abf_data::Union{String,Vector{UInt8}};
    trials::Union{Int64,Vector{Int64}}=-1,
    channels::Union{Int64, String, Vector{String}}=["Vm_prime", "Vm_prime4"],
    average_trials::Bool=false,
    stimulus_name::Union{String, Vector{String}, Nothing}="IN 7",  #One of the best places to store digital stimuli
    stimulus_threshold::T=2.5, #This is the normal voltage rating on digital stimuli
    warn_bad_channel=false, #This will warn if a channel is improper
    flatten_episodic::Bool=false, #If the stimulation is episodic and you want it to be continuous
    time_unit=:s, #The time unit is s, change to ms
) where {T<:Real}
```

# Modification of Experiment files
Once the data is open. We can do several things to modify it. 

# Extracting data and metadata from a system of file names

PhysiologyAnalysis.jl has some methods that make the extraction of file information easier. These are really just convienance functions. Because some experiments are really different, these may or may not be helpful. 

## Making a dataframe that includes all trials in a experiment