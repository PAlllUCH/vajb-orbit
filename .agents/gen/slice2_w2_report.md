# Slice 2 — W2 report: the damage pipeline (2026-09-21)

Worker W2 of engine slice 2 (Fight), Godot 4.7.2 GDScript. Read first, in order:
`AGENTS.md`, `docs/CONTRACTS.md` §2/§3/§8/§8.1, `.agents/gen/slice2_task.md`
(Global rules + the 2026-09-20 amendments + pinned items 1 and 4),
`docs/gameplay/18_engine_spec.md` §4.2/§4.5/§13, then the shipped tree
(`game/player_state.gd`, `game/player_ship.gd`, `game/impact.gd`,
`game/ship_fit.gd`, `game/ship_stats.gd`, `tests/headless_runner.gd`,
`tests/test_engine2_*.gd`) and the orchestrator addendum of 2026-09-21.

**No asset was read, swept or touched** (addendum ruling two). **No spec number was
invented**: every figure below is a §4.2/§13 row or a value `impact.gd`/`ShipFit`
already owns, and the three numbers this pass had to choose (a peer mass, a projectile
mass and a closing speed) are labelled as probe fixtures. Every file in this pass was
written with the `write`/`edit`/`multiedit` tools, never through the shell — including
the probes, which the addendum added `vajb-orbit/tools/` to this worker's set for.

**Tree state at the time of measurement.** W1, W3 and W4 had all landed files by the
time the gates below were run, and W1/W3 were still writing during the first full gate
(their file mtimes moved inside the same second as the run). The numbers in this report
were measured at **07:34–07:40** on the state that produced `passed=139 failed=0`; the
cross-file section "What the wave still owes" was read at **07:37** and should be
re-read at W6 once those files are frozen.

## Files changed

| File | Before | After | Change |
|---|---:|---:|---|
| `vajb-orbit/game/damage.gd` | — | 17 047 B | new (class `Damage`) |
| `vajb-orbit/game/player_state.gd` | 10 753 B | 12 005 B | +1 252 B, **21 insertions, 0 deletions** |
| `vajb-orbit/tests/test_engine2_damage.gd` | — | 16 696 B | new suite (20 tests) |
| `.agents/gen/slice2_w2_probe_damage.gd` | — | 19 372 B | archived probe source (deleted from `tools/` with its `.uid`) |

`git diff --stat -- vajb-orbit/game/player_state.gd` → `1 file changed, 21 insertions(+)`.
Nothing else in the tree was written by this pass; `git status` shows W1/W3/W4's files
and the orchestrator's own `_dispatch/` artefacts alongside them.

`player_state.gd` is **additions only**: a header paragraph, `SHIELD_REGEN_DEFAULT`
2.0 (§4.2 item 2 / §13 "Shield regen"), and `var shield_regen` seeded from it. No
existing signal, method, comment or field was reshaped — `damage(amount, bypass_shield,
ctx)` still records `ctx` verbatim (the wave-1 and slice-0 tests that assert
`last_damage_ctx()` keeps passing untouched).

## Interfaces as shipped

```gdscript
# game/damage.gd — class_name Damage extends RefCounted
static func apply(target, amount: float, bypass_shield := false, ctx := {}) -> void
static func regen(state: PlayerState, delta: float, quiet_since: float) -> void
static func bearing(target_position: Vector2, heading: float, source_position: Vector2) -> float
static func context(target_position: Vector2, heading: float, source_position: Vector2,
                    impulse: Variant = 0.0, family: StringName = &"") -> Dictionary
static func ram(target: Node2D, peer_position: Vector2, mass_a: float, mass_b: float,
                closing_speed: float, family := FAMILY_COLLISION) -> float
static func knockback(target: Node2D, projectile_mass: float, remaining_speed: float,
                      origin: Vector2) -> float
static func detonate(epicenter: Vector2, damage: float, bypass_shield: bool,
                     bodies: Array, family := FAMILY_EXPLOSION) -> int
const REGEN_QUIET := 4.0                     # §4.2 item 2 / §13
const CTX_DIRECTION/CTX_IMPULSE/CTX_FAMILY   # §4.2 item 5's three keys
const FAMILY_COLLISION := &"collision"       # the pipeline's own two sources
const FAMILY_EXPLOSION := &"explosion"
```

`PlayerState` gains `const SHIELD_REGEN_DEFAULT := 2.0` and
`var shield_regen: float = SHIELD_REGEN_DEFAULT`.

**The `direction` key's definition (slice 3 reads this).** `bearing` = `wrapf((source −
target).angle() − heading, −PI, PI)`: radians off the hull's nose, 0 = dead ahead,
+PI/2 = starboard, −PI = dead astern (the range is half-open at +PI, so a quadrant
comparison reads `absf(direction)`; §4.5's 160° stern arc is therefore `|d| ≥ 80°`).
It agrees with the formula W1 shipped in `weapons.gd:697` and `projectile.gd:530`
byte for byte — measured by reading both, not assumed.

## Commands and output (the evidence chain)

```text
1. probe   "...Godot_v4.7.2-stable_win64_console.exe" --headless --path
           "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit"
           --script res://tools/_probe_s2w2_damage.gd --quit-after 900
           > .agents/gen/_dispatch/slice2_w2_probe.log
   -> exit 0, [SUMMARY] ok=16 failed=0 blocked=0 gaps=4, no SCRIPT ERROR, no leak line

2. suite   ... res://tests/headless_runner.tscn --quit-after 1200 --
           --suite=test_engine2_damage
           > .agents/gen/_dispatch/slice2_w2_suite.log
   -> exit 0, [SUMMARY] passed=20 failed=0, no leak line

3. gate    ... res://tests/headless_runner.tscn --quit-after 1200
           > .agents/gen/_dispatch/slice2_w2_testgate3.log
   -> exit 0, [SUMMARY] passed=139 failed=0, no SCRIPT ERROR, no leak line
```

Per-suite breakdown of the gate: `engine2_cleaving 9 · engine2_damage 20 ·
engine2_loot 13 · engine2_npc 28 · engine2_pools 16 · p1_catalogues 11 ·
p1_clock_log 4 · p1_market 13 · p1_pricing 5 · p1_profile 9 · p1_refinery 6 ·
p1_repairs 5` = **139**. The wave's own total is the measured one (the brief's stale 53
and slice 0's 78 are both superseded); `passed=139 failed=0` is the figure to read.

The first full gate of this pass read `passed=111 failed=1`, the single red being
`tests/test_engine2_npc.gd` ("Identifier `_world` not declared") while W3 was mid-write.
The re-run 75 s later is the green one above; that red is recorded here only so the
log's history is not mistaken for a W2 failure.

## Acceptance measurements

W2's acceptance line, item by item, all from the probe log
(`.agents/gen/_dispatch/slice2_w2_probe.log`), on a real `PlayerShip` scene on its own
`RigidBody2D`, a real `PlayerState` and real bodies in the physics tree:

| Acceptance | Measured |
|---|---|
| shield-first absorb, no carry-over | hit `900.0` (`shield_max` 800 + 100) → shield `0.0`, hull unchanged at `1250.0` |
| bypass lands on the hull | bypass hit `250.0` → hull `1250.0 → 1000.0`, shield stays `800.0` |
| 4 s regen quiet window | 210 frames of quiet (3.4999 s) → shield stays `100.0`; `REGEN_QUIET − 0.001` → stays `100.0`; `REGEN_QUIET + 1 s` → `+5.99999999999966` against a `6.0/s` rate |
| the resolved rate | `ShipFit.resolve("ship_vanguard", STANDARD_FIT).shield_regen` = `6.0` = base 2 + `s_light`'s 4; the state's own default is `2.0` |
| `ctx` direction round trip | recorded `{ &"direction": 1.57079637050629, &"impulse": 1234.5, &"family": &"kinetic" }`; the four arcs read prow `0.0000`, starboard `1.5708`, port `-1.5708`, stern `-3.1416`; wrapped over 12 extra turns (`1.5708`) |
| item 6 through `impact.gd` | hull's shipped contact handler charged `9.19402985074623` against `Impact.collision_damage(110, 560, 100.0)` = `9.19402985074627`; `Damage.ram` on a `take_damage` sink charged `9.19402985074627` with ctx `{direction 0.0, impulse 0.0, family &"collision"}` |
| item 7 through `impact.gd` | `Impact.knockback(1000, 1)` → impulse `6633.2495807108` = `sqrt(2·E·M)` for 110 t; the hull's own `apply_impulse` seam gave the body `60.3022651672363 u/s` against the expected `60.3022689155527` |
| item 8 through `impact.gd` | `detonate` on a rock 5 u out: momentum `153.846153846154` (= `4000/(1+25)`), the body gained `0.27472528815269 u/s` against `momentum/560` = `0.27472527472527`; charged `1 of 2` entries (the rock is pushed, not chipped); the charged hull's ctx impulse `9.97506234413965` = `Impact.explosion_impulse(20 u)`, family `&"missile"` |
| no floating damage numbers | no feedback exists in this pass: §4.2 item 4's flare/sparks and the reticle hit marker stay HUD-side (W5). Nothing was written to a HUD or a screen. |

Supporting measurements (also in the log, and the basis of the wiring items below):

- the hull's own quiet timer launched at `WARP_DAMAGE_QUIET` `5.0`, read `0.3167` after
  20 physics frames, `0.0` the instant a hit reached `PlayerState`, and `0.05` three
  frames later — i.e. the timer `Damage.regen` wants already exists and behaves.
- `PlayerShip.has_method(&"take_damage")` is **false** in the shipped tree;
  `Damage.ram(_ship, …)` computed `9.19402985074627` and the shield stayed `800.0`.
- an unseeded `PlayerState` regenerates at `2.0/s` against the standard fit's `6.0/s`.
- the four gaps printed by the probe are the shipped-tree shortfalls listed under
  "What the wave still owes"; they are reported, never asserted green, so the
  `ok/failed` pair stays a truth table of the pipeline itself.

## Tests added

`tests/test_engine2_damage.gd` (**20 tests**, `suite_name()` = `engine2_damage`), found
by the runner's own discovery — no registration file was edited:

```
apply to a 3-arg sink · apply to a 2-arg sink · apply through PlayerState.damage ·
apply ignores non-sinks and non-positive amounts · the four arcs and the wrap ·
the three ctx keys · a Vector2 impulse passes through · ram charges impact.gd's figure ·
ram is free below COLLISION_MIN_DV · knockback is sqrt(2·E·M) through the push seam ·
knockback needs something to push · detonate charges hulls and pushes rocks ·
shield-first with no carry-over · bypass lands on the hull · the default rate is 2/s ·
the fit resolves base + module (s_light 6/s, s_ion 11/s) · the quiet window is a floor ·
regen spends the state's rate · the ceiling and the null/zero cases · 60 frames add one second
```

The suite frees its own `Node2D`/`RigidBody2D` fixtures in `teardown` rather than using
the base class's `track()`: the headless runner calls `setup`/`teardown` but **not**
`_free_tracked`, so `track()` leaves 7 body RIDs, 13 CanvasItem RIDs and 15 ObjectDB
instances in the gate log (measured, then fixed — the suite's log now carries no leak
line; the two suites that came with slice 0 track nothing, which is why this has not
bitten the wave before).

## Deviations and decisions (each with its reason)

1. **The regen rate is `PlayerState.shield_regen`, not `2.0 + shield_regen`.** The brief
   says "base 2/s plus `ShipStats.shield_regen`", but `ShipFit` already resolves
   `shield_regen = BASE_SHIELD_REGEN 2.0 + regen_add` (`ship_fit.gd:544`), so adding a
   second base would make a no-module hull regenerate at 4/s against §13's "base 2/s".
   `PlayerState.shield_regen` therefore carries the *resolved* figure (default 2.0, the
   §4.2 base, mirroring `energy_regen`'s existing pattern) and `Damage.regen` spends it.
   Verified by measurement: base 2/s unseeded, 6/s with `s_light`, 11/s with `s_ion`.
2. **`apply` tolerates both pinned sink shapes.** The wave pins two forms:
   `take_damage(amount, bypass_shield, ctx)` (this worker's prompt, and what W3 actually
   shipped at `npc_ship.gd:327`) and `take_damage(amount, bypass_shield)` (brief item 4
   and item 5). `apply` reads the target's declared parameter count (cached per script
   and method) and calls the shape it finds, so neither pin can break the other.
   `npc_ship.gd`'s 3-arg form therefore receives `ctx`.
3. **`apply` also accepts `PlayerState.damage` as a sink method.** The pin says the
   target implements `take_damage` and that `PlayerShip` forwards into
   `PlayerState.damage`; the shipped `player_ship.gd` has no `take_damage`, so without
   this fallback the pipeline could not reach the player at all today (measured:
   `Damage.apply(state, …)` drains the shield and records the ctx; `Damage.apply(ship,
   …)` does nothing). `take_damage` always wins when a target has both. This is a
   bridge, not a third interface: the forwarding method is still what W5 owes (below).
4. **`context`'s `impulse` is untyped.** §4.2 item 5 says "a force already applied by the
   caller"; `Impact`'s helpers return a *figure* (impulse-units, a float) and this file's
   `ram`/`detonate` record it, while W1's delivery records the **Vector2** it pushed with
   (`weapons.gd:690`, `projectile.gd:523`). Both shapes exist in the wave, so the door
   records what it is handed rather than forcing one shape to be wrong. Pinned by
   `test_context_records_a_vector_impulse_verbatim`. **W6 should pin one shape in
   CONTRACTS.md**; slice 3 reads `direction` only, so nothing that ships today depends on
   the answer.
5. **Two pipeline-owned `family` names.** §4.1's table (W1's `weapons.gd`) owns the weapon
   families, and a body-body ram and a detonation have no weapon behind them, so
   `FAMILY_COLLISION` and `FAMILY_EXPLOSION` name those two sources here rather than
   borrowing a family the hit did not come from. They are names for §4.2 item 4's feedback
   distinction, not calibration values; no number is involved.
6. **A blast pushes rocks and does not chip them.** `detonate` charges every entry that
   implements a hit method and merely pushes the rest. §4.2 item 8 gives a detonation an
   *impulse* (§16's "the shockwave is physics, the bloom is only its face"), and §6's
   10 % chip rate is *gun* work; offering `apply_collision_damage` to a rock would be an
   application rule the spec does not state. Measured: `charged 1 of 2` for a hull + rock.
7. **`regen` is typed `PlayerState` exactly as pinned, which is player-only.** An
   `NpcShip` cannot call it (it is not a `PlayerState`), which is why W3 carries the same
   two lines inline (`npc_ship.gd:393-394`) while reading this file's `REGEN_QUIET`
   through `get_script_constant_map()` with a documented 4.0 fallback
   (`npc_ship.gd:661-668`). If the wave wants one owner for both, the pin has to widen to
   a duck-typed state; that is a CONTRACTS decision, not something this pass may change
   unilaterally. **The window itself has one owner** either way: the reflection reads
   `Damage.REGEN_QUIET`.
8. **Probe fixtures that are not spec values, and are labelled as such in the file:** the
   peer's 560 t is CONTRACTS §8.1's rock reference mass; the projectile mass 1.0 t stands
   in for W1's weapon table (no §13 row exists for it); the peer's 100 u/s closing speed
   and the 400 u offset are geometry chosen to sit above `COLLISION_MIN_DV` 40. The ram
   assertion validates its own fixture (`closing == 100.0`) so the figure cannot drift
   unnoticed.

## What the wave still owes (measured, reported not fixed — every item is a file outside this pass's set)

1. **`PlayerShip` publishes no `take_damage`.** `Damage.ram(_ship, …)` computes its figure
   and charges nothing (measured). W5's file needs the pin's forwarding method:
   `func take_damage(amount: float, bypass_shield := false, ctx: Dictionary = {}) -> void:
   _state.damage(amount, bypass_shield, ctx)` with a `_state == null` guard.
2. **The hull's ram records no context.** `player_ship.gd:418` calls `_state.damage(damage)`;
   the last ctx after a ram is `{ }` (measured). The one-line fix is that same call plus
   `Damage.context(global_position, _heading(), other_node.global_position, 0.0,
   Damage.FAMILY_COLLISION)` (or `Damage.ram(self, peer_position, _hull_mass(),
   _peer_mass(other), _closing_speed(other))`, which the probe shows charges the identical
   figure).
3. **`game.gd` does not seed `PlayerState.shield_regen`.** `_apply_ship_maxima()` seeds
   `energy_max`/`energy_regen`/`fuel_max`; the shield's rate needs the same three lines.
   Until then a launched hull regenerates at the 2/s base rather than its fit's rate
   (measured: 2.0/s vs the standard fit's 6.0/s) — correct for a no-module fit, wrong for
   a fitted shield.
4. **Nothing in the shipped tree calls `Damage.regen`.** The rule is inert in game until
   `player_ship.gd`'s `_physics_process` calls `Damage.regen(_state, delta, _damage_quiet)`
   (the timer it already keeps, measured: launched at 5.0, reset by a hit, climbing 1/60
   per frame).
5. **The item-5 delivery seam has three owners.** `Damage.apply`/`context`/`bearing`
   (this pass) and W1's private copies: `weapons.gd:664 _deliver`, `:687 _ctx`,
   `:697 _impact_bearing`, `:706 _takes_ctx` and `projectile.gd:502 _deliver`, `:520 _ctx`,
   `:530 _impact_bearing`, `:537 _takes_ctx`. The three agree on the data shape and the
   bearing formula (read, not assumed), and W1's comments say the pipeline "calls the same
   method on the same targets", so this is duplication rather than conflict — but a slice-3
   quadrant change would then have to touch three files. The collapse is one call per
   site: `Damage.apply(target, amount, bypass, Damage.context(pos, heading, point, impulse,
   family))`, which `apply`'s arity tolerance and `context`'s Variant `impulse` already
   accept unchanged. **Tier suggestion: MED (one fixer pass), for W6 to adjudicate.**
6. **`res://game/player_ship.tscn:4` carries a stale `ext_resource` UID** (it falls back to
   the text path for `res://assets/ships/ship_vanguard_side.png`). Environment-deferred per
   addendum ruling two; recorded, not touched.

## Observations that are not findings

- **The harness can run more than one physics step across a single `await physics_frame`.**
  In the first version of the probe, writing `linear_velocity` on the hull's body from
  outside the step and reading `_last_velocity` after one `await` showed `450 → 59.82 u/s`
  (and then a clean −3.23 u/s per frame, which is `max_speed 406.6 / coast_time 2.1`);
  the identical operation on a fresh rigid body outside the hull's code kept `446.8 u/s`,
  and the same write on a freshly launched hull kept its speed too. Nothing in the
  pipeline sets a hull's velocity from outside a step, so no reported figure depends on
  it and the probe now drives its rams by moving the peer instead. Not investigated to
  conclusion: flight code is outside this pass's file set. If W6 wants it settled, it
  belongs to the hull's owner.
- **A shapeless `RigidBody2D` is charged at unit mass until the space has updated it**
  (measured: an impulse of 153.846 on a body with `mass = 560` and no collision shape gave
  `Δv = 153.846 u/s`; the same body with a shape gave `0.2747`, and a *per-frame* impulse
  stream on an unshaped body lands at unit mass on the first slice only). `Asteroid` and
  `HullBody` both carry shapes, so this is a fixture sharp edge rather than a shipping one;
  the probe's fixture bodies now carry a small circle before they join the tree.
- `ClassDB` confirms `RigidBody2D` has no `damage` method, so `apply`'s `damage` fallback
  cannot silently catch a bare body; the enum name is `DAMP_MODE_REPLACE` in 4.7 (the
  3.x-era `LINEAR_DAMP_MODE_REPLACE` does not parse).

## Environment / deferrals

- No editor was used: every run was headless, bounded with `--quit-after`, with stdout
  redirected to a log that was read afterwards. No run was left in the background.
- `tools/` is left holding only `build_theme.gd`, `derive_icon_tints.gd` and W1's/W3's
  probes; **this worker's probe and its `.uid` are deleted**, re-runnable from
  `.agents/gen/slice2_w2_probe_damage.gd` (header carries the command).
- No asset path was read, moved or swept; the one asset warning above is left as the
  graphics lane's work.

## What W6 should re-run

1. `.agents/gen/slice2_w2_probe_damage.gd` → `ok=16 failed=0 blocked=0 gaps=4` (copy it to
   `vajb-orbit/tools/` first; delete it and its `.uid` afterwards).
2. `--suite=test_engine2_damage` → `passed=20 failed=0`; the full gate → `passed=139
   failed=0` (re-measure; the number belongs to the frozen wave, not to this report).
3. The three specific claims worth attacking: the 4 s window (`Damage.REGEN_QUIET` vs
   §13's "resumes 4 s after last hit"), the resolved rate (`ship_fit.gd:544` base +
   module, no second base), and the `direction` sign convention against §4.5's four arcs
   (W1's independent copy at `weapons.gd:697` is a second opinion).
4. The five wiring items above, in `player_ship.gd` and `game.gd` — W2's file set cannot
   close them, so a green W2 report does **not** mean shield regen, ctx-carrying rams or a
   `take_damage`-able player hull exist in the running game.
