# Compatibility matrix

Status definitions:

- **Stable:** automated tests plus current-version physical hardware evidence.
- **Beta:** automated tests pass; at least one current physical platform gate is pending.
- **Unsupported:** no release contract or no maintained host path.

| Desk | Firmware | Protocol | Host app | macOS | Windows | Hardware |
|---|---:|---:|---:|---|---|---|
| Beta 1 | 0.6.16 | 1.1 | NotchAgent 3.1.2+ | Stable | Beta | JC3248W535C_I rev A |

## Windows promotion gate

Windows remains Beta until all checks pass on Windows 10 and Windows 11:

1. USB discovery and authenticated handshake on a physical Desk;
2. 100 reconnect cycles and abrupt-power recovery;
3. 24-hour soak without invalid frames or stale data;
4. 100%, 150% and 200% DPI plus multi-monitor/tray behavior;
5. signed installer and clean SmartScreen path.

Marketing and release notes must display `Windows beta` until this file records
the evidence that promotes it to Stable.

