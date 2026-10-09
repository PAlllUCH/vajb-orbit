extends Node
## S38 evidence probe: what the station shell sees when the game is started from
## the main menu, and what the contracts board does about it.
##
## The menu's PLAY routes straight to the station hub, and nothing on that path
## files the docked place (`game.gd:_file_docked_station` only runs on the
## docking route), so every reader of `StationRegistry.docked_station` starts
## empty. This probe measures that state on the real scene, then measures the
## same scene with the place filed, and reports the band countdown arithmetic
## the board's refresh needs.
##
##   godot --headless --path vajb-orbit res://tests/probe_s38_start_board.tscn --quit-after 1200
##
## Prints [S38P] lines only. Sandboxes PlayerProfile (the gate idiom) so the
## owner's live account is untouched.

const THEME_PATH := "res://ui/theme/vajb_theme.tres"
const STATION := "res://ui/screens/station.tscn"
const W := 1920.0
const H := 1080.0
const SCRATCH_DIR := "user://_s38_scratch"
const SCRATCH_PROFILE := "user://_s38_scratch/profile.cfg"

const SERVICES := 7
const OVERVIEW := 6
const CONTRACTS: StringName = &"contracts"
const START_SECTOR: StringName = &"sector_1"

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
	if _station == null:
		print("[S38P] STATION MOUNT=FAIL")
		get_tree().quit(1)
		return
	await _report_start_state()
	await _report_filed_state()
	_report_band()
	print("[S38P] done")
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
	_host.position = Vector2.ZERO
	add_child(_host)
	var packed := load(STATION) as PackedScene
	_station = packed.instantiate() as Control
	_host.add_child(_station)
	await _frames(30)


func _report_start_state() -> void:
	var profile := _profile()
	var filed := StringName(profile.call(&"docked_station"))
	var row := StationRegistryScript.docked_station(profile)
	print("[S38P] start filed_id=%s row_empty=%s board_of_empty_row=%d"
		% [String(filed), str(row.is_empty()), Registry.board({}, 0).size()])
	await _open_services()
	var panel := _contracts_panel()
	if panel == null:
		print("[S38P] start CONTRACTS panel=NULL")
		return
	var board: Array = panel.get(&"_board")
	var station_row: Dictionary = panel.get(&"_station_row")
	print("[S38P] start panel_row_empty=%s board=%d empty_text=%s"
		% [str(station_row.is_empty()), board.size(), str(panel.get(&"_empty_text"))])
	print("[S38P] start board_empty_visible=%s counter=%s"
		% [str((panel.get(&"_board_empty") as Label).visible),
		str((panel.get(&"_counter") as Label).text)])
	await _select(OVERVIEW)
	var plate := _plate_texts()
	print("[S38P] start plate=%s" % str(plate))


func _report_filed_state() -> void:
	var profile := _profile()
	var row := StationRegistryScript.primary_for(START_SECTOR)
	profile.call(&"set_docked_station", StringName(row.get(&"id", &"")))
	await _select(SERVICES)
	await _frames(4)
	var panel := _contracts_panel()
	if panel == null:
		print("[S38P] filed CONTRACTS panel=NULL")
		return
	var stale: Array = panel.get(&"_board")
	print("[S38P] filed_unrefreshed id=%s board=%d"
		% [String(row.get(&"id", &"")), stale.size()])
	panel.call(&"refresh_profile", &"docked_station")
	await _frames(4)
	var board: Array = panel.get(&"_board")
	print("[S38P] filed_refreshed id=%s board=%d empty_text=%s"
		% [String(row.get(&"id", &"")), board.size(), str(panel.get(&"_empty_text"))])
	if not board.is_empty():
		var first: Dictionary = board[0]
		print("[S38P] filed first type=%s reward=%d objective=%s"
			% [String(first.get(&"type", &"")), Registry.reward(first),
			str(first.get(&"objective", &""))])
	await _select(OVERVIEW)
	print("[S38P] filed plate=%s" % str(_plate_texts()))


func _report_band() -> void:
	var now := Clock.now()
	var band := Registry.band_index(now)
	var elapsed := now % Clock.BAND_SECONDS
	var remaining := Clock.BAND_SECONDS - elapsed
	print("[S38P] band now=%d band=%d band_seconds=%d elapsed=%d remaining=%d"
		% [now, band, Clock.BAND_SECONDS, elapsed, remaining])
	var a := Registry.board(StationRegistryScript.primary_for(START_SECTOR), 0, now)
	var b := Registry.board(
		StationRegistryScript.primary_for(START_SECTOR), 0, now + remaining
	)
	print("[S38P] band next_roll_differs=%s next_first=%s"
		% [str(_ids(a) != _ids(b)), str(_ids(b).slice(0, 2))])


func _ids(rows: Array) -> Array:
	var out: Array = []
	for row: Dictionary in rows:
		out.append(String(row.get(&"id", &"")))
	return out


func _open_services() -> void:
	await _select(SERVICES)


func _select(deck: int) -> void:
	_station.call(&"_select_module", deck, true)
	await _frames(6)


func _contracts_panel() -> CanvasItem:
	return _station.call(&"service_panel", CONTRACTS) as CanvasItem


func _plate_texts() -> Array:
	var out: Array = []
	var plate := _station.get_node_or_null(NodePath("%StationPlate"))
	if plate == null:
		return out
	for child: Node in plate.find_children("*", "Label", true, false):
		out.append((child as Label).text)
	return out


func _frames(count: int) -> void:
	for _i: int in count:
		await get_tree().process_frame
