# S6-K2_report — POIs + loot (derelicts, anomalies, beacons, the kill roll and the wreck site)

**Worker:** S6-K2 (`VAJB_WORKER_FILES="vajb-orbit/game/poi.gd,vajb-orbit/game/loot_tables.gd,vajb-orbit/game/sector.gd,vajb-orbit/game/game.gd,vajb-orbit/tests/"`)
**Wave:** S6 Travel (engine slice 3 + RPG P3). Brief `.agents/gen/slices/S6-travel/S6_BRIEF.md`; pin `docs/CONTRACTS.md` §19; docs `docs/gameplay/11_galactic_map.md` §3/§5, `06_loot_drops.md` §2–§6/§8, `15_module_affixes.md` §2/§5, `17_coder_handoff.md` §4/§5.
**Date:** 2026-09-24. **Tree:** working tree with the parallel D6 lane in flight (`ui/hud/**`, `docs/design/**`, `tests/test_d6_*.gd` are D6's churn, not touched here) and K1's travel core landed underneath (its uncommitted `game.gd`/`sector.gd`/`sector_registry.gd` edits are the base this worker appended to).

**Gate (measured, full suite, headless, scratch store):** `[SUMMARY] passed=651 failed=0`, twice on two scratch stores.
Delta from this worker: **+25 tests** (`tests/test_s6_poi_loot.gd`) and **the one existing wiring row K1's dispositions named, corrected again** (`tests/test_engine2_wiring.gd`, §5.1 — same assertion count, derived expectation). Baseline before this worker: `626/0`. **No existing test count moved.**

Two `ERROR:` lines appear in every run and are **pre-existing, not this worker's**: `Parameter "data.tree" is null` (`game/weapons.gd:2050`, reached from `test_combat_repair_c5.gd`) and `Cannot call method 'call' on a previously freed instance` (`test_weapon_fx_f4.gd:178`). Both fire in the baseline run with this worker's files reverted.

---

## 1. What shipped, against the pin

| §19 item | Where | State |
|---|---|---|
| `game/poi.gd` (`class_name Poi extends Node2D`, `setup`/`scan`/`trigger`) | new file, 26,889 B | done |
| derelict: 5 s interruptible channel; 0.40 cache / 0.35 data core / 0.25 module; one-shot per cycle | `poi.gd:288-327` (`scan`/`advance_scan`), `:523-556` (`_complete_scan`), `:199-207` (`roll_derelict`) | done |
| `scan() -> int` 0 / -1 (range or scanner) / -2 (interrupted) | `poi.gd:288-309` (`SCAN_OK`/`SCAN_REFUSED`/`SCAN_INTERRUPTED`) | done |
| data core = 03 `comp_elec` + `DATA_CORE_CREDITS` 120 CR | `poi.gd:87-88`, `:535-550` | done |
| anomalies at 200 u: ore_bloom (T+1, 10 rocks, 2×) / grave_cache (3–5, one grade up) / void_rift (`RIFT_DRAIN` 12/s + T4 exotic, 0.10 magic+) | `poi.gd:379-392` (`trigger`), `:580-618` (spawns), `:398-403` (`update_presence`) | done |
| the Hollows rolls rift at 2× weight | `poi.gd:213-256` + `sector_registry.ANOMALY_WEIGHTS_RIFT_DOUBLED` (K1's home, read not copied) | done |
| beacons reveal the sector's unscanned POIs | `poi.gd:289-293`, `sector.gd:335` (`reveal_pois`) | done |
| `game/loot_tables.gd` extended additively: `HUNTER_EXTRA`, `WRECK_PICKUP_LIFETIME`, `roll_band`, `roll_hunter_extra` | `loot_tables.gd:44` + `:117-126` (constants), `:176-230` (API) | done |
| `TABLES` + `roll(kind, tier, seed)` byte-identical | untouched; `test_s6_poi_loot.gd` proves `roll_band` is a delegate | done |
| `sector.gd:blips()` gains beacon/derelict/anomaly entries; soft fog | `sector.gd:276-293` (`blips`), `:300-350` (`pois_of_kind`…`add_wreck_site`), `:593-631` (`_spawn_pois`) | done |
| kill path = `game.gd:_on_npc_died`; wreck site 90 s, blip rides `&"neutral"` | `game.gd:1941-1985` (`_on_npc_died` + `_spawn_kill_loot`) | done |
| `WorldClock` the only respawn clock | `sector.gd:_respawn_cycle` re-arms the POIs; `poi.gd` owns no Timer | done |
| no `ui/hud/**` writes; scan readout + cache feed ride `set_prompt` | `game.gd:100-113` (constants), `:650-670` (prompt ladder), `:873-880` (feed) | done |
| no `assets/**`, `project.godot`, theme, `docs/**` write | — | honoured |

**No frozen method was renamed, retyped or removed.** `loot_tables.gd`'s `TABLES`, `roll`, `has`, `cap_violations`, `uncatalogued_items` and the five table constants are byte-identical (additive only). `sector.gd`'s and `game.gd`'s public surfaces are extended, never reshaped.

---

## 2. The numbers, measured

All samples: 10 000 seeded rolls, seed base `20260924` (the suite's `SAMPLE_SEED`), the same arithmetic `test_s6_poi_loot.gd` asserts.

### 2.1 The derelict roll (11 §3.1), 10 000 rolls

| reward | measured | doc |
|---|---:|---:|
| cache | 0.3991 | 0.40 |
| data core | 0.3488 | 0.35 |
| module | 0.2521 | 0.25 |

All inside the brief's 2 pp.

### 2.2 The anomaly kinds (11 §3.2/§5), 10 000 rolls each

| sector | ore_bloom | grave_cache | void_rift |
|---|---:|---:|---:|
| `sector_1` | 0.3321 | 0.3305 | 0.3374 |
| `sector_6` (The Hollows) | 0.2486 | 0.2519 | **0.4995** |

The rift's exotic module rate: **0.0998** (11 §3.2's 0.10).
Rift drain: `update_presence(1.0, inside) == 12.0` (`Registry.RIFT_DRAIN`), `0.5 → 6.0`, outside the 200 u radius `0.0`, and on a live `game.tscn` one 1 s tick drops the ship's shield by exactly 12.0.

### 2.3 The hunter extra (06 §8), 10 000 rolls at band 3

| item | measured | doc |
|---|---:|---:|
| `comp_elec_1` | 0.4978 | 0.50 |
| `comp_elec_2` | 0.2501 | 0.25 |
| `comp_elec_3` | 0.0984 | 0.10 |

Grade cap: **0** rows above `comp_elec_1` in 200 band-1 rolls; `hunter_extra_violations(3) == []`, `(1)` non-empty.

### 2.4 The kill hauls (`roll_band`, 06 §6 check 1), 10 000 kills each

| kind | units/kill measured | credits/kill measured | empty |
|---|---:|---:|---:|
| fighter | 2.1428 | 28.3464 | 0.1210 |
| swarmer | 2.1428 | 28.3464 | 0.1210 |
| freighter | 2.3014 | 44.7427 | 0.1560 |
| corvette | 1.4860 | 77.9180 | 0.1943 |
| maw | 6.3414 | 1581.2110 | 0.0000 |

The suite's expectation is computed from 06 §3's own chance/min/max columns and the 03 catalogue a second time in the test file (never read off the shipped tables); every row holds inside 06 §6's ±5 %. Worked check for the widest one: corvette expected `0.50×1.5×30 + 0.30×55 + 0.25×45 + 0.20×50 + 0.0986×184.82 = 78.75` vs measured 77.918 (−1.06 %).

### 2.5 POIs per sector (one populated sector each, `populate(row, 20260924)`)

| sector | derelicts | anomalies | beacons | gates | fogged neutral blips |
|---|---:|---:|---:|---:|---:|
| `sector_1` | 2 | 1 | 2 | 1 | 2 |
| `sector_3` | 2 | 1 | 4 | 2 | 3 |
| `sector_6` | 2 | 1 | 4 | 2 | 3 |
| `sector_7` | 2 | 1 | 2 | 1 | 0 |

Beacons = corridors + gates (11 §3), derelicts = wreck fields × 1, anomalies = the 1–2 roll. "Fogged neutral blips" is the neutral count minus the asteroid fields, i.e. the convoys plus any revealed POI — 0 revealed at populate, as 11 §5 requires.

### 2.6 The wreck site (06 §4)

- The payload is aboard from `setup`; `advance_lifetime(89.9)` leaves it whole and `+0.2` frees it, with `is_expired()` true. The site keeps its pickups alive while it lives (their own `Pickup.LIFETIME` is 60 s, §5.5).
- The live kill seam: `_on_npc_died(kill_point, archetype, victim)` leaves exactly one wreck site at the kill point, revealed, `blip_kind() == &"neutral"`, in `blips()`, every pickup inside its fighter line's `randi_range`.
- A credit cache the site spawned reports its collection (77 CR) and the site's own 90 s release reports nothing.

### 2.7 Refusals and one-shots

`scan` on an out-of-range player → `-1`; a scannerless player → `-1`; leaving range mid-channel → `-2` and the channel cancels; `interrupt()` → `-2` on the next step; a spent derelict → `-1` until `respawn()` re-arms it and returns the fog. `respawn` is called by `sector._respawn_cycle` only (17 §4's one clock).

---

## 3. Deviations, decisions and things the planner should know

### 3.1 Bucket 2 — one existing row moved, exactly as K1's dispositions predicted

`tests/test_engine2_wiring.gd:test_the_minimap_feed_carries_every_hull_plus_the_pois` pinned `hulls + fields + gates + 1` after K1's correction. K2 adds the beacons (11 §3's "1 per corridor + 1 per gate"), which 11 §5 maps to `friendly` and always shows, so the expectation is now `hulls + fields + gates + beacons + 1` and `friendly == gates + beacons + 1`, both **derived from the sector's own `gates()`/`beacons()` counts**, never hard-coded. The derelict and anomaly blips are fogged at populate, so they do not enter that row. Same assertion count, one existing row's expectation moved — ratify it with the rest of §19's set.

### 3.2 Bucket 1 route — the soft-fog reading: beacons always show

11 §5's prose says "a POI's blip appears once scanned or beacon-revealed; gates and stations always appear", and a beacon is a `Poi` — read literally, a beacon's own blip would be fogged until something reveals it, which cannot be a beacon. The build takes the reading 11 §3.3's blip mapping and 11 §2.2's "marked by nav buoys" support: **a beacon is a nav aid and always shows** (`Poi._revealed` is true from `setup` for beacons and wreck sites); derelicts and anomalies are fogged until scanned or beacon-revealed. This is also what makes the wiring row above move, as the brief's K1 dispositions anticipated. **Reversal:** start beacons fogged too (one line in `Poi.setup`), which drops them from the feed and returns that row to K1's form.

### 3.3 Bucket 1 route — the scan loop

- The derelict channel **starts on proximity** (the scene's scan tick calls `scan` on the nearest unspent derelict in `DERELICT_SCAN_RANGE`); there is no "press to scan" prompt in the pin, and the readout is the pin's own `SCANNING nn %` at 4 Hz. **Reversal:** gate the start behind `interact`.
- The **scanner** is read off `PlayerProfile.resolved_fit` (any computers module with `scanner_add > 0`: the Deep Scanner and the Nexus, 09 §3.4) because `PlayerShip` publishes no fit accessor and 11 §3.1 asks for "any C-slot scanner". A duck-typed `has_scanner()` on the player wins first, which is how the pure tests answer. The shipped Vanguard standard fit carries no computer, so a fresh account cannot scan a derelict until it fits one — 11 §3.1's own intent ("what makes `c_scanner` worth a slot"). **Reversal:** move the reader onto a `PlayerShip` accessor once one exists.
- A **beacon** reveals at once and needs no scanner (a nav aid, not 11 §3.1's C-slot requirement) and asks its parent once (`_reveal_asked`), so the per-frame tick is not a per-frame reveal.
- A hull hit breaks the channel through `game.gd:_on_ship_damage_taken` → `Poi.interrupt()` (the ship's own `damage_taken`, the same signal the warp channel uses).

### 3.4 Bucket 1 route — `Poi` gained a fourth kind, `wreck`

06 §4's wreck site is the same object shape (a position, a payload, a clock) and `game/poi.gd` is the only new file in this worker's set, so it lives there as `Poi.KIND_WRECK` rather than in a fifth file. **Reversal:** move it to its own `game/wreck_site.gd` (one preload in `game.gd` + one in `sector.gd`).

### 3.5 Bucket 1 route — the wreck site holds its pickups past `Pickup.LIFETIME`

`Pickup.LIFETIME` is 60 s and `game/pickup.gd` is **not** in this worker's set, so a 90 s window cannot ride the pickup's own clock. The site therefore holds its pickups' `_age` at zero each tick while it lives and frees them at 90 s (`Poi._hold_pickups`), which is 06 §4's own sentence ("holding its uncollected pickups for 90 s … the window is the only persistence"). **Reversal:** a `lifetime` argument on `Pickup.setup` (the clean fix, already reported by an earlier wave for the death drop's 300 s window).

### 3.6 Bucket 1 route — reward content the docs leave open

| value | choice | source | reversal |
|---|---|---|---|
| data-core item | `comp_elec_1` | 11 §3.1 says "03 `comp_elec`", a family, no grade | the sector band's grade |
| cache item/stack | `comp_scrap_1` ×1–3 | 11 §3.1 says "a small ore/component cache", no id | roll the sector tier's ore instead |
| module base id | uniform over `ModuleCatalog.MODULES` minus the three exclusives | 15 §2/§5: exclusives spawn at faction stations | a fixed base, or include the exclusives |
| sector band | `ceil(n / 2)` clamped 1..4 (1–2→T1, 3–4→T2, 5–6→T3, 7→T4) | 11 §1's tier bands, the same bands 11 §1.1's mixes use | any other band table |
| ore-bloom radius / jitter | 320 u, 0.25 | no doc gives the cluster's spread | one edit |

Both module rewards (the derelict's and the rift's) roll at `ModuleCatalog.SOURCE_DERELICT`, whose 15 §2 row is 75 magic / 25 rare and never Common — the "magic-rarity module" the docs promise is that table's own floor.

### 3.7 Bucket 1 route — the rift's drain goes through the ship's damage sink

`Poi.update_presence(delta, player)` returns `RIFT_DRAIN × delta` and `game.gd` applies it with `PlayerShip.take_damage(amount)`, the pinned shield-first sink. So a shieldless hull takes the drain on the hull, which is the only reading the shipped sink offers. **Reversal:** a shield-only write once `PlayerState` exposes one.

### 3.8 Bucket 1 route — the kill seam's inputs

`_on_npc_died` reads the victim's 06 kind off its own registry row (`NpcRegistry.KEY_LOOT_KIND`) and the hunter's extra off the archetype id (`game.gd:HUNTER_ARCHETYPE`, 13 §3's row; K3 owns flipping it off `SEAM_SLICE_4`). A hull whose row names no table (the boss, the parked `sibelon`) leaves no site. An empty band roll still leaves a site (06 §2.3: "empty kills happen") — the site is the kill's marker, and 06 §4 gives no exception.

### 3.9 Bucket 1 route — the cache feed

Both feed sources land on the frozen `set_prompt` seam: the derelict's data core reports the credits it paid (`Poi.scanned(reward, credits)`), and a credit-cache pickup a wreck site spawned reports its collection (`Poi.cache_collected(amount)`, wired to the pickup's `tree_exited` and silenced while `_expired`, so the site's own 90 s release is not a collection). The line is 06 §5's `+%d CR SALVAGE`, 2 s. A pickup collected outside a wreck site (the death drop) has no feed because `game/pickup.gd` is out of this worker's set — **reported, not guessed**.

### 3.10 Bucket 1 route — anomaly lifetimes

`trigger` is proximity-auto-fired and one-shot per cycle; `ore_bloom`/`grave_cache` leave their content in the world and stay consumed until `sector._respawn_cycle` re-arms them (11 §3.2's "despawns (respawns on the sector clock)"). The `void_rift` stays armed after its trigger because 11 §3.2 gives it a persistent hazard ("drains shields slowly **inside**") and a pickup at its heart; it re-rolls on the same clock. **Reversal:** free the rift node on trigger.

### 3.11 Bucket 2 flag — 06 §4's "distinct blip" has no kind in the frozen §7 set

Already K0's F12 and §19's disposition: the wreck site rides the existing `&"neutral"` kind. No new blip kind was minted and no `ui/hud/**` file was touched.

---

## 4. Files touched

| file | change (insertions/deletions) |
|---|---|
| `vajb-orbit/game/poi.gd` | **new** (26,120 B) — the four POI kinds, the pure rolls, the channel, the grants, the wreck site |
| `vajb-orbit/game/loot_tables.gd` | +77/−0: `WRECK_PICKUP_LIFETIME`, `HUNTER_EXTRA`, `roll_band`, `roll_hunter_extra`, `hunter_extra_violations` |
| `vajb-orbit/game/sector.gd` | +263/−0 of this worker's (K1's travel core is the base): `PoiScript`, `poi_spawned`, `_spawn_pois`/`_add_poi`/`_poi_position`, `pois`/`pois_of_kind`/`derelicts`/`anomalies`/`beacons`/`wrecks`, `reveal_pois`, `add_wreck_site`, the fogged `blips()` entries, the POI re-arm in `_respawn_cycle` |
| `vajb-orbit/game/game.gd` | +~200/−0 of this worker's: `PoiScript`/`LootTablesScript` preloads, the scan/feed constants, `HUNTER_ARCHETYPE`, `_update_pois`/`_update_scan`/`_nearest_scannable`, `_on_poi_spawned`/`_on_poi_scanned`/`_on_poi_cache_collected`, `_push_cache_feed`/`_tick_prompt_timers`/`_scan_prompt_text`, the prompt ladder's two new rungs, the kill loot in `_on_npc_died`, the scan interrupt in `_on_ship_damage_taken` |
| `vajb-orbit/tests/test_s6_poi_loot.gd` | **new** (25 tests) |
| `vajb-orbit/tests/test_engine2_wiring.gd` | +11/−3: the minimap feed's derived expectation (§3.1) |

Not touched: `ui/hud/**`, `ui/station/**`, `assets/**`, `project.godot`, `addons/**`, `ui/theme/vajb_theme.tres`, `docs/gameplay/18_engine_spec.md`, `docs/gameplay/08_ship_slots_modules.md`, any `docs/` file, `game/pickup.gd`. The scratch probe used for §2's tables was deleted (no probe file ships).

## 5. Owner ticks owed (from the brief, this worker's share)

1. **Derelict scan range** 300 u (K1's home; this worker reads it) — reversal the fit's `scan_range`.
2. **Rift drain** 12/s — reversal 6.
3. **Data-core credits** 120 — reversal 60.
4. **Hunter extra loot table** — the `comp_elec` proposal as built (06 §8); reversal none.
5. **Soft-fog reading** — beacons always show, derelicts/anomalies fogged (§3.2); reversal one line.
6. **Wreck site** rides `&"neutral"` and holds its pickups past `Pickup.LIFETIME` (§3.4/§3.5); reversal: a `lifetime` argument on `Pickup.setup`.
7. **`test_engine2_wiring.gd`'s minimap feed row moved again** (§3.1) — ratify the derived expectation.
