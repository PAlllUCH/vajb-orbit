---
slice: D7
worker: D7-A0
model: "flare (gpt-image-2-5-flare-text-to-image) 2K 1:1 ×9, recraft/remove-background ×11, Pillow/numpy local"
status: actionable
gate: "not run — art-only deliverable (no .gd, no .tres, no project.godot touched); the wave gate is measured at D7-C1/C2/C3"
---

# D7-A0 report — cockpit panel family + armory console (UI_CHROME §12)

## Result

The **five §12 runs rendered**, each render's objects were **detected, cut on their own boxes, keyed
on their own and trimmed** (Phase G lane order), and **six masters ship** on their pinned boxes plus
**five provenance panels** and the generation log:

| shipped file | master box | route |
|---|---|---|
| `assets/ui/ui_cockpit_panel.png` | 928×512 | recraft-keyed render cut, contain fit |
| `assets/ui/ui_gauge_face.png` | 240×240 | recraft-keyed render cut, contain fit (bytes replace the D6 face) |
| `assets/ui/ui_armory_console.png` | 1744×1816 | recraft-keyed render cut, contain fit |
| `assets/ui/ui_armory_rack_plate.png` | 194×182 | recraft-keyed render cut, contain fit |
| `assets/ui/ui_armory_row_plate.png` | 192×64 | recraft-keyed render cut, contain fit |
| `assets/ui/ui_status_panel.png` | 1440×1040 | recraft-keyed render cut, contain fit |

Provenance panels under `assets/icons/`: `panel_cockpit`, `panel_gauge`, `panel_armory`,
`panel_armory_plates`, `panel_status` (2048×2048 RGB each). Log:
`assets/ui/generation_log_d7.md`. Review sheet:
`staging/phase_g/_review/d7_masters.png` (full) / `.jpg` (viewer copy, 192 KB) — the six masters at
their logical box and 2×, the **well-registration overlay** (pinned bays vs detected wells) and the
fallback route's own output.

**§12's hard QC:** ink containment **99.88–100.00 %** on all six masters (§12 asks ≥ 95 %) and each
pinned box verifies exactly (`ui_cockpit_panel` 928×512, `ui_gauge_face` 240×240, `ui_status_panel`
1440×1040). **The well-registration item does not pass on four of the six** (measured table below);
§12's two-step remedy was executed (one re-render per failing panel, then the authored fallback) and
the fallback is **staged, not shipped** for the measured reason in Deviations 1. **STOPPED for owner
approval** — no code work started; `ui/hud/**`, `ui/station/**`, `tests/**`, `project.godot`,
`ui/theme/**` and all of `game/`/`autoload/` are untouched.

## Well measurements vs the §3.7/§3.8/§3.10 bay rects at 2×

`staging/phase_g/qc_d7.py --json staging/phase_g/ui/qc_d7_ship.json`. A pinned rect "lines up" when
the panel draws it as a recess: its own mean luminance ≤ **0.95** × the plate's median
(`recess_ratio`). `coverage` is the share of the pinned rect's pixels the detector reads as recessed;
`holds_pinned` is the box-intersection share. All boxes/tolerances are pinned or derived from
`D7_DESIGN_REPORT.md`'s Mockup v5 table and `UI_SPEC` §3.10 / Mockup A, and the derivation is in
`qc_d7.py`'s `EXPECTED` block.

| panel | pinned rect (2×) | recess_ratio | verdict |
|---|---|---|---|
| `ui_cockpit_panel` | gauge_well Ø240 @ (190,172) | **0.852** | PASS |
| | compass_well Ø216 @ (434,172) | **1.128** | FAIL — the render's middle well is at x 423–603, its centre 79 px right of the pin |
| | readout_well (558,62)-(858,442) | 0.903 | PASS (the render's right well is 179 px wide against the 300 px rect) |
| | *foot recesses (64,370)-(316,442) / (330,370)-(538,442)* | *1.205 / 1.279* | *reported, not gating: no §12 prompt asks for them* |
| `ui_gauge_face` | recessed centre (100,100)-(140,140) | **0.900** | PASS |
| `ui_armory_console` | racks_well (60,244)-(1684,1024) | **1.063** | FAIL |
| | inventory_well (60,1140)-(1684,1480) | 0.856 | PASS |
| | ammo_well (60,1592)-(1684,1768) | **1.012** | FAIL — no well in that band |
| `ui_armory_rack_plate` | slot_1..4 40×44 on a 44 pitch | **1.112** | FAIL — the render's four slots sit on a ≈34.5 px pitch at y 68–114, the pins at y 38–82 |
| `ui_armory_row_plate` | none (flat strip) | – | no wells to check |
| `ui_status_panel` | left_well (48,120)-(600,856) | **1.028** | FAIL |
| | right_well (632,120)-(1392,696) | **1.101** | FAIL |
| | footer_strip (48,888)-(1392,988) | 0.827 | PASS |

**Re-render once (measured, no fix):** the four failing panels were re-rendered with §12's own
prompts unchanged (run ids in Evidence). Neither pass registers: worst `recess_ratio` pass 1 vs pass
2 — cockpit 1.128/1.403, console 1.063/1.041, rack plate 1.112/1.093, status 1.101/1.096
(`staging/phase_g/_d7_qc_pass2.log`). Pass 1 also ships one clear prompt win: its status panel draws
**15 slots in 3 rows of 5** as §12 asks, where pass 2 dropped to 12. **Shipped masters are pass 1**
except none — all six are pass 1.

## Deviations from §12 / the brief

Every item is a bucket-1 route choice (measured and reversible) or a bucket-2/3 finding (needs a
pinned number, a doc's text, or the prompt), per the escalation ladder.

1. **The §12 fallback was executed and is staged, not shipped — measured reason (bucket 2).**
   `staging/phase_g/ui_authored_d7.py` implements §12's "§12-authored route (shapes over a painted
   plate)": it erases the model's own wells through the same detector `qc_d7.py` measures with,
   refills from the plate (reflect fill / mirror fill), and draws the pinned wells plus their
   sub-recesses. Run on the shipped masters, **the erase covers 92.0 % of the cockpit panel's
   painted pixels, 94.6 % of the console's and 100 % of the rack plate's** (347 509 / 1 043 225 /
   14 958 px of 377 750 / 1 102 287 / 14 958 painted; `staging/phase_g/ui/authored_d7_ship.json`).
   Erasing that share removes the painted surface the panel exists to provide, and the output (see
   review sheet section 3, `staging/phase_g/ui/_authored_ship/`) reads as flat dark plates. The
   alternative reading — erase only the misregistered wells — still erases 92 % on the status panel
   (578 168 of 629 263 px) because the model's wells are large and interleaved with the pins. The
   authored outputs are kept as the owner's/fixer's alternative; shipping them would breach the
   wave's own art quality bar. **Reversal:** ship `_authored_ship/*.png` over `assets/ui/*.png`.
2. **`ui_armory_console`'s box is 2× the pane's measured content rect = 1744×1816, and §12's
   `contain` order leaves the pinned wells wider than the plate (bucket 2).** The measurement (bounded
   headless probe `staging/d7/measure_armory.gd`, `XDG_DATA_HOME=/tmp/d7probe`, instantiating
   `res://ui/station/armory_panel.tscn`): pane min **878×95**, `ArmoryScroll` min 711, `ArmoryBody`
   **703×874**, `RacksMargin` 420×255, `RacksBox` 396×255, `RackRows` 396×230, `Rack1` 190×56,
   `InventoryMargin` 507×58, `HeaderMargin` 703×33, an ammunition row **870×76** (`ROW_HEIGHT` 76),
   `PaneHeader` 878×48, `PaneFooter` 878×23. The pinned content frame is therefore **872×908 → 1744×1816**,
   matching Mockup A's own canvas (`staging/mockup/mockup_rest.py`, 872×908). The §12 run-3 render came
   back 1174×1938 (aspect 0.61) against a 0.96 box, so even `contain` puts the plate at x 363–1381
   inside the 1744 px box: **the pinned wells (1624 px wide) cannot fall inside the plate**, which is
   why every console pin fails regardless of the pin's y. **Reversal:** a per-run box measured from
   the render's own aspect, or `fill` instead of `contain` (both change a pinned number).
3. **§12 run 3's console prompt contradicts §3.10/Mockup A's well stack (bucket 3).** The prompt (law
   for the art) asks for "three stacked recessed wells … the **top well long and shallow** with seven
   short machined slot recesses … the lower two wells plain and **deep**". Mockup A draws the
   opposite proportions: the racks well is the tall one (390 logical, holding the 4+3 bay grid) and
   the ammunition well the shallow one (88 logical). No render can satisfy both, which is the second
   measured cause of the console's failure. **Reversal:** word the prompt to Mockup A's proportions,
   or re-derive §3.10's three well rects from the approved render.
4. **The §12 prompts do not place the wells at §3.7/§3.10's rects (bucket 2).** Measured on two
   independent renders each: the cockpit's middle (compass) well comes back centred ≈79 px right and
   ≈68 px below its pin, the status panel's right well / footer strip come back at different extents
   (and the pinned footer strip at y 888–988 falls **below** the contain-fitted plate, whose ink ends
   at y 916, because the render's aspect is 1.77 against the box's 1.39), and the rack plate's slots
   come back on a ≈34.5 px pitch at y 68–114 rather than 44 px at y 38–82. The prompts describe the
   parts, not their rects, so the model composes them; reaching §3.7/§3.10's rects needs prompt text
   that names positions (a docs change). **Reversal:** add the positions/sizes to §12's prompts, or
   re-derive §3.7/§3.10's bay rects from the approved renders.
5. **The armory rects are measured, not invented; two of the three armory boxes are the mockup's own
   pinned numbers (bucket 1).** `ui_armory_console` 1744×1816 is 2× the measured content rect (Deviation 2);
   `ui_armory_rack_plate` 194×182 is 2× §3.10's approved bay 97×91; `ui_armory_row_plate` 192×64 is 2×
   §3.10's approved ammunition row height 32. The row plate is a nine-slice (flat bands only, per
   §3.10), so its master must be at least the row band; 192×64 gives 32/8/32/8 px margins and a flat
   stretch zone. **Reversal:** any of the three boxes re-measured and re-staged by `ship_d7.py`.
6. **`panel_gauge` and `panel_armory_plates` are derived provenance names (bucket 1).**
   `ASSET_NAMING_SPEC` §12 names three provenance panels (`panel_cockpit`, `panel_armory`,
   `panel_status`); the five §12 runs need five. The gauge re-cut and the two-cell plates render take
   §1-legal derived names (the D6 precedent: `panel_instruments`, `panel_frame_glass` were derived
   the same way). `panel_armory` carries the **console** render (`panel_armory_console` run) and
   `panel_armory_plates` the 2-cell plates run. **Reversal:** rename on the owner's word.
7. **`ui_seg_*` were NOT re-authored, against §12's post-mockup amendment (bucket 2 — brief vs doc).**
   §12's amendment says the twelve `ui_seg_*` cells are re-authored as glyph-only,
   transparent-background cells under the same names and that AC5 re-runs. The brief's hard rule says
   `ui_seg_*`, `ui_compass_*` and `ui_gauge_needle` **stay byte-identical** for this wave. The brief is
   the worker's law, so the family was left untouched and verified: `ui_seg_0` `7a884ea0`,
   `ui_seg_blank` `f9c2f26f`, `ui_compass_rose` `56f2f9ff`, `ui_compass_lubber` `84a0babc`,
   `ui_gauge_needle` `87e66a2c`, `ui_cockpit_frame` `cfc4e234` — all equal to the D6-M0b record. AC5
   therefore did **not** re-run (§12's own QC line says it "does not re-run" when the family is not
   re-cut). **Reversal:** run `seg_svg_digits.py` without the plate-face layer and re-run
   `qc_seg_digits.py`; the brief's rule has to be lifted first.
8. **`ui_readout_glass` and `ui_cockpit_frame` are untouched (bucket 1).** §3.7 makes the glass and
   the frame unreferenced **in the cluster**, and `ui_cockpit_frame` stays in service on §3.8 until
   the status restyle. Neither is D7-A0's to delete (§10 keeps every cut).
9. **The plates panel is 1×2, not 2×1.** §12's run-4 prompt reads as two plates side by side;
   `panels.py --detect` finds the bay plate **above** the row strip, so `grid=[1,2]` (the arrangement
   is read off the render, `cells` stays the authority on count and names). **Reversal:** re-detect and
   flip the grid.

## Evidence

Commands (host-neutral, from `$VAJB_WORKSPACE`; the interpreter is Linux `python3` under
`uv run --with numpy --with pillow --with scipy`):

```
python3 staging/phase_g/wave_g.py panel_cockpit panel_gauge panel_armory_console \
        panel_armory_plates panel_status                       # 5 × 2K, 1 paid call each
python3 staging/phase_g/panels.py --detect <render> --grid 1x1|1x2
python3 staging/phase_g/refit_panels.py <run-id> ...           # cut each -> key each -> trim
python3 staging/phase_g/ship_d7.py --stage-only | --replace    # fit to the pinned box, copy, log
python3 staging/phase_g/qc_d7.py --json staging/phase_g/ui/qc_d7_ship.json
python3 staging/phase_g/ui_authored_d7.py --all --preview      # section 12's fallback (staged)
python3 staging/phase_g/build_review_d7.py
XDG_DATA_HOME=/tmp/d7probe godot --headless --path "$VAJB_PROJ" \
        --script "$VAJB_WORKSPACE/staging/d7/measure_armory.gd"
```

Renders — pass 1 (the shipped set), model `flare`, 2K, aspect 1:1, `style-block.txt` verbatim as the
prompt preamble + §12's framing sentence + §12's per-run prompt + §8's negative list:

| run | job id | run folder | objects found |
|---|---|---|---|
| `panel_cockpit` | `9dee8811e70bb695b4477b41debabed9` | `20260924-102629` | 1 (1977×1031 ink) |
| `panel_gauge` | `cc0c82b53eb47bbeb3a0546efd92bb93` | `20260924-102707` | 1 (1788×1823) |
| `panel_armory_console` | `b9c9f3a61f1c22f40d492ba8e928ff64` | `20260924-102746` | 1 (1174×1938) |
| `panel_armory_plates` | `0f50b3eac095d596bccbc2e618cbaf8d` | `20260924-102824` | 2 (1497×694, 1776×273) |
| `panel_status` | `ba5a83b52f39d2476a73b320b1fdb6a9` | `20260924-102913` | 1 (1951×1158) |

Re-render (one each, same prompts), pass 2: `panel_cockpit` `dd6cdd25296d404ef5a0eefae4fbcadf`,
`panel_armory_console` `72c3896aeb1de2935c1ad276ab2a0b05`, `panel_armory_plates`
`83fe955e477efdd71e083143b45fdedf`, `panel_status` `93fd0541db3145223208c5f2c404de14`.

Cut/key order per panel (`refit_panels.py`), ink→alpha verification, pass 1:

```
ui_cockpit_panel:     ink 1977x1031 -> alpha 1983x1034 PASS
ui_gauge_face:        ink 1788x1823 -> alpha 1792x1829 PASS
ui_armory_console:    ink 1174x1938 -> alpha 1178x1944 PASS
ui_armory_rack_plate: ink 1497x694  -> alpha 1501x697  PASS
ui_armory_row_plate:  ink 1776x273  -> alpha 1781x275  PASS
ui_status_panel:      ink 1951x1158 -> alpha 1956x1162 PASS
```

Shipped bytes (`staging/phase_g/ui/ship_report_d7.json` + the containment probe):

| file | box | ink box | ink | edge margin | ink containment | md5 |
|---|---|---|---|---|---|---|
| `ui_cockpit_panel` | 928×512 | (38,34)-(890,479) | 79.8 % | 33 px | **100.00 %** | `184674c3` |
| `ui_gauge_face` | 240×240 | (10,9)-(229,231) | 84.4 % | 9 px | **99.88 %** | `860c1ce5` |
| `ui_armory_console` | 1744×1816 | (362,68)-(1382,1749) | 54.1 % | 67 px | **99.99 %** | `f2b3db46` |
| `ui_armory_rack_plate` | 194×182 | (7,49)-(187,133) | 42.8 % | 7 px | **100.00 %** | `acf82595` |
| `ui_armory_row_plate` | 192×64 | (7,18)-(185,46) | 40.6 % | 7 px | **100.00 %** | `b1568ade` |
| `ui_status_panel` | 1440×1040 | (53,123)-(1387,916) | 70.6 % | 53 px | **100.00 %** | `2f8e315d` |

The armory console's 65.19 % transparent share is the `contain` letterbox Deviation 2 measures; every
master's ink box is inside its box with ≥ 7 px to the border, so nothing is clipped.

Cost: **9 × 2K flares = 90 credits ≈ $0.45** real (10 credits = $0.05 per 2K) + **11 recraft keys**
≈ 11 credits ≈ $0.05 → **≈ 101 credits ≈ $0.50**. The brief budgeted 4 × 2K ≈ $0.20; the extra five
renders are the fifth §12 run (the status console was added 2026-09-24) plus §12's mandated one
re-render for each of the four panels whose wells did not line up.

## Files touched

- `vajb-orbit/assets/ui/` — **6 masters** (`ui_cockpit_panel`, `ui_gauge_face` (bytes replaced),
  `ui_armory_console`, `ui_armory_rack_plate`, `ui_armory_row_plate`, `ui_status_panel`) +
  `generation_log_d7.md`
- `vajb-orbit/assets/icons/` — **5 provenance panels** (`panel_cockpit`, `panel_gauge`,
  `panel_armory`, `panel_armory_plates`, `panel_status`)
- `staging/phase_g/wave_g.py` — the D7 section: the five run specs, the two frames and the six boxes
- `staging/phase_g/ship_d7.py` — **new**: box fitting, project copy, panel provenance, generation log
- `staging/phase_g/qc_d7.py` — **new**: ink containment + the well-registration measurement
- `staging/phase_g/ui_authored_d7.py` — **new**: §12's authored fallback (staged, not shipped)
- `staging/phase_g/build_review_d7.py` — **new**: the review sheet (masters + overlay + fallback)
- `staging/d7/measure_armory.gd` — **new**: the bounded headless armory-rect measurement probe
- `staging/phase_g/ui/**` — renders, `_cells/`, `_masters/` (+ `_masters_pass1`/`_masters_pass2`/
  `_masters_r1`), `_authored_ship/`, the QC JSONs (`qc_d7_ship.json`, `qc_d7_pass2.json`), the logs
  (`_d7_render.log`, `_d7_render_r2.log`, `_d7_refit_r2.log`, `_d7_qc_ship.log`, `_d7_qc_pass2.log`)
- `staging/phase_g/_review/d7_masters.png` / `.jpg` — the review sheet

No `game/`, `autoload/`, `project.godot`, `ui/theme/`, `docs/`, `addons/` or test file was touched.

## Follow-ups

| Item | Kind | Where |
|---|---|---|
| The §12 prompts do not place the wells at §3.7/§3.8/§3.10's bay rects; measured on two renders each, 4 of 6 masters fail the registration item (worst 1.403) | docs finding (bucket 2 — pinned wording) | `docs/design/UI_CHROME_ASSETS_SPEC.md` §12 |
| §12 run 3's console prompt (shallow top well, deep lower wells) contradicts §3.10/Mockup A's well stack (tall racks well, shallow ammo well) | docs finding (bucket 3 — supersedes a mockup ruling) | `docs/design/UI_CHROME_ASSETS_SPEC.md` §12 / `UI_SPEC.md` §3.10 |
| The console's 2× measured content rect 1744×1816 vs a 0.61-aspect render under `contain` leaves the pinned wells 1624 px wide against a 1018 px plate | docs finding (bucket 2 — pinned number) | `docs/design/UI_CHROME_ASSETS_SPEC.md` §12 / `UI_SPEC.md` §3.10 |
| §12's post-mockup amendment re-authors `ui_seg_*` and re-runs AC5; the brief's hard rule keeps them byte-identical — the two disagree | docs finding (bucket 2 — brief vs doc) | `.agents/gen/slices/D7-cockpit-rework/D7_BRIEF.md` / `UI_CHROME_ASSETS_SPEC.md` §12 |
| Derived provenance names `panel_gauge` / `panel_armory_plates` (ASSET_NAMING §12 names three, the batch needs five) | naming ruling | `docs/design/ASSET_NAMING_SPEC.md` §12 |
| §12's fallback as literally specified erases 92–100 % of the painted plate on these renders and cannot preserve the surface | docs finding (bucket 2) | `UI_CHROME_ASSETS_SPEC.md` §12 / `staging/phase_g/ui_authored_d7.py` |

---

# D7-A1 re-run — the three console panels as flat plates (UI_CHROME §12 Amendment 2)

**Written by D7-A1, appended to A0's report.** Task: re-render **only** `ui_cockpit_panel`,
`ui_armory_console` and `ui_status_panel` as **flat painted plates** — plate texture only (brushed
steel, bolt heads, plate seams, brush grain), **no recessed wells and no slot recesses**, because
the wells are code-drawn at the pinned rects (`D7_BRIEF.md`'s Mockup v6/v7 amendment; UI_SPEC
§3.7/§3.8's mockup blocks). A0's `ui_gauge_face`, `ui_armory_rack_plate` and `ui_armory_row_plate`
stand untouched and are verified byte-identical below. Lane order per panel: render →
`panels.py --detect` → cut each → key each → trim → ship → §12 QC minus the retired well rows.
**STOPPED for owner approval — no code.**

## Result

The three flat plates render, cut, key and ship on their pinned boxes, and all three now **cover
the box their code-drawn wells will be drawn into** (the whole point of Amendment 2: a plate that
stopped short of its box would leave those wells floating on bare void).

| shipped file | box | cut box | fit scale | ink containment | ink share | md5 |
|---|---|---|---|---|---|---|
| `assets/ui/ui_cockpit_panel.png` | 928×512 | 1944×1012 | 0.4774 | **100.00 %** | 91.93 % | `e238e6f5` |
| `assets/ui/ui_armory_console.png` | 1744×1816 | 1987×1991 | 0.8777 | **100.00 %** | 94.46 % | `a8382b40` |
| `assets/ui/ui_status_panel.png` | 1440×1040 | 2042×1340 | 0.7052 | **100.00 %** | 88.74 % | `c8c0df57` |

§12's QC minus the well rows: every box verifies exactly (`box_match=True` for all six masters,
`staging/phase_g/ui/_d7a1_containment.log`), ink containment **100.00 %** on every cut (≥ 95 %
required), and the three retired well rows report no gate (`qc_d7.py`'s `EXPECTED` now carries only
`ui_armory_rack_plate` and `ui_gauge_face`, per Amendment 2; `staging/phase_g/ui/qc_d7_a1_ship.json`).
Provenance panels under `assets/icons/`: `panel_cockpit` / `panel_armory` / `panel_status`, now the
flat renders the shipped bytes were cut from (`panel_status` is 2048×1536 — its render canvas is 4:3).
Review sheet: `staging/phase_g/_review/d7a1_plates.png` / `.jpg` (1920×1210) — the three plates at
their logical box and at 2×, plus the coverage measurement (pinned well rects in ember against the
plate's own ink rect in green).

## Plate coverage vs the pinned well rects (the number Amendment 2 hinges on)

`staging/phase_g/qc_d7_a1.py` applies the lane's own geometry in order (ink box → `trim_centre`'s
pad → `fit_contain`'s scale to the pinned box) and measures the plate's ink rect in box space
against the union of the code-drawn well rects (`WELL_UNIONS`: UI_SPEC §3.7's gauge/compass/readout
+ foot recesses, §3.8's left/right well + footer strip, §3.10's three console wells).

| panel | chosen pass | plate fills (w × h) | area | well union inside | covers? |
|---|---|---|---|---|---|
| `ui_cockpit_panel` | flat pass 2 | 99.14 % × 92.77 % | 91.97 % | **100.00 %** | **yes** |
| `ui_armory_console` | flat pass 3 | 99.20 % × 95.43 % | 94.66 % | **100.00 %** | **yes** |
| `ui_status_panel` | flat pass 4 | 99.24 % × 89.62 % | 88.93 % | 99.73 % | near (2 px short) |

The status plate is **2 px** (1 logical px) short of the union's bottom edge at the very bottom of
the 1040 px box — the footer strip's last row of pixels. Reported, not hidden; a fifth pass could
chase it but the aspect spread already shows the model will not land 1.385 on request.

## The four flat render passes, and why each exists

Amendment 2's literal instruction ("drop every `recessed well` phrase") leaves the plate's own
outline unpinned, and the model composes it. Measured, in order ($VAJB_WORKSPACE, `flare` 2K,
`style-block.txt` verbatim preamble + §12's framing sentence + the flat subject + §8's negatives):

| pass | run id | render folder | job id | canvas | ink box | ink aspect | box aspect |
|---|---|---|---|---|---|---|---|
| 1 | `panel_cockpit_flat` | `20260924-110201` | `ba70fabd869c041910c47ac2de850c44` | 1:1 | 1943×928 | 2.094 | 1.812 |
| 2 | `panel_cockpit_flat` | `20260924-110505` | `8ad99c2810106e9f8786faa2cabbc19f` | 1:1 | 1922×993 | 1.936 | 1.812 |
| 1 | `panel_armory_console_flat` | `20260924-110240` | `b252aa5c0359ea0be3998f4384fcccab` | 1:1 | 1018×1995 | **0.510** | 0.960 |
| 2 | `panel_armory_console_flat` | `20260924-110550` | `cd611f277dc5ecf7330068c93d3a3445` | 1:1 | 1439×1774 | 0.811 | 0.960 |
| 3 | `panel_armory_console_flat` | `20260924-110922` | `7087d799899b577758a500ca0b93d45d` | 1:1 | 1965×1968 | 0.998 | 0.960 |
| 1 | `panel_status_flat` | `20260924-110323` | `aca0ef2587b367dd0736620f58080899` | 1:1 | 1664×1772 | 0.939 | 1.385 |
| 2 | `panel_status_flat` | `20260924-110629` | `45e645c02b0716e308562d5b084646fb` | 1:1 | 1901×968 | 1.964 | 1.385 |
| 3 | `panel_status_flat` | `20260924-110939` | `b18de93526938a24a663e6a3cde22418` | 4:3 | 1988×1204 | 1.651 | 1.385 |
| 4 | `panel_status_flat` | `20260924-111036` | `b21d93ae23b0b978d432a11fc0abbfa2` | 4:3 | 2020×1318 | 1.533 | 1.385 |

Each pass's shipped-lane coverage (pad **0.04**, the lane default), which is the measurement that
forced the next pass:

| panel | pass 1 | pass 2 | pass 3 | pass 4 | with the A1 pad (0.00), chosen pass |
|---|---|---|---|---|---|
| cockpit | 74.12 % area / union 100 % | 80.00 % / 100 % | – | – | **91.97 % / 100 %** |
| console | 45.54 % / union 52.02 % | 72.40 % / 82.69 % | 82.40 % / 95.47 % | – | **94.66 % / 100 %** |
| status | 58.13 % / union 66.00 % | 60.44 % / 77.56 % | 71.83 % / 90.42 % | 77.44 % / 94.53 % | **88.93 % / 99.73 %** |

* **Pass 1** is Amendment 2's literal text and it fails functionally: the console came back a tall
  narrow plate (aspect 0.51) that fills **49 %** of its box's width, so §3.10's wells (which span
  x 3.4 %–96.6 % of the box) would be drawn mostly off the art. This is A0's Deviation 2 repeating
  from the other direction — A0's console render was 0.61 aspect, pass 1 is 0.51.
* **Pass 2** adds the box's own outline proportion to the subject ("about as wide as it is tall" /
  "about 1.4 times as wide…"). It fixes the console's direction (0.81) and overshoots the status
  (1.96 against 1.385).
* **Pass 3** adds "the plate filling the frame up to a narrow plain white border all around" and
  sets the **render canvas** to the box's nearest supported aspect (`flare` 2K supports
  `1:1, 3:2, 2:3, 16:9, 9:16, 4:3, 3:4, 21:9`; the console's 0.960 → 1:1, the status's 1.385 → 4:3).
  The model's outline follows the canvas more than the wording — this is the pass that lands the
  console (0.998 against 0.960).
* **Pass 4** ties the status plate to the canvas in words ("its outline matching the frame's own
  proportions of about 4 to 3") and pulls 1.651 → 1.533.
* The **cockpit's pass 2 was avoidable**: pass 1 already covered its well union 100 % (at pad 0.04,
  as shipped it would have been 85.9 % tall against pass 2's 92.77 %), so pass 2 bought 7 % more
  height for one render. Reported because the spend is real.

Chosen passes: cockpit **pass 2**, console **pass 3**, status **pass 4**. The superseded passes stay
in their own render folders as provenance; nothing was deleted.

## Deviations from §12 / the brief

Buckets per the AGENTS.md escalation ladder.

1. **The trim pad is 0 for the three flat runs (bucket 1 — lane helper).** `trim_centre`'s 4 % pad
   is *inside* the fit, so it costs the plate 8 % of its box on both axes and 8 % is exactly what
   the console and the status needed. `wave_g.trim_centre` still defaults to 0.04 for every other
   run; `refit_panels.py` reads `spec["pad_share"]` and the three A1 specs set `pad_share=0.0`
   (`trim_centre` floors it at 8 px). **Reversal:** drop the key, re-cut, and accept the 8 % margin.
2. **The flat prompts carry an outline-proportion / frame-filling clause and two runs pin the
   render canvas aspect (bucket 1 route, bucket 2 wording).** Amendment 2 says the prompts "drop
   every `recessed well` phrase"; those phrases were what fixed the plate's internal layout, and
   nothing in the amendment replaces them. Pass 1 proves the layout drifts without a replacement.
   The clause added is the pinned box's own aspect, so no pinned number moves; the canvas aspect is
   a render parameter §12 does not pin. **Reversal:** revert the subjects to Amendment 2's literal
   text and the canvas to 1:1, re-cut, and ship the pass-1 letterbox (console 49 % width) — which
   breaches the wave's own art-quality bar for the third time on this panel.
3. **`ship_d7.py` now plans all six masters but copies only the selected three (bucket 1).** The A1
   runs head the plan, so each name ships once from the newest cut; the generation log stays the
   record of the whole family (six rows). A0's three untouched masters were re-staged and verified
   **byte-identical** (`860c1ce5` / `acf82595` / `b1568ade` — the same md5s A0's report records), and
   were not re-copied into the project. `ship_report_d7.json` was rewritten for six masters (A0's
   three replaced rows are in A0's own table above); `generation_log_d7.md` was rewritten and A0's
   version is kept at `staging/phase_g/ui/_a1_backup/generation_log_d7.md.a0`.
4. **A0's three console-panel bytes are backed up before the first write (bucket 1).**
   `staging/phase_g/ui/_a1_backup/` holds the three shipped masters, the three provenance panels,
   the three A0 renders, the three staging cuts, A0's three fitted masters, A0's log and
   `MANIFEST.md5` + `README.md` with the one-line-per-file reversal.
5. **Two new staging tools (bucket 1).** `staging/phase_g/qc_d7_a1.py` measures a candidate render's
   plate coverage of the pinned well rects and the shipped masters' ink containment (the §12 QC
   record, `qc_d7_a1_ship.json` / `qc_d7_a1_containment.json`); `staging/phase_g/build_review_d7_a1.py`
   builds the three-plate review sheet. `qc_d7.py`'s three well rows were retired per Amendment 2
   (the retired rects stay in its docstring as the record the code-drawn wells must honour).
6. **§12 Amendment 2 does not say the plate must reach the box, and the pinned `contain` fit cannot
   guarantee it (bucket 2 — docs).** With a pinned master box and a pinned `contain` fit, the plate
   covers its box **only if the render's own outline aspect matches the box's**. The amendment's
   whole purpose is that the code draws the wells at the pinned rects — so this should be stated in
   §12 rather than left to each re-render. **Proposed wording (owner/designer to rule):** "*the
   three flat plates' render outline matches the pinned master box's aspect (±5 %); the plate must
   cover the box it ships in*". Reversal: leave §12 as is and treat every flat re-render as an
   iterative composition problem.
7. **Cost: 9 × 2K = 90 credits ≈ $0.45 real, plus 3 recraft keys ≈ 3 credits ≈ $0.05 → ≈ 93 credits
   ≈ $0.47** (10 credits = $0.05 per 2K, the AGENTS.md basis; the script's printed estimate
   over-reports 3×). A0 spent 9 renders for the same wave. The brief's basis was 4 × 2K ≈ $0.20 for
   the whole art batch, so the wave's art spend is now ≈ **$0.97** against that basis. The overshoot
   is the two prompt iterations the composition needed (Deviations 1–2) plus the one avoidable
   cockpit pass. **Reversal:** approve and no further spend; a fifth status pass would be a further
   $0.05.
8. **The import cache is stale for all six changed files (bucket 1, A0b's step).**
   `vajb-orbit/.godot/imported/*.md5` still records A0's source md5s (`184674c3`, `f2b3db46`,
   `2f8e315d`, `e1c59630`, `b8f017a2`, `51a0ece6`) while the sources are now `e238e6f5`,
   `a8382b40`, `c8c0df57`, `b823504a`, `aa2fc8df`, `682f814e`. The game loads A0's textures until
   the A0b reimport runs; that is the brief's own A0b step (after owner approval).
9. **`ui_armory_rack_plate`'s well row still FAILs (A0's own, unchanged by Amendment 2).**
   `qc_d7.py` reports `worst_recess_ratio 1.112`, `centre_inside=False` on all four slots — A0's
   Deviation table already records it, and the rack plate is not one of the three Amendment 2
   re-renders. Not fixed here; it is a standing A0 finding.

## Evidence

Commands (from `$VAJB_WORKSPACE`; interpreter `uv run --no-project --with numpy --with pillow
--with scipy python3`):

```
python3 staging/phase_g/wave_g.py panel_cockpit_flat panel_armory_console_flat panel_status_flat  # pass 1
python3 staging/phase_g/wave_g.py panel_cockpit_flat panel_armory_console_flat panel_status_flat  # pass 2
python3 staging/phase_g/wave_g.py panel_armory_console_flat panel_status_flat                     # pass 3
python3 staging/phase_g/wave_g.py panel_status_flat                                               # pass 4
python3 staging/phase_g/panels.py --detect <render> --grid 1x1 --page staging/phase_g/ui/_a1_detect_<run>_p<N>.jpg
python3 staging/phase_g/refit_panels.py panel_cockpit_flat panel_armory_console_flat panel_status_flat
python3 staging/phase_g/ship_d7.py --replace --only ui_cockpit_panel ui_armory_console ui_status_panel
python3 staging/phase_g/qc_d7.py --json staging/phase_g/ui/qc_d7_a1_ship.json
python3 staging/phase_g/qc_d7_a1.py --shipped --json staging/phase_g/ui/qc_d7_a1_containment.json
python3 staging/phase_g/qc_d7_a1.py --json staging/phase_g/ui/qc_d7_a1_chosen.json
python3 staging/phase_g/build_review_d7_a1.py
```

Detection: one object per render on a 1×1 grid, every pass (`panels.py --detect`), so each plate is
cut whole. Cut/key/trim (`refit_panels.py`), all PASS:

```
ui_cockpit_panel:   ink 1922x993 -> alpha 1928x996  -> cut 1944x1012
ui_armory_console:  ink 1965x1968 -> alpha 1971x1975 -> cut 1987x1991
ui_status_panel:    ink 2020x1318 -> alpha 2026x1324 -> cut 2042x1340
```

Logs: `staging/phase_g/ui/_a1_render.log`, `_a1_render_pass2.log`, `_a1_render_pass3.log`,
`_a1_render_pass4.log`, `_a1_refit.log`, `_d7a1_qc_ship.log`, `_d7a1_containment.log`. The Phase G
lane log (`staging/phase_g/ui/generation_log_phase_g.md`) carries all nine runs' prompts and job ids.

## Files touched

- `vajb-orbit/assets/ui/` — **3 masters replaced** (`ui_cockpit_panel` `e238e6f5`,
  `ui_armory_console` `a8382b40`, `ui_status_panel` `c8c0df57`) + `generation_log_d7.md` rewritten
  (six rows)
- `vajb-orbit/assets/icons/` — **3 provenance panels replaced** (`panel_cockpit` `b823504a`,
  `panel_armory` `aa2fc8df`, `panel_status` `682f814e`)
- `staging/phase_g/wave_g.py` — the three `*_flat` runs, the flat subjects, per-run `aspect` and
  `pad_share` support in `run_one`
- `staging/phase_g/refit_panels.py` — the per-run `pad_share`
- `staging/phase_g/ship_d7.py` — `A1_RUNS` / `plan` / `panel_plan` / six-row log
- `staging/phase_g/qc_d7.py` — the three well rows retired (Amendment 2)
- `staging/phase_g/qc_d7_a1.py` — **new**: coverage + containment measurement
- `staging/phase_g/build_review_d7_a1.py` — **new**: the three-plate review sheet
- `staging/phase_g/ui/**` — the nine renders, `_cells/`, `_masters/`, `qc_d7_a1_*.json`, the logs,
  `_a1_backup/**` (A0's bytes + `MANIFEST.md5` + `README.md`)
- `staging/phase_g/_review/d7a1_plates.png` / `.jpg` — the review sheet

No `game/`, `autoload/`, `project.godot`, `ui/theme/`, `docs/`, `addons/`, `ui/hud/**`,
`ui/station/**` or test file was touched. `ui_seg_*`, `ui_compass_*`, `ui_gauge_needle`,
`ui_cockpit_frame`, `ui_readout_glass`, `ui_gauge_face` and the two armory plates are byte-identical.

## Owner decision owed

Ship the three flat plates as measured (all three cover their pinned boxes, §12 QC minus the
retired well rows passes), or ask for a fifth status pass / a wording change to §12's flat prompts
(Deviation 6). On approval, **A0b** reconciles and reimports the six changed assets (Deviation 8),
then D7-C1/C2/C3 mount the plates and draw the wells at the pinned rects.
