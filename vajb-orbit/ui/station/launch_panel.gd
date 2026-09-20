extends VBoxContainer
## LAUNCH module panel: the flight briefing, the cargo plate strip, the manifest read from
## PlayerProfile.cargo_items(), and the two-press arming beat that ends in the undock
## intent. Contract: docs/design/STATION_HUB.md sections 2, 5.4, 5.6, 9 and 12,
## docs/design/STATION_SPEC.md sections 2.3, 2.6 and 6, docs/design/IMPLEMENTATION_PLAN.md
## section 9.2.
##
## The station shell loads this scene into its host, so the panel never routes and never
## writes the profile: it emits launch_requested up, reads StationCatalog / PlayerProfile
## down, and leaves the boost and jump cues and the fade to the shell and the Router
## (STATION_HUB sections 2 and 12.4).
##
## Panel contract with the shell:
##   signal status_requested(message: String, danger: bool)   write the footer strip
##   signal launch_requested()                                undock
##   func refresh_profile(key: StringName) -> void             react to profile_changed
##   func focus_primary() -> void                              focus entry after a switch
##   func disarm() -> bool                                     ui_cancel step 2

const TOKENS_TYPE: StringName = &"Tokens"

const Paths := preload("res://ui/paths.gd")
const Catalog := preload("res://game/station_catalog.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"

signal status_requested(message: String, danger: bool)
signal launch_requested()

const ROUTE_LOADING: StringName = &"loading"
const DESTINATION_ROUTE: StringName = &"game"

## Route id -> the line the briefing prints for it. Which ids exist is the route table's
## (ui/paths.gd ROUTES); this table owns only the wording, and a route it does not name
## degrades to its own upper-cased id instead of a blank row. A destination the route table
## does not hold cannot be handed to the loading bridge, so the row says so, and the panel
## still arms because the failure belongs to routing and not to this screen (section 5.4).
const DESTINATION_LINES: Dictionary = {
	&"game": "OPEN SPACE · HELIOS DRIFT",
}
const DESTINATION_UNRESOLVED := "NO ROUTE IN THE TABLE"

const ARM_SECONDS := 3.0
const ARM_PULSE_MIN_ALPHA := 0.70
const ARM_PULSE_SECONDS := 0.16

const CARGO_PLATES := 5
const CARGO_PLATE_VARIATION: StringName = &"SlotButtonCargo"
const CARGO_PLATE_SIZE := 40.0
const CARGO_PLATE_SEPARATION := 6
const CARGO_ICON_SIZE := 24.0
const CARGO_ICON_INSET := 8.0
const CARGO_ICON_DIR := "res://assets/icons/tint/"
const CARGO_ICON_TEMPLATE := "icon_cargo_%s_48.png"
const CARGO_ICON_FALLBACK := "res://assets/icons/tint/icon_cargo_crate_48.png"

## The free area of the deck-control column carries the active hull's side render, with the
## readiness line under it (the same empty frame REPAIRS fills). Contain-fit to this share
## of the frame's width, aspect kept.
const PREVIEW_FIT := 0.70
const HULL_READY_FORMAT := "%s — READY"

const COL_BRIEF := 220.0
const BRIEF_SEPARATION := 12

const BRIEF_ROWS: Array[Dictionary] = [
	{&"key": &"destination", &"label": "DESTINATION"},
	{&"key": &"hull_name", &"label": "ACTIVE HULL"},
	{&"key": &"hull", &"label": "HULL LIMIT"},
	{&"key": &"shield", &"label": "SHIELD LIMIT"},
	{&"key": &"hardpoints", &"label": "HARDPOINTS"},
	{&"key": &"cargo", &"label": "CARGO"},
	{&"key": &"ammo", &"label": "AMMUNITION"},
]

const SUBTITLE := "UNDOCK AND RETURN TO OPEN SPACE · %s DESTINATION %s"
const TAG_FORMAT := "TWO PRESSES · %d s WINDOW"
const CARGO_CAPTION := "CARGO HOLD · %d STACKS"
const CARGO_FORMAT := "%d / %d"
const AMMO_FORMAT := "%s ROUNDS ACROSS %d WEAPONS"
const MANIFEST_FORMAT := "%s   %d"
const HOLD_EMPTY := "HOLD EMPTY"
const BRIEF_NOTE := (
	"CARGO ITEM NAMES AND GLYPHS ARE DERIVED FROM THE ITEM ID · "
	+ "NO SELL OR DEPOSIT FLOW IN V1"
)

const IDLE_TEXT := "PRESS LAUNCH TO ARM · A SECOND PRESS CONFIRMS WITHIN %d s"
const ARM_TEXT := "ARMED · PRESS LAUNCH AGAIN WITHIN %d s TO UNDOCK"
const EXPIRED_TEXT := "ARMING EXPIRED · PRESS LAUNCH TO ARM AGAIN"
const FIRED_TEXT := "LAUNCH CONFIRMED · HANDOFF TO THE %s · DESTINATION %s"

const SFX_ARM: StringName = &"sfx_station_breaker_on_01"
const STATUS_ARMED := "LAUNCH ARMED · PRESS AGAIN TO CONFIRM"
const STATUS_DISARMED := "LAUNCH DISARMED"
const STATUS_EXPIRED := "LAUNCH DISARMED · ARMING EXPIRED"
const STATUS_FIRED := "LAUNCH CONFIRMED · UNDOCKING"

@onready var _subtitle: Label = %PaneSubtitle
@onready var _tag: Label = %PanelTag
@onready var _brief_rows: VBoxContainer = %BriefRows
@onready var _cargo_caption: Label = %CargoCaption
@onready var _cargo_slots: HBoxContainer = %CargoSlots
@onready var _cargo_list: ItemList = %CargoList
@onready var _brief_note: Label = %BriefNote
@onready var _launch_button: Button = %LaunchButton
@onready var _confirm_strip: Label = %ConfirmStrip
@onready var _hull_center: CenterContainer = %HullCenter
@onready var _hull_image: TextureRect = %HullImage
@onready var _hull_caption: Label = %HullCaption

var _brief_values: Dictionary = {}
var _plates: Array[TextureButton] = []
var _plate_icons: Array[TextureRect] = []
var _arm_timer: Timer
var _armed := false
var _arm_tween: Tween = null
var _native_preview := Vector2.ZERO
var _tweens: Array[Tween] = []


func _ready() -> void:
	_build_brief_rows()
	_build_cargo_plates()
	_build_arm_timer()
	_subtitle.text = SUBTITLE % [_bridge_label(), String(destination_route()).to_upper()]
	_tag.text = TAG_FORMAT % int(ARM_SECONDS)
	_brief_note.text = BRIEF_NOTE
	_confirm_strip.text = _idle_text()
	_apply_tokens()
	_hull_center.resized.connect(_update_preview_size)
	_launch_button.pressed.connect(_on_launch_pressed)
	_launch_button.focus_entered.connect(_on_launch_focused)
	_refresh_all()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_apply_tokens()


func _exit_tree() -> void:
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()


func refresh_profile(key: StringName) -> void:
	## STATION_HUB section 12.4: &"cargo" rebuilds the manifest and the plate strip,
	## &"ships" moves the active hull and the limits, &"ammo" moves the ammunition line.
	if key == &"cargo" or key == &"ships":
		_refresh_cargo()
	if key == &"cargo" or key == &"ships" or key == &"ammo":
		_refresh_brief()


func focus_primary() -> void:
	_launch_button.grab_focus()


func disarm() -> bool:
	## ui_cancel step 2 (STATION_HUB section 2): the arming beat owns the first cancel.
	if not _armed:
		return false
	_clear_arm()
	_confirm_strip.text = _idle_text()
	status_requested.emit(STATUS_DISARMED, false)
	return true


func is_armed() -> bool:
	return _armed


func destination_route() -> StringName:
	## The destination is resolved through the route table, never printed as a literal.
	if Paths.route_exists(DESTINATION_ROUTE):
		return DESTINATION_ROUTE
	return &""


func destination_line() -> String:
	var route := destination_route()
	if route == &"":
		return DESTINATION_UNRESOLVED
	return String(DESTINATION_LINES.get(route, String(route).to_upper()))


func _apply_tokens() -> void:
	_refresh_plate_textures()
	if _armed:
		_launch_button.add_theme_color_override(&"font_color", _token(&"accent_danger_bright"))


func _token(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.WHITE


func _build_brief_rows() -> void:
	for row: Dictionary in BRIEF_ROWS:
		var line := HBoxContainer.new()
		line.name = "Brief%s" % String(row[&"key"]).to_pascal_case()
		line.add_theme_constant_override(&"separation", BRIEF_SEPARATION)
		_brief_rows.add_child(line)
		var caption := Label.new()
		caption.theme_type_variation = &"StationCaption"
		caption.text = String(row[&"label"])
		caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_child(caption)
		var value := Label.new()
		value.theme_type_variation = &"StationValue"
		value.custom_minimum_size = Vector2(COL_BRIEF, 0.0)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_child(value)
		_brief_values[row[&"key"]] = value


func _build_cargo_plates() -> void:
	_cargo_slots.add_theme_constant_override(&"separation", CARGO_PLATE_SEPARATION)
	for index in CARGO_PLATES:
		var plate := _make_plate(_cargo_slots, CARGO_PLATE_VARIATION, CARGO_PLATE_SIZE)
		plate.name = "CargoSlot%02d" % (index + 1)
		plate.disabled = true
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.custom_minimum_size = Vector2(CARGO_ICON_SIZE, CARGO_ICON_SIZE)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.visible = false
		plate.add_child(icon)
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = CARGO_ICON_INSET
		icon.offset_top = CARGO_ICON_INSET
		icon.offset_right = -CARGO_ICON_INSET
		icon.offset_bottom = -CARGO_ICON_INSET
		_plates.append(plate)
		_plate_icons.append(icon)


func _make_plate(parent: HBoxContainer, variation: StringName, size: float) -> TextureButton:
	# ui/components/slot_button.gd copies the theme plate textures onto the node, because a
	# TextureButton has no stylebox items, so SlotButtonCargo/styles/* is never read by the
	# engine on a bare theme_type_variation. The panel repeats that lookup (the mockup's own
	# construct) so the strip also renders without instancing the HUD component.
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
	for plate: TextureButton in _plates:
		_apply_plate_textures(plate)


func _build_arm_timer() -> void:
	_arm_timer = Timer.new()
	_arm_timer.name = &"ArmTimer"
	_arm_timer.one_shot = true
	_arm_timer.wait_time = ARM_SECONDS
	_arm_timer.timeout.connect(_on_arm_timeout)
	add_child(_arm_timer)


func _refresh_all() -> void:
	_refresh_brief()
	_refresh_cargo()


func _refresh_brief() -> void:
	var profile := _profile()
	var active_id := _active_id(profile)
	var ship := Catalog.ship(active_id)
	var hull_name := String(ship.get(&"name", String(active_id))).to_upper()
	_refresh_preview(active_id, hull_name)
	_set_brief(&"destination", destination_line())
	_set_brief(&"hull_name", hull_name)
	_set_brief(&"hull", str(int(ship.get(&"hull", 0))))
	_set_brief(&"shield", str(int(ship.get(&"shield", 0))))
	_set_brief(&"hardpoints", str(int(ship.get(&"hardpoints", 0))))
	_set_brief(&"cargo", CARGO_FORMAT % [_cargo_used(profile), int(ship.get(&"cargo", 0))])
	_set_brief(&"ammo", AMMO_FORMAT % [_format_int(_ammo_total(profile)), _weapon_count()])


func _set_brief(key: StringName, text: String) -> void:
	var label: Label = _brief_values.get(key)
	if label != null:
		label.text = text


func _refresh_cargo() -> void:
	var items := _cargo_items()
	_cargo_caption.text = CARGO_CAPTION % items.size()
	_refresh_plates(items)
	_refresh_manifest(items)


func _refresh_plates(items: Dictionary) -> void:
	var keys := items.keys()
	for index in _plates.size():
		var used := index < keys.size()
		var plate := _plates[index]
		var icon := _plate_icons[index]
		plate.disabled = not used
		icon.visible = used
		if used:
			icon.texture = load(_cargo_icon_path(keys[index])) as Texture2D
		else:
			icon.texture = null


func _refresh_manifest(items: Dictionary) -> void:
	_cargo_list.clear()
	var keys := items.keys()
	if keys.is_empty():
		_cargo_list.add_item(HOLD_EMPTY)
		_cargo_list.set_item_disabled(0, true)
		return
	for key: Variant in keys:
		var item_id := StringName(str(key))
		_cargo_list.add_item(MANIFEST_FORMAT % [_cargo_display_name(item_id), int(items[key])])
	_cargo_list.select(0)


func _cargo_display_name(item_id: StringName) -> String:
	## No item catalogue exists in v1: PlayerProfile counts ids and a mining/loot spec owns
	## the display data later, so the name comes from the id itself.
	return String(item_id).capitalize()


func _cargo_icon_path(item_id: StringName) -> String:
	## The catalogue the mockup stubbed does not exist, so the glyph is resolved against the
	## derived tint stencils on disk: the whole id first, then its leading token, then a
	## generic crate. Never a literal path per item.
	var id := String(item_id)
	for token: String in PackedStringArray([id, id.get_slice("_", 0)]):
		var candidate := CARGO_ICON_DIR + CARGO_ICON_TEMPLATE % token
		if ResourceLoader.exists(candidate):
			return candidate
	return CARGO_ICON_FALLBACK


func _cargo_items() -> Dictionary:
	var profile := _profile()
	if profile == null:
		return {}
	var raw: Variant = profile.call(&"cargo_items")
	return raw if raw is Dictionary else {}


func _cargo_used(profile: ProfileScript) -> int:
	if profile == null:
		return 0
	var raw: Variant = profile.call(&"cargo_items")
	if not raw is Dictionary:
		return 0
	var used := 0
	for key: Variant in (raw as Dictionary):
		used += int((raw as Dictionary)[key])
	return used


func _ammo_total(profile: ProfileScript) -> int:
	if profile == null:
		return 0
	var total := 0
	for pack: Dictionary in Catalog.AMMO_PACKS:
		total += int(profile.call(&"ammo_of", pack.get(&"id", &"")))
	return total


func _weapon_count() -> int:
	return Catalog.AMMO_PACKS.size()


## The active hull's side render, resolved the way shipyard_panel.gd resolves its preview
## (the catalogue's `preview` key) rather than restating a path here. LAUNCH shows the intact
## cut only: a hull launches as it is, and the damaged state belongs to the REPAIRS report.
static func hull_preview(ship_id: StringName) -> String:
	return String(Catalog.ship(ship_id).get(&"preview", ""))


func _refresh_preview(ship_id: StringName, hull_name: String) -> void:
	var path := hull_preview(ship_id)
	var texture: Texture2D = null
	if not path.is_empty():
		texture = load(path) as Texture2D
	_hull_image.texture = texture
	_native_preview = texture.get_size() if texture != null else Vector2.ZERO
	_hull_caption.text = (HULL_READY_FORMAT % hull_name) if not hull_name.is_empty() else ""
	_update_preview_size()


func _update_preview_size() -> void:
	## Contain-fit: PREVIEW_FIT of the frame's width, aspect kept, shrunk to the frame's
	## height when the column is short (the shipyard preview's own rule, measured against
	## this frame instead of a fixed maximum width).
	var box := _hull_center.size
	var target := Vector2.ZERO
	if _native_preview.x > 0.0 and box.x > 1.0:
		target = _native_preview * (box.x * PREVIEW_FIT / _native_preview.x)
		if box.y > 1.0 and target.y > box.y:
			target *= box.y / target.y
	if not _hull_image.custom_minimum_size.is_equal_approx(target):
		_hull_image.custom_minimum_size = target


func _active_id(profile: ProfileScript) -> StringName:
	if profile == null:
		return &""
	return StringName(profile.call(&"active_ship"))


func _idle_text() -> String:
	return IDLE_TEXT % int(ARM_SECONDS)


func _bridge_label() -> String:
	## The panel names the route it hands off to; the shell owns the actual
	## route_requested(&"loading", {destination: &"game"}) emit (section 12.4).
	return "%s BRIDGE" % String(ROUTE_LOADING).to_upper()


func _on_launch_focused() -> void:
	AudioManager.play_ui(AudioManager.UiCue.HOVER)


func _on_launch_pressed() -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	if _armed:
		_fire()
		return
	_arm()


func _arm() -> void:
	_armed = true
	AudioManager.play_sfx(SFX_ARM)
	_launch_button.add_theme_color_override(&"font_color", _token(&"accent_danger_bright"))
	_confirm_strip.text = ARM_TEXT % int(ARM_SECONDS)
	status_requested.emit(STATUS_ARMED, false)
	_arm_timer.start()
	_arm_tween = _make_tween()
	_arm_tween.tween_property(_launch_button, "modulate:a", ARM_PULSE_MIN_ALPHA, ARM_PULSE_SECONDS).set_trans(Tween.TRANS_SINE)
	_arm_tween.tween_property(_launch_button, "modulate:a", 1.0, ARM_PULSE_SECONDS).set_trans(Tween.TRANS_SINE)
	_arm_tween.tween_property(_launch_button, "modulate:a", ARM_PULSE_MIN_ALPHA, ARM_PULSE_SECONDS).set_trans(Tween.TRANS_SINE)
	_arm_tween.tween_property(_launch_button, "modulate:a", 1.0, ARM_PULSE_SECONDS).set_trans(Tween.TRANS_SINE)


func _fire() -> void:
	## Inside the window: the shell owns the boost and jump cues, the ambience stop and the
	## route; the panel only declares the intent (section 11 and the Screen contract).
	_clear_arm()
	_confirm_strip.text = FIRED_TEXT % [_bridge_label(), String(destination_route()).to_upper()]
	status_requested.emit(STATUS_FIRED, false)
	launch_requested.emit()


func _on_arm_timeout() -> void:
	_armed = false
	_launch_button.remove_theme_color_override(&"font_color")
	_launch_button.modulate.a = 1.0
	_confirm_strip.text = EXPIRED_TEXT
	status_requested.emit(STATUS_EXPIRED, false)


func _clear_arm() -> void:
	_armed = false
	_arm_timer.stop()
	if _arm_tween != null and _arm_tween.is_valid():
		_arm_tween.kill()
	_launch_button.modulate.a = 1.0
	_launch_button.remove_theme_color_override(&"font_color")


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
