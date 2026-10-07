---
slice: S23
phase: P3
lane: code
status: draft
gate_baseline: "post-S22"
---

# S23 — Content activation (the dead-content wave)

## Goal
Everything already built and shipped starts working: `w_proton`/`w_flak` fire,
`c_ewar`/`u_refine`/`u_drones` carry real effects, all nine hulls launch with
role fits, the sibelon seam releases, `ship_interceptor`/`ship_turret_platform`
become real hulls, hunters fly their own skins, and every hull flies its own
sprite. Zero new art — the shipped library covers all of it.

## In scope
- Weapon families (R-S23-1/2): `game/weapons.gd:99-169 (FAMILIES)`,
  `game/station_catalog.gd:31-85 (AMMO_PACKS)` — `ammo_proton`/`ammo_flak`
- Dead modules (09 §3.4/§3.6 rows): `game/module_catalog.gd:438,498,508`
  (`effects: {}` dies) + consumers in `game/game.gd`, `game/refinery.gd:30`,
  `game/mining_laser.gd`/regen seam
- Stock fits (R-S23-3): `game/ship_fit.gd:544-587 (STANDARD_FITS)` for the 7
  starter-less hulls
- Enemy hulls (R-S23-4/5): `game/ship_fit.gd:300-382 (HULLS)` gains
  `ship_interceptor` + `ship_turret_platform`; `game/npc_registry.gd:362`
  (hunter) and `:328` (turret) resolve
- Sibelon seam (ruling 24): `game/npc_registry.gd:179-180 (SEAM_SLICE_3)` row
  complete and spawnable (loot + brain verified)
- Turrets at stations (R-S23-6, tick C6 — the 13 §5 reversal): the `turret`
  archetype mounts per station with the +25 heat/aggro law
- Per-hull flight sprites + liveries (L137): `game/player_ship.tscn:12-13`,
  `game/player_ship.gd:408-479` — per-hull sprite + per-hull collider radius +
  FX anchors scaling off the drawn hull's map; choir/concord/meridian fighter
  sheets on hunters/pirates; `ship_vanguard_damaged` in REPAIRS/LAUNCH
- Loot (06 §3.1/§7): `game/loot_tables.gd` — `cm_chaff`/`cm_flare` catalog
  rows (`component_catalog.gd`) so `uncatalogued_items():250` returns empty,
  `HUNTER_EXTRA:117` promoted to a `hunter` table, tier-scaled caches ×1/×1.5/×2
- Asset pipeline: cuts move via a new `staging/roster/` driver + `pull.py` +
  `validate_names.py --library` (pipeline law in AGENTS.md)
- `tests/test_s23_content.gd` — new suite (A1–A7)

## Out of scope
- The per-sector hostile bands (`HOSTILE_FILL` replacement) — S24's R-S24-2
- `u_vault`'s consumer (lands with the vaults in S26)
- New art of any kind (owner 2026-09-27); the leviathan/spire/thorn bosses
- Faction livery expansion beyond the three shipped fighter sheets + MMO sets
- Balance beyond the rows in the 2026-09-27 P3 blocks

## Acceptance criteria
See `S23_BRIEF.md` §6 (A1–A7), each probe- or gate-provable.

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S23-B1 | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/tests/, vajb-orbit/assets/, staging/roster/, .agents/gen/slices/S23-content-activation/S23-B1_report.md` | `S23_BRIEF.md` |
| S23-R1 | `vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S23-content-activation/S23-R1_review.md` | `S23_BRIEF.md` |
| S23-F1 | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/tests/, vajb-orbit/assets/, staging/roster/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S23-content-activation/` | `S23_BRIEF.md` |

## References
- `docs/gameplay/09_ship_slots_modules.md` §3.1/§3.4/§3.6/§7 + **2026-09-27 P3
  block** (R-S23-1/2/3, ticks C1/C2/C3)
- `docs/gameplay/08_ship_classes.md` §2/§4 + **2026-09-27 P3 block**
  (R-S23-4/5/6, ticks C4/C5/C6)
- `docs/gameplay/15_module_affixes.md` §5 (exclusives) · `06_loot_drops.md`
  §3.1/§7 · `18_engine_spec.md` §2.1 ruling 24 (read-only)
- `docs/design/ASSET_CATALOG.md` (the sprite inventory: interceptor, turret
  platform, sibelon, faction/MMO liveries, damaged Vanguard)
- `docs/design/ASSET_WIRING_HANDOFF.md` + AGENTS.md asset rules (pipeline law)

## Carries forward
- L48's mine cue closed in S22; L137 closes here (its row cites this wave).
- `HOSTILE_FILL` stays global until S24; `u_vault` waits for S26's vaults.
