# S29_prompts.md — dispatch lines (coder lane; run in the brief's order)

Models (owner, 2026-10-03): B1/B2 = `hyper/glm-5.3` @ high (very demanding);
R1 = `hyper/glm-5.3-flash` @ high. Launch with `run_in_background: true` and
**wait on each** — B2 starts only after B1's process exits. Bound every game
run with `--quit-after`; redirect probe output to logs.

**Before the first dispatch** (the five-piece is committed):

```bash
cd "$VAJB_WORKSPACE" \
  && python3 staging/verify_wave.py snapshot --name s29_start \
  && git tag s29_start
```

The gate (×2 fresh scratch, `XDG_DATA_HOME=$(mktemp -d)` each run;
`~/.local/bin/godot` on this host):

```bash
$GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200
```

## S29-B1 — the flight half (A1–A3)

```bash
cd "$VAJB_WORKSPACE" \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/ui/hud/,vajb-orbit/game/,vajb-orbit/tests/,.agents/gen/slices/S29-consolidation/' \
     crush run "You are worker S29-B1, the flight-half coder of wave S29 (panel consolidation and the map deck). Read .agents/gen/slices/S29-consolidation/S29_BRIEF.md end to end - its section 4's four rules bind every change - then SLICE.md, then the law: docs/design/UI_SPEC.md sections 9 and 10 (N1-N23, including the fixer's pin-precedence, pin-placement and toggle-to-blip-class laws), docs/gameplay/10_ship_acquisition.md's 2026-10-03 block (the e_hyperdrive row, read-only), and UI_SPEC section 3.10 A5.1-A5.4. Your half: A1 the map deck - expansion on M, the corner button and ESC (N1), LMB-drag pan, wheel zoom 25-400 percent and 64 px arrow steps (N2), the filter column with the eight toggles and per-profile persistence (N3), the new blip classes KIND_STATION, KIND_GATE, KIND_ASTEROID_FIELD, KIND_POI, KIND_WRECK, KIND_CONTRACT (N15-N18, N21-N22), KIND_GHOST riding POIs (N19), HOSTILES riding KIND_HOSTILE plus KIND_SWARMER (N20), the inert-toggle rule for unshipped classes (N23), always-on station and gate blips anchored on the new classes (N6), deck chrome on A5.4 rows; A2 the navigation pin - a press that hit-tests the pin is a remove candidate never a place or move, the pin is placed at press-down and never follows the cursor, a held move past the 8 px threshold is a pan (N14), the short press issues the existing autopilot order (player_ship.gd:419), stick input cancels (:816), hold LMB at least 0.5 s jumps to the pin when a hyperdrive is installed with the NO HYPERDRIVE INSTALLED caption otherwise, the N5 reads (1 s spool, 30 s cooldown, arrival), the compact minimap's bearing arrow and distance read; A3 the hyperdrive module - the e_hyperdrive row exactly as 10's 2026-10-03 block pins it (tier 3, engine slot, 12000 CR, draw 3, one jump per 30 s, 1 s spool, no fuel charge) in the module catalogue and the auction SOURCE_ROLLS engine column - the armory browser surface is B2's. Containers and anchors only, never coordinates; no new art, no new hue; no doc edits. Run the gate twice on fresh scratch and record both [SUMMARY] lines; zero failures is the law. Disclose every moved test row with suite and line. Report slices/S29-consolidation/S29-B1_report.md (REPORT template, 120 lines max) answering A1-A3 each with a cite." \
     -m hyper/glm-5.3 --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s29_b1.log 2>&1
```

## S29-B2 — the station half (A4–A7), after B1 exits

```bash
cd "$VAJB_WORKSPACE" \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/ui/screens/,vajb-orbit/ui/station/,vajb-orbit/tests/,.agents/gen/slices/S29-consolidation/' \
     crush run "You are worker S29-B2, the station-half coder of wave S29 (panel consolidation and the map deck). Read .agents/gen/slices/S29-consolidation/S29_BRIEF.md end to end - its section 4's four rules bind every change - then SLICE.md and your partner's report S29-B1_report.md (B1 already landed the hyperdrive catalogue row and the map half; do not touch vajb-orbit/ui/hud/ or vajb-orbit/game/), then the law: docs/design/STATION_HUB.md sections 16 and 17 (P4-P14, the merged-panel detail, the P6 lifecycle and P7 template), docs/design/UI_SPEC.md section 8 (P1-P3 button and focus law) and section 3.10 A5.1-A5.4, and the wireframes staging/mockup/d18_armory_wireframe.md and d18_shipyard_wireframe.md (the design of record). Your half: A4 the merged ARMORY per P4 and section 17 - the fitting ship grid left on its own numbers, the inventory browser right with the auction tab strip minus HULLS, every row draggable, cells accept drops filtered by slot, the wrong-slot refusal as status line plus 0.5 s slot-caption flash never colour alone, the buy-into-cell one flow with the credits check first, hover describing through the existing inspector chain, the e_hyperdrive visible in the browser at tier 3; A5 the merged SHIPYARD per P5 and section 17 - labelled hull stat pairs, the comparison block, the selected hull's installed modules shown, the repair block with NOMINAL rows and no MISSING or FEE body rows with the fee in the footer, REPAIR as ActionPrimary, hover describing everywhere; A6 the shell - the rail folds 8 to 6 (ARMORY, REFINERY, EXCHANGE, AUCTION, SHIPYARD, LAUNCH), the inspector fills with the SHIPYARD and LAUNCH summaries when idle, the P7 one-panel template, and P1-P3 buttons and focus on the merged panels; A7 the D17 leftovers inside the merged panels - no DROP HERE ghosts on empty cells, fit confirm and refuse toasts, cell tooltips plus the CANDIDATE rename, hull-comparison deltas, the REPAIRS dead band resolved, scroll affordances where rows overflow. Containers and anchors only, never coordinates; no new art, no new hue; no doc edits. Run the gate twice on fresh scratch and record both [SUMMARY] lines; zero failures is the law. Disclose every moved test row with suite and line - the brief's section 8 names the expected movers (test_d7_armory, test_s10_armory_input, test_s15, test_s11_inspector, test_s21_stability, test_p1_repairs, test_p2b_services, the fitting and shipyard suites, plus the new test_s29 rows). Report slices/S29-consolidation/S29-B2_report.md (REPORT template, 120 lines max) answering A4-A7 each with a cite." \
     -m hyper/glm-5.3 --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s29_b2.log 2>&1
```

## S29-R1 — review (after B2)

```bash
cd "$VAJB_WORKSPACE" \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/ui/,vajb-orbit/game/,vajb-orbit/tests/,.agents/gen/slices/S29-consolidation/S29-R1_review.md' \
     crush run "You are worker S29-R1, the reviewer of wave S29 (brief .agents/gen/slices/S29-consolidation/S29_BRIEF.md; review against the brief's section 5 extract, UI_SPEC sections 9, 10 and 8, STATION_HUB sections 16 and 17, and A5.1-A5.4 - never against the builders' reports). Grade A1-A8 first: every mechanic sits on its pinned N or P value (a drift is HIGH); the pin precedence, placement and pan threshold match the fixer's law exactly; the blip classes and the N23 inert rule are real; the hyperdrive row matches 10's 2026-10-03 block figure by figure; the merged panels show the owner's asks - the hull's installed modules, hover describing into the bottom inspector, buy and fit one flow, drag and drop filtered by slot with the label-plus-caption refusal; the rail reads six entries; A7's leftovers are gone; a coordinate layout is HIGH; a button off the two tokens is HIGH; the gate ran twice with zero failures - re-run it once yourself on fresh scratch and record the [SUMMARY]; every moved test row is disclosed with suite and line, an undisclosed moved row is MED; no file outside the declared union moved (docs and assets: untouched, HIGH). Update CONTRACTS.md per the brief's close-out only if a seam you measured changed, with the cite. Write slices/S29-consolidation/S29-R1_review.md (REVIEW template, 150 lines max), findings S29-B1/F## or S29-B2/F## with tier and one evidence line each, LOW rows at the next free ids from .agents/gen/_state/LOW_BACKLOG.md at write time. Never fix the builders' deliverables." \
     -m hyper/glm-5.3-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s29_r1.log 2>&1
```

## S29-F1 — fixer (only if the review leaves HIGH or MED)

Same shape as the owning builder's command, worker id S29-F1, the review's
finding list pasted in, `-m hyper/glm-5.3` @ high for deep cures or
`hyper/glm-5.3-flash` for small ones, cure note appended to the builder's
report. Gate twice again.

Never end the session while a worker is in flight; read each worker's report
file when its process exits (the logs are narration only).
