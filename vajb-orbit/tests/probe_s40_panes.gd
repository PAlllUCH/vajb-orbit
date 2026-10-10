extends Node
## S40 visibility review probe: renders every station deck into full-resolution
## 1920x1080 PNGs **and** audits the legibility of every text label on each deck.
##
## The audit is a WCAG contrast reading:
##   * text colour   = the label's own resolved `font_color`, walked through
##                     `theme_type_variation` and the ancestor `modulate` chain, so a
##                     dimmed subtree reads as dimmed;
##   * background    = the 20th-percentile colour of the framebuffer inside the label's
##                     own INK rect (the glyph box, not the whole control rect, so a
##                     left-aligned label on a wide control is not judged by the empty
##                     dark space to its right);
##   * contrast      = (L1+0.05)/(L2+0.05) on WCAG relative luminance.
## 4.5 is AA for small text, 3.0 for large text; below 3.0 is unreadable.
##
## A label over the deck backdrop art reads as a *bright, high-variance* background; a
## label on a flat panel reads as a uniform dark one. `spread` (p60-p20 of the ink rect)
## is what separates "too dim" from "no panel behind it".
##
## Not part of the gate; quits itself.
##
## Run:
##   ~/.local/bin/godot --path vajb-orbit res://tests/probe_s40_panes.tscn --quit-after 3000
## PNGs land in /tmp/vajb_review/; the audit prints [S40P] AUDIT / WORST lines.

const OUT_DIR := "/tmp/vajb_review"
const VIEW := Vector2i(1920, 1080)
const SHIP: StringName = &"ship_vanguard"
const TAG := "[S40P]"
const RATIO_AA_SMALL := 4.5
const RATIO_AA_LARGE := 3.0
const WORST_N := 90
## An ink rect whose background swings this far between its p20 and p60 is sitting on
## picture, not on a panel.
const SPREAD_ART := 0.02

var _viewport: SubViewport = null
var _host: Control = null
var _station: Control = null
var _profile: Node = null


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	_profile = get_node_or_null(NodePath("/root/PlayerProfile"))
	if _profile == null:
		print("%s FAIL no PlayerProfile autoload" % TAG)
		get_tree().quit(1)
		return
	_seed_profile()
	_viewport = SubViewport.new()
	_viewport.name = &"ReviewViewport"
	_viewport.size = VIEW
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	_host = Control.new()
	_host.name = &"ReviewHost"
	_host.theme = load("res://ui/theme/vajb_theme.tres") as Theme
	_host.size = Vector2(VIEW)
	_viewport.add_child(_host)
	var scene := load("res://ui/screens/station.tscn") as PackedScene
	_station = scene.instantiate() as Control
	_host.add_child(_station)
	_station.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in 20:
		await get_tree().process_frame
	await _walk_decks()


func _seed_profile() -> void:
	_profile.set(&"save_path", "user://probe_s40_panes.cfg")
	_profile.set(&"_credits", 50000)
	_profile.set(&"_active_ship", SHIP)
	var owned: Array[StringName] = [SHIP]
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_cargo", {&"mineral_iron": 12, &"mineral_copper": 4, &"mineral_gold": 1})
	_profile.set(&"_ammo", {&"ammo_laser": 240})


func _walk_decks() -> void:
	var decks := {
		0: "deck0_armory",
		1: "deck1_refinery",
		2: "deck2_exchange",
		3: "deck3_auction",
		4: "deck4_shipyard",
		5: "deck5_launch",
		6: "deck6_overview",
		7: "deck7_services",
	}
	for deck: int in decks.keys():
		_station.call(&"_select_module", deck, true)
		for i in 24:
			await get_tree().process_frame
		await _audit(String(decks[deck]))
		await _shoot(String(decks[deck]))
		if deck == 0:
			await _armory_modes()
	print("%s done" % TAG)
	get_tree().quit()


func _armory_modes() -> void:
	var panels: Array = _station.get(&"_panels")
	if panels.is_empty():
		return
	var panel := panels[0] as Control
	if panel == null or not panel.has_method(&"set_mode"):
		return
	for mode: StringName in [(&"battery") as StringName, (&"fit") as StringName]:
		panel.call(&"set_mode", mode)
		for i in 24:
			await get_tree().process_frame
		await _audit("deck0_armory_%s" % String(mode))
		await _shoot("deck0_armory_%s" % String(mode))


func _audit(deck: String) -> void:
	var image := await _frame()
	var entries: Array[Dictionary] = []
	_collect(_station, entries)
	var rows: Array[Dictionary] = []
	for entry: Dictionary in entries:
		var rect := _clamp_rect(_ink_rect(entry[&"node"] as Node, entry[&"rect"] as Rect2))
		if rect.size.x < 4.0 or rect.size.y < 4.0:
			continue
		var colour := _text_colour(entry[&"node"] as Node)
		var roof := _roof_colour(entry[&"node"] as Node, entry[&"rect"] as Rect2)
		var stats := _sample(image, rect)
		var bg: Color = stats[&"p20"]
		var l1 := _relative(colour)
		var l2 := _relative(bg)
		var ratio := (maxf(l1, l2) + 0.05) / (minf(l1, l2) + 0.05)
		rows.append({
			&"name": String(entry[&"name"]),
			&"text": String(entry[&"text"]).substr(0, 34),
			&"fg": colour,
			&"bg": bg,
			&"ratio": ratio,
			&"spread": _relative(stats[&"p60"] as Color) - _relative(stats[&"p20"] as Color),
			&"roof": roof,
			&"rect": rect,
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a[&"ratio"] < b[&"ratio"])
	var art := 0
	for row: Dictionary in rows:
		if float(row[&"spread"]) > SPREAD_ART:
			art += 1
	print(
		"%s AUDIT deck=%s labels=%d below_3=%.0f%% below_4.5=%.0f%% on_art=%d"
		% [
			TAG, deck, rows.size(),
			_pct(rows, RATIO_AA_LARGE), _pct(rows, RATIO_AA_SMALL), art,
		]
	)
	var unroofed: Array[Dictionary] = []
	for row: Dictionary in rows:
		if String(row[&"roof"]).is_empty():
			unroofed.append(row)
	unroofed.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a[&"ratio"] < b[&"ratio"])
	for row: Dictionary in unroofed:
		print(
			"%s   NOROOF deck=%s ratio=%.2f fg=%s bg=%s rect=%s node=%s text=\"%s\""
			% [
				TAG, deck, float(row[&"ratio"]),
				_hex(row[&"fg"] as Color), _hex(row[&"bg"] as Color),
				_rect_str(row[&"rect"] as Rect2), String(row[&"name"]), String(row[&"text"]),
			]
		)
	for i: int in mini(WORST_N, rows.size()):
		var row: Dictionary = rows[i]
		print(
			"%s   WORST deck=%s ratio=%.2f spread=%.3f fg=%s bg=%s roof=%s rect=%s node=%s text=\"%s\""
			% [
				TAG, deck, float(row[&"ratio"]), float(row[&"spread"]),
				_hex(row[&"fg"] as Color), _hex(row[&"bg"] as Color),
				String(row[&"roof"]), _rect_str(row[&"rect"] as Rect2),
				String(row[&"name"]), String(row[&"text"]),
			]
		)


func _pct(rows: Array[Dictionary], limit: float) -> float:
	if rows.is_empty():
		return 0.0
	var n := 0
	for row: Dictionary in rows:
		if float(row[&"ratio"]) < limit:
			n += 1
	return 100.0 * float(n) / float(rows.size())


func _hex(colour: Color) -> String:
	return "#%02x%02x%02x" % [int(colour.r * 255.0), int(colour.g * 255.0), int(colour.b * 255.0)]


func _rect_str(rect: Rect2) -> String:
	return "(%.0f,%.0f %.0fx%.0f)" % [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


func _collect(node: Node, out: Array[Dictionary]) -> void:
	if node is CanvasItem and not (node as CanvasItem).is_visible_in_tree():
		return
	if node is Label:
		var label := node as Label
		if not label.text.strip_edges().is_empty():
			out.append({
				&"name": String(label.name), &"text": label.text,
				&"rect": label.get_global_rect(), &"node": label,
			})
	elif node is RichTextLabel:
		var rich := node as RichTextLabel
		if not rich.get_parsed_text().strip_edges().is_empty():
			out.append({
				&"name": String(rich.name), &"text": rich.get_parsed_text(),
				&"rect": rich.get_global_rect(), &"node": rich,
			})
	for child: Node in node.get_children():
		_collect(child, out)


## The glyph box: the control rect narrowed to the text's own measured width, offset by the
## label's horizontal alignment. A wide left-aligned control rect would otherwise be judged
## by the empty space to the right of the ink.
func _ink_rect(node: Node, rect: Rect2) -> Rect2:
	if not (node is Label):
		return rect
	var label := node as Label
	var font := label.get_theme_font(&"font")
	if font == null:
		return rect
	var size := label.get_theme_font_size(&"font_size")
	var width := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x
	if width <= 0.0:
		return rect
	var x := rect.position.x
	match label.horizontal_alignment:
		HORIZONTAL_ALIGNMENT_CENTER:
			x += maxf((rect.size.x - width) * 0.5, 0.0)
		HORIZONTAL_ALIGNMENT_RIGHT:
			x += maxf(rect.size.x - width, 0.0)
		_:
			pass
	return Rect2(x, rect.position.y, minf(width, rect.size.x), rect.size.y)


## Is there an opaque surface between this label and the pane root? A `StyleBoxFlat` with a
## near-solid fill or a `StyleBoxTexture` on any ancestor Control counts as a roof; a label
## with none is drawing straight onto the deck backdrop picture.
func _roof_colour(node: Node, rect: Rect2) -> String:
	var walker := (node as CanvasItem).get_parent() as CanvasItem
	while walker != null:
		if _is_surface(walker) and _covers(walker as Control, rect):
			for slot: StringName in [&"panel", &"normal", &"background"]:
				var box := (walker as Control).get_theme_stylebox(slot)
				if box is StyleBoxFlat and (box as StyleBoxFlat).bg_color.a >= 0.9:
					return "%s.%s" % [String(walker.name), String(slot)]
				## A banded cut (`ui_panel_frame`) draws a hollow frame whose centre the deck
				## backdrop shows through; only a solid fill is a roof.
				if box is StyleBoxTexture and _texture_centre_opaque((box as StyleBoxTexture).texture):
					continue
		walker = walker.get_parent() as CanvasItem
	return ""


## A node that can carry a painted surface. A bare container asks the theme for `panel` too,
## but a container paints nothing, so only real surface classes count.
func _is_surface(node: CanvasItem) -> bool:
	return (
		node is PanelContainer or node is Panel or node is Button
		or node is TextureRect or node is ColorRect or node is NinePatchRect
	)


## Does the surface's rect cover the ink? A panel somewhere else on the pane is not a roof.
func _covers(control: Control, rect: Rect2) -> bool:
	var area := control.get_global_rect().intersection(rect)
	if area.size.x <= 0.0 or area.size.y <= 0.0:
		return false
	return area.get_area() >= rect.get_area() * 0.9


## A nine-slice frame with a hollow centre (the chrome family's `ui_panel_frame` and every
## band cut) is not a roof: the deck backdrop shows straight through its middle. Only a
## texture whose own centre is opaque backs its content.
func _texture_centre_opaque(texture: Texture2D) -> bool:
	if texture == null:
		return false
	var image := texture.get_image()
	if image == null:
		return false
	return image.get_pixel(image.get_width() / 2, image.get_height() / 2).a >= 0.9


## The label's own resolved text colour: the theme's `font_color` for its type variation,
## multiplied by the `modulate` chain above it (a subtree dimmed at 0.4 reads as dimmed).
func _text_colour(node: Node) -> Color:
	var colour := Color.WHITE
	if node is Label:
		colour = (node as Label).get_theme_color(&"font_color")
	elif node is RichTextLabel:
		colour = (node as RichTextLabel).get_theme_color(&"default_color")
	var walker := node as CanvasItem
	while walker != null:
		colour *= walker.modulate
		walker = walker.get_parent() as CanvasItem
	return colour


func _clamp_rect(rect: Rect2) -> Rect2:
	var x0 := clampf(rect.position.x, 0.0, float(VIEW.x))
	var y0 := clampf(rect.position.y, 0.0, float(VIEW.y))
	var x1 := clampf(rect.position.x + rect.size.x, 0.0, float(VIEW.x))
	var y1 := clampf(rect.position.y + rect.size.y, 0.0, float(VIEW.y))
	return Rect2(x0, y0, maxf(x1 - x0, 0.0), maxf(y1 - y0, 0.0))


func _sample(image: Image, rect: Rect2) -> Dictionary:
	var colours: Array[Color] = []
	var y := int(rect.position.y)
	while y < int(rect.position.y + rect.size.y):
		var x := int(rect.position.x)
		while x < int(rect.position.x + rect.size.x):
			colours.append(image.get_pixel(x, y))
			x += 1
		y += 1
	if colours.is_empty():
		return {&"p20": Color.BLACK, &"p60": Color.BLACK}
	colours.sort_custom(func(a: Color, b: Color) -> bool: return _relative(a) < _relative(b))
	var n := colours.size()
	return {&"p20": colours[int(float(n) * 0.20)], &"p60": colours[int(float(n) * 0.60)]}


## WCAG relative luminance.
func _relative(colour: Color) -> float:
	return 0.2126 * _channel(colour.r) + 0.7152 * _channel(colour.g) + 0.0722 * _channel(colour.b)


func _channel(value: float) -> float:
	if value <= 0.03928:
		return value / 12.92
	return pow((value + 0.055) / 1.055, 2.4)


func _frame() -> Image:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	return _viewport.get_texture().get_image()


func _shoot(name: String) -> void:
	var image := await _frame()
	var path := "%s/%s.png" % [OUT_DIR, name]
	var err := image.save_png(path)
	print("%s SHOT %s err=%d size=%s" % [TAG, path, err, str(image.get_size())])
