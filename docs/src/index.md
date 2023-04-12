# ElectroPhysiology.jl Introduction

Electrophysiology is defined the study of the electrical nature of cells in an organism. Much of the time it deals with muscular or neural physiology, however other cells have conductive behavior as well. As the field of neuroscience develops, it will draw more heavily on available computational systems. This package aims to take 

## Package composition

This module is composed of several different modules. You can load some or all of the modules based on what you need. 


- ElectroPhysiology.jl provides the basic reading and access to electrophysiology data
[ElectroPhysiology Methods](@ref)
- PhysiologyAnalysis.jl provides some analysis tools and plotting tools for analysis
[PhysiologyAnalysis Methods](@ref)
- PhysiologyModeling.jl provides some simulation tools. 

In general, if exporting PhysiologyAnalysis.jl or PhysiologyModeling.jl, ElectroPhysiology.jl doesn't need to be exported, and many of the things exported with ElectroPhysiology.jl will be left "under the hood". However if some of the tools included in ElectroPhysiology.jl are needed (see ElectroPhysiology tools), then it may be best to import both. 

# ROADMAP
Version 1.0: Can open, plot, and analyze datafiles from .ABF files. 

Notebooks are included to help analyze some electroretinography data.
To install notebooks use this link: https://github.com/mattar13/PhysiologyInterface.jl

To Do list: 
- [ ] (v0.3.0) Allow for saving .abf files and modifying
- [ ] (v0.2.0) Open .mat files (For use with MatLab and Symphony)
- [ ] (v0.2.0) Open .idata files (For use with MatLab and IrisData https://github.com/sampath-lab-ucla/IrisDVA)
- [ ] (v0.1.0) Update some of the data analysis functions and expand analysis  
- [ ] (v0.1.0) Open .csv files (Some formats are saved as CSV files, especially from LabView products)

Completed Tasks: 
- [x] (v0.1.0) Make a Pluto.jl data entry suite to use as analysis GUI 
- [x] (< v0.1.0) Some basic datasheet manipulation
- [x] (< v0.1.0)Experiments can be plotted
- [x] (< v0.1.0) Experiment struct can be added, subtracted, multiplied, and divided
- [x] (< v0.1.0) Open .abf files (ABFReader.jl)


```@contents
```