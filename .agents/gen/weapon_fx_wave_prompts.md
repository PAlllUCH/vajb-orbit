# Wave Weapon FX & audio wiring — prompts

Fenced blocks are the exact `crush run` commands. Host: Linux, workspace
`/home/kamil-paluszkiewicz/VajbOrbit`. Model `deepseek/deepseek-v4-flash`, per
`dispatch_coder.md`. **Sequential by design** (F1 and F2 both touch
`game/projectile.gd`): F1 → F2 → F3 → F4 only if F3 leaves HIGH or MED.

## F1 — fire & travel visuals and audio

```bash
VAJB_WORKER_FILES="vajb-orbit/game/weapons.gd,vajb-orbit/game/projectile.gd,vajb-orbit/game/mining_laser.gd,vajb-orbit/autoload/audio_manager.gd,vajb-orbit/game/fx.gd,vajb-orbit/tests/" \
  crush run "Read .agents/gen/weapon_fx_wave_task.md in full first - it is the law for this wave - then docs/design/ASSET_WIRING_HANDOFF.md sections 1.1, 1.2 and 3, docs/design/FX_SPEC.md sections 0, 1.2, 1.4 and 1.6, and .agents/gen/owner_playtest_findings_20260921.md. You are F1 and you own fire and travel feedback. Measured today: a projectile is an Area2D with only a collision shape, so a shot is invisible; the instant families emit shot_fired and draw nothing; and no weapon code calls AudioManager at all. Wire the shipped assets - never regenerate or edit anything under assets. Give the projectile a sprite chosen by its kind, a bolt for the bolt kind and the missile trail sheet for the homing kind, drawn additively because the sheets are RGB on void black per FX_SPEC section 0. Spawn the four-frame muzzle flash at the muzzle on each release and free it on animation_finished. Give the instant families a beam line drawn engine-side the way game/mining_laser.gd line 227 does it, which FX_SPEC section 1.6 sanctions. Play the family fire cue through AudioManager with the pools ASSET_WIRING_HANDOFF section 1.2 specifies: sfx_weapon_laser round-robin over takes 01 to 04 with pitch within plus or minus ten percent and volume between minus three and zero dB, the cannon tiers 01 to 03, and the rocket launch layer plus its warhead layer eighty milliseconds later. Add a cue-pool API to AudioManager since the handoff records that gap - keep play_sfx working unchanged for every existing caller. Play the mining beam loop cue alongside the chip cue the laser already plays. Put the shared spawn-play-free helper in a new game/fx.gd so F2 can reuse it. Add one test per wired event and keep the gate green at its measured count, growing it. Do not touch damage, cadence, range, Energy or ammo values, and do not touch assets, the theme, project.godot, addons or docs. Write your report to .agents/gen/weapon_fx_f1_report.md with the asset path and cue used per event." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## F2 — impact & death visuals and audio (after F1)

```bash
VAJB_WORKER_FILES="vajb-orbit/game/projectile.gd,vajb-orbit/game/impact.gd,vajb-orbit/game/player_ship.gd,vajb-orbit/game/npc_ship.gd,vajb-orbit/game/asteroid.gd,vajb-orbit/tests/" \
  crush run "Read .agents/gen/weapon_fx_wave_task.md in full first - it is the law for this wave - then .agents/gen/weapon_fx_f1_report.md, which is the authority on the helper and the cue API it built, and docs/design/ASSET_WIRING_HANDOFF.md sections 1.1, 1.2 and 3. You are F2 and you own impact and death feedback. Wire the hit's other half using the shipped assets only. Play the impact cue per target kind through AudioManager: sfx_impact_rock on a rock, sfx_impact_hull on a hull, sfx_impact_shield_hit while a shield absorbs and sfx_impact_shield_loop while it holds, using the pools the handoff lists. Spawn the five-frame explosion on a hull's death plus the secondary explosion, fx_arc_spark on the railgun's hit, fx_shield_ripple and fx_shield_break on the shield, and fx_smoke_plume at low hull, all additively through the helper F1 created in game/fx.gd - reuse it read-only, and if you must extend it say so in your report. Use the sfx_weapon_explosion pool for the blasts. Add one test per wired event and keep the gate green, growing the count. Do not touch damage, cadence, range, Energy or ammo values, do not touch assets, the theme, project.godot, addons or docs. Write your report to .agents/gen/weapon_fx_f2_report.md with the asset path and cue used per event." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## F3 — reviewer (mandatory)

```bash
VAJB_WORKER_FILES="vajb-orbit/tests/,vajb-orbit/tools/" \
  crush run "Read .agents/gen/weapon_fx_wave_task.md in full first - it is the law for this wave - then the F1 and F2 reports in .agents/gen/. You are F3, the mandatory reviewer. Verify by measurement, never by trusting the reports. Build or reuse a deterministic headless probe that counts what each event spawns and captures every AudioManager play_sfx call through a stub, because audio cannot be heard headless. Prove per event that the node spawns, that its res://assets/fx path resolves and exists on disk, that its blend mode is additive rather than alpha, that the cue resolves through AudioManager's own loader, and that the sheet's frames come from the shipped master rather than an invented file. Then grep every changed file to prove no damage, cadence, range, Energy or ammo value moved, and check the new cue-pool API kept play_sfx's behaviour for its existing callers. Tier every finding HIGH which blocks the wave, MED which gets one fixer pass, or LOW which rides to .agents/gen/LOW_BACKLOG.md, each with the exact reproducing command and its raw output. Report the gate count you measured yourself. Do not fix anything. Write your report to .agents/gen/weapon_fx_f3_report.md." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## F4 — fixer (only if F3 leaves HIGH or MED)

```bash
VAJB_WORKER_FILES="<per-finding sets from the F3 report>" \
  crush run "Read .agents/gen/weapon_fx_f3_report.md in full - it is the authority on every finding - and .agents/gen/weapon_fx_wave_task.md for the wave rules. You are F4 and you fix only the HIGH and MED findings assigned to you, one pass. Re-measure each finding before and after with the reviewer's own command, keep the gate green, and do not touch assets, the theme, project.godot, addons or docs. Write your report to .agents/gen/weapon_fx_f4_report.md with the per-finding evidence." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```
