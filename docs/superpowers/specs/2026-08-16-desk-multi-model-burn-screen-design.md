# Desk multi-model burn screen — design

**Status:** Approved
**Repo:** luisroquette/notchagent-desk (this repo)
**Companion spec:** `luisroquette/notchagent` →
`docs/superpowers/specs/2026-08-16-desk-multi-model-burn-protocol-design.md`
(defines the wire fields this spec consumes: `dominantModelShortName`,
`modelAlternates: [{shortName, priceRatio}]`, protocol `1.1` → `1.2`)

## Goal

Replace the BURN screen's current content (hero %, verdict panel, 20-segment
runway gauge, 3 metric tiles) with a real multi-line chart: the dominant
model's real burn curve plus up to 3 scaled alternate-model projections,
matching the app's v3.2.0 BURN chart feature. Full replacement, confirmed
explicitly by the product owner after reviewing what the current screen
contains.

## Current state (verified in `firmware/notchagent_desk/notchagent_desk.ino`,
commit `4f4242e`)

- `LV_USE_CHART` is **not** compiled in (`lv_conf.h`); `LV_USE_LINE` and
  `LV_USE_LABEL` are.
- `burnAgeSeconds[48]`/`burnUsedPercent[48]`/`burnPointCount` are parsed from
  the wire (lines ~1261-1266) but never drawn — dead data today.
- BURN card: `surface(pages[1], 0, 0, 464, 224, 14)` — the layout budget for
  the new chart.
- Existing color constants (top of file): `kPanel`, `kRaised`, `kCoral`,
  `kText`, `kMuted` — `constexpr uint32_t`, hex, used via `lv_color_hex(...)`.

## Approach

**Manual `lv_line` series, not `lv_chart`.** `LV_USE_CHART` isn't compiled
in; enabling it pulls in a widget with axis/scroll/tick semantics this
screen doesn't need, on a flash/RAM budget this repo has no local
measurement tooling for. `lv_line` is already enabled and is the primitive
the rest of this file already reasons in.

### Removed (all of it, per approved scope)

`burnHero`, `burnHeroCaption`, `burnVerdictPanel`, `burnVerdict`,
`burnStatus`, `burnGauge[20]`, the 3 `burnMetricValues[3]` tiles, `burnDetail`,
and their setup/update code (`notchagent_desk.ino` setup block ~L551-593,
update block ~L1054-1090).

### Added

- Keep `burnTitle` ("BURN") and `burnProvider` (dominant model name,
  top-right) — orientation anchors that already exist and already have the
  right data source.
- 4 new `constexpr uint32_t` color constants, copied verbatim from the app's
  `Sources/NotchAgent/Features/NotchOverlay/Components/Theme.swift` validated
  hex values, with a comment pointing at that file as the source of truth
  (this repo has no automated way to re-run the app's `dataviz` palette
  validator — visual parity depends on copying the exact numbers, not
  re-deriving them).
- 4 `lv_obj_t*` line objects (one per model: dominant + ≤3 alternates), each
  built from an `lv_point_t[48]` buffer populated from `burnHistory`
  directly for the dominant line, and from `burnUsedPercent[i] *
  alternate.priceRatio` (clamped to 100) for each alternate — the exact
  scale-and-cap rule from the app's `alternatePolyline`.
- Direct end-of-line labels: one `label()` call per line, positioned at that
  line's last point. With at most 4 labels on a 464×224 area, this is a
  simplified port of the app's `nonCollidingLabelY` — same nudge-down-until-
  clear loop, ported to plain C (no SwiftUI `Canvas` equivalent needed),
  clamped to the card's vertical bounds the same defensive way the app's
  `safeBounds` fix does (never construct a `ClosedRange`/inverted bound from
  degenerate input — the C port uses `max`/`min` clamps, no range type to
  misconstruct).
- Cold-start state: when `burnPointCount == 0` (no history yet), show the
  existing `burnStatus`-style copy — reuse the string "LEARNING YOUR PACE"
  instead of drawing an empty chart, matching what the app itself shows on
  first launch (verified live during this session: blank chart, no lines,
  on a cold `percentHistory`).
- Fable exclusion as dominant model is enforced entirely on the app side
  (`ModelProjection.dominantModel` already restricts to the shared pool).
  Firmware does not re-derive dominance — it trusts
  `dominantModelShortName` verbatim. If it's ever `Fable` (should not
  happen per the companion spec), firmware still renders it correctly; no
  special-case needed here.

## Data flow

```
USB JSON frame
   │  dominantModelShortName, modelAlternates[], burnHistory[] (existing field)
   ▼
parse (existing JSON parsing block, extended for 2 new fields)
   │
   ▼
per-alternate: scale burnUsedPercent[i] * priceRatio, clamp 100
   │
   ▼
lv_line_set_points × 4  +  4 end-of-line labels  +  cold-start fallback
```

## Versioning

- `PROTOCOL_VERSION`: `1.1` → `1.2` (matches the companion app spec).
- Desk product/firmware `VERSION`: `0.6.16` → `0.7.0` (MINOR — "backward-
  compatible screen ... capability" per this repo's `VERSIONING.md`).
- `CHANGELOG.md`: new `## [0.7.0]` entry, Added/Changed sections.
- `COMPATIBILITY.md`: update per this repo's release gate #4 — minimum
  compatible NotchAgent host version becomes `3.3.0` (the app version that
  first sends `modelAlternates`).

## Testing / validation — explicit limitation

- `arduino-cli` is installed locally; `firmware/notchagent_desk/build.sh`
  and `verify-toolchain.sh` can compile-verify the `.ino` against the pinned
  ESP32 core/library versions from this environment. This catches syntax,
  type, and missing-symbol errors.
- **Not possible from this environment:** flashing the physical ESP32-S3,
  visually confirming legibility of 4 lines + labels on the real 480×320
  panel, or exercising the Apple/.NET protocol SDKs against live USB
  traffic. This repo's own release gate #4 ("current-platform physical
  compatibility evidence") requires hardware-in-hand — stays a manual step
  for the product owner before tagging `v0.7.0` stable. This plan produces
  a compile-clean, protocol-correct, documented `-beta.N` state; hardware
  sign-off happens after.

## Out of scope

- Any change to the NOW, RHYTHM, or MODELS screens.
- Any change to the runway-gauge concept beyond its removal from BURN (no
  replacement elsewhere).
