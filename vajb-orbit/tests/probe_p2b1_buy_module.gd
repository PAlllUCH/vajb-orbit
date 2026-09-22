extends SceneTree
## P2-B1 W1 evidence probe: drive `PlayerProfile.buy_module` (CONTRACTS section
## 12) end to end and print the round-trip numbers, so every figure in
## `.agents/gen/p2b1_w1_report.md` can be re-measured by hand.
##
##   godot --headless --path vajb-orbit --script res://tests/probe_p2b1_buy_module.gd
##
## Throwaway `PlayerProfile` instances only - never the shipped autoload, and no
## instance is added to the tree, so there is no debounce Timer to flush. The
## scratch profile and the scratch economy log are removed at the end.

const Profile := preload("res://autoload/player_profile.gd")
const ModuleData := preload("res://game/module_catalog.gd")
const Log := preload("res://game/economy_log.gd")

const PROBE_PATH := "user://probe_p2b1_buy_module.cfg"
const LOG_PATH := "user://probe_p2b1_buy_module.log"

var _signals: Array[String] = []
var _failures: Array[String] = []


func _init() -> void:
	_remove(PROBE_PATH)
	_remove(LOG_PATH)
	Log.log_path = LOG_PATH

	var cannon_price := int(ModuleData.module(&"w_cannon")[&"cost"])
	var railgun_price := int(ModuleData.module(&"w_railgun")[&"cost"])
	print("[probe] catalogue prices: w_cannon=%d w_railgun=%d" % [cannon_price, railgun_price])

	var profile = _profile()
	profile.profile_changed.connect(_on_changed)
	profile.purchase_failed.connect(_on_failed)

	print("[probe] start: credits=%d w_cannon=%d" % [profile.credits(), profile.module_count(&"w_cannon")])
	_signals.clear()
	print("[probe] buy_module(w_cannon, %d) = %s" % [cannon_price, profile.buy_module(&"w_cannon", cannon_price)])
	print("[probe] after buy: credits=%d w_cannon=%d signals=%s" % [
		profile.credits(), profile.module_count(&"w_cannon"), str(_signals)
	])
	print("[probe] log lines=%d raw=%s" % [_log_lines().size(), _log_lines()[0]])

	_signals.clear()
	print("[probe] buy_module(w_cannon, %d) again = %s" % [cannon_price, profile.buy_module(&"w_cannon", cannon_price)])
	print("[probe] after the second buy: credits=%d w_cannon=%d log lines=%d" % [
		profile.credits(), profile.module_count(&"w_cannon"), _log_lines().size()
	])

	profile.reload()
	print("[probe] after reload: credits=%d w_cannon=%d" % [profile.credits(), profile.module_count(&"w_cannon")])

	print("[probe] -- refusals --")
	_failures.clear()
	print("[probe] buy_module(w_do_not_exist, 100) = %s failures=%s w_do_not_exist=%d credits=%d lines=%d" % [
		profile.buy_module(&"w_do_not_exist", 100),
		str(_failures),
		profile.module_count(&"w_do_not_exist"),
		profile.credits(),
		_log_lines().size(),
	])

	_failures.clear()
	print("[probe] buy_module(w_cannon, -1) = %s failures=%s credits=%d" % [
		profile.buy_module(&"w_cannon", -1), str(_failures), profile.credits()
	])

	_failures.clear()
	profile.spend(profile.credits() - 500)
	_signals.clear()
	print("[probe] balance drained to %d; buy_module(w_railgun, %d) = %s failures=%s credits=%d railgun=%d lines=%d signals=%s" % [
		profile.credits(),
		railgun_price,
		profile.buy_module(&"w_railgun", railgun_price),
		str(_failures),
		profile.credits(),
		profile.module_count(&"w_railgun"),
		_log_lines().size(),
		str(_signals),
	])

	profile.free()
	_remove(PROBE_PATH)
	_remove(LOG_PATH)
	quit()


func _on_changed(key: StringName) -> void:
	_signals.append(String(key))


func _on_failed(reason: StringName, id: StringName) -> void:
	_failures.append("%s/%s" % [String(reason), String(id)])


func _profile():
	var profile := Profile.new()
	profile.save_path = PROBE_PATH
	return profile


func _log_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	var file := FileAccess.open(LOG_PATH, FileAccess.READ)
	if file == null:
		return lines
	var text := file.get_as_text()
	file.close()
	for line: String in text.split("\n"):
		if not line.strip_edges().is_empty():
			lines.append(line)
	return lines


func _remove(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())
