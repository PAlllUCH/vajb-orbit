extends VBoxContainer
## SHIPYARD module panel: the hangar. The list holds **owned hulls only** -- one row per
## owned ship, its name, its class and the `ACTIVE` badge -- and selecting a row **previews**
## it (side render, comparison stats, its own fit grid) without writing anything; the
## footer `SET ACTIVE` button is the sole commit. Buying a hull happens on the AUCTION's
## shelf only (10 section 2.1). Every value is a StationCatalog, PlayerProfile, ShipFit or
## ModuleCatalog read. Contract: docs/design/STATION_HUB.md sections 5.2 (incl. the
## 2026-09-21 P2-A, 2026-09-22 P2-B and 2026-09-23 S5 amendments), 5.6, 5.11, 7.2 and 12,
## docs/design/STATION_SPEC.md sections 2.4 and 6, docs/gameplay/10_ship_acquisition.md
## sections 2.4 and 6.1, CONTRACTS sections 11 and 17.
##
## The slot layout grid (`%HardpointSlots`) is rebuilt per selection from the selected
## hull's own 08 section 3.2 matrix: one cell per matrix cell, `columns` = the matrix
## width, a gap an empty cell and a slot cell a disabled 48 px plate carrying that type's
## slot glyph. The caption and the ENGINES / SLOT CELLS rows read `ShipFit` for the same
## hull, so the whole stat column moves with the selection and no count is restated here.
## A plate also answers the pointer: hovering one publishes the fitting surface's own line
## (`<TYPE><n> · <MODULE NAME or EMPTY> · OWNED ×<n>`) into the shell's strip, read from the
## selected hull's `fit_for` entry and `module_count` - the grid stays a display, and the
## plate's size, glyph, separation and caption do not move for it (section 5.2's amendment).
##
## The station shell loads this scene into its host, so the panel never routes, never
## writes the profile except through the one `set_active_ship` the footer commits, and never
## draws the credits readout: it emits status_requested up and reads StationCatalog /
## PlayerProfile down (STATION_HUB section 12.4).
##
## Panel contract with the shell:
##   signal status_requested(message: String, danger: bool)   write the footer strip
##   func refresh_profile(key: StringName) -> void             react to profile_changed
##   func focus_primary() -> void                              focus entry after a switch

const TOKENS_TYPE: StringName = &"Tokens"
const ChromeFamily := preload("res://ui/theme/chrome_family.gd")

const Catalog := preload("res://game/station_catalog.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")
## 15 section 7's naming grammar has one builder (`Auction.rolled_name`); the hover line and
## the stat block below the grid call it rather than growing a second copy (K2's deviation 7).
const AuctionScript := preload("res://game/auction.gd")
## P5 (STATION_HUB section 17.2): the repair block reads `repairs_panel.gd:74-89`'s own
## `REPORT_ROWS` (minus the `MISSING` and `FEE` body rows) and its wordings verbatim, the
## cite the law names - one home for the damage table's shapes, the file the HUD's own
## `hull_render` reads too.
const RepairsPanelScript := preload("res://ui/station/repairs_panel.gd")
const RepairsService := preload("res://game/repairs.gd")
## S27 (10 section 3): the shipyard build path the BUILD / QUEUE / SCRAP views drive.
const ShipyardScript := preload("res://game/shipyard.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"

signal status_requested(message: String, danger: bool)
## CONTRACTS section 23.1: emitted when the pointer lands on or leaves a hull row (the
## pane's catalogue item). `title` is the row's identity line, `body` its catalogue
## description (empty when the row carries none), `danger` colours the title.
## `title == ""` clears the shell's inspector block.
## S30 (UI_SPEC section 12.2, P21): the shell's sink for this signal is the N27 tooltip.
signal inspect_requested(title: String, body: String, danger: bool)
## S30 (UI_SPEC section 12.3, N28/P21): the explicit sink. A row's own INSPECT chip (or
## `station_inspect` on the focused row) publishes the sheet's payload here; the shell opens
## the N28 sheet from it. Rows appear only where the data carries them (N35).
signal sheet_requested(payload: Dictionary)

const ROW_HEIGHT := 76.0
const COL_TAG := 130.0
const COL_STAT := 110.0
const ROW_INNER_MARGIN := Vector2i(12, 8)
const COLUMN_SEPARATION := 12
const CELL_SEPARATION := 2
const PULSE_MIN_ALPHA := 0.35
const PULSE_DOWN_SECONDS := 0.12
const PULSE_UP_SECONDS := 0.16

const PLATE_VARIATION: StringName = &"SlotButtonWeapon"
const PLATE_SIZE := 48.0
const PLATE_SEPARATION := 4
## ui/components/slot_button.tscn insets its glyph 6 px inside the 48 px plate; the
## layout grid reuses that one number rather than inventing a second inset.
const PLATE_ICON_INSET := 6.0

## 09 section 1's slot glyph per slot-type key. The glyph files are named by the
## document's own stems (`icon_slot_engine`, `icon_slot_power`, `icon_slot_w`, ...),
## which are not the API's key names, so the mapping is stated once here.
const SLOT_GLYPHS: Dictionary = {
	&"engines": "engine",
	&"power": "power",
	&"weapons": "w",
	&"shields": "s",
	&"armour": "h",
	&"computers": "c",
	&"boosters": "b",
	&"utility": "u",
}
const SLOT_GLYPH_DIR := "res://assets/icons/slot/"
const SLOT_GLYPH_TEMPLATE := "icon_slot_%s.svg"

const PREVIEW_SCALE := 0.70
const PREVIEW_MAX_WIDTH := 480.0
## S30 census row 3 (UI_SPEC section 12.5): the preview image keeps one pinned box and the
## hull scales inside it (a texture swap in a fixed box is legal; resizing the node on
## selection is not). S41 (D23 F10): the box is a fixed fraction of `PreviewFrame`'s own
## size, re-pinned whenever the frame is laid out, so the hull owns the frame instead of
## sitting in a 240 x 180 island inside it. PROPOSED 0.60 (the audit's "about 60 % of the
## box"), reversal: the shipped 240 x 180 pin at `PREVIEW_BOX`.
const PREVIEW_FRACTION := 0.60
## The pre-layout floor (the shipped S30 pin, 08 section 3's side-view envelope at
## `PREVIEW_SCALE`): the box is never smaller than this, and a laid-out frame widens it.
const PREVIEW_BOX := Vector2(240.0, 180.0)

## CONTRACTS section 11: `hull`, `shield` and `cargo` are catalogue fields; `engines`
## and `slots` are the hull's 08 section 3 counts, read through `ShipFit` (see
## `_stat_value`). No catalogue row carries them.
const STAT_ROWS: Array[Dictionary] = [
	{&"key": &"hull", &"label": "HULL"},
	{&"key": &"shield", &"label": "SHIELD"},
	{&"key": &"cargo", &"label": "CARGO"},
	{&"key": &"engines", &"label": "ENGINES"},
	{&"key": &"slots", &"label": "SLOT CELLS"},
]
const COMPARISON_CAPTION := "COMPARISON"
const COMPARISON_SELECTED := "SELECTED"
const COMPARISON_ACTIVE := "ACTIVE"
## A7 (D17-P2's own fix: "show + / - deltas"): the comparison's third column. PROPOSED
## format `%+d` (`+150` / `+0` / `-40`), reversal: the two shipped columns alone.
const COMPARISON_DELTA := "DELTA"
const DELTA_FORMAT := "%+d"
## P12/P13 (section 17.5): the installed-modules caption and the intact-row word.
const INSTALLED_CAPTION := "INSTALLED MODULES"
const ROW_NOMINAL := "NOMINAL"
## The repair block's body rows: section 17.2's own slice of `repairs_panel.gd:74-89`'s
## REPORT_ROWS - `MISSING` and `FEE` never reach the body (the fee lives in the footer line).
const REPAIR_VALUE_FORMAT := "%s / %s"
const DAMAGE_CONTEXT := "POOL %s / %s"
const ACTION_REPAIR := "REPAIR"
const REPAIR_ROW_SEPARATION := 6

const SUBTITLE := "YOUR HULLS · %d IN THE HANGAR · SIDE VIEWS ONLY"
const TAG_ACTIVE_HULL := "ACTIVE HULL %s"

## S27 (10 section 3): the SHIPYARD pane's four views beside the hangar. The mode strip
## swaps `ShipyardBody` for one of the three new views; every value is a `Shipyard`,
## `MineralCatalog`, `ComponentCatalog` or `ModuleCatalog` read.
const MODE_HANGAR := "hangar"
const MODE_BUILD := "build"
const MODE_QUEUE := "queue"
const MODE_SCRAP := "scrap"
const BUILD_HULL_FORMAT := "%s · %d CR TO BUY · %d CR TO BUILD"
const BUILD_MODULE_FORMAT := "%s · %d CR LIST · %d CR TO BUILD"
const BUILD_ACTION := "BUILD"
const BUILD_REFUSED := "BUILD REFUSED · MISSING MATERIALS OR CREDITS"
const BUILD_QUEUED := "QUEUED · %s"
const QUEUE_IDLE := "NO BUILD IN PROGRESS · ONE BUILD AT A TIME (10 §3.3)"
const QUEUE_RUNNING := "IN PROGRESS · %s\nREADY WHEN YOU RETURN FROM YOUR NEXT FLIGHT"
const QUEUE_READY := "READY · %s\nCOLLECT TO DELIVER IT TO THE STATION"
const QUEUE_CANCELLED := "BUILD CANCELLED · MATERIALS AND LABOUR REFUNDED"
const SCRAP_ACTION := "SCRAP"
const SCRAP_ROW_FORMAT := "%s · %d CR OF MATERIALS"
const SCRAP_EMPTY := "NO HULL TO BREAK DOWN"
## Section 5.11's row: the name, the class and the `ACTIVE` badge, no icon (none ships).
## The class is `ShipFit.HULLS`' own `ship_class` column, the value the AUCTION's hull rows
## render as `%s CLASS` too.
const META_FORMAT := "%s CLASS · %d HULL · %d SLOTS"
## CONTRACTS section 11's caption: the hull's slot count (08 section 3's Total, gaps
## excluded) and its ENGINE count. The node is still `%HardpointCaption`.
const HARDPOINT_CAPTION := "SLOT LAYOUT · %d CELLS · %d ENGINES"
## STATION_HUB section 5.2's 2026-09-22 amendment (owner request 1): a slot plate reads the
## fitting surface's own line on hover, `<TYPE><n> · <MODULE NAME or EMPTY> · OWNED ×<n>`,
## resolved from the selected hull's `fit_for` entry and the account's `module_count`. The grid
## stays a display - the plate is still disabled, carries no focus ring and mutates nothing -
## and the plate's size, its glyph, its separation and the caption above do not move.
const HOVER_FORMAT := "%s%d · %s · OWNED ×%d"
const HOVER_EMPTY := "EMPTY"
## The stat block the S3 amendment adds under the grid while a filled cell is hovered: 15
## section 7's two-line block (the base module's catalogue stats plus one line per rolled
## affix), built in script so the frozen scene file needs no new node.
const HOVER_BLOCK_SEPARATOR := "\n"
const HOVER_STAT_JOIN := " · "
const HOVER_BASE_FORMAT := "BASE DRAW %d"
const HOVER_ADD_SUFFIX := " ADD"
const HOVER_MULT_SUFFIX := " MULT"
const HOVER_MULTIPLIER := "×"
## `power` is one id, not a set of cells (CONTRACTS section 11 rule 1).
const POWER_SLOT: StringName = &"power"
const PRICE_ZERO := "0"

const STATE_ACTIVE := "ACTIVE"

const ACTION_IN_SERVICE := "IN SERVICE"
## The footer's one commit and the pane's only write (section 5.11: "the footer SET ACTIVE
## is the sole commit"; CONTRACTS section 17).
const ACTION_SET_ACTIVE := "SET ACTIVE"

const PREVIEW_EMPTY := "NO HULL IN THE CRADLE"
const EMPTY_HULLS := "NO HULLS OWNED"
const STATUS_HINT := "ENTER PREVIEWS · %s · %s CLASS"
## CONTRACTS section 23.1: the inspector's own identity line - the same name and class
## phrase as `STATUS_HINT`, joined by the pane's own separator, with the leading key-hint
## verb dropped so the always-visible title is the hull, not the action.
const INSPECT_TITLE_FORMAT := "%s · %s CLASS"
const STATUS_ACTIVE := "ACTIVE HULL IS NOW %s"

@onready var _subtitle: Label = %PaneSubtitle
@onready var _tag: Label = %PanelTag
@onready var _pane_icon: TextureRect = %PaneIcon
@onready var _list: VBoxContainer = %ShipList
@onready var _preview_caption: Label = %PreviewCaption
@onready var _preview_image: TextureRect = %PreviewImage
@onready var _preview_frame: PanelContainer = %PreviewFrame
@onready var _preview_name: Label = %PreviewName
@onready var _stats: VBoxContainer = %ShipStats
@onready var _hardpoint_caption: Label = %HardpointCaption
@onready var _hardpoints: GridContainer = %HardpointSlots
@onready var _repair_rows: VBoxContainer = %RepairRows
@onready var _repair_footer: Label = %RepairFooter
@onready var _repair_button: Button = %RepairButton
@onready var _action: Button = %ShipAction
@onready var _mode_hangar: Button = %ModeHangar
@onready var _mode_build: Button = %ModeBuild
@onready var _mode_queue: Button = %ModeQueue
@onready var _mode_scrap: Button = %ModeScrap
@onready var _hangar_body: Control = $ShipyardBody
@onready var _build_view: Control = %BuildView
@onready var _build_list: VBoxContainer = %BuildList
@onready var _build_footer: Label = %BuildFooter
@onready var _queue_view: Control = %QueueView
@onready var _queue_body: Label = %QueueBody
@onready var _queue_collect: Button = %QueueCollect
@onready var _queue_cancel: Button = %QueueCancel
@onready var _scrap_view: Control = %ScrapView
@onready var _scrap_list: VBoxContainer = %ScrapList
@onready var _scrap_footer: Label = %ScrapFooter

var _mode := MODE_HANGAR

var _payloads: Array[Dictionary] = []
var _stat_cells: Dictionary = {}
var _selected_id: StringName = &""
var _selected_row: Button = null
var _tweens: Array[Tween] = []
## S30 (UI_SPEC section 12.5 row 1, N30): the hovered cell's stat block text. The in-flow
## `HoverStatBlock` label is deleted; its bytes now ride the N27 tooltip's body and are
## tracked here for probes.
var _hover_block_text: String = ""
## The cell under the pointer and the grid's cluster chip (N37), so the chip knows whether
## it has a target to inspect.
var _hovered_cell: Dictionary = {}
## The payload the focused hull row carries, for `station_inspect` (N34).
var _focused_payload: Dictionary = {}
## The repair block's row labels: `{key, label, value, state, row}` for the seven body rows
## (ACTIVE HULL/HULL/SHIELD + the four armour quadrants, 09 section 3.3 P2's order).
var _repair_values: Array[Dictionary] = []
## The comparison's per-row delta labels, keyed by stat key.
var _delta_cells: Dictionary = {}


## S30-F1 (F6, UI_SPEC section 12.5 row 16): the hull whose slot matrix is already laid
## out. The grid is rebuilt for a **selection command** only; a focus move that lands on
## the hull already on the grid (the shell's `focus_primary` on every switch, a focus
## return from the sheet) never touches the tree.
var _grid_hull: StringName = &""
var _grid_built := false


func _ready() -> void:
	_build_comparison()
	_build_layout_grid()
	_build_repair_rows()
	_build_rows()
	_pin_preview_box()
	_apply_tokens()
	## S36 (UI_SPEC section 15.1): the two pane action bars wear C2 `ui_action_bar`.
	ChromeFamily.apply_action(_action)
	ChromeFamily.apply_action(_repair_button)
	_action.pressed.connect(_on_action_pressed)
	_repair_button.pressed.connect(_on_repair_pressed)
	## S27 (10 section 3): the mode strip and the build path's actions.
	_mode_hangar.pressed.connect(_set_mode.bind(MODE_HANGAR))
	_mode_build.pressed.connect(_set_mode.bind(MODE_BUILD))
	_mode_queue.pressed.connect(_set_mode.bind(MODE_QUEUE))
	_mode_scrap.pressed.connect(_set_mode.bind(MODE_SCRAP))
	_queue_collect.pressed.connect(_on_queue_collect)
	_queue_cancel.pressed.connect(_on_queue_cancel)
	## S41 (D23 F15): the four mode plates wear the chip family's own C3 `ui_inline_chip`
	## chrome (the height/ink half lives in the scene), so mode, filter and service read
	## as one family while each keeps its own count.
	ChromeFamily.apply_chip(_mode_hangar)
	ChromeFamily.apply_chip(_mode_build)
	ChromeFamily.apply_chip(_mode_queue)
	ChromeFamily.apply_chip(_mode_scrap)
	ChromeFamily.apply_action(_queue_collect)
	ChromeFamily.apply_action(_queue_cancel)
	_refresh_all()
	_set_mode(_mode)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_apply_tokens()
		_refresh_plate_textures()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and is_node_ready() and is_visible_in_tree():
		## P6 is retired with the inspector band (STATION_HUB section 18's ledger), so a
		## pane show publishes the chain's clear - never a fill that would re-arm the N27
		## tooltip (S30-F1, F5: the tooltip opens on a real hover only).
		_refresh_all()
		inspect_requested.emit("", "", false)


func _exit_tree() -> void:
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()


func refresh_profile(key: StringName) -> void:
	## STATION_HUB section 12.4: &"credits" moves the tags and the action label, &"ships"
	## moves the owned list, the active hull and the comparison column. The list is the
	## **owned** roster now (section 5.11), so a hull bought on the AUCTION makes this pane
	## rebuild its rows - and the profile emits from inside `buy_ship`/`set_active_ship`, so
	## the rebuild is a fresh row set rather than an edit of the rows a press may still have
	## on the stack (the AUCTION pane's own rule).
	if key == &"credits" or key == &"ships":
		if not _sync_rows():
			_refresh_all()
	## S27 (10 section 3): a hold or a queue write redraws the build path's views.
	if key == &"credits" or key == &"cargo" or key == &"ships" or key == &"shipyard":
		_refresh_views()


## Rebuilds the rows when the account's owned roster moved since they were built, and
## answers whether it did. The roster is compared in the catalogue's ladder order, so a
## purchase order (or a re-set of the same account) never reads as a change.
func _sync_rows() -> bool:
	var roster := _owned_roster(_profile())
	if roster == _built_ids():
		return false
	_build_rows()
	_refresh_all()
	return true


## The ids of the rows the pane currently carries, in render order.
func _built_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for payload: Dictionary in _payloads:
		ids.append(payload[&"id"])
	return ids


func focus_primary() -> void:
	for payload: Dictionary in _payloads:
		var row: Button = payload[&"row"]
		if not row.disabled:
			row.grab_focus()
			return
	if not _action.disabled:
		_action.grab_focus()


## P24's deep link (S30): OVERVIEW's `REPAIR` chip lands here - the active hull selected
## and the repair block focused. Reversal: the hull list's first row focused.
func focus_repair() -> void:
	var active := _active_id(_profile())
	var row := row_of(active)
	if row != null and not row.disabled:
		row.grab_focus()
	if not _repair_button.disabled:
		_repair_button.grab_focus()


## The row that carries one owned hull, or null for a hull the account does not own (the
## hangar lists no row for it). Read back for probes and tests, the way the AUCTION pane's
## `row_of` is.
func row_of(ship_id: StringName) -> Button:
	for payload: Dictionary in _payloads:
		if payload[&"id"] == ship_id:
			return payload[&"row"]
	return null


## The ids of the hangar's rows, in render order.
func listed_ids() -> Array[StringName]:
	return _built_ids()


## The hull the preview is showing.
func selected_id() -> StringName:
	return _selected_id


func _apply_tokens() -> void:
	_pane_icon.modulate = _token(&"text_primary")


func _token(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.WHITE


## Section 5.11's hangar list: one row per **owned** hull, in the catalogue's ladder order
## so the list reads the same ladder the AUCTION's shelf does. No row ships for a hull the
## account does not own -- the buy door is the AUCTION's (10 sections 2.1, 6.1).
func _build_rows() -> void:
	_clear(_list)
	_payloads.clear()
	var profile := _profile()
	var roster := _owned_roster(profile)
	_subtitle.text = SUBTITLE % roster.size()
	for ship: Dictionary in Catalog.SHIPS:
		var ship_id: StringName = ship.get(&"id", &"")
		if roster.has(ship_id):
			_payloads.append(_build_row(ship))
	if _payloads.is_empty():
		_list.add_child(_empty_row())
	_add_slack()


## The account's owned hulls in the catalogue's own ladder order.
func _owned_roster(profile: ProfileScript) -> Array[StringName]:
	var roster: Array[StringName] = []
	var owned := _owned_ids(profile)
	for ship: Dictionary in Catalog.SHIPS:
		var ship_id: StringName = ship.get(&"id", &"")
		if owned.has(ship_id):
			roster.append(ship_id)
	return roster


func _clear(rows: VBoxContainer) -> void:
	for child: Node in rows.get_children():
		rows.remove_child(child)
		child.queue_free()


func _empty_row() -> Label:
	var label := _make_label(&"StationCaption", EMPTY_HULLS)
	label.name = "EmptyRow"
	label.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _build_row(ship: Dictionary) -> Dictionary:
	var ship_id: StringName = ship.get(&"id", &"")
	var name_text := String(ship.get(&"name", ""))
	var hull: Dictionary = ShipFit.HULLS.get(ship_id, {})
	var meta := META_FORMAT % [
		String(hull.get(&"ship_class", "")).to_upper(),
		int(ship.get(&"hull", 0)),
		_slot_cell_count(ship_id),
	]
	var row := Button.new()
	row.name = "Ship%s" % String(ship_id).trim_prefix("ship_").to_pascal_case()
	row.toggle_mode = true
	row.focus_mode = Control.FOCUS_ALL
	row.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row.set_meta(&"id", ship_id)
	## S36 (UI_SPEC section 15.1): the hull row wears C4 `ui_row_strip`.
	ChromeFamily.apply_row(row)
	var box := _make_inner(row)
	box.add_child(_make_title_box(name_text, meta))
	var tag := _make_cell(box, COL_TAG, "", "", "Status")
	var payload := {
		&"id": ship_id,
		&"name": name_text,
		&"row": row,
		&"icon": null,
		&"tag": tag[0],
	}
	## N37 rev (owner 2026-10-07): no per-row chip - the station's INSPECT toggle routes the
	## row press to the sheet (`_on_row_pressed`).
	row.pressed.connect(_on_row_pressed.bind(payload))
	row.focus_entered.connect(_on_row_focused.bind(row, payload))
	row.mouse_entered.connect(_on_row_hovered.bind(payload, true))
	row.mouse_exited.connect(_on_row_hovered.bind(payload, false))
	_list.add_child(row)
	return payload


func _make_title_box(name_text: String, meta: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = "TitleBox"
	box.add_theme_constant_override(&"separation", CELL_SEPARATION)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := _make_label(&"StationValue", name_text)
	title.name = "Title"
	box.add_child(title)
	var meta_label := _make_label(&"StationMeta", meta)
	meta_label.name = "Meta"
	box.add_child(meta_label)
	return box


func _make_cell(
	parent: HBoxContainer, width: float, value_text: String, caption_text: String, cell_name: String
) -> Array[Label]:
	var box := VBoxContainer.new()
	box.name = cell_name
	box.custom_minimum_size = Vector2(width, 0.0)
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override(&"separation", CELL_SEPARATION)
	parent.add_child(box)
	var value := _make_label(&"StationValue", value_text)
	value.name = "Value"
	box.add_child(value)
	var caption := _make_label(&"StationCaption", caption_text)
	caption.name = "Caption"
	box.add_child(caption)
	var out: Array[Label] = [value, caption]
	return out


func _make_label(variation: StringName, text: String) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


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
	box.add_theme_constant_override(&"separation", COLUMN_SEPARATION)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(box)
	return box


func _add_slack() -> void:
	var slack := Control.new()
	slack.name = "Slack"
	slack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.add_child(slack)


func _build_comparison() -> void:
	var header := HBoxContainer.new()
	header.name = "ComparisonHeader"
	header.add_theme_constant_override(&"separation", COLUMN_SEPARATION)
	_stats.add_child(header)
	for cell: Dictionary in [
		{&"text": COMPARISON_CAPTION, &"width": 0.0, &"expand": true},
		{&"text": COMPARISON_SELECTED, &"width": COL_STAT, &"expand": false},
		{&"text": COMPARISON_ACTIVE, &"width": COL_STAT, &"expand": false},
		{&"text": COMPARISON_DELTA, &"width": COL_STAT, &"expand": false},
	]:
		header.add_child(_make_header_cell(cell))
	for row: Dictionary in STAT_ROWS:
		var line := HBoxContainer.new()
		line.name = "Stat%s" % String(row[&"key"]).to_pascal_case()
		line.add_theme_constant_override(&"separation", COLUMN_SEPARATION)
		_stats.add_child(line)
		var caption := _make_label(&"StationCaption", String(row[&"label"]))
		caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(caption)
		var selected := _make_stat_value(line)
		var active := _make_stat_value(line)
		active.add_theme_color_override(&"font_color", _token(&"text_dim"))
		var delta := _make_stat_value(line)
		delta.add_theme_color_override(&"font_color", _token(&"text_dim"))
		_delta_cells[row[&"key"]] = delta
		_stat_cells[row[&"key"]] = [selected, active]


func _make_header_cell(cell: Dictionary) -> Control:
	if String(cell[&"text"]).is_empty():
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(float(cell[&"width"]), 0.0)
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return spacer
	var label := Label.new()
	label.theme_type_variation = &"SectionHeader"
	label.text = String(cell[&"text"])
	label.custom_minimum_size = Vector2(float(cell[&"width"]), 0.0)
	label.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL if bool(cell[&"expand"]) else Control.SIZE_FILL
	)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_stat_value(parent: HBoxContainer) -> Label:
	var label := _make_label(&"StationValue", PRICE_ZERO)
	label.custom_minimum_size = Vector2(COL_STAT, 0.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	parent.add_child(label)
	return label


## The grid's separations are set here rather than per rebuild, so one constant drives
## both axes (a GridContainer's `separation` is BoxContainer-only; the HBox the strip
## used to be carried it). The cells themselves come from `_set_layout_grid`.
func _build_layout_grid() -> void:
	_hardpoints.add_theme_constant_override(&"h_separation", PLATE_SEPARATION)
	_hardpoints.add_theme_constant_override(&"v_separation", PLATE_SEPARATION)


## CONTRACTS section 11: one cell per 08 section 3.2 matrix cell of `hull_id`, row-major
## (`ShipFit.grid_cells` order), `columns` = the matrix width. A gap is an empty 48 x 48
## `Control` with no plate; a slot cell is a disabled plate carrying its type's slot
## glyph. The caption reads the same hull, so it can never describe a previous one.
func _set_layout_grid(hull_id: StringName) -> void:
	## S30-F1 (F6, UI_SPEC section 12.5 row 16): a same-hull call is a no-op, so the focus
	## route (`_on_row_focused` -> `_preview_row` -> `_refresh_preview`) never rebuilds the
	## slot matrix for a hull the grid already carries.
	if _grid_built and hull_id == _grid_hull:
		return
	_grid_built = true
	_grid_hull = hull_id
	_clear_hover_block()
	for child: Node in _hardpoints.get_children():
		_hardpoints.remove_child(child)
		child.queue_free()
	var cells: Array = ShipFit.grid_cells(hull_id)
	if cells.is_empty():
		_hardpoints.columns = 1
		_hardpoint_caption.text = ""
		return
	_hardpoints.columns = ShipFit.grid_size(hull_id).x
	var slot_cells := 0
	for cell: Dictionary in cells:
		if bool(cell[&"gap"]):
			_hardpoints.add_child(_make_gap_cell())
		else:
			_make_slot_cell(cell)
			slot_cells += 1
	var engines := int(ShipFit.grid_counts(hull_id).get(&"engines", 0))
	_hardpoint_caption.text = HARDPOINT_CAPTION % [slot_cells, engines]


func _make_gap_cell() -> Control:
	var cell := Control.new()
	cell.name = "Gap"
	cell.custom_minimum_size = Vector2(PLATE_SIZE, PLATE_SIZE)
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return cell


## Display cell for one non-gap matrix cell: the 48 px disabled plate plus its type's slot
## glyph, wired to the section 5.2 amendment's hover line. `_make_plate` parents it (it always
## has), so the caller adds nothing.
func _make_slot_cell(cell: Dictionary) -> void:
	var plate := _make_plate(_hardpoints, PLATE_VARIATION, PLATE_SIZE)
	plate.name = "Slot%s%02d" % [String(cell[&"token"]), int(cell[&"index"])]
	plate.disabled = true
	# The plate stays a display - disabled, no focus ring, no mutation - but it answers the
	# pointer, which is what the section 5.2 amendment's hover line needs (`_make_plate` leaves
	# the filter at IGNORE, and a filter that ignores the mouse never reports a hover).
	plate.mouse_filter = Control.MOUSE_FILTER_STOP
	plate.mouse_entered.connect(_on_plate_hovered.bind(cell))
	plate.mouse_exited.connect(_on_plate_unhovered)
	## N37 rev: in INSPECT mode a click on the display cell opens its sheet (the retired
	## cluster chip's own job).
	plate.gui_input.connect(_on_plate_input.bind(cell))
	var glyph := TextureRect.new()
	glyph.name = "Icon"
	glyph.custom_minimum_size = Vector2(PLATE_SIZE - PLATE_ICON_INSET * 2.0, PLATE_SIZE - PLATE_ICON_INSET * 2.0)
	glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.texture = _slot_glyph(StringName(cell[&"type"]))
	glyph.modulate = _token(&"text_dim")
	plate.add_child(glyph)
	glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glyph.offset_left = PLATE_ICON_INSET
	glyph.offset_top = PLATE_ICON_INSET
	glyph.offset_right = -PLATE_ICON_INSET
	glyph.offset_bottom = -PLATE_ICON_INSET


## 09 section 1's shipped slot glyph for a slot-type key: `icon_slot_<stem>_48.png`.
## Null for a type with no glyph (never one of the eight), so the cell then draws its
## plate alone rather than an error.
func _slot_glyph(slot_key: StringName) -> Texture2D:
	var stem := String(SLOT_GLYPHS.get(slot_key, ""))
	if stem.is_empty():
		return null
	var path := SLOT_GLYPH_DIR + SLOT_GLYPH_TEMPLATE % stem
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


## The hover line for one grid cell (STATION_HUB section 5.2's 2026-09-22 amendment): the
## cell's own type token and layout index, the selected hull's module in that cell - or the
## pin's `EMPTY` - and how many of it the account holds. A hull the account owns reads the fit
## the launch would fly (`resolved_fit`, the profile's own fallback: the stored fit when it
## holds a module, else 09 section 9's `ShipFit.standard_fit`), so the line agrees with the
## FITTING pane's preview and with the ship this hull would launch as; a hull it does not own
## keeps reading `fit_for`, whose all-empty shape answers `EMPTY` for every cell. An instance
## id resolves through the profile's own `base_module_id` bridge, the way the fitting pane
## names its modules; `&""` for a gap, which carries no plate to hover.
##
## STATION_HUB section 5.3's S3 amendment: where the cell holds an instance, the name is 15
## section 7's **full rolled name** (the shared builder) and the `OWNED ×<n>` tail counts the
## base id's held instances, summed over the bag's own keys.
func hover_line(cell: Dictionary) -> String:
	if bool(cell.get(&"gap", false)):
		return ""
	var slot_key: StringName = cell.get(&"type", &"")
	var index := int(cell.get(&"index", -1))
	var entry := _hover_entry(cell)
	if entry == &"":
		return HOVER_FORMAT % [String(cell.get(&"token", "")), index + 1, HOVER_EMPTY, 0]
	var profile := _profile()
	var base := _base_id(profile, entry)
	return HOVER_FORMAT % [
		String(cell.get(&"token", "")),
		index + 1,
		_hover_name(profile, base, entry),
		_owned_total(profile, base),
	]


## The entry the hovered cell holds, `&""` for an empty cell and a gap: the same read the line
## and the block share, so the two can never describe two different cells.
func _hover_entry(cell: Dictionary) -> StringName:
	if bool(cell.get(&"gap", false)):
		return &""
	var profile := _profile()
	if profile == null:
		return &""
	var slot_key: StringName = cell.get(&"type", &"")
	var index := int(cell.get(&"index", -1))
	var read := &"fit_for"
	if _owned_ids(profile).has(_selected_id):
		read = &"resolved_fit"
	return _fit_cell_module(profile.call(read, _selected_id), slot_key, index)


## One module entry's display name: 15 section 7's rolled name through the shared builder when
## the bag carries the record, the catalogue's own name otherwise.
func _hover_name(profile: ProfileScript, base_id: StringName, entry: StringName) -> String:
	var record := _instance_record(profile, entry)
	if not record.is_empty():
		var rolled := String(AuctionScript.rolled_name(record))
		if not rolled.is_empty():
			return rolled
	var name_text := String(ModuleCatalog.module(base_id).get(&"name", ""))
	return name_text if not name_text.is_empty() else String(base_id)


## The record behind one inventory id, `{}` for an id the bag does not carry (a delivered
## module in 09 section 9's standard fit, for one).
func _instance_record(profile: ProfileScript, entry: StringName) -> Dictionary:
	if profile == null or entry == &"":
		return {}
	var record: Variant = profile.call(&"instance", entry)
	if record is Dictionary:
		return record
	return {}


## The base id's held instances, summed over the bag's own keys through `base_module_id`:
## `module_count(base_id)` answers one record's count and reads 0 for an instance-keyed bag
## (K1's measured note), so the aggregate is the sum here, exactly as the FITTING pane sums it.
func _owned_total(profile: ProfileScript, base_id: StringName) -> int:
	var total := 0
	if profile == null or base_id == &"":
		return total
	for key: Variant in profile.call(&"modules"):
		var entry := StringName(str(key))
		var held := int(profile.call(&"module_count", entry))
		if held <= 0:
			continue
		if StringName(profile.call(&"base_module_id", entry)) == base_id:
			total += held
	return total


## The module id one fit cell holds, `&""` for an empty cell and for an index the hull does not
## carry. POWER is one id rather than a set of cells (CONTRACTS section 11 rule 1), so it is
## read as a single value; every other type is the layout-indexed array 09 section 4.5
## describes.
func _fit_cell_module(fit: Dictionary, slot_key: StringName, index: int) -> StringName:
	if slot_key == POWER_SLOT:
		var single: Variant = fit.get(slot_key, fit.get(String(slot_key), ""))
		return StringName(String(single)) if single != null else &""
	var raw: Variant = fit.get(slot_key, fit.get(String(slot_key), []))
	if not raw is Array:
		return &""
	var cells: Array = raw as Array
	if index < 0 or index >= cells.size():
		return &""
	return StringName(String(cells[index]))


## The fit stores a module *instance* id (15 section 6) and the catalogue reads base ids, so
## every id the line names goes through the profile's own bridge.
func _base_id(profile: ProfileScript, entry: StringName) -> StringName:
	if profile == null or entry == &"":
		return entry
	return StringName(profile.call(&"base_module_id", entry))


## ------------------------------------------------------- the hover stat block (15 section 7)
##
## STATION_HUB section 5.3's S3 amendment: a plate that holds an instance shows the rolled name
## in the hover line and the pane adds the instance's stat block - the base module's catalogue
## stats plus one line per rolled affix. **S30 (UI_SPEC section 12.5 row 1, N30): the in-flow
## `HoverStatBlock` label is deleted** - the block's bytes now ride the N27 tooltip's body
## (UI_SPEC section 12.2), so no node is added, moved or made visible on a hover. The text is
## tracked in `_hover_block_text` for probes. The formatter is `fitting_panel.gd`'s,
## byte-equivalently.
func _refresh_hover_block(cell: Dictionary) -> void:
	_hover_block_text = _stat_block_of(_profile(), _hover_entry(cell))


func _clear_hover_block() -> void:
	_hover_block_text = ""
	_hovered_cell = {}


## The block's own text, read back for probes and tests (now the tooltip body's stat half).
func hover_block_text() -> String:
	return _hover_block_text


## S30 census row 3 (UI_SPEC section 12.5): the preview keeps one pinned box and a selection
## swaps the texture inside it (it never sizes the node per selection).
## S41 (D23 F10): the pinned box is `PREVIEW_FRACTION` of `PreviewFrame`'s own size, so the
## hull owns the frame; the frame's own `resized` re-pins it (containers, never coordinates -
## the fraction is relative to the frame).
func _pin_preview_box() -> void:
	_preview_image.custom_minimum_size = PREVIEW_BOX
	_preview_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not _preview_frame.resized.is_connected(_resize_preview_box):
		_preview_frame.resized.connect(_resize_preview_box)
	_resize_preview_box()


func _resize_preview_box() -> void:
	var box := _preview_frame.size * PREVIEW_FRACTION
	if box.x <= 0.0 or box.y <= 0.0:
		return
	_preview_image.custom_minimum_size = box


## ------------------------------------------------- the INSPECT sheet (N28/N37, S30)
## The pane's explicit sink (UI_SPEC section 12.3): `station_inspect` on the focused row /
## hovered cell. The payload carries only the rows the data has (N35).
##
## N37 rev (owner 2026-10-07): the station's one INSPECT toggle. On, a row press opens the
## sheet instead of the preview; the per-row and cluster INSPECT chips are retired.
var _inspect_mode := false


func set_inspect_mode(on: bool) -> void:
	_inspect_mode = on


func _emit_sheet(payload: Dictionary) -> void:
	var sheet := _sheet_payload(payload)
	if not sheet.is_empty():
		sheet_requested.emit(sheet)


## N34's route: inspect whatever the pane holds - the hovered grid cell first, then the
## focused hull row.
func inspect_focused() -> void:
	if not _hovered_cell.is_empty():
		var cell := _cell_sheet_payload(_hovered_cell)
		if not cell.is_empty():
			sheet_requested.emit(cell)
			return
	if _focused_payload.is_empty():
		return
	_emit_sheet(_focused_payload)


func _inspect_hovered_cell() -> void:
	var payload := _cell_sheet_payload(_hovered_cell)
	if not payload.is_empty():
		sheet_requested.emit(payload)


func _on_plate_input(event: InputEvent, cell: Dictionary) -> void:
	if not _inspect_mode:
		return
	if event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			var payload := _cell_sheet_payload(cell)
			if not payload.is_empty():
				sheet_requested.emit(payload)


## A hull's sheet: its own name, the labelled stat pairs (section 17.2), and `OWNED ×1`
## (every shipyard row is an owned hull; a hull keeps row 5 and drops the family row, N35).
func _sheet_payload(payload: Dictionary) -> Dictionary:
	var ship_id: StringName = payload.get(&"id", &"")
	var ship := Catalog.ship(ship_id)
	if ship.is_empty():
		return {}
	var lines := PackedStringArray()
	for stat: Dictionary in STAT_ROWS:
		lines.append("%s %d" % [String(stat[&"label"]), _stat_value(ship, ship_id, stat[&"key"])])
	return {
		&"name": String(payload.get(&"name", "")).to_upper(),
		&"stats": "\n".join(lines),
		&"owned": 1,
	}


## A grid cell's sheet: the rolled name, its affixes and stat block, the module's slot
## family and its held count.
func _cell_sheet_payload(cell: Dictionary) -> Dictionary:
	var entry := _hover_entry(cell)
	if entry == &"":
		return {}
	var profile := _profile()
	var base := _base_id(profile, entry)
	return {
		&"name": _hover_name(profile, base, entry),
		&"affixes": _affix_lines(_instance_record(profile, entry)),
		&"stats": _stat_block_of(profile, entry),
		&"family": String(ModuleCatalog.module(base).get(&"slot", "")).to_upper(),
		&"owned": _owned_total(profile, base),
	}


func _stat_block_of(profile: ProfileScript, entry: StringName) -> String:
	if entry == &"":
		return ""
	var base := _base_id(profile, entry)
	var module_row := ModuleCatalog.module(base)
	if module_row.is_empty():
		return ""
	var lines := PackedStringArray([_base_stats_line(module_row)])
	for line: String in _affix_lines(_instance_record(profile, entry)):
		lines.append(line)
	return HOVER_BLOCK_SEPARATOR.join(lines)


## 15 section 7's first line: the catalogue's own draw and every `effects` entry.
func _base_stats_line(module_row: Dictionary) -> String:
	var parts := PackedStringArray([HOVER_BASE_FORMAT % int(module_row.get(&"draw", 0))])
	var effects: Dictionary = module_row.get(&"effects", {})
	for key: Variant in effects:
		parts.append(stat_line(StringName(str(key)), float(effects[key])))
	return HOVER_STAT_JOIN.join(parts)


## 15 section 7's second line onward: one line per rolled affix, in the record's own order.
func _affix_lines(record: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	if record.is_empty():
		return lines
	for raw: Variant in _rows_of(record.get("prefixes")):
		var id := StringName(str(_row_id_of(raw)))
		var prefix: Variant = ModuleCatalog.PREFIXES.get(id, null)
		if not prefix is Dictionary:
			continue
		var row: Dictionary = prefix
		var value := 0.0
		if raw is Dictionary:
			value = float((raw as Dictionary).get("value", 0.0))
		lines.append(
			String(row.get(&"name", String(id))).to_upper()
			+ HOVER_STAT_JOIN
			+ stat_line(
				StringName(str(row.get(&"stat", &""))), value, StringName(str(row.get(&"unit", &"")))
			)
		)
	for raw: Variant in _rows_of(record.get("suffixes")):
		var id := StringName(str(_row_id_of(raw)))
		var suffix: Variant = ModuleCatalog.SUFFIXES.get(id, null)
		if not suffix is Dictionary:
			continue
		var row: Dictionary = suffix
		lines.append(
			String(row.get(&"name", "of " + String(id))).to_upper()
			+ HOVER_STAT_JOIN
			+ String(row.get(&"perk", ""))
		)
	return lines


## One stat as its display line, `fitting_panel.stat_line`'s own rule: the catalogue's key as
## the label and the value in 15 section 3's unit column, or the unit the magnitude implies.
static func stat_line(
	stat_key: StringName, value: float, unit: StringName = &""
) -> String:
	var key := String(stat_key)
	if key.ends_with("_mult") or key.ends_with("_multiplier"):
		return "%s %s%s" % [stat_label(stat_key), HOVER_MULTIPLIER, String.num(value, 2)]
	var text := ""
	match String(unit):
		"percent":
			text = signed_percent(value)
		"points":
			text = "%+d pp" % int(roundf(value * 100.0))
		"units":
			text = signed_number(value)
		_:
			text = signed_percent(value) if absf(value) < 1.0 else signed_number(value)
	return "%s %s" % [stat_label(stat_key), text]


static func stat_label(stat_key: StringName) -> String:
	var words := String(stat_key).to_upper().replace("_", " ")
	for suffix: String in [HOVER_ADD_SUFFIX, HOVER_MULT_SUFFIX, " MULTIPLIER"]:
		if words.ends_with(suffix):
			return words.substr(0, words.length() - suffix.length())
	return words


static func signed_percent(value: float) -> String:
	return "%+d %%" % int(roundf(value * 100.0))


static func signed_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%+d" % int(roundf(value))
	return "%+.2f" % value


func _rows_of(raw: Variant) -> Array:
	return raw as Array if raw is Array else []


func _row_id_of(raw: Variant) -> String:
	if raw is Dictionary:
		return str((raw as Dictionary).get("id", ""))
	if raw is String or raw is StringName:
		return String(raw)
	return ""


## Hovering a plate publishes its line and the cell's stat block through the existing
## `inspect_requested` chain (S30/UI_SPEC section 12.2, N30: the shell's sink is the N27
## tooltip; the in-flow block and the status write are gone). Leaving it clears the chain
## (S30-F1, F5: P6's band fill is retired), so neither keeps a line for a cell the pointer
## has left and no unhover re-arms the tooltip.
func _on_plate_hovered(cell: Dictionary) -> void:
	_hovered_cell = cell
	_refresh_hover_block(cell)
	inspect_requested.emit(hover_line(cell), _tooltip_body(_hover_entry(cell)), false)


func _on_plate_unhovered() -> void:
	_hovered_cell = {}
	_clear_hover_block()
	## S30-F1 (F5, N33): a leave clears the shell's tooltip payload; it never re-publishes
	## the selection or an idle summary, which would re-arm the delayed tooltip.
	inspect_requested.emit("", "", false)


## UI_SPEC section 12.2's content grammar: the identity line is the title and the body is the
## catalogue description plus the shipped stat block (`_stat_block_of`), which is where N30's
## deleted in-flow blocks' bytes live.
func _tooltip_body(entry: StringName) -> String:
	if entry == &"":
		return ""
	var profile := _profile()
	var parts := PackedStringArray()
	var described := Catalog.describe(_base_id(profile, entry))
	if not described.is_empty():
		parts.append(described)
	var block := _stat_block_of(profile, entry)
	if not block.is_empty():
		parts.append(block)
	return "\n".join(parts)


func _payload(ship_id: StringName) -> Dictionary:
	for payload: Dictionary in _payloads:
		if payload[&"id"] == ship_id:
			return payload
	return {}


## How many non-gap cells the hull carries, which is 08 section 3's Total: every value
## of `ShipFit.grid_counts` (gaps are not counted by the grid at all) summed.
func _slot_cell_count(hull_id: StringName) -> int:
	var total := 0
	for count: Variant in ShipFit.grid_counts(hull_id).values():
		total += int(count)
	return total


## One comparison cell's number: the catalogue's own field, or the hull's 08 section 3
## count for `engines`/`slots` (which no catalogue row carries).
func _stat_value(ship: Dictionary, ship_id: StringName, key: StringName) -> int:
	if key == &"engines":
		return int(ShipFit.grid_counts(ship_id).get(&"engines", 0))
	if key == &"slots":
		return _slot_cell_count(ship_id)
	return int(ship.get(key, 0))


func _make_plate(parent: GridContainer, variation: StringName, plate_size: float) -> TextureButton:
	# ui/components/slot_button.gd copies the theme plate textures onto the node, because a
	# TextureButton has no stylebox items, so SlotButtonWeapon/styles/* is never read by the
	# engine on a bare theme_type_variation. The panel repeats that lookup (the mockup's own
	# construct) so the grid also renders without instancing the HUD component.
	var plate := TextureButton.new()
	plate.theme_type_variation = variation
	plate.ignore_texture_size = true
	plate.custom_minimum_size = Vector2(plate_size, plate_size)
	plate.focus_mode = Control.FOCUS_NONE
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(plate)
	_apply_plate_textures(plate)
	return plate


func _apply_plate_textures(plate: TextureButton) -> void:
	var variation: StringName = plate.theme_type_variation
	plate.texture_normal = _plate_texture(variation, &"normal")
	plate.texture_hover = _plate_texture(variation, &"hover")
	plate.texture_pressed = _plate_texture(variation, &"pressed")
	plate.texture_disabled = _plate_texture(variation, &"disabled")


func _plate_texture(variation: StringName, state: StringName) -> Texture2D:
	if not has_theme_stylebox(state, variation):
		return null
	var box := get_theme_stylebox(state, variation)
	if box is StyleBoxTexture:
		return (box as StyleBoxTexture).texture
	return null


func _refresh_plate_textures() -> void:
	# A gap cell is a bare Control, so the cast filters it out; the plates re-copy the
	# theme's four plate textures on every theme change, as before.
	for child: Node in _hardpoints.get_children():
		var plate := child as TextureButton
		if plate != null:
			_apply_plate_textures(plate)


func _refresh_all() -> void:
	var profile := _profile()
	if _selected_id == &"" or not _owned_ids(profile).has(_selected_id):
		_selected_id = _default_selection(profile)
	_refresh_rows(profile)
	_refresh_preview(profile)
	_refresh_action(profile)
	_refresh_repair(profile)


## Section 5.11's row: the `ACTIVE` badge on the hull the account flies, nothing on any
## other row (every row is an owned hull, so `FOR SALE` and `LOCKED` retired with the buy
## rows).
func _refresh_rows(profile: ProfileScript) -> void:
	var active_id := _active_id(profile)
	_tag.text = TAG_ACTIVE_HULL % _ship_name(active_id)
	for payload: Dictionary in _payloads:
		var tag: Label = payload[&"tag"]
		tag.text = STATE_ACTIVE if payload[&"id"] == active_id else ""


func _refresh_preview(profile: ProfileScript) -> void:
	var ship := Catalog.ship(_selected_id)
	if ship.is_empty():
		_preview_image.texture = null
		_preview_name.text = PREVIEW_EMPTY
		_preview_caption.text = ""
		_refresh_comparison({}, profile)
		_set_layout_grid(&"")
		return
	var texture := load(String(ship.get(&"preview", ""))) as Texture2D
	_preview_image.texture = texture
	_preview_name.text = String(ship.get(&"name", String(_selected_id)))
	_preview_caption.text = String(ship.get(&"description", ""))
	_refresh_comparison(ship, profile)
	_set_layout_grid(_selected_id)


func _refresh_comparison(ship: Dictionary, profile: ProfileScript) -> void:
	var active_id := _active_id(profile)
	var active := Catalog.ship(active_id)
	for stat: Dictionary in STAT_ROWS:
		var cells: Array = _stat_cells.get(stat[&"key"], [])
		if cells.size() < 2:
			continue
		var key: StringName = stat[&"key"]
		var selected_value := _stat_value(ship, _selected_id, key)
		var active_value := _stat_value(active, active_id, key)
		var selected_label: Label = cells[0]
		var active_label: Label = cells[1]
		selected_label.text = str(selected_value)
		active_label.text = str(active_value)
		if selected_value < active_value:
			selected_label.add_theme_color_override(&"font_color", _token(&"text_dim"))
		else:
			selected_label.remove_theme_color_override(&"font_color")
		## A7's hull-comparison deltas (D17-P2's fix): the signed difference, `+0` honest
		## when the hull is compared to itself.
		var delta := _delta_cells.get(key, null) as Label
		if delta != null:
			delta.text = DELTA_FORMAT % (selected_value - active_value)


## The footer's one action: `SET ACTIVE` for an owned hull that is not the active one,
## `IN SERVICE` (disabled) for the active one, and disabled with `SET ACTIVE` when no hull
## is owned at all. It is the pane's sole commit (section 5.11); selecting never reaches it.
func _refresh_action(profile: ProfileScript) -> void:
	_action.text = ACTION_SET_ACTIVE
	if _selected_id == &"" or not _owned_ids(profile).has(_selected_id):
		_action.disabled = true
		return
	_action.disabled = _selected_id == _active_id(profile)
	if _action.disabled:
		_action.text = ACTION_IN_SERVICE


func _on_row_focused(row: Button, payload: Dictionary) -> void:
	AudioManager.play_ui(AudioManager.UiCue.HOVER)
	if _selected_row != null and _selected_row != row and is_instance_valid(_selected_row):
		_selected_row.set_pressed_no_signal(false)
	_selected_row = row
	row.set_pressed_no_signal(true)
	_preview_row(payload)


## CONTRACTS section 23.1: the shipyard's additive hover surface. A hover publishes the
## hull's own identity line as the title and its catalogue description as the body; a
## leave clears the chain (S30-F1, F5: P6's band fill is retired, so an unhover never
## re-arms the N27 tooltip).
func _on_row_hovered(payload: Dictionary, hovered: bool) -> void:
	_inspect_row(payload, hovered)


func _inspect_row(payload: Dictionary, shown: bool) -> void:
	if not shown:
		inspect_requested.emit("", "", false)
		return
	inspect_requested.emit(
		_row_title(payload), Catalog.describe(StringName(payload[&"id"])), false
	)


## Selecting a row previews it and writes nothing (section 5.11: "selecting a row previews
## ... and writes nothing; the footer SET ACTIVE is the sole commit"). The press is the
## row's `pressed`, the focus is the ring - both go through `_preview_row`.
func _on_row_pressed(payload: Dictionary) -> void:
	if _inspect_mode:
		_emit_sheet(payload)
		return
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	var row: Button = payload[&"row"]
	row.set_pressed_no_signal(true)
	_selected_row = row
	_preview_row(payload)


func _on_action_pressed() -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	_act(_selected_id)


## The selection itself: the previewed hull moves, the three preview readers move with it,
## and the hint names the hull now previewed. Nothing here touches the profile. S30 census
## row 7 (UI_SPEC section 12.5): the status write is gone - the strip keeps transaction
## outcomes, and the hull's description rides the N27 tooltip.
func _preview_row(payload: Dictionary) -> void:
	var profile := _profile()
	_selected_id = payload[&"id"]
	_focused_payload = payload
	_refresh_preview(profile)
	_refresh_action(profile)
	_inspect_row(payload, true)


## The pane's one write: `set_active_ship` for the previewed hull, which the profile
## refuses for a hull the account does not own or already flies (it announces that itself,
## section 5.6). A refusal writes nothing and leaves the selection where it was; the refusals
## the pane can see are the ones its own footer state already prevents.
func _act(ship_id: StringName) -> void:
	var profile := _profile()
	if profile == null:
		return
	var ship := Catalog.ship(ship_id)
	if ship.is_empty():
		return
	if not bool(profile.call(&"set_active_ship", ship_id)):
		_pulse(_action)
		_refresh_all()
		return
	AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
	status_requested.emit(STATUS_ACTIVE % _ship_name(ship_id), false)
	_refresh_all()


func _row_hint(payload: Dictionary) -> String:
	return STATUS_HINT % [
		String(payload[&"name"]).to_upper(),
		String(ShipFit.HULLS.get(payload[&"id"], {}).get(&"ship_class", "")).to_upper(),
	]


## The hull's identity for the inspector's title: its name and class phrase, the same
## values `_row_hint` prints, with the key-hint verb kept for the status strip alone.
func _row_title(payload: Dictionary) -> String:
	return INSPECT_TITLE_FORMAT % [
		String(payload[&"name"]).to_upper(),
		String(ShipFit.HULLS.get(payload[&"id"], {}).get(&"ship_class", "")).to_upper(),
	]


## The hull the preview opens on: the active hull when the account owns it, else the first
## owned hull of the ladder, else nothing (an account that owns no hull at all).
func _default_selection(profile: ProfileScript) -> StringName:
	var active_id := _active_id(profile)
	if _owned_ids(profile).has(active_id):
		return active_id
	var roster := _owned_roster(profile)
	return roster[0] if not roster.is_empty() else &""


func _ship_name(ship_id: StringName) -> String:
	## The tag and the action copy name the hull the way the catalogue does, and fall back to
	## the id itself when the catalogue cannot resolve it.
	var ship := Catalog.ship(ship_id)
	return String(ship.get(&"name", String(ship_id))).to_upper()


func _active_id(profile: ProfileScript) -> StringName:
	if profile == null:
		return &""
	return StringName(profile.call(&"active_ship"))


func _owned_ids(profile: ProfileScript) -> Array:
	if profile == null:
		return []
	return profile.call(&"owned_ships")


func _profile() -> ProfileScript:
	## Autoloads are children of /root; STATION_HUB section 12.4 names a bare
	## ^"PlayerProfile" path, which would resolve against this node instead, so the
	## lookup is anchored at the tree root the way router.gd anchors its services.
	if not is_inside_tree():
		return null
	var service := get_tree().root.get_node_or_null(NodePath(PROFILE_SERVICE))
	if service == null:
		return null
	var profile: ProfileScript = service
	return profile


func _pulse(node: CanvasItem) -> void:
	var tween := _make_tween()
	tween.tween_property(node, "modulate:a", PULSE_MIN_ALPHA, PULSE_DOWN_SECONDS).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "modulate:a", 1.0, PULSE_UP_SECONDS).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "modulate:a", PULSE_MIN_ALPHA, PULSE_DOWN_SECONDS).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "modulate:a", 1.0, PULSE_UP_SECONDS).set_trans(Tween.TRANS_SINE)


func _make_tween() -> Tween:
	for index in range(_tweens.size() - 1, -1, -1):
		if not _tweens[index].is_valid():
			_tweens.remove_at(index)
	var tween := create_tween()
	_tweens.append(tween)
	return tween


## CONTRACTS section 23.1: one home for the digit-grouping rule (`StationCatalog.group_int`),
## the shell's own copy - so the fee line and the credits readout cannot drift.
func _format_int(value: int) -> String:
	return Catalog.group_int(value)


## ---------------------------------------------------- the repair block (P5, P13)
##
## STATION_HUB section 17.2: the repairs surface folds in below the comparison - the
## damage table on `repairs_panel.gd:74-89`'s own REPORT_ROWS minus the `MISSING` and
## `FEE` body rows, `NOMINAL` in `text_dim` for intact systems (P13), the fee in the
## footer line only (`REPAIR AVAILABLE · <n> CR` / `ALL SYSTEMS NOMINAL`, both shipped
## wordings) and `REPAIR` as the P1 ActionPrimary at the foot. The block is the ACTIVE
## hull's (the table's own first row names it), so the repair restores the hull the
## launch would fly.


func _build_repair_rows() -> void:
	_repair_rows.add_theme_constant_override(&"separation", REPAIR_ROW_SEPARATION)
	for row: Dictionary in RepairsPanelScript.REPORT_ROWS:
		if row[&"key"] == &"missing" or row[&"key"] == &"fee":
			continue
		var line := HBoxContainer.new()
		line.name = "Report%s" % String(row[&"key"]).to_pascal_case()
		line.add_theme_constant_override(&"separation", COLUMN_SEPARATION)
		line.mouse_filter = Control.MOUSE_FILTER_STOP
		_repair_rows.add_child(line)
		var caption := _make_label(&"StationCaption", String(row[&"label"]))
		caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(caption)
		var value := _make_label(&"StationValue", PRICE_ZERO)
		value.custom_minimum_size = Vector2(COL_STAT, 0.0)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		line.add_child(value)
		var state := _make_label(&"StationValue", "")
		state.custom_minimum_size = Vector2(COL_STAT, 0.0)
		state.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		line.add_child(state)
		var payload := {
			&"key": row[&"key"],
			&"label": String(row[&"label"]),
			&"value": value,
			&"state": state,
			&"value_text": "",
			&"missing": 0,
		}
		line.mouse_entered.connect(_on_damage_hovered.bind(payload, true))
		line.mouse_exited.connect(_on_damage_hovered.bind(payload, false))
		_repair_values.append(payload)


## One damage row describes through the existing chain, its payload carrying one line of
## `Repairs` context - what the pool is and its max (section 17.2's own rule).
func _on_damage_hovered(payload: Dictionary, hovered: bool) -> void:
	if not hovered:
		inspect_requested.emit("", "", false)
		return
	inspect_requested.emit(
		"%s %s" % [String(payload[&"label"]), String(payload[&"value_text"])],
		_damage_context(payload),
		false
	)


func _damage_context(payload: Dictionary) -> String:
	var text := String(payload[&"value_text"])
	var parts := text.split(" / ")
	if parts.size() != 2:
		return text
	return DAMAGE_CONTEXT % [parts[0], parts[1]]


## The damage table's read: the vitals the profile filed for the ACTIVE hull and the
## resolved maxima (plates and affixes included, `repairs_panel.gd:_pool_maxima`'s own
## rule) - the same figures the fee is computed from, so the block cannot disagree with
## `Repairs.fee`.
func _refresh_repair(profile: ProfileScript) -> void:
	var active_id := _active_id(profile)
	var ship := Catalog.ship(active_id)
	var vitals := _vitals_of(profile, active_id)
	var maxima := _pool_maxima(profile, active_id, ship)
	var hull_max := int(maxima.get(&"hull", 0))
	var shield_max := int(maxima.get(&"shield", 0))
	var hull := clampi(int(vitals.get(&"hull", 0)), 0, hull_max) if not vitals.is_empty() else hull_max
	var shield := clampi(int(vitals.get(&"shield", 0)), 0, shield_max) if not vitals.is_empty() else shield_max
	var current_pools: Array = RepairsService.pools(float(hull))
	var max_pools: Array = RepairsService.pools(float(hull_max))
	for payload: Dictionary in _repair_values:
		var key: StringName = payload[&"key"]
		var text := ""
		var missing := 0
		if key == &"hull_name":
			text = _ship_name(active_id) if active_id != &"" else RepairsPanelScript.UNKNOWN_HULL
		elif key == &"hull" or key == &"shield":
			var current := hull if key == &"hull" else shield
			var maximum := hull_max if key == &"hull" else shield_max
			text = REPAIR_VALUE_FORMAT % [str(current), str(maximum)]
			missing = maxi(0, maximum - current)
		else:
			var index: int = RepairsPanelScript.QUADRANT_KEYS.find(key)
			if index < 0:
				continue
			var current := int(round(float(current_pools[index])))
			var maximum := int(round(float(max_pools[index])))
			text = REPAIR_VALUE_FORMAT % [str(current), str(maximum)]
			missing = maxi(0, maximum - current)
		payload[&"value_text"] = text
		payload[&"missing"] = missing
		var value: Label = payload[&"value"]
		value.text = text
		var state: Label = payload[&"state"]
		if key == &"hull_name":
			state.text = ""
		elif missing == 0:
			## P13: intact rows read `NOMINAL` in `text_dim` (label + state, never a
			## colour alone).
			state.text = ROW_NOMINAL
			state.add_theme_color_override(&"font_color", _token(&"text_dim"))
		else:
			state.text = str(missing)
			state.remove_theme_color_override(&"font_color")
	_refresh_repair_footer(profile, active_id)


## The fee line (P5: the fee lives in the footer, never a body row) and the `REPAIR`
## primary's state - all-nominal disables it with `text_dim` (A5.4-2's unavailable idiom).
func _refresh_repair_footer(profile: ProfileScript, active_id: StringName) -> void:
	var vitals := _vitals_of(profile, active_id)
	if vitals.is_empty():
		_repair_footer.text = RepairsPanelScript.HINT_NO_REPORT
		_set_repair_enabled(false)
		return
	var fee := RepairsService.fee(profile, active_id)
	var repairable := RepairsService.is_repairable(profile, active_id)
	if not repairable:
		_repair_footer.text = RepairsPanelScript.NOMINAL
	elif fee == 0:
		_repair_footer.text = RepairsPanelScript.EXEMPT_HINT
	else:
		_repair_footer.text = RepairsPanelScript.HINT_REPAIR % _format_int(fee)
	_set_repair_enabled(repairable)


func _set_repair_enabled(enabled: bool) -> void:
	_repair_button.disabled = not enabled
	_repair_button.text = ACTION_REPAIR
	if enabled:
		_repair_button.remove_theme_color_override(&"font_color")
	else:
		_repair_button.add_theme_color_override(&"font_color", _token(&"text_dim"))


## The pane's one repair write: `Repairs.repair` on the ACTIVE hull (the composed service,
## `repairs_panel.gd`'s own route), then the block rebuilds and the result line lands in
## the footer and the shell's strip.
func _on_repair_pressed() -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	var profile := _profile()
	if profile == null:
		return
	var active_id := _active_id(profile)
	var result: Dictionary = RepairsService.repair(profile, active_id)
	_refresh_all()
	if bool(result.get(&"ok", false)):
		AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
		status_requested.emit(
			RepairsPanelScript.STATUS_REPAIRED % _format_int(int(result.get(&"fee", 0))), false
		)
		return
	var reason: StringName = result.get(&"reason", &"")
	AudioManager.play_ui(AudioManager.UiCue.DENIED)
	_pulse(_repair_button)
	if reason == RepairsService.REASON_NO_DAMAGE:
		status_requested.emit(RepairsPanelScript.NOMINAL, false)
	elif reason == RepairsService.REASON_NO_DAMAGE_REPORT:
		status_requested.emit(RepairsPanelScript.HINT_NO_REPORT, false)
	else:
		var fee := RepairsService.fee(profile, active_id)
		status_requested.emit(RepairsPanelScript.REFUSAL_INSUFFICIENT % _format_int(fee), true)


func _vitals_of(profile: ProfileScript, ship_id: StringName) -> Dictionary:
	if profile == null or ship_id == &"":
		return {}
	var raw: Variant = profile.call(&"vitals_of", ship_id)
	return raw if raw is Dictionary else {}


## The two denominators the HULL and SHIELD rows print (`repairs_panel.gd:382-400`'s own
## rule): `ShipFit.resolve`'s figures for the fit the launch would fly, plates and affixes
## included, with the catalogue row as the fallback.
func _pool_maxima(profile: ProfileScript, ship_id: StringName, ship: Dictionary) -> Dictionary:
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


## The footer line's own text and the repair rows' values, read back for probes and tests.
func repair_footer_text() -> String:
	return _repair_footer.text


func repair_row_values() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for payload: Dictionary in _repair_values:
		out.append({
			&"key": payload[&"key"],
			&"value": String(payload[&"value_text"]),
			&"state": String((payload[&"state"] as Label).text),
		})
	return out


## --- S27: the build path's views (10 section 3) -------------------------------------


## Swap the pane's body for one mode's view. Every view is a read of `Shipyard` plus the
## live catalogues; the hangar keeps its own `ShipyardBody`.
func _set_mode(mode: String) -> void:
	_mode = mode
	_hangar_body.visible = mode == MODE_HANGAR
	_build_view.visible = mode == MODE_BUILD
	_queue_view.visible = mode == MODE_QUEUE
	_scrap_view.visible = mode == MODE_SCRAP
	_mode_hangar.button_pressed = mode == MODE_HANGAR
	_mode_build.button_pressed = mode == MODE_BUILD
	_mode_queue.button_pressed = mode == MODE_QUEUE
	_mode_scrap.button_pressed = mode == MODE_SCRAP
	_refresh_views()


## Redraw the active build-path view from the live profile and catalogues.
func _refresh_views() -> void:
	if not is_node_ready():
		return
	match _mode:
		MODE_BUILD:
			_fill_build_view()
		MODE_QUEUE:
			_fill_queue_view()
		MODE_SCRAP:
			_fill_scrap_view()


## BUILD: one row per buildable hull and module, each a `StationButton` naming the
## recipe's live CR total. A press queues the build (10 section 3.3).
func _fill_build_view() -> void:
	_clear(_build_list)
	var profile := _profile()
	for ship_id: StringName in ShipyardScript.buildable_hulls():
		var recipe := ShipyardScript.hull_recipe(ship_id)
		_build_list.add_child(_build_action_row(
			ShipyardScript.KIND_HULL, ship_id,
			BUILD_HULL_FORMAT % [
				_ship_name(ship_id),
				_ship_list_price(ship_id),
				ShipyardScript.recipe_total(recipe),
			]
		))
	for module_id: StringName in ShipyardScript.buildable_modules():
		var recipe := ShipyardScript.module_recipe(module_id)
		if recipe.is_empty():
			continue
		_build_list.add_child(_build_action_row(
			ShipyardScript.KIND_MODULE, module_id,
			BUILD_MODULE_FORMAT % [
				_module_name(module_id),
				int(ModuleCatalog.module(module_id).get(&"cost", 0)),
				ShipyardScript.recipe_total(recipe),
			]
		))
	_build_footer.text = _queue_footer(profile)


## QUEUE: the one active job and its state (10 section 3.3), with COLLECT / CANCEL.
func _fill_queue_view() -> void:
	var profile := _profile()
	var job := ShipyardScript.job(profile)
	if job.is_empty():
		_queue_body.text = QUEUE_IDLE
	else:
		var label := _job_label(job)
		_queue_body.text = QUEUE_READY % label if ShipyardScript.is_ready(profile, job) else QUEUE_RUNNING % label
	_queue_collect.disabled = job.is_empty() or not ShipyardScript.is_ready(profile, job)
	_queue_cancel.disabled = job.is_empty() or ShipyardScript.is_ready(profile, job)


## SCRAP: one row per owned hull, naming 50 % of its recipe materials (10 section 3.3).
func _fill_scrap_view() -> void:
	_clear(_scrap_list)
	var profile := _profile()
	var owned := _owned_roster(profile)
	if owned.is_empty():
		_scrap_footer.text = SCRAP_EMPTY
		return
	for ship_id: StringName in owned:
		var recipe := ShipyardScript.hull_recipe(ship_id)
		if recipe.is_empty():
			continue
		var scrap := ShipyardScript.scrap_materials(recipe.get(ShipyardScript.KEY_MATERIALS, {}))
		_scrap_list.add_child(_build_action_row(
			&"scrap", ship_id,
			SCRAP_ROW_FORMAT % [_ship_name(ship_id), ShipyardScript.materials_value(scrap)]
		))
	_scrap_footer.text = SCRAP_ACTION


## One build/scrap row: a `StationButton` whose press routes to the mode's action.
func _build_action_row(kind: StringName, id: StringName, text: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 44)
	button.theme_type_variation = &"StationButton"
	button.text = text
	button.pressed.connect(_on_build_row_pressed.bind(kind, id))
	return button


func _on_build_row_pressed(kind: StringName, id: StringName) -> void:
	if kind == &"scrap":
		_scrap_ship(id)
		return
	if ShipyardScript.queue_job(_profile(), kind, id):
		status_requested.emit(BUILD_QUEUED % _job_label(ShipyardScript.job(_profile())), false)
	else:
		status_requested.emit(BUILD_REFUSED, true)
	_refresh_views()


func _on_queue_collect() -> void:
	if ShipyardScript.collect(_profile()):
		status_requested.emit(BUILD_QUEUED % "DELIVERED", false)
	_refresh_views()


func _on_queue_cancel() -> void:
	if ShipyardScript.cancel_job(_profile()):
		status_requested.emit(QUEUE_CANCELLED, false)
	_refresh_views()


## Break one owned hull down for 50 % of its recipe materials (10 section 3.3). The
## materials land in the hold and the hull leaves the owned list.
func _scrap_ship(ship_id: StringName) -> void:
	var profile := _profile()
	var recipe := ShipyardScript.hull_recipe(ship_id)
	if recipe.is_empty() or not profile.owns_ship(ship_id):
		return
	var scrap := ShipyardScript.scrap_materials(recipe.get(ShipyardScript.KEY_MATERIALS, {}))
	for key: Variant in scrap:
		profile.add_cargo(StringName(str(key)), int(scrap[key]))
	profile.remove_ship(ship_id)
	_refresh_views()


func _job_label(job: Dictionary) -> String:
	var kind := StringName(str(job.get(ShipyardScript.KEY_KIND, &"")))
	var id := StringName(str(job.get(ShipyardScript.KEY_ID, &"")))
	if kind == ShipyardScript.KIND_HULL:
		return _ship_name(id)
	return _module_name(id)


func _queue_footer(profile: ProfileScript) -> String:
	var job := ShipyardScript.job(profile)
	if job.is_empty():
		return QUEUE_IDLE
	return QUEUE_RUNNING % _job_label(job)


func _module_name(module_id: StringName) -> String:
	return String(ModuleCatalog.module(module_id).get(&"name", String(module_id)))


func _ship_list_price(ship_id: StringName) -> int:
	return int(Catalog.ship(ship_id).get(&"cost", 0))
