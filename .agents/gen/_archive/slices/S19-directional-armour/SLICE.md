---
slice: S19
phase: P2
lane: code
status: active
gate_baseline: "887/0"
---

# S19 — Directional armour & breach malfunctions

## Goal
Ruling 23's hull quadrants go live: hits route by `ctx.direction` into four
armour pools (prow/stern/port/starboard), rear-arc hits bite ×1.6, and an
emptied pool runs its breach malfunction (RCS drift, engine flicker, clipped
turning) until it is repaired. The last owner-ruled mechanic of the flight/
combat core that is specced but unshipped (`18_engine_spec.md` §4.5;
amendment `09_ship_slots_modules.md` §3.3, 2026-09-26).

## In scope
- `vajb-orbit/game/player_state.gd` — the four pools, the routing in
  `damage()`, the `hull` = sum invariant, breach readers
- `vajb-orbit/game/player_ship.gd` — the three malfunction effects (RCS drift
  torque, engine flicker, per-side turn clip)
- `vajb-orbit/game/repairs.gd` — `repair()` restores the pools (fee law
  unchanged)
- `vajb-orbit/ui/station/repairs_panel.gd` — the four per-quadrant report
  lines (18 §4.5's pointer)
- `vajb-orbit/ui/hud/ship_status_screen.gd` — four append-only pool rows
  (P8)
- `vajb-orbit/tests/test_s19_quadrants.gd` — new suite, AC1–AC6

## Out of scope
- `damage.gd` (the `ctx`/`bearing` contract is pinned and stands — forbidden
  file), `npc_ship.gd`, `npc_brain.gd`, `weapons.gd` (forbidden files)
- `NpcShip` hulls (stay flat; P7 staging)
- HUD (`ui/hud/hud.gd`) and the cockpit cluster — frozen contracts
- Any tuning beyond the named consts (balance is deferred per the owner
  2026-09-26; §13 stays owner-locked)

## Acceptance criteria
- [ ] AC1 — routing: `ctx.direction` (signed, `damage.gd:bearing`, `[-PI, PI]`)
      routes each hit to one pool by the P2 quarters (prow `|d| ≤ π/4`, stern
      `|d| ≥ 3π/4`, starboard `π/4 < d < 3π/4`, port the mirror); a missing or
      zero `direction` reads 0.0 → prow. All four arcs proven at their
      interior and both boundary angles.
- [ ] AC2 — stern vulnerability: `|d| ≥ 5π/9` (the pinned 160° rear arc)
      multiplies the incoming amount ×1.6 **before** the shield-first absorb
      (P3); hits outside the arc and direction-less hits are ×1.0.
- [ ] AC3 — pools: four pools of `hull_max / 4` at full repair (P1);
      shield-first absorb with no carry-over unchanged (§4.2 item 1); the
      routed pool absorbs and an emptying hit spills its remainder evenly
      over the other three (P6); **`hull` == sum(pools) at every step**;
      `died` and every existing signal fire exactly as before.
- [ ] AC4 — breach malfunctions (derived: the pool is at 0; lifting it above 0
      ends the effect): stern breach = RCS drift, a random-sign torque of
      `BREACH_RCS_TORQUE` (15 % of the hull's max turn torque, P4) every
      2.0 s; prow breach = engine flicker, 15 % of thrust application ticks
      ignore the thrust (pinned; the roll is seeded/injectable for tests);
      port/starboard breach = the turn rate toward the breached side clipped
      to ×0.5 (P5). A fresh/full fixture never malfunctions.
- [ ] AC5 — repairs & readout: `Repairs.repair()` restores all four pools to
      `hull_max / 4` with the 01 §6 fee law unchanged; the repairs panel's
      damage report lists four per-quadrant lines; the ship status screen
      appends four pool rows (existing rows never move).
- [ ] AC6 — summary: every new const named and tabled with its value and
      reversal in the report; `damage.gd`, `npc_ship.gd`, `npc_brain.gd`,
      `weapons.gd` byte-identical; no existing gate row moved.

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S19-B1 | `vajb-orbit/game/player_state.gd, vajb-orbit/game/player_ship.gd, vajb-orbit/game/repairs.gd, vajb-orbit/ui/station/repairs_panel.gd, vajb-orbit/ui/hud/ship_status_screen.gd, vajb-orbit/tests/, .agents/gen/slices/S19-directional-armour/S19-B1_report.md` | `S19_BRIEF.md` |
| S19-R1 | `vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S19-directional-armour/S19-R1_review.md` | `S19_BRIEF.md` |
| S19-F1 | `vajb-orbit/game/, vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S19-directional-armour/` | `S19_BRIEF.md` |

## References
- `docs/gameplay/09_ship_slots_modules.md` §3.3's **2026-09-26 amendment** —
  this wave's pin (mechanics + P1–P8 + tick list)
- `docs/gameplay/01_economy_core.md` §6's 2026-09-26 amendment (repairs
  panel lines, pool restore)
- `docs/gameplay/18_engine_spec.md` §4.2 item 5 / §4.5 / §2.1 ruling 23
  (read-only; already transcribed into the amendments)
- `docs/CONTRACTS.md` §8.1 (PlayerState pins) and §18 (status screen) — the
  reviewer updates both

## Carries forward
- L212 closed by the planner (02 §5.2 ter "exactly" → "at most"); the S18 MED
  (UI_SPEC §3.10 A3 cell 117×50 → 117×52) closed by the planner. No backlog
  row is absorbed into this wave.
