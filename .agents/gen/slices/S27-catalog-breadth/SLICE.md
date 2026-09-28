---
slice: S27
phase: P3
lane: code
status: draft
gate_baseline: "post-S26"
---

# S27 — Catalog breadth & the shipyard

## Goal
The catalogue layers thicken on every axis the docs already shape: more affixes
with perks that finally fire, tier variants of existing modules, per-archetype
loot tables for the new enemies, and the shipyard build path (materials + labour
+ queue + scrap) that gives miners a second sink and every hull a cheap door.

## In scope
- Affixes (R-S27-2/3): `game/module_catalog.gd:127-250 (PREFIXES/SUFFIXES)` —
  +4 prefixes, +3 suffixes; every suffix perk wired at the §20 aggregation seam
  (`game/affixes.gd`); the "displayed, never applied" note dies
- Variants (R-S27-1): `<base>_mk2` rows per the `p_mk2` precedent
  (`module_catalog.gd:252-610`), priced by 10 §3.2's shape rule
- Loot: per-archetype tables for `interceptor`, `turret`, `sibelon` and the
  boss rows (`game/loot_tables.gd:102-108 (TABLES)`), 06 §3's line format
- Shipyard (10 §3): `game/shipyard.gd` (new) — hull recipes per §3.1's rows,
  module builds per §3.2's shape rule, the §3.3 queue (one at a time, one
  in-space session, committed at queue, full refund on cancel, persists) and
  the §3.3 scrap path (50 % of recipe materials); the SHIPYARD panel gains the
  build/queue/scrap views (the hangar view already exists)
- `tests/test_s27_catalog.gd` — new suite (A1–A6)

## Out of scope
- New faction exclusives (15 §5 stands at three); signature unique drops (06 §7
  defers them to a 07 amendment); crafting beyond the shipyard's shape rule
- Any art (owner 2026-09-27)

## Acceptance criteria
See `S27_BRIEF.md` §6 (A1–A6), each probe- or gate-provable.

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S27-B1 | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/autoload/player_profile.gd, vajb-orbit/tests/, .agents/gen/slices/S27-catalog-breadth/S27-B1_report.md` | `S27_BRIEF.md` |
| S27-R1 | `vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S27-catalog-breadth/S27-R1_review.md` | `S27_BRIEF.md` |
| S27-F1 | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/autoload/player_profile.gd, vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S27-catalog-breadth/` | `S27_BRIEF.md` |

## References
- `docs/gameplay/15_module_affixes.md` §1/§3/§4/§20 + **2026-09-27 P3 block**
  (R-S27-2/3, ticks K2/K3) · `09_ship_slots_modules.md` **2026-09-27 P3 block**
  (R-S27-1, tick K1)
- `docs/gameplay/10_ship_acquisition.md` §3 (the shipyard pin) ·
  `06_loot_drops.md` §3 (line format) · `03_components.md` §3 (family mapping)
- `docs/CONTRACTS.md` §20 (aggregation law) — R1 updates §9/§10

## Carries forward
- Signature unique drops and crafting (07) stay design-preview; new exclusives
  wait for faction stations' vendor story.
