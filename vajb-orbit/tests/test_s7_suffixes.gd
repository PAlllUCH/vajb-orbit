@tool
extends McpTestSuite
## Suite s7_suffixes: the suffix side of the affix application (CONTRACTS section 20;
## 15 section 4) - the three seams this worker owns, plus the staged rows' no-op proof.
##
## Leeches and Cartograph are exercised through the **live** launch (`game.tscn`, opened
## the way `test_s6_heat.gd` opens it, with the autoload profile repointed at a scratch
## store): a suffixed instance is fitted on the active hull, so the flag reaches
## `game.gd:_launch_summary` by the shipped path (`PlayerProfile.affix_summary` ->
## `Affixes.summary` -> `game.gd:_affix_summary_for`) and the perk is paid by a real
## `_on_npc_died` call / a real sector entry. The Leeches gate is the handler's own
## **credited path** (K0's F6 measured that killer identity is not knowable - `NpcShip._die`
## emits position and archetype only - so the pin's fallback applies: every death that
## reaches the handler is credited and heals): this suite asserts the credit the same call
## files beside the heal, and that a launch with no flag leaves the hull alone.
##
## Ledger and the staged rows are arithmetic over a summary, so they run on a throwaway
## profile (`test_s7_affixes.gd`'s harness) and the live store is never a target.
##
## Contract: docs/CONTRACTS.md section 20 (the pin, incl. the K0/K1/K2 dispositions),
## docs/gameplay/15_module_affixes.md sections 1/3/4/6/10, 09_ship_slots_modules.md
## section 5, 11_galactic_map.md section 3.3 (Cartograph's reveal), 13_heat_bounty.md
## section 3 (Silence has no detection-time mechanic to hook).

const GameScript := preload("res://game/game.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const Profile := preload("res://autoload/player_profile.gd")
const ModuleData := preload("res://game/module_catalog.gd")
const FitData := preload("res://game/ship_fit.gd")
const AffixesScript := preload("res://game/affixes.gd")
const AuctionScript := preload("res://game/auction.gd")
const NpcRegistryScript := preload("res://game/npc_registry.gd")
const PoiScript := preload("res://game/poi.gd")
const Log := preload("res://game/economy_log.gd")

const GAME_SCENE := "res://game/game.tscn"
const PROFILE_PATH := "user://test_s7_suffixes.cfg"
const SCRATCH_PROFILE := "user://test_s7_suffixes_live.cfg"
const SCRATCH_LOG := "user://test_s7_suffixes_log.txt"

## 09 section 3's laser: the 900-cost Common the Ledger worked row is written on, and
## the module the two live fits carry (the Vanguard's standard fit has one W cell).
const LASER: StringName = &"w_laser"
## A kill point in dead space, past every witness radius (`test_s6_heat.gd`'s own
## constant): the swarmer kill below is no crime, so no witness is involved either way.
const KILL_POINT := Vector2(4800.0, -4800.0)
## 13 section 2's no-crime row: a swarmer kill files heat 0 and standing 0, so the
## credited path this suite measures is the handler's own, without the witness rung.
const SWARMER: StringName = &"swarmer"

## The five suffixes CONTRACTS section 20 stages (Silence, Vault and the three faction
## rows): no consumer reads their ids, so a summary carrying them must resolve and price
## exactly as an empty one does.
const STAGED_SUFFIXES: Array[StringName] = [
	&"silence",
	&"vault",
	&"choir",
	&"concord",
	&"ports",
]


## A victim stand-in for the kill seam: exactly the three answers `game.gd:_on_npc_died`
## reads off a real `NpcShip`, all of them read off the registry row the archetype names.
class StubHull extends Node2D:
	var archetype_id: StringName = &"swarmer"

	func row() -> Dictionary:
		return NpcRegistryScript.archetype(archetype_id)

	func heat_on_kill() -> int:
		return int(row().get(NpcRegistryScript.KEY_HEAT_ON_KILL, 0))

	func standing_on_kill() -> int:
		return int(row().get(NpcRegistryScript.KEY_STANDING_ON_KILL, 0))


var _scenes: Array[Node2D] = []
var _bare: Array[Node] = []
var _profiles: Array[Node] = []
var _previous_path := ""


func suite_name() -> String:
	return "s7_suffixes"


func suite_setup(_ctx: Dictionary) -> void:
	_stage_scratch_store()
	GameScript._transit_destination = &""


func setup() -> void:
	GameScript._transit_destination = &""
	_reset_store()


func teardown() -> void:
	GameScript._transit_destination = &""
	_free_scenes()
	_free_bare()
	_free_profiles()


func suite_teardown() -> void:
	GameScript._transit_destination = &""
	_free_scenes()
	_free_bare()
	_free_profiles()
	var profile := _store()
	if profile != null:
		profile.call(&"reset_to_defaults")
		profile.call(&"flush")
		profile.set(&"save_path", _previous_path)
	Log.log_path = Log.DEFAULT_PATH
	_delete_file(PROFILE_PATH)
	_delete_file(SCRATCH_PROFILE)
	_delete_file(SCRATCH_LOG)


## ---------------------------------------------------------------------------
## Leeches: 15 section 4's kill heal through the credited path (AC6)
## ---------------------------------------------------------------------------


## A launch whose fitted instances carry `of Leeches` heals 5 % of the hull's own
## maximum on a death that reaches `_on_npc_died`, and the same call files the kill's
## credit (the `KILL` economy-log line). The percentage, the pool and the flag are all
## read off their owners, so a band or a hull change moves the expectation with it.
func test_leeches_heals_five_percent_of_the_hull_maximum_on_a_credited_kill() -> void:
	var profile := _store()
	if profile == null:
		return
	var ship: StringName = profile.active_ship()
	var id: StringName = profile.add_instance(LASER, ModuleData.RARITY_COMMON, [], [&"leeches"])
	assert_true(
		bool(profile.call(&"fit_module_at", ship, &"weapons", 0, id)),
		"a Leeches instance fits the launch"
	)
	assert_true(
		AffixesScript.has_suffix(profile.call(&"affix_summary", ship), &"leeches"),
		"and the launch's own summary carries the flag"
	)
	var scene := _open_game()
	if scene == null:
		return
	var state := scene.get(&"_state") as PlayerStateScript
	assert_true(state != null, "the launch seeded a live state")
	if state == null:
		return
	state.set_hull(state.hull_max - 200.0)
	var before := state.hull
	var expected := minf(before + GameScript.LEECHES_FRACTION * state.hull_max, state.hull_max)
	assert_true(before < state.hull_max, "the hull is damaged before the kill")

	var kills_before := _lines_with(GameScript.EVENT_KILL).size()
	scene.call(&"_on_npc_died", KILL_POINT, SWARMER, _victim(SWARMER))
	assert_eq(
		_lines_with(GameScript.EVENT_KILL).size(),
		kills_before + 1,
		"the handler credited the kill (the path the heal is gated on)"
	)
	assert_close(state.hull, expected, "and paid 5 % of hull_max back in the same breath")


## The control: a launch with no Leeches instance heals nothing, and the hull's own
## `hull_changed` reader sees no move.
func test_a_launch_without_leeches_leaves_the_hull_alone() -> void:
	var scene := _open_game()
	if scene == null:
		return
	var state := scene.get(&"_state") as PlayerStateScript
	assert_true(state != null, "the launch seeded a live state")
	if state == null:
		return
	assert_false(
		AffixesScript.has_suffix(scene.get(&"_launch_summary"), &"leeches"),
		"nothing fitted, no Leeches flag"
	)
	state.set_hull(state.hull_max - 200.0)
	var before := state.hull
	scene.call(&"_on_npc_died", KILL_POINT, SWARMER, _victim(SWARMER))
	assert_eq(state.hull, before, "the kill pays nothing back without the perk")


## ---------------------------------------------------------------------------
## Cartograph: 15 section 4 / 11 section 3.3's sector reveal at entry (AC6)
## ---------------------------------------------------------------------------


## A launch carrying `of the Cartograph` enters a sector with every POI revealed, through
## the shipped beacon seam - one call at entry, no second fog rule. 11 section 3's
## densities guarantee a derelict and an anomaly per sector, and both kinds start fogged,
## so the reading is not vacuous.
func test_cartograph_reveals_the_sectors_pois_at_entry() -> void:
	var profile := _store()
	if profile == null:
		return
	var ship: StringName = profile.active_ship()
	var id: StringName = profile.add_instance(
		LASER, ModuleData.RARITY_COMMON, [], [GameScript.FLAG_CARTOGRAPH]
	)
	assert_true(
		bool(profile.call(&"fit_module_at", ship, &"weapons", 0, id)),
		"a Cartograph instance fits the launch"
	)
	assert_true(
		AffixesScript.has_suffix(profile.call(&"affix_summary", ship), GameScript.FLAG_CARTOGRAPH),
		"and the launch's own summary carries the flag"
	)
	var scene := _open_game()
	if scene == null:
		return
	var sector: Node = scene.get(&"_sector")
	assert_true(sector != null, "the entry spawned a sector")
	if sector == null:
		return
	assert_true(_guaranteed_fog_kinds(sector), "the sector spawned the derelict and anomaly the densities promise")
	assert_eq(
		_fogged_pois(sector).size(), 0, "and Cartograph lifted the fog off every POI at entry"
	)
	for poi: Node2D in _guaranteed_pois(sector):
		assert_true(bool(poi.call(&"is_revealed")), "including the %s" % String(poi.get(&"kind")))


## The fogged control: the same entry with no Cartograph fitted leaves every derelict and
## anomaly fogged, which is what `Sector.blips` (11 section 3.3's soft fog) reads.
func test_without_cartograph_the_sector_enters_fogged() -> void:
	var scene := _open_game()
	if scene == null:
		return
	var sector: Node = scene.get(&"_sector")
	assert_true(sector != null, "the entry spawned a sector")
	if sector == null:
		return
	assert_false(
		AffixesScript.has_suffix(scene.get(&"_launch_summary"), GameScript.FLAG_CARTOGRAPH),
		"nothing fitted, no Cartograph flag"
	)
	assert_true(_guaranteed_fog_kinds(sector), "the sector spawned the derelict and anomaly the densities promise")
	for poi: Node2D in _guaranteed_pois(sector):
		assert_false(bool(poi.call(&"is_revealed")), "the %s stays fogged" % String(poi.get(&"kind")))
	assert_true(_fogged_pois(sector).size() > 0, "so the sector has fog to lift")


## ---------------------------------------------------------------------------
## Ledger: 15 section 4's +25 % at every production sell site (AC6)
## ---------------------------------------------------------------------------


## The worked row: a 900-cost Common sells for 540, and the same instance carrying
## `of the Ledger` for 675. All three production sites - the pane's displayed row
## (`Auction._sell_row` through `sell_rows`), the transaction's quote (`Auction.sell_row`)
## and the payout (`PlayerProfile.sell_instance`) - read the record's own suffix list
## through the one price function, so they cannot disagree.
func test_ledger_pays_one_and_a_quarter_at_every_sell_site() -> void:
	var profile: Node = _fresh()
	var plain: StringName = profile.add_instance(LASER, ModuleData.RARITY_COMMON, [], [])
	var ledger: StringName = profile.add_instance(LASER, ModuleData.RARITY_COMMON, [], [&"ledger"])
	var cost := int(ModuleData.module(LASER)[&"cost"])
	var plain_price := ModuleData.sell_price(LASER, ModuleData.RARITY_COMMON)
	var ledger_price := plain_price * AuctionScript.LEDGER_PERCENT / 100
	assert_eq(cost, 900, "the worked row is 09 section 3's 900-cost laser")
	assert_eq(plain_price, 540, "whose Common sell share is 900 x 60 %")
	assert_eq(ledger_price, 675, "and 540 x 1.25 is 675, an exact integer")

	## The pane's displayed price (Auction._sell_row, the row the SELL plate carries).
	var rows: Array[Dictionary] = AuctionScript.sell_rows(profile)
	assert_eq(_row_price(rows, ledger), ledger_price, "the displayed row shows the Ledger price")
	assert_eq(_row_price(rows, plain), plain_price, "and an un-suffixed row its own")

	## The transaction's quote and the payout are the same figure.
	var before: int = profile.credits()
	var quote: Dictionary = AuctionScript.sell_row(profile, ledger)
	assert_true(bool(quote[&"ok"]), "the Ledger instance sells")
	assert_eq(int(quote[&"cost"]), ledger_price, "the quote is the Ledger price")
	assert_eq(int(quote[&"price"]), ledger_price, "and the paid figure matches it")
	assert_eq(profile.credits(), before + ledger_price, "the quote paid the Ledger price")

	## The third production site, called directly: PlayerProfile.sell_instance.
	var direct: StringName = profile.add_instance(LASER, ModuleData.RARITY_COMMON, [], [&"ledger"])
	var payout_before: int = profile.credits()
	assert_true(profile.sell_instance(direct), "a Ledger instance sells directly")
	assert_eq(profile.credits(), payout_before + ledger_price, "and the payout is the Ledger price")

	## An un-suffixed instance still pays the plain share through the same call.
	var control: StringName = profile.add_instance(LASER, ModuleData.RARITY_COMMON, [], [])
	var control_before: int = profile.credits()
	assert_true(profile.sell_instance(control), "an un-suffixed instance sells too")
	assert_eq(profile.credits(), control_before + plain_price, "at the plain share")


## The one price function's own readings: a hand-built `{id, value}` suffix row (the
## shape a fixture may use) reads like the stored bare id, a suffix that is not the
## Ledger changes nothing, and the shipped two-argument call is the pre-S7 number.
func test_the_ledger_term_reads_both_suffix_spellings_and_nothing_else() -> void:
	assert_eq(
		AuctionScript.sell_price(LASER, ModuleData.RARITY_RARE, [&"ledger"]),
		AuctionScript.sell_price(LASER, ModuleData.RARITY_RARE, [{&"id": &"ledger", &"value": 0.0}]),
		"the stored bare id and a hand-built row read the same"
	)
	assert_eq(
		AuctionScript.sell_price(LASER, ModuleData.RARITY_COMMON),
		ModuleData.sell_price(LASER, ModuleData.RARITY_COMMON),
		"no suffix argument is the shipped pre-S7 call"
	)
	assert_eq(
		AuctionScript.sell_price(LASER, ModuleData.RARITY_COMMON, []),
		ModuleData.sell_price(LASER, ModuleData.RARITY_COMMON),
		"and so is an empty list"
	)
	for other: StringName in [&"whale", &"embers", &"leeches", &"cartograph", &"silence", &"vault"]:
		assert_eq(
			AuctionScript.sell_price(LASER, ModuleData.RARITY_COMMON, [other]),
			ModuleData.sell_price(LASER, ModuleData.RARITY_COMMON),
			"%s is not the Ledger" % String(other)
		)


## ---------------------------------------------------------------------------
## The staged rows: byte-identical no-ops (AC7)
## ---------------------------------------------------------------------------


## Silence, Vault and the three faction suffixes apply nothing: a fitted instance
## carrying all five resolves to the same `ShipStats` as the same fit with an empty
## summary, and the price function ignores them. Overflowing (a prefix) stages on K1's
## side; this is the suffix half of 15 section 9.3's staged set.
func test_the_staged_suffixes_are_byte_identical_no_ops() -> void:
	var profile: Node = _fresh()
	for id: StringName in STAGED_SUFFIXES:
		assert_true(ModuleData.SUFFIXES.has(id), "%s is a shipped 15 section 4 row" % String(id))
	var ship: StringName = profile.active_ship()
	var instance: StringName = profile.add_instance(LASER, ModuleData.RARITY_RARE, [], STAGED_SUFFIXES)
	assert_true(
		bool(profile.call(&"fit_module_at", ship, &"weapons", 0, instance)),
		"one instance carries all five staged suffixes"
	)
	var summary: Dictionary = profile.call(&"affix_summary", ship)
	for id: StringName in STAGED_SUFFIXES:
		assert_true(AffixesScript.has_suffix(summary, id), "the summary carries %s" % String(id))

	var fit: Dictionary = profile.call(&"base_fit", profile.call(&"resolved_fit", ship))
	var with_staged: ShipStats = FitData.resolve(ship, fit, summary)
	var without: ShipStats = FitData.resolve(ship, fit, {})
	assert_true(
		_deep_eq(_snapshot(with_staged), _snapshot(without)),
		"resolve is byte-identical with the staged five fitted: %s" % [_snapshot(with_staged)]
	)
	assert_eq(
		AuctionScript.sell_price(LASER, ModuleData.RARITY_RARE, STAGED_SUFFIXES),
		ModuleData.sell_price(LASER, ModuleData.RARITY_RARE),
		"and the staged rows add no sell term"
	)


## ---------------------------------------------------------------------------
## Helpers
## ---------------------------------------------------------------------------


func _fresh():
	var profile := Profile.new()
	profile.save_path = PROFILE_PATH
	_profiles.append(profile)
	return profile


## A victim stand-in, parented to the fixture host so it has a tree while the handler
## runs and is freed by `_free_bare`.
func _victim(archetype: StringName) -> Node2D:
	var hull := StubHull.new()
	hull.name = "Stub%s" % String(archetype).capitalize()
	hull.archetype_id = archetype
	_fixture_host().add_child(hull)
	_bare.append(hull)
	return hull


func _open_game() -> Node2D:
	var packed := load(GAME_SCENE) as PackedScene
	if packed == null:
		return null
	var scene := packed.instantiate() as Node2D
	if scene == null:
		return null
	_fixture_host().add_child(scene)
	_scenes.append(scene)
	return scene


## The sector's still-fogged POIs, the reading `Sector.blips` applies (11 section 3.3).
func _fogged_pois(sector: Node) -> Array[Node2D]:
	var out: Array[Node2D] = []
	for poi: Node2D in sector.call(&"pois"):
		if not bool(poi.call(&"is_revealed")):
			out.append(poi)
	return out


## The derelicts and anomalies a sector always spawns (11 section 3's densities:
## `anomalies_min` 1 and one derelict per wreck field, at least one field) - the two
## kinds that start fogged by their own `_setup`.
func _guaranteed_pois(sector: Node) -> Array:
	var out: Array = []
	out.append_array(sector.call(&"derelicts"))
	out.append_array(sector.call(&"anomalies"))
	return out


func _guaranteed_fog_kinds(sector: Node) -> bool:
	return (
		not (sector.call(&"derelicts") as Array).is_empty()
		and not (sector.call(&"anomalies") as Array).is_empty()
	)


## One sell row's own price, `0` for an id the rows do not carry.
func _row_price(rows: Array[Dictionary], id: StringName) -> int:
	for row: Dictionary in rows:
		if StringName(row.get(&"id", &"")) == id:
			return int(row.get(&"price", 0))
	return 0


func _lines_with(event: String) -> Array[String]:
	var out: Array[String] = []
	if not FileAccess.file_exists(SCRATCH_LOG):
		return out
	var file := FileAccess.open(SCRATCH_LOG, FileAccess.READ)
	if file == null:
		return out
	var text := file.get_as_text()
	file.close()
	for line: String in text.split("\n", false):
		if line.contains(", %s," % event):
			out.append(line)
	return out


func _fixture_host() -> Node:
	var root := _tree().root
	var host := root.get_node_or_null(NodePath(&"PlayerProfile"))
	return host if host != null else root


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _store() -> Node:
	return _tree().root.get_node_or_null(NodePath(&"PlayerProfile"))


func _free_scenes() -> void:
	for scene: Node2D in _scenes:
		if is_instance_valid(scene):
			scene.free()
	_scenes.clear()


func _free_bare() -> void:
	for node: Node in _bare:
		if is_instance_valid(node):
			node.free()
	_bare.clear()


func _free_profiles() -> void:
	for profile: Node in _profiles:
		if is_instance_valid(profile):
			profile.free()
	_profiles.clear()


func _reset_store() -> void:
	var profile := _store()
	if profile == null:
		return
	profile.call(&"reset_to_defaults")
	profile.call(&"flush")


func _stage_scratch_store() -> void:
	var profile := _store()
	if profile == null:
		return
	_previous_path = String(profile.get(&"save_path"))
	profile.set(&"save_path", SCRATCH_PROFILE)
	profile.call(&"reset_to_defaults")
	profile.call(&"flush")
	Log.log_path = SCRATCH_LOG


func _delete_file(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


## Every field of one resolved snapshot, so an A/B comparison cannot miss one
## (`test_s7_affixes.gd`'s own reading).
func _snapshot(stats: ShipStats) -> Dictionary:
	return {
		"max_speed": stats.max_speed,
		"accel_time": stats.accel_time,
		"coast_time": stats.coast_time,
		"turn_rate": stats.turn_rate,
		"turn_spinup": stats.turn_spinup,
		"hull_mass": stats.hull_mass,
		"hull_max": stats.hull_max,
		"shield_max": stats.shield_max,
		"shield_regen": stats.shield_regen,
		"damage_mult": stats.damage_mult,
		"lock_range": stats.lock_range,
		"scan_range": stats.scan_range,
		"tractor_range": stats.tractor_range,
		"tractor_speed": stats.tractor_speed,
		"tractor_streams": stats.tractor_streams,
		"cargo_max": stats.cargo_max,
		"energy_max": stats.energy_max,
		"energy_regen": stats.energy_regen,
		"fuel_max": stats.fuel_max,
		"boosters": stats.boosters,
		"booster_cooldown_mult": stats.booster_cooldown_mult,
	}


## Structural equality with a float tolerance: `==` on nested dictionaries and typed
## arrays is not dependable.
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


func assert_close(actual: float, expected: float, msg: String) -> void:
	assert_true(
		is_equal_approx(actual, expected), "%s (got %.6f, want %.6f)" % [msg, actual, expected]
	)
