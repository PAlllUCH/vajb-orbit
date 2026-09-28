# S23 — Content activation (wave brief)

**Wave:** S23 (code lane, item 29 of `dispatch_coder.md`)
**Slice folder:** `.agents/gen/slices/S23-content-activation/`
**Baseline:** the gate after S22's close (record it in the report);
`python3 staging/verify_wave.py snapshot --name s23_start` before the first dispatch.
**Owner go (2026-09-27):** "a lot of new content as right now there isnt much" — pillar A ("activate dead content") was ticked first. **No new AI art** (owner): every sprite already ships in `asset-library/`/`vajb-orbit/assets/`.

## 1. The law to read, in order
1. `slices/S23-content-activation/SLICE.md` — scope, file sets.
2. `docs/gameplay/09_ship_slots_modules.md` + `08_ship_classes.md` **2026-09-27
   P3 blocks** (the pin rows R-S23-1..6) — by range.
3. AGENTS.md §"Rules" (asset pipeline: `archive.py --restore cut`, `pull.py`
   only copies, `validate_names.py --library` after any asset change).
4. `.agents/gen/_state/LOW_BACKLOG.md` — L137's row only.
5. The §5 spec extract.

## 2. The owner's request (verbatim)
> "right now the fundamentals are there, it needs a bit of playtesting and a lot
> of new content as right now there isnt much … i want to focus on content,
> bugfixes, playability and feel" (2026-09-27; all four pillars ticked, **no AI
> art generation** — "reuse the shipped library" is the constraint this wave
  turns into an advantage).

## 3. What is already measured (file:line)
| Fact | Site |
|---|---|
| `w_proton`/`w_flak` module rows exist but "No family row fires it yet" | `game/module_catalog.gd:328,338` |
| `c_ewar`/`u_refine`/`u_drones` carry `effects: {}` ("no effect row yet") | `module_catalog.gd:438,498,508` |
| their designed effects are pinned | 09 §3.4 (`c_ewar` 25 %/35 %), §3.6 (`u_refine` −50 % fee, `u_drones` 2/s regen) |
| 7 of 9 hulls launch mandatory-only (no starter fit) | `game/ship_fit.gd:544-587 (STANDARD_FITS)` |
| hunter's hull map names `ship_interceptor`, which exists nowhere | `game/npc_registry.gd:808`; `ship_fit.gd:300-382` has no such row |
| the turret row names `ship_turret_platform` (sprite-only) | `npc_registry.gd:328,334` |
| the sibelon seam ships nothing (`SEAM_SLICE_3`) | `npc_registry.gd:179-180` |
| `cm_chaff`/`cm_flare` drop but have no catalog rows | `game/loot_tables.gd:250 (uncatalogued_items)` |
| every hull flies the Vanguard sprite (FX anchors land wrong off it) | `game/player_ship.tscn:12-13`, `player_ship.gd:408-479` (L137) |
| faction + MMO + damaged liveries all ship unused | `docs/design/ASSET_CATALOG.md:55-143` (`ship_fighter_{choir,concord,meridian}_*`, `*_mmo_*`, `ship_vanguard_damaged_*`) |
| the sibelon/apex/interceptor/turret sprites ship | `ASSET_CATALOG.md:40-47,103-106,119-122,131` |

## 4. Pinned interface (verbatim) + rules
```gdscript
# game/weapons.gd:99-169 — the family table R-S23-1/2 extends
const FAMILIES: Dictionary = {
# game/station_catalog.gd:31-85 — the pack table that gains ammo_proton / ammo_flak
const AMMO_PACKS: Array[Dictionary] = [
# game/ship_fit.gd:544-587 / :300-382 — the fits and hulls tables this wave extends
const STANDARD_FITS: Dictionary = {
const HULLS: Dictionary = {
# game/npc_registry.gd:179-180 — the seam this wave releases (Sibelon)
const SEAM_SLICE_3: StringName = &"slice_3"
```

Rules:
1. **Content, not mechanics.** New rows follow the existing table shapes exactly
   (a family row reads like `laser`; a hull row like `ship_fighter`); the only
   values are the ones in the 2026-09-27 P3 blocks (ticks C1..C6 default
   PROPOSED — the S19 precedent).
2. **Effect rows wire end-to-end**: a module's effect is applied at the seam its
   09 §3 row names and is observable in a probe (`c_ewar` slows enemy
   targeting inside scan, `u_refine` halves the refinery fee for its ore,
   `u_drones` regenerates 2 hull/s in space). No display-only effects.
3. **Asset law**: restore `cut/` with `archive.py --restore`, cut/move only via
   `staging/roster/` scripts, `pull.py` copies into the project,
   `validate_names.py --library` proves every referenced name exists. Read
   `asset-library/_library.json` records before using any file (description is
   the truth, name is a hint).
4. **Per-hull sprite correctness**: FX anchors scale off the *drawn* hull's
   render px, the collider radius matches the drawn hull, and the Vanguard's
   numbers never leak onto another hull (L137's whole point).
5. **Turrets only if tick C6 confirms** (it is the 13 §5 reversal); unticked,
   the row is staged and A5 reports `STAGED (tick C6 open)`.

## 5. Spec extract (verbatim, cited)
`09_ship_slots_modules.md` §3.4 (computers):
> "| `c_ewar` | II | 1 | enemy targeting slowed 25 % while you are in their scan | 3 800 |
| `c_nexus` | III | 1 | +15 % weapon damage **and** +25 % scanner range and boosts `c_ewar` to 35 % | 6 400 |"

`09_ship_slots_modules.md` §3.6 (utility):
> "| `u_refine` | II | 1 | 1 U slot on the hull: refinery fee −50 % for its ore | 2 600 |
| `u_drones` | II | 1 | repair drone bay: hull regen 2/s in space | 3 000 |"

`15_module_affixes.md` §5:
> "| `w_proton` — proton missile launcher | Choir | Magic+ |
| `w_flak` — flak battery (anti-drone/anti-swarm cone) | Concord | Magic+ |
| `u_vault` — expanded station vault access (14 §4: +20 units all vaults) | Meridian | Magic+ |"
> "Exclusives never spawn Common; their floor is Magic, their ceiling is Rare with the faction suffix."

`08_ship_classes.md` §4:
> "| `ship_interceptor`, `ship_bomber`, `ship_drone_swarm`, `ship_mine_layer`, `ship_turret_platform` | — | enemy-only in v1; class entries may be added later as amendments |"

`18_engine_spec.md` §2.1 ruling 24:
> "24 | **Aliens: all three families.** Swarmer/Sibelon/Apex palettes are sanctioned art (STYLE_BIBLE §2.5); slice 2 ships **human pirates AND alien swarmers** as the first hostiles; Sibelon is slice-3, the Apex boss slice-4."

`06_loot_drops.md` §3.1:
> "| 5 | `cm_chaff` (Chaff Dispenser) | 0.15 | 1 |
| 6 | `cm_flare` (Flare Pack) | 0.15 | 1 |"

`06_loot_drops.md` §7:
> "**Sector-scaled caches:** if the exchange economy needs a combat-income bump after playtest, multiply cache ranges by sector tier (×1 T1–T2, ×1.5 T3, ×2 T4) rather than touching component odds."

**2026-09-27 P3 blocks** (09 §3.1/§7: R-S23-1 proton row, R-S23-2 flak row,
R-S23-3 the seven stock fits; 08 §4: R-S23-4 interceptor, R-S23-5 turret
platform, R-S23-6 the turret reversal) — implement as written (ticks C1–C6
default PROPOSED).

## 6. Acceptance list (numbered; the report answers each with a cite)
- **A1 (R-S23-1/2):** `w_proton` and `w_flak` fire like any family (ammo packs
  buy/load/spend, tracking and the flak cone per the rows, the ×2 vs `swarmer`),
  and 15 §5's exclusivity law is untouched (Choir/Concord-only sale, Magic floor).
- **A2 (dead modules):** `c_ewar` slows enemy targeting 25 % in scan (35 % with
  `c_nexus`), `u_refine` halves the refinery fee for its ore (3:1 unchanged),
  `u_drones` regenerates 2 hull/s in space — each with a measured probe value.
- **A3 (R-S23-3):** all seven hulls carry their stock fit; every hull launches
  playable (mandatory E/P + the row's modules), and the two frozen starter hulls
  keep their existing fits (10 §2).
- **A4 (seams):** `sibelon` spawns and fights (its row is complete: hull, brain,
  loot); the hunter's hull resolves to a real `ship_interceptor` class row;
  `ship_turret_platform` is a real hull row; A5's turret item reports per rule 5.
- **A5 (per-hull identity, L137):** each hull draws its own sprite in flight with
  matching collider radius and FX anchors scaled off the drawn hull's map;
  hunters/pirates fly faction skins (choir/concord/meridian sheets) in their
  bands' flavour; REPAIRS/LAUNCH show `ship_vanguard_damaged` for a damaged
  Vanguard. All assets provenance-clean via `staging/roster/` + `pull.py` +
  `validate_names.py --library` (paste its summary line in the report).
- **A6 (loot):** `uncatalogued_items()` returns empty (`cm_chaff`/`cm_flare`
  rows), `HUNTER_EXTRA` rolls as the `hunter` table, caches scale ×1/×1.5/×2 by
  sector tier (06 §7).
- **A7 (summary):** every new value tabled with its reversal and its tick id;
  no gate row outside §8's list moved; no new art bytes entered the pipeline.

## 7. Worker table
| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| S23-B1 | coder (builder) | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/tests/, vajb-orbit/assets/, staging/roster/, .agents/gen/slices/S23-content-activation/S23-B1_report.md` | A1–A7 + `S23-B1_report.md` |
| S23-R1 | reviewer | `vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S23-content-activation/S23-R1_review.md` | `S23-R1_review.md` + CONTRACTS §9/§10 + LOW rows |
| S23-F1 | fixer (only on HIGH/MED) | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/tests/, vajb-orbit/assets/, staging/roster/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S23-content-activation/` | `S23-F1_report.md` |

## 8. Run order + the tests that move
**B1 → R1 → F1 only on HIGH/MED.** Expected gate growth: **+
`test_s23_content.gd` rows (one per AC)** only. Candidates:

| Suite | Why | Verdict |
|---|---|---|
| `test_s7_weapon_affixes.gd`, `test_s7r1_*` | A1's exclusive families | unchanged (rarity laws untouched) |
| `test_p2a_ship_roster.gd`, `test_ship_grids.gd` | A3's fits + A4's hull rows | unchanged counts (new rows are additive) |
| `test_s5_ammo_cargo.gd`, `test_s8_launch_ammo.gd` | A1's packs | unchanged |
| `test_s6_poi_loot.gd`, `test_engine2_loot.gd` | A6's loot | unchanged (EV drift ≤ the suite's own bound) |
| `test_p1_refinery.gd` | A2's `u_refine` | unchanged (fee halves only with the module fitted) |

Any other count moving is a bucket-2 pause: report it, leave it, stop.

## 9. Hard rules
- Docs read-only (the P3 blocks are landed). `--forbidden` at verify: `docs/`,
  `vajb-orbit/project.godot`, `vajb-orbit/addons/`, `vajb-orbit/autoload/`.
- **No AI art generation.** Asset work = existing cuts only (rule 3); audio not
  needed here. Bounded runs, scratch `XDG_DATA_HOME` (L229), no shell edits.
- Signals up, calls down; preload paths only.

## 10. Staged / deferred
- `u_vault`'s consumer (S26's vaults); hostile bands (S24's R-S24-2); apex and
  the bosses (S26); leviathan/spire/thorn (staged — no design rows);
  `ship_bomber`/`ship_drone_swarm`/`ship_mine_layer` (no sprites ship for them —
  do not invent rows).

## 11. Owner tick list (unticked ⇒ the PROPOSED value ships)
| Tick | Row | PROPOSED |
|---|---|---|
| C1 | R-S23-1 | `w_proton` row as written (09 P3 block) |
| C2 | R-S23-2 | `w_flak` row as written |
| C3 | R-S23-3 | the seven stock fits as written |
| C4 | R-S23-4 | `ship_interceptor` hull row as written |
| C5 | R-S23-5 | `ship_turret_platform` hull row as written |
| C6 | R-S23-6 | ship the station turret (the 13 §5 reversal) |

## 12. Close-out (the orchestrator)
1. Gate twice on fresh scratch stores (identical counts).
2. `python3 staging/verify_wave.py verify --baseline s23_start --forbidden
   vajb-orbit/project.godot docs/ vajb-orbit/addons/ vajb-orbit/autoload/
   --tests --expect-reports .agents/gen/slices/S23-content-activation/S23-B1_report.md
   .agents/gen/slices/S23-content-activation/S23-R1_review.md`
3. `python3 staging/cut/validate_names.py --library` summary recorded in the
   WAVEBOARD one-liner (asset change).
4. WAVEBOARD + `dispatch_coder.md` one-liners; `MASTER_REPORT.md` §6 recap;
   wave-boundary commit.
