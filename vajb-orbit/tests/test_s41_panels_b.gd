extends McpTestSuite
## Suite s41_panels_b: wave S41's composition pass on the services-side panels, the
## builder S41-B4 half. One row per finding, each load-bearing (the row fails if its
## fix is reverted), read off the shipped scenes and the shipped autoload.
##
## Contract: `.agents/gen/slices/D23-panel-audit/D23-R1_audit.md` section A6's rows
## F5, F10, F11, F13, F14 (the refinery half) and F15 (the shipyard half), plus the
## wave brief `.agents/gen/slices/S41-composition/S41_BRIEF.md` section 4's A1-A8.
##
##   F5  refinery_panel.gd   - one `IN INPUT` SectionHeader row before the first loaded row
##   F10 shipyard_panel.gd   - the preview box is a fixed fraction of `PreviewFrame`
##   F11 launch_panel.tscn   - the brief note leaves the foot region (the spacer that
##                             pushed it to the column's bottom is gone)
##   F13 contracts_panel.gd  - the active card is two stack rows (head + action row)
##   F14 refinery_panel.tscn - QUEUE / LOAD / COLLECT ALL in the pane foot cluster at 360x56
##   F15 shipyard_panel.tscn - the four mode plates at the chip row's 32 and C3 chrome
##
## The profile is the shipped autoload, borrowed the way `test_p2b_services.gd` borrows
## it: `save_path` is repointed at a scratch file before the first mutation and the
## borrowed fields are handed back in `suite_teardown`.

const RefineryScene := preload("res://ui/station/refinery_panel.tscn")
const LaunchScene := preload("res://ui/station/launch_panel.tscn")
const ContractsScene := preload("res://ui/station/contracts_panel.tscn")
const ShipyardScene := preload("res://ui/station/shipyard_panel.tscn")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const Registry := preload("res://game/contract_registry.gd")

const PROFILE_PATH := "user://test_s41_panels_b.cfg"
const HULL: StringName = &"ship_vanguard"
const STATION: StringName = &"s3_primary"

## UI_SPEC section 8 P1's action token (the cluster's primary and secondary alike).
const P1_SIZE := Vector2(360.0, 56.0)
const P1_VARIATION: StringName = &"StationButton"
## The chip row's height (auction_panel.gd `TAB_MIN_HEIGHT`) and its C3 chrome class.
const CHIP_HEIGHT := 32.0
const CHIP_CLASS := "C3"
## The chip row's ink size (auction_panel.gd `TAB_LABEL_VARIATION`, `StationValue` 18).
const CHIP_INK_SIZE := 18
## D23 F5's sub-header wording, verbatim.
const HEADER_INPUT := "IN INPUT"
## D23 F10's fraction of `PreviewFrame`, verbatim ("about 60 % of the box").
const PREVIEW_FRACTION := 0.60
## The retired S30 constant pin this wave replaces.
const PREVIEW_PIN := Vector2(240.0, 180.0)

var _profile: Node = null
var _host: Control = null
var _refinery: Control = null
var _launch: Control = null
var _contracts: Control = null
var _shipyard: Control = null
var _previous: Dictionary = {}


func suite_name() -> String:
	return "s41_panels_b"


func suite_setup(_ctx: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		skip_suite("a SceneTree is needed to mount the panes")
		return
	_profile = tree.root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		skip_suite("no PlayerProfile autoload to borrow")
		return
	_previous = {
		&"save_path": String(_profile.get(&"save_path")),
		&"credits": int(_profile.call(&"credits")),
		&"cargo": (_profile.get(&"_cargo") as Dictionary).duplicate(true),
		&"contracts": (_profile.call(&"contracts") as Array).duplicate(true),
		&"standing": (_profile.call(&"standing") as Dictionary).duplicate(true),
		&"docked_station": StringName(_profile.call(&"docked_station")),
		&"active_ship": StringName(_profile.call(&"active_ship")),
		&"owned_ships": (_profile.call(&"owned_ships") as Array).duplicate(true),
		&"refinery_input": (_profile.call(&"refinery_input") as Dictionary).duplicate(true),
		&"refinery_slots": int(_profile.call(&"refinery_slots")),
	}
	_profile.set(&"save_path", PROFILE_PATH)
	_delete_file(PROFILE_PATH)


func suite_teardown() -> void:
	_free_panes()
	if _profile == null:
		return
	for key: StringName in _previous:
		var value: Variant = _previous[key]
		match key:
			&"save_path":
				_profile.call(&"flush")
				_profile.set(&"save_path", String(value))
			&"credits":
				_profile.set(&"_credits", int(value))
			&"cargo":
				_profile.set(&"_cargo", value)
			&"contracts":
				_profile.call(&"set_contracts", value)
			&"standing":
				_profile.call(&"set_standing", value)
			&"docked_station":
				_profile.call(&"set_docked_station", value)
			&"active_ship":
				_profile.set(&"_active_ship", value)
			&"owned_ships":
				_profile.set(&"_owned_ships", value)
			&"refinery_input":
				_profile.call(&"set_refinery_input", value)
			&"refinery_slots":
				_profile.call(&"set_refinery_slots", int(value))
	_profile.call(&"flush")
	_profile.set(&"save_path", String(_previous[&"save_path"]))
	_delete_file(PROFILE_PATH)
	_previous = {}
	_profile = null


func setup() -> void:
	_free_panes()
	_wipe()
	_host = Control.new()
	_host.name = "S41Host"
	_host.theme = ThemeRes
	_host.size = _viewport_size()
	_fixture_host().add_child(_host)
	_refinery = _mount(RefineryScene)
	_launch = _mount(LaunchScene)
	_contracts = _mount(ContractsScene)
	_shipyard = _mount(ShipyardScene)


func teardown() -> void:
	_free_panes()


## A clean account: no contracts, no standing, no cargo, a full purse, the Vanguard
## active and owned, an empty refinery.
func _wipe() -> void:
	if _profile == null:
		return
	_profile.call(&"set_contracts", [])
	_profile.call(&"set_standing", {})
	_profile.call(&"set_docked_station", &"")
	_profile.set(&"_cargo", {})
	_profile.set(&"_credits", 50000)
	_profile.set(&"_active_ship", HULL)
	var owned: Array[StringName] = [HULL]
	_profile.set(&"_owned_ships", owned)
	_profile.call(&"set_refinery_input", {})
	_profile.call(&"set_refinery_jobs", [])
	_profile.call(&"set_refinery_output", {})
	_profile.call(&"set_refinery_slots", 2)


func _free_panes() -> void:
	if _host != null and is_instance_valid(_host):
		_host.free()
	_host = null
	_refinery = null
	_launch = null
	_contracts = null
	_shipyard = null


func _delete_file(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(absolute):
		DirAccess.remove_absolute(absolute)


## The runner calls every test from inside its own `_ready`, so the root viewport is
## still busy: the profile autoload entered the tree first and hosts the fixture.
func _fixture_host() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(NodePath(&"PlayerProfile"))


func _viewport_size() -> Vector2:
	return Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width", 1920)),
		float(ProjectSettings.get_setting("display/window/size/viewport_height", 1080))
	)


func _mount(scene: PackedScene) -> Control:
	var panel := scene.instantiate() as Control
	_host.add_child(panel)
	return panel


## ----------------------------------------------------------------------- F5


## D23 F5: the hold stacks and the input inventory share one `HoldRows` VBox, so the
## input rows get their own `IN INPUT` sub-header (the `LOADED` tag stays - colour is
## not the only channel). Reversal: the header is dropped and the two states read as
## one list.
func test_a1_f5_the_input_inventory_carries_its_own_sub_header() -> void:
	_profile.set(&"_cargo", {&"mineral_iron": 30})
	_profile.call(&"set_refinery_input", {&"mineral_copper": 12})
	_refinery.call(&"refresh_profile", &"cargo")
	var rows := _refinery.get_node_or_null(NodePath("%HoldRows")) as VBoxContainer
	assert_true(rows != null, "the LEFT block's hold list ships")
	if rows == null:
		return
	var header := rows.get_node_or_null(NodePath("SectionInInput")) as Control
	assert_true(header != null, "the input inventory carries its own sub-header row")
	var hold := rows.get_node_or_null(NodePath("HoldIron")) as Button
	var input := rows.get_node_or_null(NodePath("InputCopper")) as Button
	assert_true(hold != null and input != null, "both states draw a row")
	if header == null or hold == null or input == null:
		return
	var label := header.get_node_or_null(NodePath("SectionLabel")) as Label
	assert_true(label != null, "the sub-header is a SectionHeader label")
	if label != null:
		assert_eq(label.text, HEADER_INPUT, "the sub-header's wording")
		assert_eq(label.theme_type_variation, &"SectionHeader", "and its own variation")
	assert_gt(header.get_index(), hold.get_index(), "the header sits after the hold rows")
	assert_gt(input.get_index(), header.get_index(), "and before the first loaded row")
	var state := input.find_child("State", true, false) as Label
	assert_true(state != null, "the loaded row keeps its STATE cell")
	if state != null:
		assert_eq(state.text, "LOADED", "and the LOADED tag still marks it")


## ----------------------------------------------------------------------- F14


## D23 F14: the REFINERY's panel-level actions live in the pane's foot cluster at the
## UI_SPEC section 8 P1 token, primary rightmost, the way EXCHANGE's do. Reversal: the
## mid-column `ActionGrid` (the shipped scattered cluster).
func test_a1_f14_the_action_cluster_sits_in_the_pane_foot_band() -> void:
	var foot := _refinery.get_node_or_null(NodePath("PaneFoot")) as Control
	assert_true(foot != null, "the pane carries its own foot band")
	if foot == null:
		return
	var row := foot.get_node_or_null(NodePath("ActionsRow")) as HBoxContainer
	assert_true(row != null, "the cluster is an HBox in the foot band")
	if row == null:
		return
	var queue := _refinery.get_node_or_null(NodePath("%QueueButton")) as Button
	var load := _refinery.get_node_or_null(NodePath("%LoadButton")) as Button
	var collect := _refinery.get_node_or_null(NodePath("%CollectButton")) as Button
	assert_true(queue != null and load != null and collect != null, "the three actions ship")
	if queue == null or load == null or collect == null:
		return
	for button: Button in [load, collect, queue]:
		assert_eq(button.get_parent(), row, "%s sits in the foot cluster" % button.name)
		assert_eq(button.custom_minimum_size, P1_SIZE, "%s wears the P1 360x56 token" % button.name)
		assert_eq(button.theme_type_variation, P1_VARIATION, "%s wears the P1 plate" % button.name)
	assert_eq(queue.get_index(), row.get_child_count() - 1, "the commit is rightmost in the row")


## ----------------------------------------------------------------------- F11


## D23 F11: the brief note is the briefing column's last row and nothing pushes it down
## into the foot region; the foot band carries the footer, the live confirm line and the
## cluster. Reversal: the `BriefSpacer` returns and the note reads as a third foot line.
func test_a1_f11_the_brief_note_leaves_the_foot_region() -> void:
	var note := _launch.get_node_or_null(NodePath("%BriefNote")) as Label
	var strip := _launch.get_node_or_null(NodePath("%ConfirmStrip")) as Label
	var foot := _launch.get_node_or_null(NodePath("PaneFoot")) as Control
	assert_true(note != null and strip != null and foot != null, "the pane's captions ship")
	if note == null or strip == null or foot == null:
		return
	var brief := note.get_parent()
	assert_eq(brief.name, "BriefBox", "the note rides the briefing column")
	assert_eq(note.get_index(), brief.get_child_count() - 1, "and it is that column's last row")
	assert_true(
		brief.get_node_or_null(NodePath("BriefSpacer")) == null,
		"no expanding spacer pushes it to the column's bottom"
	)
	var cargo := _launch.get_node_or_null(NodePath("%CargoList")) as Control
	assert_true(cargo != null, "the cargo manifest ships")
	if cargo != null:
		assert_eq(note.get_index(), cargo.get_index() + 1, "the note follows the cargo it comments on")
	assert_eq(strip.get_parent(), foot, "the live confirm line keeps the foot band")
	assert_false(note.get_parent() == foot, "the note is not foot-band text")


## ----------------------------------------------------------------------- F13


## D23 F13: the active card is two stack rows - the head, then one action row carrying
## the escrow summary with the CANCEL chip right-aligned beside it. Reversal: the chip
## and the escrow lines stack under the head in one `ROW_HEIGHT` card.
func test_a1_f13_the_active_card_is_two_stack_rows() -> void:
	_profile.call(&"set_docked_station", STATION)
	_contracts.call(&"refresh_profile", &"contracts")
	var board: Array = _contracts.get(&"_board")
	var target := {}
	for entry: Variant in board:
		var row: Dictionary = entry
		var type := StringName(row.get(&"type", &""))
		if type == Registry.TYPE_ESCORT or type == Registry.TYPE_EXPEDITION:
			continue
		if StringName(row.get(&"item_id", &"")) == &"" or int(row.get(&"quantity", 0)) <= 0:
			continue
		target = row
		break
	assert_false(target.is_empty(), "the board offers an escrowing row to accept")
	if target.is_empty():
		return
	_profile.call(&"add_cargo", StringName(target[&"item_id"]), int(target[&"quantity"]))
	var accepted: Dictionary = _contracts.call(&"accept", StringName(target[&"id"]))
	assert_true(bool(accepted.get(&"ok", false)), "the row accepts and escrows")
	var list := _contracts.get_node_or_null(NodePath("%ActiveList")) as VBoxContainer
	assert_true(list != null and list.get_child_count() == 1, "one active card is drawn")
	if list == null or list.get_child_count() != 1:
		return
	var card := list.get_child(0) as PanelContainer
	var stack := card.get_node_or_null(NodePath("CardInner/CardBox")) as VBoxContainer
	assert_true(stack != null, "the card carries its stack")
	if stack == null:
		return
	assert_eq(stack.get_child_count(), 2, "the card is exactly two stack rows")
	if stack.get_child_count() != 2:
		return
	assert_eq(stack.get_child(0).name, "CardHead", "row 1 is the head")
	var action_row := stack.get_child(1) as HBoxContainer
	assert_true(action_row != null, "row 2 is a container")
	if action_row == null:
		return
	assert_eq(action_row.name, "CardActionRow", "row 2 is the action row")
	var cancel := card.find_child("CancelButton", true, false) as Button
	assert_true(cancel != null, "the CANCEL chip ships on the card")
	if cancel != null:
		assert_eq(cancel.get_parent(), action_row, "and it shares the action row")
	var escrow := action_row.get_node_or_null(NodePath("CardEscrow")) as VBoxContainer
	assert_true(escrow != null, "the escrow summary is the action row's own column")
	if escrow != null:
		assert_gt(escrow.get_child_count(), 0, "the accepted row's escrow prints there")
		assert_true(
			bool(escrow.size_flags_horizontal & Control.SIZE_EXPAND),
			"and it is what pushes the chip to the right edge"
		)


## ----------------------------------------------------------------------- F10


## D23 F10: the preview's pinned box is a fixed fraction of `PreviewFrame`, so the hull
## owns the frame instead of a 240x180 island in it. Reversal: the constant 240x180 pin.
##
## The row reads the sizes; it never writes `PreviewFrame.size`. A host that does not lay
## the pane out (this fixture) leaves the frame min-driven, and a min-driven frame whose
## child's box is a fraction of it re-grows on every write - a shape the shipped shell
## cannot reach (`station.tscn:191` `ModuleHost` is v/h 3, so the pane is slack-driven).
func test_a1_f10_the_preview_box_is_a_fraction_of_the_frame() -> void:
	var frame := _shipyard.get(&"_preview_frame") as PanelContainer
	var image := _shipyard.get(&"_preview_image") as TextureRect
	assert_true(frame != null and image != null, "the preview frame and its image ship")
	if frame == null or image == null:
		return
	assert_eq(
		image.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "the hull keeps its aspect"
	)
	assert_gt(frame.size.x, 0.0, "the frame is laid out")
	if frame.size.x <= 0.0:
		return
	var want := frame.size * PREVIEW_FRACTION
	assert_true(
		image.custom_minimum_size.is_equal_approx(want),
		"the box is %.2f of the frame (%s vs %s)"
		% [PREVIEW_FRACTION, str(image.custom_minimum_size), str(want)]
	)
	assert_false(
		image.custom_minimum_size.is_equal_approx(PREVIEW_PIN),
		"not the retired 240x180 constant pin"
	)


## ----------------------------------------------------------------------- F15


## D23 F15: the shipyard's four mode plates wear the chip row's 32 height and its C3
## chrome, and keep their own four labels (mode is not filter or service). Reversal: the
## shipped 200x44 `StationButton` plates.
func test_a1_f15_the_shipyard_plates_wear_the_chip_family() -> void:
	var plates := {
		"ModeHangar": "HANGAR",
		"ModeBuild": "BUILD",
		"ModeQueue": "QUEUE",
		"ModeScrap": "SCRAP",
	}
	for node_name: String in plates.keys():
		var plate := _shipyard.get_node_or_null(NodePath("%" + node_name)) as Button
		assert_true(plate != null, "%s ships" % node_name)
		if plate == null:
			continue
		assert_eq(plate.custom_minimum_size.y, CHIP_HEIGHT, "%s wears the chip row's height" % node_name)
		assert_eq(String(plate.get_meta(&"chrome_class", "")), CHIP_CLASS, "%s wears the C3 chip" % node_name)
		assert_eq(plate.get_theme_font_size(&"font_size"), CHIP_INK_SIZE, "%s wears the chip ink" % node_name)
		assert_eq(plate.text, String(plates[node_name]), "%s keeps its own count" % node_name)
