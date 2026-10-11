extends VBoxContainer
## CONTRACTS panel (S25): 14_station_services.md section 2's board as the SERVICES deck's
## one shipped service - the six-row job list (R-S25-1) on the left, the active contracts
## and their escrow on the right. Contract: docs/design/STATION_HUB.md section 15.2 (the
## deck law: the U3 header strip and note, the board row anatomy, the ACCEPT pressable, the
## U6 max-3 counter and chip, the U7 Expedition staged row, the U5 escrow readout, the U4
## cancel affordance and its confirm dialog, the two U8 empty states, and - S38 - the U22
## roll countdown at the U3 strip's right end with its 1 Hz tick and the re-roll at the band
## boundary) plus section 5.2 (the confirm dialog's own idiom) and section 19.3/19.4 (the
## pane skeleton this content sits in, which the shell owns).
##
## **S38 (14's 2026-10-08 S38 block, H2/H3).** The readout is `WorldClock.BAND_SECONDS`
## minus `now` modulo it, read live at 1 Hz (never a value written once at build), and the
## board re-rolls in place the moment the band changes. Riders: U7's staged row dims whole
## (T-156) and an accepted row leaves the board so one id cannot be accepted twice in a band
## (T-157).
##
## The panel never prices, never pays and never writes the profile directly: every number is
## a `ContractRegistry` read and every write is a `ContractRegistry` transaction, which in
## turn calls only the profile's own public API. The confirm dialog is the shell's (§5.2's
## overlay lives on the screen's dialog layer, not inside a pane), so the panel asks for it
## through `confirm_requested` and the shell answers with `confirm_action`.
##
## Panel contract with the shell (the shipped duck-typed contract):
##   signal status_requested(message: String, danger: bool)   write the footer strip
##   signal inspect_requested(title: String, body: String, danger: bool)  the hover tooltip
##   signal confirm_requested(payload: Dictionary)             open the section 5.2 dialog
##   func refresh_profile(key: StringName) -> void             react to profile_changed
##   func focus_primary() -> void                              focus entry after a switch
##   func confirm_action(action: StringName, id: StringName)   the dialog's answer

const TOKENS_TYPE: StringName = &"Tokens"
const ChromeFamily := preload("res://ui/theme/chrome_family.gd")

const ContractRegistryScript := preload("res://game/contract_registry.gd")
const StationRegistryScript := preload("res://game/station_registry.gd")
const SectorRegistryScript := preload("res://game/sector_registry.gd")
const MineralCatalogScript := preload("res://game/mineral_catalog.gd")
## The one 20-minute station clock (14 section 9): the countdown's constants come from it,
## never re-derived, never hardcoded.
const Clock := preload("res://autoload/world_clock.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"

signal status_requested(message: String, danger: bool)
signal inspect_requested(title: String, body: String, danger: bool)
## U4's confirm: the payload carries the section 5.2 dialog's four fields plus the action
## the shell hands back through `confirm_action`.
signal confirm_requested(payload: Dictionary)

## STATION_HUB section 15.2's board row and the section 3.1 idiom it wears.
const ROW_HEIGHT := 76.0
const ROW_INNER_MARGIN := Vector2i(12, 8)
const COLUMN_SEPARATION := 12
const CELL_SEPARATION := 2
const COL_TYPE := 140.0
const COL_REWARD := 220.0
const COL_FACTION := 130.0
const ROW_ICON := 24.0
const COLUMN_WIDTH := 420.0
const ACTION_INLINE := Vector2(96.0, 32.0)
const CARD_SEPARATION := 6
const CARD_INNER_MARGIN := 12

## U3's four column headers, verbatim, and the note under them.
const PANEL_TITLE := "CONTRACTS"
const HEADER_TYPE := "TYPE"
const HEADER_OBJECTIVE := "OBJECTIVE"
const HEADER_REWARD := "REWARD"
const HEADER_FACTION := "FACTION"
const NOTE_U3 := (
	"THE BOARD PAYS OVER THE EXCHANGE'S BUY PRICE — GOODS LOCK INTO ESCROW AT ACCEPT · "
	+ "CANCEL FEE 100 CR"
)

## U4's own wordings.
const ACTION_ACCEPT := "ACCEPT"
const ACTION_CANCEL := "CANCEL · 100 CR FEE"
const CONFIRM_BODY := "CANCEL THIS CONTRACT? — 100 CR FEE · THE RESERVED GOODS UNLOCK."
const CONFIRM_TITLE := "CANCEL THIS CONTRACT?"
const CONFIRM_ACTION: StringName = &"cancel_contract"
## UI_SPEC section 5.2's own button words.
const CONFIRM_YES := "CONFIRM"
const CONFIRM_NO := "CANCEL"

## U5's escrow readout, verbatim.
const ESCROW_HEADER := "ESCROW — RESERVED FROM YOUR HOLD"
const ESCROW_LINE := "%d× %s · RESERVED"

## U6's counter and chip, verbatim (the format is the deck law's own `%d/3`).
const COUNTER_FORMAT := "ACTIVE CONTRACTS %d/3"
const CHIP_MAX := "MAX 3 ACTIVE"
## U7's chip and caption, verbatim.
const CHIP_STAGED := "STAGED"
const CAPTION_STAGED := "arenas arrive with S26"

## U8's two empty states, verbatim (the second is 14 section 2's own line).
const EMPTY_NO_JOBS := "NO OPEN JOBS — NEW JOBS ROLL ON THE 20-MINUTE CLOCK"
const EMPTY_GATED := "REDEMPTION MUST PRECEDE EMPLOYMENT"

## The standing the reward cell prints beside the figure (14 section 2's own column).
const STANDING_FORMAT := "+%d STANDING"
const STANDING_NEGATIVE_FORMAT := "%d STANDING"

## The pane's foot hint (STATION_HUB section 19.4's SERVICES row, tick P29).
const PANE_HINT := "ONE SERVICE AT A TIME · ESC BACK"

## U22 (STATION_HUB section 15.2, 14's 2026-10-08 S38 block H2/H3): the roll countdown at
## the U3 header strip's right end. The figure is always `WorldClock.BAND_SECONDS` minus
## `now` modulo it, read live at 1 Hz (the refinery panel's own `TICK_SECONDS` idiom), so a
## readout that disagrees with the rows behind it cannot happen; at the band boundary the
## panel re-rolls itself once. Reversal: the U8 caption alone, no countdown.
const TICK_SECONDS := 1.0
const ROLL_FORMAT := "NEW JOBS IN %s"

## The refusal and outcome lines the shell's status strip carries. PROPOSED (no doc pins a
## contract refusal wording; the shapes follow station.gd's own `REFUSED · …` copy and
## 09 section 2's `<n> NEEDED` idiom). Reversal: silent refusals.
const REFUSED_FULL := "REFUSED · MAX 3 ACTIVE"
const REFUSED_STAGED := "REFUSED · STAGED"
const REFUSED_CARGO := "REFUSED · %d× %s NEEDED"
const REFUSED_UNAVAILABLE := "REFUSED · NOT AVAILABLE"
const ACCEPTED_FORMAT := "ACCEPTED · %s"
const CANCELLED_FORMAT := "CONTRACT CANCELLED · %d CR FEE"

const FACTION_ICON_TEMPLATE := "res://assets/icons/tint/icon_insignia_%s_48.png"

@onready var _pane_icon: TextureRect = %PaneIcon
@onready var _pane_title: Label = %PaneTitle
@onready var _header_row: HBoxContainer = %HeaderRow
@onready var _note: Label = %BoardNote
@onready var _board_list: VBoxContainer = %BoardList
@onready var _board_empty: Label = %BoardEmpty
@onready var _counter: Label = %ActiveCounter
@onready var _chip: PanelContainer = %ActiveChip
@onready var _chip_label: Label = %ActiveChipLabel
@onready var _active_list: VBoxContainer = %ActiveList
@onready var _pane_hint: Label = %PaneHint

var _board: Array[Dictionary] = []
var _active: Array[Dictionary] = []
var _standing := 0
var _station_row: Dictionary = {}
var _empty_text := ""
var _accept_buttons: Array[Button] = []
var _cancel_buttons: Dictionary = {}
var _escrow_lines: Array[String] = []
var _card_labels: Array[String] = []
## U22's readout node (built with the U3 headers) and its 1 Hz tick.
var _roll_label: Label = null
var _tick_timer: Timer = null
## The band the drawn board was rolled in, so a boundary re-roll is one comparison.
var _board_band := -1
## U7 (T-156): the staged rows' inner boxes, dimmed whole in `_apply_tokens`.
var _dim_rows: Array[Control] = []


func _ready() -> void:
	_pane_icon.custom_minimum_size = Vector2(40.0, 40.0)
	_pane_icon.texture = _load_texture(ContractRegistryScript.icon_for(
		ContractRegistryScript.TYPE_HAUL
	))
	_pane_title.text = PANEL_TITLE
	_note.text = NOTE_U3
	_pane_hint.text = PANE_HINT
	_build_headers()
	_chip_label.text = CHIP_MAX
	_refresh()
	_make_tick_timer()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_apply_tokens()


## The shell's own panel contract: a profile write (credits, cargo, contracts, standing)
## re-reads the board, because every one of them can move a row's reward or its state.
func refresh_profile(_key: StringName) -> void:
	if is_node_ready():
		_refresh()


func focus_primary() -> void:
	for button: Button in _accept_buttons:
		if not button.disabled:
			button.grab_focus()
			return
	if _board_list.get_child_count() > 0:
		var first := _board_list.get_child(0) as Control
		if first != null:
			first.grab_focus()


## The shell's answer to `confirm_requested`: the one action this panel asks about.
func confirm_action(action: StringName, id: StringName) -> void:
	if action != CONFIRM_ACTION:
		return
	_cancel(id)


## ------------------------------------------------------------------ the board half


func _build_headers() -> void:
	for column: Dictionary in [
		{&"text": HEADER_TYPE, &"width": COL_TYPE},
		{&"text": HEADER_OBJECTIVE, &"width": 0.0},
		{&"text": HEADER_REWARD, &"width": COL_REWARD},
		{&"text": HEADER_FACTION, &"width": COL_FACTION},
	]:
		var label := Label.new()
		label.name = "Header%s" % String(column[&"text"]).capitalize()
		label.theme_type_variation = &"SectionHeader"
		label.text = String(column[&"text"])
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var width := float(column[&"width"])
		if width > 0.0:
			label.custom_minimum_size = Vector2(width, 0.0)
		else:
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_header_row.add_child(label)
	## U22: the roll countdown sits at the strip's right end - the OBJECTIVE header expands,
	## so the readout, as the last child, is pushed there by the container itself.
	_roll_label = Label.new()
	_roll_label.name = "RollCountdown"
	_roll_label.theme_type_variation = &"StationCaption"
	_roll_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_roll_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_roll_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	_roll_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_header_row.add_child(_roll_label)
	_sync_roll_readout()


## One board row: STATION_HUB section 15.2's own anatomy, the AUCTION row idiom (a `Button`
## carrying its own children) on the A5.4-4 flat Tokens box.
func _build_board_row(contract: Dictionary) -> Button:
	var type := StringName(contract.get(&"type", &""))
	var staged := bool(contract.get(&"staged", false))
	var row := Button.new()
	row.name = "Contract%s" % String(contract.get(&"id", &"")).to_pascal_case()
	row.toggle_mode = true
	row.focus_mode = Control.FOCUS_ALL
	row.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row.disabled = staged
	row.set_meta(&"id", contract.get(&"id", &""))
	ChromeFamily.apply_row(row)
	var inner := MarginContainer.new()
	inner.name = "RowInner"
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override(&"margin_left", ROW_INNER_MARGIN.x)
	inner.add_theme_constant_override(&"margin_top", ROW_INNER_MARGIN.y)
	inner.add_theme_constant_override(&"margin_right", ROW_INNER_MARGIN.x)
	inner.add_theme_constant_override(&"margin_bottom", ROW_INNER_MARGIN.y)
	row.add_child(inner)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := HBoxContainer.new()
	box.name = "RowBox"
	box.add_theme_constant_override(&"separation", COLUMN_SEPARATION)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(box)
	## type: the shipped icon in its own rect + the section 2 type name
	var type_cell := _make_hbox(box, COL_TYPE)
	var icon := _make_icon(ContractRegistryScript.icon_for(type), ROW_ICON)
	if icon != null:
		type_cell.add_child(icon)
	var type_label := _make_label(&"StationValue", ContractRegistryScript.label_for(type))
	type_label.name = "TypeLabel"
	type_cell.add_child(type_label)
	## objective: section 2's own line for the row, verbatim
	var objective := _make_label(&"", String(contract.get(&"objective", "")))
	objective.name = "ObjectiveLabel"
	objective.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(objective)
	## reward: the figure right-aligned, the standing under it
	var reward_cell := _make_vbox(box, COL_REWARD)
	var reward := _make_label(&"StationValue", _figure_text(contract))
	reward.name = "RewardLabel"
	reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	reward_cell.add_child(reward)
	var standing := _make_label(&"StationCaption", _standing_text(contract))
	standing.name = "StandingLabel"
	standing.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	reward_cell.add_child(standing)
	## faction: the owner's glyph + its name
	var faction := StringName(contract.get(&"faction", &""))
	var faction_cell := _make_hbox(box, COL_FACTION)
	var glyph := _make_icon(FACTION_ICON_TEMPLATE % String(faction), ROW_ICON)
	if glyph != null:
		faction_cell.add_child(glyph)
	var faction_label := _make_label(&"StationCaption", String(faction).to_upper())
	faction_label.name = "FactionLabel"
	faction_cell.add_child(faction_label)
	## the ACCEPT pressable (U4's word) - disabled at the max-3 state (U6) or when staged (U7)
	var accept := _make_action(ACTION_ACCEPT)
	if staged:
		accept.text = CHIP_STAGED
		accept.disabled = true
	elif _at_max():
		accept.text = CHIP_MAX
		accept.disabled = true
	else:
		accept.pressed.connect(_on_accept_pressed.bind(StringName(contract.get(&"id", &""))))
		_accept_buttons.append(accept)
	box.add_child(accept)
	if staged:
		var caption := _make_label(&"StationCaption", CAPTION_STAGED)
		caption.name = "StagedCaption"
		box.add_child(caption)
		## U7 (T-156): the staged Expedition row greys **whole** - the one modulate on the
		## row's inner box tints every cell under it, the type icon included. Applied in
		## `_apply_tokens` so a theme change re-reads the token.
		_dim_rows.append(inner)
	return row


## One active-contract card: two stack rows - the board row's anatomy (the head) over
## one action row carrying the escrow readout (U5) with the cancel affordance (U4)
## right-aligned beside it (S41, D23 F13).
func _build_active_card(contract: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "Active%s" % String(contract.get(&"id", &"")).to_pascal_case()
	card.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	ChromeFamily.apply_row_panel(card)
	var inner := MarginContainer.new()
	inner.name = "CardInner"
	for side: String in ["left", "top", "right", "bottom"]:
		inner.add_theme_constant_override(StringName("margin_" + side), CARD_INNER_MARGIN)
	card.add_child(inner)
	var stack := VBoxContainer.new()
	stack.name = "CardBox"
	stack.add_theme_constant_override(&"separation", CELL_SEPARATION)
	inner.add_child(stack)
	var type := StringName(contract.get(&"type", &""))
	var head := HBoxContainer.new()
	head.name = "CardHead"
	head.add_theme_constant_override(&"separation", COLUMN_SEPARATION)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(head)
	var icon := _make_icon(ContractRegistryScript.icon_for(type), ROW_ICON)
	if icon != null:
		head.add_child(icon)
	var title := _make_label(&"StationValue", ContractRegistryScript.label_for(type))
	title.name = "CardType"
	head.add_child(title)
	var objective := _make_label(&"", String(contract.get(&"objective", "")))
	objective.name = "CardObjective"
	objective.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(objective)
	var reward := _make_label(&"StationValue", _figure_text(contract))
	reward.name = "CardReward"
	reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	reward.custom_minimum_size = Vector2(COL_REWARD, 0.0)
	head.add_child(reward)
	var glyph := _make_icon(
		FACTION_ICON_TEMPLATE % String(contract.get(&"faction", &"")), ROW_ICON
	)
	if glyph != null:
		head.add_child(glyph)
	## S41 (D23 F13): the card is two stack rows - the head, then one action row that
	## carries the escrow summary with CANCEL right-aligned, so the chip shares the row
	## instead of crowding the reward figure below it. Container children only.
	var action_row := HBoxContainer.new()
	action_row.name = "CardActionRow"
	action_row.add_theme_constant_override(&"separation", COLUMN_SEPARATION)
	action_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(action_row)
	## U5's escrow readout, one caption line per reserved stack (its own column in the
	## action row, so it pushes the CANCEL chip to the right edge even when empty).
	var escrow_box := VBoxContainer.new()
	escrow_box.name = "CardEscrow"
	escrow_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	escrow_box.add_theme_constant_override(&"separation", CELL_SEPARATION)
	escrow_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_row.add_child(escrow_box)
	var escrow: Dictionary = contract.get(&"escrow", {})
	if not escrow.is_empty():
		var header := _make_label(&"StationCaption", ESCROW_HEADER)
		header.name = "EscrowHeader"
		escrow_box.add_child(header)
		_escrow_lines.append(ESCROW_HEADER)
		for key: Variant in escrow:
			var line := ESCROW_LINE % [int(escrow[key]), String(key)]
			var label := _make_label(&"StationCaption", line)
			label.name = "Escrow%s" % String(key).to_pascal_case()
			escrow_box.add_child(label)
			_escrow_lines.append(line)
	## U4's cancel affordance, the fee at the decision point.
	var cancel := _make_action(ACTION_CANCEL)
	cancel.name = "CancelButton"
	cancel.size_flags_horizontal = Control.SIZE_SHRINK_END
	cancel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cancel.pressed.connect(_on_cancel_pressed.bind(StringName(contract.get(&"id", &""))))
	action_row.add_child(cancel)
	_cancel_buttons[String(contract.get(&"id", &""))] = cancel
	return card


## ------------------------------------------------------------------ the transactions


func _on_accept_pressed(id: StringName) -> void:
	var result := accept(id)
	if bool(result.get(&"ok", false)):
		status_requested.emit(
			ACCEPTED_FORMAT % String((result[&"contract"] as Dictionary).get(&"objective", "")),
			false
		)
		return
	status_requested.emit(_refusal_text(result), true)


## The one accept door the panel (and a probe) uses: the registry's transaction, then a
## rebuild. A refusal writes nothing and the board is left byte-identical.
func accept(id: StringName) -> Dictionary:
	var profile := _profile()
	var contract := _find(id)
	if profile == null or contract.is_empty():
		return {&"ok": false, &"reason": ContractRegistryScript.REASON_UNKNOWN, &"contract": {}}
	var result := ContractRegistryScript.accept(profile, _station_row, _standing, contract)
	if bool(result.get(&"ok", false)):
		_refresh()
	return result


func _on_cancel_pressed(id: StringName) -> void:
	confirm_requested.emit(
		{
			&"id": id,
			&"title": CONFIRM_TITLE,
			&"body": CONFIRM_BODY,
			&"confirm_text": CONFIRM_YES,
			&"cancel_text": CONFIRM_NO,
			&"action": CONFIRM_ACTION,
		}
	)


## The confirm's own answer: the cancel transaction (100 CR, the goods unlock).
func _cancel(id: StringName) -> void:
	var profile := _profile()
	if profile == null:
		return
	var result := ContractRegistryScript.cancel(profile, id)
	if bool(result.get(&"ok", false)):
		status_requested.emit(
			CANCELLED_FORMAT % int(result.get(&"fee", 0)), false
		)
	else:
		status_requested.emit(_refusal_text(result), true)
	_refresh()


func _refusal_text(result: Dictionary) -> String:
	var reason := StringName(result.get(&"reason", &""))
	match reason:
		ContractRegistryScript.REASON_FULL:
			return REFUSED_FULL
		ContractRegistryScript.REASON_STAGED:
			return REFUSED_STAGED
		ContractRegistryScript.REASON_INSUFFICIENT_CARGO:
			var contract: Dictionary = result.get(&"contract", {})
			return REFUSED_CARGO % [
				int(contract.get(&"quantity", 0)), String(contract.get(&"item_id", &""))
			]
		ContractRegistryScript.REASON_INSUFFICIENT_CREDITS:
			return REFUSED_UNAVAILABLE
	return REFUSED_UNAVAILABLE


## ------------------------------------------------------------------ the rebuild


func _refresh() -> void:
	if not is_node_ready():
		return
	var profile := _profile()
	_station_row = StationRegistryScript.docked_station(profile)
	_standing = _station_standing(profile)
	_active = ContractRegistryScript.active(profile)
	_board = _without_active(ContractRegistryScript.board(_station_row, _standing), _active)
	## The band this board was rolled in: `_tick` re-rolls when the clock leaves it (H3).
	_board_band = ContractRegistryScript.band_index()
	_clear_list(_board_list)
	_clear_list(_active_list)
	_accept_buttons.clear()
	_cancel_buttons.clear()
	_escrow_lines.clear()
	_card_labels.clear()
	_dim_rows.clear()
	var gated := not _station_row.is_empty() and not ContractRegistryScript.visible(_standing)
	for contract: Dictionary in _board:
		_board_list.add_child(_build_board_row(contract))
	for contract: Dictionary in _active:
		_active_list.add_child(_build_active_card(contract))
	_empty_text = ""
	if _board.is_empty():
		_empty_text = EMPTY_GATED if gated else EMPTY_NO_JOBS
	_board_empty.text = _empty_text
	_board_empty.visible = not _empty_text.is_empty()
	_counter.text = COUNTER_FORMAT % _active.size()
	_chip.visible = _at_max()
	_sync_roll_readout()
	_apply_tokens()


## T-157: a row whose id is already active has been accepted this band - the seeded re-roll
## would re-present it, so it leaves the board and the same id cannot be accepted twice.
func _without_active(
	rows: Array[Dictionary], active: Array[Dictionary]
) -> Array[Dictionary]:
	if active.is_empty():
		return rows
	var taken: Dictionary = {}
	for record: Dictionary in active:
		taken[String(record.get(&"id", &""))] = true
	var out: Array[Dictionary] = []
	for row: Dictionary in rows:
		if taken.has(String(row.get(&"id", &""))):
			continue
		out.append(row)
	return out


## ------------------------------------------------------------------ U22: the countdown


## The refinery panel's tick idiom (`refinery_panel.gd:250`): one 1 Hz Timer, no polling.
## It runs whether or not the deck is showing it - the readout is a clock, not a job queue,
## so the band boundary is never missed (H3: "no player action").
func _make_tick_timer() -> void:
	_tick_timer = Timer.new()
	_tick_timer.name = "ContractsTick"
	_tick_timer.one_shot = false
	_tick_timer.wait_time = TICK_SECONDS
	_tick_timer.autostart = true
	_tick_timer.timeout.connect(_tick)
	add_child(_tick_timer)


## U22's 1 Hz tick: the readout follows the clock, and the board re-rolls the moment the
## band changes - one `_refresh()`, no scene change and no player action (H3).
func _tick() -> void:
	if not is_node_ready():
		return
	_sync_roll_readout()
	var band := ContractRegistryScript.band_index()
	if band != _board_band:
		_refresh()


## H2's figure: `WorldClock.BAND_SECONDS - now % WorldClock.BAND_SECONDS`, so it reads
## 20:00 at the boundary and never disagrees with the band the rows were rolled in.
func _roll_remaining() -> int:
	return Clock.BAND_SECONDS - Clock.now() % Clock.BAND_SECONDS


func _sync_roll_readout() -> void:
	if _roll_label == null:
		return
	_roll_label.text = ROLL_FORMAT % _mmss(_roll_remaining())


## The refinery panel's own `_mmss` shape (`refinery_panel.gd:1191`): two-digit minutes.
func _mmss(seconds: int) -> String:
	var clamped := maxi(seconds, 0)
	@warning_ignore("integer_division")
	var minutes := clamped / 60
	return "%02d:%02d" % [minutes, clamped % 60]


func _at_max() -> bool:
	return _active.size() >= ContractRegistryScript.MAX_ACTIVE


func _find(id: StringName) -> Dictionary:
	for contract: Dictionary in _board:
		if StringName(contract.get(&"id", &"")) == id:
			return contract
	return {}


func _figure_text(contract: Dictionary) -> String:
	## The staged Expedition row prices nothing yet (14 section 2's "arena payout" is S26's),
	## so its reward cell stays empty and U7's caption carries the state.
	if bool(contract.get(&"staged", false)):
		return ""
	return "%d CR" % ContractRegistryScript.pay(contract, _standing)


func _standing_text(contract: Dictionary) -> String:
	var delta := int(contract.get(&"standing", 0))
	if delta < 0:
		return STANDING_NEGATIVE_FORMAT % delta
	return STANDING_FORMAT % delta


func _profile() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null(NodePath(PROFILE_SERVICE))


func _station_standing(profile: Node) -> int:
	if profile == null or _station_row.is_empty():
		return 0
	return int(
		profile.call(&"standing_of", StringName(_station_row.get(&"faction", &"")))
	)


func _clear_list(list: VBoxContainer) -> void:
	for child: Node in list.get_children():
		list.remove_child(child)
		child.queue_free()


## ------------------------------------------------------------------ the small builders


func _make_hbox(parent: Control, width: float) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override(&"separation", CELL_SEPARATION)
	box.custom_minimum_size = Vector2(width, 0.0)
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(box)
	return box


func _make_vbox(parent: Control, width: float) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", CELL_SEPARATION)
	box.custom_minimum_size = Vector2(width, 0.0)
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(box)
	return box


func _make_label(variation: StringName, text: String) -> Label:
	var label := Label.new()
	if variation != &"":
		label.theme_type_variation = variation
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_icon(path: String, cell: float) -> TextureRect:
	var texture := _load_texture(path)
	if texture == null:
		return null
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(cell, cell)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = texture
	return icon


## One action pressable: UI_SPEC section 8 P1's `ActionInline` box wearing the C3 inline
## chip (section 15.1's own census row), the same token the ARMORY's row-corner chips use.
## The caller parents it - a node that already has a parent cannot be moved into a
## container while the tree is still being built.
func _make_action(text: String) -> Button:
	var button := Button.new()
	button.name = "Action%s" % text.to_pascal_case()
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = ACTION_INLINE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ChromeFamily.apply_chip(button)
	return button


func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _apply_tokens() -> void:
	_chip.add_theme_stylebox_override(&"panel", _chip_box())
	if _pane_title != null:
		_pane_title.add_theme_color_override(&"font_color", _token(&"text_primary"))
	if _note != null:
		_note.add_theme_color_override(&"font_color", _token(&"text_dim"))
	if _board_empty != null:
		_board_empty.add_theme_color_override(&"font_color", _token(&"text_dim"))
	if _roll_label != null:
		_roll_label.add_theme_color_override(&"font_color", _token(&"text_dim"))
	## U7 (T-156): the staged rows' whole inner box at `text_dim`, icons included.
	var dim := _token(&"text_dim")
	for box: Control in _dim_rows:
		if box != null and is_instance_valid(box):
			box.modulate = dim


## U6's chip: the label plus a 1 px danger frame (never colour alone - the ARMORY chip's own
## shipped reading, `chip_danger_bg` filled with a 1 px bright frame).
func _chip_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = _token(&"armory_chip_danger_bg")
	box.border_color = _token(&"accent_danger_bright")
	box.set_border_width_all(1)
	box.set_corner_radius_all(6)
	box.content_margin_left = 8.0
	box.content_margin_right = 8.0
	box.content_margin_top = 2.0
	box.content_margin_bottom = 2.0
	return box


func _token(name: StringName) -> Color:
	if has_theme_color(name, TOKENS_TYPE):
		return get_theme_color(name, TOKENS_TYPE)
	return Color.WHITE


## ------------------------------------------------------------------ the probes' reads


## The board the panel is drawing, in the deck law's own order.
func board_rows() -> Array[Dictionary]:
	return _board


## U22's readout, as rendered (`""` before the strip is built).
func roll_readout() -> String:
	return _roll_label.text if _roll_label != null else ""


## H2's figure, recomputed from the clock at the moment of the read.
func roll_remaining() -> int:
	return _roll_remaining()


## The band the drawn board was rolled in.
func board_band() -> int:
	return _board_band


## U7's dimmed inner boxes (one per staged row), so a probe can read the whole-row dim.
func dimmed_rows() -> Array[Control]:
	return _dim_rows


## The active contracts the panel is drawing.
func active_rows() -> Array[Dictionary]:
	return _active


## U3's note, as rendered.
func header_note() -> String:
	return _note.text if _note != null else ""


## U6's counter, as rendered.
func counter_text() -> String:
	return _counter.text if _counter != null else ""


## True when U6's chip is on screen.
func chip_shown() -> bool:
	return _chip != null and _chip.visible


## U6/U7's chip wording, as rendered.
func chip_text() -> String:
	return _chip_label.text if _chip_label != null else ""


## U8's empty state, as rendered ("" when the board is not empty).
func empty_state_text() -> String:
	return _empty_text


## U4's cancel wording, as rendered.
func cancel_label() -> String:
	return ACTION_CANCEL


## U4's confirm body, as sent to the shell.
func confirm_body_text() -> String:
	return CONFIRM_BODY


## U5's escrow readout lines, as rendered.
func escrow_readout() -> Array[String]:
	return _escrow_lines


## U3's four column headers, as rendered (U22's readout shares the strip, so it is skipped).
func column_headers() -> Array[String]:
	var out: Array[String] = []
	for child: Node in _header_row.get_children():
		if child is Label and child != _roll_label:
			out.append((child as Label).text)
	return out


## The ACCEPT buttons the panel built (one per open, unstaged row).
func accept_buttons() -> Array[Button]:
	return _accept_buttons


## The cancel button one active card carries, or null.
func cancel_button(id: StringName) -> Button:
	return _cancel_buttons.get(String(id)) as Button
