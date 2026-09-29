extends Node2D
## S21-B1's contact probe (worker S21-B1, 2026-09-28): the *engine-level* half of A3 /
## L22, which the synchronous gate cannot measure - the headless runner calls every suite
## from its own `_ready`, before a body is in the 2D broadphase, so no contact can fire
## there (`test_s6_heat.gd` records the same limit for its rock ray).
##
## A real `PlayerShip` (its shipped `HullBody`, its shipped contact monitor) is driven at a
## fixed velocity into a real `NpcShip` hull and then into a real `Asteroid`, and the engine
## is asked what happened:
##
##   * did the player's contact monitor fire, and did the NPC's (the pair exists when
##     *either* side's mask names the other's layer - so "ships never pair" is a reading);
##   * what did each side's pools lose on the **first** impact, against the row-15 figure
##     `Impact` computes for the same masses and closing speed: "both halves, exactly
##     once" is then the difference between the loss and the figure;
##   * what did each body's velocity do across that contact (the solver's push, and whose
##     mass entered it);
##   * the rock control: the shipped rock path must read exactly what C1/RAM measured.
##
## The ram is driven, not thrusted (C1's pattern), and this probe drives the *body*: the
## ship's own `_physics_process` is off, the probe re-asserts `linear_velocity` and
## `_last_velocity` together every physics frame until a contact is reported (the closing
## speed is then the scenario's constant, not a product of the flight law and its coast
## decay), and calls the shipped `_sync_hull_transform` so the hull node keeps riding its
## body. The NPC's physics is off too, so the pirate brain neither flies nor fires and the
## contact is the only thing changing its pools; its contact monitor is a body signal and
## stays live.
##
## Writes nothing: no profile key is touched, no economy line is filed (no death runs), and
## the run is launched under a scratch `XDG_DATA_HOME` (S21_BRIEF.md rule 5 / L229).
##
## Run:
##   XDG_DATA_HOME=$(mktemp -d) godot --headless --path vajb-orbit \
##     res://tests/probe_s21_contacts.tscn --quit-after 3000
##
## The probe quits itself once both scenarios are measured; `--quit-after` is the hard
## bound. Every line is prefixed `[S21-CONTACT]`; the last line is `[S21-CONTACT] done`.

const PlayerShipScene := preload("res://game/player_ship.tscn")
const PlayerStateScript := preload("res://game/player_state.gd")
const NpcShipScript := preload("res://game/npc_ship.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const ImpactScript := preload("res://game/impact.gd")

const TAG := "[S21-CONTACT]"
const HULL_BODY: StringName = &"HullBody"
const HULL: StringName = &"ship_vanguard"
const NPC_HULL: StringName = &"ship_fighter"
const NPC_ARCHETYPE: StringName = &"pirate"
const NPC_SPRITE := "res://assets/ships/ship_fighter_side.png"

const APPROACH_SPEED := 450.0
const START_GAP := 400.0
const FRAME_CAP := 240
const ROCK_UNITS := 100

## The launched fit's weapon ids: empty, because this probe measures the ram's own
## arithmetic and no weapon fires (the ship's guns are mounted from the fit).
var _no_fit: Array[StringName] = []


func _ready() -> void:
	print("%s probe start engine=%s" % [TAG, Engine.get_version_info()["string"]])
	await _run_ship_pair()
	await _run_rock_control()
	print("%s done" % TAG)
	get_tree().quit()


## The player's hull into an NPC hull: L22's pair, with both monitors watched.
func _run_ship_pair() -> void:
	var ship := _spawn_player()
	var body := ship.get_node_or_null(NodePath(HULL_BODY)) as RigidBody2D
	var state = ship.get(&"_state")

	var npc := NpcShipScript.new() as Node2D
	add_child(npc)
	npc.set_physics_process(false)
	var npc_stats: ShipStats = ShipFitScript.resolve(NPC_HULL, ShipFitScript.STANDARD_FIT)
	npc.call(&"setup", NPC_ARCHETYPE, npc_stats, NPC_HULL, {&"sprite_path": NPC_SPRITE})
	npc.global_position = Vector2(START_GAP, 0.0)
	var npc_body := npc.call(&"impact_body") as RigidBody2D

	var seen := {"player": 0, "npc": 0}
	body.body_entered.connect(func(_other: Node) -> void: seen["player"] += 1)
	npc_body.body_entered.connect(func(_other: Node) -> void: seen["npc"] += 1)

	var pools_before := {"player": _pools(state), "npc": _npc_pools(npc)}
	var figure := ImpactScript.collision_damage(body.mass, npc_body.mass, APPROACH_SPEED)
	var frames: int = await _drive(ship, body, seen)
	var pools_after := {"player": _pools(state), "npc": _npc_pools(npc)}
	print(
		(
			"%s SHIPHULL frames=%d pairs=player:%d npc:%d player_mass=%.1f npc_mass=%.1f "
			+ "closing=%.1f row15=%.6f"
		)
		% [TAG, frames, seen["player"], seen["npc"], body.mass, npc_body.mass, APPROACH_SPEED, figure]
	)
	print(
		"%s SHIPHULL player_loss=%.6f npc_loss=%.6f"
		% [
			TAG,
			_pool_total(pools_before["player"]) - _pool_total(pools_after["player"]),
			_pool_total(pools_before["npc"]) - _pool_total(pools_after["npc"]),
		]
	)
	print(
		"%s SHIPHULL velocity player %.3f->%.3f npc %.3f->%.3f"
		% [
			TAG,
			APPROACH_SPEED,
			body.linear_velocity.length(),
			0.0,
			npc_body.linear_velocity.length(),
		]
	)
	ship.free()
	npc.free()


## The shipped rock path, the control: a body whose mask and sink never changed.
func _run_rock_control() -> void:
	var ship := _spawn_player()
	var body := ship.get_node_or_null(NodePath(HULL_BODY)) as RigidBody2D
	var state = ship.get(&"_state")

	var rock := AsteroidScript.new() as RigidBody2D
	add_child(rock)
	rock.call(&"setup", &"iron", 1, ROCK_UNITS, AsteroidScript.SIZE_MEDIUM)
	rock.global_position = Vector2(START_GAP, 0.0)
	rock.linear_velocity = Vector2.ZERO

	var seen := {"player": 0, "npc": 0}
	body.body_entered.connect(func(_other: Node) -> void: seen["player"] += 1)

	var pools_before := _pools(state)
	var work_before := float(rock.get(&"work"))
	var units_before := int(rock.get(&"yield_units"))
	var figure := ImpactScript.collision_damage(body.mass, rock.mass, APPROACH_SPEED)
	var frames: int = await _drive(ship, body, seen)
	var credited := (
		float(units_before - int(rock.get(&"yield_units")))
		+ float(rock.get(&"work")) - work_before
	)
	print(
		"%s ROCK frames=%d pairs=%d rock_layer=%d rock_mask=%d rock_mass=%.1f row15=%.6f"
		% [TAG, frames, seen["player"], rock.collision_layer, rock.collision_mask, rock.mass, figure]
	)
	print(
		"%s ROCK player_loss=%.6f rock_credited=%.6f of an expected %.6f (C5's 10 %% channel)"
		% [
			TAG,
			_pool_total(pools_before) - _pool_total(_pools(state)),
			credited,
			figure * 0.10,
		]
	)
	ship.free()
	rock.free()


## One player hull, out of the shipped scene, with its flight law switched off: the body
## is ballistic and the probe owns the velocity the handler reads as the closing speed.
func _spawn_player() -> Node2D:
	var ship := PlayerShipScene.instantiate() as Node2D
	add_child(ship)
	var state: PlayerState = PlayerStateScript.new()
	var stats: ShipStats = ShipFitScript.resolve(HULL, ShipFitScript.STANDARD_FIT)
	state.hull_max = stats.hull_max
	state.shield_max = stats.shield_max
	state.setup()
	ship.call(&"setup", stats, state, _no_fit)
	ship.global_position = Vector2.ZERO
	ship.set_physics_process(false)
	ship.call(&"cancel_orders")
	return ship


## C1's driver, on the body instead of the stick: re-assert the velocity (and the
## handler's own `_last_velocity`) every physics frame, mirror the node onto its body, and
## stop on the frame a monitor reports. Returns the frames driven.
func _drive(ship: Node2D, body: RigidBody2D, seen: Dictionary) -> int:
	var velocity := Vector2(APPROACH_SPEED, 0.0)
	for frame in FRAME_CAP:
		if not is_instance_valid(body):
			return frame
		body.linear_velocity = velocity
		ship.set(&"_last_velocity", velocity)
		ship.call(&"_sync_hull_transform")
		await get_tree().physics_frame
		if int(seen.get("player", 0)) + int(seen.get("npc", 0)) > 0:
			return frame + 1
	return FRAME_CAP


func _pools(state) -> Dictionary:
	return {"hull": float(state.hull), "shield": float(state.shield)}


func _npc_pools(npc: Node2D) -> Dictionary:
	return {"hull": float(npc.call(&"hull")), "shield": float(npc.call(&"shield"))}


func _pool_total(pools: Dictionary) -> float:
	return float(pools["hull"]) + float(pools["shield"])
