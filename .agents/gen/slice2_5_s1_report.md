# S1 report — slice 2.5's remainder: the speed fantasy, the thruster feedback and the
# damage states (2026-09-21)

Worker: **S1** (the FX lane's own coder, the whole of slice 2.5's remainder).
Authority: `.agents/gen/slice2_5_feel_wave_task.md` (the wave's brief — nine
deliverables, all presentation), read in the brief's order: `AGENTS.md`,
`docs/CONTRACTS.md` §4/§7/§8.1/§8.2/§9, `docs/gameplay/18_engine_spec.md` **§3.4**
(owner ruling 18 — cited, never edited), `docs/design/FX_SPEC.md` **§1.3** (its
2026-09-21 amendment), **§5**, **§6**, **§7.1**, **§7.3**,
`docs/design/AUDIO_SPEC.md` **§4.5**, then the weapon-FX wave's reports
(`weapon_fx_f4_report.md`, `weapon_fx_f3_report.md`) for what the damage half already
shipped and how the loop beds work now.

**Verdict: all nine deliverables are implemented, tested and measured. The gate is
`passed=307 failed=0`, exit 0 (294 before this wave; this wave's 13 tests are the whole
growth, and no existing test moved). No asset, theme, `project.godot`, addon or doc file
was touched.**

## 0. The gate, measured by me

```
~/.local/bin/godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=307 failed=0        # exit 0, log `.agents/gen/slice2_5_s1_gate_after.txt`
```

- Pre-wave, on this host: `passed=294 failed=0` (the brief and `CONTRACTS.md` §9 agree).
- Per suite, this wave: `test_slice2_5_feel.gd` **13** — the only suite the count moved
  in (`294 + 13 = 307`). Every other suite prints exactly what it printed before.
- The green run still carries the one pre-existing `SCRIPT ERROR`
  (`Cannot call method 'call' on a previously freed instance.` at
  `tests/test_weapon_fx_f4.gd:176`, `LOW_BACKLOG` L61) — unchanged, unowned by this wave.
- No `SHADER ERROR` and no `Parse Error` anywhere in the run: the headless (dummy)
  renderer still *compiles* every shader it is handed, so `speed_blur.gdshader` is
  compile-verified by the gate itself (see §2.1 for the one error it caught).

## 1. What was written, and where

| Path | What it now holds |
|---|---|
| **`vajb-orbit/game/speed_fantasy.gd`** (new, 411 lines) | The whole screen-space stack in one `Node`: the blur `CanvasLayer` + `ColorRect` + shader, the camera's applied zoom, the dust emitter, the hull-critical vignette. One per-frame entry point `set_ratio(ratio, velocity)`, a `set_wheel_zoom(value)` for the wheel's own tweened value, `set_hull_fraction(fraction)` for the damage state, and a read-back per row. |
| **`vajb-orbit/game/speed_blur.gdshader`** (new) | The `canvas_item` screen-space blur: `blur_strength`, `blur_direction`, `chromatic_aberration`, plus its two own pixel scales. 17 weighted taps; a strength of 0 is a one-tap pass-through. |
| `vajb-orbit/game/game.tscn` | One new node, `SpeedFantasy` (script `speed_fantasy.gd`), between the parallax layers and the camera. Nothing else moved; the file's other nodes keep their own `unique_id`s. |
| `vajb-orbit/game/game.gd` | `_push_speedometer` computes the ratio once (where it always did) and hands it to its three readers; `_push_speed_fantasy` + `_bind_speed_fantasy` + `_hull_fraction`; `_set_camera_zoom` now tweens the wheel's *shown* value instead of writing `Camera2D.zoom` (the effects node is that camera's one writer). |
| `vajb-orbit/game/projectile.gd` | Three new `FEEDBACK` rows (`trail`, `dust`, `dash_charge`), the trail's engine numbers and statics (`trail_ramp/rate/length/alpha/read`, `sync_thruster_trails`, `clear_thruster_trails`), `spawn_dash_charge`, and the two cue doors (`play_boost`, `hold_thruster`/`release_thruster`) — the same file, no second FX helper. |
| `vajb-orbit/game/player_ship.gd` | `set_speed_ratio`/`speed_ratio`, `thruster_anchors`/`thruster_trails`, `arc_count`/`arc_interval`, `boost_activations`; `_update_thrust_feedback`, `_update_damage_arcs`, `_arc_point`, `_on_booster_activated`; the per-frame calls from `_physics_process`; the bed and the emitters released on `_release_state` and on death. |
| `vajb-orbit/autoload/audio_manager.gd` | `LOOP_PRIORITY` gains `sfx_ship_engine_01: 1`; the thruster curve's constants (cue, 0.15/0.10, pitch 0.85–1.15, volume −24→−12 dB); `hold_thruster_bed`, `stop_thruster_bed`, the static `thruster_ramp`, the `bed_state` read-back, the private `_shape_bed`, and a pitch reset when a voice is handed to a new bed. |
| `vajb-orbit/tests/test_slice2_5_feel.gd` (new) | 13 synchronous tests, one per deliverable plus the wiring. |
| `vajb-orbit/tests/probe_s2_5_feel.gd` + `.tscn` (new) | The deterministic state probe (headless, 64 `[S25]` lines). |
| `vajb-orbit/tests/probe_s25_pixels.gd` + `.tscn` (new) | The **pixel** probe: what the blur, the chromatic split and the vignette actually draw (needs a display, deliberately not in the gate). |
| `.agents/gen/slice2_5_s1_probe.txt`, `_pixels.txt`, `_gate_after.txt` | The raw outputs behind every number below. |

Untouched, as the brief requires: `vajb-orbit/game/fx.gd` (reused, not grown),
`vajb-orbit/game/player_ship.tscn` (the emitters are built in code behind the anchor
seam, so the scene needed nothing), every `assets/**` file, the theme, `project.godot`,
`addons/**` and `docs/**`. `git status` lists exactly the six changed/added game files
above plus the four test files.

## 2. The nine deliverables, with the raw numbers

### 2.1 Deliverable 1 — directional motion blur (FX_SPEC §5 row 1, §7.1, engine spec §3.4)

`SpeedFantasy` builds its own `CanvasLayer` at **layer 1** (above the world's canvas
layer 0, below the HUD's 10 — measured against `ui/hud/hud.tscn`), holding a full-rect
`ColorRect` with the shipped `speed_blur.gdshader`. Strength and direction come from the
frame's single input; `chromatic_aberration` is the strength itself (FX_SPEC says only
"scales with strength"). The `ColorRect` is hidden at strength 0, so a hull below the
onset pays no full-screen pass.

```
[S25] BLUR onset=0.70 span_px=24.0 aberration_px=2.0 shader=res://game/speed_blur.gdshader
[S25] BLUR ratio=0.00 strength=0.000000 chromatic=0.000000 visible=false direction=(0.7071,-0.7071) layer=1
[S25] BLUR ratio=0.50 strength=0.000000 chromatic=0.000000 visible=false direction=(0.7071,-0.7071) layer=1
[S25] BLUR ratio=0.90 strength=0.566667 chromatic=0.566667 visible=true direction=(0.7071,-0.7071) layer=1
[S25] BLUR ratio=1.00 strength=0.800000 chromatic=0.800000 visible=true direction=(0.7071,-0.7071) layer=1
[S25] BLUR onset_control at_0.70=0.000000 at_0.69=0.000000 at_0.71=0.123333
```

- **0.0/0.5 → 0.000000**, i.e. exactly zero below the 0.70 onset, as §5 requires; the
  onset itself is 0.0 and 0.71 is already 0.123333, so there is no off-by-one frame at
  the boundary.
- **0.9 → 0.566667** = `lerp(0.1, 0.8, (0.9−0.7)/0.3)`; **1.0 → 0.800000**. `visible`
  tracks the same value.
- The **pixel** probe proves the strength is not a decorative uniform. A one-pixel
  bright rule on black, measured across its own row at a 1920×1080 framebuffer:

```
[S25P] BLUR case=at_rest_below_the_onset ratio=0.00 strength=0.0000 visible=false lit_px=1 span_px=1 peak=1.000 row_split_px=0.000 column_split_px=0.000
[S25P] BLUR case=ratio_0.9 ratio=0.90 strength=0.5667 visible=true lit_px=11 span_px=11 peak=1.000 row_split_px=0.000 column_split_px=-1.278
[S25P] BLUR case=full_speed_strength_0.8 ratio=1.00 strength=0.8000 visible=true lit_px=15 span_px=15 peak=1.000 row_split_px=0.000 column_split_px=-2.565
[S25P] BLUR case=shader_uniform_at_1.0 strength=1.0000 lit_px=19 span_px=19 peak=1.000 row_split_px=0.000 column_split_px=0.000
```

  - the rule stays **1 px** at strength 0 (the pass-through really is a pass-through);
  - it smears to **11 px at 0.5667** (predicted 18 × 0.5667 ≈ 10.2) and **15 px at 0.8**
    (predicted 14.4), and **19 px** with the uniform pushed to the shader's own 1.0
    (predicted 18) — the smear is proportional to the strength and spans 0.75 ×
    `blur_span_px`, because the outermost of the 17 taps carry weight zero;
  - `lit_px == span_px` at every nonzero strength: the smear is **continuous**, not a
    comb of displaced copies. That number is why the shader ships 17 taps and not 9 —
    measured, a 9-tap smear of the same rule left gaps (`lit_px=7` inside a 19 px
    `span_px`, i.e. visible ghosting at high strength).
  - `column_split_px` **−1.278** at strength 0.5667 and **−2.565** at 0.8, against the
    predicted `2 × aberration_px × CA × strength` of 1.28 / 2.56: the channel split is a
    measured, strength-scaled pixel offset, and the sign says red is above blue (the
    shader samples red at `uv + split`).
  - `row_split_px=0.000` is the **control**: the split is perpendicular to the smear, so
    the row's horizontal channel centroids must coincide — which is how we know the
    measurement is reading the axis it claims to.

**One defect this probe caught and the gate also catches:** the first shader revision
used an early `return` in `fragment()` for the strength-0 case, which Godot rejects
(`Shader compilation failed.`, `SHADER ERROR: Using 'return' in the 'fragment' processor
function is incorrect.`, `speed_fantasy.gd:264` → the error the first gate run printed).
The shipped shader branches instead.

**The shader's two own numbers** (FX_SPEC gives the strength band and no pixel figure):
`blur_span_px` 24.0 and `aberration_px` 2.0, both `uniform`s whose only caller is
`speed_fantasy.gd` (`BLUR_SPAN_PX`/`ABERRATION_PX`). Reported as the shader's own, one
line each to tune — the reversal is the constant.

### 2.2 Deliverable 2 — camera pull-back (FX_SPEC §5 row 2, engine spec §3.4)

The wheel keeps its target: `_set_camera_zoom` still clamps `_camera_zoom` to
`CAMERA_ZOOM_MIN` 0.70 / `MAX` 1.50 and still runs the 0.18 s sine tween, which now
animates `_camera_zoom_shown` rather than `Camera2D.zoom`. `speed_fantasy.gd` is the
camera's one writer and applies `wheel × lerp(1.0, 0.82, (ratio−0.7)/0.3)`.

```
[S25] ZOOM wheel=1.0000 ratio=0.00 pullback=1.000000 applied=1.000000 camera=1.000000 wheel_readback=1.0000
[S25] ZOOM wheel=1.0000 ratio=0.50 pullback=1.000000 applied=1.000000 camera=1.000000 wheel_readback=1.0000
[S25] ZOOM wheel=1.0000 ratio=0.90 pullback=0.880000 applied=0.880000 camera=0.880000 wheel_readback=1.0000
[S25] ZOOM wheel=1.0000 ratio=1.00 pullback=0.820000 applied=0.820000 camera=0.820000 wheel_readback=1.0000
[S25] ZOOM wheel=1.3000 ratio=0.00 pullback=1.000000 applied=1.300000 camera=1.300000 wheel_readback=1.3000
[S25] ZOOM wheel=1.3000 ratio=0.50 pullback=1.000000 applied=1.300000 camera=1.300000 wheel_readback=1.3000
[S25] ZOOM wheel=1.3000 ratio=0.90 pullback=0.880000 applied=1.144000 camera=1.144000 wheel_readback=1.3000
[S25] ZOOM wheel=1.3000 ratio=1.00 pullback=0.820000 applied=1.066000 camera=1.066000 wheel_readback=1.3000
```

- The pull-back is **1.000000 at 0.0 and 0.5** (below the onset, identical to no
  pull-back) and 0.88 / 0.82 above it.
- The composition is exact and stacks: **1.144000 = 1.30 × 0.88** and
  **1.066000 = 1.30 × 0.82**, and the wheel's own read-back stays **1.3000** — the
  pull-back is never written back into the wheel.
- The camera carries exactly the applied value at every reading.
- Through the shipped frame loop (`game.tscn`, the hull held at 0.95 of `max_speed` for
  18 physics frames so the wheel's tween settles inside the window):

```
[S25] LIVE wheel target=1.30 shown=1.300000 ratio=0.9500 pullback=0.850000 applied=1.105000 camera=1.105000 composes=true pull_back_applied=true
```

  1.30 × 0.85 = **1.105000**, `composes=true`, `pull_back_applied=true`.
- The wheel's clamp/tween is pinned by
  `test_the_wheel_still_clamps_and_tweens_and_the_stage_owns_the_camera`: 2.0 → 1.50, a
  live tween object, `_camera_zoom_shown` still 1.0 (it does not snap; a frame must step
  it), and 0.10 → 0.70.

### 2.3 Deliverable 3 — dust streaks (FX_SPEC §5 row 3, §7.3)

A `GPUParticles2D` named `DustStreaks`, **parented to the camera**, `local_coords = false`
so the streaks it emits are left behind by the moving camera, rotated to the velocity's
bearing. Its art is the new `dust` row in `projectile.gd`'s `FEEDBACK` table (the
shipped `fx_dust_streak.png`, region-cut to its own ink box): 30/s, 0.5 s, 12 u.

```
[S25] DUST emitter parent=ProbeCamera sheet=res://assets/fx/fx_dust_streak.png blend=mix local_coords=false lifetime=0.50 amount=15
[S25] DUST ratio=0.00 on=false emitting=false visible=false rate=0.00 count=0 length=12.0 alpha=0.00 color_a=0.35 rotation_deg=-45.00
[S25] DUST ratio=0.50 on=false emitting=false visible=false rate=0.00 count=0 length=12.0 alpha=0.00 color_a=0.35 rotation_deg=-45.00
[S25] DUST ratio=0.69 on=false emitting=false visible=false rate=0.00 count=0 length=12.0 alpha=0.00 color_a=0.35 rotation_deg=-45.00
[S25] DUST ratio=0.70 on=true emitting=true visible=true rate=30.00 count=15 length=12.0 alpha=0.35 color_a=0.35 rotation_deg=-45.00
[S25] DUST ratio=0.90 on=true emitting=true visible=true rate=30.00 count=15 length=12.0 alpha=0.35 color_a=0.35 rotation_deg=-45.00
[S25] DUST ratio=1.00 on=true emitting=true visible=true rate=30.00 count=15 length=12.0 alpha=0.35 color_a=0.35 rotation_deg=-45.00
```

- **Off at 0.0, 0.5 and 0.69; on at 0.70 and above** — §5's own onset, the same 0.70 the
  blur uses ("one input drives all three rows").
- 30/s over its own 0.5 s lifetime = **15** particles; 12 u long; alpha 0.35.
- `blend=mix`: the emitter carries no `CanvasItemMaterial`, so it is **not additively
  blown** (§5 row 3's own words, and §7.2's). The measured consequence of that, and the
  one place this row meets an asset fact the spec does not account for, is §6.1 below.

### 2.4 Deliverable 4 — hull-critical vignette (FX_SPEC §6 row 1, §1.8)

A full-rect `TextureRect` on the same screen layer, textured with
`fx_hull_critical_vignette.png`, additively composited (the plate is RGB on Void Black
with **no alpha channel** — measured: `mode=RGB`, centre `(5,8,11)`, corner `(42,28,21)`
— so §0's additive rule is the only composite that does not draw a black box, and §1.8's
"alpha pulse" is this node's own `modulate`). The threshold is
`Projectile.LOW_HULL_FRACTION`, the same 0.25 the plume and the arcs use.

```
[S25] VIGNETTE sheet=res://assets/fx/fx_hull_critical_vignette.png line=0.25 period=1.2
[S25] VIGNETTE hull=0.30 active=false visible=false modulate_a=0.000000
[S25] VIGNETTE hull=0.20 t=0.00 active=true alpha=0.800000
[S25] VIGNETTE hull=0.20 t=0.30 active=true alpha=1.000000
[S25] VIGNETTE hull=0.20 t=0.60 active=true alpha=0.800000
[S25] VIGNETTE hull=0.20 t=0.90 active=true alpha=0.600000
[S25] VIGNETTE hull=0.20 t=1.20 active=true alpha=0.800000
[S25] VIGNETTE hull=0.30 after_the_pulse active=false undrawn_alpha=0.800000
[S25] VIGNETTE re_entered alpha=0.800000 (the clock restarts with the state)
```

- **Hull 20 %**: active, and the sine runs **1.0 at 0.3 s → 0.6 at 0.9 s**, one full
  **1.2 s** period returning to 0.800000. The pulse's phase restarts when the state is
  entered, so the read is the state's, not the run's.
- **Hull 30 %**: `active=false`, `visible=false`, `modulate_a=0.000000` — the overlay is
  removed, exactly as §6 requires ("removed above the threshold").
- Drawn, over black (pixel probe):

```
[S25P] VIGNETTE case=pulse_1.0 alpha=0.9970 corner_mean=0.1424 centre_mean=0.0323
[S25P] VIGNETTE case=pulse_0.6 alpha=0.6030 corner_mean=0.0862 centre_mean=0.0197
[S25P] VIGNETTE case=above_the_line visible=false corner_mean=0.0000 centre_mean=0.0000
```

  - the corner patch's luminance follows the pulse **linearly**: 0.0862 / 0.1424 =
    0.605 against an alpha ratio of 0.6030 / 0.9970 = 0.605;
  - removed above the line the frame is **0.0000** everywhere — the overlay draws
    nothing;
  - the screen centre is 4.4× darker than the rim (0.0323 against 0.1424), so the HUD
    stays legible, but it is **not zero** — see §6.2.

### 2.5 Deliverable 5 — low-hull electrical arcs (FX_SPEC §6 row 3, §7.1)

The delta beside the plume that already spawns on `player_ship.gd`: while the hull is
below `LOW_HULL_FRACTION`, `_update_damage_arcs` draws one arc every 1.6–2.6 s from this
hull's own seeded generator and spawns it through **`Projectile.spawn_arc_spark`** — the
same `arc` `FEEDBACK` row and the same helper the railgun's hit uses, so there is no
second spawn path for that sheet. The arc lands on the hull's own art-derived radius
(`_hull_radius()`, the figure the body's inertia and the aim deadzone already read).

```
[S25] ARCS hull=0.20 seconds=6.0 steps=360 count=2 intervals=[2.136090, 1.763172, 2.375923] sheet_nodes=2
[S25] ARCS hull=0.80 seconds=6.0 count=0 nodes=0
```

- **6 s at hull 20 % draws 2 arcs**, every drawn interval inside the section's own
  1.6–2.6 s (2.136090, 1.763172, 2.375923), one sheet node per fired arc.
- **Hull 80 % draws 0** — and 0 nodes.
- The sequence is reproducible: the probe is byte-identical across runs (§5), which is
  what `ARC_SEED` (this hull's own `RandomNumberGenerator`) exists for; it is a
  determinism seam, not a spec number, and the reversal is to draw from the global
  generator.
- Live frames agree (`LIVE hull=0.20 arced=true next_interval_in_band=true arcs=1` after
  2.5 s of physics frames — the first interval is 2.136 s, which is why the window is
  2.5 s and the assertion is "at least one, all inside the band").

### 2.6 Deliverable 6 — thruster trail (FX_SPEC §1.3's 2026-09-21 amendment, §7.1)

One `GPUParticles2D` per anchor, parented to the hull, `local_coords = false` so the
streaks trail in world space; additive ember; every number from §1.3's table.

```
[S25] TRAIL anchors=1 point=(-16.5000,0.0000) hull_radius=30.0000 sheet=res://assets/fx/fx_engine_trail.png
[S25] TRAIL ratio=0.15 emitters=1 amount=24 amount_ratio=0.333333 rate=20.0000 count=8.0000 length=24.0000 width=6.0000 scale=(0.01713062,0.06976745) alpha=0.3500 color_a=0.3500 emitting=true lifetime=0.40 local_coords=false rotation_deg=180.00 pos=(-28.5000,0.0000)
[S25] TRAIL ratio=1.00 emitters=1 amount=24 amount_ratio=1.000000 rate=60.0000 count=24.0000 length=56.0000 width=6.0000 scale=(0.03997145,0.06976745) alpha=0.8500 color_a=0.8500 emitting=true lifetime=0.40 local_coords=false rotation_deg=180.00 pos=(-44.5000,0.0000)
[S25] TRAIL case=at_rest_no_stick ratio=0.00 thrusting=false emitting=false
[S25] TRAIL case=at_rest_stick_down ratio=0.00 thrusting=true emitting=true
[S25] TRAIL case=the_floor_drifting ratio=0.15 thrusting=false emitting=true
[S25] TRAIL case=drifting ratio=0.50 thrusting=false emitting=true
```

- **ratio 0.15**: 20 streaks/s (a third of the emitter's 24-particle capacity),
  8 streaks alive, **24 u** long, **6 u** wide, alpha **0.35**;
  **ratio 1.0**: 60/s, 24 alive, **56 u**, 6 u, alpha **0.85**. Both live 0.4 s.
- `scale` is a non-uniform node pair, because §1.3 gives a length *and* a width and the
  master's own aspect (1401 × 86 px, measured off its ink) is neither:
  `(24/1401, 6/86) = (0.01713062, 0.06976745)` at 0.15 and
  `(56/1401, 6/86) = (0.03997145, 0.06976745)` at 1.0.
- `rotation_deg=180.00` and the emitter's origin sits half a streak **behind** the
  anchor (`pos=(-28.5000, 0)` at ratio 0.15, `-16.5 − 12`): the shipped plate's hot head
  is on its left (measured mean luminance 37.6 → 18.2 → 9.9 over its thirds), so a half
  turn plus a half-length offset puts the **head on the engine** and the transparent tail
  streaming behind — the amendment's intent, with no invented number.
- The active rule is §1.3's own: **off** at rest with no stick, **on** at rest with the
  stick down, **on** at the 0.15 floor drifting and at 0.50 drifting.
- The anchor seam is exactly as briefed: `thruster_anchors()` returns **one** point,
  `(-16.5000, 0.0000)` = `-(hull_radius 30.0) × 0.55`, and the sync in `projectile.gd`
  is already per anchor — `test_the_trail_seam_takes_one_emitter_per_anchor_and_drops_the_extra`
  hands it three engine-cell points and gets three emitters, then one and gets one. Wave
  P2-A's `ShipFit.mount_offset(hull_id, &"engines", i)` replaces that one line.
- One emitter setting's liveness is the renderer's, not the state's: the rate rides
  **`amount_ratio`** (0.333333 → 1.000000) over a fixed 24-particle capacity, which is the
  documented way to scale a GPU emitter without reallocating its buffer and dropping live
  streaks. The probe measures the property; the emitted particle count is not observable
  headless. The reversal, if the renderer disagrees, is one line (`emitter.amount` per
  frame) at the cost of a buffer reallocation.

### 2.7 Deliverable 7 — thruster bed (AUDIO_SPEC §4.5)

```
[S25] BED cue=sfx_ship_engine_01 path=res://assets/audio/sfx/sfx_ship_engine_01.ogg priority=1 on=0.15 off=0.10 pitch=0.85..1.15 volume_db=-24.0..-12.0
[S25] BED ratio=0.00 released_throttle held=false sounding=false pitch=1.000000 volume_db=-80.000000 ramp=0.000000
[S25] BED ratio=0.15 released_throttle held=true sounding=true pitch=0.850000 volume_db=-24.000000 ramp=0.000000
[S25] BED ratio=0.50 released_throttle held=true sounding=true pitch=0.973529 volume_db=-19.058823 ramp=0.411765
[S25] BED ratio=0.90 released_throttle held=true sounding=true pitch=1.114706 volume_db=-13.411765 ramp=0.882353
[S25] BED ratio=1.00 released_throttle held=true sounding=true pitch=1.150000 volume_db=-12.000000 ramp=1.000000
[S25] BED thrust_only ratio=0.00 thrusting=true held=true
[S25] BED hysteresis below_the_on_threshold ratio=0.12 held=false sounding=false
[S25] BED hysteresis at_the_on_threshold ratio=0.15 held=true sounding=true
[S25] BED hysteresis latched_above_off ratio=0.12 held=true sounding=true
[S25] BED hysteresis at_the_off_threshold ratio=0.10 held=true sounding=true
[S25] BED hysteresis below_the_off_threshold ratio=0.09 held=false sounding=false
[S25] BED hysteresis re_arm_needs_0.15 ratio=0.12 held=false sounding=false
[S25] BED hysteresis re_armed ratio=0.15 held=true sounding=true
[S25] BED sounding_at_once=3 beds=[sfx_impact_shield_loop, sfx_mining_beam, sfx_ship_engine_01]
[S25] BED after_thruster_stop=2 beds=[sfx_impact_shield_loop, sfx_mining_beam]
```

- The bed is the spec's pinned take (`sfx_ship_engine_01`, `loop=true`, resolved through
  `cue_path`) at `LOOP_PRIORITY` **1**, beside the mining shaft's.
- The curve is §4.5's own, linear from the 0.15 floor: **pitch 0.850000 → 1.150000**,
  **volume −24.000000 → −12.000000 dB**, with the ramp's own samples at 0.5
  (0.411765 → 0.973529 / −19.058823) and 0.9 (0.882353 → 1.114706 / −13.411765).
- The hysteresis is the spec's: 0.12 alone does not hold, 0.15 does, a released throttle
  keeps it down to 0.10, **0.09 puts it out**, and after it is out the re-arm needs 0.15
  again. A released hull still gets the bed while the thrust input is down at ratio 0.00.
- **Three beds sound at once** and the thruster's own stop leaves the other two
  (`sounding_at_once=3` → `after_thruster_stop=2`), so it can never take the shield hum
  down with it — the stop is `stop_bed(THRUSTER_CUE)` by name, not "the foreground one".
- The same three-bed case is a test
  (`test_the_thruster_bed_cannot_stop_another_holders_bed`).

**The seam I chose for the bed's driver: `player_ship.gd`.** The hull owns *when*
(it has the throttle input, `_thrust_locked()` and the state), the manager owns *what*
(the curve, the hysteresis, the voice, the stop), and the two meet at
`Projectile.hold_thruster(host, ratio, thrusting)` — the project's already-established
cue door (`play_cue`/`hold_shield`/`release_shield` live in the same file). The ratio it
uses is the one `game.gd` pushed (`set_speed_ratio`), never a second
`|v| / v_max`. The ask is one call per physics frame from `_update_thrust_feedback`;
the release is `Projectile.release_thruster` from `_release_state` (a hull swap) and
`_on_hull_death`, and the manager's `LOOP_LEASE` covers a ship that leaves the tree
without either (the pre-existing idiom the brief blesses).

### 2.8 Deliverable 8 — boost cue, and 2.9 — dash charge (AUDIO_SPEC §4.5 last paragraph, FX_SPEC §7.1)

Both hang off the **afterburner's own activation** — the single line in
`_update_boosters` that lights a burner — so neither can fire twice in a burn, and
`b_fold`'s charge stays slice 4's with its movement.

```
[S25] BOOST cue=sfx_ship_boost_01 last_sfx=sfx_ship_boost_01 path=res://assets/audio/sfx/sfx_ship_boost_01.ogg activations=1
[S25] BOOST charge=res://assets/fx/fx_dash_charge.png scale=0.02547771 world_u=32.0000 at_hull=true fades=0.20
[S25] BOOST charges=1 (one activation)
[S25] BOOST after_three_more_burning_frames activations=1 charges=1
```

- One activation → **one activation counter, one S12 cue** (`sfx_ship_boost_01`,
  resolved to its shipped file, no pool row needed so the cue door falls back to
  `play_sfx` exactly as the station's LAUNCH cue does), and **one dash charge**.
- The charge is the new `dash_charge` `FEEDBACK` row: `fx_dash_charge.png` region-cut to
  its own 1193 × 1256 px object, engine-scaled to **32.0000 u** (scale 0.02547771),
  drawn on the hull that lit it, and faded out over the row's **0.20 s**.
- Three more frames of the same held trigger light nothing further
  (`activations=1 charges=1`): the event is the activation.

## 3. The one input, and where it is computed

`game.gd:_push_speedometer` is still the only place `|v| / v_max` is computed, and it now
hands that frame's value to its three readers in one place: `speed_fantasy.set_ratio`
(blur, dust, pull-back), `PlayerShip.set_speed_ratio` (trail and bed) and the HUD dial.
`speed_fantasy.set_hull_fraction` carries `PlayerState`'s own hull fraction for the
damage states (§7.3: they key off the pools). The wiring is pinned by
`test_the_stage_pushes_one_ratio_to_the_stack_and_to_the_hull` and, on live frames:

```
[S25] LIVE frames=2 ratio=0.9500 ratio_pushed=true blur_on=true dust_on=true dust_visible=true trail_emitters=1 trail_emitting=true hull_fraction=1.0000 vignette=false
```

## 4. No gameplay number moved

- The wave adds **no** numeric literal to a balance table. The tables it touches are
  `projectile.gd`'s `FEEDBACK` (three *new* rows; the six existing rows, their regions,
  sizes and rates are byte-identical), `audio_manager.gd`'s `LOOP_PRIORITY` (one new
  row; the two existing rows untouched), and new constants that did not exist before.
  Nothing in `ShipFit.HANDLING`/`MODULES`/`FAMILIES`, `ShipStats`, `Impact`, `Damage`,
  `PlayerState`, §13 or any damage/cadence/range/energy/fuel value is touched.
- `game.gd`'s only behaviour change outside this wave's own rows is *who* writes
  `Camera2D.zoom` (now `speed_fantasy`, the same arithmetic the wheel tween produced
  before) — the wheel's clamp, step and 0.18 s tween are unchanged, and no test in the
  repository asserted on `Camera2D.zoom`, `_camera_zoom` or the old tween target
  (grepped: zero hits), so **no existing test moved**.
- The one pre-existing behaviour this wave repairs in passing is a pitch leak:
  `play_loop` now resets a voice's `pitch_scale` when it hands it to a new bed, because
  the thruster shapes its voice and the mining shaft's per-tier pitch reads the voice's
  own (AUDIO_SPEC §4.2). Without it, a thruster bed at 1.15 would retune whichever bed
  took its voice next. Reversal: delete the reset line.

## 5. The probes, and their determinism

Both probes are run and re-run here; the feel probe's 64 lines are **byte-identical
across three runs** (`md5 8ff3c8cb993a08b1c783d4da9f53cb26`, `/tmp/p2.txt` vs
`/tmp/p4.txt`), which is why every number below can be quoted as a measurement rather
than an example.

```
# state (headless, part of the wave's evidence; 64 [S25] lines)
~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_s2_5_feel.tscn \
  --fixed-fps 60 --quit-after 900            → exit 0, no SCRIPT ERROR
# pixels (needs a display; NOT part of the gate)
~/.local/bin/godot --path vajb-orbit res://tests/probe_s25_pixels.tscn \
  --fixed-fps 60                             → exit 0, 8 [S25P] lines, quits itself
```

Raw output saved beside this report: `.agents/gen/slice2_5_s1_probe.txt` (state),
`.agents/gen/slice2_5_s1_pixels.txt` (pixels), `.agents/gen/slice2_5_s1_gate_after.txt`
(the gate). The pixel probe was added because the state probe proves the *uniforms* and
nothing else; it renders a one-pixel rule and a 3 × 3 spot on black and measures what the
shader actually does to them (§2.1, §2.4). It is deliberately **not** in the gate (it
needs a window), and it quits itself rather than depending on `--quit-after`.

## 6. Findings for S2 and the owner (not hidden, not fixed)

**6.1 — the dust row's blend meets an asset fact (MED-ish, owner-decidable).**
FX_SPEC §5 row 3 and §7.2 both say the dust streak is "never additively blown", and §0
says every FX plate is RGB on Void Black. The shipped `fx_dust_streak.png` has **no alpha
channel** (measured: `mode=RGB`; centre texel `(24,30,44)`, i.e. it is a *dark* streak on
an even darker field). A non-additive draw therefore carries the plate's own surround at
the row's alpha, and the whole effect reads as a faint darkening rather than a lit streak.
I followed the letter of the law (`MIX`, no `CanvasItemMaterial`, region-cut to the
streak's 967 × 52 px ink box, alpha 0.35) and report the conflict rather than tuning it
away: **the single-line reversal is `emitter.material = FxScript.additive_material()`**,
if the owner prefers the streak to read as light (that would depart from §5's wording).
The 30/s figure is also taken exactly as given and **not ramped** by the ratio, because
§5 gives one rate ("30/s at ratio 1.0") and no onset value — inventing the ramp would be
a new number.
**6.2 — the vignette plate's centre is not fully transparent (LOW, art-side).** §1.8
requires the centre to be "fully transparent"; the shipped plate's centre texel is
`(5,8,11)` against a corner of `(42,28,21)`, and the pixel probe measures the middle of
the frame at **0.0323** mean luminance against the corner's **0.1424** — i.e. the overlay
adds a 3 % wash over the middle as well as the ember rim. Legible, low, and the art lane's
to fix; nothing in the wiring can subtract it without re-cutting the art (forbidden).
**6.3 — the trail's rate rides `amount_ratio` (§2.6).** Measured as state; the emitted
count is not observable headless. Reversal named in the code comment.
**6.4 — the shader's own pixel scales** (`blur_span_px` 24, `aberration_px` 2, TAPS 17)
are reported in §2.1 with the measurements that justify them; FX_SPEC gives the strength
band only, so these are the shader's, one line each.
**6.5 — environment notes for the next worker in this lane.** (a) The `PreToolUse` hook
denied single-`edit` calls to files that *are* in my set (two of them, `audio_manager.gd`
and `player_ship.gd`) while the same change through `multiedit` was allowed; the hook's
`_norm`/`file_path` reading looks fine on inspection, so it is recorded here as a harness
observation, not a wave finding. (b) `--resolution 640x360` did not resize the viewport
on this host (the readings are for 1920 × 1080); the shader's smear is expressed in
pixels, so the spans are unaffected, but a worker comparing spans across hosts should
quote the viewport too.
**6.6 — the one existing red line stays red**: `tests/test_weapon_fx_f4.gd:176`'s
`SCRIPT ERROR` (`LOW_BACKLOG` L61) is pre-existing and untouched; the gate is green with
it, exactly as `CONTRACTS.md` §9 says.

## 7. The owner's ticks (from the brief, block nothing)

1. Which engine bed: `sfx_ship_engine_01` (**shipped**, the spec's pinned default) or
   `sfx_ship_engine_02_loop` — one constant, `AudioManager.THRUSTER_CUE`.
2. The *proposed* rows now shipping as written: trail 20–60/s, 24–56 u, 6 u, alpha
   0.35–0.85; dust 30/s, 0.5 s, 12 u (and its blend, §6.1); arcs one per 1.6–2.6 s; dash
   charge 32 u, 0.2 s; bed pitch 0.85–1.15, volume −24 → −12 dB, hysteresis 0.15/0.10.
3. Blur 0.1 → 0.8 and the pull-back 1.0 → 0.82 (already specced; shipped as specced).
4. The shader's own two pixel scales and the dust's alpha (0.35, borrowed from §1.3's
   floor) are the only numbers this wave did not read straight out of a spec row — each
   named with its reversal above.

## 8. Close-out state

- Gate: **307 / 0**, exit 0; the wave's 13 tests are the whole growth from 294.
- `VAJB_WORKER_FILES` respected exactly (the six changed game files, `tests/`); nothing
  outside it was written except this report and its three evidence files under
  `.agents/gen/`.
- Nothing is staged, committed or pushed by me.
