# ElectroPhysiology.jl Documentation

Electrophysiology is the study of the electrical nature of cells in an organism. Much of the time it deals with muscular or neural physiology, however other cells have conductive behavior as well. As the field of neuroscience develops, it will draw more heavily on available computational systems. 

## Package composition

This module is composed of several different modules. You can load some or all of the modules based on what you need. 

- ElectroPhysiology.jl provides the basic reading and access to electrophysiology data
- PhysiologyAnalysis.jl provides some analysis tools and plotting tools for analysis
- PhysiologyModeling.jl provides some simulation tools. 

In general, if exporting PhysiologyAnalysis.jl or PhysiologyModeling.jl, ElectroPhysiology.jl doesn't need to be exported, and many of the things exported with ElectroPhysiology.jl will be left "under the hood". However if some of the tools included in ElectroPhysiology.jl are needed (see ElectroPhysiology tools), then it may be best to import both. 
