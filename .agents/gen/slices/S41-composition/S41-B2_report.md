---
slice: S41
worker: S41-B2
model: "hyper/deepseek-v4.1-flash (xhigh)"
status: actionable
gate: "1300/0 → 1327/0 (twice, fresh scratch stores)"
---

# S41-B2 report

## Result
F1, F6 and F8 are shipped on the three list decks. The gate ran twice on fresh scratch
`XDG_DATA_HOME` stores: `passed=1327 failed=0` both times. The 27 new rows are exactly the
four S41 suites (B1 12, B2 5, B3 4, B4 6), so no pre-existing row moved (A8).

## Acceptance list answers
- **A1 — F1 fixed, F6 fixed, F8 fixed with a deviation (below).** F1: `overview_panel.gd:160-200`
  drops the identity block's character line and `:338-370` builds the services rows into a new
  `%ServiceHost` outside `BlockScroll`. F6: `exchange_panel.tscn:166-179` centres the readout
  between two slack owners. F8: `auction_panel.tscn:55-140` hoists every shelf caption and
  column band into a fixed `ShelfChrome` above `AuctionScroll`.
- **A2 — no position/offset write anywhere; no visual box carries a filler flag.** The
  `size_flags_vertical = 3` flags sit on `%BlockScroll` and `%AuctionScroll` (shipped), the
  two new slack `Control`s (`TradeSlack`, `TradeTail`, owning the SALE column's slack) and
  `ServiceSlack` (owning `%ServiceHost`'s slack, inert at 16:9). No plate or label carries
  one; the changed blocks are `MarginContainer`/`VBoxContainer` wrappers.
- **A3 — no colour added or changed.** No hex literal touched; `build_theme.gd` is B1's file.
- **A4 — proved.** `tests/test_s41_panels_a.gd:70-96` mounts the pane at the shell's own box
  (1768×756) and asserts, per row, `global_position.y + size.y <= pane.end.y` with
  `scroll_vertical == 0`, plus `not scroll.is_ancestor_of(row)`, so it cannot pass on a row
  the scroll would clip. Measured: CONTRACTS 66..142, INSURANCE 148..224, VAULTS 230..306.
- **A5 / A6 — N/A here.** F14 is B3's and B4's finding (no action cluster on these decks);
  T-177 is B1's rider and no theme file is in this worker's set.
- **A7 — every new row is load-bearing.** The A4 row fails if the services return to
  `%BlockStack` (the fold pushes INSURANCE and VAULTS past `pane.end.y`); the identity row
  fails at 87.0 > 70.0 if the character line returns; the F6 row fails if either slack owner
  is dropped (null sibling) or moved (unequal sizes); both F8 rows fail if any caption or band
  returns inside a scroll. Variables are read with `get()`, never `call()`; no row awaits.
- **A8 — no gate row outside §6's list moved.** 1300 + 12 + 4 + 6 + 5 = 1327, zero failures
  on both runs; the suites §6 pins are unchanged.

## Deviations from SLICE.md
- **F1's mechanism is stronger than the brief's wording.** Shortening the identity block
  alone cannot satisfy A4: on the shipped tree the OVERVIEW content measures 793 in a
  636-tall split (identity 87 + tiles 296 + hull 123 + services 240 + flavour 19 + 4×12), so
  the three rows need ~147 px freed and no bucket-1 lever supplies more than 22. The
  services block therefore **leaves the scroll** into `%ServiceHost`, where all three rows
  are visible unscrolled, flush under the fold. Cost: at 16:9 the hull block now sits below
  the fold and scrolls (P22's own behaviour; B1's F9 makes the cue visible). Reversal:
  `_build_services` adds the rows back to `%BlockStack` and `ServiceHost` is dropped.
- **F1's spacer is inert at 16:9** (`ServiceSlack` only bites when the host has slack; at
  16:9 `%BlockScroll` takes it all), and the line dropped is the character line, not the
  name: the plate keeps the faction mark and the station name, and the shell header already
  renders both lines.
- **F6 uses the audit's option 2 (the readout centres), not option 1.** Option 1 would
  duplicate the footer hint the pane's own `%PaneFooter` already carries — the duplication
  F12 exists to remove. Measured: two slack owners of 200 and 201, the readout at y
  424..475 of a 53..688 column.
- **F8's chrome hoists all three sections; the per-section swap needs a file outside my
  set.** `auction_panel.tscn` alone can satisfy "the fold can only ever cut rows, never a
  header" only by moving the chrome above the one `AuctionScroll`, so with ALL selected the
  three caption+band blocks stack above the rows (a legend) instead of each band sitting over
  its own rows. The correct fix — the chrome swapping to the topmost visible section,
  armory-style — needs `auction_panel.gd`'s `_apply_family`, which is **not** in this worker's
  `VAJB_WORKER_FILES`; per the brief's file-set note this worker stopped rather than edit it.
  Reversal: return the three `*Margin` nodes into `AuctionScroll/AuctionBody`.

## Evidence
- `XDG_DATA_HOME=$(mktemp -d) $GODOT_CONSOLE --headless --path "$VAJB_PROJ"
  res://tests/headless_runner.tscn --quit-after 2400`, run twice on two fresh stores:
  `[SUMMARY] passed=1327 failed=0` and `passed=1327 failed=0` (both exit 0).
- The suite alone (`-- --suite=test_s41_panels_a`) → `passed=5 failed=0`.
- A4's geometry from the shell mount: OVERVIEW pane y 214..970, `%BlockScroll` y 266..644,
  service rows 656..732 / 738..814 / 820..896 — inside the pane, outside the scroll.
- The one regression the gate caught mid-build — `test_s30_shell.gd`'s "P25: three rows" —
  is why `ServiceSlack` sits beside `ServiceRows`, never inside it.

## Files touched
- `overview_panel.gd` / `.tscn` — F1: identity loses its character line; the services rows
  move to a new `%ServiceHost` with a slack owner.
- `exchange_panel.tscn` — F6: the readout between `TradeSlack` and a new `TradeTail`.
- `auction_panel.tscn` — F8: `ShelfChrome` above `AuctionScroll`.
- `tests/test_s41_panels_a.gd` — five load-bearing rows (F1 ×2, F6, F8 ×2).

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| F8's per-section chrome swap (the ALL tab's stacked legend) | code | `auction_panel.gd` `_apply_family` |
| The OVERVIEW hull block scrolls at 16:9 (P22's own behaviour) | owner call | `STATION_HUB` §19.1/§19.4 |
