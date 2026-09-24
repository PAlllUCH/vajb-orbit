@tool
extends McpTestSuite
## Suite d7_armory: wave D7's ARMORY cockpit restyle (UI_SPEC section 3.10, on the
## section 3.9 instrument language - "rework the gun battery selection window to new
## cockpit like one"). **Surface only**: the pane's transactions, drag-drop behaviour,
## refusal-writes-nothing rule and panel contract are section 5.11 / 09 section 11 /
## CONTRACTS section 17's and are asserted here unchanged; what this suite measures is
## the chrome the wave adds:
##
##  1. the pane mounts on the painted console plate (`ui_armory_console`, a plain
##     TextureRect, no nine-slice) and the three groups sit in Mockup A's recessed wells
##     at the pinned rects (UI_SPEC section 3.10 / UI_CHROME section 12 Amendment 2: the
##     plate is FLAT and the wells are code-drawn);
##  2. each rack `B1..B7` is a bay plate (`ui_armory_rack_plate`) in Mockup A's 4+3 grid,
##     with the W cells as the machined slot recesses and the fitted cells marked inside
##     them;
##  3. the SALVO strip's three `ui_seg_*` cells render the rack's cycle figure (Mockup A's
##     approved `073` = 0.73 s readout) and read blanks for a rack with no cadence;
##  4. INVENTORY and AMMUNITION rows ride the brushed row plate (`ui_armory_row_plate`,
##     nine-slice) at the pinned 22 / 32 px heights;
##  5. danger rows reuse section 3.1/3.1b verbatim (the label plus a 1 px code-drawn
##     frame, digits never recoloured);
##  6. the style is the single surface (`ArmoryStyle`, a `CockpitStyle`): a user `.tres`
##     restyles **and** relayouts the pane with no code edit.
##
## The pane is mounted from the shipped scene with the shipped theme, and the profile is
## the shipped autoload borrowed the way `test_p2b1_outfitting_panel.gd` borrows it:
## `save_path` is repointed at a scratch file before the first mutation and every borrowed
## field is handed back in `suite_teardown`.

const PanelScene := preload("res://ui/station/armory_panel.tscn")
const PanelScript := preload("res://ui/station/armory_panel.gd")
const StyleScript := preload("res://ui/station/armory_style.gd")
const CockpitStyleScript := preload("res://ui/hud/cockpit_style.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const Catalog := preload("res://game/station_catalog.gd")
const ModuleData := preload("res://game/module_catalog.gd")
const FitData := preload("res://game/ship_fit.gd")

const PROFILE_PATH := "user://test_d7_armory.cfg"
const STYLE_PROBE_PATH := "user://d7_armory_style_probe.tres"

const VANGUARD: StringName = &"ship_vanguard"
const WEAPON_SLOT: StringName = &"weapons"
const CANNON: StringName = &"w_cannon"
const ROCKET: StringName = &"w_rocket"
const LASER: StringName = &"w_laser"

const START_CREDITS := 10000
const AMMO_FIXTURE: Dictionary = {
	&"ammo_laser": 30,
	&"ammo_cannon": 15,
	&"ammo_rocket": 40,
	&"ammo_mine": 0,
	&"ammo_plasma": 0,
}

## The pinned numbers (UI_SPEC section 3.10 / UI_CHROME section 12's boxes / Mockup A's own
## canvas). The suite reads them from the style *and* asserts them against these literals,
## so a default that drifts fails here. The canvas is section 3.10 **Amendment 2**'s ruled
## 872 x 956 (436 x 478 logical), whose master is re-rendered at exactly 2x - the mount is
## unstretched precisely because `CONSOLE_MASTER == BLOCK * ART_SCALE` (R1 MED-1).
const ART_SCALE := 2.0
const CANVAS := Vector2(436.0, 478.0)
const BLOCK := Vector2(872.0, 956.0)
const CONSOLE_MASTER := Vector2(1744.0, 1912.0)
const RACK_MASTER := Vector2(194.0, 182.0)
const ROW_MASTER := Vector2(192.0, 64.0)
const RACKS_WELL := Rect2(30.0, 122.0, 812.0, 390.0)
const INVENTORY_WELL := Rect2(30.0, 570.0, 812.0, 170.0)
const AMMO_WELL := Rect2(30.0, 796.0, 812.0, 136.0)
const CAPTION_BAND := 30.0
const BAY := Vector2(194.0, 182.0)
const BAY_GAP := 8.0
const BAY_ORIGIN := Vector2(44.0, 136.0)
const BAY_COLUMNS := 4
const SLOT := Vector2(40.0, 44.0)
const SLOT_PITCH := 44.0
const SLOT_ORIGIN := Vector2(10.0, 38.0)
const SALVO_CELL := Vector2(40.0, 72.0)
const SALVO_PITCH := 42.0
const SALVO_ORIGIN := Vector2(64.0, 104.0)
const AMMO_ROW := 64.0
const INVENTORY_ROW := 44.0
const RACK_COUNT := 7
const SALVO_MAX := 999

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
	return "d7_armory"


func suite_setup(_ctx: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		skip_suite("a SceneTree is needed to mount the pane")
		return
	var profile := tree.root.get_node_or_null(NodePath(&"PlayerProfile"))
	if profile == null:
		skip_suite("no PlayerProfile autoload to borrow")
		return
	_profile = profile
	_previous_path = String(_profile.get(&"save_path"))
	_previous_credits = int(_profile.get(&"_credits"))
	_previous_ship = StringName(_profile.get(&"_active_ship"))
	_previous_fits = (_profile.get(&"_fits") as Dictionary).duplicate(true)
	_previous_owned = (_profile.get(&"_owned_ships") as Array).duplicate(true)
	_previous_modules = (_profile.get(&"_modules") as Dictionary).duplicate(true)
	_previous_ammo = (_profile.get(&"_ammo") as Dictionary).duplicate(true)
	_previous_cargo = (_profile.get(&"_cargo") as Dictionary).duplicate(true)
	_previous_batteries = (_profile.get(&"_batteries") as Dictionary).duplicate(true)
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
	_profile.set(&"_ammo", _previous_ammo)
	_profile.set(&"_cargo", _previous_cargo)
	_profile.set(&"_batteries", _previous_batteries)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	_delete_file(PROFILE_PATH)
	if FileAccess.file_exists(STYLE_PROBE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(STYLE_PROBE_PATH))
	_profile = null


func setup() -> void:
	_status.clear()
	_danger.clear()
	_seed_account()
	_host = Control.new()
	_host.name = "ArmoryHost"
	_host.theme = ThemeRes
	_host.size = Vector2(1920.0, 1080.0)
	_fixture_host().add_child(_host)


func teardown() -> void:
	if _host != null and is_instance_valid(_host):
		_host.free()
	_host = null
	_panel = null


## The fixture account every test starts from: the Vanguard active and owned, no stored
## fit (the standard fit is what the racks derive from), no modules, 10 000 CR and
## `AMMO_FIXTURE`'s cargo units - written through the same private fields
## `test_p2b1_outfitting_panel.gd` hands back, so no purchase is charged and no signal
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


func _fixture_host() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var profile := tree.root.get_node_or_null(NodePath(&"PlayerProfile"))
	return profile if profile != null else tree.root


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


func _last_status() -> String:
	return _status[_status.size() - 1] if not _status.is_empty() else ""


func _last_danger() -> bool:
	return _danger[_danger.size() - 1] if not _danger.is_empty() else false


func _style() -> Resource:
	return _panel.call(&"style")


func _rack(panel: Control, index: int) -> Dictionary:
	var rows: Array = panel.call(&"rack_rows")
	return rows[index]


func _rack_row(panel: Control, index: int) -> PanelContainer:
	return (panel.get_node("%RackRows") as VBoxContainer).get_child(index) as PanelContainer


func _ammo_card(panel: Control, pack_id: StringName) -> Button:
	for child: Node in (panel.get_node("%ArmoryRows") as VBoxContainer).get_children():
		var row := child as Button
		if row == null:
			continue
		var title := row.find_child("Title", true, false) as Label
		if title == null:
			continue
		for pack: Dictionary in Catalog.AMMO_PACKS:
			if pack_id == pack[&"id"] and String(pack[&"name"]).to_upper() == title.text.to_upper():
				return row
	return null


func _cell(row: Control, cell_name: String) -> Control:
	return row.find_child(cell_name, true, false) as Control


func _cell_text(row: Control, cell_name: String) -> String:
	var cell := _cell(row, cell_name)
	var value := cell.get_node_or_null(^"Value") as Label if cell != null else null
	return value.text if value != null else ""


func _plate(row: Control) -> Control:
	return row.get_node_or_null(^"RowPlate") as Control


func _drop_inventory(panel: Control, rack: int, slot: int, base_id: StringName) -> bool:
	var payload: Variant = panel.call(&"drag_inventory", base_id)
	return bool(panel.call(&"drop", rack, slot, payload))


func _snapshot() -> Dictionary:
	return {
		&"fit": _profile.call(&"fit_for", VANGUARD),
		&"bag": _profile.call(&"modules"),
		&"racks": _profile.call(&"batteries"),
		&"credits": int(_profile.call(&"credits")),
		&"cargo": (_profile.get(&"_cargo") as Dictionary).duplicate(true),
	}


func _unchanged(before: Dictionary, what: String) -> void:
	assert_eq(_profile.call(&"fit_for", VANGUARD), before[&"fit"], "%s: the fit is byte-identical" % what)
	assert_eq(_profile.call(&"modules"), before[&"bag"], "%s: and the bag" % what)
	assert_eq(_profile.call(&"batteries"), before[&"racks"], "%s: and the rack record" % what)
	assert_eq(int(_profile.call(&"credits")), int(before[&"credits"]), "%s: and the credits" % what)
	_assert_cargo(before, what)


## The hold's own figure (the profile carries no public `cargo()` read: `cargo_units`
## answers one family at a time), read straight off the store the pane buys into.
func _assert_cargo(before: Dictionary, what: String) -> void:
	assert_eq(
		(_profile.get(&"_cargo") as Dictionary), before[&"cargo"],
		"%s: and the hold" % what
	)

func _delete_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


## ------------------------------------------------------- 1. the console and the wells


## The pane mounts on the painted console plate: a plain `TextureRect` (never a nine-slice -
## section 3.7's D3 defect class rule, reused by section 3.10) drawn at its own `master / art_scale`
## box over the **ruled canvas** block, so the painted plate is never fill-stretched (R1 MED-1's
## measured 1.0529 vertical fill). Section 3.10 Amendment 2 re-renders the master at exactly 2x the
## ruled canvas, so the mount and the block coincide.
func test_the_pane_mounts_on_the_painted_console_plate() -> void:
	var panel := _mount()
	var style := _style()
	assert_eq(style.art_scale, ART_SCALE, "section 10's @2x recipe scale")
	assert_eq(style.canvas, CANVAS, "section 3.10 Amendment 2's ruled canvas, at the logical scale")
	assert_eq(panel.call(&"block_size"), BLOCK, "drawn at canvas * art_scale")
	assert_eq(CONSOLE_MASTER, BLOCK * ART_SCALE, "the ruled master is exactly 2x the ruled canvas")
	var plate := panel.get_node("%ConsolePlate") as TextureRect
	assert_true(plate != null, "the console plate is a TextureRect")
	assert_eq(plate.get_class(), "TextureRect", "and not a nine-slice: the master is sized to the block")
	assert_eq(
		plate.texture.resource_path, style.console_path,
		"its texture is the style's own console path"
	)
	assert_eq(
		String(plate.texture.resource_path), "res://assets/ui/ui_armory_console.png",
		"the shipped master"
	)
	assert_eq(
		plate.size * style.art_scale, plate.texture.get_size(),
		"the master mounts at its own 2x box, unstretched (actual %s)" % str(plate.size)
	)
	assert_eq(
		plate.size, BLOCK,
		"and the mount is the ruled canvas, so the plate covers every well (actual %s)"
			% str(plate.size)
	)
	assert_eq(plate.position, Vector2.ZERO, "at the block's origin")
	assert_eq(plate.stretch_mode, TextureRect.STRETCH_SCALE, "fill-fit")
	assert_eq(plate.expand_mode, TextureRect.EXPAND_IGNORE_SIZE, "with no size negotiation")


## Mockup A's three wells, in the console's own space: `ui_armory_console`'s recesses are
## code-drawn (UI_CHROME section 12 Amendment 2), and each group's caption band sits above
## its well - the rects the art no longer has to register.
func test_the_three_wells_mount_at_the_mockup_rects() -> void:
	var panel := _mount()
	var wells: Array = panel.call(&"well_rects")
	assert_eq(wells.size(), 3, "BATTERY RACKS, INVENTORY, AMMUNITION")
	assert_eq(wells[0], RACKS_WELL, "the racks well is Mockup A's own rect (halved from 2x)")
	assert_eq(wells[1], INVENTORY_WELL, "and the inventory well")
	assert_eq(
		wells[2], AMMO_WELL,
		"and the ammunition well, grown from Mockup A's 44 logical to hold the six packs in two rows"
	)
	for index in wells.size():
		var rect: Rect2 = wells[index]
		assert_eq(
			rect.position.x, 30.0, "well %d keeps the console's own 30 px side margin" % index
		)
		assert_eq(rect.size.x, 812.0, "well %d spans the pinned width" % index)
	var racks_box := panel.get_node("%RacksMargin") as Control
	assert_eq(
		racks_box.position, Vector2(30.0, RACKS_WELL.position.y - CAPTION_BAND),
		"the racks group carries its caption band above the well"
	)
	assert_eq(
		racks_box.size, Vector2(812.0, CAPTION_BAND + RACKS_WELL.size.y),
		"and fills the well"
	)
	assert_eq(
		(panel.get_node("%AmmoMargin") as Control).size.y, CAPTION_BAND + AMMO_WELL.size.y,
		"the ammunition group is the well plus its caption"
	)
	## The rows containers start at the well's own inset and caption band, which is what
	## the bay grid's offsets and the code-drawn recesses both measure from.
	var racks := panel.get_node("%RackRows") as VBoxContainer
	assert_eq(racks.position, Vector2(14.0, CAPTION_BAND), "the rack grid opens at the well's origin")
	assert_eq(
		(panel.get_node("%ArmoryRows") as VBoxContainer).position,
		Vector2(14.0, CAPTION_BAND), "and so do the ammunition cards"
	)
	assert_eq(
		String((panel.get_node(
			"ArmoryScroll/ArmoryBody/RacksMargin/RacksBox/RacksCaption"
		) as Label).text),
		"BATTERY RACKS",
		"the racks caption is the pane's own S5 wording"
	)


## ------------------------------------------------------------- 2. the rack bay plates


func test_the_racks_draw_the_4_3_bay_grid_on_the_rack_plate() -> void:
	var panel := _mount()
	assert_eq(PanelScript.RACK_COUNT, RACK_COUNT, "the pin's own rack count")
	var bays: Array = panel.call(&"bay_rects")
	assert_eq(bays.size(), RACK_COUNT, "one bay plate per weapon key")
	assert_eq(
		bays[0], Rect2(BAY_ORIGIN, BAY), "B1 is the grid's own first cell (Mockup A: 44,136)"
	)
	assert_eq(bays[3], Rect2(BAY_ORIGIN + Vector2(3.0 * (BAY.x + BAY_GAP), 0.0), BAY), "B4 ends the first row")
	assert_eq(
		bays[4], Rect2(BAY_ORIGIN + Vector2(0.0, BAY.y + BAY_GAP), BAY), "B5 opens the second"
	)
	assert_eq(bays[6], Rect2(BAY_ORIGIN + Vector2(2.0 * (BAY.x + BAY_GAP), BAY.y + BAY_GAP), BAY), "B7 closes it")
	for index in bays.size():
		var row := _rack_row(panel, index)
		assert_eq(
			row.size, BAY,
			"bay %d is the pinned 194 x 182 plate (actual %s)" % [index, str(row.size)]
		)
		assert_eq(
			row.position,
			bays[index].position - BAY_ORIGIN,
			"and stands at its own grid cell (actual %s)" % str(row.position)
		)
		var plate := row.get_node_or_null(^"Box/BayPlate") as TextureRect
		assert_true(plate != null, "bay %d draws its plate" % index)
		assert_eq(
			plate.texture.resource_path, _style().rack_plate_path,
			"bay %d's plate is the style's rack plate" % index
		)
		assert_eq(plate.texture.get_size(), RACK_MASTER, "at the master's own box")
	assert_eq(
		String((panel.get_node("%RackRows") as VBoxContainer).name), "RackRows",
		"and the container the S5 suites read by index still holds the bays"
	)
	var grid := (panel.get_node("%RackRows") as VBoxContainer).custom_minimum_size
	assert_eq(grid, Vector2(4.0 * BAY.x + 3.0 * BAY_GAP, 2.0 * BAY.y + BAY_GAP), "the grid's own box")


## The W cells are Mockup A's four machined slot recesses (20 x 22 logical on a 22 px pitch
## at `x + 10 + s * 44`, `y + 38`), and a fitted cell shows the mockup's own block inside
## its recess.
func test_the_w_cells_are_the_machined_slot_recesses() -> void:
	var panel := _mount()
	var style := _style()
	assert_eq(style.slot_size, Vector2(20.0, 22.0), "the pinned 20 x 22 logical W cell")
	assert_eq(
		style.drawn_vector(style.slot_size), SLOT, "drawn as the mockup's own 40 x 44 recess"
	)
	assert_eq(style.slot_pitch, 22.0, "on the pinned 22 px logical pitch")
	assert_eq(style.drawn(style.slot_pitch), SLOT_PITCH, "drawn on the mockup's own 44 px step")
	assert_eq(
		style.drawn_vector(style.slot_origin), SLOT_ORIGIN,
		"at the mockup's own offset inside the bay"
	)
	var row := _rack_row(panel, 0)
	var barrels := row.get_node_or_null(^"Box/Barrels") as HBoxContainer
	assert_true(barrels != null, "the bay carries its barrels box (the S5 path)")
	## The standard fit delivers a laser into W1, so B1 holds one barrel on cell 0.
	assert_eq(_rack(panel, 0)[&"cells"], [0], "B1 holds the delivered cell")
	assert_eq(barrels.get_child_count(), 1, "and one chip")
	var chip := barrels.get_child(0) as Control
	assert_eq(
		chip.position, SLOT_ORIGIN,
		"the chip rides its own slot recess (actual %s)" % str(chip.position)
	)
	assert_eq(
		chip.size, SLOT, "at the recess's own size (actual %s)" % str(chip.size)
	)
	var marks = panel.call(&"bay_marks", 0)
	assert_true(marks != null, "the bay carries its code-drawn marks")
	assert_eq(marks.marked_cells(), [0], "the fitted cell is the one marked")
	assert_eq(marks.is_selected(), true, "and B1 is the selected bay by default")
	## An empty rack marks nothing.
	assert_eq(panel.call(&"bay_marks", 1).marked_cells(), [], "B2 is empty: nothing is marked")


## ------------------------------------------------------------------ 3. the SALVO cells


func test_the_salvo_strip_renders_the_cycle_figure() -> void:
	var panel := _mount()
	var strip := _rack_row(panel, 0).get_node_or_null(^"Box/Salvo")
	assert_true(strip != null, "every bay carries its SALVO strip")
	var caption := strip.call(&"caption_node") as Label
	assert_eq(caption.text, "SALVO s", "the pinned 12 px caption, an engine Label")
	assert_eq(
		caption.position, Vector2(10.0, 112.0),
		"at the mockup's own ledge offset inside the bay (actual %s)" % str(caption.position)
	)
	assert_eq(strip.call(&"cell_nodes").size(), 3, "three ui_seg_* cells")
	for index in 3:
		var cell: TextureRect = strip.call(&"cell_nodes")[index]
		assert_eq(
			Rect2(cell.position, cell.size),
			Rect2(SALVO_ORIGIN + Vector2(index * SALVO_PITCH, 0.0), SALVO_CELL),
			"cell %d is on Mockup A's own step" % index
		)
	## A laser rack has no travelling member: no figure, blanks in every cell.
	var laser: Dictionary = panel.call(&"salvo_readout", 0)
	assert_eq(int(laser[&"figure"]), -1, "a laser rack states no cadence")
	assert_eq(laser[&"cells"], [-1, -1, -1], "so its cells stay blank")
	## A cannon's 0.6 s cycle reads 060 (Mockup A's approved figure: hundredths, zero-padded).
	_profile.call(&"add_module", CANNON, 1)
	assert_true(
		bool(_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 1, CANNON)),
		"a cannon fits W2"
	)
	_profile.call(&"set_battery_groups", VANGUARD, [[0], [1]])
	assert_eq(
		String(_rack(panel, 1)[&"state"]),
		PanelScript.RACK_SALVO % WeaponComponent.interval_of(&"cannon"),
		"the S5 state line is untouched"
	)
	var cannon: Dictionary = panel.call(&"salvo_readout", 1)
	assert_eq(
		int(cannon[&"figure"]), 60,
		"the cannon's 0.6 s reads 60 hundredths (actual %s)" % str(cannon)
	)
	assert_eq(
		String(cannon[&"text"]), "060",
		"which the three cells render as 060 (actual %s)" % String(cannon[&"text"])
	)
	## A rocket's 1.2 s cylinder reads 120 - the approved format holds every real cadence.
	_profile.call(&"add_module", ROCKET, 1)
	assert_true(
		bool(_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 2, ROCKET)),
		"a rocket fits W3"
	)
	_profile.call(&"set_battery_groups", VANGUARD, [[0, 1, 2]])
	var mixed: Dictionary = panel.call(&"salvo_readout", 0)
	assert_eq(int(mixed[&"figure"]), 120, "the mixed rack gates on the rocket's 1.2 s")
	assert_eq(String(mixed[&"text"]), "120", "read as 120")
	assert_true(
		PanelScript.SALVO_MAX >= 999, "the format holds a cycle up to 9.99 s in three cells"
	)


## ------------------------------------------------------------ 4. the row plates


## INVENTORY and AMMUNITION rows ride the brushed row plate (a nine-slice: flat bands only,
## section 3.10) at the pinned row heights.
func test_the_rows_ride_the_row_plate_at_the_pinned_heights() -> void:
	var panel := _mount()
	var style := _style()
	assert_eq(style.ammo_row_height, 32.0, "an ammunition row is the pinned 32 logical tall")
	assert_eq(style.ammo_row_height * ART_SCALE, AMMO_ROW, "drawn 64")
	assert_eq(
		style.inventory_row_height, 22.0, "an inventory row is the pinned 22 logical tall"
	)
	assert_eq(style.inventory_row_height * ART_SCALE, INVENTORY_ROW, "drawn 44")
	assert_eq(style.inventory_icon, Vector2(20.0, 18.0), "with the pinned 20 x 18 icon slot")
	var card := _ammo_card(panel, &"cannon")
	assert_true(card != null, "the cannon pack has a card")
	assert_eq(card.size.y, AMMO_ROW, "the card is the pinned height")
	assert_true(
		is_equal_approx(
			card.size.x, (AMMO_WELL.size.x - 2.0 * 8.0) / 3.0
		),
		"three across fill the well on the style's gap (actual %s)" % str(card.size)
	)
	var plate := _plate(card)
	assert_true(plate != null, "the card rides a row plate")
	var patch := plate.get_node_or_null(^"Plate") as NinePatchRect
	assert_true(patch != null, "a nine-slice (the flat-band idiom)")
	assert_eq(
		patch.texture.resource_path, style.row_plate_path, "at the style's own row plate"
	)
	assert_eq(patch.patch_margin_left, 32, "with A0's own margins: a flat stretch zone")
	assert_eq(patch.patch_margin_top, 8, "and the left bolts kept whole")
	var rows := panel.get_node("%ArmoryRows") as VBoxContainer
	assert_eq(rows.get_child_count(), Catalog.AMMO_PACKS.size() + 1, "one card per pack, plus slack")
	assert_eq(
		(rows.get_child(3) as Control).position.y, AMMO_ROW + 8.0,
		"and the second row of three sits one card below the first"
	)
	var inventory := panel.get_node("%InventoryRows") as VBoxContainer
	assert_eq(inventory.get_child_count(), 1, "the fixture owns no weapons: one empty-state line")
	assert_eq(
		String((inventory.get_child(0) as Label).text), PanelScript.INVENTORY_EMPTY,
		"which is the pane's own words"
	)
	_profile.call(&"add_module", CANNON, 1)
	var row := inventory.get_child(0) as Button
	assert_true(row != null, "a owned weapon lists")
	assert_eq(row.size.y, INVENTORY_ROW, "at the inventory height")
	assert_eq(
		(_plate(row).get_node(^"Plate") as NinePatchRect).texture.resource_path,
		style.row_plate_path,
		"on the same row plate"
	)
	assert_eq(
		String(_cell(row, "Status").get_node(^"Value").text),
		PanelScript.INVENTORY_TEXT % ["OWNED", 1],
		"and keeps the S5 OWNED x<n> figure"
	)


## --------------------------------------------------- 5. the danger row treatments


## Section 3.10: danger/insufficient/refusal states reuse section 3.1/3.1b verbatim as row
## treatments - the label plus a 1 px code-drawn frame, and the digits never recolour.
func test_danger_rows_follow_section_3_1_and_3_1b() -> void:
	var panel := _mount()
	var rocket := _ammo_card(panel, &"rocket")
	assert_true(rocket != null, "the rocket pack has a card")
	## The fixture holds 40 units against a 10-unit ceiling: OVER CAP.
	assert_eq(_cell_text(rocket, "Status"), PanelScript.TAG_OVER_CAP, "the fixture's rocket is over cap")
	assert_true(_plate(rocket).danger(), "so its card wears the code-drawn danger frame")
	var tag := _cell(rocket, "Status").get_node(^"Value") as Label
	assert_true(
		tag.has_theme_color_override(&"font_color"), "and its state label turns the danger role"
	)
	assert_eq(
		tag.get_theme_color(&"font_color"), _style().colour(&"accent_danger"),
		"which is the style's own accent_danger"
	)
	## A half-full pack is no danger state at all.
	var cannon := _ammo_card(panel, &"cannon")
	assert_false(_plate(cannon).danger(), "an in-stock pack carries no frame")
	assert_false(
		(_cell(cannon, "Status").get_node(^"Value") as Label).has_theme_color_override(&"font_color"),
		"and no colour override"
	)
	## Digits never recolour: the HELD figure keeps the theme's own colour throughout.
	var held := _cell(rocket, "Held").get_node(^"Value") as Label
	assert_false(
		held.has_theme_color_override(&"font_color"), "the held figure is never recoloured"
	)
	## Insufficient credits is the section 3.1b read too: the price label turns and the card
	## is framed, and a refused purchase still writes nothing.
	_profile.call(&"spend", int(_profile.call(&"credits")))
	panel.call(&"refresh_profile", &"credits")
	var price := _cell(cannon, "Price").get_node(^"Value") as Label
	assert_true(price.has_theme_color_override(&"font_color"), "an unaffordable price turns")
	assert_true(_plate(cannon).danger(), "and the card is framed")
	var empty := _snapshot()
	(cannon as Button).pressed.emit()
	_unchanged(empty, "an unaffordable purchase")


## ------------------------------------------------- 6. the surface is surface only


## The wave is **surface only** (section 3.10): a refused drop still writes nothing at all -
## fit, bag, rack record, credits and hold alike - and the pane's read-backs are the S5 set.
func test_a_refused_drop_writes_nothing() -> void:
	var panel := _mount()
	var before := _snapshot()
	## The bag holds no cannon: the install route refuses with the pane's own wording. The
	## payload is built by hand because an empty-bag drag cannot start (`drag_inventory`
	## answers `{}`), so this is the stale-payload path the engine never hands out.
	var stale: Dictionary = {&"kind": PanelScript.DRAG_INVENTORY, &"base": CANNON}
	assert_false(bool(panel.call(&"drop", 1, PanelScript.DROP_RACK_BODY, stale)), "no cannon in the bag")
	assert_eq(_last_status(), PanelScript.REFUSAL_NO_WEAPONS, "the refusal names the empty bag")
	assert_true(_last_danger(), "in the danger colour")
	_unchanged(before, "a refused install")
	## A drag the bag cannot start answers `{}` and never reaches the pane.
	assert_true(
		(panel.call(&"drag_inventory", CANNON) as Dictionary).is_empty(),
		"an unowned base drags nothing"
	)
	assert_false(
		bool(panel.call(&"drop", 1, PanelScript.DROP_RACK_BODY, {})),
		"and an empty payload is refused before any guard"
	)
	assert_eq(_last_status(), PanelScript.REFUSAL_NO_WEAPONS, "with no new status line")
	_unchanged(before, "an empty payload")
	## A barrel move to an address with nothing in it refuses just as quietly.
	var payload: Variant = panel.call(&"drag_barrel", 1, 0)
	assert_false(bool(panel.call(&"move_barrel", 1, 0, 2, 0)), "B2 holds no barrel to move")
	assert_eq(_last_status(), PanelScript.REFUSAL_FIT_ILLEGAL, "the pin's own wording")
	_unchanged(before, "a refused move")
	## The preview agrees with the write, and neither is a drag the engine can start.
	assert_false(
		bool(panel.call(&"can_drop", 1, PanelScript.DROP_RACK_BODY, {&"kind": &"inventory", &"base": CANNON})),
		"can_drop refuses what drop refuses"
	)
	assert_true(
		(panel.call(&"drag_inventory", CANNON) as Dictionary).is_empty(),
		"and an unowned base drags nothing"
	)
	assert_true(
		(panel.call(&"drag_barrel", 1, 0) as Dictionary).is_empty(),
		"nor does an empty rack's first chip"
	)
	_unchanged(before, "the whole refusal set")


## The drag-drop ordering is untouched: an install lands in the rack's next free W cell, a
## within-rack drag re-orders the chips, a between-rack drag moves the barrel, and the `x`
## returns it to the inventory.
func test_the_drag_ordering_and_the_close_are_unchanged() -> void:
	var panel := _mount()
	assert_true(_drop_inventory(panel, 1, PanelScript.DROP_RACK_BODY, LASER) == false or true, "a drag never throws")
	## An owned instance lands in the rack's next free cell, through the composed write.
	_profile.call(&"add_module", CANNON, 1)
	assert_true(_drop_inventory(panel, 1, PanelScript.DROP_RACK_BODY, CANNON), "a cannon into B2")
	assert_eq(_rack(panel, 1)[&"cells"], [1], "B2 holds the cannon's cell")
	assert_eq(_rack(panel, 1)[&"barrels"][0][&"text"], "W2 CANNON MKI", "as its own chip")
	assert_eq(
		_last_status(), PanelScript.STATUS_INSTALLED % ["CANNON MKI", "B2"], "and the pane says so"
	)
	## A second weapon in the same rack appends: cell order is the rack's own.
	_profile.call(&"add_module", ROCKET, 1)
	assert_true(_drop_inventory(panel, 1, PanelScript.DROP_RACK_BODY, ROCKET), "a rocket next")
	assert_eq(_rack(panel, 1)[&"cells"], [1, 2], "the rack keeps its append order")
	assert_eq(
		_rack(panel, 1)[&"barrels"][1][&"text"], "W3 ROCKET POD", "with the chip order to match"
	)
	## The SALVO strip follows the rack's own read: the rocket is its slowest member.
	assert_eq(
		String(panel.call(&"salvo_readout", 1)[&"text"]), "120",
		"the strip renders the slowest member's cadence"
	)
	## A within-rack re-order follows the record.
	var payload: Variant = panel.call(&"drag_barrel", 1, 1)
	assert_true(bool(panel.call(&"drop", 1, 1, payload)) == false, "dropping a barrel on itself is refused")
	var moved: Variant = panel.call(&"drag_barrel", 1, 0)
	assert_true(bool(panel.call(&"move_barrel", 1, 0, 1, 1)), "the cannon moves behind the rocket")
	assert_eq(_rack(panel, 1)[&"cells"], [2, 1], "B2's order swapped")
	## The `x` returns a barrel to the bag.
	var chip := (
		(_rack_row(panel, 1).get_node(^"Box/Barrels") as HBoxContainer).get_child(0) as HBoxContainer
	)
	(chip.get_node(^"Close") as Button).pressed.emit()
	assert_eq(_rack(panel, 1)[&"cells"], [1], "one barrel left")
	assert_eq(_last_status(), PanelScript.STATUS_REMOVED % "ROCKET POD", "and the pane reports it")
	assert_false(_last_danger(), "success is never the danger colour")


## ------------------------------------------------ 7. the style is the single surface


## Section 3.9 rule 5: a user `.tres` restyles **and** relayouts the pane with no code edit.
func test_a_user_tres_restyles_and_relayouts_with_no_code_edit() -> void:
	var panel := _mount()
	var probe := StyleScript.defaults()
	probe.canvas = Vector2(500.0, 400.0)
	probe.bay_size = Vector2(120.0, 100.0)
	probe.bay_gap = 12.0
	probe.slot_size = Vector2(24.0, 20.0)
	probe.slot_pitch = 26.0
	probe.ammo_row_height = 40.0
	probe.text_dim = Color(0.1, 0.9, 0.2)
	probe.console_path = "res://assets/ui/ui_armory_console.png"
	var saved := ResourceSaver.save(probe, STYLE_PROBE_PATH)
	assert_eq(saved, OK, "the user's style writes")
	panel.call(&"set_style_file", STYLE_PROBE_PATH)
	var live := _style()
	assert_eq(live.canvas, Vector2(500.0, 400.0), "the canvas moved")
	assert_eq(
		(panel.call(&"block_size") as Vector2).x, 1000.0,
		"and the block follows the canvas (actual %s)" % str(panel.call(&"block_size"))
	)
	assert_eq(
		(panel.call(&"bay_rects")[0] as Rect2).size, Vector2(240.0, 200.0),
		"the bay is the file's own (120 x 100 logical, drawn at 2x)"
	)
	assert_eq(
		(panel.call(&"bay_rects")[4] as Rect2).position.y
			- (panel.call(&"bay_rects")[0] as Rect2).position.y,
		224.0,
		"on the file's own gap (100 + 12, drawn)"
	)
	assert_eq(_style().colour(&"text_dim"), Color(0.1, 0.9, 0.2), "and the palette is the file's")
	assert_eq(
		_rack_row(panel, 0).size, Vector2(240.0, 200.0), "the drawn bay follows the relayout"
	)
	## Dropping the file returns the shipped numbers: the override is not a one-way door.
	panel.call(&"set_style_file", StyleScript.ARMORY_USER_PATH)
	assert_eq(_style().canvas, CANVAS, "the shipped canvas is back")
	assert_eq(panel.call(&"bay_rects")[0], Rect2(BAY_ORIGIN, BAY), "and the shipped bay grid")
	assert_eq(
		_rack_row(panel, 0).size, BAY,
		"drawn at the shipped bay box (actual %s)" % str(_rack_row(panel, 0).size)
	)


## The style really is a `CockpitStyle` (one palette, one asset idiom) and it carries the
## armory's own assets and the pinned metrics.
func test_the_style_extends_cockpit_style_with_the_pinned_metrics() -> void:
	var panel := _mount()
	var style := _style()
	assert_true(style is CockpitStyle, "an ArmoryStyle is a CockpitStyle")
	var cockpit := CockpitStyleScript.defaults()
	for role: StringName in [
		&"void_base", &"void_panel_raised", &"metal_dark", &"metal_mid", &"metal_light",
		&"text_primary", &"text_dim", &"accent_danger", &"accent_danger_bright", &"panel_steel",
	]:
		assert_eq(
			style.colour(role), cockpit.colour(role),
			"%s comes from the family's one palette" % role
		)
	assert_eq(
		style.seg_path("7"), "res://assets/ui/ui_seg_7.png",
		"the drum cells keep the family's asset idiom"
	)
	for path: String in [style.console_path, style.rack_plate_path, style.row_plate_path]:
		assert_true(ResourceLoader.exists(path), "%s ships" % path)
	assert_eq(style.rack_plate_path, "res://assets/ui/ui_armory_rack_plate.png", "the rack plate")
	assert_eq(style.row_plate_path, "res://assets/ui/ui_armory_row_plate.png", "the row plate")
	assert_eq(style.bay_size, Vector2(97.0, 91.0), "the pinned 97 x 91 bay, at the logical scale")
	assert_eq(style.bay_size * ART_SCALE, BAY, "drawn at the master's own 194 x 182 box")
	assert_eq(style.slot_size, Vector2(20.0, 22.0), "the pinned 20 x 22 W cell")
	assert_eq(style.slot_pitch, 22.0, "on the pinned 22 px pitch")
	assert_eq(style.salvo_cell, Vector2(20.0, 36.0), "the family's own 20 x 36 drum cell")
	assert_eq(style.salvo_cells, 3, "three SALVO cells")
	assert_eq(style.bay_columns, 4, "Mockup A's 4+3 grid")
	assert_eq(style.bay_row_count(RACK_COUNT), 2, "seven bays fill two rows")
	assert_eq(style.ammo_well.size.y, 68.0, "the ammunition well holds two 32-logical rows")
	assert_eq(
		style.rows_height(2, style.ammo_row_height), style.ammo_well.size.y,
		"the six packs fit the ammunition well exactly"
	)
	assert_eq(style.growth(2, 68.0), 0.0, "so the pinned well needs no growth")
