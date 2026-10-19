extends "res://ui/station/station_panel.gd"
## VAULTS panel (S26): 14_station_services.md section 4 as the SERVICES deck's service.
## Contract: docs/design/STATION_HUB.md section 15.4 (the tier rows, the Meridian note,
## the hold/vault contents split, the not-cargo chip and captions, the capacity readout
## and the outpost tier grey) plus UI_SPEC section 12 (the shell v2 idioms).
##
## Every number is a `PlayerProfile` read (the capacity, the contents, the tier price);
## the station's own ceiling and faction come from `StationRegistry`. A deposit or a
## withdrawal is free (14 section 4) and all-or-nothing (17 section 5).
##
## Panel contract with the shell (the shipped duck-typed contract):
##   signal status_requested(message, danger)      write the footer strip
##   signal inspect_requested(title, body, danger) the hover tooltip
##   func refresh_profile(key)                      react to profile_changed
##   func focus_primary()                           focus entry after a switch

const ChromeFamily := preload("res://ui/theme/chrome_family.gd")
const StationRegistryScript := preload("res://game/station_registry.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"
const TOKENS_TYPE: StringName = &"Tokens"
const ICON := "res://assets/icons/service/icon_service_vault.svg"

signal status_requested(message: String, danger: bool)
signal inspect_requested(title: String, body: String, danger: bool)
## UI_SPEC section 17 A5 (S49): the pane asks the shell's section 5.2 overlay for its
## rent confirmations through the S25 seam's own contract - the overlay belongs to the
## screen and the shell hands the answer back through the pane's own `confirm_action`,
## so this pane never owns a modal.
signal confirm_requested(payload: Dictionary)

const PANEL_TITLE := "VAULTS"
const PANEL_HINT := "ONE SERVICE AT A TIME · ESC BACK"
const HEADER_HOLD := "YOUR HOLD"
const HEADER_VAULT := "VAULT CONTENTS"
const CHIP_NOT_CARGO := "NOT CARGO"
const CAPTION_NOT_CARGO := "VAULT CONTENTS DO NOT COUNT AGAINST CARGO ON LAUNCH"
const CAPTION_PERSIST := "CONTENTS PERSIST PER-STATION — THE VAULT IS FURNITURE, NOT A POCKET"
const CAPTION_FREE := "DEPOSITS AND WITHDRAWALS ARE FREE"
const CAPACITY_FORMAT := "THIS VAULT — %d / %d UNITS"
const TIER_FORMAT := "TIER %d · +20 UNITS · %d CR"
const TIER_LABEL := "RENT"
const TIER_OWNED := "OWNED"
const MERIDIAN_NOTE := (
	"Meridian's stations rent 40-unit vaults and the rental tiers cost 25 % more "
	+ "(they know what a vault is worth)."
)
const OUTPOST_CAPTION := "tier 1 only — this is an outpost"
const ACTION_DEPOSIT := "DEPOSIT"
const ACTION_WITHDRAW := "WITHDRAW"
const STACK_FORMAT := "%d× %s"
const REFUSED_FULL := "REFUSED · VAULT FULL"
const REFUSED_EMPTY := "REFUSED · NOTHING SELECTED"

## UI_SPEC section 17 A5/A6 (S49): the rent door's pinned wording - the tier row's own
## identity (`VAULT TIER <n>`, A6's worked example) and the seam's own button words.
## `<cost>` is the tier's own price (the profile's derivation), never a literal here.
const BUY_CONFIRM_TITLE := "CONFIRM PURCHASE"
const BUY_CONFIRM_BODY := "ARE YOU SURE YOU WANT TO BUY %s FOR %s CREDITS?"
const BUY_CONFIRM_TIER_FORMAT := "VAULT TIER %d"
const BUY_CONFIRM_OK := "OK"
const BUY_CONFIRM_CANCEL := "CANCEL"
## The one action this panel asks the shell about (A4's door 5); deposits and
## withdrawals are free, so they stay out of the door list.
const ACTION_RENT: StringName = &"rent_vault"

const ROW_HEIGHT := 76.0
const ROW_INNER_MARGIN := Vector2i(12, 8)
const COL_VALUE := 220.0
const ACTION_INLINE := Vector2(140.0, 32.0)
const LIST_MIN := Vector2(0.0, 220.0)

@onready var _pane_icon: TextureRect = %PaneIcon
@onready var _pane_title: Label = %PaneTitle
@onready var _tier_list: VBoxContainer = %TierList
@onready var _outpost_caption: Label = %OutpostCaption
@onready var _meridian_note: Label = %MeridianNote
@onready var _hold_list: ItemList = %HoldList
@onready var _vault_list: ItemList = %VaultList
@onready var _capacity: Label = %CapacityReadout
@onready var _not_cargo_caption: Label = %NotCargoCaption
@onready var _free_caption: Label = %FreeCaption
@onready var _persist_caption: Label = %PersistCaption
@onready var _deposit: Button = %DepositButton
@onready var _withdraw: Button = %WithdrawButton
@onready var _pane_hint: Label = %PaneHint

var _tiers: Array[Dictionary] = []
var _hold_ids: Array[StringName] = []
var _vault_ids: Array[StringName] = []


func _ready() -> void:
	_pane_icon.custom_minimum_size = Vector2(40.0, 40.0)
	_pane_icon.texture = _load_texture(ICON)
	_pane_title.text = PANEL_TITLE
	_outpost_caption.text = OUTPOST_CAPTION
	_meridian_note.text = MERIDIAN_NOTE
	_not_cargo_caption.text = CAPTION_NOT_CARGO
	_free_caption.text = CAPTION_FREE
	_persist_caption.text = CAPTION_PERSIST
	_pane_hint.text = PANEL_HINT
	_deposit.text = ACTION_DEPOSIT
	_withdraw.text = ACTION_WITHDRAW
	_deposit.pressed.connect(_on_deposit_pressed)
	_withdraw.pressed.connect(_on_withdraw_pressed)
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_apply_tokens()


func refresh_profile(_key: StringName) -> void:
	if is_node_ready():
		_refresh()


func focus_primary() -> void:
	if _deposit != null and not _deposit.disabled:
		_deposit.grab_focus()


func _refresh() -> void:
	_tiers.clear()
	_clear_list(_tier_list)
	var profile := _profile()
	var row := _station_row(profile)
	var station_id := StringName(row.get(&"id", &""))
	var meridian := StringName(row.get(&"faction", &"")) == &"meridian"
	_meridian_note.visible = meridian
	var ceiling := int(row.get(&"vault_tiers", 0))
	## U16's outpost caption: tiers 2/3 grey at a station whose ceiling is 1.
	_outpost_caption.visible = ceiling < ProfileScript.VAULT_MAX_TIER
	var owned := _vault_tier(profile, station_id)
	for tier in range(1, ProfileScript.VAULT_MAX_TIER + 1):
		var entry := {
			&"tier": tier,
			&"cost": _tier_cost(profile, tier, row),
			&"owned": tier <= owned,
			&"available": tier <= ceiling,
		}
		_tiers.append(entry)
		_tier_list.add_child(_build_tier_row(entry, station_id, row))
	var capacity := _vault_capacity(profile, row)
	_capacity.text = CAPACITY_FORMAT % [_vault_used(profile, station_id), capacity]
	_rebuild_lists(profile, station_id)
	_sync_actions(profile, station_id, row)


func _build_tier_row(entry: Dictionary, station_id: StringName, row: Dictionary) -> Button:
	var tier := int(entry[&"tier"])
	var button := Button.new()
	button.name = "Tier%d" % tier
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ChromeFamily.apply_row(button)
	var inner := MarginContainer.new()
	inner.name = "RowInner"
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "top", "right", "bottom"]:
		var value: int = ROW_INNER_MARGIN.x if side in ["left", "right"] else ROW_INNER_MARGIN.y
		inner.add_theme_constant_override(StringName("margin_" + side), value)
	button.add_child(inner)
	var box := HBoxContainer.new()
	box.name = "RowBox"
	box.add_theme_constant_override(&"separation", 12)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(box)
	var label := _make_label(&"StationValue", TIER_FORMAT % [tier, int(entry[&"cost"])])
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(label)
	var action := _make_action(TIER_OWNED if bool(entry[&"owned"]) else TIER_LABEL)
	if bool(entry[&"owned"]):
		action.disabled = true
	elif not bool(entry[&"available"]):
		## U16: the outpost greys the **whole row** (`button_disabled`), not just its action.
		button.disabled = true
		action.disabled = true
	else:
		action.pressed.connect(_on_rent_pressed.bind(tier))
	box.add_child(action)
	return button


func _rebuild_lists(profile: Node, station_id: StringName) -> void:
	_hold_list.clear()
	_vault_list.clear()
	_hold_ids.clear()
	_vault_ids.clear()
	if profile == null:
		return
	var hold: Dictionary = profile.call(&"cargo_items")
	for key: Variant in hold:
		if int(hold[key]) <= 0:
			continue
		_hold_ids.append(StringName(key))
		_hold_list.add_item(STACK_FORMAT % [int(hold[key]), String(key)])
	var vault := _vault_contents(profile, station_id)
	for key: Variant in vault:
		if int(vault[key]) <= 0:
			continue
		_vault_ids.append(StringName(key))
		_vault_list.add_item(STACK_FORMAT % [int(vault[key]), String(key)])


func _sync_actions(profile: Node, station_id: StringName, row: Dictionary) -> void:
	if profile == null:
		return
	var used := _vault_used(profile, station_id)
	var capacity := _vault_capacity(profile, row)
	_deposit.disabled = _hold_ids.is_empty() or used >= capacity
	_withdraw.disabled = _vault_ids.is_empty()


func _on_rent_pressed(tier: int) -> void:
	var profile := _profile()
	if profile == null:
		return
	var row := _station_row(profile)
	## UI_SPEC section 17 A4/A5 (S49): the rent is the door - the confirm opens here and
	## the confirmed answer runs `vault_rent`, the transaction unchanged (which can still
	## refuse). The quoted cost is the tier row's own figure, re-read at press time
	## (section 5.8's clock).
	confirm_requested.emit({
		&"id": StringName(str(tier)),
		&"title": BUY_CONFIRM_TITLE,
		&"body": BUY_CONFIRM_BODY % [
			BUY_CONFIRM_TIER_FORMAT % tier,
			_format_int(_tier_cost(profile, tier, row)),
		],
		&"confirm_text": BUY_CONFIRM_OK,
		&"cancel_text": BUY_CONFIRM_CANCEL,
		&"action": ACTION_RENT,
	})


## The shell's answer to `confirm_requested` (the S25 seam's own contract): the one
## action this panel asks about. The confirmed press runs the transaction exactly as it
## always ran, so it can still refuse (the strip's own wording, never a dialog).
func confirm_action(action: StringName, id: StringName) -> void:
	if action == ACTION_RENT:
		_rent(int(String(id)))


## The rent's own transaction, unchanged.
func _rent(tier: int) -> void:
	var profile := _profile()
	if profile == null:
		return
	var row := _station_row(profile)
	var result: Dictionary = profile.call(&"vault_rent", StringName(row.get(&"id", &"")), tier, row)
	if not bool(result.get(&"ok", false)):
		status_requested.emit(REFUSED_FULL, true)
		return
	_refresh()
	status_requested.emit("VAULT TIER %d RENTED · %d CR" % [tier, int(result.get(&"cost", 0))], false)


func _on_deposit_pressed() -> void:
	var profile := _profile()
	if profile == null:
		return
	var selected := _hold_list.get_selected_items()
	if selected.is_empty():
		status_requested.emit(REFUSED_EMPTY, true)
		return
	var item_id := _hold_ids[selected[0]]
	var amount := int(profile.call(&"cargo_qty", item_id))
	var row := _station_row(profile)
	var ok := bool(
		profile.call(&"vault_deposit", StringName(row.get(&"id", &"")), item_id, amount, row)
	)
	if not ok:
		status_requested.emit(REFUSED_FULL, true)
		return
	_refresh()
	status_requested.emit("DEPOSITED · %s" % (STACK_FORMAT % [amount, String(item_id)]), false)


func _on_withdraw_pressed() -> void:
	var profile := _profile()
	if profile == null:
		return
	var selected := _vault_list.get_selected_items()
	if selected.is_empty():
		status_requested.emit(REFUSED_EMPTY, true)
		return
	var item_id := _vault_ids[selected[0]]
	var row := _station_row(profile)
	var station_id := StringName(row.get(&"id", &""))
	var amount := int(_vault_contents(profile, station_id).get(String(item_id), 0))
	if not bool(profile.call(&"vault_withdraw", station_id, item_id, amount)):
		status_requested.emit(REFUSED_EMPTY, true)
		return
	_refresh()
	status_requested.emit("WITHDREW · %s" % (STACK_FORMAT % [amount, String(item_id)]), false)

func _station_row(profile: Node) -> Dictionary:
	if profile == null or not profile.has_method(&"docked_station"):
		return {}
	return StationRegistryScript.docked_station(profile)

func _vault_tier(profile: Node, station_id: StringName) -> int:
	if profile == null:
		return 0
	return int(profile.call(&"vault_tier", station_id))


func _vault_contents(profile: Node, station_id: StringName) -> Dictionary:
	if profile == null:
		return {}
	return profile.call(&"vault_contents", station_id)


func _vault_used(profile: Node, station_id: StringName) -> int:
	if profile == null:
		return 0
	return int(profile.call(&"vault_used", station_id))


func _vault_capacity(profile: Node, row: Dictionary) -> int:
	if profile == null:
		return 0
	return int(profile.call(&"vault_capacity", row))


func _tier_cost(profile: Node, tier: int, row: Dictionary) -> int:
	if profile == null:
		return 0
	return int(profile.call(&"vault_tier_cost", tier, row))

func _make_label(variation: StringName, text: String) -> Label:
	var label := Label.new()
	if variation != &"":
		label.theme_type_variation = variation
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_action(text: String) -> Button:
	var button := Button.new()
	button.name = "Action%s" % text.to_pascal_case()
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = ACTION_INLINE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ChromeFamily.apply_chip(button)
	return button

func _apply_tokens() -> void:
	if _pane_title != null:
		_pane_title.add_theme_color_override(&"font_color", _token(&"text_primary"))
	for label: Label in [_outpost_caption, _meridian_note, _not_cargo_caption, _free_caption, _persist_caption, _pane_hint]:
		if label != null:
			label.add_theme_color_override(&"font_color", _token(&"text_dim"))

func tier_rows() -> Array[Dictionary]:
	return _tiers


func capacity_text() -> String:
	return _capacity.text if _capacity != null else ""


func deposit_label() -> String:
	return _deposit.text if _deposit != null else ""


func withdraw_label() -> String:
	return _withdraw.text if _withdraw != null else ""


func not_cargo_caption_text() -> String:
	return _not_cargo_caption.text if _not_cargo_caption != null else ""


func outpost_caption_text() -> String:
	return _outpost_caption.text if _outpost_caption != null else ""


func outpost_caption_visible() -> bool:
	return _outpost_caption != null and _outpost_caption.visible


## The tier row's own `disabled` state, by tier number (U16's whole-row grey).
func tier_row_disabled(tier: int) -> bool:
	var node := _tier_list.get_node_or_null(NodePath("Tier%d" % tier)) as Button
	return node != null and node.disabled
