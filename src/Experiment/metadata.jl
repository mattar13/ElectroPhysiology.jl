struct Metadata
     date::Date
     time::Time
     sampling_rate::Float64
     experiment_duration::Float64
     channel_labels::Array{String,1}
     units::String
     amplifier_gain::Float64
     temperature::Float64
     animal::String
     number::Real
     # Add other fields as needed
     extras
end
 