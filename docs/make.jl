push!(LOAD_PATH, "../src/")
using Pkg; Pkg.activate("docs")
#We need to build PyCall before using this to properly use
ENV["PYTHON"]=""
Pkg.build("PyCall")

using Documenter 
using ElectroPhysiology 
using PhysiologyAnalysis #Comment this out because it uses pyimport which I still haven't configured yet
using PhysiologyPlotting
import ElectroPhysiology: Experiment

makedocs(
     sitename = "ElectroPhysiology.jl", 
     authors = "Matthew Tarchick", 
     repo = "https://github.com/mattar13/ElectroPhysiology.jl",
     pages = Any[
          "Introduction" => "index.md",
          "Installation" => "installation.md",
          "Tutorial" => "tutorial.md",
          "Methods" => "methods.md", 
          "Roadmap" => "roadmap.md"
          "API" => "api.md"
     ]
)

deploydocs(
    repo = "github.com/mattar13/ElectroPhysiology.jl.git",
)