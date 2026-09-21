# Wave Rock cleave — prompts

Fenced blocks are the exact `crush run` commands. Host: Linux, workspace
`/home/kamil-paluszkiewicz/VajbOrbit`. Each runs as its own background shell job,
polled until its report exists. Order: **A1 → A2 → A3 (only if A2 leaves HIGH or
MED)**. Snapshot + commit (`verify_wave.py snapshot --name rock_cleave_start`)
before the first dispatch.

## A1 — the break effects and the random fragmentation

```bash
VAJB_WORKER_FILES="vajb-orbit/game/asteroid.gd,vajb-orbit/game/asteroid_field.gd,vajb-orbit/game/projectile.gd,vajb-orbit/autoload/audio_manager.gd,vajb-orbit/tests/" \
  crush run "Read .agents/gen/rock_cleave_wave_task.md in full first - it is the law for this wave - then docs/gameplay/18_engine_spec.md section 6 and section 13 (owner-locked, cite them), docs/gameplay/02_minerals.md sections 5 and 8, docs/design/FX_SPEC.md sections 1.4 and 7.3, and docs/CONTRACTS.md sections 5 and 9. You are A1 and you own the owner's asteroid ruling: rocks now explode, spawning a random two to five fragments moving in random directions. Make four changes exactly as the brief's table pins them: the fragment count becomes a uniform random two to five per cleaving tier with the Large fragments Medium and a Medium's fragments Small; the ejection direction becomes uniformly random over the full circle while the speed stays the parent's linear velocity times the shipped 1.2 multiplier; every depletion plays one explosion sequence at the rock's centre scaled to the rock and one break cue; and a Small keeps bursting its one to two pickups while a yield-0 rock still cracks and despawns without fragments but does play the break read. Spawn the explosion through Projectile's existing sheet helpers with the re-cut RGBA frames, and reuse impact.gd's shipped shockwave helper on nearby bodies rather than inventing a new constant; touch projectile.gd only if the fixed world sizes need one optional scale override as one named constant. Add the rock pool row to audio_manager.gd's CUE_POOLS for the four impact takes that already sit on disk. Add or update a test per change and keep the existing cleaving suite's surviving assertions green. Measure everything with a deterministic seeded probe - the count bounds on both tiers, a direction spread proof that two fragments land more than ninety degrees apart, the speed multiplier, the FX spawn, the cue, the yield-0 path and the pickup burst - and paste the raw output. Do not touch assets, the theme, project.godot, addons or docs, and do not invent a number: the counts, cone retirement, explosion scale and cue are the brief's, and the rows marked proposed are the owner's to tune. Keep the gate green at its measured 311 and grow it. Write your report to .agents/gen/rock_cleave_a1_report.md." \
  -m opencode-go/deepseek-v4.1-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## A2 — reviewer (mandatory)

```bash
VAJB_WORKER_FILES="vajb-orbit/tests/,vajb-orbit/tools/" \
  crush run "Read .agents/gen/rock_cleave_wave_task.md in full first - it is the law - then docs/gameplay/18_engine_spec.md sections 6 and 13, docs/gameplay/02_minerals.md sections 5 and 8, docs/design/FX_SPEC.md sections 1.4 and 7.3, docs/CONTRACTS.md sections 5 and 9, and .agents/gen/rock_cleave_a1_report.md. You are A2, the mandatory reviewer. Verify, never trust: re-run A1's probe byte-identically and re-measure every number yourself - the two-to-five count bounds on both cleaving tiers, the uniform direction spread, the times-1.2 ejection speed, the explosion spawn and its rock-scaled size, the break cue, the yield-0 no-fragment path with the break read still playing, the Small pickup burst, and the mineral inheritance of fragments. Confirm that 02 section 8's respawn bookkeeping, ruling 17, the section 13 collision terms and every mining rate are untouched, and that no balance number moved - this wave is a fragmentation-and-presentation change only. Grep the pinned signatures of CONTRACTS section 5 across every changed file. Tier every finding HIGH which blocks the wave, MED which gets one fixer pass, or LOW which rides to .agents/gen/LOW_BACKLOG.md, each with the exact reproducing command and its raw output. Report the gate count you measured yourself. Do not fix anything. Write your report to .agents/gen/rock_cleave_a2_report.md." \
  -m opencode-go/deepseek-v4.1-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## A3 — fixer (only if A2 leaves HIGH or MED)

```bash
VAJB_WORKER_FILES="<per-finding sets from the A2 report>" \
  crush run "Read .agents/gen/rock_cleave_a2_report.md in full - it is the authority on every finding - and .agents/gen/rock_cleave_wave_task.md for the wave rules. You are A3 and you fix only the HIGH and MED findings assigned to you, one pass. Re-measure each finding before and after with the reviewer's own command, keep the gate green and grow its count, and add or update a test per fix. Do not touch assets, the theme, project.godot, addons or docs. Write your report to .agents/gen/rock_cleave_a3_report.md with the per-finding before and after evidence." \
  -m opencode-go/deepseek-v4.1-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```
