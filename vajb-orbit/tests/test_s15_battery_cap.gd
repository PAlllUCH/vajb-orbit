extends McpTestSuite
## Suite s15_battery_cap: wave S15's battery hardcap (09 section 12) at the profile
## level -- **five batteries of at most four cells** (AC1-AC3), with no pane mounted.
##
## The rules this suite measures, one test each:
##
##  - **AC1** -- `GROUPS_MAX` is 5 and the new `BATTERY_CELLS_MAX` is 4; composing a 6th
##    battery or a 5th cell in one is **refused through the existing transaction shape**
##    and writes nothing at all: `set_battery_groups` (the record's own write),
##    `fit_into_rack` (the drag's install) and `move_rack_cell` (the drag's move) each
##    leave the record, the fit and the bag byte-identical.
##  - **AC2** -- the 7-W-cell Obliterator composes **4 + 3** (B1's four cells and B2's
##    three), and the hull's own W-cell count is untouched: the cap is per battery.
##  - **AC3** -- a save carrying a pre-S15 record (7 groups, or one rack over four cells)
##    **loads clamped**, cell order preserved, and nothing outside the record moves; a
##    second reload is inert.
##
## The pane's own surface (the five bays, the drop zones' refusals, the plate fit) is
## `tests/test_s15_armory_layout.gd`'s, and the launch's read-back is
## `tests/test_p2a_launch_fit.gd`'s moved row.
##
## The profile is the shipped autoload, borrowed the way `test_s4_batteries.gd` borrows it:
## `save_path` is repointed at a scratch file before the first mutation, every borrowed
## field is handed back in `suite_teardown` and flushed while the scratch path is still in
## place, so the owner's `user://profile.cfg` is never written.

const PanelScript := preload("res://ui/station/armory_panel.gd")
const FitData := preload("res://game/ship_fit.gd")
const WeaponData := preload("res://game/weapons.gd")

const PROFILE_PATH := "user://test_s15_battery_cap.cfg"
const SECTION := "profile"

## The 7-W-cell capital (09 section 9's Obliterator): the only hull that can show the
## per-battery cap without the hull's own matrix refusing first.
const CAPITAL: StringName = &"ship_destroyer"
const CAPITAL_W_CELLS := 7
const WEAPON_SLOT: StringName = &"weapons"
const LASER: StringName = &"w_laser"
const CANNON: StringName = &"w_cannon"
const START_CREDITS := 10000

var _profile: Node = null
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_credits := 0
var _previous_fits: Dictionary = {}
var _previous_owned: Array = []
var _previous_modules: Dictionary = {}
var _previous_ammo: Dictionary = {}
var _previous_batteries: Dictionary = {}


func suite_name() -> String:
	return "s15_battery_cap"


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
	_previous_ammo = (_profile.get(&"_ammo") as Dictionary).duplicate(true)
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
	_profile.set(&"_batteries", _previous_batteries)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	_delete_file(PROFILE_PATH)
	_profile = null


## The fixture account: the capital active and owned, its delivered fit's W cells filled
## with alternating laser/cannon **except cell 4** (left free, so a refused install's
## reason is the battery's cap and never the cell being taken), and two spare lasers in
## the bag (so an install that is *not* refused has something to spend).
func setup() -> void:
	var owned: Array[StringName] = [CAPITAL]
	_profile.set(&"_credits", START_CREDITS)
	_profile.set(&"_active_ship", CAPITAL)
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_ammo", {})
	_profile.set(&"_batteries", {})
	_capital_fit(false)


## Write the capital's fit through the profile: the delivered fit's own engines/power,
## with `sparse` leaving W cell 4 empty (the refusal test) or filling all seven (the
## composition test).
func _capital_fit(sparse: bool) -> void:
	var fit: Dictionary = FitData.standard_fit(CAPITAL)
	var capacity := FitData.slot_capacity(CAPITAL, WEAPON_SLOT)
	var weapons: Array = []
	for index in capacity:
		if sparse and index == 4:
			weapons.append("")
			continue
		weapons.append("w_laser" if index % 2 == 0 else "w_cannon")
	fit[WEAPON_SLOT] = weapons
	assert_true(bool(_profile.call(&"set_fit", CAPITAL, fit)), "the fixture fit installs")
	_profile.call(&"add_module", LASER, 2)


## One hull's stored racks, raw.
func _stored() -> Array:
	var record: Dictionary = _profile.call(&"batteries")
	return record.get(String(CAPITAL), [])


## The account as a refusal must leave it: the record, the fit and the bag together.
func _snapshot() -> Dictionary:
	return {
		&"record": _profile.call(&"batteries"),
		&"fit": _profile.call(&"fit_for", CAPITAL),
		&"bag": _profile.call(&"modules"),
	}


func _delete_file(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


## ------------------------------------------------------------- AC1: the ceilings

## AC1: the hardcap's two numbers are `game/weapons.gd`'s, and the pane draws exactly the
## batteries the input map addresses.
func test_the_hardcap_is_five_batteries_of_four_cells() -> void:
	assert_eq(WeaponData.GROUPS_MAX, 5, "GROUPS_MAX 7 -> 5 (09 section 12)")
	assert_eq(WeaponData.BATTERY_CELLS_MAX, 4, "and the new per-battery ceiling is four")
	assert_eq(PanelScript.RACK_COUNT, WeaponData.GROUPS_MAX, "the pane draws what the map addresses")
	assert_eq(FitData.slot_capacity(CAPITAL, WEAPON_SLOT), CAPITAL_W_CELLS, "the capital's seven W cells")


## --------------------------------------------------- AC1: the refusals write nothing

## AC1's rule 1: a 6th battery, a 5th cell in one rack, and a move into a full rack are all
## refused through the existing transactions, and every refusal leaves the record, the fit
## and the bag exactly as they were.
func test_a_sixth_battery_and_a_fifth_cell_are_refused_silently() -> void:
	_capital_fit(true)
	## A legal five-battery record to start from: five single-cell batteries, the fifth
	## holding cell 5.
	assert_true(
		bool(_profile.call(&"set_battery_groups", CAPITAL, [[0], [1], [2], [3], [5]])),
		"five batteries compose"
	)
	assert_eq(_stored().size(), 5, "and the record keeps all five")
	var before := _snapshot()
	## A 6th battery: one rack past `GROUPS_MAX`.
	assert_false(
		bool(_profile.call(&"set_battery_groups", CAPITAL, [[0], [1], [2], [3], [5], [6]])),
		"a sixth battery is refused"
	)
	assert_eq(_snapshot(), before, "and the refusal wrote nothing")
	## A 5th cell in one battery: one rack past `BATTERY_CELLS_MAX`.
	assert_false(
		bool(_profile.call(&"set_battery_groups", CAPITAL, [[0, 1, 2, 3, 5]])),
		"a fifth cell in one battery is refused"
	)
	assert_eq(_snapshot(), before, "and that refusal wrote nothing either")
	## The drag's install: cell 4 is free, the bag holds a laser, and B1 already holds
	## four cells -- so the only thing that can refuse is the battery's own cap.
	assert_true(
		bool(_profile.call(&"set_battery_groups", CAPITAL, [[0], [1], [2], [3], [5]])),
		"a fresh five-battery record"
	)
	assert_true(
		bool(_profile.call(&"set_battery_groups", CAPITAL, [[0, 1, 2, 3], [5]])),
		"B1 filled to its four cells"
	)
	before = _snapshot()
	assert_false(
		bool(_profile.call(&"fit_into_rack", CAPITAL, 0, 4, LASER)),
		"the fifth cell is refused by `fit_into_rack`"
	)
	assert_eq(_snapshot(), before, "with the fit, the bag and the record untouched")
	## The drag's move: an **append** into the four-cell battery would grow it past the
	## cap, so the profile refuses it and writes nothing.
	assert_false(
		bool(_profile.call(&"move_rack_cell", CAPITAL, 1, 0, 0, 4)),
		"a move that would grow the full battery is refused"
	)
	assert_eq(_snapshot(), before, "and writes nothing")
	## A **swap** onto an occupied position leaves the target's length alone, so it stays
	## legal even into a four-cell battery.
	assert_true(
		bool(_profile.call(&"move_rack_cell", CAPITAL, 1, 0, 0, 0)),
		"a swap into the full battery is legal (it never grows it)"
	)
	assert_eq(
		_profile.call(&"battery_groups", CAPITAL), [[5, 1, 2, 3], [0], [6]],
		"and the swap landed inside the cap (cell 6 keeps its trailing battery)"
	)
	assert_true(
		bool(_profile.call(&"set_battery_groups", CAPITAL, [[0, 1, 2, 3], [5]])),
		"back to B1's four cells"
	)
	## Positive control: another cell in a battery with room is accepted.
	assert_true(
		bool(_profile.call(&"fit_into_rack", CAPITAL, 1, 4, LASER)),
		"a cell into a battery with room installs"
	)
	assert_eq(
		_profile.call(&"battery_groups", CAPITAL), [[0, 1, 2, 3], [5, 4], [6]],
		"and the derived racks follow the record"
	)


## ------------------------------------------------------------------ AC2: the 4 + 3

## AC2: a 7-W-cell hull with no stored record composes **4 + 3** -- the cap chunks the
## derived tail -- and the hull's own W-cell count never moves.
func test_the_seven_cell_hull_composes_four_plus_three() -> void:
	_capital_fit(false)
	assert_eq(int((_profile.call(&"fit_for", CAPITAL) as Dictionary)[WEAPON_SLOT].size()), 7, "seven cells fitted")
	assert_eq(
		_profile.call(&"battery_groups", CAPITAL),
		[[0, 1, 2, 3], [4, 5, 6]],
		"the hardcap composes the seven cells as 4 + 3"
	)
	assert_eq(FitData.slot_capacity(CAPITAL, WEAPON_SLOT), CAPITAL_W_CELLS, "the hull's own W cells are unchanged")
	## Every fitted cell still fires from exactly one battery (CONTRACTS section 16).
	var covered: Array = []
	for rack: Variant in (_profile.call(&"battery_groups", CAPITAL) as Array):
		covered.append_array(rack as Array)
	covered.sort()
	assert_eq(covered, [0, 1, 2, 3, 4, 5, 6] as Array[int], "and every cell is claimed once")


## ------------------------------------------------------------------- AC3: the clamp

## AC3: a v7 save whose record carries **seven groups** loads as five, cell order
## preserved, and nothing outside the record moves. The two overflow cells leave the
## record but stay in the fit; the derived read **folds** them into a rack the clamp left
## with room (F3's root fix), so every fitted gun still fires from exactly one rack.
func test_a_seven_group_save_loads_clamped_with_order_preserved() -> void:
	var fixture := ConfigFile.new()
	fixture.set_value(SECTION, "save_version", 7)
	fixture.set_value(SECTION, "credits", 4321)
	fixture.set_value(SECTION, "owned_ships", [String(CAPITAL)])
	fixture.set_value(SECTION, "active_ship", String(CAPITAL))
	fixture.set_value(SECTION, "modules", {})
	var fit: Dictionary = FitData.standard_fit(CAPITAL)
	fit[WEAPON_SLOT] = ["w_laser", "w_cannon", "w_laser", "w_cannon", "w_laser", "w_cannon", "w_laser"]
	fixture.set_value(SECTION, "fits", {String(CAPITAL): fit})
	## The pre-S15 record: seven groups, in order, one cell each.
	fixture.set_value(SECTION, "batteries", {String(CAPITAL): [[0], [1], [2], [3], [4], [5], [6]]})
	assert_eq(fixture.save(PROFILE_PATH), OK, "the seven-group file is written")
	_profile.call(&"reload")
	assert_eq(_stored(), [[0], [1], [2], [3], [4]], "seven groups clamp to five, in order")
	assert_eq(
		_profile.call(&"battery_groups", CAPITAL), [[0, 5, 6], [1], [2], [3], [4]],
		"and the derived read folds the overflow cells into a rack with room"
	)
	assert_eq(int(_profile.call(&"credits")), 4321, "the clamp touched nothing outside the record")
	assert_eq(
		int((_profile.call(&"fit_for", CAPITAL) as Dictionary)[WEAPON_SLOT].size()), 7,
		"the fit still carries all seven cells"
	)
	## The clamp is a *load* path read: a second reload is inert (still clamped, no growth).
	var once: Dictionary = _profile.call(&"batteries")
	_profile.call(&"reload")
	assert_eq(_profile.call(&"batteries"), once, "a second load changes nothing")
	## A real write persists the clamped record, so the store cannot grow the 6th back.
	_profile.call(&"flush")
	var written := ConfigFile.new()
	assert_eq(written.load(PROFILE_PATH), OK, "the store reads back")
	assert_eq(
		(written.get_value(SECTION, "batteries", {}) as Dictionary).get(String(CAPITAL), []),
		[[0], [1], [2], [3], [4]],
		"and the persisted record is the clamped one"
	)


## AC3's second half: one rack longer than four cells clamps **cell by cell**, order
## preserved, and the surplus cell falls to a trailing derived battery rather than being
## lost (09 section 12's "overflow guns are re-readable").
func test_a_five_cell_rack_clamps_to_four_cells_in_order() -> void:
	var fixture := ConfigFile.new()
	fixture.set_value(SECTION, "save_version", 7)
	fixture.set_value(SECTION, "credits", 2500)
	fixture.set_value(SECTION, "owned_ships", [String(CAPITAL)])
	fixture.set_value(SECTION, "active_ship", String(CAPITAL))
	fixture.set_value(SECTION, "modules", {})
	var fit: Dictionary = FitData.standard_fit(CAPITAL)
	fit[WEAPON_SLOT] = ["w_laser", "w_cannon", "w_laser", "w_cannon", "w_laser", "w_cannon", "w_laser"]
	fixture.set_value(SECTION, "fits", {String(CAPITAL): fit})
	fixture.set_value(SECTION, "batteries", {String(CAPITAL): [[0, 1, 2, 3, 4], [5], [6]]})
	assert_eq(fixture.save(PROFILE_PATH), OK, "the over-long-rack file is written")
	_profile.call(&"reload")
	assert_eq(
		_stored(), [[0, 1, 2, 3], [5], [6]],
		"the five-cell rack clamps to its first four, in cell order"
	)
	assert_eq(
		_profile.call(&"battery_groups", CAPITAL),
		[[0, 1, 2, 3], [5], [6], [4]],
		"and the surplus cell 4 lands in a trailing derived battery, never lost"
	)
	assert_eq(int(_profile.call(&"credits")), 2500, "nothing outside the record moved")
