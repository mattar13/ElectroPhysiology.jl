#TODO: Eventually I want to add all filter functions into a single function 

"""
    Filters data in the `exp` object using a digital filter.

    # Parameters
    - exp : Experiment{F, T} 
        an object containing the data to be filtered
    - freq_start : float (optional) 
        start frequency for the filter, default is 1.0
    - freq_stop : float (optional) 
        stop frequency for the filter, default is 55.0
    - bandwidth : float (optional) 
        bandwidth for the filter, default is 10.0
    - mode : Symbol (optional) 
        filter mode, can be :Lowpass, :Highpass, :Bandpass, :Bandstop, default is :Lowpass
    - method : Symbol (optional) 
        method used to design the filter, can be :Butterworth, :Chebyshev1, :Chebyshev2, :Elliptic, default is :Chebyshev2
    - pole : int (optional) 
        number of poles for the filter, default is 8
    - ripple : float (optional) 
        ripple for the filter, default is 15.0
    - attenuation : float (optional) 
        attenuation for the filter, default is 100.0
    - filter_channels : int or Vector{String} (optional) 
        channels to be filtered, can be an integer index or a vector of channel names, default is -1 (all channels)
    # Returns
    - The input exp object is modified in place.

    # Example
    ```julia
    exp = Experiment(data_array, dt)
    filter_data!(exp, freq_start=5, freq_stop=10, mode=:Bandpass)
    ```
"""
function filter_data(exp::Experiment{F, T}; kwargs...) where {F, T<:Real}
    data = deepcopy(exp)
    filter_data!(data; kwargs...)
    return data
end

function filter_data!(exp::Experiment{F, T};
    freq_start=1.0, freq_stop=55.0, bandwidth=10.0,
    mode=:Lowpass, method=:Chebyshev2,
    pole=4, ripple=50.0, attenuation=100.0,
    filter_channels=-1
) where {F, T<:Real}

    #Determine the filter response
    if mode == :Lowpass
        responsetype = Lowpass(freq_stop; fs=1 / exp.dt)
    elseif mode == :Highpass
        responsetype = Highpass(freq_start; fs=1 / exp.dt)
    elseif mode == :Bandpass
        responsetype = Bandpass(freq_start, freq_stop, fs=1 / exp.dt)
    elseif mode == :Bandstop
        responsetype = Bandstop(freq_start, freq_stop, fs=1 / exp.dt)
    end

    #Determine the method for designing the filter
    if method == :Butterworth
        designmethod = Butterworth(pole)
    elseif method == :Chebyshev1
        designmethod = Chebyshev1(pole, ripple)
    elseif method == :Chebyshev2
        designmethod = Chebyshev2(pole, ripple)
    elseif method == :Elliptic
        designmethod = Elliptic(pole, ripple, attenuation)
    end

    if mode == :Notch
        digital_filter = iirnotch(freq, bandwidth, fs=1 / exp.dt)
    else
        digital_filter = digitalfilter(responsetype, designmethod)
    end

    if filter_channels == -1
        filter_channels = 1:size(exp, 3)
    elseif isa(filter_channels, Vector{String}) #Do this for channel names input 
        filter_channels = findall(filter_channels .== data.chNames)
    end
    for swp in axes(exp, 1)
        for ch in axes(exp, 3)
            if ch in filter_channels
                exp.data_array[swp, :, ch] .= filt(digital_filter, exp[swp, :, ch])
            end
        end
    end
end

function normalize!(exp::Experiment{F, T}; rng=(0, 1), dims = (1,2)) where {F, T<:Real}
    exp.data_array .+= minimum(exp.data_array, dims = dims)
    exp.data_array ./= maximum(exp.data_array, dims = dims)
end

function normalize(exp::Experiment{F, T}; rng=(-1, 0), dims=(1, 2)) where {F, T<:Real}
    data = deepcopy(exp)
    normalize!(data, rng = rng, dims = dims)
    return data
end

function normalize_channel!(exp::Experiment{F, T}; rng=(-1, 0)) where {F, T<:Real}
    if rng[1] < 0.0
        mins = minimum(minimum(data, dims=2), dims=1)
        exp.data_array ./= -mins
    else
        mins = maximum(maximum(data, dims=2), dims=1)
        exp.data_array ./= mins
    end
end

function normalize_channel(exp::Experiment{F, T}; rng=(-1, 0)) where {F, T<:Real}
    data = deepcopy(exp)
    normalize_channel!(data)
    return data
end

function rolling_mean(exp::Experiment{F, T}; window::Int64=10) where {F, T<:Real}
    data = deepcopy(exp)
    for swp in axes(exp, 1), ch in axes(exp, 3)
        for i in 1:window:size(data, 2)-window
            data.data_array[swp, i, ch] = sum(data.data_array[swp, i:i+window, ch]) / window
        end
    end
    return data
end