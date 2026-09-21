extends Node2D
## S2 review: a still pair of the shipped scene, the thruster emitters on and off *with the
## tree paused*, so the two frames differ by the trail's own pixels and nothing else.
##
## Run: ~/.local/bin/godot --path vajb-orbit res://tests/probe_s2_5_shot.tscn

const TAG := "[S2SHOT]"
const ON := "/tmp/s2/ship_paused_trail_on.png"
const OFF := "/tmp/s2/ship_paused_trail_off.png"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var packed := load("res://game/game.tscn") as PackedScene
	var scene := packed.instantiate() as Node2D
	add_child(scene)
	var ship: Variant = scene.get_node_or_null(NodePath(&"PlayerShip"))
	var stats: Variant = scene.get(&"_stats")
	if ship == null or stats == null:
		print("%s wiring=missing" % TAG)
		get_tree().quit()
		return
	var body := ship.call(&"impact_body") as RigidBody2D
	Input.action_press(&"thrust_forward")
	for i in 120:
		if body != null:
			body.linear_velocity = Vector2.ZERO
		await RenderingServer.frame_post_draw
	var trails: Array = ship.call(&"thruster_trails")
	if trails.is_empty():
		print("%s no emitters" % TAG)
		get_tree().quit()
		return
	var trail := trails[0] as GPUParticles2D
	get_tree().paused = true
	for i in 4:
		await RenderingServer.frame_post_draw
	_save(ON)
	trail.visible = false
	for i in 4:
		await RenderingServer.frame_post_draw
	_save(OFF)
	print(
		"%s on=%s off=%s emitters=%d visible=%s emitting=%s amount_ratio=%.6f scale=%s pos=(%.2f,%.2f) world=(%.2f,%.2f)"
		% [
			TAG,
			ON,
			OFF,
			trails.size(),
			str(trail.visible),
			str(trail.emitting),
			trail.amount_ratio,
			str(trail.scale),
			trail.position.x,
			trail.position.y,
			trail.global_position.x,
			trail.global_position.y,
		]
	)
	get_tree().paused = false
	Input.action_release(&"thrust_forward")
	get_tree().quit()


func _save(path: String) -> void:
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(path)
	print("%s save=%s error=%d size=%s" % [TAG, path, error, str(image.get_size())])
