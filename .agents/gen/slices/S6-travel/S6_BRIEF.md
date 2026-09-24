# S6_BRIEF — Travel (engine slice 3 + RPG P3)

Wave `S6`, slice `S6-travel`. Read in this order before working:
1. `AGENTS.md` (rules; the escalation ladder in the format rules; the folder law)
2. `docs/CONTRACTS.md` **§19** (this wave's pin), then §6/§7 (the base it adds to)
3. `docs/gameplay/11_galactic_map.md` **§2/§3 + §5** (gates, corridors, POIs)
4. `docs/gameplay/13_heat_bounty.md` **§2–§5 + §7** (heat, hunters, enforcement)
5. `docs/gameplay/06_loot_drops.md` **§2–§5 + §8` (tables, roll, wrecks)
6. `docs/gameplay/17_coder_handoff.md` §2/§4/§5 (one owner per file; one-timer;
   transaction law) and `18_engine_spec.md` §14 slice 3 (read-only, owner-locked)
7. this brief end to end

## Owner request, verbatim

The queue row (dispatch_coder.md item 12, owner-approved grouping): "Engine
slice 3 (Travel) merged with RPG P3 — gates/corridors/POIs/scanner/sector
transitions + heat/hunters". 17 §1's P3 row: "sector registry, gates/corridors,
anomalies, derelicts, heat + hunters, loot tables". Engine §14 slice 3:
"Deliverable: gates, corridors, POIs, scanner, sector transitions via
`loading`. New files: `game/gate.gd`, `game/corridor.gd`, `game/poi.gd`
(derelict/anomaly/beacon), scanner reveal logic in `sector.gd`."

**Two contradictions resolved docs-first (already landed):** engine §14 tags
hunters to slice 4 — the owner's item-12 grouping (P3 = heat + hunters) wins;
bosses/arena stay slice 4. And 01 §5.2's travel ceiling (0–250) vs 11 §2.2's
"0–500 CR" — 0–500 wins, amended in 01 §5.2. Both are in CONTRACTS §10 v0.12.

**K0 dispositions (owner-ratified 2026-09-24) — binding before the builders run.**
The drift pass (`S6-K0_report.md`, 21 findings) is triaged; every cure is applied
in CONTRACTS §19's dispositions block, 13 §7 / 06 §8 / 17 §2, this brief and the
prompts:

1. **Fee row:** the multiplicative build gives **750** (`floor(250 × 1.5 × 2)`);
   `562` was the additive reversal's figure and is struck.
2. **Loot is additive:** the shipped `LootTables.roll(kind, tier, seed)` keeps its
   byte-identical shape (one entry per line, `amount = randi_range` — two
   `test_engine2_loot.gd` rows pin it). The band roll is **new**:
   `roll_band(kind, seed)` + `roll_hunter_extra(band, seed)`;
   `WRECK_PICKUP_LIFETIME := 90.0` lives on `LootTables`. **No existing test
   count moves.**
3. **Seams are real:** `game.gd:_on_npc_died` (kill; `projectile.gd:_shot_down` is
   the rocket intercept, not a hull kill), `game.gd:on_route` +
   `route_requested(&"loading", {destination, sector})` (transition),
   `sector.gd:populate` (POIs). The `_on_kill`/`_transition`/`_poi_table` names in
   the earlier draft exist nowhere.
4. **Transitions file first:** `Router.route` reloads the scene, so the transition
   path calls `_file_damage_report()` (and files ammo) before routing, else
   hull/shield/fuel silently reset to the last docked state.
5. **One prompt-line owner:** `_update_dock_prompt` writes the prompt line every
   frame; the gate/scan/cache readouts need a priority arbiter in `game.gd`
   (route, bucket 1) — a readout that "needs" a HUD widget is a report, not a write.
6. **Decay:** a game-side play-time accumulator (float seconds on `game.gd`'s tick,
   −1 per 60 s, floored at 0) — no Timer, `WorldClock` untouched.
7. **Clamp:** heat 0–100 on gain.
8. **Two refusal axes:** gate ← heat tier (13 §3); dock ← standing (12 §4.1).
9. **Hunter row flips** off `SEAM_SLICE_4`; `KEY_TIER` stays 1; the hull map goes in
   `KEY_MEMBERS`; aggro/scan radius **900.0** (proposed; reversal 1200.0).
10. **`game/heat.gd` is out** of K3's set (no pin, no interface); heat logic lives
    on `player_profile.gd` / `npc_registry.gd` / `game.gd`.
11. **The bounty surface ships** (owner call): `ui/station/launch_panel.gd` +
    `game/station_catalog.gd` join K3's set.
12. **Quadrants deferred to slice 4** (owner call; 18_engine_spec §4.5/§15's
    slice-3 tag is superseded for this wave) and **the `sibelon` is superseded** by
    11 §3.2's three kinds (owner call; the row stays parked).
13. **Wreck-site blip** = the existing `&"neutral"` kind; **the stale
    `SECTOR_NAME := "Helios Drift"`** (`game/game.gd:89`) is replaced by the
    registry row's name on spawn/transition; **data-core credits** =
    `DATA_CORE_CREDITS := 120` (proposed, the cache's own value; reversal 60).

## What is already measured (file:line)

- `game/sector_registry.gd:43-47,152-156` — the §6 pin already carries
  `WRECKS_MIN` 1 / `WRECKS_MAX` 3 / `DERELICTS_PER_WRECK_FIELD` 1 and the
  densities row; S6 adds `neighbours`/`gate_links`/`corridors` (§19).
- `game/npc_registry.gd:561` `heat_tier()`, `game/npc_ship.gd:832`
  `heat_on_kill()` (−3/+15/+25 per 13 §2), `autoload/player_profile.gd:1563-1567`
  `heat()`/`set_heat()` — the plumbing exists; S6 adds enforcement + hunters.
- `game/sector.gd:194` `dock_zone_contains`, `:216` `blips()`, `:25,76`
  `WorldClock` (the only respawn clock, 17 §4) — the seams the pin extends.
- `game/ship_fit.gd:40` `BASE_SCAN_RANGE := 900.0` — 13 §7's `WITNESS_RANGE`
  derives from it (measured, not proposed).
- `autoload/player_profile.gd:263` `add_credits` (06 §5's cache route).
- The kill seam is `game.gd:_on_npc_died` (`:1618-1631`, already files heat and
  standing) fed by `NpcShip.died` (`game/npc_ship.gd:374-384`);
  `game/projectile.gd:742 _shot_down` is the rocket intercept, not a hull kill
  (K0 1.2). The transition surface is `route_requested.emit(&"loading",
  {&"destination": &"game", &"sector": <id|name>})` — `loading.gd` forwards all
  params and `game.gd:on_route` (`:287-295`) reads them (K0 1.4).
- `game/game.gd:89`'s `SECTOR_NAME := "Helios Drift"` is a stale interim label
  (the registry's sector 1 is Halcyon Reach) and `_spawn_sector` never updates it —
  the transitions make it load-bearing (K0 F15).
- `game/loot_tables.gd` is **not** new: slice 2 shipped `TABLES` (five kinds incl.
  `&"swarmer"`) and `roll(kind, tier, seed)`, pinned by `test_engine2_loot.gd`
  (K0 F2/F3). The hunter row is parked on `SEAM_SLICE_4` with radius 0.0
  (`game/npc_registry.gd:349-380`) — this wave flips it (K0 F7).
- `tests/test_engine2_npc.gd:185-193` pins `heat_tier`'s four bands at the 13 §3
  thresholds; `:389,393` pin `heat_on_kill` at −3/+15. **All hold unmodified.**
- `tests/test_p1_profile.gd:109,144,194-210` pin the `heat` key round-trip. **Holds.**
- No station turret **entity** is spawned in the tree (the archetype row is
  `SPAWN_STATION` and no consumer reads it; `npc_registry.gd:315-348`) — 13 §7 tick 7.
  The +25 lands on attacking a station, but a station has no damage sink yet
  (`sector.gd:404-424`), so that half is staged too (K0 1.1).

## The pinned interface (CONTRACTS §19 is the source of truth; nothing here may drift)

```gdscript
# game/sector_registry.gd — additive beyond §6's pin:
#   SECTORS row gains: neighbours: Array[int], gate_links: Array[int] (1-2-3-4-5-6-7
#   spine, 11 §2.3), corridors: Array[Dictionary]  # [{dest, edge_rect}]
#   static GATE_FEE_BASE := 150, GATE_FEE_PER_SECTOR := 100 (11 §2.1)
#   static CORRIDOR_DEPTH := 600.0        # proposed, reversal 400.0 (11 §5)
#   static DERELICT_SCAN_RANGE := 300.0   # proposed, reversal scan_range (11 §5)
#   static RIFT_DRAIN := 12.0             # proposed, reversal 6.0 (11 §5)
#   static ANOMALY_WEIGHTS_RIFT_DOUBLED := [&"sector_6"]   # the Hollows (11 §3.2)

# game/gate.gd — new file (engine §14's name), class_name Gate extends Area2D:
#   setup(dest_sector: int) -> void
#   fee_for(heat_tier: StringName) -> int   # floor((150 + 100·d) × want × lawless);
#       want 1.5 at Wanted only, lawless 2.0 into sector 7, else 1.0 (11 §5)
#   jump(profile, heat_tier) -> int         # 0 ok / -1 refused (Outlaw) / -2 funds;
#       charges via PlayerProfile, 2 s charge-up, then the loading transition

# game/corridor.gd — new file, class_name Corridor extends Area2D:
#   setup(dest_sector: int, edge: Rect2) -> void
#   hold_progress() -> float                # 0..1 over 15 s presence (11 §2.2);
#       resets on zone exit, NOT on hull damage (11 §5 tick 2)

# game/poi.gd — new file, class_name Poi extends Node2D (derelict/anomaly/beacon):
#   setup(kind: StringName, row: Dictionary) -> void
#   scan(player) -> int                     # derelicts: 5 s interruptible channel
#       (11 §3.1); roll 0.40 cache / 0.35 data core (03 comp_elec + credits) /
#       0.25 magic module (15 §5); one-shot per respawn cycle
#   trigger(player) -> void                 # anomalies at 200 u (11 §3.2): ore_bloom
#       (T+1 cluster, 10 rocks, 2× yield) / grave_cache (3–5 pickups, one grade up)
#       / void_rift (RIFT_DRAIN shield/s inside; 1 exotic: T4 ore, or magic+ module
#       at 0.10); despawns, respawns on the sector clock (17 §4)

# game/loot_tables.gd — the slice-2 file, extended additively (17 §2's name):
#   static TABLES: Dictionary   # shipped (five kinds incl. swarmer) — restate nothing
#   static HUNTER_EXTRA: Array[Dictionary]   # 06 §8's comp_elec table (owner tick 8)
#   static WRECK_PICKUP_LIFETIME := 90.0     # 06 §4; the wreck site's own despawn
#   roll_band(kind: StringName, random_seed := 0) -> Array[Dictionary]   # NEW:
#       the kill's band roll — delegates to the shipped roll(kind, tier, seed),
#       whose shape stays byte-identical (one entry per line, amount = randi_range,
#       caches last and distinct: 06 §2.3 as shipped and test-pinned)
#   roll_hunter_extra(band: int, random_seed := 0) -> Array[Dictionary]  # NEW:
#       06 §8's HUNTER_EXTRA rows, grade-capped by band, rolled in addition

# game/sector.gd — additive beyond §6's pin (scanner reveal lives here, engine §14):
#   blips() gains gate/beacon/ders/anomalies entries per 11 §5's mapping; soft fog:
#   a POI blip appears once scanned or beacon-revealed; gates and stations always
#   appear. WorldClock remains the only respawn clock (17 §4).

# autoload/player_profile.gd — additive:
#   pay_bounty(faction_id: StringName) -> bool   # fine = heat × 25 CR (13 §2);
#       all-or-nothing per 17 §5; one BOUNTY economy-log line; zeroes that heat

# game/game.gd — the wiring owner (one owner, 17 §2): the kill path is the real
#   seam `_on_npc_died` (NpcShip.died; projectile.gd:_shot_down is the rocket
#   intercept, not a hull kill) — it calls LootTables.roll_band + roll_hunter_extra
#   and spawns the wreck site (WRECK_PICKUP_LIFETIME 90 s, 06 §4); heat only with a
#   witness in WITNESS_RANGE 900.0 (= ShipFit.BASE_SCAN_RANGE, 13 §7); sector
#   transitions go through the `loading` route (game.gd:on_route reads PARAM_SECTOR)
#   and file the vitals first (`_file_damage_report`), so hull/shield/fuel/ammo
#   persist across the scene reload (11 §2.3: fields/pickups reset, hold/hull/heat
#   persist). One prompt-line priority owner: `_update_dock_prompt` currently writes
#   the line every frame, so gate/scan/cache readouts need a priority arbiter.
```

Rules that fix every ambiguity:

- **No `ui/hud/**` writes, period.** Gate prompt (`JUMP TO <SECTOR> — <fee> CR`,
  `GATE REFUSED — OUTLAW`), scan readout (`SCANNING nn %`, 4 Hz) and cache feed
  (`+120 CR SALVAGE`) all ride the frozen `set_prompt` seam (§7). D6 owns that
  directory until it closes; a readout that "needs" a new widget is a report,
  not a write.
- **Fee composition** is multiplicative on the base: `floor((150 + 100·d) ×
  want × lawless)` (11 §5 tick 1 as built). Worked rows: adjacent 250, two away
  350, adjacent-to-7 at Wanted **750** (`floor(250 × 1.5 × 2)`; the additive
  reversal's figure is 562 and is not this build's number).
- **Refusals write nothing** (S4's rules 7/8 precedent): the gate at heat-Outlaw,
  the dock at standing-Outlaw, `pay_bounty` with a zero heat or insufficient
  funds — the profile is byte-identical after each. Two axes, each from its own
  doc: **gate ← `NpcRegistry.heat_tier()`** (13 §3), **dock ←
  `PlayerProfile.standing()` ≤ −51** (12 §4.1, add it to the read list).
- **Heat is clamped 0–100** on gain (13 §2's bound).
- **Witness rule:** gains only with a neutral/patrol hull or station inside
  `WITNESS_RANGE` 900.0 with the brain's rock-blocking LOS (13 §7). The values
  come from `heat_on_kill()` verbatim (+15/+25/+25/+5 witness extra, −3 pirate);
  never re-derive them.
- **Hunters:** per-faction (13 §3 — Concord hunts only Concord's outlaw);
  Wanted = on next sector entry; Outlaw = perma-tail, 60 s respawn after the
  wave dies, that faction's space only. The hull map is tick 6's proposal as
  built unless the owner's tick says otherwise before dispatch.
- **Loot:** `roll_band()` delegates to the shipped `roll()` (06 §2's procedure
  exactly — independent per line, `randi_range(min, max)` inclusive, hence ±5 % on
  expected hauls; one entry per line, caches last and distinct) and
  `roll_hunter_extra()` adds 06 §8's rows grade-capped by band. Grade caps assert
  at load (06 §6). **Do not restate or reshape the shipped `roll`.**
- **One-timer rule (17 §4):** anomaly/derelict/wreck respawn bookkeeping reads
  the shared `WorldClock`; no new Timer nodes anywhere in this wave.
- Route is yours (bucket 1): file-internal structure, node names, the channel
  implementation, test helpers. What is NOT yours: any number above, any
  `ui/hud/**`/`assets/**`/`project.godot`/theme write, any existing test's
  expectations, `18_engine_spec.md`.

## Worker table

| ID | Role | VAJB_WORKER_FILES | Deliverable |
|---|---|---|---|
| S6-K0 | docs drift check | `docs/,vajb-orbit/tests/,vajb-orbit/tools/` | `S6-K0_report.md` — the pin set vs the tree (post-D6-current), contradictions at `file:line`, no numbers invented |
| S6-K1 | travel core (registry rows, gates, corridors, transitions) | `vajb-orbit/game/sector_registry.gd,vajb-orbit/game/gate.gd,vajb-orbit/game/corridor.gd,vajb-orbit/game/game.gd,vajb-orbit/game/sector.gd,vajb-orbit/tests/` | AC1/AC2/AC4 + `tests/test_s6_travel.gd` |
| S6-K2 | POIs + loot | `vajb-orbit/game/poi.gd,vajb-orbit/game/loot_tables.gd,vajb-orbit/game/sector.gd,vajb-orbit/game/game.gd,vajb-orbit/tests/` | AC3/AC7 + `tests/test_s6_poi_loot.gd` |
| S6-K3 | heat + hunters + bounty | `vajb-orbit/game/npc_registry.gd,vajb-orbit/game/npc_brain.gd,vajb-orbit/game/npc_ship.gd,vajb-orbit/autoload/player_profile.gd,vajb-orbit/game/game.gd,vajb-orbit/game/station_catalog.gd,vajb-orbit/ui/station/launch_panel.gd,vajb-orbit/tests/` | AC5/AC6 + `tests/test_s6_heat.gd` |
| S6-R1 | mandatory review | `vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md` | `S6-R1_review.md` + LOW rows in `_state/LOW_BACKLOG.md` |
| S6-F1 | fixer | union of K1–K3 sets + `docs/CONTRACTS.md` | only if R1 leaves HIGH/MED |

**Run order:** K0 → K1 → K2 → K3 → R1 → (F1 only on HIGH/MED). K1/K2/K3
are pairwise file-disjoint except `game/game.gd` + `game/sector.gd`, which are
**sequenced ownership**: K1 lands game.gd/sector.gd first and exposes the seams
(the real ones: `game.gd:_on_npc_died`, `game.gd:on_route` + the `loading` route,
`sector.gd:populate`); K2 and K3 then
append to those files in the same run order — **K2 before K3** (K3's heat hook
wires into the kill seam K2's loot roll already occupies). Each builder writes
only its own `test_s6_*.gd`. The seam lesson (WAVEBOARD): review probes the
K1↔K2↔K3 joins by measurement.

**Parallel safety with D6 (designer item 7, in flight):** this wave writes
`game/**`, `autoload/player_profile.gd`, `ui/station/launch_panel.gd` (K3's
bounty row, owner-ratified set growth) and `tests/test_s6_*.gd` only. D6 holds
`ui/hud/**`, `assets/**`, `staging/**`, `asset-library/**`, `tests/test_d6_*.gd`
— **the sets are disjoint** (the S5∥D6 precedent extended). Shared surfaces:
the `tests/` dir (file names disjoint) and gate runs (bound, scratch stores;
editor reimports only in quiet windows; one editor session).

## Tests that move, and why

- **None of the existing counts move.** `test_engine2_npc.gd`'s heat rows
  (185–193, 389, 393) and `test_p1_profile.gd`'s heat round-trip hold
  byte-identical — the pin keeps `heat_tier`/`heat_on_kill`/`heat()` as-is.
  `test_engine2_pools.gd:254`'s "context recorded for slice 3" row holds (the
  `ctx` routing turns on with quadrants in **slice 4**, not here — owner-ratified
  deferral, CONTRACTS §19's dispositions). `test_engine2_loot.gd`'s shape rows
  (`:249-272`, `:368-389`) hold too: the band roll is additive (K0 F2/F3).
- New: `test_s6_travel.gd` (fee worked rows + composition, refusal-write-nothing,
  corridor presence/reset rules, transition persistence) ≈ 14 groups;
  `test_s6_poi_loot.gd` (derelict roll over 10 000 seeded rolls, anomaly kinds +
  Hollows weighting + rift drain, expected hauls ±5 %, grade caps, wreck 90 s) ≈ 16;
  `test_s6_heat.gd` (witness gating, decay, fine math, hunter spawn/respawn/
  isolation, refusals) ≈ 15.
- Expected gate: S5's close **578** plus ~45 → the measured number at close-out
  goes into CONTRACTS §9 (the projection is not a pin).

## Hard rules

- Frozen for workers: `project.godot`, `docs/gameplay/18_engine_spec.md`,
  `docs/gameplay/08_ship_slots_modules.md`, `vajb-orbit/addons/`,
  `vajb-orbit/ui/theme/vajb_theme.tres`, **all of `ui/hud/**` and `assets/**`**
  (K3's two `ui/station/` + `game/station_catalog.gd` files are the only
  exceptions, and only for the bounty row).
- No balance number moves except the pin's own new constants (each carries its
  reversal in §19/11 §5/13 §7/06 §8). `max_speed`, damage, cadence, prices hold.
- Transaction law 17 §5 for `pay_bounty` and the gate charge; integers only;
  every economy event logs (01 §7).
- Scratch stores for every probe/gate (T-93 class); bounded probes (L82); no
  shell file edits; workspace-relative `VAJB_WORKER_FILES` (L92a); never leave
  a background job.
- A number not in the pinned docs: **report it, never invent it**.

## Staged / deferred

- The station turret entity (13 §7 tick 7 — no entity exists; +25 heat on
  attacking a station lands, turret aggro staged).
- Bosses/arena hooks (slice 4), affix application (item 13), insurance/
  contracts/vaults (P4), crafting (07).
- Faction standing dials from hunters (12 §4, P4).
- Any `ui/hud/` upgrade of the readouts (post-D6; the `set_prompt` route is the
  pin until then).

## Owner ticks owed after this wave

1. **Fee multiplier composition** — multiplicative as built (11 §5), worked row
   750; reversal additive (562).
2. **Corridor rules** — depth 600 u; damage does not interrupt the 15 s hold
   (11 §5); reversal 400 u / damage-resets.
3. **Derelict scan range** — 300 u (11 §5); reversal the fit's `scan_range`.
4. **Rift drain** — 12 shield/s (11 §5); reversal 6.
5. **Bounty surface** — LAUNCH row shipped this wave (owner-ratified set growth,
   13 §7); reversal REPAIRS column.
6. **Hunter hull map** — the three-band proposal (13 §7); reversal all-fighter.
   **Also tick the hunter aggro/scan radius 900.0** (proposed; reversal 1200.0).
7. **Station turret** — staged; tick to schedule the entity.
8. **Hunter extra loot table** — the `comp_elec` proposal (06 §8); reversal none.
9. **Data-core credits** — 120 CR (proposed, the cache's own value, CONTRACTS
   §19); reversal 60.
10. **Scope rulings ratified this pass:** quadrants deferred to slice 4;
    `sibelon` superseded by the three anomaly kinds; the 06 §8 "one pickup per
    unit" wording corrected to the shipped stack shape.
11. Standing debt unchanged: `18_engine_spec.md` §6/§13/§15, the §13
   turn/`coast_time` ticks, slice 2.5's two calls, S3's nine, S2.6's four,
   S5's three, D6's five.

## Close-out (the orchestrator runs these, in order)

1. Gate twice (scratch store; identical counts) + the live-profile untouched check.
2. `python3 staging/verify_wave.py verify --baseline s6_start --forbidden vajb-orbit/project.godot docs/gameplay/18_engine_spec.md docs/gameplay/08_ship_slots_modules.md --tests --expect-reports .agents/gen/slices/S6-travel/S6-K0_report.md .agents/gen/slices/S6-travel/S6-K1_report.md .agents/gen/slices/S6-travel/S6-K2_report.md .agents/gen/slices/S6-travel/S6-K3_report.md .agents/gen/slices/S6-travel/S6-R1_review.md` (the S4-corrected flag form; `validate_names.py --library` is environment-deferred on the Linux host)
3. CONTRACTS §9/§10 measured notes by R1 — **sequenced after D6's close-out
   §9/§10 pass** so that file has one writer at a time.
4. `_state/WAVEBOARD.md` closed; LOW rows at the next free ids.
5. Wave-boundary commit.
