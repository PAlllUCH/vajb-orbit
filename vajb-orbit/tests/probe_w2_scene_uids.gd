extends Node
## W2 evidence probe (wave UI-chrome, defect D4).
##
## Rebuilds the engine's own ext_resource check for the two scenes that were
## left carrying a uid from the pre-re-layout asset tree, then loads both
## scenes so the engine itself reports a stale UID if one is left.
##
##   godot --headless --path vajb-orbit res://tests/probe_w2_scene_uids.tscn \
##     --quit-after 120
##
## It also re-checks every `res://` literal in the L16 consumer list. Read-only:
## it opens engine files, never writes.

const SCENES: Array[String] = [
	"res://game/player_ship.tscn",
	"res://game/game.tscn",
]

const L16_FILES: Array[String] = [
	"res://game/pickup.gd",
	"res://game/sector.gd",
	"res://game/sector_registry.gd",
	"res://ui/screens/loading.tscn",
	"res://ui/screens/main_menu.tscn",
]

const EXT_RESOURCE_PREFIX := "[ext_resource"
const PATH_ATTR := "path=\"res://"
const UID_ATTR := "uid=\"uid://"

var _stale := 0
var _missing_literals := 0
var _checked_literals := 0


func _ready() -> void:
	print("[PROBE] W2 start")
	for scene_path: String in SCENES:
		_check_scene_uids(scene_path)
	for scene_path: String in SCENES:
		_load_scene(scene_path)
	for file_path: String in L16_FILES:
		_check_literals(file_path)
	_sweep_scenes()
	print("[L16] checked=%d missing=%d" % [_checked_literals, _missing_literals])
	print("[PROBE] stale_uids=%d missing_literals=%d" % [_stale, _missing_literals])
	get_tree().quit(0)


## Project-wide audit: every .tscn in the project (the vendored addon excluded)
## must have ext_resource uids that still match their assets, not just the two
## scenes this defect named. Read-only, so a later asset re-layout is caught by
## re-running this probe.
func _sweep_scenes() -> void:
	var scenes: Array[String] = []
	_collect_scenes("res://", scenes)
	scenes.sort()
	var audited := 0
	var before := _stale
	for scene_path: String in scenes:
		if scene_path.begins_with("res://addons/"):
			continue
		audited += 1
		_check_scene_uids(scene_path, false)
	print("[SWEEP] scenes=%d stale_in_sweep=%d" % [audited, _stale - before])


func _collect_scenes(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		var full := dir_path.path_join(entry) if dir_path.ends_with("/") else dir_path + "/" + entry
		if dir.current_is_dir():
			_collect_scenes(full, out)
		elif entry.ends_with(".tscn"):
			out.append(full)
		entry = dir.get_next()
	dir.list_dir_end()


## Every ext_resource's declared uid against the engine's own uid for that path.
func _check_scene_uids(scene_path: String, verbose := true) -> void:
	for line: String in _lines(scene_path):
		if not line.begins_with(EXT_RESOURCE_PREFIX):
			continue
		var target := _attr(line, PATH_ATTR)
		if target.is_empty():
			continue
		var declared := _attr(line, UID_ATTR)
		var engine_id := ResourceLoader.get_resource_uid(target)
		if declared.is_empty():
			if verbose:
				print("[UID] %s %s declared=<none> engine=%s OK" % [
					scene_path, target, _uid_text(engine_id),
				])
			continue
		if ResourceUID.text_to_id(declared) == engine_id:
			if verbose:
				print("[UID] %s %s declared=%s engine=%s OK" % [
					scene_path, target, declared, ResourceUID.id_to_text(engine_id),
				])
			continue
		_stale += 1
		print("[UID] %s %s declared=%s engine=%s STALE" % [
			scene_path, target, declared, _uid_text(engine_id),
		])


func _uid_text(id: int) -> String:
	return ResourceUID.id_to_text(id) if id != ResourceUID.INVALID_ID else "<invalid>"


## Engine-side load: any stale uid makes the engine warn on stderr here.
func _load_scene(scene_path: String) -> void:
	var packed: Variant = load(scene_path)
	if packed == null:
		print("[LOAD] %s FAILED" % scene_path)
		return
	var instance: Node = (packed as PackedScene).instantiate()
	print("[LOAD] %s ok (%d ext_resources, %d nodes)" % [
		scene_path, _ext_resource_count(scene_path), _node_count(instance),
	])
	_report_structure(scene_path, instance)
	instance.free()


## The re-save re-serializes the scene; every value a consumer can read must be
## unchanged. Prints each one so a diff of two probe runs proves it.
func _report_structure(scene_path: String, instance: Node) -> void:
	if scene_path.ends_with("player_ship.tscn"):
		var hull: Sprite2D = instance.get_node("Hull")
		var body: RigidBody2D = instance.get_node("HullBody")
		var shape: CollisionShape2D = instance.get_node("HullBody/Shape")
		print("[PROP] player_ship group=%s texture=%s scale=%s layer=%d mask=%d gravity=%s" % [
			instance.is_in_group("player_ship"),
			hull.texture.resource_path,
			hull.scale,
			body.collision_layer,
			body.collision_mask,
			body.gravity_scale,
		])
		print("[PROP] player_ship contact_monitor=%s max_contacts=%d can_sleep=%s damp=lin:%d/ang:%d radius=%.1f" % [
			body.contact_monitor,
			body.max_contacts_reported,
			body.can_sleep,
			body.linear_damp_mode,
			body.angular_damp_mode,
			(shape.shape as CircleShape2D).radius,
		])
		return
	for layer_name: String in ["StarsLayer1", "StarsLayer2", "StarsLayer3"]:
		var stars: TextureRect = instance.get_node(
			"ParallaxBackground/%s/Stars" % layer_name
		)
		var layer: ParallaxLayer = instance.get_node("ParallaxBackground/%s" % layer_name)
		print("[PROP] game %s texture=%s repeat=%d mirror=%s size=%s" % [
			layer_name,
			stars.texture.resource_path,
			stars.texture_repeat,
			layer.motion_mirroring,
			Vector2(stars.offset_right, stars.offset_bottom),
		])


func _ext_resource_count(scene_path: String) -> int:
	var count := 0
	for line: String in _lines(scene_path):
		if line.begins_with(EXT_RESOURCE_PREFIX):
			count += 1
	return count


func _node_count(node: Node) -> int:
	var total := 1
	for child: Node in node.get_children():
		total += _node_count(child)
	return total


## Every res:// literal in the file must resolve as a resource or as a file.
func _check_literals(file_path: String) -> void:
	for path: String in _literals(file_path):
		_checked_literals += 1
		var resolves := ResourceLoader.exists(path) or FileAccess.file_exists(path)
		if not resolves:
			_missing_literals += 1
		print("[LIT] %s %s %s" % [file_path, path, "OK" if resolves else "MISSING"])


func _literals(file_path: String) -> Array[String]:
	var found: Array[String] = []
	for line: String in _lines(file_path):
		var from := 0
		while true:
			var at := line.find("res://", from)
			if at < 0:
				break
			var end := at
			while end < line.length() and not _terminates(line[end]):
				end += 1
			var literal := line.substr(at, end - at)
			if not found.has(literal):
				found.append(literal)
			from = end
	return found


func _terminates(c: String) -> bool:
	return c == "\"" or c == "'" or c == " " or c == "\t" or c == ")" or c == ","


func _attr(line: String, prefix: String) -> String:
	var at := line.find(prefix)
	if at < 0:
		return ""
	var from := at + prefix.length() - "res://".length()
	if prefix == UID_ATTR:
		from = at + "uid=\"".length()
	var end := from
	while end < line.length() and line[end] != "\"":
		end += 1
	return line.substr(from, end - from)


func _lines(path: String) -> Array[String]:
	var out: Array[String] = []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("probe_w2_scene_uids: cannot read %s" % path)
		return out
	while not file.eof_reached():
		out.append(file.get_line())
	file.close()
	return out
