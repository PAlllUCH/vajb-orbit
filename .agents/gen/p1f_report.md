# P1f report — repairs module + dock damage report (01 §6/§7)

Deliverables, exactly two:

1. `vajb-orbit/game/repairs.gd` (new, 131 lines) — `class_name Repairs extends
   RefCounted`, all-static. Header cites 01 §6/§7 and the PlayerProfile `vitals`
   amendment. Constants `HULL_CR_PER_POINTS := 2`, `SHIELD_CR_PER_POINTS := 3`,
   `SHIELD_MIN_EXEMPT_PERCENT := 0.9`. API `fee`, `repair`, `is_repairable` plus
   private `_vitals` / `_credits` / `_spend` / `_restore` / `_refuse`.
2. `vajb-orbit/game/game.gd` (314 lines) — edited: header, `_ready`,
   `_update_route_input`, 3 new private methods. Nothing else changed.

Probe files `tools/_probe_p1f.gd` / `.tscn` were created, run twice and deleted; no
`.uid` sidecars were produced. `user://p1f_probe.cfg`, `user://p1f_probe_log.txt` and
both temp logs were deleted; production `user://profile.cfg` was never written
(mtime still `2026-09-18 11:00:08`).

## game.gd hunks (exact)

```
 6  ## Section 9.2 amendment: ui_cancel docks back to the station, not to the menu.
 7 +## Section 01 §6 amendment: docking files the live hull and shield as the ship's
 8 +## vitals damage report, and the same report seeds the pools on boot.
18 +const PROFILE_SERVICE: StringName = &"PlayerProfile"

 93  _state = PlayerStateScript.new()
 94  _state.setup()
 95 +_seed_vitals()
 96  _hud = _instantiate_hud()
191  func _update_route_input() -> void:
194  	if route_requested.get_connections().is_empty():
195  		return
196 +	_file_damage_report()
197  	route_requested.emit(ROUTE_LOADING, {PARAM_DESTINATION: DESTINATION_STATION})

200-206  _profile() -> Node      # tree-root-anchored lookup, null when absent
209-222  _seed_vitals() -> void  # seeds hull/shield via set_hull/set_shield, minf clamp
225-231  _file_damage_report()   # set_vitals(active_ship, int(hull), int(shield)) at dock
```

`_seed_vitals` acts only when `vitals_of(active_ship)` is a non-empty dictionary (no
record = full pools, today's behaviour) and `minf` clamps to the state maxima.
`_file_damage_report` runs after the existing `get_connections().is_empty()` guard,
before the untouched emit; route constants and payload unchanged.

## Commands and observed output

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tools/_probe_p1f.tscn --quit-after 300
```
EXIT=0; 49 stdout lines; 41 `[P1f] PASS`; 0 `FAIL`; 0 `ERROR` / `SCRIPT ERROR`;
`[P1f] all 41 checks passed` + `PROBE OK`:

```
[P1f] start: credits=10000 active=ship_vanguard
[P1f]      2026-09-18T09:24:15, REPAIR, ship_vanguard, 0, +0, 10000     (step 3)
[P1f]      2026-09-18T09:24:15, REPAIR, ship_vanguard, 0, -500, 99500   (step 4)
```

`res://game/game.tscn --quit-after 300` on the same binary: EXIT=0; 3 stdout lines
(banner, blank, godot_ai helper); 0 `SCRIPT ERROR`, 0 `ERROR`, 0 `WARNING`.

## Probe assertions (41 checks, all passed)

| Step | Assertion | Result |
|---|---|---|
| 1 | the 01 §6 example: 200/1000 hull, 300/600 shield -> `fee == 500` (800/2 + 300/3); `is_repairable == true` | PASS x2 |
| 2 | full 1000/600 -> `fee == 0`, `is_repairable == false`, `repair` = `no_damage`, log empty | PASS x4 |
| 3 | 1000/570 -> `fee == 0`, `is_repairable == true`; `repair` ok for 0 CR, hull 1000, shield 600, credits untouched; one REPAIR line with `+0` and balance = credits | PASS x9 |
| 4 | credits 100000, 200/300 -> ok, `fee == 500`, maxima returned, credits 99500, vitals (1000, 600), one line with `, -500, ` and balance 99500 | PASS x10 |
| 5 | credits 100 -> `insufficient_credits`; credits still 100, vitals 200/300, no log line | PASS x5 |
| 6 | `ship_fighter` (no record) -> `fee == 0`, `is_repairable == false`, `no_damage_report`; unknown `ship_nope` -> `fee == 0` + `no_damage_report`; empty id -> `no_damage_report` | PASS x6 |
| 7 | extras: 200/570 -> `fee == 410` (exemption is hull-conditional); 999/599 -> `fee == 2`; `is_repairable`; `fee(null, id) == 0` | PASS x4 |

Probe plumbing: private profile instance (`save_path = user://p1f_probe.cfg` set before
`add_child`) plus `EconomyLog.log_path = user://p1f_probe_log.txt`.

## Deviations and reviewer notes

1. **Profile lookup path.** The brief said `get_node_or_null(^"PlayerProfile")`, but
   that literal path resolves against the game node, not `/root`, so it would always
   be null (station.gd:497-502 documents exactly this). `_profile()` uses the house
   pattern `get_tree().root.get_node_or_null(NodePath(PROFILE_SERVICE))`, exactly as
   station.gd:496-506 does: same intended behaviour (tolerant lookup, no bare autoload
   identifier), different anchor.
2. **Dynamic calls.** `repairs.gd` reaches the profile through `call()` (`vitals_of`,
   `set_vitals`, `credits`, `spend`) rather than dot-calls, matching station.gd:493
   and avoiding unsafe-access warnings; `game.gd` does the same.
3. **Extra assertions** (step 7): fee for hull damage with shield >= 90 % (410),
   1 missing hull + 1 missing shield (2), null profile (0).
4. Run 1 was `EXIT=1`: 5 probe-only `Parse Error: Cannot infer the type of
   "credits_before"/"after"` (the private profile returns Variant) plus one FAIL from
   a wrong probe expectation in step 7 (hull 199, i.e. 801 missing, not 1); both were
   probe defects, fixed before the final run.
5. **Free repair still logs** one REPAIR line with a `+0` delta (01 §7: one line per event).
6. `_seed_vitals()` runs before the HUD is created; `hud.gd:143` calls `_pull_state()`
   inside `bind()`, so the seeded damage is what the HUD shows, not the full pools.
7. `game.gd` never writes maxima back to the profile; the state keeps its own defaults
   (1000/600, matching the Vanguard), so a non-Vanguard active ship would be clamped.
