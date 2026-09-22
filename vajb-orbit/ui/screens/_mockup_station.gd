@tool
extends Control
## D5 space-station hub mockup. Throwaway: the shipping screen is ui/screens/station.tscn.
## Standalone by design - no class_name, no autoload call, no Router call - so F6 and the
## headless check both render it with zero input. Every price, name, id, stat and icon path
## below is copied from docs/design/STATION_SPEC.md section 5 and game/station_catalog.gd
## and is listed as a stub in docs/design/STATION_HUB.md section 12, together with the
## PlayerProfile call each one will be replaced by.
##
## @tool on purpose: the mockup has to look finished in the editor's 2D view for review.
## The generated nodes keep owner == null, so an editor save cannot persist them into the
## .tscn, and input is ignored while Engine.is_editor_hint().
##
## DEV 1: three ammo rows read the derived icons/tint/ stencil instead of the catalogue
## path, because the catalogue's icon_weapon_cannon/mine/plasma_48.png are flat Phase B
## glyphs (mean RGB ~40,44,47, ASSET_AUDIT anomaly C16) that render as near-black shapes
## on the row chrome. Modulating the tint stencil with Tokens/text_primary is the only
## shipped route to a legible row today.
##
## DEV 2: the affordability and ownership states are recomputed from this script's local
## stub state so the mockup can be shopped in. The shipping screen never does that: it
## calls buy_ammo/buy_ship/install_upgrade/set_active_ship and re-reads on profile_changed.
##
## DEV 3: two verification stand-ins read OS.get_cmdline_args() so one module state can be
## rendered per run with zero input: --station-module=<outfitting|shipyard|upgrades|launch>
## and --station-credits=<int>. With no argument both are inert and the composition is the
## shipping-intent one. ui_scale needs no stand-in: Router._bind_entry_scene() hands this
## scene its live theme, so the module/credits flags are the only inputs the mockup adds.

const TOKENS_TYPE: StringName = &"Tokens"

const ARG_MODULE := "--station-module="
const ARG_CREDITS := "--station-credits="
const MODULE_ARG_NAMES: Array[String] = ["outfitting", "shipyard", "upgrades", "launch"]

const MOCK_CREDITS := 4900
const MOCK_ACTIVE_SHIP: StringName = &"ship_vanguard"
const MOCK_OWNED_SHIPS: Array[StringName] = [&"ship_vanguard", &"ship_fighter"]
const MOCK_INSTALLED_UPGRADES: Array[StringName] = [&"upgrade_engine", &"upgrade_extra"]
const MOCK_AMMO: Dictionary = {
	&"laser": 300,
	&"cannon": 140,
	&"rocket": 60,
	&"mine": 300,
	&"plasma": 0,
}
const MOCK_AMMO_MAX: Dictionary = {
	&"laser": 300,
	&"cannon": 300,
	&"rocket": 100,
	&"mine": 100,
	&"plasma": 100,
}

const AMMO_PACKS: Array[Dictionary] = [
	{
		&"id": &"laser",
		&"name": "Laser Cells",
		&"rounds": 300,
		&"cost": 120,
		&"icon": "res://assets/icons/weapon/icon_ammo_laser.png",
		&"tinted": false,
	},
	{
		&"id": &"cannon",
		&"name": "Cannon Shells",
		&"rounds": 300,
		&"cost": 180,
		&"icon": "res://assets/icons/weapon/icon_weapon_cannon.svg",
		&"tinted": true,
	},
	{
		&"id": &"rocket",
		&"name": "Rocket Pod",
		&"rounds": 60,
		&"cost": 240,
		&"icon": "res://assets/icons/weapon/icon_ammo_rocket.png",
		&"tinted": false,
	},
	{
		&"id": &"mine",
		&"name": "Mine Rack",
		&"rounds": 40,
		&"cost": 200,
		&"icon": "res://assets/icons/weapon/icon_weapon_mine.svg",
		&"tinted": true,
	},
	{
		&"id": &"plasma",
		&"name": "Plasma Cells",
		&"rounds": 50,
		&"cost": 320,
		&"icon": "res://assets/icons/weapon/icon_weapon_plasma.svg",
		&"tinted": true,
	},
]

const SHIPS: Array[Dictionary] = [
	{
		&"id": &"ship_fighter",
		&"name": "Lancer",
		&"cost": 9000,
		&"preview": "res://assets/ships/ship_fighter_side.png",
		&"hull": 700,
		&"shield": 400,
		&"cargo": 25,
		&"hardpoints": 3,
		&"description": "Light interceptor. Fast, thin plated, cheap to lose.",
	},
	{
		&"id": &"ship_vanguard",
		&"name": "Vanguard",
		&"cost": 18000,
		&"preview": "res://assets/ships/ship_vanguard_side.png",
		&"hull": 1000,
		&"shield": 600,
		&"cargo": 40,
		&"hardpoints": 4,
		&"description": "General purpose hull. The yard stick every other ship is measured against.",
	},
	{
		&"id": &"ship_gunship",
		&"name": "Bulwark",
		&"cost": 36000,
		&"preview": "res://assets/ships/ship_gunship_side.png",
		&"hull": 1400,
		&"shield": 650,
		&"cargo": 50,
		&"hardpoints": 5,
		&"description": "Heavy gunship. Trading manoeuvrability for gun decks and plate.",
	},
	{
		&"id": &"ship_destroyer",
		&"name": "Obliterator",
		&"cost": 72000,
		&"preview": "res://assets/ships/ship_destroyer_side.png",
		&"hull": 2200,
		&"shield": 900,
		&"cargo": 80,
		&"hardpoints": 7,
		&"description": "Line destroyer. Seven hardpoints and a hull built to take a beating.",
	},
]

const UPGRADES: Array[Dictionary] = [
	{
		&"id": &"upgrade_generator",
		&"name": "Reactor Mk2",
		&"cost": 4200,
		&"icon": "res://assets/icons/equip/icon_equip_generator.png",
		&"slot": &"generator",
		&"effect": {&"shield_regen": 0.30, &"energy_regen": 0.20},
	},
	{
		&"id": &"upgrade_shield",
		&"name": "Shield Amplifier",
		&"cost": 5200,
		&"icon": "res://assets/icons/equip/icon_equip_shield_gen.png",
		&"slot": &"shield",
		&"effect": {&"shield_max": 0.20},
	},
	{
		&"id": &"upgrade_engine",
		&"name": "Ion Drive",
		&"cost": 3800,
		&"icon": "res://assets/icons/equip/icon_equip_engine.png",
		&"slot": &"engine",
		&"effect": {&"speed": 0.15},
	},
	{
		&"id": &"upgrade_module",
		&"name": "Deep Scanner",
		&"cost": 4600,
		&"icon": "res://assets/icons/equip/icon_equip_module.png",
		&"slot": &"module",
		&"effect": {&"scanner_range": 0.25},
	},
	{
		&"id": &"upgrade_extra",
		&"name": "Cargo Expansion",
		&"cost": 3000,
		&"icon": "res://assets/icons/equip/icon_equip_extra.png",
		&"slot": &"extra",
		&"effect": {&"cargo_max": 0.25},
	},
	{
		&"id": &"upgrade_drone",
		&"name": "Repair Drone Bay",
		&"cost": 6800,
		&"icon": "res://assets/icons/equip/icon_equip_drone.png",
		&"slot": &"drone",
		&"effect": {&"hull_repair_rate": 0.50},
	},
]

const EFFECT_LABELS: Dictionary = {
	&"shield_regen": "SHIELD REGEN",
	&"energy_regen": "ENERGY REGEN",
	&"shield_max": "SHIELD MAX",
	&"speed": "SPEED",
	&"scanner_range": "SCANNER RANGE",
	&"cargo_max": "CARGO MAX",
	&"hull_repair_rate": "HULL REPAIR",
}

const CARGO_MANIFEST: Array[Dictionary] = [
	{
		&"id": &"ore_fragment",
		&"name": "Ore Fragment",
		&"qty": 22,
		&"icon": "res://assets/icons/cargo/icon_cargo_ore.svg",
	},
	{
		&"id": &"data_core",
		&"name": "Data Core",
		&"qty": 2,
		&"icon": "res://assets/icons/cargo/icon_cargo_data_core.svg",
	},
	{
		&"id": &"salvage_plate",
		&"name": "Salvage Plate",
		&"qty": 11,
		&"icon": "res://assets/icons/cargo/icon_cargo_salvage.svg",
	},
]

const ICON_LOGOUT := "res://assets/icons/hud/icon_logout.svg"

const RAIL_ENTRIES: Array[Dictionary] = [
	{
		&"module": Module.OUTFITTING,
		&"label": "OUTFITTING",
		&"icon": "res://assets/icons/equip/icon_equip_module.png",
		&"tinted": false,
	},
	{
		&"module": Module.SHIPYARD,
		&"label": "SHIPYARD",
		&"icon": "res://assets/icons/hud/icon_hull.svg",
		&"tinted": true,
	},
	{
		&"module": Module.UPGRADES,
		&"label": "UPGRADES",
		&"icon": "res://assets/icons/equip/icon_equip_generator.png",
		&"tinted": false,
	},
	{
		&"module": Module.LAUNCH,
		&"label": "LAUNCH",
		&"icon": "res://assets/icons/map/icon_map_route.png",
		&"tinted": false,
	},
]

const STAT_ROWS: Array[Dictionary] = [
	{&"key": &"hull", &"label": "HULL"},
	{&"key": &"shield", &"label": "SHIELD"},
	{&"key": &"cargo", &"label": "CARGO"},
	{&"key": &"hardpoints", &"label": "HARDPOINTS"},
]

enum Module { OUTFITTING, SHIPYARD, UPGRADES, LAUNCH }

const ROW_HEIGHT := 76.0
const ROW_GAP := 6
const COL_ICON := 40.0
const COL_HELD := 130.0
const COL_EFFECT := 300.0
const COL_PRICE := 110.0
const COL_TAG := 160.0
const COL_SHIP_TAG := 130.0
const COL_BRIEF := 220.0
const RAIL_ENTRY_HEIGHT := 56.0
const HARDPOINT_PLATES := 7

const PREVIEW_SCALE := 0.70
const PREVIEW_MAX_WIDTH := 480.0
const MODULE_OUT_SECONDS := 0.12
const MODULE_IN_SECONDS := 0.18
const HOVER_SECONDS := 0.09
const ENTRY_SECONDS := 0.30
const CREDITS_SECONDS := 0.60
const CREDITS_STEP_SECONDS := 0.35
const ARM_SECONDS := 3.0
const BEACON_MIN_ALPHA := 0.35
const BEACON_SECONDS := 2.4
const GRAIN_IDLE_ALPHA := 0.06
const GRAIN_PEAK_ALPHA := 0.11
const GRAIN_SECONDS := 5.0
const ROW_ICON_IDLE_ALPHA := 0.72
const BACKDROP_DIM_ALPHA := 0.72
const MODAL_DIM_ALPHA := 0.72
const LAUNCH_FADE_ALPHA := 1.0

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
@onready var _pane_outfitting: VBoxContainer = %Outfitting
@onready var _pane_shipyard: VBoxContainer = %Shipyard
@onready var _pane_upgrades: VBoxContainer = %Upgrades
@onready var _pane_launch: VBoxContainer = %Launch
@onready var _shipyard_icon: TextureRect = %ShipyardIcon
@onready var _outfitting_header: HBoxContainer = %OutfittingHeader
@onready var _outfitting_rows: VBoxContainer = %OutfittingRows
@onready var _upgrades_header: HBoxContainer = %UpgradesHeader
@onready var _upgrade_rows: VBoxContainer = %UpgradeRows
@onready var _ship_list: VBoxContainer = %ShipList
@onready var _preview_frame: PanelContainer = %PreviewFrame
@onready var _preview_center: CenterContainer = %PreviewCenter
@onready var _preview_image: TextureRect = %PreviewImage
@onready var _preview_name: Label = %PreviewName
@onready var _preview_caption: Label = %PreviewCaption
@onready var _ship_stats: VBoxContainer = %ShipStats
@onready var _hardpoint_slots: HBoxContainer = %HardpointSlots
@onready var _ship_action: Button = %ShipAction
@onready var _ship_price: Label = %ShipPrice
@onready var _brief_rows: VBoxContainer = %BriefRows
@onready var _cargo_slots: HBoxContainer = %CargoSlots
@onready var _cargo_list: ItemList = %CargoList
@onready var _launch_button: Button = %LaunchButton
@onready var _confirm_strip: Label = %ConfirmStrip
@onready var _status_label: Label = %StatusLabel
@onready var _beacon: ColorRect = %StatusBeacon
@onready var _leave_confirm: Control = %LeaveConfirm
@onready var _leave_dimmer: ColorRect = %LeaveDimmer
@onready var _leave_cancel: Button = %LeaveCancel
@onready var _leave_logout: Button = %LeaveLogout

var _module: int = Module.OUTFITTING
var _credits: int = MOCK_CREDITS
var _active_ship: StringName = MOCK_ACTIVE_SHIP
var _selected_ship: StringName = MOCK_ACTIVE_SHIP
var _owned_ships: Array[StringName] = MOCK_OWNED_SHIPS.duplicate()
var _installed: Array[StringName] = MOCK_INSTALLED_UPGRADES.duplicate()
var _ammo: Dictionary = MOCK_AMMO.duplicate()

var _panes: Array[VBoxContainer] = []
var _module_entries: Array[Button] = []
var _rows_by_module: Dictionary = {}
var _stat_values: Dictionary = {}
var _brief_values: Dictionary = {}
var _selected_row: Button = null
var _native_preview := Vector2.ZERO
var _launch_armed := false
var _arm_timer: Timer
var _tweens: Array[Tween] = []


func _ready() -> void:
	_read_launch_args()
	_panes = [_pane_outfitting, _pane_shipyard, _pane_upgrades, _pane_launch]
	_build_arm_timer()
	_build_rail()
	_build_outfitting()
	_build_upgrades()
	_build_shipyard()
	_build_launch()
	_apply_tokens()
	_wire_controls()
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


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event.is_action_pressed(&"ui_cancel"):
		# The shipping screen routes this through Router/DialogManager; the mockup walks its
		# own two-step chain: disarm, then back out of the pane, then offer the exit dialog.
		_handle_cancel()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey:
		# Module cycling is read from the keycode because station_prev_module /
		# station_next_module are not in the input map yet (STATION_HUB.md section 16).
		var key := event as InputEventKey
		if key.pressed and not key.echo:
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
	_launch_button.pressed.connect(_arm_launch)
	_leave_cancel.pressed.connect(_close_leave_confirm)
	_leave_logout.pressed.connect(_on_logout_pressed)
	_ship_action.pressed.connect(_on_ship_action_pressed)
	_preview_center.resized.connect(_update_preview_size)
	_arm_timer.timeout.connect(_on_arm_timeout)


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
	_shipyard_icon.modulate = _token(&"text_primary")
	_beacon.color = _token(&"accent_danger")
	_grain.modulate = Color(1, 1, 1, GRAIN_IDLE_ALPHA)
	_status_label.add_theme_color_override(&"font_color", _token(&"text_primary"))
	_refresh_plate_textures()
	_refresh_all()


func _token(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.WHITE


func _read_launch_args() -> void:
	for arg: String in OS.get_cmdline_args() + OS.get_cmdline_user_args():
		if arg.begins_with(ARG_MODULE):
			var index := MODULE_ARG_NAMES.find(arg.trim_prefix(ARG_MODULE).to_lower())
			if index >= 0:
				_module = index
		elif arg.begins_with(ARG_CREDITS):
			_credits = maxi(int(arg.trim_prefix(ARG_CREDITS)), 0)


func _build_arm_timer() -> void:
	_arm_timer = Timer.new()
	_arm_timer.one_shot = true
	_arm_timer.wait_time = ARM_SECONDS
	add_child(_arm_timer)


func _build_rail() -> void:
	for entry: Dictionary in RAIL_ENTRIES:
		var button := _make_rail_entry(
			_module_buttons,
			String(entry[&"label"]),
			String(entry[&"icon"]),
			bool(entry[&"tinted"])
		)
		button.pressed.connect(_on_module_pressed.bind(int(entry[&"module"])))
		_module_entries.append(button)
	var logout := _make_rail_entry(_session_buttons, "LOG OUT", ICON_LOGOUT, true)
	logout.pressed.connect(_on_logout_pressed)


func _make_rail_entry(
	parent: VBoxContainer, label_text: String, icon_path: String, tinted: bool
) -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_ALL
	button.theme_type_variation = &"StationButton"
	button.custom_minimum_size = Vector2(0.0, RAIL_ENTRY_HEIGHT)
	var box := _make_inner(button, 16, 8)
	var icon := _make_icon(icon_path, tinted, COL_ICON)
	box.add_child(icon)
	var label := Label.new()
	label.theme_type_variation = &"StationPanelTitle"
	label.text = label_text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)
	parent.add_child(button)
	return button


func _build_outfitting() -> void:
	_add_header(_outfitting_header, _pack_header_cells())
	var rows: Array[Button] = []
	for pack: Dictionary in AMMO_PACKS:
		var row := _make_row(
			String(pack[&"icon"]),
			bool(pack[&"tinted"]),
			String(pack[&"name"]),
			"%d ROUNDS PER PACK" % int(pack[&"rounds"]),
			"Ammo%s" % String(pack[&"id"]).to_pascal_case()
		)
		var box: HBoxContainer = row.get_meta(&"box")
		var held := _make_column(box, COL_HELD, "", "HELD")
		var price := _make_column(box, COL_PRICE, "", "CREDITS")
		var tag := _make_column(box, COL_TAG, "", "")
		var payload := {
			&"kind": &"ammo",
			&"id": pack[&"id"],
			&"name": pack[&"name"],
			&"rounds": pack[&"rounds"],
			&"cost": pack[&"cost"],
			&"row": row,
			&"icon": row.get_meta(&"icon"),
			&"value": held[0],
			&"caption": held[1],
			&"price": price[0],
			&"tag": tag[0],
		}
		_wire_row(row, payload)
		rows.append(row)
		_outfitting_rows.add_child(row)
	_add_slack(_outfitting_rows)
	_rows_by_module[Module.OUTFITTING] = rows


func _build_upgrades() -> void:
	_add_header(_upgrades_header, _upgrade_header_cells())
	var rows: Array[Button] = []
	for upgrade: Dictionary in UPGRADES:
		var row := _make_row(
			String(upgrade[&"icon"]),
			false,
			String(upgrade[&"name"]),
			"SLOT %s" % String(upgrade[&"slot"]).to_upper(),
			"Upgrade%s" % String(upgrade[&"slot"]).to_pascal_case()
		)
		var effect_data: Dictionary = upgrade[&"effect"]
		var box: HBoxContainer = row.get_meta(&"box")
		var effect := _make_column(box, COL_EFFECT, _effect_text(effect_data), "EFFECT")
		var price := _make_column(box, COL_PRICE, "", "CREDITS")
		var tag := _make_column(box, COL_TAG, "", "")
		var payload := {
			&"kind": &"upgrade",
			&"id": upgrade[&"id"],
			&"name": upgrade[&"name"],
			&"cost": upgrade[&"cost"],
			&"row": row,
			&"icon": row.get_meta(&"icon"),
			&"value": effect[0],
			&"caption": effect[1],
			&"price": price[0],
			&"tag": tag[0],
		}
		payload[&"effect"] = effect[0]
		_wire_row(row, payload)
		rows.append(row)
		_upgrade_rows.add_child(row)
	_add_slack(_upgrade_rows)
	_rows_by_module[Module.UPGRADES] = rows


func _build_shipyard() -> void:
	var rows: Array[Button] = []
	for ship: Dictionary in SHIPS:
		var meta := "%d HULL · %d HP" % [int(ship[&"hull"]), int(ship[&"hardpoints"])]
		var row := _make_row(
			"",
			false,
			String(ship[&"name"]),
			meta,
			"Ship%s" % String(ship[&"id"]).trim_prefix("ship_").to_pascal_case()
		)
		var box: HBoxContainer = row.get_meta(&"box")
		var tag := _make_column(box, COL_SHIP_TAG, "", "")
		var payload := {
			&"kind": &"ship",
			&"id": ship[&"id"],
			&"name": ship[&"name"],
			&"cost": ship[&"cost"],
			&"row": row,
			&"price": _ship_price,
			&"tag": tag[0],
		}
		_wire_row(row, payload)
		rows.append(row)
		_ship_list.add_child(row)
	_add_slack(_ship_list)
	_rows_by_module[Module.SHIPYARD] = rows
	_build_stat_rows()
	_build_hardpoint_slots()


func _build_stat_rows() -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override(&"separation", 12)
	_ship_stats.add_child(header)
	for cell: Dictionary in [
		{&"text": "COMPARISON", &"width": 0.0, &"expand": true},
		{&"text": "SELECTED", &"width": COL_PRICE, &"expand": false},
		{&"text": "ACTIVE", &"width": COL_PRICE, &"expand": false},
	]:
		header.add_child(_make_header_label(cell))
	for row: Dictionary in STAT_ROWS:
		var line := HBoxContainer.new()
		line.add_theme_constant_override(&"separation", 12)
		_ship_stats.add_child(line)
		var name_label := Label.new()
		name_label.theme_type_variation = &"StationCaption"
		name_label.text = String(row[&"label"])
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(name_label)
		var selected := _make_stat_value(line, COL_PRICE)
		var active := _make_stat_value(line, COL_PRICE)
		active.add_theme_color_override(&"font_color", _token(&"text_dim"))
		_stat_values[row[&"key"]] = [selected, active]


func _make_stat_value(parent: HBoxContainer, width: float) -> Label:
	var label := Label.new()
	label.theme_type_variation = &"StationValue"
	label.custom_minimum_size = Vector2(width, 0.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	parent.add_child(label)
	return label


func _build_hardpoint_slots() -> void:
	for index in HARDPOINT_PLATES:
		var plate := _make_slot_plate(_hardpoint_slots, &"SlotButtonWeapon", 48.0)
		plate.disabled = true
		plate.name = "Hardpoint%02d" % (index + 1)


func _make_slot_plate(parent: HBoxContainer, variation: StringName, size: float) -> TextureButton:
	# ui/components/slot_button.gd copies the theme plate textures onto the node, because a
	# bare TextureButton with only theme_type_variation set draws no plate at all: a
	# TextureButton has no stylebox items, so SlotButtonWeapon/Cargo/styles/* is never read
	# by the engine. The mockup repeats that lookup instead of instancing the component so the
	# strip also renders in the editor (SlotButton is not a @tool script). The child is added
	# first, because has_theme_stylebox only resolves once the node inherits the root theme.
	var plate := TextureButton.new()
	plate.theme_type_variation = variation
	plate.custom_minimum_size = Vector2(size, size)
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
	for container: HBoxContainer in [_hardpoint_slots, _cargo_slots]:
		for child: Node in container.get_children():
			var plate := child as TextureButton
			if plate != null:
				_apply_plate_textures(plate)


func _build_launch() -> void:
	for index in CARGO_MANIFEST.size() + 2:
		var plate := _make_slot_plate(_cargo_slots, &"SlotButtonCargo", 40.0)
		plate.name = "CargoSlot%02d" % (index + 1)
		plate.disabled = index >= CARGO_MANIFEST.size()
		if plate.disabled:
			continue
		var icon := _make_icon(String(CARGO_MANIFEST[index][&"icon"]), true, 24.0)
		plate.add_child(icon)
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 8.0
		icon.offset_top = 8.0
		icon.offset_right = -8.0
		icon.offset_bottom = -8.0
	for item: Dictionary in CARGO_MANIFEST:
		_cargo_list.add_item("%s   %d" % [String(item[&"name"]), int(item[&"qty"])])
	if _cargo_list.item_count > 0:
		_cargo_list.select(0)
	_build_brief_rows()


func _build_brief_rows() -> void:
	_add_brief_row(&"destination", "DESTINATION", "OPEN SPACE · SECTOR K-9")
	_add_brief_row(&"hull_name", "ACTIVE HULL", "")
	_add_brief_row(&"hull", "HULL LIMIT", "")
	_add_brief_row(&"shield", "SHIELD LIMIT", "")
	_add_brief_row(&"hardpoints", "HARDPOINTS", "")
	_add_brief_row(&"cargo", "CARGO", "")
	_add_brief_row(&"ammo", "AMMUNITION", "")


func _add_brief_row(key: StringName, caption_text: String, value_text: String) -> void:
	var line := HBoxContainer.new()
	line.add_theme_constant_override(&"separation", 12)
	_brief_rows.add_child(line)
	var caption := Label.new()
	caption.theme_type_variation = &"StationCaption"
	caption.text = caption_text
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(caption)
	var value := Label.new()
	value.theme_type_variation = &"StationValue"
	value.text = value_text
	value.custom_minimum_size = Vector2(COL_BRIEF, 0.0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line.add_child(value)
	_brief_values[key] = value


func _pack_header_cells() -> Array[Dictionary]:
	return [
		{&"text": "", &"width": COL_ICON, &"expand": false},
		{&"text": "PACK", &"width": 0.0, &"expand": true},
		{&"text": "HELD / MAX", &"width": COL_HELD, &"expand": false},
		{&"text": "PRICE", &"width": COL_PRICE, &"expand": false},
		{&"text": "STATUS", &"width": COL_TAG, &"expand": false},
	]


func _upgrade_header_cells() -> Array[Dictionary]:
	return [
		{&"text": "", &"width": COL_ICON, &"expand": false},
		{&"text": "UPGRADE", &"width": 0.0, &"expand": true},
		{&"text": "EFFECT", &"width": COL_EFFECT, &"expand": false},
		{&"text": "PRICE", &"width": COL_PRICE, &"expand": false},
		{&"text": "STATUS", &"width": COL_TAG, &"expand": false},
	]


func _add_header(parent: HBoxContainer, cells: Array[Dictionary]) -> void:
	for cell: Dictionary in cells:
		parent.add_child(_make_header_label(cell))


func _make_header_label(cell: Dictionary) -> Control:
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


func _make_row(
	icon_path: String, tinted: bool, title: String, meta: String, node_name: String
) -> Button:
	var row := Button.new()
	row.name = node_name
	row.toggle_mode = true
	row.focus_mode = Control.FOCUS_ALL
	row.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var box := _make_inner(row, 12, 8)
	var icon: TextureRect = null
	if not icon_path.is_empty():
		icon = _make_icon(icon_path, tinted, COL_ICON)
		icon.modulate.a = ROW_ICON_IDLE_ALPHA
		box.add_child(icon)
	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override(&"separation", 2)
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title_box)
	var title_label := Label.new()
	title_label.theme_type_variation = &"StationValue"
	title_label.text = title
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_box.add_child(title_label)
	var meta_label := Label.new()
	meta_label.theme_type_variation = &"StationCaption"
	meta_label.text = meta
	meta_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_box.add_child(meta_label)
	row.set_meta(&"box", box)
	row.set_meta(&"icon", icon)
	return row


func _make_inner(button: Button, h_margin: int, v_margin: int) -> HBoxContainer:
	var inner := MarginContainer.new()
	inner.name = "RowInner"
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override(&"margin_left", h_margin)
	inner.add_theme_constant_override(&"margin_top", v_margin)
	inner.add_theme_constant_override(&"margin_right", h_margin)
	inner.add_theme_constant_override(&"margin_bottom", v_margin)
	button.add_child(inner)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := HBoxContainer.new()
	box.add_theme_constant_override(&"separation", 12)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(box)
	return box


func _make_icon(icon_path: String, tinted: bool, size: float) -> TextureRect:
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(size, size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = load(icon_path)
	icon.modulate = _token(&"text_primary") if tinted else Color.WHITE
	return icon


func _make_column(
	parent: HBoxContainer, width: float, value_text: String, caption_text: String
) -> Array[Label]:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(width, 0.0)
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override(&"separation", 2)
	parent.add_child(box)
	var value := Label.new()
	value.theme_type_variation = &"StationValue"
	value.text = value_text
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(value)
	var caption := Label.new()
	caption.theme_type_variation = &"StationCaption"
	caption.text = caption_text
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(caption)
	var out: Array[Label] = [value, caption]
	return out


func _add_slack(parent: VBoxContainer) -> void:
	var slack := Control.new()
	slack.name = "Slack"
	slack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(slack)


func _wire_row(row: Button, payload: Dictionary) -> void:
	row.set_meta(&"payload", payload)
	row.pressed.connect(_on_row_pressed.bind(payload))
	row.focus_entered.connect(_on_row_focused.bind(row, payload))
	row.mouse_entered.connect(_on_row_hovered.bind(payload, true))
	row.mouse_exited.connect(_on_row_hovered.bind(payload, false))


func _refresh_all() -> void:
	_credits_value.text = _format_int(_credits)
	for rows: Array in _rows_by_module.values():
		for row: Button in rows:
			var payload: Dictionary = row.get_meta(&"payload")
			_refresh_row(payload)
	_refresh_ship_panel()
	_refresh_brief()


func _refresh_brief() -> void:
	var ship := _ship_by_id(_active_ship)
	if ship.is_empty():
		return
	var cargo_used := 0
	for item: Dictionary in CARGO_MANIFEST:
		cargo_used += int(item[&"qty"])
	var ammo_total := 0
	for id: StringName in _ammo:
		ammo_total += int(_ammo[id])
	_set_brief(&"hull_name", String(ship[&"name"]).to_upper())
	_set_brief(&"hull", str(int(ship[&"hull"])))
	_set_brief(&"shield", str(int(ship[&"shield"])))
	_set_brief(&"hardpoints", str(int(ship[&"hardpoints"])))
	_set_brief(&"cargo", "%d / %d" % [cargo_used, int(ship[&"cargo"])])
	_set_brief(&"ammo", "%s ROUNDS ACROSS %d WEAPONS" % [_format_int(ammo_total), _ammo.size()])


func _set_brief(key: StringName, text: String) -> void:
	var label = _brief_values.get(key)
	if label != null:
		(label as Label).text = text


func _refresh_row(payload: Dictionary) -> void:
	var kind: StringName = payload[&"kind"]
	var id: StringName = payload[&"id"]
	var cost: int = payload[&"cost"]
	var price: Label = payload[&"price"]
	var affordable := cost <= _credits
	if affordable:
		price.remove_theme_color_override(&"font_color")
	else:
		price.add_theme_color_override(&"font_color", _token(&"accent_danger"))
	price.text = _format_int(cost)
	var tag: Label = payload[&"tag"]
	match kind:
		&"ammo":
			var held := int(_ammo.get(id, 0))
			var capacity := int(MOCK_AMMO_MAX.get(id, 0))
			var value: Label = payload[&"value"]
			var caption: Label = payload[&"caption"]
			value.text = "%d / %d" % [held, capacity]
			if held <= 0:
				tag.text = "EMPTY"
				caption.text = "NO ROUNDS HELD"
			elif held > capacity:
				tag.text = "OVER CAP"
				caption.text = "CAPACITY IS ADVISORY"
			elif held == capacity:
				tag.text = "AT CAP"
				caption.text = "NO PURCHASE CAP"
			else:
				tag.text = "IN STOCK"
				caption.text = "BELOW CAPACITY"
		&"ship":
			if id == _active_ship:
				tag.text = "ACTIVE"
			elif _owned_ships.has(id):
				tag.text = "OWNED"
			elif affordable:
				tag.text = "FOR SALE"
			else:
				tag.text = "LOCKED"
		&"upgrade":
			if _installed.has(id):
				tag.text = "INSTALLED"
			elif affordable:
				tag.text = "AVAILABLE"
			else:
				tag.text = "LOCKED"


func _refresh_ship_panel() -> void:
	var ship := _ship_by_id(_selected_ship)
	if ship.is_empty():
		return
	var texture := load(String(ship[&"preview"])) as Texture2D
	_preview_image.texture = texture
	_native_preview = texture.get_size() if texture != null else Vector2(320.0, 180.0)
	_preview_name.text = String(ship[&"name"])
	_preview_caption.text = String(ship[&"description"])
	_update_preview_size()
	var active := _ship_by_id(_active_ship)
	for stat: Dictionary in STAT_ROWS:
		var labels: Array = _stat_values.get(stat[&"key"], [])
		if labels.size() < 2:
			continue
		var selected_value := int(ship.get(stat[&"key"], 0))
		var active_value := int(active.get(stat[&"key"], 0))
		var selected_label: Label = labels[0]
		var active_label: Label = labels[1]
		selected_label.text = str(selected_value)
		active_label.text = str(active_value)
		if selected_value < active_value:
			selected_label.add_theme_color_override(&"font_color", _token(&"text_dim"))
		else:
			selected_label.remove_theme_color_override(&"font_color")
	var hardpoints := int(ship[&"hardpoints"])
	for index in _hardpoint_slots.get_child_count():
		var plate := _hardpoint_slots.get_child(index) as TextureButton
		if plate != null:
			plate.disabled = index >= hardpoints
	_ship_price.text = _format_int(int(ship[&"cost"]))
	if int(ship[&"cost"]) > _credits:
		_ship_price.add_theme_color_override(&"font_color", _token(&"accent_danger"))
	else:
		_ship_price.remove_theme_color_override(&"font_color")
	if _selected_ship == _active_ship:
		_ship_action.text = "IN SERVICE"
		_ship_action.disabled = true
	elif _owned_ships.has(_selected_ship):
		_ship_action.text = "SET ACTIVE"
		_ship_action.disabled = false
	else:
		_ship_action.text = "BUY"
		_ship_action.disabled = false


func _update_preview_size() -> void:
	var target := _native_preview * PREVIEW_SCALE
	if target.x > PREVIEW_MAX_WIDTH:
		target *= PREVIEW_MAX_WIDTH / target.x
	var box := _preview_center.size
	if box.x > 1.0 and target.x > box.x:
		target *= box.x / target.x
	if box.y > 1.0 and target.y > box.y:
		target *= box.y / target.y
	if not _preview_image.custom_minimum_size.is_equal_approx(target):
		_preview_image.custom_minimum_size = target


func _ship_by_id(id: StringName) -> Dictionary:
	for ship: Dictionary in SHIPS:
		if ship[&"id"] == id:
			return ship
	return {}


func _effect_text(effect: Dictionary) -> String:
	var parts: PackedStringArray = []
	for key: StringName in effect:
		var label := String(EFFECT_LABELS.get(key, String(key).to_upper()))
		parts.append("%s +%d%%" % [label, roundi(float(effect[key]) * 100.0)])
	return " · ".join(parts)


func _on_module_pressed(module: int) -> void:
	_select_module(module)


func _cycle_module(step: int) -> void:
	var count := _module_entries.size()
	_select_module(posmod(_module + step, count))


func _select_module(module: int, instant: bool = false) -> void:
	if module == _module and not instant:
		return
	var outgoing := _pane_for(_module)
	var incoming := _pane_for(module)
	_module = module
	for index in _module_entries.size():
		_module_entries[index].set_pressed_no_signal(index == module)
	if instant or outgoing == null or outgoing == incoming:
		for pane: VBoxContainer in _panes:
			pane.visible = pane == incoming
		incoming.modulate.a = 1.0
		_focus_primary_row()
		return
	incoming.visible = true
	incoming.modulate.a = 0.0
	var tween := _make_tween()
	tween.tween_property(outgoing, "modulate:a", 0.0, MODULE_OUT_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(outgoing.hide)
	tween.tween_property(incoming, "modulate:a", 1.0, MODULE_IN_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_focus_primary_row)


func _pane_for(module: int) -> VBoxContainer:
	if module < 0 or module >= _panes.size():
		return null
	return _panes[module]


func _focus_primary_row() -> void:
	var rows: Array = _rows_by_module.get(_module, [])
	if rows.is_empty():
		# LAUNCH has no list rows, so its primary action takes the focus instead. Without
		# this the ring would stay on a row of the module that was just hidden.
		if _pane_for(_module) == _pane_launch:
			_launch_button.grab_focus()
		return
	var row := rows[0] as Button
	if row != null:
		row.grab_focus()


func _on_row_focused(row: Button, payload: Dictionary) -> void:
	if _selected_row != null and _selected_row != row and is_instance_valid(_selected_row):
		_selected_row.set_pressed_no_signal(false)
	_selected_row = row
	row.set_pressed_no_signal(true)
	if StringName(payload[&"kind"]) == &"ship":
		_selected_ship = payload[&"id"]
		_refresh_ship_panel()
	_set_status(_row_hint(payload), false)


func _row_hint(payload: Dictionary) -> String:
	var name_text := String(payload[&"name"])
	var cost := int(payload[&"cost"])
	match StringName(payload[&"kind"]):
		&"ammo":
			return "ENTER BUY · %s · %s CREDITS" % [name_text.to_upper(), _format_int(cost)]
		&"upgrade":
			return "ENTER INSTALL · %s · %s CREDITS" % [name_text.to_upper(), _format_int(cost)]
		&"ship":
			return "ENTER SELECT · %s · %s CREDITS" % [name_text.to_upper(), _format_int(cost)]
	return name_text.to_upper()


func _on_row_hovered(payload: Dictionary, hovered: bool) -> void:
	var icon = payload.get(&"icon")
	if icon == null:
		return
	var target := 1.0 if hovered else ROW_ICON_IDLE_ALPHA
	var tween := _make_tween()
	tween.tween_property(icon as TextureRect, "modulate:a", target, HOVER_SECONDS)


func _on_row_pressed(payload: Dictionary) -> void:
	var row: Button = payload[&"row"]
	row.set_pressed_no_signal(true)
	_selected_row = row
	var cost := int(payload[&"cost"])
	var name_text := String(payload[&"name"])
	match StringName(payload[&"kind"]):
		&"ammo":
			var id: StringName = payload[&"id"]
			if cost > _credits:
				_deny(payload, "REFUSED · NOT ENOUGH CREDITS · %s NEEDED" % _format_int(cost))
				return
			_ammo[id] = int(_ammo.get(id, 0)) + int(payload[&"rounds"])
			_spend(cost, "PURCHASED · %s · +%d ROUNDS" % [name_text.to_upper(), int(payload[&"rounds"])])
		&"ship":
			var ship_id: StringName = payload[&"id"]
			if ship_id == _active_ship:
				_deny(payload, "REFUSED · ALREADY THE ACTIVE HULL · %s" % name_text.to_upper())
				return
			if _owned_ships.has(ship_id):
				_active_ship = ship_id
				_selected_ship = ship_id
				_set_status("ACTIVE HULL IS NOW %s" % name_text.to_upper(), false)
				_refresh_all()
				return
			if cost > _credits:
				_deny(payload, "REFUSED · NOT ENOUGH CREDITS · %s NEEDED" % _format_int(cost))
				return
			_owned_ships.append(ship_id)
			_selected_ship = ship_id
			_spend(cost, "PURCHASED · %s · NOT ACTIVE UNTIL YOU SET IT" % name_text.to_upper())
		&"upgrade":
			if _installed.has(payload[&"id"]):
				_deny(payload, "REFUSED · ALREADY INSTALLED · %s" % name_text.to_upper())
				return
			if cost > _credits:
				_deny(payload, "REFUSED · NOT ENOUGH CREDITS · %s NEEDED" % _format_int(cost))
				return
			_installed.append(payload[&"id"])
			_spend(cost, "INSTALLED · %s · PERMANENT FOR V1" % name_text.to_upper())
	_refresh_all()


func _on_ship_action_pressed() -> void:
	if _selected_ship == _active_ship:
		_set_status("REFUSED · ALREADY THE ACTIVE HULL", true)
		return
	if _owned_ships.has(_selected_ship):
		_active_ship = _selected_ship
		_set_status("ACTIVE HULL IS NOW %s" % _ship_by_id(_active_ship)[&"name"], false)
		_refresh_all()
		return
	var ship := _ship_by_id(_selected_ship)
	if ship.is_empty():
		return
	if int(ship[&"cost"]) > _credits:
		_set_status("REFUSED · NOT ENOUGH CREDITS · %s NEEDED" % _format_int(int(ship[&"cost"])), true)
		_pulse(_credits_panel)
		return
	_owned_ships.append(_selected_ship)
	_spend(int(ship[&"cost"]), "PURCHASED · %s · NOW SET IT ACTIVE" % String(ship[&"name"]).to_upper())


func _spend(cost: int, message: String) -> void:
	var from := _credits
	_credits = maxi(_credits - cost, 0)
	_animate_credits(from, _credits, CREDITS_STEP_SECONDS)
	_set_status(message, false)
	_pulse(_credits_panel)


func _deny(payload: Dictionary, message: String) -> void:
	_set_status(message, true)
	_pulse(payload[&"price"] as Label)
	_pulse(_credits_panel)


func _animate_credits(from: int, to: int, seconds: float) -> void:
	var tween := _make_tween()
	tween.tween_method(_set_credits_text, float(from), float(to), seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _set_credits_text(value: float) -> void:
	_credits_value.text = _format_int(roundi(value))


func _set_status(message: String, danger: bool) -> void:
	_status_label.text = message
	if danger:
		_status_label.add_theme_color_override(&"font_color", _token(&"accent_danger"))
	else:
		_status_label.add_theme_color_override(&"font_color", _token(&"text_primary"))


func _pulse(node: CanvasItem) -> void:
	var tween := _make_tween()
	tween.tween_property(node, "modulate:a", 0.35, 0.12).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "modulate:a", 0.35, 0.12).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE)


func _arm_launch() -> void:
	if _launch_armed:
		_fire_launch()
		return
	_launch_armed = true
	_launch_button.add_theme_color_override(&"font_color", _token(&"accent_danger_bright"))
	_confirm_strip.text = "ARMED · PRESS LAUNCH AGAIN WITHIN 3 s TO UNDOCK"
	_set_status("LAUNCH ARMED · PRESS AGAIN TO CONFIRM", false)
	_arm_timer.start()
	var tween := _make_tween()
	tween.tween_property(_launch_button, "modulate:a", 0.70, 0.16).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_launch_button, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_launch_button, "modulate:a", 0.70, 0.16).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_launch_button, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE)


func _on_arm_timeout() -> void:
	_launch_armed = false
	_launch_button.remove_theme_color_override(&"font_color")
	_confirm_strip.text = "ARMING EXPIRED · PRESS LAUNCH TO ARM AGAIN"
	_set_status("LAUNCH DISARMED · ARMING EXPIRED", false)


func _fire_launch() -> void:
	_launch_armed = false
	_arm_timer.stop()
	_launch_button.remove_theme_color_override(&"font_color")
	_confirm_strip.text = "LAUNCH CONFIRMED · HANDOFF TO THE LOADING BRIDGE · DESTINATION game"
	_set_status("HANDOFF · loading -> game (the mockup does not route)", false)
	var tween := _make_tween()
	tween.tween_property(_fade, "color:a", LAUNCH_FADE_ALPHA, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_interval(0.75)
	tween.tween_property(_fade, "color:a", 0.0, 0.60).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_on_launch_faded)


func _on_launch_faded() -> void:
	_confirm_strip.text = "PRESS LAUNCH TO ARM · A SECOND PRESS CONFIRMS WITHIN 3 s"


func _handle_cancel() -> void:
	if _leave_confirm.visible:
		_close_leave_confirm()
		return
	if _launch_armed:
		_launch_armed = false
		_arm_timer.stop()
		_launch_button.remove_theme_color_override(&"font_color")
		_confirm_strip.text = "PRESS LAUNCH TO ARM · A SECOND PRESS CONFIRMS WITHIN 3 s"
		_set_status("LAUNCH DISARMED", false)
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and not _rail_has_focus(focused):
		_focus_current_rail_entry()
		return
	_open_leave_confirm()


func _rail_has_focus(control: Control) -> bool:
	return _module_buttons.is_ancestor_of(control) or _session_buttons.is_ancestor_of(control)


func _focus_current_rail_entry() -> void:
	if _module < _module_entries.size():
		_module_entries[_module].grab_focus()


func _open_leave_confirm() -> void:
	_leave_confirm.visible = true
	_leave_cancel.grab_focus()
	_set_status("LEAVE THE STATION? · ESC STAYS DOCKED", false)


func _close_leave_confirm() -> void:
	_leave_confirm.visible = false
	_focus_current_rail_entry()


func _on_logout_pressed() -> void:
	_close_leave_confirm()
	_set_status("HANDOFF · main_menu (the mockup does not route)", false)


func _play_entry() -> void:
	_backdrop_dim.color.a = 0.0
	_header.modulate.a = 0.0
	_module_rail.modulate.a = 0.0
	_module_host.modulate.a = 0.0
	_footer.modulate.a = 0.0
	var tween := _make_tween()
	tween.set_parallel(true)
	tween.tween_property(_backdrop_dim, "color:a", BACKDROP_DIM_ALPHA, ENTRY_SECONDS + 0.15)
	tween.tween_property(_header, "modulate:a", 1.0, ENTRY_SECONDS).set_delay(0.06)
	tween.tween_property(_module_rail, "modulate:a", 1.0, ENTRY_SECONDS).set_delay(0.12)
	tween.tween_property(_module_host, "modulate:a", 1.0, ENTRY_SECONDS).set_delay(0.18)
	tween.tween_property(_footer, "modulate:a", 1.0, ENTRY_SECONDS).set_delay(0.24)
	_animate_credits(0, _credits, CREDITS_SECONDS)


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
