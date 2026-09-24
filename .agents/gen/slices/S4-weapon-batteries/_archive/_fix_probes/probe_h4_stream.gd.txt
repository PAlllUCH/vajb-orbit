extends SceneTree
## S4-H4 fixer probe - the held trigger's cadence for a travelling family, re-measured on the
## fixed component (CONTRACTS section 16 rule 4). Same three stages as the review's probe D
## (`slices/S4-weapon-batteries/_review_probes/probe_h3_stream.gd.txt`, 3 shots for a 3.0 s hold
## pre-fix), so the two readings compare line for line.
##
##   XDG_DATA_HOME=/tmp/h4_scratch/xdg godot --headless --path vajb-orbit \
##     --script res://tests/probe_s4h4_stream.gd
##
## The scratch `XDG_DATA_HOME` is not optional (T-93, L106/L121): a `--script` SceneTree probe
## boots the `PlayerProfile` autoload, so without it the probe would read - and could write - the
## owner's live account.

const WeaponScript := preload("res://game/weapons.gd")
const PlayerStateScript := preload("res://game/player_state.gd")

var _state = null
var _rig: Node2D = null
var _guns: Node2D = null
var _frames := 0
var _shots: Array[int] = []
var _marks: Array[int] = []
var _ran := false


func _initialize() -> void:
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	if _ran:
		return
	_ran = true
	_state = PlayerStateScript.new()
	_state.setup()
	_rig = Node2D.new()
	root.add_child(_rig)
	_guns = WeaponScript.new() as Node2D
	_rig.add_child(_guns)
	_guns.call(&"setup", null, _state)
	var fit: Array[StringName] = [&"w_cannon", &"w_cannon", &"w_cannon"]
	_guns.call(&"set_fitted", fit)
	_guns.call(&"select_group", 1)
	_guns.call(&"set_aim_point", Vector2(400.0, 0.0))
	_state.set_ammo(WeaponScript.ammo_slot(&"cannon"), 200)
	_shots = [0]
	_guns.connect(&"shot_fired", func(_id: StringName) -> void: _shots[0] += 1)

	print("[h4d] cannon interval_of=%.3f burst_on=%.3f burst_off=%.3f"
		% [
			WeaponScript.interval_of(&"cannon"),
			float(WeaponScript.row_of(&"cannon").get(&"burst_on", 0.0)),
			float(WeaponScript.row_of(&"cannon").get(&"burst_off", 0.0)),
		])

	## Stage 1: one pull, held for 3.0 s of 1 ms frames.
	_guns.call(&"set_firing", true)
	_drive(3000, 0.001, "held 3.0 s from one pull")
	## Stage 2: release, one frame, then pull again - the same held trigger, second pull.
	_guns.call(&"set_firing", false)
	_guns.call(&"tick", 0.001)
	_guns.call(&"set_firing", true)
	_drive(3000, 0.001, "held another 3.0 s after a re-pull")
	## Stage 3: 5 s of a *pulsing* trigger, 100 ms on / 100 ms off.
	_guns.call(&"set_firing", false)
	_guns.call(&"tick", 0.001)
	var before: int = _shots[0]
	for _cycle in 25:
		_guns.call(&"set_firing", true)
		_drive_silent(100, 0.001)
		_guns.call(&"set_firing", false)
		_drive_silent(100, 0.001)
	print("[h4d] 25 pulses of 100 ms on / 100 ms off: shots=%d (pack left %d) shots-per-pulse=%.2f"
		% [
			_shots[0] - before,
			int(_state.ammo[WeaponScript.ammo_slot(&"cannon")]),
			float(_shots[0] - before) / 25.0,
		])
	## Stage 4: the mine, the one travelling family the stream must not re-arm - one release per
	## pull however long the pull is held.
	_guns.call(&"set_firing", false)
	_guns.call(&"tick", 0.001)
	var mine_guns := WeaponScript.new() as Node2D
	_rig.add_child(mine_guns)
	mine_guns.call(&"setup", null, _state)
	var mine_fit: Array[StringName] = [&"w_mine"]
	mine_guns.call(&"set_fitted", mine_fit)
	mine_guns.call(&"select_group", 1)
	var mines := [0]
	mine_guns.connect(&"shot_fired", func(_id: StringName) -> void: mines[0] += 1)
	_state.set_ammo(WeaponScript.ammo_slot(&"mine"), 10)
	mine_guns.call(&"set_firing", true)
	for _f in 3000:
		mine_guns.call(&"tick", 0.001)
	print("[h4d] mine held 3.0 s: shots=%d (ammo left %d)"
		% [mines[0], int(_state.ammo[WeaponScript.ammo_slot(&"mine")])])
	print("[h4d] done")
	quit(0)


func _drive(frames: int, delta: float, label: String) -> void:
	var before: int = _shots[0]
	_marks = []
	_drive_silent(frames, delta)
	print("[h4d] %s: shots=%d releases-at-frame=%s" % [label, _shots[0] - before, str(_marks)])


func _drive_silent(frames: int, delta: float) -> void:
	for _f in frames:
		var before: int = _shots[0]
		_guns.call(&"tick", delta)
		if _shots[0] > before:
			_marks.append(_frames + 1)
		_frames += 1
