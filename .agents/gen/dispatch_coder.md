# dispatch_coder.md — the code-lane queue of record

Purged and regenerated 2026-09-25 (owner ask: "too much shit to keep track of
it" — the queue carries only live items; closed work lives in
`MASTER_REPORT.md` §6 and git). Execute **one item per order**, close out per
the brief's close-out section. Model for every worker:
`deepseek/deepseek-flash` (owner ruling 2026-09-24) on
`--reasoning-effort high`. The owner pastes only the handoff block at the
bottom.

**File-collision law:** two waves never hold one file (nor the same `test_*`
prefix, nor one `staging/` driver). One live session per workspace (L82).
**Wave anatomy:** docs-first five-piece → `verify_wave.py snapshot` + commit
→ builders → mandatory review → fixer only on HIGH/MED → close-out (gate ×2
hermetic, `verify --baseline`, CONTRACTS §9/§10 sequenced with any parallel
lane, WAVEBOARD, wave-boundary commit).

## Queue

| # | Wave | Slice folder | Brief / prompts | Status |
|---|---|---|---|---|
| 17 | **Jump gates to sector edges** (owner ask 2026-09-24 "same gates, spawn placement only"; owner go 2026-09-25) | `slices/S17-gate-edges/` | `S17_BRIEF.md` / `S17_prompts.md` | **QUEUED — next.** Docs pin `11_galactic_map.md` §6 (the border placement, `FIELD_EDGE_MARGIN` 800 inset, tangency to the corridor band); baseline gate 866/0; `gate.gd` + `sector_registry.gd` are forbidden files. |

## Parked (owner-gated — not queued; say the word and the five-piece lands)

- The **S12 ore caps/scale rows** — the tables + §10 ticks are with the
  owner; **do not implement ticked numbers before that wave is briefed**.
- **Slice 4's remainder** — quadrants/directional armour (18 §4.5 + ruling
  23); bosses/arena (14 §5, blocked on P4 contracts + boss art).
- **§13 turn/coast column ticks** and slice 2.5's engine-bed/vignette calls —
  the owner's.
- **S8's owner gates** — O1/O2 (FITTING-drag UX call), O3
  (site/symptom/mask), L168 (repairs transaction caps at the base row), L169
  (same-family battery per-cell seed).
- The **chrome art half** owner gate.
- The D13 armory rework's **implementation wave** — briefs only on the
  owner's ticks on D13's tick list.

## Done

Items 1–16, 18–23 closed (gate 437 → 866/0 through the waves); detail,
reviews, incidents and LOW rows in `.agents/gen/MASTER_REPORT.md` §6 and the
archived session reports. The last closed wave: item 23 = **S16 fragment
re-splits** (2026-09-25, gate 859 → 866/0, 0 HIGH / 0 MED / 4 LOW L212–L215,
no fixer).

## Handoff (live)

**Item 17 (S17 — jump gates to sector edges) is QUEUED and ready**; item 23
(S16) is closed and verified. The design lane's single live item is designer
item 14 = **D13 armory rework** (`dispatch_designer.md`). Everything else is
parked above pending owner ticks.
