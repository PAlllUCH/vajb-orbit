class_name Sector
extends Node2D
## One sector's live contents: the ENGINE_SPEC §8 spawn set, the station's dock
## zone and the minimap blip feed. Built in code (this slice ships no scene
## file), so `populate(row, seed)` is the whole entry point.
## Contract: docs/CONTRACTS.md §6, ENGINE_SPEC.md §7
## (docking, safe warp), §8 (spawn set, respawn on the one clock), §13
## (SECTOR_SIZE, the 300 u spawn offset), 11 §1-§3, 02 §8, 17 §4.
##
## Scope note (brief §W4 item 2): this file spawns the asteroid fields, the
## primary station and its DockZone, and the *plan* for the rest. Wreck fields,
## hulks, derelicts, anomalies and beacons are slice 3; pirates, patrols and
## convoys are slice 2. Their counts are rolled into `spawn_plan()` and nothing
## is instantiated for them yet.
##
## `game/asteroid_field.gd` is W3's file, written in parallel: this file places
## the field nodes and hands each one its generation config, while the field owns
## its rocks, its 02 §8 depletion stamps and its respawn roll. The binding is
## duck-typed (`has_method`) so a sector built before W3 lands still measures its
## field and blip counts; the payload shape is recorded in
## .agents/gen/engine_wave1_w4_report.md for the W6 review.

const Registry := preload("res://game/sector_registry.gd")
const Clock := preload("res://autoload/world_clock.gd")

## W3's field script, loaded by path (project convention: never depend on the
## global class table, so a headless caller and the editor agree). Absent until
## W3 lands, hence the `ResourceLoader.exists` guard.
const ASTEROID_FIELD_SCRIPT := "res://game/asteroid_field.gd"

## The dockable station POI (ENVIRONMENT_SPEC §6, ASSET_CATALOG). `env_base_*`
## and `env_station_mmo.png` are station-scale alternatives but neither is
## catalogued as the dockable station.
const StationTexture := preload("res://assets/env/poi/env_station.png")

const UNALIGNED: StringName = &"unaligned"

## Station art (2048 × 2048) drawn at the shipped hull scale - the same 0.0663
## game.tscn gives the player's `ship_vanguard_side.png` - so the station reads
## ~135.8 u across, about 2.3× a hull's length, matching
## ASSET_WIRING_HANDOFF §2's "roughly 2x hull scale" note for station-scale art.
const STATION_SCALE := 0.0663

## ENGINE_SPEC §13: "player spawns 300 u off the dock ring".
const PLAYER_SPAWN_OFFSET := 300.0

## Dock zone radius. §13 fixes the spawn offset from the ring but no ring radius,
## so 120 u is this file's one placement value: the station's ~67.9 u half-extent
## plus clearance, so the zone is just outside the hull. Reversal is one edit.
const DOCK_RING_RADIUS := 120.0

## Spawn bearing. §13 fixes the distance, not the direction; +Y (screen down) is
## an arbitrary deterministic pick so the spawn point is reproducible.
const SPAWN_BEARING := Vector2.DOWN

## Field placement clearance, also unsourced by §13. Clearance keeps rock clusters
## 1800 u from the arena centre, so the nearest a cluster centre can sit to the
## player spawn (420 u out, worst case on the same bearing) is 1380 u - more than
## twice a rock cluster's own extent. The margin keeps clusters inside the 10 000 u
## arena, and the jitter stops the even-slot ring reading as a perfect circle. All
## three are tunable in one edit and are listed as open points in the W4 report.
const FIELD_STATION_CLEARANCE := 1800.0
const FIELD_EDGE_MARGIN := 800.0
const FIELD_SLOT_JITTER := 0.25

## 17 §4's one-accumulator rule: the sector reads the shared WorldClock lazily and
## owns no Timer. This gate only throttles the read; it is not a second clock.
const CLOCK_POLL_SECONDS := 1.0

var _row: Dictionary = {}
var _plan: Dictionary = {}
var _fields: Array[Node2D] = []
var _field_script: GDScript = null
var _station: Sprite2D = null
var _dock_zone: Area2D = null
var _spawn_point := Vector2.ZERO
var _rng := RandomNumberGenerator.new()
var _last_band := 0
var _clock_accumulator := 0.0
var _populated := false


## Builds the sector for one registry row and returns the player spawn point.
##
## `random_seed` 0 randomizes (the in-game call); a non-zero seed makes every roll
## reproducible for probes and tests. The return value is the W2 handoff: the
## brief (§W4 item 2) lets `populate` return the spawn point or the station expose
## it, and this file returns it.
func populate(row: Dictionary, random_seed: int = 0) -> Vector2:
	_clear()
	_row = row.duplicate(true)
	_rng = RandomNumberGenerator.new()
	if random_seed == 0:
		_rng.randomize()
	else:
		_rng.seed = random_seed
	_field_script = null
	if ResourceLoader.exists(ASTEROID_FIELD_SCRIPT):
		_field_script = load(ASTEROID_FIELD_SCRIPT) as GDScript
	var densities: Dictionary = _row.get(&"densities", {})
	var owner_id := StringName(_row.get(&"owner", UNALIGNED))
	# ENGINE_SPEC §13: "station near centre". The sector node's origin is the
	# arena centre, so the station sits on it.
	var centre := Vector2.ZERO
	var stations := int(densities.get(&"stations", 0))
	if stations > 0:
		_spawn_station(centre)
	var fields := _roll_range(densities, &"fields_min", &"fields_max")
	_spawn_fields(centre, fields, _row.get(&"tier_weights", {}), densities)
	var wreck_fields := _roll_range(densities, &"wrecks_min", &"wrecks_max")
	var hulks := 0
	for _field_index in wreck_fields:
		hulks += _roll_range(densities, &"hulks_min", &"hulks_max")
	_plan = {
		&"fields": fields,
		&"stations": stations,
		&"outposts": int(densities.get(&"outposts", 0)),
		&"wreck_fields": wreck_fields,
		&"hulks": hulks,
		&"derelicts": wreck_fields * int(densities.get(&"derelicts_per_wreck_field", 0)),
		&"anomalies": _roll_range(densities, &"anomalies_min", &"anomalies_max"),
		# 11 §3: one per corridor plus one per gate. Corridors and gates are
		# gate-slice data, so the plan carries 0 until slice 3.
		&"beacons": 0,
		&"pirates": _roll_range(densities, &"pirate_min", &"pirate_max"),
		# 11 §3: patrols exist in faction space only, so unaligned space has
		# none. §13 gives no patrol count, so the plan carries the presence flag.
		&"patrols": owner_id != UNALIGNED,
		&"convoys": int(densities.get(&"convoys", 0)),
	}
	_spawn_point = centre + SPAWN_BEARING * (DOCK_RING_RADIUS + PLAYER_SPAWN_OFFSET)
	_last_band = Clock.now()
	_clock_accumulator = 0.0
	_populated = true
	return _spawn_point


## The rolled §8 population plan for the current row. Slice 2/3 consumers read
## this; slice 1 only measures it (the probe prints it as acceptance evidence).
func spawn_plan() -> Dictionary:
	return _plan.duplicate(true)


func spawn_point() -> Vector2:
	return _spawn_point


func sector_id() -> StringName:
	return StringName(_row.get(&"id", &""))


func display_name() -> String:
	return String(_row.get(&"name", ""))


func has_station() -> bool:
	return _station != null


func station_position() -> Vector2:
	if _station == null:
		return Vector2.ZERO
	return _station.global_position


## The W2 handoff for docking (§7: "fly into the station's dock zone → prompt
## F"). Geometric on purpose: the player ship is a plain Node2D this slice, so a
## physics overlap would report nothing. An unaligned sector has no station, so
## this is always false there and safe warp correctly reports unavailable.
func dock_zone_contains(world_position: Vector2) -> bool:
	if _station == null:
		return false
	return world_position.distance_to(_station.global_position) <= DOCK_RING_RADIUS


func field_count() -> int:
	return _fields.size()


func fields() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for field: Node2D in _fields:
		out.append(field)
	return out


## Minimap feed for game.gd (brief item 7): one blip per field, not per rock, plus
## the station. Key names are the string keys the shipped HUD minimap reads
## (`"pos"` / `"kind"`); kinds are the 11 §3 classes. Hostile blips arrive with
## slice 2's NPCs.
func blips() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _station != null:
		out.append({"pos": _station.global_position, "kind": &"friendly"})
	for field: Node2D in _fields:
		out.append({"pos": field.global_position, "kind": &"neutral"})
	return out


## Advances this sector's respawn bookkeeping to now and returns the number of
## 20-minute bands consumed (17 §4: one accumulator, evaluated lazily, no
## per-consumer Timer). `_process` calls it on its 1 s gate; probes and tests call
## it directly so they never depend on frame timing.
func refresh_clock() -> int:
	var now := Clock.now()
	if _last_band <= 0:
		_last_band = now
		return 0
	var bands := Clock.bands_between(_last_band, now)
	if bands <= 0:
		return 0
	_last_band = now
	for _band: int in range(bands):
		_respawn_cycle()
	return bands


func _process(delta: float) -> void:
	if not _populated:
		return
	_clock_accumulator += delta
	if _clock_accumulator < CLOCK_POLL_SECONDS:
		return
	_clock_accumulator = 0.0
	refresh_clock()


## One band's respawn work. ENGINE_SPEC §8: fields re-roll on the 20-minute
## WorldClock - the field owns that roll and the 02 §8 ×0.7 diminishing window,
## so the sector only asks a depleted field to respawn. Slice 3 adds the POI
## re-rolls (derelicts and anomalies are one-shot per cycle).
func _respawn_cycle() -> void:
	for field: Node2D in _fields:
		if not is_instance_valid(field):
			continue
		if field.has_method(&"is_depleted") and not bool(field.call(&"is_depleted")):
			continue
		if field.has_method(&"respawn"):
			field.call(&"respawn")


## Even angular slots with a small jitter: 4-8 clusters land on a ring between
## FIELD_STATION_CLEARANCE and the arena edge, which keeps them apart and keeps
## the station and the 300 u spawn ring clear of rock collisions without a
## separate separation constant.
func _spawn_fields(
	centre: Vector2, count: int, tier_weights: Dictionary, densities: Dictionary
) -> void:
	var half := minf(Registry.SECTOR_SIZE.x, Registry.SECTOR_SIZE.y) * 0.5
	var inner := FIELD_STATION_CLEARANCE
	var outer := half - FIELD_EDGE_MARGIN
	if outer <= inner:
		outer = inner + 1.0
	for index in count:
		var angle := TAU * float(index) / float(count)
		angle += _rng.randf_range(-FIELD_SLOT_JITTER, FIELD_SLOT_JITTER)
		var radius := _rng.randf_range(inner, outer)
		_add_field(centre + Vector2.RIGHT.rotated(angle) * radius, tier_weights, densities)


func _add_field(position: Vector2, tier_weights: Dictionary, densities: Dictionary) -> void:
	var field: Node2D = null
	if _field_script != null:
		field = _field_script.new() as Node2D
	if field == null:
		# W3 has not landed: a bare marker still carries the field's position for
		# the minimap and the plan, and the W7 fixer swaps in the real field.
		field = Node2D.new()
	field.name = "Field%d" % (_fields.size() + 1)
	field.position = position
	field.add_to_group(&"asteroid_field")
	add_child(field)
	_fields.append(field)
	var config := {
		&"tier_weights": tier_weights,
		&"rocks": _roll_range(densities, &"rocks_min", &"rocks_max"),
		&"seed": _rng.randi(),
	}
	if field.has_method(&"setup"):
		field.call(&"setup", config)


func _spawn_station(centre: Vector2) -> void:
	_station = Sprite2D.new()
	_station.name = "Station"
	_station.texture = StationTexture
	_station.scale = Vector2(STATION_SCALE, STATION_SCALE)
	_station.position = centre
	_station.add_to_group(&"station")
	add_child(_station)
	# The DockZone is a sibling of the sprite, not its child: the sprite carries
	# the 0.0663 art scale, which would scale a child's collision circle down to
	# ~8 u. As a sector child it keeps DOCK_RING_RADIUS in world units.
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = DOCK_RING_RADIUS
	shape.shape = circle
	_dock_zone = Area2D.new()
	_dock_zone.name = "DockZone"
	_dock_zone.position = centre
	_dock_zone.add_to_group(&"dock_zone")
	_dock_zone.add_child(shape)
	add_child(_dock_zone)


## Re-populating a sector (a transition) drops the previous contents immediately:
## `free()` rather than `queue_free()`, so a probe or a transition can measure the
## fresh set in the same frame.
func _clear() -> void:
	_fields.clear()
	_station = null
	_dock_zone = null
	_plan.clear()
	_populated = false
	for child: Node in get_children():
		remove_child(child)
		child.free()


func _roll_range(source: Dictionary, min_key: StringName, max_key: StringName) -> int:
	var low := int(source.get(min_key, 0))
	var high := int(source.get(max_key, low))
	if high < low:
		high = low
	return _rng.randi_range(low, high)
