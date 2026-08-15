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

## [0.6.16] - 2026-08-14

### Changed

- Reduced the Beta interface to NOW, BURN, RHYTHM and MODELS.
- Removed API-account data and navigation from the Desk payload.

### Security

- The device receives sanitized snapshots only: no credentials, prompts,
  account identifiers, monetary amounts, or local file paths.

[Unreleased]: https://github.com/luisroquette/notchagent-desk/compare/v0.6.16...HEAD
[0.6.16]: https://github.com/luisroquette/notchagent-desk/releases/tag/v0.6.16
