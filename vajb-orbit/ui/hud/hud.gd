class_name Hud
extends Control
## In-game HUD: hull/shield/energy/fuel bars, weapon and cargo slots, minimap, the
## cursor and lock reticle, the target stats window, the interaction prompt strip,
## the safe-warp channel bar, the Emergency Flight Mode banner and (slice 2) the
## lock-channel ring, the hit marker and the radial speedometer inside its (wave D6,
## reworked by wave D7) cockpit instrument cluster. Contract:
## docs/design/IMPLEMENTATION_PLAN.md sections 3.10, 4.7, the 9.8 flight-placeholder
## amendments and the 9.9 engine-wave amendments (prompt strip, warp bar, friendly
## blips, reticle states), plus UI_SPEC section 3.1b for the two pool bars and the
## banner, 3.5 for the lock ring, 3.6 for the dial, 3.7 for the cluster (Mockup v5/v7,
## 2026-09-24) and CONTRACTS section 18 for its read-backs.
## Reads PlayerState and its signals only; never mutates gameplay state. The
## gameplay side pushes everything else down through the section 3.10 API.
##
## The slice-2 widgets are built in code by this file (`_build_lock_ring`,
## `_build_hit_marker`, `_build_speedometer`), the same way slice 0 built the pool
## blocks: the ring belongs to the reticle's `ui/hud/target_reticle.gd` and the dial
## is a bare `_draw` Control, and neither file is this worker's. Wave D6's cluster is
## `ui/hud/cockpit_cluster.gd` (`_build_cockpit`), and this file hands it the dial.
## Styling stays on the theme's tokens through `_token()`, with the one sanctioned
## exception UI_SPEC section 1 records (`accent_nav`, the prograde needle); the D7
## cluster reads its own `CockpitStyle` instead (UI_SPEC section 3.9 rule 5).
##
## **Wave D7 (2026-09-24)** retires the section 3.6 heading tick (`set_speedometer`'s
## `heading` is still accepted and no longer drawn), hides the old HUD column
## (`_retire_old_column`: the section 3.1 crest bars, the section 3.2 `AmmoPanel` and
## the section 3.4 cargo block) and pushes the ammo feed and the selected rack into the
## cluster, which now draws them as its AMMO row and its `B1..B5` lamps. Every frozen
## section 7 method keeps its signature and stays callable; the retired widgets stay in
## the scene, hidden and no-op, so nothing that drove them breaks.

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
##
## **Seven entries since S5** (09 section 11, CONTRACTS section 17): `GROUPS_MAX` is 7
## and `PlayerState.WEAPONS`' five v1 families are joined by the two modules that exist
## with no v1 ammo row of their own - the railgun (its own pack since S5) and the
## mining laser (a tool, `w_mining`, whose icon is the module cut, not a weapon cut).
## The tables index a **rack ordinal minus one** for the readout's label and icon.
const WEAPON_IDS: Array[StringName] = [
	&"laser", &"cannon", &"rocket", &"mine", &"plasma", &"railgun", &"mining"
]
const WEAPON_LABELS: Array[String] = [
	"Laser MkII", "Cannon MkI", "Rocket Pod", "Mine Layer", "Plasma Coil",
	"Railgun", "Mining Laser",
]
const WEAPON_ICONS: Array[Texture2D] = [
	preload("res://assets/icons/weapon/icon_weapon_laser.svg"),
	preload("res://assets/icons/weapon/icon_weapon_cannon.svg"),
	preload("res://assets/icons/weapon/icon_weapon_rocket.svg"),
	preload("res://assets/icons/weapon/icon_weapon_mine.svg"),
	preload("res://assets/icons/weapon/icon_weapon_plasma.svg"),
	preload("res://assets/icons/module/icon_module_w_railgun.svg"),
	preload("res://assets/icons/module/icon_module_w_mining.svg"),
]
const CARGO_ICONS: Array[Texture2D] = [
	preload("res://assets/icons/cargo/icon_cargo_ore.svg"),
	preload("res://assets/icons/cargo/icon_cargo_crate.svg"),
	preload("res://assets/icons/cargo/icon_cargo_container.svg"),
	preload("res://assets/icons/cargo/icon_cargo_fuel_cell.svg"),
	preload("res://assets/icons/cargo/icon_cargo_salvage.svg"),
	preload("res://assets/icons/cargo/icon_cargo_data_core.svg"),
]

## CONTRACTS section 11: the weapon grid is rebuilt from the launched hull's own W cells.
## `GROUPS_MAX` is `game/weapons.gd`'s count of selectable groups (the input map's
## `weapon_1..5`): a hull with more W cells than that draws all of them and marks the ones
## from `GROUPS_MAX` on not selectable, because no input group can reach them yet.
const GROUPS_MAX: int = WeaponComponent.GROUPS_MAX
## The empty cell's face: the weapon slot glyph (`icon_slot_w`), dimmed by the icon token.
const SLOT_GLYPH_WEAPON: Texture2D = preload("res://assets/icons/slot/icon_slot_w.svg")

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
## B2-3 (owner report: "minimap works in reverse + with -"). The signal carries the
## world-radius delta the gameplay side adds to the map
## (`game.gd::_on_minimap_zoom_changed`, `delta * MINIMAP_RADIUS_STEP`), and a smaller
## world radius magnifies the map, so the button that reads "+" emits the negative
## step and "-" the positive one. The wheel-zoom camera keeps its own direction
## (game.gd section 9.8 item 4); only this HUD path is inverted.
const ZOOM_DELTA_IN: int = -1
const ZOOM_DELTA_OUT: int = 1
const CARGO_PANEL_GAP: float = 8.0

## Section 3.10 amendment 9.8: the target window's captions carry a grouped
## number, so a 4-digit range reads `1 240 m` rather than `1240 m`.
const DISTANCE_FORMAT := "%s m"

const PERCENT_FORMAT := "%d%%"

## UI_SPEC section 3.6 / ENGINE_SPEC section 10: the 120 x 120 radial dial (UI_SPEC's own
## size; its segments, sweep, needle lengths and overdrive line live on the widget below).
const RADIAL_DIAL := "RadialDial"
const DIAL_SIZE := Vector2(120.0, 120.0)

## UI_SPEC section 3.7 / CONTRACTS section 18: the cockpit instrument cluster the dial now
## sits inside (built in code by `_build_cockpit`), and the widget node names.
const COCKPIT_CLUSTER := "CockpitCluster"

## UI_SPEC section 3.8 / CONTRACTS section 18: the ship status screen, its node name and the
## input action that toggles it. The action is read behind `InputMap.has_action`, so a project
## whose input map predates the close-out pass keeps a dead key rather than failing (the
## section 3.8 pin: the `project.godot` row is orchestrator-applied). The script is preloaded by
## path rather than reached through its global class name, so the HUD parses in a headless gate
## that has not re-scanned the project since the file landed (the class name still ships).
const ShipStatusScreenScript := preload("res://ui/hud/ship_status_screen.gd")
const SHIP_STATUS_SCREEN := "ShipStatusScreen"
const SHIP_STATUS_ACTION: StringName = &"ship_status"

## UI_SPEC section 3.5's lock ring and section 4.2 item 4's hit marker: the widget node
## names, and nothing else - each widget owns its own geometry (see the classes at the end
## of this file).
const LOCK_RING := "LockRing"
const HIT_MARKER := "HitMarker"

## The ammo column the dial joins: UI_SPEC section 3.6's "below the ammo panel".
const BOTTOM_LEFT_COLUMN := "Blocks"

## The one threat reading that colours the label (W6-4). Every other string the caller may
## pass (NEUTRAL, SCANNING, ...) keeps the theme colour.
const THREAT_HOSTILE := "HOSTILE"

## Section 3.10's range state (IMPLEMENTATION_PLAN section 9.9): the target window's
## payload carries `in_range` and the distance row prints it. The two readings are the
## spec's own words in section 10 ("in/out of range for the selected weapon").
const RANGE_IN := "IN RANGE"
const RANGE_OUT := "OUT OF RANGE"
const RANGE_FORMAT := "%s  %s"

@onready var _top_left: MarginContainer = $CanvasLayer/TopLeft
## Section 3.1b: the column the HULL and SHIELD blocks live in. The two pool blocks
## are appended to it (below ShieldBlock) by `_build_pool_blocks`.
@onready var _blocks: VBoxContainer = $CanvasLayer/TopLeft/Blocks
## The two section 3.1 crest blocks, retired (hidden) by `_retire_old_column` per UI_SPEC
## section 3.7's 2026-09-24 amendment - HULL and SHLD read in the cluster's rows now.
@onready var _hull_block: VBoxContainer = $CanvasLayer/TopLeft/Blocks/HullBlock
@onready var _shield_block: VBoxContainer = $CanvasLayer/TopLeft/Blocks/ShieldBlock
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
## Section 3.10 amendment (CONTRACTS section 11): the launched hull and the W cells the
## weapon grid was built from. Empty means the grid is still `_build_weapon_slots()`' own
## five-family default, which is the state a HUD with no pushed hull draws.
var _hull_id: StringName = &""
var _hull_slots: Array = []

var _hull_current: float = 0.0
var _hull_max: float = 0.0
var _shield_current: float = 0.0
var _shield_max: float = 0.0
## The selected **rack ordinal minus one** (`WEAPON_IDS`/`WEAPON_LABELS`/the highlight
## read it), and the **barrel position** that selection reads its ammo at - the cell's own
## index in `PlayerState.ammo`, carried by the pushed cell (`game.gd:_hull_slot_cells`'
## `position`). The two are different numbers since S5: one rack may hold several cells of
## several kinds, so rack 1 is not slot 1 (the S5 review's R1-MED-1).
var _active_slot: int = 0
var _active_barrel: int = 0
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
var _target_info_in_range: bool = false
var _target_info_has_range: bool = false

var _prompt_text: String = ""
var _warp_progress: float = -1.0
var _reticle_state: int = TargetReticle.State.PLAIN

## Slice 2's readings, mirrored here so a caller (and a probe) can assert what the HUD
## drew without reaching into a sub-node: the lock channel's progress (-1 = no channel),
## the dial's ratio and the marker's live flag.
var _lock_progress: float = -1.0
var _speedometer_ratio: float = 0.0
var _lock_ring: LockRing = null
var _hit_marker: HitMarker = null
var _speedometer: Speedometer = null
## UI_SPEC section 3.7: the cluster the dial lives in. It carries the compass and the five
## readout rows, and derives them from the feeds this HUD already receives.
var _cockpit: CockpitCluster = null
## UI_SPEC section 3.8 / CONTRACTS section 18: the ship status screen, its docked latch and the
## inputs it reads. The screen reads the profile for the hull, the fit and the power line; the
## HUD only pushes the launched hull's W cells and the two pool pairs it already holds.
var _status: Control = null
var _docked: bool = false

var _hull_fill_danger: StyleBoxFlat

## Section 3.1b state: one entry per pool kind, keyed by POOL_KIND_*, plus the
## banner, its flag and the token-composed stylebox caches. A theme change clears
## the caches, because a cached box holds the colours of the theme it was built
## from; `_pool_fills` is keyed by the token name it was built for. `_pool_bars`
## survives the 2026-09-24 amendment as the kind guard and the block registry: the
## two blocks are retired (hidden) by `_retire_pool_blocks`, and the pool feed
## drives the cluster's FUEL/ENRG dials alone.
var _pool_blocks: Dictionary = {}
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
	_build_hud_widgets()
	_build_weapon_slots()
	_place_cargo_panel()
	_retire_old_column()
	_cargo_toggle.pressed.connect(_on_cargo_toggle_pressed)
	_cargo_close.pressed.connect(_on_cargo_close_pressed)
	_zoom_minus.pressed.connect(_on_zoom_pressed.bind(ZOOM_DELTA_OUT))
	_zoom_plus.pressed.connect(_on_zoom_pressed.bind(ZOOM_DELTA_IN))
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
		_refresh_widget_theme()


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


## Section 9.8 item 4 / section 3.10: the target stats window. `info` is the section 3.10
## dictionary the caller fills; `hull` and `shield` are fractions, `distance_m` is metres.
## Slice 2 adds the two keys section 10 names: `in_range` (the selected weapon's range
## against the distance) and `threat` (section 8's blip class). The threat reading is
## normalised to the upper case the panel prints whatever case the caller sends, so a
## caller may pass the spec's own `&"hostile"` vocabulary, and `in_range` is only rendered
## when the key is present, so a caller that predates it keeps the old text.
func set_target_info(info: Dictionary) -> void:
	_target_info_name = String(info.get("name", ""))
	_target_info_hull = clampf(float(info.get("hull", 0.0)), 0.0, 1.0)
	_target_info_shield = clampf(float(info.get("shield", 0.0)), 0.0, 1.0)
	_target_info_distance_m = maxf(float(info.get("distance_m", 0.0)), 0.0)
	_target_info_threat = String(info.get("threat", "")).to_upper()
	_target_info_has_range = info.has("in_range")
	_target_info_in_range = bool(info.get("in_range", false))
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


## Section 3.1b / ENGINE_SPEC section 10: one of the two pool feeds, `kind` being
## &"energy" or &"fuel" (`POOL_KIND_*`). An unknown kind is ignored rather than
## fatal: the seam is called behind a method guard from a scene that may be older
## than this HUD, and a feed that does not exist must not break the caller.
##
## UI_SPEC section 3.1b's 2026-09-24 amendment: the two `ProgressBar` blocks are off
## the flight HUD, so this feed's only consumer is the cluster's FUEL/ENRG value
## dials - the retired bars are not refreshed. `_pool_current`/`_pool_maximum` stay
## the HUD's own bookkeeping (the frozen API's held reading), which is also what the
## dials are handed.
func set_pool(kind: StringName, value: float, maximum: float) -> void:
	if not _pool_bars.has(kind):
		return
	_pool_current[kind] = maxf(value, 0.0)
	_pool_maximum[kind] = maxf(maximum, 0.0)
	if _cockpit != null:
		_cockpit.set_pool(kind, _pool_current[kind], _pool_maximum[kind])


## Section 3.1b / ENGINE_SPEC section 10: Emergency Flight Mode (fuel 0). The banner
## appears in the TopLeft column where the retired blocks were in
## `accent_danger_bright`. UI_SPEC section 3.1b's 2026-09-24 amendment retires the
## Energy/Fuel blocks, so the banner is the only widget this flag drives; the FUEL
## dial's own danger reading (fuel <= 15 %, which an empty tank satisfies) rides the
## pool feed instead of this flag.
func set_emergency(active: bool) -> void:
	if active == _emergency:
		return
	_emergency = active
	_apply_emergency()


## Section 9.9 / ENGINE_SPEC section 10: the reticle's state, `TargetReticle.State`
## (plain / in-range / out-of-range / hostile). The HUD only relays the gameplay
## side's reading; the reticle itself follows the cursor.
func set_reticle_state(state: int) -> void:
	_reticle_state = clampi(state, TargetReticle.State.PLAIN, TargetReticle.State.HOSTILE)
	if _reticle != null:
		_reticle.set_state(_reticle_state)


## UI_SPEC section 3.5 / ENGINE_SPEC section 10: the lock channel's ring, `progress` over
## 0..1 as the channel runs. A progress of zero or less hides it (the same empty convention
## the warp bar uses), and a full ring stays drawn - "the arc completes to `metal_light` and
## stays for the lock's lifetime".
func set_lock_progress(progress: float) -> void:
	_lock_progress = progress
	if _lock_ring == null:
		return
	_lock_ring.progress = clampf(progress, 0.0, 1.0)
	_lock_ring.complete = progress >= 1.0
	_lock_ring.visible = progress > 0.0
	_lock_ring.queue_redraw()


## UI_SPEC section 3.6 / ENGINE_SPEC section 10: the radial speedometer. `ratio` is the
## hull's speed against its class maximum, `prograde` the actual velocity vector and
## `heading` the nose, both in world space (the dial takes the two angles). A ratio of
## zero still draws the dial; the caller hides it by pushing zero when docked.
func set_speedometer(ratio: float, prograde: Vector2, heading: Vector2) -> void:
	_speedometer_ratio = clampf(ratio, 0.0, 1.0)
	## UI_SPEC section 3.7: the cluster derives SPD (u/s from the prograde length), the
	## compass rotation and the HDG row from this same reading, so no second feed exists.
	if _cockpit != null:
		_cockpit.set_speedometer(_speedometer_ratio, prograde, heading)
	if _speedometer == null:
		return
	_speedometer.set_reading(_speedometer_ratio, prograde, heading)


## Section 4.2 item 4 / ENGINE_SPEC section 10: the hit marker on a confirmed hit. Small,
## no numbers, and faded out by a Tween rather than a per-frame step (the house rule for UI
## animation).
func hit_marker() -> void:
	if _hit_marker == null:
		return
	_hit_marker.flash()


## Read-only mirrors of the three slice-2 readings, so a caller (or a headless probe) can
## assert what the HUD was told without reaching into a sub-node - the same reason
## `TargetReticle.state()` exists.
func lock_progress() -> float:
	return _lock_progress


func speedometer_ratio() -> float:
	return _speedometer_ratio


func lock_ring() -> Control:
	return _lock_ring


func speedometer() -> Control:
	return _speedometer


## CONTRACTS section 18's read-backs (the same probe precedent as `speedometer()`): the
## cluster, the retired compass bay, the retired heading readout and the clamped ints the rows
## show. Each answers from the widget that owns the state, and a HUD with no cluster answers
## empty. Mockup v7 (2026-09-24) ditched the compass entirely: `compass()` answers null and
## `compass_heading()` answers 0.0 through the cluster's stubs, and `readouts()` carries
## {spd, hull, shield, ammo} - the pools read from the cluster's FUEL/ENRG dials.
func cockpit() -> Control:
	return _cockpit


func compass() -> Control:
	return _cockpit.compass() if _cockpit != null else null


func compass_heading() -> float:
	return _cockpit.compass_heading() if _cockpit != null else 0.0


func readouts() -> Dictionary:
	if _cockpit == null:
		return {"spd": 0, "hull": 0, "shield": 0, "ammo": 0}
	return _cockpit.readouts()


func hit_marker_node() -> Control:
	return _hit_marker


## The target window's payload as the HUD holds it (`{}` before the first push), read back
## for the same reason.
func target_info() -> Dictionary:
	if not _target_info_set:
		return {}
	return {
		"name": _target_info_name,
		"hull": _target_info_hull,
		"shield": _target_info_shield,
		"distance_m": _target_info_distance_m,
		"threat": _target_info_threat,
		"in_range": _target_info_in_range,
		"has_range": _target_info_has_range,
	}


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
	_set_barrel(_barrel_of_battery(_active_slot + 1))
	var weapon_id: StringName = _battery_family(_active_slot + 1)
	if weapon_id.is_empty():
		weapon_id = WEAPON_IDS[_active_slot] if _active_slot < WEAPON_IDS.size() else &""
	_on_weapon_changed(_active_slot, weapon_id, _ammo, _ammo_max)
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


## Slice 2's three widgets, all built in code for the same reason the pool blocks are: the
## lock ring belongs on the reticle (`ui/hud/target_reticle.gd` is another worker's file),
## and the marker and the dial are bare `_draw` Controls this file owns. Idempotent, so a
## theme change or a re-`_ready` cannot double them.
func _build_hud_widgets() -> void:
	_build_lock_ring()
	_build_hit_marker()
	_build_cockpit()
	_build_status_screen()


## UI_SPEC section 3.5's lock ring: a full-rect child of the reticle, so it rides the
## reticle's position (the cursor, or the marked hull) and draws around the brackets.
func _build_lock_ring() -> void:
	if _reticle == null or _lock_ring != null:
		return
	_lock_ring = LockRing.new()
	_lock_ring.name = LOCK_RING
	_lock_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lock_ring.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lock_ring.visible = false
	_reticle.add_child(_lock_ring)
	_lock_ring.apply_theme()


## Section 4.2 item 4: the marker sits on the same reticle, so it appears where the shot
## landed (the marked hull) or under the cursor when nothing is marked.
func _build_hit_marker() -> void:
	if _reticle == null or _hit_marker != null:
		return
	_hit_marker = HitMarker.new()
	_hit_marker.name = HIT_MARKER
	_hit_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hit_marker.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hit_marker.visible = false
	_reticle.add_child(_hit_marker)
	_hit_marker.apply_theme()


## UI_SPEC section 3.7 (amendment 2026-09-23, wave D6; reworked 2026-09-24, wave D7): the
## cockpit instrument cluster. The spec originally placed the dial "bottom-centre inside
## BottomLeft's parent column (below the ammo panel)"; the column below the ammo panel is
## `CanvasLayer/BottomLeft/Blocks` (that container's MarginContainer is anchored bottom-left,
## not bottom-centre) and section 3.7 resolves the discrepancy **bottom-left**, so the cluster
## joins that column and centres itself in it. `hud.tscn` is untouched: the cluster is
## `ui/hud/cockpit_cluster.gd`'s own class, built here in the section 7 inner-widget idiom.
## The old ammo panel it used to sit under is retired (hidden) by `_retire_old_column`.
func _build_cockpit() -> void:
	if _bottom_left == null or _cockpit != null:
		return
	var column := _bottom_left.get_node_or_null(NodePath(BOTTOM_LEFT_COLUMN)) as VBoxContainer
	if column == null:
		return
	_cockpit = CockpitCluster.new()
	_cockpit.name = COCKPIT_CLUSTER
	## The box is the cluster's own `CockpitStyle.box_size` (section 3.9 rule 5: a user
	## `.tres` relayouts it), so this file pins no size of its own.
	_cockpit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_cockpit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_cockpit)
	_cockpit.apply_theme()
	_build_speedometer()


## UI_SPEC section 3.6's 120 x 120 dial, now the cluster's left bay. The dial's own contract
## is byte-identical (its geometry, segments, sweep, overdrive line and read-backs); only its
## `_draw` surface gains the painted face and needle sprites under the code-drawn marks. The
## two surface paths come from the cluster's `CockpitStyle` (section 3.9 rule 5), so a user
## `.tres` restyles the dial with everything else; a path that does not resolve keeps the D6
## preloads. The heading marker is retired (section 3.6's 2026-09-24 amendment).
func _build_speedometer() -> void:
	if _speedometer != null:
		return
	var bay: Control = _cockpit.gauge_bay() if _cockpit != null else null
	if bay == null:
		return
	_speedometer = Speedometer.new()
	_speedometer.name = RADIAL_DIAL
	_speedometer.custom_minimum_size = DIAL_SIZE
	_speedometer.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_speedometer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bay.add_child(_speedometer)
	var style: Resource = _cockpit.style() if _cockpit != null else null
	if style != null:
		_speedometer.set_surface_paths(style.gauge_face_path, style.gauge_needle_path)
	_speedometer.apply_theme()


## UI_SPEC section 3.8 (amendment 2026-09-23, wave D6): the ship status screen, a
## HUD-internal modal hidden by default and in flight only. `hud.tscn` is untouched - the
## screen is `ui/hud/ship_status_screen.gd`'s own class, built here in the section 7
## inner-widget idiom and parented to the full-rect `CenterOverlay`, which centres the
## 720 x 520 body. It reads the profile itself; this file only pushes the launched hull's W
## cells and the two pool pairs, and reads the `ship_status` action behind
## `InputMap.has_action`.
func _build_status_screen() -> void:
	if _center_overlay == null or _status != null:
		return
	_status = ShipStatusScreenScript.new()
	_status.name = SHIP_STATUS_SCREEN
	_status.set_anchors_preset(Control.PRESET_FULL_RECT)
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center_overlay.add_child(_status)
	_status.apply_theme()
	_push_status()


## Section 3.8's two pushes: the launched hull with its W cells (`set_hull_slots`) and the live
## HULL/SHLD pairs the HUD already mirrors from `PlayerState`. The screen writes nothing, so
## every refresh is a re-read behind these two calls.
func _push_status() -> void:
	if _status == null:
		return
	if not _hull_id.is_empty():
		_status.set_hull(_hull_id)
	_status.set_pools(_hull_current, _hull_max, _shield_current, _shield_max)


## Section 3.8 / MENU_FLOW section 3.9: the toggle. Esc stays Pause-only, so this reads the
## `ship_status` action alone, and only when the input map carries it (the `project.godot` row
## is orchestrator-applied at close-out - a project without it leaves the key inert, never
## broken). The event is marked handled so no later `_unhandled_input` also acts on it.
func _unhandled_input(event: InputEvent) -> void:
	if _status == null:
		return
	if not InputMap.has_action(SHIP_STATUS_ACTION):
		return
	if not event.is_action_pressed(SHIP_STATUS_ACTION):
		return
	_status.set_open(not _status.is_open())
	get_viewport().set_input_as_handled()


## Section 3.8's "hidden while docked": the dock route replaces this scene, so nothing in
## production calls this today; it is the seam that keeps the rule expressible (and testable)
## on the HUD that owns the screen. Reversal: delete the latch and its two guards.
func set_docked(active: bool) -> void:
	_docked = active
	if _status != null:
		_status.set_docked(active)


func docked() -> bool:
	return _docked


## The section 3.8 read-back (the `speedometer()`/`cockpit()` precedent), so a probe can assert
## the screen's own state without reaching into the scene tree.
func status_screen() -> Control:
	return _status


## The three widgets re-read their tokens on a theme change (see `_notification`).
func _refresh_widget_theme() -> void:
	if _lock_ring != null:
		_lock_ring.apply_theme()
	if _hit_marker != null:
		_hit_marker.apply_theme()
	if _speedometer != null:
		_speedometer.apply_theme()
	if _cockpit != null:
		_cockpit.apply_theme()
	if _status != null:
		_status.apply_theme()


func _build_weapon_slots() -> void:
	for index: int in WEAPON_IDS.size():
		var slot: SlotButton = SLOT_SCENE.instantiate() as SlotButton
		slot.ignore_texture_size = true
		slot.configure(VARIATION_WEAPON, WEAPON_ICONS[index], index + 1, TOKEN_TEXT_DIM)
		slot.pressed.connect(_on_weapon_slot_pressed.bind(index))
		_weapon_grid.add_child(slot)
		_weapon_slots.append(slot)


## CONTRACTS section 11: the launched hull's W cells, one entry per W cell in layout order
## ({slot, index, module, icon, fitted, selectable, battery, position}; `game.gd` builds
## them from `ShipFit.grid_cells` + the fit + `ModuleCatalog`). The grid is rebuilt, never
## appended to, so a re-push is idempotent and the default five-family grid is what an
## empty push falls back to. The hull id is recorded with the cells so a probe can pair the
## read-back with the hull it came from.
##
## The current selection is re-resolved last: the cells are what a rack ordinal and a
## barrel position are read against, so the readout must be answered from the grid that is
## actually drawn - a launch straight into a mixed rack then reads that rack's own barrel
## instead of the empty-grid fallback it was pulled with (the S5 review's R1-MED-1).
func set_hull_slots(hull_id: StringName, cells: Array) -> void:
	_hull_id = hull_id
	_hull_slots = cells.duplicate()
	_rebuild_weapon_slots()
	select_battery(_active_slot + 1)
	## Section 3.8's status screen reads the launched hull and its own cell set.
	if _status != null:
		_status.set_hull_slots(_hull_slots)
	_push_status()


## Read-back for probes (`TargetReticle.state()`'s precedent): the cells the current grid
## was built from, in layout order, as they were handed over.
func hull_slots() -> Array:
	return _hull_slots


## One cell per pushed W cell. `columns` = the smaller of the cell count and `GROUPS_MAX`,
## exactly as pinned, so a 7-cell capital wraps to two rows; a GridContainer rejects 0
## columns, so an empty push keeps one column and simply has no children.
func _rebuild_weapon_slots() -> void:
	for slot: SlotButton in _weapon_slots:
		_weapon_grid.remove_child(slot)
		slot.queue_free()
	_weapon_slots.clear()
	var count: int = _hull_slots.size()
	_weapon_grid.columns = maxi(mini(count, GROUPS_MAX), 1)
	for index: int in count:
		var cell: Dictionary = _hull_slots[index]
		var slot: SlotButton = SLOT_SCENE.instantiate() as SlotButton
		slot.configure_cell(
			VARIATION_WEAPON, _weapon_cell_icon(cell), SlotButton.CELL_SIZE_WEAPON, TOKEN_TEXT_DIM
		)
		slot.disabled = not _weapon_cell_selectable(index, cell)
		slot.pressed.connect(_on_weapon_slot_pressed.bind(index))
		_weapon_grid.add_child(slot)
		_weapon_slots.append(slot)
	_refresh_weapon()


## A fitted cell draws the module icon it was handed; an empty cell (or a cell whose icon
## path does not resolve) draws the weapon slot glyph, which `_refresh_weapon` dims.
func _weapon_cell_icon(cell: Dictionary) -> Texture2D:
	if StringName(cell.get(&"module", &"")).is_empty():
		return SLOT_GLYPH_WEAPON
	var path := String(cell.get(&"icon", ""))
	if path.is_empty():
		return SLOT_GLYPH_WEAPON
	var texture := load(path) as Texture2D
	return texture if texture != null else SLOT_GLYPH_WEAPON


## CONTRACTS section 11 / 09 section 11: a cell is selectable when it belongs to a rack
## whose **ordinal** the input map can reach (`GROUPS_MAX`, 7 since S5), whatever the
## producer said. A cell with no rack - an empty cell - has no battery to select.
func _weapon_cell_selectable(index: int, cell: Dictionary) -> bool:
	var battery := _cell_battery(index)
	return battery >= 1 and battery <= GROUPS_MAX and bool(cell.get(&"selectable", true))


## The rack ordinal (1-based) one pushed W cell fires from, 0 for a cell the producer
## gave no battery (an unfitted cell, or a producer that predates S5 and pushed no
## `battery` field - which falls back to the cell index + 1, the pre-S5 mapping).
func _cell_battery(index: int) -> int:
	if index < 0 or index >= _hull_slots.size():
		return 0
	var cell: Dictionary = _hull_slots[index]
	if cell.has(&"battery"):
		return int(cell[&"battery"])
	return index + 1


## The **barrel position** one pushed W cell reads its ammo at (`game.gd:_hull_slot_cells`'
## `position`, the cell's own index in `PlayerState.ammo`), `-1` for a cell the fit leaves
## empty. A producer that predates S5 pushes no `position` field and falls back to the cell
## index, which is the same number as the pre-S5 one-family-per-index mapping `_cell_battery`
## falls back to - so an old payload reads exactly as it always did.
func _cell_position(index: int) -> int:
	if index < 0 or index >= _hull_slots.size():
		return index
	var cell: Dictionary = _hull_slots[index]
	if cell.has(&"position"):
		return int(cell[&"position"])
	return index


## The barrel position a **rack ordinal** reads from when only the ordinal is known - the
## keyboard `weapon_N` path (`game.gd:_select_weapon`), which names no cell: the rack's
## first cell in layout order. That is the same "first member" rule the component's
## `selected_weapon()` reads (its first barrel's family - a rack's cells ascend, so the two
## name one member). A rack no pushed cell claims falls back to `battery - 1`, the pre-S5
## mapping an empty grid has always had.
func _barrel_of_battery(battery: int) -> int:
	for index: int in _hull_slots.size():
		if _cell_battery(index) == battery:
			return _cell_position(index)
	return battery - 1


## The firing family a rack ordinal's first cell carries, `&""` when no pushed cell claims
## the rack (the caller then keeps its own fallback). `_barrel_of_battery` answers that same
## first cell, so the caption and the pack the readout shows name one weapon.
func _battery_family(battery: int) -> StringName:
	for index: int in _hull_slots.size():
		if _cell_battery(index) != battery:
			continue
		var module := StringName(_hull_slots[index].get(&"module", &""))
		return WeaponComponent.weapon_id(module)
	return &""


## Point the readout's ammo figures at one **barrel position** (`_ammo_of`'s index). The
## selection's ordinal is not that index since S5, so both selection paths set them apart.
func _set_barrel(barrel: int) -> void:
	_active_barrel = barrel
	_ammo = _ammo_of(barrel)
	_ammo_max = _ammo_max_of(barrel)


## Section 3.1b: the Energy and Fuel blocks, appended to the scene's TopLeft column
## below ShieldBlock, plus the Emergency Flight banner that sits above them. The
## blocks are built here rather than in `hud.tscn` because the scene was not in that
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
	## UI_SPEC section 3.1b's 2026-09-24 amendment: the two blocks are built (the frozen
	## API keeps a widget behind it and the reversal is an unhide) and then retired from
	## the flight HUD; the banner above them stays.
	_retire_pool_blocks()
	_apply_emergency()
	_refresh_pools()


## UI_SPEC section 3.1b's 2026-09-24 amendment: the Energy and Fuel `ProgressBar` blocks and
## their labels leave the flight HUD - the cluster's FUEL/ENRG value dials are the pool
## readouts now, fed by `set_pool`. The `EMERGENCY FLIGHT` banner stays in the TopLeft column
## where the blocks were. The blocks stay in the scene, hidden and unrefreshed by the pool
## feed, so the section 7 API keeps a widget behind it and the amendment's own reversal is an
## unhide. Reversal: unhide the two blocks and reintroduce the bar refresh in `set_pool`.
func _retire_pool_blocks() -> void:
	for block: Control in retired_pool_blocks():
		block.visible = false


## The two retired pool blocks, in `POOL_KIND_*` order, so a probe can assert their absence
## without reaching into scene paths. Deliberately kept out of `retired_widgets()`: that list
## is section 3.7's 2026-09-24 old-column retirement, a separate amendment, and the two
## retirements answer separately.
func retired_pool_blocks() -> Array[Control]:
	var out: Array[Control] = []
	for kind: StringName in [POOL_KIND_ENERGY, POOL_KIND_FUEL]:
		var block: Control = _pool_blocks.get(kind, null)
		if block != null:
			out.append(block)
	return out


## One pool block: a header row (title, spacer, current/max readout) over a bar row. It is
## registered for the kind guard and handed to `_retire_pool_blocks` (UI_SPEC section 3.1b's
## 2026-09-24 amendment), which hides it right after the build. Every node ignores the mouse,
## as the scene's HUD nodes do, so the flight view keeps the clicks that set a move target.
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
	_pool_blocks[kind] = block
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
		cell.ignore_texture_size = true
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


## UI_SPEC section 3.7 (2026-09-24, owner: "all of old HUD should be gone i think"): the old
## HUD column dies - the section 3.1 crest bars (the TopLeft HULL/SHIELD blocks), the
## section 3.2 `AmmoPanel` (with its weapon grid) and the section 3.4 cargo block (panel plus
## toggle) leave the flight HUD. HULL/SHLD read in the cluster's rows, ammo in its AMMO row.
##
## The widgets stay **in the scene**, hidden and no-op, rather than being deleted: section 3.7
## keeps "the section 7 frozen API ... callable - every frozen method keeps its signature; the
## widgets they drove are gone (hidden/no-op widgets where nothing remains to drive)". The
## pool blocks (section 3.1b) are **not** retired - section 3.7's list names section 3.1's
## crest bars only, and section 3.1b's own rows stay green.
## Reversal: unhide the five nodes (restore the column behind a debug flag).
func _retire_old_column() -> void:
	for widget: Control in retired_widgets():
		widget.visible = false


## The retired old-HUD widgets, in the order section 3.7 lists the families, so a probe can
## assert the absence without reaching into scene paths.
func retired_widgets() -> Array[Control]:
	var out: Array[Control] = []
	for widget: Control in [_hull_block, _shield_block, _ammo_panel, _cargo_toggle, _cargo_panel]:
		if widget != null:
			out.append(widget)
	return out


func _on_hull_changed(current: float, maximum: float) -> void:
	_hull_current = maxf(current, 0.0)
	_hull_max = maxf(maximum, 0.0)
	if _cockpit != null:
		_cockpit.set_hull(_hull_current, _hull_max)
	_push_status()
	_refresh_hull()


func _on_shield_changed(current: float, maximum: float) -> void:
	_shield_current = maxf(current, 0.0)
	_shield_max = maxf(maximum, 0.0)
	if _cockpit != null:
		_cockpit.set_shield(_shield_current, _shield_max)
	_push_status()
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
	## Every cell of the **selected rack** is marked active (09 section 11): the
	## selection is a battery ordinal, so a rack that holds three cells lights all
	## three rather than the one whose index happens to equal the ordinal.
	for index: int in _weapon_slots.size():
		var active: bool = _cell_battery(index) == _active_slot + 1
		_weapon_slots[index].set_active(active)
		_weapon_slots[index].set_icon_token(TOKEN_TEXT_PRIMARY if active else TOKEN_TEXT_DIM)
	## The same selection powers the cluster's own instruments (UI_SPEC section 3.7 Mockup v5
	## delta 2): the battery lamps' lit lamp is the rack ordinal, and the AMMO row carries the
	## same `_ammo` figure the retired panel's readout showed.
	if _cockpit != null:
		_cockpit.set_active_rack(_active_slot + 1)
		_cockpit.set_ammo(_ammo)


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
## flips. The two pool blocks it used to sit above are retired (section 3.1b's
## 2026-09-24 amendment), so the banner is the only widget this flag drives.
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
		var distance := DISTANCE_FORMAT % _format_int(int(round(_target_info_distance_m)))
		## Section 10's range state prints with the distance it qualifies, and only when
		## the caller sent one.
		if _target_info_has_range:
			distance = RANGE_FORMAT % [
				distance, RANGE_IN if _target_info_in_range else RANGE_OUT
			]
		_target_distance_label.text = distance
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


## A W-slot press addresses the **battery ordinal** the pressed cell fires from (09
## section 11, CONTRACTS section 17): one rack may hold several cells and several kinds,
## so the cell index is not the group. The readout keeps showing the pressed cell's own
## module and its own pack (that is what the player clicked), while the signal and the
## highlight carry the rack. A cell with no rack - an unfitted one - selects nothing and
## emits nothing.
func _on_weapon_slot_pressed(index: int) -> void:
	var battery := _cell_battery(index)
	if battery < 1:
		return
	select_battery(battery)
	## The signal is the flight scene's own selection (`game.gd:_select_weapon` ->
	## `select_battery`), so it is emitted **before** the cell's own reading is applied:
	## the round trip re-selects the rack, and this press then narrows the readout to the
	## very cell the player pressed - its module's label and its own pack - rather than
	## the rack representative `select_battery` resolves. A mixed rack is exactly where
	## the two differ.
	weapon_slot_selected.emit(battery)
	_set_barrel(_cell_position(index))
	var module := StringName(_hull_slots[index].get(&"module", &""))
	var family := WeaponComponent.weapon_id(module)
	if family != &"":
		_weapon_id = family
	_refresh_weapon()


## Select one **rack ordinal** (1-based) for the readout: the highlight, the label and
## the ammo figures follow the rack, exactly as a press of one of its cells does. The
## flight scene calls this on a keyboard `weapon_N` press (`game.gd:_select_weapon`),
## so the two selection paths cannot disagree. An ordinal outside `1..GROUPS_MAX` is
## ignored, and every cell of the selected rack is marked active (not just one index).
##
## The ordinal names a **rack**, never a family index: a mixed rack's caption and pack
## are read off the rack's own first cell (`_battery_family` / `_barrel_of_battery`), so
## `weapon_1` on a cannon+rocket rack names the cannon and shows the cannon's rounds
## rather than whichever family sits at index 0 (the S5 review's R1-MED-1).
func select_battery(battery: int) -> void:
	if battery < 1 or battery > GROUPS_MAX:
		return
	_active_slot = battery - 1
	_set_barrel(_barrel_of_battery(battery))
	_weapon_id = _battery_family(battery)
	if _weapon_id.is_empty():
		_weapon_id = WEAPON_IDS[_active_slot] if _active_slot < WEAPON_IDS.size() else &""
	_refresh_weapon()


func _on_cargo_toggle_pressed() -> void:
	_set_cargo_open(not _cargo_open)


func _on_cargo_close_pressed() -> void:
	_set_cargo_open(false)


## The section 3.4 cargo block retired with section 3.7's 2026-09-24 amendment, so the panel
## stays hidden whatever the toggle asks for (cargo reads on the section 3.8 status screen).
## The frozen setter still latches the flag and still emits `cargo_toggled`, so `game.gd`'s
## own `_cargo_open` mirror stays in step and the key keeps working.
func _set_cargo_open(open: bool) -> void:
	if _cargo_open == open:
		return
	_cargo_open = open
	if _cargo_panel != null:
		_cargo_panel.visible = false
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


## --- Slice 2's widgets -------------------------------------------------------------
##
## Each widget is its own inner class and self-contained: it reads its tokens off the
## theme itself (an inner class cannot see the enclosing class's constants, the same
## limitation `weapons.gd`'s `ChaffGhost` documents), so the Hud only builds, positions and
## drives them.


## UI_SPEC section 3.5: the lock channel's ring - a thin arc drawn clockwise from the top
## as the channel runs, in the running colour, and left complete in `metal_light` while the
## lock holds. A child of the reticle, so it needs no position of its own.
class LockRing extends Control:
	const TOKENS_TYPE: StringName = &"Tokens"
	const WIDTH := 1.0

	var progress: float = 0.0
	var complete: bool = false

	var _running: Color = Color.WHITE
	var _done: Color = Color.WHITE

	func apply_theme() -> void:
		## The spec's running colour is "Steel Highlight #565C63", which no theme token
		## carries (and `accent_nav` is the HUD's single sanctioned literal), so the running
		## arc takes the nearest existing steel and the completed arc takes `metal_light`,
		## exactly as UI_SPEC section 3.5 writes it.
		_running = _token(&"text_dim")
		_done = _token(&"metal_light")
		queue_redraw()

	func stroke() -> float:
		return WIDTH

	func _draw() -> void:
		if progress <= 0.0 or size.x <= 0.0 or size.y <= 0.0:
			return
		var centre: Vector2 = size * 0.5
		## The bracket box's inscribed circle, less half the stroke, so the ring hugs the
		## brackets: the reticle insets its own brackets by half a stroke, and this reads
		## the same geometry instead of inventing a radius.
		var radius: float = minf(size.x, size.y) * 0.5 - WIDTH * 0.5
		if radius <= 0.0:
			return
		var start := -PI * 0.5
		draw_arc(
			centre,
			radius,
			start,
			start + TAU * clampf(progress, 0.0, 1.0),
			64,
			_done if complete else _running,
			WIDTH,
			true
		)

	func _token(token: StringName) -> Color:
		if has_theme_color(token, TOKENS_TYPE):
			return get_theme_color(token, TOKENS_TYPE)
		return Color.WHITE


## §4.2 item 4's marker: a small cross drawn over the reticle's centre, flashed by a Tween
## on its own modulate (the house rule: no per-frame UI animation).
class HitMarker extends Control:
	const TOKENS_TYPE: StringName = &"Tokens"
	const ARM := 4.0
	const SECONDS := 0.25
	const WIDTH := 1.0

	var _colour: Color = Color.WHITE
	var _fade: Tween = null

	func apply_theme() -> void:
		_colour = _token(&"accent_danger_bright")
		queue_redraw()

	## One flash: full alpha, then a fade over `SECONDS`. Re-entrant, so a second hit during
	## a fade restarts it rather than queueing another.
	func flash() -> void:
		visible = true
		modulate.a = 1.0
		queue_redraw()
		if _fade != null and _fade.is_valid():
			_fade.kill()
		_fade = create_tween()
		_fade.tween_property(self, "modulate:a", 0.0, SECONDS)
		_fade.finished.connect(_on_faded)

	func fading() -> bool:
		return visible and modulate.a > 0.0

	func _on_faded() -> void:
		visible = false

	func _draw() -> void:
		var centre: Vector2 = size * 0.5
		draw_line(
			centre + Vector2(-ARM, -ARM), centre + Vector2(ARM, ARM), _colour, WIDTH
		)
		draw_line(
			centre + Vector2(-ARM, ARM), centre + Vector2(ARM, -ARM), _colour, WIDTH
		)

	func _token(token: StringName) -> Color:
		if has_theme_color(token, TOKENS_TYPE):
			return get_theme_color(token, TOKENS_TYPE)
		return Color.WHITE


## UI_SPEC section 3.6's radial dial: 10 segments across 270 degrees with the gap at the
## bottom, a `metal_mid` fill per segment, the topmost filled segment in `accent_danger`
## above 0.9 (the overdrive read) and a prograde needle in `accent_nav` at the velocity's own
## bearing. The velocity is a world-space vector and the dial draws its own angle - a world
## bearing and a screen bearing agree because both axes point the same way on screen.
## **The heading marker is retired** (section 3.6's 2026-09-24 amendment, wave D7: the dial
## must never read as a second compass); `set_reading` still takes the heading because the
## section 7 feed carries it, and nothing draws it.
class Speedometer extends Control:
	const TOKENS_TYPE: StringName = &"Tokens"
	const SEGMENTS := 10
	const SWEEP := PI * 1.5
	const OVERDRIVE := 0.9
	const NEEDLE_LENGTH := 10.0
	const WIDTH := 1.0
	## The fill's stroke thickness: the one render detail UI_SPEC section 3.6 does not state
	## (it is a line weight, not a gameplay value), onetenth of the dial's own short side.
	const THICKNESS_RATIO := 0.05
	## UI_SPEC section 1's `accent_nav` (2026-09-20): the HUD's single sanctioned cyan and
	## the one hex literal it may hold, because the shipped `ui/theme/vajb_theme.tres` (out
	## of this worker's file set) does not carry the token yet. The theme wins when it lands.
	const TOKEN_NAV: StringName = &"accent_nav"
	const NAV_FALLBACK := Color("#6fb8c4")
	## UI_SPEC section 3.7 / UI_CHROME section 11: the painted dial face and needle sit under
	## the code-drawn marks. Both masters are 2x their logical box (face 240 -> 120, needle
	## 16 x 192 -> 8 x 96) and Godot scales from the one master, so the draw rect is logical.
	## The two paths are the D6 defaults; `set_surface_paths` lets the D7 `CockpitStyle`
	## supply its own (section 3.9 rule 5) and falls back to these when it cannot.
	const FACE_TEXTURE: Texture2D = preload("res://assets/ui/ui_gauge_face.png")
	const NEEDLE_TEXTURE: Texture2D = preload("res://assets/ui/ui_gauge_needle.png")
	const NEEDLE_SIZE := Vector2(8.0, 96.0)
	## UI_SPEC section 3.7: in overdrive the painted needle is tinted `accent_danger_bright`
	## by modulate (the code-drawn prograde needle keeps its `accent_nav` token).
	const TOKEN_NEEDLE_OVERDRIVE: StringName = &"accent_danger_bright"

	var ratio: float = 0.0
	var prograde: Vector2 = Vector2.ZERO

	var _face: Texture2D = FACE_TEXTURE
	var _needle_texture: Texture2D = NEEDLE_TEXTURE
	var _fill: Color = Color.WHITE
	var _overdrive: Color = Color.WHITE
	var _needle: Color = Color.WHITE
	var _needle_overdrive: Color = Color.WHITE

	## UI_SPEC section 3.9 rule 5: the painted surface paths come from the cockpit style, so a
	## user `.tres` can re-skin the dial. A path that does not resolve keeps the D6 preload.
	func set_surface_paths(face_path: String, needle_path: String) -> void:
		var face: Texture2D = _texture_at(face_path)
		var needle_cut: Texture2D = _texture_at(needle_path)
		_face = face if face != null else FACE_TEXTURE
		_needle_texture = needle_cut if needle_cut != null else NEEDLE_TEXTURE
		queue_redraw()

	func _texture_at(path: String) -> Texture2D:
		if path.is_empty() or not ResourceLoader.exists(path):
			return null
		return load(path) as Texture2D

	func apply_theme() -> void:
		_fill = _token(&"metal_mid")
		_overdrive = _token(&"accent_danger")
		_needle = _token_or(TOKEN_NAV, NAV_FALLBACK)
		_needle_overdrive = _token(TOKEN_NEEDLE_OVERDRIVE)
		queue_redraw()

	## The dial's readings, one call per frame in flight. The heading leg is accepted and
	## ignored: the marker retired with section 3.6's 2026-09-24 amendment.
	func set_reading(speed_ratio: float, prograde_vector: Vector2, _heading_vector: Vector2) -> void:
		var wanted := clampf(speed_ratio, 0.0, 1.0)
		## The needle moves every frame in flight; the guard is for a docked or idling hull,
		## where the dial is redrawn only when one of the two live readings actually moved.
		if (
			is_equal_approx(wanted, ratio)
			and is_equal_approx(prograde_vector.angle(), prograde.angle())
		):
			return
		ratio = wanted
		prograde = prograde_vector
		queue_redraw()

	## The segments the dial fills at its current ratio, UI_SPEC section 3.6's own rule
	## ("segment i filled when `speed_ratio >= i/10`"), and the topmost of them - the one the
	## overdrive read colours.
	func filled_segments() -> int:
		var count := 0
		for index in SEGMENTS:
			if ratio >= float(index) / float(SEGMENTS):
				count += 1
		return count

	func overdrive_segment() -> int:
		if ratio <= OVERDRIVE:
			return -1
		return maxi(filled_segments() - 1, 0)

	func needle_colour() -> Color:
		return _needle

	func _draw() -> void:
		var centre: Vector2 = size * 0.5
		_draw_surfaces(centre)
		var thickness: float = minf(size.x, size.y) * THICKNESS_RATIO
		var radius: float = minf(size.x, size.y) * 0.5 - thickness
		if radius <= 0.0:
			return
		## UI_SPEC section 3.6: the dial sweeps 270 degrees clockwise and leaves the gap at
		## the bottom (screen coordinates, +Y down), which is a start of 135 degrees.
		var start := PI * 0.75
		var step := SWEEP / float(SEGMENTS)
		var filled := filled_segments()
		var overdrive := overdrive_segment()
		for index in SEGMENTS:
			if index >= filled:
				continue
			draw_arc(
				centre,
				radius,
				start + step * index,
				start + step * (index + 1),
				8,
				_overdrive if index == overdrive else _fill,
				thickness,
				true
			)
		if not prograde.is_zero_approx():
			draw_line(
				centre,
				centre + Vector2.RIGHT.rotated(prograde.angle()) * NEEDLE_LENGTH,
				_needle,
				WIDTH
			)

	## UI_SPEC section 3.7: the painted surface under the marks. The face fills the 120 x 120
	## box; the needle hangs from its own base at the centre, rotated to the prograde bearing
	## and tinted `accent_danger_bright` only in overdrive. The code-drawn segment fill and
	## prograde needle are painted after this, so they stay on top; the heading tick retired
	## with section 3.6's 2026-09-24 amendment.
	func _draw_surfaces(centre: Vector2) -> void:
		draw_texture_rect(_face, Rect2(Vector2.ZERO, size), false)
		if prograde.is_zero_approx():
			return
		var tint: Color = _needle_overdrive if ratio > OVERDRIVE else Color.WHITE
		draw_set_transform(centre, prograde.angle() + PI * 0.5, Vector2.ONE)
		draw_texture_rect(
			_needle_texture,
			Rect2(Vector2(-NEEDLE_SIZE.x * 0.5, -NEEDLE_SIZE.y), NEEDLE_SIZE),
			false,
			tint
		)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _token(token: StringName) -> Color:
		if has_theme_color(token, TOKENS_TYPE):
			return get_theme_color(token, TOKENS_TYPE)
		return Color.WHITE

	func _token_or(token: StringName, fallback: Color) -> Color:
		if has_theme_color(token, TOKENS_TYPE):
			return get_theme_color(token, TOKENS_TYPE)
		return fallback
