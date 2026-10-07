---
slice: S23
reviewer: S23-R1
verdict: blocked (HIGH remains)
gate: "1014 (S22.8's close, WAVEBOARD) → 1030/0 ×2 scratch"
---

# S23-R1 review

Graded against the brief's §5 extract and the 2026-09-27 P3 blocks (09 §7, 08 §4) read
through 18 §4.1's S22.8 cadence amendment and the brief's §0 V1–V5 — never against B1's
report. The landed tree includes the developer's three bucket-2 discharges (the V1 pack
rows + `AMMO_MAX`, the three stock fits on `p_core` per 09 §9's developer amendment, the
03 §4 countermeasure family).

## Acceptance list

- A1 — **drift** — both families fire and spend at their S22.8 cadences (proton 12 s
  stream `test_s23_content.gd:163-185`; flak 4-pellet 12° cone, one round per release
  `:121-158`; buy/load through the profile API `probe_s23_r1` buy line), exclusivity
  intact (Choir/Concord, Magic floor) — but the P3 rows' pinned draws (proton **12**,
  flak **8**) are written nowhere (F1, HIGH).
- A2 — pass — `c_ewar` 0.25 / 0.35 with `c_nexus`, engaged turn ×0.75; `u_refine` 15 →
  7 CR single / 15 double, `ORE_PER_INGOT` 3; `u_drones` +1.0 hull per 0.5 s (suite rows
  + `probe_s23_r1` identical).
- A3 — pass — all nine standard fits legal (`probe_s23_r1` fit lines: the three `p_core`
  kits draw/out **13/13, 12/15, 18/19**; every other row spare ≥ 1); the two starters
  keep their fits (`test_ship_grids.gd` transcription of 09 §9's amended table).
- A4 — pass — sibelon = corvette column, own sprite, `corvette` loot, `HOSTILE_FILL`
  third entry (fill columns sum back to 13's bands, S1 (0,1) … S7 (6,8)); interceptor
  650/350 at 585 u/s; turret platform 2 000/800 at 0; the turret archetype stays
  station-mounted (STAGED, tick C6 open, rule 5).
- A5 — pass — `ship_freighter` 0.0967/44 u and `ship_destroyer` 0.10084/48 u measured in
  flight (texture, collider, `_hull_sprite_scale` all the row's own; Vanguard frozen
  0.0663/30); V3's eight ink widths re-measured off the PNGs **exact** (831/909/946/962/
  910/911/933/952 px); 20/20 wired art paths resolve (the disclosed loader-probe
  substitute; `validate_names --library` cannot run here, B1 deviation 7); pirate/hunter
  wear the space owner's sheet; LAUNCH resolves `ship_vanguard_damaged_side.png`.
- A6 — pass — `uncatalogued_items()` empty; the hunter rolls its promoted table once
  with 06 §8's own grade-cap law (60 seeded rolls: `comp_elec_1` ×40, `comp_elec_2` ×0);
  caches ×1/×1.5/×2 at `sector_tier` S1=1 … S7=4 (the mix's highest grade).
- A7 — **drift** — two moved gate rows are listed nowhere (F3, HIGH bucket 2); B1's
  report arithmetic mis-splits the gate growth (F5, LOW); no art bytes (untracked tree
  clean of new assets; the 20-path probe is read-only).
- A8 — pass — the four `test_s13_devmenu.gd` rows pass: default 1 000, Add/Remove
  through `add_credits(±n)`, the 0 floor (the profile's own `maxi(0, …)`,
  `player_profile.gd:305-312`, probe-verified), the no-profile no-op and the untouched
  boot law (a fresh overlay reads and moves nothing).

## Findings

| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| F1 | HIGH | `game/weapons.gd:196-232` + `tests/test_s23_content.gd:92,102` | The P3 rows' pinned energy draws (R-S23-1 "draw 12", R-S23-2 "draw 8") are quoted in both row comments but keyed into neither family row (`probe_s23_r1`: `draw_key=MISSING` on both); the suite's own A1 row indexes the missing key, aborts at `:92` (`SCRIPT ERROR: Invalid access … 'draw'`, the gate's only script error) and is recorded **PASS**, so A1's flak half, exclusivity half and pack half never execute. A pinned value unlanded and undisclosed. | S23-F1 (write `draw: 12.0` / `draw: 8.0` per the P3 rows) |
| F2 | MED | `tests/test_s23_content.gd:113-116` | The same row's tail still asserts the packs STAGED (`ammo_pack(&"proton").is_empty()`) — stale since the developer's V1 landing (`station_catalog.gd:81-96`, `player_profile.gd:236-238`); unreachable only because F1's abort precedes it. F1's fix must flip these asserts to the V1 values in the same pass or the gate goes red. | S23-F1 |
| F3 | HIGH (bucket 2) | `tests/test_p1_profile.gd:94-101`, `tests/test_d7_armory.gd:385` vs brief §8 | Two moved gate rows are listed nowhere: the `AMMO_MAX` size row 6 → 8 and the armory caption "6 PACKS" → "8 PACKS" — both consequences of the developer's V1 pack landing, named neither in §8's table nor in B1's deviations (the L252 class). The rows are correct as built; the **list** is the artefact — a §8 list amendment, never a revert. | Developer/designer session |
| F4 | LOW | brief §8 vs B1 deviations 4–5 | The disclosed count-flat transcription rows also sit in suites §8 does not list (`test_combat_repair_c5`, `test_flight_feel_g1` — the two borrowed NPC handling rows; `test_engine2_npc`/`_wiring` — the sibelon fill/livery; `test_s4_batteries` — the explicit weaponless fit; `test_p1_catalogues` — 20/7; `test_s19_quadrants`/`test_s17_gate_edges` — the seal re-pins). The L259 class: disclosed, counts flat. | → ticketed L264, not fixed here |
| F5 | LOW | `S23-B1_report.md` §Result | "baseline 1015/0 = 1030 minus 15 new rows (+11 +4)" vs the tree: `test_s23_content.gd` carries **12** `func test_` and the WAVEBOARD's S22.8 close reads **1014/0** — the measured 1030 is right, the report's baseline/row-count split is off by one. | → ticketed L265 |
| F6 | LOW | `npc_registry.gd:183`, `loot_tables.gd:237` | Two seams the wave released leave orphans: `SEAM_SLICE_3` has no reader left (the sibelon row is `SPAWN_SECTOR`/`SEAM_NONE`), and `roll_hunter_extra` is production-orphaned (`game.gd` rolls the promoted table once; only `test_s6_poi_loot` still calls it). | → ticketed L266 |

## Verified fixes

None yet — no fixer has run.

## Gate

- After (this review, fresh scratch stores): `[SUMMARY] passed=1030 failed=0` twice,
  exit 0 both; pass lists identical, the only log diffs are sub-frame timing prints
  (37/38-frame straddles, 1 ms gaps).
- Before: 1014/0 (S22.8's close per the WAVEBOARD; B1's report says 1015 — F5).
- Negative control: the probe `row_of(&"proton")` keys list (`draw` absent) beside the
  suite-alone run — `SCRIPT ERROR … :92` in the log while the harness prints
  `[PASS] test_a1_the_exclusive_families_fire_per_the_p3_rows` — proving the abort is
  silent and the green gate hides it (the L230/L231 class, live again).
