extends VBoxContainer
## INSURANCE panel (S26): 14_station_services.md section 3 as the SERVICES deck's service.
## Contract: docs/design/STATION_HUB.md section 15.3 (the premium table, the policy and
## mercy chips, the one-death line, the loss warning and the opt-in toggle) plus UI_SPEC
## section 12 (the shell v2 idioms: containers, theme variations, no coordinates).
##
## The premium law is **M14's** (14's 2026-10-08 S28 block: 1.5 % of the hull's list per
## class, the 135-1 080 band), which supersedes section 3's flats. Every figure is a
## `PlayerProfile` read (`insurance_premium`), never re-derived here; the class rows are
## the profile's own `INSURANCE_TIER_ROWS`, so the panel and the charge cannot drift.
##
## Panel contract with the shell (the shipped duck-typed contract):
##   signal status_requested(message, danger)     write the footer strip
##   signal inspect_requested(title, body, danger) the hover tooltip
##   func refresh_profile(key)                     react to profile_changed
##   func focus_primary()                          focus entry after a switch

const ChromeFamily := preload("res://ui/theme/chrome_family.gd")
const StationRegistryScript := preload("res://game/station_registry.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"
const TOKENS_TYPE: StringName = &"Tokens"
const ICON := "res://assets/icons/service/icon_service_insurance.svg"

signal status_requested(message: String, danger: bool)
signal inspect_requested(title: String, body: String, danger: bool)

const PANEL_TITLE := "INSURANCE"
const PANEL_HINT := "ONE SERVICE AT A TIME · ESC BACK"
const HEADER_CLASS := "HULL CLASS"
const HEADER_PREMIUM := "PREMIUM PER LAUNCH"
const CHIP_YOUR_CLASS := "YOUR CLASS"
const NOTE_CHAMPION := "Champion standing multiplies the premium ×0.8"
const ONE_DEATH_LINE := "THE PAYOUT COVERS ONE LOSS · THE POLICY DOES NOT RENEW MID-FLIGHT"
const MERCY_CAPTION := (
	"mercy clause: if you have no other hull, the Concord reissues a bare Fighter — "
	+ "once per profile"
)
const LOSS_WARNING := "UNINSURED LOSS: HULL AND ALL INSTALLED MODULES ARE GONE"
const STATE_UNINSURED := "UNINSURED"
const STATE_INSURED := "INSURED · COVERS ONE LOSS"
const STATE_PAID_OUT := "PAID OUT · POLICY SPENT"
const MERCY_AVAILABLE := "MERCY AVAILABLE"
const MERCY_USED := "MERCY USED"
const TOGGLE_ON := "INSURE LAUNCHES"
const TOGGLE_OFF := "CANCEL POLICY"
const PREMIUM_LINE := "PREMIUM %d CR PER LAUNCH · CHARGED AT LAUNCH"
const REFUSED := "REFUSED · %s"

const ROW_HEIGHT := 76.0
const ROW_INNER_MARGIN := Vector2i(12, 8)
const COL_CLASS := 260.0
const COL_PREMIUM := 220.0
const COLUMN_WIDTH := 420.0
const ACTION_INLINE := Vector2(200.0, 32.0)

@onready var _pane_icon: TextureRect = %PaneIcon
@onready var _pane_title: Label = %PaneTitle
@onready var _header_row: HBoxContainer = %PremiumHeader
@onready var _premium_list: VBoxContainer = %PremiumList
@onready var _note: Label = %ChampionNote
@onready var _state_chip: PanelContainer = %StateChip
@onready var _state_label: Label = %StateLabel
@onready var _one_death: Label = %OneDeathLine
@onready var _mercy_chip: PanelContainer = %MercyChip
@onready var _mercy_label: Label = %MercyLabel
@onready var _mercy_caption: Label = %MercyCaption
@onready var _warning: PanelContainer = %LossWarning
@onready var _warning_label: Label = %LossWarningLabel
@onready var _toggle: Button = %OptInToggle
@onready var _premium_line: Label = %PremiumLine
@onready var _pane_hint: Label = %PaneHint

var _rows: Array[Dictionary] = []


func _ready() -> void:
	_pane_icon.custom_minimum_size = Vector2(40.0, 40.0)
	_pane_icon.texture = _load_texture(ICON)
	_pane_title.text = PANEL_TITLE
	_note.text = NOTE_CHAMPION
	_one_death.text = ONE_DEATH_LINE
	_mercy_caption.text = MERCY_CAPTION
	_warning_label.text = LOSS_WARNING
	_pane_hint.text = PANEL_HINT
	_build_headers()
	_toggle.pressed.connect(_on_toggle_pressed)
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_apply_tokens()


func refresh_profile(_key: StringName) -> void:
	if is_node_ready():
		_refresh()


func focus_primary() -> void:
	if _toggle != null and not _toggle.disabled:
		_toggle.grab_focus()
	elif _premium_list.get_child_count() > 0:
		var first := _premium_list.get_child(0) as Control
		if first != null:
			first.grab_focus()


func _build_headers() -> void:
	for column: Dictionary in [
		{&"text": HEADER_CLASS, &"width": COL_CLASS},
		{&"text": HEADER_PREMIUM, &"width": COL_PREMIUM},
	]:
		var label := Label.new()
		label.theme_type_variation = &"SectionHeader"
		label.text = String(column[&"text"])
		label.custom_minimum_size = Vector2(float(column[&"width"]), 0.0)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_header_row.add_child(label)


func _refresh() -> void:
	_rows.clear()
	_clear_list(_premium_list)
	var profile := _profile()
	var own_tier := &""
	if profile != null and profile.has_method(&"insurance_tier"):
		own_tier = StringName(profile.call(&"insurance_tier", StringName(profile.call(&"active_ship"))))
	for row: Dictionary in ProfileScript.INSURANCE_TIER_ROWS:
		var tier := StringName(row[&"tier"])
		var entry := {
			&"tier": tier,
			&"label": String(row[&"label"]),
			&"premium": _tier_premium(profile, tier),
			&"own": tier == own_tier,
		}
		_rows.append(entry)
		_premium_list.add_child(_build_premium_row(entry))
	_sync_policy(profile)


func _build_premium_row(entry: Dictionary) -> Button:
	var row := Button.new()
	row.name = "Premium%s" % String(entry[&"tier"]).to_pascal_case()
	row.toggle_mode = true
	row.focus_mode = Control.FOCUS_ALL
	row.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	row.disabled = true
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ChromeFamily.apply_row(row)
	var inner := MarginContainer.new()
	inner.name = "RowInner"
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "top", "right", "bottom"]:
		var value: int = ROW_INNER_MARGIN.x if side in ["left", "right"] else ROW_INNER_MARGIN.y
		inner.add_theme_constant_override(StringName("margin_" + side), value)
	row.add_child(inner)
	var box := HBoxContainer.new()
	box.name = "RowBox"
	box.add_theme_constant_override(&"separation", 12)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(box)
	var class_label := _make_label(&"StationValue", String(entry[&"label"]))
	class_label.custom_minimum_size = Vector2(COL_CLASS, 0.0)
	box.add_child(class_label)
	var premium := _make_label(&"StationValue", "%d CR" % int(entry[&"premium"]))
	premium.name = "PremiumValue"
	premium.custom_minimum_size = Vector2(COL_PREMIUM, 0.0)
	premium.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(premium)
	if bool(entry[&"own"]):
		var chip := _make_chip(CHIP_YOUR_CLASS)
		box.add_child(chip)
	return row


func _sync_policy(profile: Node) -> void:
	var insured := profile != null and bool(profile.call(&"insured"))
	var state := STATE_UNINSURED
	if profile != null and profile.has_method(&"insurance_state"):
		match StringName(profile.call(&"insurance_state")):
			&"insured":
				state = STATE_INSURED
			&"paid_out":
				state = STATE_PAID_OUT
	_state_label.text = state
	var mercy_used := profile != null and bool(profile.call(&"mercy_used"))
	_mercy_label.text = MERCY_USED if mercy_used else MERCY_AVAILABLE
	## The toggle reads the action it will take (the pin's two words, in that reading).
	_toggle.text = TOGGLE_OFF if insured else TOGGLE_ON
	var premium := 0
	if profile != null and profile.has_method(&"insurance_premium"):
		premium = int(profile.call(&"insurance_premium"))
	_premium_line.text = PREMIUM_LINE % premium
	_sync_service_state()


## U2's grey state, shared with the strip: a station that does not sell insurance greys
## the whole body and shows the registry's own reason caption. The U12 loss warning is a
## danger row shown while the launch is uninsured.
func _sync_service_state() -> void:
	var profile := _profile()
	var row: Dictionary = {}
	if profile != null and profile.has_method(&"docked_station"):
		row = StationRegistryScript.docked_station(profile)
	var offered := row.is_empty() or StationRegistryScript.offers(
		row, StationRegistryScript.SERVICE_INSURANCE
	)
	_toggle.disabled = not offered
	var insured := profile != null and bool(profile.call(&"insured"))
	_warning.visible = not insured


func _on_toggle_pressed() -> void:
	var profile := _profile()
	if profile == null:
		return
	var next := not bool(profile.call(&"insured"))
	profile.call(&"set_insured", next)
	_refresh()
	status_requested.emit(
		("POLICY SET · %s" % STATE_INSURED) if next else "POLICY CANCELLED", false
	)


func _profile() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null(NodePath(PROFILE_SERVICE))


func _tier_premium(profile: Node, tier: StringName) -> int:
	if profile != null and profile.has_method(&"insurance_tier_premium"):
		return int(profile.call(&"insurance_tier_premium", tier))
	return 0


func _clear_list(list: VBoxContainer) -> void:
	for child: Node in list.get_children():
		list.remove_child(child)
		child.queue_free()


func _make_label(variation: StringName, text: String) -> Label:
	var label := Label.new()
	if variation != &"":
		label.theme_type_variation = variation
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_chip(text: String) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.name = "Chip"
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var label := _make_label(&"StationCaption", text)
	label.name = "ChipLabel"
	chip.add_child(label)
	return chip


func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _apply_tokens() -> void:
	if _pane_title != null:
		_pane_title.add_theme_color_override(&"font_color", _token(&"text_primary"))
	for label: Label in [_note, _one_death, _mercy_caption, _warning_label, _pane_hint]:
		if label != null:
			label.add_theme_color_override(&"font_color", _token(&"text_dim"))


func _token(name: StringName) -> Color:
	if has_theme_color(name, TOKENS_TYPE):
		return get_theme_color(name, TOKENS_TYPE)
	return Color.WHITE


## --- the probes' reads --------------------------------------------------------------


func premium_rows() -> Array[Dictionary]:
	return _rows


func state_text() -> String:
	return _state_label.text if _state_label != null else ""


func mercy_text() -> String:
	return _mercy_label.text if _mercy_label != null else ""


func toggle_text() -> String:
	return _toggle.text if _toggle != null else ""


func premium_line_text() -> String:
	return _premium_line.text if _premium_line != null else ""


func note_text() -> String:
	return _note.text if _note != null else ""
