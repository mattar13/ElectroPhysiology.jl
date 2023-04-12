push!(LOAD_PATH, "../src/")
using Pkg; Pkg.activate("docs")
using Documenter 
using ElectroPhysiology, PhysiologyAnalysis
import ElectroPhysiology: Experiment

makedocs(
     sitename = "ElectroPhysiology.jl", 
     authors = "Matthew Tarchick", 
     repo = "https://github.com/mattar13/ElectroPhysiology.jl",
     pages = Any[
          "Introduction" => "index.md",
          "Installation" => "installation.md",
          "Tutorial" => "tutorial.md",
          "Functions" => "functions.md"
     ],
     #=
     modules = [ElectroPhysiology, PhysiologyAnalysis],
     format = Documenter.HTML()
     =#
)

deploydocs(
    repo = "github.com/mattar13/ElectroPhysiology.jl.git",
)