extends Node
## S3's scratch probe: what a mine's own detonation actually draws. The gate's
## `test_the_mine_family_owns_its_sprite_and_its_burst` reads the same nodes; this prints
## them so a failure is a measurement rather than a guess.
##
## Run: ~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_s3_mine.tscn

const ProjectileScript := preload("res://game/projectile.gd")
const FxScript := preload("res://game/fx.gd")

const TAG := "[S3M]"


func _ready() -> void:
	var row := ProjectileScript.feedback_row(&"mine_burst")
	print("%s ROW empty=%s keys=%s frames=%d" % [TAG, str(row.is_empty()), str(row.keys()), (row.get(&"frames", []) as Array).size()])
	var textures := FxScript.frame_textures(row.get(&"frames", []), row.get(&"region", Rect2()))
	print("%s TEXTURES count=%d" % [TAG, textures.size()])
	var holder := Node2D.new()
	holder.name = &"MineWorld"
	add_child(holder)
	var shot: Variant = ProjectileScript.new()
	shot.call(&"configure", {&"kind": ProjectileScript.KIND_MINE, &"damage": 1.0})
	holder.add_child(shot)
	print("%s SHOT kind=%s spent=%s parent=%s" % [TAG, String(shot.get(&"kind")), str(shot.get(&"_spent")), String(shot.get_parent().name)])
	var sprite := ProjectileScript.spawn_mine_burst(holder, Vector2(10.0, 20.0))
	print("%s DIRECT_SPAWN node=%s" % [TAG, "<none>" if sprite == null else String(sprite.name)])
	if sprite != null:
		sprite.free()
	shot.call(&"_detonate", Vector2(10.0, 20.0))
	print("%s DETONATED children=%d" % [TAG, holder.get_child_count()])
	for child: Node in holder.get_children():
		var texture: Texture2D = null
		var frames := (child as AnimatedSprite2D).sprite_frames if child is AnimatedSprite2D else null
		if frames != null and frames.has_animation(FxScript.ANIMATION) and frames.get_frame_count(FxScript.ANIMATION) > 0:
			texture = frames.get_frame_texture(FxScript.ANIMATION, 0)
		elif child is Sprite2D:
			texture = (child as Sprite2D).texture
		var path := ""
		if texture is AtlasTexture:
			path = (texture as AtlasTexture).atlas.resource_path
		elif texture != null:
			path = texture.resource_path
		print("%s CHILD %s type=%s frames=%d sheet=%s" % [TAG, String(child.name), child.get_class(), 0 if frames == null else frames.get_frame_count(FxScript.ANIMATION), path])
	print("%s done" % TAG)
	get_tree().quit()
