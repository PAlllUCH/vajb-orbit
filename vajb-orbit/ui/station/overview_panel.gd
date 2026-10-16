extends VBoxContainer
## OVERVIEW pane (S42, STATION_HUB section 23.1 P44-P47 + section 19): the landing pane on
## dock, wearing P7's one skeleton (PaneHeader / content split / foot band). Its split
## carries P46's four blocks as one stack inside a vertical `ScrollContainer` (P22, kept
## as the expand-aspect safety): the identity plate (section 15 treatment), P44's 3x3
## tile grid, the active hull and repair summary (P24) and one flavour line (P27). The
## P25 service rows retired into the grid as tiles (P44); the three service tiles
## deep-link to the SERVICES pane with that service's panel showing (P46).
##
## Contract: STATION_HUB section 23.1 (P44-P47) and section 19.2 (P23's tile interior and
## states), UI_SPEC section 3.10 A5.1-A5.5 (composition, the flat Tokens box chrome) and
## section 16.1 (the ink law). Tokens only (N29); every glyph is a shipped asset reused at
## its own cut. The pane never routes and never writes the profile: it emits
## `navigate_requested` up and reads the catalogue down.

const TOKENS_TYPE: StringName = &"Tokens"
const ChromeFamily := preload("res://ui/theme/chrome_family.gd")

const Catalog := preload("res://game/station_catalog.gd")
const ShipFit := preload("res://game/ship_fit.gd")
const RepairsService := preload("res://game/repairs.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")
## 14's 2026-10-08 block: the docked place - its service matrix is the service tiles'
## unavailable state (U2, re-seated on the tiles by P46).
const StationRegistryScript := preload("res://game/station_registry.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"

signal status_requested(message: String, danger: bool)
signal inspect_requested(title: String, body: String, danger: bool)
signal navigate_requested(deck: int, hint: StringName)

## P26: the SERVICES pane's own deck index (the three service tiles' deep-link target,
## P46), outside P20's cycle.
const SERVICES := 7

## P44's nine tiles, row-major ARMORY / REFINERY / EXCHANGE then AUCTION / SHIPYARD /
## LAUNCH then CONTRACTS / INSURANCE / VAULTS - the P25 service rows retire into the grid
## as tiles. `deck` is the shell's deck index; the three service tiles carry the
## `service` key P46's deep-link emits. The captions: the five P23 strings verbatim,
## AUCTION's P46 re-cut and the three service captions (P46, PROPOSED). `tinted` is the
## rest-ink branch P47 (T-184) generalized: every glyph joins the tinted set, so no tile
## glyph renders WHITE on the flat box.
const TILES: Array[Dictionary] = [
	{&"deck": 0, &"title": "ARMORY", &"caption": "BUY, FIT AND SWAP MODULES", &"icon": "res://assets/icons/equip/icon_equip_module.png", &"tinted": true},
	{&"deck": 1, &"title": "REFINERY", &"caption": "3 ORE = 1 INGOT", &"icon": "res://assets/icons/cargo/icon_cargo_ore.svg", &"tinted": true},
	{&"deck": 2, &"title": "EXCHANGE", &"caption": "SELL YOUR HOLD", &"icon": "res://assets/icons/cargo/icon_credits.svg", &"tinted": true},
	{&"deck": 3, &"title": "AUCTION", &"caption": "THE 20-MINUTE SHELF", &"icon": "res://assets/icons/cargo/icon_credits.svg", &"tinted": true},
	{&"deck": 4, &"title": "SHIPYARD", &"caption": "HULLS, MODULES AND REPAIRS", &"icon": "res://assets/icons/hud/icon_hull.svg", &"tinted": true},
	{&"deck": 5, &"title": "LAUNCH", &"caption": "BRIEF, CARGO, UNDOCK", &"icon": "res://assets/icons/map/icon_map_route.png", &"tinted": true},
	{&"deck": SERVICES, &"service": &"contracts", &"title": "CONTRACTS", &"caption": "JOBS · ESCROW · STANDING", &"icon": "res://assets/icons/contract/icon_contract_haul.svg", &"tinted": true},
	{&"deck": SERVICES, &"service": &"insurance", &"title": "INSURANCE", &"caption": "COVERS ONE LOSS", &"icon": "res://assets/icons/service/icon_service_insurance.svg", &"tinted": true},
	{&"deck": SERVICES, &"service": &"vaults", &"title": "VAULTS", &"caption": "STAYS BEHIND WHEN YOU FLY", &"icon": "res://assets/icons/service/icon_service_vault.svg", &"tinted": true},
]

## P44's own numbers: three 240x120 tiles plus two 16 px separations seat 752 (the pin's
## arithmetic); the P23 interior numbers stand unchanged.
const TILE_MIN := Vector2(240.0, 120.0)
const TILE_COLUMNS := 3
const TILE_SEPARATION := 16
const TILE_MARGIN := 16
const GLYPH_SIZE := 48.0
const CHIP_SIZE := Vector2(96.0, 32.0)
const CAPTION_ACTIVE_HULL := "ACTIVE HULL"
const META_FORMAT := "%s CLASS · %d HULL · %d SLOTS"
const REPAIR_AVAILABLE := "REPAIR AVAILABLE · %s CR"
const ALL_NOMINAL := "ALL SYSTEMS NOMINAL"
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
var _tile_glyphs: Array[TextureRect] = []
## The three service tiles' seats (P46's deep-link emitters, U2's disabled state), keyed
## by the registry's service id.
var _service_tiles: Dictionary = {}
var _identity_faction: StringName = &""


func _ready() -> void:
	_pane_icon.custom_minimum_size = Vector2(40.0, 40.0)
	_pane_icon.texture = load(_overview_icon())
	_build_identity()
	_build_tiles()
	_build_hull_block()
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
## faction glyph 48 at its own cut and the station name.
##
## S41 (D23-R1 F1): the shell header (`station.gd`'s `_apply_identity`) already renders the
## station name AND its character line, and the pane's copy repeated both ~200 px below it
## in a block that was tall enough to push two of the three deep-link rows under the fold.
## The plate keeps the identity it owns - the faction mark and the name - and drops the
## duplicated character line, which is the block's one line. Reversal: restore the
## `_identity_character` label under the name (the shell keeps passing the line in).
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
	## S41 (F1): the character line is not built - the shell header carries it. The field
	## stays null so `set_identity`'s own guard skips it (reversal: build the label again).
	_identity_character = null


## Block 2: P44's 3x3 tile grid - one GridContainer, columns 3, separation 16, nine tiles
## row-major, the deck's whole deep-link set (P46). A tile seats at its own (240, 120)
## minimum (P44's arithmetic) and never expands into the pane's slack.
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
	## Developer bucket-1 at the S42 close-out (disclosed): P23's tiles expand to fill
	## the pane's width (the D19 tile look — the drawn ~570-wide tile P45's reversal row
	## itself cites), so TILE_MIN (240, 120) is the floor the pin says it is, not the
	## seat. Reversal: drop the flag and the tiles hug the 752-px minimum, stranding
	## ~1000 px of the 1756-px content box.
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
	## P47 (T-184): the rest ink is the caption tone and the hover ink is `text_primary` -
	## every glyph joins the tinted set (S42-R0/F2: the branch's WHITE arm dropped; the
	## `tinted` key stays the census's own data).
	glyph.modulate = _token(&"text_caption")
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
	var key: StringName = tile_data.get(&"service", &"")
	if not String(key).is_empty():
		_service_tiles[key] = {&"button": button, &"caption": caption}
	button.pressed.connect(_on_tile_pressed.bind(tile_data))
	button.mouse_entered.connect(_on_tile_hover.bind(button, glyph, String(tile_data[&"title"]), String(tile_data[&"caption"])))
	button.mouse_exited.connect(_on_tile_unhover.bind(button, glyph))
	return button


## P45: the tile chrome is the flat Tokens box at rest - `_flat()`'s own shape, the
## `void_panel` fill and the 1 px `metal_mid` border (UI_SPEC section 3.10 A5.1/A5.4) -
## the same box the identity block wears; the C1 canvas retires with the slab's
## re-presentation row. The states stay P23's own theme boxes: the `button_hover` bevel,
## the `button_pressed` stylebox, the `button_disabled` plate and UI_SPEC section 8 P3's
## 1 px `accent_danger_bright` focus ring - no state changes any box.
func _apply_tile_chrome(button: Button) -> void:
	var flat := StyleBoxFlat.new()
	flat.bg_color = _token(&"void_panel")
	flat.border_color = _token(&"metal_mid")
	flat.set_border_width_all(1)
	flat.set_corner_radius_all(0)
	button.add_theme_stylebox_override(&"normal", flat)
	for state: StringName in [&"hover", &"pressed", &"disabled", &"focus"]:
		var box := get_theme_stylebox(state, &"Button")
		if box != null:
			button.add_theme_stylebox_override(state, box)


func _on_tile_pressed(tile_data: Dictionary) -> void:
	var hint: StringName = tile_data.get(&"service", &"")
	navigate_requested.emit(int(tile_data[&"deck"]), hint)


## P23's hover state (A5.5 legal): the glyph brightens; a disabled service tile keeps its
## rest ink. Hover also publishes the tile's own description on the chain (P21).
func _on_tile_hover(button: Button, glyph: TextureRect, title: String, caption: String) -> void:
	if button.button_pressed or button.disabled:
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
	left.add_theme_constant_override(&"separation", 4)
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


## Block 4: one flavour line (P27).
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
	_apply_service_availability()


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
		"CARGO %d / %d" % [profile.cargo_used(), int(maxima.get(&"cargo_max", int(ship.get(&"cargo", 0))))],
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


## STATION_HUB section 15.1 U2, re-seated on the tiles by P46: a service the docked
## station's matrix does not carry keeps its label and goes `button_disabled`, and the
## tile's caption line carries the registry's reason in `text_dim` - the label plus the
## disabled plate is the state, never colour alone. A place the registry cannot resolve
## leaves every tile exactly as shipped. A5.5 (UI_SPEC section 12.5): the reason is an
## in-place content swap on the caption's own line, so no box moves.
func _apply_service_availability() -> void:
	var profile := _profile()
	var station := StationRegistryScript.docked_station(profile)
	for tile_data: Dictionary in TILES:
		var key: StringName = tile_data.get(&"service", &"")
		if String(key).is_empty():
			continue
		var seat: Dictionary = _service_tiles.get(key, {})
		if seat.is_empty():
			continue
		var available: bool = station.is_empty() or StationRegistryScript.offers(station, key)
		var button: Button = seat[&"button"]
		var caption := seat[&"caption"] as Label
		button.disabled = not available
		if available:
			caption.text = String(tile_data[&"caption"])
			caption.remove_theme_color_override(&"font_color")
			continue
		caption.text = StationRegistryScript.service_reason(station, key)
		caption.add_theme_color_override(&"font_color", _token(&"text_dim"))


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
	return {&"hull": int(round(stats.hull_max)), &"shield": int(round(stats.shield_max)), &"cargo_max": int(stats.cargo_max)}


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
