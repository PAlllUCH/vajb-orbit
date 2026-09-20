extends Node
## Throwaway W5 scene probe (deleted with its .uid and .tscn before the report).
## Boots the shipped flight scene and measures the section 9.9 HUD wiring end to
## end: the dock prompt driven by game.gd's `set_prompt`, the warp bar driven by
## `set_warp_channel`, and the cursor reticle inside the live HUD.
## The owner's profile is never a target of this run: `PlayerProfile.save_path` is
## repointed at a scratch file before the game scene is instantiated.

const GAME_PATH := "res://game/game.tscn"
const SCRATCH_PROFILE := "user://probe_w5_profile.cfg"

var _checks: int = 0
var _failures: int = 0
var _game: Node = null
var _hud: Hud = null


func _ready() -> void:
	await _run()
	print("=== checks %d, failures %d ===" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)


func _run() -> void:
	var profile := get_tree().root.get_node_or_null(^"PlayerProfile")
	if profile != null:
		profile.set(&"save_path", SCRATCH_PROFILE)
	var packed := load(GAME_PATH) as PackedScene
	if packed == null:
		print("[w5] game.tscn failed to load")
		return
	_game = packed.instantiate()
	if _game == null:
		print("[w5] game.tscn did not instantiate")
		return
	add_child(_game)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_hud = _find_hud(_game)
	if _hud == null:
		_check("HUD instance found in the flight scene", false)
		return
	_check("HUD instance found in the flight scene", true)
	print("--- 1. dock prompt through game.gd ---")
	var prompt := _hud.get_node_or_null(^"CanvasLayer/BottomCenter/PromptBlock/PromptLabel") as Label
	var ship := _ship()
	var sector := _game.get_node_or_null(^"Sector")
	if prompt == null or ship == null or sector == null:
		_check("prompt / ship / sector present", false)
		return
	print("[w5] at spawn (%s): prompt visible=%s text='%s'" % [str(ship.global_position), str(prompt.visible), prompt.text])
	_check("no prompt away from the dock zone", not prompt.visible and prompt.text == "")
	var station := sector.call(&"station_position") as Vector2
	ship.global_position = station
	await get_tree().physics_frame
	await get_tree().physics_frame
	print("[w5] inside the dock zone (%s): prompt visible=%s text='%s'" % [str(station), str(prompt.visible), prompt.text])
	_check("game.gd pushes 'F · DOCK' inside the dock zone", prompt.visible and prompt.text == "F · DOCK")
	ship.global_position = station + Vector2(600.0, 0.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	print("[w5] back outside: prompt visible=%s text='%s'" % [str(prompt.visible), prompt.text])
	_check("leaving the zone clears the prompt", not prompt.visible and prompt.text == "")
	print("--- 2. warp channel bar through game.gd ---")
	var block := _hud.get_node_or_null(^"CanvasLayer/BottomCenter/PromptBlock/WarpBlock") as VBoxContainer
	var bar := _hud.get_node_or_null(^"CanvasLayer/BottomCenter/PromptBlock/WarpBlock/WarpBar") as ProgressBar
	var value := _hud.get_node_or_null(^"CanvasLayer/BottomCenter/PromptBlock/WarpBlock/WarpHeader/WarpValue") as Label
	_check("warp bar hidden before a channel", not block.visible)
	_game.call(&"_start_warp")
	await get_tree().physics_frame
	await get_tree().physics_frame
	print("[w5] warp channel t1: visible=%s value=%.1f text='%s'" % [str(block.visible), bar.value, value.text])
	_check("channel shows the bar above 0", block.visible and bar.value > 0.0 and bar.value < 100.0)
	var first: float = bar.value
	for step in 20:
		await get_tree().physics_frame
	print("[w5] warp channel t2: value=%.1f (was %.1f) text='%s'" % [bar.value, first, value.text])
	_check("bar advances with the channel", bar.value > first)
	_game.call(&"_cancel_warp")
	await get_tree().physics_frame
	print("[w5] channel cancelled: visible=%s" % str(block.visible))
	_check("cancelling hides the bar", not block.visible)
	print("--- 3. cursor reticle inside the live HUD ---")
	var reticle := _hud.get_node_or_null(^"CanvasLayer/CenterOverlay/TargetReticle") as TargetReticle
	_check("live reticle visible at the cursor", reticle != null and reticle.visible and reticle.state() == TargetReticle.State.PLAIN)
	_check("live reticle keeps the frozen lock pair", reticle != null and reticle.has_method(&"set_target") and reticle.has_method(&"clear_target"))
	if _game.has_method(&"on_route"):
		print("[w5] game.gd HUD method guard list intact: %s" % str(_game.get(&"HUD_METHODS")))
	if profile != null:
		profile.set(&"save_path", PlayerProfile.SAVE_FILE)
	DirAccess.remove_absolute(SCRATCH_PROFILE)


func _ship() -> Node2D:
	var ships := get_tree().get_nodes_in_group(&"player_ship")
	if ships.is_empty():
		return null
	return ships[0] as Node2D


func _find_hud(node: Node) -> Hud:
	var hud := node as Hud
	if hud != null:
		return hud
	for child in node.get_children():
		var found := _find_hud(child)
		if found != null:
			return found
	return null


func _check(label: String, condition: bool) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print("[%s] %s" % ["ok  " if condition else "FAIL", label])
