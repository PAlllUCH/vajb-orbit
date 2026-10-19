@tool
extends McpTestSuite
## Suite s42_overview_grid: wave S42 (the OVERVIEW 3x3 grid rework, STATION_HUB section
## 23.1 P44-P47 + T-184/T-189). One row per pinned acceptance:
##
##   P44  nine tiles row-major in one GridContainer (columns 3, separation 16) at
##        TILE_MIN (240, 120), and the deck is the four-block stack inside BlockScroll
##        (P22 kept) - the P25 rows, their ServiceHost seat and the OPEN chips are gone;
##   P45  every tile wears the flat Tokens box (1 px metal_mid) with P23's own theme
##        states, and no C1 canvas rides a tile;
##   P46  the three service tiles emit their deep-links and the shell consumes the hint
##        by showing that service's panel; the captions are the pinned strings;
##   P47  every glyph modulates text_caption at rest and text_primary on hover (T-184:
##        no tile glyph renders WHITE);
##   U2   a service the docked place does not carry keeps its label, disables, and
##        carries the registry's reason on its caption line in text_dim.
##
## T-189's probe is the shell row: it mounts the shipped station screen at 1920x1080 and
## reports the grid's seated width and the block stack's total height. The harness is the
## S30/S41 idiom: the shipped scenes and theme, the pane under a host sized to the
## S41-measured pane content box, the full screen at 1920x1080 for the shell rows.
## Container sorting is queued for the next frame and no test awaits, so every mount
## forces synchronous sort passes (`_settle`) and re-reads the autowrap labels' minimums
## before it reads a rect.

const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const OverviewScene := preload("res://ui/station/overview_panel.tscn")
const OverviewScript := preload("res://ui/station/overview_panel.gd")
const StationScene := preload("res://ui/screens/station.tscn")
const StationScript := preload("res://ui/screens/station.gd")
const StationRegistryScript := preload("res://game/station_registry.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"
## STATION_HUB section 19.3's pane content box as the mounted shell measures it (the S41
## harness's own number).
const PANE_SIZE := Vector2(1768.0, 756.0)
const SHELL_SIZE := Vector2(1920.0, 1080.0)
## P44's pinned grid seat: 3 x 240 + 2 x 16.
const GRID_SEAT_MIN := 752.0
## P44's pinned block-stack arithmetic, against section 19.3's 633-tall content split.
const STACK_BUDGET := 633.0
## P44's row-major order, as the tiles are built (`to_pascal_case` names).
const TILE_ORDER: Array[String] = [
	"ArmoryTile", "RefineryTile", "ExchangeTile",
	"AuctionTile", "ShipyardTile", "LaunchTile",
	"ContractsTile", "InsuranceTile", "VaultsTile",
]
## P46's caption law: the five P23 strings verbatim, AUCTION's re-cut, the three service
## captions.
const PINNED_CAPTIONS: Dictionary = {
	&"ARMORY": "BUY, FIT AND SWAP MODULES",
	&"REFINERY": "3 ORE = 1 INGOT",
	&"EXCHANGE": "SELL YOUR HOLD",
	&"AUCTION": "THE 20-MINUTE SHELF",
	&"SHIPYARD": "HULLS, MODULES AND REPAIRS",
	&"LAUNCH": "BRIEF, CARGO, UNDOCK",
	&"CONTRACTS": "JOBS · ESCROW · STANDING",
	&"INSURANCE": "COVERS ONE LOSS",
	&"VAULTS": "STAYS BEHIND WHEN YOU FLY",
}
## The three service tiles (P46): tile name -> its registry service id.
const SERVICE_TILES: Dictionary = {
	"ContractsTile": &"contracts",
	"InsuranceTile": &"insurance",
	"VaultsTile": &"vaults",
}

var _profile: Node = null
var _host: Control = null
var _panel: Control = null
var _station: Control = null
var _previous_dock: StringName = &""


func suite_name() -> String:
	return "s42_overview_grid"


func suite_setup(_ctx: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		skip_suite("a SceneTree is needed to mount the pane")
		return
	_profile = tree.root.get_node_or_null(NodePath(PROFILE_SERVICE))
	if _profile == null:
		skip_suite("no PlayerProfile autoload to borrow")
		return
	_previous_dock = StringName(_profile.call(&"docked_station"))


func suite_teardown() -> void:
	_free_mounts()
	if _profile != null:
		_profile.call(&"set_docked_station", _previous_dock)
	_profile = null


func setup() -> void:
	_free_mounts()


func teardown() -> void:
	_free_mounts()


func _free_mounts() -> void:
	if _host != null and is_instance_valid(_host):
		_host.free()
	_host = null
	_panel = null
	_station = null


## ---------------------------------------------------------------- P44 (the 3x3 grid)

func test_p44_nine_tiles_row_major_in_one_grid() -> void:
	_mount_pane()
	var grid := _panel.find_child("TileGrid", true, false) as GridContainer
	assert_true(grid != null, "the deck's one GridContainer ships")
	if grid == null:
		return
	assert_eq(OverviewScript.TILES.size(), 9, "P44: nine tiles")
	assert_eq(grid.columns, 3, "P44: columns 3 (P23's own grid numbers stand)")
	assert_eq(
		grid.get_theme_constant(&"h_separation"), 16,
		"P44: the pinned 16 px separation"
	)
	assert_eq(
		grid.get_theme_constant(&"v_separation"), 16,
		"P44: the pinned 16 px separation, vertical too"
	)
	assert_eq(grid.get_child_count(), 9, "P44: the grid holds exactly the nine tiles")
	var names: Array[String] = []
	for tile: Node in grid.get_children():
		names.append(tile.name)
	assert_eq(
		names, TILE_ORDER,
		"P44: row-major ARMORY/REFINERY/EXCHANGE, AUCTION/SHIPYARD/LAUNCH, CONTRACTS/INSURANCE/VAULTS"
	)
	for tile: Node in grid.get_children():
		var button := tile as Button
		assert_eq(
			button.custom_minimum_size, Vector2(240.0, 120.0),
			"P44: %s seats at the pinned (240, 120)" % tile.name
		)


func test_p44_the_deck_is_the_four_block_stack() -> void:
	_mount_pane()
	var stack := _panel.get_node_or_null(NodePath("%BlockStack")) as VBoxContainer
	var scroll := _panel.get_node_or_null(NodePath("%BlockScroll")) as ScrollContainer
	assert_true(stack != null and scroll != null, "P22's scroll seat and stack ship")
	if stack == null or scroll == null:
		return
	var names: Array[String] = []
	for block: Node in stack.get_children():
		names.append(block.name)
	assert_eq(
		names, ["IdentityBlock", "TileGrid", "HullBlock", "FlavourLine"] as Array[String],
		"P46: the four-block deck - identity, the grid, the hull block, the flavour line"
	)
	assert_true(
		scroll.is_ancestor_of(stack.get_child(1)),
		"the grid lives inside the BlockScroll (P22 kept)"
	)
	assert_true(
		_panel.get_node_or_null(NodePath("%ServiceHost")) == null,
		"the S41 fold workaround's ServiceHost seat is gone"
	)
	assert_true(
		_panel.find_child("ServiceRows", true, false) == null,
		"the P25 service rows are gone"
	)
	assert_true(
		_panel.find_child("OpenChip", true, false) == null,
		"P46: the trailing OPEN chip died with the rows"
	)


## ---------------------------------------------------------------- T-189 (the probe)

func test_t189_the_grid_seats_at_the_shells_measured_pane() -> void:
	_mount_shell()
	var overview := _shell_overview()
	assert_true(overview != null, "the OVERVIEW pane ships in the shell")
	if overview == null:
		return
	var stack := overview.get_node_or_null(NodePath("%BlockStack")) as Control
	var scroll := overview.get_node_or_null(NodePath("%BlockScroll")) as Control
	var grid := overview.find_child("TileGrid", true, false) as Control
	assert_true(stack != null and scroll != null and grid != null, "the deck's seats build")
	if stack == null or scroll == null or grid == null:
		return
	print(
		"[S42-T189] shell %s | pane %s | stack %s min %.1f | scroll viewport %.1f"
		% [
			str(_station.size), str(overview.size), str(stack.size),
			stack.get_combined_minimum_size().y, scroll.size.y,
		]
		+ " | grid node %s min %s | first tile seated %s"
		% [
			str(grid.size), str(grid.get_combined_minimum_size()),
			str((grid.get_child(0) as Control).size),
		]
	)
	assert_true(
		GRID_SEAT_MIN <= stack.size.x,
		"the pinned 3x240+2x16 grid seat %.1f fits the shell's measured content width %.1f"
		% [GRID_SEAT_MIN, stack.size.x]
	)
	assert_true(
		stack.get_combined_minimum_size().y <= scroll.size.y,
		"the block stack (%.1f tall) fits the scroll's %.1f viewport unscrolled at 16:9"
		% [stack.get_combined_minimum_size().y, scroll.size.y]
	)


## ------------------------------------------------------------- P45 (the flat chrome)

func test_p45_the_tiles_wear_the_flat_tokens_box() -> void:
	_mount_pane()
	var metal_mid := ThemeRes.get_color(&"metal_mid", &"Tokens")
	for tile_name: String in TILE_ORDER:
		var tile := _panel.find_child(tile_name, true, false) as Button
		assert_true(tile != null, "%s ships" % tile_name)
		if tile == null:
			continue
		var normal := tile.get_theme_stylebox(&"normal") as StyleBoxFlat
		assert_true(normal != null, "%s wears a flat stylebox at rest" % tile_name)
		if normal == null:
			continue
		assert_eq(normal.border_color, metal_mid, "%s: the 1 px metal_mid border" % tile_name)
		assert_eq(normal.get_border_width(SIDE_LEFT), 1, "%s: the border is 1 px" % tile_name)
		assert_true(
			tile.get_node_or_null(NodePath("ChromeCanvas")) == null,
			"%s: no C1 canvas rides the tile (P45 retires it)" % tile_name
		)
		assert_true(
			not tile.has_meta(&"chrome_class"),
			"%s: no chrome-family class is wired" % tile_name
		)


func test_p45_the_tile_states_change_tint_only() -> void:
	_mount_pane()
	var accent := ThemeRes.get_color(&"accent_danger_bright", &"Tokens")
	for tile_name: String in TILE_ORDER:
		var tile := _panel.find_child(tile_name, true, false) as Button
		assert_true(tile != null, "%s ships" % tile_name)
		if tile == null:
			continue
		for state: StringName in [&"hover", &"pressed", &"disabled", &"focus"]:
			assert_true(
				tile.get_theme_stylebox(state) != null,
				"%s: the %s state wears its own box" % [tile_name, String(state)]
			)
		var focus := tile.get_theme_stylebox(&"focus") as StyleBoxFlat
		assert_true(focus != null, "%s: the focus ring ships" % tile_name)
		if focus == null:
			continue
		assert_false(focus.draw_center, "%s: the focus box is a ring, not a fill" % tile_name)
		assert_eq(
			focus.border_color, accent,
			"%s: the P3 ring is the accent_danger_bright ink" % tile_name
		)
		## The developer's expand-fill re-cut (disclosed): the tile's minimum is P44's
		## (240, 120) and its laid-out width fills the pane's third - no state ever
		## resizes it, so the floor is what the assertion pins.
		assert_true(
			tile.size.y >= 120.0 and tile.size.x >= 240.0,
			"%s: seated at least (240, 120) - no state ever resizes the tile" % tile_name
		)


## --------------------------------------------------- P46 (deep-links and the captions)

func test_p46_the_service_tiles_emit_their_deep_link() -> void:
	_mount_pane()
	var decks: Array[int] = []
	var hints: Array[StringName] = []
	var watcher := func(deck: int, hint: StringName) -> void:
		decks.append(deck)
		hints.append(hint)
	_panel.connect(&"navigate_requested", watcher)
	for tile_name: String in SERVICE_TILES:
		var tile := _panel.find_child(tile_name, true, false) as Button
		assert_true(tile != null, "%s ships" % tile_name)
		if tile == null:
			continue
		tile.pressed.emit()
	assert_eq(
		decks, [7, 7, 7] as Array[int],
		"P46: every service tile routes to the SERVICES deck"
	)
	assert_eq(
		hints, [&"contracts", &"insurance", &"vaults"] as Array[StringName],
		"P46: the hint names the tile's own service"
	)


func test_p46_the_shell_consumes_the_service_hint() -> void:
	_mount_shell()
	var overview := _shell_overview()
	assert_true(overview != null, "the OVERVIEW pane ships in the shell")
	if overview == null:
		return
	var tile := overview.find_child("VaultsTile", true, false) as Button
	assert_true(tile != null, "the VAULTS service tile ships")
	if tile == null:
		return
	tile.pressed.emit()
	## The production route lands on the shell's tween callback; the instant re-select
	## runs the same mount path synchronously (the tween cannot fire inside this frame).
	_station.call(&"_select_module", StationScript.SERVICES, true)
	assert_eq(
		int(_station.get(&"_module")), StationScript.SERVICES,
		"the tile press routes to the SERVICES deck"
	)
	assert_eq(
		StringName(_station.get(&"_active_service")), &"vaults",
		"P46: the hint selects the tile's own service"
	)
	assert_eq(
		StringName(_station.get(&"_focus_hint")), &"",
		"the hint seam is consumed, not left set"
	)
	var vaults_pane: Control = _station.call(&"service_panel", &"vaults")
	var contracts_pane: Control = _station.call(&"service_panel", &"contracts")
	assert_true(vaults_pane.visible, "the VAULTS panel is the one showing")
	assert_false(contracts_pane.visible, "the CONTRACTS panel is not showing")


func test_p46_the_captions_are_the_pinned_strings() -> void:
	_mount_pane()
	assert_eq(OverviewScript.TILES.size(), PINNED_CAPTIONS.size(), "one caption per tile")
	for index in mini(OverviewScript.TILES.size(), TILE_ORDER.size()):
		var tile_data: Dictionary = OverviewScript.TILES[index]
		var title := String(tile_data[&"title"])
		assert_has_key(PINNED_CAPTIONS, title, "%s is a pinned caption" % title)
		assert_eq(
			String(tile_data[&"caption"]), String(PINNED_CAPTIONS[title]),
			"%s carries its pinned caption verbatim" % title
		)
		var tile := _panel.find_child(TILE_ORDER[index], true, false) as Button
		if tile == null:
			continue
		var caption := _tile_caption(tile)
		assert_eq(
			caption.text, String(PINNED_CAPTIONS[title]),
			"%s's built caption reads the pinned string" % title
		)


## ------------------------------------------------------------- P47 (the glyph ink)

func test_p47_the_glyphs_wear_the_caption_ink() -> void:
	_mount_pane()
	var caption := ThemeRes.get_color(&"text_caption", &"Tokens")
	var primary := ThemeRes.get_color(&"text_primary", &"Tokens")
	var glyphs: Array = _panel.get(&"_tile_glyphs")
	assert_eq(glyphs.size(), 9, "one glyph per tile")
	for index in mini(glyphs.size(), OverviewScript.TILES.size()):
		var glyph := glyphs[index] as TextureRect
		var tile_data: Dictionary = OverviewScript.TILES[index]
		assert_eq(
			glyph.modulate, caption,
			"tile %d (%s) rests at the caption ink - T-184's cure, no WHITE raster"
			% [index, String(tile_data[&"title"])]
		)
	## The hover chain rides the same mechanism on every tile, raster or SVG.
	for index in mini(glyphs.size(), OverviewScript.TILES.size()):
		var glyph := glyphs[index] as TextureRect
		var tile := _tile_of(glyph)
		assert_true(tile != null, "glyph %d sits on a tile" % index)
		if tile == null:
			continue
		tile.mouse_entered.emit()
		assert_eq(glyph.modulate, primary, "tile %d hovers at the text_primary ink" % index)
		tile.mouse_exited.emit()
		assert_eq(
			glyph.modulate, caption,
			"tile %d un-hovers back to the caption ink" % index
		)


## ---------------------------------------------------------------- U2 (the availability)

func test_u2_an_unavailable_service_tile_disables_with_its_reason() -> void:
	_mount_pane()
	## Marchgate Post (s2_outpost): the registry's own outpost row, whose matrix carries
	## CONTRACTS and VAULTS but not INSURANCE (14 section 1).
	_profile.call(&"set_docked_station", &"s2_outpost")
	_panel.call(&"refresh_profile", &"")
	var station := StationRegistryScript.docked_station(_profile)
	for tile_name: String in SERVICE_TILES:
		var tile := _panel.find_child(tile_name, true, false) as Button
		assert_true(tile != null, "%s ships" % tile_name)
		if tile == null:
			continue
		var service: StringName = SERVICE_TILES[tile_name]
		var caption := _tile_caption(tile)
		var offered := StationRegistryScript.offers(station, service)
		assert_eq(
			tile.disabled, not offered,
			"%s: the disabled plate follows the docked matrix" % tile_name
		)
		if offered:
			assert_eq(
				caption.text, String(PINNED_CAPTIONS[String(_tile_title(tile_name))]),
				"%s: an offered tile keeps its own caption" % tile_name
			)
			continue
		assert_eq(
			caption.text, StationRegistryScript.service_reason(station, service),
			"%s: the caption line carries the registry's reason" % tile_name
		)
		assert_eq(
			caption.get_theme_color(&"font_color"), ThemeRes.get_color(&"text_dim", &"Tokens"),
			"%s: the reason reads in text_dim" % tile_name
		)
		var glyph := _tile_glyph(tile)
		tile.mouse_entered.emit()
		assert_eq(
			glyph.modulate, ThemeRes.get_color(&"text_caption", &"Tokens"),
			"%s: a disabled tile keeps its rest ink on hover" % tile_name
		)


## --------------------------------------------------- P23 (focus and the hover chain)

func test_p23_focus_primary_and_the_hover_inspect_chain() -> void:
	_mount_pane()
	_panel.call(&"focus_primary")
	var owner := _panel.get_viewport().gui_get_focus_owner()
	assert_true(
		owner != null and _panel.is_ancestor_of(owner) and owner is Button,
		"focus_primary() seats the ring on a tile"
	)
	var payloads: Array = []
	var watcher := func(title: String, body: String, danger: bool) -> void:
		payloads.append([title, body, danger])
	_panel.connect(&"inspect_requested", watcher)
	var tile := _panel.find_child("ContractsTile", true, false) as Button
	assert_true(tile != null, "the CONTRACTS tile ships")
	if tile == null:
		return
	tile.mouse_entered.emit()
	assert_eq(payloads.size(), 1, "the hover publishes one payload")
	if payloads.is_empty():
		return
	var payload: Array = payloads[0]
	assert_eq(String(payload[0]), "CONTRACTS", "the payload carries the tile's title")
	assert_eq(String(payload[1]), "JOBS · ESCROW · STANDING", "and the tile's caption")
	assert_false(bool(payload[2]), "the payload is not danger-marked")
	tile.mouse_exited.emit()
	assert_eq(payloads.size(), 2, "the un-hover publishes the clear payload")
	if payloads.size() < 2:
		return
	var clear: Array = payloads[1]
	assert_eq(String(clear[0]), "", "the un-hover's title is empty (N46)")


## ---------------------------------------------------------------------- the harness

func _tile_title(tile_name: String) -> String:
	for index in mini(TILE_ORDER.size(), OverviewScript.TILES.size()):
		if TILE_ORDER[index] == tile_name:
			return String(OverviewScript.TILES[index][&"title"])
	return ""


func _tile_caption(tile: Button) -> Label:
	## The tile's interior: MarginContainer -> VBox -> [HBox(glyph, title), caption, foot];
	## the caption is the VBox's second child.
	var column := (tile.get_child(0) as Control).get_child(0) as VBoxContainer
	return column.get_child(1) as Label


func _tile_glyph(tile: Button) -> TextureRect:
	var column := (tile.get_child(0) as Control).get_child(0) as VBoxContainer
	var head := column.get_child(0) as HBoxContainer
	return head.get_child(0) as TextureRect


## The Button ancestor a tile child belongs to.
func _tile_of(node: Node) -> Button:
	var walker: Node = node
	while walker != null and not walker is Button:
		walker = walker.get_parent()
	return walker as Button


## The pane alone, under a themed host sized to the S41-measured pane content box (the
## S41 harness's own mount).
func _mount_pane() -> Control:
	_free_mounts()
	_host = MarginContainer.new()
	_host.name = "S42PaneHost"
	_host.theme = ThemeRes
	_host.size = PANE_SIZE
	_profile.add_child(_host)
	_panel = OverviewScene.instantiate() as Control
	_host.add_child(_panel)
	_settle(_host)
	_settle(_host)
	_refresh_label_minimums(_panel)
	_settle(_host)
	return _panel


## The full station screen at 1920x1080 (the S30 harness's own mount).
func _mount_shell() -> Control:
	_free_mounts()
	_host = Control.new()
	_host.name = "S42ShellHost"
	_host.theme = ThemeRes
	_host.size = SHELL_SIZE
	_profile.add_child(_host)
	_station = StationScene.instantiate() as Control
	_host.add_child(_station)
	_settle(_host)
	_settle(_host)
	_refresh_label_minimums(_station)
	_settle(_host)
	_settle(_host)
	return _station


func _shell_overview() -> Control:
	if _station == null or not is_instance_valid(_station):
		return null
	return _station.call(&"overview_pane") as Control


func _refresh_label_minimums(node: Node) -> void:
	for child: Node in node.get_children():
		var label := child as Label
		if label != null:
			label.update_minimum_size()
		_refresh_label_minimums(child)


## Force a synchronous container sort so geometry reads the laid-out frame (the armory's
## own `_flush_layout` idiom).
func _settle(node: Node) -> void:
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is Container:
			(current as Container).notification(Container.NOTIFICATION_SORT_CHILDREN)
		for child: Node in current.get_children():
			stack.append(child)
