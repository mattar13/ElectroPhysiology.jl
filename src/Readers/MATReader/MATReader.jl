#We need to extract HeaderData, but I don't think it is included

function readMAT(FORMAT::Type, fn::String; fs = 1.0)
     MATfile = matopen(fn)
     data_file = read(MATfile) #This reads the data into the file
     trials = []
     chNames = String[]
     chUnits = String[]
     chGains = []
     for (key, val) in data_file
          push!(trials, val')
          push!(chNames, key)
          #Defaults 
          push!(chUnits, "mV")
          push!(chGains, 1.0)
     end
     data_array = cat(trials..., dims = 3)
     dt = 1/fs
     time = 1:dt:size(trials[1], 1)
     Experiment(
          Dict{String, Any}(), 
          dt, 
          time, 
          data_array, 
          chNames, chUnits, chGains
     )
end

readMAT(fn::String; kwargs...) = readMAT(EXPERIMENT, fn; kwargs...)