@tool
extends McpTestSuite
## Suite s44_exchange_bulk: the EXCHANGE bulk sell (STATION_HUB section 23.7, P53) and
## T-190's check-mark ink. One row per acceptance item:
##   1. every hold row leads a CheckChip: a 24x24 flat button, bare 1 px `metal_mid`
##      frame unchecked, `metal_light` checked, the check mark code-drawn in its own
##      child rect in `text_primary` (T-190), no font glyph, no focus;
##   2. the chip toggles the bulk set while the row press keeps the single-sale arm
##      (stepper arms at one unit, the confirm strip quotes, a SELL press sells);
##   3. the YOUR HOLD caption band carries the MARK ALL / CLEAR ActionInline pair; both
##      move the whole set without rebuilding a single row (A5.5 content-swap law) and
##      both disable on an empty hold;
##   4. the marked read under the confirm strip reads `MARKED <n> STACKS — GROSS <g> ·
##      FEE <f> / YOU GET <p>`, the per-stack `Exchange.quote` sums with the shipped
##      grouped digits, and an empty set hides it;
##   5. SELL MARKED (360x56, StationButton) sits in the foot's ActionsRow between
##      SELL ALL RAW / CANCEL and SELL, the trio's seats and sizes untouched, disabled
##      at an empty set;
##   6. SELL MARKED sells every marked stack through the shipped per-stack `sell()`
##      (credits exactly the read's figures, the economy log's own seam), and the first
##      refused stack stops the run with section 5.6's wording naming it.
##
## The pane mounts the shipped scene and theme on the borrowed PlayerProfile the way
## `test_s5_ammo_cargo.gd` mounts it: `save_path` repointed at a scratch file, every
## field the suite writes handed back in `suite_teardown`, the economy log pointed at
## its own scratch file so `user://economy_log.txt` is never touched.

const PanelScene := preload("res://ui/station/exchange_panel.tscn")
const PanelScript := preload("res://ui/station/exchange_panel.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const ExchangeScript := preload("res://game/exchange.gd")
const Clock := preload("res://autoload/world_clock.gd")
const Log := preload("res://game/economy_log.gd")

const SCRATCH_PROFILE := "user://test_s44_exchange_bulk.cfg"
const SCRATCH_LOG := "user://test_s44_exchange_bulk_economy.txt"
const PROFILE_SERVICE: StringName = &"PlayerProfile"

const ORE: StringName = &"mineral_iron"
const INGOT: StringName = &"ingot_gold"
const COMP: StringName = &"comp_scrap_1"
const SEED_CARGO: Dictionary = {ORE: 24, INGOT: 6, COMP: 9}

var _profile: Node = null
var _host: Control = null
var _panel: Control = null
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_credits := 0
var _previous_cargo: Dictionary = {}
var _previous_ammo: Dictionary = {}
var _previous_ammo_rem: Dictionary = {}
var _previous_fits: Dictionary = {}
var _previous_owned: Array = []
var _previous_modules: Dictionary = {}
var _previous_market: Dictionary = {}
var _previous_log_path := ""
var _statuses: Array[Array] = []


func suite_name() -> String:
	return "s44_exchange_bulk"


func suite_setup(_ctx: Dictionary) -> void:
	_profile = _fixture_host()
	if _profile == null:
		fail_setup("the PlayerProfile autoload is the hold this suite sells")
		return
	_previous_path = String(_profile.get(&"save_path"))
	_previous_ship = StringName(_profile.call(&"active_ship"))
	_previous_credits = int(_profile.call(&"credits"))
	_previous_cargo = (_profile.get(&"_cargo") as Dictionary).duplicate(true)
	_previous_ammo = (_profile.get(&"_ammo") as Dictionary).duplicate(true)
	_previous_ammo_rem = (_profile.get(&"_ammo_rem") as Dictionary).duplicate(true)
	_previous_fits = _profile.call(&"fits")
	_previous_owned = _profile.call(&"owned_ships")
	_previous_modules = _profile.call(&"modules")
	_previous_market = (_profile.get(&"_market") as Dictionary).duplicate(true)
	_previous_log_path = Log.log_path
	_profile.set(&"save_path", SCRATCH_PROFILE)
	Log.log_path = SCRATCH_LOG
	_delete_file(SCRATCH_PROFILE)
	_delete_file(SCRATCH_LOG)


func suite_teardown() -> void:
	_free_host()
	if _profile == null:
		return
	_profile.set(&"_credits", _previous_credits)
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_cargo", _previous_cargo)
	_profile.set(&"_ammo", _previous_ammo)
	_profile.set(&"_ammo_rem", _previous_ammo_rem)
	_profile.set(&"_fits", _previous_fits)
	_profile.set(&"_owned_ships", _previous_owned)
	_profile.set(&"_modules", _previous_modules)
	_profile.set(&"_market", _previous_market)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	Log.log_path = _previous_log_path
	_delete_file(SCRATCH_PROFILE)
	_delete_file(SCRATCH_LOG)
	_profile = null


func setup() -> void:
	_free_host()
	_seed_account()


func teardown() -> void:
	_free_host()


## ------------------------------------------------------------- AC1: the CheckChip


func test_p53_every_hold_row_leads_a_check_chip() -> void:
	_seed_cargo(SEED_CARGO)
	var panel := _mount_panel()
	for item_id: StringName in [ORE, INGOT, COMP]:
		var chip := _chip_of(panel, item_id)
		assert_true(chip != null, "the %s row leads its CheckChip" % String(item_id))
		if chip == null:
			continue
		assert_eq(chip.get_index(), 0, "the chip is the row box's first child")
		assert_eq(chip.custom_minimum_size, Vector2(24.0, 24.0), "the 24x24 chip")
		assert_true(chip.toggle_mode, "the chip toggles")
		assert_eq(chip.focus_mode, Control.FOCUS_NONE, "the row stays the focus unit")
		assert_eq(String(chip.text), "", "no font-glyph check (section 5.8's finding)")
		assert_true(chip.icon == null, "and no icon glyph either")
		var mark := _mark_of(chip)
		assert_true(mark != null, "the chip carries its mark child")
		if mark == null:
			continue
		assert_eq(mark.get_parent(), chip, "the mark draws in its own child rect")
		assert_eq(mark.offset_left, 5.0, "the mark sits inside the 1 px frame")
		assert_eq(mark.anchor_right, 1.0, "anchored to the chip's own rect")
		assert_eq(mark.mouse_filter, Control.MOUSE_FILTER_IGNORE, "the chip owns the press")
		assert_eq(mark.get(&"colour"), panel.call(&"_token", &"text_primary"), "T-190's ink")
		assert_false(bool(mark.get(&"checked")), "unchecked draws no mark")
		var bare := chip.get_theme_stylebox(&"normal") as StyleBoxFlat
		assert_true(bare != null, "the unchecked chip carries its own flat box")
		if bare == null:
			continue
		assert_true(bare.draw_center == false, "a bare frame, no fill")
		assert_eq(bare.border_color, panel.call(&"_token", &"metal_mid"), "the 1 px metal_mid frame")
		## Checked: the frame steps to metal_light and the mark draws.
		chip.button_pressed = true
		var stepped := chip.get_theme_stylebox(&"normal") as StyleBoxFlat
		assert_eq(stepped.border_color, panel.call(&"_token", &"metal_light"), "the stepped frame")
		assert_true(bool(mark.get(&"checked")), "the mark draws when checked")
		chip.button_pressed = false
		var back := chip.get_theme_stylebox(&"normal") as StyleBoxFlat
		assert_eq(back.border_color, panel.call(&"_token", &"metal_mid"), "and steps back")
	_free_host()


## ------------------------------------------------- AC2: the set and the single-sale arm


func test_p53_the_chip_toggles_the_set_and_the_row_press_keeps_the_single_sale_arm() -> void:
	_seed_cargo(SEED_CARGO)
	var panel := _mount_panel()
	var chip := _chip_of(panel, ORE)
	assert_true(chip != null, "the ore row's chip built")
	if chip == null:
		return
	chip.button_pressed = true
	var marked: Dictionary = panel.get(&"_marked")
	assert_true(marked.has(ORE) and marked.size() == 1, "the chip toggled the ore stack in")
	var strip := panel.get_node_or_null(NodePath("%MarkedStrip")) as Label
	assert_true(strip != null and strip.visible, "the marked read showed")
	chip.button_pressed = false
	marked = panel.get(&"_marked")
	assert_false(marked.has(ORE), "and toggled it back out")
	assert_true(strip == null or not strip.visible, "the empty set hid the read again")
	## The row press keeps the shipped single-sale arm: the stepper arms at one unit, the
	## strip quotes the stack, and a SELL press sells exactly that.
	var row := _hold_row_or_null(panel, INGOT)
	assert_true(row != null, "the ingot row built")
	if row == null:
		return
	row.pressed.emit()
	assert_eq(StringName(panel.get(&"_selected_id")), INGOT, "the row press armed the trade column")
	assert_eq(int(panel.get(&"_sell_units")), 1, "the stepper armed at one unit (S28-A11)")
	assert_false((panel.get(&"_sell") as Button).disabled, "SELL woke")
	var confirm := panel.get_node_or_null(NodePath("%ConfirmStrip")) as Label
	assert_true(
		String(confirm.text).begins_with("SELL 1 GOLD INGOT"),
		"the confirm strip quotes the armed stack"
	)
	marked = panel.get(&"_marked")
	assert_false(marked.has(INGOT), "the row press never touched the bulk set")
	assert_false((_chip_of(panel, INGOT) as Button).button_pressed, "nor its chip")
	var before := int(_profile.call(&"credits"))
	(panel.get(&"_sell") as Button).pressed.emit()
	assert_eq(int(_profile.call(&"cargo_qty", INGOT)), 5, "the single sale sold one unit")
	assert_true(int(_profile.call(&"credits")) > before, "and paid through the shipped path")
	marked = panel.get(&"_marked")
	assert_false(marked.has(INGOT), "the sold stack is not in the set")
	_free_host()


## ------------------------------------------------------- AC3: the caption band pair


func test_p53_the_caption_band_gains_mark_all_and_clear() -> void:
	_seed_cargo(SEED_CARGO)
	var panel := _mount_panel()
	var caption := panel.get_node_or_null(NodePath("%HoldCaption")) as Label
	assert_true(caption != null, "YOUR HOLD keeps its caption")
	if caption == null:
		return
	assert_eq(String(caption.text), "YOUR HOLD", "the caption's word unchanged")
	## The band stays the hold box's leading Label (N44's caption -> scroll shape); the
	## pair rides inside the band, anchored to its right edge.
	var hold_box := panel.get_node_or_null(NodePath("ExchangeBody/HoldBox")) as VBoxContainer
	assert_true(
		hold_box != null and hold_box.get_child(0) == caption,
		"the band still leads the hold box (N44)"
	)
	assert_eq(caption.custom_minimum_size.y, 32.0, "the band seats the 32 px pair")
	var pair := caption.get_node_or_null(NodePath("CaptionPair")) as HBoxContainer
	assert_true(pair != null, "the pair rides the band")
	if pair == null:
		return
	var mark_all := panel.get_node_or_null(NodePath("%MarkAllButton")) as Button
	var clear_marks := panel.get_node_or_null(NodePath("%ClearButton")) as Button
	assert_true(mark_all != null and clear_marks != null, "the MARK ALL / CLEAR pair ships")
	if mark_all == null or clear_marks == null:
		return
	assert_eq(mark_all.custom_minimum_size, Vector2(96.0, 32.0), "the ActionInline chip size")
	assert_eq(clear_marks.custom_minimum_size, Vector2(96.0, 32.0), "and its pair's")
	assert_eq(String(mark_all.get_meta(&"chrome_class", "")), "C3", "the pair wears the chip chrome")
	var rows := panel.get_node_or_null(NodePath("%HoldRows")) as VBoxContainer
	assert_true(rows != null, "the hold stack read")
	if rows == null:
		return
	var before_children := rows.get_child_count()
	var first_row := rows.get_child(1)
	mark_all.pressed.emit()
	var marked: Dictionary = panel.get(&"_marked")
	assert_eq(marked.size(), 3, "MARK ALL marked every hold row")
	for item_id: StringName in [ORE, INGOT, COMP]:
		assert_true(
			(_chip_of(panel, item_id) as Button).button_pressed,
			"the %s chip shows the mark" % String(item_id)
		)
	assert_eq(rows.get_child_count(), before_children, "no row was rebuilt (A5.5)")
	assert_true(rows.get_child(1) == first_row, "the row stack kept its own rows (no reflow)")
	clear_marks.pressed.emit()
	marked = panel.get(&"_marked")
	assert_true(marked.is_empty(), "CLEAR emptied the set")
	for item_id: StringName in [ORE, INGOT, COMP]:
		assert_false(
			(_chip_of(panel, item_id) as Button).button_pressed,
			"the %s chip cleared" % String(item_id)
		)
	assert_eq(rows.get_child_count(), before_children, "the clear rebuilt nothing either")
	## An empty hold disables the pair (A5.4-2's unavailable idiom).
	_free_host()
	_seed_cargo({})
	panel = _mount_panel()
	mark_all = panel.get_node_or_null(NodePath("%MarkAllButton")) as Button
	clear_marks = panel.get_node_or_null(NodePath("%ClearButton")) as Button
	assert_true(mark_all != null and mark_all.disabled, "MARK ALL disables on an empty hold")
	assert_true(clear_marks != null and clear_marks.disabled, "so does CLEAR")
	_free_host()


## ------------------------------------------------------------- AC4: the marked read


func test_p53_the_marked_read_sums_the_stacks_own_quotes() -> void:
	_seed_cargo({ORE: 500, INGOT: 40})
	var panel := _mount_panel()
	var strip := panel.get_node_or_null(NodePath("%MarkedStrip")) as Label
	assert_true(strip != null, "the marked read built under the confirm strip")
	if strip == null:
		return
	assert_false(strip.visible, "an empty set hides the read")
	_mark(panel, ORE)
	_mark(panel, INGOT)
	assert_true(strip.visible, "a marked set shows the read")
	var quotes: Dictionary = panel.get(&"_marked_quotes")
	assert_eq(quotes.size(), 2, "the read quoted each marked stack")
	var gross := 0
	var fee := 0
	var paid := 0
	for item_id: StringName in [ORE, INGOT]:
		var quote: Dictionary = quotes.get(item_id, {})
		gross += int(quote.get(&"gross", 0))
		fee += int(quote.get(&"fee", 0))
		paid += int(quote.get(&"paid", 0))
	var expected := "MARKED 2 STACKS — GROSS %s · FEE %s\nYOU GET %s" % [
		_group(gross), _group(fee), _group(paid)
	]
	assert_eq(String(strip.text), expected, "the read sums the per-stack quotes, grouped")
	assert_true(gross > 999, "the fixture's figures exercise the grouped digits")
	_free_host()


## --------------------------------------------------- AC5: the foot keeps its seats


func test_p53_sell_marked_sits_between_and_the_foot_trio_keeps_its_seats() -> void:
	_seed_cargo(SEED_CARGO)
	var panel := _mount_panel()
	var row := panel.get_node_or_null(NodePath("PaneFoot/ActionsRow")) as HBoxContainer
	assert_true(row != null, "the foot's ActionsRow ships")
	if row == null:
		return
	var names: Array[String] = []
	for child: Node in row.get_children():
		names.append(String(child.name))
	assert_eq(
		names, ["SellAllButton", "CancelButton", "SellMarkedButton", "SellButton"],
		"SELL MARKED sits between SELL ALL RAW / CANCEL and SELL, nothing re-laid"
	)
	for child: Node in row.get_children():
		var button := child as Button
		assert_eq(button.custom_minimum_size, Vector2(360.0, 56.0), "%s keeps 360x56" % child.name)
		assert_eq(
			button.theme_type_variation, &"StationButton", "%s keeps the Pressables plate" % child.name
		)
	assert_eq(row.get_theme_constant("separation"), 16, "the P2 gutter unchanged")
	var sell_marked := panel.get_node_or_null(NodePath("%SellMarkedButton")) as Button
	assert_true(sell_marked != null, "SELL MARKED built")
	if sell_marked == null:
		return
	assert_true(sell_marked.disabled, "an empty set disables it (A5.4-2's idiom)")
	_mark(panel, ORE)
	assert_false(sell_marked.disabled, "a marked set wakes it")
	_free_host()


## ---------------------------------------------- AC6: the run, its stop, its log


func test_p53_sell_marked_sells_every_marked_stack_through_the_shipped_sell() -> void:
	_seed_cargo(SEED_CARGO)
	var panel := _mount_panel()
	_mark(panel, ORE)
	_mark(panel, INGOT)
	_mark(panel, COMP)
	var quotes: Dictionary = panel.get(&"_marked_quotes")
	var expected_paid := 0
	for item_id: StringName in [ORE, INGOT, COMP]:
		expected_paid += int(quotes.get(item_id, {}).get(&"paid", 0))
	var before := int(_profile.call(&"credits"))
	_delete_file(SCRATCH_LOG)
	(panel.get_node(NodePath("%SellMarkedButton")) as Button).pressed.emit()
	assert_eq(int(_profile.call(&"credits")), before + expected_paid,
		"the press paid exactly the read's summed figures")
	for item_id: StringName in [ORE, INGOT, COMP]:
		assert_eq(int(_profile.call(&"cargo_qty", item_id)), 0, "%s sold whole" % String(item_id))
	assert_eq(_statuses.size(), 1, "one confirmed action, one status line")
	if _statuses.size() == 1:
		assert_false(bool(_statuses[0][1]), "a success is not a danger line")
		assert_true(
			String(_statuses[0][0]).begins_with("SOLD MARKED · 3 STACKS · +"),
			"the run's own success wording"
		)
	assert_true(_log_has_sell(ORE), "the economy log carries the ore stack's line")
	assert_true(_log_has_sell(INGOT), "the ingot stack's line")
	assert_true(_log_has_sell(COMP), "and the component stack's line")
	_free_host()


func test_p53_a_refused_stack_stops_the_run_and_names_itself() -> void:
	_seed_cargo(SEED_CARGO)
	var panel := _mount_panel()
	_mark(panel, ORE)
	_mark(panel, INGOT)
	_mark(panel, COMP)
	## The refusal fixture: the ingot's hold empties behind the panel's back (no signal,
	## no rebuild), so the run reaches it armed and `sell()` refuses it.
	var cargo: Dictionary = {ORE: 24, COMP: 9}
	_profile.set(&"_cargo", cargo)
	var before := int(_profile.call(&"credits"))
	var iron_paid := int((panel.get(&"_marked_quotes") as Dictionary)[ORE].get(&"paid", 0))
	(panel.get_node(NodePath("%SellMarkedButton")) as Button).pressed.emit()
	assert_eq(int(_profile.call(&"cargo_qty", ORE)), 0, "the stack before the refusal sold")
	assert_eq(int(_profile.call(&"cargo_qty", COMP)), 9, "and the run stopped before the rest")
	assert_eq(int(_profile.call(&"credits")), before + iron_paid, "only the sold stack paid")
	assert_eq(_statuses.size(), 1, "one refusal line")
	if _statuses.size() == 1:
		assert_true(bool(_statuses[0][1]), "the refusal rides the danger strip (section 5.6)")
		assert_eq(
			String(_statuses[0][0]), "REFUSED · GOLD INGOT · PICK AT LEAST ONE UNIT",
			"section 5.6's wording, the stopped stack named"
		)
	var marked: Dictionary = panel.get(&"_marked")
	assert_false(marked.has(ORE), "the sold stack left the set")
	assert_true(marked.has(COMP), "the unrun stack keeps its mark")
	_free_host()


## ------------------------------------------------------------------------- helpers


func _seed_account() -> void:
	var owned: Array[StringName] = [&"ship_vanguard"]
	var packs: Dictionary = {}
	_profile.set(&"_credits", 10000)
	_profile.set(&"_active_ship", &"ship_vanguard")
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_cargo", {})
	_profile.set(&"_ammo", packs)
	_profile.set(&"_ammo_rem", {})
	_statuses.clear()


func _seed_cargo(cargo: Dictionary) -> void:
	## A fresh writable copy: a const fixture dictionary is read-only at runtime and the
	## profile's own remove_cargo would fail on it (measured in this suite's first run).
	var fresh := {}
	for key: Variant in cargo:
		fresh[key] = cargo[key]
	_profile.set(&"_cargo", fresh)


func _mount_panel() -> Control:
	if _host == null or not is_instance_valid(_host):
		_host = Control.new()
		_host.name = "S44ExchangeHost"
		_host.theme = ThemeRes
		_host.size = Vector2(1920.0, 1080.0)
		_fixture_host().add_child(_host)
	_panel = PanelScene.instantiate() as Control
	_host.add_child(_panel)
	_profile.connect(&"profile_changed", Callable(_panel, &"refresh_profile"))
	_panel.connect(&"status_requested", _on_status_requested)
	return _panel


func _free_host() -> void:
	if _panel != null and is_instance_valid(_panel):
		_panel.free()
	_panel = null
	if _host != null and is_instance_valid(_host):
		_host.free()
	_host = null


func _hold_row_or_null(panel: Control, item_id: StringName) -> Node:
	var rows := panel.get_node_or_null(NodePath("%HoldRows"))
	if rows == null:
		return null
	return rows.get_node_or_null(NodePath("Hold%s" % String(item_id).to_pascal_case()))


func _chip_of(panel: Control, item_id: StringName) -> Button:
	var row := _hold_row_or_null(panel, item_id)
	if row == null:
		return null
	return row.get_node_or_null(NodePath("RowInner/RowBox/CheckChip")) as Button


func _mark_of(chip: Button) -> Control:
	if chip == null:
		return null
	return chip.get_node_or_null(NodePath("CheckMark")) as Control


## Toggle one row's chip the way a pointer does: the property write emits `toggled`.
func _mark(panel: Control, item_id: StringName) -> void:
	var chip := _chip_of(panel, item_id)
	assert_true(chip != null, "the %s chip built" % String(item_id))
	if chip == null:
		return
	chip.button_pressed = true


func _on_status_requested(message: String, danger: bool) -> void:
	_statuses.append([message, danger])


func _log_has_sell(item_id: StringName) -> bool:
	var file := FileAccess.open(SCRATCH_LOG, FileAccess.READ)
	if file == null:
		return false
	var needle := ", SELL, %s," % String(item_id)
	while file.get_position() < file.get_length():
		if file.get_line().contains(needle):
			return true
	return false


## The shipped grouped-digits idiom (`exchange_panel._format_int`, positive ints only),
## quoted so the suite checks the read's own shape rather than re-deriving it.
func _group(value: int) -> String:
	var digits := str(value)
	var grouped := ""
	var count := 0
	for index in range(digits.length() - 1, -1, -1):
		grouped = digits[index] + grouped
		count += 1
		if count % 3 == 0 and index > 0:
			grouped = " " + grouped
	return grouped


func _fixture_host() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(NodePath(PROFILE_SERVICE))


func _delete_file(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())
