---
phase: P3
title: Content & feel push (playtest-2 cycle)
status: active
slices: [S21, S22, S23, S24, S25, S26, S27, D15, D16]
---

> **Use when:** a phase opens. Manifest and index only — work lives in slice
> folders; this file never grows a work log.

# P3 — Content & feel push (playtest-2 cycle)

## Goal
The owner's playtest round: clear the play-facing defect pile, land the feel and
juice pass, and fill the measured content voids (dead modules, live
bosses/aliens, stations with identity, contracts) using only the shipped art
library. Ends in playtest build 2.

## The plan (order = the two queues, one live session)
| # | Slice | Delivers | Runs after |
|---|---|---|---|
| 1 | S21 | stability & playtest fixes | — |
| 2 | D15 | flight feel & feedback design (the tick sheet) | S21 |
| 3 | S22 | feel, juice & balance | D15 (its ticks) |
| 4 | S23 | dead content activation | S22 (`game/` collision) |
| 5 | D16 | station identity & contracts UI design | S23 |
| 6 | S24 | world identity (stations, factions, nebula) | D16 |
| 7 | S25 | contracts board | S24 (`station` screen + profile) |
| 8 | S26 | bosses, arenas, insurance, vaults | S25 (Expedition seam) |
| 9 | S27 | catalog breadth + shipyard | S26 (`game/` collision) |

## Owner gates
- **Playtest pass #1** is the owner's: the "awaiting the owner's eye" list in
  `docs/gameplay/19_testing_notes.md`. Each finding joins `LOW_BACKLOG.md` at
  the next free id and rides the wave that owns its file.
- **Tick sheets** (marked in the 2026-09-27 doc amendments and each brief §11):
  M1–M7 money/repair, C1–C6 content rows, W1–W3 world, J1 board, E1–E2
  endgame, K1–K3 catalog, and D15's feel sheet (T-feel-1..7 + S19's T1–T7).
  Unticked rows implement at their PROPOSED value (the S19 precedent).
- **No AI art generation this round** (owner 2026-09-27): content reuses the
  shipped library; audio may be sourced CC0 through `assetmcp`.

## Exit criteria
- [ ] Every slice `done` (findings tiered, briefs archived)
- [ ] Playtest build 2 exported (both presets, Linux smoke-tested) and the
      tester feedback template added to `19_testing_notes.md`
- [ ] `docs/CONTRACTS.md` updated by each closing review wave (§9 gate figure)
- [ ] Phase summary appended to `MASTER_REPORT.md` §6

## Carries forward
- Parked unchanged: the S12 ore caps/scale rows (owner's §10 ticks), slice 2.5's
  engine-bed/vignette calls, S8's O1–O3, the T-93 systemic write guard.
- Staged (need art or design rows): L57's bolt/slug re-cut; the
  leviathan/spire/thorn bosses; the `u_vault` consumer lands in S26 with the
  vaults it extends.
