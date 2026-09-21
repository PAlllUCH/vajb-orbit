extends Node
## R1 review probe for wave P2-A. Re-measures, from the shipped code and the shipped
## scenes, every number the wave's five worker reports quote:
##
##   ~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_r1_frames.tscn
##
## Sections, in order:
##   1. the nine matrices, parsed independently of `ShipFit` (the table below is R1's own
##      read of 08 section 3.2 / section 3, not the constant under test);
##   2. the engine arithmetic, A/B against the pre-wave `ship_fit.gd` (loaded from
##      `tests/probe_r1_prewave_fit.gd`, a byte copy of HEAD's file minus its class_name)
##      plus the legacy singular `engine` key and the 1.40 ceiling;
##   3. the ten NPC hulls' empty shapes;
##   4. the shipped SHIPYARD panel scene, hull by hull (cells, columns, gaps, caption,
##      stat rows, list metas);
##   5. the shipped LAUNCH panel scene, hull by hull (nine brief rows);
##   6. the shipped HUD scene, hull by hull (W cells pushed = cells drawn);
##   7. the roster, the catalogue and the one-literal rule.
##
## Self-quitting and bounded: it prints and calls `quit()` at the end of `_ready`, and it
## never writes `user://profile.cfg` (the launch section borrows `_active_ship` in memory
## and hands it straight back).

const FitData := preload("res://game/ship_fit.gd")
const ModuleData := preload("res://game/module_catalog.gd")
const StationData := preload("res://game/station_catalog.gd")
const PreWave := preload("res://tests/probe_r1_prewave_fit.gd")
const ShipyardScene := preload("res://ui/station/shipyard_panel.tscn")
const LaunchScene := preload("res://ui/station/launch_panel.tscn")
const HudScene := preload("res://ui/hud/hud.tscn")

const TAG := "[r1]"

const HULLS: Array[StringName] = [
	&"ship_fighter",
	&"ship_vanguard",
	&"ship_miner",
	&"ship_trader",
	&"ship_corvette",
	&"ship_freighter",
	&"ship_gunship",
	&"ship_patrol",
	&"ship_destroyer",
]

const NPC_HULLS: Array[StringName] = [
	&"ship_swarmer",
	&"ship_sibur",
	&"ship_turret_platform",
	&"ship_boss_maw",
	&"ship_sibelon",
	&"ship_apex",
	&"ship_interceptor",
	&"ship_bomber",
	&"ship_drone_swarm",
	&"ship_mine_layer",
]

## R1's own derivation: 08 section 3.2's matrices counted by hand (the block's col/row
## order, spaces removed) and compared cell by cell with 08 section 3's table. `grid` is
## the block's own `(cols x rows)` header, `counts` its E/P/W/S/H/C/B/U row, `total` its sum.
const DOC_TABLE: Dictionary = {
	&"ship_fighter": {&"grid": Vector2i(4, 3), &"counts": [1, 1, 2, 1, 1, 1, 1, 0], &"total": 8},
	&"ship_vanguard": {&"grid": Vector2i(4, 4), &"counts": [1, 1, 3, 1, 2, 1, 1, 1], &"total": 11},
	&"ship_miner": {&"grid": Vector2i(4, 4), &"counts": [2, 1, 2, 1, 2, 1, 0, 3], &"total": 12},
	&"ship_trader": {&"grid": Vector2i(4, 4), &"counts": [2, 1, 1, 1, 2, 2, 1, 3], &"total": 13},
	&"ship_corvette": {&"grid": Vector2i(4, 4), &"counts": [1, 1, 4, 2, 2, 1, 1, 1], &"total": 13},
	&"ship_freighter": {&"grid": Vector2i(4, 5), &"counts": [3, 1, 1, 1, 3, 1, 0, 5], &"total": 15},
	&"ship_gunship": {&"grid": Vector2i(4, 5), &"counts": [2, 1, 5, 2, 2, 1, 0, 1], &"total": 14},
	&"ship_patrol": {&"grid": Vector2i(4, 5), &"counts": [2, 1, 4, 2, 3, 2, 1, 2], &"total": 17},
	&"ship_destroyer": {&"grid": Vector2i(5, 6), &"counts": [3, 1, 7, 3, 4, 2, 1, 2], &"total": 23},
}

## 08 section 2's ladder order and its frozen columns (cost, hull, shield, cargo, Weapons).
const DOC_ROSTER: Array[Dictionary] = [
	{&"id": &"ship_fighter", &"name": "Lancer", &"cost": 9000, &"hull": 700, &"shield": 400, &"cargo": 25, &"w": 2},
	{&"id": &"ship_vanguard", &"name": "Vanguard", &"cost": 18000, &"hull": 1000, &"shield": 600, &"cargo": 40, &"w": 3},
	{&"id": &"ship_miner", &"name": "Delver", &"cost": 16000, &"hull": 1100, &"shield": 500, &"cargo": 55, &"w": 2},
	{&"id": &"ship_trader", &"name": "Courier", &"cost": 21000, &"hull": 950, &"shield": 550, &"cargo": 60, &"w": 1},
	{&"id": &"ship_corvette", &"name": "Spearhead", &"cost": 27000, &"hull": 1300, &"shield": 700, &"cargo": 35, &"w": 4},
	{&"id": &"ship_freighter", &"name": "Mule", &"cost": 24000, &"hull": 1600, &"shield": 500, &"cargo": 120, &"w": 1},
	{&"id": &"ship_gunship", &"name": "Bulwark", &"cost": 36000, &"hull": 1400, &"shield": 650, &"cargo": 50, &"w": 5},
	{&"id": &"ship_patrol", &"name": "Warden", &"cost": 54000, &"hull": 1800, &"shield": 800, &"cargo": 60, &"w": 4},
	{&"id": &"ship_destroyer", &"name": "Obliterator", &"cost": 72000, &"hull": 2200, &"shield": 900, &"cargo": 80, &"w": 7},
]

const ENGINE_SETS: Array[Array] = [
	[&"e_std"],
	[&"e_ion"],
	[&"e_vector"],
	[&"e_std", &"e_std"],
	[&"e_std", &"e_ion"],
	[&"e_std", &"e_vector"],
	[&"e_std", &"e_ion", &"e_vector"],
	[&"e_ion", &"e_vector"],
	[&"e_ion", &"e_ion"],
	[&"e_vector", &"e_vector"],
	[&"e_vector", &"e_vector", &"e_vector"],
]

## 08 section 3's own column order, so the derived counts are compared in the table's
## order rather than in `FIT_SLOT_KEYS`' display order.
const LETTERS: Array[String] = ["E", "P", "W", "S", "H", "C", "B", "U"]
const LETTER_KEYS: Array[StringName] = [
	&"engines", &"power", &"weapons", &"shields", &"armour", &"computers", &"boosters", &"utility",
]

## The three hulls the engine arithmetic is measured on: one cell, two, three.
const ENGINE_HULLS: Array[StringName] = [&"ship_fighter", &"ship_miner", &"ship_freighter"]

var _fails: int = 0


func _ready() -> void:
	_section("1. the nine matrices, R1's own table vs ShipFit")
	_matrix_section()
	_section("2. engine arithmetic: pre-wave A/B, the legacy key, the ceiling")
	_engine_section()
	_section("3. the NPC hulls' empty shapes")
	_npc_section()
	_section("4. SHIPYARD panel scene, hull by hull")
	_shipyard_section()
	_section("5. LAUNCH panel scene, hull by hull")
	_launch_section()
	_section("6. HUD scene, W cells per hull")
	_hud_section()
	_section("7. roster, catalogue and the one-literal rule")
	_catalog_section()
	print("%s DONE fails=%d" % [TAG, _fails])
	get_tree().quit(0)


func _section(title: String) -> void:
	print("%s --- %s ---" % [TAG, title])


func _check(label: String, ok: bool, detail: String = "") -> void:
	if not ok:
		_fails += 1
	print("%s %s %s%s" % [TAG, "ok  " if ok else "FAIL", label, "" if detail.is_empty() else " | " + detail])


func _matrix_section() -> void:
	var doc_total := 0
	for hull: StringName in HULLS:
		var row: Dictionary = DOC_TABLE[hull]
		var size := FitData.grid_size(hull)
		var cells: Array = FitData.grid_cells(hull)
		var counts: Dictionary = FitData.grid_counts(hull)
		var derived: Array[int] = []
		for key: StringName in LETTER_KEYS:
			derived.append(int(counts[key]))
		var total := 0
		for value: int in derived:
			total += value
		doc_total += total
		var cells_ok: bool = cells.size() == row[&"grid"].x * row[&"grid"].y
		var rows_ok := true
		var row_index := 0
		for line: String in FitData.grid_rows(hull):
			for col: int in line.length():
				var cell: Dictionary = cells[row_index * size.x + col]
				rows_ok = rows_ok and int(cell[&"col"]) == col and int(cell[&"row"]) == row_index
			row_index += 1
		var weapons_match: bool = int(FitData.HULLS[hull][&"weapons"]) == int(counts[&"weapons"])
		_check(
			"%-16s grid=%s counts=%s total=%d" % [hull, str(size), str(derived), total],
			size == row[&"grid"]
			and derived == row[&"counts"]
			and total == row[&"total"]
			and cells_ok
			and rows_ok
			and weapons_match,
			"doc grid=%s counts=%s total=%d HULLS.weapons=%d"
			% [
				str(row[&"grid"]),
				str(row[&"counts"]),
				row[&"total"],
				int(FitData.HULLS[hull][&"weapons"]),
			]
		)
	print("%s nine-hull total sum = %d (doc 8+11+12+13+13+15+14+17+23 = 126)" % [TAG, doc_total])


func _fit_with(hull: StringName, engines: Array) -> Dictionary:
	var fit: Dictionary = FitData.standard_fit(hull)
	fit[&"engines"] = engines.duplicate()
	return fit


func _expected_mult(engines: Array) -> Array:
	var speed := 1.0
	var turn := 1.0
	for id: StringName in engines:
		var effects: Dictionary = ModuleData.module(id).get(&"effects", {})
		speed += float(effects.get(&"speed_mult", 1.0)) - 1.0
		turn += float(effects.get(&"turn_mult", 1.0)) - 1.0
	return [speed, minf(speed, FitData.ENGINE_MULT_CEILING), turn]


func _engine_section() -> void:
	print("%s ENGINE_MULT_CEILING=%s MOUNT_SPREAD=%s" % [TAG, str(FitData.ENGINE_MULT_CEILING), str(FitData.MOUNT_SPREAD)])
	for hull: StringName in ENGINE_HULLS:
		var base: ShipStats = FitData.resolve(hull, FitData.standard_fit(hull))
		print(
			"%s %s base speed=%.4f turn=%.4f (engine cells=%d)"
			% [TAG, hull, base.max_speed, base.turn_rate, FitData.slot_capacity(hull, &"engines")]
		)
		for engines: Array in ENGINE_SETS:
			var stats: ShipStats = FitData.resolve(hull, _fit_with(hull, engines))
			var expected := _expected_mult(engines)
			var legal := FitData.fit_legal(hull, _fit_with(hull, engines))
			_check(
				"  %-36s x%.4f turn x%.4f legal=%s"
				% [str(engines), stats.max_speed / base.max_speed, stats.turn_rate / base.turn_rate, str(legal[&"legal"])],
				is_equal_approx(stats.max_speed, base.max_speed * float(expected[1]))
				and is_equal_approx(stats.turn_rate, base.turn_rate * float(expected[2])),
				"expected sum=%.4f clamped=%.4f turn=%.4f"
				% [expected[0], expected[1], expected[2]]
			)

	## The pre-wave A/B: HEAD's own resolve, with the pre-wave fit shape, on every hull.
	print("%s pre-wave A/B (HEAD resolve vs shipped resolve, one e_std + p_std):" % TAG)
	for hull: StringName in HULLS:
		var pre_fit := {
			&"engine": &"e_std",
			&"power": &"p_std",
			&"weapons": [],
			&"shields": [],
			&"armour": [],
			&"computers": [],
			&"boosters": [],
			&"utility": [],
		}
		var new_fit := {
			&"engines": [&"e_std"],
			&"power": &"p_std",
			&"weapons": [],
			&"shields": [],
			&"armour": [],
			&"computers": [],
			&"boosters": [],
			&"utility": [],
		}
		var pre: ShipStats = PreWave.resolve(hull, pre_fit)
		var now: ShipStats = FitData.resolve(hull, new_fit)
		var same := _same_stats(pre, now)
		_check(
			"%-16s pre speed=%.4f turn=%.4f | shipped speed=%.4f turn=%.4f"
			% [hull, pre.max_speed, pre.turn_rate, now.max_speed, now.turn_rate],
			same,
			"all ShipStats fields identical"
		)

	## The same fit through the pre-wave STANDARD_FIT (HEAD's own row) and the legacy key.
	var pre_standard: ShipStats = PreWave.resolve(&"ship_vanguard", PreWave.STANDARD_FIT)
	var legacy: ShipStats = FitData.resolve(&"ship_vanguard", PreWave.STANDARD_FIT)
	var canonical: ShipStats = FitData.resolve(&"ship_vanguard", FitData.standard_fit(&"ship_vanguard"))
	_check(
		"pre-wave STANDARD_FIT: HEAD %.4f/%.4f, shipped via legacy key %.4f/%.4f, shipped canonical %.4f/%.4f"
		% [
			pre_standard.max_speed,
			pre_standard.turn_rate,
			legacy.max_speed,
			legacy.turn_rate,
			canonical.max_speed,
			canonical.turn_rate,
		],
		_same_stats(pre_standard, legacy) and _same_stats(legacy, canonical)
	)
	## `engines` wins when both keys are present.
	var both: ShipStats = FitData.resolve(&"ship_vanguard", {
		&"engine": &"e_std",
		&"engines": [&"e_ion"],
		&"power": &"p_std",
	})
	var only_ion: ShipStats = FitData.resolve(&"ship_vanguard", {&"engines": [&"e_ion"], &"power": &"p_std"})
	_check(
		"both keys present: engines wins (%.4f == e_ion-only %.4f)" % [both.max_speed, only_ion.max_speed],
		is_equal_approx(both.max_speed, only_ion.max_speed)
	)
	## A legacy singular `engine` as an Array.
	var legacy_array: ShipStats = FitData.resolve(&"ship_vanguard", {&"engine": [&"e_ion"], &"power": &"p_std"})
	_check(
		"legacy engine as Array resolves (%.4f == %.4f)" % [legacy_array.max_speed, only_ion.max_speed],
		is_equal_approx(legacy_array.max_speed, only_ion.max_speed)
	)


func _same_stats(a: ShipStats, b: ShipStats) -> bool:
	if a == null or b == null:
		return a == b
	var fields: Array[StringName] = [
		&"max_speed", &"accel_time", &"coast_time", &"turn_rate", &"turn_spinup", &"hull_mass",
		&"hull_max", &"shield_max", &"shield_regen", &"damage_mult", &"lock_range",
		&"scan_range", &"tractor_range", &"tractor_speed", &"tractor_streams", &"cargo_max",
		&"energy_max", &"energy_regen", &"fuel_max",
	]
	for field: StringName in fields:
		if not is_equal_approx(float(a.get(field)), float(b.get(field))):
			print("%s   field %s differs: %s vs %s" % [TAG, field, str(a.get(field)), str(b.get(field))])
			return false
	if a.boosters != b.boosters:
		print("%s   boosters differ: %s vs %s" % [TAG, str(a.boosters), str(b.boosters)])
		return false
	return true


func _npc_section() -> void:
	var empty_counts := {}
	for key: StringName in FitData.FIT_SLOT_KEYS:
		empty_counts[key] = 0
	for hull: StringName in NPC_HULLS:
		var counts: Dictionary = FitData.grid_counts(hull)
		var ok := (
			FitData.grid_rows(hull).is_empty()
			and FitData.grid_cells(hull).is_empty()
			and FitData.grid_size(hull) == Vector2i.ZERO
			and counts == empty_counts
			and FitData.slot_capacity(hull, &"weapons") == 0
			and FitData.standard_fit(hull).is_empty()
			and FitData.mount_offset(hull, &"engines", 0) == Vector2.ZERO
			and bool(FitData.fit_legal(hull, {})[&"legal"]) == false
		)
		_check("%-24s empty shapes" % hull, ok, "counts=%s" % str(counts.values()))
	var bogus: ShipStats = FitData.resolve(&"ship_not_a_hull", {})
	_check("a bogus hull id resolves to null (with its push_error)", bogus == null)


func _shipyard_section() -> void:
	var panel: Node = ShipyardScene.instantiate()
	add_child(panel)
	var grid := panel.find_child("HardpointSlots", true, false) as GridContainer
	var caption := panel.find_child("HardpointCaption", true, false) as Label
	_check("the shipped %HardpointSlots node is a GridContainer", grid != null and grid is GridContainer)
	for hull: StringName in HULLS:
		panel.call(&"_set_layout_grid", hull)
		var cells: Array = FitData.grid_cells(hull)
		var plates := 0
		var gaps := 0
		var sizes_ok := true
		for child: Node in grid.get_children():
			if child is TextureButton:
				plates += 1
				sizes_ok = sizes_ok and (child as Control).custom_minimum_size == Vector2(48, 48)
				sizes_ok = sizes_ok and (child as TextureButton).ignore_texture_size
			else:
				gaps += 1
				sizes_ok = sizes_ok and (child as Control).custom_minimum_size == Vector2(48, 48)
		var total := 0
		for value: Variant in FitData.grid_counts(hull).values():
			total += int(value)
		var expected_caption := "SLOT LAYOUT · %d CELLS · %d ENGINES" % [total, int(FitData.grid_counts(hull)[&"engines"])]
		_check(
			"%-16s children=%d plates=%d gaps=%d columns=%d caption='%s'"
			% [hull, grid.get_child_count(), plates, gaps, grid.columns, caption.text],
			grid.get_child_count() == cells.size()
			and plates == total
			and gaps == cells.size() - total
			and grid.columns == DOC_TABLE[hull][&"grid"].x
			and caption.text == expected_caption
			and sizes_ok
		)
	## The five stat rows, hull by hull: the SELECTED column is driven by setting the
	## panel's own `_selected_id` and re-running its own `_refresh_preview`.
	var profile: Node = get_tree().root.get_node_or_null(NodePath(&"PlayerProfile"))
	var stat_cells: Dictionary = panel.get("_stat_cells")
	var keys: Array[String] = []
	for key: StringName in stat_cells.keys():
		keys.append(String(key))
	print("%s stat row keys: %s" % [TAG, str(keys)])
	_check(
		"the five stat rows are hull/shield/cargo/engines/slots",
		keys == ["hull", "shield", "cargo", "engines", "slots"],
		str(keys)
	)
	for entry: Dictionary in DOC_ROSTER:
		var hull: StringName = entry[&"id"]
		panel.set("_selected_id", hull)
		panel.call(&"_refresh_preview", profile)
		var selected: Array[String] = []
		for key: StringName in [&"hull", &"shield", &"cargo", &"engines", &"slots"]:
			selected.append(String(((stat_cells[key] as Array)[0] as Label).text))
		var total := 0
		for count: Variant in FitData.grid_counts(hull).values():
			total += int(count)
		_check(
			"%-16s SELECTED stat column = %s" % [hull, str(selected)],
			selected
			== [
				str(entry[&"hull"]),
				str(entry[&"shield"]),
				str(entry[&"cargo"]),
				str(int(FitData.grid_counts(hull)[&"engines"])),
				str(total),
			]
		)
	var metas: Array[String] = []
	var payloads: Array = panel.get("_payloads")
	for payload: Dictionary in payloads:
		var row: Node = payload[&"row"]
		for label: Node in _labels_under(row):
			var text := String((label as Label).text)
			if text.contains("HULL ·"):
				metas.append(text)
	print("%s list metas (%d rows): %s" % [TAG, metas.size(), str(metas)])
	_check(
		"nine list rows carry a '%d HULL · %d SLOTS' meta",
		metas.size() == 9 and metas[1] == "1000 HULL · 11 SLOTS",
		str(metas)
	)
	panel.queue_free()


func _same_set(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for entry: Variant in a:
		if not b.has(entry):
			return false
	return true


func _labels_under(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	for child: Node in node.get_children():
		if child is Label:
			out.append(child)
		out.append_array(_labels_under(child))
	return out


func _launch_section() -> void:
	var panel: Node = LaunchScene.instantiate()
	add_child(panel)
	var profile: Node = get_tree().root.get_node_or_null(NodePath(&"PlayerProfile"))
	var previous: Variant = null
	if profile != null:
		previous = profile.get("_active_ship")
	var rows := panel.find_child("BriefRows", true, false) as VBoxContainer
	for entry: Dictionary in DOC_ROSTER:
		var hull: StringName = entry[&"id"]
		if profile != null:
			profile.set("_active_ship", hull)
		panel.call(&"_refresh_brief")
		var order: Array[String] = []
		var values: Dictionary = {}
		var index := 0
		for child: Node in rows.get_children():
			if child is HBoxContainer:
				var label: Label = (child as HBoxContainer).get_child(0) as Label
				var value: Label = (child as HBoxContainer).get_child(1) as Label
				order.append(String(label.text))
				values[String(label.text)] = String(value.text)
				index += 1
		var counts: Dictionary = FitData.grid_counts(hull)
		var total := 0
		for count: Variant in counts.values():
			total += int(count)
		_check(
			"%-16s rows=%d ENGINES=%s SLOT CELLS=%s HARDPOINTS=%s"
			% [hull, index, values.get("ENGINES", "?"), values.get("SLOT CELLS", "?"), values.get("HARDPOINTS", "?")],
			index == 9
			and values.get("ENGINES", "") == str(int(counts[&"engines"]))
			and values.get("SLOT CELLS", "") == str(total)
			and values.get("HARDPOINTS", "") == str(entry[&"w"])
			and values.get("HULL LIMIT", "") == str(entry[&"hull"])
			and values.get("SHIELD LIMIT", "") == str(entry[&"shield"])
			and order == [
				"DESTINATION", "ACTIVE HULL", "HULL LIMIT", "SHIELD LIMIT", "ENGINES",
				"HARDPOINTS", "SLOT CELLS", "CARGO", "AMMUNITION",
			],
			"order=%s" % str(order)
		)
	if profile != null:
		profile.set("_active_ship", previous)
		print("%s profile _active_ship restored to %s" % [TAG, str(previous)])
	var cargo := panel.find_child("CargoSlots", true, false) as HBoxContainer
	var cargo_ok := cargo.get_child_count() == 5
	for child: Node in cargo.get_children():
		cargo_ok = cargo_ok and (child as Control).custom_minimum_size == Vector2(40, 40)
	_check("the cargo strip is still five 40 px plates", cargo_ok, "children=%d" % cargo.get_child_count())
	panel.queue_free()


func _hud_section() -> void:
	var hud: Node = HudScene.instantiate()
	add_child(hud)
	for hull: StringName in HULLS:
		var cells := _hud_cells(hull)
		hud.call(&"set_hull_slots", hull, cells)
		var slots: Array = hud.get("_weapon_slots")
		var grid: GridContainer = hud.get("_weapon_grid")
		var disabled := 0
		var sizes_ok := true
		for slot: Node in slots:
			if (slot as BaseButton).disabled:
				disabled += 1
			sizes_ok = sizes_ok and (slot as Control).custom_minimum_size == Vector2(48, 48)
			sizes_ok = sizes_ok and (slot as TextureButton).ignore_texture_size
		var w_count := int(FitData.grid_counts(hull)[&"weapons"])
		var expected_columns := maxi(mini(cells.size(), 5), 1)
		var not_selectable := maxi(cells.size() - 5, 0)
		_check(
			"%-16s pushed=%d drawn=%d columns=%d disabled=%d (W cells=%d)"
			% [hull, cells.size(), slots.size(), grid.columns, disabled, w_count],
			cells.size() == w_count
			and slots.size() == cells.size()
			and grid.columns == expected_columns
			and disabled == not_selectable
			and (hud.call(&"hull_slots") as Array).size() == cells.size()
			and sizes_ok
		)
	## An empty push keeps a valid grid rather than a zero-column one.
	hud.call(&"set_hull_slots", &"", [])
	_check(
		"an empty push keeps a valid grid (columns=%d, children=%d)"
		% [(hud.get("_weapon_grid") as GridContainer).columns, (hud.get("_weapon_grid") as GridContainer).get_child_count()],
		(hud.get("_weapon_grid") as GridContainer).columns >= 1
	)
	hud.queue_free()


func _hud_cells(hull: StringName) -> Array:
	var fit: Dictionary = FitData.standard_fit(hull)
	var weapons: Array = fit.get(&"weapons", [])
	var cells: Array = []
	for cell: Dictionary in FitData.grid_cells(hull):
		if cell[&"type"] != &"weapons":
			continue
		var index := int(cell[&"index"])
		var module_id := &""
		if index < weapons.size():
			module_id = StringName(weapons[index])
		cells.append({
			&"slot": &"weapons",
			&"index": index,
			&"module": module_id,
			&"icon": ModuleData.icon_path(module_id) if module_id != &"" else "",
			&"fitted": module_id != &"",
			&"selectable": true,
		})
	return cells


func _catalog_section() -> void:
	_check(
		"ModuleCatalog.MODULES carries 32 rows",
		ModuleData.MODULES.size() == 32,
		"size=%d" % ModuleData.MODULES.size()
	)
	_check(
		"ShipFit.MODULES is the catalogue's own dictionary (a name/icon key it never had)",
		FitData.MODULES[&"w_laser"].has(&"name") and FitData.MODULES[&"w_laser"].has(&"icon")
	)
	var drift: Array[String] = []
	for id: StringName in PreWave.MODULES:
		if not ModuleData.MODULES.has(id):
			drift.append("%s missing" % id)
			continue
		for field: StringName in [&"slot", &"draw", &"effects"]:
			if PreWave.MODULES[id][field] != ModuleData.MODULES[id][field]:
				drift.append(
					"%s.%s %s -> %s"
					% [id, field, str(PreWave.MODULES[id][field]), str(ModuleData.MODULES[id][field])]
				)
	_check("every pre-wave MODULES row's slot/draw/effects is verbatim", drift.is_empty(), str(drift))
	_check(
		"StationCatalog.SHIPS has nine rows",
		StationData.SHIPS.size() == 9,
		"size=%d" % StationData.SHIPS.size()
	)
	var index := 0
	for entry: Dictionary in DOC_ROSTER:
		var ship: Dictionary = StationData.ship(entry[&"id"])
		var preview_ok := (
			String(ship.get(&"preview", ""))
			== "res://assets/ships/ship_%s_side.png" % String(entry[&"id"]).trim_prefix("ship_")
			and FileAccess.file_exists(String(ship.get(&"preview", "")))
		)
		_check(
			"roster[%d] %-16s cost=%d hull=%d shield=%d cargo=%d hardpoints=%d"
			% [
				index,
				entry[&"id"],
				int(ship.get(&"cost", 0)),
				int(ship.get(&"hull", 0)),
				int(ship.get(&"shield", 0)),
				int(ship.get(&"cargo", 0)),
				int(ship.get(&"hardpoints", 0)),
			],
			StationData.SHIPS[index][&"id"] == entry[&"id"]
			and String(ship.get(&"name", "")) == entry[&"name"]
			and int(ship.get(&"cost", 0)) == entry[&"cost"]
			and int(ship.get(&"hull", 0)) == entry[&"hull"]
			and int(ship.get(&"shield", 0)) == entry[&"shield"]
			and int(ship.get(&"cargo", 0)) == entry[&"cargo"]
			and int(ship.get(&"hardpoints", 0)) == entry[&"w"]
			and int(ship.get(&"hardpoints", 0)) == int(FitData.grid_counts(entry[&"id"])[&"weapons"])
			and preview_ok
		)
		index += 1
	## The nine standard fits, each legal on its own hull (09 section 9 + 09 section 4).
	for entry: Dictionary in DOC_ROSTER:
		var hull: StringName = entry[&"id"]
		var verdict: Dictionary = FitData.fit_legal(hull, FitData.standard_fit(hull))
		_check(
			"standard_fit(%-16s) is legal (power %d/%d)" % [hull, int(verdict[&"power"][&"draw"]), int(verdict[&"power"][&"out"])],
			bool(verdict[&"legal"])
			and (verdict[&"overflow"] as Dictionary).is_empty()
			and (verdict[&"missing"] as Array).is_empty()
			and (verdict[&"duplicates"] as Array).is_empty(),
			str(verdict)
		)
	_check(
		"SLOT_GRIDS and HULLS carry the same nine keys, all player hulls",
		FitData.SLOT_GRIDS.size() == 9
		and FitData.SLOT_GRIDS.keys().size() == 9
		and FitData.HULLS.size() == 9
		and _same_set(FitData.SLOT_GRIDS.keys(), FitData.HULLS.keys()),
		"grids=%s hulls=%s" % [str(FitData.SLOT_GRIDS.keys()), str(FitData.HULLS.keys())]
	)

	## mount_offset: 09 section 8's formula, re-derived here.
	var offset_ok := true
	for hull: StringName in HULLS:
		var size := FitData.grid_size(hull)
		for cell: Dictionary in FitData.grid_cells(hull):
			if bool(cell[&"gap"]):
				continue
			var got := FitData.mount_offset(hull, cell[&"type"], int(cell[&"index"]))
			var want := Vector2(
				(float(int(cell[&"col"])) + 0.5) / float(size.x) - 0.5,
				(float(int(cell[&"row"])) + 0.5) / float(size.y) - 0.5
			) * FitData.MOUNT_SPREAD
			offset_ok = offset_ok and got.is_equal_approx(want)
	_check("mount_offset is the 09 section 8 formula for every non-gap cell of every hull", offset_ok)
