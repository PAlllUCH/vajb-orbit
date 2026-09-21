extends Node
## C6 (reviewer) evidence probe: the discriminating power of the rewritten
## `tests/test_engine2_cleaving.gd` mask assertion, measured rather than argued.
##
## The pre-wave pin read `assert_eq(body.collision_mask, 0, "rocks mask nothing
## (the ship masks them)")` and passed because `Asteroid.setup` wrote 0. This probe
## prints, for each candidate mask, what the old pin would read, what the new pin
## reads, and whether the pairwise `collides_with` gate is open in both directions.
## It changes nothing: the shipping value is read off `setup`, the alternatives are
## arithmetic on constants, and no body is touched.
##
## Run: godot --headless --path vajb-orbit res://tests/probe_c6_pins.tscn --quit-after 600

const AsteroidScript := preload("res://game/asteroid.gd")
const PlayerShipScene := preload("res://game/player_ship.tscn")

const ROCK_UNITS := 100


func _ready() -> void:
	print("[C6-PIN] probe start engine=%s" % Engine.get_version_info()["string"])

	var ship := PlayerShipScene.instantiate()
	var hull := ship.get_node_or_null(NodePath("HullBody")) as RigidBody2D
	var hull_layer := hull.collision_layer
	var hull_mask := hull.collision_mask
	print("[C6-PIN] scene player_ship.tscn HullBody layer=%d mask=%d" % [hull_layer, hull_mask])
	print(
		"[C6-PIN] class Asteroid.COLLISION_LAYER=%d COLLISION_MASK=%d"
		% [AsteroidScript.COLLISION_LAYER, AsteroidScript.COLLISION_MASK]
	)

	var rock := AsteroidScript.new() as RigidBody2D
	add_child(rock)
	rock.call(&"setup", &"iron", 1, ROCK_UNITS, AsteroidScript.SIZE_MEDIUM)
	print(
		"[C6-PIN] shipped rock after setup: layer=%d mask=%d units=%d"
		% [rock.collision_layer, rock.collision_mask, rock.yield_units]
	)

	for candidate: int in [0, 1, AsteroidScript.COLLISION_MASK]:
		var old_pin := candidate == 0
		var new_pin := candidate == AsteroidScript.COLLISION_MASK
		var rocks_apart := AsteroidScript.COLLISION_MASK & AsteroidScript.COLLISION_LAYER == 0
		var rock_mass_in_solve := candidate & hull_layer != 0
		var hull_mass_in_solve := hull_mask & AsteroidScript.COLLISION_LAYER != 0
		print(
			(
				"[C6-PIN] mask=%d old_pin(mask==0)=%s new_pin(mask==%d)=%s rocks_apart=%s rock_in_solve=%s hull_in_solve=%s"
				% [
					candidate,
					str(old_pin),
					AsteroidScript.COLLISION_MASK,
					str(new_pin),
					str(rocks_apart),
					str(rock_mass_in_solve),
					str(hull_mass_in_solve),
				]
			)
		)

	print("[C6-PIN] done")
	ship.free()
	get_tree().quit(0)
