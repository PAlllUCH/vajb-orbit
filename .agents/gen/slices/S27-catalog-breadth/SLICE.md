---
slice: S27
phase: P3
lane: code
status: ready
gate_baseline: "post-S26 (record the measured count)"
re-cut: "2026-10-08 — against the shipped tree (post-S28): prices re-pointed to
01's L2 bands (nothing restates a price; recipe CR totals re-derive from the
live ore/component values), the T-153 tier-4 rider folded in, every cite
re-measured."
---

# S27 — Catalog breadth & the shipyard

## Goal
The catalogue layers thicken on every axis the docs already shape: more affixes
with perks that finally fire, tier variants of existing modules, per-archetype
loot tables for the new enemies, and the shipyard build path (materials + labour
+ queue + scrap) that gives miners a second sink and every hull a cheap door.

## In scope
- Affixes (R-S27-2/3): `game/module_catalog.gd:135/:227 (PREFIXES/SUFFIXES)` —
  +4 prefixes, +3 suffixes; every suffix perk wired at the §20 aggregation seam
  (`game/affixes.gd`); the "displayed, never applied" note dies
- Variants (R-S27-1): `<base>_mk2` rows per the `p_mk2` precedent
  (`module_catalog.gd:260 MODULES`), priced by 10 §3.2's shape rule at +15 %
  per step, CR prices inside 01's L2 band for their tier
- Loot: per-archetype tables for `interceptor`, `turret`, `sibelon` and the
  boss rows (`game/loot_tables.gd:103 TABLES`), 06 §3's line format
- Shipyard (10 §3): `game/shipyard.gd` (new) — hull recipes per §3.1's rows,
  module builds per §3.2's shape rule with **CR totals re-derived from the live
  ore/component values (02's 2026-10-08 table)**, the §3.3 queue (one at a
  time, one in-space session, committed at queue, full refund on cancel,
  persists) and the §3.3 scrap path (50 % of recipe materials); the SHIPYARD
  panel gains the build/queue/scrap views in the shell-v2 idiom
- Tier-4 rider (**T-153**): a tier-4 catalogue row priced in 01's L2 band
  (6 000–12 000 CR) + `game/auction.gd:421`'s clamp reads it
- `tests/test_s27_catalog.gd` — new suite (A1–A7)

## Out of scope
- New faction exclusives (15 §5 stands at three); signature unique drops (06 §7
  defers them to a 07 amendment); crafting beyond the shipyard's shape rule
- Any art (owner 2026-09-27)

## Acceptance criteria
See `S27_BRIEF.md` §6 (A1–A7), each probe- or gate-provable.

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S27-B1 | `vajb-orbit/game/module_catalog.gd, vajb-orbit/game/loot_tables.gd, vajb-orbit/game/affixes.gd, vajb-orbit/game/shipyard.gd, vajb-orbit/game/shipyard.gd.uid, vajb-orbit/game/auction.gd, vajb-orbit/autoload/player_profile.gd, vajb-orbit/ui/station/shipyard_panel.gd, vajb-orbit/ui/station/shipyard_panel.tscn, vajb-orbit/tests/test_s27_catalog.gd, .agents/gen/slices/S27-catalog-breadth/S27-B1_report.md` | `S27_BRIEF.md` |
| S27-R1 | `vajb-orbit/tests/, docs/CONTRACTS.md, .agents/gen/slices/S27-catalog-breadth/S27-R1_review.md` | `S27_BRIEF.md` |
| S27-F1 | B1's set + `vajb-orbit/tests/, docs/CONTRACTS.md, .agents/gen/slices/S27-catalog-breadth/` | `S27_BRIEF.md` |

Read-only (never in a set): `game/exchange.gd`, `game/mineral_catalog.gd`,
`game/sector_registry.gd`, `game/station_registry.gd`, `docs/`.

## References
- `docs/gameplay/15_module_affixes.md` §1/§3/§4 + **2026-09-27 P3 block**
  (R-S27-2/3, ticks K2/K3) · `09_ship_slots_modules.md` **2026-09-27 P3 block**
  (R-S27-1, tick K1)
- `docs/gameplay/01_economy_core.md` **2026-10-08 S28 block** (L2's price
  bands — S25–S27's new rows price from them) · `02_minerals.md` 2026-10-08
  block (the value table the recipes derive from)
- `docs/gameplay/10_ship_acquisition.md` §3 (the shipyard pin) ·
  `06_loot_drops.md` §3 (line format) · `03_components.md` §3 (family mapping)
- `docs/design/UI_SPEC.md` §12–§15 and `docs/design/STATION_HUB.md` §19–§21
  (shell v2, by range)
- `docs/CONTRACTS.md` §20 (aggregation law) — R1 updates §9/§10

## Carries forward
- Signature unique drops and crafting (07) stay design-preview; new exclusives
  wait for faction stations' vendor story.
- T-153 closes with A6; its reversal is the clamp-drop alternative.
