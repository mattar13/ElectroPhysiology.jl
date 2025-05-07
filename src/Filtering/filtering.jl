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

"""
    filter_experiment!(exp::Experiment{F,T}; method=:digital, params=Dict(), channels=:all) where {F,T<:Real}

Apply various filtering methods to an experiment's data. This unified interface supports multiple filtering techniques
including digital filters, wavelet transforms, and baseline corrections.

# Arguments
- `exp`: The experiment to filter
- `method`: Filter method to use. One of:
    - `:digital`: Digital filter (Lowpass, Highpass, Bandpass, Bandstop)
    - `:wavelet_cwt`: Continuous Wavelet Transform filter
    - `:wavelet_dwt`: Discrete Wavelet Transform filter
    - `:baseline`: Baseline correction using various methods
- `params`: Dictionary of method-specific parameters
- `channels`: Channels to filter (:all or specific channels)

# Method-specific Parameters

## Digital Filter (method=:digital)
- `freq_start`: Start frequency (default: 1.0)
- `freq_stop`: Stop frequency (default: 55.0)
- `bandwidth`: Filter bandwidth (default: 10.0)
- `mode`: Filter mode (:Lowpass, :Highpass, :Bandpass, :Bandstop)
- `filter_method`: Design method (:Butterworth, :Chebyshev1, :Chebyshev2, :Elliptic)
- `pole`: Number of poles (default: 4)
- `ripple`: Ripple in dB (default: 50.0)
- `attenuation`: Attenuation in dB (default: 100.0)

## Wavelet CWT (method=:wavelet_cwt)
- `period_window`: Period range tuple (default: (1,8))
- `power_window`: Power range tuple (default: (-Inf, Inf))
- `wavelet`: Wavelet type (default: Morlet(2π))
- `real_or_abs`: Output type (:real or :absolute)
- `inverse_style`: Inverse transform style (default: :paul)

## Wavelet DWT (method=:wavelet_dwt)
- `period_window`: Period range tuple (default: (1,8))
- `wave`: Wavelet type (default: WT.db4)

## Baseline (method=:baseline)
- `baseline_method`: Method type (:als, :median, or other)
- `kernel_size`: Window size for median filter (default: 51)
- `region`: Region to process (:whole or specific)
- `mode`: Processing mode (:slope or other)
- `polyN`: Polynomial order for fitting (default: 1)

For :als method:
- `lambda`: Smoothing parameter (default: 1e7)
- `p`: Asymmetry parameter (default: 0.075)
- `niter`: Number of iterations (default: 20)

# Examples
```julia
# Digital lowpass filter
filter_experiment!(exp, method=:digital, 
    params=Dict(
        :freq_stop => 55.0,
        :mode => :Lowpass,
        :filter_method => :Chebyshev2
    ))

# Wavelet filter
filter_experiment!(exp, method=:wavelet_cwt,
    params=Dict(
        :period_window => (1,8),
        :wavelet => Morlet(2π)
    ))

# Baseline correction with ALS method
filter_experiment!(exp, method=:baseline,
    params=Dict(
        :baseline_method => :als,
        :lambda => 1e7,
        :p => 0.075
    ))
```

# Returns
- The modified experiment object with filtered data
"""
function filter_experiment!(exp::Experiment{F,T};
    method=:digital,
    params=Dict(),
    channels=:all
) where {F,T<:Real}
    # Convert channels specification
    filter_channels = if channels == :all
        1:size(exp, 3)
    elseif isa(channels, Vector{String})
        findall(channels .== exp.chNames)
    else
        channels
    end

    if method == :digital
        # Extract digital filter parameters
        freq_start = get(params, :freq_start, 1.0)
        freq_stop = get(params, :freq_stop, 55.0)
        bandwidth = get(params, :bandwidth, 10.0)
        mode = get(params, :mode, :Lowpass)
        filter_method = get(params, :filter_method, :Chebyshev2)
        pole = get(params, :pole, 4)
        ripple = get(params, :ripple, 50.0)
        attenuation = get(params, :attenuation, 100.0)

        # Determine filter response
        responsetype = if mode == :Lowpass
            Lowpass(freq_stop; fs=1/exp.dt)
        elseif mode == :Highpass
            Highpass(freq_start; fs=1/exp.dt)
        elseif mode == :Bandpass
            Bandpass(freq_start, freq_stop; fs=1/exp.dt)
        elseif mode == :Bandstop
            Bandstop(freq_start, freq_stop; fs=1/exp.dt)
        end

        # Determine design method
        designmethod = if filter_method == :Butterworth
            Butterworth(pole)
        elseif filter_method == :Chebyshev1
            Chebyshev1(pole, ripple)
        elseif filter_method == :Chebyshev2
            Chebyshev2(pole, ripple)
        elseif filter_method == :Elliptic
            Elliptic(pole, ripple, attenuation)
        end

        # Create and apply filter
        digital_filter = if mode == :Notch
            iirnotch(freq_start, bandwidth, fs=1/exp.dt)
        else
            digitalfilter(responsetype, designmethod)
        end

        # Apply filter to selected channels
        for swp in axes(exp, 1), ch in filter_channels
            exp.data_array[swp, :, ch] .= filt(digital_filter, exp[swp, :, ch])
        end

    elseif method == :wavelet_cwt
        # Extract CWT parameters
        period_window = get(params, :period_window, (1,8))
        power_window = get(params, :power_window, (-Inf, Inf))
        wavelet = get(params, :wavelet, Morlet(2π))
        real_or_abs = get(params, :real_or_abs, :absolute)
        inverse_style = get(params, :inverse_style, :paul)

        cwt_filter!(exp; 
            period_window=period_window,
            power_window=power_window,
            wavelet=wavelet,
            real_or_abs=real_or_abs,
            inverseStyle=inverse_style
        )

    elseif method == :wavelet_dwt
        # Extract DWT parameters
        period_window = get(params, :period_window, (1,8))
        wave = get(params, :wave, WT.db4)

        dwt_filter!(exp;
            wave=wave,
            period_window=period_window
        )

    elseif method == :baseline
        # Extract baseline parameters
        baseline_method = get(params, :baseline_method, :als)
        kernel_size = get(params, :kernel_size, 51)
        region = get(params, :region, :whole)
        mode = get(params, :mode, :slope)
        polyN = get(params, :polyN, 1)

        if baseline_method == :als
            lam = get(params, :lambda, 1e7)
            p = get(params, :p, 0.075)
            niter = get(params, :niter, 20)
            
            for swp in axes(exp, 1), ch in filter_channels
                exp.data_array[swp, :, ch] .= baseline_als(exp[swp, :, ch];
                    lam=lam, p=p, niter=niter)
            end
        elseif baseline_method == :median
            baseline_median!(exp; kernel_size=kernel_size, channel=channels)
        else
            baseline_adjust!(exp; mode=mode, polyN=polyN, region=region)
        end
    end
    return exp
end

function filter_experiment(exp::Experiment{F,T}; kwargs...) where {F,T<:Real}
    exp_copy = deepcopy(exp)
    filter_experiment!(exp_copy; kwargs...)
    return exp_copy
end