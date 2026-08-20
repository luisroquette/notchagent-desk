# NotchAgent Desk USB protocol 1.3

## Transport

- USB CDC serial at 115200 baud.
- COBS-encoded frames terminated by `0x00`.
- CRC-32/ISO-HDLC checksum over header and payload.
- Maximum JSON payload: 16 KiB.

## Frame layout

| Offset | Size | Field |
|---:|---:|---|
| 0 | 4 | magic `NADK` |
| 4 | 1 | protocol major |
| 5 | 1 | frame type |
| 6 | 4 | sequence, little-endian |
| 10 | 4 | payload length, little-endian |
| 14 | N | UTF-8 JSON payload |
| 14+N | 4 | CRC-32, little-endian |

Frame types: hello `1`, hello acknowledgement `2`, snapshot `3`, heartbeat `4`,
and device telemetry `5`.

## Handshake

The host sends a random nonce in `hello`. The device must return the same nonce,
the exact product string `NotchAgent Desk`, firmware version, and protocol
version. Major mismatches fail closed.

## Snapshot additions by protocol version

- **1.3** — snapshot payload adds optional `currentHour` (int) and
  `currentHourElapsedFraction` (double, 0–1). A host on protocol 1.2 or older
  does not send them; devices must read their absence as "no current-hour
  information," never as hour 0 in progress.
- **1.2** — snapshot payload adds `dominantModelShortName` and
  `modelAlternates`.

## Privacy boundary

Snapshots may contain provider IDs, bounded quota metrics, timestamps, token
totals, aggregate health, burn/rhythm points, and model labels. They must not
contain credentials, prompts, account IDs or labels, financial amounts, raw
errors, device serials, or local file paths.

