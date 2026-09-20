extends SceneTree
## Derives the white-stencil tint variants of the icon set: RGB = (1, 1, 1) with the
## alpha byte preserved from the source art, so icons can be tinted with theme colours.
## Contract: docs/design/IMPLEMENTATION_PLAN.md section 3.3.

const SOURCE_DIR := "res://assets/icons"
const TINT_DIR := "res://assets/icons/tint"
const PREFIX := "icon_"
const SIZE_SUFFIXES: Array[String] = ["_16.png", "_48.png", "_96.png", "_192.png"]
const CHANNELS := 4
const ALPHA_OFFSET := 3


func _initialize() -> void:
	_run()
	quit()


func _run() -> void:
	var sources: PackedStringArray = _collect_sources()
	if sources.is_empty():
		printerr("derive_icon_tints: no icon sources found in %s" % SOURCE_DIR)
		return
	if not DirAccess.dir_exists_absolute(TINT_DIR):
		var dir_error: int = DirAccess.make_dir_recursive_absolute(TINT_DIR)
		if dir_error != OK:
			printerr("derive_icon_tints: cannot create %s (error %d)" % [TINT_DIR, dir_error])
			return
	var written: int = 0
	var failed: int = 0
	for path: String in sources:
		if _derive(path):
			written += 1
		else:
			failed += 1
	print("[tint] %d of %d sources written to %s" % [written, sources.size(), TINT_DIR])
	if failed > 0:
		printerr("[tint] FAILED for %d of %d sources" % [failed, sources.size()])


func _collect_sources() -> PackedStringArray:
	var names: PackedStringArray = PackedStringArray()
	var dir: DirAccess = DirAccess.open(SOURCE_DIR)
	if dir == null:
		printerr("derive_icon_tints: cannot open %s" % SOURCE_DIR)
		return names
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and _is_icon_source(entry):
			names.append(entry)
		entry = dir.get_next()
	dir.list_dir_end()
	names.sort()
	var paths: PackedStringArray = PackedStringArray()
	for name: String in names:
		paths.append(SOURCE_DIR + "/" + name)
	return paths


func _is_icon_source(entry: String) -> bool:
	if not entry.begins_with(PREFIX):
		return false
	for suffix: String in SIZE_SUFFIXES:
		if entry.ends_with(suffix):
			return true
	return false


func _derive(source_path: String) -> bool:
	var file_name: String = source_path.get_file()
	var source: Image = Image.load_from_file(ProjectSettings.globalize_path(source_path))
	if source == null:
		printerr("[tint] %s: cannot load source image" % file_name)
		return false
	source.convert(Image.FORMAT_RGBA8)
	var reference: Image = Image.load_from_file(ProjectSettings.globalize_path(source_path))
	reference.convert(Image.FORMAT_RGBA8)
	var width: int = source.get_width()
	var height: int = source.get_height()
	var pixels: PackedByteArray = source.get_data()
	for index: int in range(0, pixels.size(), CHANNELS):
		pixels[index] = 255
		pixels[index + 1] = 255
		pixels[index + 2] = 255
	var tinted: Image = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, pixels)
	if not _alpha_matches(reference.get_data(), tinted.get_data()):
		printerr("[tint] %s: ABORTED, alpha channel changed" % file_name)
		return false
	var output_path: String = TINT_DIR + "/" + file_name
	var save_error: int = tinted.save_png(output_path)
	if save_error != OK:
		printerr("[tint] %s: save failed (error %d)" % [file_name, save_error])
		return false
	print("[tint] %s -> %s (%dx%d, alpha preserved)" % [file_name, output_path, width, height])
	return true


func _alpha_matches(reference: PackedByteArray, candidate: PackedByteArray) -> bool:
	if reference.size() != candidate.size():
		return false
	for index: int in range(ALPHA_OFFSET, reference.size(), CHANNELS):
		if reference[index] != candidate[index]:
			return false
	return true
