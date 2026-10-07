extends Node
## S37-R1's chrome-fit probe: per chrome-bearing station surface, the chrome's drawn box
## against the content box (icon + font-measured text, +10 % padding on the dominant axis).
## A canvas class letterboxes, so the visible chrome is the cut's OPAQUE box (alpha >= 0.5)
## scaled into the drawn rect; a nine-slice stretches between its caps, so the usable chrome
## is the rect inset by the live box's texture margins (then by its content margins). A
## surface is flagged when the chrome box is smaller than the padded content on either axis,
## or when the drawn aspect leaves the cut's by more than 20 %.

const StationScene := preload("res://ui/screens/station.tscn")
const ChromeFamily := preload("res://ui/theme/chrome_family.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const ArmoryScript := preload("res://ui/station/armory_panel.gd")
const RefineryRef := preload("res://game/refinery.gd")
const AuctionRef := preload("res://game/auction.gd")
const ClockScript := preload("res://autoload/world_clock.gd")
const Catalog := preload("res://game/mineral_catalog.gd")

const PROFILE_PATH := "user://probe_s37_r1.cfg"
const HOST := Vector2(1920.0, 1080.0)
const SHIP: StringName = &"ship_vanguard"
const PAD := 0.10
const UI_DIR := "res://assets/ui/"

var _screen: Control = null
var _profile: Node = null
var _seen: Dictionary = {}
var _opaque: Dictionary = {}
var _surfaces: int = 0
var _too_small: int = 0
var _stretched: int = 0


func _ready() -> void:
	var watchdog := get_tree().create_timer(90.0)
	watchdog.timeout.connect(func() -> void:
		print("[r37] WATCHDOG quit")
		get_tree().quit(2)
	)
	_run.call_deferred()


func _run() -> void:
	_profile = get_node_or_null("/root/PlayerProfile")
	if _profile == null:
		print("[r37] FAIL no PlayerProfile autoload")
		get_tree().quit(2)
		return
	_profile.set(&"save_path", PROFILE_PATH)
	_profile.set(&"_active_ship", SHIP)
	_profile.set(&"_owned_ships", [SHIP] as Array[StringName])
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_credits", 50000)
	_seed_station_state()

	var host := Control.new()
	host.name = "R37Host"
	host.theme = ThemeRes
	host.size = HOST
	add_child(host)
	_screen = StationScene.instantiate() as Control
	host.add_child(_screen)
	await _frames(2)

	_print_cuts()
	for deck in range(0, 7):
		_screen.call(&"_select_module", deck, true)
		await _frames(3)
		var pane := _pane(deck)
		if pane == null and deck == 6:
			pane = _screen.call(&"overview_pane") as Node
		_walk(_screen, _deck_label(deck), pane, false)

	_screen.call(&"_select_module", 0, true)
	await _frames(2)
	var armory := _pane(0)
	armory.call(&"set_mode", ArmoryScript.MODE_BATTERY)
	await _frames(3)
	_walk(_screen, "0-batt", armory, true)
	armory.call(&"set_mode", ArmoryScript.MODE_FIT)
	await _frames(1)
	_report_console(armory)

	_screen.call(&"_open_drawer")
	await _frames(4)
	var drawer := _screen.get(&"_drawer") as Node
	if drawer != null:
		_walk(drawer, "drawer", drawer, false)
	_screen.call(&"_close_drawer", true)
	await _frames(1)

	var tooltip := _screen.get(&"_tooltip") as PanelContainer
	if tooltip != null:
		tooltip.call(&"show_for", "PROBE MINING LASER II",
			"Fits medium hardpoints. 12 dps at 6 range. Draws 8 MW from the fit pool.",
			false, Vector2(10, 10), HOST)
		await _frames(2)
		_walk(tooltip, "tooltip", tooltip, false)
		tooltip.call(&"hide_tooltip")

	print("[r37] SUMMARY surfaces=%d too_small=%d stretched=%d" % [
		_surfaces, _too_small, _stretched])
	get_tree().quit(0)


## Seed the state the owner's named rows need: hold ore, a refinery job forced done, and a
## rolled auction shelf. Every write lands in the probe's own save file.
func _seed_station_state() -> void:
	_profile.add_credits(100000)
	_profile.add_cargo(Catalog.ore_id(&"iron"), 12)
	_profile.add_cargo(Catalog.ore_id(&"copper"), 8)
	RefineryRef.load_ore(_profile, &"iron", 12)
	var queued: Dictionary = RefineryRef.queue(_profile, &"iron", 2)
	if bool(queued.get(&"ok", false)):
		var jobs: Array[Dictionary] = RefineryRef.jobs(_profile)
		for job: Dictionary in jobs:
			job[&"ready_at"] = 0
		_profile.call(&"set_refinery_jobs", jobs)
	AuctionRef.evaluate_shelf(_profile, ClockScript.now())


func _frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame


func _pane(deck: int) -> Node:
	var panes: Array = _screen.get(&"_panels")
	if deck < 0 or deck >= panes.size():
		return null
	return panes[deck] as Node


func _deck_label(deck: int) -> String:
	if deck >= 0 and deck < 6:
		return ["ARMORY", "REFINERY", "EXCHANGE", "AUCTION", "SHIPYARD", "LAUNCH"][deck]
	return "OVERVIEW"


## ------------------------------------------------------------------ the walk


func _walk(root: Node, label: String, scope: Node, force: bool) -> void:
	_walk_node(root, label, scope, force)


func _walk_node(node: Node, label: String, scope: Node, force: bool) -> void:
	if node is Control:
		var control := node as Control
		if control.is_visible_in_tree():
			var surface := _classify(control)
			if not surface.is_empty():
				_record(control, surface, label, scope, force)
		for child in node.get_children():
			_walk_node(child, label, scope, force)


func _classify(control: Control) -> Dictionary:
	if control.has_meta(&"chrome_bg"):
		return {}
	if control.name == StringName("ChromeCanvas") or control.name == StringName("PaneBackdrop"):
		return {}
	if control.name == StringName("ConsolePanels"):
		return {}
	var cls := String(control.get_meta(&"chrome_class", ""))
	if not cls.is_empty():
		if ChromeFamily.CANVAS_CLASSES.has(cls) or control.has_node("ChromeCanvas"):
			return {"kind": "canvas", "cls": cls}
		return {"kind": "nine", "cls": cls}
	if control.name == StringName("RowPlate"):
		return {"kind": "nine", "cls": "C4", "code": true}
	if control is TextureRect or control is TextureButton or control is NinePatchRect:
		var tex := _node_texture(control)
		if tex != null and String(tex.resource_path).begins_with(UI_DIR):
			return {"kind": "texrect", "cls": String(tex.resource_path.get_file())}
		return {}
	var box := _surface_box(control)
	if box is StyleBoxTexture:
		var tex := (box as StyleBoxTexture).texture
		if tex != null and String(tex.resource_path).begins_with(UI_DIR):
			return {"kind": "nine", "cls": String(tex.resource_path.get_file()), "box": box}
	return {}


func _node_texture(node: Node) -> Texture2D:
	if node is TextureRect:
		return (node as TextureRect).texture
	if node is TextureButton:
		return (node as TextureButton).texture_normal
	if node is NinePatchRect:
		return (node as NinePatchRect).texture
	return null


func _record(control: Control, surface: Dictionary, label: String, scope: Node, force: bool) -> void:
	var deck := label
	if scope != null and scope != control and not (scope as Node).is_ancestor_of(control):
		deck = "shell"
	var key := "%s:%s" % [deck, control.get_path()]
	if not force and _seen.has(key):
		return
	_seen[key] = true
	_surfaces += 1

	var slot := control.size
	var cls := String(surface.cls)
	var kind := String(surface.kind)
	var drawn := Rect2(Vector2.ZERO, slot)
	var band := Rect2(Vector2.ZERO, slot)
	var cut := Vector2.ZERO
	var cut_asp := 0.0
	var margins := Vector4.ZERO
	var cmargins := Vector4.ZERO
	var tex_name := ""

	if kind == "canvas":
		drawn = ChromeFamily.canvas_rect(slot, cls)
		cut = ChromeFamily.cut_size(cls)
		cut_asp = ChromeFamily.cut_aspect(cls)
		var opa: Vector2 = _opaque_box(cls)
		var scale := drawn.size / cut
		var band_size: Vector2 = opa * scale
		band = Rect2(drawn.position + (drawn.size - band_size) * 0.5, band_size)
		var canvas := control.get_node_or_null(NodePath("ChromeCanvas")) as TextureRect
		if canvas != null and canvas.texture != null:
			tex_name = canvas.texture.resource_path.get_file()
	elif kind == "nine":
		var box := _live_box(control, surface)
		if box != null:
			margins = Vector4(box.texture_margin_left, box.texture_margin_top,
				box.texture_margin_right, box.texture_margin_bottom)
			cmargins = Vector4(box.content_margin_left, box.content_margin_top,
				box.content_margin_right, box.content_margin_bottom)
			if box.texture != null:
				tex_name = box.texture.resource_path.get_file()
				cut = box.texture.get_size()
				cut_asp = cut.x / maxf(cut.y, 0.001)
		else:
			margins = ChromeFamily.drawn_margins(cls, slot)
			cut = ChromeFamily.cut_size(cls)
			cut_asp = ChromeFamily.cut_aspect(cls)
		band = Rect2(Vector2(margins.x, margins.y),
			Vector2(maxf(slot.x - margins.x - margins.z, 0.0),
				maxf(slot.y - margins.y - margins.w, 0.0)))
	elif kind == "texrect":
		var tex := _node_texture(control)
		if tex != null:
			cut = tex.get_size()
			cut_asp = cut.x / maxf(cut.y, 0.001)
			tex_name = tex.resource_path.get_file()

	var content := _content_union(control, control)
	if control.name == StringName("RowPlate"):
		var parent := control.get_parent() as Control
		if parent != null:
			content = _content_union(parent, control)
	var needed := content.size
	if needed.x > 0.0 or needed.y > 0.0:
		if needed.x >= needed.y:
			needed.x *= 1.0 + PAD
		else:
			needed.y *= 1.0 + PAD
	var def_drawn := needed - drawn.size
	var def_band := needed - band.size
	var drawn_asp := drawn.size.x / maxf(drawn.size.y, 0.001)
	var stretch := 0.0
	if cut_asp > 0.0:
		stretch = drawn_asp / cut_asp
	var too_small := def_drawn.x > 0.5 or def_drawn.y > 0.5 \
		or def_band.x > 0.5 or def_band.y > 0.5
	var off_aspect := absf(stretch - 1.0) > 0.2
	if too_small:
		_too_small += 1
	if off_aspect:
		_stretched += 1
	var band_ok := _in_band(cls, slot) if kind == "nine" else true
	print("[r37] SURF deck=%s kind=%s cls=%s flags=%s%s slot=%.0fx%.0f drawn=%.1fx%.1f band=%.1fx%.1f need=%.1fx%.1f content=%.1fx%.1f def_drawn=%.1f/%.1f def_band=%.1f/%.1f stretch=%.3f marg=%.0f/%.0f/%.0f/%.0f cm=%.0f/%.0f/%.0f/%.0f tex=%s band_ok=%s node=%s" % [
		deck, kind, cls, "S" if too_small else "-", "A" if off_aspect else "-",
		slot.x, slot.y, drawn.size.x, drawn.size.y, band.size.x, band.size.y,
		needed.x, needed.y, content.size.x, content.size.y,
		def_drawn.x, def_drawn.y, def_band.x, def_band.y, stretch,
		margins.x, margins.y, margins.z, margins.w,
		cmargins.x, cmargins.y, cmargins.z, cmargins.w,
		tex_name, "Y" if band_ok else "n", _path_of(control)])


func _live_box(control: Control, surface: Dictionary) -> StyleBoxTexture:
	if surface.has("box"):
		return surface.box as StyleBoxTexture
	if surface.get("code", false):
		return ChromeFamily.stylebox(String(surface.cls), control.size) as StyleBoxTexture
	var box: StyleBox = _surface_box(control)
	return box as StyleBoxTexture


## The surface's own stylebox, asked by the item name its class actually defines:
## `get_theme_stylebox(&"normal")` on a non-Button returns ThemeDB's fallback box, which
## would mask every `panel`-style surface.
func _surface_box(control: Control) -> StyleBox:
	if control is Button:
		return control.get_theme_stylebox(&"normal")
	if control is PanelContainer or control is Panel:
		return control.get_theme_stylebox(&"panel")
	return null


func _in_band(cls: String, slot: Vector2) -> bool:
	if not ChromeFamily.BANDS.has(cls):
		return true
	var band: Rect2 = ChromeFamily.BANDS.get(cls)
	return slot.x >= band.position.x and slot.x <= band.end.x \
		and slot.y >= band.position.y and slot.y <= band.end.y


func _path_of(node: Node) -> String:
	var out := ""
	var walk := node
	while walk != null and walk != _screen:
		out = "%s/%s" % [walk.name, out]
		walk = walk.get_parent()
	return out


## ------------------------------------------------------------------ content union


func _content_union(root: Control, surface: Control) -> Rect2:
	var mm := {"has": false, "x0": 0.0, "y0": 0.0, "x1": 0.0, "y1": 0.0}
	if root is Button:
		var text := String((root as Button).text)
		if not text.is_empty():
			_grow_text(mm, root, Vector2.ZERO, text, (root as Button).alignment,
				VERTICAL_ALIGNMENT_CENTER)
	_gather(root, surface, root, mm)
	if not bool(mm.has):
		return Rect2()
	return Rect2(Vector2(mm.x0, mm.y0), Vector2(mm.x1 - mm.x0, mm.y1 - mm.y0))


func _gather(node: Node, surface: Control, top: Control, mm: Dictionary) -> void:
	for child in node.get_children():
		if child is Control:
			var c := child as Control
			if not c.is_visible_in_tree() or c == surface:
				continue
			if _is_chrome_node(c):
				continue
			var pos := c.global_position - top.global_position
			if c is Label:
				_grow_text(mm, c, pos, String(c.text), c.horizontal_alignment,
					c.vertical_alignment)
			elif c is Button:
				var text := String((c as Button).text)
				if not text.is_empty():
					_grow_text(mm, c, pos, text, (c as Button).alignment,
						VERTICAL_ALIGNMENT_CENTER)
			elif c is RichTextLabel:
				_grow(mm, pos, c.size)
			elif c is TextureRect or c is TextureButton:
				_grow(mm, pos, c.size)
			_gather(c, surface, top, mm)
		else:
			_gather(child, surface, top, mm)


func _grow_text(mm: Dictionary, c: Control, pos: Vector2, text: String, h: int, v: int) -> void:
	if text.is_empty():
		return
	var font := c.get_theme_font(&"font")
	if font == null:
		return
	var size := c.get_theme_font_size(&"font_size")
	if size <= 0:
		size = 16
	var extent := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var hx := 0.0
	if h == HORIZONTAL_ALIGNMENT_CENTER:
		hx = 0.5
	elif h == HORIZONTAL_ALIGNMENT_RIGHT:
		hx = 1.0
	var vy := 0.0
	if v == VERTICAL_ALIGNMENT_CENTER:
		vy = 0.5
	elif v == VERTICAL_ALIGNMENT_BOTTOM:
		vy = 1.0
	var origin := pos + Vector2((c.size.x - extent.x) * hx, (c.size.y - extent.y) * vy)
	_grow(mm, origin, extent)


func _grow(mm: Dictionary, pos: Vector2, size: Vector2) -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	if not bool(mm.has):
		mm.has = true
		mm.x0 = pos.x
		mm.y0 = pos.y
		mm.x1 = pos.x + size.x
		mm.y1 = pos.y + size.y
		return
	mm.x0 = minf(mm.x0, pos.x)
	mm.y0 = minf(mm.y0, pos.y)
	mm.x1 = maxf(mm.x1, pos.x + size.x)
	mm.y1 = maxf(mm.y1, pos.y + size.y)


func _is_chrome_node(c: Control) -> bool:
	if c.has_meta(&"chrome_bg") or c.name == StringName("ChromeCanvas") \
			or c.name == StringName("PaneBackdrop") or c.name == StringName("Grain") \
			or c.name == StringName("Fade"):
		return true
	if c is ColorRect:
		return true
	var tex := _node_texture(c)
	if tex != null and String(tex.resource_path).begins_with(UI_DIR):
		return true
	return false


## ------------------------------------------------------------------ cut facts


func _print_cuts() -> void:
	var names: Array[String] = ["C1", "C2", "C3", "C4", "C5", "C7", "C9", "C12"]
	for cls in names:
		var tex := ChromeFamily.cut_texture(cls)
		if tex == null:
			continue
		var cut := tex.get_size()
		var box := _scan_alpha(tex, 0.5)
		var soft := _scan_alpha(tex, 0.05)
		_opaque[cls] = {"solid": box, "soft": soft}
		print("[r37] CUT cls=%s cut=%.0fx%.0f aspect=%.3f opaque=%.0fx%.0f soft=%.0fx%.0f" % [
			cls, cut.x, cut.y, cut.x / maxf(cut.y, 0.001), box.x, box.y, soft.x, soft.y])
	var slot_tex := load("res://assets/ui/ui_slot_weapon_normal.png") as Texture2D
	if slot_tex != null:
		var box := _scan_alpha(slot_tex, 0.5)
		_opaque["slot"] = {"solid": box, "soft": box}
		print("[r37] CUT cls=slot cut=%.0fx%.0f aspect=%.3f opaque=%.0fx%.0f" % [
			slot_tex.get_size().x, slot_tex.get_size().y,
			slot_tex.get_size().x / slot_tex.get_size().y, box.x, box.y])


func _opaque_box(cls: String) -> Vector2:
	var rec: Dictionary = _opaque.get(cls, {"solid": Vector2.ZERO})
	return rec.solid


func _scan_alpha(tex: Texture2D, threshold: float) -> Vector2:
	var img := tex.get_image()
	if img == null:
		return Vector2.ZERO
	if img.is_compressed():
		img.decompress()
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var data := img.get_data()
	var x0 := w
	var y0 := h
	var x1 := -1
	var y1 := -1
	var limit := int(threshold * 255.0)
	for y in range(h):
		var row := y * w * 4
		for x in range(w):
			if data[row + x * 4 + 3] >= limit:
				if x < x0:
					x0 = x
				if x > x1:
					x1 = x
				if y < y0:
					y0 = y
				if y > y1:
					y1 = y
	if x1 < 0:
		return Vector2.ZERO
	return Vector2(x1 - x0 + 1, y1 - y0 + 1)


func _report_console(pane: Node) -> void:
	var chrome := pane.get(&"_chrome") as Node
	if chrome == null:
		print("[r37] CONSOLE FAIL no chrome node")
		return
	var wells: Array[Rect2] = chrome.get(&"wells")
	var bays: Array[Rect2] = chrome.get(&"bays")
	var cells: Array[Rect2] = chrome.get(&"cells")
	var ledges: Array[Rect2] = chrome.get(&"ledges")
	var plate: Texture2D = chrome.get(&"slot_plate")
	var plate_size := plate.get_size() if plate != null else Vector2.ZERO
	print("[r37] CONSOLE wells=%s bays=%s cells=%s ledges=%s slot_plate=%.0fx%.0f node=%s" % [
		_rects(wells), _rects(bays), _rects(cells), _rects(ledges),
		plate_size.x, plate_size.y, _path_of(chrome)])


func _rects(list: Array[Rect2]) -> String:
	var parts: Array[String] = []
	for rect in list:
		parts.append("%.0fx%.0f@%.0f,%.0f" % [rect.size.x, rect.size.y, rect.position.x,
			rect.position.y])
	return ";".join(parts)
