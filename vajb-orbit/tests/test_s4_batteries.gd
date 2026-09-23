extends McpTestSuite
## Suite s4_batteries: the S4 battery surface of OUTFITTING's FITTED WEAPONS strip and the
## two bulk transactions behind it.
##
## The law is STATION_HUB section 5.1's 2026-09-23 amendment (the strip's battery anatomy),
## 09 section 10 (the battery itself) and CONTRACTS section 16 -- rules 3, 7, 8, 9 and 10 are
## what this suite measures:
##
##  - **rule 3 / AC1** -- one row per battery of identical weapons, grouped by `base_id`, in
##    first-cell order, reading `<n>x <NAME> - W1-W2-W3 - OWNED x<n>`, plus one read-only
##    `W<n> - EMPTY` line per empty W cell. The cell labels are the pane's own W-cell indices,
##    never the component's barrel positions, and a family-less base (`w_mining`) still groups.
##  - **rules 7-8 / AC1** -- `fit_battery` / `clear_battery` round-trip through the strip's
##    two spending actions and its remove, and a batch refused on a later cell restores the
##    **fit and the bag** whole (byte-compared against the snapshots).
##  - **rule 9** -- OUTFITTING's three refusal literals are byte-equivalent to
##    `ui/station/fitting_panel.gd`'s own, and the overload line is built from
##    `fit_legal`'s power numbers; the mandatory wording is never asserted through a battery
##    (it is unreachable for a W cell: `FitData.MANDATORY_SLOT_KEYS` is `[engines, power]`).
##  - **rule 10** -- the strip's node set is fixed: every action and the hull switch rewrite
##    rows by text/visibility/`disabled` and never free or add a node.
##  - **AC3** -- the per-barrel `▸` expander reveals the P2-B1 single-cell lines, each with
##    its own REMOVE, and L78's disclosed reading stands: removal is reachable in every state.
##
## The profile is the shipped autoload, borrowed the way `test_p2b1_outfitting_panel.gd`
## borrows it: `save_path` is repointed at a scratch file before the first mutation, the six
## fields this suite can write are seeded, handed back in `suite_teardown` and flushed while
## the scratch path is still in place, so the owner's `user://profile.cfg` is never written
## (probe hygiene L17, the S3 incident's cure, T-93).
##
## The pane is mounted from the shipped scene with the shipped theme and driven through the
## plates' own `pressed` signals, the wiring the station shell itself uses
## (`ui/screens/station.gd:_connect_panel`).

const PanelScene := preload("res://ui/station/outfitting_panel.tscn")
const PanelScript := preload("res://ui/station/outfitting_panel.gd")
const FittingPanelScript := preload("res://ui/station/fitting_panel.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const Catalog := preload("res://game/station_catalog.gd")
const ModuleData := preload("res://game/module_catalog.gd")
const FitData := preload("res://game/ship_fit.gd")

const PROFILE_PATH := "user://test_s4_batteries.cfg"

const VANGUARD: StringName = &"ship_vanguard"
## The hull the refused-batch regression switches to: the Lancer's two-barrel laser battery is
## the smallest one a bag of one instance cannot cover.
const FIT_HULL: StringName = &"ship_fighter"
const WEAPON_SLOT: StringName = &"weapons"
const STANDARD_ENGINE: StringName = &"e_std"
const STANDARD_REACTOR: StringName = &"p_std"
const LASER: StringName = &"w_laser"
const CANNON: StringName = &"w_cannon"
const RAILGUN: StringName = &"w_railgun"
const MINING: StringName = &"w_mining"

const START_CREDITS := 10000
## The W cells the Vanguard's 08 section 3.2 matrix carries, asserted rather than assumed.
const VANGUARD_W_CELLS := 3

var _profile: Node = null
var _host: Control = null
var _panel: Control = null
var _status: Array[String] = []
var _danger: Array[bool] = []
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_credits := 0
var _previous_fits: Dictionary = {}
var _previous_owned: Array = []
var _previous_modules: Dictionary = {}
var _previous_ammo: Dictionary = {}


func suite_name() -> String:
	return "s4_batteries"


func suite_setup(_ctx: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail_setup("a SceneTree is needed to mount the pane")
		return
	_profile = tree.root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		fail_setup("the PlayerProfile autoload is the pane's store")
		return
	_previous_path = String(_profile.get(&"save_path"))
	_previous_ship = StringName(_profile.call(&"active_ship"))
	_previous_credits = int(_profile.call(&"credits"))
	_previous_fits = _profile.call(&"fits")
	_previous_owned = _profile.call(&"owned_ships")
	_previous_modules = _profile.call(&"modules")
	_previous_ammo = _profile.get(&"_ammo")
	_profile.set(&"save_path", PROFILE_PATH)
	_delete_file(PROFILE_PATH)


func suite_teardown() -> void:
	if _profile == null:
		return
	## Hand every borrowed field back, flush on the scratch path and only then restore the
	## real one, so no dirty flag and no running timer carries a test's account home.
	_profile.set(&"_credits", _previous_credits)
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_fits", _previous_fits)
	_profile.set(&"_owned_ships", _previous_owned)
	_profile.set(&"_modules", _previous_modules)
	_profile.set(&"_ammo", _previous_ammo)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	_delete_file(PROFILE_PATH)
	_profile = null


func setup() -> void:
	_status.clear()
	_danger.clear()
	_seed_account()
	_host = Control.new()
	_host.name = "BatteryHost"
	_host.theme = ThemeRes
	_host.size = _viewport_size()
	_fixture_host().add_child(_host)


func teardown() -> void:
	if _host != null and is_instance_valid(_host):
		_host.free()
	_host = null
	_panel = null


## The fixture account every test starts from: the Vanguard active and owned, no fit, no
## modules, 10 000 CR, written through the private fields the other profile suites hand back
## so no purchase is charged and no signal fires before the pane is mounted.
func _seed_account() -> void:
	var owned: Array[StringName] = [VANGUARD]
	_profile.set(&"_credits", START_CREDITS)
	_profile.set(&"_active_ship", VANGUARD)
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_ammo", {})


## The runner calls every test from inside its own `_ready`, so the root viewport is still
## busy adding the runner scene and `root.add_child(...)` fails. The profile autoload entered
## the tree before the main scene, so it hosts the fixture (the p2b1 suite's own reason).
func _fixture_host() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(NodePath(&"PlayerProfile"))


func _viewport_size() -> Vector2:
	var width := float(ProjectSettings.get_setting("display/window/size/viewport_width", 1920))
	var height := float(ProjectSettings.get_setting("display/window/size/viewport_height", 1080))
	return Vector2(width, height)


func _mount() -> Control:
	_panel = PanelScene.instantiate() as Control
	_host.add_child(_panel)
	_profile.connect(&"profile_changed", Callable(_panel, &"refresh_profile"))
	_panel.connect(&"status_requested", _on_status)
	return _panel


func _on_status(message: String, danger: bool) -> void:
	_status.append(message)
	_danger.append(danger)


## ------------------------------------------------------------------ fixtures and read-backs


## The Vanguard's delivered fit (09 section 9), so every cell write below composes against a
## fit that carries 09 section 7's mandatory set.
func _seed_standard_fit() -> void:
	assert_true(
		bool(_profile.call(&"set_fit", VANGUARD, FitData.standard_fit(VANGUARD))),
		"the hull's standard fit is written"
	)


func _instance(base_id: StringName, rarity: StringName = &"common") -> StringName:
	return StringName(_profile.call(&"add_instance", base_id, rarity, [], []))


func _cells() -> Array:
	return _profile.call(&"fit_for", VANGUARD)[WEAPON_SLOT]


## The hulls the account holds a **stored** fit for: what a refused bulk action must not add to.
func _fits() -> Dictionary:
	return _profile.call(&"fits")


func _module_count(record_id: StringName) -> int:
	return int(_profile.call(&"module_count", record_id))


func _bag_size(base_id: StringName) -> int:
	return (_profile.call(&"instances_of", base_id) as Array).size()


func _name_of(base_id: StringName) -> String:
	return String(ModuleData.module(base_id).get(&"name", "")).to_upper()


## A fit with the named cells set to one base id, for a `fit_legal` reading the test computes
## rather than one it invents.
func _with_cells(fit: Dictionary, indices: Array, base_id: StringName) -> Dictionary:
	var out: Dictionary = fit.duplicate(true)
	var cells: Array = out[WEAPON_SLOT]
	for index: int in indices:
		while cells.size() <= index:
			cells.append("")
		cells[index] = String(base_id)
	out[WEAPON_SLOT] = cells
	return out


func _strip() -> VBoxContainer:
	return _panel.get_node("%FittedStrip") as VBoxContainer


func _strip_row(index: int) -> VBoxContainer:
	return _strip().get_child(index) as VBoxContainer


func _strip_main(index: int) -> HBoxContainer:
	return _strip_row(index).get_node(^"Main") as HBoxContainer


func _strip_text(index: int) -> String:
	return (_strip_main(index).get_node(^"Text") as Label).text


func _strip_control(index: int, control_name: String) -> Button:
	return _strip_main(index).get_node(control_name) as Button


func _cell_line(index: int, line_index: int) -> HBoxContainer:
	var cells := _strip_row(index).get_node(^"Cells") as VBoxContainer
	return cells.get_child(line_index) as HBoxContainer


func _cell_line_text(index: int, line_index: int) -> String:
	var text := _cell_line(index, line_index).get_node_or_null(^"Text") as Label
	return text.text if text != null else ""


func _rows() -> Array:
	return _panel.call(&"strip_rows")


func _press_bulk(index: int, control_name: String) -> void:
	_strip_control(index, control_name).pressed.emit()


func _last_status() -> String:
	return _status[_status.size() - 1] if not _status.is_empty() else ""


func _last_danger() -> bool:
	return _danger[_danger.size() - 1] if not _danger.is_empty() else false


func _delete_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


## Every node under `node`, itself included: the fixed node set's own measurement.
func _count_nodes(node: Node) -> int:
	var total := 1
	for child: Node in node.get_children():
		total += _count_nodes(child)
	return total


## ------------------------------------------------------------------------------ grouping


## AC1, rule 3: the strip groups the active hull's W cells by `base_id`, one row per battery in
## first-cell order, and accounts for every W cell - a battery row for the fitted cells, a
## read-only `W<n> — EMPTY` line for each empty one. The cell labels are the pane's own
## indices, so two cells of one base three cells apart read `W1·W3`.
func test_strip_groups_by_base_id_in_first_cell_order() -> void:
	_seed_standard_fit()
	assert_true(
		bool(_profile.call(&"set_fit_slot", VANGUARD, WEAPON_SLOT, 0, LASER)),
		"W1 holds a laser"
	)
	assert_true(
		bool(_profile.call(&"set_fit_slot", VANGUARD, WEAPON_SLOT, 1, CANNON)),
		"W2 a cannon"
	)
	assert_true(
		bool(_profile.call(&"set_fit_slot", VANGUARD, WEAPON_SLOT, 2, LASER)),
		"and W3 a second laser"
	)
	_profile.call(&"add_module", LASER, 1)
	var panel := _mount()
	var rows := _rows()
	var described := PackedStringArray()
	for row: Dictionary in rows:
		described.append("%s %s %s" % [row[&"kind"], row[&"base"], str(row[&"cells"])])
	print("[s4-batteries] mixed fit rows=%s" % str(described))
	assert_eq(rows.size(), 2, "two batteries, and no empty cell to draw")
	assert_eq(rows[0][&"kind"], &"battery", "the first row is a battery")
	assert_eq(rows[0][&"base"], LASER, "whose first cell (W1) is the laser's")
	assert_eq(rows[0][&"cells"], [0, 2], "covering both of its cells")
	## The bag count is the base's in-bag instances (section 5.1): the delivered laser row the
	## fixture just added is one record, and the other laser is fitted.
	assert_eq(rows[0][&"owned"], 1, "with the bag's own count of that base")
	assert_eq(
		_strip_text(0),
		PanelScript.BATTERY_TEXT % [
			2, _name_of(LASER), "W1·W3", PanelScript.BATTERY_OWNED % 1
		],
		"and the pin's own reading, cells and count"
	)
	assert_eq(rows[1][&"kind"], &"battery", "the second row is the other battery")
	assert_eq(rows[1][&"base"], CANNON, "the cannon the second cell holds")
	assert_eq(rows[1][&"cells"], [1], "covering its one cell")
	assert_eq(rows[1][&"owned"], 0, "with none of that base in the bag")
	assert_eq(
		_strip_text(1),
		PanelScript.BATTERY_TEXT % [
			1, _name_of(CANNON), "W2", PanelScript.BATTERY_OWNED % 0
		],
		"and its own reading"
	)
	## First-cell order, not insertion order: moving one cannon into W1 puts the cannon's row
	## first even though the laser's cells were written first.
	assert_true(
		bool(_profile.call(&"set_fit_slot", VANGUARD, WEAPON_SLOT, 0, CANNON)),
		"a cannon in W1"
	)
	assert_true(bool(_profile.call(&"set_fit_slot", VANGUARD, WEAPON_SLOT, 1, LASER)), "a laser in W2")
	rows = _rows()
	assert_eq(rows[0][&"base"], CANNON, "the battery whose first cell comes first leads")
	assert_eq(rows[0][&"cells"], [0], "and covers its own cell")
	assert_eq(rows[1][&"base"], LASER, "the other battery follows")
	assert_eq(rows[1][&"cells"], [1, 2], "over its own cells")
	assert_eq(panel.call(&"battery_row_index", CANNON), 0, "the row index is readable")
	assert_eq(panel.call(&"battery_row_index", LASER), 1, "for each base id")
	assert_eq(panel.call(&"battery_row_index", MINING), -1, "and -1 for a base with no row")


## Rule 3's second half: a base with **no firing family** still groups, because the grouping
## law is the base id and only the trigger side is family-keyed (`w_mining` resolves to `&""`
## in the component's own list). The strip reads the pane's cell list, so the row is drawn.
func test_a_family_less_base_still_gets_its_battery_row() -> void:
	_seed_standard_fit()
	assert_true(
		bool(_profile.call(&"set_fit_slot", VANGUARD, WEAPON_SLOT, 0, MINING)),
		"the mining laser fits a W cell (09 section 4 item 7)"
	)
	_mount()
	assert_eq(_strip_text(0), "1× %s · W1 · OWNED ×0" % _name_of(MINING), "its row is drawn")
	assert_eq(_rows()[0][&"base"], MINING, "and grouped by its base id")
	assert_true(_strip_control(0, "RemoveAll").visible, "with its bulk actions")
	assert_eq(_strip_text(1), "W2 — EMPTY", "and the empty cells below it")


## The bag figure the row shows and the two spending actions gate on is the base's in-bag
## **instances**, read through `PlayerProfile.instances_of` (STATION_HUB section 5.1,
## CONTRACTS section 16 rule 7). Measured divergence, reported by the builder: a record the
## bag *stacks* (`count` 2 from two `add_module` calls) is one instance and so one cell's
## worth - `module_count` would read 2, and the FITTING pane's own `owned_total` sums counts.
## The strip's figure is the pin's (`instances_of().size()`), and it is exactly the number of
## cells one `fit_battery` batch can pair. Reversal: read the summed count and cap the batch's
## index list at the pair-able instances.
func test_the_bag_figure_is_the_bases_in_bag_instances() -> void:
	_seed_standard_fit()
	_profile.call(&"add_module", LASER, 2)
	_mount()
	assert_eq(_bag_size(LASER), 1, "two units in one record are one instance")
	assert_eq(_module_count(LASER), 2, "while the record's own count is two")
	assert_eq(
		_strip_text(0),
		"1× LASER MKII · W1 · OWNED ×1",
		"so the row shows the instance count, the pin's own reading"
	)
	assert_false(_strip_control(0, "FitAll").disabled, "and FIT ALL is offered")


## ------------------------------------------------------------------------ the bulk actions


## AC1, rules 7-8: `FIT ALL` fills the battery's own cells and then the hull's empty W cells
## with the bag's instances (`fit_battery`, one call), and `REMOVE ALL` empties exactly those
## cells (`clear_battery`), handing every instance back as itself. The bag and the fit are
## asserted at each step, and the strip's own reading follows both.
func test_fit_all_and_remove_all_round_trip_the_bag() -> void:
	_seed_standard_fit()
	var instances: Array[StringName] = []
	for _index in VANGUARD_W_CELLS:
		instances.append(_instance(LASER))
	var panel := _mount()
	## 09 section 9's delivered laser is one battery row with the three bag instances behind
	## it: `FIT ALL` spends `min(owned, cells)` of them over the battery first, then the empty
	## cells (section 5.1).
	assert_eq(
		_strip_text(0),
		"1× LASER MKII · W1 · OWNED ×3",
		"the delivered laser's row, with the bag's three instances"
	)
	assert_false(_strip_control(0, "FitAll").disabled, "FIT ALL is offered")
	_press_bulk(0, "FitAll")
	assert_eq(
		_cells(),
		[String(instances[0]), String(instances[1]), String(instances[2])],
		"the three instances filled W1..W3 in creation order"
	)
	for instance: StringName in instances:
		assert_eq(_module_count(instance), 0, "every instance is out of the bag while fitted")
	assert_eq(_strip_text(0), "3× LASER MKII · W1·W2·W3 · OWNED ×1", "one row, three barrels")
	## The delivered base-keyed laser the first cell displaced came back as its own unit
	## (`_bank_entry`'s own rule, unchanged by this wave), which is what the row's count shows.
	assert_eq(_bag_size(LASER), 1, "the displaced delivered module is the one bag instance")
	assert_eq(_strip_lines_shown(), 1, "and no W cell is left empty")
	assert_eq(_last_status(), PanelScript.STATUS_FIT_ALL % [3, "LASER MKII"], "the pinned-format success")
	assert_false(_last_danger(), "success is never the danger colour")
	_press_bulk(0, "RemoveAll")
	assert_eq(_cells(), ["", "", ""], "REMOVE ALL emptied exactly the battery's cells")
	for instance: StringName in instances:
		assert_eq(_module_count(instance), 1, "every instance is back as itself")
	assert_eq(_strip_lines_shown(), VANGUARD_W_CELLS, "three read-only empty lines now")
	assert_eq(_strip_text(0), "W1 — EMPTY", "the first of them")
	assert_eq(_strip_control(0, "RemoveAll").visible, false, "with no control to press")
	assert_eq(_last_status(), PanelScript.STATUS_REMOVED % "LASER MKII", "and the remove's success")
	assert_eq(_credits_value(), START_CREDITS, "neither batch costs credits")


## The strip's rendered row count, as `strip_rows()` sees it.
func _strip_lines_shown() -> int:
	return _rows().size()


func _credits_value() -> int:
	return int(_profile.call(&"credits"))


## `SWAP ALL` re-seats each of the battery's cells with the next bag instance of the same base
## (`fit_battery` over the battery's own index list, section 5.1), the displaced instance
## returning to the bag.
func test_swap_all_reseats_the_battery_with_the_bag_instance() -> void:
	var fitted := _instance(LASER)
	assert_true(
		bool(_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 0, fitted)),
		"the first instance fits W1"
	)
	var spare := _instance(LASER, &"rare")
	var panel := _mount()
	assert_eq(_strip_text(0), "1× LASER MKII · W1 · OWNED ×1", "one fitted, one spare")
	assert_false(_strip_control(0, "SwapAll").disabled, "SWAP ALL is offered")
	_press_bulk(0, "SwapAll")
	assert_eq(String(_cells()[0]), String(spare), "the spare instance is in the cell")
	assert_eq(_module_count(spare), 0, "and it left the bag")
	assert_eq(_module_count(fitted), 1, "while the displaced instance came back")
	assert_eq(_bag_size(LASER), 1, "one instance in the bag either way")
	assert_eq(_credits_value(), START_CREDITS, "swapping is free at the station")
	assert_eq(
		_last_status(),
		PanelScript.STATUS_SWAP_ALL % [1, "LASER MKII"],
		"and the pane reports it"
	)


## A base the strip's hull does not carry has no battery row, so no bulk action can address
## it: both wrappers answer false and write nothing.
func test_bulk_actions_refuse_a_base_the_strip_is_not_showing() -> void:
	_seed_standard_fit()
	var panel := _mount()
	var fit_before: Dictionary = _profile.call(&"fit_for", VANGUARD)
	assert_false(bool(panel.call(&"fit_all_battery", MINING)), "FIT ALL for a battery with no row")
	assert_false(bool(panel.call(&"swap_all_battery", MINING)), "SWAP ALL for it")
	assert_false(bool(panel.call(&"remove_all_battery", MINING)), "and REMOVE ALL")
	assert_eq(_profile.call(&"fit_for", VANGUARD), fit_before, "nothing was written")


## ------------------------------------------------------------------- the batch's atomicity


## AC1, rules 7-8: a batch whose **third** cell is refused rolls the whole thing back - the fit
## and the bag both, through the public `set_fit`/`set_modules`. The refusal is measured, not
## assumed: two railguns fit this hull's budget and three do not, so the batch necessarily
## wrote two cells before it was refused, and a fit-only rollback would leave their two
## instances stranded at `count` 0 (the L80 class).
func test_a_refused_batch_restores_the_fit_and_the_bag() -> void:
	_seed_standard_fit()
	var instances: Array[StringName] = []
	for _index in VANGUARD_W_CELLS:
		instances.append(_instance(RAILGUN))
	var fit_before: Dictionary = _profile.call(&"fit_for", VANGUARD)
	var bag_before: Dictionary = _profile.call(&"modules")
	var standard := FitData.standard_fit(VANGUARD)
	assert_true(
		bool(FitData.fit_legal(VANGUARD, _with_cells(standard, [0, 1], RAILGUN))[&"legal"]),
		"two railguns fit the Vanguard's power budget"
	)
	assert_false(
		bool(FitData.fit_legal(VANGUARD, _with_cells(standard, [0, 1, 2], RAILGUN))[&"legal"]),
		"three do not, so the third cell is the one that refuses"
	)
	assert_false(
		bool(_profile.call(&"fit_battery", VANGUARD, RAILGUN, [0, 1, 2])),
		"so the batch is refused"
	)
	assert_eq(_profile.call(&"fit_for", VANGUARD), fit_before, "the fit is back, byte for byte")
	assert_eq(_profile.call(&"modules"), bag_before, "and so is the bag")
	for instance: StringName in instances:
		assert_eq(_module_count(instance), 1, "no instance is stranded at count 0")
	assert_eq(_bag_size(RAILGUN), VANGUARD_W_CELLS, "and the bag still offers all three")


## The guards that answer before the first write: a hull with no W cells, an index outside
## `0 .. slot_capacity-1`, a repeated index, and more cells than the bag has instances. None of
## them touches the fit or the bag.
func test_the_batchs_guards_write_nothing() -> void:
	_seed_standard_fit()
	var instance := _instance(LASER)
	var fit_before: Dictionary = _profile.call(&"fit_for", VANGUARD)
	var bag_before: Dictionary = _profile.call(&"modules")
	assert_false(
		bool(_profile.call(&"fit_battery", VANGUARD, LASER, [0, 1])),
		"one instance cannot fill two cells"
	)
	assert_false(bool(_profile.call(&"fit_battery", VANGUARD, LASER, [99])), "an index past the cells")
	assert_false(bool(_profile.call(&"fit_battery", VANGUARD, LASER, [0, 0])), "a repeated cell")
	assert_false(bool(_profile.call(&"fit_battery", VANGUARD, LASER, [])), "no cells at all")
	assert_false(bool(_profile.call(&"fit_battery", &"ship_none", LASER, [0])), "a hull outside the nine")
	assert_eq(_profile.call(&"fit_for", VANGUARD), fit_before, "the fit never moved")
	assert_eq(_profile.call(&"modules"), bag_before, "nor the bag")
	assert_eq(_module_count(instance), 1, "the instance is still in the bag")
	assert_false(
		bool(_profile.call(&"clear_battery", VANGUARD, RAILGUN)),
		"and a remove for a base the hull does not hold refuses"
	)
	assert_eq(_profile.call(&"fit_for", VANGUARD), fit_before, "writing nothing either")


## `clear_battery` empties **exactly** the cells of the named base: a hull holding two bases
## keeps the other one fitted, and the emptied cells come back as their own instances.
func test_clear_battery_empties_only_the_named_bases_cells() -> void:
	_seed_standard_fit()
	var laser := _instance(LASER)
	var cannon := _instance(CANNON)
	assert_true(bool(_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 0, laser)), "a laser in W1")
	assert_true(bool(_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 1, cannon)), "a cannon in W2")
	assert_true(bool(_profile.call(&"clear_battery", VANGUARD, LASER)), "the laser's battery empties")
	assert_eq(_cells()[0], "", "W1 is empty")
	assert_eq(String(_cells()[1]), String(cannon), "and the cannon is untouched")
	assert_eq(_module_count(laser), 1, "the laser's instance is back")
	assert_eq(_module_count(cannon), 0, "the cannon's is still fitted")


## ---------------------------------------------------------------------- the refusal copy


## Rule 9: OUTFITTING's three literals are byte-equivalent to the FITTING pane's own (the
## L116 precedent, since no S4 worker owns that file), and the mandatory one is carried for
## the set's completeness only - it is unreachable for a W cell and no test asserts it through
## a battery. `FitData.MANDATORY_SLOT_KEYS` is the measurement behind that.
func test_the_three_refusal_literals_are_byte_equivalent_to_fitting_panel() -> void:
	assert_eq(
		PanelScript.REFUSAL_OVERLOAD,
		FittingPanelScript.REFUSAL_OVERLOAD,
		"the overload format is the FITTING pane's, byte for byte"
	)
	assert_eq(
		PanelScript.REFUSAL_MANDATORY,
		FittingPanelScript.REFUSAL_MANDATORY,
		"so is the mandatory wording"
	)
	assert_eq(
		PanelScript.REFUSAL_FIT_ILLEGAL,
		FittingPanelScript.REFUSAL_FIT_ILLEGAL,
		"and the catch-all"
	)
	assert_eq(
		FitData.MANDATORY_SLOT_KEYS,
		[&"engines", &"power"] as Array[StringName],
		"the mandatory set holds no W key, which is why the wording is unreachable here"
	)


## The overload line renders with `fit_legal`'s own numbers and the batch writes nothing: a
## railgun battery the hull cannot power, with three bag instances behind it, is refused by the
## strip's own preview before any cell is written (CONTRACTS section 13 rule 6).
func test_the_overload_refusal_renders_fit_legals_own_numbers() -> void:
	_seed_standard_fit()
	assert_true(
		bool(_profile.call(&"set_fit_slot", VANGUARD, WEAPON_SLOT, 0, RAILGUN)),
		"a railgun is fitted in W1"
	)
	var instances: Array[StringName] = []
	for _index in VANGUARD_W_CELLS:
		instances.append(_instance(RAILGUN))
	var panel := _mount()
	assert_eq(_strip_text(0), "1× %s · W1 · OWNED ×3" % _name_of(RAILGUN), "the battery's row")
	## The line the pane must render, computed from the same `fit_legal` the profile re-checks.
	var legal := FitData.fit_legal(
		VANGUARD, _with_cells(FitData.standard_fit(VANGUARD), [0, 1, 2], RAILGUN)
	)
	assert_false(bool(legal[&"legal"]), "three railguns exceed the Vanguard's output")
	var power: Dictionary = legal[&"power"]
	var expected := PanelScript.REFUSAL_OVERLOAD % [
		int(power[&"draw"]), int(power[&"out"]), int(power[&"draw"]) - int(power[&"out"])
	]
	var fit_before: Dictionary = _profile.call(&"fit_for", VANGUARD)
	var bag_before: Dictionary = _profile.call(&"modules")
	_press_bulk(0, "FitAll")
	assert_eq(_last_status(), expected, "the footer carries the pin's overload line")
	assert_true(_last_danger(), "in the danger colour")
	print(
		"[s4-batteries] overload line=%s (fit_legal draw=%d out=%d, over by %d) | cells=%s"
		% [
			_last_status(),
			int(power[&"draw"]),
			int(power[&"out"]),
			int(power[&"draw"]) - int(power[&"out"]),
			str(_cells()),
		]
	)
	assert_eq(_profile.call(&"fit_for", VANGUARD), fit_before, "and the fit never moved")
	assert_eq(_profile.call(&"modules"), bag_before, "nor the bag")
	for instance: StringName in instances:
		assert_eq(_module_count(instance), 1, "every instance is still in the bag")
	## The third wording is the catch-all, and it is the one a batch the **preview** passed
	## renders - `fit_battery`'s own guard answering first (measured by the next test).
	assert_eq(PanelScript.REFUSAL_FIT_ILLEGAL, "REFUSED · FIT ILLEGAL", "the pin's third wording")


## The catch-all is reachable through the strip: `SWAP ALL` passes the battery's **own** index
## list (section 5.1 has no `min(owned, cells)` for it, unlike `FIT ALL`), so a bag that cannot
## cover every barrel is refused by `fit_battery`'s instance-count guard after the legality
## preview passed - the batch writes nothing and the footer carries the catch-all.
func test_swap_all_refuses_a_bag_that_cannot_cover_the_battery() -> void:
	_seed_standard_fit()
	var instances: Array[StringName] = []
	for _index in VANGUARD_W_CELLS:
		instances.append(_instance(LASER))
	for index in VANGUARD_W_CELLS:
		assert_true(
			bool(_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, index, instances[index])),
			"a three-barrel laser battery is fitted"
		)
	var spare := _instance(LASER)
	var panel := _mount()
	## The bag holds two instances behind three barrels: the delivered module the first cell
	## displaced (`_bank_entry`'s own rule) and the spare this fixture just minted - still
	## fewer than the battery's cells, which is what the guard refuses.
	assert_eq(
		_strip_text(0),
		"3× LASER MKII · W1·W2·W3 · OWNED ×2",
		"two instances behind a three-barrel battery"
	)
	assert_false(_strip_control(0, "SwapAll").disabled, "so SWAP ALL is offered")
	var cells_before: Array = _cells()
	var bag_before: Dictionary = _profile.call(&"modules")
	_press_bulk(0, "SwapAll")
	assert_eq(_last_status(), PanelScript.REFUSAL_FIT_ILLEGAL, "and the footer carries the catch-all")
	assert_true(_last_danger(), "in the danger colour")
	assert_eq(_cells(), cells_before, "two instances cannot re-seat three barrels: nothing was written")
	assert_eq(_profile.call(&"modules"), bag_before, "and the bag is untouched")
	assert_eq(_module_count(spare), 1, "the spare is still in the bag")
	assert_eq(_bag_size(LASER), 2, "and the delivered module the batch would have displaced too")
	for instance: StringName in instances:
		assert_eq(_module_count(instance), 0, "and no fitted barrel was disturbed")


## The refused-batch regression (S4-H4, the review's F2): a bulk action that refuses must leave
## the hull holding **no** stored fit if it held none. `fits()` is where the pin's "writing
## nothing" (`CONTRACTS` section 16 rules 7-8) is measured, and the pane's seed exists only to
## give the composed transactions a fit to compose against, so a refusal has to drop it again.
## Measured before the fix: a fresh Lancer with one laser instance behind its two-barrel battery
## refused with the catch-all **and** gained a stored fit the batch's own rollback could not undo
## (it restores to the state the batch started from, which was the seeded one).
func test_a_refused_bulk_action_leaves_no_stored_fit() -> void:
	var owned: Array[StringName] = [VANGUARD, &"ship_fighter"]
	_profile.set(&"_owned_ships", owned)
	assert_true(bool(_profile.call(&"set_active_ship", &"ship_fighter")), "the Lancer is active")
	assert_false(_fits().has(FIT_HULL), "and the account holds no fit for it")
	var instance := _instance(LASER)
	var panel := _mount()
	assert_eq(_strip_text(0), "2× LASER MKII · W1·W2 · OWNED ×1", "two barrels, one bag instance")
	assert_false(_strip_control(0, "SwapAll").disabled, "so SWAP ALL is offered")
	_press_bulk(0, "SwapAll")
	assert_eq(
		_last_status(),
		PanelScript.REFUSAL_FIT_ILLEGAL,
		"one instance cannot re-seat two barrels: the catch-all, after the preview passed"
	)
	assert_true(_last_danger(), "in the danger colour")
	assert_false(_fits().has(FIT_HULL), "and the refusal left the hull holding no stored fit")
	assert_eq(_bag_size(LASER), 1, "with the bag untouched")
	## The seed the fix keeps is not a refusal's, though: `FIT ALL` spends `min(owned, cells)` and
	## a hull that held no stored fit gains the one its committed batch writes.
	_press_bulk(0, "FitAll")
	assert_eq(_last_status(), PanelScript.STATUS_FIT_ALL % [1, "LASER MKII"], "the legal batch lands")
	assert_true(_fits().has(FIT_HULL), "and it does leave a stored fit behind")
	assert_eq(
		String(_profile.call(&"fit_for", FIT_HULL)[WEAPON_SLOT][0]),
		String(instance),
		"holding the instance the batch fitted"
	)


## -------------------------------------------------------------------- the expander (AC3)


## AC3: the `▸` expander reveals the battery's cells as the P2-B1 single-cell lines, each with
## its own REMOVE, and the single-cell action still writes the composed `clear_fit_slot` - so
## L78's disclosed reading stands (a cell carries REMOVE in every state, whether or not the
## hull has empty W cells) and the flag survives the transaction it is used for.
func test_the_expander_reveals_every_single_cell_action() -> void:
	var first := _instance(LASER)
	var second := _instance(LASER)
	assert_true(
		bool(_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 0, first)),
		"the first instance is in W1"
	)
	assert_true(
		bool(_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 2, second)),
		"and the second in W3, leaving W2 empty"
	)
	var panel := _mount()
	var rows := _rows()
	assert_eq(rows.size(), 2, "one battery row and one empty line")
	assert_eq(rows[0][&"cells"], [0, 2], "the battery covers W1 and W3")
	assert_false(panel.call(&"expanded", LASER), "the expander starts closed")
	assert_eq(_cell_line_text(0, 0), "", "so no single-cell line is rendered")
	assert_false(_cell_line(0, 0).visible, "and none is visible")
	assert_true(bool(panel.call(&"toggle_expander", LASER)), "the battery row has an expander")
	assert_true(panel.call(&"expanded", LASER), "which is open now")
	assert_true(_cell_line(0, 0).visible, "so the first cell line is shown")
	assert_eq(_cell_line_text(0, 0), "W1 LASER MKII", "naming its own cell (the pane's index)")
	assert_true(_cell_line(0, 1).visible, "and the second")
	assert_eq(_cell_line_text(0, 1), "W3 LASER MKII", "naming W3, its own cell")
	assert_false(_cell_line(0, 2).visible, "a third line the battery does not have stays hidden")
	## L78's reading: every revealed cell carries REMOVE although W2 is empty.
	var remove := _cell_line(0, 0).get_node(^"Remove") as Button
	assert_true(remove.visible, "a revealed cell carries REMOVE")
	assert_false(remove.disabled, "enabled, so removal is never unreachable")
	remove.pressed.emit()
	assert_eq(_cells()[0], "", "the single-cell REMOVE emptied W1")
	assert_eq(_module_count(first), 1, "and handed that instance back")
	assert_eq(String(_cells()[2]), String(second), "while W3's barrel is untouched")
	rows = _rows()
	assert_eq(rows.size(), 3, "the strip re-groups: one barrel, then two empty lines")
	assert_eq(rows[0][&"cells"], [2], "the battery is the W3 barrel now")
	assert_eq(rows[1][&"kind"], &"empty", "and W1 is an empty line")
	assert_eq(_strip_text(1), "W1 — EMPTY", "reading the pin's own words")
	assert_true(panel.call(&"expanded", LASER), "the expander survived the write it made")
	assert_eq(_cell_line_text(0, 0), "W3 LASER MKII", "so its first line names the new first cell")
	assert_false(bool(panel.call(&"toggle_expander", CANNON)), "a base with no row has no expander")


## ------------------------------------------------------------------ the fixed node set


## Rule 10: the strip's node set is fixed. Both a write (which re-groups every row) and a hull
## switch rewrite rows by text/visibility/`disabled` and never free or add a node, because the
## profile emits `profile_changed` from inside the handler that started the write.
func test_the_strip_never_rebuilds_its_nodes() -> void:
	_seed_standard_fit()
	var instances: Array[StringName] = []
	for _index in VANGUARD_W_CELLS:
		instances.append(_instance(LASER))
	var panel := _mount()
	var strip := _strip()
	var count := strip.get_child_count()
	assert_eq(count, PanelScript._max_weapon_cells(), "one pre-built row per W cell of the widest hull")
	print(
		"[s4-batteries] fixed strip: %d rows, %d nodes (%d per row)"
		% [count, _count_nodes(strip), _count_nodes(strip) / maxi(1, count)]
	)
	var before: Array[Node] = []
	for child: Node in strip.get_children():
		before.append(child)
	assert_true(bool(panel.call(&"toggle_expander", LASER)), "open the battery's expander")
	_press_bulk(0, "FitAll")
	assert_eq(_cells().size(), VANGUARD_W_CELLS, "the batch re-grouped every row")
	assert_eq(strip.get_child_count(), count, "and the node count never moved")
	for index in before.size():
		assert_true(
			is_same(strip.get_child(index), before[index]),
			"row %d is the same node it was" % index
		)
	## A hull switch is the same story: the Lancer has two W cells, the widest hull has seven.
	var owned: Array[StringName] = [VANGUARD, &"ship_fighter"]
	_profile.set(&"_owned_ships", owned)
	assert_true(bool(_profile.call(&"set_active_ship", &"ship_fighter")), "switch the active hull")
	assert_eq(strip.get_child_count(), count, "the node set is unchanged")
	for index in before.size():
		assert_true(
			is_same(strip.get_child(index), before[index]),
			"row %d is the same node" % index
		)


## The strip's focus order (STATION_HUB section 5.1): a battery row is `▸`, then `FIT ALL`,
## `REMOVE ALL`, `SWAP ALL`, in that sibling order - so Tab walks it - and `focus_primary`
## lands on the row's first reachable control. An empty-cell line carries none, so it is
## skipped and the ammo rows follow.
func test_focus_order_is_the_expander_then_the_three_bulk_actions() -> void:
	_seed_standard_fit()
	var panel := _mount()
	var names := PackedStringArray()
	for child: Node in _strip_main(0).get_children():
		names.append(child.name)
	assert_eq(
		names,
		PackedStringArray(["Expander", "Text", "FitAll", "RemoveAll", "SwapAll"]),
		"the pin's own order, sibling for sibling"
	)
	panel.call(&"focus_primary")
	assert_true(
		_strip_control(0, "Expander").has_focus(),
		"the first focus entry of the first battery row is its expander"
	)
	## With every battery removed the strip is all read-only empty lines, so the pane's focus
	## falls through to the ammo rows.
	_press_bulk(0, "RemoveAll")
	panel.call(&"focus_primary")
	assert_false(_strip_control(0, "Expander").visible, "the empties carry no control")
	var ammo := panel.get_node("%OutfittingRows") as VBoxContainer
	assert_true((ammo.get_child(0) as Button).has_focus(), "so the first ammo row takes focus")
