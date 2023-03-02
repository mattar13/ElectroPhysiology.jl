module ElectroPhysiology

# Write your package code here.
## 1) Basic usage starts with the experiment Readers
#=Import all experiment objects=======================#
using Dates
import Base: size, axes, length, getindex, setindex!, sum, copy, maximum, minimum, push!, cumsum, argmin, argmax
import Statistics.std

include("Experiment/StimulusProtocol.jl")
export StimulusProtocol
export setindex!, getindex
export extractStimulus

include("Experiment/Experiments.jl") #This file contains the Experiment structure. 
export std, getSampleFreq

import Base: chop
import Polynomials as PN
include("Experiment/ModifyExperiments.jl") #These functions modify individual experiments
export scaleby, scaleby!
export pad, pad!, chop, chop!
export drop, drop!
export truncate_data, truncate_data!
export average_sweeps, average_sweeps!
export downsample, downsample!
export dyadic_downsample, dyadic_downsample!
export baseline_adjust, baseline_adjust!

include("Experiment/JoiningExperiments.jl") #These files join multiple experiments
export concat, concat!

include("Experiment/IterateExperiments.jl")
export getdata, getchannel, eachchannel, eachsweep
#=Import all readers======================#
include("Readers/ABFReader/ABFReader.jl")
export readABF
export parseABF

end
