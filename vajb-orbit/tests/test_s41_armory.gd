@tool
extends McpTestSuite
## Suite s41_armory: wave S41's composition pass on the ARMORY pane (D23-R1's F2/F3/F4 and
## the armory half of F14). One load-bearing row per finding:
##   0. F2 - `FitLeftBox` owns the left sector's slack, so the roofed box reaches the sector's
##      own bottom instead of hugging the grid + CELL INFO (a layout measurement, not a flag
##      read: reverting the flag leaves the box ~a hundred px short).
##   1. F3 - the one shared band reads `STATE`/`HELD` in BATTERY CONFIG (its rows print
##      `FITTED` / `OWNED x n`) and `STATE`/`COST` in FIT CELLS, on both the build and the
##      mode switch.
##   2. F4 - the battery fold's two caption-only plates hug their captions: the empty-cell
##      list collapses to one `W<n> - EMPTY` line (22 px, the empty-cell line's own size) and
##      the drawn well plates stop at each half's content block instead of the 92 px band.
##   3. F14 (armory) - the action pair rides the pane's foot band in BOTH modes, at the same
##      rect, at P1's 360x56, primary rightmost.
##
## The pane is mounted the way the other armory suites mount it (the shipped scene, the
## shipped theme, the profile borrowed and handed back), so nothing here re-implements the
## panel's wiring. Every read is a property (`get`) or a laid-out rect - no `call()` on a
## name that could silently miss.

const PanelScene := preload("res://ui/station/armory_panel.tscn")
const PanelScript := preload("res://ui/station/armory_panel.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")

const PROFILE_PATH := "user://test_s41_armory.cfg"
const VANGUARD: StringName = &"ship_vanguard"
const WINDOW := Vector2(1920.0, 1080.0)
## §8 P1's pair and the empty-cell line's own height (armory_panel.gd's `_refresh_empty_cells`).
const ACTION_P1 := Vector2(360.0, 56.0)
const EMPTY_LINE_HEIGHT := 22.0

var _profile: Node = null
var _host: Control = null
var _panel: Control = null
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_credits := 0
var _previous_fits: Dictionary = {}
var _previous_owned: Array = []
var _previous_modules: Dictionary = {}
var _previous_batteries: Dictionary = {}


func suite_name() -> String:
	return "s41_armory"


func suite_setup(_ctx: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		skip_suite("a SceneTree is needed to mount the pane")
		return
	_profile = tree.root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		skip_suite("the PlayerProfile autoload is the pane's store")
		return
	_previous_path = String(_profile.get(&"save_path"))
	_previous_ship = StringName(_profile.call(&"active_ship"))
	_previous_credits = int(_profile.call(&"credits"))
	_previous_fits = _profile.call(&"fits")
	_previous_owned = _profile.call(&"owned_ships")
	_previous_modules = _profile.call(&"modules")
	_previous_batteries = _profile.get(&"_batteries")
	_profile.set(&"save_path", PROFILE_PATH)
	_delete_file(PROFILE_PATH)


func suite_teardown() -> void:
	if _host != null and is_instance_valid(_host):
		_host.free()
		_host = null
	_panel = null
	if _profile == null:
		return
	_profile.set(&"_credits", _previous_credits)
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_fits", _previous_fits)
	_profile.set(&"_owned_ships", _previous_owned)
	_profile.set(&"_modules", _previous_modules)
	_profile.set(&"_batteries", _previous_batteries)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	_delete_file(PROFILE_PATH)
	_profile = null


func setup() -> void:
	if _host != null and is_instance_valid(_host):
		_host.free()
		_host = null
	_seed_account()
	_host = Control.new()
	_host.name = "S41ArmoryHost"
	_host.theme = ThemeRes
	_host.size = WINDOW
	_profile.add_child(_host)
	_panel = PanelScene.instantiate() as Control
	_host.add_child(_panel)
	_profile.connect(&"profile_changed", Callable(_panel, &"refresh_profile"))


func _seed_account() -> void:
	var owned: Array[StringName] = [VANGUARD]
	_profile.set(&"_credits", 50000)
	_profile.set(&"_active_ship", VANGUARD)
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_batteries", {})


func _delete_file(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(absolute):
		DirAccess.remove_absolute(absolute)


func _settle() -> void:
	_panel.call(&"_lay")


func _node(path: String) -> Control:
	return _panel.get_node_or_null(NodePath(path)) as Control


func _band_words() -> Array[String]:
	var out: Array[String] = []
	var band := _panel.get_node("%BrowserBand") as HBoxContainer
	for cell: Node in band.get_children():
		if cell is Label:
			out.append((cell as Label).text)
	return out


## ------------------------------------------------------------------------ F2 (D23-R1, MED)


## F2: `FitLeftBox` carries the left sector's slack, so the roofed box reaches the sector's
## own bottom. The row measures the *layout*: with the flag reverted the box answers its own
## content minimum (~the grid + CELL INFO) and its bottom lands far above the sector's.
func test_f2_the_fit_left_box_fills_its_sector() -> void:
	_settle()
	var sector := _panel.get_node("%FitLeft") as Control
	var box := _panel.get_node(
		^"ModeHost/FitCells/FitSectors/FitLeft/FitLeftBox"
	) as Control
	assert_true(sector != null and box != null, "the FIT CELLS left sector carries its roofed box")
	if sector == null or box == null:
		return
	assert_eq(
		box.get(&"size_flags_vertical"), Control.SIZE_EXPAND_FILL,
		"F2: the box carries the sector's vertical slack"
	)
	assert_eq(box.size.x, sector.size.x, "and spans the sector's width")
	var gap := sector.get_global_rect().end.y - box.get_global_rect().end.y
	assert_true(
		absf(gap) <= 1.0,
		"F2: the box reaches the sector's bottom (gap %.1f px, box %s, sector %s)" % [
			gap, str(box.size), str(sector.size)
		]
	)
	assert_true(
		box.size.y > 200.0,
		"and is a real surface, not the grid's own ~100 px hug (actual %.1f)" % box.size.y
	)
	## CELL INFO rides inside the same box and still holds the slack (the two cannot fight).
	var info := _panel.get_node("%CellInfoBlock") as Control
	assert_true(
		box.is_ancestor_of(info), "CELL INFO rides the box that owns the slack"
	)


## ------------------------------------------------------------------------ F3 (D23-R1, MED)


## F3: the one shared band's value-column words follow the mode - BATTERY CONFIG's rows print
## `FITTED` / `OWNED x n`, so its band reads `HELD`, never the browser's `COST`. Both the
## landing build and a later mode switch are measured: reverting the fix leaves COST in the
## battery band.
func test_f3_the_battery_band_reads_state_and_held() -> void:
	_settle()
	var fit_words := _band_words()
	assert_true(
		fit_words.has(PanelScript.BAND_STATE) and fit_words.has(PanelScript.BAND_COST),
		"FIT CELLS' band reads the browser's own pair (%s)" % str(fit_words)
	)
	_panel.call(&"set_mode", PanelScript.MODE_BATTERY)
	_settle()
	var battery_words := _band_words()
	assert_true(
		battery_words.has(PanelScript.BAND_STATE) and battery_words.has(PanelScript.BAND_HELD),
		"F3: the battery band reads STATE / HELD (%s)" % str(battery_words)
	)
	assert_false(
		battery_words.has(PanelScript.BAND_COST),
		"F3: and never the browser's COST header over ownership words (%s)" % str(battery_words)
	)
	## The battery rows themselves print the words the band now names.
	var rows := _panel.get_node("%BrowserRows") as VBoxContainer
	var reads: Array[String] = []
	for child: Node in rows.get_children():
		var read := (child as Control).get_node_or_null(NodePath("RowInner/RowBox/Read")) as Label
		if read != null:
			reads.append(read.text)
	assert_true(
		not reads.is_empty(), "the battery list draws rows with their own read column"
	)
	assert_true(
		reads.has(PanelScript.READ_FITTED) or reads.any(
			func(text: String) -> bool: return text.begins_with("OWNED")
		),
		"whose reads are FITTED / OWNED x n (%s)" % str(reads)
	)
	## The switch is a content swap, not a rebuild of a second band.
	_panel.call(&"set_mode", PanelScript.MODE_FIT)
	_settle()
	assert_true(
		_band_words().has(PanelScript.BAND_COST),
		"and the FIT CELLS band comes back with COST"
	)


## ------------------------------------------------------------------------ F4 (D23-R1, LOW)


## F4: the two caption-only plates at the battery fold hug their captions instead of squatting
## as 92 px empty boxes. The empty-cell list collapses to one empty-cell line (22 px) and the
## drawn well plates stop at each half's own content block. Reverting either leaves a plate at
## the band's full 92 px.
func test_f4_the_battery_fold_plates_hug_their_captions() -> void:
	_panel.call(&"set_mode", PanelScript.MODE_BATTERY)
	_settle()
	var scroll := _panel.get_node("%EmptyScroll") as Control
	var half := _panel.get_node("%EmptyMargin") as Control
	assert_true(scroll != null and half != null, "the empty-cell half ships its list")
	if scroll == null or half == null:
		return
	assert_eq(
		scroll.get(&"custom_minimum_size").y, EMPTY_LINE_HEIGHT,
		"F4: the empty-cell list is one empty-cell line tall"
	)
	assert_eq(
		scroll.get(&"size_flags_vertical"), Control.SIZE_SHRINK_BEGIN,
		"and hugs it instead of filling the band"
	)
	assert_true(
		scroll.size.y <= EMPTY_LINE_HEIGHT + 1.0,
		"F4: as laid out it is a caption-height plate, not a 70 px box (actual %.1f)" % scroll.size.y
	)
	assert_true(
		half.size.y > scroll.size.y,
		"the half itself keeps the band's pinned box (%.1f)" % half.size.y
	)
	## The chrome's drawn well plates: each stops at its half's content block.
	var chrome := (_panel.get_node(^"%Console") as Control).get_node_or_null(^"ConsolePanels")
	assert_true(chrome != null, "the console's chrome layer is mounted")
	if chrome == null:
		return
	var wells: Array = chrome.get(&"wells")
	assert_eq(wells.size(), 2, "both well halves keep a plate")
	for plate: Rect2 in wells:
		assert_true(
			plate.size.y < half.size.y,
			"F4: the drawn plate stops at the caption block (%.1f < %.1f)" % [
				plate.size.y, half.size.y
			]
		)
		assert_true(plate.size.y > 0.0, "and still draws something (%.1f)" % plate.size.y)
	## Nothing is hidden: both caption lines and the empty-cell caption stay visible.
	for path: String in ["%EmptyCaption", "%SummaryCaption", "%SummaryHint"]:
		assert_true((_panel.get_node(path) as Control).visible, "%s stays visible (A5.5)" % path)


## ---------------------------------------------------------------------- F14 (armory, MED)


## F14: the action pair rides the pane's foot band in BOTH modes, at the same rect, at P1's
## 360x56 with the primary rightmost. Reverting leaves the battery mode with no band at all
## (the pair lives inside the FIT CELLS mode root and hides with it).
func test_f14_the_action_pair_rides_the_pane_foot_band_on_both_modes() -> void:
	_settle()
	var foot := _panel.get_node("%PaneFoot") as Control
	var row := _panel.get_node(^"PaneFoot/ActionsRow") as HBoxContainer
	var remove := _panel.get_node("%RemoveButton") as Button
	var buy_fit := _panel.get_node("%BuyFitButton") as Button
	assert_true(
		foot != null and row != null and remove != null and buy_fit != null,
		"the pane's foot band ships with its action cluster"
	)
	if foot == null or row == null or remove == null or buy_fit == null:
		return
	assert_eq(
		foot.custom_minimum_size, Vector2(0.0, ACTION_P1.y),
		"the band is the skeleton's 56 px foot (§19.3)"
	)
	assert_true(foot.is_ancestor_of(remove), "the cluster's home is the pane's foot band")
	assert_eq(remove.custom_minimum_size, ACTION_P1, "REMOVE is P1's 360x56 secondary")
	assert_eq(buy_fit.custom_minimum_size, ACTION_P1, "FIT the 360x56 primary (A26)")
	assert_true(
		buy_fit.get_index() > remove.get_index(), "P2: the primary sits rightmost"
	)
	var fit_rect := foot.get_global_rect()
	var fit_buttons := [remove.get_global_rect(), buy_fit.get_global_rect()]
	var pane := _panel.get_global_rect()
	assert_true(
		absf(fit_rect.end.y - pane.end.y) <= 1.0,
		"the band closes the pane (band %s, pane %s)" % [str(fit_rect), str(pane)]
	)
	for rect: Rect2 in fit_buttons:
		assert_true(fit_rect.encloses(rect), "the pair rides inside the band (%s)" % str(rect))
	## Each mode reserves the band under its own list, so no row scrolls in behind the pair.
	var scroll := _panel.get_node("%BrowserScroll") as Control
	assert_true(
		scroll.get_global_rect().end.y <= fit_rect.position.y + 1.0,
		"the FIT CELLS list stops above the band (its bottom %.1f, band top %.1f)" % [
			scroll.get_global_rect().end.y, fit_rect.position.y
		]
	)
	## The battery mode shows the same band at the same rect - the pair never moves.
	_panel.call(&"set_mode", PanelScript.MODE_BATTERY)
	_settle()
	var battery_rect := foot.get_global_rect()
	assert_true(foot.visible, "F14: the band stays in BATTERY CONFIG")
	assert_true(remove.visible and buy_fit.visible, "F14: with the pair in it")
	assert_true(
		scroll.get_global_rect().end.y <= battery_rect.position.y + 1.0,
		"and the shared menu stops above it too (its bottom %.1f, band top %.1f)" % [
			scroll.get_global_rect().end.y, battery_rect.position.y
		]
	)
	assert_eq(
		battery_rect, fit_rect,
		"F14: the cluster keeps the one place on both modes (battery %s, fit %s)" % [
			str(battery_rect), str(fit_rect)
		]
	)
	assert_true(
		battery_rect.encloses(buy_fit.get_global_rect()),
		"and the primary stays inside the band's pinned rect"
	)
