push!(LOAD_PATH, "../src/")
using Pkg; Pkg.activate("docs")

using Documenter 
using ElectroPhysiology

makedocs(
     sitename = "ElectroPhysiology.jl", 
     authors = "Matthew Tarchick", 
     repo = "https://github.com/mattar13/ElectroPhysiology.jl",
     pages = Any[
          "Introduction" => "index.md",
          "Installation" => "installation.md",
          "Tutorial" => "tutorial.md",
          "API Reference" => "API.md",
          "Reorganization Plan" => "reorganization.md",
          "Roadmap" => "roadmap.md"
     ]
)

deploydocs(
    repo = "github.com/mattar13/ElectroPhysiology.jl.git",
)
