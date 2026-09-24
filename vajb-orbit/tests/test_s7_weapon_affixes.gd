@tool
extends McpTestSuite
## Suite s7_weapon_affixes: the launch + barrel half of the affix application
## (CONTRACTS section 20; 15 sections 3/9.3; 09 sections 3.1/5).
##
## Three surfaces, one suite.
##
## - **The per-barrel prefixes** (Keen, Rapid, Frugal) ride `PlayerState.weapon_affixes`,
##   one `{keen, rapid, frugal}` magnitude dict per weapon slot, built by the launch walk
##   from the profile's raw fit (K0 F8/F9). Each released barrel reads **its own cell's**
##   dict, so Keen in cell 2 leaves barrel 1 byte-identical, Rapid divides only that
##   barrel's interval, and Frugal's fractional bank spends exactly
##   `floor(shots x (1 + sum))` integer rounds (20 shots at -0.15 -> 17).
## - **`damage_mult` goes live**: every player-origin delivered amount passes it exactly
##   once, at the five sites K0 measured - the beam frame (`weapons.gd:_deliver`), the
##   beam chip (`weapons.gd:1233`), the projectile delivery (`projectile.gd:_deliver`),
##   the projectile chip (`projectile.gd:758`) and the ram (`player_ship.gd:929`) - with
##   a `c_target` (damage_add 0.15) computer fitted. Null stats resolve 1.0 (the eight
##   gate suites hand `Weapons.setup` null), and no computer is byte-identical.
## - **Embers** heals the player's shield by 10 % of what an NPC hull just took, on both
##   deliveries, clamped at `shield_max`, and never for a rock or the player's own hull.
##
## The launch bridge itself is measured on the shipped `game.tscn` off a borrowed
## `PlayerProfile` (its `save_path` repointed at a scratch file before the first
## mutation, every field handed back in `suite_teardown`, T-93/L17): the launch is what
## composes the summary and the per-slot dicts, so a hand-built rig cannot prove it.

const WeaponScript := preload("res://game/weapons.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const PlayerShipScript := preload("res://game/player_ship.gd")
const FitData := preload("res://game/ship_fit.gd")
const ImpactScript := preload("res://game/impact.gd")
const GameScene := preload("res://game/game.tscn")

const VANGUARD: StringName = &"ship_vanguard"
const TARGETING: StringName = &"c_target"
const LASER: StringName = &"w_laser"
const CANNON: StringName = &"w_cannon"
const CANNON_FAMILY: StringName = &"cannon"
const AFTERBURNER: StringName = &"b_afterburner"

const AUDIO_SERVICE: StringName = &"AudioManager"

const SCRATCH_PROFILE := "user://test_s7_weapon_affixes.cfg"

## One delivered weapon amount, recorded as a number rather than read off the pipeline.
## `take_damage(amount, bypass)` is the pinned two-argument shape `_deliver` calls; the
## node is put in whatever ship/rock group the test's predicate needs.
class DamageSink extends Node2D:
	var total := 0.0
	var hits := 0


	func take_damage(amount: float, _bypass_shield := false) -> void:
		total += amount
		hits += 1


## A rock's chip work (section 6): the sink a gun's `apply_work` lands on.
class WorkRock extends Node2D:
	var work := 0.0
	var calls := 0


	func apply_work(amount: float) -> void:
		work += amount
		calls += 1


## The peer's half of a ram: `PlayerShip._on_hull_body_entered` offers it
## `apply_collision_damage`, and section 20's site 5 is the one place `damage_mult`
## lands on that figure.
class RamPeer extends RigidBody2D:
	var amount := 0.0
	var calls := 0


	func apply_collision_damage(value: float) -> void:
		amount += value
		calls += 1


## A battery whose beam resolves on a target without a physics world: the shipped
## `_beam_target` resolves through a ray query, so this double replaces the **targeting
## seam only** - the arming, the per-barrel spend, the Keen-weighted damage sum and the
## delivery are the shipped code's.
class BeamTargetSpy extends "res://game/weapons.gd":
	var target: Node2D = null


	func _beam_target(from: Vector2, _to: Vector2) -> Dictionary:
		if target == null or not is_instance_valid(target):
			return {}
		return {
			&"point": target.global_position,
			&"collider": target,
			&"distance": from.distance_to(target.global_position),
			&"projectile": false,
		}


var _profile: Node = null
var _scene: Node2D = null
var _state: PlayerState = null
var _guns: Node2D = null
var _holder: Node2D = null
var _staged: Array[Node] = []
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_fits: Dictionary = {}
var _previous_owned: Array = []
var _previous_modules: Dictionary = {}
## The audio pools' round-robin cursors, saved and restored around every test: the beam
## rig fires real cues (the opening take and the bed), and `test_weapon_fx_f1.gd` asserts
## the laser pool's take order a few suites later - a cue this suite leaves spent would
## move that suite's first take (the same hygiene `test_engine2_weapons.gd` documents).
var _pool_state: Dictionary = {}
var _had_pool_state := false


func suite_name() -> String:
	return "s7_weapon_affixes"


func suite_setup(_ctx: Dictionary) -> void:
	var tree := _tree()
	if tree == null:
		fail_setup("a SceneTree is needed")
		return
	_profile = tree.root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		fail_setup("the PlayerProfile autoload is the launch's store")
		return
	_previous_path = String(_profile.get(&"save_path"))
	_previous_ship = StringName(_profile.call(&"active_ship"))
	_previous_fits = _profile.call(&"fits")
	_previous_owned = _profile.call(&"owned_ships")
	_previous_modules = _profile.call(&"modules")
	_profile.set(&"save_path", SCRATCH_PROFILE)
	_delete_file(SCRATCH_PROFILE)


func suite_teardown() -> void:
	_free_scene()
	if _profile == null:
		return
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_fits", _previous_fits)
	_profile.set(&"_owned_ships", _previous_owned)
	_profile.set(&"_modules", _previous_modules)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	_delete_file(SCRATCH_PROFILE)
	_profile = null


func setup() -> void:
	_save_pools()
	_state = PlayerStateScript.new()


func teardown() -> void:
	_free_scene()
	if _guns != null and is_instance_valid(_guns):
		_guns.free()
	_guns = null
	for node: Node in _staged:
		if is_instance_valid(node):
			node.free()
	_staged.clear()
	_clear_shots()
	_state = null
	_restore_pools()


func _audio() -> Node:
	var tree := _tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null(NodePath(AUDIO_SERVICE))


func _save_pools() -> void:
	_pool_state = {}
	_had_pool_state = false
	var audio := _audio()
	if audio == null:
		return
	var cursors: Variant = audio.get(&"_pool_next")
	if not cursors is Dictionary:
		return
	_had_pool_state = true
	_pool_state = (cursors as Dictionary).duplicate()


## `Object.get` hands the live dictionary, so the cursors are restored in place.
func _restore_pools() -> void:
	if not _had_pool_state:
		return
	var audio := _audio()
	if audio == null:
		return
	var cursors: Variant = audio.get(&"_pool_next")
	if not cursors is Dictionary:
		return
	var live := cursors as Dictionary
	live.clear()
	live.merge(_pool_state, true)
	_pool_state = {}
	_had_pool_state = false


## ---------------------------------------------------------------------------
## The launch bridge: the summary into `resolve`, the per-slot dicts into the state
## ---------------------------------------------------------------------------


## The launch hands `ShipFit.resolve` the profile's summary and `PlayerState` the
## per-slot affix dicts built by the **same walk** `set_weapons` took (CONTRACTS
## section 20, K0 F8/F9). A Vanguard whose one W cell holds a rolled `w_laser` with
## Keen 0.15 and Embers must launch with slot 0 carrying Keen and the state carrying
## the flag, and the scene must keep the summary K3's seams will read.
func test_the_launch_hands_the_summary_the_slot_affixes_and_the_flags() -> void:
	var fit := _rolled_fit(VANGUARD, LASER, [{&"id": &"keen", &"value": 0.15}], [&"embers"])
	var scene := _launch(VANGUARD, fit)
	if scene == null:
		return
	var state: Variant = scene.get(&"_state")
	var affixes: Variant = state.get(&"weapon_affixes")
	assert_true(affixes is Array, "the launch wrote a per-slot affix list")
	var list: Array = affixes
	assert_eq(list.size(), 1, "one entry per fitted weapon slot")
	var slot: Dictionary = list[0]
	assert_true(_near(float(slot.get(&"keen", 0.0)), 0.15), "and Keen rides that slot")
	var flags: Variant = state.get(&"affix_flags")
	assert_true(flags is Array and (flags as Array).has(&"embers"), "the suffix flag is set")
	var summary: Variant = scene.get(&"_launch_summary")
	assert_true(summary is Dictionary and not (summary as Dictionary).is_empty(), "the summary is kept")
	## The summary and the state are the same launch fact: the row the slot dict came
	## from is in the summary the scene stored.
	var rows: Array = (summary as Dictionary).get(&"instances", [])
	assert_eq(rows.size(), 1, "one instance row")
	var stats: Variant = scene.get(&"_stats")
	assert_true(_near(float(stats.get(&"damage_mult")), 1.0), "no computer, no multiplier")


## The bank is flight state seeded empty at every launch/seed point (CONTRACTS section
## 20): `set_weapons` and `setup` both re-size it to zeros.
func test_the_frugal_bank_is_seeded_empty_by_every_sizing_point() -> void:
	_state.set_weapons([&"cannon"])
	_state.setup()
	assert_eq(_state.ammo_frac.size(), 1, "one bank entry per slot")
	_state.ammo_frac[0] = 0.75
	_state.setup()
	assert_true(_near(_state.ammo_frac[0], 0.0), "setup re-seeds the bank empty")
	_state.ammo_frac[0] = 0.75
	_state.set_weapons([&"cannon"])
	assert_true(_near(_state.ammo_frac[0], 0.0), "so does set_weapons")


## ---------------------------------------------------------------------------
## Keen: per barrel, at shot composition (travelling) and in the frame weight (beam)
## ---------------------------------------------------------------------------


## Keen scales **that barrel's** shot damage at composition, so a two-cannon battery
## with Keen only in cell 2 leaves barrel 1's shot byte-identical (AC3).
func test_keen_scales_only_its_own_barrels_shot_damage() -> void:
	_two_barrel_state()
	var guns := _rig([CANNON, CANNON])
	if guns == null:
		return
	var row: Dictionary = WeaponScript.row_of(CANNON_FAMILY)
	var base := WeaponScript.shot_damage(CANNON_FAMILY)
	var shot_one := _spawn(guns, CANNON_FAMILY, row, 0)
	var shot_two := _spawn(guns, CANNON_FAMILY, row, 1)
	assert_true(_near(shot_one.call(&"damage_amount"), base), "no affix: barrel 1 is today's shot")
	assert_true(_near(shot_two.call(&"damage_amount"), base), "and barrel 2 with it")
	_set_affixes([{}, {&"keen": 0.15}])
	shot_one = _spawn(guns, CANNON_FAMILY, row, 0)
	shot_two = _spawn(guns, CANNON_FAMILY, row, 1)
	assert_true(
		_near(shot_one.call(&"damage_amount"), base),
		"Keen in cell 2 leaves barrel 1 byte-identical (%.6f)" % float(shot_one.call(&"damage_amount"))
	)
	assert_true(
		_near(shot_two.call(&"damage_amount"), base * 1.15),
		"and scales barrel 2 by 1 + sum(keen) (%.6f)" % float(shot_two.call(&"damage_amount"))
	)
	## The mirror: Keen in cell 1 scales barrel 1 and leaves barrel 2 alone.
	_set_affixes([{&"keen": 0.15}, {}])
	assert_true(
		_near(_spawn(guns, CANNON_FAMILY, row, 0).call(&"damage_amount"), base * 1.15), "cell 1's Keen"
	)
	assert_true(
		_near(_spawn(guns, CANNON_FAMILY, row, 1).call(&"damage_amount"), base), "leaves barrel 2"
	)


## The beam's frame is the paid barrels' **summed Keen weight** (K0 F11): a two-laser
## rack with Keen only in cell 2 deals `(1 + 1.15) x dps x delta`, and the affix-free
## rack still deals exactly `2 x dps x delta` (the pinned `test_engine2_weapons:600` row).
func test_keen_weights_the_beam_frame_per_barrel() -> void:
	_state.set_weapons([&"laser", &"laser"])
	_state.setup()
	var sink := DamageSink.new()
	_staged.append(sink)
	var delta := 0.1
	var guns := _beam_rig([LASER, LASER], sink)
	if guns == null:
		return
	guns.call(&"set_firing", true)
	guns.call(&"tick", delta)
	var base := WeaponScript.dps_of(&"laser") * delta
	assert_true(
		_near(sink.total, base * 2.0),
		"no affix: two barrels deal 2 x dps x delta (%.6f)" % sink.total
	)
	guns.call(&"set_firing", false)
	guns.call(&"tick", delta)
	sink.total = 0.0
	_set_affixes([{}, {&"keen": 0.15}])
	guns.call(&"set_firing", true)
	guns.call(&"tick", delta)
	assert_true(
		_near(sink.total, base * 2.15),
		"cell 2 Keen weights the frame by 1 + 1.15 (%.6f, expected %.6f)" % [sink.total, base * 2.15]
	)
	guns.call(&"set_firing", false)
	guns.call(&"tick", delta)


## ---------------------------------------------------------------------------
## Rapid: that barrel's release interval only
## ---------------------------------------------------------------------------


## Rapid divides **that barrel's** interval (CONTRACTS section 20): cell 2's cannon
## cycles at `interval / 1.15` while cell 1 keeps the family cadence, both on the
## `_barrel_interval` read and on the timer a released shot arms.
func test_rapid_shortens_only_its_own_barrels_interval() -> void:
	_two_barrel_state()
	var guns := _rig([CANNON, CANNON])
	if guns == null:
		return
	var base := WeaponScript.interval_of(CANNON_FAMILY)
	assert_true(_near(guns.call(&"_barrel_interval", 0), base), "no affix: barrel 1's cadence")
	assert_true(_near(guns.call(&"_barrel_interval", 1), base), "and barrel 2's")
	_set_affixes([{}, {&"rapid": 0.15}])
	assert_true(
		_near(guns.call(&"_barrel_interval", 0), base),
		"Rapid in cell 2 leaves barrel 1 byte-identical"
	)
	assert_true(
		_near(guns.call(&"_barrel_interval", 1), base / 1.15),
		"and divides barrel 2's interval by 1 + sum(rapid) (%.6f)" % float(guns.call(&"_barrel_interval", 1))
	)
	_state.set_ammo(0, 30)
	_state.set_ammo(1, 30)
	var timers: Array = guns.get(&"_barrel_timers")
	guns.call(&"_fire_projectile", 0, CANNON_FAMILY, WeaponScript.row_of(CANNON_FAMILY))
	guns.call(&"_fire_projectile", 1, CANNON_FAMILY, WeaponScript.row_of(CANNON_FAMILY))
	assert_true(_near(timers[0], base), "the released barrel 1 re-arms on the family cadence")
	assert_true(_near(timers[1], base / 1.15), "while barrel 2's timer is the Rapid interval")


## ---------------------------------------------------------------------------
## Frugal: the fractional bank
## ---------------------------------------------------------------------------


## Frugal's per-shot cost is `1 x (1 + sum)`, the bank accumulates it and an integer
## round leaves only when it crosses 1 (CONTRACTS section 20): 20 shots at -0.15 spend
## exactly `floor(20 x 0.85) = 17` rounds, and the affix-free case still spends 20.
func test_frugal_spends_exactly_floor_of_the_fractional_bank() -> void:
	_one_barrel_state()
	var per: Array[Dictionary] = []
	per.append({&"frugal": -0.15})
	_state.set_weapon_affixes(per)
	var guns := _rig([CANNON])
	if guns == null:
		return
	_state.set_ammo(0, 300)
	for _shot in 20:
		guns.call(&"_consume_ammo_at", 0, CANNON_FAMILY)
	assert_eq(_state.ammo[0], 283, "20 shots at -0.15 spend exactly 17 rounds")
	assert_true(_near(_state.ammo_frac[0], 0.0), "and the bank lands on zero")
	print(
		"[s7-affixes] frugal: 20 shots at -0.15 spent %d rounds (bank %.6f)"
		% [300 - int(_state.ammo[0]), _state.ammo_frac[0]]
	)


## Without a Frugal magnitude a barrel spends through the shipped family resolution
## (`ammo_slot`), so nothing in this wave moves an un-affixed battery's rounds.
func test_a_non_frugal_barrel_keeps_the_shipped_family_spend() -> void:
	_state.set_weapons(PlayerStateScript.WEAPONS)
	_state.setup()
	_set_affixes([{}])
	var guns := _rig([CANNON])
	if guns == null:
		return
	var slot := WeaponScript.ammo_slot(CANNON_FAMILY)
	_state.set_ammo(slot, 300)
	for _shot in 20:
		guns.call(&"_consume_ammo_at", 0, CANNON_FAMILY)
	assert_eq(_state.ammo[slot], 280, "no Frugal spends one round per shot from the family pack")


## The bank is per barrel **slot** and the round leaves that slot's pack: two cannon
## cells each bank their own fraction (CONTRACTS section 20 / K0 F10).
func test_frugal_banks_are_per_slot() -> void:
	_two_barrel_state()
	_set_affixes([{&"frugal": -0.15}, {}])
	var guns := _rig([CANNON, CANNON])
	if guns == null:
		return
	_state.set_ammo(0, 300)
	_state.set_ammo(1, 300)
	for _shot in 10:
		guns.call(&"_consume_ammo_at", 0, CANNON_FAMILY)
		guns.call(&"_consume_ammo_at", 1, CANNON_FAMILY)
	assert_eq(_state.ammo[0], 300 - 8, "cell 1's bank spent floor(10 x 0.85) = 8")
	assert_eq(_state.ammo[1], 300 - 10, "cell 2 has no Frugal and spends its own 10")


## ---------------------------------------------------------------------------
## damage_mult: five sites, once each, null-tolerant
## ---------------------------------------------------------------------------


## The launch snapshot with a `c_target` (damage_add 0.15) computer fitted: the
## computers' pinned +damage resolves to `damage_mult` 1.15, the multiplier that used to
## be inert (CONTRACTS section 20's measured defect).
func test_a_targeting_computer_resolves_a_fifteen_percent_multiplier() -> void:
	var stats := _computer_stats()
	assert_true(_near(stats.damage_mult, 1.15), "c_target's 0.15 resolves to 1.15")
	assert_true(_near(_computerless_stats().damage_mult, 1.0), "no computer stays 1.0")


## Site 1, the beam's hull delivery: the frame's amount is multiplied once at
## `weapons.gd:_deliver`, and an affix-free (or null-stats) setup is byte-identical.
func test_damage_mult_lands_once_on_the_beam_delivery() -> void:
	var delta := 0.1
	var base := WeaponScript.dps_of(&"laser") * delta
	var sink := DamageSink.new()
	_staged.append(sink)
	var guns := _rig([LASER], _computer_stats())
	guns.call(&"_apply_beam", &"laser", WeaponScript.row_of(&"laser"), sink, Vector2.ZERO, delta, 1.0)
	assert_true(
		_near(sink.total, base * 1.15),
		"one beam frame x1.15 (%.6f, expected %.6f)" % [sink.total, base * 1.15]
	)
	assert_eq(sink.hits, 1, "and the frame is still one delivery")
	## Null stats: the shipped `Weapons.setup` contract, a no-op multiplier, no crash.
	var null_sink := DamageSink.new()
	_staged.append(null_sink)
	var null_guns := _rig([LASER], null)
	null_guns.call(
		&"_apply_beam", &"laser", WeaponScript.row_of(&"laser"), null_sink, Vector2.ZERO, delta, 1.0
	)
	assert_true(_near(null_sink.total, base), "null stats deliver the un-multiplied amount")


## Site 2, the beam's rock chip: `amount x GUN_CHIP_RATE x damage_mult`, once.
func test_damage_mult_lands_once_on_the_beam_chip() -> void:
	var delta := 0.1
	var base := WeaponScript.dps_of(&"laser") * delta
	var rock := WorkRock.new()
	rock.add_to_group(ProjectileScript.ROCK_GROUP)
	_staged.append(rock)
	var guns := _rig([LASER], _computer_stats())
	guns.call(&"_apply_beam", &"laser", WeaponScript.row_of(&"laser"), rock, Vector2.ZERO, delta, 1.0)
	assert_true(
		_near(rock.work, base * WeaponScript.GUN_CHIP_RATE * 1.15),
		"beam chip x1.15 (%.6f, expected %.6f)"
		% [rock.work, base * WeaponScript.GUN_CHIP_RATE * 1.15]
	)
	assert_eq(rock.calls, 1, "one chip call")


## Site 3, the projectile's hull delivery: the shot carries `damage_mult` in its
## configure dict (K0 F2) and `projectile.gd:_deliver` applies it once, no more.
func test_damage_mult_lands_once_on_the_projectile_delivery() -> void:
	var sink := DamageSink.new()
	_staged.append(sink)
	var shot := _shot({&"kind": &"bolt", &"damage": 100.0, &"damage_mult": 1.15})
	shot.call(&"_deliver", sink, 100.0, false, Vector2.ZERO, Vector2.ZERO)
	assert_true(_near(sink.total, 115.0), "one bolt x1.15 (%.6f)" % sink.total)
	assert_eq(sink.hits, 1, "one delivery")
	var plain := DamageSink.new()
	_staged.append(plain)
	_shot({&"kind": &"bolt", &"damage": 100.0}).call(
		&"_deliver", plain, 100.0, false, Vector2.ZERO, Vector2.ZERO
	)
	assert_true(_near(plain.total, 100.0), "no damage_mult key is today's 100.0")


## Site 4, the projectile's rock chip: `damage x chip x damage_mult`, once.
func test_damage_mult_lands_once_on_the_projectile_chip() -> void:
	var rock := WorkRock.new()
	rock.add_to_group(ProjectileScript.ROCK_GROUP)
	_staged.append(rock)
	var shot := _shot({&"kind": &"bolt", &"damage": 100.0, &"chip": 0.10, &"damage_mult": 1.15})
	shot.call(&"_hit_rock", rock, Vector2.ZERO)
	assert_true(_near(rock.work, 100.0 * 0.10 * 1.15), "projectile chip x1.15 (%.6f)" % rock.work)
	assert_eq(rock.calls, 1, "one chip call")
	var plain := WorkRock.new()
	plain.add_to_group(ProjectileScript.ROCK_GROUP)
	_staged.append(plain)
	_shot({&"kind": &"bolt", &"damage": 100.0, &"chip": 0.10}).call(
		&"_hit_rock", plain, Vector2.ZERO
	)
	assert_true(_near(plain.work, 10.0), "no damage_mult key is today's 10.0")


## Site 5, the ram: the peer's half takes the multiplier exactly once
## (`player_ship.gd:929`), and the player's own half is untouched by it.
func test_damage_mult_lands_once_on_the_ram() -> void:
	var peer := RamPeer.new()
	peer.mass = 5.0
	peer.global_position = Vector2(20.0, 0.0)
	_staged.append(peer)
	var stats := _computer_stats()
	var base := ImpactScript.collision_damage(110.0, 5.0, 100.0)
	var ship := _ram_ship(stats)
	ship.call(&"_on_hull_body_entered", peer)
	assert_eq(peer.calls, 1, "one ram offers the peer one amount")
	assert_true(
		_near(peer.amount, base * 1.15),
		"the peer's half x1.15 (%.6f, expected %.6f)" % [peer.amount, base * 1.15]
	)
	## No computer: byte-identical.
	var plain_peer := RamPeer.new()
	plain_peer.mass = 5.0
	plain_peer.global_position = Vector2(20.0, 0.0)
	_staged.append(plain_peer)
	var plain_ship := _ram_ship(_computerless_stats())
	plain_ship.call(&"_on_hull_body_entered", plain_peer)
	assert_true(_near(plain_peer.amount, base), "no computer ram is today's figure")


## ---------------------------------------------------------------------------
## Embers: an NPC sink only, both deliveries, clamped
## ---------------------------------------------------------------------------


## The beam delivery heals 10 % of the dealt amount when the sink is an NPC hull,
## reads the flag off `PlayerState.affix_flags`, and clamps at `shield_max`.
func test_embers_heals_the_beam_delivery_on_an_npc_sink_only() -> void:
	_state.setup()
	_state.set_affix_flags(_flags([&"embers"]))
	_state.set_shield(100.0)
	var npc := _sink_in([&"npc_ship"])
	var guns := _rig([LASER], null)
	guns.call(&"_deliver", npc, 200.0, false, Vector2.ZERO, &"energy", Vector2.ZERO)
	assert_true(_near(_state.shield, 120.0), "beam Embers heals 10 %% of 200 (%.3f)" % _state.shield)
	## A rock is excluded (K0 F7): its sink answers no ship group.
	_state.set_shield(100.0)
	var rock := WorkRock.new()
	rock.add_to_group(ProjectileScript.ROCK_GROUP)
	_staged.append(rock)
	guns.call(&"_deliver", rock, 200.0, false, Vector2.ZERO, &"energy", Vector2.ZERO)
	assert_true(_near(_state.shield, 100.0), "a rock heals nothing")
	## The player's own hull is excluded too.
	_state.set_shield(100.0)
	var own := _sink_in([&"player_ship"])
	guns.call(&"_deliver", own, 200.0, false, Vector2.ZERO, &"energy", Vector2.ZERO)
	assert_true(_near(_state.shield, 100.0), "the player's own hull heals nothing")
	## The clamp: 595 + 20 would be 615, held at shield_max.
	_state.set_shield(_state.shield_max - 5.0)
	guns.call(&"_deliver", npc, 200.0, false, Vector2.ZERO, &"energy", Vector2.ZERO)
	assert_true(_near(_state.shield, _state.shield_max), "the heal clamps at shield_max")


## Without the flag nothing heals, on either delivery.
func test_embers_without_the_flag_is_a_no_op() -> void:
	_state.setup()
	_state.set_shield(100.0)
	var npc := _sink_in([&"npc_ship"])
	var guns := _rig([LASER], null)
	guns.call(&"_deliver", npc, 200.0, false, Vector2.ZERO, &"energy", Vector2.ZERO)
	assert_true(_near(_state.shield, 100.0), "no flags, no heal (beam)")
	var shot := _shot({&"kind": &"bolt", &"damage": 200.0})
	shot.call(&"_deliver", npc, 200.0, false, Vector2.ZERO, Vector2.ZERO)
	assert_true(_near(_state.shield, 100.0), "no flags, no heal (projectile)")


## The projectile delivery heals through `PlayerShip.heal_from_damage` on its
## `_source`: an NPC sink heals, a rock does not, a source with no state is a no-op.
func test_embers_heals_the_projectile_delivery_through_the_source() -> void:
	_state.setup()
	_state.set_shield(100.0)
	var ship := PlayerShipScript.new()
	ship.set(&"_state", _state)
	_staged.append(ship)
	var npc := _sink_in([&"npc_ship"])
	var shot := _shot({&"kind": &"bolt", &"damage": 200.0, &"embers": true, &"source": ship})
	shot.call(&"_deliver", npc, 200.0, false, Vector2.ZERO, Vector2.ZERO)
	assert_true(_near(_state.shield, 120.0), "projectile Embers heals 10 %% (%.3f)" % _state.shield)
	## A rock sink is excluded.
	_state.set_shield(100.0)
	var rock := WorkRock.new()
	rock.add_to_group(ProjectileScript.ROCK_GROUP)
	_staged.append(rock)
	shot.call(&"_deliver", rock, 200.0, false, Vector2.ZERO, Vector2.ZERO)
	assert_true(_near(_state.shield, 100.0), "a rock heals nothing on the projectile path")
	## No source: the seam is a no-op, never a crash.
	_state.set_shield(100.0)
	var sourceless := _shot({&"kind": &"bolt", &"damage": 200.0, &"embers": true})
	sourceless.call(&"_deliver", npc, 200.0, false, Vector2.ZERO, Vector2.ZERO)
	assert_true(_near(_state.shield, 100.0), "no source, no heal")
	## A ship with no state is a no-op too.
	var bare := PlayerShipScript.new()
	_staged.append(bare)
	var bare_shot := _shot({&"kind": &"bolt", &"damage": 200.0, &"embers": true, &"source": bare})
	bare_shot.call(&"_deliver", npc, 200.0, false, Vector2.ZERO, Vector2.ZERO)
	assert_true(_near(_state.shield, 100.0), "a source with no state heals nothing")


## The clamp on the projectile path too.
func test_embers_clamps_on_the_projectile_path() -> void:
	_state.setup()
	_state.set_shield(_state.shield_max - 5.0)
	var ship := PlayerShipScript.new()
	ship.set(&"_state", _state)
	_staged.append(ship)
	var npc := _sink_in([&"npc_ship"])
	var shot := _shot({&"kind": &"bolt", &"damage": 200.0, &"embers": true, &"source": ship})
	shot.call(&"_deliver", npc, 200.0, false, Vector2.ZERO, Vector2.ZERO)
	assert_true(_near(_state.shield, _state.shield_max), "the projectile heal clamps at shield_max")


## ---------------------------------------------------------------------------
## Spry: the afterburner's cooldown
## ---------------------------------------------------------------------------


## Spry's aggregate lands on `ShipStats.booster_cooldown_mult` and the hull's afterburner
## line multiplies the row's 8.0 s cooldown by it (CONTRACTS section 20): -0.15 -> 6.8 s.
func test_spry_shortens_the_afterburner_cooldown() -> void:
	var stats := FitData.resolve(VANGUARD, {&"boosters": [AFTERBURNER]}, {&"spry": -0.15})
	assert_true(_near(stats.booster_cooldown_mult, 0.85), "Spry -0.15 resolves to 0.85")
	var ship := PlayerShipScript.new()
	ship.set(&"_stats", stats)
	ship.set(&"_state", _state)
	_staged.append(ship)
	assert_true(_near(ship.call(&"_booster_cooldown_scale"), 0.85), "the hull reads the field")
	var row: Dictionary = FitData.MODULES[AFTERBURNER][&"effects"]
	assert_true(_near(float(row.get(&"cooldown", 0.0)), 8.0), "the afterburner's row states 8.0 s")
	assert_true(
		_near(float(row.get(&"cooldown", 0.0)) * float(ship.call(&"_booster_cooldown_scale")), 6.8),
		"8.0 x 0.85 = 6.8"
	)
	## And the line itself, driven through the real action state: a press arms the burner
	## and the cooldown it writes is the row's 8.0 s x Spry's 0.85.
	Input.action_press(PlayerShipScript.BOOST_ACTION)
	ship.call(&"_update_boosters", 0.0)
	Input.action_release(PlayerShipScript.BOOST_ACTION)
	assert_true(
		_near(float(ship.get(&"_boost_cooldown")), 6.8),
		"the afterburner's cooldown line writes 6.8 s (%.6f)" % float(ship.get(&"_boost_cooldown"))
	)
	## No Spry: 1.0, byte-identical.
	var plain := PlayerShipScript.new()
	plain.set(&"_stats", FitData.resolve(VANGUARD, {&"boosters": [AFTERBURNER]}))
	plain.set(&"_state", _state)
	_staged.append(plain)
	assert_true(_near(plain.call(&"_booster_cooldown_scale"), 1.0), "no booster affix stays 1.0")


## ---------------------------------------------------------------------------
## Rigs and helpers
## ---------------------------------------------------------------------------


## The two-cannon state the per-barrel tests share: the launched weapons list the
## component's barrels align against, sized and seeded by `setup`.
func _two_barrel_state() -> void:
	_state.set_weapons([CANNON_FAMILY, CANNON_FAMILY])
	_state.setup()


func _one_barrel_state() -> void:
	_state.set_weapons([CANNON_FAMILY])
	_state.setup()


## The per-slot affix list out of an untyped fixture array (`{}` per cell the list
## leaves out), sized to the state's own weapons list by `set_weapon_affixes`.
func _set_affixes(cells: Array) -> void:
	var per: Array[Dictionary] = []
	for cell: Variant in cells:
		per.append((cell as Dictionary) if cell is Dictionary else {})
	_state.set_weapon_affixes(per)


func _flags(ids: Array) -> Array[StringName]:
	var out: Array[StringName] = []
	for id: Variant in ids:
		out.append(StringName(str(id)))
	return out


## A component on a fit of `ids`, hosted in the tree (a travelling test spawns shots
## and a beam test plays its flash). `stats` may be null, which is the shipped
## eight-suite convention.
func _rig(ids: Array, stats: ShipStats = null, spy := false) -> Node2D:
	var host := _fixture_host()
	if host == null:
		skip("no PlayerProfile autoload to host the rig")
		return null
	_holder = Node2D.new()
	_holder.name = "S7AffixRig"
	host.add_child(_holder)
	_guns = (BeamTargetSpy.new() if spy else WeaponScript.new()) as Node2D
	_holder.add_child(_guns)
	_guns.call(&"setup", stats, _state)
	var fit: Array[StringName] = []
	for id: Variant in ids:
		fit.append(StringName(id))
	_guns.call(&"set_fitted", fit)
	_staged.append(_holder)
	return _guns


## A laser rack aimed at a `DamageSink`, hosted in the tree so the beam's own arming,
## weighting and delivery run.
func _beam_rig(ids: Array, target: Node2D) -> Node2D:
	var guns := _rig(ids, null, true)
	if guns == null:
		return null
	guns.set(&"target", target)
	guns.call(&"set_aim_point", Vector2(400.0, 0.0))
	return guns


func _spawn(guns: Node2D, weapon: StringName, row: Dictionary, position: int) -> Node2D:
	var shot := guns.call(&"_spawn_shot", weapon, row, Vector2.RIGHT, position) as Node2D
	if shot != null:
		_staged.append(shot)
	return shot


## A projectile configured with the given keys, staged for teardown.
func _shot(config: Dictionary) -> Node2D:
	var shot := ProjectileScript.new() as Node2D
	shot.call(&"configure", config)
	_staged.append(shot)
	return shot


func _sink_in(groups: Array) -> DamageSink:
	var sink := DamageSink.new()
	for group: Variant in groups:
		sink.add_to_group(StringName(str(group)))
	_staged.append(sink)
	return sink


## A bare hull for the ram's site: the state takes the player's half, the snapshot
## supplies the mass and the multiplier, and `_last_velocity` is the closing speed the
## peer's half is computed from.
func _ram_ship(stats: ShipStats) -> Node2D:
	var ship := PlayerShipScript.new() as Node2D
	_state.setup()
	ship.set(&"_state", _state)
	ship.set(&"_stats", stats)
	ship.set(&"_last_velocity", Vector2(100.0, 0.0))
	_staged.append(ship)
	return ship


func _computer_stats() -> ShipStats:
	return FitData.resolve(VANGUARD, {&"weapons": [LASER], &"computers": [TARGETING]})


func _computerless_stats() -> ShipStats:
	return FitData.resolve(VANGUARD, {&"weapons": [LASER]})


## One hull's fit whose first W cell holds a rolled instance of `base_id` carrying
## `prefixes`/`suffixes` (CONTRACTS section 15: fitting is `count` 1 -> 0). Returns the
## fit-shaped dictionary `set_fit` takes; `_profile` must be borrowed first.
func _rolled_fit(
	hull: StringName, base_id: StringName, prefixes: Array, suffixes: Array
) -> Dictionary:
	var id: StringName = _profile.call(&"add_instance", base_id, &"rare", prefixes, suffixes)
	_profile.call(&"take_instance", id)
	return {&"weapons": [id]}


## Launch one hull on one stored fit: the test writes the profile (the launch's own
## source), then instantiates the shipped flight scene, so the affix bridge, the seed
## and the handshake are the scene's own.
func _launch(hull_id: StringName, fit: Dictionary) -> Node2D:
	_free_scene()
	_profile.set(&"_active_ship", hull_id)
	if fit.is_empty():
		_profile.set(&"_fits", {})
	else:
		_profile.call(&"set_fit", hull_id, fit)
	var packed := GameScene
	if packed == null:
		skip("game.tscn is not loadable")
		return null
	_scene = packed.instantiate() as Node2D
	if _scene == null:
		skip("game.tscn did not instantiate")
		return null
	_fixture_host().add_child(_scene)
	return _scene


func _free_scene() -> void:
	if _scene != null and is_instance_valid(_scene):
		_scene.free()
		_scene = null


## Where a fixture may enter the tree: the runner calls every test from inside its own
## `_ready`, when the root viewport is still busy, so the profile autoload hosts them.
func _fixture_host() -> Node:
	var root := _tree().root
	var host := root.get_node_or_null(NodePath(&"PlayerProfile"))
	return host if host != null else root


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _shots() -> Array[Node]:
	var tree := _tree()
	if tree == null:
		return []
	return tree.get_nodes_in_group(ProjectileScript.PROJECTILE_GROUP)


func _clear_shots() -> void:
	for shot: Node in _shots():
		if is_instance_valid(shot):
			shot.free()


func _delete_file(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


func _near(measured: float, expected: float, tolerance := 0.0001) -> bool:
	return absf(measured - expected) <= tolerance
