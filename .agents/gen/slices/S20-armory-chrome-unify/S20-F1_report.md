---
slice: S20
worker: S20-F1
model: "deepseek/deepseek-flash"
status: actionable
gate: "895/0 → 895/0 (two fresh scratch stores)"
---

# S20-F1 report — fixer, wave S20

## Result
One in-scope finding fixed: A4.1's retirement is now complete on disk — the pane
scene carries no `ui_armory_console` reference and no plate texture assignment.
Gate `895/0` twice on fresh `XDG_DATA_HOME` scratch stores, identical counts.
F1/F2 left untouched as bucket-2 escalations (orchestrator scope note).

## Finding-by-finding disposition

| Finding | Tier | Disposition |
|---|---|---|
| S20-B1/F1 `tests/test_d7_armory.gd:601-608` danger-tone row | HIGH (bucket 2) | **Escalated, no code change** — as dispatched: the row moved off the tests-that-move list; the expected colour is forced by A4.3's 4.5:1 (`accent_danger` 4.377:1 vs `accent_danger_bright` 4.855:1). Remedy is a list amendment by the developer/designer session, not a revert. `test_d7_armory.gd` untouched by me. |
| S20-B1/F2 `tests/test_d7_armory.gd:817-818` caption rows | HIGH (bucket 2) | **Escalated, no code change** — same class: byte-identical values (`#acb2ba`/`#969da5` ≡ `Tokens/armory_caption[_void]`), forced by A4.3's zero-hex rule. List amendment, no revert. `test_d7_armory.gd` untouched by me. |
| S20-B1/F3 `ui/armory_panel.tscn:4,27` retired console master still wired | MED | **Fixed.** Two content lines removed: the `2_console` `ext_resource` (was line 4) and `texture = ExtResource("2_console")` on `%ConsolePlate` (was line 29). As a direct consequence the scene header count is corrected `load_steps=4` → `2` (1 ext + 0 sub + 1, the convention every sibling `ui/station/*.tscn` follows; the old 4 was already one too high). No other line touched; the master file stays on disk (asserted green), and the pane's build-time null-clear still stands untouched in `armory_panel.gd:870`. |
| S20-B1/F4/F5/F6 (L234–L236) | LOW | **No action** (out of fixer scope; ticketed by the review). |

## Evidence
- Fix verify: `rg -n 'ui_armory_console|2_console' vajb-orbit/ui/station/armory_panel.tscn`
  → no match (exit 1); `git diff` = 4 lines (`1 insertion, 3 deletions`) in that one file.
- Gate 1: `XDG_DATA_HOME=$(mktemp -d; /tmp/tmp.HBA8uccvCf) godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200` → exit 0
  `[SUMMARY] passed=895 failed=0`
- Gate 2 (fresh store `/tmp/tmp.0lLblq9teM`, same command) → exit 0
  `[SUMMARY] passed=895 failed=0`
- Log scan: 0 `[FAIL]`, 0 `[SKIP]`, no `armory_panel.tscn` load error in either
  `/tmp/s20_f1_gate{1,2}.log`. The single `SCRIPT ERROR` per run is the
  pre-existing `test_weapon_fx_f4.gd:178` freed-instance call (L237, untouched
  suite, deterministic on both runs).
- Acceptance coverage re-run by the gate: `test_s20_chrome_unify.gd`
  `test_ac1_the_console_master_retires_for_the_panel_frame` (plate non-null,
  texture `null`, master on disk), `test_d7_armory.gd:325-341` and
  `test_s15_armory_layout.gd:212-224` plate rows all green.

## Files touched
- `vajb-orbit/ui/station/armory_panel.tscn` — F3: master ext_resource + plate
  texture assignment dropped; header `load_steps` corrected to 2.

## Deviations from the dispatch
The review described F3 as "2 lines"; the shipped fix also corrects the header
`load_steps` count the removed resource was part of (4 → 2). This is scene
metadata, not a pinned value and not geometry — the Amendment 3 geometry is
byte-identical — and it matches the `ext + sub + 1` convention of every other
scene in the project. Reversal: restore `load_steps=4`.

## Follow-ups
None from this pass. F1/F2 remain with the developer/designer session (bucket-2
list amendment); L234–L236 and L237 remain ticketed as the review left them.
