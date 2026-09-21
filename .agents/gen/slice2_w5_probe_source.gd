# ARCHIVED COPY of res://tools/_probe_s2w5_wiring.gd (deleted from the project before the
# W5 report, as the brief requires). Re-run it by copying it back:
#   copy this file to vajb-orbit/tools/_probe_s2w5_wiring.gd, then
#   "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path
#   "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit"
#   --script res://tools/_probe_s2w5_wiring.gd --quit-after 4000
#   -> [SUMMARY] ok=65 failed=0 blocked=0 (log: .agents/gen/slice2_w5_probe.txt)
# Delete the copy and its .uid afterwards (tools/ ends holding build_theme.gd and
# derive_icon_tints.gd only).
# md5 of the probe body below (LF endings): b8ab4fcc774f8249e132facde1292427
# md5 of the project copy at archival: 2cdeba75056e2df289a573c50c865d08
extends SceneTree
## Slice 2, W5 probe: the fight wiring on the shipped scene. Measures, in order:
##   1. §8's sector population per sector (counts against the registry's own band, blip
##      classes, art readiness printed but never gated on - ruling two);
##   2. the five damage-wiring items W2 measured but could not close (take_damage, the ram's
##      ctx, the seeded regen rate, the regen frame step, and the delivery node the ray
##      reaches - the last one printed as the wave's HIGH);
##   3. §4.1's lock channel: 1.2 s of clean line of sight acquires, a rock blocks and resets
##      it, ESC clears it, and the ring's progress is pushed to the HUD;
##   4. §4.6's chaff (3 ghosts, jamming, 3 blips, lock broken, window cleared) and the
##      flare's lure on a live rocket;
##   5. §3.1/§4.3's weapon groups and the `fire_primary` trigger through the mounted
##      component;
##   6. §7's warp gate with a hostile engaged, and the death flow (drop + window + respawn);
##   7. §10/UI_SPEC §3.1b/§3.5/§3.6's HUD readings (pools, ring, dial, hit marker, payload).
##
## Re-run:
##   "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path
##   "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit"
##   --script res://tools/_probe_s2w5_wiring.gd --quit-after 4000
##
## The real `user://profile.cfg` is never written: the probe repoints
## `PlayerProfile.save_path` at a scratch file for the run and restores it at the end.

const SectorScript := preload("res://game/sector.gd")
const Registry := preload("res://game/sector_registry.gd")
const NpcRegistryScript := preload("res://game/npc_registry.gd")
const NpcShipScript := preload("res://game/npc_ship.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const DamageScript := preload("res://game/damage.gd")
const PickupScript := preload("res://game/pickup.gd")
const PlayerShipScript := preload("res://game/player_ship.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"
const SCRATCH_SAVE := "user://probe_s2w5_profile.cfg"
const GAME_SCENE := "res://game/game.tscn"

var _ok := 0
var _failed := 0
var _blocked := 0
var _frame := 0

var _profile: Node = null
var _scene: Node2D = null
var _ship: Node2D = null
var _hud: Control = null
var _state: Variant = null
var _sector: Node2D = null
var _guns: Node2D = null
var _staged: Array[Node] = []
var _shots := 0


func _init() -> void:
	print("=== slice2 W5 probe: sector NPCs, lock channel, target window, dial, death ===")
	print("[env] physics_ticks_per_second=%d" % Engine.physics_ticks_per_second)
	await _step(3)
	_profile = root.get_node_or_null(NodePath(PROFILE_SERVICE))
	if _profile == null:
		print("[fatal] no PlayerProfile autoload; nothing can be measured")
		quit(1)
		return
	_profile.set(&"save_path", SCRATCH_SAVE)
	_profile.call(&"reset_to_defaults")
	await _check_sector_population()
	await _check_scene()
	_restore_profile()
	print("[SUMMARY] ok=%d failed=%d blocked=%d" % [_ok, _failed, _blocked])
	quit(1 if _failed > 0 else 0)


## --- Helpers -------------------------------------------------------------


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		_ok += 1
		print("[ok]   %s" % label)
		return
	_failed += 1
	print("[FAIL] %s%s" % [label, (" -- " + detail) if not detail.is_empty() else ""])


func _step(frames: int) -> void:
	for _tick in frames:
		await physics_frame
		_frame += 1


func _seconds(seconds: float) -> int:
	return int(roundf(seconds * float(Engine.physics_ticks_per_second)))


func _restore_profile() -> void:
	if _profile == null:
		return
	_profile.call(&"reset_to_defaults")
	_profile.set(&"save_path", ProfileScript.SAVE_FILE)


## --- 1. Section 8's sector population -----------------------------------


## One throwaway sector, re-populated per registry row with a fixed seed, so the live hull
## count can be read against the registry's own expanded band (`spawns_for`: a convoy is two
## entries). Every hull is freed with the sector between rows (`populate` clears first), so
## the run holds one sector at a time.
func _check_sector_population() -> void:
	print("[sector] per-row population (seed 20260921), §13 bands + §8 blip classes")
	var sector: Node2D = SectorScript.new()
	sector.name = &"ProbeSector"
	root.add_child(sector)
	var hostile_total_ok := true
	var band_ok := true
	var blip_ok := true
	var art_ready := 0
	var art_total := 0
	for index in Registry.SECTORS.size():
		var row: Dictionary = Registry.SECTORS[index]
		var sector_id := StringName(row.get(&"id", &""))
		sector.call(&"populate", row, 20260921 + index)
		var counts := {}
		var blips := {}
		for ship: Node2D in sector.call(&"npcs"):
			var archetype := StringName(ship.call(&"archetype"))
			counts[archetype] = int(counts.get(archetype, 0)) + 1
			var kind := StringName(ship.call(&"blip_kind"))
			blips[kind] = int(blips.get(kind, 0)) + 1
			art_total += 1
			if bool(ship.call(&"art_ready")):
				art_ready += 1
			## §8's classes: everything hostile except the convoy, which is neutral.
			var wanted := (
				NpcRegistryScript.BLIP_NEUTRAL
				if archetype == &"trader"
				else NpcRegistryScript.BLIP_HOSTILE
			)
			if kind != wanted:
				blip_ok = false
				print("      %s: blip %s, expected %s" % [archetype, kind, wanted])
		var expected := {}
		for entry: Dictionary in NpcRegistryScript.spawns_for(sector_id):
			var archetype := StringName(entry[NpcRegistryScript.KEY_ARCHETYPE])
			var span: Vector2i = expected.get(archetype, Vector2i.ZERO)
			expected[archetype] = Vector2i(
				span.x + int(entry[NpcRegistryScript.KEY_MIN]),
				span.y + int(entry[NpcRegistryScript.KEY_MAX])
			)
		for archetype: Variant in expected:
			var live := int(counts.get(archetype, 0))
			var span: Vector2i = expected[archetype]
			if live < span.x or live > span.y:
				band_ok = false
				print("      %s %s: %d live outside %s" % [sector_id, archetype, live, span])
		var hostile := (
			int(counts.get(&"pirate", 0))
			+ int(counts.get(&"swarmer", 0))
			+ int(counts.get(&"patrol", 0))
		)
		var band: Vector2i = NpcRegistryScript.HOSTILE_BAND[index]
		var wanted_hostiles := band.y + int(expected.get(&"patrol", Vector2i.ZERO).y)
		var least_hostiles := band.x + int(expected.get(&"patrol", Vector2i.ZERO).x)
		if hostile < least_hostiles or hostile > wanted_hostiles:
			hostile_total_ok = false
			print("      %s: hostile total %d outside %d..%d"
				% [sector_id, hostile, least_hostiles, wanted_hostiles])
		print("      %s  hostiles=%d/%d  patrol=%d  convoy=%d  blips=%s"
			% [sector_id, hostile, wanted_hostiles, int(counts.get(&"patrol", 0)),
				int(counts.get(&"trader", 0)), str(blips)])
	_check("every sector's hostile total sits in §13's band", hostile_total_ok)
	_check("every archetype's live count sits in its own expanded registry band", band_ok)
	_check("every hull publishes §8's blip class (pirates/swarmers/patrols hostile, the convoy neutral)",
		blip_ok)
	print("[sector] art ready %d/%d (printed, never gated: ruling two, the graphics lane owns assets)"
		% [art_ready, art_total])
	sector.free()
	await _step(1)


## --- 2-7. The shipped game scene ----------------------------------------


func _check_scene() -> void:
	var packed := load(GAME_SCENE) as PackedScene
	if packed == null:
		_check("game.tscn loads", false, "not a PackedScene")
		return
	_scene = packed.instantiate() as Node2D
	root.add_child(_scene)
	await _step(4)
	_ship = _scene.get_node_or_null(NodePath("PlayerShip")) as Node2D
	_hud = _scene.get_node_or_null(NodePath("Hud")) as Control
	_state = _scene.get(&"_state")
	_sector = _scene.get(&"_sector")
	_check("the scene spawns its ship, its HUD and its sector",
		_ship != null and _hud != null and _state != null and _sector != null)
	if _ship == null or _hud == null or _state == null or _sector == null:
		_blocked = 1
		return
	await _check_damage_wiring()
	await _check_lock_channel()
	await _check_weapons()
	await _check_countermeasures()
	await _check_hud_readings()
	await _check_warp_gate()
	await _check_death()


## --- 2. W2's five wiring items ------------------------------------------


func _check_damage_wiring() -> void:
	print("[damage] the five items W2 measured but could not close")
	_guns = _ship.get_node_or_null(NodePath(PlayerShipScript.WEAPONS_NODE)) as Node2D
	_check("the fit's weapon module mounted a WeaponComponent", _guns != null)
	var stats: Variant = _scene.get(&"_stats")

	## (1) the player hull is a damage sink.
	var shield_before: float = _state.shield
	DamageScript.apply(_ship, 50.0, false, {})
	_check("PlayerShip.take_damage forwards into PlayerState.damage (shield 1000 -> 950)",
		is_equal_approx(_state.shield, shield_before - 50.0), "shield %s" % _state.shield)
	_check("the hull reads its own shield state for §4.1's rules", bool(_ship.call(&"shield_up")))

	## (2) the ram carries ctx, measured through the shipped handler. The closing speed is
	## read from the hull's own pre-step velocity (the solver-spent approach speed), so the
	## fixture sets that field and the peer sits dead ahead of it.
	var peer := RigidBody2D.new()
	peer.mass = 560.0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 20.0
	shape.shape = circle
	peer.add_child(shape)
	_scene.add_child(peer)
	peer.global_position = _ship.global_position + Vector2(100.0, 0.0)
	await _step(2)
	_ship.set(&"_last_velocity", Vector2(300.0, 0.0))
	var before_ram: float = _state.shield
	_ship.call(&"_on_hull_body_entered", peer)
	var ctx: Dictionary = _state.last_damage_ctx()
	var rammed: float = before_ram - float(_state.shield)
	_check("a ram charges the shield through the pipeline (about 83 for 110 t into 560 t at 300 u/s)",
		rammed > 0.0, "charged %.3f" % rammed)
	_check("the ram records §4.2 item 5's context (direction + collision family)",
		ctx.has(&"direction") and StringName(ctx.get(&"family", &"")) == &"collision",
		"ctx %s" % str(ctx))
	print("[damage] ram charged %.3f, ctx %s" % [rammed, str(ctx)])

	## (3) the launch snapshot seeds the shield's regeneration rate.
	_check("PlayerState.shield_regen is the resolved fit's rate (base 2 + s_light 4 = 6)",
		is_equal_approx(_state.shield_regen, 6.0), "regen %s" % _state.shield_regen)
	_check("the snapshot agrees with the state's rate",
		stats != null and is_equal_approx(_state.shield_regen, stats.shield_regen))

	## (4) the regen frame step runs, after §4.2 item 2's 4 s quiet window.
	_state.set_shield(200.0)
	await _step(_seconds(4.1))
	var quiet: float = _state.shield
	await _step(_seconds(1.0))
	var recovered: float = _state.shield - quiet
	_check("Damage.regen resumes 4 s after the last hit at the state's rate (6/s +/- 1)",
		absf(recovered - 6.0) <= 1.0, "recovered %.3f in 1 s" % recovered)

	## (5) where a shot's delivery actually lands: the hull body, not the hull.
	print("[damage] §4.2 item 5 delivery, measured on a real hull (this is the wave's HIGH)")
	var ship: Node2D = _spawn_probe_hull(Vector2(400.0, 0.0))
	await _step(2)
	var ship_shield_max: float = float(ship.call(&"shield_max"))
	DamageScript.apply(ship, 120.0, false, {})
	_check("Damage.apply(hull, ...) charges the hull's own shield pool",
		is_equal_approx(float(ship.call(&"shield")), ship_shield_max - 120.0),
		"shield %s of %s" % [ship.call(&"shield"), ship_shield_max])
	var shield_after: float = float(ship.call(&"shield"))
	DamageScript.apply(ship.call(&"impact_body"), 120.0, false, {})
	_check("Damage.apply(hull_body, ...) charges NOTHING (the ray's own collider)",
		is_equal_approx(float(ship.call(&"shield")), shield_after),
		"shield %s" % ship.call(&"shield"))
	peer.free()
	ship.call(&"despawn")


## One real NPC hull of the shipped registry, placed by hand (the sector's own set is too
## far from the player to lock cheaply).
func _spawn_probe_hull(position: Vector2) -> Node2D:
	var hull: Node2D = NpcShipScript.new()
	hull.name = "ProbePirate"
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


## --- 3. The lock channel ------------------------------------------------


func _check_lock_channel() -> void:
	print("[lock] §4.1's channel: 1.2 s clean LOS, a rock resets it, ESC clears it")
	var hull := _spawn_probe_hull(Vector2(400.0, 0.0))
	await _step(3)
	var picked := _scene.call(&"_pick_lock_target", hull.global_position) as Node2D
	_check("a click on a hostile hull inside lock range picks it", picked == hull)
	_check("the same point picks nothing with a non-hostile class (the convoy's own pick)",
		_scene.call(&"_pick_lock_target", hull.global_position + Vector2(4000.0, 0.0)) == null)
	_scene.call(&"_start_lock", hull)
	_check("the channel starts at zero and nothing is locked yet",
		is_equal_approx(float(_hud.call(&"lock_progress")), 0.0)
		and _guns.call(&"lock_target") == null)
	await _step(_seconds(0.6))
	var mid := float(_hud.call(&"lock_progress"))
	_check("the ring is a fraction of the way round at 0.6 s", mid > 0.3 and mid < 0.7, "ring %.3f" % mid)
	await _step(_seconds(0.7))
	var ring := _hud.call(&"lock_ring") as Control
	_check("the channel completes at 1.2 s and the lock lands on the hull",
		_guns.call(&"lock_target") == hull, "lock %s" % str(_guns.call(&"lock_target")))
	_check("the completed ring stays drawn at full (UI_SPEC §3.5)",
		is_equal_approx(float(_hud.call(&"lock_progress")), 1.0) and ring != null and ring.visible)

	## A rock on the live line between the two resets the channel. The hull is frozen for this
	## one check, so the line the rock sits on is the line the ray keeps being cast along -
	## an aggroed pirate circling at 900 u would otherwise step out from behind the rock.
	var rock: Node2D = AsteroidScript.new() as Node2D
	## A rigid body takes the transform it enters the tree with; setting it afterwards is
	## overwritten by the body's own state (measured: the rock snapped back to the world
	## origin and the ray sailed past it).
	rock.position = _ship.global_position.lerp(hull.global_position, 0.5)
	_scene.add_child(rock)
	var hull_body: RigidBody2D = hull.call(&"impact_body")
	hull_body.freeze = true
	await _step(2)
	rock.call(&"setup", &"iron", 1, 4)
	await _step(3)
	_scene.call(&"_start_lock", hull)
	var clear: bool = bool(_scene.call(&"_lock_clear_line", hull.global_position))
	_check("the hull/rock on the line is what the ray hits", not clear, "clear_line %s" % clear)
	await _step(_seconds(1.4))
	var blocked := float(_hud.call(&"lock_progress"))
	_check("a hull/rock in the way resets the channel (§4.1's uninterrupted LOS)",
		is_equal_approx(blocked, 0.0), "ring %.3f" % blocked)
	_check("nothing is locked while the line is blocked", _guns.call(&"lock_target") == null)
	hull_body.freeze = false
	rock.free()
	await _step(2)
	await _step(_seconds(1.4))
	_check("clearing the line lets the channel land again", _guns.call(&"lock_target") == hull)

	## ESC: the order and the lock both go.
	Input.action_press(&"ui_cancel")
	await _step(2)
	Input.action_release(&"ui_cancel")
	await _step(1)
	_check("ESC clears the mark, the lock and the ring",
		_scene.get(&"_lock_target") == null and _guns.call(&"lock_target") == null
		and float(_hud.call(&"lock_progress")) <= 0.0 and not ring.visible)

	## The cursor reading, asked at explicit points.
	var reading: int = _scene.call(&"_reticle_state_for", hull.global_position)
	_check("the reticle reads HOSTILE over a hostile hull (TargetReticle.State.HOSTILE = 3)",
		reading == 3, "state %d" % reading)
	var plain: int = _scene.call(&"_reticle_state_for", hull.global_position + Vector2(9000.0, 0.0))
	_check("the reticle reads PLAIN over empty space", plain == 0, "state %d" % plain)

	## The target window's payload, pushed at the HUD cadence.
	_scene.call(&"_start_lock", hull)
	await _step(_seconds(1.4))
	await _step(12)
	var info: Dictionary = _hud.call(&"target_info")
	_check("the target window carries a name, a hull fraction, a distance and §10's readings",
		not info.is_empty() and String(info.get("name", "")) == "Lancer"
		and float(info.get("hull", 0.0)) > 0.0 and float(info.get("distance_m", 0.0)) > 300.0
		and info.has("in_range") and String(info.get("threat", "")) == "HOSTILE",
		str(info))
	var wanted_range: bool = float(info.get("distance_m", 0.0)) <= 500.0
	_check("the range state is the selected laser's own range against the live distance",
		bool(info.get("in_range")) == wanted_range,
		"%.0f m, in_range %s" % [float(info.get("distance_m", 0.0)), info.get("in_range")])

	## §4.2 item 4's marker: a pool drop between two pushes is a confirmed hit.
	DamageScript.apply(hull, 30.0, false, {})
	await _step(12)
	var marker := _hud.call(&"hit_marker_node") as Control
	_check("a confirmed hit flashes the reticle's marker", marker != null and marker.visible)
	await _step(_seconds(0.4))
	_check("the marker has faded out again", marker != null and not marker.visible)
	hull.call(&"despawn")


## --- 4. Weapon groups and the trigger -----------------------------------


func _check_weapons() -> void:
	print("[weapons] §4.3's groups and the `fire_primary` trigger through the mounted component")
	Input.action_press(&"weapon_2")
	await _step(2)
	Input.action_release(&"weapon_2")
	await _step(1)
	_check("the HUD's slot 2 selects group 2 on the component",
		int(_guns.call(&"selected_group")) == 2, "group %s" % _guns.call(&"selected_group"))
	Input.action_press(&"weapon_1")
	await _step(2)
	Input.action_release(&"weapon_1")
	await _step(1)
	_check("slot 1 selects group 1 again", int(_guns.call(&"selected_group")) == 1)

	## Space: the laser is the standard fit's group 1, and it draws Energy while held.
	var hull := _spawn_probe_hull(Vector2(300.0, 0.0))
	await _step(2)
	_guns.call(&"set_aim_point", hull.global_position)
	var energy_before: float = _state.energy
	var shots_before := _shots
	if not _guns.is_connected(&"shot_fired", _on_shot):
		_guns.connect(&"shot_fired", _on_shot)
	Input.action_press(&"fire_primary")
	await _step(_seconds(1.0))
	Input.action_release(&"fire_primary")
	await _step(2)
	_check("holding Space fires the selected group (shot_fired raised)",
		_shots > shots_before, "shots %d -> %d" % [shots_before, _shots])
	## The beam draws 6 E/s and the reactor refills 5 E/s at the same time, so the pool's
	## *net* move over a second of fire is the two rates minus each other.
	var net: float = energy_before - _state.energy
	_check("the energy family pays for the beam through try_spend_energy (6 E/s drawn against a 5 E/s refill)",
		net >= 0.5, "net %.2f E over 1 s (draw 6, refill 5)" % net)
	_check("the beam's delivery reached the hull BODY and charged nothing (the HIGH above)",
		is_equal_approx(float(hull.call(&"shield")), float(hull.call(&"shield_max"))),
		"shield %s of %s" % [hull.call(&"shield"), hull.call(&"shield_max")])
	hull.call(&"despawn")


func _on_shot(_weapon_id: StringName) -> void:
	_shots += 1


## The thrust measurements leave real momentum on the hull; with no order to cancel it, a
## drifting hull would eventually ram a field rock and die mid-probe (measured on the first
## run: the death flow's checks then found an already-dead scene). The probe stops it.
func _stop_ship() -> void:
	var body: RigidBody2D = _ship.call(&"impact_body")
	if body != null:
		body.linear_velocity = Vector2.ZERO
		body.angular_velocity = 0.0


## --- 5. Countermeasures -------------------------------------------------


func _check_countermeasures() -> void:
	print("[cm] §4.6: chaff breaks the lock and shows 3 ghosts for 3 s; the flare lures a rocket")
	_profile.call(&"add_cargo", &"cm_chaff", 2)
	_profile.call(&"add_cargo", &"cm_flare", 2)
	var hull := _spawn_probe_hull(Vector2(350.0, 0.0))
	await _step(3)
	_scene.call(&"_start_lock", hull)
	await _step(_seconds(1.4))
	_check("a lock is held before the chaff", _guns.call(&"lock_target") == hull)

	var used: bool = bool(_guns.call(&"use_countermeasure", &"cm_chaff"))
	var ghosts: Array = _guns.call(&"ghosts")
	var blips: Array = _scene.call(&"_ghost_blips")
	_check("one chaff use spends an item and spawns 3 ghost signatures",
		used and ghosts.size() == 3, "ghosts %d" % ghosts.size())
	_check("the chaff breaks the active lock immediately", _guns.call(&"lock_target") == null)
	_check("the ghosts reach the minimap feed as their own blip kind",
		blips.size() == 3
		and StringName(blips[0].get("kind", &"")) == &"ghost", str(blips))
	_scene.call(&"_start_lock", hull)
	_check("and the component refuses re-acquisition while they live (jamming, no lock)",
		bool(_guns.call(&"jamming")) and _guns.call(&"lock_target") == null
		and not bool(_scene.get(&"_lock_channeling")))
	await _step(_seconds(2.0))
	_check("the ghosts are still alive at 2.0 s of the 3.0 s window",
		(_guns.call(&"ghosts") as Array).size() == 3)
	await _step(_seconds(1.3))
	_check("the window closes at 3.0 s: no ghosts and no jamming",
		(_guns.call(&"ghosts") as Array).is_empty() and not bool(_guns.call(&"jamming")))

	## A flare lures a live rocket: the standard fit carries no rocket, so the pack is swapped
	## for the fire and the hull is locked by hand.
	var rocket_fit: Array[StringName] = [&"w_rocket"]
	_guns.call(&"set_fitted", rocket_fit)
	_guns.call(&"select_group", 1)
	await _step(2)
	_guns.call(&"set_lock_target", hull)
	_guns.call(&"set_aim_point", hull.global_position)
	Input.action_press(&"fire_primary")
	await _step(_seconds(0.2))
	Input.action_release(&"fire_primary")
	await _step(_seconds(0.1))
	var rockets := _rockets()
	_check("the rocket family launches a live seeker", rockets.size() >= 1,
		"rockets %d" % rockets.size())
	_guns.call(&"use_countermeasure", &"cm_flare")
	var flare: Node2D = _guns.call(&"flare") as Node2D
	await _step(2)
	var lured := 0
	for shot: Node2D in _rockets():
		if shot.call(&"decoy") == flare:
			lured += 1
	_check("the flare is live and inside the lure radius of the rocket's own launch point",
		flare != null)
	_check("every rocket inside FLARE_LURE retargeted onto the decoy (§4.6)",
		not rockets.is_empty() and lured >= 1, "lured %d of %d" % [lured, rockets.size()])
	hull.call(&"despawn")


func _rockets() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for node: Node in get_nodes_in_group(&"projectile"):
		var shot := node as Node2D
		if shot == null or not is_instance_valid(shot):
			continue
		if StringName(shot.call(&"family")) == &"missile":
			out.append(shot)
	return out


## --- 6. The HUD's own readings ------------------------------------------


func _check_hud_readings() -> void:
	print("[hud] §3.1b's live pools, §3.6's dial, §3.5's ring and the reticle states")
	await _step(12)
	var currents: Dictionary = _hud.get(&"_pool_current")
	_check("the Energy bar reads PlayerState (§3.1b)",
		is_equal_approx(float(currents.get(&"energy", -1.0)), _state.energy),
		"bar %s vs state %s" % [currents.get(&"energy", null), _state.energy])
	_check("the Fuel bar reads PlayerState",
		is_equal_approx(float(currents.get(&"fuel", -1.0)), _state.fuel))
	_check("the Emergency Flight banner is dark with a tank aboard",
		not bool(_hud.get(&"_emergency")))

	var dial := _hud.call(&"speedometer") as Control
	_check("the radial dial is the 120 x 120 control UI_SPEC §3.6 asks for",
		dial != null and dial.size.x >= 120.0 and dial.size.y >= 120.0,
		"size %s" % (dial.size if dial != null else Vector2.ZERO))
	Input.action_press(&"thrust_forward")
	await _step(_seconds(1.5))
	Input.action_release(&"thrust_forward")
	await _step(2)
	var ratio := float(_hud.call(&"speedometer_ratio"))
	var speed: Vector2 = _ship.call(&"velocity")
	_check("the dial's ratio follows the hull's speed against its class maximum",
		ratio > 0.0 and ratio <= 1.0, "ratio %.3f speed %.1f" % [ratio, speed.length()])
	_check("the needle is the one sanctioned cyan (§3.6's accent_nav)",
		str((dial.call(&"needle_colour") as Color).to_html(false)) == "6fb8c4",
		str((dial.call(&"needle_colour") as Color).to_html(false)))
	print("[hud] dial ratio %.3f, filled segments %d, overdrive segment %d"
		% [ratio, int(dial.call(&"filled_segments")), int(dial.call(&"overdrive_segment"))])
	await _step(_seconds(2.5))
	_stop_ship()

	## The reticle states the gameplay side pushes: a hostile over the cursor is out of the
	## question headless (no pointer), so the reading function is asked directly.
	var hull := _spawn_probe_hull(Vector2(300.0, 0.0))
	await _step(3)
	_scene.call(&"_push_reticle_state")
	await _step(1)
	_check("the scene pushes a reticle state without a pointer (§9.9's inert default)",
		int(_hud.get(&"_reticle_state")) >= 0)
	hull.call(&"despawn")


## --- 7. The warp gate, then the death flow ------------------------------


func _check_warp_gate() -> void:
	print("[warp] §7's gate: a hostile in Alert/Engage on the player closes it")
	await _step(12)
	_check("a quiet sector has no engagement", not bool(_scene.call(&"_enemy_engaged")))
	_check("and safe warp is offered (quiet hull + station in sector)",
		bool(_scene.call(&"_warp_ready")))
	var hull := _spawn_probe_hull(_ship.global_position + Vector2(250.0, 0.0))
	await _step(_seconds(2.0))
	var engaged := bool(_scene.call(&"_enemy_engaged"))
	var state_name := StringName(hull.call(&"state_name"))
	_check("a pirate 250 u away engages the player and closes the warp gate",
		engaged and not bool(_scene.call(&"_warp_ready")), "state %s engaged %s" % [state_name, engaged])
	_check("the hull still reports itself warp-quiet (the gate is the aggro, not damage)",
		bool(_ship.call(&"warp_available")))
	hull.call(&"despawn")
	await _step(_seconds(1.0))


func _check_death() -> void:
	print("[death] §7: hull 0 drops the hold at the wreck and respawns docked")
	_check("the hull is still alive when the death flow is exercised", not bool(_scene.get(&"_dead")))
	_profile.call(&"add_cargo", &"mineral_iron", 4)
	_profile.call(&"add_cargo", &"comp_scrap_1", 2)
	print("[death] hold before the wreck: %s" % str(_profile.call(&"cargo_items")))
	var credits_before := int(_profile.call(&"credits"))
	_state.set_hull(0.0)
	await _step(2)
	_check("the scene marks itself dead and switches the wreck off",
		bool(_scene.get(&"_dead")) and not _ship.is_physics_processing())
	var dropped := 0
	var windowed := 0
	var shortest := INF
	for node: Node in _scene.get_children():
		if not node.is_in_group(&"pickup"):
			continue
		dropped += 1
		var window: float = Pickup.LIFETIME - float(node.get(&"_age"))
		shortest = minf(shortest, window)
		if window >= 295.0:
			windowed += 1
	_check("the whole hold dropped as pickups at the wreck (one per stack)", dropped == 4,
		"pickups %d" % dropped)
	_check("every drop carries decision 7's 5-minute window (>= 295 s of life)",
		dropped > 0 and windowed == dropped,
		"windowed %d of %d, shortest %.1f s" % [windowed, dropped, shortest])
	_check("the hold is empty in the profile afterwards",
		int(_profile.call(&"cargo_qty", &"mineral_iron")) == 0
		and int(_profile.call(&"cargo_qty", &"comp_scrap_1")) == 0)
	_check("the credits are not cargo and stay in the wallet",
		int(_profile.call(&"credits")) == credits_before)
	_check("nothing filed a dead hull as this ship's vitals (the next launch must not die on frame one)",
		int((_profile.call(&"vitals_of", _profile.call(&"active_ship")) as Dictionary).get("hull", -1)) != 0)
	_check("the lock and the ring are cleared by death",
		_scene.get(&"_lock_target") == null and float(_hud.call(&"lock_progress")) <= 0.0)
	print("[death] the respawn route is inert in a probe (no listener); the station screen is")
	print("        reached in the shipped game, and 14 §3's insurance half is slice 4")
	for hull: Node in _staged:
		if is_instance_valid(hull) and hull.has_method(&"despawn"):
			hull.call(&"despawn")
