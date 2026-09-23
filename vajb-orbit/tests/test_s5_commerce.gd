@tool
extends McpTestSuite
## Suite s5_commerce: wave S5's commerce pair (CONTRACTS section 17, STATION_HUB section
## 5.11) -- the AUCTION's family tabs are **display grouping over S3's own draw**, and the
## SHIPYARD is the **hangar**: owned hulls only, a selection that previews and writes
## nothing, and one footer commit.
##
## Two readings, one per acceptance:
##
## * **AC1** -- a mounted, seeded shelf is toured through all ten pin tabs and after every
##   step the row set is still 10 section 2.1's six hulls + ten rolled listings, every
##   rendered price / meta / tag / `WAS` line is still `Auction.hull_rows` and
##   `Auction.listing_rows`' own value for that row, the pane's built payloads are
##   unchanged, and the profile's `auction` state, its hot slot and the restock reading are
##   byte-identical to the readings taken before the tour. The tabs filter what is *shown*
##   and nothing else.
## * **AC2** -- a mounted hangar is driven through the disclosure the owner asked for: the
##   list is the owned roster, selecting a hull moves the preview and writes **nothing**
##   (no credit, no owned set, no active hull, no fit, no `profile_changed` emission), and
##   the footer button is the only call that reaches `set_active_ship` -- with a refusal
##   still writing nothing.
##
## The pane harness is `test_s3_auction.gd`'s: the shipped scene, the shipped theme, the
## shipped autoload with its `save_path` borrowed to a suite-private scratch file and handed
## back in `suite_teardown` (T-93: the owner's `user://profile.cfg` is never written). No
## test awaits: the headless runner calls each test synchronously.

const PanelScene := preload("res://ui/station/auction_panel.tscn")
const PanelScript := preload("res://ui/station/auction_panel.gd")
const ShipyardScene := preload("res://ui/station/shipyard_panel.tscn")
const ShipyardScript := preload("res://ui/station/shipyard_panel.gd")
const AuctionScript := preload("res://game/auction.gd")
const ModuleData := preload("res://game/module_catalog.gd")
const Catalog := preload("res://game/station_catalog.gd")
const FitData := preload("res://game/ship_fit.gd")
const Clock := preload("res://autoload/world_clock.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")

const PROFILE_PATH := "user://test_s5_commerce.cfg"
const PROFILE_SERVICE: StringName = &"PlayerProfile"

## The seed every shelf in this suite is drawn from, so each test reads one fixed shelf.
const SEED := 20260923

## STATION_HUB section 5.11's tab list (CONTRACTS section 17), transcribed label by label
## and slot by slot rather than read off the pane, so the pane is measured against the pin.
## `slot` is `&""` for the two tabs that are not a module family; `DRIVES` keys on
## `engine`, the catalogue's own slot word (the J0 disposition of 2026-09-23).
const PIN_TABS: Array[Dictionary] = [
	{&"id": &"hulls", &"label": "HULLS", &"slot": &""},
	{&"id": &"weapons", &"label": "WEAPONS", &"slot": &"weapons"},
	{&"id": &"drives", &"label": "DRIVES", &"slot": &"engine"},
	{&"id": &"shields", &"label": "SHIELDS", &"slot": &"shields"},
	{&"id": &"armour", &"label": "ARMOUR", &"slot": &"armour"},
	{&"id": &"power", &"label": "POWER", &"slot": &"power"},
	{&"id": &"computers", &"label": "COMPUTERS", &"slot": &"computers"},
	{&"id": &"boosters", &"label": "BOOSTERS", &"slot": &"boosters"},
	{&"id": &"utility", &"label": "UTILITY", &"slot": &"utility"},
	{&"id": &"all", &"label": "ALL", &"slot": &""},
]

## STATION_HUB section 3.1's host pane content box: x 453..1842 at 1920x1080, which is the
## width the tab strip has to live inside.
const PANE_CONTENT_WIDTH := 1390.0

## The two `STAT_ROWS` keys the hangar's comparison column is read on (CONTRACTS section 11).
const STAT_HULL: StringName = &"hull"
const STAT_CARGO: StringName = &"cargo"

var _profile: Node = null
var _host: Control = null
var _panel: Control = null
var _status: Array[String] = []
var _danger: Array[bool] = []
var _changes: Array[StringName] = []
var _previous_path := ""
var _previous_credits := 0
var _previous_owned: Array = []
var _previous_active: StringName = &""
var _previous_fits: Dictionary = {}
var _previous_modules: Dictionary = {}
var _previous_auction: Dictionary = {}
var _previous_counter := 0
var _previous_ammo: Dictionary = {}


func suite_name() -> String:
	return "s5_commerce"


func setup() -> void:
	_status.clear()
	_danger.clear()


func teardown() -> void:
	_release_host()
	if _profile != null:
		_profile.set(&"_credits", _previous_credits)
		_profile.set(&"_owned_ships", _previous_owned)
		_profile.set(&"_active_ship", _previous_active)
		_profile.set(&"_fits", _previous_fits)
		_profile.set(&"_modules", _previous_modules)
		_profile.set(&"_auction", _previous_auction)
		_profile.set(&"_instance_counter", _previous_counter)
		_profile.set(&"_ammo", _previous_ammo)
		_profile.call(&"flush")
		_profile.set(&"save_path", _previous_path)
		if _profile.is_connected(&"profile_changed", _on_profile_changed):
			_profile.disconnect(&"profile_changed", _on_profile_changed)
		_profile = null


func suite_teardown() -> void:
	_delete_file(PROFILE_PATH)


## ---------------------------------------------------------------------------
## Harnesses
## ---------------------------------------------------------------------------


## The shipped autoload, borrowed for a mount: every field this suite writes is handed back
## in `teardown`, and the store is flushed while the scratch path is still in place.
func _borrow_autoload() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "a SceneTree is needed to mount the panes")
	if tree == null:
		return null
	var profile := tree.root.get_node_or_null(NodePath(PROFILE_SERVICE))
	assert_true(profile != null, "the PlayerProfile autoload is the panes' store")
	if profile == null:
		return null
	_profile = profile
	_previous_path = String(profile.get(&"save_path"))
	_previous_credits = int(profile.call(&"credits"))
	_previous_owned = profile.call(&"owned_ships")
	_previous_active = StringName(profile.call(&"active_ship"))
	_previous_fits = profile.call(&"fits")
	_previous_modules = profile.call(&"modules")
	_previous_auction = profile.call(&"auction")
	_previous_counter = int(profile.get(&"_instance_counter"))
	_previous_ammo = profile.get(&"_ammo")
	profile.set(&"save_path", PROFILE_PATH)
	_delete_file(PROFILE_PATH)
	_changes.clear()
	if not profile.is_connected(&"profile_changed", _on_profile_changed):
		profile.connect(&"profile_changed", _on_profile_changed)
	return profile


func _on_profile_changed(key: StringName) -> void:
	_changes.append(key)


func _stream() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	return rng


## One seeded, stamped shelf: `draw_shelf`'s own draw (15 section 8's rolls read the global
## RNG, so the global seed is fixed too) with the stamp that keeps pane entry from
## redrawing it.
func _seed_shelf(profile: Node) -> Dictionary:
	seed(SEED)
	var shelf: Dictionary = AuctionScript.draw_shelf(profile, _stream())
	shelf[&"last_band"] = Clock.now()
	profile.call(&"set_auction", shelf)
	_changes.clear()
	return shelf


func _release_host() -> void:
	if _host != null and is_instance_valid(_host):
		_host.free()
	_host = null
	_panel = null


## Mounts one shipped pane scene under a 1920x1080 host carrying the shipped theme, the way
## the station shell mounts it, and wires the pane's own status channel.
func _mount(scene: PackedScene) -> Control:
	_release_host()
	var host := Control.new()
	host.name = "CommerceHost"
	host.theme = ThemeRes
	host.size = Vector2(1920.0, 1080.0)
	_fixture_host().add_child(host)
	_host = host
	_panel = scene.instantiate() as Control
	_host.add_child(_panel)
	if _panel.has_signal(&"status_requested"):
		_panel.connect(&"status_requested", _on_status)
	return _panel


func _on_status(message: String, danger: bool) -> void:
	_status.append(message)
	_danger.append(danger)


## The runner calls every test from inside its own `_ready`, so the root viewport is still
## busy adding the runner scene and `root.add_child(...)` fails. The profile autoload
## entered the tree before the main scene, so it hosts the fixtures.
func _fixture_host() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(NodePath(PROFILE_SERVICE))


func _delete_file(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


func _read_source(path: String) -> String:
	return FileAccess.get_file_as_string(path)


## The row set of one of the auction pane's three lists, in render order.
func _rows_of(panel: Control, box: String) -> Array[Button]:
	var container := panel.get_node("%" + box) as VBoxContainer
	var rows: Array[Button] = []
	if container == null:
		return rows
	for child: Node in container.get_children():
		var row := child as Button
		if row != null:
			rows.append(row)
	return rows


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


func _digits_only(text: String) -> String:
	var digits := ""
	for index in text.length():
		var glyph := text[index]
		if glyph >= "0" and glyph <= "9":
			digits += glyph
	return digits


## The block of the pane a pin tab shows: `HULLS` shows the six hull rows, `ALL` shows the
## whole shelf, and every other tab is a module family (`STATION_HUB` section 5.11's three
## groupings). Derived from the tab's id, so the pin table above stays label + slot only.
func _tab_section(tab: Dictionary) -> StringName:
	match StringName(tab[&"id"]):
		&"hulls":
			return &"hulls"
		&"all":
			return &"all"
	return &"listings"


## The grouping a tab promises, read off the shelf's own rows rather than off the pin:
## the listing ids whose slot is that tab's key, in the shelf's drawn order.
func _expected_listing_ids(tab: Dictionary, listings: Array[Dictionary]) -> Array[StringName]:
	var ids: Array[StringName] = []
	if _tab_section(tab) == &"hulls":
		return ids
	var slot := StringName(tab[&"slot"])
	for entry: Dictionary in listings:
		if slot == &"" or StringName(entry[&"slot"]) == slot:
			ids.append(entry[&"id"])
	return ids


## The hull ids shown for a tab: the whole shelf for HULLS and ALL, none for a module family.
func _expected_hull_ids(tab: Dictionary, hulls: Array[Dictionary]) -> Array[StringName]:
	var ids: Array[StringName] = []
	if _tab_section(tab) != &"listings":
		for entry: Dictionary in hulls:
			ids.append(entry[&"id"])
	return ids


## ---------------------------------------------------------------------------
## AC1 -- the AUCTION's family tabs (CONTRACTS section 17)
## ---------------------------------------------------------------------------


## The pin's ten tabs, in the pin's order, over one button each: `HULLS · WEAPONS · DRIVES ·
## SHIELDS · ARMOUR · POWER · COMPUTERS · BOOSTERS · UTILITY · ALL`, the pane opening on
## `ALL` (the flat list, section 5.11's stated reversal).
func test_the_family_tabs_are_the_pins_ten_in_the_pins_order() -> void:
	var profile := _borrow_autoload()
	assert_true(profile != null, "the autoload is the pane's store")
	if profile == null:
		return
	_seed_shelf(profile)
	var panel := _mount(PanelScene)
	var tabs: Array = panel.call(&"family_tabs")
	assert_eq(tabs.size(), PIN_TABS.size(), "ten tabs")
	for index: int in PIN_TABS.size():
		var expected: Dictionary = PIN_TABS[index]
		var actual: Dictionary = tabs[index]
		assert_eq(actual[&"id"], expected[&"id"], "tab %d is the pin's id" % index)
		assert_eq(actual[&"label"], expected[&"label"], "tab %d is the pin's label" % index)
		assert_eq(actual[&"slot"], expected[&"slot"], "tab %d groups on the pin's slot" % index)
	## `DRIVES` keys on the catalogue's own `engine` slot (the J0 disposition of 2026-09-23),
	## which is the word the shelf's listing rows carry.
	assert_eq(tabs[2][&"slot"], &"engine", "DRIVES is the engine slot, not the engines alias")
	assert_true(ModuleData.SLOT_ALIASES.has(&"engine"), "which the catalogue aliases for ShipFit")
	var strip := panel.get_node("%FamilyTabs") as HBoxContainer
	assert_eq(strip.get_child_count(), PIN_TABS.size(), "one plate per tab")
	for index: int in strip.get_child_count():
		var button := strip.get_child(index) as Button
		assert_true(button != null, "tab %d is a Button" % index)
		if button == null:
			continue
		assert_true(button.toggle_mode, "tab %d is a toggle plate" % index)
		assert_eq(
			button.get_meta(&"id", &""),
			PIN_TABS[index][&"id"],
			"tab %d carries its own id" % index
		)
		assert_eq(
			String(button.name), "Family%sTab" % String(PIN_TABS[index][&"id"]).to_pascal_case(),
			"tab %d is named for its id" % index
		)
	assert_eq(panel.call(&"family_tab"), PanelScript.TAB_ALL, "the pane opens on the flat list")
	assert_eq(panel.call(&"shown_hull_ids").size(), 6, "which shows the six hulls")
	assert_eq(panel.call(&"shown_listing_ids").size(), 10, "and the ten listings")
	## The strip has to live inside the pane's own content box (STATION_HUB section 3.1).
	var measured := strip.get_combined_minimum_size().x
	print("[S5-COMMERCE] tab strip minimum width %.1f px of %.0f px" % [measured, PANE_CONTENT_WIDTH])
	assert_true(
		measured <= PANE_CONTENT_WIDTH,
		"the ten tabs fit the pane's content box (%.1f <= %.0f)" % [measured, PANE_CONTENT_WIDTH]
	)


## AC1: the tab tour is display grouping and nothing else. After every tab the shelf is
## still 10 section 2.1's six hulls + ten rolled listings; every rendered price, meta, `WAS`
## line and F LOT tag is `Auction.hull_rows` / `Auction.listing_rows`' own value for that
## row; the pane's built payloads are unchanged; and the shelf's state, its hot slot and the
## restock reading are byte-identical to the readings taken before the tour.
func test_the_tab_tour_leaves_the_draw_prices_and_restock_byte_identical() -> void:
	var profile := _borrow_autoload()
	assert_true(profile != null, "the autoload is the pane's store")
	if profile == null:
		return
	profile.set(&"_credits", 100_000)
	profile.set(&"_modules", {})
	var shelf_before := _seed_shelf(profile)
	var hulls_before := AuctionScript.hull_rows(profile)
	var listings_before := AuctionScript.listing_rows(profile)
	assert_eq(hulls_before.size(), 6, "S3's six hull rows")
	assert_eq(listings_before.size(), 10, "and its ten listing rows")
	var hot_before := AuctionScript.hot_id(profile)
	var panel := _mount(PanelScene)
	var restock_before := String(panel.call(&"restock_text"))
	var status_before := String(panel.call(&"status_text"))
	var payloads_hulls: Array[Dictionary] = panel.call(&"hull_payloads")
	var payloads_listings: Array[Dictionary] = panel.call(&"module_payloads")
	assert_eq(payloads_hulls.size(), 6, "the pane builds the six hull rows")
	assert_eq(payloads_listings.size(), 10, "and the ten listing rows")
	for tab: Dictionary in PIN_TABS:
		var tab_id: StringName = tab[&"id"]
		panel.call(&"select_family", tab_id)
		assert_eq(panel.call(&"family_tab"), tab_id, "the pane shows %s" % String(tab_id))
		## 1. The same 6 + 10 rows are built: the rows move in and out of view, never out of
		##    the list.
		var hull_rows := _rows_of(panel, "HullRows")
		var listing_rows := _rows_of(panel, "ModuleRows")
		assert_eq(hull_rows.size(), 6, "%s keeps six hull rows" % String(tab_id))
		assert_eq(listing_rows.size(), 10, "%s keeps ten listing rows" % String(tab_id))
		## 2. The pane's built payloads are the ones it built before the tour.
		assert_eq(
			panel.call(&"hull_payloads"), payloads_hulls, "%s moves no hull payload" % String(tab_id)
		)
		assert_eq(
			panel.call(&"module_payloads"),
			payloads_listings,
			"%s moves no listing payload" % String(tab_id)
		)
		## 3. Every rendered number is S3's own arithmetic for that row.
		_assert_s3_rendering(panel, profile, tab_id)
		## 4. The shelf itself, its hot slot and the footer's reading never move.
		assert_eq(
			profile.call(&"auction"), shelf_before, "%s writes no shelf state" % String(tab_id)
		)
		assert_eq(AuctionScript.hot_id(profile), hot_before, "the hot slot is the shelf's own")
		assert_eq(
			panel.call(&"restock_text"), restock_before, "the restock reading never moves"
		)
		assert_eq(panel.call(&"status_text"), status_before, "and neither does the strip")
		assert_eq(AuctionScript.listing_ids(profile).size(), 10, "the shelf still lists ten")
	## The grouping itself: each tab shows exactly its own family, and the two non-family tabs
	## show the whole shelf. The tabs are driven through their own `pressed` -- the plate the
	## player clicks, not the pane's value setter.
	for tab: Dictionary in PIN_TABS:
		var button := panel.call(&"tab_button", tab[&"id"]) as Button
		assert_true(button != null, "%s has its own plate" % String(tab[&"id"]))
		if button == null:
			continue
		button.pressed.emit()
		assert_eq(
			panel.call(&"family_tab"), tab[&"id"], "pressing %s selects it" % String(tab[&"id"])
		)
		assert_eq(
			panel.call(&"shown_hull_ids"),
			_expected_hull_ids(tab, hulls_before),
			"%s shows the hulls the pin gives it" % String(tab[&"id"])
		)
		assert_eq(
			panel.call(&"shown_listing_ids"),
			_expected_listing_ids(tab, listings_before),
			"%s shows the listings the pin gives it" % String(tab[&"id"])
		)
		var hull_margin := panel.get_node("%HullsMargin") as Control
		assert_eq(
			hull_margin.visible,
			_tab_section(tab) != &"listings",
			"%s hides or shows the HULLS block with its own section" % String(tab[&"id"])
		)
	## The focused row follows the shown rows: a hidden row is never a focus stop (section
	## 5.10's focus order, read through section 5.11's display grouping). The tab driven here
	## is the first module family the shelf actually stocks, so the reading is never a
	## seed-dependent mismatch between "no rows" and "no focus".
	var focus_tab := _first_stocked_family(listings_before)
	assert_ne(focus_tab, &"", "the shelf stocks at least one module family")
	panel.call(&"select_family", focus_tab)
	panel.call(&"focus_primary")
	var focus := panel.get_viewport().gui_get_focus_owner() if panel.is_inside_tree() else null
	if focus != null:
		assert_true(focus.visible, "focus never lands on a hidden row")
		assert_true(
			_rows_of(panel, "ModuleRows").has(focus as Button), "and lands on a shown module row"
		)
	assert_eq(
		panel.call(&"family_tab"), focus_tab, "entering the pane keeps the player's own tab"
	)


## The first module family with at least one row on this shelf, or `&""` for a shelf that
## stocks none of them.
func _first_stocked_family(listings: Array[Dictionary]) -> StringName:
	for tab: Dictionary in PIN_TABS:
		if _tab_section(tab) != &"listings":
			continue
		if not _expected_listing_ids(tab, listings).is_empty():
			return tab[&"id"]
	return &""


## The pane's own rendering of the shelf, checked row by row against S3's readers: ids,
## prices, the hot row's `WAS` line, the F LOT tag, the meta line and the README's own
## grouped figures. Nothing here reads a literal the pin does not already carry.
func _assert_s3_rendering(panel: Control, profile: Node, tab_id: StringName) -> void:
	var hulls := AuctionScript.hull_rows(profile)
	var listings := AuctionScript.listing_rows(profile)
	var hull_rows := _rows_of(panel, "HullRows")
	var listing_rows := _rows_of(panel, "ModuleRows")
	for index in hull_rows.size():
		var entry: Dictionary = hulls[index]
		var row: Button = hull_rows[index]
		assert_eq(
			String(row.get_meta(&"id", &"")),
			String(entry[&"id"]),
			"%s: hull row %d is the shelf's own id" % [String(tab_id), index]
		)
		assert_eq(
			_digits_only(_cell_text(row, "Price")),
			str(int(entry[&"price"])),
			"%s: hull row %d charges the shelf's price" % [String(tab_id), index]
		)
		assert_eq(
			_cell_caption(row, "Price"),
			AuctionScript.HOT_CAPTION_FORMAT % _group(int(entry[&"was"]))
			if bool(entry[&"hot"])
			else PanelScript.LIST_CAPTION,
			"%s: hull row %d carries the shelf's own caption" % [String(tab_id), index]
		)
		assert_eq(
			_cell_text(row, "Action"),
			PanelScript.ACTION_BUY,
			"%s: hull row %d keeps the auction's buy door" % [String(tab_id), index]
		)
	for index in listing_rows.size():
		var entry: Dictionary = listings[index]
		var row: Button = listing_rows[index]
		assert_eq(
			String(row.get_meta(&"id", &"")),
			String(entry[&"id"]),
			"%s: listing row %d is the shelf's own id" % [String(tab_id), index]
		)
		assert_eq(
			_digits_only(_cell_text(row, "Price")),
			str(int(entry[&"price"])),
			"%s: listing row %d charges the shelf's price" % [String(tab_id), index]
		)
		assert_eq(
			_cell_caption(row, "Price"),
			AuctionScript.HOT_CAPTION_FORMAT % _group(int(entry[&"was"]))
			if bool(entry[&"hot"])
			else PanelScript.PRICE_CAPTION,
			"%s: listing row %d carries S3's price caption" % [String(tab_id), index]
		)
		var meta := row.find_child("Meta", true, false) as Label
		assert_eq(
			meta.text, String(entry[&"meta"]), "%s: listing row %d's meta" % [String(tab_id), index]
		)
		assert_eq(
			_cell_text(row, "Status"),
			AuctionScript.FACTION_LOT_TAG if bool(entry[&"faction_lot"]) else "",
			"%s: listing row %d's tag" % [String(tab_id), index]
		)
		assert_eq(
			_cell_text(row, "Action"),
			PanelScript.ACTION_BUY,
			"%s: listing row %d keeps the auction's buy door" % [String(tab_id), index]
		)
		assert_gt(int(entry[&"price"]), 0, "%s: listing row %d is priced" % [String(tab_id), index])
	for entry: Dictionary in hulls:
		assert_gt(int(entry[&"price"]), 0, "%s: every hull row is priced" % String(tab_id))


## Buying on the AUCTION is the one door for a hull (10 sections 2.1 and 6.1): the sheet's
## buy rows stay here, and a press charges the price the row showed and adds the hull.
func test_the_auction_keeps_the_hulls_buy_door() -> void:
	var profile := _borrow_autoload()
	assert_true(profile != null, "the autoload is the pane's store")
	if profile == null:
		return
	profile.set(&"_credits", 200_000)
	_seed_shelf(profile)
	var panel := _mount(PanelScene)
	var rows := _rows_of(panel, "HullRows")
	var target: Dictionary = AuctionScript.hull_rows(profile)[0]
	var before := int(profile.call(&"credits"))
	var row: Button = rows[0]
	assert_eq(String(row.get_meta(&"id", &"")), String(target[&"id"]), "the first row is the first hull")
	row.pressed.emit()
	assert_eq(
		int(profile.call(&"credits")), before - int(target[&"price"]), "the row charged its own price"
	)
	assert_true(
		bool(profile.call(&"owns_ship", target[&"id"])), "and the hull is the account's now"
	)
	assert_true(String(panel.call(&"status_text")).begins_with("PURCHASED · "), "reported as bought")


## ---------------------------------------------------------------------------
## AC2 -- the SHIPYARD is the hangar (CONTRACTS section 17)
## ---------------------------------------------------------------------------


## Section 5.11's list: one row per **owned** hull, in the catalogue's ladder order, with
## the `ACTIVE` badge on the hull the account flies and none on any other row. A hull the
## account does not own has no row at all -- the buy door is the AUCTION's.
func test_the_hangar_lists_the_owned_hulls_with_the_active_badge() -> void:
	var profile := _borrow_autoload()
	assert_true(profile != null, "the autoload is the pane's store")
	if profile == null:
		return
	## Owned in a deliberately unsorted order, so a list that echoed the roster would fail.
	profile.set(&"_credits", 200_000)
	profile.set(&"_modules", {})
	profile.set(&"_fits", {})
	_own_none(profile)
	for ship_id: StringName in [&"ship_destroyer", &"ship_fighter", &"ship_miner"]:
		assert_true(bool(profile.call(&"buy_ship", ship_id, 0)), "%s is owned" % String(ship_id))
	assert_true(bool(profile.call(&"set_active_ship", &"ship_fighter")), "the Lancer is active")
	var panel := _mount(ShipyardScene)
	var payloads: Array = panel.get(&"_payloads")
	var roster := _ladder_roster([&"ship_fighter", &"ship_miner", &"ship_destroyer"])
	assert_eq(payloads.size(), roster.size(), "one row per owned hull")
	for index: int in payloads.size():
		var payload: Dictionary = payloads[index]
		assert_eq(
			payload[&"id"], roster[index], "row %d is the ladder's own owned hull" % index
		)
		var tag := payload[&"tag"] as Label
		assert_eq(
			tag.text,
			ShipyardScript.STATE_ACTIVE if payload[&"id"] == &"ship_fighter" else "",
			"%s carries the ACTIVE badge only on the active hull" % String(payload[&"id"])
		)
	assert_eq(panel.call(&"listed_ids"), roster, "the pane lists exactly the owned roster")
	assert_true(panel.call(&"row_of", &"ship_vanguard") == null, "an unowned hull has no row")
	var name_label := panel.get_node("%PreviewName") as Label
	assert_eq(name_label.text, "Lancer", "the preview opens on the active hull")
	assert_eq(
		String(panel.get_node("%PaneSubtitle").text),
		ShipyardScript.SUBTITLE % roster.size(),
		"the subtitle counts the account's own hulls"
	)
	var action := panel.get_node("%ShipAction") as Button
	assert_eq(action.text, ShipyardScript.ACTION_IN_SERVICE, "the active hull is in service")
	assert_true(action.disabled, "so the footer has nothing to commit")


## AC2's core probe: a selection previews (side render, class stats, fit grid, footer label)
## and writes **nothing** -- no credit, no owned set, no active hull, no fit, no module, and
## not one `profile_changed` emission. The footer press is the only write, and a refusal
## writes nothing either.
func test_selecting_previews_and_writes_nothing_the_footer_is_the_sole_commit() -> void:
	var profile := _borrow_autoload()
	assert_true(profile != null, "the autoload is the pane's store")
	if profile == null:
		return
	profile.set(&"_credits", 200_000)
	profile.set(&"_modules", {})
	_own_none(profile)
	for ship_id: StringName in [&"ship_fighter", &"ship_miner"]:
		assert_true(bool(profile.call(&"buy_ship", ship_id, 0)), "%s is owned" % String(ship_id))
	assert_true(bool(profile.call(&"set_active_ship", &"ship_fighter")), "the Lancer is active")
	profile.call(&"set_fit", &"ship_miner", FitData.standard_fit(&"ship_miner"))
	var panel := _mount(ShipyardScene)
	## The five stores a selection could plausibly touch, read before the press.
	var credits_before := int(profile.call(&"credits"))
	var owned_before: Array = profile.call(&"owned_ships")
	var active_before := StringName(profile.call(&"active_ship"))
	var fits_before: Dictionary = profile.call(&"fits")
	var modules_before: Dictionary = profile.call(&"modules")
	var auction_before: Dictionary = profile.call(&"auction")
	var row := panel.call(&"row_of", &"ship_miner") as Button
	assert_true(row != null, "the owned hull has a row")
	if row == null:
		return
	_changes.clear()
	row.pressed.emit()
	## The preview moved: the selection, the side render, the stat column and the fit grid.
	assert_eq(
		StringName(panel.call(&"selected_id")), &"ship_miner", "the selection follows the row"
	)
	var name_label := panel.get_node("%PreviewName") as Label
	assert_eq(name_label.text, "Delver", "the preview names the selected hull")
	var image := panel.get_node("%PreviewImage") as TextureRect
	assert_true(image.texture != null, "the side render is drawn")
	if image.texture != null:
		assert_eq(
			image.texture.resource_path,
			String(Catalog.ship(&"ship_miner")[&"preview"]),
			"and it is the hull's own catalogue render"
		)
	var cells: Dictionary = panel.get(&"_stat_cells")
	assert_eq(
		String((cells[STAT_HULL][0] as Label).text),
		str(int(Catalog.ship(&"ship_miner")[&"hull"])),
		"the comparison's SELECTED column reads the selected hull"
	)
	assert_eq(
		String((cells[STAT_HULL][1] as Label).text),
		str(int(Catalog.ship(&"ship_fighter")[&"hull"])),
		"and its ACTIVE column the hull in service"
	)
	var grid := panel.get_node("%HardpointSlots") as GridContainer
	assert_eq(
		grid.get_child_count(),
		FitData.grid_cells(&"ship_miner").size(),
		"the fit grid is rebuilt for the selected hull"
	)
	assert_eq(
		grid.columns, FitData.grid_size(&"ship_miner").x, "with the selected hull's own columns"
	)
	assert_eq(
		String((panel.get_node("%HardpointCaption") as Label).text),
		ShipyardScript.HARDPOINT_CAPTION
		% [
			_slot_cell_count(&"ship_miner"),
			int(FitData.grid_counts(&"ship_miner").get(&"engines", 0)),
		],
		"and its own layout caption"
	)
	var action := panel.get_node("%ShipAction") as Button
	assert_eq(action.text, ShipyardScript.ACTION_SET_ACTIVE, "the footer offers the one commit")
	assert_false(action.disabled, "and it is armed for a hull that is not in service")
	## And nothing was written: no store moved and the profile never signalled.
	assert_eq(int(profile.call(&"credits")), credits_before, "the selection costs no credit")
	assert_eq(profile.call(&"owned_ships"), owned_before, "and owns nothing new")
	assert_eq(StringName(profile.call(&"active_ship")), active_before, "and activates nothing")
	assert_eq(profile.call(&"fits"), fits_before, "and fits nothing")
	assert_eq(profile.call(&"modules"), modules_before, "and banks nothing")
	assert_eq(profile.call(&"auction"), auction_before, "and touches no shelf")
	assert_eq(_changes.size(), 0, "the selection emitted no profile_changed at all")
	## The commit: one press, one write, one status line.
	_changes.clear()
	action.pressed.emit()
	assert_eq(
		StringName(profile.call(&"active_ship")), &"ship_miner", "SET ACTIVE is the commit"
	)
	var expected_changes: Array[StringName] = [&"ships"]
	assert_eq(_changes, expected_changes, "and it is exactly one ships emission")
	assert_eq(int(profile.call(&"credits")), credits_before, "committing a hull is free")
	assert_eq(profile.call(&"owned_ships"), owned_before, "and buys nothing")
	assert_eq(profile.call(&"fits"), fits_before, "and refits nothing")
	## The hangar reports through the shell's strip (`status_requested`), which is the channel
	## this suite captures, so the last emitted line is the pane's own report.
	assert_eq(_status[_status.size() - 1], "ACTIVE HULL IS NOW DELVER", "the strip names the commit")
	assert_eq(_danger[_danger.size() - 1], false, "and reports it as a success")
	assert_eq(action.text, ShipyardScript.ACTION_IN_SERVICE, "the footer closes for that hull")
	assert_true(action.disabled, "now that it is in service")
	var payloads: Array = panel.get(&"_payloads")
	for payload: Dictionary in payloads:
		var tag := payload[&"tag"] as Label
		assert_eq(
			tag.text,
			ShipyardScript.STATE_ACTIVE if payload[&"id"] == &"ship_miner" else "",
			"the badge moved to the committed hull"
		)
	## A refused commit writes nothing: the hull that is already in service is refused by the
	## profile before any store moves, so nothing is emitted at all (CONTRACTS section 17's
	## "refusals write nothing").
	_changes.clear()
	panel.call(&"_act", &"ship_miner")
	assert_eq(StringName(profile.call(&"active_ship")), &"ship_miner", "the active hull stands")
	assert_eq(_changes.size(), 0, "a refusal emits nothing")


## The retired half, measured on the files themselves: the hangar's source carries no buy
## path and the scene carries no price block, so the buy rows really did retire to the
## AUCTION (10 section 6.1).
func test_the_shipyard_carries_no_buy_path_and_no_price_block() -> void:
	var source := _read_source("res://ui/station/shipyard_panel.gd")
	for required: String in ["\"owned_ships\"", "\"set_active_ship\"", "\"fit_for\""]:
		assert_true(source.contains(required), "the hangar reaches the profile through %s" % required)
	for forbidden: String in [
		"\"buy_ship\"", "ACTION_BUY", "STATUS_BOUGHT", "\"FOR SALE\"", "\"LOCKED\"", "\"can_afford\"",
	]:
		assert_false(source.contains(forbidden), "the shipyard carries no %s" % forbidden)
	var scene_text := _read_source("res://ui/station/shipyard_panel.tscn")
	for node_name: String in ["ShipPrice", "PriceCaption"]:
		assert_false(
			scene_text.contains(node_name), "the price block retired with the buy rows (%s)" % node_name
		)
	assert_true(scene_text.contains("SET ACTIVE"), "and the footer is the sole commit")
	## The auction keeps the one hull-buying door (10 sections 2.1 and 6.1).
	var auction_source := _read_source("res://ui/station/auction_panel.gd")
	assert_true(auction_source.contains("buy_hull"), "the AUCTION is where a hull is bought")
	assert_true(auction_source.contains("FAMILY_TABS"), "and it carries the family tabs")


## The comparison column's own caption/row set is untouched by the hangar rework: the five
## pinned stat rows still read the selected and the active hull.
func test_the_comparison_rows_still_read_both_hulls() -> void:
	var profile := _borrow_autoload()
	assert_true(profile != null, "the autoload is the pane's store")
	if profile == null:
		return
	profile.set(&"_credits", 200_000)
	_own_none(profile)
	for ship_id: StringName in [&"ship_fighter", &"ship_miner"]:
		assert_true(bool(profile.call(&"buy_ship", ship_id, 0)), "%s is owned" % String(ship_id))
	assert_true(bool(profile.call(&"set_active_ship", &"ship_fighter")), "the Lancer is active")
	var panel := _mount(ShipyardScene)
	var panel_rows := panel.call(&"row_of", &"ship_miner") as Button
	assert_true(panel_rows != null, "the owned hull has a row")
	if panel_rows == null:
		return
	panel_rows.pressed.emit()
	var cells: Dictionary = panel.get(&"_stat_cells")
	## 08 section 2 + 08 section 3: cargo is the catalogue's column, `slots` the hull's own
	## grid total, and the two columns are the selected hull's and the active hull's.
	assert_eq(
		String((cells[STAT_CARGO][0] as Label).text),
		str(int(Catalog.ship(&"ship_miner")[&"cargo"])),
		"CARGO SELECTED is the selected hull's"
	)
	assert_eq(
		String((cells[STAT_CARGO][1] as Label).text),
		str(int(Catalog.ship(&"ship_fighter")[&"cargo"])),
		"CARGO ACTIVE is the active hull's"
	)
	assert_eq(
		String((cells[&"slots"][0] as Label).text),
		str(_slot_cell_count(&"ship_miner")),
		"SLOT CELLS SELECTED is the selected hull's grid total"
	)


## An empty owned set, typed the way the profile's own field is.
func _own_none(profile: Node) -> void:
	var none: Array[StringName] = []
	profile.set(&"_owned_ships", none)


## The owned set in `StationCatalog.SHIPS`' ladder order.
func _ladder_roster(owned: Array) -> Array[StringName]:
	var roster: Array[StringName] = []
	for ship: Dictionary in Catalog.SHIPS:
		var ship_id: StringName = ship.get(&"id", &"")
		if owned.has(ship_id):
			roster.append(ship_id)
	return roster


## How many non-gap cells a hull carries (08 section 3's Total, through `ShipFit`).
func _slot_cell_count(hull_id: StringName) -> int:
	var total := 0
	for count: Variant in FitData.grid_counts(hull_id).values():
		total += int(count)
	return total


## The pane's own `_format_int` grouping, mirrored so a rendered number and the arithmetic
## behind it can be compared without the thousands space in the way.
func _group(value: int) -> String:
	var digits := str(absi(value))
	var grouped := ""
	var count := 0
	for index in range(digits.length() - 1, -1, -1):
		grouped = digits[index] + grouped
		count += 1
		if count % 3 == 0 and index > 0:
			grouped = " " + grouped
	return ("-" if value < 0 else "") + grouped
