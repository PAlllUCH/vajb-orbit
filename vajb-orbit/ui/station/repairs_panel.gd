extends VBoxContainer
## REPAIRS module panel: the damage report, the fee line and the single-press repair
## control. Contract: docs/design/STATION_HUB.md sections 3.1, 5.6, 5.9, 12.3 and 12.4,
## docs/gameplay/01_economy_core.md sections 6 and 7.
##
## The station shell loads this scene into its host, so the panel never routes, never
## computes a fee and never writes the profile except through Repairs: it emits
## status_requested up and reads Repairs, StationCatalog and PlayerProfile down
## (STATION_HUB section 12.4). The FEE row prints Repairs.fee(profile, active_ship)
## verbatim (section 5.9); the panel owns no rate of its own.
##
## Panel contract with the shell:
##   signal status_requested(message: String, danger: bool)   write the footer strip
##   func refresh_profile(key: StringName) -> void             react to profile_changed
##   func focus_primary() -> void                              focus entry after a switch

const TOKENS_TYPE: StringName = &"Tokens"

const Catalog := preload("res://game/station_catalog.gd")
const RepairsService := preload("res://game/repairs.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"

signal status_requested(message: String, danger: bool)

const COL_VALUE := 220.0
const ROW_SEPARATION := 6
const CELL_SEPARATION := 12
const PULSE_MIN_ALPHA := 0.35
const PULSE_DOWN_SECONDS := 0.12
const PULSE_UP_SECONDS := 0.16

## The free area of the action column carries the active hull's side render, so the damaged
## state is visible next to the report that describes it. The render is contain-fit to this
## share of the frame's width (PREVIEW_FIT * width, aspect kept, height-clamped).
const PREVIEW_FIT := 0.70
const SIDE_SUFFIX := "_side.png"
const DAMAGED_SIDE_SUFFIX := "_damaged_side.png"

## STATION_HUB section 5.9 copy: the caption under the button is the control's standing
## note, the strip is the live state line and the success or refusal result.
const CAPTION_OPTIONAL := "OPTIONAL · A DAMAGED HULL LAUNCHES FROM THE LAUNCH DECK"
const CAPTION_NO_REPORT := "UNDOCK AND DOCK TO FILE A DAMAGE REPORT"
const NOT_REPORTED := "NOT REPORTED"
const NOMINAL := "ALL SYSTEMS NOMINAL"
const EXEMPT_HINT := "SHIELD TOP-UP · NO FEE"
const HINT_REPAIR := "REPAIR AVAILABLE · %s CR"
const HINT_NO_REPORT := "NO DAMAGE REPORT"
const STATUS_REPAIRED := "REPAIRED · %s CR · ALL SYSTEMS NOMINAL"
const REFUSAL_INSUFFICIENT := "REFUSED · NOT ENOUGH CREDITS · %s NEEDED"
const TAG_ACTIVE := "ACTIVE %s"
const UNKNOWN_HULL := "NO HULL"

## Section 5.9 fixes the shape of these rows as `"200 / 1000"` and
## `"800 HULL · 300 SHIELD"`, so the report prints plain digits: the grouped formatter
## the credits and price columns use would render the 1000 hull as `"1 000"`.
const VALUE_FORMAT := "%s / %s"
const MISSING_FORMAT := "%s HULL · %s SHIELD"
const FEE_FORMAT := "%s CR"

## The pane footer states the fee schedule, so it is built from the module's own rates
## instead of carrying copy that can drift away from Repairs.fee.
const FOOTER_FORMAT := "FEE · 1 CR PER %d MISSING HULL · 1 CR PER %d MISSING SHIELD"

const REPORT_ROWS: Array[Dictionary] = [
	{&"key": &"hull_name", &"label": "ACTIVE HULL"},
	{&"key": &"hull", &"label": "HULL"},
	{&"key": &"shield", &"label": "SHIELD"},
	{&"key": &"missing", &"label": "MISSING"},
	{&"key": &"fee", &"label": "FEE"},
]

@onready var _tag: Label = %PanelTag
@onready var _rows: VBoxContainer = %ReportRows
@onready var _hull_center: CenterContainer = %HullCenter
@onready var _hull_image: TextureRect = %HullImage
@onready var _button: Button = %RepairButton
@onready var _strip: Label = %RepairStrip
@onready var _caption: Label = %RepairCaption
@onready var _footer: Label = %PaneFooter

var _values: Dictionary = {}
var _fee_danger := false
var _strip_danger := false
var _native_preview := Vector2.ZERO
var _tweens: Array[Tween] = []


func _ready() -> void:
	_build_report_rows()
	_build_footer()
	_apply_tokens()
	_hull_center.resized.connect(_update_preview_size)
	_button.pressed.connect(_on_repair_pressed)
	_button.focus_entered.connect(_on_repair_focused)
	_refresh_all()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_apply_tokens()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and is_node_ready() and is_visible_in_tree():
		## The module switch is the other entry point: a vitals write is silent by
		## contract (17 section 3), so every entry re-reads the active ship and its
		## report instead of trusting what the last rebuild left behind.
		_refresh_all()


func _exit_tree() -> void:
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()


func refresh_profile(key: StringName) -> void:
	## STATION_HUB section 12.4: &"credits" moves the fee colour, &"ships" moves the
	## active hull with its maxima and the whole damage report.
	if key == &"credits" or key == &"ships":
		_refresh_all()


func focus_primary() -> void:
	## The report rows are labels, so the button is the pane's only focusable entry.
	## While it is disabled nothing inside takes the ring and the shell falls back to the
	## rail entry (station.gd:401-410); a disabled Button refuses grab_focus anyway.
	if not _button.disabled:
		_button.grab_focus()


func _apply_tokens() -> void:
	_apply_fee_colour()
	_apply_strip_colour()


func _token(token: StringName) -> Color:
	if has_theme_color(token, TOKENS_TYPE):
		return get_theme_color(token, TOKENS_TYPE)
	return Color.WHITE


func _build_report_rows() -> void:
	_rows.add_theme_constant_override(&"separation", ROW_SEPARATION)
	for row: Dictionary in REPORT_ROWS:
		var line := HBoxContainer.new()
		line.name = "Report%s" % String(row[&"key"]).to_pascal_case()
		line.add_theme_constant_override(&"separation", CELL_SEPARATION)
		_rows.add_child(line)
		var caption := Label.new()
		caption.theme_type_variation = &"StationCaption"
		caption.text = String(row[&"label"])
		caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_child(caption)
		var value := Label.new()
		value.name = "Value"
		value.theme_type_variation = &"StationValue"
		value.custom_minimum_size = Vector2(COL_VALUE, 0.0)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_child(value)
		_values[row[&"key"]] = value


func _refresh_all() -> void:
	var profile := _profile()
	var active_id := _active_id(profile)
	var ship := Catalog.ship(active_id)
	var hull_name := _hull_name(ship, active_id)
	_tag.text = (TAG_ACTIVE % hull_name) if not ship.is_empty() else UNKNOWN_HULL
	var vitals := _vitals(profile, active_id)
	if vitals.is_empty():
		## No reported damage: the hull still gets its intact render.
		_refresh_preview(active_id, 0)
		_refresh_missing_report(hull_name)
		return
	var hull_max := int(ship.get(&"hull", 0))
	var shield_max := int(ship.get(&"shield", 0))
	var hull := int(vitals.get(&"hull", 0))
	_refresh_preview(active_id, maxi(0, hull_max - hull))
	var shield := int(vitals.get(&"shield", 0))
	var fee := RepairsService.fee(profile, active_id)
	var repairable := RepairsService.is_repairable(profile, active_id)
	_set_report(&"hull_name", hull_name)
	_set_report(&"hull", VALUE_FORMAT % [str(hull), str(hull_max)])
	_set_report(&"shield", VALUE_FORMAT % [str(shield), str(shield_max)])
	_set_report(&"missing", MISSING_FORMAT % [
		str(maxi(0, hull_max - hull)), str(maxi(0, shield_max - shield))
	])
	_set_report(&"fee", FEE_FORMAT % str(fee))
	_fee_danger = fee > 0 and profile != null and int(profile.call(&"credits")) < fee
	_apply_fee_colour()
	_button.disabled = not repairable
	_caption.text = CAPTION_OPTIONAL
	if not repairable:
		_set_strip(NOMINAL, false)
	elif fee == 0:
		_set_strip(EXEMPT_HINT, false)
	else:
		_set_strip(HINT_REPAIR % str(fee), false)


func _refresh_missing_report(hull_name: String) -> void:
	## No vitals record: the hull is still known from the catalogue, but nothing can be
	## said about its damage, its fee or its repairability (section 5.9).
	_set_report(&"hull_name", hull_name)
	for key: StringName in [&"hull", &"shield", &"missing", &"fee"]:
		_set_report(key, NOT_REPORTED)
	_fee_danger = false
	_apply_fee_colour()
	_button.disabled = true
	_caption.text = CAPTION_NO_REPORT
	_set_strip(HINT_NO_REPORT, false)


func _set_report(key: StringName, text: String) -> void:
	var label: Label = _values.get(key)
	if label != null:
		label.text = text


## Section 5.9's footer caption, always the live fee schedule: the page and the service
## cannot disagree because both read Repairs.
func _build_footer() -> void:
	_footer.text = FOOTER_FORMAT % [
		RepairsService.HULL_CR_PER_POINTS,
		RepairsService.SHIELD_CR_PER_POINTS,
	]


func _apply_fee_colour() -> void:
	var label: Label = _values.get(&"fee")
	if label == null:
		return
	if _fee_danger:
		label.add_theme_color_override(&"font_color", _token(&"accent_danger"))
		return
	label.remove_theme_color_override(&"font_color")


func _set_strip(message: String, danger: bool) -> void:
	_strip.text = message
	_strip_danger = danger
	_apply_strip_colour()


func _apply_strip_colour() -> void:
	var token: StringName = &"accent_danger" if _strip_danger else &"text_primary"
	_strip.add_theme_color_override(&"font_color", _token(token))


func _on_repair_focused() -> void:
	AudioManager.play_ui(AudioManager.UiCue.HOVER)
	status_requested.emit(_strip.text, _strip_danger)


func _on_repair_pressed() -> void:
	AudioManager.play_ui(AudioManager.UiCue.CLICK)
	var profile := _profile()
	if profile == null:
		return
	var active_id := _active_id(profile)
	var result: Dictionary = RepairsService.repair(profile, active_id)
	## The repair moves credits (emitted) and vitals (silent, 17 section 3), so the report
	## is rebuilt here, before the result line is written over the idle hint.
	_refresh_all()
	if bool(result.get(&"ok", false)):
		AudioManager.play_ui(AudioManager.UiCue.CONFIRM)
		_set_strip(STATUS_REPAIRED % str(int(result.get(&"fee", 0))), false)
		status_requested.emit(_strip.text, false)
		return
	var reason: StringName = result.get(&"reason", &"")
	AudioManager.play_ui(AudioManager.UiCue.DENIED)
	_pulse(_values.get(&"fee"))
	if reason == RepairsService.REASON_NO_DAMAGE:
		_caption.text = NOMINAL
		_set_strip(NOMINAL, false)
	elif reason == RepairsService.REASON_NO_DAMAGE_REPORT:
		_caption.text = CAPTION_NO_REPORT
		_set_strip(HINT_NO_REPORT, false)
	else:
		var fee := RepairsService.fee(profile, active_id)
		_set_strip(REFUSAL_INSUFFICIENT % str(fee), true)
	status_requested.emit(_strip.text, _strip_danger)


## The active hull's side render, resolved the way shipyard_panel.gd resolves its preview
## (the catalogue's `preview` key) rather than restating a path here. A hull with missing
## points shows the damaged cut when one exists on disk; an unreported or repaired hull, an
## unknown hull and a hull with no damaged cut all keep the intact render.
static func hull_render(ship_id: StringName, missing_hull: int) -> String:
	var preview := String(Catalog.ship(ship_id).get(&"preview", ""))
	if preview.is_empty() or missing_hull <= 0:
		return preview
	var damaged := preview.replace(SIDE_SUFFIX, DAMAGED_SIDE_SUFFIX)
	return damaged if ResourceLoader.exists(damaged) else preview


func _refresh_preview(ship_id: StringName, missing_hull: int) -> void:
	var path := hull_render(ship_id, missing_hull)
	var texture: Texture2D = null
	if not path.is_empty():
		texture = load(path) as Texture2D
	_hull_image.texture = texture
	_native_preview = texture.get_size() if texture != null else Vector2.ZERO
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


func _hull_name(ship: Dictionary, active_id: StringName) -> String:
	var name_text := String(ship.get(&"name", String(active_id)))
	return name_text.to_upper() if not name_text.is_empty() else UNKNOWN_HULL


func _active_id(profile: ProfileScript) -> StringName:
	if profile == null:
		return &""
	return StringName(profile.call(&"active_ship"))


func _vitals(profile: ProfileScript, ship_id: StringName) -> Dictionary:
	if profile == null or ship_id == &"":
		return {}
	var raw: Variant = profile.call(&"vitals_of", ship_id)
	return raw if raw is Dictionary else {}


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


func _pulse(node: CanvasItem) -> void:
	if node == null:
		return
	var tween := _make_tween()
	tween.tween_property(node, "modulate:a", PULSE_MIN_ALPHA, PULSE_DOWN_SECONDS).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "modulate:a", 1.0, PULSE_UP_SECONDS).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "modulate:a", PULSE_MIN_ALPHA, PULSE_DOWN_SECONDS).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "modulate:a", 1.0, PULSE_UP_SECONDS).set_trans(Tween.TRANS_SINE)


func _make_tween() -> Tween:
	for index in range(_tweens.size() - 1, -1, -1):
		if not _tweens[index].is_valid():
			_tweens.remove_at(index)
	var tween := create_tween()
	_tweens.append(tween)
	return tween
