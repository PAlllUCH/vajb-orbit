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

---

# D7-A1b — the glyph-only digit family, the D7 reconcile and the unified import

**Written by D7-A1b, appended to A0's report.** Task: (1) re-author the twelve `ui_seg_*` masters as
**glyph-only, transparent-background** cells per §12's post-mockup amendment and re-run AC5;
(2) reconcile every shipped D7 master against the §12 table; (3) unify the import settings and
trigger the reimport in a quiet window; (4) append the results here. **No code.** The owner approved
the plates, which lifts A0's Deviation 7 (the brief's "`ui_seg_*` stay byte-identical" rule) — the
§12 amendment is the newer doc text and it is what the approved cockpit look requires.

## Result

| item | outcome |
|---|---|
| the twelve `ui_seg_*` | re-authored **glyph-only** (segment lattice alone, transparent plate) at 48×88, same names, shipped (`staging/phase_g/ui/_seg_glyph/`) |
| AC5 digit QC | **PASS** on the re-authored family — containment **1.0000 on all 12 cells**, blank smallest, `1` smallest digit, `8` largest, no by-segment inversion |
| §12 reconcile | **23/23** masters present, **no box mismatch**, all names as the table pins |
| import settings | all 18 wave masters now read **mipmaps on / lossless / 3D auto-detect off** (5 needed the rewrite) |
| reimport | 18 files reimported through the open editor; the cache's `source_md5` matches every shipped source |
| code touched | none — `game/`, `autoload/`, `ui/hud/**`, `ui/station/**`, `ui/theme/`, `project.godot`, `docs/`, `addons/`, `tests/**` untouched |

## 1. The twelve glyph-only cells

§12's post-mockup amendment: "the D6 `ui_seg_*` cells carry painted plate backgrounds and are
**re-authored as glyph-only, transparent-background cells under the same 12 names**: rasterise the
existing `staging/phase_g/_svg/ui_seg_*.svg` segment lattice alone (drop the plate-face layer) at
48×88 — no paid generation." The lattices live at `staging/phase_g/ui/_svg/` (the path in the
amendment omits the `ui/` level); they are the ones `seg_svg_digits.py` authored from
`seg_geometry.lattice`, so the glyph geometry is exactly the geometry AC5 measures against. New step
`staging/phase_g/seg_glyph_only.py` rasterises each lattice **directly at 48×88** on a transparent
canvas and ships the twelve PNGs; the D6 plate-composited bytes it replaces are snapshotted to
`staging/phase_g/ui/_a1b_backup/` (+ `MANIFEST.md5`, `README.md`).

| file | box | transparent | ink | opaque palette | md5 (new) | md5 (D6, replaced) |
|---|---|---|---|---|---|---|
| `ui_seg_0` | 48×88 | 64.06 % | 35.94 % | `#C9CDD2` 0.878 / `#2A2E35` 0.122 | `bb05f189` | `7a884ea0` |
| `ui_seg_1` | 48×88 | 64.06 % | 35.94 % | `#2A2E35` 0.647 / `#C9CDD2` 0.353 | `b1875f42` | `357ef3fa` |
| `ui_seg_2` | 48×88 | 64.06 % | 35.94 % | `#C9CDD2` 0.695 / `#2A2E35` 0.305 | `7b878e72` | `be0ef507` |
| `ui_seg_3` | 48×88 | 64.06 % | 35.94 % | `#C9CDD2` 0.744 / `#2A2E35` 0.256 | `2d0ec8d8` | `f570fd9b` |
| `ui_seg_4` | 48×88 | 64.06 % | 35.94 % | `#C9CDD2` 0.603 / `#2A2E35` 0.397 | `fd9aeb81` | `2956fba0` |
| `ui_seg_5` | 48×88 | 64.06 % | 35.94 % | `#C9CDD2` 0.695 / `#2A2E35` 0.305 | `71f89a1a` | `ea95b9f6` |
| `ui_seg_6` | 48×88 | 64.06 % | 35.94 % | `#C9CDD2` 0.824 / `#2A2E35` 0.176 | `f4d6e6a0` | `381d4785` |
| `ui_seg_7` | 48×88 | 64.06 % | 35.94 % | `#2A2E35` 0.513 / `#C9CDD2` 0.487 | `6dee7c6e` | `bb6f91ba` |
| `ui_seg_8` | 48×88 | 64.06 % | 35.94 % | `#C9CDD2` 1.000 | `c32b1b03` | `60ea0ba5` |
| `ui_seg_9` | 48×88 | 64.06 % | 35.94 % | `#C9CDD2` 0.872 / `#2A2E35` 0.128 | `31bb2de1` | `3a200a94` |
| `ui_seg_pct` | 48×88 | 64.06 % | 35.94 % | `#2A2E35` 0.573 / `#C9CDD2` 0.427 | `ebf471a6` | `b0e17a4f` |
| `ui_seg_blank` | 48×88 | 64.06 % | 35.94 % | `#2A2E35` 1.000 | `a90eab91` | `f9c2f26f` |

Every cell now carries **only** the two segment fills (`#C9CDD2` lit, `#2A2E35` unlit) on
transparency — 64.06 % of each cell is transparent, against **6.34 %** for the D6 plate-composited
bytes; the plate face is gone. The **ghost survives by construction**: §11's "ghost outline present
in every cell" is the *unlit* lattice, which stays drawn as opaque panel steel, so a bare drum still
reads its full figure-8 with the lit bars bone. The ink share is constant across the family (35.94 %)
because all seven bars are always drawn; only the lit/unlit split moves.

**Direct rasterisation, not supersample+downscale (measured route choice).** The D6 route rendered at
4× and LANCZOS-resized to 48×88 before compositing. Applied to a *transparent* cell that produces a
soft sprite — 1272 partial-alpha pixels of 4224, and 2 dominant opaque colours that are not the
lattice's own (`#CCD0D6` 0.122, `#D6DADF` 0.047 beside the correct `#C9CDD2` 0.400 / `#2A2E35`
0.074) because PIL resizes the RGBA plane without premultiplying. Rasterising directly at 48×88 gives
2 opaque colours and 208 fringe pixels, so the lattice's fills are the only opaque colours in the
file. The amendment names the master box, so direct is also the literal reading. **Reversal:** re-add
the `SS` supersample + LANCZOS downscale in `seg_glyph_only.rasterise` and re-ship.

## 2. AC5 digit QC re-run on the re-authored family

`python3 staging/phase_g/qc_seg_digits.py --dir staging/phase_g/ui/_seg_glyph --json
staging/phase_g/ui/qc_seg_glyph.json` — the **unmodified** tool, so the yardstick is the one D6 was
measured with. Reference: 7 ghost segment boxes read off `ui_seg_blank`'s own unlit bars (`ghost ink`),
`[[13,4,34,19],[30,19,46,44],[30,43,46,69],[13,68,34,84],[2,43,14,69],[2,19,14,44],[13,36,34,52]]`.

| cell | plate px | lit px | ink share | containment | segs | verdict |
|---|---|---|---|---|---|---|
| `ui_seg_0` | 1518 | 1310 | 0.8630 | **1.0000** | 6 | PASS |
| `ui_seg_1` | 1518 | 526 | 0.3465 | **1.0000** | 2 | PASS |
| `ui_seg_2` | 1518 | 1082 | 0.7128 | **1.0000** | 5 | PASS |
| `ui_seg_3` | 1518 | 1166 | 0.7681 | **1.0000** | 5 | PASS |
| `ui_seg_4` | 1518 | 910 | 0.5995 | **1.0000** | 4 | PASS |
| `ui_seg_5` | 1518 | 1082 | 0.7128 | **1.0000** | 5 | PASS |
| `ui_seg_6` | 1518 | 1258 | 0.8287 | **1.0000** | 6 | PASS |
| `ui_seg_7` | 1518 | 742 | 0.4888 | **1.0000** | 3 | PASS |
| `ui_seg_8` | 1518 | 1518 | 1.0000 | **1.0000** | 7 | PASS |
| `ui_seg_9` | 1518 | 1342 | 0.8841 | **1.0000** | 6 | PASS |
| `ui_seg_pct` | 1518 | 650 | 0.4282 | **1.0000** | 5\* | PASS |
| `ui_seg_blank` | 1518 | 0 | 0.0000 | **1.0000** | – | PASS |

- containment ≥ 95 % on every cell: **PASS** (1.0000 on all twelve)
- blank smallest of all: **PASS** (blank 0.0000, next 0.3465)
- `1` smallest of the digits: **PASS** (1 0.3465); `8` largest: **PASS** (8 1.0000)
- by-segment order (more lit segments ⇒ more ink): **PASS**, no inversions
- literal `1 ≤ 2 ≤ … ≤ 8`: **does not hold** — impossible for a seven-segment font (segment counts
  `1→2, 2→5, 3→5, 4→4, 5→5, 6→6, 7→3, 8→7`). Reported, not enforced; the same finding D6-M0 recorded
  (`_state/LOW_BACKLOG.md` L145).
- **AC5 verdict: PASS.**

\* the `segs` column reads 5 for `ui_seg_pct`, which is the first-pass *generated* percent sign
(`a,f,g,c,d`). The authored lattice is `seg_geometry.PCT_SEGMENTS = "f,g,c"` — **3 segments**, per the
D6 cure that replaced the slash with seven-segment dots-and-stroke. The stale constant is a reporting
column only: `qc_seg_digits.SEGMENTS` is read by no verdict (by-segment ordering iterates the ten
digits), so the tool was left byte-identical. Finding below.

## 3. Reconcile — every shipped D7 master against §12

`python3 staging/phase_g/reconcile_d7.py --json staging/phase_g/ui/reconcile_d7.json` reads the
shipped bytes, not the logs. §11/§12 names 23 masters in the family (6 panel/frame masters + 12 digit
cells + the 5 instruments the cockpit still reuses).

| file | present | box | pinned | logical | verdict |
|---|---|---|---|---|---|
| `ui_cockpit_panel` | yes | 928×512 | 928×512 | 464×256 | OK |
| `ui_gauge_face` | yes | 240×240 | 240×240 | 120×120 | OK |
| `ui_armory_console` | yes | 1744×1816 | 1744×1816 | 872×908 | OK |
| `ui_armory_rack_plate` | yes | 194×182 | 194×182 | 97×91 | OK |
| `ui_armory_row_plate` | yes | 192×64 | 192×64 | – | OK |
| `ui_status_panel` | yes | 1440×1040 | 1440×1040 | 720×520 | OK |
| `ui_cockpit_frame` | yes | 192×192 | 192×192 | – | OK |
| `ui_gauge_needle` | yes | 16×192 | 16×192 | 8×96 | OK |
| `ui_compass_rose` | yes | 192×192 | 192×192 | 96×96 | OK |
| `ui_compass_lubber` | yes | 32×24 | 32×24 | 16×12 | OK |
| `ui_readout_glass` | yes | 272×380 | 272×380 | 136×190 | OK |
| `ui_seg_0` … `ui_seg_9` | yes | 48×88 | 48×88 | 20×36 | OK (×10) |
| `ui_seg_pct`, `ui_seg_blank` | yes | 48×88 | 48×88 | 20×36 | OK |

**23/23 present, no box mismatch.** Provenance panels under `assets/icons/`: `panel_cockpit` 2048×2048,
`panel_gauge` 2048×2048, `panel_armory` 2048×2048, `panel_armory_plates` 2048×2048, `panel_status`
2048×1536 (its render canvas is 4:3) — all five present.

## 4. Import settings unified, and the reimport

`staging/phase_g/import_settings_d7.py` rewrites only the three `[params]` lines of a sidecar
(`[remap]`/`[deps]` and every other param stay byte-identical, so the editor keeps the uid and imported
path it already derived); the pre-rewrite sidecars are snapshotted to
`staging/phase_g/ui/_a1b_backup/import/`. Applied to the five panels that still carried the editor
defaults — the twelve digit cells and `ui_gauge_face` already read the unified set.

| file | before | after | sidecar lines changed |
|---|---|---|---|
| `ui_cockpit_panel` | `mipmaps=false, mode=0, detect_3d=1` | `true / 0 / 0` | 2 (`mipmaps/generate`, `detect_3d/compress_to`) |
| `ui_armory_console` | `false / 0 / 1` | `true / 0 / 0` | 2 |
| `ui_armory_rack_plate` | `false / 0 / 1` | `true / 0 / 0` | 2 |
| `ui_armory_row_plate` | `false / 0 / 1` | `true / 0 / 0` | 2 |
| `ui_status_panel` | `false / 0 / 1` | `true / 0 / 0` | 2 |
| the 12 `ui_seg_*` + `ui_gauge_face` | `true / 0 / 0` | unchanged | 0 |

A second run of the tool reports **0 needing the set** (`staging/phase_g/ui/import_settings_d7.json`),
so the state is idempotent.

**Reimport in the quiet window.** The editor session `vajb-orbit@86fd6072c72f957c` was live and idle
(`readiness ready`, `play_state stopped`, no game running), so the reimport ran **through the open
editor**, never a second engine instance. `filesystem_manage reimport` on the 17 changed paths
answered `reimported_count: 17`, but **nothing was written to `.godot/imported/`** — the call registers
the files, the import itself drains in the editor's scan pass. `filesystem_manage scan` (settled,
`global_classes_registered_delta: 0`) ran the import; `.godot/imported/` was rewritten at that point.
Recorded as a workflow finding: **`reimport` alone is not enough on this editor build; follow it with
`scan`.**

Final import state (`staging/phase_g/ui/import_state_d7.json`; every `.ctex`'s cached `source_md5`
equals its shipped source):

| file | box | ctex before | ctex after | Δ | cache |
|---|---|---|---|---|---|
| `ui_cockpit_panel` | 928×512 | 581 486 | 779 570 | +198 084 | current |
| `ui_gauge_face` | 240×240 | 73 344 | 73 344 | 0 | current |
| `ui_armory_console` | 1744×1816 | 4 121 006 | 5 446 836 | +1 325 830 | current |
| `ui_armory_rack_plate` | 194×182 | 22 994 | 32 808 | +9 814 | current |
| `ui_armory_row_plate` | 192×64 | 8 300 | 12 354 | +4 054 | current |
| `ui_status_panel` | 1440×1040 | 1 834 966 | 2 423 720 | +588 754 | current |
| `ui_seg_0` | 48×88 | 7 866 | 1 362 | −6 504 | current |
| `ui_seg_1` | 48×88 | 7 810 | 1 456 | −6 354 | current |
| `ui_seg_2` | 48×88 | 7 906 | 1 494 | −6 412 | current |
| `ui_seg_3` | 48×88 | 7 902 | 1 356 | −6 546 | current |
| `ui_seg_4` | 48×88 | 7 902 | 1 456 | −6 446 | current |
| `ui_seg_5` | 48×88 | 7 922 | 1 504 | −6 418 | current |
| `ui_seg_6` | 48×88 | 7 918 | 1 460 | −6 458 | current |
| `ui_seg_7` | 48×88 | 7 884 | 1 530 | −6 354 | current |
| `ui_seg_8` | 48×88 | 7 890 | 1 198 | −6 692 | current |
| `ui_seg_9` | 48×88 | 7 898 | 1 362 | −6 536 | current |
| `ui_seg_pct` | 48×88 | 7 900 | 1 566 | −6 334 | current |
| `ui_seg_blank` | 48×88 | 7 830 | 1 224 | −6 606 | current |

The five panels' `+34 %` growth is the mip chain the flag change adds (the `mipmaps/generate=true`
proof); `ui_gauge_face` is unchanged because its sidecar already read the unified set. The digit cells
shrink ~80 % because the glyph-only PNGs compress far better losslessly than the plate-composited ones.
A1's Deviation 8 (a six-file stale cache) no longer applies: every one of the six now matches.

## Deviations and findings

Buckets per the `AGENTS.md` escalation ladder.

1. **`qc_seg_digits.SEGMENTS["ui_seg_pct"] = 5` is stale against the authored lattice (bucket 1,
   reporting column only).** `seg_geometry.PCT_SEGMENTS = "f,g,c"` is the set `seg_svg_digits.py`
   rasterised, and the D6 report records the cure (the slash could not pass containment, and the
   first pass's `a,f,g,c,d` was literally the digit 5). The dict's value is read by no verdict, so the
   tool was left **byte-identical** for this re-run and the correction is reported instead: read the
   column as `3` for `ui_seg_pct`, or set `SEGMENTS["ui_seg_pct"] = 3` in a tool pass outside a QC
   re-run.
2. **The brief's "`ui_seg_*` stay byte-identical" hard rule is superseded (bucket 3 — already ruled).**
   A0 recorded the contradiction (Deviation 7); the owner's approval of the plates, with §12's
   post-mockup amendment as the newer doc text, is the ruling this step executes. `ui_compass_*`,
   `ui_gauge_needle`, `ui_cockpit_frame`, `ui_readout_glass`, `ui_gauge_face` and the two armory
   plates remain byte-identical. **Reversal:** copy `_a1b_backup/ui_seg_*.png` back and reimport.
3. **Direct-at-48×88 rasterisation replaces the D6 supersample+LANCZOS (bucket 1, measured).** See
   §1. **Reversal:** restore the `SS` supersample in `seg_glyph_only.rasterise`.
4. **The glyph-only prepared masters live in `ui/_seg_glyph/`, not `ui/_masters/` (bucket 1).** The
   plate-composited D6 masters stay in `_masters/` as the D6 record, and `ship_d6.py`'s `PREPARED`
   route string for the digit cells still names `seg_svg_digits.py` — **a future `ship_d6` run would
   re-ship the plate masters over the glyph-only ones.** Flagged for whoever next runs that tool: point
   `ship_d6.PREPARED` at `seg_glyph_only.py` / `_seg_glyph/` before re-shipping the family.
5. **`filesystem_manage reimport` does not by itself reimport on this editor build (bucket 1,
   workflow).** `reimport` answers success for 17 paths while `.godot/imported/` is not rewritten; the
   following `filesystem_manage scan` performs the import. Recorded in §4; worth a line in the
   environment skill if it repeats.
6. **No D7 rendering artifact for the glyph family was commissioned (bucket 1, deliberate).** The
   amendment says "no paid generation", and the lattice is hand-authored, so the 12 cells have no
   render, no job id and no provenance panel; `staging/phase_g/ui/_seg_glyph/` plus this report are
   their provenance. Review image: `staging/phase_g/_review/d7a1b_seg_glyph.png` (the twelve cells at
   4× on a dark backdrop).

## Evidence

```
python3 staging/phase_g/seg_glyph_only.py [--ship] [--preview <png>]      # re-author + ship the 12
python3 staging/phase_g/qc_seg_digits.py --dir staging/phase_g/ui/_seg_glyph \
        --json staging/phase_g/ui/qc_seg_glyph.json                       # AC5 re-run (tool unmodified)
python3 staging/phase_g/reconcile_d7.py --json staging/phase_g/ui/reconcile_d7.json
python3 staging/phase_g/import_settings_d7.py                             # check
python3 staging/phase_g/import_settings_d7.py --apply --json staging/phase_g/ui/import_settings_d7.json
# then, editor live and idle: filesystem_manage op=reimport (17 paths) -> filesystem_manage op=scan
```

Logs/artifacts: `staging/phase_g/ui/qc_seg_glyph.json`, `reconcile_d7.json`,
`import_settings_d7.json`, `import_state_d7.json`, `_a1b_backup/{MANIFEST.md5,README.md,import/}`,
`staging/phase_g/_review/d7a1b_seg_glyph.png`.

## Files touched

- `vajb-orbit/assets/ui/` — the **12 `ui_seg_*` masters replaced** (glyph-only bytes; table above) and
  **5 `.import` sidecars** (`ui_cockpit_panel`, `ui_armory_console`, `ui_armory_rack_plate`,
  `ui_armory_row_plate`, `ui_status_panel`) unified to `mipmaps=true / mode=0 / detect_3d=0`
- `vajb-orbit/.godot/imported/` — 18 reimported `.ctex`/`.md5` pairs (editor-written, gitignored)
- `staging/phase_g/seg_glyph_only.py` — **new**: the glyph-only re-authoring + ship step
- `staging/phase_g/reconcile_d7.py` — **new**: name/box/import reconciliation against §11/§12
- `staging/phase_g/import_settings_d7.py` — **new**: the unified import settings for the wave
- `staging/phase_g/ui/_seg_glyph/`, `_a1b_backup/`, the four JSONs, `_review/d7a1b_seg_glyph.png`

No `game/`, `autoload/`, `project.godot`, `ui/theme/`, `ui/hud/**`, `ui/station/**`, `docs/`,
`addons/` or test file was touched; no paid generation ran (spend **$0.00**). Binary PNGs are
gitignored by design, so the digit-family bytes are verified by the md5 table above rather than by
`git status`.
---

# D7-A2 — the armory console re-rendered on the ruled canvas (UI_SPEC §3.10 Amendment 2)

**Written by D7-A2, appended to A0's report.** Task: re-render **only** `ui_armory_console` as a
flat painted plate at **1744×1912** (2× the ruled 872×956 canvas, `UI_SPEC` §3.10 Amendment 2, the
D7-R1 MED-1 ruling) — plate texture only (brushed steel, bolt heads, plate seams), **no wells and
no recesses**; Phase G lane order (render → `panels.py --detect` → cut each → key each → trim); §12
QC minus the retired well rows; back up the current master + its provenance panel first; ship under
the same names. **This run ships directly** — the look is owner-approved already (A1's flat-plate
subject kept verbatim apart from the outline clause, and only the canvas aspect is corrected), so
there is no approval stop between the render and the ship. **No code.**

## Result

| shipped file | box | cut box | fit scale | ink containment | ink share | md5 |
|---|---|---|---|---|---|---|
| `assets/ui/ui_armory_console.png` | **1744×1912** | 1929×2064 | 0.9041 | **100.00 %** | 95.97 % | `4f97aa94` |
| `assets/icons/panel_armory.png` | 2048×2048 (provenance render) | — | — | — | — | `34dc944b` |

(The coverage probe's `scale 0.9079` is its ink-box model of the same fit — it measures the render
before the cut exists; the shipped cut's real fit scale is 0.9041, both reported by `qc_d7_a1.py`.)

§12's QC minus the well rows: `box_match=True` for all six masters and ink containment **100.00 %**
on every cut (`staging/phase_g/ui/qc_d7_a2_shipped.json`, ≥ 95 % required); `reconcile_d7.py` reads
**23/23 masters present, no box mismatch, import unified** now that its table carries the
Amendment-2 box (`staging/phase_g/ui/reconcile_d7.json`). `ui_cockpit_panel`, `ui_status_panel`,
`ui_gauge_face`, `ui_armory_rack_plate` and `ui_armory_row_plate` were re-staged and verified
**byte-identical** to what already ships (`e238e6f5` / `c8c0df57` / `860c1ce5` / `acf82595` /
`b1568ade`) and were not re-copied into the project.

**The MED-1 defect is closed as measured:** the plate now covers **100.00 %** of the pinned well
union (y 244–1864 of the 1912 box) with a render ink aspect of **0.930 against the box's 0.912**,
filling **99.14 % × 97.23 %** of the box (A1's plate filled 99.20 % × 95.43 % of the *retired* 1816
box, and against the pane's drawn `ConsolePlate` size — measured by D7-R1 at **872×956**, exactly
the ruled canvas — the 1816 master was a 5.29 % vertical fill-stretch). The master is now exactly
**2× the drawn block on both axes** (1744/872 = 1912/956 = 2.0), so nothing stretches: Amendment 2's
whole point. Measured by `qc_d7_a1.py`'s own geometry
(`staging/phase_g/ui/qc_d7_a2_coverage.json`).

## Why the plate had to be re-rendered rather than re-fitted, and the eight passes it took

`contain` puts a plate at `W = 1744` and `H = 1744 / aspect` when the plate is wider than the box
and at `H = 1912` and `W = 1912 × aspect` when it is taller. Covering the union (x 60–1684,
y 244–1864) with a **centred** plate therefore needs the plate's drawn rect to be at least
**1624 × 1816** — the width is the union's own 1624, and the height is the union's 1864 bottom edge
doubled about the box centre (2 × (1864 − 956)) — so the cut aspect must be in **[0.855, 0.960]**.
A square plate cannot reach it at all: a 2048 px canvas caps its contained height below 1744 px
(≈1730 for a 1946 px square), some 85 px short of 1816. A1's shipped render is 1965×1968
(aspect 0.998) and `contain`-fits the new box at 91.4 % of its height, which is why re-fitting was
not an option: the plate has to be a little taller than it is wide, but only by 4–15 %.

Eight passes, each measured the same way (ink box → cut aspect → well-union coverage). All renders
`flare` 2K, `style-block.txt` verbatim preamble, §12's framing sentence, §8's negatives, `pad_share`
0.0:

| pass | run folder | canvas | job id | ink box | cut aspect | union | verdict |
|---|---|---|---|---|---|---|---|
| p1 | `20260924-123123` | 1:1 | `c3a7245583f68d7e79920dc7adff533f` | 1667×2025 | 0.823 | 96.18 % | rejected |
| p2 | `20260924-123236` | 1:1 | `e3ed8d5bdf9607335f12eefad9918570` | 1946×1940 | 1.003 | 96.62 % | rejected |
| p3 | `20260924-123344` | 1:1 | `3c405addb1d663b0da4c3f58ecea679d` | 1385×1976 | 0.701 | 81.83 % | rejected |
| p4 | `20260924-123458` | 1:1 | `3409d72fa46666d8e3e5e19a7a6d4742` | 1663×2000 | 0.832 | 97.11 % | rejected |
| p5 | `20260924-123645` | 1:1 | `eb62e4d3d3bd6675e91933a18416b1b7` | 1493×2030 | 0.735 | 85.90 % | rejected |
| p6 | `20260924-123758` | 3:4 | `007f2af928e7a0d8971c4a1da6b833ef` | 1182×1930 | 0.612 | 71.49 % | rejected |
| p7 | `20260924-123919` | 1:1 | `0f60165b9f309065f9151d5d9b76b4d6` | 1473×2035 | 0.724 | 84.54 % | rejected |
| **p8** | **`20260924-124037`** | **1:1** | **`a637f6eb2dcaa337a2228b49800c40c1`** | **1905×2048** | **0.930** | **100.00 %** | **SHIPS** |

The measured lesson: on a 1:1 canvas the model has exactly **two modes** — it either fills the frame
(aspect ≈ 1.00, p2) or draws a portrait plate (0.70–0.83, p1/p3/p4/p5/p7) — and no wording landed
between them (the ratio words 0.90/0.95/nine-to-ten all came back at or below their ask; "a tenth
taller than it is wide" came back 0.70; the 3:4 canvas made it narrower still). Pass 8 is the only
self-consistent instruction: it keeps the frame-filling mode on the **vertical** axis ("the plate
reaching the frame's top edge and bottom edge") and puts the missing ~6 % of width in two named
white strips at the sides, so the plate is ~1792×2048 rather than a compromise between two
contradictory clauses. The full wording is `wave_g.UI_D7_ARMORY_CONSOLE_FLAT_A2`; every earlier
pass stays in its own run folder as provenance.

Cut/key order (`refit_panels.py`, one object on a 1×1 grid): ink 1905×2048 → alpha 1913×2048
**PASS** (one billed `recraft/remove-background` call) → `trim_centre` → `1929×2064`.

## Deviations from §12 / the brief

Buckets per the `AGENTS.md` escalation ladder.

1. **Eight renders, not one (bucket 1 — cost, reported).** §12's two-step remedy is "one re-render,
   then the fallback"; that rule is for a render whose **wells** do not line up, and Amendment 2
   retired the well rows for this panel. What failed here is the **plate's own aspect against the
   new box**, which §12 does not address at all (A1's Deviation 6 proposed exactly that wording:
   "*the three flat plates' render outline matches the pinned master box's aspect (±5 %)*"). The
   first seven passes are the measured search for an aspect in [0.855, 0.960]; the spend is
   **8 × 2K = 80 credits ≈ $0.40** real (10 credits = $0.05 per 2K, the `AGENTS.md` basis; the
   script's printed estimate over-reports 3×) plus **1 recraft key ≈ $0.005**, and it is recorded
   here rather than hidden. **Reversal:** no further spend — the shipped pass is the covering one.
2. **The render canvas moved to 1:1 with a width-strip clause (bucket 1 — route).** Amendment 2
   drops the `recessed well` phrases but says nothing about the plate's outline; A1 added an
   outline-proportion clause and a canvas pinned to the box's nearest supported aspect. Both are
   kept, but the 0.912 box has no matching canvas (1:1 is 0.088 away, 3:4 is 0.162), so the outline
   is steered in words and the canvas stays at the nearest supported 1:1. **Reversal:** restore the
   A1 wording and accept a plate that covers the union only ~96 %.
3. **The staging constants carry the Amendment-2 box now (bucket 1).** `wave_g.UI_D7_LOGICAL`
   (`872×956`) / `UI_D7_MASTER` (`1744×1912`), `qc_d7.BOXES`, `qc_d7_a1.WELL_UNIONS` (the ammo well
   grown to the Amendment-2 136 → `(60,1592)-(1684,1864)`), `reconcile_d7.TABLE` and
   `ship_d7.py`'s plan/log all move together, so the QC measures the shipped bytes against the
   ruled box. The retired 872×908 / 1744×1816 pair stays in the pass tables and in A1's section as
   the record. **Reversal:** the `_a2_backup/` restore block below.
4. **A2's provenance panel is the new flat render (bucket 1).** `panel_armory.png` now carries the
   pass-8 render (2048×2048) that `4f97aa94` was cut from; A1's render is the one in
   `_a2_backup/renders/`. `ship_d7.py`'s `PANEL_NAMES_A1` and `PLAN_RUNS` lead with the A2 run so
   the console's plate and provenance both come from it.
5. **The reimport needs a `scan` before a `reimport` (bucket 1 — process finding).** The first
   `filesystem_manage reimport` reported both paths reimported but left the cache stamp on the old
   source (`a8382b40`); a `filesystem_manage scan` followed by the same reimport rewrote both
   `.ctex` pairs at 12:42:46 with `source_md5` = the shipped bytes (`4f97aa94` / `34dc944b`). This
   sharpens A1b's own import note: after an out-of-band byte write, scan first, then reimport, then
   check the stamp — the `reimported` list alone is not evidence the cache moved.
6. **The armory rack plate's well row still FAILs (A0's standing finding, unchanged).** `qc_d7.py`
   reports `worst_recess_ratio 1.112`, `centre_inside=False` on all four slots; `ui_armory_rack_plate`
   is A0's bytes and is not one of the plates Amendment 2 re-renders (A1's Deviation 9 already
   records it). Not fixed here.

## Evidence

Commands (host-neutral, from `$VAJB_WORKSPACE`; the interpreter is Linux `python3` under
`uv run --with numpy --with pillow --with scipy`):

```
python3 staging/phase_g/wave_g.py panel_armory_console_flat_a2           # 8 × 2K, 1 paid call each
python3 staging/phase_g/panels.py --detect <render> --grid 1x1 --page ... --json ...
python3 staging/phase_g/qc_d7_a1.py <render> --panel ui_armory_console --pad-share 0.0
python3 staging/phase_g/refit_panels.py panel_armory_console_flat_a2    # cut -> key -> trim
python3 staging/phase_g/ship_d7.py --replace --only ui_armory_console   # stage, copy, log
python3 staging/phase_g/qc_d7_a1.py --shipped --json .../qc_d7_a2_shipped.json
python3 staging/phase_g/qc_d7.py --json staging/phase_g/ui/qc_d7_a2.json
python3 staging/phase_g/qc_d7_a1.py --json .../qc_d7_a2_coverage.json
python3 staging/phase_g/reconcile_d7.py --json staging/phase_g/ui/reconcile_d7.json
python3 staging/phase_g/build_review_d7_a2.py
# then, editor live and idle: filesystem_manage op=scan -> op=reimport (both changed paths)
```

Logs/records: `staging/phase_g/ui/_a2_render.log`, `_a2_refit.log`,
`_a2_detect_panel_armory_console_flat_a2.{json,jpg}` (pass 1) and `..._p2` … `..._p8` for the rest,
`_a2_backup/{MANIFEST.md5,README.md}`, `qc_d7_a2_shipped.json`, `qc_d7_a2.json`,
`qc_d7_a2_coverage.json`, `reconcile_d7.json`, `_review/d7a2_console.png` (760×1984) / `.jpg`
(176 KB) — the plate at its logical box and 2×, the well-union coverage overlay, and the eight-pass
table with the chosen render and cut.

## Files touched

- `vajb-orbit/assets/ui/ui_armory_console.png` — **replaced** (1744×1816 → **1744×1912**,
  `a8382b40` → `4f97aa94`); its `.import` sidecar is unchanged (A1b's unified set already applies)
- `vajb-orbit/assets/icons/panel_armory.png` — **replaced** (the A2 flat render, `aa2fc8df` →
  `34dc944b`)
- `vajb-orbit/.godot/imported/` — the two reimported `.ctex`/`.md5` pairs (editor-written, gitignored)
- `vajb-orbit/assets/ui/generation_log_d7.md` — regenerated by `ship_d7.py` (A1's copy kept at
  `_a2_backup/generation_log_d7.md.a1`)
- `staging/phase_g/wave_g.py` — the Amendment-2 box, the A2 run + its flat subject, the pass table
- `staging/phase_g/ship_d7.py`, `qc_d7.py`, `qc_d7_a1.py`, `reconcile_d7.py` — the ruled box
- `staging/phase_g/build_review_d7_a2.py` — **new**: the A2 review sheet
- `staging/phase_g/ui/**` — the eight renders, `_cells/20260924-124037/`, `_masters/`, `_a2_backup/`,
  the QC JSONs and logs, `_review/d7a2_console.{png,jpg}`

No `game/`, `autoload/`, `project.godot`, `ui/theme/`, `ui/hud/**`, `ui/station/**`, `docs/`,
`addons/` or test file was touched, and the gate is unchanged (no `.gd`, `.tscn` or `.tres` moved —
art-only run, the same basis A0/A1/A1b report on). Binary PNGs are gitignored by design, so the
shipped bytes are verified by the md5 tables above rather than by `git status`.

## Follow-ups

| Item | Kind | Where |
|---|---|---|
| §12 should state the aspect rule this run had to discover: the three flat plates' render outline matches the pinned master box's aspect (±5 %), so the plate covers the box it ships in | docs finding (bucket 2 — pinned wording; A1's Deviation 6, now with two measured runs behind it) | `docs/design/UI_CHROME_ASSETS_SPEC.md` §12 |
| The 872×956 canvas has no supported `flare` render aspect (1:1 is 0.088 away, 3:4 is 0.162), so the plate's outline has to be steered in words; a future re-render of this panel should reuse pass 8's width-strip clause | route note (bucket 1) | `staging/phase_g/wave_g.py` (`UI_D7_ARMORY_CONSOLE_FLAT_A2`) |
| The armory rack plate's slot row still fails its registration QC (A0's standing finding) | art finding | `D7-A0_report.md` §"Well measurements", `qc_d7.py` |
| After an out-of-band asset write, `filesystem_manage reimport` alone left the cache stale — `scan` first, then `reimport`, then verify the `source_md5` stamp | process note (bucket 1) | `staging/phase_g/import_settings_d7.py`'s note |
