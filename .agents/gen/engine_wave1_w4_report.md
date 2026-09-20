# Engine wave 1 — W4 report (sector, registry, spawns, station + dock zone)

Worker: **W4**. Status: **done, acceptance measured clean (probe `failures=0`, scene boot exit 0)**.
Brief: `.agents/gen/engine_wave1_task.md` §W4 + the global rules; contract: `ENGINE_SPEC.md`
§2/§7/§8/§13/§14 and the numbered gameplay docs (11 §1/§1.1/§3, 02 §5/§7/§8, 12 §1/§3,
13 §4, 14 §5/§8, 17 §4). W0's doc freeze was read first; nothing under `docs/`,
`project.godot`, `addons/`, `assets/` or `ui/` was touched.

Pinned interface items 7 and 8 are implemented exactly (`Sector extends Node2D` in
`game/sector.gd` with `populate(row)` / `blips()`; `SectorRegistry extends RefCounted` in
`game/sector_registry.gd` with `static SECTORS` and `SECTOR_SIZE`). Every number in both
files is either read from the spec/doc it cites or listed as a derived placement constant in
§5 below; none was invented silently.

---

## 0. Files changed (before → after)

Both files are new; the workspace root is `G:/Mój dysk/Projekty/Vajb Orbit`.

| File | Bytes | Lines | LF/CRLF | md5 |
|---|---:|---:|---|---|
| `vajb-orbit/game/sector_registry.gd` | 0 → 5 815 | 0 → 159 | 159 / 0 | `C3F3AE450CEF4F03FAE0233EA4DB2077` |
| `vajb-orbit/game/sector.gd` | 0 → 12 438 | 0 → 325 | 325 / 0 | `02BE97B023CED32ABA4D7023DA69B5B8` |

Total: +18 253 bytes, +484 lines, two new files, LF-only, 203 + 212 tab-indent characters,
no hex literal in either file, no `get_node()`, no `Timer`.

Scope proof (mtime scan of everything under `vajb-orbit/` written in the last 90 minutes,
`addons/` and `.godot/` excluded):

```
17:01:59 game\sector.gd              <- this worker
16:17:55 game\sector_registry.gd     <- this worker
16:16:22 game\ship_stats.gd          <- W1
16:18:09 game\ship_fit.gd            <- W1
16:19:17 game\player_ship.tscn       <- W2
16:21:21 game\game.gd                <- W2
16:21:29 game\game.tscn              <- W2
16:22:29 game\mining_laser.gd        <- W3
16:23:59 game\asteroid.gd            <- W3
16:24:05 game\asteroid_field.gd      <- W3
16:37:00 game\pickup.gd              <- W3
```

`vajb-orbit/tools/` ends holding only `build_theme.gd` (+`.uid`) and `derive_icon_tints.gd`
(+`.uid`); both probes (`tools/_probe_w4_registry.gd`, `tools/_probe_w4_sector.gd`) and their
`.uid` sidecars were deleted after the final run.

---

## 1. `game/sector_registry.gd` — 11 §1 / §1.1 / §3 / §4, ENGINE_SPEC §13

- `const SECTOR_SIZE := Vector2(10000.0, 10000.0)` — ENGINE_SPEC §13, "one arena size"
  (§2 decision 4). The sector derives its own `SECTOR_HALF` from this at runtime, so 10 000
  has exactly one home.
- `static SECTORS: Array[Dictionary]` filled in `static func _static_init()`, seven rows, the
  six pinned keys and nothing else: `id`, `name`, `owner`, `tier_weights`, `backdrop_id`,
  `densities`. Row ids are `sector_1` … `sector_7` (harvested from 11 §1's `#` column); W2's
  `SECTOR_ID_DEFAULT = &"sector_1"` already agrees.
- `tier_weights` is **not** a second copy of 11 §1.1: each row references
  `MineralCatalog.SECTOR_TIER_MIX[n]`, the existing transcription of that table, through
  `preload("res://game/mineral_catalog.gd")`. Measured identical to the doc (§3, run 1).
- `densities` is the §8/§13 population shape: `pirate_min`/`pirate_max` (per-sector §13 band),
  `stations`, `outposts`, `convoys`, `fields_min`/`fields_max` (4/8), `rocks_min`/`rocks_max`
  (6/12), `wrecks_min`/`wrecks_max` (1/3), `hulks_min`/`hulks_max` (3/6),
  `derelicts_per_wreck_field` (1), `anomalies_min`/`anomalies_max` (1/2). Only the first five
  vary by sector.
- Two static helpers beyond the pin: `sector(id) -> Dictionary` (empty for an unknown id) and
  `sector_ids() -> Array[StringName]`. Both are additive; the pinned names are unchanged.
- `_densities(...)` is a private static builder so the four per-sector numbers are the only
  values a reader has to compare against the docs.

Measured table (run 1, §3): 7 rows, `SECTOR_SIZE=(10000.0, 10000.0)`, every row's tier weights
byte-equal to 11 §1.1 (sum 100), every pirate band equal to §13, every `backdrop_id` resolving
(`ResourceLoader.exists=true`).

---

## 2. `game/sector.gd` — what `populate` builds

`populate(row, random_seed := 0) -> Vector2` returns the **player spawn point** (the choice the
brief §W4 item 2 leaves open; "the interface is `populate` returning the spawn point or the
station exposing it: pick one, both must document it" — this is that documentation). W2's
`game.gd:205`/`:207` consumes the return value directly and the measurement in §3 run 6 shows
the ship seated on it.

Spawned by slice 1:

1. **Primary station** where `densities.stations > 0`: `Sprite2D` named `Station`, group
   `&"station"`, texture `res://assets/env/env_station.png` (the catalog's "Dockable station
   (POI)"), at the arena centre, scale `STATION_SCALE` (see §5).
2. **`DockZone`**: `Area2D` named `DockZone`, group `&"dock_zone"`, holding a
   `CollisionShape2D` with a `CircleShape2D` of radius `DOCK_RING_RADIUS`, positioned at the
   station centre. It is a **sibling** of the station sprite, not its child: the sprite carries
   the 0.0663 art scale, which would have scaled a child's collision circle to ~8 u. The
   comment in the file says exactly that.
3. **4–8 asteroid fields** (W3's `game/asteroid_field.gd`, loaded by path behind
   `ResourceLoader.exists`, groups `&"asteroid_field"`, named `Field1…N`), placed on even
   angular slots on a ring between `FIELD_STATION_CLEARANCE` and the arena edge with a small
   angular jitter. Each field is handed
   `{&"tier_weights", &"rocks", &"seed"}` through a duck-typed `setup(config)`.
4. **The plan for everything else** in `spawn_plan()` — the slice-1 shape of the §8 set:
   `fields`, `stations`, `outposts`, `wreck_fields`, `hulks`, `derelicts`, `anomalies`,
   `beacons` (0), `pirates`, `patrols`, `convoys`. Nothing is instantiated for any of them
   (brief item 2: "leave the spawn table shape, spawn nothing"), so `get_child_count()` is
   exactly `fields + 2 × stations`.
5. **Minimap feed** `blips()`: station as `&"friendly"`, **one** `&"neutral"` blip per field
   (not per rock), `&"hostile"` empty until slice 2's NPCs. Shape is `{"pos": Vector2,
   "kind": StringName}` with string keys, matching what `game.gd`/`hud.gd` read.
6. **Clock bookkeeping**: `refresh_clock() -> int` consumes the one `WorldClock` band
   accumulator (17 §4) and asks each depleted field to `respawn()`. `_process` calls it on a
   1 s read gate; there is no Timer anywhere and no second clock.

Query surface for W2/slice 2/3 (all additive to the pin): `spawn_point()`, `spawn_plan()`,
`sector_id()`, `display_name()`, `has_station()`, `station_position()`,
`dock_zone_contains(world_position)`, `field_count()`, `fields()`, `blips()`,
`refresh_clock()`.

`dock_zone_contains` is geometric on purpose: the player ship is a plain `Node2D` this slice,
so a physics overlap would report nothing. Measured boundary: inside at exactly
`DOCK_RING_RADIUS`, outside at `+1 u`, spawn (420 u) outside.

---

## 3. Acceptance — measured, not asserted

Probe `res://tools/_probe_w4_sector.gd` (`extends SceneTree`, `quit()`-terminated, deleted with
its `.uid` after the final run). Command, verbatim:

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --script res://tools/_probe_w4_sector.gd
```

Output, verbatim and complete except for the seven repeated per-sector blocks (run 1):

```
asteroid_field.gd (W3) exists=true
=== 1. registry vs 11 section 1.1 / ENGINE_SPEC section 13 ===
rows=7 SECTOR_SIZE=(10000.0, 10000.0)
sector_1 Halcyon Reach | concord | { 1: 100 } | pirates 0-1 stations 1 outposts 0 convoys 1 | backdrop=true
sector_2 Iron Marches | concord | { 1: 55, 2: 45 } | pirates 1-2 stations 1 outposts 1 convoys 1 | backdrop=true
sector_3 Meridian Span | meridian | { 1: 20, 2: 80 } | pirates 2-3 stations 1 outposts 0 convoys 1 | backdrop=true
sector_4 Ashveil Expanse | meridian | { 2: 60, 3: 40 } | pirates 3-4 stations 1 outposts 1 convoys 1 | backdrop=true
sector_5 Cinder Verge | choir | { 2: 35, 3: 65 } | pirates 3-5 stations 1 outposts 1 convoys 1 | backdrop=true
sector_6 The Hollows | choir | { 3: 55, 4: 45 } | pirates 4-6 stations 1 outposts 0 convoys 1 | backdrop=true
sector_7 Maw Belt | unaligned | { 3: 40, 4: 60 } | pirates 6-8 stations 0 outposts 0 convoys 0 | backdrop=true
=== 2.1 sector_1 ===
plan={ &"fields": 8, &"stations": 1, &"outposts": 0, &"wreck_fields": 2, &"hulks": 9, &"derelicts": 2, &"anomalies": 1, &"beacons": 0, &"pirates": 0, &"patrols": true, &"convoys": 1 }
spawn=(0.0, 420.0) station=true fields=8 children=10
station scale=0.0663 size=135.8 u ring=120 | spawn distance=420.0 | in zone: spawn=false centre=true ring=true outside=false
fields: ring 2655.3..4127.8 u | spawn to nearest 2240.6 u | rocks per field=[8, 7, 10, 12, 9, 6, 11, 7] total=70
blips=9 kinds=[friendly, neutral x8] shape_ok=true
=== 2.2 sector_2 ===
plan={ ...fields 5, stations 1, outposts 1, wreck_fields 1, hulks 4, derelicts 1, anomalies 2, beacons 0, pirates 1, patrols true, convoys 1 }
spawn=(0.0, 420.0) station=true fields=5 children=7
fields: ring 2294.0..3332.4 u | spawn to nearest 2638.6 u | rocks per field=[9, 7, 10, 6, 12] total=44
blips=6 kinds=[friendly, neutral x5] shape_ok=true
=== 2.3 sector_3 ===   fields=4 children=6  ring 2267.5..2996.5 u  rocks=[7, 8, 6, 7] total=28
=== 2.4 sector_4 ===   fields=5 children=7  ring 2221.1..3433.4 u  rocks=[12, 11, 6, 10, 12] total=51
=== 2.5 sector_5 ===   fields=4 children=6  ring 2182.2..3336.7 u  rocks=[10, 8, 8, 9] total=35
=== 2.6 sector_6 ===   fields=5 children=7  ring 2169.6..3539.6 u  rocks=[8, 11, 8, 10, 7] total=44
=== 2.7 sector_7 ===
plan={ ...fields 8, stations 0, outposts 0, wreck_fields 2, hulks 9, derelicts 2, anomalies 1, beacons 0, pirates 8, patrols false, convoys 0 }
spawn=(0.0, 420.0) station=false fields=8 children=8
fields: ring 2195.7..3725.8 u | spawn to nearest 2328.8 u | rocks per field=[10, 12, 6, 8, 10, 7, 8, 9] total=70
=== 3. one-clock bands (17 section 4) ===
stamp=0 three_bands=3 repeat=0 sub_band=0 BAND_SECONDS=1200
=== 4. field respawn on the band (ENGINE_SPEC section 8, 02 section 8) ===
before=[8, 7, 10, 12, 9, 6, 11, 7] | depleted=8/8 ([0, 0, 0, 0, 0, 0, 0, 0]) | bands=1 | after=[8, 7, 10, 12, 9, 6, 11, 7] | in x0.7 window=8
=== 5. flight scene (game.tscn: W2 ship + W4 sector) ===
sector=sector_1 fields=8 (plan 8) station=true blips=9 | ship seated=(0.0, 420.0) spawn=(0.0, 420.0)

PROBE_RESULT failures=0
```

What each measurement proves:

1. **Registry = docs.** 7 rows, exact key set, tier weights and pirate bands equal to the
   cited tables, every backdrop resolving.
2. **§8 counts.** Every sector rolls 4–8 fields inside 4/8; rocks per field land in 6–12
   (W3's field landed during this wave, so these are real rocks, not markers); `children`
   equals `fields + 2 × stations` in all seven, i.e. nothing beyond slice-1 scope is
   instantiated; `plan` carries the rolled counts for the slice-2/3 categories.
3. **Dock geometry.** Spawn distance is exactly `DOCK_RING_RADIUS + 300 = 420.0` in all seven
   sectors (ENGINE_SPEC §13's "300 u off the dock ring"); the ring edge is inside the zone and
   `ring + 1 u` is outside; the spawn is never inside the zone. The station measures 135.8 u
   across (2048 px × 0.0663).
4. **Blips.** Counts are `fields + station`, kinds are exactly one `friendly` for the station
   and one `neutral` per field (sector 1: 1 + 8 = 9), shape is two-key `{pos, kind}` with a
   `Vector2` under `pos`.
5. **Clock.** `populate` stamps the clock (0 bands), three elapsed bands read as 3, an
   immediate repeat reads 0, and a sub-band advance reads 0 — one accumulator, no drift.
6. **Respawn.** All eight fields of sector 4 were mined to depletion (`rock_count` 0 each),
   one band was consumed, and every field came back with its rolled count
   (`[8,7,10,12,9,6,11,7]`) and reported inside 02 §8's ×0.7 window.
7. **Scene integration.** `res://game/game.tscn` (W2's) instantiates, W2's `game.gd` creates
   and populates my `Sector` (`sector_1`: 8 fields, station, 9 blips) and seats the ship on the
   exact `populate` return `(0.0, 420.0)`.

Scene boot, verbatim (run 2):

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --quit-after 90 res://game/game.tscn
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
EXIT=0
```

Zero `ERROR:`, zero `WARNING:`, zero `push_warning` output; exit code 0. The gdscript LSP was
not used as a gate (the brief's known trap: `--check-only --script` cannot resolve autoloads);
runs 1 and 2 are behaviour checks, per the brief's sanctioned console-binary path.

### Cross-file interface check (W2's call sites, read only)

`game/game.gd` (W2, 16:21) consumes exactly the pinned surface: `SectorScript.new()` +
`add_child` with `name = "Sector"`, `_sector.populate(row)` used as the spawn `Vector2`,
`_sector.has_method(&"dock_zone_contains")` then `dock_zone_contains(_ship.global_position)`,
`_sector.has_station()` for warp availability, `_sector.blips()` merged into the HUD payload,
and `Registry.sector(...)` for the row. `game/asteroid_field.gd` (W3, 16:24) documents the same
`setup({tier_weights, rocks, seed})` / `is_depleted()` / `respawn()` handoff this file calls.
No adapter, no shim, no rename was needed in either direction.

---

## 4. What slice 1 deliberately does not spawn

| §8 / 11 §3 category | Slice | This file |
|---|---|---|
| Asteroid fields (4–8, 6–12 rocks) | 1 | spawned (W3's field) |
| Primary station + dock zone | 1 | spawned |
| Outpost (0–1; S2, S4, S5 per 14 §8) | 3 | in the plan, not spawned |
| Wreck fields (1–3, 3–6 hulks, 1 derelict each) | 3 | in the plan, not spawned |
| Anomalies (1–2) | 3 | in the plan, not spawned |
| Nav beacons (1/corridor + 1/gate) | 3 | plan key present, value 0 |
| Pirates (§13 band), patrols, 1 convoy | 2 | in the plan, not spawned |

The plan keys are the "spawn table shape" the brief asks to leave; it lives in `spawn_plan()`
rather than in three empty member arrays, so the numbers are measurable now and slice 3 adds
the node arrays when it spawns them.

---

## 5. Deviations, derived numbers and open points

Nothing here is a silent redesign; each item is either a reading of two conflicting doc lines
or a number no doc supplies, with the reversal path.

1. **`densities.stations = 0` for sector 7 (the Maw has no station).** ENGINE_SPEC §7 says safe
   warp reports unavailable when the sector has no station and names S7 as the hardcore case
   ("No station in the sector → the action reports unavailable (S7 stays hardcore)"), which
   conflicts with §8's blanket "1 primary station + 0–1 outpost" and with 12 §1's "no station
   *services*". I read §7 as authoritative for the engine, so the Maw spawns no station, no
   dock zone and no warp target, and `convoys = 0` there as well (11 §3: one per *inhabited*
   sector). **Reversal: one argument** in `sector_registry.gd`'s `_densities(6, 8, 0, 0, 0)` →
   `(6, 8, 1, 0, 0)`; nothing else changes. **Owner confirmation requested.**
2. **Outposts are data only.** 14 §8 names exactly three secondary stations (S2 outpost, S4
   outpost, S5 shrine), so `outposts = 1` for sectors 2, 4, 5 and 0 elsewhere; the brief's
   §W4 item 2 names only the primary station, so no outpost node is built. Reversal: spawn a
   sprite in `populate` the way the station is spawned.
3. **Placement numbers §13 does not supply** (every one is a named const in `sector.gd` with
   its reasoning in the file, listed here so W6 can re-tune in one edit each):
   - `DOCK_RING_RADIUS = 120.0` u: §13 fixes the 300 u spawn offset *from* the ring but no ring
     radius. 120 u is just outside the station's ~67.9 u half-extent at the shipped art scale.
   - `FIELD_STATION_CLEARANCE = 1800.0` u and `FIELD_EDGE_MARGIN = 800.0` u: field-cluster
     placement bounds. With the spawn at 420 u, the worst case a cluster centre can sit from
     the spawn is 1380 u, and the measured minimum across the seven sectors is 1766.1 u.
   - `FIELD_SLOT_JITTER = 0.25` rad: keeps the even-slot ring from reading as a perfect circle.
   - `SPAWN_BEARING = Vector2.DOWN`: §13 fixes the distance, not a bearing; +Y is an arbitrary
     deterministic pick so the spawn point is reproducible (measured stable across sectors).
4. **`STATION_SCALE = 0.0663` is reused, not invented.** It is the scale `game.tscn` already
   gives `ship_vanguard_side.png` (W2's `player_ship.tscn` keeps it), which makes the 2048 px
   `env_station.png` 135.8 u across: ~2.3× a hull's length, consistent with
   `ASSET_WIRING_HANDOFF.md` §2's "draw at roughly 2x hull scale" for station-scale art. If W2's
   ship scene ever changes the hull scale, this const follows it.
5. **The arena centre is the sector node's origin.** §13 says "station near centre"; the sector
   node is placed at the arena centre by `game.gd`, so the station sits on `Vector2.ZERO`. No
   jitter: a moving station would move the spawn and the dock ring with it every entry.
6. **`backdrop_id` is populated for all seven sectors but nothing renders it.**
   `env_sector_1_bg.png` … `env_sector_7_bg.png` are all shipped (ASSET_CATALOG lines 878–884,
   measured `exists=true` for all seven), so the field records them truthfully; ENGINE_SPEC §14's
   slice 1 has no backdrop-wiring item and the brief allows the field to be null "for now", so
   the game scene's three star layers remain the visible backdrop. Note that
   `ASSET_WIRING_HANDOFF.md` §2 assigns the *parallax* body layer to `env_bg_body_plate.png`,
   not to the per-sector 16:9 backdrops — whoever wires sector backdrops should decide which of
   the two roles `env_sector_N_bg.png` plays (screen backdrop vs world plane) before adding it.
   Reversal: set the seven `backdrop_id` values to `null`, or wire a layer.
7. **`patrols` in the plan is a bool, not a count.** 11 §3 says patrols exist in
   "Concord/Meridian/Choir space only" and ENGINE_SPEC §13 gives pirate counts per sector but no
   patrol count, so the plan carries presence (`owner != &"unaligned"`); slice 2 owns the count.
8. **Faction ids are new.** `owner` uses the short forms 12 §3 already uses for its economy rows
   (`concord`, `meridian`, `choir`) plus `unaligned` (11 §1, 12 §1). No spelling existed in code
   before this file; 12 §4/17 §2 name `game/faction_registry.gd` as the eventual owner, which
   should adopt these four rather than invent a second set.
9. **11 §4's `neighbours` and `gate links` row keys are absent.** The pinned interface
   enumerates exactly six keys and both omitted keys are gate-slice data (slice 3). Additive
   when the gate slice needs them.
10. **`populate` gained an optional `random_seed: int = 0`** (0 = randomize). This keeps the
    pinned one-argument call working (W2 calls `populate(row)`, measured) while giving probes
    and the W6 review a reproducible arena. Reversal: drop the parameter.
11. **Field respawn cadence.** 02 §8 says a field respawns "20 minutes after a field is fully
    depleted"; ENGINE_SPEC §8 and 11 §3 say POIs and fields "re-roll on the single 20-minute
    `WorldClock`". I implemented the engine rule (band evaluation), so a field depleted mid-band
    respawns at the next band boundary: at most 20 minutes, not exactly 20 minutes after the
    crack. W3's field keeps its own `last_depleted_time` / `last_respawn_time` stamps and its
    02 §8 ×0.7 window, which the measurement confirms is applied on respawn. If the owner wants
    the literal 02 §8 per-field timer instead, the change belongs in `_respawn_cycle`.
12. **`_process` uses a 1 s read gate on the shared clock.** 17 §4 forbids per-consumer Timers
    and a second schedule; this is a throttle on `WorldClock.now()` reads, not a clock, and
    `refresh_clock()` is public so tests and probes never depend on frame timing (run 1 §3/§4
    drive it with an override).
13. **Not spawned this slice, so not measured here:** any POI node, NPC behaviour and counter
    (13 §6's Wanted wings), and the station-turret objects. `blips()` therefore returns no
    `&"hostile"` entries yet, which is the interface shape, not a gap.

---

## 6. Verification runs (all commands, in order)

1. `..._console.exe --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --script res://tools/_probe_w4_registry.gd`
   — registry-only smoke while writing (7 rows, weights, backdrops, `SECTOR_SIZE`); probe
   deleted afterwards.
2. `..._console.exe --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --script res://tools/_probe_w4_sector.gd`
   — final acceptance probe, output quoted in §3, `PROBE_RESULT failures=0`. The probe was
   iterated three times (two probe-side bugs found and fixed: a `Node2D`-typed parameter that
   could not resolve `Sector`'s members, and a scene check that ran before `_ready` propagates;
   neither involved product code).
3. `..._console.exe --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --quit-after 90 res://game/game.tscn`
   — flight scene boot, exit 0, no errors or warnings.
4. Probe files deleted with their `.uid`; `tools/` re-listed (only `build_theme.gd` and
   `derive_icon_tints.gd` remain).

No editor was launched, no `--headless --editor` reimport was run, no graphical game was
started, and nothing outside `game/sector_registry.gd`, `game/sector.gd` and the two throwaway
probes was written.
