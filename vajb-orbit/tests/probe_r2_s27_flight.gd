extends Node2D
## S27-R2 probe 2 (live flight): the Pyre ring proven on the real scene and real
## NpcShip hulls, not the suite's stub sink. Self-quits; run bound:
##   $GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/probe_r2_s27_flight.tscn --quit-after 400

const GameScript := preload("res://game/game.gd")
const NpcShipScript := preload("res://game/npc_ship.gd")
const NpcRegistryScript := preload("res://game/npc_registry.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")

const KILL_POINT := Vector2(4800.0, -4800.0)
const ARCHETYPE := &"swarmer"
const HULL_ID := &"ship_fighter"

var _fail := 0


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var packed := load("res://game/game.tscn") as PackedScene
	var scene := packed.instantiate() as Node2D
	add_child(scene)
	await get_tree().process_frame
	var stats := ShipFitScript.resolve(HULL_ID, ShipFitScript.STANDARD_FIT)
	if stats == null:
		print("PROBE_R2_FLIGHT FAIL resolve returned null")
		_quit()
		return
	# A nearby real hull the ring would charge (its shield drained so the ring
	# reaches the hull pool directly).
	var nb := _spawn(scene, stats, KILL_POINT + Vector2(60.0, 0.0), "ProbeRingNeighbor")
	nb.call(&"set_shield", 0.0)
	var hull: float = float(nb.call(&"get", "_hull"))
	scene.set(&"_launch_summary", {&"suffixes": [&"pyre"]})

	# 1) a full-hull one-shot: the shared recorded at the top of take_damage is 1.0,
	# so the gate (>= 0.25) holds and no ring fires.
	var one_shot := _spawn(scene, stats, KILL_POINT, "ProbeOneShotVictim")
	one_shot.connect(&"died", scene._on_npc_died.bind(one_shot))
	var pre_default: float = float(one_shot.call(&"pre_hit_hull_fraction"))
	one_shot.call(&"take_damage", 999999.0, true)
	var after_one_shot: float = float(nb.call(&"get", "_hull"))
	if pre_default != 1.0:
		_fail_line("F2 fresh-hull pre_hit default %f != 1.0" % pre_default)
	if float(one_shot.call(&"pre_hit_hull_fraction")) != 1.0:
		_fail_line("F2 one-shot pre_hit %f != 1.0 (not recorded at the top of take_damage)"
			% float(one_shot.call(&"pre_hit_hull_fraction")))
	if after_one_shot != hull:
		_fail_line("F2 the ring fired on a full-hull one-shot: neighbor %f -> %f"
			% [hull, after_one_shot])

	# 2) a finish below the quarter line: chip to 10 % of the hull, then a lethal
	# bypass blow. The stored share is the pre-blow 0.10, so the ring fires.
	var nb2 := _spawn(scene, stats, KILL_POINT + Vector2(60.0, 0.0), "ProbeRingNeighbor2")
	nb2.call(&"set_shield", 0.0)
	var hull2: float = float(nb2.call(&"get", "_hull"))
	var victim := _spawn(scene, stats, KILL_POINT, "ProbeQuarterVictim")
	victim.call(&"set_shield", 0.0)
	var v_max: float = float(victim.call(&"get", "_hull_max"))
	victim.call(&"set_hull", v_max * 0.10)
	victim.connect(&"died", scene._on_npc_died.bind(victim))
	victim.call(&"take_damage", v_max, true)
	var pre_before_lethal: float = float(victim.call(&"pre_hit_hull_fraction"))
	var after_finish: float = float(nb2.call(&"get", "_hull"))
	var drop := hull2 - after_finish
	if absf(pre_before_lethal - 0.10) > 0.001:
		_fail_line("F2 pre-blow share %f != 0.10 (recorded after the blow?)" % pre_before_lethal)
	if is_equal_approx(drop, 0.0):
		_fail_line("F2 the ring did NOT fire on a below-quarter finish")
	elif absf(drop - minf(50.0, hull2)) > 0.001:
		_fail_line("F2 ring damage %f != 50 (clamped %f)" % [drop, minf(50.0, hull2)])

	# 3) no Pyre: the same shape of a below-quarter finish pays no ring.
	var nb3 := _spawn(scene, stats, KILL_POINT + Vector2(60.0, 0.0), "ProbeRingNeighbor3")
	nb3.call(&"set_shield", 0.0)
	var hull3: float = float(nb3.call(&"get", "_hull"))
	scene.set(&"_launch_summary", {})
	var victim3 := _spawn(scene, stats, KILL_POINT, "ProbeNoPyreVictim")
	victim3.call(&"set_shield", 0.0)
	victim3.call(&"set_hull", float(victim3.call(&"get", "_hull_max")) * 0.10)
	victim3.connect(&"died", scene._on_npc_died.bind(victim3))
	victim3.call(&"take_damage", v_max, true)
	if hull3 - float(nb3.call(&"get", "_hull")) != 0.0:
		_fail_line("F2 the ring fired without of the Pyre")
	print("PROBE_R2_FLIGHT verdict failed=%d (hulls %.0f/%.0f/%.0f before)"
		% [_fail, hull, hull2, hull3])
	_quit()


func _spawn(scene: Node2D, stats: ShipStats, pos: Vector2, name: String) -> Node2D:
	var ship: Node2D = NpcShipScript.new() as Node2D
	ship.name = name
	scene.add_child(ship)
	ship.global_position = pos
	ship.call(&"setup", ARCHETYPE, stats, HULL_ID,
		{NpcShipScript.OPT_HOME: pos, NpcShipScript.OPT_SPRITE_PATH: ""})
	return ship


func _fail_line(text: String) -> void:
	_fail += 1
	print("PROBE_R2_FLIGHT FAIL %s" % text)


func _quit() -> void:
	get_tree().quit(1 if _fail > 0 else 0)
