# F1 report — fire and travel feedback (weapon FX & audio wave, 2026-09-21)

Brief: `.agents/gen/weapon_fx_wave_task.md` (worker F1, `VAJB_WORKER_FILES` =
`game/weapons.gd`, `game/projectile.gd`, `game/mining_laser.gd`,
`autoload/audio_manager.gd`, `game/fx.gd`, `tests/`). Nothing under `assets/`, the
theme, `project.godot`, `addons/` or `docs/` was touched; no damage, cadence, range,
Energy or ammo number was moved.

Evidence: `.agents/gen/weapon_fx_f1_probe.txt` (a real `game.tscn` run, one family per
line, headless and self-quitting) and the gate (`passed=258 failed=0`, measured at
`passed=236 failed=0` before this wave, so +22 tests, none removed). Probe command:

```
~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_f1_weapon_fx.tscn --quit-after 600
```

## Owner rulings with a row per family

| Ruling | What carries it |
|---|---|
| Fire must sound like fire | `weapons.gd:_on_shot_fired` (hung off `shot_fired`) → `_play_fire_cue` |
| Fire must look like fire | `weapons.gd:_spawn_muzzle_flash` + the instant families' `_draw_beam` |
| Hits must read | F2's file set (untouched here); `fx.gd` is the shared seam it reuses |

## Asset + cue per event

| Event | Asset (shipped path) | Region / size | Cue (AUDIO_SPEC) |
|---|---|---|---|
| Cannon shot (kind `bolt`) | `res://assets/fx/fx_laser_bolt.png` | `Rect2(194, 604, 1718, 105)` (the sheet's thin object), 64 units long | `sfx_weapon_cannon` → take `sfx_weapon_cannon_01` (S2 tier 1) |
| Railgun shot (kind `slug`) | `res://assets/fx/fx_laser_bolt.png` | `Rect2(232, 1189, 1680, 178)` (the thick object), 96 units | `sfx_weapon_cannon` → take `sfx_weapon_cannon_02_medium` (S2 tier 2) |
| Rocket (kind `rocket`, homing) | `res://assets/fx/fx_missile_trail.png` | four frames `(79,960,243,61) (490,911,374,109) (906,941,535,72) (1670,982,109,17)`, widest 48 units, 12 FPS, looping | `sfx_weapon_rocket` → `sfx_weapon_rocket_01` then `sfx_weapon_rocket_02_warhead` at +80 ms (S3) |
| Mine (kind `mine`) | `res://assets/fx/fx_ember_pulse.png` | `Rect2(811, 791, 423, 421)`, 22 units | none — AUDIO_SPEC §8 states no deployable cue (see open items) |
| Any released shot | `res://assets/fx/fx_muzzle_flash_f{1..4}.png` | 4 frames, 20 FPS, one-shot, `animation_finished → queue_free` | the family's cue above |
| Laser / plasma beam (instant) | engine-drawn `Line2D` `Beam` (width 5, halo) + `BeamCore` (width 2, core) | muzzle → the weapon's own reach | `sfx_weapon_laser` round-robin `_01.._04`, pitch ±10 %, −3..0 dB (S1) |
| Mining shaft | `game/mining_laser.gd`'s existing `Line2D` pair (unchanged) | unchanged | + `sfx_mining_beam` (S7 bed, looped) alongside the existing `sfx_mining_chip_01` (S8) |

Every fx sheet is composited **additively** (`CanvasItemMaterial.BLEND_MODE_ADD`),
which the probe prints per shot (`additive=true`) — the sheets are RGB on Void Black
per FX_SPEC §0, so an alpha wiring would have drawn a black box.

## What was added, by file

- **`game/fx.gd` (new).** The spawn-play-free seam: `additive_material()`,
  `frame()`, `sheet_frames()`, `texture_frames()`, `scale_for()`, `play_once()` (adds
  the node, plays it, frees it on `animation_finished`, returns null when there is
  nothing to draw with), `display()` (a single-frame additive sprite) and
  `fade_and_free()` (the engine-side lifetime FX_SPEC §1.5/§1.7 give a single frame).
  Callers own their own regions, so no geometry is duplicated and nothing is written
  back to `assets/`.
- **`game/projectile.gd`.** `SHEETS` (one row per kind: sheet, region(s), source size,
  world length, fps, loop), `_sync_visual()` / `_build_visual()` / `_face_travel()`, a
  `visual()` accessor and `VISUAL_NODE`. The sprite is built in code (the shot has no
  scene file) and turns with the shot's own bearing, so a homing rocket's exhaust
  swings with every turn.
- **`game/weapons.gd`.** `FIRE_CUES` (+ `fire_cue_of` / `fire_take_of`),
  `_on_shot_fired` connected to the component's own `shot_fired` from `setup` and
  `_ready`, `_spawn_muzzle_flash`, `_play_fire_cue`, `_audio`, and the engine-drawn
  beam (`_sync_beam` / `_draw_beam` / `_hide_beam` / `_make_beam`) built in code
  because the component itself is mounted in code. The beam is hidden on release, on
  a dry pull and when its reach is zero.
- **`autoload/audio_manager.gd`.** The cue-pool API the handoff §1.2 records as
  missing: `CUE_POOLS` (data), `has_pool`, `cue_pool`, `pool_takes`, `play_pool(cue,
  take := -1)` (round-robin or tier, the row's pitch/volume range, delayed layers on
  the pool's own timer, returns the plan it played), plus `play_loop` / `stop_loop` /
  `current_loop` (one dedicated voice, so a held loop cannot steal a one-shot) and the
  probe seams `cue_path()` and `last_sfx()`. `play_sfx` and `play_ui` are unchanged
  for every existing caller — and its voice now resets `pitch_scale`/`volume_db`
  before playing, so a pooled take's variation can never leak into the next
  `play_sfx`.
- **`game/mining_laser.gd`.** The S7 bed: `BEAM_LOOP_CUE` started by `_draw_beam()`
  (the shaft's own live frame) and stopped by `_extinguish()` and `_exit_tree()`, with
  a `_play_cue(cue, loop)` door so the bed and the chip transient cannot drift.
- **`tests/test_weapon_fx_f1.gd` (new, 22 tests).** One per wired event: the four
  kinds' sprites, the flash's sheet/rate/lifetime/placement, the beam's visibility and
  reach, the five families' cues, the pool's round-robin and ranges, the tiers, the
  +80 ms layer, the plain-cue fallback, the mining bed, and that every wired path
  resolves. Nothing awaits a frame (the gate's runner calls test methods synchronously).
- **`tests/probe_f1_weapon_fx.gd` + `.tscn` (new).** The measured evidence above.

## Pools added to `AudioManager` beyond F1's own

F2 cannot edit `audio_manager.gd` (its file set is `projectile/impact/player_ship/
npc_ship/asteroid/tests`), so the table also carries the rows F2's brief names:
`sfx_weapon_explosion` (`_01/_02`, round-robin), `sfx_impact_hull` (`_01.._05`),
`sfx_impact_shield_hit` (`_01.._09`), each with no pitch/volume spread because the
handoff states none for those rows. F2 needs only `play_pool(&"<cue>")`.

## Open items and proposals (nothing invented silently)

1. **The mine has no cue.** AUDIO_SPEC §8 lists S1/S2/S3 for weapons and nothing for
   the deployable family, so the mine draws its flash and stays silent; the probe
   shows the previous cue surviving the drop. A cue needs an owner ruling (and an
   asset), not a wiring guess.
2. **`sfx_weapon_laser_04.ogg` is a 1.244 s outlier in a 0.064–0.092 s pool**
   (ASSET_AUDIT C9, "reject as a pool member until trimmed"). The wave brief is
   explicit ("round-robin over takes 01 to 04"), so all four ship; if the owner wants
   the audit's call, it is one line: drop the last entry of
   `AudioManager.CUE_POOLS[&"sfx_weapon_laser"][&"takes"]`.
3. **The cannon's three takes are 3.46 s / 8.38 s / 17.97 s against a 0.6 s cadence.**
   Tier 1 (cannon) and tier 2 (railgun) are wired; tier 3 — the 18 s "long doomsday
   charge-up" — is reachable through `play_pool(&"sfx_weapon_cannon", 2)` but is
   assigned to no player family, because no shipped family is a charged shot.
   Overlapping tails are audible at this cadence; retrimming the takes is an audio-lane
   job.
4. **Sizes the spec does not state.** FX_SPEC §1.1 gives the bolt sheet its 64 px light
   and 96 px medium read (those are used verbatim); it gives no size for the trail and
   no row at all for the mine, so they read at 48 units (about a hull) and 22 units
   (a third of one), measured against the 43 px Vanguard side view. Both are single
   constants (`SHEETS[..][&"world"]`).
5. **The trail's 12 FPS and its loop** are not in any spec (FX_SPEC states 20 FPS for
   the flash/sparks and 15 FPS for the explosion only). It is one constant
   (`SHEETS[&"rocket"][&"fps"]`).
6. **The seeker's exhaust is the art's own smoke, so it reads dim**, and its four
   frames differ in size (22 px flare → 48 px dissipating smoke → 10 px wisp), i.e. the
   puff grows and fades. If it reads faint in play the fix is art (`fx_engine_trail.png`
   is the ember streak) or a larger `world`; both are the owner's call, not a wiring
   change.
7. **The muzzle is the component's own origin**, because that is where a shot already
   spawns (`projectile.gd`'s spawn point and the beam's launch point). The flash is
   therefore centred on the hull rather than on the nose; moving it forward would
   desynchronise it from the shot's own spawn point, which is a contract change.
8. **A fired shot's flash lives 0.2 s of real time** and the component holds it until
   then: at the shipped cadences (0.6 s cannon, 1.2 s rocket, once per beam hold) at
   most one flash is up per family. The probe's `flash=x6` is an artefact of the probe
   running no frames at all, not of play.
9. **Headless exit warnings.** Playback objects are reported leaked at exit
   (`20 ObjectDB instances` / `8 resources` for the full gate) because the dummy audio
   driver never mixes the streams. Measured as an engine artefact, not a wiring
   defect: a probe that plays exactly one cue through any route leaks
   `4 ObjectDB instances` on its own. The gate's own result (`passed=258 failed=0`) is
   unaffected. No production code pretends to cure it (an `_exit_tree` stop was tried
   and did not change the count, so it was removed).
10. **`Fx.fade_and_free()` is unused by F1** — it is the seam F2's single-frame
    effects (shield ripple §1.5, cargo pulse §1.7, arc spark) need, and F2 cannot edit
    `fx.gd`. If F2 does not use it, it is three lines to delete.
11. **Undrawn feedback left to the hit site (F2):** the impact cue per target kind, the
    explosion/secondary explosion, `fx_arc_spark`, `fx_shield_ripple`/`fx_shield_break`,
    `fx_smoke_plume` at low hull, and the *destruction* of a shot in flight (a rocket
    shot down still fizzles with no visual).
