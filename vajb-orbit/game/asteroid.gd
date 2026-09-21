class_name Asteroid
extends RigidBody2D
## One mineable rock: a solid body that accumulates extraction work and cracks
## open at yield 0.
## Contract: ENGINE_SPEC.md §6 (mining — the laser is primary, guns work rocks at
## 10 %; rocks are solid, block shots and beams; tiered cleaving per ruling 17),
## §13 (`MINE_CYCLE` 1.2 s per ore unit; the cleaving rows; the class mass column),
## §15 ("Mining: N cycles on a rock spawn N ore pickups; gun work accumulates at
## 10 %; cracks at yield 0"; "a depleted Large spawns 2-3 Medium fragments ejecting
## at x1.2 velocity ±15°; a depleted Small bursts 1-2 pickups; yield-0 rocks still
## despawn bare"); docs/gameplay/02_minerals.md §5 (the mineral and yield rolls) and
## §7 (the mining flow); slice-0 brief §M2 and pinned interface item 5.
##
## Work, not damage: `apply_work` accumulates fractional work and converts it to
## whole ore units at `WORK_PER_UNIT`, so 02 §7.1's "one completed extraction cycle
## pops one ore unit" and ENGINE_SPEC §6's 10 % gun rate are the same arithmetic
## with different callers. Slice 2's weapons call `apply_work(dps * 0.1 * delta)`;
## no weapon code lives here. That arithmetic is untouched by slice 0: guns still
## only deplete (the caller that spawns pickups is the mining laser's MINE_CYCLE).
##
## **Slice 0 (ruling 8): the rock is a real body.** A `RigidBody2D` with a heavy
## mass and linear damping, so a rammed rock is a near-wall and a knocked rock
## settles instead of wandering (ruling 15/16: every body-body impact deals kinetic
## damage to both sides). Gravity is off — this is space, not a planet — and
## `can_sleep` stays false so a rock is always able to answer a contact, which is
## what the ship's contact monitor needs to charge the ram to both sides.
##
## **Cleaving (ruling 17):** this file owns the *rules and the numbers*; the field
## that spawned the rock does the spawning, because it owns the generation RNG, the
## field count and the pickups' world parent. `AsteroidField._on_rock_cracked`
## reads `size_class()`, `mineral_id`, `tier`, `cleaves()` and `eject_velocity()`
## off the rock during the `cracked` emission (the node is freed right after), and
## spawns the fragments per `FRAGMENT_SPLIT` / `PICKUP_BURST`.
##
## The 02 §5 mineral and yield rolls happen in `AsteroidField`; this file only
## carries the result (mineral, tier, yield). The sprite's size class is a look and
## never a stat for throughput — a large rock mines exactly as fast as a small one —
## but ruling 17 makes it the cleaving class, which is why `setup` can be told which
## row to roll from.

signal cracked

## 02 §7.1 / §15: one unit of ore per unit of work. The mining laser applies
## exactly this per cycle; a weapon applies a fraction of it per hit.
const WORK_PER_UNIT := 1.0

## Work is accumulated in floats, so a caller applying 0.1 per hit reaches
## 0.9999999999999999 after ten hits. The conversion forgives that much and no
## more, so 02 §6's 10 % rate is exact by intent rather than an eleventh hit.
const WORK_EPSILON := 0.0001

## Physics layer 1 (bit 0). Rocks are solid to ships and block shots and beams
## (ENGINE_SPEC §6), so this body carries the rock layer and, for the hull layer, a
## mask. Godot pairs two bodies from both sides: `interacts_with` (either mask) decides
## the pair exists, and `collides_with` (this body's mask ∩ the peer's layer) decides
## whether this body's mass enters the solve. With the shipped `collision_mask` 0 the
## rock's inverse mass was forced to 0, so the solver resolved every contact as if the
## rock were immovable: the ship's half landed and the rock's half was dropped (C1
## measured `v_peak = 0.000 u/s`, `pos_delta = 0.000 u`). The mask names the hull layer
## (`player_ship.tscn`'s `HullBody` is layer 2 / mask 1), never the rock's own: two
## rocks are both layer 1, so `mask 2 & layer 1 = 0` and rocks still do not collide
## with each other.
const COLLISION_LAYER := 1
const COLLISION_MASK := 2
const ROCK_GROUP: StringName = &"asteroid"

## The §13 class mass column's single owner: `ShipFit.HANDLING`. Read as data
## only, so the rock's mass cannot drift from the hull table (§13 v2 puts
## `hull_mass` in that table and nowhere else).
const ShipFitScript := preload("res://game/ship_fit.gd")

## The ram sink's conversion is the shipped 10 % gun chip (ENGINE_SPEC §6, ruling 17),
## read from its single owner `WeaponComponent.GUN_CHIP_RATE` rather than re-declared:
## the owner's 2026-09-21 re-scope rejected a second damage-to-work constant, so a ram
## and a shot chip a rock through the same arithmetic. Reached by path and not by the
## global class name, which only resolves once the editor has scanned the project.
const WeaponsScript := preload("res://game/weapons.gd")

## The look rows of `LOOK_TEXTURES`: three size tiers (S, M, L) times three
## silhouettes. Row order is S1-S3, M1-M3, L1-L3, so the size class of a look is
## `_look / LOOKS_PER_SIZE`.
const LOOKS_PER_SIZE := 3
const SIZE_SMALL := 0
const SIZE_MEDIUM := 1
const SIZE_LARGE := 2
const SIZE_ANY := -1

## §13 "Cleaving (ruling 17)", verbatim: `L -> 2-3 M`, `M -> 2 S`, `S -> 1-2
## pickups`. A small's row reads (0, 0) fragments because its cleave *is* the
## pickup burst in `PICKUP_BURST`; a large's fragments are Medium, a medium's are
## Small (the row below it), which is what `fragment_size()` returns.
const FRAGMENT_SPLIT: Dictionary = {
	SIZE_SMALL: Vector2i(0, 0),
	SIZE_MEDIUM: Vector2i(2, 2),
	SIZE_LARGE: Vector2i(2, 3),
}
const PICKUP_BURST: Vector2i = Vector2i(1, 2)

## §13: fragments "eject at `current_velocity × 1.2` + random ±15° cone".
const FRAGMENT_EJECT_MULT := 1.2
const FRAGMENT_EJECT_CONE_DEG := 15.0

## §13's class mass column (the engine-slice-0 `hull_mass` row) × 4 — the brief's
## "heavy mass (class `hull_mass` × 4, proposed)". A rock has no class of its own
## and §13 gives no size mapping, so one mass serves all three looks: the rock's
## size stays a look (this file's rule, amended only by cleaving) and the brief's
## single factor is applied to one named reference row. `ship_miner` is that row —
## the rock-facing hull and the median of the nine-class column (see the M2 report
## for the derivation and the reversal).
const ROCK_MASS_MULT := 4.0
const ROCK_MASS_REFERENCE: StringName = &"ship_miner"

## The damping that makes "a free rock drifts at most about 10 u/s" true. Derivation
## (§13 numbers only, in the M2 report): the heaviest hull at its §13 max speed
## under the +60 % afterburner carries the most momentum of the nine classes
## (Destroyer 300 t × 504 u/s = 151 200), a momentum-conserving contact with a
## `ROCK_MASS_MULT` rock hands it `2·151200/(300+560) ≈ 409 u/s`, and requiring that
## to fall to the 10 u/s drift ceiling inside one second gives
## `d = ln(409/10) ≈ 3.71·s⁻¹`. Discrete check at 60 Hz:
## `409 · (1 − 3.71/60)⁶⁰ ≈ 8.9 u/s`, measured 8.88 u/s by the M2 probe.
## `DAMP_MODE_REPLACE` is required: the project default (`physics/2d/
## default_linear_damp` 0.1) would otherwise be *added* and the derivation drift.
const LINEAR_DAMP := 3.71

## The drift the damping is sized to (`DRIFT_SPEED_CEILING` u/s one second after the
## worst ram). Not a runtime clamp -- the number the derivation targets, so the probe
## can read the ceiling instead of repeating it.
const DRIFT_SPEED_CEILING := 10.0

## The nine shipped Phase B rock sprites: ENVIRONMENT_SPEC §4's three size tiers
## times three silhouettes, all pre-cut `rgba` (ASSET_CATALOG). Row order is
## S1-S3, M1-M3, L1-L3.
##
## The `env/prop/` container is ASSET_NAMING_SPEC §3's (`env/` splits into
## `backdrop/ body/ poi/ prop/ pickup/ tile/`) and is the folder `pull.py` copies
## this family into. Slice 0 repaired these nine parse-time paths: the asset
## re-layout emptied `assets/env/` and re-pulled every file into its container, so
## the flat paths this file carried since wave 1 no longer resolved (the same
## sweep is still owed to `pickup.gd`, `sector.gd`, `sector_registry.gd` and the
## icon consumers — see the M2 report's blocker section).
const LOOK_TEXTURES: Array[Texture2D] = [
	preload("res://assets/env/prop/env_asteroid_S1.png"),
	preload("res://assets/env/prop/env_asteroid_S2.png"),
	preload("res://assets/env/prop/env_asteroid_S3.png"),
	preload("res://assets/env/prop/env_asteroid_M1.png"),
	preload("res://assets/env/prop/env_asteroid_M2.png"),
	preload("res://assets/env/prop/env_asteroid_M3.png"),
	preload("res://assets/env/prop/env_asteroid_L1.png"),
	preload("res://assets/env/prop/env_asteroid_L2.png"),
	preload("res://assets/env/prop/env_asteroid_L3.png"),
]

## Target world width per look row, in units, one entry per LOOK_TEXTURES row.
## No spec number exists for a rock's size and none is invented as a gameplay
## value: this is the phase's only visual constant, read off the shipped hull
## scale (the 905 px `ship_vanguard_side.png` at game.tscn's 0.0663 is 60.0 u
## long), so the three tiers read at 0.8 / 1.4 / 2.2 hull lengths. Reversal is one
## edit; see the W3 report's open points.
const LOOK_WIDTHS: Array[float] = [
	48.0, 48.0, 48.0,
	84.0, 84.0, 84.0,
	132.0, 132.0, 132.0,
]

const LOOK_NODE: StringName = &"Look"
const SHAPE_NODE: StringName = &"Shape"

var mineral_id: StringName = &""
var tier: int = 0
var yield_units: int = 0
var work: float = 0.0

var _look := 0
var _sprite: Sprite2D = null
var _shape: CollisionShape2D = null
var _cracked := false
## Whether the rock was rolled *with* ore. Ruling 17's "a yield-0 rock still cracks
## and despawns bare" is exactly this flag: a rock that never carried ore has
## nothing to cleave, so it cracks, emits and frees without fragments.
var _bore_ore := false


## 02 §5's roll lands here: which mineral the rock holds, its tier and how many ore
## units it carries. The look is rolled here too, uniformly over the nine shipped
## silhouettes on the global RNG (a caller that needs a reproducible look calls
## `seed()` first; the generation rolls that carry gameplay numbers are seeded in
## `AsteroidField`, not here).
##
## `size_class` (slice 0's addition, defaulted so every pre-existing three-argument
## call resolves exactly as before) pins the look row: a cleaving fragment must be
## a Medium or a Small, never whatever the uniform roll produced. `SIZE_ANY` keeps
## the uniform roll over all nine silhouettes.
func setup(
	mineral: StringName,
	mineral_tier: int,
	units: int,
	size_class: int = SIZE_ANY
) -> void:
	mineral_id = mineral
	tier = mineral_tier
	yield_units = maxi(units, 0)
	work = 0.0
	_cracked = false
	_bore_ore = yield_units > 0
	add_to_group(ROCK_GROUP)
	collision_layer = COLLISION_LAYER
	collision_mask = COLLISION_MASK
	_configure_body()
	_build_look(size_class)


## Fractional work in, whole ore units out. Work accumulates across calls, so a
## 0.1-per-hit caller mines one unit every ten hits. Returns the units this call
## mined; the rock emits `cracked` and despawns when the last unit leaves.
func apply_work(amount: float) -> int:
	if amount <= 0.0 or _cracked:
		return 0
	work += amount
	var units := 0
	while yield_units > 0 and work >= WORK_PER_UNIT - WORK_EPSILON:
		work = maxf(work - WORK_PER_UNIT, 0.0)
		yield_units -= 1
		units += 1
	if yield_units <= 0:
		_crack()
	return units


## The other half of a body-body impact (ENGINE_SPEC §4.2 item 6, CONTRACTS §4): the
## hull's contact monitor charges its own side and offers the peer's half through this
## method, which `NpcShip` answers by passing it to `take_damage`. A rock carries no
## hull pool, so its half goes through the rock's own mining channel at the shipped gun
## chip rate, exactly what a beam (`weapons.gd:_apply_beam`) and a bolt
## (`projectile.gd:_hit_rock`) apply, and is therefore readable as `work` and
## `yield_units` rather than vanishing. Measured (C1's 450 u/s ram at a 560 t medium
## rock): the offer is 186.179, so the rock gains 18.618 work, 18 ore units leave it and
## the rock moves 73.351 u/s / 21.056 u.
func apply_collision_damage(amount: float) -> void:
	apply_work(amount * WeaponsScript.GUN_CHIP_RATE)


func is_depleted() -> bool:
	return yield_units <= 0


## Which of the nine looks this rock rolled (0-8), for probes and review sheets.
func look_index() -> int:
	return _look


## The look row this rock rolled: `SIZE_SMALL`, `SIZE_MEDIUM` or `SIZE_LARGE`
## (ruling 17's cleaving class). Read off the look, so it is the sprite the player
## sees that decides what the rock breaks into.
func size_class() -> int:
	return floori(float(_look) / float(LOOKS_PER_SIZE))


## Ruling 17's "a yield-0 rock still cracks and despawns without fragments": only a
## rock that rolled ore cleaves. The field asks this before spawning anything.
func cleaves() -> bool:
	return _bore_ore


## The velocity the fragments inherit: `current_velocity × 1.2` of the §13 cleaving
## row, read while the rock still exists (the `cracked` emission happens before the
## free). The ±15° cone is the field's roll, because it owns the RNG.
func eject_velocity() -> Vector2:
	return linear_velocity * FRAGMENT_EJECT_MULT


## The collision radius the sprite's shorter side implies, in world units.
func world_radius() -> float:
	if _shape == null or _shape.shape == null:
		return 0.0
	return (_shape.shape as CircleShape2D).radius


func _crack() -> void:
	if _cracked:
		return
	_cracked = true
	cracked.emit()
	queue_free()


## Slice 0's rigid body: a heavy, damped, gravity-free rock (ruling 8). The mass is
## the §13 class column × `ROCK_MASS_MULT` read from the one owner of that table,
## so no number is duplicated here.
func _configure_body() -> void:
	mass = ROCK_MASS_MULT * _reference_hull_mass()
	linear_damp = LINEAR_DAMP
	linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	## Space, not a planet: the project's 980 u/s² 2D gravity would rain the field.
	gravity_scale = 0.0
	## A sleeping body stops answering contacts, and the ship's contact monitor is
	## what charges a ram to both sides (ruling 15). Rocks are few and cheap.
	can_sleep = false


func _reference_hull_mass() -> float:
	var row: Dictionary = ShipFitScript.HANDLING.get(ROCK_MASS_REFERENCE, {})
	return float(row.get(&"hull_mass", 0.0))


func _build_look(size_class: int) -> void:
	_look = _roll_look(size_class)
	var texture := LOOK_TEXTURES[_look]
	var scale_factor := LOOK_WIDTHS[_look] / maxf(float(texture.get_width()), 1.0)
	_sprite = Sprite2D.new()
	_sprite.name = LOOK_NODE
	_sprite.texture = texture
	_sprite.scale = Vector2(scale_factor, scale_factor)
	add_child(_sprite)
	var shorter_side := float(mini(texture.get_width(), texture.get_height()))
	var circle := CircleShape2D.new()
	circle.radius = 0.5 * shorter_side * scale_factor
	_shape = CollisionShape2D.new()
	_shape.name = SHAPE_NODE
	_shape.shape = circle
	add_child(_shape)


## A pinned row rolls one of its three silhouettes; `SIZE_ANY` (or an out-of-range
## request) keeps the original uniform roll over all nine, so a pre-slice-0 caller's
## distribution is unchanged.
func _roll_look(size_class: int) -> int:
	if size_class < SIZE_SMALL or size_class > SIZE_LARGE:
		return randi_range(0, LOOK_TEXTURES.size() - 1)
	var first := size_class * LOOKS_PER_SIZE
	return randi_range(first, first + LOOKS_PER_SIZE - 1)
