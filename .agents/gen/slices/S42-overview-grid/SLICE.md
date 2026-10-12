---
slice: S42
phase: P4
lane: code
status: active
gate_baseline: "1330/0"
---

# S42 — the OVERVIEW 3×3 grid rework

## Goal
The OVERVIEW deck becomes one 3×3 grid of nine module buttons (P44–P47,
STATION_HUB §23.1); the P25 service rows retire; the two raster tile glyphs
become visible (T-184). The deck fits unscrolled at 16:9 again.

## In scope
- P44 — one `GridContainer`, columns 3, separation 16, nine tiles row-major
  ARMORY · REFINERY · EXCHANGE / AUCTION · SHIPYARD · LAUNCH / CONTRACTS ·
  INSURANCE · VAULTS; `TILE_MIN` (240, 120); the 752/756 and 620/633 arithmetic;
  the P25 service rows retire; `T-189` re-measure rides.
- P45 — the tiles' chrome becomes the flat Tokens box (`_flat()`, 1 px
  `metal_mid`); the C1 slab re-presents only on a re-widen/re-cut.
- P46 — the four-block deck (identity → grid → hull+repair → flavour); the
  three service tiles deep-link to SERVICES with that service showing; the
  three PROPOSED service captions; AUCTION's caption re-cut.
- P47 (T-184) — the two raster glyphs modulate `text_caption`.
- T-162 closes by retirement (the vault readout dies with the rows).

## Out of scope
- The SVG glyph remaster (§19.7 staged; ships only on owner approval).
- Any other pane; the SERVICES deck's own build (`station.gd:_build_services`);
  the theme (no token value changes).

## Acceptance criteria
- [ ] AC1 — nine tiles in one grid, row-major in P44's order, each ≥ (240, 120),
      separation 16; the P25 rows and `ServiceHost` are gone.
- [ ] AC2 — T-189: the grid seat is re-measured on the live shell before it
      lands; the measured numbers are reported with the probe.
- [ ] AC3 — the tile chrome is the flat Tokens box (1 px `metal_mid`), states
      tint-only; no C1 canvas remains on the tiles.
- [ ] AC4 — the four-block deck order holds; block 4 is the flavour line.
- [ ] AC5 — a service tile press routes `navigate_requested(SERVICES, hint)`
      and the shell shows that service (the hint seam in `station.gd`).
- [ ] AC6 — every tile glyph modulates `text_caption` (T-184); hover steps to
      `text_primary`, unhover back to `text_caption`.
- [ ] AC7 — a service the docked station does not offer renders its tile
      disabled with the reason caption (the §15.1 U2 law re-seated).
- [ ] AC8 — the new suite pins AC1–AC7; the gate is green ×2 hermetic.

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S42-V0 | `vajb-orbit/ui/station/overview_panel.gd, vajb-orbit/ui/station/overview_panel.tscn, vajb-orbit/ui/screens/station.gd, vajb-orbit/tests/test_s42_overview_grid.gd` | `S42-V0_BRIEF.md` |
| S42-R0 | read-own review of the S42 set | `S42-R0_review.md` |

## References
- STATION_HUB §23.1 (P44–P47) + §23.10 tick rows P44–P47; §19.1–19.4 (the
  superseded rows); §15.1 U2 (the service availability law)
- UI_SPEC §3.10 A5.1/A5.4 (the flat Tokens box), §16.1 (A1/A3 ink)
- `docs/CODE_MAP.md` (the panel/shell wiring)

## Carries forward
- T-184 (cured by P47), T-189 (re-measure), T-162 (closes by retirement).
- Developer bucket-2 re-cuts after the build: `test_s30_shell.gd` block rows,
  `test_s40_legibility.gd` A3 glyph row, `test_s41_panels_a.gd` F1 fold row.
