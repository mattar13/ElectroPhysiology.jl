push!(LOAD_PATH, "../src/")
using Pkg; Pkg.activate("docs")
using Documenter 
using ElectroPhysiology 
using PhysiologyAnalysis #Comment this out because it uses pyimport which I still haven't configured yet
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
     ],
)