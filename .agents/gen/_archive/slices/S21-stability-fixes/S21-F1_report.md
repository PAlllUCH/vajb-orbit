---
slice: S21
worker: S21-F1
model: deepseek/deepseek-flash (reasoning-effort max)
status: informational
gate: "941/0 (R1's finished-tree count) → 941/0 on two fresh scratch stores, identical, exit 0 both"
---

# S21-F1 report — fixer, wave S21

## Result
Both findings this dispatch owns are closed at their named file:line: the MED's call
site is cured so the s20 chrome row's whole tail executes (the flip that printed 7/0
pre-fix now reads 6/1), and brief §8's tests-that-move table carries both s5 suites
with their moved figures. Gate **941/0** twice on fresh scratch stores; the pre-fix
`SCRIPT ERROR` (R1 log line 644) is absent from both. No LOW item, no refactor, no
pinned code value, no production file moved; `game/damage.gd` sha256 `5cabf3d9…6269`
= HEAD. Re-dispatched after the first attempt wedged; every Godot run below was
bounded with `--quit-after 1200` and its stdout redirected to a log read after exit.

## Finding-by-finding disposition
| Finding | Tier | Disposition |
|---|---|---|
| S21-R1/F1 — `tests/test_s20_chrome_unify.gd:276` | MED | **Fixed.** The row called the inner class's static on the panel instance (`panel.call(&"slot_plate_rect", …)`, a method the outer script does not have), so the function aborted on `SCRIPT ERROR: Invalid call. Nonexistent function 'slot_plate_rect (via call)'` and the plate-centring/size, BUY/X and L236 closure asserts never ran under a `[PASS]`. The call now reads `PanelScript.ConsolePanels.slot_plate_rect(…)` (`:276-278`). Proof with one temporary flip: R1 flipped the L236 expectation to `Vector2(0,0)` and still saw 7/0; post-fix the same flip (`:308`) prints `[FAIL] test_s20_chrome_unify.gd.test_ac2…: pinned at the plate's own minimum (L236)` → `passed=6 failed=1`; restored → 7/0. Zero `SCRIPT ERROR` in either full gate (R1's carried one). |
| S21-B2/F1 (= L246) — `S21_BRIEF.md` §8 | HIGH (bucket 2) | **Fixed** as the dispatched list amendment (S19-F1/L240 precedent, disclosed below): §8's table gains `test_s5_ammo_cargo.gd` + `test_s5_commerce.gd` with the moved values (`test_s5_ammo_cargo.gd:465-489` 10→1, 50→59; `:538-544` 50→59, 46→55; `test_s5_commerce.gd:493-497` `BUY`→`OWNED` iff owned) and cites L246; L246 now carries the closure. No test value and no production line changed for it, and no row count moved. |
| S21-B1/F1, S21-B2/F2, S21-B2/F3 (L247–L249) | LOW | **No action** — out of fixer scope; left open exactly as the review wrote them. |

## Deviations from the dispatch
- The HIGH's review fix-owner is "developer/designer session"; this dispatch executed
  that one list edit in the fixer pass, exactly L246's remedy and the S19-F1/L240
  precedent the dispatch names. Reversal: revert the §8 row and the L246 closure; the
  gate does not move (no code changed).
- L246 is closed in `_state/LOW_BACKLOG.md` with this report as the evidence pointer,
  per the L240 closure protocol.

## Evidence
- Pre-fix, from R1: `/tmp/s21_r1/gate_scratch.log:644` the `slot_plate_rect` SCRIPT
  ERROR; its flip of the L236 expectation measured 7/0.
- Post-fix scoped runs (`-- --suite=test_s20_chrome_unify`, fresh scratch store each,
  `--quit-after 1200`, log read after exit):
  - `/tmp/s21_f1/s20_fixed.log` → exit 0, `[SUMMARY] passed=7 failed=0`, no SCRIPT ERROR
  - flip `:308` → `/tmp/s21_f1/s20_flip.log` → exit 1, `[FAIL] … (L236)`, `passed=6 failed=1`
  - restored → `/tmp/s21_f1/s20_restored.log` → exit 0, `[SUMMARY] passed=7 failed=0`
- The two closing gates, one per fresh `mktemp -d` scratch store:
  - `XDG_DATA_HOME=/tmp/s21_f1/gate1.GSxiJo $GODOT_CONSOLE --headless --path "$VAJB_PROJ"
    res://tests/headless_runner.tscn --quit-after 1200` → exit 0,
    `[SUMMARY] passed=941 failed=0` (`/tmp/s21_f1/gate1.log`; 0 `SCRIPT ERROR`, 0
    `[FAIL]`/`[SKIP]`)
  - `XDG_DATA_HOME=/tmp/s21_f1/gate2.1HdU9R` same command → exit 0,
    `[SUMMARY] passed=941 failed=0` (`/tmp/s21_f1/gate2.log`; 0 `SCRIPT ERROR`, 0
    `[FAIL]`/`[SKIP]`)
- `sha256sum vajb-orbit/game/damage.gd` = `5cabf3d9302fe942aff2ad97b4f3dc85c298e7e204fffb0e86f89e444cbf6269`
  (= HEAD blob = the seal); `git diff --stat` empty for `damage.gd`, `npc_brain.gd`,
  `weapons.gd`.
- No temporary file remains: `ls vajb-orbit/tests/ | rg -i 'tmp|inner_check'` → none
  (the wedged attempt's `_tmp_inner_check.gd` was already removed by the orchestrator).

## Files touched
- `vajb-orbit/tests/test_s20_chrome_unify.gd` — MED: the call site now invokes
  `PanelScript.ConsolePanels.slot_plate_rect`; nothing else in the suite moved.
- `.agents/gen/slices/S21-stability-fixes/S21_BRIEF.md` §8 — HIGH: the two s5 suites
  added to the tests-that-move table with their moved figures, dated, L246 cited.
- `.agents/gen/_state/LOW_BACKLOG.md` — L246 disposition: `CLOSED in S21 (S21-F1,
  2026-09-29)`.

## Follow-ups
None new. L247–L249 remain open LOWs; the wave close-out (`verify_wave.py verify
--baseline s21_start`, WAVEBOARD, wave-boundary commit) is the orchestrator's and
untouched here.
