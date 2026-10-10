---
slice: S27
worker: S27-B2
model: "deepseek-v4.1-flash (reasoning xhigh)"
status: actionable
gate: "1291/4 (B1 handoff) → 1298/1 ×2 hermetic (the 1 is the out-of-set S19 seal — Deviation 1)"
---

# S27-B2 report — completion builder: the flight call sites + §8's re-cut pins

## Result
A2's three perks fire in play (Echoes at the ammo bank, Long Watch at the lock channel,
Pyre at the kill handler) and A5's `Shipyard.note_flight` runs on the launch path, with
four new `test_s27_catalog.gd` rows proving each changes the outcome. §8's four obsoleted
pins are re-cut to the wave's own law (two seeded cases re-derived beyond the brief's
example — Deviation 3). Gate ×2 fresh scratch stores: `passed=1298 failed=1`,
byte-identical; the sole failure is the S19 seal, which B2's in-set `weapons.gd` edit moves
and B2's file set excludes (Deviation 1).

## Acceptance list answers
- **A2 — DONE** — Echoes: `weapons.gd:_consume_ammo_at` (:2254) counts `_shots_released`
  and returns before the spend when `Affixes.echoes_refunds` is true. Long Watch:
  `game.gd:_update_lock` (:1829) reads `Affixes.lock_channel_seconds(_launch_summary,
  LOCK_CHANNEL)` for the progress and the land test. Pyre: `game.gd:_on_npc_died` (:2683)
  calls `_detonate_pyre_ring`, gating on `Affixes.pyre_ring_damage` and charging every
  `npc_ship` in `PYRE_RING_RADIUS`. Rows: `test_a2_echoes_refunds_a_shot_in_flight` (96 vs
  95 of 100 after 5), `test_a2_long_watch_extends_the_lock_in_flight` (channeling at 1.3 s,
  lands by 3.3 s; plain lands at 1.2 s), `test_a2_pyre_ring_fires_on_a_kill_in_flight`
  (nearby hull takes 50, 0 without the flag).
- **A5 — DONE** — `game.gd:_ready`'s launch branch calls `ShipyardScript.note_flight(_profile())`;
  `test_a5_a_launch_advances_the_shipyard_session` proves a queued hull is ready after one
  launch and a crossing (transit flag set) advances nothing.
- **§8 four re-cut pins** — DONE, each tabled below with its old → new.

## Deviations from SLICE.md
1. **Bucket 2 — the S19 AC6 seal moves and is out of B2's file set.** `tests/test_s19_quadrants.gd:131`
   pins `weapons.gd`'s SHA-256; A2's required edit (the §7 amendment adds `weapons.gd` to
   B2's set) moves it `6848270a…` → `8c9f0707…`. The file is not in `VAJB_WORKER_FILES`, so
   the PreToolUse hook denied the re-pin ("report deviations … instead of editing") and §8
   says leave it. **B2's tree is red by exactly this one row**; the re-pin (S39 precedent,
   disclosed) belongs to R1/F1, whose set holds `vajb-orbit/tests/`. One-line fix:
   `"res://game/weapons.gd": "8c9f0707fc4623f324cd64aca5b797055025632cae7f4937bbccd1e5f02f2c5b",`
2. **`PYRE_RING_RADIUS` 240.0 is PROPOSED** — R-S27-2 names the 50 damage and the 25 %
   line but no reach. Reversal: delete the constant and the loop's radius test.
3. **The seeded outcomes re-derive in four cases, not one.** The brief names `c_target`
   (leeches → echoes); the RNG also re-picks `u_vault` (leeches → embers), `w_proton`
   (choir → echoes) and `b_fold` (silence → leeches) because A1's three new suffix rows
   resize the family pools. Each is updated to the measured outcome; none is weakened.
4. **Pyre's `hull_fraction` reads 0.0 at the handler** — a dead hull is at zero, so any
   kill with the perk is below the quarter line and the ring fires; the seam's threshold
   still gates a direct call (B1's `test_a2_pyre_detonates_below_quarter_hull`). Reversal:
   read a pre-blow share if a future pin supplies one.

## Evidence
- Gate ×2, fresh `XDG_DATA_HOME=$(mktemp -d)`, byte-identical: `[SUMMARY] passed=1298 failed=1`
  (both runs); the failure is `test_s19_quadrants.gd.test_the_four_forbidden_files_are_byte_identical`
  (`res://game/weapons.gd is byte-identical`).
- `XDG_DATA_HOME=$(mktemp -d) $GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 2400`.
- 24/24 `test_s27_catalog.gd` rows pass (incl. the four new). B1's four failures
  (`test_engine2_loot.gd.test_unknown_kinds_are_not_tables`,
  `test_s3_instances.gd.test_the_seeded_outcomes_are_pinned`, `test_s6_poi_loot.gd`'s two
  moved rows) all pass after the re-cuts.

## Moved values — old → new, reversal
| Value | Old | New | Reversal |
|---|---|---|---|
| `weapons.gd:_consume_ammo_at` Echoes gate | none | `_shots_released` + `echoes_refunds` | remove counter + return |
| `game.gd:_update_lock` channel | `LOCK_CHANNEL` 1.2 s | `lock_channel_seconds(_launch_summary, LOCK_CHANNEL)` | revert to `LOCK_CHANNEL` |
| `game.gd:PYRE_RING_RADIUS` (PROPOSED) | — | 240.0 | delete constant + radius test |
| `game.gd:_ready` launch branch | no shipyard call | `ShipyardScript.note_flight(_profile())` | remove the call |
| `test_engine2_loot.gd:431` no-table list | `boss, patrol, turret, sibelon, apex, ""` | `patrol, apex, ""` | re-add the three |
| `test_s6_poi_loot.gd:129` skip set | `hunter` | `hunter` + `NEW_KINDS` | drop the new-kinds skip |
| `test_s6_poi_loot.gd:208` `TABLES.size()` | 6 | 10 | revert to 6 |
| `test_s3_instances.gd:192` suffixes | `c_target` leeches, `u_vault` leeches, `w_proton` choir, `b_fold` silence | echoes / embers / echoes / leeches | re-roll (A1) |
| S19 seal `weapons.gd` SHA-256 | `6848270a…` | `8c9f0707…` (NOT applied) | re-pin (Deviation 1) |

## Files touched
- `game/weapons.gd` — `AffixesScript` preload, `_shots_released`, the Echoes gate
- `game/game.gd` — `ShipyardScript` preload, `PYRE_RING_RADIUS`, launch `note_flight`, Long
  Watch channel, `_detonate_pyre_ring` + its call
- `tests/test_engine2_loot.gd` — :431 no-table list
- `tests/test_s6_poi_loot.gd` — `NEW_KINDS`, :129 skip, :208 size 10
- `tests/test_s3_instances.gd` — :192 four re-derived suffixes + comment
- `tests/test_s27_catalog.gd` — live-launch harness + the four proof rows

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| Re-pin the S19 AC6 seal to `8c9f0707…` (R1/F1; `tests/` is in their set) | test | `tests/test_s19_quadrants.gd:131` |
| Ratify `PYRE_RING_RADIUS` 240.0 or re-cut it | owner tick | `game/game.gd` |
