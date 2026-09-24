@tool
extends McpTestSuite
## Suite s11_describe: wave S11's inspector body and its identity title (CONTRACTS
## section 23.1, amended 2026-09-24).
##
## It proves the four things the amended pin names, off the shipped files:
##  1. `StationCatalog.describe` reads `MineralCatalog` (a bare mineral id, an ore id and
##     an ingot id alike) and `ComponentCatalog`, so a REFINERY ore row and an EXCHANGE
##     mineral/component hold row show their own catalogue's prose;
##  2. an `ammo_*` cargo id still resolves to its pack, a `mod_*` instance still resolves
##     through its base and appends its rolled affix perks, and a description-less row
##     still answers `""` (never invented text);
##  3. each of the six item panes' inspector titles is the row's **identity** (its name
##     plus its price phrase) with no leading key-hint verb;
##  4. the same pane's status line still carries that verb, unchanged.
##
## The station is mounted once per suite, exactly as `ui/screens/station.tscn` ships it,
## so the six panes sit in their real ancestor chain and are read as the shell loads them.

const StationScene := preload("res://ui/screens/station.tscn")
const Catalog := preload("res://game/station_catalog.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")

const PROFILE_PATH := "user://test_s11_describe.cfg"

## The panel order `ui/screens/station.gd:MODULE_FILES` ships: the six item panes.
const ARMORY := 0
const REFINERY := 1
const EXCHANGE := 2
const AUCTION := 3
const SHIPYARD := 4
const FITTING := 5

const MINERAL: StringName = &"iron"
const ORE: StringName = &"mineral_iron"
const INGOT: StringName = &"ingot_iron"
const COMPONENT: StringName = &"comp_scrap_1"
const MODULE: StringName = &"w_cannon"
const SHIP: StringName = &"ship_vanguard"
const PACK: StringName = &"laser"
const AMMO_CARGO: StringName = &"ammo_laser"
const SUFFIX: StringName = &"leeches"

var _profile: Node = null
var _station: Control = null
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_fits: Dictionary = {}
var _previous_owned: Array = []
var _previous_modules: Dictionary = {}
var _previous_credits := 0
var _previous_ammo: Dictionary = {}


func suite_name() -> String:
	return "s11_describe"


func suite_setup(_ctx: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		skip_suite("a SceneTree is needed to mount the station")
		return
	var profile := tree.root.get_node_or_null(NodePath(&"PlayerProfile"))
	if profile == null:
		skip_suite("no PlayerProfile autoload to borrow")
		return
	_profile = profile
	_previous_path = String(_profile.get(&"save_path"))
	_previous_ship = StringName(_profile.get(&"_active_ship"))
	_previous_fits = (_profile.get(&"_fits") as Dictionary).duplicate(true)
	_previous_owned = (_profile.get(&"_owned_ships") as Array).duplicate(true)
	_previous_modules = (_profile.get(&"_modules") as Dictionary).duplicate(true)
	_previous_credits = int(_profile.call(&"credits"))
	_previous_ammo = (_profile.get(&"_ammo") as Dictionary).duplicate(true)
	_profile.set(&"save_path", PROFILE_PATH)
	_delete_file(PROFILE_PATH)
	_seed_account()
	_station = StationScene.instantiate() as Control
	if _station == null:
		fail_setup("ui/screens/station.tscn failed to instantiate")
		return
	var host := Control.new()
	host.name = "DescribeHost"
	host.theme = ThemeRes
	host.size = Vector2(1920.0, 1080.0)
	_profile.add_child(host)
	host.add_child(_station)


func suite_teardown() -> void:
	if _station != null and is_instance_valid(_station):
		_station.get_parent().free()
		_station = null
	if _profile == null:
		return
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_fits", _previous_fits)
	_profile.set(&"_owned_ships", _previous_owned)
	_profile.set(&"_modules", _previous_modules)
	_profile.set(&"_ammo", _previous_ammo)
	_profile.set(&"_credits", _previous_credits)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	_delete_file(PROFILE_PATH)
	_profile = null


func _seed_account() -> void:
	var owned: Array[StringName] = [SHIP]
	_profile.set(&"_active_ship", SHIP)
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_ammo", {})


func _delete_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _pane(index: int) -> CanvasItem:
	var panels: Array = _station.get(&"_panels")
	if index < 0 or index >= panels.size():
		return null
	return panels[index]


## ---------------------------------------------------- 1. the widened source list


func test_describe_reads_a_mineral_row() -> void:
	var row := MineralCatalog.mineral(MINERAL)
	var prose := String(row[&"description"])
	assert_eq(Catalog.describe(MINERAL), prose, "a bare mineral id reads its mineral row")
	assert_eq(Catalog.describe(ORE), prose, "a mineral_* ore id reads its mineral row")
	assert_eq(Catalog.describe(INGOT), prose, "an ingot_* id reads its mineral row")


func test_describe_reads_a_component_row() -> void:
	var row := ComponentCatalog.component(COMPONENT)
	assert_eq(
		Catalog.describe(COMPONENT),
		String(row[&"description"]),
		"a component id reads its component row"
	)


func test_describe_still_appends_the_rolled_affix_perks() -> void:
	var instance := StringName(
		_profile.call(&"add_instance", MODULE, &"magic", [], [SUFFIX])
	)
	assert_ne(instance, &"", "the profile must mint the instance")
	var described := Catalog.describe(instance)
	assert_contains(
		described, String(ModuleCatalog.module(MODULE)[&"description"]),
		"the base's own prose is still the head of the body"
	)
	assert_contains(
		described, String(ModuleCatalog.SUFFIXES[SUFFIX][&"perk"]),
		"the instance's rolled suffix perk is still appended"
	)
	assert_contains(described, Catalog.AFFIX_JOIN, "the join is the pinned separator")


func test_describe_still_maps_an_ammo_cargo_id_to_its_pack() -> void:
	assert_eq(Catalog.ammo_item_id(PACK), AMMO_CARGO, "the cargo id form is the pin's")
	assert_eq(
		Catalog.describe(AMMO_CARGO),
		String(Catalog.ammo_pack(PACK)[&"description"]),
		"an ammo cargo id reads its pack's prose"
	)
	assert_eq(
		Catalog.describe(AMMO_CARGO), Catalog.describe(PACK),
		"the cargo id and its family answer alike"
	)


func test_describe_is_empty_for_a_row_with_no_description() -> void:
	assert_eq(Catalog.describe(&""), "", "a blank id carries nothing")
	assert_eq(Catalog.describe(&"no_such_row"), "", "an unknown id carries nothing")
	assert_eq(Catalog.describe(&"mod_9999"), "", "an unresolvable instance carries nothing")


## ------------------------------------------------------- 2. the title and the hint


func test_armory_title_is_the_identity_and_the_hint_keeps_its_verb() -> void:
	var pane := _pane(ARMORY)
	var payload := {&"id": MODULE, &"name": "CANNON MKI", &"cost": 1200, &"complete": true}
	_assert_identity(
		pane, payload, "CANNON MKI", "ENTER BUY", String(pane.call(&"_row_hint", payload))
	)


func test_shipyard_title_is_the_identity_and_the_hint_keeps_its_verb() -> void:
	var pane := _pane(SHIPYARD)
	var payload := {&"id": SHIP, &"name": "VANGUARD"}
	_assert_identity(
		pane, payload, "VANGUARD", "ENTER PREVIEWS", String(pane.call(&"_row_hint", payload))
	)


func test_exchange_title_is_the_identity_and_the_hint_keeps_its_verb() -> void:
	var pane := _pane(EXCHANGE)
	var payload := {&"id": ORE, &"name": "IRON"}
	_assert_identity(
		pane, payload, "IRON", "ENTER SELECT", String(pane.call(&"_row_hint", payload))
	)


func test_auction_title_is_the_identity_and_the_hint_is_unchanged() -> void:
	## AUCTION's shipped `STATUS_HINT` renders its args in `[name, cost, action_word]` order,
	## so its footer reads `ENTER <name> · <cost> · <verb> CREDITS` rather than leading with
	## the verb. The pin keeps that wording byte-identical; this test reads it, they do not
	## move it. The title is the pin's identity: name plus price phrase, no key-hint verb.
	var pane := _pane(AUCTION)
	var payload := {&"id": SHIP, &"name": "VANGUARD", &"cost": 5000, &"action_word": "BUY"}
	var hint := String(pane.get_script().get_script_constant_map()["STATUS_HINT"])
	var status := String(pane.call(&"_row_hint", payload))
	assert_eq(
		status,
		hint % ["VANGUARD", "5 000", "BUY"],
		"the status strip's wording is the pane's own shipped hint, byte for byte"
	)
	assert_true(status.find("BUY") != -1, "the status line keeps the row's action verb")
	var seen := _emit_inspect(pane, payload)
	assert_eq(seen.size(), 1, "a focus writes the inspector once")
	if seen.is_empty():
		return
	var title := String(seen[0][0])
	assert_eq(title, "VANGUARD · 5 000 CREDITS", "the identity is name plus price phrase")
	assert_true(title.find("ENTER") == -1, "the title carries no key-hint verb")
	assert_ne(status, title, "the status line is not the identity line")


func test_refinery_title_is_the_identity_and_the_hint_keeps_its_verb() -> void:
	var pane := _pane(REFINERY)
	var payload := {&"id": MINERAL, &"name": "IRON ORE", &"conversions": 2, &"fee": 120}
	var conversions := String(pane.call(&"_conversions_text", 2))
	var ready := String(pane.get_script().get_script_constant_map()["STATUS_READY"])
	var status := ready % ["IRON ORE", conversions, "120"]
	_assert_identity(pane, payload, "IRON ORE", "READY", status)


func test_fitting_title_is_the_identity_with_no_hint_verb() -> void:
	## FITTING carries no leading hint verb: its rows print FIT/SWAP in the ACTION cell and
	## its status line is its own footer line, so B1's title (the row's own name) already is
	## the identity. The pane's status surface must still publish its own wording.
	var pane := _pane(FITTING)
	var payload := {&"name": "MAULER", &"entry": MODULE}
	var seen := _emit_inspect(pane, payload)
	assert_eq(seen.size(), 1, "a focus writes the inspector once")
	if seen.size() == 1:
		var title := String(seen[0][0])
		assert_eq(title, "MAULER", "the fitting title is the row's own name")
		assert_true(title.find("ENTER") == -1, "the fitting title carries no key-hint verb")
	var fit_word := String(pane.get_script().get_script_constant_map()["ACTION_FIT"])
	var lines: Array[String] = []
	var recorder := func(message: String, _danger: bool) -> void:
		lines.append(message)
	pane.connect(&"status_requested", recorder)
	pane.call(&"_notice", fit_word, false)
	pane.disconnect(&"status_requested", recorder)
	assert_eq(lines.size(), 1, "the pane still publishes its status line")
	if lines.size() == 1:
		assert_eq(lines[0], fit_word, "the status line is the pane's own action word")


## ---------------------------------------------------------------------- helpers


## A pane's inspector title for one row: connect, emit through the pane's own `_inspect_row`,
## capture and detach, so no recorder leaks into the next test.
func _emit_inspect(pane: CanvasItem, payload: Dictionary) -> Array:
	var seen: Array[Array] = []
	var recorder := _recorder(seen)
	pane.connect(&"inspect_requested", recorder)
	pane.call(&"_inspect_row", payload, true)
	if pane.is_connected(&"inspect_requested", recorder):
		pane.disconnect(&"inspect_requested", recorder)
	return seen


## The amended pin, one assertion per clause: the title names the row and drops the leading
## verb; the pane's status line is unchanged (`<verb> · <title>`, byte for byte).
func _assert_identity(
	pane: CanvasItem, payload: Dictionary, name: String, verb: String, status: String
) -> void:
	var seen := _emit_inspect(pane, payload)
	assert_eq(seen.size(), 1, "a focus writes the inspector once")
	if seen.is_empty():
		return
	var title := String(seen[0][0])
	assert_contains(title, name, "the inspector title names the row")
	assert_true(title.find("ENTER") == -1, "the inspector title carries no key-hint verb")
	assert_true(
		not title.begins_with(verb), "the inspector title drops the leading verb"
	)
	assert_true(status.begins_with(verb), "the status strip keeps its verb")
	assert_eq(
		status, verb + " · " + title, "the status line is its verb plus the identity"
	)


func _recorder(seen: Array[Array]) -> Callable:
	return func(title: String, body: String, danger: bool) -> void:
		seen.append([title, body, danger])
