---
slice: S26
phase: P3
lane: code
status: draft
gate_baseline: "post-S25"
---

# S26 — Endgame: bosses, arenas, insurance, vaults

## Goal
The ladder has a top: two arena bosses with their physical rings and contract
runs, The Maw roaming lawless S7 with its Grade-III loot table, death that
finally costs-but-insures (insurance + mercy clause), and per-station vaults
that give `u_vault` its consumer.

## In scope
- Arenas (14 §5): The Boneyard (S3) + The Pyre (S6) — physical barricaded ring
  zones with nav pylons, opened by an Expedition contract (S25's seam flips
  live), 60 s entry window, payout on return win or lose, one run/boss per
  20-minute clock, last-hit kill credit
- Bosses: `game/npc_registry.gd:420 (boss row, SEAM_SLICE_4)` released —
  Boneyard Behemoth + Pyre Hierophant at R-S26-1's fits and 14 §5's rewards
  (15k + magic roll / 40k + guaranteed rare per 15 §5), The Maw roaming S7
- The Maw's loot: `game/loot_tables.gd:89-101 (MAW_LINES)` finally fed (06
  §3.4: floor 1 025 CR, mean 1 584.75, the only Voidshard source)
- Death persistence (18 §2 dec. 7 + §7): the wreck and its window survive the
  death/respawn route (completes S21's A2 for death), respawn docked at the last
  station visited (`game/game.gd:2522-2630`'s deferred comments die)
- Insurance (14 §3): premiums per launch (200/250/300/400/500/700 by class),
  one-death policy, payout flow (respawn in the tier's cheapest base hull;
  hull+fit paid back into the dock), Champion ×0.8 (S24's hook), Choir sells
  none, mercy clause once per profile (`player_profile.gd:1748-1759`)
- Vaults (14 §4): one per station, 20 units, tiers 500/1 200/2 400, Meridian
  40-unit at +25 %, contents persist per station and are excluded from launch
  cargo; `u_vault`'s +20-units consumer lands (15 §5)
- `tests/test_s26_endgame.gd` — new suite (A1–A7)

## Out of scope
- The leviathan/spire/thorn bosses (staged — no design rows); crafting (07 is
  design-preview only); buy-side exchange; story
- New art (owner 2026-09-27) — bosses use the shipped renders

## Acceptance criteria
See `S26_BRIEF.md` §6 (A1–A7), each probe- or gate-provable.

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S26-B1 | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/autoload/player_profile.gd, vajb-orbit/tests/, .agents/gen/slices/S26-endgame/S26-B1_report.md` | `S26_BRIEF.md` |
| S26-R1 | `vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S26-endgame/S26-R1_review.md` | `S26_BRIEF.md` |
| S26-F1 | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/autoload/player_profile.gd, vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S26-endgame/` | `S26_BRIEF.md` |

## References
- `docs/gameplay/14_station_services.md` §3/§4/§5 (the pin) ·
  `06_loot_drops.md` §3.4 (the Maw table) · `15_module_affixes.md` §5 (the
  `u_vault` row + rare rolls)
- `docs/gameplay/08_ship_classes.md` **2026-09-27 P3 block** (R-S26-1, tick E1)
- `docs/gameplay/18_engine_spec.md` §2 dec. 7 + §7 (read-only)
- `slices/S25-contracts/S25-B1_report.md` — the Expedition seam contract

## Carries forward
- The Maw's roam/respawn numbers go to the developer's next 14 §5 block at tick
  E2 (see the brief §11); the optional three extra bosses stay staged.
