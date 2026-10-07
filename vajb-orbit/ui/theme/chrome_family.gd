extends RefCounted
## S36 chrome re-skin — the one true-aspect chrome family (UI_SPEC section 15).
##
## Every factory here is static; callers reach the script by path
## (`const ChromeFamily := preload("res://ui/theme/chrome_family.gd")`) so the family
## still resolves in a headless gate whose global class table predates this file.
##
## The law this file wires (UI_SPEC section 15.2 A1-A7, section 15.3 margins):
##   * A1 — every cut is drawn at its class's true aspect (the cut is cut pad-to-master,
##     so the cut's own aspect IS the class master's aspect).
##   * A2/A3 — nine-slice stretch only in the flat bands; caps, corners and rivets never
##     stretch (margins hold the ornament).
##   * A6 — whole-face plates contain, never stretch.
##   * A7 — states derive by modulate and stylebox tint only (never size, position or an
##     in-flow `visible`).
##
## Nine-slice margins are the N51 measured values (cut px), the max of the two independent
## methods in `D21-G2-R1_review.md` (that review's own "safe wiring value"). The measured
## table is the law AT CUT SCALE; every wired plate scales it to its DRAWN rect
## (`drawn_margins`, section 15.3's proportional rule - its C12 note "32 at the 96 cut (64
## at the 192 master)" is the worked case), with the degenerate guard that a margin pair may
## never meet the rect (the engine's `map_ninepatch_axis` has no centre branch below the
## margins sum: a hard UV seam and a truncated cap). Reversal: wire section 15.3's declared
## values unscaled.

const CUT_DIR := "res://assets/ui/"

## Class master true aspects (UI_SPEC section 15.1 / 15.3). The cut for each class is the
## master at 2x, so its aspect equals the master's.
const MASTER := {
	"C1": Vector2(567.0, 140.0),
	"C2": Vector2(360.0, 56.0),
	"C3": Vector2(96.0, 32.0),
	"C4": Vector2(560.0, 76.0),
	"C5": Vector2(260.0, 192.0),
	"C6": Vector2(1360.0, 516.0),
	"C7": Vector2(360.0, 240.0),
	"C9": Vector2(272.0, 56.0),
	"C12": Vector2(96.0, 96.0),
	"C13": Vector2(1765.0, 753.0),
}

## Class cut files, all under `vajb-orbit/assets/ui/`.
const CUT := {
	"C1": "ui_tile_slab.png",
	"C2": "ui_action_bar.png",
	"C3": "ui_inline_chip.png",
	"C4": "ui_row_strip.png",
	"C5": "ui_rack_bay_card.png",
	"C6": "ui_armory_console.png",
	"C7": "ui_tooltip_frame.png",
	"C9": "ui_drawer_entry.png",
	"C12": "ui_panel_frame.png",
}

## The nine-slice classes and their N51 measured margins (cut px), left/right/top/bottom
## (the order R1's `probe_s36_r1_measure.py` publishes as "lrtb"). S36-F1 corrected B1's
## assignment, which read this vector as (l, t, r, b) and so swapped top and right.
const MARGINS := {
	"C3": Vector4(24.0, 34.0, 23.0, 39.0),
	"C4": Vector4(74.0, 74.0, 35.0, 49.0),
	"C7": Vector4(22.0, 43.0, 50.0, 64.0),
}

## The classes drawn as a uniform canvas at their slot rect (the rail cuts and the square
## card): whole texture, aspect-preserving, the transparent pad is the look (UI_SPEC 15.6).
const CANVAS_CLASSES: Array[String] = ["C1", "C2", "C5", "C9"]

## Legal stretch bands (UI_SPEC 15.3), in use px. A slot outside its band is a reported
## finding (A4), never a smear.
const BANDS := {
	"C1": Rect2(510.0, 126.0, 114.0, 28.0),
	"C2": Rect2(272.0, 56.0, 178.0, 32.0),
	"C3": Rect2(80.0, 0.0, 80.0, 4096.0),
	"C4": Rect2(320.0, 64.0, 1445.0, 20.0),
	"C7": Rect2(280.0, 120.0, 80.0, 280.0),
	"C9": Rect2(272.0, 56.0, 88.0, 0.0),
}

const BG_CUTS := {
	"BG-1": "ui_backdrop_armory_deck.png",
	"BG-2": "ui_backdrop_refinery_deck.png",
	"BG-3": "ui_backdrop_market_deck.png",
	"BG-4": "ui_backdrop_dock_deck.png",
}
## The pane-content box the backdrops cover-fit (UI_SPEC 15.1 C13, 1765:753).
const BG_BOX := Vector2(1765.0, 753.0)

## The keep-list surfaces (UI_SPEC 15.6 keep-restore) — never touched by this family.
const KEEP_CUTS := [
	"ui_slot_weapon_normal.png", "ui_slot_cargo_normal.png", "ui_slot_inventory_normal.png",
	"ui_bar_caps.png", "ui_minimap_bezel.png", "ui_backdrop_hangar.png",
]


static func cut_path(cls: String) -> String:
	return CUT_DIR + String(CUT.get(cls, ""))


static func cut_texture(cls: String) -> Texture2D:
	var path := cut_path(cls)
	if path.ends_with(".png") and ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


static func master_aspect(cls: String) -> float:
	var m: Vector2 = MASTER.get(cls, Vector2.ONE)
	return m.x / maxf(m.y, 0.001)


static func cut_aspect(cls: String) -> float:
	var tex := cut_texture(cls)
	if tex == null:
		return 0.0
	var size := tex.get_size()
	return size.x / maxf(size.y, 0.001)


## A class cut's own pixel size (the engine compares the nine-slice margins against the
## drawn rect in texture px 1:1, so `measured / cut` is the proportional scale).
static func cut_size(cls: String) -> Vector2:
	var tex := cut_texture(cls)
	return tex.get_size() if tex != null else Vector2.ZERO


## The measured margins scaled from cut px to a DRAWN rect, per axis, with the degenerate
## guard (A2/A3, section 15.3). `size` <= 0 yields the measured values unscaled (cut scale,
## the census's reference). The MARGINS vector is (left, right, top, bottom); returns
## l/t/r/b in drawn px.
static func drawn_margins(cls: String, size: Vector2) -> Vector4:
	var m: Vector4 = MARGINS.get(cls, Vector4.ZERO)
	var cut := cut_size(cls)
	if cut.x <= 0.0 or cut.y <= 0.0 or size.x <= 0.0 or size.y <= 0.0:
		return Vector4(m.x, m.z, m.y, m.w)
	var l := roundf(m.x * size.x / cut.x)
	var r := roundf(m.y * size.x / cut.x)
	var t := roundf(m.z * size.y / cut.y)
	var b := roundf(m.w * size.y / cut.y)
	## The guard: a margin pair may never meet or exceed the rect (map_ninepatch_axis has no
	## centre branch below the margins sum). Clamping halves both sides of the axis.
	var half_h := floorf(size.x * 0.5)
	var half_v := floorf(size.y * 0.5)
	return Vector4(minf(l, half_h), minf(t, half_v), minf(r, half_h), minf(b, half_v))


## The nine-slice stylebox for a class (A2/A3). `size` is the surface's drawn rect: the
## measured margins scale to it and the guard clamps them. Omit `size` for the measured
## (cut-scale) reference. Returns null for a canvas class (C1/C2/C5/C9 draw uniformly).
static func stylebox(cls: String, size: Vector2 = Vector2.ZERO) -> StyleBoxTexture:
	if CANVAS_CLASSES.has(cls):
		return null
	var tex := cut_texture(cls)
	if tex == null:
		return null
	var box := StyleBoxTexture.new()
	box.texture = tex
	var m: Vector4 = drawn_margins(cls, size)
	box.texture_margin_left = m.x
	box.texture_margin_top = m.y
	box.texture_margin_right = m.z
	box.texture_margin_bottom = m.w
	## The ornament band is texture margin; the CONTENT margin is zeroed so the plate never
	## grows its surface's minimum size (the pane's own MarginContainers place content) -
	## except C7, whose panel is a bare PanelContainer and whose text inset WAS the panel
	## stylebox's content margin (F4, S36-F1). The C7 inset is its top/bottom bevel only, so
	## N47's 360 width cap and the panel footprint stand; reversal: 0 (text under the bevel).
	if cls == "C7":
		var cm: Vector4 = MARGINS.get("C7", Vector4.ZERO)
		box.content_margin_left = 0.0
		box.content_margin_top = cm.z
		box.content_margin_right = 0.0
		box.content_margin_bottom = cm.w
	else:
		box.content_margin_left = 0.0
		box.content_margin_top = 0.0
		box.content_margin_right = 0.0
		box.content_margin_bottom = 0.0
	return box


## A tinted duplicate of a stylebox (A7: states are tint, never size/position). A null
## source yields a flat tint of the same colour so a canvas class still gets a state.
static func tinted(source: StyleBox, colour: Color) -> StyleBox:
	if source is StyleBoxTexture:
		var dup := (source as StyleBoxTexture).duplicate() as StyleBoxTexture
		dup.modulate_color = colour
		return dup
	var flat := StyleBoxFlat.new()
	flat.bg_color = colour
	return flat


## A whole-face contain plate (A6): a full-rect, aspect-preserving TextureRect that draws
## behind its parent's own draw, so a whole-face plate never stretches or slices.
static func make_contain(cls: String, node_name: String = "ChromeCanvas") -> TextureRect:
	var canvas := make_canvas(cls, node_name)
	if canvas != null:
		canvas.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return canvas


## A uniform canvas TextureRect for a canvas class (C1/C2/C5/C9): fills its rect, keeps its
## own aspect (letterboxed), draws behind the parent's own draw, never eats the pointer.
static func make_canvas(cls: String, node_name: String = "ChromeCanvas") -> TextureRect:
	var tex := cut_texture(cls)
	if tex == null:
		return null
	var canvas := TextureRect.new()
	canvas.name = node_name
	canvas.texture = tex
	canvas.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	canvas.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.show_behind_parent = true
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.set_meta(&"chrome_class", cls)
	return canvas


## The aspect-fit rect a KEEP_ASPECT_CENTERED canvas draws inside `slot`.
static func canvas_rect(slot: Vector2, cls: String) -> Rect2:
	var aspect := cut_aspect(cls)
	if aspect <= 0.0:
		return Rect2(Vector2.ZERO, slot)
	var size := slot
	if slot.x / maxf(slot.y, 0.001) > aspect:
		size = Vector2(slot.y * aspect, slot.y)
	else:
		size = Vector2(slot.x, slot.x / aspect)
	return Rect2((slot - size) * 0.5, size)


## A backdrop TextureRect layer (C13): cover-fit, IGNORE, behind the pane's content.
static func make_backdrop(bg_id: String, node_name: String = "PaneBackdrop") -> TextureRect:
	var path := CUT_DIR + String(BG_CUTS.get(bg_id, ""))
	if not ResourceLoader.exists(path):
		return null
	var layer := TextureRect.new()
	layer.name = node_name
	layer.texture = load(path) as Texture2D
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.set_meta(&"chrome_bg", bg_id)
	return layer


# ------------------------------------------------------------------- the surface appliers


## C4 row strip: a nine-slice at the measured margins scaled to the row's drawn rect, states
## by tint (A7).
static func apply_row(button: Button) -> void:
	_wire_nineslice(button, "C4", true)


## C4 row strip on a panel-style surface (a `PanelContainer`'s `panel` stylebox).
static func apply_row_panel(panel: Control) -> void:
	_wire_nineslice(panel, "C4", false)


## C3 inline chip: the measured nine-slice scaled to the chip's drawn rect, states by tint.
static func apply_chip(button: Button) -> void:
	_wire_nineslice(button, "C3", true)


## Wire a nine-slice plate to a control and keep its margins scaled to the control's DRAWN
## rect: the box is rebuilt on every resize, because the surface's size is not known before
## layout (F1, S36-F1). Idempotent - one resize handler per control.
static func _wire_nineslice(control: Control, cls: String, states: bool) -> void:
	control.set_meta(&"chrome_class", cls)
	control.set_meta(&"chrome_states", states)
	## Connect BEFORE the first refresh: the first `add_theme_stylebox_override` can trigger
	## a synchronous re-layout (a resized), and a handler connected after it would miss it.
	if not control.has_meta(&"chrome_resized"):
		control.set_meta(&"chrome_resized", true)
		control.resized.connect(func() -> void: _refresh_nineslice(control))
	_refresh_nineslice(control)


## Rebuild a wired plate's stylebox at the control's current drawn rect (margins scale, the
## guard clamps; A7 states are tints of the same box).
static func _refresh_nineslice(control: Control) -> void:
	var cls := String(control.get_meta(&"chrome_class", ""))
	if cls.is_empty():
		return
	var box := stylebox(cls, control.size)
	if box == null:
		return
	if bool(control.get_meta(&"chrome_states", false)) and control is Button:
		var button := control as Button
		var hover := Color(1.12, 1.12, 1.12, 1.0)
		var pressed := Color(0.82, 0.82, 0.82, 1.0)
		var disabled := Color(0.62, 0.62, 0.62, 0.85)
		if cls == "C3":
			hover = Color(1.15, 1.15, 1.15, 1.0)
			pressed = Color(0.80, 0.80, 0.80, 1.0)
			disabled = Color(0.60, 0.60, 0.60, 0.80)
		button.add_theme_stylebox_override(&"normal", box)
		button.add_theme_stylebox_override(&"hover", tinted(box, hover))
		button.add_theme_stylebox_override(&"pressed", tinted(box, pressed))
		button.add_theme_stylebox_override(&"disabled", tinted(box, disabled))
	else:
		control.add_theme_stylebox_override(&"panel", box)


## C1 tile slab: the rail cut as a uniform canvas at the tile rect (the pad is the look).
static func apply_tile(button: Button) -> void:
	apply_canvas(button, "C1")


## C2 action bar: the rail cut as a uniform canvas at the bar rect.
static func apply_action(button: Button) -> void:
	apply_canvas(button, "C2")


## C9 drawer entry: the rail cut as a uniform canvas at the entry rect.
static func apply_entry(button: Button) -> void:
	apply_canvas(button, "C9")


## C5 rack bay card: the square cut as a uniform canvas at the bay rect.
static func apply_card(control: Control) -> void:
	apply_canvas(control, "C5")


## Shared canvas-class wiring: add the uniform canvas behind the control's own draw and
## swap the state styleboxes to tints (A7). Idempotent (a second call reuses the canvas).
static func apply_canvas(control: Control, cls: String) -> void:
	var canvas := control.get_node_or_null(NodePath("ChromeCanvas")) as TextureRect
	if canvas == null:
		canvas = make_canvas(cls)
		if canvas == null:
			return
		## Appended (never inserted at 0) and `show_behind_parent`, so the canvas draws behind
		## the control's own draw and never shadows a content node in a tree walk.
		control.add_child(canvas)
	control.set_meta(&"chrome_class", cls)
	if control is Button:
		var button := control as Button
		button.add_theme_stylebox_override(&"normal", StyleBoxEmpty.new())
		var hover := StyleBoxFlat.new()
		hover.bg_color = Color(1.0, 1.0, 1.0, 0.06)
		button.add_theme_stylebox_override(&"hover", hover)
		var pressed := StyleBoxFlat.new()
		pressed.bg_color = Color(0.0, 0.0, 0.0, 0.12)
		button.add_theme_stylebox_override(&"pressed", pressed)
		var disabled := StyleBoxFlat.new()
		disabled.bg_color = Color(0.0, 0.0, 0.0, 0.35)
		button.add_theme_stylebox_override(&"disabled", disabled)


## C7 tooltip frame: the measured nine-slice scaled to the panel's drawn rect, with the
## tooltip's text inset restored as the box's content margin (F4, S36-F1).
static func apply_tooltip(panel: PanelContainer) -> void:
	_wire_nineslice(panel, "C7", false)


## C6 whole-face plate: contain, never stretch (A6).
static func apply_contain(control: Control, cls: String = "C6") -> void:
	var canvas := make_contain(cls)
	if canvas == null:
		return
	control.add_child(canvas)
	control.move_child(canvas, 0)
	control.set_meta(&"chrome_class", cls)


## A backdrop layer added behind a pane's content (C13). Returns the node (or null).
static func apply_backdrop(pane: Control, bg_id: String) -> TextureRect:
	var layer := make_backdrop(bg_id)
	if layer == null:
		return null
	pane.add_child(layer)
	pane.move_child(layer, 0)
	return layer
