---
slice: D11
worker: D11-C1 (run in-session by the owner's order "do the wiring yourself")
model: n/a (orchestrator-direct)
status: complete
gate: "812/0 x2, byte-identical, scratch stores; the +5 rows are test_d11_station"
---

# D11-C1 report — the composed station wiring

## Result
`game/station_scene.gd` (new) + `game/sector.gd:_spawn_station` swap +
`tests/test_d11_station.gd` (new, 5 rows) are done; gate **812/0 twice** (753 +
S8/S11's live-lane rows + this suite's 5). `tests/` pre-grep disposition: **no
row pins the old sprite** (`STATION_SCALE|env_station|StationTexture|&"station"`
= 0 hits in `vajb-orbit/tests/`) — nothing to ratify, S6 dock/blip rows stay
green untouched and are re-probed by this suite.

## The swap (invariants measured)
- `sector.gd:_spawn_station` builds `StationScene`, names it `Station`, places
  it at `centre`, and `setup()` joins `&"station"` — probe: group survives,
  `station_position() == centre` unchanged.
- DockZone unchanged: **sibling** of the scene, `CircleShape2D.radius == 120.0`
  in world units, `global_scale == (1,1)` (never under art scale) — probe
  asserts each; `dock_zone_contains` answers 119 u in / 121 u out as before.
- S6 seams byte-identical: `blips()` = one `friendly` row at the centre.
- Preloads are **function-local** in `_spawn_station` so `probe_g3_shadow`'s
  pinned line map on sector.gd never shifts (its rows pass).

## The scene (A0's approved geometry, hero-relative u)
Hero at `HERO_SCALE 0.1459` (= 0.0663 x 2.2, frame 298.8 u); 11 static
instances (arm/mast/gantry/window/plate/lamp kinds) at the sheet's positions;
moving kinds in `_process` via `step_motion`, **no Timer nodes**: strobe chase
5 dots (55 u spacing, `STROBE_PERIOD 1.2`), 2 shuttles on the 1865.5 u loop
(`SHUTTLE_SPEED 30.0`), crane slew ±60° (`SLEW_RATE 4.0`). Each motion rule is
a pure static taking its constant; **reversal (≤ 0) = the element stands
still** — proven by `test_reversal_valued_constants_stand_still`.

## AC map
AC1 ✅ (approved sheet is the baseline; A1 already shipped against it) ·
AC2 ✅ (A1's report) · AC3 ✅ `test_station_draws_composed_not_one_sprite`,
`test_spawn_swap_keeps_centre_group_and_dock_radius`,
`test_s6_dock_and_blip_seams_still_answer` ·
AC4 ✅ `test_motion_two_frames_under_the_constants` + the reversal row ·
AC5 ✅ diff = `_spawn_station` + the two new files only · AC6 ✅ 812/0 x2.

## Deviation from the pinned interface (report, bucket 2 — R1 re-measures)
The brief pins `class_name StationScene extends Node2D`. The **class_name
registration is dropped** (file still `game/station_scene.gd`, same API):
four pre-existing suites hold `const StationScene := preload("res://ui/
screens/station.tscn")` (`test_s3_auction.gd:29`, `test_p2b_fitting_panel.gd:30`,
`test_s11_describe.gd:20`, `test_s11_inspector.gd:23` — the last two are the
**live S11 lane's**, untouchable), and the registration made
`test_p2a_lint_shadow` fail 811/1 ("a constant may not share a global class's
name"). Renaming the consts = editing locked/parallel files; renaming the class
= a bigger pin move. Project convention ("never depend on the global class
table") already reaches scripts by path, which is how both sector.gd and the
suite load it. Reversal: restore `class_name StationScene` after the four consts
are renamed upstream.

## Files touched
- `vajb-orbit/game/station_scene.gd` — new (scene + placement table + motion).
- `vajb-orbit/game/sector.gd` — `_spawn_station` body + `_station` typed
  `Node2D` (was `Sprite2D`); `StationTexture`/`STATION_SCALE` consts kept as
  the documented reversal anchors (now unused by the spawn path).
- `vajb-orbit/tests/test_d11_station.gd` — new, 5 rows.

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| class_name deviation ratify/reverse | owner tick or R1 | this report |
| A1's ring A/B (r=120 vs 175) | owner tick | A0 report §Proposed pins |
| R1 re-measurement of AC1–AC7 | next in run order | D11-R1_review.md |
