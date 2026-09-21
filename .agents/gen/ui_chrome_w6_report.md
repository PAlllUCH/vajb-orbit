# W6 report — one-pass fixer, UI-chrome wave (code lane)

Fixer: **W6**. Declared file set (`VAJB_WORKER_FILES`): `docs/CONTRACTS.md`. Host: Linux
(`~/VajbOrbit`), Godot 4.7.2-stable at `~/.local/bin/godot`, 2026-09-21.
Inputs read in full before editing: `.agents/gen/ui_chrome_w5_report.md` (the review, §5.2,
§6, §8 MED-1/MED-2), `.agents/gen/ui_chrome_wave_task.md` (the wave law), and the current
text of `docs/CONTRACTS.md` §9.

**Two MED findings in, two MED findings closed. No code, asset, theme, scene, test or other
doc file was touched.** `git diff --stat` for my file: **17 insertions, 5 deletions** (5 of
those deletions are W4's pre-existing, still-unstaged 219 edit being superseded — see §2).

---

## 1. Verdict

| Finding | Status | Evidence |
|---|---|---|
| **MED-1** — §9's expected count stale by 7 | **closed** | §9 now reads `passed=226` with the `219 pre-wave + 7 from tests/test_ui_slot_layout.gd` composition and the 2026-09-21 measurement date; the 217 record no longer claims to be the expectation; the v1.1 changelog at 775 is untouched |
| **MED-2** — the false "headless cannot observe a warning" limit | **closed in `docs/CONTRACTS.md`** | §9's trap block gains the `--headless --debug` item (final lines 681-689) naming `vajb-orbit/tests/probe_w5_lint.tscn` and the `weapons.gd` positive control |

One item of W5's MED-2 fix text is **outside my file set and is left open**: the false-limit
sentence inside `.agents/gen/ui_chrome_w3_report.md` §1 is not a `docs/CONTRACTS.md` edit, and
this pass is barred from other files. See §7.

---

## 2. MED-1 — the three edits, verbatim

Line numbers are the **pre-edit** numbers W5 reported (639/647/657), so this report can be
diffed against the review. W5's map was exact; W4's own residual claim (655/763) was indeed
off by two, and the changelog line W5 placed at 765 is at **775** in the current tree (the
W4 hunk above it had already shifted it by ten).

**Edit A — `docs/CONTRACTS.md:639` (the expectation), W4's 219 → the measured 226:**

```diff
-Expected: `[SUMMARY] passed=219 failed=0` (re-measured on this host 2026-09-21),
+Expected: `[SUMMARY] passed=226 failed=0` (re-measured on this host 2026-09-21),
 exit 0, no `SCRIPT ERROR`. A wave is
```

**Edit B — `docs/CONTRACTS.md:646-648` (the arithmetic that produces it):**

```diff
-pass added `tests/test_engine2_fixes.gd` (**17**) and the slice-2 close added
-`tests/test_engine2_dock.gd` (**2**), so the total is **219** and the count
+pass added `tests/test_engine2_fixes.gd` (**17**) and the slice-2 close added
+`tests/test_engine2_dock.gd` (**2**), and the UI-chrome wave added
+`tests/test_ui_slot_layout.gd` (**7**), so the total is **226** (the 219 measured
+before that wave, plus this suite's 7) and the count
 to read is the measured one with zero failures, never a stale total. Discovery is
```

(The first two lines of that hunk are W4's, unchanged by me; only the `so the total is`
sentence and the two added lines are mine. The composition is stated as the review measured
it: the 219 that existed before this wave, plus the 7 the wave added.)

**Edit C — `docs/CONTRACTS.md:657` (the 217 record's claim to be live):**

```diff
-2026-09-21 (W8 re-review, the number this file now expects): `passed=217 failed=0`,
+2026-09-21 (W8 re-review, before the slot suite): `passed=217 failed=0`,
```

The per-suite list, `exit 0, no SCRIPT ERROR, no RID-leak line` and every other digit of the
W8 record are byte-identical to what they were. **The v1.1 changelog at line 775 is
untouched**, as instructed; grep A in §5 shows it still contains `measured 217`.

### 2.1 The one interpretation call in MED-1, and why

The brief's phrase "drop the stale 217 sentence" admits two readings, and I took the one that
W5's own fix text prescribes:

- **W5 §5.2/§8 MED-1 fix**: *"line 657: drop 'the number this file now expects' (that
  parenthetical is what makes a *historical* 217 record read as the live expectation)"*.
- **The brief's own contrast**: the changelog entry is left alone *"since it records history
  rather than the expectation"* — i.e. history stays, the expectation claim goes.

So the edit removes the **claim** and keeps the **measurement**. Deleting the whole W8
sentence instead would have (a) destroyed the only in-body record of how 217 was composed,
which the surviving changelog line at 775 explicitly cites ("`engine2_fixes` (17) broken
out"), leaving that citation dangling, and (b) contradicted the brief's own history/expectation
rule. If the orchestrator wanted the W8 measurement paragraph deleted outright, that is a
one-line follow-up: delete lines 658-664, and line 775's citation needs rewriting in the same
pass. **I did not do it, and this is the only place my edit could be read as narrower than the
brief.**

---

## 3. MED-2 — the trap-block item, verbatim

Appended to §9's trap block after the `Input` harness limit, final lines 681-689:

```text
a running game through the editor's input injection. **Fifth harness limit, measured in the
UI-chrome wave (2026-09-21):** a headless run *can* observe warnings after all, which the
wave's D5 pass assumed it could not — `--headless --debug` attaches the local stdout
debugger and prints every `WARNING: ...` attributed as
`at: GDScript::reload (res://file:line)`, so a per-file lint ledger is buildable by loading
one file at a time between printed markers (`vajb-orbit/tests/probe_w5_lint.tscn` is the
reference implementation: zero warnings in all nine D5 files, 19 in the `weapons.gd`
positive control). Never record "verified by reading the source" while this one-command
ledger exists.
```

Everything the brief required is in it: `--headless --debug` attaches the **local stdout
debugger**; warnings print **attributed to `res://file:line`**; a **per-file ledger** is
buildable by loading **one file at a time between printed markers**; the reference proof is
`tests/probe_w5_lint.tscn` with the **`weapons.gd` positive control** (19 warnings) stated as
the control's number.

The referenced files exist on this host, checked before the write landed:
`vajb-orbit/tests/probe_w5_lint.tscn` (199 bytes, mtime Sep 21 14:40), `probe_w5_lint.gd`
(2628 bytes) and the raw ledger `.agents/gen/ui_chrome_w5_lint_ledger.log`.

### 3.1 Why the item is labelled `Fifth harness limit`, not `Fourth`

The brief calls it "the fourth item". §9's trap block **already carries four ordinals**:

| ordinal label | final line | subject |
|---|---|---|
| `**Known trap:**` | 664 | `--check-only --script` cannot resolve autoload singletons |
| `**Second form of the same trap …**` | 666 | `preload` vs `load()` for an autoload-touching scene |
| `**Third form, measured in the slice-2 re-review:**` | 671 | `const preload("res://game/game.gd")` poisons the compile cache |
| `**Fourth harness limit, measured the same pass:**` | 676 | a `--script` run cannot drive `Input`'s action state |

Adding the new item as "the fourth" would collide with line 676; the honest next ordinal is
the fifth, and the block stays monotonic and chronological (appended, not inserted). W5's
"add a fourth item" counts the three `form` items and appears to have missed that the
`Fourth harness limit` paragraph is itself a fourth entry; the review's own §4.3 quotes the
block without numbering it. The alternative (insert as "fourth" and relabel the `Input` limit
to "fifth") was rejected because it edits a historical record's label for a cosmetic ordinal,
which the rest of this brief explicitly forbids.

---

## 4. Verification — re-read of the edited lines

`docs/CONTRACTS.md:639-649` (edited regions A and B), read back from disk after the edits:

```text
639|Expected: `[SUMMARY] passed=226 failed=0` (re-measured on this host 2026-09-21),
640|exit 0, no `SCRIPT ERROR`. A wave is
...
645|pass added `tests/test_engine2_fixes.gd` (**17**) and the slice-2 close added
646|`tests/test_engine2_dock.gd` (**2**), and the UI-chrome wave added
647|`tests/test_ui_slot_layout.gd` (**7**), so the total is **226** (the 219 measured
648|before that wave, plus this suite's 7) and the count
649|to read is the measured one with zero failures, never a stale total. Discovery is
```

`docs/CONTRACTS.md:658-659` (edited region C):

```text
658|(`test_p1_profile.gd:204`, the save-version digit) stays fixed. **Measured again
659|2026-09-21 (W8 re-review, before the slot suite): `passed=217 failed=0`,
```

`docs/CONTRACTS.md:676-689` (new trap item, read back):

```text
676|appears). Reach the flight scene with `load()`, never `preload`. **Fourth harness limit,
677|measured the same pass:** a `--script` run cannot exercise an `Input` action's state —
...
681|a running game through the editor's input injection. **Fifth harness limit, measured in the
682|UI-chrome wave (2026-09-21):** a headless run *can* observe warnings after all, which the
683|wave's D5 pass assumed it could not — `--headless --debug` attaches the local stdout
684|debugger and prints every `WARNING: ...` attributed as
685|`at: GDScript::reload (res://file:line)`, so a per-file lint ledger is buildable by loading
686|one file at a time between printed markers (`vajb-orbit/tests/probe_w5_lint.tscn` is the
687|reference implementation: zero warnings in all nine D5 files, 19 in the `weapons.gd`
688|positive control). Never record "verified by reading the source" while this one-command
689|ledger exists.
```

(Final numbers below 659 differ from the pre-edit ones because Edit C re-wrapped two lines
into one; nothing else in the file moved.)

---

## 5. Verification — raw grep output, pasted as it came back

```sh
grep -n "217\|219\|226" docs/CONTRACTS.md
```

```text
639:Expected: `[SUMMARY] passed=226 failed=0` (re-measured on this host 2026-09-21),
648:`tests/test_ui_slot_layout.gd` (**7**), so the total is **226** (the 219 measured
659:2026-09-21 (W8 re-review, before the slot suite): `passed=217 failed=0`,
775:  write, or a `_docking` flag). **§9**: the expected total is the **measured 217** with
```

Reading: 639 and 648 are the live expectation and its composition; 659 is the labelled
historical W8 measurement; 775 is the v1.1 changelog, deliberately untouched.

```sh
grep -n "Expected\|the number this file now expects" docs/CONTRACTS.md
```

```text
639:Expected: `[SUMMARY] passed=226 failed=0` (re-measured on this host 2026-09-21),
```

The former phrase "the number this file now expects" now occurs **nowhere** in the file: one
`Expected:` line, and it says 226.

```sh
grep -n "Known trap\|Second form\|Third form\|Fourth harness\|Fifth harness\|probe_w5_lint" docs/CONTRACTS.md
```

```text
664:p1_refinery 6 · p1_repairs 5`. **Known trap:**
666:as a gate; use scene runs or `load()` probes. **Second form of the same trap
671:SceneTree is up. **Third form, measured in the slice-2 re-review:** the same trap hits a
676:appears). Reach the flight scene with `load()`, never `preload`. **Fourth harness limit,
681:a running game through the editor's input injection. **Fifth harness limit, measured in the
686:one file at a time between printed markers (`vajb-orbit/tests/probe_w5_lint.tscn` is the
```

```sh
git diff --stat docs/CONTRACTS.md
```

```text
 docs/CONTRACTS.md | 22 +++++++++++++++++-----
 1 file changed, 17 insertions(+), 5 deletions(-)
```

---

## 6. Independent confirmation of the number I wrote into the contract

The contract now asserts 226 in two places, so I re-measured it on this host rather than
inheriting W5's figure:

```sh
~/.local/bin/godot --headless --path vajb-orbit res://tests/headless_runner.tscn \
  --quit-after 1200 > .agents/gen/ui_chrome_w6_gate.log 2>&1
echo "exit=$?"                                   # exit=0
grep -n "^\[SUMMARY\]" .agents/gen/ui_chrome_w6_gate.log
```

```text
243:[SUMMARY] passed=226 failed=0
```

```sh
grep -c "^\[PASS\]" .agents/gen/ui_chrome_w6_gate.log                                      # 226
grep '^\[PASS\]' .agents/gen/ui_chrome_w6_gate.log | grep -v test_ui_slot_layout | wc -l   # 219
grep -c test_ui_slot_layout .agents/gen/ui_chrome_w6_gate.log                              # 7
grep -c "^\[FAIL\]" .agents/gen/ui_chrome_w6_gate.log                                      # 0
grep -c "SCRIPT ERROR" .agents/gen/ui_chrome_w6_gate.log                                   # 0
```

`226 = 219 + 7` reproduces exactly: 219 passes outside the UI-chrome suite, 7 inside it. The
log is kept raw at `.agents/gen/ui_chrome_w6_gate.log`.

---

## 7. Deviations, and what is left open

1. **Tooling deviation (not a file deviation): the worker-file hook denies absolute paths on
   this host.** My first `edit` call, with the documented absolute path
   `/home/kamil-paluszkiewicz/VajbOrbit/docs/CONTRACTS.md`, was **blocked**:

   ```text
   Tool call blocked by hook. Reason: outside this worker's declared file set.
   Allowed: docs/contracts.md. Report deviations in your report file instead of editing.
   ```

   `.crush/hooks/enforce_worker_files.py:_norm()` strips the Windows workspace prefix
   (`g:/mój dysk/projekty/vajb orbit/`) but not the Linux one, so on this host only a
   workspace-relative path (`docs/CONTRACTS.md`) matches the declared set; the `.agents/`
   fail-open branch has the same blind spot, so this report and the gate log were written
   with relative paths too. Every edit in this pass was made that way. This is the host
   defect W5 recorded as **LOW-9**; it is worth fixing in the hook (one prefix entry) before
   the next wave dispatches workers here, since a worker following `AGENTS.md` ("always use
   absolute paths") cannot write at all.

2. **Open, outside my file set: W3's report still carries the false limit.** W5's MED-2 fix
   text asks to "correct W3's §1 sentence so the wave's evidence chain does not carry the
   false limit forward" (`.agents/gen/ui_chrome_w3_report.md`: *"A headless run cannot observe
   a warning"*). My declared set is `docs/CONTRACTS.md` and the brief forbids other files, so
   that sentence is **uncorrected**. The contract now records the truth, so the next D5-style
   worker reads the correction in §9; the stale sentence itself needs an orchestrator or a
   W7-scoped one-line edit.

3. **Open, W5's LOW findings: untouched, as the wave rule says** (LOW items ride to
   `.agents/gen/LOW_BACKLOG.md`). I did not add them; the backlog write is not in my set.

4. **Line-number drift inside `docs/CONTRACTS.md`:** everything below line 659 shifts by one
   after Edit C (e.g. the "Fourth harness limit" item now sits at 676). Nothing in the file
   cross-references those lines numerically, so no text update is owed.

---

## 8. Files written by this pass

| Path | Role |
|---|---|
| `docs/CONTRACTS.md` | the two MED fixes (17 insertions / 5 deletions vs `HEAD`) |
| `.agents/gen/ui_chrome_w6_gate.log` | the confirmation gate run (raw, `[SUMMARY] passed=226 failed=0`) |
| `.agents/gen/ui_chrome_w6_report.md` | this report |

No other path was written: `git status --short` shows no change I own outside these three
(the other modified paths belong to W1-W4's landed work, the parallel graphics lane, and
`docs/gameplay/19_testing_notes.md` from W4).
