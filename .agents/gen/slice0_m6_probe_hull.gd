extends Node
## slice-0 M6 re-review probe A: the shipped hull, measured by this review.
##
## It re-measures the four hull-side findings the fixer pass claims (F2 emergency
## throttle lock, F3 boost burn + arm lockout, F4 the reactor refill, F5 the
## fuel-cell caller) and it verifies the F5 half M5 did not: a **real key event**
## (InputEventKey, parsed from the probe root's `_physics_process` so the hull's
## `is_action_just_pressed` sees the frame it lands in) rather than a direct
## `Input.action_press`, so the input map's binding -- R per owner ruling R3, not
## section 11's superseded C -- is what arms the cell. A C key event is measured
## too, because C must stay `cargo_toggle` and must not burn a cell.
##
## The fuel cell is counted by a witness state (`_probe_s0m6_witness.gd`) so no
## `fuel_cell` is spent from the live `PlayerProfile` record (`user://profile.cfg`);
## the conversion itself is covered by `tests/test_engine2_pools.gd` in the gate and
## by M2's pools probe, both re-run green by this review.
##
## Re-run:
##   "..._console.exe" --headless --path <proj> res://tools/_probe_s0m6_hull.tscn --quit-after 2400

const PlayerShipScene := preload("res://game/player_ship.tscn")
const WitnessScript := preload("res://tools/_probe_s0m6_witness.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")

const HULL_ID: StringName = &"ship_fighter"
const FUEL_CELL_ACTION: StringName = &"consume_fuel_cell"
const CARGO_ACTION: StringName = &"cargo_toggle"
const R_KEYCODE := 82
const C_KEYCODE := 67
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
var _key_code := 0
var _key_hold := 0
var _key_frame := 0


func _ready() -> void:
	_watchdog()
	_run()


func _watchdog() -> void:
	await get_tree().create_timer(150.0).timeout
	print("WATCHDOG: probe did not finish")
	get_tree().quit(2)


## The key script. A press event is parsed on the first frame it is armed and the
## release `hold` frames later, so the action is down for `hold` frames and its
## `just_pressed` edge exists exactly once -- what a real keyboard does.
func _physics_process(_delta: float) -> void:
	if _key_code == 0:
		return
	_key_frame += 1
	if _key_frame == 1:
		_send_key(_key_code, true)
	elif _key_frame == _key_hold + 1:
		_send_key(_key_code, false)
		_key_code = 0
		_key_frame = 0


func _send_key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)


func _press_key(code: int, hold: int) -> void:
	_key_code = code
	_key_hold = hold
	_key_frame = 0
	await _ticks(float(hold + 2) / float(Engine.physics_ticks_per_second))


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
		&"turn_right", &"boost", &"mine"]:
		if InputMap.has_action(action):
			Input.action_release(action)


func _reset_boost() -> void:
	_ship.set(&"_boost_remaining", 0.0)
	_ship.set(&"_boost_cooldown", 0.0)


func _keycodes(action: StringName) -> Array:
	var codes: Array = []
	if not InputMap.has_action(action):
		return codes
	for event: InputEvent in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key != null:
			codes.append(key.keycode)
	return codes


func _run() -> void:
	print("=== slice0 M6 probe A: hull, key-level fuel cell, reactor chain ===")
	var world := Node2D.new()
	add_child(world)
	_ship = PlayerShipScene.instantiate()
	world.add_child(_ship)
	var fit_ids: Array[StringName] = ShipFitScript.fitted_ids(BOOST_FIT)
	var stats: ShipStats = ShipFitScript.resolve(HULL_ID, BOOST_FIT)
	_state = WitnessScript.new() as PlayerState
	_state.hull_max = stats.hull_max
	_state.shield_max = stats.shield_max
	_state.cargo_max = stats.cargo_max
	_state.setup()
	_ship.call(&"setup", stats, _state, fit_ids)
	await _ticks(0.2)
	_check("setup: the hull flies with the resolved section 13 snapshot",
		stats.hull_mass == 80.0 and is_equal_approx(stats.max_speed, 427.5),
		"mass=%s max_speed=%s" % [stats.hull_mass, stats.max_speed])

	await _report_input()
	await _report_key_cell()
	await _report_emergency()
	await _report_boost()
	await _report_reactor()
	_release_all()
	print("[SUMMARY] ok=%d failed=%d" % [_ok, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


## Section 11's action, bound per owner ruling R3.
func _report_input() -> void:
	_check("input a: consume_fuel_cell is in the input map (section 11)",
		InputMap.has_action(FUEL_CELL_ACTION),
		"has_action(%s) = %s" % [FUEL_CELL_ACTION, InputMap.has_action(FUEL_CELL_ACTION)])
	_check("input b: its binding is R (owner ruling R3 supersedes section 11's C)",
		_keycodes(FUEL_CELL_ACTION) == [R_KEYCODE],
		"keycodes = %s (want [82] = R)" % [_keycodes(FUEL_CELL_ACTION)])
	_check("input c: cargo_toggle keeps C (ruling R3)",
		_keycodes(CARGO_ACTION) == [C_KEYCODE],
		"keycodes = %s (want [67] = C)" % [_keycodes(CARGO_ACTION)])


## F5: the hull's caller, reached by a real key event.
func _report_key_cell() -> void:
	await _place(Vector2(0.0, 0.0))
	var before := int(_state.get(&"consume_calls"))
	await _press_key(R_KEYCODE, 4)
	var after_one := int(_state.get(&"consume_calls"))
	_check("cell a: a real R key press reaches PlayerState.consume_fuel_cell once",
		after_one - before == 1,
		"calls %s -> %s over one 4-frame R press" % [before, after_one])
	_check("cell b: holding R spends once, not once per frame (it is an edge)",
		after_one - before == 1,
		"still %s calls after holding R for 4 physics frames" % after_one)
	await _press_key(R_KEYCODE, 1)
	var after_two := int(_state.get(&"consume_calls"))
	_check("cell c: a second press spends again",
		after_two - after_one == 1,
		"calls = %s after two presses" % after_two)
	await _press_key(C_KEYCODE, 4)
	var after_c := int(_state.get(&"consume_calls"))
	_check("cell d: a C key press does not burn a cell (C is cargo_toggle, ruling R3)",
		after_c == after_two,
		"calls stayed %s across a 4-frame C press" % after_c)


## F2: ruling 14's thrust lock.
func _report_emergency() -> void:
	await _place(Vector2(0.0, 0.0))
	_state.set_fuel(0.0)
	Input.action_press(&"thrust_forward", 1.0)
	await _ticks(1.0)
	var locked := absf(_speed())
	Input.action_release(&"thrust_forward")
	_check("emergency a: at fuel 0 a full second of throttle does not accelerate (F2)",
		locked < 1.0,
		"fuel=0.0, speed after 1 s of full throttle = %s u/s (want 0)" % locked)

	await _place(Vector2(0.0, 0.0))
	_state.set_fuel(200.0)
	Input.action_press(&"thrust_forward", 1.0)
	await _ticks(1.0)
	var flying := absf(_speed())
	Input.action_release(&"thrust_forward")
	_check("emergency b: the same throttle with fuel aboard still flies (the control)",
		flying > 100.0,
		"fuel=200.0, speed after 1 s of full throttle = %s u/s" % flying)

	await _place(Vector2(0.0, 0.0))
	_state.set_fuel(0.0)
	Input.action_press(&"turn_right", 1.0)
	await _ticks(0.5)
	var omega := absf(_body().angular_velocity)
	Input.action_release(&"turn_right")
	_check("emergency c: the reaction wheels still turn the hull at fuel 0 (ruling 14)",
		omega > 3.0,
		"|angular_velocity| = %s rad/s (class turn rate 3.4)" % omega)

	await _place(Vector2(0.0, 0.0))
	_state.set_fuel(0.0)
	var peak := 0.0
	_ship.call(&"set_move_target", Vector2(400.0, 0.0))
	var elapsed := 0.0
	while elapsed < 1.0:
		await get_tree().physics_frame
		elapsed += 1.0 / float(Engine.physics_ticks_per_second)
		peak = maxf(peak, absf(_speed()))
	_ship.call(&"cancel_orders")
	_check("emergency d: an autopilot order cannot thrust either at fuel 0 (F2's second source)",
		peak < 1.0,
		"peak speed under a 400 u order at fuel 0 = %s u/s (want 0)" % peak)


## F3: ruling 11's toll and ruling 14's lockout.
func _report_boost() -> void:
	await _place(Vector2(0.0, 0.0))
	_state.set_fuel(200.0)
	_reset_boost()
	var tank := _state.fuel
	Input.action_press(&"boost", 1.0)
	await _ticks(1.0)
	Input.action_release(&"boost")
	var burned := tank - _state.fuel
	_check("boost a: one second of afterburner burns BOOST_FUEL 3.0 (F3, section 13)",
		absf(burned - 3.0) < 0.05,
		"fuel %s -> %s (burned %s, spec 3.0)" % [tank, _state.fuel, burned])

	await _place(Vector2(0.0, 0.0))
	_state.set_fuel(0.0)
	_reset_boost()
	Input.action_press(&"boost", 1.0)
	await _ticks(0.5)
	var armed := float(_ship.get(&"_boost_remaining"))
	Input.action_release(&"boost")
	_check("boost b: at fuel 0 boost refuses to arm (F3 + ruling 14's lockout)",
		armed <= 0.0,
		"boost_remaining = %s s after pressing boost on an empty tank" % armed)

	await _place(Vector2(0.0, 0.0))
	_state.set_fuel(0.05)
	_reset_boost()
	Input.action_press(&"boost", 1.0)
	await _ticks(0.3)
	var dry_tank := _state.fuel
	var dry_armed := float(_ship.get(&"_boost_remaining"))
	Input.action_release(&"boost")
	_check("boost c: a tank that runs dry ends the burn instead of burning on credit",
		is_zero_approx(dry_tank) and dry_armed <= 0.0,
		"fuel 0.05 -> %s, boost_remaining = %s" % [dry_tank, dry_armed])


## F4: the reactor tick, at full efficiency and under ruling 14's penalty.
func _report_reactor() -> void:
	await _place(Vector2(0.0, 0.0))
	_state.set_fuel(200.0)
	_state.set_energy(_state.energy_max)
	var toll_before := _state.fuel
	_state.try_spend_energy(10.0)
	var spent := _state.energy
	_check("reactor a: spending 10 Energy burns FUEL_PER_ENERGY 0.10 per point (ruling 11)",
		is_equal_approx(toll_before - _state.fuel, 1.0),
		"fuel %s -> %s while energy 100.0 -> %s" % [toll_before, _state.fuel, spent])
	await _ticks(1.0)
	var refill := _state.energy - spent
	_check("reactor b: a spent buffer refills at energy_regen 5/s in the shipped hull (F4)",
		absf(refill - 5.0) < 0.05,
		"energy %s -> %s after 1 s (refill %s, spec 5.0)" % [spent, _state.energy, refill])

	await _place(Vector2(0.0, 0.0))
	_state.set_fuel(0.0)
	_state.set_energy(_state.energy_max)
	_state.try_spend_energy(10.0)
	var spent_emergency := _state.energy
	await _ticks(1.0)
	var refill_emergency := _state.energy - spent_emergency
	_check("reactor c: under emergency the refill runs at x0.7 (section 13, ruling 14)",
		absf(refill_emergency - 3.5) < 0.05,
		"energy %s -> %s after 1 s at fuel 0 (refill %s, spec 3.5)"
		% [spent_emergency, _state.energy, refill_emergency])
