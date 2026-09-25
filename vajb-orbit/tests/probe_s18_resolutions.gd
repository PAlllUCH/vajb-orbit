extends Node
## S18's resolution probe: mounts the shipped station at whatever window the run was
## launched with, waits for the layout, and prints the ARMORY pane's derived geometry -
## the host rect, the console the pane derives from it (P6), the five bays, the cell grid
## and the two wells - plus a containment check against the canvas.
##
## The wave's standalone evidence runs this scene three times, once per proof canvas:
##
##   $GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/probe_s18_resolutions.tscn \
##     --resolution 1280x720 --quit-after 400
##
## (headless honours --resolution for the stretch canvas; a project_run game does not - the
## gap AGENTS.md records as backlog row L222 - which is why this is a standalone run.)

const StationScene := preload("res://ui/screens/station.tscn")

const SETTLE_FRAMES := 12
## The three proof canvases the brief names, as window sizes. The project pins
## `window_width_override`/`window_height_override`, so `--resolution` cannot move the
## window; the probe resizes it itself (a standalone run, where a window change is real).
const PROOF_WINDOWS: Array[Vector2i] = [
	Vector2i(1280, 720), Vector2i(2560, 1080), Vector2i(1280, 1024)
]


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var station := StationScene.instantiate() as Control
	if station == null:
		push_error("s18 probe: the station scene failed to instantiate")
		get_tree().quit(1)
		return
	get_tree().root.add_child(station)
	## The project pins `window_width_override`/`window_height_override` (both 1920x1080),
	## which clamps the window; the probe clears them so the three proof sizes are real.
	ProjectSettings.set_setting("display/window/size/window_width_override", 0)
	ProjectSettings.set_setting("display/window/size/window_height_override", 0)
	for window: Vector2i in PROOF_WINDOWS:
		get_window().size = window
		for _frame in SETTLE_FRAMES:
			await get_tree().process_frame
		_report(station)
	get_tree().quit(0)


func _report(station: Control) -> void:
	var canvas: Vector2 = get_viewport().get_visible_rect().size
	var window: Vector2i = DisplayServer.window_get_size()
	var panes: Array = station.get(&"_panels")
	if panes.is_empty():
		push_error("s18 probe: the station carries no panes")
		return
	var armory := panes[0] as Control
	var host := armory.get_global_rect()
	var style: Resource = armory.call(&"style")
	var console: Rect2 = style.console_rect(Rect2(Vector2.ZERO, armory.size))
	var bays: Array = armory.call(&"bay_rects")
	var wells: Array = armory.call(&"well_rects")
	print(
		"[s18res] window=%s root=%s canvas=%s scale=%s mode=%d aspect=%d"
		% [
			str(window), str(get_window().size), str(canvas),
			str(get_window().content_scale_size),
			get_window().content_scale_mode, get_window().content_scale_aspect,
		]
	)
	print("[s18res] pane_host=%s console_local=%s" % [str(host), str(console)])
	print("[s18res] canvas_encloses_pane=%s" % str(Rect2(Vector2.ZERO, canvas).encloses(host)))
	print("[s18res] host_encloses_console=%s" % str(Rect2(Vector2.ZERO, armory.size).encloses(console)))
	for index in bays.size():
		var bay: Rect2 = bays[index]
		print(
			"[s18res] bay%d=%s inside_pane=%s"
			% [index + 1, str(bay), str(Rect2(Vector2.ZERO, armory.size).encloses(bay))]
		)
	for index in wells.size():
		var well: Rect2 = wells[index]
		print(
			"[s18res] well%d=%s inside_pane=%s"
			% [index + 1, str(well), str(Rect2(Vector2.ZERO, armory.size).encloses(well))]
		)
	var cell: Rect2 = style.bay_cell_rect(0, Rect2(Vector2.ZERO, bays[0].size))
	print("[s18res] cell0=%s inside_bay=%s" % [str(cell), str(Rect2(Vector2.ZERO, bays[0].size).encloses(cell))])
	print(
		"[s18res] band=%s wells_band=%s"
		% [str(style.bays_band(Rect2(Vector2.ZERO, armory.size))), str(style.wells_rect(Rect2(Vector2.ZERO, armory.size)))]
	)
