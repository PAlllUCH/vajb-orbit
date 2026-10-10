extends VBoxContainer
## OVERVIEW pane (S30, STATION_HUB section 18 P17/P18 + section 19): the landing pane on
## dock, wearing P7's one skeleton (PaneHeader / content split / foot band). Its split
## carries P18's five blocks as one stack inside a vertical `ScrollContainer` (P22): the
## identity plate (section 15 treatment), the 3x2 department tiles (P23), the active hull
## and repair summary (P24), the U2 services rows (P25) and one flavour line (P27).
##
## Contract: STATION_HUB section 19.1/19.2/19.4, UI_SPEC section 12 (A5.5 everywhere -
## hover mutates colour and `modulate` only, never a box). Tokens only (N29); every glyph
## is a shipped asset reused at its own cut. The pane never routes and never writes the
## profile: it emits `navigate_requested` up and reads the catalogue down.

const TOKENS_TYPE: StringName = &"Tokens"
const ChromeFamily := preload("res://ui/theme/chrome_family.gd")

const Catalog := preload("res://game/station_catalog.gd")
const ShipFit := preload("res://game/ship_fit.gd")
const RepairsService := preload("res://game/repairs.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")
## 14's 2026-10-08 block: the docked place - its service matrix (block 4's unavailable
## state) and its own vault record.
const StationRegistryScript := preload("res://game/station_registry.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"

signal status_requested(message: String, danger: bool)
signal inspect_requested(title: String, body: String, danger: bool)
signal navigate_requested(deck: int, hint: StringName)

## The six department tiles (P23), row-major ARMORY / REFINERY / EXCHANGE then AUCTION /
## SHIPYARD / LAUNCH. `deck` is the shell's Module enum index.
const TILES: Array[Dictionary] = [
	{&"deck": 0, &"title": "ARMORY", &"caption": "BUY, FIT AND SWAP MODULES", &"icon": "res://assets/icons/equip/icon_equip_module.png", &"tinted": false},
	{&"deck": 1, &"title": "REFINERY", &"caption": "3 ORE = 1 INGOT", &"icon": "res://assets/icons/cargo/icon_cargo_ore.svg", &"tinted": true},
	{&"deck": 2, &"title": "EXCHANGE", &"caption": "SELL YOUR HOLD", &"icon": "res://assets/icons/cargo/icon_credits.svg", &"tinted": true},
	{&"deck": 3, &"title": "AUCTION", &"caption": "THE HOUSE SHELF · 20-MINUTE RESTOCK", &"icon": "res://assets/icons/cargo/icon_credits.svg", &"tinted": true},
	{&"deck": 4, &"title": "SHIPYARD", &"caption": "HULLS, MODULES AND REPAIRS", &"icon": "res://assets/icons/hud/icon_hull.svg", &"tinted": true},
	{&"deck": 5, &"title": "LAUNCH", &"caption": "BRIEF, CARGO, UNDOCK", &"icon": "res://assets/icons/map/icon_map_route.png", &"tinted": false},
]

## P26: the SERVICES pane's own deck index (the deep-link target), outside P20's cycle.
const SERVICES := 7

## P25's three rows: the U2 service names, their shipped glyphs, and the readout key.
const SERVICE_ROWS: Array[Dictionary] = [
	{&"key": &"contracts", &"name": "CONTRACTS", &"icon": "res://assets/icons/contract/icon_contract_haul.svg"},
	{&"key": &"insurance", &"name": "INSURANCE", &"icon": "res://assets/icons/service/icon_service_insurance.svg"},
	{&"key": &"vaults", &"name": "VAULTS", &"icon": "res://assets/icons/service/icon_service_vault.svg"},
]

## STATION_HUB section 19.1's own numbers (reused, not re-derived).
const TILE_MIN := Vector2(300.0, 140.0)
const TILE_COLUMNS := 3
const TILE_SEPARATION := 16
const TILE_MARGIN := 16
const GLYPH_SIZE := 48.0
const ROW_HEIGHT := 76.0
const ROW_ICON := 24.0
const ROW_INNER_MARGIN := Vector2i(12, 8)
const CHIP_SIZE := Vector2(96.0, 32.0)
const CAPTION_ACTIVE_HULL := "ACTIVE HULL"
const META_FORMAT := "%s CLASS · %d HULL · %d SLOTS"
const REPAIR_AVAILABLE := "REPAIR AVAILABLE · %s CR"
const ALL_NOMINAL := "ALL SYSTEMS NOMINAL"
const CONTRACTS_FORMAT := "ACTIVE CONTRACTS %d/3"
const CONTRACTS_MAX := 3
const INSURED_TEXT := "INSURED · COVERS ONE LOSS"
const UNINSURED_TEXT := "UNINSURED"
const VAULT_FORMAT := "THIS VAULT — %d / %d UNITS"
## U14's base capacity (PROPOSED 40/60/80 by tier). The record read below resolves the
## docked station's own vault (14's 2026-10-08 block); the capacity stays the base tier's
## reading, because section 4's tiers are rented per station and S26 owns the tier pane.
## Reversal: read the record's own tier into the denominator.
const VAULT_BASE_CAPACITY := 40
const FLAVOUR_LINE := "THE DOCK CLAMPS ARE CHEAP. THE AMMUNITION IS NOT."
const FACTION_ICON_TEMPLATE := "res://assets/icons/tint/icon_insignia_%s_48.png"
const OVERVIEW_FALLBACK_ICON := "res://assets/icons/tint/icon_map_node_station_48.png"

@onready var _pane_icon: TextureRect = %PaneIcon
@onready var _stack: VBoxContainer = %BlockStack

var _identity_plate: PanelContainer = null
var _identity_mark: TextureRect = null
var _identity_name: Label = null
var _identity_character: Label = null
var _hull_name: Label = null
var _hull_meta: Label = null
var _hull_stats: Label = null
var _hull_repair: Label = null
var _service_reads: Dictionary = {}
var _service_rows: Dictionary = {}
var _service_chips: Dictionary = {}
var _service_names: Dictionary = {}
var _tile_glyphs: Array[TextureRect] = []
var _identity_faction: StringName = &""


func _ready() -> void:
	_pane_icon.custom_minimum_size = Vector2(40.0, 40.0)
	_pane_icon.texture = load(_overview_icon())
	_build_identity()
	_build_tiles()
	_build_hull_block()
	_build_services()
	_build_flavour()
	_refresh_blocks()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_apply_tokens()


## The shell pushes the header's identity in (one source of truth for the station name and
## character line). Called after the shell mounts the pane.
func set_identity(station_name: String, character_line: String, faction: StringName) -> void:
	_identity_faction = faction
	if _identity_name != null:
		_identity_name.text = station_name
	if _identity_character != null:
		_identity_character.text = character_line
	if _identity_mark != null:
		var path := _faction_icon(faction)
		if ResourceLoader.exists(path):
			_identity_mark.texture = load(path)
	_apply_tokens()


func focus_primary() -> void:
	for tile: Button in _tile_buttons():
		if not tile.disabled:
			tile.grab_focus()
			return


func refresh_profile(_key: StringName) -> void:
	_refresh_blocks()


func _overview_icon() -> String:
	var faction := _docked_faction()
	if not faction.is_empty():
		var path := FACTION_ICON_TEMPLATE % String(faction)
		if ResourceLoader.exists(path):
			return path
	return OVERVIEW_FALLBACK_ICON


func _faction_icon(faction: StringName) -> String:
	if faction.is_empty():
		return OVERVIEW_FALLBACK_ICON
	var path := FACTION_ICON_TEMPLATE % String(faction)
	if ResourceLoader.exists(path):
		return path
	return OVERVIEW_FALLBACK_ICON


## Block 1: the section 15.5 name plate (UI_SPEC section 7 A5.4-1) - a flat Tokens box,
## faction glyph 48 at its own cut, the station name and the character line.
func _build_identity() -> void:
	_identity_plate = PanelContainer.new()
	_identity_plate.name = "IdentityBlock"
	_identity_plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	## S36: the identity block keeps its flat Tokens box and its faction border (a code
	## feature, not a stretched plate) - the owner's "native chrome keeps it" criterion.
	_stack.add_child(_identity_plate)
	var margin := MarginContainer.new()
	margin.name = "IdentityMargin"
	margin.add_theme_constant_override(&"margin_left", 12)
	margin.add_theme_constant_override(&"margin_top", 8)
	margin.add_theme_constant_override(&"margin_right", 12)
	margin.add_theme_constant_override(&"margin_bottom", 8)
	_identity_plate.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	margin.add_child(row)
	_identity_mark = TextureRect.new()
	_identity_mark.custom_minimum_size = Vector2(GLYPH_SIZE, GLYPH_SIZE)
	_identity_mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_identity_mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_identity_mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_identity_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_identity_mark.texture = load(OVERVIEW_FALLBACK_ICON)
	row.add_child(_identity_mark)
	var box := VBoxContainer.new()
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_theme_constant_override(&"separation", 2)
	row.add_child(box)
	_identity_name = Label.new()
	_identity_name.theme_type_variation = &"HeroTitle"
	box.add_child(_identity_name)
	_identity_character = Label.new()
	_identity_character.theme_type_variation = &"StationCaption"
	box.add_child(_identity_character)


## Block 2: the 3x2 department tiles (P23). A tile is a Button (container children), the
## theme's `panel_raised` flat bevel, navigating on press.
func _build_tiles() -> void:
	var grid := GridContainer.new()
	grid.name = "TileGrid"
	grid.columns = TILE_COLUMNS
	grid.add_theme_constant_override(&"h_separation", TILE_SEPARATION)
	grid.add_theme_constant_override(&"v_separation", TILE_SEPARATION)
	_stack.add_child(grid)
	for tile_data: Dictionary in TILES:
		grid.add_child(_make_tile(tile_data))


func _make_tile(tile_data: Dictionary) -> Button:
	var button := Button.new()
	button.name = "%sTile" % String(tile_data[&"title"]).to_pascal_case()
	button.custom_minimum_size = TILE_MIN
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_tile_chrome(button)
	var margin := MarginContainer.new()
	margin.name = "TileMargin"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override(&"margin_left", TILE_MARGIN)
	margin.add_theme_constant_override(&"margin_top", TILE_MARGIN)
	margin.add_theme_constant_override(&"margin_right", TILE_MARGIN)
	margin.add_theme_constant_override(&"margin_bottom", TILE_MARGIN)
	button.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 8)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)
	var head := HBoxContainer.new()
	head.add_theme_constant_override(&"separation", 12)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(head)
	var glyph := TextureRect.new()
	glyph.custom_minimum_size = Vector2(GLYPH_SIZE, GLYPH_SIZE)
	glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.texture = load(String(tile_data[&"icon"]))
	## S40 (UI_SPEC section 16, A3): the tinted glyphs carry the caption tone, not
	## `text_dim` - the C1 slab's interior measures 3.32-3.55:1 against `text_dim`.
	glyph.modulate = _token(&"text_caption") if bool(tile_data[&"tinted"]) else Color.WHITE
	head.add_child(glyph)
	_tile_glyphs.append(glyph)
	var title := Label.new()
	title.theme_type_variation = &"SectionHeader"
	title.text = String(tile_data[&"title"])
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(title)
	var caption := Label.new()
	caption.theme_type_variation = &"StationCaption"
	caption.text = String(tile_data[&"caption"])
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(caption)
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_END
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(foot)
	foot.add_child(_make_chevron())
	var deck := int(tile_data[&"deck"])
	button.pressed.connect(_on_tile_pressed.bind(deck))
	button.mouse_entered.connect(_on_tile_hover.bind(button, glyph, String(tile_data[&"title"]), String(tile_data[&"caption"])))
	button.mouse_exited.connect(_on_tile_unhover.bind(button, glyph))
	return button


## P23's tile chrome (S36, UI_SPEC section 15.1/15.6): the C1 `ui_tile_slab` rail cut drawn
## as a uniform canvas at the tile rect - the transparent pad is the owner's accepted look
## (never cropped to fill). States stay tint-only (A7).
func _apply_tile_chrome(button: Button) -> void:
	ChromeFamily.apply_tile(button)


func _on_tile_pressed(deck: int) -> void:
	navigate_requested.emit(deck, &"")


## P23's hover state (A5.5 legal): the glyph brightens. Hover also publishes the tile's
## own description on the chain (P21).
func _on_tile_hover(button: Button, glyph: TextureRect, title: String, caption: String) -> void:
	if button.button_pressed:
		return
	glyph.modulate = _token(&"text_primary")
	inspect_requested.emit(title, caption, false)


func _on_tile_unhover(_button: Button, glyph: TextureRect) -> void:
	glyph.modulate = _token(&"text_caption")
	inspect_requested.emit("", "", false)


## Block 3: the active hull and the repair summary (P24), with `REPAIR` deep-linking to
## SHIPYARD (the active hull selected, the repair block focused).
func _build_hull_block() -> void:
	var block := HBoxContainer.new()
	block.name = "HullBlock"
	block.add_theme_constant_override(&"separation", 16)
	_stack.add_child(block)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override(&"separation", 6)
	block.add_child(left)
	var caption := Label.new()
	caption.theme_type_variation = &"SectionHeader"
	caption.text = CAPTION_ACTIVE_HULL
	left.add_child(caption)
	_hull_name = Label.new()
	_hull_name.theme_type_variation = &"StationValue"
	left.add_child(_hull_name)
	_hull_meta = Label.new()
	_hull_meta.theme_type_variation = &"StationCaption"
	left.add_child(_hull_meta)
	_hull_stats = Label.new()
	_hull_stats.theme_type_variation = &"StationCaption"
	left.add_child(_hull_stats)
	_hull_repair = Label.new()
	_hull_repair.theme_type_variation = &"StationCaption"
	left.add_child(_hull_repair)
	var chip := _make_chip("REPAIR")
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.pressed.connect(_on_repair_pressed)
	block.add_child(chip)


func _on_repair_pressed() -> void:
	navigate_requested.emit(4, &"repair")


## Block 4: the U2 services rows (P25) - the section 3.1 76-tall row idiom, an icon 24, the
## name, a right-aligned readout and a trailing `OPEN` chip, deep-linking to SERVICES (P26).
func _build_services() -> void:
	var rows := VBoxContainer.new()
	rows.name = "ServiceRows"
	rows.add_theme_constant_override(&"separation", 6)
	_stack.add_child(rows)
	for service: Dictionary in SERVICE_ROWS:
		rows.add_child(_make_service_row(service))


func _make_service_row(service: Dictionary) -> Button:
	var row := Button.new()
	row.name = "%sRow" % String(service[&"name"]).to_pascal_case()
	row.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	row.focus_mode = Control.FOCUS_ALL
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	## S36 (UI_SPEC section 15.1): the service row wears C4 `ui_row_strip`.
	ChromeFamily.apply_row(row)
	var box := _make_inner(row)
	box.add_child(_make_icon(String(service[&"icon"]), ROW_ICON, true))
	var name_label := Label.new()
	name_label.text = String(service[&"name"])
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_label)
	_service_names[service[&"key"]] = name_label
	var read := Label.new()
	read.theme_type_variation = &"StationValue"
	read.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	read.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	read.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	read.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(read)
	_service_reads[service[&"key"]] = read
	var chip := _make_chip("OPEN")
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.pressed.connect(_on_service_pressed)
	box.add_child(chip)
	_service_rows[service[&"key"]] = row
	_service_chips[service[&"key"]] = chip
	row.pressed.connect(_on_service_pressed)
	row.mouse_entered.connect(_on_row_hover.bind(String(service[&"name"])))
	row.mouse_exited.connect(_on_row_unhover)
	return row


func _on_service_pressed() -> void:
	navigate_requested.emit(SERVICES, &"")


func _on_row_hover(name: String) -> void:
	inspect_requested.emit(name, "OPEN THE SERVICES DECK", false)


func _on_row_unhover() -> void:
	inspect_requested.emit("", "", false)


## Block 5: one flavour line (P27).
func _build_flavour() -> void:
	var line := Label.new()
	line.name = "FlavourLine"
	line.theme_type_variation = &"StationCaption"
	line.text = FLAVOUR_LINE
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stack.add_child(line)


## A small code-drawn chevron mark in its own child rect (P30), never the literal arrow
## glyph (the theme font set does not guarantee it, section 5.8's finding).
func _make_chevron() -> Control:
	var chevron := Chevron.new()
	chevron.custom_minimum_size = Vector2(16.0, 16.0)
	chevron.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chevron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chevron.colour = _token(&"text_caption")
	return chevron


func _make_chip(text: String) -> Button:
	var button := Button.new()
	button.name = "%sChip" % text.to_pascal_case()
	button.custom_minimum_size = CHIP_SIZE
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	## S36 (UI_SPEC section 15.1): the chip wears C3 `ui_inline_chip`.
	ChromeFamily.apply_chip(button)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override(&"margin_left", 10)
	margin.add_theme_constant_override(&"margin_right", 6)
	button.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)
	var label := Label.new()
	label.text = text
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	row.add_child(_make_chevron())
	return button


func _make_inner(button: Button) -> HBoxContainer:
	var inner := MarginContainer.new()
	inner.name = "RowInner"
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override(&"margin_left", ROW_INNER_MARGIN.x)
	inner.add_theme_constant_override(&"margin_top", ROW_INNER_MARGIN.y)
	inner.add_theme_constant_override(&"margin_right", ROW_INNER_MARGIN.x)
	inner.add_theme_constant_override(&"margin_bottom", ROW_INNER_MARGIN.y)
	button.add_child(inner)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := HBoxContainer.new()
	box.add_theme_constant_override(&"separation", 12)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(box)
	return box


func _make_icon(path: String, icon_size: float, tinted: bool) -> TextureRect:
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = load(path)
	icon.modulate = _token(&"text_primary") if tinted else Color.WHITE
	return icon


func _tile_buttons() -> Array[Button]:
	var out: Array[Button] = []
	for child: Node in _stack.get_children():
		if child is GridContainer:
			for tile: Node in child.get_children():
				if tile is Button:
					out.append(tile)
	return out


func _refresh_blocks() -> void:
	_refresh_hull()
	_refresh_services()


func _refresh_hull() -> void:
	if _hull_name == null:
		return
	var profile := _profile()
	var active := _active_ship(profile)
	var ship := Catalog.ship(active)
	if ship.is_empty():
		_hull_name.text = "NO HULL"
		_hull_meta.text = ""
		_hull_stats.text = ""
		_hull_repair.text = ALL_NOMINAL
		return
	var hull: Dictionary = ShipFit.HULLS.get(active, {})
	_hull_name.text = String(ship.get(&"name", "")).to_upper()
	_hull_meta.text = META_FORMAT % [
		String(hull.get(&"ship_class", "")).to_upper(),
		int(ship.get(&"hull", 0)),
		_slot_cell_count(active),
	]
	_hull_stats.text = _stat_pairs(profile, active, ship)
	_hull_repair.text = _repair_summary(profile, active)


func _stat_pairs(profile: ProfileScript, active: StringName, ship: Dictionary) -> String:
	var current := _vitals(profile, active)
	var maxima := _maxima(profile, active, ship)
	var parts: Array[String] = [
		"HULL %d / %d" % [int(current.get(&"hull", maxima.get(&"hull", 0))), int(maxima.get(&"hull", 0))],
		"SHIELD %d / %d" % [int(current.get(&"shield", maxima.get(&"shield", 0))), int(maxima.get(&"shield", 0))],
		"CARGO %d / %d" % [int(ship.get(&"cargo", 0)), int(ship.get(&"cargo", 0))],
		"ENGINES %d" % int(ShipFit.grid_counts(active).get(&"engines", 0)),
		"SLOT CELLS %d" % _slot_cell_count(active),
	]
	return " · ".join(parts)


func _repair_summary(profile: ProfileScript, active: StringName) -> String:
	if profile == null or active == &"":
		return ALL_NOMINAL
	var fee := int(RepairsService.fee(profile, active))
	if fee <= 0:
		return ALL_NOMINAL
	return REPAIR_AVAILABLE % Catalog.group_int(fee)


func _refresh_services() -> void:
	var profile := _profile()
	var contracts := 0
	var insured := false
	var vault_units := 0
	if profile != null:
		contracts = mini(int((profile.call(&"contracts") as Array).size()), CONTRACTS_MAX)
		insured = bool(profile.call(&"insured"))
		vault_units = _vault_units(profile)
	if _service_reads.has(&"contracts"):
		(_service_reads[&"contracts"] as Label).text = CONTRACTS_FORMAT % contracts
	if _service_reads.has(&"insurance"):
		(_service_reads[&"insurance"] as Label).text = INSURED_TEXT if insured else UNINSURED_TEXT
	if _service_reads.has(&"vaults"):
		(_service_reads[&"vaults"] as Label).text = VAULT_FORMAT % [vault_units, VAULT_BASE_CAPACITY]
	_apply_service_availability(profile)


## STATION_HUB section 15.1 U2 / 14's 2026-10-08 block: a service the docked station's
## matrix does not carry keeps its label and goes `button_disabled`, and its readout cell
## carries the section 1 / section 8 reason caption in `text_dim` - the label plus the
## disabled plate is the state, never colour alone. A place the registry cannot resolve
## leaves every row exactly as shipped. A5.5 (UI_SPEC section 12.5): the caption is N31's
## in-place content swap in the pinned 76-tall row, so the row box, the chip and the
## caption's own line box never move - only the text and its colour.
func _apply_service_availability(profile: ProfileScript) -> void:
	var station := StationRegistryScript.docked_station(profile)
	for service: Dictionary in SERVICE_ROWS:
		var key: StringName = service[&"key"]
		if not _service_rows.has(key) or not _service_reads.has(key):
			continue
		var available := station.is_empty() or StationRegistryScript.offers(station, key)
		(_service_rows[key] as Button).disabled = not available
		(_service_chips[key] as Button).disabled = not available
		var read := _service_reads[key] as Label
		var name_label := _service_names[key] as Label
		var reason := "" if available else StationRegistryScript.service_reason(station, key)
		if reason.is_empty():
			read.remove_theme_color_override(&"font_color")
			name_label.remove_theme_color_override(&"font_color")
			continue
		read.text = reason
		read.add_theme_color_override(&"font_color", _token(&"text_dim"))
		name_label.add_theme_color_override(&"font_color", _token(&"text_dim"))


## The docked station's own vault record (14 section 9's `station_id -> {tier, contents}`):
## the place's record alone, never the sum of every station (14's 2026-10-08 block gives the
## seam that resolves the id). No place, no record and no contents all read 0.
func _vault_units(profile: ProfileScript) -> int:
	if profile == null:
		return 0
	var vaults: Variant = profile.call(&"vaults")
	if not vaults is Dictionary:
		return 0
	var station_id := StationRegistryScript.docked_station_id(profile)
	if station_id == &"":
		return 0
	var record: Variant = (vaults as Dictionary).get(String(station_id), {})
	if not record is Dictionary:
		return 0
	var contents: Variant = (record as Dictionary).get(&"contents", {})
	if not contents is Dictionary:
		return 0
	var total := 0
	for value: Variant in (contents as Dictionary).values():
		total += int(value)
	return total


func _apply_tokens() -> void:
	var faction := _identity_faction if not _identity_faction.is_empty() else _docked_faction()
	if _identity_plate != null:
		var border := _token(&"metal_mid")
		if faction == &"meridian":
			border = _token(&"metal_light")
		elif faction == &"choir":
			border = _token(&"metal_dark")
		var base := get_theme_stylebox(&"panel", &"PanelContainer")
		if base is StyleBoxFlat:
			var box := (base as StyleBoxFlat).duplicate() as StyleBoxFlat
			box.border_color = border
			_identity_plate.add_theme_stylebox_override(&"panel", box)
	if _pane_icon != null and _pane_icon.texture == null:
		_pane_icon.texture = load(_overview_icon())


func _slot_cell_count(hull_id: StringName) -> int:
	var cells: Array = ShipFit.grid_cells(hull_id)
	var total := 0
	for cell: Variant in cells:
		if cell is Dictionary:
			total += int((cell as Dictionary).get(&"count", 1))
	return total


func _vitals(profile: ProfileScript, ship_id: StringName) -> Dictionary:
	if profile == null or ship_id == &"":
		return {}
	var raw: Variant = profile.call(&"vitals_of", ship_id)
	return raw if raw is Dictionary else {}


## The two denominators (repairs_panel.gd's own rule): `ShipFit.resolve` for the fit the
## launch would fly, with the catalogue row as the fallback.
func _maxima(profile: ProfileScript, ship_id: StringName, ship: Dictionary) -> Dictionary:
	var fallback := {
		&"hull": int(ship.get(&"hull", 0)),
		&"shield": int(ship.get(&"shield", 0)),
	}
	if profile == null or ship.is_empty():
		return fallback
	var stored: Variant = profile.call(&"resolved_fit", ship_id)
	if not stored is Dictionary:
		return fallback
	var fit: Dictionary = profile.call(&"base_fit", stored as Dictionary)
	var summary: Variant = {}
	if profile.has_method(&"affix_summary"):
		summary = profile.call(&"affix_summary", ship_id)
	var stats: ShipStats = ShipFit.resolve(ship_id, fit, summary if summary is Dictionary else {})
	if stats == null:
		return fallback
	return {&"hull": int(round(stats.hull_max)), &"shield": int(round(stats.shield_max))}


func _active_ship(profile: ProfileScript) -> StringName:
	if profile == null:
		return &""
	return StringName(profile.call(&"active_ship"))


func _docked_faction() -> StringName:
	var profile := _profile()
	if profile == null:
		return &""
	if profile.has_method(&"docked_faction"):
		var faction := StringName(profile.call(&"docked_faction"))
		if not faction.is_empty():
			return faction
	## The same S30 dead branch `ui/screens/station.gd:_docked_faction` carried - it probed
	## the profile for a method named `n`, which exists nowhere - is deleted here too; the
	## docked station row's own owner answers instead. Reversal: restore the two lines.
	return StringName(
		StationRegistryScript.docked_station(profile).get(&"faction", &"")
	)


func _profile() -> ProfileScript:
	if not is_inside_tree():
		return null
	var service := get_tree().root.get_node_or_null(NodePath(PROFILE_SERVICE))
	if service == null:
		return null
	var profile: ProfileScript = service
	return profile


func _token(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.WHITE


## A code-drawn chevron mark (P30) inside its own child rect (A5.2(iii)).
class Chevron extends Control:
	var colour: Color = Color.WHITE

	func _draw() -> void:
		var points := PackedVector2Array([
			Vector2(size.x * 0.35, size.y * 0.20),
			Vector2(size.x * 0.65, size.y * 0.50),
			Vector2(size.x * 0.35, size.y * 0.80),
		])
		draw_polyline(points, colour, 2.0, true)
