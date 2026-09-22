extends Node
## R1 evidence probe (P2-B proper review, part 1 of 2): the two composed fitting
## transactions measured on R1's own throwaway profile instance - the per-cell install,
## the swap that hands the displaced module back, the mandatory-cell refusal, the cell
## and ownership guards, the over-budget refusal before any write, one economy-log line
## per success and the signal order.
##
## Nothing here borrows the shipped autoload and no shipped file is written: the profile
## is a `Profile.new()` whose `save_path` is repointed at a scratch file (the
## `test_p2b_retirement.gd` harness), and the economy log is redirected to its own
## scratch path so the owner's `user://economy_log.txt` is never appended to.
##
## Run:  godot --headless --path vajb-orbit res://tests/probe_r1_fit_profile.tscn --quit-after 600
## Signal: the [R1-PROFILE] lines; the last line is [R1-PROFILE] done.
##
## Self-bound: `FRAME_CAP` frames and a hard `LOOP_CAP` on every iteration (L82).

const Profile := preload("res://autoload/player_profile.gd")
const FitData := preload("res://game/ship_fit.gd")
const Log := preload("res://game/economy_log.gd")

const PROFILE_PATH := "user://probe_r1_fit_profile.cfg"
const LOG_PATH := "user://probe_r1_fit_profile_log.txt"
const FRAME_CAP := 600
const LOOP_CAP := 64

## 08 section 3.2's Fighter row: `.WW.` / `HSCB` / `.HWU.` / `.EP.` - two W cells, one
## engine, one power, and 08 section 2's `power_out` 6.
const HULL: StringName = &"ship_fighter"
const VANGUARD: StringName = &"ship_vanguard"
const NPC: StringName = &"ship_swarmer"
const WEAPONS: StringName = &"weapons"
const ENGINES: StringName = &"engines"
const POWER: StringName = &"power"
const UTILITY: StringName = &"utility"
const LASER: StringName = &"w_laser"
const CANNON: StringName = &"w_cannon"
const PLASMA: StringName = &"w_plasma"
const RAILGUN: StringName = &"w_railgun"
const ION: StringName = &"e_ion"

var _frames := 0
var _profile: Node = null
var _signals: Array[StringName] = []


func _ready() -> void:
	_delete(PROFILE_PATH)
	_delete(LOG_PATH)
	Log.log_path = LOG_PATH
	_probe_the_delivered_fit()
	_probe_the_per_cell_install()
	_probe_the_swap()
	_probe_the_remove()
	_probe_the_mandatory_refusal()
	_probe_the_guards()
	_probe_the_power_refusal()
	_probe_the_line_and_signals()
	Log.log_path = Log.DEFAULT_PATH
	_delete(PROFILE_PATH)
	_delete(LOG_PATH)
	print("[R1-PROFILE] done")
	get_tree().quit(0)


func _process(_delta: float) -> void:
	_frames += 1
	if _frames > FRAME_CAP:
		print("[R1-PROFILE] FRAME CAP %d reached; quitting" % FRAME_CAP)
		get_tree().quit(3)


## --------------------------------------------------------------------------- harness


func _delete(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


## A fresh account holding `modules` (id -> count) with the delivered standard fit of
## `hull` written the way the OUTFITTING pane's own seed writes it.
func _seed(hull: StringName, modules: Dictionary) -> Node:
	if _profile != null and is_instance_valid(_profile):
		_profile.free()
	_profile = Profile.new()
	_profile.set(&"save_path", PROFILE_PATH)
	_profile.call(&"_load_catalog")
	_profile.reload()
	_profile.set(&"_credits", 10000)
	_profile.set(&"_active_ship", hull)
	_profile.set(&"_owned_ships", [hull] as Array[StringName])
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", _records(modules))
	_profile.call(&"set_fit", hull, FitData.standard_fit(hull))
	_delete(LOG_PATH)
	_signals.clear()
	if not _profile.profile_changed.is_connected(_on_changed):
		_profile.profile_changed.connect(_on_changed)
	return _profile


func _on_changed(key: StringName) -> void:
	_signals.append(key)


func _records(modules: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key: Variant in modules:
		out[String(key)] = {"base_id": String(key), "count": int(modules[key])}
	return out


func _fit(hull: StringName) -> Dictionary:
	return _profile.call(&"fit_for", hull)


func _cells(hull: StringName, slot_key: StringName) -> Array:
	return _fit(hull).get(slot_key, [])


func _held(module_id: StringName) -> int:
	return int(_profile.call(&"module_count", module_id))


func _lines() -> Array[String]:
	var out: Array[String] = []
	if not FileAccess.file_exists(LOG_PATH):
		return out
	var text := FileAccess.get_file_as_string(LOG_PATH)
	for line: String in text.split("\n", false):
		if not line.strip_edges().is_empty():
			out.append(line.strip_edges())
	return out


func _line_report() -> String:
	var lines := _lines()
	var fitted := 0
	var index := 0
	while index < lines.size() and index < LOOP_CAP:
		if lines[index].contains("FIT_MODULE"):
			fitted += 1
		index += 1
	return "total=%d fit_module=%d" % [lines.size(), fitted]


## ----------------------------------------------------------------------- the fixtures


func _probe_the_delivered_fit() -> void:
	var profile := _seed(HULL, {LASER: 3})
	print("[R1-PROFILE] hull=%s grid_counts=%s power_out(fit_legal)=%s" % [
		HULL, FitData.grid_counts(HULL), FitData.fit_legal(HULL, _fit(HULL))[&"power"],
	])
	print("[R1-PROFILE] delivered fit: weapons=%s engines=%s power=%s shields=%s" % [
		_cells(HULL, WEAPONS), _cells(HULL, ENGINES),
		_fit(HULL).get(POWER, ""), _cells(HULL, &"shields"),
	])
	print("[R1-PROFILE] inventory at start: %s (module_count)" % [_inventory()])
	print("[R1-PROFILE] fit_for(NPC %s)=%s" % [NPC, _profile.call(&"fit_for", NPC)])


func _inventory() -> String:
	var out: Array[String] = []
	for module_id: StringName in [LASER, CANNON, PLASMA, RAILGUN, ION, &"e_std", &"p_std"]:
		out.append("%s=%d" % [module_id, _held(module_id)])
	return ", ".join(out)


## --------------------------------------------------------------------- the transactions


func _probe_the_per_cell_install() -> void:
	_seed(HULL, {LASER: 3, CANNON: 1})
	var before := _cells(HULL, WEAPONS)
	var ok: bool = _profile.call(&"fit_module_at", HULL, WEAPONS, 1, CANNON)
	print("[R1-PROFILE] install into W2 (index 1): ok=%s weapons %s -> %s cannon=%d laser=%d" % [
		ok, before, _cells(HULL, WEAPONS), _held(CANNON), _held(LASER)
	])
	print("[R1-PROFILE] engine and power cells untouched: engines=%s power=%s" % [
		_cells(HULL, ENGINES), _fit(HULL).get(POWER, "")
	])
	print("[R1-PROFILE] the install's log lines: %s" % _line_report())
	print("[R1-PROFILE] the install's signals: %s" % [str(_signals)])


func _probe_the_swap() -> void:
	_seed(HULL, {LASER: 2, CANNON: 1})
	var first: bool = _profile.call(&"fit_module_at", HULL, WEAPONS, 0, CANNON)
	var after_first := _cells(HULL, WEAPONS)
	var lasers_after_first := _held(LASER)
	var second: bool = _profile.call(&"fit_module_at", HULL, WEAPONS, 0, LASER)
	print("[R1-PROFILE] W1 laser -> cannon: ok=%s weapons=%s laser=%d cannon=%d" % [
		first, after_first, lasers_after_first, _held(CANNON)
	])
	print("[R1-PROFILE] W1 cannon -> laser (the swap): ok=%s weapons=%s laser=%d cannon=%d" % [
		second, _cells(HULL, WEAPONS), _held(LASER), _held(CANNON)
	])
	print("[R1-PROFILE] the displaced cannon came back at %d (0 would be a lost module)" % (
		_held(CANNON)
	))


func _probe_the_remove() -> void:
	_seed(HULL, {LASER: 3})
	var ok: bool = _profile.call(&"clear_fit_slot", HULL, &"shields", 0)
	print("[R1-PROFILE] remove the delivered shield: ok=%s shields=%s laser=%d" % [
		ok, _cells(HULL, &"shields"), _held(&"s_light")
	])
	var again: bool = _profile.call(&"clear_fit_slot", HULL, &"shields", 0)
	print("[R1-PROFILE] removing an already-empty cell answers %s (no second write)" % again)


func _probe_the_mandatory_refusal() -> void:
	_seed(HULL, {ION: 1, &"p_mk2": 1})
	var fit_before := _fit(HULL)
	var engine_remove: bool = _profile.call(&"clear_fit_slot", HULL, ENGINES, 0)
	var power_remove: bool = _profile.call(&"clear_fit_slot", HULL, POWER, 0)
	var mandatory: Array = FitData.MANDATORY_SLOT_KEYS
	print("[R1-PROFILE] MANDATORY_SLOT_KEYS=%s (the pin reads FitData, not a copy)" % [str(mandatory)])
	print("[R1-PROFILE] clear engines[0]=%s clear power=%s fit unchanged=%s" % [
		engine_remove, power_remove, _fit(HULL) == fit_before
	])
	print("[R1-PROFILE] the swap that is allowed: %s" % [
		_profile.call(&"fit_module_at", HULL, ENGINES, 0, ION)
	])
	print("[R1-PROFILE] engines=%s e_std back in the inventory=%d power=%s" % [
		_cells(HULL, ENGINES), _held(&"e_std"), _fit(HULL).get(POWER, "")
	])
	var power_swap: bool = _profile.call(&"fit_module_at", HULL, POWER, 0, &"p_mk2")
	print("[R1-PROFILE] a reactor swap is allowed too: %s -> power=%s p_std=%d" % [
		power_swap, _fit(HULL).get(POWER, ""), _held(&"p_std")
	])


func _probe_the_guards() -> void:
	_seed(HULL, {LASER: 2, RAILGUN: 0})
	var capacity := int(FitData.slot_capacity(HULL, WEAPONS))
	print("[R1-PROFILE] fighter W capacity=%d utility capacity=%d" % [
		capacity, int(FitData.slot_capacity(HULL, UTILITY))
	])
	var cases: Array[Dictionary] = [
		{"label": "index == capacity", "args": [HULL, WEAPONS, capacity, LASER]},
		{"label": "index == -1", "args": [HULL, WEAPONS, -1, LASER]},
		{"label": "no such cell (utility on the fighter)", "args": [HULL, UTILITY, 0, LASER]},
		{"label": "unknown slot key", "args": [HULL, &"hulls", 0, LASER]},
		{"label": "unknown hull", "args": [&"ship_nonexistent", WEAPONS, 0, LASER]},
		{"label": "an NPC hull", "args": [NPC, WEAPONS, 0, LASER]},
		{"label": "a module the inventory does not hold", "args": [HULL, WEAPONS, 1, RAILGUN]},
		{"label": "an empty module id", "args": [HULL, WEAPONS, 1, &""]},
	]
	var fit_before := _fit(HULL)
	var logs_before := _lines().size()
	var index := 0
	while index < cases.size() and index < LOOP_CAP:
		var entry: Dictionary = cases[index]
		var args: Array = entry["args"]
		var ok: bool = _profile.call(&"fit_module_at", args[0], args[1], args[2], args[3])
		print("[R1-PROFILE] guard %s -> %s" % [entry["label"], ok])
		index += 1
	print("[R1-PROFILE] every guard refused without a write: fit unchanged=%s new lines=%d" % [
		_fit(HULL) == fit_before, _lines().size() - logs_before
	])


func _probe_the_power_refusal() -> void:
	_seed(HULL, {PLASMA: 2})
	var first: bool = _profile.call(&"fit_module_at", HULL, WEAPONS, 0, PLASMA)
	var after_first := _fit(HULL)
	var first_power: Dictionary = FitData.fit_legal(HULL, after_first)[&"power"]
	var lines_after_first := _lines().size()
	var second: bool = _profile.call(&"fit_module_at", HULL, WEAPONS, 1, PLASMA)
	var candidate := _with_cell(after_first, 1, PLASMA)
	var power: Dictionary = FitData.fit_legal(HULL, candidate)[&"power"]
	print("[R1-PROFILE] plasma into W1: ok=%s weapons=%s power=%s" % [
		first, _cells(HULL, WEAPONS), first_power
	])
	print("[R1-PROFILE] plasma into W2: ok=%s (candidate power=%s over_by=%d)" % [
		second, power, int(power[&"draw"]) - int(power[&"out"])
	])
	print("[R1-PROFILE] the refused call wrote nothing: weapons=%s plasma=%d new lines=%d" % [
		_cells(HULL, WEAPONS), _held(PLASMA), _lines().size() - lines_after_first
	])


func _with_cell(fit: Dictionary, index: int, module_id: StringName) -> Dictionary:
	var out := fit.duplicate(true)
	var cells: Array = out[WEAPONS]
	cells[index] = String(module_id)
	out[WEAPONS] = cells
	return out


func _probe_the_line_and_signals() -> void:
	_seed(HULL, {LASER: 3, CANNON: 1})
	_signals.clear()
	var ok: bool = _profile.call(&"fit_module_at", HULL, WEAPONS, 1, CANNON)
	var lines := _lines()
	print("[R1-PROFILE] one success writes %d line(s):" % lines.size())
	var index := 0
	while index < lines.size() and index < LOOP_CAP:
		print("[R1-PROFILE]   %s" % lines[index])
		index += 1
	print("[R1-PROFILE] the success's signals in order: %s" % [str(_signals)])
	print("[R1-PROFILE] the refused install emits nothing: %s" % [_refused_signals()])


func _refused_signals() -> String:
	_seed(HULL, {LASER: 3})
	_signals.clear()
	_profile.call(&"clear_fit_slot", HULL, ENGINES, 0)
	_profile.call(&"fit_module_at", HULL, WEAPONS, 1, RAILGUN)
	return str(_signals)
