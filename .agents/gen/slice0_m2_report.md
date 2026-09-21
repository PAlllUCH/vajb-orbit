# Slice 0 — M2 report: pools + asteroid (energy/fuel chain, rock migration, cleaving)

**Worker:** M2 (file set: `game/ship_stats.gd`, `game/ship_fit.gd`, `game/player_state.gd`,
`game/asteroid.gd`, `game/asteroid_field.gd`).
**Date:** 2026-09-21. **Engine:** Godot 4.7.2, headless `--script` / scene runs only (no editor).
**Status:** all in-set acceptance items pass, **one acceptance item BLOCKED by a file outside my
set** (§6), one cross-file wiring item handed to M5 (§6.2).

---

## 1. Files changed (measured)

| File | Bytes | Lines | md5 (12) | Δ |
|---|---:|------:|---|---:|
| `vajb-orbit/game/ship_stats.gd` | 1 858 | 45 | `d081081f1c77` | +14 |
| `vajb-orbit/game/ship_fit.gd` | 17 979 | 617 | `4f0f19662ecd` | +40/-2 |
| `vajb-orbit/game/player_state.gd` | 10 753 | 279 | `187fc58df09f` | +198/-0 (additions only) |
| `vajb-orbit/game/asteroid.gd` | 13 543 | 304 | `094153ebe602` | +174/-25 |
| `vajb-orbit/game/asteroid_field.gd` | 16 329 | 410 | `0026cec9cc1b` | +204/-20 |
| `vajb-orbit/tests/test_engine2_pools.gd` (new) | 12 000 | 279 | `6aad5afe6c0a` | new |
| `vajb-orbit/tests/test_engine2_cleaving.gd` (new) | 11 632 | 266 | `007a3cdcfb6a` | new |

`git diff --stat` over the five shipping files: **625 insertions, 43 deletions**.

Evidence files: `.agents/gen/slice0_m2_probe_pools.txt`, `.agents/gen/slice0_m2_probe_rocks.txt`
(raw probe output), `.agents/gen/slice0_m2_tests.txt` (raw universal-gate output), probe sources
archived as `.agents/gen/slice0_m2_probe_{pools,rocks}.gd` (the wave-1 convention: `tools/` is
left holding only `build_theme.gd` + `derive_icon_tints.gd`, and the archived copy's header says
to copy it back to `res://tools/` to re-run).

## 2. What was implemented

**`ShipStats`** — `hull_mass`, `energy_max`, `energy_regen`, `fuel_max` added, inserted in the
section 9 field order (`hull_mass` between `turn_spinup` and `hull_max`; the three pool fields
after `cargo_max`, before `boosters`). No existing field moved, retyped or reordered.

**`ShipFit`** — `hull_mass` joins the section 13 `HANDLING` table (the one owner of the class
column) with the brief's nine values: Fighter 80 · Cutter 110 · Miner 140 · Trader 160 ·
Corvette 90 · Hauler 260 · Gunship 190 · Frigate 220 · Destroyer 300 (t). The pools are the
section 13 flat base (`BASE_ENERGY_MAX` 100, `BASE_FUEL_MAX` 200, `BASE_ENERGY_REGEN` 5.0), set
for every hull. Two additions to existing passes: the armour pass now multiplies `hull_mass` by
the module's own `mass_add` (the `h_composite` entry has carried an unread `mass_add: 0.10` since
wave 1, and section 3.2 names plating as a mass source), and `_clamp` extends 09 §5 step 4's
3× rule to the two new pools against their own base.

**`PlayerState`** (additions only; no existing signal or method reshaped) — `energy`/`fuel` with
`energy_max`/`fuel_max`/`energy_regen`; `energy_changed(current, maximum)` /
`fuel_changed(current, maximum)`; `try_spend_energy(amount) -> bool` (false on a short pool, burns
`FUEL_PER_ENERGY` 0.10 Fuel per Energy spent through the reactor, clamped so the tank never goes
negative); `try_spend_fuel(amount) -> bool` (boost/dash burn, false when short — which is also the
emergency lockout, since emergency mode *is* `fuel <= 0`); `emergency_mode` as a **getter-only
property** (read-only, exactly `fuel <= 0.0`); `consume_fuel_cell() -> bool` (one `fuel_cell`
cargo unit → 40 Fuel, 10 s cooldown, cargo spent through `PlayerProfile`); `damage(amount,
bypass_shield := false, ctx := {})` (context accepted and recorded, no-op until slice 3).
Beyond the pin, and required to make the pinned numbers real rather than decorative:
`reactor_efficiency()` (0.7 under emergency), `tick(delta)` (the demand-driven refill plus the
cell cooldown), `set_energy`/`set_fuel`, `fuel_cell_ready()`, `last_damage_ctx()`. `setup()` also
seeds both pools and announces them.

**Emergency Flight Mode (section 4.4)** — state side complete: fuel 0 locks boost and dash
(`try_spend_fuel` false), the reactor runs at `reactor_efficiency() == 0.7` so a second of refill
delivers 3.5 instead of 5.0, thrust is *ignored* by whoever reads the flag, and burning a cell
ends the mode immediately. **The hull's thrust gate is not wired — see §6.2.**

**`Asteroid`** — `StaticBody2D` → `RigidBody2D`: mass = `ROCK_MASS_MULT` 4 × the section 13
`hull_mass` of `ROCK_MASS_REFERENCE` `ship_miner` (140 t → **560 t**), `linear_damp` 3.71 with
`DAMP_MODE_REPLACE`, `gravity_scale` 0 (the project's 980 u/s² 2D gravity is on by default),
`can_sleep = false`, layer 1 / mask 0 (unchanged). The cleaving rules live here as typed consts
transcribed from §13 (`FRAGMENT_SPLIT` L→(2,3) M, M→(2,2) S, S→(0,0); `PICKUP_BURST` (1,2);
`FRAGMENT_EJECT_MULT` 1.2; `FRAGMENT_EJECT_CONE_DEG` 15). `setup(mineral, tier, units,
size_class := SIZE_ANY)` gained one defaulted parameter so a fragment can be pinned to a row
(three-argument calls keep the uniform nine-look roll byte for byte). New read-only queries:
`size_class()`, `cleaves()`, `eject_velocity()`. `apply_work` arithmetic is **untouched** (verified
by probe and test: ten 0.1 hits mine exactly one unit; gun chips still deplete and still extract
nothing, because the mining laser's `MINE_CYCLE` remains the only caller that turns returned units
into pickups).

**`AsteroidField`** — the ruling-17 spawn wiring: on the `cracked` signal (still the pinned bare
signal; the field binds the rock itself) the field erases the rock, cleaves per `FRAGMENT_SPLIT`
(or bursts 1–2 pickups for a Small), then stamps depletion only if nothing is left. Fragments are
built by the same `_new_rock` path as the field's own rocks, so they are field members from birth
(`rocks()`, `rock_count()`, `is_depleted()` see them; no respawn fires while a cleave is still
being chewed through). Fragment yield is re-rolled through the 02 §5 path (`roll_yield`, the base ×
variance roll) with 02 §8's ×0.7 window applied by the same shared helper the field's own roll
uses; the mineral and tier are inherited from the parent; fragments eject at the parent's
`× 1.2` velocity inside a ±15° cone, and are placed on a ring (parent radius + fragment radius) so
a cleave never spawns two bodies inside one another. Small bursts place 1–2 pickups of the parent's
mineral carrying the ore item id (`MineralCatalog.ore_id`), parented to the world
(`current_scene`, else the tree root) like the mining laser's pickups. `pickup.gd` is loaded
**lazily** with a `can_instantiate()` gate and a one-shot warning, so one bad leaf script can never
stop a rock field from building, rolling or cleaving.

## 3. Commands and results (verbatim evidence)

```text
# universal gate (CONTRACTS section 9), after the tools/ probe cleanup
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path
  "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tests/headless_runner.tscn --quit-after 1200
-> [SUMMARY] passed=78 failed=0   (exit 0)
   the only WARNING is test_p1_clock_log's own unwritable-log case; no SCRIPT ERROR
   wave start was 52/1 (the 1 = test_p1_catalogues mineral-icon path, see section 5)
```

```text
# probe A — pools / reactor chain (tools/_probe_s0m2_pools.gd)
-> [SUMMARY] ok=31 failed=0 blocked=0
# probe B — rock body / cleaving (tools/_probe_s0m2_rocks.gd)
-> [SUMMARY] ok=24 failed=0 blocked=1   (the blocked item is section 6.1)
```

## 4. Acceptance, as measurements (probe logs)

| Brief §M2 acceptance | Measured | Where |
|---|---|---|
| spending 10 Energy burns 1 Fuel | `fuel 200.0 -> 199.0` | probe A `spend b` |
| boost burns 3/s | `199.0 -> 195.999999999999 over 1 s` (60 × 3/60) | probe A `boost` |
| a dash consumes 25 | `195.99 -> 170.99` | probe A `dash` |
| fuel 0 triggers emergency | `fuel=0.0 mode=true`; boost/dash spends return false | probe A `emergency a/b` |
| thrust ignored (drift-only) | state half proven (`emergency_mode` true, lockouts false); **hull gate unwired — §6.2** | probe A |
| reactor ×0.7 efficiency | `efficiency=0.7`; one second of refill `gained 3.5` (full = 5.0) | probe A `emergency d/e` |
| a fuel cell refills 40 and ends the mode | `50.0 -> 90.0`, `mode=false efficiency=1.0`, cooldown 10 s, cargo `1 -> 0` | probe A `cell c–f` |
| a depleted Large cleaves into 2–3 Medium | counts `[3,3,3,3,3,3,3,2,2,2,2]` over 11 Large rocks; every fragment Medium | probe B `cleave L a` |
| fragments inherit the mineral with a re-rolled yield | mineral identical, every yield ≥ 1 | probe B `cleave L b` |
| eject at ×1.2 with a ±15° cone | speed ×1.2 exact; widest deviation `14.91°` | probe B `cleave L c/d` |
| a depleted Medium → 2 Small | `2 fragment(s), class 0` | probe B `cleave M a` |
| fragments count toward the same field | `rock_count 37 -> 38 (2 fragment(s))`, `is_depleted() == false` | probe B `cleave F a` |
| a depleted Small bursts 1–2 pickups | **BLOCKED** (§6.1); the no-fragments half passes | probe B `cleave S a/b` |
| yield-0 despawns bare | cracks once, `rock_count 37 -> 37 (0 fragments)`, freed | probe B `bare a–c` |
| gun chips deplete, only MINE_CYCLE extracts | ten 0.1 hits → exactly 1 unit; the return value is unchanged, so the laser's pickup call remains the only extractor | probe B `work a–d` |
| rock drifts at most ~10 u/s | 409 u/s → `8.88 u/s` after 1 s (moved 101 u) | probe B `drift` |
| rock is a heavy rigid body | mass `560.0 t`, damp `3.71` + REPLACE, gravity 0, never sleeps, layer 1 / mask 0 | probe B `body a–h` |

## 5. Deviations, interpretations and reversals

1. **Rock mass: one reference class, not a per-size mapping.** The brief says "class `hull_mass`
   × 4" and gives no size→class mapping, while §13 v2 puts a single new `hull_mass` column in the
   table. I applied the factor to one named row: `ROCK_MASS_REFERENCE = &"ship_miner"` (140 t — the
   median of the nine-class column and the rock-facing hull), giving 560 t = 7 × a Fighter, so a
   rammed rock is effectively a wall for every hull short of the capitals. No number is duplicated:
   the mass is read from `ShipFit.HANDLING`, the column's single owner. Alternatives the owner may
   prefer: per-size rows (S/M/L → some class each) or the lightest row (Fighter 80 t → 320 t, which
   is the class §16 item 2's worked example is written against). Reversal: one const.
2. **`linear_damp` 3.71, and the reading of "at most about 10 u/s".** Derivation from §13 numbers
   only: the heaviest hull at its §13 max speed with the +60 % afterburner carries the most
   momentum of the nine classes (Destroyer 300 t × 504 u/s = 151 200 t·u/s); a momentum-conserving
   contact with a 560 t rock hands it `2·151 200/(300+560) ≈ 409 u/s`; requiring that to fall under
   the 10 u/s drift ceiling within one second gives `d = ln(409/10) ≈ 3.71 s⁻¹`. Discrete check at
   60 Hz: `409 · (1 − 3.71/60)⁶⁰ ≈ 8.9 u/s` — measured **8.88 u/s**. I read "drifts at most about
   10 u/s" as the *settled* drift after the damping has acted (the damp is what "sizes" it, as the
   brief's wording says). If the owner wants a literal instantaneous cap instead, it is one line in
   `_integrate_forces`; the derivation's `DRIFT_SPEED_CEILING` const is already there.
3. **`DAMP_MODE_REPLACE` is required, not cosmetic.** The project default
   (`physics/2d/default_linear_damp` = 0.1) is *added* under `DAMP_MODE_COMBINE`, so a bare
   `linear_damp = 3.71` would really be 3.81 and the derivation would drift. Verified in the probe
   detail line (`mode=1`, project default reported alongside).
4. **`can_sleep = false`.** A sleeping rigid body stops answering contacts, and ruling 15's
   damage-to-both-sides depends on the ship's contact monitor seeing the rock. Rocks are few and
   cheap, so they never sleep. (M1 made the same choice on the hull body.)
5. **`hull_mass` × plating `mass_add`.** The module table's `h_composite` has carried
   `mass_add: 0.10` unread since wave 1; section 3.2 lists plating as a mass source and section 9
   says `hull_mass` feeds inertia and the collision formula, so the armour pass now applies it
   (Cutter 110 t → 121 t). No previously resolved field changes value.
6. **Pool ceiling.** 09 §5 step 4's "pools ≤ 3× hull base" is extended to the new pools against
   their own section 13 base (300 / 600). Nothing moves them yet; the clamp is there before a
   module does.
7. **`emergency_mode` is a getter-only property** (read-only as pinned: assigning it is a parse
   error, reading it is `fuel <= 0.0`), so no setter can ever desynchronise it from the tank.
8. **Additions beyond the pinned list** (`reactor_efficiency`, `tick`, `set_energy`/`set_fuel`,
   `fuel_cell_ready`, `last_damage_ctx`): without a tick, `energy_regen`, the ×0.7 emergency penalty,
   the `FUEL_PER_ENERGY` toll and the cell cooldown would be numbers nothing reads — the task's own
   acceptance requires them measurable. `tick(delta)` is deliberately the *whole* reactor frame job
   (refill + cooldown) so slice 2's W2 has one call to make, and it refuses to refill a full pool
   (ruling 11: "no free regen while nothing runs").
9. **Spend edge cases** (the pin does not define them): `amount == 0` is a no-op success, a negative
   amount is refused, and the fuel toll takes only what the tank holds (an empty tank cannot make
   `try_spend_energy` fail — the hull is in emergency mode anyway, and the pool never goes negative).
10. **`consume_fuel_cell` refuses a full tank** (the conversion is clamped at the ceiling, so a full
    tank would destroy the cell for nothing) and refuses when no `PlayerProfile` service resolves.
    Both are "false otherwise" under the pin; the no-waste guard is an interpretation.
11. **Cleaving: "inherit the parent mineral with a re-rolled yield"** (the task's wording) is what I
    implemented — the mineral *and its tier* are inherited, and 02 §5's `base × variance` roll is
    re-run. §6's aside "the children inherit a re-rolled tier" cannot mean a different mineral: the
    same sentence fixes the mineral as inherited, and a tier change without a mineral change is not
    representable. Reported so M4 can rule.
12. **02 §8's ×0.7 diminishing window applies to fragment yields too**, through the same helper the
    field's own roll uses. Otherwise a respawned field's fragments would pay full while its rocks
    paid ×0.7, which is the exploit 01 §5.5 exists to close.
13. **`Asteroid.setup`'s optional 4th parameter** (`size_class := SIZE_ANY`) keeps the three-argument
    call's behaviour identical (uniform roll over the nine looks) and is the only way a fragment can
    be a Medium/Small: CONTRACTS §5's three-argument signature stays valid.
14. **`pickup.gd` is loaded lazily.** My first cut preloaded it, which made a broken leaf script kill
    the whole field at parse time. The lazy `ResourceLoader.exists` → `load` → `can_instantiate`
    route is the pattern `mining_laser.gd` already uses for the same leaf, and it is what makes the
    rock slice survive §6.1 today.
15. **Nine `asteroid.gd` sprite paths repaired** (`res://assets/env/env_asteroid_*.png` →
    `res://assets/env/prop/…`). Those are parse-time preloads: the file could not load at all in the
    workspace as handed over, so my slice was unrunnable without the repair. This is the same sweep
    the naming re-layout owes the rest of the tree — see §6.3.

## 6. Blockers and cross-file findings

### 6.1 BLOCKED (HIGH) — "a depleted Small bursts 1–2 pickups" cannot be proven while `pickup.gd` is unloadable

`game/pickup.gd` line 47 preloads `res://assets/env/env_pickup_ore_pod.png`. The asset re-layout
(ASSET_NAMING_SPEC §3: `env/` splits into `backdrop/ body/ poi/ prop/ pickup/ tile/`, and `pull.py`
copies each family into its library `folder`) emptied the flat `assets/env/` and re-pulled every
file into its container, so that path no longer resolves and the script fails to compile:

```text
SCRIPT ERROR: Parse Error: Preload file "res://assets/env/env_pickup_ore_pod.png" does not exist.
ERROR: Failed to load script "res://game/pickup.gd" with error "Parse error".
```

`pickup.gd` is **not in any slice-0 worker's file set**, and the brief forbids me to write outside
mine, so I did not touch it. Consequences, all measured:

* probe B `cleave S b` reports `[BLOCK]` instead of a pass: a Small still cracks and still spawns no
  rock fragments (`cleave S a` passes), but the burst spawns nothing because the leaf cannot be
  instantiated. `AsteroidField` warns once per field rather than failing.
* The two new test suites stay silent about the burst on purpose: cracking a Small reaches for the
  leaf, and even *asking* whether that script compiles prints its parse errors into the gate log,
  which CONTRACTS §9's "no SCRIPT ERROR" forbids. `test_engine2_cleaving` therefore asserts the §13
  split table (which is real invariant coverage) and leaves the burst to the probe.

**Minimal external action (one line, inside M5's remit):** in `vajb-orbit/game/pickup.gd`, change

```gdscript
const POD_TEXTURE := preload("res://assets/env/env_pickup_ore_pod.png")
```
to
```gdscript
const POD_TEXTURE := preload("res://assets/env/pickup/env_pickup_ore_pod.png")
```

Re-running `.agents/gen/slice0_m2_probe_rocks.gd` (copied back to `res://tools/`) then turns the
`[BLOCK]` into a pass and removes the warning; the suite can then take the end-to-end Small case.

### 6.2 HANDOFF (MEDIUM) — Emergency Flight Mode's "thrust ignored" has no hull-side gate yet

Section 4.4 wants fuel 0 to ignore thrust input (drift-only, reaction wheels only). The state side
is done and proven (`emergency_mode`, boost/dash lockout, reactor ×0.7). The input gate belongs to
`game/player_ship.gd` — **M1's file, which I did not touch**, and M1's own brief is the body/motion
migration. Today nothing reads `emergency_mode` in the hull, so the flag is inert at the controls.
The fix is one guard where throttle/turn input is sampled:

```gdscript
if _state != null and _state.emergency_mode:
    throttle = 0.0   # drift-only; turning (reaction wheels) stays live
```

Flagged for M5/the owner of `player_ship.gd`.

### 6.3 HANDOFF (HIGH, wave-level) — the asset re-layout still owes 12 files their path sweep

Measured by scanning every `res://assets/...` literal in `vajb-orbit/` against the disk (script kept
out of the repo; result reproduced in §5 of this report's evidence): **12 files** still name files
that are not where they say. The parallel icon pass swept most consumers while I ran (the gate's
`test_p1_catalogues.test_mineral_icons_are_the_dedicated_glyphs` was red at wave start per
`.agents/gen/_slice0_m0_testgate.log` and is green now), but the env family and the tint set are
still stale:

| File | Stale path(s) | Real location |
|---|---|---|
| `game/pickup.gd` | `env_pickup_ore_pod.png` | `env/pickup/` |
| `game/sector.gd` | `env_station.png` | `env/poi/` |
| `game/sector_registry.gd` | `env_sector_1..7_bg.png` (7) | `env/backdrop/` |
| `game/game.tscn` | `env_stars_layer1..3.png` (3) | `env/tile/` |
| `ui/screens/loading.tscn`, `main_menu.tscn` | `env_loading_bg.png`, `env_menu_bg.png` | `env/backdrop/` |
| `ui/hud/hud.gd`, `ui/hud/hud.tscn`, `ui/screens/_mockup_station.gd` | `icons/tint/icon_*.png` (9, incl. `icon_ammo_16`) | the tint quartet's new container |
| `ui/screens/_mockup_station.tscn` | `icons/icon_equip_*.png`, `icons/tint/*` | their containers |

(`tools/build_theme.gd` and `ui/theme/vajb_theme.tres` also matched my scan, but those are regex
artifacts — the font path is `assets/fonts/Oxanium[wght].ttf`, truncated at `[`.) Until the env
family is swept, the game boot path is broken (`game.gd` fails to compile transitively through
`sector.gd`), which blocks every boot gate in this wave, not just mine.

### 6.4 SCOPE — the dash's 0.8 s invulnerability is not slice-0 state

Acceptance pairs "a dash consumes 25" with "grants 0.8 s i-frames". The fuel cost is state-level and
proven (`try_spend_fuel(25.0)`). The displacement and the i-frames belong to `b_fold`'s own
implementation — CONTRACTS §4 records blink/fold as "a stub seam (no module until slice 4)". Nothing
in my file set can host an i-frame window (it is a damage gate on the hull, not a pool), so I did not
invent one. Flagged for slice 4 / whoever owns the booster activation.

## 7. Probe-environment facts worth carrying forward

* **Autoloads *are* available to a `--script` SceneTree run** — they register with the first frame,
  not at `_init`. My first environment probe checked at `_init` and concluded the opposite; the
  pinned "no autoloads in probe mode" assumption in the brief is wrong for probes that await a frame.
  `Engine.get_main_loop()` is likewise null at `_init` and valid after the first frame.
* A script that fails to compile still `load()`s as a `GDScript` object; `new()` on it errors. The
  reliable gate is `GDScript.can_instantiate()`.
* Godot's 2D defaults matter here: `physics/2d/default_linear_damp` 0.1 and 980 u/s² gravity are
  project defaults, so a body that wants a derived damp or no gravity must say so explicitly.

## 8. Reported but not fixed (not mine, not this slice)

* `game/sector.gd`, `game/sector_registry.gd`, `game/game.tscn`, the HUD/mockup icon paths and
  `game/pickup.gd` (§6.3, §6.1) — outside my file set.
* `game/player_ship.gd`'s emergency input gate (§6.2) — outside my file set.
* `ui/screens/_mockup_station.{gd,tscn}` still exist and reference moved icons; IMPLEMENTATION_PLAN
  §9.6 retires the mockup once its verification close-out lands, so I left them alone.
