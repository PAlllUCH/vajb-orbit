---
slice: S34
phase: P3
lane: code
status: draft
gate_baseline: "1110/0"   # re-measured at dispatch after S33's close
---

> Filled from `_templates/SLICE.md` at the owner's 2026-10-05 note.

# S34 — The refinery queue: timed refining, job slots, inventory

## Goal
Refining takes wall-clock time per resource, runs across upgradable job slots,
and buffers through the refinery's own input/output inventory — the station
gains a machine you leave working.

## In scope
- The job/slot/inventory model + constants — `docs/gameplay/04_refinery.md` §7
- Profile keys + doors — §7.1 + `S34_BRIEF.md` §3
- The queue panel — `STATION_HUB.md` §21.3 P42/P43
- Test migration + the new `test_s34_refinery_queue.gd` suite

## Out of scope
- `u_refine` module synergy (R3's reversal — later economy pass)
- Balance tuning beyond R1–R8 (04 §6's lever order stands)
- `CONTRACTS.md` rows (the review wave's docs pass owns them)

## Acceptance criteria
- [ ] AC1–AC7 = `S34_BRIEF.md` §4's acceptance list (R1 formula, all-or-nothing
  queue, the slot ladder, inventory caps, wall-clock settle, the P42/P43 panel,
  gate + disclosure)

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S34-B1 | `vajb-orbit/game/,vajb-orbit/autoload/,vajb-orbit/ui/,vajb-orbit/tests/` | `S34_BRIEF.md` |
| S34-R1 | `vajb-orbit/tests/,.agents/gen/slices/S34-refinery-queue/` | `S34_BRIEF.md` (acceptance list) |
| S34-F1 | as B1 (only if HIGH/MED) | `S34_BRIEF.md` |

## References
- `docs/gameplay/04_refinery.md` §1–§7, `01_economy_core.md` §3/§6/§7
- `docs/design/STATION_HUB.md` §5.7 + §21.3, `docs/design/UI_SPEC.md` §8
- `docs/CODE_MAP.md` (the refinery wiring rows)

## Carries forward
- Tick **T-133** (the R1–R8 value pack).
- `test_p1_refinery.gd:192` is sealed (must not move).
