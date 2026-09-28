# dispatch_coder.md — the code-lane queue of record

Purged and regenerated 2026-09-25 (owner ask: "too much shit to keep track of
it" — the queue carries only live items; closed work lives in
`MASTER_REPORT.md` §6 and git). Execute **one item per order**, close out per
the brief's close-out section. Model for every worker:
`deepseek/deepseek-flash` (owner ruling 2026-09-24) on
`--reasoning-effort max`. The owner pastes only the handoff block at the
bottom.

**File-collision law:** two waves never hold one file (nor the same `test_*`
prefix, nor one `staging/` driver). One live session per workspace (L82).
**Wave anatomy:** docs-first five-piece → `verify_wave.py snapshot` + commit
→ builders → mandatory review → fixer only on HIGH/MED → close-out (gate ×2
hermetic, `verify --baseline`, CONTRACTS §9/§10 sequenced with any parallel
lane, WAVEBOARD, wave-boundary commit).

## Queue

| # | Wave | Item | What | Status |
|---|---|---|---|---|
| 27 | S21 | Stability & playtest fixes | Death state, wreck window across transitions, ship-vs-ship crash damage, profile/hermeticity hygiene, bag reads, money edges, world-sim fixes (L18/L22/L23/L24/L73/L90/L93/L110/L114/L122/L124/L130/L131/L136/L150/L152/L153/L154/L176/L215/L237/L243). Five-piece: `slices/S21-stability-fixes/`; pins R-S21-1..3 (01/10's 2026-09-27 P3 blocks, ticks M1–M3). **Split into three builders (B1/B2/B3, owner-ruled 2026-09-28)** — disjoint regions, sequential, review grades A1–A11 across all three. | **running** |
| 28 | S22 | Feel, juice & balance | Hit/ram/mining feedback, muzzle at nose, quadrant HUD feed, anti-flam + mine cue, low-hull arcs, the feel tick rows and the S19 balance rows (L28/L56/L51/L52/L65/L241/L54/L48/L55/L25/L39/L103/L182/L168/L244/L242/L70). Five-piece: `slices/S22-feel-and-juice/`; pins R-S22-1..4 (01/09 P3 blocks, ticks M4–M7) + D15's tick sheet. | queued · after 27 (`game/`+`ui/`+`tests/`) |
| 29 | S23 | Content activation | `w_proton`/`w_flak` families, the three dead module effects, 7 stock fits, sibelon seam, interceptor/turret-platform hulls, per-hull sprites + liveries (L137), loot rows (L48-class closed). Five-piece: `slices/S23-content-activation/`; pins R-S23-1..6 (09/08 P3 blocks, ticks C1–C6). | queued · after 28 (`game/`) |
| 30 | S24 | World identity | Named stations + per-faction menus/flavours, standing band effects, per-sector hostile bands, nebula clouds (L-band-split). Five-piece: `slices/S24-world-identity/`; pins R-S24-1..3 (14/13/11 P3 blocks, ticks W1–W3). | queued · after 17 (D16's spec) + 29 |
| 31 | S25 | Contracts board | `contract_registry` + the board panel: Haul/Hunt/Gather/Escort, escrow + 100 CR cancel, standing gates, the escort convoy loop. Five-piece: `slices/S25-contracts/`; pin R-S25-1 (14 P3 block, tick J1). | queued · after 30 (`ui/station/` + profile) |
| 32 | S26 | Bosses, arenas, insurance, vaults | The Boneyard + The Pyre arena runs, the Maw roaming S7 with 06 §3.4's table, death persistence, insurance + mercy clause, vaults + `u_vault`. Five-piece: `slices/S26-endgame/`; pin R-S26-1 (08 P3 block, ticks E1/E2). | queued · after 31 (Expedition seam) |
| 33 | S27 | Catalog breadth & shipyard | +7 affix rows with perks live, tier variants, per-archetype loot, the 10 §3 shipyard (recipes/queue/scrap). Five-piece: `slices/S27-catalog-breadth/`; pins R-S27-1..3 (09/15 P3 blocks, ticks K1–K3). | queued · after 32 (`game/`) |

## Parked (owner-gated — not queued; say the word and the five-piece lands)


## Done

Items 1–26 closed (gate 437 → **914/0** through the waves); detail, reviews,
incidents and LOW rows in `.agents/gen/MASTER_REPORT.md` §6 and the archived
session reports.

- **Item 26 = S19 directional armour & breach malfunctions** (2026-09-26,
  gate 895 → **914/0** twice hermetic, 1 HIGH / 0 MED / 5 LOW **L240–L245**).
  Four `hull_max/4` pools route by `ctx.direction` with the sum invariant, the
  rear 160° arc's ×1.6 lands before the shield-first absorb, an emptied pool
  runs its breach malfunction (RCS drift / flicker / turn clip, derived state),
  repairs and both readouts carry the four quadrants. Its one HIGH was bucket 2
  (the astern shielded row the pin moves, off the brief's §3 list): **S19-F1**
  ran, moved the row onto P3's own `STERN_DAMAGE_MULT` and wrote the §3 list
  amendment (L240 closed), the first fixer to take a bucket-2 list item,
  disclosed as a deviation. Ran only after S20's close-out per the
  file-collision law (its first, concurrent B1 was stopped before it wrote
  anything; the baseline was re-taken on the post-S20 tree). Owner ticks
  **T1–T7** in 09 §3.3's amendment stay open (balance deferred).
- **Item 25 = S20 ARMORY chrome unification & the hover reflow fix**
  (2026-09-26, gate 887 → **895/0** twice hermetic, 2 HIGH / **1 MED** /
  4 LOW **L234–L239**). The pane wears the §5.3 chrome family with the D13
  layout frozen, the shell inspector holds a constant height, `OVER CAP`
  measures 4.855:1 (**L227 closed**). Its one MED (the pane scene still
  carrying the retired master's ext_resource) was the fixer's only in-scope
  item, so **S20-F1** ran and dropped it; its two HIGHs are bucket-2 pin-list
  items — **L238–L239**, the developer session's list edit, no code revert.
  Owner ticks recorded in `UI_SPEC.md` §3.10 A4: T1–T4 as briefed, T5 = keep,
  **T6 open** (the bay chip's `▲ OVER CAP` vs `▲ AT CAP` wording).
- **Item 24 = S18 armory rework** (2026-09-26, gate 877 → 886/0, 0 HIGH /
  1 MED / 5 LOW L223–L229, no fixer — its one MED was UI_SPEC §3.10 A3's cell
  `117×50 → 117×52`, docs text, the developer session's owed fix, landed in
  `d323cb7`). The owner's same-day live bug report (text behind backgrounds)
  was fixed post-close-out — the chrome layer under the content, the drop cues
  in their own grid slots (L232–L233 closed, two guards) — taking the gate
  886 → 887/0.

## Handoff (live)

**Item 27 = S21 stability & playtest fixes** (paste as-is; the later items'
handoff blocks live at the bottom of their own `<WaveID>_prompts.md`):

```text
Read .agents/gen/dispatch_coder.md and execute queue item 27 only — S21 stability & playtest fixes. Brief: .agents/gen/slices/S21-stability-fixes/S21_BRIEF.md. Prompts: .agents/gen/slices/S21-stability-fixes/S21_prompts.md. Snapshot + commit before the first dispatch, run B1 → B2 → B3 → R1, and the fixer only if the review leaves HIGH or MED. Stop before item 28. Close out per the brief's close-out section (gate re-run, verify_wave.py verify --baseline s21_start, WAVEBOARD update, wave-boundary commit), then report back: the measured gate count, the builder's per-deliverable numbers, the reviewer's findings by tier, and the owner ticks.
```

The whole queue is phase **P3** (`phases/P3-content-feel-push/PHASE.md`);
order and the collisions that force it are in `WAVEBOARD.md` §Queued. The
parked list stands owner-gated.
