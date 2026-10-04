---
slice: S32
worker: S32-R1
model: hyper/glm-5.3-flash
status: review
verdict: blocked (1 HIGH)
---

# S32-R1 review — S32-B1's ARMORY two-module rework

## Re-measurement (independent, not trusted from the report)

- Gate ×2 fresh scratch: `XDG_DATA_HOME=$(mktemp -d) ~/.local/bin/godot --headless --path vajb-orbit
  res://tests/headless_runner.tscn --quit-after 1200` → `[SUMMARY] passed=1110 failed=0` **twice**. Matches report.
- Probe: `vajb-orbit/tests/probe_s32_review.gd` (headless `--script`, self-quitting, bounded). 15 RESULT lines:
  14 OK, 1 FAIL (see F4). Probe left in place as evidence.
- P35 grep re-run independently on script+scene: only `anchors_preset` layout keys match; no preset/loadout/save surface. OK.

## Acceptance list grading (1-7)

1. **P32 two modes + switch — PASS.** Probe: FIT CELLS is landing mode; `set_mode(BATTERY)` hides FitCells /
   shows BatteryConfig and back; invalid mode id ignored. Both `%ModeFitCells`/`%ModeBatteryConfig` in `PaneHeader`
   (armory_panel.tscn:57-77), toggle buttons render at exactly 96×32 (min size measured 96.0×32.0) matching the
   P2 `ActionInline` idiom. Hint swaps per mode.
2. **P33 CELL INFO / FITS HERE / BUYABLE — PASS.** Probe: W1 → `W1 · WEAPONS CELL`, `FITTED · LASER MKII`,
   `POWER DRAW 1 · PWR 3 / 8`, `LEGAL · THIS CELL FITS`; empty W2 → `EMPTY`; E1 → `REFUSAL_MANDATORY` wording
   (`_refresh_cell_info` armory_panel.gd:2050, `_cell_legality` :2088). FITS HERE cross-asserted against an
   independent derivation (catalogue family + `ShipFit.fit_legal` on the candidate fit): `listed == expected`
   (w_cannon, w_rocket). Select-to-fit (`_on_fits_here_pressed` :2554) and drag-to-fit (`cell_drop` :3871) both
   wrote W2=cannon through profile doors. BUYABLE filtered to cell family, `BUY` charged credits and fitted e_ion.
3. **P34 racks — PASS.** Racks contain only fitted W cells (probe: racks [[0],[1],[2]] vs fit). Drag B2→B1 via
   `drag_barrel`/`drop` persisted: profile `battery_groups` read back as [[0,1],…]; write lands through
   `move_rack_cell` → `set_battery_groups` (player_profile.gd:1548) — the profile door, no new shape.
   `W3 — EMPTY` rows are read-only Labels (`_refresh_empty_cells` :2028). SALVO/cycle: mixed rack readout is the
   rocket's 12.0 s → figure 1200; `_rack_cycle` :2396 uses `maxf(interval_of(member))` = the slowest member (09 §11).
4. **P35 no presets — PASS.** Grep clean; no new profile shape.
5. **P36 foot band — PASS (acceptance as written).** `%FootBand` holds AmmoMargin + MeterLabel + REMOVE +
   BUY & FIT; visible in both modes, meter reads `PWR 4 / 8 · IF FITTED 4 / 8`; `%BodyScroll` gone from tree and
   scene. Pin-table caveat in F1.
6. **P37 row containment — PASS with note (F4).** All FITS HERE/BUYABLE row rects within x 0..1909 at 1920 wide;
   vertical overflow (rows to y 1269) lives inside the vertical `BrowserScroll`/`InventoryScroll` viewports, i.e.
   scrollable and reachable — N45's defect (unscrollable horizontal overflow) is cured.
7. **Gate + disclosure — PASS.** 1110/0 ×2 fresh scratch. Every moved row in the report was found in the diff
   (d7 ×3, s18 ×1, p2b1 ×1, s29 n45, s10 setup) and no undisclosed moved row exists; all six promised new rows
   landed in `test_s32_armory_modes.gd` (11 rows = the +11 count).

## Pin table

- **P32 PASS** — two full-screen modes, header switch, exactly one visible, pure visibility (`_apply_mode` :993).
- **P33 PASS** — three blocks shipped; refusal strings reused as the legality vocabulary (no second wording).
- **P34 PASS** — B1–B5 over fitted weapons, drag persists via the profile door, read-only EMPTY rows, SALVO/cycle.
- **P35 PASS** — no preset/save surface.
- **P36 PARTIAL — see F1 (HIGH).** Foot band OK, BodyScroll fold dead; **T-122's dead space did not die**.
- **P37 PASS** — lists are full-width columns; no 490 px half; 160 px trim law retained on rows.

## Findings

- **S32-B1/F1** — HIGH — P36's clause "T-122's dead space die with the rework" is unmet: BATTERY CONFIG retains the
  1360×516 console pinned at the host's top-left (`_lay` armory_panel.gd:1189-1192, `Console` at
  armory_panel.tscn:237), leaving large dead space right/below in the full-screen mode host; T-122 was ticketed to
  ride S32 (LOW_BACKLOG.md:934,947; STATION_HUB.md:1903). Disclosed with reversal (report §Deviations 1-2) — not
  silent — but the pin stays unmet, and every cure (centre/stretch the console) collides with the d7/s15/s18/s20
  pinned `block_size()`/`bay_rects()`/`well_rects()` rows, so this is an owner/designer ruling, not a worker choice.
- **S32-B1/F2** — LOW — `set_mode` also calls `_lay()` (armory_panel.gd:990), slightly beyond P32's "pure visibility
  operation"; measured harmless (no reflow of the mode roots, console idempotent), but drop the call or justify it.
- **S32-B1/F3** — LOW — MeterLabel silently re-themed `StationValue` → `StationCaption` (armory_panel.tscn:331);
  undisclosed cosmetic change, no test pins it (gate green), but per disclosure law it should have been named.
- **S32-B1/F4** — LOW — measured BUYABLE/FITS HERE rows extend to y 1269, past 1080 (probe `p37_rows_inside`);
  scroll-contained so reachable, but the acceptance's literal "within 1920×1080" only holds horizontally — the s32
  suite row asserts x only (test_s32_armory_modes.gd:393-411); consider asserting the scroll viewport instead.
- **S32-B1/F5** — LOW — FITS HERE with no selection falls back to the owned-weapon list and BUYABLE to the tab
  filter (disclosed, report §Deviations 3-4); acceptable judgment, reversal paths recorded.
- **S32-B1/F6** — LOW — new `_summary_hint` is placed by raw coordinates inside the console's hand-derived well
  (armory_panel.gd:1206-1208); consistent with the pinned console idiom, but it is new coordinate code under A5.2(i)
  — keep it inside the disclosed console-retention reversal.

## Disclosure duty

- All named moved rows verified in the diff; counts preserved (1110 = 1099 + 11 new rows, no row lost).
- All promised new rows landed (mode switch, CELL INFO, FITS HERE/BUYABLE filtering, regroup→set_battery_groups,
  W<n> — EMPTY, shared foot band, containment, no-preset).
- Deviations §1-§7 all carry reversal paths; F1's deviation is the only one that leaves a pin clause unmet.

## Verdict

**Blocked** — one HIGH (S32-B1/F1). Acceptance list 1-7 otherwise met; gate green ×2; profile writes stay inside
the public doors.

### Fixer / close-out items (S32-F1)

1. **F1 (needs owner/designer ruling first — escalation bucket 2/3):** pick the dead-space cure for BATTERY CONFIG:
   (a) centre the 1360×516 console in the mode host (no pinned number changes; visually balances the space), or
   (b) stretch/rebuild the console full-width (requires re-anchoring d7/s15/s18/s20 rect rows — pin edits).
   Implement the owner-chosen option, update T-122 in LOW_BACKLOG, and record the ruling. If the owner cannot be
   reached in this wave, (a) is the least-invasive interim and must be disclosed again.
2. **F2:** remove the `_lay()` call from `set_mode` (or justify it in one line) so mode switching is pure visibility.
3. **F3:** disclose the MeterLabel theme change in the report (or revert to `StationValue`).
4. **F4:** leave code as-is; optionally tighten the s32 containment row to assert the scroll viewport, not raw rects.
5. Re-run the gate ×2 fresh scratch after any change; counts move only with disclosure.
