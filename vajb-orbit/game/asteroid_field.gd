class_name AsteroidField
extends Node2D
## One asteroid field: 6-12 rocks in a cluster, the 02 §5 generation rolls, the
## 02 §8 respawn bookkeeping and (engine slice 0) the ruling-17 cleaving.
## Contract: ENGINE_SPEC.md §8 ("4-8 asteroid fields (6-12 rocks each) ... POIs and
## fields re-roll on the single 20-minute `WorldClock`"), §6 (tiered cleaving: a
## depleted Large spawns 2-3 Medium fragments, a Medium 2 Small, a Small bursts into
## 1-2 pickups of its mineral; fragments eject at `current_velocity × 1.2` ±15°;
## yield-0 rocks despawn bare; fragments belong to the same field count), §13; §15;
## docs/gameplay/02_minerals.md §5 (the rolls), §7 and §8 (depletion, respawn and the
## ×0.7 diminishing window); docs/gameplay/11_galactic_map.md §1.1 (the per-sector
## tier weights, which supersede 02 §5's abstract ranges); docs/gameplay/
## 17_coder_handoff.md §4 (one 20-minute accumulator, no per-consumer Timers);
## slice-0 brief §M2 and pinned interface item 5.
##
## Consumer contract — W4's `game/sector.gd` binds this script duck-typed, so the
## three names below are the frozen handoff:
##   * `setup(config)` with `{&"tier_weights": Dictionary, &"rocks": int,
##     &"seed": int}` (only `tier_weights` is required; a missing `rocks` rolls
##     6-12 here, and a zero `seed` randomizes),
##   * `is_depleted() -> bool`,
##   * `respawn(now := -1) -> bool`, called on each elapsed 20-minute band.
##
## The clock is read, never owned: no Timer lives here, and the 20-minute cadence
## is the band itself (ENGINE_SPEC §8, 17 §4), not a second schedule.
##
## **Slice 0's split of labour:** `asteroid.gd` owns the cleaving *rules* (the size
## class, the split table, the ejection arithmetic); this file owns the *spawning*,
## because it holds the generation RNG, the field count and the pickups' world
## parent. Fragments are built by the same code path as the field's own rocks, so
## they are field members from birth: `rocks()`, `rock_count()` and `is_depleted()`
## see them, and a field with live fragments is not depleted (no respawn fires while
## a cleave is still being chewed through).

const AsteroidScript := preload("res://game/asteroid.gd")
const MineralCatalogScript := preload("res://game/mineral_catalog.gd")
const Clock := preload("res://autoload/world_clock.gd")

## `Pickup` is loaded lazily, exactly as the mining laser loads it: this field must
## be able to build, roll and cleave a rock field whether or not the pickup leaf
## script compiles, and a `preload` would make one bad leaf path kill the whole
## field. A missing/failed pickup script costs the burst's cargo, never the field.
const PICKUP_SCRIPT := "res://game/pickup.gd"

## ENGINE_SPEC §8's rocks-per-field band, and the fallback count when a caller
## hands in no `rocks` value.
const FIELD_ROCKS_MIN := 6
const FIELD_ROCKS_MAX := 12

## Cluster radius, and the ring geometry inside it. No spec number exists for a
## field's footprint: 400 u is this file's one placement value, small against the
## 10 000 u arena (§13 `SECTOR_SIZE`) and wide enough that twelve rocks of the
## largest look (132 u across) do not interpenetrate. Jitter values are the same
## kind of placement constant. Reversal is one edit.
const FIELD_RADIUS := 400.0
const FIELD_INNER_FRACTION := 0.35
const FIELD_ANGLE_JITTER := 0.25

## 02 §8's diminishing window: an asteroid rolled while the field is inside the
## five minutes after its last respawn carries ×0.7 yield. 01 §5.5 names the
## multiplier's purpose ("mine the same rock forever" must not pay).
const DIMINISHING_WINDOW_SECONDS := 300
const DIMINISHING_YIELD_MULT := 0.7

## Ruling 17's fragment placement: fragments land on a spread ring around the dying
## rock, at the dying rock's own radius plus the fragment's, so a cleave never
## spawns two bodies inside one another. The ring's angular jitter is the same kind
## of placement constant as the cluster's (`FIELD_ANGLE_JITTER`); no spec number
## exists for a spawn ring and none is invented as a gameplay value.
const FRAGMENT_ANGLE_JITTER := 0.25

## 02 §7's floating pickup prop and the group `Pickup.setup` joins. The burst's ore
## is placed on the same ring as the fragments, for the same reason.
const PICKUP_GROUP: StringName = &"pickup"
const PICKUP_NAME: StringName = &"BurstPickup"

## 02 §8's per-field stamps, in WorldClock seconds (the same basis as the sector's
## 20-minute band, so the window survives a process restart).
var last_depleted_time: int = 0
var last_respawn_time: int = 0

## The generation RNG. A caller that wants reproducible rocks seeds it through
## `setup(config)`'s `&"seed"`; a probe may also read it back.
var rng := RandomNumberGenerator.new()

var _tier_weights: Dictionary = {}
var _rocks: Array[Node2D] = []
var _rocks_per_cycle := FIELD_ROCKS_MIN
var _built := false
## Fragment names come from one counter, so a cleave's children can never collide
## with a rock's name or with an earlier cleave's.
var _spawned := 0
## The lazily loaded pickup leaf and its one-shot warning latch.
var _pickup: GDScript = null
var _pickup_warned := false


## Builds the field. `config` is W4's payload: `&"tier_weights"` (11 §1.1's weights
## for the sector, passed straight from `SectorRegistry`), `&"rocks"` (the sector's
## 6-12 roll) and `&"seed"`. A virgin field rolls at full yield: the ×0.7 window
## belongs to respawns only (02 §8, 01 §5.5).
func setup(config: Dictionary = {}) -> void:
	_tier_weights = _integer_keys(config.get(&"tier_weights", {}))
	rng = RandomNumberGenerator.new()
	var seed_value := int(config.get(&"seed", 0))
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	var count := int(config.get(&"rocks", 0))
	if count <= 0:
		count = rng.randi_range(FIELD_ROCKS_MIN, FIELD_ROCKS_MAX)
	_rocks_per_cycle = clampi(count, FIELD_ROCKS_MIN, FIELD_ROCKS_MAX)
	_clear_rocks()
	_roll_rocks(_rocks_per_cycle)
	_built = true


## True once every rock has cracked (02 §8: a fully depleted field is the one that
## respawns). A sector may call `respawn()` unconditionally: this is its guard.
func is_depleted() -> bool:
	if not _built:
		return false
	return rocks().is_empty()


## Re-rolls the field: fresh minerals and yields under 02 §5's rules for the same
## rock count (02 §8's "a respawned field is a fresh roll"). Stamps
## `last_respawn_time` first, so the new rocks roll inside the ×0.7 window.
##
## Returns false when the field still has rocks. `now` defaults to the WorldClock
## and exists so probes and review sheets can drive the window without waiting.
func respawn(now: int = -1) -> bool:
	if not is_depleted():
		return false
	last_respawn_time = now if now >= 0 else Clock.now()
	_clear_rocks()
	_roll_rocks(_rocks_per_cycle)
	return true


## 02 §8's window as a query: true while the field sits inside the five minutes
## after its last respawn.
func diminishing_active(now: int = -1) -> bool:
	if last_respawn_time <= 0:
		return false
	return (now if now >= 0 else Clock.now()) - last_respawn_time < DIMINISHING_WINDOW_SECONDS


## The live rocks, in spawn order. Cracking frees a rock, so freed entries are
## pruned here; `Sector` never calls this (it blips one per field, 11 §3).
func rocks() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for rock: Node2D in _rocks:
		if is_instance_valid(rock):
			out.append(rock)
	return out


func rock_count() -> int:
	return rocks().size()


## The rock count this field rolls per cycle (W4's roll, held across respawns).
func rocks_per_cycle() -> int:
	return _rocks_per_cycle


func tier_weights() -> Dictionary:
	return _tier_weights.duplicate()


func _roll_rocks(count: int) -> void:
	if _tier_weights.is_empty():
		## Defensive only: a field with no weights cannot roll a tier. W4 always
		## hands in `SectorRegistry`'s table, which is 11 §1.1.
		push_warning("AsteroidField: empty tier weights, field left bare")
		return
	for index in count:
		var tier := _roll_tier()
		var mineral: Dictionary = MineralCatalogScript.roll_mineral(tier, rng)
		var mineral_id := StringName(mineral.get(&"id", &""))
		if mineral_id == &"":
			push_warning("AsteroidField: unknown tier %d, rock %d skipped" % [tier, index])
			continue
		_spawn_rock(index, mineral_id, tier, _rolled_yield(tier))


## 02 §5's yield roll (`base × variance`) with 02 §8's ×0.7 window applied, exactly
## as the field roll has always applied it. One helper, so a rock the field rolls and
## a fragment a cleave rolls cannot drift apart.
func _rolled_yield(tier: int) -> int:
	var units := MineralCatalogScript.roll_yield(tier, rng)
	var multiplier := _yield_multiplier()
	if multiplier < 1.0:
		units = maxi(1, roundi(float(units) * multiplier))
	return units


func _spawn_rock(index: int, mineral_id: StringName, tier: int, units: int) -> void:
	var rock := _new_rock(
		"Rock%d" % (index + 1), mineral_id, tier, units, AsteroidScript.SIZE_ANY
	)
	rock.position = _rock_position(index)


## The one construction path for every rock in the field, originals and fragments
## alike: named, parented, initialised and connected before it is measured. The
## connect carries the rock itself (`bind`), because the `cracked` signal is the
## pinned bare signature and the field is what needs to know which rock died. The
## counter increments last, so a caller that names its child from `_spawned + 1`
## gets a unique name every time.
func _new_rock(
	node_name: String,
	mineral_id: StringName,
	tier: int,
	units: int,
	size_class: int
) -> RigidBody2D:
	var rock := AsteroidScript.new() as RigidBody2D
	rock.name = node_name
	add_child(rock)
	rock.call(&"setup", mineral_id, tier, units, size_class)
	rock.connect(&"cracked", _on_rock_cracked.bind(rock))
	_rocks.append(rock)
	_spawned += 1
	return rock


## Ruling 17, on the way out: a depleted rock cleaves into fragments (or, at the
## small end, bursts into pickups) before it is freed. The `cracked` emission is
## synchronous inside `apply_work`, so the rock is still valid here and its velocity
## is still readable -- which is what `× 1.2` is measured against.
func _on_rock_cracked(rock: Node2D) -> void:
	_rocks.erase(rock)
	_cleave(rock)
	if _rocks.is_empty():
		last_depleted_time = Clock.now()


## §13's "Fragment split: L → 2-3 M · M → 2 S · S → 1-2 pickups". A yield-0 rock
## carries nothing to break and despawns bare (§6/§15). A small never spawns rock
## fragments: its cleave is the pickup burst.
func _cleave(rock: Node2D) -> void:
	if not bool(rock.call(&"cleaves")):
		return
	var size_class: int = int(rock.call(&"size_class"))
	if size_class == AsteroidScript.SIZE_SMALL:
		_spawn_pickup_burst(rock)
		return
	var split := Vector2i(
		AsteroidScript.FRAGMENT_SPLIT.get(size_class, Vector2i.ZERO) as Vector2i
	)
	var count := rng.randi_range(split.x, split.y)
	if count <= 0:
		return
	var velocity: Vector2 = rock.call(&"eject_velocity")
	var origin: Vector2 = rock.global_position
	var ring := maxf(float(rock.call(&"world_radius")), 0.0)
	var mineral_id := StringName(rock.get(&"mineral_id"))
	var tier := int(rock.get(&"tier"))
	for index in count:
		var fragment := _new_rock(
			"Fragment%d" % (_spawned + 1),
			mineral_id,
			tier,
			_rolled_yield(tier),
			_fragment_size(size_class)
		)
		var angle := TAU * float(index) / float(count)
		angle += rng.randf_range(-FRAGMENT_ANGLE_JITTER, FRAGMENT_ANGLE_JITTER)
		var distance := ring + float(fragment.call(&"world_radius"))
		fragment.global_position = origin + Vector2.RIGHT.rotated(angle) * distance
		fragment.linear_velocity = velocity.rotated(
			deg_to_rad(
				rng.randf_range(
					-AsteroidScript.FRAGMENT_EJECT_CONE_DEG,
					AsteroidScript.FRAGMENT_EJECT_CONE_DEG
				)
			)
		)


## The row below: a Large's fragments are Medium, a Medium's are Small (§13).
func _fragment_size(size_class: int) -> int:
	return size_class - 1


## Ruling 17's small end: "a Small bursts into 1-2 resource pickups of its mineral".
## The pickups are the same floating cargo a mining cycle spawns (02 §7), so they
## carry the ore item id the profile's manifest reads, and they are parented to the
## world rather than to the field so a respawn cannot free the player's ore.
func _spawn_pickup_burst(rock: Node2D) -> void:
	var script := _pickup_script()
	if script == null:
		return
	var item := MineralCatalogScript.ore_id(StringName(rock.get(&"mineral_id")))
	if item == &"":
		return
	var count := rng.randi_range(
		AsteroidScript.PICKUP_BURST.x, AsteroidScript.PICKUP_BURST.y
	)
	var origin: Vector2 = rock.global_position
	var ring := maxf(float(rock.call(&"world_radius")), 0.0)
	var parent := _world_parent()
	for index in count:
		var pickup := script.new() as Node2D
		pickup.name = PICKUP_NAME
		parent.add_child(pickup)
		var angle := TAU * float(index) / float(count)
		angle += rng.randf_range(-FRAGMENT_ANGLE_JITTER, FRAGMENT_ANGLE_JITTER)
		pickup.global_position = origin + Vector2.RIGHT.rotated(angle) * ring
		pickup.call(&"setup", item, 1, false)


## The pickup leaf, loaded once and remembered. A script that fails to compile
## (a stale asset path in it, as the naming re-layout left behind) is reported once
## per field, not once per burst: the rock field keeps working either way.
## `can_instantiate()` is the real gate — a script that failed to compile still
## loads as a `GDScript` object and only fails at `new()`.
func _pickup_script() -> GDScript:
	if _pickup != null:
		return _pickup
	if not ResourceLoader.exists(PICKUP_SCRIPT):
		_report_missing_pickup("does not exist")
		return null
	var script := load(PICKUP_SCRIPT) as GDScript
	if script == null or not script.can_instantiate():
		_report_missing_pickup("failed to compile")
		return null
	_pickup = script
	return _pickup


func _report_missing_pickup(reason: String) -> void:
	if _pickup_warned:
		return
	_pickup_warned = true
	push_warning(
		"AsteroidField: %s %s; a small rock's pickup burst spawns nothing"
		% [PICKUP_SCRIPT, reason]
	)


## Pickups live in world space and outlive the rock that burst: `current_scene` is
## the running scene (the same parent the mining laser's pickups use), and the tree
## root is the fallback for a field outside a scene (a probe).
func _world_parent() -> Node:
	var tree := get_tree()
	if tree == null:
		return self
	return tree.current_scene if tree.current_scene != null else tree.root


func _clear_rocks() -> void:
	for rock: Node2D in _rocks:
		if is_instance_valid(rock):
			rock.queue_free()
	_rocks.clear()


## The ×0.7 window, evaluated at roll time against `last_respawn_time` — the
## literal 02 §8 implementation note. A virgin field (no stamp) rolls at full
## yield; every respawn stamps first, so a respawned field's rocks roll at ×0.7.
## See the W3 report for the reading of 02 §8's note and its reversal path.
func _yield_multiplier() -> float:
	if last_respawn_time <= 0:
		return 1.0
	if Clock.now() - last_respawn_time >= DIMINISHING_WINDOW_SECONDS:
		return 1.0
	return DIMINISHING_YIELD_MULT


## 11 §1.1's weights, rolled exactly as `MineralCatalog.roll_tier` rolls its
## per-sector table (same tier order 1-4, same accumulate), because this field is
## handed the weights rather than a sector number.
func _roll_tier() -> int:
	var total := 0
	for weight: Variant in _tier_weights.values():
		total += int(weight)
	if total <= 0:
		return 0
	var roll := rng.randi_range(1, total)
	var accumulated := 0
	for tier: int in [1, 2, 3, 4]:
		if not _tier_weights.has(tier):
			continue
		accumulated += int(_tier_weights[tier])
		if roll <= accumulated:
			return tier
	return 0


## An even angular spread at a jittered radius: 6-12 rocks cannot stack, which
## keeps a separation pass out of the loop.
func _rock_position(index: int) -> Vector2:
	var angle := TAU * float(index) / float(maxi(_rocks_per_cycle, 1))
	angle += rng.randf_range(-FIELD_ANGLE_JITTER, FIELD_ANGLE_JITTER)
	var radius := rng.randf_range(FIELD_RADIUS * FIELD_INNER_FRACTION, FIELD_RADIUS)
	return Vector2.RIGHT.rotated(angle) * radius


## Weight tables are int-keyed in `MineralCatalog.SECTOR_TIER_MIX`; a string-keyed
## config (a hand-written or JSON-shaped payload) is normalised rather than
## silently rolling tier 0.
func _integer_keys(source: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key: Variant in source.keys():
		out[int(key)] = int(source[key])
	return out
