@tool
extends McpTestSuite
const Support := preload("res://tests/support.gd")
## Suite s49_confirm_doors: wave S49's four buy-confirmation doors on the surfaces
## D24's A series left untouched - the AUCTION's hull buy and its module listing buy,
## the INSURANCE opt-in (off->on only) and the VAULTS rent per tier (UI_SPEC section 17
## A4-A6). One row per acceptance item:
##   1. the hull buy press opens the shell seam's confirm (A6's wording) and charges
##      nothing; the confirmed answer runs `buy_hull` unchanged, which can still refuse;
##   2. the module listing buy press opens the same dialog with the rolled listing's own
##      name and price; the confirmed answer runs `buy_listing` unchanged;
##   3. the INSURE LAUNCHES press opens the dialog with the active hull's class premium
##      (the PER LAUNCH tail is A6's own worked example); the OFF path stays dialog-free;
##   4. the VAULTS RENT press per tier opens the dialog with the tier row's own cost;
##      the confirmed answer runs `vault_rent` unchanged, which can still refuse;
##   5. the out-boundary surfaces stay dialog-free: the LAUNCH commit (and with it the
##      per-launch premium charge, which the same flow performs), the refinery QUEUE
##      presses, the REPAIR and PAY BOUNTY services and the contract cancel's own S25
##      wording - asserted on the files themselves, the way the S5 suite measures a
##      retired half;
##   6. the wording-law rows: A6's worked examples instantiated verbatim, one row each -
##      the exact body string the door emits, `<NAME>`/`<PRICE>` derived from the
##      owning catalogues (the corvette hull's 10 section 3.1 figure, the M14 premium
##      re-derivation, 14 section 4's tier-2 rent).
##
## The panes mount the way the commerce suite mounts them (the shipped scenes, the
## shipped theme, the profile borrowed and handed back). The confirm door is watched
## through each pane's own `confirm_requested` signal - the shell overlay is not mounted
## here, so the suite answers through the seam's public `confirm_action` and never
## asserts the shell's own focus/ESC behaviour (that is station.gd's, already shipped).

const AuctionScene := preload("res://ui/station/auction_panel.tscn")
const AuctionPanel := preload("res://ui/station/auction_panel.gd")
const InsuranceScene := preload("res://ui/station/insurance_panel.tscn")
const InsurancePanel := preload("res://ui/station/insurance_panel.gd")
const VaultsScene := preload("res://ui/station/vaults_panel.tscn")
const VaultsPanel := preload("res://ui/station/vaults_panel.gd")
const AuctionScript := preload("res://game/auction.gd")
const Catalog := preload("res://game/station_catalog.gd")
const Clock := preload("res://autoload/world_clock.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")

const PROFILE_PATH := "user://test_s49_confirm_doors.cfg"
const PROFILE_SERVICE: StringName = &"PlayerProfile"
const SEED := 20261013
const CORVETTE: StringName = &"ship_corvette"
const FIGHTER: StringName = &"ship_fighter"
## The worked examples' own figures, pinned where their owning doc pins them and read
## back off the catalogue in the rows below (never hardcoded into an expectation).
const WORKED_CORVETTE_COST := 27000
const WORKED_VAULT_TIER := 2
const WORKED_VAULT_COST := 1200
const WINDOW := Vector2(1920.0, 1080.0)
const SEED_TRIES := 200

var _profile: Node = null
var _host: Control = null
var _panel: Control = null
var _previous_path := ""
var _previous_credits := 0
var _previous_ship: StringName = &""
var _previous_owned: Array = []
var _previous_modules: Dictionary = {}
var _previous_batteries: Dictionary = {}
var _previous_auction: Dictionary = {}
var _previous_counter := 0
var _previous_insured := false
var _previous_paid_out := false
var _previous_vaults: Dictionary = {}
var _previous_standing: Dictionary = {}
var _confirms: Array[Dictionary] = []
var _statuses: Array[String] = []
var _danger: Array[bool] = []


func suite_name() -> String:
	return "s49_confirm_doors"


func suite_setup(_ctx: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		skip_suite("a SceneTree is needed to mount the panes")
		return
	_profile = tree.root.get_node_or_null(NodePath(PROFILE_SERVICE))
	if _profile == null:
		skip_suite("the PlayerProfile autoload is the panes' store")
		return
	_previous_path = String(_profile.get(&"save_path"))
	_previous_credits = int(_profile.call(&"credits"))
	_previous_ship = StringName(_profile.call(&"active_ship"))
	_previous_owned = _profile.call(&"owned_ships")
	_previous_modules = _profile.call(&"modules")
	_previous_batteries = _profile.get(&"_batteries")
	_previous_auction = _profile.call(&"auction")
	_previous_counter = int(_profile.get(&"_instance_counter"))
	_previous_insured = bool(_profile.call(&"insured"))
	_previous_paid_out = bool(_profile.get(&"_insurance_paid_out"))
	_previous_vaults = _profile.call(&"vaults")
	_previous_standing = (_profile.get(&"_standing") as Dictionary).duplicate(true)
	_profile.set(&"save_path", PROFILE_PATH)
	Support.delete_file(PROFILE_PATH)


func suite_teardown() -> void:
	_release_host()
	if _profile == null:
		return
	_profile.set(&"_credits", _previous_credits)
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_owned_ships", _previous_owned)
	_profile.set(&"_modules", _previous_modules)
	_profile.set(&"_batteries", _previous_batteries)
	_profile.set(&"_auction", _previous_auction)
	_profile.set(&"_instance_counter", _previous_counter)
	_profile.set(&"_insured", _previous_insured)
	_profile.set(&"_insurance_paid_out", _previous_paid_out)
	_profile.call(&"set_vaults", _previous_vaults)
	_profile.set(&"_standing", _previous_standing)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	Support.delete_file(PROFILE_PATH)
	_profile = null


func setup() -> void:
	_release_host()
	_confirms.clear()
	_statuses.clear()
	_danger.clear()
	_seed_account()
	_profile.set(&"_active_ship", FIGHTER)


func teardown() -> void:
	_release_host()


func _seed_account() -> void:
	var owned: Array[StringName] = []
	var neutral: Dictionary = {}
	_profile.set(&"_credits", 200000)
	_profile.set(&"_active_ship", FIGHTER)
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_modules", {})
	_profile.set(&"_batteries", {})
	_profile.set(&"_insurance_paid_out", false)
	_profile.call(&"set_insured", false)
	_profile.call(&"set_vaults", {})
	_profile.set(&"_auction", {})
	## Neutral standing everywhere (the bands' own baseline), so the shelf's prices are
	## the catalogue's own and the worked examples' figures derive exactly.
	_profile.set(&"_standing", neutral)


func _mount(scene: PackedScene) -> Control:
	var host := Control.new()
	host.name = "S49DoorsHost"
	host.theme = ThemeRes
	host.size = WINDOW
	_profile.add_child(host)
	_host = host
	_panel = scene.instantiate() as Control
	_host.add_child(_panel)
	if _panel.has_signal(&"status_requested"):
		_panel.connect(&"status_requested", _on_status_requested)
	if _panel.has_signal(&"confirm_requested"):
		_panel.connect(&"confirm_requested", _on_confirm_requested)
	_profile.connect(&"profile_changed", Callable(_panel, &"refresh_profile"))
	return _panel


func _release_host() -> void:
	if _host != null and is_instance_valid(_host):
		_host.free()
	_host = null
	_panel = null


func _on_confirm_requested(payload: Dictionary) -> void:
	_confirms.append(payload)


func _on_status_requested(message: String, danger: bool) -> void:
	_statuses.append(message)
	_danger.append(danger)

func _read_source(path: String) -> String:
	return FileAccess.get_file_as_string(path)


## The one seeded shelf that carries the wanted hull at its list price: a fixed-seed
## draw loop, so the outcome stays deterministic (the S3 suite's own two-stream law -
## the global seed fixes the rarity and affix rolls) while still guaranteeing the
## worked example's row.
func _seed_shelf_with(profile: Node, ship_id: StringName) -> bool:
	var rng := RandomNumberGenerator.new()
	for step in range(SEED_TRIES):
		rng.seed = SEED + step
		seed(SEED + step)
		var shelf: Dictionary = AuctionScript.draw_shelf(profile, rng)
		shelf[&"last_band"] = Clock.now()
		profile.call(&"set_auction", shelf)
		if AuctionScript.hull_ids(profile).has(ship_id):
			return not AuctionScript.hot_ids(profile).has(ship_id)
	return false


func _hull_row_of(panel: Control, ship_id: StringName) -> Button:
	for payload: Dictionary in panel.call(&"hull_payloads") as Array[Dictionary]:
		if StringName(payload[&"id"]) == ship_id:
			return payload[&"row"] as Button
	return null


func _listing_row_of(panel: Control, index: int) -> Button:
	var rows: Array[Dictionary] = panel.call(&"module_payloads")
	if index < 0 or index >= rows.size():
		return null
	return rows[index][&"row"] as Button


func _rent_button(panel: Control, tier: int) -> Button:
	var tier_row := panel.get_node_or_null(
		NodePath("%TierList/" + ("Tier%d" % tier))
	) as Control
	if tier_row == null:
		return null
	var stack: Array[Node] = [tier_row]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is Button and String(node.name).begins_with("Action"):
			return node as Button
		stack.append_array(node.get_children())
	return null


## One confirm press, word for word: the seam's own title, the A6 sentence's frame and
## the two button words the seam's contract fixes.
func _assert_confirm_shape(payload: Dictionary, expected_body: String, what: String) -> void:
	assert_eq(String(payload.get(&"title", "")), AuctionPanel.BUY_CONFIRM_TITLE,
		"%s carries the pinned title" % what)
	assert_eq(String(payload.get(&"body", "")), expected_body, "%s carries the A6 body" % what)
	assert_eq(String(payload.get(&"confirm_text", "")), AuctionPanel.BUY_CONFIRM_OK,
		"%s carries the seam's OK" % what)
	assert_eq(String(payload.get(&"cancel_text", "")), AuctionPanel.BUY_CONFIRM_CANCEL,
		"%s carries the seam's CANCEL" % what)


## ------------------------------------------------------------------ A1: the hull door


func test_f1_the_hull_buy_press_opens_the_confirm_and_the_answer_buys() -> void:
	assert_true(
		_seed_shelf_with(_profile, CORVETTE),
		"the seeded shelf lists the worked example's hull at its list price"
	)
	var panel := _mount(AuctionScene)
	var row := _hull_row_of(panel, CORVETTE)
	assert_true(row != null, "the corvette row built")
	if row == null:
		return
	var target: Dictionary = {}
	for hull: Dictionary in panel.call(&"hull_payloads") as Array[Dictionary]:
		if StringName(hull[&"id"]) == CORVETTE:
			target = hull
	assert_true(not target.is_empty(), "the corvette row carries its own figures")
	if target.is_empty():
		return
	var before := int(_profile.call(&"credits"))
	row.pressed.emit()
	assert_eq(_confirms.size(), 1, "the hull press opened exactly one confirm")
	assert_eq(int(_profile.call(&"credits")), before, "and charged nothing before the answer")
	if _confirms.is_empty():
		return
	var payload := _confirms[0]
	assert_eq(StringName(payload.get(&"action", &"")), AuctionPanel.ACTION_BUY_HULL,
		"the payload routes the hull action")
	assert_eq(StringName(payload.get(&"id", &"")), CORVETTE, "the payload carries the hull id")
	_confirms.clear()
	panel.call(&"confirm_action", AuctionPanel.ACTION_BUY_HULL, CORVETTE)
	assert_eq(
		int(_profile.call(&"credits")), before - int(target[&"cost"]),
		"the confirmed answer charged the buyout the press quoted"
	)
	assert_true(bool(_profile.call(&"owns_ship", CORVETTE)), "and the hull is the account's now")
	assert_true(
		String(panel.call(&"status_text")).begins_with("PURCHASED · "),
		"the transaction's own strip wording still reports it"
	)


func test_f1_a_confirmed_hull_buy_can_still_refuse() -> void:
	assert_true(_seed_shelf_with(_profile, CORVETTE), "the seeded shelf lists a hull")
	var panel := _mount(AuctionScene)
	var row := _hull_row_of(panel, CORVETTE)
	assert_true(row != null, "the corvette row built")
	if row == null:
		return
	var target: Dictionary = {}
	for hull: Dictionary in panel.call(&"hull_payloads") as Array[Dictionary]:
		if StringName(hull[&"id"]) == CORVETTE:
			target = hull
	assert_true(not target.is_empty(), "the corvette row carries its own figures")
	if target.is_empty():
		return
	_profile.set(&"_credits", 0)
	row.pressed.emit()
	assert_eq(_confirms.size(), 1, "the unaffordable press still opens the door")
	if _confirms.is_empty():
		return
	_statuses.clear()
	panel.call(&"confirm_action", AuctionPanel.ACTION_BUY_HULL, CORVETTE)
	assert_false(bool(_profile.call(&"owns_ship", CORVETTE)), "the refused answer bought nothing")
	assert_eq(int(_profile.call(&"credits")), 0, "and charged nothing")
	assert_eq(
		String(panel.call(&"status_text")),
		AuctionPanel.STATUS_REFUSED_CREDITS % _format_int(int(target[&"cost"])),
		"the refusal keeps section 5.6's strip wording, never a dialog"
	)
	assert_eq(_danger[_danger.size() - 1], true, "and marks it as danger")


## --------------------------------------------------------------- A2: the listing door


func test_f2_the_listing_buy_press_opens_the_confirm_and_the_answer_buys() -> void:
	assert_true(_seed_shelf_with(_profile, CORVETTE), "the seeded shelf stocks its listings")
	var panel := _mount(AuctionScene)
	var row := _listing_row_of(panel, 0)
	assert_true(row != null, "the first listing row built")
	if row == null:
		return
	var target: Dictionary = panel.call(&"module_payloads")[0] as Dictionary
	var before := int(_profile.call(&"credits"))
	row.pressed.emit()
	assert_eq(_confirms.size(), 1, "the listing press opened exactly one confirm")
	assert_eq(int(_profile.call(&"credits")), before, "and charged nothing before the answer")
	if _confirms.is_empty():
		return
	var payload := _confirms[0]
	assert_eq(
		String(payload.get(&"body", "")),
		AuctionPanel.BUY_CONFIRM_BODY
			% [String(target[&"name"]).to_upper(), _format_int(int(target[&"cost"]))],
		"the dialog words the rolled instance's own name and price, never the tier's list"
	)
	var listing_id: StringName = StringName(target[&"id"])
	_confirms.clear()
	panel.call(&"confirm_action", AuctionPanel.ACTION_BUY_LISTING, listing_id)
	var banked: Dictionary = _profile.call(&"instance", listing_id)
	assert_eq(int(banked.get(&"count", 0)), 1, "the confirmed answer put the instance in the bag")
	assert_eq(
		int(_profile.call(&"credits")), before - int(target[&"cost"]),
		"and charged the price the row showed"
	)


## -------------------------------------------------------------- A3: the insurance door


func test_f3_the_insure_opt_in_opens_the_confirm_and_the_answer_sets_the_policy() -> void:
	var panel := _mount(InsuranceScene)
	var toggle := panel.get_node(NodePath("%OptInToggle")) as Button
	assert_true(toggle != null and not toggle.disabled, "the opt-in toggle is live at H1")
	if toggle == null:
		return
	var premium := int(_profile.call(&"insurance_premium"))
	var before := int(_profile.call(&"credits"))
	toggle.pressed.emit()
	assert_eq(_confirms.size(), 1, "the opt-in press opened exactly one confirm")
	assert_eq(int(_profile.call(&"credits")), before, "and charged nothing before the answer")
	assert_false(bool(_profile.call(&"insured")), "and the policy is not set yet")
	if _confirms.is_empty():
		return
	var payload := _confirms[0]
	assert_eq(StringName(payload.get(&"action", &"")), InsurancePanel.ACTION_INSURE,
		"the payload routes the insurance action")
	_confirms.clear()
	panel.call(&"confirm_action", InsurancePanel.ACTION_INSURE, StringName(payload.get(&"id", &"")))
	assert_true(bool(_profile.call(&"insured")), "the confirmed answer set the policy")
	assert_eq(
		_last_status(),
		"POLICY SET · %s" % InsurancePanel.STATE_INSURED,
		"through the toggle's own report"
	)
	assert_eq(int(_profile.call(&"credits")), before, "and the per-launch charge stays uncharged")


func test_f3_the_insure_off_path_stays_dialog_free() -> void:
	var panel := _mount(InsuranceScene)
	var toggle := panel.get_node(NodePath("%OptInToggle")) as Button
	assert_true(toggle != null and not toggle.disabled, "the opt-in toggle is live at H1")
	if toggle == null:
		return
	_profile.call(&"set_insured", true)
	panel.call(&"refresh_profile", &"insurance")
	assert_eq(String(panel.call(&"toggle_text")), InsurancePanel.TOGGLE_OFF,
		"the toggle reads the action it will take")
	toggle.pressed.emit()
	assert_eq(_confirms.size(), 0, "the OFF path opens no dialog")
	assert_false(bool(_profile.call(&"insured")), "and the policy cancelled on the press")
	assert_eq(_last_status(), "POLICY CANCELLED", "through its own report")


## ----------------------------------------------------------------- A4: the vault door


func test_f4_the_vault_rent_press_opens_the_confirm_and_the_answer_rents() -> void:
	var panel := _mount(VaultsScene)
	var rent := _rent_button(panel, WORKED_VAULT_TIER)
	assert_true(rent != null and not rent.disabled, "tier 2's RENT is live at H1")
	if rent == null:
		return
	var before := int(_profile.call(&"credits"))
	rent.pressed.emit()
	assert_eq(_confirms.size(), 1, "the rent press opened exactly one confirm")
	assert_eq(int(_profile.call(&"credits")), before, "and charged nothing before the answer")
	assert_eq(int(_profile.call(&"vault_tier", &"s1_primary")), 0, "and rented nothing yet")
	if _confirms.is_empty():
		return
	var payload := _confirms[0]
	assert_eq(StringName(payload.get(&"action", &"")), VaultsPanel.ACTION_RENT,
		"the payload routes the rent action")
	_confirms.clear()
	panel.call(&"confirm_action", VaultsPanel.ACTION_RENT, StringName(payload.get(&"id", &"")))
	assert_eq(int(_profile.call(&"vault_tier", &"s1_primary")), WORKED_VAULT_TIER,
		"the confirmed answer rented the tier")
	assert_eq(
		int(_profile.call(&"credits")), before - WORKED_VAULT_COST,
		"and charged the tier row's own cost"
	)
	assert_eq(
		_last_status(),
		"VAULT TIER %d RENTED · %d CR" % [WORKED_VAULT_TIER, WORKED_VAULT_COST],
		"through the transaction's own strip wording"
	)


func test_f4_a_confirmed_vault_rent_can_still_refuse() -> void:
	var panel := _mount(VaultsScene)
	var rent := _rent_button(panel, WORKED_VAULT_TIER)
	assert_true(rent != null and not rent.disabled, "tier 2's RENT is live at H1")
	if rent == null:
		return
	_profile.set(&"_credits", 0)
	rent.pressed.emit()
	assert_eq(_confirms.size(), 1, "the unaffordable press still opens the door")
	if _confirms.is_empty():
		return
	_statuses.clear()
	panel.call(&"confirm_action", VaultsPanel.ACTION_RENT, StringName(_confirms[0].get(&"id", &"")))
	assert_eq(int(_profile.call(&"vault_tier", &"s1_primary")), 0, "the refused answer rented nothing")
	assert_eq(_last_status(), VaultsPanel.REFUSED_FULL,
		"the refusal keeps the strip's own wording, never a dialog")
	assert_eq(_danger[_danger.size() - 1], true, "and marks it as danger")


## ------------------------------------------------------------ A5: the out-boundary rows


## The LAUNCH commit is P48's two-press law, not a dialog (A4's own exclusion) - and the
## per-launch premium charge rides that same flow, so the file carries no confirm seam
## at all. REPAIR and PAY BOUNTY are the same shape: service spends with their own
## verify/refusal strips.
func test_f5_the_launch_commit_and_the_service_spends_open_no_dialog() -> void:
	var launch := _read_source("res://ui/station/launch_panel.gd")
	assert_contains(launch, "launch_requested", "the LAUNCH flow is the file under test")
	assert_eq(
		launch.contains("confirm_requested"), false,
		"the LAUNCH panel carries no confirm seam - the commit and the charge stay dialog-free"
	)
	var repairs := _read_source("res://ui/station/repairs_panel.gd")
	assert_contains(repairs, "REPAIR", "the repair service is the file under test")
	assert_eq(
		repairs.contains("confirm_requested"), false,
		"the REPAIR service opens no dialog"
	)


func test_f5_the_refinery_queue_presses_open_no_dialog() -> void:
	var source := _read_source("res://ui/station/refinery_panel.gd")
	assert_contains(source, "func _on_queue_pressed", "the refinery queue press is the file's")
	for handler: String in ["_on_queue_pressed", "_on_queue_all_pressed"]:
		var body := _function_body(source, handler)
		assert_true(body != "", "the %s handler is readable" % handler)
		if body == "":
			continue
		assert_eq(
			body.contains("confirm_requested"), false,
			"the QUEUE press opens no dialog (A4's own exclusion)"
		)


func test_f5_the_contract_cancel_keeps_its_own_wording() -> void:
	var source := _read_source("res://ui/station/contracts_panel.gd")
	assert_contains(source, "CANCEL THIS CONTRACT?", "the cancel door keeps S25's own title")
	assert_eq(
		source.contains(AuctionPanel.BUY_CONFIRM_TITLE), false,
		"the contract cancel is never fronted with the A6 purchase wording"
	)


## ------------------------------------------------------- A6: the worked-example rows


func test_f6_worked_example_the_hull_string() -> void:
	assert_true(
		_seed_shelf_with(_profile, CORVETTE),
		"the seeded shelf lists the corvette at its list price"
	)
	var panel := _mount(AuctionScene)
	var row := _hull_row_of(panel, CORVETTE)
	assert_true(row != null, "the corvette row built")
	if row == null:
		return
	assert_eq(
		int(Catalog.ship(CORVETTE).get(&"cost", 0)), WORKED_CORVETTE_COST,
		"the worked example's figure is the catalogue's own (10 section 3.1)"
	)
	row.pressed.emit()
	assert_eq(_confirms.size(), 1, "the door opened")
	if _confirms.is_empty():
		return
	var name_text := String(Catalog.ship(CORVETTE).get(&"name", "")).to_upper()
	_assert_confirm_shape(
		_confirms[0],
		AuctionPanel.BUY_CONFIRM_BODY % [name_text, _format_int(WORKED_CORVETTE_COST)],
		"the hull door"
	)


func test_f6_worked_example_the_insurance_string() -> void:
	var panel := _mount(InsuranceScene)
	var toggle := panel.get_node(NodePath("%OptInToggle")) as Button
	assert_true(toggle != null and not toggle.disabled, "the opt-in toggle is live at H1")
	if toggle == null:
		return
	var premium := int(_profile.call(&"insurance_premium"))
	assert_gt(premium, 0, "the fighter class carries its own premium (14 section 3)")
	toggle.pressed.emit()
	assert_eq(_confirms.size(), 1, "the door opened")
	if _confirms.is_empty():
		return
	var body := String(_confirms[0].get(&"body", ""))
	assert_eq(
		body,
		InsurancePanel.BUY_CONFIRM_BODY % _format_int(premium),
		"the exact string, the premium the M14 re-derivation quotes"
	)
	assert_true(
		body.begins_with("ARE YOU SURE YOU WANT TO BUY LAUNCH INSURANCE FOR ")
			and body.ends_with(" CREDITS PER LAUNCH?"),
		"the worked example's own sentence frame (the PER LAUNCH tail included)"
	)


func test_f6_worked_example_the_vault_string() -> void:
	var panel := _mount(VaultsScene)
	var rent := _rent_button(panel, WORKED_VAULT_TIER)
	assert_true(rent != null and not rent.disabled, "tier 2's RENT is live at H1")
	if rent == null:
		return
	var row: Dictionary = {}
	for entry: Dictionary in panel.get(&"_tiers") as Array:
		if int(entry[&"tier"]) == WORKED_VAULT_TIER:
			row = entry
	assert_true(not row.is_empty(), "tier 2's own row is on the pane")
	if row.is_empty():
		return
	assert_eq(
		int(row[&"cost"]), WORKED_VAULT_COST,
		"the worked example's figure is the tier row's own cost field (14 section 4)"
	)
	rent.pressed.emit()
	assert_eq(_confirms.size(), 1, "the door opened")
	if _confirms.is_empty():
		return
	_assert_confirm_shape(
		_confirms[0],
		VaultsPanel.BUY_CONFIRM_BODY
			% [VaultsPanel.BUY_CONFIRM_TIER_FORMAT % WORKED_VAULT_TIER, _format_int(WORKED_VAULT_COST)],
		"the vault door"
	)


## ----------------------------------------------------------------------- the helpers


## The service panes report through the shell's strip only (no own read), so the suite
## captures the `status_requested` channel the shell itself wires and reads its tail.
func _last_status() -> String:
	return _statuses[_statuses.size() - 1] if not _statuses.is_empty() else ""


func _function_body(source: String, name: String) -> String:
	var marker := "func %s" % name
	var start := source.find(marker)
	if start < 0:
		return ""
	var next := source.find("\nfunc ", start + 1)
	var end := next if next > 0 else source.length()
	return source.substr(start, end - start)


func _format_int(value: int) -> String:
	var digits := str(absi(value))
	var grouped := ""
	var count := 0
	for index in range(digits.length() - 1, -1, -1):
		grouped = digits[index] + grouped
		count += 1
		if count % 3 == 0 and index > 0:
			grouped = " " + grouped
	return ("-" if value < 0 else "") + grouped
