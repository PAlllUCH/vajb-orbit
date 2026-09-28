# D15_prompts.md — dispatch lines (design lane; run in the brief's order)

Model for every design worker: `opencode-go/mimo-v2.6-pro` (owner standing rule
2026-09-25) on `--reasoning-effort low` (measured: `medium` stalls on long
worker loops). Run order **A1 → R1**. Launch with `run_in_background: true` and
**wait on each** (`job_output`, `wait: true`); a wedged worker is killed with
python SIGKILL (wrapper AND inner pid) and re-dispatched; re-check `git status`
and the report file after any kill. Design only — a worker writing code has
failed its brief.

**Before the first dispatch** (the five-piece is committed):

```bash
cd "$VAJB_WORKSPACE" \
  && python3 staging/verify_wave.py snapshot --name d15_start \
  && git tag d15_start
```

## D15-A1 — the feel sheet + feedback composition

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='docs/design/,staging/mockup/,.agents/gen/slices/D15-flight-feedback/' \
     crush run "You are worker D15-A1, a design worker on the Vajb Orbit workspace, wave D15 (flight feel and feedback design). Read .agents/gen/slices/D15-flight-feedback/D15_BRIEF.md end to end - its section 4's four rules bind every line you write - then SLICE.md. DESIGN ONLY: no code, no docs/gameplay, no CONTRACTS. Deliverables: (A1) the resolved feel tick sheet - every row of slices/S22-feel-and-juice/S22_BRIEF.md section 11 (T-feel-1..7) plus 09 section 3.3's S19 T1-T7, CONTRACTS section 22's T3, and L39/L103/L182/L57 - as row | PROPOSED value | reversal | tick id | the section text it implements, ready for the owner to tick (unticked rows implement at the PROPOSED value; call out any bucket-3 escalation where a row supersedes an owner ruling); (A2) dated amendment block drafts for docs/design/FX_SPEC.md (the chip-spark 3-object master correction, the low-hull arc interval row per L55, L59/L64's unstated rates and world sizes pinned as rows, L57's disposition) and docs/design/AUDIO_SPEC.md (section 8's mine_drop row - the cue is CC0 sourced through assetmcp per AGENTS.md - plus section 4.1's anti-flam wiring note and L49's trim disposition), each row with its reversal and tick id; (A3) the feedback composition - where the quadrant feed lands on the status screen, the hit marker's visual verb, the ram spark's placement - specified under UI_SPEC section 3.10 A5.2's mechanism with a mockup or labelled sketch in staging/mockup/, naming the owner rulings you implement (ruling 18 speed fantasy, ruling 23 quadrants, the A5 chrome law); (A4) the report naming every owner ruling implemented and every escalation. Evidence cites (file:line or doc section) on every row. Report slices/D15-flight-feedback/D15-A1_report.md (REPORT template, 120 lines max)." \
     -m opencode-go/mimo-v2.6-pro --reasoning-effort low --cwd "$VAJB_WORKSPACE" \
  > /tmp/d15_a1.log 2>&1
```

## D15-R1 — design review

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='docs/design/,.agents/gen/slices/D15-flight-feedback/D15-R1_review.md' \
     crush run "You are worker D15-R1, the design reviewer of wave D15 (brief .agents/gen/slices/D15-flight-feedback/D15_BRIEF.md; review against the brief's section 5 extract and UI_SPEC section 3.10 A5.2, never against A1's report). Grade A1-A4 first: every tick-sheet row carries a value, a reversal, a tick id and a source cite (an unsourced row is HIGH); every proposed number is consistent with 18 section 3's feedback-only rule or names its gameplay consequence; the FX/AUDIO amendment drafts change no existing section text (blocks append only) and cover exactly L48/L49/L55/L57/L59/L64's asks; the composition obeys A5.2's four clauses and uses shipped assets only (a re-cut proposal is HIGH - no generation budget this round); every owner ruling named in A3/A4 really is implemented by the text. Verify no file outside docs/design/, staging/mockup/ and the slice folder moved (diff the tree). Write slices/D15-flight-feedback/D15-R1_review.md (REVIEW template, 150 lines max), findings D15-A1/F## with tier and one evidence line each, LOW rows at the next free ids from .agents/gen/_state/LOW_BACKLOG.md at write time. Never fix A1's deliverables." \
     -m opencode-go/mimo-v2.6-pro --reasoning-effort low --cwd "$VAJB_WORKSPACE" \
  > /tmp/d15_r1.log 2>&1
```

Never end the session while a worker is in flight; read each worker's report
file when its process exits (the logs are narration only).

## Handoff (paste at this item's turn)

```text
Read .agents/gen/dispatch_designer.md and execute queue item 16 only — D15 flight feel & feedback design. Brief: .agents/gen/slices/D15-flight-feedback/D15_BRIEF.md. Prompts: .agents/gen/slices/D15-flight-feedback/D15_prompts.md. Snapshot + commit before the first dispatch, run A1 → R1 (design only — no fixer; a HIGH finding re-runs A1). Stop before item 17. Close out per the brief's close-out section (verify_wave.py verify --baseline d15_start, WAVEBOARD update, wave-boundary commit), then report back: the tick sheet's rows, the reviewer's findings by tier, and the bucket-3 escalations for me to rule.
```
