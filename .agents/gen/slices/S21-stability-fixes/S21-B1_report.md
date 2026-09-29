---
slice: S21
worker: S21-B1
model: deepseek/deepseek-flash (reasoning-effort max)
status: actionable
gate: "917/0 → 930/1 (the one failure is S19's byte-seal row — Deviations (b))"
---

# S21-B1 report

## Result
A1/A2/A3/A4b/A9a/A9b landed; `tests/test_s21_stability.gd` carries **14 rows** (green:
`--suite=test_s21_stability` → `passed=14 failed=0`) and `tests/probe_s21_contacts.*` adds
the engine-level contact reading. Gate, fresh scratch `XDG_DATA_HOME`: `[SUMMARY]
passed=930 failed=1` = 917 + 14 − the S19 seal row my `npc_ship.gd` edit moves (Deviations
(b)). `game/damage.gd` byte-identical; `project.godot`, `docs/`, `addons/` untouched.
## Acceptance list answers
- **A1 — DONE.** `PlayerShip.die()` is a real state (input off, orders dropped, force/torque
  zeroed, blast drawn); `_physics_process` returns after the body mirror while dead
  (`player_ship.gd:596,615,697-703`) and `take_damage` (`:578`),
  `_on_hull_body_entered` (`:1151`) and `_unhandled_input` (`:792`) guard on it.
  `game.gd:_switch_ship_off` keeps the wiring's half (group + guns, `:2664`) and
  `_on_ship_died` runs §7's order: die → `_explode_wreck` → drops → respawn (`:2641-2655`).
  Rows: 24 death frames under held thrust give `applied_force()==ZERO`, `applied_torque()==0`
  and no added momentum (a live control does apply force); a wreck contact charges neither
  side; the node order is FX → pickups, route last, hold already over the side.
- **A2 — DONE.** `Pickup.setup(…, window := LIFETIME)` with `var lifetime`
  (`pickup.gd:40,81`) is the seam; `_spawn_drop` files
  `{sector, position, item, amount, expires = WorldClock.now()+DROP_WINDOW, face}` in the
  static ledger (`game.gd:263,2733`) and `_materialise_wreck_drops` re-draws this sector's
  entries with `expires - now` on every `_spawn_sector` (`:772,2753,2771`); `collected`
  removes a taken stack (`pickup.gd:63`, `game.gd:2783`). Fake-clock rows: lifetime 300 s and
  299 s of frames leave it standing, the 300th frees it; the respawn rebuild returns it with
  180 s left at the wreck's position; a crossing to sector 2 takes the face down and keeps
  the entry, crossing back re-draws it; past expiry the ledger is pruned, and collection
  empties it and returns the cargo.
- **A3 — DONE.** `player_ship.tscn`'s `HullBody` mask is 3 (rock + ship layer) and the player
  hull gains `apply_collision_damage` (`player_ship.gd:588`); both monitors resolve the peer
  hull via `hull_behind` and ask the shared `ram_authority` (heavier → greater approach →
  lower instance id; `player_ship.gd:1182,1207`, `npc_ship.gd:551,935`), so exactly one side
  charges both halves. The probe measures the pair at the engine level: both monitors fire
  once, each side's loss is exactly `Impact`'s row-15 figure (`93.789474` at 110 t/80 t/450
  u/s); the rock control reads C1/C5's numbers (loss 186.179104, rock credited 18.617910).
  Rows pin complementarity, the mass rule, the tie-break and rocks staying single-sided.
- **A4b — DONE.** `_clear_transit_flag()` is the one clear (`game.gd:1106`), called by
  `_request_dock` (`:1265`), `_respawn_docked` (`:2820`), `on_route` (`:483`) and by
  `_exit_tree` when the leaving scene did not arm it (`:427-437`); the arming rides
  `_crossing_routed` (`:365,1095`). Row: a real crossing's flag survives the scene teardown
  and the successor consumes it; a dock route and a scene leaving on a route it never armed
  both drop it.
- **A9a — DONE.** `_heat_play_time` is `static` beside `_transit_destination` (`game.gd:381`),
  consumed unchanged in `_decay_heat` (`:2413`). Row: 59.9 s banks, the scene is freed, the
  rebuilt scene's 0.2 s cools 13 §2's point (bank reads 0.1).- **A9b — DONE.** `cancel_jump` is live: `_track_gate_ring` calls it on ring exit
  (`game.gd:922,1002`), `_cancel_gate_charge` on damage (`:1362`) and death (`:2647`); the
  rungs are Outlaw → funds → priced (`:962-979`), `_gate_affordable` reading the same
  `fee_for`/`can_afford` pair `Gate.jump` does (`:991`). Rows: three cancels; one-credit-short
  reads `GATE REFUSED — NOT ENOUGH CR`, a funded account `JUMP TO …`, Outlaw stays first.

## Deviations from SLICE.md
- **(a) A2's ledger is new machinery, not just the seam** — the window must survive the
  respawn route and a crossing, and a `setup` argument cannot outlive a scene the Router
  discards, so `_wreck_drops` remembers the *drop* (absolute expiry on the one WorldClock).
  It is the drop's half of L23's record (the wreck hull/field record stays slice 4,
  CONTRACTS §9). Reversal: delete the static, `_materialise_wreck_drops`,
  `_materialise_drop`, `_clear_drop_faces` and their calls, and `Pickup.collected`.
- **(b) BUCKET 2 — the S19 byte-seal row fails.** `test_s19_quadrants.gd:645`
  (`FORBIDDEN_FILES`) pins `res://game/npc_ship.gd`'s SHA-256, and this brief's §7 hands me
  that file, so A3's authority (the NPC monitor standing down, the peer offer walking to the
  ship) cannot be written elsewhere. Live hash
  `728268c53526dd8436c236ba923528bffea123b31ec0237438fc2baaa8ab661a` (pinned `de8596b1…81be`);
  `damage.gd`, `npc_brain.gd`, `weapons.gd` byte-identical. Resolution: re-pin that one
  string — a yardstick edit an implementer must not make, and the file is B3's region. Every
  other suite count is unchanged (917 + 14 = 931 rows).
- **(c) The NPC body's mask stays rock-only** (widening it would move `test_engine2_npc.gd:401`
  and `test_s6_heat.gd:236`), so the pair exists through the player's mask (either side's
  suffices) and the solver keeps an NPC immovable for the pair — measured (player 450 → 0
  u/s, NPC 0 → 0). The damage is two-sided exactly once (A3's figure); NPC-vs-NPC pairs and
  the two-sided push need those rows moved first. Reversal: mask the NPC body rock|ship and
  re-pin both rows in the same change.
- **(d) The drop expiry is wall-clock (WorldClock seconds):** no doc pins play-time here and
  11 §2.3's crossings are scene rebuilds, so only an absolute stamp keeps a *recovery* window
  meaningful; reversal is the ledger's `expires` base. **(e)** `probe_s2_5_review.gd`'s
  `dead=` print (`not ship.is_physics_processing()`) now reads false by design; its FX/bed
  readings are unchanged, and it is not a gate row.

## Evidence
- Gate, fresh scratch store:
  `XDG_DATA_HOME=$(mktemp -d) $GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200`
  → `[SUMMARY] passed=930 failed=1`; only `[FAIL]`: `test_s19_quadrants.gd.test_the_four_forbidden_files_are_byte_identical`.
  With `-- --suite=test_s21_stability` → `[SUMMARY] passed=14 failed=0`.
- `… res://tests/probe_s21_contacts.tscn --quit-after 3000` (scratch store) → `SHIPHULL
  pairs=player:1 npc:1 … row15=93.789474 player_loss=93.789474 npc_loss=93.789474`;
  `ROCK pairs=1 … row15=186.179104 player_loss=186.179104 rock_credited=18.617910`. S19's
  four hashes: `sha256sum` (deviation (b)).

## Files touched
`player_ship.gd` (death state, `hull_behind`/`ram_authority`, `apply_collision_damage`, the
guards), `game.gd` (death wiring, wreck ledger, transit clears, static heat bank, gate
cancels + rung), `npc_ship.gd` (pair authority, `step_velocity`), `pickup.gd` (lifetime seam,
`collected`), `player_ship.tscn` (mask 1 → 3), and the new `tests/test_s21_stability.gd`,
`tests/probe_s21_contacts.gd/.tscn`.

## New values (with their reversal)
| Value | Where | Reversal |
|---|---|---|
| `GATE_REFUSED_FUNDS_PROMPT` | `game.gd:145` | delete the const + its rung |
| `_wreck_drops` (static), `_crossing_routed`, `_gate_in_ring`, `_drop_faces` | `game.gd:263,365,369,373` | deviation (a); the flags: drop the var and its writer |
| `_heat_play_time` (now static) | `game.gd:381` | remove `static` (L150's loss returns) |
| `Pickup.lifetime` + `window` arg, `signal collected` | `pickup.gd:40,63,81` | revert to `LIFETIME`; delete it |
| `SHIP_GROUPS`, `hull_behind`, `ram_authority` | `player_ship.gd:95,1182,1207` | inline the group names; delete the statics |
| `die`/`is_dead`/`step_velocity`/`apply_collision_damage` | `player_ship.gd:588-623` | restore `_switch_ship_off`'s switch-off and `_on_hull_death` |
| `HullBody.collision_mask = 3` | `player_ship.tscn:18` | back to 1 (the pair stops existing) |

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| `dead=` print should read `ship.is_dead()` | LOW | `tests/probe_s2_5_review.gd:1084` |
| the "mirrors the players physics contract" row no longer describes the player's mask | LOW | `tests/test_engine2_npc.gd:396-401` |
| NPC-vs-NPC pairs and a two-sided ram push (deviation (c)) | LOW | `npc_ship.gd:66-79` |
