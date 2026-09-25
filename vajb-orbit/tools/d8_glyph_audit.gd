extends Node
## D8-B1's 1080p glyph audit (wave D8 item 10): measures every in-flight HUD
## text/glyph row against the wave's floor - cap height in pixels at 1920x1080,
## ui_scale 1.0 - and prints the table the report carries.
##
##   XDG_DATA_HOME=/tmp/d8audit "$GODOT_CONSOLE" --headless --path "$VAJB_PROJ" \
##     res://tools/d8_glyph_audit.tscn --quit-after 600
##
## It runs as a scene so the HUD's autoload reads compile in the normal project
## context (a bare --script run cannot resolve `SettingsManager`).
##
## Definitions (the ones the report and test use):
## - TEXT cap height: the rasterised ink height of a capital "H" at the row's
##   resolved font and size, read from the face's own glyph contours through the
##   text server, so the number is the face's real cap (Rajdhani ~0.65 em,
##   Oxanium ~0.69 em), not an ascent estimate.
## - GLYPH cap height: the drawn ink height of the mark at 1920x1080. Both the
##   full ink box and the dark knocked-out stroke box print (the zoom icons knock
##   their mark out of a plate), so a reviewer can re-measure either definition.
## - Rows hidden by the D7 retirement print `visible=false` so the sweep covers
##   the documented un-hide reversal too.

const HudScene := preload("res://ui/hud/hud.tscn")
const HudTheme := preload("res://ui/theme/vajb_theme.tres")

const TAG := "[D8AUDIT]"
const DARK_LUMA := 0.35
const VIEWPORT := Vector2(1920.0, 1080.0)
const CALIBRATION_SIZES: Array[int] = [10, 11, 13, 14, 16, 18, 20, 22]
const CALIBRATION_FACES: Array[String] = [
	"res://assets/fonts/Rajdhani-Regular.ttf",
	"res://assets/fonts/Rajdhani-Medium.ttf",
	"res://assets/fonts/Rajdhani-SemiBold.ttf",
	"res://assets/fonts/Oxanium[wght].ttf",
	"res://assets/fonts/SairaStencilOne-Regular.ttf",
]


func _ready() -> void:
	_calibrate()
	var hud: Control = HudScene.instantiate() as Control
	hud.theme = HudTheme
	add_child(hud)
	hud.size = VIEWPORT
	await get_tree().process_frame
	await get_tree().process_frame
	print("%s viewport=%.0fx%.0f ui_scale=1.0" % [TAG, VIEWPORT.x, VIEWPORT.y])
	_walk(hud)
	print("%s done" % TAG)
	get_tree().quit(0)


## The cap height of every shipped face at every size the HUD family uses: the
## number the table's `cap` column is read against.
func _calibrate() -> void:
	for face_path: String in CALIBRATION_FACES:
		var font: FontFile = load(face_path) as FontFile
		var caps: Array[String] = []
		for size: int in CALIBRATION_SIZES:
			caps.append("%d:%.2f" % [size, cap_height(font, size)])
		print("%s CAL %s %s" % [TAG, face_path.get_file(), " ".join(caps)])


func _walk(node: Node) -> void:
	for child: Node in node.get_children():
		if child is Label:
			_report_label(child as Label)
		elif child is TextureRect:
			_report_texture(child as TextureRect)
		elif child is TextureButton:
			_report_button(child as TextureButton)
		elif child.has_method(&"zoom_mark_rects"):
			print("%s MARK %s rects=%s" % [TAG, child.get_path(), str(child.call(&"zoom_mark_rects"))])
		_walk(child)


func _report_label(label: Label) -> void:
	var font: Font = label.get_theme_font(&"font")
	var size: int = label.get_theme_font_size(&"font_size")
	var cap: float = cap_height(font, size)
	print(
		"%s TEXT %s var=%s font=%s size=%d cap=%.2f visible=%s"
		% [
			TAG,
			_path(label),
			String(label.theme_type_variation),
			_font_name(font),
			size,
			cap,
			str(label.visible),
		]
	)


func _report_texture(rect: TextureRect) -> void:
	if rect.texture == null:
		return
	var drawn: Vector2 = rect.size if rect.size.x > 0.0 else rect.custom_minimum_size
	_report_mark(_path(rect), rect.texture, drawn)


func _report_button(button: TextureButton) -> void:
	if button.texture_normal == null:
		return
	var drawn: Vector2 = button.size if button.size.x > 0.0 else button.custom_minimum_size
	_report_mark(_path(button), button.texture_normal, drawn)


func _report_mark(path: String, texture: Texture2D, drawn: Vector2) -> void:
	var tex_size: Vector2 = texture.get_size()
	var image: Image = texture.get_image()
	if image == null:
		print("%s GLYPH %s tex=%.0fx%.0f drawn=%.0fx%.0f (no image)" % [TAG, path, tex_size.x, tex_size.y, drawn.x, drawn.y])
		return
	var scale: float = drawn.y / tex_size.y if tex_size.y > 0.0 else 1.0
	var full: Rect2i = ink_bbox(image, false)
	var dark: Rect2i = ink_bbox(image, true)
	print(
		"%s GLYPH %s tex=%.0fx%.0f drawn=%.0fx%.0f ink=%.1fpx dark_mark=%.1fpx"
		% [
			TAG,
			path,
			tex_size.x,
			tex_size.y,
			drawn.x,
			drawn.y,
			float(full.size.y) * scale,
			float(dark.size.y) * scale if dark.size.y > 0 else 0.0,
		]
	)


func _path(node: Node) -> String:
	var full: NodePath = node.get_path()
	var names: PackedStringArray = full.get_concatenated_names().split("/")
	return "/".join(names.slice(maxi(names.size() - 3, 0)))


## The ink bbox of a texture's pixels: everything not transparent, or - when
## `dark_only` - the dark knocked-out strokes that identify the mark.
static func ink_bbox(image: Image, dark_only: bool) -> Rect2i:
	var box := Rect2i(0, 0, 0, 0)
	var found := false
	for y: int in image.get_height():
		for x: int in image.get_width():
			var pixel: Color = image.get_pixel(x, y)
			var hit: bool = pixel.a > 0.02
			if dark_only:
				var luma: float = pixel.r * 0.2126 + pixel.g * 0.7152 + pixel.b * 0.0722
				hit = pixel.a > 0.02 and luma < DARK_LUMA
			if not hit:
				continue
			if not found:
				box = Rect2i(x, y, 1, 1)
				found = true
			else:
				box = box.expand(Vector2i(x, y))
	return box


## The rasterised cap height: the ink box of the face's capital "H" through the
## text server's glyph contours. Static so the D8 suite measures with the exact
## same definition (tools/d8_glyph_audit.gd is that definition's one home).
static func cap_height(font: Font, size: int) -> float:
	var ts: TextServer = TextServerManager.get_primary_interface()
	if ts == null or font == null or size <= 0:
		return 0.0
	var measured: float = _cap_from_rids(ts, font.get_rids(), size)
	if measured >= 0.0:
		return measured
	if font is FontVariation:
		var base: Font = (font as FontVariation).base_font
		if base != null:
			return _cap_from_rids(ts, base.get_rids(), size)
	return -1.0


static func _cap_from_rids(ts: TextServer, rids: Array[RID], size: int) -> float:
	for rid: RID in rids:
		var index: int = ts.font_get_glyph_index(rid, size, "H".unicode_at(0), 0)
		if index == 0:
			continue
		var contours: Dictionary = ts.font_get_glyph_contours(rid, size, index)
		var points: PackedVector3Array = contours.get("points", PackedVector3Array())
		if points.is_empty():
			continue
		var top: float = points[0].y
		var bottom: float = points[0].y
		for point: Vector3 in points:
			top = minf(top, point.y)
			bottom = maxf(bottom, point.y)
		return absf(bottom - top)
	return -1.0


func _font_name(font: Font) -> String:
	if font is FontVariation:
		return "Var(%s)" % _font_name((font as FontVariation).base_font)
	if font is FontFile:
		return String((font as FontFile).resource_path).get_file()
	return font.get_class()
