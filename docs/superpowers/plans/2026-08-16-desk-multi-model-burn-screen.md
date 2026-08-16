# Desk Multi-Model Burn Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the BURN screen's hero/verdict/gauge/tiles with a real
4-line chart (dominant model + up to 3 alternates), consuming the
`dominantModelShortName`/`modelAlternates` wire fields defined in the
companion `notchagent` repo's protocol plan.

**Architecture:** All state and logic lives in the single existing sketch
file `firmware/notchagent_desk/notchagent_desk.ino` (1485 lines today, no
other firmware source files) — parse the 2 new JSON fields into fixed-size
globals, then draw 4 `lv_line` objects (manual, not `lv_chart` — not
compiled in) scaled from the existing `burnUsedPercent`/`burnAgeSeconds`
arrays, with direct end-of-line labels.

**Tech Stack:** Arduino C++ (ESP32-S3), LVGL 9.2.2, ArduinoJson.

## Global Constraints

- No new source files — this sketch is a single `.ino`, matching every
  existing convention in it (helpers, globals, structs all live at file
  scope, in the order they're introduced).
- Colors are copied verbatim (not re-derived) from
  `notchagent`'s `Sources/NotchAgent/Features/NotchOverlay/Components/
  Theme.swift` **dark** variant (this device's background is fixed black,
  `kPanel = 0x000000`): Haiku `0x3987E5`, Sonnet `0x199E70`, Opus
  `0x9085E9`, Fable `0xD55181`. A comment must point at that file as the
  source of truth, since this repo has no way to re-run the app's
  `dataviz` palette validator.
- Verification for every task in this plan is `./firmware/notchagent_desk/
  build.sh build` (compiles via the pinned `arduino-cli` toolchain — see
  `verify-toolchain.sh`) — there is no unit-test framework for LVGL
  rendering in this repo. A clean compile is the pass/fail gate.
- `PROTOCOL_VERSION` file goes `1.1` → `1.2` (matches the companion app
  plan's `protocolMinor` bump) — part of Task 1.
- Field names on the wire must match the companion app plan exactly:
  `dominantModelShortName` (string), `modelAlternates` (array of
  `{shortName, priceRatio}`) — verified against
  `2026-08-16-desk-multi-model-burn-protocol-design.md` in `notchagent`.

---

### Task 1: Parse the new wire fields

**Files:**
- Modify: `firmware/notchagent_desk/notchagent_desk.ino`
- Modify: `PROTOCOL_VERSION`

**Interfaces:**
- Produces: globals `dominantModelShortName[8]`, `hasDominantModel`,
  `burnAlternates[3]` (`BurnAlternateState { shortName[8], priceRatio }`),
  `burnAlternateCount` — consumed by Task 3's render function.

- [ ] **Step 1: Add the struct and globals**

In `notchagent_desk.ino`, add the struct right after `struct ModelState { ...
}` (currently line 36-41):

```cpp
struct BurnAlternateState {
  char shortName[8] = "";
  float priceRatio = 1.0f;
};
```

Add the globals right after `size_t burnPointCount = 0;` (currently line
62):

```cpp
size_t burnPointCount = 0;
char dominantModelShortName[8] = "";
bool hasDominantModel = false;
BurnAlternateState burnAlternates[3];
size_t burnAlternateCount = 0;
```

- [ ] **Step 2: Parse the fields in `parseSnapshot`**

In `parseSnapshot(...)`, right after the existing `burnHistory` loop (ends
at `++burnPointCount; }`, currently line 1266) and before the `rhythm` loop,
add:

```cpp
  hasDominantModel = document["dominantModelShortName"].is<const char *>();
  strlcpy(dominantModelShortName, document["dominantModelShortName"] | "",
          sizeof(dominantModelShortName));
  burnAlternateCount = 0;
  for (JsonObject item : document["modelAlternates"].as<JsonArray>()) {
    if (burnAlternateCount >= 3) break;
    BurnAlternateState &state = burnAlternates[burnAlternateCount++];
    strlcpy(state.shortName, item["shortName"] | "", sizeof(state.shortName));
    state.priceRatio = max(0.0f, item["priceRatio"].as<float>());
  }
```

This mirrors the existing `models` loop immediately below it (same
`JsonObject item : document["..."].as<JsonArray>()` shape, same
bounds-check-before-write pattern).

- [ ] **Step 3: Reset the new state in `clearData()`**

In `clearData()` (currently line 1195-1202), add alongside the existing
`providerCount = modelCount = 0; burnPointCount = 0;`:

```cpp
  hasDominantModel = false;
  burnAlternateCount = 0;
```

- [ ] **Step 4: Bump the protocol version**

In `PROTOCOL_VERSION` (repo root), change the content from `1.1` to `1.2`.

- [ ] **Step 5: Compile-verify**

Run: `./firmware/notchagent_desk/build.sh build`
Expected: compiles clean, no new warnings. This is the pass/fail gate —
no unit test exists for this parsing path in this repo.

- [ ] **Step 6: Commit**

```bash
git add firmware/notchagent_desk/notchagent_desk.ino PROTOCOL_VERSION
git commit -m "feat(protocol): parse dominantModelShortName and modelAlternates"
```

---

### Task 2: Replace the BURN screen's static UI (setup)

**Files:**
- Modify: `firmware/notchagent_desk/notchagent_desk.ino`

**Interfaces:**
- Consumes: nothing new from Task 1 yet (this task only builds the empty
  line/label objects; Task 3 feeds them data).
- Produces: globals `burnLines[4]`, `burnLineLabels[4]`, `burnEmptyLabel`,
  `burnLinePoints[4][48]` — consumed by Task 3.

- [ ] **Step 1: Remove the old BURN object globals**

Delete these 8 lines (currently lines 94-102):

```cpp
lv_obj_t *burnHero = nullptr;
lv_obj_t *burnHeroCaption = nullptr;
lv_obj_t *burnProvider = nullptr;
lv_obj_t *burnVerdictPanel = nullptr;
lv_obj_t *burnVerdict = nullptr;
lv_obj_t *burnDetail = nullptr;
lv_obj_t *burnStatus = nullptr;
lv_obj_t *burnGauge[20] = {};
lv_obj_t *burnMetricValues[3] = {};
```

Replace with:

```cpp
lv_obj_t *burnProvider = nullptr;
lv_obj_t *burnLines[4] = {};
lv_obj_t *burnLineLabels[4] = {};
lv_obj_t *burnEmptyLabel = nullptr;
lv_point_precise_t burnLinePoints[4][48];
```

(`burnProvider` is kept — it's still used, just repurposed to show the
dominant model's name instead of the primary provider's.)

- [ ] **Step 2: Add the 4 model colors and the color-lookup helper**

Add the 4 constants next to the existing color block (currently lines
12-20, after `kDanger`):

```cpp
// Copied verbatim from notchagent's Theme.swift (dark variant — this
// device's background is fixed black). Not re-derived here; if the app's
// validated palette changes, update these 4 to match.
constexpr uint32_t kModelHaiku = 0x3987E5;
constexpr uint32_t kModelSonnet = 0x199E70;
constexpr uint32_t kModelOpus = 0x9085E9;
constexpr uint32_t kModelFable = 0xD55181;
```

Add the lookup helper next to `styleTracking` (currently lines 167-169):

```cpp
uint32_t colorForModelShortName(const char *shortName) {
  if (!strcmp(shortName, "Haiku")) return kModelHaiku;
  if (!strcmp(shortName, "Sonnet")) return kModelSonnet;
  if (!strcmp(shortName, "Opus")) return kModelOpus;
  if (!strcmp(shortName, "Fable")) return kModelFable;
  return kMuted;
}
```

- [ ] **Step 3: Replace the BURN card setup block**

Replace the entire block from `lv_obj_t *burnCard = surface(pages[1], 0, 0,
464, 224, 14);` through `lv_label_set_long_mode(burnDetail,
LV_LABEL_LONG_CLIP);` (currently lines 551-593) with:

```cpp
  lv_obj_t *burnCard = surface(pages[1], 0, 0, 464, 224, 14);
  lv_obj_t *burnTitle = label(burnCard, "BURN FORECAST", &lv_font_montserrat_12, kCoral, 14, 10);
  styleTracking(burnTitle, 1);
  lv_obj_t *burnQuestion = label(burnCard, "WHAT IF I SWITCHED MODELS?", &lv_font_montserrat_12, kMuted, 178, 10);
  styleTracking(burnQuestion, 1);
  burnProvider = label(burnCard, "--", &lv_font_montserrat_12, kCoral, 366, 10);
  lv_obj_set_width(burnProvider, 82);
  lv_obj_set_style_text_align(burnProvider, LV_TEXT_ALIGN_RIGHT, 0);

  for (int i = 0; i < 4; ++i) {
    burnLines[i] = lv_line_create(burnCard);
    lv_obj_remove_flag(burnLines[i], LV_OBJ_FLAG_CLICKABLE);
    lv_obj_set_style_line_width(burnLines[i], i == 0 ? 3 : 2, 0);
    lv_obj_set_style_line_rounded(burnLines[i], true, 0);
    lv_obj_add_flag(burnLines[i], LV_OBJ_FLAG_HIDDEN);
    burnLineLabels[i] = label(burnCard, "", &lv_font_montserrat_12, kMuted, 0, 0);
    lv_obj_set_width(burnLineLabels[i], 60);
    lv_obj_set_style_text_align(burnLineLabels[i], LV_TEXT_ALIGN_RIGHT, 0);
    lv_obj_add_flag(burnLineLabels[i], LV_OBJ_FLAG_HIDDEN);
  }
  burnEmptyLabel = label(burnCard, "LEARNING YOUR PACE", &lv_font_montserrat_16, kMuted, 14, 96);
```

- [ ] **Step 4: Compile-verify**

Run: `./firmware/notchagent_desk/build.sh build`
Expected: compiles clean. `refreshUI()` still references the now-deleted
`burnHero`/`burnVerdict`/etc. at this point — that's Task 3's job, so this
step is expected to **fail** until Task 3 lands. Confirm the failure is
exactly the expected "use of undeclared identifier" errors for those
removed names, and no other errors — that isolates this task's own change
as correct before Task 3 touches `refreshUI()`.

- [ ] **Step 5: Commit**

```bash
git add firmware/notchagent_desk/notchagent_desk.ino
git commit -m "feat(burn-screen): replace hero/verdict/gauge UI with line-chart objects"
```

Note: this commit intentionally leaves the build broken (Task 3 fixes it
in the same PR before merge) — acceptable here because both tasks are
part of one small, sequential plan reviewed together, not shipped
independently.

---

### Task 3: Render the 4 lines and their labels

**Files:**
- Modify: `firmware/notchagent_desk/notchagent_desk.ino`

**Interfaces:**
- Consumes: `dominantModelShortName`, `hasDominantModel`, `burnAlternates`,
  `burnAlternateCount` (Task 1), `burnLines`, `burnLineLabels`,
  `burnEmptyLabel`, `burnLinePoints` (Task 2), and the existing
  `burnUsedPercent[48]`/`burnPointCount` globals (unchanged).

- [ ] **Step 1: Remove the old BURN update block**

In `refreshUI()`, delete the block from `const ProviderState *primary =
providerCount ? &providers[0] : nullptr;` through `lv_obj_set_style_bg_color
(burnGauge[segment], ...)` closing brace (currently lines 1043-1110 — ends
right before the RHYTHM section's `int64_t peak = 1;`).

Replace it with a single call:

```cpp
  updateBurnLines();
```

- [ ] **Step 2: Add the `updateBurnLines` function**

Add this new function directly above `void refreshUI() {` (currently line
991), so it's defined before its call site:

```cpp
void updateBurnLines() {
  const bool hasData = hasDominantModel && burnPointCount >= 2;
  lv_label_set_text(burnProvider, hasDominantModel ? dominantModelShortName : "--");

  if (hasData) lv_obj_add_flag(burnEmptyLabel, LV_OBJ_FLAG_HIDDEN);
  else lv_obj_remove_flag(burnEmptyLabel, LV_OBJ_FLAG_HIDDEN);

  const int chartLeft = 14;
  const int chartRight = 450;
  const int chartTop = 40;
  const int chartBottom = 208;
  const int chartWidth = chartRight - chartLeft;
  const int chartHeight = chartBottom - chartTop;
  const size_t seriesCount = hasData ? 1 + burnAlternateCount : 0;

  int placedLabelY[4];
  size_t placedCount = 0;

  for (size_t series = 0; series < 4; ++series) {
    if (series >= seriesCount) {
      lv_obj_add_flag(burnLines[series], LV_OBJ_FLAG_HIDDEN);
      lv_obj_add_flag(burnLineLabels[series], LV_OBJ_FLAG_HIDDEN);
      continue;
    }
    const bool isDominant = series == 0;
    const float ratio = isDominant ? 1.0f : burnAlternates[series - 1].priceRatio;
    const char *seriesName = isDominant ? dominantModelShortName : burnAlternates[series - 1].shortName;
    const uint32_t color = isDominant ? kCoral : colorForModelShortName(seriesName);

    for (size_t i = 0; i < burnPointCount; ++i) {
      const float scaledPercent = constrain(burnUsedPercent[i] * ratio, 0.0f, 100.0f);
      const float x = chartLeft + chartWidth *
        (burnPointCount > 1 ? static_cast<float>(i) / (burnPointCount - 1) : 1.0f);
      const float y = chartTop + chartHeight * (1.0f - scaledPercent / 100.0f);
      burnLinePoints[series][i] = {x, y};
    }
    lv_line_set_points(burnLines[series], burnLinePoints[series], burnPointCount);
    lv_obj_set_style_line_color(burnLines[series], lv_color_hex(color), 0);
    lv_obj_remove_flag(burnLines[series], LV_OBJ_FLAG_HIDDEN);

    int labelY = static_cast<int>(burnLinePoints[series][burnPointCount - 1].y) - 6;
    for (size_t p = 0; p < placedCount; ++p) {
      if (abs(labelY - placedLabelY[p]) < 12) labelY = placedLabelY[p] + 12;
    }
    labelY = constrain(labelY, chartTop, chartBottom - 12);
    placedLabelY[placedCount++] = labelY;

    lv_label_set_text(burnLineLabels[series], seriesName);
    lv_obj_set_style_text_color(burnLineLabels[series], lv_color_hex(color), 0);
    lv_obj_set_pos(burnLineLabels[series], chartRight - 60, labelY);
    lv_obj_remove_flag(burnLineLabels[series], LV_OBJ_FLAG_HIDDEN);
  }
}
```

Notes for the implementer:
- `lv_point_precise_t` fields are `x`/`y` of type `float`
  (`lv_value_precise_t`, confirmed in this repo's vendored
  `lv_area.h`) — the aggregate-init `{x, y}` above relies on that.
- X-axis is evenly spaced by **sample index**, not by exact `ageSeconds`
  gaps — `burnHistory` is already ordered oldest-first (confirmed by the
  companion app repo's own test,
  `testBurnHistoryUsesPrimaryProviderAndBoundsValues`), and samples arrive
  at a roughly constant cadence, so index-spacing is a deliberate
  simplification versus the app's exact time-axis, not a bug.
- Label horizontal position is a fixed `chartRight - 60`, not a dynamic
  measure-and-flip like the app's `drawEndLabel` — there's no cheap
  text-measurement API already in use in this codebase to mirror that, and
  a fixed-width right-aligned label at a fixed x is always on-canvas by
  construction, which is the property that mattered.

- [ ] **Step 3: Compile-verify**

Run: `./firmware/notchagent_desk/build.sh build`
Expected: compiles clean now (this task's `updateBurnLines()` supplies
every symbol Task 2's setup code needs).

- [ ] **Step 4: Commit**

```bash
git add firmware/notchagent_desk/notchagent_desk.ino
git commit -m "feat(burn-screen): draw dominant + alternate model lines with end labels"
```

---

## Self-Review

- **Spec coverage:** full replacement of hero/verdict/gauge/tiles (Task 2),
  4-line chart with direct labels (Task 3), cold-start state (Task 3),
  colors copied from the app (Task 2), protocol bump (Task 1) — every
  requirement in `2026-08-16-desk-multi-model-burn-screen-design.md` maps
  to a task.
- **Placeholder scan:** none — every step has complete code against real,
  read line numbers in the actual current file.
- **Type consistency:** `BurnAlternateState.shortName`/`.priceRatio` match
  the wire field names (`shortName`, `priceRatio`) from the companion app
  plan's `DeskSnapshot.ModelAlternate`.
- **Known limitation, called out explicitly (not hidden):** Task 2's commit
  leaves the sketch non-compiling until Task 3 lands, 1 commit later in the
  same plan — flagged in Task 2 Step 4/5 rather than silently glossed over.

## After this plan lands

- Firmware `VERSION`: `0.6.16` → `0.7.0`.
- `CHANGELOG.md`: new `## [0.7.0]` entry (Added: multi-model burn chart;
  Changed: BURN screen layout).
- `COMPATIBILITY.md`: minimum compatible NotchAgent host version →
  `3.3.0`.
- Hardware sign-off (flash + visual legibility check on the physical
  480×320 panel) is a manual step for the product owner — not achievable
  from this environment. `-beta.N` until that's done, per this repo's own
  `VERSIONING.md` prerelease rule.
