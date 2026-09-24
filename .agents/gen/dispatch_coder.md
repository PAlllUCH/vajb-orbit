# dispatch_coder.md — the code-lane queue of record

Rebuilt 2026-09-22, reorganised 2026-09-24 (open items only — closed work lives
in the Done pointer below, `MASTER_REPORT.md` and `_state/WAVEBOARD.md` §Closed).
Execute **one item per order**, close out per the brief's close-out section.
Model for every worker: `opencode-go/deepseek-v4.1-flash` (owner order
2026-09-24; fallback `deepseek/deepseek-v4-flash`). The owner pastes only the
handoff block at the bottom.

**File-collision law:** two waves never hold one file (nor the same `test_*`
prefix, nor one `staging/` driver). Across lanes only with provably disjoint
write sets (the S5∥D6 precedent); one live session per workspace (L82).
**Wave anatomy:** docs-first five-piece → `verify_wave.py snapshot` + commit →
Q0/K0 dispositions into CONTRACTS → builders → review → fixer only on
HIGH/MED → close-out (gate ×2 hermetic, `verify --baseline`, §9/§10 sequenced
with any parallel lane, WAVEBOARD, wave-boundary commit).

## Open queue

| # | Wave | Slice folder | Brief / prompts | Status |
|---|---|---|---|---|
| 14 | **S8 QA playtest fixes** — the independent review's 2 HIGH / 6 MED + copy/naming/warning bundle + the owner's O1–O3 (FITTING drag, weapon groups, ram strength); pin **CONTRACTS §21** | `.agents/gen/slices/S8-qa-fixes/` | `S8_BRIEF.md` / `S8_prompts.md` | **READY.** Docs-first landed (§21 + O-table, v0.18, 05 §9). Run: Q0 → dispositions → Q1 → Q2 → R1 → F1 only on HIGH/MED. Parallel-legal with designer item 13 (D11) — disjoint sets; both briefs carry the cross-lane attribution rules. |
| 15 | **Flight-feel retune** (owner O4/O5: torque/slow-down, strafe/inertia) — pin **CONTRACTS §22** | not opened | — | **NUMBERS PROPOSED — waiting on your ticks.** §22 holds four tick-gated levers with worked rows + reversals: T1 `COAST_TIME_MULT` 2.0→2.5, T2 new `ANGULAR_DAMP_MULT` 0.5, T3 new `STRAFE_RATE_MULT` 0.75, T4 `LATERAL_DAMP_MULT` 1.0→0.6. Tick any subset in §22 → I write **S9**'s five-piece from the ticked table. Nothing dispatches until then. |

Beyond the queue: **slice 4's remainder** (quadrants/directional armour — 18
§4.5 + ruling 23; bosses/arena — 14 §5, blocked on P4 contracts + boss art).
Owner-locked homework stays the owner's (`18_engine_spec.md` §6/§13/§15, the
§13 turn/coast column ticks, slice 2.5's two calls).

## Done

Items 1–13 closed: chrome, combat repair, weapon FX (→ `MASTER_REPORT.md`);
P2-A `8d189bf`, Rock cleave `0e419f7`, P2-B1 `1f794cc`, P2-B `3e79e61` (→
`session_2026-09-22_items_4_to_7_report.md`, gate 437); S2.6 (457), S3 (493),
S4 (524), S5 (578), S6 (674), S7 (753) — detail, reviews, incidents and LOW
rows in `WAVEBOARD.md` §Closed +
`session_2026-09-24_items_8_to_13_report.md`; evidence archived in each
slice's `_archive/`.

## Handoff (live — paste as one block)

```text
Read .agents/gen/dispatch_coder.md and execute queue item 14 only — S8, the QA playtest fixes (CONTRACTS §21, incl. the owner O1–O3 table). Brief: .agents/gen/slices/S8-qa-fixes/S8_BRIEF.md. Prompts: .agents/gen/slices/S8-qa-fixes/S8_prompts.md. Snapshot + commit (s8_start) before the first dispatch, apply Q0's dispositions to §21 in one commit before Q1, run Q0 → Q1 → Q2 → R1, and the fixer only if the review leaves HIGH or MED. This may run parallel with designer item 13 (D11 station scene): you hold the S8 write sets — never touch game/sector.gd, game/station_scene.gd, assets/env/**, staging/**, tests/test_d11_*, project.godot, or docs/ beyond Q0's disposition pass and R1's §9/§10; take CONTRACTS §9/§10 as the next free rows read at close-out, sequenced after D11's (rebase, never revert), and attribute any D11 rows in the gate. Close out per the brief's close-out section (gate ×2 scratch stores, verify --baseline s8_start, WAVEBOARD update, wave-boundary commit), then report back: the measured gate count, Q0's dispositions, the builders' per-AC numbers, the reviewer's findings by tier, and S8's owner ticks (incl. O3's ram factor and the O1/O2 UX call).
```
