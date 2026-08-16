# Changelog

All notable changes to NotchAgent Desk are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project follows
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Independent product repository and explicit boundary from the NotchAgent app.
- Apple and .NET protocol SDK packages.
- Cross-platform compatibility and release contracts.

### Fixed

- Windows SDK exception compatibility and deterministic Arduino library path in CI.

## [0.7.0] - 2026-08-16

### Added

- BURN screen now shows a real multi-line chart: the dominant Claude model's
  burn curve plus up to 3 scaled alternate-model projections (Haiku, Sonnet,
  Opus, Fable), with direct end-of-line labels — mirrors the NotchAgent app's
  v3.2.0/3.3.0 burn chart feature.

### Changed

- BURN screen's hero percentage, verdict panel, 20-segment runway gauge, and
  metric tiles are replaced by the line chart above. This is a full layout
  replacement, not an addition.

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

[Unreleased]: https://github.com/luisroquette/notchagent-desk/compare/v0.7.0...HEAD
[0.7.0]: https://github.com/luisroquette/notchagent-desk/compare/v0.6.16...v0.7.0
[0.6.16]: https://github.com/luisroquette/notchagent-desk/releases/tag/v0.6.16
