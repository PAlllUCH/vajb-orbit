@tool
extends McpTestSuite
## Suite s2_6_gate_hygiene: the gate's own hermeticity (CONTRACTS section 14, L90/L93).
##
## The gate's complaint (L93) was that one tree reads `passed=437 failed=0` on a sandboxed
## `user://` and 433/4 against the owner's live account. The cause is not a flaky test: the
## runner let every suite read the **live** profile - its packs, its credits and above all
## its fits, which decide the launched weapon slots - so the counts depended on the account
## (`test_engine2_dock.gd` 2, `test_engine2_fixes.gd` 1, `test_engine2_wiring.gd` 1).
##
## `tests/headless_runner.gd:_seed_scratch_store` cures it at boot: it creates
## `user://_gate_scratch/`, repoints `PlayerProfile.save_path` inside it, resets the
## **in-memory** profile (the autoload loaded the live file long before the runner's `_ready`)
## and seeds the deterministic default. This suite pins that cure from the inside - the half
## the acceptance run cannot see - and it is the in-process form of "two consecutive runs
## with a mutated live profile present read identical counts":
##
## 1. the store the gate reads is the sandbox: the path, the directory, the seeded file, and
##    the second writable store, `EconomyLog` (which suites hand back to the live default in
##    their own teardowns);
## 2. the seeded account is the deterministic default, so the launch flies the hull's own
##    standard fit and every suite reads the same slots on every run;
## 3. a **mutated** file sitting at the store path cannot reach the in-memory store: re-running
##    the boot sequence - the harness's own call, not a copy of it - leaves identical readings.
##
## Nothing here awaits a frame. Under the editor's own runner the store is not sandboxed, so
## the suite skips: it gates the headless gate.

const ShipFitScript := preload("res://game/ship_fit.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")
const RunnerScript := preload("res://tests/headless_runner.gd")
const Log := preload("res://game/economy_log.gd")

const GAME_SCENE := "res://game/game.tscn"
const PROFILE_SERVICE := &"PlayerProfile"
const SANDBOX_DIR := "user://_gate_scratch"
const SANDBOX_PROFILE := "user://_gate_scratch/profile.cfg"
const SANDBOX_LOG := "user://_gate_scratch/economy_log.txt"
const LIVE_LOG := "user://economy_log.txt"

## The mutation stands in for the owner's account: same file shape, deliberately different
## numbers, and a fit - `[w_cannon]` - that mounts no laser, which is the shape that took the
## four coupled tests from green to red on a live profile.
const MUTATED_CREDITS := ProfileScript.DEFAULT_CREDITS + 777
const MUTATED_LASER_AMMO := 7
const MUTATED_FIT: Dictionary = {
	&"engines": [&"e_std"],
	&"power": &"p_std",
	&"weapons": [&"w_cannon"],
	&"shields": [&"s_light"],
	&"armour": [&"h_plate_light"],
}

var _scene: Node2D = null


func suite_name() -> String:
	return "s2_6_gate_hygiene"


func suite_setup(_ctx: Dictionary) -> void:
	if _runner() == null:
		skip_suite("not the headless runner, which is the gate this suite measures")
		return
	## Guarded before anything is written: this suite **writes** a mutated account, and the
	## one thing it must never write is the owner's live file.
	var profile: Node = _profile()
	var store := "none" if profile == null else String(profile.get(&"save_path"))
	if store != SANDBOX_PROFILE:
		fail_setup(
			"the gate's store is not the sandbox (path=%s): `headless_runner.gd`" % store
			+ ":_seed_scratch_store must repoint it before any suite loads"
		)
		return
	var packed := load(GAME_SCENE) as PackedScene
	if packed == null:
		fail_setup("game.tscn did not load")
		return
	_scene = packed.instantiate() as Node2D
	if _scene == null:
		fail_setup("game.tscn did not instantiate")
		return
	_fixture_host().add_child(_scene)


func suite_teardown() -> void:
	if _scene != null and is_instance_valid(_scene):
		_scene.free()
	_scene = null


## ---------------------------------------------------------------------------
## 1. The store the gate reads is the sandbox
## ---------------------------------------------------------------------------


func test_the_store_the_gate_reads_is_the_sandbox() -> void:
	var profile: Node = _profile()
	var path := String(profile.get(&"save_path"))
	assert_eq(path, SANDBOX_PROFILE, "the store is repointed into the gate's own sandbox")
	assert_ne(path, ProfileScript.SAVE_FILE, "and never at the owner's live account")
	assert_true(
		DirAccess.dir_exists_absolute(SANDBOX_DIR),
		"the sandbox directory exists (ConfigFile.save fails err=7 without it, and the "
		+ "dropped write leaves a store that silently seeds nothing)"
	)
	assert_true(FileAccess.file_exists(SANDBOX_PROFILE), "and the seeded default is on disk")
	var seeded := ConfigFile.new()
	assert_eq(seeded.load(SANDBOX_PROFILE), OK, "the seeded file loads")
	assert_eq(
		int(seeded.get_value(ProfileScript.SECTION, "save_version", 0)),
		ProfileScript.SAVE_VERSION,
		"as the current save version"
	)
	## The second writable store. `EconomyLog.log_path` is a static that suites hand back to
	## the live default in their own `suite_teardown` (`test_engine2_dock.gd`), so the harness
	## re-applies the sandbox around every suite and every method, not once at boot.
	assert_eq(Log.log_path, SANDBOX_LOG, "the economy log is sandboxed too")
	var live_before := _size_of(LIVE_LOG)
	Log.append("gate_hygiene", &"none", 0, 0, 0)
	assert_true(FileAccess.file_exists(SANDBOX_LOG), "an append lands in the sandbox")
	assert_eq(_size_of(LIVE_LOG), live_before, "and never grows the owner's live log")


## ---------------------------------------------------------------------------
## 2. The seeded account is the deterministic default
## ---------------------------------------------------------------------------


func test_the_seeded_account_is_the_deterministic_default_the_launch_flies() -> void:
	var profile: Node = _profile()
	assert_eq(
		int(profile.call(&"credits")),
		ProfileScript.DEFAULT_CREDITS,
		"the sandbox opens on the shipped balance"
	)
	assert_eq(
		StringName(profile.call(&"active_ship")),
		ProfileScript.DEFAULT_SHIP,
		"on the shipped hull"
	)
	assert_eq(
		profile.call(&"fits"),
		{},
		"holding no fit for it, which is what makes the launch deterministic"
	)
	for family: StringName in ProfileScript.AMMO_MAX:
		assert_eq(
			int(profile.call(&"ammo_of", family)),
			ProfileScript.DEFAULT_AMMO,
			"%s's pack opens at the shipped default" % family
		)
	## The one reading every suite that touches a launched fit depends on: the launch flies
	## the hull's standard fit, not the account's. A live account carrying `w_mining` in W0 is
	## exactly what the three coupled suites failed on.
	if _scene == null:
		assert_true(false, "the suite's game scene is the launch under test")
		return
	var launched: Array[StringName] = []
	for module_id: StringName in _scene.get(&"_launch_fit").get(&"weapons", []):
		launched.append(module_id)
	var standard: Array[StringName] = []
	for module_id: StringName in ShipFitScript.standard_fit(ProfileScript.DEFAULT_SHIP).get(
		&"weapons", []
	):
		standard.append(module_id)
	assert_eq(launched, standard, "and the launch mounts the standard fit's own W cells")


## ---------------------------------------------------------------------------
## 3. A mutated store file cannot reach the in-memory profile
## ---------------------------------------------------------------------------


func test_a_mutated_store_file_cannot_reach_the_in_memory_profile() -> void:
	var profile: Node = _profile()
	var path := String(profile.get(&"save_path"))
	assert_eq(
		path,
		SANDBOX_PROFILE,
		"the mutated account goes to the gate's own sandbox, never the owner's live file"
	)
	if path != SANDBOX_PROFILE:
		return
	var mutated := _mutated_config()
	assert_eq(mutated.save(path), OK, "the mutated account is written to the store's own path")
	var readback := ConfigFile.new()
	assert_eq(readback.load(path), OK, "and it is really on disk")
	assert_eq(
		int(readback.get_value(ProfileScript.SECTION, "credits", 0)),
		MUTATED_CREDITS,
		"carrying the mutated balance"
	)
	assert_true(
		not (readback.get_value(ProfileScript.SECTION, "fits", {}) as Dictionary).is_empty(),
		"and the mutated fit, which is the reading a launch depends on"
	)
	## The boot sequence itself, not a copy of it: this is the call the runner makes before
	## any suite loads, and it is what makes the second "run" read the same counts as the
	## first. Repointing alone would leave the mutated values in memory.
	_runner().call(&"_seed_scratch_store")
	assert_eq(
		int(profile.call(&"credits")),
		ProfileScript.DEFAULT_CREDITS,
		"so the mutated balance does not survive the boot sequence"
	)
	assert_eq(profile.call(&"fits"), {}, "nor the mutated fit")
	assert_eq(
		int(profile.call(&"ammo_of", &"laser")),
		ProfileScript.DEFAULT_AMMO,
		"nor the mutated pack"
	)
	assert_eq(String(profile.get(&"save_path")), SANDBOX_PROFILE, "and the store stays sandboxed")


## ---------------------------------------------------------------------------
## Fixtures
## ---------------------------------------------------------------------------


## The harness under test, found by its own script so the suite never fails on the editor's
## runner (which does not sandbox the store and where this suite skips instead).
func _runner() -> Node:
	var scene := _tree().current_scene
	if scene != null and scene.get_script() == RunnerScript:
		return scene
	for child: Node in _tree().root.get_children():
		if child.get_script() == RunnerScript:
			return child
	return null


## One whole stored account, in the shape `PlayerProfile._write_profile` writes.
func _mutated_config() -> ConfigFile:
	var config := ConfigFile.new()
	config.set_value(ProfileScript.SECTION, "save_version", ProfileScript.SAVE_VERSION)
	config.set_value(ProfileScript.SECTION, "credits", MUTATED_CREDITS)
	config.set_value(ProfileScript.SECTION, "owned_ships", [String(ProfileScript.DEFAULT_SHIP)])
	config.set_value(ProfileScript.SECTION, "active_ship", String(ProfileScript.DEFAULT_SHIP))
	config.set_value(ProfileScript.SECTION, "cargo", {})
	config.set_value(ProfileScript.SECTION, "ammo", {"laser": MUTATED_LASER_AMMO})
	config.set_value(ProfileScript.SECTION, "modules", {})
	config.set_value(
		ProfileScript.SECTION, "fits", {String(ProfileScript.DEFAULT_SHIP): MUTATED_FIT}
	)
	return config


func _profile() -> Node:
	return _tree().root.get_node_or_null(NodePath(PROFILE_SERVICE))


## Where a fixture may enter the tree: the `PlayerProfile` autoload is already in it and takes
## children all through the run, whereas the root viewport is busy adding the runner scene
## during `_ready` (the same seam the engine2 suites use).
func _fixture_host() -> Node:
	var root := _tree().root
	var host := root.get_node_or_null(NodePath(PROFILE_SERVICE))
	return host if host != null else root


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## -1 for a file that is not there, so "unchanged" is provable without creating it.
func _size_of(path: String) -> int:
	if not FileAccess.file_exists(path):
		return -1
	var file := FileAccess.open(path, FileAccess.READ)
	return -1 if file == null else int(file.get_length())
