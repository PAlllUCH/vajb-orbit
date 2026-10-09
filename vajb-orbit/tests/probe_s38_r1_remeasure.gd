extends Node
## S38-R1 re-measurement probe: the reviewer's own read of the wave's three
## measurements plus the negatives and the riders, on a fresh scratch store.
##
## Fine-grained countdown sampling (every SAMPLE_WAIT for SAMPLE_COUNT reads)
## decides whether the U22 readout is a live 1 Hz read or a frozen string, and
## whether its figure tracks `BAND_SECONDS - now % BAND_SECONDS` within one tick.
##
##   godot --headless --path vajb-orbit res://tests/probe_s38_r1_remeasure.tscn --quit-after 1200
##
## Prints [S38R] lines only. Sandboxes PlayerProfile like B1's probe.

const THEME_PATH := "res://ui/theme/vajb_theme.tres"
const STATION := "res://ui/screens/station.tscn"
const W := 1920.0
const H := 1080.0
const SCRATCH_DIR := "user://_s38r_scratch"
const SCRATCH_PROFILE := "user://_s38r_scratch/profile.cfg"

const SERVICES := 7
const OVERVIEW := 6
const CONTRACTS: StringName = &"contracts"
const START_SECTOR: StringName = &"sector_1"
const SAMPLE_WAIT := 0.35
const SAMPLE_COUNT := 9

const Registry := preload("res://game/contract_registry.gd")
const StationRegistryScript := preload("res://game/station_registry.gd")
const Clock := preload("res://autoload/world_clock.gd")

var _theme: Theme = null
var _station: Control = null
var _host: Control = null


func _ready() -> void:
	await get_tree().process_frame
	_sandbox()
	_theme = load(THEME_PATH) as Theme
	await _mount_station()
	_report_cold_start()
	await _report_countdown()
	await _report_boundary()
	await _report_negatives()
	await _report_riders()
	_report_pins()
	print("[S38R] done")
	get_tree().quit(0)


func _sandbox() -> void:
	DirAccess.make_dir_recursive_absolute(SCRATCH_DIR)
	var profile := _profile()
	if profile != null:
		profile.set(&"save_path", SCRATCH_PROFILE)
		profile.call(&"reset_to_defaults")
		profile.call(&"flush")


func _profile() -> Node:
	return get_tree().root.get_node_or_null(NodePath("PlayerProfile"))


func _mount_station() -> void:
	_host = Control.new()
	_host.name = "Host"
	_host.theme = _theme
	_host.size = Vector2(W, H)
	add_child(_host)
	var packed := load(STATION) as PackedScene
	_station = packed.instantiate() as Control
	_host.add_child(_station)
	await _frames(30)


func _free_station() -> void:
	if _host != null and is_instance_valid(_host):
		_host.free()
	_station = null
	_host = null


func _report_cold_start() -> void:
	var profile := _profile()
	var row := StationRegistryScript.docked_station(profile)
	print("[S38R] cold filed='%s' resolved=%s board=%d"
		% [String(profile.call(&"docked_station")), String(row.get(&"id", &"")),
		Registry.board(row, 0).size()])
	_select_sync(SERVICES)
	var panel := _panel()
	var rows: Array = panel.call(&"board_rows")
	print("[S38R] cold panel_rows=%d empty='%s' station_row=%s"
		% [rows.size(), String(panel.call(&"empty_state_text")),
		String(panel.get(&"_station_row").get(&"id", &""))])
	print("[S38R] cold first_row=%s" % _first_row(rows))
	_select_sync(OVERVIEW)
	print("[S38R] cold plate=%s" % str(_plate_texts()))


func _report_countdown() -> void:
	_select_sync(SERVICES)
	var panel := _panel()
	var timer := panel.get(&"_tick_timer") as Timer
	print("[S38R] tick wait=%s one_shot=%s running=%s"
		% [str(timer.wait_time), str(timer.one_shot), str(not timer.is_stopped())])
	var seen := {}
	for index in SAMPLE_COUNT:
		var text := String(panel.call(&"roll_readout"))
		var live := int(panel.call(&"roll_remaining"))
		var now := Clock.now()
		var expected := Clock.BAND_SECONDS - now % Clock.BAND_SECONDS
		seen[text] = true
		print("[S38R] tick#%d t=%s text=%s live=%d expected=%d lag=%d time_left=%.2f"
			% [index, str(int(Time.get_unix_time_from_system())), text,
			live, expected, expected - _mmss_seconds(text), timer.time_left])
		await _wait(SAMPLE_WAIT)
	print("[S38R] tick distinct_texts=%d moved=%s"
		% [seen.size(), str(seen.size() > 1)])
	panel.call(&"_tick")
	print("[S38R] tick manual text=%s" % String(panel.call(&"roll_readout")))


func _report_boundary() -> void:
	var panel := _panel()
	var now := Clock.now()
	var remaining := Clock.BAND_SECONDS - now % Clock.BAND_SECONDS
	var before_band := int(panel.call(&"board_band"))
	var before := _ids(panel.call(&"board_rows"))
	Clock.set_override(now + remaining)
	panel.call(&"_tick")
	var after := _ids(panel.call(&"board_rows"))
	var next_expected := _ids(Registry.board(StationRegistryScript.starting_station(), 0))
	print("[S38R] boundary band %d->%d expected=%d readout=%s"
		% [before_band, int(panel.call(&"board_band")),
		Registry.band_index(Clock.now()), String(panel.call(&"roll_readout"))])
	print("[S38R] boundary next_band_rows=%s changed=%s same_panel=%s"
		% [str(after == next_expected), str(after != before),
		str(panel == _panel())])
	Clock.clear_override()
	panel.call(&"refresh_profile", &"docked_station")
	await _frames(4)


func _report_negatives() -> void:
	var profile := _profile()
	profile.call(&"set_docked_station", &"sector_7")
	var s7 := StationRegistryScript.docked_station(profile)
	print("[S38R] s7 filed=sector_7 place_empty=%s id_seam=%s"
		% [str(s7.is_empty()), String(StationRegistryScript.docked_station_id(profile))])
	## A fresh mount is the honest fallback reading: the running screen's labels were
	## already written by the cold start, so only a new mount shows the scene's copy.
	_free_station()
	await _mount_station()
	_select_sync(OVERVIEW)
	print("[S38R] s7 plate_fresh=%s" % str(_plate_texts()))
	profile.call(&"set_docked_station", &"nonsense")
	print("[S38R] unparseable place_empty=%s id_seam=%s"
		% [str(StationRegistryScript.docked_station(profile).is_empty()),
		String(StationRegistryScript.docked_station_id(profile))])
	profile.call(&"set_docked_station", &"")
	print("[S38R] nullprofile place_empty=%s"
		% str(StationRegistryScript.docked_station(null).is_empty()))
	## A fresh mount again, so the riders read a panel whose board was derived at s1_primary.
	profile.call(&"set_docked_station", &"s1_primary")
	_free_station()
	await _mount_station()


func _report_riders() -> void:
	var profile := _profile()
	_select_sync(SERVICES)
	await _frames(4)
	var panel := _panel()
	var dimmed: Array = panel.call(&"dimmed_rows")
	var dim: Color = panel.call(&"_token", &"text_dim")
	if dimmed.is_empty():
		print("[S38R] t156 none_dimmed")
	else:
		var inner := dimmed[0] as Control
		var icon := inner.find_child("Icon", true, false) as Control
		print("[S38R] t156 boxes=%d modulate_is_dim=%s icon_under=%s icon_modulate=%.2f"
			% [dimmed.size(), str(inner.modulate == dim), str(icon != null and _descends(icon, inner)),
			icon.modulate.a if icon != null else -1.0])
	var rows: Array = panel.call(&"board_rows")
	var target := {}
	for row: Dictionary in rows:
		if StringName(row.get(&"type", &"")) == Registry.TYPE_HUNT:
			target = row
			break
	if target.is_empty():
		print("[S38R] t157 no_hunt_row")
		return
	var id := StringName(target.get(&"id", &""))
	var first: Dictionary = panel.call(&"accept", id)
	var after: Array = panel.call(&"board_rows")
	var second: Dictionary = panel.call(&"accept", id)
	print("[S38R] t157 first_ok=%s rows %d->%d id_gone=%s second_ok=%s active=%d"
		% [str(bool(first.get(&"ok", false))), rows.size(), after.size(),
		str(not _ids(after).has(String(id))), str(bool(second.get(&"ok", false))),
		Registry.active_count(profile)])


func _report_pins() -> void:
	print("[S38R] pins band=%d board=%d max_active=%d cancel=%d round=%d sc=%s"
		% [Clock.BAND_SECONDS, Registry.BOARD_SIZE, Registry.MAX_ACTIVE,
		Registry.CANCEL_FEE, Registry.ROUND_UNIT, str(Registry.SC)])
	print("[S38R] pins hunt=%d escort=%d haul=%d known_floor=%d known_hook=%s gate_floor=%d"
		% [Registry.HUNT_FLAT, Registry.ESCORT_FLAT, Registry.HAUL_FLAT,
		Registry.KNOWN_FLOOR, str(Registry.KNOWN_HOOK),
		StationRegistryScript.CONTRACTS_FLOOR])


func _select_sync(deck: int) -> void:
	_station.call(&"_select_module", deck, true)
	await _frames(6)


func _panel() -> Control:
	return _station.call(&"service_panel", CONTRACTS) as Control


func _plate_texts() -> Array:
	var out: Array = []
	var plate := _station.get_node_or_null(NodePath("%StationPlate"))
	if plate == null:
		return out
	for child: Node in plate.find_children("*", "Label", true, false):
		out.append((child as Label).text)
	return out


func _first_row(rows: Array) -> String:
	if rows.is_empty():
		return "none"
	var row: Dictionary = rows[0]
	return "%s · %d CR · %s" % [
		String(row.get(&"type", &"")), Registry.reward(row),
		String(row.get(&"objective", &""))]


func _ids(rows: Array) -> Array:
	var out: Array = []
	for row: Dictionary in rows:
		out.append(String(row.get(&"id", &"")))
	return out


func _mmss_seconds(text: String) -> int:
	var marker := text.rfind(" ")
	if marker < 0:
		return -1
	var parts := text.substr(marker + 1).split(":")
	if parts.size() != 2:
		return -1
	return int(parts[0]) * 60 + int(parts[1])


func _descends(child: Node, ancestor: Node) -> bool:
	var node := child
	while node != null:
		if node == ancestor:
			return true
		node = node.get_parent()
	return false


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _frames(count: int) -> void:
	for _i: int in count:
		await get_tree().process_frame
