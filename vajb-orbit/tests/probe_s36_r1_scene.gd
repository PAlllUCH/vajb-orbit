extends Node
## S36-R1's independent scene probe, pass 2: only the ACTIVE pane per deck is measured,
## after two real layout frames, so every printed rect is the live drawn geometry.
## Prints unique surface records, the C5 bay rects at layout time, the backdrop boxes
## against the pinned 1765x753 content box, and the tooltip's real height.

const StationScene := preload("res://ui/screens/station.tscn")
const StationScript := preload("res://ui/screens/station.gd")
const ChromeFamily := preload("res://ui/theme/chrome_family.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")

const PROFILE_PATH := "user://probe_s36_r1.cfg"
const HOST := Vector2(1920.0, 1080.0)
const SHIP: StringName = &"ship_vanguard"

var _profile: Node = null
var _screen: Control = null


func _ready() -> void:
	var watchdog := get_tree().create_timer(150.0)
	watchdog.timeout.connect(func() -> void:
		print("[r36] WATCHDOG quit")
		get_tree().quit(2)
	)
	_run.call_deferred()


func _run() -> void:
	_profile = get_node_or_null("/root/PlayerProfile")
	if _profile == null:
		print("[r36] FAIL no PlayerProfile autoload")
		get_tree().quit(2)
		return
	_profile.set(&"save_path", PROFILE_PATH)
	_profile.set(&"_active_ship", SHIP)
	_profile.set(&"_owned_ships", [SHIP] as Array[StringName])
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_credits", 50000)

	var host := Control.new()
	host.name = "R36Host"
	host.theme = ThemeRes
	host.size = HOST
	add_child(host)
	_screen = StationScene.instantiate() as Control
	host.add_child(_screen)
	await _frames(2)

	var module_host := _screen.get_node("%ModuleHost") as PanelContainer
	var host_style := module_host.get_theme_stylebox(&"panel")
	print("[r36] module_host size=%s style=%s" % [module_host.size,
		host_style.get_class() if host_style != null else "none"])
	var host_margin := module_host.get_node("%HostMargin") as Control
	print("[r36] host_margin size=%s" % host_margin.size)

	for deck in range(0, 7):
		_screen.call(&"_select_module", deck, true)
		await _frames(2)
		var pane := _pane(deck)
		if pane == null:
			print("[r36] FAIL deck %d no pane" % deck)
			continue
		var seen: Dictionary = {}
		_walk(pane, deck, seen)
		for key: String in seen:
			print("[r36] %s" % key)
		if deck == 0:
			_report_bays(pane)
		_report_backdrops(deck)

	var tooltip := _screen.get(&"_tooltip") as PanelContainer
	if tooltip != null:
		tooltip.call(&"show_for", "PROBE", "short body", false, Vector2(10, 10), HOST)
		await _frames(2)
		print("[r36] tooltip size=%s" % tooltip.size)
		tooltip.call(&"hide_tooltip")

	var entries: Array = _screen.call(&"drawer_entries")
	var sizes: Dictionary = {}
	for entry in entries:
		var button := entry as Control
		var canvas := button.get_node_or_null(NodePath("ChromeCanvas")) as TextureRect
		if canvas == null:
			print("[r36] entry %s NO CANVAS" % button.name)
			continue
		var fit := ChromeFamily.canvas_rect(button.size, "C9")
		sizes["%s slot=%s drawn=%s" % [button.name, button.size, fit.size]] = true
	for key: String in sizes:
		print("[r36] entry %s" % key)

	get_tree().quit(0)


func _frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame


func _pane(deck: int) -> Node:
	var panes: Array = _screen.get(&"_panels")
	if deck < 0 or deck >= panes.size():
		return null
	return panes[deck] as Node


func _walk(node: Node, deck: int, seen: Dictionary) -> void:
	if node is Control:
		var control := node as Control
		if control.is_visible_in_tree():
			var cls := String(control.get_meta(&"chrome_class", ""))
			if not cls.is_empty():
				_record_plate(control, cls, deck, seen)
			if control.name == StringName("ChromeCanvas") and control is TextureRect:
				_record_canvas(control as TextureRect, control.get_parent() as Control, deck, seen)
		for child in node.get_children():
			_walk(child, deck, seen)
	if node.name == StringName("RowPlate") or node.name == StringName("ConsolePanels"):
		var ctrl := node as Control
		_record("coded-draw deck=%d node=%s size=%s visible=%s" % [deck, node.name, ctrl.size,
			_yn(ctrl.is_visible_in_tree())], seen)


func _record(line: String, seen: Dictionary) -> void:
	seen[line] = true


func _record_plate(control: Control, cls: String, deck: int, seen: Dictionary) -> void:
	var box := control.get_theme_stylebox(&"normal")
	if box == null:
		box = control.get_theme_stylebox(&"panel")
	var margin_l := 0.0
	var margin_t := 0.0
	var margin_r := 0.0
	var margin_b := 0.0
	var tex := ""
	if box is StyleBoxTexture:
		var sbt := box as StyleBoxTexture
		margin_l = sbt.texture_margin_left
		margin_t = sbt.texture_margin_top
		margin_r = sbt.texture_margin_right
		margin_b = sbt.texture_margin_bottom
		tex = sbt.texture.resource_path.get_file() if sbt.texture != null else ""
	var size := control.size
	var key := "plate cls=%s size=%sx%.0f margins=%.0f/%.0f/%.0f/%.0f tex=%s degen_v=%s degen_h=%s node=%s/%s" % [
		cls, size.x, size.y, margin_l, margin_t, margin_r, margin_b, tex,
		_yn(size.y < margin_t + margin_b), _yn(size.x < margin_l + margin_r),
		control.get_parent().name, control.name]
	_record(key, seen)


func _record_canvas(canvas: TextureRect, parent: Control, deck: int, seen: Dictionary) -> void:
	var cls := String(canvas.get_meta(&"chrome_class", ""))
	var slot := parent.size
	var fit := ChromeFamily.canvas_rect(slot, cls)
	var cut_aspect := ChromeFamily.cut_aspect(cls)
	var aspect_err := -1.0
	if cut_aspect > 0.0 and fit.size.y > 0.0:
		aspect_err = absf(fit.size.x / fit.size.y - cut_aspect) / cut_aspect
	var key := "canvas cls=%s slot=%.0fx%.0f drawn=%.1fx%.1f aspect_err=%.5f tex=%s node=%s/%s" % [
		cls, slot.x, slot.y, fit.size.x, fit.size.y, aspect_err,
		(canvas.texture.resource_path if canvas.texture != null else "").get_file(),
		parent.get_parent().name, parent.name]
	_record(key, seen)


func _report_bays(pane: Node) -> void:
	var chrome := pane.get(&"_chrome") as Node
	if chrome == null:
		print("[r36] bays FAIL no ConsolePanels")
		return
	var bays: Array[Rect2] = chrome.get(&"bays")
	for rect in bays:
		var fit := ChromeFamily.canvas_rect(rect.size, "C5")
		print("[r36] bay rect=%s pos=%s drawn=%s" % [rect.size, rect.position, fit.size])


func _report_backdrops(deck: int) -> void:
	var module_host := _screen.get_node("%ModuleHost") as Control
	var backdrops: Dictionary = _screen.get(&"_backdrops")
	var active := String(StationScript.DECK_BACKDROP.get(deck, ""))
	for bg_id: String in backdrops:
		var layer := backdrops[bg_id] as TextureRect
		print("[r36] backdrop deck=%d bg=%s active=%s visible=%s size=%s pos=%s stretch=%d filter=%d index=%d" % [
			deck, bg_id, active, _yn(layer.visible), layer.size, layer.position,
			layer.stretch_mode, layer.mouse_filter, layer.get_index()])


func _yn(v: bool) -> String:
	return "Y" if v else "n"
