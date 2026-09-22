---
slice: S3
phase: P2
lane: code
status: draft
gate_baseline: "437/0 (sandboxed; 433/4 on the live save — L93)"
---

> Draft created 2026-09-22 under the folder law (`_templates/README.md`); scope
> expanded the same day when the owner ruled the AUCTION is required inside this
> wave ("without it we cannot test all items"). Docs-first is **done**:
> 15 §8, 10 §2.4, 09 §10, STATION_HUB §5.10 and CONTRACTS §14–§16 + v0.7 are
> landed; the brief (`S3_BRIEF.md`) is law for the workers.

# S3 — Module instances with affixes, sold by the AUCTION

## Goal
Modules stop being flat catalogue rows and become rolled instances — a bought
or dropped module carries `{instance_id, base_id, rarity, prefixes[], suffixes[]}`
with Common/Magic/Rare rarity, named prefix/suffix stats and 15 §7's name — and
the AUCTION (10 §2) opens as the one door that stocks every module family and
the faction exclusives, so every item is testable. After S3 the player can shop
a rotating shelf of named drops and tell two `w_laser` instances apart.

## In scope
- The module instance shape + identity (`mod_%04d`) and roll-at-creation — 15 §1/§6/§8
- Roll sources and tables (auction listings at restock, drops at drop) — 15 §2/§3/§4
- Faction-exclusive lots (the §8 interim until 12 §5's faction stations) — 15 §5
- The AUCTION screen: rotation, hull weights, hot slot, buy/sell — 10 §2/§2.4, STATION_HUB §5.10
- Rolled names + stat lines in FITTING and shipyard hover; rarity tints — 15 §7, STATION_HUB §5.10
- Save v6 + the idempotent v5→v6 migration; L80's instance-true remove/swap
- The retirement of OUTFITTING's seven weapon rows into the auction — 10 §2.4/§6

## Out of scope
- Weapon batteries (09 §10) — wave S4, after this one
- Crafting/derelict/arena roll sources (15 §2 rows exist, no callers — those systems don't exist yet)
- Balance re-tuning of base module stats or roll weights (15/10/09 are frozen arithmetic)
- The bare-hull mandatory-cell `REMOVE` residual (L92) unless its fixer owns a
  file this slice already touches

## Acceptance criteria
- [ ] AC1 — seeded probes prove the roll tables row by row (15 §2/§3/§4), roll at
      creation, never re-rolled
- [ ] AC2 — v5 stacked records migrate to N Common instances, idempotently; fits
      hold instance ids; REMOVE/SWAP return the same instance (L80 closed)
- [ ] AC3 — the auction draws 6 hulls + 10 rolled modules per §2.1's clock, hot
      slot −20 % after rarity, F lot at Magic+ floor, sell at base × rarity × 60 %
- [ ] AC4 — OUTFITTING's weapon rows are gone and the pane reads ammunition-only;
      every rolled name renders per 15 §7 in FITTING and the hover lines
- [ ] AC5 — the gate holds green with the S3 suites added (measured number into
      CONTRACTS §9)

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S3-K0 | `docs/,vajb-orbit/tests/,vajb-orbit/tools/` | `S3_BRIEF.md` |
| S3-K1 | `vajb-orbit/autoload/player_profile.gd,vajb-orbit/game/module_catalog.gd,vajb-orbit/game/ship_fit.gd,vajb-orbit/tests/` | `S3_BRIEF.md` |
| S3-K2 | `vajb-orbit/ui/station/auction_panel.{gd,tscn},vajb-orbit/ui/station/outfitting_panel.{gd,tscn},vajb-orbit/ui/screens/station.gd,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/` | `S3_BRIEF.md` |
| S3-K3 | `vajb-orbit/ui/station/fitting_panel.gd,vajb-orbit/ui/station/shipyard_panel.gd,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/` | `S3_BRIEF.md` |
| S3-K4 | `vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md` | reviewer |
| S3-K5 | the union of K1–K3 sets + `docs/CONTRACTS.md` | fixer, only on HIGH/MED |

## References
- `docs/gameplay/15_module_affixes.md` (the spec; §8 the dated amendment)
- `docs/gameplay/10_ship_acquisition.md` §2/§2.4/§5/§6
- `docs/gameplay/09_ship_slots_modules.md` §3.1/§4
- `docs/design/STATION_HUB.md` §5.10
- `docs/CONTRACTS.md` §15 (this wave's pin), §12/§13 (the seams it extends)

## Carries forward
- `T-80` (L80) — instance-vs-base-id seam, resolved here
- Owner ticks: the v5 migration's Common-vs-retro-roll, the F-lot interim, the rail position
