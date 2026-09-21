# Engine slice 2 — W9 closing fixer report (2026-09-21)

Closer: **W9**, the pass the wave closes on. Authority: **R1** of
`.agents/gen/slice2_w8_report.md` §2 (read in full, with §1 and §8 for its context), the wave's
finding list `.agents/gen/slice2_review_report.md`, the fixer pass `.agents/gen/slice2_w7_report.md`
(the F2 fix that turned R1 on), `AGENTS.md`, and the shipped code. One finding was assigned —
**R1** (MED, one line) — and it is fixed, measured, and now guarded by a test.

**Verdict: R1 is closed.** The reviewer's own probe, re-run on the fixed tree, reads
**`ok=133 failed=0`** with its dock section **D 11/0** and the double call now measured
**297 → 297** where it measured **297 → 294**. The universal gate reads **`passed=219 failed=0`**,
exit 0. The two new tests are proven to detect R1: with the one line removed they fail with the
reviewer's exact numbers (`297 → 294`), and with it present they pass.

## 1. The cure, and why this one

**One line added inside `_file_ammo_report`, `vajb-orbit/game/game.gd:1107`:**

```gdscript
		var stored := int(profile.call(&"ammo_of", weapon_id))
		profile.call(&"set_ammo", weapon_id, maxi(stored - fired, 0))
		_ammo_seed[weapon_id] = live          # <- the added line (1107)
		EconomyLogScript.append(
			EVENT_AMMO, weapon_id, fired, 0, int(profile.call(&"credits"))
		)
```

Nothing else in the file changed: `git diff` of `game.gd` carries the whole uncommitted slice-2
addition (the last commit is the post-slice-0 snapshot), so the delta of *this* pass is proven the
other way — by the negative control in §3, where removing exactly that line reproduces R1's numbers
and restoring it removes them.

**Chosen over the `_docking` flag, because the blast radius is smaller.** The re-seed touches only
the function R1 names and only the ammo half of the settle:

- The flag would change `_request_dock`'s behaviour for **every** caller — the dock prompt
  (`game.gd:397`) and the warp arrival (`game.gd:489`) — and would need a reset path for a route
  that is requested but never taken (a cancelled fade, a probe with no listener), which is state
  the flight scene does not have today.
- The re-seed also closes the re-entry that exists **without** the route: any second caller of the
  filing (a probe, a future "safe undock", a retry after a failed write) is now idempotent by
  construction, not by a guard that only the routing path respects. The vitals half is already
  absolute (`set_vitals`), so it needed no lock either.

**What it means semantically:** after each pack's write, the slot's remembered seed becomes the live
figure, so `fired` always means "rounds fired since the last settle" rather than "rounds fired since
launch". A retried settle therefore finds nothing left to charge, and rounds fired *between* two
settles are still charged exactly once — both halves are asserted in §4. The store keeps its own
value; the `maxi(stored - fired, 0)` formula and the `EVENT_AMMO` log line are untouched, so the
filing's accounting is unchanged for the single-call case (still `300 → 297` for three rounds).

## 2. Before / after measurement of the double call

Measured with the reviewer's **own** probe, live `game.tscn`, the shipped `_file_ammo_report`; three
rounds fired on the live state before the first report, and **no further firing** before the second.

| | Run | Log line | Reading |
|---|---|---|---|
| **Before** | W8's archived probe, **unmodified**, run in place (`md5 1979983fb50030612a719c213883c205`) → `.agents/gen/slice2_w9_probe_before.txt` | `[measure] fired 3: stored laser 300 -> 297, live was 300, cannon still 300` then `[measure] REVIEW/finding: a second dock report in one launch files the same delta again: 297 -> 294` | **300 → 297 → 294** (R1 reproduced) |
| **After** | the same probe, one check flipped (§5.1), on the fixed tree → `.agents/gen/slice2_w9_probe_after.txt` | `[measure] fired 3: stored laser 300 -> 297, live was 300, cannon still 300` then `[measure] R1 closed by W9: a second dock report in one launch files nothing more: 297 -> 297` | **300 → 297 → 297** |

That is exactly the closure condition W8's §2 states: two consecutive `_file_ammo_report` calls on
one launch leave the pack at `stored − fired`, not `stored − twice fired`. The pack that was not
fired still reads `300 → 300` in both runs, so the untouched-pack half of the seam is unmoved.

## 3. The gates

| Gate | Command (bounded, stdout to a log) | Result |
|---|---|---|
| **The reviewer's probe, fixed tree** | `..._console.exe --headless --path <proj> --script res://tools/_probe_w8_slice2.gd --quit-after 4000` → `.agents/gen/slice2_w9_probe_after.txt` | **`[SUMMARY] ok=133 failed=0`, exit 0.** Per section: `A 16 · B 7 · C 12 · **D 11** · E 14 · F 17 · G 9 · H 46` (+1 in the preamble) = 133, **zero `[FAIL]`**, zero `SCRIPT ERROR`. D is 11/0 — the same count W8 read, with its R1 record flipped to a passing idempotence check |
| **The same probe, before** | identical command, in place from `.agents/gen/` → `.agents/gen/slice2_w9_probe_before.txt` | **`ok=133 failed=0`, exit 0** (its R1 check asserted the buggy behaviour, so it was green then too) — this is §2's "before" half |
| **Universal test gate** | `..._console.exe --headless --path <proj> res://tests/headless_runner.tscn --quit-after 1200` → `.agents/gen/slice2_w9_testgate.txt` | **`[SUMMARY] passed=219 failed=0`, exit 0**, zero `[FAIL]`, zero `SCRIPT ERROR`, zero RID-leak lines. Per suite: `engine2_cleaving 9 · engine2_damage 20 · **engine2_dock 2** · engine2_fixes 17 · engine2_hud 19 · engine2_loot 13 · engine2_npc 28 · engine2_pools 16 · engine2_weapons 29 · engine2_wiring 13 · p1_catalogues 11 · p1_clock_log 4 · p1_market 13 · p1_pricing 5 · p1_profile 9 · p1_refinery 6 · p1_repairs 5` = **219** (W8's measured 217 + this pass's 2) |
| **Negative control (scoped)** | `..._console.exe --headless --path <proj> res://tests/headless_runner.tscn --quit-after 1200 -- --suite=test_engine2_dock` with line 1107 **removed** → `.agents/gen/slice2_w9_dock_suite_unfixed.txt` | **`passed=0 failed=2`, exit 1.** `[FAIL] …test_a_settle_charges_the_rounds_fired_since_the_last_one: the second charges the two that followed, not the three again (297 -> 292)` and `[FAIL] …test_the_dock_report_is_idempotent_within_one_launch: a second report in the same launch charges nothing more (297 -> 294)` |
| **The suite alone, fixed tree** | identical scoped command → `.agents/gen/slice2_w9_dock_suite.txt` | **`passed=2 failed=0`, exit 0** |

The negative control is the part that matters: it proves the new tests fail on the bug for R1's own
reason, so the green gate is evidence and not decoration.

## 4. The test added

**`vajb-orbit/tests/test_engine2_dock.gd`** (new, suite `engine2_dock`, **2 tests**) — the runner
discovers every `res://tests/test_*.gd`, so no registry needed a change.

| Test | What it asserts |
|---|---|
| `test_the_dock_report_is_idempotent_within_one_launch` | On a live `game.tscn` and the shipped `PlayerProfile`: the launch seeds the live pack from the store (`live == min(stored, ceiling)`), three rounds are fired, and **three** consecutive `_file_ammo_report` calls leave the store at `stored − 3` — `maxi(stored − 3, 0)` once, then identical twice more. Three calls, not two, because a re-seed that only ever fired once would still pass a two-call probe. The unfired control pack must not move |
| `test_a_settle_charges_the_rounds_fired_since_the_last_one` | The other half of idempotence: three rounds, settle, two more rounds, settle again — the store pays `stored − 3` then `stored − 5`. A cure that froze the seed would fail this half; a cure that re-applied the delta would fail the first test |

Hygiene, the same discipline `test_engine2_fixes.gd` records for this seam: the store is the shipped
autoload, its `save_path` is repointed at `user://test_engine2_dock.cfg` **before** anything can
write, `EconomyLog.log_path` at `user://test_engine2_dock_log.txt`, and the store is handed back in
memory with a `flush()` while the scratch path is still in place, then the files are deleted. Measured
after the pass: the owner's `user://profile.cfg` is **723 B / `0c52310bd372a629218e6d81d6b4986f`**,
byte-identical to the value W8 recorded, and `user://` holds no `test_engine2_dock*` file.

## 5. Deviations, and what was deliberately left alone

1. **The probe copy, and its one flipped check.** The dispatch's route (write it back with the
   `write` tool) would mean re-emitting 1172 lines by hand; a transcription slip there would make the
   run *less* provable, so the archived source was copied **byte-for-byte** (`cp`, md5 verified as
   `1979983f…` before and after the copy — W8 disclosed the same `cp` step) into
   `res://tools/_probe_w8_slice2.gd`, and **one** check inside it was changed with the `edit` tool:

   - before: `_check("REVIEW/finding R1 (recorded, NOT fixed): a repeat dock report in one launch re-applies the fired delta", filed_twice == maxi(filed - 3, 0), …)`
   - after: `_check("R1 (W9 fix): a repeat dock report in one launch does not re-apply the fired delta", filed_twice == filed, …)`

   Everything else — all 132 other checks, all eight sections, the header, the fixture wiring — is
   byte-identical to W8's source. The exact bytes that were run are archived at
   `.agents/gen/slice2_w9_probe_source.gd` (`md5 e68fc26dae9d56509c603a1869cecc28`), one check
   different from W8's archive by construction. So §3's "reviewer's probe" run is *his* probe with
   *his* R1 check re-phrased to assert the closure he specified, not a new probe.
2. **Two tests, not one.** The dispatch asked for "one test for the idempotence". R1 has two failure
   modes to guard — re-applying the delta (the bug) and freezing the seed (the naive cure) — and each
   test catches one, so the gate reads **219**, not 218. Both are listed in §4; the extra one is a
   strict addition, touching no shipped file.
3. **The test file's name.** The dispatch named `res://tests/test_engine2_*.gd`; read as the
   engine2 family wildcard, filled as **`test_engine2_dock.gd`** (suite `engine2_dock`), which is the
   family's own naming style (`weapons`, `npc`, `damage`, `hud`, `loot`, `wiring`, `fixes`).
4. **Shell touches, all inside the pass's own set or report space.** `cp` into
   `res://tools/_probe_w8_slice2.gd`, `cp` of that file out to `.agents/gen/slice2_w9_probe_source.gd`,
   and `rm` of the probe **and its `.uid`** from `tools/`. No probe content was authored through the
   shell (the one changed check went through `edit`). `tools/` ends holding exactly
   `build_theme.gd`, `derive_icon_tints.gd`, their `.uid` sidecars and `desktop.ini` — no probe, no
   stray `.uid`, as the dispatch requires.
5. **Pre-existing noise in W8's probe, unchanged by this pass.** Both runs emit **7** `String
   formatting error` lines from the probe's own `print`/`_check` messages (e.g. `"… | missing=%s"` with
   no argument). They are W8's strings, identical in both logs, `[PASS]`-only, and harmless; they were
   not "fixed" because editing more of his probe would weaken the before/after comparison.
6. **`game.gd:1085-1089`'s stale comment is still stale.** The `_file_ammo_report` doc block still
   says "`PlayerProfile` publishes no writer for a pack today … until then the seam is inert", which
   W7's F2 fix made false and W7 reported (§F2's closing note). It is not R1, it is not a behaviour,
   and this dispatch's rule is comments unchanged — so it is left as found, still owned by whichever
   pass owns that seam next.
7. **`docs/CONTRACTS.md` still records R1 as open in three places** — the §4.3 row (line 332), §8.2's
   finding + cure (lines 621-631) and the wave-close paragraph (line 759). `docs/` is outside this
   pass's file set (`game/game.gd`, `tests/`, `tools/` only), so the reviewer/orchestrator's doc pass
   needs to flip those three rows to closed with §2's numbers. Nothing else about R1 is left open.
8. **Nothing outside the file set moved.** `project.godot`, `ui/theme/**`, `assets/**` and
   `addons/**` were not read for editing and not written; the same editor session that was open
   (`vajb-orbit@f13f58fae5e1d177`, play state stopped) served the runs. The owner's profile is
   byte-identical (§4), and the probe's own last check re-proves that across its run.

## 6. Files and evidence of this pass

| File | Before → after | Size / md5 after |
|---|---|---|
| `vajb-orbit/game/game.gd` | 1451 → **1452** lines | 55 904 B, `4cacbf1ca7ae049ec6fbcfef7e665554` (one added line: 1107) |
| `vajb-orbit/tests/test_engine2_dock.gd` | — → **new**, 233 lines | 9 342 B, `f8d8f33d0a73e1c455f490f0bade18d9` (2 tests) |
| `res://tools/_probe_w8_slice2.gd` | written, run, **deleted** (+ its `.uid`) | ran as 45 202 B, `e68fc26dae9d56509c603a1869cecc28` |

| Evidence | Size / md5 |
|---|---|
| `.agents/gen/slice2_w9_probe_before.txt` | 19 239 B, `dff491157efe032d7bdfc5004930345b` |
| `.agents/gen/slice2_w9_probe_after.txt` | 17 846 B, `8901e78fa946c4bc10f1886dc458890b` |
| `.agents/gen/slice2_w9_testgate.txt` | 19 824 B, `464f409cb82331a1b6bf77daaadd7ccf` |
| `.agents/gen/slice2_w9_dock_suite.txt` (2/0) | 2 138 B, `e6e0fb69564bd816d8bc5428899353db` |
| `.agents/gen/slice2_w9_dock_suite_unfixed.txt` (0/2, exit 1) | 2 284 B, `b3fe4cf94ad89ff237282794e64903fa` |
| `.agents/gen/slice2_w9_probe_source.gd` (the exact probe bytes run) | 45 202 B, `e68fc26dae9d56509c603a1869cecc28` |

## 7. Closing statement

R1's own closure condition is met and measured from both sides: the double call files
`stored − fired`, not `stored − twice fired` (300 → 297 → **297**), on the shipped
`_file_ammo_report` against a live `game.tscn` and the shipped `PlayerProfile`; the reviewer's probe
is green at **133/0** with section D green; the universal gate is green at **219/0** with this pass's
two tests the only additions; and those two tests are red (`0/2`, `297 → 294`) on the unfixed tree,
so the green is causal. The wave's remaining items are the ones W8's §8 lists — none of them R1, and
none of them created or worsened here. **The engine slice-2 wave is clean.**
