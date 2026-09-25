---
slice: S12
worker: S12-K1
role: coder
status: ready
tier: paid
---

# S12-K1 — the rock-rate probe (`tests/probe_s12_rock_rate.gd`)

Read, in this order: `S12_BRIEF.md` (§4 is the pinned contract and §8 the hard
rules, both binding), `SLICE.md` (AC2/AC4), `docs/gameplay/01_economy_core.md`
§5.6, `docs/CONTRACTS.md` §5 lines 345-375, and
`vajb-orbit/tests/probe_s2_6_burst.gd` for the probe shape.

## Task
Build one standalone probe that measures **delivered ore per second and per
rock** for the three legs of §4 (`LASER`, `GUN3`, `GUNMAX`) on the same pinned
seeded field, using §4's definitions verbatim — including the shots-per-second
rule and the delivery rule that only a Small's crack pays on the gun legs.

Print, for each leg: delivered units/s, delivered units/rock, the seconds to
empty the field, the total rocks the field spawned (originals + fragments), and
the mining:gunning ratio against `LASER`. Add one **single-rock** row: one
seeded rock, its `yield_units` in, the units each leg realises out of it, and
its own seconds — this is the per-rock half of `01 §5.6`'s invariant 1.

Also print every constant §4's table names, with the value read from its owner,
and the hold it compared against (`ShipFit.HULLS[&"ship_vanguard"][&"cargo"]`
and the maximum over `HULLS`).

`[S12K1]` prefix, one line per row, last line `[S12K1] done failures=N`, exit 1
when N > 0. Two runs must print byte-identical output.

## Output contract
- Report: `.agents/gen/slices/S12-ore-budget/S12-K1_report.md` (≤120 lines):
  both runs' output, the how-to-run line with its `XDG_DATA_HOME`, and the rate
  table.
- Gate: **unchanged at 807/0** — run it once and record the `[SUMMARY]` line.
- Never write a production file, the profile, or a live `user://`.

## Paste block
See `S12_prompts.md`, block `S12-K1`.
