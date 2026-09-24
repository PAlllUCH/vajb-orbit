---
slice: S6
worker: S6-R1
model: "deepseek/deepseek-v4-flash"
status: passed-with-followups   # no HIGH, no MED; eight LOW rows (L150–L157)
gate: "passed=674 failed=0, four runs on four scratch stores; live profile md5 unchanged"
---

# S6-R1 review — travel (engine slice 3 + RPG P3)

Reviewer `S6-R1`, wave `S6`, slice `S6-travel`, 2026-09-24.
Brief: `.agents/gen/slices/S6-travel/S6_BRIEF.md`. **Findings are diffed against the pins,
never against the brief**: `docs/CONTRACTS.md` §19 (with its K0/K1/K2/K3 dispositions
blocks) + §9/§10, `docs/gameplay/11_galactic_map.md` §2/§3/§5,
`docs/gameplay/13_heat_bounty.md` §2–§5/§7, `docs/gameplay/06_loot_drops.md` §2–§5/§8,
`docs/gameplay/12_factions.md` §4.1, `docs/gameplay/01_economy_core.md` §5.2/§7 and
`docs/gameplay/17_coder_handoff.md` §2/§4/§5. Every number below was re-measured by the
reviewer; the builders' suites are cited as corroboration, never as proof.

## Verdict

**No HIGH, no MED.** Eight **LOW** (backlog rows `L150`–`L157`). Every acceptance criterion
in `SLICE.md` measures as pinned, the builders' suites (18/25/23) are green and their
assertions are non-tautological (each was read, and the numbers each depends on were
re-derived independently), the K1↔K2↔K3 seam joins hold under an independent scene probe,
no frozen file moved and no `ui/hud/**`/`assets/**` write happened. **No fixer pass is
owed.**

| Tier | Count | Where |
|---|---|---|
| HIGH | 0 | — |
| MED | 0 | — |
| LOW | 8 | `L150`–`L157` in `.agents/gen/_state/LOW_BACKLOG.md` |

## Method (what the reviewer ran itself)

- **Gate, four times, four scratch stores** (`XDG_DATA_HOME=/tmp/s6r1_scratch_{a,b,c,d}`),
  the canonical command
  `$GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200`
  → **`[SUMMARY] passed=674 failed=0`**, exit 0, all four runs, identical counts;
  **674 PASS rows, 0 FAIL, 0 SKIP, 53 suites** (logs saved in `_review_probes/gate_{a,b}.log`).
  The live `~/.local/share/godot/app_userdata/Vajb Orbit/profile.cfg` md5 is
  **`06f5660a4f884c5d799311287721f78f`** before and after, `economy_log.txt` md5
  **`ca40fe2c0ab3bd0f2047723a2d737d9a`** before and after, and the profile's mtime
  `2026-09-24 09:43:36` is unmoved (the runner's own `_gate_scratch` sandbox, CONTRACTS §14).
  The three error-ish lines are the pre-existing ones: `ERROR: Parameter "data.tree" is
  null.` (the detached-hull plasma path, `game/weapons.gd:2050`, reached from
  `test_combat_repair_c5.gd`), `SCRIPT ERROR: Cannot call method 'call' on a previously
  freed instance.` at `tests/test_weapon_fx_f4.gd:178` (L61) and the benign
  `ERROR: 12 resources still in use at exit` warning. No new `SCRIPT ERROR`, no new failure.
- **The four S6-related suites in isolation**, each green: `test_s6_travel` **18**,
  `test_s6_poi_loot` **25**, `test_s6_heat` **23** (the builders' 18 + 25 + 23 = 66),
  `test_engine2_loot` **13**, `test_engine2_npc` **28**, `test_p1_profile` **11**.
  `608` (D6's close) `+ 18 = 626` (K1) `+ 25 = 651` (K2) `+ 23 = 674` (K3) — the arithmetic
  the three reports claim.
- **`staging/verify_wave.py verify --baseline s6_start --forbidden
  vajb-orbit/project.godot docs/gameplay/18_engine_spec.md docs/gameplay/08_ship_slots_modules.md
  --tests`** (the S4-corrected flag form, under scratch store C; log
  `_review_probes/verify_wave_tests.log`) → the gate passes internally, and the only
  `problems` entry is `"forbidden files touched: vajb-orbit/project.godot"`. **That hit is
  not S6's**: `git log -- vajb-orbit/project.godot` shows the file's only post-`s6_start`
  writer is **`ef0e06f` (D6's close-out)**, which adds the `ship_status` input action (key
  **U**); the working tree has **no** diff against `HEAD` for it. S6's own file set
  (`game/**`, `autoload/player_profile.gd`, `ui/station/launch_panel.gd`,
  `tests/test_s6_*.gd`, the one ratified `test_engine2_wiring.gd` row) contains no
  `project.godot`, `ui/hud/**`, `assets/**`, theme or docs-gameplay write. Row `L157`.
- **An independent pure probe** (reviewer-written, run as `--script`, then deleted; log
  `_review_probes/probe_s6_r1.log`): the registry spine, the fee sweep, the corridor rules,
  the three seeded distributions, the loot hauls, the grade caps and the hunter row, with
  every expectation typed from the docs rather than read off the shipped tables.
- **An independent scene probe suite** (reviewer-written `test_s6_r1_seams.gd`, run under
  `--suite`, then deleted; log `_review_probes/probe_s6_r1_seams.log`): the K1↔K2↔K3 joins
  measured end to end on the real scene lifecycle. The builders' own probes were deleted at
  their close, so this re-runs the joins their suites prove with the reviewer's own
  assertions (the W8 method's intent).

## Findings

| ID | Tier | File:area | Finding |
|---|---|---|---|
| R1-L150 | LOW | `game/game.gd:215,307-309,2112-2129` | **The heat-decay clock is scene-scoped, so a sector crossing discards the minute in progress.** `_heat_play_time` is a plain `var` on the scene, advanced by `_decay_heat`; `Router.route` rebuilds the scene on every crossing (and on every dock→launch), so the bank resets. 13 §2 says "−1 per minute of play, **anywhere**"; the pin puts the accumulator "on the game scene's own tick", so the pinned shape loses up to 60 s per crossing — bounded to **<1 heat point per crossing**, measured by construction (`_decay_heat(59.9)` leaves 40; a rebuilt scene reads `_heat_play_time == 0`). K3 reported it (`S6-K3_report.md` §3.9) but it is **not** in §19's K3 dispositions. Reversal: a `static` accumulator beside `_transit_destination` (one line). |
| R1-L151 | LOW | `game/poi.gd:535-536,558-565,610-621` | **The rift's module exotic is granted straight to the bag, not spawned as the "1 exotic pickup … at its heart" 11 §3.2 describes.** `_spawn_rift_exotic` spawns a pickup for the T4-ore branch but calls `_grant_module()` (`PlayerProfile.roll_instance` → `add_instance`) for the 10 % module branch; the derelict's 25 % module branch (`:535-536`) is direct too. The player is already inside the 200 u trigger radius when it fires, so the practical difference is nil, but the delivery mode is a route decision the K2 report does not state. Reversal: a pickup that grants an instance (new plumbing), or a report line in §19. |
| R1-L152 | LOW | `game/gate.gd:142-150,153-155,164-165`; `game/game.gd:824-848` | **A paid gate jump cannot be interrupted.** `Gate.advance_charge` runs from `_process` regardless of the ship leaving `TRIGGER_RADIUS` or taking a hull hit, and `Gate._process` still runs while the scene is `_dead` (`_physics_process` returns early but the ring's own tick does not). The warp channel cancels on both (`game.gd:_on_ship_damage_taken`). 11 §2.1/§5 give no cancel rule and the fee is paid at confirm, so "always arrives" is a defensible reading — but `Gate.cancel_jump()` (`:153`) is **dead code**, never called. Reversal: call it on zone exit / damage / death. |
| R1-L153 | LOW | `game/game.gd:747-760,776-780`; `game/gate.gd:105-128` | **The gate's insufficient-funds refusal has no readout.** `_request_gate_jump` discards `Gate.jump`'s `-2`; the prompt keeps showing `JUMP TO <SECTOR> — <fee> CR` and `interact` silently does nothing. 11 §5 pins only the Outlaw line (`GATE REFUSED — OUTLAW`) and the fee formula is priced at the Wanted/Suspect tiers too, so a Wanted player 100 CR short gets no feedback. Reversal: a `GATE REFUSED — NOT ENOUGH CR` rung in the same ladder. |
| R1-L154 | LOW | `game/game.gd:215,329-335,391-393,832-840,1737-1745` | **A stale `_transit_destination` survives an interrupted crossing.** `_request_sector_route` arms the static, and only `game.gd:_ready` (after reading it) and `on_route` clear it. If the player dies during the loading fade — `Router.route` awaits ~1.4 s of fades — and the route becomes the station (or a game scene never lands), the flag stays armed through the dock and the next launch calls `_seed_ammo_from_store()` instead of drawing the hold. Bounded and rare; the store was filed at the transition, so the packs are the last filed state. Reversal: clear it in `_exit_tree` or when the route target is not `game`. |
| R1-L155 | LOW | `game/gate.gd:60-64` | **The gate's `Area2D` carries collision layer 1 (the rock layer) with a 200 u circle.** `_ready` adds a `CollisionShape2D` and never sets `collision_layer`; measured `collision_layer=1, collision_mask=1` against `Asteroid.COLLISION_LAYER=1`. **Inert today**: measured `PhysicsRayQueryParameters2D.create(...).collide_with_areas == false`, `_rock_line_clear`/`_lock_clear_line`/`weapons` all use that default (or a layer-1|2 mask) and `projectile.gd:_sweep_projectiles` masks layer 4, while `Area2D` never blocks a body. Hygiene only: give the ring a dedicated layer (or `collision_layer = 0`) so a later `collide_with_areas = true` query cannot read a ring as rock. |
| R1-L156 | LOW | `docs/gameplay/12_factions.md:70`; `docs/gameplay/13_heat_bounty.md:135` | **Two doc drifts the pin leaves behind.** (a) 12 §4.1's Outlaw band lists "**gate refusal**" as a standing effect, but CONTRACTS §19 and 13 §7 assign the gate refusal to the **heat tier** (the two-axis rule) — so a standing-Outlaw/heat-Clean player is sold a ticket and 12 §4.1's cell is unreachable. The pin wins; the cell needs a superseding note. (b) 13 §7 cites `game/npc_registry.gd:208` for the pirate fighter band's radius; the value is now at **`:220`** (the row shifted by the 12 lines of new hunter constants above it). Both are bucket-2 doc text. |
| R1-L157 | LOW | `.agents/gen/_state/_wave_state/s6_start.json`; `staging/verify_wave.py` | **The `s6_start` baseline predates D6's close-out, so the forbidden-file check trips on a parallel lane's ratified write.** `verify_wave.py verify --baseline s6_start --forbidden vajb-orbit/project.godot …` exits 1 with `forbidden files touched: vajb-orbit/project.godot`; the only post-`s6_start` writer is `ef0e06f` (D6's close-out, the `ship_status` action, no working-tree diff). Not S6's write. The close-out should either accept the hit with this attribution or re-snapshot before verifying. (Same class as L149's `XDG_DATA_HOME` gap.) |

**No HIGH and no MED is a finding, not an omission.** The two candidates that looked
closest were the scene-scoped decay (`L150`, pinned shape, <1 point per crossing) and the
rift's module delivery (`L151`, nil impact because the player is inside the trigger radius);
both are bounded, both have one-line reversals, and neither touches a pinned number, a
pinned test or the acceptance criteria.

## Acceptance criteria, re-measured

| AC | Pin | Measured by the reviewer | State |
|---|---|---|---|
| AC1 fee | 11 §2.1 adjacent 250 / two away 350; 11 §5 `floor((150+100·d) × want × lawless)` | Independent formula sweep vs `Gate.fee_for`: `1→2` 250, `1→3` 350, `6→7` Wanted **750**, `1→3` Wanted 525, `5→7` clean 700 / Wanted 1050, `6→7` Suspect 500 — every row equal; **562 produced for no (origin,dest,tier) combination** | PASS |
| AC1 refusal | Outlaw refused, nothing written | `jump` at Outlaw → `-1`, `spend_calls == 0`, balance unmoved; a 249 CR account vs 250 → `-2`, `spend_calls == 0`; the live `PlayerProfile` deep snapshot (credits, cargo, heat, standing, ammo, vitals) byte-equal after both | PASS |
| AC2 corridor | 15 s presence; exit resets; hull damage does not | `update_presence(7.5, inside)` → 0.500; exit → 0.000 / `is_holding() == false`; 14.9 s fires nothing, +0.2 fires `crossed(2)` once, a further step does not re-fire; on the live scene a hull hit (`_on_ship_damage_taken(25.0)`) leaves the hold byte-equal | PASS |
| AC3 derelict | 0.40/0.35/0.25 over 10 000 ±2 pp | 10 000 seeded: cache **0.3991**, data core **0.3488**, module **0.2521** | PASS |
| AC3 anomaly | three kinds; Hollows rift 2× | `sector_1` 0.3321/0.3305/0.3374; `sector_6` 0.2486/0.2519/**0.4995** (weights 1/1/2 → 0.50); `sector_7` normal | PASS |
| AC3 rift | `RIFT_DRAIN` 12/s; module 0.10 | `RIFT_DRAIN == 12.0`; `update_presence(1.0) == 12.0`, `0.5 → 6.0`, outside → `0.0`; exotic module rate **0.0998** over 10 000 | PASS |
| AC4 transition | through `loading`; fields/pickups reset, hold/hull/heat byte-equal | Independent probe: hull 41 / shield 9 / fuel 77 filed **before** the route (read at emit time); the rebuilt scene reads 41/9/77, hold byte-equal, heat `{concord: 33}` preserved, pickups 1 → 0; the route is `loading` → `{destination: game, sector: sector_2}`; `_sector_name` lands "Iron Marches"; the destination re-populates 2 gates / 2 corridors / POIs | PASS |
| AC5 heat | witness-gated (0 without), −1/min, fine = heat × 25, refusals | Suite + independent probe: a real sector trader killed in dead space files **0**; the same kill with a real patrol 200 u away files `row + 5`; clamp 95+30 → 100 and 2−3 → 0; decay 59.9 s → 40, +0.2 → 39, +3 min → 36, +10 min → 26, floor 0 writes nothing; 40 heat → **1 000 CR**; `pay_bounty` zeroes that faction, one `BOUNTY` line, refusals byte-identical and log nothing | PASS |
| AC6 hunters | Wanted 2–3 on entry; Outlaw 60 s; per-faction | Row: `seam=""`, `spawn=sector`, `tier=1`, `aggro=scan=900.0`, density `(0,0)` in every sector; hull map matches 13 §7 for all ten player hulls; wing size `(2,3)`; suite: Wanted spawns 2–3 homed ≤600 u on the player, one wing per entry; Outlaw dead at 59 s, back at 61 s, Wanted never perma-tails; Concord's heat spawns nothing in Meridian space and sector 7 spawns nothing at any tier | PASS |
| AC7 loot | 06 §6 ±5 %; grade caps; wreck 90 s | Independent 10 000-kill sample vs doc-derived sums: fighter 2.1428 u / 28.3464 CR (−0.33 % / −0.10 %), freighter 2.3014 / 44.7427 (+0.06 % / +0.43 %), corvette 1.4860 / 77.9180 (−0.93 % / −1.06 %), maw 6.3414 / 1581.2110 (−0.53 % / −0.22 %); `cap_violations() == []`, `hunter_extra_violations(3) == []`, `(1)` non-empty; wreck whole to 89.9 s, freed at 90; hunter extra 0.4978/0.2501/0.0984 | PASS |

## The shipped `roll` and the moved row

- **`LootTables.roll(kind, tier, seed)` is byte-identical.** `git diff HEAD --
  game/loot_tables.gd` adds `WRECK_PICKUP_LIFETIME`, `HUNTER_EXTRA`, `roll_band`,
  `roll_hunter_extra` and `hunter_extra_violations` around it; `TABLES` and `roll`'s body
  carry no diff line. `test_engine2_loot.gd`'s shape rows are green (`13/13`), and an
  independent 800-kill walk of `roll_band` for all four kinds holds "cache last, at most
  one". `roll_band` is a delegate (`roll(kind, TABLES[kind].band, seed)`).
- **One existing row moved, exactly as ratified.** `tests/test_engine2_wiring.gd`'s
  minimap-feed assertion is the only pre-existing edit in the wave's diff; the expectation
  is derived from the sector's own `gates()`/`beacons()` counts (`hulls + fields + gates +
  beacons + 1`, `friendly == gates + beacons + 1`), so a one-link and a two-link sector both
  hold and K2's fogged derelict/anomaly blips do not enter it. No other existing test
  expectation changed (the wave's test diff is that row plus the three new suites).

## The K1↔K2↔K3 seam joins, by measurement

The builders' probes were deleted at their closes, so the joins were re-measured with the
reviewer's own scene probe (three tests, all green):

1. **K1 `sector.gd:populate` → travel + POIs, across a real crossing.** Sector 1 populates
   its gate/corridor/POIs; `_transition_to_sector(2)` files vitals first and routes
   `loading`→`sector_2`; the rebuilt scene's `on_route` lands sector 2 with **2 gates, 2
   corridors and its own POIs**, hull/hold/heat preserved. This is the join the brief calls
   out (K1's `_spawn_travel` + K2's `_spawn_pois` in one `populate`).
2. **K1 `game.gd:_on_npc_died` → K2's wreck site + K3's witness gate, on real hulls.**
   A real `trader` hull spawned through the sector's own `_add_npc`, moved to dead space,
   killed through the seam: **heat 0** (K3's victim exclusion) and **one wreck site** (K2's
   loot). A real `patrol` hull 200 u away then turns a second real kill into
   `heat_on_kill + WITNESS_EXTRA`, and that kill leaves a second site.
3. **K1's destination geometry answers its own links.** Sector 1's single ring fees 2 at
   250; sector 2's two rings fee 1 and 3 at 250 and its two corridors name `[1, 3]`.

The suite-level joins the builders own were also read for tautology: the witness tests
derive the expected value from the victim's own row (`_row_value(archetype, KEY_HEAT_ON_KILL)
+ WITNESS_EXTRA`), the hunter-extra tell is read off both tables (`_line_max(FIGHTER_LINES)
== 1` vs `_line_max(HUNTER_EXTRA) == 2`), the refusal snapshots are deep, and the wreck
test derives each amount's bounds from the shipped table's own line. None restates the
number it checks.

## Owner ticks — nothing new is owed by this review

The brief's fourteen tick items stand unchanged. This review adds **no** new number for the
owner: every LOW row is a route note or a citation drift, and each carries its reversal in
the table above. The two measured deviations worth an owner look if the orchestrator wants
them folded into §19 are `L150` (decay across a crossing) and `L151` (the rift's module
delivery).

## Close-out notes for the orchestrator

1. **Gate**: `674/0` four times on four scratch stores; the live `profile.cfg` md5
   `06f5660a4f884c5d799311287721f78f` and `economy_log.txt` md5
   `ca40fe2c0ab3bd0f2047723a2d737d9a` are unmoved.
2. **`verify_wave.py`** exits 1 on the single `project.godot` forbidden hit — **D6's**
   `ef0e06f` write, not S6's (`L157`). Either accept it with that attribution or
   re-snapshot; `docs/gameplay/18_engine_spec.md` and `docs/gameplay/08_ship_slots_modules.md`
   are untouched.
3. **CONTRACTS §9/§10** carry S6's measured notes (this review, the next §10 entry).
4. The reviewer's probes were deleted after their runs; their logs live in
   `.agents/gen/slices/S6-travel/_review_probes/` (the D6 precedent).

## Gate

`[SUMMARY] passed=674 failed=0` — runs A, B, C (inside `verify_wave --tests`) and D, exit 0
each, identical counts, 674 PASS / 0 FAIL / 0 SKIP over 53 suites. Negative control: the
live store pair is byte-stable across all four runs, and the pre-existing `data.tree` /
`test_weapon_fx_f4.gd:178` lines are the only errors in the log.
