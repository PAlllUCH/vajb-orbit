---
slice: S16
phase: P2
lane: code
status: active
gate_baseline: "859/0"
---

# S16 — Fragment re-splits (debris keeps splitting)

## Goal

A rock born of a split splits again per its own size class — shot debris
reads as debris through the whole chain, not a one-step pop.

## In scope

- The cleave gate: fragments cleave per size class regardless of bore
  (02 §5.2 ter); originals keep ruling 17's yield-0 law.
- 02 §5.2's split table, yields, conservation and the gun cap stay exactly
  as shipped (02 §5.2 ter pins the invariants).

## Out of scope

- No split-table or spawn-mix change (`OreTuning` untouched; Rule B stays
  deferred; the measured spawn mix 37.6/34.5/20.7/7.2 stands until the owner
  ticks).
- No dev-overlay change (no new tunable).
- The frozen `probe_rock_cleave*.gd` rows stay frozen (L202 owns them).
- No break-read, FX, sound or shockwave change (`_break_read` is
  unconditional and stays so).

## Acceptance criteria

- [ ] AC1 — a gun shatter's child cleaves per its own class: seeded, a shot
      XL's L/M/S children split into strictly smaller children; the chain
      reaches S and stops (S's cleave is the burst).
- [ ] AC2 — a 0-bore fragment pays nothing: every shatter in a shot chain
      pays 0 units and no pickup spawns from owed 0.
- [ ] AC3 — conservation holds on both routes: a fully shot family realises
      at most `GUN_BURST_SHARE × root _bore_ore + 1`; a fully mined family
      stays at root `_bore_ore ± 1` (S14's AC3 row stays green untouched).
- [ ] AC4 — a yield-0 ORIGINAL still cleaves into nothing (ruling 17 for
      originals; only rocks born of a cleave are marked).
- [ ] AC5 — every chain terminates: strictly smaller children; a fully shot
      XL leaves no live family rock.
- [ ] AC6 — the gate `[SUMMARY]` at baseline + the new suite's rows, twice,
      hermetic, zero failures.

## Worker file sets

| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S16-B1 | `vajb-orbit/game/asteroid.gd, vajb-orbit/game/asteroid_field.gd, vajb-orbit/tests/, .agents/gen/slices/S16-fragment-resplit/S16-B1_report.md` | `S16_BRIEF.md` |
| S16-R1 | `vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S16-fragment-resplit/S16-R1_review.md` | `S16_BRIEF.md` |
| S16-F1 | `vajb-orbit/game/, vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S16-fragment-resplit/` | `S16_BRIEF.md` |

## References

- `docs/gameplay/02_minerals.md` §5.2 ter (this wave's pin) + §5.2 (the
  table) + §5.1 Rule A (conservation); `01_economy_core.md` §5.6 (shooting
  never out-earns mining).
- `docs/CONTRACTS.md` §5 (the Asteroid seam; R1 lands the `cleaves` pin's new
  sentence there with the next free §9/§10 rows).

## Carries forward

- None. No ticket absorbed; L202's frozen probe rows stay frozen and owned
  by their named next owner.
