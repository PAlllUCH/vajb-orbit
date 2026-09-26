---
slice: S20
worker: S20-B1
model: "deepseek/deepseek-flash (crush run, reasoning max)"
status: actionable
gate: "887/0 → 895/0 (two fresh-store runs)"
---

# S20-B1 report — ARMORY chrome unification + the shell inspector pin

## Result

A4.1–A4.4 built and gated. Gate 887/0 → **895/0**, twice, both on
`XDG_DATA_HOME=$(mktemp -d)` stores, every run bounded `--quit-after 1200`. 8 new rows:
7 in `tests/test_s20_chrome_unify.gd` (AC1–AC5) + 1 in `tests/test_s11_inspector.gd`.

## Pre-grep of brief §3 (before any edit) and the route taken

| Row | Route | Verdict as built |
|---|---|---|
| `test_d7_armory.gd:325-341` plate texture/master block | A4.1 master retires | **moved** — `plate.texture == null`; master on disk; theme frame at 32 px asserted |
| `test_d7_armory.gd:741` `probe.console_path` | A4.1 | **moved** — line retires with the field |
| `test_d7_armory.gd:798-807` master ships / scripted-master | A4.1 | **moved** — `style.console_path == null` + master on disk |
| `test_d7_armory.gd:784` `ArmoryStyle is CockpitStyle` | A4.5 keeps `ui_seg_*` | unchanged ✓ |
| `test_d7_armory.gd:601-608` danger tag tone | unlisted, forced | **moved** — A4.3/L227 (deviation 2) |
| `test_d7_armory.gd:817-818` caption hex literals | unlisted, forced | **1:1 re-point** — same values from Tokens (deviation 3) |
| `test_s15_armory_layout.gd:32/:213-218` const + plate rows | A4.1 | **moved** — master 2x on disk, unwired; chrome = theme frame |
| `test_s15_armory_layout.gd` geometry pins | layout frozen | unchanged ✓ |
| `test_s18_armory_rework.gd:429-430`, 13 px/contrast/P5/P6/layer-order | retired / floors stand | unchanged ✓ (suite green) |
| `test_s11_inspector.gd:291` `max_lines_visible == 2` | seam unchanged | unchanged ✓; suite **gained** the A4.4 pin row |
| `test_s10_armory_input.gd`, `test_p2b1_outfitting_panel.gd` | skin only | unchanged ✓ (no retired plate named; both green) |

## A4 surface → chrome as built

| Surface | As built |
|---|---|
| `%ConsolePlate` (master) | texture cleared at build (`armory_panel.gd:870`); floor = the host's `PanelRaised` frame |
| bay cards, wells halves | `ConsolePanels._frame` draws the theme's `PanelRaised` box (`ui_panel_frame`, 32 px patch) over `bay_rect`/`well_half_rect` |
| pack/row plates (`RowPlate`) | the same theme box + the 1 px danger frame when in danger |
| bay cells (4 × 5) | `SlotButtonWeapon/normal` (`ui_slot_weapon_normal.png`) over every cell rect |
| fitted name plate | `StationButton` (unchanged) |
| `BUY` | `Button` + `StationButton` (was `ChipPlate`); press routes to the same buy |
| `✕` (`Close`) | `StationButton`, `flat` removed |
| state chips (all six wordings) | label + 1 px frame kept (`ChipPlate`, `frame_width`) in Tokens tones |
| palette (9 fields) | `Tokens/armory_*` via `ArmoryStyle.resolve_theme()` (`_init`) — zero hex in pane/style |

## Measured

- **OVER CAP contrast:** bay chip **4.86:1**, pack card **4.86:1** (`accent_danger_bright`
  `#e8622a` on `armory_chip_danger_bg` `#381509`, the mockup's 78,32,18 darkened; L227's
  4.04 cured). Printed by `test_s20_chrome_unify.gd` (`[s20] OVER CAP ratio`).
- **Inspector pin (A4.4):** title pin `21.0`, body pin `45.0` (font-derived); live heights
  `[154.0, 154.0, 154.0, 154.0]` at body content `""`, 1, 2 and 4 lines; `ModuleHost`
  rect `(376, 0) + 1496×710` identical across all four emits.
- **Visual:** `tests/probe_s20_capture.gd` (windowed, scratch store) — bays/wells framed,
  slot-chrome cells, plated `BUY`/`✕`, `▲ OVER CAP` chip, dark console floor. PNG at
  `/tmp/s20_cap_*/godot/app_userdata/Vajb Orbit/s20_armory_capture.png`.
- Owner's live profile untouched (md5 `d9d878e2…`, 6412 B, mtime 10:10, pre-session).

## Deviations / judgment calls

1. **`armory_panel.tscn` is outside this worker's file set (hook-blocked).** The scene
   still carries the `ui_armory_console` ext_resource + `ConsolePlate` texture property;
   `_apply_style` clears the texture at build, so the pane never draws it. Clean-up for a
   later pass: drop both lines.
2. **Danger tag tone moved `accent_danger` → `accent_danger_bright`** (`_style_danger`,
   unlisted d7 row). Forced by A4.3's 4.5:1 pin: `accent_danger`'s ceiling is 4.38:1
   against pure black, so no fill can cure it.
3. **d7:817-818** re-pointed from hex literals to `Tokens/armory_caption`(`_void`) —
   unlisted, values byte-identical, forced by AC3's zero-hex rule.
4. **The three `rarity_*` tokens were missing from `tools/build_theme.gd`** — they lived
   only in the shipped `.tres`, so a plain regeneration dropped them (would fail
   `test_s3_auction.gd:689-691`). Registered in the builder with the same hexes.
5. **Theme regeneration used `--headless --editor --script`:** plain `--script` strips
   every `uid` line from the `.tres` (measured); editor mode preserves them.
6. **`resolve_theme()` reads `res://ui/theme/vajb_theme.tres`** (the `game/weapons.gd`
   precedent) in `_init`, so a user `.tres`'s stored values still win.
7. **Bay cells draw the family plate at the cell's 117×52 box** (the
   `SlotButton.configure_cell` idiom); the painted silhouette stretches. Nine-slice/tile of
   the 48×48 plate smears or repeats worse (measured).
8. **The pin adds the label's `line_spacing` constant** per line — without it the 2-line
   state sat 3 px above the one-line pin (measured).
9. **A4.5/T8 reported, not touched:** the seven-seg ledge, its rects, caption and figure
   are byte-identical to S18 (tick T5 can still re-open it).
10. **Reported not fixed:** the *resting* card-chip label falls back to `Tokens/text_dim`
    on `chip_bg` (measured 2.70:1) because `_style_danger(false)` removes the caption
    override; `test_d7_armory.gd:610-615` (unlisted) pins that removal.

## Evidence

```bash
# baseline (pre-edit, fresh store):   [SUMMARY] passed=887 failed=0
XDG_DATA_HOME=$(mktemp -d) $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
  res://tests/headless_runner.tscn --quit-after 1200   # x2 -> [SUMMARY] passed=895 failed=0
XDG_DATA_HOME=$(mktemp -d) $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
  res://tests/headless_runner.tscn --quit-after 1200 -- --suite=test_s20_chrome_unify   # 7/7
XDG_DATA_HOME=$(mktemp -d) $GODOT_CONSOLE --path "$VAJB_PROJ" \
  res://tests/probe_s20_capture.tscn --quit-after 400
$GODOT_CONSOLE --headless --editor --path "$VAJB_PROJ" --script res://tools/build_theme.gd
```

## Files touched

- `ui/station/armory_panel.gd` — frame bays/wells/rows, slot-chrome cells, plated BUY/✕, bright danger tone, master unwired.
- `ui/station/armory_style.gd` — console fields retired; `resolve_theme()` + `PALETTE_ROLES`.
- `ui/screens/station.gd` — A4.4 `_pin_inspector_height()` / `_lines_height()`.
- `tools/build_theme.gd` + `ui/theme/vajb_theme.tres` — 9 `Tokens/armory_*` (+ 3 recovered `rarity_*`), regenerated.
- `tests/test_s20_chrome_unify.gd`, `tests/probe_s20_capture.gd/.tscn` — new.
- `tests/test_d7_armory.gd`, `tests/test_s15_armory_layout.gd`, `tests/test_s11_inspector.gd` — the moved/gained rows.
- `docs/design/ASSET_CATALOG.md` — unwired-entry note. `UI_SPEC.md` / `STATION_HUB.md` untouched (Amendment 4 already carries the approved text).

## Follow-ups

| Item | Kind | Where |
|---|---|---|
| Drop the retired `ui_armory_console` ext_resource + `texture` line from the pane scene | cleanup | `vajb-orbit/ui/station/armory_panel.tscn` (outside this worker's file set) |
| Resting card-chip ink 2.70:1 (`text_dim` on `chip_bg`) + the row pinning the override removal | contrast | `ui/station/armory_panel.gd:_style_danger`, `tests/test_d7_armory.gd:610-615` |
