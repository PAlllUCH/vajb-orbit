---
slice: S10
worker: S10-R1
role: reviewer
status: ready
tier: deepseek-direct
---

# S10-R1 — the mandatory review of the ARMORY fixes

## Context (read in this order)

1. `slices/S10-armory-racks/S10-A0_report.md` end to end — the audit this wave
   answers; its probe is the baseline you re-run
2. `slices/S10-armory-racks/S10-B1_report.md` end to end — the fix and its
   six deviations
3. `S10_BRIEF.md` §"A0 + B1 dispositions" — the orchestrator's rulings on those
   deviations (D1 corrected, D2/D3 accepted, D4 staged, D5 recorded)
4. `docs/design/STATION_HUB.md` §5.11 + §5.1, `docs/gameplay/09_ship_slots_modules.md`
   §11, `docs/CONTRACTS.md` §17/§16/§9, `docs/design/UI_SPEC.md` §3.9/§3.10

## Task — re-measure everything yourself, fix nothing

Diff against the pins, never against the brief. The bar is **real input**: a
probe that calls `can_drop`/`drop` is not evidence (S8's L170, this wave's whole
reason for existing).

1. **Re-run A0's probe and B1's suite byte-identically** (paths in the reports)
   and confirm: the chip's plate and `✕` are hittable post-layout and a real
   press/move/release commits a move/swap, a real `✕` click removes, a rolled
   (`mod_*`) cell reads a cycle figure, and a bay click plus `weapon_1..7` move
   the selection with **no** profile write (byte-compare the fit/bag/`batteries`
   around each).
2. **Independently prove the red state — in a worktree.** `git worktree add` at
   `c8a6b5d` (the pre-B1 tree), copy B1's suite in, run the filtered suite, and
   report the failure count and lines. **Never `git checkout` the shipped tree**
   to measure red (B1 did; that is the breach this review closes).
3. **No pin moved:** the `REFUSAL_W_SLOTS_FULL` wording, `RACK_KEY`, the
   `SALVO`/drum constants, the bay/ember frame presentation, and
   `test_d7_armory.gd`'s **11 rows unmoved and green**. Compare against
   `c8a6b5d` where a number is in doubt.
4. **Scope:** the diff is `ui/station/armory_panel.gd` + `tests/test_s10_armory_input.gd`
   only — no `.tscn`, `docs/`, `assets/`, `fitting_panel.gd`, no shell-edit
   residue (B1 disclosed `sed`/`python3` use while iterating; diff the shipped
   artifacts and say whether anything unintended rode along).
5. Gate **twice** on fresh scratch stores; live `profile.cfg` / `economy_log.txt`
   md5 pair unchanged across every run. Then
   `staging/verify_wave.py verify --baseline s10_repro_start --forbidden
   vajb-orbit/project.godot docs/gameplay/18_engine_spec.md
   docs/design/STATION_HUB.md docs/design/UI_SPEC.md --tests --expect-reports
   .agents/gen/slices/S10-armory-racks/S10-A0_report.md
   .agents/gen/slices/S10-armory-racks/S10-B1_report.md
   .agents/gen/slices/S10-armory-racks/S10-R1_review.md`
   (CONTRACTS is deliberately not forbidden — your §9/§10 write it).
6. Tier findings HIGH/MED/LOW with `file:line` and measured evidence. Write
   `S10-R1_review.md`; append LOW rows at the **next free ids read from
   `LOW_BACKLOG.md`** (D11 runs parallel and may have taken ids; ~L172); update
   `docs/CONTRACTS.md` §9 (measured figure) + §10 (**next free row read at
   close-out** — v0.21 unless a parallel lane landed first; rebase, never
   revert).

## Hard constraints

- File set: `vajb-orbit/tests/`, `vajb-orbit/tools/`, `docs/CONTRACTS.md`.
  Never fix production code; never revert the working tree to measure anything.
- Every probe on a scratch store; bounded; no background commands.
- Report ≤150 lines, one evidence line per finding, no pasted source.

## Output contract

`S10-R1_review.md` (from `_templates/REVIEW.md`): verdict, findings by tier with
`file:line` + the measurement that proves each, the AC-by-AC re-derivation, the
red-state worktree numbers, the gate lines, and the owner ticks the wave leaves.
