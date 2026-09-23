@tool
extends McpTestSuite
## Suite s5_batteries_v2: AC3 of the S5 wave -- the ARMORY pane's drag-and-drop battery
## composition, the slowest-member salvo gate in flight, and save v7's rack migration.
##
## The law is 09 section 11 (batteries v2), STATION_HUB section 5.11 (the pane's rework and
## the rename) and CONTRACTS section 17; the acceptance this suite measures:
##
##  - **the rename** -- `ARMORY` is the rail entry's label and the pane's own title, the
##    pane ships as `armory_panel.{gd,tscn}` and the OUTFITTING files are gone.
##  - **the drag interface** -- a left inventory list and racks `B1..B7`; a drop installs
##    into the rack's next free W cell through the composed transactions, a within/between
##    rack drop re-orders and swaps, a `✕` returns a barrel to the inventory, and **every
##    refusal writes nothing** (the fit, the bag and the rack record byte-compared).
##  - **the salvo gate** -- one trigger releases every armed barrel of a mixed
##    laser+cannon rack and the next salvo waits for the slowest member's cycle
##    (`max(members' cadence)`); the dry/empty rules stay per barrel.
##  - **save v7** -- a v6 file's fitted weapons are grouped by `base_id`, cells ascending,
##    in memory at load, idempotently, and the record is persisted by the next write.
##
## **AC3's own numbers, measured and reported** (`S5-J3_report.md`): the acceptance asks for
## "a 0.6 s + 1.5 s pair cycles at 1.5 s". No shipped family states a 1.5 s cadence --
## `interval_of` answers 0.6 for the cannon, 1.2 for the rocket, 0.0 for both instant
## families and 0.0 for the mine's drop -- so a 0.6+1.5 pair cannot be built out of the
## family table, and this suite measures the rule instead with the pairs the table has:
## laser+cannon reads 0.6 (the cannon's window; the laser states none) and cannon+rocket
## reads 1.2 (the rocket's interval), each one `max(members' cadence)`.
##
## The profile is the shipped autoload, borrowed the way `test_s4_batteries.gd` borrows it:
## `save_path` is repointed at a scratch file before the first mutation, every field this
## suite can write is seeded, handed back in `suite_teardown` and flushed while the scratch
## path is still in place, so the owner's `user://profile.cfg` is never written (probe
## hygiene L17, the S3 incident's cure, T-93).

const PanelScene := preload("res://ui/station/armory_panel.tscn")
const PanelScript := preload("res://ui/station/armory_panel.gd")
const StationScript := preload("res://ui/screens/station.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const ModuleData := preload("res://game/module_catalog.gd")
const FitData := preload("res://game/ship_fit.gd")
const WeaponScript := preload("res://game/weapons.gd")
const PlayerStateScript := preload("res://game/player_state.gd")

const GameScene := preload("res://game/game.tscn")
const HUD_NODE: StringName = &"Hud"
const AUDIO_SERVICE: StringName = &"AudioManager"

const PROFILE_PATH := "user://test_s5_batteries_v2.cfg"
const SECTION := "profile"

const VANGUARD: StringName = &"ship_vanguard"
const WEAPON_SLOT: StringName = &"weapons"
const ENGINE_SLOT: StringName = &"engines"
const POWER_SLOT: StringName = &"power"
const LASER: StringName = &"w_laser"
const CANNON: StringName = &"w_cannon"
const ROCKET: StringName = &"w_rocket"
const RAILGUN: StringName = &"w_railgun"

const START_CREDITS := 10000
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
var _previous_batteries: Dictionary = {}
## The flight rig's own state: the mounted component, the pooled account it spends and the
## holder that keeps both inside the tree for the length of one test.
var _guns: Node2D = null
var _state: PlayerState = null
var _holder: Node2D = null
var _scene: Node2D = null
## The audio pools' round-robin cursors, saved and restored around every test: the rig fires
## real cues (the cannon's take and the beam's bed), and `test_weapon_fx_f1.gd` asserts the
## laser pool's take order a few suites later - a cue this suite leaves spent would move that
## suite's first take (measured: it did, which is the engine2_weapons suite's own reason for
## the same hygiene).
var _pool_state: Dictionary = {}
var _had_pool_state := false


func suite_name() -> String:
	return "s5_batteries_v2"


func suite_setup(_ctx: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail_setup("a SceneTree is needed")
		return
	_profile = tree.root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		fail_setup("the PlayerProfile autoload is the store under test")
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


## The fixture account every test starts from: the Vanguard active and owned, no fit, no
## modules, no racks, 10 000 CR.
func setup() -> void:
	_status.clear()
	_danger.clear()
	_free_scene()
	_free_rig()
	_save_pools()
	_profile.set(&"_credits", START_CREDITS)
	_profile.set(&"_active_ship", VANGUARD)
	var owned: Array[StringName] = [VANGUARD]
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_ammo", {})
	_profile.set(&"_batteries", {})
	_delete_file(PROFILE_PATH)


func teardown() -> void:
	if _host != null and is_instance_valid(_host):
		_host.free()
	_host = null
	_panel = null
	_free_scene()
	_free_rig()
	_restore_pools()


func _audio() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(NodePath(AUDIO_SERVICE))


func _save_pools() -> void:
	_pool_state = {}
	_had_pool_state = false
	var audio := _audio()
	if audio == null:
		return
	var cursors: Variant = audio.get(&"_pool_next")
	if not cursors is Dictionary:
		return
	_had_pool_state = true
	_pool_state = (cursors as Dictionary).duplicate()


## `Object.get` hands the live dictionary, so the cursors are restored in place.
func _restore_pools() -> void:
	if not _had_pool_state:
		return
	var audio := _audio()
	if audio == null:
		return
	var cursors: Variant = audio.get(&"_pool_next")
	if not cursors is Dictionary:
		return
	var live := cursors as Dictionary
	live.clear()
	live.merge(_pool_state, true)
	_pool_state = {}
	_had_pool_state = false


func _free_scene() -> void:
	if _scene != null and is_instance_valid(_scene):
		_scene.free()
	_scene = null


func _free_rig() -> void:
	if _holder != null and is_instance_valid(_holder):
		_holder.free()
	_holder = null
	_guns = null
	_state = null


## ------------------------------------------------------------------ fixtures and read-backs


func _fixture_host() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(NodePath(&"PlayerProfile"))


func _instance(base_id: StringName) -> StringName:
	return StringName(_profile.call(&"add_instance", base_id, &"common", [], []))


func _cells() -> Array:
	return _profile.call(&"fit_for", VANGUARD)[WEAPON_SLOT]


func _stored() -> Array:
	return _profile.call(&"batteries").get(String(VANGUARD), [])


func _mount() -> Control:
	_host = Control.new()
	_host.name = "ArmoryHost"
	_host.theme = ThemeRes
	_host.size = Vector2(1280.0, 720.0)
	_fixture_host().add_child(_host)
	_panel = PanelScene.instantiate() as Control
	_host.add_child(_panel)
	_profile.connect(&"profile_changed", Callable(_panel, &"refresh_profile"))
	_panel.connect(&"status_requested", _on_status)
	return _panel


func _on_status(message: String, danger: bool) -> void:
	_status.append(message)
	_danger.append(danger)


func _last_status() -> String:
	return _status[_status.size() - 1] if not _status.is_empty() else ""


func _last_danger() -> bool:
	return _danger[_danger.size() - 1] if not _danger.is_empty() else false


func _snapshot() -> Dictionary:
	return {
		&"fit": _profile.call(&"fit_for", VANGUARD),
		&"bag": _profile.call(&"modules"),
		&"racks": _profile.call(&"batteries"),
		&"credits": int(_profile.call(&"credits")),
	}


func _unchanged(before: Dictionary, what: String) -> void:
	assert_eq(_profile.call(&"fit_for", VANGUARD), before[&"fit"], "%s: the fit is byte-identical" % what)
	assert_eq(_profile.call(&"modules"), before[&"bag"], "%s: and the bag" % what)
	assert_eq(_profile.call(&"batteries"), before[&"racks"], "%s: and the rack record" % what)
	assert_eq(int(_profile.call(&"credits")), int(before[&"credits"]), "%s: and the credits" % what)


## One rack's drawn chips, as the pane's own read-back hands them out.
func _rack(panel: Control, index: int) -> Dictionary:
	var rows: Array = panel.call(&"rack_rows")
	return rows[index]


func _barrel_text(panel: Control, rack: int, position: int) -> String:
	var barrels: Array = _rack(panel, rack)[&"barrels"]
	if position < 0 or position >= barrels.size():
		return ""
	return String(barrels[position][&"text"])


## One drop, exactly as the engine's drag would deliver it: the pane's own payload builders
## and its own `drop`, which is the same call `_drop_data` makes.
func _drop_inventory(panel: Control, rack: int, position: int, base_id: StringName) -> bool:
	var payload: Variant = panel.call(&"drag_inventory", base_id)
	return bool(panel.call(&"drop", rack, position, payload))


func _move_barrel(panel: Control, from_rack: int, from_position: int, to_rack: int, to_position: int) -> bool:
	var payload: Variant = panel.call(&"drag_barrel", from_rack, from_position)
	return bool(panel.call(&"drop", to_rack, to_position, payload))


func _delete_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


## ------------------------------------------------------------------------- the rename


## The rail entry and the pane file move together (STATION_HUB section 5.11): the label is
## `ARMORY`, it lives in `ui/screens/station.gd` (the theme carries no label-text constants,
## J0's F3), `MODULE_FILES` loads the renamed scene, and the retired files are gone.
func test_the_rail_says_armory_and_loads_the_renamed_pane() -> void:
	assert_eq(StationScript.MODULE_LABELS[0], "ARMORY", "the rail's first entry is renamed")
	assert_eq(StationScript.MODULE_FILES[0], "armory", "and loads the pane's new file name")
	assert_true(
		ResourceLoader.exists("res://ui/station/armory_panel.tscn"), "the ARMORY scene ships"
	)
	assert_true(
		ResourceLoader.exists("res://ui/station/armory_panel.gd"), "with its script"
	)
	assert_false(
		ResourceLoader.exists("res://ui/station/outfitting_panel.tscn"), "and the old scene is gone"
	)
	assert_false(
		ResourceLoader.exists("res://ui/station/outfitting_panel.gd"), "with its old script"
	)
	assert_eq(
		StationScript.MODULE_LABELS.size(),
		StationScript.MODULE_FILES.size(),
		"the two rail arrays stay the same length"
	)
	## The pane's own title is the same word: a pane whose header disagreed with the rail
	## entry it was loaded from would read as two surfaces.
	var panel := _mount()
	assert_eq(
		String((panel.get_node("PaneHeader/TitleBox/PaneTitle") as Label).text),
		"ARMORY",
		"the pane's title reads the same word as the rail"
	)


## The map grew with the racks (CONTRACTS section 17): `GROUPS_MAX` is 7, `weapon_6` and
## `weapon_7` are read by the flight scene, the HUD's three tables carry seven entries, and
## the pane draws seven racks. One number, three consumers.
func test_groups_max_is_seven_across_its_consumers() -> void:
	assert_eq(WeaponScript.GROUPS_MAX, 7, "GROUPS_MAX 5 -> 7")
	assert_eq(PanelScript.RACK_COUNT, WeaponScript.GROUPS_MAX, "the pane draws one rack per key")
	var hud := load("res://ui/hud/hud.gd") as GDScript
	assert_eq(
		(hud.get_script_constant_map()[&"WEAPON_IDS"] as Array).size(),
		7,
		"the HUD's weapon ids grew to seven"
	)
	assert_eq(
		(hud.get_script_constant_map()[&"WEAPON_LABELS"] as Array).size(),
		7,
		"and so did its labels"
	)
	assert_eq(
		(hud.get_script_constant_map()[&"WEAPON_ICONS"] as Array).size(),
		7,
		"and its icons"
	)
	var game := load("res://game/game.gd") as GDScript
	assert_eq(
		(game.get_script_constant_map()[&"WEAPON_ACTIONS"] as Array).size(),
		7,
		"the flight scene reads weapon_1..7"
	)
	assert_eq(
		String(game.get_script_constant_map()[&"WEAPON_ACTIONS"][6]), "weapon_7", "through the seventh key"
	)
	## The two new icons are the module cuts the owner named (railgun and mining), not a
	## seventh weapon cut: the table's last two entries answer those files.
	var icons: Array = hud.get_script_constant_map()[&"WEAPON_ICONS"]
	assert_true(
		String((icons[5] as Texture2D).resource_path).ends_with("icon_module_w_railgun.svg"),
		"the sixth entry is the railgun module glyph"
	)
	assert_true(
		String((icons[6] as Texture2D).resource_path).ends_with("icon_module_w_mining.svg"),
		"and the seventh the mining laser's"
	)


## ------------------------------------------------------------- the drag composition


## The pane's drop zones: a left inventory list and seven racks, and a drop installs into the
## rack's next free W cell through the composed transaction - the cell holds the bag's
## instance, the record names the rack, and the pane's own read-back follows both.
func test_a_drop_installs_into_the_racks_next_free_cell() -> void:
	var panel := _mount()
	var cannon := _instance(CANNON)
	assert_eq(_rack(panel, 0)[&"cells"], [0], "B1 shows the delivered fit's cell, derived on read")
	assert_true(_drop_inventory(panel, 1, PanelScript.DROP_RACK_BODY, CANNON), "the drop installs")
	assert_eq(String(_cells()[1]), String(cannon), "into the next free W cell (W2)")
	assert_eq(
		_profile.call(&"module_count", cannon), 0, "spending the bag's own instance, not a copy"
	)
	assert_eq(_rack(panel, 1)[&"cells"], [1], "and B2's own read-back follows")
	assert_eq(_barrel_text(panel, 1, 0), "W2 CANNON MKI", "with the chip naming its cell")
	assert_eq(
		_last_status(),
		PanelScript.STATUS_INSTALLED % ["CANNON MKI", "B2"],
		"and the pane reports it in its own wording"
	)
	assert_false(_last_danger(), "success is never the danger colour")
	## A second drop fills the next free cell (W3) and leaves the record's two racks alone.
	var laser := _instance(LASER)
	assert_true(_drop_inventory(panel, 2, PanelScript.DROP_RACK_BODY, LASER), "another drop")
	assert_eq(String(_cells()[2]), String(laser), "lands in W3")
	assert_eq(_rack(panel, 2)[&"cells"], [2], "recorded in B3")
	assert_eq(_stored(), [[0], [1], [2]], "the record names all three racks")


## Every refusal writes nothing at all (CONTRACTS section 17, S4's rules 7/8): an unowned
## base, a full battery, a drop onto a barrel (that drag is a move), a rack past `B7`, and an
## over-budget candidate. The fit, the bag, the record and the credits are byte-compared.
func test_a_refused_drop_writes_nothing() -> void:
	var panel := _mount()
	_instance(LASER)
	assert_true(_drop_inventory(panel, 0, PanelScript.DROP_RACK_BODY, LASER), "one laser runs in")
	var before := _snapshot()
	## A base the bag holds none of cannot even start a drag: the inventory list only
	## carries owned ids, and its payload builder answers `{}` - so `drop` is handed no
	## payload and the store is untouched.
	assert_true(
		(panel.call(&"drag_inventory", &"w_plasma") as Dictionary).is_empty(),
		"an unowned base drags nothing"
	)
	assert_false(
		_drop_inventory(panel, 0, PanelScript.DROP_RACK_BODY, &"w_plasma"),
		"and a drop carrying no payload is refused"
	)
	_unchanged(before, "an unowned base")
	assert_false(_drop_inventory(panel, 0, 0, LASER), "an inventory weapon dropped on a barrel")
	_unchanged(before, "a drop on a barrel")
	assert_false(
		_drop_inventory(panel, PanelScript.RACK_COUNT, PanelScript.DROP_RACK_BODY, LASER),
		"a rack past B7"
	)
	_unchanged(before, "a rack past B7")
	## Fill the battery: the last free cell takes the last instance, and the next drop has
	## nowhere to go.
	var spare := _instance(LASER)
	assert_true(_drop_inventory(panel, 1, PanelScript.DROP_RACK_BODY, LASER), "the last cell fills")
	assert_eq(
		int(_profile.call(&"free_weapon_cell", VANGUARD)), -1, "so no W cell is free"
	)
	assert_eq(String(_cells()[2]), String(spare), "the spare landed in W3")
	var full := _snapshot()
	_instance(LASER)
	assert_false(
		_drop_inventory(panel, 2, PanelScript.DROP_RACK_BODY, LASER),
		"a drop with every W cell taken"
	)
	assert_eq(
		_last_status(), PanelScript.REFUSAL_W_SLOTS_FULL, "is refused with the P2-B1 wording"
	)
	assert_eq(_profile.call(&"fit_for", VANGUARD), full[&"fit"], "the full battery's fit is untouched")
	assert_eq(_profile.call(&"batteries"), full[&"racks"], "and so is its record")
	## An over-budget candidate: a fresh Cutter's budget is 8 and its delivered fit spends 3,
	## so a railgun fits and the second one does not.
	## A clean two-cell battery for the over-budget case: both trailing W cells are empty,
	## so the two railguns have somewhere to go and the **second** one is the illegal
	## candidate (the Cutter's 8 budget: laser 1 + shield 2 + railgun 3 = 6 fits, +3 does
	## not).
	_profile.call(&"set_fit_slot", VANGUARD, WEAPON_SLOT, 1, "")
	_profile.call(&"set_fit_slot", VANGUARD, WEAPON_SLOT, 2, "")
	_profile.call(&"set_battery_groups", VANGUARD, [[0]])
	_instance(RAILGUN)
	_instance(RAILGUN)
	assert_true(_drop_inventory(panel, 0, PanelScript.DROP_RACK_BODY, RAILGUN), "one railgun fits")
	var loaded := _snapshot()
	assert_false(
		_drop_inventory(panel, 0, PanelScript.DROP_RACK_BODY, RAILGUN),
		"a second railgun is over the budget"
	)
	assert_true(
		_last_status().contains("PWR — OVER BY"), "and the overload line is the pane's own"
	)
	_unchanged(loaded, "an over-budget candidate")


## The within/between-rack drags (09 section 11: "re-orders and swaps"): a barrel dropped
## inside its own rack re-orders it, a barrel dropped onto another rack's barrel swaps the
## two - and neither writes the fit, because a rack is which trigger fires a cell, not what
## the cell holds.
func test_a_barrel_drag_reorders_and_swaps() -> void:
	var panel := _mount()
	var laser := _instance(LASER)
	_instance(LASER)
	var spare := _instance(LASER)
	var cannon := _instance(CANNON)
	assert_true(bool(_profile.call(&"fit_battery", VANGUARD, LASER, [0, 1, 2])), "three barrels")
	assert_true(
		bool(_profile.call(&"set_battery_groups", VANGUARD, [[0, 1, 2]])), "one rack holds all three"
	)
	assert_eq(_rack(panel, 0)[&"cells"], [0, 1, 2], "B1 shows all three chips")
	assert_eq(_barrel_text(panel, 0, 0), "W1 LASER MKII", "the first chip names its own cell")
	assert_true(_move_barrel(panel, 0, 2, 0, 0), "the last barrel dragged to B1's front")
	assert_eq(_stored(), [[2, 0, 1]], "re-orders the rack")
	assert_eq(_barrel_text(panel, 0, 0), "W3 LASER MKII", "and the chips follow the new order")
	assert_eq(
		_last_status(),
		PanelScript.STATUS_MOVED % ["LASER MKII", "B1"],
		"with the pane's own success line"
	)
	## Between racks: one barrel each, then a drag of B1's onto B2's - which swaps them.
	assert_true(
		bool(_profile.call(&"set_battery_groups", VANGUARD, [[0], [2]])), "one barrel per rack"
	)
	_profile.call(&"set_fit_slot", VANGUARD, WEAPON_SLOT, 1, "")
	assert_eq(_profile.call(&"batteries").get(String(VANGUARD), []), [[0], [2]], "the record as written")
	assert_true(_move_barrel(panel, 1, 0, 0, 0), "B2's barrel dragged onto B1's")
	assert_eq(_stored(), [[2], [0]], "the two racks swap their barrels")
	assert_eq(_rack(panel, 0)[&"cells"], [2], "and the read-back follows")
	assert_eq(_rack(panel, 1)[&"cells"], [0], "on both racks")
	## The fit never moved: the barrels are where they always were, only their trigger changed.
	assert_eq(_cells().size(), VANGUARD_W_CELLS, "the hull still has three W cells")
	assert_eq(String(_cells()[0]), String(laser), "W1 holds the first instance still")
	assert_eq(String(_cells()[2]), String(spare), "and W3 the last one the batch paired")
	assert_eq(String(_cells()[1]), "", "with W2 emptied by the fixture above")
	assert_eq(
		int(_profile.call(&"module_count", cannon)), 1, "the cannon never entered the hull at all"
	)


## A barrel dropped on a rack's **body** appends to that rack, and the pane's preview
## (`can_drop`, what the engine asks while the pointer hovers) agrees with the write
## (`drop`) about the address: both name the target rack's end, never the dragged barrel's
## own rack.
func test_a_body_drop_appends_to_the_target_rack() -> void:
	var panel := _mount()
	var laser := _instance(LASER)
	_instance(LASER)
	assert_true(bool(_profile.call(&"fit_battery", VANGUARD, LASER, [0, 1])), "two barrels")
	assert_true(bool(_profile.call(&"set_battery_groups", VANGUARD, [[0], [1]])), "one per rack")
	var payload: Variant = panel.call(&"drag_barrel", 0, 0)
	assert_true(
		bool(panel.call(&"can_drop", 1, PanelScript.DROP_RACK_BODY, payload)),
		"the preview accepts the body drop"
	)
	assert_true(bool(panel.call(&"drop", 1, PanelScript.DROP_RACK_BODY, payload)), "and the drop lands")
	assert_eq(_stored(), [[], [1, 0]], "appended to the target rack's end, its own barrel first")
	assert_eq(_rack(panel, 1)[&"cells"], [1, 0], "and the read-back follows")
	assert_eq(String(_cells()[0]), String(laser), "with the fit untouched")


## The `✕` on a barrel is the pane's one remove: the cell empties, the barrel returns to the
## inventory as itself and the record drops the reference.
func test_the_close_returns_a_barrel_to_the_inventory() -> void:
	var panel := _mount()
	var cannon := _instance(CANNON)
	assert_true(_drop_inventory(panel, 1, PanelScript.DROP_RACK_BODY, CANNON), "a cannon into B2")
	var chip: HBoxContainer = (
		(panel.get_node("%RackRows") as VBoxContainer).get_child(1).get_node(^"Box/Barrels").get_child(0)
	) as HBoxContainer
	(chip.get_node(^"Close") as Button).pressed.emit()
	assert_eq(String(_cells()[1]), "", "the cell is empty")
	assert_eq(_profile.call(&"module_count", cannon), 1, "the instance is back in the bag")
	assert_eq(_rack(panel, 1)[&"cells"], [], "and B2 holds nothing again")
	assert_eq(_stored(), [[0]], "while B1's derived barrel is still referenced")
	assert_eq(_last_status(), PanelScript.STATUS_REMOVED % "CANNON MKI", "the pane reports it")
	assert_false(_last_danger(), "success is never the danger colour")


## ------------------------------------------------------------ the salvo gate in flight


## The rig: the shipped component in a tree (its travelling half needs a world to spawn a
## shot into), handed a composed mixed rack directly. `set_batteries` is the launch's own
## call, in the component's index space (barrel positions).
func _rig(ids: Array, racks: Array) -> Node2D:
	var host := _fixture_host()
	if host == null:
		skip("no PlayerProfile autoload to host the rig")
		return null
	_holder = Node2D.new()
	_holder.name = "S5BatteryRig"
	host.add_child(_holder)
	_guns = WeaponScript.new() as Node2D
	_holder.add_child(_guns)
	_state = PlayerStateScript.new()
	_state.setup()
	_guns.call(&"setup", null, _state)
	var fit: Array[StringName] = []
	for id: Variant in ids:
		fit.append(StringName(id))
	_guns.call(&"set_fitted", fit)
	_guns.call(&"set_batteries", racks)
	_guns.call(&"set_aim_point", Vector2(400.0, 0.0))
	return _guns


## One trigger releases **every** armed barrel of a mixed laser+cannon rack, and the next
## salvo waits for the slowest member's cycle. The pair's own numbers: the cannon's burst
## window is 0.6 s and the laser is an instant family with no cadence at all, so the rack's
## gate is 0.6 s (`max(members' cadence)` = the cannon).
func test_a_mixed_rack_fires_both_barrels_and_gates_on_the_slowest() -> void:
	var guns := _rig([&"w_laser", &"w_cannon"], [[0, 1]])
	if guns == null:
		return
	var slot := WeaponScript.ammo_slot(&"cannon")
	_state.set_ammo(slot, 30)
	assert_eq(guns.call(&"racks"), [[0, 1]], "the composed rack holds both barrels")
	assert_eq(
		guns.call(&"battery_cycle"),
		maxf(WeaponScript.interval_of(&"laser"), WeaponScript.interval_of(&"cannon")),
		"the gate is max(members' cadence)"
	)
	assert_eq(guns.call(&"battery_cycle"), 0.6, "which is the cannon's 0.6 s window")
	var frame := 1.0 / 60.0
	var cannon_marks: Array[int] = []
	var laser_opens := [0]
	## The run's own frame counter, read by the signal handler: a mark is the frame it was
	## fired on, so the gaps below are real periods.
	var tick := [0]
	guns.connect(
		&"shot_fired",
		func(id: StringName) -> void:
			if id == &"cannon":
				cannon_marks.append(tick[0])
			else:
				laser_opens[0] += 1
	)
	## The first salvo: one arm, and both barrels leave on their own strum frames. The
	## offsets are drawn in `[0, BATTERY_STRUM_MS]` ms, so the whole salvo has landed well
	## inside the rack's 0.6 s window.
	## The first salvo: one arm, and both barrels leave on their own strum frames. The
	## offsets are drawn in `[0, BATTERY_STRUM_MS]` ms, so the whole salvo has landed well
	## inside the rack's 0.6 s window.
	guns.call(&"set_firing", true)
	for _frame in 5:
		tick[0] += 1
		guns.call(&"tick", frame)
	assert_eq(cannon_marks.size(), 1, "the cannon left one shot in the pull's own salvo")
	assert_eq(laser_opens[0], 1, "and the laser opened its beam in the same salvo")
	## And the next salvo waits the slowest member's cycle: nothing inside the window.
	while tick[0] < int(round(0.6 / frame)) - 2:
		tick[0] += 1
		guns.call(&"tick", frame)
	assert_eq(cannon_marks.size(), 1, "no salvo inside the battery's window")
	for _frame in 8:
		tick[0] += 1
		guns.call(&"tick", frame)
	print(
		"[s5-batteries] mixed laser+cannon rack: cycle %.3f s, cannon salvos at %s frames"
		% [float(guns.call(&"battery_cycle")), str(cannon_marks)]
	)
	assert_eq(cannon_marks.size(), 2, "the second salvo arrives just past the window")
	## The period is the rack's cycle with the pin's own two sources of slack: the strum's
	## 40 ms draw (2.4 frames) and the cannon's burst window, which can hold a barrel until
	## the next on-window. Six frames (100 ms) covers both.
	assert_true(
		absi(cannon_marks[1] - cannon_marks[0] - int(round(0.6 / frame))) <= 6,
		"and it follows the pull by the rack's own cycle (measured %d frames)"
		% (cannon_marks[1] - cannon_marks[0])
	)
	assert_eq(laser_opens[0], 1, "while the beam barrel opened once for the whole hold")
	assert_eq(_state.ammo[slot], 28, "two salvos spent two rounds of the one cannon pack")
	guns.call(&"set_firing", false)
	guns.call(&"tick", frame)


## The gate over two **non-zero** cycles: a cannon (0.6) plus a rocket (1.2) reads 1.2, which
## is the rule AC3 asks for with the numbers the family table actually states.
func test_a_rack_gates_on_the_slowest_of_two_travelling_members() -> void:
	var guns := _rig([&"w_cannon", &"w_rocket"], [[0, 1]])
	if guns == null:
		return
	_state.set_ammo(WeaponScript.ammo_slot(&"cannon"), 30)
	_state.set_ammo(WeaponScript.ammo_slot(&"rocket"), 30)
	assert_eq(WeaponScript.interval_of(&"cannon"), 0.6, "the cannon's burst cycle")
	assert_eq(WeaponScript.interval_of(&"rocket"), 1.2, "the rocket's interval")
	assert_eq(guns.call(&"battery_cycle"), 1.2, "the rack waits for its slowest member")
	var frame := 1.0 / 60.0
	var marks: Array[int] = []
	var counter := [0]
	guns.connect(
		&"shot_fired",
		func(id: StringName) -> void:
			if id == &"cannon":
				marks.append(counter[0])
	)
	guns.call(&"set_firing", true)
	for index in int(3.0 / frame):
		counter[0] = index
		guns.call(&"tick", frame)
	var gaps := PackedStringArray()
	for index in range(1, marks.size()):
		gaps.append(str(marks[index] - marks[index - 1]))
	print(
		"[s5-batteries] cannon+rocket rack: cycle 1.2 s, cannon salvos at %s (gaps %s frames)"
		% [str(marks), gaps]
	)
	assert_true(marks.size() >= 2, "the cannon streams inside the rack's slower cycle")
	for index in range(1, marks.size()):
		## The same slack, and this rack is the decisive one: the alternative S4 rule (each
		## barrel on its own cadence) would put the cannon on 0.6 s / 36 frames, which 72 +/- 6
		## excludes by a wide margin.
		assert_true(
			absi(marks[index] - marks[index - 1] - int(round(1.2 / frame))) <= 6,
			"every salvo waits the rack's 1.2 s cycle (measured gap %d frames)"
			% (marks[index] - marks[index - 1])
		)
	guns.call(&"set_firing", false)
	guns.call(&"tick", frame)


## The dry/empty rules stay **per barrel** (CONTRACTS section 16 rule 4's carve-outs, kept by
## section 17): a barrel whose pack is empty is dry for itself and never holds the rest of its
## rack back.
func test_a_dry_barrel_does_not_hold_its_rack_back() -> void:
	var guns := _rig([&"w_laser", &"w_cannon"], [[0, 1]])
	if guns == null:
		return
	var slot := WeaponScript.ammo_slot(&"cannon")
	_state.set_ammo(slot, 0)
	var dries := [0]
	guns.connect(&"dry_fired", func(_id: StringName) -> void: dries[0] += 1)
	guns.call(&"set_firing", true)
	## The strum may hold a barrel back up to its 40 ms ceiling, so the pull is stepped a
	## tenth of a second before the reading (2.4 frames of jitter, six frames of room).
	for _frame in 6:
		guns.call(&"tick", 1.0 / 60.0)
	assert_eq(dries[0], 1, "the empty cannon reads dry once for the pull")
	assert_eq(_state.ammo[slot], 0, "and spends nothing")
	## The laser barrel is untouched by the cannon's dry state: its beam is open and drawing.
	assert_true(
		bool(guns.call(&"is_firing")), "the trigger is still held"
	)
	assert_eq(
		_guns.call(&"selected_rack"), [0, 1], "the rack is still the composed pair"
	)
	## A laser-only rack with the same empty pack is not dry at all: the dry state is the
	## barrel's own family's.
	_free_rig()
	var laser_guns := _rig([&"w_laser"], [[0]])
	if laser_guns == null:
		return
	_state.set_ammo(slot, 0)
	var laser_dries := [0]
	laser_guns.connect(&"dry_fired", func(_id: StringName) -> void: laser_dries[0] += 1)
	laser_guns.call(&"set_firing", true)
	for _frame in 6:
		laser_guns.call(&"tick", 1.0 / 60.0)
	assert_eq(laser_dries[0], 0, "the beam barrel never reads dry on the cannon's empty pack")


## ------------------------------------------------------------------ the v6 -> v7 migration


## Save v7's flag day (CONTRACTS section 17): a v6 file's fitted weapons are grouped by
## `base_id`, cells ascending, **in memory at load** - the fitting arrays' own "never
## rewritten at load" rule - idempotently, and the next real write persists the record.
func test_a_v6_file_migrates_its_racks_and_the_next_write_persists_them() -> void:
	var fixture := ConfigFile.new()
	fixture.set_value(SECTION, "save_version", 6)
	fixture.set_value(SECTION, "credits", 2500)
	fixture.set_value(SECTION, "owned_ships", ["ship_vanguard"])
	fixture.set_value(SECTION, "active_ship", "ship_vanguard")
	fixture.set_value(SECTION, "modules", {})
	fixture.set_value(
		SECTION,
		"fits",
		{
			"ship_vanguard": {
				"engines": ["e_std"],
				"power": "p_std",
				## Two lasers and a cannon, so the grouping has something to do: the
				## laser cells are 0 and 2 and the cannon's is 1.
				"weapons": ["w_laser", "w_cannon", "w_laser"],
				"shields": ["s_light"],
				"armour": ["h_plate_light"],
				"computers": [""],
				"boosters": [""],
				"utility": [""],
			}
		}
	)
	assert_eq(fixture.save(PROFILE_PATH), OK, "the v6 fixture is written")
	_profile.call(&"reload")
	assert_eq(
		_profile.call(&"battery_groups", VANGUARD),
		[[0, 2], [1]],
		"the fitted weapons group by base id, cells ascending"
	)
	assert_eq(_stored(), [[0, 2], [1]], "and the record holds the migration's own grouping")
	assert_eq(
		int(_profile.call(&"migrate_batteries")), 0, "a second call migrates nothing: it is idempotent"
	)
	## The file is not rewritten by the load (17 section 3): it is still v6 on disk, and the
	## next real write - here a bag write, the smallest one this account can make - persists
	## v7 with the record.
	var on_disk := ConfigFile.new()
	assert_eq(on_disk.load(PROFILE_PATH), OK, "the fixture reads back")
	assert_eq(
		int(on_disk.get_value(SECTION, "save_version", 0)), 6, "still a v6 file after the load"
	)
	assert_false(
		on_disk.has_section_key(SECTION, "batteries"), "with no record on disk yet"
	)
	_profile.call(&"add_module", LASER, 1)
	_profile.call(&"flush")
	var written := ConfigFile.new()
	assert_eq(written.load(PROFILE_PATH), OK, "the written file reads back")
	assert_eq(
		int(written.get_value(SECTION, "save_version", 0)), 7, "a write persists save v7"
	)
	var stored: Dictionary = written.get_value(SECTION, "batteries", {})
	assert_eq(
		stored.get("ship_vanguard", []), [[0, 2], [1]], "and the migrated racks with it"
	)


## The v7 record drives the launch (09 section 11 / CONTRACTS section 17): the flight scene
## resolves the profile's racks into the mounted component's own index space, and the HUD's
## pushed cells carry the rack ordinal their trigger addresses.
func test_the_launch_hands_the_mounted_component_the_recorded_racks() -> void:
	_profile.call(&"set_fit", VANGUARD, FitData.standard_fit(VANGUARD))
	var laser := _instance(LASER)
	assert_true(
		bool(_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 1, laser)), "a laser in W2"
	)
	assert_true(
		bool(_profile.call(&"set_battery_groups", VANGUARD, [[0], [1]])), "two racks recorded"
	)
	var packed := load("res://game/game.tscn") as PackedScene
	_scene = packed.instantiate() as Node2D
	_fixture_host().add_child(_scene)
	var ship := _scene.get_node_or_null(NodePath(&"PlayerShip")) as Node2D
	var guns: Node2D = (
		ship.get_node_or_null(NodePath(&"WeaponComponent")) as Node2D if ship != null else null
	)
	assert_true(guns != null, "the launch mounted the weapon component")
	if guns == null:
		return
	assert_eq(
		guns.call(&"racks"), [[0], [1]], "the component received both racks in the record's order"
	)
	assert_eq(int(guns.call(&"rack_count")), 2, "two weapon keys select something")
	var hud: Control = _scene.get_node_or_null(NodePath(HUD_NODE)) as Control
	if hud != null and hud.has_method(&"hull_slots"):
		var cells: Array = hud.call(&"hull_slots")
		assert_eq(cells.size(), VANGUARD_W_CELLS, "the HUD kept the hull's three W cells")
		assert_eq(int(cells[0][&"battery"]), 1, "W1's cell fires from rack 1")
		assert_eq(int(cells[1][&"battery"]), 2, "and W2's from rack 2")
		assert_eq(int(cells[2][&"battery"]), 0, "an empty cell belongs to no rack")
		assert_false(bool(cells[2][&"selectable"]), "and selects nothing")


## The readout follows the barrel a selection names, never the array entry its **ordinal**
## happens to land on (the S5 review's R1-MED-1): the pushed cells carry the cell's own
## `position` beside the rack ordinal, and `select_battery`/a press read the pack of that
## barrel. A mixed rack is the case that bites - B1 is the cannon+rocket pair and B2 the
## laser - so `weapon_1` must name the cannon and show the cannon's rounds, not laser's.
func test_the_readout_follows_the_selected_barrels_own_pack() -> void:
	_profile.call(&"set_fit", VANGUARD, FitData.standard_fit(VANGUARD))
	var cannon := _instance(CANNON)
	var rocket := _instance(ROCKET)
	assert_true(
		bool(_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 1, cannon)),
		"a cannon in W2 beside the standard fit's laser in W1"
	)
	assert_true(
		bool(_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 2, rocket)), "a rocket in W3"
	)
	assert_true(
		bool(_profile.call(&"set_battery_groups", VANGUARD, [[1, 2], [0]])),
		"B1 = the cannon+rocket pair, B2 = the laser"
	)
	var packed := load("res://game/game.tscn") as PackedScene
	_scene = packed.instantiate() as Node2D
	_fixture_host().add_child(_scene)
	var state: PlayerState = _scene.get(&"_state") as PlayerState
	assert_eq(
		state.weapons,
		[&"laser", &"cannon", &"rocket"] as Array[StringName],
		"the launch's barrel slots are W1's laser, W2's cannon, W3's rocket"
	)
	## One family's pack per slot, at figures no two slots share, so a readout that landed
	## on the wrong array entry cannot pass. Written straight onto the array the readout
	## reads (`set_ammo` would emit `weapon_changed` and move the selection with it, which
	## is the launch's own channel, not this test's subject).
	state.ammo[0] = 111
	state.ammo[1] = 222
	state.ammo[2] = 133
	var hud: Control = _scene.get_node_or_null(NodePath(HUD_NODE)) as Control
	assert_true(hud != null, "the launch mounted the HUD")
	if hud == null:
		return
	## The push itself answered the launch's selection from the grid it drew: rack 1's own
	## representative, the cannon in W2 - never the empty-grid fallback `WEAPON_IDS[0]`'s
	## laser, which is what the ordinal read before the cells were in.
	assert_eq(int(hud.get(&"_active_slot")), 0, "the launch selects rack 1")
	assert_eq(String(hud.get(&"_weapon_id")), "cannon", "resolved against the pushed grid")
	var cells: Array = hud.call(&"hull_slots")
	assert_eq(cells.size(), VANGUARD_W_CELLS, "the HUD kept the hull's three W cells")
	assert_eq(int(cells[0][&"battery"]), 2, "W1's cell fires from rack 2")
	assert_eq(int(cells[1][&"battery"]), 1, "and W2's from rack 1")
	assert_eq(int(cells[2][&"battery"]), 1, "with W3 in that pair")
	assert_eq(int(cells[0][&"position"]), 0, "W1 carries barrel slot 0")
	assert_eq(int(cells[1][&"position"]), 1, "W2 slot 1")
	assert_eq(int(cells[2][&"position"]), 2, "and W3 slot 2")
	## The keyboard path names only the ordinal, so the rack's own first cell answers:
	## rack 1 is the cannon - never `WEAPON_IDS[0]`'s laser, which is what the ordinal
	## used to read.
	hud.call(&"select_battery", 1)
	assert_eq(String(hud.get(&"_weapon_id")), "cannon", "rack 1's representative is the cannon")
	assert_eq(int(hud.get(&"_ammo")), 222, "and the readout shows the cannon's rounds")
	## A press names one cell of the rack, so the readout follows that cell's barrel.
	hud.call(&"_on_weapon_slot_pressed", 2)
	assert_eq(String(hud.get(&"_weapon_id")), "rocket", "the pressed cell's own family")
	assert_eq(int(hud.get(&"_ammo")), 133, "and its own pack")
	hud.call(&"_on_weapon_slot_pressed", 0)
	assert_eq(String(hud.get(&"_weapon_id")), "laser", "W1 is the laser cell")
	assert_eq(int(hud.get(&"_ammo")), 111, "with the laser's pack")
