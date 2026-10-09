extends Node
## S38 evidence probe: what the station shell sees when the game is started from
## the main menu, and what the contracts board does about it.
##
## The menu's PLAY routes straight to the station hub, and nothing on that path
## files the docked place (`game.gd:_file_docked_station` only runs on the
## docking route). Before S38 that meant every reader of
## `StationRegistry.docked_station` started empty; H1 makes an empty filed id
## mean "no run has filed a place" and resolve the starting sector's primary.
## This probe measures the cold start on the real scene, the countdown moving on
## its own (two reads one second apart, real time), the boundary re-roll driven
## directly (no 20-minute wait), then the same scene with the place filed.
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
const TICK_WAIT := 1.2

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
	await _report_countdown()
	await _report_filed_state()
	await _report_boundary()
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


## The cold start: no run has filed a place, and the hub entered from the menu must
## still offer the starting sector's primary's board and its own plate.
func _report_start_state() -> void:
	var profile := _profile()
	var filed := StringName(profile.call(&"docked_station"))
	var row := StationRegistryScript.docked_station(profile)
	print("[S38P] start filed_id=%s row_empty=%s board_of_empty_row=%d"
		% [String(filed), str(row.is_empty()), Registry.board({}, 0).size()])
	var start := StationRegistryScript.starting_station()
	print("[S38P] start starting_station=%s starting_sector=%d"
		% [String(start.get(&"id", &"")), int(start.get(&"sector", 0))])
	print("[S38P] start docked_id=%s docked_name=%s"
		% [
			String(StationRegistryScript.docked_station_id(profile)),
			String(row.get(&"name", &"")),
		])
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
	_print_board("start", board)
	await _select(OVERVIEW)
	var plate := _plate_texts()
	print("[S38P] start plate=%s" % str(plate))


## H2: the U22 readout reads the clock's own remainder and moves on its own - two
## reads `TICK_WAIT` apart on the live 1 Hz tick, no override, no player action.
func _report_countdown() -> void:
	await _select(SERVICES)
	var panel := _contracts_panel()
	if panel == null:
		print("[S38P] countdown CONTRACTS panel=NULL")
		return
	var first := String(panel.call(&"roll_readout"))
	var remaining := int(panel.call(&"roll_remaining"))
	var now := Clock.now()
	print("[S38P] countdown first=%s remaining=%d arithmetic=%d band_seconds=%d"
		% [
			first,
			remaining,
			Clock.BAND_SECONDS - now % Clock.BAND_SECONDS,
			Clock.BAND_SECONDS,
		])
	var timer := panel.get(&"_tick_timer") as Timer
	print("[S38P] countdown timer_wait=%s one_shot=%s running=%s"
		% [
			str(timer.wait_time if timer != null else -1.0),
			str(timer.one_shot if timer != null else true),
			str(not timer.is_stopped() if timer != null else false),
		])
	await _wait(TICK_WAIT)
	var second := String(panel.call(&"roll_readout"))
	print("[S38P] countdown second=%s moved=%s" % [second, str(second != first)])


## H3: the boundary driven directly - the clock is pinned to the band edge, one tick
## lands, and the board must be the next band's with the readout restarted at 20:00.
func _report_boundary() -> void:
	var panel := _contracts_panel()
	if panel == null:
		print("[S38P] boundary CONTRACTS panel=NULL")
		return
	var now := Clock.now()
	var remaining := Clock.BAND_SECONDS - now % Clock.BAND_SECONDS
	var before := _ids(panel.get(&"_board"))
	var before_band := int(panel.call(&"board_band"))
	Clock.set_override(now + remaining)
	panel.call(&"_tick")
	var after := _ids(panel.get(&"_board"))
	print("[S38P] boundary before_band=%d after_band=%d expected_band=%d"
		% [before_band, int(panel.call(&"board_band")), Registry.band_index(now + remaining)])
	print("[S38P] boundary readout=%s" % String(panel.call(&"roll_readout")))
	print("[S38P] boundary rows_are_next_band=%s rows_changed=%s"
		% [
			str(after == _ids(Registry.board(StationRegistryScript.starting_station(), 0))),
			str(after != before),
		])
	print("[S38P] boundary next_first=%s" % str(after.slice(0, 2)))
	Clock.clear_override()
	panel.call(&"refresh_profile", &"docked_station")
	await _frames(4)


## The same scene with the place filed: the board and the plate read the filed row.
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
	_print_board("filed", board)
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


func _print_board(label: String, rows: Array) -> void:
	for index in mini(rows.size(), 2):
		var row: Dictionary = rows[index]
		print("[S38P] %s row%d id=%s type=%s reward=%d objective=%s"
			% [
				label,
				index,
				String(row.get(&"id", &"")),
				String(row.get(&"type", &"")),
				Registry.reward(row),
				String(row.get(&"objective", &"")),
			])


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


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _frames(count: int) -> void:
	for _i: int in count:
		await get_tree().process_frame
