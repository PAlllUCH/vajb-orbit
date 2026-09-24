class_name Sector
extends Node2D
## One sector's live contents: the ENGINE_SPEC §8 spawn set (asteroid fields, the
## station's dock zone, the NPC hulls the registry's per-sector band calls for) and
## the minimap blip feed. Built in code (this slice ships no scene file), so
## `populate(row, seed)` is the whole entry point.
## Contract: docs/CONTRACTS.md §6, ENGINE_SPEC.md §7
## (docking, safe warp), §8 (spawn set, respawn on the one clock), §13
## (SECTOR_SIZE, the 300 u spawn offset), 11 §1-§3, 02 §8, 17 §4.
##
## Scope note (brief §W4 item 2): this file spawns the asteroid fields, the
## primary station and its DockZone, the slice-2 NPC hulls (`_spawn_npcs`, from
## `NpcRegistry.spawns_for`) and, since S6, the travel geometry of the sector's own
## registry row: one jump-gate ring per `gate_links` link (11 §2.1), one border
## corridor per `corridors` entry (11 §2.2) and the POIs 11 §3 calls for (derelicts,
## anomalies and nav beacons, `_spawn_pois`, plus the wreck sites a kill leaves).
## Wreck fields and their non-interactive hulks are still counts in `spawn_plan()`
## only - nothing is instantiated for them (no doc places them and no consumer reads
## them yet).
##
## `game/asteroid_field.gd` is W3's file, written in parallel: this file places
## the field nodes and hands each one its generation config, while the field owns
## its rocks, its 02 §8 depletion stamps and its respawn roll. The binding is
## duck-typed (`has_method`) so a sector built before W3 lands still measures its
## field and blip counts; the payload shape is recorded in
## .agents/gen/engine_wave1_w4_report.md for the W6 review.

const Registry := preload("res://game/sector_registry.gd")
const Clock := preload("res://autoload/world_clock.gd")

## W3's NPC layer (slice 2): the registry owns the archetype rows, the per-sector
## counts, the factions and the swap-ready sprite paths; the hull owns its body, its
## brain and its vital pools. The sector only rolls the band, places the hull on a POI
## and hands it the options bag, reached by path like every other cross-file reach here
## (a brand-new `class_name` is only in the global table after a project scan).
const NpcRegistryScript := preload("res://game/npc_registry.gd")
const NpcShipScript := preload("res://game/npc_ship.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")

## S6's travel geometry (CONTRACTS §19): the gate ring and the border corridor, reached
## by path like every other cross-file reach here.
const GateScript := preload("res://game/gate.gd")
const CorridorScript := preload("res://game/corridor.gd")

## S6's POIs (CONTRACTS §19, 11 §3/§5): the derelicts, anomalies, beacons and wreck
## sites, reached by path like the travel geometry.
const PoiScript := preload("res://game/poi.gd")

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

## 11 §2.1's "gate structure near its primary station": the ring is placed on the
## bearing of the destination's own map edge, this far from the arena centre. No doc
## gives the radius, so 900 u is this file's placement value (one edit reverses it).
const GATE_RING_RADIUS := 900.0

## No doc places a nav beacon beyond "1 per corridor + 1 per gate" (11 §3), so a gate's
## beacon stands this far outside the ring (clear of the 200 u trigger) and a corridor's
## sits on its band's centre. One edit reverses it.
const BEACON_GATE_OFFSET := 300.0

## Raised for every NPC hull this sector spawns, so the wiring (`game.gd`) can bind a
## hull's `died` before the first shot without polling the tree. A re-population raises
## it again for the fresh set.
signal npc_spawned(ship: Node2D)

## Raised for every POI this sector spawns or is handed (S6, 11 §3), so the wiring can
## bind a derelict's `scanned` reward. A re-population raises it again for the fresh set.
signal poi_spawned(poi: Node2D)

var _row: Dictionary = {}
var _plan: Dictionary = {}
var _fields: Array[Node2D] = []
var _field_script: GDScript = null
var _station: Sprite2D = null
var _dock_zone: Area2D = null
var _gates: Array[Node2D] = []
var _corridors: Array[Node2D] = []
var _pois: Array[Node2D] = []
var _npcs: Array[Node2D] = []
var _npc_anchor_index := 0
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
	var rolled_fields := _roll_range(densities, &"fields_min", &"fields_max")
	_spawn_fields(centre, rolled_fields, _row.get(&"tier_weights", {}), densities)
	## S6: the travel geometry comes off the same row, before the plan is built so the
	## beacon count (11 §3: one per corridor plus one per gate) is the live one.
	_spawn_travel(centre)
	var wreck_fields := _roll_range(densities, &"wrecks_min", &"wrecks_max")
	var hulks := 0
	for _field_index in wreck_fields:
		hulks += _roll_range(densities, &"hulks_min", &"hulks_max")
	_plan = {
		&"fields": rolled_fields,
		&"stations": stations,
		&"outposts": int(densities.get(&"outposts", 0)),
		&"wreck_fields": wreck_fields,
		&"hulks": hulks,
		&"derelicts": wreck_fields * int(densities.get(&"derelicts_per_wreck_field", 0)),
		&"anomalies": _roll_range(densities, &"anomalies_min", &"anomalies_max"),
		# 11 §3: one per corridor plus one per gate, now that S6 spawns both.
		&"beacons": _corridors.size() + _gates.size(),
		# The rolled §8 counts for a probe to read; the live hulls are `npcs()` and come
		# from the registry's own per-sector band (the same §13 numbers, split between
		# pirates and swarmers), so this entry is the plan's pirate share, not the set.
		&"pirates": _roll_range(densities, &"pirate_min", &"pirate_max"),
		# 11 §3: patrols exist in faction space only, so unaligned space has
		# none. §13 gives no patrol count, so the plan carries the presence flag.
		&"patrols": owner_id != UNALIGNED,
		&"convoys": int(densities.get(&"convoys", 0)),
	}
	## S6's POIs come off the same plan (11 §3's densities: one derelict per wreck
	## field, 1-2 anomalies, one beacon per corridor plus one per gate), placed after
	## the plan so their counts are the live ones and before the hulls so a hull's
	## anchor walk sees a complete sector.
	_spawn_pois(centre)
	_spawn_point = centre + SPAWN_BEARING * (DOCK_RING_RADIUS + PLAYER_SPAWN_OFFSET)
	## §8's on-entry set: the fields above are placed by count, the NPC hulls by the
	## registry's own per-sector band (the `_plan` entries are the rolled counts for a
	## probe to read; the hulls themselves are the live set).
	_spawn_npcs()
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


## The jump-gate rings this sector spawned, one per `gate_links` link (11 §2.1). The
## wiring reads them to raise the prompt and to bind each ring's `jumped`.
func gates() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for gate: Node2D in _gates:
		if is_instance_valid(gate):
			out.append(gate)
	return out


## The border corridors this sector spawned, one per `corridors` entry (11 §2.2). The
## wiring drives each one's presence hold from the ship's position.
func corridors() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for corridor: Node2D in _corridors:
		if is_instance_valid(corridor):
			out.append(corridor)
	return out


## Minimap feed for game.gd (brief item 7): one blip per field, not per rock, plus
## the station, the gate rings, the live NPC hulls and S6's POIs. Key names are the
## string keys the shipped HUD minimap reads (`"pos"` / `"kind"`); kinds are the
## 11 §3/§5 mapping (gates, stations and beacons `friendly`). A hull's own class comes
## off its registry row (`NpcShip.blip_kind()`: hostile for pirates, swarmers and
## patrols, neutral for a convoy). 11 §5's soft fog is applied here: a derelict's or
## anomaly's blip appears only once scanned or beacon-revealed (`Poi.is_revealed`),
## while gates, stations, beacons and wreck sites always appear.
func blips() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _station != null:
		out.append({"pos": _station.global_position, "kind": &"friendly"})
	for gate: Node2D in _gates:
		if is_instance_valid(gate):
			out.append({"pos": gate.global_position, "kind": &"friendly"})
	for field: Node2D in _fields:
		out.append({"pos": field.global_position, "kind": &"neutral"})
	for poi: Node2D in _pois:
		if not is_instance_valid(poi):
			continue
		if not bool(poi.call(&"is_revealed")):
			continue
		out.append({"pos": poi.global_position, "kind": StringName(poi.call(&"blip_kind"))})
	for ship: Node2D in _npcs:
		if not is_instance_valid(ship):
			continue
		out.append({"pos": ship.global_position, "kind": _npc_blip_kind(ship)})
	return out


## S6's POIs, one entry per live node (11 §3/§5): derelicts, anomalies, beacons and
## the wreck sites a kill left. The wiring reads them to drive the scan channel, the
## 200 u anomaly triggers and the rift drain.
func pois() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for poi: Node2D in _pois:
		if is_instance_valid(poi):
			out.append(poi)
	return out


func pois_of_kind(poi_kind: StringName) -> Array[Node2D]:
	var out: Array[Node2D] = []
	for poi: Node2D in pois():
		if StringName(poi.get(&"kind")) == poi_kind:
			out.append(poi)
	return out


func derelicts() -> Array[Node2D]:
	return pois_of_kind(PoiScript.KIND_DERELICT)


func anomalies() -> Array[Node2D]:
	return pois_of_kind(PoiScript.KIND_ANOMALY)


func beacons() -> Array[Node2D]:
	return pois_of_kind(PoiScript.KIND_BEACON)


func wrecks() -> Array[Node2D]:
	return pois_of_kind(PoiScript.KIND_WRECK)


## 11 §3.3's beacon reveal: every POI in the sector becomes visible. A beacon calls
## this through its parent; a probe calls it directly.
func reveal_pois() -> void:
	for poi: Node2D in pois():
		if poi.has_method(&"reveal"):
			poi.call(&"reveal")


## Adds a wreck site a kill just left (06 §4) to this sector, so it is in the blip
## feed and dies with the sector's own repopulation. The site is placed by the caller
## before `setup`, so its payload lands at the kill point.
func add_wreck_site(site: Node2D) -> void:
	if site == null:
		return
	if site.get_parent() != self:
		add_child(site)
	if not _pois.has(site):
		_pois.append(site)
		poi_spawned.emit(site)


## The live NPC hulls this sector spawned (the wiring binds their `died`; a probe counts
## them against §13's band).
func npcs() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for ship: Node2D in _npcs:
		if is_instance_valid(ship):
			out.append(ship)
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
## so the sector only asks a depleted field to respawn. S6's POIs re-arm on the same
## clock (11 §3.1's "one-shot per respawn cycle", §3.2's "respawns on the sector
## clock"): the sector owns the clock and the POI owns no timer (17 §4).
func _respawn_cycle() -> void:
	for field: Node2D in _fields:
		if not is_instance_valid(field):
			continue
		if field.has_method(&"is_depleted") and not bool(field.call(&"is_depleted")):
			continue
		if field.has_method(&"respawn"):
			field.call(&"respawn")
	for poi: Node2D in _pois:
		if not is_instance_valid(poi):
			continue
		if poi.has_method(&"respawn"):
			poi.call(&"respawn", _rng.randi())
	## §8: the sector re-rolls on the same clock, so the hulls go with the fields. A
	## despawn is not a kill (no `died`, no loot, no heat - W3's contract), and the fresh
	## set is re-spawned from the registry's band, so a band that drifted low is refilled.
	for ship: Node2D in npcs():
		if ship.has_method(&"despawn"):
			ship.call(&"despawn")
	_npcs.clear()
	_npc_anchor_index = 0
	_spawn_npcs()


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


func _add_field(field_position: Vector2, tier_weights: Dictionary, densities: Dictionary) -> void:
	var field: Node2D = null
	if _field_script != null:
		field = _field_script.new() as Node2D
	if field == null:
		# W3 has not landed: a bare marker still carries the field's position for
		# the minimap and the plan, and the W7 fixer swaps in the real field.
		field = Node2D.new()
	field.name = "Field%d" % (_fields.size() + 1)
	field.position = field_position
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


## ENGINE_SPEC §8's on-entry set (and §5's spawn model: the sector populates on entry
## and re-rolls on the 20-minute clock): one hull per `NpcRegistry.spawns_for` row,
## rolled inside the row's own per-sector band. The registry owns which archetype, how
## many, whose space it is and which sprite it wears; this method only rolls the band,
## places the hull on a POI and hands over the options bag.
func _spawn_npcs() -> void:
	for spawn: Dictionary in NpcRegistryScript.spawns_for(sector_id()):
		var count := _rng.randi_range(
			int(spawn.get(NpcRegistryScript.KEY_MIN, 0)),
			int(spawn.get(NpcRegistryScript.KEY_MAX, 0))
		)
		for _index in count:
			_add_npc(spawn)


## One hull: the archetype's row drives its behaviour, the resolved `ShipFit` snapshot
## drives its flight law (null is legal - the static rows have no 08 class row, W3's
## report D4) and the registry's swap-ready sprite path dresses it. The hull is added
## before `setup` so its `_ready` build exists when the handshake lands, which is the
## order W3's interface documents.
func _add_npc(spawn: Dictionary) -> void:
	var archetype := StringName(spawn.get(NpcRegistryScript.KEY_ARCHETYPE, &""))
	var hull_id := StringName(spawn.get(NpcRegistryScript.KEY_HULL_ID, &""))
	var anchor := _npc_anchor(spawn)
	var ship: Node2D = NpcShipScript.new()
	ship.name = "Npc%s%d" % [String(archetype).capitalize(), _npcs.size() + 1]
	add_child(ship)
	ship.global_position = anchor
	ship.call(
		&"setup",
		archetype,
		ShipFitScript.resolve(hull_id, ShipFitScript.STANDARD_FIT),
		hull_id,
		{
			NpcShipScript.OPT_HOME: anchor,
			NpcShipScript.OPT_SPACE_OWNER: StringName(
				spawn.get(NpcRegistryScript.KEY_FACTION_ID, &"")
			),
			NpcShipScript.OPT_SPRITE_PATH: String(spawn.get(NpcRegistryScript.KEY_SPRITE_PATH, "")),
		}
	)
	_npcs.append(ship)
	npc_spawned.emit(ship)


## Where a hull is placed. §5 gives each archetype a home and no doc gives a sector a
## spawn radius, so a hull is placed **on an existing POI** rather than on an invented
## offset: a hull hostile to everything "guards asteroid fields/wrecks" and takes the
## next field (round-robin, so a band spreads over the sector's own fields), and a hull
## with the local faction's rules (a patrol) or none (a convoy) takes the station, or the
## arena centre in a sector without one. A hull therefore spawns on top of its POI and two
## hulls of one row share an anchor until the solver separates them; a scatter radius or a
## patrol-route row is the owner's call (reported).
func _npc_anchor(spawn: Dictionary) -> Vector2:
	var hostility := StringName(
		spawn.get(NpcRegistryScript.KEY_HOSTILITY, NpcRegistryScript.HOSTILITY_NONE)
	)
	if hostility != NpcRegistryScript.HOSTILITY_EVERYTHING:
		return _station.global_position if _station != null else Vector2.ZERO
	if _fields.is_empty():
		return _station.global_position if _station != null else Vector2.ZERO
	var guard: Node2D = _fields[_npc_anchor_index % _fields.size()]
	_npc_anchor_index += 1
	return guard.global_position


## §8's minimap class for one hull, read off the hull's own registry row.
func _npc_blip_kind(ship: Node2D) -> StringName:
	if ship.has_method(&"blip_kind"):
		return StringName(ship.call(&"blip_kind"))
	return NpcRegistryScript.BLIP_HOSTILE


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


## S6's travel geometry, off the sector's own registry row: one corridor per
## `corridors` entry and one ring per `gate_links` link (11 §2.1/§2.2, §2.3's spine).
func _spawn_travel(centre: Vector2) -> void:
	for entry: Variant in _row.get(&"corridors", []):
		if entry is Dictionary:
			_add_corridor(entry)
	for dest: Variant in _row.get(&"gate_links", []):
		_add_gate(centre, int(dest))


func _add_corridor(entry: Dictionary) -> void:
	var dest := int(entry.get(&"dest", 0))
	var band: Rect2 = entry.get(&"edge_rect", Rect2())
	var corridor: Node2D = CorridorScript.new() as Node2D
	corridor.name = "Corridor%d" % dest
	add_child(corridor)
	corridor.call(&"setup", dest, band)
	_corridors.append(corridor)


func _add_gate(centre: Vector2, dest: int) -> void:
	var gate: Node2D = GateScript.new() as Node2D
	gate.name = "Gate%d" % dest
	gate.position = centre + _gate_bearing(dest) * GATE_RING_RADIUS
	add_child(gate)
	gate.call(&"setup", dest)
	gate.call(&"set_origin_sector", Registry.sector_number(sector_id()))
	_gates.append(gate)


## S6's POIs, off the plan the same `populate` just built: one derelict per wreck
## field, the rolled 1-2 anomalies, and one beacon per corridor plus one per gate
## (11 §3's density table). Derelicts and anomalies share an even-slot ring at a half
## step from the fields' own slots, so the two sets interleave instead of stacking;
## beacons sit on the travel geometry they mark.
func _spawn_pois(centre: Vector2) -> void:
	var derelict_count := int(_plan.get(&"derelicts", 0))
	var anomaly_count := int(_plan.get(&"anomalies", 0))
	var total := derelict_count + anomaly_count
	var index := 0
	for _slot in derelict_count:
		_add_poi(PoiScript.KIND_DERELICT, _poi_position(centre, index, total))
		index += 1
	for _slot in anomaly_count:
		_add_poi(PoiScript.KIND_ANOMALY, _poi_position(centre, index, total))
		index += 1
	for gate: Node2D in _gates:
		if not is_instance_valid(gate):
			continue
		var bearing := gate.position.normalized()
		_add_poi(PoiScript.KIND_BEACON, gate.position + bearing * BEACON_GATE_OFFSET)
	for corridor: Node2D in _corridors:
		if not is_instance_valid(corridor):
			continue
		var band: Rect2 = corridor.get(&"edge")
		_add_poi(PoiScript.KIND_BEACON, band.get_center())


## One POI node, positioned, given the sector it stands in and a fresh roll seed.
func _add_poi(poi_kind: StringName, poi_position: Vector2) -> Node2D:
	var poi: Node2D = PoiScript.new() as Node2D
	poi.name = "Poi%s%d" % [String(poi_kind).capitalize(), _pois.size() + 1]
	poi.position = poi_position
	add_child(poi)
	poi.call(&"setup", poi_kind, {&"sector_id": sector_id(), &"seed": _rng.randi()})
	_pois.append(poi)
	poi_spawned.emit(poi)
	return poi


## An even angular slot at a jittered radius, a half step off the fields' own slots
## (the field placement's rule, `_spawn_fields`), inside the same clearance ring so a
## POI never crowds the station or the spawn point.
func _poi_position(centre: Vector2, index: int, total: int) -> Vector2:
	var half := minf(Registry.SECTOR_SIZE.x, Registry.SECTOR_SIZE.y) * 0.5
	var inner := FIELD_STATION_CLEARANCE
	var outer := half - FIELD_EDGE_MARGIN
	if outer <= inner:
		outer = inner + 1.0
	var step := TAU / float(maxi(total, 1))
	var angle := step * (float(index) + 0.5)
	angle += _rng.randf_range(-FIELD_SLOT_JITTER, FIELD_SLOT_JITTER)
	var radius := _rng.randf_range(inner, outer)
	return centre + Vector2.RIGHT.rotated(angle) * radius


## The bearing a gate to `dest` stands on: the direction of the destination's own map
## edge (the corridor band's centre, read off the row), so the ring reads as "toward the
## link". Falls back to the east edge for a destination the row does not name.
func _gate_bearing(dest: int) -> Vector2:
	for entry: Variant in _row.get(&"corridors", []):
		if not entry is Dictionary:
			continue
		var record: Dictionary = entry
		if int(record.get(&"dest", 0)) != dest:
			continue
		var band: Rect2 = record.get(&"edge_rect", Rect2())
		var edge_centre := band.get_center()
		if edge_centre.length() > 0.0:
			return edge_centre.normalized()
	return Vector2.RIGHT


## Re-populating a sector (a transition) drops the previous contents immediately:
## `free()` rather than `queue_free()`, so a probe or a transition can measure the
## fresh set in the same frame.
func _clear() -> void:
	_fields.clear()
	_npcs.clear()
	_gates.clear()
	_corridors.clear()
	_pois.clear()
	_npc_anchor_index = 0
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
