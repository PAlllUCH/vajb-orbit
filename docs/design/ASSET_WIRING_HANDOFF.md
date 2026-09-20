# Vajb Orbit - asset wiring handoff

**Written 2026-09-17 for the Phase C coding agent.** Asset generation is done: Phase B, D and E
art plus the new audio family are on disk, imported, and indexed. What is missing is **binding** -
almost none of it is referenced from code yet. This document is the contract for doing that
without re-deriving paths, and it records the two mismatches between the written audio spec and
the audio code that is already live.

Read this together with:

- `docs/design/ASSET_CATALOG.md` - every shipped file, pixel size, alpha mode, phase tag, purpose.
  Generated from the filesystem; never hand-edited.
- `docs/design/IMPLEMENTATION_PLAN.md` section 3.8 - the cue resolution rule the code implements.
- `vajb-orbit/ui/paths.gd` - `AUDIO_DIRS` (the flat per-bus dirs) and `AUDIO_BUSES`.
- `docs/design/AUDIO_SPEC.md` - the design intent for every cue (sections 2 and 3), plus the
  amendments recorded in section 8 that this handoff depends on.

Counts: **317 art files** (Phase B 109 / D 141 / E 67) and **95 audio files** (music 6, sfx 62,
ui 11, ambience 16).

---

## 1. Audio - the resolution contract that already exists

`AudioManager._load_cue()` resolves a cue as:

```
res://assets/audio/<bus-dir>/<cue>.ogg          # exact match wins
res://assets/audio/<bus-dir>/<cue>_01.ogg       # fallback
```

There is **no round-robin, no random pitch and no per-variant loading** in `AudioManager` today:
one cue name resolves to exactly one file. Round-robin/variant behaviour is AUDIO_SPEC section 4.1
and has to be built (a small `SfxPool`), which is why the extra variants below exist on disk but
are not reachable through a single cue name.

Bus directories are **flat**: `music/`, `sfx/`, `ui/`, and `ambience/` (added this pass; not in
`Paths.AUDIO_DIRS` yet). AUDIO_SPEC section 6 originally described a nested feature tree
(`sfx/weapons/`, `ui/clicks/`, ...) - the implemented loader cannot resolve that, so the
category prefix in every filename carries the grouping instead. Amendment recorded in
AUDIO_SPEC section 8.

### 1.1 Cues that work today

Every cue below resolves with a plain `AudioManager.play_sfx(&"<cue>")` /
`AudioManager.play_ui(AudioManager.UiCue.CLICK)`. Path = `res://assets/audio/<bus>/<cue>_01.ogg`,
except the two marked *exact*, which resolve to `<cue>.ogg`.

| Bus | Cue | Cue purpose |
|---|---|---|
| `ui` | `ui_click` (*exact*) | S9 button press - already called by the menu controller |
| `ui` | `ui_hover` (*exact*) | S10 button hover - already called by the menu controller |
| `ui` | `ui_confirm`, `ui_denied`, `ui_scroll` | confirmation, blocked action, menu scroll |
| `sfx` | `sfx_weapon_laser`, `sfx_weapon_cannon`, `sfx_weapon_rocket`, `sfx_weapon_explosion` | S1/S2/S3 weapons |
| `sfx` | `sfx_impact_rock`, `sfx_impact_hull`, `sfx_impact_shield_hit`, `sfx_impact_shield_loop` | S4/S5/S6 impacts and shield |
| `sfx` | `sfx_mining_beam`, `sfx_mining_chip` | S7/S8 mining |
| `sfx` | `sfx_ship_jump`, `sfx_ship_boost`, `sfx_ship_engine` | S11/S12/S16 jump, boost, thruster |
| `sfx` | `sfx_station_machine_loop`, `sfx_station_boiler_loop`, `sfx_station_hum_loop` | S18 machinery layers |
| `sfx` | `sfx_station_power_off`, `sfx_station_breaker_on`, `sfx_station_breaker_off` | S19 blackout |
| `sfx` | `sfx_station_hull_groan`, `sfx_station_hull_ring`, `sfx_station_hull_crack` | S20 hull stress |
| `sfx` | `sfx_stinger_boss_roar`, `sfx_stinger_scare`, `sfx_stinger_rumble_pass`, `sfx_stinger_anomaly` | S21-S24 stingers |

43 cues in total. `staging/audio/list_cues.py` prints this mapping mechanically (file by file,
including variants) - run it after any change to the audio tree.

### 1.2 Variants on disk that need code to reach them

These are the extra takes the spec's round-robin rules need. Today they are only reachable by
passing the full filename stem as the cue (`play_sfx(&"sfx_weapon_laser_02")`), because
`AudioManager` has no pool.

| Group | Files | Note |
|---|---|---|
| Laser variants 02-04 | `sfx_weapon_laser_{02,03,04}.ogg` | S1 round-robin pool (pitch +/-10 %, vol -3..0 dB) |
| Cannon tiers | `sfx_weapon_cannon_{02_medium,03_long}.ogg` | S2 tier 2/3; cue `sfx_weapon_cannon` is tier 1 |
| Rocket warhead layer | `sfx_weapon_rocket_02_warhead.ogg` | S3 +80 ms after the launch layer |
| Explosion pool | `sfx_weapon_explosion_{01,02}.ogg` | generic explosion fills |
| Hull impacts 02-05 | `sfx_impact_hull_{02..05}.ogg` | S4 foley pool |
| Shield hits 02-09 | `sfx_impact_shield_hit_{02..09}.ogg` | S5 pool (cue resolves to take 01) |
| Mining chips 02-04 | `sfx_mining_chip_{02,03,04}.ogg` | S8 chip transients (loop: cue is 01) |
| Engine bed 02 | `sfx_ship_engine_02_loop.ogg` | S16 alternative thruster (rocket-engine sample) |
| Machine loops 02-03 | `sfx_station_machine_loop_{02,03}.ogg` | S18 layered bed |
| Hull ring 02-03, crack 02-03 | `sfx_station_hull_ring_{02,03}.ogg`, `sfx_station_hull_crack_{02,03}.ogg` | S20 composite layers |
| Scare 02, anomaly 02-03 | `sfx_stinger_scare_02.ogg`, `sfx_stinger_anomaly_{02,03}.ogg` | S22/S24 variety |
| UI click 02-05, hover 02-03 | `ui_click_{02..05}.ogg`, `ui_hover_{02,03}.ogg` | UI pool; pitch randomization must stay within +/-5 % |

Unclassified pool: `amb_space_misc_{01..05}.ogg` - five cues cut from the *7 Space Sounds* source.
The OGA page advertises seven; only five are separated by silence, and the two long chunks may
each hold more than one cue. Audition and split further if a specific sound is wanted.

### 1.3 Music and ambience: the one real code gap

`AudioManager` exposes `play_ui()` and `play_sfx()` only - there is **no music or ambience API**,
so the 6 music beds and 16 ambience beds cannot be played through it at all (they are not in
`Paths.AUDIO_DIRS` either, except `music/`). Recommended shape, consistent with the existing
services:

```
AudioManager.play_music(&"mus_menu_theme")     # crossfades, Music bus
AudioManager.play_ambience(&"amb_space_drone") # layered, World/ambience bus
```

Paths, for a direct `load()` if you prefer to keep the service untouched:

| Cue | Path | Role |
|---|---|---|
| `mus_menu_theme` | `res://assets/audio/music/mus_menu_theme_01.ogg` | M1 menu theme |
| `mus_exploration_ambient` | `res://assets/audio/music/mus_exploration_ambient_01.ogg` | M2 exploration bed |
| `mus_exploration_dread` | `res://assets/audio/music/mus_exploration_dread_01.ogg` | M5 dread bed |
| `mus_combat_loop` | `res://assets/audio/music/mus_combat_loop_01.ogg` | M3 combat |
| `mus_boss_metal_01_opening` | `res://assets/audio/music/mus_boss_metal_01_opening.ogg` | M4 one-shot intro |
| `mus_boss_metal_01_loop` | `res://assets/audio/music/mus_boss_metal_01_loop.ogg` | M4 loop (starts on `finished`) |
| `amb_space_drone` | `res://assets/audio/ambience/amb_space_drone_01.ogg` | dead-ship sector drone |
| `amb_space_wind` | `res://assets/audio/ambience/amb_space_wind_01.ogg` | open-space wind bed |
| `amb_space_rumble` | `res://assets/audio/ambience/amb_space_rumble_{01,02}.ogg` | capital-ship / deep rumble |
| `amb_space_float` | `res://assets/audio/ambience/amb_space_float_{01,02}.ogg` | floating ambience |
| `amb_space_misc` | `res://assets/audio/ambience/amb_space_misc_{01..05}.ogg` | unclassified space cues |
| `amb_station_room` | `res://assets/audio/ambience/amb_station_room_{01,02,03}.ogg` | station room tones |
| `amb_station_pump_loop` | `res://assets/audio/ambience/amb_station_pump_loop_01.ogg` | machinery room bed |
| `amb_station_noise_loop` | `res://assets/audio/ambience/amb_station_noise_loop_01.ogg` | static bed |

Buses already match AUDIO_SPEC section 4.3 (built by `AudioManager._build_buses()` and verified in
the Phase C report): `Master`, `Music`, `SFX` (+ `SFXWeapon`, `SFXImpact`, `SFXWorld`), `UI`, with
defaults master 0 dB, music -8 dB, sfx -6 dB, ui -10 dB. Assign `Music`/`ambience` players to the
`Music` bus and world beds to `SFXWorld` (the sub-buses are created but nothing routes to them yet).

### 1.4 Loop flags

25 files are loop-material and must import with `loop = true`. `staging/audio/set_loop_flags.py`
patches their `.import` sidecars from the build report, and the final import pass was verified by
loading every stream through the engine (`SUMMARY total=95 looping=25 missing=0`). If a file is ever
reimported from scratch, re-run that script and reimport; the verified loop set is:

- `music/`: all six `mus_*` beds except `mus_boss_metal_01_opening`.
- `ambience/`: all 16 files.
- `sfx/`: `sfx_impact_shield_loop_01`, `sfx_mining_beam_01`, `sfx_ship_engine_01`,
  `sfx_ship_engine_02_loop`, `sfx_station_machine_loop_{01,02,03}`, `sfx_station_boiler_loop_01`,
  `sfx_station_hum_loop_01`.

Everything else is a one-shot with `loop = false`.

### 1.5 Known audio limitations (accepted, not defects to fix in code)

- Six loop beds were loop-prepared automatically (dead air trimmed, tail crossfaded into the head,
  2 s crossfade, level-continuous seam verified numerically). Three still measure a seam above
  3 dB: `mus_exploration_dread_01` (11.1 dB), `amb_space_float_01` (5.0 dB, repair reverted because
  it made the seam worse) and `mus_boss_metal_01_loop` (3.9 dB). They are long beds whose head and
  tail content genuinely differ; polishing them is an ear-level sound-design pass, not a wiring
  task. Details per file: `vajb-orbit/assets/audio/generation_log_audio.md`.
- Loop seams were verified numerically (first vs last 50 ms level), never by ear.
- Every source is CC0; provenance (pack, author, URL, checksum) is in
  `asset-library/ASSET_MANIFEST.json` and the generation log. Nothing requires attribution.

---

## 2. Art that is shipped but not bound

These families exist and import cleanly; they are the cheapest content to add because they need
code, not generation. Suggested consumers are proposals - the gameplay decision is yours.

| Family | Files | Suggested consumer |
|---|---|---|
| Station-scale bases | `env/env_base_{mining,trade,defense,shipyard}.png` (1.1-2.0 kpx, RGBA) | Sector POIs: dockable at bases; draw at roughly 2x hull scale |
| Outposts | `env/env_outpost_{mining,defense,relay,repair}.png` (0.6-1.9 kpx, RGBA) | Smaller satellite POIs, contested-sector objectives |
| Airless bodies | `env/env_body_{ice_moon,ore_moon,shattered}.png`, `env/env_bg_body_plate.png` (16:9 RGB) | World props and a parallax body layer |
| Rock look 2 | `env/env_asteroid_b{1..6}.png` | Second asteroid set, doubles field variety against the Phase B rocks |
| Mine | `env/env_mine.png` | Deployed mine world object (not a backdrop) |
| Wrecks and props | `env/env_wreck_hulk.png`, `env/env_station_ruined.png`, `env/env_prop_*` (9 fragments) | Salvage/debris POIs, composite wreck layouts |
| Boosters | `icons/icon_booster_{speed,damage,shield,repair,emp,teleport}_{16,48}.png` | Consumable booster slots (48 px) and the compact strip (16 px) |
| Status effects | `icons/icon_status_{burning,slowed,disabled,shielded,repairing,locked,cloaked,radiated,drained}_{16,48}.png` | HUD status strip |
| Sector backdrop | `env/env_bg_body_plate.png` | Parallax layer behind the star layers |
| Screen backdrops | `ui/ui_backdrop_{hangar,login,starmap}.png` (16:9 RGB) | Future hangar / company-select / starmap screens |
| Insignia | `ui/ui_insignia_{mic,mmo,ven,neutral}.png` | Company selection, HUD sector plate |
| Hangar chrome | `ui/ui_panel_frame.png`, `ui/ui_slot_inventory_*.png` | Inventory/equipment panels (flagged unconsumed in the Phase C report) |

Multi-frame FX sheets (already sliced: `fx_explosion` 5 frames, `fx_mining_beam` 4, `fx_muzzle_flash`
4, `fx_missile_trail` 4, `fx_shield_break` 4; the rest are single frames) are **RGB on void black**:
blend them additively, never with alpha blending.

---

## 3. Consumer rules (do not invent alternatives)

1. **Sprites are pre-cut RGBA.** Phase B/D/E silhouettes were matted locally; do not add a
   colour-key or shader cutout.
2. **FX and backdrops are RGB**, meant for additive blending on the void background.
3. **Rotation views** follow the shipped naming: `_front` bow up, `_back` bow down, `_side` bow
   right, `_three_quarter` bow 45 deg. Rotate hulls in code from the 3/4 view rather than
   generating new angles.
4. **Tinting:** only `icons/tint/*` (40 derived white stencils from the Phase B flat glyphs) accept
   `modulate`. The painted Phase D/E icon splits are full-colour - tinting them muddies the palette.
5. **Never reference** from code: `assets/style-block.txt`, `assets/*/20260917-*/` run folders,
   `panel_*.png` masters, `generation_log*.md`, or `icons/tint/` source PNGs outside a shader.
6. Palette and value rules are in `docs/design/STYLE_BIBLE.md`; new UI must use
   `res://ui/theme/vajb_theme.tres` rather than raw colours.

---

## 4. Acceptance checks after wiring

- Every new `preload`/`load` resolves: run the affected scene headless, zero `ERROR: Cannot open
  file` / `Resource file not found`.
- With audio enabled, hover and press a menu button: two distinct UI cues audible through the `UI`
  bus at the settings volume.
- Fire a weapon, take an impact and mine once: three distinct `sfx` cues audible.
- Music: at least one bed playing in the game scene, on the `Music` bus, unaffected by UI volume.
- Loop check by ear on `sfx_ship_engine_01`, `sfx_mining_beam_01` and `mus_combat_loop_01`.
- Report anything still unbound deliberately, so it does not read as an omission later.
