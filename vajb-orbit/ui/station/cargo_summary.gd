class_name CargoSummary
extends RefCounted
## The C overlay's cargo grammar in one place (UI_SPEC section 20, the owner's
## playtest passes): the A14 slots law's single home, the icon ink law, the
## read-only row builder, and — A21 — the overlay's own window (the A15
## chrome, the tab strip, the category grouping, the uncapped scroll) that the
## LAUNCH manifest and the armory's CARGO HOLD block render through at their
## host columns' width. The overlay keeps its chip-bearing rows and delegates
## the slot derivation here; the summaries are read-only — no chip, the
## profile's own category order.

const MineralCatalogScript := preload("res://game/mineral_catalog.gd")
const ComponentCatalogScript := preload("res://game/component_catalog.gd")
const Catalog := preload("res://game/station_catalog.gd")
const ChromeFamily := preload("res://ui/theme/chrome_family.gd")

## A10: the refinery row grammar's own numbers (the overlay's, verbatim).
const ROW_HEIGHT := 76.0
const COL_ICON := 40.0
const COL_AMOUNT := 130.0
const ROW_INNER_MARGIN := Vector2i(12, 8)
const COLUMN_SEPARATION := 12
const TITLE_SEPARATION := 2
const ROW_ICON_IDLE_ALPHA := 0.72
const TINT_DIR := "res://assets/icons/tint/"
const DEDICATED_ICON_PREFIX := "icon_mineral_"
## The column band's lead gap: the row's own 12 px inner margin rides in front
## of the 40 px icon, so the captions seat exactly over the row's columns.
const BAND_LEAD_GAP: float = COL_ICON + float(ROW_INNER_MARGIN.x)
const BAND_ITEM := "ITEM"
const BAND_AMOUNT := "AMOUNT"
const EMPTY_ROW := "NONE HELD"
const ROUNDS_IN_PACK := "%d ROUNDS IN PACK"
const TIER_ORE_META := "TIER %d ORE"
const TIER_INGOT_META := "TIER %d INGOT"
const GRADE_COMPONENT_META := "GRADE %d COMPONENT"
const GRADE_FUEL_META := "GRADE %d FUEL CELL"
const POW_FAMILY: StringName = &"pow"

## A8's pinned copy - the single home; the overlay and the armory's block
## caption read it.
const TITLE_FORMAT := "CARGO — %d/%d UNITS"

## A9's five words + ALL, in A9's order; the section headers reuse the labels.
const CATEGORY_AMMO: StringName = &"ammo"
const CATEGORY_ORE: StringName = &"ore"
const CATEGORY_INGOTS: StringName = &"ingots"
const CATEGORY_COMPONENTS: StringName = &"components"
const CATEGORY_FUEL: StringName = &"fuel"
const TAB_ALL: StringName = &"all"
const CATEGORY_ORDER: Array[StringName] = [
	CATEGORY_AMMO, CATEGORY_ORE, CATEGORY_INGOTS, CATEGORY_COMPONENTS, CATEGORY_FUEL,
]
const CATEGORY_LABELS := {
	CATEGORY_AMMO: "AMMUNITION",
	CATEGORY_ORE: "ORE",
	CATEGORY_INGOTS: "INGOTS",
	CATEGORY_COMPONENTS: "COMPONENTS",
	CATEGORY_FUEL: "FUEL CELLS",
	TAB_ALL: "ALL",
}

## A11's strip: the five categories + ALL, in the strip's own order — the
## overlay's tab row and the A21 windows' read the same list.
const CARGO_TABS: Array[Dictionary] = [
	{&"id": CATEGORY_AMMO, &"label": "AMMUNITION"},
	{&"id": CATEGORY_ORE, &"label": "ORE"},
	{&"id": CATEGORY_INGOTS, &"label": "INGOTS"},
	{&"id": CATEGORY_COMPONENTS, &"label": "COMPONENTS"},
	{&"id": CATEGORY_FUEL, &"label": "FUEL CELLS"},
	{&"id": TAB_ALL, &"label": "ALL"},
]

## A21's window chrome — the overlay's own values (its scene plus its
## `_fit()`), verbatim: the PanelRaised panel, the 16 px margin, the
## content/title/tab/row separations, the tab chip's own 32 px height.
const WINDOW_VARIATION := &"PanelRaised"
const WINDOW_MARGIN := 16
const CONTENT_SEPARATION := 12
const TITLE_ROW_SEPARATION := 12
const TABS_SEPARATION := 4
const ROWS_SEPARATION := 8
const TAB_MIN_SIZE := Vector2(0.0, 32.0)


## A14's law, verbatim from the overlay's `_slots`: the one slot list, A9's
## five categories in order, the catalogue's own order within each.
## AMMUNITION carries only the families the hold lists (A14: hold units are
## the row's existence test); its amount is the hold stack, the pack rides the
## meta line.
static func slots(profile: Node, items: Dictionary) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	if profile != null and profile.has_method(&"ammo_of"):
		for family: StringName in Catalog.ammo_ids():
			var pack := Catalog.ammo_pack(family)
			if pack.is_empty():
				continue
			var item_id := Catalog.ammo_item_id(family)
			var rounds := int(profile.call(&"ammo_of", family))
			var units := held(items, item_id)
			## A14: the zero-hold ammo law - the hold's units are the row's own
			## existence test; the fitted pack's rounds never summon one.
			if units <= 0:
				continue
			list.append({
				&"id": item_id,
				&"category": CATEGORY_AMMO,
				&"name": String(pack.get(&"name", String(family))).to_upper(),
				&"meta": ROUNDS_IN_PACK % rounds,
				&"amount": units,
				&"dispose": units > 0,
				&"icon": String(pack.get(&"icon", &"")),
				&"tint": Color.WHITE,
			})
	for mineral_id: StringName in MineralCatalogScript.mineral_ids():
		var mineral: Dictionary = MineralCatalogScript.mineral(mineral_id)
		if mineral.is_empty():
			continue
		_add_mineral_slot(list, items, mineral_id, mineral, true)
		_add_mineral_slot(list, items, mineral_id, mineral, false)
	for entry: Dictionary in ComponentCatalogScript.COMPONENTS:
		var component_id := StringName(entry.get(&"id", &""))
		var family := StringName(entry.get(&"family", &""))
		if component_id == &"" or (family == POW_FAMILY) != false:
			continue
		var qty := held(items, component_id)
		if qty <= 0:
			continue
		list.append({
			&"id": component_id,
			&"category": CATEGORY_COMPONENTS,
			&"name": String(entry.get(&"name", String(component_id))).to_upper(),
			&"meta": GRADE_COMPONENT_META % int(entry.get(&"grade", 0)),
			&"amount": qty,
			&"dispose": true,
			&"icon": String(entry.get(&"icon", &"")),
			&"tint": grade_tint(int(entry.get(&"grade", 0))),
		})
	for entry: Dictionary in ComponentCatalogScript.COMPONENTS:
		var component_id := StringName(entry.get(&"id", &""))
		var family := StringName(entry.get(&"family", &""))
		if component_id == &"" or (family == POW_FAMILY) != true:
			continue
		var qty := held(items, component_id)
		if qty <= 0:
			continue
		list.append({
			&"id": component_id,
			&"category": CATEGORY_FUEL,
			&"name": String(entry.get(&"name", String(component_id))).to_upper(),
			&"meta": GRADE_FUEL_META % int(entry.get(&"grade", 0)),
			&"amount": qty,
			&"dispose": true,
			&"icon": String(entry.get(&"icon", &"")),
			&"tint": grade_tint(int(entry.get(&"grade", 0))),
		})
	return list


static func _add_mineral_slot(
		list: Array[Dictionary], items: Dictionary, mineral_id: StringName,
		mineral: Dictionary, ore: bool
) -> void:
	var item_id := MineralCatalogScript.ore_id(mineral_id) if ore \
			else MineralCatalogScript.ingot_id(mineral_id)
	var qty := held(items, item_id)
	if qty <= 0:
		return
	list.append({
		&"id": item_id,
		&"category": CATEGORY_ORE if ore else CATEGORY_INGOTS,
		&"name": ("%s ORE" if ore else "%s INGOT") % String(mineral.get(&"name", String(mineral_id))).to_upper(),
		&"meta": (TIER_ORE_META if ore else TIER_INGOT_META) % int(mineral.get(&"tier", 0)),
		&"amount": qty,
		&"dispose": true,
		&"icon": String(mineral.get(&"icon_ore" if ore else &"icon_ingot", &"")),
		&"tint": tier_tint(int(mineral.get(&"tier", 0))),
	})


static func tier_tint(tier: int) -> Color:
	if MineralCatalogScript.TIER_TINTS.has(tier):
		return MineralCatalogScript.TIER_TINTS[tier]
	return Color.WHITE


static func grade_tint(grade: int) -> Color:
	if ComponentCatalogScript.GRADE_TINTS.has(grade):
		return ComponentCatalogScript.GRADE_TINTS[grade]
	return Color.WHITE


## A8's `<n>`: the hold's own units summed.
static func held_units(items: Dictionary) -> int:
	var used := 0
	for quantity: Variant in items.values():
		used += int(quantity)
	return used


## A8's `<cap>`: the active hull's cargo column (08 section 3).
static func cargo_capacity(profile: Node) -> int:
	if profile == null or not profile.has_method(&"active_ship"):
		return 0
	var ship: Dictionary = Catalog.ship(StringName(profile.call(&"active_ship")))
	return int(ship.get(&"cargo", 0))


static func held(items: Dictionary, item_id: StringName) -> int:
	return int(items.get(item_id, 0))


## The stencil route: prefer `assets/icons/tint/` when a stencil of the same
## file exists, the catalogue path otherwise.
static func icon_source(icon_path: String) -> String:
	if icon_path.is_empty():
		return ""
	var stencil := TINT_DIR + icon_path.get_file()
	if stencil != icon_path and ResourceLoader.exists(stencil):
		return stencil
	return icon_path


## The refinery's ink law: `text_primary` on the dedicated `icon_mineral_*`
## stencils, the slot's tier/grade tint on other stenciled art, WHITE on raw
## catalogue art - the idle alpha always. The theme token reads off the host
## control (a static helper cannot reach a theme without one).
static func icon_ink(slot: Dictionary, host: Control) -> Color:
	var ink := Color.WHITE
	var source := icon_source(String(slot.get(&"icon", &"")))
	if source.begins_with(TINT_DIR):
		if source.get_file().begins_with(DEDICATED_ICON_PREFIX):
			if host != null and host.has_theme_color(&"text_primary", TOKENS_TYPE):
				ink = host.get_theme_color(&"text_primary", TOKENS_TYPE)
		else:
			var tint: Variant = slot.get(&"tint", Color.WHITE)
			if tint is Color:
				ink = tint
	ink.a = ROW_ICON_IDLE_ALPHA
	return ink


## A21: the C overlay's own window at the host column's width — the A15
## chrome (`PanelRaised` panel expand-filling its column, the 16 px margin,
## the vertical scroll always shown and horizontal disabled, the content
## column) carrying the title row, the tab strip, the ITEM/AMOUNT band and the
## rows box. The sort chip and the close hint stay the overlay's own dialog
## affordances. The children keep the overlay's node names so probes read one
## grammar; the host names the root (the armory's `CargoWindow` cannot collide
## with the station's `CargoLayer/CargoOverlay` in a tree search). Returns the
## nodes the host keeps: window/scroll/title/tabs/rows.
static func build_window(parent: Control, window_name: String, on_tab: Callable) -> Dictionary:
	var window := PanelContainer.new()
	window.name = window_name
	window.theme_type_variation = WINDOW_VARIATION
	window.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	window.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(window)
	var margin := MarginContainer.new()
	margin.name = "CargoMargin"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override(&"margin_left", WINDOW_MARGIN)
	margin.add_theme_constant_override(&"margin_top", WINDOW_MARGIN)
	margin.add_theme_constant_override(&"margin_right", WINDOW_MARGIN)
	margin.add_theme_constant_override(&"margin_bottom", WINDOW_MARGIN)
	window.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.name = "CargoScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	margin.add_child(scroll)
	var content := VBoxContainer.new()
	content.name = "CargoContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override(&"separation", CONTENT_SEPARATION)
	scroll.add_child(content)
	var title_row := HBoxContainer.new()
	title_row.name = "CargoTitleRow"
	title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_theme_constant_override(&"separation", TITLE_ROW_SEPARATION)
	content.add_child(title_row)
	var title := _label(&"StationValue", "")
	title.name = "CargoTitle"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_row.add_child(title)
	var tabs := HBoxContainer.new()
	tabs.name = "CargoTabs"
	tabs.add_theme_constant_override(&"separation", TABS_SEPARATION)
	content.add_child(tabs)
	_build_tabs(tabs, on_tab)
	content.add_child(_build_band())
	var rows := VBoxContainer.new()
	rows.name = "CargoRows"
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override(&"separation", ROWS_SEPARATION)
	content.add_child(rows)
	return {
		&"window": window, &"scroll": scroll, &"title": title,
		&"tabs": tabs, &"rows": rows,
	}


## The overlay's tab strip (A11): six toggle tabs, the active one
## text_primary + pressed, the rest text_dim — the colours apply in
## `apply_tab_states` on every refresh.
static func _build_tabs(tabs_box: HBoxContainer, on_tab: Callable) -> void:
	for tab: Dictionary in CARGO_TABS:
		var button := Button.new()
		button.name = "Tab%s" % String(tab[&"id"]).to_pascal_case()
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_ALL
		button.custom_minimum_size = TAB_MIN_SIZE
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = String(tab[&"label"])
		button.set_meta(&"tab", StringName(tab[&"id"]))
		button.pressed.connect(on_tab.bind(StringName(tab[&"id"])))
		tabs_box.add_child(button)


static func apply_tab_states(tabs_box: Control, category: StringName, host: Control) -> void:
	if tabs_box == null:
		return
	for button_node: Node in tabs_box.get_children():
		var button := button_node as Button
		if button == null:
			continue
		var active := StringName(button.get_meta(&"tab", &"")) == category
		button.set_pressed_no_signal(active)
		if host != null and host.has_theme_color(&"text_primary", TOKENS_TYPE):
			button.add_theme_color_override(
				&"font_color",
				host.get_theme_color(&"text_primary", TOKENS_TYPE) if active
					else host.get_theme_color(&"text_dim", TOKENS_TYPE)
			)


static func filter_category(
		list: Array[Dictionary], category: StringName
) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for slot: Dictionary in list:
		if StringName(slot[&"category"]) == category:
			out.append(slot)
	return out


## The read-only window's refresh (A21): the A8 title words, then the rows —
## ALL view groups the full list under the A13 headers, a category tab shows
## that band's rows flat, exactly the overlay's own split, and the scroll owns
## the length (no cap, no tail — the A17 bound stays the HUD block's law). The
## rows box is cleared first - detached, then deferred-deleted (the S48 law:
## queue_free alone double-renders a frame in the frame-less runner, and a
## live refresh cannot free a row from inside its own press emission either).
static func populate_window(
		parts: Dictionary, profile: Node, host: Control, category: StringName
) -> void:
	var rows_box: VBoxContainer = parts.get(&"rows")
	if rows_box == null:
		return
	clear_rows(rows_box)
	var items: Dictionary = {}
	if profile != null and profile.has_method(&"cargo_items"):
		var raw: Variant = profile.call(&"cargo_items")
		items = raw if raw is Dictionary else {}
	var title: Label = parts.get(&"title")
	if title != null:
		title.text = TITLE_FORMAT % [held_units(items), cargo_capacity(profile)]
	var list := slots(profile, items)
	if category != TAB_ALL:
		for slot: Dictionary in filter_category(list, category):
			rows_box.add_child(_summary_row(slot, host))
	else:
		for group: StringName in CATEGORY_ORDER:
			var band_slots := filter_category(list, group)
			if band_slots.is_empty():
				continue
			rows_box.add_child(_section_header(String(CATEGORY_LABELS[group])))
			for slot: Dictionary in band_slots:
				rows_box.add_child(_summary_row(slot, host))
	if list.is_empty():
		rows_box.add_child(_caption_label(EMPTY_ROW))
	apply_tab_states(parts.get(&"tabs"), category, host)


static func clear_rows(rows_box: VBoxContainer) -> void:
	for child: Node in rows_box.get_children():
		rows_box.remove_child(child)
		child.queue_free()


## The P40 column-header band: a leading caption over the title column and one
## caption seated over the AMOUNT column at its own width — the summaries carry
## no ACTION column (no chip).
static func _build_band() -> HBoxContainer:
	var band := HBoxContainer.new()
	band.name = "CargoBand"
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_theme_constant_override(&"separation", COLUMN_SEPARATION)
	var icon_gap := Control.new()
	icon_gap.name = "IconGap"
	icon_gap.custom_minimum_size = Vector2(BAND_LEAD_GAP, 0.0)
	icon_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(icon_gap)
	var lead := _caption_label(BAND_ITEM)
	lead.name = "HeaderLead"
	lead.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	band.add_child(lead)
	var amount := _caption_label(BAND_AMOUNT)
	amount.name = "HeaderAmount"
	amount.custom_minimum_size = Vector2(COL_AMOUNT, 0.0)
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	band.add_child(amount)
	return band


static func _section_header(text: String) -> MarginContainer:
	var row := MarginContainer.new()
	row.name = "Band%s" % text.replace(" ", "")
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"margin_left", float(ROW_INNER_MARGIN.x))
	row.add_theme_constant_override(&"margin_right", float(ROW_INNER_MARGIN.x))
	var label := Label.new()
	label.name = "SectionLabel"
	label.theme_type_variation = &"SectionHeader"
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	return row


## One A10 slot row without the chip: the C4 strip, `RowInner` 12/8, the
## 40 px icon at its own rect, the title box (A16's explicit minimum so the
## ellipsis-trim labels cannot collapse it), the right-aligned AMOUNT cell.
## The row is a read-only Button: the overlay's rows carry no press of their
## own either (only the chip acts), so the look and the focus behaviour match.
static func _summary_row(slot: Dictionary, host: Control) -> Button:
	var row := Button.new()
	row.name = "Slot%s" % String(slot[&"id"]).to_pascal_case()
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
	var icon := _icon(slot, host)
	if icon != null:
		box.add_child(icon)
	else:
		var gap := Control.new()
		gap.name = "IconGap"
		gap.custom_minimum_size = Vector2(COL_ICON, 0.0)
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(gap)
	var title_box := VBoxContainer.new()
	title_box.name = "TitleBox"
	title_box.add_theme_constant_override(&"separation", TITLE_SEPARATION)
	title_box.custom_minimum_size = Vector2(TITLE_FLOOR, 0.0)
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title_box)
	var title := _label(&"StationValue", String(slot[&"name"]))
	title.name = "Title"
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_box.add_child(title)
	var meta := _label(&"StationMeta", String(slot[&"meta"]))
	meta.name = "Meta"
	meta.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_box.add_child(meta)
	var amount := _label(&"StationValue", format_int(int(slot[&"amount"])))
	amount.name = "Amount"
	amount.custom_minimum_size = Vector2(COL_AMOUNT, 0.0)
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(amount)
	return row


## A16's floor for the summaries' title column: the overlay measures its own
## off the live layout; the summaries are fixed-width surfaces whose column
## reads off the host's own width minus the row's known constants.
const TITLE_FLOOR := 150.0

## The grouped-number formatter (the overlay's `_format_int`, moved here as
## the shared home - the AMOUNT cell and every summary read it).
static func format_int(value: int) -> String:
	var digits := str(absi(value))
	var grouped := ""
	var count := 0
	for index in range(digits.length() - 1, -1, -1):
		grouped = digits[index] + grouped
		count += 1
		if count % 3 == 0 and index > 0:
			grouped = " " + grouped
	return ("-" if value < 0 else "") + grouped


const TOKENS_TYPE: StringName = &"Tokens"

static func _icon(slot: Dictionary, host: Control) -> TextureRect:
	var source := icon_source(String(slot.get(&"icon", &"")))
	if source.is_empty() or not ResourceLoader.exists(source):
		return null
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(COL_ICON, COL_ICON)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = load(source)
	icon.modulate = icon_ink(slot, host)
	return icon


static func _label(variation: StringName, text: String) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


static func _caption_label(text: String) -> Label:
	var label := Label.new()
	label.theme_type_variation = &"StationCaption"
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
