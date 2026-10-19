extends RefCounted
## Shared test fixtures (CODE_AUDIT 2026-10-19, P0 item 2). These are the
## self-contained helpers every suite used to copy: the tree lookup, the
## float comparison, the scratch-file delete, the deep compare and the cell
## text read. Suite-local state (profiles, mounted hosts, status arrays) stays
## in its own suite; only the stateless rules live here.
##
## Deliberately not named `test_*`: the runner discovers `test_*.gd` only, so
## this file is a library, not a suite.
##
## Reversal: copy a helper back into the suite that needs it.

static func tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


static func near(measured: float, expected: float, tolerance: float = 0.001) -> bool:
	return absf(measured - expected) <= tolerance


## Remove a scratch file whether the path is res://, user:// or absolute.
static func delete_file(path: String) -> void:
	if path.is_empty():
		return
	var absolute := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute):
		return
	var directory := DirAccess.open(absolute.get_base_dir())
	if directory != null:
		directory.remove(absolute.get_file())


static func deep_eq(a: Variant, b: Variant) -> bool:
	if a is Dictionary and b is Dictionary:
		var left: Dictionary = a
		var right: Dictionary = b
		if left.size() != right.size():
			return false
		for key: Variant in left.keys():
			if not right.has(key):
				return false
			if not deep_eq(left[key], right[key]):
				return false
		return true
	if a is Array and b is Array:
		var left_array: Array = a
		var right_array: Array = b
		if left_array.size() != right_array.size():
			return false
		for index: int in range(left_array.size()):
			if not deep_eq(left_array[index], right_array[index]):
				return false
		return true
	if (a is float) or (b is float):
		return is_equal_approx(float(a), float(b))
	return a == b


static func cell_text(row: Node, cell_name: String) -> String:
	if row == null:
		return ""
	var cell := row.find_child(cell_name, true, false) as Control
	if cell == null:
		return ""
	var value := cell.get_node_or_null(^"Value") as Label
	return value.text if value != null else ""


## The live profile autoload, or null when the tree is not up yet.
static func profile() -> Node:
	var scene_tree := tree()
	if scene_tree == null:
		return null
	return scene_tree.root.get_node_or_null(NodePath(&"PlayerProfile"))


## The fixture host the suites mount into: the profile autoload when it exists,
## the tree root otherwise (the runner calls every test from inside its own
## `_ready`, when `/root` is still busy).
static func fixture_host() -> Node:
	var scene_tree := tree()
	if scene_tree == null:
		return null
	var root := scene_tree.root
	var host := root.get_node_or_null(NodePath(&"PlayerProfile"))
	return host if host != null else root


## The live audio autoload, or null.
static func audio(service: StringName = &"AudioManager") -> Node:
	var scene_tree := tree()
	if scene_tree == null:
		return null
	return scene_tree.root.get_node_or_null(NodePath(service))
