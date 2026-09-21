# P2-A — R1 report: the mandatory review (slot frames, per-class counts, layouts)

**Worker:** R1 (coder — reviewer, mandatory). **Wave:** P2-A ship slot frames.
**Brief (law):** `.agents/gen/p2a_slot_frames_wave_task.md` §3 (the pin) + §4 row R1 + §5 + §6.
**File set (`VAJB_WORKER_FILES`):** `vajb-orbit/tests/`, `vajb-orbit/tools/` — the review's own
probes only (four new files under `tests/`, listed in §12). **No product file was edited, and
nothing was fixed**: every finding below is a report, not a patch.

**Verdict: no HIGH finding. One MED, six LOW. The wave's data is exact.**

| Check the brief ordered | Result |
|---|---|
| 08 §3.2's nine matrices parsed by R1, independently of W1's code, and compared with 08 §3's table cell by cell | **PASS** — 126/126 cells, all nine rows, both directions (§2) |
| The gate re-run, count reported as measured | **PASS** — `passed=370 failed=0`, exit 0 (§3) |
| Shipyard grid cells + columns per hull, HUD cell count per hull, launch brief rows re-measured **from the shipped scenes** | **PASS** — all nine hulls, three scenes (§5) |
| The engine sum and the 1.40 ceiling proved by R1's own probe, and a single engine resolving to the pre-wave figure | **PASS** — A/B against **HEAD's own `ship_fit.gd`** run in-process (§4) |
| A v2 and a v3 profile fixture driven through the new loader: no data loss, no warning | **PASS** — both fixtures, byte-identical on load, complete on write (§6) |
| Every pinned signature of CONTRACTS §2/§3/§7/§11 grepped across the changed files | **PASS** — 20 + 2 + 15 + 33 signatures, each declared exactly once (§7) |
| No matrix tidied; no number moved outside 08 §3's marked rows; the legacy singular `engine` key still resolves; NPC hulls read empty shapes with no warning; `assets/**`, the theme, `project.godot` and `docs/**` untouched by code workers | **PASS** — all five, with the raw diffs (§8) |

---

## 1. What I measured, and where the raw output is

| Evidence | File |
|---|---|
| The gate (R1's own run) | `.agents/gen/p2a_r1_gate.txt` |
| R1's independent matrix parse + document-vs-code comparison | `.agents/gen/p2a_r1_matrices.txt` |
| R1's frames probe (matrices, engine A/B, NPC shapes, three scenes, roster) | `.agents/gen/p2a_r1_probe_frames.txt` |
| R1's migration probe (v2 and v3 fixtures) | `.agents/gen/p2a_r1_probe_migration.txt` |
| The gate's `--debug` warning ledger | `.agents/gen/p2a_r1_lint_ledger.txt` |
| W4's launch probe, re-run by R1 unchanged | `.agents/gen/p2a_r1_w4_probe_rerun.txt` |

Re-runnable commands (Linux host; `godot` = 4.7.2-stable):

```text
godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
godot --headless --path vajb-orbit res://tests/probe_r1_frames.tscn --quit-after 600
godot --headless --path vajb-orbit --script res://tests/probe_r1_migration.gd
godot --headless --debug --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
python3 /tmp/r1_matrices.py ; python3 /tmp/r1_codegrids.py      # both scripts in p2a_r1_matrices.txt
```

`tests/probe_r1_prewave_fit.gd` is HEAD's `game/ship_fit.gd` **byte for byte minus its
`class_name` line** (verified with `diff`), so §4's A/B runs the real pre-wave code path
rather than a re-implementation of it.

---

## 2. The nine matrices, re-derived independently (the brief's first order)

Two independent passes, neither of which reads W1's code or W1's suite:

1. **Document → table.** `python3 /tmp/r1_matrices.py` parses 08 §3.2's fenced block itself
   (the `Class (cols x rows)` headers, then the rows with the cosmetic spaces removed),
   counts each letter, and compares the result with 08 §3's markdown table, read from its
   own header row (the `△` marks stripped) — cell by cell **and** against each block
   header's own `E1 P1 W2 … = 8` line:

```text
class     ship       grid     E  P  W  S  H  C  B  U  sum table-total  declared  match
Fighter   Lancer     4x3       1  1  2  1  1  1  1  0    8           8      True  True
Cutter    Vanguard   4x4       1  1  3  1  2  1  1  1   11          11      True  True
Miner     Delver     4x4       2  1  2  1  2  1  0  3   12          12      True  True
Trader    Courier    4x4       2  1  1  1  2  2  1  3   13          13      True  True
Corvette  Spearhead  4x4       1  1  4  2  2  1  1  1   13          13      True  True
Hauler    Mule       4x5       3  1  1  1  3  1  0  5   15          15      True  True
Gunship   Bulwark    4x5       2  1  5  2  2  1  0  1   14          14      True  True
Frigate   Warden     4x5       2  1  4  2  3  2  1  2   17          17      True  True
Destroyer Obliterator 5x6      3  1  7  3  4  2  1  2   23          23      True  True
ALL MATRIX/TABLE AGREEMENT: True
```

2. **Document → code.** `python3 /tmp/r1_codegrids.py` compares 08 §3.2's rows with the
   `SLOT_GRIDS` literal in `game/ship_fit.gd` (parsed out of the source text, not through
   `ShipFit`):

```text
ship_fighter     doc=['.WW.', 'HSCB', '.EP.'] code=['.WW.', 'HSCB', '.EP.'] same=True
ship_vanguard    doc=['.WW.', 'HSCB', 'HWU.', '.EP.'] code=[...] same=True
ship_miner       doc=['W..W', 'CHHS', 'UUU.', 'EEP.'] same=True
ship_trader      doc=['.W..', 'SCCH', 'HUUU', 'EEBP'] same=True
ship_corvette    doc=['.WW.', 'HSSH', 'WCBW', '.EPU'] same=True
ship_freighter   doc=['.W..', 'HHHS', 'UUUU', 'CU..', 'EEEP'] same=True
ship_gunship     doc=['WWWW', '.SS.', 'HCH.', 'WU..', 'EEP.'] same=True
ship_patrol      doc=['.WW.', 'HSSH', 'CWWC', 'HBUU', '.EEP'] same=True
ship_destroyer   doc=['.WWW.', 'HSSSH', 'CWCW.', 'H.BH.', 'WWUU.', 'EEEP.'] same=True
unknown keys in code: set()
ALL ROWS IDENTICAL: True
```

3. **The live API, not the literal.** `probe_r1_frames.tscn` §1 compares `grid_size` /
   `grid_cells` / `grid_counts` against R1's own transcribed table (a third copy, written by
   hand from the document before the probe ran), asserts `grid_cells.size() == cols × rows`,
   asserts the row-major `col`/`row` of every cell, and asserts
   `HULLS[hull].weapons == grid_counts(hull)[weapons]` for all nine (rule 5):

```text
[r1] ok   ship_fighter     grid=(4, 3) counts=[1, 1, 2, 1, 1, 1, 1, 0] total=8 | doc ... total=8 HULLS.weapons=2
...
[r1] ok   ship_destroyer   grid=(5, 6) counts=[3, 1, 7, 3, 4, 2, 1, 2] total=23 | doc ... total=23 HULLS.weapons=7
[r1] nine-hull total sum = 126 (doc 8+11+12+13+13+15+14+17+23 = 126)
```

**No matrix was tidied.** Every row of every hull is the document's row with the spaces
removed; `SLOT_GRIDS` carries exactly the nine player hull keys and no other; every letter
used is one of the eight in `SLOT_TOKEN_KEYS` plus `.` (an unmapped letter would have made
the parse fail).

**The engine counts are derivable, not chosen** (owner tick 1): 18 §13's `hull_mass` column
reads Fighter 80 · Cutter 110 · Miner 140 · Trader 160 · Corvette 90 · Hauler 260 · Gunship
190 · Frigate 220 · Destroyer 300; 08 §3.1's bands (≤110 → 1, 140–220 → 2, ≥260 → 3) map
onto them with no hull in a gap, and the derived E counts are exactly 1/1/2/2/1/3/2/2/3.

---

## 3. The gate, as R1 measured it

```text
$ godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=370 failed=0
EXIT=0
```

`grep -c '^\[PASS\]'` = **370**, `grep -c '^\[FAIL\]'` = **0**, 30 suites. The wave's five
suites, counted off the log rather than carried forward: `test_ship_grids` **27**,
`test_p2a_profile_fits` **11**, `test_p2a_launch_fit` **12**, `test_p2a_ship_roster` **4**,
and `test_ui_slot_layout` **12** (7 before → +5). D0 measured the pre-wave baseline at
**311**; 311 + 27 + 11 + 12 + 4 + 5 = **370** exactly, so the count grew and nothing was
deleted, disabled or hidden.

The log carries **exactly one** `SCRIPT ERROR`, and it is the pre-existing
`Cannot call method 'call' on a previously freed instance.` at `tests/test_weapon_fx_f4.gd:176`
(CONTRACTS §9 / LOW_BACKLOG **L61**): the file is unmodified by the wave
(`git status --short vajb-orbit/tests/test_weapon_fx_f4.gd` is empty) and the test passes.
No new `SCRIPT ERROR`, and no `unknown hull id` error anywhere in the log
(`grep -c "unknown hull id"` = 0).

---

## 4. The engine arithmetic, A/B against the real pre-wave code

`probe_r1_frames.tscn` §2 loads `tests/probe_r1_prewave_fit.gd` (HEAD's file, `class_name`
dropped) and `game/ship_fit.gd` into one process and compares them.

**The pre-wave product vs the shipped sum**, measured on the one-, two- and three-cell hulls
(Fighter / Delver / Mule), against a multiplier R1 recomputes from `ModuleCatalog`'s own
effect rows rather than from the resolver:

```text
[r1] ship_freighter base speed=293.0000 turn=0.7500 (engine cells=3)
[r1] ok  [&"e_std"]                             x1.0000 turn x1.0000 legal=false | expected sum=1.0000 clamped=1.0000 turn=1.0000
[r1] ok  [&"e_ion"]                             x1.1500 turn x1.0000 legal=false | expected sum=1.1500 clamped=1.1500 turn=1.0000
[r1] ok  [&"e_vector"]                          x1.2500 turn x1.2000 legal=false | expected sum=1.2500 clamped=1.2500 turn=1.2000
[r1] ok  [&"e_std", &"e_ion", &"e_vector"]      x1.4000 turn x1.2000 legal=true  | expected sum=1.4000 clamped=1.4000 turn=1.2000
[r1] ok  [&"e_ion", &"e_ion"]                   x1.3000 turn x1.0000 legal=false | expected sum=1.3000 clamped=1.3000 turn=1.0000
[r1] ok  [&"e_vector", &"e_vector"]             x1.4000 turn x1.4000 legal=false | expected sum=1.5000 clamped=1.4000 turn=1.4000
[r1] ok  [&"e_vector", &"e_vector", &"e_vector"] x1.4000 turn x1.6000 legal=false | expected sum=1.7500 clamped=1.4000 turn=1.6000
```

`ENGINE_MULT_CEILING` = 1.40, `MOUNT_SPREAD` = (0.34, 0.22); the ceiling bites the **speed**
multiplier only (three vectors: speed 1.4000, turn 1.6000) and every legal set's resolved
figure equals R1's own recomputation. `e_vector`+`e_vector` is refused (`legal=false`) while
`e_std`+`e_std` is accepted (09 §3.7's by-hand exception) — both measured, on all three hulls.

**A single engine resolves to the pre-wave figure, field by field.** HEAD's own `resolve` and
the shipped `resolve`, on all nine hulls, with one `e_std` + `p_std`, compared over 19 float
fields plus `boosters`:

```text
[r1] ok   ship_fighter     pre speed=450.0000 turn=1.7000 | shipped speed=450.0000 turn=1.7000 | all ShipStats fields identical
[r1] ok   ship_vanguard    pre speed=428.0000 turn=1.5000 | shipped speed=428.0000 turn=1.5000 | ...
[r1] ok   ship_miner       pre speed=338.0000 turn=1.0000 | ...
[r1] ok   ship_trader      pre speed=383.0000 turn=1.2000 | ...
[r1] ok   ship_corvette    pre speed=495.0000 turn=1.6000 | ...
[r1] ok   ship_freighter   pre speed=293.0000 turn=0.7500 | ...
[r1] ok   ship_gunship     pre speed=360.0000 turn=0.9500 | ...
[r1] ok   ship_patrol      pre speed=383.0000 turn=1.0500 | ...
[r1] ok   ship_destroyer   pre speed=315.0000 turn=0.8000 | ...
```

The same test through HEAD's own `STANDARD_FIT` row (which spells the engine key `engine`),
through the shipped code with that legacy row, and through the shipped canonical
`standard_fit(&"ship_vanguard")`:

```text
[r1] ok   pre-wave STANDARD_FIT: HEAD 406.6000/1.5000, shipped via legacy key 406.6000/1.5000, shipped canonical 406.6000/1.5000
[r1] ok   both keys present: engines wins (492.2000 == e_ion-only 492.2000)
[r1] ok   legacy engine as Array resolves (492.2000 == 492.2000)
```

**The legacy singular `engine` key still resolves** — as a `StringName` (the HEAD row above)
and as an `Array` — and `engines` wins when both are present, including an empty `engines`
(presence decides, not length). Every existing fixture that still spells the singular key
(`tests/test_engine2_damage.gd:327`, `tests/test_engine2_pools.gd:82`) resolves through it in
the green gate.

**The nine standard fits are legal on their own hulls** (09 §9 + 09 §4), measured by R1:

```text
[r1] ok   standard_fit(ship_fighter    ) is legal (power 4/6)
[r1] ok   standard_fit(ship_vanguard   ) is legal (power 3/8)
[r1] ok   standard_fit(ship_miner/trader/corvette/freighter/gunship/patrol/destroyer) is legal (power 0/N)
```

---

## 5. The consumers, re-measured from the shipped scenes (not from the reports)

`probe_r1_frames.tscn` instantiates the **shipped** `ui/station/shipyard_panel.tscn`,
`ui/station/launch_panel.tscn` and `ui/hud/hud.tscn` and drives their own builders.

**SHIPYARD** — `%HardpointSlots` is a `GridContainer` in the scene; R1 calls the panel's own
`_set_layout_grid(hull)` for all nine hulls and reads the scene back:

```text
[r1] ok   ship_fighter     children=12 plates=8  gaps=4 columns=4 caption='SLOT LAYOUT · 8 CELLS · 1 ENGINES'
[r1] ok   ship_vanguard    children=16 plates=11 gaps=5 columns=4 caption='SLOT LAYOUT · 11 CELLS · 1 ENGINES'
[r1] ok   ship_miner       children=16 plates=12 gaps=4 columns=4 caption='SLOT LAYOUT · 12 CELLS · 2 ENGINES'
[r1] ok   ship_trader      children=16 plates=13 gaps=3 columns=4 caption='SLOT LAYOUT · 13 CELLS · 2 ENGINES'
[r1] ok   ship_corvette    children=16 plates=13 gaps=3 columns=4 caption='SLOT LAYOUT · 13 CELLS · 1 ENGINES'
[r1] ok   ship_freighter   children=20 plates=15 gaps=5 columns=4 caption='SLOT LAYOUT · 15 CELLS · 3 ENGINES'
[r1] ok   ship_gunship     children=20 plates=14 gaps=6 columns=4 caption='SLOT LAYOUT · 14 CELLS · 2 ENGINES'
[r1] ok   ship_patrol      children=20 plates=17 gaps=3 columns=4 caption='SLOT LAYOUT · 17 CELLS · 2 ENGINES'
[r1] ok   ship_destroyer   children=30 plates=23 gaps=7 columns=5 caption='SLOT LAYOUT · 23 CELLS · 3 ENGINES'
```

Every row's `plates` is 08 §3's Total, `gaps == cells − plates`, `columns` is the matrix
width, every plate and every gap is exactly 48 px, every plate sets `ignore_texture_size`,
and the caption reads the same hull's counts. The five stat rows, driven per hull through the
panel's own `_selected_id` + `_refresh_preview`:

```text
[r1] stat row keys: ["hull", "shield", "cargo", "engines", "slots"]
[r1] ok   ship_fighter     SELECTED stat column = ["700", "400", "25", "1", "8"]
[r1] ok   ship_vanguard    SELECTED stat column = ["1000", "600", "40", "1", "11"]
[r1] ok   ship_miner       SELECTED stat column = ["1100", "500", "55", "2", "12"]
[r1] ok   ship_trader      SELECTED stat column = ["950", "550", "60", "2", "13"]
[r1] ok   ship_corvette    SELECTED stat column = ["1300", "700", "35", "1", "13"]
[r1] ok   ship_freighter   SELECTED stat column = ["1600", "500", "120", "3", "15"]
[r1] ok   ship_gunship     SELECTED stat column = ["1400", "650", "50", "2", "14"]
[r1] ok   ship_patrol      SELECTED stat column = ["1800", "800", "60", "2", "17"]
[r1] ok   ship_destroyer   SELECTED stat column = ["2200", "900", "80", "3", "23"]
[r1] ok   nine list rows carry a '%d HULL · %d SLOTS' meta
     ["700 HULL · 8 SLOTS", "1000 HULL · 11 SLOTS", "1100 HULL · 12 SLOTS", "950 HULL · 13 SLOTS",
      "1300 HULL · 13 SLOTS", "1600 HULL · 15 SLOTS", "1400 HULL · 14 SLOTS", "1800 HULL · 17 SLOTS",
      "2200 HULL · 23 SLOTS"]
```

**LAUNCH** — the nine `BRIEF_ROWS` in the pin's order, per hull, with the active ship borrowed
in memory and handed straight back (the probe never writes `user://profile.cfg`):

```text
[r1] ok   ship_fighter     rows=9 ENGINES=1 SLOT CELLS=8  HARDPOINTS=2 | order=["DESTINATION","ACTIVE HULL","HULL LIMIT","SHIELD LIMIT","ENGINES","HARDPOINTS","SLOT CELLS","CARGO","AMMUNITION"]
[r1] ok   ship_vanguard    rows=9 ENGINES=1 SLOT CELLS=11 HARDPOINTS=3
[r1] ok   ship_miner       rows=9 ENGINES=2 SLOT CELLS=12 HARDPOINTS=2
[r1] ok   ship_trader      rows=9 ENGINES=2 SLOT CELLS=13 HARDPOINTS=1
[r1] ok   ship_corvette    rows=9 ENGINES=1 SLOT CELLS=13 HARDPOINTS=4
[r1] ok   ship_freighter   rows=9 ENGINES=3 SLOT CELLS=15 HARDPOINTS=1
[r1] ok   ship_gunship     rows=9 ENGINES=2 SLOT CELLS=14 HARDPOINTS=5
[r1] ok   ship_patrol      rows=9 ENGINES=2 SLOT CELLS=17 HARDPOINTS=4
[r1] ok   ship_destroyer   rows=9 ENGINES=3 SLOT CELLS=23 HARDPOINTS=7
[r1] ok   the cargo strip is still five 40 px plates | children=5
```

**HUD** — one entry per W cell pushed, built by R1 from `ShipFit.grid_cells` + the standard
fit + `ModuleCatalog.icon_path` (the same shape `game.gd` sends), read back off the scene:

```text
[r1] ok   ship_fighter     pushed=2 drawn=2 columns=2 disabled=0 (W cells=2)
[r1] ok   ship_vanguard    pushed=3 drawn=3 columns=3 disabled=0 (W cells=3)
[r1] ok   ship_miner       pushed=2 drawn=2 columns=2 disabled=0 (W cells=2)
[r1] ok   ship_trader      pushed=1 drawn=1 columns=1 disabled=0 (W cells=1)
[r1] ok   ship_corvette    pushed=4 drawn=4 columns=4 disabled=0 (W cells=4)
[r1] ok   ship_freighter   pushed=1 drawn=1 columns=1 disabled=0 (W cells=1)
[r1] ok   ship_gunship     pushed=5 drawn=5 columns=5 disabled=0 (W cells=5)
[r1] ok   ship_patrol      pushed=4 drawn=4 columns=4 disabled=0 (W cells=4)
[r1] ok   ship_destroyer   pushed=7 drawn=7 columns=5 disabled=2 (W cells=7)
[r1] ok   an empty push keeps a valid grid (columns=1, children=0)
```

The capital's 7 cells wrap at `GROUPS_MAX` (5, read from `weapons.gd:134`) with cells 5–6
drawn but disabled; every cell is 48 px with `ignore_texture_size`; `hull_slots()` reads the
push back. **W4's payload and W5's consumer agree key for key** — the pairing W5 flagged for
R1 is verified: `{slot, index, module, icon, fitted, selectable}`, one entry per W cell of
`ShipFit.grid_cells`, `icon` from `ModuleCatalog.icon_path`, `selectable` from
`index < GROUPS_MAX` (`game.gd:1404`).

**The roster** (W3) — nine rows in 08 §2's ladder order, with that table's frozen columns,
`preview` = the hull's own side render and the file on disk, and
`hardpoints == ShipFit.grid_counts(hull)[weapons]`:

```text
[r1] ok   roster[0] ship_fighter   cost=9000  hull=700  shield=400 cargo=25  hardpoints=2
[r1] ok   roster[1] ship_vanguard  cost=18000 hull=1000 shield=600 cargo=40  hardpoints=3
[r1] ok   roster[2] ship_miner     cost=16000 hull=1100 shield=500 cargo=55  hardpoints=2
[r1] ok   roster[3] ship_trader    cost=21000 hull=950  shield=550 cargo=60  hardpoints=1
[r1] ok   roster[4] ship_corvette  cost=27000 hull=1300 shield=700 cargo=35  hardpoints=4
[r1] ok   roster[5] ship_freighter cost=24000 hull=1600 shield=500 cargo=120 hardpoints=1
[r1] ok   roster[6] ship_gunship   cost=36000 hull=1400 shield=650 cargo=50  hardpoints=5
[r1] ok   roster[7] ship_patrol    cost=54000 hull=1800 shield=800 cargo=60  hardpoints=4
[r1] ok   roster[8] ship_destroyer cost=72000 hull=2200 shield=900 cargo=80  hardpoints=7
[r1] ok   mount_offset is the 09 section 8 formula for every non-gap cell of every hull
```

`git diff vajb-orbit/game/station_catalog.gd` removes exactly two lines —
`&"hardpoints": 3,` (the Lancer) and `&"hardpoints": 4,` (the Vanguard) — so the Bulwark's 5
and the Obliterator's 7 are untouched and **no existing description moved**.

---

## 6. The profile's v2 and v3 fixtures through the new loader

`probe_r1_migration.gd` (throwaway `PlayerProfile` instances only, never the autoload, no
instance in the tree, every scratch file removed — L17). `SAVE_VERSION` = 4,
`MIN_READABLE_VERSION` = 1.

**v2 fixture** (single strings per slot type, the legacy singular `engine` key, two hulls —
one of them a three-engine hull):

```text
[r1m] on disk: { "save_version": 2, ..., "fits": { "ship_freighter": { "engine": "e_ion", "power": "p_std" },
                                                   "ship_vanguard": { "armour": "h_plate_light", "engine": "e_std", "power": "p_std",
                                                                      "shields": "s_light", "weapons": "w_laser" } } }
[r1m] ok   the load rewrites nothing (byte-identical snapshot)
[r1m] ok   fit_for(vanguard) normalises to capacity, one element padded
           { &"engines": ["e_std"], &"weapons": ["w_laser", "", ""], &"shields": ["s_light"], &"armour": ["h_plate_light", ""],
             &"computers": [""], &"boosters": [""], &"utility": [""], &"power": "p_std" }
[r1m] ok   fit_for(freighter) pads engines to three cells with the v2 value at index 0
[r1m] ok   every other v2 value survives the load | credits=4321 active=ship_freighter cargo={ &"ore_iron": 7 } ammo=111
[r1m] ok   set_fit_slot(engines, 0) returns true
[r1m] ok   the write persists save_version 4
[r1m] ok   the written vanguard row is the array shape with the engine cell changed and nothing dropped
           { "armour": ["h_plate_light", ""], "boosters": [""], "computers": [""], "engines": ["e_ion"], "power": "p_std",
             "shields": ["s_light"], "utility": [""], "weapons": ["w_laser", "", ""] }
[r1m] ok   the untouched second hull keeps its v2 value (shape: e_ion)
[r1m] ok   the untouched hull still resolves to e_ion through fit_for after the write
[r1m] ok   every v2 key is carried over unchanged (no data loss)
[r1m] ok   a fresh reload reads the write back cell for cell
```

**v3 fixture** (credits, two owned ships, cargo, ammo, an inventory instance, `insured`, the
`vitals` fuel key, and single-string fits):

```text
[r1m] ok   the v3 load rewrites nothing (byte-identical snapshot)
[r1m] ok   every v3 value survives the load | credits=9876 active=ship_miner cargo={ &"ore_gold": 1, &"ore_iron": 3 } ammo=250 insured=true vitals={ "hull": 900, "shield": 400, "fuel": 133 }
[r1m] ok   base_module_id resolves the stored instance (mod_0007 -> s_heavy)
[r1m] ok   fit_for(miner) normalises to the Delver's capacity (E2 W2 S1 H2 C1 B0 U3 P1)
           { &"engines": ["e_std", ""], ..., &"boosters": [], &"utility": ["u_refine", "", ""], &"power": "p_std" }
[r1m] ok   the v3 write persists save_version 4
[r1m] ok   the written miner row carries the v3 values over and adds the second engine
[r1m] ok   the v3 non-fit keys are all carried over (fuel, modules, insured, cargo, ammo)
[r1m] ok   a fresh reload reads the v3 write back cell for cell
[r1m] note: ammo after the write = { "cannon": 40, "laser": 250, "mine": 300, "plasma": 300, "rocket": 300 }
[r1m] DONE fails=0
```

**No data loss, and no warning.** `WARNING:` lines between the probe's own
`MARK warnings-between-start/end` markers: **zero**, in both sections. (The five families'
ammo defaulting on load and the full key set on write are **pre-existing** save semantics:
`git show HEAD:vajb-orbit/autoload/player_profile.gd` carries the identical
`for weapon: StringName in AMMO_MAX: if not _ammo.has(weapon): _ammo[weapon] = DEFAULT_AMMO`
and the identical 17 `set_value` calls.)

---

## 7. The pinned signatures, grepped (CONTRACTS §2/§3/§7/§11)

Each pin was grepped as a literal string in the file the pin places it in; every one is
present exactly once, and a project-wide search shows **no pinned method is declared twice**:

```text
### §2 ShipStats (game/ship_stats.gd) — 20/20 fields, typed and ordered as pinned
1  ship_stats.gd  var max_speed: float        … (all 20, incl. hull_mass, energy_max, energy_regen, fuel_max, boosters)
### §3 ShipFit
1  ship_fit.gd    static func resolve(hull_id: StringName, fit: Dictionary) -> ShipStats
   ship_fit.gd    const STANDARD_FIT
### §7 HUD — 15/15 (frozen set_target/clear_target, the four slice-0/2 additions and all six read-backs)
1  hud.gd  func set_prompt(text: String) -> void / set_warp_channel / set_pool / set_emergency
1  hud.gd  func set_lock_progress(progress: float) -> void / set_speedometer(ratio, prograde, heading) / hit_marker()
1  hud.gd  func lock_progress() / speedometer_ratio() / lock_ring() / speedometer() / hit_marker_node() / target_info()
### §11 ShipFit — 15/15 consts + statics
1  ship_fit.gd  const SLOT_GRIDS / SLOT_TOKEN_KEYS / FIT_SLOT_KEYS / MANDATORY_SLOT_KEYS
1  ship_fit.gd  const ENGINE_MULT_CEILING := 1.40 / MOUNT_SPREAD := Vector2(0.34, 0.22) / STANDARD_FITS
1  ship_fit.gd  static func grid_rows / grid_size / grid_cells / grid_counts / slot_capacity / fit_legal / standard_fit / mount_offset
### §11 ModuleCatalog — 5/5
1  module_catalog.gd  const MODULES: Dictionary / static func module / icon_path / slot_of
                      (class_name ModuleCatalog + extends RefCounted on two lines, the GDScript form of the pin's one line)
### §11 PlayerProfile — 8/8
1  player_profile.gd  func fit_for / set_fit / set_fit_slot / clear_fit / base_module_id / module_count / add_module / take_module
### §11 PlayerState — 2/2 (+ const WEAPONS kept)
1  player_state.gd  var weapons: Array[StringName] / func set_weapons(ids: Array[StringName]) -> void
### §11 HUD / SlotButton — 3/3
1  hud.gd  func set_hull_slots(hull_id: StringName, cells: Array) -> void / func hull_slots() -> Array
1  slot_button.gd  func configure_cell(          (configure( untouched, 18 lines added, 0 deleted)
```

Project-wide duplicate check (`rg -c` over `vajb-orbit/`, review probes excluded): the 23
pinned methods live in exactly five files — `player_profile.gd` 8, `ship_fit.gd` 8,
`hud.gd` 2, `player_state.gd` 1, `slot_button.gd` 1, `module_catalog.gd` 3 — and nowhere else.
`SINGLE_SLOT_KEYS` is published but **unread** anywhere in the shipped tree (its only readers
are HEAD's copy in R1's pre-wave fixture and the pre-wave file itself), so no consumer still
walks the singular engine list.

---

## 8. The five explicit guards

1. **No matrix was tidied** — §2 above: document rows == `SLOT_GRIDS` rows, hull by hull, row
   by row, `unknown keys in code: set()`.

2. **No number moved outside 08 §3's marked rows.** `git diff -U6 vajb-orbit/game/ship_fit.gd`
   over the `HULLS` table moves exactly three values, all `weapons`:
   `ship_fighter` 3 → **2**, `ship_vanguard` 4 → **3**, `ship_corvette` 3 → **4** (08 §2/§3's
   △ rows, owner tick 1). No other `HULLS` field moved; `HANDLING` appears in the diff only as
   hunk context (`@@ -241,166 +325,58 @@ const HANDLING: Dictionary = {`) and not one of its
   numbers is added or removed. `station_catalog.gd`'s diff removes exactly the Lancer's and
   the Vanguard's `hardpoints`. Every numeric literal the wave adds elsewhere is a pinned
   constant (`1.40`, `0.34`, `0.22`), a doc reference, a shipped plate size (48/40), a frozen
   price from 08 §2, or a test's own 4096 px art probe — checked by listing every added
   numeric literal across the changed files and classifying each.

3. **The legacy singular `engine` key still resolves** — §4: HEAD's own `STANDARD_FIT` row
   resolves to the identical 19-field snapshot through the shipped resolver, and the same key
   as an `Array` resolves too; `engines` wins when both are present.

4. **NPC hulls read empty shapes with no warning.** All ten ids in CONTRACTS §11 rule 6
   measured by R1: `grid_rows`/`grid_cells` empty, `grid_size` ZERO, `grid_counts` the eight
   keys at 0, `slot_capacity` 0, `standard_fit` `{}`, `mount_offset` ZERO, `fit_legal` legal
   false — and the gate's `--debug` ledger attributes **no warning** to `ship_fit.gd`
   (`grep -c` over the ledger = 0). A bogus id pushes its one pre-existing error and returns
   `null`, which the probe asserts deliberately.

5. **`assets/**`, the theme, `project.godot`, `addons/**` and `docs/**` untouched by code
   workers.**

```text
$ git status --porcelain | grep -E "assets/|vajb_theme|build_theme|project\.godot|addons/"
NONE
$ git diff --name-only
.agents/gen/WAVEBOARD.md   .agents/gen/dispatch_designer.md          # the designer lane's, modified before this wave
docs/CONTRACTS.md  docs/design/IMPLEMENTATION_PLAN.md  docs/design/STATION_HUB.md
docs/design/STATION_SPEC.md  docs/gameplay/17_coder_handoff.md        # D0's five files, all in its declared set
vajb-orbit/autoload/player_profile.gd  vajb-orbit/game/game.gd  vajb-orbit/game/player_ship.gd
vajb-orbit/game/player_state.gd  vajb-orbit/game/ship_fit.gd  vajb-orbit/game/station_catalog.gd
vajb-orbit/tests/test_engine2_wiring.gd  vajb-orbit/tests/test_p1_profile.gd
vajb-orbit/tests/test_ui_slot_layout.gd
vajb-orbit/ui/components/slot_button.gd  vajb-orbit/ui/hud/hud.gd
vajb-orbit/ui/station/launch_panel.gd  vajb-orbit/ui/station/shipyard_panel.gd
vajb-orbit/ui/station/shipyard_panel.tscn
```

`docs/gameplay/08_ship_classes.md` and `docs/gameplay/09_ship_slots_modules.md` are
**unmodified since HEAD** (they were committed earlier, by `09d4ca5`), so 08 §3.2's block the
code parses is the pre-wave, owner-approved document — the code cannot have moved a matrix to
suit itself. `docs/gameplay/18_engine_spec.md` (owner-locked) is untouched.

**Order of the pin**: `docs/CONTRACTS.md`'s mtime is 22:38:18 and the earliest code write in
the wave is `game/station_catalog.gd` at 22:41:02, so D0's §11 landed before the first code
worker wrote a byte.

**D0's docs, spot-checked** (not this review's main order, but cheap): §11's body is
**byte-identical** to the brief's §3 body —

```text
$ python3 - <<'PY' … PY
verbatim: True      (heading line 837, body 842–1018, 177 lines)
```

— `docs/design/IMPLEMENTATION_PLAN.md` carries §9.10, `docs/design/STATION_SPEC.md` §4.2
carries the nine-hull ladder, `docs/gameplay/17_coder_handoff.md` §2/§3 carry the new file and
the array `fits` shape, `docs/CONTRACTS.md` §10 carries the v0.2 entry, and STATION_HUB's
seven-plate references are all rewritten or explicitly marked superseded with reversal paths.

---

## 9. The tests that moved

| Test | §5's sanction | R1's finding |
|---|---|---|
| `tests/test_ui_slot_layout.gd` (7 → 12) | sanctioned | The literal 7 is gone; the grid, the caption, the stat rows, the metas and the HUD count all read `ShipFit`/`weapons.gd`; the three D3 guard properties (`ignore_texture_size` at every plate site, 48 px weapon / 40 px cargo cells, a 4096 px plate cannot grow a panel or the grid) are intact and swept over more sites than before. |
| `tests/test_p1_profile.gd:204` | sanctioned | Exactly the version digit 3 → 4, one line, nothing else in the diff. |
| `tests/test_engine2_wiring.gd:260-269` | **not named in §5** | W4's deviation 1. Its loop read `_state.WEAPONS` (5) while indexing `_state.ammo`, which is now sized to the launched fit, so it produced a hard `SCRIPT ERROR: Invalid access of index '2' on a base object of type: 'Array[int]'` on every hull with fewer than five guns. The replacement reads `_state.weapons` and **adds** `assert_eq(_state.ammo.size(), _state.weapons.size())`, so the loop cannot pass vacuously. Not a hidden failure — a required adaptation that strengthens the test — but the wave's §5 list and §9.10 should name it. **LOW (R1-L3)**. |

---

## 10. Findings by tier

### HIGH — none

Nothing blocks the wave. The data is exact against 08 §3, the gate is green and grew by the
wave's own 59 tests, the consumers agree with the producers, the migration loses nothing, and
the engine arithmetic is a strict superset of the pre-wave behaviour.

### MED — one, one fixer pass

**R1-M1 — a new warning in a wave-owned file.** `tests/test_p2a_ship_roster.gd:10` declares
`const ShipFit := preload("res://game/ship_fit.gd")`, which shadows the project's global
`class_name ShipFit`. It is the **only** P2-A-attributed row in the gate's 43-row `--debug`
warning ledger (the other 42 belong to pre-existing files: `tests/test_engine2_cleaving.gd`
8, `game/speed_fantasy.gd` 7, `game/npc_ship.gd` 4, `game/npc_brain.gd` 4, and so on).

```text
$ godot --headless --debug --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
WARNING: The constant "ShipFit" has the same name as a global class defined in "ship_fit.gd".
     at: GDScript::reload (res://tests/test_p2a_ship_roster.gd:10)
```

Repro (one command): the `--debug` gate above, then
`grep -A1 "^WARNING" /tmp/r1_gate_debug.log | grep "test_p2a_ship_roster"`.
Fix: rename the const (e.g. `const FitData := preload(...)`) and its uses in that file —
one line plus the call sites. Precedent: the flight-feel wave's fixer pass (G5) renamed three
such shadowing sites in its own new files to take that wave's new-file ledger 3 → 0, and
CONTRACTS §9's instrument treats the ledger as the lint gate. Cosmetic, but it is the wave's
own file and the house bar for a new file is zero rows.

### LOW — six, to `.agents/gen/LOW_BACKLOG.md`

| ID | Item |
|---|---|
| **R1-L1** | `hud.gd:628-633`'s doc block says "the default five-family grid is what an empty push falls back to", and `_hull_slots`' declaration says the same state means the five-family default — but an empty push **clears** the grid (measured: `columns=1, children=0`), it does not restore `_build_weapon_slots()`' five. The two comments disagree with each other and the first disagrees with the code. Unreachable today (`game.gd:_hull_slot_cells` always sends ≥ 1 cell for the nine hulls), so it is a wording bug, not a behaviour bug. `_hull_id` (`hud.gd:180`) is likewise recorded and never read (W5 reported it; deleting the two lines is behaviour-free). |
| **R1-L2** | CONTRACTS §11's bullet "Writes always persist the array shape" reads as a whole-file rule, but the shipped write normalises **only the hull it writes**: a v2/v3 file with two hulls, written for one of them, keeps the other hull's single-string row (measured: `{ "engine": "e_ion", "power": "p_std" }` beside the written row's full array shape). Both shapes read back correctly (`fit_for` and `ShipFit.resolve` both tolerate the singular key), so nothing is lost — but the pin's sentence and the code's own doc block ("the file keeps the shape it was saved with until something mutates the fit") should be made to agree, either by rewording the pin or by normalising every row on write. |
| **R1-L3** | `tests/test_engine2_wiring.gd` is a third test that moved, outside §5's "only these" list (W4's reported deviation 1). Justified and strengthening, but the wave's record (brief §5, IMPLEMENTATION_PLAN §9.10) should name it so the next reviewer does not read it as an unsanctioned edit. |
| **R1-L4** | The throwaway `ui/screens/_mockup_station.tscn`/`.gd` still carries the pre-wave construct: `HardpointSlots` as an `HBoxContainer` with seven plates, `@onready var _hardpoint_slots: HBoxContainer`, `"%d HULL · %d HP"` and a stubbed four-hull roster (hardpoints 3/4/5/7). It is its own scene (it never instances `shipyard_panel.tscn`) so nothing breaks, but the mockup now shows the old shipyard markup. Its deletion is already scheduled (IMPLEMENTATION_PLAN §9.6). |
| **R1-L5** | The HUD's ammo label names a fitted module with no firing family by its **slot index**: a fit carrying `w_mining` maps to the empty family (measured `live slots=[&"", &"laser"]`), `WEAPON_IDS.find(&"")` is −1, so the label falls back to `WEAPON_LABELS[_active_slot]` and a mining-laser slot reads as a gun name. Cosmetic, and the pin freezes that path ("the ammo label path is unchanged"), so it rides forward rather than being fixed here. |
| **R1-L6** | The owner's launch-fit gate is closed **in mechanism, not yet for the owner's own hull** (see §11): the Lancer's standard fit is two lasers, so `E` still mines nothing until a `w_mining` is fitted, which is P2-B's fitting panel. The WAVEBOARD's gate row should say so rather than "closed". |

---

## 11. The owner's launch-fit gate, re-measured (a wave deliverable)

W4's probe re-run by R1 **unchanged**, against the owner's own profile state
(`fits={}`, `active_ship="ship_fighter"`):

```text
[w4] active hull=ship_fighter mounted=[&"laser", &"laser"] slots=2 total_rounds=600 (was five families / 1500)
[w4] store after launch unchanged=true (instance id still stored=mod_0007)
[w4] --- a W cell that is the mining tool ---
[w4] fit.weapons=[&"w_mining", &"w_laser"] live slots=[&"", &"laser"] ammo=[0, 300] mounts_laser=true
```

| Symptom (WAVEBOARD) | Before | After | Verdict |
|---|---|---|---|
| the briefing reports five weapons / 1500 rounds while the ship mounts `[w_laser]` | five fixed families, 5 × 300 = 1500 rounds, the Vanguard's row resolved on every hull | **2** slots (`[laser, laser]`), **600** rounds, the Lancer's own row — and the launch, the HUD's cells and the briefing all read that one fit | **CLOSED** |
| "shooting is not working" | the HUD drew five cells / 1500 rounds for a hull mounting one or two weapons | the HUD draws the hull's own W cells (2 for the Lancer, 7 for the capital, 5 selectable), each seeded from its own family's pack | **CLOSED** |
| "cannot shoot asteroids" (no mining laser) | `E` mounted nothing because the launch's fit never carried `w_mining` | the mechanism is real and measured (`mounts_laser=true` for a fit that carries it; `player_ship._has_mining_module` gates the node) — but the **owner's Lancer standard fit still has no `w_mining`**, so the owner cannot mine until P2-B's fitting panel lets them trade a laser for it | **STILL OPEN for the owner; the root cause is closed** |

The orchestrator should record the third row as open, naming P2-B, rather than closing the
gate wholesale (R1-L6).

---

## 12. What R1 wrote, and what R1 did not do

New files (all under `tests/`, R1's declared set; none is discovered by the gate, which scans
`test_*.gd` only):

| File | Purpose |
|---|---|
| `tests/probe_r1_frames.gd` / `.tscn` | the scene probe of §2/§4/§5 (self-quitting, bounded) |
| `tests/probe_r1_migration.gd` | the v2/v3 fixture probe of §6 (`--script`) |
| `tests/probe_r1_prewave_fit.gd` | HEAD's `ship_fit.gd`, `class_name` dropped, for the A/B |

**Nothing was fixed**, per the brief: no product file, no test, no doc and no asset was
edited by this pass. The MED and the LOWs are for F1 and the close-out to act on.

**Residual uncertainty, stated rather than hidden:**

- The `--debug` warning ledger attributes rows by file; a warning raised *inside* a call made
  by a P2-A file but compiled from another file would be attributed to the other file. The
  ledger's 42 non-P2-A rows are all in files this wave did not touch, so the reading holds.
- The engine A/B compares the shipped resolver with HEAD's file loaded beside it. Both share
  the one `ShipStats` class, so the comparison is of the resolver's arithmetic, not of a
  frozen copy of `ShipStats` (which this wave does not touch: `git diff` over
  `game/ship_stats.gd` is empty).
- The migration probe drives `PlayerProfile` in isolation, as W2's does; it does not exercise
  the station shell's own save/load round trip, which is outside this wave's file set and
  covered by the green `p1_*` suites.
