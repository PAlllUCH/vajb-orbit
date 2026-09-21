extends Screen
## Station hub shell: backdrop, grain, safe area, header with the credits readout, the
## module rail, the module host, the footer, the entry motion, the module switch and the
## focus contract. Contract: docs/design/STATION_HUB.md sections 2 to 12,
## docs/design/STATION_SPEC.md section 6, docs/design/IMPLEMENTATION_PLAN.md section 9.4.
##
## The shell owns the routing intent, the audio hooks, the credits readout, the leave
## confirm and one loaded panel per module. Panels live in res://ui/station/ and are
## loaded by the host, so a module whose panel scene is not written yet degrades to an
## in-place placeholder instead of an error (STATION_HUB section 12.1).
##
## Panel contract, duck typed, the pattern every module panel copies:
##   signal status_requested(message: String, danger: bool)   write the footer strip
##   signal launch_requested()                                LAUNCH panel: undock
##   func refresh_profile(key: StringName) -> void             react to profile_changed
##   func focus_primary() -> void                              focus entry after a switch
##   func disarm() -> bool                                     optional, ui_cancel step 2

const TOKENS_TYPE: StringName = &"Tokens"

const Catalog := preload("res://game/station_catalog.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"

const ROUTE_LOADING: StringName = &"loading"
const ROUTE_MAIN_MENU: StringName = &"main_menu"
const PARAM_DESTINATION: StringName = &"destination"
const DESTINATION_GAME: StringName = &"game"

const REASON_INSUFFICIENT: StringName = &"insufficient_credits"
const REASON_ALREADY_OWNED: StringName = &"already_owned"

const PANEL_DIR := "res://ui/station/"
const PANEL_SUFFIX := "_panel.tscn"
## Marks a pane the host had to synthesise because its panel scene is not written yet,
## so a verifier can tell an offline module from a loaded one at a glance.
const PLACEHOLDER_GROUP: StringName = &"station_placeholder"

## Real files, docs/design/ASSET_AUDIT.md section D.1 items 2, 3, 4, 7, 8 and 9.
const SFX_MODULE_SWITCH: StringName = &"sfx_station_breaker_on_01"
const SFX_LAUNCH_BOOST: StringName = &"sfx_ship_boost_01"
const SFX_LAUNCH_JUMP: StringName = &"sfx_ship_jump_01"
const BED_ROOM: StringName = &"amb_station_room_01"
const BED_PUMP: StringName = &"amb_station_pump_loop_01"
const BED_NOISE: StringName = &"amb_station_noise_loop_01"
const ENTRY_AMBIENCE_FADE := 2.0
const SWITCH_AMBIENCE_FADE := 1.0
const EXIT_AMBIENCE_FADE := 1.0

enum Module { OUTFITTING, REFINERY, EXCHANGE, SHIPYARD, UPGRADES, REPAIRS, LAUNCH }

const MODULE_FILES: Array[String] = [
	"outfitting",
	"refinery",
	"exchange",
	"shipyard",
	"upgrades",
	"repairs",
	"launch",
]
const MODULE_LABELS: Array[String] = [
	"OUTFITTING",
	"REFINERY",
	"EXCHANGE",
	"SHIPYARD",
	"UPGRADES",
	"REPAIRS",
	"LAUNCH",
]
const MODULE_ICONS: Array[String] = [
	"res://assets/icons/equip/icon_equip_module_48.png",
	"res://assets/icons/tint/icon_cargo_ore_48.png",
	"res://assets/icons/tint/icon_credits_48.png",
	"res://assets/icons/tint/icon_hull_48.png",
	"res://assets/icons/equip/icon_equip_generator_48.png",
	"res://assets/icons/status/icon_status_repairing_48.png",
	"res://assets/icons/map/icon_map_route_48.png",
]
const MODULE_TINTED: Array[bool] = [false, true, true, true, false, false, false]
const MODULE_BEDS: Array[StringName] = [
	BED_ROOM, BED_PUMP, BED_NOISE, BED_PUMP, BED_NOISE, BED_ROOM, BED_ROOM
]
const ICON_LOGOUT := "res://assets/icons/tint/icon_logout_48.png"

const RAIL_ENTRY_HEIGHT := 56.0
const RAIL_ICON_SIZE := 40.0
const RAIL_INNER_MARGIN := Vector2i(16, 8)

const ENTRY_SECONDS := 0.30
const ENTRY_DIM_SECONDS := 0.45
const ENTRY_DELAYS: Array[float] = [0.06, 0.12, 0.18, 0.24]
const CREDITS_SECONDS := 0.60
const CREDITS_STEP_SECONDS := 0.35
const MODULE_OUT_SECONDS := 0.12
const MODULE_IN_SECONDS := 0.18
const BEACON_MIN_ALPHA := 0.35
const BEACON_SECONDS := 2.4
const GRAIN_IDLE_ALPHA := 0.06
const GRAIN_PEAK_ALPHA := 0.11
const GRAIN_SECONDS := 5.0
const BACKDROP_DIM_ALPHA := 0.84
const MODAL_DIM_ALPHA := 0.72
const PULSE_MIN_ALPHA := 0.35
const PULSE_DOWN_SECONDS := 0.12
const PULSE_UP_SECONDS := 0.16

const STATUS_DOCKED := "DOCKED · ALL SYSTEMS NOMINAL"

@onready var _backdrop_dim: ColorRect = %BackdropDim
@onready var _grain: TextureRect = %Grain
@onready var _fade: ColorRect = %Fade
@onready var _header: HBoxContainer = %Header
@onready var _footer: HBoxContainer = %Footer
@onready var _credits_panel: PanelContainer = %CreditsPanel
@onready var _credits_icon: TextureRect = %CreditsIcon
@onready var _credits_value: Label = %CreditsValue
@onready var _module_rail: PanelContainer = %ModuleRail
@onready var _module_buttons: VBoxContainer = %ModuleButtons
@onready var _session_buttons: VBoxContainer = %SessionButtons
@onready var _module_host: PanelContainer = %ModuleHost
@onready var _host_margin: MarginContainer = %HostMargin
@onready var _status_label: Label = %StatusLabel
@onready var _beacon: ColorRect = %StatusBeacon
@onready var _leave_confirm: Control = %LeaveConfirm
@onready var _leave_dimmer: ColorRect = %LeaveDimmer
@onready var _leave_cancel: Button = %LeaveCancel
@onready var _leave_logout: Button = %LeaveLogout

var _module: int = Module.OUTFITTING
var _panels: Array[CanvasItem] = []
var _module_entries: Array[Button] = []
var _displayed_credits := 0
var _status_danger := false
var _tweens: Array[Tween] = []


func _ready() -> void:
	_build_rail()
	_build_panels()
	_apply_tokens()
	_refresh_credits()
	_wire_controls()
	_connect_profile()
	_select_module(_module, true)
	_play_entry()
	_start_idle()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_apply_tokens()


func _exit_tree() -> void:
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()


func on_route(_params: Dictionary) -> void:
	_focus_active_panel()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		if Router.overlay_depth() > 0:
			return
		_handle_cancel()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey:
		# station_prev_module / station_next_module are not in the input map, so the
		# keycodes are read directly (STATION_HUB sections 10 and 14 item 6).
		var key := event as InputEventKey
		if not key.pressed or key.echo:
			return
		if key.keycode == KEY_PAGEUP:
			_cycle_module(-1)
			get_viewport().set_input_as_handled()
		elif key.keycode == KEY_PAGEDOWN:
			_cycle_module(1)
			get_viewport().set_input_as_handled()
		return
	if event is InputEventJoypadButton:
		var pad := event as InputEventJoypadButton
		if not pad.pressed:
			return
		if pad.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			_cycle_module(1)
			get_viewport().set_input_as_handled()
		elif pad.button_index == JOY_BUTTON_LEFT_SHOULDER:
			_cycle_module(-1)
			get_viewport().set_input_as_handled()


func _wire_controls() -> void:
	_leave_cancel.pressed.connect(_close_leave_confirm)
	_leave_logout.pressed.connect(_on_logout_pressed)


func _connect_profile() -> void:
	var profile := _profile()
	if profile == null:
		return
	if not profile.is_connected(&"profile_changed", _on_profile_changed):
		profile.connect(&"profile_changed", _on_profile_changed)
	if not profile.is_connected(&"purchase_failed", _on_purchase_failed):
		profile.connect(&"purchase_failed", _on_purchase_failed)


func _apply_tokens() -> void:
	var dim: Color = _token(&"void_base")
	dim.a = BACKDROP_DIM_ALPHA
	_backdrop_dim.color = dim
	var modal: Color = _token(&"void_base")
	modal.a = MODAL_DIM_ALPHA
	_leave_dimmer.color = modal
	var fade: Color = _token(&"void_fade")
	fade.a = 0.0
	_fade.color = fade
	_credits_icon.modulate = _token(&"text_primary")
	_beacon.color = _token(&"accent_danger")
	_grain.modulate = Color(1.0, 1.0, 1.0, GRAIN_IDLE_ALPHA)
	_apply_status_colour()


func _token(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.WHITE


func _build_rail() -> void:
	for index in MODULE_LABELS.size():
		var entry := _make_rail_entry(
			_module_buttons, MODULE_LABELS[index], MODULE_ICONS[index], MODULE_TINTED[index]
		)
		entry.pressed.connect(_on_module_pressed.bind(index))
		_module_entries.append(entry)
	var logout := _make_rail_entry(_session_buttons, "LOG OUT", ICON_LOGOUT, true)
	logout.pressed.connect(_on_logout_pressed)


func _make_rail_entry(
	parent: VBoxContainer, label_text: String, icon_path: String, tinted: bool
) -> Button:
	var button := Button.new()
	button.name = "%sEntry" % label_text.to_pascal_case()
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_ALL
	button.theme_type_variation = &"StationButton"
	button.custom_minimum_size = Vector2(0.0, RAIL_ENTRY_HEIGHT)
	var box := _make_inner(button, RAIL_INNER_MARGIN)
	box.add_child(_make_icon(icon_path, tinted, RAIL_ICON_SIZE))
	var label := Label.new()
	label.theme_type_variation = &"StationPanelTitle"
	label.text = label_text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)
	parent.add_child(button)
	return button


func _build_panels() -> void:
	_panels.clear()
	for index in MODULE_FILES.size():
		var pane := _load_panel(index)
		pane.visible = false
		_host_margin.add_child(pane)
		_panels.append(pane)


func _load_panel(index: int) -> CanvasItem:
	var path := PANEL_DIR + MODULE_FILES[index] + PANEL_SUFFIX
	if not ResourceLoader.exists(path):
		return _make_placeholder(index, path)
	var packed := load(path) as PackedScene
	if packed == null:
		return _make_placeholder(index, path)
	var pane := packed.instantiate() as CanvasItem
	if pane == null:
		return _make_placeholder(index, path)
	pane.name = MODULE_LABELS[index].to_pascal_case()
	_connect_panel(pane)
	return pane


func _connect_panel(pane: Node) -> void:
	if pane.has_signal(&"status_requested"):
		pane.connect(&"status_requested", _on_panel_status)
	if pane.has_signal(&"launch_requested"):
		pane.connect(&"launch_requested", _on_launch_requested)


func _make_placeholder(index: int, path: String) -> CanvasItem:
	## An unwritten module panel is a build order fact, not a failure: the module names
	## itself and stays inert instead of erroring, warning or crashing. The node keeps
	## the module's own name, so the host's one pane per module contract holds.
	var pane := VBoxContainer.new()
	pane.name = MODULE_LABELS[index].to_pascal_case()
	pane.add_to_group(PLACEHOLDER_GROUP)
	pane.add_theme_constant_override(&"separation", 12)
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pane.add_child(center)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override(&"separation", 6)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(stack)
	stack.add_child(_make_label(&"StationPanelTitle", "MODULE OFFLINE"))
	stack.add_child(
		_make_label(&"StationCaption", "%s PANEL IS NOT INSTALLED YET" % MODULE_LABELS[index])
	)
	stack.add_child(_make_label(&"StationCaption", "EXPECTED AT %s" % path))
	return pane


func _make_label(variation: StringName, text: String) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_inner(button: Button, margin: Vector2i) -> HBoxContainer:
	var inner := MarginContainer.new()
	inner.name = "RowInner"
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override(&"margin_left", margin.x)
	inner.add_theme_constant_override(&"margin_top", margin.y)
	inner.add_theme_constant_override(&"margin_right", margin.x)
	inner.add_theme_constant_override(&"margin_bottom", margin.y)
	button.add_child(inner)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := HBoxContainer.new()
	box.add_theme_constant_override(&"separation", 12)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(box)
	return box


func _make_icon(icon_path: String, tinted: bool, icon_size: float) -> TextureRect:
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = load(icon_path)
	icon.modulate = _token(&"text_primary") if tinted else Color.WHITE
	return icon


func _on_module_pressed(module: int) -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	_select_module(module)


func _cycle_module(step: int) -> void:
	_select_module(posmod(_module + step, _module_entries.size()))


func _select_module(module: int, instant: bool = false) -> void:
	if module == _module and not instant:
		return
	var outgoing := _panel_for(_module)
	var incoming := _panel_for(module)
	_module = module
	for index in _module_entries.size():
		_module_entries[index].set_pressed_no_signal(index == module)
	if not instant:
		AudioManager.play_sfx(SFX_MODULE_SWITCH)
		AudioManager.play_ambience(MODULE_BEDS[module], SWITCH_AMBIENCE_FADE)
	_set_status(STATUS_DOCKED, false)
	if instant or outgoing == null or outgoing == incoming:
		for pane: CanvasItem in _panels:
			pane.visible = pane == incoming
		incoming.modulate.a = 1.0
		_focus_active_panel()
		return
	incoming.visible = true
	incoming.modulate.a = 0.0
	var tween := _make_tween()
	tween.tween_property(outgoing, "modulate:a", 0.0, MODULE_OUT_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(outgoing.hide)
	tween.tween_property(incoming, "modulate:a", 1.0, MODULE_IN_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_focus_active_panel)


func _panel_for(module: int) -> CanvasItem:
	if module < 0 or module >= _panels.size():
		return null
	return _panels[module]


func _focus_active_panel() -> void:
	## A panel with nothing focusable (the offline placeholder) leaves the ring on a
	## hidden row, so the rail entry takes it instead.
	var panel := _panel_for(_module)
	if panel != null and panel.has_method(&"focus_primary"):
		panel.call(&"focus_primary")
		var focus_owner := get_viewport().gui_get_focus_owner()
		if focus_owner != null and panel.is_ancestor_of(focus_owner):
			return
	_focus_current_rail_entry()


func _focus_current_rail_entry() -> void:
	if _module >= 0 and _module < _module_entries.size():
		_module_entries[_module].grab_focus()


func _on_panel_status(message: String, danger: bool) -> void:
	_set_status(message, danger)


func _on_launch_requested() -> void:
	## LAUNCH panels declare the undock; only the shell routes (Screen intent contract).
	AudioManager.play_sfx(SFX_LAUNCH_BOOST)
	AudioManager.play_sfx(SFX_LAUNCH_JUMP)
	AudioManager.stop_ambience(EXIT_AMBIENCE_FADE)
	route_requested.emit(ROUTE_LOADING, {PARAM_DESTINATION: DESTINATION_GAME})


func _on_logout_pressed() -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	_close_leave_confirm()
	AudioManager.stop_ambience(EXIT_AMBIENCE_FADE)
	route_requested.emit(ROUTE_MAIN_MENU, {})


func _on_profile_changed(key: StringName) -> void:
	if key == &"credits":
		_animate_credits(_displayed_credits, _credits(), CREDITS_STEP_SECONDS)
	for pane: CanvasItem in _panels:
		if pane != null and pane.has_method(&"refresh_profile"):
			pane.call(&"refresh_profile", key)


func _on_purchase_failed(reason: StringName, id: StringName) -> void:
	## The refusal is never a dialog (STATION_HUB section 5.6): strip text, one cue and
	## the pulse. Focus and the selection stay where they were.
	AudioManager.play_ui(AudioManager.UiCue.DENIED)
	_set_status(_refusal_text(reason, id), true)
	_pulse(_credits_panel)


func _refusal_text(reason: StringName, id: StringName) -> String:
	if reason == REASON_INSUFFICIENT:
		return "REFUSED · NOT ENOUGH CREDITS · %s NEEDED" % _format_int(_entry_cost(id))
	if reason == REASON_ALREADY_OWNED:
		return "REFUSED · %s · %s" % [_owned_state_text(id), _entry_name(id)]
	return "REFUSED · NOT FOR SALE"


func _owned_state_text(id: StringName) -> String:
	var profile := _profile()
	if profile != null and id == StringName(profile.call(&"active_ship")):
		return "ALREADY THE ACTIVE HULL"
	if not Catalog.upgrade(id).is_empty():
		return "ALREADY INSTALLED"
	return "ALREADY OWNED"


func _entry_name(id: StringName) -> String:
	return String(_entry(id).get(&"name", String(id))).to_upper()


func _entry_cost(id: StringName) -> int:
	return int(_entry(id).get(&"cost", 0))


func _entry(id: StringName) -> Dictionary:
	## purchase_failed carries only the reason and the id, so the copy resolves the
	## entry and its price from the catalogue the panel bought from.
	var entry := Catalog.ammo_pack(id)
	if entry.is_empty():
		entry = Catalog.ship(id)
	if entry.is_empty():
		entry = Catalog.upgrade(id)
	return entry


func _credits() -> int:
	var profile := _profile()
	if profile == null:
		return 0
	return int(profile.call(&"credits"))


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


func _set_status(message: String, danger: bool) -> void:
	_status_label.text = message
	_status_danger = danger
	_apply_status_colour()


func _apply_status_colour() -> void:
	var token: StringName = &"accent_danger" if _status_danger else &"text_primary"
	_status_label.add_theme_color_override(&"font_color", _token(token))


func _refresh_credits() -> void:
	_displayed_credits = _credits()
	_credits_value.text = _format_int(_displayed_credits)


func _animate_credits(from: int, to: int, seconds: float) -> void:
	var tween := _make_tween()
	tween.tween_method(_set_credits_text, float(from), float(to), seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _set_credits_text(value: float) -> void:
	_displayed_credits = roundi(value)
	_credits_value.text = _format_int(_displayed_credits)


func _pulse(node: CanvasItem) -> void:
	var tween := _make_tween()
	tween.tween_property(node, "modulate:a", PULSE_MIN_ALPHA, PULSE_DOWN_SECONDS).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "modulate:a", 1.0, PULSE_UP_SECONDS).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "modulate:a", PULSE_MIN_ALPHA, PULSE_DOWN_SECONDS).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "modulate:a", 1.0, PULSE_UP_SECONDS).set_trans(Tween.TRANS_SINE)


func _handle_cancel() -> void:
	if _leave_confirm.visible:
		_close_leave_confirm()
		return
	var panel := _panel_for(_module)
	if panel != null and panel.has_method(&"disarm") and bool(panel.call(&"disarm")):
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and not _rail_has_focus(focused):
		_focus_current_rail_entry()
		return
	_open_leave_confirm()


func _rail_has_focus(control: Control) -> bool:
	return _module_buttons.is_ancestor_of(control) or _session_buttons.is_ancestor_of(control)


func _open_leave_confirm() -> void:
	_leave_confirm.visible = true
	_leave_cancel.grab_focus()
	_set_status("LEAVE THE STATION? · ESC STAYS DOCKED", false)


func _close_leave_confirm() -> void:
	_leave_confirm.visible = false
	_focus_current_rail_entry()


func _play_entry() -> void:
	AudioManager.play_ambience(BED_ROOM, ENTRY_AMBIENCE_FADE)
	_backdrop_dim.color.a = 0.0
	_header.modulate.a = 0.0
	_module_rail.modulate.a = 0.0
	_module_host.modulate.a = 0.0
	_footer.modulate.a = 0.0
	var tween := _make_tween()
	tween.set_parallel(true)
	tween.tween_property(_backdrop_dim, "color:a", BACKDROP_DIM_ALPHA, ENTRY_DIM_SECONDS)
	tween.tween_property(_header, "modulate:a", 1.0, ENTRY_SECONDS).set_delay(ENTRY_DELAYS[0])
	tween.tween_property(_module_rail, "modulate:a", 1.0, ENTRY_SECONDS).set_delay(ENTRY_DELAYS[1])
	tween.tween_property(_module_host, "modulate:a", 1.0, ENTRY_SECONDS).set_delay(ENTRY_DELAYS[2])
	tween.tween_property(_footer, "modulate:a", 1.0, ENTRY_SECONDS).set_delay(ENTRY_DELAYS[3])
	_animate_credits(0, _credits(), CREDITS_SECONDS)


func _start_idle() -> void:
	var grain := _make_tween().set_loops()
	grain.set_trans(Tween.TRANS_SINE)
	grain.tween_property(_grain, "modulate:a", GRAIN_PEAK_ALPHA, GRAIN_SECONDS)
	grain.tween_property(_grain, "modulate:a", GRAIN_IDLE_ALPHA, GRAIN_SECONDS)
	var beacon := _make_tween().set_loops()
	beacon.set_trans(Tween.TRANS_SINE)
	beacon.tween_property(_beacon, "modulate:a", BEACON_MIN_ALPHA, BEACON_SECONDS)
	beacon.tween_property(_beacon, "modulate:a", 1.0, BEACON_SECONDS)


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
