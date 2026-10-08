---
phase: P3
title: Content & feel push (playtest-2 cycle)
status: active
slices: [S24, S28, S25, S26, S27]
---

> **Use when:** a phase opens. Manifest and index only — work lives in slice
> folders; this file never grows a work log. **2026-10-08 (owner clear-out):**
> trimmed to the remaining slices and reworked as a checkbox list, ticked as
> each slice closes. S21–S23, the D15–D22 design rounds and S28–S37 shipped and
> are archived (`_archive/slices/`, `MASTER_REPORT.md` §6).

# P3 — Content & feel push (playtest-2 cycle)

## Goal
The owner's playtest round: clear the play-facing defect pile, land the feel and
juice pass, and fill the measured content voids (dead modules, live
bosses/aliens, stations with identity, contracts) using only the shipped art
library. Ends in playtest build 2.

## Remaining slices (order = the two queues, one live session)

- [x] **S24 — world identity.** Named stations + per-faction menus/flavours,
      standing band effects, per-sector hostile bands, nebula clouds.
      `slices/S24-world-identity/` · **closed 2026-10-08**, gate 1186/0 ×2, verify
      `"problems": []` vs `s24_start` · re-cut before dispatch (two sequential
      builders B1 A1–A2 → B2 A3–A5, R1, F1 on its one HIGH) · **all eleven ticks
      (W1–W3 + V1–V8) owner-ratified green 2026-10-08**
- [ ] **S28 — universal cost law.** The ×2.0/tier value ladder, the
      value-relative refine fee, SC-scaled boss/contract payouts, the
      battery/bloom caps. `slices/S28-economy-law/` · runs after: S24 ·
      baseline `post-S24` (1186/0) · **runs before S25/S26** (they pin the
      `14` §2/§7 payouts it amends) · **ticks M8–M14 owner-ratified green
      2026-10-08**
- [ ] **S25 — contracts board.** `contract_registry` + the board panel:
      Haul/Hunt/Gather/Escort, escrow + 100 CR cancel, standing gates, the
      escort convoy loop. `slices/S25-contracts/` · runs after: S28 · baseline
      `post-S28`
- [ ] **S26 — endgame: bosses, arenas, insurance, vaults.** The Boneyard + The
      Pyre arena runs, the Maw roaming S7, death persistence, insurance + mercy
      clause, vaults + `u_vault`. `slices/S26-endgame/` · runs after: S25 ·
      baseline `post-S25`
- [ ] **S27 — catalog breadth & shipyard.** +7 affix rows with perks live, tier
      variants, per-archetype loot, the shipyard build path
      (recipes/queue/scrap). `slices/S27-catalog-breadth/` · runs after: S26 ·
      baseline `post-S26`

## Wave checklist (applies to every slice above)

- [ ] Docs first — the owning doc amended with the real numbers, each carrying
      its reversal path
- [ ] Five-piece handoff re-cut against the current shell (`BRIEF` + `prompts`)
- [ ] `verify_wave.py snapshot` + commit before the first dispatch
- [ ] Builders run → mandatory review → fixer only if the review leaves HIGH/MED
- [ ] Close-out: gate ×2 hermetic, `verify --baseline`, CONTRACTS §9/§10,
      WAVEBOARD + TICKS refresh, wave-boundary commit

## Owner gates
- **Playtest pass #1** is the owner's: the "awaiting the owner's eye" list in
  `docs/gameplay/19_testing_notes.md`. Each finding joins `LOW_BACKLOG.md` at
  the next free id and rides the wave that owns its file.
- **Tick sheets** (marked in the 2026-09-27 doc amendments and each brief §11):
  W1–W3 world, J1 board, E1–E2 endgame, K1–K3 catalog, plus M1–M14
  money/economy (M8–M14 = S28's block) and C1–C6 content rows. Unticked rows implement at their PROPOSED value (the
  S19 precedent).
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
- T-138 (SERVICES deck placeholder) rides S25; the S36/S37 chrome rows retired
  to `_archive/low_backlog_s36_s37_rows_2026-10-08.md`.
