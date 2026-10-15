extends Node
## The visual audit sweep (owner 2026-10-15): walks every surface the game
## shows, captures a full-resolution PNG of each into /tmp/vajb_audit/ and
## prints the cargo overlay's own row data so the owner's two cargo complaints
## (ammo rows at a zero hold, category sizes) read off state, not pixels.
## Profile writes are redirected to user://audit_profile.cfg; the real save is
## never touched. The run self-quits at the end; a watchdog kills it.

const OUT_DIR := "/tmp/vajb_audit"

const MineralCatalogScript := preload("res://game/mineral_catalog.gd")
const ComponentCatalogScript := preload("res://game/component_catalog.gd")
const Catalog := preload("res://game/station_catalog.gd")

var _index := 0


func _ready() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var profile := get_node_or_null(NodePath("/root/PlayerProfile"))
	if profile != null:
		profile.save_path = "user://audit_profile.cfg"
		print("AUDIT save_path -> ", profile.save_path)
	await _wait(1.0)
	await _shot("01_main_menu")

	_router().route(StringName("settings"))
	await _wait_idle()
	await _shot("02_settings")

	_router().route(StringName("station"))
	await _wait_idle()
	var station := get_tree().root.get_node_or_null(NodePath("Station"))
	if station == null:
		print("AUDIT FATAL no station")
		get_tree().quit()
		return
	for i in 6:
		station._select_module(i, true)
		await _wait(0.4)
		await _shot("1%d_station_module" % i)
	_probe_pane_fit(station)
	station._select_module(7, true)
	await _wait(0.4)
	for service in ["contracts", "insurance", "vaults"]:
		station._show_service(StringName(service))
		await _wait(0.4)
		await _shot("2%s_station_service" % service)
	_probe_pane_fit(station, true)
	var overview: Control = station.get("_overview")
	if overview == null:
		print("AUDIT OVSCROLL no overview pane")
	else:
		var scroll: ScrollContainer = overview.get_node(NodePath("BlockScroll"))
		var stack: VBoxContainer = overview.get_node(NodePath("BlockScroll/BlockStack"))
		print("AUDIT OVSCROLL size=", str(scroll.size), " stack_min=", str(stack.get_combined_minimum_size()))
		for child in stack.get_children():
			print("AUDIT OVBLK ", child.name, " min=", str(child.get_combined_minimum_size()))

	## --- cargo overlay, station plane -----------------------------------
	var overlay := station.get_node_or_null(NodePath("CargoLayer/CargoOverlay"))
	if overlay == null:
		print("AUDIT FATAL no station cargo overlay")
		get_tree().quit()
		return

	_print_ammo_state(profile)
	overlay.open()
	await _wait(0.4)
	_print_rows(overlay)
	await _shot("31_cargo_station_boot")

	## The owner's case: hold ammo zero. Clear every cargo entry and zero the packs.
	for item_id: StringName in (profile.cargo_items() as Dictionary).keys():
		profile.remove_cargo(item_id, int((profile.cargo_items() as Dictionary)[item_id]))
	for family: StringName in Catalog.ammo_ids():
		if profile.has_method(&"set_ammo"):
			profile.call(&"set_ammo", family, 0)
	overlay.select_category(StringName("all"))
	await _wait(0.4)
	_print_rows(overlay)
	await _shot("32_cargo_station_zero_ammo")
	overlay.close()
	await _wait(0.3)

	## A full mixed hold: ore, ingots, components, fuel, hold ammo and a loaded pack.
	profile.add_cargo(_ore_id("iron"), 6)
	profile.add_cargo(_ore_id("copper"), 2)
	profile.add_cargo(_ingot_id("iron"), 4)
	profile.add_cargo(_ingot_id("chromium"), 1)
	profile.add_cargo(_component_id(false), 3)
	profile.add_cargo(_component_id(true), 2)
	var laser_item := Catalog.ammo_item_id(StringName("laser"))
	if laser_item != StringName(""):
		profile.add_cargo(laser_item, 3)
	var rocket_item := Catalog.ammo_item_id(StringName("rocket"))
	if rocket_item != StringName(""):
		profile.add_cargo(rocket_item, 2)
	if profile.has_method(&"set_ammo"):
		profile.call(&"set_ammo", StringName("laser"), 137)
		profile.call(&"set_ammo", StringName("rocket"), 24)
	overlay.open()
	overlay.select_category(StringName("all"))
	await _wait(0.4)
	_print_rows(overlay)
	await _shot("33_cargo_station_mixed_all")
	for category in ["ammo", "ore", "ingots", "components", "fuel"]:
		overlay.select_category(StringName(category))
		await _wait(0.25)
		await _shot("34_cargo_station_tab_" + category)
	overlay.close()
	await _wait(0.3)

	## --- flight plane ------------------------------------------------------
	_router().route(StringName("game"))
	await _wait_idle()
	await _wait(2.0)
	var game := get_tree().root.get_node_or_null(NodePath("Game"))
	if game == null:
		print("AUDIT FATAL no game scene; children follow")
		var names := []
		for child in get_tree().root.get_children():
			names.append(str(child.name))
		print("AUDIT root children: ", ", ".join(names))
		get_tree().quit()
		return
	await _shot("41_hud_flight")
	if game.has_method(&"_set_cargo_open"):
		game.call(&"_set_cargo_open", true)
		await _wait(0.4)
		var flight_overlay: Node = game.find_child("CargoOverlay", true, false)
		if flight_overlay != null:
			_print_rows(flight_overlay)
		await _shot("42_hud_flight_cargo")
		game.call(&"_set_cargo_open", false)

	print("AUDIT DONE index=", _index)
	get_tree().quit()


## --- helpers ------------------------------------------------------------


func _router() -> Node:
	return get_node_or_null(NodePath("/root/Router"))


func _profile() -> Node:
	return get_node_or_null(NodePath("/root/PlayerProfile"))


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _wait_idle() -> void:
	var router := _router()
	var budget := 6.0
	while router != null and router.is_busy() and budget > 0.0:
		await get_tree().create_timer(0.1).timeout
		budget -= 0.1
	await _wait(0.2)


func _shot(shot_name: String) -> void:
	await _wait(0.1)
	var image := get_viewport().get_texture().get_image()
	_index += 1
	var path := "%s/%02d_%s.png" % [OUT_DIR, _index, shot_name]
	image.save_png(path)
	print("AUDIT SHOT ", path, " ", image.get_width(), "x", image.get_height())


func _print_ammo_state(profile: Node) -> void:
	for family: StringName in Catalog.ammo_ids():
		var rounds := int(profile.call(&"ammo_of", family))
		var item_id := Catalog.ammo_item_id(family)
		var units := int((profile.cargo_items() as Dictionary).get(item_id, 0))
		print("AUDIT AMMOFAM ", family, " rounds=", rounds, " item=", item_id, " hold_units=", units)
		print("AUDIT AMMOMAX ", family, " max=", int(profile.call(&"ammo_max", family)))

func _print_rows(overlay: Node) -> void:
	for row: Dictionary in (overlay.slot_rows() as Array):
		print("AUDIT ROW ", row["category"], " | ", row["name"], " | ", row["amount"],
				" | dispose=", row["dispose"])
	print("AUDIT BANDS ", str(overlay.band_texts()))
	print("AUDIT PANEL min=", str(overlay._panel.custom_minimum_size),
			" size=", str(overlay._panel.size))
	var scroll: ScrollContainer = overlay._scroll
	print("AUDIT SCROLL size=", str(scroll.size), " min=", str(scroll.custom_minimum_size))
	var content: VBoxContainer = scroll.get_child(0)
	print("AUDIT CONTENT size=", str(content.size), " min=", str(content.get_combined_minimum_size()))
	var rows_box: VBoxContainer = overlay._rows
	if rows_box.get_child_count() > 0:
		var first := rows_box.get_child(rows_box.get_child_count() - 1)
		print("AUDIT FIRSTROW ", first.name, " size=", str(first.size),
				" min=", str(first.get_combined_minimum_size()))
		var inner := first.get_child(0) if first.get_child_count() > 0 else null
		if inner != null and inner.get_child_count() > 0:
			for child in inner.get_child(0).get_children():
				print("AUDIT COL ", child.name, " size=", str(child.size),
						" min=", str(child.get_combined_minimum_size()))


## The pane-fit probe: every pane's own minimum against the space the shell's
## host actually gives it - the container-stability audit's hard numbers.
func _probe_pane_fit(station: Node, services: bool = false) -> void:
	var host_margin: Control = station.get_node_or_null(NodePath("Layout/Page/Body/ModuleHost/HostMargin"))
	var available := Vector2.ZERO
	if host_margin != null:
		available = host_margin.size
		print("AUDIT HOST available=", str(available))
	var panes: Array = []
	if services:
		var map: Dictionary = station.get("_service_panes")
		for key in map:
			panes.append(map[key])
	else:
		panes = station.get("_panels")
		var overview: Control = station.get("_overview")
		if overview != null:
			panes.append(overview)
	for pane in panes:
		if pane == null:
			continue
		var minimum: Vector2 = pane.get_combined_minimum_size()
		var over := minimum.y - available.y
		print("AUDIT PANE ", pane.name, " min=", str(minimum), " over_h=", "%.1f" % over)
		if over > 0.0:
			for child in pane.get_children():
				print("AUDIT   BLK ", child.name, " min_y=",
						"%.1f" % child.get_combined_minimum_size().y)


func _ore_id(mineral: String) -> StringName:
	return MineralCatalogScript.ore_id(StringName(mineral))


func _ingot_id(mineral: String) -> StringName:
	return MineralCatalogScript.ingot_id(StringName(mineral))


func _component_id(power: bool) -> StringName:
	for entry: Dictionary in ComponentCatalogScript.COMPONENTS:
		var family := StringName(entry.get(&"family", ""))
		if (family == StringName("pow")) == power:
			return StringName(entry.get(&"id", ""))
	return &""
