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
| 24 | S18 | **Armory rework — the implementation** (D13's owner-ticked design: approach B, landscape console, P1–P6) | `slices/S18-armory-rework/` | **QUEUED — next.** Law: `S18_BRIEF.md` + `slices/D13-armory-rework/D13-A0_report.md`; prompts `S18_prompts.md`. Run B1 → R1 → (F1 on HIGH/MED). |

## Parked (owner-gated — not queued; say the word and the five-piece lands)


## Done

Items 1–23 closed (gate 437 → **877/0** through the waves); detail,
reviews, incidents and LOW rows in `.agents/gen/MASTER_REPORT.md` §6 and the
archived session reports. The last closed wave: item 17 = **S17 jump gates to
sector edges** (2026-09-25, gate 866 → 877/0, 0 HIGH / 0 MED / 5 LOW L216–L220,
no fixer).

## Handoff (live)

**Coder item 24 = S18 armory rework (implementation) is QUEUED and ready** —
the ARMORY pane rebuild on D13's owner-ticked design (approach B, landscape
console 1360×516, 2×2 rack cells, the T1 all-resolutions condition). Brief
`slices/S18-armory-rework/S18_BRIEF.md` (design law rides
`slices/D13-armory-rework/D13-A0_report.md`), prompts
`slices/S18-armory-rework/S18_prompts.md`. Run `S18-B1` → `S18-R1`, and `S18-F1`
only if the review leaves HIGH or MED. Gate starts **877/0** (add rows, never
lose one). The design lane has no live item (D13 closed); everything else is
parked above.
