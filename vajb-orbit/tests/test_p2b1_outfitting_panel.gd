@tool
extends McpTestSuite
## Suite p2b1_outfitting_panel: the ARMORY pane (the OUTFITTING pane renamed, STATION_HUB
## section 5.11's 2026-09-23 S5 amendment) as the S3 retirement and the S5 rework leave it
## -- the battery racks over the inventory list over one row per
## `StationCatalog.AMMO_PACKS` entry (STATION_HUB section 5.1's S3/S4 amendments and
## section 5.11; 09 section 11; 10 section 6.1; CONTRACTS sections 12, 15, 16 and 17) --
## plus the shell's own refusal copy for the catalogue ids those rows and the catalogue's
## remaining price source answer to.
##
## **The MODULES section is retired**: the AUCTION shelf sells the rolled instances now,
## so this suite guards the retirement (no rows, no constants, no scene nodes) and proves
## the AUCTION is the door instead. **The S4 strip became the S5 racks** (section 5.11, 09
## section 11, CONTRACTS section 17): `B1..B7` drop zones over a list of inventory weapons,
## so the suite's row assertions moved to the racks' read-back (`rack_rows()`) and its
## single-cell REMOVE moved to a barrel chip's `✕`, which still writes through the composed
## remove (CONTRACTS section 13, S3-K4 HIGH-1's cure) with the same `_seed_fit` guard, for
## a base-id cell and for a rolled instance alike. The drag interface itself - install,
## move, swap, the refusals that write nothing - and the profile's own rack record are
## `tests/test_s5_batteries_v2.gd`'s.
##
## The pane is mounted from the shipped scene with the shipped theme and driven through the
## wiring the station shell itself uses -- the row's own `pressed` signal for an action
## (`ui/screens/station.gd:_connect_panel`) and `profile_changed` -> `refresh_profile` for
## the refresh (`_on_profile_changed`) -- so nothing here re-implements the panel's
## dispatch. The row set, the rounds, the costs and the icons are read off
## `StationCatalog.AMMO_PACKS`; the state lines are the script's own constants.
##
## The profile is the shipped autoload, borrowed the way `test_p2a_launch_fit.gd` borrows
## it: `save_path` is repointed at a scratch file before the first mutation, the seven
## fields the suite can write are seeded to a known account and handed back in
## `suite_teardown`, and the store is flushed while the scratch path is still in place, so
## the owner's `user://profile.cfg` is never written (probe hygiene L17, T-93).

const PanelScene := preload("res://ui/station/armory_panel.tscn")
const PanelScript := preload("res://ui/station/armory_panel.gd")
const StationScript := preload("res://ui/screens/station.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const Catalog := preload("res://game/station_catalog.gd")
const ModuleData := preload("res://game/module_catalog.gd")
const FitData := preload("res://game/ship_fit.gd")

const PROFILE_PATH := "user://test_p2b1_outfitting_panel.cfg"

const VANGUARD: StringName = &"ship_vanguard"
const LANCER: StringName = &"ship_fighter"
const WEAPON_SLOT: StringName = &"weapons"
const ENGINE_SLOT: StringName = &"engines"
const POWER_SLOT: StringName = &"power"
const STANDARD_ENGINE: StringName = &"e_std"
const STANDARD_REACTOR: StringName = &"p_std"
const LASER: StringName = &"w_laser"
const RAILGUN: StringName = &"w_railgun"

const START_CREDITS := 10000
## The W cells the Vanguard's 08 section 3.2 matrix carries, asserted rather than assumed.
const VANGUARD_W_CELLS := 3
## The **hold** account every test starts from, in cargo units since S5 (10 section 6.1: a
## purchase delivers units, so the HELD cell is the hold's count): a laser at its advisory
## cap (30 units of a 300-round ceiling), a half-full cannon, an over-cap rocket (40 units
## against a 10-unit ceiling - a stack bought before the delist, which the pane still has to
## render), and empty mine and plasma.
const AMMO_FIXTURE: Dictionary = {
	&"ammo_laser": 30,
	&"ammo_cannon": 15,
	&"ammo_rocket": 40,
	&"ammo_mine": 0,
	&"ammo_plasma": 0,
}

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
var _previous_cargo: Dictionary = {}
var _previous_batteries: Dictionary = {}


func suite_name() -> String:
	return "p2b1_outfitting_panel"


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
	_previous_cargo = _profile.get(&"_cargo")
	_previous_batteries = _profile.get(&"_batteries")
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
	_profile.set(&"_cargo", _previous_cargo)
	_profile.set(&"_batteries", _previous_batteries)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	_delete_file(PROFILE_PATH)
	_profile = null


func setup() -> void:
	_status.clear()
	_danger.clear()
	_seed_account()
	_host = Control.new()
	_host.name = "ArmoryHost"
	_host.theme = ThemeRes
	_host.size = _viewport_size()
	_fixture_host().add_child(_host)


func teardown() -> void:
	if _host != null and is_instance_valid(_host):
		_host.free()
	_host = null
	_panel = null


## The fixture account every test starts from: the Vanguard active and owned, no fit, no
## modules, no racks, 10 000 CR and `AMMO_FIXTURE`'s cargo units. Written through the same
## private fields `test_p2a_launch_fit.gd` hands back, so no purchase is charged and no signal
## fires before the pane is mounted.
func _seed_account() -> void:
	var owned: Array[StringName] = [VANGUARD]
	_profile.set(&"_credits", START_CREDITS)
	_profile.set(&"_active_ship", VANGUARD)
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_ammo", {})
	_profile.set(&"_cargo", AMMO_FIXTURE.duplicate())
	_profile.set(&"_batteries", {})


## The runner calls every test from inside its own `_ready`, so the root viewport is still
## busy adding the runner scene and `root.add_child(...)` fails. The profile autoload
## entered the tree before the main scene, so it hosts the fixture (suite ui_slot_layout's
## own reason).
func _fixture_host() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(NodePath(&"PlayerProfile"))


func _viewport_size() -> Vector2:
	var width := float(ProjectSettings.get_setting("display/window/size/viewport_width", 1920))
	var height := float(ProjectSettings.get_setting("display/window/size/viewport_height", 1080))
	return Vector2(width, height)


## Mount the shipped pane the way the shell does: into a sized host, with the shell's two
## wirings (the panel's status strip up, the profile's keys down).
func _mount() -> Control:
	_panel = PanelScene.instantiate() as Control
	_host.add_child(_panel)
	_profile.connect(&"profile_changed", Callable(_panel, &"refresh_profile"))
	_panel.connect(&"status_requested", _on_status)
	return _panel


func _on_status(message: String, danger: bool) -> void:
	_status.append(message)
	_danger.append(danger)


## --------------------------------------------------------------- panel read-backs


func _ammo_rows(panel: Control) -> VBoxContainer:
	return panel.get_node("%ArmoryRows") as VBoxContainer


func _ammo_row(panel: Control, pack_id: StringName) -> Button:
	for child: Node in _ammo_rows(panel).get_children():
		var row := child as Button
		if row != null and _row_pack_id(row) == pack_id:
			return row
	return null


## A row's pack id, read back off the catalogue by name rather than stored: the pane names
## its rows `Ammo<PascalCase>` and the catalogue is the only id source.
func _row_pack_id(row: Button) -> StringName:
	var title := row.find_child("Title", true, false) as Label
	if title == null:
		return &""
	for pack: Dictionary in Catalog.AMMO_PACKS:
		if String(pack.get(&"name", "")).to_upper() == title.text.to_upper():
			return pack.get(&"id", &"")
	return &""


func _cell_text(row: Button, cell_name: String) -> String:
	var cell := row.find_child(cell_name, true, false) as Control
	if cell == null:
		return ""
	var value := cell.get_node_or_null(^"Value") as Label
	return value.text if value != null else ""


func _cell_caption(row: Button, cell_name: String) -> String:
	var cell := row.find_child(cell_name, true, false) as Control
	if cell == null:
		return ""
	var caption := cell.get_node_or_null(^"Caption") as Label
	return caption.text if caption != null else ""


func _price_danger(row: Button) -> bool:
	var price := row.find_child("Price", true, false) as Control
	var value := price.get_node_or_null(^"Value") as Label
	return value != null and value.has_theme_color_override(&"font_color")


## The strip's rendered rows, the S4 shape (STATION_HUB section 5.1's 2026-09-23 amendment):
## one battery row per battery in first-cell order, then one read-only `W<n> — EMPTY` line per
## empty W cell. A row is a `VBoxContainer` whose `Main` box carries
## `Expander`/`Text`/`FitAll`/`RemoveAll`/`SwapAll` and whose `Cells` box carries the
## expander's single-cell lines (each one the P2-B1 strip's own `Text` + `Remove` row).
## The racks the pane drew, as `rack_rows()` hands them out, plus the node read-backs a
## probe would use: each rack's `B<n>` label, its `SALVO`/`READY` state line and its barrel
## chips (`W<cell> <NAME>` plates, each with its own `✕`).
func _rack_rows(panel: Control) -> Array:
	return panel.call(&"rack_rows")


func _rack_row(panel: Control, index: int) -> PanelContainer:
	var racks := panel.get_node("%RackRows") as VBoxContainer
	return racks.get_child(index) as PanelContainer


func _rack_label(panel: Control, index: int) -> String:
	return (_rack_row(panel, index).get_node(^"Box/Head/Label") as Label).text


func _rack_text(panel: Control, index: int) -> String:
	return (_rack_row(panel, index).get_node(^"Box/Head/State") as Label).text


func _barrel_chip(panel: Control, rack: int, position: int) -> HBoxContainer:
	var row := _rack_row(panel, rack)
	var barrels := row.get_node(^"Box/Barrels") as HBoxContainer
	return barrels.get_child(position) as HBoxContainer


func _close_barrel(panel: Control, rack: int, position: int) -> void:
	(_barrel_chip(panel, rack, position).get_node(^"Close") as Button).pressed.emit()


func _inventory_rows(panel: Control) -> VBoxContainer:
	return panel.get_node("%InventoryRows") as VBoxContainer


## One inventory row's drag payload, exactly as its own `_get_drag_data` builds it: the
## suite drives the same call the engine's drag does.
func _drag_inventory(panel: Control, base_id: StringName) -> Dictionary:
	var payload: Variant = panel.call(&"drag_inventory", base_id)
	return payload if payload is Dictionary else {}


func _cells(hull: StringName) -> Array:
	return _profile.call(&"fit_for", hull)[WEAPON_SLOT]


## The hold's own **cargo units** of one ammo family: since S5 that is the figure the pane's
## HELD cell shows (10 section 6.1), not the magazine `ammo_of` reads.
func _held(pack_id: StringName) -> int:
	return int(_profile.call(&"ammo_units", pack_id))


## The unit equivalent of one family's advisory `ammo_max`: the pane's own MAX figure.
func _unit_cap(pack_id: StringName) -> int:
	return int(
		ceili(
			float(_profile.call(&"ammo_max", pack_id))
			/ float(Catalog.ROUNDS_PER_CARGO_UNIT)
		)
	)


func _press_ammo(panel: Control, pack_id: StringName) -> void:
	_ammo_row(panel, pack_id).pressed.emit()




## A **module** id's held count, which is not `ammo_of`: a rack's remove hands a module
## back through `add_module`, and 15 section 8's aggregation reads `instances_of` (K1's own
## note on `module_count`, which does not aggregate instances).
func _module_held(module_id: StringName) -> int:
	return (_profile.call(&"instances_of", module_id) as Array).size()


## One **record's** own `count`, instance key and base key alike: 1 in the bag, 0 fitted. Not
## `_module_held`, which aggregates the bag's ids per base and cannot tell a stranded record
## from a restored one (S3-K4's HIGH-1 read `instances_of`; the fix's acceptance reads this).
func _module_count(record_id: StringName) -> int:
	return int(_profile.call(&"module_count", record_id))


func _credits() -> int:
	return int(_profile.call(&"credits"))


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


## ------------------------------------------------------- the ammunition rows


## One row per `StationCatalog.AMMO_PACKS` entry, in the catalogue's own order (05's
## `PlayerState.WEAPONS` order), each one carrying the catalogue's name, its rounds meta,
## its price and its icon. Nothing in this section is a literal: the pane reads the
## catalogue and this suite reads the same catalogue back.
func test_ammo_rows_are_the_catalogue_in_order() -> void:
	var panel := _mount()
	var rows := _ammo_rows(panel)
	var buttons: Array[Button] = []
	for child: Node in rows.get_children():
		var row := child as Button
		if row != null:
			buttons.append(row)
	assert_eq(
		buttons.size(), Catalog.AMMO_PACKS.size(), "one row per catalogue pack, and nothing else"
	)
	for index in Catalog.AMMO_PACKS.size():
		var pack: Dictionary = Catalog.AMMO_PACKS[index]
		var pack_id: StringName = pack[&"id"]
		var row := _ammo_row(panel, pack_id)
		assert_true(row != null, "%s has a row" % pack_id)
		if row == null:
			continue
		assert_eq(
			String(row.find_child("Title", true, false).text),
			String(pack[&"name"]),
			"%s's title is the catalogue's name" % pack_id
		)
		assert_eq(
			String(row.find_child("Meta", true, false).text),
			PanelScript.ROUNDS_CAPTION % int(pack[&"rounds"]),
			"%s's meta is its rounds" % pack_id
		)
		assert_eq(
			_cell_text(row, "Price").replace(" ", ""),
			str(int(pack[&"cost"])),
			"%s's PRICE is the catalogue's cost" % pack_id
		)
		var icon := row.find_child("Icon", true, false) as TextureRect
		assert_true(icon != null, "%s carries an icon" % pack_id)
		if icon != null:
			assert_eq(
				icon.texture.resource_path,
				String(pack[&"icon"]),
				"%s's icon is the catalogue's own file" % pack_id
			)
			assert_eq(
				bool(panel.call(&"_is_flat_glyph", String(pack[&"icon"]))),
				PanelScript.FLAT_GLYPH_ICONS.has(String(pack[&"icon"])),
				"%s's C16 flat-glyph classification is the pane's own table" % pack_id
			)
	## The panel's own header names the catalogue's five packs, so the tag cannot go stale.
	var listed := PackedStringArray()
	for pack: Dictionary in Catalog.AMMO_PACKS:
		listed.append(String(pack[&"id"]))
	assert_eq(
		String((panel.get_node("%PanelTag") as Label).text),
		PanelScript.TAG_LIST_PREFIX + PanelScript.TAG_LIST_SEPARATOR.join(listed),
		"the panel tag lists the catalogue's own ids"
	)


## The four state lines of section 5.1, over a fixture account that carries all four, now
## read off the **hold's units** (10 section 6.1): `AT CAP` for a laser at its 30-unit
## equivalent, `IN STOCK` for a half-full cannon, `OVER CAP` for a 40-unit rocket stack
## against its 10-unit ceiling, `EMPTY` for the unheld mine.
func test_ammo_state_lines_and_tags() -> void:
	var panel := _mount()
	var cases: Array = [
		{&"id": &"laser", &"tag": PanelScript.TAG_AT_CAP, &"meta": PanelScript.META_NO_CAP},
		{&"id": &"cannon", &"tag": PanelScript.TAG_IN_STOCK, &"meta": PanelScript.META_BELOW_CAPACITY},
		{&"id": &"rocket", &"tag": PanelScript.TAG_OVER_CAP, &"meta": PanelScript.META_ADVISORY},
		{&"id": &"mine", &"tag": PanelScript.TAG_EMPTY, &"meta": PanelScript.META_NO_ROUNDS},
		{&"id": &"plasma", &"tag": PanelScript.TAG_EMPTY, &"meta": PanelScript.META_NO_ROUNDS},
	]
	for entry: Dictionary in cases:
		var pack_id: StringName = entry[&"id"]
		var row := _ammo_row(panel, pack_id)
		assert_true(row != null, "%s has a row" % pack_id)
		if row == null:
			continue
		assert_eq(
			_cell_text(row, "Held"),
			PanelScript.HELD_FORMAT % [_held(pack_id), _unit_cap(pack_id)],
			"%s's HELD / MAX is the hold's units against the family's unit ceiling" % pack_id
		)
		assert_eq(_cell_text(row, "Status"), String(entry[&"tag"]), "%s's tag" % pack_id)
		assert_eq(_cell_caption(row, "Held"), String(entry[&"meta"]), "%s's state line" % pack_id)
	## The advisory footer is the scene's own copy, unchanged by this pass: the hold cap is
	## advisory and a purchase is never clamped (`STATION_SPEC.md` section 2.3).
	assert_eq(
		String((panel.get_node("%PaneFooter") as Label).text),
		"HOLD CAPACITY IS ADVISORY · A PURCHASE IS NEVER CLAMPED",
		"the pane footer still states the advisory rule"
	)


## BUY charges the catalogue's own price and delivers the pack's **cargo units** (10
## section 6.1 / CONTRACTS section 17: `units = rounds / ROUNDS_PER_CARGO_UNIT`); an
## unaffordable pack greys its price and the profile refuses the purchase without charging.
## The pack itself - the magazine a launch loads - is not what a purchase grows any more,
## which is the move J2's report left to this pane's surface.
func test_ammo_purchase_charges_the_catalogue_price_and_greys_when_short() -> void:
	var panel := _mount()
	var pack := Catalog.ammo_pack(&"rocket")
	var rounds := int(pack[&"rounds"])
	var cost := int(pack[&"cost"])
	var units := int(ceili(float(rounds) / float(Catalog.ROUNDS_PER_CARGO_UNIT)))
	assert_eq(_held(&"rocket"), 40, "the fixture holds a 40-unit rocket stack")
	_press_ammo(panel, &"rocket")
	assert_eq(_credits(), START_CREDITS - cost, "the buy charged the catalogue's cost")
	assert_eq(_held(&"rocket"), 40 + units, "and added the pack's own units to the hold")
	assert_eq(_profile.call(&"cargo_qty", &"ammo_rocket"), 40 + units, "under the ammo id")
	assert_eq(
		_last_status(),
		PanelScript.STATUS_BOUGHT % ["ROCKET POD", rounds],
		"the pane reports the purchase in the shell's own shape"
	)
	## Drain the balance: the price cell greys and the purchase is refused with nothing
	## charged and nothing added.
	var row := _ammo_row(panel, &"plasma")
	assert_false(_price_danger(row), "an affordable pack's price is not greyed")
	assert_true(bool(_profile.call(&"spend", _credits())), "drain the balance")
	assert_eq(_credits(), 0, "the balance is empty")
	assert_true(_price_danger(row), "the price greys in accent_danger (section 5.6)")
	var before := _held(&"plasma")
	_press_ammo(panel, &"plasma")
	assert_eq(_held(&"plasma"), before, "the refused buy added nothing")
	assert_eq(_credits(), 0, "and charged nothing")
	assert_eq(_last_danger(), false, "the refusal line and the cue belong to the shell's strip")


## ------------------------------------------------------ the retirement (10 section 2.4)


## The MODULES section is gone from the pane, its scene and its script: no caption, no
## header, no rows box, no row set, no constants and none of the four fit actions. The S5
## racks and inventory are **not** part of the retirement (STATION_HUB section 5.11 reworks
## this pane), so they are asserted present here and measured in their own tests.
func test_the_module_rows_are_retired_from_the_pane_its_scene_and_its_script() -> void:
	var panel := _mount()
	assert_true(
		panel.get_node_or_null("%RackRows") != null, "the battery racks are drawn"
	)
	assert_eq(
		String((panel.get_node("ArmoryScroll/ArmoryBody/RacksMargin/RacksBox/RacksCaption") as Label).text),
		"BATTERY RACKS",
		"and keep their own caption"
	)
	assert_true(
		panel.get_node_or_null("%InventoryRows") != null, "and so is the inventory list"
	)
	for gone: String in ["%ModuleRows", "%ModulesHeader", "%ModulesCaption", "%ModulesMargin"]:
		assert_true(panel.get_node_or_null(gone) == null, "no node %s exists" % gone)
	for constant: String in ["MODULE_ROWS", "EFFECT_TEXT", "STATUS_FITTED", "STATUS_OWNED"]:
		assert_false(
			_has_member(PanelScript, constant), "the script carries no %s" % constant
		)
	for method: String in [
		"module_row_ids",
		"module_action",
		"buy_module",
		"install_module",
		"swap_module",
		"fit_index_of",
		"_module_state",
		"_build_module_rows",
	]:
		assert_false(_has_member(PanelScript, method), "the script carries no %s()" % method)
	## The scene file itself carries no MODULES caption and no rows box: the retirement is
	## in the shipped scene, not only in the script.
	var scene := FileAccess.get_file_as_string("res://ui/station/armory_panel.tscn")
	assert_false(scene.contains("MODULES"), "the pane scene names no MODULES section")
	assert_false(scene.contains("ModuleRows"), "and carries no rows box for one")


## Whether a script exposes a member (a constant, a method or a property) by name. The
## retirement guard asks the script's own reflection, so a constant that comes back is a
## real regression rather than a string this suite typed out twice.
func _has_member(script: GDScript, name: String) -> bool:
	for entry: Dictionary in script.get_script_method_list():
		if String(entry.get("name", "")) == name:
			return true
	for entry: Dictionary in script.get_script_property_list():
		if String(entry.get("name", "")) == name:
			return true
	for key: Variant in script.get_script_constant_map():
		if String(key) == name:
			return true
	return false


## The AUCTION is the modules' door now, and the catalogue's price source is untouched:
## the shelf ships as a scene, the rail carries the entry with a pane behind it, and
## `ModuleCatalog` still prices every module id the retired rows sold.
func test_the_auction_is_the_modules_door_now() -> void:
	assert_true(
		ResourceLoader.exists("res://ui/station/auction_panel.tscn"),
		"the AUCTION pane scene ships"
	)
	assert_true(
		ResourceLoader.exists("res://ui/station/auction_panel.gd"),
		"and its script with it"
	)
	var module_index := StationScript.MODULE_LABELS.find("AUCTION")
	assert_true(module_index >= 0, "the station rail carries an AUCTION entry")
	if module_index >= 0:
		assert_eq(
			StationScript.MODULE_FILES[module_index], "auction", "which loads the AUCTION pane"
		)
		assert_eq(
			module_index, 3, "directly after EXCHANGE, the position section 5.10 pins"
		)
		assert_eq(
			StationScript.MODULE_LABELS[2], "EXCHANGE", "EXCHANGE is the entry before it"
		)
	## The price source the retired rows used is still the catalogue's: every module id the
	## seven rows sold still answers with its 09 section 3.1 cost.
	var ids: Array[StringName] = [
		&"w_laser",
		&"w_cannon",
		&"w_rocket",
		&"w_mine",
		&"w_plasma",
		&"w_railgun",
		&"w_mining",
	]
	for id: StringName in ids:
		assert_gt(int(ModuleData.module(id).get(&"cost", 0)), 0, "%s still has a price" % id)
	assert_true(
		bool(_profile.call(&"buy_module", LASER, int(ModuleData.module(LASER)[&"cost"]))),
		"and buy_module still prices a module with no UI caller above it"
	)


## The shell's own refusal copy still names a catalogue cost for the ids it can resolve,
## and resolves a rolled **instance** id to nothing -- which is the measured reason the
## AUCTION pane owns its own footer strip (STATION_HUB section 5.10's S3 amendment), so the
## behaviour is pinned here rather than left as prose.
func test_shell_refusal_still_names_a_catalogue_cost() -> void:
	var shell: Node = StationScript.new()
	var pack_cost := int(Catalog.ammo_pack(&"laser")[&"cost"])
	assert_eq(
		_digits_only(String(shell.call(&"_refusal_text", &"insufficient_credits", &"laser"))),
		str(pack_cost),
		"the ammo pack's copy names the catalogue's price"
	)
	var railgun_cost := int(ModuleData.module(RAILGUN)[&"cost"])
	assert_eq(
		_digits_only(String(shell.call(&"_refusal_text", &"insufficient_credits", RAILGUN))),
		str(railgun_cost),
		"and so does a module id: the catalogue is still the price source"
	)
	var ship_cost := int(Catalog.ship(LANCER)[&"cost"])
	assert_eq(
		_digits_only(String(shell.call(&"_refusal_text", &"insufficient_credits", LANCER))),
		str(ship_cost),
		"and a hull id"
	)
	assert_eq(
		int(shell.call(&"_entry_cost", &"w_not_a_module")), 0, "an unknown id resolves to nothing"
	)
	## An instance id is not a catalogue id: the copy cannot price it, which is why the
	## AUCTION pane reads the shelf itself and refuses in its own strip.
	var instance := StringName(
		_profile.call(&"add_instance", LASER, ModuleData.RARITY_MAGIC, [], [])
	)
	assert_eq(
		int(shell.call(&"_entry_cost", instance)), 0, "a rolled instance id prices to 0 here"
	)
	assert_eq(
		String(shell.call(&"_refusal_text", &"insufficient_credits", instance)),
		"REFUSED · NOT ENOUGH CREDITS · 0 NEEDED",
		"so this copy would read 0 NEEDED, exactly as section 5.10's amendment records"
	)
	shell.free()


## The digits of `text`, separators and words dropped: the shell groups its numbers with the
## project's thousands space, so `5 200 NEEDED` and `5200` compare equal.
func _digits_only(text: String) -> String:
	var digits := ""
	for index in text.length():
		var glyph := text[index]
		if glyph >= "0" and glyph <= "9":
			digits += glyph
	return digits


## ------------------------------------------------------------- the racks (S5)


## The B1..B7 racks over the inventory (STATION_HUB section 5.11, 09 section 11): seven drop
## zones, each one labelled `B<n>`, and the pane's read-back accounts for the active hull's
## W cells - the Vanguard's delivered laser sits in B1 on cell W1, and the other six racks
## are empty drop zones.
func test_the_racks_draw_seven_drop_zones_over_the_inventory() -> void:
	assert_eq(
		PanelScript.RACK_COUNT, 7, "the pin's own rack count (GROUPS_MAX 5 -> 7)"
	)
	assert_eq(
		FitData.slot_capacity(VANGUARD, WEAPON_SLOT),
		VANGUARD_W_CELLS,
		"the Vanguard's matrix carries three W cells"
	)
	var panel := _mount()
	var rows := _rack_rows(panel)
	assert_eq(rows.size(), PanelScript.RACK_COUNT, "one rack per weapon key")
	for index in rows.size():
		assert_eq(_rack_label(panel, index), "B%d" % (index + 1), "rack %d carries its own label" % index)
	assert_eq(rows[0][&"cells"], [0], "B1 holds the standard fit's cell, derived on read")
	assert_eq(
		rows[0][&"barrels"][0][&"text"], "W1 LASER MKII", "as a chip naming its own W cell"
	)
	assert_eq(rows[1][&"cells"], [], "an empty rack holds nothing")
	assert_eq(rows[3][&"cells"], [], "and so does a rack past the hull's cells")
	## The empty-state cue and the salvo line are the pane's own two labels, one visible at a
	## time: an empty rack offers the drop, a loaded one states its rate.
	var loaded := _rack_row(panel, 0)
	assert_true((loaded.get_node(^"Box/Head/Hint") as Label).visible == false, "a loaded rack hides the drop cue")
	assert_true((loaded.get_node(^"Box/Head/State") as Label).visible, "and shows its state line")
	assert_eq(_rack_text(panel, 0), PanelScript.RACK_READY, "a laser rack states no travelling cadence")
	var empty := _rack_row(panel, 1)
	assert_true((empty.get_node(^"Box/Head/Hint") as Label).visible, "an empty rack shows the drop cue")
	assert_eq(
		(empty.get_node(^"Box/Head/Hint") as Label).text,
		PanelScript.RACK_INSTALL_CUE,
		"the pane's own words"
	)


## The salvo line is the pin's rule made visible (09 section 11: "the rof will be limited by
## the slowest weapon"): a rack holding a cannon states the cannon's 0.6 s cycle, and a rack
## mixing it with a rocket states the rocket's 1.2 s. The arithmetic is the component's own
## (`WeaponComponent.interval_of`), never a number written here.
func test_a_rack_states_its_slowest_members_cycle() -> void:
	var panel := _mount()
	_profile.call(&"add_module", &"w_cannon", 1)
	## The composed install composes its candidate from the fit the launch flies (09
	## section 9's delivered laser in W1), so the cannon lands beside it rather than in a
	## one-module fit.
	assert_true(
		bool(_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 1, &"w_cannon")),
		"a cannon fits W2"
	)
	_profile.call(&"set_battery_groups", VANGUARD, [[0], [1]])
	assert_eq(
		_rack_text(panel, 1),
		PanelScript.RACK_SALVO % WeaponComponent.interval_of(&"cannon"),
		"the cannon rack states its own 0.6 s cycle"
	)
	_profile.call(&"add_module", &"w_rocket", 1)
	assert_true(
		bool(_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 2, &"w_rocket")),
		"a rocket fits W3"
	)
	_profile.call(&"set_battery_groups", VANGUARD, [[0], [1, 2]])
	assert_eq(
		_rack_text(panel, 1),
		PanelScript.RACK_SALVO % WeaponComponent.interval_of(&"rocket"),
		"and the mixed rack states the rocket's 1.2 s, its slowest member"
	)
	assert_eq(
		WeaponComponent.interval_of(&"cannon"), 0.6, "the cannon's cycle is the burst window"
	)


## The inventory list (section 5.11: "a left list of inventory weapons"): one row per owned
## weapon id, aggregated, with the bag's own instance count - and nothing for a base the bag
## does not carry. An account owning none shows the pane's own empty state instead.
func test_the_inventory_lists_the_owned_weapon_ids() -> void:
	var panel := _mount()
	assert_eq(_inventory_rows(panel).get_child_count(), 1, "no weapons owned: one empty-state line")
	assert_eq(
		String((_inventory_rows(panel).get_child(0) as Label).text),
		PanelScript.INVENTORY_EMPTY,
		"which is the pane's own words"
	)
	_profile.call(&"add_module", &"w_laser", 1)
	_profile.call(&"add_module", &"w_railgun", 1)
	## The figure is `instances_of`, one entry per record (S4's own reading): a record the
	## bag stacks (`count` 2 from two `add_module` calls) is one instance and one cell, so a
	## second **instance** is the honest way to make the count two.
	_profile.call(&"add_instance", &"w_railgun", ModuleData.RARITY_COMMON, [], [])
	## A non-weapon module never appears: the list is the rack record's own domain.
	_profile.call(&"add_module", &"p_std", 1)
	var rows := panel.call(&"inventory_rows") as Array
	assert_eq(rows.size(), 2, "two owned weapon ids")
	assert_eq(StringName(rows[0][&"base"]), &"w_laser", "in catalogue order")
	assert_eq(StringName(rows[1][&"base"]), &"w_railgun", "the later row of the two")
	var views := panel.call(&"inventory_view_rows") as Array
	assert_eq(
		String(views[0][&"text"]),
		PanelScript.INVENTORY_TEXT % ["OWNED", 1],
		"the row carries the bag's own count"
	)
	assert_eq(String(views[1][&"text"]), PanelScript.INVENTORY_TEXT % ["OWNED", 2], "and so does the stack")
	## Every row is a drag source: its payload names the base id and nothing else.
	var payload := _drag_inventory(panel, &"w_laser")
	assert_eq(StringName(payload[&"kind"]), PanelScript.DRAG_INVENTORY, "the row drags an inventory weapon")
	assert_eq(StringName(payload[&"base"]), &"w_laser", "its own base id")
	assert_true(_drag_inventory(panel, &"w_cannon").is_empty(), "an unowned base drags nothing")


## The `✕` on a barrel is the pane's one remove (section 5.11): the cell empties, the barrel
## returns to the inventory, nothing is charged, and the racks re-read without a rebuild of
## the pane. It writes through the composed `clear_rack_cell`, so the mandatory set and
## `fit_legal` are checked before the first write.
func test_the_close_removes_a_barrel_back_to_the_inventory() -> void:
	var panel := _mount()
	assert_eq(_cells(VANGUARD), ["", "", ""], "a fresh account stores no fit for the hull")
	assert_eq(_module_held(&"w_laser"), 0, "and holds no laser")
	_close_barrel(panel, 0, 0)
	assert_eq(_cells(VANGUARD)[0], "", "the rack's barrel left its cell")
	assert_eq(_module_held(&"w_laser"), 1, "and is back in the inventory")
	assert_eq(_rack_rows(panel)[0][&"cells"], [], "the rack holds nothing again")
	assert_eq(_credits(), START_CREDITS, "removing costs nothing")
	assert_eq(
		_last_status(),
		PanelScript.STATUS_REMOVED % "LASER MKII",
		"and the pane reports it in its own wording"
	)
	assert_false(_last_danger(), "success is never the danger colour")
	## 09 section 7's mandatory set survives: the pane can only address W cells, and the
	## mandatory keys are engines and power (the guard rather than a second rule).
	var fit: Dictionary = _profile.call(&"fit_for", VANGUARD)
	assert_eq(fit[ENGINE_SLOT], ["e_std"], "the engine set is untouched")
	assert_eq(fit[POWER_SLOT], "p_std", "the reactor is untouched")
	assert_eq(FitData.fit_legal(VANGUARD, fit)[&"missing"], [], "and the fit still has its mandatory set")


## The `✕` against a cell that holds an **instance** (S3-K4 HIGH-1). The composed remove
## banks the entry the cell holds as *itself*, so a weapon rolled and fitted through FITTING
## comes back with its own id, rarity and affix rows instead of being stranded at `count` 0
## behind a fresh base-keyed Common (CONTRACTS section 15's `restore_instance` clause).
func test_the_close_hands_back_the_fitted_instance() -> void:
	var panel := _mount()
	var instance := StringName(
		_profile.call(&"add_instance", &"w_laser", &"magic", [{"id": "keen", "value": 0.16}], ["whale"])
	)
	assert_true(
		bool(_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 0, instance)),
		"the rolled instance fits the first W cell"
	)
	assert_eq(
		String(_cells(VANGUARD)[0]), String(instance), "the cell holds the instance id, not its base"
	)
	assert_eq(_module_count(instance), 0, "and the instance is out of the bag")
	assert_eq(_rack_rows(panel)[0][&"barrels"][0][&"text"], "W1 LASER MKII", "the rack names the base")
	_close_barrel(panel, 0, 0)
	assert_eq(_cells(VANGUARD)[0], "", "the remove emptied the cell")
	assert_eq(_module_count(instance), 1, "and the same instance is back in the bag")
	var record: Dictionary = _profile.call(&"instance", instance)
	assert_eq(String(record[&"rarity"]), "magic", "with its own rarity")
	var row: Dictionary = (record[&"prefixes"] as Array)[0]
	assert_eq(String(row[&"id"]), "keen", "and its own prefix row")
	assert_true(is_equal_approx(float(row[&"value"]), 0.16), "at its own band value")
	assert_true((record[&"suffixes"] as Array) == ["whale"], "and its own suffix")
	assert_eq(
		(_profile.call(&"modules") as Dictionary).size(), 1, "one record throughout: nothing minted"
	)
	assert_eq(
		_last_status(),
		PanelScript.STATUS_REMOVED % "LASER MKII",
		"and the pane reports it in its own wording"
	)


## The duplication half of S3-K4 HIGH-1: a base-keyed unit of the same base already in the
## bag is not incremented by the remove. The raw `add_module(base_id, 1)` this pane wrote
## before the fix banked a fresh unit whichever entry the cell held, so one physical unit
## became two and `Auction.sell_rows` priced both.
func test_the_close_does_not_duplicate_a_base_keyed_unit() -> void:
	var panel := _mount()
	var instance := StringName(_profile.call(&"add_instance", &"w_laser", &"rare", [], []))
	assert_true(
		bool(_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 0, instance)), "the instance fits"
	)
	_profile.call(&"add_module", &"w_laser", 1)
	assert_eq(_module_count(&"w_laser"), 1, "one plain base-keyed laser sits in the bag")
	_close_barrel(panel, 0, 0)
	assert_eq(_module_count(instance), 1, "the fitted instance is back as itself")
	assert_eq(_module_count(&"w_laser"), 1, "and the base-keyed unit is still one unit, not two")
	assert_eq(
		(_profile.call(&"modules") as Dictionary).size(), 2, "two records: no third was minted"
	)
	assert_true(
		(_profile.call(&"instances_of", &"w_laser") as Array).has(instance),
		"and the bag offers the restored instance"
	)


## ------------------------------------------------------------------- the refresh


## The refresh is the profile's signal, not a read-through: the ammo rows move on `credits`,
## `ammo` and `cargo` (a purchase writes both of the last two), and the racks and the
## inventory on `fits`, `ships`, `modules` and `batteries` - a rack's record being the newest
## of those keys.
func test_profile_changed_drives_the_refresh() -> void:
	var panel := _mount()
	var row := _ammo_row(panel, &"plasma")
	assert_eq(_cell_text(row, "Status"), PanelScript.TAG_EMPTY, "the plasma pack starts empty")
	## Without the shell's wiring the pane is not told, and its cells do not move.
	_profile.disconnect(&"profile_changed", Callable(panel, &"refresh_profile"))
	_profile.call(&"add_cargo", &"ammo_plasma", 5)
	assert_eq(_held(&"plasma"), 5, "the hold moved")
	assert_eq(
		_cell_text(row, "Status"), PanelScript.TAG_EMPTY, "an unwired pane is stale: nothing refreshed it"
	)
	## Wired, the same key refreshes it, and so does a credits change.
	_profile.connect(&"profile_changed", Callable(panel, &"refresh_profile"))
	_profile.call(&"add_cargo", &"ammo_plasma", 1)
	assert_eq(_cell_text(row, "Status"), PanelScript.TAG_IN_STOCK, "cargo refreshed the tag")
	assert_eq(
		_cell_text(row, "Held"),
		PanelScript.HELD_FORMAT % [6, _unit_cap(&"plasma")],
		"and the held count"
	)
	assert_true(bool(_profile.call(&"spend", _credits())), "drain the balance")
	assert_true(_price_danger(row), "credits recomputed the price's colour")
	## The racks follow the fit and the rack record.
	_profile.call(&"add_module", &"w_railgun", 1)
	assert_true(
		bool(_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 1, &"w_railgun")),
		"an external fit write"
	)
	var racks := _rack_rows(panel)
	assert_eq(racks[0][&"cells"], [0, 1], "fits refreshed the racks: one derived group holds both cells")
	assert_eq(racks[0][&"barrels"][1][&"text"], "W2 RAILGUN", "and the new barrel is drawn")
	_profile.call(&"set_battery_groups", VANGUARD, [[0], [1]])
	racks = _rack_rows(panel)
	assert_eq(racks[0][&"cells"], [0], "a batteries write re-read the racks")
	assert_eq(racks[1][&"cells"], [1], "splitting the two cells into B1 and B2")
	assert_eq(racks[1][&"barrels"][0][&"text"], "W2 RAILGUN", "with the barrel's chip following its cell")
	## `modules` moves the inventory list, which is the bag's own read.
	assert_eq((panel.call(&"inventory_rows") as Array).size(), 0, "no railgun in the bag yet")
	_profile.call(&"add_module", &"w_railgun", 1)
	assert_eq((panel.call(&"inventory_rows") as Array).size(), 1, "a modules write moved the list")
	assert_eq(_cells(VANGUARD)[1], &"w_railgun", "and wrote no fit cell")
