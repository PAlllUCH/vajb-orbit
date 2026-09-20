# Engine wave 1 — W6 review report

Reviewer: W6. Scope (per `.agents/gen/engine_wave1_task.md` §W6): `ENGINE_SPEC.md`
§2/§3/§6/§7/§8/§9/§13, every file changed by W0–W5, all six reports, the pinned
interfaces, and the five cross-worker seams. Method: **measure, never trust the
reports.** Every number below was re-derived by headless run on 2026-09-18; every
report claim that could be checked from disk was re-checked.

Result: **21 findings — 4 HIGH, 7 MED, 10 LOW.** All five named seams are broken
except the ones the wave already documented, and the two headline slice-1
interactions (dock, safe warp) are inert in a live build because their input
actions were never applied. The mechanics the wave does own (flight, mining,
pickups, spawns, HUD strip/bar) reproduce §13 and the brief to within one physics
step.

---

## 0. Gates run (exact commands)

```
# 1. engine-wave review probe (scene run; source archived, see §7)
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless \
  --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tools/_probe_w6_review.tscn
-> exit 1, "=== w6 review probe: checks 42, failures 5 ==="   (.agents/gen/engine_wave1_w6_probe.txt)

# 2. flight-scene boot gate
... --headless --path <proj> --quit-after 180 res://game/game.tscn
-> exit 0, stdout = banner + godot_ai helper line only, no ERROR/WARNING  (.agents/gen/engine_wave1_w6_boot_game.txt)

# 3. the P1 economy suite
... --headless --path <proj> res://tests/headless_runner.tscn
-> exit 0, "[SUMMARY] passed=53 failed=0"  (.agents/gen/engine_wave1_w6_tests.txt)

# 4. probe-hygiene control: --script cannot compile game.gd
... --headless --path <proj> --script res://tools/_probe_w6_script.gd
-> "Compile Error: Identifier not found: Router at: game.gd:478" (exit code 0, see §6)  (.agents/gen/engine_wave1_w6_script_try.txt)
```

Probe source archived at `.agents/gen/engine_wave1_w6_probe_source.gd` +
`…_source.tscn`; copy both to `res://tools/_probe_w6_review.gd|.tscn` to re-run.
The throwaway copies and their `.uid` sidecars are deleted: `vajb-orbit/tools/`
holds only `build_theme.gd` and `derive_icon_tints.gd` (+ their `.uid`).

---

## 1. File identity — every report's size and md5 re-measured (all match)

| File | Bytes | md5 (measured) | Report agrees |
|---|---:|---|---|
| `game/ship_stats.gd` | 1 161 | `E0ED5BFB5D1003BCC5C744D148831825` | W1 ✓ |
| `game/ship_fit.gd` | 16 022 | `6061432175AC933FAB99E6D56E450940` | W1 ✓ |
| `game/player_ship.gd` | 11 216 | `6EA28365A486B916280E33CDBD0DAA53` | W2 ✓ |
| `game/player_ship.tscn` | 432 | `B8532F34D6BE08BF8E00740BCAAE5795` | W2 ✓ |
| `game/game.gd` | 16 208 | `03144938FA5FDB92D30CBD5AA6DB8914` | W2 ✓ |
| `game/game.tscn` | 1 700 | `726C1B2584D654B466270AC2D5FFE170` | W2 ✓ |
| `game/asteroid.gd` | 5 834 | `36493D5C7D7BD7470796E87B8C10D4C1` | W3 ✓ |
| `game/asteroid_field.gd` | 8 686 | `6A299942EDD699974F04D4AFD20C5DDD` | W3 ✓ |
| `game/mining_laser.gd` | 8 428 | `792305ECD1AB50CBEEDC78D483AFD6FF` | W3 ✓ |
| `game/mining_laser.tscn` | 333 | `AE7437E276EEC22A543DC2813DE695A5` | W3 ✓ |
| `game/pickup.gd` | 6 775 | `91594EA0A15010821F24BE489FD189EC` | W3 ✓ |
| `game/sector_registry.gd` | 5 815 | `C3F3AE450CEF4F03FAE0233EA4DB2077` | W4 ✓ |
| `game/sector.gd` | 12 438 | `02BE97B023CED32ABA4D7023DA69B5B8` | W4 ✓ |
| `ui/hud/hud.gd` | 21 142 | `0AE885ACDC87F6DC06ED5480F7419BBE` | W5 ✓ |
| `ui/hud/hud.tscn` | 18 780 | `343D63F205AAF24282AE5BFB908FE674` | W5 ✓ |
| `ui/hud/minimap.gd` | 5 698 | `8EB85539C5E7924A5152422CB2AD1675` | W5 ✓ |
| `ui/hud/target_reticle.gd` | 6 553 | `98FEA21048E6746F9B6D3ACA2DF7BDD5` | W5 ✓ |

Untouched, re-measured: `ui/theme/vajb_theme.tres` 25 771 B, mtime **15:16:36**,
md5 `F0BF1B434CB19EDD0FEE7001B17632B4` (W5's figures exactly — the HUD pass added
no theme item); `tools/build_theme.gd` md5 `3962995AA4E7C48E02B647A4B5DA630D`;
`project.godot` md5 `1E69D6C2F84C9FAF26F631FDBD202A7B` (no wave-1 edit).
No `MOCK_` identifier survives in `game/` (`MOCK_*` remains only in the retired
`ui/screens/_mockup_station.gd`, scheduled for deletion by
`IMPLEMENTATION_PLAN.md` §9.6, and in one `game.gd` doc comment). No hex colour
literal appears in any wave-1 file (`Color("#…")` hits are P1 catalogue files).
`turn_spinup` has exactly one owner (`ship_fit.gd` `HANDLING`; `player_ship.gd`
only consumes the `ShipStats` field) — the "single owner" pin holds.

## 2. Interface aggregation checklist (pinned items 1–9)

| Pin | Verdict | Evidence |
|---|---|---|
| 1. `ShipStats extends RefCounted`, the 16 fields with the pinned types | **pass** | `game/ship_stats.gd:1-31`; resolved values measured (§3.1) |
| 2. `ShipFit.resolve(hull_id, fit) -> ShipStats`; `STANDARD_FIT`; handling table single owner | **pass** | `ship_fit.gd:362-371`, `:378`, `HANDLING :127-191` = §13 for all 9 classes (§3.2) |
| 3. `player_ship.tscn`: root `Node2D` `PlayerShip`, group, script, hull sprite at 0.0663, laser child; API `setup`/`set_move_target`/`cancel_orders`/`warp_available` | **pass**, one structural note (LOW-2) | `player_ship.tscn:6-11`; the laser child is mounted at runtime, not in the `.tscn`; reached and functional (§3.4) |
| 4. `Asteroid extends StaticBody2D`, `setup(mineral_id, tier, yield_units)`, `apply_work -> int`, `WORK_PER_UNIT 1.0`, `cracked` | **pass** (param *names* differ, LOW-8) | `asteroid.gd:23,27,87,102,132`; measured §3.3 |
| 5. `MiningLaser`: `bind(stats)`, `set_active(bool)`, hold `mine`, 220 u, 1.2 s → 1 unit → 1 `Pickup` | **pass** | `mining_laser.gd:29-30,79,86`; measured §3.3; `project.godot` `mine` = key 69 (E) |
| 6. `Pickup`: `setup(item_id, amount, is_credit_cache)`, 60 s, tractor 120 u @ 90 u/s, collect via `PlayerProfile` + `economy_log`, hold-full drifts, self-free | **pass** (param names differ, LOW-8) | `pickup.gd:30-32,64,99-110`; measured §3.3 |
| 7. `Sector.populate(row)` / `blips()`; `WorldClock` only, no second clock | **pass** (additive optional `random_seed`, LOW-3) | `sector.gd:89,191,204`; `WorldClock.bands_between` reused, no `Timer` in the file |
| 8. `SectorRegistry`: `static SECTORS`, 7 rows, six keys; `SECTOR_SIZE` 10 000² | **pass** | `sector_registry.gd:31,51-115`; 7 rows, every row's tier weights byte-equal to 11 §1.1, every pirate band equal to §13 |
| 9. HUD `set_prompt`, `set_warp_channel`, `&"friendly"` blips, cursor reticle states, static ESC hint retired | **pass** (states unwired, HIGH-4) | `hud.gd:237,247,258`; `minimap.gd:19-30,120`; `target_reticle.gd:24-29`; measured §3.4 |

## 3. Re-measured behaviour (measurements, not assertions)

Probe log: `.agents/gen/engine_wave1_w6_probe.txt`.

### 3.1 §13 world/combat constants as shipped — all match

`BRAKE_MULT 1.8` · `SLOW_DOWN_RADIUS 240.0` · `ARRIVE_RADIUS 40.0` ·
`MINE_CYCLE 1.2` · `MINE_LASER_RANGE 220.0` · `Pickup LIFETIME 60.0`,
`TRACTOR_RANGE 120.0`, `TRACTOR_SPEED 90.0` · `SECTOR_SIZE (10000, 10000)` ·
`WARP_CHANNEL 3.0` · `WARP_DAMAGE_QUIET 5.0` (§7's 5 s quiet). Also present and
untouched: camera zoom 0.70–1.50 step 0.10 (`game.gd:50-53`), minimap
800–6 400 step 800 (`game.gd:43-46`).

### 3.2 Handling — resolved table vs §13 (all nine classes)

`ship_fit.gd` `HANDLING` compared byte-for-byte with §13: fighter 450/2.0/1.6/3.4/0.4 ·
cutter 428/2.4/2.0/3.0/0.5 · miner 338/4.0/3.4/2.0/1.0 · trader 383/3.0/2.6/2.4/0.7 ·
corvette 495/2.2/1.8/3.2/0.45 · hauler 293/6.0/5.2/1.5/1.4 · gunship 360/4.4/3.8/1.9/1.0 ·
frigate 383/4.0/3.4/2.1/0.9 · destroyer 315/6.4/5.6/1.6/1.2 — **9/9 exact**, and
every §13 max speed = 08 §2's percentage × 450 u/s (100/95/75/85/110/65/80/85/70 %).
`HULLS` vs 08 §2: 9/9 hull/shield/cargo/hardpoints/power-out exact.

Vanguard standard fit resolves to `406.6 / 2.52 / 2.1 / 3.0 / 0.525` (the plate's
×1.05 on the times). Driven through the **shipped** `player_ship.tscn` at 120 Hz:

| Measurement | Measured | Spec |
|---|---:|---:|
| Time to max speed | 2.5250 s | 2.52 |
| Coast to rest | 2.1000 s | 2.10 |
| Brake (S) to rest | 1.3833 s | `accel_time / 1.8` = 1.4 (2 steps short — discrete `move_toward`) |
| Turn spin-up to 99 % | 0.5250 s | 0.525 |
| Autopilot 1200 u order | cancels 36.27 u from the target | ≤ `ARRIVE_RADIUS` 40 |

### 3.3 Mining and pickups

- `Asteroid.apply_work`: an 8-unit rock took exactly 8 × 1.0 work and reported
  depleted; ten 0.1 hits produced **exactly 1** unit (§6's 10 % gun rate).
- Shipped `MiningLaser` on a real rock: acquired the target under the cursor,
  0 pickups at 1.1 s of contact, **1 at 1.3 s**; one unit per `MINE_CYCLE`.
- `Pickup`: 110 u away travelled exactly 45.0 u in 30 frames at 60 Hz = 90 u/s;
  a credit cache paid +250 through `PlayerProfile.add_credits`; an ore pickup
  added 1 through `add_cargo`; a pickup aged to 59.999 s despawned at 60 s; a
  pickup at 30/30 u with the hold full neither moved nor collected.
- Sector spawns (seed per row): sector_1 5 fields/48 rocks, s2 8/71, s3 7/67,
  s4 4/38, s5 7/61, s6 7/76, s7 8/74 — every field inside 6–12 rocks, every
  sector inside 4–8 fields, blips = fields + station (s7 = fields only, no
  station). Live `game.tscn` boots sector_1 with the ship seated on the
  `populate` return `(0, 420)`.
- HUD wiring in the live scene: prompt invisible at the spawn and `F · DOCK` at
  the station centre; the warp bar shows while channelling and hides on cancel;
  0 labels still carry `ESC`.

## 4. Findings

### HIGH

**H1 — the HUD cargo bar can never move while mining (seam 1).**
`PlayerState.set_cargo_used()` has **no caller anywhere in the project**
(`grep set_cargo_used` → only the definition at `player_state.gd:68`), and
`game.gd` never reads `PlayerProfile.cargo_items()`. Measured in the live scene:
profile cargo 30 → 33 (and 33 → 35 after a literally collected pickup) while
`PlayerState.cargo_used` stayed **0** and the HUD footer stayed **`CARGO 0/40`**
for every frame. The ore reaches the profile (W3's probes and mine agree), but the
only channel the HUD reads (§3.9) is never written, so the hold-full HUD state and
the cargo bar are dead. W3 flagged the seam; it is still open. Fix belongs to a
`game.gd` owner: sum `PlayerProfile.cargo_items()` into
`PlayerState.set_cargo_used()` at the 0.1 s HUD refresh (and immediately after a
pickup collects).

**H2 — the player ship does not collide with rocks (seam 3, ENGINE_SPEC §6).**
§6 says "Rocks are solid: ships collide with them". `Asteroid` is a `StaticBody2D`
on layer 1 (measured), but `PlayerShip` is a bare `Node2D` with **0
`CollisionObject2D` descendants** (measured on the instantiated scene and in the
live game scene), so nothing can stop it. Measured: under thrust from (0, 0), in
6.7 s the ship ended at x = 2201.7 with a 66 u-radius rock centred at x = 200
(surface at 134 u) — a full pass-through. W2 disclosed this; it is still a §6
violation and it also removes the approach risk the dock ring and the rock fields
were laid out around.

**H3 — `PlayerState.damage` has no `bypass_shield` and ignores the shield (seam 4).**
§12 item 5 requires `damage(amount, bypass_shield := false)` and §4.2 makes a live
shield absorb with no carry-over. Measured: the method declares **1 argument**;
with `hull 500 / shield 100`, `damage(150)` left `hull 350` and `shield 100` — the
shield is not consulted at all, so the shield pool is decorative and slice 2's
damage pipeline has no seam to plug into. Fix is one file (`game/player_state.gd`),
two doc-required lines.

**H4 — nothing pushes the reticle state, so the mining reticle never appears (seam 2).**
`Hud.set_reticle_state` exists (`hud.gd:258`), but `game.gd` neither has a pusher
method (`_push_reticle_state`/`set_reticle_state` both absent from its script) nor
calls one anywhere in the project, so `TargetReticle.State` stays `PLAIN`.
Measured with
the live scene's laser actually active and a rock under the cursor:
`laser active=true has_target=true ; reticle state=0 (PLAIN)`. The plain state is
live, but the two states that carry slice-1 meaning (in-range / out-of-range) are
unreachable. W5's §7 already carries the one-hunk fix.

### MED

**M1 — the pickup hold gate and `PlayerState` read two different cargo tables.**
`pickup.gd:135` gates on `StationCatalog.ship(active_ship).cargo`;
`game.gd:180-193` seeds `PlayerState.cargo_max` from `ShipFit.HULLS[..].cargo`.
Only 4 of 9 hulls exist in `StationCatalog.SHIPS`, so for the other five the gate
computes 0 and **no ore pickup can ever be collected**. Measured: `ship_miner`
(`ShipFit` hold 55, `StationCatalog` row missing) → an ore pickup placed on the
player was not collected (cargo 35 → 35). Invisible today only because the
default active hull is the Vanguard (both sources 40). Add a `bind(stats)` seam or
read the hold from one table.

**M2 — `interact` and `warp` are absent from `project.godot`, and
`SettingsManager.REBINDABLE_ACTIONS` still lists 15 (seam 5).**
Measured: `rebindable_actions = 15`, `InputMap.has_action(&"interact") = false`,
`&"warp" = false`; `PROJECT_SETTINGS_PATCH.md` §2 lists **17** actions
(`input_action_count: 17`, orders 16/17 = F/H). Consequence today: the guarded
dock and safe-warp paths are **inert in a live build** — F does nothing, H does
nothing. W0 flagged the const as a code gap. The action application is the
orchestrator's planned post-wave step; the const extension is unassigned.

**M3 — the mining laser is mounted and fires for every fit, including one without `w_mining`.**
`STANDARD_FIT` has no `w_mining` (`standard fit lists w_mining = false` measured)
yet `player_ship.gd:_mount_mining_laser` attaches it unconditionally and `E`
mines. 09 §4.5 and §4.3 ("whenever it is fitted") make `w_mining` a **W-slot**
module, so the W-slot cost — the whole point of the Delver/Fighter trade-off — is
not enforced. The brief's pinned item 5 does say "child of PlayerShip (W3 owns, W2
mounts)", so this is a brief-vs-spec deviation, not worker drift; it needs an owner
decision (gate the mount on the fitted `w_mining`, or drop the W-slot rule).

**M4 — sector 7 spawns no station, contradicting §8's blanket "1 primary station".**
`sector_registry.gd:113` passes `stations = 0` for the Maw; §8 says "1 primary
station + 0–1 outpost" for every sector, while §7 says warp "reports unavailable
(no station in the sector)". W4 read §7 as authoritative and asked for
confirmation. Measured: s7 blips = fields only, `has_station = false`, warp gate
false. Owner ruling needed; reversal is one argument.

**M5 — field respawn semantics differ from 02 §8 on both halves.**
(a) 02 §8 says "20 minutes **after a field is fully depleted**"; `sector.gd`
respawns on the 20-minute `WorldClock` band only, so a field depleted just after a
band boundary waits ~40 min. (b) 02 §8's ×0.7 window is `now − last_respawn <
300 s`, but `asteroid_field.gd:98-104` stamps `last_respawn_time` and rolls
immediately, so every respawned field is at ×0.7 and the window can never be
partly elapsed. Both are deliberate readings (W3/W4 disclosed them) and both are
testable, but the doc text and the code do not agree. Also LOW-9 below.

**M6 — `TargetReticle.clear_target()` changed a frozen §3.10 behaviour.**
The reticle is now always visible and `clear_target` only drops the lock's
brackets and micro-bar. The signature and the locked-target look (UI_SPEC §3.5)
are unchanged and the change is what §9.9's cursor reticle implies, but it is a
behavioural change to a method the plan calls frozen, and it is not
pixel-verified (no framebuffer headless). Needs a one-line owner sign-off or the
reversal `visible = _has_target`.

**M7 — 02 §9 still says asteroid combat is out of scope; ENGINE_SPEC §6 ships it.**
`docs/gameplay/02_minerals.md:190` reads "Asteroid combat (shooting rocks to break
them faster) — the mining laser is the only extraction tool in v1", while §2
decision 6, §6 and §13 ship "guns apply work at 10 %". The code implements the
spec (measured: ten 0.1 hits = 1 unit) and W0's brief did not include 02. The
docs-first rule is broken for this one sentence; the spec is newer, so a
transcription into 02 is the fix.

### LOW

**L1 — invented constants, all disclosed, none gameplay-breaking.** §13 has no
value for, and no doc supplies: `ARRIVAL_RADIUS 16`, `POD_WIDTH 20`,
`LOOK_WIDTHS 48/84/132`, `WORK_EPSILON 0.0001`, `FIELD_RADIUS 400`,
`FIELD_INNER_FRACTION 0.35`, `FIELD_ANGLE_JITTER 0.25`, `DOCK_RING_RADIUS 120`,
`FIELD_STATION_CLEARANCE 1800`, `FIELD_EDGE_MARGIN 800`, `FIELD_SLOT_JITTER 0.25`,
`SPAWN_BEARING`, `CLOCK_POLL_SECONDS 1.0`, the reticle/cursor geometry
(`CURSOR_GAP/TICK/RADIUS/DOT/SLASH`), `FRIENDLY_RADIUS 3.0`, the mining-beam
widths/alphas, `PERCENT_FORMAT`, and the one gameplay inference
`BASE_SCAN_RANGE 900` (derived from §4.1 + §13's lock range — flagged by W1 with a
one-const reversal). Each is disclosed in its worker's report; none silently
re-tunes a §13 value.

**L2 — mining-beam look deviates from FX_SPEC §1.6.** FX_SPEC fixes an ember beam
with a four-frame chip-spark burst; the brief overrides the colour ("neutral/steel
token") and the code draws `metal_light` + `text_dim` (measured), with no spark
texture and no crack FX. Recorded as art gaps, not code defects.

**L3 — the mining chip cue is `_01` only,** not a 01–04 round-robin, because
`sfx_mining_chip_04` is a documented 21 s asset-audit outlier. Deliberate.

**L4 — additive API beyond the pin, all disclosed:** `ShipFit.fitted_ids()`,
`ShipFit.power_budget()`, `PlayerShip.damage_taken`, `Hud.set_reticle_state`,
`Sector.spawn_point/spawn_plan/has_station/station_position/dock_zone_contains/
field_count/fields/refresh_clock`, `AsteroidField.diminishing_active` and friends.
Nothing pinned was renamed or removed.

**L5 — §10 items deliberately deferred:** the `set_target_info` range state,
reticle hit markers and POI subkinds are not in the slice-1 pinned list and are
not half-implemented.

**L6 — `Q` (`target_next`) and `fire_secondary` are unwired in `game.gd`** —
slice 2 (no NPCs, no weapons). `_fire()` still decrements ammo with no weapon
system behind it, as shipped.

**L7 — the interim HUD label.** `game.gd` keeps `SECTOR_NAME = "Helios Drift"`
while flying `sector_1` Halcyon Reach, and the station's LAUNCH sends no `sector`
param, so a live launch shows the interim label. W2's open point.

**L8 — parameter names differ from the pins** on `Asteroid.setup(mineral,
mineral_tier, units)` vs `setup(mineral_id, tier, yield_units)` and
`Pickup.setup(item, quantity, credit_cache)` vs `setup(item_id, amount,
is_credit_cache)`. GDScript has no named arguments, so call sites are unaffected;
cosmetic only.

**L9 — `AsteroidField.last_depleted_time` is written but never read** for any
gate (the sector drives respawn), and `mining_laser.gd`'s comment for
`MINE_LASER_RANGE`/`MINE_CYCLE` cites "05 §13" where the value is ENGINE_SPEC §13.
Bookkeeping/comment nits.

**L10 — process:** W2, W3 and W4 deleted their probe sources (only their stdout
survives), so their exact acceptance runs are not re-runnable from disk the way
W1's and W5's are. This W6 pass archives its own source (`.agents/gen/
engine_wave1_w6_probe_source.gd|.tscn`) and its log. Also, `--script` load
failures exit **0**, so an exit-code-only gate silently passes a script that never
compiled (§6).

## 5. What the wave got right (re-measured, not taken on faith)

The §13 table, the 08 §2 hull table and the 09 §3 module table are reproduced
exactly (module draws/effects checked row by row against 09 §3.1–§3.8, and every
tier weight against 11 §1.1). Flight reproduces the per-class times to one 120 Hz
step, including the `BRAKE_MULT` brake and the arrive-steering radius. The mining
work model is exactly §6's two rates through one `apply_work` path. The pickup
behaviour matches §13 and 02 §7 (60 s, 120 u, 90 u/s, hold-full drifts, per-item
cargo, credits via `add_credits`, one economy-log line each). Sector population
matches §8/§13 counts for all seven rows, `blips()` shape is `{pos, kind}` with the
station friendly, and the sector reads the one `WorldClock` with no second timer.
The HUD prompt strip, warp bar, friendly diamond blip and ESC-hint retirement all
work in the live scene, and the P1 suite stays 53/53.

## 6. Probe hygiene (confirmed by measurement)

- **A scene run is the reliable gate.** A `--script` main loop cannot compile
  `game.gd`: measured `Compile Error: Identifier not found: Router at:
  game.gd:478`. Note the `--script` run **exited 0** despite the failed load, so a
  gate that only reads the exit code would pass a script that never compiled.
- **A `SceneTree` probe must call `quit()`** or it hangs; both archived probes end
  every path with `get_tree().quit(code)` and carry a 90 s watchdog.
- `set_physics_process(false)` sticks for nodes disabled in the same frame they
  enter the tree, so manually driven probes are deterministic; pickups must be
  disabled **before** the first frame or the engine collects them mid-measurement.
- Headless physics ticks at 60 Hz; drive manual pickups at 1/60 and manual flight
  at 1/120 to match the numbers above.

## 7. Handoff

| # | Finding | Owner | Size |
|---|---|---|---|
| H1 | mirror profile cargo into `PlayerState.set_cargo_used` | `game.gd` | ~5 lines |
| H2 | give `PlayerShip` a collision body that masks the rock layer | `player_ship.tscn` + `player_ship.gd` | ~1 node + 1 step |
| H3 | `PlayerState.damage(amount, bypass_shield := false)` + shield absorption | `game/player_state.gd` | ~8 lines |
| H4 | push the mining reticle state from `game.gd` | `game.gd` | 1 hunk (W5 §7) |
| M1 | one hold source for the pickup gate | `pickup.gd` (+ `PlayerShip` accessor) | ~3 lines |
| M2 | apply `interact`/`warp`; extend `REBINDABLE_ACTIONS` to 17 | orchestrator / `settings_manager.gd` | 1 patch + 2 rows |
| M3–M7 | owner rulings, then one small edit each | owner | — |

Everything above is re-runnable: copy
`.agents/gen/engine_wave1_w6_probe_source.gd|.tscn` into `res://tools/` as
`_probe_w6_review.gd|.tscn`, run the §0 command, and the probe reprints
`checks 42, failures 5` with the same numbers. Delete the copies and their `.uid`
afterwards.
