@tool
extends McpTestSuite
## Suite p2b1_outfitting_panel: the OUTFITTING pane's MODULES section and FITTED WEAPONS
## strip (STATION_HUB section 5.1's amendment, CONTRACTS section 12, wave brief P2-B1
## section 3) plus the shell's own refusal copy for the ids those rows sell
## (`ui/screens/station.gd:_refusal_text`).
##
## The pane is mounted from the shipped scene with the shipped theme and driven through the
## wiring the station shell itself uses - the row's own `pressed` signal for an action
## (`ui/screens/station.gd:_connect_panel`) and `profile_changed` -> `refresh_profile` for
## the refresh (`_on_profile_changed`) - so nothing here re-implements the panel's dispatch.
## Every number is read off the panel (the strip's line text, the rows' STATUS / ACTION /
## PRICE cells) or off the profile (credits, `module_count`, `fit_for`), and the row set,
## the costs, the draws and the effect prose are parsed out of
## docs/gameplay/09_ship_slots_modules.md - section 3.1's table plus section 4 item 7's
## mining laser - so the surface cannot drift from 09.
##
## The profile is the shipped autoload, borrowed the way `test_p2a_launch_fit.gd` borrows
## it: `save_path` is repointed at a scratch file before the first mutation, the six fields
## the panel can write are seeded to a known account and handed back in `suite_teardown`,
## and the store is flushed while the scratch path is still in place, so the owner's
## `user://profile.cfg` is never written (probe hygiene L17).

const PanelScene := preload("res://ui/station/outfitting_panel.tscn")
const PanelScript := preload("res://ui/station/outfitting_panel.gd")
const StationScript := preload("res://ui/screens/station.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const Catalog := preload("res://game/station_catalog.gd")
const ModuleData := preload("res://game/module_catalog.gd")
const FitData := preload("res://game/ship_fit.gd")

const PROFILE_PATH := "user://test_p2b1_outfitting_panel.cfg"
const DOC_PATH := "res://../docs/gameplay/09_ship_slots_modules.md"
const HUB_PATH := "res://../docs/design/STATION_HUB.md"
const WEAPON_HEADING := "### 3.1 WEAPONS (W slots)"
const OVERLOAD_MARK := "PWR — OVER BY"
const SLOTS_FULL_MARK := "W SLOTS FULL"

const VANGUARD: StringName = &"ship_vanguard"
const LANCER: StringName = &"ship_fighter"
const WEAPON_SLOT: StringName = &"weapons"
const ENGINE_SLOT: StringName = &"engines"
const POWER_SLOT: StringName = &"power"
const STANDARD_ENGINE: StringName = &"e_std"
const STANDARD_REACTOR: StringName = &"p_std"
const LASER: StringName = &"w_laser"
const CANNON: StringName = &"w_cannon"
const ROCKET: StringName = &"w_rocket"
const MINE: StringName = &"w_mine"
const PLASMA: StringName = &"w_plasma"
const RAILGUN: StringName = &"w_railgun"
## 09 section 4 item 7's seventh weapon module: the one 09 section 3.1's table does not carry.
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


## The fixture account every test starts from: the Vanguard active and owned, no fit and no
## modules, 10 000 CR. Written through the same private fields `test_p2a_launch_fit.gd`
## hands back, so no purchase is charged and no signal fires before the pane is mounted.
func _seed_account() -> void:
	var owned: Array[StringName] = [VANGUARD]
	_profile.set(&"_credits", START_CREDITS)
	_profile.set(&"_active_ship", VANGUARD)
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})


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


## --------------------------------------------------------------- document parsers


func _doc_lines(path: String) -> PackedStringArray:
	assert_true(FileAccess.file_exists(path), "%s is reachable" % path)
	return FileAccess.get_file_as_string(path).split("\n")


func _heading_index(lines: PackedStringArray, prefix: String) -> int:
	for index: int in lines.size():
		if String(lines[index]).begins_with(prefix):
			return index
	return -1


## 09 section 3.1's WEAPONS table, read off the render: `ids` in the table's own row order
## and `rows` as id -> {draw, cost, effect}. The costs carry the document's thousands space
## and the ids their backticks; both are stripped here.
func _document_weapons() -> Dictionary:
	var lines := _doc_lines(DOC_PATH)
	var start := _heading_index(lines, WEAPON_HEADING)
	assert_true(start >= 0, "09 section 3.1's heading is in the document")
	var ids := PackedStringArray()
	var rows: Dictionary = {}
	if start < 0:
		return {&"ids": ids, &"rows": rows}
	for index in range(start + 1, lines.size()):
		var line := String(lines[index]).strip_edges()
		if line.begins_with("#"):
			break
		if not line.begins_with("|"):
			continue
		var cells := line.split("|", false)
		if cells.size() != 7:
			continue
		var id_cell := String(cells[0]).strip_edges().trim_prefix("`").trim_suffix("`")
		if id_cell.is_empty() or id_cell == "Module":
			continue
		if id_cell.replace("-", "").strip_edges().is_empty():
			continue
		ids.append(id_cell)
		rows[id_cell] = {
			&"draw": int(String(cells[2]).strip_edges()),
			&"effect": String(cells[5]).strip_edges(),
			&"cost": int(
				String(cells[6]).strip_edges().replace(" ", "").replace("\u00a0", "")
			),
		}
	return {&"ids": ids, &"rows": rows}


## The backticked string on the first line of `path` carrying `marker`: 09 section 2's
## overload example and STATION_HUB section 5.1's two refusal wordings live that way.
func _document_quoted(path: String, marker: String) -> String:
	for line: String in _doc_lines(path):
		if line.find(marker) == -1:
			continue
		var open := line.find("`")
		var close := line.find("`", open + 1)
		if open >= 0 and close > open:
			return line.substr(open + 1, close - open - 1)
	return ""


## One numbered 09 section 4 item's prose, read off the render: the item's own line plus every
## line it wraps over, up to the next numbered item or heading. Lines are joined with a space
## so a phrase the document wraps matches a phrase the panel renders on one line.
func _document_item(number: int, marker: String) -> String:
	var lines := _doc_lines(DOC_PATH)
	var prefix := "%d. " % number
	var start := _heading_index(lines, prefix + marker)
	assert_true(start >= 0, "09 section 4 item %d is in the document" % number)
	var prose := ""
	for index in range(start, lines.size()):
		var line := String(lines[index])
		if index > start and (line.begins_with("#") or line.begins_with("%d. " % (number + 1))):
			break
		prose += " " + line.strip_edges()
	return prose.strip_edges()


## The first integer in `text` after `marker` (`draw 1, cost 600` -> 1 / 600), or -1 when the
## marker is absent: the numbers stay the document's own rather than a transcription.
func _document_number(prose: String, marker: String) -> int:
	var at := prose.find(marker)
	if at < 0:
		return -1
	var rest := prose.substr(at + marker.length()).strip_edges()
	var digits := ""
	for index in rest.length():
		var glyph := rest[index]
		if glyph >= "0" and glyph <= "9":
			digits += glyph
			continue
		if not digits.is_empty():
			break
		if glyph != " ":
			return -1
	return int(digits) if not digits.is_empty() else -1


## 09 section 3.1's own family / shield-rule note for the mining laser, joined the same way:
## the line naming `w_mining` and the lines it wraps over. The note's sentence starts mid-line
## (the table's family list comes first), so this matches on containment, not on a prefix.
func _document_mining_note() -> String:
	var lines := _doc_lines(DOC_PATH)
	var start := -1
	for index: int in lines.size():
		if String(lines[index]).find("The mining laser (`w_mining`") >= 0:
			start = index
			break
	assert_true(start >= 0, "09 section 3.1 carries the mining laser's family note")
	if start < 0:
		return ""
	var prose := ""
	for index in range(start, lines.size()):
		var line := String(lines[index])
		if index > start and (line.strip_edges().is_empty() or line.begins_with("#")):
			break
		prose += " " + line.strip_edges()
	return prose.strip_edges()


## --------------------------------------------------------------- panel read-backs


func _module_row(panel: Control, module_id: StringName) -> Button:
	var rows := panel.get_node("%ModuleRows") as VBoxContainer
	for child: Node in rows.get_children():
		var row := child as Button
		if row != null and StringName(row.get_meta(&"id", &"")) == module_id:
			return row
	return null


func _cell_text(row: Button, cell_name: String) -> String:
	var cell := row.find_child(cell_name, true, false) as Control
	if cell == null:
		return ""
	var value := cell.get_node_or_null(^"Value") as Label
	return value.text if value != null else ""


func _price_danger(row: Button) -> bool:
	var price := row.find_child("Price", true, false) as Control
	var value := price.get_node_or_null(^"Value") as Label
	return value != null and value.has_theme_color_override(&"font_color")


func _strip_line(panel: Control, index: int) -> HBoxContainer:
	var strip := panel.get_node("%FittedStrip") as VBoxContainer
	return strip.get_child(index) as HBoxContainer


func _strip_text(panel: Control, index: int) -> String:
	var line := _strip_line(panel, index)
	var text := line.get_node_or_null(^"Text") as Label
	return text.text if text != null else ""


func _strip_remove(panel: Control, index: int) -> Button:
	return _strip_line(panel, index).get_node(^"Remove") as Button


func _strip_lines(panel: Control) -> int:
	var strip := panel.get_node("%FittedStrip") as VBoxContainer
	var shown := 0
	for child: Node in strip.get_children():
		if (child as Control).visible:
			shown += 1
	return shown


func _press(panel: Control, module_id: StringName) -> void:
	_module_row(panel, module_id).pressed.emit()


func _cells(hull: StringName) -> Array:
	return _profile.call(&"fit_for", hull)[WEAPON_SLOT]


func _owned(module_id: StringName) -> int:
	return int(_profile.call(&"module_count", module_id))


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


## ------------------------------------------------------- the row set and its numbers


## The MODULES rows are 09 section 3.1's table, in its order, with its own costs, draws and
## effect prose, and 09 section 4 item 7's mining laser rides beside them as the seventh row
## (P2-B1 F1, R1's MED-2: that row is the mining laser's only door). The ids/order/prose are
## parsed out of the document and the costs/draws out of the catalogue the panel reads, so
## neither can drift from the pin.
func test_module_rows_are_09_3_1s_table_in_order() -> void:
	var doc := _document_weapons()
	var ids: PackedStringArray = doc[&"ids"]
	var rows: Dictionary = doc[&"rows"]
	assert_eq(ids.size(), 6, "09 section 3.1's table carries six weapon rows")
	var panel := _mount()
	var panel_ids: Array[StringName] = panel.call(&"module_row_ids")
	assert_eq(panel_ids.size(), ids.size() + 1, "the pane renders the table plus the mining laser")
	assert_eq(panel_ids[ids.size()], MINING, "and 09 section 4 item 7's mining laser is the seventh")
	for index in ids.size():
		var id := StringName(ids[index])
		assert_eq(panel_ids[index], id, "row %d is 09 section 3.1's own order" % index)
		var row := _module_row(panel, id)
		assert_true(row != null, "%s has a row" % id)
		if row == null:
			continue
		var expected: Dictionary = rows[ids[index]]
		var title := row.find_child("Title", true, false) as Label
		assert_eq(
			String(ModuleData.module(id).get(&"name", "")),
			title.text,
			"%s's title is the catalogue's name" % id
		)
		assert_eq(
			str(ModuleData.module(id)[&"draw"]),
			str(expected[&"draw"]),
			"%s's draw is the table's" % id
		)
		assert_eq(
			str(ModuleData.module(id)[&"cost"]),
			str(expected[&"cost"]),
			"%s's catalogue cost is the table's" % id
		)
		assert_eq(
			_cell_text(row, "Price").replace(" ", ""),
			str(expected[&"cost"]),
			"%s's PRICE is the table's cost" % id
		)
		assert_eq(
			_cell_text(row, "Effect"),
			String(expected[&"effect"]),
			"%s's EFFECT is the table's prose" % id
		)
		var meta := row.find_child("Meta", true, false) as Label
		assert_eq(
			meta.text, "W SLOT · DRAW %d" % int(expected[&"draw"]), "%s's meta is the draw" % id
		)
		## A fresh account holds no fit for the Vanguard, so the strip and the rows read 09
		## section 9's standard fit: the laser is already fitted in W1, the rest are for sale.
		var expected_status := "FITTED (W1)" if id == LASER else "FOR SALE"
		assert_eq(_cell_text(row, "Status"), expected_status, "%s's STATUS on a fresh account" % id)
		assert_eq(_cell_text(row, "Action"), "BUY", "%s's first action is BUY" % id)
	## 09 section 4 item 7's mining laser: the seventh row, at the item's own draw and cost,
	## with an EFFECT assembled from 09's own words (section 3.1's family / shield-rule note
	## plus item 7's W slot sentence).
	var mining_prose := _document_item(7, "**Mining laser rule")
	var mining_note := _document_mining_note()
	var mining_draw := _document_number(mining_prose, "draw ")
	var mining_cost := _document_number(mining_prose, "cost ")
	assert_eq(mining_draw, 1, "09 section 4 item 7 gives the mining laser draw 1")
	assert_eq(mining_cost, 600, "and 600 CR")
	assert_eq(
		str(ModuleData.module(MINING)[&"cost"]), str(mining_cost), "its catalogue cost is item 7's"
	)
	assert_eq(str(ModuleData.module(MINING)[&"draw"]), str(mining_draw), "its draw is item 7's")
	var mining := _module_row(panel, MINING)
	assert_true(mining != null, "w_mining has a row")
	if mining == null:
		return
	assert_eq(
		_cell_text(mining, "Price").replace(" ", ""), str(mining_cost), "its PRICE is item 7's 600"
	)
	var mining_meta := mining.find_child("Meta", true, false) as Label
	assert_eq(mining_meta.text, "W SLOT · DRAW %d" % mining_draw, "its meta is item 7's draw")
	assert_true(
		PanelScript.EFFECT_TEXT.has(MINING), "the mining laser's effect prose is transcribed"
	)
	assert_eq(
		_cell_text(mining, "Effect"),
		String(PanelScript.EFFECT_TEXT.get(MINING, "")),
		"and the row renders it"
	)
	assert_true(
		mining_note.find("tool") >= 0 and mining_note.find("rocks only") >= 0,
		"09 section 3.1's note carries the family and the shield rule"
	)
	assert_true(
		mining_prose.find("occupies a W slot") >= 0, "and item 7 puts it in a W slot"
	)
	assert_eq(_cell_text(mining, "Status"), "FOR SALE", "w_mining is for sale on a fresh account")
	assert_eq(_cell_text(mining, "Action"), "BUY", "and its first action is BUY")


## The closed door's guard (P2-B1 F1, R1's MED-2): every weapon-slot id the catalogue ships
## has a row on this surface, the row is pressable and it carries an ACTION. An id without a
## row is a module the player can never obtain (the AUCTION is future), which is exactly what
## let `w_mining` ship with no door.
func test_every_catalogue_weapon_has_a_pressable_row() -> void:
	var panel := _mount()
	var catalogue_ids: Array[StringName] = []
	for id: StringName in ModuleData.MODULES:
		if ModuleData.slot_of(id) == WEAPON_SLOT:
			catalogue_ids.append(id)
	var panel_ids: Array[StringName] = panel.call(&"module_row_ids")
	assert_eq(panel_ids.size(), catalogue_ids.size(), "one row per catalogue weapon id")
	var missing: Array[StringName] = []
	for id: StringName in catalogue_ids:
		var row := _module_row(panel, id)
		if row == null or row.disabled or _cell_text(row, "Action").is_empty():
			missing.append(id)
	assert_eq(missing, [], "every catalogue weapon id has a pressable row")
	## And the door opens: the mining laser's own row buys it, at 09 section 4 item 7's cost.
	var mining_cost := _document_number(_document_item(7, "**Mining laser rule"), "cost ")
	assert_eq(_owned(MINING), 0, "the mining laser starts unowned")
	_press(panel, MINING)
	assert_eq(_owned(MINING), 1, "and its own row buys it")
	assert_eq(_credits(), START_CREDITS - mining_cost, "charging 09 section 4 item 7's cost")
	assert_eq(
		_cell_text(_module_row(panel, MINING), "Status"), "OWNED ×1", "and the row reads owned"
	)


## The shell's own refusal copy for a module (P2-B1 F1, R1's MED-1): `purchase_failed` carries
## the reason and the id, and `ui/screens/station.gd` resolves the entry behind them. A module
## id it cannot resolve rendered a fabricated `0 NEEDED`, so this pins the shell's copy to the
## cost 09 gives the module - section 3.1's table for the railgun, section 4 item 7 for the
## mining laser - while the ammo pack's own line stays exactly as it was.
func test_shell_refusal_names_a_module_cost() -> void:
	var doc := _document_weapons()
	var rows: Dictionary = doc[&"rows"]
	var shell: Node = StationScript.new()
	var railgun_cost := int(rows[&"w_railgun"][&"cost"])
	assert_eq(
		_digits_only(String(shell.call(&"_refusal_text", &"insufficient_credits", RAILGUN))),
		str(railgun_cost),
		"the shell names 09 section 3.1's own price for the railgun, not 0"
	)
	var mining_cost := _document_number(_document_item(7, "**Mining laser rule"), "cost ")
	assert_eq(
		_digits_only(String(shell.call(&"_refusal_text", &"insufficient_credits", MINING))),
		str(mining_cost),
		"and 09 section 4 item 7's price for the mining laser"
	)
	assert_eq(
		int(shell.call(&"_entry_cost", RAILGUN)),
		railgun_cost,
		"the entry the copy resolves is the catalogue's"
	)
	## The families the shell already resolved are untouched: the ammo pack still reads its own
	## price, and an id no catalogue ships still resolves to nothing rather than to a number.
	var pack_cost := int(Catalog.ammo_pack(&"laser").get(&"cost", -1))
	assert_eq(
		_digits_only(String(shell.call(&"_refusal_text", &"insufficient_credits", &"laser"))),
		str(pack_cost),
		"the ammo pack's copy is unchanged"
	)
	assert_eq(
		int(shell.call(&"_entry_cost", &"w_not_a_module")), 0, "an unknown id resolves to nothing"
	)
	shell.free()


## The digits of `text`, separators and words dropped: the shell groups its numbers with the
## project's thousands space, so `5 200 NEEDED` and the document's own `5 200` compare equal.
func _digits_only(text: String) -> String:
	var digits := ""
	for index in text.length():
		var glyph := text[index]
		if glyph >= "0" and glyph <= "9":
			digits += glyph
	return digits


## The strip is one line per W cell of the active hull, read from `ShipFit.grid_cells` +
## the fit the launch resolves: the Vanguard's own three cells, `W1 LASER MKII` from 09
## section 9's standard fit, and REMOVE on the fitted line only.
func test_fitted_strip_reads_the_active_hulls_w_cells() -> void:
	assert_eq(
		FitData.slot_capacity(VANGUARD, WEAPON_SLOT),
		VANGUARD_W_CELLS,
		"the Vanguard's matrix carries three W cells"
	)
	var panel := _mount()
	assert_eq(_strip_lines(panel), VANGUARD_W_CELLS, "one line per W cell of the active hull")
	assert_eq(_strip_text(panel, 0), "W1 LASER MKII", "the pin's own fitted line")
	assert_eq(_strip_text(panel, 1), "W2 — EMPTY", "the pin's own empty line")
	assert_eq(_strip_text(panel, 2), "W3 — EMPTY", "the Cutter's third cell")
	assert_true(_strip_remove(panel, 0).visible, "a fitted line carries REMOVE")
	assert_false(_strip_remove(panel, 1).visible, "an empty line does not")
	assert_false(_strip_remove(panel, 2).visible, "nor does the third")
	## A hull switch is the profile's own key: the Lancer carries two W cells and 09
	## section 9's two-laser fit, so the strip follows the active hull without a rebuild of
	## the pane.
	assert_true(
		bool(_profile.call(&"buy_ship", LANCER, int(Catalog.ship(LANCER)[&"cost"]))),
		"the Lancer can be bought"
	)
	assert_true(bool(_profile.call(&"set_active_ship", LANCER)), "and made active")
	assert_eq(_strip_lines(panel), 2, "the Lancer's own two W cells")
	assert_eq(_strip_text(panel, 0), "W1 LASER MKII", "its first standard laser")
	assert_eq(_strip_text(panel, 1), "W2 LASER MKII", "and its second")
	assert_true(_strip_remove(panel, 1).visible, "both lines carry REMOVE")


## ------------------------------------------------------------- the four state changes


## BUY -> INSTALL (the first empty W cell) -> SWAP (the displaced module returns to the
## inventory) -> REMOVE (from the row and from the strip's own line), across the Vanguard's
## three W cells, with the credits, the inventory, the fit and the pane's own cells checked
## at every step.
func test_buy_install_swap_remove_round_trip() -> void:
	var panel := _mount()
	assert_eq(_cells(VANGUARD), ["", "", ""], "a fresh account stores no fit for the hull")

	## BUY: the catalogue's price, one into the inventory, the row's own state follows.
	_press(panel, CANNON)
	assert_eq(_credits(), START_CREDITS - 1200, "the buy charged 09 section 3.1's 1 200")
	assert_eq(_owned(CANNON), 1, "and put one cannon in the inventory")
	assert_eq(_cell_text(_module_row(panel, CANNON), "Status"), "OWNED ×1", "STATUS is OWNED")
	assert_eq(_cell_text(_module_row(panel, CANNON), "Action"), "INSTALL", "ACTION is INSTALL")

	## INSTALL fills the *first* empty W cell: W1 holds the standard fit's laser, so W2.
	_press(panel, CANNON)
	assert_eq(_cells(VANGUARD)[1], "w_cannon", "INSTALL filled the first empty W cell")
	assert_eq(_owned(CANNON), 0, "and took the module out of the inventory")
	assert_eq(_strip_text(panel, 1), "W2 CANNON MKI", "the strip reads the new cell")
	assert_eq(_cell_text(_module_row(panel, CANNON), "Status"), "FITTED (W2)", "STATUS is FITTED")
	assert_eq(
		_cell_text(_module_row(panel, CANNON), "Action"),
		"BUY",
		"a fitted module with no spare offers a second copy"
	)

	## 09 section 4 item 4 lets a weapon repeat: with a spare in the inventory and a cell
	## still empty the same row installs the second copy rather than pinning itself to
	## REMOVE, so the surface can build a two-cannon fit.
	_press(panel, CANNON)
	assert_eq(_credits(), START_CREDITS - 1200 - 1200, "the second cannon charged 1 200")
	assert_eq(_owned(CANNON), 1, "and is in the inventory")
	assert_eq(
		_cell_text(_module_row(panel, CANNON), "Action"),
		"INSTALL",
		"an owned spare installs beside the fitted copy (09 section 4 item 4)"
	)
	_press(panel, CANNON)
	assert_eq(
		_cells(VANGUARD), ["w_laser", "w_cannon", "w_cannon"], "two cannons, one per cell"
	)
	assert_eq(_owned(CANNON), 0, "and the spare left the inventory")

	## With every W cell full and a module the account holds, the row offers SWAP.
	_press(panel, ROCKET)
	assert_eq(_credits(), START_CREDITS - 1200 - 1200 - 2400, "the rocket charged 2 400")
	assert_eq(_owned(ROCKET), 1, "and is in the inventory")
	assert_eq(
		_cell_text(_module_row(panel, ROCKET), "Action"),
		"SWAP",
		"no empty W cell, so the row offers SWAP"
	)

	## SWAP takes the first W cell and hands the displaced module back.
	_press(panel, ROCKET)
	assert_eq(_cells(VANGUARD)[0], "w_rocket", "SWAP wrote the first W cell")
	assert_eq(_owned(ROCKET), 0, "the rocket left the inventory")
	assert_eq(_owned(LASER), 1, "and the displaced laser is in the inventory, not destroyed")
	assert_eq(_strip_text(panel, 0), "W1 ROCKET POD", "the strip follows the swap")
	assert_eq(_cell_text(_module_row(panel, ROCKET), "Status"), "FITTED (W1)", "STATUS is FITTED")
	assert_eq(
		_cell_text(_module_row(panel, ROCKET), "Action"),
		"REMOVE",
		"a fitted module on a full grid is offered REMOVE"
	)

	## REMOVE from the row, then from the strip's own line.
	_press(panel, ROCKET)
	assert_eq(_cells(VANGUARD)[0], "", "the row's REMOVE emptied the cell")
	assert_eq(_owned(ROCKET), 1, "and the module is back in the inventory")
	assert_eq(_strip_text(panel, 0), "W1 — EMPTY", "the strip reads the empty cell")
	assert_false(_strip_remove(panel, 0).visible, "an emptied line carries no REMOVE")
	_strip_remove(panel, 2).pressed.emit()
	assert_eq(_cells(VANGUARD)[2], "", "the strip's REMOVE emptied the third cell")
	assert_eq(_owned(CANNON), 1, "and the second cannon is back in the inventory")
	assert_eq(_strip_text(panel, 2), "W3 — EMPTY", "the strip reads it")
	assert_eq(_credits(), START_CREDITS - 1200 - 1200 - 2400, "removing costs nothing")
	assert_eq(_owned(LASER), 1, "the swapped-out laser is still held")
	assert_eq(
		_cells(VANGUARD), ["", "w_cannon", ""], "and the fit holds only what is fitted"
	)


## The power refusal: 09 section 2's over-by line over the *candidate* fit's arithmetic, in
## the pane's own footer strip, with nothing written and nothing auto-removed.
func test_power_overload_refusal_shows_the_over_by_line() -> void:
	var panel := _mount()
	_press(panel, PLASMA)
	_press(panel, PLASMA)
	assert_eq(_cells(VANGUARD)[1], "w_plasma", "the first plasma fits the budget")
	assert_eq(_strip_text(panel, 1), "W2 PLASMA COIL", "and the strip reads it")
	_press(panel, PLASMA)
	_press(panel, PLASMA)
	## The candidate draws 1 (laser) + 3 (plasma) + 3 (plasma) + 2 (light shield) = 9
	## against the Vanguard's 8 + `p_std`'s 0 = 8, so it is over by 1.
	assert_eq(_last_status(), "9 / 8 PWR — OVER BY 1", "the pane renders 09 section 2's format")
	assert_true(_last_danger(), "and renders it as danger")
	assert_eq(_cells(VANGUARD)[2], "", "the refused install wrote nothing")
	assert_eq(_owned(PLASMA), 1, "the module stayed in the inventory")
	assert_eq(_credits(), START_CREDITS - 4800 - 4800, "and nothing was charged")
	assert_eq(_strip_text(panel, 2), "W3 — EMPTY", "the strip still reads the empty cell")
	assert_eq(_cell_text(_module_row(panel, PLASMA), "Status"), "FITTED (W2)", "STATUS is FITTED")
	assert_eq(
		_cell_text(_module_row(panel, PLASMA), "Action"),
		"INSTALL",
		"and the row still offers the install that was refused"
	)
	## The pane's format is 09 section 2's own: applied to that example's numbers it
	## reproduces the document's string byte for byte.
	var example := _document_quoted(DOC_PATH, OVERLOAD_MARK)
	assert_eq(example, "13 / 11 PWR — OVER BY 2", "09 section 2's own over-by example")
	assert_eq(
		PanelScript.REFUSAL_OVERLOAD % [13, 11, 2],
		example,
		"the pane's format reproduces 09 section 2's example"
	)


## The full-cells refusal: an INSTALL with no empty W cell renders STATION_HUB section
## 5.1's own line, while the row itself offers SWAP for the same state.
func test_full_cells_refusal_line() -> void:
	var panel := _mount()
	_press(panel, PLASMA)
	_press(panel, PLASMA)
	_press(panel, ROCKET)
	_press(panel, ROCKET)
	assert_eq(_cells(VANGUARD), ["w_laser", "w_plasma", "w_rocket"], "every W cell is full")
	_press(panel, MINE)
	assert_eq(_owned(MINE), 1, "the mine is in the inventory")
	assert_eq(
		_cell_text(_module_row(panel, MINE), "Action"),
		"SWAP",
		"the row offers SWAP rather than a doomed INSTALL"
	)
	assert_false(
		bool(panel.call(&"install_module", MINE)),
		"INSTALL itself is refused when no cell is empty"
	)
	assert_eq(
		_last_status(),
		_document_quoted(HUB_PATH, SLOTS_FULL_MARK),
		"the pane renders STATION_HUB section 5.1's own full-cells line"
	)
	assert_eq(_last_status(), "W SLOTS FULL — SWAP OR REMOVE FIRST", "byte for byte")
	assert_true(_last_danger(), "and renders it as danger")
	assert_eq(_owned(MINE), 1, "the refused install gave nothing")
	assert_eq(_cells(VANGUARD), ["w_laser", "w_plasma", "w_rocket"], "and wrote nothing")
	## The SWAP the row offered does the job instead, and the displaced module comes back.
	assert_true(bool(panel.call(&"swap_module", MINE, 0)), "the SWAP itself is legal")
	assert_eq(_cells(VANGUARD)[0], "w_mine", "SWAP wrote the first W cell")
	assert_eq(_owned(LASER), 1, "and the displaced laser is back in the inventory")


## The mandatory set is untouchable from this surface: no row is an engine or a reactor, an
## engine id cannot be installed into a W cell, and the hull's own mandatory set survives a
## full round trip with `fit_legal` reporting nothing missing.
func test_mandatory_set_is_untouchable() -> void:
	var panel := _mount()
	var rows: Array[StringName] = panel.call(&"module_row_ids")
	assert_eq(rows.size(), 7, "seven rows: 09 section 3.1's six plus 09 section 4 item 7's")
	for id: StringName in rows:
		assert_eq(
			String(ModuleData.slot_of(id)), "weapons", "%s is a W module, not an engine" % id
		)
		assert_ne(id, STANDARD_ENGINE, "no engine row exists")
		assert_ne(id, STANDARD_REACTOR, "no reactor row exists")
	assert_eq(_strip_lines(panel), VANGUARD_W_CELLS, "the strip carries W cells only")
	assert_false(
		bool(panel.call(&"install_module", STANDARD_ENGINE)),
		"an engine id cannot be installed into a W cell"
	)
	assert_false(
		bool(panel.call(&"swap_module", STANDARD_REACTOR, 0)),
		"nor can a reactor be swapped in"
	)
	assert_eq(_cells(VANGUARD), ["", "", ""], "and neither write touched the fit")
	assert_eq(_status.size(), 0, "neither emitted a footer line")
	## A full round trip leaves the mandatory set exactly where the launch put it.
	_press(panel, CANNON)
	_press(panel, CANNON)
	_press(panel, MINE)
	_press(panel, MINE)
	var fit: Dictionary = _profile.call(&"fit_for", VANGUARD)
	assert_eq(fit[ENGINE_SLOT], ["e_std"], "the engine set is untouched")
	assert_eq(fit[POWER_SLOT], "p_std", "the reactor is untouched")
	var legal: Dictionary = FitData.fit_legal(VANGUARD, fit)
	assert_eq(legal[&"missing"], [], "and the fit still has its mandatory set")
	assert_eq(legal[&"overflow"], {}, "with no cell overflow")


## The refresh is the profile's signal, not a read-through: the pane's own cells and strip
## move when the profile changes underneath it and stay put when nothing is connected.
func test_profile_changed_drives_the_refresh() -> void:
	var panel := _mount()
	var row := _module_row(panel, RAILGUN)
	assert_eq(_cell_text(row, "Status"), "FOR SALE", "the railgun starts for sale")
	## Without the shell's wiring the pane is not told, and its cells do not move.
	_profile.disconnect(&"profile_changed", Callable(panel, &"refresh_profile"))
	assert_true(bool(_profile.call(&"buy_module", RAILGUN, 5200)), "the railgun is bought")
	assert_eq(_owned(RAILGUN), 1, "and is in the inventory")
	assert_eq(
		_cell_text(row, "Status"),
		"FOR SALE",
		"an unwired pane is stale: nothing refreshed it"
	)
	## Wired, the same key refreshes it: `modules` moves the status, `fits` the strip.
	_profile.connect(&"profile_changed", Callable(panel, &"refresh_profile"))
	_profile.call(&"add_module", CANNON, 1)
	assert_eq(_owned(CANNON), 1, "a cannon arrives in the inventory")
	assert_eq(_cell_text(_module_row(panel, CANNON), "Status"), "OWNED ×1", "modules refreshed")
	assert_eq(_cell_text(_module_row(panel, CANNON), "Action"), "INSTALL", "and its action")
	assert_true(
		bool(_profile.call(&"set_fit_slot", VANGUARD, WEAPON_SLOT, 0, RAILGUN)),
		"an external fit write"
	)
	assert_eq(_strip_text(panel, 0), "W1 RAILGUN", "fits refreshed the strip")
	assert_eq(_strip_text(panel, 1), "W2 — EMPTY", "and left the empty cells empty")
	assert_true(_strip_remove(panel, 0).visible, "with REMOVE on the new fitted line")
	## `credits` is the third key the pane listens to: an unaffordable module locks.
	assert_true(bool(_profile.call(&"spend", _credits())), "drain the balance")
	assert_eq(_cell_text(_module_row(panel, ROCKET), "Status"), "LOCKED", "credits locked it")
	assert_eq(_cell_text(_module_row(panel, ROCKET), "Action"), "BUY", "BUY is still offered")
	assert_true(_price_danger(_module_row(panel, ROCKET)), "and the price is greyed in danger")
