extends Control
## UI_SPEC section 18 A7-A13: the C-key cargo overlay, one surface for both
## planes. The seat differs per plane (the station's own CanvasLayer under the
## shell, flight's layer-20 host in game.gd); the surface, the slot rows and the
## close law are this scene's.
##
## The 18.2 rework (owner 2026-10-14, "look like refinery, categories like in
## armory, each slot: icon + amount + dispose, sort by categories"): the body is
## the refinery row idiom (A10) - C4 row strips 76 tall, RowInner 12/8, the 40 px
## material icon at its own rect, a StationValue/StationMeta title box, the 130
## AMOUNT cell and one ActionInline DISPOSE chip per row (A12); the armory
## MENU_TABS strip (A11) sorts the one list into the five A9 categories + ALL;
## the title row's SORT chip cycles CATEGORY / NAME / AMOUNT (A13).
##
## The one transaction is A12's DISPOSE: the whole hold stack of the row's id,
## through PlayerProfile.remove_cargo (all-or-nothing, no refund, nothing
## dropped); an ammunition row disposes only the hold's ammo_* units - the
## loaded pack stays. Every read stays A9's seams (cargo_items / cargo_qty /
## ammo_of). Rows are detached and queue_freed on rebuild, so a dispose that
## fires from inside a chip's own press emission is safe (a freed emitter is
## not).
##
## Close paths (each one operation, P19): the owner plane's ESC step, the scrim
## (N38), C again - the shell drives all three through close(); focus returns
## to the trigger (N39). The surface geometry is A15's one-geometry law (§18.3):
## 720 wide, the 80 % viewport cap tall, held for the whole open session; the
## rows scroll under the cap.

signal closed

const Catalog := preload("res://game/station_catalog.gd")
const ChromeFamily := preload("res://ui/theme/chrome_family.gd")
const Summary := preload("res://ui/station/cargo_summary.gd")
## Section 20: the slots law, the icon ink law and the grouped formatter's
## single home is the shared summary builder; this overlay delegates its reads
## and keeps its own chip-bearing rows.

const UiTokensScript := preload("res://ui/components/ui_tokens.gd")
const PROFILE_SERVICE: StringName = &"PlayerProfile"

## A15's floor: the surface may never go under 420 wide (A8's outer band).
const MIN_WIDTH := 420.0
const MAX_WIDTH := 720.0
## A15: the one geometry law - the surface holds ONE geometry while it is open:
## width at the 720 ceiling, height at the 80 % viewport cap. The 420 floor is
## the minimum the surface may never go under, not a target it seeks.
const PANEL_WIDTH := MAX_WIDTH
const PANEL_MARGIN := 16.0
const MAX_HEIGHT_RATIO := 0.8
const DIMMER_ALPHA := 0.6
const MOTION_SECONDS := 0.18

## A10: the refinery row grammar's own numbers (S45's `refinery_panel.gd`).
const ROW_HEIGHT := 76.0
const COL_ICON := 40.0
const COL_AMOUNT := 130.0
const ACTION_INLINE := Vector2(96.0, 32.0)
const ROW_INNER_MARGIN := Vector2i(12, 8)
const COLUMN_SEPARATION := 12
const TITLE_SEPARATION := 2
## A11: the armory strip's own tab minimum (S35's `armory_panel.gd`).
const TAB_MIN_SIZE := Vector2(0.0, 32.0)
## A13: the sort chip's own box; the words ride SORT_LABELS.
const SORT_CHIP := Vector2(150.0, 32.0)
## A16: the title column never collapses. The column is measured off the live
## layout (the fixed geometry makes the last layout the truth for this one);
## before the first measure a static floor stands in. The AMOUNT cell and its
## band caption read right-aligned (P40's value-column law).
const SCROLL_RIDE := 12.0
const TITLE_COL: float = (
	PANEL_WIDTH - PANEL_MARGIN * 2.0 - SCROLL_RIDE - float(ROW_INNER_MARGIN.x) * 2.0
		- COL_ICON - COL_AMOUNT - ACTION_INLINE.x - float(COLUMN_SEPARATION) * 3.0
)
## The column band's lead gap: the row's own 12 px inner margin rides in front of
## the 40 px icon, so the captions seat exactly over the row's columns.
const BAND_LEAD_GAP: float = COL_ICON + float(ROW_INNER_MARGIN.x)

## A8/A10's pinned copy — the single home is the shared builder's
## `TITLE_FORMAT`; this overlay reads it through `Summary`.
const DISPOSE_WORD := "DISPOSE"
const EMPTY_ROW := "NONE HELD"
const CLOSE_HINT := "ESC · CLOSE"
const BAND_ITEM := "ITEM"
const BAND_AMOUNT := "AMOUNT"
const BAND_ACTION := "ACTION"

## A13's cycle.
const SORT_CATEGORY: StringName = &"category"
const SORT_NAME: StringName = &"name"
const SORT_AMOUNT: StringName = &"amount"
const SORT_ORDER: Array[StringName] = [SORT_CATEGORY, SORT_NAME, SORT_AMOUNT]
const SORT_LABELS := {
	SORT_CATEGORY: "CATEGORY",
	SORT_NAME: "NAME",
	SORT_AMOUNT: "AMOUNT",
}
const SORT_CHIP_FORMAT := "SORT: %s"

## A23's window chrome: the title row is the drag handle and the CLOSE chip is
## the mouse's twin of the C step.
const CLOSE_WORD := "CLOSE"

@onready var _dimmer: ColorRect = %CargoDimmer
@onready var _panel: PanelContainer = %CargoPanel
@onready var _scroll: ScrollContainer = %CargoScroll
@onready var _title_row: HBoxContainer = %CargoTitleRow
@onready var _title: Label = %CargoTitle
@onready var _sort_chip: Button = %CargoSort
@onready var _close_chip: Button = %CargoClose
@onready var _tabs: HBoxContainer = %CargoTabs
@onready var _band: HBoxContainer = %CargoBand
@onready var _rows: VBoxContainer = %CargoRows
@onready var _hint: Label = %CargoHint

var _tween: Tween = null
var _open := false
var _trigger: Control = null
var _category: StringName = Summary.TAB_ALL
var _sort: StringName = SORT_CATEGORY
var _slot_payloads: Array[Dictionary] = []
var _band_texts: PackedStringArray = PackedStringArray()
## The dispose transaction's own guard (the refinery's `_transaction` idiom): a
## refresh seen mid-transaction is deferred to one rebuild right after the
## write returns, so the chip's press emission never rides a rebuild.
var _transaction := false
var _rebuild_pending := false
## The panel chrome's own insets (the PanelRaised stylebox's content margins) and
## the measured title column - the static floor until the first live measure.
var _panel_inset := Vector2.ZERO
var _title_col := TITLE_COL
## A23's drag state: the press's panel-to-cursor offset, live only while the
## title row holds the press.
var _dragging := false
var _drag_offset := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	modulate.a = 0.0
	_apply_tokens()
	_measure_panel_inset()
	_hint.text = CLOSE_HINT
	_build_tabs()
	_build_band()
	ChromeFamily.apply_chip(_sort_chip)
	ChromeFamily.apply_chip(_close_chip)
	_close_chip.text = CLOSE_WORD
	_refresh_sort_chip()
	_sort_chip.pressed.connect(_on_sort_pressed)
	_close_chip.pressed.connect(_on_close_pressed)
	_title_row.gui_input.connect(_on_title_row_input)
	_dimmer.gui_input.connect(_on_dimmer_input)
	_connect_profile()


func _measure_panel_inset() -> void:
	var stylebox := _panel.get_theme_stylebox(&"panel")
	if stylebox == null:
		return
	_panel_inset = Vector2(
		stylebox.get_margin(SIDE_LEFT) + stylebox.get_margin(SIDE_RIGHT),
		stylebox.get_margin(SIDE_TOP) + stylebox.get_margin(SIDE_BOTTOM),
	)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_apply_tokens()
		_measure_panel_inset()
	elif what == NOTIFICATION_RESIZED and is_node_ready() and _open:
		## S50-B F02: a viewport resize while the window is up re-fits - the
		## 80 % cap and the clamp ride the new bounds instead of waiting for
		## the next incidental refresh.
		_fit()
		_center_panel()


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
	_center_panel()
	_animate(1.0)
	## The geometry is fixed, so the layout that follows this frame's pass is the
	## truth for every later one - re-measure the title column off it.
	_fit.call_deferred()


## Close is one operation (P19): `_open` flips immediately, the fade is cosmetic.
func close() -> void:
	if not _open:
		return
	_open = false
	_dragging = false
	_animate(0.0, true)


func is_open() -> bool:
	return _open


## A8's title line, for probes.
func title_text() -> String:
	return _title.text


## A11 probes: the strip's ids in draw order, the active one, and the one door
## both the tab press and a probe share.
func category_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for tab: Dictionary in Summary.CARGO_TABS:
		ids.append(StringName(tab[&"id"]))
	return ids


func active_category() -> StringName:
	return _category


func select_category(id: StringName) -> void:
	if not Summary.CATEGORY_LABELS.has(id) or id == _category:
		return
	_category = id
	_apply_tab_states()
	_refresh()
	_fit()


## A13 probes: the active mode and the cycle the chip drives.
func sort_mode() -> StringName:
	return _sort


func cycle_sort() -> void:
	var index := SORT_ORDER.find(_sort)
	_sort = SORT_ORDER[wrapi(index + 1, 0, SORT_ORDER.size())]
	_refresh_sort_chip()
	_refresh()
	_fit()


## The slot rows in draw order, one dictionary per row (id, category, name,
## meta, amount, dispose) - the probe surface for the A10/A12 law.
func slot_rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for payload: Dictionary in _slot_payloads:
		var slot: Dictionary = payload[&"slot"]
		out.append({
			&"id": slot[&"id"],
			&"category": slot[&"category"],
			&"name": slot[&"name"],
			&"meta": slot[&"meta"],
			&"amount": slot[&"amount"],
			&"dispose": slot[&"dispose"],
		})
	return out


## The drawn band captions and empty rows in order (A13's grouped view).
func band_texts() -> PackedStringArray:
	return _band_texts.duplicate()


## The row's A12 chip, for probes (null when the id is not drawn).
func dispose_button(item_id: StringName) -> Button:
	for payload: Dictionary in _slot_payloads:
		if StringName(payload[&"id"]) == item_id:
			return payload[&"chip"]
	return null


func _connect_profile() -> void:
	var profile := _profile()
	if profile == null or not profile.has_signal(&"profile_changed"):
		return
	if not profile.is_connected(&"profile_changed", _on_profile_changed):
		profile.connect(&"profile_changed", _on_profile_changed)


## The overlay rides a live plane (a pickup or a pane's transaction can land
## while it is up), so an open read tracks the hold and the packs; a closed one
## stays silent.
func _on_profile_changed(key: StringName) -> void:
	if not _open or (key != &"cargo" and key != &"ammo"):
		return
	if _transaction:
		_rebuild_pending = true
		return
	_refresh()
	_fit()


func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		close()


func _on_sort_pressed() -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	cycle_sort()


func _on_close_pressed() -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	close()


## A23: the title row drags the window. The press records the panel-to-cursor
## offset; motion rides it through `_clamp_panel`, and the chips keep their
## own presses (a child's STOP consumes the event before the row sees it).
func _on_title_row_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_dragging = (event as InputEventMouseButton).pressed
		if _dragging:
			_drag_offset = _panel.position - (event as InputEventMouseButton).global_position
	elif event is InputEventMouseMotion and _dragging \
			and (event as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT:
		_panel.position = (event as InputEventMouseMotion).global_position + _drag_offset
		_clamp_panel()


func _on_tab_pressed(id: StringName) -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	select_category(id)


## A12: the one transaction. One press, the row's whole hold stack, through the
## model's own writer; the rebuild rides `profile_changed` (deferred through
## `_transaction` so the chip's emission never walks a freed row) and one flush
## lands after the write returns either way.
func _on_dispose_pressed(payload: Dictionary) -> void:
	if _transaction:
		return
	var item_id := StringName(payload[&"id"])
	var quantity := int(payload[&"dispose_qty"])
	if item_id == &"" or quantity <= 0:
		return
	var profile := _profile()
	if profile == null or not profile.has_method(&"remove_cargo"):
		return
	_transaction = true
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	var removed: bool = profile.call(&"remove_cargo", item_id, quantity)
	_transaction = false
	_rebuild_pending = false
	if not removed:
		return
	_refresh()
	_fit()


## The list: A9's five categories (A11's strip) filtered to the active tab,
## ordered by A13's cycle - CATEGORY groups the ALL view under the five bands
## (empty bands skipped), NAME and AMOUNT read it flat.
func _refresh() -> void:
	_clear_rows()
	var profile := _profile()
	var items := _cargo_items()
	_title.text = Summary.TITLE_FORMAT % [_held_units(items), _cargo_capacity()]
	var slots := _slots(profile, items)
	if _category != Summary.TAB_ALL:
		slots = _filter_category(slots, _category)
	_apply_sort(slots)
	if _category == Summary.TAB_ALL and _sort == SORT_CATEGORY:
		for category: StringName in Summary.CATEGORY_ORDER:
			var held := _filter_category(slots, category)
			if held.is_empty():
				continue
			_build_section_header(String(Summary.CATEGORY_LABELS[category]))
			for slot: Dictionary in held:
				_add_row(slot)
	else:
		for slot: Dictionary in slots:
			_add_row(slot)
	if _slot_payloads.is_empty():
		_build_empty_row()


## The strip (the armory `_build_browser` idiom): six toggle tabs, the active
## one `text_primary` + pressed, the rest `text_dim`.
func _build_tabs() -> void:
	for tab: Dictionary in Summary.CARGO_TABS:
		var button := Button.new()
		button.name = "Tab%s" % String(tab[&"id"]).to_pascal_case()
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_ALL
		button.custom_minimum_size = TAB_MIN_SIZE
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = String(tab[&"label"])
		button.set_meta(&"tab", StringName(tab[&"id"]))
		button.add_theme_color_override(
			&"font_color",
			_token(&"text_primary") if tab[&"id"] == _category else _token(&"text_dim")
		)
		button.pressed.connect(_on_tab_pressed.bind(StringName(tab[&"id"])))
		_tabs.add_child(button)
	_apply_tab_states()


func _apply_tab_states() -> void:
	for button: Node in _tabs.get_children():
		var tab_button := button as Button
		if tab_button == null:
			continue
		var active := StringName(tab_button.get_meta(&"tab", &"")) == _category
		tab_button.set_pressed_no_signal(active)
		tab_button.add_theme_color_override(
			&"font_color", _token(&"text_primary") if active else _token(&"text_dim")
		)


## The P40 column-header band: a leading caption over the title column, one
## caption seated over each fixed column at that column's own width.
func _build_band() -> void:
	var icon_gap := Control.new()
	icon_gap.name = "IconGap"
	icon_gap.custom_minimum_size = Vector2(BAND_LEAD_GAP, 0.0)
	icon_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_band.add_child(icon_gap)
	var lead := _make_label(&"StationCaption", BAND_ITEM)
	lead.name = "HeaderLead"
	lead.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_band.add_child(lead)
	var amount := _make_label(&"StationCaption", BAND_AMOUNT)
	amount.name = "HeaderAmount"
	amount.custom_minimum_size = Vector2(COL_AMOUNT, 0.0)
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_band.add_child(amount)
	var action := _make_label(&"StationCaption", BAND_ACTION)
	action.name = "HeaderAction"
	action.custom_minimum_size = Vector2(ACTION_INLINE.x, 0.0)
	_band.add_child(action)


## One A13 group band (the refinery's `_build_section_header` idiom).
func _build_section_header(text: String) -> void:
	var row := MarginContainer.new()
	row.name = "Band%s" % text.replace(" ", "")
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"margin_left", float(ROW_INNER_MARGIN.x))
	row.add_theme_constant_override(&"margin_right", float(ROW_INNER_MARGIN.x))
	var label := _make_label(&"SectionHeader", text)
	label.name = "SectionLabel"
	row.add_child(label)
	_rows.add_child(row)
	_band_texts.append(text)


## Section 5.8's empty-state caption.
func _build_empty_row() -> void:
	var label := _make_label(&"StationCaption", EMPTY_ROW)
	label.name = "EmptyRow"
	_rows.add_child(label)
	_band_texts.append(EMPTY_ROW)


## One A10 slot row: the refinery grammar - C4 strip, RowInner 12/8, the 40 px
## icon at its own rect, the title box, the AMOUNT cell, A12's chip.
func _add_row(slot: Dictionary) -> void:
	var row := Button.new()
	row.name = "Slot%s" % String(slot[&"id"]).to_pascal_case()
	row.toggle_mode = true
	row.focus_mode = Control.FOCUS_ALL
	row.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ChromeFamily.apply_row(row)
	var inner := MarginContainer.new()
	inner.name = "RowInner"
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override(&"margin_left", float(ROW_INNER_MARGIN.x))
	inner.add_theme_constant_override(&"margin_top", float(ROW_INNER_MARGIN.y))
	inner.add_theme_constant_override(&"margin_right", float(ROW_INNER_MARGIN.x))
	inner.add_theme_constant_override(&"margin_bottom", float(ROW_INNER_MARGIN.y))
	row.add_child(inner)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := HBoxContainer.new()
	box.name = "RowBox"
	box.add_theme_constant_override(&"separation", COLUMN_SEPARATION)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(box)
	var ink := _icon_ink(slot)
	var icon := _make_icon(String(slot.get(&"icon", &"")), ink)
	if icon != null:
		box.add_child(icon)
	else:
		var gap := Control.new()
		gap.name = "IconGap"
		gap.custom_minimum_size = Vector2(COL_ICON, 0.0)
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(gap)
	box.add_child(_make_title_box(slot))
	var amount := _make_label(&"StationValue", _format_int(int(slot[&"amount"])))
	amount.name = "Amount"
	amount.custom_minimum_size = Vector2(COL_AMOUNT, 0.0)
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(amount)
	var chip := Button.new()
	chip.name = "Dispose"
	chip.custom_minimum_size = ACTION_INLINE
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.focus_mode = Control.FOCUS_ALL
	chip.text = DISPOSE_WORD
	chip.disabled = not bool(slot[&"dispose"])
	chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ChromeFamily.apply_chip(chip)
	var payload := {
		&"id": StringName(slot[&"id"]),
		&"dispose_qty": int(slot[&"amount"]),
		&"slot": slot,
		&"row": row,
		&"chip": chip,
	}
	chip.pressed.connect(_on_dispose_pressed.bind(payload))
	box.add_child(chip)
	_rows.add_child(row)
	_slot_payloads.append(payload)


func _make_title_box(slot: Dictionary) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = "TitleBox"
	box.add_theme_constant_override(&"separation", TITLE_SEPARATION)
	## A16: an explicit minimum - the measured title column; the ellipsis-trim
	## labels alone would collapse it to zero.
	box.custom_minimum_size = Vector2(_title_col, 0.0)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := _make_label(&"StationValue", String(slot[&"name"]))
	title.name = "Title"
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(title)
	var meta := _make_label(&"StationMeta", String(slot[&"meta"]))
	meta.name = "Meta"
	meta.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(meta)
	return box


func _make_label(variation: StringName, text: String) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## Detached first, then deferred-deleted: the container's minimum drops the row
## the same frame (the fit re-measures immediately), and a dispose that fires
## from inside a chip's own press emission never walks a freed node (the
## S48 clear's `free()` would - measured 2026-10-14).
func _clear_rows() -> void:
	for child: Node in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	_slot_payloads.clear()
	_band_texts = PackedStringArray()


func _refresh_sort_chip() -> void:
	_sort_chip.text = SORT_CHIP_FORMAT % String(SORT_LABELS[_sort])


func _apply_sort(slots: Array[Dictionary]) -> void:
	match _sort:
		SORT_NAME:
			slots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				return String(a[&"name"]) < String(b[&"name"]))
		SORT_AMOUNT:
			slots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				var left := int(a[&"amount"])
				var right := int(b[&"amount"])
				if left != right:
					return left > right
				return String(a[&"name"]) < String(b[&"name"]))
		_:
			pass


func _filter_category(slots: Array[Dictionary], category: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for slot: Dictionary in slots:
		if StringName(slot[&"category"]) == category:
			out.append(slot)
	return out


## --- the read seams (A9's, unchanged) -------------------------------------------------


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


## A8's `<n>`: the hold's own units summed - the shared builder's read.
func _held_units(items: Dictionary) -> int:
	return Summary.held_units(items)


## A8's `<cap>`: the active hull's cargo column (08 section 3), the OVERVIEW's
## own `Catalog.ship` read - the shared builder's read.
func _cargo_capacity() -> int:
	return Summary.cargo_capacity(_profile())


## The one slot list, A9's five categories in order, the catalogue's own order
## within each - the A14 law's single home is the shared builder; this overlay
## reads through it (the public `slot_rows()` seam unchanged).
func _slots(profile: Node, items: Dictionary) -> Array[Dictionary]:
	return Summary.slots(profile, items)


func _tier_tint(tier: int) -> Color:
	return Summary.tier_tint(tier)


func _grade_tint(grade: int) -> Color:
	return Summary.grade_tint(grade)


## --- the icon laws (the refinery's own, verbatim; the single home is the
## shared builder) ------------------------------------------------------


## The stencil route: prefer `assets/icons/tint/` when a stencil of the same
## file exists, the catalogue path otherwise.
func _icon_source(icon_path: String) -> String:
	return Summary.icon_source(icon_path)


## The refinery's ink law: `text_primary` on the dedicated `icon_mineral_*`
## stencils, the row's tier/grade tint on other stenciled art, WHITE on raw
## catalogue art - the idle alpha always.
func _icon_ink(slot: Dictionary) -> Color:
	var ink := Summary.icon_ink(slot, self)
	return ink


func _make_icon(icon_path: String, ink: Color) -> TextureRect:
	var source := _icon_source(icon_path)
	if source.is_empty() or not ResourceLoader.exists(source):
		return null
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(COL_ICON, COL_ICON)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = load(source)
	icon.modulate = ink
	return icon


## --- the N28 surface laws (A8's, unchanged) ---------------------------------------------


## A15: the one geometry law. The panel's width is the 720 ceiling and the
## scroll's height the 80 % viewport cap, every time - no per-tab or per-content
## re-fit; the rows scroll under the cap while the surface holds still.
func _fit() -> void:
	_panel.custom_minimum_size.x = PANEL_WIDTH
	_panel.custom_minimum_size.y = 0.0
	var cap := _viewport_size().y * MAX_HEIGHT_RATIO - PANEL_MARGIN * 2.0 \
			- _panel_inset.y
	_scroll.custom_minimum_size.y = maxf(0.0, cap)
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	_measure_title_col()
	_clamp_panel()


## A23: the window seats itself — centered on open, clamped to the viewport on
## every later fit; the drag owns the position while the surface is open.
func _center_panel() -> void:
	_panel.reset_size()
	_panel.position = ((_viewport_size() - _panel.size) / 2.0).floor()
	_clamp_panel()


func _clamp_panel() -> void:
	var view := _viewport_size()
	var max_pos := (view - _panel.size).max(Vector2.ZERO)
	_panel.position = _panel.position.clamp(Vector2.ZERO, max_pos)


## A16: the title column measured off the live layout - a laid-out row's own
## width is the engine's truth for the space the columns share (the scroll's
## model can be one layout early). Existing rows are re-seated on the spot.
func _measure_title_col() -> void:
	var row_w := 0.0
	for payload: Dictionary in _slot_payloads:
		var laid_row: Button = payload[&"row"]
		row_w = laid_row.size.x
		break
	if row_w < 300.0:
		var bar: VScrollBar = _scroll.get_v_scroll_bar()
		row_w = _scroll.size.x - bar.size.x
	if row_w < 300.0:
		return
	var col := row_w - float(ROW_INNER_MARGIN.x) * 2.0 - COL_ICON - COL_AMOUNT \
			- ACTION_INLINE.x - float(COLUMN_SEPARATION) * 3.0
	if col <= 0.0:
		return
	_title_col = col
	for payload: Dictionary in _slot_payloads:
		var row: Button = payload[&"row"]
		var box := row.get_node_or_null(NodePath("RowInner/RowBox/TitleBox")) as VBoxContainer
		if box != null:
			box.custom_minimum_size.x = _title_col


## The refinery's space-grouped integer.
func _format_int(value: int) -> String:
	return Summary.format_int(value)


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
	return UiTokensScript.colour(self, token)
