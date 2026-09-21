extends Node
## slice-0 M5 fix probe: the hull side of the reactor chain that the M4 review measured
## as unwired (findings F2-F5).
##
## The four behaviours the review measured have their own probe, re-run here exactly as
## the review left it: `res://tools/_probe_s0m4_live.tscn` (restored from
## `.agents/gen/slice0_m4_probe_live.{gd,tscn}` and deleted again before this report;
##  the before/after logs are `.agents/gen/slice0_m5_probe_live_{before,after}.txt`).
## This probe covers what that one could not, and each check cites its spec section:
##
##  * F3  the section 13 rows `BOOST_FUEL` 3.0 / `DASH_FUEL` 25 have one shipping-code
##        owner and it is the hull, not the fit (the review's other choice).
##  * F5  the C key's *caller*: M4's check only proved the input action exists. The
##        action is put down here the way a real press behaves -- four physics frames
##        down, released on the fifth -- so a held key is one edge and repeated presses
##        are separate edges, which is what section 11 asks for.
##  * F2  the reach of ruling 14's lock: it takes thrust from the autopilot as well as
##        from the stick, and it leaves the reaction wheels live.
##  * F3  the burn is charged per frame, so a tank that runs dry mid-burn ends it
##        instead of burning on credit.
##
## Re-run:
##   "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path
##   "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tools/_probe_s0m5_reactor.tscn
##   --quit-after 2400

const PlayerShipScene := preload("res://game/player_ship.tscn")
const WitnessScript := preload("res://tools/_probe_s0m5_witness.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const HULL_SCRIPT := "res://game/player_ship.gd"
const FIT_SCRIPT := "res://game/ship_fit.gd"

const HULL_ID: StringName = &"ship_fighter"
const C_ACTION: StringName = &"consume_fuel_cell"
const BOOST_ACTION: StringName = &"boost"
const TURN_RIGHT: StringName = &"turn_right"

## Four frames down, released on the fifth: one `is_action_just_pressed` edge.
const HOLD_FRAMES := 4
const BOOST_FIT := {
	&"engine": &"e_std",
	&"power": &"p_std",
	&"weapons": [&"w_mining"],
	&"shields": [&"s_light"],
	&"armour": [&"h_plate_light"],
	&"computers": [],
	&"boosters": [&"b_afterburner"],
	&"utility": [],
}

var _ok := 0
var _failed := 0
var _state: PlayerState = null
var _ship: Node2D = null
var _press_left := 0
var _pressed_action: StringName = &""


func _ready() -> void:
	_watchdog()
	_run()


## The press generator. The probe root joined the `physics_process` group before the
## hull did (the hull is instantiated in `_ready`), so a press put down here lands on
## the same physics frame the hull polls: that is how a real key behaves. A press that
## arrives after the hull's step would be a frame late and is the failure this ordering
## rules out.
func _physics_process(_delta: float) -> void:
	if _press_left <= 0:
		return
	_press_left -= 1
	if _press_left <= 0:
		Input.action_release(_pressed_action)
		return
	Input.action_press(_pressed_action, 1.0)


func _watchdog() -> void:
	await get_tree().create_timer(150.0).timeout
	print("WATCHDOG: probe did not finish")
	get_tree().quit(2)


func _check(label: String, passed: bool, detail: String) -> void:
	if passed:
		_ok += 1
		print("[OK]   %s | %s" % [label, detail])
	else:
		_failed += 1
		print("[FAIL] %s | %s" % [label, detail])


func _ticks(seconds: float) -> void:
	for _i in int(round(seconds * float(Engine.physics_ticks_per_second))):
		await get_tree().physics_frame


func _press(action: StringName, frames: int) -> void:
	_pressed_action = action
	_press_left = frames


func _body() -> RigidBody2D:
	return _ship.call(&"impact_body") as RigidBody2D


func _speed() -> float:
	var body := _body()
	return body.linear_velocity.dot(Vector2.RIGHT.rotated(body.global_rotation))


func _place(pos: Vector2) -> void:
	var body := _body()
	body.linear_velocity = Vector2.ZERO
	body.angular_velocity = 0.0
	body.global_position = pos
	body.global_rotation = 0.0
	_ship.call(&"cancel_orders")
	await get_tree().physics_frame


func _release_all() -> void:
	for action: StringName in [&"thrust_forward", &"thrust_backward", &"turn_left",
		&"turn_right", BOOST_ACTION, &"mine", C_ACTION]:
		if InputMap.has_action(action):
			Input.action_release(action)


func _run() -> void:
	print("=== slice0 M5 probe: reactor chain's hull side (F2-F5) ===")
	var world := Node2D.new()
	add_child(world)
	_ship = PlayerShipScene.instantiate()
	world.add_child(_ship)
	var stats: ShipStats = ShipFitScript.resolve(HULL_ID, BOOST_FIT)
	_state = WitnessScript.new()
	_state.hull_max = stats.hull_max
	_state.shield_max = stats.shield_max
	_state.cargo_max = stats.cargo_max
	_state.setup()
	_ship.call(&"setup", stats, _state)
	await _ticks(0.2)

	await _report_const_owner()
	await _report_fuel_cell_key()
	await _report_emergency_reach()
	await _report_dry_burn()
	_release_all()
	print("[SUMMARY] ok=%d failed=%d" % [_ok, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


## F3: section 13's two fuel rows, and the single owner they were missing.
func _report_const_owner() -> void:
	## `load`ed into Variants rather than preloaded as typed consts: a preloaded
	## `class_name` script resolves to the class itself, and the constant map is an
	## instance-level call the analyzer refuses on a class.
	var hull_script: Variant = load(HULL_SCRIPT)
	var fit_script: Variant = load(FIT_SCRIPT)
	var hull_consts: Dictionary = hull_script.get_script_constant_map()
	var fit_consts: Dictionary = fit_script.get_script_constant_map()
	_check("owner: the hull declares section 13's afterburner burn (BOOST_FUEL 3.0)",
		hull_consts.has("BOOST_FUEL") and is_equal_approx(float(hull_consts["BOOST_FUEL"]), 3.0),
		"PlayerShip.BOOST_FUEL = %s" % hull_consts.get("BOOST_FUEL", "absent"))
	_check("owner: the hull declares section 13's fold/dash cost (DASH_FUEL 25)",
		hull_consts.has("DASH_FUEL") and is_equal_approx(float(hull_consts["DASH_FUEL"]), 25.0),
		"PlayerShip.DASH_FUEL = %s" % hull_consts.get("DASH_FUEL", "absent"))
	_check("owner: ShipFit duplicates neither name (exactly one owner)",
		not fit_consts.has("BOOST_FUEL") and not fit_consts.has("DASH_FUEL"),
		"ShipFit consts carry neither BOOST_FUEL nor DASH_FUEL")


## F5: section 11's `consume_fuel_cell` key, driven through the real input path.
func _report_fuel_cell_key() -> void:
	_check("input: section 11's consume_fuel_cell action is in the input map",
		InputMap.has_action(C_ACTION),
		"events = %s" % str(InputMap.action_get_events(C_ACTION)))
	var before: int = _state.consume_calls
	_press(C_ACTION, HOLD_FRAMES)
	await _ticks(0.2)
	_check("fuel cell: the C key reaches PlayerState.consume_fuel_cell through the hull",
		_state.consume_calls == before + 1,
		"consume_fuel_cell calls %d -> %d over one %d-frame press"
		% [before, _state.consume_calls, HOLD_FRAMES])
	_check("fuel cell: a held key spends once, not once per frame (it is an edge)",
		_state.consume_calls == before + 1,
		"still %d calls after holding the key %d frames" % [_state.consume_calls, HOLD_FRAMES])
	_press(C_ACTION, HOLD_FRAMES)
	await _ticks(0.2)
	_check("fuel cell: a second press spends again",
		_state.consume_calls == before + 2,
		"consume_fuel_cell calls = %d after two presses" % _state.consume_calls)


## F2: how far ruling 14's lock reaches -- both thrust sources, never the wheels.
func _report_emergency_reach() -> void:
	await _place(Vector2.ZERO)
	_state.set_fuel(0.0)
	Input.action_press(TURN_RIGHT, 1.0)
	await _ticks(0.5)
	var spin := absf(_body().angular_velocity)
	Input.action_release(TURN_RIGHT)
	_check("emergency: the reaction wheels still turn the hull at fuel 0 (ruling 14)",
		spin > 0.1,
		"|angular_velocity| = %s rad/s after 0.5 s of turn input at fuel 0" % spin)

	await _place(Vector2.ZERO)
	_state.set_fuel(0.0)
	_ship.call(&"set_move_target", Vector2(400.0, 0.0))
	await _ticks(1.0)
	var locked_speed := absf(_speed())
	_ship.call(&"cancel_orders")
	_check("emergency: an autopilot order cannot thrust either at fuel 0",
		locked_speed < 1.0,
		"speed = %s u/s after 1 s of a 400 u order at fuel 0" % locked_speed)

	await _place(Vector2.ZERO)
	_state.set_fuel(200.0)
	_ship.call(&"set_move_target", Vector2(400.0, 0.0))
	var fuelled_peak := 0.0
	for _i in Engine.physics_ticks_per_second:
		await get_tree().physics_frame
		fuelled_peak = maxf(fuelled_peak, absf(_speed()))
	_ship.call(&"cancel_orders")
	_check("emergency: the same order does thrust with fuel aboard (the control)",
		fuelled_peak > 50.0,
		"peak speed = %s u/s in the first second with a full tank" % fuelled_peak)


## F3's other half: the burn is metered, so a dry tank ends the burn.
func _report_dry_burn() -> void:
	await _place(Vector2.ZERO)
	_state.set_fuel(0.05)
	_ship.set(&"_boost_remaining", 0.0)
	_ship.set(&"_boost_cooldown", 0.0)
	Input.action_press(BOOST_ACTION, 1.0)
	await _ticks(0.3)
	Input.action_release(BOOST_ACTION)
	var remaining := float(_ship.get(&"_boost_remaining"))
	_check("boost: a tank that runs dry ends the burn instead of burning on credit",
		is_zero_approx(remaining) and is_zero_approx(_state.fuel),
		"fuel 0.05 -> %s, boost_remaining = %s s after 0.3 s of boost" % [_state.fuel, remaining])
