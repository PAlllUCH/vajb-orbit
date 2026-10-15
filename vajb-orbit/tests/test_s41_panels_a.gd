@tool
extends McpTestSuite
## Suite s41_panels_a: wave S41 (the composition pass), the three list decks - OVERVIEW,
## EXCHANGE and AUCTION - implementing the D23-R1 design audit. One load-bearing row per
## finding, plus the layout assertion A4:
##
##   F1  the OVERVIEW pane's three service rows (CONTRACTS / INSURANCE / VAULTS) sit inside
##       the pane's content box unscrolled, the identity block carries one text line, and
##       the services block lives outside `BlockScroll`;
##   F6  the EXCHANGE SALE column's readout is centred by a slack owner on each side, so the
##       column no longer ends in dead backdrop;
##   F8  every AUCTION shelf caption and column band sits in fixed chrome above the scroll,
##       so the fold can only ever cut rows, never a header, and that chrome carries the
##       topmost section still showing rows so no legend stacks above them.
##
## The harness is the S40 suite's: the shipped scene and theme under a host sized to
## STATION_HUB section 19.3's measured pane content box (1768 x 756 at 1920x1080 - the
## shell's own reading). Container sorting is queued for the next frame and no test awaits,
## so every mount forces one synchronous sort pass (`_settle`, the armory's `_flush_layout`
## idiom) before it reads a rect. Every shipped number is read off the built tree, never
## re-declared here; the one literal is the pane size the shell hands a pane.

const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const OverviewScene := preload("res://ui/station/overview_panel.tscn")
const ExchangeScene := preload("res://ui/station/exchange_panel.tscn")
const AuctionScene := preload("res://ui/station/auction_panel.tscn")
const AuctionScript := preload("res://game/auction.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"
## F8's staged shelf: the seed every draw in `_stage_full_shelf` is fixed to, so the row's
## scroll geometry is repeatable (the harness is `test_s3_auction.gd`'s own).
const SHELF_SEED := 20261011
## STATION_HUB section 19.3's pane content box, as the mounted shell measures it.
const PANE_SIZE := Vector2(1768.0, 756.0)
## F1's one-line identity block: the faction glyph (48) + the block's 8/8 margins + the
## 1 px border. A second text line puts it back over 70.
const IDENTITY_ONE_LINE_MAX := 70.0
## The AUCTION shelf sections: `[caption, band, the section's own scroll]`.
const SHELF_SECTIONS: Array[Array] = [
	["HullsCaption", "HullsHeader", "AuctionScroll"],
	["ModulesCaption", "ModulesHeader", "ModuleScroll"],
	["SellCaption", "SellHeader", "SellScroll"],
]
## F8's fixed chrome blocks, one per shelf section, in the order the sections' rows stack in
## `AuctionBody` (so the first one is the section the shelf shows at the top of the scroll).
const SHELF_CHROME: Array[String] = ["HullsMargin", "ModulesMargin", "SellMargin"]
const EXPAND_FILL := Control.SIZE_EXPAND_FILL

var _profile: Node = null
var _host: Control = null
var _panel: Control = null


func suite_name() -> String:
	return "s41_panels_a"


func setup() -> void:
	_profile = (Engine.get_main_loop() as SceneTree).root.get_node_or_null(
		NodePath(PROFILE_SERVICE)
	)


func teardown() -> void:
	if _host != null and is_instance_valid(_host):
		_host.free()
	_host = null
	_panel = null


## ------------------------------------------------------------------ F1 (OVERVIEW, A4)

## S42 (STATION_HUB section 23.1 P44/P46) re-cut: the three service rows are retired into
## the 3x3 grid, so the fold law they proved is now proven by the deck itself - the whole
## block stack fits its scroll viewport unscrolled at 16:9, every tile inside the pane.
func test_f1_the_three_service_rows_sit_inside_the_pane_unscrolled() -> void:
	_mount(OverviewScene)
	var pane := _panel.get_global_rect()
	var scroll := _panel.get_node_or_null(NodePath("%BlockScroll")) as Control
	assert_true(scroll != null, "the OVERVIEW block scroll is built")
	if scroll == null:
		return
	assert_eq(scroll.scroll_vertical, 0, "the assertion reads the deck unscrolled")
	var stack := _panel.get_node_or_null(NodePath("%BlockStack")) as Control
	assert_true(stack != null, "the block stack is built")
	if stack == null:
		return
	assert_true(
		stack.size.y <= scroll.size.y + 0.5,
		(
			"the block stack (%.1f tall) fits the scroll viewport (%.1f) unscrolled - P44's 620/633 arithmetic"
			% [stack.size.y, scroll.size.y]
		)
	)
	for tile_name: String in ["ArmoryTile", "RefineryTile", "ContractsTile", "VaultsTile"]:
		var tile := _panel.find_child(tile_name, true, false) as Control
		assert_true(tile != null, "%s is built" % tile_name)
		if tile == null:
			continue
		var bottom := tile.global_position.y + tile.size.y
		assert_true(
			bottom <= pane.end.y and tile.global_position.y >= pane.position.y,
			(
				"%s spans y %.1f..%.1f, inside the pane's content box %.1f..%.1f (unscrolled)"
				% [tile_name, tile.global_position.y, bottom, pane.position.y, pane.end.y]
			)
		)


func test_f1_the_identity_block_carries_one_line() -> void:
	_mount(OverviewScene)
	var plate := _panel.find_child("IdentityBlock", true, false) as Control
	assert_true(plate != null, "the identity plate is built")
	if plate == null:
		return
	var height := plate.get_combined_minimum_size().y
	assert_true(
		height <= IDENTITY_ONE_LINE_MAX,
		(
			"the identity block measures %.1f tall (<= %.1f): the shell header's character"
			% [height, IDENTITY_ONE_LINE_MAX]
			+ " line is not repeated in the pane"
		)
	)


## ------------------------------------------------------------------ F6 (EXCHANGE SALE)

func test_f6_the_sale_readout_is_centred_by_equal_slack_owners() -> void:
	_mount(ExchangeScene)
	var strip := _panel.get_node_or_null(NodePath("%ConfirmStrip")) as Control
	assert_true(strip != null, "the SALE readout is built")
	if strip == null:
		return
	var box := strip.get_parent() as Control
	assert_true(box != null, "the readout has a column to centre in")
	if box == null:
		return
	var above := _slack_sibling(box, strip, -1)
	var below := _slack_sibling(box, strip, 1)
	assert_true(
		above != null and below != null,
		"the SALE column carries a slack owner above and below the readout"
	)
	if above == null or below == null:
		return
	assert_true(
		above.size.y > 0.0 and below.size.y > 0.0,
		"both slack owners hold real space (%.1f / %.1f)" % [above.size.y, below.size.y]
	)
	assert_true(
		absf(above.size.y - below.size.y) <= 1.0,
		"the readout is centred: %.1f above, %.1f below" % [above.size.y, below.size.y]
	)
	assert_true(
		strip.global_position.y + strip.size.y * 0.5 > box.global_position.y + box.size.y * 0.5,
		"and it sits in the column's lower half, where the dead backdrop was"
	)


## -------------------------------------------------------------------- F8 (AUCTION shelf)

func test_f8_every_shelf_caption_and_band_is_fixed_chrome() -> void:
	_mount(AuctionScene)
	var scroll := _panel.get_node_or_null(NodePath("%AuctionScroll")) as Control
	assert_true(scroll != null, "the shelf scroll is built")
	if scroll == null:
		return
	for section: Array in SHELF_SECTIONS:
		for node_name: String in [String(section[0]), String(section[1])]:
			var chrome := _panel.find_child(node_name, true, false) as Control
			assert_true(chrome != null, "%s is built" % node_name)
			if chrome == null:
				continue
			assert_false(
				_inside_scroll(chrome),
				"%s lives outside every scroll, so the fold can only cut rows" % node_name
			)
			assert_true(
				chrome.global_position.y + chrome.size.y <= scroll.global_position.y + 1.0,
				"%s sits above the shelf rows (%.1f <= %.1f)" % [
					node_name,
					chrome.global_position.y + chrome.size.y,
					scroll.global_position.y,
				]
			)


func test_f8_the_all_tab_leaves_no_header_for_the_fold_to_cut() -> void:
	_mount(AuctionScene)
	_panel.call(&"select_family", &"all")
	_settle(_panel)
	var scroll := _panel.get_node_or_null(NodePath("%AuctionScroll")) as Control
	assert_true(scroll != null, "the shelf scroll is built")
	if scroll == null:
		return
	## The scroll's body carries rows and nothing else: a header can never be its last
	## visible item, whatever the fold does.
	var body := _panel.get_node_or_null(NodePath("%AuctionBody")) as Control
	assert_true(body != null, "the shelf body is built")
	if body == null:
		return
	var row_hosts: Array[String] = ["HullRows", "ModuleRows", "SellRows", "ScrollTail"]
	for child: Node in body.get_children():
		assert_true(
			row_hosts.has(child.name),
			"the shelf body holds rows and V3's tail only (%s is not a header)" % child.name
		)
	for section: Array in SHELF_SECTIONS:
		var chrome := _panel.find_child(String(section[0]), true, false) as Control
		assert_true(chrome != null, "%s is built" % String(section[0]))
	## F8 (S41-B5): the chrome carries one section at a time - the topmost one that shows rows
	## - so with ALL selected exactly the HULLS block sits above the rows.
	for block_name: String in SHELF_CHROME:
		assert_true(
			_panel.find_child(block_name, true, false) != null, "%s is built" % block_name
		)
	assert_eq(
		_visible_chrome(),
		["HullsMargin"],
		"ALL selected leaves the topmost section's own chrome above the rows, no legend"
	)


## F8 (S41-B5): the chrome follows the topmost section that is showing rows, so a band always
## sits over the rows it labels - on a filtered tab, on the entry tab, and as the shelf moves.
func test_f8_the_chrome_follows_the_visible_section() -> void:
	## A full shelf, so the pane's body is taller than the pane and its scroll can move: the
	## last assertion below is the chrome's own scroll pass. The shelf is handed back at the
	## foot of this row, so no other row in the suite sees a staged shelf.
	var previous := _stage_full_shelf()
	_mount(AuctionScene)
	## A filtered tab shows one section, so the chrome is that section's own block.
	_select_family(&"hulls")
	assert_eq(_visible_chrome(), ["HullsMargin"], "the HULLS tab shows the HULLS chrome")
	_select_family(&"weapons")
	var shown := _visible_chrome()
	assert_eq(
		shown,
		["ModulesMargin"],
		"a module tab shows the MODULES chrome (got %s)" % str(shown)
	)
	## The entry tab shows all three sections at once, so the chrome is the topmost one - the
	## body's first row host - and no legend stacks above the rows.
	_select_family(&"all")
	assert_eq(_visible_chrome(), ["HullsMargin"], "ALL shows the topmost section's chrome")
	## And it follows the scroll: past the hull rows the module section owns the visible top,
	## so the MODULES band takes over the chrome.
	var scroll := _panel.get_node_or_null(NodePath("%AuctionScroll")) as ScrollContainer
	var hulls := _panel.get_node_or_null(NodePath("%HullRows")) as Control
	assert_true(scroll != null and hulls != null, "the shelf scroll and its hull rows are built")
	if scroll != null and hulls != null:
		scroll.scroll_vertical = int(hulls.position.y + hulls.size.y + 1.0)
		_settle(_panel)
		assert_eq(
			_visible_chrome(),
			["ModulesMargin"],
			"scrolled past the hull rows the chrome follows to the module section"
		)
	_restore_shelf(previous)


## ------------------------------------------------------------------------------ helpers

## Stage the shelf this suite's fixture lacks (a bare autoload lists nothing, so the pane's
## body is shorter than the pane and its own scroll never moves): `test_s3_auction.gd`'s
## harness - the passed stream fixes the hull, tier and hot draws, the global seed the rarity
## and affix rolls `roll_listing` reads. Returns what the row hands back at its foot.
func _stage_full_shelf() -> Dictionary:
	var previous := {
		&"auction": _profile.call(&"auction"),
		&"counter": int(_profile.get(&"_instance_counter")),
	}
	seed(SHELF_SEED)
	_profile.call(&"set_auction", AuctionScript.draw_shelf(_profile, _shelf_stream()))
	return previous


## Put the borrowed profile's shelf and instance counter back exactly as they were (the mint
## above spends ids), the way `test_s3_auction.gd` hands its borrow back.
func _restore_shelf(previous: Dictionary) -> void:
	_profile.set(&"_auction", previous.get(&"auction", {}))
	_profile.set(&"_instance_counter", int(previous.get(&"counter", 0)))


func _shelf_stream() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = SHELF_SEED
	return rng


## Press a family tab the way the player does, then lay the pane out before reading a rect.
func _select_family(tab_id: StringName) -> void:
	_panel.call(&"select_family", tab_id)
	_settle(_panel)


## The shelf chrome blocks that are showing, in body order. Exactly one is expected: the
## topmost section still showing rows.
func _visible_chrome() -> Array[String]:
	var shown: Array[String] = []
	for block_name: String in SHELF_CHROME:
		var block := _panel.find_child(block_name, true, false) as Control
		if block != null and block.visible:
			shown.append(block_name)
	return shown


func _mount(scene: PackedScene) -> Control:
	if _host != null and is_instance_valid(_host):
		_host.free()
	## The host is a `MarginContainer` (margin 0): a plain `Control` parent lets a pane grow
	## to its own minimum (the SALE readout's autowrap minimum alone is taller than the
	## pane), while the shell hands every pane the host's rect. Two sort passes: the first
	## gives the autowrap labels their real width, the second re-sorts with the corrected
	## minimums.
	_host = MarginContainer.new()
	_host.name = "S41PanelsHost"
	_host.theme = ThemeRes
	_host.size = PANE_SIZE
	_profile.add_child(_host)
	_panel = scene.instantiate() as Control
	_host.add_child(_panel)
	_settle(_host)
	_settle(_host)
	_refresh_label_minimums(_panel)
	_settle(_host)
	return _panel


## An autowrap `Label`'s minimum height is read off its own width, which a container only
## hands it during a sort pass, so a synchronous layout settles it one pass late. Re-reading
## each label's minimum after the first pass lets the last pass sort on the real figures.
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


## The nearest sibling of `node` in `direction` (-1 above, +1 below) that owns the column's
## slack, or null.
func _slack_sibling(box: Control, node: Control, direction: int) -> Control:
	var children := box.get_children()
	var index := children.find(node)
	if index < 0:
		return null
	var walker := index + direction
	while walker >= 0 and walker < children.size():
		var candidate := children[walker] as Control
		if candidate != null and candidate.size_flags_vertical == EXPAND_FILL:
			return candidate
		walker += direction
	return null


## Whether any ScrollContainer in the tree owns `node`.
func _inside_scroll(node: Control) -> bool:
	var walker := node.get_parent()
	while walker != null:
		if walker is ScrollContainer:
			return true
		walker = walker.get_parent()
	return false
