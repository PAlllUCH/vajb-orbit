# S39-B1_report — flight feel, hostile fire and cargo

**Wave:** S39 · **Slice:** `slices/S39-flight-feel/` · **Baseline:** `s39_start`
(pre-S39 tree at `f8a22d2`) · **Gate:** 1258/0 → **1267/0** ×2 hermetic · **Model:**
executed in-session by the orchestrator on the owner's "write these down, add to
queue and start fixing" (no worker dispatch; the wave was small enough that a
dispatch round-trip would have cost more than the work).

## 1. What the owner asked (playtest #2, verbatim)
Seven findings (see `S39_BRIEF.md` §2). All seven became tickets **T-164–T-170**
and closed in the wave.

## 2. The findings, their root causes and their fixes

| # | Ticket | Root cause (measured) | Fix | Where |
|---|---|---|---|---|
| 1 | T-164 | The brain's `fire` intent had no consumer (`npc_ship.gd:149,1054`) and no archetype row carried a weapon | `NPC_WEAPONS` table + `weapon_row`/`has_weapon`; `_step_weapon`/`_fire_volley` consume `INTENT_FIRE` on the shipped `projectile.gd` pipeline | `npc_registry.gd`, `npc_ship.gd` |
| 2 | T-165 | `_thrust_axis` chases the commanded speed along the nose at the class rate, so a 180° reversal is two `accel_time`s | `REVERSAL_ASSIST_MULT` 1.6 multiplies the rate when the command opposes the travel | `player_ship.gd:_step_speed` |
| 3 | T-166 | `_boost_multiplier` only scaled `_max_speed`; the accel rate was untouched | `_accel_rate()` scales by `_boost_multiplier()` | `player_ship.gd` |
| 4 | T-167 | `_update_boosters` returned unless `b_afterburner` was fitted, so Shift did nothing | `_base_boost` (held Shift) gives a baseline boost the afterburner stacks on | `player_ship.gd` |
| 5 | T-168 | `_patrol_waypoint` advanced only inside the 40 u ring; `_order_speed` zeroes past 90°, so a deflected convoy stalled | `_leg_reached` along-track leg advance | `npc_brain.gd` |
| 6 | T-169 | `KNOCKBACK_FRACTION` 0.40 of a shot's KE, delivered as `sqrt(2EM)` | 0.15 (a hit's Δv falls to 0.61x) | `impact.gd` |
| 7 | T-170 | `_retire_old_column()` hid the cargo panel and never replaced it; the armory showed no hold slots | HUD `CargoBlock` + armory `HOLD %d/%d` subtitle | `hud.gd`, `armory_panel.gd` |

## 3. Acceptance list, item by item
- **A1 (T-164)** — MET. `test_a1_the_armed_archetypes_fire_and_the_neutral_does_not`
  (registry: pirate/swarmer/patrol/turret/three bosses armed, trader not) and
  `test_a1_an_engaged_hostile_puts_shots_on_target` (a pirate puts the row's shots
  in the world with `INTENT_FIRE` true, none with it false).
- **A2 (T-165)** — MET. `test_a2_a_reversal_thrusts_harder_than_a_forward_burn`
  (reversal force > 1.4× the forward force).
- **A3 (T-166)** — MET. `test_a3_a_lit_boost_raises_the_commanded_acceleration`.
- **A4 (T-167)** — MET. `test_a4_shift_boosts_with_no_afterburner_and_the_module_stacks_on_top`.
- **A5 (T-168)** — MET. `test_a5_a_route_leg_advances_once_the_hull_has_passed_its_waypoint`
  (past the waypoint advances; short of it holds).
- **A6 (T-169)** — MET. `test_a6_the_knockback_share_is_below_the_pre_wave_pin`.
- **A7 (T-170)** — MET. `test_a7_the_flight_hud_carries_a_live_hold_readout` and
  `test_a7_the_armory_subtitle_carries_the_hold_slots`.

## 4. Tests that moved
- New: `tests/test_s39_feel.gd` (9 rows).
- Re-pinned: `tests/test_s19_quadrants.gd` (`npc_ship.gd`, `npc_brain.gd` — the
  S22 procedure), `tests/probe_rock_cleave_a2.gd` (knockback invariant 0.15).
- No other suite moved; gate 1258 → 1267/0 ×2 hermetic.

## 5. Numbers (all PROPOSED — no doc pins one; reversals in CONTRACTS §29)
`REVERSAL_ASSIST_MULT` 1.6; `BOOST_BASE_MULT` 1.25; `BOOST_BASE_BURN_FRACTION`
0.5; `KNOCKBACK_FRACTION` 0.15; `NPC_WEAPONS` per-archetype rows. `18_engine_spec.md`
is owner-locked, so these await the owner's fold-in; the reversals are stated.

## 6. What the wave still owes (owner ticks)
- Ratify or re-cut the four PROPOSED constants and the `NPC_WEAPONS` rows.
- Fold the S39 numbers into the owner-locked `18_engine_spec.md` §3.2/§4.2/§13.
- Playtest: does a pirate now return fire, does a turnaround feel quicker, does
  Shift boost with no module, does the convoy reach its gate, do hits nudge, does
  the hold read in flight and at the armory.

## 7. Environment notes
- The `s39_start` baseline was taken from a detached worktree at `f8a22d2` (the
  real pre-S39 tree), because the wave was executed in-session rather than
  dispatched, so a "snapshot before the first dispatch" moment never existed. The
  worktree's checkout lacks gitignored files, so `verify`'s `added` list is noisy;
  `problems: []` and exit 0 are the readings that matter.
- `verify --baseline s39_start --forbidden vajb-orbit/project.godot docs/
  vajb-orbit/addons/` → exit 0, `problems: []`.
