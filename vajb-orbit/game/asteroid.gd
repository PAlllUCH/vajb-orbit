class_name Asteroid
extends StaticBody2D
## One mineable rock: a solid body that accumulates extraction work and cracks
## open at yield 0.
## Contract: ENGINE_SPEC.md §6 (mining — the laser is primary, guns work rocks at
## 10 %; rocks are solid, block shots and beams), §13 (`MINE_CYCLE` 1.2 s per ore
## unit), §15 ("Mining: N cycles on a rock spawn N ore pickups; gun work
## accumulates at 10 %; cracks at yield 0"); docs/gameplay/02_minerals.md §5 (the
## mineral and yield rolls) and §7 (the mining flow); brief §W3 item 1 and pinned
## interface item 4.
##
## Work, not damage: `apply_work` accumulates fractional work and converts it to
## whole ore units at `WORK_PER_UNIT`, so 02 §7.1's "one completed extraction cycle
## pops one ore unit" and ENGINE_SPEC §6's 10 % gun rate are the same arithmetic
## with different callers. Slice 2's weapons call `apply_work(dps * 0.1 * delta)`;
## no weapon code lives here.
##
## The 02 §5 mineral and yield rolls happen in `AsteroidField`, which owns the
## generation RNG; this file only carries the result (mineral, tier, yield). The
## sprite's size class is a look and never a stat: throughput is per unit of work,
## so a large rock mines exactly as fast as a small one.

signal cracked

## 02 §7.1 / §15: one unit of ore per unit of work. The mining laser applies
## exactly this per cycle; a weapon applies a fraction of it per hit.
const WORK_PER_UNIT := 1.0

## Work is accumulated in floats, so a caller applying 0.1 per hit reaches
## 0.9999999999999999 after ten hits. The conversion forgives that much and no
## more, so 02 §6's 10 % rate is exact by intent rather than an eleventh hit.
const WORK_EPSILON := 0.0001

## Physics layer 1 (bit 0). Rocks are solid to ships and block shots and beams
## (ENGINE_SPEC §6), so this body carries the layer and no mask: the mining laser's
## cursor ray masks the rock layer, and a ship that collides with rocks is the
## moving body masking it (the ship's own layer is W2's choice).
const COLLISION_LAYER := 1
const ROCK_GROUP: StringName = &"asteroid"

## The nine shipped Phase B rock sprites: ENVIRONMENT_SPEC §4's three size tiers
## times three silhouettes, all pre-cut `rgba` (ASSET_CATALOG). Row order is
## S1-S3, M1-M3, L1-L3.
const LOOK_TEXTURES: Array[Texture2D] = [
	preload("res://assets/env/env_asteroid_S1.png"),
	preload("res://assets/env/env_asteroid_S2.png"),
	preload("res://assets/env/env_asteroid_S3.png"),
	preload("res://assets/env/env_asteroid_M1.png"),
	preload("res://assets/env/env_asteroid_M2.png"),
	preload("res://assets/env/env_asteroid_M3.png"),
	preload("res://assets/env/env_asteroid_L1.png"),
	preload("res://assets/env/env_asteroid_L2.png"),
	preload("res://assets/env/env_asteroid_L3.png"),
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


## 02 §5's roll lands here: which mineral the rock holds, its tier and how many ore
## units it carries. The look is rolled here too, uniformly over the nine shipped
## silhouettes on the global RNG (a caller that needs a reproducible look calls
## `seed()` first; the generation rolls that carry gameplay numbers are seeded in
## `AsteroidField`, not here).
func setup(mineral: StringName, mineral_tier: int, units: int) -> void:
	mineral_id = mineral
	tier = mineral_tier
	yield_units = maxi(units, 0)
	work = 0.0
	_cracked = false
	add_to_group(ROCK_GROUP)
	collision_layer = COLLISION_LAYER
	collision_mask = 0
	_build_look()


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


func is_depleted() -> bool:
	return yield_units <= 0


## Which of the nine looks this rock rolled (0-8), for probes and review sheets.
func look_index() -> int:
	return _look


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


func _build_look() -> void:
	_look = randi_range(0, LOOK_TEXTURES.size() - 1)
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
