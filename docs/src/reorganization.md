# Repository Reorganization Plan

This plan keeps behavior stable while making the package easier to maintain and document.

## Goals

- Make public API boundaries explicit
- Separate stable/public APIs from experimental utilities
- Eliminate stale docs and unused exports
- Make docs generation deterministic

## Proposed Layout

```text
src/
  ElectroPhysiology.jl
  Core/
    types.jl
    base_overloads.jl
    accessors.jl
  Stimulus/
    protocol.jl
    extraction.jl
  Readers/
    ABF/
      reader.jl
      headers.jl
      waveform.jl
    Image/
      reader.jl
  Processing/
    modify.jl
    join.jl
    export.jl
  Imaging/
    roi.jl
    morphology.jl
  Optional/
    xlsx.jl
    mat.jl
    wavelet.jl
```

## Export Policy

- Export only stable, tested functions.
- Keep helper/internal methods unexported (`ElectroPhysiology.<name>` access only).
- Remove exported symbols with no implementation (for example `find_boutons`) or implement them before export.

## Initialization Strategy

- Replace legacy `OLD__init__` optional loading path with either:
  - explicit normal includes for stable dependencies, or
  - clearly separated extension modules (Julia package extension mechanism).

## Documentation Strategy

- Keep one source-aligned API reference (`docs/src/API.md`) as the canonical surface.
- Keep a short tutorial with tested workflows.
- Avoid docs pages that depend on symbols not in the current module load path.

## Suggested Migration Steps

1. Freeze API surface for next minor release.
2. Move files into the new folder layout without changing signatures.
3. Update `src/ElectroPhysiology.jl` includes/exports.
4. Add/repair tests for each exported symbol.
5. Remove deprecated names after one deprecation cycle.

## High-Value Fixes Before Reorg

- Fix constructor bugs and stale references in `StimulusProtocol`.
- Fix `Experiment(time, data)` dt calculation.
- Resolve exported-but-missing functions.
- Decide whether filtering APIs are public in this package or delegated to `PhysiologyAnalysis.jl`.
