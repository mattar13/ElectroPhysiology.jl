function int_to_letter(num)
     return Char(num + 64) |> string
end

function extractChannelData(worksheet::XLSX.Worksheet)
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

function extractHeaderInfo(headerSheet::XLSX.Worksheet)
     #println(headerSheet)
     HeaderDict = Dict()
     categories = headerSheet["A"][2:end]
     types = headerSheet["B"][2:end]
     values = headerSheet["C"][2:end]
     for (idx, key) in enumerate(categories)
          HeaderDict[key] = values[idx]
     end
     return HeaderDict
end

function readXLSX(filename::String)
     XLSX.openxlsx(filename, mode = "r") do xf
          snames = XLSX.sheetnames(xf)
          headerSheet = xf["Header"]
          HeaderDict = extractHeaderInfo(headerSheet)
          channelNames, channelTelegraph, channelUnits, dt = extractChannelData(headerSheet)
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
               chData = channelSheet["A2:$(dims.stop)"] #Speed this up
               channelArr = convert(Array{Float64, 2}, chData)'
               push!(data_as_chs, channelArr)
          end
          data = cat(data_as_chs..., dims = 3)
          experiment = Experiment(data)
          experiment.t = t |> vec
          experiment.format = :XLSX
          experiment.HeaderDict = HeaderDict
          experiment.chNames = Vector{String}(channelNames[keep_channels]) 
          experiment.chUnits = Vector{String}(channelUnits[keep_channels]) 
          experiment.chTelegraph = Vector{Float64}(channelTelegraph[keep_channels]) 
          experiment.stimulus_protocol = stimulus_protocol
          #experiment.dt = dt
          return experiment
     end
end