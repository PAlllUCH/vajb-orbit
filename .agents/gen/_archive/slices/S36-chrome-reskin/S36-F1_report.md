---
slice: S36
worker: S36-F1
model: "hyper/deepseek-v4.1-flash @ xhigh"
status: actionable
gate: "1150/0 → 1151/0"
---

# S36-F1 report — the chrome fixer (R1's F1–F5)

## Result
F1–F5 executed. Every nine-slice plate now draws its measured margins scaled to its DRAWN
rect under a per-axis degenerate guard: a fresh scene probe reads **0** degenerate plates
(was **86**). F2/F3/F5 revert their out-of-band surfaces to pre-swap style. F4 restores the
tooltip's text inset (top/bottom 50/64 = 114 px; live tooltip 360×174, inside C7's 120–400
band). The gate reads `[SUMMARY] passed=1151 failed=0` (1138 + 13 census rows); no existing
row moved.

## Fix table (finding → fix → file:line)
| # | Finding | Fix | file:line |
|---|---|---|---|
| F1 | measured margins exceed the drawn rects → degenerate nine-patch | scale `round(measured·drawn/cut)` per axis + guard `min(m, ⌊rect/2⌋)`; box rebuilt on every `resized` | `ui/theme/chrome_family.gd:131` (drawn_margins), `:150` (stylebox), `:272`/`:285` (wire/refresh) |
| F1b | armory RowPlate drew the margins unscaled | pass the card's drawn rect | `ui/station/armory_panel.gd:734` |
| F2 | 4 REFINERY bars 114–176 px < C2's 272 floor | revert to native `StationButton` | `ui/station/refinery_panel.gd:156-165` |
| F3 | 5 rack bays 876×116 outside C4/C5 bands | revert to the flat Tokens plate (pre-swap) | `ui/station/armory_panel.gd:783-796` |
| F4 | tooltip text inset zeroed → text under the C7 bevel | restore `content_margin_top/bottom` = the C7 bevel (50/64) | `ui/theme/chrome_family.gd:160-175` |
| F5 | cluster chip 452 px > C3's 160 ceiling | revert the chip to native (no C3 plate) | `ui/components/inspect_chip.gd:19-35`, `ui/station/shipyard_panel.gd:798` |
| F1c | B1 read the (l,r,t,b) table as (l,t,r,b): top/right swapped | assign `top=m.z, right=m.y` | `ui/theme/chrome_family.gd:59`, `:131`, `:153-160` |

## A4 report table (surface → live rect → why out of band → reverted style)
| Surface | Live rect (probe) | Why out of band | Reverted / clamped style |
|---|---|---|---|
| REFINERY `QueueButton` | 115×56 | under C2's 272 wide floor | native `StationButton` |
| REFINERY `QueueAllButton` | 114×56 | under C2's 272 | native `StationButton` |
| REFINERY `LoadButton` | 176×56 | under C2's 272 | native `StationButton` |
| REFINERY `CollectButton` | 176×56 | under C2's 272 | native `StationButton` |
| SHIPYARD `StatsStack/ClusterInspectChip` | 452×32 | over C3's 160 wide ceiling | native `Button` (no C3 plate) |
| ARMORY rack bays ×5 (`ConsolePanels`) | 876×116.2 | over C4's 84 tall cap; C5 is the fixed 260×192 card | flat Tokens plate (pre-swap) |
| C3 inline chips (INSPECT / mode / MAX-0 / overview / auction) | 96×32 | measured C3 bevel t+b = 32 = the chip height | C3 plate, guard-clamped (b 20→16) |

## Gate
- Before (fresh scratch `XDG_DATA_HOME`, `--quit-after 1200`): `[SUMMARY] passed=1150 failed=0`.
- After (same, fresh scratch): `[SUMMARY] passed=1151 failed=0`. No `[FAIL]` rows.

## Acceptance list answers
1 — DONE — F1 units cure; 0 degenerate plates in `tests/probe_s36_r1_scene.gd` (was 86).
2 — DONE — F2/F3/F5 revert + the A4 table above.
3 — DONE — F4 tooltip inset restored; live 360×174, inside C7's band.
4 — DONE — everything else as wired (A6/A7, the keep-group and BG-1..4 re-probe clean).
5 — DONE-with-changes — census 12 → 13 rows (1 added, 2 updated); disclosed below.

## Deviations
- **F1c top/right order fix (B1 defect).** `MARGINS` holds R1's `lrtb` table but was assigned
  `(l,t,r,b)`, so top and right were swapped on every plate (C3: wired top 34 = the table's
  right; C7: wired top 43 = the table's right). F1's "the measured table stays the law"
  requires the correct assignment, and it is what makes F4's 114 (= top 50 + bottom 64) land.
  Reversal: assign `top=m.y, right=m.z`.
- **F4 inset = top/bottom only (0/50/0/64).** All four sides would grow the panel to 425 px,
  breaking N47's 360 width cap; the top/bottom bevel alone grows the min height by 114 into
  C7's band. Reversal: add left 22 / right 43.
- **Census row count 12 → 13.** Added `test_b_the_nine_slice_margins_scale_and_never_degenerate`
  (F1's regression). Reversal: delete it.
- **Census row updated: `..._carry_the_measured_margins`.** Made stale by F1c (the box is now
  (l,t,r,b) vs the table's (l,r,t,b)); it compares the re-ordered vector. Reversal: `want`.
- **Census row updated: `..._rows_and_the_tooltip_wear_their_nine_slice`.** The tooltip now
  wears drawn-space margins (F1), so its exact-margin assert is replaced by the drawn-space
  value plus the F4 content inset. Reversal: assert `texture_margin_left == 22`.
- **F3 stale doc measurement (no doc edit).** The census's C5 assertion (group a) checks the
  cut's aspect, not the bay wiring, so it stands; §15.1's 260×192 bay measurement is stale
  against the live 876×116 — a designer note, never edited here.

## Evidence
- Probe before: 86 `degen_v=Y`/`degen_h=Y` plates of 104 (`/tmp/s36f1_probe/scene_before.log`).
- Probe after: 0 degenerate; C4 rows symmetric (864 → 57/18/57/25; 1756 → 116/18/116/25),
  C3 chips 12/12/17/16, C7 tooltip 360×174, `StatsStack/ClusterInspectChip` gone.
- Gate lines above; both runs on a fresh scratch `XDG_DATA_HOME`.

## Files touched
- `ui/theme/chrome_family.gd` — drawn_margins + guard, scaled stylebox + C7 content inset, wire/refresh appliers, the F1c order fix.
- `ui/components/inspect_chip.gd` — `wear_chrome` opt-out (F5).
- `ui/station/refinery_panel.gd` — F2 revert.
- `ui/station/shipyard_panel.gd` — F5 revert.
- `ui/station/armory_panel.gd` — RowPlate scaled C4, F3 bay revert.
- `tests/test_s36_chrome_census.gd` — +1 row, 2 rows updated.

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| REFINERY bars 114–176 px need a plate under C2's floor | ticket | §15.1 P42 / `refinery_panel.gd:165` |
| ARMORY bays 876×116 need a wide-strip class (or re-measure) | ticket | §15.1 C5 / `armory_panel.gd:805` |
| Cluster chip 452×32 needs a plate above C3's ceiling | ticket | §15.1 C3 / `shipyard_panel.gd` |
| C3 chip bevel t+b = the 32 px height (guard-clamped) | ticket | §15.3 C3 |
| F1c order swap in B1 — designer to ratify | note | `chrome_family.gd:59` |
