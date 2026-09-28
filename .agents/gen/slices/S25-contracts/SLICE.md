---
slice: S25
phase: P3
lane: code
status: draft
gate_baseline: "post-S24"
---

# S25 — The contracts board

## Goal
Sessions gain goals: a data-driven job board (Haul, Hunt, Gather, Escort) at
every faction station, rolling on the 20-minute clock, paying over the exchange
and feeding standing. Escort finally gives the convoys a purpose, and the
corridor ambush becomes gameplay.

## In scope
- `game/contract_registry.gd` (new): the 5 types per 14 §2 (Haul/Hunt/Gather/
  Escort live; **Expedition = a seam row** until S26), generation on
  `world_clock.gd:18 (BAND_SECONDS)`, 6 rows per board (R-S25-1), max 3 active
- Escrow + cancel (14 §2 rules): goods locked at accept, 100 CR cancel fee
- Standing gates (12 §4.1 via S24's `contracts_visible` seam) + Known +5 %
  pay hook + Champion's standing-order contract
- Escort loop (14 §6): the convoy spawns at the accepting station (1 hauler AI +
  1–2 fighters, Hauler stats, 50 % visible cargo pods), fixed route to the
  target gate at freighter speed, pirates ambush at the corridor midpoint, win/
  lose rules (−5 standing on loss)
- Persistence: `autoload/player_profile.gd:1724 (contracts())` + the
  `:2545-2548` keys; completion pays into the profile
- The CONTRACTS panel per `slices/D16-station-ui/D16-A1_report.md`'s spec
  (fallback: the armory/auction row idioms under UI_SPEC §3.10 A5)
- `tests/test_s25_contracts.gd` — new suite (A1–A7)

## Out of scope
- Expedition/arena contracts (S26's arenas), insurance/vaults (S26)
- Story text/flavour beyond the objective strings 14 §2's examples imply
- Any art (owner 2026-09-27)

## Acceptance criteria
See `S25_BRIEF.md` §6 (A1–A7), each probe- or gate-provable.

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S25-B1 | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/autoload/player_profile.gd, vajb-orbit/tests/, .agents/gen/slices/S25-contracts/S25-B1_report.md` | `S25_BRIEF.md` |
| S25-R1 | `vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S25-contracts/S25-R1_review.md` | `S25_BRIEF.md` |
| S25-F1 | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/autoload/player_profile.gd, vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S25-contracts/` | `S25_BRIEF.md` |

## References
- `docs/gameplay/14_station_services.md` §2/§6/§9 (the pin) + **2026-09-27 P3
  block** (R-S25-1, tick J1)
- `docs/gameplay/12_factions.md` §4.1 (gates/pay bands) · `11_galactic_map.md`
  §2.2 (corridor ambush) · `08_ship_classes.md` §2 (Hauler convoy stats)
- `slices/D16-station-ui/D16-A1_report.md` — the panel spec (design law)
- `docs/CONTRACTS.md` §9/§10 — R1 updates

## Carries forward
- Expedition = `contract_registry`'s seam row (S26 flips it live with the
  arenas). The Champion standing-order contract rides A3's hook.
