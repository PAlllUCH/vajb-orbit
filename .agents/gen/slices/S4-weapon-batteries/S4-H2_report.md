---
slice: S4
worker: S4-H2
model: deepseek-v4-flash
status: actionable
gate: "508/0 → 521/0 (test_engine2_weapons 29 → 42; test_engine2_wiring unchanged at 13)"
---

# S4-H2 report — the volley and the strum

## Result

One trigger pull now discharges the whole battery exactly as CONTRACTS §16 v0.8.0 pins it.
`set_fitted` keeps one entry per barrel (the `_fitted.has(id)` guard is gone; unknown/family-less
ids still drop and the fit's order is kept), `battery_ids()` is the distinct ids of `fitted()` in
first-barrel order and every `weapon_1..5` / HUD slot addresses a battery through it,
`battery(base_id)` answers a battery's barrel **positions in `fitted()`** normalised through
`weapon_id` (`[]` for a family-less base), and the one-timer/one-weapon fire path is a per-barrel
volley: a pull arms the battery, every barrel draws a release offset in `[0, 40]` ms, and each
released barrel spends its own round or its own Energy frame, applies its own recoil, emits
`shot_fired` and deals its own damage — a barrel the family refuses is dry and never holds the
rest back.

**Gate: 521/0, twice, identical** (S3+H1's 508 + 13 new tests). The live `profile.cfg` md5 is
`3e6ee8d7e7145c4e37bbd8dc90f62f9b` and `economy_log.txt` is `eef2929404d1b3b2a4f30565e7b183b2`
— both read before the first run and after the last, unchanged from the wave-start record.

## What was built, with the numbers

| Deliverable | Where | Measured |
|---|---|---|
| per-barrel `fitted()` | `vajb-orbit/game/weapons.gd:407` (`set_fitted`) | `[w_laser, w_laser, w_laser]` → 3 entries, all `laser`; `[cannon, w_laser, cannon]` → `[cannon, laser, cannon]` (fit order, duplicates kept); `[w_mining, w_laser, w_nothing, w_laser]` → 2 entries |
| `battery_ids()` | `weapons.gd:462`, built in `_sync_barrels` (`:419`) | `[w_laser, w_cannon, w_laser, cannon, w_rocket]` → `[laser, cannon, rocket]` (five barrels, three batteries) |
| groups address batteries | `weapons.gd:450` (`selected_weapon`) | 3 lasers → group 1 `laser`, group 2 `&""`, `dry_reason` `none`; `[w_cannon, w_laser, w_cannon]` → group 2 `laser` |
| `battery(base_id)` | `weapons.gd:472` | `[w_laser, w_mining, w_cannon, w_laser]` → `w_laser` and `laser` both `[0, 2]`, `w_cannon` `[1]`, `w_mining` `[]`, `w_nothing` `[]` |
| the volley | `weapons.gd:650` (arm) / `:687` (release), driven from `:599` (`tick`) | 3-cannon pull at 1 ms steps: 3 shots, pack 30 → 27, last release **≤ 40 ms** (measured spans `[1, 9, 15]`, `[1, 3, 12]`, `[1, 32, 38]`, `[1, 8, 26]`, `[1, 2, 10]` ms) |
| per-barrel damage | `weapons.gd:739` (`_fire_beam_battery`), `:855` (`_apply_beam(…, barrels)`) | 3 lasers at `delta` 0.1 → one delivery of **9.000** (30 dps × 0.1 × 3), not 3.000 |
| per-barrel rounds | `weapons.gd:800` (`_fire_projectile`) | each of the 3 spawned shots carries `shot_damage(cannon)` 27.0; the one cannon pack loses exactly 3 |
| per-barrel Energy frame | `weapons.gd:739-750` | 3 lasers, `delta` 0.1 → **1.800** Energy (3 × 6 E/s × 0.1); a 1.200 pool pays 2 barrels, the third is dry **once**, the shaft still draws |
| a dry barrel never holds the battery | measured | pack of 1, 3 cannons → 1 shot, `dry_fired` **once** (not once per barrel), nothing else spawned |
| `BATTERY_STRUM_MS` | `weapons.gd:151` | `40`, asserted by `test_the_strum_ceiling_is_the_pinned_number` |

## Deviations from SLICE.md / the brief

1. **The strum's release clock is the battery's own earliest draw.** §16 rule 4 draws a release
   offset per barrel "uniformly in `[0, BATTERY_STRUM_MS]` ms". Taken literally with the clock at
   the pull, a **one-barrel** battery opens up to 40 ms late, which turns four pinned
   pull-then-`tick(0.016)` readings in `test_weapon_fx_f1.gd` into coin flips (a 16 ms frame
   clears only ~40 % of a `[0, 40]` ms draw): `:242-243` and `:281-282` assert the muzzle flash
   and the open shaft one frame after the pull, `:261-262` the release path, and `_fire_once`
   (`:559-560`) drives the whole family-cue block. (The beam suites are not at risk — g2 and f4
   tick `BEAM_FRAME` = 0.05 s.) So every barrel still draws its offset uniformly in
   `[0, BATTERY_STRUM_MS]` ms and the volley's clock is the battery's smallest draw: the lead
   barrel releases on the pull's own frame and each barrel behind it when its own offset elapses
   (`weapons.gd:650-666`). *Reversal: measure every offset from the pull itself — one line, and
   the four pinned feedback readings move to "within 40 ms".*
2. **A group switched mid-hold arms the battery it switched to** (`weapons.gd:624-628`). §16
   rule 4 arms on the rising edge only, so a battery that was never armed would fire nothing;
   switching `weapon_1..5` while the trigger is held would have gone silent until the trigger was
   released (today it fires the newly selected group at once). *Reversal: drop the
   `_armed_weapon` check and let a mid-hold switch fall silent.*
3. **A travelling barrel whose pack refuses it is disarmed for that pull** (`weapons.gd:687-704`,
   `:800-802`). Today's single timer retried every held frame, so a pack that refilled mid-hold
   resumed firing; §16 rule 4 makes the refusal that barrel's dry read for the volley.
   *Reversal: leave the barrel armed on `_dry` and retry next frame.*
4. **A closed burst window and an unready cadence timer keep the barrel armed** rather than
   reading it dry (`weapons.gd:696-699`), which is the shipped single-barrel behaviour ("a
   sustained pull is a stream of salvos, not one burst"). §16 rule 4 lists "the burst window
   closed" among a family's refusals; state 4 only arises if a window closes with a barrel still
   pending, which a pull's own `_burst_phase = 0` makes unreachable today. *Reversal: consume the
   arm and call `_dry` on a closed window.*
5. **The shaft and its contact feedback stay one read per frame; only the damage and the chip
   work are per barrel** (`_apply_beam`'s new `barrels` argument, `weapons.gd:855-874`). A
   battery has one muzzle and one aim point, so N barrels draw one shaft and make one contact
   read; the frame's damage is N × `dps × delta` in one `_deliver` call. Per-barrel reads would
   have machine-gunned the impact cue and the shield ring, because `_beam_read_due` is one clock
   for the shaft. *Reversal: loop `_apply_beam` once per paid barrel.*
6. **The weapons suite now owns a small tree-backed rig and one test double.** `_volley_rig`
   hangs the component on the profile autoload (the runner calls tests from inside its own
   `_ready`, where `/root` refuses children — the wiring suite's own measured note); the pure
   fixture cannot spawn a shot (`_spawn_shot` needs `get_tree()`) or play a muzzle flash (an
   untreed `AnimatedSprite2D.play()` logs `data.tree is null`, measured). `BeamTargetSpy`
   overrides **`_beam_target` only**, because a movable target needs a physics world the fixture
   does not build and a destructible shot on the segment takes the fizzle branch, so a beam's
   frame can otherwise carry no damage in a test. *Reversal: drop the rig and the spy with the
   five travelling/damage tests they carry.*
7. **The suite saves and restores the audio pools' round-robin cursors** (`_save_pools` /
   `_restore_pools`, the pattern `test_flight_beam_g2` already uses). Measured: without it the
   full gate failed `test_weapon_fx_f1.gd.test_the_laser_pool_round_robins_its_takes_within_the_specs_ranges`
   ("take 0 in order"), because the rigs play the families' cues for real. *Reversal: none
   wanted — a suite that sounds a cue hands the cursors back.*
8. **`fitted()` and `battery_ids()` keep the shipped typed signatures** (`-> Array[StringName]`),
   where §16's code block writes `-> Array`. A typed array is an `Array`, every caller
   (`_state.weapons`, the HUD, `assert_eq`) reads it unchanged, and the ship's own seam is typed
   (§8.2's block leaves both bare) — the alternative would widen a shipped return type for no
   consumer. *Reversal: strip the type annotation.*

## Tests that moved

| File | Move |
|---|---|
| `tests/test_engine2_weapons.gd` | **29 → 42**: 13 added (per-barrel `fitted()`, `battery_ids()`, groups-address-batteries, `battery()` shapes, the strum ceiling, the volley round-trip with the strum bound, each shot's own damage, the dry barrel, the per-barrel Energy frame, the split pool, the `_apply_beam` multiplier, the end-to-end battery damage). Every existing family, group, cadence, dry and projectile test holds, unchanged |
| `tests/test_engine2_wiring.gd` | `test_the_ship_mounts_its_weapons_component` rewritten to the per-barrel reading (H0 F9): `launched` no longer de-duplicates and now also asserts `battery_ids()`, plus a **bite check** that re-fits the mounted component with two barrels of one family, asserts 2 `fitted()` / 1 `battery_ids()` / `battery() == [0, 1]`, and puts the launched fit back. Count unchanged (13) |

## Evidence

```
$ source ~/.profile && godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=521 failed=0        (run A)
[SUMMARY] passed=521 failed=0        (run B, identical)
[s4-weapons] volley: releases at [1, 9, 15] ms, ceiling 40, pack 30 -> 27   (run A)
[s4-weapons] volley: releases at [1, 3, 12] ms, ceiling 40, pack 30 -> 27   (run B)

$ md5sum ".../Vajb Orbit/profile.cfg" ".../Vajb Orbit/economy_log.txt"   # before and after every run
3e6ee8d7e7145c4e37bbd8dc90f62f9b    # = the wave-start record
eef2929404d1b3b2a4f30565e7b183b2    # unchanged
```

**Mutation checks (each mutation reverted immediately and the suites re-verified green):**

| Mutation | Result |
|---|---|
| restore the `_fitted.has(id)` guard (dedup) | 9 failures: the 7 per-barrel/battery shape tests, the volley count, and the wiring bite check |
| `_fire_beam_battery` pays only the first open barrel | 2 failures: `test_a_laser_battery_pays_a_draw_per_barrel_every_frame` (0.600 vs 1.800) and the split-pool test |
| `_fire_beam_battery` forces `paid = 1` | 1 failure: `test_a_laser_battery_deals_one_frame_of_damage_per_barrel` (3.000 vs 9.000) |

**Scratch-store rule (T-93).** No `--script` probe was run at all — every number above came from
`headless_runner.tscn`, whose `_seed_scratch_store` repoints `save_path` at
`user://_gate_scratch/profile.cfg` and resets the store before the first suite, including every
`--suite=` run. Parse checks of the two suites used `--check-only` (parses, runs nothing, boots
no autoload). The two live-store md5s were read before the first run and after the last.

**One pre-existing error line, not fixed, not mine:** `SCRIPT ERROR: Cannot call method 'call' on
a previously freed instance … at test_a_held_beam_reads_one_hit_per_contact_interval
(res://tests/test_weapon_fx_f4.gd:178)`. `_clear()` (`test_weapon_fx_f4.gd:470-480`) frees every
child of `_root`, and the test then hands the freed `hull` back into `_beam_frame` (`:178`); the
line is that suite's own fixture, recorded before this wave's changes (`S4-H1_report.md:117-119`
reads the same line off the 508/0 run) and it predates H2's edit (no path in it changed). The
suite still passes. Left alone per the don't-fix-unrelated-failures rule; see Follow-ups.

## Files touched

- `vajb-orbit/game/weapons.gd` — `BATTERY_STRUM_MS`; the per-barrel state (`_barrel_timers`,
  `_armed`, `_beam_open`, `_batteries`, `_armed_weapon`, `_strum_rng`); `set_fitted` +
  `_sync_barrels`; `battery_ids()` / `battery()` / `selected_weapon()`; `tick` +
  `_arm_battery` / `_disarm_battery` / `_release_battery` / `_advance_barrel_timers` /
  `_close_beams`; `_fire_beam` → `_fire_beam_battery`; `_fire_projectile` per barrel;
  `_apply_beam`'s `barrels` argument
- `vajb-orbit/tests/test_engine2_weapons.gd` — 13 volley tests, the tree-backed `_volley_rig`,
  `_shots`/`_clear_shots`, `_release_trigger`, `_save_pools`/`_restore_pools`, `DamageSink`,
  `BeamTargetSpy`
- `vajb-orbit/tests/test_engine2_wiring.gd` — the per-barrel mounted-fit assertion + its bite
  check, the `WeaponScript` preload

No file outside the declared set was edited; nothing was created (no new `.uid` sidecar).

## Follow-ups

| Item | Kind | Where |
|---|---|---|
| The HUD's W-slot buttons map a **cell** index to a group (`select_group(slot + 1)`), so on a hull whose W row holds fewer batteries than cells the trailing slots select nothing and a battery need not sit at its own cell's slot. Unchanged from before S4 for duplicate fits (they collapsed to one group); the two index spaces are H0 F2's | [SPEC] | `vajb-orbit/game/game.gd:1358-1359`, `docs/CONTRACTS.md` §16 rule 2 |
| A 3-barrel volley triples the per-trigger ammo delta, which multiplies H0 F3's knock-on: `_file_ammo_report` is not idempotent within one launch, and `ammo_slot` reads `PlayerState.WEAPONS`' catalogue order while the launch sizes the packs in fit order | [SPEC] | `vajb-orbit/game/game.gd:1247-1249`, `docs/CONTRACTS.md:781-791` |
| `test_weapon_fx_f4.gd:178` hands a freed hull into `_beam_frame` after `_clear()` and logs a SCRIPT ERROR on every gate run (pre-existing, suite green). One-line fixture fix: stage a fresh hull instead of the freed one | [HARNESS] | `vajb-orbit/tests/test_weapon_fx_f4.gd:178`, `:470-480` |
| The strum test is a **bound**: it proves no barrel releases later than 40 ms and that the lead barrel releases on the pull's frame, but nothing pins that a spread exists (`[1, 1, 1]` would pass — the pin's own reversal is strum 0, so that is intended) | [HARNESS] | `vajb-orbit/tests/test_engine2_weapons.gd` |
