# Tutorial

This tutorial shows a practical baseline workflow with the currently loaded APIs.

## 1) Load ABF data

```julia
using ElectroPhysiology

exp = readABF("my_recording.abf"; stimulus_name = "IN 7")
size(exp)           # (trials, timepoints, channels)
getSampleFreq(exp)  # Hz
```

## 2) Inspect and slice data

```julia
first_trial_first_channel = exp[1, :, 1]
ch1 = getchannel(exp, 1)
first_two_trials = getdata(exp, 1:2, :, 1:size(exp, 3))
```

## 3) Attach or inspect stimulus protocol

```julia
stim = getStimulusProtocol(exp)
starts = getStimulusStartTime(exp)
ends = getStimulusEndTime(exp)
```

To add stimulus from a channel:

```julia
addStimulus!(exp, "IN 7")
```

## 4) Common preprocessing

```julia
exp2 = downsample(exp, 1000.0)
exp3 = truncate_data(exp2, 0.0, 1.0; truncate_based_on = :time_range)
exp4 = baseline_adjust(exp3)
avg = average_trials(exp4)
```

## 5) Two-photon workflow (image stack)

```julia
img = readImage("my_stack.tif")
deinterleave!(img, n_channels = 2)
pixel_splits_roi!(img, 16)

roi_mask = getROImask(img, 1)
roi_trace = getROIarr(img, 1)
```

## 6) Export

```julia
writeXLSX("processed.xlsx", avg)
```

For complete signatures and caveats, see [API Reference](API.md).
