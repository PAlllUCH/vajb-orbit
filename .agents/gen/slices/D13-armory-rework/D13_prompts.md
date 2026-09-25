# D13_prompts.md — dispatch lines (one per worker; run in the brief's order)

Model for every worker: `opencode-go/mimo-v2.6-pro` (design lane, owner
standing rule 2026-09-25) on `--reasoning-effort low` (measured 2026-09-25:
`medium` stalls on long worker loops). Run order **A0 → R1 → (F1 only on
HIGH/MED)**. Every `crush run` is launched with `run_in_background: true` and
**waited on** (`job_output`, `wait: true`) before the next step or the end of
the session. If a worker wedges (0 sockets, frozen `/proc/<pid>/io`, ~0
CPU-sec), kill it with python SIGKILL — the wrapper AND the inner
`bin/crush run` pid — then re-dispatch; re-check `git status` and the report
file after any kill.

**Before the first dispatch** (the five-piece is already committed; this
takes the baseline and the evidence tag):

```bash
cd "$VAJB_WORKSPACE" \
  && python3 staging/verify_wave.py snapshot --name d13_start \
  && git tag d13_start
```

## D13-A0 — the rework design

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='staging/mockup/,.agents/gen/slices/D13-armory-rework/' \
     crush run "You are worker D13-A0 on the Vajb Orbit workspace, wave D13 (the armory rework DESIGN — you produce design, mockups and a tick list, never code). Read .agents/gen/slices/D13-armory-rework/D13_BRIEF.md end to end — its section 4's method and section 5's yardstick bind everything you produce — then SLICE.md, then the brief's law list in order (STATION_HUB 5.11 and its amendments, UI_SPEC 3.9 and 3.10 with Amendment 2, STYLE_BIBLE, 09 sections 11-12, CONTRACTS 17, all by range). Method, mandated by the owner: (1) VISION — view .agents/gen/slices/D13-armory-rework/_evidence/armory_live_1100.jpg first, then crop the pane, one bay, the ammunition half and the shell strip from armory_live_1920x1080.png with PIL (crops under 204800 bytes; this host has no screen-capture stack, pip is blocked, install nothing — the pinned capture is the vision input); judge the composition from the capture plus the brief's audit numbers, never from memory of similar UIs. (2) BRAINSTORMING — read ~/.local/share/crush/skills/brainstorming/SKILL.md by path and run its architectural path adapted to a dispatched worker: no dialogue partner, the owner tick list IS the approval gate, the hard gate means this wave writes design only. (3) REASONING — the report says what the pane is for, what today fails at per finding, what the reworked hierarchy is and why, every decision with its reason. (4) MOCKUPS — write staging/mockup/armory_mockup_v2.py on the station_mockup.py precedent (PIL, geometry and palette as source of truth, deterministic, no paid calls) and render one 1920x1080 mockup per approach into staging/mockup/out/ plus one owner sheet carrying the tick list as text. Deliver: 2-3 approaches with explicit trade-offs (fold, ink, hierarchy, the canvas pin), one recommended with reasons; every D12-A0 finding and LOW L208 addressed or explicitly deferred with a reason; the data model unchanged (5 batteries x 4 cells, pack cards, the 13/16 transactions, CONTRACTS 17); STYLE_BIBLE palette and type only, ink at least 13 px, text_dim at least 4.5 to 1, state never colour alone; the UI_SPEC 3.10 Amendment 2 canvas pin may be proposed changed but only marked PROPOSED with its reversal; every proposed value carries its reversal; zero writes outside staging/mockup/ and the slice folder — no vajb-orbit, no docs. Report .agents/gen/slices/D13-armory-rework/D13-A0_report.md (REPORT template, 120 lines max) with the today reading, the approaches, the recommended design in sections, the proposed values and reversals, the owner tick list, and the mockup paths." \
     -m opencode-go/mimo-v2.6-pro --reasoning-effort low --cwd "$VAJB_WORKSPACE" \
  > /tmp/d13_a0.log 2>&1
```

## D13-R1 — mandatory design review (after A0 reports)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='staging/mockup/,.agents/gen/slices/D13-armory-rework/' \
     crush run "You are worker D13-R1, the mandatory reviewer of wave D13 (brief .agents/gen/slices/D13-armory-rework/D13_BRIEF.md; diff findings against its section 5 yardstick and the pinned inputs, never against the designer's taste). Re-derive everything yourself: re-render every mockup from the committed script and require byte-identical output; view the mockups and the pinned evidence capture (armory_live_1100.jpg — crops via PIL under 204800 bytes, no re-capture, install nothing); check every D12-A0 finding and LOW L208 is addressed by the recommended design or explicitly deferred with a reason; check the data model is unchanged (5 x 4, pack cards, the 13/16 transactions, CONTRACTS 17), the palette and type are STYLE_BIBLE only, ink at least 13 px, text_dim at least 4.5 to 1, state never colour alone, no CSS idiom the engine cannot draw; check every proposed value carries its reversal and rides the tick list, and that the canvas pin is only PROPOSED, never assumed. Write .agents/gen/slices/D13-armory-rework/D13-R1_review.md (REVIEW template, 150 lines max), findings D13-A0/F## with tier and one evidence line each; an invented datum, a dropped datum or an unmarked assumption is HIGH. Never fix the design yourself. Bounded renders only, no paid calls." \
     -m opencode-go/mimo-v2.6-pro --reasoning-effort low --cwd "$VAJB_WORKSPACE" \
  > /tmp/d13_r1.log 2>&1
```

## D13-F1 — fixer (only if R1 leaves HIGH or MED)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='staging/mockup/,.agents/gen/slices/D13-armory-rework/' \
     crush run "You are worker D13-F1, the fixer of wave D13 (brief .agents/gen/slices/D13-armory-rework/D13_BRIEF.md; review .agents/gen/slices/D13-armory-rework/D13-R1_review.md). Fix ONLY the HIGH and MED findings at their named file:line — in the mockup script, the renders and the report; no LOW items, no re-design beyond the findings, no code, no docs. Re-render every mockup byte-identically from the fixed script and report .agents/gen/slices/D13-armory-rework/D13-F1_report.md with a finding-by-finding disposition." \
     -m opencode-go/mimo-v2.6-pro --reasoning-effort low --cwd "$VAJB_WORKSPACE" \
  > /tmp/d13_f1.log 2>&1
```

Never end the session while a worker is in flight; read each worker's report
file when its process exits (the logs are narration only).
