---
slice: S24
phase: P3
lane: code
status: draft
gate_baseline: "post-S23"
---

# S24 — World identity (stations, factions, nebula)

## Goal
The nine docking places become nine *places*: named stations with per-faction
service menus, price flavours and shelf bias; faction standing starts gating
docking, prices and perks; each sector carries its own hostile band; and
nebula clouds finally tint and blind. The map stops being one room copied
seven times.

## In scope
- Station entities: `game/station_catalog.gd:25 (no per-station structure — this
  wave adds one)`, `game/station_scene.gd:128`, `ui/screens/station.gd` — names
  and character per R-S24-1, service matrix per 14 §1/§8, faction ownership per
  sector
- Faction flavour: `game/exchange.gd:51` (Meridian's 1.5 % commission), the
  12 §3 demand biases, 12 §5's −15 % tech discounts, 12 §2's shelf bias
- Standing effects (12 §4.1's band table): dock refusal (≤ −51, two-axis rule
  13 §7 unchanged), price ±10/5 %, contract visibility (a seam S25 reads),
  auction perks (Known ×1.5 hot slot; Trusted reserved slot)
- Hostile bands (R-S24-2): `game/npc_registry.gd:89 (HOSTILE_FILL)` becomes
  per-sector; densities stay 13 §4's
- Nebula (R-S24-3, ruling 25): 0–2 clouds per sector (`sector_registry.gd:40-50`),
  radar/lock ×0.5 + 15 % tint while inside
- `tests/test_s24_world.gd` — new suite (A1–A5)

## Out of scope
- Contracts, insurance, vaults (S25/S26) — S24 only exposes the seams they read
- Turrets (S23's tick C6), bosses (S26), `HOSTILE_FILL`'s hunter pressure logic
  (stays heat-driven per 13 §3)
- Any art (owner 2026-09-27): station identity is names + existing chrome only
  (the D16 treatment is the design law when it exists)

## Acceptance criteria
See `S24_BRIEF.md` §6 (A1–A5), each probe- or gate-provable.

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S24-B1 | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/tests/, .agents/gen/slices/S24-world-identity/S24-B1_report.md` | `S24_BRIEF.md` |
| S24-R1 | `vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S24-world-identity/S24-R1_review.md` | `S24_BRIEF.md` |
| S24-F1 | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S24-world-identity/` | `S24_BRIEF.md` |

## References
- `docs/gameplay/14_station_services.md` §1/§8 + **2026-09-27 P3 block**
  (R-S24-1's name table, tick W3)
- `docs/gameplay/12_factions.md` §2/§3/§4.1/§5 (the flavour + band law)
- `docs/gameplay/13_heat_bounty.md` §4/§7 + **2026-09-27 P3 block** (R-S24-2,
  tick W1) · `docs/gameplay/11_galactic_map.md` §1/§3 + **2026-09-27 P3 block**
  (R-S24-3, tick W2)
- `docs/gameplay/18_engine_spec.md` §2.1 ruling 25 (read-only)
- `slices/D16-station-ui/D16-A1_report.md` — the station identity treatment
  (read when it exists; otherwise names + existing chrome only)

## Carries forward
- S25 consumes the contract-visibility seam and the station screen; S26 consumes
  the standing band's insurance ×0.8 row and `u_vault`'s faction exception.
