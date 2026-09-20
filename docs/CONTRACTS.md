# CONTRACTS.md — living interface contract

**Status: v0 (engine wave 1).** This file is the single source of pinned interfaces
between workers. Every worker brief says "code against CONTRACTS.md §n" instead of
re-pasting signatures; every review/fix wave owns updating it (additions and
amendments recorded at the bottom in the changelog). Never edit it mid-wave while
workers hold the same files — the orchestrator merges review-wave changes after a
wave closes. Numbers here are transcribed from `docs/gameplay/18_engine_spec.md`,
the gameplay docs,
and the wave-1 brief; deviations are reported, never invented.

Conventions and forbidden files are defined in `AGENTS.md` (§ Rules) and apply to
every agent; they are not restated here.

---

## §1 Input map (project settings)

| Action | Binding | Status |
|---|---|---|
| `interact` | F | new, engine wave 1; orchestrator-applied via godot-ai after the wave |
| `warp` | H | new, engine wave 1; orchestrator-applied via godot-ai after the wave |
| `mine` | E | existing |
| `boost` | existing | afterburner |

Code defensively: `InputMap.has_action(&"warp")` / `&"interact"` guards — the
actions land in `project.godot` after the wave, never hand-edit the file.

## §2 ShipStats — `class_name ShipStats extends RefCounted`, `game/ship_stats.gd`

Typed fields exactly:

```gdscript
max_speed, accel_time, coast_time, turn_rate, turn_spinup: float
hull_max, shield_max, shield_regen, damage_mult: float
lock_range, scan_range, tractor_range, tractor_speed: float
tractor_streams: int
cargo_max: int
boosters: Array[StringName]
```

## §3 ShipFit — `class_name ShipFit extends RefCounted`, `game/ship_fit.gd`

```gdscript
static func resolve(hull_id: StringName, fit: Dictionary) -> ShipStats
static STANDARD_FIT   # the 09 §7 standard fit (Vanguard): e_std, p_std, w_laser, s_light, h_plate_light
```

Resolver order (09 §5): hull base (08 §2) → flat module effects → multiplicative
effects (speed: armour → engine → booster-on-activation; damage: computers;
scanner/regen: best value) → clamps (speed ≥ 40 % hull base, pools ≤ 3× hull base).
The per-class handling table (ENGINE_SPEC §13) lives in W1's files as a typed
const — single owner, nobody duplicates it. Armour plating multiplies handling
times by `1 + |its speed penalty|`; shields-first vs bypass weapon families per
09 §3.1 `family` column; base shield regen 2/s.

## §4 PlayerShip — `game/player_ship.tscn` / `game/player_ship.gd`

Root `Node2D` named `PlayerShip`, group `&"player_ship"`, hull `Sprite2D` +
mining-laser child (W3's scene). API called by `game.gd`:

```gdscript
setup(stats: ShipStats, state: PlayerState) -> void
set_move_target(pos: Vector2) -> void
cancel_orders() -> void
warp_available() -> bool
```

Flight (ENGINE_SPEC §3): WASD throttle/turn (S = reverse thrust + active brake at
`BRAKE_MULT` 1.8), angular spin-up/damping, linear coasting — constants arrive via
`ShipStats`, no literals in movement code. Autopilot: LMB on empty space sets a
move target, arrive steering (slow-down radius 240 u, arrive radius 40 u), the
same physics; **any** thrust/turn input cancels it, firing does not. Boosters:
`boost` = afterburner (+60 %, 3 s, 8 s cooldown) reading `ShipStats.boosters`;
blink is a stub seam (no module until slice 4).

## §5 Combat/mining entities (slice 1 scope)

**Asteroid** — `class_name Asteroid extends StaticBody2D`, `game/asteroid.gd`:

```gdscript
setup(mineral_id: StringName, tier: int, yield_units: int) -> void
apply_work(work: float) -> int   # units mined this call; WORK_PER_UNIT := 1.0
signal cracked
```

Rocks are solid to ships, block shots/beams, crack at yield 0. Gun work = 10 %
efficiency (slice-2 seam: expose `apply_work`, ship nothing else).

**MiningLaser** — `game/mining_laser.tscn`, child of PlayerShip:

```gdscript
bind(stats: ShipStats) -> void
set_active(active: bool) -> void
```

Trigger = hold `mine` (E). Beam reaches the asteroid under the cursor within
`MINE_LASER_RANGE := 220.0` u; every `MINE_CYCLE := 1.2` s of contact applies
1.0 work → one `Pickup` per unit. Beam visual: theme token (neutral/steel), no
hex literals. **AsteroidField**: 6..12 rocks per cluster (`FIELD_ROCKS_MIN..MAX`),
tracks `last_depleted_time`/`last_respawn_time` for the 02 §8 ×0.7 diminishing
window, exposes respawn for the Sector clock hook.

**Pickup** — `class_name Pickup extends Node2D`, `game/pickup.gd`:

```gdscript
setup(item_id: StringName, amount: int, is_credit_cache: bool) -> void
```

Lifetime 60 s; drifts toward the `&"player_ship"` member within `tractor_range`
(pull at `tractor_speed`; `u_salvage`/`u_tractor` base values are slice 4). On
arrival: `PlayerProfile.add_cargo` or credits API + `economy_log` line, then
`free()`. Hold full → keeps drifting.

## §6 Sector / SectorRegistry

**SectorRegistry** — `class_name SectorRegistry extends RefCounted`,
`game/sector_registry.gd`:

```gdscript
static SECTORS: Array[Dictionary]   # 7 rows per 11 §1 + §1.1 tier weights
# row shape: id, name, owner, tier_weights, backdrop_id, densities
static SECTOR_SIZE := Vector2(10_000, 10_000)  # lives here
```

**Sector** — `class_name Sector extends Node2D`, `game/sector.gd`:

```gdscript
populate(row: Dictionary) -> ...   # spawns the §8 set; documents how the player
                                   # spawn point (300 u off the dock ring) is exposed
blips() -> Array[Dictionary]       # {"pos": Vector2, "kind": StringName}
```

Blip kinds: `&"hostile"`, `&"neutral"` (one blip per asteroid field, not per
rock), `&"friendly"` (station); `&"self"` is game.gd's own. `populate` places
4–8 fields, the primary station + `DockZone` Area2D, and stub POI hooks (wreck/
anomaly/beacon arrays are slice 3 — keep the spawn table shape, spawn nothing).
Respawn bookkeeping uses the existing `WorldClock` autoload (17 §4 one-timer rule
— no second clock).

## §7 HUD — frozen API + wave-1 additions

Frozen (do not remove): `set_target`, `clear_target` (unused until slice 2).
Additions (W5 owns `ui/hud/hud.gd`/`hud.tscn`, W2 wires the calls):

```gdscript
set_prompt(text: String) -> void        # empty string hides
set_warp_channel(progress: float) -> void  # ≤ 0 hides
```

Blip kinds gain `&"friendly"`; cursor reticle drawn at the mouse position with
plain / in-range / out-of-range states (slice-1 scope: plain + mining states
only). The static `ESC · DOCK AT KEPLER-9` hint retires. Styling: existing theme
items only (`StationCaption`, `HudReadout`), no new theme items, no font-size
overrides, no hex literals.

## §8 Economy / state seams

- Only `PlayerProfile` mutates credits/cargo; every economy event logs via
  `game/economy_log.gd` to `user://economy_log.txt` (01 §7).
- Respawn/diminishing timers consume the one `WorldClock` autoload (17 §4).
- Docking: inside the station dock zone → `set_prompt("F · DOCK")`; `interact`
  files the damage report + routes `route_requested(&"loading", {destination: &"station"})`.
- Safe warp (ENGINE_SPEC §7): `warp` starts a 3 s channel pushing progress to
  `HUD.set_warp_channel`; gate `_enemy_engaged() -> bool` is trivially false in
  slice 1 (no NPCs) so slice 2 fills it; breaks on damage/aggro; on completion →
  dock route.

## §9 Universal test gate

```text
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tests/headless_runner.tscn --quit-after 1200
```

Expected: `[SUMMARY] passed=53 failed=0`, exit 0, no `SCRIPT ERROR`. A wave is
done = gate green + the worker added tests for their slice. **Known trap:**
headless `--check-only --script` cannot resolve autoload singletons — never use
it as a gate; use scene runs or `load()` probes.

## §10 Changelog

- **v0 (2026-09-18)** — seeded from the engine wave-1 pinned interfaces
  (evidence: `.agents/gen/engine_wave1_w1_report.md`) +
  `docs/gameplay/18_engine_spec.md`
  §2/§3/§7/§9/§13. Slices 2–4 (combat,
  travel, integration) append their sections here at their review gates.
