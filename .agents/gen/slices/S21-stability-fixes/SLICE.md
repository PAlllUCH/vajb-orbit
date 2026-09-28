---
slice: S21
phase: P3
lane: code
status: draft
gate_baseline: "914/0"
---

# S21 — Stability & playtest fixes

## Goal
A playtest run meets no wrong-money, death-loop or silent-refusal bug: the hull
has a real death state, the wreck window survives transitions, ships collide
with ships per 18 §2.1, and the gate reads the same count on any `user://`.
Everything restores already-pinned behaviour except three proposed rows
(R-S21-1..3).

## In scope
- Death/respawn/wreck: `game/game.gd:2522,2560,2595,2630`, `player_ship.gd:1568`,
  `game/pickup.gd:31,100` (the `Pickup.setup` lifetime seam, L23)
- Crash damage: the contact handlers (`player_ship.gd:472-492`,
  `npc_ship.gd:538-548`) + hull-vs-hull pairing (L22, 18 §2.1 rows 15-16)
- Profile hygiene (L18/L122/L154/L229-class): `ui/screens/station.gd`,
  `ui/station/auction_panel.gd:145-171`, `game/game.gd:215,329-335,832-840`,
  `autoload/player_profile.gd`
- Hermetic fixtures (L90/L93): `tests/test_engine2_dock.gd:31,204`,
  `tests/test_engine2_fixes.gd`, `tests/test_engine2_wiring.gd:243-246`
- Instance-bag reads (L110/L124): `autoload/player_profile.gd:362-374`,
  `ui/station/outfitting_panel.gd:823,1295`
- Money edges (L130/L131/L136): `game/exchange.gd:376-388`,
  `autoload/player_profile.gd:350-375`, `ui/station/launch_panel.gd:523-533`
- World-sim (L73/L150/L152/L153/L215/L176): `game/asteroid_field.gd:153,212,444`,
  `game/asteroid.gd:247,289`, `game/game.gd:168,307-309`, `game/gate.gd:142-165`,
  `ui/station/armory_panel.gd:2051`
- Harness (L61/L237/L243): `tests/test_weapon_fx_f4.gd:172-179`, one assert row
  in `tests/test_s19_quadrants.gd`
- `tests/test_s21_stability.gd` — new suite (A1–A10)

## Out of scope
- `game/damage.gd` (the ctx/bearing contract stands byte-identical; the two
  `CTX_DIRECTION` consts are only *asserted* equal)
- `game/weapons.gd`, `game/projectile.gd`, flight constants in
  `player_ship.gd` (S22's), repairs pricing (`game/repairs.gd` = S22's R-S22-1)
- All `docs/` (read-only; R1 owns `CONTRACTS.md`)
- The T-93 systemic `_write_profile` guard (owner-gated — the hook is the write
  guard)

## Acceptance criteria
See `S21_BRIEF.md` §6 (A1–A10), each probe- or gate-provable.

## Worker file sets
The builder is split in three (owner-ruled 2026-09-28, `S21_BRIEF.md` §7): same
`VAJB_WORKER_FILES`, disjoint regions, strictly sequential. `S21-B1` carries
A1/A2/A3/A4b/A9a/A9b, `S21-B2` A4a/A5/A6/A7/A8, `S21-B3` A9c/A9d/A10/A11.

| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S21-B1 | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/autoload/player_profile.gd, vajb-orbit/tests/, .agents/gen/slices/S21-stability-fixes/S21-B1_report.md` | `S21_BRIEF.md` |
| S21-B2 | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/autoload/player_profile.gd, vajb-orbit/tests/, .agents/gen/slices/S21-stability-fixes/S21-B2_report.md` | `S21_BRIEF.md` |
| S21-B3 | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/autoload/player_profile.gd, vajb-orbit/tests/, .agents/gen/slices/S21-stability-fixes/S21-B3_report.md` | `S21_BRIEF.md` |
| S21-R1 | `vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S21-stability-fixes/S21-R1_review.md` | `S21_BRIEF.md` |
| S21-F1 | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/autoload/player_profile.gd, vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S21-stability-fixes/` | `S21_BRIEF.md` |

## References
- `docs/gameplay/18_engine_spec.md` §2 dec. 7, §2.1 rows 15-16, §7 (read-only)
- `docs/gameplay/11_galactic_map.md` §2 · `13_heat_bounty.md` §2–§3 ·
  `05_exchange.md` §5 · `01_economy_core.md` §3/§4 · `10_ship_acquisition.md` §2
- `docs/gameplay/01_economy_core.md` + `10_ship_acquisition.md` **2026-09-27
  P3 blocks** (R-S21-1..3 with ticks M2/M3/M1)
- `docs/CONTRACTS.md` §9/§10/§14 — R1 updates §9/§10

## Carries forward
- L22 resolves by enforcing 18 §2.1's existing row-15 formula (no new number).
- L114's row shows an `OWNED` plate only if tick **M1** confirms; unticked it
  implements at the PROPOSED value (S19 precedent).
- L168/L169/L242/L244 ride S22 (ticks M4/M5/M7); L57 rides D15.
