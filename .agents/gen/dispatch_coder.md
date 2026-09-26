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
| — | — | *(Empty — no coder item is queued. The next wave needs its own docs-first five-piece from the developer/designer session.)* | — | — |

## Parked (owner-gated — not queued; say the word and the five-piece lands)


## Done

Items 1–24 closed (gate 437 → **887/0** through the waves); detail,
reviews, incidents and LOW rows in `.agents/gen/MASTER_REPORT.md` §6 and the
archived session reports. The last closed wave: item 24 = **S18 armory rework**
(2026-09-26, gate 877 → 886/0, 0 HIGH / **1 MED** / 5 LOW L223–L229, no fixer —
the MED is UI_SPEC §3.10 A3's cell **117×50 → 117×52**, docs text, **owed by the
developer session**, not the coder lane). The owner's same-day live bug report
(text behind backgrounds) was fixed post-close-out — the chrome layer under the
content, the drop cues in their own grid slots (L232–L233 closed, two guards) —
taking the gate **886 → 887/0**.

## Handoff (live)

**No coder item is queued.** The coder lane is idle at gate **887/0** (S18 closed
2026-09-26; the design lane has no live item, D13 closed). Before the next code
wave, the developer/designer session owes: (1) the S18 MED — UI_SPEC §3.10
Amendment 3's Layout bullet says cells **117×50**, the shipped/tested cell is
**117×52** (bucket 2, docs text — no worker may edit it); (2) the next wave's
docs-first five-piece. Note L229: probes that mount the station boot the owner's
live profile — run them under `XDG_DATA_HOME=$(mktemp -d)`. Everything else is
parked above.
