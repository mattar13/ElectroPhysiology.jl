@testset "Image helpers on synthetic TWO_PHOTON data" begin
    px, py, frames, channels = 4, 3, 5, 2
    data_array = reshape(collect(1.0:(px * py * frames * channels)), px * py, frames, channels)
    dt = 0.1
    t = collect(0.0:dt:(frames - 1) * dt)

    exp = Experiment(
        TWO_PHOTON,
        Dict("framesize" => (px, py), "xrng" => 1:px, "yrng" => 1:py),
        dt,
        t,
        data_array,
        ["ch1", "ch2"],
        ["px", "px"],
        [1.0, 1.0],
    )

    frame2 = get_frame(exp, 2)
    @test size(frame2) == (px, py, 1, channels)

    all_frames = get_all_frames(exp)
    @test size(all_frames) == (px, py, frames, channels)

    @test getIMG_size(exp) == (px, py)
end
