extends Node
## W5 reviewer probe: the two-state layout seam, measured in memory only.
##
## W1's "before" column was taken with a throwaway probe that switched the D3 guard back
## off on the live nodes. This probe does the same, so the before column is re-measured
## against the shipped scenes and the shipped art without editing any shipped file.
##
## Run:  godot --headless --path vajb-orbit res://tests/probe_w5_layout.tscn --quit-after 300
## Signal: the [W5-LAYOUT] lines; the last line is [W5-LAYOUT] done.

const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const ShipyardScene := preload("res://ui/station/shipyard_panel.tscn")
const LaunchScene := preload("res://ui/station/launch_panel.tscn")
const HudScene := preload("res://ui/hud/hud.tscn")
const SlotScene := preload("res://ui/components/slot_button.tscn")

const WEAPON_VARIATION: StringName = &"SlotButtonWeapon"
const CARGO_VARIATION: StringName = &"SlotButtonCargo"
const HUD_CARGO_CELLS := 40

var _host: Control = null


func _ready() -> void:
	_host = Control.new()
	_host.name = "W5Host"
	_host.theme = ThemeRes
	_host.size = Vector2(1920.0, 1080.0)
	add_child(_host)
	await get_tree().process_frame

	print("[W5-LAYOUT] viewport=(%s, %s)" % [
		ProjectSettings.get_setting("display/window/size/viewport_width", -1),
		ProjectSettings.get_setting("display/window/size/viewport_height", -1),
	])

	await _probe_shipyard()
	await _probe_launch()
	await _probe_component()
	await _probe_hud()

	print("[W5-LAYOUT] done")
	get_tree().quit(0)


func _mount(scene: PackedScene) -> Control:
	var node := scene.instantiate() as Control
	_host.add_child(node)
	return node


func _plate_art(plate: TextureButton) -> Vector2:
	if plate == null or plate.texture_normal == null:
		return Vector2.ZERO
	return plate.texture_normal.get_size()


## Flip the guard off (or back on) on a set of plates, in memory, and mark the minimum
## size dirty. No shipped file is written.
func _guard(plates: Array, on: bool) -> void:
	for child: Node in plates:
		var plate := child as TextureButton
		if plate != null:
			plate.ignore_texture_size = on
			plate.update_minimum_size()


func _probe_shipyard() -> void:
	var panel := _mount(ShipyardScene)
	var strip: HBoxContainer = panel.get(&"_hardpoints")
	var stats: Control = panel.get_node_or_null(NodePath(&"ShipyardBody/StatsBox"))
	print("[W5-LAYOUT] shipyard on: strip %s panel %s statsbox %s (art %s, separation %s, children %d)" % [
		strip.get_combined_minimum_size(),
		panel.get_combined_minimum_size(),
		stats.get_combined_minimum_size(),
		_plate_art(strip.get_child(0) as TextureButton),
		strip.get_theme_constant(&"separation"),
		strip.get_child_count(),
	])
	_guard(strip.get_children(), false)
	print("[W5-LAYOUT] shipyard guard-off immediate: strip %s panel %s statsbox %s" % [
		strip.get_combined_minimum_size(),
		panel.get_combined_minimum_size(),
		stats.get_combined_minimum_size(),
	])
	await get_tree().process_frame
	print("[W5-LAYOUT] shipyard guard-off frame1: strip %s panel %s statsbox %s" % [
		strip.get_combined_minimum_size(),
		panel.get_combined_minimum_size(),
		stats.get_combined_minimum_size(),
	])
	_guard(strip.get_children(), true)
	print("[W5-LAYOUT] shipyard guard-restored: strip %s panel %s statsbox %s" % [
		strip.get_combined_minimum_size(),
		panel.get_combined_minimum_size(),
		stats.get_combined_minimum_size(),
	])
	panel.queue_free()


func _probe_launch() -> void:
	var panel := _mount(LaunchScene)
	var strip: HBoxContainer = panel.get(&"_cargo_slots")
	var launch: Button = panel.get(&"_launch_button")
	print("[W5-LAYOUT] launch on: strip %s panel %s launchbutton %s (art %s, separation %s, children %d)" % [
		strip.get_combined_minimum_size(),
		panel.get_combined_minimum_size(),
		launch.get_combined_minimum_size(),
		_plate_art(strip.get_child(0) as TextureButton),
		strip.get_theme_constant(&"separation"),
		strip.get_child_count(),
	])
	_guard(strip.get_children(), false)
	print("[W5-LAYOUT] launch guard-off immediate: strip %s panel %s launchbutton %s" % [
		strip.get_combined_minimum_size(),
		panel.get_combined_minimum_size(),
		launch.get_combined_minimum_size(),
	])
	await get_tree().process_frame
	print("[W5-LAYOUT] launch guard-off frame1: strip %s panel %s launchbutton %s" % [
		strip.get_combined_minimum_size(),
		panel.get_combined_minimum_size(),
		launch.get_combined_minimum_size(),
	])
	_guard(strip.get_children(), true)
	print("[W5-LAYOUT] launch guard-restored: strip %s panel %s launchbutton %s" % [
		strip.get_combined_minimum_size(),
		panel.get_combined_minimum_size(),
		launch.get_combined_minimum_size(),
	])
	panel.queue_free()


func _probe_component() -> void:
	var slot := SlotScene.instantiate() as SlotButton
	_host.add_child(slot)
	slot.configure(WEAPON_VARIATION, null, 1)
	print("[W5-LAYOUT] component weapon on: cell %s (art %s, ignore=%s)" % [
		slot.get_combined_minimum_size(),
		_plate_art(slot),
		slot.ignore_texture_size,
	])
	slot.ignore_texture_size = false
	slot.update_minimum_size()
	print("[W5-LAYOUT] component weapon off immediate: cell %s" % slot.get_combined_minimum_size())
	await get_tree().process_frame
	print("[W5-LAYOUT] component weapon off frame1: cell %s" % slot.get_combined_minimum_size())

	slot.configure(CARGO_VARIATION, null, 0)
	print("[W5-LAYOUT] component cargo on: cell %s (art %s, ignore=%s)" % [
		slot.get_combined_minimum_size(),
		_plate_art(slot),
		slot.ignore_texture_size,
	])
	slot.ignore_texture_size = false
	slot.update_minimum_size()
	print("[W5-LAYOUT] component cargo off immediate: cell %s" % slot.get_combined_minimum_size())
	await get_tree().process_frame
	print("[W5-LAYOUT] component cargo off frame1: cell %s" % slot.get_combined_minimum_size())
	slot.queue_free()


func _probe_hud() -> void:
	var hud := _mount(HudScene)
	var weapons: Array = hud.get(&"_weapon_slots")
	hud.call(&"_ensure_cargo_cells", HUD_CARGO_CELLS)
	var cells: Array = hud.get(&"_cargo_cells")
	print("[W5-LAYOUT] hud on: weapons %d first %s (art %s), cargo %d first %s (art %s)" % [
		weapons.size(),
		(weapons[0] as TextureButton).get_combined_minimum_size(),
		_plate_art(weapons[0] as TextureButton),
		cells.size(),
		(cells[0] as TextureButton).get_combined_minimum_size(),
		_plate_art(cells[0] as TextureButton),
	])
	_guard(weapons, false)
	_guard(cells, false)
	var weapon_huge := 0
	for node: Node in weapons:
		if (node as TextureButton).get_combined_minimum_size() == Vector2(880.0, 876.0):
			weapon_huge += 1
	var cargo_huge := 0
	for node: Node in cells:
		if (node as TextureButton).get_combined_minimum_size() == Vector2(873.0, 864.0):
			cargo_huge += 1
	print("[W5-LAYOUT] hud guard-off immediate: %d/%d weapons read 880x876, %d/%d cargo read 873x864" % [
		weapon_huge,
		weapons.size(),
		cargo_huge,
		cells.size(),
	])
	await get_tree().process_frame
	print("[W5-LAYOUT] hud guard-off frame1: first weapon %s, first cargo %s" % [
		(weapons[0] as TextureButton).get_combined_minimum_size(),
		(cells[0] as TextureButton).get_combined_minimum_size(),
	])
	hud.queue_free()
