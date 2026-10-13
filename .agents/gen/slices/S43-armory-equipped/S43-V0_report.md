---
slice: S43
worker: S43-V0
model: hyper/glm-5.3-flash
status: actionable # the 3 moved-premise gate rows below must be re-cut before slice close
gate: "1330/0 (brief baseline) → 1347/3 (3 moved-premise rows, developer re-cut owed)"
---

# S43-V0 report

## Result
A fresh re-dispatch over two frozen runs: the partial tree was diff-verified against this
brief and is now complete. The FIT CELLS left sector carries the third EQUIPPED block
(caption, one row per fitted module in the grid's own order, flat Tokens rows in their own
scroll), both A4 doors (module BUY, ammo BUY) open the shell's confirm dialog with A6's
wording, and the confirmed answers run the unchanged transaction paths. The new suite is
9 rows, all green. The full gate carries exactly 3 failures, all one class: suites that
pin the old direct-buy press (below, Follow-ups) — no implementation can satisfy both
A4/A5 and those rows; I may not edit suites I did not write.

## Acceptance list answers
1 — third block under CELL INFO, caption `EQUIPPED — <n>/<slot count>` (StationCaption) —
    `armory_panel.tscn:193-216` (EquippedBlock after CellInfoBlock in FitLeftStack);
    caption counts at `armory_panel.gd:2203-2224` (fitted vs `_cells.size()`, which
    `_sync_grid` fills with non-gap cells only, `:3502-3512`).
2 — one row per fitted module in the grid's own order, empties skipped —
    `armory_panel.gd:2203-2224` walks `_cells` (row-major) and skips `&""` entries; cell id
    via `_cell_id` reusing CELL_INFO_ID's leading pair (`:147-149`, `:2333`); name
    `_module_name` (`:3298`); stat line `_effect_line`/`_stat_line` (`:2341-2356`, the
    `fitting_panel.gd:1634` idiom's twins); family glyph 24 via `_make_icon(…, 24)`
    (`:1886-1904`).
3 — flat Tokens rows + own scroll — `_apply_flat_chrome` (`:2319-2331`, item_bg fill,
    1 px metal_mid border, zero radius); RowInner inset 6 (`:2237-2242`); EquippedScroll
    (tscn `:205-216`, horizontal disabled, `size_flags_vertical = 3`).
4 — row press = grid selection — `_on_equipped_pressed` → `select_cell` (`:2293-2296`), so
    CELL INFO and the grid follow; the reverse direction mirrors in
    `_apply_equipped_selection` (`:2309-2317`), called from `_select` (`:3620`) and
    `clear_selection` (`:3657`).
5 — BATTERY CONFIG shows no list — the block rides `FitCells`, hidden by `_apply_mode`
    (`:1065-1076`); no mode branch in `_sync_equipped` itself.
6 — module BUY door — `_on_buy_pressed` → `_request_buy_confirm` (`:4631-4641`); OK →
    `confirm_action(ACTION_BUY_MODULE, base)` (`:4039`) → `_run_module_buy` →
    `_buy_into_cell` unchanged (`:4047`); a confirmed refusal keeps §5.6's strip wording
    (`_refuse`, `:3167`, STATUS_SHORTFALL `:394`).
7 — ammo door — `_on_row_pressed` → `_request_buy_confirm` with `AMMO_CONFIRM_NAME`
    (`:1974-1984`); OK → `confirm_action(ACTION_BUY_AMMO, id)` → `_run_ammo_buy` →
    `_purchase_ammo` (the unchanged transaction: refusal pulse + danger frame, `:4063`);
    the price quoted is the card payload's press-time `cost` (§5.8's clock law).
8 — new suite pins 1–7 — `tests/test_s43_armory_equipped.gd`, 9 rows (items 1-2 two rows,
    3 one, 4 two incl. the reverse direction, 5 one, 6 two incl. the refusal, 7 two incl.
    the refusal), `[SUMMARY] passed=9 failed=0`.

## Deviations from SLICE.md
- None against the brief. The disclosed route (bucket 1) was followed: the pane emits
  `confirm_requested` (`:82`) and the shell's own connect answers it
  (`station.gd:1289-1290`); station.gd untouched; focus-return/ESC are the seam's own.
- Inherited-tree fixes: the frozen run's test expected the drive's line as `SPEED ×1.00`;
  the pinned idiom's own format (`fitting_panel.gd:1639`, `String.num(value, 2)`) renders
  `×1.0` (measured: Godot 4.7.2 `String.num(1.0, 2)` → `1.0`), so the test row was
  corrected to the idiom's output — the code is the idiom, not the test's guess.
- `tests/_tmp_s43_probe.gd` (the frozen run's scratch) deleted; it could never have run
  clean (it loads armory_panel.gd outside the autoload environment — AudioManager).

## Evidence
- `-- --suite=test_s43_armory_equipped` → `[SUMMARY] passed=9 failed=0`.
- `-- --suite=test_s41_armory` → `[SUMMARY] passed=4 failed=0` (the brief's protected
  suite: no premise moved there).
- `python3 staging/gate.py --times 1` → `[GATE] run 1: FAIL - [SUMMARY] passed=1347
  failed=3`; raw engine re-run (own `XDG_DATA_HOME` scratch) attributes the 3, zero
  SCRIPT ERROR lines anywhere:
  - `test_p2b1_outfitting_panel.gd:485` "the buy charged the catalogue's cost" — the
    suite mounts `armory_panel.tscn` (the renamed OUTFITTING pane, `:35`) and presses the
    ammo card's BUY expecting the charge on that same press: A4/A5's door moves the
    premise by construction.
  - `test_s32_armory_modes.gd:420` "BUY charged the catalogue's price" — calls
    `_on_buy_pressed` directly then asserts the charge: same moved premise.
  - `test_s32_armory_modes.gd` `test_mode_actions_intact_through_the_public_doors` —
    same class, same door.
- Baseline note: the brief's 1330/0 (2026-10-12) predates S42's close (761edee); the
  current tree's full run is 1350 rows (1347 passed + 3). This slice's suite adds 9.

## Files touched
- `vajb-orbit/ui/station/armory_panel.gd` — the EQUIPPED block (signal, constants,
  `_sync_equipped` + row builder + selection mirror, the stat-line twins) and the two
  confirm doors (`_request_buy_confirm`/`confirm_action`/`_run_*`/`_purchase_ammo`).
- `vajb-orbit/ui/station/armory_panel.tscn` — EquippedBlock/Caption/Scroll/Rows under
  FitLeftStack; CellInfoBlock releases the slack (`size_flags_vertical = 0`).
- `vajb-orbit/tests/test_s43_armory_equipped.gd` — the 9-row suite (completed from the
  partial run; one expectation corrected to the idiom's output).

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| Re-cut the 3 moved-premise rows (answer the confirm through the seam's public `confirm_action` before asserting the charge) | gate rows, developer-owned | `test_p2b1_outfitting_panel.gd:477`, `test_s32_armory_modes.gd:399`, `:725` |

## Fixer amendment (developer, 2026-10-12 — post-review)
- **F1 (MED) cured:** the BUY & FIT cluster (`_on_buy_fit_pressed`) and a BUYABLE
  row's select-to-fit flow (`_on_browser_pressed`) are acquisition doors now —
  the same `_request_buy_confirm` (ACTION_BUY_MODULE, A6's wording) fronts
  them; owned-row fits stay dialog-free; the confirmed answer runs the same
  buy-then-fit path. The owner's own ask ("EVERY buy action needs to have
  popup") is the criterion reading; reversal: leave the two presses doorless.
  Pinned by the suite's `test_f1_the_buy_fit_cluster_and_the_buyable_flow_are_doors`
  (gate 1351/0).
- F2/F3 LOW → T-194 (the report's count parenthetical + frontmatter; the
  no-op stylebox loop at `armory_panel.gd`).
