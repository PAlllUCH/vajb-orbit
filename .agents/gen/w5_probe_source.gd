extends SceneTree
## Throwaway W5 probe (deleted with its .uid after the run). Prints what the regenerated
## theme resolves to: the default face, every variation's face and size, the theme versus
## Router font-size item coverage, and the face the three edited scenes resolve at runtime.

const PATHS := preload("res://ui/paths.gd")

const VARIATIONS: Array[StringName] = [
	&"ScreenTitle",
	&"SectionHeader",
	&"HudReadout",
	&"DialogTitle",
	&"Version",
	&"HeroTitle",
	&"StationPanelTitle",
	&"StationValue",
	&"StationCaption",
	&"FlavourText",
	&"MenuButtonPlate",
	&"Label",
]

const TARGETS: Array[Dictionary] = [
	{
		&"scene": "res://ui/screens/main_menu.tscn",
		&"path": "%FocusReadout",
		&"note": "read-out",
		&"plate": "%PlayButton",
	},
	{
		&"scene": "res://ui/screens/station.tscn",
		&"path": "Layout/Page/Header/TitleBox/StationLocation",
		&"note": "station subline",
	},
	{
		&"scene": "res://ui/hud/hud.tscn",
		&"path": "CanvasLayer/BottomRight/MinimapPanel/MinimapBox/MinimapFooter/SectorLabel",
		&"note": "minimap sector label",
	},
]

var _theme: Theme


func _initialize() -> void:
	_run()


func _run() -> void:
	_theme = load(PATHS.THEME) as Theme
	if _theme == null:
		print("[w5] theme failed to load")
		quit()
		return
	print("[w5] theme path = %s" % PATHS.THEME)
	print("[w5] default_font = %s" % _face(_theme.default_font))
	print("[w5] default_font_size = %d" % _theme.default_font_size)
	for variation: StringName in VARIATIONS:
		print("[w5] %s -> %s @ %d colour %s" % [
			String(variation),
			_face(_theme.get_font(&"font", variation)),
			_theme.get_font_size(&"font_size", variation),
			_theme.get_color(&"font_color", variation),
		])
	_report_coverage()
	await _report_scenes()
	quit()


func _report_coverage() -> void:
	var theme_items: Dictionary = {}
	for type: StringName in _theme.get_font_size_type_list():
		for item: StringName in _theme.get_font_size_list(type):
			theme_items["%s/%s" % [String(type), String(item)]] = true
	var router_items: Dictionary = {}
	for entry: Dictionary in Router.FONT_SIZE_ITEMS:
		router_items["%s/%s" % [String(entry[&"type"]), String(entry[&"item"])]] = true
	var theme_only: Array[String] = []
	var router_only: Array[String] = []
	for key: String in theme_items:
		if not router_items.has(key):
			theme_only.append(key)
	for key: String in router_items:
		if not theme_items.has(key):
			router_only.append(key)
	theme_only.sort()
	router_only.sort()
	print("[w5] theme font-size items = %d, Router.FONT_SIZE_ITEMS = %d" % [theme_items.size(), router_items.size()])
	print("[w5] in theme not in router = %d %s" % [theme_only.size(), theme_only])
	print("[w5] in router not in theme = %d %s" % [router_only.size(), router_only])
	print("[w5] FlavourText in Router = %s" % str(router_items.has("FlavourText/font_size")))


func _report_scenes() -> void:
	for target: Dictionary in TARGETS:
		var packed: PackedScene = load(target[&"scene"]) as PackedScene
		if packed == null:
			print("[w5] %s failed to load" % target[&"scene"])
			continue
		var instance: Node = packed.instantiate()
		root.add_child(instance)
		await process_frame
		await process_frame
		var node: Node = instance.get_node_or_null(NodePath(target[&"path"]))
		if node == null:
			print("[w5] %s (%s): node %s not found" % [target[&"note"], target[&"scene"], target[&"path"]])
		else:
			var label := node as Label
			print("[w5] %s (%s): variation=%s face=%s size=%d text=%s" % [
				target[&"note"],
				target[&"scene"].get_file(),
				String(label.theme_type_variation),
				_face(label.get_theme_font(&"font")),
				label.get_theme_font_size(&"font_size"),
				label.text,
			])
		if target.has(&"plate"):
			_report_plate(instance, target[&"plate"])
		instance.queue_free()
		await process_frame


## The plate row height follows its font above the 70 px art floor (MAIN_MENU_V2 section
## 12.1), so the display face is measured here rather than assumed.
func _report_plate(instance: Node, path: NodePath) -> void:
	var plate: Control = instance.get_node_or_null(path) as Control
	if plate == null:
		print("[w5] plate %s not found" % String(path))
		return
	var button: Button = plate.get_node_or_null(^"Button") as Button
	print("[w5] PLAY row: plate size=%s custom_minimum=%s inner min=%s font=%s @%d" % [
		str(plate.size),
		str(plate.custom_minimum_size),
		str(button.get_minimum_size()) if button != null else "<no Button>",
		_face(button.get_theme_font(&"font")) if button != null else "<none>",
		button.get_theme_font_size(&"font_size") if button != null else -1,
	])


func _face(font: Font) -> String:
	if font == null:
		return "<none>"
	if font is FontVariation:
		var variation := font as FontVariation
		return "%s over %s opentype=%s" % [
			variation.get_class(),
			_face(variation.base_font),
			str(variation.variation_opentype),
		]
	if font.resource_path.is_empty():
		return "%s (embedded)" % font.get_class()
	return font.resource_path
