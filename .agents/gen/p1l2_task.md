# P1l2 task — recover and finish the P1 test wave (supersedes the stalled P1l run)

Read `.agents/gen/p1l_task.md` first, then this addendum. A previous P1l
attempt stalled (it launched a GUI Godot process that never exited and was
killed). Its four suites already exist on disk:

- `vajb-orbit/tests/test_p1_market.gd`
- `vajb-orbit/tests/test_p1_profile.gd`
- `vajb-orbit/tests/test_p1_repairs.gd`
- `vajb-orbit/tests/test_p1_clock_log.gd`

Treat them as WIP: verify every suite against the P1l brief and the gameplay
docs, fix what is wrong, make them pass.

Leftovers to delete once done (and confirm gone):

- `vajb-orbit/tests/_p1l_probe.gd`, `_p1l_probe.tscn`, and any `.uid` for them.

## Hard rules (a previous worker violated these and hung)

- **NEVER launch the GUI Godot binary.** Every run uses the console binary:
  `"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe"` with `--headless`.
- Every Godot invocation must have `--headless` and either `--quit-after` or a
  runner that quits itself. If a command produces no output for 2 minutes,
  kill it and investigate; do not let it hang.
- Suites must never touch `user://profile.cfg` or `user://economy_log.txt`
  (redirect `save_path` / `log_path` first, clean up after).
- Do not edit any file outside `vajb-orbit/tests/` and the report.
  Exception: if a test failure uncovers a genuine bug in the modules, fix the
  module minimally and document it in the report with the failing test name,
  the bug, and the fix.

## Gate

Run the P1k runner headless until green:

    "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tests/headless_runner.tscn --quit-after 1200

Requirements: `[SUMMARY] passed=<all> failed=0`, exit 0, no `SCRIPT ERROR`.
`--check-only --script` is forbidden (known false negatives).

## Report

Overwrite `.agents/gen/p1l_report.md` (the old attempt never wrote one) with:
deliverables, exact command + `[SUMMARY]` line, per-suite test counts, fixes
made to the stalled attempt's suites, module bugs found (if any), and
leftover-cleanup confirmation. Under 100 lines.
