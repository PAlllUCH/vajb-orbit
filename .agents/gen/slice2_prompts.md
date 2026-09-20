# Engine Slice 2 — paste-ready worker prompts (2026-09-18)

One prompt per worker, run order: W0 → W1–W4 parallel → W5 → W6 → W7/W8.
Each dispatch: prepend the `VAJB_WORKER_FILES` env (per file-set table in
`slice2_task.md`) so the file-set hook enforces scope. Quotes are shell-safe
(no nested double quotes inside the prompt bodies below).

Dispatch template (bash):

```bash
VAJB_WORKER_FILES="<set>" crush run "<prompt>" -m deepseek/deepseek-v4-flash --cwd "G:/Mój dysk/Projekty/Vajb Orbit"
```

---

## W0 — doc check

```
You are worker W0 of engine slice 2 (Fight) for the Vajb Orbit Godot project. Read first, in order: AGENTS.md (workspace root), .agents/gen/slice2_task.md (your brief - the W0 section and Global rules are law), ENGINE_SPEC.md sections 4, 5 and 14 slice 2. Your job is a small doc-check pass only. 1) Confirm docs/design/IMPLEMENTATION_PLAN.md section 9.9 records the slice-2 scope (weapon families, damage pipeline, six NPC archetypes, loot); if the engine-wave section lacks a slice-2 line, append one transcribed from ENGINE_SPEC.md section 14 - no new numbers. 2) Confirm docs/gameplay/09_ship_slots_modules.md section 3.1 carries the family and shield-rule columns; if anything slice-2 needs is missing from 08/09/06/13, add the missing transcription; otherwise report no doc changes needed. Static typing conventions do not apply to docs; match the surrounding doc style. Do not edit any file outside docs/design/IMPLEMENTATION_PLAN.md and docs/gameplay/06, 08, 09. Headless runs are not expected for this pass. Write your report to .agents/gen/slice2_w0_report.md: files changed with byte sizes before/after, what you verified, deviations.
```

---

## W1 — weapons + projectiles

```
You are worker W1 of engine slice 2 (Fight) for the Vajb Orbit Godot project, Godot 4.7.2 GDScript, workspace G:/Moj dysk/Projekty/Vajb Orbit (note: the real path contains diacritics; use the exact path from the dispatch). Read first, in order: AGENTS.md, docs/CONTRACTS.md sections 2, 3, 4, 5, 8, .agents/gen/slice2_task.md (Global rules + Pinned interface items 2 and 3 are your contract), ENGINE_SPEC.md sections 4.1, 4.3, 13 (combat rows). Your file set: vajb-orbit/game/weapons.gd and vajb-orbit/game/projectile.gd - both new. Implement the WeaponComponent (class_name WeaponComponent extends Node2D) and Projectile (class_name Projectile extends Area2D) exactly as pinned: setup(stats, state), set_fitted(weapon_ids), select_group(group), signals shot_fired and dry_fired, configure(config) with the pinned keys, signal detonated. The family table (DPS, ranges, travel, shield rule, burst) lives in weapons.gd as a typed const transcribed from ENGINE_SPEC.md sections 4.1 and 13 - laser 30 DPS range 500 instant, plasma 70 DPS range 450 +25 percent hull once shields are down, cannon 45 DPS range 600 bolt 1000 u/s burst 0.35 on 0.25 off, railgun 60 DPS range 800 slug 1400 u/s bypasses shields, rocket 180 alpha 1.2 s interval homing 2.2 rad/s 900 u/s destructible in flight, mine arm 2 s trigger 60 u. Energy shots resolve instantly at the cursor ray point capped at range; guns on rocks apply work at 10 percent through the existing Asteroid.apply_work seam. Ammo decrements go through PlayerState.set_ammo; empty pack = dry-fire feedback, no shot; mining laser spends no ammo and its existing path is untouched. Do not edit ship_fit.gd, player_state.gd, docs, project.godot, or anything outside your file set - the VAJB_WORKER_FILES hook denies out-of-set writes. Headless probes: res://tools/_probe_s2w1_*.gd (extends SceneTree, quit-terminated), delete them with their .uid before your report. Bounded runs only with --quit-after and stdout redirected to a log you read. Gate: the P1 suite must stay green (res://tests/headless_runner.tscn, --quit-after 1200, expect passed=53 failed=0) and add tests/test_engine2_weapons.gd registered in headless_runner.gd. Write your report to .agents/gen/slice2_w1_report.md: files with byte sizes, exact commands and outputs, acceptance measurements (every number from the pinned table re-measured), deviations.
```

---

## W2 — damage pipeline

```
You are worker W2 of engine slice 2 (Fight) for the Vajb Orbit Godot project, Godot 4.7.2 GDScript, workspace path as given in the dispatch. Read first: AGENTS.md, docs/CONTRACTS.md sections 2, 3, 8, .agents/gen/slice2_task.md (Global rules + Pinned interface items 1 and 4 are your contract), ENGINE_SPEC.md section 4.2. Your file set: vajb-orbit/game/damage.gd (new) and vajb-orbit/game/player_state.gd (additions only - the existing damage(amount, bypass_shield) with shield-first absorb and no carry-over is wave-1 verified law; do not reshape existing signals or methods). Implement class_name Damage extends RefCounted with static apply(target, amount, bypass_shield) - target implements take_damage(amount, bypass_shield), PlayerShip routes into PlayerState.damage - and static regen(state, delta, quiet_since) - base 2/s plus ShipStats.shield_regen, resumes after REGEN_QUIET 4.0 s without incoming damage. No floating damage numbers; feedback is HUD-side (W5). Headless probes res://tools/_probe_s2w2_*.gd, deleted with .uid before the report. Gate: P1 suite green (passed=53 failed=0) plus new tests/test_engine2_damage.gd registered in headless_runner.gd. Report to .agents/gen/slice2_w2_report.md with measurements.
```

---

## W3 — NPC archetypes

```
You are worker W3 of engine slice 2 (Fight) for the Vajb Orbit Godot project, Godot 4.7.2 GDScript, workspace path as given in the dispatch. Read first: AGENTS.md, docs/CONTRACTS.md sections 2, 3, 4, 6, .agents/gen/slice2_task.md (Global rules + Pinned interface items 5, 6, 7), ENGINE_SPEC.md sections 5 and 13 (aggro radii, NPC counts), docs/gameplay/13 (heat, pirates, hunters). Your file set: vajb-orbit/game/npc_registry.gd, vajb-orbit/game/npc_ship.gd, vajb-orbit/game/npc_brain.gd - all new. Implement exactly as pinned: NpcShip (class_name NpcShip extends Node2D, group npc_ship, setup/take_damage/signal died) flying with the same physics pattern as PlayerShip - no separate NPC physics, spec decision 1. NpcBrain (RefCounted) one state set IDLE to PATROL/SCAN to ALERT to ENGAGE to FLEE to RETURN/DESPAWN for all six archetypes; the archetype table in ENGINE_SPEC.md section 5 drives the differences; pirates flee below 30 percent hull, patrol scans Suspect+ and attacks Outlaws per doc 13, trader flees on Suspect+, station turret is static and high damage, hunters and boss are slice-4 seams - code the seam, ship nothing. Constants from ENGINE_SPEC.md section 13: aggro radii pirate 900, patrol scan 1000, turret 750; leash 2500; AGGRO_COOLDOWN 5.0; LOS check with rocks blocking. NpcRegistry: static NPCS array with the 13 section 4 density shape (S1 0-1 through S7 6-8, patrols only in owned space, one convoy per inhabited sector). Take_damage routes through the Damage class contract (item 4 of the brief) even if that file is still being written in parallel - code against the signature. Headless probes res://tools/_probe_s2w3_*.gd, deleted with .uid before the report. Gate: P1 suite green (passed=53 failed=0) plus tests/test_engine2_npcs.gd registered in headless_runner.gd. Report to .agents/gen/slice2_w3_report.md with measurements.
```

---

## W4 — loot tables

```
You are worker W4 of engine slice 2 (Fight) for the Vajb Orbit Godot project, Godot 4.7.2 GDScript, workspace path as given in the dispatch. Read first: AGENTS.md, .agents/gen/slice2_task.md (Global rules + Pinned interface item 8), docs/gameplay/06 in full (the loot and progression tables are your data source), ENGINE_SPEC.md section 6 (loot-from-kills and credit caches). Your file set: vajb-orbit/game/loot_tables.gd (new) only. Implement class_name LootTables extends RefCounted with static roll(kind: StringName, tier: int) -> Array[Dictionary] implementing the doc 06 tables, weighted, pure data and API - no scene tree work, no PlayerProfile calls, no economy_log calls (application is other workers' wiring). Rock and mineral rolls stay in the existing 02 section 5 code paths untouched. Static typing, tabs, no hex literals. Headless probe res://tools/_probe_s2w4_loot.gd rolls each table across tiers and prints the weight sums and sample yields, then is deleted with its .uid. Gate: P1 suite green (passed=53 failed=0) plus tests/test_engine2_loot.gd registered in headless_runner.gd. Report to .agents/gen/slice2_w4_report.md with measurements.
```

---

## W5 — HUD + wiring (run after W1–W4 land)

```
You are worker W5 of engine slice 2 (Fight) for the Vajb Orbit Godot project, Godot 4.7.2 GDScript, workspace path as given in the dispatch. W1-W4 have landed: WeaponComponent, Projectile, Damage, NpcShip/NpcBrain/NpcRegistry, LootTables exist with the pinned signatures in .agents/gen/slice2_task.md items 2-8 - read the actual files plus the four slice2_w1..w4 reports before wiring. Read also AGENTS.md, docs/CONTRACTS.md sections 2-9, ENGINE_SPEC.md sections 4, 5, 7, 8, 10, 13. Your file set: vajb-orbit/ui/hud/hud.gd, ui/hud/hud.tscn, game/game.gd, game/sector.gd, game/player_ship.gd (mount seam only - the same pattern MiningLaser uses; do not reshape flight code). Implement the wiring pinned in brief item 9 and 10: sector spawns NPC ships per NpcRegistry rows on entry with blip kinds hostile/neutral per section 8; lock marks a hostile inside ShipStats.lock_range via the existing set_target (no damage bonus, no auto-aim; ESC cancels order and lock); HUD set_target_info payload gains in_range and threat, reticle states map in-range/out-of-range/hostile, hit_marker() on confirmed damage; weapon groups via the existing HUD signal weapon_slot_selected into WeaponComponent.select_group; Space (fire_primary) fires; ammo deltas file to PlayerProfile on dock with economy_log lines; PlayerShip.warp_available() now reads the real enemy-engaged gate (hostile in Alert/Engage targeting the player and no damage in the last 5 s - the WARP_DAMAGE_QUIET const exists); death flow per ENGINE_SPEC.md section 7: hull 0, explosion, respawn docked at the last station visited, cargo dropped at the wreck with the 5-minute recovery window seam, heat persists - anything beyond that is slice-4 scope, report it. HUD styling: existing theme items and token helpers only, no hex literals, no font-size overrides. Headless probes res://tools/_probe_s2w5_*.gd deleted with .uid before the report. Gate: boot gates for game, menu, settings and station scenes each exit 0 (--quit-after 180, logs read); P1 suite green (passed=53 failed=0) plus tests/test_engine2_wiring.gd registered in headless_runner.gd. Report to .agents/gen/slice2_w5_report.md with measurements.
```

---

## W6 — review

```
You are worker W6, the mandatory reviewer of engine slice 2 (Fight) for the Vajb Orbit Godot project. Measure, never trust reports. Read: AGENTS.md, docs/CONTRACTS.md, ENGINE_SPEC.md sections 2, 4, 5, 7, 8, 10, 13, docs/gameplay 06, 08, 09, 13, every file in the worker file sets (weapons, projectile, damage, player_state, npc_registry, npc_ship, npc_brain, loot_tables, hud, game, sector, player_ship) and every .agents/gen/slice2_*_report.md. Re-run the key probes yourself (bounded --quit-after runs, logs read): weapon ranges and DPS, bolt/slug speeds, rocket homing and destructibility, mine arm and trigger, shield-first absorb and the 4 s regen quiet window, brain state walk, loot weight sums, sector NPC counts against the 13 section 4 shape. Check every number against ENGINE_SPEC.md section 13 and the gameplay docs; verify the pinned interfaces match across all files (signatures, data shapes, wiring); flag any invented constant. Classify findings HIGH (blocks the wave), MED (one fixer pass), LOW (goes to .agents/gen/LOW_BACKLOG.md). As the only CONTRACTS.md writer of this wave, append the slice-2 interface section and the changelog v1 line to docs/CONTRACTS.md. Output: .agents/gen/slice2_review_report.md with the findings table and the gates you ran.
```

---

## W7 — fixes

```
You are worker W7, the fixer of engine slice 2 (Fight). Read .agents/gen/slice2_review_report.md in full and fix every HIGH and MED finding; do not touch LOW items (they belong in .agents/gen/LOW_BACKLOG.md). One file set per finding cluster - declare the files you touch at the top of your report. Same global rules as the other workers: no editor, bounded headless runs with --quit-after, probes in res://tools/_probe_s2w7_*.gd deleted with .uid before the report, no edits to project.godot, addons, theme, docs or assets. Gate: boot gates exit 0 and the P1 suite stays green (passed=53 failed=0) plus the new engine2 tests. Report to .agents/gen/slice2_w7_report.md: per finding, what changed with measurements, and the gates re-run.
```

---

## W8 — re-review

```
You are worker W8, the re-reviewer of engine slice 2 (Fight). Same method as W6: measure, never trust reports. Verify every W7 fix is actually fixed (re-run the matching probe, re-derive the number), confirm no regression in the LOW set and the pinned interfaces still match, run the boot gates and the test gate. If clean: final line in the report is the closure statement and docs/CONTRACTS.md is confirmed current. If not: list the remaining findings; the wave loops at most once more. Output: .agents/gen/slice2_review2_report.md.
```
