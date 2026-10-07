# S33-R1 review — shell v3: ARMORY two sectors + the exchange sell cluster

Reviewer: S33-R1 (`hyper/glm-5.3-flash` @ max) · 2026-10-05 · verdict: **blocked**
Method: brief + STATION_HUB §21.1/§21.2/§20.1 + UI_SPEC §14.1/§13.1/§11.1/§3.10 A5 +
09 §10–§12 read; full diff of the four ui files + seven test files read; gate ×2 on
fresh scratch; probes `tests/probe_s33_review.gd` (ARMORY P38–P40 + A5.5 + doors) and
its exchange section (N48/N49), left in the tree as evidence. The D21 docs diffs in
the working tree belong to the parallel docs wave and are out of scope here.

## Gate

`[SUMMARY] passed=1118 failed=0` twice (`XDG_DATA_HOME=$(mktemp -d)`, grep
`\[SUMMARY\]|SCRIPT ERROR`), zero `SCRIPT ERROR` lines — matches the report's claim.

## Acceptance list (graded 1–7)

1. **P38 layout — PASS.** Probe: `%FitLeft`/`%FitRight` equal at both hosts
   (952/952 @ 1920×1080, 688/688 @ the pinned host per report), 16 px gutter,
   grid + CELL INFO left, list + band right. Containers only (A5.2).
2. **P38 semantics — FAIL (F1).** Tags, order, legality, BUY/INSPECT, select-to-fit,
   drag-to-fit and the inert browse press all verify — but the browse state's row set
   reads the bag only, so an owned module fitted with no bag spare never lists.
3. **P39 — PASS.** Sectors equal (952/952); rack drag persists through the profile
   door (probe: seed `[[0],[2]]` → drag rack2's barrel onto rack0 → read-back
   `[[0,2]]`); EQ tabs (9 categories), `×n` count rows, INSPECT chip, band all present.
4. **No wide blocks / no foot band — PASS.** Probe + grep: `%FootBand`,
   `%InventoryRows`, `%InventoryScroll`, `%InventoryCaption` all null; scene carries no
   `FITS HERE`/`BUYABLE THAT FITS`/`FootBand`; script carries no retired symbols.
5. **N48 — PASS.** `SELL` idle/armed/stepped/cleared (probe b1 ×4); confirm strip
   keeps its count (`SELL 3 IRON ORE — GROSS 54 · FEE 10`).
6. **N49 — PASS.** Stack order measured (StepperRow 2 → SellUnitsRow 4 → cluster 5);
   floor 1, ceiling = row units (5), disabled + dim without a selection; a SELL press
   moved exactly the selector value (hold 5 → 2 for 3 units).
7. **P40 + gate — FAIL (F2, F3).** Bands + 160 px trim + containment verify (probe
   violations empty in both modes + exchange); gate ×2 green — but P40's "the mode
   hint line updates per mode **+ selection**" is unmet and one moved row died
   undisclosed.

## Pin table

| Pin | Grade | Note |
|---|---|---|
| P38 | **FAIL** | browse row set is bag-only (F1); everything else verifies |
| P39 | PASS | incl. the disclosed wells-band reading (F5) |
| P40 | **FAIL** | hint line never follows the selection (F2); bands/trim/containment pass |
| N48 | PASS | wording + counted confirm strip |
| N49 | PASS | order, bounds, disable, delta |
| P32/P34/P35/P41 (stand) | PASS / **MED** | pins hold in code; P32's only shipped test row died (F3) |

## Findings

- **S33-B1/F1 — HIGH — P38's browse state omits fitted-only owned modules.**
  `_equip_rows`'s browse branch sources rows from `_owned_total` (bag units,
  `armory_panel.gd:4113`, `:4497-4500` → `_bag_units` → `module_count`); a fitted
  instance leaves the bag (`player_profile.gd:1108` `take_instance`), so a module the
  profile owns only fitted never lists — P38's "browse everything the profile owns
  that the active hull can use" is unmet, and the FIT tag degenerates to "you hold a
  spare of something fitted" (probe DIAG: rocket fitted at W2, bag 0 → absent; laser
  fitted + 1 spare → FIT). The count cell then under-reports (laser: `OWNED ×1`,
  profile owns 2). The report's FIT/STORED deviation discloses the tag reading, not
  this row-set gap.
- **S33-B1/F2 — HIGH — P40's hint line never follows the selection.**
  `_update_hint` is called only from `_apply_mode` (`:1016`) and `_apply_style`
  (`:1192`); `_select` (`:3255`) and `clear_selection` (`:3295`) never refresh it.
  Probe `a3_hint_fit_cell` FAIL: with W2 selected the hint still reads the idle
  `PANE_HINT_FIT`, so `PANE_HINT_FIT_CELL` can never show. No test row covers the
  hint at all (the brief's §7 new-row list names none either — but the spec extract
  in §4 pins it).
- **S33-B1/F3 — MED — the P32 mode-switch test row died undisclosed.** The rewrite
  deleted `test_the_mode_switch_shows_exactly_one_mode`
  (`git show HEAD:vajb-orbit/tests/test_s32_armory_modes.gd:127`); no shipped suite
  now asserts exactly-one-mode-visible or the per-mode hint swap (grep: only the S32
  review probe reads them). P32/P41 stand, so the row had to move, not die; the
  report's blanket "rewritten to P38–P41" does not name it.
- **S33-B1/F4 — MED — the CELL INFO row silently lost its EMPTY assertion.** The kept
  row dropped "an empty cell reads EMPTY" (old
  `test_s32_armory_modes.gd:175-193` → new row keeps id/fitted/legal only); the
  armory suites no longer test `CellInfoFitted`'s EMPTY reading (P41: CELL INFO stands
  unchanged). Cheap restore alongside F3's row.
- **S33-B1/F5 — LOW — disclosed deviations accepted.** Wells band kept in the left
  rack sector (P34's empty-cells law needs a home; reversal recorded); 16 px gutter
  (§19.3's PaneBox is 12, the EXCHANGE body 16 — parity); legality line reads the OK
  wording on every listed row (the list is pre-filtered; refusal strings stay wired
  for dropped rows). All three are bucket-1 readings, disclosed with reversals.
- **S33-B1/F6 — LOW — stale comment names the retired block**
  (`armory_panel.gd:3697` "a FITS HERE row's own inventory drag"). Words only; the
  scene/script greps stay clean.

## A5.5/N24 + A5.2 + doors

- Hover/focus/selection mutate colour, `modulate` and text only: probe `a8_hover_freeze`
  OK (359 nodes, no rect/visible change across a browser-row hover cycle); the new EQ
  rows' hover path is the same modulate tween + popup emit (`:4057-4063`); the N49 dim
  is a `font_color` override. No layout mutation found in any hover path.
- Composition: the new surfaces are containers end to end (FitSectors/FitLeft/FitRight,
  BatterySectors/RackSector/EqSector, band HBoxes on `custom_minimum_size` columns, EQ
  rows on Margin/HBox/VBox). The only hand-placed children remain inside their own
  hand-derived boxes (`_position_card`), the A5.2 carve-out.
- Profile writes: every write goes through the public doors (`fit_module_at`,
  `clear_fit_slot`, `move_rack_cell` inside `move_barrel`, `install_weapon`,
  `ExchangeScript.sell`); no direct field write in the changed ui files.
- The buy-quantity selector going display-only for the sale is the pin's own shape
  (N49 gives the sale to `SELL UNITS`); the report's follow-up ticket is taste, correctly routed.

## Disclosure duty

Promised new rows all landed (sector equality ×2, two states incl. tags/legality, EQ
categories + counts, SELL wording, SELL UNITS bounds + disable, SELL's profile delta,
stack order, bands + 160 trim, containment). The named moved rows in d7/s15/s18/s10/
s29/p2b1/s5 all match their diffs. The "not moved" claim for s5_batteries_v2 /
s11_inspector / s20_chrome_unify / s30_shell is confirmed (untouched in the diff, green
in both gates). Exceptions: F3 (a row died) and F4 (an assertion died) — both
undisclosed; the s32 disclosure is a blanket "rewritten" that names neither.

## Verdict: **blocked** — fixer required (2 HIGH, 2 MED)

Fixer items (S33-F1, in order):
1. **F1**: source the browse state from bag units ∪ fitted bases — a fitted-only base
   lists (tag `FIT`, count reading its fitted state, e.g. `FITTED`), a bag-only base
   lists `STORED`, a base both fitted and in the bag lists `FIT` with its bag count;
   keep the family-tab filter. Re-run the two-state rows; add a row asserting the
   fitted-only module lists.
2. **F2**: call `_update_hint()` from `_select` and `clear_selection` (content swap,
   N31-legal); add a hint row (mode swap + selection + clear).
3. **F3**: restore the P32 row (exactly one mode visible both ways + hint swap) in
   `test_s32_armory_modes.gd`.
4. **F4**: restore the "an empty cell reads EMPTY" assertion in the CELL INFO row.
5. Re-run the gate ×2 fresh scratch; the disclosure duty re-checks F3/F4's rows in the
   fixer report. F5/F6 need no work (F6 may ride along as a one-word comment fix).
