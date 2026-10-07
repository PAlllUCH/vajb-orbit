---
slice: S37
worker: S37-B2
model: "hyper/deepseek-v4.1-flash @ xhigh (generation + wiring, orchestrator-run)"
status: landed
gate: "1151/0 -> 1151/0 (x2 fresh scratch)"
---

# S37-B2 report — the replacement-cut builder

## Result
Five replacement chrome cuts were generated (one qwen2-1 sheet, five rails at
five aspects, native transparent), cut by `staging/cut_chrome_fit.py`, resized to
each class master at 2x, and wired. The canvas classes (C1/C2/C9) are now clean;
the C3/C4 nine-slice bands clear their content vertically. `verify_chrome_fit.py`
reads **too_small 180 -> 95**, **DISTORT 0**; the gate is **1151/0** x2 fresh
scratch. The remaining 95 are content (C4 x) and pinned/theme (C7, C12,
`ui_button_plate`), not chrome.

## What landed
| class | cut file | size | source rail | master aspect |
|---|---|---|---|---|
| C1 | `ui_tile_slab.png` | 1134x280 | qwen rail 1 (4.00) | 567x140 (4.05) |
| C2 | `ui_action_bar.png` | 720x112 | qwen rail 2 (6.82) | 360x56 (6.43) |
| C9 | `ui_drawer_entry.png` | 544x112 | qwen rail 3 (4.99) | 272x56 (4.86) |
| C3 | `ui_inline_chip.png` | 192x64 | qwen rail 4 (3.09) | 96x32 (3.00) |
| C4 | `ui_row_strip.png` | 1120x152 | qwen rail 5 (21.7) | 560x76 (7.37) |

- **C9 realigned to §15.1's 272x56.** The retired cut was 720x112 (360x56): it
  letterboxed to 42.6 px in the 274x56 drawer entry and its opaque rail was
  49/112 -> 18.6 px under 40 px of content. The census suite's `CLASS_MASTERS`
  C9 moves 360x56 -> 272x56 to match (`test_s36_chrome_census.gd`).
- **C3/C4 margins re-measured** off the new thin frames (the retired recessed
  wells over-measured: 97 % / 55 % vertical ornament -> a 1 px / 34 px band):
  C3 `(18, 18, 9, 11)`, C4 `(30, 30, 8, 10)` (`chrome_family.gd` MARGINS;
  census `MEASURED_MARGINS` mirrored). Reversal: the N51 table
  `(24,34,23,39)` / `(74,74,35,49)`.
- **Generation.** qwen2-1 t2i @2K, `--transparent`, style pulled to the family
  (ember lamps and corner brackets dropped, four corner rivets, flat plates).
  Prompts `/tmp/s37_qwen_prompt2.txt`; run
  `asset-library/raw/chrome_fit_2026-10-07/qwen/20261007-202701/`. The seedream
  5 Flash re-run was dropped per the owner (it cannot emit alpha; its transparent
  attempt renders a fake checker).
- **Cutter** `staging/cut_chrome_fit.py`: `--mode alpha|luminance|checker|pink`,
  ink-row band segmentation. The `checker` mode (border flood-fill on an eroded
  light mask) keys a fake-transparency checker cleanly where a plain threshold
  leaves a light fringe on the plate bevel (used for the seedream sheet).

## Acceptance (owner: "regenerate on qwen, keep it full, then wire")
1 — DONE — qwen re-run with the plates kept solid/full (no hollow centre);
every rail is >= 97 % opaque ink (the retired cuts carried 24-38 % vertical air).
2 — DONE — all five cuts resized to the class masters and installed; C9 to 272x56.
3 — DONE — C3/C4 margins re-measured; §15.3 amended; §15.8 added.

## Tool counts (before -> after)
```
before (S37-F1 close): surfaces=232 too_small=169 DISTORT=0  band=1 failures=168 waived=2
after  (S37-B2):       surfaces=232 too_small=95  DISTORT=0  band=1 failures=95  waived=2
fails by class: C4=87, ui_panel_frame=4, C3=2, C7=1, ui_button_plate=1
C1/C2/C9: 0 failures.
```
C4 band 33 -> 67 px (slot 76); C3 band 4 -> 21 px (slot 32). The C4/C3 fails
left are **x-only**: the row content spans 92-97 % of its slot, so content +10 %
(the owner's pad) exceeds the slot itself (e.g. AUCTION 1756 slot, need 1878).

## Gate
- `XDG_DATA_HOME=$(mktemp -d) $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
  res://tests/headless_runner.tscn --quit-after 1200` -> `[SUMMARY] passed=1151 failed=0` (x2).

## Files touched
- `vajb-orbit/assets/ui/{ui_tile_slab,ui_action_bar,ui_inline_chip,ui_row_strip,ui_drawer_entry}.png` (binary, gitignored)
- `vajb-orbit/ui/theme/chrome_family.gd` — MARGINS C3/C4 + the header note
- `vajb-orbit/tests/test_s36_chrome_census.gd` — MEASURED_MARGINS C3/C4; CLASS_MASTERS C9
- `staging/cut_chrome_fit.py` — new cutter
- `docs/design/UI_SPEC.md` — §15.3 C3/C4 lines + §15.8
- `asset-library/raw/chrome_fit_2026-10-07/` — generation, cut sets, `class_cuts/`
- `asset-library/_prekey_backup/chrome_family_s37_2026-10-07/` — the retired five cuts

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| Right-size the C4 row content so content +10 % fits its slot (87 rows) | ticket | auction/overview/exchange/refinery/shipyard/armory `*_panel.gd` |
| C12 `ui_panel_frame` shell frames: content > the frame band (pre-existing) | ticket | `vajb_theme.tres` |
| C7 tooltip: seat text inside the side caps without moving N47's 360 label | ticket | `chrome_family.gd`, `tooltip.gd:38` |
| REFINERY `UpgradeButton` 187 px under C2's 272 floor (content +10 % over) | ticket | `refinery_panel.gd` |
