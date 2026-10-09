# S38_prompts.md — dispatch lines (one per worker; run in the brief's order)

**Models (the owner's 2026-10-03 roster, as S24/S25/S28 ran it):** the builder
runs `hyper/deepseek-v4.1-flash` at `--reasoning-effort xhigh` (that route's top
rung; its ladder is low/high/xhigh, not max); the reviewer runs
`hyper/glm-5.3-flash` at `--reasoning-effort max`. `deepseek/deepseek-flash` is
the same model on the DeepSeek route if the Hyper quota throttles — say so
before switching.

Run order **B1 → R1 → (F1 only on HIGH/MED)**. Launch each with
`run_in_background: true` and **wait on it** (`job_output`, `wait: true`); a
wedged worker (0 sockets, frozen I/O) is killed with python SIGKILL — wrapper
AND child — then re-dispatched; re-check `git status` and the report file.

**Before the first dispatch** (the five-piece is committed):

```bash
cd "$VAJB_WORKSPACE" \
  && python3 staging/verify_wave.py snapshot --name s38_start \
  && git tag s38_start
```

## S38-B1 — the cold start, the countdown, the re-roll, the riders (A1–A6)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/sector_registry.gd,vajb-orbit/game/game.gd,vajb-orbit/game/station_registry.gd,vajb-orbit/game/contract_registry.gd,vajb-orbit/ui/station/contracts_panel.gd,vajb-orbit/ui/station/contracts_panel.tscn,vajb-orbit/ui/screens/station.gd,vajb-orbit/ui/station/overview_panel.gd,vajb-orbit/tests/test_s38_start_and_clock.gd,vajb-orbit/tests/probe_s38_start_board.gd,vajb-orbit/tests/probe_s38_start_board.tscn,.agents/gen/slices/S38-hub-start-and-clock/S38-B1_report.md' \
     crush run "You are worker S38-B1 on the Vajb Orbit workspace, wave S38 the board's clock and the hub's cold start, builder. Read .agents/gen/slices/S38-hub-start-and-clock/S38_BRIEF.md end to end - its section 4's seven rules bind every line you write - then SLICE.md, then the law in the brief's section 1 order: the 2026-10-08 S38 block in docs/gameplay/14_station_services.md (H1 to H3, each with its reversal), docs/design/STATION_HUB.md section 15.2 (the CONTRACTS panel law, U3 to U8, plus the new U22 roll countdown row) and section 15.6 (U21/U22) and section 15.5 (the plate), docs/CONTRACTS.md sections 24 and 26 by range, docs/CODE_MAP.md by range. The owner's playtest finding is verbatim in the brief's section 2. Task: land A1 to A6 exactly. A1: the hub's cold start - game/sector_registry.gd gains DEFAULT_SECTOR_ID sector_1 (the constant game.gd line 113 carries today; game.gd reads it from the registry afterwards), game/station_registry.gd gains starting_station() answering primary_for(DEFAULT_SECTOR_ID), and both docked_station and docked_station_id answer the starting place when the profile's filed id is empty; an empty filed id means no run has filed a place and nothing else, so game.gd:_file_docked_station files the sector's OWN id when the sector has no primary row (S7 files sector_7) and a null profile, an unparseable id and a station-less sector keep their current answers. A2 and A3: the roll countdown - ui/station/contracts_panel.gd gains TICK_SECONDS 1.0 and a 1 Hz timer (the refinery panel's own idiom at ui/station/refinery_panel.gd lines 57, 250, 272 and the _mmss shape at line 1191), a StationCaption readout at the right end of the U3 header strip reading NEW JOBS IN mm:ss at WorldClock.BAND_SECONDS minus now modulo BAND_SECONDS with two-digit minutes, and at zero one _refresh() so the next band's rows appear and the readout restarts at 20:00 with no scene change and no player action; the readout must move on its own, never a value written once at build. A4: prove S7 and the two unchanged paths. A5: the two riders this wave owns - T-156, the staged Expedition row dims whole (its icon included, at text_dim), and T-157, an accepted row leaves the board so one id cannot be accepted twice in one band. A6: the gate twice on fresh scratch XDG_DATA_HOME stores, both SUMMARY lines recorded, and every moved row enumerated with its reason (the brief's section 8 lists the candidates: test_s24_world.gd line 306 and test_s25_contracts.gd lines 1171 to 1207). No contract number, reward shape, gate, escrow rule or escort rule moves - they are S25's and pinned in CONTRACTS section 26. Extend the shipped probe tests/probe_s38_start_board.gd and its scene so it prints the cold-start board, the filed board, the countdown moving between two reads one second apart and the boundary re-roll driven directly; its lines are your evidence. New suite tests/test_s38_start_and_clock.gd with one row per acceptance criterion. Docs are read-only. Containers and anchors only, never coordinates. Write slices/S38-hub-start-and-clock/S38-B1_report.md from the REPORT template, 120 lines maximum, answering A1 to A6 with cites and tabling every moved value with its reversal and tick." \
     -m hyper/deepseek-v4.1-flash --reasoning-effort xhigh --cwd "$VAJB_WORKSPACE" \
  > /tmp/s38_b1.log 2>&1
```

## S38-R1 — mandatory review (after B1 reports)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/,docs/CONTRACTS.md,.agents/gen/slices/S38-hub-start-and-clock/S38-R1_review.md' \
     crush run "You are worker S38-R1, the mandatory reviewer of wave S38 - brief .agents/gen/slices/S38-hub-start-and-clock/S38_BRIEF.md. Diff findings against the brief's section 5 extracts and the 2026-10-08 S38 block they cite, never against B1's report. Grade A1 to A6 first, re-measuring yourself on fresh scratch stores and re-running the shipped probe byte-identically. The three measurements that decide this wave: (1) the cold start - with a fresh sandboxed profile and NO docked station filed, mount ui/screens/station.tscn, select SERVICES and read the contracts panel: the board must read 6 rows and the plate must read the station row's own name and character line, not the scene's placeholder copy (the pre-wave reading was 0 rows and ORBITAL DRYDOCK KEPLER-9 / HELIOS DRIFT); (2) the countdown - the U3 strip's readout must read NEW JOBS IN mm:ss and must CHANGE between two reads one second apart, and its figure must equal WorldClock.BAND_SECONDS minus now modulo BAND_SECONDS at the moment of reading (an off-by-one band or a frozen readout is HIGH); (3) the re-roll - drive the boundary and prove the board's rows are the NEXT band's (compare against ContractRegistry.board for band+1) with the readout restarted, with no scene change. Then check the negatives: S7 and a station-less sector still resolve to no place, a null profile and an unparseable id are unchanged, and no contract number, reward shape, gate, escrow rule or escort rule moved (CONTRACTS section 26 is the pin - an unlisted moved row or a moved pinned value is HIGH). Check the two riders: the staged Expedition row dims whole including its icon, and an accepted row leaves the board so the same id cannot be accepted twice in one band (try it twice in one band and prove the second attempt cannot happen). Diff moved gate rows against the brief's section 8 list. Update docs/CONTRACTS.md: section 9's measured block and section 10's changelog row at the next free rows read at write time, plus a new section pinning this wave's interface (the cold-start resolution and the empty-id sentinel, the countdown's constants and its 1 Hz contract, the re-roll) if the next free section number is free when you write. Write slices/S38-hub-start-and-clock/S38-R1_review.md from the REVIEW template, 150 lines maximum, findings S38-B1 with F numbers, a tier and one evidence line each, and LOW rows at the next free ids read from .agents/gen/_state/LOW_BACKLOG.md at write time (T-156 and T-157 are this wave's riders - report them closed or not). Never fix code. Bounded probes only." \
     -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s38_r1.log 2>&1
```

## S38-F1 — fixer (only if R1 leaves HIGH or MED)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/sector_registry.gd,vajb-orbit/game/game.gd,vajb-orbit/game/station_registry.gd,vajb-orbit/game/contract_registry.gd,vajb-orbit/ui/station/contracts_panel.gd,vajb-orbit/ui/station/contracts_panel.tscn,vajb-orbit/ui/screens/station.gd,vajb-orbit/ui/station/overview_panel.gd,vajb-orbit/tests/test_s38_start_and_clock.gd,vajb-orbit/tests/probe_s38_start_board.gd,vajb-orbit/tests/probe_s38_start_board.tscn,vajb-orbit/tests/,docs/CONTRACTS.md,.agents/gen/slices/S38-hub-start-and-clock/' \
     crush run "You are worker S38-F1, the fixer of wave S38 (brief .agents/gen/slices/S38-hub-start-and-clock/S38_BRIEF.md - read it for the pinned law; review .agents/gen/slices/S38-hub-start-and-clock/S38-R1_review.md). Fix ONLY the HIGH and MED findings at their named file:line; adjust tests only where a fix changes what is proven. No LOW items, no refactors, no pinned value changed, no contract number touched. Prove each fix with a negative control where the finding allows it. Re-run the gate twice on fresh scratch stores and write slices/S38-hub-start-and-clock/S38-F1_report.md with a finding-by-finding disposition and both gate lines." \
     -m hyper/deepseek-v4.1-flash --reasoning-effort xhigh --cwd "$VAJB_WORKSPACE" \
  > /tmp/s38_f1.log 2>&1
```

Never end the session while a worker is in flight; read each worker's report
file when its process exits (the logs are narration only).

## Handoff (paste at this item's turn)

```text
Read .agents/gen/dispatch_coder.md and execute queue item 35 only — S38 the board's clock and the hub's cold start. Brief: .agents/gen/slices/S38-hub-start-and-clock/S38_BRIEF.md. Prompts: .agents/gen/slices/S38-hub-start-and-clock/S38_prompts.md. Snapshot + commit before the first dispatch, run B1 → R1, and the fixer only if the review leaves HIGH or MED. Stop before item 32. Close out per the brief's close-out section (gate re-run, verify_wave.py verify --baseline s38_start, build_code_map.py, CONTRACTS, WAVEBOARD update, wave-boundary commit), then report back: the measured gate count, the builder's per-deliverable numbers, the reviewer's findings by tier, and the owner ticks.
```
