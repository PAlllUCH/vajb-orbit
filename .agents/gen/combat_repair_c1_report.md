# C1 report — the ram, measured

**Worker C1** (brief `.agents/gen/combat_repair_wave_task.md`, worker table row C1).
**Scope:** the ram measurement only. **Nothing was fixed.** No file outside
`vajb-orbit/tests/` was written; no asset, theme, `project.godot`, `addons/**` or
`docs/**` was touched.

## 1. Verdict, first

**The numbers support candidate cause 1, the one-way pair, and they name
`vajb-orbit/game/asteroid.gd:194` (`collision_mask = 0`) as the line that must change.**

| Candidate cause | Verdict from the measurement |
|---|---|
| **1. The one-way pair** (`asteroid.gd:194`, `collision_mask = 0`) | **SUPPORTED — this is why the rock does not move.** With the shipped mask the contact is detected and charged to the ship, and the rock receives **exactly zero** (`v_peak = 0.000 u/s`, `pos_delta = 0.000 u`). With the **single** in-memory change `rock.collision_mask = 2` and nothing else, the same ram gives the rock **`v_peak = 73.351 u/s`, `pos_delta = 21.056 u`**. |
| **2. The missing `apply_collision_damage` on the rock** | **REAL, but it cannot move a rock.** Shipping `Asteroid` answers none of `apply_collision_damage` / `take_damage` / `damage` (only `apply_work`), so the peer's half that `player_ship.gd:478-479` offers is dropped. The stub sink scores the offer at **1 hit / 186.179 damage** — so the offer exists and the loss is real — but the stub's rock still moves `0.000 u`: this cause explains a *damage* gap (and a rock has no hull pool at all), never the motion the owner reported. |
| **3. The 40 u/s `COLLISION_MIN_DV` floor** (`impact.gd:26`) | **REFUTED for every ram measured.** Closings measured: **450.000** (driven, 11.3× the floor) and **272.171** (coasting, 6.8×). `Impact.collision_damage(110, 560, 450.0) = 186.179` and the ship's shield lost exactly **−186.179**; the coasting ram's `68.107` also landed to the digit. The floor's only reach is below 40 u/s (`v = 39.9 → 0.000000`, `v = 40.0 → 1.471045`), which no launch-speed ram is. |

The one-line change the fixer pass must make, and the only one this report claims:
`vajb-orbit/game/asteroid.gd:194` `collision_mask = 0` → the hull's layer bit (`2`).
It must be **2, not merely non-zero**: scenario S2b corrected the mask to the rock's own
layer `1` and the rock still moved `0.000 u` (see §4). Setting it to `2` also preserves
the property `asteroid.gd:52-57` is trying to buy: two rocks are both layer 1, so
`mask 2 & layer 1 = 0` and rocks still do not collide with each other.

## 2. What was built

| File | Role |
|---|---|
| `vajb-orbit/tests/probe_c1_ram.gd` | the probe: 7 scenarios + the floor sweep, all raw numbers, self-quitting |
| `vajb-orbit/tests/probe_c1_ram.tscn` | the deterministic headless scene (root `Node2D`, no window) |
| `vajb-orbit/tests/c1_stub_rock.gd` | scenario S3/S6's in-memory-only sink (`extends "res://game/asteroid.gd"`, records the offer). Probe furniture; never ships; adds no constant and changes no physics number |

Reproduce (**byte-identical across runs** — verified by diffing two full runs, 195
`[C1-RAM]` lines each):

```
godot --headless --path vajb-orbit res://tests/probe_c1_ram.tscn --quit-after 100000
```

Exit `0`, wall clock **20.9 s**, 201 MB peak RSS. The probe prints `[C1-RAM] done` and
calls `get_tree().quit(0)` itself; `--quit-after 100000` is the brief's hard bound, not the
stop condition. Raw transcript, exactly as produced:
`.agents/gen/combat_repair_c1_ram.log` (195 lines).

**Probe hygiene, per CONTRACTS §9's trap list.** It is a headless scene, not a `--script`
run, and it dispatches **no** `Input` action and opens no window. It loads shipping scenes
and scripts only. The ram is *driven*: the probe root's `_physics_process` runs before the
ship's (tree order, parents first), so it re-asserts a fixed `linear_velocity` on the
shipped `HullBody` each frame until the first `body_entered` — the brief's "fixed velocity
step". That makes the closing speed a constant of the scenario (`_last_velocity` reads
exactly `450.000`) instead of a product of the thrust model. The driver stops the instant a
contact is reported, so no post-contact frame is pushed.

**Warning ledger (CONTRACTS §9's fifth harness limit).** The same run under
`--headless --debug` prints 25 `WARNING:` lines and **0 attributed to either new file**
(`grep -E "at: GDScript::reload"` matched `probe_c1_ram` / `c1_stub_rock` zero times); all
25 are pre-existing, in `game/weapons.gd`, `game/projectile.gd` and `game/asteroid.gd`.
0 `SCRIPT ERROR`, and the same 195 `[C1-RAM]` lines with the debugger attached.

## 3. The world every scenario builds (measured, not assumed)

```
[C1-RAM] probe start engine=4.7.2-stable (official) physics_ticks=60 hull=ship_vanguard approach=450.0 gap=400.0 seed=20260921
[C1-RAM] medium rock (pinned SIZE_MEDIUM + seed): radius=42.000 mass=560.0
```

Per scenario, identical in all of them:

```
rock:  layer=1 mask=<scenario> mass=560.0 damp=3.710 radius=42.00
hull:  layer=2 mask=1          mass=110.0 damp=0.476 radius=30.00 monitor=true contacts=4 sleep=false
solver view: rock mode=2 mass=560.000 inv_mass=0.001786 | hull mode=2 mass=110.000 inv_mass=0.009091
```

The RID-level view (`PhysicsServer2D.body_get_mode` = 2 `RIGID`,
`BODY_PARAM_MASS` = 560.000) is **identical in every scenario**, so the divergence below is
caused by the mask and by nothing else the server can see. The rock's collision radius
(42.00) is pinned by `seed(20260921)` + `SIZE_MEDIUM`, so all seven scenarios ram the same
rock; the hull is `ship_vanguard` (110 t) on the shipped `STANDARD_FIT`.

## 4. Raw numbers, all seven scenarios

### S1 SHIPPED — rock layer 1, mask 0 (the shipping configuration)

```
[C1-RAM] S1 SHIPPED rock sinks: apply_collision_damage=false take_damage=false damage=false apply_work=true
[C1-RAM] S1 SHIPPED start gap=400.00 ship_v=(450.00, 0.00) rock_v=(0.00, 0.00)
[C1-RAM] S1 SHIPPED pre  f42   gap=  87.26 ship_v=( 446.77,   0.00) rock_v=(   0.00,   0.00)
[C1-RAM] S1 SHIPPED pre  f43   gap=  79.82 ship_v=( 446.77,   0.00) rock_v=(   0.00,   0.00)
[C1-RAM] S1 SHIPPED pre  f44   gap=  72.37 ship_v=( 446.77,   0.00) rock_v=(   0.00,   0.00)
[C1-RAM] S1 SHIPPED pre  f45   gap=  64.93 ship_v=( 446.77,   0.00) rock_v=(   0.00,   0.00)
[C1-RAM] S1 SHIPPED contact=YES frame=45 gap=64.93 closing=450.00 peer=Rock (res://game/asteroid.gd) layer=1 mask=0
[C1-RAM] S1 SHIPPED closing arithmetic: hull _last_velocity=(450.000, 0.000) rock_v_pre=(0.000, 0.000) dot=450.00
[C1-RAM] S1 SHIPPED engine view: contact_count=1 colliding_bodies=1 peer_has_sink=false
[C1-RAM] S1 SHIPPED Impact.collision_damage(110.0, 560.0, 450.00)=186.179 (floor COLLISION_MIN_DV=40.0)
[C1-RAM] S1 SHIPPED post f46   gap=  70.35 ship_v=(   0.00,   0.00) rock_v=(   0.00,   0.00)
[C1-RAM] S1 SHIPPED post f47   gap=  71.43 ship_v=(   0.00,   0.00) rock_v=(   0.00,   0.00)
[C1-RAM] S1 SHIPPED post f48   gap=  71.65 ship_v=(   0.00,   0.00) rock_v=(   0.00,   0.00)
[C1-RAM] S1 SHIPPED post f49   gap=  71.69 ship_v=(   0.00,   0.00) rock_v=(   0.00,   0.00)
[C1-RAM] S1 SHIPPED post f50   gap=  71.70 ship_v=(   0.00,   0.00) rock_v=(   0.00,   0.00)
[C1-RAM] S1 SHIPPED post f51   gap=  71.70 ship_v=(   0.00,   0.00) rock_v=(   0.00,   0.00)
[C1-RAM] S1 SHIPPED post f52   gap=  71.70 ship_v=(   0.00,   0.00) rock_v=(   0.00,   0.00)
[C1-RAM] S1 SHIPPED post f53   gap=  71.70 ship_v=(   0.00,   0.00) rock_v=(   0.00,   0.00)
[C1-RAM] S1 SHIPPED rock: v_at_contact=(0.000, 0.000) v_peak=0.000 v_final=(0.000, 0.000) pos_delta=(0.000, 0.000) |d|=0.000
[C1-RAM] S1 SHIPPED rock pools: yield 8 -> 8, work 0.0 -> 0.0, sink_hits=<no sink> sink_total=<no sink>
[C1-RAM] S1 SHIPPED ship pools: hull 1250.000 -> 1250.000 (delta +0.000) shield 800.000 -> 613.821 (delta -186.179)
[C1-RAM] S1 SHIPPED ship body end: pos=(-71.700, 0.000) travelled=328.300 v=(0.000, 0.000)
```

Read it straight off: **the contact monitor fires** (the probe's own listener on the
shipped `HullBody` reports it at frame 45; the engine's `contact_count` is 1 and
`colliding_bodies` is 1), **the ship's half of the damage lands**
(shield `800.000 → 613.821`, exactly `Impact.collision_damage(110, 560, 450.0) = 186.179`),
the ship is stopped dead in that one step (`446.77 → 0.00`) — and **the rock's velocity,
position, `yield_units` and `work` are all unchanged to the last digit**. The rock's own
three pool deltas are `0`; the rock has no hull/shield pool at all, and of the four
candidate sink names only `apply_work` exists.

### S2 MASK2 — identical in every way except `rock.collision_mask = 2`, set in memory only

```
[C1-RAM] S2 MASK2 contact=YES frame=45 gap=64.93 closing=450.00 peer=Rock (res://game/asteroid.gd) layer=1 mask=2
[C1-RAM] S2 MASK2 Impact.collision_damage(110.0, 560.0, 450.00)=186.179 (floor COLLISION_MIN_DV=40.0)
[C1-RAM] S2 MASK2 post f46   gap=  70.35 ship_v=(  73.35,   0.00) rock_v=(  73.35,   0.00)
[C1-RAM] S2 MASK2 post f47   gap=  71.43 ship_v=(  69.03,   0.00) rock_v=(  69.03,   0.00)
[C1-RAM] S2 MASK2 post f48   gap=  71.65 ship_v=(  64.93,   0.00) rock_v=(  64.93,   0.00)
[C1-RAM] S2 MASK2 post f49   gap=  71.69 ship_v=(  61.05,   0.00) rock_v=(  61.05,   0.00)
[C1-RAM] S2 MASK2 post f50   gap=  71.70 ship_v=(  57.36,   0.00) rock_v=(  57.36,   0.00)
[C1-RAM] S2 MASK2 post f51   gap=  71.70 ship_v=(  53.87,   0.00) rock_v=(  53.87,   0.00)
[C1-RAM] S2 MASK2 post f52   gap=  71.70 ship_v=(  50.55,   0.00) rock_v=(  50.55,   0.00)
[C1-RAM] S2 MASK2 post f53   gap=  71.70 ship_v=(  47.33,   0.00) rock_v=(  47.43,   0.00)
[C1-RAM] S2 MASK2 rock: v_at_contact=(0.000, 0.000) v_peak=73.351 v_final=(0.037, 0.000) pos_delta=(21.056, 0.000) |d|=21.056
[C1-RAM] S2 MASK2 rock pools: yield 8 -> 8, work 0.0 -> 0.0, sink_hits=<no sink> sink_total=<no sink>
[C1-RAM] S2 MASK2 ship pools: hull 1250.000 -> 1250.000 (delta +0.000) shield 800.000 -> 613.821 (delta -186.179)
[C1-RAM] S2 MASK2 ship body end: pos=(-57.234, 0.000) travelled=342.766 v=(0.000, 0.000)
```

The rock now takes **73.351 u/s** at the contact and travels **21.056 u** (exactly half its
own 42.00 u radius) before its `LINEAR_DAMP` 3.71 settles it to `0.037 u/s`; the ship keeps
moving with it at the same common velocity. The ship's shield loses the **same 186.179** —
the mask changes nothing about the damage, only about who is allowed to be pushed.
Momentum: `110 × 450 = 49 500` before, `(110 + 560) × 73.351 = 49 145` after (0.7 % out, one
step of damping), i.e. the solver produced the inelastic common velocity
`110·450/670 = 73.88 u/s` — **not** the `2·m₁·v₁/(m₁+m₂)` reading that `asteroid.gd:103-107`
sizes `LINEAR_DAMP` from. See §6.

### S2b MASK1 — the mask set non-zero but to the *wrong* layer (the rock's own, 1)

```
[C1-RAM] S2b MASK1 contact=YES frame=45 gap=64.93 closing=450.00 peer=Rock (res://game/asteroid.gd) layer=1 mask=1
[C1-RAM] S2b MASK1 rock: v_at_contact=(0.000, 0.000) v_peak=0.000 v_final=(0.000, 0.000) pos_delta=(0.000, 0.000) |d|=0.000
[C1-RAM] S2b MASK1 ship pools: hull 1250.000 -> 1250.000 (delta +0.000) shield 800.000 -> 613.821 (delta -186.179)
```

A non-zero mask does **not** fix it. The mask must name the hull's layer (`2`).

### S3 SINK — shipped mask 0 plus the stub `apply_collision_damage` the rock does not have

```
[C1-RAM] S3 SINK rock sinks: apply_collision_damage=true take_damage=false damage=false apply_work=true
[C1-RAM] S3 SINK contact=YES frame=45 gap=64.93 closing=450.00 peer=Rock (res://tests/c1_stub_rock.gd) layer=1 mask=0
[C1-RAM] S3 SINK engine view: contact_count=1 colliding_bodies=1 peer_has_sink=true
[C1-RAM] S3 SINK rock: v_at_contact=(0.000, 0.000) v_peak=0.000 v_final=(0.000, 0.000) pos_delta=(0.000, 0.000) |d|=0.000
[C1-RAM] S3 SINK rock pools: yield 8 -> 8, work 0.0 -> 0.0, sink_hits=1 sink_total=186.179104477612
[C1-RAM] S3 SINK ship pools: hull 1250.000 -> 1250.000 (delta +0.000) shield 800.000 -> 613.821 (delta -186.179)
```

`sink_hits = 1`, `sink_total = 186.179104477612` — so `player_ship.gd:478-479`'s offer does
arrive, carrying the full `186.179`, and shipping `Asteroid` currently drops it for want of a
method name. The rock still does not move: **cause 2 is a damage gap, not a motion gap.**

### C1 CONTROL — a bare `RigidBody2D`, layer 1 / mask 0, the rock's mass, damp and radius

```
[C1-RAM] C1 CONTROL contact=YES frame=45 gap=64.93 closing=450.00 peer=BareControl (<none>) layer=1 mask=0
[C1-RAM] C1 CONTROL rock sinks: apply_collision_damage=false take_damage=false damage=false apply_work=false
[C1-RAM] C1 CONTROL rock: v_at_contact=(0.000, 0.000) v_peak=0.000 v_final=(0.000, 0.000) pos_delta=(0.000, 0.000) |d|=0.000
```

The control body is not an `Asteroid` and has no script at all, yet behaves identically to
S1: the result is the engine's rule for a mask-0 body, not anything the `Asteroid` class
does. It also proves the harness *can* observe a solved two-body contact (S2/S6 show it),
so S1's zeros are a measurement, not a blind spot.

### S5 COAST — the shipped pair, released at 450 u/s, **not** driven (the owner's own ram)

```
[C1-RAM] S5 COAST pre  f52   gap=  84.41 ship_v=( 281.85,   0.00) rock_v=(   0.00,   0.00)
[C1-RAM] S5 COAST pre  f53   gap=  79.77 ship_v=( 278.62,   0.00) rock_v=(   0.00,   0.00)
[C1-RAM] S5 COAST pre  f54   gap=  75.18 ship_v=( 275.40,   0.00) rock_v=(   0.00,   0.00)
[C1-RAM] S5 COAST pre  f55   gap=  70.64 ship_v=( 272.17,   0.00) rock_v=(   0.00,   0.00)
[C1-RAM] S5 COAST contact=YES frame=55 gap=70.64 closing=272.17 peer=Rock (res://game/asteroid.gd) layer=1 mask=0
[C1-RAM] S5 COAST Impact.collision_damage(110.0, 560.0, 272.17)=68.107 (floor COLLISION_MIN_DV=40.0)
[C1-RAM] S5 COAST rock: v_at_contact=(0.000, 0.000) v_peak=0.000 v_final=(0.000, 0.000) pos_delta=(0.000, 0.000) |d|=0.000
[C1-RAM] S5 COAST ship pools: hull 1250.000 -> 1250.000 (delta +0.000) shield 800.000 -> 731.893 (delta -68.107)
```

With the flight model's coast decay live and **no driver at all**, the result is the same:
contact at frame 55, closing `272.171`, the shield charged `68.107` to the digit, and the
rock untouched. The driving is therefore not an artefact of the harness — and note the
coast decay ate `450 → 272.171` over 400 u (0.91 s), which is the `COAST`/`coast_time 2.0`
curve C3 owns, seen here only as the approach.

### S6 FIXED — both in-memory repairs together (the fixer pass's target numbers)

```
[C1-RAM] S6 FIXED contact=YES frame=45 gap=64.93 closing=450.00 peer=Rock (res://tests/c1_stub_rock.gd) layer=1 mask=2
[C1-RAM] S6 FIXED rock: v_at_contact=(0.000, 0.000) v_peak=73.351 v_final=(0.037, 0.000) pos_delta=(21.056, 0.000) |d|=21.056
[C1-RAM] S6 FIXED rock pools: yield 8 -> 8, work 0.0 -> 0.0, sink_hits=1 sink_total=186.179104477612
[C1-RAM] S6 FIXED ship pools: hull 1250.000 -> 1250.000 (delta +0.000) shield 800.000 -> 613.821 (delta -186.179)
```

With `collision_mask = 2` **and** a damage sink, a 450 u/s ram at a 560 t medium rock gives:
rock **73.351 u/s / 21.056 u**, ship shield **−186.179**, rock sink **1 hit / 186.179**.
Those are the after-numbers C5 must reproduce, and what C6 must re-measure.

### Floor sweep — `Impact.collision_damage(110.0, 560.0, v)`, `COLLISION_FACTOR = 0.00002000`

```
[C1-RAM] floor sweep v=   0.000 -> damage=  0.000000
[C1-RAM] floor sweep v=  20.000 -> damage=  0.000000
[C1-RAM] floor sweep v=  39.900 -> damage=  0.000000
[C1-RAM] floor sweep v=  40.000 -> damage=  1.471045
[C1-RAM] floor sweep v=  41.000 -> damage=  1.545516
[C1-RAM] floor sweep v= 100.000 -> damage=  9.194030
[C1-RAM] floor sweep v= 272.171 -> damage= 68.106664
[C1-RAM] floor sweep v= 446.770 -> damage=183.515992
[C1-RAM] floor sweep v= 450.000 -> damage=186.179104
```

`game/impact.gd:26`'s floor is real and it is exact: `39.9 → 0.000000`, `40.0 → 1.471045`.
Both measured rams sit far above it, so it is not in play for either symptom the owner
reported. (Ram damage scales with `dv²`: the floor is only reachable by deliberately gentle
contact — a docking nudge, or a two-hull closing that the flight model has already bled
down below 40.)

## 5. Why the mask is the cause — the engine rule, traced

The measurement is unambiguous, and the Godot physics source says exactly why. In
`modules/godot_physics_2d/godot_body_pair_2d.cpp`, `GodotBodyPair2D::setup()`:

```cpp
collide_A = (A->get_mode() > PS2DE::BODY_MODE_KINEMATIC) && A->collides_with(B);
collide_B = (B->get_mode() > PS2DE::BODY_MODE_KINEMATIC) && B->collides_with(A);
...
if (!collide_A && !collide_B) {
    if ((A->get_max_contacts_reported() > 0) || (B->get_max_contacts_reported() > 0)) {
        report_contacts_only = true;   // detected, never solved
    } else { collided = false; return false; }
}
```

with, in `modules/godot_physics_2d/godot_collision_object_2d.h`:

```cpp
bool collides_with(const GodotCollisionObject2D *p_other) const {
    return p_other->collision_layer & collision_mask;
}
bool interacts_with(const GodotCollisionObject2D *p_other) const {
    return collision_layer & p_other->collision_mask || p_other->collision_layer & collision_mask;
}
```

`interacts_with` (either side masks the other) decides the pair *exists* — so the contact is
detected and reported. `collides_with` (this body's mask ∩ the other's layer) decides
whether *this* body's mass enters the solve, and `pre_solve`/`solve` gate both the mass and
the impulse on it:

```cpp
real_t inv_mass_A = collide_A ? A->get_inv_mass() : 0.0;   // forced to 0 when !collide
real_t inv_mass_B = collide_B ? B->get_inv_mass() : 0.0;
...
if (collide_A) { A->apply_impulse(-j, c.rA + A->get_center_of_mass()); }
if (collide_B) { B->apply_impulse(j,  c.rB + B->get_center_of_mass()); }
```

The rock is layer 1 / mask 0 and the hull is layer 2 / mask 1, so
`collide_ship = 1 & 1 = true` and `collide_rock = 2 & 0 = 0 → false`. The pair resolves
with the ship's mass alone and `inv_mass_rock = 0`: **the rock is solved as an immovable
body.** That is precisely what the probe measured — the ship stops dead, `body_entered`
fires, the rock keeps `0.000` velocity and `0.000 u` of displacement. `asteroid.gd:52-57`'s
comment ("the solver pairs the two from the ship's side, so a rock needs no mask of its
own") describes `interacts_with` and misses `collides_with`.

*Provenance for the two quotes: read from the public `godotengine/godot` tree
(`modules/godot_physics_2d/…`) on 2026-09-21; the file paths and the flag names are as
above. This is a source read, not a local file in this repository.*

## 6. Observations for C5/C6 (recorded, **not** fixed here)

1. **`asteroid.gd:103-107`'s `LINEAR_DAMP` derivation is sized off a figure the solver does
   not produce.** It derives from "a 450 u/s ram handing the rock ~409 u/s" via
   `2·m₁·v₁/(m₁+m₂)` (the elastic form). Measured, the shipped solver hands the rock the
   *inelastic* common velocity: `110·450/670 = 73.88`, and the probe read **73.351** (0.7 %
   lower, one step of damping). The factor is 2×. The damping still does its job — measured,
   the S2 rock fell `73.351 → 47.43 u/s` in 8 frames and its `DRIFT_SPEED_CEILING` 10 u/s is
   reached in ~0.54 s, inside the 1 s the derivation targets — but the comment's arithmetic
   and the `409/8.88 u/s` figures it records are not reproducible against the shipping pair.
   This is a doc/spec defect (`asteroid.gd` prose), for an owner-tick pass, **not a code
   change**: the shipped constant is conservative, not wrong.
2. **A rock takes no damage today even when the contact is charged**, because
   `Asteroid` implements none of `apply_collision_damage` / `take_damage` / `damage`
   (measured in every scenario's "rock sinks" line). Ruling 1 gives the rock a `take_damage`
   for weapons; the ram's peer half arrives through the *same* name
   (`player_ship.gd:478-479` calls `apply_collision_damage`), so C5's sink should serve both
   or the ram half stays dropped. S3/S6 measure the offer at **186.179** for the 450 u/s ram.
3. **The rock's only pools are `yield_units` and `work`** (measured `8 → 8` and
   `0.0 → 0.0` in every scenario, including the moving ones). So "the rock took the ram"
   is not observable on a rock pool today at all: with the mask fixed the rock moves and
   still reports `0` ore units of damage. Any sink C5 adds must be visible somewhere the
   report can read, or the next reviewer will repeat this measurement and see zeros.
4. **The ship's own half is already correct and must not be "fixed".** Measured in all
   seven scenarios: `shield 800.000 → 613.821` (−186.179) driven and `→ 731.893` (−68.107)
   coasting, each exactly `Impact.collision_damage(110, 560, the hull's own
   _last_velocity)`. `hull 1250.000` never moved (shield-first absorb, `damage.gd`'s
   `ram` with `bypass_shield = false`). Nothing is wrong on the ship's side of a ram.

## 7. Boundaries, and what this report does **not** claim

- **Nothing was fixed.** No shipping file was edited; the two in-memory deviations (the
  corrected mask, the stub sink) exist only as per-scenario nodes inside one probe run.
- The ram is driven at a fixed 450 u/s, which is above `ship_vanguard`'s §13 `max_speed`
  428 (so it is the strongest realistic ram, not a typical one). S5 COAST covers the
  undriven case at 272.171 u/s. Neither is a *live* flight; both are engine-accurate.
- This report is **one rock, one hull, one speed band, one size class** (medium, radius
  42.00). It does not measure large/small rocks, other hulls, or the cleaving/fragment path.
- It does **not** re-litigate the owner's live flow beyond the two facts it confirms: the
  contact monitor fires and the ship's half lands. Why the owner perceived "no collision
  damage" is **not** answered by these numbers — every ram measured here is far above the
  floor and charges the shield. That is a question for the live case (a below-40 u/s nudge
  would explain it, and the floor sweep shows exactly what that looks like) and it is
  outside C1's scope.
- **Gate, measured after this worker's files landed: `[SUMMARY] passed=229 failed=0`**
  (`godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200`,
  exit 0). The 226 baseline was measured green before the wave; the +3 is the parallel C3
  worker's `tests/test_engine_c3_flight_decay.gd` (3 tests), not this worker's. **C1 adds
  no test count on purpose:** `probe_c1_ram.gd` and `c1_stub_rock.gd` are not `test_*.gd`,
  so `headless_runner.gd`'s discovery never picks them up (`[PASS] test_engine_c3_flight_decay`
  ×3 is the whole delta). The count grew, it did not shrink, and nothing was edited to hide
  a failure.
