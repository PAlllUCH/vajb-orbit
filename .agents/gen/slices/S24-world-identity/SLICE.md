---
slice: S24
phase: P3
lane: code
status: ready
gate_baseline: "1152/0 (measured 2026-10-08, item 30's re-cut)"
---

# S24 — World identity (stations, factions, standing, bands, nebula)

## Goal
The nine docking places become nine *places*: named stations with per-faction
service matrices, price flavours and shelf bias; faction standing starts gating
prices, contracts, the auction and the insurance seam; each sector carries its own
hostile band; and nebula clouds finally tint and blind. The map stops being one
room copied seven times.

## In scope
- The station entity: **new** `game/station_registry.gd` (nine rows, per
  `14_station_services.md`'s 2026-10-08 block) + the docked-station seam on
  `autoload/player_profile.gd` + `game/game.gd`'s dock filing; the shell header's
  plate text (`ui/screens/station.gd`, `ui/screens/station.tscn`'s placeholder
  strings retire); OVERVIEW block 4's availability state + the vault record read
  (`ui/station/overview_panel.gd`)
- The price law (12's V1/V2/V6 rows): `game/repairs.gd`'s fee, the ammo pack and
  hull prices (`game/station_catalog.gd`'s readers), the Meridian 1.5 % commission
  (`game/exchange.gd`), the module price factor at `ui/station/armory_panel.gd` /
  `ui/station/fitting_panel.gd`
- Standing effects (12 §4.1 + V3/V4/V5/V7): `contracts_visible`, the auction's
  hot-slot pair and the reserved tier slot, the insurance multiplier seam
- Hostile bands (R-S24-2 + 13's 2026-10-08 block): `game/sector_registry.gd`'s row
  gains `hostile_band`; `game/npc_registry.gd`'s global `HOSTILE_FILL` retires as
  the source
- Nebula (R-S24-3 + 11's 2026-10-08 block): the sector row's `clouds`, the cloud
  node in `game/sector.gd`, the three ×0.5 readings + the 15 % tint in
  `game/game.gd`
- `tests/test_s24_world.gd` (B1) and `tests/test_s24_bands.gd` (B2)

## Out of scope
- Contracts, insurance, vaults panels (S25/S26) — S24 exposes the seams they read
- Outpost **nodes** (the three outpost rows are data + tests only; spawning them is
  the staged per-station POI-flavour item)
- Turrets (S23's tick C6), bosses (S26), the SERVICES pane's §15.2–§15.4 panels
- Any art (owner 2026-09-27): identity is names + existing chrome only

## Acceptance criteria
See `S24_BRIEF.md` §6 (A1–A6), each probe- or gate-provable.

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S24-B1 | `vajb-orbit/game/station_registry.gd, vajb-orbit/game/station_catalog.gd, vajb-orbit/game/repairs.gd, vajb-orbit/game/exchange.gd, vajb-orbit/game/game.gd, vajb-orbit/autoload/player_profile.gd, vajb-orbit/ui/screens/station.gd, vajb-orbit/ui/station/overview_panel.gd, vajb-orbit/ui/station/launch_panel.gd, vajb-orbit/ui/station/armory_panel.gd, vajb-orbit/ui/station/fitting_panel.gd, vajb-orbit/tests/test_s24_world.gd, .agents/gen/slices/S24-world-identity/S24-B1_report.md` | `S24_BRIEF.md` |
| S24-B2 | `vajb-orbit/game/sector_registry.gd, vajb-orbit/game/sector.gd, vajb-orbit/game/npc_registry.gd, vajb-orbit/game/auction.gd, vajb-orbit/game/game.gd, vajb-orbit/ui/station/auction_panel.gd, vajb-orbit/tests/test_s24_bands.gd, .agents/gen/slices/S24-world-identity/S24-B2_report.md` | `S24_BRIEF.md` |
| S24-R1 | `vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S24-world-identity/S24-R1_review.md` | `S24_BRIEF.md` |
| S24-F1 | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/autoload/, vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S24-world-identity/` | `S24_BRIEF.md` |

B1 and B2 both hold `vajb-orbit/game/game.gd` and run **strictly in order** (B1
first; B2 re-reads the file) — one live builder at a time.

## References
- `docs/gameplay/14_station_services.md` §1/§8 + **2026-09-27 P3 block** (R-S24-1)
  + **2026-10-08 block** (the nine rows, the seam, the plate landing)
- `docs/gameplay/12_factions.md` §2/§3/§4.1/§5 + **2026-10-08 block** (V1–V7)
- `docs/gameplay/13_heat_bounty.md` §4/§7 + **2026-09-27 P3 block** (R-S24-2) +
  **2026-10-08 block** (the band moves to the row)
- `docs/gameplay/11_galactic_map.md` §1/§3 + **2026-09-27 P3 block** (R-S24-3) +
  **2026-10-08 block** (V8: the cloud rows, the three readings)
- `docs/design/STATION_HUB.md` §15.5 (+ its 2026-10-08 landing note), §19.1/§19.4
  (OVERVIEW block 4, the SERVICES pane); `docs/design/UI_SPEC.md` §12.4 (the
  header plate row)
- `docs/gameplay/18_engine_spec.md` §2.1 ruling 25 (read-only)

## Carries forward
- S25 consumes `contracts_visible` and the SERVICES pane; S26 consumes
  `insurance_multiplier` and `u_vault`'s faction exception.
