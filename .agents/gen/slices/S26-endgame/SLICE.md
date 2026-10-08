---
slice: S26
phase: P3
lane: code
status: ready
gate_baseline: "post-S25 (record the measured count; S28 closed at 1202/0)"
re-cut: "2026-10-08 — against the shipped tree (post-S24 + S28): boss payouts
re-cut to 6 000/12 000 (M10), the premium law re-cut to M14's 1.5 %-of-list,
the panel law re-pointed to STATION_HUB §15.3/§15.4, every cite re-measured.
The S25 seam cite is prospective — re-verify at dispatch."
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
  live; the §15.2 U7 staged row un-greys), 60 s entry window, payout on return
  win or lose, one run/boss per 20-minute clock, last-hit kill credit
- Bosses: `game/npc_registry.gd:184/:451/:510 (SEAM_SLICE_4)` released —
  Boneyard Behemoth + Pyre Hierophant at R-S26-1's fits and **S28's payouts
  (6 000 + magic roll / 12 000 + guaranteed rare, M10)**, The Maw roaming S7
- The Maw's loot: `game/loot_tables.gd:90 (MAW_LINES)` finally fed (06
  §3.4: floor 1 025 CR, mean 1 584.75, the only Voidshard source)
- Death persistence (18 §2 dec. 7 + §7): the wreck and its window survive the
  death/respawn route, respawn docked at the last station visited
  (`game/game.gd:3056 _respawn_docked`; the deferred slice-4 comments at
  `:2881`/`:3055` die)
- Insurance (14 §3 + S28's block): **the premium is 1.5 % of the hull's list
  per class (135–1 080 band, M14 — ratified)**, charged at launch, one-death
  policy, payout flow (respawn in the tier's cheapest base hull; hull+fit paid
  back into the dock), Champion ×0.8 (`station_registry.gd:423`), Choir sells
  none, mercy clause once per profile (`player_profile.gd:1949`)
- Vaults (14 §4): one per station, 20 units, tiers 500/1 200/2 400, Meridian
  40-unit at +25 %, contents persist per station and are excluded from launch
  cargo; `u_vault`'s +20-units consumer lands (15 §5; `module_catalog.gd:547`)
- The INSURANCE and VAULTS panels per `STATION_HUB.md` §15.3/§15.4, wired into
  the SERVICES deck beside S25's contracts strip
- `tests/test_s26_endgame.gd` — new suite (A1–A8)

## Out of scope
- The leviathan/spire/thorn bosses (staged — no design rows); crafting (07 is
  design-preview only); buy-side exchange; story
- New art (owner 2026-09-27) — bosses use the shipped renders

## Acceptance criteria
See `S26_BRIEF.md` §6 (A1–A8), each probe- or gate-provable.

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S26-B1 | `vajb-orbit/game/npc_registry.gd, vajb-orbit/game/loot_tables.gd, vajb-orbit/game/game.gd, vajb-orbit/game/contract_registry.gd, vajb-orbit/game/module_catalog.gd, vajb-orbit/autoload/player_profile.gd, vajb-orbit/ui/screens/station.gd, vajb-orbit/ui/station/insurance_panel.gd, vajb-orbit/ui/station/insurance_panel.gd.uid, vajb-orbit/ui/station/insurance_panel.tscn, vajb-orbit/ui/station/vaults_panel.gd, vajb-orbit/ui/station/vaults_panel.gd.uid, vajb-orbit/ui/station/vaults_panel.tscn, vajb-orbit/tests/test_s26_endgame.gd, .agents/gen/slices/S26-endgame/S26-B1_report.md` | `S26_BRIEF.md` |
| S26-R1 | `vajb-orbit/tests/, docs/CONTRACTS.md, .agents/gen/slices/S26-endgame/S26-R1_review.md` | `S26_BRIEF.md` |
| S26-F1 | B1's set + `vajb-orbit/tests/, docs/CONTRACTS.md, .agents/gen/slices/S26-endgame/` | `S26_BRIEF.md` |

Read-only (never in a set): `game/station_registry.gd`, `game/exchange.gd`,
`game/sector_registry.gd`, `game/mineral_catalog.gd`,
`autoload/world_clock.gd`, `docs/`.

## References
- `docs/gameplay/14_station_services.md` §3/§4/§5 (the pin) + **2026-10-08 S28
  block** (M10's boss payouts, M14's premium) · `06_loot_drops.md` §3.4 (the
  Maw table) · `15_module_affixes.md` §5 (the `u_vault` row + rare rolls)
- `docs/gameplay/08_ship_classes.md` **2026-09-27 P3 block** (R-S26-1, tick E1)
- `docs/gameplay/18_engine_spec.md` §2 dec. 7 + §7 (read-only)
- `docs/design/STATION_HUB.md` §15.3/§15.4 (the panel laws) + §5.2 ·
  `docs/design/UI_SPEC.md` §12–§15 and STATION_HUB §19–§21 (shell v2, by range)
- `slices/S25-contracts/S25-B1_report.md` — the Expedition seam contract
  (prospective; S25's brief §6 A1 until it lands)

## Carries forward
- The Maw's roam/respawn numbers go to the developer's next 14 §5 block at tick
  E2 (see the brief §11); the optional three extra bosses stay staged.
