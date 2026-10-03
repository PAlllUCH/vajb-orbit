# D18_prompts.md — dispatch lines (design lane; run in the brief's order)

Models (owner, 2026-10-03): A1 = `hyper/glm-5.3` on `--reasoning-effort high`
(the demanding slot — "go with glm5.3 on very demanding"), R1 =
`hyper/glm-5.3-flash` on `--reasoning-effort high`. Launch with
`run_in_background: true` and **wait on each** (`job_output`, `wait: true`);
a wedged worker is killed with SIGKILL (wrapper AND inner pid) and
re-dispatched; re-check `git status` and the report file after any kill.
Design only — a worker writing code has failed its brief.

**Before the first dispatch** (the five-piece is committed):

```bash
cd "$VAJB_WORKSPACE" \
  && python3 staging/verify_wave.py snapshot --name d18_start \
  && git tag d18_start
```

## D18-A1 — map deck & panel consolidation design (A1–A6)

```bash
cd "$VAJB_WORKSPACE" \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='docs/design/,staging/mockup/,.agents/gen/slices/D18-map-panels/' \
     crush run "You are worker D18-A1, a design worker on the Vajb Orbit workspace, wave D18 (map deck and station panel consolidation design). Read .agents/gen/slices/D18-map-panels/D18_BRIEF.md end to end - its section 4's four rules bind every line you write - then SLICE.md, then the three pin blocks: docs/design/UI_SPEC.md section 8 and section 9, docs/design/STATION_HUB.md section 16, and docs/gameplay/10_ship_acquisition.md's 2026-10-03 block (read-only). DESIGN ONLY: no code, no docs/gameplay, no CONTRACTS. The pins are law: a number you believe is wrong gets reported, not changed. Deliverables, under UI_SPEC section 3.10 A5.1-A5.4's mechanism with shipped chrome/Tokens only - every surface names its A5.4 row or theme idiom with its ASSET_CATALOG or theme cite: (A1) the map deck spec and wireframes - expansion toggle N1, pan and zoom and arrow panning N2, the filter column with per-profile persistence N3, deck chrome on A5.4 pane rows, the compact minimap's pin bearing arrow and always-on station and gate blips N6; (A2) the navigation pin spec and wireframes - place, move and remove, the autopilot order on the existing API (game/player_ship.gd:419), stick-cancel, the hold-LMB 0.5 s hyperdrive jump with its NO HYPERDRIVE INSTALLED caption, and the N5 module's UX - spool, cooldown read, arrival state; (A3) the merged ARMORY panel spec and wireframe on STATION_HUB 16's P4 pin - ship grid left, inventory browser right with the auction filter-tab strip (auction_panel.gd:82-100 idiom), drag and drop filtered by slot with the wrong-slot refusal that is label plus caption flash, never colour alone, the buy-into-cell one flow, hover describing through the existing inspector signal chain; (A4) the merged SHIPYARD panel spec and wireframe on the P5 pin - labelled hull stat pairs, comparison block, the selected hull's installed modules shown, the repair block with NOMINAL copy and the fee in the footer, hover describing everywhere; (A5) the tick sheet detail - every new wording as an N or P row with value, reversal and tick id, continuing N7, P8 and onward, plus the P6 inspector lifecycle law text and the P7 one-panel template and six-entry rail as one spec block; (A6) the report naming the owner rulings implemented - the 2026-10-03 ruling, the A5 chrome law, D13 approach B where it carries over, the 2026-09-26 look-this-clean and anchors-and-relative-positioning rulings - and mapping each deliverable to S29's citation list. Mockups are markdown wireframes in staging/mockup/ (the D16-precedented form). Evidence cites on every row. Report slices/D18-map-panels/D18-A1_report.md (REPORT template, 120 lines max)." \
     -m hyper/glm-5.3 --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/d18_a1.log 2>&1
```

## D18-R1 — design review

```bash
cd "$VAJB_WORKSPACE" \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='docs/design/,.agents/gen/slices/D18-map-panels/D18-R1_review.md' \
     crush run "You are worker D18-R1, the design reviewer of wave D18 (brief .agents/gen/slices/D18-map-panels/D18_BRIEF.md; review against the brief's section 5 extract, UI_SPEC section 8 and 9, STATION_HUB section 16 and UI_SPEC section 3.10 A5.1-A5.4 - never against A1's report). Grade A1-A6 first: every mockup and spec row sits on its pinned N or P value (a number drifting from the pin is HIGH); every surface names a shipped asset or theme idiom with its cite (a new-render proposal is HIGH - no generation budget); every new wording carries a tick id and a reversal; the composition obeys A5.2's four clauses (coordinates-only layout is HIGH); the drag-and-drop law refuses wrong-slot drops by label plus caption, never colour alone; the merged panels really show the owner's asks - equipped items on the hull in shipyard, hover describing into the bottom inspector, buy and fit as one flow; the rail reads six entries; A6's named rulings really are implemented by the text. Verify no file outside docs/design/, staging/mockup/ and the slice folder moved. Write slices/D18-map-panels/D18-R1_review.md (REVIEW template, 150 lines max), findings D18-A1/F## with tier and one evidence line each, LOW rows at the next free ids from .agents/gen/_state/LOW_BACKLOG.md at write time. Never fix A1's deliverables." \
     -m hyper/glm-5.3-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/d18_r1.log 2>&1
```

Never end the session while a worker is in flight; read each worker's report
file when its process exits (the logs are narration only).
