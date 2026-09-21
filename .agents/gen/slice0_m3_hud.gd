extends Node
## Slice 0, M3 probe B (throwaway; its source is archived under .agents/gen/ after the
## run and can be dropped back into res://tools/ to re-measure).
## Scene run: the HUD is a Control with a theme, and the theme is only resolvable in
## a real tree.
##
## Measures M3's acceptance from the slice-0 brief: UI_SPEC section 3.1b's two pool
## bars (Energy fill `metal_light`, Fuel fill `metal_mid` turning `accent_danger` at
## 15 % or less) and the Emergency Flight banner in `accent_danger_bright`, driven
## both through the section 10 API and through PlayerState's own signals.
## A [FAIL] line means the acceptance did not land.

const HudScene := preload("res://ui/hud/hud.tscn")
const PlayerStateScript := preload("res://game/player_state.gd")

const TOKENS_TYPE: StringName = &"Tokens"
const TOKEN_ENERGY_FILL: StringName = &"metal_light"
const TOKEN_FUEL_FILL: StringName = &"metal_mid"
const TOKEN_DANGER: StringName = &"accent_danger"
const TOKEN_DANGER_BRIGHT: StringName = &"accent_danger_bright"

const BLOCKS_PATH := "CanvasLayer/TopLeft/Blocks"
const ENERGY_BLOCK := "EnergyBlock"
const FUEL_BLOCK := "FuelBlock"
const BANNER := "EmergencyBanner"
const BAR := "Bar"
const VALUE := "Value"
const DANGER_FUEL_FRACTION := 0.15
const CELLS := 100.0
const TANK := 200.0

var _ok := 0
var _fail := 0
var _hud: Control = null


func _ready() -> void:
	_watch()
	_run()


func _watch() -> void:
	await get_tree().create_timer(60.0).timeout
	print("WATCHDOG: probe B did not finish in 60 s")
	get_tree().quit(2)


func _check(label: String, ok: bool, detail: String) -> void:
	if ok:
		_ok += 1
	else:
		_fail += 1
	print("%s %s | %s" % ["[OK]  " if ok else "[FAIL]", label, detail])


func _token(name: StringName) -> Color:
	return _hud.get_theme_color(name, TOKENS_TYPE)


func _run() -> void:
	print("=== slice0 M3 probe B: the Energy and Fuel bars and the emergency banner ===")
	_hud = HudScene.instantiate() as Control
	if _hud == null:
		_check("the HUD scene instantiates", false, "hud.tscn")
		_finish()
		return
	add_child(_hud)
	await get_tree().process_frame
	await get_tree().process_frame
	_structure()
	_fills()
	_danger_line()
	_emergency()
	_state_channel()
	_unknown_kind()
	_finish()


func _bar(block: String) -> ProgressBar:
	return _hud.get_node_or_null(NodePath("%s/%s/%s%sRow/%s%s" % [BLOCKS_PATH, block, block, BAR, block, BAR])) as ProgressBar


func _value(block: String) -> Label:
	return _hud.get_node_or_null(NodePath("%s/%s/%sHeader/%s%s" % [BLOCKS_PATH, block, block, block, VALUE])) as Label


func _block(block: String) -> VBoxContainer:
	return _hud.get_node_or_null(NodePath("%s/%s" % [BLOCKS_PATH, block])) as VBoxContainer


func _banner() -> Label:
	return _hud.get_node_or_null(NodePath("%s/%s" % [BLOCKS_PATH, BANNER])) as Label


func _dump(node: Node, depth: int) -> void:
	for child: Node in node.get_children():
		print("%s%s (%s)" % ["  ".repeat(depth), child.name, child.get_class()])
		if depth < 3:
			_dump(child, depth + 1)


func _structure() -> void:
	var blocks := _hud.get_node_or_null(NodePath(BLOCKS_PATH))
	if blocks == null:
		_check("structure a: the TopLeft column exists", false, BLOCKS_PATH)
		return
	var order: Array[String] = []
	for child: Node in blocks.get_children():
		order.append(String(child.name))
	_check(
		"structure a: the banner sits above the blocks, the pools below the shield",
		order == [BANNER, "HullBlock", "ShieldBlock", ENERGY_BLOCK, FUEL_BLOCK],
		str(order),
	)
	var banner := _banner()
	_check(
		"structure b: the banner reads EMERGENCY FLIGHT and starts hidden",
		banner != null and banner.text == "EMERGENCY FLIGHT" and not banner.visible,
		"banner=%s" % (banner.text if banner != null else "missing"),
	)
	var titles: Array[String] = []
	var ignores_mouse := true
	for kind: Array in [[ENERGY_BLOCK, "ENERGY"], [FUEL_BLOCK, "FUEL"]]:
		var block := _block(String(kind[0]))
		if block == null:
			continue
		titles.append((block.get_node_or_null(NodePath("%sHeader/%sTitle" % [kind[0], kind[0]])) as Label).text)
		var nodes: Array[Control] = [block]
		var bar := _bar(String(kind[0]))
		var value := _value(String(kind[0]))
		var row := bar.get_parent() as Control
		var header := row.get_parent().get_node(NodePath("%sHeader" % kind[0])) as Control
		var caption := header.get_child(0) as Control
		var spacer := header.get_child(1) as Control
		nodes.append(row)
		nodes.append(header)
		nodes.append(caption)
		nodes.append(spacer)
		nodes.append(bar)
		nodes.append(value)
		for node: Control in nodes:
			if node.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				ignores_mouse = false
	_check(
		"structure c: the two blocks carry the section 3.1b titles",
		titles == ["ENERGY", "FUEL"],
		str(titles),
	)
	_check(
		"structure d: every new node ignores the mouse, so flight clicks survive",
		ignores_mouse,
		"mouse_filter",
	)
	var energy := _bar(ENERGY_BLOCK)
	var fuel := _bar(FUEL_BLOCK)
	_check(
		"structure e: both bars are the 260 x 14 readout with no percentage",
		energy != null and fuel != null
			and energy.custom_minimum_size == Vector2(260.0, 14.0)
			and fuel.custom_minimum_size == Vector2(260.0, 14.0)
			and not energy.show_percentage and not fuel.show_percentage,
		"energy=%s fuel=%s" % [
			energy.custom_minimum_size if energy != null else "missing",
			fuel.custom_minimum_size if fuel != null else "missing",
		],
	)
	var value := _value(ENERGY_BLOCK)
	_check(
		"structure f: the readout uses the existing HudReadout variation, no new font size",
		value != null and value.theme_type_variation == &"HudReadout"
			and not value.has_theme_font_size_override(&"font_size"),
		value.theme_type_variation if value != null else "missing",
	)


func _fills() -> void:
	_hud.call(&"set_pool", &"energy", 75.0, CELLS)
	_hud.call(&"set_pool", &"fuel", 150.0, TANK)
	var energy := _bar(ENERGY_BLOCK)
	var fuel := _bar(FUEL_BLOCK)
	var energy_fill := energy.get_theme_stylebox(&"fill") as StyleBoxFlat
	var fuel_fill := fuel.get_theme_stylebox(&"fill") as StyleBoxFlat
	_check(
		"fill a: Energy is metal_light (the buffer is not a danger state)",
		energy_fill != null and energy_fill.bg_color == _token(TOKEN_ENERGY_FILL),
		str(energy_fill.bg_color if energy_fill != null else "missing"),
	)
	_check(
		"fill b: Fuel is metal_mid above the danger line",
		fuel_fill != null and fuel_fill.bg_color == _token(TOKEN_FUEL_FILL),
		str(fuel_fill.bg_color if fuel_fill != null else "missing"),
	)
	_check(
		"fill c: both readouts print current/max",
		_value(ENERGY_BLOCK).text == "75/100" and _value(FUEL_BLOCK).text == "150/200",
		"%s | %s" % [_value(ENERGY_BLOCK).text, _value(FUEL_BLOCK).text],
	)
	_check(
		"fill d: the bars carry the values",
		int(round(energy.value)) == 75 and int(round(energy.max_value)) == 100
			and int(round(fuel.value)) == 150 and int(round(fuel.max_value)) == 200,
		"energy=%s/%s fuel=%s/%s" % [energy.value, energy.max_value, fuel.value, fuel.max_value],
	)


func _danger_line() -> void:
	_hud.call(&"set_pool", &"fuel", TANK * DANGER_FUEL_FRACTION, TANK)
	var fuel := _bar(FUEL_BLOCK)
	var label := _value(FUEL_BLOCK)
	var fill := fuel.get_theme_stylebox(&"fill") as StyleBoxFlat
	_check(
		"danger a: at exactly 15 % the fill and the readout turn accent_danger",
		fill.bg_color == _token(TOKEN_DANGER)
			and label.has_theme_color_override(&"font_color")
			and label.get_theme_color(&"font_color") == _token(TOKEN_DANGER),
		"fill=%s label=%s" % [fill.bg_color, label.get_theme_color(&"font_color")],
	)
	var energy_label := _value(ENERGY_BLOCK)
	_check(
		"danger b: the Energy readout does not follow a danger reading (only Fuel does)",
		not energy_label.has_theme_color_override(&"font_color"),
		"override=%s" % energy_label.has_theme_color_override(&"font_color"),
	)
	_hud.call(&"set_pool", &"fuel", TANK * DANGER_FUEL_FRACTION + 1.0, TANK)
	_check(
		"danger c: above 15 % the fill and readout return to metal_mid",
		(fuel.get_theme_stylebox(&"fill") as StyleBoxFlat).bg_color == _token(TOKEN_FUEL_FILL)
			and not label.has_theme_color_override(&"font_color"),
		str((fuel.get_theme_stylebox(&"fill") as StyleBoxFlat).bg_color),
	)


func _emergency() -> void:
	_hud.call(&"set_emergency", true)
	var banner := _banner()
	var energy_fill := _bar(ENERGY_BLOCK).get_theme_stylebox(&"fill") as StyleBoxFlat
	_check(
		"emergency a: the banner appears in accent_danger_bright",
		banner.visible and banner.get_theme_color(&"font_color") == _token(TOKEN_DANGER_BRIGHT),
		"visible=%s colour=%s" % [banner.visible, banner.get_theme_color(&"font_color")],
	)
	_check(
		"emergency b: the Energy fill turns accent_danger while the mode lasts",
		energy_fill.bg_color == _token(TOKEN_DANGER),
		str(energy_fill.bg_color),
	)
	_check(
		"emergency c: the Fuel fill is not what marks the mode",
		(_bar(FUEL_BLOCK).get_theme_stylebox(&"fill") as StyleBoxFlat).bg_color == _token(TOKEN_FUEL_FILL),
		str((_bar(FUEL_BLOCK).get_theme_stylebox(&"fill") as StyleBoxFlat).bg_color),
	)
	_hud.call(&"set_emergency", false)
	_check(
		"emergency d: clearing the mode hides the banner and restores metal_light",
		not banner.visible
			and (_bar(ENERGY_BLOCK).get_theme_stylebox(&"fill") as StyleBoxFlat).bg_color == _token(TOKEN_ENERGY_FILL),
		"visible=%s" % banner.visible,
	)


func _state_channel() -> void:
	var state := PlayerStateScript.new()
	state.energy_max = CELLS
	state.fuel_max = TANK
	state.energy_regen = 5.0
	state.setup()
	_hud.call(&"bind", state)
	_check(
		"state a: bind seeds both bars from the pools",
		_value(ENERGY_BLOCK).text == "100/100" and _value(FUEL_BLOCK).text == "200/200",
		"%s | %s" % [_value(ENERGY_BLOCK).text, _value(FUEL_BLOCK).text],
	)
	state.set_energy(40.0)
	_check(
		"state b: an Energy change reaches the bar",
		_value(ENERGY_BLOCK).text == "40/100",
		_value(ENERGY_BLOCK).text,
	)
	state.set_fuel(0.0)
	_check(
		"state c: fuel 0 raises the banner through the state's own signal (ruling 14)",
		_banner().visible and state.emergency_mode,
		"visible=%s emergency=%s" % [_banner().visible, state.emergency_mode],
	)
	_check(
		"state d: the empty bar is also at the danger line, so the red fill is truthful",
		(_bar(FUEL_BLOCK).get_theme_stylebox(&"fill") as StyleBoxFlat).bg_color == _token(TOKEN_DANGER),
		str((_bar(FUEL_BLOCK).get_theme_stylebox(&"fill") as StyleBoxFlat).bg_color),
	)
	state.set_fuel(30.0)
	_check(
		"state e: burning a fuel cell ends the mode and hides the banner",
		not _banner().visible,
		"visible=%s fuel=%s" % [_banner().visible, state.fuel],
	)


func _unknown_kind() -> void:
	var energy_before := _value(ENERGY_BLOCK).text
	_hud.call(&"set_pool", &"shield", 1.0, 1.0)
	_hud.call(&"set_pool", &"", 1.0, 1.0)
	_check(
		"seam a: an unknown pool kind is ignored instead of fatal",
		_value(ENERGY_BLOCK).text == energy_before,
		"energy=%s after=%s" % [energy_before, _value(ENERGY_BLOCK).text],
	)


func _finish() -> void:
	print("[SUMMARY] ok=%d failed=%d" % [_ok, _fail])
	get_tree().quit(1 if _fail > 0 else 0)
