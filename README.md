# NotchAgent Desk

**Your AI limits, always visible. No terminal. No tab switching.**

NotchAgent Desk is the physical 3.5-inch companion for Claude Code and Codex.
It turns local quota data from the [NotchAgent](https://github.com/luisroquette/notchagent)
desktop app into a dedicated, touch-first instrument on your desk.

> This repository is the source of truth for the **hardware product**: ESP32-S3
> firmware, USB protocol, compatibility contracts, factory documentation, and
> host SDKs. The desktop application lives in the separate
> [`luisroquette/notchagent`](https://github.com/luisroquette/notchagent) repository.

## Product boundary

| Product | Purpose | Platforms | Repository |
|---|---|---|---|
| **NotchAgent** | Native software gauge in the computer UI | macOS stable · Windows preview | [`notchagent`](https://github.com/luisroquette/notchagent) |
| **NotchAgent Desk** | Physical ESP32-S3 touch display over USB | macOS stable · Windows beta | **this repository** |

## How it works

```text
Claude Code / Codex local data
           ↓
NotchAgent host app (Mac or Windows)
           ↓  sanitized snapshot · USB CDC · protocol 1.1
NotchAgent Desk firmware 0.6.16
           ↓
NOW · BURN · RHYTHM · MODELS
```

The display has no provider credentials, cloud account, independent polling,
or product telemetry. The host app calculates; the Desk only renders a bounded,
sanitized snapshot.

## Current compatibility

- **macOS 14+ / Apple Silicon:** stable host path, signed and notarized app.
- **Windows 10/11 x64:** beta host path; protocol builds on Windows CI, physical
  USB/DPI/tray validation remains a release gate.
- **Firmware:** `0.6.16` on Guition `JC3248W535C_I` / ESP32-S3.
- **Wire protocol:** `1.1`; major versions must match.

See [`COMPATIBILITY.md`](COMPATIBILITY.md) before claiming a platform as supported.

## Repository map

```text
firmware/       Arduino + LVGL firmware
protocol/       wire contract and compatibility rules
sdk/apple/      Swift frame codec package
sdk/dotnet/     .NET 8 frame codec package
docs/           BOM, factory, onboarding and pilot gates
tools/          release and contract checks
```

## Build firmware

The toolchain is pinned to Arduino CLI `1.5.1`, ESP32 core `3.3.8`, LVGL
`9.2.2`, ArduinoJson `7.2.0`, and Arduino GFX `1.6.5`.

```bash
cd firmware/notchagent_desk
./build.sh build
```

## Validate

```bash
./tools/check-release-contract.sh
swift test --package-path sdk/apple
dotnet test sdk/dotnet/NotchAgent.Desk.Protocol.Tests/NotchAgent.Desk.Protocol.Tests.csproj
```

## Versioning

This project follows Semantic Versioning 2.0.0, Conventional Commits 1.0.0,
and a human-readable Keep a Changelog structure. Firmware, SDKs and published
artifacts are immutable after release. See [`VERSIONING.md`](VERSIONING.md).

## Buy and install

- Product: <https://cfgauss.com.br/shop/notchagent-desk>
- Two-minute setup: <https://cfgauss.com.br/notchagent/instalar>
- Support and recovery instructions: [`docs/ONBOARDING.md`](docs/ONBOARDING.md)

## License

Copyright © 2026 Luis Roquette. All rights reserved. Public access to this
repository does not grant permission to manufacture, redistribute, sublicense,
or sell the hardware, firmware, enclosure, or derived commercial products.
