push!(LOAD_PATH, "../src/")
using Pkg; Pkg.activate("docs")

using Documenter 
using ElectroPhysiology, PhysiologyAnalysis #Comment this out because it uses pyimport which I still haven't configured yet
using PhysiologyPlotting


import PhysiologyPlotting: add_scalebar, add_sig_bar, draw_axes_border
#using GLMakie #OpenGL is not available, so this may be left out for now
import ElectroPhysiology: Experiment, StimulusProtocol, extractStimulus, setIntensity, getIntensity
import ElectroPhysiology: Stimulus, Flash
# Import filtering functions
import ElectroPhysiology: baseline_median, baseline_als, baseline_trace, baseline_stack, baseline_stack!
import ElectroPhysiology: moving_average

makedocs(
     sitename = "ElectroPhysiology.jl", 
     authors = "Matthew Tarchick", 
     repo = "https://github.com/mattar13/ElectroPhysiology.jl",
     pages = Any[
          "Introduction" => "index.md",
          "Installation" => "installation.md",
          "Tutorial" => "tutorial.md",
          "ElectroPhysiology Methods" => "ElectroPhysiologyMethods.md", 
          "PhysiologyAnalysis Methods" => "PhysiologyAnalysisMethods.md", 
          "PhysiologyPlotting Methods" => "PhysiologyPlottingMethods.md", 
          "Roadmap" => "roadmap.md"
     ]
)

deploydocs(
    repo = "github.com/mattar13/ElectroPhysiology.jl.git",
)