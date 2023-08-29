# ElectroPhysiology.jl Introduction

Electrophysiology is defined the study of the electrical nature of cells in an organism. Much of the time it deals with muscular or neural physiology, however other cells have conductive behavior as well. As the field of neuroscience develops, it will draw more heavily on available computational systems. This package aims to take 

## Package composition

This module is composed of several different modules. You can load some or all of the modules based on what you need. 

- ElectroPhysiology.jl provides the basic reading and access to electrophysiology data
     - [ElectroPhysiology Methods](@ref)
- PhysiologyAnalysis.jl provides some analysis tools and plotting tools for analysis
     - [PhysiologyAnalysis Methods](@ref)
- PhysiologyPlotting.jl provides plotting and visualization tools. 
     - [PhysiologyPlotting Methods](@ref)

In general, if exporting PhysiologyAnalysis.jl or PhysiologyModeling.jl, ElectroPhysiology.jl doesn't need to be exported, and many of the things exported with ElectroPhysiology.jl will be left "under the hood". However if some of the tools included in ElectroPhysiology.jl are needed (see ElectroPhysiology tools), then it may be best to import both. 

If you would like tutorials, look into the tutorial package here with help on how to use the software


```@contents
```