function writeCSV(exp::Experiment; loc = nothing, channel = nothing)
     if isnothing(channel)
          for ch in eachchannel(exp)
               a = ch.data_array[:,:,1]' #We have to transpose the data to store it
               if isnothing(loc)
                    writedlm("$(ch.chNames[1]).csv", a, ',')
               else
                    writedlm("$(loc)/$(ch.chNames[1]).csv", a, ',')
               end
          end
     elseif isa(channel, Int64)
          a = data[:,:,channel]
          if isnothing(loc)
               writedlm("$(ch.chNames[1]).csv", a, ',')
          else
               writedlm("$(loc)/$(ch.chNames[1]).csv", a, ',')
          end
     end
end

function readCSVtoExperiment(filename::String, exp::Experiment, channel)
     

end