@tool
extends McpTestSuite
## Suite engine2_fixes: the W7 fixer pass of engine slice 2 (fight).
##
## One section per finding of `.agents/gen/slice2_review_report.md` that this pass fixes:
##
## - **F1** a shot's damage must reach the ship, not the hull's own `HullBody` collider
##   (`game/weapons.gd` / `game/projectile.gd`, ENGINE_SPEC section 4.1).
## - **F2** `PlayerProfile.set_ammo` — the dock's pack report needs an absolute writer
##   (18_engine_spec section 4.3 / 01 section 6).
## - **F4** the minimap's `&"ghost"` flicker and `&"swarmer"` sub-kind
##   (ENGINE_SPEC section 10, UI_SPEC sections 3.3 and 4.6).
##
## Nothing here awaits a frame: every reading is synchronous off a shipped seam, which is
## what keeps the gate deterministic. The frame-stepped half of F1 (a held laser on a real
## hull, a released bolt crossing 300 u) is the W7 probe's, measured the way the reviewer
## measured it (`.agents/gen/slice2_w7_probe.txt`).
##
## The dock filing test borrows the shipped `PlayerProfile` autoload for the length of one
## test (it redirects `save_path` at a scratch file and flushes before handing it back),
## never mutating what it does not restore, so the owner's `user://profile.cfg` is never
## written - measured by md5 across the run.

const WeaponsScript := preload("res://game/weapons.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const PlayerShipScript := preload("res://game/player_ship.gd")
const PlayerShipScene := preload("res://game/player_ship.tscn")
const PlayerStateScript := preload("res://game/player_state.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const NpcShipScript := preload("res://game/npc_ship.gd")
const NpcRegistryScript := preload("res://game/npc_registry.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")
const MinimapScript := preload("res://ui/hud/minimap.gd")
const Log := preload("res://game/economy_log.gd")
const GameScene := preload("res://game/game.tscn")
const HudTheme := preload("res://ui/theme/vajb_theme.tres")

const HULL: StringName = &"ship_vanguard"
const GAME_SCENE := "res://game/game.tscn"
const SCRATCH_PROFILE := "user://test_engine2_fixes.cfg"
const SCRATCH_LOG := "user://test_engine2_fixes_log.txt"

## The dock filing test's own fit (CONTRACTS section 14): the laser it fires and the cannon
## it leaves alone must both be mounted whatever the account holds - the live Vanguard fit is
## `["w_mining", "w_cannon", ""]`, which mounts no laser at all (F11) - so the store's fit
## for the active hull is replaced before `game.tscn` is instantiated and put back in
## `suite_teardown`, both flushes landing on the harness's own scratch `save_path`
## (`headless_runner.gd:_seed_scratch_store`).
const FIXTURE_FIT: Dictionary = {
	&"engines": [&"e_std"],
	&"power": &"p_std",
	&"weapons": [&"w_laser", &"w_cannon"],
	&"shields": [&"s_light"],
	&"armour": [&"h_plate_light"],
}

## The reviewers' own alpha extremes for section 3.3's flicker: a sine at 6 Hz reaches
## 0.7 a quarter period in and 0.3 three quarters in, so these are the two instants the
## curve must hit, not invented numbers.
const FLICKER_PEAK_AT: float = 1.0 / 24.0
const FLICKER_TROUGH_AT: float = 3.0 / 24.0
const FLICKER_PERIOD: float = 1.0 / 6.0

var _shooter: Node2D = null
var _shooter_state: Variant = null
var _victim: Node2D = null
var _victim_state: Variant = null
var _guns: Node2D = null
var _minimap: Control = null
var _scene: Node2D = null
var _state: Variant = null
var _staged: Array[Node] = []
var _profiles: Array[Node] = []
var _signals: Array[StringName] = []
var _previous_fits: Dictionary = {}


func suite_name() -> String:
	return "engine2_fixes"


func suite_setup(_ctx: Dictionary) -> void:
	_stage_fixture_fit()
	var host := _fixture_host()
	var pair := _build_ship(host, Vector2(-400.0, 0.0))
	_shooter = pair[0]
	_shooter_state = pair[1]
	pair = _build_ship(host, Vector2(400.0, 0.0))
	_victim = pair[0]
	_victim_state = pair[1]
	if _shooter == null or _victim == null:
		fail_setup("the player-ship fixture did not build")
		return
	_guns = _shooter.get_node_or_null(NodePath(PlayerShipScript.WEAPONS_NODE)) as Node2D
	if _guns == null:
		fail_setup("PlayerShip mounted no WeaponComponent")
		return
	_minimap = MinimapScript.new() as Control
	if _minimap == null:
		fail_setup("the minimap did not instantiate")
		return
	_minimap.name = &"SuiteMinimap"
	_minimap.theme = HudTheme
	_minimap.size = Vector2(200.0, 200.0)
	host.add_child(_minimap)
	var packed := load(GAME_SCENE) as PackedScene
	if packed == null:
		fail_setup("game.tscn did not load")
		return
	_scene = packed.instantiate() as Node2D
	if _scene == null:
		fail_setup("game.tscn did not instantiate")
		return
	host.add_child(_scene)
	_state = _scene.get(&"_state")
	if _state == null:
		fail_setup("game.tscn did not build its state")
		return


func suite_teardown() -> void:
	_clear_staged()
	for profile: Node in _profiles:
		if is_instance_valid(profile):
			profile.free()
	_profiles.clear()
	if _minimap != null and is_instance_valid(_minimap):
		_minimap.free()
	_minimap = null
	if _scene != null and is_instance_valid(_scene):
		_scene.free()
	_scene = null
	_state = null
	for ship: Node2D in [_shooter, _victim]:
		if ship != null and is_instance_valid(ship):
			ship.free()
	_shooter = null
	_victim = null
	_guns = null
	_delete_file(SCRATCH_PROFILE)
	_delete_file(SCRATCH_LOG)
	Log.log_path = Log.DEFAULT_PATH
	_restore_fits()


## The fixture's own fit, written before the scene is instantiated (`set_fit` is the store's
## plain per-hull setter) and reversed in `suite_teardown`, so the account ends this suite
## exactly as it started.
func _stage_fixture_fit() -> void:
	var profile: Node = _tree().root.get_node_or_null(NodePath(&"PlayerProfile"))
	if profile == null:
		return
	_previous_fits = profile.call(&"fits")
	profile.call(&"set_fit", StringName(profile.call(&"active_ship")), FIXTURE_FIT)
	profile.call(&"flush")


func _restore_fits() -> void:
	var profile: Node = _tree().root.get_node_or_null(NodePath(&"PlayerProfile"))
	if profile == null:
		return
	profile.call(&"set_fits", _previous_fits)
	profile.call(&"flush")
	_previous_fits = {}


## Each test opens on a full victim and a charged shooter, so the deltas below are the
## test's own and never a previous test's residue.
func setup() -> void:
	_signals.clear()
	if _victim_state != null:
		_victim_state.set_hull(_victim_state.hull_max)
		_victim_state.set_shield(_victim_state.shield_max)
	if _shooter_state != null:
		_shooter_state.set_hull(_shooter_state.hull_max)
		_shooter_state.set_shield(_shooter_state.shield_max)
		_shooter_state.set_energy(_shooter_state.energy_max)


func teardown() -> void:
	_clear_staged()
	_signals.clear()


## ---------------------------------------------------------------------------
## Shared fixtures
## ---------------------------------------------------------------------------


## Where a fixture may enter the tree. The runner calls every test from inside its own
## `_ready`, and the root viewport is still busy adding the runner scene at that moment,
## so `root.add_child(...)` fails with "Parent node is busy setting up children"
## (measured, `test_engine2_hud.gd`). The profile autoload entered the tree before the
## main scene and takes children all through the run.
func _fixture_host() -> Node:
	var root := _tree().root
	var host := root.get_node_or_null(NodePath(&"PlayerProfile"))
	return host if host != null else root


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## One launched hull: the same fixture the W6 probe builds (the resolved standard fit, a
## throwaway `PlayerState` seeded from it, then the shipped `PlayerShip.setup`).
func _build_ship(host: Node, at: Vector2) -> Array:
	var stats := ShipFitScript.resolve(HULL, ShipFitScript.STANDARD_FIT)
	var state := PlayerStateScript.new()
	state.hull_max = stats.hull_max
	state.shield_max = stats.shield_max
	state.cargo_max = stats.cargo_max
	state.energy_max = stats.energy_max
	state.energy_regen = stats.energy_regen
	state.fuel_max = stats.fuel_max
	state.shield_regen = stats.shield_regen
	state.setup()
	var ship := PlayerShipScene.instantiate() as PlayerShipScript
	if ship == null:
		return [null, state]
	host.add_child(ship)
	ship.global_position = at
	ship.setup(stats, state, ShipFitScript.fitted_ids(ShipFitScript.STANDARD_FIT))
	return [ship, state]


## The collider a shot actually touches: the hull's own `HullBody`.
func _hull_body(ship: Node) -> Node:
	return ship.get_node_or_null(NodePath(PlayerShipScript.HULL_BODY_NODE))


## A fresh shot of the shipped family row, parented so its own `queue_free` has a tree
## to land in.
func _build_shot(config: Dictionary) -> Node2D:
	var shot: Node2D = ProjectileScript.new()
	_fixture_host().add_child(shot)
	shot.call(&"configure", config)
	_staged.append(shot)
	return shot


## A fixture that the code under test has already spent (`_consume` / `_detonate` queue
## their own free) is left to the engine's delete queue rather than freed twice.
func _clear_staged() -> void:
	for node: Node in _staged:
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			node.free()
	_staged.clear()


func _near(measured: float, expected: float, tolerance: float) -> bool:
	return absf(measured - expected) <= tolerance


## Every pickup in the tree, whatever a spawner parented it to. Counted by script path so
## the suite needs no global class registration (the probe's own reader).
func _pickup_count() -> int:
	var count := 0
	for node: Node in _tree().root.find_children("*", "Node2D", true, false):
		var script := node.get_script() as Script
		if script != null and script.resource_path.ends_with("pickup.gd"):
			count += 1
	return count


## ---------------------------------------------------------------------------
## F1. The damage sink: a hit on a `HullBody` belongs to the ship
## ---------------------------------------------------------------------------


func test_a_hull_body_is_walked_to_the_ship_behind_it() -> void:
	var body := _hull_body(_victim)
	assert_true(body != null, "the victim's scene carries its HullBody")
	if body == null:
		return
	assert_false(
		body.has_method(&"take_damage") or body.has_method(&"damage"),
		"the body answers no damage method - the reviewer's measured defect, unchanged"
	)
	assert_eq(
		_guns.call(&"_sink_for", body),
		_victim,
		"the weapon resolves the sink through the collider's ship ancestor"
	)
	assert_eq(_guns.call(&"_sink_for", _victim), _victim, "a ship hands itself back untranslated")
	assert_eq(_guns.call(&"_sink_for", null), null, "and nothing stays nothing")


func test_the_sink_leaves_a_target_that_answers_for_itself_alone() -> void:
	## `PlayerState.damage` is the resource-level seam both files document: a non-Node
	## target that answers for damage must never be walked away from.
	assert_eq(
		_guns.call(&"_sink_for", _shooter_state),
		_shooter_state,
		"a resource target is delivered to as-is"
	)


func test_a_beam_hit_on_a_hull_body_charges_the_ships_shield() -> void:
	var body := _hull_body(_victim)
	var shield_before: float = _victim_state.shield
	var hull_before: float = _victim_state.hull
	assert_true(shield_before > 0.0, "the victim opens with its shields up")
	_guns.call(
		&"_deliver", body, 120.0, false, _victim.global_position, &"energy", Vector2.ZERO
	)
	assert_true(
		_near(shield_before - _victim_state.shield, 120.0, 0.01),
		"the shield took the whole 120 (before: %s, after: %s)"
		% [shield_before, _victim_state.shield]
	)
	assert_true(
		_near(_victim_state.hull, hull_before, 0.001),
		"and the hull is untouched while the shield holds"
	)


func test_a_beam_hit_with_the_shields_down_charges_the_ships_hull() -> void:
	var body := _hull_body(_victim)
	_victim_state.set_shield(0.0)
	var hull_before: float = _victim_state.hull
	_guns.call(
		&"_deliver", body, 120.0, false, _victim.global_position, &"energy", Vector2.ZERO
	)
	assert_true(
		_near(hull_before - _victim_state.hull, 120.0, 0.01),
		"the hit carried through to the hull (before: %s, after: %s)"
		% [hull_before, _victim_state.hull]
	)


## Section 4.1's plasma rule, read through the sink: "+25 % to hull once shields are
## down". The collider cannot answer `shield_up`, so this reading is what proves the
## shield rule follows the ship and not the body's silence.
func test_the_plasma_bonus_reads_the_ships_shields_not_the_bodys_silence() -> void:
	var body := _hull_body(_victim)
	var row: Dictionary = WeaponsScript.FAMILIES[&"plasma"]
	var dps: float = WeaponsScript.dps_of(&"plasma")
	var bonus := float(row.get(&"hull_bonus", 1.0))
	assert_true(bonus > 1.0, "the row carries the 1.25 hull bonus")
	var shield_before: float = _victim_state.shield
	var hull_before: float = _victim_state.hull
	_guns.call(&"_apply_beam", &"plasma", row, body, _victim.global_position, 1.0)
	assert_true(
		_near(shield_before - _victim_state.shield, dps, 0.01),
		"with the shields up the beam deals its plain dps, no bonus (measured %s, expected %s)"
		% [shield_before - _victim_state.shield, dps]
	)
	assert_true(_near(_victim_state.hull, hull_before, 0.001), "and the hull is untouched")
	_victim_state.set_shield(0.0)
	var bare_hull: float = _victim_state.hull
	_guns.call(&"_apply_beam", &"plasma", row, body, _victim.global_position, 1.0)
	assert_true(
		_near(bare_hull - _victim_state.hull, dps * bonus, 0.01),
		"and once they are down the same second lands dps x 1.25 (measured %s, expected %s)"
		% [bare_hull - _victim_state.hull, dps * bonus]
	)


func test_a_projectile_hit_on_a_hull_body_charges_the_ship() -> void:
	var body := _hull_body(_victim)
	var shot := _build_shot({
		&"kind": &"bolt",
		&"speed": 1000.0,
		&"damage": 27.0,
		&"bypass_shield": true,
		&"range": 600.0,
		&"chip": WeaponsScript.GUN_CHIP_RATE,
	})
	assert_eq(shot.call(&"_sink_for", body), _victim, "the projectile resolves the same sink")
	var hull_before: float = _victim_state.hull
	var shield_before: float = _victim_state.shield
	shot.call(&"_hit_body", body, _victim.global_position)
	assert_true(
		_near(hull_before - _victim_state.hull, 27.0, 0.01),
		"the bolt's 27 came off the ship's hull (before: %s, after: %s)"
		% [hull_before, _victim_state.hull]
	)
	assert_true(
		_near(_victim_state.shield, shield_before, 0.001),
		"a bypassing shot leaves the shield alone"
	)


## The mine is the control the reviewer measured staying green: it resolves its victim
## through the ship groups already, so its 180 must still land on the hull.
func test_a_mine_blast_still_lands_on_the_ship_it_triggers() -> void:
	var mine := _build_shot({
		&"kind": &"mine",
		&"damage": 180.0,
		&"bypass_shield": true,
		&"range": 0.0,
		&"arm": 2.0,
		&"trigger": 60.0,
	})
	mine.global_position = _victim.global_position
	var hull_before: float = _victim_state.hull
	var shield_before: float = _victim_state.shield
	mine.call(&"_detonate", mine.global_position, _victim)
	assert_true(
		_near(hull_before - _victim_state.hull, 180.0, 0.01),
		"the blast alpha landed (measured %s)" % [hull_before - _victim_state.hull]
	)
	assert_true(
		_near(_victim_state.shield, shield_before, 0.001), "and its bypass rule held"
	)


## The NPC half of the walk: an alien or pirate hull is in `npc_ship`, not `player_ship`.
func test_an_npc_hull_is_reached_through_its_body_too() -> void:
	var npc: Node2D = NpcShipScript.new()
	_fixture_host().add_child(npc)
	npc.call(
		&"setup",
		&"pirate",
		ShipFitScript.resolve(&"ship_fighter", ShipFitScript.STANDARD_FIT),
		&"ship_fighter",
		{&"home": Vector2(2000.0, 0.0)},
	)
	_staged.append(npc)
	var body := npc.get_node_or_null(NodePath(NpcShipScript.BODY_NODE))
	assert_true(body != null, "the NPC carries its HullBody")
	if body == null:
		return
	assert_true(
		npc.is_in_group(NpcRegistryScript.GROUP),
		"and answers the %s group the walk reads" % String(NpcRegistryScript.GROUP)
	)
	assert_false(
		body.has_method(&"take_damage") or body.has_method(&"damage"),
		"the NPC's body answers no damage method either"
	)
	assert_eq(_guns.call(&"_sink_for", body), npc, "the sink is the NPC hull")
	var hull_before: float = float(npc.call(&"hull"))
	_guns.call(&"_deliver", body, 50.0, true, npc.global_position, &"kinetic", Vector2.ZERO)
	assert_true(
		_near(hull_before - float(npc.call(&"hull")), 50.0, 0.01),
		"the hit landed on the NPC's own hull pool (before: %s, after: %s)"
		% [hull_before, npc.call(&"hull")]
	)


## The rock branch of the beam is the one path that already worked, and the delivery
## fix renamed its local: it must still chip at section 6's 10 % rate and extract
## nothing (ruling 17).
func test_a_gun_still_chips_a_rock_and_extracts_nothing() -> void:
	var rock: Node2D = AsteroidScript.new() as Node2D
	rock.call(&"setup", &"ore_iron", 1, 20, AsteroidScript.SIZE_LARGE)
	_fixture_host().add_child(rock)
	_staged.append(rock)
	assert_eq(
		_guns.call(&"_sink_for", rock),
		rock,
		"a rock is not walked away from: it has no ship ancestor"
	)
	var units_before: int = int(rock.get(&"yield_units"))
	var pickups_before := _pickup_count()
	_guns.call(
		&"_apply_beam", &"laser", WeaponsScript.FAMILIES[&"laser"], rock, rock.global_position, 1.0
	)
	var chipped: int = units_before - int(rock.get(&"yield_units"))
	assert_eq(
		chipped,
		3,
		"one second of the 30 dps laser at the 10 %% chip rate is three work units (got %d)" % chipped
	)
	assert_eq(_pickup_count(), pickups_before, "a gun chip extracts no ore (ruling 17)")


## ---------------------------------------------------------------------------
## F2. The pack writer and the dock's report
## ---------------------------------------------------------------------------


func test_set_ammo_writes_the_pack_and_survives_the_file() -> void:
	_delete_file(SCRATCH_PROFILE)
	var profile = _fresh_profile()
	profile.reload()
	assert_eq(
		profile.ammo_of(&"cannon"),
		ProfileScript.DEFAULT_AMMO,
		"the pack opens at the shipped default"
	)
	profile.set_ammo(&"cannon", 175)
	assert_eq(profile.ammo_of(&"cannon"), 175, "the writer is the read's other half")
	profile.save()
	var reloaded = _fresh_profile()
	reloaded.reload()
	assert_eq(reloaded.ammo_of(&"cannon"), 175, "and the write survives the config file")
	assert_eq(
		reloaded.ammo_of(&"laser"),
		ProfileScript.DEFAULT_AMMO,
		"a pack the report did not touch keeps its own holding"
	)


func test_set_ammo_ignores_an_unknown_pack_and_a_write_that_changes_nothing() -> void:
	_delete_file(SCRATCH_PROFILE)
	var profile = _fresh_profile()
	profile.reload()
	profile.profile_changed.connect(_on_profile_changed)
	profile.set_ammo(&"cannon", ProfileScript.DEFAULT_AMMO)
	assert_true(_signals.is_empty(), "a write that changes nothing does not signal")
	profile.set_ammo(&"lance", 12)
	assert_eq(profile.ammo_of(&"lance"), 0, "an id outside AMMO_MAX opens no sixth pack")
	assert_true(_signals.is_empty(), "and does not signal either")
	profile.set_ammo(&"cannon", 12)
	var expected: Array[StringName] = [ProfileScript.KEY_AMMO]
	assert_eq(_signals, expected, "a real change touches the ammo key")
	profile.set_ammo(&"cannon", -5)
	assert_eq(profile.ammo_of(&"cannon"), 0, "and a negative holding clamps at empty")
	profile.profile_changed.disconnect(_on_profile_changed)


## The dock's ammo report, end to end: the launch seeds the live pack from the profile's
## store, three rounds are fired, `game.gd:_file_ammo_report` files the delta and the
## store reads three rounds lighter. The slot is the fired family's own index in the live
## `PlayerState.weapons` - the fit-ordered sizing the launch writes - and not
## `PlayerState.WEAPONS`' catalogue order, which a launched fit need not follow
## (`.agents/gen/p2b_proper_r1_report.md` section 7, LOW-6). The structure cannot be swapped
## here (the runner is inside its own `_ready`, so `/root` is blocked for `add_child` -
## measured), so the shipped autoload is *borrowed* instead: its `save_path` is pointed at a
## scratch file, the one pack the report touches is snapshotted and written back, and the
## store is flushed while the scratch path is still in place, so the owner's `profile.cfg` is
## never written and the live store ends exactly as it started.
func test_the_dock_report_settles_a_fired_pack() -> void:
	if _scene == null or _state == null:
		assert_true(false, "the game scene is the dock fixture")
		return
	var profile: Node = _tree().root.get_node_or_null(NodePath(&"PlayerProfile"))
	assert_true(profile != null, "the profile autoload is the dock's store")
	if profile == null:
		return
	var slot: int = int((_state.get(&"weapons") as Array).find(&"laser"))
	assert_true(
		slot >= 0,
		"the fixture's own fit mounts the laser this report fires (%s)"
		% [_state.get(&"weapons")]
	)
	if slot < 0:
		return
	var previous_path: String = profile.get(&"save_path")
	var stored_before: int = int(profile.call(&"ammo_of", &"laser"))
	var other_before: int = int(profile.call(&"ammo_of", &"cannon"))
	var previous_log: String = Log.log_path
	profile.set(&"save_path", SCRATCH_PROFILE)
	Log.log_path = SCRATCH_LOG
	_delete_file(SCRATCH_PROFILE)
	_delete_file(SCRATCH_LOG)
	_scene.call(&"_seed_ammo")
	var live: int = int((_state.get(&"ammo") as Array)[slot])
	var ceiling: int = int((_state.get(&"ammo_max") as Array)[slot])
	_state.set_ammo(slot, live - 3)
	_scene.call(&"_file_ammo_report")
	var filed: int = int(profile.call(&"ammo_of", &"laser"))
	var other_after: int = int(profile.call(&"ammo_of", &"cannon"))
	## Hand the store back before any assertion can matter: the same holding, then a flush
	## on the scratch path, so no dirty flag and no running timer outlive the test.
	profile.call(&"set_ammo", &"laser", stored_before)
	profile.call(&"flush")
	profile.set(&"save_path", previous_path)
	Log.log_path = previous_log
	_delete_file(SCRATCH_PROFILE)
	_delete_file(SCRATCH_LOG)
	assert_eq(
		live,
		mini(stored_before, ceiling),
		"the launch seeded the live pack from the store (%d of %d)" % [stored_before, ceiling]
	)
	assert_eq(
		filed,
		maxi(stored_before - 3, 0),
		"the dock filed exactly the three rounds that were fired (%d -> %d)"
		% [stored_before, filed]
	)
	assert_eq(other_after, other_before, "and a pack that was not fired did not move")


func _fresh_profile():
	var profile := ProfileScript.new()
	profile.save_path = SCRATCH_PROFILE
	_profiles.append(profile)
	return profile


func _on_profile_changed(key: StringName) -> void:
	_signals.append(key)


func _delete_file(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


## ---------------------------------------------------------------------------
## F4. The minimap's two new blip kinds (ENGINE_SPEC section 10, UI_SPEC section 3.3)
## ---------------------------------------------------------------------------


func _token(name: StringName) -> Color:
	if HudTheme.has_color(name, &"Tokens"):
		return HudTheme.get_color(name, &"Tokens")
	return Color.WHITE


func test_a_swarmer_blip_is_drawn_as_a_hostile_blip() -> void:
	var hostile: Color = _minimap.call(&"_color_for", &"hostile")
	assert_eq(
		_minimap.call(&"_color_for", &"swarmer"),
		hostile,
		"section 10's sub-kind wears the hostile colour byte for byte"
	)
	assert_eq(hostile, _token(&"accent_danger"), "which is section 3.3's accent_danger")
	assert_eq(
		_minimap.call(&"_radius_for", &"swarmer"),
		_minimap.call(&"_radius_for", &"hostile"),
		"and it is drawn at the hostile blip's own size"
	)


func test_a_ghost_blip_flickers_between_the_spec_alphas() -> void:
	var peak: float = _minimap.call(&"ghost_alpha", FLICKER_PEAK_AT)
	var trough: float = _minimap.call(&"ghost_alpha", FLICKER_TROUGH_AT)
	assert_true(_near(peak, 0.7, 0.0001), "the curve reaches section 3.3's 0.7 (got %s)" % peak)
	assert_true(_near(trough, 0.3, 0.0001), "and its 0.3 (got %s)" % trough)
	assert_true(
		_near(
			_minimap.call(&"ghost_alpha", 0.07),
			_minimap.call(&"ghost_alpha", 0.07 + FLICKER_PERIOD),
			0.0001
		),
		"6 Hz: one period later the reading is the same"
	)
	var inside := true
	for step in 60:
		var reading: float = _minimap.call(&"ghost_alpha", float(step) / 60.0)
		if reading < 0.3 - 0.0001 or reading > 0.7 + 0.0001:
			inside = false
	assert_true(inside, "and never leaves the 0.3-0.7 band over a full second")


func test_a_ghost_is_the_neutral_colour_with_only_its_alpha_moving() -> void:
	_minimap.set(&"_ghost_clock", FLICKER_TROUGH_AT)
	var ghost: Color = _minimap.call(&"_color_for", &"ghost")
	var neutral := _token(&"text_dim")
	assert_true(
		_near(ghost.a, 0.3, 0.0001),
		"the dot is drawn at the flicker's own reading (got %s)" % ghost.a
	)
	assert_eq(
		Color(ghost.r, ghost.g, ghost.b),
		Color(neutral.r, neutral.g, neutral.b),
		"and it is the neutral text_dim dot, never the hostile red"
	)
	assert_true(ghost != _minimap.call(&"_color_for", &"hostile"), "so it cannot be mistaken for a hostile")


func test_the_flicker_driver_runs_only_while_a_ghost_is_on_the_feed() -> void:
	var plain: Array[Dictionary] = [
		{"pos": Vector2.ZERO, "kind": &"self"},
		{"pos": Vector2(100.0, 0.0), "kind": &"hostile"},
	]
	_minimap.call(&"set_blips", plain)
	assert_false(_minimap.is_processing(), "no clock without a ghost")
	var with_ghost: Array[Dictionary] = plain.duplicate()
	with_ghost.append({"pos": Vector2(150.0, 0.0), "kind": &"ghost"})
	_minimap.call(&"set_blips", with_ghost)
	assert_true(_minimap.is_processing(), "a chaff ghost turns the flicker on")
	_minimap.call(&"_process", 1.0 / 12.0)
	assert_true(
		_near(float(_minimap.call(&"ghost_clock")), 1.0 / 12.0, 0.0001),
		"the clock is the integral of the deltas it is handed"
	)
	_minimap.call(&"set_blips", plain)
	assert_false(_minimap.is_processing(), "and it stops when the last ghost leaves")
	assert_true(
		_near(float(_minimap.call(&"ghost_clock")), 0.0, 0.0001),
		"a fresh drop opens at the same phase"
	)


func test_the_existing_blip_colours_are_unchanged() -> void:
	assert_eq(_minimap.call(&"_color_for", &"self"), _token(&"text_primary"))
	assert_eq(_minimap.call(&"_color_for", &"friendly"), _token(&"text_primary"))
	assert_eq(_minimap.call(&"_color_for", &"hostile"), _token(&"accent_danger"))
	assert_eq(_minimap.call(&"_color_for", &"neutral"), _token(&"text_dim"))
	assert_eq(
		_minimap.call(&"_color_for", &"anything_else"),
		_token(&"text_dim"),
		"an unknown kind still falls back to the neutral token"
	)
