extends VBoxContainer
## EXCHANGE module panel: the hold list (what the station buys), the market board (both
## books) and the sale column (stepper, quote strip, actions). Every number on the panel is
## an Exchange read: the panel never recomputes a price from a baseline (05 section 8) and
## never runs a Timer (17 section 4) - it re-evaluates the market through
## `Exchange.evaluate_market` on entry and before every quote or sale.
##
## Contract: docs/design/STATION_HUB.md section 5.8 (amendment 2026-09-18), sections 3.1,
## 5.6, 10, 11 and 12.3/12.4; docs/gameplay/05_exchange.md sections 2 to 6 and 8.
##
## The station shell loads this scene into its host, so the panel never routes, never writes
## the profile and never draws the credits readout: it emits status_requested up and reads
## Exchange / MineralCatalog / ComponentCatalog / PlayerProfile down.
##
## Panel contract with the shell:
##   signal status_requested(message: String, danger: bool)   write the footer strip
##   func refresh_profile(key: StringName) -> void             react to profile_changed
##   func focus_primary() -> void                              focus entry after a switch
##   func disarm() -> bool                                     ui_cancel step 2

const TOKENS_TYPE: StringName = &"Tokens"

const ExchangeScript := preload("res://game/exchange.gd")
const MineralCatalog := preload("res://game/mineral_catalog.gd")
const ComponentCatalog := preload("res://game/component_catalog.gd")
const Clock := preload("res://autoload/world_clock.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"

signal status_requested(message: String, danger: bool)

## Section 12.3 constants, carried from the measured grid.
const ROW_HEIGHT := 76.0
const ROW_INNER_MARGIN := Vector2i(12, 8)
const COLUMN_SEPARATION := 12
const CELL_SEPARATION := 2
const STEPPER_SIZE := 48.0
const SELL_HEIGHT := 88.0
const ACTION_HEIGHT := 56.0
const COL_ICON := 40.0
const COL_QTY := 70.0
const COL_UNIT := 80.0
const COL_TOTAL := 100.0
const COL_PRICE := 80.0
const COL_DEMAND := 60.0
const COL_TREND := 95.0
const COL_STOCK := 80.0
const COL_FAMILY := 130.0
const COL_GRADE := 60.0
## The hold column's real width: what one 76 px row needs to seat its icon, its title, its
## three value cells and the row margins. `HoldBox` keeps section 5.8's 340 px floor in the
## scene; this is the measured content width that raises the column (see the P1i report for
## the arithmetic: section 5.8's 130/110/160 triple plus the 360 px trade column plus the
## board's own triple does not fit the 1440 px pane box).
const HOLD_CONTENT_WIDTH := 500.0
const ROW_ICON_IDLE_ALPHA := 0.72
const HOVER_SECONDS := 0.09
const PULSE_MIN_ALPHA := 0.35
const PULSE_DOWN_SECONDS := 0.12
const PULSE_UP_SECONDS := 0.16

const ICON_DIR := "res://assets/icons/"
const TINT_DIR := "res://assets/icons/tint/"
## ICONS_SPEC §8.1 names the dedicated mineral and ingot glyphs `icon_mineral_<id>_48.png` /
## `icon_ingot_<id>_48.png`. A row that carries one is drawn with that art as it is: the file
## name is the one signal that tells a dedicated glyph apart from the generic fallback,
## because `derive_icon_tints` writes a tint/ stencil for every icon, dedicated family
## included.
const DEDICATED_ICON_PREFIXES: Array[String] = ["icon_mineral_", "icon_ingot_"]

## 03 section 3's family names, by the family key the catalogue stores. A family this table
## does not name degrades to its own upper-cased key, never to a blank cell.
const FAMILY_LABELS: Dictionary = {
	&"salvage": "SALVAGE",
	&"mech": "MACHINERY",
	&"elec": "ELECTRONICS",
	&"weap": "WEAPONS",
	&"pow": "POWER",
	&"ore_grade": "ORE-GRADE",
}
const GRADE_NUMERALS: Array[String] = ["", "I", "II", "III"]

const META_ORE := "ORE"
const META_INGOT := "INGOT"
const META_SURPLUS := "SURPLUS"

const CAPTION_UNITS := "UNITS"
const CAPTION_CR_EACH := "CR EACH"
const CAPTION_CR_NET := "CR NET"
const CAPTION_INDEX := "INDEX"
const CAPTION_BAND := "BAND"
const CAPTION_QUOTA := "QUOTA"
const CAPTION_KIND := "KIND"
const CAPTION_GRADE := "GRADE"

const TAG_FORMAT := "TWO BOOKS · %d MINERALS · %d COMPONENTS"
const SUBTITLE := "MINERALS AND SURPLUS"

const HOLD_EMPTY := "HOLD EMPTY"
const NO_SELECTION := "NO STACK SELECTED"
const STEP_FORMAT := "%d UNITS"
const TITLE_FORMAT := "%s · %d HELD"
const CONFIRM_FORMAT := "SELL %d %s — GROSS %s · FEE %s · YOU GET %s"
const CONFIRM_IDLE := "SELECT A STACK · THE STRIP QUOTES THE CONFIRMED PRICE"
const DEMAND_FORMAT := "%sx"
## The mineral board row's meta line (05 §2): the ingot kind and the baseline the net PRICE
## cell is derived from; the demand index lives in its own column.
const BOARD_META_FORMAT := "INGOT · %s CR BASE"
const STOCK_FORMAT := "%d / %d"
const STATUS_HINT := "ENTER SELECT · %s · %s CR EACH"
const STATUS_SOLD := "SOLD · %d %s · +%s CR"
const STATUS_QUEUED := "STOCK FULL · %d UNITS QUEUED"
const STATUS_ALL := "SOLD ALL RAW · %d STACKS · +%s CR"
const STATUS_ALL_QUEUED := " · %d UNITS QUEUED"
const STATUS_REFUSED_EMPTY := "REFUSED · HOLD EMPTY"
const STATUS_REFUSED_RAW := "REFUSED · NO RAW STACK TO SELL"
const STATUS_REFUSED_UNKNOWN := "REFUSED · NOT FOR SALE"
const STATUS_REFUSED_QTY := "REFUSED · PICK AT LEAST ONE UNIT"
const STATUS_REFUSED_CARGO := "REFUSED · NOT ENOUGH IN THE HOLD"

const REASON_UNKNOWN: StringName = &"unknown_item"
const REASON_INVALID_QTY: StringName = &"invalid_qty"
const REASON_INSUFFICIENT_CARGO: StringName = &"insufficient_cargo"

@onready var _subtitle: Label = %PaneSubtitle
@onready var _tag: Label = %PanelTag
@onready var _pane_icon: TextureRect = %PaneIcon
@onready var _hold_rows: VBoxContainer = %HoldRows
@onready var _board_rows: VBoxContainer = %BoardRows
@onready var _hold_scroll: ScrollContainer = %HoldScroll
@onready var _board_scroll: ScrollContainer = %BoardScroll
@onready var _trade_title: Label = %TradeTitle
@onready var _step_minus: Button = %StepMinus
@onready var _step_value: Label = %StepValue
@onready var _step_plus: Button = %StepPlus
@onready var _confirm_strip: Label = %ConfirmStrip
@onready var _sell: Button = %SellButton
@onready var _sell_all: Button = %SellAllButton
@onready var _cancel: Button = %CancelButton

var _hold_ids: Array[StringName] = []
var _hold_payloads: Array[Dictionary] = []
var _board_payloads: Array[Dictionary] = []
var _selected_id: StringName = &""
var _selected_row: Button = null
var _step := 0
var _tweens: Array[Tween] = []


func _ready() -> void:
	## The one evaluation on entry (05 section 2 and 8); every quote and sale evaluates again.
	_evaluate()
	_hold_scroll.custom_minimum_size.x = HOLD_CONTENT_WIDTH
	_build_header()
	_build_board()
	_rebuild_hold()
	_apply_tokens()
	_connect_scroll()
	_wire_trade()
	_refresh_board()
	_refresh_trade()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_apply_tokens()


func _exit_tree() -> void:
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()


func refresh_profile(key: StringName) -> void:
	## Section 12.4: &"cargo" rebuilds the hold, &"credits" moves the quote and the board
	## cells. The exchange is not a buy shop, so there is no affordability to grey here: the
	## one price read is the quote the player is about to confirm.
	if key == &"cargo":
		_rebuild_hold()
		_refresh_board()
		_refresh_trade()
	elif key == &"credits":
		_refresh_board()
		_refresh_trade()


func focus_primary() -> void:
	## A disabled control must not take the ring: when nothing enabled can, the panel
	## returns without grabbing and the shell's rail fallback runs (station.gd:401-410).
	for payload: Dictionary in _hold_payloads:
		var row: Button = payload[&"row"]
		if not row.disabled:
			row.grab_focus()
			return
	if not _sell_all.disabled:
		_sell_all.grab_focus()


func disarm() -> bool:
	## ui_cancel step 2 (STATION_HUB section 2): the selection and the stepper own the first
	## cancel, and the shell keeps the ring where it is when this returns true.
	if _selected_id == &"" and _step == 0:
		return false
	_clear_selection()
	return true


func _apply_tokens() -> void:
	_pane_icon.modulate = _token(&"text_primary")
	for payload: Dictionary in _hold_payloads:
		_apply_icon_tokens(payload)
	for payload: Dictionary in _board_payloads:
		_apply_icon_tokens(payload)


func _apply_icon_tokens(payload: Dictionary) -> void:
	var icon: TextureRect = payload[&"icon"]
	if icon == null:
		return
	var tint: Color = payload[&"tint"]
	tint.a = ROW_ICON_IDLE_ALPHA
	icon.modulate = tint


func _token(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.WHITE


func _evaluate() -> void:
	var profile := _profile()
	if profile == null:
		return
	## One clock, one pricing function family: the market is advanced to now() here and
	## again inside every Exchange.quote / Exchange.sell call (05 section 8).
	ExchangeScript.evaluate_market(profile, Clock.now())


func _build_header() -> void:
	_subtitle.text = SUBTITLE
	_tag.text = TAG_FORMAT % [
		MineralCatalog.MINERALS.size(),
		ComponentCatalog.COMPONENTS.size(),
	]


## ---------------------------------------------------------------------------
## Market board
## ---------------------------------------------------------------------------


func _build_board() -> void:
	_board_payloads.clear()
	for spec: Dictionary in _board_specs():
		_board_payloads.append(_build_board_row(spec))
	_add_slack(_board_rows)
	for payload: Dictionary in _board_payloads:
		_apply_icon_tokens(payload)


func _board_specs() -> Array[Dictionary]:
	## 05 section 6: every mineral of the minerals book, then every component of the surplus
	## book, in catalogue order. The minerals row quotes the ingot form, which is the price
	## 05 section 2 and section 3 publish for a mineral.
	var specs: Array[Dictionary] = []
	for mineral_id: StringName in MineralCatalog.mineral_ids():
		var mineral: Dictionary = MineralCatalog.mineral(mineral_id)
		specs.append({
			&"item": MineralCatalog.ingot_id(mineral_id),
			&"mineral": mineral_id,
			&"name": String(mineral.get(&"name", String(mineral_id))).to_upper(),
			&"meta": META_INGOT,
			&"icon_path": String(mineral.get(&"icon_ingot", "")),
			&"tint": _tier_tint(int(mineral.get(&"tier", 0))),
			&"columns": [
				{&"key": &"price", &"width": COL_PRICE, &"caption": CAPTION_CR_EACH},
				{&"key": &"demand", &"width": COL_DEMAND, &"caption": CAPTION_INDEX},
				{&"key": &"trend", &"width": COL_TREND, &"caption": CAPTION_BAND},
			],
		})
	for entry: Dictionary in ComponentCatalog.COMPONENTS:
		var component_id: StringName = entry.get(&"id", &"")
		if component_id == &"":
			continue
		specs.append({
			&"item": component_id,
			&"mineral": &"",
			&"name": String(entry.get(&"name", String(component_id))).to_upper(),
			&"meta": META_SURPLUS,
			&"icon_path": String(entry.get(&"icon", "")),
			&"tint": _grade_tint(int(entry.get(&"grade", 0))),
			&"grade": int(entry.get(&"grade", 0)),
			&"family": String(entry.get(&"family", "")),
			&"columns": [
				{&"key": &"stock", &"width": COL_STOCK, &"caption": CAPTION_QUOTA},
				{&"key": &"family", &"width": COL_FAMILY, &"caption": CAPTION_KIND},
				{&"key": &"grade", &"width": COL_GRADE, &"caption": CAPTION_GRADE},
			],
		})
	return specs


func _build_board_row(spec: Dictionary) -> Dictionary:
	var row := Button.new()
	row.name = "Board%s" % String(spec[&"item"]).to_pascal_case()
	row.focus_mode = Control.FOCUS_NONE
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	var box := _make_inner(row)
	var icon := _make_icon(String(spec[&"icon_path"]))
	if icon != null:
		box.add_child(icon)
	var title_box := _make_title_box(String(spec[&"name"]), String(spec[&"meta"]))
	box.add_child(title_box)
	var payload := {
		&"item": spec[&"item"],
		&"mineral": spec[&"mineral"],
		&"grade_no": int(spec.get(&"grade", 0)),
		&"family_key": String(spec.get(&"family", "")),
		&"row": row,
		&"icon": icon,
		&"tint": _icon_tint(String(spec[&"icon_path"]), spec[&"tint"]),
		## The meta caption is the baseline and the demand of the row's own item (05 §2,
		## "the current price next to the baseline"), so the label is kept for refresh.
		&"meta": title_box.get_node("Meta") as Label,
	}
	for column: Dictionary in spec[&"columns"]:
		var cell := _make_cell(
			box, float(column[&"width"]), "", String(column[&"caption"]), String(column[&"key"])
		)
		payload[column[&"key"]] = cell[0]
	_board_rows.add_child(row)
	return payload


func _refresh_board() -> void:
	var profile := _profile()
	for payload: Dictionary in _board_payloads:
		var item_id: StringName = payload[&"item"]
		if ExchangeScript.is_component(item_id):
			_refresh_board_component(payload, profile)
		else:
			_refresh_board_mineral(payload, profile)


func _refresh_board_mineral(payload: Dictionary, profile: ProfileScript) -> void:
	var mineral_id: StringName = payload[&"mineral"]
	var demand := ExchangeScript.DEMAND_DEFAULT
	if profile != null:
		demand = ExchangeScript.demand_of(profile, mineral_id)
	(payload[&"price"] as Label).text = _format_int(
		ExchangeScript.exchange_price(payload[&"item"], demand)
	)
	(payload[&"demand"] as Label).text = DEMAND_FORMAT % String.num(demand, 1)
	(payload[&"trend"] as Label).text = ExchangeScript.trend_word(
		_trend_of(profile, mineral_id)
	)
	## 05 §2: the current price sits next to the baseline, so the row's meta line carries the
	## ingot kind and the baseline the net price is derived from.
	(payload[&"meta"] as Label).text = BOARD_META_FORMAT % [
		_format_int(ExchangeScript.baseline_of(payload[&"item"])),
	]


func _refresh_board_component(payload: Dictionary, profile: ProfileScript) -> void:
	var component_id: StringName = payload[&"item"]
	var grade := int(payload[&"grade_no"])
	var stock := 0
	if profile != null:
		stock = _stock_of(profile, component_id)
	(payload[&"stock"] as Label).text = STOCK_FORMAT % [
		stock, ExchangeScript.quota_for(grade)
	]
	(payload[&"family"] as Label).text = _family_label(payload[&"family_key"])
	(payload[&"grade"] as Label).text = _grade_label(grade)


## ---------------------------------------------------------------------------
## Hold
## ---------------------------------------------------------------------------


func _rebuild_hold() -> void:
	var profile := _profile()
	_hold_ids = _sellable_ids(profile)
	_clear(_hold_rows)
	_hold_payloads.clear()
	_selected_row = null
	if not _hold_ids.has(_selected_id):
		_selected_id = &""
		_step = 0
	if _hold_ids.is_empty():
		_hold_rows.add_child(_make_caption_row(HOLD_EMPTY, "HoldEmpty"))
		return
	for item_id: StringName in _hold_ids:
		_hold_payloads.append(_build_hold_row(item_id))
	_add_slack(_hold_rows)
	for payload: Dictionary in _hold_payloads:
		_apply_icon_tokens(payload)
	_restore_selection()


func _sellable_ids(profile: ProfileScript) -> Array[StringName]:
	## 05 section 8 ordering: the profile's hold filtered by Exchange.is_sellable, minerals in
	## catalogue order (ore then ingot per mineral), then components in catalogue order. An id
	## the exchange cannot price is not drawn at all.
	var ids: Array[StringName] = []
	if profile == null:
		return ids
	var cargo: Dictionary = profile.call(&"cargo_items")
	for mineral_id: StringName in MineralCatalog.mineral_ids():
		for item_id: StringName in [
			MineralCatalog.ore_id(mineral_id), MineralCatalog.ingot_id(mineral_id)
		]:
			if item_id != &"" and _qty(cargo, item_id) > 0 and ExchangeScript.is_sellable(item_id):
				ids.append(item_id)
	for entry: Dictionary in ComponentCatalog.COMPONENTS:
		var component_id: StringName = entry.get(&"id", &"")
		if (
			component_id != &""
			and _qty(cargo, component_id) > 0
			and ExchangeScript.is_sellable(component_id)
		):
			ids.append(component_id)
	return ids


func _build_hold_row(item_id: StringName) -> Dictionary:
	var row := Button.new()
	row.name = "Hold%s" % String(item_id).to_pascal_case()
	row.toggle_mode = true
	row.focus_mode = Control.FOCUS_ALL
	row.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row.set_meta(&"id", item_id)
	var box := _make_inner(row)
	var icon_path := _icon_path(item_id)
	var icon := _make_icon(icon_path)
	if icon != null:
		box.add_child(icon)
	box.add_child(_make_title_box(_item_name(item_id), _meta_of(item_id)))
	var qty := _make_cell(box, COL_QTY, "", CAPTION_UNITS, "Qty")
	var unit := _make_cell(box, COL_UNIT, "", CAPTION_CR_EACH, "Unit")
	var total := _make_cell(box, COL_TOTAL, "", CAPTION_CR_NET, "Total")
	var payload := {
		&"id": item_id,
		&"name": _item_name(item_id),
		&"row": row,
		&"icon": icon,
		&"tint": _icon_tint(icon_path, _tint_of(item_id)),
		&"qty": qty[0],
		&"unit": unit[0],
		&"total": total[0],
	}
	row.pressed.connect(_on_row_pressed.bind(payload))
	row.focus_entered.connect(_on_row_focused.bind(row, payload))
	row.mouse_entered.connect(_on_row_hovered.bind(payload, true))
	row.mouse_exited.connect(_on_row_hovered.bind(payload, false))
	_hold_rows.add_child(row)
	return payload


func _restore_selection() -> void:
	if _selected_id == &"":
		return
	for payload: Dictionary in _hold_payloads:
		if payload[&"id"] == _selected_id:
			var row: Button = payload[&"row"]
			row.set_pressed_no_signal(true)
			_selected_row = row
			return


func _refresh_hold() -> void:
	var profile := _profile()
	for payload: Dictionary in _hold_payloads:
		var item_id: StringName = payload[&"id"]
		var held := 0
		var demand := ExchangeScript.DEMAND_DEFAULT
		if profile != null:
			held = int(profile.call(&"cargo_qty", item_id))
			demand = ExchangeScript.demand_of(profile, MineralCatalog.mineral_id_of_item(item_id))
		(payload[&"qty"] as Label).text = _format_int(held)
		(payload[&"unit"] as Label).text = _format_int(
			ExchangeScript.exchange_price(item_id, demand)
		)
		var quote: Dictionary = _quote(profile, item_id, held)
		(payload[&"total"] as Label).text = _format_int(int(quote.get(&"paid", 0)))


func _row_hint(payload: Dictionary) -> String:
	return STATUS_HINT % [
		String(payload[&"name"]),
		_format_int(int(_quote(_profile(), payload[&"id"], 1).get(&"unit", 0))),
	]


## ---------------------------------------------------------------------------
## Sale column
## ---------------------------------------------------------------------------


func _wire_trade() -> void:
	_step_minus.pressed.connect(_on_step_pressed.bind(-1))
	_step_plus.pressed.connect(_on_step_pressed.bind(1))
	_sell.pressed.connect(_on_sell_pressed)
	_sell_all.pressed.connect(_on_sell_all_pressed)
	_cancel.pressed.connect(_on_cancel_pressed)


func _refresh_trade() -> void:
	var profile := _profile()
	var held := 0
	if profile != null and _selected_id != &"":
		held = int(profile.call(&"cargo_qty", _selected_id))
	if held <= 0:
		_selected_id = &""
		_step = 0
	if held > 0:
		_step = clampi(maxi(_step, 1), 1, held)
	var armed := held > 0 and _selected_id != &""
	var has_hold := not _hold_ids.is_empty()
	_trade_title.text = (
		TITLE_FORMAT % [_item_name(_selected_id), held] if armed
		else NO_SELECTION if has_hold
		else HOLD_EMPTY
	)
	_step_value.text = STEP_FORMAT % (_step if armed else 0)
	_step_minus.disabled = not armed
	_step_plus.disabled = not armed
	_sell.disabled = not armed
	_sell_all.disabled = not has_hold
	_cancel.disabled = not armed
	_confirm_strip.text = _confirm_text(profile) if armed else CONFIRM_IDLE
	_refresh_hold()


func _confirm_text(profile: ProfileScript) -> String:
	var quote: Dictionary = _quote(profile, _selected_id, _step)
	return CONFIRM_FORMAT % [
		_step,
		String(_selected_id).to_upper(),
		_format_int(int(quote.get(&"gross", 0))),
		_format_int(int(quote.get(&"fee", 0))),
		_format_int(int(quote.get(&"paid", 0))),
	]


func _select(item_id: StringName) -> void:
	var profile := _profile()
	var held := 0
	if profile != null:
		held = int(profile.call(&"cargo_qty", item_id))
	if item_id != _selected_id or _step <= 0:
		## 05 section 6: the stepper defaults to the whole stack.
		_step = held
	_selected_id = item_id
	_refresh_trade()


func _clear_selection() -> void:
	if _selected_row != null and is_instance_valid(_selected_row):
		_selected_row.set_pressed_no_signal(false)
	_selected_row = null
	_selected_id = &""
	_step = 0
	_refresh_trade()


func _set_step(value: int) -> void:
	var held := 0
	var profile := _profile()
	if profile != null and _selected_id != &"":
		held = int(profile.call(&"cargo_qty", _selected_id))
	_step = clampi(value, 1, maxi(1, held))
	_refresh_trade()


func _on_step_pressed(direction: int) -> void:
	AudioManager.play_ui(AudioManager.UiCue.SCROLL)
	if _selected_id == &"":
		return
	_set_step(_step + direction)


func _on_cancel_pressed() -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	_clear_selection()


func _on_sell_pressed() -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	var profile := _profile()
	if profile == null:
		return
	if _selected_id == &"" or _step <= 0:
		_deny(STATUS_REFUSED_EMPTY)
		return
	var item_id := _selected_id
	var quantity := _step
	var result: Dictionary = ExchangeScript.sell(profile, item_id, quantity, Clock.now())
	if not bool(result[&"ok"]):
		_deny(_reason_text(result[&"reason"]))
		return
	AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
	_after_sale()
	_announce_sale(item_id, result)


func _on_sell_all_pressed() -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	var profile := _profile()
	if profile == null:
		return
	if _hold_ids.is_empty():
		_deny(STATUS_REFUSED_EMPTY)
		return
	var result: Dictionary = ExchangeScript.sell_all(profile, Clock.now())
	var sold := 0
	var queued := 0
	for line: Dictionary in result[&"lines"]:
		if bool(line.get(&"ok", false)):
			sold += 1
		queued += int(line.get(&"queued", 0))
	_after_sale()
	if sold <= 0:
		_deny(STATUS_REFUSED_RAW)
		return
	AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
	var line := STATUS_ALL % [sold, _format_int(int(result[&"paid"]))]
	if queued > 0:
		line += STATUS_ALL_QUEUED % queued
	_report(line)


func _announce_sale(item_id: StringName, result: Dictionary) -> void:
	var queued := int(result[&"queued"])
	var line := ""
	if queued > 0:
		line = STATUS_QUEUED % queued
	else:
		line = STATUS_SOLD % [
			int(result[&"sellable"]),
			String(item_id).to_upper(),
			_format_int(int(result[&"paid"])),
		]
	_report(line)


func _after_sale() -> void:
	## Rows rebuild, the board restocks and the credits readout is the shell's (it hears
	## profile_changed); the quote is re-read only after the profile has settled.
	_selected_id = &""
	_step = 0
	_selected_row = null
	_evaluate()
	_rebuild_hold()
	_refresh_board()
	_refresh_trade()


func _report(line: String) -> void:
	_confirm_strip.text = line
	status_requested.emit(line, false)


func _deny(line: String) -> void:
	## Section 5.6: the strip text, one cue and a pulse. Focus and the selection stay put.
	AudioManager.play_ui(AudioManager.UiCue.DENIED)
	_confirm_strip.text = line
	status_requested.emit(line, true)
	_pulse(_confirm_strip)


func _reason_text(reason: StringName) -> String:
	match reason:
		REASON_UNKNOWN:
			return STATUS_REFUSED_UNKNOWN
		REASON_INVALID_QTY:
			return STATUS_REFUSED_QTY
		REASON_INSUFFICIENT_CARGO:
			return STATUS_REFUSED_CARGO
	return STATUS_REFUSED_UNKNOWN


func _on_row_focused(row: Button, payload: Dictionary) -> void:
	AudioManager.play_ui(AudioManager.UiCue.HOVER)
	if _selected_row != null and _selected_row != row and is_instance_valid(_selected_row):
		_selected_row.set_pressed_no_signal(false)
	_selected_row = row
	row.set_pressed_no_signal(true)
	_select(payload[&"id"])
	status_requested.emit(_row_hint(payload), false)


func _on_row_pressed(payload: Dictionary) -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	var row: Button = payload[&"row"]
	row.set_pressed_no_signal(true)
	_selected_row = row
	_select(payload[&"id"])


func _on_row_hovered(payload: Dictionary, hovered: bool) -> void:
	var icon: TextureRect = payload[&"icon"]
	if icon == null:
		return
	var target := 1.0 if hovered else ROW_ICON_IDLE_ALPHA
	var tween := _make_tween()
	tween.tween_property(icon, "modulate:a", target, HOVER_SECONDS)


func _connect_scroll() -> void:
	for scroll: ScrollContainer in [_hold_scroll, _board_scroll]:
		if scroll.has_signal(&"scroll_started"):
			scroll.connect(&"scroll_started", _on_scroll_started)


func _on_scroll_started() -> void:
	AudioManager.play_ui(AudioManager.UiCue.SCROLL)


## ---------------------------------------------------------------------------
## Builders and helpers
## ---------------------------------------------------------------------------


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


func _make_title_box(name_text: String, meta_text: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = "TitleBox"
	box.add_theme_constant_override(&"separation", CELL_SEPARATION)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := _make_label(&"StationValue", name_text, true)
	title.name = "Title"
	box.add_child(title)
	var meta := _make_label(&"StationCaption", meta_text, true)
	meta.name = "Meta"
	box.add_child(meta)
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


func _make_caption_row(text: String, node_name: String) -> Label:
	var label := _make_label(&"StationCaption", text)
	label.name = node_name
	return label


func _make_label(variation: StringName, text: String, trim := false) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if trim:
		## A row title is catalogue text of any length squeezed into a fixed column: it is
		## trimmed with an ellipsis instead of drawing over the next cell (a Label that never
		## fits its box would otherwise spill past the branch, because a Button is not a
		## Container and does not clip its children).
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return label


func _make_icon(icon_path: String) -> TextureRect:
	if icon_path.is_empty():
		return null
	var source := _tint_path(icon_path)
	if not ResourceLoader.exists(source):
		return null
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(COL_ICON, COL_ICON)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = load(source)
	return icon


func _add_slack(parent: VBoxContainer) -> void:
	var slack := Control.new()
	slack.name = "Slack"
	slack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(slack)


func _clear(parent: Node) -> void:
	for child: Node in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _icon_path(item_id: StringName) -> String:
	if MineralCatalog.is_ore(item_id):
		return String(MineralCatalog.entry_for_item(item_id).get(&"icon_ore", ""))
	if MineralCatalog.is_ingot(item_id):
		return String(MineralCatalog.entry_for_item(item_id).get(&"icon_ingot", ""))
	return String(ComponentCatalog.component(item_id).get(&"icon", ""))


func _tint_path(icon_path: String) -> String:
	## Every icon family is single-colour silhouette art (ICONS_SPEC §1), so the white tint/
	## stencil is the render source whenever one exists: the dedicated Phase F glyphs
	## (ICONS_SPEC §8.1) take `Tokens/text_primary` in `_icon_tint`, the generic 02 §6
	## fallback and the components take their tier / grade tint. The master path is the last
	## resort for art without a derived stencil.
	if not icon_path.begins_with(ICON_DIR):
		return icon_path
	var candidate := TINT_DIR + icon_path.get_file()
	if ResourceLoader.exists(candidate):
		return candidate
	return icon_path


## True for the dedicated Phase F glyph names (`icon_mineral_<id>_48` / `icon_ingot_<id>_48`).
func _is_dedicated_icon(icon_path: String) -> bool:
	var file_name := icon_path.get_file()
	for prefix: String in DEDICATED_ICON_PREFIXES:
		if file_name.begins_with(prefix):
			return true
	return false


## The row ink for one icon: a dedicated glyph reads as neutral state art (ICONS_SPEC §1 and
## §8.6's retired fallback), everything else through its tier / grade tint. A master without
## a derived stencil draws at full colour.
func _icon_tint(icon_path: String, tint: Color) -> Color:
	if not _tint_path(icon_path).begins_with(TINT_DIR):
		var plain := Color.WHITE
		plain.a = ROW_ICON_IDLE_ALPHA
		return plain
	var ink := _token(&"text_primary") if _is_dedicated_icon(icon_path) else tint
	ink.a = ROW_ICON_IDLE_ALPHA
	return ink


func _tint_of(item_id: StringName) -> Color:
	if ExchangeScript.is_component(item_id):
		return _grade_tint(int(ComponentCatalog.component(item_id).get(&"grade", 0)))
	return _tier_tint(int(MineralCatalog.entry_for_item(item_id).get(&"tier", 0)))


func _tier_tint(tier: int) -> Color:
	if MineralCatalog.TIER_TINTS.has(tier):
		return MineralCatalog.TIER_TINTS[tier]
	return Color.WHITE


func _grade_tint(grade: int) -> Color:
	if ComponentCatalog.GRADE_TINTS.has(grade):
		return ComponentCatalog.GRADE_TINTS[grade]
	return Color.WHITE


func _item_name(item_id: StringName) -> String:
	if item_id == &"":
		return ""
	if MineralCatalog.is_ore(item_id):
		return "%s ORE" % String(
			MineralCatalog.entry_for_item(item_id).get(&"name", String(item_id))
		).to_upper()
	if MineralCatalog.is_ingot(item_id):
		return "%s INGOT" % String(
			MineralCatalog.entry_for_item(item_id).get(&"name", String(item_id))
		).to_upper()
	return String(ComponentCatalog.component(item_id).get(&"name", String(item_id))).to_upper()


func _meta_of(item_id: StringName) -> String:
	if MineralCatalog.is_ore(item_id):
		return META_ORE
	if MineralCatalog.is_ingot(item_id):
		return META_INGOT
	return _family_label(ComponentCatalog.component(item_id).get(&"family", &""))


func _family_label(family: Variant) -> String:
	var key := StringName(family)
	if FAMILY_LABELS.has(key):
		return String(FAMILY_LABELS[key])
	if key == &"":
		return ""
	return String(key).to_upper()


func _grade_label(grade: int) -> String:
	if grade >= 0 and grade < GRADE_NUMERALS.size():
		return GRADE_NUMERALS[grade]
	return str(grade)


func _quote(profile: ProfileScript, item_id: StringName, quantity: int) -> Dictionary:
	if profile == null or item_id == &"" or quantity <= 0:
		return {}
	## The one price read (05 section 8): every displayed figure comes from Exchange.quote or
	## Exchange.exchange_price, and the market re-evaluates on the way in.
	return ExchangeScript.quote(profile, item_id, quantity, Clock.now())


func _qty(cargo: Dictionary, item_id: StringName) -> int:
	if cargo.has(item_id):
		return int(cargo[item_id])
	return int(cargo.get(String(item_id), 0))


func _stock_of(profile: ProfileScript, component_id: StringName) -> int:
	if profile == null:
		return 0
	var bucket: Variant = _bucket(profile.call(&"market"), &"stock")
	if bucket is Dictionary:
		var stock: Dictionary = bucket
		if stock.has(component_id):
			return int(stock[component_id])
		return int(stock.get(String(component_id), 0))
	return 0


func _trend_of(profile: ProfileScript, mineral_id: StringName) -> int:
	if profile == null:
		return 0
	var bucket: Variant = _bucket(profile.call(&"market"), &"trend")
	if bucket is Dictionary:
		var trend: Dictionary = bucket
		if trend.has(mineral_id):
			return int(trend[mineral_id])
		return int(trend.get(String(mineral_id), 0))
	return 0


func _bucket(market: Dictionary, key: StringName) -> Variant:
	if market.has(key):
		return market[key]
	return market.get(String(key), null)


func _profile() -> ProfileScript:
	## Autoloads are children of /root; STATION_HUB section 12.4 names a bare
	## ^"PlayerProfile" path, which would resolve against this node instead, so the lookup is
	## anchored at the tree root the way router.gd anchors its services.
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
