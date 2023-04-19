# Installation

## Making an analysis environment (OPTIONAL)
While it is not necessary to create a seperate environment, this helps to isolate packages and prevent cross-contamination of packages. 

In order to create a new environment use this code: 
```
using Pkg; Pkg.activate("Analysis")
```

Each time you run julia you will need to run this line first. 

## Installing ElectroPhysiology.jl

```
using Pkg; Pkg.add("ElectroPhysiology")
```

## Installing the PhysiologyAnalysis.jl toolkit
```
using Pkg; Pkg.add("PhysiologyAnalysis")
```

## Installing the PhysiologyPlotting.jl toolkit
```
using Pkg; Pkg.add("PhysiologyPlotting")
```