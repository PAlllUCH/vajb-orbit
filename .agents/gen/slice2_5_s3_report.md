# S3 report — slice 2.5 (feel) fixer pass: the two HIGH findings, and the re-cut re-wire
# (2026-09-21)

Worker: **S3**, the wave's fixer. Authority: `.agents/gen/slice2_5_feel_wave_task.md` §4's
S3 row ("only S2's HIGH/MED findings, one pass, each re-measured before and after with
S2's own command; gate green and grown"), read with `.agents/gen/slice2_5_s2_report.md`
**in full** (the authority on both HIGH findings), `docs/design/FX_SPEC.md` §1.3, §5, §6,
§7.1, §7.3, `docs/design/AUDIO_SPEC.md` §4.5, and `.agents/gen/slice2_5_s1_report.md` for
what the builder shipped. The owner's new art facts and three jobs arrived with this pass
(2026-09-21).

**Verdict: both HIGH findings are fixed and re-measured with S2's own probes; every effect
is re-wired to the re-cut per-frame RGBA sheets; the gate is `passed=311 failed=0` (307
before, +4 new tests, no existing test moved in count).** No `assets/**`, no theme, no
`project.godot`, no `addons/**`, no `docs/**` was touched; nothing is staged or committed.

File set (`VAJB_WORKER_FILES`, unchanged from S1): `game/game.gd`, `game/game.tscn`,
`game/speed_fantasy.gd`, `game/speed_blur.gdshader`, `game/player_ship.gd`,
`game/player_ship.tscn`, `game/projectile.gd`, `game/fx.gd`,
`autoload/audio_manager.gd`, `tests/`. **Only four shipped files changed**
(`autoload/audio_manager.gd`, `game/fx.gd`, `game/projectile.gd`,
`game/speed_fantasy.gd`); `game.gd`, `game.tscn`, `player_ship.gd`,
`player_ship.tscn` and `speed_blur.gdshader` needed nothing.

## 0. The gate, measured

```
$ ~/.local/bin/godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=311 failed=0        # exit 0, `.agents/gen/slice2_5_s3_gate.txt`
```

- **307 before this pass, 311 after** (+4). `test_slice2_5_feel` **13 → 17**; every other
  suite prints exactly its recorded count:

  | suite | count | | suite | count |
  |---|---|---|---|---|
  | `weapons` | 29 | | `p1_market` | 13 |
  | `npc` | 28 | | `wiring` | 13 |
  | `weapon_fx_f1` | 22 | | `loot` | 13 |
  | `damage` | 20 | | `flight_feel_g1` | 12 |
  | `hud` | 19 | | `p1_catalogues` | 11 |
  | **`slice2_5_feel`** | **17** (was 13) | | `p1_profile` | 9 |
  | `engine2_fixes` | 17 | | `cleaving` | 9 |
  | `pools` | 16 | | `ui_slot_layout` | 7 |
  | `weapon_fx_f2` | 13 | | `combat_repair_c5` | 7 |
  | | | | `weapon_fx_f4` 6 · `p1_refinery` 6 · `p1_repairs` 5 · `p1_pricing` 5 · `flight_beam_g2` 5 · `p1_clock_log` 4 · `engine_c3_flight_decay` 3 · `engine2_dock` 2 |

- The green run carries the same single pre-existing `SCRIPT ERROR`
  (`Cannot call method 'call' on a previously freed instance.` at
  `tests/test_weapon_fx_f4.gd:176`, `LOW_BACKLOG` L61) and the same `ObjectDB`/resource
  exit pair the 307 run carried. No new red line of either kind.
- **The 24 failing assertions the re-wire caused were updated, not deleted**: the suites
  that locate an effect by its sheet (`weapon_fx_f1`, `weapon_fx_f2`, `weapon_fx_f4`,
  `flight_beam_g2`) now name the per-frame file and assert the sheet's own alpha (§4).

## 1. HIGH 1 — the thruster bed held a voice but never played a stream

**The fix.** `autoload/audio_manager.gd`: the shaped bed now owns its own start.

- `_shape_bed` calls a new `_start_bed(cue, player)` **before** it writes the level:
  `_start_bed` loads the cue's own stream, sets it on the voice and calls `play()`, and is
  idempotent (a voice already playing that stream is left alone, so a bed re-asked every
  frame does not restart itself). The crossfade tween is still killed first — that is what
  the level write requires — but the stream no longer depends on the callback it killed.
- A public read-back `bed_voice(cue)` → `{sounding, playing, stream, pitch_scale,
  volume_db}` was added beside `bed_state`: the cue table can say "sounding" while the
  player holds nothing, so the fix is pinned by a read that cannot.

**Reproduce (S2's own command, before and after).**

```
$ ~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_s2_5_voice.tscn --fixed-fps 60 --quit-after 900
```

```
# BEFORE (`.agents/gen/slice2_5_s3_voice_before.txt`)
[S2V] ARM C_hold_thruster_bed held=true index=0 reported_sounding=true pitch=0.9735 volume_db=-19.0588
[S2V] ARM C_hold_thruster_bed frame=1 index=0 playing=true stream=res://assets/audio/sfx/sfx_ship_engine_02_loop.ogg volume_db=-19.0588 pitch=0.9735
[S2V] ARM C_hold_thruster_bed frame=10 index=0 playing=true stream=res://assets/audio/sfx/sfx_ship_engine_02_loop.ogg volume_db=-19.0588 pitch=0.9735
[S2V] ARM C_hold_thruster_bed frame=90 index=0 playing=true stream=res://assets/audio/sfx/sfx_ship_engine_02_loop.ogg volume_db=-19.0588 pitch=0.9735
[S2V] ARM D_thruster_after_the_ask frame=0 index=1 playing=false stream=<none> volume_db=-19.0588 pitch=0.9735

# AFTER (`.agents/gen/slice2_5_s3_voice_after.txt`)
[S2V] ARM C_hold_thruster_bed held=true index=0 reported_sounding=true pitch=0.9735 volume_db=-19.0588
[S2V] ARM C_hold_thruster_bed frame=1 index=0 playing=true stream=res://assets/audio/sfx/sfx_ship_engine_01.ogg volume_db=-19.0588 pitch=0.9735
[S2V] ARM C_hold_thruster_bed frame=10 index=0 playing=true stream=res://assets/audio/sfx/sfx_ship_engine_01.ogg volume_db=-19.0588 pitch=0.9735
[S2V] ARM C_hold_thruster_bed frame=90 index=0 playing=true stream=res://assets/audio/sfx/sfx_ship_engine_01.ogg volume_db=-19.0588 pitch=0.9735
[S2V] ARM D_thruster_after_the_ask frame=0 index=1 playing=true stream=res://assets/audio/sfx/sfx_ship_engine_01.ogg volume_db=-19.0588 pitch=0.9735
```

- **Arm C (a re-used voice)** no longer keeps the previous bed's file: it plays
  `sfx_ship_engine_01.ogg` — the bed's own cue — from frame 1.
- **Arm D (a fresh voice, the shipped first-flight case)** is no longer silent: it plays
  the cue's own file at the thruster's own pitch and level.
- Arms A/B/B2 (a plain `play_loop`) and arm E (the death release) are byte-identical to
  S2's run: the fix changes only the shaped-bed route. Arm F is unchanged, so `LOW_BACKLOG`
  L70 (the return value means "held", not "sounding") is untouched and still owned by the
  backlog.

**The same read on the shipped scene** (S2's review probe, before/after):

```
# BEFORE (`.agents/gen/slice2_5_s2_probe.txt`)
[S2R] BED_SHIPPED cue_index=0 reported_sounding=true pitch=1.1062 volume_db=-13.7506 playing=false stream=<none> matching_stream=false
[S2R] BED_VOICE frame=1 index=0 playing=false stream=<none> volume_db=-19.0588 pitch=0.9735
[S2R] BED_VOICE frame=30 index=0 playing=false stream=<none> volume_db=-19.0588 pitch=0.9735

# AFTER (`.agents/gen/slice2_5_s3_review_after.txt`)
[S2R] BED_SHIPPED cue_index=0 reported_sounding=true pitch=1.0663 volume_db=-15.3466 playing=true stream=res://assets/audio/sfx/sfx_ship_engine_01.ogg matching_stream=true
[S2R] BED_VOICE frame=1 index=0 playing=true stream=res://assets/audio/sfx/sfx_ship_engine_01.ogg volume_db=-19.0588 pitch=0.9735
[S2R] BED_VOICE frame=30 index=0 playing=true stream=res://assets/audio/sfx/sfx_ship_engine_01.ogg volume_db=-19.0588 pitch=0.9735
```

(`pitch`/`volume_db` differ between the two runs only because the hull's ratio differs by
a frame — 0.9103 vs 0.9183 in the `DEATH` line; the stream and `playing` are the fix.)

**The test that pins it** (`tests/test_slice2_5_feel.gd`, new, 1 of the 4):
`test_the_thruster_beds_voice_plays_its_own_stream_from_its_first_frame` — it pre-loads the
manager's voices with the *alternative take* playing (S2's arm C state, the shared-voice
case), holds the bed and reads `bed_voice(THRUSTER_CUE)`: `sounding`, `playing` **true**,
`stream` = `sfx_ship_engine_01.ogg` at the curve's own 0.5 level; then it clears the voices
and re-holds, so the fresh-voice case is read the same way. S1's
`test_the_thruster_bed_holds_by_ratio_with_hysteresis_and_its_own_cue` is untouched (it
tests the curve and the cue table, which are unchanged).

## 2. HIGH 2 — the trail's streaks drew at the master's native size

**The fix.** FX_SPEC §1.3's "24 u at ratio 0.15 → 56 u at 1.0 / 6 u wide" is a statement
about the rectangle the emitter **draws**. A `GPUParticles2D` draws its texture at the
texture's own size — the node's `scale` never reaches it, and the process material's
`scale_min/max` is one number, so it can only follow the art's aspect. The one lever that
reaches the drawn rectangle is the **draw pass**, and that is what the trail now uses:

- `game/fx.gd` gains the quad pass: `QUAD_SHADER` (a `canvas_item` vertex stage that scales
  the quad's own vertices by `quad_scale`), `quad_shader()` (built once and shared),
  `quad_material(quad_scale)`, `set_quad_scale(material, quad_scale)` and
  `quad_scale_for(source, world_length, world_width)`. No `render_mode` is declared, so the
  pass blends with the default MIX — the alpha blend the re-cut sheets carry (§3).
- `game/projectile.gd`: `trail_read` keeps its arithmetic (the SAME
  `(length/source.x, width/source.y)` S1 wrote) but `_shape_trail` now writes it into the
  draw pass instead of the node, and the node itself stays at `Vector2.ONE`.

**Reproduce (S2's own command, before and after).**

```
$ ~/.local/bin/godot --path vajb-orbit res://tests/probe_s2_5_trail_draw.tscn
```

```
# BEFORE (`.agents/gen/slice2_5_s3_trail_draw_before.txt`)
[S2D] TRAIL ratio=0.15 … scale=(0.017131,0.069767) … material=():<CanvasItemMaterial#…> sheet=res://assets/fx/fx_engine_trail.png lit=120485 max=1.0000 mean=0.01471602 box=[P: (247, 497), S: (1401, 86)]
[S2D] TRAIL ratio=1.00 … scale=(0.039971,0.069767) … material=():<CanvasItemMaterial#…> sheet=res://assets/fx/fx_engine_trail.png lit=120485 max=1.0000 mean=0.05740297 box=[P: (231, 497), S: (1401, 86)]
[S2D] SCALE_LEVER mode=node_scale    node_scale=(0.017131,0.069767) particle_scale=1.000000 lit=120485 box=[P: (259, 497), S: (1401, 86)]
[S2D] SCALE_LEVER mode=particle_scale node_scale=(1.000000,1.000000) particle_scale=0.017131 lit=48 box=[P: (948, 539), S: (24, 2)]
[S2D] SHIPPED_ALPHA trail_alpha=0.3500 plate_peak=1.0000 additive=true particles_alive=24 scale=(0.017131, 0.069767)

# AFTER (`.agents/gen/slice2_5_s3_trail_draw_after.txt`)
[S2D] TRAIL ratio=0.15 … scale=(1.000000,1.000000) … material=():<ShaderMaterial#…> sheet=res://assets/fx/fx_engine_trail_f1.png lit=73 max=0.9843 mean=0.00002647 box=[P: (938, 537), S: (22, 6)]
[S2D] TRAIL ratio=1.00 … scale=(1.000000,1.000000) … material=():<ShaderMaterial#…> sheet=res://assets/fx/fx_engine_trail_f1.png lit=171 max=1.0000 mean=0.00007639 box=[P: (906, 537), S: (54, 6)]
[S2D] SCALE_LEVER mode=node_scale    node_scale=(0.150943,0.230769) particle_scale=1.000000 lit=2020 box=[P: (880, 527), S: (159, 26)]
[S2D] SCALE_LEVER mode=particle_scale node_scale=(1.000000,1.000000) particle_scale=0.150943 lit=49 box=[P: (948, 538), S: (21, 4)]
[S2D] SCALE_LEVER mode=quad_pass     node_scale=(1.000000,1.000000) particle_scale=1.000000 lit=73 box=[P: (948, 537), S: (22, 6)]
[S2D] SHIPPED_ALPHA trail_alpha=0.3500 plate_peak=1.0000 additive=false particles_alive=24 scale=(1.0, 1.0)
```

- The band is gone: **1401 × 86 px → 22–24 × 6 px** at the floor and **54–56 × 6 px** at
  full speed, i.e. the spec's own numbers (the 2 px at each end is the art's taper falling
  under the probe's 0.002 threshold; the solid-frame control below measures the rectangle
  itself).
- S2's three-lever arm now separates them in one run: the **node's scale draws the frame
  native (159 × 26)**, the **process material's uniform scale gives 21 × 4** (the art's own
  aspect — it cannot give 6 u of width at a 24 u length), and **the draw pass gives 22 × 6**.

**The acceptance measurement, on the shipped emitter** (new probe,
`.agents/gen/slice2_5_s3_trail_quad.txt`):

```
$ ~/.local/bin/godot --path vajb-orbit res://tests/probe_s3_trail_quad.tscn
[S3Q] SHIPPED ratio=0.15 length=24.0 width=6.0 quad_scale=(0.150943,0.230769) quad_px=(24.0,6.0) node_scale=(1.0, 1.0) box=[P: (919, 537), S: (24, 6)] lit=73 max=0.9882 bright_x=934 box_right=943 anchor_x=944
[S3Q] SHIPPED ratio=0.50 length=37.2 width=6.0 quad_scale=(0.233814,0.230769) quad_px=(37.2,6.0) node_scale=(1.0, 1.0) box=[P: (906, 537), S: (37, 6)] lit=117 max=0.9961 bright_x=929 box_right=943 anchor_x=944
[S3Q] SHIPPED ratio=1.00 length=56.0 width=6.0 quad_scale=(0.352201,0.230769) quad_px=(56.0,6.0) node_scale=(1.0, 1.0) box=[P: (887, 537), S: (56, 6)] lit=171 max=1.0000 bright_x=921 box_right=943 anchor_x=944
[S3Q] SOLID ratio=0.15 frame=159x26 box=[P: (919, 537), S: (24, 6)] lit=144
[S3Q] SOLID ratio=1.00 frame=159x26 box=[P: (887, 537), S: (56, 6)] lit=336
[S3Q] LEVER mode=node_scale       node_scale=(0.150943, 0.230769) particle_scale=1.000000 quad_scale=(0.0, 0.0) box=[P: (880, 527), S: (159, 26)] lit=4134
[S3Q] LEVER mode=particle_uniform node_scale=(1.0, 1.0) particle_scale=0.150943 quad_scale=(0.0, 0.0) box=[P: (948, 538), S: (24, 4)] lit=96
[S3Q] LEVER mode=draw_pass        node_scale=(1.0, 1.0) particle_scale=1.000000 quad_scale=(0.150943, 0.230769) box=[P: (948, 537), S: (24, 6)] lit=144
```

- The **drawn rectangle is 24 × 6 px at ratio 0.15 and 56 × 6 px at 1.0** (1 world unit =
  1 px at zoom 1.0), and the SOLID arm — the same quad scale over a solid frame of the drawn
  frame's own 159 × 26 — measures exactly that, with full coverage (`lit=144=24×6`,
  `lit=336=56×6`), so the number is the rectangle and not the art's taper.
- The streak's **head still rides the engine**: the drawn box's right edge is 943 px and the
  anchor is 944 px at every ratio, and the luminance centroid sits in the right half of the
  box (934 / 929 / 921 of 919–943), which is the art's hot head after the half turn.
- **A note on the two HIGH 2 numbers' provenance**: `source` is now the *drawn frame's own
  ink box* (159 × 26 px, measured off `fx_engine_trail_f1.png`), not the old master's region,
  and the 6 u width is §1.3's own constant applied through the draw pass. `LOW_BACKLOG` L72
  (the 6 u width unreachable *from the master's aspect*) is **closed** by the draw pass:
  the drawn rectangle is 6 u wide at every length, measured.

**Seen, not inferred** (S2's own still probe, re-run):

```
$ ~/.local/bin/godot --path vajb-orbit res://tests/probe_s2_5_shot.tscn
[S2SHOT] on=/tmp/s2/ship_paused_trail_on.png off=/tmp/s2/ship_paused_trail_off.png emitters=1 visible=true emitting=true amount_ratio=0.333333 scale=(1.0, 1.0) pos=(-28.50,0.00) world=(29.56,425.19)
# BEFORE: … amount_ratio=0.333333 scale=(0.017131, 0.069767) pos=(-28.50,0.00) world=(-21.09,418.94)
```

The still (`.agents/gen/slice2_5_s3_shot_trail_after.png`) shows a compact ember flame on
the hull's tail instead of S2's screen-wide band; the amplified on/off difference is
`.agents/gen/slice2_5_s3_shot_trail_diff.png`. S2's `SHIPPED_BAND` reading over the old
1401 × 86 band collapses to `lift=0.000004` (it was +0.022639 over the band), which is the
same fact from the other side.

**The test that pins it** (`tests/test_slice2_5_feel.gd`, new, 1 of the 4):
`test_the_trails_quad_is_sized_through_a_vertex_scaling_draw_pass` — it asserts the material
is a `ShaderMaterial` whose code scales `VERTEX`, that `quad_scale` is readable and
re-writable, that a sheet's own material is *not* a quad pass, and that the shipped
emitter's quad at ratio 0.15 is exactly `(24/159, 6/26)`; and the trail test itself now
asserts `trail.scale == Vector2.ONE` (the inert lever is no longer the one that carries the
number) and reads the draw pass's own value.

## 3. The re-cut re-wire (the owner's third job)

**Every row addresses `fx_<effect>_fN.png` directly, and no row names a v1 master.** The
2K masters are untouched on disk and are no longer an atlas source; the only region left in
the wiring is a *frame's own measured ink box*, and only where a row draws one frame of a
sequence (so the row's `world` reads the object rather than the frame's margin). A row that
plays a sequence draws its frames whole, because the re-cut gives a sequence's frames one
shared canvas on purpose — that is what keeps the relative size inside the animation.

```
$ ~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_s3_rewire.tscn
# `.agents/gen/slice2_5_s3_rewire.txt` — every row, verbatim:
```

| table | row | frames it draws | region | source | world | fps / loop |
|---|---|---|---|---|---|---|
| FEEDBACK | `explosion` | `fx_explosion_f1..f5.png` | — | 904 × 776 | 96 u | 15 / once |
| FEEDBACK | `secondary` | `fx_secondary_explosion_f1..f4.png` | — | 352 × 312 | 48 u | 15 / once |
| FEEDBACK | `arc` | `fx_arc_spark_f1..f4.png` | — | 912 × 672 | 40 u | 20 / once |
| FEEDBACK | `shield_break` | `fx_shield_break_f1..f4.png` | — | 536 × 624 | 64 u | 10 / once |
| FEEDBACK | `chip` | `fx_mining_beam_f1..f4.png` | — | 440 × 424 | 40 u | 20 / once |
| FEEDBACK | `ripple` | `fx_shield_ripple_f1.png` | (196,192,343,334) | 343 × 334 | 64 u | engine tween |
| FEEDBACK | `plume` | `fx_smoke_plume_f1.png` | (110,58,244,882) | 244 × 882 | 40 u | emitter |
| FEEDBACK | `trail` | `fx_engine_trail_f1.png` | (253,18,159,26) | 159 × 26 | 24→56 u | emitter |
| FEEDBACK | `dust` | `fx_dust_streak_f1.png` | (222,17,147,29) | 147 × 29 | 12 u | emitter |
| FEEDBACK | `dash_charge` | `fx_dash_charge_f1.png` | (178,194,580,572) | 580 × 572 | 32 u | fade 0.2 s |
| FEEDBACK | `mine_burst` | `fx_mine_f1..f4.png` | (41,42,661,653) | 661 × 653 | 22 u | 20 / once |
| SHEETS | `bolt` | `fx_laser_bolt_f1.png` | (245,35,310,92) | 310 × 92 | 64 u | still |
| SHEETS | `slug` | `fx_laser_bolt_f3.png` | (75,37,651,89) | 651 × 89 | 96 u | still |
| SHEETS | `mine` | `fx_mine_f1..f4.png` | (41,42,661,653) | 661 × 653 | 22 u | 20 / loop |
| SHEETS | `rocket` | `fx_missile_trail_f1..f4.png` | — | 552 × 248 | 48 u | 12 / loop |
| speed_fantasy | vignette | `fx_hull_critical_vignette_f1.png` | — (full-screen rect) | — | — | modulate pulse |
| weapons.gd | muzzle flash | `fx_muzzle_flash_f1..f4.png` | — | (stale 535 × 487) | 44 u | 20 / once |

Frames a row reads *one* of are `_f1` where the art's own sequence is not the animation the
spec asks for (the trail, the dust, the plume, the ripple, the charge and the vignette all
keep their engine-side animation — FX_SPEC §2's 2026-09-21 amendment: "a one-frame consumer
can always draw `_f1`"); the bolt's still is `_f1` (light bright) and the slug's `_f3`
(medium bright), which is the sheet's own tier order.

**The blend: alpha, per the owner's ruling, with its reversal named.** `Fx.alpha_material()`
(BLEND_MODE_MIX) is now what `Fx.play_once`, `Fx.display`, every `FEEDBACK`/`SHEETS` row,
the dust emitter, the plume emitter and the vignette use; `Fx.additive_material()` survives
for the one thing that is not a sheet — `weapons.gd`'s engine-drawn beam halo. This is a
deliberate departure from FX_SPEC §0's "RGB on void black is drawn additively" for the
sheets, taken on the owner's sentence ("address `fx_effect_fN` directly with alpha blending
as the sheets now carry their own alpha") and on §0.1's own reasoning (an effect whose
opacity is its own alpha is blended with it). **Reversal: one word per row**
(`additive_material()` in `Fx.play_once`/`display`, `_make_trail`, `spawn_smoke_plume`, the
dust emitter, the vignette). The measured consequences are in §5.

**`fx_mine` is the mine family's own effect** (owner ruling): `SHEETS`' `mine` row draws the
family's four frames (the lamp's own pulse, looped at `Fx.DEFAULT_FPS` — the one sequence no
doc gives a rate, so it takes the helper's documented fallback) at the row's own 22 u, and a
new `FEEDBACK` row `mine_burst` plays the same art once where a mine goes off, beside
FX_SPEC §1.4's explosion. The `fx_ember_pulse` crop is gone from the wiring.

```
$ ~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_s3_mine.tscn
[S3M] ROW empty=false keys=[&"frames", &"region", &"source", &"world", &"fps"] frames=4
[S3M] TEXTURES count=4
[S3M] SHOT kind=mine spent=false parent=MineWorld
[S3M] DIRECT_SPAWN node=mine_burst
[S3M] DETONATED children=3
[S3M] CHILD @Area2D@12 type=Area2D frames=0 sheet=
[S3M] CHILD explosion type=AnimatedSprite2D frames=5 sheet=res://assets/fx/fx_explosion_f1.png
[S3M] CHILD mine_burst type=AnimatedSprite2D frames=4 sheet=res://assets/fx/fx_mine_f1.png
```

Its four frames are one object with a pulsing ember lamp (measured, and rendered in
`.agents/gen/slice2_5_s3_mine_frames.png`), which is why the deployed sprite loops and the
burst plays once.

**The beam stays the engine-drawn line.** `weapons.gd` is untouched by this pass and the
instant families still draw their shaft as the `Beam`/`BeamCore` `Line2D` pair
(`weapons.gd:806`), with the halo on `Fx.additive_material()` — no sprite was added for it,
which is the owner's ruling and also FX_SPEC §1.6's ("the beam line itself is engine-drawn;
no texture needed"). `test_the_instant_families_draw_an_engine_side_beam` and
`test_flight_beam_g2`'s beam tests are green.

## 4. The tests that moved, and the four that grew

**Grown (4, all in `tests/test_slice2_5_feel.gd`, 13 → 17):**

1. `test_the_thruster_beds_voice_plays_its_own_stream_from_its_first_frame` — HIGH 1, reads
   the voice (§1).
2. `test_the_trails_quad_is_sized_through_a_vertex_scaling_draw_pass` — HIGH 2, pins the
   draw pass and the shipped emitter's quad (§2).
3. `test_every_effect_row_addresses_its_own_per_frame_files` — every row in both tables:
   its files exist, each is a per-frame `.png`, each frame really carries alpha
   (`Image.detect_alpha()`), its region fits its own frame, and a multi-frame row has a rate.
4. `test_the_mine_family_owns_its_sprite_and_its_burst` — the mine's sprite and burst rows
   agree frame-for-frame, and a mine's own `_detonate` draws its burst at the mine's own
   22 u beside §1.4's explosion.

**Updated (assertions only; no test was deleted or weakened to pass):** the four suites that
locate an effect by its sheet path now name the per-frame file and assert the sheet's own
alpha instead of the additive material —

- `test_weapon_fx_f1.gd` — `BOLT_FRAME`/`SLUG_FRAME`/`TRAIL_FRAME`/`MINE_FRAME` constants;
  the bolt and slug read a region of their own frame; the mine is now the family's four
  animated frames (was "one additive frame"); `_assert_alpha` beside `_assert_additive`
  (the latter kept for the beam halo); the resolve test walks `frames` + `region`.
- `test_weapon_fx_f2.gd` — the six sheet constants are the `_f1` files; `_drawn_from` accepts
  a whole frame or the frame an `AtlasTexture` reads; the resolve test walks `frames`.
- `test_weapon_fx_f4.gd` and `test_flight_beam_g2.gd` — the ripple/explosion/chip constants
  are the `_f1` files and the sheet assertions are alpha.
- `test_slice2_5_feel.gd`'s existing tests — the dust/vignette/arc/trail sheet constants are
  the frames; the dust asserts MIX (the row's own blend) and the measured region; the
  vignette asserts MIX; the trail asserts the draw pass (§2).

**Probes re-run (S2's own, byte-comparable):** `probe_s2_5_voice.tscn`,
`probe_s2_5_review.tscn` (96 lines), `probe_s2_5_trail_draw.tscn`,
`probe_s2_5_review_pixels.tscn`, `probe_s2_5_node_scale.tscn` (byte-identical to S2's — the
lever it proves is untouched), `probe_s2_5_shot.tscn`; plus S1's `probe_s2_5_feel.tscn`
(64 lines) and `probe_s25_pixels.tscn`. **Four of them needed a one-line read patched** to
the new row shape (`row["texture"]` → `row["frames"][0]`, the sheet constant → the `_f1`
file, and the trail's lever arm gained the `quad_pass` mode); every patch is a *probe* edit,
no assertion in them changed, and each is recorded here rather than hidden. S1's probe is
therefore no longer byte-identical to `.agents/gen/slice2_5_s1_probe.txt` — the diff is the
patched reads plus the re-wired values, and its 64 lines are stored as
`.agents/gen/slice2_5_s3_s1_probe_after.txt`.

**My own new probes** (`tests/`, none in the gate): `probe_s3_levers.tscn` (which lever sizes
a particle's quad), `probe_s3_trail_quad.tscn` (the acceptance rectangle, §2),
`probe_s3_rewire.tscn` (every row, §3), `probe_s3_mine.tscn` (the mine's sprite and burst).

## 5. What I did not touch, what changed as a consequence, and the findings I own up to

- **No asset, theme, `project.godot`, addon or doc file was written.** `game.gd`,
  `game.tscn`, `player_ship.gd`, `player_ship.tscn`, `speed_blur.gdshader` and `weapons.gd`
  were read and not edited; `weapons.gd` is outside this worker's file set.
- **`LOW_BACKLOG` L66–L73 are untouched** (S2's LOWs are not mine): the death freeze, the
  dust's contribution, the vignette's plate, the blur/dust boundary at exactly 0.70, the
  held-vs-sounding return, `mining_laser.gd`'s `current_loop()` stop and the hook's absolute
  path all stand as recorded. **L72 is closed by §2's fix** (the 6 u width is reachable and
  measured); **L68's "vignette centre wash" is closed by the keyed frame** (the pixel probe's
  centre is now `0.0000`).
- **The vignette under the alpha blend (measured, owner-decidable).** S1's pixel probe:

  ```
  # BEFORE  [S25P] VIGNETTE case=pulse_1.0 alpha=0.9970 corner_mean=0.1424 centre_mean=0.0323
  #         [S25P] VIGNETTE case=pulse_0.6 alpha=0.6030 corner_mean=0.0862 centre_mean=0.0197
  # AFTER   [S25P] VIGNETTE case=pulse_1.0 alpha=0.9997 corner_mean=0.0000 centre_mean=0.0000
  #         [S25P] VIGNETTE case=pulse_0.6 alpha=0.6022 corner_mean=0.0000 centre_mean=0.0000
  ```

  The centre is now genuinely clear (§1.8's "fully transparent centre"), but the *corner*
  patch is 0.0000 too: the re-cut frame's own corners are `(0,0,0,0)` (the luminance key
  zeroes the darkest ember), and under MIX a luminance-keyed plate renders its brightness
  squared — over the whole frame the plate draws a mean of **0.0214 under MIX against 0.0518
  under ADD** (0.41×; the v1 master's own mean was 0.108). This is the one effect where the
  owner's alpha-blend ruling costs visible strength, and it is one line to reverse
  (`additive_material()` in `speed_fantasy.gd`'s vignette build). I followed the ruling.
- **The vignette frame carries a 49/58 px transparent margin** (its ink box is 880 × 840 of
  984 × 960), so stretched to the screen its ember starts ~5 % inside. I did **not** cut it
  to the ink box: the vignette is a full-screen overlay whose framing *is* the screen, while
  the rows that carry a `world` size get a region so that size reads the object. Art-lane
  call if the owner wants the ember flush to the edge.
- **`weapons.gd`'s muzzle flash constants are stale against the re-cut** (outside my file
  set, reported): `FLASH_FRAME_SIZE` is `(535, 487)` while the frames are `504 × 496`, so
  the flash reads `44 × 504/535 = 41.4 u` instead of the row's own 44 u, and the muzzle
  offset (`FLASH_MUZZLE_PX` 135 px) is scaled by the same stale factor. One constant pair,
  the flash's own lane.
- **The main menu still points at a v1 master** (`ui/screens/main_menu.tscn:5` →
  `fx_ember_pulse.png`, MAIN_MENU_SPEC §5's wreck pulse). It is a scene plate, not a
  `FEEDBACK` row or an `fx.gd` helper, and it is outside my file set; the re-cut gives that
  effect frames if the menu lane wants them.
- **Sizes that moved by the re-cut's own framing** (no number was invented; the rows' own
  values are applied to the frames the art lane shipped): the explosion's canvas is now
  904 × 776 against the old master's 781 × 707 region, so at the row's own 96 u the largest
  frame reads 95 u against 96 (the canvas is the union of the five frames); the arc reads
  0.92×, the shatter 0.90×, the chip 0.89×, the rocket's exhaust 0.90× for the same reason.
  The mine keeps its 22 u, the bolt its 64 u, the slug its 96 u, the charge its 32 u, the
  ripple its 64 u, the plume its 40 u, the dust its 12 u and the trail 24→56 u — those rows
  cut to the drawn frame's own ink box, so their `world` still reads the object.
- **The one input rule is unchanged**: `game.gd:_push_speedometer` still computes
  `|v| / v_max` once and pushes it to `speed_fantasy`, `PlayerShip` and the HUD; nothing in
  this pass recomputes it, and no gameplay number (damage, cadence, range, energy, fuel,
  mass, §13) moved — the diff is presentation only.

## 6. Owner ticks raised by this pass

1. **The vignette's blend** (§5): alpha per your ruling, with the measured 0.41× strength
   cost; one line back to additive if the ember wash should read as it did.
2. **The mine's own rate**: the four frames loop at `Fx.DEFAULT_FPS` 20 (the helper's
   documented fallback) because no doc gives the mine's sequence a rate; one constant.
3. **`weapons.gd`'s flash size/offset** (§5) and the **menu's v1 plate** (§5) — two
   one-line lanes outside this worker's set.
4. Everything S2 raised in its §6 still stands: the bed's take, the trail's width (now 6 u
   as specced), the dust's blend (now alpha, as specced), and L66's death freeze.

## 7. State of my artifacts

- Changed shipped files (`git diff --numstat`): `autoload/audio_manager.gd` **+52/-0**,
  `game/fx.gd` **+118/-21**, `game/projectile.gd` **+235/-156**,
  `game/speed_fantasy.gd` **+17/-22**. Every deleted line is an old row read
  (`&"texture"`/`&"regions"`), an `additive_material()` call or the `_texture_of` helper;
  no pinned signature, no gameplay value and no FX_SPEC number was removed. Changed
  tests/probes:
  `test_slice2_5_feel.gd`, `test_weapon_fx_f1.gd`, `test_weapon_fx_f2.gd`,
  `test_weapon_fx_f4.gd`, `test_flight_beam_g2.gd`, `probe_s2_5_feel.gd`,
  `probe_s2_5_review.gd`, `probe_s2_5_review_pixels.gd`, `probe_s2_5_trail_draw.gd`. New:
  `probe_s3_levers`, `probe_s3_trail_quad`, `probe_s3_rewire`, `probe_s3_mine` (+ `.tscn`).
- Evidence: `.agents/gen/slice2_5_s3_gate.txt`, `_voice_{before,after}.txt`,
  `_trail_draw_{before,after}.txt`, `_trail_quad.txt`, `_levers.txt`, `_rewire.txt`,
  `_mine.txt`, `_mine_frames.png`, `_review_{before,after}.txt`,
  `_pixels_{before,after}.txt`, `_s1_probe_after.txt`, `_s1_pixels_after.txt`,
  `_node_scale_after.txt`, `_shot.txt`, `_shot_trail_{after,diff}.png`.
- Nothing is staged, committed or pushed by me. The only workspace file outside
  `vajb-orbit/` and `.agents/gen/` that this pass touched is nothing at all.
