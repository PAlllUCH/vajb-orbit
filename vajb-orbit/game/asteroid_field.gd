class_name AsteroidField
extends Node2D
## One asteroid field: 6-12 rocks in a cluster, the 02 §5 generation rolls and the
## 02 §8 respawn bookkeeping.
## Contract: ENGINE_SPEC.md §8 ("4-8 asteroid fields (6-12 rocks each) ... POIs and
## fields re-roll on the single 20-minute `WorldClock`"), §13; docs/gameplay/
## 02_minerals.md §5 (the rolls), §7 and §8 (depletion, respawn and the ×0.7
## diminishing window); docs/gameplay/11_galactic_map.md §1.1 (the per-sector tier
## weights, which supersede 02 §5's abstract ranges); docs/gameplay/
## 17_coder_handoff.md §4 (one 20-minute accumulator, no per-consumer Timers);
## brief §W3 item 2.
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

const AsteroidScript := preload("res://game/asteroid.gd")
const MineralCatalogScript := preload("res://game/mineral_catalog.gd")
const Clock := preload("res://autoload/world_clock.gd")

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
	var multiplier := _yield_multiplier()
	for index in count:
		var tier := _roll_tier()
		var mineral: Dictionary = MineralCatalogScript.roll_mineral(tier, rng)
		var mineral_id := StringName(mineral.get(&"id", &""))
		if mineral_id == &"":
			push_warning("AsteroidField: unknown tier %d, rock %d skipped" % [tier, index])
			continue
		var units := MineralCatalogScript.roll_yield(tier, rng)
		if multiplier < 1.0:
			units = maxi(1, roundi(float(units) * multiplier))
		_spawn_rock(index, mineral_id, tier, units)


func _spawn_rock(index: int, mineral_id: StringName, tier: int, units: int) -> void:
	var rock := AsteroidScript.new() as Node2D
	rock.name = "Rock%d" % (index + 1)
	rock.position = _rock_position(index)
	add_child(rock)
	rock.call(&"setup", mineral_id, tier, units)
	rock.connect(&"cracked", _on_rock_cracked.bind(rock))
	_rocks.append(rock)


func _on_rock_cracked(rock: Node2D) -> void:
	_rocks.erase(rock)
	if _rocks.is_empty():
		last_depleted_time = Clock.now()


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
