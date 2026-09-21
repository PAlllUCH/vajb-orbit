# Vajb Orbit — Audio Spec

Final audio design for the 2D top-down Dark Orbit-style shooter. Locked policy:
**CC0 sources only + procedural layering in Godot**; no paid audio services, no CC-BY / OGA-BY assets.

Sources of truth for every named candidate:
- `docs/assets/research/audio.md` (weapons, mining, impacts, shields, ambience, light combat)
- `docs/assets/research/grimdark_audio.md` (dread drones, industrial, rumble, hull, dark combat, stingers)

Every URL below is copied verbatim from those files. Anything not confirmed there is marked
**TODO for confirmation**. Nothing has been downloaded yet.

Fit scores are inherited from the research files (5 = drop-in, 4 = strong/light processing,
3 = usable after pitch/tone work).

---

## 1. Design direction (grimdark)

Space is hostile, dead, and huge. Audio pillars:

1. **Dread beds over melodies.** Music is drone/dark-ambient-first; combat adds rhythm, not fanfare.
2. **Layered reality.** Most cues are composites of 2-3 CC0 layers processed in Godot
   (pitch, low-pass, volume), not single drop-in sounds.
3. **Reactivity.** Sector state (safe → contested → boss) crossfades music layers; no hard track cuts.
4. **Retro-adjacent but not retro.** Kenney packs provide clean digital SFX; foley packs get pitched
   down / filtered so nothing reads as "wood in space".

---

## 2. Music track list

All music buses through the `Music` bus (see §4). Loops import as OGG with `loop = true`
(see §5.2 for MP3/FLAC conversion).

| # | Role | Primary CC0 candidate | Fit | Direct download | Fallback |
|---|------|----------------------|-----|-----------------|----------|
| M1 | Main menu theme | *I swear I saw it — background track* (yd) — dark/mystery/space ambient loop, same tonal family as the owned *Space Graveyard* | 5 | https://opengameart.org/sites/default/files/IswearIsawit_0.ogg | *EmptyCity* (yd), OGG 2 MB, fit 5: https://opengameart.org/sites/default/files/EmptyCity.ogg |
| M2 | Exploration ambient loop | *Factory ambiance* (yd) — industrial-ruins bed, "Fallout 2 Vault Archives" register | 5 | https://opengameart.org/sites/default/files/Factory.ogg | *Outpost* / *The World Fell Silent* loop renders (FLAC → convert): https://opengameart.org/sites/default/files/outpost_loop.flac · https://opengameart.org/sites/default/files/the_world_fell_silent_loop.flac |
| M3 | Combat loop | *Fast fight / battle music (looped)* (Ville Nousiainen, loop edit by XCVG) | 5 | https://opengameart.org/sites/default/files/fight_looped.wav | *Hunter-class Lifeform* (Vitalezzz), MP3/WAV, fit 5: https://opengameart.org/sites/default/files/hunter-class_lifeform_1.mp3 (WAV master listed on the same page) |
| M4 | Danger / boss layer + boss theme | *Boss Battle #9 [Metal]* (nene) — already split into opening + loop, the exact intro+loop structure Godot needs | 4 | https://opengameart.org/sites/default/files/boss_battle_9_metal_opening.wav · https://opengameart.org/sites/default/files/boss_battle_9_metal_loop.wav | *Hunter-class Lifeform* as the grimdark combat tier above M3; *Dark Intro* (Nikke) as sector-entry sting into a boss: https://opengameart.org/sites/default/files/Dark%20Intro_0.ogg |
| M5 | Sector dread bed (low layer under M2/M3) | *Horror Atmosphere* (Juhani Junkala / SubspaceAudio) — 5:23 seamless OGG loop | 5 | https://opengameart.org/sites/default/files/Juhani%20Junkala%20-%20Post%20Apocalyptic%20Wastelands%20%5BLoop%20Ready%5D.ogg | *Ambience Pack 1 — Sci Fi Horror* (Joth), 5 tracks, MP3-only → convert: https://opengameart.org/sites/default/files/The%20Surreal%20Truth.mp3 · https://opengameart.org/sites/default/files/Infestation%20in%20the%20Control%20Room.mp3 · https://opengameart.org/sites/default/files/Final%20Captain%27s%20Log.mp3 · https://opengameart.org/sites/default/files/The%20Depths%20of%20Hell.mp3 · https://opengameart.org/sites/default/files/Cage%20of%20the%20Cryptid.mp3 |
| M6 | Alien-artifact / anomaly zone (optional tier) | *Dissonance Anthem* (Some Weirdo) — 21 min microtonal drone, trim first minutes | 4 | https://opengameart.org/sites/default/files/dissonance_anthem.ogg | *Dark Shrine Loop* (qubodup remixing yd): https://opengameart.org/sites/default/files/qubodup-yd-DarkShrineLoop-OpenGameArt.ogg |

Notes:
- Combat has only one genuine CC0 "fast battle" track per research; combat tiers are built as
  M3 (fast) + M4 (boss) + M6 (anomaly) instead of hunting more combat tracks.
- Boss Battle #2 [Symphonic Metal] (nene) is an audition-only reserve; its archive has swapped
  inner filenames (documented in research). URL: https://opengameart.org/sites/default/files/boss_battle_%232_metal_pack.zip
- yd tracks ship LMMS sources, so stems can be re-mixed per sector without leaving CC0.

### Music state machine (reactivity)

```
safe ────────► contested ────────► boss
M5 + M2 (low)   M5 + M2 + M3       M4 (opening → loop)
   crossfade 2 s on all transitions; never hard-cut music
```

---

## 3. SFX inventory

Shorthand: **[P]** = procedurally layered in Godot from the named CC0 layers; **[D]** = direct
drop-in from the named source. All SFX route to the `SFX` or `UI` bus (§4).

| # | Cue | Build | Primary candidate(s) | Direct download |
|---|-----|-------|----------------------|-----------------|
| S1 | Lasers (player light/medium) | **[P]** round-robin of 3-4 laser/phaser one-shots, pitch ±10 %, vol ±3 dB | *63 Digital sound effects (Kenney)* — 9 lasers, 15 phasers, WAV ZIP: https://opengameart.org/sites/default/files/Digital_SFX_Set.zip — plus already-owned Kenney Sci-Fi Sounds (de-duplicate by ear first) | |
| S2 | Heavy cannon | **[D]** *Doomsday Laser Cannon* (TAD): short + medium for turret tiers, long = doomsday charge-up | https://opengameart.org/sites/default/files/doomsday_laser_cannon_short.wav · https://opengameart.org/sites/default/files/doomsday_laser_cannon_midium_.wav · https://opengameart.org/sites/default/files/doomsday_laser_cannon_long.wav | |
| S3 | Rockets (launch + detonation) | **[P]** rocket layer (fit 4) + bang layer for the warhead | *50 CC0 Sci-Fi SFX* (rubberduck) ZIP: https://opengameart.org/sites/default/files/sci-fi-sfx.zip · *25 CC0 bang / firework SFX* ZIP: https://opengameart.org/sites/default/files/25-CC0-bang-sfx.zip | |
| S4 | Asteroid / hull impacts | **[P]** foley impact pitched down 15-40 % + synthetic sub-thump from owned Kenney Sci-Fi Sounds | *Kenney Impact Sounds* (130 WAV, ZIP): https://kenney.nl/media/pages/assets/impact-sounds/87b4ddecda-1677589768/kenney_impact-sounds.zip · secondary layer *75 CC0 breaking / falling / hit sfx* ZIP: https://opengameart.org/sites/default/files/sfx_breaking_and_falling.zip · dedicated asteroid cue *7 Space Sounds* (Joth), single MP3, trim first: https://opengameart.org/sites/default/files/7%20Space%20Sounds_1.mp3 | |
| S5 | Shield hits | **[D]** *Space Ship Shield Sounds* (bart), set of starship shield SFX + FL source for re-voicing | https://opengameart.org/sites/default/files/space%20shield%20sounds.zip | |
| S6 | Shield-up / barrier hum | **[D]** *Seamless Energy Emission Loop* | https://opengameart.org/sites/default/files/movingshield_sound.ogg | |
| S7 | Mining beam loop | **[P]** beam bed + chip transients; pitch per asteroid tier | *Seamless Energy Emission Loop* (beam bed): https://opengameart.org/sites/default/files/movingshield_sound.ogg · *Mining sample* (jordan4ibanez, OGG): https://opengameart.org/sites/default/files/mining_1.ogg | |
| S8 | Mining chip hit | **[D]** *Mining sample* as one-shot, randomized pitch | https://opengameart.org/sites/default/files/mining_1.ogg | |
| S9 | UI click | **[D]** Kenney Interface Sounds (already owned) | TODO for confirmation: exact file inside the owned pack | |
| S10 | UI hover / menu scroll | **[D]** *7 Space Sounds* contains a menu-scroll cue (needs trim) + owned Kenney Interface Sounds | https://opengameart.org/sites/default/files/7%20Space%20Sounds_1.mp3 | |
| S11 | Teleport / jump (1) | **[D]** 2 teleport cues in *50 CC0 Sci-Fi SFX* ZIP | https://opengameart.org/sites/default/files/sci-fi-sfx.zip | |
| S12 | Teleport / jump (2) / boost | **[D]** *Rocket launch* (qubodup) — take-off/boost character, 7z with WAV + Audacity source | https://opengameart.org/sites/default/files/launch.7z | |
| S13 | Space sector ambience (dead-ship drone) | **[D]** *Background space track* (yd), OGG + LMMS source | https://opengameart.org/sites/default/files/projects.zip | |
| S14 | Open-space emptiness / wind bed | **[D]** *Space Winds* (MP3 → convert to OGG) | https://opengameart.org/sites/default/files/space-wind_0.mp3 | |
| S15 | Capital-ship / engine-room rumble | **[D]** *underwater or space engine rumble* (gmason), OGG loop-ready | https://opengameart.org/sites/default/files/underwater_or_space_engine_0.ogg · https://opengameart.org/sites/default/files/deep_rumble.ogg | |
| S16 | Thruster / engine loop (player) | **[D]** *Thruster* (EZduzziteh, OGG) or *Rocket Engine* (WAV); redundant with owned Kenney engine beds — audition both | https://opengameart.org/sites/default/files/space_ship_0.ogg · https://opengameart.org/sites/default/files/rocket_engine.001.wav | |
| S17 | Starship floating ambience bed | **[D]** *Space ship floating sounds(2)*, 2 MP3 beds → convert | https://opengameart.org/sites/default/files/space_ship_floating_sound_1.mp3 · https://opengameart.org/sites/default/files/space_ship_floating_sound.mp3 | |
| S18 | Station machinery loop | **[P]** three-layer bed: machine loops + boiler body + electrical hum | *30 CC0 SFX loops* (11 machine loops): https://opengameart.org/sites/default/files/sfx_loops.zip · *Steam boiler sound loop* (bart): https://opengameart.org/sites/default/files/generator_loop.wav · *Electronic device loop* (FLAC → convert): https://opengameart.org/sites/default/files/qubodup-edev.flac | |
| S19 | Station blackout / power-loss event | **[D]** *Machine shutting down* (OGG, tiny) + *SFX — Circuit breaker* (ON/OFF takes) | https://opengameart.org/sites/default/files/MachinePowerOff.ogg · https://opengameart.org/sites/default/files/Circuit%20Breaker.zip | |
| S20 | Hull groans / creaks | **[P]** Tree Creaking (body, pitched down 20-40 %) + Metal Interactions (ring) + Deep Bone Crack (fracture); pitch ±10 %, low-pass ~120 Hz | *Tree Creaking*: https://opengameart.org/sites/default/files/tree_creak_0.ogg · *Metal Interactions* (7z): https://opengameart.org/sites/default/files/metal_interactions.7z · *Deep Bone Crack/Break SFX* (10 cracks): https://opengameart.org/sites/default/files/deep_breaks.zip | |
| S21 | Boss arrival stinger | **[P]** *CC0 Deep Monster Roar* + sub-thump layer (Kenney Sci-Fi Sounds) | https://opengameart.org/sites/default/files/monster_roar.wav | |
| S22 | Horror scare stinger | **[D]** *Horror SFX* (TinyWorlds), 2 dark stabs | https://opengameart.org/sites/default/files/horror_sfx.zip | |
| S23 | "Something huge is near" pass-by | **[D]** *rumble fx* (19 s rumble with built-in fades) | https://opengameart.org/sites/default/files/rumble.wav | |
| S24 | Anomalous-energy stinger (optional) | **[D]** *3 dark magic spells* — purely synthetic despite fantasy naming | https://opengameart.org/sites/default/files/dark_magic.7z | |
| S25 | Derelict-station room tone (optional tier) | **[D]** *Ambience Pack 1 — Sci Fi Horror* cut per room (MP3 → convert); deeper room packs: Nihilex *Underground Facility Ambient Pack* (itch.io, pay-what-you-want, CC0) | https://opengameart.org/sites/default/files/The%20Surreal%20Truth.mp3 (et al., see M5) · https://nihil-existentia.itch.io/free-audio-asset-collection/purchase | |

Open questions (all **TODO for confirmation**):
- Exact UI click/hover files inside the already-owned Kenney Interface Sounds pack.
- Whether S16 engine beds duplicate the owned Kenney Sci-Fi Sounds engines closely enough to skip.
- Inner formats of the ZIP/7z archives (not stated on pages): *50 / 60 CC0 Sci-Fi SFX*,
  *25 CC0 bang*, *Space Ship Shield Sounds*, *30 CC0 SFX loops*, *Horror SFX*, *Deep Bone Crack*,
  *Metal Interactions* (7z), *dark magic* (7z), *Rocket launch* (7z), *68 Workshop Sounds* (7z),
  *Kenney Impact Sounds* (ZIP of WAV per Kenney convention).
- Whether the *60 CC0 Sci-Fi SFX* archive passes integrity checks (a commenter reported a
  corrupted download): https://opengameart.org/sites/default/files/60-sci-fi-sfx_0.zip

---

## 4. Procedural layering rules (Godot)

### 4.1 Round-robin variants

Godot 4 has no native round-robin; build a small `SfxPool` (Node) that preloads N `AudioStreamPlayer`
children per cue and cycles `pitch_scale` / `volume_db` per trigger.

Rules:
- **Pitch round-robin:** one-shot weapons/impacts get 3-4 variants drawn from the pack
  (e.g. Kenney's 9 lasers) or a single source re-pitched. Per-trigger pitch:
  `pitch_scale = base * randf_range(1.0 - spread, 1.0 + spread)`,
  spread 0.10 for weapons/impacts, 0.05 for UI (UI never goes above ±5 %).
- **Volume round-robin:** per-trigger `volume_db = base_db + randf_range(-3.0, 0.0)` for combat
  cues; UI one-shots stay fixed volume.
- **No immediate repeats:** keep the last used variant index; skip it on the next trigger when
  `N > 2`.
- **Anti-flam:** minimum 30 ms between triggers of the same cue; overlapping triggers steal the
  oldest playing voice.
- **Cap:** every `SfxPool` has a max concurrent voices (weapons 4, impacts 6, mining 1, UI 2);
  excess triggers are dropped, not queued.

### 4.2 Layered composite cues

Composite cues (S3, S4, S7, S18, S20, S21) are assembled as sibling players with
per-layer `pitch_scale` and an optional `AudioEffectLowPassFilter` / `AudioEffectEQ` on a
dedicated effect bus:

| Cue | Layer recipe |
|-----|--------------|
| S3 rocket | rocket launch (as-is) + bang warhead (-6 dB, pitch 0.85) |
| S4 asteroid impact | foley impact (pitch 0.60-0.85) + sub-thump (pitch 0.5, -9 dB) |
| S7 mining beam | energy loop (looping, pitch per asteroid tier 0.8/1.0/1.2) + chip one-shot every 0.4-0.8 s (random) |
| S18 station machinery | machine loop (as-is) + boiler (looping, -6 dB) + device hum (looping, -12 dB) |
| S20 hull groan | tree creak (pitch 0.6-0.8) + metal hit ring (as-is, -6 dB) + bone crack (pitch 0.7, low-pass 120 Hz) |
| S21 boss stinger | monster roar (as-is) + sub-thump (pitch 0.5, -6 dB) |

Layer timing offsets use `AudioStreamPlayer.play(from_position)` with deliberate `from_position`
delays (warhead +80 ms after launch, fracture +120 ms after groan body).

### 4.3 Bus layout (AudioServer)

```
Master
├── Music
│   └── MusicDuck (sidechained, see below)          [optional; TODO confirm]
├── SFX
│   ├── SFXWeapon      (lasers, cannon, rockets)
│   ├── SFXImpact      (asteroid/hull impacts, shield hits)
│   └── SFXWorld       (mining, engines, station machinery, groans, stingers)
└── UI                 (clicks, hovers, menu sounds; never ducked, fixed volume)
```

- Set up in code at startup (default_bus_layout.tres **TODO for confirmation** on whether to ship
  one or build buses in an autoload):
  `AudioServer.add_bus()`, `AudioServer.set_bus_name()`, `AudioServer.set_bus_send()`.
- **Music ducking:** when a boss stinger (S21/S22) or boss theme (M4) fires, lower `Music` by
  -6 dB over 0.3 s and restore over 1.5 s (tween the bus volume or use an `AudioEffectHardLimiter`
  with sidechain **TODO for confirmation** — manual tween is the simpler default).
- **Mixing levels (starting point, tune by ear):** Music -8 dB, SFX -6 dB, UI -10 dB, Master 0 dB.
- UI bus ignores ducking and never applies pitch randomization above ±5 %.

### 4.4 Crossfade rules for music states

- All music players are `AudioStreamPlayer` on the `Music` bus, always playing their assigned
  loop (players are cheap; no dynamic stream swapping mid-playback).
- State changes tween `volume_db` over 2.0 s on both outgoing and incoming players.
- Boss entry: M4's *opening* part plays as a one-shot, then the *loop* part starts on
  `finished` — the nene asset is pre-split exactly this way.

### 4.5 Held state beds (amendment 2026-09-21)

A **bed** is a looping stream that belongs to a held state, not to an event. The
player's own ship needs three of them at once, and `AudioManager` holds them as
per-bed voices with a priority, a lease and a cue-scoped stop
(`LOOP_VOICE_COUNT` **3**, `LOOP_LEASE` 1.2 s, `LOOP_PRIORITY`) — a bed that is
re-asked every frame it is held never expires, and a bed nobody re-asks is
released.

| Bed | Cue | Priority | Curve |
|---|---|---|---|
| Shield hum | `sfx_impact_shield_loop` (S6) | **2** | as-is while a shield hit is recent |
| Mining beam | `sfx_mining_beam` (S7) | **1** | pitch per asteroid tier 0.8/1.0/1.2 (§4.2) |
| **Thruster** | `sfx_ship_engine_01` (S16) | **1** | see below |
| Thruster, alternative take | `sfx_ship_engine_02_loop` (S16b) | — | the one-constant swap: the owner auditions `_01` against `_02_loop` and only the bed's cue name changes |

**Thruster bed curve (proposed — the owner's audition and the playtest tune it).**
Held while the thrust input is down **or** `speed_ratio ≥ 0.15` (engine spec
§3.4's single input), with hysteresis: on at **0.15**, off below **0.10**, so a
drifting hull keeps its hum and a standstill does not chatter.

| Field | Value | Reversal |
|---|---|---|
| `pitch_scale` | 0.85 at ratio 0.15 → 1.15 at 1.0 (linear) | one constant pair |
| `volume_db` | −24 dB at ratio 0.15 → −12 dB at 1.0 | one constant pair |
| Re-ask | every frame while held (the lease model) | — |

One-shots that pair with a bed keep their own rows: **S12**
(`sfx_ship_boost_01`, `loop = false`) fires once on **booster activation** — the
afterburner's own activation in v1, since `b_fold`'s movement is slice 4's — and
its take is the cue the station already plays at launch, so no second asset is
owed.

---

## 5. Format, conversion and looping

### 5.1 OGG conversion requirement

Godot 4 imports MP3, but MP3 has **no sample-accurate loop points** — looping MP3s will click
or drift at the seam. Therefore:

- Every MP3-sourced candidate used as a **loop** must be converted to OGG before import
  (ffmpeg/loudness-matched encode is fine).
- Affected primary assets: *Space Winds* (S14), *floating sounds* (S17), *7 Space Sounds* (S4, S10),
  *Ambience Pack 1* (M5/S25), *Hunter-class Lifeform* MP3 variant (M3 fallback — prefer the WAV
  master listed on its page), *Downfall* (reserve).
- FLAC (Godot 4 has **no FLAC importer**): *The World Fell Silent* loop renders (M2 fallback),
  *Electronic device loop* (S18) → convert to WAV/OGG before import.
- 7z/ZIP archives with unstated inner formats: extract, inspect, convert anything MP3/FLAC to
  OGG/WAV per the rules above.

### 5.2 Import settings

| Kind | Source format | Import settings |
|------|--------------|-----------------|
| Short one-shots (S1-S8, S9-S12, S19-S22) | WAV preferred | WAV import defaults; loop off |
| Loops (M1-M6, S6, S13-S18, S25) | OGG | `loop = true`, `loop_offset = 0` |
| Long one-shots (stingers M4 opening, S23) | WAV | loop off, no fade edits |
| MP3-sourced loops | (converted) OGG | same as above; verify seam by ear |
| MP3-sourced one-shots | MP3 → trim/convert | convert to OGG or WAV; MP3 may stay only for non-looping one-shots **TODO for confirmation** on policy strictness |

- Verify seamlessness by ear on the two assets advertising it: *Horror Atmosphere* (M5) and
  *Seamless Energy Emission Loop* (S6/S7).
- Trim *7 Space Sounds* (single MP3, 7 cues) into individual files before import.
- Trim *Dissonance Anthem* (21 min) to its first 2-3 minutes before import.
- Keep WAV for short one-shots, OGG for anything looping (research-recommended split).

---

## 6. Import layout and naming convention

All audio lives under `vajb-orbit/assets/audio/`, feature-grouped (project convention).

```
vajb-orbit/assets/audio/
├── music/
│   ├── menu/                  # M1 (+ variants)
│   ├── exploration/           # M2, M5
│   ├── combat/                # M3
│   └── boss/                  # M4 opening + loop, M6
├── sfx/
│   ├── weapons/               # S1, S2, S3
│   ├── impacts/               # S4, S5, S6
│   ├── mining/                # S7, S8
│   ├── ship/                  # S12, S16 (engines, boost, jump)
│   ├── station/               # S18, S19, S20
│   └── stingers/              # S21, S22, S23, S24
├── ui/
│   ├── clicks/                # S9
│   └── hover/                 # S10
└── ambience/
    ├── space/                 # S13, S14, S15, S17
    └── station/               # S25
```

File naming:

```
<category>_<cue>_<variant>[_<descriptor>].<ext>
```

- lowercase snake_case throughout (project file convention)
- `<category>`: `mus`, `sfx`, `ui`, `amb`
- `<cue>`: short kebab-to-snake cue name, e.g. `laser`, `cannon`, `rocket`, `impact_rock`,
  `shield_hit`, `shield_loop`, `mining_beam`, `ui_click`, `jump`, `engine`, `hull_groan`,
  `boss_roar`, `sector_drone`, `menu_theme`
- `<variant>`: zero-padded 2-digit index (`01`, `02`, …); `01` is always the primary/default
- optional `<descriptor>`: `long`, `short`, `loop`, `charge`, `tier1..3`, `lowpass`
- keep the upstream filename fragment in `<descriptor>` only when needed for provenance
  (provenance otherwise lives in `ASSET_MANIFEST.json` / `CREDITS.md`, rebuilt after import
  even though CC0 requires no attribution)

Examples:

```
mus_menu_theme_01.ogg
mus_exploration_ambient_01.ogg
mus_exploration_dread_01.ogg
mus_combat_loop_01.ogg
mus_boss_metal_01_opening.wav
mus_boss_metal_01_loop.wav
sfx_weapon_laser_01.wav
sfx_weapon_laser_02.wav
sfx_weapon_cannon_01_short.wav
sfx_weapon_cannon_02_medium.wav
sfx_weapon_cannon_03_long.wav
sfx_weapon_rocket_01.wav
sfx_impact_rock_01.wav
sfx_impact_shield_hit_01.wav
sfx_impact_shield_loop_01.ogg
sfx_mining_beam_01.ogg
sfx_mining_chip_01.ogg
sfx_ship_jump_01.wav
sfx_ship_engine_01.ogg
sfx_station_machine_loop_01.ogg
sfx_station_power_off_01.ogg
sfx_station_hull_groan_01.wav
sfx_stinger_boss_roar_01.wav
sfx_stinger_scare_01.wav
sfx_stinger_rumble_pass_01.wav
ui_click_01.wav
ui_hover_01.ogg
amb_space_drone_01.ogg
amb_space_wind_01.ogg
amb_station_room_01.ogg
```

Rules:
- One directory per feature, no files at the root of `assets/audio/`.
- Sources download into `asset-library/raw/audio/<pack_name>/` first, then files are moved by
  hand into the tree above (the extractor flattens `subfolder`; see `docs/ASSETS.md`).
- Raw archives are never referenced by the game; only converted/renamed files under
  `vajb-orbit/assets/audio/` are imported.
- Conversion happens between "raw" and "final" steps; converted files keep the final name above.

---

## 7. TODO list (confirmation before import batch)

1. Exact UI click/hover filenames inside owned Kenney Interface Sounds (S9/S10).
2. Engine bed choice: new *Thruster*/*Rocket Engine* vs owned Kenney engines (S16).
3. Whether to ship a `default_bus_layout.tres` or build buses in an autoload (§4.3).
4. Inner formats of all ZIP/7z archives (extract-and-inspect step in the download batch).
5. Integrity check for *60 CC0 Sci-Fi SFX* archive (commenter-reported corruption).
6. MP3 one-shot policy strictness: convert everything to OGG/WAV, or allow MP3 for non-looping
   one-shots only (§5.2).
7. Boss stinger ducking implementation: manual bus-volume tween vs sidechain limiter (§4.3).
8. Whether M6 *Dissonance Anthem* trim length (2-3 min) is acceptable, and whether the
   56.6 MB source is worth its disk cost.
9. Ambience Pack 1 per-sector assignment (which of the 5 tracks maps to which sector mood).
10. Nihilex itch.io packs (S25 deep tier): confirm download size budget (zips 242-867 MB) before
    pulling individual room packs.

---

## 8. Implementation amendments (2026-09-17 - sources downloaded and imported)

The audio family was sourced and imported on this date: **25 CC0 downloads, 14 archives extracted,
95 files shipped** into `vajb-orbit/assets/audio/` (music 6, sfx 62, ui 11, ambience 16). Pipeline:
`staging/audio/build_audio.py` (conversion + QC + generation log), `staging/audio/set_loop_flags.py`
(import sidecars), `staging/audio/list_cues.py` (cue resolution report). Integration contract for
code: `docs/design/ASSET_WIRING_HANDOFF.md`.

Four decisions in this spec changed when it met the code and the real files. **The files on disk
follow this section, not sections 5-6 above.**

### 8.1 Flat per-bus directories, not feature subfolders

`AudioManager._load_cue()` resolves `Paths.AUDIO_DIRS[bus] + cue + ".ogg"`, then
`cue + "_01.ogg"`, and `AUDIO_DIRS` holds three flat dirs. Section 6's nested tree
(`sfx/weapons/`, `ui/clicks/`, ...) can never be resolved by that loader, and changing it would
mean editing verified Phase C code for no user-visible gain. Shipped layout:

```
vajb-orbit/assets/audio/
├── music/       flat - one directory per bus, exactly as AudioManager resolves it
├── sfx/         flat
├── ui/          flat
└── ambience/    flat, new - world beds with no AudioManager route yet
```

The category prefix (`mus_`, `sfx_`, `ui_`, `amb_`) carries the grouping the folders would have.
Section 6's naming convention still stands with one correction: the **primary take of a cue is
`<cue>_01.ogg` with no descriptor**, so the `_01` fallback finds it; descriptors appear only on
variants (`sfx_weapon_cannon_02_medium.ogg`, `sfx_weapon_rocket_02_warhead.ogg`,
`sfx_ship_engine_02_loop.ogg`). 43 cue names resolve today; the rest of the library is a variant
pool that needs the section 4.1 `SfxPool`.

### 8.2 Everything ships as OGG

Section 5.2 kept WAV for short one-shots. The loader hardcodes `CUE_EXTENSION := ".ogg"`, so a WAV
could never be reached by a cue name. All 95 files are Ogg Vorbis: sources already in OGG pass
through bit-exact, PCM/FLAC/MP3 sources are encoded at q5 (music q6) with measurement-based peak
normalisation to -1 dBFS and silence trimmed on one-shots.

### 8.3 Loops are prepared and set at import, not at runtime

Loop candidates were measured (level difference between the first and last 50 ms). Six exceeded
3 dB and were loop-prepared automatically - dead air trimmed, tail crossfaded into the head over
min(2 s, 5 % of length) - bringing the menu theme from 8.5 to 0.2 dB, the dread bed from 63 to
11 dB, the dead-ship drone from 57 to 0.07 dB and the thruster from silence to 2.1 dB. One repair
made its seam worse and was reverted (`amb_space_float_01`, 5.0 dB).

Three beds still measure above 3 dB because their head and tail content genuinely differ:
`mus_exploration_dread_01` (11.1), `amb_space_float_01` (5.0), `mus_boss_metal_01_loop` (3.9).
Polishing those is an ear-level sound-design pass; nothing in code is blocked by them.

The `loop` flag lives in the `.import` sidecars (25 files: all six music beds except the M4
opening one-shot, all 16 ambience beds, and the nine looping `sfx` cues). Seams were verified
numerically, never by ear - that is the one QC step this pipeline cannot do for you.

### 8.4 The section 7 TODO list, resolved

| # | Item | Outcome |
|---|---|---|
| 1 | Kenney interface click/hover filenames | Closed: `click_001` -> `ui/ui_click.ogg`, `select_001` -> `ui/ui_hover.ogg`, plus 4 click, 2 hover, 1 scroll, 1 denied, 1 confirm as a pool |
| 2 | Engine bed: new vs owned Kenney | Both new candidates ship (`space_ship_0.ogg` = cue `sfx_ship_engine`, `rocket_engine.001.wav` = variant `_02_loop`). The comparison could not happen: no Kenney pack existed anywhere in the workspace, so the "already owned" premise in section 3 was wrong |
| 3 | Ship `default_bus_layout.tres`? | Neither - `AudioManager._build_buses()` builds the section 4.3 tree at startup (verified in Phase C). No `.tres` ships |
| 4 | Inner formats of the ZIP/7z archives | Resolved by extraction: the SFX archives are OGG inside (bit-exact passthrough), the impact/interface/foley archives are WAV, `launch.7z` and `metal_interactions.7z` carry Audacity sources, `dark_magic.7z` is FLAC |
| 5 | *60 CC0 Sci-Fi SFX* corruption | Not used. The rubberduck *50 CC0 Sci-Fi SFX* pack supplies S1/S3/S11 instead |
| 6 | MP3 one-shot policy strictness | Settled by 8.2: everything becomes OGG |
| 7 | Boss ducking implementation | Still open, and it is code: manual bus-volume tween vs sidechain limiter. The `Music` bus exists; nothing ducks yet |
| 8 | M6 Dissonance Anthem trim | Not downloaded: 56 MB for the optional anomaly tier. `sfx_stinger_anomaly_{01..03}` (dark magic pack) covers the stinger case |
| 9 | Ambience Pack 1 per-sector mapping | Not downloaded: the CC0 *30 SFX loops* pack supplies three station room tones (`amb_station_room_{01..03}`) instead |
| 10 | Nihilex itch.io packs | Not pulled: 242-867 MB per zip for the optional deep tier |

Two further deviations worth recording:

- ***7 Space Sounds* is not 7 cues.** Silence analysis at -40 dB / 0.12 s separates **five**
  (`amb_space_misc_{01..05}`); the two long chunks (5.5 s and 5.4 s) may each hold more than one cue.
  The OGA page copy is not authoritative here. Audition and re-cut if a specific sound is wanted.
- **S13's `projects.zip`** carries the yd track as `MyVeryOwnDeadShip.ogg` plus its LMMS source; the
  OGG is what shipped (`amb_space_drone_01`).

### 8.5 Import verification (evidence)

Every file was verified by loading it through the engine, not by eyeballing the filesystem: a
throwaway `SceneTree` script run headless against the project printed each stream's length and loop
flag and ended with `SUMMARY total=95 looping=25 missing=0` - so all 95 import, all 25 loop-flagged
files really carry `loop = true` (music 5 of 6, ambience 16, sfx 9), and the lengths match the
generation log after loop preparation (e.g. the menu theme reports 205.228 s, the trimmed value).

One piece of noise to expect in the editor's Debugger dock: while the audio build was rewriting
files on disk, the editor's own import queue logged `Can't find file 'res://assets/audio/...'
during file reimport` for about 87 paths. Those are a race between the rebuild and the watcher, they
predate the final import pass, and they are stale - the same paths all load cleanly in the check
above. Re-triggering a filesystem scan adds no new errors.
