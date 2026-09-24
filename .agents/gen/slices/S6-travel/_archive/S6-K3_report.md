# S6-K3_report — heat enforcement, hunters and the bounty (AC5/AC6)

**Worker:** S6-K3 (`VAJB_WORKER_FILES="vajb-orbit/game/npc_registry.gd,vajb-orbit/game/npc_brain.gd,vajb-orbit/game/npc_ship.gd,vajb-orbit/autoload/player_profile.gd,vajb-orbit/game/game.gd,vajb-orbit/game/station_catalog.gd,vajb-orbit/ui/station/launch_panel.gd,vajb-orbit/tests/"`)
**Wave:** S6 Travel (engine slice 3 + RPG P3). Brief `.agents/gen/slices/S6-travel/S6_BRIEF.md`; pin `docs/CONTRACTS.md` §19 (its K0 dispositions block is binding); docs `docs/gameplay/13_heat_bounty.md` §2–§5/§7, `12_factions.md` §4.1, `17_coder_handoff.md` §4/§5, `14_station_services.md` §1/§7.
**Date:** 2026-09-24. **Tree:** the working tree with K1's travel core and K2's POIs/loot landed underneath (their uncommitted `game.gd`/`sector.gd`/`sector_registry.gd`/`loot_tables.gd` edits are the base this worker appended to) and the parallel D6 lane in flight (`ui/hud/**`, `docs/design/**`, `tests/test_d6_*.gd` are D6's churn, not touched here).

**Gate (measured, full suite, headless, scratch store):** `[SUMMARY] passed=674 failed=0`, twice on the identical final tree.
Delta from this worker: **+23 tests** (`tests/test_s6_heat.gd`). Baseline before this worker: `651/0` (K2). **No existing test count moved** and no existing assertion changed.

Two `ERROR:` lines appear in every run and are **pre-existing, not this worker's**: `Parameter "data.tree" is null` (`game/weapons.gd:2050`, reached from `test_combat_repair_c5.gd`) and `Cannot call method 'call' on a previously freed instance` (`test_weapon_fx_f4.gd:178`). Both fire with this worker's files reverted.

**Warning ledger: zero new rows.** A `--debug` gate run reports the same ten shadow/name warnings in the files this worker touched as the committed tree does (`game.gd` 631/647/1923/1950, `npc_registry.gd` 579/616/777, `npc_ship.gd` 168/623/673 — every one present in `HEAD`, only shifted by the insertions). `player_profile.gd`, `station_catalog.gd`, `launch_panel.gd` and `tests/test_s6_heat.gd` contribute none. One warning this worker introduced (`pay_bounty`'s local `heat` shadowing `heat()`) was caught in that run and renamed to `paid_off`.

---

## 1. What shipped, against the pin

| §19 / brief item | Where | State |
|---|---|---|
| Witness-gated gains: heat only with a neutral/patrol hull or station inside `WITNESS_RANGE` 900.0 with the brain's rock-blocking LOS | `game/game.gd:_witnessed`/`_is_witness_hull`/`_witness_visible`/`_station_witnesses`/`_rock_line_clear`; `WITNESS_RANGE := ShipFitScript.BASE_SCAN_RANGE` | done |
| Values verbatim from `heat_on_kill()`, +5 witness extra, never re-derived | `game.gd:_on_npc_died` reads the victim's own row; `WITNESS_EXTRA := 5` (13 §2) | done |
| Clamp every gain to 0–100 (13 §2) | `game.gd:_apply_heat` (`clampi(current + delta, 0, HEAT_MAX)`) | done |
| Decay −1/min of play through a float accumulator on `game.gd`'s tick; no Timer; `WorldClock` untouched | `game.gd:_decay_heat` + `_heat_play_time`; `HEAT_DECAY_SECONDS := 60.0` | done |
| `PlayerProfile.pay_bounty(faction_id)` — fine = heat × 25 CR, all-or-nothing, one `BOUNTY` line, zeroes that heat, refusals write nothing | `autoload/player_profile.gd:pay_bounty`/`bounty_fine`/`heat_of`/`standing_of`; `EVENT_BOUNTY`, `BOUNTY_CR_PER_HEAT` | done |
| Hunter row flipped off `SEAM_SLICE_4`; `KEY_TIER` stays 1; the hull map in `KEY_MEMBERS`; aggro/scan radius 900.0 | `game/npc_registry.gd` hunter row + `KEY_PLAYER_HULLS`, `hunter_members`/`hunter_wing_size`/`hunter_hull_for`/`hunter_spawn` | done |
| Wanted spawns `randi_range(2,3)` on next sector entry; Outlaw perma-tails with 60 s respawn; that faction's space only | `game.gd:_update_hunters`/`_spawn_hunter_wave`/`_live_hunters`/`_home_last_hunter`; `HUNTER_RESPAWN_SECONDS := 60.0` | done |
| Hunters drop their band table plus `HUNTER_EXTRA` | K2's `_spawn_kill_loot` (`archetype == HUNTER_ARCHETYPE`) — now reachable, measured | done |
| Dock refusal reads standing (`standing() <= −51`, 12 §4.1); gate refusal reads the heat tier (13 §3); both write nothing | `game.gd:_dock_refused` + `_request_dock` + `_update_dock_prompt`; gate half is K1's shipped `_push_gate_prompt`/`Gate.jump` | done |
| Trader flee at Suspect+ (brain's Flee), patrol scan-on-sight at Suspect+ (brain's Scan) | already shipped as row data; **made real for the convoy** by the `NpcShip._read_heat_tier` cure (§3.3) | done |
| Bounty surface: `PAY BOUNTY (n CR)` row beside REFUEL/RECHARGE + a `StationCatalog.SERVICES` row, shown for the docked station's faction when its heat > 0, calling `pay_bounty`, writing nothing on refusal | `ui/station/launch_panel.gd` (`SERVICE_BOUNTY`, `_refresh_bounty_row`, `_run_bounty`, `bounty_button`) + `game/station_catalog.gd` (`SERVICE_BOUNTY`, the `SERVICES` row) + `PlayerProfile.docked_faction` | done |
| No `ui/hud/**`, `assets/**`, `project.godot`, theme, `docs/**`, `game/heat.gd` write | — | honoured |
| Station turret: +25 on attacking a station, turret aggro staged | staged — see §3.7 | staged |

**No frozen method was renamed, retyped or removed.** Every existing public signature in the six source files is intact; the additions are new constants, new private functions, one new public `NpcShip.set_home`, four new `PlayerProfile` accessors (`heat_of`, `standing_of`, `bounty_fine`, `pay_bounty`), one transient `docked_faction` pair, four new `NpcRegistry` statics and one new `SERVICES` row. `game/npc_brain.gd` needed **no change** (its Flee and Scan states already read the row's `KEY_FLEE_TIER`/`KEY_SCAN_TIER`; the hunter's `everything` hostility plus the row's 900 u radius is the whole hunter behaviour).

---

## 2. The numbers, measured

### 2.1 The witness rule (13 §5/§7)

`test_s6_heat.gd` measures, on a live `game.tscn`:

| case | kill point | heat filed |
|---|---|---:|
| no witness at all (dead space, 6 788 u from the station) | `(4800, −4800)` | **0** (profile byte-identical, no heat key) |
| a neutral hull 200 u away | dead space | **20** = trader 15 + 5 |
| a patrol hull 300 u away | dead space | **30** = patrol 25 + 5 |
| a witness whose own LOS says "blocked" | dead space | **0** |
| a witness at `WITNESS_RANGE + 100` | dead space | **0** |
| the station 100 u away | station + 100 | **20** |
| a **real convoy hull** killed at its own position | dead space | **0** (the victim is excluded — §3.2) |
| a pirate, no witness | dead space | **−3** (10 → 7) |

`WITNESS_RANGE == ShipFit.BASE_SCAN_RANGE == 900.0`, asserted against its owner rather than restated. Clamp, measured: 95 + 30 → **100**; 2 − 3 → **0**.

### 2.2 Decay (13 §7)

40 heat → 59.9 s of play leaves it at 40, +0.2 s lands **39**; a second faction's 5 cools with it (same tick, "anywhere"); +3 min → 36 / 1; +10 min → 26; a long bank floors both at **0**, and a fully cooled record then writes nothing at all (byte-identical).

### 2.3 The fine and `pay_bounty` (13 §2, 17 §5)

| case | measured |
|---|---|
| 40 heat | `bounty_fine` = **1 000 CR** (13 §2's own worked row), 25 CR per point |
| 5 000 CR, 40 heat | `true`; balance **4 000**; `heat` `{concord: 0, meridian: 12}`; exactly **one** `BOUNTY` line carrying `−1000` |
| 0 heat | `false`, profile byte-identical, no line |
| 999 CR against a 1 000 fine | `false`, profile byte-identical, no line, no partial charge, no partial clear |

The refusal snapshot deep-compares `{credits, cargo_items, heat, standing, ammo_of(laser), vitals_of(active_ship), docked_faction}`.

### 2.4 The two refusal axes (13 §3 vs 12 §4.1)

| heat (concord) | standing (concord) | gate prompt | `_dock_refused()` |
|---|---|---|---|
| 95 (Outlaw) | 0 | `GATE REFUSED — OUTLAW` | false |
| 0 (Clean) | −51 | `JUMP TO … — <fee> CR` | true |

The dock refusal is checked **before** `_file_damage_report`, so a refused dock files no vitals and no `docked_faction`; an allowed dock files both and emits `route_requested(&"loading", …)` once. Both readings come from their own doc (the gate reads `NpcRegistry.heat_tier`, the dock reads `PlayerProfile.standing_of`).

### 2.5 Hunters (13 §3/§7)

- Row: `KEY_SEAM == SEAM_NONE`, `KEY_SPAWN == SPAWN_SECTOR`, `KEY_TIER == 1`, `KEY_AGGRO_RADIUS == KEY_SCAN_RADIUS == 900.0`, and `NpcRegistry.density(&"hunter", <every sector>) == (0, 0)` — so `spawns_for` never rolls a hunter with the ordinary band (the pre-existing `test_engine2_npc.gd` seam row holds unmodified).
- Hull map, asserted for all ten player hulls: `ship_fighter`/`ship_interceptor`/`ship_patrol`/`ship_miner`/`ship_vanguard`/`ship_trader`/`ship_corvette` → `ship_fighter`; `ship_gunship`/`ship_destroyer`/`ship_freighter` → `ship_gunship` (13 §7's three-band proposal).
- Wing size over **40 sector entries**: `{2: 19, 3: 21}` — 13 §3's 2–3, uniform.
- Every hull of a Wanted wing: `archetype() == hunter`, `blip_kind() == hostile`, `faction() == <space owner>`, and within `HUNTER_SPAWN_RADIUS` (600 u) of the player.
- One wing per sector entry: a second tick 5 s later adds nothing.
- Outlaw: a dead wing is still dead at 59 s and is back at 61 s (2+ hulls); a **Wanted** wing does not perma-tail (four respawn windows later: still 0).
- Per-faction isolation: Concord's 55 heat in Meridian space spawns nothing; Meridian's own 55 does, and the wing wears Meridian's flag; sector 7 (unaligned) spawns nothing at any tier.
- Hunter extra (06 §8): over 60 kills each, `comp_elec_1` stacks **larger than the band table's own line can pay** appear **10/60** for a hunter and **0/60** for a pirate. The tell is read off the tables (06 §3.1's fighter line pays 1..1, 06 §8's extra pays 1..2), so a doc change turns the test red rather than silently weakening it.

### 2.6 The bounty surface (13 §7, 14 §7)

On the shipped `launch_panel.tscn`, mounted the way the station shell mounts it: no docked faction → hidden; docked faction with heat 0 → hidden; docked faction with 40 heat → **visible**, text `PAY BOUNTY (1000 CR)` (the catalogue's own `name` plus the profile's own `bounty_fine`). A press with 5 000 CR charges 1 000, zeroes the heat, collapses the row and reports `BOUNTY PAID · 1000 CR`; a press with 999 CR leaves the profile byte-identical, writes no log line, reports `REFUSED · NOT ENOUGH CREDITS` and keeps the row up. Another faction's heat never changes this station's fine.

### 2.7 The tier reaching the brain (end to end)

A witnessed trader kill at the station files **20** heat (Suspect), and the sector's own hulls act on it in the same frame: the convoy's brain enters **flee** and the patrol's enters **scan** (both read through `NpcShip._steer_frame`, so the heat tier is read from the live profile, not handed in).

---

## 3. Deviations, decisions and things the planner should know

### 3.1 Bucket 1 — only a **crime** needs a witness; the pirate reduction does not

13 §2's table calls the +5 "Witness survives (**any crime**)" and lists the pirate kill under **Reduction** ("Kill a pirate in that faction's space: −3 per kill"), and 13 §5's rule is about heat being *earned* ("Solo kills in dead space are free"). The build therefore gates **positive** heat on a witness and adds `WITNESS_EXTRA` to it, while a negative `heat_on_kill` lands unconditionally and is never surcharged. The alternative reading (a witness needed for the −3 too) would make pirate hunting in dead space worthless, which contradicts 13 §4's "honest income" loop. **Reversal:** one `if` in `_on_npc_died`.

### 3.2 Bucket 1 — the victim is excluded from its own witness scan (a defect caught by measurement)

`NpcShip._die` raises `died` **before** `despawn()` (deliberately: "so every listener runs on a live node"), so at the moment `_on_npc_died` runs the victim is still in the `npc_ship` group, still at the kill point, and — for a trader or a patrol — still one of 13 §5's witness classes. Without an exclusion, **every** neutral or patrol kill would be witnessed by its own corpse and 13 §5 would never fire. `_witnessed(at, victim)` skips the victim by identity; `_on_npc_died` passes the hull it was handed. Measured with the sector's own convoy hull moved to dead space (§2.1): heat 0. A stub victim could not show this, which is why the suite carries a real-hull case.

### 3.3 Bucket 1 — the convoy's heat tier read the wrong key (a pre-existing defect 13 §5 depends on)

`NpcShip._read_heat_tier` read the player's heat under `_space_owner`, which for a **factionless** row is `NpcRegistry.resolve_faction`'s own answer — the literal `&"none"` for a convoy hull, and `&"unaligned"` in nobody's space. Neither is a heat key, so every factionless hull read tier **Clean** and 13 §5's trader panic ("neutral traders in the sector gain `flee` behaviour while your Suspect+ tier is active") could never fire, however high the player's heat. The cure is one predicate (`_has_local_faction`): a hull whose space owner is not one of the three powers reads the **worst** of the player's heats, which is 13 §5's own sector-wide reading. No other row changes behaviour (a pirate's and a swarmer's flee floor is hull-based and their hostility is `everything`; a patrol's and a hunter's space owner is a real faction). **No existing test moved** — measured: the suite's end-to-end case now passes, and the full gate reads 674/0. **Reversal:** delete `_has_local_faction` and restore the `!= &""` test.

### 3.4 Bucket 1 — a hidden Control is how the row is "not shown"

14 §7 says the strip appears "at any faction station with heat > 0". The row is built once in the same `ServiceRow` as REFUEL/RECHARGE and toggled with `visible` (a hidden Control takes no space in a container), so the panel's node count never changes and the pre-existing `test_p2b_services.gd` row assertions (`recharge.get_parent() == refuel.get_parent()`, LAUNCH stays last) hold unmodified. **Reversal:** free the button instead of hiding it (which would move those assertions).

### 3.5 Bucket 1 — `PlayerProfile.docked_faction`, a transient field, is how the pane learns whose fine it shows

Nothing in the tree carried "the station you are docked at" into the station screen: the dock route sends `{destination: station}` with no sector, and neither `ui/screens/station.gd` (D6's neighbour, and outside this worker's set) nor the panel can reach `game.gd`'s `_sector_owner()`. The docking route now files the sector owner's id on the profile (`game.gd:_file_docked_faction`), and the panel reads it. It is **not a save key** (a station is only ever reached from flight; `_apply_defaults` clears it) so no save version moves and no round-trip test is owed. **Reversal:** carry the faction in the `loading` route params and forward it from the station shell (a two-file change outside this worker's set).

### 3.6 Bucket 1 — the wing is homed on the player (the "tail" is real)

`sector.gd:_add_npc` anchors an `everything`-hostility hull on an asteroid field, which for a hunter wing means a wing that spawns in the sector and then patrols a rock 3 000 u away — a wing that never hunts. `_spawn_hunter_wave` therefore re-homes each hull: `HUNTER_SPAWN_RADIUS` (**600.0**, proposed, no doc source; reversal: the sector's own field anchor) on an even bearing, both the node and the body it takes its transform from, plus `NpcShip.set_home` so the brain's 2 500 u leash is measured from where the wing appeared. **Reversal:** drop `_home_last_hunter` and let the sector place the wing.

### 3.7 Staged — the station turret (13 §7 tick 7)

Measured, not taken on K0's word: the station is a bare `Sprite2D` in the `station` group (`game/sector.gd:_spawn_station`) with a sibling `DockZone` `Area2D` and **no collision body and no damage sink** anywhere in the file, and the turret archetype's `KEY_SPAWN` is `SPAWN_STATION` with no consumer. So "attacking a station" has no path to land the +25 on, and turret aggro has no entity. Nothing was invented for it: the value that path would use is already the turret row's own `KEY_HEAT_ON_KILL` 25, read through the same `heat_on_kill()` the kill seam reads. **Owner tick 7** (schedule the entity); reversal: a station-attached NPC with a damage sink in `sector.gd` (outside this worker's set).

### 3.8 Copy choices, reported not invented

| line | value | source | reversal |
|---|---|---|---|
| dock refusal readout | `DOCK REFUSED — OUTLAW` | 11 §5 pins the gate's line (`GATE REFUSED — OUTLAW`) and no dock copy exists; this mirrors it | delete the constant and its ladder rung (the refusal still works, silently) |
| bounty label | `PAY BOUNTY (1000 CR)` | 14 §7's own words plus the profile's own fine (the brief's `PAY BOUNTY (n CR)`) | one format string |
| bounty success | `BOUNTY PAID · 1000 CR` | the pane's `SERVICE_REPORT` pattern; 14 §7 pins no wording ("Paying is a single confirm") | one constant |
| bounty refusal | `REFUSED · NOT ENOUGH CREDITS` | the shell's own refusal vocabulary (STATION_HUB §5.6) | one constant |
| bounty, nothing owed | `NO BOUNTY DUE` | unreachable from the row (it is hidden at heat 0); named because `pay_bounty` is callable directly | one constant |

### 3.9 Route notes (no pin moves)

- **The witness ray cannot be measured by the gate.** The headless runner calls every suite from its own `_ready`, before the engine's first physics step, so no body is in the 2D broadphase yet: a probe placed a 66 u-radius `Asteroid` across a 400 u ray and the ray hit **nothing**, and `PhysicsServer2D.space_flush_queries` does not exist in 4.7.2. The suite therefore measures the LOS half as "the **hull's own** verdict is the one the scene reads" (a witness whose `_line_of_sight` answers `false` blocks a crime that would otherwise score), plus the mask identity `NpcShip.HULL_MASK == Asteroid.COLLISION_LAYER`, which is 13 §7's "the brain's own rock-blocking check" by construction. The station half (no brain) uses the same rock-layer ray cast by `game.gd:_rock_line_clear`.
- **A live Outlaw wing keeps chasing when the tier cools** (a bounty cannot be paid at Outlaw — docking is refused — and decay can drop the heat below 80 while the wing is alive). 13 §3's tail is already launched, so it is left alive; reversal: a `despawn()` sweep when the tier leaves Outlaw.
- **The wing size rolls on the global RNG** (`randi_range`), like the sector's own band rolls; nothing is seeded per scene.
- **`_heat_play_time` is scene-scoped**, so a sector transition restarts the minute in progress (up to 60 s of play time is lost per crossing). The pin asks for "a float play-time accumulator on the game scene's own tick", and `Router.route` rebuilds the scene, so this is the pinned shape; reversal: a `static` accumulator beside `_transit_destination`.
- **A floored faction keeps a 0 in the record** (`_apply_heat` and `_decay_heat` write the clamped value; `pay_bounty` sets the key to 0 rather than erasing it, so a record has one spelling of "clean"). Every reader answers 0 for it (`heat_of`, `NpcShip._read_heat_tier`, `_player_heat_tier`). Reversal: erase the key wherever the value reaches 0.
- **`_apply_heat` writes nothing when the clamped value is unchanged**, so a pirate killed at a zero heat leaves no zero-heat key behind (the pre-wave code would have written `−3` into the record).
- **A hunter's row hostility is still `everything`** (the shipped seam), so a wing will also engage a patrol or a convoy that crosses it. 13 §3 gives hunters no hostility column; reversal: a same-faction-ignoring rule, which is slice-4 tuning.
- **`SLICE.md`'s worker table still lists `game/heat.gd` in K3's set**; §19's disposition drops it (no pin, no interface) and the brief's table is authoritative. Docs are not this worker's to edit — flagged for R1/the developer.

---

## 4. Files touched

| file | change |
|---|---|
| `vajb-orbit/autoload/player_profile.gd` | +73: `EVENT_BOUNTY`, `BOUNTY_CR_PER_HEAT`, `HEAT_MIN`/`HEAT_MAX`, the transient `_docked_faction` (+ cleared in `_apply_defaults`), `heat_of`/`standing_of`/`bounty_fine`/`pay_bounty`/`docked_faction`/`set_docked_faction` |
| `vajb-orbit/game/game.gd` | the witness rule (`WITNESS_RANGE`, `WITNESS_EXTRA`, `HEAT_MAX`), `_witnessed`/`_is_witness_hull`/`_witness_visible`/`_station_witnesses`/`_rock_line_clear`, `_decay_heat` + `_heat_play_time`, `_apply_heat`'s clamp + no-op guard, the kill seam's witness gate, `_dock_refused`/`DOCK_REFUSED_PROMPT`/`STANDING_OUTLAW` + `_file_docked_faction`, the hunter wing (`_update_hunters`/`_spawn_hunter_wave`/`_home_last_hunter`/`_live_hunters` + their constants), the `ShipFitScript` preload, `HUNTER_ARCHETYPE` now read off `NpcRegistry.ARCHETYPE_HUNTER` (one home for the id), and the two new `_physics_process` calls |
| `vajb-orbit/game/npc_registry.gd` | +109/−?: `ARCHETYPE_HUNTER`, `HUNTER_HULL_DEFAULT`, `KEY_PLAYER_HULLS`, the hunter row's flip (seam/spawn/radii/hull-map members) and `hunter_members`/`hunter_wing_size`/`hunter_hull_for`/`hunter_spawn` |
| `vajb-orbit/game/npc_ship.gd` | +34/−?: `set_home`, and `_read_heat_tier`'s factionless cure (`_has_local_faction`) |
| `vajb-orbit/game/station_catalog.gd` | +14: `SERVICE_BOUNTY` and its `SERVICES` row (14 §1/§7) |
| `vajb-orbit/ui/station/launch_panel.gd` | +96/−?: the bounty row (`SERVICE_BOUNTY`, the four copy constants, `_bounty_button`, `bounty_button()`, `_refresh_bounty_row`, `_bounty_faction`, `_run_bounty`, the `refresh_profile(&"credits")` rung, the `_on_service_pressed` branch) |
| `vajb-orbit/tests/test_s6_heat.gd` | **new** (42,775 B, 23 tests) |

Not touched: `ui/hud/**`, `assets/**`, `project.godot`, `addons/**`, `ui/theme/vajb_theme.tres`, `docs/**`, `game/heat.gd` (not created), `game/sector.gd`, `game/sector_registry.gd`, `game/loot_tables.gd`, `game/poi.gd`. No probe file ships (the two scratch probes used for §2.5 and §3.9 were deleted).

## 5. Owner ticks owed (from the brief, this worker's share)

1. **Bounty surface** (tick 5) — shipped as the LAUNCH row beside REFUEL/RECHARGE; reversal: the REPAIRS column. The row's copy choices are §3.8.
2. **Hunter hull map** (tick 6) — the three-band proposal as built, in `KEY_MEMBERS`; reversal: all-fighter. **And the aggro/scan radius 900.0** (proposed; reversal 1200.0).
3. **Station turret** (tick 7) — staged, measured (§3.7).
4. **Hunter extra loot table** (tick 8) — reachable and measured (§2.5); reversal: none.
5. **New, reported not invented:** the wing's spawn radius `HUNTER_SPAWN_RADIUS` **600.0** u (§3.6; reversal: the sector's own field anchor) and the dock refusal's readout copy (§3.8; reversal: delete the rung).
6. **New, reported:** the transient `PlayerProfile.docked_faction` (§3.5) and the `NpcShip._read_heat_tier` cure (§3.3) — neither moves a pin, a test or a save key.
