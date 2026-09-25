@tool
extends McpTestSuite
## Suite d11_station: wave D11's composed station scene (ENVIRONMENT_SPEC §11,
## CONTRACTS §21 O6 — "bigger with more details, not a single sprite"). AC3:
## the composed tree draws, the `&"station"` group survives, the DockZone keeps
## its world-unit radius as a sibling, and the S6 dock/blip seams answer.
## AC4: a two-frame motion probe under the named constants, and a
## reversal-valued constant standing still. Today's pins: STATION_SCALE 0.0663
## (sector.gd), footprint half 67.9 u; the hero pin is 0.0663 x 2.2 = 0.1459.

const SectorScript := preload("res://game/sector.gd")
const StationSceneScript := preload("res://game/station_scene.gd")
const HeroTexture := preload("res://assets/env/poi/env_station_hero.png")

const CENTRE := Vector2(420.0, -260.0)
const TODAY_SCALE := 0.0663
const HERO_FLOOR := 2.2

var _bare: Array[Node] = []


func setup() -> void:
	_bare.clear()


func teardown() -> void:
	for node: Node in _bare:
		if is_instance_valid(node):
			node.free()
	_bare.clear()


func _spawned_station() -> Node2D:
	var sector: Node2D = SectorScript.new() as Node2D
	_bare.append(sector)
	sector.call(&"_spawn_station", CENTRE)
	return sector


## AC3: the composed tree draws — hero + every element present, the hero scale
## is the approved pin read from the scene, and there is no bare single-sprite
## path (the root has the whole set, not one sprite).
func test_station_draws_composed_not_one_sprite() -> void:
	var scene: Node2D = StationSceneScript.new() as Node2D
	_bare.append(scene)
	var elements: Array[Dictionary] = scene.call(&"approved_elements")
	scene.call(&"setup", HeroTexture, elements)
	assert_true(elements.size() >= 19, "the approved set is hero-scale composed, not one sprite")
	assert_true(scene.get_child_count() > elements.size(), "hero plus every element draw")
	assert_true(
		absf(StationSceneScript.HERO_SCALE - TODAY_SCALE * HERO_FLOOR) < 0.001,
		"the hero pin reads the approved 0.0663 x 2.2 from the scene"
	)
	var hero: Sprite2D = scene.get_node_or_null(^"Hero") as Sprite2D
	assert_true(hero != null, "the hero sprite exists")
	if hero != null:
		assert_eq(hero.scale, Vector2(0.1459, 0.1459), "hero scale == the approved pin")
	assert_true(scene.is_in_group(&"station"), "the scene root keeps the &station group")


## AC3: the swap's invariants in sector — placement centre unchanged, the group
## survives on the composed node, and the DockZone is a SIBLING whose circle
## radius still reads in world units (120, sector.gd's DOCK_RING_RADIUS).
func test_spawn_swap_keeps_centre_group_and_dock_radius() -> void:
	var sector := _spawned_station()
	assert_true(sector.call(&"has_station"), "the sector has a station")
	assert_eq(sector.call(&"station_position"), CENTRE, "placement centre unchanged")
	var station: Node2D = sector.get_node_or_null(^"Station") as Node2D
	assert_true(station != null, "the composed node is named Station")
	if station != null:
		assert_true(station.is_in_group(&"station"), "group survives the swap")
		assert_eq(station.get_parent(), sector, "the station is a sector child")
	var dock: Node2D = sector.get_node_or_null(^"DockZone") as Node2D
	assert_true(dock != null, "DockZone exists")
	if dock != null:
		assert_eq(dock.get_parent(), sector, "DockZone stays a SIBLING, not a scaled child")
		assert_eq(dock.global_scale, Vector2.ONE, "DockZone is not under art scale")
		for child: Node in dock.get_children():
			var shape := child as CollisionShape2D
			if shape != null and shape.shape is CircleShape2D:
				assert_eq((shape.shape as CircleShape2D).radius, 120.0,
					"radius reads 120 in world units as before")


## The S6 seams still answer byte-identically: dock_zone_contains is the same
## geometric test around the station centre, and blips() still carries the
## station as one friendly row.
func test_s6_dock_and_blip_seams_still_answer() -> void:
	var sector := _spawned_station()
	assert_true(sector.call(&"dock_zone_contains", CENTRE + Vector2(0.0, 119.0)),
		"inside the ring docks")
	assert_false(sector.call(&"dock_zone_contains", CENTRE + Vector2(0.0, 121.0)),
		"outside the ring does not")
	var blips: Array = sector.call(&"blips")
	assert_eq(blips.size(), 1, "one blip for one station")
	assert_eq(blips[0].get("pos"), CENTRE, "the blip sits at the centre")
	assert_eq(blips[0].get("kind"), &"friendly", "the station blips friendly")


## AC4: a two-frame motion probe — under the named constants the shuttles move,
## the crane slews and the strobe chase advances between two sampled frames.
func test_motion_two_frames_under_the_constants() -> void:
	var scene: Node2D = StationSceneScript.new() as Node2D
	_bare.append(scene)
	scene.call(&"setup", HeroTexture, scene.call(&"approved_elements"))
	var shuttle: Node2D = scene.get_node_or_null(^"ShuttleA") as Node2D
	var pivot: Node2D = scene.get_node_or_null(^"SlewPivot") as Node2D
	assert_true(shuttle != null and pivot != null, "moving elements exist")
	if shuttle == null or pivot == null:
		return
	var before_pos := shuttle.position
	var before_rot := pivot.rotation_degrees
	var before_lit := StationSceneScript.strobe_lit(0.0,
		StationSceneScript.STROBE_PERIOD, 5)
	scene.call(&"step_motion", 1.3)
	assert_ne(shuttle.position, before_pos, "the shuttle moves between frames")
	assert_ne(pivot.rotation_degrees, before_rot, "the crane slews between frames")
	assert_ne(StationSceneScript.strobe_lit(1.3,
		StationSceneScript.STROBE_PERIOD, 5), before_lit, "the strobe chase advances")


## AC4: a reversal-valued constant stands still — 0.0 freezes each motion rule.
func test_reversal_valued_constants_stand_still() -> void:
	var s0 := StationSceneScript.shuttle_s(0.0, 0.0, 0.25)
	assert_eq(StationSceneScript.shuttle_s(9.5, 0.0, 0.25), s0,
		"a zero shuttle speed parks the shuttle")
	assert_eq(StationSceneScript.slew_deg(9.5, 0.0), 0.0,
		"a zero slew rate parks the crane at rest")
	for t: float in [0.0, 1.3, 7.7]:
		assert_eq(StationSceneScript.strobe_lit(t, 0.0, 5), 0,
			"a zero strobe period freezes the chase on dot 0")
