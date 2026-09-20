# P1l report — market/profile/repairs/clock-log suites (P1l2 recovery)

Worker: coder. Tasks: `.agents/gen/p1l_task.md` + `.agents/gen/p1l2_task.md`. Status: **done, gate green** (exit 0, `failed=0`, no `SCRIPT ERROR`).

## Deliverables

Four suites, recovered from the stalled attempt and audited against every brief bullet and the docs:

| File | Suite id | Tests |
|---|---|---|
| `vajb-orbit/tests/test_p1_market.gd` | `p1_market` | 12 |
| `vajb-orbit/tests/test_p1_profile.gd` | `p1_profile` | 9 |
| `vajb-orbit/tests/test_p1_repairs.gd` | `p1_repairs` | 5 |
| `vajb-orbit/tests/test_p1_clock_log.gd` | `p1_clock_log` | 4 |

One of the four was edited (Fixes below); no other file changed except this report and the two evidence logs.

## Gate — command and summary

P1k's runner was present, so the gate used it. Full wave (exit 0):

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=51 failed=0
```

Scoped to the four P1l suites (`--suite=` flags after `--`):

```
... res://tests/headless_runner.tscn -- --suite=test_p1_market --suite=test_p1_profile --suite=test_p1_repairs --suite=test_p1_clock_log
[RUN] suites=test_p1_market,test_p1_profile,test_p1_repairs,test_p1_clock_log
[SUMMARY] passed=30 failed=0
```

No `[FAIL]`, no `[SKIP]`, no `SCRIPT ERROR`; the only WARNING is the deliberate negative-path one from
`test_unwritable_log_path_is_survivable`. `--check-only --script` never used. Logs: `.agents/gen/p1l_run.txt`,
`.agents/gen/p1l_run_scoped.txt`.

Per-suite counts, full run, one process: catalogues 10 · clock_log 4 · market 12 · pricing 5 · profile 9 ·
refinery 6 · repairs 5 = 51, failed 0. The P1l four are 30/51 full and 30/30 scoped, so they are independent
of their neighbours in the directory.

## Fixes made to the stalled attempt's suites

Audited every brief bullet against `05_exchange.md` §2/§4/§5, `01_economy_core.md` §6/§7 and
`17_coder_handoff.md` §3/§6. The suites already encoded the documented numbers (quota 40/15/4; drift ±0.15
clamped to [0.6, 1.6]; trade impact 0.01/unit floored at 0.6; commission 2 % with the 10 CR ceil floor;
surplus `round(baseline × 0.9)`; Vanguard 20 %/50 % → 500 CR at `(800/2)+(300/3)`; shield ≥ 90 % exemption;
six-field log line; migration read leaving the file at `save_version` 1). One gap found and fixed:

- `test_p1_market.test_first_evaluation_stamps_and_restocks` checked "fills every component stock with its
  quota" by sampling three ids. It now keeps the doc-cited numbers for one item per grade **and** loops over
  `ComponentCatalog.COMPONENTS` asserting each stocked id equals `Exchange.quota_for(its own grade)`, so a
  per-item restock bug cannot hide behind the sample. Module behaviour unchanged; the suite is still green.

No test was deleted, weakened or skipped. **Module bugs found: none** — `game/exchange.gd`,
`autoload/player_profile.gd`, `game/repairs.gd`, `autoload/world_clock.gd`, `game/economy_log.gd` and the
three catalogues match their contracts, so no module was edited.

## Leftovers, isolation and gate sensitivity

- `tests/_p1l_probe.gd`, `_p1l_probe.tscn` and their `.uid` files were already absent when I started: a
  `*_p1l_probe*` workspace glob and a `tests/` listing show no `probe`/`p1l` artefact. My scratch probe and the
  temporary capture directory `.agents/gen/tmp/` are deleted; `tests/` holds only the runner, its scene and the
  seven suites.
- GUI binary never launched: every invocation was the `_console.exe` with `--headless` and `--quit-after`, each
  finishing in seconds. No MCP tool, no editor run — shell only. Nothing outside `vajb-orbit/tests/` and this
  report was edited.
- `user://profile.cfg` untouched: MD5 `9BDC13BB2A60E6BB5A7B7131B033F8BC` and mtime `2026-09-18 12:30:42`
  identical before and after three full runs. `user://economy_log.txt` does not exist and no `test_p1_*.cfg` /
  `test_p1_log.txt` survived in the user data directory.
- Gate sensitivity: a throwaway `tests/test_p1l_gate_probe.gd` with one deliberate `assert_eq(1, 2)` gave
  `[FAIL]` / `[SUMMARY] passed=0 failed=1` and **exit 1**, so the green line above is evidence, not a rubber
  stamp. It was deleted; a headless run leaves no `.uid` sidecar for it.

## Deviations and reviewer notes

1. The previous attempt **did** write this report (mtime 12:32), contrary to the addendum's assumption.
2. Suites never add a profile to the tree, so `_ready()` never runs and there is no debounce Timer: mutations
   write through synchronously, which is what makes the round trips exact. A fresh instance therefore carries
   compile-time field defaults (`_owned_ships`, `_ammo` empty until a load); the suites assert ammo/ship
   defaults on the v1 migration path, where `_read_values()` applies them.
3. Nested-dictionary `assert_eq` is not dependable across a ConfigFile round trip (key order), so the two
   state-comparing suites use a local `_deep_eq()`. Profiles are freed in `teardown()`; the headless runner
   never calls `_free_tracked`, so tracked cleanup is not relied on.
4. The clamp tests choose seeds rather than guess: `_seed_with_first_step` scans for a first drawn step of at
   least ±0.10, so the clamp is truly exercised. The exact demand index goes in via `set_market`, as no public
   API exposes one.
5. `user://profile.cfg` is stale from before this task; nothing in the wave reads or writes it.
6. `05_exchange.md` §6's confirm strip ("GROSS 1 140 · FEE 23 · YOU GET 1 117") disagrees with §3/§5 for 10
   gold ingots: a P1i pricing wording issue already recorded by P1d, not asserted here.
