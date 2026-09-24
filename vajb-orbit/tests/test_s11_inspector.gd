@tool
extends McpTestSuite
## Suite s11_inspector: wave S11's station inspector (CONTRACTS section 23.1).
##
## It proves the four things the pin names, off the shipped files:
##  1. `inspect_requested(title, body, danger)` is declared on all eight station panes;
##  2. an item pane emits it on a hover-in, hands the row's catalogue description as the
##     body, and **clears** it (`title == ""`) on the hover-out;
##  3. `StationCatalog.describe` resolves a `mod_*` instance through its base, appends the
##     instance's rolled affix perks, and answers `""` for a row with no description;
##  4. the shell block exists above the status strip with the pinned variations, the
##     `Tokens/text_primary` body override, the two-line cap and `group_int` as the one
##     digit-grouping copy (`ui/screens/station.gd:_format_int` delegates to it);
##  5. the HUD's `CreditsBlock` (section 23.3): it reads the profile's credits, follows a
##     `&"credits"` change, ignores every other profile key, and builds absent-safe when
##     the service is missing.
##
## The station is mounted once per suite, exactly as `ui/screens/station.tscn` ships it, so
## the panes sit in their real ancestor chain and the block is read from the real scene. The
## credits half mounts a fresh `ui/hud/hud.tscn` per test under the profile autoload, the
## `test_d6_status.gd` fixture-host idiom.

const StationScene := preload("res://ui/screens/station.tscn")
const Catalog := preload("res://game/station_catalog.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const HudScene := preload("res://ui/hud/hud.tscn")
const HudTheme := preload("res://ui/theme/vajb_theme.tres")

## The credits block's node path, from the HUD's own top-left column (CONTRACTS section
## 23.3: `CreditsBlock` appended below the fuel block, its `CreditsValue` the HudReadout).
const CREDITS_VALUE_PATH := ^"CanvasLayer/TopLeft/Blocks/CreditsBlock/CreditsValue"
## The autoload's own name, renamed for one test to prove the guarded lookup is absent-safe.
const PROFILE_SERVICE: StringName = &"PlayerProfile"

const PROFILE_PATH := "user://test_s11_inspector.cfg"

## The six item panes and the two item-less ones (CONTRACTS section 23.1: all eight declare
## the signal; only the six emit).
const EMITTERS: Array[int] = [0, 1, 2, 3, 4, 5]
const DECLARERS_ONLY: Array[int] = [6, 7]

const PACK: StringName = &"laser"
const SHIP: StringName = &"ship_vanguard"
const MODULE: StringName = &"w_cannon"
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
	return "s11_inspector"


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
	host.name = "InspectorHost"
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


## The fixture account every test starts from: the Vanguard owned and active, no stored fit,
## no module instances and no ammo - written through the private fields the sibling suites
## hand back, so the station opens on a deterministic shelf.
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


## ------------------------------------------------------------------ 1. the declaration


func test_every_pane_declares_the_signal() -> void:
	var panels: Array = _station.get(&"_panels")
	assert_eq(panels.size(), 8, "the shell loads one pane per module")
	for index in panels.size():
		var pane: CanvasItem = panels[index]
		assert_true(
			pane.has_signal(&"inspect_requested"),
			"pane %d (%s) must declare inspect_requested" % [index, pane.name]
		)
	for index: int in EMITTERS:
		assert_true(_pane(index).has_signal(&"inspect_requested"))
	for index: int in DECLARERS_ONLY:
		assert_true(_pane(index).has_signal(&"inspect_requested"))


func test_the_six_item_panes_are_the_emitters() -> void:
	## A panes' own source declares the signal; emission is checked on ARMORY below. The
	## two item-less panes are still the shell's own module list entries 6 and 7.
	assert_eq(EMITTERS.size(), 6)
	assert_eq(DECLARERS_ONLY.size(), 2)
	assert_eq(_pane(0).name, "Armory")
	assert_eq(_pane(6).name, "Repairs")
	assert_eq(_pane(7).name, "Launch")


## ------------------------------------------------------- 2. the hover signal and the clear


func test_armory_hover_emits_and_unhover_clears() -> void:
	var pane := _pane(0)
	var payload := _ammo_payload(pane, PACK)
	assert_true(not payload.is_empty(), "the armory must carry a %s card" % String(PACK))
	var row := payload[&"row"] as Button
	assert_true(row != null, "the card carries a row button")
	var seen: Array[Array] = []
	pane.connect(&"inspect_requested", _recorder(seen))
	row.mouse_entered.emit()
	assert_eq(seen.size(), 1, "a hover-in must emit once")
	if seen.size() == 1:
		var call: Array = seen[0]
		assert_ne(String(call[0]), "", "a hovered row carries a title")
		assert_eq(
			String(call[1]),
			Catalog.describe(PACK),
			"the body is the row's own catalogue description"
		)
		assert_eq(bool(call[2]), false, "a live catalogue row is not danger-coloured")
	row.mouse_exited.emit()
	assert_eq(seen.size(), 2, "a hover-out must emit once")
	if seen.size() == 2:
		var call: Array = seen[1]
		assert_eq(String(call[0]), "", "the hover-out clears the block (title == \"\")")
		assert_eq(String(call[1]), "", "the hover-out clears the body too")


func test_armory_selection_publishes_the_title() -> void:
	var pane := _pane(0)
	var payload := _ammo_payload(pane, PACK)
	var seen: Array[Array] = []
	pane.connect(&"inspect_requested", _recorder(seen))
	pane.call(&"_on_row_focused", payload[&"row"], payload)
	assert_eq(seen.size(), 1, "a selection writes the block")
	if seen.size() == 1:
		assert_ne(String(seen[0][0]), "")


## -------------------------------------------------------------- 3. describe and group_int


func test_describe_reads_a_row_that_carries_one() -> void:
	var ship := Catalog.ship(SHIP)
	assert_eq(Catalog.describe(SHIP), String(ship[&"description"]))
	var pack := Catalog.ammo_pack(PACK)
	assert_eq(Catalog.describe(PACK), String(pack[&"description"]))


func test_describe_is_empty_for_a_row_with_no_description() -> void:
	assert_eq(Catalog.describe(&""), "", "a blank id carries nothing")
	assert_eq(Catalog.describe(&"no_such_row"), "", "an unknown id carries nothing")
	assert_eq(Catalog.describe(&"mod_9999"), "", "an unresolvable instance carries nothing")


func test_describe_resolves_an_instance_through_its_base() -> void:
	var instance := StringName(_profile.call(&"add_instance", SHIP, &"common", [], []))
	assert_ne(instance, &"", "the profile must mint the instance")
	assert_ne(String(instance), String(SHIP), "a minted id is its own record key")
	assert_eq(
		Catalog.describe(instance),
		Catalog.describe(SHIP),
		"a mod_* instance resolves through its base"
	)


func test_describe_appends_the_rolled_affix_perks() -> void:
	var suffixes: Array = [SUFFIX]
	var instance := StringName(_profile.call(&"add_instance", MODULE, &"magic", [], suffixes))
	assert_ne(instance, &"", "the profile must mint the instance")
	var perk := String(ModuleCatalog.SUFFIXES[SUFFIX][&"perk"])
	var described := Catalog.describe(instance)
	assert_contains(described, perk, "the instance's rolled suffix perk is appended")


func test_group_int_is_the_station_rule() -> void:
	assert_eq(Catalog.group_int(0), "0")
	assert_eq(Catalog.group_int(999), "999")
	assert_eq(Catalog.group_int(1200), "1 200")
	assert_eq(Catalog.group_int(1000000), "1 000 000")
	assert_eq(Catalog.group_int(-1200), "-1 200")


func test_shell_format_int_delegates_to_group_int() -> void:
	for value: int in [0, 999, 1200, 1000000, -1200]:
		assert_eq(
			String(_station.call(&"_format_int", value)),
			Catalog.group_int(value),
			"the shell's readout is the catalogue's rule"
		)


## ------------------------------------------------------------------- 4. the block


func test_the_block_sits_above_the_status_strip() -> void:
	var page := _station.get_node_or_null(^"Layout/Page") as Control
	assert_true(page != null, "the page container ships")
	var inspector := page.get_node_or_null(^"Inspector") as Control
	var footer := page.get_node_or_null(^"Footer") as Control
	assert_true(inspector != null, "the Inspector block ships")
	assert_true(footer != null, "the status strip ships")
	assert_eq(
		inspector.get_index() + 1,
		footer.get_index(),
		"the Inspector sits immediately above the status strip"
	)


func test_the_block_carries_the_pinned_nodes() -> void:
	var title := _station.get_node_or_null(NodePath("%InspectorTitle")) as Label
	var body := _station.get_node_or_null(NodePath("%InspectorBody")) as Label
	assert_true(title != null, "InspectorTitle ships")
	assert_true(body != null, "InspectorBody ships")
	if title == null or body == null:
		return
	assert_eq(title.theme_type_variation, &"StationPanelTitle", "the title's own variation")
	assert_true(title.clip_text, "the title is one clipped line")
	assert_eq(body.theme_type_variation, &"SectionHeader", "the body's own variation")
	assert_eq(
		body.autowrap_mode,
		TextServer.AUTOWRAP_WORD_SMART,
		"the body wraps on words"
	)
	assert_eq(body.max_lines_visible, 2, "the two-line cap (INSPECTOR_BODY_MAX_LINES)")
	assert_eq(
		body.get_theme_color(&"font_color"),
		ThemeRes.get_color(&"text_primary", &"Tokens"),
		"the body carries the theme's text_primary override"
	)


func test_the_shell_writes_and_clears_the_block() -> void:
	var pane := _pane(0)
	var title := _station.get_node_or_null(NodePath("%InspectorTitle")) as Label
	var body := _station.get_node_or_null(NodePath("%InspectorBody")) as Label
	pane.inspect_requested.emit("LASER CELLS", "Standard laser capacitors.", false)
	assert_eq(title.text, "LASER CELLS", "the shell writes the title")
	assert_eq(body.text, "Standard laser capacitors.", "the shell writes the body")
	pane.inspect_requested.emit("", "", false)
	assert_eq(title.text, "", "an empty title clears the block")
	assert_eq(body.text, "", "an empty title clears the body too")


## -------------------------------------------------------- 5. the HUD credits block


func test_the_hud_credits_block_reads_the_profile() -> void:
	_profile.set(&"_credits", 4321)
	var hud := _mount_hud()
	var value := _credits_value(hud)
	assert_true(value != null, "the CreditsValue label ships in the top-left column")
	if value != null:
		assert_eq(value.text, Catalog.group_int(4321), "the block reads the profile's credits")
		assert_eq(value.theme_type_variation, &"HudReadout", "the value is a HudReadout")
	_unmount_hud(hud)


func test_the_hud_credits_block_carries_the_pinned_nodes() -> void:
	var hud := _mount_hud()
	var block := hud.get_node_or_null(^"CanvasLayer/TopLeft/Blocks/CreditsBlock")
	assert_true(block != null, "CreditsBlock ships in the top-left column")
	if block == null:
		_unmount_hud(hud)
		return
	var header := block.get_node_or_null(^"CreditsHeader") as HBoxContainer
	var icon := block.get_node_or_null(^"CreditsHeader/CreditsIcon") as TextureRect
	var title := block.get_node_or_null(^"CreditsHeader/CreditsTitle") as Label
	var spacer := block.get_node_or_null(^"CreditsHeader/CreditsSpacer") as Control
	assert_true(header != null, "CreditsHeader is an HBoxContainer")
	assert_true(icon != null and icon.texture != null, "the credits icon ships")
	if title != null:
		assert_eq(title.text, "CREDITS", "the title is the pinned string")
	else:
		assert_true(false, "CreditsTitle ships")
	assert_true(spacer != null, "the spacer ships")
	var fuel := hud.get_node_or_null(^"CanvasLayer/TopLeft/Blocks/FuelBlock") as Control
	assert_true(
		fuel != null and block.get_index() > fuel.get_index(),
		"the block sits below the fuel block"
	)
	_unmount_hud(hud)


func test_the_hud_credits_block_follows_a_credits_change() -> void:
	_profile.set(&"_credits", 1000)
	var hud := _mount_hud()
	var value := _credits_value(hud)
	assert_true(value != null, "the CreditsValue label ships")
	if value == null:
		_unmount_hud(hud)
		return
	assert_eq(value.text, Catalog.group_int(1000), "the block opens on the seeded credits")
	## The profile's own mutation emits `profile_changed(&"credits")`; the block follows it.
	_profile.call(&"add_credits", 2500)
	assert_eq(value.text, Catalog.group_int(3500), "the block follows a credits change")
	_unmount_hud(hud)


func test_the_hud_credits_block_ignores_other_profile_keys() -> void:
	_profile.set(&"_credits", 777)
	var hud := _mount_hud()
	var value := _credits_value(hud)
	assert_true(value != null, "the CreditsValue label ships")
	if value == null:
		_unmount_hud(hud)
		return
	var before := value.text
	_profile.emit_signal(&"profile_changed", &"cargo")
	assert_eq(value.text, before, "a non-credits key leaves the readout alone")
	_unmount_hud(hud)


func test_the_hud_credits_block_is_absent_safe_without_the_service() -> void:
	## The guarded lookup is proven by renaming the autoload for one mount: the block must
	## still build and leave the readout at zero rather than fail `_ready`.
	var original := String(_profile.name)
	_profile.name = "PlayerProfileAbsentS11"
	var hud := HudScene.instantiate() as Control
	hud.theme = HudTheme
	_profile.add_child(hud)
	var value := _credits_value(hud)
	assert_true(value != null, "the block still builds with no service to read")
	if value != null:
		assert_eq(value.text, Catalog.group_int(0), "no service leaves the readout at zero")
	_profile.name = original
	assert_eq(String(_profile.name), original, "the service name is restored")
	if is_instance_valid(hud):
		hud.free()


## ------------------------------------------------------------------- helpers


func _ammo_payload(pane: CanvasItem, pack_id: StringName) -> Dictionary:
	var payloads: Array = pane.get(&"_payloads")
	for payload: Variant in payloads:
		if (payload as Dictionary).get(&"id", &"") == pack_id:
			return payload
	return {}


## The HUD mounts under the profile autoload rather than the busy root viewport (the
## `test_d6_status.gd` fixture-host idiom); `_ready` resolves the service by name at the
## tree root either way.
func _mount_hud() -> Control:
	var hud := HudScene.instantiate() as Control
	hud.theme = HudTheme
	_profile.add_child(hud)
	return hud


func _unmount_hud(hud: Control) -> void:
	if hud != null and is_instance_valid(hud):
		hud.free()


func _credits_value(hud: Control) -> Label:
	return hud.get_node_or_null(CREDITS_VALUE_PATH) as Label


## A fresh recorder per test: a bound `Callable` compares equal across binds (two empty
## `seen` arrays), so `connect` would refuse the second one.
func _recorder(seen: Array[Array]) -> Callable:
	return func(title: String, body: String, danger: bool) -> void:
		seen.append([title, body, danger])
