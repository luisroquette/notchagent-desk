# Changelog

All notable changes to NotchAgent Desk are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project follows
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.8.0] - 2026-08-20

### Added

- BURN touch scrubber: press-and-drag on the burn chart shows the nearest
  model line's percentage and age at the touch point — the macOS app's hover
  readout, reworked for touch.
- RHYTHM touch scrubber: press-and-drag on the hourly bars shows the touched
  hour's exact token count, suffixed "SO FAR" while that hour is still running.
- Current-hour projection on the RHYTHM chart: an outline-only cap above the
  live bar extrapolates the hour to full length, shown only after 15% of the
  hour has elapsed (same grace fraction as the macOS app).
- Clawd mascot per model row on the MODELS page, breathing at clinically real
  resting rates and accelerating as the shared Claude pool nears empty; an
  unmeasured quota renders as a frozen, dimmed mascot, never a fabricated calm
  one.

### Changed

- Page transition eased to a 260 ms quartic glide, matching the macOS pager.
- BURN/RHYTHM chart geometry extracted into shared constants so drawing and
  touch readout cannot drift apart.

### Protocol

- Wire protocol minor version 1.2 → 1.3 (additive fields: `currentHour`,
  `currentHourElapsedFraction` — sent by NotchAgent host 3.4.0+, read
  defensively by this firmware and ignored by older firmware).

## [0.7.0] - 2026-08-16

### Added

- Independent product repository and explicit boundary from the NotchAgent app.
- Apple and .NET protocol SDK packages.
- Cross-platform compatibility and release contracts.
- BURN screen now shows a real multi-line chart: the dominant Claude model's
  burn curve plus up to 3 scaled alternate-model projections (Haiku, Sonnet,
  Opus, Fable), with direct end-of-line labels — mirrors the NotchAgent app's
  v3.2.0/3.3.0 burn chart feature.

### Changed

- BURN screen's hero percentage, verdict panel, 20-segment runway gauge, and
  metric tiles are replaced by the line chart above. This is a full layout
  replacement, not an addition.

### Fixed

- Windows SDK exception compatibility and deterministic Arduino library path in CI.

### Protocol

- Wire protocol minor version 1.1 → 1.2 (additive fields:
  `dominantModelShortName`, `modelAlternates` — older/newer hosts and
  firmware remain compatible per this repo's protocol-minor contract).

## [0.6.16] - 2026-08-14

### Changed

- Reduced the Beta interface to NOW, BURN, RHYTHM and MODELS.
- Removed API-account data and navigation from the Desk payload.

### Security

- The device receives sanitized snapshots only: no credentials, prompts,
  account identifiers, monetary amounts, or local file paths.

[Unreleased]: https://github.com/luisroquette/notchagent-desk/compare/v0.8.0...HEAD
[0.8.0]: https://github.com/luisroquette/notchagent-desk/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/luisroquette/notchagent-desk/compare/v0.6.16...v0.7.0
[0.6.16]: https://github.com/luisroquette/notchagent-desk/releases/tag/v0.6.16
