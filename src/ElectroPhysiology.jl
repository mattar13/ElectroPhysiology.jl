module ElectroPhysiology

#=Import all experiment objects=======================#
using Dates
import Base: size, axes, length, getindex, setindex!, sum, copy, maximum, minimum, push!, cumsum, argmin, argmax
import Statistics.std

#This code does several things
#=1) Creates several objects used in the analysis of ElectroPhysiology data=#
#=2) Reads =#
#=3) Modifies experiment objects =#
using DSP #Used for lowpass, highpass, EI, and notch filtering
using DelimitedFiles

include("Experiment/StimulusProtocol.jl")
export StimulusProtocol
export setindex!, getindex
export extractStimulus

include("Experiment/Experiments.jl") #This file contains the Experiment structure. 
export std, getSampleFreq

include("Experiment/IterateExperiments.jl")
export getdata, getchannel, eachchannel, eachtrial

import Base: chop
import Polynomials as PN
include("Experiment/ModifyExperiments.jl") #These functions modify individual experiments
export scaleby, scaleby!
export pad, pad!, chop, chop!
export drop, drop!
export truncate_data, truncate_data!
export average_trials, average_trials!
export downsample, downsample!
export dyadic_downsample, dyadic_downsample!
export baseline_adjust, baseline_adjust!

include("Experiment/JoiningExperiments.jl") #These files join multiple experiments
export concat, concat!

include("Experiment/ExportingExperiments.jl")
export writeCSV
#1)Filter ====================================================================================#
include("Filtering/filtering.jl")
export filter_data, filter_data!
export rolling_mean
export normalize, normalize!

include("Filtering/filteringPipelines.jl")
export data_filter!, data_filter

#using ContinuousWavelets, Wavelets

#include("Filtering/make_spectrum.jl")
#include("Filtering/wavelet_filtering.jl")
#export cwt_filter!, cwt_filter
#export dwt_filter!, dwt_filter

#=Import all readers======================#
include("Readers/ABFReader/ABFReader.jl")
export readABF
export parseABF

end
