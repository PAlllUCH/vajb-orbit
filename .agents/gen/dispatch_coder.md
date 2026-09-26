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
| 26 | S19 | Directional armour & breach malfunctions (ruling 23) | Four armour pools routed by `ctx.direction`, stern ×1.6, breach malfunctions (RCS drift / engine flicker / clipped turn), repairs + readouts. `slices/S19-directional-armour/` (`S19_BRIEF.md`, `S19_prompts.md`); pin `09_ship_slots_modules.md` §3.3's 2026-09-26 amendment. Run B1 → R1 → F1 on HIGH/MED. | **queued** |

## Parked (owner-gated — not queued; say the word and the five-piece lands)


## Done

Items 1–25 closed (gate 437 → **895/0** through the waves); detail, reviews,
incidents and LOW rows in `.agents/gen/MASTER_REPORT.md` §6 and the archived
session reports.

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

Read `.agents/gen/dispatch_coder.md` and execute queue item 26 only — S19
directional armour & breach malfunctions (ruling 23). Brief:
`.agents/gen/slices/S19-directional-armour/S19_BRIEF.md`. Prompts:
`.agents/gen/slices/S19-directional-armour/S19_prompts.md`. Snapshot + commit
before the first dispatch, run B1 → R1, and the fixer only if the review
leaves HIGH or MED. Close out per the brief's close-out section (gate re-run ×2
on scratch stores, `verify_wave.py verify --baseline s19_start`, WAVEBOARD
update, wave-boundary commit), then report back: the measured gate count, the
builder's per-deliverable numbers (P1–P8 const table, per-AC measurements),
the reviewer's findings by tier, and the owner ticks (T1–T7 in the 09 §3.3
amendment — balance is deferred, they calibrate later). Note L229: probes
that mount the station run under `XDG_DATA_HOME=$(mktemp -d)`.
