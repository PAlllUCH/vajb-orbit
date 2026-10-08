---
slice: S25
phase: P3
lane: code
status: ready
gate_baseline: "post-S28 (1202/0)"
re-cut: "2026-10-08 — against the shipped shell (S24 + S28 + S30–S37); every
cite re-measured; the reward extract re-cut against 14's 2026-10-08 S28 block;
the panel law re-pointed to STATION_HUB §15.2 (U3–U8)."
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
- **S28's payout scaling (M11, ratified)**: every flat reward scales
  ×SC(t)/SC(1) by the target sector's tier (Hunt 800/1 100/2 200/4 400;
  Escort 1 200/1 600/3 300/6 500; Haul's flat 300/400/800/1 600 derived),
  rounded to 100 CR
- Escrow + cancel (14 §2 rules): goods locked at accept, 100 CR cancel fee
- Standing gates (12 §4.1 via S24's `contracts_visible` seam,
  `game/station_registry.gd:417`) + Known +5 % pay hook + Champion's
  standing-order contract
- Escort loop (14 §6): the convoy spawns at the accepting station (1 hauler AI +
  1–2 fighters, Hauler stats, 50 % visible cargo pods), fixed route to the
  target gate at freighter speed, pirates ambush at the corridor midpoint, win/
  lose rules (−5 standing on loss)
- Persistence: `autoload/player_profile.gd:1914 (contracts())`, `:2195` (read),
  `:2801` (save); completion pays into the profile
- The CONTRACTS panel per `docs/design/STATION_HUB.md` §15.2 (the deck law,
  U3–U8), wired into the SERVICES deck in place of `ui/screens/station.gd:940`'s
  `MODULE OFFLINE` placeholder (**T-138**)
- Riders: **T-152** (`ui/station/launch_panel.gd:53` reads the docked sector's
  own name) and **T-154** (`game/refinery.gd:129-130` stale fee example,
  comment-only)
- `tests/test_s25_contracts.gd` — new suite (A1–A8)

## Out of scope
- Expedition/arena contracts (S26's arenas), insurance/vaults (S26)
- Story text/flavour beyond the objective strings 14 §2's examples imply
- Any art (owner 2026-09-27): the `icon_contract_*` icons ship

## Acceptance criteria
See `S25_BRIEF.md` §6 (A1–A8), each probe- or gate-provable.

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S25-B1 | `vajb-orbit/game/contract_registry.gd, vajb-orbit/game/contract_registry.gd.uid, vajb-orbit/game/game.gd, vajb-orbit/game/npc_registry.gd, vajb-orbit/game/refinery.gd, vajb-orbit/autoload/player_profile.gd, vajb-orbit/ui/station/contracts_panel.gd, vajb-orbit/ui/station/contracts_panel.gd.uid, vajb-orbit/ui/station/contracts_panel.tscn, vajb-orbit/ui/screens/station.gd, vajb-orbit/ui/station/launch_panel.gd, vajb-orbit/tests/test_s25_contracts.gd, .agents/gen/slices/S25-contracts/S25-B1_report.md` | `S25_BRIEF.md` |
| S25-R1 | `vajb-orbit/tests/, docs/CONTRACTS.md, .agents/gen/slices/S25-contracts/S25-R1_review.md` | `S25_BRIEF.md` |
| S25-F1 | B1's set + `vajb-orbit/tests/, docs/CONTRACTS.md, .agents/gen/slices/S25-contracts/` | `S25_BRIEF.md` |

Read-only (never in a set): `game/exchange.gd`, `game/sector_registry.gd`,
`game/station_registry.gd`, `game/mineral_catalog.gd`,
`autoload/world_clock.gd`, `docs/`.

## References
- `docs/gameplay/14_station_services.md` §2/§6/§9 (the pin) + **2026-09-27 P3
  block** (R-S25-1, tick J1) + **2026-10-08 S28 block** (the payout scaling)
- `docs/gameplay/01_economy_core.md` 2026-10-08 S28 block (SC(t) = 1 100 /
  1 500 / 3 000 / 6 000)
- `docs/gameplay/12_factions.md` §3/§4.1 (gates/pay bands) + its **2026-10-08
  S24 block** (V3's `contracts_visible`) · `11_galactic_map.md` §2.2 (corridor
  ambush) · `08_ship_classes.md` §2 (Hauler convoy stats)
- `docs/design/STATION_HUB.md` §15.2 (the CONTRACTS panel law, U3–U8) + §5.2
  (the confirm dialog) · `docs/design/UI_SPEC.md` §12–§15 and STATION_HUB
  §19–§21 (shell v2, by range)
- `docs/CONTRACTS.md` §9/§10 — R1 updates

## Carries forward
- Expedition = `contract_registry`'s seam row (S26 flips it live with the
  arenas). The Champion standing-order contract rides A3's hook.
- T-138/T-152 close with this wave if the review passes them clean; T-154's
  comment fix lands with B1.
