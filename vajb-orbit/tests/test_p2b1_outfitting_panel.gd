@tool
extends McpTestSuite
## Suite p2b1_outfitting_panel: the OUTFITTING pane as the S3 amendment leaves it --
## the FITTED WEAPONS strip above one row per `StationCatalog.AMMO_PACKS` entry
## (STATION_HUB section 5.1's 2026-09-22 S3 amendment, 10 section 2.4, CONTRACTS
## sections 12 and 15) -- plus the shell's own refusal copy for the catalogue ids those
## rows and the catalogue's remaining price source answer to.
##
## **The MODULES section is retired**: the AUCTION shelf sells the rolled instances now,
## so this suite guards the retirement (no rows, no constants, no scene nodes) and proves
## the AUCTION is the door instead. The strip survives the retirement and becomes a **battery
## list** (STATION_HUB section 5.1's 2026-09-23 S4 amendment, 09 section 10, CONTRACTS
## section 16): one row per battery of identical weapons, then one read-only line per empty W
## cell, so this suite's per-cell row assertions moved to the battery rows and the empty-cell
## assertions stayed. The single-cell REMOVE is still reachable through the row's `▸` expander
## and still writes through the composed `clear_fit_slot` (CONTRACTS section 13, S3-K4
## HIGH-1's cure), with the same `_seed_fit` guard, for a base-id cell and for a rolled
## instance alike; `tests/test_s4_batteries.gd` owns the expander's own reachability.
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

const PanelScene := preload("res://ui/station/outfitting_panel.tscn")
const PanelScript := preload("res://ui/station/outfitting_panel.gd")
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
## The ammo account every test starts from: a full laser (`AT CAP`), a half-full cannon
## (`IN STOCK`), an over-cap rocket (the default 300 against a 100 advisory cap), and
## empty mine and plasma. Written through the private field the dock's own report writes
## through.
const AMMO_FIXTURE: Dictionary = {
	&"laser": 300,
	&"cannon": 150,
	&"rocket": 300,
	&"mine": 0,
	&"plasma": 0,
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
	_host.name = "OutfittingHost"
	_host.theme = ThemeRes
	_host.size = _viewport_size()
	_fixture_host().add_child(_host)


func teardown() -> void:
	if _host != null and is_instance_valid(_host):
		_host.free()
	_host = null
	_panel = null


## The fixture account every test starts from: the Vanguard active and owned, no fit, no
## modules, 10 000 CR and `AMMO_FIXTURE`'s holds. Written through the same private fields
## `test_p2a_launch_fit.gd` hands back, so no purchase is charged and no signal fires before
## the pane is mounted.
func _seed_account() -> void:
	var owned: Array[StringName] = [VANGUARD]
	_profile.set(&"_credits", START_CREDITS)
	_profile.set(&"_active_ship", VANGUARD)
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_ammo", AMMO_FIXTURE.duplicate())


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
	return panel.get_node("%OutfittingRows") as VBoxContainer


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
func _strip_row(panel: Control, index: int) -> VBoxContainer:
	var strip := panel.get_node("%FittedStrip") as VBoxContainer
	return strip.get_child(index) as VBoxContainer


func _strip_main(panel: Control, index: int) -> HBoxContainer:
	return _strip_row(panel, index).get_node(^"Main") as HBoxContainer


func _strip_text(panel: Control, index: int) -> String:
	var text := _strip_main(panel, index).get_node_or_null(^"Text") as Label
	return text.text if text != null else ""


func _strip_control(panel: Control, index: int, control_name: String) -> Button:
	return _strip_main(panel, index).get_node(control_name) as Button


func _cell_line(panel: Control, index: int, line_index: int) -> HBoxContainer:
	var cells := _strip_row(panel, index).get_node(^"Cells") as VBoxContainer
	return cells.get_child(line_index) as HBoxContainer


func _cell_line_text(panel: Control, index: int, line_index: int) -> String:
	var text := _cell_line(panel, index, line_index).get_node_or_null(^"Text") as Label
	return text.text if text != null else ""


func _strip_lines(panel: Control) -> int:
	var strip := panel.get_node("%FittedStrip") as VBoxContainer
	var shown := 0
	for child: Node in strip.get_children():
		if (child as Control).visible:
			shown += 1
	return shown


func _press_ammo(panel: Control, pack_id: StringName) -> void:
	_ammo_row(panel, pack_id).pressed.emit()


## One of a battery row's three bulk plates, pressed.
func _press_bulk(panel: Control, index: int, control_name: String) -> void:
	_strip_control(panel, index, control_name).pressed.emit()


func _cells(hull: StringName) -> Array:
	return _profile.call(&"fit_for", hull)[WEAPON_SLOT]


func _held(pack_id: StringName) -> int:
	return int(_profile.call(&"ammo_of", pack_id))


## A **module** id's held count, which is not `ammo_of`: the strip's REMOVE hands a module
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


## The four state lines of section 5.1, over a fixture account that carries all four:
## `AT CAP` for a full laser, `IN STOCK` for a half-full cannon, `OVER CAP` for the
## default 300 against the rocket's advisory 100, `EMPTY` for the unheld mine.
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
			PanelScript.HELD_FORMAT % [_held(pack_id), int(_profile.call(&"ammo_max", pack_id))],
			"%s's HELD / MAX is the profile's own reading" % pack_id
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


## BUY charges the catalogue's own price and moves the held count and the tag; an
## unaffordable pack greys its price and the profile refuses the purchase without charging.
func test_ammo_purchase_charges_the_catalogue_price_and_greys_when_short() -> void:
	var panel := _mount()
	var pack := Catalog.ammo_pack(&"rocket")
	var rounds := int(pack[&"rounds"])
	var cost := int(pack[&"cost"])
	assert_eq(_held(&"rocket"), 300, "the fixture holds the default 300")
	_press_ammo(panel, &"rocket")
	assert_eq(_credits(), START_CREDITS - cost, "the buy charged the catalogue's cost")
	assert_eq(_held(&"rocket"), 300 + rounds, "and added the pack's own rounds")
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
## header, no rows box, no row set, no constants and none of the four fit actions. The
## FITTED WEAPONS strip is **not** part of the retirement (STATION_HUB section 5.1's S3
## amendment keeps it), so it is asserted present here and measured in its own test.
func test_the_module_rows_are_retired_from_the_pane_its_scene_and_its_script() -> void:
	var panel := _mount()
	assert_true(
		panel.get_node_or_null("%FittedStrip") != null, "the FITTED WEAPONS strip survives"
	)
	assert_eq(
		String((panel.get_node("%OutfittingScroll/OutfittingBody/FittedMargin/FittedBox/FittedCaption") as Label).text),
		"FITTED WEAPONS",
		"and keeps its own caption"
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
	var scene := FileAccess.get_file_as_string("res://ui/station/outfitting_panel.tscn")
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


## ------------------------------------------------------------- the surviving strip


## The strip is a battery list read from `ShipFit.grid_cells` + the fit the launch resolves:
## the Vanguard's three W cells carry one standard laser in W1, so the strip draws one battery
## row (its own three bulk plates and its `▸`) and two read-only empty-cell lines, and a hull
## switch re-reads the same fixed node set (STATION_HUB section 5.1's S4 amendment).
func test_fitted_strip_reads_the_active_hulls_w_cells() -> void:
	assert_eq(
		FitData.slot_capacity(VANGUARD, WEAPON_SLOT),
		VANGUARD_W_CELLS,
		"the Vanguard's matrix carries three W cells"
	)
	var panel := _mount()
	assert_eq(_strip_lines(panel), VANGUARD_W_CELLS, "three rows: one battery and two empties")
	var rows: Array = panel.call(&"strip_rows")
	assert_eq(rows.size(), 3, "every W cell of the active hull is accounted for")
	assert_eq(rows[0][&"kind"], &"battery", "the fitted cell's row is a battery")
	assert_eq(rows[0][&"cells"], [0], "covering the one cell the standard fit fills")
	assert_eq(
		_strip_text(panel, 0),
		PanelScript.BATTERY_TEXT % [
			1,
			"LASER MKII",
			PanelScript.BATTERY_CELLS % 1,
			PanelScript.BATTERY_OWNED % 0,
		],
		"the pin's own battery row reading"
	)
	assert_eq(_strip_text(panel, 1), "W2 — EMPTY", "the pin's own empty line")
	assert_eq(_strip_text(panel, 2), "W3 — EMPTY", "the Cutter's third cell")
	assert_eq(rows[1][&"kind"], &"empty", "an empty cell is its own read-only line")
	assert_eq(rows[1][&"cells"], [], "and covers no battery cell")
	assert_true(_strip_control(panel, 0, "RemoveAll").visible, "a battery row carries REMOVE ALL")
	assert_eq(
		PanelScript.STRIP_REMOVE_ALL,
		_strip_control(panel, 0, "RemoveAll").text,
		"whose plate is the pin's own word"
	)
	assert_true(_strip_control(panel, 0, "Expander").visible, "and its own expander")
	## The bag holds none of the base, so the two spending actions are disabled by state and
	## REMOVE ALL never is (STATION_HUB section 5.1).
	assert_true(_strip_control(panel, 0, "FitAll").disabled, "FIT ALL needs a bag instance")
	assert_true(_strip_control(panel, 0, "SwapAll").disabled, "and so does SWAP ALL")
	assert_false(_strip_control(panel, 0, "RemoveAll").disabled, "REMOVE ALL is never disabled")
	## An empty line carries no control at all: the whole row is read-only.
	assert_false(_strip_control(panel, 1, "RemoveAll").visible, "an empty line has no REMOVE")
	assert_false(_strip_control(panel, 1, "FitAll").visible, "and no FIT ALL")
	assert_false(_strip_control(panel, 1, "Expander").visible, "and no expander")
	assert_eq(_cell_line_text(panel, 1, 0), "", "and no revealed single-cell line")
	## A hull switch is the profile's own key: the Lancer carries two W cells and 09
	## section 9's two-laser fit, so its two barrels are **one** row without a rebuild of
	## the pane (09 section 10's grouping).
	assert_true(
		bool(_profile.call(&"buy_ship", LANCER, int(Catalog.ship(LANCER)[&"cost"]))),
		"the Lancer can be bought"
	)
	assert_true(bool(_profile.call(&"set_active_ship", LANCER)), "and made active")
	assert_eq(_strip_lines(panel), 1, "one row for the Lancer's two-barrel battery")
	rows = panel.call(&"strip_rows")
	assert_eq(rows[0][&"cells"], [0, 1], "covering both of its W cells")
	assert_eq(_strip_text(panel, 0), "2× LASER MKII · W1·W2 · OWNED ×0", "one battery, one row")


## The battery strip's `REMOVE ALL` is the ammo pane's one bulk fit write: it empties every
## cell of the battery, hands the module(s) back to the inventory, costs nothing, and never
## touches the mandatory set (09 section 4 items 9 to 13: only 09 section 9's W cells are
## reachable from here).
func test_strip_remove_is_the_ammo_panes_one_fit_action() -> void:
	var panel := _mount()
	assert_eq(_cells(VANGUARD), ["", "", ""], "a fresh account stores no fit for the hull")
	assert_true(
		_strip_control(panel, 0, "RemoveAll").visible, "the standard fit's laser is a battery"
	)
	assert_eq(_module_held(LASER), 0, "and the fixture holds no laser of its own")
	_press_bulk(panel, 0, "RemoveAll")
	assert_eq(_cells(VANGUARD)[0], "", "REMOVE ALL emptied the battery's cell")
	assert_eq(_module_held(LASER), 1, "and the module is back in the inventory")
	assert_eq(_strip_text(panel, 0), "W1 — EMPTY", "the strip reads the empty cell")
	assert_false(
		_strip_control(panel, 0, "RemoveAll").visible, "an emptied line carries no REMOVE ALL"
	)
	assert_eq(_credits(), START_CREDITS, "removing costs nothing")
	assert_eq(
		_last_status(),
		PanelScript.STATUS_REMOVED % "LASER MKII",
		"and the pane reports it in its own pinned wording"
	)
	assert_false(_last_danger(), "success is never the danger colour")
	## 09 section 7's mandatory set survives the whole round trip: the fit still has its
	## engine and its reactor and `fit_legal` reports nothing missing. Nothing this pane can
	## address is in `FitData.MANDATORY_SLOT_KEYS`, which is the guard rather than a second
	## rule (an index past the W cells is refused by `remove_module` itself).
	var fit: Dictionary = _profile.call(&"fit_for", VANGUARD)
	assert_eq(fit[ENGINE_SLOT], ["e_std"], "the engine set is untouched")
	assert_eq(fit[POWER_SLOT], "p_std", "the reactor is untouched")
	var legal: Dictionary = FitData.fit_legal(VANGUARD, fit)
	assert_eq(legal[&"missing"], [], "and the fit still has its mandatory set")
	assert_false(
		bool(panel.call(&"remove_module", VANGUARD_W_CELLS + 4)),
		"an index past the W cells refuses"
	)


## `REMOVE ALL` against a cell that holds an **instance** (S3-K4 HIGH-1). The composed
## `clear_fit_slot` banks the entry the cell holds as *itself*, so a weapon rolled and fitted
## through FITTING comes back with its own id, rarity and affix rows instead of being stranded
## at `count` 0 behind a fresh base-keyed Common (CONTRACTS section 15's `restore_instance`
## clause: REMOVE hands the same instance back, never destroyed, never duplicated).
func test_strip_remove_hands_back_the_fitted_instance() -> void:
	var panel := _mount()
	var instance := StringName(
		_profile.call(&"add_instance", LASER, &"magic", [{"id": "keen", "value": 0.16}], ["whale"])
	)
	assert_true(
		bool(_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 0, instance)),
		"the rolled instance fits the first W cell"
	)
	assert_eq(
		String(_cells(VANGUARD)[0]),
		String(instance),
		"the cell holds the instance id, not its base"
	)
	assert_eq(_module_count(instance), 0, "and the instance is out of the bag")
	assert_eq(_strip_text(panel, 0), "1× LASER MKII · W1 · OWNED ×0", "the strip names the base")
	assert_true(_strip_control(panel, 0, "RemoveAll").visible, "and carries REMOVE ALL")
	_press_bulk(panel, 0, "RemoveAll")
	assert_eq(_cells(VANGUARD)[0], "", "REMOVE ALL emptied the cell")
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
	assert_eq(_credits(), START_CREDITS, "removing costs nothing")
	assert_eq(
		_last_status(),
		PanelScript.STATUS_REMOVED % "LASER MKII",
		"and the pane reports it in its own pinned wording"
	)


## The duplication half of S3-K4 HIGH-1: a base-keyed unit of the same base already in the
## bag is not incremented by REMOVE ALL. The raw `add_module(base_id, 1)` this pane wrote
## before the fix banked a fresh unit whichever entry the cell held, so one physical unit
## became two and `Auction.sell_rows` priced both.
func test_strip_remove_does_not_duplicate_a_base_keyed_unit() -> void:
	var panel := _mount()
	var instance := StringName(_profile.call(&"add_instance", LASER, &"rare", [], []))
	assert_true(
		bool(_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 0, instance)),
		"the instance fits"
	)
	_profile.call(&"add_module", LASER, 1)
	assert_eq(_module_count(LASER), 1, "one plain base-keyed laser sits in the bag")
	_press_bulk(panel, 0, "RemoveAll")
	assert_eq(_module_count(instance), 1, "the fitted instance is back as itself")
	assert_eq(_module_count(LASER), 1, "and the base-keyed unit is still one unit, not two")
	assert_eq(
		(_profile.call(&"modules") as Dictionary).size(), 2, "two records: no third was minted"
	)
	assert_true(
		(_profile.call(&"instances_of", LASER) as Array).has(instance),
		"and the bag offers the restored instance"
	)


## ------------------------------------------------------------------- the refresh


## The refresh is the profile's signal, not a read-through: the ammo rows move on `credits`
## and `ammo`, the strip on `fits` and `ships`, and - since the battery row carries the bag
## figure it spends from (STATION_HUB section 5.1) - on `modules` too.
func test_profile_changed_drives_the_refresh() -> void:
	var panel := _mount()
	var row := _ammo_row(panel, &"plasma")
	assert_eq(_cell_text(row, "Status"), PanelScript.TAG_EMPTY, "the plasma pack starts empty")
	## Without the shell's wiring the pane is not told, and its cells do not move.
	_profile.disconnect(&"profile_changed", Callable(panel, &"refresh_profile"))
	_profile.call(&"set_ammo", &"plasma", 40)
	assert_eq(_held(&"plasma"), 40, "the hold moved")
	assert_eq(
		_cell_text(row, "Status"),
		PanelScript.TAG_EMPTY,
		"an unwired pane is stale: nothing refreshed it"
	)
	## Wired, the same key refreshes it, and so does a credits change.
	_profile.connect(&"profile_changed", Callable(panel, &"refresh_profile"))
	_profile.call(&"set_ammo", &"plasma", 41)
	assert_eq(_cell_text(row, "Status"), PanelScript.TAG_IN_STOCK, "ammo refreshed the tag")
	assert_eq(
		_cell_text(row, "Held"),
		PanelScript.HELD_FORMAT % [41, int(_profile.call(&"ammo_max", &"plasma"))],
		"and the held count"
	)
	assert_true(bool(_profile.call(&"spend", _credits())), "drain the balance")
	assert_true(_price_danger(row), "credits recomputed the price's colour")
	assert_true(
		bool(_profile.call(&"set_fit_slot", VANGUARD, WEAPON_SLOT, 0, RAILGUN)),
		"an external fit write"
	)
	assert_eq(
		_strip_text(panel, 0),
		"1× RAILGUN · W1 · OWNED ×0",
		"fits refreshed the battery row"
	)
	assert_eq(_strip_text(panel, 1), "W2 — EMPTY", "and left the empty cells empty")
	assert_true(_strip_control(panel, 0, "RemoveAll").visible, "with REMOVE ALL on the battery")
	## `modules` is the strip's own key now: the bag figure the row shows and the two actions
	## it gates are read through `instances_of`, so a bag write must move them. Before the S4
	## amendment the strip ignored this key (it read the fit alone).
	assert_true(_strip_control(panel, 0, "FitAll").disabled, "no railgun in the bag yet")
	_profile.call(&"add_module", RAILGUN, 1)
	assert_eq(
		_strip_text(panel, 0),
		"1× RAILGUN · W1 · OWNED ×1",
		"a modules write moved the battery's bag figure"
	)
	assert_false(_strip_control(panel, 0, "FitAll").disabled, "and re-enabled FIT ALL")
	assert_eq(_cells(VANGUARD)[0], RAILGUN, "and wrote no fit cell")
