class_name Hud
extends Control
## In-game HUD: hull/shield/energy/fuel bars, weapon and cargo slots, minimap, the
## cursor and lock reticle, the target stats window, the interaction prompt strip,
## the safe-warp channel bar and the Emergency Flight Mode banner. Contract:
## docs/design/IMPLEMENTATION_PLAN.md sections 3.10, 4.7, the 9.8 flight-placeholder
## amendments and the 9.9 engine-wave amendments (prompt strip, warp bar, friendly
## blips, reticle states), plus UI_SPEC section 3.1b for the two pool bars and the
## banner (ENGINE_SPEC section 10).
## Reads PlayerState and its signals only; never mutates gameplay state. The
## gameplay side pushes everything else down through the section 3.10 API.

signal weapon_slot_selected(slot: int)
signal cargo_toggled(open: bool)
signal minimap_zoom_changed(delta: int)

const TOKENS_TYPE: StringName = &"Tokens"
const TOKEN_TEXT_PRIMARY: StringName = &"text_primary"
const TOKEN_TEXT_DIM: StringName = &"text_dim"
const TOKEN_DANGER: StringName = &"accent_danger"
const TOKEN_DANGER_BRIGHT: StringName = &"accent_danger_bright"
const TOKEN_METAL_LIGHT: StringName = &"metal_light"
const TOKEN_METAL_MID: StringName = &"metal_mid"
const TOKEN_VOID_BASE: StringName = &"void_base"

const SETTINGS_SECTION: StringName = &"interface"
const SETTINGS_KEY_OPACITY: StringName = &"hud_opacity"

const SLOT_SCENE: PackedScene = preload("res://ui/components/slot_button.tscn")
const VARIATION_WEAPON: StringName = &"SlotButtonWeapon"
const VARIATION_CARGO: StringName = &"SlotButtonCargo"

## Slot order mirrors PlayerState.WEAPONS (contract section 3.9); the icons are
## the 48 px cuts from the weapon panel (ICONS_SPEC section 5).
const WEAPON_IDS: Array[StringName] = [&"laser", &"cannon", &"rocket", &"mine", &"plasma"]
const WEAPON_LABELS: Array[String] = ["Laser MkII", "Cannon MkI", "Rocket Pod", "Mine Layer", "Plasma Coil"]
const WEAPON_ICONS: Array[Texture2D] = [
	preload("res://assets/icons/tint/icon_weapon_laser_48.png"),
	preload("res://assets/icons/tint/icon_weapon_cannon_48.png"),
	preload("res://assets/icons/tint/icon_weapon_rocket_48.png"),
	preload("res://assets/icons/tint/icon_weapon_mine_48.png"),
	preload("res://assets/icons/tint/icon_weapon_plasma_48.png"),
]
const CARGO_ICONS: Array[Texture2D] = [
	preload("res://assets/icons/tint/icon_cargo_ore_48.png"),
	preload("res://assets/icons/tint/icon_cargo_crate_48.png"),
	preload("res://assets/icons/tint/icon_cargo_container_48.png"),
	preload("res://assets/icons/tint/icon_cargo_fuel_cell_48.png"),
	preload("res://assets/icons/tint/icon_cargo_salvage_48.png"),
	preload("res://assets/icons/tint/icon_cargo_data_core_48.png"),
]

const HULL_DANGER_FRACTION: float = 0.25
const AMMO_DANGER_FRACTION: float = 0.10

## UI_SPEC section 3.1b: the Fuel fill and readout turn `accent_danger` at or below
## this share of the tank. The Energy fill has no share of its own — it follows
## Emergency Flight Mode, which is `fuel <= 0` (ENGINE_SPEC section 4.4 ruling 14).
const FUEL_DANGER_FRACTION: float = 0.15
const POOL_KIND_ENERGY: StringName = &"energy"
const POOL_KIND_FUEL: StringName = &"fuel"
const POOL_TITLE_ENERGY := "ENERGY"
const POOL_TITLE_FUEL := "FUEL"
const POOL_BLOCK_ENERGY := "EnergyBlock"
const POOL_BLOCK_FUEL := "FuelBlock"
const EMERGENCY_BANNER := "EmergencyBanner"
const EMERGENCY_BANNER_TEXT := "EMERGENCY FLIGHT"
## UI_SPEC section 3.1b: the same 260 x 14 readout the hull and shield bars use.
const POOL_BAR_SIZE := Vector2(260.0, 14.0)
## The scene's own block/header/row separations (hud.tscn, HullBlock pattern).
const POOL_BLOCK_SEPARATION := 2
const POOL_HEADER_SEPARATION := 6
const POOL_ROW_SEPARATION := 0
const POOL_VALUE_FORMAT := "%d/%d"
const ZOOM_DELTA_MINUS: int = -1
const ZOOM_DELTA_PLUS: int = 1
const CARGO_PANEL_GAP: float = 8.0

## Section 3.10 amendment 9.8: the target window's captions carry a grouped
## number, so a 4-digit range reads `1 240 m` rather than `1240 m`.
const DISTANCE_FORMAT := "%s m"

const PERCENT_FORMAT := "%d%%"

## The one threat reading that colours the label (W6-4). Every other string the caller may
## pass (NEUTRAL, SCANNING, ...) keeps the theme colour.
const THREAT_HOSTILE := "HOSTILE"

@onready var _top_left: MarginContainer = $CanvasLayer/TopLeft
## Section 3.1b: the column the HULL and SHIELD blocks live in. The two pool blocks
## are appended to it (below ShieldBlock) by `_build_pool_blocks`.
@onready var _blocks: VBoxContainer = $CanvasLayer/TopLeft/Blocks
@onready var _top_right: MarginContainer = $CanvasLayer/TopRight
@onready var _bottom_left: MarginContainer = $CanvasLayer/BottomLeft
@onready var _bottom_right: MarginContainer = $CanvasLayer/BottomRight
@onready var _bottom_center: MarginContainer = $CanvasLayer/BottomCenter
@onready var _prompt_label: Label = %PromptLabel
@onready var _warp_block: VBoxContainer = %WarpBlock
@onready var _warp_bar: ProgressBar = %WarpBar
@onready var _warp_value: Label = %WarpValue
@onready var _center_overlay: Control = $CanvasLayer/CenterOverlay
@onready var _ammo_panel: PanelContainer = %AmmoPanel
@onready var _hull_icon: TextureRect = %HullIcon
@onready var _hull_value: Label = %HullValue
@onready var _hull_bar: ProgressBar = %HullBar
@onready var _shield_icon: TextureRect = %ShieldIcon
@onready var _shield_value: Label = %ShieldValue
@onready var _shield_bar: ProgressBar = %ShieldBar
@onready var _ammo_icon: TextureRect = %AmmoIcon
@onready var _ammo_label: Label = %AmmoLabel
@onready var _weapon_grid: GridContainer = %WeaponGrid
@onready var _cargo_toggle: TextureButton = %CargoToggle
@onready var _minimap_panel: PanelContainer = %MinimapPanel
@onready var _minimap: Minimap = %MinimapView
@onready var _sector_label: Label = %SectorLabel
@onready var _zoom_minus: TextureButton = %ZoomMinus
@onready var _zoom_plus: TextureButton = %ZoomPlus
@onready var _reticle: TargetReticle = %TargetReticle
@onready var _target_panel: PanelContainer = %TargetPanel
@onready var _target_name_label: Label = %TargetName
@onready var _target_hull_bar: ProgressBar = %TargetHullBar
@onready var _target_shield_bar: ProgressBar = %TargetShieldBar
@onready var _target_distance_label: Label = %TargetDistance
@onready var _target_threat_label: Label = %TargetThreat
@onready var _cargo_panel: PanelContainer = %CargoPanel
@onready var _cargo_grid: GridContainer = %CargoGrid
@onready var _cargo_footer_label: Label = %CargoFooterLabel
@onready var _cargo_close: TextureButton = %CargoClose

var _state: PlayerState = null
var _weapon_slots: Array[SlotButton] = []
var _cargo_cells: Array[SlotButton] = []

var _hull_current: float = 0.0
var _hull_max: float = 0.0
var _shield_current: float = 0.0
var _shield_max: float = 0.0
var _active_slot: int = 0
var _weapon_id: StringName = &""
var _ammo: int = 0
var _ammo_max: int = 0
var _cargo_used: int = 0
var _cargo_max: int = 0
var _cargo_open: bool = false
var _minimap_radius: float = 0.0
var _blips: Array[Dictionary] = []
var _sector_name: String = ""
var _zoom_hovered: TextureButton = null

var _target_set: bool = false
var _target_position: Vector2 = Vector2.ZERO
var _target_hull: float = 0.0

var _target_info_set: bool = false
var _target_info_name: String = ""
var _target_info_hull: float = 0.0
var _target_info_shield: float = 0.0
var _target_info_distance_m: float = 0.0
var _target_info_threat: String = ""

var _prompt_text: String = ""
var _warp_progress: float = -1.0
var _reticle_state: int = TargetReticle.State.PLAIN

var _hull_fill_danger: StyleBoxFlat

## Section 3.1b state: one entry per pool kind, keyed by POOL_KIND_*, plus the
## banner, its flag and the token-composed stylebox caches. A theme change clears
## the caches, because a cached box holds the colours of the theme it was built
## from; `_pool_fills` is keyed by the token name it was built for.
var _pool_bars: Dictionary = {}
var _pool_values: Dictionary = {}
var _pool_current: Dictionary = {}
var _pool_maximum: Dictionary = {}
var _emergency: bool = false
var _emergency_banner: Label = null
var _pool_background_box: StyleBoxFlat = null
var _pool_fill_boxes: Dictionary = {}


func _ready() -> void:
	_apply_zone_theme()
	_apply_ammo_panel_style()
	_build_pool_blocks()
	_build_weapon_slots()
	_place_cargo_panel()
	_cargo_panel.visible = false
	_cargo_toggle.pressed.connect(_on_cargo_toggle_pressed)
	_cargo_close.pressed.connect(_on_cargo_close_pressed)
	_zoom_minus.pressed.connect(_on_zoom_pressed.bind(ZOOM_DELTA_MINUS))
	_zoom_plus.pressed.connect(_on_zoom_pressed.bind(ZOOM_DELTA_PLUS))
	_bind_zoom_feedback(_zoom_minus)
	_bind_zoom_feedback(_zoom_plus)
	_refresh_static_tints()
	_refresh_hull()
	_refresh_shield()
	_refresh_weapon()
	_refresh_cargo()
	_apply_sector_name()
	_apply_target()
	_apply_target_info()
	_apply_minimap()
	_apply_prompt()
	_apply_warp_channel()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_hull_fill_danger = null
		_pool_background_box = null
		_pool_fill_boxes.clear()
		_apply_zone_theme()
		_apply_ammo_panel_style()
		_refresh_static_tints()
		_refresh_hull()
		_refresh_weapon()
		_refresh_cargo()
		_apply_emergency()
		_refresh_pools()


func bind(state: PlayerState) -> void:
	_release_state()
	_state = state
	_apply_opacity()
	if _state == null:
		return
	_state.hull_changed.connect(_on_hull_changed)
	_state.shield_changed.connect(_on_shield_changed)
	_state.energy_changed.connect(_on_energy_changed)
	_state.fuel_changed.connect(_on_fuel_changed)
	_state.weapon_changed.connect(_on_weapon_changed)
	_state.cargo_changed.connect(_on_cargo_changed)
	_pull_state()


func set_sector_name(sector: String) -> void:
	_sector_name = sector
	_apply_sector_name()


func set_minimap_scale(world_radius: float) -> void:
	_minimap_radius = maxf(world_radius, 0.001)
	_apply_minimap()


func set_minimap_blips(blips: Array[Dictionary]) -> void:
	_blips = blips
	if _minimap != null:
		_minimap.set_blips(blips)


func set_target(screen_position: Vector2, hull_fraction: float) -> void:
	_target_set = true
	_target_position = screen_position
	_target_hull = clampf(hull_fraction, 0.0, 1.0)
	_apply_target()


## Section 9.8 item 4: the target stats window. `info` is the section 3.10 dictionary
## the caller fills; `hull` and `shield` are fractions, `distance_m` is metres.
func set_target_info(info: Dictionary) -> void:
	_target_info_name = String(info.get("name", ""))
	_target_info_hull = clampf(float(info.get("hull", 0.0)), 0.0, 1.0)
	_target_info_shield = clampf(float(info.get("shield", 0.0)), 0.0, 1.0)
	_target_info_distance_m = maxf(float(info.get("distance_m", 0.0)), 0.0)
	_target_info_threat = String(info.get("threat", ""))
	_target_info_set = true
	_apply_target_info()


func clear_target() -> void:
	_target_set = false
	_target_info_set = false
	_apply_target()
	_apply_target_info()


func set_cargo_open(open: bool) -> void:
	_set_cargo_open(open)


## Section 3.10 (engine-wave amendment) / ENGINE_SPEC section 7: the dock, gate and
## interact prompt strip. An empty string hides it.
func set_prompt(text: String) -> void:
	if text == _prompt_text:
		return
	_prompt_text = text
	_apply_prompt()


## Section 3.10 (engine-wave amendment) / ENGINE_SPEC section 7: the safe-warp
## channel. A progress of zero or less hides the bar; anything above it is clamped
## into the 0 to 1 range.
func set_warp_channel(progress: float) -> void:
	var wanted: float = clampf(progress, 0.0, 1.0)
	if is_equal_approx(wanted, _warp_progress):
		return
	_warp_progress = wanted
	_apply_warp_channel()


## Section 3.1b / ENGINE_SPEC section 10: one of the two pool bars, `kind` being
## &"energy" or &"fuel" (`POOL_KIND_*`). An unknown kind is ignored rather than
## fatal: the seam is called behind a method guard from a scene that may be older
## than this HUD, and a bar that does not exist must not break the caller.
func set_pool(kind: StringName, value: float, maximum: float) -> void:
	if not _pool_bars.has(kind):
		return
	_pool_current[kind] = maxf(value, 0.0)
	_pool_maximum[kind] = maxf(maximum, 0.0)
	_refresh_pool(kind)


## Section 3.1b / ENGINE_SPEC section 10: Emergency Flight Mode (fuel 0). The banner
## appears above the blocks in `accent_danger_bright`, and the Energy fill turns
## `accent_danger` for as long as the mode lasts — the buffer is not a danger state,
## but running dry is. Only the Fuel readout follows a danger reading (section 3.1b).
func set_emergency(active: bool) -> void:
	if active == _emergency:
		return
	_emergency = active
	_apply_emergency()
	_refresh_pool(POOL_KIND_ENERGY)


## Section 9.9 / ENGINE_SPEC section 10: the reticle's state, `TargetReticle.State`
## (plain / in-range / out-of-range / hostile). The HUD only relays the gameplay
## side's reading; the reticle itself follows the cursor.
func set_reticle_state(state: int) -> void:
	_reticle_state = clampi(state, TargetReticle.State.PLAIN, TargetReticle.State.HOSTILE)
	if _reticle != null:
		_reticle.set_state(_reticle_state)


func _release_state() -> void:
	if _state == null:
		return
	if _state.hull_changed.is_connected(_on_hull_changed):
		_state.hull_changed.disconnect(_on_hull_changed)
	if _state.shield_changed.is_connected(_on_shield_changed):
		_state.shield_changed.disconnect(_on_shield_changed)
	if _state.energy_changed.is_connected(_on_energy_changed):
		_state.energy_changed.disconnect(_on_energy_changed)
	if _state.fuel_changed.is_connected(_on_fuel_changed):
		_state.fuel_changed.disconnect(_on_fuel_changed)
	if _state.weapon_changed.is_connected(_on_weapon_changed):
		_state.weapon_changed.disconnect(_on_weapon_changed)
	if _state.cargo_changed.is_connected(_on_cargo_changed):
		_state.cargo_changed.disconnect(_on_cargo_changed)


func _pull_state() -> void:
	_on_hull_changed(_state.hull, _state.hull_max)
	_on_shield_changed(_state.shield, _state.shield_max)
	_on_energy_changed(_state.energy, _state.energy_max)
	_on_fuel_changed(_state.fuel, _state.fuel_max)
	var weapon_id: StringName = WEAPON_IDS[_active_slot] if _active_slot < WEAPON_IDS.size() else &""
	_on_weapon_changed(_active_slot, weapon_id, _ammo_of(_active_slot), _ammo_max_of(_active_slot))
	_on_cargo_changed(_state.cargo_used, _state.cargo_max)


func _ammo_of(slot: int) -> int:
	if _state == null or slot < 0 or slot >= _state.ammo.size():
		return 0
	return _state.ammo[slot]


func _ammo_max_of(slot: int) -> int:
	if _state == null or slot < 0 or slot >= _state.ammo_max.size():
		return 0
	return _state.ammo_max[slot]


func _apply_opacity() -> void:
	var value: Variant = SettingsManager.get_value(SETTINGS_SECTION, SETTINGS_KEY_OPACITY, 1.0)
	modulate.a = clampf(float(value), 0.0, 1.0)


func _apply_zone_theme() -> void:
	# A CanvasLayer is not a CanvasItem, so Godot's Control theme inheritance
	# stops at it and every node below it would resolve against the default
	# theme. The zones carry the HUD's theme so both the baked theme and the
	# router's live theme reach the widgets, and inherit downwards from there.
	if theme == null:
		return
	var zones: Array[Control] = [
		_top_left,
		_top_right,
		_bottom_left,
		_bottom_right,
		_bottom_center,
		_center_overlay,
	]
	for zone: Control in zones:
		if zone != null and zone.theme != theme:
			zone.theme = theme


func _apply_ammo_panel_style() -> void:
	if _ammo_panel == null or theme == null:
		return
	var raised: StyleBox = theme.get_stylebox(&"panel_raised", &"")
	if raised != null:
		_ammo_panel.add_theme_stylebox_override(&"panel", raised)


func _build_weapon_slots() -> void:
	for index: int in WEAPON_IDS.size():
		var slot: SlotButton = SLOT_SCENE.instantiate() as SlotButton
		slot.configure(VARIATION_WEAPON, WEAPON_ICONS[index], index + 1, TOKEN_TEXT_DIM)
		slot.pressed.connect(_on_weapon_slot_pressed.bind(index))
		_weapon_grid.add_child(slot)
		_weapon_slots.append(slot)


## Section 3.1b: the Energy and Fuel blocks, appended to the scene's TopLeft column
## below ShieldBlock, plus the Emergency Flight banner that sits above them. The
## blocks are built here rather than in `hud.tscn` because the scene is not in this
## worker's file set, so the builder mirrors the HullBlock/ShieldBlock pattern
## exactly (header row over a 260 x 14 bar) and styles the bars from the theme's
## `Tokens` roles, the way the hull bar's danger fill already does. That keeps
## section 3.1b's rule intact: no new theme item, no font-size override, no hex
## literal. The scene's atlas bar caps are deliberately not reproduced — they are
## .tscn sub-resources, and the two bars read as the same readout without them.
func _build_pool_blocks() -> void:
	if _blocks == null:
		return
	_emergency_banner = Label.new()
	_emergency_banner.name = EMERGENCY_BANNER
	_emergency_banner.theme_type_variation = &"SectionHeader"
	_emergency_banner.text = EMERGENCY_BANNER_TEXT
	_emergency_banner.visible = false
	_emergency_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_blocks.add_child(_emergency_banner)
	## "Above the blocks" (section 3.1b): the column stacks HULL then SHIELD, so the
	## new child is moved to the top of it.
	_blocks.move_child(_emergency_banner, 0)
	_register_pool(POOL_KIND_ENERGY, POOL_TITLE_ENERGY, POOL_BLOCK_ENERGY)
	_register_pool(POOL_KIND_FUEL, POOL_TITLE_FUEL, POOL_BLOCK_FUEL)
	_apply_emergency()
	_refresh_pools()


## One pool block: a header row (title, spacer, current/max readout) over a bar row.
## Every node ignores the mouse, as the scene's HUD nodes do, so the flight view
## keeps the clicks that set a move target.
func _register_pool(kind: StringName, title: String, block_name: String) -> void:
	var block := VBoxContainer.new()
	block.name = block_name
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block.add_theme_constant_override(&"separation", POOL_BLOCK_SEPARATION)
	var header := HBoxContainer.new()
	header.name = "%sHeader" % block_name
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_constant_override(&"separation", POOL_HEADER_SEPARATION)
	var caption := Label.new()
	caption.name = "%sTitle" % block_name
	caption.theme_type_variation = &"SectionHeader"
	caption.text = title
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var spacer := Control.new()
	spacer.name = "%sSpacer" % block_name
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var value := Label.new()
	value.name = "%sValue" % block_name
	value.theme_type_variation = &"HudReadout"
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(caption)
	header.add_child(spacer)
	header.add_child(value)
	var row := HBoxContainer.new()
	row.name = "%sBarRow" % block_name
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", POOL_ROW_SEPARATION)
	var bar := ProgressBar.new()
	bar.name = "%sBar" % block_name
	bar.custom_minimum_size = POOL_BAR_SIZE
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override(&"background", _pool_background())
	row.add_child(bar)
	block.add_child(header)
	block.add_child(row)
	_blocks.add_child(block)
	_pool_bars[kind] = bar
	_pool_values[kind] = value
	_pool_current[kind] = 0.0
	_pool_maximum[kind] = 0.0


func _ensure_cargo_cells(count: int) -> void:
	var wanted: int = maxi(count, 0)
	while _cargo_cells.size() > wanted:
		var removed: SlotButton = _cargo_cells.pop_back()
		removed.queue_free()
	while _cargo_cells.size() < wanted:
		var index: int = _cargo_cells.size()
		var cell: SlotButton = SLOT_SCENE.instantiate() as SlotButton
		cell.configure(VARIATION_CARGO, CARGO_ICONS[index % CARGO_ICONS.size()], 0, TOKEN_TEXT_DIM)
		_cargo_grid.add_child(cell)
		_cargo_cells.append(cell)


func _place_cargo_panel() -> void:
	# The panel is bottom-anchored inside the full-rect overlay, so it can only
	# be stacked clear of the minimap panel by reading the minimap panel's laid
	# out rect; its own height then grows upwards from that offset.
	if _cargo_panel == null or _minimap_panel == null or _center_overlay == null:
		return
	var overlay: Rect2 = _center_overlay.get_global_rect()
	var minimap: Rect2 = _minimap_panel.get_global_rect()
	if overlay.size.y <= 0.0:
		return
	_cargo_panel.offset_bottom = minimap.position.y - overlay.position.y - overlay.size.y - CARGO_PANEL_GAP


func _on_hull_changed(current: float, maximum: float) -> void:
	_hull_current = maxf(current, 0.0)
	_hull_max = maxf(maximum, 0.0)
	_refresh_hull()


func _on_shield_changed(current: float, maximum: float) -> void:
	_shield_current = maxf(current, 0.0)
	_shield_max = maxf(maximum, 0.0)
	_refresh_shield()


func _on_weapon_changed(slot: int, weapon_id: StringName, ammo: int, ammo_max: int) -> void:
	_active_slot = clampi(slot, 0, WEAPON_IDS.size() - 1)
	_weapon_id = weapon_id
	_ammo = maxi(ammo, 0)
	_ammo_max = maxi(ammo_max, 0)
	_refresh_weapon()


func _on_cargo_changed(used: int, maximum: int) -> void:
	_cargo_used = maxi(used, 0)
	_cargo_max = maxi(maximum, 0)
	_ensure_cargo_cells(_cargo_max)
	_refresh_cargo()


func _on_energy_changed(current: float, maximum: float) -> void:
	set_pool(POOL_KIND_ENERGY, current, maximum)


## The tank channel carries the mode with it: Emergency Flight Mode is exactly
## `fuel <= 0` (ENGINE_SPEC section 4.4 ruling 14), and `PlayerState` is the one that
## decides it — the HUD reads the flag instead of re-deriving the rule, so the banner
## can never disagree with the hull about whether it can thrust.
func _on_fuel_changed(current: float, maximum: float) -> void:
	set_pool(POOL_KIND_FUEL, current, maximum)
	set_emergency(_state != null and _state.emergency_mode)


func _refresh_hull() -> void:
	var critical: bool = _hull_is_critical()
	if _hull_bar != null:
		_hull_bar.max_value = maxf(_hull_max, 1.0)
		_hull_bar.value = _hull_current
		if critical:
			_hull_bar.add_theme_stylebox_override(&"fill", _danger_fill())
		else:
			_hull_bar.remove_theme_stylebox_override(&"fill")
	if _hull_value != null:
		_hull_value.text = "%d/%d" % [int(round(_hull_current)), int(round(_hull_max))]
	_set_text_alert(_hull_value, critical, TOKEN_DANGER_BRIGHT)
	_push_tint(_hull_icon, TOKEN_DANGER if critical else TOKEN_TEXT_DIM)


func _refresh_shield() -> void:
	if _shield_bar != null:
		_shield_bar.max_value = maxf(_shield_max, 1.0)
		_shield_bar.value = _shield_current
	if _shield_value != null:
		_shield_value.text = "%d/%d" % [int(round(_shield_current)), int(round(_shield_max))]


func _refresh_weapon() -> void:
	var low_ammo: bool = _ammo_is_low()
	if _ammo_label != null:
		var label: String = WEAPON_LABELS[_active_slot] if _active_slot < WEAPON_LABELS.size() else ""
		if not _weapon_id.is_empty():
			var known: int = WEAPON_IDS.find(_weapon_id)
			if known >= 0:
				label = WEAPON_LABELS[known]
		_ammo_label.text = "%s  %d/%d" % [label, _ammo, _ammo_max]
	_set_text_alert(_ammo_label, low_ammo, TOKEN_DANGER)
	_push_tint(_ammo_icon, TOKEN_DANGER if low_ammo else TOKEN_TEXT_DIM)
	for index: int in _weapon_slots.size():
		var active: bool = index == _active_slot
		_weapon_slots[index].set_active(active)
		_weapon_slots[index].set_icon_token(TOKEN_TEXT_PRIMARY if active else TOKEN_TEXT_DIM)


func _refresh_cargo() -> void:
	var full: bool = _cargo_is_full()
	if _cargo_footer_label != null:
		_cargo_footer_label.text = "CARGO %d/%d" % [_cargo_used, _cargo_max]
	_set_text_alert(_cargo_footer_label, full, TOKEN_DANGER)
	for index: int in _cargo_cells.size():
		_cargo_cells[index].set_icon_token(TOKEN_TEXT_PRIMARY if index < _cargo_used else TOKEN_TEXT_DIM)


func _refresh_pools() -> void:
	for kind: StringName in _pool_bars:
		_refresh_pool(kind)


func _refresh_pool(kind: StringName) -> void:
	if not _pool_bars.has(kind):
		return
	var maximum: float = _pool_maximum[kind]
	var current: float = _pool_current[kind]
	var bar: ProgressBar = _pool_bars[kind]
	bar.max_value = maxf(maximum, 1.0)
	bar.value = current
	bar.add_theme_stylebox_override(&"fill", _pool_fill(_pool_fill_token(kind)))
	var label: Label = _pool_values[kind]
	if label != null:
		label.text = POOL_VALUE_FORMAT % [int(round(current)), int(round(maximum))]
	_set_text_alert(label, kind == POOL_KIND_FUEL and _pool_in_danger(kind), TOKEN_DANGER)


## Section 3.1b: the Energy fill is `metal_light` — the buffer is not a danger state,
## the same reasoning the shield bar follows — and it takes `accent_danger` only while
## Emergency Flight Mode runs. The Fuel fill is `metal_mid` until the 15 % line.
func _pool_fill_token(kind: StringName) -> StringName:
	if kind == POOL_KIND_FUEL:
		return TOKEN_DANGER if _pool_in_danger(kind) else TOKEN_METAL_MID
	return TOKEN_DANGER if _emergency else TOKEN_METAL_LIGHT


func _pool_in_danger(kind: StringName) -> bool:
	if kind != POOL_KIND_FUEL:
		return _emergency
	var maximum: float = _pool_maximum[kind]
	return maximum > 0.0 and _pool_current[kind] / maximum <= FUEL_DANGER_FRACTION


## The bar styleboxes are composed from the theme's `Tokens` roles, exactly as the
## hull bar's danger fill is: section 3.1b adds no theme item, and a hex literal is
## not legal in HUD code. They are cached because a pool refresh runs at HUD cadence;
## a theme change clears the caches and re-applies them (see `_notification`).
func _pool_background() -> StyleBoxFlat:
	if _pool_background_box == null:
		var box := StyleBoxFlat.new()
		box.set_border_width_all(1)
		box.set_corner_radius_all(0)
		box.bg_color = _token(TOKEN_VOID_BASE)
		box.border_color = _token(TOKEN_METAL_MID)
		_pool_background_box = box
	return _pool_background_box


func _pool_fill(token: StringName) -> StyleBoxFlat:
	var cached: StyleBoxFlat = _pool_fill_boxes.get(token, null)
	if cached != null:
		return cached
	var colour: Color = _token(token)
	var box := StyleBoxFlat.new()
	box.set_border_width_all(1)
	box.set_corner_radius_all(0)
	box.bg_color = colour
	box.border_color = colour
	_pool_fill_boxes[token] = box
	return box


## Section 3.1b: the banner's own colour is fixed at `accent_danger_bright` rather
## than toggled, so it is re-applied on a theme change instead of only when the mode
## flips; the readout beside a full bar is never tinged by it.
func _apply_emergency() -> void:
	if _emergency_banner == null:
		return
	_emergency_banner.visible = _emergency
	_emergency_banner.add_theme_color_override(&"font_color", _token(TOKEN_DANGER_BRIGHT))


func _refresh_static_tints() -> void:
	_push_tint(_hull_icon, TOKEN_TEXT_DIM)
	_push_tint(_shield_icon, TOKEN_TEXT_DIM)
	_push_tint(_cargo_toggle, TOKEN_TEXT_DIM)
	_push_zoom_tint(_zoom_minus)
	_push_zoom_tint(_zoom_plus)
	_push_tint(_cargo_close, TOKEN_TEXT_DIM)


func _hull_is_critical() -> bool:
	return _hull_max > 0.0 and _hull_current / _hull_max < HULL_DANGER_FRACTION


func _ammo_is_low() -> bool:
	return _ammo_max > 0 and float(_ammo) / float(_ammo_max) <= AMMO_DANGER_FRACTION


func _cargo_is_full() -> bool:
	return _cargo_max > 0 and _cargo_used >= _cargo_max


func _danger_fill() -> StyleBoxFlat:
	if _hull_fill_danger == null:
		_hull_fill_danger = StyleBoxFlat.new()
		_hull_fill_danger.set_border_width_all(1)
		_hull_fill_danger.set_corner_radius_all(0)
		var colour: Color = _token(TOKEN_DANGER_BRIGHT)
		_hull_fill_danger.bg_color = colour
		_hull_fill_danger.border_color = colour
	return _hull_fill_danger


func _set_text_alert(label: Label, alert: bool, token: StringName) -> void:
	if label == null:
		return
	if alert:
		label.add_theme_color_override(&"font_color", _token(token))
	else:
		label.remove_theme_color_override(&"font_color")


func _push_tint(item: CanvasItem, token: StringName) -> void:
	if item == null:
		return
	item.modulate = _token(token)


func _apply_sector_name() -> void:
	if _sector_label != null:
		_sector_label.text = _sector_name


func _apply_prompt() -> void:
	if _prompt_label == null:
		return
	_prompt_label.text = _prompt_text
	_prompt_label.visible = not _prompt_text.is_empty()


func _apply_warp_channel() -> void:
	var active: bool = _warp_progress > 0.0
	if _warp_block != null:
		_warp_block.visible = active
	if not active:
		return
	if _warp_bar != null:
		_warp_bar.value = _warp_progress * 100.0
	if _warp_value != null:
		_warp_value.text = PERCENT_FORMAT % int(round(_warp_progress * 100.0))


func _apply_target() -> void:
	if _reticle == null:
		return
	if _target_set:
		_reticle.set_target(_target_position, _target_hull)
	else:
		_reticle.clear_target()


func _apply_target_info() -> void:
	if _target_panel == null:
		return
	_target_panel.visible = _target_info_set
	_apply_threat_tint()
	if not _target_info_set:
		return
	if _target_name_label != null:
		_target_name_label.text = _target_info_name
	if _target_hull_bar != null:
		_target_hull_bar.value = _target_info_hull
	if _target_shield_bar != null:
		_target_shield_bar.value = _target_info_shield
	if _target_distance_label != null:
		_target_distance_label.text = DISTANCE_FORMAT % _format_int(int(round(_target_info_distance_m)))
	if _target_threat_label != null:
		_target_threat_label.text = _target_info_threat


## W6-4: the threat label's colour follows the reading it prints, not the panel's existence.
## Only a hostile reading takes `accent_danger`; any other value (and the hidden panel) drops
## the override and falls back to the theme's label colour.
func _apply_threat_tint() -> void:
	if _target_threat_label == null:
		return
	var hostile: bool = _target_info_set and _target_info_threat == THREAT_HOSTILE
	_set_text_alert(_target_threat_label, hostile, TOKEN_DANGER)


func _apply_minimap() -> void:
	if _minimap == null:
		return
	if _minimap_radius > 0.0:
		_minimap.set_world_radius(_minimap_radius)
	_minimap.set_blips(_blips)


func _on_weapon_slot_pressed(slot: int) -> void:
	_active_slot = clampi(slot, 0, WEAPON_IDS.size() - 1)
	_weapon_id = WEAPON_IDS[_active_slot]
	_ammo = _ammo_of(_active_slot)
	_ammo_max = _ammo_max_of(_active_slot)
	_refresh_weapon()
	weapon_slot_selected.emit(slot)


func _on_cargo_toggle_pressed() -> void:
	_set_cargo_open(not _cargo_open)


func _on_cargo_close_pressed() -> void:
	_set_cargo_open(false)


func _set_cargo_open(open: bool) -> void:
	if _cargo_open == open:
		return
	_cargo_open = open
	if _cargo_panel != null:
		if open:
			_place_cargo_panel()
		_cargo_panel.visible = open
	cargo_toggled.emit(open)


func _on_zoom_pressed(delta: int) -> void:
	minimap_zoom_changed.emit(delta)


## Section 9.8 item 4: the zoom buttons carry no plate art, so hover reads on the
## glyph's own modulate. The pointer is unique, so one field tracks which button
## the resting tint must not overwrite.
func _bind_zoom_feedback(button: TextureButton) -> void:
	if button == null:
		return
	button.mouse_entered.connect(_on_zoom_hovered.bind(button))
	button.mouse_exited.connect(_on_zoom_unhovered.bind(button))


func _on_zoom_hovered(button: TextureButton) -> void:
	_zoom_hovered = button
	_push_zoom_tint(button)


func _on_zoom_unhovered(button: TextureButton) -> void:
	if _zoom_hovered == button:
		_zoom_hovered = null
	_push_zoom_tint(button)


func _push_zoom_tint(button: TextureButton) -> void:
	_push_tint(button, TOKEN_TEXT_PRIMARY if button == _zoom_hovered else TOKEN_TEXT_DIM)


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


func _token(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.WHITE
