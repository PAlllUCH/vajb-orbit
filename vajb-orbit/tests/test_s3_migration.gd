@tool
extends McpTestSuite
## Suite s3_migration: the save v5 -> v6 flag day (15 section 8, CONTRACTS section 15) -
## every v5 `{base_id, count}` inventory record becomes `count` **Common** instances with
## their own minted ids, once, and `_load_profile` is its only production caller.
##
## The two acceptance figures the pin names are the two tests below: a v5 file with a
## stacked record reads back as that many instances, and a second migration call returns
## 0. v5 stock was never rolled (15 section 6 rolls at creation), so Common with no affix
## rows is the honest default, and the owner's retro-roll alternative is one call at
## migration. The write the flag day makes persists v6, so the file on disk carries the
## instances rather than the stacked record.
##
## Profiles are throwaway instances of the autoload script whose `save_path` is repointed
## at a scratch file before the first mutation (the `test_p1_profile.gd` harness): no
## instance enters the tree, so the debounced save Timer does not exist and the flag day's
## write lands immediately, which is what lets the on-disk shape be asserted here.

const Profile := preload("res://autoload/player_profile.gd")
const ModuleData := preload("res://game/module_catalog.gd")

const PROFILE_PATH := "user://test_s3_migration.cfg"
const SECTION := "profile"

const LASER: StringName = &"w_laser"
const ION: StringName = &"e_ion"
const CARGO: StringName = &"u_cargo"
const LIGHT_SHIELD: StringName = &"s_light"

var _profiles: Array[Node] = []


func suite_name() -> String:
	return "s3_migration"


func setup() -> void:
	_delete_file(PROFILE_PATH)


func teardown() -> void:
	for profile: Node in _profiles:
		if is_instance_valid(profile):
			profile.free()
	_profiles.clear()


func suite_teardown() -> void:
	_delete_file(PROFILE_PATH)


## ---------------------------------------------------------------------------
## The flag day
## ---------------------------------------------------------------------------


func test_a_v5_stacked_record_becomes_that_many_common_instances() -> void:
	_write_fixture({LASER: 3})
	var profile = _fresh()
	profile.reload()
	assert_eq(profile.credits(), 4321, "the rest of the file reads as it always did")
	assert_false(
		profile.modules().has(String(LASER)), "the stacked record's key is gone"
	)
	assert_eq(profile.modules().size(), 3, "and three records took its place")
	var ids: Array[StringName] = profile.instances_of(LASER)
	assert_eq(
		ids,
		[
			StringName(Profile.INSTANCE_ID_FORMAT % 1),
			StringName(Profile.INSTANCE_ID_FORMAT % 2),
			StringName(Profile.INSTANCE_ID_FORMAT % 3),
		],
		"three instances, minted from 1 in the bag's own order"
	)
	for id: StringName in ids:
		var record: Dictionary = profile.instance(id)
		assert_eq(String(record[Profile.KEY_BASE_ID]), String(LASER), "%s keeps the base id" % id)
		assert_eq(
			String(record[Profile.KEY_RARITY]),
			ModuleData.RARITY_COMMON,
			"%s is Common: v5 stock was never rolled" % id
		)
		assert_true(
			_deep_eq(record[Profile.KEY_PREFIXES], []), "%s carries no prefix row" % id
		)
		assert_true(_deep_eq(record[Profile.KEY_SUFFIXES], []), "%s carries no suffix" % id)
		assert_eq(int(record[Profile.KEY_COUNT]), 1, "%s is in the bag" % id)

	## The flag day wrote the file itself: v6, three records, no stacked key.
	var on_disk := ConfigFile.new()
	assert_eq(on_disk.load(PROFILE_PATH), OK, "the migrated file reads back")
	assert_eq(int(on_disk.get_value(SECTION, "save_version", 0)), 6, "the flag day writes v6")
	var stored: Dictionary = on_disk.get_value(SECTION, "modules", {})
	assert_eq(stored.size(), 3, "three records on disk")
	assert_false(stored.has(String(LASER)), "and no stacked record")


func test_the_second_migration_call_returns_zero() -> void:
	_write_fixture({LASER: 3})
	var profile = _fresh()
	profile.reload()
	assert_eq(profile.modules().size(), 3, "the first load migrated the record")
	assert_eq(profile.migrate_module_instances(), 0, "a second call has nothing left to do")
	assert_eq(profile.modules().size(), 3, "and writes nothing: three instances, not six")
	assert_eq(profile.instances_of(LASER).size(), 3, "the bag still holds one per v5 unit")

	var again = _fresh()
	again.reload()
	assert_eq(again.modules().size(), 3, "a second load of the migrated file migrates nothing")
	assert_eq(again.migrate_module_instances(), 0, "and the call answers 0 again")
	assert_eq(again.instances_of(LASER).size(), 3, "still three instances")


func test_a_v6_bag_and_an_empty_bag_have_nothing_to_migrate() -> void:
	var profile = _fresh()
	assert_eq(profile.migrate_module_instances(), 0, "an empty bag has nothing to migrate")
	## A v5-shaped record cannot even reach the bag through `set_modules` -- it normalises
	## to the six-key shape -- so the in-memory call only ever meets v6 records, which is
	## the idempotence the pin asks for from either direction.
	var id: StringName = profile.add_instance(
		LIGHT_SHIELD, &"magic", [{"id": "sturdy", "value": 0.15}], ["whale"]
	)
	assert_eq(
		profile.migrate_module_instances(), 0, "and a record carrying an instance_id is skipped"
	)
	assert_eq(profile.module_count(id), 1, "it is left exactly as it was")
	assert_eq(String(profile.instance(id)[Profile.KEY_RARITY]), "magic", "affixes and all")
	assert_true(
		_deep_eq(
			profile.instance(id)[Profile.KEY_PREFIXES], [{"id": "sturdy", "value": 0.15}]
		),
		"and its prefix row"
	)


## A file that is part-migrated already: the record that carries an `instance_id` keeps
## its mint and its affixes, the short ones convert, and a bare `{count: n}` record is read
## with its own key as the base id (the tolerance `base_module_id` has always had).
func test_a_mixed_bag_converts_only_the_short_records() -> void:
	var fixture := ConfigFile.new()
	fixture.set_value(SECTION, "save_version", 5)
	fixture.set_value(SECTION, "credits", 4321)
	fixture.set_value(SECTION, "instance_counter", 0)
	fixture.set_value(
		SECTION,
		"modules",
		{
			"mod_0009":
			{
				"instance_id": "mod_0009",
				"base_id": String(LIGHT_SHIELD),
				"rarity": "rare",
				"prefixes": [{"id": "sturdy", "value": 0.2}],
				"suffixes": ["whale"],
				"count": 1,
			},
			String(ION): {"base_id": String(ION), "count": 2},
			String(CARGO): {"count": 1},
		}
	)
	assert_eq(fixture.save(PROFILE_PATH), OK, "the mixed v5 fixture is written")

	var profile = _fresh()
	profile.reload()
	assert_eq(profile.modules().size(), 4, "one kept record plus three minted ones")
	assert_eq(
		String(profile.instance(&"mod_0009")[Profile.KEY_RARITY]),
		"rare",
		"the record that already had an instance_id keeps its mint and its rarity"
	)
	assert_true(
		_deep_eq(
			profile.instance(&"mod_0009")[Profile.KEY_PREFIXES],
			[{"id": "sturdy", "value": 0.2}]
		),
		"and its affix row"
	)
	var ions: Array[StringName] = profile.instances_of(ION)
	assert_eq(ions.size(), 2, "the stacked record became two instances")
	for id: StringName in ions:
		assert_eq(
			String(profile.instance(id)[Profile.KEY_RARITY]),
			ModuleData.RARITY_COMMON,
			"%s is Common" % id
		)
	var bare: Array[StringName] = profile.instances_of(CARGO)
	assert_eq(bare.size(), 1, "a bare `{count: n}` record became one instance of its own key")
	assert_eq(
		profile.instance(bare[0])[Profile.KEY_BASE_ID],
		String(CARGO),
		"and the key is its base id"
	)
	assert_eq(profile.migrate_module_instances(), 0, "a second call converts nothing more")
	assert_eq(profile.modules().size(), 4, "and the bag is unchanged")


## CONTRACTS section 15: the counter never rewinds, so a migrated file keeps minting after
## the number it had already spent.
func test_the_mint_continues_from_the_files_own_counter() -> void:
	_write_fixture({LASER: 2}, 7)
	var profile = _fresh()
	profile.reload()
	assert_eq(
		profile.instances_of(LASER),
		[&"mod_0008", &"mod_0009"],
		"the two instances continue from the file's counter of 7"
	)
	var minted: StringName = profile.add_instance(LASER, ModuleData.RARITY_COMMON, [], [])
	assert_eq(minted, &"mod_0010", "and the next mint is the one after the last")
	profile.save()
	var reloaded = _fresh()
	reloaded.reload()
	assert_eq(
		reloaded.add_instance(LASER, ModuleData.RARITY_COMMON, [], []),
		&"mod_0011",
		"which persists with the save"
	)


## ---------------------------------------------------------------------------
## Helpers
## ---------------------------------------------------------------------------


## A pre-v6 file: `save_version` 5 and the `{base_id, count}` module records of the
## stamped-stock shape, plus the mint counter when one is asked for.
func _write_fixture(records: Dictionary, counter: int = 0) -> void:
	var modules: Dictionary = {}
	for base: Variant in records:
		modules[String(base)] = {"base_id": String(base), "count": int(records[base])}
	var fixture := ConfigFile.new()
	fixture.set_value(SECTION, "save_version", 5)
	fixture.set_value(SECTION, "credits", 4321)
	fixture.set_value(SECTION, "owned_ships", ["ship_vanguard"])
	fixture.set_value(SECTION, "instance_counter", counter)
	fixture.set_value(SECTION, "modules", modules)
	assert_eq(fixture.save(PROFILE_PATH), OK, "the v5 fixture is written")


func _fresh():
	var profile := Profile.new()
	profile.save_path = PROFILE_PATH
	_profiles.append(profile)
	return profile


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
