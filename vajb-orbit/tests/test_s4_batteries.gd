@tool
extends McpTestSuite
## Suite s4_batteries: the S4 battery **transactions** and the S5 rack **record** -- the
## profile-level half of the battery work, with no pane mounted.
##
## The law is 09 section 10 (the battery), 09 section 11 (batteries v2: composed mixed
## racks) and CONTRACTS sections 16/17; the rules this suite measures:
##
##  - **§16 rules 7-8** -- `fit_battery` / `clear_battery`, the two bulk wrappers: the
##    batch's pairing (`instances_of` into ascending cells), its atomicity over the fit
##    **and** the bag, and the guards that answer before the first write.
##  - **§16 rule 9** -- the three refusal literals are byte-equivalent to
##    `ui/station/fitting_panel.gd`'s own, and the overload line is built from
##    `fit_legal`'s power numbers; the mandatory wording is never asserted through a
##    battery (it is unreachable for a W cell: `FitData.MANDATORY_SLOT_KEYS` is
##    `[engines, power]`).
##  - **§17** -- the persisted record `batteries: {ship_id: Array[Array[cell_ref]]}`:
##    `battery_groups` (the derived read that covers every fitted W cell),
##    `set_battery_groups` (the normalising write), the three composed drag
##    transactions `fit_into_rack` / `clear_rack_cell` / `move_rack_cell`, and the
##    `GROUPS_MAX` rack ceiling.
##
## The pane's own surface (the racks, the drop zones, the drag payloads, the footer's
## refusals) is `tests/test_p2b1_outfitting_panel.gd`'s, and the flight half of the salvo
## gate plus the v6 -> v7 file fixture is `tests/test_s5_batteries_v2.gd`'s.
##
## The profile is the shipped autoload, borrowed the way `test_p2a_launch_fit.gd` borrows
## it: `save_path` is repointed at a scratch file before the first mutation, every field
## this suite can write is seeded, handed back in `suite_teardown` and flushed while the
## scratch path is still in place, so the owner's `user://profile.cfg` is never written
## (probe hygiene L17, the S3 incident's cure, T-93).

const PanelScript := preload("res://ui/station/armory_panel.gd")
const FittingPanelScript := preload("res://ui/station/fitting_panel.gd")
const Catalog := preload("res://game/station_catalog.gd")
const ModuleData := preload("res://game/module_catalog.gd")
const FitData := preload("res://game/ship_fit.gd")

const PROFILE_PATH := "user://test_s4_batteries.cfg"

const VANGUARD: StringName = &"ship_vanguard"
## The hull the refused-batch regression switches to: the Lancer's two-barrel laser battery is
## the smallest one a bag of one instance cannot cover.
const FIT_HULL: StringName = &"ship_fighter"
const WEAPON_SLOT: StringName = &"weapons"
const ENGINE_SLOT: StringName = &"engines"
const POWER_SLOT: StringName = &"power"
const STANDARD_ENGINE: StringName = &"e_std"
const STANDARD_REACTOR: StringName = &"p_std"
const LASER: StringName = &"w_laser"
const CANNON: StringName = &"w_cannon"
const RAILGUN: StringName = &"w_railgun"
const MINING: StringName = &"w_mining"

const START_CREDITS := 10000
## The W cells the Vanguard's 08 section 3.2 matrix carries, asserted rather than assumed.
const VANGUARD_W_CELLS := 3

var _profile: Node = null
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_credits := 0
var _previous_fits: Dictionary = {}
var _previous_owned: Array = []
var _previous_modules: Dictionary = {}
var _previous_batteries: Dictionary = {}


func suite_name() -> String:
	return "s4_batteries"


func suite_setup(_ctx: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		fail_setup("a SceneTree is needed to reach the profile")
		return
	_profile = tree.root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		fail_setup("the PlayerProfile autoload is the store under test")
		return
	_previous_path = String(_profile.get(&"save_path"))
	_previous_ship = StringName(_profile.call(&"active_ship"))
	_previous_credits = int(_profile.call(&"credits"))
	_previous_fits = _profile.call(&"fits")
	_previous_owned = _profile.call(&"owned_ships")
	_previous_modules = _profile.call(&"modules")
	_previous_batteries = _profile.get(&"_batteries")
	_profile.set(&"save_path", PROFILE_PATH)
	_delete_file(PROFILE_PATH)


func suite_teardown() -> void:
	if _profile == null:
		return
	## Hand every borrowed field back, flush on the scratch path and only then restore the
	## real one, so no dirty flag and no running timer carries a test's account home.
	_profile.set(&"_credits", _previous_credits)
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_fits", _previous_fits)
	_profile.set(&"_owned_ships", _previous_owned)
	_profile.set(&"_modules", _previous_modules)
	_profile.set(&"_batteries", _previous_batteries)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	_delete_file(PROFILE_PATH)
	_profile = null


## The fixture account every test starts from: the Vanguard active and owned, no fit, no
## modules, no racks, 10 000 CR. Written through the private fields the other profile suites
## hand back, so no purchase is charged and no signal fires before the test acts.
func setup() -> void:
	var owned: Array[StringName] = [VANGUARD]
	_profile.set(&"_credits", START_CREDITS)
	_profile.set(&"_active_ship", VANGUARD)
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_ammo", {})
	_profile.set(&"_batteries", {})


## ------------------------------------------------------------------ fixtures and read-backs


## The Vanguard's delivered fit (09 section 9), so every cell write below composes against a
## fit that carries 09 section 7's mandatory set.
func _seed_standard_fit() -> void:
	assert_true(
		bool(_profile.call(&"set_fit", VANGUARD, FitData.standard_fit(VANGUARD))),
		"the hull's standard fit is written"
	)


func _instance(base_id: StringName, rarity: StringName = &"common") -> StringName:
	return StringName(_profile.call(&"add_instance", base_id, rarity, [], []))


func _cells() -> Array:
	return _profile.call(&"fit_for", VANGUARD)[WEAPON_SLOT]


## The hulls the account holds a **stored** fit for: what a refused transaction must not add to.
func _fits() -> Dictionary:
	return _profile.call(&"fits")


func _module_count(record_id: StringName) -> int:
	return int(_profile.call(&"module_count", record_id))


func _bag_size(base_id: StringName) -> int:
	return (_profile.call(&"instances_of", base_id) as Array).size()


func _groups(hull: StringName = VANGUARD) -> Array:
	return _profile.call(&"battery_groups", hull)


func _stored(hull: StringName = VANGUARD) -> Array:
	return _profile.call(&"batteries").get(String(hull), [])


## A fit with the named cells set to one base id, for a `fit_legal` reading the test computes
## rather than one it invents.
func _with_cells(fit: Dictionary, indices: Array, base_id: StringName) -> Dictionary:
	var out: Dictionary = fit.duplicate(true)
	var cells: Array = out[WEAPON_SLOT]
	for index: int in indices:
		while cells.size() <= index:
			cells.append("")
		cells[index] = String(base_id)
	out[WEAPON_SLOT] = cells
	return out


func _credits_value() -> int:
	return int(_profile.call(&"credits"))


func _delete_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


## --------------------------------------------------- the bulk wrappers (S4, rules 7-8)


## Rule 7: the batch pairs the base's in-bag instances into the cells **in ascending order**,
## one per cell, and every instance is out of the bag while it is fitted. The delivered
## base-keyed module the first cell displaced comes back as its own unit.
func test_fit_battery_pairs_the_bags_instances_into_ascending_cells() -> void:
	_seed_standard_fit()
	var instances: Array[StringName] = []
	for _index in VANGUARD_W_CELLS:
		instances.append(_instance(LASER))
	assert_eq(_bag_size(LASER), 3, "three laser instances in the bag")
	assert_true(
		bool(_profile.call(&"fit_battery", VANGUARD, LASER, [0, 1, 2])),
		"the batch fills the battery's three cells"
	)
	assert_eq(
		_cells(),
		[String(instances[0]), String(instances[1]), String(instances[2])],
		"the three instances filled W1..W3 in creation order"
	)
	for instance: StringName in instances:
		assert_eq(_module_count(instance), 0, "every instance is out of the bag while fitted")
	assert_eq(_bag_size(LASER), 1, "the displaced delivered module is the one bag instance")
	assert_eq(_credits_value(), START_CREDITS, "and the batch costs nothing")


## Rule 8: `clear_battery` empties **exactly** the cells of the named base, leaving another
## base's cells alone, and hands every instance back as itself.
func test_clear_battery_empties_only_the_named_bases_cells() -> void:
	var laser := _instance(LASER)
	var cannon := _instance(CANNON)
	assert_true(
		bool(_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 0, laser)), "a laser in W1"
	)
	assert_true(
		bool(_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 2, cannon)), "a cannon in W3"
	)
	assert_true(bool(_profile.call(&"clear_battery", VANGUARD, LASER)), "the laser battery clears")
	assert_eq(String(_cells()[0]), "", "W1 is empty")
	assert_eq(String(_cells()[2]), String(cannon), "and W3's cannon is untouched")
	assert_eq(_module_count(laser), 1, "the laser instance came back as itself")
	assert_eq(_module_count(cannon), 0, "the cannon is still fitted")
	assert_false(
		bool(_profile.call(&"clear_battery", VANGUARD, LASER)),
		"a base the hull no longer holds has nothing to clear"
	)


## Rule 7's instance-count guard: a bag that carries fewer instances than the index list
## names is refused **before** the first cell, so nothing is written at all.
func test_a_bag_that_cannot_cover_the_cells_is_refused() -> void:
	_seed_standard_fit()
	_instance(LASER)
	var fit_before: Dictionary = _profile.call(&"fit_for", FIT_HULL)
	var bag_before: Dictionary = _profile.call(&"modules")
	assert_false(
		bool(_profile.call(&"fit_battery", FIT_HULL, LASER, [0, 1])),
		"one instance cannot cover a two-barrel battery"
	)
	assert_eq(_profile.call(&"fit_for", FIT_HULL), fit_before, "and the hull's fit is untouched")
	assert_eq(_profile.call(&"modules"), bag_before, "and so is the bag")


## Rules 7-8: a batch whose **third** cell is refused rolls the whole thing back - the fit and
## the bag both, through the public `set_fit`/`set_modules`. The refusal is measured, not
## assumed: two railguns fit this hull's budget and three do not, so the batch necessarily
## wrote two cells before it was refused, and a fit-only rollback would leave their two
## instances stranded at `count` 0 (the L80 class).
func test_a_refused_batch_restores_the_fit_and_the_bag() -> void:
	_seed_standard_fit()
	var instances: Array[StringName] = []
	for _index in VANGUARD_W_CELLS:
		instances.append(_instance(RAILGUN))
	var fit_before: Dictionary = _profile.call(&"fit_for", VANGUARD)
	var bag_before: Dictionary = _profile.call(&"modules")
	var fits_before: Dictionary = _fits()
	assert_false(
		bool(_profile.call(&"fit_battery", VANGUARD, RAILGUN, [0, 1, 2])),
		"three railguns are over the Cutter's power budget"
	)
	assert_eq(_profile.call(&"fit_for", VANGUARD), fit_before, "the fit is byte-identical")
	assert_eq(_profile.call(&"modules"), bag_before, "and so is the bag: no stranded instance")
	assert_eq(_fits(), fits_before, "and the stored-fit set did not grow")
	for instance: StringName in instances:
		assert_eq(_module_count(instance), 1, "every instance is still in the bag")


## The guards that answer before the first write: a hull with no W cells, an index outside
## `0 .. slot_capacity-1`, a repeated index, an empty list and a W-less hull. None of them
## touches the fit or the bag.
func test_the_batchs_guards_write_nothing() -> void:
	_seed_standard_fit()
	_instance(LASER)
	var fit_before: Dictionary = _profile.call(&"fit_for", VANGUARD)
	assert_false(bool(_profile.call(&"fit_battery", VANGUARD, LASER, [])), "an empty list")
	assert_false(bool(_profile.call(&"fit_battery", VANGUARD, LASER, [0, 0])), "a repeated cell")
	assert_false(
		bool(_profile.call(&"fit_battery", VANGUARD, LASER, [VANGUARD_W_CELLS])),
		"an index past the hull's W cells"
	)
	assert_false(bool(_profile.call(&"fit_battery", VANGUARD, LASER, [-1])), "a negative index")
	assert_false(bool(_profile.call(&"fit_battery", &"ship_npc", LASER, [0])), "a hull outside the nine")
	assert_false(bool(_profile.call(&"fit_battery", VANGUARD, &"", [0])), "no base id at all")
	assert_false(bool(_profile.call(&"clear_battery", VANGUARD, &"")), "and a clear with no base")
	assert_eq(_profile.call(&"fit_for", VANGUARD), fit_before, "nothing was written")


## ---------------------------------------------------------------------- the refusal copy


## Rule 9: ARMORY's three literals are byte-equivalent to the FITTING pane's own (the L116
## precedent, since no wave owns both files), and the mandatory one is carried for the set's
## completeness only - it is unreachable for a W cell and no test asserts it through a
## battery. `FitData.MANDATORY_SLOT_KEYS` is the measurement behind that.
func test_the_three_refusal_literals_are_byte_equivalent_to_fitting_panel() -> void:
	assert_eq(
		PanelScript.REFUSAL_OVERLOAD, FittingPanelScript.REFUSAL_OVERLOAD, "the overload line"
	)
	assert_eq(
		PanelScript.REFUSAL_MANDATORY, FittingPanelScript.REFUSAL_MANDATORY, "the mandatory line"
	)
	assert_eq(
		PanelScript.REFUSAL_FIT_ILLEGAL, FittingPanelScript.REFUSAL_FIT_ILLEGAL, "the catch-all"
	)
	assert_eq(
		PanelScript.REFUSAL_MANDATORY,
		"MANDATORY CELL — SWAP ONLY, NEVER EMPTY",
		"byte for byte, em dash and all"
	)
	assert_eq(PanelScript.REFUSAL_OVERLOAD, "%d / %d PWR — OVER BY %d", "09 section 2's format")
	assert_false(
		FitData.MANDATORY_SLOT_KEYS.has(WEAPON_SLOT),
		"a W cell is never mandatory, which is why the wording is unreachable here"
	)
	assert_eq(
		FitData.MANDATORY_SLOT_KEYS.size(), 2, "the mandatory set is the engines and the reactor"
	)


## The overload line renders with `fit_legal`'s own numbers: a railgun battery the hull cannot
## power is over by exactly the difference the arithmetic states, and the wording is the
## pane's constant.
func test_the_overload_line_renders_fit_legals_own_numbers() -> void:
	_seed_standard_fit()
	var candidate := _with_cells(
		FitData.standard_fit(VANGUARD), [0, 1, 2], RAILGUN
	)
	var legal := FitData.fit_legal(VANGUARD, candidate)
	assert_false(bool(legal[&"legal"]), "three railguns are illegal on the Cutter")
	var power: Dictionary = legal[&"power"]
	assert_false(bool(power[&"legal"]), "and it is the power budget that refuses them")
	var draws := int(power[&"draw"])
	var out := int(power[&"out"])
	assert_true(draws > out, "the measured overload is %d over %d" % [draws, out])
	assert_eq(
		PanelScript.REFUSAL_OVERLOAD % [draws, out, draws - out],
		"%d / %d PWR — OVER BY %d" % [draws, out, draws - out],
		"the pane's constant renders `fit_legal`'s own numbers"
	)
	assert_eq(
		PanelScript.REFUSAL_OVERLOAD % [13, 11, 2],
		"13 / 11 PWR — OVER BY 2",
		"and reproduces 09 section 2's own worked example"
	)


## ------------------------------------------------------- the rack record (S5, section 17)


## `battery_groups` is the derived read: the stored racks in their order, each one restricted
## to the cells the fit really holds, and one trailing rack for every fitted cell the record
## does not mention - so a fitted weapon always fires from exactly one rack.
func test_battery_groups_covers_every_fitted_cell_once() -> void:
	_seed_standard_fit()
	var laser := _instance(LASER)
	assert_true(
		bool(_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 1, laser)), "a laser in W2"
	)
	assert_eq(_groups(), [[0, 1]], "with no record, one derived rack holds both fitted cells")
	assert_true(
		bool(_profile.call(&"set_battery_groups", VANGUARD, [[0], [1]])), "two racks written"
	)
	assert_eq(_groups(), [[0], [1]], "the record's own racks, in its own order")
	assert_true(
		bool(_profile.call(&"set_battery_groups", VANGUARD, [[1], []])),
		"an interior empty rack is kept"
	)
	assert_eq(_stored(), [[1]], "a trailing empty one is dropped: it carries no identity")
	assert_eq(
		_groups(),
		[[1], [0]],
		"and the cell the record no longer mentions derives its own trailing rack"
	)
	assert_true(
		bool(_profile.call(&"set_battery_groups", VANGUARD, [[], []])), "an all-empty record"
	)
	assert_eq(_groups(), [[0, 1]], "leaves every fitted cell in the derived trailing rack")
	assert_eq(_stored(), [], "and stores nothing at all")


## A W cell is a W cell whatever is in it: a **family-less** module (`w_mining`, 09 section 4
## item 7 - a tool with no firing family) composes into a rack like any other, because the
## grouping law is the cell and only the trigger side is family-keyed.
func test_a_family_less_cell_composes_into_a_rack() -> void:
	_seed_standard_fit()
	var mining := _instance(MINING)
	assert_true(
		bool(_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 1, mining)),
		"the mining laser fits a W cell"
	)
	assert_eq(
		_groups(), [[0, 1]], "with no record yet, both fitted cells derive into one trailing rack"
	)
	assert_true(
		bool(_profile.call(&"set_battery_groups", VANGUARD, [[0, 1]])),
		"and a record may mix them"
	)
	assert_eq(_groups(), [[0, 1]], "into one rack")
	assert_eq(_profile.call(&"battery_groups", &"ship_npc"), [], "an NPC hull has no racks")
	assert_eq(
		_profile.call(&"battery_groups", &"ship_freighter"),
		[],
		"and a hulk whose delivered fit carries no weapon derives no rack"
	)


## `set_battery_groups` refuses junk outright - writing nothing - because the record is the
## author of rack identity: an index outside the hull's W cells, a cell in two racks, a
## non-array rack, or more racks than the input map can address.
func test_set_battery_groups_refuses_junk() -> void:
	_seed_standard_fit()
	assert_true(bool(_profile.call(&"set_battery_groups", VANGUARD, [[0]])), "a good write")
	assert_eq(_stored(), [[0]], "which the record keeps")
	## A cell that holds nothing is **in range and unique**, so the record keeps it - the
	## composition is the player's and the fit is the truth: the derived read drops the
	## reference (it is a stale one) rather than refusing the write.
	assert_true(
		bool(_profile.call(&"set_battery_groups", VANGUARD, [[1]])),
		"a cell the fit does not hold is still a legal reference"
	)
	assert_eq(_stored(), [[1]], "which the record keeps")
	assert_eq(
		_groups(),
		[[], [0]],
		"while the derived read drops the stale reference and keeps the fitted barrel"
	)
	assert_true(bool(_profile.call(&"set_battery_groups", VANGUARD, [[0]])), "back to the fitted cell")
	assert_false(
		bool(_profile.call(&"set_battery_groups", VANGUARD, [[VANGUARD_W_CELLS]])),
		"an index past the hull's W cells"
	)
	assert_false(bool(_profile.call(&"set_battery_groups", VANGUARD, [[0], [0]])), "a repeated cell")
	assert_false(bool(_profile.call(&"set_battery_groups", VANGUARD, [0])), "a rack that is not an array")
	assert_false(bool(_profile.call(&"set_battery_groups", &"ship_npc", [[0]])), "a hull outside the nine")
	var too_many: Array = []
	for _rack in PanelScript.RACK_COUNT + 1:
		too_many.append([0])
	assert_false(
		bool(_profile.call(&"set_battery_groups", VANGUARD, too_many)),
		"more racks than the input map addresses"
	)
	assert_eq(_stored(), [[0]], "every refusal left the record exactly as it was")


## The next free W cell is the lowest empty one, read off the fit the launch flies: a hull the
## account holds no stored fit for reserves the cell its delivered fit fills.
func test_free_weapon_cell_is_the_lowest_empty_cell() -> void:
	assert_eq(
		int(_profile.call(&"free_weapon_cell", VANGUARD)),
		1,
		"the delivered laser holds W1, so W2 is the next free cell"
	)
	_seed_standard_fit()
	assert_eq(int(_profile.call(&"free_weapon_cell", VANGUARD)), 1, "the stored standard fit agrees")
	assert_true(
		bool(_profile.call(&"set_fit_slot", VANGUARD, WEAPON_SLOT, 1, LASER)), "fill W2"
	)
	assert_true(
		bool(_profile.call(&"set_fit_slot", VANGUARD, WEAPON_SLOT, 2, LASER)), "and W3"
	)
	assert_eq(int(_profile.call(&"free_weapon_cell", VANGUARD)), -1, "a full battery has no free cell")
	## The Lancer's delivered fit (09 section 9) carries **two** lasers, so a fresh Lancer
	## has no free W cell: the delivered fit reserves them (the read is `resolved_fit`).
	assert_eq(
		int(_profile.call(&"free_weapon_cell", FIT_HULL)),
		-1,
		"the Lancer's delivered two-laser fit fills both of its W cells"
	)
	assert_eq(int(_profile.call(&"free_weapon_cell", &"ship_npc")), -1, "and an NPC hull has none")


## `fit_into_rack`, the drag's install: one weapon into the rack's next free W cell, recorded
## in that rack, atomically over the fit, the bag and the record.
func test_fit_into_rack_installs_and_records_the_cell() -> void:
	_seed_standard_fit()
	var instance := _instance(CANNON)
	assert_true(
		bool(_profile.call(&"fit_into_rack", VANGUARD, 1, 1, CANNON)),
		"a cannon into rack B2's next free cell, W2"
	)
	assert_eq(String(_cells()[1]), String(instance), "the bag's instance landed in W2")
	assert_eq(_module_count(instance), 0, "and left the bag")
	assert_eq(
		_stored(),
		[[0], [1]],
		"while the record names rack B2 and its cell - and materialises B1's derived barrel"
	)
	assert_eq(_groups(), [[0], [1]], "so the derived racks are B1's delivered laser and B2's cannon")
	assert_eq(_credits_value(), START_CREDITS, "installing is free at the station")


## And its refusals, every one of which writes nothing at all: a rack outside `B1..B7`, a base
## that is not a weapon module, a bag that holds none of it, a cell that already holds a
## weapon (a drag onto a barrel is a move, not an install) and a candidate fit that is illegal.
func test_fit_into_rack_refuses_without_writing() -> void:
	_seed_standard_fit()
	var instance := _instance(RAILGUN)
	var spare := _instance(RAILGUN)
	## The Cutter's budget is 8 (08 section 2 plus `p_std`'s zero) and the delivered fit
	## spends 3 of it, so one railgun fits into W2 and a second does not - which makes the
	## second install this test's over-budget candidate.
	assert_true(
		bool(_profile.call(&"fit_into_rack", VANGUARD, 0, 1, RAILGUN)), "one railgun fits W2"
	)
	var fit_before: Dictionary = _profile.call(&"fit_for", VANGUARD)
	var bag_before: Dictionary = _profile.call(&"modules")
	assert_false(
		bool(_profile.call(&"fit_into_rack", VANGUARD, PanelScript.RACK_COUNT, 1, RAILGUN)),
		"a rack past B7"
	)
	assert_false(bool(_profile.call(&"fit_into_rack", VANGUARD, -1, 1, RAILGUN)), "and a negative one")
	assert_false(
		bool(_profile.call(&"fit_into_rack", VANGUARD, 0, 1, &"p_std")), "a module that is not a weapon"
	)
	assert_false(
		bool(_profile.call(&"fit_into_rack", VANGUARD, 0, 1, &"w_cannon")), "a base the bag holds none of"
	)
	assert_false(
		bool(_profile.call(&"fit_into_rack", VANGUARD, 0, 0, RAILGUN)), "a cell that already holds a weapon"
	)
	assert_false(
		bool(_profile.call(&"fit_into_rack", VANGUARD, 0, 2, RAILGUN)),
		"a second railgun is over the Cutter's budget"
	)
	assert_eq(_profile.call(&"fit_for", VANGUARD), fit_before, "the fit is untouched")
	assert_eq(_profile.call(&"modules"), bag_before, "the bag is untouched")
	assert_eq(
		_stored(),
		[[0, 1]],
		"and the refused cell is in no rack: B1 still names only the two cells it held"
	)
	assert_eq(_module_count(instance), 0, "the instance the install paired is the fitted one")
	assert_eq(_module_count(spare), 1, "and the spare never left the bag: the refusal spent nothing")
	assert_eq(_bag_size(RAILGUN), 1, "one railgun instance in the bag either way")


## `clear_rack_cell`, the `✕`: the cell empties, the barrel returns, and the record drops the
## reference - including from a rack that is not the one the cell sits in (the record is the
## authority, the fit is the truth).
func test_clear_rack_cell_returns_the_barrel_and_drops_the_ref() -> void:
	_seed_standard_fit()
	var instance := _instance(CANNON)
	assert_true(bool(_profile.call(&"fit_into_rack", VANGUARD, 2, 1, CANNON)), "a cannon into B3")
	assert_eq(_stored(), [[0], [], [1]], "B3 holds it, beside B1's derived barrel")
	assert_true(bool(_profile.call(&"clear_rack_cell", VANGUARD, 1)), "the barrel comes out")
	assert_eq(String(_cells()[1]), "", "the cell is empty")
	assert_eq(_module_count(instance), 1, "and the instance is back in the bag")
	assert_eq(_stored(), [[0]], "its rack leaves the record, B1's barrel stays referenced")
	assert_true(bool(_profile.call(&"clear_rack_cell", VANGUARD, 0)), "and the delivered laser comes out")
	assert_eq(_stored(), [], "so the record is empty again")
	assert_false(bool(_profile.call(&"clear_rack_cell", VANGUARD, 1)), "an empty cell has no barrel")
	assert_false(
		bool(_profile.call(&"clear_rack_cell", VANGUARD, VANGUARD_W_CELLS)), "and no cell past the hull"
	)
	assert_eq(_stored(), [], "both refusals wrote nothing")


## The within-rack drag re-orders (no fit write: the barrel keeps its cell and gains a new
## place in the rack's own order).
func test_move_rack_cell_reorders_within_a_rack() -> void:
	_seed_standard_fit()
	for _index in VANGUARD_W_CELLS:
		_instance(LASER)
	assert_true(bool(_profile.call(&"fit_battery", VANGUARD, LASER, [0, 1, 2])), "three barrels")
	assert_true(
		bool(_profile.call(&"set_battery_groups", VANGUARD, [[0, 1, 2]])), "one rack holds all three"
	)
	assert_true(bool(_profile.call(&"move_rack_cell", VANGUARD, 0, 2, 0, 0)), "the last barrel to the front")
	assert_eq(_stored(), [[2, 0, 1]], "the rack re-ordered, the cells untouched")
	var fit_before: Dictionary = _profile.call(&"fit_for", VANGUARD)
	assert_false(
		bool(_profile.call(&"move_rack_cell", VANGUARD, 0, 0, 0, 0)), "the same address twice"
	)
	assert_false(bool(_profile.call(&"move_rack_cell", VANGUARD, 0, 9, 0, 0)), "a barrel that is not there")
	assert_false(bool(_profile.call(&"move_rack_cell", VANGUARD, 0, 0, 9, 0)), "a rack past B7")
	assert_eq(_stored(), [[2, 0, 1]], "every refusal wrote nothing")
	assert_eq(_profile.call(&"fit_for", VANGUARD), fit_before, "and no fit moved")


## The between-rack drag moves a barrel and, when it lands on an occupied place, **swaps**:
## the displaced barrel takes the dragged one's old place.
func test_move_rack_cell_moves_and_swaps_between_racks() -> void:
	_seed_standard_fit()
	_instance(LASER)
	var cannon := _instance(CANNON)
	assert_true(
		bool(_profile.call(&"fit_module_at", VANGUARD, WEAPON_SLOT, 1, cannon)), "a cannon in W2"
	)
	assert_true(bool(_profile.call(&"set_battery_groups", VANGUARD, [[0], [1]])), "two racks")
	assert_true(bool(_profile.call(&"move_rack_cell", VANGUARD, 0, 0, 1, 1)), "the laser to B2's end")
	assert_eq(_stored(), [[], [1, 0]], "B2 now holds the cannon and then the laser")
	assert_true(bool(_profile.call(&"move_rack_cell", VANGUARD, 1, 1, 1, 0)), "and the laser back to B2's front")
	assert_eq(_stored(), [[], [0, 1]], "which re-orders inside the one rack")
	assert_true(
		bool(_profile.call(&"set_battery_groups", VANGUARD, [[0], [1]])), "back to one barrel each"
	)
	assert_true(bool(_profile.call(&"move_rack_cell", VANGUARD, 0, 0, 1, 0)), "B1's laser onto B2's cannon")
	assert_eq(_stored(), [[1], [0]], "the two swapped racks: the cannon took B1")
	assert_eq(_groups(), [[1], [0]], "and the derived racks read the same")


## The rack ceiling is the input map's own count (`GROUPS_MAX`, 7 since S5), one source for
## the pane, the record and the component.
func test_the_rack_ceiling_is_the_groups_max() -> void:
	assert_eq(PanelScript.RACK_COUNT, WeaponComponent.GROUPS_MAX, "the pane draws what the map addresses")
	assert_eq(WeaponComponent.GROUPS_MAX, 7, "and the map is seven keys wide since S5")


## The bag figure every rack read-out shows and every install spends from is the base's in-bag
## **instances**, read through `PlayerProfile.instances_of` (CONTRACTS section 16 rule 7): one
## entry per record, which is exactly the number of cells one batch can pair. A record the bag
## *stacks* (`count` 2) is one instance and one cell.
func test_the_bag_figure_is_the_bases_in_bag_instances() -> void:
	_profile.call(&"add_module", LASER, 2)
	assert_eq(_bag_size(LASER), 1, "two units in one record are one instance")
	assert_eq(_module_count(LASER), 2, "while the record's own count is two")
	_instance(LASER)
	assert_eq(_bag_size(LASER), 2, "a second instance is a second cell's worth")


## --------------------------------------------------------- the record on disk (save v7)


## The record is persisted: a rack write, a flush and a reload read the same racks back, and
## the file is at save v7 (CONTRACTS section 17).
func test_the_record_persists_at_save_v7() -> void:
	_seed_standard_fit()
	_instance(CANNON)
	assert_true(bool(_profile.call(&"fit_into_rack", VANGUARD, 1, 1, CANNON)), "a cannon into B2")
	assert_eq(_stored(), [[0], [1]], "the install recorded the cell in B2 beside B1's derived barrel")
	assert_true(bool(_profile.call(&"set_battery_groups", VANGUARD, [[0], [1], []])), "and an empty B3")
	assert_eq(_stored(), [[0], [1]], "which the normaliser drops")
	_profile.call(&"flush")
	var on_disk := ConfigFile.new()
	assert_eq(on_disk.load(PROFILE_PATH), OK, "the scratch file reads back")
	assert_eq(int(on_disk.get_value("profile", "save_version", 0)), 7, "a write persists save v7")
	_profile.call(&"reload")
	assert_eq(_stored(), [[0], [1]], "the racks survive the round trip, trailing empties dropped")
	assert_eq(_groups(), [[0], [1]], "and the derived read agrees with what was written")
