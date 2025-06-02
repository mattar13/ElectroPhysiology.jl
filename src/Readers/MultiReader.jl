#This is not implemented yet. Give me a little bit

#This function takes an image file and a .abf file and returns an experiment object 
function readMulti(image_fn::String, abf_fn::String;
    spike_train_group_time = nothing,
    stimulus_name = "IN 3",
    kwargs...
)

    #Read the image file
    image_data = readImage(image_fn; kwargs...)

    #Read the .abf file
    abf_data = readABF(abf_fn; kwargs...)
    if !isnothing(spike_train_group_time)
        spike_train_group!(abf_data, spike_train_group_time)
    end
    addStimulus!(abf_data, image_fn, stimulus_name; kwargs...)
    #Return the experiment object
    return Experiment(image_data, abf_data)
end