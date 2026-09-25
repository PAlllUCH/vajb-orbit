extends Node
## S18-R1's reviewer probe (wave S18 review): mounts the shipped station in a running
## (windowed) game and measures, at each of the three proof windows, the ARMORY pane's
## live ink and state - every visible Label/Button's resolved font size, any font_size
## override, the caption contrast computed from the pane's own style colours, the pack
## card wording on the drawn cards and the bay chip's label-plus-shape state - then
## saves the frame to user:// for the reviewer's visual comparison against the D13
## mockups. Bounded by --quit-after; it quits itself.
##
##   $GODOT_CONSOLE --path "$VAJB_PROJ" res://tests/probe_s18r1_audit.tscn --quit-after 1200

const StationScene := preload("res://ui/screens/station.tscn")

const WINDOWS: Array[Vector2i] = [
	Vector2i(1280, 720), Vector2i(2560, 1080), Vector2i(1280, 1024)
]
const SETTLE_FRAMES := 14
const MIN_INK := 13


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var station := StationScene.instantiate() as Control
	if station == null:
		push_error("s18r1 probe: the station scene failed to instantiate")
		get_tree().quit(1)
		return
	get_tree().root.add_child(station)
	ProjectSettings.set_setting("display/window/size/window_width_override", 0)
	ProjectSettings.set_setting("display/window/size/window_height_override", 0)
	## A directly-mounted station keeps the shell's entry fade; clear it to read the ink.
	var fade := station.get_node_or_null(^"Layout/Fade") as ColorRect
	if fade == null:
		fade = station.get_node_or_null(^"Fade") as ColorRect
	if fade != null:
		fade.color.a = 0.0
	var router := get_tree().root.get_node_or_null(NodePath(&"Router"))
	if router != null:
		var fade_rect := router.get(&"_fade_rect") as ColorRect
		if fade_rect != null:
			fade_rect.color.a = 0.0
	for window: Vector2i in WINDOWS:
		get_window().size = window
		for _frame in SETTLE_FRAMES:
			await get_tree().process_frame
		_audit(station, window)
		## The Router re-arms the fade on mount; clear it again right before the read.
		if router != null:
			var live_fade := router.get(&"_fade_rect") as ColorRect
			if live_fade != null:
				live_fade.color.a = 0.0
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		var path := "user://s18r1_%dx%d.png" % [window.x, window.y]
		image.save_png(path)
		print("[s18r1] wrote %s (%dx%d)" % [path, image.get_width(), image.get_height()])
	get_tree().quit(0)


func _audit(station: Control, window: Vector2i) -> void:
	var panes: Array = station.get(&"_panels")
	if panes.is_empty():
		print("[s18r1] window=%s NO PANES" % str(window))
		return
	var pane := panes[0] as Control
	var small: Array[String] = []
	var overrides: Array[String] = []
	_collect(pane, small, overrides)
	print("[s18r1] window=%s canvas=%s ink_below_13=%d font_size_overrides=%d"
		% [str(window), str(get_viewport().get_visible_rect().size), small.size(), overrides.size()])
	for entry: String in small:
		print("[s18r1]   BELOW FLOOR: %s" % entry)
	for entry: String in overrides:
		print("[s18r1]   OVERRIDE: %s" % entry)
	_style_contrast(pane)
	_card_texts(pane)
	_chip_state(pane)


## Every visible Label/Button in the pane whose resolved `font_size` is under the floor.
func _collect(node: Node, small: Array[String], overrides: Array[String]) -> void:
	var control := node as Control
	if control != null:
		if control.has_theme_font_size_override(&"font_size"):
			overrides.append("%s %s" % [node.name, node.get_class()])
		if control.visible and (node is Label or node is Button):
			var size := control.get_theme_font_size(&"font_size")
			if size < MIN_INK:
				small.append("%s %s (%d px)" % [node.name, node.get_class(), size])
	for child: Node in node.get_children():
		_collect(child, small, overrides)


## The caption tones against every surface the pane draws them on, computed live.
func _style_contrast(pane: Control) -> void:
	var style: Resource = pane.call(&"style")
	for pair: Array in [
		[&"caption", &"bay_bg"], [&"caption", &"cell_bg"], [&"caption", &"ledge_bg"],
		[&"caption", &"item_bg"], [&"caption", &"chip_bg"], [&"caption_void", &"void_base"],
		[&"caption_void", &"panel_steel"], [&"caption_void", &"metal_dark"],
	]:
		var ratio := _contrast(style.colour(pair[0]), style.colour(pair[1]))
		print("[s18r1] contrast %s on %s = %.2f %s"
			% [pair[0], pair[1], ratio, "OK" if ratio >= 4.5 else "BELOW"]) 


func _card_texts(pane: Control) -> void:
	var rows := pane.get_node_or_null("%ArmoryRows") as Control
	if rows == null:
		return
	for child: Node in rows.get_children():
		var card := child as Button
		if card == null:
			continue
		var held := card.find_child("Held", true, false)
		var price := card.find_child("Price", true, false)
		if held == null or price == null:
			continue
		print("[s18r1] card %s title=%s price=%s held=%s"
			% [
				card.name,
				String((card.find_child("Title", true, false) as Label).text),
				String((price.get_node(^"Value") as Label).text),
				String((held.get_node(^"Value") as Label).text),
			])


func _chip_state(pane: Control) -> void:
	for index in 2:
		var row := pane.get_node_or_null(
			NodePath("%RackRows/Rack" + str(index + 1))
		) as Control
		if row == null:
			continue
		var state := row.get_node_or_null(^"Box/Head/State") as Label
		var chip := row.get_node_or_null(^"Box/Head/Chip") as Control
		if state == null or chip == null:
			continue
		print("[s18r1] bay B%d state=%s chevron=%s danger=%s"
			% [index + 1, state.text, str(chip.get(&"chevron")), str(chip.get(&"danger"))])


func _luminance(colour: Color) -> float:
	var channels: Array[float] = [colour.r, colour.g, colour.b]
	var weights: Array[float] = [0.2126, 0.7152, 0.0722]
	var out := 0.0
	for index in 3:
		var value: float = channels[index]
		var linear: float = value / 12.92 if value <= 0.03928 else pow((value + 0.055) / 1.055, 2.4)
		out += linear * weights[index]
	return out


func _contrast(first: Color, second: Color) -> float:
	var high: float = maxf(_luminance(first), _luminance(second))
	var low: float = minf(_luminance(first), _luminance(second))
	return (high + 0.05) / (low + 0.05)
