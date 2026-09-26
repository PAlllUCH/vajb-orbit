extends Node
## S20-R1's independent re-measurement (AC1-AC6 of `S20_BRIEF.md`, diffed against UI_SPEC
## section 3.10 Amendment 4). Windowed standalone run under a scratch store (L229):
##
##   XDG_DATA_HOME=$(mktemp -d) $GODOT_CONSOLE --path "$VAJB_PROJ" \
##     res://tests/probe_s20_review.tscn --quit-after 900
##
## Prints `[r1]` lines, saves two PNGs under `user://` (the scratch store) and quits 0.
## It writes nothing else and never boots the owner's live profile.

const StationScene := preload("res://ui/screens/station.tscn")
const PanelScene := preload("res://ui/station/armory_panel.tscn")
const StyleScript := preload("res://ui/station/armory_style.gd")
const PanelScript := preload("res://ui/station/armory_panel.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const FitData := preload("res://game/ship_fit.gd")

const HOST := Vector2(1392.0, 610.0)
const STATION_HOST := Vector2i(1920, 1080)
const CONSOLE := Vector2(1360.0, 516.0)
const CONSOLE_ORIGIN := Vector2(16.0, 68.0)
const BAND_ORIGIN := Vector2(16.0, 38.0)
const BAND := Vector2(1328.0, 192.0)
const BAY := Vector2(260.0, 192.0)
const BAY_GAP := 7.0
const CELL := Vector2(117.0, 52.0)
const CELL_ORIGIN := Vector2(10.0, 34.0)
const CELL_GAP := 6.0
const LEDGE_ORIGIN := Vector2(10.0, 150.0)
const LEDGE := Vector2(240.0, 34.0)
const SALVO_CELL := Vector2(18.0, 32.0)
const SALVO_PITCH := 20.0
const WELLS_TOP := 286.0
const WELL := Vector2(648.0, 220.0)
const ITEM := Vector2(320.0, 68.0)
const ITEM_GAP := 8.0
const CHIP_FLOOR := 4.5
const DESTROYER: StringName = &"ship_destroyer"
const WEAPON_SLOT: StringName = &"weapons"
const ROCKET_PACK: StringName = &"rocket"
const USER_PROBE := "user://probe_s20_review_style.tres"
const PANE_PNG := "user://s20_review_pane.png"
const STATION_PNG := "user://s20_review_station.png"
const SCAN_PATHS: Array[String] = [
	"res://ui/station/armory_panel.gd",
	"res://ui/station/armory_style.gd",
	"res://ui/screens/station.gd",
	"res://tools/build_theme.gd",
	"res://tests/test_s20_chrome_unify.gd",
	"res://tests/test_d7_armory.gd",
	"res://tests/test_s15_armory_layout.gd",
	"res://tests/test_s11_inspector.gd",
]

var _profile: Node = null
var _pane_host: Control = null
var _panel: Control = null
var _station: Control = null
var _failures: Array[String] = []


func _ready() -> void:
	var watchdog := get_tree().create_timer(150.0)
	watchdog.timeout.connect(func() -> void:
		print("[r1] WATCHDOG quit")
		get_tree().quit(2)
	)
	_run.call_deferred()


func _run() -> void:
	_scan()
	_fixture()
	if _profile == null:
		return
	await _mount_pane()
	_ac1()
	_ac2()
	_ac3()
	_ac4()
	_ac6()
	await _capture(PANE_PNG)
	await _ac5()
	await _buy_click()
	await _capture(STATION_PNG)
	_ac3_user_path()
	print("[r1] failures=%d" % _failures.size())
	for line: String in _failures:
		print("[r1] FAIL %s" % line)
	print("[r1] DONE")
	get_tree().quit(0)


## ------------------------------------------------------- 0. the static scans (AC1/AC3)

func _scan() -> void:
	for path: String in SCAN_PATHS:
		var source := FileAccess.get_file_as_string(path)
		print("[r1] scan %s hex=%d console_ref=%d console_path=%d font_size=%d" % [
			path.get_file(), _count(source, "\"#"), _count(source, "ui_armory_console"),
			_count(source, "console_path"), _count(source, "font_size"),
		])
	var scene := FileAccess.get_file_as_string("res://ui/station/armory_panel.tscn")
	print("[r1] scan armory_panel.tscn console_ref=%d ext_resource=%d" % [
		_count(scene, "ui_armory_console"), _count(scene, "2_console"),
	])


static func _count(source: String, needle: String) -> int:
	var total := 0
	var at := source.find(needle)
	while at != -1:
		total += 1
		at = source.find(needle, at + 1)
	return total


## ------------------------------------------------------------------- the fixture

func _fixture() -> void:
	_profile = get_tree().root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		print("[r1] FAIL no PlayerProfile")
		get_tree().quit(1)
		return
	_profile.set(&"save_path", "user://probe_s20_review.cfg")
	_profile.set(&"_credits", 10000)
	_profile.set(&"_active_ship", DESTROYER)
	_profile.set(&"_owned_ships", [DESTROYER] as Array[StringName])
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_ammo", {})
	_profile.set(&"_cargo", {})
	_profile.set(&"_batteries", {})
	_profile.call(&"add_module", &"w_laser", 1)
	var fit: Dictionary = FitData.standard_fit(DESTROYER)
	var weapons: Array = []
	for index in FitData.slot_capacity(DESTROYER, WEAPON_SLOT):
		weapons.append("" if index > 3 else ("w_laser" if index % 2 == 0 else "w_cannon"))
	fit[WEAPON_SLOT] = weapons
	_profile.call(&"set_fit", DESTROYER, fit)
	_profile.call(&"set_battery_groups", DESTROYER, [[0, 1, 2, 3]])
	_profile.call(&"add_cargo", &"ammo_rocket", 40)


func _mount_pane() -> void:
	get_window().size = Vector2i(int(HOST.x), int(HOST.y))
	_pane_host = Control.new()
	_pane_host.name = "S20ReviewHost"
	_pane_host.theme = ThemeRes
	_pane_host.size = HOST
	add_child(_pane_host)
	_panel = PanelScene.instantiate() as Control
	_pane_host.add_child(_panel)
	await get_tree().process_frame
	_panel.call(&"refresh_profile", &"batteries")


func _style() -> Resource:
	return _panel.call(&"style")


func _chrome() -> Control:
	return (_panel.get_node(^"%Console") as Control).get_node(^"ConsolePanels") as Control


func _rack_row(index: int) -> Control:
	return (_panel.get_node("%RackRows") as VBoxContainer).get_child(index) as Control


func _card(pack_id: StringName) -> Button:
	for child: Node in (_panel.get_node("%ArmoryRows") as Control).get_children():
		var row := child as Button
		if row != null and String(row.name).to_lower().ends_with(String(pack_id)):
			return row
	return null


func _fail(line: String) -> void:
	_failures.append(line)


func _check(condition: bool, line: String) -> void:
	if not condition:
		_fail(line)


## ------------------------------------------------------------------- 1. AC1 (A4.1)

func _ac1() -> void:
	var plate := _panel.get_node("%ConsolePlate") as NinePatchRect
	print("[r1] ac1 plate_texture=%s" % ("null" if plate.texture == null else plate.texture.resource_path))
	_check(plate.texture == null, "AC1 the scene plate still draws the master")
	var source := FileAccess.get_file_as_string("res://ui/station/armory_panel.gd")
	_check(source.find("ui_armory_console") == -1, "AC1 pane code mentions the master")
	_check(_style().get(&"console_path") == null, "AC1 the style still carries console_path")
	_check(ResourceLoader.exists("res://assets/ui/ui_armory_console.png"), "AC1 master gone from disk")
	var frame := _chrome().get(&"frame_box") as StyleBox
	if frame is StyleBoxTexture:
		var box := frame as StyleBoxTexture
		print("[r1] ac1 frame=%s patch=%.0f/%.0f/%.0f/%.0f expand=%.0f" % [
			box.texture.resource_path, box.texture_margin_left, box.texture_margin_top,
			box.texture_margin_right, box.texture_margin_bottom, box.expand_margin_left,
		])
		_check(
			String(box.texture.resource_path) == "res://assets/ui/ui_panel_frame.png",
			"AC1 the chrome frame is not ui_panel_frame"
		)
		_check(box.texture_margin_left == 32.0, "AC1 the frame patch margin is not 32")
	else:
		_fail("AC1 the chrome has no texture frame")
	var sibling := PanelContainer.new()
	sibling.theme_type_variation = &"PanelRaised"
	_panel.add_child(sibling)
	_check(
		frame == sibling.get_theme_stylebox(&"panel"),
		"AC1 the chrome frame is not the PanelRaised panel box"
	)
	sibling.free()
	var bays: Array = _panel.call(&"bay_rects")
	var wells: Array = _panel.call(&"well_rects")
	print("[r1] ac1 bays=%d wells=%d frame_calls=%d" % [
		bays.size(), wells.size(), int(_chrome().get(&"bays").size()) + int(_chrome().get(&"wells").size()),
	])


## ------------------------------------------------------------------- 2. AC2 (A4.2)

func _ac2() -> void:
	var chrome := _chrome()
	var slot := chrome.get(&"slot_box") as StyleBox
	if slot is StyleBoxTexture:
		print("[r1] ac2 slot=%s" % (slot as StyleBoxTexture).texture.resource_path)
		_check(
			String((slot as StyleBoxTexture).texture.resource_path)
			== "res://assets/ui/ui_slot_weapon_normal.png",
			"AC2 the cell box is not the slot chrome"
		)
	else:
		_fail("AC2 the cells have no slot box")
	var probe := Button.new()
	probe.theme_type_variation = &"SlotButtonWeapon"
	_panel.add_child(probe)
	_check(
		slot == probe.get_theme_stylebox(&"normal"),
		"AC2 the cell box is not the SlotButtonWeapon normal box"
	)
	probe.free()
	## A fitted chip: the name plate is a StationButton plate over the cell, the X a plate.
	var barrels := _rack_row(0).get_node(^"Box/Barrels") as Control
	var chip := barrels.get_child(0) as Control
	var name_plate := chip.get_node(^"Name") as Button
	var close := chip.get_node(^"Close") as Button
	print("[r1] ac2 name_var=%s name_box=%s close_var=%s close_flat=%s close_size=%s" % [
		name_plate.theme_type_variation,
		String((name_plate.get_theme_stylebox(&"normal") as StyleBoxTexture).texture.resource_path),
		close.theme_type_variation, str(close.flat), str(close.size),
	])
	_check(close.theme_type_variation == &"StationButton", "AC2 the X is not a StationButton")
	_check(not close.flat, "AC2 the X still draws flat")
	var card := _card(ROCKET_PACK)
	var buy := card.get_node(^"Buy") as Button
	print("[r1] ac2 buy_var=%s buy_box=%s buy_pressed=%s" % [
		buy.theme_type_variation,
		String((buy.get_theme_stylebox(&"normal") as StyleBoxTexture).texture.resource_path),
		str(buy.pressed.get_connections().size()),
	])
	_check(buy.theme_type_variation == &"StationButton", "AC2 BUY is not a StationButton")
	## State chips: label + 1 px frame, Tokens tones, chevron on the over-cap chip.
	var head := _rack_row(0).get_node(^"Box/Head") as Control
	var state := head.get_node(^"State") as Label
	var chip_plate := head.get_node(^"Chip") as Control
	print("[r1] ac2 state=%s chip_danger=%s chevron=%s frame=%.0f ready=%s" % [
		state.text, str(chip_plate.get(&"danger")), str(chip_plate.get(&"chevron")),
		_style().frame_width, (_rack_row(1).get_node(^"Box/Head/State") as Label).text,
	])
	_check(state.text == PanelScript.RACK_STATE_OVER, "AC2 the over-cap bay chip reads wrong")
	_check(bool(chip_plate.get(&"chevron")), "AC2 the over-cap chip carries no chevron")
	_check(_style().frame_width == 1.0, "AC2 the chip frame is not 1 px")
	var tag := (card.get_node(^"Status") as Control).get_node(^"Value") as Label
	var wordings: Array[String] = []
	for pack: String in ["cannon", "rocket"]:
		wordings.append(((_card(StringName(pack)).get_node(^"Status") as Control).get_node(^"Value") as Label).text)
	print("[r1] ac2 stock chips=%s" % str(wordings))


## ------------------------------------------------------------------- 3. AC3 (A4.3)

func _ac3() -> void:
	var style := _style()
	var roles: Array[StringName] = [
		&"caption", &"caption_void", &"bay_bg", &"cell_bg", &"ledge_bg",
		&"item_bg", &"chip_bg", &"chip_danger_bg", &"fit_line",
	]
	var drifted: Array[String] = []
	for role: StringName in roles:
		var token := StringName("armory_" + String(role))
		var want: Color = ThemeRes.get_color(token, &"Tokens")
		if style.colour(role) != want:
			drifted.append("%s=%s want=%s" % [role, style.colour(role), want])
	print("[r1] ac3 tokens_drifted=%s" % ("none" if drifted.is_empty() else str(drifted)))
	_check(drifted.is_empty(), "AC3 palette roles do not resolve from Tokens/armory_*")
	## The override path: a user .tres restyles and dropping it returns the theme's values.
	var shipped: Color = style.colour(&"caption")
	var probe := StyleScript.defaults()
	probe.caption = Color(0.1, 0.9, 0.2)
	probe.chip_bg = Color(0.2, 0.1, 0.4)
	var saved := ResourceSaver.save(probe, USER_PROBE)
	_panel.call(&"set_style_file", USER_PROBE)
	var live: Color = _style().colour(&"caption")
	var live_fill: Color = _style().colour(&"chip_bg")
	_panel.call(&"set_style_file", StyleScript.ARMORY_USER_PATH)
	var back: Color = _style().colour(&"caption")
	print("[r1] ac3 user_tres saved=%d live=%s live_fill=%s back=%s default_path=%s" % [
		saved, live, live_fill, back, StyleScript.ARMORY_USER_PATH,
	])
	_check(saved == OK and live == Color(0.1, 0.9, 0.2), "AC3 the user tres does not win")
	_check(back == shipped, "AC3 the theme's own value does not return")
	_check(FileAccess.file_exists(StyleScript.ARMORY_USER_PATH) == false, "AC3 a real user tres exists")
	var dir := DirAccess.open(USER_PROBE.get_base_dir())
	if dir != null and FileAccess.file_exists(USER_PROBE):
		dir.remove(USER_PROBE.get_file())


## ------------------------------------------------------------------- 4. AC4 (A4.3)

func _ac4() -> void:
	var style := _style()
	var fill: Color = style.colour(&"chip_danger_bg")
	var card := _card(ROCKET_PACK)
	var tag := (card.get_node(^"Status") as Control).get_node(^"Value") as Label
	var card_ratio := _contrast(tag.get_theme_color(&"font_color"), fill)
	var state := _rack_row(0).get_node(^"Box/Head/State") as Label
	var bay_ratio := _contrast(state.get_theme_color(&"font_color"), fill)
	var resting := _card(&"cannon")
	var resting_tag := (resting.get_node(^"Status") as Control).get_node(^"Value") as Label
	var resting_ratio := _contrast(resting_tag.get_theme_color(&"font_color"), style.colour(&"chip_bg"))
	print("[r1] ac4 card=%.3f bay=%.3f overlay=%s resting(cannon)=%.3f overlay=%s" % [
		card_ratio, bay_ratio, str(tag.has_theme_color_override(&"font_color")),
		resting_ratio, str(resting_tag.has_theme_color_override(&"font_color")),
	])
	_check(card_ratio >= CHIP_FLOOR, "AC4 the card OVER CAP label is %.3f:1" % card_ratio)
	_check(bay_ratio >= CHIP_FLOOR, "AC4 the bay OVER CAP label is %.3f:1" % bay_ratio)


## A real left click on the plated BUY chip, through the viewport's own GUI routing, in
## the station phase (1920x1080 window = the canvas, so the coordinates are 1:1): one press
## buys exactly one pack - the card must not fire beside the chip.
func _buy_click() -> void:
	var pane := (_station.get(&"_panels") as Array)[0] as Control
	_profile.set(&"_cargo", {&"ammo_rocket": 0})
	pane.call(&"refresh_profile", &"ammo")
	await get_tree().process_frame
	var card: Button = null
	for child: Node in (pane.get_node("%ArmoryRows") as Control).get_children():
		var row := child as Button
		if row != null and String(row.name).to_lower().ends_with("rocket"):
			card = row
	if card == null:
		_fail("BUY: no rocket card in the station's armory")
		return
	var buy := card.get_node(^"Buy") as Control
	var emissions: Array[int] = [0]
	pane.status_requested.connect(func(_message: String, _danger: bool) -> void:
		emissions[0] += 1
	)
	var before: int = int((_profile.get(&"_cargo") as Dictionary).get(&"ammo_rocket", 0))
	var centre := buy.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed = pressed
		event.position = centre
		event.global_position = centre
		get_viewport().push_input(event, true)
	await get_tree().process_frame
	var after: int = int((_profile.get(&"_cargo") as Dictionary).get(&"ammo_rocket", 0))
	print("[r1] buy filter=%d emissions=%d units %d -> %d at %s hovered=%s" % [
		buy.mouse_filter, emissions[0], before, after, str(centre),
		str(get_viewport().gui_get_hovered_control().name) if get_viewport().gui_get_hovered_control() != null else "none",
	])
	_check(after - before == 6, "BUY bought %d units, not one rocket pack (6)" % (after - before))
	_check(emissions[0] == 1, "BUY fired %d status reads, not one" % emissions[0])


## The shipped override path itself: a `.tres` dropped at `ARMORY_USER_PATH` is what the
## pane loads with no code edit. Written, read back, deleted inside this one phase.
func _ac3_user_path() -> void:
	var probe := StyleScript.defaults()
	probe.caption = Color(0.9, 0.2, 0.4)
	var saved := ResourceSaver.save(probe, StyleScript.ARMORY_USER_PATH)
	var loaded: Resource = StyleScript.load_style()
	var picked: bool = loaded != null and loaded.colour(&"caption") == Color(0.9, 0.2, 0.4)
	_panel.call(&"set_style_file", StyleScript.ARMORY_USER_PATH)
	var live: Color = _style().colour(&"caption")
	var gone := true
	var dir := DirAccess.open(StyleScript.ARMORY_USER_PATH.get_base_dir())
	if dir != null and FileAccess.file_exists(StyleScript.ARMORY_USER_PATH):
		gone = dir.remove(StyleScript.ARMORY_USER_PATH.get_file()) == OK
	print("[r1] ac3 user_path saved=%d load_style_picks=%s live=%s removed=%s" % [
		saved, str(picked), live, str(gone),
	])
	_check(saved == OK and picked, "AC3 the default user path is not honoured")
	_check(live == Color(0.9, 0.2, 0.4), "AC3 the pane does not apply the user file")
	_check(gone and not FileAccess.file_exists(StyleScript.ARMORY_USER_PATH), "AC3 the probe file stayed")


## ------------------------------------------------------------------- 5. AC6 (A3)

func _ac6() -> void:
	var console := Rect2(_panel.get_node(^"%Console").position, _panel.get_node(^"%Console").size)
	print("[r1] ac6 host=%s console=%s/%s block=%s" % [
		str(_pane_host.size), str(_panel.get_node(^"%Console").position),
		str(_panel.get_node(^"%Console").size), str(_panel.call(&"block_size")),
	])
	_check(_panel.call(&"block_size") == CONSOLE, "AC6 the console is not 1360x516")
	_check(_panel.get_node(^"%Console").position == CONSOLE_ORIGIN, "AC6 the console origin moved")
	var style := _style()
	var bays: Array = _panel.call(&"bay_rects")
	_check(bays.size() == 5, "AC6 the bay count is not five")
	for index in bays.size():
		var want := Rect2(
			CONSOLE_ORIGIN + BAND_ORIGIN + Vector2(float(index) * (BAY.x + BAY_GAP), 0.0), BAY
		)
		_check(bays[index] == want, "AC6 bay %d is %s want %s" % [index, bays[index], want])
	var band: Rect2 = style.bays_band(console)
	_check(band.size == BAND, "AC6 the band is %s" % band.size)
	var bay := Rect2(Vector2.ZERO, BAY)
	for index in 4:
		var cell: Rect2 = style.bay_cell_rect(index, bay)
		var want := Rect2(
			CELL_ORIGIN + Vector2(
				float(index % 2) * (CELL.x + CELL_GAP), float(index / 2) * (CELL.y + CELL_GAP)
			), CELL
		)
		_check(cell == want, "AC6 cell %d is %s want %s" % [index, cell, want])
	var ledge: Rect2 = style.ledge_rect(bay)
	_check(ledge == Rect2(LEDGE_ORIGIN, LEDGE), "AC6 the ledge is %s" % ledge)
	for index in style.salvo_cells:
		var drum: Rect2 = style.salvo_cell_rect(index, ledge)
		_check(
			drum == Rect2(LEDGE_ORIGIN + Vector2(float(index) * SALVO_PITCH, 1.0), SALVO_CELL),
			"AC6 salvo drum %d is %s" % [index, drum]
		)
	var wells: Array = _panel.call(&"well_rects")
	print("[r1] ac6 wells=%s" % str(wells))
	_check(wells.size() == 2, "AC6 the wells halves are not two")
	for index in wells.size():
		_check((wells[index] as Rect2).size == WELL, "AC6 well %d is %s" % [index, wells[index]])
	var well_band: Rect2 = style.wells_rect(console)
	_check(
		is_equal_approx(well_band.position.y - console.position.y, WELLS_TOP),
		"AC6 the wells band top is %.1f" % (well_band.position.y - console.position.y)
	)
	var well_size: Vector2 = (wells[0] as Rect2).size if wells.size() > 0 else Vector2.ZERO
	var item: Rect2 = style.item_rect(0, Rect2(Vector2.ZERO, well_size))
	print("[r1] ac6 item=%s item_gap=%.0f" % [str(item), style.item_gap])
	_check(item.size == ITEM, "AC6 the item box is %s" % item.size)
	_check(style.item_gap == ITEM_GAP, "AC6 the item gap moved")
	## The ink floor: no font_size override anywhere in the pane's tree, nothing under 13.
	var offenders: Array[String] = []
	_ink_offenders(_panel, offenders)
	print("[r1] ac6 ink_offenders=%d %s" % [
		offenders.size(), "none" if offenders.is_empty() else str(offenders.slice(0, 6)),
	])
	_check(offenders.is_empty(), "AC6 sub-13 px or overridden ink in the pane")


func _ink_offenders(node: Node, out: Array[String]) -> void:
	for child: Node in node.get_children():
		var control := child as Control
		if control != null:
			if control.has_theme_font_size_override(&"font_size"):
				out.append("%s override" % control.name)
			elif control is Label and control.get_theme_font_size(&"font_size") < 13:
				out.append("%s %dpx" % [control.name, control.get_theme_font_size(&"font_size")])
		_ink_offenders(child, out)


## ------------------------------------------------------------------- 6. AC5 (A4.4)

func _ac5() -> void:
	_station = StationScene.instantiate() as Control
	get_window().size = STATION_HOST
	get_tree().root.add_child(_station)
	await _settle(8)
	var title := _station.get_node(^"%InspectorTitle") as Label
	var body := _station.get_node(^"%InspectorBody") as Label
	var inspector := _station.get_node(^"%Inspector") as Control
	var host := _station.get_node(^"%ModuleHost") as Control
	var pane := (_station.get(&"_panels") as Array)[0] as CanvasItem
	print("[r1] ac5 station=%s host=%s inspector=%s tiles=%s" % [
		str(_station.size), str(host.get_global_rect()), str(inspector.get_global_rect()),
		str(pane.get_global_rect()),
	])
	print("[r1] ac5 pins title=%.1f body=%.1f min=%.1f" % [
		title.custom_minimum_size.y, body.custom_minimum_size.y,
		inspector.get_combined_minimum_size().y,
	])
	## The frame's own measured minimum for the same content, as a cross-check of the pin.
	var two: float = _shaped_min(body, "a\nb")
	var one: float = _shaped_min(body, "a")
	print("[r1] ac5 shaped one=%.1f two=%.1f title_one=%.1f" % [
		one, two, _shaped_min(title, "T"),
	])
	_check(is_equal_approx(body.custom_minimum_size.y, two), "AC5 the body pin is not two lines")
	_check(
		is_equal_approx(title.custom_minimum_size.y, _shaped_min(title, "T")),
		"AC5 the title pin is not one line"
	)
	var states: Array = [
		["", ""],
		[String(), String()],
		["LASER CELLS", "One line."],
		["LASER CELLS", "Two\nlines."],
		["LASER CELLS", "Four\nlines\nof\nhover prose."],
		["A LONG TITLE THAT WRAPS BELOW ITS OWN LINE", "wrapped\nwrapped\nwrapped"],
	]
	var heights: Array[float] = []
	var host_rects: Array[Rect2] = []
	var mins: Array[float] = []
	for state: Array in states:
		pane.inspect_requested.emit(String(state[0]), String(state[1]), false)
		await _settle(2)
		heights.append(inspector.size.y)
		host_rects.append(host.get_global_rect())
		mins.append(inspector.get_combined_minimum_size().y)
	print("[r1] ac5 heights=%s mins=%s host=%s" % [
		str(heights), str(mins), str(host_rects[0]),
	])
	for index in range(1, heights.size()):
		_check(
			is_equal_approx(heights[index], heights[0]),
			"AC5 the inspector height at state %d is %.1f not %.1f"
			% [index, heights[index], heights[0]]
		)
		_check(
			host_rects[index] == host_rects[0],
			"AC5 the ModuleHost rect at state %d is %s" % [index, host_rects[index]]
		)
		_check(
			is_equal_approx(mins[index], mins[0]),
			"AC5 the reserved minimum at state %d is %.1f" % [index, mins[index]]
		)
	var sibling := _station.get_node_or_null(^"%ModuleRail") as Control
	if sibling != null:
		print("[r1] ac5 sibling_rail=%s" % str(sibling.get_global_rect()))
	pane.inspect_requested.emit("", "", false)
	await _settle(2)
	print("[r1] ac5 cleared=%s body=%s title=%s" % [
		str(inspector.size), str(body.text), str(title.text),
	])
	## The fix's own cost, measured: with the pins cleared the block collapses (the defect)
	## and the page hands the host the difference. Restored immediately.
	var title_pin: float = title.custom_minimum_size.y
	var body_pin: float = body.custom_minimum_size.y
	title.custom_minimum_size.y = 0.0
	body.custom_minimum_size.y = 0.0
	await _settle(2)
	print("[r1] ac5 collapsed inspector=%s host=%s" % [
		str(inspector.size), str(host.get_global_rect()),
	])
	title.custom_minimum_size.y = title_pin
	body.custom_minimum_size.y = body_pin
	await _settle(2)
	print("[r1] ac5 repinned inspector=%s host=%s" % [
		str(inspector.size), str(host.get_global_rect()),
	])


func _settle(frames: int) -> void:
	for _frame in frames:
		await get_tree().process_frame


static func _shaped_min(label: Label, text: String) -> float:
	var saved := label.text
	label.text = text
	var height := label.get_minimum_size().y
	label.text = saved
	return height


## ------------------------------------------------------------------- the capture

func _capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(path)
	print("[r1] capture %s %dx%d" % [path, image.get_width(), image.get_height()])


## WCAG 2.x contrast, computed here so the floor is measured, not quoted.
func _luminance(colour: Color) -> float:
	var channels: Array[float] = [colour.r, colour.g, colour.b]
	var weights: Array[float] = [0.2126, 0.7152, 0.0722]
	var out := 0.0
	for index in 3:
		var value: float = channels[index]
		var linear: float = value / 12.92 if value <= 0.03928 else pow((value + 0.055) / 1.055, 2.4)
		out += linear * weights[index]
	return out


func _contrast(first: Color, second: Color) -> float:
	var high: float = maxf(_luminance(first), _luminance(second))
	var low: float = minf(_luminance(first), _luminance(second))
	return (high + 0.05) / (low + 0.05)
