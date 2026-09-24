# S6-K1_report — travel core (registry rows, gates, corridors, transitions)

**Worker:** S6-K1 (`VAJB_WORKER_FILES="vajb-orbit/game/sector_registry.gd,vajb-orbit/game/gate.gd,vajb-orbit/game/corridor.gd,vajb-orbit/game/game.gd,vajb-orbit/game/sector.gd,vajb-orbit/tests/"`)
**Wave:** S6 Travel (engine slice 3 + RPG P3). Brief `.agents/gen/slices/S6-travel/S6_BRIEF.md`; pin `docs/CONTRACTS.md` §19; docs `docs/gameplay/11_galactic_map.md` §2/§3/§5, `17_coder_handoff.md` §5, `18_engine_spec.md` §14 slice 3.
**Date:** 2026-09-24. **Tree:** working tree with the parallel D6 lane in flight (`ui/hud/**`, `tests/test_d6_*.gd`, `project.godot`'s `ship_status` action are D6's churn, not touched here).

**Gate (measured, full suite, headless):** `[SUMMARY] passed=626 failed=0`.
Delta from this worker: **+18 tests** (`tests/test_s6_travel.gd`) and **one pre-existing assertion corrected** (`tests/test_engine2_wiring.gd`, see §5.1). Before K1's suite the same run read `passed=607 failed=1`; K1 turns the one fail into a pass and adds 18 passes.

---

## 1. What shipped, against the pin

| §19 item | Where | State |
|---|---|---|
| `SECTORS` rows gain `neighbours`/`gate_links`/`corridors` | `game/sector_registry.gd:141-148` (merged after the row literals) | done |
| `GATE_FEE_BASE` 150 / `GATE_FEE_PER_SECTOR` 100 / `CORRIDOR_DEPTH` 600.0 | `game/sector_registry.gd:52-61` | done |
| `DERELICT_SCAN_RANGE` 300.0 / `RIFT_DRAIN` 12.0 / `ANOMALY_WEIGHTS_RIFT_DOUBLED` | `game/sector_registry.gd:63-69` | done, for K2 (see §5.2) |
| `game/gate.gd` (`class_name Gate extends Area2D`, `setup`/`fee_for`/`jump`) | new file, 5,692 B | done |
| `game/corridor.gd` (`class_name Corridor extends Area2D`, `setup`/`hold_progress`) | new file, 2,253 B | done |
| Transition through the `loading` route, filing first | `game/game.gd:711-740` (`_transition_to_sector` / `_request_sector_route`) | done |
| One prompt-line owner | `game/game.gd:616-652` (`_update_dock_prompt` arbiter + `_push_gate_prompt`) | done |
| Stale `SECTOR_NAME` replaced by the registry name | `game/game.gd` (const removed; `_sector_name` set in `_spawn_sector`) | done |
| Gate/corridor spawn + `blips()` gate entries | `game/sector.gd:467-521` (`_spawn_travel`), `:227-253` (`gates()`/`corridors()`), `:255-273` (`blips()`) | done |
| No `ui/hud/**`, `assets/**`, `project.godot`, theme, docs write | — | honoured |

**No frozen method was renamed, retyped or removed.** Every existing public signature in `game.gd`/`sector.gd`/`sector_registry.gd` is intact; the additions are new private functions, one new public `Gate`/`Corridor` class each, three new registry helpers (`edge_band`, `sector_number`, `sector_id_for`, `distance`) and the three pinned row keys.

---

## 2. The fee, measured (11 §2.1 + §5)

`fee_for(heat_tier) = floor((150 + 100·d) × want × lawless)`, `d = |dest − origin|` along the §2.3 spine, `want = 1.5` at `NpcRegistry.HEAT_WANTED` only, `lawless = 2.0` into sector 7 (`sector_registry.LAWLESS_SECTOR`).

| case | d | tier | fee | note |
|---|---:|---|---:|---|
| adjacent (1→2) | 1 | clean | **250** | 11 §2.1's own row |
| two away (1→3) | 2 | clean | **350** | 11 §2.1's own row |
| two away | 2 | wanted | 525 | `floor(350 × 1.5)` |
| two away into 7 (5→7) | 2 | clean | 700 | `floor(350 × 2)` |
| two away into 7 | 2 | wanted | 1050 | `floor(350 × 1.5 × 2)` |
| adjacent into 7 (6→7) | 1 | suspect | 500 | lawless alone |
| adjacent into 7 | 1 | **wanted** | **750** | `floor(250 × 1.5 × 2)`; **562 is not produced** (it is `floor(250 × 2.25)`, the additive reversal) |

`jump(profile, heat_tier)` measured: Outlaw → `-1`; a 249 CR account vs the 250 fee → `-2`; both leave `StubProfile.spend_calls == 0` and the balance unchanged. A successful jump: 1000 → **750**, one `spend`, `GATE` economy-log line, `is_charging()` true; a second confirm inside the same charge-up returns `0` with no second charge; `advance_charge(1.0)` emits nothing, `advance_charge(1.0)` emits `jumped(2)` once.

**Live-profile refusal byte proof** (`test_gate_refusal_on_the_live_profile_is_byte_identical`): a deep snapshot of `{credits, cargo_items, heat, standing, ammo_of(laser), vitals_of(active_ship)}` is byte-equal before and after both refusals on the shipped `PlayerProfile` autoload.

---

## 3. The corridor, measured (11 §2.2 + §5 tick 2)

- `update_presence(7.5, centre)` → `hold_progress() == 0.5`; leaving the band → `0.0` and `is_holding() == false`.
- `update_presence(14.9, …)` emits nothing; `+0.2` emits `crossed(dest)` **once**; a further step does not re-fire.
- **Hull damage does not interrupt**: on the live scene, 5 s of presence (progress 0.333) is unchanged after `scene._on_ship_damage_taken(25.0)` (the ship's own damage signal handler). `Corridor` has no damage input at all, so presence is the only writer of the hold.

---

## 4. The transition, measured (11 §2.3 / AC4)

On a live `game.tscn` with the ship's pools set to hull 37 / shield 12 / fuel 88, hold `{iron_ore: 7}`, heat `{concord: 42}`, and one pickup in the scene:

- `_transition_to_sector(2)` emits `route_requested(&"loading", {destination: &"game", sector: &"sector_2"})`, and the **vitals read at emit time** are already 37/12/88 — the filing runs before the route (the Router reloads the scene, so an unfiled crossing would reset the pools).
- A freshly instantiated `game.tscn` (the reload) reads hull 37 / shield 12 / fuel 88 from the filed record; `cargo_items()` is byte-equal to the pre-crossing hold; `heat()` is still `{concord: 42}`; pickups 1 → 0; `on_route({sector: "sector_2"})` lands `_sector_row_id == &"sector_2"` and `_sector_name == "Iron Marches"`.
- `SECTOR_NAME` is gone; a plain launch labels `"Halcyon Reach"` (sector 1's registry name), not the stale `"Helios Drift"`.

---

## 5. Deviations, decisions and things the planner should know

### 5.1 Bucket 2 — one existing test moved, and the brief's "no test moves" list is short by it

`tests/test_engine2_wiring.gd:test_the_minimap_feed_carries_every_hull_plus_the_pois` pinned `blips.size() == hulls + fields + 1` and `friendly == 1` ("the station is the one friendly blip"). §19 requires `sector.gd:blips()` to gain gate entries and 11 §5 maps gates to `friendly`, so **the pin necessarily moves that row**. I applied the minimal correction: the expectation is now derived from the sector's own `gates()` count (`hulls + fields + gates + 1`, `friendly == gates + 1`), so the test's intent (one blip per hull/field, the station friendly) holds and a one-link and a two-link sector both pass. No other existing assertion changed. **The brief's "Tests that move: None of the existing counts move" is therefore incomplete and needs the developer's ratification.** K2's beacon/derelict/anomaly blips will move the same row again.

### 5.2 Bucket 1 route — `DERELICT_SCAN_RANGE`/`RIFT_DRAIN`/`ANOMALY_WEIGHTS_RIFT_DOUBLED` are landed here

§19 gives those three constants a home in `game/sector_registry.gd`, which is **only** in K1's file set (K2 owns `poi.gd`/`loot_tables.gd`/`sector.gd`/`game.gd`). They are added now so K2 reads them instead of inventing a second home or blocking.

### 5.3 Bucket 1 route — the crossing must not re-run the launch's ammo auto-load

`Router.route` reloads `game.tscn`, so `_ready` runs again and `_seed_ammo` would draw cargo units out of the hold a second time (the S5 per-launch auto-load), shrinking the hold across the crossing and contradicting AC4's "hold byte-equal". The outgoing scene sets a `static var _transit_destination` (`game/game.gd:158-165`) immediately before it routes; `_ready` reads it and seeds the packs from the filed store (`_seed_ammo_from_store`, `game.gd:1483-1495`) with no hold draw. Cleared in `_ready` and in `on_route`, so a same-scene `on_route` (a probe) cannot leave it armed. A dock launch is unaffected (the flag is only set by a sector crossing). Measured: the hold is byte-equal across the crossing.

### 5.4 Placement values with no doc source (report, never invent)

| constant | value | source | reversal |
|---|---:|---|---|
| `sector.gd:GATE_RING_RADIUS` | 900.0 u | 11 §2.1 says "near its primary station" only | one edit |
| `gate.gd:RING_SCALE` | 0.25 | 11 §2.1 says "visible from across the sector" only; 2048 u art → ~512 u | one edit |
| `gate.gd:TRIGGER_RADIUS` | 200.0 u | no doc gives the ring's opening | one edit |

The gate ring texture is the shipped `res://assets/env/poi/env_jump_gate.png` (ASSET_CATALOG, Phase D), no new art.

### 5.5 The pinned prompt copy carries an em dash

11 §5's lines are `JUMP TO <SECTOR> — <fee> CR` and `GATE REFUSED — OUTLAW`. The pin's U+2014 is written as a `\u2014` escape (`game/game.gd:106-108`) so the source stays plain ASCII while the runtime string is the pinned copy verbatim; the test asserts `"GATE REFUSED \u2014 OUTLAW"`.

### 5.6 Sector 7 has a gate but no station

The spine gives sector 7 `gate_links == [6]`, so a ring is spawned there even though 11 §2.1 says "every inhabited sector has a gate structure near its primary station". The ring is placed on the destination's edge bearing from the arena centre, which is the same formula every sector uses; 11 §2.1's "the only gate that goes to sector 7 is a Meridian expedition gate" is about the *inbound* gate (in sector 6). No arrival-point rule exists for a gate jump, so the transition seats the player on the destination sector's own spawn point (`_spawn_sector` → `populate`), unchanged from today's launch.

### 5.7 `spawn_plan()["beacons"]` is now live

11 §3's "one per corridor plus one per gate" is now computable, so `sector.gd:157` reads `_corridors.size() + _gates.size()` instead of the placeholder 0. No test pins the plan value; K2 spawns the beacons themselves.

### 5.8 Seams left for K2/K3, not stubbed

`game.gd:_on_npc_died` is untouched (K2 appends the band roll + wreck site; K3 appends the witness gate). `game.gd:on_route` already read `PARAM_SECTOR` and still does. `sector.gd:populate` gained `_spawn_travel` before the plan; K2's POI spawn joins the same call site. The prompt arbiter in `_update_dock_prompt` is the single ladder the scan readout and cache feed join.

---

## 6. Files touched

| file | change (insertions/deletions) |
|---|---|
| `vajb-orbit/game/sector_registry.gd` | +90/−4: +3 row keys (merged in `_static_init`), +3 fee/depth constants, +3 POI constants, +4 helpers |
| `vajb-orbit/game/gate.gd` | **new** (5,853 B) |
| `vajb-orbit/game/corridor.gd` | **new** (2,253 B) |
| `vajb-orbit/game/game.gd` | +166/−5: prompt arbiter, travel tick, seam binding, transition route, transit ammo seed, sector label |
| `vajb-orbit/game/sector.gd` | +100/−11: `_spawn_travel`, `gates()`/`corridors()`, gate blips, plan beacon count, `_clear` |
| `vajb-orbit/tests/test_s6_travel.gd` | **new** (21,424 B, 18 tests) |
| `vajb-orbit/tests/test_engine2_wiring.gd` | +12/−3: the minimap feed expectation (§5.1) |

Not touched: `ui/hud/**`, `assets/**`, `project.godot`, `addons/**`, `ui/theme/vajb_theme.tres`, `docs/gameplay/18_engine_spec.md`, `docs/gameplay/08_ship_slots_modules.md`, any docs file.

## 7. Owner ticks owed (from the brief, unchanged by this worker)

1. Fee multiplier composition — multiplicative as built, worked row 750; reversal additive (562).
2. Corridor rules — depth 600 u; damage does not interrupt the 15 s hold; reversal 400 u / damage-resets.
3. Derelict scan range 300 u (K2); reversal the fit's `scan_range`.
4. Rift drain 12/s (K2); reversal 6.
5. Data-core credits 120 (K2); reversal 60.
6. `test_engine2_wiring.gd`'s minimap feed row moved (§5.1) — ratify the corrected expectation.
