---
slice: S39
phase: P3
lane: code            # code | design
status: active        # draft | active | review | done
gate_baseline: "1258/0"
---

# S39 — Flight feel, hostile fire and cargo (owner playtest #2)

## Goal
Answer the owner's second live playtest: enemies that shoot back, a flight model
whose reversal and boost read as thrust, a convoy that holds its route, hits that
nudge instead of throw, and a cargo hold the player can actually see.

## In scope
- **T-164** — hostile NPCs fire on their target (18 §5's Engage; the brain's
  `INTENT_FIRE` gains a consumer).
- **T-165** — a 180° reversal accelerates faster than the class rate (18 §3.2).
- **T-166** — a lit boost adds thrust, not only a speed ceiling (18 §3.2).
- **T-167** — Shift is a baseline boost; afterburner/other thrust modules stack
  on top of it (18 §3.2, §13's `boost` row).
- **T-168** — a route-following hull recovers its leg after a deflection (18 §5).
- **T-169** — weapon knockback is reduced so a hit nudges (18 §4.2 item 7).
- **T-170** — the hold's contents and `used/max` are visible in flight and at the
  station's armory.

## Out of scope
- New weapon families or boss-weapon mechanics beyond a hostile hull's gun.
- The catalogue breadth of S27 (queued behind this wave).
- Any re-key of art or audio; no new assets.

## Acceptance criteria
- [ ] AC1 — an engaged hostile hull fires a projectile at its target, and a
  disengaged/neutral one does not.
- [ ] AC2 — a commanded reversal changes the velocity's sign in less than
  2 × `accel_time` on a shipped hull.
- [ ] AC3 — a lit boost raises the commanded acceleration, not only `max_speed`.
- [ ] AC4 — with no afterburner fitted, Shift still raises speed (and thrust).
- [ ] AC5 — a convoy hull deflected off its leg re-acquires the leg and reaches
  the gate; it does not stall at zero speed with the waypoint behind it.
- [ ] AC6 — a shot's knockback Δv is measurably below the pre-wave figure.
- [ ] AC7 — the hold's contents and `used/max` render in flight and in the armory.

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S39-B1 | `game/npc_ship.gd, game/npc_registry.gd, game/npc_brain.gd, game/player_ship.gd, game/impact.gd, game/projectile.gd, game/damage.gd, ui/hud/hud.gd, ui/station/armory_panel.gd, tests/` | `S39_BRIEF.md` |

## References
- `docs/gameplay/18_engine_spec.md` §3.2 (inertia model), §4.2 items 6–8 (push
  physics), §5 (NPC archetypes), §13 (calibration rows).
- `docs/CONTRACTS.md` §10 (changelog), §14 (runner sandbox), §20 (ship stat
  affixes), §28 (S26).
- `docs/design/UI_SPEC.md` §3.7 (the retired old HUD column).

## Carries forward
- `T-164`–`T-170`, all filed 2026-10-10 from the owner's playtest #2.
