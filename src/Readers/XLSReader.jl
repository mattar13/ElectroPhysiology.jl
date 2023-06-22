function int_to_letter(num)
     return Char(num + 64) |> string
end

function extractHeaderInfo(worksheet::XLSX.Worksheet)
     channelCount = worksheet["C48"]
     letter = int_to_letter(2+channelCount)
     channelNames =worksheet["C26:$(letter)26"]
     channelTelegraph = worksheet["C42:$(letter)42"]
     channelUnits = worksheet["C34:$(letter)34"]
     dt = 1/worksheet["C35"]
     return channelNames, channelTelegraph, channelUnits, dt
end

function StimulusProtocol(stimSheet::XLSX.Worksheet)
     StimulusA = StimulusProtocol()
     for (idx, row) in enumerate(XLSX.eachrow(stimSheet))
          if idx != 1
               typeName = row["A"]
               intensity = row["B"]
               if typeName == "flash"
                    type = Flash(intensity)
               end
               channel = row["C"]
               TimeStart = row["D"]
               TimeStop = row["E"]
               stimulusAdd = StimulusProtocol(type, channel, (TimeStart, TimeStop))
               push!(StimulusA, stimulusAdd)
          end
     end
     return StimulusA
end

function readXLSX(filename::String)
     XLSX.openxlsx(filename, mode = "r") do xf
          snames = XLSX.sheetnames(xf)
          headerSheet = xf["Header"]
          channelNames, channelTelegraph, channelUnits, dt = extractHeaderInfo(headerSheet)
          timeSheet = xf["Time"]
          t = timeSheet["B2:$(timeSheet.dimension.stop)"]
          stimulusSheet = xf["Stimulus"]
          stimulus_protocol = StimulusProtocol(stimulusSheet)
          #match sheetnames and channels
          match_idxs = maximum((snames .== channelNames), dims = 2) |> vec
          keep_channels = maximum((snames .== channelNames), dims = 1) |> vec
          
          data_as_chs = []
          for channel in snames[match_idxs]
               channelSheet = xf[channel]
               dims = channelSheet.dimension
               channelArr = Array{Float64}(channelSheet["A2:$(dims.stop)"]')
               push!(data_as_chs, channelArr)
          end
          data = cat(data_as_chs..., dims = 3)
          experiment = Experiment(data)
          experiment.t = t |> vec
          experiment.format = :XLSX
          experiment.HeaderDict = Dict(("Ready" => "No", "when" => 2))
          experiment.chNames = Vector{String}(channelNames[keep_channels]) 
          experiment.chUnits = Vector{String}(channelUnits[keep_channels]) 
          experiment.chTelegraph = Vector{Float64}(channelTelegraph[keep_channels]) 
          experiment.stimulus_protocol = stimulus_protocol
          #experiment.dt = dt
          return experiment
     end
end