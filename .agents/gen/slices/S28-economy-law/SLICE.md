---
slice: S28
phase: P3
lane: code
status: ready
gate_baseline: "post-S24 (1186/0, 2026-10-08)"
---

# S28 — The universal cost law

> **ID note (the owner's word, 2026-10-08):** the owner named this slice S28.
`_archive/slices/S28-station-chrome/` already carries that number (shipped and
retired), so every reference here uses the full slug `S28-economy-law` and the
worker letter **C** (the archived wave holds B/R/F ids) to keep bare worker IDs
unique. Say "S38" and this is one rename before dispatch.

## Goal
One law under the economy: every price and payout reads as sessions of its
tier and every income number derives from one value ladder — the Obliterator
stops being a 3-trip purchase and the ladder takes the 70–100 sessions the
design promised.

## In scope
- The 20-row value table (×2.0/tier means, T1 byte-unchanged) — `02`'s
  2026-10-08 block
- The value-relative refine fee with its 15 CR floor — `04` §8
- The SC-scaled boss/contract payout tables (docs) — `14`'s 2026-10-08 block
- The battery work-channel cap (`1 + 0.4×(N−1)`) and the ore bloom cap
  (6 rocks × 1.5) — `01`'s L4
- The moved test rows + the two new S28 suites

## Out of scope
- Every price row (hulls frozen, modules compliant — L2 ships zero edits)
- Insurance premiums (M14 is a docs-only option; S26 implements insurance)
- Work-per-unit tier scaling (staged — sessions are hold-limited; revisit on
  the probe's evidence)
- `docs/gameplay/18_engine_spec.md` (owner-locked) and `docs/CONTRACTS.md`
  (R1's alone)

## Acceptance criteria
- [ ] AC1 — the 20 rows land exactly; T1 byte-identical; the board monotone
      across tiers
- [ ] AC2 — every mineral's conversion fee = `max(15, ingot×80/1000)`; iron's
      15/30/45 CR rows unchanged; the four panel call sites re-pointed
- [ ] AC3 — N fitted `w_mining` deliver `1+0.4×(N−1)` work channels (N=1
      unchanged, the floor is one channel)
- [ ] AC4 — the ore bloom spawns 6 rocks × 1.5 yield (T+1, same trigger)
- [ ] AC5 — the S28 suites assert the law's derivation and the SC model band
- [ ] AC6 — the gate ×2 hermetic; every moved test row enumerated in the reports

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S28-C1 | `vajb-orbit/game/mineral_catalog.gd, vajb-orbit/game/refinery.gd, vajb-orbit/ui/station/refinery_panel.gd, vajb-orbit/tests/test_p1_catalogues.gd, vajb-orbit/tests/test_p1_pricing.gd, vajb-orbit/tests/test_p1_refinery.gd, vajb-orbit/tests/test_s34_refinery_queue.gd, vajb-orbit/tests/probe_s34_review.gd, vajb-orbit/tests/test_s28_econ.gd, .agents/gen/slices/S28-economy-law/S28-C1_report.md` | `S28_BRIEF.md` |
| S28-C2 | `vajb-orbit/game/ore_tuning.gd, vajb-orbit/game/mining_laser.gd, vajb-orbit/ui/dev/dev_tuning_menu.gd, vajb-orbit/game/poi.gd, vajb-orbit/tests/test_s13_caps.gd, vajb-orbit/tests/test_s13_mining_batteries.gd, vajb-orbit/tests/test_s13_devmenu.gd, vajb-orbit/tests/test_s6_poi_loot.gd, vajb-orbit/tests/test_s28_events.gd, .agents/gen/slices/S28-economy-law/S28-C2_report.md` | `S28_BRIEF.md` |
| S28-R1 | `vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S28-economy-law/S28-R1_review.md` | `S28_BRIEF.md` |
| S28-F1 | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S28-economy-law/` | `S28_BRIEF.md` |

C1 and C2 are file-disjoint but run in order (one live session; the gate is
global). R1 after both; F1 only if the review leaves HIGH or MED.

## References
- The five 2026-10-08 S28 blocks: `01_economy_core.md`, `02_minerals.md`,
  `04_refinery.md`, `05_exchange.md`, `11_galactic_map.md`,
  `14_station_services.md`
- The superseded law, for context: `01` §5, `02` §2/§4, `04` §2–§3, `05` §3,
  `11` §3.2, `14` §2/§7
- `docs/CONTRACTS.md` (R1 pins the wave's interfaces at the next free section)

## Carries forward
- T-138 (SERVICES deck placeholder) stays on S25
- The S25/S26 brief extracts re-cut against `14`'s S28 block before their
  dispatch (the queue rows carry it)
