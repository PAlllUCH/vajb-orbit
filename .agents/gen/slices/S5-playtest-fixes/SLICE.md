---
slice: S5
phase: P2
lane: code
status: draft
gate_baseline: "524/0 (S4 close-out)"
---

# S5 — Playtest fixes (the owner's ten findings, 2026-09-23)

## Goal
The station reads the way the owner plays: auction shelves split by family, a
shipyard that is a hangar (preview → SET ACTIVE), an `ARMORY` where weapon
batteries are drag-and-drop mixed groups firing at the slowest member's rate,
consumables living in cargo and sellable, no fuel cells for sale — and in flight
every hull maps its thruster and weapon hardpoints so shots and engine FX come
from real positions at per-weapon tracking speeds.

## In scope
- Auction family tabs; shipyard hangar + preview + `SET ACTIVE` — STATION_HUB §5.11
- `ARMORY` rename + drag-and-drop mixed batteries + slowest-cycle salvo gate — 09 §11
- Ammunition as cargo (`ammo_*`, auto-load at launch, EXCHANGE sell) + fuel-cell delist — 10 §6.1
- `ShipFit.HARDPOINTS` per hull (thrusters + weapon mounts) + per-barrel `track_dps` — 09 §11

## Out of scope
- The shipyard BUILD queue (10 §3 stays spec'd for its own wave)
- Countermeasure packs in cargo ("etc." staged)
- Painted-only rail icons (designer lane — `dispatch_designer.md`)
- `project.godot` (the `weapon_6`/`weapon_7` rows are orchestrator-applied at close-out)

## Acceptance criteria
- [ ] AC1 — the auction's family tabs show the same 6+10 draw grouped; weights, hot
      slot and prices byte-identical to S3's
- [ ] AC2 — the shipyard lists owned hulls only; selection writes nothing; `SET ACTIVE`
      is the sole commit (probe: `fits()`/`active_ship` unchanged on select)
- [ ] AC3 — `ARMORY` composes mixed batteries by drag & drop; a salvo of a
      laser+cannon battery fires both barrels and the next salvo waits for the
      slowest member's cycle (measured: a 0.6 s + 1.5 s pair cycles at 1.5 s)
- [ ] AC4 — ammo bought lands in cargo at `ROUNDS_PER_CARGO_UNIT 10`; launch auto-fills
      packs from cargo; EXCHANGE sells units at 60 %; no surface sells fuel cells
- [ ] AC5 — all nine hulls carry measured hardpoint maps in 09 §11's table; thrust/
      brake/strafe FX read the right anchors and shots spawn at their mount
- [ ] AC6 — barrels track at their `track_dps` (a 60°/s barrel visibly lags a 180°/s
      one in a mixed battery); beams connect within `TRACK_TOLERANCE 5°`
- [ ] AC7 — gate holds green with the S5 suites (measured number into CONTRACTS §9)

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S5-J0 | `docs/,vajb-orbit/tests/,vajb-orbit/tools/` | `S5_BRIEF.md` |
| S5-J1 | `vajb-orbit/ui/station/auction_panel.{gd,tscn},vajb-orbit/ui/station/shipyard_panel.{gd,tscn},vajb-orbit/ui/screens/station.gd,vajb-orbit/tests/` | `S5_BRIEF.md` |
| S5-J2 | `vajb-orbit/game/module_catalog.gd,vajb-orbit/game/game.gd,vajb-orbit/autoload/player_profile.gd,vajb-orbit/ui/station/exchange_panel.{gd,tscn},vajb-orbit/tests/` | `S5_BRIEF.md` |
| S5-J3 | `vajb-orbit/ui/station/outfitting_panel.{gd,tscn},vajb-orbit/ui/station/armory_panel.{gd,tscn},vajb-orbit/autoload/player_profile.gd,vajb-orbit/game/weapons.gd,vajb-orbit/tests/` | `S5_BRIEF.md` |
| S5-J4 | `vajb-orbit/game/ship_fit.gd,vajb-orbit/game/player_ship.gd,vajb-orbit/game/weapons.gd,vajb-orbit/game/projectile.gd,vajb-orbit/game/mining_laser.gd,vajb-orbit/tests/` | `S5_BRIEF.md` |
| S5-R1 | `vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md` | reviewer |
| S5-F1 | the union of J1–J4 sets + `docs/CONTRACTS.md` | fixer, only on HIGH/MED |

## References
- `docs/CONTRACTS.md` §17 (this wave's pin), §13/§16 (the transactions it wraps)
- `docs/design/STATION_HUB.md` §5.11 (+ §5.1/§5.2/§5.8/§5.10)
- `docs/gameplay/10_ship_acquisition.md` §6.1 (+ §2/§3)
- `docs/gameplay/09_ship_slots_modules.md` §11 (+ §3.1 `track_dps`, §8 superseded)

## Carries forward
- The `weapon_6`/`weapon_7` input-map rows — orchestrator-applied at close-out (CONTRACTS §1)
- Countermeasure packs in cargo (staged out of 10 §6.1)
- The build queue (10 §3) waits for its own wave
