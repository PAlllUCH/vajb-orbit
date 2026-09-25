---
slice: S12
worker: S12-K0
role: coder
status: ready
tier: paid
---

# S12-K0 — the field budget probe (`tests/probe_s12_field_budget.gd`)

Read, in this order: `S12_BRIEF.md` (§4 is the pinned contract and §8 the hard
rules, both binding), `SLICE.md` (AC1/AC4), `docs/gameplay/02_minerals.md` §5 and
§5.1, `docs/CONTRACTS.md` §5 lines 345-375, and
`vajb-orbit/tests/probe_s2_6_burst.gd` for the probe shape.

## Task
Build one standalone probe that measures **how much ore a field holds and how
much each depletion path realises from it**. Per leg (`LASER`, `GUN3`,
`GUNMAX`, §4's table) and per tier (T1 and T3), on the pinned seeded field:

- Σ spawn yield: sum `yield_units` over `field.rocks()` immediately after
  `setup`, walked once (the fragments do not exist yet);
- Σ delivered ore, per §4's definition for that leg;
- the out/in factor, the rocks the field spawned in total (`spawned`-style
  count, read from the field's children), the steps taken and the seconds the
  leg's own rate implies;
- the constants of §4's table, printed with the value read from its owner.

Run each leg on a freshly seeded field. `[S12K0]` prefix, one line per row, last
line `[S12K0] done failures=N`, exit 1 when N > 0. Two runs must print
byte-identical output.

## Output contract
- Report: `.agents/gen/slices/S12-ore-budget/S12-K0_report.md` (≤120 lines):
  the two runs' output, the how-to-run line with its `XDG_DATA_HOME`, and the
  budget table.
- Gate: **unchanged at 807/0** — run it once and record the `[SUMMARY]` line;
  the wave moves no gate row, so a moved row is a finding, not a fix.
- Never write a production file, the profile, or a live `user://`.

## Paste block
See `S12_prompts.md`, block `S12-K0`.
