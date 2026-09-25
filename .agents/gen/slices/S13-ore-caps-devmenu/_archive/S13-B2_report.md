---
slice: S13
worker: S13-B2
model: "deepseek-flash"
status: informational
gate: "826/0 → 834/0"
---

# S13-B2 report

## Result
The F1 dev overlay ships: `ui/dev/dev_tuning_menu.gd` (+ `.tscn`), a
`CanvasLayer` toggled by the raw `KEY_F1` keycode, with 13 sliders covering every
`OreTuning` field, live apply + a printed value per row, a TUNED badge, and
Save/Reset over `user://dev_tuning.cfg`. `tests/test_s13_devmenu.gd` proves all of
it through the real input pipeline and the real widgets (8/8). Gate
**826/0 → 834/0**, twice on fresh scratch stores, and **834/0** on a store that
carries a divergent `dev_tuning.cfg` at boot (AC4). No `project.godot`, no
`docs/`, no `game/` write.

## Control table
| Control | Key | Range (step) | Writes |
|---|---|---|---|
| F1 (raw keycode) | `KEY_F1` / `physical_keycode` | toggle | `visible` |
| gun_burst_share | `&"gun_burst_share"` | 0..1 (0.01) | `OreTuning.gun_burst_share` |
| fragment_core_share | `&"fragment_core_share"` | 0..1 (0.01) | `OreTuning.fragment_core_share` |
| gun_chip_rate | `&"gun_chip_rate"` | 0..0.5 (0.005) | `OreTuning.gun_chip_rate` |
| mine_cycle | `&"mine_cycle"` | 0.2..3.0 (0.05) | `OreTuning.mine_cycle` |
| work_per_unit | `&"work_per_unit"` | 0.25..4.0 (0.05) | `OreTuning.work_per_unit` |
| tier 1..4 yield | `&"tier_base_yield_1"`..`_4` | 1..12 (1, int) | `tier_base_yield[tier]` |
| yield_variance_min | `&"yield_variance_min"` | 0..2 (0.01) | `OreTuning.yield_variance_min` |
| yield_variance_max | `&"yield_variance_max"` | 0..2 (0.01) | `OreTuning.yield_variance_max` |
| pickup x | `&"pickup_burst_x"` | 0..6 (1, int) | `pickup_burst.x` |
| pickup y | `&"pickup_burst_y"` | 0..6 (1, int) | `pickup_burst.y` |
| TUNED badge | — | — | visible while any field != default |
| Save button | `SaveButton` | — | writes `user://dev_tuning.cfg` |
| Reset button | `ResetButton` | — | `reset_to_defaults()` + deletes the file |

Every row prints its value (`"%d"` for int fields, `"%.3f"` otherwise), updated
on each `value_changed`.

## Per-AC proof
- **AC4 — toggle.** `_unhandled_key_input` checks `key.pressed`, ignores `echo`,
  and matches `keycode`/`physical_keycode` against `KEY_F1`; no InputMap action
  and no `project.godot` line exists (git diff empty). `test_f1_toggles_the_overlay`
  drives `Input.parse_input_event` through the `SceneTree` and sees closed → open
  → closed; it also asserts `tree.paused == false` and
  `process_mode == PROCESS_MODE_ALWAYS` (never pauses the game).
- **AC4 — live apply.** `test_sliders_write_every_live_field` sets all 13 sliders
  and reads every `OreTuning` field back; `test_sliders_are_bounded_to_the_pinned_ranges`
  checks each min/max against the pinned spec.
- **AC4 — Save/Reset.** `save()` writes `ConfigFile` `[ore_tuning] values=<to_dict()>`;
  `reset()` calls `reset_to_defaults()` and deletes the file.
  `test_save_and_reset_buttons_are_wired` presses the real `SaveButton`/`ResetButton`
  (S8's L170), asserts the file appears then disappears and the fields return.
- **AC4 — open-only read / hermeticity.** `open()` is the only caller of
  `load_from_disk()`; `_ready()` builds widgets and syncs the current values but
  never touches the file. `test_config_is_never_read_at_boot` writes a divergent
  config (gun 0.9, reserve 0.8), mounts a fresh overlay and proves the default
  signature (`extractable(7)/reserve(7)/gun`) is unchanged and the badge is off,
  then proves `open()` alone applies 0.9. `test_save_then_open_round_trips` proves
  the same via close → reset → open.
- **AC4 — TUNED badge.** `is_tuned()` compares the live `to_dict()` against the
  defaults `OreTuning` itself produces; `test_tuned_badge_tracks_the_fields`
  asserts hidden at default and shown after any of the three field families moves.
- **AC4 — gate byte-identical.** The whole gate runs on a store that carries the
  divergent config at boot: `[SUMMARY] passed=834 failed=0` and a byte-identical
  sorted PASS set against the fresh store (only pre-existing frame-timing print
  lines differ between any two runs).

## Deviations
1. **Nothing shipped mounts the overlay.** B2's file set is `ui/dev/` + the test,
   so `dev_tuning_menu.tscn` is a standalone scene the owner can add as a child in
   the editor (or a later wave mounts it); no `project.godot`/autoload/shipped UI
   edit was in scope. Reversal: a follow-up ticket wires a mount point.
2. **TUNED detection types no default.** `_defaults_snapshot` snapshots the live
   values, calls `reset_to_defaults()`, captures the result, then restores the
   snapshot, so no published number is retyped in `ui/dev/` (hard rule 4). Cached
   once. Reversal: add a `defaults()` accessor to `game/ore_tuning.gd` (bucket 2).
3. **`config_path` is a `var` (default the pinned path).** The test uses the pinned
   default; the handle only lets a future harness redirect the file. Reversal: make
   it a `const`.
4. **The panel is unthemed** (engine default + one `StyleBoxFlat`) so a headless
   mount has no `Router`/theme dependency. Reversal: `theme = Router.live_theme()`.

## Evidence
```
gate before  /tmp/s13_b2_gate_before : [SUMMARY] passed=826 failed=0
gate after   /tmp/s13_b2_gate_after2 : [SUMMARY] passed=834 failed=0  (fresh store)
gate after   /tmp/s13_b2_gate_after3 : [SUMMARY] passed=834 failed=0  (fresh store)
gate carry   /tmp/s13_b2_gate_carry  : [SUMMARY] passed=834 failed=0  (store carries
  a divergent user://dev_tuning.cfg at boot; sorted PASS sets identical)
suite alone  /tmp/s13_b2_suite_only  : [SUMMARY] passed=8 failed=0
  (test_config_is_never_read_at_boot, test_f1_toggles_the_overlay,
   test_reset_restores_defaults_and_removes_the_file,
   test_save_and_reset_buttons_are_wired, test_save_then_open_round_trips,
   test_sliders_are_bounded_to_the_pinned_ranges,
   test_sliders_write_every_live_field, test_tuned_badge_tracks_the_fields)
```
Runs: `XDG_DATA_HOME=<scratch> godot --headless --path "$VAJB_PROJ"
res://tests/headless_runner.tscn --quit-after 1800` (suite filter `-- --suite=test_s13_devmenu`).

## Files touched
- new `ui/dev/dev_tuning_menu.gd` — the overlay (built in code, no shipped UI file)
- new `ui/dev/dev_tuning_menu.tscn` — the CanvasLayer scene (script attached)
- new `tests/test_s13_devmenu.gd` — 8 rows, AC4
- untracked `.uid` sidecars for the two new `.gd` files

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| No shipped file mounts the overlay in-game | LOW | `ui/dev/dev_tuning_menu.tscn` (owner wires) |
| `pickup_burst` is a live slider with no live reader under the credit rule (carried from B1) | LOW | `game/ore_tuning.gd`, `game/asteroid_field.gd:_pay_burst` |
