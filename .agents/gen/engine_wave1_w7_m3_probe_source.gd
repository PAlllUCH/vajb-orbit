extends Node
## Engine wave 1 batch 2 - M3 W-slot gate probe (throwaway; archived under
## .agents/gen/ after the run, then deleted with its .uid sidecar).
## A scene run, not a --script run (game.gd's autoload references do not resolve in
## a custom main loop). Self-quitting, with a 90 s watchdog.
##
## M3, per the owner's ruling: the mining laser is mounted, and `E` mines, only when
## the resolved fit carries `w_mining` (09 section 4.5, ENGINE_SPEC sections 4.3/6).
## Cases: the fit data gate; the standard fit (no module) on the shipped
## player_ship.tscn; a fit with `w_mining` on the same scene and the same geometry
## (the positive control that proves the negative control measures the gate and not
## a broken harness); the pinned two-argument `setup` call; and the live game.tscn
## launch ship. A [FAIL] line means the gate is not in force.

const PlayerShipScene := preload("res://game/player_ship.tscn")
const PlayerShipScript := preload("res://game/player_ship.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const EconomyLogScript := preload("res://game/economy_log.gd")

const SCRATCH_PROFILE := "user://_probe_m3_profile.cfg"
const SCRATCH_LOG := "user://_probe_m3_log.txt"

## Stand-off from the cursor point to the rock's centre: inside MINE_LASER_RANGE
## (220 u), so the beam reaches, and outside the pickup TRACTOR_RANGE (120 u), so a
## spawned pickup is never collected and no unrelated profile write can happen.
const STANDOFF := 200.0
const ROCK_YIELD := 3
## 100 frames at 60 Hz = 1.67 s: one 1.2 s cycle plus margin, and short of two.
const CYCLE_FRAMES := 100

## The 09 section 7 standard shape with the laser bought instead of the gun: the
## same hull, the same mandatory pair, one W slot spent on the tool.
const MINING_FIT: Dictionary = {
	&"engine": &"e_std",
	&"power": &"p_std",
	&"weapons": [&"w_mining"],
	&"shields": [&"s_light"],
	&"armour": [&"h_plate_light"],
	&"computers": [],
	&"boosters": [],
	&"utility": [],
}

var _checks := 0
var _fails := 0
var _profile: Node = null
var _game: Node = null


func _ready() -> void:
	_watchdog()
	_run()


func _watchdog() -> void:
	await get_tree().create_timer(90.0).timeout
	print("WATCHDOG: probe did not finish in 90 s")
	get_tree().quit(2)


func _check(label: String, ok: bool, detail: String) -> void:
	_checks += 1
	if not ok:
		_fails += 1
	print("%s %s | %s" % ["[OK]  " if ok else "[FAIL]", label, detail])


func _run() -> void:
	_profile = get_tree().root.get_node_or_null(NodePath("PlayerProfile"))
	if _profile != null:
		_profile.set(&"save_path", SCRATCH_PROFILE)
	EconomyLogScript.log_path = SCRATCH_LOG

	_fit_gate()
	await _mining_case("the 09 section 7 standard fit (no w_mining)", ShipFit.STANDARD_FIT, false)
	await _mining_case("a fit with w_mining", MINING_FIT, true)
	await _pinned_call()
	await _launch_scene()

	print("=== m3 gate probe: checks %d, failures %d ===" % [_checks, _fails])
	_cleanup()
	get_tree().quit(1 if _fails > 0 else 0)


## M3 a: the gate reads the resolved fit's module ids, so measure the ids.
func _fit_gate() -> void:
	print("--- M3 a: the resolved fit's module ids ---")
	var standard := ShipFit.fitted_ids(ShipFit.STANDARD_FIT)
	var mining := ShipFit.fitted_ids(MINING_FIT)
	var module := PlayerShipScript.MINING_MODULE
	print("MINING_MODULE=%s ; standard fit ids=%s ; mining fit ids=%s" % [
		module, standard, mining,
	])
	_check("M3 a1: the standard fit carries no w_mining",
		not standard.has(module), "ids=%s" % [standard])
	_check("M3 a2: a fit with w_mining resolves with the module in its ids",
		mining.has(module) and ShipFit.resolve(&"ship_vanguard", MINING_FIT) != null,
		"ids=%s" % [mining])


## M3 b/c: identical geometry both times - the ship is parked 200 u from the rock
## under the cursor (the beam's own cursor ray) and `mine` is held for one cycle.
## The only difference between the two runs is the fit's module ids.
func _mining_case(label: String, fit: Dictionary, expect_mining: bool) -> void:
	print("--- M3: mining on %s ---" % label)
	var ids := ShipFit.fitted_ids(fit)
	var stats: ShipStats = ShipFit.resolve(&"ship_vanguard", fit)
	var state: PlayerState = PlayerStateScript.new()
	state.setup()
	var ship: Node2D = PlayerShipScene.instantiate() as Node2D
	add_child(ship)
	ship.call(&"setup", stats, state, ids)
	await get_tree().physics_frame
	var cursor := ship.get_global_mouse_position()
	ship.global_position = cursor - Vector2(STANDOFF, 0.0)
	var rock: Node2D = AsteroidScript.new()
	add_child(rock)
	rock.call(&"setup", &"iron", 1, ROCK_YIELD)
	rock.global_position = cursor
	await get_tree().physics_frame
	await get_tree().physics_frame

	var laser := ship.get_node_or_null(NodePath(PlayerShipScript.MINING_LASER_NODE))
	var reach := ship.global_position.distance_to(rock.global_position)
	var before := int(rock.get(&"yield_units"))
	Input.action_press(&"mine")
	for _frame: int in CYCLE_FRAMES:
		await get_tree().physics_frame
	Input.action_release(&"mine")
	var after := int(rock.get(&"yield_units"))
	var pickups := get_tree().get_nodes_in_group(&"pickup").size()
	print("laser=%s cursor=%s ship=%s rock=%s reach=%s ; rock yield %d -> %d ; pickups %d" % [
		laser, cursor, ship.global_position, rock.global_position, reach,
		before, after, pickups,
	])
	var mounted := laser != null
	if expect_mining:
		_check("M3 b: with w_mining the laser mounts and E mines one unit per cycle",
			mounted and after == before - 1 and pickups == 1 and reach <= 220.0,
			"laser=%s yield %d -> %d pickups=%d reach=%s" % [
				mounted, before, after, pickups, reach,
			])
	else:
		_check("M3 c: without w_mining no laser mounts and E mines nothing",
			not mounted and after == before and pickups == 0 and reach <= 220.0,
			"laser=%s yield %d -> %d pickups=%d reach=%s" % [
				mounted, before, after, pickups, reach,
			])

	if is_instance_valid(ship):
		ship.queue_free()
	if is_instance_valid(rock):
		rock.queue_free()
	## The positive case's pickup is probe residue (the stand-off keeps it out of
	## tractor range), so clear it before the next case counts.
	for pickup: Node in get_tree().get_nodes_in_group(&"pickup"):
		pickup.queue_free()
	await get_tree().physics_frame
	await get_tree().physics_frame


## M3 d: the pinned API keeps working - `setup(stats, state)`, the shape game.gd and
## the wave-1 probes call. The fit argument is additive with an empty default, and
## an empty fit mounts nothing.
func _pinned_call() -> void:
	print("--- M3 d: the pinned two-argument setup(stats, state) call ---")
	var stats: ShipStats = ShipFit.resolve(&"ship_vanguard", ShipFit.STANDARD_FIT)
	var state: PlayerState = PlayerStateScript.new()
	state.setup()
	var ship: Node2D = PlayerShipScene.instantiate() as Node2D
	add_child(ship)
	ship.call(&"setup", stats, state)
	await get_tree().physics_frame
	var laser := ship.get_node_or_null(NodePath(PlayerShipScript.MINING_LASER_NODE))
	print("pinned setup(stats, state): laser=%s hull_max=%s ship group=%s" % [
		laser, state.hull_max, ship.is_in_group(&"player_ship"),
	])
	_check("M3 d: the pinned call still runs (no W slot, so no laser)",
		laser == null and state.hull_max > 0.0 and ship.is_in_group(&"player_ship"),
		"laser=%s hull_max=%s" % [laser, state.hull_max])
	if is_instance_valid(ship):
		ship.queue_free()
	await get_tree().physics_frame


## M3 e: the shipped launch, end to end. The v1 launch resolves the standard fit, so
## the launch ship must carry no laser, the HUD reticle must stay PLAIN while `mine`
## is held, and no pickup may appear.
func _launch_scene() -> void:
	print("--- M3: the live game.tscn launch ship ---")
	_game = (load("res://game/game.tscn") as PackedScene).instantiate()
	add_child(_game)
	for _frame: int in 5:
		await get_tree().physics_frame
	var ship: Node2D = _game.get(&"_ship")
	var game_laser: Node = _game.get(&"_laser")
	var mounted := ship != null and ship.get_node_or_null(
		NodePath(PlayerShipScript.MINING_LASER_NODE)) != null
	var pickups_before := get_tree().get_nodes_in_group(&"pickup").size()
	Input.action_press(&"mine")
	for _frame: int in CYCLE_FRAMES:
		await get_tree().physics_frame
	Input.action_release(&"mine")
	var pickups := get_tree().get_nodes_in_group(&"pickup").size() - pickups_before
	var reticle := int(_game.get(&"_reticle_state"))
	var state: PlayerState = _game.get(&"_state")
	print("live ship=%s game._laser=%s ship laser=%s reticle_state=%d (PLAIN=%d) ; hold=%d hull=%s" % [
		ship, game_laser, mounted, reticle, TargetReticle.State.PLAIN,
		state.cargo_max, state.hull_max,
	])
	_check("M3 e: the launch ship mounts no laser, E mines nothing, reticle stays plain",
		ship != null and game_laser == null and not mounted
			and reticle == TargetReticle.State.PLAIN and pickups == 0
			and state.cargo_max > 0,
		"ship=%s game._laser=%s mounted=%s reticle=%d pickups=%d hold=%d" % [
			ship, game_laser, mounted, reticle, pickups, state.cargo_max,
		])


## The profile flushes its debounced write at exit, which would recreate a scratch
## file after this cleanup. Nothing here is worth persisting and the owner's own
## file was never the write target, so the dirty flag and the debounce are cleared
## first.
func _cleanup() -> void:
	if _profile != null:
		var timer := _profile.get(&"_save_timer") as Timer
		if timer != null:
			timer.stop()
		_profile.set(&"_dirty", false)
	for path: String in [SCRATCH_PROFILE, SCRATCH_LOG]:
		if FileAccess.file_exists(path):
			var absolute := ProjectSettings.globalize_path(path)
			print("cleanup %s -> error %d" % [absolute, DirAccess.remove_absolute(absolute)])
