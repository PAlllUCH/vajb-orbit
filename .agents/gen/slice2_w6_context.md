# Slice 2, W6 — reviewer context for this pass (2026-09-21)

You are the mandatory reviewer of engine slice 2. Measure, never trust the
reports: the five worker reports are **claims**, and your job is to falsify them
against the spec and the shipped tree. Read this file alongside the brief
`.agents/gen/slice2_task.md` and `docs/CONTRACTS.md`.

## 1. What is in the tree

| Worker | Shipped | Report |
|---|---|---|
| W1 | `game/weapons.gd` 35 272 B, `game/projectile.gd` 23 243 B, `tests/test_engine2_weapons.gd` (29 tests) | `slice2_w1_report.md` |
| W2 | `game/damage.gd` (new), `game/player_state.gd` (+21 lines: `SHIELD_REGEN_DEFAULT`, `shield_regen`) | `slice2_w2_report.md` |
| W3 | `game/npc_registry.gd`, `game/npc_brain.gd`, `game/npc_ship.gd`, `tests/test_engine2_npc.gd` (28 tests) | `slice2_w3_report.md` |
| W4 | `game/loot_tables.gd`, `tests/test_engine2_loot.gd` (13 tests) | `slice2_w4_report.md` |
| W5 | `ui/hud/hud.gd` → 48 056 B, `game/game.gd` → 55 873 B, `game/sector.gd` → 18 153 B, `game/player_ship.gd` → 36 402 B, `ui/hud/hud.tscn` **unchanged**, `tests/test_engine2_hud.gd` + `tests/test_engine2_wiring.gd` (32 tests) | `slice2_w5_report.md` |
| W0/W0b | the slice-2 record in `IMPLEMENTATION_PLAN.md` §9.9; the per-sector NPC band in `13_heat_bounty.md` §4 | `slice2_w0_report.md`, `slice2_w0b_report.md` |

**The universal gate is GREEN: 200 tests, zero failures, exit 0** (measured by
the orchestrator after W5). Update `CONTRACTS.md` §9 and the changelog with the
real total; the brief's "53" and even slice 0's 78 are stale.

## 2. What to scrutinise hardest

- **The five wiring items W2 flagged and W5 claimed to close**: hull
  `take_damage`, the ram's `ctx`, the `shield_regen` seed, the `Damage.regen`
  frame caller, and whether W1's private delivery seam is now shared or still
  duplicated. Measure each; W5's report §5 names its placements.
- **W2's claim that `damage.gd` routes impulses through `impact.gd`** rather
  than reimplementing §4.2 items 6–8.
- **W1's family table against §4.1/§13** and the Power draw rows: laser 6 E/s,
  plasma 10 E/s, mining 5 E/s, kinetics/rockets/mines 0 (they spend packs), and
  the seeker + countermeasure rules of §4.6 (`CHAFF_WINDOW` 3.0 s / 3 ghosts,
  `FLARE_LURE` 450 u).
- **W4's tables against `06_loot_drops.md`**, including the two countermeasure
  lines at 0.15 and the weight sums.
- **W3's brain thresholds against §13**: aggro radii 900/1 000/750, leash
  2 500, `AGGRO_COOLDOWN` 5.0, pirate flees at 30 % hull, LOS blocked by rock.
- **W5's HUD additions against UI_SPEC §3.1b/§3.3/§3.5/§3.6** and the frozen API.
- **The 2026-09-20 amendments**: power draw, the context pipeline, the swarmer,
  the pools bars, the radial speedometer, the ghost blips.
- **The `hud.tscn` non-change.** W5 left `ui/hud/hud.tscn` byte-identical and
  built the new widgets in code (it inherited that shape from slice 0's M3).
  Rule on whether that is acceptable or a MED, and say which.
- **Invented constants.** Flag any value that traces to no §13 row, doc table or
  spec'd drawing detail.

## 3. Reported gaps you must judge, not assume

W3 reported these as spec holes rather than inventing values: the human/alien
split of the §13 per-sector band (it used a stated fill-order rule), the patrol
count (a proposal), the alien hulls have no doc-08 class row, the station turret
has neither a class row nor a damage figure, NPC armament is unspecified so the
`fire` intent ships unarmed, and there is no stand-off range or turret scan
radius. W4 reported: `06` §3 prose hauls and its §6 check 1 look stale against
06's own tables (numbers in its report), `cm_chaff`/`cm_flare` have no `03` §3
component row so the grade cap is unprovable for those two lines, and a credit
cache has no distinct visual. W1 reported its own deviations; W2 reported the
five wiring items; W5 reports its placements in its §5.

Tier them. A missing spec value that a worker refused to invent is **not** a
defect in the code — it is a spec gap to record. An invented value is a defect.

## 4. Two things that are explicitly NOT code findings

- **The assets re-layout** (graphics lane, mid-flight): any failure that is only
  a missing or moved asset path is environment-deferred. The pending list is
  `.agents/gen/asset_path_fallout.md`.
- **The UI chrome regression** (`.agents/gen/ui_chrome_regression.md`): the
  button plates are whole sheet cells so the theme stretches a mostly
  transparent canvas, the menu wordmark crop is empty, the bezel nine-patch band
  draws 3 px instead of 16. The theme is a forbidden file, the art belongs to
  the graphics lane, and the owner holds the routing decision. Record it as
  open-owner, never as a slice-2 finding.

## 5. Two other lanes have already touched your subject matter

- **batch-2** (playtest lane) changed `ui/hud/hud.gd` before W5: the minimap zoom
  constants were renamed and the two bindings swapped so `+` zooms in. Its
  report is `.agents/gen/batch2_report.md`. Do not score that change as W5's.
- **slice 0's fixes** are in the same files W5 extended (`player_ship.gd`'s
  emergency thrust gate, boost burn, reactor tick, fuel-cell caller). Keep them
  in the pinned set.

## 6. Standing rulings

- `consume_fuel_cell` = **R**; `cargo_toggle` keeps C.
- Refuel and recharge are free; no CR rate may exist anywhere.
- No invented numbers: a missing spec value is reported, never guessed.
- You are the **only** writer of `docs/CONTRACTS.md` in this wave. Update §9 (the
  gate total), the new slice-2 section, and the changelog; record the standing
  rulings there too, or the next wave re-litigates them.
