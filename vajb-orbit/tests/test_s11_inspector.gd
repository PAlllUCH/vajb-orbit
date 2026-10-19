@tool
extends McpTestSuite
const Support := preload("res://tests/support.gd")
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
const CREDITS_VALUE_PATH := ^"CanvasLayer/TopLeft/Blocks/CreditsPlate/CreditsBlock/CreditsValue"
## The autoload's own name, renamed for one test to prove the guarded lookup is absent-safe.
const PROFILE_SERVICE: StringName = &"PlayerProfile"

const PROFILE_PATH := "user://test_s11_inspector.cfg"

## The merged rail's six panes (P7 folded FITTING into ARMORY and REPAIRS into SHIPYARD):
## all six declare the signal and all six emit - every one on a real hover, and a leave
## publishes the chain's clear (P6's idle fill retired with the inspector band, S30-F1/F5).
const EMITTERS: Array[int] = [0, 1, 2, 3, 4, 5]
const DECLARERS_ONLY: Array[int] = []

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
	Support.delete_file(PROFILE_PATH)
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
	Support.delete_file(PROFILE_PATH)
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

func _pane(index: int) -> CanvasItem:
	var panels: Array = _station.call(&"panes")
	if index < 0 or index >= panels.size():
		return null
	return panels[index]


## ------------------------------------------------------------------ 1. the declaration


func test_every_pane_declares_the_signal() -> void:
	var panels: Array = _station.call(&"panes")
	assert_eq(panels.size(), 6, "the shell loads one pane per module (P7's six)")
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
	## S29 (P4/P5/P7): the rail carries six panes and every one of them publishes - each on
	## a real hover (P6's idle summaries retired, S30-F1/F5).
	assert_eq(EMITTERS.size(), 6)
	assert_eq(DECLARERS_ONLY.size(), 0)
	assert_eq(_pane(0).name, "Armory")
	assert_eq(_pane(4).name, "Shipyard")
	assert_eq(_pane(5).name, "Launch")


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


## **S30 (STATION_HUB section 18's supersession ledger, P6 retired).** The inspector band is
## removed with the shell-v2 re-lay: the hover sink is the N27 tooltip (section 12.2), so the
## retired band's nodes are gone and the footer status strip is the last band.
func test_the_inspector_band_is_retired() -> void:
	var page := _station.get_node_or_null(^"Layout/Page") as Control
	assert_true(page != null, "the page container ships")
	assert_true(
		page.get_node_or_null(^"Inspector") == null, "the inspector band is removed (S30)"
	)
	assert_true(
		_station.get_node_or_null(NodePath("%InspectorTitle")) == null,
		"and its title label with it"
	)
	var footer := page.get_node_or_null(^"Footer") as Control
	assert_true(footer != null, "the status strip ships")
	assert_eq(footer.get_index(), page.get_child_count() - 1, "the footer is the last band")


## **S30 (UI_SPEC section 12.2, N27).** The shell's sink is the hover tooltip: a pane's
## `inspect_requested` payload starts the 0.25 s delay (N33 restarts it per target) and the
## tooltip opens at the cursor once it elapses; an empty emit clears both.
func test_the_shell_shows_the_hover_tooltip_and_clears_it() -> void:
	_station.call(&"_select_module", 0, true)
	var pane := _pane(0)
	var tooltip := _tooltip()
	assert_true(tooltip != null, "the shell builds the N27 tooltip")
	pane.inspect_requested.emit("LASER CELLS", "Standard laser capacitors.", false)
	assert_eq(String(_station.get(&"_hover_title")), "LASER CELLS", "the shell stores the title")
	assert_true(_hover_timer().time_left > 0.0, "the 0.25 s delay is running (N33)")
	_station.call(&"_show_hover_tooltip")
	assert_true(bool(tooltip.call(&"is_open")), "the tooltip opens once the delay elapses")
	assert_eq(String(tooltip.call(&"content_title")), "LASER CELLS", "with the row's title")
	assert_contains(String(tooltip.call(&"rendered_text")), "INSPECT", "and N33's hint line")
	## N46 (supersedes S30's immediate clear): an empty emit is the pointer leaving, so the
	## popup lingers 0.5 s (2x the 0.25 s appear delay) before it drops; the payload is held
	## until the linger elapses.
	pane.inspect_requested.emit("", "", false)
	assert_true(bool(tooltip.call(&"is_open")), "an empty emit lingers, never clears at once (N46)")
	var linger := _station.get(&"_linger_timer") as Timer
	assert_true(linger != null and linger.time_left > 0.0, "the 0.5 s linger runs (N46)")
	assert_eq(linger.wait_time, 0.5, "the linger is 2x the appear delay (N46)")
	_station.call(&"_on_linger_timeout")
	assert_false(bool(tooltip.call(&"is_open")), "the linger's timeout drops the popup")
	assert_eq(String(_station.get(&"_hover_title")), "", "and clears the payload")


## N46 (UI_SPEC section 13.1): the popup holds steady while the pointer crosses a row's
## children - a same-target payload cancels the linger and never re-arms the appear delay;
## only a different target restarts it.
func test_n46_the_popup_holds_steady_across_one_row() -> void:
	_station.call(&"_select_module", 0, true)
	var pane := _pane(0)
	var tooltip := _tooltip()
	pane.inspect_requested.emit("LASER CELLS", "Standard laser capacitors.", false)
	_station.call(&"_show_hover_tooltip")
	_hover_timer().stop()
	assert_true(bool(tooltip.call(&"is_open")), "the popup is up")
	pane.inspect_requested.emit("", "", false)
	pane.inspect_requested.emit("LASER CELLS", "Standard laser capacitors.", false)
	assert_true(bool(tooltip.call(&"is_open")), "the popup stays up across child churn (N46)")
	assert_true(_hover_timer().time_left <= 0.0, "and the appear delay is not re-armed (N46)")
	pane.inspect_requested.emit("IRON ORE", "Raw iron.", false)
	assert_true(_hover_timer().time_left > 0.0, "a new target re-arms the appear delay (N46)")
	assert_false(bool(tooltip.call(&"is_open")), "and drops the stale popup (N33)")
	_station.call(&"_clear_inspector")


## N47 (UI_SPEC section 13.1): the tooltip body renders `text_primary` (not bold), the
## RichTextLabel font is 15 px scoped to the tooltip node (never the theme's 13 px default),
## the INSPECT hint stays `text_dim`, and the cap widens to 360.
func test_n47_the_tooltip_body_and_its_own_font() -> void:
	var tooltip := _tooltip()
	tooltip.call(
		&"show_for", "LASER CELLS", "Standard laser capacitors.", false,
		Vector2.ZERO, Vector2(1920.0, 1080.0)
	)
	var text := String(tooltip.call(&"rendered_text"))
	var primary := (tooltip.call(&"_token", &"text_primary") as Color).to_html(false)
	var dim := (tooltip.call(&"_token", &"text_dim") as Color).to_html(false)
	assert_true(
		text.contains("[color=#%s]Standard laser capacitors.[/color]" % primary),
		"the body renders text_primary, not bold (N47)"
	)
	assert_true(text.contains("[color=#%s]INSPECT[/color]" % dim), "the hint stays text_dim (N47)")
	var label := tooltip.get_node("%TooltipLabel") as RichTextLabel
	assert_eq(label.get_theme_font_size(&"normal_font_size"), 15, "the body font is 15 px (N47)")
	assert_eq(label.custom_minimum_size.x, 360.0, "the cap widens to 360 (N47)")
	tooltip.call(&"hide_tooltip")


## **S30 (UI_SPEC section 12.2).** The stale-hover defect (S28's A1): the switch takes the
## tooltip down and drops the payload, so the previous module's hover never rides in.
func test_the_tooltip_clears_on_module_switch() -> void:
	var pane := _pane(0)
	var tooltip := _tooltip()
	pane.inspect_requested.emit("VANGUARD", "General purpose hull.", false)
	_station.call(&"_show_hover_tooltip")
	assert_true(bool(tooltip.call(&"is_open")), "the active pane fills the tooltip")
	_station.call(&"_select_module", 1)
	assert_false(bool(tooltip.call(&"is_open")), "the switch takes it down")
	assert_eq(String(_station.get(&"_hover_title")), "", "and drops the payload")
	_station.call(&"_select_module", 0, true)


func test_an_inactive_pane_never_fills_the_tooltip() -> void:
	var outgoing := _pane(0)
	var incoming := _pane(1)
	_station.call(&"_select_module", 1)
	outgoing.inspect_requested.emit("LASER CELLS", "Standard laser capacitors.", false)
	assert_eq(
		String(_station.get(&"_hover_title")), "",
		"a hidden module's hover cannot ride into the next one"
	)
	incoming.inspect_requested.emit("IRON ORE", "Raw iron.", false)
	assert_eq(String(_station.get(&"_hover_title")), "IRON ORE", "the pane on the host publishes")
	_station.call(&"_select_module", 0, true)


## **S30 (UI_SPEC section 12.3, N28/N35/N36).** The shell's explicit sink: a pane's
## `sheet_requested` payload opens the INSPECT sheet, and its rows are the pinned ones.
func test_the_sheet_opens_from_a_pane_payload() -> void:
	_station.call(&"_select_module", 0, true)
	var pane := _pane(0)
	var sheet := _sheet()
	assert_true(sheet != null, "the shell builds the N28 sheet")
	assert_true(pane.has_signal(&"sheet_requested"), "every pane declares the sheet signal")
	pane.sheet_requested.emit({
		&"name": "Thruster Mk II",
		&"affixes": ["+12 % thrust · SCAVENGED"],
		&"stats": "PWR 2 · DRAW 3",
		&"family": "ENGINES",
		&"owned": 2,
	})
	assert_true(bool(sheet.call(&"is_open")), "the sheet opens on the pane's payload")
	var rows: PackedStringArray = sheet.call(&"row_texts")
	assert_eq(rows[0], "Thruster Mk II", "row 1 carries the name")
	assert_eq(rows[1], "+12 % thrust · SCAVENGED", "row 2 carries the affix lines")
	assert_eq(rows[2], "PWR 2 · DRAW 3", "row 3 carries the stat block")
	assert_eq(rows[3], "SLOT FAMILY · ENGINES", "row 4 carries the family (N35)")
	assert_eq(rows[4], "OWNED ×2", "row 5 carries the held count (N35)")
	assert_eq(rows[5], "ESC · CLOSE", "row 6 is N36's close hint")
	## Leave the sheet closed so the suite's one mounted shell does not leak it forward.
	_station.call(&"_handle_cancel")


## **S30 (UI_SPEC section 12.6, N28/P19).** ESC is the sheet's own close step in the
## station's topmost-first unwind (P19), one operation.
func test_the_sheet_closes_on_the_cancel_route() -> void:
	var pane := _pane(0)
	var sheet := _sheet()
	pane.sheet_requested.emit({&"name": "Laser Cells"})
	assert_true(bool(sheet.call(&"is_open")), "the sheet is up")
	_station.call(&"_handle_cancel")
	assert_false(bool(sheet.call(&"is_open")), "the cancel route closes it in one operation")


## **S30 (UI_SPEC section 12.3, section 5.2's queue).** A second open while one is up
## queues behind the first rather than stacking.
func test_the_sheet_queues_a_second_open() -> void:
	var pane := _pane(0)
	var sheet := _sheet()
	_station.call(&"_handle_cancel")
	assert_false(bool(sheet.call(&"is_open")), "the sheet starts closed")
	pane.sheet_requested.emit({&"name": "First"})
	assert_eq(int(sheet.call(&"pending_count")), 0, "nothing waits behind the first")
	pane.sheet_requested.emit({&"name": "Second"})
	assert_true(bool(sheet.call(&"is_open")), "the first stays up")
	assert_eq(int(sheet.call(&"pending_count")), 1, "the second queues (one at a time)")
	_station.call(&"_handle_cancel")


## **S30 (UI_SPEC section 12.6, N34).** `station_inspect` on the focused row opens the
## sheet for that row's payload.
func test_station_inspect_opens_the_sheet_on_the_focused_row() -> void:
	_station.call(&"_select_module", 0, true)
	var pane := _pane(0)
	var payload := _ammo_payload(pane, PACK)
	assert_true(not payload.is_empty(), "the armory carries a %s card" % String(PACK))
	pane.call(&"_on_row_focused", payload[&"row"], payload)
	_station.call(&"_inspect_focused")
	assert_true(bool(_sheet().call(&"is_open")), "E on the focused row opens the sheet")
	_station.call(&"_handle_cancel")


## **S37 (owner 2026-10-07, N37 rev).** The header's one INSPECT toggle: on, an item press
## opens the sheet instead of its normal action, and no per-row chip ships.
func test_the_inspect_toggle_routes_an_item_press_to_the_sheet() -> void:
	_station.call(&"_select_module", 0, true)
	var pane := _pane(0)
	var button := _station.get_node_or_null(NodePath("%InspectButton")) as Button
	assert_true(button != null, "the header carries the one INSPECT toggle")
	if button == null:
		return
	assert_true(button.toggle_mode, "and it is a toggle")
	var payload := _ammo_payload(pane, PACK)
	assert_true(not payload.is_empty(), "the armory carries a %s card" % String(PACK))
	var row := payload[&"row"] as Button
	assert_true(
		row.get_node_or_null(NodePath("RowInner/RowBox/InspectChip")) == null,
		"the row carries no per-row INSPECT chip"
	)
	## On: the press opens the sheet.
	button.button_pressed = true
	assert_true(bool(pane.get(&"_inspect_mode")), "the pane takes the inspect mode")
	pane.call(&"_on_row_pressed", payload)
	assert_true(bool(_sheet().call(&"is_open")), "an item press opens the sheet in inspect mode")
	_station.call(&"_handle_cancel")
	## Off: the pane drops the mode.
	button.button_pressed = false
	assert_false(bool(pane.get(&"_inspect_mode")), "the pane drops the mode")


## **S30 (A5.5, UI_SPEC section 12.5).** The reviewer's probe: a pane's own geometry is
## byte-identical before, during and after a hover - the state change mutates colour,
## `modulate` and `_draw` only.
func test_a_hover_never_moves_a_pane() -> void:
	_station.call(&"_select_module", 0, true)
	var pane := _pane(0)
	var payload := _ammo_payload(pane, PACK)
	var row := payload[&"row"] as Button
	var before := _geometry(pane)
	row.mouse_entered.emit()
	assert_eq(_geometry(pane), before, "the hover moved nothing (A5.5)")
	row.mouse_exited.emit()
	assert_eq(_geometry(pane), before, "and the unhover moved nothing (A5.5)")


## One pane's geometry: its own rect plus every descendant's, so a single moved cell fails
## the probe.
func _geometry(root: Node) -> Array:
	var out: Array = []
	_collect_geometry(root, out)
	return out


func _collect_geometry(node: Node, out: Array) -> void:
	if node is Control:
		var control := node as Control
		out.append([control.name, control.position, control.size, control.custom_minimum_size])
	for child: Node in node.get_children():
		_collect_geometry(child, out)


## The popup layer's own nodes (S30, UI_SPEC section 12.2/12.3), read off the shell.
func _tooltip() -> Control:
	return _station.get(&"_tooltip") as Control


func _hover_timer() -> Timer:
	return _station.get(&"_hover_timer") as Timer


func _sheet() -> Control:
	return _station.get(&"_sheet") as Control


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
	var block := hud.get_node_or_null(^"CanvasLayer/TopLeft/Blocks/CreditsPlate/CreditsBlock")
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
	var plate := block.get_parent() as Control
	assert_true(
		fuel != null and plate != null and plate.get_index() > fuel.get_index(),
		"the block sits below the fuel block (V1's plate carries it)"
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
	## P39a: the pack cards live in the shared menu's AMMUNITION category.
	if pane.has_method(&"select_tab"):
		pane.call(&"select_tab", &"ammo")
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
