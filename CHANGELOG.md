# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-08-11

### Added

- `anchored-points(...)` to place several points (and, optionally, their labels) in one call.
- `label-rotate` option for `anchored-point` labels.
- `label-styles` option for `anchored-point` labels (a dictionary spread into `text(...)` to style every label).
- `scatter(...)` for one-call scatter plots.
- `repere: false` now labels the origin `0` instead of the red `O`.
- `anchored-points(...)` now accepts a list of bare points (coordinate or anchor, no label) or points paired with a label — the two forms can be mixed freely.

### Changed

- Renamed `anchored-point-marker` to `anchored-point`.
- `anchored-point` / `anchored-points` `marker:` now also accepts the cetz/`plot.add` vocabulary (`mark`, `mark-fill`, `mark-stroke`, `mark-size`).

### Fixed

- Markers no longer worked in `anchored-points(...)` (they were not drawn); the `marker:` dictionary is now normalized correctly.

### Removed

- The obsolete simple-circle `anchored-point` helper (no longer needed after the rename).

## [0.1.0] - 2026-08-07

### Added

- Initial release: `newFig`, `setPlot`, `setAxes`, `setExtraStyles`, `monplot`, `anchored-basis-vectors`, `anchored-lines`, `anchored-derivative-arrow`, `anchored-point-marker`, `point-marker`, `draw-mark-shape`, `plot-scale`, `rotate-point`, `resolve-origine`.
