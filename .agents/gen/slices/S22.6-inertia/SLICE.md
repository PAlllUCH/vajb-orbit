---
slice: S22.6
phase: P3
lane: code
status: draft
gate_baseline: "983/0"
---

# S22.6 — Inertia

## Goal
Releasing the stick stops feeling like a hand brake: a hull coasts twice as long and twice
as far as it does today, and a broken rock's debris flies instead of settling within its own
width, so the vacuum reads as vacuum in both cases.

## In scope
- `game/ship_fit.gd` — `COAST_TIME_MULT` 2.5 → **5.0** and its retune comment
  (`18_engine_spec.md` §13's new Hull release row; `CONTRACTS.md` §22 T1 / §23.5 T1)
- `game/asteroid.gd` — `LINEAR_DAMP` 3.71 → **0.35**, new `FRAGMENT_LINEAR_DAMP`
  **0.25** for cleave children, and the damping derivation comment restated
  (§13's new Rock drift row)
- `game/asteroid_field.gd` — the child that inherits the lighter damp (the
  cleave/splinter spawn path)
- `tests/test_s22_6_inertia.gd` — new suite, one row per AC

## Out of scope
- The release *law*: it stays a scripted constant brake at `max_speed / coast_time`
  (no drag model, no Newtonian rewrite — the tick is the constant, not the shape)
- `max_speed`, `accel_time`, `turn_rate`, `turn_spinup`, `BRAKE_MULT` (1.8),
  `ANGULAR_DAMP_MULT`, the S-thrust brake and the per-axis thrust law
- `game/damage.gd` and the collision maths: the ram's momentum hand-off is unchanged
- `docs/gameplay/02_minerals.md` (S22.5's ore rows) and the mining/extraction arithmetic

## Acceptance criteria
- [ ] AC1 — `COAST_TIME_MULT` is **5.0**, the nine resolved `coast_time` rows read 4.0–14.0 s, and a released hull still brakes at a constant `max_speed / coast_time`: a Vanguard (max 427.5 u/s measured) stops in **≈4.0 s over ≈855 u**, measured
- [ ] AC2 — §23.5's acceptance survives: a released forward+strafe holds its bearing within 5° while the speed falls to 0.1×, on one line, at the new rate
- [ ] AC3 — `LINEAR_DAMP` is **0.35** and a cleave child carries **0.25** (`FRAGMENT_LINEAR_DAMP`, `DAMP_MODE_REPLACE` both): a kicked 150 u/s reads ≈106 u/s after one second and carries ≈429 u (a child ≈600 u) before settling, measured
- [ ] AC4 — a field rock at rest stays at rest (no spontaneous drift), and a rammed rock now keeps travelling: the before/after carried distance is measured and tabled
- [ ] AC5 — no other gameplay number moves: `max_speed`/`accel_time`/`turn_*`/`BRAKE_MULT`/`ANGULAR_DAMP_MULT`, the collision hand-off, the mining arithmetic and `damage.gd` are all unchanged
- [ ] AC6 — the as-shipped constants table matches 18 §13's two new rows and CONTRACTS §22 T1 / §23.5 T1 (`5.0`, reversal `2.5`) exactly
- [ ] AC7 — only the listed rows move (the flight-decay suites' numerics re-derive; the rows that read a *constant* by name — `test_engine2_cleaving.gd:267`, `test_s7_affixes.gd` — survive untouched); any other count moving is a bucket-2 report

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S22.6-B1 | `vajb-orbit/game/, vajb-orbit/tests/, .agents/gen/slices/S22.6-inertia/S22.6-B1_report.md` | `S22.6_BRIEF.md` |
| S22.6-R1 | `vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S22.6-inertia/S22.6-R1_review.md` | `S22.6_BRIEF.md` |
| S22.6-F1 | `vajb-orbit/game/, vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S22.6-inertia/` | `S22.6_BRIEF.md` |

## References
- `docs/gameplay/18_engine_spec.md` §13 — the two new rows (owner-ticked 2026-09-30)
- `docs/CONTRACTS.md` §22 T1 / §23.5 T1 / §14 — the ticked coast value and its history
- `docs/gameplay/18_engine_spec.md` §3.1/§3.2 — the flight law this does not change
- `game/asteroid.gd`'s header — the derivation the new damping supersedes

## Carries forward
- The owner's 2026-09-30 question ("why do things stop moving?") and its two ticks; the
  S22.5 rock work is untouched and its `DRIFT_SPEED_CEILING` derivation is superseded only
  as a *target* (the constant stays as documentation of why 3.71 existed)
