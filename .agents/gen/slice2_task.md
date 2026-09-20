# Engine Slice 2 — Fight. Task brief (2026-09-18)

Owner-approved slice 2 of `ENGINE_SPEC.md` §14: **fight** — weapons fire,
projectiles, the damage pipeline, NPC archetypes on one brain, loot, death.
Spec sections §4 (combat), §5 (NPCs), §7 (death), §13 (calibration) are law;
`docs/CONTRACTS.md` §2/§3/§4/§5 (ShipStats/ShipFit/PlayerShip seams) are law.
**Stay to spec: implement exactly what the spec and the numbered gameplay docs
say. Deviations go in the report — never silently redesign, never invent a
number.**

Run order: **W0 first** (small doc check) → **W1–W4 parallel** (disjoint file
sets, pinned interfaces below) → **W5** (HUD + wiring, needs W1–W4 landed) →
**W6 review** → **W7 fixes** → **W8 re-review**. Findings tiering: HIGH blocks,
MED = one fixer pass, LOW → backlog (`.agents/gen/LOW_BACKLOG.md`).

---

## W0 — doc check (run first)

Files: `docs/design/IMPLEMENTATION_PLAN.md`, optionally
`docs/gameplay/06_loot_and_progression.md`.

1. Confirm `IMPLEMENTATION_PLAN.md` §9.9 records the slice-2 scope (weapons
   families, damage pipeline, six NPC archetypes, loot). If the engine-wave
   section lacks a slice-2 line, append one — transcription from
   `ENGINE_SPEC.md` §14, no new numbers.
2. Confirm `09_ship_slots_modules.md` §3.1 carries the family + shield-rule
   columns (wave-1 W0 added them). If anything slice-2 needs is missing from
   08/09/06/13, add the missing transcription; if 06's loot tables need no
   change, report "no doc changes needed".
3. Report: `.agents/gen/slice2_w0_report.md`.

## Global rules (all workers)

- Engine Godot 4.7.2, GDScript; workspace `G:/Mój dysk/Projekty/Vajb Orbit`;
  code in `vajb-orbit/`. Read first, in order: `AGENTS.md`,
  `docs/CONTRACTS.md` (§1–§9), `ENGINE_SPEC.md` §4/§5/§7/§13, then your
  section below.
- **Do not edit:** `project.godot`, `addons/godot_ai/`,
  `ui/theme/vajb_theme.tres`, `tools/build_theme.gd`, `docs/**` (except W0's
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
- Probes: `res://tools/_probe_s2wN_*.gd` (`extends SceneTree`,
  `quit()`-terminated), deleted with `.uid` before the report; `tools/` must
  end holding only `build_theme.gd` + `derive_icon_tints.gd`.
- Universal test gate before reporting:
  `..._console.exe --headless --path <proj> res://tests/headless_runner.tscn
  --quit-after 1200` → `[SUMMARY] passed=53 failed=0`. A wave adds tests for
  its slice (new test files follow `tests/test_p2_*.gd` naming is NOT yet
  allowed — P2 fitting tests come later; add slice-2 tests into
  `tests/` as `test_engine2_*.gd` registered in `headless_runner.gd`).
- Reports → `.agents/gen/slice2_<id>_report.md`: files changed with byte
  sizes, exact commands + output, acceptance as measurements, deviations.
- Every economy/heat event logs via `game/economy_log.gd`; only `PlayerProfile`
  mutates credits/cargo/heat.

## Pinned interfaces (code against these exactly; source: current code verified 2026-09-18)

1. **`PlayerState`** (`game/player_state.gd`, existing): `damage(amount:
   float, bypass_shield: bool = false)` already implements shield-first absorb
   with no carry-over (wave-1 verified). `WEAPONS: Array[StringName]`
   `[&"laser", &"cannon", &"rocket", &"mine", &"plasma"]`; ammo via
   `set_ammo(slot, value)` + `weapon_changed` signal. W2 may only ADD
   regen-timing helpers (below) — do not reshape existing signals or methods.
2. **`WeaponComponent`** — `class_name WeaponComponent extends Node2D` in
   `game/weapons.gd`; mounted/managed by PlayerShip like MiningLaser (a seam
   const + `set_active` pattern already exists).
   - `setup(stats: ShipStats, state: PlayerState) -> void`
   - `set_fitted(weapon_ids: Array[StringName]) -> void`
   - `select_group(group: int) -> void` (weapon_1..5)
   - signals `shot_fired(weapon_id: StringName)`, `dry_fired(weapon_id: StringName)`
   - `fire_primary` (Space) held = fire the selected group; `E` stays mining
     convenience (existing MiningLaser path untouched). Empty pack → dry-fire
     feedback, no shot. Mining laser spends no ammo.
   - The family table (DPS, range, travel, shield rule, burst cycles) lives in
     `weapons.gd` as a typed const — single owner — transcribed from
     `ENGINE_SPEC.md` §4.1 + §13 (laser 500 / plasma 450 / cannon 600 burst
     0.35 on/0.25 off / railgun 800 slug 1400 u/s, shares the cannon pack /
     rocket 900 lock 900 / mine arm 2 s trigger 60 u). Do NOT edit
     `ship_fit.gd`.
   - Energy = instant circle hit-test at the cursor's ray point, capped at
     range; kinetics = spawn `Projectile`; rocket with a lock homes, without
     dumb-fires; mine = dropped. Guns on rocks: `Asteroid.apply_work` at the
     10 % rate (existing seam).
3. **`Projectile`** — `class_name Projectile extends Area2D` in
   `game/projectile.gd`:
   - `configure(config: Dictionary) -> void` with keys `kind`
     (&"bolt"/&"slug"/&"rocket"/&"mine"), `speed`, `damage`, `bypass_shield`,
     `homing`, `target`, `turn_rate` (2.2 rad/s), `source`.
   - Kinetics fizzle at max range (§4.1 ranges); rockets are destructible —
     any weapon hit kills them; mines arm after 2 s, trigger radius 60 u.
   - signal `detonated(pos: Vector2, damage: float, bypass_shield: bool)`.
4. **`Damage`** — `class_name Damage extends RefCounted` in `game/damage.gd`:
   - `static func apply(target, amount: float, bypass_shield: bool) -> void`
     — target implements `take_damage(amount: float, bypass_shield: bool) ->
     void` (PlayerShip routes into `PlayerState.damage`; NpcShip mirrors it).
   - `static func regen(state: PlayerState, delta: float, quiet_since: float)
     -> void` — base 2/s + `ShipStats.shield_regen`, resumes after
     `REGEN_QUIET := 4.0` s without incoming damage; owners call it from their
     `_physics_process`.
   - No floating damage numbers (§4.2 item 4 — feedback is HUD-side, W5).
5. **`NpcShip`** — `class_name NpcShip extends Node2D`, group `&"npc_ship"`,
   in `game/npc_ship.gd`:
   - `setup(archetype: StringName, stats: ShipStats, hull_id: StringName) ->
     void`; `take_damage(amount: float, bypass_shield: bool) -> void`;
   - signal `died(position: Vector2, archetype: StringName)` — death flow §7:
     loot roll + heat via the W4/W0-pinned tables; wreck + cargo pickups
     (5-min recovery window, 14 §3) is slice-4 scope — leave the seam.
6. **`NpcBrain`** — `class_name NpcBrain extends RefCounted` in
   `game/npc_brain.gd`: one state set
   IDLE→PATROL/SCAN→ALERT→ENGAGE→FLEE→RETURN/DESPAWN for all six archetypes
   (§5 table drives the differences: pirate flee at 30 % hull, patrol scans
   Suspect+/attacks Outlaws per 13 §2, trader flees on Suspect+, turret is
   static + high damage, hunters/boss are slice-4 seams — code the seam, ship
   nothing). Constants from §13: aggro radii pirate 900 / patrol scan 1 000 /
   turret 750, leash 2 500, `AGGRO_COOLDOWN := 5.0`; LOS check, rocks block.
   Movement reuses the PlayerShip physics pattern — same physics for NPC and
   player (spec decision 1).
7. **`NpcRegistry`** — `class_name NpcRegistry extends RefCounted` in
   `game/npc_registry.gd`: `static NPCS: Array[Dictionary]` — the 13 §4
   density shape per sector (S1 0–1 … S7 6–8, patrols only in owned space,
   one convoy per inhabited sector) + archetype → hull/tier/faction rows.
8. **`LootTables`** — `class_name LootTables extends RefCounted` in
   `game/loot_tables.gd`: `static func roll(kind: StringName, tier: int) ->
   Array[Dictionary]` per `docs/gameplay/06` tables (weighted; rock/mineral
   rolls stay in 02 §5 code paths untouched). Pure data + API; application is
   W3/W5's wiring.
9. **HUD additions** (W5; frozen API untouched — `set_target`,
   `set_target_info`, `clear_target`, `set_reticle_state` stay):
   - `set_target_info(info: Dictionary)` payload gains `in_range: bool`
     (selected weapon range vs distance) and `threat: StringName`.
   - Reticle states map to in-range/out-of-range/hostile (§10).
   - Hit markers on confirmed hits (small, no numbers): HUD exposes
     `hit_marker()`; game.gd calls it from the damage feedback signal.
10. **Wiring** (W5 owns `game/game.gd`, `game/sector.gd` spawn hook):
    - Sector spawns NPC ships per `NpcRegistry` rows on entry (spec §8
      counts); blip kinds gain hostiles (pirates/hunters) and traders as
      neutral.
    - Lock: aiming at a hostile inside `ShipStats.lock_range` marks it
      (`set_target`), no damage bonus, no auto-aim; ESC cancels order + lock.
    - Weapon groups: HUD `weapon_slot_selected(slot)` →
      `WeaponComponent.select_group`.
    - Ammo deltas filed to `PlayerProfile` on dock (01 §6 pattern);
      `economy_log` lines per 01 §7.
    - Safe warp gate `PlayerShip.warp_available()` now reads the real
      `_enemy_engaged()` (hostile in Alert/Engage targeting the player AND no
      damage in the last 5 s — `WARP_DAMAGE_QUIET` const already exists).
    - Death: hull 0 → `died` → explosion → respawn docked at the last station
      visited, 14 §3 insurance + mercy clause; heat persists. If the full
      insurance flow needs profile/schema work beyond the spec, implement the
      minimal flow (respawn docked, cargo dropped at wreck with the 5-min
      window) and report the rest as slice-4 scope.

## Worker file sets

| Worker | Files |
|---|---|
| W0 | `docs/design/IMPLEMENTATION_PLAN.md` (+ possibly 06/08/09) |
| W1 | `vajb-orbit/game/weapons.gd`, `game/projectile.gd` (both new) |
| W2 | `vajb-orbit/game/damage.gd` (new), `game/player_state.gd` (additions only) |
| W3 | `vajb-orbit/game/npc_registry.gd`, `game/npc_ship.gd`, `game/npc_brain.gd` (new) |
| W4 | `vajb-orbit/game/loot_tables.gd` (new) |
| W5 | `vajb-orbit/ui/hud/hud.gd`, `ui/hud/hud.tscn`, `game/game.gd`, `game/sector.gd`, `game/player_ship.gd` (mount seam only) |
| W6/W7/W8 | review/fix; fixers get per-finding file sets |

## Acceptance (each worker, measured)

- W1: headless probe fires each family at a dummy target: energy resolves at
  range cap (no damage past it), cannon bolt travels 1000 u/s, railgun slug
  1400 u/s bypasses shields, rocket homes at 2.2 rad/s with a lock and dies to
  one hit, mine arms at 2 s and triggers at 60 u; dry-fire on empty pack.
- W2: probe applies shield-first absorb (no carry-over), regen resumes 4 s
  after last hit at base 2/s.
- W3: probe spawns each archetype, walks the brain states on synthetic
  positions (LOS blocked by a rock), leash + `AGGRO_COOLDOWN` clears, pirate
  flees at 30 % hull, trader flees on Suspect+.
- W4: probe rolls each 06 table across tiers and prints weight sums = 1.0
  (or the table's own total) and non-empty yields.
- W5: scene run spawns the sector with NPC counts per §13 (probe prints
  counts); lock marks inside lock range; HUD shows range state + hit markers;
  boot gates (game/menu/settings/station) exit 0; test gate green.
- W6/W8: measure, never trust reports — re-run probes, check every number
  against `ENGINE_SPEC.md` §13 and 08/09/06/13, verify the pinned interfaces
  match across all files, flag any invented constant; update
  `docs/CONTRACTS.md` (new slice-2 section + changelog v1) — the ONLY writer
  of CONTRACTS.md in this wave.

## Dispatch

Model fixed by owner: `deepseek/deepseek-v4-flash` (re-check the live catalog
per the orchestrator protocol). Template (bash form):

```bash
VAJB_WORKER_FILES="vajb-orbit/game/weapons.gd,vajb-orbit/game/projectile.gd" \
  crush run "<worker prompt from slice2_prompts.md>" \
  -m deepseek/deepseek-v4-flash --cwd "G:/Mój dysk/Projekty/Vajb Orbit"
```

PowerShell form: `$env:VAJB_WORKER_FILES='...'; crush run "<prompt>" -m
deepseek/deepseek-v4-flash --cwd "G:/Mój dysk/Projekty/Vajb Orbit"`.

Paste-ready prompts: `.agents/gen/slice2_prompts.md` (one per worker, order
W0 → W1–W4 parallel → W5 → W6 → W7/W8). Commit before dispatch
(`git add -A && git commit`) so the wave start is diffable; snapshot first:
`py -3.14 staging/verify_wave.py snapshot --name slice2_start`.
