---
slice: S23
worker: S23-B1
model: "glm-5.3-flash"
status: actionable
gate: "1015/0 → 1030/0 (twice, fresh scratch stores)"
---

# S23-B1 report

## Result
Eight acceptance rows landed; two pieces staged (A1's packs, A3's three
power-illegal fits) and A4's turret item per rule 5 (tick C6 open). Gate
`[SUMMARY] passed=1030 failed=0` twice on fresh scratch stores (baseline 1015/0 =
1030 minus the wave's 15 new rows: +11 `test_s23_content.gd`, +4
`test_s13_devmenu.gd`). Zero art bytes; `docs/`, `autoload/`, `project.godot`
untouched.

## Acceptance list answers
- A1 — families fire: `proton` cooldown 12 s / alpha 220 / homing 2.6 / draw 12;
  `flak` spam 0.55 s / 22-damage 4-pellet 12° cone / ×2 vs swarmer
  (`weapons.gd:187-233`); one round per release. Packs STAGED - Deviation 1.
  Exclusivity untouched (`module_catalog.gd:115-120`).
- A2 — `c_ewar` slows the engaged NPC's turn 25 % / 35 % with `c_nexus` in scan
  (`player_ship.gd:190-206`, `npc_ship.gd:477-549`; measured 0.75 ratio);
  `u_refine` halves the fee (`refinery.gd:36-77`; measured 7 CR single, 15
  double, 3:1 kept); `u_drones` regen 2/s in flight (`player_ship.gd:748-763`;
  measured +1.0 hull/0.5 s).
- A3 — Delver/Courier/Mule/Warden carry their stock fits, the starters keep
  theirs, every hull launches (`ship_fit.gd:572-641`); three rows STAGED -
  Deviation 2.
- A4 — sibelon flies the corvette column, own sprite, `corvette` loot, third
  `HOSTILE_FILL` entry (`npc_registry.gd:89-93,447-483`); interceptor 650/350 at
  585 u/s, turret platform 2000/800 at 0 (`ship_fit.gd:386-412,514-540`); turret
  STAGED per rule 5.
- A5 — every hull draws its own side view at the V3 scale, radius = length/2,
  FX anchors off the drawn sprite (`ship_fit.gd:298-327`, `player_ship.gd:334-374`);
  pirates/hunters wear the owner's fighter sheet (`npc_registry.gd:218-222`);
  LAUNCH swaps the damaged Vanguard (`launch_panel.gd:691-731`).
- A6 — `uncatalogued_items()` empty (`component_catalog.gd:190-221`); the hunter
  rolls its promoted table once (`loot_tables.gd:124-146`, `game.gd:2351-2367`);
  caches ×1/×1.5/×2 by the tier ladder (`sector_registry.gd:211-225`).
- A7 — every value carries its reversal in its row comment; no gate count moved
  outside the two new suites; no art bytes.
- A8 — the F1 CREDITS section: amount field default 1 000, Add/Remove through
  `add_credits(±n)`, balance line, no-op guard, boot law untouched
  (`dev_tuning_menu.gd:23-32,446-596`); 4 rows in `test_s13_devmenu.gd`.

## Deviations from SLICE.md
1. **A1's pack rows STAGED (bucket 2 - file-set pin).** V1's `AMMO_MAX` lives in
   `autoload/player_profile.gd`, outside this worker's set (hook-enforced) and in
   §9's `--forbidden` list; without it `buy_ammo`/`load_ammo_from_hold` refuse.
   Remedy: `&"proton": 60`, `&"flak": 300` in `player_profile.AMMO_MAX:227` plus
   the two pack rows in `station_catalog.AMMO_PACKS:31` (40 r/400 CR rocket
   glyph; 300 r/260 CR cannon glyph), and `test_s5_ammo_cargo.gd:172-181`'s
   six-id transcription to eight (count unchanged) in the same change.
2. **A3's Spearhead/Bulwark/Obliterator rows STAGED (bucket 2 - pinned-number
   conflict).** The tabled fits draw 13/9, 14/11, 18/15 power against 09 §4 rule
   2 (rule 6's own crunch); shipping them writes illegal stock fits. Remedy: the
   developer amends 09 §9 (`p_core` in the three rows, or a trim); the
   transcription and the suite's staged-guards update with it. The Courier's
   tabled second `s_light` overflows its single S cell; the row ships with the
   one the grid holds (08 §3.2: the matrix is the authority); reversal: the
   amendment restores two.
3. **A4's turret item STAGED** per rule 5 (tick C6 open): the row is unchanged,
   no station mounts one.
4. **Three byte-identity seals re-pinned** (the S21/S22 disclosed procedure):
   `npc_ship.gd` + `weapons.gd` (`test_s19_quadrants.gd:94-125`),
   `sector_registry.gd` (`test_s17_gate_edges.gd:47-51`) - A2's EWAR slow, A1's
   families/cone, A6's sector tier are the wave's edits.
5. **Transcription rows re-derived with the landings (counts unchanged):**
   `test_ship_grids.gd:139` (fits), `test_engine2_npc.gd` + `test_engine2_wiring.gd`
   (filler sums, seam list, pirate livery), `test_engine2_loot.gd` (uncatalogued
   empty, hunter is a table, the 06 §8 cap exception), `test_s6_poi_loot.gd`,
   `test_s4_batteries.gd:404` (weaponless fit written explicitly - the Mule ships
   a laser), `test_p1_catalogues.gd` (20 components, 7 families),
   `test_flight_feel_g1.gd` + `test_combat_repair_c5.gd` (borrowed handling rows).
6. **Derived readings (bucket 1, reversible in place):** the flak's volley is one
   round per release; the proton's range borrows the missile kind's 900; both
   exclusives borrow their kind's fire cue; `u_refine`'s fee floors per batch (7
   CR single, 15 double); the countermeasure rows price 0 CR - 06 §3.1's
   re-checked haul counts them in items, not credits - under a seventh
   `countermeasure` family (03 §4's enum needs the developer's amendment); sector
   tier = the mix's highest mineral grade (S1 T1; S2-S3 T2; S4-S5 T3; S6-S7 T4),
   `sector_registry.gd:211-225`.
7. **`validate_names.py --library` could not run on this host:** `cut/`//`raw/`
   are archived away here (`archive.py --restore cut`: no zip at
   `_archive/cut_2026-09-21.zip`) and `staging/cut/_naming/assignments.tsv` is
   absent, so both modes exit before checking. The wired-name proof this host
   can run: a loader probe over all 19 paths the wave wires (9 player side
   views, sibelon/interceptor/turret art, 3 fighter liveries, the damaged
   Vanguard, the two borrowed pack glyphs, the cargo glyph) - 19/19 present -
   plus the suite's `ResourceLoader.exists` rows. Zero bytes changed.

## Evidence
- Both gates: `XDG_DATA_HOME=/tmp/s23_gA|gB $GODOT_CONSOLE --headless --path
  "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200` →
  `[SUMMARY] passed=1030 failed=0` (log line 1278 of each). A2/A6's measured
  values are suite rows (0.75 turn ratio; 7/15 CR; +1.0 hull/0.5 s; 240-500).
- Flake disclosure: pass 3 saw `test_s21_stability`'s boot-purity row fail once
  ("entering the pane rolled the shelf"); the identical tree passed it in passes
  4/A/B - a wall-clock band race in the assertion; the recorded runs are green.

## Files touched
- `game/`: `weapons.gd`, `projectile.gd`, `module_catalog.gd`, `refinery.gd`,
  `player_ship.gd`, `npc_ship.gd`, `ship_fit.gd`, `npc_registry.gd`,
  `loot_tables.gd`, `component_catalog.gd`, `sector_registry.gd`, `game.gd` -
  the deliverables Deviations 1-6 and the acceptance rows cite
- `ui/`: `dev_tuning_menu.gd` (CREDITS section), `launch_panel.gd` (damaged
  Vanguard preview)
- `tests/`: new `test_s23_content.gd`; A8 rows in `test_s13_devmenu.gd`;
  Deviation 5's re-derivations; three seal re-pins

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| A1's pack rows + `AMMO_MAX` (Deviation 1) | code | `player_profile.gd:227`, `station_catalog.gd:31` |
| Amend + land the three power-illegal fits (Deviation 2) | docs+code | 09 §9, `ship_fit.gd:572-641` |
| 03 §4's enum gains `countermeasure` (Deviation 6) | docs | 03 §4 |
| Station turret per tick C6 (Deviation 3) | code | `npc_registry.gd:328` |
