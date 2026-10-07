# D16_prompts.md — dispatch lines (design lane; run in the brief's order)

Model for every design worker: `opencode-go/mimo-v2.6-pro` (owner standing rule
2026-09-25) on `--reasoning-effort low`. Run order **A1 → R1**. Launch with
`run_in_background: true` and **wait on each** (`job_output`, `wait: true`); a
wedged worker is killed with python SIGKILL (wrapper AND inner pid) and
re-dispatched; re-check `git status` and the report file after any kill. Design
only — a worker writing code has failed its brief.

**Amended 2026-10-02 (owner, this wave's dispatch):** routes move for D16 — A1
runs `xiaomi/mimo-v2.6-pro` on `--reasoning-effort high` (design work), R1 runs
`hyper/glm-5.3-flash` on `--reasoning-effort high`. Two addenda ride the
prompts: UI_SPEC §3.10 now also carries **A5.4** (the per-surface chrome table,
D14 2026-09-26) so every surface names its A5.4 row or proposes one; and LOW
**L263** (the armory's four-cell SALVO drum) is in scope as a design row —
shipped assets only, a dedicated heavy-cadence icon is a *staged* row needing
generation budget (the 2026-09-27 no-AI-art gate stands; no render this wave),
and no code is touched.

**Before the first dispatch** (the five-piece is committed):

```bash
cd "$VAJB_WORKSPACE" \
  && python3 staging/verify_wave.py snapshot --name d16_start \
  && git tag d16_start
```

## D16-A1 — station identity & contracts UI (A1–A5)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='docs/design/,staging/mockup/,.agents/gen/slices/D16-station-ui/' \
     crush run "You are worker D16-A1, a design worker on the Vajb Orbit workspace, wave D16 (station identity and contracts UI design). Read .agents/gen/slices/D16-station-ui/D16_BRIEF.md end to end - its section 4's four rules bind every line you write - then SLICE.md. DESIGN ONLY: no code, no docs/gameplay, no CONTRACTS. Deliverables under UI_SPEC section 3.10 A5.1/A5.2's mechanism with the A5.4 per-surface chrome table as the second law - every surface names its A5.4 row or proposes one - using shipped chrome/Tokens only (rule 2 - every surface names its ASSET_CATALOG or theme cite): (A1) the CONTRACTS panel spec - row anatomy (type, objective, reward with the over-exchange note, faction), accept/cancel with the 100 CR cancel fee visible at the decision point, the escrow readout, the max-3 state, Expedition greyed as staged - with a mockup; (A2) the insurance and vaults panel specs - 14 section 3's premium rows per class with the one-death and mercy-clause states legible, section 4's vault tier rows (500/1200/2400, Meridian's 40-unit +25 percent note) and a contents view that says not-cargo - mockups included; (A3) the station identity treatment for the nine places of R-S24-1's table (name plate + character line + per-faction accent from existing chrome), one worked example per faction in mockup; (A4) the tick sheet: the nine names ready-to-tick (tick W3) plus every presentation value (labels, wordings) with reversals; (A4b) the armory SALVO drum design row answering LOW_BACKLOG L263 - the four-cell drum's treatment under A5 with shipped assets only, its own tick id and reversal, the dedicated heavy-cadence icon marked staged pending generation budget, no code touched; (A5) the report naming the owner rulings implemented (the A5 chrome law, D13 approach B where it carries over, the 2026-09-26 look-this-clean and anchors-and-relative-positioning rulings) and each panel's handoff as the design law S24/S25/S26 cite. Evidence cites on every row. Report slices/D16-station-ui/D16-A1_report.md (REPORT template, 120 lines max)." \
     -m xiaomi/mimo-v2.6-pro --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/d16_a1.log 2>&1
```

## D16-R1 — design review

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='docs/design/,.agents/gen/slices/D16-station-ui/D16-R1_review.md' \
     crush run "You are worker D16-R1, the design reviewer of wave D16 (brief .agents/gen/slices/D16-station-ui/D16_BRIEF.md; review against the brief's section 5 extract and UI_SPEC section 3.10 A5.1-A5.4, never against A1's report). Grade A1-A5 first: every panel shows exactly 14 sections 1-4/8's content and nothing invented (an invented service, price or reward line is HIGH); every surface names a shipped asset or theme idiom with its cite (a new-render proposal is HIGH - no generation budget); every row of A4 carries a value, a reversal and a tick id; the composition obeys A5.2's four clauses (coordinates-only layout is HIGH); the identity treatment covers all nine places and one worked example per faction; the A4b SALVO-drum row answers LOW_BACKLOG L263 with a value, a reversal and a tick id and proposes no render; A5's named rulings really are implemented by the text. Verify no file outside docs/design/, staging/mockup/ and the slice folder moved. Write slices/D16-station-ui/D16-R1_review.md (REVIEW template, 150 lines max), findings D16-A1/F## with tier and one evidence line each, LOW rows at the next free ids from .agents/gen/_state/LOW_BACKLOG.md at write time. Never fix A1's deliverables." \
     -m hyper/glm-5.3-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/d16_r1.log 2>&1
```

Never end the session while a worker is in flight; read each worker's report
file when its process exits (the logs are narration only).

## Handoff (paste at this item's turn)

```text
Read .agents/gen/dispatch_designer.md and execute queue item 17 only — D16 station identity & contracts UI design. Brief: .agents/gen/slices/D16-station-ui/D16_BRIEF.md. Prompts: .agents/gen/slices/D16-station-ui/D16_prompts.md. Snapshot + commit before the first dispatch, run A1 → R1 (design only — no fixer; a HIGH finding re-runs A1). Stop before item 18. Close out per the brief's close-out section (verify_wave.py verify --baseline d16_start, WAVEBOARD update, wave-boundary commit), then report back: the tick sheet's rows, the reviewer's findings by tier, and the bucket-3 escalations for me to rule.
```
