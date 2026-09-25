@tool
extends McpTestSuite
## Suite s13_devmenu: the F1 developer tuning overlay (S13_BRIEF section 2 rule
## 6, AC4). It drives the real input pipeline (`Input.parse_input_event` ->
## `SceneTree` -> the overlay's `_unhandled_key_input`) and the real widgets, and
## checks that the panel reads its config file only on open.
##
## The store is scratch per run (`XDG_DATA_HOME` is set by the gate command), and
## every overlay this suite mounts is pointed at the runner's own `_gate_scratch`
## subdirectory, so the run never reads, writes or deletes the pinned
## `user://dev_tuning.cfg` (S13-R1's F2). The pinned default is asserted, not used.

const MenuScene := preload("res://ui/dev/dev_tuning_menu.tscn")
const MenuScript := preload("res://ui/dev/dev_tuning_menu.gd")
const OreTuningScript := preload("res://game/ore_tuning.gd")
const AsteroidScript := preload("res://game/asteroid.gd")

## The default path the shipped overlay must keep (S13_BRIEF section 2 rule 6). The
## suite asserts it and never writes or deletes the file at it.
const PINNED_CONFIG_PATH := "user://dev_tuning.cfg"
## The suite's own config file, inside the sandbox directory `headless_runner.gd`
## seeds for the gate (`GATE_SCRATCH_DIR`), never the pinned path above.
const SCRATCH_DIR := "user://_gate_scratch"
const CONFIG_PATH := "user://_gate_scratch/dev_tuning.cfg"
const CONFIG_SECTION := "ore_tuning"
const CONFIG_KEY := "values"
## The owner tick 01 section 5.6, the anchor `test_s13_caps.gd` also asserts.
const DEFAULT_GUN_BURST_SHARE := 0.10

var _tree: SceneTree = null
## An autoload already in the tree, so mounting never races the runner's own
## `_ready` (adding to the root there fails with "busy setting up children").
var _host: Node = null
var _menu: CanvasLayer = null
## Whether the pinned config existed before this suite ran, so a test can prove
## the run neither created nor deleted it (S13-R1's F2).
var _pinned_existed_at_start := false


func suite_name() -> String:
	return "s13_devmenu"


func suite_setup(_ctx: Dictionary) -> void:
	_tree = Engine.get_main_loop() as SceneTree
	if _tree == null:
		skip_suite("a SceneTree is needed to mount the overlay")
		return
	_host = _tree.root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _host == null:
		skip_suite("no PlayerProfile autoload to host the overlay")
		return
	_pinned_existed_at_start = FileAccess.file_exists(PINNED_CONFIG_PATH)


func setup() -> void:
	OreTuningScript.reset_to_defaults()
	_ensure_scratch_dir()
	_delete_config()
	_menu = MenuScene.instantiate() as CanvasLayer
	assert_true(_menu != null, "the overlay scene instantiates as a CanvasLayer")
	if _menu != null:
		_menu.set(&"config_path", CONFIG_PATH)
		_host.add_child(_menu)


func teardown() -> void:
	if _menu != null and is_instance_valid(_menu):
		_menu.free()
	_menu = null
	OreTuningScript.reset_to_defaults()
	_delete_config()


## ---------------------------------------------------------------- the toggles


func test_f1_toggles_the_overlay() -> void:
	assert_false(_menu.is_open(), "the overlay starts closed")
	_tap_f1()
	assert_true(_menu.is_open(), "F1 opens it")
	_tap_f1()
	assert_false(_menu.is_open(), "F1 again closes it")
	## The overlay is a dev panel: it must not pause the game.
	assert_false(_tree.paused, "toggling never pauses the tree")
	assert_eq(_menu.process_mode, Node.PROCESS_MODE_ALWAYS, "and it stays live through a pause")


## ------------------------------------------------------------ the live apply


func test_sliders_write_every_live_field() -> void:
	_open()
	var fields: Dictionary = {
		&"gun_burst_share": 0.42,
		&"fragment_core_share": 0.66,
		&"gun_chip_rate": 0.35,
		&"mine_cycle": 2.4,
		&"work_per_unit": 3.0,
		&"tier_base_yield_1": 9.0,
		&"tier_base_yield_2": 8.0,
		&"tier_base_yield_3": 7.0,
		&"tier_base_yield_4": 6.0,
		&"yield_variance_min": 0.2,
		&"yield_variance_max": 1.8,
		&"pickup_burst_x": 4.0,
		&"pickup_burst_y": 5.0,
	}
	for key: StringName in fields:
		_set_slider(key, float(fields[key]))
	for key: StringName in fields:
		assert_true(
			is_equal_approx(_ore_value(key), float(fields[key])),
			"%s wrote the live field (got %.3f)" % [key, _ore_value(key)]
		)
		## And the row prints the value it now holds.
		assert_contains(
			_menu.value_text(key),
			_printed_for(key, float(fields[key])),
			"%s prints its value" % key
		)
	## Every slider in the panel is exercised by the table above.
	assert_eq(fields.size(), MenuScript.SLIDER_SPECS.size(), "the table covers every slider")


func test_sliders_are_bounded_to_the_pinned_ranges() -> void:
	_open()
	for spec: Dictionary in MenuScript.SLIDER_SPECS:
		var control: Range = _menu.slider(spec[&"key"])
		assert_true(control != null, "slider %s exists" % spec[&"key"])
		assert_true(is_equal_approx(control.min_value, float(spec[&"min"])), "min pinned")
		assert_true(is_equal_approx(control.max_value, float(spec[&"max"])), "max pinned")


## ---------------------------------------------------------- the config file


func test_save_then_open_round_trips() -> void:
	_open()
	_set_slider(&"gun_burst_share", 0.33)
	_set_slider(&"mine_cycle", 2.5)
	_set_slider(&"tier_base_yield_2", 11.0)
	assert_eq(_menu.save(), OK, "Save writes the config")
	assert_true(FileAccess.file_exists(CONFIG_PATH), "the file exists after Save")
	## Close and wipe the live surface, then re-open: only opening may read it.
	_menu.close()
	OreTuningScript.reset_to_defaults()
	assert_true(is_equal_approx(_ore_value(&"gun_burst_share"), 0.10), "defaults came back")
	_menu.open()
	assert_true(is_equal_approx(_ore_value(&"gun_burst_share"), 0.33), "open applied the file")
	assert_true(is_equal_approx(_ore_value(&"mine_cycle"), 2.5), "and every field")
	assert_eq(int(_ore_value(&"tier_base_yield_2")), 11, "including the tier table")


func test_reset_restores_defaults_and_removes_the_file() -> void:
	_open()
	_set_slider(&"gun_chip_rate", 0.35)
	_menu.save()
	assert_true(FileAccess.file_exists(CONFIG_PATH), "the file is on disk before Reset")
	assert_true(_menu.is_tuned(), "a changed field is TUNED")
	_menu.reset()
	assert_true(is_equal_approx(_ore_value(&"gun_chip_rate"), 0.10), "Reset restores the fields")
	assert_false(_menu.is_tuned(), "the badge clears")
	assert_false(_menu.badge_visible(), "and the widget hides")
	assert_false(FileAccess.file_exists(CONFIG_PATH), "Reset deletes the config")


## The two buttons are the real widgets: the suite presses them, not the
## methods they call (S8's L170 - a handler called directly proves no plumbing).
func test_save_and_reset_buttons_are_wired() -> void:
	_open()
	_set_slider(&"gun_burst_share", 0.44)
	var save_button := _menu.get_node(NodePath(&"DevTuningPanel/Column/Buttons/SaveButton")) as Button
	assert_true(save_button != null, "the Save button exists")
	if save_button != null:
		save_button.pressed.emit()
	assert_true(FileAccess.file_exists(CONFIG_PATH), "the Save button writes the config")
	var reset_button := _menu.get_node(NodePath(&"DevTuningPanel/Column/Buttons/ResetButton")) as Button
	assert_true(reset_button != null, "the Reset button exists")
	if reset_button != null:
		reset_button.pressed.emit()
	assert_false(FileAccess.file_exists(CONFIG_PATH), "the Reset button deletes it")
	assert_true(is_equal_approx(_ore_value(&"gun_burst_share"), 0.10), "and restores the fields")


func test_tuned_badge_tracks_the_fields() -> void:
	_open()
	assert_false(_menu.is_tuned(), "a fresh overlay is at defaults")
	assert_false(_menu.badge_visible(), "with the badge hidden")
	for key: StringName in [&"gun_burst_share", &"fragment_core_share", &"pickup_burst_x"]:
		_menu.reset()
		assert_false(_menu.badge_visible(), "%s at default hides the badge" % key)
		_set_slider(key, _other_value(key))
		assert_true(_menu.is_tuned(), "%s off default is TUNED" % key)
		assert_true(_menu.badge_visible(), "%s shows the badge" % key)


## ------------------------------------------------------------------- AC4 guard


## The file is never read at boot: a store carrying a divergent config must leave
## the default-path arithmetic byte-identical until the panel is opened, and a
## freshly mounted overlay must not be TUNED by it. The pinned default is asserted
## rather than used: the suite's own file lives in the scratch dir (S13-R1's F2), so
## this test also proves the pinned file survives the run's own delete.
func test_config_is_never_read_at_boot() -> void:
	assert_eq(MenuScript.CONFIG_PATH, PINNED_CONFIG_PATH, "the shipped default path is pinned")
	assert_eq(CONFIG_PATH.get_base_dir(), SCRATCH_DIR, "the suite's own file is in the scratch dir")
	var baseline := _default_path_signature()
	_write_divergent_config()
	assert_true(FileAccess.file_exists(CONFIG_PATH), "the store carries a config")
	assert_eq(FileAccess.file_exists(PINNED_CONFIG_PATH), _pinned_existed_at_start,
		"writing the suite's file leaves the pinned config alone")
	var fresh := MenuScene.instantiate() as CanvasLayer
	assert_eq(
		String(fresh.get(&"config_path")), PINNED_CONFIG_PATH,
		"a freshly mounted overlay defaults to the pinned path"
	)
	fresh.set(&"config_path", CONFIG_PATH)
	_host.add_child(fresh)
	assert_eq(_default_path_signature(), baseline, "default-path arithmetic is unchanged while mounted")
	assert_false(fresh.is_tuned(), "a never-opened overlay is not TUNED by the file")
	assert_true(is_equal_approx(OreTuningScript.gun_burst_share, DEFAULT_GUN_BURST_SHARE),
		"and the live gun cap is still the default")
	fresh.open()
	assert_true(is_equal_approx(OreTuningScript.gun_burst_share, 0.9),
		"only opening reads the file")
	fresh.free()
	OreTuningScript.reset_to_defaults()
	_delete_config()
	assert_eq(FileAccess.file_exists(PINNED_CONFIG_PATH), _pinned_existed_at_start,
		"and deleting the suite's file leaves the pinned config alone")
	assert_eq(_default_path_signature(), baseline, "and the store is clean again")


## ---------------------------------------------------------------- the helpers


func _open() -> void:
	if not _menu.is_open():
		_menu.open()


func _tap_f1() -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = KEY_F1
		event.physical_keycode = KEY_F1
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()


func _set_slider(key: StringName, value: float) -> void:
	var control: Range = _menu.slider(key)
	assert_true(control != null, "slider %s exists" % key)
	if control != null:
		control.value = value


## A value inside the field's own range but different from its default, so the
## range slider emits (Range only signals a real change).
func _other_value(key: StringName) -> float:
	var control: Range = _menu.slider(key)
	if control == null:
		return 0.0
	var candidate: float = control.value + control.step
	if candidate > control.max_value:
		candidate = control.value - control.step
	if candidate < control.min_value:
		candidate = control.max_value
	return round(candidate) if _is_int_key(key) else candidate


func _is_int_key(key: StringName) -> bool:
	for spec: Dictionary in MenuScript.SLIDER_SPECS:
		if spec[&"key"] == key:
			return bool(spec[&"int"])
	return false


## The printed text matches the widget's own format (ints as ints).
func _printed_for(key: StringName, value: float) -> String:
	return "%d" % int(round(value)) if _is_int_key(key) else "%.3f" % value


## The test's own reading of a field, so a typo in the overlay's apply map cannot
## hide behind the same typo in the assertion.
func _ore_value(key: StringName) -> float:
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
			return float(OreTuningScript.tier_base_yield.get(1, 0))
		&"tier_base_yield_2":
			return float(OreTuningScript.tier_base_yield.get(2, 0))
		&"tier_base_yield_3":
			return float(OreTuningScript.tier_base_yield.get(3, 0))
		&"tier_base_yield_4":
			return float(OreTuningScript.tier_base_yield.get(4, 0))
	return 0.0


## A cheap default-path reading that depends on `OreTuning` (the reserve split and
## the gun cap): if the file leaked into memory, either figure would move.
func _default_path_signature() -> String:
	return "%d/%d/%.3f" % [
		AsteroidScript.extractable_units(7),
		AsteroidScript.reserve_units_of(7),
		OreTuningScript.gun_burst_share,
	]


## The config the overlay itself writes, but written by the test: a divergent gun
## cap (0.9) and reserve share (0.8), so a leaked read is unmistakable.
func _write_divergent_config() -> void:
	var config := ConfigFile.new()
	config.set_value(CONFIG_SECTION, CONFIG_KEY, {
		&"gun_burst_share": 0.9,
		&"fragment_core_share": 0.8,
	})
	assert_eq(config.save(CONFIG_PATH), OK, "the divergent config writes")


func _delete_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		return
	var directory := DirAccess.open(CONFIG_PATH.get_base_dir())
	if directory != null:
		directory.remove(CONFIG_PATH.get_file())


## `ConfigFile.save` into a missing directory fails with `err=7`, and the editor's
## own runner seeds no scratch store, so the suite creates it itself (the gate
## runner's store already holds it: `ERR_ALREADY_EXISTS` is fine).
func _ensure_scratch_dir() -> void:
	var error := DirAccess.make_dir_recursive_absolute(SCRATCH_DIR)
	assert_true(
		error == OK or error == ERR_ALREADY_EXISTS,
		"the scratch dir %s is available (error %d)" % [SCRATCH_DIR, error]
	)
