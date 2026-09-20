# Engine Wave 1 — task brief (2026-09-18)

Owner-approved slice 1 of `ENGINE_SPEC.md` (workspace root): **fly and mine** —
hybrid flight with mass-scaled inertia, a populated sector, asteroids, mining,
pickups, docking, safe warp, HUD pass. The spec is the contract; this brief
only assigns it. **Stay to spec: implement exactly what `ENGINE_SPEC.md` and
the numbered gameplay docs say. If the spec and reality disagree, report the
deviation in your report — never silently redesign, never invent a number.**

Waves: **W0 runs first** (doc transcription, one small pass). **W1–W4 run in
parallel** (disjoint file sets, pinned interfaces below). **W5 (HUD) runs
after W1–W4 land** (it wires into game.gd, which W2 owns). **W6 = mandatory
review** of everything, then W7 fixes, W8 re-review, up to 3 cycles. W0
writes the `ENGINE_SPEC.md` §12 amendments into the docs; after W0 the docs
are frozen for this wave — no worker edits them again.

---

## W0 — doc amendments (run first, before W1)

Files: `docs/design/IMPLEMENTATION_PLAN.md`, `docs/gameplay/08_ship_classes.md`,
`docs/gameplay/09_ship_slots_modules.md`, `docs/gameplay/11_galactic_map.md`,
`docs/design/PROJECT_SETTINGS_PATCH.md`.

Mechanical transcription from `ENGINE_SPEC.md` §12 — no new numbers, no
rewording beyond what the spec states:

1. `IMPLEMENTATION_PLAN.md`: new **§9.9 Engine wave** recording decisions 1–7,
   the input-map additions (`interact` = F, `warp` = H) as §3.7 amendments,
   the §3.9 `damage(amount, bypass_shield)` signature, the §3.10 HUD
   additions (`set_prompt`, `set_warp_channel`, friendly blips, reticle
   states, target-info range state), and the retirement of the ESC-dock
   placeholder + `MOCK_*` constants.
2. `08_ship_classes.md` §2: note that the handling column of §13 in
   `ENGINE_SPEC.md` is the flight-stat source for engine purposes.
3. `09_ship_slots_modules.md` §3.1: add the `family` + `shield rule` columns
   (energy/kinetic/missile/deployable/tool; shields-first vs bypass) per
   ENGINE_SPEC §4.1, and retire the railgun's "ignores 50 % armour" line with
   the spec's reasoning. §3.2: name the base shield regen 2/s.
4. `11_galactic_map.md` §1: note the one-arena-size rule (spec decision 4);
   the per-sector tier table stays authoritative.
5. `PROJECT_SETTINGS_PATCH.md`: append the two new actions with bindings
   (`interact` = F, `warp` = H) for the orchestrator to apply via godot-ai
   after the wave.

Report: `.agents/gen/engine_wave1_w0_report.md` (docs changed, nothing else).

---

## Global rules (all workers)

- Engine: Godot 4.7.2, GDScript. Project code lives in `vajb-orbit/` under
  workspace root `G:/Mój dysk/Projekty/Vajb Orbit`.
- Read first, in order: `AGENTS.md`, `ENGINE_SPEC.md` (§2 decisions, §13
  calibration, §9 interface, your slice in §14), then your section below.
- Match existing style: static typing everywhere, tab indentation, `##` doc
  comments for non-obvious *why*, signals up / calls down, `class_name` +
  `extends` order, no `get_node()` in loops, no `_process` for UI animation.
- **Do not edit:** `project.godot` (input actions are orchestrator-applied via
  godot-ai after this wave — code defensively with
  `InputMap.has_action(&"warp")` / `&"interact"` guards),
  `addons/godot_ai/`, `ui/theme/vajb_theme.tres` (generated),
  `tools/build_theme.gd`, anything under `docs/`, anything under `assets/`
  not explicitly allowed in your section.
- No hex literals outside `tools/build_theme.gd`; read colours from the theme
  (the existing `_token()` helper pattern in `ui/` scripts).
- The Godot editor may be open with the project, and a game may be playing.
  Do **not** launch the editor or the graphical game, and do not run a
  headless `--editor` reimport (a second instance writes the same import
  cache). Parse/behaviour checks use the console binary:
  `"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path
  "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --quit-after N res://<scene>.tscn`
  **Known trap:** headless `--check-only --script` cannot resolve autoload
  singletons — it fails identically on untouched control files (proven in fix
  wave 1). Do not use it as a gate; use scene runs or `load()` probes.
- **Never put a command in the background, and keep every command under ~60 s
  of wall time.** The shell tool moves anything longer to a background job,
  and a worker that waits on that job never wakes up — this wedged three
  workers in this wave (W4, W6, W7). So: pass `--quit-after N` to every Godot
  run, make every probe self-quit (a 90 s watchdog plus an explicit `quit`),
  redirect a probe's stdout to a log file and read the log instead of waiting
  on the process, and split any command that would take longer than a minute.
- Throwaway probes (`extends SceneTree`, `quit()`-terminated) live at
  `res://tools/_probe_wN_*.gd` and are deleted with their `.uid` sidecar
  before your report; `tools/` must end holding only `build_theme.gd` +
  `derive_icon_tints.gd` (+ their `.uid`).
- Every economy event logs to `user://economy_log.txt` via the existing
  `game/economy_log.gd` (01 §7). Only `PlayerProfile` mutates credits/cargo.
- Write your report to `.agents/gen/engine_wave1_<id>_report.md`: files
  changed with byte sizes before/after, exact commands with output,
  acceptance evidence as **measurements** (not assertions), deviations/open
  points. Existing reports in `.agents/gen/` are the standard.

---

## Pinned interfaces (all workers code against these exactly)

1. **`ShipStats`** — `class_name ShipStats extends RefCounted` in
   `game/ship_stats.gd`. Typed fields exactly:
   `max_speed, accel_time, coast_time, turn_rate, turn_spinup: float`;
   `hull_max, shield_max, shield_regen, damage_mult: float`;
   `lock_range, scan_range, tractor_range, tractor_speed: float`;
   `tractor_streams: int`; `cargo_max: int`; `boosters: Array[StringName]`.
2. **`ShipFit`** — `class_name ShipFit extends RefCounted` in
   `game/ship_fit.gd`; `static func resolve(hull_id: StringName, fit:
   Dictionary) -> ShipStats` implementing the 09 §5 order over the 08 §2 hull
   table + 09 §3 module effects; `ShipFit.STANDARD_FIT` = the 09 §7 standard
   fit (Vanguard). The per-class handling table (ENGINE_SPEC §13) lives in
   W1's files as a typed const — single owner, nobody else duplicates it.
3. **`PlayerShip`** — `game/player_ship.tscn`: root `Node2D` named
   `PlayerShip`, added to group `&"player_ship"`, script `player_ship.gd`,
   containing a hull `Sprite2D` (current `ship_vanguard_side.png` scale) and
   the mining-laser child (W3's scene). API called by `game.gd`:
   `setup(stats: ShipStats, state: PlayerState)`, `set_move_target(pos:
   Vector2)`, `cancel_orders()`, `warp_available() -> bool` (state query).
   `game.tscn` keeps its `Camera2D`; `game.gd` keeps following the player.
4. **`Asteroid`** — `class_name Asteroid extends StaticBody2D` in
   `game/asteroid.gd`; `setup(mineral_id: StringName, tier: int,
   yield_units: int)`; `apply_work(work: float) -> int` returns units mined
   this call (`WORK_PER_UNIT := 1.0`); signal `cracked`. Rocks are solid to
   ships, block shots/beams, crack at yield 0.
5. **`MiningLaser`** — `game/mining_laser.tscn` child of PlayerShip (W3
   owns, W2 mounts); API `bind(stats: ShipStats)`, `set_active(active:
   bool)`. Trigger = hold the `mine` action (E). Beam reaches the asteroid
   under the cursor within `MINE_LASER_RANGE` 220 u; every `MINE_CYCLE`
   1.2 s of contact applies 1.0 work (1 ore unit → one `Pickup`).
6. **`Pickup`** — `class_name Pickup extends Node2D` in `game/pickup.gd`;
   `setup(item_id: StringName, amount: int, is_credit_cache: bool)`;
   lifetime 60 s; drifts toward the `&"player_ship"` group member when
   within `tractor_range` (pull at `tractor_speed`, base values from §13 —
   `u_salvage`/`u_tractor` are slice 4); on arrival credits/cargo go through
   `PlayerProfile` (`add_cargo` or the credits API + `economy_log` line),
   then free itself. Hold full → keeps drifting.
7. **`Sector`** — `class_name Sector extends Node2D` in `game/sector.gd`;
   `populate(row: Dictionary)` spawns the §8 set for that registry row;
   `blips() -> Array[Dictionary]` (`{"pos": Vector2, "kind": StringName}` —
   kinds `&"self"` is game.gd's; sector returns `&"hostile"`, `&"neutral"`,
   `&"friendly"` entries) consumed by `game.gd` for the minimap. Respawn
   bookkeeping consumes the existing `WorldClock` autoload (17 §4 one-timer
   rule — read `autoload/world_clock.gd` first; no second clock).
8. **`SectorRegistry`** — `class_name SectorRegistry extends RefCounted` in
   `game/sector_registry.gd`; `static SECTORS: Array[Dictionary]`, 7 rows
   per 11 §1 + §1.1 tier weights: `id, name, owner, tier_weights,
   backdrop_id, densities`; `SECTOR_SIZE` 10 000 × 10 000 u lives here.
9. **HUD additions** (W5 owns `hud.gd`/`hud.tscn`; W2 wires the calls):
   `set_prompt(text: String)` (empty hides), `set_warp_channel(progress:
   float)` (≤ 0 hides), blip kinds gain `&"friendly"`, reticle drawn at the
   cursor with plain/in-range/out-of-range states (slice-1 scope: plain +
   mining states only). The static `ESC · DOCK AT KEPLER-9` hint retires.

---

## W1 — ShipFit / ShipStats

Files (new): `vajb-orbit/game/ship_stats.gd`, `vajb-orbit/game/ship_fit.gd`.

1. Implement interface items 1–2 exactly. The resolver walks the 09 §5 order:
   hull base (08 §2) → flat module effects → multiplicative effects (speed:
   armour then engine then booster-on-activation; damage: computers; scanner
   best value; regen best value) → clamps (speed ≥ 40 % hull base, pools ≤ 3×
   hull base). v1 fit = `STANDARD_FIT` (09 §7: `e_std`, `p_std`, `w_laser`,
   `s_light`, `h_plate_light`).
2. Handling table per class exactly as ENGINE_SPEC §13 (max speed = hull % ×
   450; accel/coast/turn/turn-spin-up columns). Armour plating multiplies
   handling times by `1 + |its speed penalty|` on top of its 09 §3.3 speed
   penalty; engines per spec §3.2 last paragraph.
3. Acceptance (headless probe, then delete): `resolve("ship_vanguard",
   STANDARD_FIT)` prints every ShipStats field; assert the arithmetic you can
   derive from 08 §2 + 09 §3/§7 (show the derivation in the report). Also
   resolve a fit with two `h_plate_light` and show the compounded handling
   multiplier.

## W2 — Player ship flight + game.gd rewire

Files: `vajb-orbit/game/player_ship.gd`, `game/player_ship.tscn` (new),
`game/game.gd`, `game/game.tscn`.

1. Hybrid flight per ENGINE_SPEC §3: WASD throttle/turn (S = reverse thrust +
   active brake at `BRAKE_MULT` 1.8), angular spin-up/damping, linear
   coasting; the per-class constants arrive via `ShipStats` — no literals in
   movement code.
2. Autopilot: LMB on empty space sets a move target (`set_move_target`);
   arrive steering (slow-down radius 240 u, arrive radius 40 u) using the
   same physics; **any** thrust/turn input cancels it; firing does not.
   Mouse wheel camera zoom 0.70–1.50 stays as shipped.
3. Boosters: keep the `boost` action as afterburner (+60 % 3 s, 8 s
   cooldown) reading `ShipStats.boosters`; fold blink is a stub behind
   `ShipStats.boosters` (its module does not exist until slice 4 — code the
   seam, ship nothing).
4. `game.gd` rewires: instance `player_ship.tscn` + `Sector` (W4), keep HUD
   binding/route/damage-report flow; retire `MOCK_*` constants, the mock
   drain, the orbiting mock target, and **ESC docking** — ESC now cancels
   order + lock. Docking: when the player ship is inside the station's dock
   zone, `set_prompt("F · DOCK")`; pressing `interact` (guarded by
   `InputMap.has_action`) files the damage report + routes
   `route_requested(&"loading", {destination: &"station"})`.
5. Safe warp per spec §7: `warp` action (guarded) starts a 3 s channel with
   progress pushed to `HUD.set_warp_channel`; v1 "no enemy engaged" is
   trivially true (no NPCs yet) but implement the gate function
   (`_enemy_engaged() -> bool` returning false for now) so slice 2 fills it;
   on completion → dock route as above. Breaks on damage: connect the
   hull/shield change to cancel the channel.
6. Acceptance: headless scene run boots the flight scene with no errors; a
   probe (or `game_eval`-style measurement, editor not required) shows the
   ship reaching ~max speed in `accel_time` and coasting to stop in
   `coast_time` ±10 %.

## W3 — Asteroids, mining, pickups

Files (new): `vajb-orbit/game/asteroid.gd`, `game/asteroid_field.gd`,
`game/mining_laser.gd`, `game/mining_laser.tscn`, `game/pickup.gd`.

1. Asteroids per interface item 4 + spec §6: mineral + yield per 02 §5 roll
   (tier from the sector row), `MINE_CYCLE` 1.2 s per unit via the mining
   laser, gun work at 10 % (the gun hook is a slice-2 seam — expose
   `apply_work` and ship nothing else). Visual: pick ONE existing rock/
   asteroid sprite from `vajb-orbit/assets/` (check
   `docs/design/ASSET_CATALOG.md` first); if nothing fits, use a themed
   Polygon2D placeholder and record it as an art-gap note. Cracks at 0 with
   a despawn (reuse `FX_SPEC.md` language if a fitting asset exists; no new
   art).
2. `AsteroidField`: spawns `FIELD_ROCKS_MIN..MAX` = 6..12 rocks in a cluster,
   tracks `last_depleted_time`/`last_respawn_time` for the 02 §8 ×0.7
   diminishing window; exposes respawn for the Sector clock hook.
3. `MiningLaser` per interface item 5: cursor-aimed beam, range 220 u,
   `MINE_CYCLE` → `Pickup`. Trigger = hold `mine` (E). No ammo. Beam visual:
   theme-coloured Line2D/`_draw`, ember accent reserved for danger states
   (ICONS_SPEC §1) — mining beam uses a neutral/steel token.
4. `Pickup` per interface item 6: ore pickups carry the rock's mineral id;
   collection → `PlayerProfile.add_cargo` + economy log line per stack;
   credit caches are slice-2 content but keep the `is_credit_cache` seam.
5. Acceptance: headless probe spawns a field, runs `apply_work` to depletion,
   asserts N pickups for N units; pickup drift + collection with a fake
   player node in the group; hold-full leaves the pickup drifting.

## W4 — Sector, registry, spawns, station + dock zone

Files (new): `vajb-orbit/game/sector_registry.gd`, `game/sector.gd`;
allowed asset read: `docs/design/ASSET_CATALOG.md` (read-only).

1. Registry per interface item 8: all 7 rows of 11 §1 with §1.1 tier mixes,
   owner factions, backdrop ids (`backdrop_id` may be null for now — the
   sector falls back to the existing starfield layers; record which sectors
   have shipped backdrops per the catalog).
2. `Sector.populate(row)`: place 4–8 fields, the primary station (Sprite2D
   from an existing suitable asset + a `DockZone` Area2D at the dock ring),
   and stub POI hooks (wreck/anomaly/beacon arrays are slice 3 — leave the
   spawn table shape, spawn nothing). Player spawn: 300 u off the dock ring,
   clear of collisions (owned with W2 — agree the exact offset in your
   reports; the interface is `populate` returning the spawn point or the
   station exposing it: pick one, both must document it).
3. Minimap feed: `blips()` includes the station as `&"friendly"`, rocks as
   `&"neutral"` clusters (one blip per field, not per rock).
4. Acceptance: headless scene run populates the sector with the §8 counts
   (probe prints counts); blips array shape verified; no errors.

## W5 — HUD pass (after W1–W4)

Files: `vajb-orbit/ui/hud/hud.gd`, `vajb-orbit/ui/hud/hud.tscn`
(`ui/hud/minimap.gd` only if the blip-kind change requires it).

1. Implement interface item 9: `set_prompt`, `set_warp_channel`, friendly
   blips, cursor reticle (plain/in-range/out-of-range states drawn at the
   mouse position; hardware cursor behaviour unchanged this slice), remove
   the static ESC hint. Styling: existing theme items only
   (`StationCaption`, `HudReadout`), no new theme items, no font-size
   overrides.
2. Keep the frozen HUD API intact — additions only (§10 amendment list);
   `set_target`/`clear_target` stay (unused until slice 2, do not delete).
3. Acceptance: probe loads `hud.tscn` at 1920×1080, calls the new methods,
   verifies visibility states + blip kinds; no parse errors.

## W6 — review (mandatory, after W5)

Reviewer reads `ENGINE_SPEC.md` §2/§3/§6/§7/§8/§9/§13 + every changed file +
all W1–W5 reports. **Measure, never trust reports**: re-run key probes
(spawn counts, handling times, mining cycles), check every number against
§13 and the gameplay docs, check the pinned interfaces match across files
(aggregation checklist: filenames, identifiers, signatures, data shapes,
wiring), and flag any invented constant. Output: `.agents/gen/
engine_wave1_review_report.md` with findings classified HIGH/MED/LOW.

## W7 / W8 — fix cycle and re-review

Fix workers address each finding (one file set per fixer, same rules), then a
re-review runs the same gates. Loop until clean (max 3 cycles); unresolved
items go back to the orchestrator with evidence.

---

## Dispatch (the owner runs these from another agent; model fixed by owner)

The paste-ready prompts live in `.agents/gen/engine_wave1_prompts.md` — one
per worker, in run order W0 → W1–W4 parallel → W5 → W6 → W7/W8 loop. Model:
`deepseek/deepseek-v4-flash`, slug verified and used in fix wave 1
(2026-09-18); re-check the live catalog before each dispatch per the
orchestrator protocol. Template:

```
crush run "<worker prompt from engine_wave1_prompts.md>" -m deepseek/deepseek-v4-flash --cwd "G:/Mój dysk/Projekty/Vajb Orbit"
```
