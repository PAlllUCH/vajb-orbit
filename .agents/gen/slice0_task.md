# Engine Slice 0 — Physics & Fuel (migration wave). Task brief (2026-09-20)

Owner-ruled wave that runs **before slice 2** (18_engine_spec §2.1 ruling 8,
§14 slice 0): the hull migrates to real physics (`RigidBody2D`) and the ship
runs on the **energy/fuel reactor chain**. Spec sections §3 (flight + §3.4
speed fantasy seam), §4.2 (damage items 5–8), §4.4 (pools), §6 (cleaving),
§9, §13 are law; `docs/CONTRACTS.md` §2/§3/§4 are law. **Stay to spec:
implement exactly what the spec says. Deviations go in the report — never
silently redesign, never invent a number.**

Run order: **M0 first** (small doc check) → **M1–M3 parallel** (disjoint file
sets, pinned interfaces below) → **M4 review** → **M5 fixes** → **M6
re-review**. Findings tiering: HIGH blocks, MED = one fixer pass, LOW →
`.agents/gen/LOW_BACKLOG.md`.

---

## M0 — doc check (run first)

Files: `docs/design/IMPLEMENTATION_PLAN.md`, `docs/gameplay/01_economy_core.md`,
`docs/gameplay/08_ship_classes.md`.

1. The 2026-09-20 doc amendments are already applied to
   `09_ship_slots_modules.md`, `14_station_services.md`, `06_loot_drops.md`,
   `11_galactic_map.md` — **verify, do not redo**: each file carries its
   2026-09-20 amendment block matching `docs/gameplay/18_engine_spec.md`
   §12 items 7–12. Report discrepancies only.
2. Transcribe into `01_economy_core.md` §6 (one paragraph, no new numbers):
   the vitals record gains `fuel` (Energy recomputes at launch; Fuel
   persists) — the §12 item 13 wording, and `set_vitals` callers keep the
   shield-alone exemption unchanged.
3. Append the slice-0 line to `IMPLEMENTATION_PLAN.md` §9.9 (transcription
   from `docs/gameplay/18_engine_spec.md` §14 slice 0; no new numbers).
4. Report: `.agents/gen/slice0_m0_report.md`.

## Global rules (all workers)

- Engine Godot 4.7.2, GDScript; workspace `G:/Mój dysk/Projekty/Vajb Orbit`;
  code in `vajb-orbit/`. Read first, in order: `AGENTS.md`,
  `docs/CONTRACTS.md` (§1–§9), `docs/gameplay/18_engine_spec.md` §2.1/§3/§4.2/
  §4.4/§6/§9/§13, then your section below.
- **Do not edit:** `project.godot`, `addons/godot_ai/`,
  `ui/theme/vajb_theme.tres`, `tools/build_theme.gd`, `docs/**` (except M0's
  named files), `assets/**`, any file not in your section. The dispatch sets
  `VAJB_WORKER_FILES` and the hook denies out-of-set writes.
- Style: static typing, tabs, `##` why-comments, signals up / calls down,
  no hex literals (theme `_token()` pattern), no `get_node()` in loops, no
  `_process` for UI animation.
- No editor. Bounded headless runs only:
  `"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path
  "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" ...` with `--quit-after N`,
  stdout redirected to a log that is read afterwards. Known trap:
  `--check-only --script` cannot resolve autoloads — never a gate.
- Probes: `res://tools/_probe_s0mN_*.gd` (`extends SceneTree`,
  `quit()`-terminated), deleted with `.uid` before the report; `tools/` must
  end holding only `build_theme.gd` + `derive_icon_tints.gd`.
- Universal test gate before reporting:
  `..._console.exe --headless --path <proj> res://tests/headless_runner.tscn
  --quit-after 1200` → `[SUMMARY] passed=53 failed=0` (the gate grows with
  the wave's new tests, registered in `headless_runner.gd` as
  `test_engine2_*.gd`).
- Reports → `.agents/gen/slice0_<id>_report.md`: files changed with byte
  sizes, exact commands + output, acceptance as measurements, deviations.
- Every economy event logs via `game/economy_log.gd`; only `PlayerProfile`
  mutates credits/cargo/heat.

## Pinned interfaces (code against these exactly; verified against post-wave-1 code)

1. **`PlayerShip`** (`game/player_ship.gd`, 413 lines): hybrid flight
   (`_heading`, `_speed`, arrive steering, `BRAKE_MULT`, `SLOW_DOWN_RADIUS`,
   `ARRIVE_RADIUS`), `setup(stats, state, fit_ids)`, `set_move_target(pos)`,
   `damage_taken` signal, mining-laser mount seam, `HullBody`
   (CharacterBody2D at local zero, radius = hull half-length, mask
   `Asteroid.COLLISION_LAYER`). M1 replaces the **body and the motion math**,
   nothing else: the scene stays one node swap (`HullBody` → `RigidBody2D`
   with `contact_monitor = true`, `max_contacts_reported = 4`,
   `can_sleep = false`), the API above is frozen.
2. **`ShipStats`** (`game/ship_stats.gd`): fields per 18_engine_spec §9 —
   M2 adds `hull_mass`, `energy_max`, `energy_regen`, `fuel_max` (resolved in
   `ShipFit.resolve` per §13; hull mass is the §13 class column, pools base
   100/200 with module effects later). **Do not reshape existing fields.**
3. **`PlayerState`** (`game/player_state.gd`): existing
   `damage(amount, bypass_shield)`, `hull_changed`/`shield_changed` signals.
   M2 adds: `energy`/`fuel` floats + maxima, `energy_changed(current,
   maximum)`/`fuel_changed(current, maximum)` signals,
   `try_spend_energy(amount) -> bool` (false when the pool is short — the
   slice-2 weapons gate), `try_spend_fuel(amount) -> bool` (boost/dash burn,
   false when empty), `emergency_mode` read-only bool (fuel ≤ 0),
   `consume_fuel_cell() -> bool` (converts one `fuel_cell` cargo unit into
   `FUEL_CELL_UNITS` fuel, 10 s cooldown, false otherwise), and `ctx`
   tolerance on `damage(amount, bypass_shield := false, ctx := {})`.
4. **`Impact`** — `class_name Impact extends RefCounted` in
   `game/impact.gd` (new, M1):
   - `static func collision_damage(mass_a: float, mass_b: float,
     relative_velocity: float) -> float` — the reduced-mass form of
     §4.2 item 6, floored by `COLLISION_MIN_DV`.
   - `static func knockback(remaining_speed: float, projectile_mass: float)
     -> float` — `KNOCKBACK_FRACTION` of remaining KE, applied by the caller
     along the impact line.
   - `static func explosion_impulse(distance: float) -> float` —
     `EXPLOSION_P0 / (1 + d²)`.
   - `static func apply_shockwave(epicenter: Vector2, body, window: float)
     -> void` — the §4.2 item 8 outward impulse over `EXPLOSION_WINDOW`;
     callers: slice 2's detonations, ship deaths, slice-0 cleaving.
   All constants live here as typed consts transcribed from §13 — single
   owner.
5. **`Asteroid`** (`game/asteroid.gd`): becomes a `RigidBody2D` with the
   class's heavy `hull_mass × 4` (proposed §13 — tunable) and `linear_damp`
   sized so a free rock drifts ~10 u/s max (report the derivation). `apply_work`
   arithmetic is untouched (M2: gun chips deplete, only MINE_CYCLE extracts).
   **Cleaving** (ruling 17): on depletion the rock spawns 2–3 Medium / 2
   Small / 1–2 pickups per its look size; fragments inherit the mineral with
   a re-rolled yield (02 §5 path), eject at `current_velocity × 1.2` + ±15°
   cone; yield-0 rocks still despawn bare; fragments count toward the same
   field (`asteroid_field.gd` wiring, M2).
6. **HUD seam** (M3): `set_pool(kind: StringName, value: float, maximum:
   float)`, `set_emergency(active: bool)` — bars per UI_SPEC §3.1b (Energy
   fill `metal_light`, Fuel fill `metal_mid` turning `accent_danger` ≤ 15 %,
   `EMERGENCY FLIGHT` banner). `set_speedometer`/`set_lock_progress` are
   **slice-2 W5 scope** — leave the seams undocumented here.
7. **Station services** (M3): `repairs.gd` gains `refuel(profile, ship_id) ->
   Dictionary` (same shape as `repair()`: `ok`/`fee`/`fuel_max`; CR per
   fuel point per §13) and `recharge(profile, ship_id) -> Dictionary`
   (instant Energy top-up); `station_catalog.gd` gains the
   `refuel`/`recharge` service rows (§12 item 8); the REPAIRS panel lists
   them (existing panel pattern, no new panel).
8. **Persistence** (M3): `autoload/player_profile.gd` vitals gain `fuel`
   (`vitals_of`/`set_vitals` extend; the shield-alone exemption is
   untouched), `profile_changed` key `&"fuel"`, save-schema bump per the P1
   migration pattern (save v3); docking files fuel with the damage report.

## Worker file sets

| Worker | Files |
|---|---|
| M0 | `docs/design/IMPLEMENTATION_PLAN.md`, `docs/gameplay/01_economy_core.md`, `docs/gameplay/08_ship_classes.md` |
| M1 | `vajb-orbit/game/player_ship.gd`, `vajb-orbit/game/player_ship.tscn`, `vajb-orbit/game/impact.gd` (new) |
| M2 | `vajb-orbit/game/ship_stats.gd`, `vajb-orbit/game/ship_fit.gd`, `vajb-orbit/game/player_state.gd` (additions only), `vajb-orbit/game/asteroid.gd`, `vajb-orbit/game/asteroid_field.gd` |
| M3 | `vajb-orbit/game/repairs.gd`, `vajb-orbit/game/station_catalog.gd`, `vajb-orbit/autoload/player_profile.gd`, `vajb-orbit/ui/hud/hud.gd`, `vajb-orbit/game/game.gd` |
| M4/M5/M6 | review/fix; fixers get per-finding file sets |

## Acceptance (each worker, measured)

- M1: probe flies the hull on the rigid body — throttle reaches §13 max
  speed within `accel_time` ±10 %, coast decay within `coast_time`, brake
  distance shorter than coast, autopilot arrives inside `ARRIVE_RADIUS`;
  a 450 u/s flat-wall impact deals 162 ±10 % hull damage (§16 worked
  example); recoil pushes the ship back per shot.
- M2: probe spends 10 Energy → 1 Fuel; boost burns 3/s; a dash consumes 25
  and grants 0.8 s i-frames; fuel 0 → emergency (thrust ignored, reactor
  ×0.7); a fuel cell refills 40; a depleted Large cleaves into 2–3 Medium
  fragments ejecting at ×1.2 ±15°; a Small bursts 1–2 pickups; yield-0
  still despawns bare.
- M3: probe refuels at a station (fee math per §13), recharge tops Energy,
  `profile_changed &"fuel"` fires, save round-trips fuel (v3); HUD shows
  both bars + the emergency banner; boot gates (game/menu/settings/station)
  exit 0; test gate green.
- M4/M6: measure, never trust reports — re-run probes, check every number
  against `docs/gameplay/18_engine_spec.md` §13, verify the pinned
  interfaces match across all files, flag any invented constant; update
  `docs/CONTRACTS.md` (slice-0 section + changelog) — the ONLY writer of
  CONTRACTS.md in this wave.

## Open dependency

**Speed table v2 (ruling 26)** is owner-gated: the △ interpolations in
18_engine_spec §13 need the owner's tick before any slice-0 test bakes new
max-speed/turn-rate numbers. Until the tick lands, the shipped §13 class
columns stay law and the migration derives forces from them.

## Dispatch

Model fixed by owner: `deepseek/deepseek-v4-flash` (re-check the live catalog
per the orchestrator protocol). Template (bash form):

```bash
VAJB_WORKER_FILES="vajb-orbit/game/player_ship.gd,vajb-orbit/game/impact.gd" \
  crush run "<worker prompt from slice0_prompts.md>" \
  -m deepseek/deepseek-v4-flash --cwd "G:/Mój dysk/Projekty/Vajb Orbit"
```

PowerShell form: `$env:VAJB_WORKER_FILES='...'; crush run "<prompt>" -m
deepseek/deepseek-v4-flash --cwd "G:/Mój dysk/Projekty/Vajb Orbit"`.

Paste-ready prompts: `.agents/gen/slice0_prompts.md` (one per worker, order
M0 → M1–M3 parallel → M4 → M5 → M6). Commit before dispatch
(`git add -A && git commit`) so the wave start is diffable; snapshot first:
`py -3.14 staging/verify_wave.py snapshot --name slice0_start`.
