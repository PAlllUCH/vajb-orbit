---
slice: S12
phase: P2
lane: code
status: active
gate_baseline: "807/0"
---

# S12 — Ore budget (the cleaving arithmetic, measured)

## Goal
Put the ore faucet's real numbers on the table — how much ore a field holds, how
much each depletion path delivers, and at what rate — so the owner can tick
`01 §5.6`'s `GUN_BURST_SHARE`/`FRAGMENT_CORE_SHARE` and `02 §5.1`'s scale rows
from measurement instead of from arithmetic. No production behaviour changes in
this slice.

## In scope
- Two probes measuring the shipped tree, read-only, seeded, byte-reproducible:
  `tests/probe_s12_field_budget.gd` (S12-K0) and
  `tests/probe_s12_rock_rate.gd` (S12-K1).
- S12-R1's replay review: both probes re-run byte-identically at the wave
  baseline, the ratio table checked against the emitted constants.

## Out of scope
- **Any production-code edit.** The caps, the fragment-share rule and the scale
  rows are proposals (`01 §5.6`, `02 §5.1`) and need owner ticks first; a wave
  that implemented them now would be editing the yardstick it measures against.
- Veins, cluster placement, field counting, hold-ladder changes (`02 §5.1`
  Rule B) — a later wave, armed with this slice's numbers.
- The ARMORY pane's readability/ded height findings (D12-A0, design lane) and
  `.agents/gen/session_2026-09-25_findings.md` §2's F1 (rack plate) — different
  lane, different files.
- `docs/` edits: the two amendments are already written and owner-ticked.

## Acceptance criteria
- [ ] AC1 — `probe_s12_field_budget` prints, for one seeded T1 field: the
  field's Σ spawn yield, Σ delivered ore units and the out/in factor for the
  laser path and for the gun path; two runs print byte-identical rows
  (`[S12K0]` lines, last line `done failures=0`).
- [ ] AC2 — `probe_s12_rock_rate` prints delivered ore units/s and delivered
  ore units/rock for the mining laser, a 3-cannon rack and a max-cell rack on
  the same seeded field, plus the mining:gunning ratio; two runs byte-identical
  (`[S12K1]` lines).
- [ ] AC3 — neither probe writes production code, the profile, or any `user://`
  path (scratch store only); the universal gate reads **807/0** before and after
  and no gate row moves (probes are not gate rows).
- [ ] AC4 — every number a probe uses is read from its owner (`Weapons`,
  `Asteroid`, `AsteroidField`, `MineralCatalog`, `MiningLaser`, `ShipFit`); a
  probe that re-declares a yield, chip rate, cadence, `MINE_CYCLE` or hold is a
  failure, and R1 greps for it.
- [ ] AC5 — R1 reproduces both probes byte-identically on a detached worktree at
  this slice's baseline commit and publishes the ratio table with its own
  reading of every constant the probes printed.

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S12-K0 | `vajb-orbit/tests/probe_s12_field_budget.gd` | `S12-K0_BRIEF.md` |
| S12-K1 | `vajb-orbit/tests/probe_s12_rock_rate.gd` | `S12-K1_BRIEF.md` |
| S12-R1 | `vajb-orbit/tests/probe_s12_r1_replay.gd` | `S12-R1_BRIEF.md` |

## References
- `docs/gameplay/01_economy_core.md` §5.6 — the invariant and its amendment
- `docs/gameplay/02_minerals.md` §5.1 — Rule A (no minting) + Rule B (scale)
- `docs/CONTRACTS.md` §5 (lines 345-375) — the cleaving and gun-work pins this
  slice measures
- `docs/CONTRACTS.md` §9 (the gate) and §14 (probe conventions, `[S26R2]` model)
- `docs/gameplay/18_engine_spec.md` §6/§13/§15 — owner-locked; the probe reports
  what the tree does, never what the spec says it should do

## Carries forward
- `.agents/gen/session_2026-09-25_findings.md` §2 F6 and §3 (the live-fire
  observation this slice measures properly). No `L#` row is absorbed; the wave
  raises its own.
