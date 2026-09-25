# D8-H1 report — the top-left block (wave D8 item 10)

**Files:** `ui/hud/hud.tscn`, `ui/hud/hud.gd`, `tests/test_d8_hud_visibility.gd` | **Gate:** `[SUMMARY] passed=854 failed=1`

## What is shown

- `CanvasLayer/TopLeft/Blocks` at the 12 px screen margin in the theme's existing chrome (`HudReadout` rows over the `HudHullBar`/`HudShieldBar` 260 x 14 bars): **HullBlock** and **ShieldBlock**, the scene's own section 3.1 blocks, un-hidden (`_retire_old_column` no longer lists them; `retired_widgets()` answers the 3 still-retired: ammo panel + cargo toggle/panel).
- Measured at 1920 x 1080 (test row 1): `Blocks` non-zero (the QA's `0x0`), HullBlock at (12, 12), both blocks visible in tree inside the top-left quadrant.
- Nothing invented: the uncommitted prototype `StateBlock` is dropped for the blocks the QA names; its SPD/TARGET/THREAT rows mirrored state that stays on the cluster's SPD row and the top-right target window (row 3 proves each still writes).
- Energy/Fuel keep section 3.1b's pool-block retirement (owner 2026-09-24): the cluster's FUEL/ENRG dials remain their readout, booked from the same `set_pool` call (row 2).

## Wiring source (same frame by construction)

`PlayerState.hull_changed`/`shield_changed` -> `_on_hull_changed`/`_on_shield_changed` -> `_refresh_hull`/`_refresh_shield` write the block rows **and** `_cockpit.set_hull`/`set_shield` write the cluster rows in the same call. Row 2 pushes 640/1000 + 120/300, asserts each block's value equals the cluster's `readouts()` in that frame, and a second feed (250) moves both together.

## Gate line

`XDG_DATA_HOME=<scratch> godot --headless --path <proj> res://tests/headless_runner.tscn --quit-after 1200` -> `[SUMMARY] passed=854 failed=1` (own scratch store, bounded).

## Findings (bucket 2 — the tests-that-moves list is a pin)

- The 1 failure is the stale pin `test_d7_cockpit.gd:391` (`test_the_old_hud_column_is_gone_from_the_flight_hud`): `retired_widgets()` asserted 5 all-hidden, i.e. `hull_vis=false` — the exact condition the QA row names as the defect and the task reverses. Left untouched (outside the file set); fix at the fixer/developer session: expect the 3 still-retired widgets (5 -> 3), under the brief's "unless the QA row names it" escape.
- Unrelated pre-existing noise: `SCRIPT ERROR` at `test_weapon_fx_f4.gd:178` (freed-instance call in the beam-cadence row; outside `ui/hud/`, its row passes). The tree also carried the stalled B1 run's wave work (minimap legend, zoom marks, `HudReadout` swaps), kept for the H2/H3 lanes.
