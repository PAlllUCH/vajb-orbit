# Wave Combat/collision repair — prompts

Fenced blocks are the exact `crush run` commands. Host: Linux, workspace
`/home/kamil-paluszkiewicz/VajbOrbit`. Model `deepseek/deepseek-v4-flash`, per
`dispatch_coder.md`. Each runs as its own background shell job, polled until its
report exists. Order: **C1 · C2 · C3 · T1 in parallel → C5 → C6 → (C7 only if C6
leaves HIGH or MED)**.

## C1 — deterministic ram probe (measure, do not fix)

```bash
VAJB_WORKER_FILES="vajb-orbit/tests/,vajb-orbit/tools/" \
  crush run "Read .agents/gen/combat_repair_wave_task.md in full first - it is the law for this wave - then .agents/gen/owner_playtest_findings_20260921.md for the owner report and the measured lines. You are C1 and you own the ram measurement only. Build a deterministic headless probe scene under vajb-orbit/tests/ that drives a player hull into a rock with a fixed velocity step - never a live window, never an Input action, per CONTRACTS section 9's trap list - and measure, with raw numbers in your report: the rock's linear_velocity and position delta across the contact, both sides' pool deltas, and whether the ship's contact monitor fires at all. Then run the same ram twice more in memory only, once with the rock's collision_mask corrected to include the hull's layer and once with a stub sink added to the rock, so the report separates three candidate causes: the one-way pair, the missing apply_collision_damage on the rock, and the 40 u/s COLLISION_MIN_DV floor in game/impact.gd. State which one the numbers support, with the file and line that must change. Do not fix anything, do not touch assets, the theme, project.godot, addons or docs. Keep the gate green at its measured count and write your report to .agents/gen/combat_repair_c1_report.md." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## C2 — deterministic weapon probe (measure, do not fix)

```bash
VAJB_WORKER_FILES="vajb-orbit/tests/,vajb-orbit/tools/" \
  crush run "Read .agents/gen/combat_repair_wave_task.md in full first - it is the law for this wave - then .agents/gen/owner_playtest_findings_20260921.md. You are C2 and you own the weapon measurement only. Build a deterministic headless probe scene under vajb-orbit/tests/ that fires each of the five weapon families at an NPC hull and at a rock, using the component's own external trigger and a fixed step - never a live window and never an Input action. Measure and report raw numbers per family: damage landed on the NPC hull, whether the shield absorbed it first and whether bypass_shield followed the kinetic and missile rows, the exact no-op path when the target is a rock including which sink name the rock is missing, and dry_reason per family. Also probe the real launch fit rather than a single laser: five weapons and 1500 rounds, the fit the launch panel installs, so an empty or unfitted group is distinguishable from a broken firing path. Do not fix anything, do not touch assets, the theme, project.godot, addons or docs. Keep the gate green at its measured count and write your report to .agents/gen/combat_repair_c2_report.md." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## C3 — flight decay probe (measure the curve, do not retune)

```bash
VAJB_WORKER_FILES="vajb-orbit/tests/,vajb-orbit/tools/" \
  crush run "Read .agents/gen/combat_repair_wave_task.md in full first - it is the law for this wave - then .agents/gen/owner_playtest_findings_20260921.md, the owner item about weird drag. You are C3 and you own the flight decay measurement only. Build a deterministic headless probe under vajb-orbit/tests/ that accelerates a player hull to cruise speed with the shipped constants, releases the input, and logs velocity and distance every 0.1 s until the hull is effectively stopped, plus the afterburner case. Report the curve and the two numbers a retune must beat: the time to 10 percent of the release speed and the distance carried after release. Name every constant that drives the decay and where it lives, and say explicitly which of them are section 13 rows and which are the flight model's own feel numbers. Do not retune anything - C5 does that with these numbers. Do not touch assets, the theme, project.godot, addons or docs. Keep the gate green at its measured count and write your report to .agents/gen/combat_repair_c3_report.md." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## T1 — `--only` scope for the import-settings tool

```bash
VAJB_WORKER_FILES="staging/phase_f/apply_import_settings.py" \
  crush run "Read .agents/gen/combat_repair_wave_task.md in full first - it is the law for this wave. You are T1 and you own one tooling fix. staging/phase_f/apply_import_settings.py currently has no scope flag and wants to rewrite 1080 of 1620 .import files, which blocks the graphics lane's import pass. Add an --only option taking one or more patterns - plain paths or globs - that restricts every write to the matching files, keeping today's whole-tree behaviour as the default when the flag is absent. Do not change the import settings it applies, do not touch any .import file, any asset, the theme, project.godot, addons or docs. Prove it with a dry run that prints the counts for both modes and paste the raw output in .agents/gen/combat_repair_t1_report.md." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## C5 — fixer (after C1–C3)

```bash
VAJB_WORKER_FILES="vajb-orbit/game/asteroid.gd,vajb-orbit/game/weapons.gd,vajb-orbit/game/projectile.gd,vajb-orbit/game/player_ship.gd,vajb-orbit/game/impact.gd,vajb-orbit/tests/" \
  crush run "Read .agents/gen/combat_repair_wave_task.md in full first - it is the law - then the C1, C2 and C3 reports in .agents/gen/, which are the authority on what is broken. You are C5, the one-pass fixer, and you own three jobs. First, the rock's collision half: make a ram push the rock and charge both sides per CONTRACTS section 4 and the owner ruling, using C1's measurement of whether the one-way pair or the missing sink is the cause. Second, the owner ruling that weapon fire damages asteroids: give the rock the damage sink and route weapon damage through its existing cleave channel, apply_work, with the damage-to-work conversion as ONE named constant that you propose explicitly in your report together with its reversal path and its section 13 tick request. Third, the drag retune the owner asked for: use C3's measured curve, keep every section 13 row it must not move untouched, and report the old and new constants with the after curve. Add a test per fix, keep the gate green and grow its count, and re-measure each fix with the same probe the reviewer will re-run. Do not touch assets, the theme, project.godot, addons or docs. Write your report to .agents/gen/combat_repair_c5_report.md." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## C6 — reviewer (mandatory)

```bash
VAJB_WORKER_FILES="vajb-orbit/tests/,vajb-orbit/tools/" \
  crush run "Read .agents/gen/combat_repair_wave_task.md in full first - it is the law - then all four reports combat_repair_c1_report.md, combat_repair_c2_report.md, combat_repair_c3_report.md and combat_repair_c5_report.md in .agents/gen/. You are C6, the mandatory reviewer. Verify, never trust: re-run every probe byte-identically, re-measure every number C1, C2, C3 and C5 published - the rock's velocity and position delta on a ram, both sides' pool deltas, the per-family damage on an NPC hull and the rock no-op path, the decay curve and the two retune numbers - and grep the pinned signatures across every changed file against docs/CONTRACTS.md section 4 and section 8.2 rather than against the brief. Check explicitly that no section 13 row moved except the two deviations the brief sanctions, and that the damage-to-work constant is a single named value with a reversal path. Tier every finding HIGH which blocks the wave, MED which gets one fixer pass, or LOW which rides to .agents/gen/LOW_BACKLOG.md, each with the exact reproducing command and its raw output. Report the gate count you measured yourself. Do not fix anything. Write your report to .agents/gen/combat_repair_c6_report.md." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## C7 — fixer (only if C6 leaves HIGH or MED)

```bash
VAJB_WORKER_FILES="<per-finding sets from the C6 report>" \
  crush run "Read .agents/gen/combat_repair_c6_report.md in full - it is the authority on every finding - and .agents/gen/combat_repair_wave_task.md for the wave rules. You are C7 and you fix only the HIGH and MED findings assigned to you, one pass. Re-measure each finding before and after with the reviewer's own command, and keep the gate green. Do not touch assets, the theme, project.godot, addons or docs. Write your report to .agents/gen/combat_repair_c7_report.md with the per-finding evidence." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```
