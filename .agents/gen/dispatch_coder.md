# dispatch_coder.md — the code-lane queue of record

Rebuilt 2026-09-22 after the purge; reorganised 2026-09-24 (this file now carries
**open items only** in the queue — everything done lives in the Done list, with
detail in `MASTER_REPORT.md` and `_state/WAVEBOARD.md` §Closed). Execute **one
item per order**, close out per the brief's close-out section before starting the
next. Model for every worker: `deepseek/deepseek-v4-flash` (owner instruction
2026-09-22; `opencode-go/deepseek-v4.1-flash` is broken). Briefs and prompts live
in the slice folders; the owner pastes only the short handoff paragraph.

**File-collision law:** two waves may never hold one file at once (nor the same
`test_*` prefix, nor one `staging/` driver). **Parallelism:** builders *inside*
one wave may run concurrent when pairwise file-disjoint; *across* waves only with
provably disjoint write sets and test prefixes (the S5∥D6 precedent) — everything
else is sequential, because waves share the gate close-out and git state (L82:
one live session per workspace).

**Wave anatomy (every wave):** the docs-first five-piece (docs amendments →
`<WaveID>_BRIEF.md` → `<WaveID>_prompts.md` → queued here **and** in
`_state/WAVEBOARD.md` → the short handoff paragraph), then `verify_wave.py
snapshot` + commit → docs-drift worker → builders → review → fixer only on
HIGH/MED → the brief's close-out (gate ×2 hermetic, `verify_wave.py verify`,
CONTRACTS §9/§10 measured notes, WAVEBOARD update, wave-boundary commit).

## Open queue

| # | Wave | Slice folder | Brief / prompts | Status |
|---|---|---|---|---|
| 12 | **Engine slice 3 (Travel) merged with RPG P3** — gates, corridors, POIs, scanner, sector transitions + heat/hunters; sector registry, anomalies, derelicts, loot tables (17 §1 P3) | `slices/S6-travel/` | `S6_BRIEF.md` / `S6_prompts.md` | **BRIEFED 2026-09-24** (docs-first landed: CONTRACTS §19 + v0.11, 11 §5, 13 §7, 06 §8, 01 §5.2) — ready to dispatch; parallel-safe with D6 (disjoint sets) |
| 13 | **Affix-application wave** (15 §9.3 — apply the stored affixes to stats; S3 stores/prices/names/displays but applies none) | not opened | — | NOT BRIEFED — S3 tick 6 ("whether to schedule") gates it |

Next beyond the queue: owner-locked homework stays the owner's —
`18_engine_spec.md` §6/§13/§15 (the cleaving amendment + `FRAGMENT_OUTWARD_KICK`
+ the two flight multipliers; §15's test checklist now contradicts the shipped
suite), the §13 turn/`coast_time` column ticks, slice 2.5's two calls.

## Done (items 1–11)

1–3 (chrome, combat repair, weapon FX) — closed 2026-09-21, see
`MASTER_REPORT.md`. 4 P2-A ship slot frames (`8d189bf`), 5 Rock cleave
(`0e419f7`), 6 P2-B1 weapon fit (`1f794cc`), 7 P2-B proper fitting panel
(`3e79e61`) — closed 2026-09-22, gate 437, see
`session_2026-09-22_items_4_to_7_report.md`. 8 S2.6 truth-and-feel (`8d0691d`,
gate 457; owner requests #5–#7 landed here: fragment outward kick, beam-hit
scatter, beam sink), 9 S3 the item economy (gate 493), 10 S4 weapon batteries
(gate 524) — closed 2026-09-22/23. **11 S5 playtest fixes** (auction family tabs,
shipyard hangar, ARMORY drag-and-drop mixed batteries, ammo-as-cargo, hardpoints
+ `track_dps`) — closed 2026-09-24, gate 524 → **578/0** hermetic (orchestrator
re-verified twice on scratch stores 2026-09-24); reports
`slices/S5-playtest-fixes/`, see `WAVEBOARD.md` §Closed.
