---
slice: S36
worker: S36-B1
model: "hyper/deepseek-v4.1-flash @ xhigh"
status: actionable
gate: "1138/0 → 1150/0"
---

# S36-B1 report — the chrome re-skin (the swap map + the census suite)

## Result
The swap map is wired across the station panes, the OVERVIEW tiles and the exchange
tooltip; the four BG layers sit behind the pane content. The gate reads
`[SUMMARY] passed=1150 failed=0` (baseline `passed=1138 failed=0`); the new suite adds
**12** rows and no existing row moved. The keep-list is untouched (group c asserts it).

## Wiring table (surface → cut → file:line)
| Surface | Cut | Wiring |
|---|---|---|
| OVERVIEW tiles | C1 `ui_tile_slab` | `overview_panel.gd:264` (uniform canvas) |
| OVERVIEW service rows | C4 `ui_row_strip` | `overview_panel.gd:340` (nine-slice) |
| OVERVIEW chips (REPAIR/OPEN) | C3 `ui_inline_chip` | `overview_panel.gd:406` |
| INSPECT chips (every pane) | C3 | `components/inspect_chip.gd:26` |
| EXCHANGE board / hold rows | C4 | `exchange_panel.gd:430,569` |
| EXCHANGE MAX / 0 chips | C3 | `exchange_panel.gd:648-649` |
| AUCTION shelf rows | C4 | `auction_panel.gd:824` |
| SHIPYARD hull rows | C4 | `shipyard_panel.gd:398` |
| SHIPYARD action bars (REPAIR…) | C2 `ui_action_bar` | `shipyard_panel.gd:230-231` |
| REFINERY ore / job rows | C4 | `refinery_panel.gd:408,708` |
| REFINERY QUEUE… bars | C2 | `refinery_panel.gd:165` (CANCEL stays native) |
| LAUNCH deck-control bars | C2 | `launch_panel.gd:210,404` |
| ARMORY pack/inventory cards | C4 | `armory_panel.gd:734` (`RowPlate._draw`) |
| ARMORY browser rows | C4 | `armory_panel.gd:4130` |
| ARMORY mode switch | C3 | `armory_panel.gd:984,988` |
| ARMORY rack bay cards | C5 `ui_rack_bay_card` | `armory_panel.gd:805` (`ConsolePanels._draw`) |
| Tooltip frame | C7 `ui_tooltip_frame` | `components/tooltip.gd:38` |
| Drawer entries | C9 `ui_drawer_entry` | `screens/station.gd:571` |
| Pane frames | C12 `ui_panel_frame` | already shipped (`test_s20` AC1 pins it) |
| Pane backdrops | BG-1..4 | `screens/station.gd:792` (+ `_sync_backdrop`) |

## Measured vs declared margins (master px; N51)
| class | wired (R1 "max of the two methods") | declared §15.3 ×2 | my bevel scan |
|---|---|---|---|
| C3 chip | 24/34/23/39 | 16×4 | 2/0/20/19 |
| C4 strip | 74/74/35/49 | 24/24/16/16 | 1/1/32/7 |
| C7 tooltip | 22/43/50/64 | 24×4 | 21/23/48/45 |
| C12 frame | shipped 32×4 (pinned) | 64×4 | 13/13/13/14 |
The margins are method-dependent (the plateau/trim band vs the structure band; R1's
own note). Per R1's explicit rule (`D21-G2-R1_review.md`, "max(the two methods) is the
safe wiring value") the wired value is the per-side max of R1's and the builder's scans;
my independent bevel scan is the third column. Reversal: wire §15.3's declared defaults.

## Suite groups (`tests/test_s36_chrome_census.gd`, 12 rows)
- (a) class-aspect — **3** rows: every class cut == its master within 1 %; the tile and
  drawer-entry canvases draw the cut's own aspect.
- (b) no-smear — **4** rows: the nine-slice plates carry the measured margins; the canvas
  classes have no nine-slice; the SHIPYARD C2 bars draw the whole cut.
- (c) keep-group — **3** rows: `ui_slot_weapon_normal` 48×48, `ui_bar_caps` 42×14,
  `ui_minimap_bezel` 200×200; the drawer plate stays PanelRaised; SELL/SELL ALL/CANCEL and
  the main-menu `MenuButtonPlate` keep `ui_button_plate_normal`.
- (d) backdrops — **2** rows: BG-1..4 exist, cover-fit, IGNORE, behind content; the active
  deck shows only its assigned layer.

## Acceptance list answers
1 — DONE — every swap-map surface wears its class cut (the wiring table above); nothing
  outside the table moved (gate rows unchanged).
2 — DONE — margins measured per N51 and reported measured-vs-declared (table above).
3 — DONE — A1: every cut's aspect == its class master within 1 % (suite group a).
4 — DONE — A2/A3: the nine-slice plates hold non-zero margins; the canvas classes draw the
  whole cut uniformly (group b); the rails' slot draws are the legal uniform case.
5 — DONE-with-note — A6: the armory console face is retired from the pane (`test_s20` AC1
  / A5.1) so no whole-face plate stretches; `ChromeFamily.apply_contain` is the C6 route.
6 — DONE — A7: states are modulate / stylebox tint only (`ChromeFamily.tinted`, the tint
  StyleBoxFlats); no size, position or `visible` change for a state.
7 — DONE — the keep-list is untouched (group c asserts the shipped sizes and native styles).
8 — DONE — BG-1..4 land per the assignment, cover-fit at 1765×753, behind content, IGNORE.
9 — DONE — the rails' air is preserved: the four hard-class cuts draw at their slot rects as
  cut (`canvas_rect` = aspect-fit, never cropped to fill).
10 — DONE — `test_s36_chrome_census.gd` ships with the four groups; the gate reads
  1138 → 1150 / 0.
11 — DONE — this report.

## Deviations from SLICE.md
- **C9 landed aspect.** The C9 cut is 720×112 (6.43:1); §15.1 declares the C9 target
  272×56 (4.857:1). The cut is final (§15.6) and the owner accepted the rail shape, so the
  entry draws the landed aspect. Reversal: re-cut C9 at 272×56.
- **C12 pane-frame margins.** Shipped 32 (pinned by `test_s20` AC1:243); §15.3 declares 64;
  measured 13. Left at 32 — a pin (escalation bucket 2). Reversal: wire the measured value.
- **C6 armory console.** Not re-wired: the pane retires it (`test_s20` AC1 / A5.1). Reversal:
  re-introduce the console as a `contain` plate.
- **OVERVIEW identity block.** Kept its flat Tokens box + faction border (native chrome, the
  owner's "native keeps it" criterion) rather than C4. Reversal: apply C4.
- **Margins source.** Wired from R1's "max of the two methods" rule, not §15.3's declared
  defaults. Reversal: wire the declared values.
- **Armory C4/C5.** Wired through the armory's existing code-drawn chrome idiom
  (`ConsolePanels._draw`, `RowPlate._draw`), the pane's pinned architecture (A5.1). Same
  art; reversal: none owed.

## Evidence
- Gate before: `[SUMMARY] passed=1138 failed=0` (fresh `XDG_DATA_HOME`, `--quit-after 1200`).
- Gate after: `[SUMMARY] passed=1150 failed=0` (same command, fresh scratch).
- No `[FAIL]` rows; no moved existing row.
- New suite: `res://tests/test_s36_chrome_census.gd` (12 `test_*` methods).

## Files touched
- `ui/theme/chrome_family.gd` — new: the class tables, the measured margins, the appliers.
- `ui/components/inspect_chip.gd`, `ui/components/tooltip.gd` — C3 / C7.
- `ui/screens/station.gd` — C9 drawer entries, the BG-1..4 layers, `_sync_backdrop`.
- `ui/station/overview_panel.gd` — C1 tiles, C4 rows, C3 chips.
- `ui/station/exchange_panel.gd` — C4 rows, C3 MAX/0.
- `ui/station/auction_panel.gd`, `shipyard_panel.gd`, `refinery_panel.gd`, `launch_panel.gd`
  — C4 rows, C2 action bars, C3 chips.
- `ui/station/armory_panel.gd` — C4 cards/rows, C3 mode switch, C5 bays.
- `tests/test_s36_chrome_census.gd` — new census suite.

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| C9 cut aspect vs §15.1's 272 nominal (re-cut or doc) | ticket | `UI_SPEC.md` §15.1 / the cut |
| C12 pane-frame margin 32 (pin) vs §15.3 64 / measured 13 | ticket | `test_s20` AC1 / §15.3 |
