extends Node
## P2-B1 R1 review probe, fifth pass: the rendered construct, read off the laid-out pane
## rather than from the scene file. Verifies STATION_HUB section 5.1's render order (the
## FITTED WEAPONS strip, then the MODULES rows, then the ammo rows), the 48 px module icon
## column against the ammo rows' 40 px, the two headers' alignment with their own rows,
## and CELL_SEPARATION 2.
##
##   godot --headless --path vajb-orbit res://tests/probe_r1_p2b1_layout.tscn

const PanelScene := preload("res://ui/station/outfitting_panel.tscn")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const Log := preload("res://game/economy_log.gd")

const SCRATCH := "user://probe_r1_p2b1_layout.cfg"
const LOG_SCRATCH := "user://probe_r1_p2b1_layout.log"
const VANGUARD: StringName = &"ship_vanguard"

var _profile: Node = null
var _host: Control = null
var _panel: Control = null
var _saved: Dictionary = {}


func _ready() -> void:
	_profile = get_tree().root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		print("[r1e] FAILED: no PlayerProfile autoload")
		get_tree().quit()
		return
	_borrow()
	await _layout()
	_read_off()
	_restore()
	print("[r1e] == done ==")
	get_tree().quit()


func _borrow() -> void:
	_saved = {
		&"path": String(_profile.get(&"save_path")),
		&"credits": int(_profile.call(&"credits")),
		&"ship": StringName(_profile.call(&"active_ship")),
		&"owned": _profile.call(&"owned_ships"),
		&"fits": _profile.call(&"fits"),
		&"modules": _profile.call(&"modules"),
	}
	Log.log_path = LOG_SCRATCH
	_profile.set(&"save_path", SCRATCH)
	_remove(SCRATCH)
	_profile.set(&"_credits", 40000)
	_profile.set(&"_active_ship", VANGUARD)
	_profile.set(&"_owned_ships", [VANGUARD] as Array[StringName])
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_host = Control.new()
	_host.name = "R1eHost"
	_host.theme = ThemeRes
	_host.size = Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width", 1920)),
		float(ProjectSettings.get_setting("display/window/size/viewport_height", 1080))
	)
	add_child(_host)
	_panel = PanelScene.instantiate() as Control
	_host.add_child(_panel)
	_profile.connect(&"profile_changed", Callable(_panel, &"refresh_profile"))


func _layout() -> void:
	for frame in 12:
		await get_tree().process_frame


func _restore() -> void:
	_profile.set(&"_credits", int(_saved[&"credits"]))
	_profile.set(&"_active_ship", StringName(_saved[&"ship"]))
	_profile.set(&"_owned_ships", _saved[&"owned"])
	_profile.set(&"_fits", _saved[&"fits"])
	_profile.set(&"_modules", _saved[&"modules"])
	_profile.call(&"flush")
	_profile.set(&"save_path", String(_saved[&"path"]))
	_remove(SCRATCH)
	_remove(LOG_SCRATCH)


func _remove(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


func _rect(node: Control) -> String:
	var position := node.global_position
	var size := node.size
	return "pos=(%.0f,%.0f) size=(%.0f,%.0f)" % [position.x, position.y, size.x, size.y]


func _read_off() -> void:
	print("[r1e] panel %s" % _rect(_panel))
	var body := _panel.get_node_or_null("OutfittingScroll/OutfittingBody") as VBoxContainer
	print("[r1e] body children (render order, top to bottom):")
	for child: Node in body.get_children():
		var control := child as Control
		var extra := ""
		if control is Label:
			extra = " text='%s'" % (control as Label).text
		print("[r1e]   %s (%s) visible=%s %s%s" % [
			control.name, control.get_class(), str(control.visible), _rect(control), extra
		])
	var strip := _panel.get_node("%FittedStrip") as VBoxContainer
	print("[r1e] strip lines:")
	for child: Node in strip.get_children():
		var line := child as HBoxContainer
		var text := line.get_node_or_null(^"Text") as Label
		var remove := line.get_node_or_null(^"Remove") as Button
		print("[r1e]   %s visible=%s %s text='%s' remove_visible=%s remove=%s" % [
			line.name, str(line.visible), _rect(line), text.text,
			str(remove.visible), _rect(remove)
		])
	var rows := _panel.get_node("%ModuleRows") as VBoxContainer
	print("[r1e] module rows (top to bottom):")
	for child: Node in rows.get_children():
		var row := child as Button
		var icon := row.find_child("Icon", true, false) as TextureRect
		print("[r1e]   %s %s icon=%s action_label_width=%.0f" % [
			row.name, _rect(row),
			_rect(icon) if icon != null else "<none>",
			(row.find_child("Action", true, false) as Control).size.x if row.find_child("Action", true, false) != null else -1.0
		])
	var ammo := _panel.get_node("%OutfittingRows") as VBoxContainer
	print("[r1e] ammo rows (top to bottom):")
	for child: Node in ammo.get_children():
		var row := child as Button
		if row == null:
			print("[r1e]   %s (%s) slack" % [child.name, child.get_class()])
			continue
		var icon := row.find_child("Icon", true, false) as TextureRect
		print("[r1e]   %s %s icon=%s" % [
			row.name, _rect(row), _rect(icon) if icon != null else "<none>"
		])
	print("[r1e] separation constants: body=%d strip=%d module_rows=%d modules_box=%d ammo_rows=%d" % [
		body.get_theme_constant(&"separation"),
		strip.get_theme_constant(&"separation"),
		rows.get_theme_constant(&"separation"),
		(_panel.get_node("OutfittingScroll/OutfittingBody/ModulesMargin/ModulesBox") as VBoxContainer)
			.get_theme_constant(&"separation"),
		ammo.get_theme_constant(&"separation"),
	])
	var module_header := _panel.get_node("%ModulesHeader") as HBoxContainer
	var ammo_header := _panel.get_node("%OutfittingHeader") as HBoxContainer
	print("[r1e] module header left=%.0f ; first module row grid left=%.0f" % [
		module_header.global_position.x,
		(_panel.get_node("%ModuleRows").get_child(0) as Button)
			.get_node("RowInner").get_child(0).global_position.x,
	])
	print("[r1e] ammo header left=%.0f ; first ammo row grid left=%.0f" % [
		ammo_header.global_position.x,
		(_panel.get_node("%OutfittingRows").get_child(0) as Button)
			.get_node("RowInner").get_child(0).global_position.x,
	])
	print("[r1e] module row height=%.0f vs the ammo row height=%.0f (76 px pitch)" % [
		(_panel.get_node("%ModuleRows").get_child(0) as Button).size.y,
		(_panel.get_node("%OutfittingRows").get_child(0) as Button).size.y,
	])
	print("[r1e] the scroll body is taller than the viewport: body=%.0f scroll=%.0f" % [
		(_panel.get_node("OutfittingScroll/OutfittingBody") as Control).size.y,
		(_panel.get_node("%OutfittingScroll") as Control).size.y,
	])
