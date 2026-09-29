---
slice: S21
worker: S21-B3
model: deepseek/deepseek-flash (reasoning-effort max)
status: actionable
gate: "936/1 → 941/0 (the one failure was S19's byte-seal row, re-pinned here)"
---

# S21-B3 report

## Result
A9c/A9d/A10/A11 landed plus amendment 3's two owner-ruled items. `tests/test_s21_stability.gd`
20 → **23 rows** (`--suite=…` → `23/0`); the full gate on a fresh scratch store reads
`[SUMMARY] passed=941 failed=0` = 937 rows (B2's tree) + 3 (A9c×2, A9d) + 1 (A10's s19 row), with
S19's seal row flipping fail→pass. `game/damage.gd` byte-identical; no doc, `project.godot` or
`addons/` touched.

## Acceptance list answers
- **A9c — DONE.** `respawn(now)` stamps and rolls off **one** reading: `var stamp := now if now >= 0
  else Clock.now()` (`game/asteroid_field.gd:189`) reaches `_roll_rocks(count, now)` (`:231`),
  `_rolled_yield(tier, now)` (`:251`) and `_yield_multiplier(now)` (`:618`, `Clock.now()` is now the
  default only), so a driven stamp rolls the ×0.7 band it just opened, not the wall clock's reading;
  `setup()` and the cleave path keep the clock. `Asteroid.setup` clears the S16 marker with its other
  resets (`_cleave_child = false`, `game/asteroid.gd:290`). Rows `test_s21_stability.gd:747,791`.
- **A9d — DONE.** `move_barrel` reads the moved barrel's name **before** the record write
  (`var name_text := _rack_barrel_name(profile, from_rack, from_position)`,
  `ui/station/armory_panel.gd:2375`) and emits it (`:2381`) — the order `remove_barrel` (`:2399-2410`)
  already used — so an emptied source or a swap can no longer print `MOVED ·  · B2` or the wrong
  barrel. Row `test_s21_stability.gd:818`, both failure modes asserted.
- **A10 — DONE.** The f4 held-beam row's release/re-hold block wipes only the ripple nodes, never
  `_clear()` (which frees the rig), so its final assertion runs on a live `guns`/`hull`
  (`tests/test_weapon_fx_f4.gd:177-183`); L61/L237's `SCRIPT ERROR` is gone from the gate log. The s19
  row pins the two `direction` spellings as one: `test_the_direction_ctx_key_is_one_spelling`
  (`tests/test_s19_quadrants.gd:665`, +1 gate row).
- **A11 — DONE.** The wave's const table is below; `damage.gd`'s hash is 5cabf3d9… (Evidence); no gate
  row outside §8's list moved (Evidence: the all-suite count check + the 937→941 arithmetic).

## Amendment 3's two owner-ruled items
- **The S19 byte-seal re-pin — DISCLOSED, and the shipped value is NOT the amendment's literal.** The
  item names B1's pre-mask hash `728268c5…`; my own second item (below) edits the *same file*, so the
  finished tree hashes `a694170c9783b44ed1dd91e07d0632288535eef91ef391f4036ff2ede9b889f7`, the only
  value that keeps the seal green. The pin carries it with the chain in its own comment
  (`tests/test_s19_quadrants.gd:95-100`); the other three hashes are untouched. Bucket 2, for R1/owner
  adjudication: the literal and this value cannot both hold.
- **A3's reach widened — DONE, two-sided push measured.** `HULL_MASK` is now rock|ship
  (`Asteroid.COLLISION_LAYER | HULL_LAYER` = 3, `game/npc_ship.gd:71`) on the body (`:220`); the brain's
  LOS ray keeps the rock layer under its own const `LOS_MASK` (`:77`, used at `:604` — Deviations (b)).
  Probe, same scenario, before → after: `velocity player 450.000->0.000 npc 0.000->0.000` →
  `player 450.000->258.872 npc 0.000->258.872` (both hulls leave at the pair's common speed; damage
  stayed exactly row 15's 93.789474 on both sides). Rows re-pinned to the measured truth:
  `tests/test_engine2_npc.gd:400-411` and `tests/test_s6_heat.gd:238-245`; both counts unchanged.

## Deviations from SLICE.md
- **(a) The seal pin's value** (above): the amendment's literal was B1's hash, the file moves again
  under my own mask item. Reversal: pin `728268c5…` and accept a red seal row, or restore the file.
- **(b) `LOS_MASK` is new (`game/npc_ship.gd:77`).** The widened hull mask could not stay shared with
  `_line_of_sight`: the ray is cast to the contact's centre, so a ship-layer mask reports the target's
  own hull as the blocker and no NPC could see what it shoots. 13 §5's rock-blocking check stands under
  its own const. Reversal: delete it and point `_line_of_sight` at `Asteroid.COLLISION_LAYER`.
- **(c) The gate's second `SCRIPT ERROR` is pre-existing and left.** `tests/test_s20_chrome_unify.gd:276`
  calls the inner class's static `slot_plate_rect` on the panel instance; disclosed as S20's own miss in
  `S21_prompts.md` ("leave both cures to the fixer"). Not my region; the row still prints `[PASS]`.
- **(d) My two new rows were proven by a temporary revert of their own fixes**: with L73/L176 reverted
  the suite reads `passed=21 failed=2` (exactly those two rows), restored it reads `23/0`; both files
  byte-restored and the gate re-run after (Evidence).

## Evidence
- Value flip (A10): `--suite=test_weapon_fx_f4` with the row's expected `1` → `2` (message carrying the
  read) → `[FAIL] …test_a_held_beam_reads_one_hit_per_contact_interval: flip probe: a new hold reads
  from its own first frame (read 1)`, `passed=5 failed=1`; flip reverted → `6/0`, no `SCRIPT ERROR`.
- Gate, fresh scratch store — `XDG_DATA_HOME=$(mktemp -d) godot --headless --path "$VAJB_PROJ"
  res://tests/headless_runner.tscn --quit-after 1200` → `[SUMMARY] passed=941 failed=0`, exit 0; no
  `[FAIL]`, no `[SKIP]`; the only `SCRIPT ERROR` is Deviations (c)'s. Whole s21 suite → `23/0`.
- A11 no-row-moved proof: every suite's `[PASS]` count equals its file's `func test_` count — 80
  suites, `sum(func test_) = 941`, mismatches `[]` — so no row was dropped or renamed anywhere; with
  zero failures and 941 = 937 + 3 + 1, only the rows this wave added and the rows §8 names moved.
  Named suites: s21 23 (20+3), s19 20 (19+1, seal now green), f4 6 (same count, dead row executes),
  engine2_npc 28, s6_heat 23, engine2_dock 2, engine2_fixes 17, engine2_wiring 13, p2b1_outfitting 13,
  p1_market 13, s3_auction 11, p2b_services 14, s13_mining_batteries 4, s5_ammo_cargo 14,
  s5_commerce 7 (the last two B2's own deviation (c)).
- A11 `damage.gd` proof: `git cat-file -p HEAD:vajb-orbit/game/damage.gd | sha256sum` =
  `5cabf3d9302fe942aff2ad97b4f3dc85c298e7e204fffb0e86f89e444cbf6269`, identical to the working file and
  to the seal's own pin (`tests/test_s19_quadrants.gd:95`, `tests/probe_s19r1_review.gd:693`);
  `git diff HEAD -- game/damage.gd` empty. The four forbidden files now: damage 5cabf3d9…, npc_ship
  a694170c… (re-pinned), npc_brain e39440bf…, weapons fcdc549f… — only the re-pinned one moved.
- Two-sided push / mask rows: `res://tests/probe_s21_contacts.tscn --quit-after 3000` (scratch store),
  the before/after velocity lines quoted above; `--suite=test_s19_quadrants --suite=test_engine2_npc
  --suite=test_s6_heat --suite=test_weapon_fx_f4` → `77/0`.

## New consts (the wave's table — A11)
| Const / value | Site | Reversal |
|---|---|---|
| `GATE_REFUSED_FUNDS_PROMPT` | `game/game.gd:145` (B1) | delete it and its rung |
| `_wreck_drops` (static), `_crossing_routed`, `_gate_in_ring`, `_drop_faces` | `game/game.gd:263,365,369,373` (B1) | B1 (a): delete the ledger + its three helpers; drop each flag, its writer and its readers |
| `_heat_play_time` (now `static`) | `game/game.gd:381` (B1) | remove `static` |
| `Pickup.lifetime`, the `window` arg, `signal collected` | `game/pickup.gd:40,63,81` (B1) | revert to `LIFETIME`; delete the signal |
| `SHIP_GROUPS`, `hull_behind`, `ram_authority`, `die`/`is_dead`/`step_velocity`/`apply_collision_damage` | `game/player_ship.gd:95,588-623,1182,1207` (B1) | inline the group names; delete the statics; restore `_switch_ship_off`'s switch-off and `_on_hull_death` |
| `HullBody.collision_mask` 1 → 3 | `game/player_ship.tscn:18` (B1) | back to 1 |
| `KEY_AMMO_REM = &"ammo_rem"` | `autoload/player_profile.gd:97` (B2) | delete it, the remainder bank and its four readers/writers |
| `ACTION_OWNED = "OWNED"` | `ui/station/auction_panel.gd:131` (B2) | delete it; render `ACTION_BUY` with `disabled = false` |
| `FIXTURE_PACKS`, `FIXTURE_FAMILIES` | the three `test_engine2_*.gd` (B2) | test-local; drop them and their staging |
| `HULL_MASK` 1 → 3 (`COLLISION_LAYER \| HULL_LAYER`) | `game/npc_ship.gd:71` (B3) | drop `\| HULL_LAYER`; re-pin the two rows back to rock-only |
| `LOS_MASK = Asteroid.COLLISION_LAYER` (1) | `game/npc_ship.gd:77` (B3) | delete it; point `_line_of_sight` at `Asteroid.COLLISION_LAYER` |
| `FORBIDDEN_FILES["res://game/npc_ship.gd"]` → `a694170c…`; `FIELD_SEED = 20260928` | `tests/test_s19_quadrants.gd:95-100`; `tests/test_s21_stability.gd:64` (B3) | restore the pinned string (Deviations (a)); drop the field fixture's two reseeds |

## Files touched
- `game/asteroid_field.gd` — `respawn`'s `now` threaded to `_roll_rocks`/`_rolled_yield`/`_yield_multiplier`
- `game/asteroid.gd` — `setup` clears `_cleave_child`
- `ui/station/armory_panel.gd` — the `MOVED` line's name read moved before the write
- `game/npc_ship.gd` — `HULL_MASK` = rock|ship; `LOS_MASK` split out for the ray; comment amended
- `tests/test_weapon_fx_f4.gd` — the held-beam row re-ordered onto a live rig
- `tests/test_s19_quadrants.gd` — the `CTX_DIRECTION` row; the byte-seal re-pin + comment
- `tests/test_engine2_npc.gd`, `tests/test_s6_heat.gd` — the two mask rows re-pinned
- `tests/test_s21_stability.gd` — A9c×2 + A9d rows (20 → 23), three preloads, two helpers

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| The seal pin's literal vs the finished tree's hash (Deviations (a)) | R1/owner ruling | `tests/test_s19_quadrants.gd:95-100` |
| S20's dead `slot_plate_rect` call keeps printing `[PASS]` (pre-existing, disclosed) | LOW | `tests/test_s20_chrome_unify.gd:276` |
