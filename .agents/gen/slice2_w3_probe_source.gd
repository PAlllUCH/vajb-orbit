extends SceneTree
## Slice-2 W3 probe: the NPC registry, the one brain and the hull, measured end to end.
##
## Archived copy lives with the W3 report; to re-run it, copy this file to
## `vajb-orbit/tools/` (the brief keeps `tools/` holding only `build_theme.gd` and
## `derive_icon_tints.gd`) and:
##
##   "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path
##   "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --script res://tools/_probe_s2w3_npc.gd
##   --quit-after 2400
##
## It runs on a real scene tree, so the hulls fly on live RigidBody2D bodies and the
## LOS check is the shipping physics ray (a real `Asteroid` between the hull and the
## player). The scene's own `_physics_process` is what ticks each brain, exactly as it
## does in the game - the probe only teleports bodies and reads states back.
##
## Measurements printed, one line per check:
##   * the section 13 per-sector band and where patrols/convoys may spawn;
##   * every archetype spawned as a hull: art, body layers, mass, circle radius, blip;
##   * the brain's state walk on synthetic positions (IDLE -> PATROL -> ALERT -> ENGAGE
##     -> FLEE -> RETURN) with a blocked and a clear LOS;
##   * the shipping rock ray: a rock between hull and player keeps the state in Alert;
##   * the AGGRO_COOLDOWN grace, the re-acquire, and the section 13 leash;
##   * the fire intent and `engaged_with` (the section 7 safe-warp gate's input).

const Registry := preload("res://game/npc_registry.gd")
const Brain := preload("res://game/npc_brain.gd")
const Ship := preload("res://game/npc_ship.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const AsteroidScript := preload("res://game/asteroid.gd")

const PLAYER_GROUP: StringName = &"player_ship"
const PROFILE_SERVICE: StringName = &"PlayerProfile"
const PROFILE_SAVE_FILE := "user://profile.cfg"
const SCRATCH_PROFILE := "user://_probe_s2w3_profile.cfg"
const DAMAGE_SCRIPT := "res://game/damage.gd"
const OWNER: StringName = &"concord"
const HOME := Vector2.ZERO
const PLAYER_AT := Vector2(300.0, 0.0)
const ROCK_BETWEEN := Vector2(150.0, 0.0)
const ROCK_PARKED := Vector2(0.0, 6000.0)
const FAR_AWAY := Vector2(4000.0, 0.0)
const PAST_THE_LEASH := Vector2(Brain.LEASH_RADIUS + 400.0, 0.0)
const TICKS := 60

var _ok := 0
var _failed := 0
var _world: Node2D = null
var _ship: Node2D = null
var _player: Node2D = null
var _rock: Node2D = null


func _init() -> void:
	print("=== slice2 W3 probe: registry + brain + NPC hull ===")
	_world = Node2D.new()
	_world.name = "ProbeWorld"
	get_root().add_child(_world)
	_report_registry()
	await _report_archetypes()
	_report_brain_walk()
	await _report_rock_los()
	await _report_grace_and_leash()
	await _report_sink_contract()
	await _report_heat_chain()
	print("[SUMMARY] ok=%d failed=%d" % [_ok, _failed])
	quit(1 if _failed > 0 else 0)


func _check(label: String, passed: bool, detail: String = "") -> void:
	if passed:
		_ok += 1
		print("[OK]   %s | %s" % [label, detail])
	else:
		_failed += 1
		print("[FAIL] %s | %s" % [label, detail])


func _ticks(count: int) -> void:
	for _i in count:
		await physics_frame


## --- The registry (section 13's count shape) --------------------------------------


func _report_registry() -> void:
	print("-- registry: section 13's per-sector shape --")
	var wanted: Array[Vector2i] = [
		Vector2i(0, 1), Vector2i(1, 2), Vector2i(2, 3), Vector2i(3, 4),
		Vector2i(3, 5), Vector2i(4, 6), Vector2i(6, 8),
	]
	var all_ok := true
	for index in wanted.size():
		var sector: StringName = &"sector_%d" % (index + 1)
		var table := Registry.density_table(sector)
		var hostiles := Vector2i.ZERO
		for id: StringName in [&"pirate", &"swarmer"]:
			if table.has(id):
				hostiles += table[id] as Vector2i
		if hostiles != wanted[index]:
			all_ok = false
		print(
			"   %s owner=%s hostiles=%s patrol=%s convoy=%s (section 13 band %s)"
			% [
				sector,
				Registry.space_owner(sector),
				hostiles,
				table.get(&"patrol", Vector2i.ZERO),
				table.get(&"trader", Vector2i.ZERO),
				wanted[index],
			]
		)
	_check(
		"bands: pirate+swarmer per sector equal section 13's S1 0-1 ... S7 6-8",
		all_ok,
		"patrols only where the owner is a faction; the convoy only where the sector is inhabited"
	)
	var spawn_ids := {}
	for sector_index in wanted.size():
		var sector: StringName = &"sector_%d" % (sector_index + 1)
		for row: Dictionary in Registry.spawns_for(sector):
			spawn_ids[StringName(row[Registry.KEY_ARCHETYPE])] = true
	_check(
		"spawns: only pirate/swarmer/patrol/trader reach a sector",
		(
			spawn_ids.has(&"pirate") and spawn_ids.has(&"swarmer") and spawn_ids.has(&"patrol")
			and spawn_ids.has(&"trader") and not spawn_ids.has(&"hunter")
			and not spawn_ids.has(&"boss") and not spawn_ids.has(&"sibelon")
			and not spawn_ids.has(&"apex") and not spawn_ids.has(&"turret")
		),
		"spawned archetypes across all seven sectors: %s" % str(spawn_ids.keys())
	)
	var unaligned := Registry.spawns_for(&"sector_7")
	var hunter_free := true
	for row: Dictionary in unaligned:
		if StringName(row[Registry.KEY_ARCHETYPE]) == &"patrol":
			hunter_free = false
	_check("sector 7 is unaligned: no patrol, no convoy", hunter_free)


## --- Every archetype as a live hull ----------------------------------------------


func _report_archetypes() -> void:
	print("-- hulls: one of each shipping archetype --")
	for spec: Dictionary in [
		{&"id": &"pirate", &"hull": &"ship_fighter"},
		{&"id": &"swarmer", &"hull": &"ship_fighter"},
		{&"id": &"patrol", &"hull": &"ship_patrol"},
		{&"id": &"trader", &"hull": &"ship_freighter"},
	]:
		var id: StringName = spec[&"id"]
		var hull: StringName = spec[&"hull"]
		var stats: ShipStats = ShipFitScript.resolve(hull, ShipFitScript.STANDARD_FIT)
		var ship: Node2D = _spawn(id, hull, stats, &"concord")
		_check(
			"spawn %s: art, body and row are live" % id,
			bool(ship.call(&"art_ready")) and ship.call(&"impact_body") != null,
			"hull=%s sprite=%s mass=%.0f t radius=%.1f u blip=%s state=%s"
			% [
				hull,
				Registry.sprite_path(Registry.archetype(id), &"concord"),
				(ship.call(&"impact_body") as RigidBody2D).mass,
				_circle_radius(ship),
				ship.call(&"blip_kind"),
				ship.call(&"state_name"),
			]
		)
		ship.queue_free()
	## The turret: 08 section 5 gives `ship_turret_platform` no class row, so it has no
	## snapshot to resolve and its hull holds position (the W3 report raises the gap).
	var turret: Node2D = _spawn(&"turret", &"ship_turret_platform", null, &"concord")
	var turret_body := turret.call(&"impact_body") as RigidBody2D
	var frozen := turret_body != null and turret_body.freeze
	_check(
		"spawn turret: static, frozen, no snapshot (the 08 gap is reported)",
		frozen,
		"freeze=%s mass=%.1f art=%s state=%s"
		% [
			str(frozen),
			turret_body.mass if turret_body != null else 0.0,
			turret.call(&"art_ready"),
			turret.call(&"state_name"),
		]
	)
	turret.queue_free()
	await _ticks(2)
	var swarmer: Node2D = _spawn(&"swarmer", &"ship_fighter", _stats_for(&"ship_fighter"), &"")
	_check(
		"swarmer craft: ruling 24's alien hull is the row's own sprite",
		Registry.sprite_path(Registry.archetype(&"swarmer"), &"") \
			== "res://assets/ships/ship_swarmer_side.png",
		"sprite=%s art_ready=%s" % [
			Registry.sprite_path(Registry.archetype(&"swarmer"), &""),
			swarmer.call(&"art_ready"),
		]
	)
	var pirate_row := Registry.archetype(&"pirate")
	var swarmer_row := Registry.archetype(&"swarmer")
	_check(
		"swarmer behaviour: pirate-like on the same brain (ruling 24)",
		(
			swarmer_row[Registry.KEY_AGGRO_RADIUS] == pirate_row[Registry.KEY_AGGRO_RADIUS]
			and swarmer_row[Registry.KEY_FLEE_HULL] == pirate_row[Registry.KEY_FLEE_HULL]
			and swarmer_row[Registry.KEY_HOSTILITY] == pirate_row[Registry.KEY_HOSTILITY]
			and swarmer_row[Registry.KEY_BLIP_KIND] == pirate_row[Registry.KEY_BLIP_KIND]
		),
		"aggro=%s flee=%s hostility=%s blip=%s"
		% [
			swarmer_row[Registry.KEY_AGGRO_RADIUS],
			swarmer_row[Registry.KEY_FLEE_HULL],
			swarmer_row[Registry.KEY_HOSTILITY],
			swarmer_row[Registry.KEY_BLIP_KIND],
		]
	)
	swarmer.queue_free()
	await _ticks(2)


func _circle_radius(ship: Node2D) -> float:
	var body := ship.call(&"impact_body") as RigidBody2D
	if body == null:
		return 0.0
	var shape := body.get_node_or_null(NodePath(Ship.SHAPE_NODE)) as CollisionShape2D
	if shape == null or not (shape.shape is CircleShape2D):
		return 0.0
	return (shape.shape as CircleShape2D).radius


func _stats_for(hull: StringName) -> ShipStats:
	return ShipFitScript.resolve(hull, ShipFitScript.STANDARD_FIT)


func _spawn(
	id: StringName, hull: StringName, stats: ShipStats, owner: StringName
) -> Node2D:
	var ship: Node2D = Ship.new()
	_world.add_child(ship)
	ship.call(&"setup", id, stats, hull, {
		Ship.OPT_HOME: HOME,
		Ship.OPT_SPACE_OWNER: owner,
	})
	return ship


## --- The brain's state walk (synthetic positions) ----------------------------------


func _report_brain_walk() -> void:
	print("-- brain: the state walk on synthetic positions --")
	var brain: RefCounted = Brain.new()
	brain.call(&"setup", &"pirate", Registry.archetype(&"pirate"), HOME)
	var low_los := Callable(self, &"_blocked_los")
	var walk: Array[StringName] = []
	walk.append(brain.call(&"state_name") as StringName)
	var player := _player_contact(PLAYER_AT)
	brain.call(&"tick", 1.0 / 60.0, _brain_ctx([], 1.0))
	walk.append(brain.call(&"state_name") as StringName)
	brain.call(&"set_line_of_sight", low_los)
	brain.call(&"tick", 1.0 / 60.0, _brain_ctx([player], 1.0))
	walk.append(brain.call(&"state_name") as StringName)
	brain.call(&"set_line_of_sight", Callable())
	brain.call(&"tick", 1.0 / 60.0, _brain_ctx([player], 1.0))
	walk.append(brain.call(&"state_name") as StringName)
	## The second engage is section 5's grace: the contact is gone from the context but
	## the aggro is held for AGGRO_COOLDOWN, which is the state the safe warp reads.
	brain.call(&"tick", 1.0 / 60.0, _brain_ctx([], 1.0))
	walk.append(brain.call(&"state_name") as StringName)
	brain.call(&"tick", 1.0 / 60.0, _brain_ctx([], 0.29))
	walk.append(brain.call(&"state_name") as StringName)
	brain.call(&"tick", 1.0 / 60.0, _brain_ctx([], 0.90))
	walk.append(brain.call(&"state_name") as StringName)
	var expected: Array[StringName] = [
		&"idle", &"patrol", &"alert", &"engage", &"engage", &"flee", &"return",
	]
	_check(
		"brain walk: idle -> patrol -> alert -> engage -> (grace) -> flee -> return",
		walk == expected,
		"observed %s" % str(walk)
	)


func _blocked_los(_from: Vector2, _to: Vector2) -> bool:
	return false


func _player_contact(pos: Vector2) -> Dictionary:
	return {
		&"pos": pos,
		&"velocity": Vector2.ZERO,
		&"is_player": true,
		&"archetype": &"",
		&"hostility": Registry.HOSTILITY_NONE,
	}


func _brain_ctx(contacts: Array[Dictionary], hull_fraction: float) -> Dictionary:
	return {
		Brain.CTX_POS: HOME,
		Brain.CTX_HULL_FRACTION: hull_fraction,
		Brain.CTX_HOME: HOME,
		Brain.CTX_HEAT_TIER: &"clean",
		Brain.CTX_CONTACTS: contacts,
		Brain.CTX_ATTACKED: false,
	}


## --- The shipping LOS ray, blocked by a real rock ----------------------------------


func _report_rock_los() -> void:
	print("-- LOS: the shipping ray against a real rock --")
	_ship = _spawn(&"pirate", &"ship_fighter", _stats_for(&"ship_fighter"), &"")
	_player = Node2D.new()
	_player.name = "ProbePlayer"
	_player.add_to_group(PLAYER_GROUP)
	_world.add_child(_player)
	_player.global_position = PLAYER_AT
	_rock = AsteroidScript.new()
	_world.add_child(_rock)
	_rock.call(&"setup", &"iron", 1, 5)
	_rock.global_position = ROCK_BETWEEN
	_place(_ship, HOME)
	await _ticks(30)
	_check(
		"LOS blocked: a rock between hull and player keeps the state in Alert",
		StringName(_ship.call(&"state_name")) == &"alert",
		"pirate at %s, rock at %s, player at %s -> state=%s"
		% [HOME, ROCK_BETWEEN, PLAYER_AT, _ship.call(&"state_name")]
	)
	_rock.global_position = ROCK_PARKED
	await _ticks(30)
	var intent: Dictionary = _ship.call(&"intent")
	_check(
		"LOS clear: the same contact, an open line, becomes an engage",
		StringName(_ship.call(&"state_name")) == &"engage" and bool(intent[Brain.INTENT_FIRE]),
		"state=%s fire=%s los=%s target=%s"
		% [
			_ship.call(&"state_name"),
			intent.get(Brain.INTENT_FIRE),
			intent.get(Brain.INTENT_LOS),
			_ship.call(&"target"),
		]
	)
	_check(
		"safe-warp gate: `engaged_with(player)` is true while the brain holds it",
		bool(_ship.call(&"engaged_with", _player)),
		"target=%s" % str(_ship.call(&"target"))
	)


## --- AGGRO_COOLDOWN, re-acquire and the leash -------------------------------------


func _report_grace_and_leash() -> void:
	print("-- aggro: the cooldown grace, the re-acquire and the leash --")
	_place(_ship, HOME)
	await _ticks(6)
	_player.global_position = FAR_AWAY
	var before := float(Brain.AGGRO_COOLDOWN) - 0.33
	await _ticks(int(before * float(TICKS)))
	var held := StringName(_ship.call(&"state_name"))
	await _ticks(int(0.66 * float(TICKS)))
	var released := StringName(_ship.call(&"state_name"))
	var aggro_states: Array[StringName] = [&"alert", &"engage"]
	_check(
		"grace: an aggro state holds for AGGRO_COOLDOWN after the player leaves, then not",
		aggro_states.has(held) and not aggro_states.has(released),
		"at %.1f s: %s; at %.1f s: %s (player %.0f u away, hull %.0f u from its POI)"
		% [
			before,
			held,
			before + 0.66,
			released,
			FAR_AWAY.length(),
			_ship.global_position.distance_to(HOME),
		]
	)
	_check(
		"release: the safe-warp gate opens with the aggro",
		not bool(_ship.call(&"engaged_with", _player)),
		"engaged_with(player) = %s" % str(_ship.call(&"engaged_with", _player))
	)
	_place(_ship, HOME)
	_player.global_position = PLAYER_AT
	await _ticks(30)
	_check(
		"re-acquire: a returning contact re-enters the fight",
		StringName(_ship.call(&"state_name")) == &"engage",
		"state=%s" % _ship.call(&"state_name")
	)
	_place(_ship, PAST_THE_LEASH)
	_player.global_position = PAST_THE_LEASH + Vector2(300.0, 0.0)
	await _ticks(10)
	_check(
		"leash: a chase past 2500 u from the POI ends in a return",
		StringName(_ship.call(&"state_name")) == &"return",
		"hull at %s (leash %s) with the player 300 u away -> state=%s"
		% [PAST_THE_LEASH, Brain.LEASH_RADIUS, _ship.call(&"state_name")]
	)


func _place(node: Node2D, pos: Vector2) -> void:
	var body := node.call(&"impact_body") as RigidBody2D
	if body == null:
		node.global_position = pos
		return
	body.linear_velocity = Vector2.ZERO
	body.angular_velocity = 0.0
	body.global_position = pos
	body.global_rotation = 0.0


## --- The sink contract (brief item 4, `damage.gd` -> `NpcShip.take_damage`) --------


## The pinned pipeline delivers a hit by calling the sink's `take_damage`, and it hands
## the item-5 context only to a sink that declares the third parameter (CONTRACTS
## section 8.1 / brief item 4). This measures both halves against the hull: the shield
## absorbs, the hull is untouched, and the context arrives whole.
func _report_sink_contract() -> void:
	print("-- sink: damage.gd -> NpcShip.take_damage (brief item 4) --")
	var damage_script: Variant = load(DAMAGE_SCRIPT)
	if damage_script == null:
		_check(
			"sink: damage.gd is present to deliver the hit",
			false,
			"the pipeline file is missing; the signature is still asserted by the test suite"
		)
		return
	var ship: Node2D = _spawn(&"patrol", &"ship_patrol", _stats_for(&"ship_patrol"), OWNER)
	var shield_before: float = ship.call(&"shield")
	var hull_before: float = ship.call(&"hull")
	var ctx: Dictionary = damage_script.call(
		&"context", ship.global_position, ship.global_rotation, Vector2(-200.0, 0.0), 0.0, &"laser"
	)
	damage_script.call(&"apply", ship, 120.0, false, ctx)
	var recorded: Dictionary = ship.call(&"last_damage_ctx")
	_check(
		"sink: Damage.apply reaches take_damage(amount, bypass, ctx) and the shield absorbs",
		(
			is_equal_approx(float(ship.call(&"shield")), shield_before - 120.0)
			and is_equal_approx(float(ship.call(&"hull")), hull_before)
			and is_equal_approx(absf(float(recorded.get(&"direction", 0.0))), PI)
		),
		"shield %.0f -> %.0f, hull %.0f (unchanged), ctx direction=%.3f family=%s"
		% [
			shield_before,
			ship.call(&"shield"),
			ship.call(&"hull"),
			float(recorded.get(&"direction", 0.0)),
			recorded.get(&"family", &""),
		]
	)
	damage_script.call(&"apply", ship, 40.0, true, {})
	_check(
		"sink: a bypassing hit lands on the hull",
		is_equal_approx(float(ship.call(&"hull")), hull_before - 40.0),
		"hull %.0f -> %.0f after a 40 bypass hit" % [hull_before, ship.call(&"hull")]
	)
	ship.queue_free()
	await _ticks(2)


## --- The heat chain (doc 13 sections 2/3 -> the brain) ----------------------------


## The one path the probe has not measured above: `PlayerProfile.heat` -> doc 13
## section 3's tier -> the trader's flee and the patrol's scan. The profile is an
## autoload, so this is the only place the probe touches a singleton, and it points
## `save_path` at a scratch file and puts the heat back, exactly as
## `tests/test_engine2_pools.gd` does for the fuel cell: the player's own profile.cfg is
## never written.
func _report_heat_chain() -> void:
	print("-- heat: the player's tier reaching the brain (doc 13) --")
	var profile := get_root().get_node_or_null(NodePath(PROFILE_SERVICE))
	if profile == null:
		_check(
			"heat: PlayerProfile is reachable from the probe tree",
			false,
			"no autoload found; the tier chain is asserted in tests/test_engine2_npc.gd instead"
		)
		return
	var stash = profile.call(&"heat")
	profile.set(&"save_path", SCRATCH_PROFILE)
	profile.call(&"set_heat", {String(OWNER): Registry.heat_min(&"suspect")})
	_ship.queue_free()
	await _ticks(2)
	var trader: Node2D = _spawn(&"trader", Registry.CONVOY_HAULER, _stats_for(Registry.CONVOY_HAULER), OWNER)
	await _ticks(int(Ship.HEAT_POLL_SECONDS * float(TICKS)) + 10)
	_check(
		"heat: a Suspect player makes a neutral convoy run (doc 13 section 5)",
		StringName(trader.call(&"state_name")) == &"flee",
		"heat %d in %s -> tier %s -> state=%s"
		% [
			Registry.heat_min(&"suspect"),
			OWNER,
			Registry.heat_tier(Registry.heat_min(&"suspect")),
			trader.call(&"state_name"),
		]
	)
	profile.call(&"set_heat", {String(OWNER): Registry.heat_min(&"clean")})
	await _ticks(int(Ship.HEAT_POLL_SECONDS * float(TICKS)) + 10)
	var cooled := StringName(trader.call(&"state_name"))
	_check(
		"heat: the tier cooling ends the flight",
		cooled != &"flee",
		"heat %d -> state=%s (back to its route once the run is over)"
		% [Registry.heat_min(&"clean"), cooled]
	)
	trader.queue_free()
	profile.call(&"set_heat", stash)
	profile.set(&"save_path", PROFILE_SAVE_FILE)
	await _ticks(2)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_PROFILE))
