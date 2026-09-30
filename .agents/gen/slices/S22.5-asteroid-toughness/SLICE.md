---
slice: S22.5
phase: P3
lane: code
status: draft
gate_baseline: "971/0"
---

# S22.5 — Asteroid toughness

## Goal
A rock's life becomes a real, size-aware and randomised quantity instead of its ore
budget: an XL takes several times the fire an S does, every rock rolls its own
toughness, debris stops dying to a single glancing hit, and sustained fire on a
large rock sheds visible splinters off it.

## In scope
- `game/ore_tuning.gd` — the four new fields (`toughness_min/max`,
  `size_toughness_mult`, `fragment_work`, `splinter_chance` + its cap) beside
  S13/S14's, with the F1 overlay's Save/Load coverage (`02_minerals.md` §5.3)
- `game/asteroid.gd` — the rolled `toughness`, the gun-door divisor, the
  no-ore work budget, the splinter signal (`02_minerals.md` §5.3; a cite-only
  reference to owner-locked `18_engine_spec.md` §13)
- `game/asteroid_field.gd` — the splinter spawn on a non-cracking gun chip
  (reusing the `_cleave` ejection shape and the field's seeded RNG)
- `tests/test_s22_5_asteroids.gd` — new suite, one row per AC

## Out of scope
- The mining door's arithmetic: the mining laser's 1.2 s/unit pace, `work_per_unit`,
  the split table, the spawn mix and the tier yields all stand (§5.3's A5)
- Ore economics: Rule A holds, a splinter and every gun-born child pay nothing
- Owner-locked `18_engine_spec.md` §13 (cite-only; the owner folds the row in)
- Art: no new sprites — a splinter is the shipped S-class look

## Acceptance criteria
- [ ] AC1 — every spawned rock carries a rolled toughness in [0.80, 1.60], reproducible under the field's seed and readable off the rock
- [ ] AC2 — a gun hit's work divides by `SIZE_TOUGHNESS_MULT[class] × toughness`; measured time-to-crack for a T1 rock at the mean roll is S ≥ 3.0 s · M ≥ 5.0 s · L ≥ 8.0 s · XL ≥ 12.0 s of `w_laser` 30 dps, and S ≠ XL
- [ ] AC3 — mining is untouched: the mining laser's 1.2 s/unit pace and every mining payout row are unchanged
- [ ] AC4 — a gun-born fragment survives ordinary fire: cracking it takes `FRAGMENT_WORK[class]` chip work (S 2.0 · M 3.0 · L 4.5) and a ram no longer insta-cracks it
- [ ] AC5 — a gun-born fragment still carries `bore 0` (pays nothing) and still never splits further (§5.2 ter's parentage rule intact)
- [ ] AC6 — an L/XL rock under sustained fire sheds splinters at 25 % per non-cracking hit, capped at 1 per 0.5 s per rock; each is a real S body with `bore 0` and the S budget, ejected outward; S/M rocks shed none, and a cracking hit spawns the normal split set
- [ ] AC7 — no ore is minted: a fully shot family still realises ≤ `GUN_BURST_SHARE × _bore_ore`, and the sealed files (`damage.gd`, `projectile.gd`'s pin) are untouched

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S22.5-B1 | `vajb-orbit/game/, vajb-orbit/tests/, .agents/gen/slices/S22.5-asteroid-toughness/S22.5-B1_report.md` | `S22.5_BRIEF.md` |
| S22.5-R1 | `vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S22.5-asteroid-toughness/S22.5-R1_review.md` | `S22.5_BRIEF.md` |
| S22.5-F1 | `vajb-orbit/game/, vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S22.5-asteroid-toughness/` | `S22.5_BRIEF.md` |

## References
- `docs/gameplay/02_minerals.md` §5.3 — **the operative amendment** (A1–A5, ticked)
- `docs/gameplay/02_minerals.md` §5/§5.1/§5.2 bis/ter — the ore budget, the split
  table and the parentage rule this slice must not move
- `docs/gameplay/01_economy_core.md` §5.6 — the `GUN_BURST_SHARE` payout cap
- `vajb-orbit/game/asteroid.gd`'s header comments — the work-not-damage contract
- `docs/CONTRACTS.md` §9 — the gate figure

## Carries forward
- The owner's 2026-09-30 ask (its three parts) and the two S22-era tickets it does
  not touch: **L253** (the seeker fuze's no-distance-gate delivery) and **L254**
  (the anti-flam docstring) stay where they are
