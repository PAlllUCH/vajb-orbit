# Wave Slice 2.5 — Feel (speed fantasy, damage states, thruster feedback) — task brief

Law, in order: `AGENTS.md`, `docs/CONTRACTS.md` (§4 PlayerShip, §7 HUD, §9 gate,
§8.1/§8.2 for the slice-0/2 pins this wave reads and must not move),
`docs/gameplay/18_engine_spec.md` **§3.4** (speed fantasy, owner-locked — cite,
never edit), `docs/design/FX_SPEC.md` **§1.3** (engine trail + its 2026-09-21
numbers), **§5** (blur / camera pull-back / dust), **§6** (damage states),
**§7.1** (the engine-side rows) and **§7.3** (the wiring contract),
`docs/design/AUDIO_SPEC.md` **§4.5** (held state beds + the thruster curve),
then this brief, then `.agents/gen/WAVEBOARD.md`.

Owner request this wave executes (2026-09-21): *"ship while traveling has to make
sounds (thrusters depending on speed) and thrusters should create flame fx."*

## 1. What slice 2.5 is, and what is left of it

`18_engine_spec.md` §14 defines slice 2.5 as "the speed fantasy and damage states
on top of slice 2's signals — **no new gameplay systems; every number already in
§13**". The weapon-FX wave (closed 2026-09-21, commit `09d4ca5`, gate 236 → 277)
already landed the **damage half**: the explosion, secondary, arc, shield-break,
ripple and plume sheets are wired through `game/projectile.gd`'s `FEEDBACK` table
and `game/fx.gd`'s helpers, and the low-hull smoke plume already spawns on both
`player_ship.gd` and `npc_ship.gd`. **Do not rebuild any of that.**

What remains, all presentation, no gameplay number anywhere:

| # | Deliverable | Law |
|---|---|---|
| 1 | Directional **motion blur** — screen-space `ColorRect` + `canvas_item` shader on its own `CanvasLayer` | FX_SPEC §5 row 1 |
| 2 | **Camera pull-back** — `zoom` multiplied by `lerp(1.0, 0.82, (ratio − 0.7) / 0.3)`, stacking with the wheel zoom | FX_SPEC §5 row 2 |
| 3 | **Dust streaks** — `GPUParticles2D` on the camera, `fx_dust_streak.png` | FX_SPEC §5 row 3 |
| 4 | **Hull-critical vignette** — `fx_hull_critical_vignette.png`, alpha 0.6→1.0 @ 1.2 s sine, hull < 25 % | FX_SPEC §6 row 1 |
| 5 | **Low-hull electrical arcs** — intermittent `fx_arc_spark.png` while hull < 25 % | FX_SPEC §6 row 3 |
| 6 | **Thruster trail** — one emitter per engine cell, `fx_engine_trail.png`, all keyed to `speed_ratio` | FX_SPEC §1.3 (numbers table) + §7.1 |
| 7 | **Thruster bed** — `sfx_ship_engine_01` held while thrusting/drifting, pitch and volume by ratio, with hysteresis | AUDIO_SPEC §4.5 |
| 8 | **Boost cue** — `sfx_ship_boost_01` one-shot on booster activation | AUDIO_SPEC §4.5 last paragraph |
| 9 | **Dash charge FX** — `fx_dash_charge.png` on that same activation | FX_SPEC §7.1 row "Dash charge" |

## 2. What is already measured (do not re-discover, do not duplicate)

Read on 2026-09-21 before this brief was written:

- **Gate: `passed=277 failed=0`** (the FX wave's close). Measure yours; grow it,
  never shrink it. **No existing test moves** — this wave only adds.
- `game/fx.gd` (163 lines, `class_name Fx`) is the FX library:
  `additive_material()`, `frame()`, `sheet_frames()`, `texture_frames()`,
  `scale_for(source_size, world_length)`, `play_once()`, `display()`,
  `fade_and_free()`. Reuse it; do not grow a second FX helper file.
- `game/projectile.gd`'s `FEEDBACK` table already carries `explosion`,
  `secondary`, `arc`, `shield_break`, `ripple`, `plume` with their regions,
  `source` sizes, `world` lengths and fps, plus `spawn_sheet`, `spawn_shield_break`,
  `spawn_shield_ripple`, `spawn_smoke_plume`, `clear_smoke_plume`, `_fx_parent()`.
  A new effect is a **table row** (one is owed for the dash charge), not a new
  spawn path.
- `game/player_ship.gd:875` and `game/npc_ship.gd:366` already call
  `spawn_smoke_plume`/`clear_smoke_plume` on the low-hull threshold. The arcs are
  the delta, in the same place.
- `autoload/audio_manager.gd` holds **per-bed loop voices** (the FX wave's F4):
  `play_loop(cue, fade)`, `stop_loop(fade, cue)`, `stop_bed`, `current_loop()`,
  `sounding_loops()`, `LOOP_VOICE_COUNT` **3**, `LOOP_LEASE` 1.2 s,
  `LOOP_PRIORITY` `{sfx_impact_shield_loop: 2, sfx_mining_beam: 1}` with
  `LOOP_PRIORITY_DEFAULT` 1, plus `play_pool(cue, take)`, `play_sfx`,
  `set_bus_linear`. A held bed is re-asked every frame it is held.
- `game/game.gd` already computes the wave's single input every frame:
  `_push_speedometer()` does `ratio = clampf(velocity.length() / _stats.max_speed, 0, 1)`
  and hands it to the HUD. `$Camera` is a `Camera2D`; `_camera_zoom` is the wheel
  target and `_set_camera_zoom()` tweens `_camera.zoom` **directly** to it
  (`CAMERA_ZOOM_MIN` 0.70, `MAX` 1.50, `STEP` 0.10, `SECONDS` 0.18) — the
  pull-back must compose with that, not fight it.
- `game/player_ship.gd` exposes `velocity()`, `_max_speed()` (× `_boost_multiplier()`),
  `_velocity_along_heading()`, `_thrust_locked()`, `_boost_remaining`,
  `_boost_cooldown`, `_update_boosters(delta)`, and reads the throttle in
  `_physics_process`. The hull is a `Sprite2D` named `Hull` (scale 0.0663) over a
  `HullBody` `RigidBody2D`; `_guns` and `_laser` are mounted by guarded path, the
  same idiom a thruster emitter parent should use.
- **Unconsumed assets this wave exists to wire:** `fx_engine_trail.png`,
  `fx_dust_streak.png`, `fx_dash_charge.png`, `fx_hull_critical_vignette.png`
  (zero code/scene references today), `sfx_ship_engine_01.ogg` /
  `sfx_ship_engine_02_loop.ogg` (both import `loop=true`), `sfx_ship_boost_01.ogg`
  (`loop=false`). **No new asset and no regeneration is owed.**

## 3. The pinned seams (so the two halves cannot collide)

1. **One input, one owner.** `game.gd` keeps computing `speed_ratio` where it
   already does and pushes it to the new effects node and the thruster driver.
   Nothing recomputes `|v| / v_max` elsewhere.
2. **One node for the screen-space stack.** New file
   `vajb-orbit/game/speed_fantasy.gd` (a `Node`), instantiated once in
   `game.tscn`, owns the blur `CanvasLayer` + `ColorRect` + shader, the dust
   emitter, the vignette overlay **and** the camera's applied zoom. `game.gd`
   calls one method on it per frame (name it `set_ratio(ratio: float, velocity:
   Vector2)` and add a read-back `ratio()` for probes).
3. **The wheel keeps its target.** `_set_camera_zoom()` still clamps and tweens
   `_camera_zoom`; the applied value becomes `_camera_zoom * pullback(ratio)`
   (`pullback` = 1.0 below the 0.70 onset). The wheel tween must not be
   invalidated by the pull-back, and the pull-back must not be written back into
   `_camera_zoom`.
4. **Thruster anchors are a seam, not a hardcode.**
   `player_ship.gd` gains `thruster_anchors() -> Array[Vector2]` returning
   hull-local points. **Today it returns one tail point** behind the hull's
   centre (`Vector2(-hull_half_width * 0.55, 0)`); when wave **P2-A** lands
   `ShipFit.mount_offset(hull_id, &"engines", i)` it returns one point per engine
   cell and nothing else changes. One emitter per anchor.
5. **The bed's driver is the ship, its numbers are the audio manager's.**
   `player_ship.gd` (or `game.gd`, one owner only — pick one and say which in the
   report) asks for the bed each frame while held and calls the stop when
   released; the pitch/volume/hysteresis constants live beside the other loop
   constants in `autoload/audio_manager.gd` (`LOOP_PRIORITY` gains the thruster
   row at **1**). A bed nobody re-asks is released by the lease; a stopped bed
   must be stopped **by cue** (`stop_loop(fade, cue)`) so it cannot take the
   shield hum down with it.
6. **Booster activation is the one trigger for #8 and #9** — the afterburner's
   own activation. `b_fold`'s movement is slice 4's, so its charge waits with it
   (FX_SPEC §7.1 says so; do not invent fold behaviour).
7. **No gameplay number moves.** Not a damage value, a cadence, a range, an
   energy or fuel rate, a mass, a speed, or a §13 row. This wave adds draw calls
   and audio voices, nothing else.

## 4. Worker table

| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| **S1** | coder — the whole slice (the FX lane's own worker) | `vajb-orbit/game/game.gd,vajb-orbit/game/game.tscn,vajb-orbit/game/speed_fantasy.gd,vajb-orbit/game/speed_blur.gdshader,vajb-orbit/game/player_ship.gd,vajb-orbit/game/player_ship.tscn,vajb-orbit/game/projectile.gd,vajb-orbit/game/fx.gd,vajb-orbit/autoload/audio_manager.gd,vajb-orbit/tests/` | Deliverables 1–9 of §1 exactly as specced, reusing `Fx` and the `FEEDBACK` table (one new row for the dash charge), with a test per deliverable and one deterministic probe. The probe measures, with raw numbers: blur strength at ratio 0.0/0.5/0.9/1.0 and zero below onset; applied zoom at those ratios with the wheel at 1.0 and at 1.30 (proving the composition); dust emission on/off by ratio; vignette alpha and its pulse over one period at hull 20 % vs 30 %; arc count over 6 s at hull 20 %; trail particle count/scale/alpha at ratio 0.15 and 1.0; the bed's sounding state, pitch and volume at those ratios plus the 0.15/0.10 hysteresis; the boost cue and dash-charge spawn on one activation. |
| **S2** | coder — reviewer (**mandatory**) | `vajb-orbit/tests/,vajb-orbit/tools/` | Re-runs S1's probe byte-identically and re-measures every number itself; checks each of the nine deliverables against FX_SPEC §1.3/§5/§6/§7.1/§7.3 and AUDIO_SPEC §4.5 rather than against the report; greps CONTRACTS §4/§7/§8.1/§8.2 for drift and confirms **no §13 row, damage, cadence, range or energy value moved**; confirms the wheel zoom still tweens and clamps as before; confirms the thruster bed cannot stop another bed and that three beds sound at once; tiers HIGH/MED/LOW with a reproducing command and raw output each. LOW → `.agents/gen/LOW_BACKLOG.md`. |
| **S3** | coder — fixer | per-finding sets from S2's report | Only S2's HIGH/MED findings, one pass, each re-measured before and after with S2's own command; gate green and grown. |

Run order: **S1 → S2 → S3 (only if S2 leaves HIGH or MED)**.

## 5. Hard rules

- `VAJB_WORKER_FILES` exactly as tabled; the PreToolUse hook denies writes outside
  it (and denies absolute paths on this host — use workspace-relative paths).
- Bounded Godot runs only (`--quit-after N`, stdout to a log the worker reads).
  Probe hygiene (L17): a probe that repoints `PlayerProfile.save_path` must
  stop/flush the 0.5 s debounce before restoring it.
- The gate is `godot --headless --path vajb-orbit res://tests/headless_runner.tscn
  --quit-after 1200`, measured at **277** before this wave.
- No `assets/**`, no theme, no `project.godot`, no `addons/**`, no `docs/**`;
  `18_engine_spec.md` is owner-locked and nobody edits it.
- A load failing only on a missing sprite/texture path is *environment-deferred*,
  not a finding.
- **No invented numbers.** Every value this wave uses is in FX_SPEC §1.3/§5/§6/§7.1
  or AUDIO_SPEC §4.5; the rows marked *proposed* there are the owner's to tune, and
  a worker who believes one is wrong says so in the report and leaves it.

## 6. Staged, not in this wave

- **Fold/dash (`b_fold`) movement and its charge** — slice 4's.
- **NPC thrusters** — the trail and bed are the player's hull only in this wave;
  NPC hulls have no engine grid, so their flame is a later row.
- **Per-engine-cell flames** — the anchor seam (#4) ships now, the per-cell list
  arrives with P2-A's `mount_offset`.
- **The `weapon_6`/`weapon_7` input-map extension** — an owner `project.godot`
  pass, unrelated to this wave.

## 7. Owner ticks (block nothing)

1. Which engine bed is the thruster's: `sfx_ship_engine_01` (pinned default) or
   `sfx_ship_engine_02_loop` (the alternative take) — AUDIO_SPEC §4.5, one constant.
2. The *proposed* rows: trail 20–60/s, 24–56 u, alpha 0.35–0.85; dust 30/s, 0.5 s,
   12 u; arcs one per 1.6–2.6 s; dash charge 32 u, 0.2 s; bed pitch 0.85–1.15,
   volume −24→−12 dB, hysteresis 0.15/0.10.
3. Blur strength 0.1 → 0.8 and the camera pull-back 1.0 → 0.82 (FX_SPEC §5, engine
   spec §3.4 — already specced, listed for completeness).

## 8. Close-out (orchestrator)

Gate re-run (record the measured count); `python3 staging/verify_wave.py verify
--baseline slice2_5_start --forbidden project.godot --expect-reports
<the wave's reports> --tests`; `.agents/gen/WAVEBOARD.md` updated (slice 2.5 Done,
its report paths, the owner ticks above, **P2-A unblocked and next**);
wave-boundary commit; report to the owner with the measured gate count, the
per-deliverable numbers S1 published, and S2's findings by tier.
**Snapshot + commit before the first dispatch**, per the standing wave rule.
