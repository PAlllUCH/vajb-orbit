extends SceneTree

## D4c geometry probe. Instantiates the mockup at 1920 x 1080, prints every relevant
## Control rect at ui_scale 1.0 / 1.2 / 1.4 / 2.0 by re-assigning a theme scaled the way
## Router._scale_font_sizes scales it, so the font-driven row height can be read directly.

const MOCKUP := "res://ui/screens/_mockup_main_menu.tscn"
const THEME_SRC := "res://ui/theme/vajb_theme.tres"

const ITEMS: Array[Dictionary] = [
	{&"type": &"Button", &"item": &"font_size"},
	{&"type": &"DialogTitle", &"item": &"font_size"},
	{&"type": &"HudReadout", &"item": &"font_size"},
	{&"type": &"Label", &"item": &"font_size"},
	{&"type": &"MenuButton", &"item": &"font_size"},
	{&"type": &"MenuButtonPlate", &"item": &"font_size"},
	{&"type": &"SectionHeader", &"item": &"font_size"},
	{&"type": &"Version", &"item": &"font_size"},
]

const PATHS: Array[String] = [
	"SafeArea",
	"SafeArea/Bands",
	"SafeArea/Bands/HeaderBand",
	"SafeArea/Bands/HeaderBand/Logo",
	"SafeArea/Bands/MiddleBand",
	"SafeArea/Bands/MiddleBand/CommandColumn",
	"SafeArea/Bands/MiddleBand/CommandColumn/CommandHeader",
	"SafeArea/Bands/MiddleBand/CommandColumn/CommandHeader/HeaderGutter",
	"SafeArea/Bands/MiddleBand/CommandColumn/CommandHeader/InsigniaBadge",
	"SafeArea/Bands/MiddleBand/CommandColumn/VerbStack",
	"SafeArea/Bands/MiddleBand/CommandColumn/VerbStack/PlayRow",
	"SafeArea/Bands/MiddleBand/CommandColumn/VerbStack/PlayRow/PlayTick",
	"SafeArea/Bands/MiddleBand/CommandColumn/VerbStack/PlayRow/PlayButton",
	"SafeArea/Bands/MiddleBand/CommandColumn/VerbStack/PlayRow/PlayButton/Button",
	"SafeArea/Bands/MiddleBand/CommandColumn/VerbStack/OptionsRow",
	"SafeArea/Bands/MiddleBand/CommandColumn/VerbStack/OptionsRow/OptionsTick",
	"SafeArea/Bands/MiddleBand/CommandColumn/VerbStack/OptionsRow/OptionsButton",
	"SafeArea/Bands/MiddleBand/CommandColumn/VerbStack/OptionsRow/OptionsButton/Button",
	"SafeArea/Bands/MiddleBand/CommandColumn/VerbStack/ExitRow",
	"SafeArea/Bands/MiddleBand/CommandColumn/VerbStack/ExitRow/ExitTick",
	"SafeArea/Bands/MiddleBand/CommandColumn/VerbStack/ExitRow/ExitButton",
	"SafeArea/Bands/MiddleBand/CommandColumn/VerbStack/ExitRow/ExitButton/Button",
	"SafeArea/Bands/FooterBand",
	"SafeArea/Bands/FooterBand/FocusReadout",
	"SafeArea/Bands/FooterBand/VersionLabel",
]

var _scene: Control
var _steps: Array[Callable] = []
var _wait: int = 3


func _initialize() -> void:
	_scene = load(MOCKUP).instantiate() as Control
	root.add_child(_scene)
	for scale: float in [1.0, 1.2, 1.4, 2.0]:
		_steps.append(_apply.bind(scale))
		_steps.append(_dump.bind(scale))


func _process(_delta: float) -> bool:
	if _wait > 0:
		_wait -= 1
		return false
	if _steps.is_empty():
		quit()
		return true
	var step: Callable = _steps.pop_front()
	step.call()
	_wait = 3
	return false


func _apply(scale: float) -> void:
	var theme := load(THEME_SRC).duplicate() as Theme
	theme.default_font_size = roundi(14.0 * scale)
	for entry: Dictionary in ITEMS:
		var type: StringName = entry[&"type"]
		var item: StringName = entry[&"item"]
		if theme.has_font_size(item, type):
			theme.set_font_size(item, type, roundi(float(theme.get_font_size(item, type)) * scale))
	_scene.theme = theme


func _dump(scale: float) -> void:
	var viewport: Vector2 = _scene.get_viewport_rect().size
	print("== ui_scale %.1f == viewport %s" % [scale, str(viewport)])
	print("  fonts: MenuButtonPlate %d HudReadout %d Label %d Version %d" % [
		_scene.get_theme_font_size(&"font_size", &"MenuButtonPlate"),
		_scene.get_theme_font_size(&"font_size", &"HudReadout"),
		_scene.get_theme_font_size(&"font_size", &"Label"),
		_scene.get_theme_font_size(&"font_size", &"Version")])
	for path: String in PATHS:
		var node := _scene.get_node_or_null(NodePath(path)) as Control
		if node == null:
			print("  MISSING %s" % path)
			continue
		var rect: Rect2 = node.get_global_rect()
		print("  %-16s pos %8s size %10s min %10s global [P: %s, S: %s]" % [
			node.name, str(node.position), str(node.size),
			str(node.get_combined_minimum_size()), str(rect.position), str(rect.size)])
	var row1 := _scene.get_node_or_null(NodePath(PATHS[10])) as Control
	var row2 := _scene.get_node_or_null(NodePath(PATHS[14])) as Control
	var row3 := _scene.get_node_or_null(NodePath(PATHS[18])) as Control
	var plate := _scene.get_node_or_null(NodePath(PATHS[12])) as Control
	var inner := _scene.get_node_or_null(NodePath(PATHS[13])) as Control
	if row1 != null and row2 != null and row3 != null and plate != null and inner != null:
		print("  rows tops %.1f / %.1f / %.1f, row heights %.1f %.1f %.1f" % [
			row1.global_position.y, row2.global_position.y, row3.global_position.y,
			row1.size.y, row2.size.y, row3.size.y])
		print("  stack pitch %.1f and %.1f, visible gap %.1f and %.1f" % [
			row2.global_position.y - row1.global_position.y,
			row3.global_position.y - row2.global_position.y,
			row2.global_position.y - row1.global_position.y - row1.size.y,
			row3.global_position.y - row2.global_position.y - row2.size.y])
		print("  plate min %s, inner Button font-driven min %s, inner Button rect pos %s size %s" % [
			str(plate.get_combined_minimum_size()), str(inner.get_minimum_size()),
			str(inner.position), str(inner.size)])
