# D8-H3 report — the 1080p glyph floor sweep (wave D8 item 10)

**Files:** `ui/hud/hud.gd`, `ui/hud/cockpit_style.gd`, `ui/hud/ship_status_screen.gd`, `tests/test_d8_hud_visibility.gd` | **Gate:** `[SUMMARY] passed=859 failed=0`

Measured with `tools/d8_glyph_audit.gd` (its own scene, scratch store) before and after; caps are rendered ink / OS/2 table (Rajdhani sCapHeight 643/1000, Oxanium 690/1000), floor 12 px at 1920x1080.

## Offenders found and fixed — before/after pixel measurements

| row (count) | size source | before | after |
|---|---|---|---|
| weapon-cell slot ordinals `WeaponGrid/*/Number` (7; on the D7-retired `AmmoPanel`, swept for the documented un-hide reversal) | theme `SlotNumber` 10 px -> `hud.gd` `SLOT_NUMBER_FONT_SIZE` 20 px per-node (`_apply_slot_font_floor`, hud.gd:973) | 6.00 / 6.43 | 13.00 / 12.86 |
| status caption + module rows (`Center/Body/SlotCaption`, `ModuleRows/Row*`) | `cockpit_style.gd` `status_row_font_size` 13 -> 20 | 9.00 / 8.36 | 13.00 / 12.86 |
| status W refs (`Ref*`, dynamic) | `cockpit_style.gd` `status_ref_font_size` 10 -> 20 | 6.00 / 6.43 | 13.00 / 12.86 |

TextureRects: no offenders - every HUD glyph ink measured >= 12 px (min 13.0 px, the `HudHullBar`/`HudShieldBar` cap strips; row 7 keeps them measured). `status_title_font_size` 20 (cap 14) was already clear and is untouched.

## Attributed, never fixed — the rule-5 cockpit (bucket 2: owner pin "the cockpit is display-only and stays as it is"; SLICE "Out of scope"; its rack ordinals are S15's)

| row (count) | source | measured |
|---|---|---|
| `CockpitCluster/BatteryLamps/Lamp1..5` (B1..B5) | `lamp_font_size` 11 | 8.00 / 7.07 |
| `ValueDials/fuel|enrg/Name` | `dial_label_font_size` 12 | 8.00 / 7.72 |
| `ReadoutRows/spd|hull|shld|ammo/Label` | `label_font_size` 11 | 8.00 / 7.07 |

## How the fixes land (sizing only; no variation, colour or layout touched)

Every fix is at its source (two style constants, one HUD constant); the per-node overrides apply `base x ui_scale` and re-apply on `SettingsManager.setting_changed` (`hud.gd::_connect_ui_scale_watch` -> `_apply_slot_font_floor` + `ShipStatusScreen.apply_font_floor`), so none can escape `ui_scale` (D12-A0's lesson). The ui_scale follow is a code reading - measuring it needs a settings write, which is barred. Reversal for all three: 10 / 13 / 10.

## Gate (own XDG_DATA_HOME scratch store, bounded)

`XDG_DATA_HOME=<scratch> $GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200` -> `[SUMMARY] passed=859 failed=0` (858 + row 7; only `test_d8_hud_visibility` grew)

## Test row and deviations

- Row 7 (`test_every_hud_label_and_texture_clears_the_12_px_floor`) is append-only, table-driven (`FONT_FLOOR_TABLE`): every Label and textured TextureRect in the HUD tree resolves one table row (first match wins), so no text/glyph row exists without a floor decision; the dynamic W refs are guarded at their source constant by a probe. Rows 1-6 pre-grepped and untouched.
- (bucket 1 note) `test_d7_status.gd:393-394` messages read "10 px" and are now stale wording - the assertions read `style.status_ref_font_size` / the variation name and stay green (suites untouched).
- (pre-existing, H1's finding) `test_weapon_fx_f4.gd:178` SCRIPT ERROR (freed-instance call) remains; its row passes.
