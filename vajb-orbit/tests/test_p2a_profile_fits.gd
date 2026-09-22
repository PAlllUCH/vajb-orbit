@tool
extends McpTestSuite
## Suite p2a_profile_fits: the per-hull fit store of save v4 on `PlayerProfile`
## (CONTRACTS section 11, 09 sections 4.5 and 9) - the normalised cell shape and
## its capacity padding, the v1-v3 single-string migration read, the layout
## index, and the module inventory helpers.
##
## Profiles are throwaway instances of the autoload script whose `save_path` is
## repointed at a scratch file before the first mutation, so `user://profile.cfg`
## is never touched. No instance is added to the tree, so the debounced save
## Timer does not exist and every mutation writes through immediately, which is
## what makes the round-trip assertions exact (the same harness as
## `test_p1_profile.gd`).

const Profile := preload("res://autoload/player_profile.gd")
const FitData := preload("res://game/ship_fit.gd")

const PROFILE_PATH := "user://test_p2a_profile_fits.cfg"
const SECTION := "profile"

## 08 section 3's own counts: the Delver carries two engine cells and no B cell at
## all, the Mule carries three engines and one W cell (08 section 3.1's mass bands
## decide the engine count, 08 section 3.2's matrices everything else).
const TWO_ENGINE_HULL: StringName = &"ship_miner"
const THREE_ENGINE_HULL: StringName = &"ship_freighter"
const NPC_HULL: StringName = &"ship_swarmer"

var _profiles: Array[Node] = []
var _signals: Array[StringName] = []


func suite_name() -> String:
	return "p2a_profile_fits"


func setup() -> void:
	_delete_file(PROFILE_PATH)
	_signals.clear()


func teardown() -> void:
	for profile: Node in _profiles:
		if is_instance_valid(profile):
			profile.free()
	_profiles.clear()
	_signals.clear()


func suite_teardown() -> void:
	_delete_file(PROFILE_PATH)


## ---------------------------------------------------------------------------
## The shape, its capacity padding and the layout index
## ---------------------------------------------------------------------------


func test_fit_for_answers_every_type_at_the_hulls_capacity() -> void:
	var profile = _fresh()
	profile.reload()
	for hull: StringName in FitData.HULLS:
		var fit: Dictionary = profile.fit_for(hull)
		assert_eq(fit.size(), FitData.FIT_SLOT_KEYS.size(), "%s answers all eight slot types" % hull)
		for slot_key: StringName in FitData.FIT_SLOT_KEYS:
			assert_has_key(fit, String(slot_key), "%s has no %s entry" % [hull, slot_key])
			if slot_key == Profile.POWER_SLOT:
				assert_eq(
					typeof(fit[slot_key]), TYPE_STRING, "%s power is one module id" % hull
				)
				assert_eq(fit[slot_key], "", "%s starts with an empty power cell" % hull)
				continue
			var cells: Array = fit[slot_key]
			assert_eq(
				cells.size(),
				FitData.slot_capacity(hull, slot_key),
				"%s %s is as long as the hull has cells" % [hull, slot_key]
			)
			for cell: Variant in cells:
				assert_eq(String(cell), "", "%s %s starts empty" % [hull, slot_key])
	## The two engine counts 08 section 3.1 and 08 section 3 name, asserted as
	## numbers rather than read back out of the same call the code makes.
	assert_eq(FitData.slot_capacity(TWO_ENGINE_HULL, &"engines"), 2, "the Delver's engines")
	assert_eq(FitData.slot_capacity(THREE_ENGINE_HULL, &"engines"), 3, "the Mule's engines")
	assert_eq(profile.fit_for(TWO_ENGINE_HULL)[&"engines"].size(), 2, "and its fit is two long")
	assert_eq(profile.fit_for(THREE_ENGINE_HULL)[&"engines"].size(), 3, "and its fit three")
	## A returned array is a copy: writing into one cannot reach the store.
	var returned: Array = profile.fit_for(TWO_ENGINE_HULL)[&"weapons"]
	returned[0] = "w_laser"
	assert_eq(
		profile.fit_for(TWO_ENGINE_HULL)[&"weapons"][0], "", "fit_for hands out copies"
	)


func test_a_three_engine_hull_pads_its_engines_to_three_cells() -> void:
	var profile = _fresh()
	var engines: Array = profile.fit_for(THREE_ENGINE_HULL)[&"engines"]
	assert_eq(engines.size(), 3, "the Mule's three engine cells, not one")
	assert_eq(engines, ["", "", ""], "all three empty on a bare hull")
	assert_true(
		profile.set_fit_slot(THREE_ENGINE_HULL, &"engines", 2, &"e_std"),
		"the third engine cell takes a drive"
	)
	assert_eq(
		profile.fit_for(THREE_ENGINE_HULL)[&"engines"],
		["", "", "e_std"],
		"the cell is its layout index, and the array keeps its three cells"
	)
	assert_false(
		profile.set_fit_slot(THREE_ENGINE_HULL, &"engines", 3, &"e_std"),
		"a fourth engine cell does not exist"
	)
	profile.save()
	var reloaded = _fresh()
	reloaded.reload()
	assert_eq(
		reloaded.fit_for(THREE_ENGINE_HULL)[&"engines"],
		["", "", "e_std"],
		"the padded array survives the save"
	)


func test_set_fit_normalises_to_the_hulls_shape_and_the_array_shape_persists() -> void:
	var first = _fresh()
	assert_true(
		first.set_fit(
			TWO_ENGINE_HULL,
			{
				&"engines": [&"e_ion", &"e_std"],
				&"weapons": ["w_mining", "w_laser", "w_cannon"],
				&"power": &"p_mk2",
			}
		),
		"a fit is stored at the hull's own shape"
	)
	var fit: Dictionary = first.fit_for(TWO_ENGINE_HULL)
	assert_eq(fit[&"engines"], ["e_ion", "e_std"], "both engine cells hold their module")
	assert_eq(
		fit[&"weapons"],
		["w_mining", "w_laser"],
		"a longer tail is cut at the Delver's two W cells"
	)
	assert_eq(fit[&"armour"], ["", ""], "a type the caller omitted is padded, not missing")
	assert_eq(fit[&"boosters"], [], "a hull with no B cell stores an empty array")
	assert_eq(fit[&"power"], "p_mk2", "power is one module id, not an array")

	first.save()
	var second = _fresh()
	second.reload()
	assert_true(_deep_eq(second.fit_for(TWO_ENGINE_HULL), fit), "the fit round trips")

	## The persisted shape is the array shape, one entry per cell.
	var on_disk := ConfigFile.new()
	assert_eq(on_disk.load(PROFILE_PATH), OK, "the profile is on disk")
	var stored: Dictionary = on_disk.get_value(SECTION, "fits", {})
	assert_has_key(stored, String(TWO_ENGINE_HULL), "the hull's fit is persisted")
	var entry: Dictionary = stored[String(TWO_ENGINE_HULL)]
	assert_eq(entry.size(), FitData.FIT_SLOT_KEYS.size(), "every type is persisted")
	assert_true(entry["engines"] is Array, "engines persist as an array")
	assert_eq(entry["engines"], ["e_ion", "e_std"], "the engine set persists cell by cell")
	assert_eq(entry["power"], "p_mk2", "power persists as one id")


func test_set_fit_slot_refuses_an_index_the_hull_has_no_cell_for() -> void:
	var profile = _fresh()
	_watch(profile)
	assert_true(profile.set_fit_slot(TWO_ENGINE_HULL, &"engines", 0, &"e_std"), "engine cell 0")
	assert_true(profile.set_fit_slot(TWO_ENGINE_HULL, &"engines", 1, &"e_ion"), "engine cell 1")
	assert_false(profile.set_fit_slot(TWO_ENGINE_HULL, &"engines", 2, &"e_std"), "no cell 2")
	assert_false(profile.set_fit_slot(TWO_ENGINE_HULL, &"engines", -1, &"e_std"), "no cell -1")
	assert_false(
		profile.set_fit_slot(TWO_ENGINE_HULL, &"boosters", 0, &"b_fold"),
		"the Delver has no B cell"
	)
	assert_true(profile.set_fit_slot(TWO_ENGINE_HULL, &"power", 0, &"p_core"), "power cell 0")
	assert_false(profile.set_fit_slot(TWO_ENGINE_HULL, &"power", 1, &"p_core"), "power is one cell")
	assert_false(
		profile.set_fit_slot(TWO_ENGINE_HULL, &"hull", 0, &"h_plate_light"),
		"the hull stat is not a slot type"
	)
	assert_eq(
		profile.fit_for(TWO_ENGINE_HULL)[&"engines"], ["e_std", "e_ion"], "both cells hold"
	)
	assert_eq(profile.fit_for(TWO_ENGINE_HULL)[&"power"], "p_core", "the reactor is one id")

	## The Mule's weapons array is one long: index 0 is its only W cell.
	assert_true(
		profile.set_fit_slot(THREE_ENGINE_HULL, &"weapons", 0, &"w_mining"), "Mule W cell 0"
	)
	assert_false(
		profile.set_fit_slot(THREE_ENGINE_HULL, &"weapons", 1, &"w_cannon"), "and no W cell 1"
	)
	assert_eq(
		profile.fit_for(THREE_ENGINE_HULL)[&"weapons"], ["w_mining"], "one W cell, one entry"
	)

	## A cell can be emptied, and an emptied cell stays in the array.
	assert_true(profile.set_fit_slot(TWO_ENGINE_HULL, &"engines", 1, &""), "a cell can be emptied")
	assert_eq(
		profile.fit_for(TWO_ENGINE_HULL)[&"engines"], ["e_std", ""], "and then it is empty"
	)

	## Both spellings address the same fit (a loaded ConfigFile gives String).
	assert_eq(
		profile.fit_for(String(TWO_ENGINE_HULL))[String("engines")],
		["e_std", ""],
		"a String hull id and slot key read the same entry"
	)


## ---------------------------------------------------------------------------
## Migration: v1 to v3 files load clean and are not rewritten
## ---------------------------------------------------------------------------


func test_a_v2_single_string_fit_reads_as_a_padded_array() -> void:
	var fixture := ConfigFile.new()
	fixture.set_value(SECTION, "save_version", 2)
	fixture.set_value(SECTION, "credits", 4321)
	fixture.set_value(
		SECTION,
		"fits",
		{
			"ship_vanguard":
			{
				"engine": "e_std",
				"power": "p_std",
				"weapons": "w_laser",
				"shields": "s_light",
			},
		}
	)
	assert_eq(fixture.save(PROFILE_PATH), OK, "the v2 fixture is written")

	var profile = _fresh()
	profile.reload()
	assert_eq(profile.credits(), 4321, "the v2 file loads rather than defaulting")

	var fit: Dictionary = profile.fit_for(&"ship_vanguard")
	assert_eq(fit[&"engines"], ["e_std"], "the singular engine key is the engine set")
	assert_eq(
		fit[&"weapons"], ["w_laser", "", ""], "one string becomes a one-element array, padded"
	)
	assert_eq(fit[&"shields"], ["s_light"], "at this hull's single S cell")
	assert_eq(fit[&"armour"], ["", ""], "a type the v2 file never wrote is empty at capacity")
	assert_eq(fit[&"power"], "p_std", "power keeps its one id")
	assert_eq(fit.size(), FitData.FIT_SLOT_KEYS.size(), "the read shape is complete")

	## The migration read never rewrites the file: the stored entries are still
	## single strings and the version is still 2.
	var on_disk := ConfigFile.new()
	assert_eq(on_disk.load(PROFILE_PATH), OK)
	assert_eq(int(on_disk.get_value(SECTION, "save_version", 0)), 2, "still a v2 file on disk")
	var stored: Dictionary = on_disk.get_value(SECTION, "fits", {})
	var entry: Dictionary = stored["ship_vanguard"]
	assert_eq(entry["weapons"], "w_laser", "the file still holds the v2 single string")
	assert_eq(entry["engine"], "e_std", "and its singular engine key")
	var raw: Dictionary = profile.fits()
	var raw_entry: Dictionary = raw["ship_vanguard"]
	assert_eq(raw_entry["weapons"], "w_laser", "fits() reads the file's own shape")


func test_a_v3_fit_loads_clean_and_the_first_write_persists_version_5() -> void:
	assert_eq(Profile.MIN_READABLE_VERSION, 1, "v1 to v3 files stay readable")
	assert_eq(Profile.SAVE_VERSION, 5, "writes persist save v5 (P2-B proper, CONTRACTS section 13)")
	var fixture := ConfigFile.new()
	fixture.set_value(SECTION, "save_version", 3)
	fixture.set_value(SECTION, "credits", 2500)
	fixture.set_value(SECTION, "owned_ships", ["ship_miner"])
	fixture.set_value(SECTION, "active_ship", "ship_miner")
	fixture.set_value(SECTION, "fits", {"ship_miner": {"engine": "e_std", "power": "p_std"}})
	fixture.set_value(SECTION, "vitals", {"ship_miner": {"hull": 640, "shield": 220, "fuel": 143}})
	assert_eq(fixture.save(PROFILE_PATH), OK, "the v3 fixture is written")

	var profile = _fresh()
	profile.reload()
	assert_eq(profile.credits(), 2500, "the v3 file loads")
	assert_eq(profile.active_ship(), &"ship_miner", "its ship survives")
	var vitals: Dictionary = profile.vitals_of(&"ship_miner")
	assert_eq(int(vitals["fuel"]), 143, "the v3 fuel key survives the v4 read")
	assert_eq(
		profile.fit_for(&"ship_miner")[&"engines"],
		["e_std", ""],
		"the v3 single id is padded to the Delver's two engine cells"
	)

	assert_true(profile.set_fit_slot(&"ship_miner", &"engines", 1, &"e_ion"), "a second drive fits")
	profile.save()
	var on_disk := ConfigFile.new()
	assert_eq(on_disk.load(PROFILE_PATH), OK)
	assert_eq(int(on_disk.get_value(SECTION, "save_version", 0)), 5, "a write persists save v5")
	var stored: Dictionary = on_disk.get_value(SECTION, "fits", {})
	var entry: Dictionary = stored["ship_miner"]
	assert_eq(entry["engines"], ["e_std", "e_ion"], "the write persists the array shape")
	assert_eq(entry["power"], "p_std", "the migrated power id is kept")

	var second = _fresh()
	second.reload()
	assert_eq(
		second.fit_for(TWO_ENGINE_HULL)[&"engines"], ["e_std", "e_ion"], "and it reloads as stored"
	)


func test_a_v1_file_without_a_fits_key_answers_the_empty_shape() -> void:
	var fixture := ConfigFile.new()
	fixture.set_value(SECTION, "save_version", 1)
	fixture.set_value(SECTION, "credits", 777)
	assert_eq(fixture.save(PROFILE_PATH), OK, "the v1 fixture is written")

	var profile = _fresh()
	profile.reload()
	assert_eq(profile.credits(), 777, "the v1 file loads")
	assert_true(profile.fits().is_empty(), "a v1 file holds no fit")
	assert_eq(profile.fit_for(TWO_ENGINE_HULL)[&"engines"], ["", ""], "and none is invented")
	assert_eq(
		profile.fit_for(THREE_ENGINE_HULL)[&"engines"], ["", "", ""], "however many cells it has"
	)
	assert_eq(
		profile.fit_for(TWO_ENGINE_HULL).size(), FitData.FIT_SLOT_KEYS.size(), "the shape is whole"
	)


## ---------------------------------------------------------------------------
## Signals, and the hulls that cannot fit anything
## ---------------------------------------------------------------------------


func test_fit_writes_emit_the_fits_key_and_no_ops_do_not() -> void:
	var profile = _fresh()
	_watch(profile)

	assert_true(
		profile.set_fit(TWO_ENGINE_HULL, {&"engines": [&"e_std", &"e_std"]}), "an engine set fits"
	)
	assert_eq(_signals, [&"fits"], "set_fit emits the fits key")

	_signals.clear()
	assert_true(profile.set_fit_slot(TWO_ENGINE_HULL, &"weapons", 0, &"w_laser"), "one W cell")
	assert_eq(_signals, [&"fits"], "set_fit_slot emits the fits key")

	## Re-storing what is already there is silent, like every other setter here.
	_signals.clear()
	assert_true(
		profile.set_fit(TWO_ENGINE_HULL, profile.fit_for(TWO_ENGINE_HULL)), "the same fit again"
	)
	assert_true(_signals.is_empty(), "an equal set_fit writes nothing: %s" % str(_signals))

	_signals.clear()
	assert_true(profile.set_fit_slot(TWO_ENGINE_HULL, &"weapons", 0, &"w_laser"), "the same cell")
	assert_true(_signals.is_empty(), "an equal set_fit_slot writes nothing: %s" % str(_signals))

	_signals.clear()
	profile.clear_fit(TWO_ENGINE_HULL)
	assert_eq(_signals, [&"fits"], "clear_fit emits the fits key")

	_signals.clear()
	profile.clear_fit(TWO_ENGINE_HULL)
	assert_true(_signals.is_empty(), "clearing an absent fit is silent")

	assert_eq(profile.fit_for(TWO_ENGINE_HULL)[&"engines"], ["", ""], "and the fit is empty again")


func test_an_npc_or_unknown_hull_fits_nothing_and_says_so() -> void:
	var profile = _fresh()
	_watch(profile)
	assert_true(profile.fit_for(NPC_HULL).is_empty(), "an NPC hull has no fit")
	assert_true(profile.fit_for(&"ship_typo").is_empty(), "an unknown id has no fit")
	assert_false(profile.set_fit(NPC_HULL, {&"engines": [&"e_std"]}), "an NPC hull fits nothing")
	assert_false(
		profile.set_fit_slot(NPC_HULL, &"engines", 0, &"e_std"), "not even an engine cell"
	)
	profile.clear_fit(NPC_HULL)
	assert_true(_signals.is_empty(), "refused and absent writes emit nothing: %s" % str(_signals))
	assert_true(profile.fits().is_empty(), "and nothing was stored")


## ---------------------------------------------------------------------------
## The module inventory behind a fit
## ---------------------------------------------------------------------------


func test_base_module_id_resolves_instances_and_passes_base_ids_through() -> void:
	var profile = _fresh()
	profile.set_modules(
		{
			"mod_0007":
			{
				"base_id": "s_heavy",
				"rarity": 2,
				"prefixes": ["hot"],
				"suffixes": [],
				"count": 1,
			},
			"mod_0008": {"count": 1},
		}
	)
	assert_eq(profile.base_module_id(&"mod_0007"), &"s_heavy", "an instance resolves to its base")
	assert_eq(profile.base_module_id(&"w_laser"), &"w_laser", "a base id passes through unchanged")
	assert_eq(profile.base_module_id(&"mod_0008"), &"mod_0008", "a record with no base id is itself")
	assert_eq(profile.base_module_id(&"mod_9999"), &"mod_9999", "so is an id the dict does not hold")
	assert_eq(profile.base_module_id(&""), &"", "and the empty id stays empty")

	profile.save()
	var reloaded = _fresh()
	reloaded.reload()
	assert_eq(reloaded.base_module_id(&"mod_0007"), &"s_heavy", "the instance survives the save")
	assert_eq(reloaded.module_count(&"mod_0007"), 1, "with its count")


func test_module_counts_add_and_take() -> void:
	var profile = _fresh()
	_watch(profile)
	assert_eq(profile.module_count(&"w_laser"), 0, "an empty inventory holds none")

	profile.add_module(&"w_laser", 3)
	assert_eq(profile.module_count(&"w_laser"), 3, "three are held")
	assert_eq(_signals, [&"modules"], "add_module emits the modules key")

	_signals.clear()
	profile.add_module(&"w_laser")
	assert_eq(profile.module_count(&"w_laser"), 4, "the default adds one")
	assert_eq(_signals, [&"modules"], "and emits")

	_signals.clear()
	assert_true(profile.take_module(&"w_laser", 1), "one comes out")
	assert_eq(profile.module_count(&"w_laser"), 3)
	assert_eq(_signals, [&"modules"], "take_module emits the modules key")

	_signals.clear()
	assert_false(profile.take_module(&"w_laser", 9), "you cannot take what you do not hold")
	assert_eq(profile.module_count(&"w_laser"), 3, "a refused take writes nothing")
	assert_false(profile.take_module(&"w_laser", 0), "and neither does a zero take")
	assert_true(_signals.is_empty(), "a refused take is silent: %s" % str(_signals))

	profile.add_module(&"w_laser", 0)
	profile.add_module(&"", 2)
	assert_true(_signals.is_empty(), "a no-op add is silent")

	assert_true(profile.take_module(&"w_laser", 3), "emptying the entry")
	assert_eq(profile.module_count(&"w_laser"), 0)
	assert_false(profile.modules().has("w_laser"), "an emptied entry is erased, like remove_cargo")

	## A record created here carries the base id and the count only: 15 section 6
	## rolls affixes at creation, and this helper is not that roll.
	profile.add_module(&"mod_0009", 2)
	var record: Dictionary = profile.modules()["mod_0009"]
	assert_eq(record["base_id"], "mod_0009", "a common module's base id is itself")
	assert_eq(int(record["count"]), 2, "and its count")
	assert_false(record.has("rarity"), "no affix roll is invented here")

	profile.save()
	var reloaded = _fresh()
	reloaded.reload()
	assert_eq(reloaded.module_count(&"mod_0009"), 2, "the inventory round trips")
	assert_eq(reloaded.base_module_id(&"mod_0009"), &"mod_0009", "with its base id")


## ---------------------------------------------------------------------------
## Helpers
## ---------------------------------------------------------------------------


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


func _delete_file(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


## Structural equality: `==` on nested dictionaries is not dependable across a
## ConfigFile round trip, where key order is not preserved.
func _deep_eq(a: Variant, b: Variant) -> bool:
	if a is Dictionary and b is Dictionary:
		var left: Dictionary = a
		var right: Dictionary = b
		if left.size() != right.size():
			return false
		for key: Variant in left.keys():
			if not right.has(key):
				return false
			if not _deep_eq(left[key], right[key]):
				return false
		return true
	if a is Array and b is Array:
		var left_array: Array = a
		var right_array: Array = b
		if left_array.size() != right_array.size():
			return false
		for index: int in range(left_array.size()):
			if not _deep_eq(left_array[index], right_array[index]):
				return false
		return true
	if (a is float) or (b is float):
		return is_equal_approx(float(a), float(b))
	return a == b
