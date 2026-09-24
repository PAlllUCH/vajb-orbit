@tool
extends McpTestSuite
## Suite engine2_wiring: slice 2 W5's wiring — the sector's NPC population (ENGINE_SPEC
## section 8), the target window and the hit marker (section 10 / section 4.2 item 4), the
## launch snapshot's pool seeding (sections 4.2 item 2 and 4.3) and the warp gate
## (section 7).
##
## One `game.tscn` and one throwaway `Sector` are built once, in `suite_setup`, and freed in
## `suite_teardown`: `headless_runner.gd` calls `setup`/`teardown` per test but never the
## base class's `_free_tracked`, and a scene with a sector holds hundreds of bodies. Each
## test starts from a cleared targeting state (`setup`), so nothing leaks between them.
##
## No frame is awaited: everything asserted here is a synchronous reading (the counts, the
## blip classes, the anchors, the payload the HUD holds). The frame-stepped behaviour — the
## 1.2 s channel, the rock's block, the regen window, the death drop — is the W5 probe's
## (`.agents/gen/slice2_w5_probe.txt`).

const GameScene := preload("res://game/game.tscn")
const SectorScript := preload("res://game/sector.gd")
const Registry := preload("res://game/sector_registry.gd")
const NpcRegistryScript := preload("res://game/npc_registry.gd")
const NpcShipScript := preload("res://game/npc_ship.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const DamageScript := preload("res://game/damage.gd")
const PlayerShipScript := preload("res://game/player_ship.gd")
const WeaponScript := preload("res://game/weapons.gd")

const GAME_SCENE := "res://game/game.tscn"
const SEED := 20260921
const SECTORS: Array[StringName] = [&"sector_1", &"sector_4", &"sector_7"]

var _scene: Node2D = null
var _sector: Node2D = null
var _ship: Node2D = null
var _state: Variant = null
var _hud: Control = null
var _guns: Node2D = null
var _staged: Array[Node2D] = []


func suite_name() -> String:
	return "engine2_wiring"


func suite_setup(_ctx: Dictionary) -> void:
	_sector = SectorScript.new()
	_sector.name = &"SuiteSector"
	## The sector's own contents are built with `add_child` on this node, which needs no
	## parent and no tree at all: the population, the anchors and the blips are all
	## synchronous readings off an unparented sector.
	var packed := load(GAME_SCENE) as PackedScene
	if packed == null:
		fail_setup("game.tscn did not load")
		return
	_scene = packed.instantiate() as Node2D
	if _scene == null:
		fail_setup("game.tscn did not instantiate")
		return
	_fixture_host().add_child(_scene)
	_ship = _scene.get_node_or_null(NodePath("PlayerShip")) as Node2D
	_hud = _scene.get_node_or_null(NodePath("Hud")) as Control
	_state = _scene.get(&"_state")
	if _ship == null or _hud == null or _state == null:
		fail_setup("the game scene did not build its ship, HUD and state")
		return
	_guns = _ship.get_node_or_null(NodePath(PlayerShipScript.WEAPONS_NODE)) as Node2D


func suite_teardown() -> void:
	for hull: Node2D in _staged:
		if is_instance_valid(hull):
			hull.free()
	_staged.clear()
	if _scene != null and is_instance_valid(_scene):
		_scene.free()
	_scene = null
	if _sector != null and is_instance_valid(_sector):
		_sector.free()
	_sector = null


## Where the scene may enter the tree. The runner calls every test from inside its own
## `_ready`, and the root viewport is still busy adding the runner scene at that moment, so
## `root.add_child(...)` fails with "Parent node is busy setting up children" (measured).
## The profile autoload entered the tree before the main scene and takes children all
## through the run; `game.gd` resolves the profile from the tree root, not from its parent,
## so nothing in the scene depends on where it hangs.
func _fixture_host() -> Node:
	var root := _tree().root
	var host := root.get_node_or_null(NodePath(&"PlayerProfile"))
	return host if host != null else root


func setup() -> void:
	if _scene != null:
		_scene.call(&"_cancel_lock")


func teardown() -> void:
	for hull: Node2D in _staged:
		if is_instance_valid(hull):
			hull.free()
	_staged.clear()


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## One row of the sector registry, resolved by id.
func _row(sector_id: StringName) -> Dictionary:
	for row: Dictionary in Registry.SECTORS:
		if StringName(row.get(&"id", &"")) == sector_id:
			return row
	return {}


## A real NPC hull of the shipped registry, placed by hand next to the player.
func _spawn_hull(position: Vector2) -> Node2D:
	var hull: Node2D = NpcShipScript.new()
	hull.name = "SuitePirate"
	_scene.add_child(hull)
	hull.global_position = position
	hull.call(
		&"setup",
		&"pirate",
		ShipFitScript.resolve(&"ship_fighter", ShipFitScript.STANDARD_FIT),
		&"ship_fighter",
		{&"home": position, &"space_owner": &"concord"}
	)
	_staged.append(hull)
	return hull


## ---------------------------------------------------------------------------
## Section 8: the on-entry population
## ---------------------------------------------------------------------------


func test_a_sector_spawns_every_archetype_inside_its_registry_band() -> void:
	for index in SECTORS.size():
		var sector_id: StringName = SECTORS[index]
		_sector.call(&"populate", _row(sector_id), SEED + index)
		var counts := _archetype_counts()
		var expected := _expected_counts(sector_id)
		for archetype: Variant in expected:
			var span: Vector2i = expected[archetype]
			var live := int(counts.get(archetype, 0))
			assert_true(
				live >= span.x and live <= span.y,
				"%s: %s live %d outside %s" % [sector_id, archetype, live, span]
			)
		var hostiles := (
			int(counts.get(&"pirate", 0))
			+ int(counts.get(&"swarmer", 0))
			+ int(counts.get(&"patrol", 0))
		)
		## Section 13's band is the pirate + swarmer total; the patrol's own count comes from
		## the registry's patrol row (one per owned sector, none in unaligned space).
		var patrol: Vector2i = expected.get(&"patrol", Vector2i.ZERO)
		var band: Vector2i = NpcRegistryScript.HOSTILE_BAND[
			NpcRegistryScript.sector_index(sector_id)
		]
		var least := band.x + patrol.x
		var most := band.y + patrol.y
		assert_true(
			hostiles >= least and hostiles <= most,
			"%s: %d hostiles outside section 13's %d..%d" % [sector_id, hostiles, least, most]
		)


func test_the_two_state_band_only_spawns_in_owned_space() -> void:
	_sector.call(&"populate", _row(&"sector_7"), SEED)
	var counts := _archetype_counts()
	assert_eq(int(counts.get(&"patrol", 0)), 0, "S7 is nobody's, so no patrol")
	assert_eq(int(counts.get(&"trader", 0)), 0, "and no convoy in an uninhabited sector")
	_sector.call(&"populate", _row(&"sector_1"), SEED)
	counts = _archetype_counts()
	assert_eq(int(counts.get(&"patrol", 0)), 1, "an owned sector is patrolled")
	assert_true(int(counts.get(&"trader", 0)) >= 1, "and runs its convoy")


func test_every_hull_publishes_section_eights_blip_class() -> void:
	_sector.call(&"populate", _row(&"sector_4"), SEED)
	var hostiles := 0
	var neutrals := 0
	for ship: Node2D in _sector.call(&"npcs"):
		var archetype := StringName(ship.call(&"archetype"))
		var kind := StringName(ship.call(&"blip_kind"))
		if archetype == &"trader":
			assert_eq(kind, NpcRegistryScript.BLIP_NEUTRAL, "a convoy blips neutral")
			neutrals += 1
		else:
			assert_eq(kind, NpcRegistryScript.BLIP_HOSTILE, "%s blips hostile" % archetype)
			hostiles += 1
	assert_true(hostiles + neutrals > 0, "the sector spawned something to class")


func test_the_minimap_feed_carries_every_hull_plus_the_pois() -> void:
	_sector.call(&"populate", _row(&"sector_4"), SEED)
	var blips: Array[Dictionary] = _sector.call(&"blips")
	var kinds := {}
	for blip: Dictionary in blips:
		var kind := StringName(blip.get("kind", &""))
		kinds[kind] = int(kinds.get(kind, 0)) + 1
	var hulls: Array = _sector.call(&"npcs")
	var hostiles := 0
	for ship: Node2D in hulls:
		if StringName(ship.call(&"blip_kind")) == NpcRegistryScript.BLIP_HOSTILE:
			hostiles += 1
	## S6 (CONTRACTS section 19, 11 section 5): the sector's gate rings and nav beacons
	## blip `friendly` and always appear, so the feed is one per hull, one per field, one
	## per gate, one per beacon and one for the station. The expectation is derived from
	## the sector's own counts, so a sector with one link and one with two both hold, and
	## K2's fogged derelict/anomaly blips (they need a scan) do not enter it.
	var gates: int = (_sector.call(&"gates") as Array).size()
	var beacons: int = (_sector.call(&"beacons") as Array).size()
	assert_eq(
		blips.size(),
		hulls.size() + (_sector.call(&"fields") as Array).size() + gates + beacons + 1,
		"one blip per hull, one per field, one per gate, one per beacon and the station"
	)
	assert_eq(
		int(kinds.get(&"hostile", 0)), hostiles, "every hostile hull shows hostile"
	)
	assert_eq(
		int(kinds.get(&"friendly", 0)),
		gates + beacons + 1,
		"the station, every gate ring and every nav beacon are the friendly blips"
	)
	assert_true(hostiles >= 1, "and the sector has hostiles to show")


func test_every_hull_is_anchored_on_a_poi() -> void:
	_sector.call(&"populate", _row(&"sector_1"), SEED)
	var station: Vector2 = _sector.call(&"station_position")
	var fields: Array = _sector.call(&"fields")
	var anchors := []
	for field: Node2D in fields:
		anchors.append(field.global_position)
	for ship: Node2D in _sector.call(&"npcs"):
		var home: Vector2 = ship.call(&"home")
		var archetype := StringName(ship.call(&"archetype"))
		if archetype == &"pirate" or archetype == &"swarmer":
			assert_true(anchors.has(home), "a field guard anchors on a field, not a new point")
		else:
			assert_eq(home, station, "%s anchors on the station" % archetype)


## ---------------------------------------------------------------------------
## The scene's slice-2 wiring
## ---------------------------------------------------------------------------


func test_the_ship_mounts_its_weapons_component() -> void:
	assert_true(_guns != null, "the standard fit's w_laser mounted a WeaponComponent")
	assert_eq(int(_guns.call(&"selected_group")), 1, "group 1 is the selected one")
	## The mounted barrels are read off the launched fit rather than named, so the
	## assertion holds for whatever the launch mounts (the sandboxed default account flies
	## the hull's standard fit) and the family-less tools - `w_mining` maps to `&""` - drop
	## out exactly as `WeaponComponent.set_fitted` drops them.
	##
	## **Per barrel, duplicates kept** (CONTRACTS section 16 rule 1): `_state.weapons` is
	## one slot per fitted W cell, and the component keeps one entry per barrel of the fit,
	## so a Lancer's `[w_laser, w_laser]` mounts two barrels here and not one. The old
	## reading de-duplicated both sides and would have stayed green through the change.
	var launched: Array[StringName] = []
	for weapon_id: StringName in _state.weapons:
		var family := WeaponScript.weapon_id(weapon_id)
		if family != &"":
			launched.append(family)
	assert_true(not launched.is_empty(), "the launched fit mounts at least one firing barrel")
	assert_eq(_guns.call(&"fitted"), launched, "and it mounts the launched fit's own barrels")
	## ... and one battery per distinct family, in first-barrel order (rule 2). On this
	## one-family fit the two readings coincide, which is what keeps every group test green.
	var batteries: Array[StringName] = []
	for family: StringName in launched:
		if not batteries.has(family):
			batteries.append(family)
	assert_eq(_guns.call(&"battery_ids"), batteries, "addressed as one battery per family")
	## The per-barrel reading has to **bite**: on the default one-laser hull both readings
	## agree, so the mounted component is asked for a doubled barrel directly and the
	## launched fit put back before the suite's other tests read it.
	var doubled: Array[StringName] = [launched[0], launched[0]]
	_guns.call(&"set_fitted", doubled)
	assert_eq(_guns.call(&"fitted"), doubled, "two barrels of one family mount as two")
	assert_eq((_guns.call(&"battery_ids") as Array).size(), 1, "and read as one battery")
	assert_eq(_guns.call(&"battery", launched[0]), [0, 1], "the battery holds both positions")
	_guns.call(&"set_fitted", launched)
	assert_eq(_guns.call(&"fitted"), launched, "then the launched fit is put back")


func test_the_launch_snapshot_seeds_the_pools_and_the_shield_rate() -> void:
	var stats: Variant = _scene.get(&"_stats")
	assert_true(stats != null, "the scene resolved a launch snapshot")
	assert_eq(_state.hull_max, stats.hull_max, "hull maximum")
	assert_eq(_state.shield_max, stats.shield_max, "shield maximum")
	assert_eq(_state.energy_max, stats.energy_max, "energy pool")
	assert_eq(_state.fuel_max, stats.fuel_max, "fuel pool")
	assert_eq(_state.shield_regen, stats.shield_regen, "the shield's own rate (section 4.2 item 2)")
	assert_eq(_state.shield_regen, 6.0, "base 2/s plus s_light's 4")


func test_the_ammo_packs_are_seeded_from_the_profile() -> void:
	var profile := _tree().root.get_node_or_null(NodePath(&"PlayerProfile"))
	assert_true(profile != null, "the profile autoload is there")
	## P2-A (CONTRACTS section 11): the live slots are the launched fit's own W cells,
	## not the five fixed families, so the loop reads `weapons` - and `ammo` is exactly
	## that long, which the array assertion keeps non-vacuous for a fit with no guns.
	assert_eq(_state.ammo.size(), _state.weapons.size(), "one pack per launched weapon slot")
	for slot in _state.weapons.size():
		var weapon_id: StringName = _state.weapons[slot]
		assert_eq(
			_state.ammo[slot],
			int(profile.call(&"ammo_of", weapon_id)),
			"%s's pack follows the profile's store" % weapon_id
		)


func test_the_pools_and_the_dial_reach_the_hud() -> void:
	_scene.call(&"_refresh_hud")
	var currents: Dictionary = _hud.get(&"_pool_current")
	assert_eq(float(currents.get(&"energy", -1.0)), _state.energy, "the Energy bar's reading")
	assert_eq(float(currents.get(&"fuel", -1.0)), _state.fuel, "the Fuel bar's reading")
	_scene.call(&"_push_speedometer")
	assert_eq(float(_hud.call(&"speedometer_ratio")), 0.0, "a hull at rest reads zero")


func test_the_warp_gate_opens_in_a_quiet_sector() -> void:
	_scene.call(&"_refresh_hud")
	assert_false(bool(_scene.call(&"_enemy_engaged")), "no hostile is engaged at launch")
	assert_true(bool(_ship.call(&"warp_available")), "and the hull is warp-quiet")
	assert_true(bool(_scene.call(&"_warp_ready")), "so the gate offers the jump")


func test_the_reticle_reads_plain_over_empty_space() -> void:
	assert_eq(
		int(_scene.call(&"_reticle_state_for", _ship.global_position + Vector2(9000.0, 0.0))),
		TargetReticle.State.PLAIN,
		"nothing under the point, no laser firing: plain"
	)


func test_a_npc_hull_answers_the_hostility_the_targeting_reads() -> void:
	var hull := _spawn_hull(_ship.global_position + Vector2(300.0, 0.0))
	assert_true(bool(_scene.call(&"_is_hostile", hull)), "a pirate is a hostile signature")
	assert_eq(
		StringName(hull.call(&"blip_kind")), NpcRegistryScript.BLIP_HOSTILE, "section 8's class"
	)
	assert_false(bool(_scene.call(&"_is_hostile", _ship)), "the player's hull is not")


## The target window: a marked hull fills the payload (name from 08 section 2's hull row,
## the range state from the selected weapon) and a pool drop between two pushes is the
## confirmed hit that flashes the marker (section 4.2 item 4).
func test_a_marked_hostile_fills_the_window_and_a_hit_flashes_the_marker() -> void:
	var hull := _spawn_hull(_ship.global_position + Vector2(300.0, 0.0))
	_scene.call(&"_start_lock", hull)
	_scene.call(&"_push_target")
	var info: Dictionary = _hud.call(&"target_info")
	assert_eq(String(info.get("name", "")), "Lancer", "08 section 2's hull name")
	assert_eq(String(info.get("threat", "")), "HOSTILE", "the threat reading")
	assert_true(bool(info.get("in_range")), "300 u is inside the laser's 500 u")
	assert_true(float(info.get("distance_m", 0.0)) > 290.0, "and the distance is measured")
	assert_true(bool(_hud.get(&"_reticle").get(&"_has_target")), "the reticle marks the hull")

	var marker: Control = _hud.call(&"hit_marker_node")
	assert_false(marker.visible, "nothing has hit yet")
	DamageScript.apply(hull, 25.0, false, {})
	_scene.call(&"_push_target")
	assert_true(marker.visible, "a pool drop between two pushes is a confirmed hit")


## ---------------------------------------------------------------------------
## Helpers
## ---------------------------------------------------------------------------


func _archetype_counts() -> Dictionary:
	var counts := {}
	for ship: Node2D in _sector.call(&"npcs"):
		var archetype := StringName(ship.call(&"archetype"))
		counts[archetype] = int(counts.get(archetype, 0)) + 1
	return counts


## The registry's own expanded band for one sector: a convoy row is two entries, so its
## counts add up rather than standing alone.
func _expected_counts(sector_id: StringName) -> Dictionary:
	var expected := {}
	for entry: Dictionary in NpcRegistryScript.spawns_for(sector_id):
		var archetype := StringName(entry[NpcRegistryScript.KEY_ARCHETYPE])
		var span: Vector2i = expected.get(archetype, Vector2i.ZERO)
		expected[archetype] = Vector2i(
			span.x + int(entry[NpcRegistryScript.KEY_MIN]),
			span.y + int(entry[NpcRegistryScript.KEY_MAX])
		)
	return expected
