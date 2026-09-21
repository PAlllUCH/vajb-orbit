# G2 — beam polish + weapons/projectile warning sweep (report)

Wave: **flight feel & beam polish** (`.agents/gen/flight_beam_wave_task.md`, owner rulings
2026-09-21 third round). Worker: **G2**. Status: **done** — three beam defects fixed, the
warning sweep in the two owned files is at zero, five new tests, gate green at a grown
count.

Declared file set (the hook enforced it):

- `vajb-orbit/game/weapons.gd`
- `vajb-orbit/game/projectile.gd`
- `vajb-orbit/tests/` — `test_flight_beam_g2.gd` (new suite) and `probe_g2_lint.gd` /
  `probe_g2_lint.tscn` (new ledger probe)

Nothing outside that set was touched: no asset, no theme, no `project.godot`, no `addons/`,
no `docs/`, and no damage, cadence, range, Energy or ammo value moved (proof in §7).

---

## 1. Defect 1 — the shaft stopped at the aim point, not at what it hit (owner finding W2)

`_fire_beam` used to draw the shaft to `from + dir * reach` **before** `_beam_target()` was
called, so a shot at a rock or a hull passed straight through it to the cursor's reach.

`vajb-orbit/game/weapons.gd:529-566` now resolves the target first and chooses the endpoint
from it:

```gdscript
	var to := from + offset.normalized() * reach
	var target := _beam_target(from, to)
	var endpoint := to
	if not target.is_empty():
		endpoint = target[&"point"]
	_draw_beam(endpoint)
	_beam_started(weapon)
	_advance_fire_feedback(weapon, delta)
	if target.is_empty():
		return
```

- **Hit**: the shaft ends on `target[&"point"]` — the ray's own resolved point — and
  `_apply_beam` / the rocket branch receive the same `endpoint` (they previously read
  `target[&"point"]` directly, so the drawn shaft and the damage site are now the same
  value by construction rather than by coincidence).
- **Miss** (`target.is_empty()`): the shaft keeps the weapon's own reach, exactly as before,
  so an empty shot still shows. Nothing else about the miss path changed.
- `_beam_started` and the new `_advance_fire_feedback` are called on both paths, so the
  opening flash/bed and the held-feedback cycle behave identically whether the shot lands
  or not.

Reach, damage, Energy draw and the family table are untouched.

---

## 2. Defect 2 — a laser chipping a rock had no cue and no FX (owner finding W3)

`_apply_beam`'s rock branch called `apply_work` and `return`ed: no cue, no burst, unlike the
hull branch F4 fixed.

**The cue.** AUDIO_SPEC §8's **S8 "Mining chip hit"** is the pair FX_SPEC §1.6 names for
this sheet, so the chip cue is S8's own take: `sfx_mining_chip_01`.
`vajb-orbit/game/weapons.gd:245` declares

```gdscript
const CHIP_CUE: StringName = &"sfx_mining_chip_01"
```

`_01` and not the 01-04 round-robin, because `sfx_mining_chip_04` is the documented 21 s
outlier (ASSET_AUDIT item 8) — the same reasoning `mining_laser.gd:47` records for its own
`CHIP_CUE`. The suite asserts `WeaponScript.CHIP_CUE == MiningLaserScript.CHIP_CUE`, so the
two constants cannot drift. It plays through `_play_chip_cue()` (`weapons.gd:704`), the same
one-shot `play_sfx` route `mining_laser.gd:_play_chip` uses.

**The burst.** FX_SPEC line 138 names `fx_mining_beam.png` for exactly this; its §1.6 row
fixes the read at "4-frame mini sheet at 20 FPS = 0.2 s, one-shot per S8 chip event".
`projectile.gd`'s `FEEDBACK` table is this codebase's one owner of shipped effect sheets, so
the row lives there (`vajb-orbit/game/projectile.gd:264`):

```gdscript
	&"chip": {
		&"texture": "res://assets/fx/fx_mining_beam.png",
		&"regions": [
			Rect2(0.0, 752.0, 500.0, 500.0),
			Rect2(500.0, 759.0, 500.0, 500.0),
			Rect2(1019.0, 771.0, 500.0, 500.0),
			Rect2(1548.0, 755.0, 500.0, 500.0),
		],
		&"source": Vector2(500.0, 500.0),
		&"world": 40.0,
		&"fps": 20.0,
	},
```

with `spawn_chip_sparks(parent, at)` beside `spawn_arc_spark` (`projectile.gd:1158`) as the
reader `weapons.gd`'s rock branch calls.

*How the regions were derived (no asset was modified — the sheet was read, not cut).* The
master is a 2048×2048 RGB render carrying four spark bursts in a row. The ink was masked at
a luminance threshold and the four clusters measured, each burst's dense core sitting near
y ≈ 1000-1035 with x-centres ≈ 240 / 756 / 1270 / 1797. Each region is a uniform 500×500 box
centred on its own burst, clamped into the sheet, so every frame is the same size and the
burst is centred on the sprite origin (`play_once` centres the frame on the hit point). The
four crops were re-read side by side to confirm the §1.6 reading order (burst → dissipating →
fainter → nearly empty); the measurement and the crop strip are kept as evidence in
`.agents/gen/g2/mining_crops.png`, `mining_sheet_small.png`.

**The guard.** The hull branch's per-contact rate guard is now one function,
`_beam_read_due(target, delta)` (`weapons.gd:669`), used by both reads:

```gdscript
	if hull_body != null and hull_body.is_in_group(ProjectileScript.ROCK_GROUP):
		if hull_body.has_method(&"apply_work"):
			hull_body.call(&"apply_work", amount * GUN_CHIP_RATE)
		if _beam_read_due(collider, delta):
			_play_chip_cue()
			ProjectileScript.spawn_chip_sparks(_hit_fx_parent(collider), point)
		return
```

The guard's arithmetic is byte-for-byte the hull branch's old one (fresh contact reads at
once, then `BEAM_HIT_INTERVAL` = 0.25 s apart), so a rock chips on the same cadence a hull
reads. `_hide_beam` still clears the contact, so a new hold reads from its own first frame.
The chip work itself (`dps × delta × GUN_CHIP_RATE`) is unchanged; the suite asserts the
amount it lands.

---

## 3. Defect 3 — a held beam's fire feedback looped nowhere (owner finding W4)

The muzzle flash and the family cue played once per **release**: `shot_fired` is emitted
once per hold for the instant families (`_beam_started` guards on `_beam_live`).

**The conflict that decides the shape of the fix.** FX_SPEC §1.2 fixes the flash itself at
"4 frames at 20 FPS = 0.2 s total, **one-shot, no loop**", so looping the animation would
contradict the spec. The owner's ask ("they should loop") is therefore implemented as
*replaying the same one-shot once per its own cycle*, for as long as the trigger is held —
the animation is then unbroken, which is what "loop" reads as on screen, while the sheet
stays a one-shot exactly as specced.

`vajb-orbit/game/weapons.gd:731`:

```gdscript
func _advance_fire_feedback(weapon: StringName, delta: float) -> void:
	_beam_feedback_clock += maxf(delta, 0.0)
	if _beam_feedback_clock < FLASH_SECONDS:
		return
	_beam_feedback_clock = fmod(_beam_feedback_clock, FLASH_SECONDS)
	_on_shot_fired(weapon)
```

- Called from `_fire_beam` on every frame the beam is up (hit or miss).
- **`FLASH_SECONDS` is derived, not invented** — `weapons.gd:213`: 0.2 s, the spec's own
  "4 frames at 20 FPS"; the suite asserts
  `FLASH_SECONDS == FLASH_FRAMES.size() / FLASH_FPS` so the two cannot drift.
- The clock is reset in `_beam_started` (the hold's opening frame, so the first replay is one
  full cycle after the opening flash) and in `_hide_beam` (release, hull swap, death), so
  each hold starts from its own opening flash.
- It goes through `_on_shot_fired`, the one feedback route (flash at the muzzle + the
  family's cue through `play_pool`), so the flash **and** the sound repeat together.
- **`shot_fired` is deliberately not re-emitted.** CONTRACTS §4 pins it as "once per released
  shot / per beam hold"; the loop repeats only what the hold looks and sounds like. The
  suite asserts one emission per hold while the flash count grows.

---

## 4. Warning sweep — `weapons.gd` + `projectile.gd` at zero

Ledger: the `--headless --debug` debugger-stdout ledger CONTRACTS §9 documents. New probe
`vajb-orbit/tests/probe_g2_lint.gd` (same mechanism as `probe_w5_lint.gd`: a printed marker,
one file loaded with `CACHE_MODE_IGNORE`, another marker, so every `WARNING:` between two
markers belongs to the file the opening marker names).

```text
~/.local/bin/godot --headless --debug --path vajb-orbit res://tests/probe_g2_lint.tscn --quit-after 600
```

| file | `SHADOWED_*` warning sites before | after |
|---|---|---|
| `res://game/weapons.gd` | **23** | **0** |
| `res://game/projectile.gd` | **6** | **0** |
| positive control `res://ui/hud/minimap.gd` | 1 | 1 (still warns — the run is not blind) |
| negative control `res://autoload/world_clock.gd` | 0 | 0 |

Raw logs: `.agents/gen/g2/lint_before.log` (36 `WARNING:` lines, 29 unique sites),
`.agents/gen/g2/lint_after.log` (1 `WARNING:` line, the control's).
Cross-check with the wave's own reference ledger (`probe_w5_lint.tscn`): its `weapons.gd`
positive-control block goes from 23 lines to **0** while its minimap control still reports 1
(`lint_w5_before.log` / `lint_w5_after.log`).

Every fix is a rename of a **parameter or a local** — no function, signal, constant or
method name moved, and GDScript has no named arguments, so no call site changes:

| site | shadowed | renamed to |
|---|---|---|
| `weapons.gd:319` `set_fitted(weapon_ids)` | the `weapon_ids()` static | `ids` |
| 21 × `weapons.gd` `weapon_id:` parameters (`is_fitted`, `_fire_beam`, `_fire_projectile`, `_spawn_shot`, `_apply_beam`, `_beam_started`, `_dry`, `_on_shot_fired`, `_play_fire_cue`, `_seeker_target`, `_ammo_available`, `_consume_ammo`, `row_of`, `family_of`, `fire_cue_of`, `fire_take_of`, `range_of`, `dps_of`, `interval_of`, `shot_damage`, `ammo_slot`) | the `weapon_id()` static | `weapon` (instance) / `id` (statics, matching the names CONTRACTS §4 already uses) |
| `weapons.gd:1398` `var owner` in `ammo_slot` | `Node.owner` | `pack` |
| `projectile.gd:376` `var source` in `configure` | the `source()` accessor | `src` |
| `projectile.gd:456` `retarget(decoy)` | the `decoy()` accessor | `lure` |
| `projectile.gd:533` `var decoy` in `_reaches_decoy` | the `decoy()` accessor | `lure` |
| `projectile.gd:1098` `feedback_row(name)` | `Node.name` | `row_name` |
| `projectile.gd:1109` `spawn_sheet(parent, name, at)` | `Node.name` | `fx_name` |
| `projectile.gd:1339` `var material` in `_plume_material` | `CanvasItem.material` | `plume` |

Behaviour is byte-identical: no expression, constant or branch changed with the renames; the
gate (which treats GDScript warnings as errors) and every pre-existing suite stayed green.

---

## 5. Tests — one suite, five tests, each one measured against a mutation

`vajb-orbit/tests/test_flight_beam_g2.gd` (new, synchronous like its F1/F4 neighbours, so the
gate's non-awaiting runner can read it):

| test | behaviour |
|---|---|
| `test_a_shot_that_hits_nothing_still_draws_the_weapons_own_reach` | a miss keeps the full reach |
| `test_the_shaft_stops_on_the_point_its_ray_resolved` | a resolved hit stops the shaft on the target's own point, short of the aim point |
| `test_a_laser_chipping_a_rock_plays_the_chip_cue_and_the_burst` | the chip cue (== `mining_laser.gd`'s), the `fx_mining_beam.png` burst (4 frames, 20 FPS, one-shot, additive, on the contact) and the unchanged `dps × delta × 10 %` chip work |
| `test_a_held_beams_rock_chip_reads_on_hulls_own_contact_guard` | the same per-contact guard as the hull branch: one chip on contact, one per `BEAM_HIT_INTERVAL`, a fresh rock reads at once, a held-back frame plays neither the cue nor a burst |
| `test_a_held_beams_feedback_repeats_for_as_long_as_the_trigger_is_held` | the feedback repeats on the flash's own cycle while held, stops on release, restarts with a new hold's own flash, and `shot_fired` stays one per hold |

Each is a real test, not a tautology — reverting the fix fails it (evidence logs
`.agents/gen/g2/mutation_*.log`, one mutation per behaviour, each reverting exactly that fix
in `weapons.gd` and running only this suite):

| mutation | result |
|---|---|
| `_draw_beam(endpoint)` → `_draw_beam(to)` | `[FAIL] …test_the_shaft_stops_on_the_point_its_ray_resolved: the shaft ends on the target's own point (300.0)` → passed=4 failed=1 |
| rock branch returns right after `apply_work` (the old code) | `[FAIL] …test_a_held_beams_rock_chip_reads_on_hulls_own_contact_guard: the first frame of contact chips` and `[FAIL] …test_a_laser_chipping_a_rock_plays_the_chip_cue_and_the_burst: …(it played nothing before)` → passed=3 failed=2 |
| `_advance_fire_feedback` returns before replaying | `[FAIL] …test_a_held_beams_feedback_repeats_for_as_long_as_the_trigger_is_held: and comes round again a cycle later, instead of one flash per release` → passed=4 failed=1 |

**Harness limits the fixtures respect** (both documented in the suite's header):

- `_beam_target`'s physics ray cannot see a body added in the same frame (measured: empty for
  a collider born this frame, and F3's probe awaits a physics frame for exactly that reason),
  so the resolved-hit case is driven through `_beam_target`'s other half — a destructible shot
  on the segment, the route `test_weapon_fx_f4.gd` already uses — which yields a genuine
  `point` for the shaft to stop on.
- no frame passes during a test, so a spawned sheet never reaches `animation_finished`; a
  count of live effect nodes is therefore a count of what the code asked for.

---

## 6. Gate

```text
~/.local/bin/godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
```

| run | result |
|---|---|
| wave start (before any worker's edit) | `[SUMMARY] passed=277 failed=0`, exit 0 |
| after this worker's product edits, before its suite | `passed=276 failed=2` — both G1's, whose `test_flight_feel_g1.gd` was mid-edit in the parallel lane (`ship_fit.gd` turn_rate not yet retuned, and their new suite's parse errors); no weapon-suite failure |
| **final, after all edits and the new suite** | **`[SUMMARY] passed=294 failed=0`, exit 0** |

This worker's contribution is **+5 tests** (`flight_beam_g2`); G1's parallel suite supplies
the other +12. The one `SCRIPT ERROR` in the run is pre-existing and identical before and
after (`test_weapon_fx_f4.gd:176`, a call on a freed instance in the F4 suite, present in the
baseline log too — reported, not touched).

---

## 7. Numbers that did not move

- `FAMILIES` (ranges, dps, draw, alpha, interval, burst cycle, speed, turn_rate, arm,
  trigger), `GUN_CHIP_RATE`, `SHOT_MASS`, `KINETIC_INTERVAL`, `BEAM_HIT_INTERVAL`,
  `CHAFF_*`, `FLARE_LURE`, the masks, `DEFAULT_MASS`, `HIT_RADIUS`: **not one byte of the
  diff touches them.**
- The only new constants are `CHIP_CUE` (an existing shipped cue's name) and
  `FLASH_SECONDS` (the flash sheet's own `4 / 20`), plus the `chip` row's own numbers
  (regions, `world`, `fps`), which are presentation, not balance.
- The chip work a rock receives is unchanged and asserted:
  `30 dps × 0.05 s × 0.10 = 0.15`.
- The hull read is unchanged in cadence and amount; F4's
  `test_a_beam_that_lands_on_a_hull_plays_the_impact_cue_and_the_ring` (asserting
  `30 dps × 0.05 s = 1.5`) still passes.

---

## 8. Deviations, proposals and things for the reviewer

1. **Parameter names vs CONTRACTS §4's prose.** CONTRACTS §4 text spells
   `set_fitted(weapon_ids)` and `retarget(decoy: Node2D)`. The parameters were renamed (the
   renames the warning sweep requires) and both doc strings are now nominal, not literal.
   No call contract changed: GDScript has no named arguments, every caller is positional, and
   the statics' own parameters were renamed to `id`, which is what CONTRACTS §4 already
   prints for them. G4 should treat the doc text as stale rather than the code as broken; I
   could not correct the doc (no `docs/**` in this worker's set).
2. **The burst's world size is the wiring's own.** FX_SPEC §1.6 fixes the sheet, the palette
   and "4-frame mini sheet at 20 FPS" but states no world size for the burst; `world: 40.0`
   matches §7.2's arc-spark read and is one constant, recorded as reported in the row's own
   doc comment (`projectile.gd:208`).
3. **The chip cue is S8's transient, not `sfx_impact_rock`.** FX_SPEC §1.6 pairs this sheet
   with "S8 Mining chip hit" and line 138 names the sheet for the chip event; `sfx_impact_rock`
   is the impact read the *projectile* route already plays on a rock hit. If the owner wanted
   a gun chip to read as a rock impact instead, the change is the one constant `CHIP_CUE`.
4. **A shared-autoload side effect my suite caused, and how it is handled.** Firing a beam
   plays its family cue through `AudioManager`'s round-robin pool, which advances a cursor
   shared by every suite; `test_weapon_fx_f1.gd` asserts the laser pool cycles from take 0,
   so its reading depends on how many shots ran before it. With this suite's beams in front of
   it the gate went red (`passed=293 failed=1`, `take 0 in order`) — a test-order artifact, not
   a product regression. The suite now snapshots `AudioManager._pool_next` in `suite_setup`
   and restores it in `suite_teardown` (`test_flight_beam_g2.gd:114/126`), so a suite that
   fires leaves the cursor where it found it and F1's reading is its own again. Flagging it
   because a reviewer will see private-state restoration in a test; the alternative was
   editing another worker's assertion, which the wave's rules forbid.
5. **The held loop is a replay, not an animation loop.** FX_SPEC §1.2 says the flash is
   "one-shot, no loop", so the sheet was not made loopable; the feedback replays the same
   one-shot on its own cycle. If the owner meant a genuinely looping animation, the reversal
   is `_advance_fire_feedback` plus a `loop` flag on the flash's `SpriteFrames`.
6. **Pre-existing, not fixed** (outside this worker's brief): the `SCRIPT ERROR` in
   `test_weapon_fx_f4.gd:176` (a `call` on a freed instance — the test still passes), and the
   23 warning sites in other files the owner's console shows (G3's lane).

---

## 9. Reversal paths

| change | reversal |
|---|---|
| shaft endpoint | `_draw_beam(to)` instead of `_draw_beam(endpoint)` |
| rock chip cue + burst | delete the `if _beam_read_due(collider, delta):` block in `_apply_beam`'s rock branch |
| rock chip cue choice | `const CHIP_CUE := &"sfx_impact_rock"` |
| chip burst's size | the `chip` row's `world` value (one number) |
| `chip` row removal | delete the row; `spawn_chip_sparks` then returns null and the branch draws nothing |
| held feedback loop | `FLASH_SECONDS` (one number), or return early in `_advance_fire_feedback` |
| warning sweep | `git checkout` the two files; every rename is mechanical and independent |
| suite's pool-cursor restore | delete `_snapshot_pools`/`_restore_pools` and their two calls |

---

## 10. Evidence index (`.agents/gen/g2/`)

| file | what it is |
|---|---|
| `lint_before.log` / `lint_after.log` | this worker's own ledger, before and after |
| `lint_w5_before.log` / `lint_w5_after.log` | the wave's reference ledger (`probe_w5_lint`), cross-check |
| `weapons_before_pairs.txt`, `projectile_before_pairs.txt` | the 29 sites, with lines |
| `gate_before.log` | `passed=277 failed=0` at wave start |
| `gate_after.log` | final `passed=294 failed=0` |
| `suite_g2.log`, `suite_pair.log` | this suite alone (5/0) and with F1's suite (27/0) |
| `mutation_endpoint.log`, `mutation_chip.log`, `mutation_loop.log` | one revert per behaviour: each fails its own test |
| `mining_sheet_small.png`, `mining_crops.png` | the sheet and the four regions re-read, the region derivation |
