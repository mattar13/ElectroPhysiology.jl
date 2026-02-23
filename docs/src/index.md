# ElectroPhysiology.jl

ElectroPhysiology.jl is the core data I/O and data-structure package for electrophysiology workflows in Julia.
It standardizes recordings into an `Experiment` object and provides utilities for:

- ABF file reading
- stimulus extraction/annotation
- trial/time/channel manipulation
- two-photon image stack handling
- ROI extraction and basic image transforms

## Start Here

- [Installation](installation.md)
- [Tutorial](tutorial.md)
- [API Reference](API.md)
- [Reorganization Plan](reorganization.md)

## Related Packages

- `PhysiologyAnalysis.jl` for expanded analysis pipelines
- `PhysiologyPlotting.jl` for plotting/visualization

```@contents
Pages = ["installation.md", "tutorial.md", "API.md", "reorganization.md", "roadmap.md"]
Depth = 2
```
