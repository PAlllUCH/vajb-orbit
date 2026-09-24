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
"0–500 CR" — 0–500 wins, amended in 01 §5.2. Both are in CONTRACTS §10 v0.11.

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
- `autoload/player_profile.gd:263` `add_credits` (06 §5's cache route),
  `game/projectile.gd:742` `_shot_down` (the kill seam where the loot roll lands).
- `tests/test_engine2_npc.gd:185-193` pins `heat_tier`'s four bands at the 13 §3
  thresholds; `:389,393` pin `heat_on_kill` at −3/+15. **All hold unmodified.**
- `tests/test_p1_profile.gd:109,144,194-210` pin the `heat` key round-trip. **Holds.**
- No station turret entity exists in `game/` (grep 2026-09-24) — 13 §7 tick 7.

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

# game/loot_tables.gd — new file (17 §2's name), class_name LootTables extends RefCounted:
#   static TABLES: Dictionary   # 06 §3.1–§3.4 verbatim (fighter/freighter/corvette/Maw)
#   static HUNTER_EXTRA: Array  # 06 §8's proposed comp_elec table (owner tick 8)
#   roll(band: StringName) -> Array[Dictionary]   # §2's procedure; one pickup per
#       unit (06 §8's made choice); caches last, one distinct pickup (06 §5)

# game/sector.gd — additive beyond §6's pin (scanner reveal lives here, engine §14):
#   blips() gains gate/beacon/ders/anomalies entries per 11 §5's mapping; soft fog:
#   a POI blip appears once scanned or beacon-revealed; gates and stations always
#   appear. WorldClock remains the only respawn clock (17 §4).

# autoload/player_profile.gd — additive:
#   pay_bounty(faction_id: StringName) -> bool   # fine = heat × 25 CR (13 §2);
#       all-or-nothing per 17 §5; one BOUNTY economy-log line; zeroes that heat

# game/game.gd — the wiring owner (one owner, 17 §2): the kill path calls
#   LootTables.roll + spawns the wreck site (WRECK_PICKUP_LIFETIME 90 s, 06 §4);
#   heat only with a witness in WITNESS_RANGE 900.0 (= ShipStats.BASE_SCAN_RANGE,
#   13 §7); sector transitions go through the `loading` screen route (11 §2.3:
#   fields/pickups reset, hold/hull/heat persist).
```

Rules that fix every ambiguity:

- **No `ui/hud/**` writes, period.** Gate prompt (`JUMP TO <SECTOR> — <fee> CR`,
  `GATE REFUSED — OUTLAW`), scan readout (`SCANNING nn %`, 4 Hz) and cache feed
  (`+120 CR SALVAGE`) all ride the frozen `set_prompt` seam (§7). D6 owns that
  directory until it closes; a readout that "needs" a new widget is a report,
  not a write.
- **Fee composition** is multiplicative on the base: `floor((150 + 100·d) ×
  want × lawless)` (11 §5 tick 1 as built). Worked rows: adjacent 250, two away
  350, adjacent-to-7 at Wanted 562 (floor of 250×1.5×2).
- **Refusals write nothing** (S4's rules 7/8 precedent): Outlaw at a gate, an
  Outlaw docking, `pay_bounty` with a zero heat or insufficient funds — the
  profile is byte-identical after each.
- **Witness rule:** gains only with a neutral/patrol hull or station inside
  `WITNESS_RANGE` 900.0 with the brain's rock-blocking LOS (13 §7). The values
  come from `heat_on_kill()` verbatim (+15/+25/+25/+5 witness extra, −3 pirate);
  never re-derive them.
- **Hunters:** per-faction (13 §3 — Concord hunts only Concord's outlaw);
  Wanted = on next sector entry; Outlaw = perma-tail, 60 s respawn after the
  wave dies, that faction's space only. The hull map is tick 6's proposal as
  built unless the owner's tick says otherwise before dispatch.
- **Loot:** `roll()` implements 06 §2's procedure exactly (independent per line,
  `randi_range(min, max)` inclusive — hence ±5 % on expected hauls), one pickup
  per unit, caches last and distinct. Grade caps assert at load (06 §6).
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
| S6-K3 | heat + hunters + bounty | `vajb-orbit/game/heat.gd,vajb-orbit/game/npc_registry.gd,vajb-orbit/game/npc_brain.gd,vajb-orbit/game/npc_ship.gd,vajb-orbit/autoload/player_profile.gd,vajb-orbit/game/game.gd,vajb-orbit/tests/` | AC5/AC6 + `tests/test_s6_heat.gd` |
| S6-R1 | mandatory review | `vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md` | `S6-R1_review.md` + LOW rows in `_state/LOW_BACKLOG.md` |
| S6-F1 | fixer | union of K1–K3 sets + `docs/CONTRACTS.md` | only if R1 leaves HIGH/MED |

**Run order:** K0 → **(K1 ∥ K2 ∥ K3)** → R1 → (F1 only on HIGH/MED). K1/K2/K3
are pairwise file-disjoint except `game/game.gd` + `game/sector.gd`, which are
**sequenced ownership**: K1 lands game.gd/sector.gd first and exposes the seams
(`_on_kill`, `_transition`, `_poi_table` hooks named in §19); K2 and K3 then
append to those files in the same run order — **K2 before K3** (K3's heat hook
wires into the kill seam K2's loot roll already occupies). Each builder writes
only its own `test_s6_*.gd`. The seam lesson (WAVEBOARD): review probes the
K1↔K2↔K3 joins by measurement.

**Parallel safety with D6 (designer item 7, in flight):** this wave writes
`game/**`, `autoload/player_profile.gd` and `tests/test_s6_*.gd` only. D6 holds
`ui/hud/**`, `assets/**`, `staging/**`, `asset-library/**`, `tests/test_d6_*.gd`
— **the sets are disjoint** (the S5∥D6 precedent extended). Shared surfaces:
the `tests/` dir (file names disjoint) and gate runs (bound, scratch stores;
editor reimports only in quiet windows; one editor session).

## Tests that move, and why

- **None of the existing counts move.** `test_engine2_npc.gd`'s heat rows
  (185–193, 389, 393) and `test_p1_profile.gd`'s heat round-trip hold
  byte-identical — the pin keeps `heat_tier`/`heat_on_kill`/`heat()` as-is.
  `test_engine2_pools.gd:254`'s "context recorded for slice 3" row holds (the
  `ctx` routing turns on with quadrants in **slice 4**, not here).
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
  `vajb-orbit/ui/theme/vajb_theme.tres`, **all of `ui/hud/**` and `assets/**`**.
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

1. **Fee multiplier composition** — multiplicative as built (11 §5); reversal
   additive.
2. **Corridor rules** — depth 600 u; damage does not interrupt the 15 s hold
   (11 §5); reversal 400 u / damage-resets.
3. **Derelict scan range** — 300 u (11 §5); reversal the fit's `scan_range`.
4. **Rift drain** — 12 shield/s (11 §5); reversal 6.
5. **Bounty surface** — LAUNCH row (13 §7); reversal REPAIRS column.
6. **Hunter hull map** — the three-band proposal (13 §7); reversal all-fighter.
7. **Station turret** — staged; tick to schedule the entity.
8. **Hunter extra loot table** — the `comp_elec` proposal (06 §8); reversal none.
9. Standing debt unchanged: `18_engine_spec.md` §6/§13/§15, the §13
   turn/`coast_time` ticks, slice 2.5's two calls, S3's nine, S2.6's four,
   S5's three, D6's five.

## Close-out (the orchestrator runs these, in order)

1. Gate twice (scratch store; identical counts) + the live-profile untouched check.
2. `python3 staging/verify_wave.py verify --baseline s6_start --forbidden vajb-orbit/project.godot docs/gameplay/18_engine_spec.md docs/gameplay/08_ship_slots_modules.md --tests --expect-reports .agents/gen/slices/S6-travel/S6-K0_report.md .agents/gen/slices/S6-travel/S6-K1_report.md .agents/gen/slices/S6-travel/S6-K2_report.md .agents/gen/slices/S6-travel/S6-K3_report.md .agents/gen/slices/S6-travel/S6-R1_review.md` (the S4-corrected flag form; `validate_names.py --library` is environment-deferred on the Linux host)
3. CONTRACTS §9/§10 measured notes by R1 — **sequenced after D6's close-out
   §9/§10 pass** so that file has one writer at a time.
4. `_state/WAVEBOARD.md` closed; LOW rows at the next free ids.
5. Wave-boundary commit.
