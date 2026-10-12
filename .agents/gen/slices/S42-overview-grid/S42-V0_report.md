---
slice: S42
worker: S42-V0
model: hyper/glm-5.3-flash
status: actionable    # Follow-ups MUST be ticketed before slice close
gate: "1330/0 → 1317/6 (6 premise rows red: 4 briefed, 2 unbriefed suites; S42 suite 11/0)"
---

# S42-V0 report

## Result
The OVERVIEW deck is P44's 3×3 nine-tile grid (ARMORY · REFINERY · EXCHANGE /
AUCTION · SHIPYARD · LAUNCH / CONTRACTS · INSURANCE · VAULTS) at `TILE_MIN`
(240, 120), flat Tokens box chrome, the P25 rows and the S41 fold workaround
gone; the three service tiles deep-link through the shell's `_focus_hint` seam
to the SERVICES pane with that service's panel showing, all nine glyphs ride
the caption ink (T-184), and U2's availability law is re-seated on the tiles.
New suite `test_s42_overview_grid.gd` pins the acceptance list: 11 rows, 11/0.
T-189 measured (Evidence): the pinned seat fits; the deck rides its scroll
viewport exactly (636 = 636, 0 px slack).

## Acceptance list answers
1 — DONE — nine entries row-major in P44's order (`overview_panel.gd:44-55`); one
`GridContainer`, columns 3, h/v separation 16 (`:59-60`, `_build_tiles`
`:198-206`); every tile's minimum (240, 120) (`_make_tile` `:212`). Row:
`test_s42_overview_grid.gd:116`.
2 — DONE — no `SERVICE_ROWS`, no `ServiceRows` node, no `%ServiceHost` node
(removed from `overview_panel.tscn`), no `Open` chip; the stack is
IdentityBlock / TileGrid / HullBlock / FlavourLine inside `%BlockScroll`
(P22 kept). Row: `:148`.
3 — DONE (T-189) — probe = the suite's shell row (`:182`), numbers under
Evidence. 240/120 seats; the deviation is the pane-width reading, reported.
4 — DONE — `_apply_tile_chrome` (`overview_panel.gd:276-286`) builds `_flat()`'s
own shape (void_panel fill, 1 px `metal_mid` border — the same box the identity
block wears); states are the theme's own `button_hover`/`button_pressed`/
`button_disabled`/P3 focus boxes; no `ChromeCanvas`/`chrome_class` meta; tiles
stay (240, 120) seated. Rows: `:220`, `:244`.
5 — DONE — a service tile's press emits `navigate_requested(SERVICES,
&"contracts" | &"insurance" | &"vaults")` (`_on_tile_pressed` `:289-292`);
`station.gd` consumes the hint in `_focus_active_panel`'s SERVICES branch
(`station.gd:1610-1615`) by calling `_show_service(<hint>)`, clearing the seam.
Rows: `:274` (emission), `:298` (shell consumption: VAULTS tile → `_module` 7,
`_active_service` `&"vaults"`, hint cleared, vaults pane the one visible).
6 — DONE — AUCTION `THE 20-MINUTE SHELF`; CONTRACTS `JOBS · ESCROW · STANDING`;
INSURANCE `COVERS ONE LOSS`; VAULTS `STAYS BEHIND WHEN YOU FLY`
(`overview_panel.gd:47-54`); the other five P23 captions verbatim; data and
built labels both asserted (`test_s42_overview_grid.gd:330`).
7 — DONE — all nine glyphs modulate `text_caption` at rest and `text_primary` on
hover (`_make_tile` `:242`, hover/unhover `:296-305`); T-184's mechanism via the
tinted branch, generalized to the two raster masters. Row: `:353`.
8 — DONE — `_apply_service_availability` (`:460-481`): a service the docked
matrix does not carry keeps its label, goes `button_disabled`, and its caption
line carries the registry's reason in `text_dim` (in-place content swap, A5.5 —
no box moves); a place the registry cannot resolve leaves every tile as
shipped. Row: `:385` (s2_outpost → INSURANCE disabled, caption `fly to a
capital` in `text_dim`; CONTRACTS/VAULTS keep their own captions; hover keeps
rest ink on the disabled tile).
9 — DONE — `focus_primary()` seats the ring on the first tile (`:130-134`);
hover publishes the tile's title + caption on `inspect_requested`, un-hover
clears it (N46). Row: `:428`.
10 — DONE — `tests/test_s42_overview_grid.gd` pins items 1–2, 5–9 (row map:
P44 grid `:116`, deck `:148`; P46 links `:274`/`:298`, captions `:330`; P47
`:353`; U2 `:385`; P23 chain `:428`), plus the T-189 probe row `:182`.

## Deviations from SLICE.md
- `tinted` kept on all nine tiles (now the rest-ink branch's own data, P47's
  verbatim framing — the two raster masters join the tinted set); this keeps
  S40's A3 census row alive instead of script-erroring on a retired key.
  Reversal: drop the key and hardcode the caption ink.
- **[Developer fixer amendment, 2026-10-12, post-review — S42-R0/F1/F2
  cured:]** after this report was filed, the developer (a) expanded the tiles
  to fill the pane's width (`overview_panel.gd`, `SIZE_EXPAND_FILL` — P23's
  own idiom; `TILE_MIN` stays the floor; reversal: drop the flag, tiles hug
  the 752-px minimum), re-cut the P45 size row to the `>= (240, 120)` floor
  and the three premise suites (s24 ×3, s30 ×2, s36 ×2, s41 fold row);
  (b) dropped the branch's `Color.WHITE` arm (F2) — every glyph modulates
  `text_caption`. The T-189 numbers below were taken before both changes; the
  reviewer's own probe re-measured the shipped tree (first tile seated at
  (575, 120), grid min 752×392 exact, stack 636 ≤ viewport 636) and its
  `S42-R0_review.md` carries the post-fix numbers. Gate after the fixes:
  1341/0.
- Tiles do not expand (`SIZE_EXPAND_FILL` dropped): the pinned (240, 120)
  minimum is the seat, per P46's caption arithmetic (the 240-tile's 208 px
  caption width). The grid node itself still fills the stack width; tiles hug
  left. Unpinned alignment — reversal: restore the expand flag (D19's
  full-width tiles). *(Superseded by the developer amendment above.)*
- Hover on a disabled service tile keeps rest ink (guard `_on_tile_hover`
  `:296-299`) — bucket-1 call: the disabled plate + `text_dim` caption carry
  the state, so a hover brighten would read as available.

## Evidence
- T-189 pre-land probe (old deck): `shell (1920, 1080) | pane (1768, 756) |
  stack (1756, 540) min 540 | scroll viewport 380 | grid (1756, 296)` — the S41
  fold workaround's ServiceHost seat measured 244 px between scroll and foot.
- T-189 post-land (same row, new deck): `shell (1920, 1080) | pane (1768, 756)
  | stack (1756, 636) min 636 | scroll viewport 636 | grid node (1756, 392)
  min (752, 392) | first tile seated (240, 120)` — unscrolled at 16:9, 0 px
  slack; the grid's own minimum is exactly P44's 752×392.
- Suite: `$GODOT_CONSOLE --headless --path "$VAJB_PROJ"
  res://tests/headless_runner.tscn --quit-after 1200 --
  --suite=test_s42_overview_grid` → `[SUMMARY] passed=11 failed=0`.
- Gate (wrapper). Before: 1330/0 (the brief's baseline, measured 2026-10-12 on
  this tree). After: `python3 staging/gate.py --times 1` → `[SUMMARY]
  passed=1317 failed=6`, engine exit 1, 3 SCRIPT ERROR lines. The 6 red rows,
  all premise rows over the retired deck (none fixed, per the brief):
  `test_s24_world.gd` whole suite (parse error on the retired
  `ROW_HEIGHT`/`VAULT_FORMAT`/`VAULT_BASE_CAPACITY`; its two OVERVIEW U2 rows
  and the vault-read row carry P25 premises); `test_s30_shell.gd`
  `.test_the_overview_carries_the_five_blocks` + `.test_the_services_rows_carry_the_u2_names`
  (both briefed); `test_s36_chrome_census.gd.test_a_the_tile_draws_the_c1_canvas_at_its_own_aspect`
  + `.test_b_the_rows_and_the_tooltip_wear_their_nine_slice` (unbriefed — C1
  canvas and "the OVERVIEW CONTRACTS row ships", retired by P45/P46);
  `test_s41_panels_a.gd.test_f1_the_three_service_rows_sit_inside_the_pane_unscrolled`
  (briefed).
- `python3 staging/check_wiring.py` → "every hard reference resolves" (1550
  hard refs).

## Files touched
- `vajb-orbit/ui/station/overview_panel.gd` — rewritten: nine-tile TILES +
  (240, 120), flat-box chrome, deep-link press payloads, U2 on tiles; the rows'
  constants, builders and readouts deleted.
- `vajb-orbit/ui/station/overview_panel.tscn` — `%ServiceHost` node removed.
- `vajb-orbit/ui/screens/station.gd` — the SERVICES focus branch consumes a
  service hint via `_show_service` (`:1610-1615`).
- `vajb-orbit/tests/test_s42_overview_grid.gd` — new suite (11 rows + probe).

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| Re-cut `test_s24_world.gd`'s OVERVIEW premises (the suite is unparseable until then; re-seat its U2 rows on the tiles like `test_s42`'s row) | premise re-cut (bucket 2) | `tests/test_s24_world.gd:400-460` |
| Re-cut `test_s36_chrome_census.gd`'s two OVERVIEW rows (C1 canvas + the CONTRACTS row) to P45/P46 | premise re-cut (bucket 2) | `tests/test_s36_chrome_census.gd` |
| The deck rides its scroll seat exactly (stack min 636 = viewport 636; the hull block measures 123, not P44's 84 estimate) — any later block growth re-opens the fold; P22's scroll stays the safety | LOW note | `overview_panel.gd` block stack |
