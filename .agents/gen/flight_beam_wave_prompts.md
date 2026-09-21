# Wave Flight feel & beam polish — prompts

Fenced blocks are the exact `crush run` commands. Host: Linux, workspace
`/home/kamil-paluszkiewicz/VajbOrbit`. Model `deepseek/deepseek-v4-flash`, per
`dispatch_coder.md`. Run order: **G1 · G2 · G3 in parallel** (file-disjoint), then **G4**,
then **G5** only if G4 leaves HIGH or MED.

**G1 is gated on the orchestrator registering the two strafe actions** (`strafe_left` on A,
`strafe_right` on D) through the editor's input-map API — the editor refuses writes while the
game is playing, so G1 is dispatched as soon as the owner's session stops. G2 and G3 need
nothing from the input map and may run first.

## G2 — beam polish + weapons/projectile warning sweep

```bash
VAJB_WORKER_FILES="vajb-orbit/game/weapons.gd,vajb-orbit/game/projectile.gd,vajb-orbit/tests/" \
  crush run "Read .agents/gen/flight_beam_wave_task.md in full first - it is the law for this wave - then docs/design/FX_SPEC.md section 1.6 and line 138, and .agents/gen/owner_playtest_findings_20260921.md third round. You are G2 and you own three measured beam defects plus a warning sweep. First, the shaft stops at the hit point: today weapons.gd draws it to the aim point before the target is resolved, so it passes through whatever it hits - draw it to the resolved hit point when there is one and keep the full reach for a miss. Second, a laser chipping a rock gets feedback: the rock branch of _apply_beam returns right after apply_work with no cue and no burst, unlike the hull branch - give it the chip cue and the chip-sparks burst from fx_mining_beam.png, the sheet FX_SPEC line 138 names for exactly this, behind the same per-contact rate guard the hull branch uses. Third, a held beam's fire feedback loops for as long as the trigger is held instead of one flash per release. Then clear the shadowing warnings in these two files - the editor log shows around thirty, all a parameter or local shadowing a function, a base-class property or a global class, for example set_fitted's weapon_ids, projectile's source, retarget's decoy, feedback_row's name and the local material - and prove the count fell with the debug lint ledger CONTRACTS section 9 documents. Add a test per behaviour, keep the gate green and grow its count, and do not move any damage, cadence, range, Energy or ammo value. Do not touch assets, the theme, project.godot, addons or docs. Write your report to .agents/gen/flight_beam_g2_report.md." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## G3 — UI/game warning sweep

```bash
VAJB_WORKER_FILES="vajb-orbit/ui/station/exchange_panel.gd,vajb-orbit/ui/station/shipyard_panel.gd,vajb-orbit/ui/station/launch_panel.gd,vajb-orbit/ui/components/slot_button.gd,vajb-orbit/game/sector.gd,vajb-orbit/tests/" \
  crush run "Read .agents/gen/flight_beam_wave_task.md in full first - it is the law for this wave. You are G3 and you own one job: clear every shadowing warning in your six files, behaviour byte-identical. The editor log names exchange_panel.gd lines 24 and 25 for the two global-class constants, shipyard_panel.gd line 321 and launch_panel.gd line 246 for a size parameter shadowing Control's own property, slot_button.gd lines 95 and 96, and sector.gd lines 125 and 309; re-derive the full list yourself with the debug lint ledger CONTRACTS section 9 documents rather than trusting this list, and fix the whole class in these files. Rename the offending parameter or local, never the pinned signature: check docs/CONTRACTS.md and docs/design/IMPLEMENTATION_PLAN.md before renaming anything a caller could see, and remember GDScript has no named arguments so a parameter label is safe while a method name is not. Prove the ledger's count fell and that the gate stays green at the same or a higher count. Do not touch assets, the theme, project.godot, addons or docs. Write your report to .agents/gen/flight_beam_g3_report.md with the before and after ledger." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## G1 — flight feel (dispatch once the strafe actions exist)

```bash
VAJB_WORKER_FILES="vajb-orbit/game/player_ship.gd,vajb-orbit/game/ship_fit.gd,vajb-orbit/autoload/settings_manager.gd,vajb-orbit/tests/" \
  crush run "Read .agents/gen/flight_beam_wave_task.md in full first - it is the law for this wave - then .agents/gen/owner_playtest_findings_20260921.md third round and docs/gameplay/18_engine_spec.md sections 3.2 and 4.3. You are G1 and you own the flight feel. The owner ruled three things. First, the nose follows the cursor while thrust_forward is held and the heading holds when it is not - the autopilot's own _order_turn already turns toward a fly-to point, so reuse that mechanism and keep turn_rate and turn_spinup governing the speed of the turn. Second, A/D strafe sideways: the actions strafe_left and strafe_right are already in the input map with A and D bound, turn_left and turn_right now carry no key, and the strafe's strength must be DERIVED from the class's own rows - accel_time and max_speed - with no new balance number invented; if a derived constant is unavoidable it is one named value you propose in your report with its reversal path. Third, all nine turn_rate rows in game/ship_fit.gd are scaled by 0.50, which is the owner's ruling and the only handling number this wave may move. Add the two strafe actions to settings_manager.gd REBINDABLE_ACTIONS so the Controls tab lists them, and keep every existing action's behaviour. Tests: the nose reaches the cursor bearing within the class rate, the heading holds with no thrust held, strafe moves the hull laterally rather than forward, and no other handling number moved. Keep the gate green and grow its count. Do not touch assets, the theme, project.godot, addons or docs. Write your report to .agents/gen/flight_beam_g1_report.md with the strafe derivation and the turn curve before and after." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## G4 — reviewer (mandatory)

```bash
VAJB_WORKER_FILES="vajb-orbit/tests/,vajb-orbit/tools/" \
  crush run "Read .agents/gen/flight_beam_wave_task.md in full first - it is the law for this wave - then the G1, G2 and G3 reports in .agents/gen/. You are G4, the mandatory reviewer. Verify by measurement, never by trusting the reports. Re-run every probe byte-identically and measure: the turn curve per class before and after the x0.50 retune against the shipped values, the strafe's lateral response and whether it really derives from the class rows rather than a new number, the beam's endpoint against a target at several distances including a miss, the rock-chip cue and burst on a weapon hit, the held-beam loop's lifetime, and the debug lint ledger's before and after counts for every file the wave touched. Diff against docs/CONTRACTS.md sections 3.2, 4.1 and 4.3 and against section 13, and prove no damage, cadence, range, Energy or ammo value moved and that the only handling column that moved is turn_rate. Tier every finding HIGH which blocks the wave, MED which gets one fixer pass, or LOW which rides to .agents/gen/LOW_BACKLOG.md, each with the exact reproducing command and its raw output. Report the gate count you measured yourself. Do not fix anything. Write your report to .agents/gen/flight_beam_g4_report.md." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## G5 — fixer (only if G4 leaves HIGH or MED)

```bash
VAJB_WORKER_FILES="<per-finding sets from the G4 report>" \
  crush run "Read .agents/gen/flight_beam_g4_report.md in full - it is the authority on every finding - and .agents/gen/flight_beam_wave_task.md for the wave rules. You are G5 and you fix only the HIGH and MED findings assigned to you, one pass. Re-measure each finding before and after with the reviewer's own command, keep the gate green, and do not touch assets, the theme, project.godot, addons or docs. Write your report to .agents/gen/flight_beam_g5_report.md with the per-finding evidence." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```
