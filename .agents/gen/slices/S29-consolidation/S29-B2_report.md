---
slice: S29
worker: S29-B2
model: "mimo-v2.6-pro (re-dispatch)"
status: actionable
gate: "1063/0 -> 1073/0 (x2, fresh scratch)"
---

# S29-B2 report

## Result
A4–A7 ship: the merged ARMORY (P4 split: the FITTING grid left on its own numbers, the
inventory browser right with the auction tab strip minus HULLS), the merged SHIPYARD (P5:
labelled stat pairs + comparison with deltas, `INSTALLED MODULES`, the repair block with
`NOMINAL` rows and the fee in the footer), the shell's folded rail 8→6 with the P7
template and the P1–P3 cluster, and A7's D17 leftovers inside both panes. Gate ×2 on
fresh scratch: `[SUMMARY] passed=1073 failed=0` both runs (1063 + 10 new `test_s29_station_panels` rows).

## Acceptance list answers
- **A4 — DONE** — grid left (48 px `SlotButtonWeapon` plates, gaps, glyph inset 6, sep 4,
  `SLOT LAYOUT · %d CELLS · %d ENGINES`, `PWR` meter — `armory_panel.gd:_make_grid_cell`,
  consts at :217-245); browser right with `MODULES · OWNED & BUYABLE` (P8) and the nine
  tabs minus HULLS (`_build_browser`, `BROWSER_TABS` :193); every row draggable
  (`BrowserRow._get_drag_data` → `drag_browser`); drops filtered by slot (`cell_drop`);
  the wrong-slot refusal = P9's `DROP REFUSED — <MODULE> FITS NO <SLOT> CELL` + the cell's
  own slot caption flashing 0.5 s (P10, `_refuse_drop`/`_flash_slot_caption`), never a
  colour alone; buy-into-cell one flow with the credits check first
  (`_fit_entry_at` — `fit_legal` → credits → `buy_module` → `fit_module_at`); hover through
  the existing `inspect_requested`/`describe()` chain (`_inspect_browser`); `e_hyperdrive`
  listed at tier 3 with `12 000 CR` (`test_s29_station_panels.gd:243-262`).
- **A5 — DONE** — labelled hull stat pairs kept (`shipyard_panel.gd:88-94` STAT_ROWS) and
  the comparison block with the A7 delta column (`_build_comparison`, `_refresh_comparison`);
  the selected hull's installed modules under P12's `INSTALLED MODULES` caption
  (`shipyard_panel.tscn`, `%InstalledCaption`); the repair block on
  `repairs_panel.gd:74-89`'s REPORT_ROWS minus `MISSING`/`FEE`, `NOMINAL` in `text_dim`
  (P13, `_build_repair_rows`/`_refresh_repair`), the fee only in the footer line
  (`REPAIR AVAILABLE · <n> CR` / `ALL SYSTEMS NOMINAL`, `RepairsPanelScript`'s own
  wordings), `REPAIR` the P1 ActionPrimary (360×56, rightmost) with `SET ACTIVE` its
  secondary; hover on hull rows, plates and damage rows through the chain
  (`_on_damage_hovered` + the `POOL <cur> / <max>` context line).
- **A6 — DONE** — the rail folds 8→6: ARMORY, REFINERY, EXCHANGE, AUCTION, SHIPYARD,
  LAUNCH (`station.gd:67-102`, enum + five arrays, P7's own order and icons); the P7
  template on both merged panes (PaneHeader with the module icon — D17-P2's missing-icon
  MED dies here — content split, P2 cluster, footer hint); the P1–P3 cluster (360×56
  `StationButton` plates, 16 px gutter, primary rightmost; the row-corner BUY a 96×32
  `ActionInline` chip) and the P6 fills: SHIPYARD publishes the active hull + worst pool,
  LAUNCH its ready line + arm instruction, through `inspect_requested`
  (`shipyard_panel.gd:publish_idle_summary`, `launch_panel.gd:publish_idle_summary`).
- **A7 — DONE** — no `DROP HERE` ghosts (the rack drop-cells' cue deleted,
  `armory_panel.gd:_build_drop_cell`; re-pinned as no-cue rows in test_d7/test_p2b1/test_s18);
  fit confirm `FITTED · <MODULE>` (P11) + the refusal toasts (P9 line, the shipped
  shortfall/overload/mandatory wordings); cell tooltips = the `<TYPE><n> · <MODULE or
  EMPTY> · OWNED ×<n>` naming line and the `CANDIDATE` → `IF FITTED` rename
  (`METER_PREVIEW`); hull-comparison deltas (`+0` on self-compare); the REPAIRS dead band
  resolved (the block is one right-column stack + the footer line + the cluster, no
  780 px gaps — the wireframe's own composition); scroll affordances where rows overflow
  (`BrowserScroll` and the body window's `BodyScroll`, A5.2 containers).
- **A8 — DONE** — gate ×2 fresh scratch `passed=1073 failed=0`; moved rows below.

## Moved test rows (suite:line — the L264 disclosure)
- `test_d7_armory.gd:456-462` — the empty-cell `DROP HERE` cue row → asserts NO cue (A7).
- `test_d7_armory.gd:325-328` — the console-plate host-inset row → the body now rides the
  scroll window under the split (asserted structurally). Body placement moved.
- `test_p2b1_outfitting_panel.gd:676-693` — T4's cue asserts → no-cue (A7); T7's chip rows unmoved.
- `test_p2b1_outfitting_panel.gd` `test_the_module_rows_are_retired_from_the_pane_its_scene_and_its_script`
  → renamed `test_the_module_rows_return_as_the_p4_inventory_browser` (P4/P8/P11 supersede
  S5's retirement row: the script now carries `STATUS_FITTED` etc. by law).
- `test_s18_armory_rework.gd:346-353` — T4's cue row → no-cue (A7).
- `test_s18_armory_rework.gd` `test_every_rect_derives_from_the_host_at_the_three_proofs` —
  rewritten: the body derives at the style's base numbers (deviation 4 below).
- `test_s11_inspector.gd:37-40,140-166` — the emitter set rows: 8 panes → 6, `DECLARERS_ONLY`
  empty, `_pane(6/7)` → the merged indices (P6/P7).
- `test_s11_describe.gd:247-268` — `test_fitting_title_is_the_identity_with_no_hint_verb`
  retargeted to the merged ARMORY's `_inspect_browser` (FITTING folds in; `const FITTING`
  → `LAUNCH`).
- `test_s20_chrome_unify.gd` (AC5 row) — "eight panes" → six (P7).
- `test_p2b_fitting_panel.gd:405-470` — `test_the_rail_entry_is_fitting_and_the_upgrades_pane_is_gone`
  → renamed `test_the_rail_folds_to_six_entries_and_the_fitting_tile_retires` (P7).
- `test_s21_stability.gd:905-922` — `test_booting_the_station_writes_nothing_to_user`'s two
  band rows `== ClockScript.now()` → `>` the fixture's stale bands (the exact-equality row
  raced the clock's second tick and flaked once mid-wave).
- NOT moved: `test_p1_repairs`, `test_p2b_services` (the brief's §8 expected movers) — their
  reads still pass because `repairs_panel.gd`/`fitting_panel.gd` stay shipped as the cited
  data homes (§17.2 names `repairs_panel.gd:74-89`; `auction_panel.gd:51` and
  `ui/hud/ship_status_screen.gd:58` preload them and `ui/hud/` is outside this worker's set);
  the merged surfaces are pinned by the new `test_s29_station_panels` rows instead.
- NOT moved: `test_s10_armory_input` (the brief's expected mover) — its five hit rows pass
  unchanged once the pane root regained full-rect anchors.

## Deviations (what, why, reversal)
1. **The D13 body rides below the P4 split** (bucket-2 owner flag): P4/§17.1 pin the split
   (grid left, browser right) and are delivered exactly; but §5.1/§5.11/09 §11-12 pin the
   battery racks and the five ammo packs, and no ruling retires them — dropping them would
   strand `PlayerProfile.buy_ammo` and `fit_into_rack` with no UI (an economy-loop hole).
   The racks band + barrel inventory + ammunition keep their own laws below the split (the
   body's readbacks keep their base derivation). Reversal: retire the bands for the strict
   wireframe read (P7's "nothing else").
2. **`CANDIDATE` → `IF FITTED`** (A7's rename; §17.1:1541 still spells `CANDIDATE`).
   PROPOSED, self-defining per D17-P1. Reversal: `CANDIDATE %d / %d`.
3. **Delta column** `DELTA` / `%+d` (`+150`, `+0`): PROPOSED (D17-P2 asked for +/- deltas,
   no format pinned). Reversal: the two shipped columns.
4. **The body derives at the base host** (`console_size_at_base`), not the live pane rect —
   it moved into a scroll window under the split. Reversal: re-derive from the pane rect.
5. **Row-press vs BUY**: a browser-row press fits (owned) or buys-then-fits (buyable) into
   the selected cell or the next free legal cell; the row-corner `BUY` and `BUY & FIT`
   always buy-then-fits (P4's literal "BUY … buys into the next free legal cell").
   Reversal: any other press/chip mapping.
6. Derived formats (reported, not pinned): cell tooltip = the shared
   `<TYPE><n> · <MODULE or EMPTY> · OWNED ×<n>` line; the flash word = the cell's own
   fit-slot word (`WEAPONS`/`ENGINES`/…); LAUNCH's idle fill = its `HULL_READY_FORMAT`
   line + `IDLE_TEXT` (both pinned strings).
7. `fitting_panel.{gd,tscn}` and `repairs_panel.{gd,tscn}` stay on disk (forced: `ui/hud/`
   preloads the repairs script and `auction_panel.gd` the fitting script); the shell loads
   neither (rail 6).

## Evidence
- `XDG_DATA_HOME=$(mktemp -d) ~/.local/bin/godot --headless --path "$VAJB_PROJ"
  res://tests/headless_runner.tscn --quit-after 1200`, twice, fresh scratch each:
  run 1 `[SUMMARY] passed=1073 failed=0`; run 2 `[SUMMARY] passed=1073 failed=0`.
- 1073 = 1063/0 + 10 (`test_s29_station_panels.gd`: browser caption + tabs, the hyperdrive
  row, the wrong-slot refusal + flash, P11 + the `IF FITTED` meter, the credits-first buy,
  cell tooltips, `NOMINAL` rows + footer fee, deltas + P12, the P1 cluster rows, the P6 fills).

## Files touched
- `vajb-orbit/ui/station/armory_panel.gd` / `.tscn` — the merged pane: P4 split (grid +
  browser), DnD law (P9/P10), the buy-into-cell flow (P11), tooltips, `IF FITTED`, the P2
  cluster; the body re-housed below the split with its cue removed.
- `vajb-orbit/ui/station/shipyard_panel.gd` / `.tscn` — deltas (A7), P12 caption, the
  repair block (P5/P13) + footer fee line + `REPAIR`/`SET ACTIVE` cluster, damage-row hover,
  the P6 idle fill.
- `vajb-orbit/ui/screens/station.gd` — the rail 8→6 (P7: enum + the five arrays).
- `vajb-orbit/ui/station/launch_panel.gd` — the P6 LAUNCH idle fill.
- `vajb-orbit/tests/test_s29_station_panels.gd` — NEW, 10 rows (A4–A6).
- Moved-row edits: `test_d7_armory.gd`, `test_p2b1_outfitting_panel.gd`,
  `test_s18_armory_rework.gd`, `test_s11_inspector.gd`, `test_s11_describe.gd`,
  `test_s20_chrome_unify.gd`, `test_p2b_fitting_panel.gd`, `test_s21_stability.gd`.
