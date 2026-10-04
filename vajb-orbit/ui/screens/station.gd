extends Screen
## Station hub shell v2 (S30): backdrop, grain, safe area, the header band (TERMINAL
## button + station identity plate + credits housing), one pane at full body width, the
## footer status strip, the TERMINAL drawer overlay, the entry motion, the deck switch and
## the focus contract. Contract: docs/design/STATION_HUB.md sections 2 to 12, 18 and 19,
## docs/design/UI_SPEC.md sections 11 and 12, docs/design/STATION_SPEC.md section 6.
##
## The shell owns the routing intent, the audio hooks, the credits readout, the leave
## confirm, the drawer and one loaded panel per deck. Panels live in res://ui/station/ and
## are loaded by the host, so a module whose panel scene is not written yet degrades to an
## in-place placeholder instead of an error (STATION_HUB section 12.1).
##
## Panel contract, duck typed, the pattern every module panel copies:
##   signal status_requested(message: String, danger: bool)   write the footer strip
##   signal inspect_requested(title: String, body: String, danger: bool)  the hover tooltip
##   signal sheet_requested(payload: Dictionary)               the INSPECT sheet
##   signal navigate_requested(deck: int, hint: StringName)    a pane's deep link
##   signal launch_requested()                                LAUNCH panel: undock
##   func refresh_profile(key: StringName) -> void             react to profile_changed
##   func focus_primary() -> void                              focus entry after a switch
##   func disarm() -> bool                                     optional, ui_cancel step 2
##   func inspect_focused() -> void                            optional, station_inspect

const TOKENS_TYPE: StringName = &"Tokens"

const Catalog := preload("res://game/station_catalog.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")
const ExchangeScript := preload("res://game/exchange.gd")
const Clock := preload("res://autoload/world_clock.gd")
const TooltipScene := preload("res://ui/components/tooltip.tscn")
const SheetScene := preload("res://ui/components/inspect_sheet.tscn")
const OverviewScene := preload("res://ui/station/overview_panel.tscn")

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

## The six service decks the drawer holds below OVERVIEW. STATION_HUB section 18 P16's
## drawer order is OVERVIEW then these six; P20's cycle is these six alone. Reversal: the
## shipped enum order without OVERVIEW.
enum Module { OUTFITTING, REFINERY, EXCHANGE, AUCTION, SHIPYARD, LAUNCH }

## S30 (STATION_HUB section 19, UI_SPEC section 12.1): the deck indices beyond the six
## service panes. OVERVIEW is the landing pane (P17); SERVICES is P26's deep-link target,
## outside P20's cycle and with no drawer entry. Reversal: OVERVIEW loads last-used, the
## SERVICES slot drops.
const OVERVIEW := 6
const SERVICES := 7

const MODULE_FILES: Array[String] = [
	"armory",
	"refinery",
	"exchange",
	"auction",
	"shipyard",
	"launch",
]
const MODULE_LABELS: Array[String] = [
	"ARMORY",
	"REFINERY",
	"EXCHANGE",
	"AUCTION",
	"SHIPYARD",
	"LAUNCH",
]
const MODULE_ICONS: Array[String] = [
	"res://assets/icons/equip/icon_equip_module.png",
	"res://assets/icons/cargo/icon_cargo_ore.svg",
	"res://assets/icons/cargo/icon_credits.svg",
	"res://assets/icons/cargo/icon_credits.svg",
	"res://assets/icons/hud/icon_hull.svg",
	"res://assets/icons/map/icon_map_route.png",
]
const MODULE_TINTED: Array[bool] = [false, true, true, true, true, false]
const MODULE_BEDS: Array[StringName] = [
	BED_ROOM, BED_PUMP, BED_NOISE, BED_NOISE, BED_PUMP, BED_ROOM
]
const ICON_LOGOUT := "res://assets/icons/hud/icon_logout.svg"

const OVERVIEW_LABEL := "OVERVIEW"
const SERVICES_LABEL := "SERVICES"
## N41's OVERVIEW glyph fallback: the station node mark until the staged `icon_overview`
## ships. The per-faction glyph is `icon_insignia_<faction>_48` (STATION_HUB section 19.7).
const OVERVIEW_FALLBACK_ICON := "res://assets/icons/tint/icon_map_node_station_48.png"
const FACTION_ICON_TEMPLATE := "res://assets/icons/tint/icon_insignia_%s_48.png"
const STATION_FALLBACK_ICON := "res://assets/icons/map/icon_map_node_station.png"

## The drawer order (P16): OVERVIEW first, then the six, then the spacer and LOG OUT.
const DRAWER_DECKS: Array[int] = [
	OVERVIEW,
	Module.OUTFITTING,
	Module.REFINERY,
	Module.EXCHANGE,
	Module.AUCTION,
	Module.SHIPYARD,
	Module.LAUNCH,
]

const RAIL_ENTRY_HEIGHT := 56.0
const RAIL_ICON_SIZE := 40.0
const RAIL_INNER_MARGIN := Vector2i(16, 8)
## R-S30-1 (T-111's cure): the drawer's content box is 272 px so the UI_SPEC section 8 P8
## 272x56 plate seats without squeeze. The 272 content + 2x12 RailMargin + 2x33 PanelRaised
## inset = a 362 px plate (the shipped ModuleRail measured 360). Reversal: 254-wide plates
## in the 270 box.
const DRAWER_ENTRY_WIDTH := 272.0
## The drawer plate's own width: 272 content + 2x12 RailMargin + 2x33 PanelRaised inset
## = 362 (the shipped ModuleRail measured 360). Reversal: R-S30-1's own.
const DRAWER_SLIDE_WIDTH := 362.0
const DRAWER_WIDTH := 360.0
## STATION_HUB section 3.1's band boxes, reused so the drawer lands on the body band
## (x 24..384, y 163..1021) by containers, not coordinates (A5.2).
const SAFE_MARGIN := 24.0
const BAND_SEPARATION := 16.0
const BASE_HEIGHT := 1080.0
const HEADER_BAND_HEIGHT := 123.0
const FOOTER_BAND_HEIGHT := 18.0
## N40's scrim extent: the Body band alone (163..1022), derived from the band arithmetic.
const BODY_TOP := SAFE_MARGIN + HEADER_BAND_HEIGHT + BAND_SEPARATION
const BODY_BOTTOM := BASE_HEIGHT - SAFE_MARGIN - FOOTER_BAND_HEIGHT - BAND_SEPARATION
const DRAWER_IN_SECONDS := 0.18
const DRAWER_OUT_SECONDS := 0.12
const DRAWER_SCRIM_ALPHA := 0.6

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

## S30 (UI_SPEC section 12.2/12.3): the popup layer. The tooltip is N27's hover sink of the
## `inspect_requested` chain; the sheet is N28's explicit sink. The tooltip rides its own
## CanvasLayer just above the panes and below the sheet's dialog layer (section 12.2's
## stacking), and the sheet rides section 5.2's layer 20.
const TOOLTIP_LAYER := 19
const SHEET_LAYER := 20
## S30 (UI_SPEC section 12.1): the TERMINAL drawer's overlay, on section 2.3's dialog layer
## (20), added before the sheet so the sheet stacks above it.
const DRAWER_LAYER := 20
const TOOLTIP_DELAY := 0.25
## N34's `station_inspect`: keyboard `E`, pad `JOY_BUTTON_X`. The action is not in the input
## map this wave (rule 3), so the raw key is read here; the close-out registers it.
const INSPECT_KEY := KEY_E
## N25's TERMINAL toggle raw-key fallback (rule 3): `T`, registered at close-out. PROPOSED
## (no doc pins the key); reversal: the button / `ui_accept` alone.
const TERMINAL_KEY := KEY_T

## S28's A8: the credits box reserves the width of its widest readout once, so a balance
## change never reflows the header corner (D17-P2: CreditsPanel 186 -> 185 px after one
## 59-credit sale). The reserve is font-derived - nine grouped digits, more than the
## ledger prints this wave - measured with the value label's own face at its own size.
const CREDITS_WIDTH_RESERVE := 999999999

@onready var _backdrop_dim: ColorRect = %BackdropDim
@onready var _grain: TextureRect = %Grain
@onready var _fade: ColorRect = %Fade
@onready var _header: HBoxContainer = %Header
@onready var _footer: HBoxContainer = %Footer
@onready var _credits_panel: PanelContainer = %CreditsPanel
@onready var _credits_icon: TextureRect = %CreditsIcon
@onready var _credits_value: Label = %CreditsValue
@onready var _terminal_button: Button = %TerminalButton
@onready var _station_plate: PanelContainer = %StationPlate
@onready var _station_mark: TextureRect = %StationMark
@onready var _station_name: Label = %StationName
@onready var _station_location: Label = %StationLocation
@onready var _module_host: PanelContainer = %ModuleHost
@onready var _host_margin: MarginContainer = %HostMargin
@onready var _status_label: Label = %StatusLabel
@onready var _beacon: ColorRect = %StatusBeacon
@onready var _leave_confirm: Control = %LeaveConfirm
@onready var _leave_dimmer: ColorRect = %LeaveDimmer
@onready var _leave_cancel: Button = %LeaveCancel
@onready var _leave_logout: Button = %LeaveLogout

var _module: int = OVERVIEW
var _panels: Array[CanvasItem] = []
var _overview: CanvasItem = null
var _services: CanvasItem = null
var _module_entries: Array[Button] = []
var _drawer_focus_order: Array[Control] = []
var _displayed_credits := 0
var _status_danger := false
var _tweens: Array[Tween] = []
var _focus_hint: StringName = &""

## The drawer (S30, UI_SPEC section 12.1).
var _drawer_layer: CanvasLayer = null
var _drawer: Control = null
var _drawer_scrim: ColorRect = null
var _drawer_slide: Control = null
var _drawer_plate: PanelContainer = null
var _drawer_buttons: VBoxContainer = null
var _session_buttons: VBoxContainer = null
var _drawer_tween: Tween = null
var _drawer_open := false

## The popup layer (S30): the tooltip's delayed show, its last payload, and the sheet.
var _tooltip_layer: CanvasLayer = null
var _sheet_layer: CanvasLayer = null
var _tooltip: Control = null
var _sheet: Control = null
var _hover_timer: Timer = null
var _hover_title := ""
var _hover_body := ""
var _hover_danger := false
var _sheet_trigger: Control = null


func _ready() -> void:
	_build_drawer()
	_build_popups()
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
	if _drawer_tween != null and _drawer_tween.is_valid():
		_drawer_tween.kill()


func on_route(_params: Dictionary) -> void:
	_normalise_market()
	_focus_active_panel()


## A4a / L18: the market is normalised **at the dock** - once, when the station is routed
## to - and never at build, so booting the screen leaves `user://` untouched while a real
## docking still prices the exchange's board to now. `Exchange.evaluate_market` is
## idempotent at one clock reading, so the panes' own entry evaluations (the EXCHANGE
## pane's `focus_primary`, every quote and sale) cost nothing afterwards.
func _normalise_market() -> void:
	var profile := _profile()
	if profile == null:
		return
	ExchangeScript.evaluate_market(profile, Clock.now())


## The drawer's focus trap (N39): while the drawer is open, `ui_up`/`ui_down` and Tab walk
## its own controls and wrap, so focus never escapes into the pane behind. Handled in
## `_input` (before GUI) so the pane controls cannot take the event first.
func _input(event: InputEvent) -> void:
	if not _drawer_open:
		return
	if event.is_action_pressed(&"ui_up") or event.is_action_pressed(&"ui_focus_prev"):
		_move_drawer_focus(-1)
		accept_event()
	elif event.is_action_pressed(&"ui_down") or event.is_action_pressed(&"ui_focus_next"):
		_move_drawer_focus(1)
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	## N33's dismiss rule: a press, a pane switch or an overlay open all take the tooltip
	## down; only the pointer settling on a target shows it.
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_hide_tooltip()
	if event is InputEventKey and (event as InputEventKey).pressed:
		_hide_tooltip()
	if event.is_action_pressed(&"ui_cancel"):
		if Router.overlay_depth() > 0:
			return
		_handle_cancel()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey:
		# station_prev_module / station_next_module / station_inspect / station_terminal
		# are not in the input map, so the keycodes are read directly (STATION_HUB
		# sections 10 and 14 item 6; S30 rule 3). station_inspect is N34's own binding `E`;
		# the TERMINAL toggle's `T` is this wave's PROPOSED fallback.
		var key := event as InputEventKey
		if not key.pressed or key.echo:
			return
		if key.keycode == KEY_PAGEUP:
			_cycle_module(-1)
			get_viewport().set_input_as_handled()
		elif key.keycode == KEY_PAGEDOWN:
			_cycle_module(1)
			get_viewport().set_input_as_handled()
		elif key.keycode == INSPECT_KEY:
			_inspect_focused()
			get_viewport().set_input_as_handled()
		elif key.keycode == TERMINAL_KEY:
			_toggle_drawer()
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
		elif pad.button_index == JOY_BUTTON_X:
			_inspect_focused()
			get_viewport().set_input_as_handled()


func _wire_controls() -> void:
	_leave_cancel.pressed.connect(_close_leave_confirm)
	_leave_logout.pressed.connect(_on_logout_pressed)
	_terminal_button.pressed.connect(_toggle_drawer)


## S30's popup layer (UI_SPEC section 12.2/12.3): the N27 tooltip on its own CanvasLayer
## just above the panes, the N28 sheet on section 5.2's dialog layer (20), and the one
## hover-delay timer the tooltip's show rides.
func _build_popups() -> void:
	_tooltip_layer = CanvasLayer.new()
	_tooltip_layer.name = "TooltipLayer"
	_tooltip_layer.layer = TOOLTIP_LAYER
	add_child(_tooltip_layer)
	_tooltip = TooltipScene.instantiate() as Control
	_tooltip.name = "Tooltip"
	_tooltip_layer.add_child(_tooltip)
	_sheet_layer = CanvasLayer.new()
	_sheet_layer.name = "SheetLayer"
	_sheet_layer.layer = SHEET_LAYER
	add_child(_sheet_layer)
	_sheet = SheetScene.instantiate() as Control
	_sheet.name = "InspectSheet"
	_sheet_layer.add_child(_sheet)
	_sheet.connect(&"closed", _on_sheet_closed)
	_hover_timer = Timer.new()
	_hover_timer.name = "HoverDelay"
	_hover_timer.one_shot = true
	_hover_timer.wait_time = TOOLTIP_DELAY
	_hover_timer.timeout.connect(_show_hover_tooltip)
	add_child(_hover_timer)


## S30's TERMINAL drawer (UI_SPEC section 12.1, N26): a full-rect overlay on layer 20, the
## section 5.2 dimmer over the Body band only (N40), and the ModuleRail's box re-homed as
## an overlay plate. The plate lands on the body band by containers (a header gap and a
## footer gap mirror section 3.1's bands), never by coordinates (A5.2).
func _build_drawer() -> void:
	_drawer_layer = CanvasLayer.new()
	_drawer_layer.name = "DrawerLayer"
	_drawer_layer.layer = DRAWER_LAYER
	add_child(_drawer_layer)
	_drawer = Control.new()
	_drawer.name = "TerminalDrawer"
	_drawer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	## N40 (S30-F1): the overlay root never eats the pointer - the header's TERMINAL toggle
	## and the footer stay live while the drawer is up. The scrim (Body band only) and the
	## plate are the two STOP surfaces that block the pane behind them.
	_drawer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drawer.visible = false
	_drawer_layer.add_child(_drawer)
	## F4 (S30-F1): theme propagation stops at a CanvasLayer, so the code-built drawer
	## resolves `PanelRaised` / `StationButton` / `Tokens` off the shell's own theme here.
	_drawer.theme = theme
	_drawer_scrim = ColorRect.new()
	_drawer_scrim.name = "DrawerScrim"
	_drawer_scrim.anchor_left = 0.0
	_drawer_scrim.anchor_right = 1.0
	_drawer_scrim.anchor_top = BODY_TOP / BASE_HEIGHT
	_drawer_scrim.anchor_bottom = BODY_BOTTOM / BASE_HEIGHT
	_drawer_scrim.offset_left = 0.0
	_drawer_scrim.offset_right = 0.0
	_drawer_scrim.offset_top = 0.0
	_drawer_scrim.offset_bottom = 0.0
	_drawer_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_drawer_scrim.gui_input.connect(_on_scrim_input)
	_drawer.add_child(_drawer_scrim)
	var layout := MarginContainer.new()
	layout.name = "DrawerLayout"
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "top", "right", "bottom"]:
		layout.add_theme_constant_override(StringName("margin_" + side), int(SAFE_MARGIN))
	_drawer.add_child(layout)
	var page := VBoxContainer.new()
	page.name = "DrawerPage"
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_theme_constant_override(&"separation", int(BAND_SEPARATION))
	layout.add_child(page)
	var header_gap := Control.new()
	header_gap.name = "DrawerHeaderGap"
	header_gap.custom_minimum_size = Vector2(0.0, HEADER_BAND_HEIGHT)
	header_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(header_gap)
	var body := HBoxContainer.new()
	body.name = "DrawerBody"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_constant_override(&"separation", int(BAND_SEPARATION))
	page.add_child(body)
	## The slide carrier: a plain Control the HBox sizes, so the plate inside it can be
	## translated offscreen by the open/close tween without the container re-sorting it.
	_drawer_slide = Control.new()
	_drawer_slide.name = "DrawerSlide"
	_drawer_slide.custom_minimum_size = Vector2(DRAWER_SLIDE_WIDTH, 0.0)
	_drawer_slide.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_drawer_slide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(_drawer_slide)
	var footer_gap := Control.new()
	footer_gap.name = "DrawerFooterGap"
	footer_gap.custom_minimum_size = Vector2(0.0, FOOTER_BAND_HEIGHT)
	footer_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(footer_gap)
	_drawer_plate = PanelContainer.new()
	_drawer_plate.name = "DrawerPlate"
	_drawer_plate.theme_type_variation = &"PanelRaised"
	_drawer_plate.custom_minimum_size = Vector2(DRAWER_SLIDE_WIDTH, 0.0)
	_drawer_slide.add_child(_drawer_plate)
	## F2 (S30-F1): the full-rect anchors are written explicitly (all four offsets 0) after
	## the plate is in the tree, so it fills the slide's 362 x body-band box instead of
	## carrying the minimum-size offset a preset computed out of tree left behind.
	_drawer_plate.anchor_left = 0.0
	_drawer_plate.anchor_top = 0.0
	_drawer_plate.anchor_right = 1.0
	_drawer_plate.anchor_bottom = 1.0
	_drawer_plate.offset_left = 0.0
	_drawer_plate.offset_top = 0.0
	_drawer_plate.offset_right = 0.0
	_drawer_plate.offset_bottom = 0.0
	var rail_margin := MarginContainer.new()
	rail_margin.name = "RailMargin"
	for side: String in ["left", "top", "right", "bottom"]:
		rail_margin.add_theme_constant_override(StringName("margin_" + side), 12)
	_drawer_plate.add_child(rail_margin)
	var rail_box := VBoxContainer.new()
	rail_box.name = "RailBox"
	rail_box.add_theme_constant_override(&"separation", 10)
	rail_margin.add_child(rail_box)
	var caption := Label.new()
	caption.name = "RailCaption"
	caption.theme_type_variation = &"StationCaption"
	caption.text = "MODULES"
	rail_box.add_child(caption)
	_drawer_buttons = VBoxContainer.new()
	_drawer_buttons.name = "ModuleButtons"
	_drawer_buttons.add_theme_constant_override(&"separation", 6)
	rail_box.add_child(_drawer_buttons)
	var spacer := Control.new()
	spacer.name = "RailSpacer"
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rail_box.add_child(spacer)
	var session_caption := Label.new()
	session_caption.name = "SessionCaption"
	session_caption.theme_type_variation = &"StationCaption"
	session_caption.text = "SESSION"
	rail_box.add_child(session_caption)
	_session_buttons = VBoxContainer.new()
	_session_buttons.name = "SessionButtons"
	_session_buttons.add_theme_constant_override(&"separation", 6)
	rail_box.add_child(_session_buttons)
	_build_drawer_entries()


func _build_drawer_entries() -> void:
	for deck: int in DRAWER_DECKS:
		var entry := _make_drawer_entry(
			_drawer_buttons, _label_for(deck), _icon_for(deck), _tinted_for(deck)
		)
		entry.pressed.connect(_on_drawer_pressed.bind(deck))
		_module_entries.append(entry)
	var logout := _make_drawer_entry(_session_buttons, "LOG OUT", ICON_LOGOUT, true)
	logout.pressed.connect(_on_drawer_logout)
	_drawer_focus_order.clear()
	for entry: Button in _module_entries:
		_drawer_focus_order.append(entry)
	_drawer_focus_order.append(logout)


func _make_drawer_entry(
	parent: VBoxContainer, label_text: String, icon_path: String, tinted: bool
) -> Button:
	var button := Button.new()
	button.name = "%sEntry" % label_text.to_pascal_case()
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_ALL
	button.theme_type_variation = &"StationButton"
	button.custom_minimum_size = Vector2(DRAWER_ENTRY_WIDTH, RAIL_ENTRY_HEIGHT)
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


func _label_for(deck: int) -> String:
	if deck == OVERVIEW:
		return OVERVIEW_LABEL
	if deck >= 0 and deck < MODULE_LABELS.size():
		return MODULE_LABELS[deck]
	return SERVICES_LABEL


func _icon_for(deck: int) -> String:
	if deck == OVERVIEW:
		return _overview_icon()
	if deck >= 0 and deck < MODULE_ICONS.size():
		return MODULE_ICONS[deck]
	return OVERVIEW_FALLBACK_ICON


func _tinted_for(deck: int) -> bool:
	if deck == OVERVIEW:
		return false
	if deck >= 0 and deck < MODULE_TINTED.size():
		return MODULE_TINTED[deck]
	return true


## N41: the OVERVIEW glyph is the station's faction insignia until the staged
## `icon_overview` ships; the station node mark is the reversal.
func _overview_icon() -> String:
	var faction := _docked_faction()
	if not faction.is_empty():
		var path := FACTION_ICON_TEMPLATE % String(faction)
		if ResourceLoader.exists(path):
			return path
	return OVERVIEW_FALLBACK_ICON


func _docked_faction() -> StringName:
	var profile := _profile()
	if profile == null:
		return &""
	if profile.has_method(&"docked_faction"):
		var faction := StringName(profile.call(&"docked_faction"))
		if not faction.is_empty():
			return faction
	if profile.has_method(&"n"):
		return StringName(profile.call(&"n"))
	return &""


## N33: the delay elapsed with the payload still live, so the tooltip opens at the cursor.
func _show_hover_tooltip() -> void:
	if _tooltip == null or (_hover_title.is_empty() and _hover_body.is_empty()):
		return
	var viewport := get_viewport()
	if viewport == null:
		return
	_tooltip.call(
		&"show_for",
		_hover_title,
		_hover_body,
		_hover_danger,
		viewport.get_mouse_position(),
		viewport.get_visible_rect().size
	)


func _hide_tooltip() -> void:
	if _hover_timer != null:
		_hover_timer.stop()
	if _tooltip != null and bool(_tooltip.call(&"is_open")):
		_tooltip.call(&"hide_tooltip")


## N28's explicit sink: a pane's own INSPECT chip (or `station_inspect`) publishes here.
func _on_panel_sheet(payload: Dictionary, pane: Node) -> void:
	if pane != _panel_for(_module):
		return
	_hide_tooltip()
	open_sheet(payload)


## Open the sheet, remembering the focused trigger so N39 can hand focus back.
func open_sheet(payload: Dictionary) -> void:
	if _sheet == null:
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null:
		_sheet_trigger = focused
	_sheet.call(&"open", payload)


## N34's keyboard/pad route: ask the pane on the host to inspect whatever it holds focused.
func _inspect_focused() -> void:
	if _sheet != null and bool(_sheet.call(&"is_open")):
		return
	var panel := _panel_for(_module)
	if panel != null and panel.has_method(&"inspect_focused"):
		panel.call(&"inspect_focused")


func _on_sheet_closed() -> void:
	if _sheet != null and bool(_sheet.call(&"is_open")):
		return
	if _sheet_trigger != null and is_instance_valid(_sheet_trigger):
		_sheet_trigger.grab_focus()
	_sheet_trigger = null


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
	var scrim: Color = _token(&"void_base")
	scrim.a = DRAWER_SCRIM_ALPHA
	if _drawer_scrim != null:
		_drawer_scrim.color = scrim
	var fade: Color = _token(&"void_fade")
	fade.a = 0.0
	_fade.color = fade
	_credits_icon.modulate = _token(&"text_primary")
	_beacon.color = _token(&"accent_danger")
	_grain.modulate = Color(1.0, 1.0, 1.0, GRAIN_IDLE_ALPHA)
	_apply_status_colour()
	_apply_identity()
	_reserve_credits_width()


## STATION_HUB section 15.5 / UI_SPEC section 7 A5.4-1: the name plate's faction glyph and
## its 1 px metal-ramp border. Tokens only (N29): the ramp is the shipped metal tokens, no
## new hue. A faction the plate cannot resolve keeps the shipped mark and `metal_mid`.
func _apply_identity() -> void:
	var faction := _docked_faction()
	var border := _token(&"metal_mid")
	if faction == &"meridian":
		border = _token(&"metal_light")
	elif faction == &"choir":
		border = _token(&"metal_dark")
	var base := get_theme_stylebox(&"panel", &"PanelContainer")
	if base is StyleBoxFlat:
		var box := (base as StyleBoxFlat).duplicate() as StyleBoxFlat
		box.border_color = border
		_station_plate.add_theme_stylebox_override(&"panel", box)
	if not faction.is_empty():
		var path := FACTION_ICON_TEMPLATE % String(faction)
		if ResourceLoader.exists(path):
			_station_mark.texture = load(path)


## A8: one font-measured reservation on the value label; right alignment (the scene) keeps
## the digits off the icon while the width never moves again.
func _reserve_credits_width() -> void:
	var font := _credits_value.get_theme_font(&"font")
	if font == null:
		return
	var size := _credits_value.get_theme_font_size(&"font_size")
	var reserve := ceilf(
		font.get_string_size(_format_int(CREDITS_WIDTH_RESERVE), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	)
	_credits_value.custom_minimum_size.x = maxf(reserve, _credits_value.custom_minimum_size.x)


func _token(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.WHITE


func _build_panels() -> void:
	_panels.clear()
	for index in MODULE_FILES.size():
		var pane := _load_panel(index)
		pane.visible = false
		_host_margin.add_child(pane)
		_panels.append(pane)
	_overview = OverviewScene.instantiate() as CanvasItem
	if _overview != null:
		_overview.name = "Overview"
		_connect_panel(_overview)
		_overview.visible = false
		_host_margin.add_child(_overview)
		## The header is the one source of truth for the identity text (section 15.5).
		if _overview.has_method(&"set_identity"):
			_overview.call(
				&"set_identity", _station_name.text, _station_location.text, _docked_faction()
			)
	_services = _make_placeholder(SERVICES, PANEL_DIR + "services" + PANEL_SUFFIX)
	_services.name = "Services"
	_services.visible = false
	_host_margin.add_child(_services)


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
	if pane.has_signal(&"inspect_requested"):
		pane.connect(&"inspect_requested", _on_panel_inspect.bind(pane))
	if pane.has_signal(&"sheet_requested"):
		pane.connect(&"sheet_requested", _on_panel_sheet.bind(pane))
	if pane.has_signal(&"navigate_requested"):
		pane.connect(&"navigate_requested", _on_pane_navigate.bind(pane))


func _make_placeholder(index: int, path: String) -> CanvasItem:
	## An unwritten module panel is a build order fact, not a failure: the module names
	## itself and stays inert instead of erroring, warning or crashing. The node keeps
	## the module's own name, so the host's one pane per module contract holds.
	var pane := VBoxContainer.new()
	pane.name = _label_for(index).to_pascal_case()
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
		_make_label(&"StationCaption", "%s PANEL IS NOT INSTALLED YET" % _label_for(index))
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


## ------------------------------------------------------------------- the drawer (N25/N26/N39/N40)


func _toggle_drawer() -> void:
	if _drawer_open:
		_close_drawer()
	else:
		_open_drawer()


func _open_drawer() -> void:
	if _drawer == null or _drawer_open:
		return
	_drawer_open = true
	_drawer.visible = true
	_drawer_plate.position.x = -DRAWER_SLIDE_WIDTH
	_drawer_scrim.color.a = 0.0
	_animate_drawer(DRAWER_IN_SECONDS, 0.0, DRAWER_SCRIM_ALPHA)
	_focus_current_entry()
	## F2 (S30-F1): re-write the plate's vertical box once the slide has been laid out - a
	## build-time zero-height parent left the plate carrying its 648 px minimum size as an
	## offset, so the drawer's LOG OUT sat below the viewport.
	_reset_plate_box()
	_reset_plate_box.call_deferred()


## F2 (S30-F1): the drawer plate fills its slide carrier's height exactly. Only the
## vertical offsets are written - the horizontal pair belongs to the slide-in tween.
func _reset_plate_box() -> void:
	if _drawer_plate == null:
		return
	_drawer_plate.offset_top = 0.0
	_drawer_plate.offset_bottom = 0.0


func _close_drawer(instant: bool = false) -> void:
	if _drawer == null or not _drawer_open:
		return
	_drawer_open = false
	_hide_tooltip()
	if instant:
		_drawer.visible = false
		_drawer_scrim.color.a = 0.0
		_focus_terminal()
		return
	_animate_drawer(DRAWER_OUT_SECONDS, -DRAWER_SLIDE_WIDTH, 0.0, true)
	_focus_terminal()


func _animate_drawer(seconds: float, x: float, scrim_alpha: float, then_hide: bool = false) -> void:
	if _drawer_tween != null and _drawer_tween.is_valid():
		_drawer_tween.kill()
	_drawer_tween = create_tween()
	_drawer_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_drawer_tween.set_parallel(true)
	_drawer_tween.tween_property(_drawer_plate, "position:x", x, seconds)
	_drawer_tween.tween_property(_drawer_scrim, "color:a", scrim_alpha, seconds)
	if then_hide:
		_drawer_tween.chain().tween_callback(func() -> void: _drawer.visible = false)


func _on_scrim_input(event: InputEvent) -> void:
	## N38: a scrim press closes the drawer.
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_close_drawer()


func _on_drawer_pressed(deck: int) -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	if deck == _module:
		_close_drawer()
		return
	_select_module(deck)
	_close_drawer()


func _on_drawer_logout() -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	## P16: the drawer's LOG OUT opens the leave confirm first (section 2's flow unchanged).
	## The drawer closes instantly so the confirm (layer 0) is not hidden behind the overlay.
	_close_drawer(true)
	_open_leave_confirm()


func _move_drawer_focus(step: int) -> void:
	if _drawer_focus_order.is_empty():
		return
	var focused := get_viewport().gui_get_focus_owner()
	var index := _drawer_focus_order.find(focused)
	if index < 0:
		index = 0 if step > 0 else _drawer_focus_order.size() - 1
	else:
		index = posmod(index + step, _drawer_focus_order.size())
	_drawer_focus_order[index].grab_focus()


func _focus_current_entry() -> void:
	var index := DRAWER_DECKS.find(_module)
	if index >= 0 and index < _module_entries.size():
		_module_entries[index].grab_focus()


func _focus_terminal() -> void:
	if _terminal_button != null:
		_terminal_button.grab_focus()


func _drawer_has_focus(control: Control) -> bool:
	for entry: Control in _drawer_focus_order:
		if entry == control or entry.is_ancestor_of(control):
			return true
	return false


## Read-backs for probes and tests (S30): the drawer's seven entries in P16's order, the
## drawer's open state, and the OVERVIEW pane.
func drawer_entries() -> Array[Button]:
	return _module_entries.duplicate()


func is_drawer_open() -> bool:
	return _drawer_open


func overview_pane() -> CanvasItem:
	return _overview


## ------------------------------------------------------------------- the deck switch


func _on_module_pressed(module: int) -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	_select_module(module)


func _cycle_module(step: int) -> void:
	## P20: PageUp/PageDown and the pad shoulders wrap the six service panes from anywhere;
	## a cycle press closes the drawer (N38). Reversal: cycle only from the drawer.
	if _drawer_open:
		_close_drawer()
	var count := _panels.size()
	if count <= 0:
		return
	if _module < 0 or _module >= count:
		_select_module(0 if step > 0 else count - 1)
		return
	_select_module(posmod(_module + step, count))


func _select_module(module: int, instant: bool = false) -> void:
	if module == _module and not instant:
		return
	var outgoing := _panel_for(_module)
	var incoming := _panel_for(module)
	_module = module
	_sync_entry_pressed()
	if not instant:
		AudioManager.play_sfx(SFX_MODULE_SWITCH)
		AudioManager.play_ambience(_bed_for(module), SWITCH_AMBIENCE_FADE)
	_set_status(STATUS_DOCKED, false)
	## P6 (STATION_HUB section 16): the tooltip is the shell's, so the shell empties it on
	## every switch - a hover from the outgoing module never rides into the incoming one.
	_clear_inspector()
	if instant or outgoing == null or outgoing == incoming:
		_show_only(incoming)
		_focus_active_panel()
		return
	incoming.visible = true
	incoming.modulate.a = 0.0
	var tween := _make_tween()
	tween.tween_property(outgoing, "modulate:a", 0.0, MODULE_OUT_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(outgoing.hide)
	tween.tween_property(incoming, "modulate:a", 1.0, MODULE_IN_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_focus_active_panel)


func _sync_entry_pressed() -> void:
	for index in _module_entries.size():
		_module_entries[index].set_pressed_no_signal(DRAWER_DECKS[index] == _module)


func _bed_for(module: int) -> StringName:
	if module >= 0 and module < MODULE_BEDS.size():
		return MODULE_BEDS[module]
	return BED_ROOM


func _panel_for(module: int) -> CanvasItem:
	if module == OVERVIEW:
		return _overview
	if module == SERVICES:
		return _services
	if module < 0 or module >= _panels.size():
		return null
	return _panels[module]


func _all_panes() -> Array[CanvasItem]:
	var out: Array[CanvasItem] = []
	out.append_array(_panels)
	if _overview != null:
		out.append(_overview)
	if _services != null:
		out.append(_services)
	return out


func _show_only(incoming: CanvasItem) -> void:
	for pane: CanvasItem in _all_panes():
		if pane == null:
			continue
		pane.visible = pane == incoming
		if pane == incoming:
			pane.modulate.a = 1.0


func _focus_active_panel() -> void:
	## A pane with nothing focusable (the offline placeholder) leaves the ring on a hidden
	## row, so the TERMINAL button takes it instead.
	var panel := _panel_for(_module)
	if not _focus_hint.is_empty() and panel != null:
		var hint := _focus_hint
		_focus_hint = &""
		if hint == &"repair" and panel.has_method(&"focus_repair"):
			panel.call(&"focus_repair")
			return
	if panel != null and panel.has_method(&"focus_primary"):
		panel.call(&"focus_primary")
		var focus_owner := get_viewport().gui_get_focus_owner()
		if focus_owner != null and panel.is_ancestor_of(focus_owner):
			return
	_focus_terminal()


func _on_pane_navigate(deck: int, hint: StringName, pane: Node) -> void:
	if pane != _panel_for(_module):
		return
	_focus_hint = hint
	_select_module(deck)


func _on_panel_status(message: String, danger: bool) -> void:
	_set_status(message, danger)


## CONTRACTS section 23.1: the additive hover surface. `status_requested` keeps its meaning
## and its wording; the hover description's sink is the N27 tooltip (UI_SPEC section 12.2),
## shown after the 0.25 s delay (N33 restarts it per target). The retired inspector band no
## longer exists (S30, section 18's ledger).
func _on_panel_inspect(title: String, body: String, danger: bool, pane: Node) -> void:
	if pane != _panel_for(_module):
		return
	_hover_title = title
	_hover_body = body
	_hover_danger = danger
	if title.is_empty() and body.is_empty():
		_clear_inspector()
		return
	if _hover_timer != null:
		_hover_timer.start(TOOLTIP_DELAY)


## P6's mechanical clear: the shell owns the tooltip, so every module switch takes it down
## and cancels a pending show.
func _clear_inspector() -> void:
	_hover_title = ""
	_hover_body = ""
	_hover_danger = false
	_hide_tooltip()


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
	if _overview != null and _overview.has_method(&"refresh_profile"):
		_overview.call(&"refresh_profile", key)
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
	## FITTING refuses in the pane's own footer strip, with its own pinned wordings
	## (STATION_HUB section 5.3), so this copy path only ever names a hull or a catalogue row
	## that still answers to `purchase_failed`.
	var profile := _profile()
	if profile != null and id == StringName(profile.call(&"active_ship")):
		return "ALREADY THE ACTIVE HULL"
	return "ALREADY OWNED"


func _entry_name(id: StringName) -> String:
	return String(_entry(id).get(&"name", String(id))).to_upper()


func _entry_cost(id: StringName) -> int:
	return int(_entry(id).get(&"cost", 0))


func _entry(id: StringName) -> Dictionary:
	## purchase_failed carries only the reason and the id, so the copy resolves the
	## entry and its price from the catalogue the panel bought from: the ammo packs,
	## the ships and the modules. The retired upgrades rows are gone with save v5
	## (CONTRACTS section 13). A rolled **instance** id resolves to nothing here, which
	## is why the AUCTION pane owns its own footer strip (STATION_HUB section 5.10's
	## S3 amendment): this copy would read `0 NEEDED` and the raw id as the name.
	var entry := Catalog.ammo_pack(id)
	if entry.is_empty():
		entry = Catalog.ship(id)
	if entry.is_empty():
		entry = ModuleCatalog.module(id)
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


## P19's unwind, topmost-first, one operation per step (S29-F1's `game.gd:951`
## precedent): INSPECT modal -> drawer -> LAUNCH disarm -> leave confirm.
func _handle_cancel() -> void:
	if _sheet != null and bool(_sheet.call(&"is_open")):
		_sheet.call(&"close")
		return
	if _drawer_open:
		_close_drawer()
		return
	var panel := _panel_for(_module)
	if panel != null and panel.has_method(&"disarm") and bool(panel.call(&"disarm")):
		return
	if _leave_confirm.visible:
		_close_leave_confirm()
		return
	_open_leave_confirm()


func _open_leave_confirm() -> void:
	_leave_confirm.visible = true
	_leave_cancel.grab_focus()
	_set_status("LEAVE THE STATION? · ESC STAYS DOCKED", false)


func _close_leave_confirm() -> void:
	_leave_confirm.visible = false
	if _drawer_open:
		_focus_current_entry()
	else:
		_focus_terminal()


func _play_entry() -> void:
	AudioManager.play_ambience(BED_ROOM, ENTRY_AMBIENCE_FADE)
	_backdrop_dim.color.a = 0.0
	_header.modulate.a = 0.0
	_module_host.modulate.a = 0.0
	_footer.modulate.a = 0.0
	var tween := _make_tween()
	tween.set_parallel(true)
	tween.tween_property(_backdrop_dim, "color:a", BACKDROP_DIM_ALPHA, ENTRY_DIM_SECONDS)
	tween.tween_property(_header, "modulate:a", 1.0, ENTRY_SECONDS).set_delay(ENTRY_DELAYS[0])
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
	## CONTRACTS section 23.1: one home for the rule (`StationCatalog.group_int`), so the
	## shell's credits readout and the tooltip cannot drift.
	return Catalog.group_int(value)
