module ElectroPhysiology

#=Import all experiment objects=======================#
using Requires
capabilies = Symbol[] #This indicates all the things the package is capable of doing
using Dates, TimeZones
import Base: size, axes, length, getindex, setindex!, sum, copy, maximum, minimum, push!, cumsum, argmin, argmax, abs
import Statistics: std, mean, median

#This code does several things
#=1) Creates several objects used in the analysis of ElectroPhysiology data=#
#=2) Reads =#
#=3) Modifies experiment objects =#
using DSP #Used for lowpass, highpass, EI, and notch filtering

include("Experiment/StimulusProtocol.jl")
export StimulusProtocol
export setindex!, getindex
export getStimulusProtocol
export extractStimulus, setIntensity, getIntensity

include("Experiment/Experiments.jl") #This file contains the Experiment structure. 
export getSampleFreq
export abs 
export std,mean

include("Experiment/IterateExperiments.jl")
export getdata, getchannel, eachchannel, eachtrial

import Base: chop
import Polynomials as PN
using FileIO, Images
using ImageMagick #This package is for getting metadata of .tif files
import ImageMagick.magickinfo
import Images.Kernel
import OffsetArrays.OffsetArray
using CurveFit



include("Experiment/ModifyExperiments.jl") #These functions modify individual experiments
export scaleby, scaleby!
export pad, pad!, chop, chop!
export drop, drop!
export truncate_data, truncate_data!
export average_trials, average_trials!
export downsample, downsample!
export dyadic_downsample, dyadic_downsample!
export baseline_adjust, baseline_adjust!

#Image reading utilities
include("Experiment/ImageMorphologyUtils.jl")
export delta_f, delta_ff
export find_boutons
export project
export deinterleave!
export adjustBC!
export imfilter!, imfilter
export mapwindow, mapwindow!
export bin!
export Kernel



include("Experiment/JoiningExperiments.jl") #These files join multiple experiments
export concat, concat!
export create_signal_waveform!

include("Experiment/ExportingExperiments.jl")
export writeXLSX

#1)Filter ====================================================================================#
include("Filtering/filtering.jl")
export filter_data, filter_data!
export rolling_mean
export normalize, normalize!

include("Filtering/filteringPipelines.jl")
export data_filter!, data_filter

#=Import all readers======================#
include("Readers/ABFReader/ABFReader.jl") #This file contains some binary extras
export readABF
export parseABF
export getABF_datetime #Eventually these should go elsewhere

include("Readers/ImageReader/ImageReader.jl")
export readImage
export get_frame, get_all_frames
export getIMG_datetime

include("Readers/ImageReader/ROIReader.jl")
export recordROI 
export getROIindexes, getROImask, getROIarr
export loadROIfn!


function __init__()    
    @require XLSX = "fdbf4ff8-1666-58a4-91e7-1b58723a45e0" begin
        using .XLSX; push!(capabilies, :XLSX)
        @require DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0" begin
            using .DataFrames; push!(capabilies, :DataFrames)
            include("Readers/XLSReader.jl")
            export readXLSX

            import .DataFrames.DataFrame
            include("Experiment/StimulusToDataFrame.jl")
            export DataFrame
        end
    end

    @require Wavelets = "29a6e085-ba6d-5f35-a997-948ac2efa89a" begin
        using .Wavelets; push!(capabilies, :Wavelets)

        @require ContinuousWavelets = "96eb917e-2868-4417-9cb6-27e7ff17528f" begin
            println("Wavelet utilites added")
            using .ContinuousWavelets; push!(capabilies, :ContinuousWavelets)
            
            include("Filtering/make_spectrum.jl")
            include("Filtering/wavelet_filtering.jl")
            export cwt_filter!, cwt_filter
            export dwt_filter!, dwt_filter
        
        end
    end

    @require MAT = "23992714-dd62-5051-b70f-ba57cb901cac" begin
        push!(capabilies, :MAT)
        using .MAT
        include("Readers/MATReader/MATReader.jl")
        export readMAT
    end
end

export capabilies #Export this, and even append to it when you load a new package
end
