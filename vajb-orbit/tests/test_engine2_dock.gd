@tool
extends McpTestSuite
## Suite engine2_dock: the dock's ammo settle, engine slice 2 (fight), closing pass W9.
##
## Finding **R1** of `.agents/gen/slice2_w8_report.md` section 2: `game.gd:_file_ammo_report`
## measured every pack's fired delta against `_ammo_seed`, which the launch captures once
## (`_seed_ammo`, `game.gd:1116`) and the filing left alone afterwards, so a second report
## inside one launch re-applied the same delta - measured 300 -> 297 -> 294 for three rounds
## fired once. It is reachable from the shipped code: `_request_dock` (`game.gd:413`) has no
## re-entry guard, `_update_dock_prompt` is the flight scene's only per-frame caller, and
## `Router.route()` awaits its 0.2 s fade before the scene switch, so flight stays alive,
## docked and reading `interact` long enough to file twice. The fix re-seeds the slot from the
## live pack as each write lands (`game.gd:1107`), so a retried settle finds nothing to charge.
##
## Idempotence, not a lock: the delta is still the launch's own reading of what was fired, so
## rounds fired *between* two reports are still charged, exactly once. Both halves are asserted
## below. Everything is read off the shipped `_file_ammo_report` on a live `game.tscn` and the
## shipped `PlayerProfile` autoload; its `save_path` is repointed at a scratch file for the
## length of each test and flushed before it is handed back, so the owner's `user://profile.cfg`
## is never written - the discipline `test_engine2_fixes.gd` records for the same seam.

const Log := preload("res://game/economy_log.gd")

const GAME_SCENE := "res://game/game.tscn"
const SCRATCH_PROFILE := "user://test_engine2_dock.cfg"
const SCRATCH_LOG := "user://test_engine2_dock_log.txt"

## The pack that is fired and the pack that is not. The fired pack's slot is read off the
## launched state's own `weapons` (`PlayerState.set_weapons`, the fit-ordered sizing the
## launch writes) and never off `PlayerState.WEAPONS`' catalogue order, because a launched
## fit need not follow that order: the owner's Vanguard fit is
## `["w_cannon", "w_laser", "w_laser"]`, where the catalogue's slot 0 is the *cannon*'s pack
## (`.agents/gen/p2b_proper_r1_report.md` section 7, LOW-6).
const FIRED_WEAPON: StringName = &"laser"
const IDLE_WEAPON: StringName = &"cannon"
const FIRED_ROUNDS := 3
const LATER_ROUNDS := 5

## The fixture's own fit (CONTRACTS section 14): both packs this suite names must be
## mounted whatever the account holds - the live Vanguard fit is `["w_mining",
## "w_cannon", ""]`, which mounts no laser at all (F11) - so the store's fit for the
## active hull is replaced before `game.tscn` is instantiated and put back in
## `suite_teardown`. Both writes are flushed while the harness's own scratch `save_path`
## is still in place (`headless_runner.gd:_seed_scratch_store`), never the owner's file.
const FIXTURE_FIT: Dictionary = {
	&"engines": [&"e_std"],
	&"power": &"p_std",
	&"weapons": [&"w_laser", &"w_cannon"],
	&"shields": [&"s_light"],
	&"armour": [&"h_plate_light"],
}

var _scene: Node2D = null
var _state: Variant = null
var _previous_fits: Dictionary = {}


func suite_name() -> String:
	return "engine2_dock"


func suite_setup(_ctx: Dictionary) -> void:
	_stage_fixture_fit()
	var packed := load(GAME_SCENE) as PackedScene
	if packed == null:
		fail_setup("game.tscn did not load")
		return
	_scene = packed.instantiate() as Node2D
	if _scene == null:
		fail_setup("game.tscn did not instantiate")
		return
	_fixture_host().add_child(_scene)
	_state = _scene.get(&"_state")
	if _state == null:
		fail_setup("game.tscn did not build its state")
		return
	## The same seam W7's dock test borrows: the shipped EconomyLog must not carry a test's
	## filings home to the owner's `user://economy_log.txt`.
	Log.log_path = SCRATCH_LOG


func suite_teardown() -> void:
	if _scene != null and is_instance_valid(_scene):
		_scene.free()
	_scene = null
	_state = null
	_delete_file(SCRATCH_PROFILE)
	_delete_file(SCRATCH_LOG)
	Log.log_path = Log.DEFAULT_PATH
	_restore_fits()


## Every test hands the store back itself, so this only clears what a failed run left behind.
func teardown() -> void:
	_delete_file(SCRATCH_PROFILE)
	_delete_file(SCRATCH_LOG)


## ---------------------------------------------------------------------------
## R1. One launch, several settles (18_engine_spec section 4.3 / 01 section 6)
## ---------------------------------------------------------------------------


## The finding's own closure condition: a repeat `_file_ammo_report` in one launch must leave
## the pack at `stored - fired`, not `stored - 2 * fired`. Three calls, not two, because the
## cure is a re-seed after each write and a re-seed that only ever fires once would still pass
## a two-call probe.
func test_the_dock_report_is_idempotent_within_one_launch() -> void:
	if _scene == null or _state == null:
		assert_true(false, "the live game scene is the dock fixture")
		return
	var profile: Node = _store()
	assert_true(profile != null, "the PlayerProfile autoload is the dock's store")
	if profile == null:
		return
	var slot := _slot()
	assert_true(
		slot >= 0,
		"the fixture's own fit mounts the pack this test fires (%s of %s)"
		% [FIRED_WEAPON, _state.get(&"weapons")]
	)
	if slot < 0:
		return
	var previous_path: String = _repoint(profile)
	var stored_before: int = int(profile.call(&"ammo_of", FIRED_WEAPON))
	var idle_before: int = int(profile.call(&"ammo_of", IDLE_WEAPON))
	_scene.call(&"_seed_ammo")
	var live: int = int((_state.get(&"ammo") as Array)[slot])
	var ceiling: int = int((_state.get(&"ammo_max") as Array)[slot])
	assert_true(
		live >= FIRED_ROUNDS,
		"the fixture loaded at least %d rounds to fire (live=%d)" % [FIRED_ROUNDS, live]
	)
	_state.set_ammo(slot, live - FIRED_ROUNDS)
	_scene.call(&"_file_ammo_report")
	var filed_once: int = int(profile.call(&"ammo_of", FIRED_WEAPON))
	_scene.call(&"_file_ammo_report")
	var filed_twice: int = int(profile.call(&"ammo_of", FIRED_WEAPON))
	_scene.call(&"_file_ammo_report")
	var filed_thrice: int = int(profile.call(&"ammo_of", FIRED_WEAPON))
	var idle_after: int = int(profile.call(&"ammo_of", IDLE_WEAPON))
	_hand_back(profile, previous_path, FIRED_WEAPON, stored_before)
	assert_eq(
		live,
		mini(stored_before, ceiling),
		"the launch seeded the live pack from the store (%d of %d)" % [stored_before, ceiling]
	)
	assert_eq(
		filed_once,
		maxi(stored_before - FIRED_ROUNDS, 0),
		"the first report charges exactly the rounds that were fired (%d -> %d)"
		% [stored_before, filed_once]
	)
	assert_eq(
		filed_twice,
		filed_once,
		"a second report in the same launch charges nothing more (%d -> %d)"
		% [filed_once, filed_twice]
	)
	assert_eq(
		filed_thrice,
		filed_once,
		"and a third is inert too (%d -> %d)" % [filed_twice, filed_thrice]
	)
	assert_eq(idle_after, idle_before, "the pack that was not fired never moved")


## The cure must not swallow later firing: the settle of an interrupted dock is retried with a
## fresh seed, not with a frozen one, so rounds fired since the last report are still charged -
## once. Three rounds, settle, two more, settle again: the store pays five.
func test_a_settle_charges_the_rounds_fired_since_the_last_one() -> void:
	if _scene == null or _state == null:
		assert_true(false, "the live game scene is the dock fixture")
		return
	var profile: Node = _store()
	assert_true(profile != null, "the PlayerProfile autoload is the dock's store")
	if profile == null:
		return
	var slot := _slot()
	assert_true(
		slot >= 0,
		"the fixture's own fit mounts the pack this test fires (%s of %s)"
		% [FIRED_WEAPON, _state.get(&"weapons")]
	)
	if slot < 0:
		return
	var previous_path: String = _repoint(profile)
	var stored_before: int = int(profile.call(&"ammo_of", FIRED_WEAPON))
	_scene.call(&"_seed_ammo")
	var live: int = int((_state.get(&"ammo") as Array)[slot])
	assert_true(
		live >= LATER_ROUNDS,
		"the fixture loaded at least %d rounds to fire (live=%d)" % [LATER_ROUNDS, live]
	)
	_state.set_ammo(slot, live - FIRED_ROUNDS)
	_scene.call(&"_file_ammo_report")
	var after_first: int = int(profile.call(&"ammo_of", FIRED_WEAPON))
	_state.set_ammo(slot, live - LATER_ROUNDS)
	_scene.call(&"_file_ammo_report")
	var after_second: int = int(profile.call(&"ammo_of", FIRED_WEAPON))
	_hand_back(profile, previous_path, FIRED_WEAPON, stored_before)
	assert_eq(
		after_first,
		maxi(stored_before - FIRED_ROUNDS, 0),
		"the first settle charges its three (%d -> %d)" % [stored_before, after_first]
	)
	assert_eq(
		after_second,
		maxi(stored_before - LATER_ROUNDS, 0),
		"the second charges the two that followed, not the three again (%d -> %d)"
		% [after_first, after_second]
	)


## ---------------------------------------------------------------------------
## Fixtures (the same shapes `test_engine2_fixes.gd` uses for this seam)
## ---------------------------------------------------------------------------


## Where a fixture may enter the tree. The runner calls every test from inside its own
## `_ready`, when the root viewport is still busy adding the runner scene, so
## `root.add_child(...)` fails there; the profile autoload took children all through the run.
func _fixture_host() -> Node:
	var root := _tree().root
	var host := root.get_node_or_null(NodePath(&"PlayerProfile"))
	return host if host != null else root


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## The dock's store, at the only path that resolves an autoload (`game.gd:_profile`).
func _store() -> Node:
	return _tree().root.get_node_or_null(NodePath(&"PlayerProfile"))


## The fired pack's slot as this launch sized it: the index of the fired family in the live
## `PlayerState.weapons` array, so the test charges the pack it names whatever order the fit
## holds its W cells in (LOW-6). It answers -1 when the launch mounts no such pack, and
## GDScript's negative indexing would then silently read the **last** pack rather than
## failing, so every caller guards the value before it indexes `ammo` (F11).
func _slot() -> int:
	return int((_state.get(&"weapons") as Array).find(FIRED_WEAPON))


## The suite's own fit, written before the scene is instantiated: `set_fit` is the store's
## plain per-hull setter (no inventory or power-budget legality - that is `fit_legal`'s and
## the fitting panel's), and the stored value is captured first so the account ends this
## suite exactly as it started.
func _stage_fixture_fit() -> void:
	var profile: Node = _store()
	if profile == null:
		return
	_previous_fits = profile.call(&"fits")
	profile.call(&"set_fit", StringName(profile.call(&"active_ship")), FIXTURE_FIT)
	profile.call(&"flush")


func _restore_fits() -> void:
	var profile: Node = _store()
	if profile == null:
		return
	profile.call(&"set_fits", _previous_fits)
	profile.call(&"flush")
	_previous_fits = {}


## The scratch handover, in the order the finding's own measurements use: repoint the writer
## before anything can write, then clear the two files. Returns the path to hand back.
func _repoint(profile: Node) -> String:
	var previous: String = profile.get(&"save_path")
	profile.set(&"save_path", SCRATCH_PROFILE)
	Log.log_path = SCRATCH_LOG
	_delete_file(SCRATCH_PROFILE)
	_delete_file(SCRATCH_LOG)
	return previous


## The store is restored in memory and flushed while the scratch path is still in place, so no
## dirty flag and no running timer carry a test's filings into the owner's profile.
func _hand_back(profile: Node, previous_path: String, weapon: StringName, rounds: int) -> void:
	profile.call(&"set_ammo", weapon, rounds)
	profile.call(&"flush")
	profile.set(&"save_path", previous_path)
	Log.log_path = Log.DEFAULT_PATH
	_delete_file(SCRATCH_PROFILE)
	_delete_file(SCRATCH_LOG)


func _delete_file(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())
