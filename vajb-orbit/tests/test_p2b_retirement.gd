@tool
extends McpTestSuite
## Suite p2b_retirement: the P2-B proper save v5 flag day and the two composed
## fitting transactions (CONTRACTS section 13, 09 section 4 items 9, 10 and 13,
## docs/gameplay/10 section 5).
##
## Covers the six-row retirement table, the conversion of a v4 file (and of a
## pre-v4 one) into inventory modules, the one-way door and the idempotence of
## `retire_legacy_upgrades`, the per-cell install, the swap that hands the
## displaced module back, the composed remove, the mandatory-cell and empty-cell
## refusals, the unowned-module and cell-guard refusals, the over-budget refusal
## before any write, one economy-log line per transaction, and the absence of
## the retired surface from the two sources.
##
## Profiles are throwaway instances of the autoload script whose `save_path` is
## repointed at a scratch file before the first mutation, so `user://profile.cfg`
## is never touched. None is added to the tree, so the debounced save Timer does
## not exist and every mutation - the migration's own write included - goes
## through immediately, which is what makes the on-disk assertions exact (the
## same harness as `test_p1_profile.gd`).

const Profile := preload("res://autoload/player_profile.gd")
const FitData := preload("res://game/ship_fit.gd")
const Log := preload("res://game/economy_log.gd")

const PROFILE_PATH := "user://test_p2b_retirement.cfg"
const LOG_PATH := "user://test_p2b_retirement_log.txt"
const SECTION := "profile"

## 09 section 4 item 13's six retired rows in the catalogue's own order, and the
## module each one converts to (09's own lineage rows, 10 section 5). The test
## holds both lists itself so a drift between them and `LEGACY_UPGRADE_MODULES`
## is a red assertion rather than a tautology.
const RETIRED: Array[StringName] = [
	&"upgrade_generator", &"upgrade_shield", &"upgrade_engine",
	&"upgrade_module", &"upgrade_extra", &"upgrade_drone",
]
const SUCCESSORS: Array[StringName] = [
	&"p_mk2", &"s_heavy", &"e_ion", &"c_scanner", &"u_cargo", &"u_drones",
]

## 08 section 3.2's Fighter row (`.WW.`, `HSCB`, `.EP.`): two W cells, one engine
## cell, one power cell and 08 section 2's `power_out` 6. 09 section 3's draws
## make it the budget case below: two plasma coils (3 each) plus the delivered
## light shield (2) is 8 against an output of 6, over by 2.
const HULL: StringName = &"ship_fighter"
const HULL_WEAPONS := 2
const NPC_HULL: StringName = &"ship_swarmer"

var _profiles: Array[Node] = []
var _signals: Array[StringName] = []


func suite_name() -> String:
	return "p2b_retirement"


func setup() -> void:
	_delete_file(PROFILE_PATH)
	_reset_log()
	_signals.clear()


func teardown() -> void:
	for profile: Node in _profiles:
		if is_instance_valid(profile):
			profile.free()
	_profiles.clear()
	_signals.clear()


func suite_teardown() -> void:
	_delete_file(PROFILE_PATH)
	_delete_file(LOG_PATH)
	Log.log_path = Log.DEFAULT_PATH


## ---------------------------------------------------------------------------
## The retirement table and the flag day
## ---------------------------------------------------------------------------


func test_the_retirement_table_is_09s_lineage_rows() -> void:
	assert_eq(Profile.LEGACY_UPGRADE_MODULES.size(), 6, "six retired rows, one successor each")
	for index: int in RETIRED.size():
		var retired: StringName = RETIRED[index]
		var successor: StringName = SUCCESSORS[index]
		assert_eq(
			Profile.LEGACY_UPGRADE_MODULES.get(retired, &""),
			successor,
			"%s converts to %s" % [retired, successor]
		)
		assert_false(FitData.MODULES.has(retired), "%s is not a module id" % retired)
		assert_true(FitData.MODULES.has(successor), "%s is a catalogue module" % successor)


func test_a_v4_file_with_all_six_upgrades_loads_as_six_modules() -> void:
	_write_fixture(4, RETIRED)
	var profile = _fresh()
	profile.reload()
	assert_eq(profile.modules().size(), 6, "six inventory records, one per retired row")
	for index: int in RETIRED.size():
		assert_eq(
			profile.module_count(SUCCESSORS[index]), 1, "%s came over once" % SUCCESSORS[index]
		)
		assert_eq(profile.module_count(RETIRED[index]), 0, "%s is never an inventory id" % RETIRED[index])
	## The flag day wrote the file itself: v6 (S3), no record, the six modules on disk.
	var on_disk := ConfigFile.new()
	assert_eq(on_disk.load(PROFILE_PATH), OK, "the migrated file reads back")
	assert_eq(int(on_disk.get_value(SECTION, "save_version", 0)), 6, "writes always persist v6")
	assert_false(on_disk.has_section_key(SECTION, "upgrades"), "the retired key is gone")
	var stored: Dictionary = on_disk.get_value(SECTION, "modules", {})
	assert_eq(stored.size(), 6, "the six records are on disk")
	## The one-way door: a second call and a second load both find nothing left.
	assert_eq(profile.retire_legacy_upgrades(), 0, "the migration is idempotent")
	var again = _fresh()
	again.reload()
	assert_eq(again.modules().size(), 6, "a v6 file loads as six modules, not twelve")
	assert_eq(again.retire_legacy_upgrades(), 0, "and has nothing left to migrate")


func test_a_v1_file_with_a_record_migrates_too() -> void:
	_write_fixture(1, [&"upgrade_engine"])
	var profile = _fresh()
	profile.reload()
	assert_eq(profile.credits(), 10000, "the rest of the file reads as it always did")
	assert_eq(profile.module_count(&"e_ion"), 1, "the one installed upgrade came over")
	assert_eq(profile.modules().size(), 1, "and nothing else did")


func test_a_pre_v5_file_without_the_record_is_left_alone() -> void:
	var fixture := ConfigFile.new()
	fixture.set_value(SECTION, "save_version", 3)
	fixture.set_value(SECTION, "credits", 1234)
	fixture.set_value(SECTION, "owned_ships", ["ship_vanguard"])
	assert_eq(fixture.save(PROFILE_PATH), OK, "the v3 fixture is written")
	var profile = _fresh()
	profile.reload()
	assert_eq(profile.credits(), 1234, "the file's own values are read")
	assert_true(profile.modules().is_empty(), "nothing was migrated")
	assert_eq(profile.retire_legacy_upgrades(), 0, "and nothing is left to migrate")
	var on_disk := ConfigFile.new()
	assert_eq(on_disk.load(PROFILE_PATH), OK, "the file reads back")
	assert_eq(
		int(on_disk.get_value(SECTION, "save_version", 0)),
		3,
		"a file with nothing to migrate is not rewritten at load"
	)


func test_the_retired_surface_is_gone_from_the_two_sources() -> void:
	var profile_source := _read_source("res://autoload/player_profile.gd")
	for token: String in [
		"KEY_UPGRADES", "func has_upgrade(", "func installed_upgrades(", "func install_upgrade(",
	]:
		assert_false(profile_source.contains(token), "the profile still carries %s" % token)
	var catalog_source := _read_source("res://game/station_catalog.gd")
	for token: String in ["const UPGRADES:", "func upgrade(", "func upgrade_ids(", "UPGRADE_SLOTS"]:
		assert_false(catalog_source.contains(token), "the catalogue still carries %s" % token)
	var methods: Array[String] = []
	for entry: Dictionary in _fresh().get_method_list():
		methods.append(str(entry.get("name", "")))
	for retired: String in ["has_upgrade", "installed_upgrades", "install_upgrade"]:
		assert_false(methods.has(retired), "PlayerProfile still answers %s()" % retired)


## ---------------------------------------------------------------------------
## The composed install
## ---------------------------------------------------------------------------


func test_the_install_targets_the_cell_it_is_given() -> void:
	var profile = _fitted_fighter()
	_watch(profile)
	profile.add_module(&"w_cannon", 1)
	_signals.clear()
	assert_true(
		profile.fit_module_at(HULL, &"weapons", 1, &"w_cannon"), "the second W cell takes the cannon"
	)
	var weapons: Array = profile.fit_for(HULL)[&"weapons"]
	assert_eq(weapons.size(), HULL_WEAPONS, "the fighter keeps its two W cells")
	assert_eq(weapons[0], "w_laser", "the cell that was not named is untouched")
	assert_eq(weapons[1], "w_cannon", "the cell that was named took the module")
	assert_eq(profile.module_count(&"w_cannon"), 0, "the bought cannon left the inventory")
	assert_eq(profile.module_count(&"w_laser"), 1, "the displaced laser came back")
	## Both keys signal, in the order the transaction writes them, and nothing else does.
	assert_eq(_signals.size(), 3, "displace, take, write: %s" % str(_signals))
	assert_eq(_signals[0], &"modules", "the displaced module returns to the inventory first")
	assert_eq(_signals[1], &"modules", "the incoming module leaves it second")
	assert_eq(_signals[2], &"fits", "and the cell is written last")
	for key: StringName in _signals:
		assert_true(key == &"fits" or key == &"modules", "only the fit keys signal, saw %s" % key)


func test_a_swap_hands_the_displaced_module_back() -> void:
	var profile = _fitted_fighter()
	profile.add_module(&"w_cannon", 1)
	profile.add_module(&"w_laser", 1)
	assert_true(
		profile.fit_module_at(HULL, &"weapons", 0, &"w_cannon"), "the first W cell takes the cannon"
	)
	assert_eq(profile.module_count(&"w_laser"), 2, "the displaced laser went back to the inventory")
	assert_eq(profile.module_count(&"w_cannon"), 0, "and the cannon came out of it")
	assert_eq(profile.fit_for(HULL)[&"weapons"][0], "w_cannon", "the cell holds the cannon")
	## The swap back: the cannon is the displaced module this time, so neither
	## transaction can lose one.
	assert_true(
		profile.fit_module_at(HULL, &"weapons", 0, &"w_laser"), "the same cell takes a laser again"
	)
	assert_eq(profile.module_count(&"w_cannon"), 1, "the displaced cannon is back in the inventory")
	assert_eq(profile.module_count(&"w_laser"), 1, "one of the two lasers was taken")
	assert_eq(
		profile.fit_for(HULL)[&"weapons"],
		["w_laser", "w_laser"],
		"the fit is the delivered one again"
	)
	assert_eq(profile.fit_for(HULL)[&"weapons"][1], "w_laser", "cell 1 was never touched")


func test_clear_returns_the_module_and_empties_the_cell() -> void:
	var profile = _fitted_fighter()
	_watch(profile)
	assert_true(profile.clear_fit_slot(HULL, &"weapons", 0), "the first W cell can be emptied")
	assert_eq(profile.fit_for(HULL)[&"weapons"][0], "", "the cell is empty")
	assert_eq(profile.fit_for(HULL)[&"weapons"][1], "w_laser", "the other cell keeps its module")
	assert_eq(profile.module_count(&"w_laser"), 1, "the module is back in the inventory")
	assert_eq(_log_lines().size(), 1, "one line for the remove")
	assert_true(_signals.has(&"fits") and _signals.has(&"modules"), "both keys signal")
	## A second remove of the same cell has nothing to return and writes nothing.
	_signals.clear()
	assert_false(profile.clear_fit_slot(HULL, &"weapons", 0), "an empty cell is not a transaction")
	assert_true(_signals.is_empty(), "a refused remove signals nothing")
	assert_eq(_log_lines().size(), 1, "and logs nothing")


## ---------------------------------------------------------------------------
## The launch's own fit (R1 MED-1: what the panel previews and the profile commits)
## ---------------------------------------------------------------------------


## `resolved_fit` is the fit the launch would fly: the account's stored fit while it holds a
## module, and 09 section 9's delivered fit otherwise - `game.gd:_launch_fit_for`'s own
## fallback, so the panel and the profile judge one fit.
func test_resolved_fit_is_the_launchs_own_fallback() -> void:
	var profile = _fresh()
	assert_ne(FitData.standard_fit(HULL), {}, "the Fighter has a delivered fit to fall back to")
	assert_eq(
		profile.resolved_fit(HULL),
		FitData.standard_fit(HULL),
		"a hull with nothing stored resolves to the delivered fit"
	)
	assert_true(profile.set_fit(HULL, FitData.standard_fit(HULL)), "the delivered fit is stored")
	assert_eq(
		profile.resolved_fit(HULL), profile.fit_for(HULL), "a fit that holds a module is the one"
	)
	assert_eq(profile.resolved_fit(NPC_HULL), {}, "a hull outside the nine still resolves to nothing")
	assert_true(profile.set_fit(HULL, {}), "an all-empty stored fit is written back")
	assert_eq(
		profile.resolved_fit(HULL),
		FitData.standard_fit(HULL),
		"an all-empty stored fit falls back too"
	)


## R1 MED-1's profile half: the first install on a hull the account holds no fit for. The
## launch flies the delivered fit, so the candidate is that fit with the one cell set and the
## write leaves the delivery standing - the fit is launchable afterwards, and not a one-module
## fit that would fly lacking 09 section 4.1's mandatory cells.
func test_the_first_install_on_a_bare_hull_keeps_the_launchs_fit() -> void:
	var profile = _fresh()
	profile.add_module(&"w_cannon", 1)
	assert_true(
		profile.fit_module_at(HULL, &"weapons", 1, &"w_cannon"),
		"the composed install on a hull with no stored fit succeeds"
	)
	var stored: Dictionary = profile.fit_for(HULL)
	var legality: Dictionary = FitData.fit_legal(HULL, stored)
	assert_true(bool(legality[&"legal"]), "the fit left behind is launchable: %s" % str(legality))
	assert_true((legality[&"missing"] as Array).is_empty(), "with no mandatory cell missing")
	assert_eq(stored[&"engines"], ["e_std"], "the delivered engine stands")
	assert_eq(stored[&"power"], "p_std", "and the delivered reactor")
	assert_eq(stored[&"weapons"], ["w_laser", "w_cannon"], "the named cell took the cannon")
	assert_eq(stored[&"shields"], ["s_light"], "and the delivered shield stands")
	assert_eq(stored[&"armour"], ["h_plate_light"], "and the plate")
	assert_eq(profile.module_count(&"w_cannon"), 0, "the cannon left the inventory")
	assert_eq(profile.module_count(&"w_laser"), 0, "the delivered laser it replaced was not banked")
	assert_eq(profile.resolved_fit(HULL), stored, "the launch's fit and the stored fit are one fit")


## The other half of R1 MED-1: a hull that already holds a fit is written cell by cell as
## before, so every cell the install does not name keeps exactly what the stored fit held.
func test_a_stored_fit_is_written_cell_by_cell_as_before() -> void:
	var profile = _fitted_fighter()
	var before: Dictionary = profile.fit_for(HULL)
	profile.add_module(&"w_cannon", 1)
	assert_true(profile.fit_module_at(HULL, &"weapons", 1, &"w_cannon"), "the install")
	var after: Dictionary = profile.fit_for(HULL)
	for key: StringName in FitData.FIT_SLOT_KEYS:
		if key == &"weapons":
			assert_eq(after[key], ["w_laser", "w_cannon"], "the named cell changed, cell 0 did not")
			continue
		assert_eq(after[key], before[key], "%s is exactly what the stored fit held" % key)
	assert_true(
		bool(FitData.fit_legal(HULL, after)[&"legal"]), "and the fit is still launchable"
	)


## ---------------------------------------------------------------------------
## The refusals
## ---------------------------------------------------------------------------


func test_a_mandatory_cell_is_never_emptied() -> void:
	var profile = _fitted_fighter()
	_watch(profile)
	assert_false(profile.clear_fit_slot(HULL, &"engines", 0), "an engine cell is never emptied")
	assert_false(profile.clear_fit_slot(HULL, &"power", 0), "nor is the reactor")
	assert_eq(profile.fit_for(HULL)[&"engines"], ["e_std"], "the delivered engine is untouched")
	assert_eq(profile.fit_for(HULL)[&"power"], "p_std", "and so is the delivered reactor")
	assert_eq(profile.modules().size(), 0, "no inventory write")
	assert_eq(_log_lines().size(), 0, "no log line")
	assert_true(_signals.is_empty(), "and no signal")
	## Swapping a mandatory cell is the half that is allowed: replaced, never empty.
	profile.add_module(&"e_ion", 1)
	assert_true(profile.fit_module_at(HULL, &"engines", 0, &"e_ion"), "an engine cell can be swapped")
	assert_eq(profile.fit_for(HULL)[&"engines"], ["e_ion"], "the cell took the better drive")
	assert_eq(profile.module_count(&"e_std"), 1, "the delivered drive came back to the inventory")
	assert_eq(profile.module_count(&"e_ion"), 0, "and the new one left it")


func test_an_unowned_module_refuses() -> void:
	var profile = _fitted_fighter()
	_watch(profile)
	assert_eq(profile.module_count(&"w_railgun"), 0, "the railgun is not owned")
	assert_false(
		profile.fit_module_at(HULL, &"weapons", 0, &"w_railgun"), "an unowned module cannot be fitted"
	)
	assert_eq(profile.fit_for(HULL)[&"weapons"], ["w_laser", "w_laser"], "both cells are untouched")
	assert_eq(profile.modules().size(), 0, "and so is the inventory")
	assert_eq(_log_lines().size(), 0, "no log line")
	assert_true(_signals.is_empty(), "no signal")
	assert_false(profile.fit_module_at(HULL, &"weapons", 0, &""), "nor can an empty id")


func test_the_cell_guards_refuse_before_any_write() -> void:
	var profile = _fitted_fighter()
	_watch(profile)
	profile.add_module(&"w_cannon", 1)
	_signals.clear()
	assert_false(
		profile.fit_module_at(HULL, &"weapons", HULL_WEAPONS, &"w_cannon"), "the third W cell does not exist"
	)
	assert_false(profile.fit_module_at(HULL, &"weapons", -1, &"w_cannon"), "nor does a negative index")
	assert_false(profile.fit_module_at(HULL, &"utility", 0, &"u_cargo"), "the fighter has no U cell")
	assert_false(profile.fit_module_at(HULL, &"hulls", 0, &"w_cannon"), "and no hulls cell")
	assert_false(profile.fit_module_at(NPC_HULL, &"weapons", 0, &"w_cannon"), "an NPC hull fits nothing")
	assert_false(profile.clear_fit_slot(HULL, &"weapons", HULL_WEAPONS), "the remove guards match")
	assert_false(profile.clear_fit_slot(NPC_HULL, &"weapons", 0), "on an NPC hull too")
	assert_eq(profile.fit_for(HULL)[&"weapons"], ["w_laser", "w_laser"], "nothing was written")
	assert_eq(profile.module_count(&"w_cannon"), 1, "and nothing was taken")
	assert_eq(_log_lines().size(), 0, "no log line")
	assert_true(_signals.is_empty(), "no signal")


func test_an_over_budget_candidate_refuses_before_any_write() -> void:
	var profile = _fitted_fighter()
	_watch(profile)
	profile.add_module(&"w_plasma", 2)
	## The first coil is exactly at the budget: the delivered laser 1 + the coil 3
	## + the light shield 2 = 6 against 08 section 2's output of 6.
	assert_true(profile.fit_module_at(HULL, &"weapons", 0, &"w_plasma"), "the first coil fits exactly")
	assert_eq(_log_lines().size(), 1, "and is one transaction")
	## The second would make it 8, so the candidate is 09 section 4's own refusal.
	var candidate: Dictionary = profile.fit_for(HULL)
	var cells: Array = candidate[&"weapons"]
	cells[1] = "w_plasma"
	candidate[&"weapons"] = cells
	var legality: Dictionary = FitData.fit_legal(HULL, candidate)
	assert_false(bool(legality[&"legal"]), "the candidate fit is illegal")
	var power: Dictionary = legality[&"power"]
	assert_eq(int(power[&"out"]), 6, "08 section 2's power output")
	assert_eq(int(power[&"draw"]), 8, "two coils and the light shield")
	assert_eq(int(power[&"spare"]), -2, "over by two")
	assert_false(
		profile.fit_module_at(HULL, &"weapons", 1, &"w_plasma"), "the over-budget cell is refused"
	)
	assert_eq(profile.fit_for(HULL)[&"weapons"][1], "w_laser", "the cell is untouched")
	assert_eq(profile.module_count(&"w_plasma"), 1, "the inventory is untouched")
	assert_eq(_log_lines().size(), 1, "and no second line was written")


## ---------------------------------------------------------------------------
## The log
## ---------------------------------------------------------------------------


func test_one_fit_module_line_per_successful_transaction() -> void:
	var profile = _fitted_fighter()
	profile.add_module(&"w_cannon", 1)
	profile.add_module(&"w_plasma", 1)
	assert_eq(_log_lines().size(), 0, "the fixture writes no line itself")
	## An install, a swap and a remove: three transactions, three lines.
	assert_true(profile.fit_module_at(HULL, &"weapons", 1, &"w_cannon"), "the install")
	assert_true(profile.fit_module_at(HULL, &"weapons", 1, &"w_plasma"), "the swap")
	assert_true(profile.clear_fit_slot(HULL, &"weapons", 0), "the remove")
	var lines := _log_lines()
	assert_eq(lines.size(), 3, "one line per transaction, never two")
	var moved: Array[String] = ["w_cannon", "w_plasma", "w_laser"]
	for index: int in lines.size():
		var fields := lines[index].split(", ")
		assert_eq(fields.size(), 6, "the log's six fields")
		assert_eq(fields[1], Profile.EVENT_FIT_MODULE, "the fitting transaction's own id")
		assert_eq(fields[2], moved[index], "the module the transaction moved")
		assert_eq(fields[3], "1", "one module")
		assert_eq(fields[4], "+0", "no credits move: fitting at the station is free")
		assert_eq(fields[5], "10000", "the balance is the untouched default")
	## A refusal adds nothing.
	assert_false(profile.fit_module_at(HULL, &"weapons", 5, &"w_cannon"), "an out-of-range cell")
	assert_eq(_log_lines().size(), 3, "a refused transaction logs nothing")


## ---------------------------------------------------------------------------
## Helpers
## ---------------------------------------------------------------------------


## 09 section 9's delivered Fighter: the mandatory set plus the plate, the shield
## and two lasers, which is 4 of the hull's 6 power and is legal as it stands.
func _fitted_fighter():
	var profile = _fresh()
	assert_true(
		profile.set_fit(HULL, FitData.standard_fit(HULL)), "the Fighter takes its delivered fit"
	)
	assert_eq(
		profile.fit_for(HULL)[&"engines"].size(), 1, "the delivered fit carries its mandatory engine"
	)
	return profile


## A pre-v5 file: the retired `upgrades` record plus the values every version has
## carried, so the migration is measured against a loadable file and not a shape
## this test invented.
func _write_fixture(version: int, upgrades: Array) -> void:
	var fixture := ConfigFile.new()
	fixture.set_value(SECTION, "save_version", version)
	fixture.set_value(SECTION, "credits", 10000)
	fixture.set_value(SECTION, "owned_ships", ["ship_vanguard"])
	fixture.set_value(SECTION, "active_ship", "ship_vanguard")
	fixture.set_value(SECTION, "upgrades", upgrades)
	fixture.set_value(SECTION, "cargo", {})
	fixture.set_value(SECTION, "ammo", {"laser": 300})
	fixture.set_value(SECTION, "modules", {})
	assert_eq(fixture.save(PROFILE_PATH), OK, "the v%d fixture is written" % version)


func _fresh():
	var profile := Profile.new()
	profile.save_path = PROFILE_PATH
	_profiles.append(profile)
	return profile


func _watch(profile: Node) -> void:
	_signals.clear()
	profile.profile_changed.connect(_on_profile_changed)


func _on_profile_changed(key: StringName) -> void:
	_signals.append(key)


## The lines of the scratch economy log, blank ones dropped.
func _log_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	var file := FileAccess.open(LOG_PATH, FileAccess.READ)
	if file == null:
		return lines
	var text := file.get_as_text()
	file.close()
	for line: String in text.split("\n"):
		if not line.strip_edges().is_empty():
			lines.append(line)
	return lines


func _read_source(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _delete_file(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


func _reset_log() -> void:
	Log.log_path = LOG_PATH
	var file := FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if file != null:
		file.close()
