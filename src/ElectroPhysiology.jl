module ElectroPhysiology

# Write your package code here.
## 1) Basic usage starts with the experiment Readers
#=Import all experiment objects=======================#
using Dates
import Base: size, axes, length, getindex, setindex, sum, copy, maximum, minimum, push!, cumsum, argmin, argmax
import Statistics.std

include("Experiment/StimulusProtocol.jl")
include("Experiment/Experiments.jl") #This file contains the Experiment structure. 

#=Import all readers======================#
include("Readers/ABFReader/ABFReader.jl")
export readABF
export parseABF

end
