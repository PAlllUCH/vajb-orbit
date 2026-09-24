# S11_prompts.md — dispatch lines (one per worker; run in the brief's order)

Model for every worker: `deepseek/deepseek-flash` (DeepSeek API direct, owner ruling
2026-09-24; fallback `opencode-go/deepseek-v4.1-flash`). Effort: `high` for B1/B2/B3, `max`
for B4 (the flight law is the one place a subtle error ships). All four are code workers, so
every line sets `VAJB_SLIM=1`.

Each `VAJB_WORKER_FILES` is the worker's own set from `S11_BRIEF.md` **plus its report
path** (the hook must allow the report). `R1`'s line is written at review-prep.

## Run order

**B1 ∥ B3 ∥ B4** (disjoint file sets) → **B2** (needs B1's `group_int`) → **R1**.

```bash
cd /home/kamil-paluszkiewicz/VajbOrbit && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/ui/station/armory_panel.gd,vajb-orbit/ui/station/shipyard_panel.gd,vajb-orbit/ui/station/exchange_panel.gd,vajb-orbit/ui/station/auction_panel.gd,vajb-orbit/ui/station/refinery_panel.gd,vajb-orbit/ui/station/fitting_panel.gd,vajb-orbit/ui/station/repairs_panel.gd,vajb-orbit/ui/station/launch_panel.gd,vajb-orbit/ui/screens/station.gd,vajb-orbit/ui/screens/station.tscn,vajb-orbit/game/station_catalog.gd,vajb-orbit/tests/test_s11_inspector.gd,.agents/gen/slices/S11-legibility-gunnery-feel/S11-B1_report.md' \
     crush run "You are worker S11-B1 on the Vajb Orbit workspace, wave S11. Read .agents/gen/slices/S11-legibility-gunnery-feel/S11_BRIEF.md end to end first, then docs/CONTRACTS.md section 23 end to end — it is the pin, not a summary. Task: build the station inspector. Declare signal inspect_requested on all eight panes and emit it from the six item panes on hover-in, hover-out and selection; add the Inspector block to ui/screens/station.tscn immediately above the status strip with InspectorTitle and InspectorBody exactly as section 23.1 pins, including the font colour override to the theme's text_primary token; add the static describe and group_int helpers to game/station_catalog.gd and make station.gd's _format_int delegate to group_int so the rule has one home; add tests/test_s11_inspector.gd proving the hover signal, the clear on unhover, describe's base-id resolution and its empty answer for a row with no description, and the block's rendering. Never reword an existing status string, never change an existing pane's font size or colour, never edit docs, never edit game/module_catalog.gd. Run the gate on a scratch store and report .agents/gen/slices/S11-legibility-gunnery-feel/S11-B1_report.md with the gate line, the files touched and per-deliverable evidence." \
     -m deepseek/deepseek-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s11_b1.log 2>&1
```

```bash
cd /home/kamil-paluszkiewicz/VajbOrbit && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/weapons.gd,.agents/gen/slices/S11-legibility-gunnery-feel/S11-B3_report.md' \
     crush run "You are worker S11-B3 on the Vajb Orbit workspace, wave S11. Read .agents/gen/slices/S11-legibility-gunnery-feel/S11_BRIEF.md end to end first, then docs/CONTRACTS.md section 23.4. Task: add const NEAR_INFINITE_RANGE := 30000.0 to game/weapons.gd beside the FAMILIES table and apply it as the range of the laser, plasma, cannon and railgun rows only — rocket stays 900.0 and mine stays 0.0. Do not touch projectile.gd's max_range contract, do not touch game.gd's range readout, and leave every other family key byte-identical. Then re-derive only the test rows that pin one of those four families' range or read it through Weapons.range_of, and weaken no bound. Run the gate twice on fresh scratch stores and report .agents/gen/slices/S11-legibility-gunnery-feel/S11-B3_report.md with both gate lines, the rows you re-derived and the reversals." \
     -m deepseek/deepseek-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s11_b3.log 2>&1
```

```bash
cd /home/kamil-paluszkiewicz/VajbOrbit && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/ship_fit.gd,vajb-orbit/game/player_ship.gd,vajb-orbit/tests/test_s2_6_flight.gd,vajb-orbit/tests/test_flight_feel_g1.gd,vajb-orbit/tests/test_engine_c3_flight_decay.gd,vajb-orbit/tests/test_s11_flight_stop.gd,.agents/gen/slices/S11-legibility-gunnery-feel/S11-B4_report.md' \
     crush run "You are worker S11-B4 on the Vajb Orbit workspace, wave S11. Read .agents/gen/slices/S11-legibility-gunnery-feel/S11_BRIEF.md end to end first, then docs/CONTRACTS.md section 23.5 and section 14's amended flight-feel bullet. Task: make a released hull decay as one velocity vector. In game/player_ship.gd make _lateral_damp return _linear_damp so one rate owns both axes; _lateral_extra_damp then returns zero and _step_lateral_drag becomes inert — keep both in place for the reversal, do not delete them. In game/ship_fit.gd retire LATERAL_DAMP_MULT in place as a documented unread constant, tick COAST_TIME_MULT from 2.0 to 2.5, and add ANGULAR_DAMP_MULT := 0.5 read by player_ship._angular_damp as that multiplier over one divided by turn_spinup. Implement nothing for T3. Keep the commanded strafe's class-rate chase working through the single damp. Re-derive the numeric rows in tests/test_s2_6_flight.gd, tests/test_flight_feel_g1.gd and tests/test_engine_c3_flight_decay.gd to the ticked constants, weakening no bound, and add tests/test_s11_flight_stop.gd proving that a hull released from a commanded forward plus strafe holds its velocity direction within five degrees of the release bearing while its speed falls to a tenth of release. Run the gate twice on fresh scratch stores and report .agents/gen/slices/S11-legibility-gunnery-feel/S11-B4_report.md with both gate lines, the measured direction hold and every numeric row you moved." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s11_b4.log 2>&1
```

```bash
cd /home/kamil-paluszkiewicz/VajbOrbit && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/module_catalog.gd,vajb-orbit/ui/hud/hud.gd,vajb-orbit/ui/hud/hud.tscn,vajb-orbit/tests/test_s11_inspector.gd,.agents/gen/slices/S11-legibility-gunnery-feel/S11-B2_report.md' \
     crush run "You are worker S11-B2 on the Vajb Orbit workspace, wave S11. Read .agents/gen/slices/S11-legibility-gunnery-feel/S11_BRIEF.md end to end first, then docs/CONTRACTS.md sections 23.2 and 23.3 — run only AFTER S11-B1 has landed, because you read its StationCatalog.group_int helper. Task one: add one description key to all 35 rows of the MODULES table in game/module_catalog.gd, verbatim from section 23.2's table. Transcribe it exactly — never improve the wording, and if you believe a row is wrong, report it and leave it as written. Every other key of every row stays byte-identical. Task two: append a CreditsBlock to the HUD's top-left block column in ui/hud/hud.gd and ui/hud/hud.tscn exactly as section 23.3 pins — an HBoxContainer header with the credits icon, the CREDITS title and a spacer, plus a HudReadout value written through StationCatalog.group_int — reading the PlayerProfile singleton by name through the guarded service pattern, connecting its profile_changed signal and updating only on the credits key, and never writing the profile. Add the credits half of tests/test_s11_inspector.gd: the block reads the profile's credits, follows a credits change, and is absent-safe when the service is missing. Run the gate twice on fresh scratch stores and report .agents/gen/slices/S11-legibility-gunnery-feel/S11-B2_report.md with both gate lines, the 35 rows confirmed one by one, and the credits evidence." \
     -m deepseek/deepseek-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s11_b2.log 2>&1
```

`crush run` prints only narration, so a silent log is normal. Poll with
`pgrep -af 'worker S11-B'` and read each report when its process exits; never end the
session while a worker is in flight.

## Wave 2 — continuations (after B1 ∥ B3 ∥ B4 landed)

B1, B3 and B4 all exited. The gate read **788/3**: the three red rows are the wave's own —
two suites and one probe outside the builders' sets — and §23.6's list was amended to name
them. B2 (the block above) had not run yet and now runs beside these two. **B2 ∥ B5 ∥ B6**
are disjoint.

```bash
cd /home/kamil-paluszkiewicz/VajbOrbit && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/test_engine2_weapons.gd,vajb-orbit/tests/test_s7_affixes.gd,vajb-orbit/tests/probe_s2_6_flight.gd,vajb-orbit/tests/probe_g1_flight_feel.gd,vajb-orbit/tests/probe_c3_flight_decay.gd,.agents/gen/slices/S11-legibility-gunnery-feel/S11-B5_report.md' \
     crush run "You are worker S11-B5 on the Vajb Orbit workspace, wave S11 continuation. Read .agents/gen/slices/S11-legibility-gunnery-feel/S11_B5_BRIEF.md end to end first, then docs/CONTRACTS.md sections 23.4, 23.5 and the amended 23.6, plus the S11-B3_report.md and S11-B4_report.md rows you are closing. Task: re-derive only the test and probe rows the wave's ticked constants reach, weakening no bound. One: tests/test_engine2_weapons.gd lines 141 to 145 read the four families range as 30000.0 through WeaponScript.NEAR_INFINITE_RANGE, with rocket still 900.0. Two: tests/test_s7_affixes.gd rows that resolve a coast time against the old multiplier follow ShipFit.COAST_TIME_MULT instead of a second literal. Three: tests/probe_s2_6_flight.gd and tests/probe_g1_flight_feel.gd get their moved printed rows and their prose corrected - the lateral split prose and the LATERAL_DAMP_MULT key list now describe a retired drag. Four: tests/probe_c3_flight_decay.gd reports four failures in its accelerate leg; prove ownership before touching it by adding a git worktree at the pre-dispatch commit 4c19812 under /tmp/s11_base and running the probe there on a scratch store - if it fails at the baseline too, leave the file untouched and report both runs. Report .agents/gen/slices/S11-legibility-gunnery-feel/S11-B5_report.md with two gate lines from fresh scratch stores, every row moved with before and after, and the probe ownership verdict." \
     -m deepseek/deepseek-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s11_b5.log 2>&1
```

```bash
cd /home/kamil-paluszkiewicz/VajbOrbit && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/station_catalog.gd,vajb-orbit/ui/station/armory_panel.gd,vajb-orbit/ui/station/shipyard_panel.gd,vajb-orbit/ui/station/exchange_panel.gd,vajb-orbit/ui/station/auction_panel.gd,vajb-orbit/ui/station/refinery_panel.gd,vajb-orbit/ui/station/fitting_panel.gd,vajb-orbit/tests/test_s11_describe.gd,.agents/gen/slices/S11-legibility-gunnery-feel/S11-B6_report.md' \
     crush run "You are worker S11-B6 on the Vajb Orbit workspace, wave S11 continuation. Read .agents/gen/slices/S11-legibility-gunnery-feel/S11_B6_BRIEF.md end to end first, then docs/CONTRACTS.md section 23.1 both amended rows, and S11-B1_report.md deviations 1 2 3. Task one: widen StationCatalog.describe to also read MineralCatalog and ComponentCatalog, so a REFINERY ore row and an EXCHANGE mineral or component hold row show the prose those catalogues already carry - keep the base-id and ammo pack handling, keep an empty answer for a row that carries none, and invent no text. Task two: give the six item panes a real inspector title - the row name plus the pane's own price phrase joined by the pane's existing separator, with the leading key-hint verb dropped - while the status strip hover line keeps its verb and its wording byte-identically, and no other string, font size or colour moves. Task three: add tests/test_s11_describe.gd proving the widened resolution, the affix perk join, the ammo pack mapping, the empty answer, and that each of the six panes title carries the name with no ENTER verb while its status line still carries it. Run the gate twice on fresh scratch stores and report .agents/gen/slices/S11-legibility-gunnery-feel/S11-B6_report.md with both gate lines, one before and after title per pane, and a reversal per change." \
     -m deepseek/deepseek-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE" \
  > /tmp/s11_b6.log 2>&1
```
