extends CanvasLayer
## S13-B2 dev tuning overlay: the F1 panel that writes every `OreTuning` field
## live, saves the set to `user://dev_tuning.cfg` and resets it.
##
## Contract: S13_BRIEF.md section 2 rule 6. The overlay is a CanvasLayer
## toggled by the raw `KEY_F1` keycode in `_unhandled_key_input` - no
## `project.godot` edit and no InputMap action exist for it. It never pauses
## the game (`process_mode` is ALWAYS so F1 keeps working if the game pauses
## for another reason) and it touches no shipped UI file.
##
## The config file is read **only** when the overlay opens, never in `_ready`:
## the gate has to stay byte-identical on a store carrying the file, so a boot
## that does not open the panel must not see a single tuned value (AC4).
##
## `OreTuning` is the only source of the values: the overlay re-declares no
## default. The TUNED badge is measured against the defaults `OreTuning` itself
## produces, cross-checked by a snapshot/reset/restore dance around
## `reset_to_defaults()` so a tuned session cannot poison the yardstick.
##
## Reached by preload path only (the project convention: never the global class
## table - D11-C1's lesson), so instantiating works in a headless run.

const OreTuningScript := preload("res://game/ore_tuning.gd")

## The pinned dev config path (S13_BRIEF section 2 rule 6). A test may point
## `config_path` at its own scratch file, but production uses this one.
const CONFIG_PATH := "user://dev_tuning.cfg"
const CONFIG_SECTION := "ore_tuning"
const CONFIG_KEY := "values"

## The panel draws above the HUD and the station screens.
const LAYER_INDEX := 100

## Every slider, in panel order. `int` marks a whole-number field (a tier yield
## or a pickup burst axis); `min`/`max`/`step` are the pinned ranges from the
## brief. These are the control ranges, not balance values: the balance values
## live only in `OreTuning`.
const SLIDER_SPECS: Array[Dictionary] = [
	{
		&"key": &"gun_burst_share",
		&"label": "gun_burst_share",
		&"min": 0.0,
		&"max": 1.0,
		&"step": 0.01,
		&"int": false,
	},
	{
		&"key": &"fragment_core_share",
		&"label": "fragment_core_share",
		&"min": 0.0,
		&"max": 1.0,
		&"step": 0.01,
		&"int": false,
	},
	{
		&"key": &"gun_chip_rate",
		&"label": "gun_chip_rate",
		&"min": 0.0,
		&"max": 0.5,
		&"step": 0.005,
		&"int": false,
	},
	{
		&"key": &"mine_cycle",
		&"label": "mine_cycle",
		&"min": 0.2,
		&"max": 3.0,
		&"step": 0.05,
		&"int": false,
	},
	{
		&"key": &"work_per_unit",
		&"label": "work_per_unit",
		&"min": 0.25,
		&"max": 4.0,
		&"step": 0.05,
		&"int": false,
	},
	{
		&"key": &"tier_base_yield_1",
		&"label": "tier 1 yield",
		&"min": 1.0,
		&"max": 12.0,
		&"step": 1.0,
		&"int": true,
	},
	{
		&"key": &"tier_base_yield_2",
		&"label": "tier 2 yield",
		&"min": 1.0,
		&"max": 12.0,
		&"step": 1.0,
		&"int": true,
	},
	{
		&"key": &"tier_base_yield_3",
		&"label": "tier 3 yield",
		&"min": 1.0,
		&"max": 12.0,
		&"step": 1.0,
		&"int": true,
	},
	{
		&"key": &"tier_base_yield_4",
		&"label": "tier 4 yield",
		&"min": 1.0,
		&"max": 12.0,
		&"step": 1.0,
		&"int": true,
	},
	{
		&"key": &"yield_variance_min",
		&"label": "yield_variance_min",
		&"min": 0.0,
		&"max": 2.0,
		&"step": 0.01,
		&"int": false,
	},
	{
		&"key": &"yield_variance_max",
		&"label": "yield_variance_max",
		&"min": 0.0,
		&"max": 2.0,
		&"step": 0.01,
		&"int": false,
	},
	{
		&"key": &"pickup_burst_x",
		&"label": "pickup x",
		&"min": 0.0,
		&"max": 6.0,
		&"step": 1.0,
		&"int": true,
	},
	{
		&"key": &"pickup_burst_y",
		&"label": "pickup y",
		&"min": 0.0,
		&"max": 6.0,
		&"step": 1.0,
		&"int": true,
	},
]

## Defaults captured from `OreTuning` itself, so no published number is typed
## twice. Filled on first use (see `_defaults_snapshot`).
static var _defaults: Dictionary = {}

var config_path := CONFIG_PATH

var _panel: Control = null
var _badge: Label = null
var _status: Label = null
var _sliders: Dictionary = {}
var _value_labels: Dictionary = {}
var _syncing := false


func _ready() -> void:
	## Auto-enable key processing even if the engine's virtual detection misses
	## it, and stay live through a paused tree (the overlay never pauses it).
	set_process_unhandled_key_input(true)
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = LAYER_INDEX
	_build()
	_sync_sliders()
	visible = false


# ----- input -----------------------------------------------------------------


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode != KEY_F1 and key.physical_keycode != KEY_F1:
		return
	toggle()
	get_viewport().set_input_as_handled()


# ----- open / close ----------------------------------------------------------


func is_open() -> bool:
	return visible


func open() -> void:
	## The one and only read of the config: mounting the overlay never reads it.
	load_from_disk()
	_sync_sliders()
	_refresh_badge()
	visible = true


func close() -> void:
	visible = false


func toggle() -> void:
	if is_open():
		close()
	else:
		open()


# ----- the config file -------------------------------------------------------


## Writes the live `OreTuning` snapshot to `config_path`. Returns the write error.
func save() -> Error:
	var config := ConfigFile.new()
	config.set_value(CONFIG_SECTION, CONFIG_KEY, OreTuningScript.to_dict())
	var error := config.save(config_path)
	_set_status("saved %s" % config_path if error == OK else "save failed (%d)" % error)
	return error


## Applies `config_path` when it exists. Returns false when there is no file (or
## it is unreadable/unusable), in which case the live values are left alone.
func load_from_disk() -> bool:
	if not FileAccess.file_exists(config_path):
		return false
	var config := ConfigFile.new()
	if config.load(config_path) != OK:
		return false
	var values: Variant = config.get_value(CONFIG_SECTION, CONFIG_KEY, null)
	if not values is Dictionary:
		return false
	OreTuningScript.from_dict(values)
	_set_status("loaded %s" % config_path)
	return true


## Back to the declared defaults and the config file is gone.
func reset() -> void:
	OreTuningScript.reset_to_defaults()
	_delete_config()
	_sync_sliders()
	_refresh_badge()
	_set_status("reset to defaults")


func _delete_config() -> void:
	if not FileAccess.file_exists(config_path):
		return
	var directory := DirAccess.open(config_path.get_base_dir())
	if directory != null:
		directory.remove(config_path.get_file())


# ----- the TUNED badge -------------------------------------------------------


## True while the TUNED badge is shown (the widget's own flag).
func badge_visible() -> bool:
	return _badge != null and _badge.visible


## True while any field differs from the default `OreTuning` produces.
func is_tuned() -> bool:
	var defaults := _defaults_snapshot()
	var live := OreTuningScript.to_dict()
	for key: Variant in defaults:
		if not _same_value(live[key], defaults[key]):
			return true
	return false


## The defaults are whatever `reset_to_defaults()` writes - never a number typed
## here. A snapshot/reset/restore so capturing them cannot disturb a tuned
## session, and the result is cached (the defaults cannot change).
static func _defaults_snapshot() -> Dictionary:
	if _defaults.is_empty():
		var live := OreTuningScript.to_dict()
		OreTuningScript.reset_to_defaults()
		_defaults = OreTuningScript.to_dict()
		OreTuningScript.from_dict(live)
	return _defaults


static func _same_value(a: Variant, b: Variant) -> bool:
	if a is Dictionary and b is Dictionary:
		var left := a as Dictionary
		var right := b as Dictionary
		if left.size() != right.size():
			return false
		for key: Variant in left:
			if not right.has(key) or not _same_value(left[key], right[key]):
				return false
		return true
	if (a is float or a is int) and (b is float or b is int):
		return is_equal_approx(float(a), float(b))
	return a == b


# ----- the slider surface ----------------------------------------------------


## The slider for a field key, or null. Used by the tests and by `_sync_sliders`.
func slider(key: StringName) -> Range:
	return _sliders.get(key) as Range


## The printed value for a field key, the row's read-out text.
func value_text(key: StringName) -> String:
	var label: Label = _value_labels.get(key)
	return label.text if label != null else ""


func _sync_sliders() -> void:
	_syncing = true
	for spec: Dictionary in SLIDER_SPECS:
		var key: StringName = spec[&"key"]
		var control := slider(key)
		if control != null:
			control.value = _current_value(key)
	_syncing = false
	_refresh_value_texts()


func _on_slider_changed(value: float, key: StringName) -> void:
	if _syncing:
		return
	_apply(key, value)
	_refresh_value_texts()
	_refresh_badge()


## Writes one field straight into the live surface (the "live apply").
func _apply(key: StringName, value: float) -> void:
	match key:
		&"gun_burst_share":
			OreTuningScript.gun_burst_share = value
		&"fragment_core_share":
			OreTuningScript.fragment_core_share = value
		&"gun_chip_rate":
			OreTuningScript.gun_chip_rate = value
		&"mine_cycle":
			OreTuningScript.mine_cycle = value
		&"work_per_unit":
			OreTuningScript.work_per_unit = value
		&"yield_variance_min":
			OreTuningScript.yield_variance_min = value
		&"yield_variance_max":
			OreTuningScript.yield_variance_max = value
		&"pickup_burst_x":
			OreTuningScript.pickup_burst = Vector2i(
				int(round(value)), OreTuningScript.pickup_burst.y
			)
		&"pickup_burst_y":
			OreTuningScript.pickup_burst = Vector2i(
				OreTuningScript.pickup_burst.x, int(round(value))
			)
		&"tier_base_yield_1":
			_set_tier_yield(1, value)
		&"tier_base_yield_2":
			_set_tier_yield(2, value)
		&"tier_base_yield_3":
			_set_tier_yield(3, value)
		&"tier_base_yield_4":
			_set_tier_yield(4, value)


func _set_tier_yield(tier: int, value: float) -> void:
	var table := OreTuningScript.tier_base_yield.duplicate()
	table[tier] = int(round(value))
	OreTuningScript.tier_base_yield = table


func _current_value(key: StringName) -> float:
	match key:
		&"gun_burst_share":
			return OreTuningScript.gun_burst_share
		&"fragment_core_share":
			return OreTuningScript.fragment_core_share
		&"gun_chip_rate":
			return OreTuningScript.gun_chip_rate
		&"mine_cycle":
			return OreTuningScript.mine_cycle
		&"work_per_unit":
			return OreTuningScript.work_per_unit
		&"yield_variance_min":
			return OreTuningScript.yield_variance_min
		&"yield_variance_max":
			return OreTuningScript.yield_variance_max
		&"pickup_burst_x":
			return float(OreTuningScript.pickup_burst.x)
		&"pickup_burst_y":
			return float(OreTuningScript.pickup_burst.y)
		&"tier_base_yield_1":
			return float(OreTuningScript.tier_base_yield.get(1, 1))
		&"tier_base_yield_2":
			return float(OreTuningScript.tier_base_yield.get(2, 1))
		&"tier_base_yield_3":
			return float(OreTuningScript.tier_base_yield.get(3, 1))
		&"tier_base_yield_4":
			return float(OreTuningScript.tier_base_yield.get(4, 1))
	return 0.0


func _refresh_value_texts() -> void:
	for key: StringName in _sliders:
		_set_value_text(key)


func _set_value_text(key: StringName) -> void:
	var label: Label = _value_labels.get(key)
	var control := slider(key)
	if label == null or control == null:
		return
	if _is_int(key):
		label.text = "%d" % int(round(control.value))
	else:
		label.text = "%.3f" % control.value


func _is_int(key: StringName) -> bool:
	for spec: Dictionary in SLIDER_SPECS:
		if spec[&"key"] == key:
			return bool(spec[&"int"])
	return false


func _refresh_badge() -> void:
	if _badge != null:
		_badge.visible = is_tuned()


func _set_status(text: String) -> void:
	if _status != null:
		_status.text = text


# ----- the panel -------------------------------------------------------------


## Built in code so no shipped UI file is touched. A new instance that is never
## opened creates no widget bound to a tuned value (AC4).
func _build() -> void:
	_panel = PanelContainer.new()
	_panel.name = "DevTuningPanel"
	_panel.position = Vector2(28.0, 28.0)
	_panel.custom_minimum_size = Vector2(460.0, 0.0)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.07, 0.94)
	style.border_color = Color(0.35, 0.85, 0.65, 0.9)
	style.set_border_width_all(1)
	style.set_content_margin_all(12.0)
	_panel.add_theme_stylebox_override(&"panel", style)
	add_child(_panel)

	var column := VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override(&"separation", 6)
	_panel.add_child(column)

	var title := Label.new()
	title.name = "Title"
	title.text = "ORE TUNING  (F1)"
	column.add_child(title)

	_badge = Label.new()
	_badge.name = "TunedBadge"
	_badge.text = "TUNED"
	_badge.visible = false
	column.add_child(_badge)

	var scroll := ScrollContainer.new()
	scroll.name = "Rows"
	scroll.custom_minimum_size = Vector2(0.0, 460.0)
	column.add_child(scroll)

	var rows := VBoxContainer.new()
	rows.name = "RowList"
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)

	for spec: Dictionary in SLIDER_SPECS:
		_add_slider_row(rows, spec)

	var buttons := HBoxContainer.new()
	buttons.name = "Buttons"
	buttons.add_theme_constant_override(&"separation", 8)
	column.add_child(buttons)

	var save_button := Button.new()
	save_button.name = "SaveButton"
	save_button.text = "Save"
	save_button.pressed.connect(save)
	buttons.add_child(save_button)

	var reset_button := Button.new()
	reset_button.name = "ResetButton"
	reset_button.text = "Reset"
	reset_button.pressed.connect(reset)
	buttons.add_child(reset_button)

	_status = Label.new()
	_status.name = "Status"
	_status.text = ""
	column.add_child(_status)


func _add_slider_row(parent: Control, spec: Dictionary) -> void:
	var key: StringName = spec[&"key"]
	var is_int: bool = bool(spec[&"int"])

	var row := HBoxContainer.new()
	row.name = String(key) + "Row"
	row.add_theme_constant_override(&"separation", 8)
	parent.add_child(row)

	var name_label := Label.new()
	name_label.name = "Name"
	name_label.text = String(spec[&"label"])
	name_label.custom_minimum_size = Vector2(170.0, 0.0)
	row.add_child(name_label)

	var control := HSlider.new()
	control.name = String(key)
	control.min_value = float(spec[&"min"])
	control.max_value = float(spec[&"max"])
	control.step = float(spec[&"step"])
	control.rounded = is_int
	control.allow_greater = false
	control.allow_lesser = false
	control.custom_minimum_size = Vector2(180.0, 0.0)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.value_changed.connect(_on_slider_changed.bind(key))
	row.add_child(control)

	var value_label := Label.new()
	value_label.name = "Value"
	value_label.custom_minimum_size = Vector2(64.0, 0.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)

	_sliders[key] = control
	_value_labels[key] = value_label
