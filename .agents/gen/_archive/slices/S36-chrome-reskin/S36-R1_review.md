---
slice: S36
reviewer: S36-R1
verdict: blocked (HIGH F1 remains — owner ruling required)
gate: "1150/0 (reviewer's own fresh-scratch run, --quit-after 1200) == B1's claimed after-gate"
---

# S36-R1 review

Method: everything re-measured, never eyeballed. (1) Pillow re-scan of every cut — I
replicated BOTH published margin methods (`D21-G2-R1_measure4.py` `margins4` and the
builder's `g2_driver.py` `measure_margins`) and reproduced both tables exactly
(`tests/probe_s36_r1_measure.py`); the wired values equal the per-side max of the two
and my own re-measurement, 0 px deviation on every side. (2) A live scene probe
(`tests/probe_s36_r1_scene.gd`, headless, self-quit) mounts the shipped station and
prints every chrome surface's drawn rect, stylebox margins, canvas fit, bay rects and
backdrop boxes per deck. (3) The nine-patch degrade behaviour is read from the engine
source (`servers/rendering/renderer_rd/shaders/canvas.glsl`, `map_ninepatch_axis`).
(4) The gate re-run fresh. Keep-list greps + the diff audited for scope.

## Acceptance list

1 — pass — every wiring-table cite verified in the diff and in the live tree
(inspect_chip.gd:26, tooltip.gd:38, station.gd:571+792, overview:264/340/406,
exchange:430/569/648, auction:824, shipyard:230/398, refinery:165/408/708,
launch:210/404, armory:734/805/984/4130); git diff touches only swap-map files +
chrome_family.gd + the suite (the docs/CODE_MAP working-tree diff only adds D21's
probe_b3_diag.gd — it predates B1).
2 — pass — margins re-measured by me with both published methods: R1 8/34/20/39 +
builder 24/24/23/23 → C3; 70/73/32/49 + 74/74/35/35 → C4; 22/43/50/64 + 22/22/50/50 →
C7; wired == max == mine per side (chrome_family.gd:53-57).
3 — pass — every cut matches its §15.1 master within 1 % (C1 1134×280, C2/C9 720×112,
C3 192×64, C4 1120×152, C5 520×384, C6 2720×1032, C7 720×480, C12 192×192); C9's
6.43:1 vs §15.1's 272×56 is B1's disclosed deviation (§15.6's "drawn shape" ruling;
follow-up ticketed); every drawn canvas preserves the cut aspect exactly
(aspect_err 0.00000 on all 40+ canvas records).
4 — drift — F1: every nine-slice plate renders in the engine's degenerate regime (drawn
rect shorter than its margins sum); F5: one chip stretches beyond C3's band ceiling.
5 — pass — the console face is retired from the pane (test_s20 AC1); every whole-face
draw is `STRETCH_KEEP_ASPECT_CENTERED` or `canvas_rect` aspect-fit; no whole-face
stretch anywhere in the probe.
6 — pass — grep over the diff: zero size/position changes tied to hover/pressed; the
only `visible` writes are the backdrop deck switch (not a control state); states are
`tinted()` stylebox duplicates / StyleBoxFlats (chrome_family.gd:140-147, 209-238,
264-285).
7 — pass — keep textures re-measured 48×48 / 42×14 / 200×200; no changed file wires
them; the drawer plate, CANCEL/SELL (`StationButton` + `ui_button_plate_normal`) and
`MenuButtonPlate` are asserted by suite group c and untouched in the diff.
8 — pass — `DECK_BACKDROP` verified against `Module` (OUTFITTING..LAUNCH, OVERVIEW=6):
BG-1 ARMORY / BG-2 REFINERY / BG-3 EXCHANGE+AUCTION / BG-4 SHIPYARD+LAUNCH+OVERVIEW;
layers `STRETCH_KEEP_ASPECT_COVERED`, `MOUSE_FILTER_IGNORE`, indices 0-3 behind
HostMargin(4), only the assigned layer visible per deck; the live box is 1808×796, not
the pinned 1765×753 → F6 (LOW).
9 — pass — the four hard-class cuts draw whole and uniformly, never cropped (probe:
C1 567×140 in 575-wide slots, C2 360×56 fills, C9 272×42.3 in 272×56 slots, C5
aspect-fit); the bay slot's stale doc number is F3, not a crop.
10 — pass — `test_s36_chrome_census.gd` ships the four groups / 12 rows; my own
fresh-scratch gate reads `[SUMMARY] passed=1150 failed=0` (= 1138 + 12, zero moved).
11 — pass — the report answers 1–10 item by item with cites at exactly 120 lines.

## Findings

| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| F1 | HIGH | ui/theme/chrome_family.gd:53-57,129-134 + every C3/C4/C7 surface | The measured margins exceed the drawn rects, so every plate renders degenerate: C4 rows 76 tall vs t+b 35+49=84, C3 chips 32 vs 23+39=62, C7 tooltip 60 vs 50+64=114. `map_ninepatch_axis` then maps caps 1:1 with no centre branch → a hard UV seam mid-plate (C4: texture row 34 jumps to 111) and one cap's inner band truncated, instead of §15.3's declared flat centre band. ~150 surfaces station-wide. Zeroing content margins (:129-134) removed the minimum-size guard that would have grown the rects to 84. | Owner ruling (bucket 2/3) — any fix touches a pin: margins under the measured bevel smear ornament (A2); rows over 76 break `ROW_HEIGHT`; §15.3's declared 12/8 under-covers the measured art |
| F2 | MED | refinery_panel.gd:165 + QueueRow/TransferRow | The four REFINERY bars live at 115/114/176/176×56 — far under C2's 272 h-band floor — so the C2 canvas letterboxes to 11-27 px slivers (probe canvas records). §15.1's P42 row assumed 360×56; the live RefineBox layout disagrees (A4: new plate or the §15.4-8 flat-chip escape, never this dress). | Developer/designer session (bucket 2 — the census row is stale) |
| F3 | MED | armory_panel.gd:805 + ConsolePanels._bay | Live bay rects are 876×116 ×5 (`test_s20` asserts the same five), not §15.1's pinned 260×192 — the C5 card draws 157×116 inside a wide strip, not the owner-approved sheet look (card ≈ filling 260×192). The wiring itself is uniform and uncropped. | Developer/designer session (bucket 2 — stale doc measurement) |
| F4 | MED | components/tooltip.gd:38 + chrome_family.gd:129-134 | The tooltip is a bare PanelContainer: its text inset WAS the panel stylebox's content margins, which the family zeroes — the label now draws under C7's 22-64 px bevel; and short tooltips (360×60 live) sit below C7's v-band floor 120 AND degenerate (114 > 60). | Developer/designer session (bucket 2; a fixer could restore content margins only for C7 — but that re-grows the tooltip's min size, an owner-visible change) |
| F5 | MED | shipyard StatsStack/ClusterInspectChip | The cluster INSPECT chip expands to 452×32 — C3's centre stretches ≈ 5.6× beyond the declared 80-160 band ceiling (A4). Renders cleanly; a band-law breach. | Developer/designer session (bucket 2) |
| F6 | LOW | screens/station.gd:792 + chrome_family.gd:81 | Backdrop layers cover the live ModuleHost content rect 1808×796 (aspect 2.271), not the pinned 1765×753 (2.344) — COVERED crops ≈ 57 px total horizontally; no stretch either way; `test_d` asserts only `>= BG_BOX`. | → ticket as `T-102`, not fixed here |
| F7 | LOW | screens/station.gd:737-744 | The station name plate (census row C4, content-width × 64) stays native — consistent with B1's identity-block deviation rationale but not disclosed for this surface. | → ticket as `T-103` |
| F8 | LOW | refinery_panel.gd:48,708 | JOB rows live at 56 tall — below C4's v-band floor 64 (A4) even independent of F1 (census says 76). | → ticket as `T-104` |
| F9 | LOW | docs/CODE_MAP.* | The generated code map does not yet carry `chrome_family.gd` / `test_s36_chrome_census.gd`; regenerate at close-out (the working-tree diff only adds D21's probe). | Close-out step, no ticket |

## Fix list for S36-F1

No fixer code change is legal inside the current pins — F1-F5 are all bucket-2/3. The
owner session needs one ruling plus one re-measure pass:

1. **F1 ruling (pick one):** (a) keep the measured margins and let surfaces grow to
   their margins sum (restore content margins; `ROW_HEIGHT` 76 → 84 — breaks a pin);
   (b) re-cut C3/C4/C7 with bands near §15.3's declared values (paid, §13.6 ceiling);
   (c) accept the seam as shipped. Reversal paths: (a) one line in `stylebox()`;
   (b) the §13 route; (c) none.
2. **F2/F3/F5/F8:** a re-measure pass over the live station (S35's job) to re-pin the
   census's stale use rects (RefineBox bars, bay strips, cluster chip, job rows), then
   re-class per A4 — the family is not re-wired until the census matches the live tree.
3. **F4:** if the owner keeps C7, restore content margins on the C7 box only (tooltip
   min height grows to 114 — inside its own declared band) or give the tooltip an inner
   margin container; fixer-legal, one file.

## Verified fixes

None yet — no fixer pass has run.

## Gate

Before (B1, disclosed): `[SUMMARY] passed=1138 failed=0`. After (my own run, fresh
`XDG_DATA_HOME`, `--quit-after 1200`): `[SUMMARY] passed=1150 failed=0`; all 12
`s36_chrome_census` rows PASS; no `[FAIL]` rows. Negative control: the gate's own
keep-group rows (test_s20 AC2 / test_d8) stayed green on my run.
