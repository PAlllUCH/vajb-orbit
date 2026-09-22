extends VBoxContainer
## AUCTION module panel: the rotating shelf -- six hulls, ten rolled module instances
## and the `SELL MODULES` sub-list -- plus the pane's own rotation footer.
## Contract: docs/design/STATION_HUB.md section 5.10 (the 2026-09-22 S3 amendment),
## sections 5.1, 5.3, 5.6, 10, 11, 12.3 and 12.4; docs/gameplay/10_ship_acquisition.md
## sections 2/2.2/2.3/2.4; docs/gameplay/15_module_affixes.md sections 1, 5, 6, 7, 8 and 9;
## docs/CONTRACTS.md section 15.
##
## The pane never prices anything itself and never mutates the profile directly: every
## number it renders is an `Auction` read (the one pricing family, 05 section 8) and every
## write is an `Auction` transaction (`evaluate_shelf`, `buy_hull`, `buy_listing`,
## `sell_row`), which in turn calls only the profile's own public API. That is what keeps
## a rolled instance's price arithmetic in one place.
##
## **The footer is the pane's own** (section 5.10's S3 amendment): the shell's copy prices
## by catalogue id and an instance id resolves to `{}`, so the pane carries its own
## `RestockLabel` + `StatusLabel` strip the way FITTING carries its meter. The refusal
## wordings are unchanged -- CONTRACTS section 12's three plus 09 section 2's `<n> NEEDED`
## -- only their owner is. The pane also reads the two conditions it can see
## (`can_afford`, `owns_ship`) before it calls, so a refusal the profile would have to
## price through an instance id never reaches the shell's copy path at all.
##
## **The restock line is a reading, not a countdown** (section 5.10's S3 amendment): it is
## computed at pane entry from `WorldClock.now()` and `Auction.next_restock_seconds`, and
## nothing ticks it, because the clock forbids a per-consumer Timer (05 section 8).
##
## Panel contract with the shell:
##   signal status_requested(message: String, danger: bool)   write the shell's strip
##   func refresh_profile(key: StringName) -> void             react to profile_changed
##   func focus_primary() -> void                              focus entry after a switch

const TOKENS_TYPE: StringName = &"Tokens"

const AuctionScript := preload("res://game/auction.gd")
const ModuleData := preload("res://game/module_catalog.gd")
const Catalog := preload("res://game/station_catalog.gd")
const Clock := preload("res://autoload/world_clock.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"

signal status_requested(message: String, danger: bool)

## ------------------------------------------------------------------ 12.3 constants
const ROW_HEIGHT := 76.0
const ROW_INNER_MARGIN := Vector2i(12, 8)
const COLUMN_SEPARATION := 12
const CELL_SEPARATION := 2
const COL_ICON := 48.0
const COL_PRICE := 170.0
const COL_OWNED := 170.0
const COL_STATUS := 160.0
const COL_ACTION := 160.0
## A header cannot trust its declared widths (a caption can outgrow its column), so it is
## re-fitted from its own rows' grid; frames the retry loop waits while its host has not
## laid the rows out yet. The same construct the OUTFITTING and FITTING panes carry.
const HEADER_FIT_RETRIES := 8
const ROW_ICON_IDLE_ALPHA := 0.72
const HOVER_SECONDS := 0.09

## Section 5.10's own captions, column words and row words. Nothing below is this pass's
## invention: `HULLS`, `MODULES` and `SELL MODULES` are the amendment's own section names,
## `BUY` and `SELL` its own ACTION words, `F LOT` its own tag.
const CAPTION_HULLS := "HULLS"
const CAPTION_MODULES := "MODULES"
const CAPTION_SELL := "SELL MODULES"
const HEADER_HULL := "HULL"
const HEADER_MODULE := "MODULE"
const HEADER_OWNED := "OWNED"
const HEADER_PRICE := "PRICE"
const HEADER_STATUS := "STATUS"
const HEADER_ACTION := "ACTION"
const PRICE_CAPTION := "CREDITS"
const LIST_CAPTION := "LIST"
const HULL_CLASS_FORMAT := "%s CLASS"
## Section 5.10's two ACTION words, the rows' own column: the pane renders them, so they
## live here rather than in the rotation module the words are read from.
const ACTION_BUY := "BUY"
const ACTION_SELL := "SELL"
const SUBTITLE := "THE HOUSE BROKER · %d HULLS · %d MODULES"
const TAG_INTERIM := "F LOT · ONE PER SHELF"

## The pane's own empty states. Section 5.10 gives no wording for a bought-out shelf (the
## shelf persists and refills at the next band, 10 section 2.1), so the caption names the
## rotation it is missing rather than a refusal, and the sell sub-list names the bag.
const EMPTY_HULLS := "NO HULLS IN THIS ROTATION"
const EMPTY_MODULES := "NO MODULES IN THIS ROTATION"
const EMPTY_SELL := "NO MODULES IN THE BAG"

## Line shapes. The hint is the OUTFITTING pane's own; the purchase line is the shell's,
## the sale line the exchange's, and the three refusals CONTRACTS section 12's and
## 09 section 2's own.
const STATUS_HINT := "ENTER %s · %s · %s CREDITS"
const STATUS_BOUGHT := "PURCHASED · %s · %s CREDITS"
const STATUS_SOLD := "SOLD · %s · +%s CR"
const STATUS_REFUSED_UNKNOWN := "REFUSED · NOT FOR SALE"
const STATUS_REFUSED_OWNED := "REFUSED · ALREADY OWNED · %s"
const STATUS_REFUSED_CREDITS := "REFUSED · NOT ENOUGH CREDITS · %s NEEDED"
const STATUS_IDLE := "BUYOUT AT LIST PRICE · SELL AT %d %%"

## The rows' own node path to the tinted title label, built in script: the row Button's
## `RowInner` margin holds one HBox (`RowBox`), which holds `ThemeBox`, which holds `Title`.
const TITLE_PATH := ^"RowInner/RowBox/ThemeBox/Title"

@onready var _subtitle: Label = %PaneSubtitle
@onready var _tag: Label = %PanelTag
@onready var _scroll: ScrollContainer = %AuctionScroll
@onready var _hull_caption: Label = %HullsCaption
@onready var _hull_header: HBoxContainer = %HullsHeader
@onready var _hull_rows: VBoxContainer = %HullRows
@onready var _module_caption: Label = %ModulesCaption
@onready var _module_header: HBoxContainer = %ModulesHeader
@onready var _module_rows: VBoxContainer = %ModuleRows
@onready var _sell_caption: Label = %SellCaption
@onready var _sell_header: HBoxContainer = %SellHeader
@onready var _sell_rows: VBoxContainer = %SellRows
@onready var _restock: Label = %RestockLabel
@onready var _status: Label = %StatusLabel

## The three rendered lists, each a payload array; `hull_payloads()`, `module_payloads()`
## and `sell_payloads()` read them back for probes and tests.
var _hulls: Array[Dictionary] = []
var _listings: Array[Dictionary] = []
var _sales: Array[Dictionary] = []

## The three header/rows pairs (`{key, header, rows, cells, queued, retries}`), so one fit
## pass serves all three headers instead of three copies of it.
var _sections: Array[Dictionary] = []

var _pending_rebuild := false
var _selected_row: Button = null
var _tweens: Array[Tween] = []


func _ready() -> void:
	_hull_caption.text = CAPTION_HULLS
	_module_caption.text = CAPTION_MODULES
	_sell_caption.text = CAPTION_SELL
	_connect_layout()
	_build_header(_hull_header, _hulls_layout())
	_build_header(_module_header, _listings_layout())
	_build_header(_sell_header, _sales_layout())
	_apply_tokens()
	_connect_scroll()
	enter_pane()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_apply_tokens()
		_queue_header_fit()


func _exit_tree() -> void:
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()


## Pane entry: the shelf is advanced to the clock's reading (10 section 2.1's lazy bands,
## the exchange's own shape) and the whole pane is drawn from it. The shell calls this
## through `focus_primary` when the module is switched to; `_ready` calls it once for the
## pane the shell builds but does not show.
func enter_pane() -> void:
	var profile := _profile()
	if profile != null:
		AuctionScript.evaluate_shelf(profile, Clock.now())
	_rebuild()
	_take_restock_reading()
	_set_status(status_idle(), false)


func focus_primary() -> void:
	## STATION_HUB section 5.10's focus order: the two lists in row order (HULLS then
	## MODULES), then the sell sub-list, then the footer, then the rail. Entering the pane
	## is also when the rotation is advanced and the restock line is read (section 5.10's
	## S3 amendment: "a reading taken at pane entry").
	enter_pane()
	for payload: Dictionary in _hulls + _listings + _sales:
		var row: Button = payload[&"row"]
		if row != null and is_instance_valid(row) and not row.disabled:
			row.grab_focus()
			return


func refresh_profile(key: StringName) -> void:
	## STATION_HUB section 12.4: `&"credits"` moves every price and tag, `&"modules"` the
	## shelf's own rows (a bought listing leaves it) and the bag's sell rows, `&"ships"`
	## the hulls' owned state. Nothing here rebuilds a node inline: the profile emits
	## mid-handler and the row whose press started it is still on the stack, so a rebuild
	## is queued and runs after that handler returns.
	if key == &"credits":
		_refresh_rows()
		return
	if key == &"modules" or key == &"ships":
		_refresh_rows()
		_queue_rebuild()


## The shelf's hull rows, in render order, read back for probes and tests: one entry per
## listed hull, `{id, name, ship_class, list, cost, was, hot, owned}`.
func hull_payloads() -> Array[Dictionary]:
	return _hulls.duplicate(true)


## The shelf's module rows, in render order, `{id, base_id, name, meta, cost, was, hot,
## faction_lot, tint, owned}`.
func module_payloads() -> Array[Dictionary]:
	return _listings.duplicate(true)


## The sell sub-list's rows, in render order, `{id, base_id, name, meta, cost, owned,
## owned_text, tint}`.
func sell_payloads() -> Array[Dictionary]:
	return _sales.duplicate(true)


## The row that carries one listing, hull or instance id, or null.
func row_of(id: StringName) -> Button:
	for payload: Dictionary in _hulls + _listings + _sales:
		if payload[&"id"] == id:
			return payload[&"row"]
	return null


## The restock line the pane took at its last entry, `NEXT RESTOCK <m:ss>`.
func restock_text() -> String:
	return _restock.text


## The pane's own status/refusal strip's current line.
func status_text() -> String:
	return _status.text


## The pane's idle line, built from 10 section 2.3's buyout rule and the catalogue's own
## sell share rather than from a literal.
func status_idle() -> String:
	return STATUS_IDLE % ModuleData.SELL_PERCENT


## ------------------------------------------------------------- the actions


## BUY a listed hull at 10 section 2.3's buyout (the shelf's price, hot slot included).
## The profile decides; the pane reads the two conditions it can see first, so a refusal
## that would have to be priced through the shell's copy never gets there.
func buy_hull(ship_id: StringName) -> bool:
	var profile := _profile()
	if profile == null:
		return false
	var ship := Catalog.ship(ship_id)
	if ship.is_empty():
		return _refuse(STATUS_REFUSED_UNKNOWN)
	if bool(profile.call(&"owns_ship", ship_id)):
		return _refuse(STATUS_REFUSED_OWNED % String(ship.get(&"name", String(ship_id))).to_upper())
	var result: Dictionary = AuctionScript.buy_hull(profile, ship_id)
	if not bool(result.get(&"ok", false)):
		return _refuse(_refusal(result))
	AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
	_set_status(
		STATUS_BOUGHT % [String(result[&"name"]).to_upper(), _format_int(int(result[&"price"]))],
		false
	)
	return true


## BUY one listed instance. The cost is the row's own (the hot slot is the shelf's, not the
## catalogue's), and `buy_instance` takes it as "the price it shows".
func buy_listing(id: StringName) -> bool:
	var profile := _profile()
	if profile == null:
		return false
	var row := _listing_payload(id)
	if row.is_empty():
		return _refuse(STATUS_REFUSED_UNKNOWN)
	if not bool(profile.call(&"can_afford", int(row[&"cost"]))):
		return _refuse(STATUS_REFUSED_CREDITS % _format_int(int(row[&"cost"])))
	var result: Dictionary = AuctionScript.buy_listing(profile, id)
	if not bool(result.get(&"ok", false)):
		return _refuse(_refusal(result))
	AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
	_set_status(
		STATUS_BOUGHT % [String(result[&"name"]).to_upper(), _format_int(int(result[&"price"]))],
		false
	)
	return true


## SELL one instance out of the bag, at 15 section 6's `base x rarity x 60 %`.
func sell_row(id: StringName) -> bool:
	var profile := _profile()
	if profile == null:
		return false
	if _sell_payload(id).is_empty():
		return _refuse(STATUS_REFUSED_UNKNOWN)
	var result: Dictionary = AuctionScript.sell_row(profile, id)
	if not bool(result.get(&"ok", false)):
		return _refuse(_refusal(result))
	AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
	_set_status(
		STATUS_SOLD % [String(result[&"name"]).to_upper(), _format_int(int(result[&"price"]))],
		false
	)
	return true


## The pinned refusal line for a refused transaction. The three wordings are CONTRACTS
## section 12's and 09 section 2's; none is this pass's.
func _refusal(result: Dictionary) -> String:
	match StringName(result.get(&"reason", &"")):
		AuctionScript.REASON_ALREADY_OWNED:
			return STATUS_REFUSED_OWNED % String(result.get(&"name", "")).to_upper()
		AuctionScript.REASON_INSUFFICIENT:
			return STATUS_REFUSED_CREDITS % _format_int(int(result.get(&"cost", 0)))
	return STATUS_REFUSED_UNKNOWN


func _refuse(message: String) -> bool:
	AudioManager.play_ui(AudioManager.UiCue.DENIED)
	_set_status(message, true)
	return false


func _set_status(message: String, danger: bool) -> void:
	_status.text = message
	_status.add_theme_color_override(
		&"font_color", _token(&"accent_danger") if danger else _token(&"text_primary")
	)
	status_requested.emit(message, danger)


## ----------------------------------------------------------- the restock reading


func _take_restock_reading() -> void:
	var profile := _profile()
	var seconds := (
		AuctionScript.next_restock_seconds(profile, Clock.now())
		if profile != null
		else Clock.BAND_SECONDS
	)
	_restock.text = AuctionScript.restock_text(seconds)


## ------------------------------------------------------------------- the rows


func _rebuild() -> void:
	_clear(_hull_rows)
	_clear(_module_rows)
	_clear(_sell_rows)
	_hulls.clear()
	_listings.clear()
	_sales.clear()
	var profile := _profile()
	if profile == null:
		return
	for entry: Dictionary in AuctionScript.hull_rows(profile):
		_hulls.append(_build_hull_row(entry))
	for entry: Dictionary in AuctionScript.listing_rows(profile):
		_listings.append(_build_module_row(entry))
	for entry: Dictionary in AuctionScript.sell_rows(profile):
		_sales.append(_build_sell_row(entry))
	if _hulls.is_empty():
		_hull_rows.add_child(_empty_row(EMPTY_HULLS))
	if _listings.is_empty():
		_module_rows.add_child(_empty_row(EMPTY_MODULES))
	if _sales.is_empty():
		_sell_rows.add_child(_empty_row(EMPTY_SELL))
	_subtitle.text = SUBTITLE % [_hulls.size(), _listings.size()]
	_tag.text = TAG_INTERIM if AuctionScript.AUCTION_FACTION_LOTS_INTERIM else ""
	_refresh_rows()


func _clear(rows: VBoxContainer) -> void:
	for child: Node in rows.get_children():
		rows.remove_child(child)
		child.queue_free()


func _empty_row(text: String) -> Label:
	var label := Label.new()
	label.name = "EmptyRow"
	label.theme_type_variation = &"StationCaption"
	label.text = text
	label.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## One HULLS row: section 5.10's "48 px class icon slot, name, class, `LIST <n> CR` (08
## section 2 column), the hot-slot line `WAS <n> CR` when discounted, ACTION `BUY`". No
## class icon ships, so the slot draws the hull's own `preview`, the way the shipyard's row
## does (section 5.2), and the row carries the class as its meta line.
func _build_hull_row(entry: Dictionary) -> Dictionary:
	var ship_id: StringName = entry[&"id"]
	var row := _make_row("Hull%s" % String(ship_id).trim_prefix("ship_").to_pascal_case(), ship_id)
	var box := _make_inner(row)
	var icon := _make_icon(String(entry.get(&"preview", "")), COL_ICON)
	if icon != null:
		box.add_child(icon)
	box.add_child(
		_make_title_box(
			String(entry.get(&"name", "")),
			HULL_CLASS_FORMAT % String(entry.get(&"ship_class", "")).to_upper(),
			&""
		)
	)
	var price := _make_cell(box, COL_PRICE, "Price")
	var action := _make_cell(box, COL_ACTION, "Action")
	_connect_cells(box, _section_for(&"hulls"))
	var payload := {
		&"id": ship_id,
		&"name": String(entry.get(&"name", "")),
		&"ship_class": String(entry.get(&"ship_class", "")),
		&"list": int(entry.get(&"list", 0)),
		&"cost": int(entry.get(&"price", 0)),
		&"was": int(entry.get(&"was", 0)),
		&"hot": bool(entry.get(&"hot", false)),
		&"owned": bool(entry.get(&"owned", false)),
		&"row": row,
		&"icon": icon,
		&"tinted": false,
		&"action_word": ACTION_BUY,
		&"price": price[0],
		&"price_caption": price[1],
		&"action": action[0],
	}
	row.pressed.connect(_on_action_pressed.bind(payload, &"hull"))
	_wire_row(row, payload)
	_hull_rows.add_child(row)
	return payload


## One MODULES row: section 5.10's "48 px module icon, the 15 section 7 full rolled name,
## the meta `SLOT <TYPE> · DRAW <n> · <RARITY>`, price ..., ACTION `BUY`", tinted by the
## rarity table and tagged `F LOT` while 15 section 8's interim is on.
func _build_module_row(entry: Dictionary) -> Dictionary:
	var id: StringName = entry[&"id"]
	var row := _make_row("Listing%s" % String(id).to_pascal_case(), id)
	var icon_path := String(entry.get(&"icon", ""))
	var box := _make_inner(row)
	var icon := _make_icon(icon_path, COL_ICON)
	if icon != null:
		box.add_child(icon)
	box.add_child(
		_make_title_box(
			String(entry.get(&"name", "")),
			String(entry.get(&"meta", "")),
			StringName(entry.get(&"tint", &""))
		)
	)
	var price := _make_cell(box, COL_PRICE, "Price")
	var status := _make_cell(box, COL_STATUS, "Status")
	var action := _make_cell(box, COL_ACTION, "Action")
	_connect_cells(box, _section_for(&"listings"))
	var payload := {
		&"id": id,
		&"base_id": entry[&"base_id"],
		&"name": String(entry.get(&"name", "")),
		&"meta": String(entry.get(&"meta", "")),
		&"cost": int(entry.get(&"price", 0)),
		&"was": int(entry.get(&"was", 0)),
		&"hot": bool(entry.get(&"hot", false)),
		&"faction_lot": bool(entry.get(&"faction_lot", false)),
		&"tint": StringName(entry.get(&"tint", &"")),
		&"owned": int(entry.get(&"owned", 0)),
		&"row": row,
		&"icon": icon,
		&"tinted": _is_flat_glyph(icon_path),
		&"title": row.get_node_or_null(TITLE_PATH) as Label,
		&"action_word": ACTION_BUY,
		&"price": price[0],
		&"price_caption": price[1],
		&"status": status[0],
		&"action": action[0],
	}
	row.pressed.connect(_on_action_pressed.bind(payload, &"listing"))
	_wire_row(row, payload)
	_module_rows.add_child(row)
	return payload


## One `SELL MODULES` row: section 5.3's OWNED MODULES anatomy with section 5.10's sell
## price, `SELL` at `base x rarity x 60 %`. One row per instance, so the price on the row
## is the price the sale pays (two instances of one base id at two rarities do not sell
## for the same money).
func _build_sell_row(entry: Dictionary) -> Dictionary:
	var id: StringName = entry[&"id"]
	var row := _make_row("Sell%s" % String(id).to_pascal_case(), id)
	var icon_path := String(entry.get(&"icon", ""))
	var box := _make_inner(row)
	var icon := _make_icon(icon_path, COL_ICON)
	if icon != null:
		box.add_child(icon)
	box.add_child(
		_make_title_box(
			String(entry.get(&"name", "")),
			String(entry.get(&"meta", "")),
			StringName(entry.get(&"tint", &""))
		)
	)
	var owned := _make_cell(box, COL_OWNED, "Owned")
	var price := _make_cell(box, COL_PRICE, "Price")
	var action := _make_cell(box, COL_ACTION, "Action")
	_connect_cells(box, _section_for(&"sales"))
	var payload := {
		&"id": id,
		&"base_id": entry[&"base_id"],
		&"name": String(entry.get(&"name", "")),
		&"meta": String(entry.get(&"meta", "")),
		&"cost": int(entry.get(&"price", 0)),
		&"owned": int(entry.get(&"owned", 0)),
		&"owned_text": String(entry.get(&"owned_text", "")),
		&"tint": StringName(entry.get(&"tint", &"")),
		&"row": row,
		&"icon": icon,
		&"tinted": _is_flat_glyph(icon_path),
		&"title": row.get_node_or_null(TITLE_PATH) as Label,
		&"action_word": ACTION_SELL,
		&"owned_label": owned[0],
		&"price": price[0],
		&"price_caption": price[1],
		&"action": action[0],
	}
	row.pressed.connect(_on_action_pressed.bind(payload, &"sale"))
	_wire_row(row, payload)
	_sell_rows.add_child(row)
	return payload


func _make_row(node_name: String, id: StringName) -> Button:
	var row := Button.new()
	row.name = node_name
	row.toggle_mode = true
	row.focus_mode = Control.FOCUS_ALL
	row.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row.set_meta(&"id", id)
	return row


func _wire_row(row: Button, payload: Dictionary) -> void:
	row.focus_entered.connect(_on_row_focused.bind(row, payload))
	row.mouse_entered.connect(_on_row_hovered.bind(payload, true))
	row.mouse_exited.connect(_on_row_hovered.bind(payload, false))


func _make_title_box(name_text: String, meta_text: String, tint: StringName) -> VBoxContainer:
	## The box is named `ThemeBox` so a payload can find its own title label by one path
	## (`TITLE_PATH`); the rows are built in script, so no scene file carries it.
	var box := VBoxContainer.new()
	box.name = "ThemeBox"
	box.add_theme_constant_override(&"separation", CELL_SEPARATION)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := _make_label(&"StationValue", name_text)
	title.name = "Title"
	if tint != &"":
		title.add_theme_color_override(&"font_color", _rarity_color(tint))
	box.add_child(title)
	var meta := _make_label(&"StationCaption", meta_text)
	meta.name = "Meta"
	box.add_child(meta)
	return box


func _make_cell(parent: HBoxContainer, width: float, cell_name: String) -> Array[Label]:
	var box := VBoxContainer.new()
	box.name = cell_name
	box.custom_minimum_size = Vector2(width, 0.0)
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override(&"separation", CELL_SEPARATION)
	parent.add_child(box)
	var value := _make_label(&"StationValue", "")
	value.name = "Value"
	box.add_child(value)
	var caption := _make_label(&"StationCaption", "")
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
	box.name = "RowBox"
	box.add_theme_constant_override(&"separation", COLUMN_SEPARATION)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(box)
	return box


func _make_icon(icon_path: String, cell: float) -> TextureRect:
	if icon_path.is_empty() or not ResourceLoader.exists(icon_path):
		return null
	var tinted := _is_flat_glyph(icon_path)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(cell, cell)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = load(_icon_source(icon_path))
	var base := _token(&"text_primary") if tinted else Color.WHITE
	base.a = ROW_ICON_IDLE_ALPHA
	icon.modulate = base
	return icon


## Audit anomaly C16's rule, carried from the OUTFITTING and FITTING panes: these three
## catalogue weapon icons are flat Phase B glyphs that read as near-black shapes on the row
## chrome, so the row draws the derived icons/tint/ stencil moderated with text_primary.
const FLAT_GLYPH_ICONS: Array[String] = [
	"res://assets/icons/weapon/icon_weapon_cannon.svg",
	"res://assets/icons/weapon/icon_weapon_mine.svg",
	"res://assets/icons/weapon/icon_weapon_plasma.svg",
]
const TINT_DIR := "res://assets/icons/tint/"


func _is_flat_glyph(icon_path: String) -> bool:
	return FLAT_GLYPH_ICONS.has(icon_path)


func _icon_source(icon_path: String) -> String:
	if icon_path.ends_with(".svg") or not _is_flat_glyph(icon_path):
		return icon_path
	return TINT_DIR + icon_path.get_file()


## ---------------------------------------------------------------- the refresh


func _refresh_rows() -> void:
	var profile := _profile()
	for payload: Dictionary in _hulls:
		_refresh_hull_row(payload, profile)
	for payload: Dictionary in _listings:
		_refresh_module_row(payload, profile)
	for payload: Dictionary in _sales:
		_refresh_sell_row(payload)
	_queue_header_fit()


func _refresh_hull_row(payload: Dictionary, profile: ProfileScript) -> void:
	var price: Label = payload[&"price"]
	_apply_affordability(price, int(payload[&"cost"]), profile)
	price.text = _format_int(int(payload[&"cost"]))
	payload[&"price_caption"].text = (
		AuctionScript.HOT_CAPTION_FORMAT % _format_int(int(payload[&"was"]))
		if bool(payload[&"hot"])
		else LIST_CAPTION
	)
	payload[&"action"].text = ACTION_BUY
	payload[&"owned"] = _owns(profile, payload[&"id"])
	payload[&"row"].disabled = false


func _refresh_module_row(payload: Dictionary, profile: ProfileScript) -> void:
	var price: Label = payload[&"price"]
	_apply_affordability(price, int(payload[&"cost"]), profile)
	price.text = _format_int(int(payload[&"cost"]))
	payload[&"price_caption"].text = (
		AuctionScript.HOT_CAPTION_FORMAT % _format_int(int(payload[&"was"]))
		if bool(payload[&"hot"])
		else PRICE_CAPTION
	)
	payload[&"status"].text = (
		AuctionScript.FACTION_LOT_TAG
		if bool(payload[&"faction_lot"]) and AuctionScript.AUCTION_FACTION_LOTS_INTERIM
		else ""
	)
	payload[&"action"].text = ACTION_BUY
	payload[&"row"].disabled = false


func _refresh_sell_row(payload: Dictionary) -> void:
	var price: Label = payload[&"price"]
	price.remove_theme_color_override(&"font_color")
	price.text = _format_int(int(payload[&"cost"]))
	payload[&"price_caption"].text = PRICE_CAPTION
	payload[&"owned_label"].text = String(payload[&"owned_text"])
	payload[&"action"].text = ACTION_SELL
	payload[&"row"].disabled = false


func _apply_affordability(price: Label, cost: int, profile: ProfileScript) -> void:
	## Affordability is presentation only (section 12.4): the price greys in
	## `accent_danger` and the profile still makes the decision.
	var affordable := profile == null or bool(profile.call(&"can_afford", cost))
	if affordable:
		price.remove_theme_color_override(&"font_color")
	else:
		price.add_theme_color_override(&"font_color", _token(&"accent_danger"))


func _owns(profile: ProfileScript, ship_id: StringName) -> bool:
	if profile == null:
		return false
	return bool(profile.call(&"owns_ship", ship_id))


func _queue_rebuild() -> void:
	if _pending_rebuild:
		return
	_pending_rebuild = true
	_rebuild_deferred.call_deferred()


func _rebuild_deferred() -> void:
	_pending_rebuild = false
	if is_inside_tree():
		_rebuild()


## ------------------------------------------------------------- the row payloads


func _listing_payload(id: StringName) -> Dictionary:
	for payload: Dictionary in _listings:
		if payload[&"id"] == id:
			return payload
	return {}


func _sell_payload(id: StringName) -> Dictionary:
	for payload: Dictionary in _sales:
		if payload[&"id"] == id:
			return payload
	return {}


## ------------------------------------------------------------ the focus and hover


func _on_action_pressed(payload: Dictionary, kind: StringName) -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	var row: Button = payload[&"row"]
	row.set_pressed_no_signal(true)
	_selected_row = row
	match kind:
		&"hull":
			buy_hull(payload[&"id"])
		&"listing":
			buy_listing(payload[&"id"])
		_:
			sell_row(payload[&"id"])


func _on_row_focused(row: Button, payload: Dictionary) -> void:
	AudioManager.play_ui(AudioManager.UiCue.HOVER)
	if _selected_row != null and _selected_row != row and is_instance_valid(_selected_row):
		_selected_row.set_pressed_no_signal(false)
	_selected_row = row
	row.set_pressed_no_signal(true)
	_set_status(_row_hint(payload), false)


func _on_row_hovered(payload: Dictionary, hovered: bool) -> void:
	var icon: TextureRect = payload[&"icon"]
	if icon == null:
		return
	var target := 1.0 if hovered else ROW_ICON_IDLE_ALPHA
	var tween := _make_tween()
	tween.tween_property(icon, "modulate:a", target, HOVER_SECONDS)


## The footer hint a focused row writes, in the OUTFITTING pane's own shape.
func _row_hint(payload: Dictionary) -> String:
	return STATUS_HINT % [
		String(payload.get(&"name", "")).to_upper(),
		_format_int(int(payload.get(&"cost", 0))),
		String(payload.get(&"action_word", ACTION_BUY)),
	]


## ------------------------------------------------------------------ the headers


## One section's column names and header words, in render order. The header word list is
## the same length as the cell list, so a section's columns and its captions cannot drift.
func _hulls_layout() -> Dictionary:
	return {&"cells": _hull_cells(), &"words": ["", HEADER_HULL, HEADER_PRICE, HEADER_ACTION]}


func _listings_layout() -> Dictionary:
	return {
		&"cells": _module_cells(),
		&"words": ["", HEADER_MODULE, HEADER_PRICE, HEADER_STATUS, HEADER_ACTION],
	}


func _sales_layout() -> Dictionary:
	return {
		&"cells": _sell_cells(),
		&"words": ["", HEADER_MODULE, HEADER_OWNED, HEADER_PRICE, HEADER_ACTION],
	}


func _hull_cells() -> Array[StringName]:
	return [&"Icon", &"ThemeBox", &"Price", &"Action"]


func _module_cells() -> Array[StringName]:
	return [&"Icon", &"ThemeBox", &"Price", &"Status", &"Action"]


func _sell_cells() -> Array[StringName]:
	return [&"Icon", &"ThemeBox", &"Owned", &"Price", &"Action"]


func _column_width(cell: StringName) -> float:
	match cell:
		&"Icon":
			return COL_ICON
		&"Owned":
			return COL_OWNED
		&"Price":
			return COL_PRICE
		&"Status":
			return COL_STATUS
		&"Action":
			return COL_ACTION
	return 0.0


func _build_header(header: HBoxContainer, layout: Dictionary) -> void:
	var cells: Array[StringName] = layout[&"cells"]
	var words: Array = layout[&"words"]
	for index in cells.size():
		header.add_child(_make_header_cell(String(words[index]), _column_width(cells[index])))


func _make_header_cell(text: String, width: float) -> Control:
	if text.is_empty():
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(width, 0.0)
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return spacer
	var label := Label.new()
	label.theme_type_variation = &"SectionHeader"
	label.text = text
	label.custom_minimum_size = Vector2(width, 0.0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL if width <= 0.0 else Control.SIZE_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _connect_layout() -> void:
	## A header cannot trust its declared column widths: a caption that outgrows its column
	## widens that cell, so any event that can move the rows' columns queues a re-fit of
	## that section's header onto its own rows' box.
	_sections.clear()
	_sections.append(_make_section(&"hulls", _hull_header, _hull_rows, _hull_cells()))
	_sections.append(_make_section(&"listings", _module_header, _module_rows, _module_cells()))
	_sections.append(_make_section(&"sales", _sell_header, _sell_rows, _sell_cells()))
	_scroll.resized.connect(_queue_header_fit)
	_scroll.get_v_scroll_bar().visibility_changed.connect(_queue_header_fit)
	for section: Dictionary in _sections:
		var header: HBoxContainer = section[&"header"]
		var rows: VBoxContainer = section[&"rows"]
		rows.resized.connect(_queue_section_fit.bind(section))
		header.resized.connect(_queue_section_fit.bind(section))


func _make_section(
	key: StringName, header: HBoxContainer, rows: VBoxContainer, cells: Array[StringName]
) -> Dictionary:
	return {
		&"key": key,
		&"header": header,
		&"rows": rows,
		&"cells": cells,
		&"queued": false,
		&"retries": 0,
	}


func _section_for(key: StringName) -> Dictionary:
	for section: Dictionary in _sections:
		if section.get(&"key", &"") == key:
			return section
	return {}


func _queue_header_fit() -> void:
	for section: Dictionary in _sections:
		_queue_section_fit(section)


func _queue_section_fit(section: Dictionary) -> void:
	if section.is_empty() or bool(section[&"queued"]):
		return
	section[&"queued"] = true
	_fit_section.call_deferred(section)


func _fit_section(section: Dictionary) -> void:
	## The header takes each declared column's width from the matching cell of the first
	## row's own grid, so a header caption's left edge is the value label's left edge in
	## every state. A panel built before its host has laid it out re-queues a few frames and
	## then leaves it to the layout signals above.
	section[&"queued"] = false
	var header: HBoxContainer = section[&"header"]
	var cells: Array[StringName] = section[&"cells"]
	var grid := _row_grid(section[&"rows"])
	if grid == null or grid.size.x <= 0.0 or size.x <= 0.0:
		if int(section[&"retries"]) < HEADER_FIT_RETRIES:
			section[&"retries"] = int(section[&"retries"]) + 1
			_queue_section_fit(section)
		return
	section[&"retries"] = 0
	var columns := mini(header.get_child_count(), cells.size())
	for index in columns:
		var head := header.get_child(index) as Control
		var cell := grid.get_node_or_null(NodePath(cells[index])) as Control
		if head == null or cell == null:
			continue
		## The cell's own minimum, not its laid-out width: a minimum is content driven and
		## settles in the same frame, so the header cannot be fitted from a grid that is
		## halfway through its own re-sort.
		if not is_equal_approx(
			head.custom_minimum_size.x, cell.get_combined_minimum_size().x
		):
			head.custom_minimum_size.x = cell.get_combined_minimum_size().x


func _row_grid(rows: VBoxContainer) -> HBoxContainer:
	for child: Node in rows.get_children():
		var row := child as Button
		if row == null:
			continue
		var inner := row.get_node_or_null(^"RowInner") as MarginContainer
		if inner == null:
			continue
		return inner.get_child(0) as HBoxContainer
	return null


func _connect_cells(box: HBoxContainer, section: Dictionary) -> void:
	if section.is_empty():
		return
	var cells: Array[StringName] = section[&"cells"]
	for cell_name: StringName in cells:
		var cell := box.get_node_or_null(NodePath(cell_name)) as Control
		if cell != null:
			cell.resized.connect(_queue_section_fit.bind(section))


func _connect_scroll() -> void:
	if _scroll.has_signal(&"scroll_started"):
		_scroll.connect(&"scroll_started", _on_scroll_started)


func _on_scroll_started() -> void:
	AudioManager.play_ui(AudioManager.UiCue.SCROLL)


## --------------------------------------------------------------------- tokens


## Re-applies the rarity tints after a theme change: the tint token each row carries is
## re-read from the theme rather than remembered as a colour.
func _apply_tokens() -> void:
	for payload: Dictionary in _listings + _sales:
		var title: Label = payload[&"title"]
		if title != null and is_instance_valid(title):
			title.add_theme_color_override(
				&"font_color", _rarity_color(StringName(payload.get(&"tint", &"rarity_common")))
			)


## One rarity's tint: the theme's `rarity_*` token first (STATION_HUB section 5.10's
## three, added to `vajb_theme.tres` this wave), the documented hexes only as the fallback
## the pin itself names.
func _rarity_color(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return AuctionScript.rarity_fallback(_rarity_of(token))


func _rarity_of(token: StringName) -> StringName:
	for rarity: Variant in AuctionScript.RARITY_TOKENS:
		if AuctionScript.RARITY_TOKENS[rarity] == token:
			return StringName(str(rarity))
	return &"common"


func _token(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.WHITE


## ------------------------------------------------------------------ the services


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


func _make_tween() -> Tween:
	for index in range(_tweens.size() - 1, -1, -1):
		if not _tweens[index].is_valid():
			_tweens.remove_at(index)
	var tween := create_tween()
	_tweens.append(tween)
	return tween


func _format_int(value: int) -> String:
	var digits := str(absi(value))
	var grouped := ""
	var count := 0
	for index in range(digits.length() - 1, -1, -1):
		grouped = digits[index] + grouped
		count += 1
		if count % 3 == 0 and index > 0:
			grouped = " " + grouped
	return ("-" if value < 0 else "") + grouped
