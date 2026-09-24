extends Node2D
## S8-R1 reviewer probe: AC4's second half - the fragment's collision shape is *active on the
## next physics step*, not merely deferred. A real `AsteroidField` is mounted, a medium rock is
## built outside any flush, depleted so the shipped `_cleave` path spawns fragments, and the
## fragment's `Shape` child is read at the cleave's own call and after two physics frames.
##
## Run:  godot --headless --path vajb-orbit res://tests/probe_s8_r1_fragment_shape.tscn \
##         --quit-after 1200 --fixed-fps 60
## Signal: the [S8R1] lines; the last line is `[S8R1] done`.

const FieldScript := preload("res://game/asteroid_field.gd")
const AsteroidScript := preload("res://game/asteroid.gd")

const TAG := "[S8R1]"
const SHAPE_NODE: StringName = &"Shape"


func _ready() -> void:
	await get_tree().process_frame
	var field := FieldScript.new() as Node2D
	field.name = "R1FragmentField"
	add_child(field)
	await get_tree().physics_frame
	var rock: RigidBody2D = field.call(
		&"_new_rock", "RockR1", &"iron", 1, 3, AsteroidScript.SIZE_MEDIUM
	)
	await get_tree().physics_frame
	var rock_shape := rock.get_node_or_null(NodePath(SHAPE_NODE))
	print(
		"%s rock shape=%s radius=%.3f"
		% [TAG, str(rock_shape != null), float(rock.call(&"world_radius"))]
	)
	rock.call(&"apply_work", 3.0)
	var fragments: Array[Node] = []
	for child: Node in field.get_children():
		if String(child.name).begins_with("Fragment"):
			fragments.append(child)
	print("%s fragments=%d" % [TAG, fragments.size()])
	for fragment: Node in fragments:
		var pending := fragment.get_node_or_null(NodePath(SHAPE_NODE))
		print(
			"%s at_cleave shape=%s radius=%.3f"
			% [
				TAG,
				str(pending != null),
				float(fragment.call(&"world_radius")),
			]
		)
	await get_tree().process_frame
	await get_tree().physics_frame
	var live := 0
	for fragment: Node in fragments:
		var shape := fragment.get_node_or_null(NodePath(SHAPE_NODE)) as CollisionShape2D
		var radius := -1.0
		var disabled := true
		if shape != null:
			disabled = shape.disabled
			if shape.shape is CircleShape2D:
				radius = (shape.shape as CircleShape2D).radius
		if shape != null and not disabled:
			live += 1
		print(
			"%s after_frames shape=%s disabled=%s radius=%.3f"
			% [TAG, str(shape != null), str(disabled), radius]
		)
	print("%s active_fragments=%d/%d" % [TAG, live, fragments.size()])
	print("%s done" % TAG)
	get_tree().quit(0)
