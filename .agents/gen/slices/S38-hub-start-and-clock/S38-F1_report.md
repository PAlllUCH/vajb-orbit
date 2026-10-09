---
slice: S38
worker: S38-F1
model: "hyper/deepseek-v4.1-flash"
status: informational
gate: "1236/0 → 1236/0 ×2 (fresh scratch stores)"
---

# S38-F1 report

## Result
S38-R1's one MED is cured: `test_a8_the_launch_line_names_the_docked_sector`'s last leg now
states H1's meaning of an empty filed id (the cold start at Halcyon) instead of the retired "a
profile with no place" wording, and the leg carries a comment saying so. No assertion outcome,
no value and no leg structure moved: the call still files `&""`, the assertion is still the same
`assert_false(...contains("HELIOS"))`, and the row still passes. Gate `passed=1236 failed=0`
twice on fresh scratch stores (was `1236/0` after the developer's seven re-cuts; F1 moves no
row). F2/F3 (LOW, T-158/T-159) were not touched per the orchestrator note.

## Fix-list answers
- **F1 (MED) — DONE.** `tests/test_s25_contracts.gd:1206-1212`: the message restated from "and a
  profile with no place still names no dead sector" to "an empty filed id is the cold start and
  still names no dead sector", with a 3-line comment above the `set_docked_station(&"")` call
  stating H1 (an empty id is the cold start and answers the starting place; the leg's outcome is
  unchanged because HALCYON REACH carries no HELIOS). The assertion, its condition, the filed
  value and the leg order are byte-identical to R1's reviewed tree.
- **F2 (LOW) — NOT FIXED (ticketed T-158).** `tests/probe_s38_start_board.gd:30,144-146`
  untouched, per the orchestrator note.
- **F3 (LOW) — NOT FIXED (ticketed T-159).** `autoload/world_clock.gd` untouched, per the
  orchestrator note.

## Added test rows
None. F1 changes no assertion outcome, so nothing new is proven and no row is added or removed;
the suite's per-`func test_` count is unchanged (`test_s25_contracts` alone reads `passed=24
failed=0`).

## Evidence
- **Negative control (non-vacuity).** `assert_false(line.contains("HELIOS"))` would pass on an
  empty string for free, so the leg was measured with a throwaway probe
  (`res://tests/probe_s38_f1_control.tscn`, deleted after the run; the tree carries no trace):
  `[S38F1] empty_filed line=OPEN SPACE · HALCYON REACH len=26 contains_helios=false` ·
  `[S38F1] filed_s1_primary line=OPEN SPACE · HALCYON REACH same_as_empty=true` ·
  `[S38F1] control_ok=true`. The cold-start line is a real 26-char name (not empty), it equals
  the line the explicitly filed `s1_primary` produces (H1's empty-id resolution, measured), and
  it carries no HELIOS. So the leg exercises a live value and its outcome is genuinely unchanged.
- **Scoped suite.** `XDG_DATA_HOME=$(mktemp -d) $GODOT_CONSOLE --headless --path "$VAJB_PROJ"
  res://tests/headless_runner.tscn --quit-after 1200 -- --suite=test_s25_contracts` →
  `[PASS] test_s25_contracts.gd.test_a8_the_launch_line_names_the_docked_sector` and
  `[SUMMARY] passed=24 failed=0`.
- **Gate run A.** `XDG_DATA_HOME=$(mktemp -d) $GODOT_CONSOLE --headless --path "$VAJB_PROJ"
  res://tests/headless_runner.tscn --quit-after 1200` → `[SUMMARY] passed=1236 failed=0`, exit 0.
- **Gate run B** (fresh scratch store) → `[SUMMARY] passed=1236 failed=0`, exit 0. The two lines
  are identical.
- **Wave diff.** `python3 staging/verify_wave.py verify --baseline s38_start --forbidden
  vajb-orbit/project.godot vajb-orbit/addons/ --tests` → `"problems": []`; the modified set is
  the wave's files plus `tests/test_s25_contracts.gd` (F1's one line), the added set is the
  wave's four; no file outside F1's mandate moved.

## Files touched
- `vajb-orbit/tests/test_s25_contracts.gd` — the A8 last leg's comment + message only
  (`:1206-1212`); the `set_docked_station(&"")` value and the `assert_false` are unchanged.

## Follow-ups
- **Outside-mandate observation (not fixed: the orchestrator's note scopes F1 to R1's named
  finding, and a change to B1's suite would invalidate R1's grade unreviewed).**
  `tests/test_s38_start_and_clock.gd:204` calls `panel.call(&"_station_row")`, but
  `_station_row` is a **variable** on `contracts_panel.gd:143`, not a method. The call raises
  `SCRIPT ERROR: Invalid call. Nonexistent function '_station_row (via call)' in base
  'VBoxContainer (contracts_panel.gd)'` and **aborts the rest of
  `test_a1_the_cold_start_offers_the_full_board`** at that line, so its `:203-206` station-row
  assertion and `:207` `assert_true(screen != null)` never run while the harness prints
  `[PASS]` (the S18-F1/L237 silent-abort class). Reproduced in isolation:
  `--suite=test_s38_start_and_clock` → `passed=10 failed=0` with the one SCRIPT ERROR; the row's
  `:179-202` assertions do run and pass. Recommended cure (one line): read the variable with
  `panel.get(&"_station_row")` instead of `call`. This is the wave's only new red line and R1's
  review did not list it.
- **Gate red lines, re-measured.** My runs carry exactly two: the `_station_row` SCRIPT ERROR
  above, and `ERROR: Parameter "data.tree" is null.` (the tolerated `weapons.gd` one). The
  `tests/test_weapon_fx_f4.gd` `_clear()` SCRIPT ERROR named by `CONTRACTS.md:974` and repeated
  in R1's review is **absent** from every run (`--suite=test_weapon_fx_f4` alone: `passed=6
  failed=0`, zero SCRIPT ERROR), consistent with backlog L237 having closed it in S21; §9's
  tolerated-red-line text therefore names an error that no longer occurs and misses the one that
  does. `CONTRACTS.md` is R1's file, not mine, so it is reported, not edited.
