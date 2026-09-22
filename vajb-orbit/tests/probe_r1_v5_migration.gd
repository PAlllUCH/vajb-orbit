extends Node
## R1 evidence probe (P2-B proper review): the save v5 flag day, measured from R1's own
## fixtures. Every fixture here is built by this file, not borrowed from a worker suite:
## the retired `upgrades` record is written in both spellings `ConfigFile` can carry
## (the shipped Array of ids and a Dictionary of flags), and the load path is driven
## through a throwaway instance of the autoload script the way a real boot drives it
## (`_load_catalog()` then `reload()`).
##
## Run:  godot --headless --path vajb-orbit res://tests/probe_r1_v5_migration.tscn --quit-after 600
## Signal: the [R1-MIGRATION] lines; the last line is [R1-MIGRATION] done.
##
## Self-bound: `FRAME_CAP` frames and a hard `LOOP_CAP` on every iteration, so a wedged
## probe exits by itself even without `--quit-after` (L82's lesson).

const Profile := preload("res://autoload/player_profile.gd")
const Catalog := preload("res://game/station_catalog.gd")
const ModuleData := preload("res://game/module_catalog.gd")

const PROFILE_PATH := "user://probe_r1_v5.cfg"
const SECTION := "profile"
const FRAME_CAP := 600
const LOOP_CAP := 64

## 09 section 4 item 13's six retired rows and the successor each one carries in
## `LEGACY_UPGRADE_MODULES`. R1 states both lists here so a drift between the shipped
## constant and this review's reading of 09 is visible in the printout.
const RETIRED: Array[StringName] = [
	&"upgrade_generator", &"upgrade_shield", &"upgrade_engine",
	&"upgrade_module", &"upgrade_extra", &"upgrade_drone",
]
const SUCCESSORS: Array[StringName] = [
	&"p_mk2", &"s_heavy", &"e_ion", &"c_scanner", &"u_cargo", &"u_drones",
]

var _frames := 0


func _ready() -> void:
	_delete_file(PROFILE_PATH)
	_probe_the_table()
	_probe_the_v4_fixture()
	_probe_the_dict_spelling()
	_probe_a_v1_fixture()
	_probe_a_v3_fixture_without_the_record()
	_probe_a_v5_fixture()
	_probe_the_retired_api_is_gone()
	_delete_file(PROFILE_PATH)
	print("[R1-MIGRATION] done")
	get_tree().quit(0)


func _process(_delta: float) -> void:
	## The hard self-bound: whatever a test above does, this node quits the run.
	_frames += 1
	if _frames > FRAME_CAP:
		print("[R1-MIGRATION] FRAME CAP %d reached; quitting" % FRAME_CAP)
		get_tree().quit(3)


## ------------------------------------------------------------------ the fixture writer


func _fixture(version: int, record: Variant) -> void:
	var file := ConfigFile.new()
	file.set_value(SECTION, "save_version", version)
	file.set_value(SECTION, "credits", 4321)
	file.set_value(SECTION, "owned_ships", ["ship_vanguard"])
	file.set_value(SECTION, "active_ship", "ship_vanguard")
	if record != null:
		file.set_value(SECTION, "upgrades", record)
	file.save(PROFILE_PATH)


func _fresh() -> Node:
	var profile: Node = Profile.new()
	profile.set(&"save_path", PROFILE_PATH)
	profile.call(&"_load_catalog")
	profile.reload()
	return profile


func _delete_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


func _on_disk() -> ConfigFile:
	var file := ConfigFile.new()
	file.load(PROFILE_PATH)
	return file


## ------------------------------------------------------------------------- the checks


## The constant itself, read against 09's six rows and the two lists above.
func _probe_the_table() -> void:
	print("[R1-MIGRATION] table size=%d" % Profile.LEGACY_UPGRADE_MODULES.size())
	var index := 0
	while index < RETIRED.size() and index < LOOP_CAP:
		var retired: StringName = RETIRED[index]
		var successor: StringName = SUCCESSORS[index]
		print("[R1-MIGRATION] row %d %s -> %s (shipped=%s)" % [
			index,
			retired,
			successor,
			Profile.LEGACY_UPGRADE_MODULES.get(retired, &"<missing>"),
		])
		index += 1


## A v4 file with all six installed, in the shipped Array spelling.
func _probe_the_v4_fixture() -> void:
	var ids: Array = []
	for retired: StringName in RETIRED:
		ids.append(String(retired))
	_fixture(4, ids)
	var profile := _fresh()
	var migrated: int = profile.call(&"retire_legacy_upgrades")
	print("[R1-MIGRATION] v4 load: modules=%d" % profile.modules().size())
	var index := 0
	while index < RETIRED.size() and index < LOOP_CAP:
		print("[R1-MIGRATION] v4 successor %s count=%d (retired %s count=%d)" % [
			SUCCESSORS[index],
			int(profile.call(&"module_count", SUCCESSORS[index])),
			RETIRED[index],
			int(profile.call(&"module_count", RETIRED[index])),
		])
		index += 1
	print("[R1-MIGRATION] v4 credits=%d (the rest of the file reads as it always did)" % (
		int(profile.call(&"credits"))
	))
	print("[R1-MIGRATION] v4 second call answers %d, a second load reads %d records" % [
		migrated,
		_load_again(),
	])
	var disk := _on_disk()
	print("[R1-MIGRATION] v4 on disk: save_version=%d upgrades_key=%s module_records=%d" % [
		int(disk.get_value(SECTION, "save_version", 0)),
		disk.has_section_key(SECTION, "upgrades"),
		(disk.get_value(SECTION, "modules", {}) as Dictionary).size(),
	])
	profile.free()


func _load_again() -> int:
	var again := _fresh()
	var count: int = again.modules().size()
	var second := int(again.call(&"retire_legacy_upgrades"))
	print("[R1-MIGRATION] a v5 file loads as %d records and has %d left to migrate" % [
		count, second
	])
	again.free()
	return count


## The second spelling the shipped v4 writer never produced: a Dictionary of flags.
func _probe_the_dict_spelling() -> void:
	_fixture(4, {"upgrade_engine": true, "upgrade_shield": false})
	var profile := _fresh()
	var migrated: int = profile.call(&"retire_legacy_upgrades")
	print("[R1-MIGRATION] dict spelling: migrated=%d modules=%d e_ion=%d s_heavy=%d" % [
		migrated,
		profile.modules().size(),
		int(profile.call(&"module_count", &"e_ion")),
		int(profile.call(&"module_count", &"s_heavy")),
	])
	profile.free()


func _probe_a_v1_fixture() -> void:
	_fixture(1, ["upgrade_engine", "upgrade_generator"])
	var profile := _fresh()
	print("[R1-MIGRATION] v1 fixture: credits=%d modules=%d e_ion=%d p_mk2=%d" % [
		int(profile.call(&"credits")),
		profile.modules().size(),
		int(profile.call(&"module_count", &"e_ion")),
		int(profile.call(&"module_count", &"p_mk2")),
	])
	profile.free()


func _probe_a_v3_fixture_without_the_record() -> void:
	_fixture(3, null)
	var profile := _fresh()
	print("[R1-MIGRATION] v3 fixture, no record: credits=%d modules=%d migrate=%d" % [
		int(profile.call(&"credits")),
		profile.modules().size(),
		int(profile.call(&"retire_legacy_upgrades")),
	])
	profile.free()
	var disk := _on_disk()
	print("[R1-MIGRATION] v3 on disk stays save_version=%d (nothing to migrate, so no rewrite)" % (
		int(disk.get_value(SECTION, "save_version", 0))
	))


func _probe_a_v5_fixture() -> void:
	## The shipped v5 writer: no record at all, and the loader must not invent one.
	_fixture(5, null)
	var profile := _fresh()
	print("[R1-MIGRATION] v5 fixture: modules=%d migrate=%d" % [
		profile.modules().size(),
		int(profile.call(&"retire_legacy_upgrades")),
	])
	profile.free()
	## A spoofed v5 file that still carries the record: the load path's own threshold
	## (`version < 5`) does not fire, so the record survives until something calls the
	## migration by hand. Not reachable from a shipped writer (a v4 build writes 4).
	_fixture(5, ["upgrade_drone"])
	var spoofed := _fresh()
	print("[R1-MIGRATION] v5 with a stale record: modules=%d (the `version < 5` gate held)" % (
		spoofed.modules().size()
	))
	print("[R1-MIGRATION] v5 with a stale record, migration called by hand: %d -> u_drones=%d" % [
		int(spoofed.call(&"retire_legacy_upgrades")),
		int(spoofed.call(&"module_count", &"u_drones")),
	])
	var disk := _on_disk()
	print("[R1-MIGRATION] v5 spoofed on disk after the hand call: upgrades_key=%s" % (
		disk.has_section_key(SECTION, "upgrades")
	))
	spoofed.free()


## The retired API, measured on a live throwaway instance and on the two scripts.
func _probe_the_retired_api_is_gone() -> void:
	var profile: Node = Profile.new()
	var methods: Array[String] = []
	for entry: Dictionary in profile.get_method_list():
		methods.append(String(entry.get("name", "")))
	var removed: Dictionary = {
		"has_upgrade": false, "installed_upgrades": false, "install_upgrade": false,
	}
	for name_text: String in removed:
		removed[name_text] = methods.has(name_text)
	print("[R1-MIGRATION] profile instance methods present: has_upgrade=%s installed_upgrades=%s install_upgrade=%s" % [
		removed["has_upgrade"], removed["installed_upgrades"], removed["install_upgrade"]
	])
	var constants: Dictionary = (profile.get_script() as Script).get_script_constant_map()
	print("[R1-MIGRATION] profile constants: KEY_UPGRADES=%s KEY_RETIRED_UPGRADES=%s LEGACY_UPGRADE_MODULES=%s EVENT_FIT_MODULE=%s" % [
		constants.has("KEY_UPGRADES"),
		constants.has("KEY_RETIRED_UPGRADES"),
		constants.has("LEGACY_UPGRADE_MODULES"),
		constants.has("EVENT_FIT_MODULE"),
	])
	print("[R1-MIGRATION] save version constants: SAVE_VERSION=%d MIN_READABLE_VERSION=%d" % [
		int(Profile.SAVE_VERSION), int(Profile.MIN_READABLE_VERSION)
	])
	var catalog: RefCounted = Catalog.new()
	var catalog_constants: Dictionary = (catalog.get_script() as Script).get_script_constant_map()
	print("[R1-MIGRATION] StationCatalog constants: UPGRADES=%s UPGRADE_SLOTS=%s" % [
		catalog_constants.has("UPGRADES"), catalog_constants.has("UPGRADE_SLOTS"),
	])
	print("[R1-MIGRATION] the six successors are catalogue modules: %s" % [_successors_are_modules()])
	print("[R1-MIGRATION] the six retired ids are not module ids: %s" % [_retired_are_not_modules()])
	profile.free()


func _successors_are_modules() -> String:
	var out: Array[String] = []
	var index := 0
	while index < SUCCESSORS.size() and index < LOOP_CAP:
		out.append("%s=%s" % [
			SUCCESSORS[index], not ModuleData.module(SUCCESSORS[index]).is_empty()
		])
		index += 1
	return ", ".join(out)


func _retired_are_not_modules() -> String:
	var out: Array[String] = []
	var index := 0
	while index < RETIRED.size() and index < LOOP_CAP:
		out.append("%s=%s" % [
			RETIRED[index], ModuleData.module(RETIRED[index]).is_empty()
		])
		index += 1
	return ", ".join(out)
