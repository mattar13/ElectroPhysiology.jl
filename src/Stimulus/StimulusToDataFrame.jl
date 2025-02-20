println("This is loading, and shouldn't be")
#Export this only if XLSX and DataFrame are loaded
function DataFrame(protocol::StimulusProtocol{T}) where T <: Real
     StimulusDF = DataFrame(Type = String[], Intensity = T[], Channel = String[], TimeStart = T[], TimeEnd = T[])
     for stimulus in protocol
         #println(stimulus)
         push!(StimulusDF, (
             Type = string(stimulus.type[1]),
             Intensity = stimulus.type[1].intensity,
             Channel = stimulus.channelName[1], 
             TimeStart = stimulus.timestamps[1][1], 
             TimeEnd = stimulus.timestamps[1][2]        
             )
         )
     end
     return StimulusDF
 end