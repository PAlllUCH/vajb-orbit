---
slice: S42
worker: S42-V0
role: coder
status: ready
tier: paid
---

# S42-V0 — the OVERVIEW 3×3 grid rework (P44–P47 + T-184, T-189 rides)

## Context (read in this order, by range)
1. `docs/design/STATION_HUB.md` §23.1 (lines ~2113–2121) — P44–P47 verbatim
   (below); §23.10's tick rows P44–P47; §19.1–§19.4 for what is superseded
   (§23.11's ledger rows 1–6); §15.1's U2 rows (the service availability law
   you re-seat).
2. `docs/design/UI_SPEC.md` §3.10 Amendment 5 (A5.1–A5.5, lines ~682–714) and
   §16.1 (lines ~1872–1902) — the composition and ink law.
3. `vajb-orbit/ui/station/overview_panel.gd` (727 lines, read whole — it is the
   file you rewrite) and `overview_panel.tscn` (46 lines).
4. `vajb-orbit/ui/screens/station.gd` by grep: `OVERVIEW := 6` (line 76),
   `SERVICES := 7` (77), `_on_pane_navigate` (1632), `_focus_active_panel`
   (1600), `_show_service` (1217), `SERVICES_STRIP` (114) — the deep-link seam
   you extend.
5. `vajb-orbit/tools/build_theme.gd:582` `_flat()` — the flat box builder;
   `vajb-orbit/ui/station/armory_panel.tscn` `FitLeftBox` + the
   `armory_panel.gd` `_apply_tokens` border idiom (`overview_panel.gd:632-636`
   is the closest exemplar in your own file).

## Spec extract (the pinned law, verbatim)

**STATION_HUB §23.1 P44** — "the OVERVIEW deck is **one `GridContainer`,
columns 3, separation 16** (P23's own grid numbers stand), row-major:
**ARMORY · REFINERY · EXCHANGE / AUCTION · SHIPYARD · LAUNCH / CONTRACTS ·
INSURANCE · VAULTS** — the P25 service rows retire into the grid as tiles.
`TILE_MIN` re-derives to **(240, 120)**: the arithmetic is 3×240 + 2×16 =
**752 ≤ 756** (the S41-measured pane, §22's own note) and the block stack
90 + (3×120 + 2×16) + 84 + 18 + 3×12 = **620 ≤ 633** (§19.3's content split),
so the four-block deck fits **unscrolled at 16:9** — P22's `ScrollContainer`
stays as the `expand`-aspect safety, and §19.1's scroll arithmetic is
superseded by this row's. The tile interior is P23's unchanged (margin 16,
`VBox` 8, glyph 48, `SectionHeader` title, one caption line)."

**P45** — "the nine tiles' chrome is the **flat Tokens box** (`_flat()`,
1 px `metal_mid`, UI_SPEC §3.10 A5.1/A5.4) at the P44 tile size … Tile states
are P23's (hover bevel, P3 focus ring, pressed stylebox; no state changes any
box)."

**P46** — "the deck's block order is **identity → the 3×3 grid → active hull +
repair (P24's anatomy unchanged) → flavour line (P27)** — block 4 (the P25
services rows) dies with the rows. The three service tiles deep-link to the
**SERVICES pane with that service's panel showing** (P26's law, reachability
re-pointed from rows to tiles; the U6/U10/U16 readouts now live only in
§15.2–§15.4's panels). The three service captions (**PROPOSED**, P23's caption
law): CONTRACTS `JOBS · ESCROW · STANDING` · INSURANCE `COVERS ONE LOSS` ·
VAULTS `STAYS BEHIND WHEN YOU FLY`. **AUCTION's caption re-cuts to
`THE 20-MINUTE SHELF`**. P30's trailing `OPEN →` chip dies with the rows; the
tile affordance mark stands."

**P47** — "**T-184's cure:** the two raster tile glyphs — ARMORY
`icon_equip_module.png`, LAUNCH `icon_map_route.png` (`overview_panel.gd:33,38`,
`tinted: false`) — **modulate `text_caption`** like the four tinted SVG glyphs."

**T-189 (rider)** — "P44 spends the whole measured pane width: 752 ≤ 756 leaves
4 px with no content-inset allowance. Re-measure the grid seat at the S42
implementation" — measure before you land; report the numbers; if 240 cannot
seat, report and leave the value (never change a pin).

**§15.1 U2 (the availability law you re-seat on tiles)** — "a service the
docked station's matrix does not carry keeps its label and goes
`button_disabled`, and its readout cell carries the reason caption in
`text_dim` — the label plus the disabled plate is the state, never colour
alone."

## Measured facts (cite, do not re-derive)
- `overview_panel.gd:32-39` `TILES` (3×2), `:52` `TILE_MIN := Vector2(300,140)`,
  `:53-54` columns 3 / separation 16, `:45-49` `SERVICE_ROWS`, `:42`
  `SERVICES := 7`, `:74` `VAULT_BASE_CAPACITY := 40` (dies with the rows —
  T-162), `:207-215` `_build_tiles`, `:218-274` `_make_tile` (glyph modulate at
  `:251` — the WHITE branch is T-184's defect), `:280-281`
  `ChromeFamily.apply_tile` (the C1 canvas — P45 retires it), `:284-286`
  `_on_tile_pressed` → `navigate_requested`, `:290-299` hover/unhover, `:302-337`
  the hull block, `:339-402` `_build_services`/`_make_service_row` (dies), `:417-424`
  flavour, `:554-598` `_refresh_services`/`_apply_service_availability` (the
  availability law re-seats on tiles), `:494-501` `_tile_buttons`.
- `overview_panel.tscn`: `%BlockScroll`/`%BlockStack` (the scroll seat P22
  keeps) and the `ServiceHost` node (dies — P44's four-block deck returns it
  into the stack; the S41 fold workaround's own reversal note at
  `overview_panel.gd:349-350` already names this).
- `station.gd`: the hint seam is `_focus_hint` (set at `:1632-1635`, consumed at
  `:1618-1621` with only `&"repair"` handled); `_active_service` (`:279`) and
  `_show_service` (`:1217`) are the service selection you drive from the hint;
  the SERVICES focus branch is `:1606-1612`.
- The service icons ship: `icon_contract_haul.svg`, `icon_service_insurance.svg`,
  `icon_service_vault.svg` (`overview_panel.gd:46-48`).
- Gate baseline 1330/0 (measured 2026-10-12 on this tree).

## Task
Rebuild the OVERVIEW deck per P44–P47: nine tiles in one 3×3 grid at
`TILE_MIN (240, 120)`, flat Tokens box chrome, the four-block deck, the service
deep-links with the hint seam, T-184's glyph cure, and the availability law
re-seated on the three service tiles. Re-measure the seat first (T-189) with a
headless probe and report the numbers. Add the new suite
`tests/test_s42_overview_grid.gd` pinning the acceptance list.

## Acceptance list
1. `TILES` carries nine entries row-major in P44's order; the grid is one
   `GridContainer`, columns 3, separation 16; every tile's minimum is (240, 120).
2. The P25 rows are gone: no `SERVICE_ROWS` rows, no `ServiceRows` node, no
   `%ServiceHost` node, no `OPEN` chip; the deck is the four-block stack inside
   `%BlockScroll` (P22 kept).
3. T-189: a probe mounts the pane at the shell's measured content width and
   reports the grid's seated width and the block stack's total height; the
   numbers are in the report; 240/120 seats or the deviation is reported.
4. Every tile wears the flat Tokens box (1 px `metal_mid` border, no C1 canvas,
   no `ChromeFamily.apply_tile` on tiles); hover/pressed/focus states change
   tint only, never size or position.
5. A service tile's press emits `navigate_requested(SERVICES, &"contracts" |
   &"insurance" | &"vaults")`; `station.gd` consumes the hint by calling
   `_show_service(<hint>)` so the deep-linked panel shows.
6. The three service captions and AUCTION's re-cut caption are exactly P46's
   strings; the other five P23 captions are unchanged.
7. All nine glyphs modulate `text_caption` at rest and `text_primary` on hover
   (T-184's mechanism; no raster glyph renders `Color.WHITE`).
8. A tile for a service the docked station does not offer renders disabled with
   the registry's reason caption in `text_dim` on the tile's caption line
   (available tiles carry their own caption); label + disabled plate carry the
   state.
9. `focus_primary()` and the tile hover/inspect chain still work (the
   `inspect_requested` payload is the tile's title + caption).
10. New suite `tests/test_s42_overview_grid.gd` pins items 1–2, 5–9 with at
    least one row each; the report answers every item with a cite.

## Hard constraints
- File set: `vajb-orbit/ui/station/overview_panel.gd`,
  `vajb-orbit/ui/station/overview_panel.tscn`, `vajb-orbit/ui/screens/station.gd`,
  `vajb-orbit/tests/test_s42_overview_grid.gd` (dispatch sets
  `VAJB_WORKER_FILES` to exactly this). **Do not touch** `tests/test_s30_shell.gd`,
  `tests/test_s40_legibility.gd`, `tests/test_s41_panels_a.gd` — their
  premise rows are the developer's bucket-2 re-cut (the orchestrator edits them
  after your build; your gate run may show them red — report the count, do not
  fix them). Do not touch any other pane, the theme, `addons/`, or docs.
- No new hex, no new tokens; every ink is an existing token.
- Composition is A5.1–A5.5 (containers + anchors + `custom_minimum_size` +
  size flags; never `position`/`offset_*` on laid-out children; no `_draw` over
  content).
- Shell edits are forbidden — use edit tools only.
- Every Godot run bounded (`--quit-after`), probes self-quit; never leave a
  command in the background; redirect probe stdout to a log you read.
- The gate runs through `python3 staging/gate.py --times 1` for your own check
  (the close-out runs `--times 2`); record before/after `[SUMMARY]` in the
  report.

## Output contract
- Report: `.agents/gen/slices/S42-overview-grid/S42-V0_report.md` (≤120 lines,
  from `_templates/REPORT.md`): acceptance answers with cites, the T-189
  measured numbers, gate before/after, files touched, follow-ups.
- Deliverable: the four files above.

## Paste block
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="vajb-orbit/ui/station/overview_panel.gd,vajb-orbit/ui/station/overview_panel.tscn,vajb-orbit/ui/screens/station.gd,vajb-orbit/tests/test_s42_overview_grid.gd" crush run "You are worker S42-V0. Read .agents/gen/slices/S42-overview-grid/S42-V0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```
