---
slice: S22.7
phase: P3
lane: code
status: draft
gate_baseline: "990/0"
---

# S22.7 — Mass physics & rock contact

## Goal
Mass stops being decorative. The flight forces derive from the class mass and are applied
against the fit's, so fitted plating finally makes a hull slower and a heavier fit coasts
further; fuel burns in proportion to the thrust it buys; a rock weighs what its size says;
rocks collide with each other instead of passing through; and every split leaves at its own
random speed, weighted so splinters fly and boulders lumber.

## In scope
- `game/ship_stats.gd` + `game/ship_fit.gd` — `base_mass` (the class row's `hull_mass`,
  read before the armour pass); plating's `1 + |speed penalty|` becomes a mass multiplier
  (the three handling-time multipliers retire); the derived `engine_thrust`
  (`18_engine_spec.md` §3.2's mass law, §13's fuel rows)
- `game/player_ship.gd` — the force sites take the **class** mass while the body keeps the
  **fitted** mass; the boost burn ∝ thrust (Vanguard-anchored 3.0/s); the dash's fuel ∝ mass
- `game/asteroid.gd` — `ROCK_MASS_DENSITY × r²` (M anchored at 560 t → S 183 / L 1 383 /
  XL 2 571); `COLLISION_MASK` **3** (rocks meet rocks); the split-speed jitter
  `(0.7, 1.3)` and the mass weighting `(m_M/m_child)^0.5` beside the ejection constants
- `game/asteroid_field.gd` — the minimum-separation placement pass (field spawn ring and
  the debris ring, margin 8 u); the jitter × weighting applied in `_deploy_debris`
- `tests/test_s22_7_ships.gd` + `tests/test_s22_7_rocks.gd` — one suite per builder

## Out of scope
- `fuel_max` stays the flat 200 (§13's owner-locked "flat base, not a class column" — M5
  kept flat at the tick)
- The true-vacuum rewrite (N3) and a real authored `thrust` column re-balancing the nine
  rows (M2b) — both staged, neither ticked
- `game/damage.gd` and the collision maths: `Impact.collision_damage` is unchanged (it
  already takes whatever masses the callers hand it)
- Rock-rock damage: rocks gain **no** contact monitor (R2 — a contact is a nudge, not a
  fight); ruling 15/16 stays ship-vs-rock
- NPC hulls carry no fit, so their forces are already class-derived — no NPC flight number
  moves and no NPC file needs the law (B1 discloses it)
- The mining/extraction arithmetic, the S22.5 ore constants, the split mix and the
  mining laser are untouched

## Acceptance criteria
- [ ] AC1 — `ShipStats.base_mass` is the class row's `hull_mass` read before any module
  multiplication; at an unfitted hull `base_mass == hull_mass` for all nine classes, and
  every shipped flight figure is byte-identical (the S2.6/S22.6 measured pairs stand)
- [ ] AC2 — the forces are the class's: `_thrust_axis`, `_step_release`'s brake and the
  turn torque derive from `base_mass` while `_body.mass`/`_body.inertia` keep the fitted
  mass; a fitted `mass_add` now slows the hull (measured: an `h_composite` fit accelerates
  ~9 % slower than today's resolve of the same fit, its coast carrying ~10 % further)
- [ ] AC3 — plating's ponderous half is mass: `_apply_speed` multiplies `hull_mass` by
  `1 + |penalty|` (beside `mass_add`) and no longer multiplies `accel_time`/`coast_time`/
  `turn_spinup`; `h_plate_light` resolves mass ×1.05 with the times unchanged
- [ ] AC4 — fuel burns ∝ thrust: the boost's per-second burn is §13's eight-rate table
  (Vanguard **3.0** exactly; fighter 2.75 · miner 1.81 · patrol 3.22 · freighter 1.94),
  the dash spends `25 × base_mass / 110`, and `fuel_max` stays 200
- [ ] AC5 — §23.5's acceptance stands at the new law: a released forward+strafe holds its
  bearing within 5° to 0.1× on one line (`test_s11_flight_stop.gd` re-derived, never weakened)
- [ ] AC6 — rock mass is `ROCK_MASS_DENSITY × r²`: the four class masses measure within
  ±10 % of §13's row (S 183 / M 560 / L 1 383 / XL 2 571 t) and are printed; the retired
  `ROCK_MASS_MULT`/`ROCK_MASS_REFERENCE` pair stays as the superseded record (no live reader)
- [ ] AC7 — rocks collide with rocks (`COLLISION_MASK` 3) and a rock-rock contact deals no
  damage (no monitor); after any 12-rock spawn and any cleave, no two rocks overlap
  (centre distance ≥ r_i + r_j + 8 u margin) — the separation pass is deterministic on the
  field's seeded RNG
- [ ] AC8 — split speed is random and mass-weighted: a resting rock's children leave at
  ~105–195 u/s (jitter 0.7–1.3 on the whole ejection vector), an S splinter at ~1.75× the
  base kick and an L child at ~0.64× (the §13 weighting), measured and tabled
- [ ] AC9 — no other gameplay number moves: the S22.5 ore constants, `split_mix`, the kick
  150, the cone 360, the two rock damps (0.35/0.25), `BRAKE_MULT`, `ANGULAR_DAMP_MULT`,
  `ACCEL_TIME_MULT`, `COAST_TIME_MULT` and `damage.gd` are all unchanged; only the listed
  test rows move — any other count moving is a bucket-2 report

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S22.7-B1 | `vajb-orbit/game/, vajb-orbit/tests/, .agents/gen/slices/S22.7-mass-physics/S22.7-B1_report.md` | `S22.7_BRIEF.md` |
| S22.7-B2 | `vajb-orbit/game/, vajb-orbit/tests/, vajb-orbit/tools/, .agents/gen/slices/S22.7-mass-physics/S22.7-B2_report.md` | `S22.7_BRIEF.md` |
| S22.7-R1 | `vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S22.7-mass-physics/S22.7-R1_review.md` | `S22.7_BRIEF.md` |
| S22.7-F1 | `vajb-orbit/game/, vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S22.7-mass-physics/` | `S22.7_BRIEF.md` |

## References
- `docs/gameplay/18_engine_spec.md` §3.2 (the mass law), §13 (the rock mass, rock-rock
  contact, ejection and fuel rows) — owner-ticked 2026-09-30
- `docs/CONTRACTS.md` §14's 2026-09-30 S22.7 bullet — the disclosure of record
- `docs/gameplay/02_minerals.md` §5.4 — the rock mass and split speed rows
- `docs/gameplay/09_ship_slots_modules.md` §1's amendment note — the one-channel plating read
- `docs/CONTRACTS.md` §23.5 — the one-vector acceptance this wave must not break

## Carries forward
- The owner's 2026-09-30 ask ("i want everything to be physics based on mass") and the
  ticked rows R1–R3, S1–S2, M1–M4 (M2b/M5-flat/M6 staged); backlog **L8 closes in B2**;
  the three untracked S22.6 `.uid` sidecars join the pre-flight commit
