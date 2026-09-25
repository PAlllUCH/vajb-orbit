---
slice: S14
phase: P4
lane: code
status: active
gate_baseline: "834/0"
---

# S14 — Four asteroid sizes, debris splits

## Goal
Rocks read as debris: XL breaks into a random mix of L, M and S, each smaller
rock breaks into a random mix below it, and the cascade stays inside S13's ore
budget.

## In scope
- Four size classes `XL > L > M > S` (`SIZE_*` gains XL; XL renders the L
  silhouettes scaled to 180 u — staged art)
- RNG debris splits: XL → L 1-3, M 2-4, S 2-5; L → M 1-3, S 2-4; M → S 1-3;
  S → none (02 §5.2's dated amendment is the pin)
- Spawn size mix S 40 / M 32 / L 20 / XL 8 (proposed in §5.2)
- `OreTuning` fields `split_mix` + `spawn_size_weights` (dev overlay keeps working)

## Out of scope
- Yields: no `SIZE_YIELD_MULT`, no tier-curve change (Rule B stays deferred)
- Rock art commissioning (XL is scaled L art), FX, mining/gun rules from S13
- `FIELD_ROCKS_MIN/MAX`, respawn/diminishing rules (02 §8)

## Acceptance criteria
- [ ] AC1 — seeded 200 XL shatters: children only L/M/S, per-kind counts inside
      the rolled ranges, each kind appears, no child ≥ its parent
- [ ] AC2 — M → only S children; S never splits; L → only M/S
- [ ] AC3 — conservation holds across the mixed chain: a fully mined family
      realises ≤ root `_bore_ore` + 1 (S13's yardstick, re-measured)
- [ ] AC4 — spawn mix over 1000 seeded rolls within ±3 % of 40/32/20/8
- [ ] AC5 — XL draws at 180 u target width from 3 XL looks (scaled L art)
- [ ] AC6 — gate grows only by `test_s14_splits` rows + the listed moved rows,
      twice on scratch stores; `verify --baseline s14_start` clean

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S14-B1 | `vajb-orbit/game/,vajb-orbit/tests/` | `S14_BRIEF.md` |
| S14-R1 | `vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md` | `S14_BRIEF.md` |
| S14-F1 | union of B1 + `docs/CONTRACTS.md` | `S14_BRIEF.md` |

## References
- `docs/gameplay/02_minerals.md` §5.2 (this wave's pin) + §5.1 Rule A (the
  conservation rules that must keep holding)
- `slices/S13-ore-caps-devmenu/` (S13's rules the splits must not break)

## Carries forward
- LOW ids and gate counts read from the files at write time; the parallel S15
  lane's rows are attributed, never fixed
