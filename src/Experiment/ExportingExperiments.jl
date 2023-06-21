#It will be much easier to export these files to excel
["data", "EpochTableByChannel", "dataType", "abfFileComment"]
function HeaderToFrame(data; skips = ["data", "EpochTableByChannel", "dataType", "abfFileComment", "StringSection"])
     HeaderDF = DataFrame(Category = String[], Type = String[], Value = Any[])
     for (key, val) in data.HeaderDict
          println(val |> typeof)
          if key ∉  skips && !isa(val, Dict)
               push!(HeaderDF, (Category = key, Type = string(val |> typeof), Value = val))
          end
     end
     return HeaderDF
end

function writeXLSX(filename::String, data::Experiment; 
     columns = :trials, column_names = :auto, 
     sheets = :channels, 
     save_header = true, skips = ["data", "EpochTableByChannel", "abfFileComment", "StringSection"],
     save_sections = true,
     save_stimulus =  true,
     auto_open = false,
     verbose = true
)  
     XLSX.openxlsx(filename, mode = "w") do xf
          sheet = xf[1]
          XLSX.rename!(sheet, "Header")
          #The next sheets have to be the channels
          timeSheet = XLSX.addsheet!(xf, "Time")
          XLSX.writetable!(timeSheet, DataFrame(Index = 1:length(data.t), Timestamp = data.t))
          for ch in data.chNames
               XLSX.addsheet!(xf, ch)
          end
          if save_stimulus
               StimulusSheet = XLSX.addsheet!(xf, "Stimulus")
               XLSX.writetable!(StimulusSheet, DataFrame(data.stimulus_protocol))
          end
          if save_header
               HeaderDF = DataFrame(Category = String[], Type = String[], Value = Any[])
               for (key, val) in data.HeaderDict
                    if key ∉ skips && !isa(val, Dict) && !isa(val, DataType)
                         push!(HeaderDF, (Category = key, Type = string(val |> typeof), Value = val))
                    elseif isa(val, DataType)
                         push!(HeaderDF, (Category = key, Type = string(val |> typeof), Value = string(val)))
                    elseif isa(val, Dict) && save_sections# && key ∉ ["EpochSection", "SyncArraySection", "abfVersionDict", "ADCSection", "ProtocolSection", "EpochPerDACSection", "DACSection"]
                         sheet_section = XLSX.addsheet!(xf, key)
                         SectionDF = DataFrame(Category = String[], Value = Any[])
                         for (keySECT, valSECT) in val
                              if isa(valSECT, Vector{Char})
                                   #println("Is a Vector{Char}")
                                   push!(SectionDF, (Category = keySECT, Value = string(valSECT)))
                              elseif isa(valSECT, Char)
                                   #println("Is a char")
                                   push!(SectionDF, (Category = keySECT, Value = string.(valSECT)))
                              else
                                   push!(SectionDF, (Category = keySECT, Value = valSECT))
                              end
                         end
                         XLSX.writetable!(sheet_section, SectionDF)
                         if verbose
                              println("Saving section $key")
                         end
                    end
               end 
               XLSX.writetable!(sheet, HeaderDF)
               if verbose
                    println("Saving header")
               end
          end


          if sheets == :channels
               for channel in eachchannel(data)
                    sheet_channel = xf[channel.chNames[1]]#XLSX.addsheet!(xf, channel.chNames[1])
                    
                    n_trials = size(data, 1)
                    df = DataFrame(channel.data_array[:,:,1]', :auto)
                    if column_names == :auto
                         rename!(df, [Symbol("Trial$i") for i in 1:n_trials])
                    else
                         rename!(df, column_names, makeunique=true)
                    end
                    #insertcols!(df, 1, "Time" => channel.t)
                    if verbose
                         print("Saving channel")
                         println(sheet_channel)
                    end
                    XLSX.writetable!(sheet_channel, df)
               end
          end
     end

     if auto_open
          run(`powershell start excel.exe test.xlsx`);
     end
end