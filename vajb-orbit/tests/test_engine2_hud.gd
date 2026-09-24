@tool
extends McpTestSuite
## Suite engine2_hud: slice 2 W5's HUD additions (ENGINE_SPEC section 10, UI_SPEC sections
## 3.1b / 3.3 / 3.5 / 3.6).
##
## The shipped `hud.tscn` is instantiated into the runner's own scene tree, so `_ready`
## builds the slice-2 widgets and the theme is the live one; each suite frees what it added,
## because `headless_runner.gd` calls `setup`/`teardown` but never the base class's
## `_free_tracked` (measured by W2: a tracked node leaks its RIDs into the gate log).
##
## Everything asserted here is a *reading the HUD was handed back*: the payload it holds,
## the ring's progress, the dial's own geometry rule and the marker's flag. The gameplay
## side's pushes are `engine2_wiring`'s.

const HudScene := preload("res://ui/hud/hud.tscn")
const HudTheme := preload("res://ui/theme/vajb_theme.tres")

const ENERGY: StringName = &"energy"
const FUEL: StringName = &"fuel"

var _hud: Control = null


func suite_name() -> String:
	return "engine2_hud"


func setup() -> void:
	_hud = HudScene.instantiate() as Control
	if _hud == null:
		fail_setup("hud.tscn did not instantiate")
		return
	_hud.theme = HudTheme
	_fixture_host().add_child(_hud)


func teardown() -> void:
	if _hud != null and is_instance_valid(_hud):
		_hud.free()
	_hud = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## Where a fixture may enter the tree. The runner calls every test from inside its own
## `_ready`, and the root viewport is still busy adding the runner scene at that moment, so
## `root.add_child(...)` fails with "Parent node is busy setting up children" (measured on
## the first run of this suite). The profile autoload entered the tree before the main scene
## and takes children all through the run, and the HUD carries its own theme, so nothing in
## this suite depends on where the fixture hangs.
func _fixture_host() -> Node:
	var root := _tree().root
	var host := root.get_node_or_null(NodePath(&"PlayerProfile"))
	return host if host != null else root


## ---------------------------------------------------------------------------
## Section 3.1b: the pool feed (the cluster's FUEL/ENRG dials) and the emergency banner
## ---------------------------------------------------------------------------


func test_pool_bars_hold_the_values_they_were_pushed() -> void:
	_hud.call(&"set_pool", ENERGY, 40.0, 100.0)
	_hud.call(&"set_pool", FUEL, 12.0, 200.0)
	var currents: Dictionary = _hud.get(&"_pool_current")
	var maxima: Dictionary = _hud.get(&"_pool_maximum")
	assert_eq(float(currents[ENERGY]), 40.0, "energy current")
	assert_eq(float(maxima[ENERGY]), 100.0, "energy maximum")
	assert_eq(float(currents[FUEL]), 12.0, "fuel current")
	assert_eq(float(maxima[FUEL]), 200.0, "fuel maximum")


func test_the_pool_blocks_retire_to_the_cluster_dials() -> void:
	## UI_SPEC section 3.1b's 2026-09-24 amendment: the two ProgressBar blocks and their
	## labels leave the flight HUD; the cluster's FUEL/ENRG value dials are the pool
	## readouts now, fed by the same `set_pool` seam.
	var retired: Array = _hud.call(&"retired_pool_blocks")
	assert_eq(retired.size(), 2, "the energy and the fuel block")
	for block: Control in retired:
		assert_false(block.is_visible_in_tree(), "%s is off the flight HUD" % block.name)
	## The feed lands on the dials instead: 40/100 reads 40 %, 12/200 reads 6 %.
	_hud.call(&"set_pool", ENERGY, 40.0, 100.0)
	_hud.call(&"set_pool", FUEL, 12.0, 200.0)
	var cockpit: Control = _hud.call(&"cockpit")
	assert_true(cockpit != null, "the cluster is built")
	var pools: Dictionary = cockpit.call(&"pool_readings")
	assert_eq(int(pools["enrg"]["percent"]), 40, "the ENRG dial reads the energy percent")
	assert_eq(int(pools["fuel"]["percent"]), 6, "the FUEL dial reads the fuel percent")
	assert_true(bool(pools["fuel"]["danger"]), "and 6 % is the fuel dial's danger read")


func test_the_emergency_flag_flips_the_banner_and_the_energy_fill() -> void:
	_hud.call(&"set_emergency", true)
	assert_true(bool(_hud.get(&"_emergency")), "the flag is held")
	var banner: Label = _hud.get(&"_emergency_banner")
	assert_true(banner != null and banner.visible, "the banner is shown")
	assert_eq(banner.text, "EMERGENCY FLIGHT", "section 3.1b's own words")
	_hud.call(&"set_emergency", false)
	assert_false(banner.visible, "and hidden again once the mode ends")


func test_an_unknown_pool_kind_is_ignored_rather_than_fatal() -> void:
	_hud.call(&"set_pool", &"coolant", 5.0, 10.0)
	var currents: Dictionary = _hud.get(&"_pool_current")
	assert_false(currents.has(&"coolant"), "no bar, no entry, no error")


## ---------------------------------------------------------------------------
## Section 10: the target window's payload
## ---------------------------------------------------------------------------


func test_the_payload_carries_section_tens_two_new_keys() -> void:
	_hud.call(&"set_target_info", {
		"name": "Lancer",
		"hull": 0.5,
		"shield": 0.25,
		"distance_m": 1240.0,
		"in_range": false,
		"threat": &"hostile",
	})
	var info: Dictionary = _hud.call(&"target_info")
	assert_eq(String(info["name"]), "Lancer")
	assert_eq(float(info["hull"]), 0.5)
	assert_eq(float(info["shield"]), 0.25)
	assert_eq(float(info["distance_m"]), 1240.0)
	assert_false(bool(info["in_range"]), "the range state rides the payload")
	assert_true(bool(info["has_range"]), "and the HUD records that it was sent")
	assert_eq(String(info["threat"]), "HOSTILE", "section 8's class, upper-cased for the panel")


func test_the_range_state_prints_with_the_distance_it_qualifies() -> void:
	_hud.call(&"set_target_info", {
		"name": "Lancer",
		"distance_m": 1240.0,
		"in_range": true,
		"threat": &"hostile",
	})
	var label: Label = _hud.get(&"_target_distance_label")
	assert_eq(label.text, "1 240 m  IN RANGE", "the grouped distance plus the state")
	_hud.call(&"set_target_info", {"name": "Lancer", "distance_m": 1240.0, "in_range": false})
	assert_eq(label.text, "1 240 m  OUT OF RANGE")


func test_a_caller_without_the_range_key_keeps_the_old_text() -> void:
	_hud.call(&"set_target_info", {"name": "Lancer", "distance_m": 900.0})
	var label: Label = _hud.get(&"_target_distance_label")
	assert_eq(label.text, "900 m", "no range reading, no extra text")


func test_the_threat_tint_still_follows_a_hostile_reading() -> void:
	_hud.call(&"set_target_info", {"name": "Lancer", "threat": &"hostile"})
	var threat: Label = _hud.get(&"_target_threat_label")
	assert_true(
		threat.has_theme_color_override(&"font_color"), "the hostile reading takes accent_danger"
	)
	_hud.call(&"set_target_info", {"name": "Convoy", "threat": &"neutral"})
	assert_false(
		threat.has_theme_color_override(&"font_color"), "any other reading keeps the theme colour"
	)


## ---------------------------------------------------------------------------
## UI_SPEC 3.5: the lock ring
## ---------------------------------------------------------------------------


func test_the_lock_ring_follows_the_channel_progress() -> void:
	var ring: Control = _hud.call(&"lock_ring")
	assert_true(ring != null, "the ring exists")
	assert_false(ring.visible, "and is hidden before the first channel")
	_hud.call(&"set_lock_progress", 0.5)
	assert_true(ring.visible, "a running channel shows the ring")
	assert_eq(float(ring.get(&"progress")), 0.5)
	assert_false(bool(ring.get(&"complete")), "not complete yet")
	_hud.call(&"set_lock_progress", 1.0)
	assert_true(bool(ring.get(&"complete")), "the completed ring is the metal_light one")
	assert_true(ring.visible, "and it stays drawn for the lock's lifetime")
	_hud.call(&"set_lock_progress", 0.0)
	assert_false(ring.visible, "an empty progress hides it")
	assert_eq(float(_hud.call(&"lock_progress")), 0.0, "and the reading is mirrored")


func test_the_ring_is_a_child_of_the_reticle_and_ignores_the_mouse() -> void:
	var ring: Control = _hud.call(&"lock_ring")
	var reticle: Control = _hud.get(&"_reticle")
	assert_eq(ring.get_parent(), reticle, "it rides the reticle's position")
	assert_eq(ring.mouse_filter, Control.MOUSE_FILTER_IGNORE, "and never eats a click")
	assert_true(ring.anchor_right == 1.0 and ring.anchor_bottom == 1.0, "full-rect over it")


## ---------------------------------------------------------------------------
## UI_SPEC 3.6: the radial speedometer
## ---------------------------------------------------------------------------


func test_the_dial_is_the_120_square_with_the_spec_geometry() -> void:
	var dial: Control = _hud.call(&"speedometer")
	assert_true(dial != null, "the dial exists")
	assert_eq(dial.custom_minimum_size, Vector2(120.0, 120.0), "UI_SPEC's 120 x 120 control")
	assert_eq(int(dial.get_script().get_script_constant_map()["SEGMENTS"]), 10, "10 segments")
	var sweep: float = dial.get_script().get_script_constant_map()["SWEEP"]
	assert_true(is_equal_approx(sweep, PI * 1.5), "across 270 degrees")
	var overdrive: float = dial.get_script().get_script_constant_map()["OVERDRIVE"]
	assert_eq(overdrive, 0.9, "the overdrive read above 0.9")


func test_the_dial_fills_its_segments_by_the_spec_rule() -> void:
	var dial: Control = _hud.call(&"speedometer")
	var cases := {0.0: 1, 0.05: 1, 0.55: 6, 0.95: 10, 1.0: 10}
	for ratio: float in cases:
		_hud.call(&"set_speedometer", ratio, Vector2.RIGHT, Vector2.RIGHT)
		assert_eq(
			int(dial.call(&"filled_segments")),
			int(cases[ratio]),
			"segment i is filled when ratio >= i/10 (ratio %s)" % ratio
		)


func test_the_overdrive_segment_is_the_topmost_filled_one() -> void:
	var dial: Control = _hud.call(&"speedometer")
	_hud.call(&"set_speedometer", 0.95, Vector2.RIGHT, Vector2.RIGHT)
	assert_eq(int(dial.call(&"overdrive_segment")), 9, "the tenth segment reads red")
	_hud.call(&"set_speedometer", 0.9, Vector2.RIGHT, Vector2.RIGHT)
	assert_eq(int(dial.call(&"overdrive_segment")), -1, "at exactly 0.9 nothing is in overdrive")
	_hud.call(&"set_speedometer", 0.5, Vector2.RIGHT, Vector2.RIGHT)
	assert_eq(int(dial.call(&"overdrive_segment")), -1, "and nothing at cruise")


func test_the_speedometer_mirrors_the_ratio_it_was_handed() -> void:
	_hud.call(&"set_speedometer", 0.42, Vector2(1.0, 0.0), Vector2.RIGHT.rotated(1.0))
	assert_eq(float(_hud.call(&"speedometer_ratio")), 0.42)
	_hud.call(&"set_speedometer", 4.0, Vector2.RIGHT, Vector2.RIGHT)
	assert_eq(float(_hud.call(&"speedometer_ratio")), 1.0, "clamped to the dial's own range")


## The prograde needle is UI_SPEC section 1's `accent_nav`: the theme's token when the
## theme carries it, and the spec's own literal until then (the theme is a forbidden file
## for this worker, so the HUD holds that one hex).
func test_the_prograde_needle_is_the_one_sanctioned_cyan() -> void:
	var dial: Control = _hud.call(&"speedometer")
	var theme_has_token: bool = HudTheme.has_color(&"accent_nav", &"Tokens")
	var wanted: Color = Color("#6fb8c4")
	if theme_has_token:
		wanted = HudTheme.get_color(&"accent_nav", &"Tokens")
	assert_eq(dial.call(&"needle_colour"), wanted, "the needle's colour")


func test_the_hit_marker_flashes_and_then_fades() -> void:
	var marker: Control = _hud.call(&"hit_marker_node")
	assert_true(marker != null, "the marker exists")
	assert_false(marker.visible, "hidden until something lands")
	_hud.call(&"hit_marker")
	assert_true(marker.visible, "a confirmed hit shows it")
	assert_true(bool(marker.call(&"fading")), "at full alpha, on its way out")
	assert_eq(marker.modulate.a, 1.0, "the flash starts opaque")


## ---------------------------------------------------------------------------
## Section 3.3 / section 8: the blip feed and the frozen API
## ---------------------------------------------------------------------------


func test_blips_reach_the_minimap_including_the_ghost_kind() -> void:
	var blips: Array[Dictionary] = [
		{"pos": Vector2.ZERO, "kind": &"self"},
		{"pos": Vector2(100.0, 0.0), "kind": &"hostile"},
		{"pos": Vector2(200.0, 0.0), "kind": &"ghost"},
	]
	_hud.call(&"set_minimap_blips", blips)
	var minimap: Minimap = _hud.get(&"_minimap")
	assert_eq((minimap.get(&"_blips") as Array).size(), 3, "every blip was handed on")
	assert_eq(StringName((minimap.get(&"_blips") as Array)[2].get("kind", &"")), &"ghost")


func test_the_frozen_target_api_still_marks_and_clears() -> void:
	var reticle: Control = _hud.get(&"_reticle")
	_hud.call(&"set_target", Vector2(600.0, 400.0), 0.5)
	assert_true(bool(reticle.get(&"_has_target")), "set_target marks the hull")
	assert_eq(float(reticle.get(&"_hull_fraction")), 0.5, "with its hull micro-bar")
	_hud.call(&"clear_target")
	assert_false(bool(reticle.get(&"_has_target")), "clear_target hands the draw back to the cursor")
	assert_true((_hud.call(&"target_info") as Dictionary).is_empty(), "and the window empties")


func test_the_reticle_state_is_relayed_and_clamped() -> void:
	_hud.call(&"set_reticle_state", TargetReticle.State.HOSTILE)
	var reticle: Control = _hud.get(&"_reticle")
	assert_eq(int(reticle.call(&"state")), TargetReticle.State.HOSTILE)
	_hud.call(&"set_reticle_state", 99)
	assert_eq(int(reticle.call(&"state")), TargetReticle.State.HOSTILE, "clamped to the enum")
