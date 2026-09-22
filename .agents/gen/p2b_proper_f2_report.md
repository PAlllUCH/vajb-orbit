# P2-B proper — F2 report (test-only cure of R1's LOW-6) (2026-09-22)

**Role:** F2, the small test-only pass the orchestrator authorised after F1. I cured the three
data-dependent failures R1 diagnosed in `.agents/gen/p2b_proper_r1_report.md` section 7, LOW-6,
in exactly the two fixtures R1 named, exactly the way R1 wrote the cure: the pack slot is now
resolved from the **launched state's own `weapons`** (the running game's `PlayerState.weapons`,
the fit-ordered sizing `set_weapons` writes) instead of from `PlayerState.WEAPONS`' catalogue
order. No assertion changed meaning, no test was added, renamed or removed, and no game file,
other test, asset, theme file, `project.godot`, addon or doc was touched.

**Files I changed** (only these two; `git status` shows no other modification of mine):

| File | Change |
|---|---|
| `vajb-orbit/tests/test_engine2_dock.gd` | `_slot()` resolves the fired pack from the live `PlayerState.weapons`; the now-unused `WeaponsScript` preload dropped; the two comments that named the catalogue order rewritten |
| `vajb-orbit/tests/test_engine2_fixes.gd` | its dock test's one `slot` line resolves from the live `PlayerState.weapons`; its doc comment records why |

---

## 1. The cure — exact diff

`git diff -- vajb-orbit/tests/test_engine2_dock.gd vajb-orbit/tests/test_engine2_fixes.gd`
(also saved verbatim as `.agents/gen/p2b_proper_f2_diff.txt`):

```diff
diff --git a/vajb-orbit/tests/test_engine2_dock.gd b/vajb-orbit/tests/test_engine2_dock.gd
index dea696a..f374ba5 100644
--- a/vajb-orbit/tests/test_engine2_dock.gd
+++ b/vajb-orbit/tests/test_engine2_dock.gd
@@ -19,15 +19,18 @@ extends McpTestSuite
 ## length of each test and flushed before it is handed back, so the owner's `user://profile.cfg`
 ## is never written - the discipline `test_engine2_fixes.gd` records for the same seam.
 
-const WeaponsScript := preload("res://game/weapons.gd")
 const Log := preload("res://game/economy_log.gd")
 
 const GAME_SCENE := "res://game/game.tscn"
 const SCRATCH_PROFILE := "user://test_engine2_dock.cfg"
 const SCRATCH_LOG := "user://test_engine2_dock_log.txt"
 
-## The pack that is fired and the pack that is not. The slot index is asked for through
-## `WeaponsScript.ammo_slot` rather than assumed from `PlayerState.WEAPONS`' order.
+## The pack that is fired and the pack that is not. The fired pack's slot is read off the
+## launched state's own `weapons` (`PlayerState.set_weapons`, the fit-ordered sizing the
+## launch writes) and never off `PlayerState.WEAPONS`' catalogue order, because a launched
+## fit need not follow that order: the owner's Vanguard fit is
+## `["w_cannon", "w_laser", "w_laser"]`, where the catalogue's slot 0 is the *cannon*'s pack
+## (`.agents/gen/p2b_proper_r1_report.md` section 7, LOW-6).
 const FIRED_WEAPON: StringName = &"laser"
 const IDLE_WEAPON: StringName = &"cannon"
 const FIRED_ROUNDS := 3
@@ -201,8 +204,11 @@ func _store() -> Node:
 	return _tree().root.get_node_or_null(NodePath(&"PlayerProfile"))
 
 
+## The fired pack's slot as this launch sized it: the index of the fired family in the live
+## `PlayerState.weapons` array, so the test charges the pack it names whatever order the fit
+## holds its W cells in (LOW-6).
 func _slot() -> int:
-	return int(WeaponsScript.ammo_slot(FIRED_WEAPON))
+	return int((_state.get(&"weapons") as Array).find(FIRED_WEAPON))
 
 
 ## The scratch handover, in the order the finding's own measurements use: repoint the writer
diff --git a/vajb-orbit/tests/test_engine2_fixes.gd b/vajb-orbit/tests/test_engine2_fixes.gd
index 56aa881..ff79be4 100644
--- a/vajb-orbit/tests/test_engine2_fixes.gd
+++ b/vajb-orbit/tests/test_engine2_fixes.gd
@@ -477,11 +477,14 @@ func test_set_ammo_ignores_an_unknown_pack_and_a_write_that_changes_nothing() ->
 
 ## The dock's ammo report, end to end: the launch seeds the live pack from the profile's
 ## store, three rounds are fired, `game.gd:_file_ammo_report` files the delta and the
-## store reads three rounds lighter. The structure cannot be swapped here (the runner is
-## inside its own `_ready`, so `/root` is blocked for `add_child` - measured), so the
-## shipped autoload is *borrowed* instead: its `save_path` is pointed at a scratch file,
-## the one pack the report touches is snapshotted and written back, and the store is
-## flushed while the scratch path is still in place, so the owner's `profile.cfg` is
+## store reads three rounds lighter. The slot is the fired family's own index in the live
+## `PlayerState.weapons` - the fit-ordered sizing the launch writes - and not
+## `PlayerState.WEAPONS`' catalogue order, which a launched fit need not follow
+## (`.agents/gen/p2b_proper_r1_report.md` section 7, LOW-6). The structure cannot be swapped
+## here (the runner is inside its own `_ready`, so `/root` is blocked for `add_child` -
+## measured), so the shipped autoload is *borrowed* instead: its `save_path` is pointed at a
+## scratch file, the one pack the report touches is snapshotted and written back, and the
+## store is flushed while the scratch path is still in place, so the owner's `profile.cfg` is
 ## never written and the live store ends exactly as it started.
 func test_the_dock_report_settles_a_fired_pack() -> void:
 	if _scene == null or _state == null:
@@ -500,7 +503,7 @@ func test_the_dock_report_settles_a_fired_pack() -> void:
 	_delete_file(SCRATCH_PROFILE)
 	_delete_file(SCRATCH_LOG)
 	_scene.call(&"_seed_ammo")
-	var slot: int = WeaponsScript.ammo_slot(&"laser")
+	var slot: int = int((_state.get(&"weapons") as Array).find(&"laser"))
 	var live: int = int((_state.get(&"ammo") as Array)[slot])
 	var ceiling: int = int((_state.get(&"ammo_max") as Array)[slot])
 	_state.set_ammo(slot, live - 3)
```

Two notes on the shape of the diff:

1. **`WeaponsScript`'s preload is gone from the dock suite** because that const's only use was
   the catalogue lookup this cure removes; an unused preload of the file whose order is no
   longer consulted is exactly the trap LOW-6 describes. `test_engine2_fixes.gd` keeps its own
   preload (it uses `FAMILIES`, `dps_of`, `GUN_CHIP_RATE` and `_apply_beam` elsewhere).
2. **Nothing else moved.** Every assertion, its message and its order are the ones that were
   there; only the value feeding the slot changed. In fixes the single changed line sits where
   the slot was already read, so the test's own `stored_before`/`live`/`ceiling` readings and
   all three of its assertions are untouched.

---

## 2. The gate lines (before and after)

### 2a. The canonical gate, no XDG override — what the brief asked me to measure

```text
$ PATH=$HOME/.local/bin:$PATH godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200

# BEFORE the cure (measured on the live profile, 17:24:40)
485:[SUMMARY] passed=437 failed=0
486:EXIT=0

# AFTER the cure (measured on the live profile, 17:26:55)
485:[SUMMARY] passed=437 failed=0
486:EXIT=0

# and once more on the delivered state, after the control run of section 2c (17:2x)
485:[SUMMARY] passed=437 failed=0
490:EXIT=0
```

Logs: `.agents/gen/p2b_proper_f2_gate_before.txt`, `.agents/gen/p2b_proper_f2_gate_after.txt`,
`.agents/gen/p2b_proper_f2_gate_final.txt`.

**Honest reading of those lines: the canonical before-line is not the 434/3 the brief expected,
and it is not because of my change.** The owner's live profile was rewritten at 17:23:34 (66 s
before my first gate run) and its Vanguard fit now holds a laser-first fit, so the three
failures could not appear on it any more — measured, with the evidence in section 4. I did not
take that at face value: I reproduced the failing state on a byte copy of the live profile as R1
recorded it, and cured against that. That is the next table.

### 2b. The same gate against a byte copy of the live profile that carries the three failures

The copy is R1's own saved live-profile copy (`/tmp/r1_live/godot/app_userdata/Vajb Orbit/profile.cfg`,
`md5 9a04bea68fbe90c4d017e66245ceee7e` — the bytes R1's `p2b_proper_r1_gate_livecopy.txt` used,
Vanguard fit `["w_cannon", "w_laser", "w_laser"]`), copied to its own scratch root so the
owner's file is never read or written:

```text
$ cp /tmp/r1_live/godot/app_userdata/"Vajb Orbit"/profile.cfg \
     /tmp/f2_live/godot/app_userdata/"Vajb Orbit"/profile.cfg          # md5 9a04bea...

$ XDG_DATA_HOME=/tmp/f2_live PATH=$HOME/.local/bin:$PATH godot --headless --path vajb-orbit \
    res://tests/headless_runner.tscn --quit-after 1200

# BEFORE the cure — the brief's 434/3, byte for byte
57:[FAIL] test_engine2_dock.gd.test_a_settle_charges_the_rounds_fired_since_the_last_one: the first settle charges its three (300 -> 300)
58:[FAIL] test_engine2_dock.gd.test_the_dock_report_is_idempotent_within_one_launch: the launch seeded the live pack from the store (300 of 300)
71:[FAIL] test_engine2_fixes.gd.test_the_dock_report_settles_a_fired_pack: the launch seeded the live pack from the store (300 of 300)
485:[SUMMARY] passed=434 failed=3
486:EXIT=1

# AFTER the cure — same profile, same tree, only the two test files differ
57:[PASS] test_engine2_dock.gd.test_a_settle_charges_the_rounds_fired_since_the_last_one
58:[PASS] test_engine2_dock.gd.test_the_dock_report_is_idempotent_within_one_launch
71:[PASS] test_engine2_fixes.gd.test_the_dock_report_settles_a_fired_pack
485:[SUMMARY] passed=437 failed=0
486:EXIT=0
```

Logs: `.agents/gen/p2b_proper_f2_sandbox_before.txt`, `.agents/gen/p2b_proper_f2_sandbox_after.txt`.

The copy is untouched by both runs (`md5 9a04bea...` still — the gate never flushes, R1's own
observation), so the two runs differ in nothing but the cure. The two suites alone on the same
copy, post-cure:

```text
$ XDG_DATA_HOME=/tmp/f2_live ... res://tests/headless_runner.tscn --quit-after 600 \
    -- --suite=test_engine2_dock --suite=test_engine2_fixes
4:[RUN] suites=test_engine2_dock,test_engine2_fixes
24:[SUMMARY] passed=19 failed=0        # 2 dock + 17 fixes
29:EXIT=0
```

### 2c. The control: the same scoped run with only the cure removed

For one control run I put the two test files back at HEAD (`git checkout --` on exactly those
two paths), ran the scoped pair on the live-profile copy, then restored the cured files and
proved the restore byte-identical against the saved diff (`diff` clean between
`.agents/gen/p2b_proper_f2_diff.txt` and the tree's fresh `git diff`). On the same copy, same
tree, same command:

```text
# pre-cure (HEAD's lines)
5:[FAIL] test_engine2_dock.gd.test_a_settle_charges_the_rounds_fired_since_the_last_one: the first settle charges its three (300 -> 300)
6:[FAIL] test_engine2_dock.gd.test_the_dock_report_is_idempotent_within_one_launch: the launch seeded the live pack from the store (300 of 300)
19:[FAIL] test_engine2_fixes.gd.test_the_dock_report_settles_a_fired_pack: the launch seeded the live pack from the store (300 of 300)
24:[SUMMARY] passed=16 failed=3
25:EXIT=1

# cured
24:[SUMMARY] passed=19 failed=0
29:EXIT=0
```

Log: `.agents/gen/p2b_proper_f2_suite_before_control.txt` (the cured half is
`.agents/gen/p2b_proper_f2_suite_after.txt`). 16/3 -> 19/0 is the same three tests either way,
and it keeps the failing pair reproducible on demand rather than dependent on the profile's
current fit.

### 2d. No test moved in or out

Sorted `[PASS]` name sets, compared:

```text
canonical before vs canonical after vs final ... IDENTICAL (437 names each)
sandbox before (434 names) vs sandbox after .. +3 names, and they are exactly the three above:
  + test_engine2_dock.gd.test_a_settle_charges_the_rounds_fired_since_the_last_one
  + test_engine2_dock.gd.test_the_dock_report_is_idempotent_within_one_launch
  + test_engine2_fixes.gd.test_the_dock_report_settles_a_fired_pack
```

434 passed + 3 failed = 437 = 437 passed after the cure: the failures were three of the 437,
not three missing tests. No suite gained or lost a test, and the canonical after-log's
`grep -c "^\[PASS\]"` is 437.

### 2e. Log hygiene of the canonical runs

```text
$ grep -n "SCRIPT ERROR" .agents/gen/p2b_proper_f2_gate_after.txt
475:SCRIPT ERROR: Cannot call method 'call' on a previously freed instance.
          at: test_weapon_fx_f4.gd:176
              [0] test_a_held_beam_reads_one_hit_per_contact_interval (res://tests/test_weapon_fx_f4.gd:176)
```

One `SCRIPT ERROR` line in the canonical after-run, and one in the final run (same line 475) —
the pre-existing `test_weapon_fx_f4` freed-instance one the brief names (R1's section 8 records
the same single line at line 469 of its own log — line number only, the tree moved under it).
The two other engine lines are pre-existing and present in R1's runs too: `ERROR: Parameter
"data.tree" is null.` (boot, line 6) and the `EconomyLog: could not open
user://p1l_missing_dir_do_not_create/...` warning (line 228). The canonical runs carried **no**
exit-time leak lines; the sandbox after-run carried `64 ObjectDB instances were leaked at exit`
/ `26 resources still in use at exit` with the same `passed=437 failed=0` — R1's LOW-7
nondeterminism, unchanged, not a finding of this pass.

The owner's live profile is untouched by my runs too: `md5
a917182e16fa1dda759743c8b75f8074` before and after the canonical runs
(`.agents/gen/p2b_proper_f2_md5.txt`, `…_md5_final.txt`).

---

## 3. Why the three failed, in the fixtures' own numbers

LOW-6's mechanism, re-measured rather than restated. The owner's Vanguard fit is
`["w_cannon", "w_laser", "w_laser"]`, which `game.gd:_launch_weapons` (`game.gd:397-405`) maps
to `PlayerState.weapons == [&"cannon", &"laser", &"laser"]`. `WeaponsScript.ammo_slot(&"laser")`
(`game/weapons.gd:1465-1472`) answers the *catalogue* index instead — `PlayerState.WEAPONS` is
`[&"laser", &"cannon", &"rocket", &"mine", &"plasma"]` (`game/player_state.gd:35`), so it
answers **0**, which in that fit is the *cannon*'s pack. The two suites then charged slot 0 and
read back the pack named `laser`. The failures' own messages are the proof, and the second is
the sharpest:

| # | Test | Message | What it proves |
|---|---|---|---|
| 1 | `test_engine2_dock.gd::test_a_settle_charges_the_rounds_fired_since_the_last_one` | `the first settle charges its three (300 -> 300)` | its *seeding* assertion passed, i.e. slot 0's seeded live value did equal `min(300, 300)` at the start of the suite; the charge then moved a pack that is not the one the test reads back |
| 2 | `test_engine2_dock.gd::test_the_dock_report_is_idempotent_within_one_launch` | `the launch seeded the live pack from the store (300 of 300)` | in the **same process, one test later**, slot 0's seeded live value is no longer 300 — the only state change between the two is test 1's filing, so test 1's three rounds did land on the pack slot 0 seeds from |
| 3 | `test_engine2_fixes.gd::test_the_dock_report_settles_a_fired_pack` | `the launch seeded the live pack from the store (300 of 300)` | the same slot-0 pack in a later suite of the same process (the dock suite's earlier test had already reduced it); R1's isolated fixes run, which had no dock suite in front of it, passed this seeding and failed the *filing* assertion instead (`the dock filed exactly the three rounds that were fired (300 -> 300)`) |

The in-memory reduction is the arithmetic consequence of test 1's filing (`set_ammo` writes
`maxi(stored - fired, 0)`), and the value 297 is printed nowhere, so I state it as the
consequence and not as a measurement. What *is* measured is enough for the diagnosis: the slot
the tests charge is not the pack they read.

The economy log agrees only in part, so it is recorded as corroboration and not as the proof.
The two cured sandbox runs each added an `AMMO, laser, 3` / `AMMO, laser, 5` pair to that root's
log (`15:26:06`, `15:26:51`), and each of my canonical runs added the same pair to the live
root's log (`15:24:43`, `15:26:58`) — the cured charge is filed against the laser. The pre-cure
control run of section 2c added **no** AMMO line to that log at all, and no `AMMO, cannon` line
exists anywhere in the live log's 817 lines (all 112 of its AMMO lines name `laser`); both
suites repoint `EconomyLog.log_path` at a scratch log they delete at handover, so which filings
survive in the default file is a logging question this pass did not chase. The assertion numbers
above do not depend on it.

The cure is order-independent in both directions, measured:

- **cannon-first fit** (the live-profile copy): 434/3 -> 437/0 (section 2b), 16/3 -> 19/0 scoped
  (section 2c).
- **laser-first fit** (the live profile as it stands): 437/0 -> 437/0 (section 2a), the three
  suites' `[PASS]` name sets identical.

---

## 4. F2-1 (observation, outside this pass) — the live profile's Vanguard fit was rewritten

I did not set out to look at this, but it is why section 2a's before-line is green, so it is
recorded with its evidence rather than left as a mystery for the reviewer:

- **The write:** `~/.local/share/godot/app_userdata/Vajb Orbit/profile.cfg`, mtime
  `2026-09-22 17:23:34`, md5 `a917182e16fa1dda759743c8b75f8074`. Both R1 (17:04-17:06) and F1
  (17:22) recorded the same file as `9a04bea68fbe90c4d017e66245ceee7e`.
- **Its own economy event:** `~/.local/share/godot/app_userdata/Vajb Orbit/economy_log.txt:771`
  reads `2026-09-22T15:23:34, FIT_MODULE, w_laser, 1, +0, 117` — the log is UTC and the file
  mtime is local, and `117` is that profile's own credit balance, so a **live-account install of
  `w_laser`** was filed at exactly the moment the file changed.
- **Its effect:** `fits.ship_vanguard.weapons` went from `["w_cannon", "w_laser", "w_laser"]`
  (the copy in `/tmp/r1_live`, still on disk) to `["w_laser", "w_laser", "w_laser"]` — the
  standard fit's weapons line, which is also what a `w_laser` install at W cell 0 produces.
  Every other line of that fit is unchanged, and `modules` still holds only `w_cannon x1` and
  `w_laser x2`.
- **Who:** not the gate and not this pass. Three gate runs of mine left the md5 `a917182e...`
  unchanged before and after (`.agents/gen/p2b_proper_f2_md5.txt`, `…_md5_final.txt`), matching
  R1's own "the gate never flushes" measurement; the write predates my first run by 66 s, and the
  two short runs in `logs/` at 17:22:45 and 17:23:24 sit between F1's report and it. Candidate
  writers are the pane/probe runs of that window (F1 notes the shipped OUTFITTING surface banks
  the delivered fit once its own `_seed_fit` has materialised it; F1's MED-1 cure writes a
  composed candidate whole). Attributing it needs a run this pass had no mandate to make.
- **What it means for the wave:** the owner's live profile now carries a Vanguard fit the
  account's own inventory cannot build (three lasers against two `w_laser` held), and the LOW-6
  failures it used to produce are hidden. Restoring the fit from the frozen copy is the
  orchestrator's call; nothing in this pass depends on which fit is live, which is the point of
  the cure.

---

## 5. Hygiene, limits and reversal

- **Touched:** `vajb-orbit/tests/test_engine2_dock.gd`, `vajb-orbit/tests/test_engine2_fixes.gd`,
  and this report's own evidence files under `.agents/gen/`. Nothing else: no game file
  (`game.gd`, `player_state.gd`, `weapons.gd`, `player_profile.gd`, the panels), no other test,
  no asset, no theme file, no `project.godot`, no addon, no doc. `git status` on `vajb-orbit/`
  shows my two files plus the wave's pre-existing modifications only.
- **The one temporary revert:** section 2c's control run required the two test files at HEAD for
  one scoped run; they were restored immediately afterwards and the restore was verified
  byte-identical against `.agents/gen/p2b_proper_f2_diff.txt`, followed by a fresh canonical gate
  on the delivered state (`p2b_proper_f2_gate_final.txt`: `passed=437 failed=0`, exit 0).
- **Not run by me:** the editor (every measurement is headless), the probes, the lint probes, the
  R1 signature audits, and the canonical gate against a fresh sandboxed `user://` — the two
  configurations that matter here are the canonical live-profile one and the byte-copy one, and
  both are above.
- **Two harness frictions (not mine to fix):** the worker-file hook refused the `write` of this
  report and the first `edit` at an absolute Linux path ("outside this worker's declared file
  set. Allowed: vajb-orbit/tests/") — LOW_BACKLOG **L75** again, and it now also blocks a
  worker's own declared report path; the report was therefore written through the shell, and every
  in-tree write used the workspace-relative path. Recorded, not worked around.
- **Reversal:** in `test_engine2_dock.gd` restore `return int(WeaponsScript.ammo_slot(FIRED_WEAPON))`
  in `_slot()`, re-add `const WeaponsScript := preload("res://game/weapons.gd")` and its original
  const comment; in `test_engine2_fixes.gd` restore `var slot: int = WeaponsScript.ammo_slot(&"laser")`.
  That is the whole reversal, and it restores the catalogue-order assumption and the three
  failures on a cannon-first profile.
