---
slice: S18
reviewer: S18-R1
verdict: passed-with-followups
gate: "877/0 (baseline) → 886/0 (S18-R1, gate run twice, identical)"
---

# S18-R1 review — the ARMORY rework (D13 approach B) re-derived

## Findings
| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| S18-B1/F1 | MED | `docs/design/UI_SPEC.md` §3.10 A3, Layout bullet | The amendment pins cells **117×50**; the shipped and tested cell is **117×52** at the base host (`style.bay_cell_rect`; `test_s15` `CELL`, `test_s18` `CELL`), and the block's own arithmetic (192−34−8−34−6−6)/2 = 52. Docs text = bucket 2: the developer/designer session fixes the number, no fixer edits the yardstick. | developer session (docs pin, bucket 2) |
| S18-B1/F2 | LOW | `ui/station/armory_style.gd:65,120` | Two comments still call the master "2720×1072"; shipped and re-rendered master is 2720×1032 (md5 `b1241913488d4d566e4f670d33d9ca53`, `cmp` clean). | → ticket |
| S18-B1/F3 | LOW | `tests/probe_s10_a0_armory.gd:271` | Still reads `view[&"hint"]`; rack views no longer carry `hint` (gained `salvo`), so re-running that S10 audit probe errors. No suite reads it. | → ticket |
| S18-B1/F4 | LOW | `ui/station/armory_style.gd:152-162` | `drawn()/drawn_vector()/drawn_rect()` now have zero callers (builder-reported; the plate-fit path retired). | → ticket |
| S18-B1/F5 | LOW | `ui/station/armory_panel.gd` chip tones | The `OVER CAP` label reads 4.04:1 (#e8622a on #4e2012), under the caption floor; T7 holds (label + chevron + frame), but it is the only sub-floor ink in the pane. | → ticket |
| S18-B1/F6 | LOW | UI_SPEC A3 / STATION_HUB §5.11 "measured (452,214)+1392×610" | The live pane host measures **(452,204)+1392×606** at 1920×1080 (my probe and `resolutions_raw.log` agree); the derivation absorbs it (console 1360×512.6) but the "measured" figure needs re-measure/amend (builder follow-up row). | → ticket |

## Verified (every item re-derived, not read back)
- **Gate ×2.** `[SUMMARY] passed=886 failed=0` in two standalone hermetic runs, byte-for-byte the same count; only the pre-existing ObjectDB-leak warning.
- **No lost row.** HEAD tree carries 877 `test_*` functions; now 886 (net +9 = 8 `test_s18` rows + 1 `test_s10` right-click row). Six rows were renamed 1:1 with their retired subjects, coverage intact: d7 `4_3_bay_grid_on_the_rack_plate`→`bays_draw_five_across_the_band`, `rows_ride_the_row_plate`→`items_ride_the_code_drawn_plate`, `three_wells_mount`→`two_wells_mount`, `w_cells_are_the_machined_slot_recesses`→`cells_are_the_2x2_rack`; s15 `bay_marks_sit_on_the_plates_own_ink`→`console_and_the_bays_are_the_derived_geometry`, `five_bays_flowing_four_plus_one`→`five_bays_across_one_band`. No assertion was deleted without a successor; several were strengthened (held-unit words, caption-ramp colour, P5 wording).
- **Master.** `python3 staging/mockup/render_console_master.py` ×2 → 2720×1032, md5 `b1241913488d4d566e4f670d33d9ca53`, `cmp` clean against the shipped PNG; the gate's own `plate.texture.get_size() == 2720×1032` proves the reimport landed.
- **Pane in a running game** (reviewer probe `tests/probe_s18r1_audit.gd/.tscn`, windowed, three windows): 0 labels under 13 px and 0 `font_size` overrides; CAP ratios 6.67–8.56, CAP_VOID 4.97–7.27 (computed live from the style); all six drawn cards print `HELD %d ROUNDS - HOLD %d UNITS` plus `PRICE CR`; bay head = `READY`/`OVER CAP` **label + chevron** (colour never alone); empty cells print `DROP HERE`; footer caption absent (T5); inspector body is two lines (P4).
- **P6 standalone.** `probe_s18_resolutions.tscn` at 1280×720 / 2560×1080 / 1280×1024 → canvas 1920×1080 / 2560×1080 / 1920×1536; my run reproduces the builder's geometry line-for-line (window field excepted: headless vs windowed). `canvas_encloses_pane`, `host_encloses_console`, every bay/well/cell `inside=true` at all three; bays 260→385 wide (wide canvas), 328 tall (tall canvas) — the mockups' law. Windowed captures vs `armory_mockup_v2_b{,_wide,_tall}.png` show approach B's structure at all three; the wide mockup's own off-canvas card column is cured by the per-half 2×3 grid (disclosed in the report).
- **Data model (a dropped datum = HIGH).** `GROUPS_MAX=5` + `BATTERY_CELLS_MAX=4` unchanged (`weapons.gd:205,210`); every §17 seam the pane calls exists (`player_profile.gd:1222,1279,1319,1346,1401,1439`, ammo `:316,332,350`); refusal-writes-nothing, drag/swap/close and the hardcap refusal tests unchanged and green; card carries name/rounds/cost/held units vs ceiling/state + state line/BUY; salvo readouts and `rack_rows()`/`salvo_readout()` intact. `test_s15_battery_cap`, `test_s4_batteries`, `test_s5_batteries_v2`, `test_s8_qa_fixes`, `test_s11_*` untouched and green.
- **Moved numbers.** Every old→new pair in the report re-derived from code/tests and matching: host 1392×610, console 1360×516, master 2720×1032, band (16,38)/192, bay 260×192/gap 7, cells 117×52 @ (10,34), ledge (10,150) 240×34, drums 18×32 pitch 20, items 320×68, wells (16,286)+(696,286) 648×220, `%s CR`, `DROP HERE`, five-across.
- **Docs.** UI_SPEC A3 and STATION_HUB §5.11 carry dated blocks with per-item reversal paths; `18_engine_spec.md` untouched; `verify_wave.py verify --baseline s18_start` → `"problems": []`, modified = exactly the wave's 9 tracked files, deleted = [].
- **Deviations disclosed, not silently normalised:** mockup console 536 vs tick 516, the mockup's off-canvas card column, the 606/610 host read.

## Verified fixes
None — no fixer pass was run on this review (one MED, docs-only, escalated per bucket 2).

## Gate
`877/0` before (SLICE.md baseline) → `[SUMMARY] passed=886 failed=0` after, twice. Negative control: full test-name set diff HEAD↔worktree (877/886, renames above) — no orphaned row. Reviewer artifacts: `tests/probe_s18r1_audit.gd/.tscn` (own probes, per SLICE.md), captures at `user://s18r1_*.png`.
