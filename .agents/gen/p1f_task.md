# P1f task — repairs module + dock damage report (docs 01 §6/§7)

Worker: coder. Wave: P1 economy core. Deliverables, exactly two files:

1. `vajb-orbit/game/repairs.gd` (new)
2. `vajb-orbit/game/game.gd` (edit — dock wiring only, see below)

Do not touch any other file. No MCP tools. Do not run the editor. Do not edit
`addons/`, `project.godot`, docs, or any other script.

Depends on files that may land around the same time (read them first):
- `autoload/player_profile.gd` — v2 with `vitals_of(ship_id) -> {hull, shield}`,
  `set_vitals(ship_id, hull, shield)`, `active_ship()`, `credits()`, `spend()`,
  `add_credits()`, `save_path`.
- `game/station_catalog.gd` — `StationCatalog.ship(id)` rows carry `hull` and
  `shield` maxima.
- `game/economy_log.gd` — `EconomyLog.append(event, item, qty, delta, balance)`.
- `docs/gameplay/01_economy_core.md` §6 (fee formula, example, exemption) and
  §7 (order + log). Read both.

## Contract — `game/repairs.gd`

`class_name Repairs extends RefCounted`. Preload dependencies by path. Header
cites 01 §6 and the amendment that added `PlayerProfile` `vitals`.

Constants:

- `const HULL_CR_PER_POINTS := 2`
- `const SHIELD_CR_PER_POINTS := 3`
- `const SHIELD_MIN_EXEMPT_PERCENT := 0.9`

API (all static):

- `static func fee(profile: Node, ship_id: StringName) -> int`
  - `current := profile.vitals_of(ship_id)`; empty -> 0.
  - maxima from `StationCatalog.ship(ship_id)`; unknown ship -> 0.
  - `hull_missing = maxi(0, hull_max - hull)`, shield likewise.
  - exemption (01 §6): `hull_missing == 0` and
    `shield >= 0.9 * shield_max` -> fee 0 even when the shield is not full.
  - otherwise `ceili(hull_missing / 2.0) + ceili(shield_missing / 3.0)`.
  - The 01 §6 example must reproduce: Vanguard at 200/1000 hull and 300/600
    shield pays **500 CR**.
- `static func repair(profile: Node, ship_id: StringName) -> Dictionary` —
  one all-or-nothing transaction (verify -> spend -> restore -> log):
  - unknown ship or no vitals record -> `{ok: false, reason:
    "no_damage_report"}`;
  - nothing missing at all -> `no_damage`;
  - `fee == 0` with the shield exemption -> free restore, ok;
  - fee > 0: verify `credits() >= fee` (`insufficient_credits`), then
    `spend(fee)` must succeed; restore with `set_vitals(ship_id, hull_max,
    shield_max)`;
  - log `EconomyLog.append("REPAIR", ship_id, 0, -fee, profile.credits())`;
  - success returns `{ok: true, ship_id, fee, hull_max, shield_max}`.
  - On a defensive `spend` failure after verification, return
    `insufficient_credits` with nothing changed.
- `static func is_repairable(profile: Node, ship_id: StringName) -> bool` —
  true when `fee > 0`, or when the exemption case has anything to top up;
  false for `no_damage` / `no_damage_report`.

## Edit — `game/game.gd` dock wiring (small, precise)

The station's REPAIRS module reads `PlayerProfile.vitals_of(active_ship)`.
`game.gd` is the only place the scene state and the profile meet
(STATION_SPEC §1), so:

1. In `_ready()`, after `_state.setup()`: look the profile up with
   `get_node_or_null(^"PlayerProfile")` (house pattern — do not reference the
   autoload by bare identifier). If found, seed the live state's current hull
   and shield from `vitals_of(active_ship)` when that record exists and is
   inside the state's maxima (`minf` clamp), via `_state.set_hull(...)` /
   `_state.set_shield(...)`. When there is no record, change nothing (full
   pools, today's behaviour).
2. In `_update_route_input()`, before the `route_requested.emit(...)` that
   docks to the station: if the profile is found, file a damage report with
   `set_vitals(profile.active_ship(), int(_state.hull), int(_state.shield))`.
   Keep the existing guard (`route_requested.get_connections().is_empty()`)
   and route payloads untouched.

Nothing else in `game.gd` changes behaviour. Keep its header comment and add
one line citing 01 §6 (`vitals` damage report at dock).

## Parse gate (required)

Probe scene `res://tools/_probe_p1f.tscn` + `_probe_p1f.gd`, off-tree profile
with `save_path = "user://p1f_probe.cfg"` before any mutation. Assert with
printed evidence:

1. Vanguard vitals 200/1000 hull, 300/600 shield -> `fee == 500`.
2. Full hull 1000, shield 600 -> `fee == 0`, `is_repairable == false`.
3. Full hull, shield 570 -> `fee == 0` (exemption) but `is_repairable ==
   true`; `repair` restores shield to 600 for 0 CR and logs a REPAIR line.
4. Damaged ship, credits 100000 -> `repair` spends exactly the fee, vitals
   become the maxima, one REPAIR line with -fee.
5. Damaged ship, credits below the fee -> `insufficient_credits`, vitals and
   credits untouched.
6. No vitals record -> `no_damage_report`.

Also run the game scene headless to prove the edit still parses and boots:
`... --headless --path ... res://game/game.tscn --quit-after 300` -> exit 0,
no SCRIPT ERROR.

Run:

    "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tools/_probe_p1f.tscn --quit-after 300

Requirements: exit 0, stdout contains `PROBE OK`, no `SCRIPT ERROR`. Do NOT
use `--check-only --script`. Delete the probe files and any `.uid` sidecars
they got, and the probe cfg/log files in `user://`, before you finish.

## Shell notes (this workspace)

- `grep`, `head`, `tail`, `wc` are absent; use PowerShell `Select-String` /
  `Get-Content` or `py -3.14`.
- The bash tool strips `$` before PowerShell sees it — no `$` in PowerShell.
- `py -3.14` is the working Python; bare `python` is not.

## Report (required)

Write `.agents/gen/p1f_report.md`: deliverables, the exact game.gd hunks,
commands + observed output, every probe assertion with its result, and
anything a reviewer should look at. Under 100 lines.
