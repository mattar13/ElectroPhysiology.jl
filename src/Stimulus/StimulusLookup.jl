function parse_stimulus_name(stimulus_name::AbstractString)
    m = match(r"nd(\d+)_(\d+)p_(\d+)ms.abf", stimulus_name)
    nd = parse(Int, m.captures[1])
    percent = parse(Float64, m.captures[2])
    flash_duration = parse(Float64, m.captures[3])
    return (nd = nd, percent = percent, flash_duration = flash_duration)
end


percent_to_photons_eq(percent::Float64; slope = 1881.7, intercept = 1824.9) = slope * percent + intercept

function calculate_photons(stimulus_name::AbstractString)
    params = parse_stimulus_name(stimulus_name)
    photons = percent_to_photons_eq(params.percent) * 10^-params.nd * params.flash_duration
    return photons
end