@tool
extends McpTestSuite
## Suite wiring_map: the gate half of `staging/check_wiring.py` (agentic-tooling
## pass 2026-09-26). "Coders wire weirdly" ends here: a wrong path in a hard
## wiring position fails the gate instead of a reviewer's eye. The advisory refs
## (format-string templates, optional user overrides, existence-probed negative
## controls) stay tooling-only; see check_wiring.py's header for the split.
##
## Hard set, mirrored from check_wiring.py:
##   1. every scene under res:// loads as a PackedScene (addons/ vendored, skipped);
##   2. every `preload("res://...")` literal in a script resolves to a file;
##   3. every `[ext_resource ... path="res://..."]` in a scene resolves to a file.
##
## One assert per reference with the offending path in the message, so a red row
## points straight at the broken wire. Nothing here awaits a frame or touches a
## writable store (gate hermeticity, CONTRACTS section 14).

const SKIP_DIRS: PackedStringArray = ["addons", ".godot"]
const PRELOAD_RE := "preload\\(\\s*[\"'](res://[^\"']+)[\"']"
const EXT_RES_RE := "(?m)^\\[ext_resource[^\\]]*path=\"(res://[^\"]+)\""


func test_every_scene_loads() -> void:
	var scenes := _files_with_suffix("res://", ".tscn")
	assert_true(scenes.size() > 0, "scene walk finds scenes")
	for path in scenes:
		var packed := ResourceLoader.load(path)
		assert_true(packed is PackedScene, "scene loads: %s" % path)


func test_script_preloads_resolve() -> void:
	var checked := 0
	for path in _files_with_suffix("res://", ".gd"):
		for ref in _matches(PRELOAD_RE, _code(FileAccess.get_file_as_string(path))):
			checked += 1
			assert_true(FileAccess.file_exists(ref),
				"preload resolves: %s (in %s)" % [ref, path])
	assert_true(checked > 0, "preload walk finds references")


func test_scene_ext_resources_resolve() -> void:
	var checked := 0
	for path in _files_with_suffix("res://", ".tscn"):
		for ref in _matches(EXT_RES_RE, FileAccess.get_file_as_string(path)):
			checked += 1
			assert_true(FileAccess.file_exists(ref),
				"ext_resource resolves: %s (in %s)" % [ref, path])
	assert_true(checked > 0, "ext_resource walk finds references")


func _code(text: String) -> String:
	# Comment text is not code: cut each line at the first `#` so prose that
	# quotes `preload("res://...")` can never fail the walk (mirrors check_wiring.py).
	var lines := text.split("\n")
	for i in lines.size():
		lines[i] = lines[i].split("#")[0]
	return "\n".join(lines)


func _matches(pattern: String, text: String) -> PackedStringArray:
	var re := RegEx.new()
	assert_true(re.compile(pattern) == OK, "regex compiles: %s" % pattern)
	var out := PackedStringArray()
	for m in re.search_all(text):
		out.append(m.get_string(1))
	return out


func _files_with_suffix(root: String, suffix: String) -> PackedStringArray:
	var out := PackedStringArray()
	var stack: Array[String] = [root]
	while not stack.is_empty():
		var dir_path: String = stack.pop_back()
		var dir := DirAccess.open(dir_path)
		if dir == null:
			continue
		dir.list_dir_begin()
		var entry := dir.get_next()
		while entry != "":
			if not entry.begins_with("."):
				var full := dir_path.path_join(entry)
				if dir.current_is_dir():
					if not (dir_path == root and entry in SKIP_DIRS):
						stack.append(full)
				elif entry.ends_with(suffix):
					out.append(full)
			entry = dir.get_next()
		dir.list_dir_end()
	out.sort()
	return out
