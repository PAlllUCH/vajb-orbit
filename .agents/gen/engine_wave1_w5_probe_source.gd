extends Node
## Throwaway W5 probe (deleted with its .uid and .tscn before the report). Run as a
## scene, because hud.gd reads the SettingsManager autoload and an autoload is only
## a compile-time identifier in a normal run (the same limitation fix wave 1 hit).
## Loads hud.tscn at the project's 1920x1080 logical size and prints measured facts:
## prompt/warp visibility and values, reticle state and position, blip-kind colours,
## frozen-API survival, theme-item usage.

const HUD_PATH := "res://ui/hud/hud.tscn"
const PLAYER_STATE_PATH := "res://game/player_state.gd"
const ESC_HINT := "ESC · DOCK AT KEPLER-9"

const FROZEN_METHODS: Array[StringName] = [
	&"bind",
	&"set_sector_name",
	&"set_minimap_scale",
	&"set_minimap_blips",
	&"set_target",
	&"set_target_info",
	&"clear_target",
	&"set_cargo_open",
]
const FROZEN_SIGNALS: Array[StringName] = [
	&"weapon_slot_selected",
	&"cargo_toggled",
	&"minimap_zoom_changed",
]

var _checks: int = 0
var _failures: int = 0
var _hud: Hud = null
var _theme: Theme = null


func _ready() -> void:
	await _run()
	print("=== checks %d, failures %d ===" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)


func _run() -> void:
	_theme = _live_theme()
	var packed := load(HUD_PATH) as PackedScene
	if packed == null:
		print("[w5] hud.tscn failed to load")
		return
	_hud = packed.instantiate() as Hud
	if _hud == null:
		print("[w5] hud.tscn did not instantiate as Hud")
		return
	add_child(_hud)
	_hud.theme = _theme
	await get_tree().process_frame
	await get_tree().process_frame
	print("[w5] viewport = %s | hud size = %s" % [str(get_viewport().get_visible_rect().size), str(_hud.size)])
	print("[w5] theme = %s" % ("Router.live_theme()" if _theme != null else "NULL"))
	_check_api()
	_check_hint_retired()
	await _check_bind()
	await _check_prompt()
	await _check_warp()
	await _check_reticle()
	await _check_blips()


func _check_api() -> void:
	print("--- 1. section 3.10 API ---")
	var methods: Array[StringName] = FROZEN_METHODS.duplicate()
	methods.append_array([&"set_prompt", &"set_warp_channel", &"set_reticle_state"])
	for method: StringName in methods:
		_check("Hud.%s" % String(method), _hud.has_method(method))
	for hud_signal: StringName in FROZEN_SIGNALS:
		_check("Hud.%s signal" % String(hud_signal), _hud.has_signal(hud_signal))


func _check_hint_retired() -> void:
	print("--- 2. ESC hint retirement ---")
	var texts: Array[String] = []
	_collect_texts(_hud, texts)
	var hint := 0
	for text: String in texts:
		if text.contains(ESC_HINT):
			hint += 1
	_check("no node carries '%s' (labels=%d)" % [ESC_HINT, texts.size()], hint == 0)
	_check("DockHint node gone", _hud.find_child("DockHint", true, false) == null)


func _check_bind() -> void:
	print("--- 3. frozen state path ---")
	var state: PlayerState = load(PLAYER_STATE_PATH).new()
	state.setup()
	_hud.bind(state)
	await get_tree().process_frame
	var hull_label := _hud.get_node_or_null(^"CanvasLayer/TopLeft/Blocks/HullBlock/HullHeader/HullValue") as Label
	var cargo_label := _hud.get_node_or_null(^"CanvasLayer/CenterOverlay/CargoPanel/CargoBox/CargoFooter/CargoFooterLabel") as Label
	print("[w5] bound: hull='%s' cargo='%s'" % [hull_label.text, cargo_label.text])
	_check("bind() still pulls the pools", hull_label.text == "1000/1000" and cargo_label.text == "CARGO 0/40")
	state.set_hull(750.0)
	await get_tree().process_frame
	print("[w5] after set_hull(750): hull='%s'" % hull_label.text)
	_check("hull signal still reaches the readout", hull_label.text == "750/1000")


func _check_prompt() -> void:
	print("--- 4. set_prompt ---")
	var label := _hud.get_node_or_null(^"CanvasLayer/BottomCenter/PromptBlock/PromptLabel") as Label
	if label == null:
		_check("PromptLabel exists", false)
		return
	_check("prompt hidden at boot (text='%s')" % label.text, not label.visible)
	_hud.set_prompt("F · DOCK")
	await get_tree().process_frame
	print("[w5] prompt on: visible=%s text='%s' variation=%s size=%d colour=%s rect=%s" % [
		str(label.visible),
		label.text,
		String(label.theme_type_variation),
		label.get_theme_font_size(&"font_size"),
		str(label.get_theme_color(&"font_color")),
		str(label.get_global_rect()),
	])
	_check("prompt visible with text", label.visible and label.text == "F · DOCK")
	_check("prompt uses StationCaption 13", String(label.theme_type_variation) == "StationCaption" and label.get_theme_font_size(&"font_size") == 13)
	_check("prompt carries no font-size override", not label.has_theme_font_size_override(&"font_size"))
	_check("prompt carries no colour override", not label.has_theme_color_override(&"font_color"))
	_hud.set_prompt("")
	await get_tree().process_frame
	print("[w5] prompt off: visible=%s text='%s'" % [str(label.visible), label.text])
	_check("empty prompt hides", not label.visible and label.text == "")


func _check_warp() -> void:
	print("--- 5. set_warp_channel ---")
	var block := _hud.get_node_or_null(^"CanvasLayer/BottomCenter/PromptBlock/WarpBlock") as VBoxContainer
	var bar := _hud.get_node_or_null(^"CanvasLayer/BottomCenter/PromptBlock/WarpBlock/WarpBar") as ProgressBar
	var value := _hud.get_node_or_null(^"CanvasLayer/BottomCenter/PromptBlock/WarpBlock/WarpHeader/WarpValue") as Label
	if block == null or bar == null or value == null:
		_check("warp nodes exist", false)
		return
	_check("warp hidden at boot", not block.visible)
	_hud.set_warp_channel(0.4)
	await get_tree().process_frame
	print("[w5] warp 0.40: visible=%s value=%s max=%.0f text='%s' bar variation=%s rect=%s" % [
		str(block.visible),
		str(bar.value),
		bar.max_value,
		value.text,
		String(bar.theme_type_variation),
		str(bar.get_global_rect()),
	])
	_check("0.40 shows the bar at 40/100 with '40%'", block.visible and is_equal_approx(bar.value, 40.0) and value.text == "40%")
	_check("bar is a theme variation, unoverridden", String(bar.theme_type_variation) == "HudShieldBar" and not bar.has_theme_stylebox_override(&"fill"))
	_check("bar fill comes from the theme variation", bar.get_theme_stylebox(&"fill") == _theme.get_stylebox(&"fill", &"HudShieldBar"))
	_check("value label uses HudReadout 18, no override", String(value.theme_type_variation) == "HudReadout" and value.get_theme_font_size(&"font_size") == 18 and not value.has_theme_font_size_override(&"font_size"))
	_check("caption uses StationCaption", String((block.get_node(^"WarpHeader/WarpCaption") as Label).theme_type_variation) == "StationCaption")
	_hud.set_warp_channel(1.0)
	await get_tree().process_frame
	print("[w5] warp 1.00: visible=%s value=%s text='%s'" % [str(block.visible), str(bar.value), value.text])
	_check("1.0 fills the bar", block.visible and is_equal_approx(bar.value, 100.0) and value.text == "100%")
	_hud.set_warp_channel(0.0)
	await get_tree().process_frame
	print("[w5] warp 0.00: visible=%s value=%s" % [str(block.visible), str(bar.value)])
	_check("0.0 hides the bar", not block.visible)
	_hud.set_warp_channel(-3.0)
	await get_tree().process_frame
	print("[w5] warp -3.00: visible=%s" % str(block.visible))
	_check("<= 0 hides the bar", not block.visible)
	_hud.set_warp_channel(2.5)
	await get_tree().process_frame
	print("[w5] warp 2.50 (clamped): visible=%s value=%s text='%s'" % [str(block.visible), str(bar.value), value.text])
	_check("progress above 1 clamps to 100%", block.visible and is_equal_approx(bar.value, 100.0))
	_hud.set_prompt("F · DOCK")
	_hud.set_warp_channel(0.6)
	await get_tree().process_frame
	await get_tree().process_frame
	var prompt := _hud.get_node(^"CanvasLayer/BottomCenter/PromptBlock/PromptLabel") as Label
	var ammo := _hud.get_node(^"CanvasLayer/BottomLeft/Blocks/AmmoPanel") as Control
	var minimap_panel := _hud.get_node(^"CanvasLayer/BottomRight/MinimapPanel") as Control
	## The prompt label spans the strip and centres its text (the retired hint's rect was
	## P(12,1042) S(1896,18) too, fix_wave1_w3_report section 4 item 2), so the drawn
	## content is measured as the text's own box rather than the label's full rect.
	var prompt_rect: Rect2 = prompt.get_global_rect()
	var text_width: float = prompt.get_minimum_size().x
	var prompt_text := Rect2(
		Vector2(prompt_rect.position.x + (prompt_rect.size.x - text_width) * 0.5, prompt_rect.position.y),
		Vector2(text_width, prompt_rect.size.y)
	)
	print("[w5] both visible: warp=%s bar=%s prompt=%s prompt_text=%s ammo=%s minimap=%s" % [
		str(block.get_global_rect()),
		str(bar.get_global_rect()),
		str(prompt_rect),
		str(prompt_text),
		str(ammo.get_global_rect()),
		str(minimap_panel.get_global_rect()),
	])
	_check("warp sits above the prompt", block.get_global_rect().end.y <= prompt_rect.position.y)
	_check("warp block hugs its content", is_equal_approx(block.get_global_rect().size.x, bar.get_global_rect().size.x))
	_check("strip stays clear of the ammo panel", not block.get_global_rect().intersects(ammo.get_global_rect()) and not prompt_text.intersects(ammo.get_global_rect()))
	_check("strip stays clear of the minimap panel", not block.get_global_rect().intersects(minimap_panel.get_global_rect()) and not prompt_text.intersects(minimap_panel.get_global_rect()))
	_hud.set_prompt("")
	_hud.set_warp_channel(0.0)
	await get_tree().process_frame


func _check_reticle() -> void:
	print("--- 6. cursor reticle ---")
	var reticle := _hud.get_node_or_null(^"CanvasLayer/CenterOverlay/TargetReticle") as TargetReticle
	if reticle == null:
		_check("TargetReticle exists", false)
		return
	var bar_box := reticle.get_node_or_null(^"ReticleBarBox") as VBoxContainer
	print("[w5] tokens: accent_danger=%s text_dim=%s text_primary=%s" % [
		str(_theme.get_color(&"accent_danger", &"Tokens")),
		str(_theme.get_color(&"text_dim", &"Tokens")),
		str(_theme.get_color(&"text_primary", &"Tokens")),
	])
	print("[w5] reticle colour keys: lock=%s plain=%s engaged=%s" % [
		String(TargetReticle.COLOR_LOCK),
		String(TargetReticle.COLOR_PLAIN),
		String(TargetReticle.COLOR_ENGAGED),
	])
	print("[w5] reticle at boot: visible=%s state=%d size=%s pos=%s bar_box=%s" % [
		str(reticle.visible),
		reticle.state(),
		str(reticle.size),
		str(reticle.position),
		str(bar_box.visible),
	])
	_check("cursor reticle drawn at boot (state PLAIN)", reticle.visible and reticle.state() == TargetReticle.State.PLAIN)
	_check("lock micro-bar hidden without a target", not bar_box.visible)
	_check("reticle ignores the mouse", reticle.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	_check("runs with the hardware cursor visible", Input.mouse_mode == Input.MOUSE_MODE_VISIBLE)
	_hud.set_reticle_state(TargetReticle.State.IN_RANGE)
	await get_tree().process_frame
	print("[w5] reticle IN_RANGE: state=%d" % reticle.state())
	_check("IN_RANGE state applied", reticle.state() == TargetReticle.State.IN_RANGE)
	_hud.set_reticle_state(TargetReticle.State.OUT_OF_RANGE)
	await get_tree().process_frame
	print("[w5] reticle OUT_OF_RANGE: state=%d" % reticle.state())
	_check("OUT_OF_RANGE state applied", reticle.state() == TargetReticle.State.OUT_OF_RANGE)
	_hud.set_reticle_state(99)
	await get_tree().process_frame
	print("[w5] reticle 99 (clamped): state=%d" % reticle.state())
	_check("out-of-range state value clamps to HOSTILE", reticle.state() == TargetReticle.State.HOSTILE)
	_hud.set_reticle_state(TargetReticle.State.PLAIN)
	reticle.set_cursor_position(Vector2(960.0, 540.0))
	await get_tree().process_frame
	print("[w5] cursor (960,540): pos=%s expected=%s" % [
		str(reticle.position),
		str(Vector2(960.0, 540.0) - reticle.size * 0.5),
	])
	_check("reticle centred on the cursor", reticle.position.is_equal_approx(Vector2(960.0, 540.0) - reticle.size * 0.5))
	var motion := InputEventMouseMotion.new()
	var raw := Vector2(300.0, 200.0)
	motion.position = raw
	var before: Vector2 = reticle.position
	Input.parse_input_event(motion)
	await get_tree().process_frame
	await get_tree().process_frame
	## Headless has no pointer, so the delivered event position is reconstructed from
	## the ratio of the logical viewport to the 2560x1440 host window; both are printed.
	var scale: Vector2 = get_viewport().get_visible_rect().size / Vector2(get_window().size)
	var delivered: Vector2 = raw * scale
	print("[w5] injected motion raw=%s window=%s logical=%s delivered=%s pos=%s expected=%s" % [
		str(raw),
		str(get_window().size),
		str(get_viewport().get_visible_rect().size),
		str(delivered),
		str(reticle.position),
		str(delivered - reticle.size * 0.5),
	])
	_check("mouse motion moved the cursor reticle", not reticle.position.is_equal_approx(before))
	_check("mouse motion drives the cursor reticle", reticle.position.is_equal_approx(delivered - reticle.size * 0.5))
	_hud.set_target(Vector2(600.0, 400.0), 0.62)
	await get_tree().process_frame
	var hull_bar := reticle.get_node(^"ReticleBarBox/ReticleHullBar") as ProgressBar
	print("[w5] lock (600,400) hull 0.62: visible=%s pos=%s bar_box=%s hull_bar=%s" % [
		str(reticle.visible),
		str(reticle.position),
		str(bar_box.visible),
		str(hull_bar.value),
	])
	_check("lock positions and shows the micro-bar", reticle.position.is_equal_approx(Vector2(600.0, 400.0) - reticle.size * 0.5) and bar_box.visible and is_equal_approx(hull_bar.value, 62.0))
	_hud.clear_target()
	await get_tree().process_frame
	print("[w5] clear_target: visible=%s pos=%s bar_box=%s" % [
		str(reticle.visible),
		str(reticle.position),
		str(bar_box.visible),
	])
	_check("clear_target returns to the cursor reticle", reticle.visible and not bar_box.visible and reticle.position.is_equal_approx(delivered - reticle.size * 0.5))


func _check_blips() -> void:
	print("--- 7. blip kinds ---")
	var minimap := _hud.get_node_or_null(^"CanvasLayer/BottomRight/MinimapPanel/MinimapBox/Bezel/MinimapView") as Minimap
	if minimap == null:
		_check("MinimapView exists", false)
		return
	var expected: Dictionary = {
		&"self": _theme.get_color(&"text_primary", &"Tokens"),
		&"friendly": _theme.get_color(&"text_primary", &"Tokens"),
		&"neutral": _theme.get_color(&"text_dim", &"Tokens"),
		&"hostile": _theme.get_color(&"accent_danger", &"Tokens"),
		&"": _theme.get_color(&"text_dim", &"Tokens"),
	}
	for kind: StringName in expected:
		var colour: Color = minimap.call(&"_color_for", kind)
		print("[w5] minimap kind '%s' -> %s" % [String(kind), str(colour)])
		_check("minimap kind '%s' resolves its token" % String(kind), colour.is_equal_approx(expected[kind]))
	_hud.set_minimap_blips([
		{"pos": Vector2(0.0, 420.0), "kind": &"self"},
		{"pos": Vector2(0.0, 0.0), "kind": &"friendly"},
		{"pos": Vector2(500.0, 0.0), "kind": &"neutral"},
		{"pos": Vector2(-400.0, 300.0), "kind": &"hostile"},
	])
	await get_tree().process_frame
	print("[w5] blips fed: self + friendly + neutral + hostile at radius %.0f" % minimap.world_radius())
	_check("four kinds accepted in one feed", minimap.world_radius() > 0.0)


func _live_theme() -> Theme:
	var router := get_tree().root.get_node_or_null(^"Router")
	if router != null and router.has_method(&"live_theme"):
		var theme: Variant = router.call(&"live_theme")
		if theme is Theme:
			return theme
	return load("res://ui/theme/vajb_theme.tres") as Theme


func _collect_texts(node: Node, into: Array[String]) -> void:
	var label := node as Label
	if label != null:
		into.append(label.text)
	for child in node.get_children():
		_collect_texts(child, into)


func _check(label: String, condition: bool) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print("[%s] %s" % ["ok  " if condition else "FAIL", label])
