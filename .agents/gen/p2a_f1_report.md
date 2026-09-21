# P2-A — F1 report: the fixer pass (R1-M1, one pass)

**Worker:** F1 (coder — fixer). **Wave:** P2-A ship slot frames.
**Brief (law):** `.agents/gen/p2a_slot_frames_wave_task.md` §4 row F1 + §5 + §6.
**Review (authority):** `.agents/gen/p2a_r1_report.md` §10.
**File set (`VAJB_WORKER_FILES`):** `vajb-orbit/tests/` — nothing else was written.

**Verdict: one fix, one MED (R1-M1). No HIGH was assigned (R1 found none), so one MED is
the whole pass. The gate is green and grew 370 → 372; R1's own repro command goes
1 P2-A row → 0; R1's frames probe is byte-identical to its record.**

| Tier | Finding | Status |
|---|---|---|
| HIGH | none — R1 §10 "HIGH — none" | — |
| MED | **R1-M1** — `tests/test_p2a_ship_roster.gd:10` shadowed the global class `ShipFit`, the wave's only row in the `--debug` warning ledger | **FIXED** + regression test |
| LOW | R1-L1…L6 — not assigned to F1 | untouched (they are backlog items, not this pass's) |

---

## 1. The evidence, by file

| Evidence | File |
|---|---|
| The gate, before (R1's own debug command on the pre-fix tree) | `.agents/gen/f1_before_gate_debug.log` |
| The gate, after | `.agents/gen/f1_after_gate.log` |
| R1-M1's own repro command, after | `.agents/gen/f1_after_gate_debug.log` |
| The negative control (the construct put back, the new test expected to fail) | `.agents/gen/f1_negative_control.log` |
| R1's frames probe re-run after the fix | `.agents/gen/f1_after_r1_frames.log` |

Re-runnable commands (Linux host; `godot` = 4.7.2-stable):

```text
godot --headless --debug --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
    # R1-M1's repro: then
    grep -A1 "^WARNING" <log> | grep "test_p2a"
godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 400 -- --suite=test_p2a_lint_shadow
godot --headless --path vajb-orbit res://tests/probe_r1_frames.tscn --quit-after 600
```

---

## 2. R1-M1 — the wave's own file shadowed a global class

### 2.1 Before (R1's own command, run by F1 on the untouched tree, first)

```text
$ godot --headless --debug --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=370 failed=0
EXIT=0

$ grep -A1 "^WARNING" .agents/gen/f1_before_gate_debug.log | grep "test_p2a"
     at: GDScript::reload (res://tests/test_p2a_ship_roster.gd:10)
count=1
```

The row itself, verbatim:

```text
WARNING: The constant "ShipFit" has the same name as a global class defined in "ship_fit.gd".
     at: GDScript::reload (res://tests/test_p2a_ship_roster.gd:10)
```

`grep -c '^WARNING'` over the whole ledger = **43**, and the rows per file reproduce R1's
§10 inventory exactly. F1 also re-measured the cause independently, name-based, to know the
detector it would need for the test:

```text
$ python3 <<'PY'   # every `const <Name>` under tests/ whose name is a project `class_name`
name-based const hits (any RHS): 3
   vajb-orbit/tests/test_engine2_npc.gd      line 21  SectorRegistry  (pre-existing)
   vajb-orbit/tests/test_p1_repairs.gd       line 11  Repairs         (pre-existing)
   vajb-orbit/tests/test_p2a_ship_roster.gd  line 10  ShipFit         (this wave)
```

Three sites, three ledger rows, one per site, in the same run — so the name-based reading and
the compiler's warning are the same instrument, which is what the new test rides on.

### 2.2 The fix

`tests/test_p2a_ship_roster.gd` — three lines, no behaviour change; the preload stays, only the
identifier moves (R1's prescribed cure, `FitData`, the same name R1's own
`tests/probe_r1_migration.gd:16` already uses for the identical preload):

```diff
-## hull's W-slot count (`ShipFit.HULLS[id].weapons`, the same value 08 section 3's
+## hull's W-slot count (`FitData.HULLS[id].weapons`, the same value 08 section 3's
-const ShipFit := preload("res://game/ship_fit.gd")
+const FitData := preload("res://game/ship_fit.gd")
-		var hull: Dictionary = ShipFit.HULLS.get(ship_id, {})
+		var hull: Dictionary = FitData.HULLS.get(ship_id, {})
```

That is the const declaration, its one read, and the doc comment that named it. The file's
other const (`Catalog`) was never a global class name and is untouched. The human-readable
assertion string at `:149` ("`%s is a ShipFit hull`") still says `ShipFit` on purpose: it names
the product class the hull must exist in, and a string is not an identifier.

### 2.3 After (R1's own command, unchanged)

```text
$ godot --headless --debug --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
EXIT=0
--- P2-A rows (R1-M1's repro grep) ---
NONE
--- ledger totals ---
before=43 after=42
      8 res://tests/test_engine2_cleaving.gd      <- the remaining rows, unchanged
      7 res://game/speed_fantasy.gd
      4 res://game/npc_ship.gd
      4 res://game/npc_brain.gd
      3 res://tests/test_p1_market.gd
      3 res://game/projectile.gd
new suite: no warning rows
```

The ledger drops by exactly the one row the finding named, and the wave's new suite
contributes zero rows — the house bar for a new file ("zero rows", R1 §10).

---

## 3. The test the fix added — `tests/test_p2a_lint_shadow.gd` (2 tests)

R1-M1 is a lint finding, so the regression guard is an instrument, not an assertion on the
renamed identifier: a test that re-derives the rule the compiler warns from and fails on any
new site. It reads `ProjectSettings.get_global_class_list()` — the same table the compiler
warns from, confirmed readable headless by a throwaway probe before the suite was written
(`entries=90 ShipFit_entries=1 has=true`; probe deleted) — and scans every `res://tests/test_*.gd`
for a `const <Name>` whose name is one of those classes. The rule is name-based; the
right-hand side plays no part, which is why the detector matches the ledger 3 sites ↔ 3 rows.

| Test | What it asserts |
|---|---|
| `test_no_const_shadows_a_global_class_outside_the_pre_existing_sites` | Any such site is a failure **unless its file is in `PRE_EXISTING`** (the two pre-wave sites measured above, outside this pass's mandate). Guards the ledger against growth from anywhere in `tests/`. The offender message carries `file:line`, the const, the class it shadows and the cure. Guards vacuity with `assert_gt(globals.size(), 0, …)`. |
| `test_wave_owned_suites_declare_no_shadowing_constant` | Wave P2-A's five suites (`test_ship_grids`, `test_p2a_profile_fits`, `test_p2a_launch_fit`, `test_p2a_ship_roster`, `test_ui_slot_layout`) hold the house bar of **zero sites, no exception** — and the test fails if a wave file is ever added to `PRE_EXISTING`. |

### 3.1 Negative control — the test fails when the construct comes back

The construct was put back verbatim (const and both reads) and the suite re-run; the tree was
then restored and checked byte-for-byte (`md5sum` equal before and after the run).

```text
$ godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 400 -- --suite=test_p2a_lint_shadow
EXIT=1
[FAIL] test_p2a_lint_shadow.gd.test_no_const_shadows_a_global_class_outside_the_pre_existing_sites: a constant may not share a global class's name - rename the constant:
[FAIL] test_p2a_lint_shadow.gd.test_wave_owned_suites_declare_no_shadowing_constant: test_p2a_ship_roster.gd declares no constant named after a global class: line 10: const ShipFit
[SUMMARY] passed=0 failed=2

$ md5sum /tmp/f1_roster_fixed.gd vajb-orbit/tests/test_p2a_ship_roster.gd
1e4101be3b8560f733d087e7f0ec7f8b  /tmp/f1_roster_fixed.gd
1e4101be3b8560f733d087e7f0ec7f8b  vajb-orbit/tests/test_p2a_ship_roster.gd
```

Green on the fixed tree:

```text
$ godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 400 -- --suite=test_p2a_lint_shadow
[PASS] test_p2a_lint_shadow.gd.test_no_const_shadows_a_global_class_outside_the_pre_existing_sites
[PASS] test_p2a_lint_shadow.gd.test_wave_owned_suites_declare_no_shadowing_constant
[SUMMARY] passed=2 failed=0
```

---

## 4. The gate: green, and the count grew by the two tests

```text
$ godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
EXIT=0
[SUMMARY] passed=372 failed=0        (before this pass: passed=370 failed=0)
PASS lines: 372      FAIL lines: 0
```

Per suite, so nothing shrank and nothing was hidden:

| Suite | before | after |
|---|---:|---:|
| `test_ship_grids` | 27 | 27 |
| `test_p2a_profile_fits` | 11 | 11 |
| `test_p2a_launch_fit` | 12 | 12 |
| `test_p2a_ship_roster` | 4 | 4 (renamed const, same four tests, all passing) |
| `test_ui_slot_layout` | 12 | 12 |
| **`test_p2a_lint_shadow`** | 0 | **2 (new)** |
| **total** | **370** | **372** |

The one `SCRIPT ERROR` in the after log is the pre-existing `Cannot call method 'call' on a
previously freed instance.` at `tests/test_weapon_fx_f4.gd:176` — CONTRACTS §9 / LOW_BACKLOG
**L61**, in a file this pass did not touch, and its test passes. No new `SCRIPT ERROR`, and
`grep -c "unknown hull id"` = 0 as before.

---

## 5. Non-regression: R1's own probe, re-run unchanged

A test-only change must not move the wave's data, so R1's full frames probe was re-run and
diffed against R1's recorded output:

```text
$ godot --headless --path vajb-orbit res://tests/probe_r1_frames.tscn --quit-after 600
EXIT=0     FAILs=0     [r1] ok lines=130   (R1's record: 130)
$ diff <(grep -E '^\[r1\]' .agents/gen/f1_after_r1_frames.log) \
       <(grep -E '^\[r1\]' .agents/gen/p2a_r1_probe_frames.txt)
diff lines: 0
```

All 130 lines byte-identical: the nine matrices, the engine A/B against HEAD's `ship_fit.gd`,
the three consumers' per-hull cells/columns/brief rows and the roster are exactly where R1
left them.

---

## 6. What F1 touched, and what it did not

| File | Change |
|---|---|
| `vajb-orbit/tests/test_p2a_ship_roster.gd` | the three lines of §2.2 (R1-M1's fix) |
| `vajb-orbit/tests/test_p2a_lint_shadow.gd` | **new** — the two-test regression guard of §3 |
| `.agents/gen/f1_*.log`, this report | evidence |

Nothing else. `git status --porcelain` shows the other modified files are the wave's own
workers' (docs = D0, `game/*` = W1/W4, `ui/*` = W5, `station_catalog.gd` = W3) and are
unchanged by this pass; `assets/**`, the theme (`ui/theme/vajb_theme.tres`, `tools/build_theme.gd`),
`project.godot`, `addons/**` and `docs/**` were not written. No LOW was fixed: R1-L1…L6 are
backlog/close-out items, not this pass's mandate, and R1-L3/L4/L6 are doc-record items D0 and
the orchestrator own. The throwaway probe F1 used to confirm the global-class API
(`tests/probe_f1_globals.gd`) was deleted after its single run.

**Nothing in R1's report called for a game-logic change, and none was made** — the MED was a
lint row in a test file, so this pass is one rename plus its guard.

---

## 7. Residuals, stated rather than hidden

1. **Two pre-existing shadowing sites ride forward, named in the new test.**
   `tests/test_engine2_npc.gd:21` (`SectorRegistry`) and `tests/test_p1_repairs.gd:11`
   (`Repairs`) carry the identical construct and each own one row of the ledger's remaining 42.
   They are not part of R1's M1 (which is scoped to the wave's own row) and both files sit
   outside a fixer pass's mandate, so the new test records them in `PRE_EXISTING` instead of
   editing them; `test_wave_owned_suites_declare_no_shadowing_constant` asserts no P2-A file can
   ever be excused by that list. They are worth one LOW_BACKLOG line each — the cure is the same
   one-line rename — but F1 did not add them, because the fixer's scope is R1's findings.
2. **`test_p2a_lint_shadow.gd` has no `.uid` sidecar yet**, while every other file the wave
   added has one. `.uid` files are generated by the editor's scan, not by a headless run (the
   gate loads the suite and passes without it), and running an editor pass is outside this
   pass's mandate; the close-out's reimport will create it alongside the rest. Flagged so it is
   committed with the wave rather than lost.
3. **The guard is scoped to `tests/`**, which is where the wave's files, and the finding, live.
   A shadowing const in `game/**` or `ui/**` would not be seen by this suite; no such site
   exists today (the 34 `class_name` declarations are the only global classes, and the
   non-test rows in the ledger are other warning kinds), and widening the scan to the whole
   project would put product files under this wave's instrument, which is not F1's call.
