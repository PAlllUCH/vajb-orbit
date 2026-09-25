---
slice: S18
worker: S18-F1
model: deepseek/deepseek-flash
status: informational
gate: "886/0 (baseline) → 886/0 (post-fix, two standalone runs, identical)"
---

# S18-F1 report — the two dead guards re-pinned

## Result
Both wave-introduced silent aborts are cured by re-pins only, no assertion
weakened: `test_s5_batteries_v2.gd:336` reads the shipped `PaneTitle` node,
`test_d7_armory.gd:720` casts the shipped `Control`. Each suite is green with
zero abort markers; the full gate stays `886/0`, twice.

## Deviations from SLICE.md
None. Production code, docs and every other test file untouched (the R1 MED is
the developer session's docs fix, not the fixer's).
- `tests/test_s5_batteries_v2.gd:336` — `get_node("PaneHeader/TitleBox/PaneTitle")`
  → `get_node(^"PaneTitle")` (the node the S18 scene moved to the panel root).
- `tests/test_d7_armory.gd:720` — `as HBoxContainer).get_child(0) as HBoxContainer`
  → `as Control).get_child(0) as Control` (matches the wave's sibling at :425).

## Evidence
All Godot runs headless, `--quit-after` bounded, each under a fresh
`XDG_DATA_HOME=$(mktemp -d)`.

1. **Suite s5** — `godot --headless --path vajb-orbit res://tests/headless_runner.tscn
   --quit-after 600 -- --suite=test_s5_batteries_v2` →
   `[SUMMARY] passed=13 failed=0`, exit 0; all 13 `test_*` functions print
   `[PASS]`; zero matches for `Invalid access to property or key`,
   `Cannot call method get_child on a null value`, `SCRIPT ERROR`.
2. **Suite d7** — same command, `--suite=test_d7_armory` →
   `[SUMMARY] passed=11 failed=0`, exit 0; 11/11 `[PASS]`; same zero matches.
3. **The gated assertions execute** (temporary value flips, each reverted and
   the revert re-run; final diff carries only the two re-pins):
   - s5 expected `"ARMORY"` → `"ARMORY_TYPO"` gave
     `[FAIL] …test_the_rail_says_armory_and_loads_the_renamed_pane: the pane's
     title reads the same word as the rail`, `passed=12 failed=1`, exit 1.
   - d7 close row `[1]` → `[9]` gave
     `[FAIL] …test_the_drag_ordering_and_the_close_are_unchanged: one barrel
     left`, `passed=10 failed=1`, exit 1.
4. **Negative control** (throwaway `tests/probe_s18f1_negctl.gd`, deleted after
   the runs; not a `test_*` file): replaying the two pre-fix forms logged
   `SCRIPT ERROR: Invalid access to property or key 'text' on a base object of
   type 'null instance'.` and `SCRIPT ERROR: Cannot call method 'get_child' on
   a null value.` — so the greps in 1–2 are sensitive to exactly the aborts
   being fixed.
5. **Full gate ×2** — `godot --headless --path vajb-orbit
   res://tests/headless_runner.tscn --quit-after 1200` (no `--suite`) →
   `[SUMMARY] passed=886 failed=0` and `[SUMMARY] passed=886 failed=0`, exit 0
   both; zero matches for the two target abort strings in either log.
6. **Diff scope** — `git diff -- vajb-orbit/tests/test_s5_batteries_v2.gd
   vajb-orbit/tests/test_d7_armory.gd` is exactly one hunk each (d7's diff also
   shows the wave's own uncommitted S18 rework; the fixer hunk is
   `test_d7_armory.gd:720`, the only line this pass added); no other file
   changed by S18-F1.

## Files touched
- `vajb-orbit/tests/test_s5_batteries_v2.gd` — one path re-pin (line 336)
- `vajb-orbit/tests/test_d7_armory.gd` — one cast re-pin (line 720)
- throwaway `tests/probe_s18f1_negctl.gd` created for evidence 4 and deleted;
  `git status` confirms no residue.

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| Same silent-abort class, pre-existing: `guns.call(&"_hide_beam")` runs after `_clear()` freed the rig — `SCRIPT ERROR: Cannot call method 'call' on a previously freed instance.` aborts the rest of the test while the harness prints `[PASS]`. Reproduces isolated (`--suite=test_weapon_fx_f4` → `passed=6 failed=0`, exit 0, same error); file and its deps are untouched by S18, so it is not wave-introduced and not in this fixer's file set. | pre-existing defect | `vajb-orbit/tests/test_weapon_fx_f4.gd:178` → ticket |
