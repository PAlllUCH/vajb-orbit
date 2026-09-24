@tool
extends McpTestSuite
## Suite s6_heat: wave S6's heat enforcement and hunters (AC5/AC6) - 13 §5/§7's witness
## rule, 13 §7's decay accumulator, 13 §2's fine math and `PlayerProfile.pay_bounty`, the
## two refusal axes (dock ← standing 12 §4.1, gate ← heat tier 13 §3), 13 §3's per-faction
## hunter wings and the LAUNCH pane's bounty row (13 §7 / 14 §7).
##
## Contract: docs/CONTRACTS.md §19 (the pin, incl. the K0 dispositions block),
## docs/gameplay/13_heat_bounty.md §2-§5/§7, docs/gameplay/12_factions.md §4.1,
## docs/gameplay/17_coder_handoff.md §4/§5. Every number the suite compares against is
## read off its owner (`NpcRegistry`'s rows, `ShipFit.BASE_SCAN_RANGE`, `game.gd`'s own
## constants) rather than restated here, so a drift in either direction is a red assertion.
##
## The live tests instantiate `game.tscn` the way `test_s6_travel.gd` and
## `test_s6_poi_loot.gd` do (the profile autoload as the fixture host) and repoint
## `PlayerProfile.save_path` at a scratch file for the length of the suite, so the owner's
## `user://profile.cfg` is never written. No test awaits: the headless runner calls each
## `test_*` method and drops its return value, so an `await` would silently skip the rest
## of the body.

const GameScript := preload("res://game/game.gd")
const NpcRegistryScript := preload("res://game/npc_registry.gd")
const NpcShipScript := preload("res://game/npc_ship.gd")
const SectorRegistryScript := preload("res://game/sector_registry.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const LootTablesScript := preload("res://game/loot_tables.gd")
const Catalog := preload("res://game/station_catalog.gd")
const Log := preload("res://game/economy_log.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const LaunchScene := preload("res://ui/station/launch_panel.tscn")

const GAME_SCENE := "res://game/game.tscn"
const SCRATCH_PROFILE := "user://test_s6_heat.cfg"
const SCRATCH_LOG := "user://test_s6_heat_log.txt"

## A kill point in dead space: past every witness radius from the sector's station and its
## convoy/patrol anchors (which sit on the station), so 13 §5's "solo kills in dead space
## are free" is measurable rather than asserted.
const DEAD_SPACE := Vector2(4800.0, -4800.0)
## 13 §2's own fine row, as numbers: 40 heat costs 1 000 CR.
const FINE_HEAT := 40
const FINE_CREDITS := 1000
## How many kills each half of the hunter-extra measurement makes. 06 §8's extra pays the
## shared item half the time and pays a 2 half of that, so 60 kills miss the tell with
## probability ~3e-8.
const LOOT_KILLS := 60


## A victim stand-in for the kill seam: exactly the three answers `game.gd:_on_npc_died`
## reads off a real `NpcShip`, and every one of them read off the **registry row** the
## archetype names - so this suite never restates 13 §2's -3/+15/+25 or 06 §3's loot kind.
class StubHull extends Node2D:
	var archetype_id: StringName = &"trader"

	func row() -> Dictionary:
		return NpcRegistryScript.archetype(archetype_id)

	func heat_on_kill() -> int:
		return int(row().get(NpcRegistryScript.KEY_HEAT_ON_KILL, 0))

	func standing_on_kill() -> int:
		return int(row().get(NpcRegistryScript.KEY_STANDING_ON_KILL, 0))


## A witness stand-in: a hull in the `npc_ship` group with the one behaviour class the
## witness rule reads (`blip_kind`, or `hostility` for a row that has no blip of its own).
## `blind` makes it answer its own line-of-sight check - 13 §7's "LOS is the NPC brain's own
## rock-blocking check" - so a blocked line is measurable without a physics body.
class StubWitness extends Node2D:
	var blip: StringName = &"neutral"
	var hostility_id: StringName = &""
	var blind := false

	func blip_kind() -> StringName:
		return blip

	func hostility() -> StringName:
		return hostility_id

	func _line_of_sight(_from: Vector2, _to: Vector2) -> bool:
		return not blind


var _scenes: Array[Node2D] = []
var _bare: Array[Node] = []
var _host: Control = null
var _panel: Control = null
var _status: Array[String] = []
var _previous_path := ""


func suite_name() -> String:
	return "s6_heat"


func suite_setup(_ctx: Dictionary) -> void:
	_stage_scratch_store()
	GameScript._transit_destination = &""


func setup() -> void:
	GameScript._transit_destination = &""
	_status.clear()


func teardown() -> void:
	GameScript._transit_destination = &""
	if _host != null and is_instance_valid(_host):
		_host.free()
	_host = null
	_panel = null
	_free_scenes()
	_free_bare()


func suite_teardown() -> void:
	_free_scenes()
	_free_bare()
	GameScript._transit_destination = &""
	var profile := _store()
	if profile != null:
		profile.call(&"reset_to_defaults")
		profile.call(&"flush")
		profile.set(&"save_path", _previous_path)
	Log.log_path = Log.DEFAULT_PATH
	_delete_file(SCRATCH_PROFILE)
	_delete_file(SCRATCH_LOG)


## ---------------------------------------------------------------------------
## 13 §5/§7's witness rule
## ---------------------------------------------------------------------------


## "Solo kills in dead space are free": a crime with no witness inside `WITNESS_RANGE`
## adds nothing at all, and the profile is byte-identical after it. The witness range is
## 13 §7's derived constant (`ShipFitScript.BASE_SCAN_RANGE`), asserted rather than assumed.
func test_a_crime_without_a_witness_writes_nothing() -> void:
	assert_eq(
		GameScript.WITNESS_RANGE,
		ShipFitScript.BASE_SCAN_RANGE,
		"13 §7 derives the witness range from the tree's only scan range"
	)
	var scene := _open_game()
	var profile := _store()
	assert_true(scene != null and profile != null, "game.tscn and the profile autoload exist")
	if scene == null or profile == null:
		return
	profile.call(&"set_heat", {})
	assert_false(
		bool(scene.call(&"_witnessed", DEAD_SPACE)),
		"dead space is outside every witness radius (station and hull anchors)"
	)
	var before := _profile_snapshot(profile)
	scene.call(&"_on_npc_died", DEAD_SPACE, &"trader", _victim(&"trader"))
	assert_eq(
		_profile_snapshot(profile), before, "an unwitnessed crime leaves the profile untouched"
	)
	assert_eq(profile.call(&"heat"), {}, "and files no heat key at all")


## A neutral hull (the convoy's own blip class) inside the range scores the crime **plus**
## 13 §2's witness surcharge, and the value is the victim's own row plus that surcharge.
func test_a_neutral_witness_scores_the_crime_plus_the_witness_extra() -> void:
	var scene := _open_game()
	var profile := _store()
	if scene == null or profile == null:
		return
	profile.call(&"set_heat", {})
	_witness(DEAD_SPACE + Vector2(200.0, 0.0), &"neutral")
	assert_true(
		bool(scene.call(&"_witnessed", DEAD_SPACE)), "a neutral hull 200 u away is a witness"
	)
	scene.call(&"_on_npc_died", DEAD_SPACE, &"trader", _victim(&"trader"))
	assert_eq(
		_heat_of(profile, &"concord"),
		_row_value(&"trader", NpcRegistryScript.KEY_HEAT_ON_KILL) + GameScript.WITNESS_EXTRA,
		"the trader's +15 plus 13 §2's +5 witness extra"
	)


## 13 §5's "or patrol": the law's own hull witnesses too, and the victim's row still sets
## the value (a patrol kill is +25 + the surcharge).
func test_a_patrol_witness_scores_the_crime_too() -> void:
	var scene := _open_game()
	var profile := _store()
	if scene == null or profile == null:
		return
	profile.call(&"set_heat", {})
	_witness(DEAD_SPACE + Vector2(0.0, 300.0), &"hostile", &"faction_rules")
	assert_true(bool(scene.call(&"_witnessed", DEAD_SPACE)), "a patrol hull is a witness")
	scene.call(&"_on_npc_died", DEAD_SPACE, &"patrol", _victim(&"patrol"))
	assert_eq(
		_heat_of(profile, &"concord"),
		_row_value(&"patrol", NpcRegistryScript.KEY_HEAT_ON_KILL) + GameScript.WITNESS_EXTRA,
		"the patrol's own +25 plus the witness extra"
	)


## 13 §7's LOS half: a witness whose own line-of-sight check says "blocked" witnesses
## nothing, and a hull past `WITNESS_RANGE` is not a witness however clear the line.
func test_a_blocked_line_or_a_witness_past_the_range_is_no_witness() -> void:
	var scene := _open_game()
	var profile := _store()
	if scene == null or profile == null:
		return
	profile.call(&"set_heat", {})
	var blind := _witness(DEAD_SPACE + Vector2(200.0, 0.0), &"neutral")
	blind.blind = true
	assert_false(bool(scene.call(&"_witnessed", DEAD_SPACE)), "a rock on the line is no witness")
	blind.free()
	_witness(DEAD_SPACE + Vector2(GameScript.WITNESS_RANGE + 100.0, 0.0), &"neutral")
	assert_false(
		bool(scene.call(&"_witnessed", DEAD_SPACE)),
		"past %d u the witness is out of range" % int(GameScript.WITNESS_RANGE)
	)
	scene.call(&"_on_npc_died", DEAD_SPACE, &"trader", _victim(&"trader"))
	assert_eq(_heat_of(profile, &"concord"), 0, "so the crime files nothing")


## 13 §7's LOS half is "the NPC brain's own rock-blocking check": the scene asks a **hull**
## witness for its own verdict (`NpcShip._line_of_sight`, the rock-layer ray) and only falls
## back to its own ray for the station, which has no brain. A witness whose own check says
## "blocked" witnesses nothing even though the scene's own ray would answer clear here.
##
## **Why the rock is not a physics body in this test.** The headless runner calls every
## suite from its own `_ready`, before the engine's first physics step, so no body is in the
## 2D broadphase yet: a ray cast from a test hits nothing, measured (a 66 u-radius rock
## placed across a 400 u ray is not seen). The harness therefore cannot measure rock
## occlusion; what it can measure - and what this test does - is that the hull's own
## verdict is the one the witness rule reads, plus that both rays mask the same layer
## (`NpcShip.HULL_MASK` is `Asteroid.COLLISION_LAYER`, the brain's own mask).
func test_the_witness_line_is_the_brains_own_rock_check() -> void:
	assert_eq(
		NpcShipScript.HULL_MASK,
		AsteroidScript.COLLISION_LAYER,
		"the brain's LOS ray and the rock layer are the same mask"
	)
	var scene := _open_game()
	var profile := _store()
	if scene == null or profile == null:
		return
	profile.call(&"set_heat", {})
	var witness := _witness(DEAD_SPACE + Vector2(200.0, 0.0), &"neutral")
	assert_true(bool(scene.call(&"_witnessed", DEAD_SPACE)), "a clear line witnesses")
	witness.blind = true
	assert_false(
		bool(scene.call(&"_witnessed", DEAD_SPACE)),
		"the hull's own rock-blocked verdict is the one the scene reads"
	)
	scene.call(&"_on_npc_died", DEAD_SPACE, &"trader", _victim(&"trader"))
	assert_eq(_heat_of(profile, &"concord"), 0, "so the crime files nothing")


## 13 §5's station half: a kill inside the station's own witness radius scores, and the
## station stands in for the turret bolted to it.
func test_the_station_is_a_witness() -> void:
	var scene := _open_game()
	var profile := _store()
	if scene == null or profile == null:
		return
	var sector: Node = scene.get(&"_sector")
	assert_true(bool(sector.call(&"has_station")), "sector 1 is inhabited")
	profile.call(&"set_heat", {})
	var station: Vector2 = sector.call(&"station_position")
	var at := station + Vector2(100.0, 0.0)
	assert_true(bool(scene.call(&"_witnessed", at)), "the station witnesses inside 900 u")
	scene.call(&"_on_npc_died", at, &"trader", _victim(&"trader"))
	assert_eq(
		_heat_of(profile, &"concord"),
		_row_value(&"trader", NpcRegistryScript.KEY_HEAT_ON_KILL) + GameScript.WITNESS_EXTRA,
		"and the crime scores"
	)


## 13 §2's reduction is **not** a crime: killing a pirate costs the local faction nothing
## and returns 3 heat with no witness in sight and no surcharge.
func test_the_pirate_reduction_needs_no_witness_and_never_surcharges() -> void:
	var scene := _open_game()
	var profile := _store()
	if scene == null or profile == null:
		return
	assert_false(bool(scene.call(&"_witnessed", DEAD_SPACE)), "no witness at the kill point")
	profile.call(&"set_heat", {"concord": 10})
	scene.call(&"_on_npc_died", DEAD_SPACE, &"pirate", _victim(&"pirate"))
	assert_eq(
		_heat_of(profile, &"concord"),
		10 + _row_value(&"pirate", NpcRegistryScript.KEY_HEAT_ON_KILL),
		"the pirate's own -3 lands unwitnessed"
	)
	profile.call(&"set_heat", {})
	scene.call(&"_on_npc_died", DEAD_SPACE, &"pirate", _victim(&"pirate"))
	assert_eq(
		profile.call(&"heat"), {}, "a floor-0 reduction leaves no zero-heat key behind"
	)


## 13 §2's bound: a gain is clamped to 100 and a reduction to 0, per faction.
func test_heat_is_clamped_to_the_zero_to_hundred_band() -> void:
	var scene := _open_game()
	var profile := _store()
	if scene == null or profile == null:
		return
	profile.call(&"set_heat", {"concord": 95})
	_witness(DEAD_SPACE + Vector2(200.0, 0.0), &"neutral")
	scene.call(&"_on_npc_died", DEAD_SPACE, &"patrol", _victim(&"patrol"))
	assert_eq(
		_heat_of(profile, &"concord"),
		GameScript.HEAT_MAX,
		"95 + 25 + 5 clamps at 13 §2's ceiling"
	)
	assert_eq(profile.call(&"heat_of", &"concord"), GameScript.HEAT_MAX, "and reads back bounded")
	profile.call(&"set_heat", {"concord": 2})
	scene.call(&"_on_npc_died", DEAD_SPACE, &"pirate", _victim(&"pirate"))
	assert_eq(_heat_of(profile, &"concord"), 0, "and 2 - 3 floors at 0")


## A dead neutral hull does not witness its own murder. `NpcShip._die` raises `died` before
## it leaves the tree (so every listener runs on a live node), so the victim is still in the
## `npc_ship` group and still at the kill point - the exact hull 13 §5's rule would count as
## a witness if the seam did not exclude it. Measured with the sector's **own** convoy hull,
## moved to dead space: a stub victim could not show this.
func test_a_dead_neutral_hull_does_not_witness_its_own_kill() -> void:
	var scene := _open_game()
	var profile := _store()
	if scene == null or profile == null:
		return
	var sector: Node = scene.get(&"_sector")
	if sector == null:
		return
	profile.call(&"set_heat", {})
	var victim := _move_to_dead_space(_find_hull(sector, &"trader"))
	assert_true(victim != null, "sector 1 spawned a convoy hull to kill")
	if victim == null:
		return
	assert_true(
		StringName(victim.call(&"blip_kind")) == NpcRegistryScript.BLIP_NEUTRAL,
		"the victim is 13 §5's neutral hull"
	)
	assert_true(victim.is_in_group(NpcRegistryScript.GROUP), "and still in the witness group")
	assert_eq(
		int(victim.call(&"heat_on_kill")),
		_row_value(&"trader", NpcRegistryScript.KEY_HEAT_ON_KILL),
		"whose row is the trader's"
	)
	assert_false(
		bool(scene.call(&"_witnessed", DEAD_SPACE, victim)),
		"the victim is excluded from its own kill's witness scan"
	)
	scene.call(&"_on_npc_died", DEAD_SPACE, &"trader", victim)
	assert_eq(_heat_of(profile, &"concord"), 0, "so the unwitnessed crime files nothing")


## ---------------------------------------------------------------------------
## 13 §7's decay
## ---------------------------------------------------------------------------


## -1 per minute of **play time**, for every faction at once, floored at 0 - and a partial
## minute banks rather than rounds.
func test_heat_decays_one_per_minute_of_play() -> void:
	var scene := _open_game()
	var profile := _store()
	if scene == null or profile == null:
		return
	profile.call(&"set_heat", {"concord": 40, "meridian": 5})
	var minute := GameScript.HEAT_DECAY_SECONDS
	scene.call(&"_decay_heat", minute - 0.1)
	assert_eq(_heat_of(profile, &"concord"), 40, "59.9 s of play is not yet a minute")
	scene.call(&"_decay_heat", 0.2)
	assert_eq(_heat_of(profile, &"concord"), 39, "60 s of play cools one point")
	assert_eq(_heat_of(profile, &"meridian"), 4, "and cools every faction, anywhere")
	scene.call(&"_decay_heat", minute * 3.0)
	assert_eq(_heat_of(profile, &"concord"), 36, "three more minutes cool three more")
	assert_eq(_heat_of(profile, &"meridian"), 1, "the small heat is not floored early")
	scene.call(&"_decay_heat", minute * 10.0)
	assert_eq(_heat_of(profile, &"concord"), 26, "the bank keeps counting")
	scene.call(&"_decay_heat", minute * 60.0)
	assert_eq(_heat_of(profile, &"meridian"), 0, "and stops at 13 §2's floor")
	var at_floor := _profile_snapshot(profile)
	scene.call(&"_decay_heat", minute * 5.0)
	assert_eq(_profile_snapshot(profile), at_floor, "a fully cooled record writes nothing")


## ---------------------------------------------------------------------------
## 13 §2's fine math and `pay_bounty`
## ---------------------------------------------------------------------------


## 13 §2's own worked row: `fine = heat x 25 CR`, so 40 heat costs 1 000 CR.
func test_the_fine_is_heat_times_twenty_five() -> void:
	var profile := _store()
	if profile == null:
		return
	profile.call(&"set_heat", {})
	assert_eq(profile.call(&"bounty_fine", &"concord"), 0, "no heat owes nothing")
	profile.call(&"set_heat", {"concord": FINE_HEAT})
	assert_eq(
		profile.call(&"bounty_fine", &"concord"), FINE_CREDITS, "13 §2's own 40 heat = 1 000 CR"
	)
	assert_eq(
		profile.call(&"bounty_fine", &"concord"),
		FINE_HEAT * 25,
		"the rate is 25 CR per point of heat"
	)
	assert_eq(profile.call(&"bounty_fine", &"meridian"), 0, "and it is per faction")


## 17 §5's law on the success path: one charge, one `BOUNTY` log line, that faction's heat
## cleared and every other faction's left alone.
func test_pay_bounty_clears_that_faction_and_logs_one_line() -> void:
	var profile := _store()
	if profile == null:
		return
	profile.call(&"set_heat", {"concord": FINE_HEAT, "meridian": 12})
	profile.set(&"_credits", 5000)
	var lines_before := _lines_with("BOUNTY").size()
	assert_true(bool(profile.call(&"pay_bounty", &"concord")), "the fine is paid")
	assert_eq(int(profile.call(&"credits")), 5000 - FINE_CREDITS, "the fine leaves the balance")
	assert_eq(
		profile.call(&"heat"), {"concord": 0, "meridian": 12}, "concord is zeroed, Meridian is not"
	)
	assert_eq(profile.call(&"heat_of", &"concord"), 0, "and reads back as zero")
	var bounty_lines := _lines_with("BOUNTY")
	assert_eq(bounty_lines.size(), lines_before + 1, "exactly one BOUNTY line is appended")
	assert_true(
		bounty_lines[0].contains("-1000"), "the line carries the fine as its credits delta"
	)
	assert_eq(_heat_of(profile, &"concord"), 0, "nothing is left owed")


## "Refusals write nothing": a zero heat and a short balance both return `false` with the
## profile byte-identical and no log line.
func test_pay_bounty_refusals_write_nothing() -> void:
	var profile := _store()
	if profile == null:
		return
	profile.call(&"set_heat", {})
	profile.set(&"_credits", 5000)
	var empty := _profile_snapshot(profile)
	var lines_before := _log_lines().size()
	assert_false(bool(profile.call(&"pay_bounty", &"concord")), "no heat is nothing to pay")
	assert_eq(_profile_snapshot(profile), empty, "and the profile is byte-identical")
	profile.call(&"set_heat", {"concord": FINE_HEAT})
	profile.set(&"_credits", FINE_CREDITS - 1)
	var short := _profile_snapshot(profile)
	assert_false(bool(profile.call(&"pay_bounty", &"concord")), "999 CR cannot pay 1 000")
	assert_eq(_profile_snapshot(profile), short, "a short balance writes nothing")
	assert_eq(int(profile.call(&"credits")), FINE_CREDITS - 1, "no partial charge")
	assert_eq(profile.call(&"heat"), {"concord": FINE_HEAT}, "and no partial clear")
	assert_eq(_log_lines().size(), lines_before, "neither refusal wrote a log line")


## ---------------------------------------------------------------------------
## 13 §3 / 12 §4.1's two refusal axes
## ---------------------------------------------------------------------------


## The two axes are independent and each reads its own doc: the **gate** refusal is the
## heat tier (13 §3), the **dock** refusal is standing (12 §4.1) - and the dock refusal
## writes nothing, not even the vitals an allowed dock files.
func test_the_gate_reads_heat_and_the_dock_reads_standing() -> void:
	var scene := _open_game()
	var profile := _store()
	if scene == null or profile == null:
		return
	var sector: Node = scene.get(&"_sector")
	var ship: Node2D = scene.get(&"_ship")
	assert_true(sector != null and ship != null, "the scene has a sector and a ship")
	if sector == null or ship == null:
		return
	var gates: Array = sector.call(&"gates")
	assert_true(gates.size() >= 1, "sector 1 has a gate link")
	if gates.is_empty():
		return
	## An earlier test in this suite may have filed a report or a docked faction; the
	## refusal's proof is that this dock writes neither, so both start empty here.
	profile.set(&"_vitals", {})
	profile.call(&"set_docked_faction", &"")
	var gate: Node2D = gates[0]
	## Heat Outlaw, standing clean: the gate refuses, the dock does not.
	profile.call(&"set_heat", {String(_owner()): 95})
	profile.call(&"set_standing", {})
	ship.global_position = gate.global_position
	scene.call(&"_update_dock_prompt")
	assert_eq(String(scene.get(&"_prompt")), GameScript.GATE_REFUSED_PROMPT, "13 §3: refused")
	assert_false(bool(scene.call(&"_dock_refused")), "12 §4.1: standing is clean, so docking is not")
	## Heat clean, standing Outlaw: the gate sells a ticket, the dock refuses.
	profile.call(&"set_heat", {})
	profile.call(&"set_standing", {String(_owner()): GameScript.STANDING_OUTLAW})
	scene.call(&"_update_dock_prompt")
	assert_true(String(scene.get(&"_prompt")).begins_with("JUMP TO"), "13 §3: the jump line")
	assert_true(bool(scene.call(&"_dock_refused")), "12 §4.1: the Outlaw band denies docking")
	ship.global_position = sector.call(&"station_position")
	assert_true(bool(scene.call(&"_inside_dock_zone")), "the ship is inside the dock zone")
	scene.call(&"_update_dock_prompt")
	assert_eq(String(scene.get(&"_prompt")), GameScript.DOCK_REFUSED_PROMPT, "the refusal line")
	var before := _profile_snapshot(profile)
	scene.call(&"_request_dock")
	assert_eq(_profile_snapshot(profile), before, "the dock refusal writes nothing")
	assert_true(
		(profile.call(&"vitals_of", profile.call(&"active_ship")) as Dictionary).is_empty(),
		"not even the damage report an allowed dock files"
	)
	assert_eq(String(profile.call(&"docked_faction")), "", "and no docked faction is filed")


## The allowed half of the same axis: a clean-standing dock files the report, names the
## docked faction (13 §7's bounty row reads it) and routes through `loading`.
func test_an_allowed_dock_files_the_report_and_the_docked_faction() -> void:
	var scene := _open_game()
	var profile := _store()
	if scene == null or profile == null:
		return
	var sector: Node = scene.get(&"_sector")
	var ship: Node2D = scene.get(&"_ship")
	if sector == null or ship == null:
		return
	var routes: Array = []
	scene.route_requested.connect(
		func(route: StringName, params: Dictionary) -> void:
			routes.append({&"route": route, &"params": params})
	)
	profile.call(&"set_standing", {})
	profile.call(&"set_heat", {})
	ship.global_position = sector.call(&"station_position")
	scene.call(&"_request_dock")
	assert_eq(routes.size(), 1, "the dock routes once")
	if routes.is_empty():
		return
	assert_eq(StringName(routes[0][&"route"]), &"loading", "through the loading route")
	assert_false(
		(profile.call(&"vitals_of", profile.call(&"active_ship")) as Dictionary).is_empty(),
		"and the damage report is filed first"
	)
	assert_eq(
		String(profile.call(&"docked_faction")), String(_owner()), "the docked faction is named"
	)


## ---------------------------------------------------------------------------
## 13 §3's hunters
## ---------------------------------------------------------------------------


## The registry half: the row is off its slice-4 seam, its tier stays 1, its density stays
## zero (so the ordinary population never rolls it) and its `KEY_MEMBERS` carry doc 13 §7's
## hull map and the 2-3 wing.
func test_the_hunter_row_carries_doc_13_7s_map_and_no_band() -> void:
	var row := NpcRegistryScript.archetype(&"hunter")
	assert_true(not row.is_empty(), "the hunter row exists")
	assert_eq(StringName(row[NpcRegistryScript.KEY_SEAM]), NpcRegistryScript.SEAM_NONE, "off the seam")
	assert_eq(
		StringName(row[NpcRegistryScript.KEY_SPAWN]), NpcRegistryScript.SPAWN_SECTOR, "a sector archetype"
	)
	assert_eq(int(row[NpcRegistryScript.KEY_TIER]), 1, "13 §3's fighter band (test-pinned tier)")
	assert_eq(float(row[NpcRegistryScript.KEY_AGGRO_RADIUS]), 900.0, "the proposed 900 u aggro")
	assert_eq(float(row[NpcRegistryScript.KEY_SCAN_RADIUS]), 900.0, "and the same release radius")
	assert_eq(NpcRegistryScript.hunter_wing_size(), Vector2i(2, 3), "13 §3's 2-3 hull wing")
	for sector_row: Dictionary in SectorRegistryScript.SECTORS:
		var sector_id := StringName(sector_row[&"id"])
		assert_eq(
			NpcRegistryScript.density(&"hunter", sector_id),
			Vector2i.ZERO,
			"%s never rolls a hunter with its band" % sector_id
		)
	## 13 §7's hull map, read off the registry rather than restated: one band below.
	var fighter_band: Array[StringName] = [
		&"ship_fighter", &"ship_interceptor", &"ship_patrol", &"ship_miner",
		&"ship_vanguard", &"ship_trader", &"ship_corvette",
	]
	for hull: StringName in fighter_band:
		assert_eq(
			NpcRegistryScript.hunter_hull_for(hull), &"ship_fighter", "%s draws a fighter wing" % hull
		)
	for hull: StringName in [&"ship_gunship", &"ship_destroyer", &"ship_freighter"]:
		assert_eq(
			NpcRegistryScript.hunter_hull_for(hull), &"ship_gunship", "%s draws a gunship wing" % hull
		)
	var spawn := NpcRegistryScript.hunter_spawn(&"sector_1", &"ship_vanguard")
	assert_eq(StringName(spawn[NpcRegistryScript.KEY_ARCHETYPE]), &"hunter", "the spawn row is a hunter")
	assert_eq(StringName(spawn[NpcRegistryScript.KEY_FACTION_ID]), _owner(), "in the space's faction")
	assert_eq(
		Vector2i(int(spawn[NpcRegistryScript.KEY_MIN]), int(spawn[NpcRegistryScript.KEY_MAX])),
		Vector2i(2, 3),
		"carrying the wing's own band"
	)


## 13 §3's Wanted row: a wing of 2-3 spawns on sector entry, once, and a Clean tier spawns
## nothing.
func test_wanted_spawns_two_to_three_hunters_on_sector_entry() -> void:
	var scene := _open_game()
	var profile := _store()
	if scene == null or profile == null:
		return
	profile.call(&"set_heat", {})
	scene.call(&"_update_hunters", 0.0)
	assert_eq(int(scene.call(&"_live_hunters")), 0, "a Clean tier spawns nothing")
	profile.call(&"set_heat", {String(_owner()): 55})
	scene.call(&"_update_hunters", 0.0)
	var live := int(scene.call(&"_live_hunters"))
	assert_true(live >= 2 and live <= 3, "13 §3's 2-3 hull wing, measured %d" % live)
	var sector: Node = scene.get(&"_sector")
	for hull: Node2D in sector.call(&"npcs"):
		if StringName(hull.call(&"archetype")) != &"hunter":
			continue
		assert_eq(StringName(hull.call(&"blip_kind")), NpcRegistryScript.BLIP_HOSTILE, "a hostile blip")
		assert_eq(StringName(hull.call(&"faction")), _owner(), "flying the space owner's flag")
		assert_true(
			hull.global_position.distance_to((scene.get(&"_ship") as Node2D).global_position)
				<= GameScript.HUNTER_SPAWN_RADIUS + 1.0,
			"the wing is homed on the player (a tail, not a field patrol)"
		)
	scene.call(&"_update_hunters", 5.0)
	assert_eq(int(scene.call(&"_live_hunters")), live, "one wing per sector entry, not per frame")


## 13 §3's Outlaw row: a wing that dies comes back after 60 s, and only Outlaw perma-tails.
func test_outlaw_respawns_the_tail_after_sixty_seconds() -> void:
	var scene := _open_game()
	var profile := _store()
	if scene == null or profile == null:
		return
	profile.call(&"set_heat", {String(_owner()): 85})
	scene.call(&"_update_hunters", 0.0)
	var first := int(scene.call(&"_live_hunters"))
	assert_true(first >= 2, "the Outlaw wing spawns on entry, measured %d" % first)
	_clear_hunters(scene)
	assert_eq(int(scene.call(&"_live_hunters")), 0, "the wing is dead")
	scene.call(&"_update_hunters", GameScript.HUNTER_RESPAWN_SECONDS - 1.0)
	assert_eq(int(scene.call(&"_live_hunters")), 0, "59 s is short of the respawn")
	scene.call(&"_update_hunters", 2.0)
	assert_true(int(scene.call(&"_live_hunters")) >= 2, "60 s brings the tail back")
	## Wanted does not perma-tail: a dead Wanted wing stays dead.
	profile.call(&"set_heat", {String(_owner()): 55})
	_clear_hunters(scene)
	scene.call(&"_update_hunters", GameScript.HUNTER_RESPAWN_SECONDS * 4.0)
	assert_eq(int(scene.call(&"_live_hunters")), 0, "13 §3: only Outlaw perma-tails")


## 13 §3's per-faction rule: Concord hunts only Concord's outlaw. A high heat with one
## faction spawns nothing in another faction's space, and nobody hunts in nobody's space.
func test_hunters_are_per_faction_and_only_in_that_factions_space() -> void:
	var scene := _open_game()
	var profile := _store()
	if scene == null or profile == null:
		return
	assert_ne(_owner(), NpcRegistryScript.space_owner(&"sector_3"), "sector 3 is another faction's")
	profile.call(&"set_heat", {String(_owner()): 55})
	scene.call(&"on_route", {&"sector": &"sector_3"})
	assert_eq(int(scene.call(&"_live_hunters")), 0, "Concord's heat does not hunt in Meridian space")
	profile.call(&"set_heat", {String(NpcRegistryScript.space_owner(&"sector_3")): 55})
	scene.call(&"_update_hunters", 0.0)
	var live := int(scene.call(&"_live_hunters"))
	assert_true(live >= 2, "Meridian's own heat does, measured %d" % live)
	var sector: Node = scene.get(&"_sector")
	for hull: Node2D in sector.call(&"npcs"):
		if StringName(hull.call(&"archetype")) == &"hunter":
			assert_eq(
				StringName(hull.call(&"faction")),
				NpcRegistryScript.space_owner(&"sector_3"),
				"the wing wears the space owner's flag"
			)
	## Nobody's space: no faction owns sector 7, so no heat tier can spawn a wing there.
	profile.call(&"set_heat", {String(NpcRegistryScript.space_owner(&"sector_3")): 95})
	scene.call(&"on_route", {&"sector": &"sector_7"})
	scene.call(&"_update_hunters", 0.0)
	assert_eq(int(scene.call(&"_live_hunters")), 0, "unaligned space has no owner to hunt for")


## 13 §3 / 06 §8: a hunter drops its band table **plus** `HUNTER_EXTRA`. The pirate row
## shares the band table and never draws the extra, so the two are told apart by the one
## stack size only the extra can pay (see `_extra_stacks`).
func test_a_hunter_drops_its_band_table_plus_the_hunter_extra() -> void:
	var scene := _open_game()
	if scene == null:
		return
	var item := StringName(LootTablesScript.HUNTER_EXTRA[0][&"item"])
	assert_eq(
		_line_max(LootTablesScript.FIGHTER_LINES, item),
		1,
		"06 §3.1's own fighter line pays one of the shared item"
	)
	assert_eq(
		_line_max(LootTablesScript.HUNTER_EXTRA, item),
		2,
		"06 §8's extra pays up to two, so a stack of two is the extra's tell"
	)
	assert_eq(
		_extra_stacks(scene, &"pirate", LOOT_KILLS),
		0,
		"a fighter-band pirate never draws 06 §8's extra"
	)
	assert_gt(
		_extra_stacks(scene, &"hunter", LOOT_KILLS),
		0,
		"a hunter draws it (about a quarter of its kills, measured over %d)" % LOOT_KILLS
	)


## ---------------------------------------------------------------------------
## 13 §7's bounty surface (14 §7)
## ---------------------------------------------------------------------------


## 14 §7's condition: the row is shown for the docked station's faction while its heat is
## above zero, and its label carries the profile's own fine.
func test_the_bounty_row_shows_only_for_the_docked_factions_heat() -> void:
	var profile := _store()
	if profile == null:
		return
	profile.call(&"set_heat", {})
	profile.call(&"set_docked_faction", &"")
	_mount_panel()
	var button := _bounty_button()
	assert_true(button != null, "the bounty button exists")
	if button == null:
		return
	assert_false(button.visible, "no docked faction, no row")
	profile.call(&"set_docked_faction", &"concord")
	_panel.call(&"refresh_profile", &"credits")
	assert_false(button.visible, "no heat, no row")
	profile.call(&"set_heat", {"concord": FINE_HEAT})
	_panel.call(&"refresh_profile", &"credits")
	assert_true(button.visible, "heat > 0 shows the row")
	var name := String(_service(&"bounty").get(&"name", ""))
	assert_eq(
		button.text,
		"%s (%d CR)" % [name, FINE_CREDITS],
		"the label is the catalogue's own name plus the profile's fine"
	)
	profile.call(&"set_heat", {"concord": FINE_HEAT, "meridian": 90})
	assert_eq(
		int(profile.call(&"bounty_fine", &"concord")),
		FINE_CREDITS,
		"another faction's heat is not this station's fine"
	)


## 14 §7's single confirm: a press pays through the profile, the row collapses and the pane
## says so; a short balance refuses with the profile untouched.
func test_the_bounty_row_pays_and_writes_nothing_on_a_refusal() -> void:
	var profile := _store()
	if profile == null:
		return
	profile.call(&"set_heat", {"concord": FINE_HEAT})
	profile.call(&"set_docked_faction", &"concord")
	profile.set(&"_credits", 5000)
	_mount_panel()
	var button := _bounty_button()
	if button == null:
		return
	assert_true(button.visible, "the row is shown with heat owed")
	button.pressed.emit()
	assert_eq(int(profile.call(&"credits")), 5000 - FINE_CREDITS, "the fine was charged")
	assert_eq(_heat_of(profile, &"concord"), 0, "and the heat is cleared")
	assert_false(button.visible, "so the row collapses")
	assert_true(
		_status.size() >= 1 and _status[_status.size() - 1].contains("BOUNTY PAID"),
		"the pane reports the payment"
	)
	## The refusal: heat owed again, a balance one credit short.
	profile.call(&"set_heat", {"concord": FINE_HEAT})
	profile.set(&"_credits", FINE_CREDITS - 1)
	_panel.call(&"refresh_profile", &"credits")
	assert_true(button.visible, "the row is back")
	var before := _profile_snapshot(profile)
	var lines_before := _log_lines().size()
	button.pressed.emit()
	assert_eq(_profile_snapshot(profile), before, "the refusal writes nothing")
	assert_eq(_log_lines().size(), lines_before, "and logs nothing")
	assert_true(_last_status().contains("REFUSED"), "the refusal is rendered in the pane")
	assert_true(button.visible, "and the row stays up, still owed")


## ---------------------------------------------------------------------------
## The tier the sector reads (13 §5's two behaviours, end to end)
## ---------------------------------------------------------------------------


## A witnessed crime pushes the local heat to Suspect, and the sector's own hulls act on
## it: 13 §5's trader panic (the brain's Flee state) and the patrol's scan-on-sight (the
## brain's Scan state). This is the K3 seam - the kill's heat reaching the brain.
func test_a_witnessed_crime_turns_the_sector_suspect() -> void:
	var scene := _open_game()
	var profile := _store()
	if scene == null or profile == null:
		return
	var sector: Node = scene.get(&"_sector")
	if sector == null:
		return
	profile.call(&"set_heat", {})
	var at: Vector2 = sector.call(&"station_position") + Vector2(100.0, 0.0)
	scene.call(&"_on_npc_died", at, &"trader", _victim(&"trader"))
	assert_eq(
		_heat_of(profile, &"concord"),
		20,
		"13 §2's trader +15 plus the +5 witness extra lands at Suspect's own floor"
	)
	assert_eq(
		StringName(NpcRegistryScript.heat_tier(_heat_of(profile, &"concord"))),
		NpcRegistryScript.HEAT_SUSPECT,
		"which is 13 §3's Suspect band"
	)
	var saw_trader := false
	var saw_patrol := false
	for hull: Node2D in sector.call(&"npcs"):
		var archetype := StringName(hull.call(&"archetype"))
		if archetype == &"trader":
			saw_trader = true
			hull.call(&"_steer_frame", 1.0)
			assert_eq(
				StringName(hull.call(&"state_name")), &"flee", "13 §5: the convoy runs"
			)
		elif archetype == &"patrol":
			saw_patrol = true
			hull.call(&"_steer_frame", 1.0)
			assert_eq(
				StringName(hull.call(&"state_name")), &"scan", "13 §5: the patrol scans on sight"
			)
	assert_true(saw_trader, "sector 1 spawned its convoy")
	assert_true(saw_patrol, "and its patrol")


## ---------------------------------------------------------------------------
## Helpers
## ---------------------------------------------------------------------------


## The space owner of the sector this scene is in, read off the registry.
func _owner() -> StringName:
	return NpcRegistryScript.space_owner(&"sector_1")


## One row's own value for a key, so no test restates 13 §2's table.
func _row_value(archetype: StringName, key: StringName) -> int:
	return int(NpcRegistryScript.archetype(archetype).get(key, 0))


## One faction's heat, read through the profile's bounded accessor.
func _heat_of(profile: Node, faction: StringName) -> int:
	return int(profile.call(&"heat_of", faction))


func _victim(archetype: StringName) -> Node2D:
	var hull := StubHull.new()
	hull.name = "Stub%s" % String(archetype).capitalize()
	hull.archetype_id = archetype
	_fixture_host().add_child(hull)
	_bare.append(hull)
	return hull


## A witness in the `npc_ship` group at `at` - the group `game.gd:_witnessed` reads, which
## a real `NpcShip` joins in its own `_ready`.
func _witness(at: Vector2, blip: StringName, hostility_id: StringName = &"") -> StubWitness:
	var hull := StubWitness.new()
	hull.name = "StubWitness"
	hull.blip = blip
	hull.hostility_id = hostility_id
	hull.add_to_group(NpcRegistryScript.GROUP)
	_fixture_host().add_child(hull)
	hull.global_position = at
	_bare.append(hull)
	return hull


## One live sector hull of an archetype, or null. The sector's own population is the only
## source of a **real** `NpcShip` in this suite.
func _find_hull(sector: Node, archetype: StringName) -> Node2D:
	for hull: Node2D in sector.call(&"npcs"):
		if hull != null and is_instance_valid(hull):
			if StringName(hull.call(&"archetype")) == archetype:
				return hull
	return null


## Moves a live hull (and the body `NpcShip` takes its transform from) to dead space, so a
## kill there has no witness but the hull itself.
func _move_to_dead_space(hull: Node2D) -> Node2D:
	if hull == null:
		return null
	hull.global_position = DEAD_SPACE
	if hull.has_method(&"impact_body"):
		var body := hull.call(&"impact_body") as RigidBody2D
		if body != null:
			body.global_position = DEAD_SPACE
	return hull


## Frees this sector's live hunter hulls, so a dead wing is a reading and not an absence.
func _clear_hunters(scene: Node) -> void:
	var sector: Node = scene.get(&"_sector")
	if sector == null:
		return
	for hull: Node2D in sector.call(&"npcs"):
		if StringName(hull.call(&"archetype")) == &"hunter":
			hull.free()


## How many of `count` kills of `archetype` left a wreck site holding a `comp_elec_1`
## stack **larger than the band table's own line pays**. 06 §3.1's fighter line pays 1..1
## while 06 §8's extra pays 1..2, and `roll_band` ships one entry per line with the lines
## distinct, so a 2 is the extra and nothing else. Both the item and the bound are read
## off their tables (`_line_max`), so a doc change turns this red rather than silently
## weakening it. The victim is a stub whose row is the archetype's own, so the only
## difference between the two halves is the archetype id `_spawn_kill_loot` reads.
func _extra_stacks(scene: Node, archetype: StringName, count: int) -> int:
	var sector: Node = scene.get(&"_sector")
	if sector == null:
		return 0
	var item := StringName(LootTablesScript.HUNTER_EXTRA[0][&"item"])
	var bound := _line_max(LootTablesScript.FIGHTER_LINES, item)
	var hits := 0
	for index in count:
		var at := DEAD_SPACE + Vector2(float(index) * 10.0, 0.0)
		scene.call(&"_on_npc_died", at, archetype, _victim(archetype))
		var wrecks: Array = sector.call(&"wrecks")
		if wrecks.is_empty():
			continue
		var site: Node2D = wrecks[wrecks.size() - 1]
		for pickup: Node2D in site.call(&"pickups"):
			if StringName(pickup.get(&"item_id")) != item:
				continue
			if int(pickup.get(&"amount")) > bound:
				hits += 1
				break
	return hits


## One table line's own `max`, read off the table: 0 for an item the table does not name.
func _line_max(lines: Array[Dictionary], item: StringName) -> int:
	for line: Dictionary in lines:
		if StringName(line[&"item"]) == item:
			return int(line[&"max"])
	return 0


## Mounts the shipped LAUNCH pane the way the station shell does: into a sized host with
## the shell's own two wirings (the pane's status line up, the profile's keys down).
func _mount_panel() -> void:
	_host = Control.new()
	_host.name = "HeatHost"
	_host.theme = ThemeRes
	_host.size = Vector2(1920.0, 1080.0)
	_fixture_host().add_child(_host)
	_panel = LaunchScene.instantiate() as Control
	_host.add_child(_panel)
	var profile := _store()
	if profile != null:
		profile.connect(&"profile_changed", Callable(_panel, &"refresh_profile"))
	_panel.connect(&"status_requested", _on_status)


func _bounty_button() -> Button:
	if _panel == null:
		return null
	return _panel.call(&"bounty_button") as Button


func _service(id: StringName) -> Dictionary:
	return Catalog.service(id)


func _on_status(message: String, _danger: bool) -> void:
	_status.append(message)


func _last_status() -> String:
	return _status[_status.size() - 1] if not _status.is_empty() else ""


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


## Every field a refusal must leave alone, deep-compared by `assert_eq`.
func _profile_snapshot(profile: Node) -> Dictionary:
	return {
		"credits": int(profile.call(&"credits")),
		"cargo": profile.call(&"cargo_items"),
		"heat": profile.call(&"heat"),
		"standing": profile.call(&"standing"),
		"ammo_laser": int(profile.call(&"ammo_of", &"laser")),
		"vitals": profile.call(&"vitals_of", profile.call(&"active_ship")),
		"docked_faction": String(profile.call(&"docked_faction")),
	}


func _log_lines() -> Array[String]:
	var out: Array[String] = []
	if not FileAccess.file_exists(SCRATCH_LOG):
		return out
	var file := FileAccess.open(SCRATCH_LOG, FileAccess.READ)
	if file == null:
		return out
	var text := file.get_as_text()
	file.close()
	for line: String in text.split("\n", false):
		if not line.strip_edges().is_empty():
			out.append(line)
	return out


func _lines_with(event: String) -> Array[String]:
	var out: Array[String] = []
	for line: String in _log_lines():
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
