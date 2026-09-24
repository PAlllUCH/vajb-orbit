# dispatch_coder.md — the code-lane queue of record

Rebuilt 2026-09-22, reorganised 2026-09-24 (open items only — closed work lives
in the Done pointer below, `MASTER_REPORT.md` and `_state/WAVEBOARD.md` §Closed).
Execute **one item per order**, close out per the brief's close-out section.
Model for every worker: `deepseek/deepseek-flash` (DeepSeek API direct, owner
ruling 2026-09-24; supersedes the same-day go order; fallback
`opencode-go/deepseek-v4.1-flash`) on `--reasoning-effort high`. The owner pastes
only the handoff block at the bottom.

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
| 16 | **S10 ARMORY interactivity** — the owner's live report (2026-09-24: cannot select a battery, cannot drag weapons onto racks, no per-battery ammo preview or stats); measured through real UI input, not direct handler calls; pins **STATION_HUB §5.11 + CONTRACTS §17/§16** | `.agents/gen/slices/S10-armory-racks/` | `S10_BRIEF.md` / `S10_prompts.md` | **A0 DISPATCHED 2026-09-24** (independent reproduction audit, measure only). Run: A0 → B1 fix (its brief written from A0's report) → R1 → F1 only on HIGH/MED. |
| 15 | **Flight-feel retune** (owner O4/O5: torque/slow-down, strafe/inertia) — pin **CONTRACTS §22** | not opened | — | **NUMBERS PROPOSED — waiting on your ticks.** §22 holds four tick-gated levers with worked rows + reversals: T1 `COAST_TIME_MULT` 2.0→2.5, T2 new `ANGULAR_DAMP_MULT` 0.5, T3 new `STRAFE_RATE_MULT` 0.75, T4 `LATERAL_DAMP_MULT` 1.0→0.6. Tick any subset in §22 → I write **S9**'s five-piece from the ticked table. Nothing dispatches until then. |

Beyond the queue: **slice 4's remainder** (quadrants/directional armour — 18
§4.5 + ruling 23; bosses/arena — 14 §5, blocked on P4 contracts + boss art).
Owner-locked homework stays the owner's (`18_engine_spec.md` §6/§13/§15, the
§13 turn/coast column ticks, slice 2.5's two calls).

## Done

Items 1–14 closed: chrome, combat repair, weapon FX (→ `MASTER_REPORT.md`);
P2-A `8d189bf`, Rock cleave `0e419f7`, P2-B1 `1f794cc`, P2-B `3e79e61` (→
`session_2026-09-22_items_4_to_7_report.md`, gate 437); S2.6 (457), S3 (493),
S4 (524), S5 (578), S6 (674), S7 (753), S8 (770) — detail, reviews, incidents
and LOW rows in `MASTER_REPORT.md` §6 +
`session_2026-09-24_items_8_to_13_report.md`; evidence archived in each
slice's `_archive/` (S8's still in its slice folder).

## Handoff (live)

Item 16 (**S10 ARMORY interactivity**) is dispatched: A0's reproduction audit is
running — brief and prompts in `slices/S10-armory-racks/`. Its report scopes the
fix wave (B1 → R1 → F1 only on HIGH/MED). Item 15 (flight-feel) still waits on
your ticks to CONTRACTS §22's T1–T4; slice 4's remainder needs its own
five-piece first.
