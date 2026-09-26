@tool
extends McpTestSuite
## Suite s19_quadrants: wave S19's directional armour and breach malfunctions (owner
## ruling 23; 09 section 3.3's 2026-09-26 amendment, P1-P8, and 01 section 6's repair
## amendment). One section per acceptance criterion:
##
## AC1 the arc map (P2): every quadrant's interior and both of its boundary angles, plus
##     a missing, zero or non-numeric `direction` reading 0.0 (dead ahead, the prow);
## AC2 the rear 160 degree arc (P3): x1.6 inside it, x1.0 outside, multiplied into the
##     incoming amount **before** the shield-first absorb;
## AC3 the pools (P1/P6): `hull_max / 4` each at full repair, shield-first with no
##     carry-over, the emptying pool's even spill, `hull == sum(pools)` after every step
##     and `died` firing exactly once;
## AC4 the malfunctions (P4/P5): the seeded drift sign on its 2.0 s cadence, the seeded
##     flicker share of thrust ticks, the flank turn clip, and the derived clear a
##     repair gives;
## AC5 repairs and readout: `Repairs.repair` restores the pools with the fee law intact,
##     and both panes list four quadrant entries without moving a shipped row;
## AC6 the consts against the amendment's own values and the four forbidden files'
##     byte identity.
##
## Nothing here awaits a frame (the runner never does): the hull half drives the shipped
## `_physics_process` itself, the way `test_s2_6_flight.gd` does, and the RNG is reseeded
## through the hull's own `seed_breach_rolls` with a twin `RandomNumberGenerator` in the
## suite computing the expected rolls. The two panes mount on a themed throwaway host.
## The profile fixture installs/restores the active hull, credits and fit the panes read.

const PlayerStateScript := preload("res://game/player_state.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const PlayerShipScene := preload("res://game/player_ship.tscn")
const PlayerShipScript := preload("res://game/player_ship.gd")
const DamageScript := preload("res://game/damage.gd")
const RepairsScript := preload("res://game/repairs.gd")
const RepairsPanelScene := preload("res://ui/station/repairs_panel.tscn")
const StatusScreenScript := preload("res://ui/hud/ship_status_screen.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")
const Log := preload("res://game/economy_log.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")

const HULL: StringName = &"ship_vanguard"
const HULL_MAX := 1000.0
const SHIELD_MAX := 600.0
const QUARTER := HULL_MAX / 4.0
const PROBE_HIT := 100.0
const PROFILE_SERVICE: StringName = &"PlayerProfile"
const SCRATCH_PROFILE := "user://test_s19_quadrants.cfg"
const SCRATCH_LOG := "user://test_s19_quadrants_log.txt"

const THRUST_FORWARD: StringName = &"thrust_forward"
const TURN_LEFT: StringName = &"turn_left"
const TURN_RIGHT: StringName = &"turn_right"
const ACTIONS: Array[StringName] = [
	THRUST_FORWARD, &"thrust_backward", TURN_LEFT, TURN_RIGHT,
	&"strafe_left", &"strafe_right",
]

## The breach rolls' seed the drift and flicker tests reseed the hull to, with a twin
## generator in the suite replaying the same sequence (the `ARC_SEED` pattern).
const BREACH_SEED := 20260926
## A quarter second is exact in binary, so eight frames are exactly P4's 2.0 s cadence.
const DRIFT_FRAME := 0.25

## The arc map the amendment pins (P2/P3): direction, quadrant, why the row exists.
const ARC_CASES: Array = [
	[0.0, &"prow", "dead ahead"],
	[PI / 4.0, &"prow", "the prow boundary"],
	[-PI / 4.0, &"prow", "the port mirror of the prow boundary"],
	[PI / 4.0 + 0.01, &"starboard", "just off the prow boundary"],
	[PI / 2.0, &"starboard", "the starboard flank"],
	[PI * 3.0 / 4.0 - 0.01, &"starboard", "just inside the stern boundary"],
	[PI * 3.0 / 4.0, &"stern", "the stern boundary"],
	[PI, &"stern", "dead astern"],
	[-PI, &"stern", "dead astern, the half-open end"],
	[-PI * 3.0 / 4.0, &"stern", "the port stern boundary"],
	[-PI * 3.0 / 4.0 + 0.01, &"port", "just inside the port stern boundary"],
	[-PI / 2.0, &"port", "the port flank"],
	[-PI / 4.0 - 0.01, &"port", "just off the port prow boundary"],
]

## The fit the two panes' fixtures install, the standard Vanguard shape (1000 hull,
## 600 shield) so the readout's expected strings are the resolved figures.
const FIXTURE_FIT: Dictionary = {
	&"engines": [&"e_std"],
	&"power": &"p_std",
	&"weapons": [&"w_laser"],
	&"shields": [&"s_light"],
	&"armour": [],
}

## AC6's byte-identity yardstick: the four forbidden files' SHA-256s, taken at the wave's
## start (pre-grep, before the first edit). Any agent that touches one of these moves its
## hash, so the suite is the wave's own seal.
const FORBIDDEN_FILES: Dictionary = {
	"res://game/damage.gd": "5cabf3d9302fe942aff2ad97b4f3dc85c298e7e204fffb0e86f89e444cbf6269",
	"res://game/npc_ship.gd": "de8596b161dda9edbaef8e39f36c460303b4902d48cdacdbf64b1979c91981be",
	"res://game/npc_brain.gd": "e39440bf410b535c50f924208290e54dc8085eea52731890b778a4ad3fbe5d22",
	"res://game/weapons.gd": "fcdc549f0b0b3c6a3523e79af2b4797472f65b380f88b9771837b3b6497f8279",
}

var _staged: Array[Node] = []
var _pane_host: Control = null
var _profile: Node = null
var _saved: Dictionary = {}


func suite_name() -> String:
	return "s19_quadrants"


func suite_setup(_ctx: Dictionary) -> void:
	_profile = _host()
	_pane_host = Control.new()
	_pane_host.name = "S19PaneHost"
	_pane_host.theme = ThemeRes
	_pane_host.size = Vector2(1920.0, 1080.0)
	_host().add_child(_pane_host)


func setup() -> void:
	_release_all()
	_delete_file(SCRATCH_PROFILE)
	Log.log_path = SCRATCH_LOG


func teardown() -> void:
	_release_all()
	for node: Node in _staged:
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			node.free()
	_staged.clear()


func suite_teardown() -> void:
	_restore_profile()
	if _pane_host != null and is_instance_valid(_pane_host):
		_pane_host.free()
	_pane_host = null
	Log.log_path = Log.DEFAULT_PATH
	_delete_file(SCRATCH_PROFILE)
	_delete_file(SCRATCH_LOG)


## ---------------------------------------------------------------------------
## AC1/AC2 -- the arc map and the rear vulnerability
## ---------------------------------------------------------------------------


func test_the_pools_split_hull_max_into_four_even_quarters() -> void:
	var state := _fresh_state()
	for quadrant: StringName in PlayerStateScript.QUADRANTS:
		assert_true(
			is_equal_approx(state.pool_of(quadrant), QUARTER),
			"%s opens at hull_max / 4 (%.3f)" % [quadrant, state.pool_of(quadrant)]
		)
		assert_false(state.breached(quadrant), "%s starts intact" % quadrant)
	assert_true(is_equal_approx(state.hull, HULL_MAX), "the hull is their sum")


func test_routing_sends_each_arc_to_its_own_pool() -> void:
	for entry: Array in ARC_CASES:
		var direction: float = entry[0]
		var expected: StringName = entry[1]
		## The shipped amount is P3's x1.6 inside the rear arc, so the routed pool's drop
		## is read off the same law the arc map is: a starboard hit just inside the stern
		## boundary is still multiplied (the 160 degree arc reaches into both flanks).
		var landed := PROBE_HIT * (
			PlayerStateScript.STERN_DAMAGE_MULT
			if absf(direction) >= PlayerStateScript.STERN_VULN_ARC
			else 1.0
		)
		var state := _fresh_state()
		state.damage(PROBE_HIT, true, _ctx(direction))
		assert_eq(
			PlayerStateScript.quadrant_for(direction),
			expected,
			"%s (d=%.4f): the arc map" % [entry[2], direction]
		)
		for quadrant: StringName in PlayerStateScript.QUADRANTS:
			var want := QUARTER - landed if quadrant == expected else QUARTER
			assert_true(
				is_equal_approx(state.pool_of(quadrant), want),
				"%s (d=%.4f): %s reads %.3f, expected %.3f"
					% [entry[2], direction, quadrant, state.pool_of(quadrant), want]
			)
		assert_true(
			is_equal_approx(state.hull, HULL_MAX - landed),
			"%s (d=%.4f): the hull dropped by the landed hit" % [entry[2], direction]
		)
		print("[s19] route d=%+.4f -> %s pool=%.3f hull=%.3f" % [
			direction, expected, state.pool_of(expected), state.hull
		])


func test_a_missing_or_non_numeric_direction_reads_dead_ahead() -> void:
	for shape: Dictionary in [
		{},
		{PlayerStateScript.CTX_DIRECTION: 0.0},
		{PlayerStateScript.CTX_DIRECTION: &"stern"},
	]:
		var state := _fresh_state()
		state.set_shield(0.0)
		state.damage(PROBE_HIT, false, shape)
		assert_true(
			is_equal_approx(state.pool_of(&"prow"), QUARTER - PROBE_HIT),
			"a direction-less hit reads prow (ctx %s)" % shape
		)
		for other: StringName in [&"stern", &"port", &"starboard"]:
			assert_true(
				is_equal_approx(state.pool_of(other), QUARTER),
				"nothing else moved (ctx %s)" % shape
			)
	## The shield keeps the direction-less numbers too: x1.0 and no carry-over.
	var shielded := _fresh_state()
	shielded.damage(PROBE_HIT, false, {})
	assert_true(is_equal_approx(shielded.shield, SHIELD_MAX - PROBE_HIT), "the shield took 100")
	assert_true(is_equal_approx(shielded.hull, HULL_MAX), "and the hull is untouched")


func test_the_rear_arc_multiplies_before_the_shield_absorbs() -> void:
	## Inside the arc (its own boundary and dead astern): x1.6 into the shield-first absorb.
	var inside_shield := 0.0
	for direction: float in [PlayerStateScript.STERN_VULN_ARC, PI, -PI]:
		var state := _fresh_state()
		state.damage(PROBE_HIT, false, _ctx(direction))
		inside_shield = state.shield
		assert_true(
			is_equal_approx(state.shield, SHIELD_MAX - PROBE_HIT * 1.6),
			"d=%.4f: the shield eats the x1.6 amount" % direction
		)
		assert_true(is_equal_approx(state.hull, HULL_MAX), "and no carry-over reaches the hull")
	## Outside it: x1.0.
	var outside_shield := 0.0
	for direction: float in [PlayerStateScript.STERN_VULN_ARC - 0.001, PlayerStateScript.PROW_ARC, 0.0]:
		var state := _fresh_state()
		state.damage(PROBE_HIT, false, _ctx(direction))
		outside_shield = state.shield
		assert_true(
			is_equal_approx(state.shield, SHIELD_MAX - PROBE_HIT),
			"d=%.4f: outside the arc a hit is x1.0" % direction
		)
	print("[s19] rear arc: inside shield=%.3f outside shield=%.3f (base %.3f)" % [
		inside_shield, outside_shield, SHIELD_MAX - PROBE_HIT
	])
	## The application point is the incoming amount, not the hull side: 62.5 x 1.6 = 100
	## empties a 100 point shield whole.
	var point := _fresh_state()
	point.set_shield(100.0)
	point.damage(62.5, false, _ctx(-PI))
	assert_true(is_equal_approx(point.shield, 0.0), "the multiplied hit landed on the shield")
	assert_true(is_equal_approx(point.hull, HULL_MAX), "and stopped there")
	## With the shield down the routed pool takes the multiplied figure.
	var open := _fresh_state()
	open.set_shield(0.0)
	open.damage(PROBE_HIT, false, _ctx(PI))
	assert_true(
		is_equal_approx(open.pool_of(&"stern"), QUARTER - PROBE_HIT * 1.6),
		"the stern pool took 160"
	)


## ---------------------------------------------------------------------------
## AC3 -- the pools, the spill and the sum invariant
## ---------------------------------------------------------------------------


func test_the_pools_take_what_the_shield_leaves() -> void:
	var state := _fresh_state()
	state.set_shield(40.0)
	state.damage(PROBE_HIT, false, _ctx(PI))
	assert_true(is_equal_approx(state.shield, 0.0), "a hit bigger than the shield drains it")
	assert_true(is_equal_approx(state.hull, HULL_MAX), "and carries nothing over (item 1)")
	assert_true(is_equal_approx(state.pool_of(&"stern"), QUARTER), "no pool was touched")
	state.damage(PROBE_HIT, false, _ctx(PI))
	assert_true(
		is_equal_approx(state.pool_of(&"stern"), QUARTER - PROBE_HIT * 1.6),
		"the next rear hit lands on the stern pool"
	)
	_sum_holds(state, "after the shield fell")


func test_an_emptying_pool_spills_its_remainder_evenly() -> void:
	var state := _fresh_state()
	state.set_shield(0.0)
	state.damage(400.0, false, _ctx(0.0))
	assert_true(is_equal_approx(state.pool_of(&"prow"), 0.0), "the prow emptied")
	for other: StringName in [&"stern", &"port", &"starboard"]:
		assert_true(
			is_equal_approx(state.pool_of(other), QUARTER - 50.0),
			"%s took the 150 remainder's third" % other
		)
	assert_true(is_equal_approx(state.hull, HULL_MAX - 400.0), "the hull dropped by the hit")
	_sum_holds(state, "after the spill")
	print("[s19] spill 400@0: prow=%.3f others=%.3f hull=%.3f" % [
		state.pool_of(&"prow"), state.pool_of(&"stern"), state.hull
	])

	var second := _fresh_state()
	second.set_shield(0.0)
	second.damage(300.0, false, {})
	var share := (300.0 - QUARTER) / 3.0
	for other: StringName in [&"stern", &"port", &"starboard"]:
		assert_true(
			is_equal_approx(second.pool_of(other), QUARTER - share),
			"a direction-less emptying hit spills the same way"
		)
	assert_true(is_equal_approx(second.hull, HULL_MAX - 300.0), "and drops the hull by 300")
	_sum_holds(second, "after the direction-less spill")


func test_the_hull_stays_the_sum_of_the_pools_through_hits_and_heals() -> void:
	var state := _fresh_state()
	state.set_shield(0.0)
	var steps: Array = [
		[420.0, true, 0.3],
		[180.0, true, -PI / 2.0],
		[QUARTER / PlayerStateScript.STERN_DAMAGE_MULT, true, PI],
		[260.0, true, 0.0],
	]
	for step: Array in steps:
		state.damage(float(step[0]), bool(step[1]), _ctx(float(step[2])))
		_sum_holds(state, "after a %s hit at %s" % [step[0], step[2]])
	assert_true(state.breached(&"stern"), "the rear hit emptied the stern")
	var before := state.hull
	state.set_hull(state.hull + 120.0)
	_sum_holds(state, "after a proportional heal")
	assert_true(state.hull > before, "the heal moved the hull")
	assert_true(state.breached(&"stern"), "and a heal cannot lift a breached pool off 0")
	assert_true(
		is_equal_approx(state.pool_of(&"prow"), state.pool_of(&"port")),
		"the heal scaled the intact pools together"
	)


func test_the_emptying_hit_drops_the_hull_and_died_fires_once() -> void:
	var state := _fresh_state()
	var deaths: Array[int] = []
	state.died.connect(func() -> void: deaths.append(1))
	state.set_shield(0.0)
	state.damage(HULL_MAX + 500.0, true, _ctx(0.0))
	assert_true(is_equal_approx(state.hull, 0.0), "an overkill drops the hull to 0")
	for quadrant: StringName in PlayerStateScript.QUADRANTS:
		assert_true(is_equal_approx(state.pool_of(quadrant), 0.0), "%s is empty" % quadrant)
	assert_eq(deaths.size(), 1, "died fires on the crossing to 0")
	state.damage(PROBE_HIT, true, {})
	assert_eq(deaths.size(), 1, "a second hit on a dead hull does not re-fire died")


func test_the_hull_signal_fires_once_per_landed_hit() -> void:
	var state := _fresh_state()
	var events: Array[float] = []
	state.hull_changed.connect(
		func(current: float, _maximum: float) -> void: events.append(current)
	)
	state.damage(PROBE_HIT, true, _ctx(0.0))
	assert_eq(events.size(), 1, "a hull hit announces once")
	assert_eq(events[0], HULL_MAX - PROBE_HIT, "with the pooled total")
	state.damage(PROBE_HIT, false, _ctx(PI / 2.0))
	assert_eq(events.size(), 1, "a shield-absorbed hit announces nothing on the hull channel")
	assert_true(is_equal_approx(state.shield, SHIELD_MAX - PROBE_HIT), "the shield moved instead")


## ---------------------------------------------------------------------------
## AC4 -- the breach malfunctions (P4/P5)
## ---------------------------------------------------------------------------


func test_the_stern_breach_drifts_on_the_pinned_cadence_and_sign() -> void:
	var state := _fresh_state()
	_breach(state, &"stern")
	var ship := _ship(state, Vector2(120.0, -40.0))
	ship.call(&"seed_breach_rolls", BREACH_SEED)
	var twin := RandomNumberGenerator.new()
	twin.seed = BREACH_SEED
	var peak := float(ship.call(&"_angular_inertia")) * float(ship.call(&"_spin_rate"))
	assert_gt(peak, 0.0, "the fixture resolves a hull moment and a spin rate")
	var expected := PlayerShipScript.BREACH_DRIFT_FRACTION * peak
	for frame: int in 7:
		ship.call(&"_physics_process", DRIFT_FRAME)
		assert_true(
			is_zero_approx(float(ship.call(&"applied_torque"))),
			"no drift before 2 s (frame %d)" % (frame + 1)
		)
	for index: int in 2:
		ship.call(&"_physics_process", DRIFT_FRAME)
		var sign := -1.0 if twin.randf() < 0.5 else 1.0
		var torque := float(ship.call(&"applied_torque"))
		assert_true(
			is_equal_approx(absf(torque), expected),
			"drift %d is 15 %% of the max turn torque (%.3f vs %.3f)"
				% [index + 1, absf(torque), expected]
		)
		assert_true(
			is_equal_approx(signf(torque), sign),
			"drift %d carries the seeded sign" % (index + 1)
		)
		print("[s19] drift %d @2.0s: torque=%.6f sign=%.0f peak=%.6f" % [
			index + 1, torque, signf(torque), peak
		])
		for quiet: int in 7:
			ship.call(&"_physics_process", DRIFT_FRAME)
			assert_true(
				is_zero_approx(float(ship.call(&"applied_torque"))),
				"the next drift waits its own 2 s"
			)


func test_a_full_hull_never_malfunctions() -> void:
	var ship := _ship(_fresh_state(), Vector2(240.0, 0.0))
	for frame: int in 16:
		ship.call(&"_physics_process", DRIFT_FRAME)
		assert_true(
			is_zero_approx(float(ship.call(&"applied_torque"))),
			"a fresh hull drifts nothing (frame %d)" % (frame + 1)
		)
	Input.action_press(THRUST_FORWARD)
	for frame: int in 20:
		ship.call(&"_physics_process", 1.0 / 60.0)
		assert_false(
			(ship.call(&"applied_force") as Vector2).is_zero_approx(),
			"a fresh hull's thrust lands every tick"
		)
	Input.action_release(THRUST_FORWARD)
	assert_eq(int(ship.call(&"flicker_ignores")), 0, "and it swallows none")


func test_the_prow_breach_swallows_the_seeded_share_of_thrust_ticks() -> void:
	var state := _fresh_state()
	_breach(state, &"prow")
	var ship := _ship(state, Vector2(0.0, 160.0))
	ship.call(&"seed_breach_rolls", BREACH_SEED)
	var twin := RandomNumberGenerator.new()
	twin.seed = BREACH_SEED
	## An idle stick is not a thrust application tick: it rolls nothing.
	for frame: int in 10:
		ship.call(&"_physics_process", 1.0 / 60.0)
	assert_eq(int(ship.call(&"flicker_ignores")), 0, "an idle stick rolls nothing")
	Input.action_press(THRUST_FORWARD)
	var expected := 0
	var observed := 0
	for frame: int in 200:
		ship.call(&"_physics_process", 1.0 / 60.0)
		if (ship.call(&"applied_force") as Vector2).is_zero_approx():
			observed += 1
		if twin.randf() < PlayerShipScript.BREACH_FLICKER_CHANCE:
			expected += 1
	Input.action_release(THRUST_FORWARD)
	assert_gt(expected, 0, "the seeded run ignores at least one tick")
	assert_eq(int(ship.call(&"flicker_ignores")), expected, "the hull swallowed the seeded share")
	assert_eq(observed, expected, "and every swallowed tick applied no thrust force")
	print("[s19] flicker seed=%d: swallowed=%d of 200 thrust ticks" % [BREACH_SEED, expected])


func test_a_breached_flank_clips_the_turn_towards_it() -> void:
	var healthy := _ship(_fresh_state(), Vector2.ZERO)
	var starboard_state := _fresh_state()
	_breach(starboard_state, &"starboard")
	var starboard := _ship(starboard_state, Vector2.ZERO)
	var port_state := _fresh_state()
	_breach(port_state, &"port")
	var port := _ship(port_state, Vector2.ZERO)
	var right := _turn_torque(healthy, TURN_RIGHT)
	var left := _turn_torque(healthy, TURN_LEFT)
	assert_true(
		is_equal_approx(_turn_torque(starboard, TURN_RIGHT), right * PlayerShipScript.BREACH_TURN_CLIP),
		"a starboard breach clips the turn towards it"
	)
	assert_true(
		is_equal_approx(_turn_torque(starboard, TURN_LEFT), left),
		"and the turn away keeps the class rate"
	)
	assert_true(
		is_equal_approx(_turn_torque(port, TURN_LEFT), left * PlayerShipScript.BREACH_TURN_CLIP),
		"a port breach clips the port turn"
	)
	assert_true(
		is_equal_approx(_turn_torque(port, TURN_RIGHT), right),
		"and its starboard turn keeps the class rate"
	)


func test_a_repair_clears_the_breach_and_its_malfunctions() -> void:
	var state := _fresh_state()
	_breach(state, &"stern")
	_breach(state, &"prow")
	var ship := _ship(state, Vector2(-120.0, 0.0))
	ship.call(&"seed_breach_rolls", BREACH_SEED)
	for frame: int in 8:
		ship.call(&"_physics_process", DRIFT_FRAME)
	assert_false(
		is_zero_approx(float(ship.call(&"applied_torque"))),
		"the stern breach drifts"
	)
	Input.action_press(THRUST_FORWARD)
	for frame: int in 40:
		ship.call(&"_physics_process", 1.0 / 60.0)
	Input.action_release(THRUST_FORWARD)
	var swallowed := int(ship.call(&"flicker_ignores"))
	assert_gt(swallowed, 0, "the prow breach flickers")
	## P8's restore, as the launch seeds it: the pools come back even and both effects,
	## being derived state, end with them.
	state.setup()
	assert_false(state.breached(&"stern"))
	assert_false(state.breached(&"prow"))
	ship.call(&"_physics_process", DRIFT_FRAME)
	for frame: int in 16:
		ship.call(&"_physics_process", DRIFT_FRAME)
		assert_true(
			is_zero_approx(float(ship.call(&"applied_torque"))),
			"a repaired pool drifts nothing (frame %d)" % (frame + 1)
		)
	Input.action_press(THRUST_FORWARD)
	for frame: int in 40:
		ship.call(&"_physics_process", 1.0 / 60.0)
	Input.action_release(THRUST_FORWARD)
	assert_eq(
		int(ship.call(&"flicker_ignores")),
		swallowed,
		"and a repaired prow swallows no further tick"
	)


## ---------------------------------------------------------------------------
## AC5 -- repairs and the two readouts
## ---------------------------------------------------------------------------


func test_a_repair_restores_the_pools_and_keeps_the_fee_law() -> void:
	var profile := _scratch_profile()
	profile.set_vitals(HULL, 200, 300)
	assert_eq(RepairsScript.fee(profile, HULL), 500, "(800 / 2) + (300 / 3)")
	var result: Dictionary = RepairsScript.repair(profile, HULL)
	assert_true(bool(result[&"ok"]))
	assert_eq(int(result[&"fee"]), 500, "the fee law is the same figure")
	assert_eq(profile.credits(), 9500, "exactly the fee is spent")
	assert_eq(int(result[&"hull_max"]), 1000, "the Vanguard's ceiling")
	print("[s19] repair fee=%d pools=%s" % [int(result[&"fee"]), str(result[&"pools"])])
	var pools: Array = result[&"pools"]
	assert_eq(pools.size(), 4, "the repair reports four pools")
	for value: float in pools:
		assert_true(is_equal_approx(value, QUARTER), "each pool is hull_max / 4")
	## The launch's half of the restore: the repaired sum seeds the four even pools (P1).
	var state := _fresh_state()
	state.set_hull(200.0)
	state.set_hull(float(result[&"hull_max"]))
	for quadrant: StringName in PlayerStateScript.QUADRANTS:
		assert_true(
			is_equal_approx(state.pool_of(quadrant), QUARTER),
			"%s is back at hull_max / 4" % quadrant
		)
		assert_false(state.breached(quadrant), "%s is no longer breached" % quadrant)


func test_the_repairs_report_lists_four_quadrant_lines() -> void:
	_install_profile()
	var stats: ShipStats = ShipFitScript.resolve(HULL, FIXTURE_FIT)
	var hull_max := int(round(stats.hull_max))
	var shield_max := int(round(stats.shield_max))
	var panel := _mount(RepairsPanelScene)
	assert_eq(_report_value(panel, &"hull"), "200 / %d" % hull_max, "the shipped hull row")
	assert_eq(_report_value(panel, &"shield"), "300 / %d" % shield_max, "the shipped shield row")
	assert_eq(
		_report_value(panel, &"missing"),
		"%d HULL · %d SHIELD" % [hull_max - 200, shield_max - 300],
		"the shipped missing row"
	)
	assert_eq(
		_report_value(panel, &"fee"),
		"%d CR" % RepairsScript.fee(_profile, HULL),
		"the shipped fee row, the service's own figure"
	)
	var expected := "50 / %d" % int(round(float(hull_max) / 4.0))
	var drawn: Array[String] = []
	for key: StringName in [&"prow", &"stern", &"port", &"starboard"]:
		assert_eq(_report_value(panel, key), expected, "the %s line" % key)
		drawn.append("%s %s" % [key, _report_value(panel, key)])
	print("[s19] repairs quadrant lines: %s" % ", ".join(drawn))
	var rows: Dictionary = panel.get(&"_values")
	for shipped: StringName in [&"hull_name", &"hull", &"shield", &"missing", &"fee"]:
		assert_true(rows.has(shipped), "the shipped %s row survives" % shipped)
	assert_eq(rows.size(), 9, "five shipped rows plus the four per-quadrant lines")


func test_the_status_screen_appends_four_pool_rows() -> void:
	_install_profile()
	var screen := StatusScreenScript.new() as Control
	screen.name = "S19StatusScreen"
	_pane_host.add_child(screen)
	screen.call(&"set_hull", HULL)
	screen.call(&"set_hull_slots", [])
	var fit_rows: Array = screen.call(&"module_rows")
	screen.call(&"set_pools", 812.0, HULL_MAX, 240.0, SHIELD_MAX)
	var fallback: Array = screen.call(&"pool_rows")
	assert_eq(fallback.size(), 4, "four pool rows")
	assert_eq(
		String(fallback[0][&"text"]),
		"PROW 203 / 250",
		"with no pool feed the row reads the even split of the hull figure (P1's launch seed)"
	)
	screen.call(&"set_quadrants", 100.0, 120.0, 130.0, 140.0)
	var rows: Array = screen.call(&"pool_rows")
	var texts: Array[String] = []
	for row: Dictionary in rows:
		texts.append(String(row[&"text"]))
	assert_eq(
		texts,
		["PROW 100 / 250", "STERN 120 / 250", "PORT 130 / 250", "STBD 140 / 250"],
		"the four pool rows read the pushed values against hull_max / 4"
	)
	print("[s19] status pool rows: %s" % ", ".join(texts))
	assert_eq(
		(screen.call(&"module_rows") as Array).size(),
		fit_rows.size(),
		"the fit rows did not move"
	)
	var footer: Dictionary = screen.call(&"footer_lines")
	assert_eq(String(footer[&"hull"]), "HULL 812 / 1000", "the shipped footer still reads")


## ---------------------------------------------------------------------------
## AC6 -- the const table and the forbidden files' seal
## ---------------------------------------------------------------------------


func test_the_pinned_consts_carry_the_amendment_values() -> void:
	assert_eq(PlayerStateScript.QUADRANT_COUNT, 4, "P1: four pools")
	assert_true(is_equal_approx(PlayerStateScript.PROW_ARC, PI / 4.0), "P2: the 45 degree prow")
	assert_true(is_equal_approx(PlayerStateScript.REAR_ARC, PI * 3.0 / 4.0), "P2: the 135 degree stern")
	assert_true(
		is_equal_approx(PlayerStateScript.STERN_VULN_ARC, PI * 5.0 / 9.0),
		"P3: the 160 degree rear arc"
	)
	assert_true(is_equal_approx(PlayerStateScript.STERN_DAMAGE_MULT, 1.6), "P3: x1.6")
	assert_true(
		is_equal_approx(PlayerShipScript.BREACH_DRIFT_FRACTION, 0.15),
		"P4: 15 percent of the max turn torque"
	)
	assert_true(is_equal_approx(PlayerShipScript.BREACH_DRIFT_INTERVAL, 2.0), "P4: every 2 s")
	assert_true(is_equal_approx(PlayerShipScript.BREACH_TURN_CLIP, 0.5), "P5: x0.5")
	assert_true(
		is_equal_approx(PlayerShipScript.BREACH_FLICKER_CHANCE, 0.15),
		"the prow roll: 15 percent of thrust ticks"
	)


func test_the_four_forbidden_files_are_byte_identical() -> void:
	for path: String in FORBIDDEN_FILES:
		assert_eq(
			FileAccess.get_sha256(path),
			FORBIDDEN_FILES[path],
			"%s is byte-identical" % path
		)


## ---------------------------------------------------------------------------
## Helpers
## ---------------------------------------------------------------------------


## One launched state, the fixture every AC1-AC3 row uses: the Vanguard ceiling, the
## four pools seeded full by `setup`.
func _fresh_state() -> PlayerState:
	var state: PlayerState = PlayerStateScript.new()
	state.hull_max = HULL_MAX
	state.shield_max = SHIELD_MAX
	state.setup()
	return state


func _ctx(direction: float) -> Dictionary:
	return {PlayerStateScript.CTX_DIRECTION: direction}


## Empty one quadrant through the shipped seam: a bypassing hit of exactly that pool's
## own size (the stern's divided by P3's multiplier, so the x1.6 lands it on the pool's
## face and spills nothing).
func _breach(state: PlayerState, quadrant: StringName) -> void:
	match quadrant:
		&"prow":
			state.damage(QUARTER, true, _ctx(0.0))
		&"stern":
			state.damage(QUARTER / PlayerStateScript.STERN_DAMAGE_MULT, true, _ctx(PI))
		&"port":
			state.damage(QUARTER, true, _ctx(-PI / 2.0))
		&"starboard":
			state.damage(QUARTER, true, _ctx(PI / 2.0))
	assert_true(
		state.breached(quadrant),
		"the %s fixture is breached (pool %.3f)" % [quadrant, state.pool_of(quadrant)]
	)


## One launched hull on the fixture host, aimed at its own position so the cursor law
## holds the heading and the only torque a row can read is the law's or a breach's.
func _ship(state: PlayerState, at: Vector2) -> Node2D:
	var stats: ShipStats = ShipFitScript.resolve(HULL, ShipFitScript.STANDARD_FIT)
	var ship := PlayerShipScene.instantiate() as Node2D
	_host().add_child(ship)
	ship.global_position = at
	ship.call(&"setup", stats, state, ShipFitScript.fitted_ids(ShipFitScript.STANDARD_FIT))
	ship.call(&"set_aim_point", at)
	_staged.append(ship)
	return ship


## One frame of a commanded turn: the action held for the step, the torque it applied
## read back, the stick released again.
func _turn_torque(ship: Node2D, action: StringName) -> float:
	Input.action_press(action)
	ship.call(&"_physics_process", 1.0 / 60.0)
	var torque := float(ship.call(&"applied_torque"))
	Input.action_release(action)
	return torque


func _sum_holds(state: PlayerState, label: String) -> void:
	var total := 0.0
	for quadrant: StringName in PlayerStateScript.QUADRANTS:
		var pool := state.pool_of(quadrant)
		assert_true(pool >= 0.0 and pool <= state.hull_max, "%s: %s is in range" % [label, quadrant])
		total += pool
	assert_true(
		is_equal_approx(total, state.hull),
		"%s: sum(pools) %.9f == hull %.9f" % [label, total, state.hull]
	)


## The panes' fixture: the active hull, its credits and the standard fit installed on
## the real autoload. The pre-install state is captured **once** -- the first install of
## the suite is the only one that may overwrite the snapshot -- so `suite_teardown` hands
## the account back exactly as this suite found it (the hygiene suite's reading depends on
## it) even though two tests install.
func _install_profile() -> void:
	if _profile == null:
		return
	if _saved.is_empty():
		_saved = {
			&"active": _profile.call(&"active_ship"),
			&"credits": int(_profile.call(&"credits")),
			&"fits": _profile.call(&"fits"),
			&"vitals": _profile.call(&"vitals_of", HULL),
		}
	_profile.set(&"_active_ship", HULL)
	_profile.set(&"_credits", 10000)
	_profile.call(&"set_fit", HULL, FIXTURE_FIT)
	_profile.call(&"set_vitals", HULL, 200, 300)


func _restore_profile() -> void:
	if _profile == null or _saved.is_empty():
		return
	_profile.set(&"_active_ship", _saved[&"active"])
	_profile.set(&"_credits", _saved[&"credits"])
	if _saved[&"fits"] is Dictionary:
		_profile.call(&"set_fits", _saved[&"fits"])
	var vitals: Variant = _saved[&"vitals"]
	if vitals is Dictionary and not (vitals as Dictionary).is_empty():
		var record: Dictionary = vitals
		_profile.call(
			&"set_vitals", HULL, int(record.get("hull", 0)), int(record.get("shield", 0))
		)
	_saved = {}


## A throwaway profile for the REPAIRS service, the `test_p1_repairs.gd` fixture: its
## own scratch save path, handed back when the suite is freed.
func _scratch_profile() -> Node:
	var profile := ProfileScript.new()
	profile.save_path = SCRATCH_PROFILE
	_staged.append(profile)
	return profile


func _mount(scene: PackedScene) -> Control:
	var node := scene.instantiate() as Control
	_pane_host.add_child(node)
	return node


func _report_value(panel: Control, key: StringName) -> String:
	var values: Dictionary = panel.get(&"_values")
	var label: Label = values.get(key)
	assert_true(label != null, "the report carries %s" % key)
	return "" if label == null else String(label.text)


## Where a fixture may enter the tree: the `PlayerProfile` autoload is already in it and
## takes children all through the run, whereas the root viewport is busy adding the
## runner scene during `_ready` (see `test_engine2_fixes.gd`).
func _host() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var root := tree.root
	var host := root.get_node_or_null(NodePath(PROFILE_SERVICE))
	return host if host != null else root


func _release_all() -> void:
	for action: StringName in ACTIONS:
		if InputMap.has_action(action):
			Input.action_release(action)


func _delete_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
