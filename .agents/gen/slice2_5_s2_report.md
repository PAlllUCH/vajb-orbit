# S2 report — slice 2.5 (speed fantasy, damage states, thruster feedback), mandatory review
# (2026-09-21)

Worker: **S2**, the wave's mandatory reviewer. Authority: `.agents/gen/slice2_5_feel_wave_task.md`
(the nine deliverables of its §1, its §5 hard rules, its tiering rule), read with
`docs/design/FX_SPEC.md` §1.3 (the 2026-09-21 amendment), §5, §6, §7.1, §7.3,
`docs/design/AUDIO_SPEC.md` §4.5, `docs/gameplay/18_engine_spec.md` **§3.4** (owner-locked, cited
only), `docs/CONTRACTS.md` §4, §7, §8.1, §8.2, §9, and `.agents/gen/slice2_5_s1_report.md`.
File set: `vajb-orbit/tests/`, `vajb-orbit/tools/` (probes only; nothing shipped was edited).

**Verdict: the wave is NOT ready to close. Two HIGH findings block it — both of them mean the
deliverable does not do what its own spec row says.** Deliverable 7 (the owner's "ship while
traveling has to make sounds") holds a voice that never plays a stream: silent on a fresh voice,
and on a re-used voice it plays *the previous bed's file* at the thruster's pitch and level.
Deliverable 6's size table never reaches the screen: the streaks draw at the master's native
**1401 × 86 px** on a 1920 × 1080 frame because `GPUParticles2D.scale` is inert for the drawn
quad, so the flame is a screen-wide ember band instead of a 24–56 u streak. Everything else
measures exactly as S1 published — the gate is `passed=307 failed=0`, S1's probe replays
byte-identically, and no gameplay number moved. **One fixer pass (S3) is therefore owed, on
those two findings only.** No MED findings; six LOW findings ride to
`.agents/gen/LOW_BACKLOG.md` (L66–L72).

## 0. The gate I measured, and the replay of S1's evidence

```
$ ~/.local/bin/godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=307 failed=0        # exit 0, `.agents/gen/slice2_5_s2_gate.txt`
```

- 307 `[PASS]` lines, 0 failures, exit 0 — **S1's number, reproduced.** Per suite, summed from
  the log (`grep '^\[PASS\]' … | sed -E 's/^\[PASS\] ([^.]*)\.gd\..*/\1/' | sort | uniq -c`):
  `weapons 29 · npc 28 · weapon_fx_f1 22 · damage 20 · hud 19 · engine2_fixes 17 · pools 16 ·
  weapon_fx_f2 13 · slice2_5_feel 13 · p1_market 13 · wiring 13 · loot 13 · flight_feel_g1 12 ·
  p1_catalogues 11 · p1_profile 9 · cleaving 9 · ui_slot_layout 7 · combat_repair_c5 7 ·
  weapon_fx_f4 6 · p1_refinery 6 · p1_repairs 5 · p1_pricing 5 · flight_beam_g2 5 · p1_clock_log 4 ·
  engine_c3_flight_decay 3 · engine2_dock 2` = **307**.
- Against `CONTRACTS.md` §9's recorded pre-wave table (294, 26 suites): **every one of the 25
  other suites prints exactly its recorded count and `test_slice2_5_feel` (13) is the only
  addition.** `294 + 13 = 307`. No existing test moved.
- The green run still carries the one pre-existing `SCRIPT ERROR`
  (`Cannot call method 'call' on a previously freed instance.` at `tests/test_weapon_fx_f4.gd:176`,
  `LOW_BACKLOG` L61) and the same `28 ObjectDB instances were leaked` / `12 resources still in use`
  pair the weapon-FX wave's own report records for the 294 gate (`weapon_fx_f4_report.md` §"The
  exit warnings"); this wave adds no new line of either kind.

**S1's probe, re-run byte-identically** (`probe_s2_5_feel.tscn`, its own command, twice):

```
$ ~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_s2_5_feel.tscn --fixed-fps 60 --quit-after 900
$ grep '\[S25\]' <run> | md5sum
8ff3c8cb993a08b1c783d4da9f53cb26   # my run 1
8ff3c8cb993a08b1c783d4da9f53cb26   # my run 2
8ff3c8cb993a08b1c783d4da9f53cb26   # S1's stored .agents/gen/slice2_5_s1_probe.txt
$ diff <my 64 lines> <S1's 64 lines>   → no differences
```

64 `[S25]` lines, byte-identical three ways. S1's **pixel** probe also reproduces digit for digit
(`.agents/gen/slice2_5_s2_s1_pixels_rerun.txt` vs `.agents/gen/slice2_5_s1_pixels.txt` → no
differences: `lit_px` 1/11/15/19, `column_split_px` −1.278/−2.565, corner/centre means
0.1424/0.0323 and 0.0862/0.0197). Full transcript: `.agents/gen/slice2_5_s2_replay.txt`.

My own probe (`.agents/gen/slice2_5_s2_probe.txt`, 96 `[S2R]` lines) is **byte-identical across
two runs** (`md5 4a350b7c37b38673faafa43b9f7ce0ef` both), so every number quoted below is a
measurement rather than an example:

```
$ ~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_s2_5_review.tscn --fixed-fps 60 --quit-after 5400
```

Supporting probes, each with its own file: `probe_s2_5_voice.tscn` (the bed's voices),
`probe_s2_5_trail_draw.tscn` + `probe_s2_5_node_scale.tscn` (rendering, needs a display),
`probe_s2_5_review_pixels.tscn` (dust), `probe_s2_5_shot.tscn` (the shipped-scene stills).

## 1. The nine deliverables against the spec rows themselves

Measured mine, not read from S1's report. "✓" = the spec row is met; the two ✗ are §2's HIGH
findings.

| # | Deliverable | Spec row | My measurement | |
|---|---|---|---|---|
| 1 | Directional motion blur | FX_SPEC §5 row 1, §7.1 | `ColorRect` 1920×1080 with `speed_blur.gdshader` on its own `CanvasLayer` **layer 1**, above the world's 0 and below the HUD's 10 (`ui/hud/hud.tscn:37` = 10, the only other CanvasLayer in the tree). Strength `0.000000` at 0.0/0.5/0.69/**0.70**, `0.100233` at 0.7001, `0.123333` at 0.71, `0.450000` at 0.85, `0.566667` at 0.9, `0.800000` at 1.0 — each equal to my own `lerp(0.1, 0.8, (r−0.7)/0.3)` to 1e-6, and `visible=false` exactly where the strength is 0. `blur_direction` = the normalised velocity at every reading. Pixel-verified: a 1 px rule stays 1 px at strength 0 and smears to 11/15/19 px at 0.5667/0.8/1.0 (my re-run of S1's pixel probe). | ✓ |
| 2 | Camera pull-back | FX_SPEC §5 row 2, §3.4 | `wheel × 1.0/0.91/0.82` exactly at ratio 0/0.85/1.0 for wheel 0.70/1.00/1.30/1.50 — 20 readings, all `match=true`, largest float32 storage delta **4.8e-8**; the camera carries the applied value at every reading and `wheel_zoom()` never moves. Live: `_set_camera_zoom(2.0)` → target **1.5000**, `_set_camera_zoom(0.10)` → **0.7000**, a mid-tween sample of **1.143402** (strictly between 1.0 and 1.5 → the 0.18 s tween is live, not a snap), settled `target=1.500000 shown=1.500000 pushed=1.500000 camera=1.275000 = 1.5 × 0.85`, and a 10-cycle ratio sweep with the wheel fixed leaves `_camera_zoom` **unchanged**. | ✓ |
| 3 | Dust streaks | FX_SPEC §5 row 3, §7.3 | `GPUParticles2D` **child of the camera**, `fx_dust_streak.png`, `local_coords=false`, `amount=15`, `lifetime=0.50`, 12 u, `color.a=0.35`, **no `CanvasItemMaterial` (MIX, "never additively blown")**; `emitting/visible` **off at 0.0/0.5/0.69 and on at 0.70/0.71/1.0**; `rotation = −45.00°` for a (0.707,−0.707) velocity (the streak lies along travel). Drawn (blur switched off for the reading): over black **70 px, max +0.0784**; over a 0.5 field **214 px, ±0.1529** — the row works, and reads as a whisper; see L67. | ✓ |
| 4 | Hull-critical vignette | FX_SPEC §6 row 1, §1.8 | `fx_hull_critical_vignette.png` as a full-frame `TextureRect` on the same layer, additive; **hull 0.2500 → `active=false`, `visible=false`, `modulate_a=0.000000`; 0.2499 → active** (the 25 % line is `<`, not `≤`). Pulsed on the engine's own process frames for 1.5 s: **low 0.6000, high 1.0000, half-period 0.6000 s** against the spec's 0.6 s, worst gap to the sine 0.0174 (a 2-frame sampling offset). Plate centre `(5,8,11)`, `min=0.0000`, corner `(44,20,13)`; drawn centre mean 0.0323 vs corner 0.1424 — the "fully transparent centre" is 3 % short; see L68. | ✓ |
| 5 | Low-hull electrical arcs | FX_SPEC §6 row 3, §7.1 | 360 real physics frames at hull 20 % draw **2 arcs**, next interval **2.375923** (inside 1.6–2.6); at hull 80 % **0**; the arc's own sheet is really drawn (`most_nodes_at_once=1`, `frames_that_drew=22` ≈ 0.37 s of the 0.2 s/frame sheet), and the spawn goes through the shipped `arc` row (`Projectile.spawn_arc_spark`). | ✓ |
| 6 | Thruster trail | FX_SPEC §1.3 amendment, §7.1 | Emitter-per-anchor ✓ (3 anchors → 3 emitters, 1 → 1, clear → 0, measured on a bare holder so a live hull's own re-sync cannot confound it); one tail point `(−16.5000, 0) = −0.55 × r 30.0` ✓; `local_coords=false`, additive `CanvasItemMaterial`, `lifetime=0.4000` ✓; `amount=24` with `amount_ratio` **0.333333 → 1.000000** = 20/s → 60/s ✓; alpha `0.3500 → 0.8500` ✓; the active rule through real frames with the input action ✓ (`at_rest_no_stick` off; `at_rest_stick_down` on; `the_floor_drifting` 0.15 on; `drifting` 0.50 on). **"World length 24 u → 56 u" and "Width 6 u" FAIL:** the drawn quad is **1401 × 86 px** (the master's native region) at every ratio — §2.2. | **✗** |
| 7 | Thruster bed | AUDIO_SPEC §4.5 | Cue `sfx_ship_engine_01` → `res://assets/audio/sfx/sfx_ship_engine_01.ogg`, `LOOP_PRIORITY` **1**; pitch **0.850000 → 1.150000**, volume **−24.000000 → −12.000000 dB** (0.5 → 0.973529/−19.058823, 0.9 → 1.114706/−13.411765) — each equal to my own spec arithmetic; hysteresis **0.12 off / 0.15 on / latched to 0.10 / 0.095 off / re-arm needs 0.15**; `thrust_at_ratio_zero` held; **three beds sound at once** and `stop_thruster_bed` leaves exactly the other two (shield `kept=true`, beam `kept=true`); the death path releases it (`sounding=false`, `trail_children=0` after a real `state.damage(hull+1)` + `_switch_ship_off` order). **The bed never plays: §2.1.** | **✗** |
| 8 | Boost cue | AUDIO_SPEC §4.5 last ¶ | One activation → `activations=1`, `last_sfx=sfx_ship_boost_01`, path `res://assets/audio/sfx/sfx_ship_boost_01.ogg`; three further frames of the same held trigger light nothing further; the cue resolves through `play_sfx` (no pool row, the station LAUNCH route). | ✓ |
| 9 | Dash charge | FX_SPEC §7.1 row | `fx_dash_charge.png`, one node at `world_u=32.0000` (= the row's own 32), on the hull (`at_hull=true`), `fades=0.20` (= the row's 0.2 s), and **freed after 30 further burn frames while `activations` stays 1** — one charge per activation. Only the afterburner's line calls it (`b_fold` waits, as the brief's seam 6 requires). | ✓ |

### 1.1 The wave's own seams, verified

- **One input, one owner.** `grep -rn "max_speed"` over `game/`, `ui/`: the only `|v| / v_max` is
  `game/game.gd:1192` (`_push_speedometer`), which pushes the same number to
  `speed_fantasy.set_ratio`, `PlayerShip.set_speed_ratio` and the HUD. No second computation.
- **The wheel keeps its target.** `_set_camera_zoom` still clamps to 0.70/1.50 and still tweens
  0.18 s (`TRANS_SINE`/`EASE_OUT`), now onto `_camera_zoom_shown`; `Camera2D.zoom` has exactly one
  writer (`speed_fantasy.gd:393`), and the pull-back is never written back (measured above and by
  a 10-cycle ratio sweep).
- **The bed's driver is the ship.** `player_ship.gd:_update_thrust_feedback` asks once per physics
  frame with the ratio the scene pushed; the manager owns the curve, the hysteresis and the
  voice; the stop is `stop_bed(THRUSTER_CUE)` by cue.
- **No new gameplay coupling.** The vignette/arcs read `PlayerState.hull / hull_max` — the pool the
  HUD already reads — and the trail/bed read `speed_ratio` only (§7.3's own wording).
- **A wreck does not thrust.** `_on_hull_death` releases the bed and clears the emitters, measured
  with `sounding=false`, `trail_children=0` in the shipped order (`hull_changed` handler first,
  then `game.gd:_switch_ship_off()`).

### 1.2 Nothing outside the wave was touched

`git status --porcelain` lists exactly five modified files (`autoload/audio_manager.gd`,
`game/game.gd`, `game/game.tscn`, `game/player_ship.gd`, `game/projectile.gd`), the two new
sources (`game/speed_fantasy.gd`, `game/speed_blur.gdshader`) plus their `.uid` sidecars, four new
tests, and the wave's `.agents/gen/` records. **No `assets/**`, no theme, no `project.godot`, no
`addons/**`, no `docs/**`.** `game/fx.gd` is reused and unmodified; `game/player_ship.tscn` needed
nothing (the emitters are built in code behind the anchor seam). Nothing is staged or committed.

### 1.3 No gameplay number moved

- The whole five-file diff is **605 insertions and exactly 5 deletions**; the five deleted lines are
  one reworded audio comment, the old `Camera2D.zoom` tween target, and the three lines of
  `_push_speedometer`'s old guard:
  ```
  $ git diff -U0 | grep -E '^-[^-]'
  -## against a lower one. An impact read (S6's hum) outranks a held tool's own bed.
  -		_camera, "zoom", Vector2(_camera_zoom, _camera_zoom), CAMERA_ZOOM_SECONDS
  -	if _hud == null or _ship == null or _stats == null:
  -		return
  -	if not _hud.has_method(&"set_speedometer"):
  ```
- Every added numeric literal is presentation: the thruster curve (0.15/0.10/0.85/1.15/−24/−12), the
  trail row (0.15/20/60/0.4/24/56/6/0.35/0.85), the shader's two pixel scales (24/2), the dust row
  (30/0.5/12/0.35), the arc cadence (1.6/2.6, FX_SPEC §6's own *proposed* row), the anchor fraction
  0.55, and the dash charge's region/32 u/0.2 s (FX_SPEC §7.1's own *proposed* row). Nothing in
  `ShipFit.HANDLING`/`MODULES`/`FAMILIES`, `ShipStats`, `Impact`, `Damage`, `PlayerState`, §13 or
  any damage/cadence/range/energy/fuel value appears in the diff.
- The pinned tables the wave touches are additive only: `projectile.gd`'s `FEEDBACK` gains three new
  rows and its six pre-existing rows are untouched (`git diff | grep -E '^[-+].*&"(explosion|
  secondary|arc|shield_break|ripple|plume)":'` → no output); `LOOP_PRIORITY` gains the thruster row
  and keeps its two.
- **CONTRACTS pins, grepped across the changed files:** §4 — `setup`, `set_move_target`,
  `cancel_orders`, `warp_available`, `signal damage_taken`, `velocity`, `impact_body`,
  `apply_impulse`, `apply_recoil`, `set_aim_point`, `clear_aim_point` (all present, none moved);
  §7 — the frozen four plus the slice-2 seven intact (`ui/hud/hud.gd` is not in the diff at all);
  §8.1 — `try_spend_energy`, `try_spend_fuel`, `consume_fuel_cell`, `fuel_cell_ready`,
  `emergency_mode`, `reactor_efficiency`, `tick`, `set_energy`, `set_fuel`, `damage`
  (`player_state.gd` not in the diff), `BOOST_FUEL` 3.0 / `DASH_FUEL` 25 still `player_ship.gd`'s;
  §8.2 — Projectile's `configure`, `family`, `is_destructible`, `hit_radius`, `damage_amount`,
  `bypasses_shield`, `velocity`, `source`, `lock_target`, `decoy`, `retarget`, `fizzle`,
  `signal detonated`.
- The strongest single line of evidence is behavioural: **the 25 pre-existing suites print their
  recorded counts and pass** (§0), which is what pins §13's rows, the damage values, the cadences,
  the ranges and the pools.

## 2. HIGH findings — the two that block the wave

### 2.1 HIGH — the thruster bed holds a voice but never plays a stream (deliverable 7, and the owner's own sentence is unmet)

**Reproduce** (headless, no display needed):

```
$ ~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_s2_5_voice.tscn --fixed-fps 60 --quit-after 900
[S2V] ARM A_beam_play_loop_only frame=10 index=0 playing=true stream=res://assets/audio/sfx/sfx_mining_beam_01.ogg volume_db=0.0000 pitch=1.0000
[S2V] ARM B_thruster_play_loop_only frame=10 index=0 playing=true stream=res://assets/audio/sfx/sfx_ship_engine_01.ogg volume_db=0.0000 pitch=1.0000
[S2V] ARM C_hold_thruster_bed frame=10 index=0 playing=true stream=res://assets/audio/sfx/sfx_ship_engine_02_loop.ogg volume_db=-19.0588 pitch=0.9735
[S2V] ARM D_thruster_after_the_ask frame=0 index=1 playing=false stream=<none> volume_db=-19.0588 pitch=0.9735
```

and on the shipped scene (`.agents/gen/slice2_5_s2_probe.txt`):

```
$ ~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_s2_5_review.tscn --fixed-fps 60 --quit-after 5400
[S2R] BED_SHIPPED cue_index=0 reported_sounding=true pitch=1.1062 volume_db=-13.7506 playing=false stream=<none> matching_stream=false
[S2R] BED_VOICE frame=1 index=0 playing=false stream=<none> volume_db=-19.0588 pitch=0.9735
[S2R] BED_VOICE frame=30 index=0 playing=false stream=<none> volume_db=-19.0588 pitch=0.9735
```

**What it means.** `AudioManager.sounding_loops()`/`bed_state()` report the bed from the cue table,
which is all S1's suite asserts — so the wave looks green while the audio is wrong. The voice's own
`AudioStreamPlayer` is the witness, and it says:

- **Arm D (a fresh voice):** `play_loop` took voice 1, `_loop_cues[1] = sfx_ship_engine_01`, and the
  player has **no stream and is not playing** → **silence**. This is the shipped case: the first
  time the hull flies, the thruster voice is brand new.
- **Arm C (a re-used voice):** the voice keeps playing **the previous cell's file**
  (`sfx_ship_engine_02_loop.ogg`, leaked from the arm before it) at the **thruster's own pitch and
  level** (0.9735 / −19.06 dB) and never swaps in `sfx_ship_engine_01.ogg` → the wrong sound, for
  as long as the bed is held.
- **The mechanism is isolated by arms A and B:** the same `play_loop` on its own plays correctly
  (arm A: the beam; arm B: `sfx_ship_engine_01.ogg` swapped in by frame 10). The difference is
  `hold_thruster_bed`, which calls `play_loop` and then `_shape_bed` **in the same frame**;
  `_shape_bed` starts with `_kill_loop_tween(index)` (audio_manager.gd:695), which kills the
  crossfade tween whose `tween_callback(_start_stream)` had not run yet. The stream is therefore
  never `set`, and every later frame's `play_loop` early-returns ("already sounding") so it never
  retries. `_shape_bed`'s own doc-comment assumes the stream is up ("the bed enters at the curve's
  own floor"), which is exactly what does not happen.
- **The owner's request is unmet:** *"ship while traveling has to make sounds (thrusters depending
  on speed)"* — the bed is silent (fresh voice) or wrong (re-used voice). The one thing S1 could
  not see headless is the one thing that fails.
- **Severity:** HIGH. It is the wave's audio deliverable and one half of the owner's sentence.
- **Fix path (S3).** Make the shaped bed own the start rather than kill it: let the voice's stream
  be set before the level is written — e.g. `_shape_bed` calls `_start_stream`/assigns the cue's
  own stream and `play()` when the voice is not already playing that stream, then kills the tween
  and writes pitch/volume; or `hold_thruster_bed` does not shape on the frame that starts the bed.
  The regression must then be pinned by a test that reads the voice, not the cue table:
  `get_node("/root/AudioManager")._loop_players[index].stream` (or a small `voice_state(cue)`
  read-back) must be the cue's own file and `playing` true after two frames — S1's
  `test_the_thruster_bed_holds_by_ratio_with_hysteresis_and_its_own_cue` currently asserts only
  `bed_state()`/`sounding_loops()`.

### 2.2 HIGH — the trail's streaks draw at the master's native 1401 × 86 px, so §1.3's 24–56 u × 6 u never reach the screen (deliverable 6)

**Reproduce** (needs a display; Vulkan on this host):

```
$ ~/.local/bin/godot --path vajb-orbit res://tests/probe_s2_5_trail_draw.tscn
[S2D] TRAIL ratio=0.15 emitting=true amount=24 amount_ratio=0.333333 scale=(0.017131,0.069767) … lit=120485 max=1.0000 box=[P: (247, 497), S: (1401, 86)]
[S2D] TRAIL ratio=1.00 emitting=true amount=24 amount_ratio=1.000000 scale=(0.039971,0.069767) … lit=120485 max=1.0000 box=[P: (231, 497), S: (1401, 86)]
[S2D] SCALE_LEVER mode=node_scale    node_scale=(0.017131,0.069767) particle_scale=1.000000 lit=120485 box=[P: (259, 497), S: (1401, 86)]
[S2D] SCALE_LEVER mode=particle_scale node_scale=(1.000000,1.000000) particle_scale=0.017131 lit=48 box=[P: (948, 539), S: (24, 2)]
$ ~/.local/bin/godot --path vajb-orbit res://tests/probe_s2_5_node_scale.tscn
[S2S] NODE_SCALE scale=(1.000000,1.000000)  drawn_box=[P: (928, 508), S: (64, 64)]
[S2S] NODE_SCALE scale=(0.500000,0.500000)  drawn_box=[P: (928, 508), S: (64, 64)]
[S2S] NODE_SCALE scale=(0.017131,0.069767)  drawn_box=[P: (928, 508), S: (64, 64)]
```

**What it means.** `lit=120485` is exactly `1401 × 86 − 1`: the drawn particle quad is the
`AtlasTexture` region at 1:1 texel-to-pixel, **the node's `scale` is not applied to the drawn
particle at all** (a uniform 0.5 on a 64 × 64 texture also draws 64 × 64), while the
*process material's* `scale_min` does scale it (the 24 × 2 arm — and that is the route S1's own
**dust** row already uses successfully). So `_shape_trail`'s non-uniform node scale
(`projectile.gd:1440`) and its "the master's aspect is neither" reasoning do nothing:
FX_SPEC §1.3's "World length 24 u at ratio 0.15 → 56 u at 1.0 / Width 6 u" becomes a
**1401 × 86 px** band on a 1920 × 1080 frame — 73 % of the screen's width — and because the
emission shape is a `POINT` with zero velocity, all 8–24 particles stack on the same spot
(measured: the same band's frame mean is 0.0182 at ratio 0.15 against 0.0574 at 1.0).

**Seen, not inferred.** `.agents/gen/slice2_5_s2_shot_trail_on.png` is the shipped scene (throttle
held, tree paused, emitters on) and `.agents/gen/slice2_5_s2_shot_trail_diff.png` is the
amplified on/off difference of the same still — a screen-wide ember band with a bright core line
through it and the plate's own translucent surround visible as a slab. Reproduce:

```
$ ~/.local/bin/godot --path vajb-orbit res://tests/probe_s2_5_shot.tscn   # writes /tmp/s2/ship_paused_trail_{on,off}.png
```

**Severity:** HIGH. Deliverable 6's central numbers do not reach the frame, and what does reach it
is worse than nothing: a long stacked ember band across the ship.

**Fix path (S3).** Move the size onto the lever that works: set
`ParticleProcessMaterial.scale_min/max` from the ratio (as the dust row already does) and drop the
node scale, keeping `position = anchor − length/2` and the plate's own head/tail orientation. Note
the spec/art consequence: a *uniform* particle scale can only give 24 u × 1.47 u (the master's own
1401:86 aspect) — **FX_SPEC §1.3's 6 u width is unreachable from this master without re-cutting the
art** (`LOW_BACKLOG` L72). Re-measure with `probe_s2_5_trail_draw.tscn`: the expected box is
24 × 2 px at ratio 0.15 and 56 × 3 px at 1.0.

## 3. S1's three reported findings, re-measured and re-tiered

| S1 | Claim | My measurement | Tier |
|---|---|---|---|
| §6.1 | The dust plate has no alpha, so a MIX draw carries its surround ("MED-ish, owner-decidable") | `Image.detect_alpha() = 0` on `fx_dust_streak.png`; the region's ink box is `(6,11,16)…(47,57,75)`; the emitter carries no `CanvasItemMaterial`. Drawn (blur off): over black **70 changed px, max +0.0784**; over a 0.5 field **214 px, +0.1529/−0.1529** — so the row *does* read, as a faint dash that both lifts (core) and darkens (surround). The blend follows §5 row 3's "never additively blown" and §0's own no-alpha plates to the letter. | **LOW** (L67) — owner tuning, one line if the owner wants it to read as light |
| §6.2 | The vignette plate's centre is not transparent | centre texel `(5,8,11)` against a corner `(44,20,13)`; the plate's own minimum over a 4 px grid is `0.0000`; drawn centre mean **0.0323** vs corner **0.1424** (S1's pixel numbers reproduced exactly). Wiring-side unavoidable without a re-cut. | **LOW** (L68) — art lane |
| §6.3 | `amount_ratio`'s liveness is unobservable headless ("reversal named in the code comment") | **Resolved: it is live.** With the emitter restarted per ratio, a 24-particle synthetic emitter draws `lit=864 / 288 / 396` at `amount_ratio` 1.0 / 0.333333 / 0.5, exactly `amount × ratio` (36 px per 6 × 6 particle) — the count scales with `amount_ratio`, and the shipped trail's `amount_ratio × amount / lifetime` is therefore the spec's 20–60/s. | **no finding — closed** |

## 4. LOW findings (these ride to `.agents/gen/LOW_BACKLOG.md` as L66–L72)

Each row there carries the command and raw output; in one line each:

- **L66** — the screen-space stack freezes on at death: after `_on_ship_died` (which stops
  `game.gd`'s per-frame push) `blur_visible=true, blur_strength=0.6093, dust_emitting=true` while
  the ship is gone. `[S2R] DEATH …` in `.agents/gen/slice2_5_s2_probe.txt`.
- **L67** — the dust row's drawn contribution (above), and its 0.35 alpha borrowed from §1.3.
- **L68** — the vignette plate's non-zero centre (above).
- **L69** — the blur is `0.000000` at **exactly** ratio 0.70 while the dust is **on** at exactly
  0.70: `blur_for` uses `> ONSET`, `dust_read` uses `>= ONSET`. One comparison; the spec's two
  clauses ("strength is 0 below the 0.70 onset" vs "clamps 0.1 at cruise", "active from 0.70") do
  not agree on the boundary point itself. `[S2R] BLUR ratio=0.7000 …, [S2R] DUST ratio=0.70 on=true`.
- **L70** — `hold_thruster_bed`'s return value means "held", not "sounding", against its own
  docstring: with all three voices taken it returns `true` while `bed_state().sounding=false` and
  the cue is not in the voice table. `[S2V] ARM F_full_house returned=true bed_state_sounding=false`.
- **L71** — `mining_laser.gd:_stop_beam_loop` still stops its bed through `current_loop()` (the
  foreground only), the route `weapons.gd:_stop_beam_bed` already replaced with `stop_bed`; measured
  failing **both** with and without the thruster bed up (`beam_still_sounding_after_stop=true`, 2
  beds left), so it is pre-existing rather than this wave's regression — but a third peer bed makes
  it likelier. `[S2R] BEAM_BED with_thruster=false|true …` in `.agents/gen/slice2_5_s2_probe.txt`.
- **L72** — FX_SPEC §1.3's 6 u width is unreachable from the shipped 1401 × 86 master with a uniform
  particle scale (the aspect gives 1.47 u at a 24 u length); an owner/spec call or an art re-cut,
  and it survives §2.2's fix.
- Plus a harness row (**L73**): the `PreToolUse` worker-file hook denies a `write` whose
  `file_path` is *absolute* even when the path is inside the worker's own set (its `_norm` strips
  only the Windows workspace root); the same call with a workspace-relative path is allowed. S1 hit
  the same hook with `edit` (its §6.5a); worth fixing so a worker does not conclude its file set is
  wrong.

## 5. What I checked and found clean (so the close-out does not re-run it)

- The gate, the byte-identical replay, S1's pixel probe re-run, the per-suite table (§0).
- Every pinned signature of CONTRACTS §4/§7/§8.1/§8.2 in the changed files, and the five-file diff's
  five deletions (§1.3).
- The single-input rule, the wheel's clamp/tween/one-writer, the pull-back never written back, the
  drag-along of `_camera_zoom_shown` into `speed_fantasy` (measured through the shipped frame loop).
- The trail's anchor seam (3 → 3, 1 → 1, 0 → 0), its active rule on real frames, and the bed's
  three-voice scope, its own-cue stop and its death release.
- No asset, theme, `project.godot`, addon or doc file touched; `fx.gd` unmodified; nothing staged.
- Two staged items confirmed still staged: `b_fold`'s charge waits (only the afterburner's
  activation calls `_on_booster_activated`), and no NPC hull has a trail or a bed.

## 6. Owner ticks raised by this review

1. **The bed's take is unchanged** (`sfx_ship_engine_01`) — but it is currently inaudible; see §2.1.
2. **The trail's width**: after §2.2's fix a uniform particle scale gives ≈1.5 u, not §1.3's 6 u.
   Either the spec's 6 u is relaxed to the art's aspect, or the art is re-cut (L72).
3. **The dust's blend** (S1's §6.1, re-measured in §3): keep §5's literal MIX, or one line to
   additive if the dust should read as light.
4. **The blur/dust death freeze** (L66) — leave it or clear the stack in `_on_ship_died`.

## 7. State of my own artifacts

- Probes (mine, all under `vajb-orbit/tests/`, none shipped, none in the gate):
  `probe_s2_5_review.gd`/`.tscn` (the state re-measure, 96 lines, byte-identical across runs),
  `probe_s2_5_voice.gd`/`.tscn` (the bed's voices), `probe_s2_5_trail_draw.gd`/`.tscn` (the drawn
  quad and the scale levers), `probe_s2_5_review_pixels.gd`/`.tscn` (the dust on the framebuffer),
  `probe_s2_5_node_scale.gd`/`_world.gd`/`.tscn` (the scale lever alone), `probe_s2_5_shot.gd`/`.tscn`
  (the paused stills).
- Evidence: `.agents/gen/slice2_5_s2_{gate,probe,probe_replay,voice_probe,trail_draw,pixels,
  s1_pixels_rerun,node_scale,shot,replay}.txt` and the three PNG crops
  (`slice2_5_s2_shot_trail_{on,diff,diff_full}.png`, gitignored by design).
- Nothing was fixed. No shipped file was written; nothing is staged, committed or pushed.
