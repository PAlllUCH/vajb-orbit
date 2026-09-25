---
slice: S14
worker: S14-F1
model: "deepseek-flash"
status: informational
gate: "852/0 → 852/0"
---

# S14-F1 report

## Result
A **disposition pass: no code was changed.** The two HIGHs are closed by the brief's
§3 ratification that landed after the review (`S14_BRIEF.md:77-81`): R1's own remedy
for both is "designer — amend §3's list; **no F1 code pass**" (review `:27-28`), and
its LOW block repeats it for all three ("the remedy is a §3 amendment in the
developer/designer session, not an F1 code pass"). The one MED, S14-B1/F3, is
**left, not F1**: R1's fix-owner column reads "developer/designer — §3's list, then
the row in the next wave" (review `:29`), and an implementer may not add a row to
the tests-that-move list itself (AGENTS.md escalation ladder, bucket 2). No file
under `vajb-orbit/game/`, `vajb-orbit/tests/` or `vajb-orbit/tools/` was written by
this pass; the only file it wrote is this report. Gate **852/0 twice**, exit 0,
0 `[FAIL]`.

## Findings — disposition

| ID | Tier | Disposition |
|---|---|---|
| S14-B1/F1 | HIGH | **Closed by ratification — no code pass.** The moved row `tests/test_engine2_cleaving.gd:453-486` is named by the post-review §3 paragraph (`S14_BRIEF.md:77-81`). Its bounds are the pinned table's own sums, not a new number: L = `M 1-3` + `S 2-4` = **3-7**, M = `S 1-3` = **1-3** (`:459-462`), and the row passes in both gates. |
| S14-B1/F2 | HIGH | **Closed by ratification — no code pass.** The COUNT block (`tests/probe_rock_cleave_a2.gd:280-373`, `_total_span` at `:366`) is named by the same §3 line. It derives every band from the live `OreTuning.split_mix` (`:309`) and measures each kind's own roll, so it cannot drift from the pin. Replayed below: `[A2] done failures=0`, `COUNT Large total=3-7 {3 x32, 4 x62, 5 x108, 6 x68, 7 x30} | kind 1 chi2=0.26 | kind 0 chi2=2.94`, `Medium total=1-3 ... chi2=2.16`. |
| S14-B1/F3 | MED | **Left, not F1 (bucket 2).** `tests/test_engine2_cleaving.gd:291-292` still asserts `klass <= SIZE_LARGE` ("the three rows"). It is green **only because the fixture's seed rolls no XL** (`_field_with()` = seed 7331, 6 rocks; the row PASSes in both gates), while XL is a real roll at the measured **0.0720** (probe replay below; 16 XL in 240 build spawns), so `(1 - 0.072)^6 ≈ 0.64`: **~36 % of 6-rock fixture seeds red that gate row with no behaviour change**. Remedy for the developer session: name `tests/test_engine2_cleaving.gd:291-294` in §3's list, then at `:291` `AsteroidScript.SIZE_LARGE` → `AsteroidScript.SIZE_XL` and "the three rows" → "the four rows", the loop at `:293-294` gaining `AsteroidScript.SIZE_XL` so the XL row is itself proven. Reversal: restore those tokens. |

## Deviations from SLICE.md
None. No pinned value, doc, row count or forbidden file changed; nothing was written
outside this report.

## Evidence

```bash
# gate 1 and gate 2 — two fresh scratch stores, identical counts
XDG_DATA_HOME=/tmp/s14_f1_gate1 $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
  res://tests/headless_runner.tscn --quit-after 1200
# [SUMMARY] passed=852 failed=0    (exit 0; 852 [PASS], 0 [FAIL])
XDG_DATA_HOME=/tmp/s14_f1_gate2 ...  (same command; same store layout)
# [SUMMARY] passed=852 failed=0

# R1's AC replay, re-run by this pass: the F1/F2 numbers and F3's XL rate
XDG_DATA_HOME=/tmp/s14_f1_probe $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
  --script res://tools/r1_s14_ac_replay.gd
# [S14R1] done failures=0
# [S14R1] AC4 1000 rolls ... XL 0.0720 vs 0.08 | build classes={ 0: 100, 1: 75, 2: 49, 3: 16 }
# [S14R1] AC3 conservation measured over 4 seeds x 3 parent sizes
#   (12 rows, each `bore 32.0 -> realised 32`; the +1 slack never used)

# the F2 artifact, replayed
XDG_DATA_HOME=/tmp/s14_f1_a2 $GODOT_CONSOLE --headless --path "$VAJB_PROJ" \
  res://tests/probe_rock_cleave_a2.tscn --quit-after 900
# [A2] done failures=0    (COUNT lines quoted in the disposition above)

# the brief's mandated wave gate, on a fresh scratch store
XDG_DATA_HOME=/tmp/s14_f1_verify python3 staging/verify_wave.py verify --baseline s14_start \
  --forbidden vajb-orbit/project.godot docs/gameplay/18_engine_spec.md \
  docs/gameplay/09_ship_slots_modules.md docs/gameplay/15_module_affixes.md \
  docs/gameplay/04_refinery.md docs/design/ ui/ addons/ --tests \
  --expect-reports .agents/gen/slices/S14-debris-splits/S14-B1_report.md \
  .agents/gen/slices/S14-debris-splits/S14-R1_review.md
# "problems": []   (exit 0; S14_BRIEF.md is listed under "modified" — that §3
#                   ratification, not a code file, and it is not in --forbidden)
```

## Files touched
- None. This report (`.agents/gen/slices/S14-debris-splits/S14-F1_report.md`) is the
  only file the pass wrote.

## Follow-ups
- S14-B1/F3 is the review's own MED, already recorded (`S14-R1_review.md:29` and the
  S14 block in `_state/LOW_BACKLOG.md`); no new ticket. Escalated to the developer
  session for the §3 line plus the two-token row fix in the disposition table.
