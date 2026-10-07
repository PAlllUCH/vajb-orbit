extends VBoxContainer
## REFINERY module panel: the queue pane (STATION_HUB section 21.3 P42/P43, the
## model is 04 section 7). Three blocks: LEFT the hold ore stacks plus the input
## inventory (rows tagged LOADED); CENTRE the stepper, the ORE IN / INGOTS OUT /
## FEE / TIME totals and the QUEUE N / QUEUE ALL / CANCEL / LOAD / COLLECT ALL
## actions; RIGHT the job list (running rows with an mm:ss countdown, pending rows,
## done rows awaiting collection). The SLOTS n/5 readout and UPGRADE live in the
## pane header band.
##
## The station shell loads this scene into its host, so the panel never routes and
## never writes the profile directly: it emits status_requested up, reads Refinery
## / MineralCatalog / PlayerProfile down, and every printed number is a Refinery or
## MineralCatalog read (04 section 7.3: the panel hardcodes no price and no
## duration).
##
## Panel contract with the shell:
##   signal status_requested(message: String, danger: bool)   write the footer strip
##   func refresh_profile(key: StringName) -> void             react to profile_changed
##   func focus_primary() -> void                              focus entry after a switch
##   func disarm() -> bool                                     ui_cancel step 2 / CANCEL
##
## Jobs run station-side on wall-clock `ready_at` (R6), so the panel settles
## finished jobs on becoming visible, on every `&"refinery"` refresh, and on a 1 Hz
## tick while it is open.
##
## A Refinery transaction emits profile_changed(&"refinery") / (&"cargo") /
## (&"credits") from inside the call, so the shell forwards a refresh into this
## panel while its own handler is still on the stack. A rebuild there would free
## the row the signal chain is walking, so a refresh seen mid-transaction is
## deferred to one rebuild right after the call returns.

const TOKENS_TYPE: StringName = &"Tokens"
const ChromeFamily := preload("res://ui/theme/chrome_family.gd")

const RefineryModule := preload("res://game/refinery.gd")
const Catalog := preload("res://game/mineral_catalog.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")
const StationCatalogScript := preload("res://game/station_catalog.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"

signal status_requested(message: String, danger: bool)
signal inspect_requested(title: String, body: String, danger: bool)
signal sheet_requested(payload: Dictionary)

const ROW_HEIGHT := 76.0
const JOB_ROW_HEIGHT := 56.0
const COL_ICON := 40.0
const COL_ORE := 130.0
const COL_STATE := 160.0
const ROW_INNER_MARGIN := Vector2i(12, 8)
const COLUMN_SEPARATION := 12
const CELL_SEPARATION := 2
const ROW_ICON_IDLE_ALPHA := 0.72
const HOVER_SECONDS := 0.09
const STEPPER_MIN := 1
const TICK_SECONDS := 1.0

const HEADER_MINERAL := "MINERAL"
const HEADER_ORE := "ORE"
const HEADER_STATE := "STATE"
const HEADER_JOB := "JOB"
const HEADER_TIME := "TIME"

const TAG_FORMAT := "%s · %s READY"
const TAG_EMPTY := "NO CONVERTIBLE STACKS"
const TAG_LOADED := "LOADED"
const TAG_HELD_FORMAT := "%d ORE HELD"
const TAG_INPUT_FORMAT := "%d IN INPUT"
const SELECTED_NONE := "NO STACK SELECTED"
const STEPPER_FORMAT := "%d CONVERSIONS"
const STEPPER_ONE := "1 CONVERSION"
const STEPPER_IDLE := "0 CONVERSIONS"
const FEE_FORMAT := "%s CR"
const ZERO_TEXT := "0"
const ZERO_TIME := "00:00"
const QUEUE_FORMAT := "QUEUE %d"
const QUEUE_ALL_WORD := "QUEUE ALL"
const CANCEL_WORD := "CANCEL"
const LOAD_WORD := "LOAD"
const COLLECT_WORD := "COLLECT ALL"
const SLOTS_FORMAT := "SLOTS %d/%d"
const UPGRADE_FORMAT := "UPGRADE (%s CR)"
const FOOTER_FORMAT := "%d ORE = 1 INGOT · FEE %d CR PER CONVERSION"
const FOOTER_EMPTY := "BRING RAW ORE FROM THE BELT"
const FOOTER_LOAD := "LOAD ORE TO START A JOB"
const EMPTY_HOLD_ROW := "NO ORE IN HOLD"
const EMPTY_JOB_ROW := "NO JOBS QUEUED"
const JOB_LINE_FORMAT := "%s · %s · %s"
const JOB_DONE_FORMAT := "%s · %s · DONE · COLLECT"
const JOB_RUNNING_TAG := "RUNNING"
const JOB_PENDING_TAG := "PENDING"

const STATUS_READY := "READY · %s · %s · %s FEE"
const INSPECT_TITLE_FORMAT := "%s · %s · %s FEE"
const STATUS_QUEUED := "QUEUED · %s · %s · %s CR FEE"
const STATUS_QUEUED_ALL := "QUEUED · ALL ORE · %s · %s CR FEE"
const STATUS_REFUSED_CREDITS := "REFUSED · NOT ENOUGH CREDITS · %s NEEDED"
const STATUS_REFUSED_ORE := "REFUSED · NOT ENOUGH ORE · %s NEEDED"
const STATUS_REFUSED_INPUT := "REFUSED · INPUT FULL"
const STATUS_REFUSED_COUNT := "REFUSED · NO CONVERSIONS SELECTED"
const STATUS_REFUSED_EMPTY := "REFUSED · NOTHING TO QUEUE"
const STATUS_REFUSED_UNKNOWN := "REFUSED · UNKNOWN MINERAL"
const STATUS_REFUSED_MAX_SLOTS := "REFUSED · ALL SLOTS BOUGHT"
const STATUS_CANCELLED := "CANCELLED · %s · %s RETURNED"
const STATUS_LOADED := "LOADED · %s · %s"
const STATUS_COLLECTED := "COLLECTED · %s"
const STATUS_OUTPUT_FULL := "OUTPUT FULL · COLLECT FIRST"
const STATUS_UPGRADED := "SLOTS UPGRADED · %d"
const STATUS_IDLE := "REFINERY IDLE · SELECT A STACK"

const TINT_DIR := "res://assets/icons/tint/"
const DEDICATED_ICON_PREFIX := "icon_mineral_"

@onready var _pane_icon: TextureRect = %PaneIcon
@onready var _tag: Label = %PanelTag
@onready var _slots_label: Label = %SlotsLabel
@onready var _upgrade_button: Button = %UpgradeButton
@onready var _hold_header: HBoxContainer = %HoldHeader
@onready var _hold_scroll: ScrollContainer = %HoldScroll
@onready var _hold_rows: VBoxContainer = %HoldRows
@onready var _selected_name: Label = %SelectedName
@onready var _stepper_less: Button = %StepperLess
@onready var _stepper_value: Label = %StepperValue
@onready var _stepper_more: Button = %StepperMore
@onready var _ore_in: Label = %OreInValue
@onready var _ingots_out: Label = %IngotsOutValue
@onready var _fee_value: Label = %FeeValue
@onready var _time_value: Label = %TimeValue
@onready var _queue_button: Button = %QueueButton
@onready var _queue_all_button: Button = %QueueAllButton
@onready var _cancel_button: Button = %CancelButton
@onready var _load_button: Button = %LoadButton
@onready var _collect_button: Button = %CollectButton
@onready var _jobs_header: HBoxContainer = %JobsHeader
@onready var _jobs_scroll: ScrollContainer = %JobsScroll
@onready var _jobs_rows: VBoxContainer = %JobsRows
@onready var _footer: Label = %PaneFooter

var _payloads: Array[Dictionary] = []
var _job_payloads: Array[Dictionary] = []
var _selected_id: StringName = &""
var _selected_row: Button = null
var _selected_job_id: int = -1
var _focused_payload: Dictionary = {}
var _stepper: int = STEPPER_MIN
var _stepper_max: int = 0
var _job_signature := PackedStringArray()
var _transaction := false
var _rebuild_pending := false
var _tick_timer: Timer = null
var _tweens: Array[Tween] = []


func _ready() -> void:
	_build_headers()
	_build_rows()
	_build_jobs()
	_apply_tokens()
	_wire_controls()
	## S36-F1 (A4, F2): the four QUEUE / QUEUE ALL / LOAD / COLLECT ALL bars live at
	## 114-176 px wide, under C2's 272 h-band floor - they revert to their pre-swap
	## StationButton style (reported as new-plate candidates). CANCEL stays native too.
	## S37-F1 (section 15.1 C8): the 48x48 StepperLess/StepperMore wear the flat Tokens
	## box, not the plate - the census's C8 square slot plate is a TextureButton variation
	## a plain Button cannot resolve (measured StyleBoxFlat), so the tscn drops their
	## StationButton variation (the brief's A5.1 fallback).
	_connect_scroll()
	_make_tick_timer()
	visibility_changed.connect(_on_visibility_changed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_apply_tokens()


func _exit_tree() -> void:
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()


func refresh_profile(key: StringName) -> void:
	## STATION_HUB section 12.4 / 04 section 7: &"cargo" and &"refinery" rebuild the
	## blocks, &"credits" only moves the affordability colour.
	if key != &"cargo" and key != &"credits" and key != &"refinery":
		return
	if _transaction:
		_rebuild_pending = true
		return
	if key == &"refinery":
		_settle()
	_rebuild_all()


func focus_primary() -> void:
	## A disabled control must not take the ring: when nothing enabled can, the panel
	## returns without grabbing and the shell's rail fallback runs (station.gd:401-410).
	for payload: Dictionary in _payloads:
		var row: Button = payload[&"row"]
		if not row.disabled:
			row.grab_focus()
			return
	if not _queue_button.disabled:
		_queue_button.grab_focus()


func disarm() -> bool:
	## ui_cancel step 2 (STATION_HUB section 2) and the CANCEL button's idle path: the
	## job selection first, then the mineral selection.
	if _selected_job_id >= 0:
		_select_job(-1)
		return true
	if _selected_id == &"":
		return false
	_clear_selection()
	return true


func inspect_focused() -> void:
	if _focused_payload.is_empty():
		return
	_emit_sheet(_focused_payload)


## --------------------------------------------------------------- the shell wiring


func _wire_controls() -> void:
	_stepper_less.pressed.connect(_on_stepper_pressed.bind(-1))
	_stepper_more.pressed.connect(_on_stepper_pressed.bind(1))
	_queue_button.pressed.connect(_on_queue_pressed)
	_queue_all_button.pressed.connect(_on_queue_all_pressed)
	_cancel_button.pressed.connect(_on_cancel_pressed)
	_load_button.pressed.connect(_on_load_pressed)
	_collect_button.pressed.connect(_on_collect_pressed)
	_upgrade_button.pressed.connect(_on_upgrade_pressed)


func _connect_scroll() -> void:
	if _hold_scroll.has_signal(&"scroll_started"):
		_hold_scroll.connect(&"scroll_started", _on_scroll_started)
	if _jobs_scroll.has_signal(&"scroll_started"):
		_jobs_scroll.connect(&"scroll_started", _on_scroll_started)


func _make_tick_timer() -> void:
	_tick_timer = Timer.new()
	_tick_timer.name = "RefineryTick"
	_tick_timer.one_shot = false
	_tick_timer.wait_time = TICK_SECONDS
	_tick_timer.timeout.connect(_tick)
	add_child(_tick_timer)


func _on_visibility_changed() -> void:
	if _tick_timer == null:
		return
	if is_visible_in_tree():
		_settle()
		_rebuild_all()
		_tick_timer.start()
	else:
		_tick_timer.stop()


## R6's 1 Hz tick: settle finished jobs, then refresh the countdowns in place (a
## full rebuild would drop the focus ring). A state change rebuilds the list.
func _tick() -> void:
	if not is_visible_in_tree():
		return
	_settle()
	if _live_signature() != _job_signature:
		_build_jobs()
		_refresh_slots()
		return
	_refresh_countdowns()


func _settle() -> void:
	var profile := _profile()
	if profile == null:
		return
	_transaction = true
	RefineryModule.settle(profile)
	_transaction = false
	_rebuild_pending = false


## --------------------------------------------------------------------- the header


func _build_headers() -> void:
	for cell: Dictionary in _header_cells():
		_hold_header.add_child(_make_header_cell(cell))
	for cell: Dictionary in _job_header_cells():
		_jobs_header.add_child(_make_header_cell(cell))
	_refresh_slots()


func _header_cells() -> Array[Dictionary]:
	return [
		{&"text": "", &"width": COL_ICON, &"expand": false},
		{&"text": HEADER_MINERAL, &"width": 0.0, &"expand": true},
		{&"text": HEADER_ORE, &"width": COL_ORE, &"expand": false},
		{&"text": HEADER_STATE, &"width": COL_STATE, &"expand": false},
	]


func _job_header_cells() -> Array[Dictionary]:
	return [
		{&"text": HEADER_JOB, &"width": 0.0, &"expand": true},
		{&"text": HEADER_TIME, &"width": COL_STATE, &"expand": false},
	]


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


func _refresh_slots() -> void:
	var profile := _profile()
	var current := RefineryModule.slots(profile) if profile != null else RefineryModule.BASE_SLOTS
	_slots_label.text = SLOTS_FORMAT % [current, RefineryModule.MAX_SLOTS]
	_upgrade_button.text = UPGRADE_FORMAT % _format_cost(RefineryModule.SLOT_UPGRADE_COST)
	_upgrade_button.disabled = current >= RefineryModule.MAX_SLOTS


## ------------------------------------------------------------- the LEFT block rows


func _build_rows() -> void:
	_clear_rows()
	_selected_row = null
	var hold := _stacks()
	var input := _input_stacks()
	if hold.is_empty() and input.is_empty():
		_selected_id = &""
		_stepper = STEPPER_MIN
		_stepper_max = 0
		_build_empty_row()
	else:
		for stack: Dictionary in hold:
			_payloads.append(_build_row(stack, false))
		for stack: Dictionary in input:
			_payloads.append(_build_row(stack, true))
		_add_slack()
		_reselect()
	_rebuild_pending = false
	_refresh_tag()
	_refresh_footer()
	_refresh_box()
	_refresh_affordability()


func _clear_rows() -> void:
	_payloads.clear()
	for child: Node in _hold_rows.get_children():
		_hold_rows.remove_child(child)
		child.queue_free()


func _build_empty_row() -> void:
	var row := Button.new()
	row.name = "EmptyRow"
	row.disabled = true
	row.focus_mode = Control.FOCUS_NONE
	row.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	var box := _make_inner(row)
	var label := Label.new()
	label.name = "EmptyCaption"
	label.theme_type_variation = &"StationCaption"
	label.text = EMPTY_HOLD_ROW
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)
	_hold_rows.add_child(row)


func _build_row(stack: Dictionary, loaded: bool) -> Dictionary:
	var mineral_id: StringName = stack.get(&"mineral_id", &"")
	var entry: Dictionary = stack.get(&"entry", {})
	var name_text := String(entry.get(&"name", String(mineral_id)))
	var ore_qty := int(stack.get(&"ore_qty", 0))
	var conversions := int(stack.get(&"conversions", RefineryModule.input_conversions(_profile(), mineral_id)))
	var fee := RefineryModule.fee_for(conversions, RefineryModule.fee_multiplier(_profile()))
	var row := Button.new()
	row.name = "%s%s" % ["Input" if loaded else "Hold", String(mineral_id).to_pascal_case()]
	row.toggle_mode = true
	row.focus_mode = Control.FOCUS_ALL
	row.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row.set_meta(&"id", mineral_id)
	## S36 (UI_SPEC section 15.1): the ore/hold row wears C4 `ui_row_strip`.
	ChromeFamily.apply_row(row)
	var box := _make_inner(row)
	var icon := _make_icon(entry)
	if icon != null:
		box.add_child(icon)
	box.add_child(_make_title_box(name_text, ore_qty, loaded))
	var ore := _make_value_cell(box, COL_ORE, "Ore")
	ore.text = _format_int(ore_qty)
	var state := _make_value_cell(box, COL_STATE, "State")
	state.theme_type_variation = &"StationCaption"
	state.text = TAG_LOADED if loaded else ""
	var payload := {
		&"id": mineral_id,
		&"name": name_text,
		&"entry": entry,
		&"ore": ore_qty,
		&"conversions": conversions,
		&"fee": fee,
		&"loaded": loaded,
		&"row": row,
		&"icon": icon,
		&"tint": _icon_tint(entry),
		&"fee_value": state,
	}
	row.pressed.connect(_on_row_pressed.bind(payload))
	row.focus_entered.connect(_on_row_focused.bind(row, payload))
	row.mouse_entered.connect(_on_row_hovered.bind(payload, true))
	row.mouse_exited.connect(_on_row_hovered.bind(payload, false))
	_hold_rows.add_child(row)
	return payload


func _make_title_box(name_text: String, ore_qty: int, loaded: bool) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = "TitleBox"
	box.add_theme_constant_override(&"separation", CELL_SEPARATION)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := _make_label(&"StationValue", name_text)
	title.name = "Title"
	box.add_child(title)
	var meta := _make_label(
		&"StationCaption",
		TAG_INPUT_FORMAT % ore_qty if loaded else TAG_HELD_FORMAT % ore_qty
	)
	meta.name = "Meta"
	box.add_child(meta)
	return box


func _make_value_cell(parent: HBoxContainer, width: float, cell_name: String) -> Label:
	var label := _make_label(&"StationValue", "")
	label.name = cell_name
	label.custom_minimum_size = Vector2(width, 0.0)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parent.add_child(label)
	return label


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


func _make_icon(entry: Dictionary) -> TextureRect:
	var icon_path := _icon_source(entry)
	if icon_path.is_empty():
		return null
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(COL_ICON, COL_ICON)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = load(icon_path)
	icon.modulate = _icon_tint(entry)
	return icon


func _icon_source(entry: Dictionary) -> String:
	var icon_path := String(entry.get(&"icon_ore", ""))
	if icon_path.is_empty():
		return ""
	var stencil := TINT_DIR + icon_path.get_file()
	if stencil != icon_path and ResourceLoader.exists(stencil):
		return stencil
	return icon_path


func _icon_tint(entry: Dictionary) -> Color:
	var ink: Color = Color.WHITE
	var source := _icon_source(entry)
	if source.begins_with(TINT_DIR):
		if source.get_file().begins_with(DEDICATED_ICON_PREFIX):
			ink = _token(&"text_primary")
		else:
			var raw: Variant = Catalog.TIER_TINTS.get(int(entry.get(&"tier", 0)))
			if raw is Color:
				ink = raw
	ink.a = ROW_ICON_IDLE_ALPHA
	return ink


func _add_slack() -> void:
	var slack := Control.new()
	slack.name = "Slack"
	slack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hold_rows.add_child(slack)


func _reselect() -> void:
	if _selected_id == &"":
		return
	for payload: Dictionary in _payloads:
		if payload[&"id"] == _selected_id:
			_arm(payload, false)
			return
	_selected_id = &""
	_stepper = STEPPER_MIN
	_stepper_max = 0


func _arm(payload: Dictionary, cue: bool) -> void:
	var row: Button = payload[&"row"]
	if row == _selected_row and _selected_id == payload[&"id"]:
		return
	if cue:
		AudioManager.play_ui(AudioManager.UiCue.CLICK)
	if _selected_row != null and _selected_row != row and is_instance_valid(_selected_row):
		_selected_row.set_pressed_no_signal(false)
	_selected_row = row
	row.set_pressed_no_signal(true)
	_selected_id = payload[&"id"]
	_stepper_max = RefineryModule.input_conversions(_profile(), _selected_id)
	_stepper = maxi(STEPPER_MIN, _stepper_max)
	_refresh_box()
	_refresh_affordability()


func _clear_selection() -> void:
	if _selected_row != null and is_instance_valid(_selected_row):
		_selected_row.set_pressed_no_signal(false)
	_selected_row = null
	_selected_id = &""
	_stepper = STEPPER_MIN
	_stepper_max = 0
	_refresh_box()
	_refresh_affordability()


## S8 copy law (CONTRACTS section 21): one conversion reads `1 CONVERSION`, the
## stepper's singular; every other count keeps the plural form.
func _conversions_text(count: int) -> String:
	if count == 1:
		return STEPPER_ONE
	if count == 0:
		return STEPPER_IDLE
	return STEPPER_FORMAT % count


func _armed() -> bool:
	return _selected_id != &"" and _stepper_max >= 1


func _refresh_box() -> void:
	var profile := _profile()
	var armed := _selected_id != &""
	if armed:
		_selected_name.text = _selected_name_text().to_upper()
		_stepper_value.text = _conversions_text(_stepper)
	else:
		_selected_name.text = SELECTED_NONE
		_stepper_value.text = STEPPER_IDLE
	_queue_button.text = QUEUE_FORMAT % _stepper
	_queue_button.disabled = not _armed()
	_stepper_less.disabled = not armed or _stepper <= STEPPER_MIN
	_stepper_more.disabled = not armed or _stepper >= _stepper_max
	_queue_all_button.disabled = _queueable_total() < 1
	_cancel_button.disabled = _selected_job_id < 0
	_load_button.disabled = not _load_available()
	_collect_button.disabled = RefineryModule.output_total(profile) < 1 if profile != null else true
	_ore_in.text = _format_int(_stepper * RefineryModule.ORE_PER_INGOT) if _armed() else ZERO_TEXT
	_ingots_out.text = _format_int(_stepper) if _armed() else ZERO_TEXT
	_fee_value.text = FEE_FORMAT % _format_int(_selected_fee() if _armed() else 0)
	_time_value.text = _selected_time_text() if _armed() else ZERO_TIME


func _refresh_affordability() -> void:
	var profile := _profile()
	_colour_fee(_fee_value, profile, _selected_fee() if _armed() else 0)


func _colour_fee(cell: Label, profile: ProfileScript, fee: int) -> void:
	if profile != null and not bool(profile.call(&"can_afford", fee)):
		cell.add_theme_color_override(&"font_color", _token(&"accent_danger"))
		return
	cell.remove_theme_color_override(&"font_color")


func _refresh_tag() -> void:
	var stacks := _stacks()
	if stacks.is_empty():
		_tag.text = TAG_EMPTY
		return
	var conversions := 0
	for stack: Dictionary in stacks:
		conversions += int(stack.get(&"conversions", 0))
	_tag.text = TAG_FORMAT % [
		StationCatalogScript.plural(stacks.size(), "STACK"),
		StationCatalogScript.plural(conversions, "CONVERSION"),
	]


func _refresh_footer() -> void:
	if _queueable_total() >= 1:
		_footer.text = FOOTER_FORMAT % [
			RefineryModule.ORE_PER_INGOT,
			RefineryModule.FEE_PER_CONVERSION,
		]
		return
	if not _stacks().is_empty():
		_footer.text = FOOTER_LOAD
		return
	_footer.text = FOOTER_EMPTY


## ------------------------------------------------------------------- the RIGHT jobs


func _build_jobs() -> void:
	_clear_jobs()
	var jobs := RefineryModule.jobs(_profile())
	if jobs.is_empty():
		_build_empty_job_row()
	else:
		for job: Dictionary in jobs:
			_job_payloads.append(_build_job_row(job))
		_add_job_slack()
	_job_signature = _live_signature()
	_refresh_box()


func _clear_jobs() -> void:
	_job_payloads.clear()
	for child: Node in _jobs_rows.get_children():
		_jobs_rows.remove_child(child)
		child.queue_free()


func _build_empty_job_row() -> void:
	var row := Button.new()
	row.name = "EmptyJobRow"
	row.disabled = true
	row.focus_mode = Control.FOCUS_NONE
	row.custom_minimum_size = Vector2(0.0, JOB_ROW_HEIGHT)
	var box := _make_inner(row)
	var label := _make_label(&"StationCaption", EMPTY_JOB_ROW)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(label)
	_jobs_rows.add_child(row)


func _build_job_row(job: Dictionary) -> Dictionary:
	var job_id := int(job.get(&"id", -1))
	var mineral_id := StringName(job.get(&"mineral_id", &""))
	var entry := Catalog.mineral(mineral_id)
	var name_text := String(entry.get(&"name", String(mineral_id))).to_upper()
	var ingots := int(job.get(&"conversions", 0))
	var state := StringName(job.get(&"state", RefineryModule.JOB_PENDING))
	var row := Button.new()
	row.name = "Job%d" % job_id
	row.toggle_mode = true
	row.focus_mode = Control.FOCUS_ALL
	row.custom_minimum_size = Vector2(0.0, JOB_ROW_HEIGHT)
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	## S36 (UI_SPEC section 15.1): the job row wears C4 `ui_row_strip`.
	ChromeFamily.apply_row(row)
	var box := _make_inner(row)
	var label := _make_label(&"StationValue", _job_line(state, name_text, ingots))
	label.name = "JobLine"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(label)
	var time := _make_value_cell(box, COL_STATE, "Time")
	time.text = _job_time_text(job)
	var payload := {&"id": job_id, &"row": row, &"time": time, &"state": state}
	row.pressed.connect(_on_job_pressed.bind(job_id))
	_jobs_rows.add_child(row)
	if job_id == _selected_job_id:
		row.set_pressed_no_signal(true)
	return payload


func _add_job_slack() -> void:
	var slack := Control.new()
	slack.name = "Slack"
	slack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_jobs_rows.add_child(slack)


func _job_line(state: StringName, name_text: String, ingots: int) -> String:
	var count := StationCatalogScript.plural(ingots, "INGOT")
	if state == RefineryModule.JOB_DONE:
		return JOB_DONE_FORMAT % [name_text, count]
	if state == RefineryModule.JOB_RUNNING:
		return JOB_LINE_FORMAT % [name_text, count, JOB_RUNNING_TAG]
	return JOB_LINE_FORMAT % [name_text, count, JOB_PENDING_TAG]


func _job_time_text(job: Dictionary) -> String:
	if StringName(job.get(&"state", RefineryModule.JOB_PENDING)) != RefineryModule.JOB_RUNNING:
		return ""
	var remaining := maxi(int(job.get(&"ready_at", 0)) - int(Time.get_unix_time_from_system()), 0)
	return _mmss(remaining)


func _refresh_countdowns() -> void:
	var jobs := RefineryModule.jobs(_profile())
	var by_id: Dictionary = {}
	for job: Dictionary in jobs:
		by_id[int(job.get(&"id", -1))] = job
	for payload: Dictionary in _job_payloads:
		var job: Dictionary = by_id.get(int(payload[&"id"]), {})
		var time: Label = payload[&"time"]
		if job.is_empty():
			continue
		time.text = _job_time_text(job)


## The signature of the jobs the profile currently holds, so a tick can tell a
## countdown change (refresh in place) from a state change (rebuild).
func _live_signature() -> PackedStringArray:
	var signature := PackedStringArray()
	for job: Dictionary in RefineryModule.jobs(_profile()):
		signature.append("%d:%s" % [int(job.get(&"id", -1)), String(job.get(&"state", ""))])
	return signature


func _select_job(job_id: int) -> void:
	_selected_job_id = job_id
	for payload: Dictionary in _job_payloads:
		var row: Button = payload[&"row"]
		row.set_pressed_no_signal(int(payload[&"id"]) == job_id)
	_refresh_box()


func _on_job_pressed(job_id: int) -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	_select_job(-1 if _selected_job_id == job_id else job_id)


## ------------------------------------------------------------------- interactions


func _on_row_focused(_row: Button, payload: Dictionary) -> void:
	_focused_payload = payload
	_arm(payload, true)
	_inspect_row(payload, true)


func _on_row_pressed(payload: Dictionary) -> void:
	if _inspect_mode:
		_emit_sheet(payload)
		return
	_arm(payload, true)
	_inspect_row(payload, true)


func _on_row_hovered(payload: Dictionary, hovered: bool) -> void:
	_inspect_row(payload, hovered)
	var icon: TextureRect = payload[&"icon"]
	if icon == null:
		return
	var target := 1.0 if hovered else ROW_ICON_IDLE_ALPHA
	var tween := _make_tween()
	tween.tween_property(icon, "modulate:a", target, HOVER_SECONDS)


## CONTRACTS section 23.1: the ore row's additive inspector line. The row's own
## identity line (name, conversions and fee) is the title; the body is whatever
## `StationCatalog.describe` answers for the row's own id.
func _inspect_row(payload: Dictionary, shown: bool) -> void:
	if not shown:
		inspect_requested.emit("", "", false)
		return
	inspect_requested.emit(
		INSPECT_TITLE_FORMAT % [
			String(payload[&"name"]).to_upper(),
			_conversions_text(int(payload[&"conversions"])),
			_format_int(int(payload[&"fee"])),
		],
		StationCatalogScript.describe(StringName(payload[&"id"])),
		false,
	)


## N37 rev (owner 2026-10-07): the station's one INSPECT toggle. On, an item press opens the
## sheet instead of the normal action; the per-row INSPECT chip is retired.
var _inspect_mode := false


func set_inspect_mode(on: bool) -> void:
	_inspect_mode = on


func _emit_sheet(payload: Dictionary) -> void:
	var sheet := _sheet_payload(payload)
	if not sheet.is_empty():
		sheet_requested.emit(sheet)


func _sheet_payload(payload: Dictionary) -> Dictionary:
	var mineral_id: StringName = payload.get(&"id", &"")
	if mineral_id == &"":
		return {}
	var out := {
		&"name": String(payload.get(&"name", "")).to_upper(),
		&"stats": StationCatalogScript.describe(mineral_id),
	}
	var ore := int(payload.get(&"ore", -1))
	if ore >= 0:
		out[&"owned"] = ore
	return out


func _on_scroll_started() -> void:
	AudioManager.play_ui(AudioManager.UiCue.SCROLL)


func _on_stepper_pressed(step: int) -> void:
	if _selected_id == &"":
		return
	var next := clampi(_stepper + step, STEPPER_MIN, maxi(_stepper_max, STEPPER_MIN))
	if next == _stepper:
		return
	AudioManager.play_ui(AudioManager.UiCue.SCROLL)
	_stepper = next
	_refresh_box()
	_refresh_affordability()


func _on_queue_pressed() -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	var profile := _profile()
	if profile == null or not _armed():
		return
	var mineral_id := _selected_id
	var name_text := _selected_name_text()
	var conversions := _stepper
	var fee := RefineryModule.fee_for(conversions, RefineryModule.fee_multiplier(profile))
	_begin()
	var result: Dictionary = RefineryModule.queue(profile, mineral_id, conversions)
	_end()
	if bool(result.get(&"ok", false)):
		AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
		status_requested.emit(
			STATUS_QUEUED % [
				name_text.to_upper(),
				StationCatalogScript.plural(conversions, "INGOT"),
				_format_int(fee),
			],
			false
		)
		return
	AudioManager.play_ui(AudioManager.UiCue.DENIED)
	status_requested.emit(_refusal_text(result.get(&"reason", &""), fee, conversions), true)


func _on_queue_all_pressed() -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	var profile := _profile()
	if profile == null:
		return
	var fee := _queueable_fee()
	_begin()
	var result: Dictionary = RefineryModule.queue_all(profile)
	_end()
	if bool(result.get(&"ok", false)):
		AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
		status_requested.emit(
			STATUS_QUEUED_ALL % [
				StationCatalogScript.plural(int(result.get(&"ingots", 0)), "INGOT"),
				_format_int(int(result.get(&"fee", fee))),
			],
			false
		)
		return
	AudioManager.play_ui(AudioManager.UiCue.DENIED)
	status_requested.emit(_refusal_text(result.get(&"reason", &""), fee, int(result.get(&"conversions", 0))), true)


func _on_cancel_pressed() -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	var profile := _profile()
	if profile == null:
		return
	if _selected_job_id < 0:
		if disarm():
			status_requested.emit(STATUS_IDLE, false)
		return
	var job_id := _selected_job_id
	var job := _job_by_id(job_id)
	var name_text := _mineral_name(StringName(job.get(&"mineral_id", &""))).to_upper()
	var ore_units := int(job.get(&"conversions", 0)) * RefineryModule.ORE_PER_INGOT
	_begin()
	var result: Dictionary = RefineryModule.cancel(profile, job_id)
	_end()
	_select_job(-1)
	if bool(result.get(&"ok", false)):
		AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
		status_requested.emit(
			STATUS_CANCELLED % [name_text, StationCatalogScript.plural(ore_units, "ORE UNIT")],
			false
		)
		return
	AudioManager.play_ui(AudioManager.UiCue.DENIED)
	status_requested.emit(STATUS_REFUSED_EMPTY, true)


func _on_load_pressed() -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	var profile := _profile()
	if profile == null or _selected_id == &"":
		return
	var units := _load_units()
	if units < 1:
		AudioManager.play_ui(AudioManager.UiCue.DENIED)
		status_requested.emit(STATUS_REFUSED_INPUT, true)
		return
	var name_text := _selected_name_text()
	_begin()
	var result: Dictionary = RefineryModule.load_ore(profile, _selected_id, units)
	_end()
	if bool(result.get(&"ok", false)):
		AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
		status_requested.emit(
			STATUS_LOADED % [name_text.to_upper(), StationCatalogScript.plural(units, "ORE UNIT")],
			false
		)
		return
	AudioManager.play_ui(AudioManager.UiCue.DENIED)
	status_requested.emit(_refusal_text(result.get(&"reason", &""), 0, 0), true)


func _on_collect_pressed() -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	var profile := _profile()
	if profile == null:
		return
	_begin()
	var result: Dictionary = RefineryModule.collect_all(profile)
	_end()
	if bool(result.get(&"ok", false)):
		AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
		status_requested.emit(
			STATUS_COLLECTED % StationCatalogScript.plural(int(result.get(&"collected", 0)), "INGOT"),
			false
		)
		return
	AudioManager.play_ui(AudioManager.UiCue.DENIED)
	status_requested.emit(STATUS_OUTPUT_FULL, true)


func _on_upgrade_pressed() -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	var profile := _profile()
	if profile == null:
		return
	_begin()
	var result: Dictionary = RefineryModule.upgrade_slots(profile)
	_end()
	if bool(result.get(&"ok", false)):
		AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
		status_requested.emit(STATUS_UPGRADED % int(result.get(&"slots", 0)), false)
		return
	AudioManager.play_ui(AudioManager.UiCue.DENIED)
	if StringName(result.get(&"reason", &"")) == RefineryModule.REASON_MAX_SLOTS:
		status_requested.emit(STATUS_REFUSED_MAX_SLOTS, true)
		return
	status_requested.emit(
		STATUS_REFUSED_CREDITS % _format_int(RefineryModule.SLOT_UPGRADE_COST), true
	)


## Run one module transaction inside the deferred-rebuild guard, then flush any
## rebuild the transaction's own signals asked for.
func _begin() -> void:
	_transaction = true


func _end() -> void:
	_transaction = false
	if _rebuild_pending:
		_rebuild_pending = false
		_rebuild_all()


func _rebuild_all() -> void:
	_build_rows()
	_build_jobs()
	_refresh_slots()


func _refusal_text(reason: Variant, fee: int, conversions: int) -> String:
	var key := StringName(reason)
	if key == &"insufficient_credits":
		return STATUS_REFUSED_CREDITS % _format_int(fee)
	if key == &"insufficient_ore":
		return STATUS_REFUSED_ORE % _format_int(conversions * RefineryModule.ORE_PER_INGOT)
	if key == &"input_full":
		return STATUS_REFUSED_INPUT
	if key == &"invalid_count":
		return STATUS_REFUSED_COUNT
	if key == &"nothing_to_queue" or key == &"nothing_to_refine":
		return STATUS_REFUSED_EMPTY
	return STATUS_REFUSED_UNKNOWN


## ------------------------------------------------------------------------- helpers


func _selected_fee() -> int:
	return RefineryModule.fee_for(_stepper, RefineryModule.fee_multiplier(_profile()))


func _selected_time_text() -> String:
	var seconds := RefineryModule.resource_seconds(_selected_id) * _stepper
	return _mmss(seconds)


func _selected_name_text() -> String:
	for payload: Dictionary in _payloads:
		if payload[&"id"] == _selected_id:
			return String(payload[&"name"])
	return ""


func _mineral_name(mineral_id: StringName) -> String:
	var entry := Catalog.mineral(mineral_id)
	return String(entry.get(&"name", String(mineral_id)))


func _job_by_id(job_id: int) -> Dictionary:
	for job: Dictionary in RefineryModule.jobs(_profile()):
		if int(job.get(&"id", -1)) == job_id:
			return job
	return {}


func _stacks() -> Array[Dictionary]:
	var profile := _profile()
	if profile == null:
		var none: Array[Dictionary] = []
		return none
	return RefineryModule.stacks(profile)


## One row per mineral whose input holds ore, in catalogue order, shaped like a
## `stacks` row (the LEFT block's input inventory).
func _input_stacks() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var profile := _profile()
	if profile == null:
		return rows
	for entry: Dictionary in Catalog.MINERALS:
		var mineral_id: StringName = entry.get(&"id", &"")
		if mineral_id == &"":
			continue
		var units := RefineryModule.input_units(profile, mineral_id)
		if units < 1:
			continue
		rows.append({&"mineral_id": mineral_id, &"entry": entry, &"ore_qty": units})
	return rows


## How many minerals the input can queue at least one conversion for (QUEUE ALL).
func _queueable_total() -> int:
	var profile := _profile()
	if profile == null:
		return 0
	var total := 0
	for entry: Dictionary in Catalog.MINERALS:
		if RefineryModule.input_conversions(profile, entry.get(&"id", &"")) >= 1:
			total += 1
	return total


## The combined fee QUEUE ALL would charge, read off the same input the button acts on.
func _queueable_fee() -> int:
	var profile := _profile()
	if profile == null:
		return 0
	var mult := RefineryModule.fee_multiplier(profile)
	var total := 0
	for entry: Dictionary in Catalog.MINERALS:
		var conversions := RefineryModule.input_conversions(profile, entry.get(&"id", &""))
		if conversions >= 1:
			total += RefineryModule.fee_for(conversions, mult)
	return total


func _load_available() -> bool:
	return _selected_id != &"" and _load_units() >= 1


func _load_units() -> int:
	var profile := _profile()
	if profile == null or _selected_id == &"":
		return 0
	var ore_id: StringName = Catalog.ore_id(_selected_id)
	var held := int(profile.call(&"cargo_qty", ore_id))
	var space := RefineryModule.INPUT_CAP - RefineryModule.input_total(profile)
	return clampi(mini(held, space), 0, RefineryModule.INPUT_CAP)


func _profile() -> ProfileScript:
	if not is_inside_tree():
		return null
	var service := get_tree().root.get_node_or_null(NodePath(PROFILE_SERVICE))
	if service == null:
		return null
	var profile: ProfileScript = service
	return profile


func _apply_tokens() -> void:
	_pane_icon.modulate = _token(&"text_primary")
	for payload: Dictionary in _payloads:
		var icon: TextureRect = payload[&"icon"]
		if icon != null:
			icon.modulate = payload[&"tint"]


func _token(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.WHITE


func _make_tween() -> Tween:
	for index in range(_tweens.size() - 1, -1, -1):
		if not _tweens[index].is_valid():
			_tweens.remove_at(index)
	var tween := create_tween()
	_tweens.append(tween)
	return tween


func _mmss(seconds: int) -> String:
	var clamped := maxi(seconds, 0)
	@warning_ignore("integer_division")
	var minutes := clamped / 60
	return "%02d:%02d" % [minutes, clamped % 60]


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


## The header's slot price reads the §21.3 wording `3,000 CR` (comma-grouped, not
## the house `_format_int`'s spaces), so the label matches the pinned copy.
func _format_cost(value: int) -> String:
	var digits := str(absi(value))
	var grouped := ""
	var count := 0
	for index in range(digits.length() - 1, -1, -1):
		grouped = digits[index] + grouped
		count += 1
		if count % 3 == 0 and index > 0:
			grouped = "," + grouped
	return ("-" if value < 0 else "") + grouped
