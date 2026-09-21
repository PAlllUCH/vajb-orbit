# W4 report — D6 doc ticks (UI-chrome wave)

Worker: **W4**, coder, defect **D6** only. Declared file set:
`docs/gameplay/19_testing_notes.md`, `docs/CONTRACTS.md`.
Host: Linux (`~/VajbOrbit`, Godot 4.7.2-stable at `~/.local/bin/godot`), 2026-09-21.

## Verdict

Both doc ticks landed. **Two edits, two files, no code, no asset, no theme, no scene.**
`git diff --stat` over my file set: `docs/CONTRACTS.md | 8 +++++---`,
`docs/gameplay/19_testing_notes.md | 3 ++-`.

## Gate measurement behind edit 2 (taken before the edit, not copied from the brief)

```text
godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
```

Raw log archived at `.agents/gen/ui_chrome_w4_gate.log` (19 631 bytes), exit 0,
2.8 s wall clock, `[SUMMARY] passed=219 failed=0`, no `SCRIPT ERROR`, no RID-leak line
(the only WARNING is the test's own deliberate unwritable-log-path probe).

Measured per-suite counts (219 total, **17** `test_*.gd` suites):

| suite | tests | | suite | tests |
|---|---|---|---|---|
| engine2_cleaving | 9 | | p1_catalogues | 11 |
| engine2_damage | 20 | | p1_clock_log | 4 |
| **engine2_dock** | **2** | | p1_market | 13 |
| engine2_fixes | 17 | | p1_pricing | 5 |
| engine2_hud | 19 | | p1_profile | 9 |
| engine2_loot | 13 | | p1_refinery | 6 |
| engine2_npc | 28 | | p1_repairs | 5 |
| engine2_pools | 16 | | | |
| engine2_weapons | 29 | | | |
| engine2_wiring | 13 | | | |

**Where the +2 comes from, measured, not inferred.** The brief's "16 suites" and
`CONTRACTS.md`'s W8 per-suite list both predate `vajb-orbit/tests/test_engine2_dock.gd`:
`git log --diff-filter=A` dates that file to `c24ed3f` ("Close engine slice 2"), it holds
exactly 2 `func test_` methods (both `[PASS]` in the log above), and the W8-era 16-suite
list sums to 217 = 219 − 2. So the suite grew; the count did not drift.

## Edit 1 — `docs/gameplay/19_testing_notes.md`, B2-3 (line 56)

The stale closing sentence of the B2-3 defect paragraph, which still asked for a coder
task plus a plan line although the fix had landed.

**Before**

```text
and the step 800. Tiny coder task + a line in `IMPLEMENTATION_PLAN` §9.8 follow-up.
```

**After**

```text
and the step 800. Landed 2026-09-21, recorded in `IMPLEMENTATION_PLAN` §9.8 item 6
with the measured bindings (see the fix note below).
```

It now points at the landed evidence, which is real: `IMPLEMENTATION_PLAN.md` §9.8 item 6
("Batch-2 playtest follow-up (2026-09-21)") records `%ZoomPlus` → `-1` → world radius
3200 → 2400 (zoom in) and `%ZoomMinus` → `+1` → 3200 → 4000 (zoom out), clamp, step and
wheel-zoom camera unchanged. The "see the fix note below" half points at the
"**Fixed 2026-09-21 (batch 2, measured)**" paragraph already in the same section
(`19_testing_notes.md:58-62`), so the sentence no longer contradicts the section it sits in.
Nothing else in that file was touched; the two other §9.8 references (lines 7 and 96) are
still accurate and were left alone.

## Edit 2 — `docs/CONTRACTS.md` §9 (universal test gate), lines 639-646

**Before**

```text
Expected: `[SUMMARY] passed=217 failed=0`, exit 0, no `SCRIPT ERROR`. A wave is
done = gate green + the worker added tests for their slice. The suite held **53**
tests through engine wave 1; engine slice 0 added `tests/test_engine2_pools.gd`
(**16**) and `tests/test_engine2_cleaving.gd` (**9**), engine slice 2 added six
`tests/test_engine2_*.gd` suites — `weapons` (**29**), `npc` (**28**), `damage`
(**20**), `hud` (**19**), `loot` (**13**) and `wiring` (**13**) — and the slice-2 fixer
pass added `tests/test_engine2_fixes.gd` (**17**), so the total is **217** and the count
to read is the measured one with zero failures, never a stale total. Discovery is
```

**After**

```text
Expected: `[SUMMARY] passed=219 failed=0` (re-measured on this host 2026-09-21),
exit 0, no `SCRIPT ERROR`. A wave is
done = gate green + the worker added tests for their slice. The suite held **53**
tests through engine wave 1; engine slice 0 added `tests/test_engine2_pools.gd`
(**16**) and `tests/test_engine2_cleaving.gd` (**9**), engine slice 2 added six
`tests/test_engine2_*.gd` suites — `weapons` (**29**), `npc` (**28**), `damage`
(**20**), `hud` (**19**), `loot` (**13**) and `wiring` (**13**) — the slice-2 fixer
pass added `tests/test_engine2_fixes.gd` (**17**) and the slice-2 close added
`tests/test_engine2_dock.gd` (**2**), so the total is **219** and the count
to read is the measured one with zero failures, never a stale total. Discovery is
```

Every other number in the paragraph is byte-identical (53, 16, 9, 29, 28, 20, 19, 13, 13,
17, the W6 `passed=200` record and its 15-suite list, the W8 `passed=217` record and its
16-suite list, the `test_p1_profile.gd:204` note); no section was renumbered. The two
chain figures that had to move are the two the tick is about: the expected total
(217 → 219) and the arithmetic that produces it, which now names the suite that supplied
the 2 tests, so `219` is reconcilable by any reader who re-runs the gate.

## Observed but NOT edited (outside the two-edit scope; for the next CONTRACTS writer)

Both are now dated-and-superseded rather than live claims, but a successive CONTRACTS
writer should decide on them:

1. `docs/CONTRACTS.md:655` — the W8 record still reads "(W8 re-review, **the number this
   file now expects**): `passed=217 failed=0`". The measurement itself (217, its 16-suite
   list) is correct history and was left untouched, but the parenthetical now claims to be
   the live expectation while line 639 states 219. One-clause fix: drop
   "the number this file now expects" (e.g. "before `engine2_dock` landed").
2. `docs/CONTRACTS.md:763` — the v1.1 changelog entry says "**§9**: the expected total is
   the **measured 217**". Correct as a record of what v1.1 wrote; a v1.2 entry (or a
   parenthetical) is what would supersede it, and changelog authorship was not in my set.

## Environment note (LOW, host-level, worth the waveboard)

`file_path` must be **workspace-relative** in this session:
`.crush/hooks/enforce_worker_files.py` normalizes only the Windows workspace root
(`g:/mój dysk/projekty/vajb orbit/`), so on Linux an absolute `/home/…` path normalizes to
itself, never matches the worker set, and is denied. Both my edits were denied first
(absolute paths) and landed unchanged once passed as `docs/CONTRACTS.md` and
`docs/gameplay/19_testing_notes.md`; `AGENTS.md`'s "always use absolute paths" guidance is
wrong for hooked writes on this host. Worth a line in the hook docstring or in WAVEBOARD.

## Files written

- `docs/gameplay/19_testing_notes.md` (edit 1)
- `docs/CONTRACTS.md` (edit 2)
- `.agents/gen/ui_chrome_w4_report.md` (this report)
- `.agents/gen/ui_chrome_w4_gate.log` (raw gate evidence, 219 passes)
