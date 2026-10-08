---
slice: S37
worker: S37-F1
model: "hyper/deepseek-v4.1-flash @ xhigh"
status: actionable
gate: "1151/0 → 1151/0"
---

# S37-F1 report — the chrome-fit fixer

## Result
The theme plate is now a real nine-slice: `ui_button_plate_*` carries a 4 px side texture
margin (built by `tools/build_theme.gd`), so the whole-texture smear is gone.
`staging/verify_chrome_fit.py` reads **DISTORT 14 → 0** and **too_small 180 → 169**; the
universal gate is unchanged at **1151/0**. The 48×48 steppers left the plate for the flat
box (the census C8 slot plate does not resolve on a plain `Button`). Items 3 (row content)
and 4 (tooltip inset) are **reported, not landed** — both break standing tests; the numbers
and the reversal are below.

## Acceptance list answers (the fix list, items 1–5)
1 — DONE — the four plate boxes carry `texture_margin_left/right = 4.0`; DISTORT 14 → 0 —
   `tools/build_theme.gd:33-41` (`PLATE_MARGIN_SIDE`), `:548` (`_button_plate`),
   `ui/theme/vajb_theme.tres:200-235` (the four SubResources).
2a — DONE (verify only) — every in-band C2 action bar is already wired: the ARMORY pane
   cluster (`armory_panel.gd:3104-3105`), SHIPYARD (`:230-231`), LAUNCH (`:210,404`). The
   EXCHANGE SELL/SELL ALL/CANCEL and the REFINERY QUEUE…COLLECT bars are keep-list / reverted
   (`S36_proposal.md` keep table; `refinery_panel.gd:162-164`), so nothing else is in scope.
   **Finding:** the ARMORY `FitCells/FitFoot` pair still probes as `ui_button_plate_normal`
   despite that wiring — flagged below.
2b — DONE — the four 48×48 steppers (`SellMinus/SellPlus`, `StepperLess/StepperMore`) wear
   the **flat Tokens box**: a plain `Button` does not resolve the TextureButton-based
   `SlotButtonWeapon` variation (measured: `get_theme_stylebox("normal")` returns
   `StyleBoxFlat`, not the slot plate), so per the brief's fallback their `StationButton`
   variation is dropped — `exchange_panel.tscn:134,151`, `refinery_panel.tscn:124,139`.
3 — NOT DONE — right-sizing the row content (icon + type sizes) shrinks 6 standing tests red,
   incl. `test_s18_armory_rework.gd:…no_font_size_override_escapes_the_scale` (HIGH-1 bars
   per-node `font_size` overrides). Reported as replacement-cut candidates below.
4 — NOT DONE — scaling the C7 content inset changes the tooltip's drawn rect, which makes the
   C7 box's texture margins stale against `tooltip.size` and reddens
   `test_s36_chrome_census.gd:…rows_and_the_tooltip_wear_their_nine_slice`; N47 pins the
   label at 360 (`test_s11_inspector.gd:349`), so the label cannot shrink to seat the text
   inside the side caps. Reported.
5 — DONE — the C9 drawer entries and C1 overview tiles are left exactly as wired (their
   shipped cuts carry ~55–60 % transparent air); reported as replacement cuts below.

## Fix table (defect → fix → file:line)
| # | Defect | Fix | file:line |
|---|---|---|---|
| 1 | `ui_button_plate_*` ship zero texture margins → whole 280×56 art smears (14 DISTORT) | 4 px side texture margin on the four plate boxes (a real nine-slice; the measured side bevel) + regenerate the theme | `tools/build_theme.gd:33-41,548-556`; `ui/theme/vajb_theme.tres:200-235` |
| 2b | 48×48 steppers wear the legacy plate (census C8) | drop the `StationButton` variation → base theme Button (flat box); C8's slot plate is unreachable on a plain Button | `exchange_panel.tscn:134,151`; `refinery_panel.tscn:124,139` |

## Tool counts (before → after)
```
before: surfaces=245 too_small=180 DISTORT=14 band=1 failures=191 waived=2
after:  surfaces=232 too_small=169 DISTORT=0  band=1 failures=168 waived=2
```
`python3 staging/verify_chrome_fit.py --timeout 600`; the 13 fewer surfaces = the 4 steppers
plus 9 plate surfaces whose flat band now sits differently.

## Gate
- Before (fresh scratch `XDG_DATA_HOME`, `--quit-after 1200`): `[SUMMARY] passed=1151 failed=0`.
- After (same): `[SUMMARY] passed=1151 failed=0`. No test row moved.

## Replacement-cut candidates (the generation batch; out of this pass)
| Surface | Live slot | Flat band | Content need | Why wiring cannot fix it |
|---|---|---|---|---|
| C9 drawer entries ×8 | 274×56 | 274×18.6 | ≤168×40 | the shipped C9 cut's rail is 49/112 of the cut → 18.6 px drawn; needs a C9 cut at the entry's own aspect, band ≥ 44 |
| C1 overview tiles ×6 | 567×140 | 567×57 | ≤231×74 | the C1 cut carries a transparent pad (opaque 114/280); needs a C1 cut at ≈4:1, band ≥ content |
| C3 chips ×64 | 96×32 | 67×4 | ≤52×19 | the C3 cut is 192×64 with a 14 px transparent pad (opaque rows 14–49); the N51 t/b margins (23/39) fill the height → re-cut without the pad, or re-measure the margins |
| C4 rows ×87 (AUCTION/EXCHANGE/ARMORY/OVERVIEW/REFINERY/SHIPYARD) | pane-width ×76 | 1524×33 | ≈1707×24–37 | the N51 C4 margins (74/74/35/49 at the 1120×152 cut) over-measure the visible bevel (~8–12 px): the drawn 116 px side caps + 18/25 bands leave a 33 px band the row content spans wider than. Needs a re-measured margin or a thinner-bevel cut |
| C2 action bars ×7 | 349×56 | 349×16.5 | ≤195×29 | the C2 cut's opaque rail is 16.5/56 drawn (transparent pad) |
| REFINERY bars ×4 (Queue/QueueAll/Cancel/Upgrade) | 114–187×40–56 | 69–95×48 | 76–197×29 | 114–187 px wide, under C2's 272 floor; the legacy plate's band is under the content |
| C7 tooltip | 360×105 | 327×80 | 360×80 | N47 pins the label at 360 → the panel is 360 + the side caps (393), out of C7's 280–360 band |

## Deviations
- **Item 1 is side-only (4 px), not a full nine-slice.** A nine-slice's texture margins also
  raise the stylebox minimum (2× the margin): a vertical margin grows the pinned 24×29 A4.2
  rack X chip (29 → 41 at vert 6) and the 45×67 rack cells, reddening
  `test_s20/d7/s10/s18`. The 4 px side keeps the minimum at 8×0 so no pinned control moves.
  Reversal: `PLATE_MARGIN_VERT := 6.0` (breaks those four tests) or zero all four margins.
- **Theme regeneration strips the ext_resource uids** (a headless `--script` run does not load
  the uid cache). Restored from the shipped file, so the `.tres` diff is only the four plate
  SubResources' margins. Reversal: commit the uid-less file.
- **Item 2b chose the flat box over C8.** Measured, not assumed: a plain `Button` with
  `theme_type_variation = &"SlotButtonWeapon"` resolves to `StyleBoxFlat`. Reversal: restore
  the `StationButton` variation on the four steppers.
- **Item 3 reverted.** The icon shrink-center + reduced icon/type sizes were implemented, then
  reverted: they shrank 6 standing tests red (`test_d7`, `test_s10`, `test_s18` ×2,
  `test_s20`, `test_s36`) and the font overrides violate HIGH-1's no-escaping-override rule.
  Reversal: n/a (the changes are gone).
- **Item 4 reverted.** The C7 content-inset scaling reddened the census test's texture-margin
  assert (the circular panel-size dependency). Reversal: n/a.
- **`addons/godot_ai/` was rewritten by a headless `--editor --quit` probe run and reverted**
  (`git checkout -- vajb-orbit/addons/`). No addon change ships.

## Evidence
```
XDG_DATA_HOME=$(mktemp -d) $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
  res://tests/headless_runner.tscn --quit-after 1200 | grep '\[SUMMARY\]'   # 1151/0 both runs
python3 staging/verify_chrome_fit.py --timeout 600    # DISTORT 14 -> 0, too_small 180 -> 169
$GODOT_CONSOLE --headless --path "$VAJB_PROJ" --script res://tools/build_theme.gd   # regen
diff /tmp/theme_before.tres vajb-orbit/ui/theme/vajb_theme.tres   # 4x texture_margin_left/right = 4.0
```
Plate band measured 2026-10-07 on `ui_button_plate_normal.png` (280×56): side bevel cols 1–2,
top/bottom rows 1–3 / 52–54, rivets x≈12 / x≈266 (the census §15.1 C2 "bolts x7–19 / x261–277").

## Files touched
- `tools/build_theme.gd` — `PLATE_MARGIN_SIDE/VERT` + `_button_plate`; the plate variations use it.
- `ui/theme/vajb_theme.tres` — regenerated (only the four plate SubResources' side margins).
- `ui/station/exchange_panel.{gd,tscn}` — steppers off the plate + the item-2 note.
- `ui/station/refinery_panel.{gd,tscn}` — steppers off the plate + the item-2 note.

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| ARMORY `FitCells/FitFoot/RemoveButton`+`BuyFitButton` probe as `ui_button_plate_normal` despite `_wire_actions` C2 | ticket | `armory_panel.gd:3104-3105` |
| C9/C1/C3/C4/C2 replacement cuts at slot aspect (band ≥ content) | paid | `staging/verify_chrome_fit.py` candidates above |
| C4 margin re-measure (the N51 74/74/35/49 over-measures the visible bevel) | designer | `chrome_family.gd:61` |
| Tooltip: seat the text inside the side caps without moving the N47 360 label | ticket | `chrome_family.gd:168-173`, `tooltip.gd:38` |
| Right-size the row content without per-node `font_size` overrides (HIGH-1) | ticket | `auction/overview/exchange/refinery/shipyard/armory_panel.gd` |
