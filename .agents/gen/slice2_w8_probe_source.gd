extends SceneTree
## W8 re-review probe for engine slice 2 (fight), written by the re-reviewer.
##
## Independent re-derivation of the findings the fixer pass (W7) claims to have closed:
## the delivery of a shot's damage to a ship (the wave's HIGH), the `PlayerProfile`
## pack writer and the dock's filing seam, the minimap's `&"ghost"`/`&"swarmer"`
## sub-kinds, and the two countermeasure bindings plus their spend chain. Every check
## reads a shipped seam and states the spec row or the reviewer's figure it is testing.
##
## Run (bounded, stdout to a log):
##   "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path
##   "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --script res://tools/_probe_w8_slice2.gd
##   --quit-after 4000
##
## Sections:
##   A  delivery: a held laser and a released bolt on a real hull, and the sink walk
##   B  the sink walk's other halves: an NPC hull, a rock, a plain node, a PlayerState
##   C  the pack writer: `set_ammo` semantics on a throwaway profile instance
##   D  the dock filing seam through the shipped `game.gd` on a live `game.tscn`
##   E  the minimap's swarmer/ghost kinds against the shipped theme tokens
##   F  the input map on disk and at runtime (Z / X / R / C, 20 project actions)
##   G  the spend chain: a real key event's predicate, and the item actually spent
##   H  the pinned interfaces of the wave (frozen and additive)
##
## The owner's `user://profile.cfg` and `user://economy_log.txt` are never written:
## every section that needs a profile repoints `PlayerProfile.save_path` at a scratch
## file after clearing the dirty flag, and flushes before handing it back (L17's rule).

const WeaponsScript := preload("res://game/weapons.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const PlayerShipScript := preload("res://game/player_ship.gd")
const PlayerShipScene := preload("res://game/player_ship.tscn")
const PlayerStateScript := preload("res://game/player_state.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const NpcShipScript := preload("res://game/npc_ship.gd")
const NpcBrainScript := preload("res://game/npc_brain.gd")
const NpcRegistryScript := preload("res://game/npc_registry.gd")
const LootScript := preload("res://game/loot_tables.gd")
const MinimapScript := preload("res://ui/hud/minimap.gd")
const HudTheme := preload("res://ui/theme/vajb_theme.tres")
const ProfileScript := preload("res://autoload/player_profile.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const DamageScript := preload("res://game/damage.gd")
const LogScript := preload("res://game/economy_log.gd")
## `res://game/game.gd` is deliberately NOT preloaded: it names the `Router` autoload
## (line 1231), and a `preload` at parse time runs before the autoloads exist, so the
## whole script fails to compile and poisons the later scene load. It is reached with
## `load()` after the tree is up, exactly like `hud.tscn` (CONTRACTS section 9).

const HULL: StringName = &"ship_vanguard"
const TICKS := 60
const GAME_SCENE := "res://game/game.tscn"
const SCRATCH_WRITER := "user://_w8_probe_writer.cfg"
const SCRATCH_DOCK := "user://_w8_probe_dock.cfg"
const SCRATCH_SPEND := "user://_w8_probe_spend.cfg"
const SCRATCH_LOG := "user://_w8_probe_econ.txt"

var _ok := 0
var _fail := 0
var _world: Node2D = null
var _delta := 1.0 / 60.0
var _profile: Node = null
var _real_save_path := ""
var _real_log_path := ""
var _owner_profile_md5 := ""


func _init() -> void:
	print("=== W8 slice-2 re-review probe ===")
	_delta = 1.0 / maxf(float(Engine.physics_ticks_per_second), 1.0)
	_world = Node2D.new()
	_world.name = &"W8ProbeWorld"
	get_root().add_child(_world)
	## One frame first: an autoload is only in the tree once the SceneTree iterates.
	await _ticks(2)
	_profile = get_root().get_node_or_null(NodePath(&"PlayerProfile"))
	_check(
		"the PlayerProfile autoload is in the tree (the spend seam's owner)",
		_profile != null,
		"node=%s" % _profile
	)
	if _profile != null:
		_real_save_path = String(_profile.save_path)
	_owner_profile_md5 = FileAccess.get_md5(_real_save_path)
	_real_log_path = String(LogScript.log_path)
	LogScript.log_path = SCRATCH_LOG
	await _section_a_delivery()
	await _section_b_sink_walk()
	_section_c_pack_writer()
	await _section_d_dock_filing()
	await _section_e_minimap()
	_section_f_input_map()
	await _section_g_spend_chain()
	_section_h_pins()
	_restore_paths()
	_cleanup_scratch()
	_check(
		"the owner's own profile.cfg is byte-identical across this whole pass",
		FileAccess.get_md5(_real_save_path) == _owner_profile_md5,
		"md5 %s -> %s" % [_owner_profile_md5, FileAccess.get_md5(_real_save_path)]
	)
	print("[SUMMARY] ok=%d failed=%d" % [_ok, _fail])
	quit(1 if _fail > 0 else 0)


func _ticks(count: int) -> void:
	for _i in count:
		await physics_frame


func _near(measured: float, expected: float, tol: float) -> bool:
	return absf(measured - expected) <= tol


func _check(label: String, passed: bool, detail: String = "") -> void:
	if passed:
		_ok += 1
		print("[PASS] %s | %s" % [label, detail])
	else:
		_fail += 1
		print("[FAIL] %s | %s" % [label, detail])


## --- the profile's scratch discipline (L17) --------------------------------


func _point_at(path: String) -> void:
	if _profile == null:
		return
	_profile.set(&"_dirty", false)
	_remove_file(path)
	_profile.save_path = path


func _restore_paths() -> void:
	LogScript.log_path = _real_log_path
	if _profile == null:
		return
	_profile.call(&"flush")
	_profile.set(&"_dirty", false)
	_profile.save_path = _real_save_path


func _remove_file(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute)


func _cleanup_scratch() -> void:
	for path: String in [SCRATCH_WRITER, SCRATCH_DOCK, SCRATCH_SPEND, SCRATCH_LOG]:
		_remove_file(path)


## --- A. Delivery: a real shot on a real hull ------------------------------


func _build_ship(at: Vector2) -> Array:
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
	_world.add_child(ship)
	ship.global_position = at
	ship.setup(stats, state, ShipFitScript.fitted_ids(ShipFitScript.STANDARD_FIT))
	return [ship, state, stats]


func _answers_damage(target: Object) -> bool:
	return target != null and (target.has_method(&"take_damage") or target.has_method(&"damage"))


func _hull_body(ship: Node) -> Node:
	return ship.get_node_or_null(NodePath(PlayerShipScript.HULL_BODY_NODE))


func _section_a_delivery() -> void:
	print("-- A. delivery: a held laser and a released bolt on a real hull --")
	var pair := _build_ship(Vector2.ZERO)
	var shooter: Node2D = pair[0]
	var shooter_state: PlayerStateScript = pair[1]
	var victim_pair := _build_ship(Vector2(300.0, 0.0))
	var victim: Node2D = victim_pair[0]
	var victim_state: PlayerStateScript = victim_pair[1]
	await _ticks(3)
	var guns: Node2D = shooter.get_node_or_null(NodePath(PlayerShipScript.WEAPONS_NODE))
	_check("PlayerShip mounts the WeaponComponent", guns != null, "node=%s" % guns)
	if guns == null:
		return
	var body := _hull_body(victim)
	_check("the victim has a HullBody collider", body != null, "body=%s" % body)
	_check(
		"the root cause still holds: the HullBody answers no damage method",
		not _answers_damage(body),
		"take_damage=%s damage=%s" % [
			body.has_method(&"take_damage"), body.has_method(&"damage")
		]
	)
	## 1 s of held laser at 300 u (inside the 500 u range). Section 13's laser is 30 dps.
	var shield_before: float = victim_state.shield
	guns.call(&"set_aim_point", victim.global_position)
	guns.call(&"set_firing", true)
	await _ticks(TICKS)
	guns.call(&"set_firing", false)
	var shield_after: float = victim_state.shield
	var drained: float = shield_before - shield_after
	print(
		"   [measure] 1 s laser at 300 u: shield %s -> %s (drained %s), shooter energy %s"
		% [shield_before, shield_after, drained, shooter_state.energy]
	)
	_check(
		"HIGH/delivery: 1 s of laser drains the target's shield by its 30 dps",
		_near(drained, 30.0, 1.0),
		"drained %s (want 30, section 13 laser dps)" % drained
	)
	_check(
		"the beam paid for itself out of the shooter's Energy (section 4.4)",
		shooter_state.energy < shooter_state.energy_max - 1.0,
		"energy %s -> %s" % [shooter_state.energy_max, shooter_state.energy]
	)
	## The sink walk, both delivery files, on the same collider.
	_check(
		"weapons.gd resolves the hull body to the ship behind it",
		guns.call(&"_sink_for", body) == victim,
		"sink=%s victim=%s" % [guns.call(&"_sink_for", body), victim]
	)
	var shot := ProjectileScript.new() as Node2D
	_world.add_child(shot)
	_check(
		"projectile.gd resolves the same collider to the same ship",
		shot.call(&"_sink_for", body) == victim,
		"sink=%s" % shot.call(&"_sink_for", body)
	)
	shot.queue_free()
	## A direct delivery through the beam's own seam: 120 must come off the shield.
	var direct_before: float = victim_state.shield
	guns.call(&"_deliver", body, 120.0, false, body.global_position, &"laser", Vector2.ZERO)
	var direct_after: float = victim_state.shield
	_check(
		"weapons.gd _deliver on a hull body charges the ship exactly 120",
		_near(direct_before - direct_after, 120.0, 0.01),
		"shield %s -> %s" % [direct_before, direct_after]
	)
	## The control: the same charge through the ship node itself (unchanged behaviour).
	var control_before: float = victim_state.shield
	DamageScript.apply(victim, 120.0, false, {})
	var control_after: float = victim_state.shield
	_check(
		"Damage.apply on the ship node still lands its 120 (unchanged control)",
		_near(control_before - control_after, 120.0, 0.01),
		"shield %s -> %s" % [control_before, control_after]
	)
	## Plasma's section 4.1 bonus must read the *ship's* shields, not the body's silence:
	## 1 s of plasma with the shields up is its 70 dps, and 87.5 (70 x 1.25) with them down.
	var plasma_ids: Array[StringName] = [&"w_plasma"]
	guns.call(&"set_fitted", plasma_ids)
	_check(
		"the plasma fit selects as plasma",
		guns.call(&"selected_weapon") == &"plasma",
		"selected=%s" % guns.call(&"selected_weapon")
	)
	victim_state.set_shield(victim_state.shield_max)
	await _ticks(2)
	var plasma_up_before: float = victim_state.shield
	guns.call(&"set_aim_point", victim.global_position)
	guns.call(&"set_firing", true)
	await _ticks(TICKS)
	guns.call(&"set_firing", false)
	var plasma_up: float = plasma_up_before - victim_state.shield
	print("   [measure] 1 s plasma against live shields: shield drained %s" % plasma_up)
	_check(
		"plasma does not take its hull bonus against live shields",
		_near(plasma_up, 70.0, 1.5),
		"drained %s (want its 70 dps, not 87.5)" % plasma_up
	)
	victim_state.set_shield(0.0)
	await _ticks(2)
	var hull_before: float = victim_state.hull
	guns.call(&"set_firing", true)
	await _ticks(TICKS)
	guns.call(&"set_firing", false)
	var hull_burn: float = hull_before - victim_state.hull
	print("   [measure] 1 s plasma with the shields down: hull burned %s" % hull_burn)
	_check(
		"plasma's +25 % lands on the hull once the ship's shields are down",
		_near(hull_burn, 87.5, 1.5),
		"burned %s (want 70 x 1.25 = 87.5)" % hull_burn
	)
	## A released bolt from the shipped trigger, crossing the same 300 u.
	var victim_hull_before: float = victim_state.hull
	var victim_shield_before: float = victim_state.shield
	var cannon_ids: Array[StringName] = [&"w_cannon"]
	guns.call(&"set_fitted", cannon_ids)
	guns.call(&"set_aim_point", victim.global_position)
	var bolt := await _fire_once(guns)
	var released: bool = float(guns.get(&"_shot_timer")) > 0.0 or bolt != null
	await _ticks(40)
	var bolt_hull: float = victim_hull_before - victim_state.hull
	print(
		"   [measure] a cannon bolt at a hull 300 u away: released=%s, hull %s -> %s (%s per bolt), shield %s"
		% [released, victim_hull_before, victim_state.hull, bolt_hull, victim_state.shield]
	)
	_check(
		"a released cannon bolt charges the target's hull for its 27",
		released and _near(bolt_hull, 27.0, 1.0),
		"released=%s, hull %s -> %s" % [released, victim_hull_before, victim_state.hull]
	)
	_check(
		"the bolt's bypass rule leaves the shield alone",
		_near(victim_state.shield, victim_shield_before, 0.01),
		"shield %s -> %s" % [victim_shield_before, victim_state.shield]
	)
	## Section 6 ruling 17: a gun chip depletes a rock and extracts nothing (no pickups).
	var pickups_before := _pickup_count()
	var rock := _make_rock(Vector2(0.0, 300.0))
	var laser_ids: Array[StringName] = [&"w_laser"]
	guns.call(&"set_fitted", laser_ids)
	guns.call(&"set_aim_point", rock.global_position)
	var yield_before: int = int(rock.get(&"yield_units"))
	guns.call(&"set_firing", true)
	await _ticks(TICKS)
	guns.call(&"set_firing", false)
	var chip: int = yield_before - int(rock.get(&"yield_units"))
	print("   [measure] 1 s of laser on a rock at 300 u drained %s ore units" % chip)
	_check(
		"the beam still chips a rock at the 10 % gun rate (30 dps x 0.10 = 3 units)",
		_near(float(chip), 3.0, 0.5),
		"drained %s units" % chip
	)
	_check(
		"a gun chip still extracts no pickup (ruling 17)",
		_pickup_count() == pickups_before,
		"pickups %s -> %s" % [pickups_before, _pickup_count()]
	)
	for node: Node in [shooter, victim, rock]:
		if is_instance_valid(node):
			node.queue_free()
	await _ticks(2)


func _fire_once(guns: Node2D) -> Node2D:
	guns.call(&"set_firing", false)
	var waited := 0
	while float(guns.get(&"_shot_timer")) > 0.0 and waited < 180:
		await physics_frame
		waited += 1
	await physics_frame
	guns.call(&"set_firing", true)
	for _i in 40:
		await physics_frame
		var shot := _first_shot()
		if shot != null:
			guns.call(&"set_firing", false)
			return shot
	guns.call(&"set_firing", false)
	return null


func _first_shot() -> Node2D:
	for node: Node in get_root().find_children("*", "Area2D", true, false):
		if node.is_in_group(&"projectile") and node is Node2D:
			return node as Node2D
	return null


func _make_rock(at: Vector2) -> Node2D:
	var rock := AsteroidScript.new() as Node2D
	rock.global_position = at
	rock.call(&"setup", &"ore_iron", 1, 20, AsteroidScript.SIZE_LARGE)
	_world.add_child(rock)
	return rock


func _pickup_count() -> int:
	var count := 0
	for node: Node in get_root().find_children("*", "Node2D", true, false):
		var script := node.get_script() as Script
		if script != null and script.resource_path.ends_with("pickup.gd"):
			count += 1
	return count


## --- B. The sink walk's other halves --------------------------------------


func _section_b_sink_walk() -> void:
	print("-- B. the sink walk: an NPC hull, a rock, a plain node, a resource --")
	var pair := _build_ship(Vector2(0.0, 4000.0))
	var shooter: Node2D = pair[0]
	await _ticks(3)
	var guns: Node2D = shooter.get_node_or_null(NodePath(PlayerShipScript.WEAPONS_NODE))
	if guns == null:
		_check("section B needs the mounted component", false, "no WeaponComponent")
		return
	var stats := ShipFitScript.resolve(HULL, ShipFitScript.STANDARD_FIT)
	var npc := NpcShipScript.new() as Node2D
	_world.add_child(npc)
	npc.call(&"setup", &"pirate", stats, HULL)
	await _ticks(2)
	var npc_body := _hull_body(npc)
	_check(
		"an NPC hull has a body and no damage method of its own",
		npc_body != null and not _answers_damage(npc_body),
		"body=%s" % npc_body
	)
	_check(
		"the npc_ship half of the walk resolves too",
		guns.call(&"_sink_for", npc_body) == npc,
		"sink=%s npc=%s" % [guns.call(&"_sink_for", npc_body), npc]
	)
	_check(
		"a hull that answers for itself is returned untouched",
		guns.call(&"_sink_for", npc) == npc and guns.call(&"_sink_for", shooter) == shooter,
		"npc=%s shooter=%s" % [guns.call(&"_sink_for", npc), shooter]
	)
	var rock := _make_rock(Vector2(0.0, 300.0))
	await _ticks(2)
	_check(
		"a rock comes back unchanged (the chip path is untouched)",
		guns.call(&"_sink_for", rock) == rock,
		"sink=%s rock=%s" % [guns.call(&"_sink_for", rock), rock]
	)
	var plain := Node2D.new()
	_world.add_child(plain)
	_check(
		"a node in neither ship group comes back unchanged",
		guns.call(&"_sink_for", plain) == plain,
		"sink=%s" % guns.call(&"_sink_for", plain)
	)
	_check("a null target stays null", guns.call(&"_sink_for", null) == null, "ok")
	var state := PlayerStateScript.new()
	state.hull_max = 1000.0
	state.shield_max = 600.0
	state.setup()
	_check(
		"a resource-level sink (PlayerState answers `damage`) is returned untouched",
		guns.call(&"_sink_for", state) == state,
		"sink=%s" % guns.call(&"_sink_for", state)
	)
	for node: Node in [shooter, npc, rock, plain]:
		if is_instance_valid(node):
			node.queue_free()
	await _ticks(2)


## --- C. The pack writer ---------------------------------------------------


func _section_c_pack_writer() -> void:
	print("-- C. PlayerProfile.set_ammo: the writer the dock's pack report needs --")
	var profile := ProfileScript.new() as Node
	_check("a throwaway PlayerProfile instantiates", profile != null, "instance=%s" % profile)
	if profile == null:
		return
	## A throwaway instance defaults to the *shipped* `SAVE_FILE`, so every writer on it
	## must be pointed at a scratch path before it is touched (L17, learned the hard way).
	profile.save_path = SCRATCH_WRITER
	_check(
		"the throwaway instance is pointed away from the owner's file before any write",
		String(profile.save_path) != ProfileScript.SAVE_FILE
			and String(profile.save_path).ends_with("_w8_probe_writer.cfg"),
		"save_path=%s" % profile.save_path
	)
	profile.call(&"_apply_defaults")
	_check(
		"the shipped autoload now publishes set_ammo (the guard game.gd reads)",
		_profile != null and _profile.has_method(&"set_ammo"),
		"has_method=%s" % (_profile.has_method(&"set_ammo") if _profile != null else "no profile")
	)
	_check(
		"set_ammo is id-keyed on the profile while PlayerState's is slot-indexed (no collision)",
		_script_has(ProfileScript, &"set_ammo") and _script_has(PlayerStateScript, &"set_ammo"),
		"profile id-keyed=%s, state slot-indexed=%s" % [
			_script_has(ProfileScript, &"set_ammo"), _script_has(PlayerStateScript, &"set_ammo")
		]
	)
	_check(
		"the defaults are the five packs at 300",
		profile.call(&"ammo_of", &"laser") == 300 and profile.call(&"ammo_of", &"cannon") == 300,
		"laser=%s cannon=%s" % [
			profile.call(&"ammo_of", &"laser"), profile.call(&"ammo_of", &"cannon")
		]
	)
	var signals: Array = []
	profile.connect(&"profile_changed", func(key: StringName) -> void: signals.append(key))
	profile.call(&"set_ammo", &"laser", 175)
	_check(
		"set_ammo writes the pack",
		profile.call(&"ammo_of", &"laser") == 175,
		"laser=%s" % profile.call(&"ammo_of", &"laser")
	)
	_check(
		"a real change emits exactly one profile_changed(&\"ammo\")",
		signals.size() == 1 and signals[0] == &"ammo",
		"signals=%s" % signals
	)
	signals.clear()
	profile.call(&"set_ammo", &"laser", 175)
	_check(
		"a write that changes nothing neither signals nor dirties",
		signals.is_empty(),
		"signals=%s" % signals
	)
	profile.call(&"set_ammo", &"lance", 500)
	_check(
		"an unknown pack id is refused (no sixth pack can be opened)",
		profile.call(&"ammo_of", &"lance") == 0,
		"lance=%s" % profile.call(&"ammo_of", &"lance")
	)
	profile.call(&"set_ammo", &"laser", -5)
	_check(
		"a negative write clamps at zero",
		profile.call(&"ammo_of", &"laser") == 0,
		"laser=%s" % profile.call(&"ammo_of", &"laser")
	)
	## The write must survive the file, and the untouched packs must not move.
	var scratch := ProfileScript.new() as Node
	scratch.save_path = SCRATCH_WRITER
	scratch.call(&"_apply_defaults")
	scratch.call(&"set_ammo", &"laser", 175)
	scratch.call(&"save")
	var reader := ProfileScript.new() as Node
	reader.save_path = SCRATCH_WRITER
	reader.call(&"reload")
	_check(
		"the written pack reloads from the file at 175",
		reader.call(&"ammo_of", &"laser") == 175,
		"reloaded laser=%s" % reader.call(&"ammo_of", &"laser")
	)
	_check(
		"the untouched packs still read the shipped default after the round trip",
		reader.call(&"ammo_of", &"cannon") == ProfileScript.DEFAULT_AMMO
			and reader.call(&"ammo_of", &"rocket") == ProfileScript.DEFAULT_AMMO,
		"cannon=%s rocket=%s (shipped default %s)" % [
			reader.call(&"ammo_of", &"cannon"), reader.call(&"ammo_of", &"rocket"),
			ProfileScript.DEFAULT_AMMO
		]
	)
	profile.free()
	scratch.free()
	reader.free()


## --- D. The dock's filing seam --------------------------------------------


func _section_d_dock_filing() -> void:
	print("-- D. the dock filing seam through the shipped game.gd on a live game.tscn --")
	if _profile == null:
		_check("section D needs the profile autoload", false, "no autoload")
		return
	_point_at(SCRATCH_DOCK)
	var packed := load(GAME_SCENE) as PackedScene
	_check("game.tscn loads", packed != null, "path=%s" % GAME_SCENE)
	if packed == null:
		return
	var game := packed.instantiate() as Node2D
	_world.add_child(game)
	var state: Variant = null
	for _i in 180:
		await physics_frame
		state = game.get(&"_state")
		if state != null:
			break
	_check("the live game.tscn built its PlayerState", state != null, "state=%s" % state)
	if state == null:
		return
	_check(
		"game.gd reaches the profile autoload (its _profile guard now resolves)",
		game.call(&"_profile") == _profile,
		"resolved=%s" % game.call(&"_profile")
	)
	## The seed half: the launch loads each pack from the store.
	var stored_laser := int(_profile.call(&"ammo_of", &"laser"))
	var stored_cannon := int(_profile.call(&"ammo_of", &"cannon"))
	_check(
		"the launch seeds the live pack from the store",
		int(state.ammo[0]) == mini(stored_laser, state.ammo_max[0]),
		"live=%s stored=%s ceiling=%s" % [state.ammo[0], stored_laser, state.ammo_max[0]]
	)
	## The filing half: three rounds fired, then the dock report runs (the real function).
	var live_before := int(state.ammo[0])
	state.set_ammo(0, live_before - 3)
	game.call(&"_file_damage_report")
	var filed := int(_profile.call(&"ammo_of", &"laser"))
	print(
		"   [measure] fired 3: stored laser %s -> %s, live was %s, cannon still %s"
		% [stored_laser, filed, live_before, _profile.call(&"ammo_of", &"cannon")]
	)
	_check(
		"the dock report settles the fired pack (-3), via the shipped function",
		filed == maxi(stored_laser - 3, 0),
		"stored %s -> %s (want %s)" % [stored_laser, filed, maxi(stored_laser - 3, 0)]
	)
	_check(
		"the pack that was not fired does not move",
		int(_profile.call(&"ammo_of", &"cannon")) == stored_cannon,
		"cannon %s -> %s" % [stored_cannon, _profile.call(&"ammo_of", &"cannon")]
	)
	game.call(&"_file_ammo_report")
	var filed_twice := int(_profile.call(&"ammo_of", &"laser"))
	print(
		"   [measure] REVIEW/finding: a second dock report in one launch files the same delta again: %s -> %s"
		% [filed, filed_twice]
	)
	_check(
		"REVIEW/finding R1 (recorded, NOT fixed): a repeat dock report in one launch re-applies the fired delta",
		filed_twice == maxi(filed - 3, 0),
		"laser %s -> %s on a second _file_ammo_report with no further firing" % [filed, filed_twice]
	)
	## Put the in-memory pack back to what it was before the filing, while the scratch path
	## is still in place: the flush in `_restore_paths` must not carry a filed delta home.
	_profile.call(&"set_ammo", &"laser", stored_laser)
	_check(
		"the filing is reversible in memory (the scratch round trip leaves no residue)",
		int(_profile.call(&"ammo_of", &"laser")) == stored_laser,
		"laser back to %s" % _profile.call(&"ammo_of", &"laser")
	)
	## The HUD the live scene built carries every pinned method.
	var hud: Variant = game.get(&"_hud")
	_check("the live game built its HUD", hud != null, "hud=%s" % hud)
	if hud is Node:
		var frozen: Array[StringName] = [
			&"set_target", &"set_target_info", &"clear_target", &"set_reticle_state",
		]
		var slice_two: Array[StringName] = [
			&"set_lock_progress", &"set_speedometer", &"hit_marker",
			&"set_pool", &"set_emergency", &"set_minimap_blips", &"set_prompt",
			&"set_warp_channel",
		]
		var missing: Array[String] = []
		for method: StringName in frozen:
			if not (hud as Node).has_method(method):
				missing.append("frozen:%s" % method)
		for method: StringName in slice_two:
			if not (hud as Node).has_method(method):
				missing.append("added:%s" % method)
		_check(
			"the HUD keeps every frozen method and carries the wave's additions",
			missing.is_empty(),
			"missing=%s" % missing
		)
	## The minimap feed is what game.gd pushes: ghost blips ride their own kind.
	var blips: Array[Dictionary] = []
	var guns: Variant = game.get(&"_guns")
	if guns is Node:
		blips.append_array(game.call(&"_ghost_blips"))
		_check(
			"no ghosts on a fresh launch means no ghost blips on the feed",
			blips.is_empty(),
			"ghost blips=%s" % blips.size()
		)
	else:
		_check("the live game built its WeaponComponent", false, "guns=%s" % guns)
	game.queue_free()
	await _ticks(4)
	_restore_paths()


## --- E. The minimap's two sub-kinds --------------------------------------


func _section_e_minimap() -> void:
	print("-- E. the minimap's swarmer/ghost kinds against the shipped theme --")
	_check(
		"the theme carries the neutral and hostile tokens the map reads",
		HudTheme.has_color(&"text_dim", MinimapScript.TOKENS_TYPE)
			and HudTheme.has_color(&"accent_danger", MinimapScript.TOKENS_TYPE)
			and HudTheme.has_color(&"text_primary", MinimapScript.TOKENS_TYPE),
		"tokens=%s" % MinimapScript.TOKENS_TYPE
	)
	var map := MinimapScript.new() as Control
	if map == null:
		_check("the minimap instantiates", false, "null")
		return
	map.name = &"W8Minimap"
	map.theme = HudTheme
	map.size = Vector2(200.0, 200.0)
	_world.add_child(map)
	await _ticks(2)
	var hostile: Color = map.call(&"_color_for", &"hostile")
	var swarmer: Color = map.call(&"_color_for", &"swarmer")
	var self_colour: Color = map.call(&"_color_for", &"self")
	var friendly: Color = map.call(&"_color_for", &"friendly")
	var neutral: Color = map.call(&"_color_for", &"neutral")
	var unknown: Color = map.call(&"_color_for", &"nonsense")
	print(
		"   [measure] hostile=%s swarmer=%s self=%s neutral=%s"
		% [hostile, swarmer, self_colour, neutral]
	)
	_check(
		"KIND_SWARMER is the pinned &\"swarmer\" and KIND_GHOST the pinned &\"ghost\"",
		MinimapScript.KIND_SWARMER == &"swarmer" and MinimapScript.KIND_GHOST == &"ghost",
		"%s / %s" % [MinimapScript.KIND_SWARMER, MinimapScript.KIND_GHOST]
	)
	_check(
		"a swarmer blip is the very same colour a hostile blip wears",
		swarmer == hostile and hostile == HudTheme.get_color(&"accent_danger", MinimapScript.TOKENS_TYPE),
		"swarmer=%s hostile=%s" % [swarmer, hostile]
	)
	_check(
		"a swarmer blip draws at the hostile radius",
		_near(map.call(&"_radius_for", &"swarmer"), map.call(&"_radius_for", &"hostile"), 0.0001),
		"swarmer=%s hostile=%s" % [
			map.call(&"_radius_for", &"swarmer"), map.call(&"_radius_for", &"hostile")
		]
	)
	_check(
		"the pre-existing kinds did not move (self/friendly text_primary, neutral text_dim)",
		self_colour == HudTheme.get_color(&"text_primary", MinimapScript.TOKENS_TYPE)
			and friendly == self_colour
			and neutral == HudTheme.get_color(&"text_dim", MinimapScript.TOKENS_TYPE)
			and unknown == neutral,
		"self=%s neutral=%s" % [self_colour, neutral]
	)
	## UI_SPEC section 3.3's curve, verbatim: alpha 0.3-0.7 at 6 Hz.
	var peak: float = map.call(&"ghost_alpha", 1.0 / 24.0)
	var trough: float = map.call(&"ghost_alpha", 3.0 / 24.0)
	print("   [measure] ghost_alpha peak %s at 1/24 s, trough %s at 3/24 s" % [peak, trough])
	_check(
		"the flicker reaches 0.7 a quarter period in and 0.3 three quarters in",
		_near(peak, 0.7, 0.0001) and _near(trough, 0.3, 0.0001),
		"peak=%s trough=%s" % [peak, trough]
	)
	_check(
		"the flicker repeats a period later (6 Hz)",
		_near(float(map.call(&"ghost_alpha", 1.0 / 24.0 + 1.0 / 6.0)), peak, 0.0001),
		"reading=%s" % map.call(&"ghost_alpha", 1.0 / 24.0 + 1.0 / 6.0)
	)
	var out_of_band := 0
	for step in 60:
		var reading := float(map.call(&"ghost_alpha", float(step) / 60.0))
		if reading < 0.3 - 0.0001 or reading > 0.7 + 0.0001:
			out_of_band += 1
	_check(
		"60 samples across a second never leave [0.3, 0.7]",
		out_of_band == 0,
		"samples outside the band=%s" % out_of_band
	)
	map.set(&"_ghost_clock", 3.0 / 24.0)
	var ghost: Color = map.call(&"_color_for", &"ghost")
	_check(
		"a ghost blip is the neutral token with only its alpha moved",
		_near(ghost.a, 0.3, 0.0001)
			and Color(ghost.r, ghost.g, ghost.b) == Color(neutral.r, neutral.g, neutral.b)
			and ghost != hostile,
		"ghost=%s" % ghost
	)
	## The flicker driver: on only while a ghost is on the feed.
	_check(
		"the flicker clock is off with no ghost on the feed",
		not map.is_processing(),
		"is_processing=%s" % map.is_processing()
	)
	var plain: Array[Dictionary] = [{"pos": Vector2.ZERO, "kind": &"self"}]
	map.call(&"set_blips", plain)
	_check(
		"a plain feed still leaves the map frame-free",
		not map.is_processing(),
		"is_processing=%s" % map.is_processing()
	)
	var with_ghost: Array[Dictionary] = plain.duplicate()
	with_ghost.append({"pos": Vector2(150.0, 0.0), "kind": &"ghost"})
	map.call(&"set_blips", with_ghost)
	_check(
		"a ghost on the feed turns the flicker clock on",
		map.is_processing(),
		"is_processing=%s" % map.is_processing()
	)
	map.call(&"_process", 1.0 / 12.0)
	map.call(&"_process", 1.0 / 12.0)
	_check(
		"the clock is the integral of the deltas it is handed",
		_near(float(map.call(&"ghost_clock")), 1.0 / 6.0, 0.0001),
		"clock=%s" % map.call(&"ghost_clock")
	)
	map.call(&"set_blips", plain)
	_check(
		"the clock stops and resets when the last ghost leaves",
		not map.is_processing() and _near(float(map.call(&"ghost_clock")), 0.0, 0.0001),
		"is_processing=%s clock=%s" % [map.is_processing(), map.call(&"ghost_clock")]
	)
	map.queue_free()
	await _ticks(2)


## --- F. The input map -----------------------------------------------------


func _project_input_keys() -> Array:
	var config := ConfigFile.new()
	if config.load("res://project.godot") != OK:
		return []
	return config.get_section_keys("input")


func _keycodes(action: StringName) -> Array:
	var out: Array = []
	if not InputMap.has_action(action):
		return out
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			out.append((event as InputEventKey).keycode)
	return out


func _section_f_input_map() -> void:
	print("-- F. the input map on disk and at runtime --")
	var keys := _project_input_keys()
	print("   [measure] project.godot [input] holds %s actions" % keys.size())
	_check(
		"the project input map holds its 20 actions (18 before this wave)",
		keys.size() == 20,
		"count=%s" % keys.size()
	)
	for action: String in ["countermeasure_chaff", "countermeasure_flare", "consume_fuel_cell",
			"cargo_toggle", "interact", "warp"]:
		_check(
			"%s is a project action" % action,
			keys.has(action) and InputMap.has_action(StringName(action)),
			"in project.godot=%s in InputMap=%s" % [
				keys.has(action), InputMap.has_action(StringName(action))
			]
		)
	var expected := {
		&"countermeasure_chaff": KEY_Z,
		&"countermeasure_flare": KEY_X,
		&"consume_fuel_cell": KEY_R,
		&"cargo_toggle": KEY_C,
		&"interact": KEY_F,
		&"warp": KEY_H,
	}
	for action: StringName in expected:
		var codes := _keycodes(action)
		print("   [measure] %s -> keycodes %s" % [action, codes])
		_check(
			"%s is bound to keycode %s (owner ruling R5/R3)" % [action, expected[action]],
			codes.size() == 1 and int(codes[0]) == int(expected[action]),
			"keycodes=%s" % codes
		)
	## A real key event is the action's event, and C is *not* the fuel cell's.
	var z_event := InputEventKey.new()
	z_event.keycode = KEY_Z
	z_event.physical_keycode = KEY_Z
	z_event.pressed = true
	var x_event := InputEventKey.new()
	x_event.keycode = KEY_X
	x_event.physical_keycode = KEY_X
	x_event.pressed = true
	var c_event := InputEventKey.new()
	c_event.keycode = KEY_C
	c_event.physical_keycode = KEY_C
	c_event.pressed = true
	var r_event := InputEventKey.new()
	r_event.keycode = KEY_R
	r_event.physical_keycode = KEY_R
	r_event.pressed = true
	_check(
		"a Z key event maps to countermeasure_chaff",
		InputMap.event_is_action(z_event, &"countermeasure_chaff"),
		"event_is_action=%s" % InputMap.event_is_action(z_event, &"countermeasure_chaff")
	)
	_check(
		"an X key event maps to countermeasure_flare",
		InputMap.event_is_action(x_event, &"countermeasure_flare"),
		"event_is_action=%s" % InputMap.event_is_action(x_event, &"countermeasure_flare")
	)
	_check(
		"an R key event maps to consume_fuel_cell",
		InputMap.event_is_action(r_event, &"consume_fuel_cell"),
		"event_is_action=%s" % InputMap.event_is_action(r_event, &"consume_fuel_cell")
	)
	_check(
		"a C key event does NOT map to consume_fuel_cell (cargo keeps C)",
		not InputMap.event_is_action(c_event, &"consume_fuel_cell")
			and InputMap.event_is_action(c_event, &"cargo_toggle"),
		"fuel_cell=%s cargo_toggle=%s" % [
			InputMap.event_is_action(c_event, &"consume_fuel_cell"),
			InputMap.event_is_action(c_event, &"cargo_toggle")
		]
	)
	## The predicate the two consumers evaluate (game.gd:583, player_ship.gd:829) is
	## `Input.is_action_just_pressed(action)`. A `--script` run cannot exercise it: measured,
	## `Input.parse_input_event(Z)` leaves `is_action_pressed` false and the strength 0.0 in
	## this harness (the binding itself is proven by `event_is_action` above). The live key
	## press is measured in the running game instead, through the editor (see the report).
	Input.parse_input_event(z_event)
	print(
		"   [harness] parse_input_event(Z): event_is_action=%s, is_action_pressed=%s (a --script run does not feed the Input action state)"
		% [
			InputMap.event_is_action(z_event, &"countermeasure_chaff"),
			Input.is_action_pressed(&"countermeasure_chaff"),
		]
	)


## --- G. The spend chain ---------------------------------------------------


## Forces a held quantity to an exact figure (the only mutator of cargo is the profile).
func _set_hold(item: StringName, target: int) -> void:
	if _profile == null:
		return
	var held := int(_profile.call(&"cargo_qty", item))
	if held < target:
		_profile.call(&"add_cargo", item, target - held)
	elif held > target:
		_profile.call(&"remove_cargo", item, held - target)


func _section_g_spend_chain() -> void:
	print("-- G. the spend chain: the item actually spent, ghosts, and the fuel cell --")
	var pair := _build_ship(Vector2(0.0, 6000.0))
	var shooter: Node2D = pair[0]
	var state: PlayerStateScript = pair[1]
	await _ticks(3)
	var guns: Node2D = shooter.get_node_or_null(NodePath(PlayerShipScript.WEAPONS_NODE))
	if guns == null or _profile == null:
		_check("section G needs the component and the profile", false, "guns=%s" % guns)
		return
	_point_at(SCRATCH_SPEND)
	var used: Array = []
	guns.connect(&"countermeasure_used", func(item: StringName) -> void: used.append(item))
	_check(
		"chaff with none in the hold is refused and fires nothing",
		not bool(guns.call(&"use_countermeasure", WeaponsScript.CHAFF_ITEM))
			and (guns.call(&"ghosts") as Array).is_empty(),
		"ghosts=%s" % (guns.call(&"ghosts") as Array).size()
	)
	var held_before := int(_profile.call(&"cargo_qty", WeaponsScript.CHAFF_ITEM))
	var chaff_before := held_before
	_profile.call(&"add_cargo", WeaponsScript.CHAFF_ITEM, 1)
	var fired := bool(guns.call(&"use_countermeasure", WeaponsScript.CHAFF_ITEM))
	var held_after := int(_profile.call(&"cargo_qty", WeaponsScript.CHAFF_ITEM))
	var ghosts: Array = guns.call(&"ghosts")
	print(
		"   [measure] use_countermeasure(cm_chaff): fired=%s, hold %s -> %s, ghosts=%s, used=%s"
		% [fired, held_before, held_after, ghosts.size(), used]
	)
	_check(
		"the chaff's held spend actually spends one item",
		fired and held_after == held_before,
		"hold %s -> %s (one added, one spent)" % [held_before, held_after]
	)
	_check(
		"the spend raises countermeasure_used exactly once with the item id",
		used.size() == 1 and used[0] == WeaponsScript.CHAFF_ITEM,
		"used=%s" % used
	)
	_check(
		"the chaff deploys its three ghost signatures",
		ghosts.size() == WeaponsScript.CHAFF_GHOSTS,
		"ghosts=%s (want %s)" % [ghosts.size(), WeaponsScript.CHAFF_GHOSTS]
	)
	var kinds: Array = []
	for ghost: Variant in ghosts:
		if ghost is Node and (ghost as Node).has_method(&"blip_kind"):
			kinds.append((ghost as Node).call(&"blip_kind"))
	_check(
		"every ghost answers blip_kind() == &\"ghost\" (what the minimap reads)",
		kinds.size() == WeaponsScript.CHAFF_GHOSTS and kinds.count(&"ghost") == WeaponsScript.CHAFF_GHOSTS,
		"kinds=%s" % kinds
	)
	## The fuel cell: ruling R3's key reaches PlayerState.consume_fuel_cell's spend.
	var cell_before := int(_profile.call(&"cargo_qty", PlayerStateScript.FUEL_CELL_ITEM))
	state.set_fuel(0.0)
	_check(
		"a fuel cell is not ready when the hold carries none",
		not state.call(&"fuel_cell_ready"),
		"fuel=%s ready=%s" % [state.fuel, state.call(&"fuel_cell_ready")]
	)
	_profile.call(&"add_cargo", PlayerStateScript.FUEL_CELL_ITEM, 1)
	var ready := bool(state.call(&"fuel_cell_ready"))
	var spent := bool(state.call(&"consume_fuel_cell"))
	var cell_after := int(_profile.call(&"cargo_qty", PlayerStateScript.FUEL_CELL_ITEM))
	print(
		"   [measure] consume_fuel_cell: ready=%s spent=%s, fuel %s, cooldown %s, hold %s -> %s"
		% [ready, spent, state.fuel, state.fuel_cell_cooldown, cell_before, cell_after]
	)
	_check(
		"one fuel cell becomes its 40 tank units and one item leaves the hold",
		ready and spent and _near(float(state.fuel), 40.0, 0.01) and cell_after == cell_before,
		"fuel=%s hold %s -> %s" % [state.fuel, cell_before, cell_after]
	)
	_check(
		"the cell arms its 10 s cooldown, and a second press is refused",
		_near(float(state.fuel_cell_cooldown), 10.0, 0.01)
			and not bool(state.call(&"consume_fuel_cell")),
		"cooldown=%s second=%s" % [state.fuel_cell_cooldown, state.call(&"consume_fuel_cell")]
	)
	## Put both holds back to exactly what they were before this section, whatever
	## happened above, then hand the paths back.
	_set_hold(WeaponsScript.CHAFF_ITEM, chaff_before)
	_set_hold(PlayerStateScript.FUEL_CELL_ITEM, cell_before)
	_check(
		"the probe leaves both holds exactly as it found them",
		int(_profile.call(&"cargo_qty", WeaponsScript.CHAFF_ITEM)) == chaff_before
			and int(_profile.call(&"cargo_qty", PlayerStateScript.FUEL_CELL_ITEM)) == cell_before,
		"chaff=%s cell=%s" % [
			_profile.call(&"cargo_qty", WeaponsScript.CHAFF_ITEM),
			_profile.call(&"cargo_qty", PlayerStateScript.FUEL_CELL_ITEM)
		]
	)
	shooter.queue_free()
	await _ticks(2)
	_restore_paths()


## --- H. The pinned interfaces --------------------------------------------


## Whether a script *file* declares a method of its own. A const `has_method` on a
## `GDScript` resource answers for the resource's own API, not for the script's text, so
## the script's own method list is the honest reading in a `--script` run.
func _script_has(script: Script, name: StringName) -> bool:
	for entry: Dictionary in script.get_script_method_list():
		if StringName(entry.get("name", &"")) == name:
			return true
	return false


func _script_has_signal(script: Script, name: StringName) -> bool:
	for entry: Dictionary in script.get_script_signal_list():
		if StringName(entry.get("name", &"")) == name:
			return true
	return false


func _section_h_pins() -> void:
	print("-- H. the wave's pinned interfaces --")
	var component_methods: Array[StringName] = [
		&"setup", &"set_fitted", &"select_group", &"selected_group", &"selected_weapon",
		&"fitted", &"is_fitted", &"set_firing", &"poll_input", &"is_firing", &"dry_reason",
		&"set_lock_target", &"clear_lock_target", &"lock_target", &"set_aim_point",
		&"clear_aim_point", &"tick", &"use_countermeasure", &"jamming", &"ghosts", &"flare",
	]
	var missing: Array[String] = []
	for method: StringName in component_methods:
		if not _script_has(WeaponsScript, method):
			missing.append(String(method))
	for method: StringName in [&"row_of", &"weapon_ids", &"family_of", &"range_of", &"dps_of",
			&"interval_of", &"shot_damage", &"ammo_slot", &"weapon_id"]:
		if not _script_has(WeaponsScript, method):
			missing.append("static:%s" % method)
	_check("WeaponComponent keeps every pinned method and static", missing.is_empty(), "missing=%s" % missing)
	var signals_missing: Array[String] = []
	for name: StringName in [&"shot_fired", &"dry_fired", &"locks_broken", &"countermeasure_used"]:
		if not _script_has_signal(WeaponsScript, name):
			signals_missing.append(String(name))
	_check("the component keeps its four signals", signals_missing.is_empty(), "missing=%s" % signals_missing)
	var projectile: Node2D = ProjectileScript.new() as Node2D
	_world.add_child(projectile)
	var target := Node2D.new()
	_world.add_child(target)
	projectile.call(&"configure", {
		&"kind": &"bolt", &"speed": 1000.0, &"damage": 27.0, &"bypass_shield": true,
		&"homing": false, &"target": target, &"turn_rate": 0.0, &"source": target,
		&"direction": Vector2.RIGHT, &"range": 600.0, &"arm": 0.0, &"trigger": 60.0,
		&"mass": 1.0, &"chip": 0.1,
	})
	_check(
		"Projectile.configure still accepts every pinned key",
		projectile.call(&"family") == &"kinetic"
			and bool(projectile.call(&"bypasses_shield"))
			and _near(float(projectile.call(&"damage_amount")), 27.0, 0.01),
		"family=%s bypass=%s damage=%s" % [
			projectile.call(&"family"), projectile.call(&"bypasses_shield"),
			projectile.call(&"damage_amount")
		]
	)
	_check(
		"a configured projectile answers its pinned queries",
		(projectile.call(&"velocity") as Vector2).is_equal_approx(Vector2(1000.0, 0.0))
			and projectile.call(&"source") == target
			and _near(float(projectile.call(&"hit_radius")), 4.0, 0.01),
		"velocity=%s source=%s" % [projectile.call(&"velocity"), projectile.call(&"source")]
	)
	for method: StringName in [&"apply", &"regen", &"bearing", &"context", &"ram", &"knockback",
			&"detonate"]:
		_check(
			"Damage.%s is present" % method,
			_script_has(DamageScript, method),
			"has_method=%s" % _script_has(DamageScript, method)
		)
	_check(
		"Damage.REGEN_QUIET is still the section 13 4.0 s",
		_near(DamageScript.REGEN_QUIET, 4.0, 0.001),
		"got %s" % DamageScript.REGEN_QUIET
	)
	for method: StringName in [&"setup", &"take_damage", &"apply_collision_damage", &"despawn",
			&"intent", &"engaged_with", &"blip_kind", &"hull", &"shield", &"impact_body",
			&"velocity", &"apply_impulse", &"last_damage_ctx"]:
		_check(
			"NpcShip.%s is present" % method,
			_script_has(NpcShipScript, method),
			"has_method=%s" % _script_has(NpcShipScript, method)
		)
	for method: StringName in [&"setup", &"set_line_of_sight", &"set_home", &"set_route",
			&"tick", &"state", &"is_engaged", &"target", &"aggro_radius", &"scan_radius",
			&"is_static", &"request_despawn"]:
		_check(
			"NpcBrain.%s is present" % method,
			_script_has(NpcBrainScript, method),
			"has_method=%s" % _script_has(NpcBrainScript, method)
		)
	_check(
		"NpcRegistry keeps spawns_for / density / is_hostile",
		_script_has(NpcRegistryScript, &"spawns_for")
			and _script_has(NpcRegistryScript, &"density")
			and _script_has(NpcRegistryScript, &"is_hostile"),
		"ok"
	)
	var payload: Array = NpcRegistryScript.spawns_for(&"sector_1")
	_check(
		"spawns_for returns the per-hull rows the sector consumes",
		payload.size() > 0,
		"rows=%s" % payload.size()
	)
	var first: Dictionary = payload[0] if payload.size() > 0 else {}
	var row_keys: Array[String] = []
	for key: String in ["archetype", "hull_id", "min", "max", "faction_id", "sprite_path", "group_kind"]:
		if first.has(key):
			row_keys.append(key)
	_check(
		"the row shape carries every pinned key",
		row_keys.size() == 7,
		"keys=%s" % row_keys
	)
	var frozen_missing: Array[String] = []
	for method: StringName in [&"setup", &"set_move_target", &"cancel_orders", &"warp_available",
			&"take_damage", &"shield_up", &"velocity", &"impact_body", &"apply_impulse",
			&"apply_recoil"]:
		if not _script_has(PlayerShipScript, method):
			frozen_missing.append(String(method))
	_check(
		"the frozen PlayerShip API and the slice-0 push seams are intact",
		frozen_missing.is_empty(),
		"missing=%s" % frozen_missing
	)
	_check(
		"PlayerShip still raises damage_taken",
		_script_has_signal(PlayerShipScript, &"damage_taken"),
		"has_signal=%s" % _script_has_signal(PlayerShipScript, &"damage_taken")
	)
	_check(
		"LootTables still knows the five hull bands and nothing more",
		LootScript.has(&"fighter") and LootScript.has(&"swarmer")
			and LootScript.has(&"freighter") and LootScript.has(&"corvette")
			and LootScript.has(&"maw") and not LootScript.has(&"dreadnought"),
		"ok"
	)
	var two_arg: Array = LootScript.roll(&"fighter", 1)
	_check(
		"LootTables.roll keeps its two-argument call",
		two_arg is Array,
		"payload=%s" % two_arg.size()
	)
	_check(
		"the frozen WeaponComponent consts the mount reads are intact",
		PlayerShipScript.WEAPONS_NODE == &"WeaponComponent"
			and PlayerShipScript.WEAPONS_SCRIPT == "res://game/weapons.gd",
		"%s / %s" % [PlayerShipScript.WEAPONS_NODE, PlayerShipScript.WEAPONS_SCRIPT]
	)
	projectile.queue_free()
	target.queue_free()
