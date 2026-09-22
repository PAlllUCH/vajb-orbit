---
slice: S2.6
phase: P2
lane: code
status: draft
gate_baseline: "437/0 (sandboxed; 433/4 on the live save — L93)"
---

# S2.6 — Truth and feel (repair + polish + flight model)

## Goal
The gate tells the truth on any machine, and the owner's seven feel rulings land:
asteroid fragments burst outward, beam hits scatter and beams end mid-object,
mining chips spark, the ship accelerates slower and keeps its speed, turning is
neutral (no translation) and its slide is symmetric, and motion blur never blurs
the player hull.

## In scope
- Gate hermeticity — CONTRACTS §14 (closes L90/L93)
- Fragment outward kick — CONTRACTS §14 (`FRAGMENT_OUTWARD_KICK 150.0`)
- Beam sink + hit scatter + the mining chip read — CONTRACTS §14 / FX_SPEC §1.6
- Flight feel — CONTRACTS §14's flight block: `ACCEL_TIME_MULT 2.0`,
  `COAST_TIME_MULT 2.0`, `TURN_TRANSLATE_LEAK_MAX 5.0 u`, mirror symmetry
- Blur exclusion — FX_SPEC §5's amendment (`SPEED_BLUR_EXCLUDE_PLAYER`)

## Out of scope
- Any balance number (damage, cadence, range, Energy, ammo, prices)
- Instance/affix or auction work (S3), battery grouping (S4)
- New input bindings or control-scheme changes (the A/D/cursor scheme stands)
- The exit-time leak noise (L91) and the hook path fix (L92a)

## Acceptance criteria
- [ ] AC1 — two consecutive gate runs against a mutated live profile both read
      `passed=<total> failed=0` with identical counts, and the live
      `profile.cfg` md5 is unchanged across both (CONTRACTS §14)
- [ ] AC2 — a near-stationary rock's break moves every fragment outward:
      radial velocity component ≥ 0.5 × `FRAGMENT_OUTWARD_KICK` in 200 seeded breaks
- [ ] AC3 — a held beam's contact reads scatter within the pinned jitter disc and
      the drawn beam ends at `lerp(hit, centre, 0.45)`
- [ ] AC4 — the mining beam plays the chip sparks (L65 closed)
- [ ] AC5 — time to 90 % of `max_speed` ≥ 1.8× today's (measured, per class), and
      the coast decay re-derives to §13's column (`COAST_TIME_MULT 2.0`)
- [ ] AC6 — a full 360° neutral turn at zero throttle displaces the hull ≤ 5.0 u,
      and mirrored maneuvers mirror within 1 %
- [ ] AC7 — at full blur strength the hull-region pixels match the unblurred
      render while the background differs measurably

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S2.6-R0 | `docs/,vajb-orbit/tests/,vajb-orbit/tools/` | `S2.6_BRIEF.md` |
| S2.6-R1 | `vajb-orbit/tests/` | `S2.6_BRIEF.md` |
| S2.6-R2 | `vajb-orbit/game/asteroid.gd,vajb-orbit/tests/` | `S2.6_BRIEF.md` |
| S2.6-R3 | `vajb-orbit/game/weapons.gd,vajb-orbit/game/mining_laser.gd,vajb-orbit/game/projectile.gd,vajb-orbit/tests/` | `S2.6_BRIEF.md` |
| S2.6-R4 | `vajb-orbit/game/player_ship.gd,vajb-orbit/game/ship_fit.gd,vajb-orbit/tests/` | `S2.6_BRIEF.md` |
| S2.6-R5 | `vajb-orbit/game/speed_fantasy.gd,vajb-orbit/game/speed_blur.gdshader,vajb-orbit/game/player_ship.tscn,vajb-orbit/tests/` | `S2.6_BRIEF.md` |
| S2.6-R6 | `vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md` | reviewer |
| S2.6-R7 | the union of R2–R5 sets + `docs/CONTRACTS.md` | fixer, only on HIGH/MED |

Each builder owns exactly one test file (`test_s2_6_burst/beam/flight/blur.gd` +
R1's `test_s2_6_gate_hygiene.gd`) — never edit another worker's file.

## References
- `docs/CONTRACTS.md` §14 (this wave's pin, incl. the flight block), §4 (the
  HANDLING rows the multipliers re-derive), §5, §9 (the gate)
- `docs/design/FX_SPEC.md` §1.6 + amendment, §5 + the blur-exclusion amendment
- `.agents/gen/_state/LOW_BACKLOG.md` L65, L90, L93

## Carries forward
- L91 (leak-line noise), L92 (hook absolute-path + probe-ship policy) — out of scope here
- The owner-locked §13 tick list grows: `accel_time` ×2.0 and `coast_time` back on
  its own column (the revert of the combat wave's ×0.50)
