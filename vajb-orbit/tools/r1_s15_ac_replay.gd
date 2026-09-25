extends SceneTree
## S15-R1's independent AC replay (W8 method): measures the wave's claims through
## the shipped seam instead of trusting the builder's suite.
##
##   XDG_DATA_HOME=/tmp/s15r1 "$GODOT_CONSOLE" --headless --path "$VAJB_PROJ" \
##     --script res://tools/r1_s15_ac_replay.gd
##
## AC1 -- GROUPS_MAX 5 / BATTERY_CELLS_MAX 4; a 6th battery and a 5th cell refuse and
##        leave the persisted bytes identical.
## AC2 -- an empty-record 7-cell hull composes 4+3; and the 5-stored-rack shape is
##        measured for the derived-read invariant (a fitted weapon is never rackless).
## AC3 -- a v7 file with a 7-group record loads clamped, order preserved, nothing else
##        moves.

const ProfileScript := preload("res://autoload/player_profile.gd")
const FitData := preload("res://game/ship_fit.gd")
const WeaponData := preload("res://game/weapons.gd")

const TAG := "[S15R1]"
const CAPITAL: StringName = &"ship_destroyer"
const WEAPON_SLOT: StringName = &"weapons"
const LASER: StringName = &"w_laser"
const CANNON: StringName = &"w_cannon"
const SAVE_PATH := "user://r1_s15_ac_replay.cfg"

var _failures: Array[String] = []
var _profile: Node = null


func _init() -> void:
	_profile = ProfileScript.new() as Node
	_profile.set(&"save_path", SAVE_PATH)
	get_root().add_child(_profile)
	_delete_file(SAVE_PATH)
	_ac1()
	_ac2()
	_ac3()
	print("%s done failures=%d" % [TAG, _failures.size()])
	_profile.free()
	quit(1 if not _failures.is_empty() else 0)


func _check(name: String, ok: bool, detail: String) -> void:
	if ok:
		print("%s ok   %s - %s" % [TAG, name, detail])
	else:
		print("%s FAIL %s - %s" % [TAG, name, detail])
		_failures.append(name)


func _delete_file(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


## The whole persisted account, written out, so "refused silently" is the bytes.
func _bytes() -> PackedByteArray:
	_profile.call(&"save")
	return FileAccess.get_file_as_bytes(SAVE_PATH)


## The account's state read back from the file: the record, the fits and the bag.
func _state() -> Dictionary:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	return {
		&"batteries": config.get_value(&"profile", &"batteries", {}),
		&"fits": config.get_value(&"profile", &"fits", {}),
		&"modules": config.get_value(&"profile", &"modules", {}),
		&"credits": config.get_value(&"profile", &"credits", 0),
	}


func _fixture(record: Array, sparse: bool) -> void:
	var fit: Dictionary = FitData.standard_fit(CAPITAL)
	var capacity := FitData.slot_capacity(CAPITAL, WEAPON_SLOT)
	var weapons: Array = []
	for index in capacity:
		if sparse and index == 4:
			weapons.append("")
			continue
		weapons.append(String(LASER) if index % 2 == 0 else String(CANNON))
	fit[WEAPON_SLOT] = weapons
	_profile.set(&"_credits", 10000)
	_profile.set(&"_active_ship", CAPITAL)
	var owned: Array[StringName] = [CAPITAL]
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_ammo", {})
	_profile.set(&"_batteries", {})
	_check("fixture_fit", bool(_profile.call(&"set_fit", CAPITAL, fit)), "the capital fit installs")
	_profile.call(&"add_module", LASER, 3)
	_delete_file(SAVE_PATH)
	if not record.is_empty():
		_check(
			"fixture_record", bool(_profile.call(&"set_battery_groups", CAPITAL, record)),
			"the fixture record writes: %s" % str(record)
		)


## ------------------------------------------------------------------------- AC1


func _ac1() -> void:
	_check(
		"ac1_groups_max", WeaponData.GROUPS_MAX == 5,
		"weapons.gd GROUPS_MAX=%d" % WeaponData.GROUPS_MAX
	)
	_check(
		"ac1_cells_max", WeaponData.BATTERY_CELLS_MAX == 4,
		"weapons.gd BATTERY_CELLS_MAX=%d" % WeaponData.BATTERY_CELLS_MAX
	)
	_fixture([[0], [1], [2], [3], [5]], true)
	var before := _bytes()
	var refused_sixth := not bool(
		_profile.call(&"set_battery_groups", CAPITAL, [[0], [1], [2], [3], [5], [6]])
	)
	_check("ac1_sixth_battery_refused", refused_sixth, "a 6-rack write answers false")
	_check("ac1_sixth_wrote_nothing", _bytes() == before, "persisted bytes unchanged")
	var refused_fifth := not bool(
		_profile.call(&"set_battery_groups", CAPITAL, [[0, 1, 2, 3, 5]])
	)
	_check("ac1_fifth_cell_refused", refused_fifth, "a 5-cell rack write answers false")
	_check("ac1_fifth_wrote_nothing", _bytes() == before, "persisted bytes unchanged")
	_check(
		"ac1_record_still_five",
		_profile.call(&"battery_groups", CAPITAL) == [[0], [1], [2], [3], [5]],
		"derived read: %s" % str(_profile.call(&"battery_groups", CAPITAL))
	)
	## The drag's install: cell 4 is free, the bag holds lasers, B1 holds four cells.
	_check(
		"ac1_seed_four_cell_rack",
		bool(_profile.call(&"set_battery_groups", CAPITAL, [[0, 1, 2, 3], [5]])),
		"B1 filled to four"
	)
	before = _bytes()
	var installed := bool(_profile.call(&"fit_into_rack", CAPITAL, 0, 4, LASER))
	_check("ac1_install_refused", not installed, "fit_into_rack into a full rack answers false")
	_check("ac1_install_wrote_nothing", _bytes() == before, "persisted bytes unchanged")
	## The move that would grow a full rack.
	var moved := bool(_profile.call(&"move_rack_cell", CAPITAL, 1, 0, 0, 4))
	_check("ac1_move_grow_refused", not moved, "an append onto a full rack answers false")
	_check("ac1_move_wrote_nothing", _bytes() == before, "persisted bytes unchanged")
	## Positive controls, so the refusals are the cap and not a broken fixture.
	var swapped := bool(_profile.call(&"move_rack_cell", CAPITAL, 1, 0, 0, 0))
	_check("ac1_swap_accepted", swapped, "a swap into a full rack is legal")
	_check(
		"ac1_swap_result",
		_profile.call(&"battery_groups", CAPITAL) == [[5, 1, 2, 3], [0], [6]],
		"derived read: %s" % str(_profile.call(&"battery_groups", CAPITAL))
	)
	_check(
		"ac1_install_into_room",
		bool(_profile.call(&"fit_into_rack", CAPITAL, 1, 4, LASER)),
		"the same install into a rack with room is accepted"
	)


## ------------------------------------------------------------------------- AC2


func _ac2() -> void:
	_fixture([], false)
	var groups: Array = _profile.call(&"battery_groups", CAPITAL)
	_check("ac2_capacity", FitData.slot_capacity(CAPITAL, WEAPON_SLOT) == 7, "the hull's seven W cells")
	_check("ac2_empty_record_4_3", groups == [[0, 1, 2, 3], [4, 5, 6]], "composes %s" % str(groups))
	## The derived-read invariant the read's own contract states: every fitted cell in
	## exactly one rack. Measured for a record that already holds five racks.
	_fixture([[0], [1], [2], [3], [4]], false)
	var filled: Array = _profile.call(&"battery_groups", CAPITAL)
	var covered: Array = []
	for rack: Variant in filled:
		covered.append_array(rack as Array)
	covered.sort()
	var fitted_count := 0
	for cell: Variant in (_profile.call(&"fit_for", CAPITAL)[WEAPON_SLOT] as Array):
		if String(cell) != "":
			fitted_count += 1
	_check(
		"ac2_five_rack_invariant",
		covered == [0, 1, 2, 3, 4, 5, 6],
		"a 5-rack record with a 7-cell fit covers %s of 7 fitted cells (racks=%s)"
		% [str(covered), str(filled)]
	)
	_check(
		"ac2_five_rack_fitted_count", fitted_count == 7, "the fit really holds %d guns" % fitted_count
	)
	## The same shape reached the way play reaches it: four racks, then the FITTING
	## pane fills the rest (the fit is written without the record).
	_fixture([[0], [1], [2], [3]], false)
	var four: Array = _profile.call(&"battery_groups", CAPITAL)
	var four_covered: Array = []
	for rack: Variant in four:
		four_covered.append_array(rack as Array)
	four_covered.sort()
	_check(
		"ac2_four_rack_invariant",
		four_covered == [0, 1, 2, 3, 4, 5, 6],
		"a 4-rack record covers %s" % str(four_covered)
	)
	## The same gap reached the way play reaches it: five batteries composed by the pane's
	## moves over six barrels, then the FITTING pane fills the still-empty seventh cell.
	var sparse_fit: Dictionary = FitData.standard_fit(CAPITAL)
	var sparse_weapons: Array = []
	for index in 7:
		sparse_weapons.append(
			"" if index == 6 else (String(LASER) if index % 2 == 0 else String(CANNON))
		)
	sparse_fit[WEAPON_SLOT] = sparse_weapons
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_batteries", {})
	_profile.call(&"add_module", LASER, 3)
	_check("ac2_play_sparse_fit", bool(_profile.call(&"set_fit", CAPITAL, sparse_fit)), "seven cells, the seventh empty")
	_check(
		"ac2_play_record",
		bool(_profile.call(&"set_battery_groups", CAPITAL, [[0, 1, 2, 3], [], [4], [], [5]])),
		"five batteries over six barrels (the shape the moves build)"
	)
	var full_fit: Dictionary = FitData.standard_fit(CAPITAL)
	var full_weapons: Array = []
	for index in 7:
		full_weapons.append(String(LASER) if index % 2 == 0 else String(CANNON))
	full_fit[WEAPON_SLOT] = full_weapons
	_check("ac2_play_fitting_fill", bool(_profile.call(&"set_fit", CAPITAL, full_fit)), "FITTING fills the seventh cell")
	var play_groups: Array = _profile.call(&"battery_groups", CAPITAL)
	var play_covered: Array = []
	for rack: Variant in play_groups:
		play_covered.append_array(rack as Array)
	play_covered.sort()
	_check(
		"ac2_play_invariant",
		play_covered == [0, 1, 2, 3, 4, 5, 6],
		"five composed batteries + a FITTING fill cover %s (groups=%s)"
		% [str(play_covered), str(play_groups)]
	)


## ------------------------------------------------------------------------- AC3


func _ac3() -> void:
	## A real pre-S15 file: v7, seven one-cell groups, a full 7-cell fit.
	var config := ConfigFile.new()
	config.set_value(&"profile", &"save_version", 7)
	config.set_value(&"profile", &"credits", 4321)
	config.set_value(&"profile", &"owned_ships", [String(CAPITAL)])
	config.set_value(&"profile", &"active_ship", String(CAPITAL))
	config.set_value(&"profile", &"modules", {})
	var fit: Dictionary = FitData.standard_fit(CAPITAL)
	var weapons: Array = []
	for index in 7:
		weapons.append(String(LASER) if index % 2 == 0 else String(CANNON))
	fit[WEAPON_SLOT] = weapons
	config.set_value(&"profile", &"fits", {String(CAPITAL): fit})
	config.set_value(
		&"profile", &"batteries", {String(CAPITAL): [[0], [1], [2], [3], [4], [5], [6]]}
	)
	_check("ac3_fixture_written", config.save(SAVE_PATH) == OK, "the seven-group file is written")
	_profile.call(&"reload")
	var stored: Array = _profile.call(&"batteries").get(String(CAPITAL), [])
	_check("ac3_clamped_five", stored == [[0], [1], [2], [3], [4]], "stored=%s" % str(stored))
	_check(
		"ac3_order_preserved",
		stored == [[0], [1], [2], [3], [4]],
		"cell order preserved (first five in order)"
	)
	_check("ac3_credits_intact", int(_profile.call(&"credits")) == 4321, "credits=4321")
	_check(
		"ac3_fit_intact",
		int((_profile.call(&"fit_for", CAPITAL) as Dictionary)[WEAPON_SLOT].size()) == 7,
		"the fit still carries seven cells"
	)
	## The read-back of the clamped store: cells 5/6 are fitted but claim no rack, which
	## is the same derived-read gap AC2 measured (the pin's "overflow guns").
	var groups: Array = _profile.call(&"battery_groups", CAPITAL)
	var covered: Array = []
	for rack: Variant in groups:
		covered.append_array(rack as Array)
	covered.sort()
	print("%s ac3_derived=%s covered=%s" % [TAG, str(groups), str(covered)])
	## A second reload is inert.
	var once: Dictionary = _profile.call(&"batteries")
	_profile.call(&"reload")
	_check(
		"ac3_second_reload_inert", _profile.call(&"batteries") == once, "a second load changes nothing"
	)
	## An over-long rack clamps cell by cell and the surplus cell re-derives.
	var config2 := ConfigFile.new()
	config2.set_value(&"profile", &"save_version", 7)
	config2.set_value(&"profile", &"credits", 2500)
	config2.set_value(&"profile", &"owned_ships", [String(CAPITAL)])
	config2.set_value(&"profile", &"active_ship", String(CAPITAL))
	config2.set_value(&"profile", &"modules", {})
	config2.set_value(&"profile", &"fits", {String(CAPITAL): fit})
	config2.set_value(&"profile", &"batteries", {String(CAPITAL): [[0, 1, 2, 3, 4], [5], [6]]})
	_check("ac3b_fixture_written", config2.save(SAVE_PATH) == OK, "the over-long-rack file is written")
	_profile.call(&"reload")
	var stored2: Array = _profile.call(&"batteries").get(String(CAPITAL), [])
	_check(
		"ac3b_clamped", stored2 == [[0, 1, 2, 3], [5], [6]],
		"stored=%s" % str(stored2)
	)
	_check(
		"ac3b_surplus_derived",
		_profile.call(&"battery_groups", CAPITAL) == [[0, 1, 2, 3], [5], [6], [4]],
		"derived=%s" % str(_profile.call(&"battery_groups", CAPITAL))
	)


func _notification(_what: int) -> void:
	pass
