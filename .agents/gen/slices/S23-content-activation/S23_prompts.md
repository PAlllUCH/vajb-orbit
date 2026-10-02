# S23_prompts.md — dispatch lines (one per worker; run in the brief's order)

Model for every worker: **`hyper/glm-5.3-flash` on `--reasoning-effort max`** (the
owner's S22.7 mid-wave ruling: never `opencode-go`; this file's original
`deepseek/deepseek-flash` line is superseded by it).
Run order **B1 → R1 → (F1 only on HIGH/MED)**. Launch every `crush run` with
`run_in_background: true` and **wait on it** (`job_output`, `wait: true`). A
wedged worker (0 sockets, frozen I/O) is killed with python SIGKILL — wrapper
AND inner `bin/crush run` pid — then re-dispatched; re-check `git status` and
the report file after any kill.

**Before the first dispatch** (the five-piece + the brief's 2026-10-01 amendment
are committed; the tree carries no other work):

```bash
cd "$VAJB_WORKSPACE" \
  && python3 staging/verify_wave.py snapshot --name s23_start \
  && git tag -f s23_start
```

**Wave facts the dispatch text carries (the brief's §0 amendment, 2026-10-01):**
the owner delegated the P3 blocks' open values to the developer (V1–V5 in the
brief), the S22.8 cadence law is live (18 §4.1's amendment: spam vs cooldown
tiers — `w_proton` cools 12 s, `w_flak` stays spam at 0.55 s), the F1 credits
section is **A8**, and every sprite the wave needs already ships in
`vajb-orbit/assets/` (verified 2026-10-01) — no `staging/roster/` work unless a
referenced file is missing.

## S23-B1 — the content activation (A1–A7)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/ui/,vajb-orbit/tests/,vajb-orbit/assets/,staging/roster/,.agents/gen/slices/S23-content-activation/S23-B1_report.md' \
     crush run "You are worker S23-B1 on the Vajb Orbit workspace, wave S23 (content activation - the dead-content wave). Read .agents/gen/slices/S23-content-activation/S23_BRIEF.md end to end - its section 4's five rules bind every line you write, and its section 0 amendment (2026-10-01) carries the owner-delegated values V1-V5 you implement - then SLICE.md. Task: land A1-A8 exactly: the w_proton and w_flak firing families with their ammo packs under the S22.8 cadence law (A1, rows R-S23-1/2 in docs 09's 2026-09-27 P3 block read through brief V5: the proton joins the cooldown tier at 12 s, the flak stays spam at its 0.55 s interval; the pack rows are V1's: proton 40 rounds/400 CR max 60, flak 300/260 max 300, icons borrow the rocket/cannon glyphs; the 15 section 5 exclusivity law untouched), the three dead module effects end-to-end (A2: c_ewar slows enemy targeting 25/35 percent in scan, u_refine halves the refinery fee for its ore, u_drones regenerates 2 hull/s in space), the seven stock fits (A3, R-S23-3's table - 09 section 9's own table is already amended to the new rows; re-derive tests/test_ship_grids.gd's transcribed const to match), the sibelon seam released plus the interceptor and turret-platform hull rows resolving the hunter/turret maps (A4, R-S23-4/5; the sibelon flies the corvette column per brief V2 with the corvette loot table and a global HOSTILE_FILL third entry; the station turret only if tick C6 is ticked - rule 5), per-hull flight sprites with matching colliders and FX anchors scaled off the drawn hull, faction liveries on hunters/pirates and the damaged Vanguard in REPAIRS/LAUNCH (A5, L137 - every sprite already ships in vajb-orbit/assets, so no pipeline work: wire the per-hull visuals off the existing files and run validate_names.py --library to prove every referenced name resolves; the world-length ladder is brief V3, the Vanguard frozen at its shipped scale and radius), and the loot rows (A6: cm_chaff/cm_flare catalogue rows in component_catalog.gd so uncatalogued_items() is empty, HUNTER_EXTRA promoted to the hunter table without double-rolling the band, caches x1/1.5/2 by sector tier per 06 section 7 - derive the sector tier from the registry's tier-mix index and record the mapping). Plus A8 (brief V4): the F1 developer overlay (ui/dev/dev_tuning_menu.gd) gains a CREDITS section - an integer amount field defaulting to 1000 and Add/Remove buttons calling PlayerProfile.add_credits(+-n), a status line reporting the new balance, a no-op when no profile is in the tree, and the boot law untouched (the overlay still reads nothing until opened); its test rows join tests/test_s13_devmenu.gd. Docs and autoload/ and project.godot are read-only. New suite tests/test_s23_content.gd (one row per AC A1-A7; A8's rows live in test_s13_devmenu.gd); headless gate twice on fresh scratch XDG_DATA_HOME stores, record both [SUMMARY] lines. Report slices/S23-content-activation/S23-B1_report.md (REPORT template, 120 lines max) answering A1-A8 with cites plus the validate_names summary line." \
     -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s23_b1.log 2>&1
```

## S23-R1 — mandatory review (after B1 reports)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S23-content-activation/S23-R1_review.md' \
     crush run "You are worker S23-R1, the mandatory reviewer of wave S23 (brief .agents/gen/slices/S23-content-activation/S23_BRIEF.md - grade A8 and the section 0 amendment's V1-V5 values as the developer-assumed law; diff findings against its section 5 extract and the 2026-09-27 P3 blocks read through 18 section 4.1's S22.8 cadence amendment, never against B1's report). Grade A1-A8 first, re-measuring yourself on scratch stores (W8's byte-identical replay): both new families firing and spending their packs at their S22.8 cadences (proton cooldown 12 s, flak spam), the exclusivity floors, each dead-module effect at its measured value (probe the 25/35 percent slow, the halved fee against the 3:1 unchanged, the 2/s regen), every stock fit launching on its hull, sibelon spawning with loot on the corvette column, the hunter/turret hull rows, the per-hull sprite/collider/anchor correctness on at least two non-Vanguard hulls (L137's whole point) with the V3 ladder, the asset provenance (every referenced sprite resolves in-project; validate_names --library green), the loot rows incl. uncatalogued_items() empty and the cache multipliers, and the F1 credits section (add/remove through the profile API, the 0 floor, the untouched boot law). Diff moved gate rows against section 8's list; an unlisted row moved or a pinned value that moved is HIGH. A value written without its P3 row or its V-row is HIGH. Update docs/CONTRACTS.md section 9/10 at the next free rows read at write time. Write slices/S23-content-activation/S23-R1_review.md (REVIEW template, 150 lines max), findings S23-B1/F## with tier and one evidence line each, LOW rows at the next free ids from .agents/gen/_state/LOW_BACKLOG.md at write time. Never fix code. Bounded probes only." \
     -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s23_r1.log 2>&1
```

## S23-F1 — fixer (only if R1 leaves HIGH or MED)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/ui/,vajb-orbit/tests/,vajb-orbit/assets/,staging/roster/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S23-content-activation/' \
     crush run "You are worker S23-F1, the fixer of wave S23 (brief .agents/gen/slices/S23-content-activation/S23_BRIEF.md; review .agents/gen/slices/S23-content-activation/S23-R1_review.md). Fix ONLY the HIGH and MED findings at their named file:line; adjust tests only where a fix changes what is proven. No LOW items, no refactors, no pinned value changed. Re-run the gate twice on fresh scratch stores and report slices/S23-content-activation/S23-F1_report.md with a finding-by-finding disposition and both gate lines." \
     -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s23_f1.log 2>&1
```

Never end the session while a worker is in flight; read each worker's report
file when its process exits (the logs are narration only).

## Handoff (paste at this item's turn)

```text
Read .agents/gen/dispatch_coder.md and execute queue item 29 only — S23 content activation. Brief: .agents/gen/slices/S23-content-activation/S23_BRIEF.md. Prompts: .agents/gen/slices/S23-content-activation/S23_prompts.md. Snapshot + commit before the first dispatch, run B1 → R1, and the fixer only if the review leaves HIGH or MED. Stop before item 30. Close out per the brief's close-out section (gate re-run, verify_wave.py verify --baseline s23_start, validate_names --library summary, WAVEBOARD update, wave-boundary commit), then report back: the measured gate count, the builder's per-deliverable numbers, the reviewer's findings by tier, and the owner ticks.
```
