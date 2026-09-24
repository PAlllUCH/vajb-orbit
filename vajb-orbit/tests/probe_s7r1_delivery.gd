extends Node
## S7-R1 reviewer probe C: the delivery side re-measured with the reviewer's own rig.
##
## Independent of `tests/test_s7_weapon_affixes.gd`: its own sink/rock/peer doubles,
## its own beam spy, its own arithmetic. Measures the per-barrel prefixes (Keen at
## composition, Rapid on the interval, Frugal's bank), the `damage_mult` product at
## each of CONTRACTS section 20's five sites with a value that would be wrong if the
## product landed twice, the null-stats convention, Embers' NPC-only predicate on both
## deliveries and Spry's cooldown line.
##
## Run: godot --headless --path vajb-orbit res://tests/probe_s7r1_delivery.tscn --quit-after 600

const WeaponScript := preload("res://game/weapons.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const PlayerShipScript := preload("res://game/player_ship.gd")
const FitData := preload("res://game/ship_fit.gd")
const ImpactScript := preload("res://game/impact.gd")

const LASER: StringName = &"w_laser"
const CANNON_FAMILY: StringName = &"cannon"
const CANNON_MODULE: StringName = &"w_cannon"

var _fail := 0


class Sink extends Node2D:
	var total := 0.0
	var hits := 0

	func take_damage(amount: float, _bypass := false) -> void:
		total += amount
		hits += 1


class Rock extends Node2D:
	var work := 0.0
	var calls := 0

	func apply_work(amount: float) -> void:
		work += amount
		calls += 1


class Peer extends RigidBody2D:
	var amount := 0.0
	var calls := 0

	func apply_collision_damage(value: float) -> void:
		amount += value
		calls += 1


class BeamSpy extends "res://game/weapons.gd":
	var aim: Node2D = null

	func _beam_target(from: Vector2, _to: Vector2) -> Dictionary:
		if aim == null or not is_instance_valid(aim):
			return {}
		return {
			&"point": aim.global_position,
			&"collider": aim,
			&"distance": from.distance_to(aim.global_position),
			&"projectile": false,
		}


func _ready() -> void:
	print("[S7R1-C] begin")
	_keen_per_barrel()
	_keen_and_multiply_once()
	_beam_weight()
	_rapid_interval()
	_frugal_bank()
	_damage_mult_five_sites()
	_null_stats()
	_embers()
	_spry()
	print("[S7R1-C] done failures=%d" % [_fail])
	get_tree().quit(0)


func _check(ok: bool, label: String, detail: String) -> void:
	if not ok:
		_fail += 1
	print("[S7R1-C] %s %s %s" % ["OK " if ok else "BAD", label, detail])


func _near(a: float, b: float) -> bool:
	return absf(a - b) <= 0.0001


func _state(weapons: Array, affixes: Array) -> PlayerState:
	var state := PlayerStateScript.new()
	var ids: Array[StringName] = []
	for id: Variant in weapons:
		ids.append(StringName(id))
	state.set_weapons(ids)
	state.setup()
	var per: Array[Dictionary] = []
	for cell: Variant in affixes:
		per.append((cell as Dictionary) if cell is Dictionary else {})
	state.set_weapon_affixes(per)
	return state


func _rig(ids: Array, state: PlayerState, stats: ShipStats = null, spy := false) -> Node2D:
	var host := Node2D.new()
	add_child(host)
	var guns: Node2D = (BeamSpy.new() if spy else WeaponScript.new()) as Node2D
	host.add_child(guns)
	guns.call(&"setup", stats, state)
	var fit: Array[StringName] = []
	for id: Variant in ids:
		fit.append(StringName(id))
	guns.call(&"set_fitted", fit)
	return guns


func _spawn(guns: Node2D, weapon: StringName, row: Dictionary, position: int) -> Node2D:
	var shot: Node2D = guns.call(&"_spawn_shot", weapon, row, Vector2.RIGHT, position) as Node2D
	return shot


func _stats(damage_add: float) -> ShipStats:
	if damage_add <= 0.0:
		return FitData.resolve(&"ship_vanguard", {&"weapons": [LASER]})
	return FitData.resolve(&"ship_vanguard", {&"weapons": [LASER], &"computers": [&"c_target"]})


## Keen: only the carrying barrel's shot is scaled, at composition.
func _keen_per_barrel() -> void:
	var state := _state([CANNON_FAMILY, CANNON_FAMILY], [{}, {&"keen": 0.15}])
	var guns := _rig([CANNON_MODULE, CANNON_MODULE], state)
	var row: Dictionary = WeaponScript.row_of(CANNON_FAMILY)
	var base := WeaponScript.shot_damage(CANNON_FAMILY)
	var one := _spawn(guns, CANNON_FAMILY, row, 0)
	var two := _spawn(guns, CANNON_FAMILY, row, 1)
	var d1 := float(one.call(&"damage_amount"))
	var d2 := float(two.call(&"damage_amount"))
	print("[S7R1-C] keen base=%.6f barrel1=%.6f barrel2=%.6f" % [base, d1, d2])
	_check(_near(d1, base), "keen leaves barrel 1 alone", "%.6f" % [d1])
	_check(_near(d2, base * 1.15), "keen scales barrel 2", "%.6f" % [d2])
	one.free()
	two.free()
	# The mirror: Keen in cell 1.
	var mirror := _state([CANNON_FAMILY, CANNON_FAMILY], [{&"keen": 0.15}, {}])
	var mirror_guns := _rig([CANNON_MODULE, CANNON_MODULE], mirror)
	var m1 := _spawn(mirror_guns, CANNON_FAMILY, row, 0)
	var m2 := _spawn(mirror_guns, CANNON_FAMILY, row, 1)
	print(
		"[S7R1-C] keen mirror barrel1=%.6f barrel2=%.6f"
		% [float(m1.call(&"damage_amount")), float(m2.call(&"damage_amount"))]
	)
	_check(_near(float(m1.call(&"damage_amount")), base * 1.15), "mirror cell 1", "%.6f" % [base * 1.15])
	_check(_near(float(m2.call(&"damage_amount")), base), "mirror cell 2 untouched", "%.6f" % [base])
	m1.free()
	m2.free()


## Keen at composition x `damage_mult` at delivery: each lands exactly once, so the
## delivered amount is `base x 1.15 x 1.15`, never the cube.
func _keen_and_multiply_once() -> void:
	var state := _state([CANNON_FAMILY], [{&"keen": 0.15}])
	var guns := _rig([CANNON_MODULE], state, _stats(0.15))
	var row: Dictionary = WeaponScript.row_of(CANNON_FAMILY)
	var base := WeaponScript.shot_damage(CANNON_FAMILY)
	var shot := _spawn(guns, CANNON_FAMILY, row, 0)
	var sink := Sink.new()
	add_child(sink)
	shot.call(&"_deliver", sink, float(shot.call(&"damage_amount")), false, Vector2.ZERO, Vector2.ZERO)
	var once := base * 1.15 * 1.15
	var twice := base * 1.15 * 1.15 * 1.15
	print(
		"[S7R1-C] keen+mult base=%.6f shot=%.6f dealt=%.6f once=%.6f thrice=%.6f hits=%d"
		% [base, float(shot.call(&"damage_amount")), sink.total, once, twice, sink.hits]
	)
	_check(_near(sink.total, once), "keen and damage_mult each once", "%.6f" % [sink.total])
	_check(not _near(sink.total, twice), "not applied twice", "%.6f" % [twice])
	_check(sink.hits == 1, "one delivery", "%d" % [sink.hits])
	shot.free()
	sink.free()


## The beam frame's paid weight: `sum(1 + keen)` over the paying barrels.
func _beam_weight() -> void:
	var sink := Sink.new()
	add_child(sink)
	var state := _state([LASER, LASER], [{}, {}])
	var guns := _rig([LASER, LASER], state, null, true)
	guns.set(&"aim", sink)
	guns.call(&"set_aim_point", Vector2(400.0, 0.0))
	guns.call(&"set_firing", true)
	guns.call(&"tick", 0.1)
	var base := WeaponScript.dps_of(&"laser") * 0.1
	var plain := sink.total
	guns.call(&"set_firing", false)
	guns.call(&"tick", 0.1)
	sink.total = 0.0
	state.set_weapon_affixes(_dicts([{}, {&"keen": 0.15}]))
	guns.call(&"set_firing", true)
	guns.call(&"tick", 0.1)
	var weighted := sink.total
	guns.call(&"set_firing", false)
	guns.call(&"tick", 0.1)
	print(
		"[S7R1-C] beam plain=%.6f (2 x %.6f) weighted=%.6f want=%.6f"
		% [plain, base, weighted, base * 2.15]
	)
	_check(_near(plain, base * 2.0), "affix-free frame is the barrel count", "%.6f" % [plain])
	_check(_near(weighted, base * 2.15), "keen weights the frame", "%.6f" % [weighted])


func _dicts(cells: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for cell: Variant in cells:
		out.append((cell as Dictionary) if cell is Dictionary else {})
	return out


## Rapid: only the carrying barrel's interval, both on the read and the timer.
func _rapid_interval() -> void:
	var state := _state([CANNON_FAMILY, CANNON_FAMILY], [{}, {&"rapid": 0.15}])
	var guns := _rig([CANNON_MODULE, CANNON_MODULE], state)
	var base := WeaponScript.interval_of(CANNON_FAMILY)
	var i0 := float(guns.call(&"_barrel_interval", 0))
	var i1 := float(guns.call(&"_barrel_interval", 1))
	print("[S7R1-C] rapid base=%.6f barrel1=%.6f barrel2=%.6f want=%.6f" % [base, i0, i1, base / 1.15])
	_check(_near(i0, base), "rapid leaves barrel 1", "%.6f" % [i0])
	_check(_near(i1, base / 1.15), "rapid divides barrel 2", "%.6f" % [i1])
	state.set_ammo(0, 30)
	state.set_ammo(1, 30)
	var row: Dictionary = WeaponScript.row_of(CANNON_FAMILY)
	guns.call(&"_fire_projectile", 0, CANNON_FAMILY, row)
	guns.call(&"_fire_projectile", 1, CANNON_FAMILY, row)
	var timers: Array = guns.get(&"_barrel_timers")
	print("[S7R1-C] rapid timers=%s" % [timers])
	_check(_near(float(timers[0]), base), "barrel 1's timer", "%.6f" % [float(timers[0])])
	_check(_near(float(timers[1]), base / 1.15), "barrel 2's timer", "%.6f" % [float(timers[1])])


## Frugal: `floor(shots x (1 + sum))` rounds leave the pack, and the bank lands at 0.
func _frugal_bank() -> void:
	var state := _state([CANNON_FAMILY], [{&"frugal": -0.15}])
	var guns := _rig([CANNON_MODULE], state)
	state.set_ammo(0, 300)
	for _shot in 20:
		guns.call(&"_consume_ammo_at", 0, CANNON_FAMILY)
	print("[S7R1-C] frugal 20 shots at -0.15 spent=%d bank=%.6f" % [300 - int(state.ammo[0]), state.ammo_frac[0]])
	_check(state.ammo[0] == 283, "frugal spends floor(20 x 0.85) = 17", "%d" % [300 - int(state.ammo[0])])
	_check(_near(state.ammo_frac[0], 0.0), "the bank lands on zero", "%.6f" % [state.ammo_frac[0]])
	# A non-Frugal barrel keeps the shipped family spend: `ammo_slot` resolves the
	# family's index in the **const** `PlayerState.WEAPONS`, not in the fit-order list
	# (LOW L90, unchanged by this wave), so the state here is the shipped const list.
	var plain := _state(PlayerStateScript.WEAPONS, [])
	var plain_guns := _rig(PlayerStateScript.WEAPONS, plain)
	var shipped_slot := WeaponScript.ammo_slot(CANNON_FAMILY)
	var cannon_barrel := PlayerStateScript.WEAPONS.find(CANNON_FAMILY)
	plain.set_ammo(shipped_slot, 300)
	for _shot in 20:
		plain_guns.call(&"_consume_ammo_at", cannon_barrel, CANNON_FAMILY)
	print(
		"[S7R1-C] frugal plain ammo_slot=%d barrel=%d spent=%d"
		% [shipped_slot, cannon_barrel, 300 - int(plain.ammo[shipped_slot])]
	)
	_check(
		plain.ammo[shipped_slot] == 280,
		"no frugal spends 20 from the shipped family slot",
		"%d" % [300 - int(plain.ammo[shipped_slot])]
	)
	# Through the real release path.
	var live := _state([CANNON_FAMILY], [{&"frugal": -0.15}])
	var live_guns := _rig([CANNON_MODULE], live)
	live.set_ammo(0, 300)
	var row: Dictionary = WeaponScript.row_of(CANNON_FAMILY)
	for _shot in 20:
		live_guns.call(&"_fire_projectile", 0, CANNON_FAMILY, row)
	print("[S7R1-C] frugal via release spent=%d" % [300 - int(live.ammo[0])])
	_check(live.ammo[0] == 283, "the release path spends the same 17", "%d" % [300 - int(live.ammo[0])])


## `damage_mult` at each of section 20's five sites, with a "not twice" control.
func _damage_mult_five_sites() -> void:
	var stats := _stats(0.15)
	var mult := float(stats.damage_mult)
	print("[S7R1-C] damage_mult resolved=%.6f (c_target 0.15)" % [mult])
	_check(_near(mult, 1.15), "c_target resolves 1.15", "%.6f" % [mult])

	# 1. the beam's hull delivery
	var delta := 0.1
	var frame := WeaponScript.dps_of(&"laser") * delta
	var sink := Sink.new()
	add_child(sink)
	var state := _state([LASER], [{}])
	var guns := _rig([LASER], state, stats)
	guns.call(&"_apply_beam", &"laser", WeaponScript.row_of(&"laser"), sink, Vector2.ZERO, delta, 1.0)
	print("[S7R1-C] site1 beam dealt=%.6f want=%.6f twice=%.6f" % [sink.total, frame * 1.15, frame * 1.15 * 1.15])
	_check(_near(sink.total, frame * 1.15), "site 1 beam x1.15 once", "%.6f" % [sink.total])
	_check(not _near(sink.total, frame * 1.15 * 1.15), "site 1 not squared", "%.6f" % [frame * 1.15 * 1.15])
	_check(sink.hits == 1, "site 1 one delivery", "%d" % [sink.hits])

	# 2. the beam's rock chip
	var rock := Rock.new()
	rock.add_to_group(ProjectileScript.ROCK_GROUP)
	add_child(rock)
	guns.call(&"_apply_beam", &"laser", WeaponScript.row_of(&"laser"), rock, Vector2.ZERO, delta, 1.0)
	var want_chip := frame * WeaponScript.GUN_CHIP_RATE * 1.15
	print("[S7R1-C] site2 beam chip=%.6f want=%.6f calls=%d" % [rock.work, want_chip, rock.calls])
	_check(_near(rock.work, want_chip), "site 2 chip x1.15 once", "%.6f" % [rock.work])
	_check(rock.calls == 1, "site 2 one chip", "%d" % [rock.calls])

	# 3. the projectile's hull delivery
	var shot: Node2D = ProjectileScript.new() as Node2D
	shot.call(&"configure", {&"kind": &"bolt", &"damage": 100.0, &"damage_mult": mult})
	var psink := Sink.new()
	add_child(psink)
	shot.call(&"_deliver", psink, 100.0, false, Vector2.ZERO, Vector2.ZERO)
	print("[S7R1-C] site3 projectile dealt=%.6f want=%.6f twice=%.6f" % [psink.total, 115.0, 132.25])
	_check(_near(psink.total, 115.0), "site 3 projectile x1.15 once", "%.6f" % [psink.total])
	_check(not _near(psink.total, 132.25), "site 3 not squared", "%.6f" % [132.25])
	_check(psink.hits == 1, "site 3 one delivery", "%d" % [psink.hits])

	# 4. the projectile's rock chip
	var shot2: Node2D = ProjectileScript.new() as Node2D
	shot2.call(&"configure", {&"kind": &"bolt", &"damage": 100.0, &"chip": 0.10, &"damage_mult": mult})
	var rock2 := Rock.new()
	rock2.add_to_group(ProjectileScript.ROCK_GROUP)
	add_child(rock2)
	shot2.call(&"_hit_rock", rock2, Vector2.ZERO)
	print("[S7R1-C] site4 projectile chip=%.6f want=%.6f calls=%d" % [rock2.work, 11.5, rock2.calls])
	_check(_near(rock2.work, 11.5), "site 4 chip x1.15 once", "%.6f" % [rock2.work])
	_check(rock2.calls == 1, "site 4 one chip", "%d" % [rock2.calls])

	# 5. the ram
	var peer := Peer.new()
	peer.mass = 5.0
	peer.global_position = Vector2(20.0, 0.0)
	add_child(peer)
	var ship: Node2D = PlayerShipScript.new() as Node2D
	var ship_state := _state([CANNON_FAMILY], [{}])
	ship.set(&"_state", ship_state)
	ship.set(&"_stats", stats)
	ship.set(&"_last_velocity", Vector2(100.0, 0.0))
	add_child(ship)
	var ram_base := ImpactScript.collision_damage(110.0, 5.0, 100.0)
	ship.call(&"_on_hull_body_entered", peer)
	print("[S7R1-C] site5 ram base=%.6f got=%.6f want=%.6f calls=%d" % [ram_base, peer.amount, ram_base * 1.15, peer.calls])
	_check(_near(peer.amount, ram_base * 1.15), "site 5 ram x1.15 once", "%.6f" % [peer.amount])
	_check(peer.calls == 1, "site 5 one ram call", "%d" % [peer.calls])

	# no computer: byte-identical
	var plain_stats := _stats(0.0)
	var plain_sink := Sink.new()
	add_child(plain_sink)
	var plain_guns := _rig([LASER], _state([LASER], [{}]), plain_stats)
	plain_guns.call(&"_apply_beam", &"laser", WeaponScript.row_of(&"laser"), plain_sink, Vector2.ZERO, delta, 1.0)
	print("[S7R1-C] site1 no computer dealt=%.6f want=%.6f mult=%.6f" % [plain_sink.total, frame, plain_stats.damage_mult])
	_check(_near(plain_sink.total, frame), "no computer is today's figure", "%.6f" % [plain_sink.total])
	_check(_near(plain_stats.damage_mult, 1.0), "no computer mult 1.0", "%.6f" % [plain_stats.damage_mult])

	# the projectile with no damage_mult key
	var bare: Node2D = ProjectileScript.new() as Node2D
	bare.call(&"configure", {&"kind": &"bolt", &"damage": 100.0})
	var bare_sink := Sink.new()
	add_child(bare_sink)
	bare.call(&"_deliver", bare_sink, 100.0, false, Vector2.ZERO, Vector2.ZERO)
	print("[S7R1-C] site3 no key dealt=%.6f" % [bare_sink.total])
	_check(_near(bare_sink.total, 100.0), "a shot with no key is 100.0", "%.6f" % [bare_sink.total])


## A null stats argument is the shipped eight-suite convention: 1.0, never a crash.
func _null_stats() -> void:
	var sink := Sink.new()
	add_child(sink)
	var guns := _rig([LASER], _state([LASER], [{}]), null)
	guns.call(&"_apply_beam", &"laser", WeaponScript.row_of(&"laser"), sink, Vector2.ZERO, 0.1, 1.0)
	var frame := WeaponScript.dps_of(&"laser") * 0.1
	print("[S7R1-C] null stats dealt=%.6f want=%.6f" % [sink.total, frame])
	_check(_near(sink.total, frame), "null stats deliver un-multiplied", "%.6f" % [sink.total])
	var ship: Node2D = PlayerShipScript.new() as Node2D
	add_child(ship)
	_check(_near(float(ship.call(&"_damage_scale")), 1.0), "PlayerShip null stats 1.0", "%.6f" % [float(ship.call(&"_damage_scale"))])
	_check(_near(float(ship.call(&"_booster_cooldown_scale")), 1.0), "PlayerShip null Spry 1.0", "%.6f" % [float(ship.call(&"_booster_cooldown_scale"))])


## Embers: an NPC hull only, both deliveries, 10 % of the dealt amount, clamped.
func _embers() -> void:
	var state := _state([LASER], [{}])
	state.setup()
	var flags: Array[StringName] = [&"embers"]
	state.set_affix_flags(flags)
	state.set_shield(100.0)
	var npc := Sink.new()
	npc.add_to_group(&"npc_ship")
	add_child(npc)
	var guns := _rig([LASER], state, null)
	guns.call(&"_deliver", npc, 200.0, false, Vector2.ZERO, &"energy", Vector2.ZERO)
	print("[S7R1-C] embers beam npc shield=%.6f want=120.0" % [state.shield])
	_check(_near(state.shield, 120.0), "beam Embers heals 10%% of 200", "%.6f" % [state.shield])
	state.set_shield(100.0)
	var rock := Rock.new()
	rock.add_to_group(ProjectileScript.ROCK_GROUP)
	add_child(rock)
	guns.call(&"_deliver", rock, 200.0, false, Vector2.ZERO, &"energy", Vector2.ZERO)
	_check(_near(state.shield, 100.0), "a rock heals nothing", "%.6f" % [state.shield])
	state.set_shield(100.0)
	var own := Sink.new()
	own.add_to_group(&"player_ship")
	add_child(own)
	guns.call(&"_deliver", own, 200.0, false, Vector2.ZERO, &"energy", Vector2.ZERO)
	_check(_near(state.shield, 100.0), "the player's own hull heals nothing", "%.6f" % [state.shield])
	state.set_shield(state.shield_max - 5.0)
	guns.call(&"_deliver", npc, 200.0, false, Vector2.ZERO, &"energy", Vector2.ZERO)
	_check(_near(state.shield, state.shield_max), "the beam heal clamps", "%.6f" % [state.shield])
	# The heal is 10 % of the *delivered* amount (post-multiplier).
	var mult_state := _state([LASER], [{}])
	mult_state.setup()
	mult_state.set_affix_flags(flags)
	mult_state.set_shield(0.0)
	var mult_guns := _rig([LASER], mult_state, _stats(0.15))
	mult_guns.call(&"_deliver", npc, 200.0, false, Vector2.ZERO, &"energy", Vector2.ZERO)
	print("[S7R1-C] embers beam with mult shield=%.6f want=%.6f" % [mult_state.shield, 200.0 * 1.15 * 0.10])
	_check(_near(mult_state.shield, 200.0 * 1.15 * 0.10), "Embers heals the delivered amount", "%.6f" % [mult_state.shield])
	# The projectile path heals through the source.
	var p_state := _state([CANNON_FAMILY], [{}])
	p_state.setup()
	p_state.set_affix_flags(flags)
	p_state.set_shield(100.0)
	var ship: Node2D = PlayerShipScript.new() as Node2D
	ship.set(&"_state", p_state)
	add_child(ship)
	var shot: Node2D = ProjectileScript.new() as Node2D
	shot.call(&"configure", {&"kind": &"bolt", &"damage": 200.0, &"embers": true, &"source": ship})
	shot.call(&"_deliver", npc, 200.0, false, Vector2.ZERO, Vector2.ZERO)
	print("[S7R1-C] embers projectile shield=%.6f want=120.0" % [p_state.shield])
	_check(_near(p_state.shield, 120.0), "projectile Embers heals through the source", "%.6f" % [p_state.shield])
	p_state.set_shield(100.0)
	shot.call(&"_deliver", rock, 200.0, false, Vector2.ZERO, Vector2.ZERO)
	_check(_near(p_state.shield, 100.0), "projectile Embers skips a rock", "%.6f" % [p_state.shield])
	# No flag: no heal.
	var quiet := _state([LASER], [{}])
	quiet.setup()
	quiet.set_shield(100.0)
	var quiet_guns := _rig([LASER], quiet, null)
	quiet_guns.call(&"_deliver", npc, 200.0, false, Vector2.ZERO, &"energy", Vector2.ZERO)
	_check(_near(quiet.shield, 100.0), "no flag, no heal", "%.6f" % [quiet.shield])


## Spry: the afterburner's own line writes the row's 8.0 s x the ship stat.
func _spry() -> void:
	var spry_stats: ShipStats = FitData.resolve(
		&"ship_vanguard", {&"boosters": [&"b_afterburner"]}, {&"spry": -0.15}
	)
	var plain_stats: ShipStats = FitData.resolve(&"ship_vanguard", {&"boosters": [&"b_afterburner"]})
	print(
		"[S7R1-C] spry mult=%.6f plain=%.6f" % [spry_stats.booster_cooldown_mult, plain_stats.booster_cooldown_mult]
	)
	_check(_near(spry_stats.booster_cooldown_mult, 0.85), "spry resolves 0.85", "%.6f" % [spry_stats.booster_cooldown_mult])
	_check(_near(plain_stats.booster_cooldown_mult, 1.0), "no spry 1.0", "%.6f" % [plain_stats.booster_cooldown_mult])
	var state := _state([CANNON_FAMILY], [{}])
	var ship: Node2D = PlayerShipScript.new() as Node2D
	ship.set(&"_stats", spry_stats)
	ship.set(&"_state", state)
	add_child(ship)
	Input.action_press(PlayerShipScript.BOOST_ACTION)
	ship.call(&"_update_boosters", 0.0)
	Input.action_release(PlayerShipScript.BOOST_ACTION)
	var cooldown := float(ship.get(&"_boost_cooldown"))
	print("[S7R1-C] spry afterburner cooldown=%.6f want=6.8" % [cooldown])
	_check(_near(cooldown, 6.8), "8.0 s x 0.85 = 6.8 s", "%.6f" % [cooldown])
