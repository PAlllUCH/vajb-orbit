extends Control
## UI_SPEC section 18 A7-A9: the C-key cargo overlay, one read-only surface for both
## planes. The seat differs per plane (the station's own CanvasLayer under the shell,
## flight's layer-20 host in game.gd); the surface, the rows and the close law are this
## scene's.
##
## The surface is the N28 sheet idiom (section 12.3): a full-rect MOUSE_FILTER_STOP root,
## a void_base 60 % dimmer, a centred panel_raised PanelContainer, a 16 px margin and a
## 12 px VBox, size-to-content inside the 420/720 width band and N32's 80 %-viewport
## scroll rule. Open/close is N29's envelope: `modulate:a` 0 -> 1 / 1 -> 0 in 0.18 s
## TRANS_CUBIC EASE_OUT (an overlay, so A5.5 never touches the layout).
##
## The contents are A9's five groups, every figure read off the profile's own seams
## (`cargo_items` / `cargo_qty` / `ammo_of`) with no price, no quote and no recomputation,
## and no transactional control anywhere (the panes are the act, the overlay is the look).
##
## Close paths (each one operation, P19): the owner plane's ESC step, the scrim (N38), C
## again - the shell drives all three through close(); focus returns to the trigger (N39).

signal closed

const MineralCatalogScript := preload("res://game/mineral_catalog.gd")
const ComponentCatalogScript := preload("res://game/component_catalog.gd")
const ModuleCatalogScript := preload("res://game/module_catalog.gd")
const WeaponScript := preload("res://game/weapons.gd")
const Catalog := preload("res://game/station_catalog.gd")

const TOKENS_TYPE: StringName = &"Tokens"
const PROFILE_SERVICE: StringName = &"PlayerProfile"

const MIN_WIDTH := 420.0
const MAX_WIDTH := 720.0
const PANEL_MARGIN := 16.0
const MAX_HEIGHT_RATIO := 0.8
const DIMMER_ALPHA := 0.6
const MOTION_SECONDS := 0.18
const GLYPH_SIZE := 24.0
const ROW_SEPARATION := 8

## A8/A9's pinned copy.
const TITLE_FORMAT := "CARGO — %d/%d UNITS"
const AMMO_FORMAT := "%s · %d ROUNDS"
const STACK_FORMAT := "%s · %d"
const EMPTY_ROW := "NONE HELD"
const CLOSE_HINT := "ESC · CLOSE"

const BAND_AMMUNITION := "AMMUNITION"
const BAND_ORE := "ORE"
const BAND_INGOTS := "INGOTS"
const BAND_COMPONENTS := "COMPONENTS"
const BAND_FUEL_CELLS := "FUEL CELLS"
## 03 section 3's power family, drawn as its own group so nothing double-counts.
const POW_FAMILY: StringName = &"pow"

@onready var _dimmer: ColorRect = %CargoDimmer
@onready var _panel: PanelContainer = %CargoPanel
@onready var _scroll: ScrollContainer = %CargoScroll
@onready var _content: VBoxContainer = %CargoContent
@onready var _title: Label = %CargoTitle
@onready var _groups: VBoxContainer = %CargoGroups
@onready var _hint: Label = %CargoHint

var _tween: Tween = null
var _open := false
var _trigger: Control = null
var _text_labels: Array[Label] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	modulate.a = 0.0
	_apply_tokens()
	_dimmer.gui_input.connect(_on_dimmer_input)
	_connect_profile()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_apply_tokens()


func _exit_tree() -> void:
	var profile := _profile()
	if profile != null and profile.is_connected(&"profile_changed", _on_profile_changed):
		profile.disconnect(&"profile_changed", _on_profile_changed)


## Open the read (one at a time, section 5.2's queue): a second `open()` while one is up
## is a no-op - the shell's C step closes through close() instead.
func open() -> void:
	if _open:
		return
	var viewport := get_viewport()
	if viewport != null:
		_trigger = viewport.gui_get_focus_owner()
	_open = true
	visible = true
	modulate.a = 0.0
	_refresh()
	_fit()
	_animate(1.0)


## Close is one operation (P19): `_open` flips immediately, the fade is cosmetic.
func close() -> void:
	if not _open:
		return
	_open = false
	_animate(0.0, true)


func is_open() -> bool:
	return _open


## A8's title line, for probes.
func title_text() -> String:
	return _title.text


## The probe surface: every visible band / row / empty text in draw order, title and
## hint excluded (the tests assert those separately).
func row_texts() -> PackedStringArray:
	var out := PackedStringArray()
	for child: Node in _groups.get_children():
		var label := child as Label
		if label != null:
			if label.visible:
				out.append(label.text)
			continue
		var text := child.get_node_or_null(NodePath("Text")) as Label
		if text != null and text.visible:
			out.append(text.text)
	return out


func _connect_profile() -> void:
	var profile := _profile()
	if profile == null or not profile.has_signal(&"profile_changed"):
		return
	if not profile.is_connected(&"profile_changed", _on_profile_changed):
		profile.connect(&"profile_changed", _on_profile_changed)


## The overlay rides a live plane (a pickup can land while it is up), so an open read
## tracks the hold and the packs; a closed one stays silent.
func _on_profile_changed(key: StringName) -> void:
	if not _open or (key != &"cargo" and key != &"ammo"):
		return
	_refresh()
	_fit()


func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		close()


## A9's five groups, in the pin's order, every figure read off the profile's seams.
func _refresh() -> void:
	_clear_rows()
	var items := _cargo_items()
	_title.text = TITLE_FORMAT % [_held_units(items), _cargo_capacity()]
	_build_group(BAND_AMMUNITION, _ammunition_rows(), &"")
	_build_group(BAND_ORE, _mineral_rows(items, true), &"ore")
	_build_group(BAND_INGOTS, _mineral_rows(items, false), &"ingot")
	_build_group(BAND_COMPONENTS, _component_rows(items, false), &"comp")
	_build_group(BAND_FUEL_CELLS, _component_rows(items, true), &"pow")


func _build_group(band: String, rows: Array[Dictionary], stem: StringName) -> void:
	var band_name := "Band" + band.replace(" ", "")
	var caption := _make_label(&"StationCaption", band)
	caption.name = band_name
	_groups.add_child(caption)
	if rows.is_empty():
		var empty := _make_label(&"StationCaption", EMPTY_ROW)
		empty.name = "Empty" + band.replace(" ", "")
		_groups.add_child(empty)
		return
	for row: Dictionary in rows:
		var row_id := StringName(row.get(&"id", &""))
		var node_name := "Row%s" % String(row_id).to_pascal_case() if row_id != &"" \
				else "Row%s" % String(stem).to_pascal_case()
		_groups.add_child(_make_row(row, node_name))


## One A9 row: the family glyph 24 at its own rect (A5.2(iii)) beside the 13 px read.
func _make_row(row: Dictionary, node_name: String) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.name = node_name
	box.add_theme_constant_override(&"separation", int(ROW_SEPARATION))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	icon.name = "Glyph"
	icon.custom_minimum_size = Vector2(GLYPH_SIZE, GLYPH_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_path := String(row.get(&"icon", ""))
	if icon_path != "" and ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	icon.modulate = row.get(&"tint", Color.WHITE)
	box.add_child(icon)
	var label := _make_label(&"StationCaption", String(row.get(&"text", "")))
	label.name = "Text"
	label.add_theme_color_override(&"font_color", _token(&"text_primary"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(label)
	_text_labels.append(label)
	return box


func _make_label(variation: StringName, text: String) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _clear_rows() -> void:
	## Freed, not queued: the fit measures the content's minimum the same frame the rows
	## rebuild, and a queued child still counts into it.
	for child: Node in _groups.get_children():
		_groups.remove_child(child)
		child.free()
	_text_labels.clear()


## --- the read-only seams -------------------------------------------------------------


func _profile() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null(NodePath(PROFILE_SERVICE))


func _cargo_items() -> Dictionary:
	var profile := _profile()
	if profile == null or not profile.has_method(&"cargo_items"):
		return {}
	var raw: Variant = profile.call(&"cargo_items")
	return raw if raw is Dictionary else {}


## A8's `<n>`: the hold's own units summed (the armory/launch `_cargo_used` exemplar).
func _held_units(items: Dictionary) -> int:
	var used := 0
	for quantity: Variant in items.values():
		used += int(quantity)
	return used


## A8's `<cap>`: the active hull's cargo column (08 section 3), the OVERVIEW's own
## `Catalog.ship` read.
func _cargo_capacity() -> int:
	var profile := _profile()
	if profile == null or not profile.has_method(&"active_ship"):
		return 0
	var ship: Dictionary = Catalog.ship(StringName(profile.call(&"active_ship")))
	return int(ship.get(&"cargo", 0))


func _held(items: Dictionary, item_id: StringName) -> int:
	return int(items.get(item_id, 0))


## A9's AMMUNITION rows: one per fitted weapon family in cell order (duplicates share
## one pack), `<weapon name> · <rounds> ROUNDS`, the rounds read off `ammo_of` - the
## battery's own pack, never the hold's ammo units.
func _ammunition_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var profile := _profile()
	if profile == null or not profile.has_method(&"resolved_fit") \
			or not profile.has_method(&"active_ship") or not profile.has_method(&"base_module_id"):
		return rows
	var fit: Variant = profile.call(&"resolved_fit", StringName(profile.call(&"active_ship")))
	if not fit is Dictionary:
		return rows
	var fitted: Variant = (fit as Dictionary).get(&"weapons", [])
	if not fitted is Array:
		return rows
	var seen: Dictionary = {}
	for entry: Variant in fitted as Array:
		var cell := StringName(str(entry))
		if cell == &"":
			continue
		var base := StringName(str(profile.call(&"base_module_id", cell)))
		var family := WeaponScript.weapon_id(base)
		if family == &"" or seen.has(family):
			continue
		seen[family] = true
		var module := ModuleCatalogScript.module(base)
		if module.is_empty():
			continue
		var rounds := 0
		if profile.has_method(&"ammo_of"):
			rounds = int(profile.call(&"ammo_of", family))
		rows.append({
			&"id": family,
			&"text": AMMO_FORMAT % [
				String(module.get(&"name", String(base))).to_upper(), rounds
			],
			&"icon": String(module.get(&"icon", "")),
			&"tint": Color.WHITE,
		})
	return rows


## A9's ORE / INGOTS rows: one per held stack in catalogue order (05 section 8's hold
## ordering), the mineral entry's own icon field, the tier tint (02 section 6).
func _mineral_rows(items: Dictionary, ore: bool) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for mineral_id: StringName in MineralCatalogScript.mineral_ids():
		var item_id := MineralCatalogScript.ore_id(mineral_id) if ore \
				else MineralCatalogScript.ingot_id(mineral_id)
		var qty := _held(items, item_id)
		if qty <= 0:
			continue
		var entry: Dictionary = MineralCatalogScript.mineral(mineral_id)
		var name_text := String(entry.get(&"name", String(mineral_id))).to_upper()
		rows.append({
			&"id": item_id,
			&"text": STACK_FORMAT % [("%s ORE" if ore else "%s INGOT") % name_text, qty],
			&"icon": String(entry.get(&"icon_ore" if ore else &"icon_ingot", "")),
			&"tint": _tier_tint(int(entry.get(&"tier", 0))),
		})
	return rows


## A9's COMPONENTS / FUEL CELLS rows: the component catalogue's own rows in catalogue
## order, the `pow` family drawn as its own group so nothing double-counts, the grade
## tint (03 section 4.1). An id no catalogue answers is not drawn (section 5.8's rule).
func _component_rows(items: Dictionary, fuel: bool) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for entry: Dictionary in ComponentCatalogScript.COMPONENTS:
		var component_id := StringName(entry.get(&"id", &""))
		if component_id == &"":
			continue
		var family := StringName(entry.get(&"family", &""))
		if (family == POW_FAMILY) != fuel:
			continue
		var qty := _held(items, component_id)
		if qty <= 0:
			continue
		rows.append({
			&"id": component_id,
			&"text": STACK_FORMAT % [
				String(entry.get(&"name", String(component_id))).to_upper(), qty
			],
			&"icon": String(entry.get(&"icon", "")),
			&"tint": _grade_tint(int(entry.get(&"grade", 0))),
		})
	return rows


func _tier_tint(tier: int) -> Color:
	if MineralCatalogScript.TIER_TINTS.has(tier):
		return MineralCatalogScript.TIER_TINTS[tier]
	return Color.WHITE


func _grade_tint(grade: int) -> Color:
	if ComponentCatalogScript.GRADE_TINTS.has(grade):
		return ComponentCatalogScript.GRADE_TINTS[grade]
	return Color.WHITE


## --- the N28 surface laws ------------------------------------------------------------


## Size-to-content inside N28's band: measure the title and every row's natural width,
## floor at 420, cap at 720 (the rows then wrap at that edge), then cap the height at
## N32's 80 % viewport. The content node is re-sized, never the anchor-laid-out root
## (the sheet's own S30-F1 note: a root reset collapses the full-rect overlay).
func _fit() -> void:
	_panel.custom_minimum_size.x = MIN_WIDTH
	_scroll.custom_minimum_size.y = 0.0
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content.reset_size()
	var widest := _text_width(_title)
	for label: Label in _text_labels:
		widest = maxf(widest, _row_width(label))
	var target := clampf(widest + PANEL_MARGIN * 2.0, MIN_WIDTH, MAX_WIDTH)
	_panel.custom_minimum_size.x = target
	var text_width := target - PANEL_MARGIN * 2.0 - GLYPH_SIZE - ROW_SEPARATION
	_title.custom_minimum_size.x = target - PANEL_MARGIN * 2.0
	for label: Label in _text_labels:
		label.custom_minimum_size.x = text_width
	_content.reset_size()
	var cap := _viewport_size().y * MAX_HEIGHT_RATIO - PANEL_MARGIN * 2.0
	var content_h := _content.get_combined_minimum_size().y
	_scroll.custom_minimum_size.y = maxf(0.0, minf(content_h, cap))
	_scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_AUTO
		if content_h > cap
		else ScrollContainer.SCROLL_MODE_DISABLED
	)


func _row_width(label: Label) -> float:
	return GLYPH_SIZE + ROW_SEPARATION + _text_width(label)


func _text_width(label: Label) -> float:
	var font := label.get_theme_font(&"font")
	if font == null:
		return 0.0
	var size := label.get_theme_font_size(&"font_size")
	var widest := 0.0
	for line: String in label.text.split("\n"):
		widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x)
	return widest


func _animate(target: float, then_hide: bool = false) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", target, MOTION_SECONDS)
	if then_hide:
		_tween.tween_callback(_on_closed)


func _on_closed() -> void:
	visible = false
	_return_focus()
	closed.emit()


## N39: the focus that opened the overlay gets it back when it closes.
func _return_focus() -> void:
	if _trigger == null or not is_instance_valid(_trigger):
		_trigger = null
		return
	if _trigger.is_inside_tree() and _trigger.focus_mode != Control.FOCUS_NONE:
		_trigger.grab_focus()
	_trigger = null


func _apply_tokens() -> void:
	var dim: Color = _token(&"void_base")
	dim.a = DIMMER_ALPHA
	_dimmer.color = dim
	_title.add_theme_color_override(&"font_color", _token(&"text_primary"))
	_hint.add_theme_color_override(&"font_color", _token(&"text_dim"))


func _viewport_size() -> Vector2:
	var viewport := get_viewport()
	if viewport == null:
		return Vector2(1920.0, 1080.0)
	return viewport.get_visible_rect().size


func _token(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.WHITE
