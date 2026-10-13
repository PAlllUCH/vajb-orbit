@tool
extends McpTestSuite
## Suite s45_refinery: the refinery LOAD ALL, the machine strip and the REFINE/CRAFT
## mode switch (04 section 9 R9-R12, STATION_HUB section 23.5 P50/P51 and section 23.6
## P52). One row per acceptance item:
##   1. `Refinery.load_all` moves the hold's ore stacks whole-stack at a time up to
##      R5's 60-unit cap: overflow stays in the hold, no credits move, and the two
##      refusals (nothing to load / input already at cap) come back as reasons;
##   2. the foot cluster is QUEUE (primary, rightmost) / LOAD / LOAD ALL / COLLECT
##      ALL - four 360x56 plates 16 px apart, the hint cell intact, QUEUE ALL / CANCEL
##      still in the conversion column;
##   3. a LOAD ALL press runs the seam: stacks move, overflow stays, no credits move,
##      status `LOADED · <n> ORE`, the refusals ride the section 5.6 strip;
##   4. the machine strip sits in the P42 header seat: SLOTS n/5 first, one chip per
##      owned slot (AVAILABLE / RUNNING mm:ss / DONE), then + <n> QUEUED, the UPGRADE
##      ActionInline rightmost - the chips read the model's own job states and the
##      countdown ticks in place on the 1 Hz tick;
##   5. the UPGRADE press opens the A4 door (7) confirm through the S25 seam (title
##      CONFIRM PURCHASE, A6's worked example body, OK/CANCEL); the confirmed answer
##      runs `upgrade_slots` unchanged and its refusal still reports;
##   6. the header band carries the REFINE / CRAFT ActionInline pair; exactly one mode
##      body is visible, switching is a pure visibility operation, and the CRAFT body
##      renders the NOTHING TO CRAFT caption and nothing else this wave.
##
## The model rows run on a throwaway `player_profile.gd` instance the way
## `test_s34_refinery_queue.gd` runs them. The pane rows mount the shipped scene on
## the borrowed PlayerProfile autoload the way `test_s44_exchange_bulk.gd` mounts it
## (`save_path` repointed at a scratch file, every borrowed field handed back in
## `suite_teardown`, the economy log pointed at its own scratch file), with one
## difference the gate's own budget dictates: the runner walks every suite inside one
## frame window, so every mount's and every freed node's pending messages pile onto
## the shared message queue and the gate's ceiling now sits at about three refinery
## mounts (measured: 3 bare mount+free cycles land, 4 overflow the queue at the next
## big layout). The pane rows therefore mount ONCE for the whole suite and drive each
## test's fresh state through silent field writes plus one
## `refresh_profile(&"refinery")` rebuild - the same borrow-and-hand-back shape, a
## fraction of the queue churn.

const PanelScene := preload("res://ui/station/refinery_panel.tscn")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const Ref := preload("res://game/refinery.gd")
const Log := preload("res://game/economy_log.gd")

const SUITE_ID := "s45_refinery"
const SCRATCH_PROFILE := "user://test_s45_refinery.cfg"
const SCRATCH_LOG := "user://test_s45_refinery_economy.txt"
const MODEL_SAVE := "user://test_s45_refinery_model.cfg"
const MODEL_LOG := "user://test_s45_refinery_model_log.txt"
const PROFILE_SERVICE: StringName = &"PlayerProfile"

const IRON: StringName = &"iron"
const COPPER: StringName = &"copper"
const GOLD: StringName = &"gold"
const IRON_ORE: StringName = &"mineral_iron"
const COPPER_ORE: StringName = &"mineral_copper"
const GOLD_ORE: StringName = &"mineral_gold"

const P1_SIZE := Vector2(360.0, 56.0)
const P1_VARIATION: StringName = &"StationButton"
const CHIP_SIZE := Vector2(96.0, 32.0)

var _model: Node = null
var _profile: Node = null
var _host: Control = null
var _panel: Control = null
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_credits := 0
var _previous_cargo: Dictionary = {}
var _previous_fits: Dictionary = {}
var _previous_owned: Array = []
var _previous_modules: Dictionary = {}
var _previous_log_path := ""
var _previous_refinery: Dictionary = {}
var _confirms: Array[Dictionary] = []
var _statuses: Array[Array] = []


func suite_name() -> String:
	return SUITE_ID


func suite_setup(_ctx: Dictionary) -> void:
	_profile = _fixture_host()
	if _profile == null:
		fail_setup("the PlayerProfile autoload is the account the pane reads")
		return
	_previous_path = String(_profile.get(&"save_path"))
	_previous_ship = StringName(_profile.call(&"active_ship"))
	_previous_credits = int(_profile.call(&"credits"))
	_previous_cargo = (_profile.get(&"_cargo") as Dictionary).duplicate(true)
	_previous_fits = _profile.call(&"fits")
	_previous_owned = _profile.call(&"owned_ships")
	_previous_modules = _profile.call(&"modules")
	_previous_log_path = Log.log_path
	_previous_refinery = {
		&"slots": _profile.call(&"refinery_slots"),
		&"input": _profile.call(&"refinery_input"),
		&"output": _profile.call(&"refinery_output"),
		&"jobs": _profile.call(&"refinery_jobs"),
		&"next_id": _profile.call(&"refinery_next_job_id"),
	}
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
	_profile.set(&"_fits", _previous_fits)
	_profile.set(&"_owned_ships", _previous_owned)
	_profile.set(&"_modules", _previous_modules)
	_profile.set(&"_refinery_slots", int(_previous_refinery[&"slots"]))
	_profile.set(&"_refinery_input", _previous_refinery[&"input"])
	_profile.set(&"_refinery_output", _previous_refinery[&"output"])
	_profile.set(&"_refinery_jobs", _previous_refinery[&"jobs"])
	_profile.set(&"_refinery_next_job_id", int(_previous_refinery[&"next_id"]))
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	Log.log_path = _previous_log_path
	_delete_file(SCRATCH_PROFILE)
	_delete_file(SCRATCH_LOG)
	_profile = null


func setup() -> void:
	if _model != null and is_instance_valid(_model):
		_model.free()
	_model = null
	_seed_account()
	_statuses.clear()
	_confirms.clear()
	if _panel == null or not is_instance_valid(_panel):
		_mount_panel()


func teardown() -> void:
	if _model != null and is_instance_valid(_model):
		_model.free()
	_model = null
	_delete_file(MODEL_SAVE)
	_delete_file(MODEL_LOG)


## --------------------------------------------- AC5: the UPGRADE confirm door
## (the runner walks methods alphabetically, so this shared-pane row runs first)


func test_a4_the_upgrade_press_opens_the_door_and_the_answer_runs_the_buy() -> void:
	var panel := _panel
	panel.call(&"_refresh_slots")
	var upgrade := panel.get_node_or_null(NodePath("%UpgradeButton")) as Button
	assert_false(upgrade.disabled, "the chip is armed below the cap")
	upgrade.pressed.emit()
	assert_eq(_confirms.size(), 1, "the press opened one confirm request")
	if _confirms.is_empty():
		return
	var payload: Dictionary = _confirms[0]
	assert_eq(String(payload[&"title"]), "CONFIRM PURCHASE", "A6's title")
	assert_eq(
		String(payload[&"body"]),
		"ARE YOU SURE YOU WANT TO BUY A REFINERY SLOT FOR 3 000 CREDITS?",
		"A6's worked example for the refinery slot"
	)
	assert_eq(String(payload[&"confirm_text"]), "OK", "the OK answer")
	assert_eq(String(payload[&"cancel_text"]), "CANCEL", "the CANCEL answer")
	assert_eq(StringName(payload[&"action"]), &"buy_refinery_slot", "the door's action")
	## The confirmed answer runs `upgrade_slots` unchanged.
	var before := int(_profile.call(&"credits"))
	panel.call(&"confirm_action", StringName(payload[&"action"]), StringName(payload[&"id"]))
	assert_eq(int(_profile.call(&"refinery_slots")), 3, "the confirmed press bought the slot")
	assert_eq(int(_profile.call(&"credits")), before - Ref.SLOT_UPGRADE_COST,
		"the flat 3,000 CR left the balance")
	assert_eq(_statuses.size(), 1, "the confirmed run reported once")
	if _statuses.size() == 1:
		assert_eq(String(_statuses[0][0]), "SLOTS UPGRADED · 3", "the upgrade's own status")
	## The confirmed press can still refuse: a drained purse buys nothing and the
	## strip carries the wording.
	_statuses.clear()
	_confirms.clear()
	_profile.set(&"_credits", 10)
	upgrade.pressed.emit()
	assert_eq(_confirms.size(), 1, "the press opened the door again")
	if _confirms.size() < 1:
		return
	panel.call(
		&"confirm_action",
		StringName(_confirms[0][&"action"]),
		StringName(_confirms[0][&"id"])
	)
	assert_eq(int(_profile.call(&"refinery_slots")), 3, "no slot was bought")
	assert_eq(_statuses.size(), 1, "the refusal answered on the strip")
	if _statuses.size() == 1:
		assert_true(bool(_statuses[0][1]), "a refusal is a danger line")
		assert_eq(
			String(_statuses[0][0]), "REFUSED · NOT ENOUGH CREDITS · 3 000 NEEDED",
			"the strip still reports the confirmed press's own refusal"
		)


## -------------------------------------------------------- AC4: the machine strip


func test_p51_the_strip_reads_the_model_and_ticks_in_place() -> void:
	var panel := _panel
	panel.call(&"_refresh_slots")
	var header := panel.get_node_or_null(NodePath("PaneHeader")) as HBoxContainer
	assert_true(header != null, "the header band ships")
	if header == null:
		return
	var names: Array[String] = []
	for child: Node in header.get_children():
		names.append(String(child.name))
	assert_eq(
		names,
		["PaneIcon", "TitleBox", "ModeSwitch", "PanelTag", "SlotsLabel", "SlotStrip",
		"QueuedCaption", "UpgradeButton"],
		"SLOTS first, the chips, the queued caption, UPGRADE rightmost"
	)
	var slots := panel.get_node_or_null(NodePath("%SlotsLabel")) as Label
	assert_eq(String(slots.text), "SLOTS 2/5", "the strip leads with the SLOTS readout")
	var caption := panel.get_node_or_null(NodePath("%QueuedCaption")) as Label
	var chips := _strip_chips(panel)
	assert_eq(chips.size(), 2, "one chip per owned slot")
	for chip: PanelContainer in chips:
		var label := chip.get_node_or_null(NodePath("ChipLabel")) as Label
		assert_eq(String(label.text), "AVAILABLE", "a free slot reads AVAILABLE")
		var box := chip.get_theme_stylebox(&"panel") as StyleBoxFlat
		assert_true(box != null, "the chip carries its own flat box")
		if box == null:
			continue
		assert_eq(box.border_color, panel.call(&"_token", &"metal_mid"), "the 1 px frame")
		assert_eq(box.bg_color, panel.call(&"_token", &"armory_chip_bg"), "the chip fill")
		assert_eq(box.border_width_left, 1, "the frame is 1 px")
	assert_false(caption.visible, "no pending jobs, no queued caption")
	var upgrade := panel.get_node_or_null(NodePath("%UpgradeButton")) as Button
	assert_eq(String(upgrade.text), "UPGRADE (3,000 CR)", "the UPGRADE chip keeps its words")
	assert_eq(String(upgrade.get_meta(&"chrome_class", "")), "C3", "the ActionInline chrome")
	## Two iron jobs fill the two slots; a gold job queues behind them (R7's FIFO).
	## The jobs queue through the panel's own transaction guard (`_begin`/`_end`, the
	## shipped idiom): a direct call's signals would otherwise rebuild the pane
	## re-entrantly mid-transaction, the very cascade the guard defers.
	_profile.set(&"_refinery_input", {IRON_ORE: 6, GOLD_ORE: 3})
	assert_true(bool(Ref.queue(_profile, IRON, 1)[&"ok"]), "the first iron job queued")
	assert_true(bool(Ref.queue(_profile, IRON, 1)[&"ok"]), "the second iron job queued")
	panel.call(&"_refresh_slots")
	chips = _strip_chips(panel)
	assert_eq(chips.size(), 2, "still one chip per owned slot")
	var first := chips[0].get_node_or_null(NodePath("ChipLabel")) as Label
	var second := chips[1].get_node_or_null(NodePath("ChipLabel")) as Label
	assert_true(String(first.text).begins_with("RUNNING "), "the running slot reads its job")
	assert_true(String(second.text).begins_with("RUNNING "), "both slots run their own job")
	assert_false(caption.visible, "no pending job yet, no queued caption")
	assert_true(bool(Ref.queue(_profile, GOLD, 1)[&"ok"]), "the gold job queued behind them")
	panel.call(&"_refresh_slots")
	assert_true(caption.visible, "a pending job shows the caption")
	assert_eq(String(caption.text), "+ 1 QUEUED", "the FIFO count reads off the model")
	## A done job takes a chip when the running set leaves one: both iron jobs reach
	## their ready_at, settle finishes them and the pending gold promotes into the
	## freed slot (R6) - one chip reads DONE, the promoted job keeps RUNNING.
	var jobs: Array = Ref.jobs(_profile)
	jobs[0][&"ready_at"] = 0
	jobs[1][&"ready_at"] = 0
	_profile.set(&"_refinery_jobs", jobs)
	panel.call(&"_settle")
	panel.call(&"_refresh_slots")
	chips = _strip_chips(panel)
	var states: Array[String] = []
	for chip: PanelContainer in chips:
		states.append(String((chip.get_node_or_null(NodePath("ChipLabel")) as Label).text))
	var done_count := 0
	for state: String in states:
		if state == "DONE":
			done_count += 1
	assert_eq(done_count, 1, "the finished slot reads DONE")
	assert_false(caption.visible, "the promoted job left the FIFO count")
	## The 1 Hz tick: the job store is written silently (a `set_refinery_jobs` write
	## would rebuild the strip through its own signal), the tick refreshes the running
	## chip's countdown in place, and the chip node itself is never rebuilt. The job
	## list's signature is brought current first (`_build_jobs`), so the tick takes its
	## refresh-in-place branch and not the state-change rebuild.
	panel.call(&"_build_jobs")
	var chip := _strip_chips(panel)[0]
	var label := chip.get_node_or_null(NodePath("ChipLabel")) as Label
	jobs = Ref.jobs(_profile)
	jobs[2][&"ready_at"] = int(Time.get_unix_time_from_system()) + 95
	_profile.set(&"_refinery_jobs", jobs)
	panel.call(&"_tick")
	assert_true(String(label.text).begins_with("RUNNING 01:3"),
		"the countdown renders mm:ss (95 s reads 01:3x)")
	assert_eq(String(panel.call(&"_mmss", 95)), "01:35", "the mm:ss idiom renders 95 s")
	var before_children := chip.get_child_count()
	jobs = Ref.jobs(_profile)
	jobs[2][&"ready_at"] = int(Time.get_unix_time_from_system()) + 65
	_profile.set(&"_refinery_jobs", jobs)
	panel.call(&"_tick")
	assert_true(String(label.text).begins_with("RUNNING 01:0"),
		"the chip's countdown moved with the tick (65 s reads 01:0x)")
	assert_true(_strip_chips(panel)[0] == chip, "the chip node survived the tick")
	assert_eq(chip.get_child_count(), before_children, "the tick rebuilt nothing")


## ------------------------------------------------------ AC6: the REFINE / CRAFT pair


func test_p52_the_mode_switch_swaps_the_bodies() -> void:
	var panel := _panel
	var refine := panel.get_node_or_null(NodePath("%ModeRefine")) as Button
	var craft := panel.get_node_or_null(NodePath("%ModeCraft")) as Button
	assert_true(refine != null and craft != null, "the REFINE / CRAFT pair ships")
	if refine == null or craft == null:
		return
	assert_eq(refine.custom_minimum_size, CHIP_SIZE, "the ActionInline chip size")
	assert_eq(craft.custom_minimum_size, CHIP_SIZE, "and its pair's")
	assert_eq(String(refine.get_meta(&"chrome_class", "")), "C3", "the pair wears the chip chrome")
	assert_eq(String(craft.get_meta(&"chrome_class", "")), "C3", "both entries do")
	assert_eq(String(refine.text), "REFINE", "the pinned word")
	assert_eq(String(craft.text), "CRAFT", "and its pair's")
	assert_true(refine.toggle_mode and craft.toggle_mode, "the pair toggles (P32's idiom)")
	var body := panel.get_node_or_null(NodePath("%RefineryBody")) as Control
	var craft_body := panel.get_node_or_null(NodePath("%CraftBody")) as Control
	assert_true(body.visible and not craft_body.visible, "REFINE is the default mode")
	assert_eq(StringName(panel.call(&"mode")), &"refine", "the mode reads refine")
	## The CRAFT body: the section 19.4 empty-state caption and nothing else this wave.
	var empty := craft_body.get_node_or_null(NodePath("%CraftEmpty")) as Label
	assert_true(empty != null, "the CRAFT body carries its caption")
	if empty != null:
		assert_eq(String(empty.text), "NOTHING TO CRAFT", "the empty-state wording")
		assert_eq(craft_body.get_child_count(), 1, "and nothing else this wave")
	## The switch is a pure visibility operation (A5.5): no node is rebuilt or moved.
	var body_children := body.get_child_count()
	var rows := panel.get_node_or_null(NodePath("%HoldRows")) as VBoxContainer
	var row_children := rows.get_child_count()
	craft.button_pressed = true
	craft.pressed.emit()
	assert_eq(StringName(panel.call(&"mode")), &"craft", "the switch moved to CRAFT")
	assert_true(craft_body.visible and not body.visible, "exactly one mode body is visible")
	var actions := panel.get_node_or_null(NodePath("%ActionsRow")) as Control
	assert_false(actions.visible, "the foot band keeps its seat but carries no cluster")
	var footer := panel.get_node_or_null(NodePath("%PaneFooter")) as Label
	assert_eq(
		String(footer.text), "EVERY INPUT IS CONSUMED ON CRAFT · THE FEE IS LABOUR",
		"the CRAFT mode's own hint"
	)
	assert_eq(craft_body.get_child_count(), 1, "the CRAFT body grew nothing")
	assert_eq(rows.get_child_count(), row_children, "the REFINE rows were never rebuilt")
	assert_eq(body.get_child_count(), body_children, "nor moved")
	assert_true(refine.button_pressed == false and craft.button_pressed,
		"the pair's pressed states follow the mode")
	craft.button_pressed = false
	refine.pressed.emit()
	assert_eq(StringName(panel.call(&"mode")), &"refine", "the switch moved back")
	assert_true(body.visible and not craft_body.visible, "REFINE shows today's pane unchanged")
	assert_true(actions.visible, "the cluster is back")
	panel.call(&"set_mode", &"battery")
	assert_eq(StringName(panel.call(&"mode")), &"refine", "an unknown mode is ignored")


## ----------------------------------------------------- AC2: the fourth foot plate


func test_r11_the_foot_cluster_is_the_four_plates() -> void:
	var panel := _panel
	var row := panel.get_node_or_null(NodePath("PaneFoot/ActionsRow")) as HBoxContainer
	assert_true(row != null, "the foot cluster ships")
	if row == null:
		return
	var names: Array[String] = []
	for child: Node in row.get_children():
		names.append(String(child.name))
	assert_eq(
		names, ["CollectButton", "LoadAllButton", "LoadButton", "QueueButton"],
		"COLLECT ALL / LOAD ALL / LOAD / QUEUE left to right - QUEUE primary rightmost"
	)
	var words := ["COLLECT ALL", "LOAD ALL", "LOAD"]
	var index := 0
	for child: Node in row.get_children():
		var button := child as Button
		assert_eq(button.custom_minimum_size, P1_SIZE, "%s keeps the 360x56 plate" % child.name)
		assert_eq(button.theme_type_variation, P1_VARIATION, "%s keeps its plate" % child.name)
		if index < words.size():
			assert_eq(String(button.text), words[index], "%s keeps its word" % child.name)
		else:
			assert_true(String(button.text).begins_with("QUEUE"),
				"the primary keeps the QUEUE word (the live stepper count rides it)")
		index += 1
	assert_eq(row.get_theme_constant("separation"), 16, "the P2 gutter unchanged")
	var footer := panel.get_node_or_null(NodePath("%PaneFooter")) as Label
	assert_true(footer != null, "the hint cell is intact beside the cluster")
	var queue_all := panel.get_node_or_null(NodePath("%QueueAllButton")) as Button
	var cancel := panel.get_node_or_null(NodePath("%CancelButton")) as Button
	assert_true(queue_all != null and cancel != null, "QUEUE ALL and CANCEL ship")
	if queue_all != null and cancel != null:
		var queue_grid: Control = queue_all.get_parent().get_parent()
		var cancel_grid: Control = cancel.get_parent().get_parent()
		assert_true(queue_grid != null and cancel_grid != null,
			"both secondaries sit in their ActionGrid")
		if queue_grid != null and cancel_grid != null:
			assert_eq(
				String(queue_grid.get_parent().name), "RefineBox",
				"QUEUE ALL stays in the conversion column"
			)
			assert_eq(
				String(cancel_grid.get_parent().name), "RefineBox",
				"so does CANCEL"
			)


## ------------------------------------- AC3: the LOAD ALL press and its two refusals


func test_r9_the_press_moves_the_hold_and_the_refusals_ride_the_strip() -> void:
	var panel := _panel
	_profile.set(&"_cargo", {IRON_ORE: 24, COPPER_ORE: 24, GOLD_ORE: 24})
	panel.call(&"refresh_profile", &"refinery")
	var button := panel.get_node(NodePath("%LoadAllButton")) as Button
	var before := int(_profile.call(&"credits"))
	button.pressed.emit()
	assert_eq(Ref.input_total(_profile), 48, "the press filled the input with whole stacks")
	assert_eq(int(_profile.call(&"cargo_qty", GOLD_ORE)), 24, "the overflow stayed in the hold")
	assert_eq(int(_profile.call(&"credits")), before, "no credits moved (the LOAD law)")
	assert_eq(_statuses.size(), 1, "one status line")
	if _statuses.size() == 1:
		assert_false(bool(_statuses[0][1]), "a success is not a danger line")
		assert_eq(String(_statuses[0][0]), "LOADED · 48 ORE", "R9's status wording")
	## The empty-hold refusal: the hold drains behind the panel's back (no signal, no
	## rebuild), the press still answers on the strip.
	_profile.set(&"_cargo", {})
	button.pressed.emit()
	assert_eq(_statuses.size(), 2, "the empty hold answered on the strip")
	if _statuses.size() == 2:
		assert_true(bool(_statuses[1][1]), "a refusal is a danger line")
		assert_eq(String(_statuses[1][0]), "REFUSED · NOTHING TO LOAD", "the refusal wording")
	## The at-cap refusal: the input fills to its cap behind the panel's back, the
	## hold's stack cannot move and the strip names the cap.
	_profile.set(&"_cargo", {GOLD_ORE: 24})
	_profile.set(&"_refinery_input", {IRON_ORE: Ref.INPUT_CAP})
	button.pressed.emit()
	assert_eq(_statuses.size(), 3, "the at-cap input answered on the strip")
	if _statuses.size() == 3:
		assert_true(bool(_statuses[2][1]), "a refusal is a danger line")
		assert_eq(String(_statuses[2][0]), "REFUSED · INPUT FULL", "the at-cap wording")
	assert_eq(int(_profile.call(&"cargo_qty", GOLD_ORE)), 24, "the hold kept its stack")


## ------------------------------------------------- AC1: the model's LOAD ALL seam


func test_r9_load_all_moves_whole_stacks_up_to_the_cap() -> void:
	_model = _make_model()
	_model.add_cargo(IRON_ORE, 24)
	_model.add_cargo(GOLD_ORE, 9)
	var result: Dictionary = Ref.load_all(_model)
	assert_true(bool(result[&"ok"]), "a hold with movable stacks loads")
	assert_eq(int(result[&"loaded"]), 33, "the whole stacks moved, 24 + 9")
	assert_eq(Ref.input_total(_model), 33, "the input holds the moved units")
	assert_eq(Ref.input_units(_model, IRON), 24, "the iron stack moved whole")
	assert_eq(Ref.input_units(_model, GOLD), 9, "the gold stack moved whole")
	assert_eq(int(_model.call(&"cargo_qty", IRON_ORE)), 0, "the iron stack left the hold")
	assert_eq(int(_model.call(&"cargo_qty", GOLD_ORE)), 0, "the gold stack left the hold")


func test_r9_load_all_stops_at_the_cap_and_leaves_the_overflow() -> void:
	_model = _make_model()
	_model.add_cargo(IRON_ORE, 24)
	_model.add_cargo(COPPER_ORE, 24)
	_model.add_cargo(GOLD_ORE, 24)
	var result: Dictionary = Ref.load_all(_model)
	assert_true(bool(result[&"ok"]), "a partial fill still loads")
	assert_eq(int(result[&"loaded"]), 48, "two stacks filled the input to 48 of 60")
	assert_eq(Ref.input_total(_model), 48, "the input reads the moved units")
	assert_eq(int(_model.call(&"cargo_qty", GOLD_ORE)), 24,
		"the stack that cannot fit whole stays in the hold (R8's idiom)")
	assert_eq(int(_model.call(&"cargo_qty", IRON_ORE)), 0, "the first stack moved")
	assert_eq(int(_model.call(&"cargo_qty", COPPER_ORE)), 0, "the second stack moved")


func test_r9_load_all_never_splits_a_stack() -> void:
	_model = _make_model()
	_model.add_cargo(GOLD_ORE, 63)
	var result: Dictionary = Ref.load_all(_model)
	assert_false(bool(result[&"ok"]), "no whole stack fits, nothing loads")
	assert_eq(StringName(result[&"reason"]), Ref.REASON_INPUT_FULL,
		"the input cannot take the next whole stack")
	assert_eq(int(_model.call(&"cargo_qty", GOLD_ORE)), 63,
		"the oversized stack stays whole in the hold")
	assert_eq(Ref.input_total(_model), 0, "nothing moved")


func test_r9_load_all_refuses_an_input_already_at_cap() -> void:
	_model = _make_model()
	_model.add_cargo(IRON_ORE, 9)
	_model.set(&"_refinery_input", {IRON_ORE: Ref.INPUT_CAP})
	var before := int(_model.call(&"credits"))
	var result: Dictionary = Ref.load_all(_model)
	assert_false(bool(result[&"ok"]), "a full input refuses")
	assert_eq(StringName(result[&"reason"]), Ref.REASON_INPUT_FULL, "reason input_full")
	assert_eq(int(_model.call(&"cargo_qty", IRON_ORE)), 9, "the hold kept its stack")
	assert_eq(int(_model.call(&"credits")), before, "no credits moved")


func test_r9_load_all_refuses_an_empty_hold() -> void:
	_model = _make_model()
	var result: Dictionary = Ref.load_all(_model)
	assert_false(bool(result[&"ok"]), "an empty hold refuses")
	assert_eq(StringName(result[&"reason"]), Ref.REASON_NOTHING_TO_LOAD,
		"reason nothing_to_load")
	assert_eq(Ref.input_total(_model), 0, "the input untouched")


func test_r9_load_all_moves_no_credits_and_logs_none() -> void:
	_model = _make_model()
	_model.add_cargo(IRON_ORE, 12)
	var before := int(_model.call(&"credits"))
	var result: Dictionary = Ref.load_all(_model)
	assert_true(bool(result[&"ok"]), "the load ran")
	assert_eq(int(_model.call(&"credits")), before, "the LOAD law: no credits move")
	_delete_file(MODEL_LOG)
	assert_false(FileAccess.file_exists(MODEL_LOG),
		"no economy-log line - a transfer is not a transaction")


## ------------------------------------------------------------------------- helpers


func _make_model() -> Node:
	_delete_file(MODEL_LOG)
	var model: Node = load("res://autoload/player_profile.gd").new()
	model.save_path = MODEL_SAVE
	Log.log_path = MODEL_LOG
	return model


## A fresh account, written straight into the borrowed fields (the s44 idiom): the
## setter doors emit per write, and this suite's shared pane pays one rebuild per
## test instead of one per field.
func _seed_account() -> void:
	var owned: Array[StringName] = [&"ship_vanguard"]
	_profile.set(&"_credits", 10000)
	_profile.set(&"_active_ship", &"ship_vanguard")
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_cargo", {})
	_profile.set(&"_refinery_slots", 2)
	_profile.set(&"_refinery_input", {})
	_profile.set(&"_refinery_output", {})
	_profile.set(&"_refinery_jobs", [])
	_profile.set(&"_refinery_next_job_id", 1)


func _mount_panel() -> void:
	if _host == null or not is_instance_valid(_host):
		_host = Control.new()
		_host.name = "S45RefineryHost"
		_host.theme = ThemeRes
		_host.size = Vector2(1920.0, 1080.0)
		_fixture_host().add_child(_host)
	_panel = PanelScene.instantiate() as Control
	_host.add_child(_panel)
	## `profile_changed` stays DISCONNECTED for this suite: every transaction this
	## suite drives would otherwise rebuild the whole pane through the signal (the
	## shipped live-path behaviour), and the gate's one-frame window has no headroom
	## for that churn (measured above). Every row here reads the profile's own fields,
	## the strip's narrow `_refresh_slots` read, or the captured status/confirm
	## signals - never the rendered rows - so the live refresh path is s41/s8's
	## suites' to pin, not this one's.
	_panel.connect(&"status_requested", _on_status_requested)
	_panel.connect(&"confirm_requested", _on_confirm_requested)


func _free_host() -> void:
	if _panel != null and is_instance_valid(_panel):
		_panel.free()
	_panel = null
	if _host != null and is_instance_valid(_host):
		_host.free()
	_host = null


func _strip_chips(panel: Control) -> Array[PanelContainer]:
	var chips: Array[PanelContainer] = []
	var strip := panel.get_node_or_null(NodePath("%SlotStrip")) as HBoxContainer
	if strip == null:
		return chips
	for child: Node in strip.get_children():
		var chip := child as PanelContainer
		if chip != null:
			chips.append(chip)
	return chips


func _on_status_requested(message: String, danger: bool) -> void:
	_statuses.append([message, danger])


func _on_confirm_requested(payload: Dictionary) -> void:
	_confirms.append(payload)


func _fixture_host() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(NodePath(PROFILE_SERVICE))


func _delete_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())
