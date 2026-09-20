# Engine wave 1 — W2 report (player ship flight + `game.gd` rewire)

Worker: W2. Status: **done**, with the deviations and open points in §6. Deliverables:
`vajb-orbit/game/player_ship.gd` (new), `game/player_ship.tscn` (new), `game/game.gd`
(rewired), `game/game.tscn` (mock nodes retired). Brief: `.agents/gen/engine_wave1_task.md`
§W2 + the global rules; law: `ENGINE_SPEC.md` §3/§7/§8/§9/§13 and the pinned interfaces.

Every number that appears in the two new files is either (a) a field of the `ShipStats`
snapshot `ShipFit` resolves, (b) the booster's own data read out of `ShipFit.MODULES`, (c) a
§13 calibration value with no class and no module home, or (d) a value that was already in the
shipped scene/script. §6 item 5 lists them with their citations; no value was invented.

## 1. Files changed (measured)

Measured with `py -3.14` (the interpreter AGENTS.md mandates); LF-only files, `crlf=0` on all
four.

| File | Before | After | md5 after |
|---|---:|---:|---|
| `vajb-orbit/game/game.gd` | 13 494 B | **16 208 B (507 lines)** | `03144938FA5FDB92D30CBD5AA6DB8914` |
| `vajb-orbit/game/game.tscn` | 2 175 B | **1 700 B (46 lines)** | `726C1B2584D654B466270AC2D5FFE170` |
| `vajb-orbit/game/player_ship.gd` | — (new) | **11 216 B (330 lines)** | `6EA28365A486B916280E33CDBD0DAA53` |
| `vajb-orbit/game/player_ship.tscn` | — (new) | **432 B (11 lines)** | `B8532F34D6BE08BF8E00740BCAAE5795` |

Nothing else was written: `project.godot`, `ui/theme/vajb_theme.tres`, `tools/build_theme.gd`,
`docs/**`, `assets/**`, `addons/**` and every other worker's files are untouched. Four
throwaway probe files were created under `tools/` and deleted with their `.uid` sidecars
(`_probe_w2_env.gd`, `_probe_w2_flight.gd`, `_probe_w2_game.gd` + `_probe_w2_game.tscn`, the
last with a scene file because `game.gd` reads the `Router` autoload — see §6 item 11); the
only `_probe_*` files left in `tools/` belong to W3/W4.

## 2. What was implemented, per brief item

**Item 1 — hybrid flight (§3.1/§3.2/§3.3).** `player_ship.gd` owns the movement that used to
live in `game.gd`. Linear: the ship's forward speed chases `throttle × max_speed` at
`max_speed / accel_time`, at `× BRAKE_MULT` when S is held (reverse thrust doubles as the
brake), and at `max_speed / coast_time` toward zero with no input. Angular: the turn velocity
(spin-up over `turn_spinup`, same rate damping back) then integrates the heading. No per-class
literal exists in the file: `max_speed`, `accel_time`, `coast_time`, `turn_rate` and
`turn_spinup` all come from `ShipStats`.

**Item 2 — autopilot.** LMB (`_unhandled_input` on the ship, so the whole flight control set
lives in one file) calls `set_move_target(get_global_mouse_position())`. Arrive steering uses
the same accel/coast model and the same turn model: desired speed = `max_speed ×
clamp((d − ARRIVE_RADIUS) / SLOW_DOWN_RADIUS, 0, 1)` (so the ship reaches zero *at* the arrival
ring), desired turn = `clamp(bearing error in rad, −1, 1) × turn_rate`. A target behind the bow
holds speed at 0 while the ship comes about. Cancellation: any thrust or turn input (measured),
not firing (measured), and `cancel_orders()`. The wheel-zoom block (0.70–1.50, 0.10 step, 0.18 s
tween) is unchanged, including `_unhandled_input` staying free for UI controls.

**Item 3 — boosters.** `boost` is the afterburner, gated on `has_booster(&"b_afterburner")` and
on nothing else: multiplier, duration and cooldown are read from `ShipFit.MODULES`
(`boost_speed_mult`/`duration`/`cooldown` — W1's `ship_stats.gd` doc names that home), so no
booster number is duplicated in W2's file. `b_fold` needs nothing beyond the generic
`has_booster(id)` seam: its 400 u blink is slice 4, and a fit carrying it activates nothing.

**Item 4 — `game.gd` rewire.** The script now resolves the launch snapshot
(`ShipFit.resolve(active_ship, ShipFit.STANDARD_FIT)`, §9), takes `PlayerState`'s maxima from it
(replacing the old `StationCatalog` read, per §9), instances `player_ship.tscn` and the sector,
seats the ship and the camera on the sector's returned spawn point, keeps the HUD
bind/route/damage-report/vitals flow, and feeds the minimap `self` + the sector's blips.
Retired: the `MOCK_*` constants, the mock shield/hull drain, the orbiting mock target and its
stats window, `MOCK_BLIPS`, `_world_to_screen`, ESC docking, and the mock `mine` cargo bump
(`E` is the mining laser now, §4.3). Docking: inside the dock zone the HUD gets
`set_prompt("F · DOCK")`; `interact` (behind `InputMap.has_action`) files the damage report and
emits `route_requested(&"loading", {destination: &"station"})`. ESC cancels the order and clears
the (empty, slice-1) lock.

**Item 5 — safe warp (§7).** `warp` starts a 3 s channel (`WARP_CHANNEL`, §13) with progress
pushed to `HUD.set_warp_channel`; completion lands docked through the same dock route;
the gate is `_enemy_engaged()` (false, slice-2 seam) **and** the ship's `warp_available()`
(alive + 5 s without a hit, §7) **and** a station in the sector; damage breaks the channel.

**Item 6 — acceptance.** §3 and §4 below: the flight scene boots clean, and the handling times
reproduce §13 within one 120 Hz step (0.2 %).

## 3. Commands run, with output

Engine binary: `C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe`. The editor was left
alone throughout: it was already running with the project, so no editor was launched and no
headless `--editor` reimport was run (a second instance writes the same import cache).

### 3.1 Flight measurements (throwaway probe, deleted)

```
"…_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" \
  --script res://tools/_probe_w2_flight.gd
```

```
[STATS] vanguard standard: max_speed=406.600 accel=2.520 coast=2.100 turn=3.000 spinup=0.525
[ACCEL] time to max speed = 2.5250 s (spec accel_time 2.52)
[COAST] time from max speed to a stop = 2.1000 s (spec coast_time 2.10)
[BRAKE] time from max speed to a stop under S = 1.4000 s (accel_time/1.8 = 1.4000)
[REVERSE] speed after 2 s of held S from a standstill = -406.609 u/s (max 406.600)
[TURN] spin-up to 99% of turn rate = 0.5250 s (spec turn_spinup 0.53)
[TURN] damping back to ~0 = 0.5250 s
[AUTOPILOT] target=(1200,0) cancelled after 4.250 s at 36.265 u from it (last pre-cancel 38.497), settled 36.265 u (slow-down 240, arrive 40)
[ORDER] cancelled by thrust=true turn=true ; kept by fire=true
[ORDER] cancel_orders() left an order active=false
[ORDER] set_move_target() left an order active=true
[LASER] mounted node=MiningLaser script=res://game/mining_laser.gd parent=PlayerShip bind=true | mine held -> active=true, released -> active=false
[BOOST] standard fit has b_afterburner=false b_fold=false
[BOOST] b_fold only: peak speed 0.000 u/s (stat max 406.600) -> blink shipped=false
[BOOST] fit booster ids=[&"b_afterburner"] effects={ &"boost_speed_mult": 1.6, &"duration": 3.0, &"cooldown": 8.0 }
[BOOST] afterburner peak 650.566 u/s (stat max 406.600, x1.6 = 650.560); speed at end of window 485.391; speed at 6 s 406.597
[BOOST] second activation after 8.008 s of held boost (spec cooldown 8 s)
EXIT=0
```

Method: the shipped `player_ship.tscn` is instantiated into a live tree, its own
`_physics_process` is disabled and called manually at 120 Hz, and the input map is driven with
`Input.action_press/release` — so the measurements are of the shipped input path and the shipped
function, not of a re-implementation. Speeds are derived from per-step displacement.

### 3.2 Scene-side behaviour (throwaway probe scene, deleted)

```
"…_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" \
  res://tools/_probe_w2_game.tscn
```

```
[BOOT] scene=res://game/game.tscn hud=true sector=Sector row=sector_1 ship=PlayerShip
[BOOT] camera=(0.0, 420.0) ship=(0.0, 420.0) spawn_point=(0.0, 420.0) equal=true
[BOOT] fields=5 plan={ &"fields": 5, &"stations": 1, &"outposts": 0, &"wreck_fields": 1, &"hulks": 3, &"derelicts": 1, &"anomalies": 2, &"beacons": 0, &"pirates": 0, &"patrols": true, &"convoys": 1 } blips=7 kinds=["self", "friendly", "neutral", "neutral", "neutral", "neutral", "neutral"] station=true
[BOOT] pools hull=250.0/1250.0 shield=570.0/800.0 cargo_max=40 stats=max_speed=406.600 accel=2.52 coast=2.10 turn=3.00
[DOCK] prompt at spawn='' inside the dock zone='F · DOCK' (interact in map=false, key path routed=0)
[DOCK] _request_dock() -> routes=[&"loading"] params=[{ &"destination": &"station" }] vitals={ "hull": 250, "shield": 570 }
[ESC] order before=true after=false routes added=0 (ESC no longer docks)
[WARP] warp in input map=false ready=true
[WARP] channel: ["0.50s=0.17", "1.00s=0.33", "1.50s=0.50", "2.00s=0.67", "2.50s=0.83", "3.00s=1.00"] -> route after 3.02 s (spec channel 3.0) progress after=0.00 active=false
[WARP] landed docked: route=[&"loading", &"loading"] params=[{ &"destination": &"station" }, { &"destination": &"station" }] vitals={ "hull": 250, "shield": 570 }
[WARP] progress mid-channel=0.33 after damage=0.00 active=false routes added=0
[WARP] broke=true blocked while hurt=true -> after 5 s quiet ready=true
[SECTOR] sector_7 row=sector_7 name='Maw Belt' station=false warp ready=false ship=(0.0, 420.0) blips=8
[SECTOR] back to sector_1 name='Halcyon Reach' station=true
[RETIRED] game.tscn Player node=false TargetBody node=false | ship scene=res://game/player_ship.tscn
EXIT=0
```

Notes on that log. The hit points at boot (250/1250, 570/800) are the *stored* damage report
being seeded through 01 §6 — the owner's profile is currently carrying a damaged Vanguard, and
the launch maxima (1250/800) are the standard fit's resolved pools, which is the §9 behaviour
the brief asked for. `blips=7` is the `self` blip plus the station (`friendly`) and one
`neutral` per field — W4's §8 feed. The rolled field/wreck counts differ per run (the sector
randomises); counts are W4's acceptance, shown here only to prove the populate call is wired.
The warp/ESC/dock numbers are all in §4.2.

This probe is a *scene* probe, not a `--script` probe: a `--script` main loop does not register
autoloads as compile-time identifiers, so `game.gd`'s `Router.live_theme()` reference fails to
compile there (pre-existing, not introduced by W2; §6 item 11).

### 3.3 Boot / regression gates

```
"…_console.exe" --headless --path <proj> --quit-after 240 res://game/game.tscn        -> EXIT=0, no script errors, no warnings
"…_console.exe" --headless --path <proj> --quit-after 120 res://ui/screens/boot.tscn   -> EXIT=0, clean
"…_console.exe" --headless --path <proj> --quit-after 120 res://ui/screens/main_menu.tscn -> EXIT=0 (4 ObjectDB leak warnings, pre-existing)
"…_console.exe" --headless --path <proj> --quit-after 120 res://ui/screens/station.tscn   -> EXIT=0 (same pre-existing leak warnings)
"…_console.exe" --headless --path <proj> res://tests/headless_runner.tscn              -> [SUMMARY] passed=53 failed=0
```

The P1 suite is unchanged and green, so nothing in the station/economy layer regressed. The two
leak warnings on the menu/station standalone runs are pre-existing (they are F6-style runs of
scenes whose routers are absent) and do not name any W2 file.

### 3.4 Owner-data safety

The scene probe repoints `PlayerProfile.save_path` at `user://probe_w2_profile.cfg` before the
game scene is instantiated, and removes it afterwards. Verified:

```
profile.cfg md5 before probe run = 9C2FAF9BB786BF75E03DEDEF68A5759F
profile.cfg md5 after  probe run = 9C2FAF9BB786BF75E03DEDEF68A5759F   (mtime unchanged)
probe_w2_profile.cfg             = SCRATCH ABSENT
```

`_write_profile()` writes to `save_path` (`player_profile.gd:660`), so the owner's save is never
a target of this worker's runs. Recorded for the wave's picture: `profile.cfg`'s mtime did move
during the wave (16:24:44) — that is another parallel worker's probe, not W2's.

## 4. Acceptance evidence

### 4.1 Ship handling against ENGINE_SPEC §13

Vanguard standard fit (`ShipFit.resolve(&"ship_vanguard", ShipFit.STANDARD_FIT)`) resolves to
`max_speed 406.600`, `accel_time 2.520`, `coast_time 2.100`, `turn_rate 3.000`,
`turn_spinup 0.525` (W1's §13 handling column with the plate's ×1.05 handling multiplier).

| Measurement | Measured | Spec | Delta |
|---|---:|---:|---|
| Time to reach max speed from rest | 2.5250 s | `accel_time` 2.52 | +0.005 s (one 120 Hz step) |
| Time from max speed to a stop, no input | 2.1000 s | `coast_time` 2.10 | 0.000 s |
| Time from max speed to a stop, S held | 1.4000 s | `accel_time / BRAKE_MULT` = 2.52/1.8 = 1.4000 | 0.000 s |
| Speed after 2 s of held S from rest | −406.609 u/s | reverse thrust reaches `max_speed` | −max, i.e. S drives backwards |
| Turn spin-up to 99 % of `turn_rate` | 0.5250 s | `turn_spinup` 0.525 | 0.000 s |
| Turn damping from full rate to ~0 | 0.5250 s | same rate, damping (§3.2 "damps down the same way") | 0.000 s |
| Autopilot arrival for a 1200 u order | cancels 36.265 u from the target, 4.250 s | ≤ `ARRIVE_RADIUS` 40 u | 3.7 u inside the ring, and the ship stays put |
| Order cancelled by thrust / by turn | true / true | §3.1 "any thrust/turn input does" | — |
| Order kept by firing | true | §3.1 "firing does not cancel" | — |
| Afterburner peak (fit carrying `b_afterburner`) | 650.566 u/s | `max_speed × 1.6` = 650.560 | +0.006 u/s |
| Second afterburner activation with boost held | 8.008 s | `cooldown` 8.0 (09 §3.5) | +0.008 s |
| Fold-only fit with boost held | peak 0.000 u/s, no displacement | blink is slice 4 | inert, as the brief requires |

### 4.2 Scene behaviour

| Check | Measured |
|---|---|
| Flight scene boots headless | `EXIT=0`, no script errors or warnings |
| Ship seated on the sector's spawn point | `ship=(0.0, 420.0)` = `spawn_point()` = 300 u off W4's 120 u dock ring (`PLAYER_SPAWN_OFFSET`) |
| Camera starts on the ship | `camera=(0.0, 420.0)` |
| Minimap feed | `kinds=["self", "friendly", "neutral" ×5]` — station friendly blip + one per field |
| Dock prompt outside / inside the dock zone | `''` → `'F · DOCK'` |
| `interact` route | absent from the map (orchestrator-applied later), so the guarded key path fires 0 routes; the shipped route body emits `loading{destination: station}` and files vitals |
| ESC | order `true → false`, 0 routes (ESC no longer docks) |
| Warp channel | progress 0.17/0.33/0.50/0.67/0.83/1.00 at 0.5 s steps, lands docked after 3.02 s, bar hidden (0.00) after |
| Warp break on damage | 0.33 mid-channel → 0.00, `_warp_active=false`, 0 routes |
| Warp gate | ready with a station and 5 s of quiet; blocked while hurt; false in `sector_7` (no station, §7 "no station → unavailable") |
| Sector param through the loading bridge | `on_route({sector: "sector_7"})` re-populates, re-seats the ship and relabels the HUD (`Maw Belt`); returning to `sector_1` restores a station |
| Retired mocks | `game.tscn` has no `Player`/`TargetBody` node; the ship is the instance of `res://game/player_ship.tscn`; `game.gd` declares no `MOCK_*` constant and keeps no mock drain (the class doc names the retirement) |

## 5. Pinned interface compliance (item 3)

| Pin | Implementation |
|---|---|
| `game/player_ship.tscn` root `Node2D` named `PlayerShip` | exact; also declared in the scene's `groups` and re-asserted in `_ready` |
| group `&"player_ship"` | `groups=["player_ship"]` in the scene + `add_to_group` in `_ready` |
| script `player_ship.gd` | `class_name PlayerShip extends Node2D` |
| hull `Sprite2D` at the current `ship_vanguard_side.png` scale | `Hull` child, texture `ship_vanguard_side.png`, `scale 0.0663` (the shipped `game.tscn` value) |
| mining-laser child (W3's scene) | `MiningLaser` child, mounted by guarded path (§6 item 1); measured: `script=res://game/mining_laser.gd`, `bind`/`set_active` present, holds on `mine` |
| `setup(stats: ShipStats, state: PlayerState)` | exact signature |
| `set_move_target(pos: Vector2)` / `cancel_orders()` / `warp_available() -> bool` | exact |
| `game.tscn` keeps its `Camera2D`; `game.gd` keeps following the player | `Camera` node kept; `_follow_ship()` sets `_camera.global_position = _ship.global_position` |

## 6. Deviations, interpretations and open points

1. **The mining laser is mounted by guarded path, not as a `.tscn` `ext_resource`.** The brief's
   item 3 says the scene "contains" W3's laser child. W2 and W3 ran in parallel, and a hard
   `ext_resource` on a file that does not exist yet makes `player_ship.tscn` — and with it
   `game.tscn` — unloadable, so the whole wave would have been untestable mid-flight. The mount
   therefore follows the project's existing cross-wave convention (`game.gd`'s HUD load): prefer
   an existing `MiningLaser` child, else `ResourceLoader.exists` + `load` + `instantiate` +
   `add_child`, then `bind(stats)`. **Reversal:** W3 has now landed, so this is a one-edit change
   — either add the `ext_resource` instance to `player_ship.tscn`, or leave the code and let the
   `get_node_or_null` branch take over. Measured working both ways through the same call sites.
2. **The afterburner is inert in the shipped v1 launch.** 09 §7's `STANDARD_FIT` has
   `boosters: []`, so `ShipStats.boosters` is empty and `boost` does nothing on the launch ship;
   the module is bought at the station (P2 fitting). The brief's "keep the `boost` action as
   afterburner … reading `ShipStats.boosters`" is implemented exactly, and the effect is measured
   with a fit that carries the module. **Owner ruling wanted:** accept (it arrives with the
   fitting UI), or add `b_afterburner` to the slice-1 launch fit (one line in W1's
   `STANDARD_FIT`, not W2's file).
3. **Booster activation numbers live in `ShipFit.MODULES`, not here.** `ship_stats.gd`'s own doc
   names `ShipFit.MODULES` (`effects.boost_speed_mult`/`duration`/`cooldown`/`blink_distance`) as
   their home, so `player_ship.gd` reads them; §13 carries no booster row and 09 §3.5 does. No
   duplicate constant exists in W2's files.
4. **Cooldown is counted from activation.** 09 §3.5 says "+60 % speed for 3 s, 8 s cooldown"
   without fixing which event starts it. Implemented as "8 s from the press" (3 s active + 5 s
   locked); measured second activation at 8.008 s with `boost` held. One-line reversal if the
   owner reads it as "8 s after the effect ends".
5. **§13 values that live in W2's files (the full list, for the W6 number audit).**
   `player_ship.gd`: `BRAKE_MULT 1.8` and `SLOW_DOWN_RADIUS 240` / `ARRIVE_RADIUS 40` (§13),
   `WARP_DAMAGE_QUIET 5.0` (§7), `scale 0.0663` (the shipped hull scale, per the pin).
   `game.gd`: `WARP_CHANNEL 3.0` (§13), `DOCK_PROMPT "F · DOCK"` (§W2 item 4), and the already
   shipped `HUD_REFRESH_INTERVAL 0.1`, camera zoom 0.10/0.70/1.50/0.18 s (§9.8 item 4) and
   minimap 3200/800/800/6400 (§9.8). W1's typed const covers the per-class handling table only,
   so these globals are single copies here; if slice 2 wants one §13 home for them, that is a
   refactor, not a fix.
6. **Dock-zone detection is delegated to the sector** (`Sector.dock_zone_contains`, W4's
   documented W2 handoff) rather than re-derived in `game.gd`. The pinned `PlayerShip` root is a
   plain `Node2D`, so a physics overlap would report nothing — W4's file says the same and
   derives its own ring radius; nothing invented on W2's side.
7. **Sector row and interim HUD label.** `_ready` populates `sector_1` (Halcyon Reach, T1,
   Concord home space) and the HUD keeps the §9.8 item 5 interim label `Helios Drift`. The
   `sector` param the loading bridge already forwards (`loading.gd` `SECTOR_KEY`) is honoured in
   `on_route`: a matching id or name re-populates, re-seats the ship and relabels. **Open point:**
   the station's LAUNCH sends no `sector`, so a live launch shows the interim label while flying
   `sector_1`'s contents. Either switch the label to the row's `name` (one line) or send the param
   from the station — an owner/cross-wave call, not W2's to make.
8. **`damage_taken` is a new signal on `PlayerShip` (additive).** The brief says "connect the
   hull/shield change to cancel the channel"; the ship already holds the `PlayerState` (via
   `setup`) and owns the §7 quiet clock, so it raises `damage_taken(amount)` on a *pool decrease*
   and `game.gd` connects that one signal. The decrease test is what keeps a future shield-regen
   tick (§4.2, slice 2) from breaking a channel. No signal was removed or renamed.
9. **`_enemy_engaged()` returns `false`, documented at the function** (brief item 5's seam). Slice
   2 replaces the body with the §7 "hostile in Alert/Engage targeting the player" test; the
   5-second quiet half of the gate is already real and measured.
10. **Ships do not collide with rocks.** ENGINE_SPEC §6 says rocks are solid and block shots and
    beams, and W3 ships them as `StaticBody2D`, but the pinned `PlayerShip` root is a bare
    `Node2D` with no collision body, no slice-1 file list owns one, and §13 carries no collision
    radius to derive one from. The ship currently flies through rocks. **Recommendation:** assign
    a `CharacterBody2D` (or `Area2D`) hull proxy to a W7 fixer; W2 owns `player_ship.tscn`, so the
    seam is one node plus a `move_and_collide` step in `_advance`. Not silently redesigned here.
11. **`--script` runs cannot compile `game.gd`** (it reads the `Router` autoload by global name;
    a custom main loop does not register autoloads as identifiers). Pre-existing, unrelated to
    W2's edits, and the reason W2's scene-side probe is a scene run. W6's re-measurements should
    use a scene run or a `load()` probe.
12. **`game/player_state.gd` still has the one-argument `damage()`.** §12 item 5's
    `damage(amount, bypass_shield := false)` is documented in the plan but implemented nowhere:
    W0 reported it as outside its docs-only remit and no slice-1 file list owns it. W2 needs
    neither half of that change (the channel break rides the pool signals), so it is left for the
    orchestrator to assign — a W7 candidate alongside item 10.
13. **Low: the camera follows one frame behind.** `Camera2D` reads the ship's position in
    `game.gd`'s `_physics_process`, which runs before the child ship's own physics step, so the
    follow is one physics frame late; `position_smoothing_enabled` (5.0) makes it invisible, and
    the shipped behaviour is preserved rather than re-timed.

## 7. State handed to W5 and W6

- `game.gd` already calls the §9.9 HUD additions: `set_prompt(text)` with `"F · DOCK"` /
  `""`, and `set_warp_channel(progress)` on 0…1 (0 hides). Both are `has_method`-guarded, so W5's
  HUD is wired the moment it lands, and the frozen §3.10 gate list is unchanged — W5 must keep
  the eight existing methods and the three signals.
- Blips handed to the HUD are `{"pos": Vector2, "kind": StringName}` with `&"self"`,
  `&"friendly"` (station) and `&"neutral"` (one per field) present today; `&"hostile"` and
  `&"scout"`/POI subkinds are slice 2/3.
- `PlayerShip`'s public surface for other workers: `setup`, `set_move_target`, `cancel_orders`,
  `warp_available`, `has_booster`, the `damage_taken` signal, and the group `&"player_ship"`.
- W3 integration verified end-to-end: the laser mounts under `PlayerShip`, `bind(stats)` is called
  at setup, and the `mine` action drives `set_active` on the edges (no input read in W3's file).
