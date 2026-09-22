@tool
extends McpTestSuite
## Suite p2a_ship_grids: the slot frames of CONTRACTS section 11 / 08 section 3.
##
## Two halves, and the first is the point of the suite: **08 section 3.2's fenced
## block is parsed out of `docs/gameplay/08_ship_classes.md` and compared with
## `ShipFit.SLOT_GRIDS` hull by hull and row by row**, and 08 section 3's counts
## table is parsed out of the same document and compared with `grid_counts` cell by
## cell, so neither the matrices nor the counts can drift from the data. The second
## half pins the derived API: capacities, legality, the engine set's summed
## arithmetic and ceiling, the standard fits, the mount geometry, and the module
## catalogue's own rows, names, icons and the one-literal alias.
##
## Pure data: no scene instancing, no editor API, no MCP.

const Fit := preload("res://game/ship_fit.gd")
const Catalog := preload("res://game/module_catalog.gd")

## 08 section 3.2's document, reached from the project root (the docs live one
## level above `res://`, which FileAccess resolves in a project run).
const DOC_PATH := "res://../docs/gameplay/08_ship_classes.md"

## 08 section 2's ladder: the nine player hulls, in that table's order.
const HULL_IDS: Array[StringName] = [
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

## 08 section 3's Total column: the non-gap cell count of each hull's matrix, in
## `HULL_IDS` order.
const HULL_TOTALS: Array[int] = [8, 11, 12, 13, 13, 15, 14, 17, 23]

## Rule 6 of CONTRACTS section 11: the NPC hulls, none of which fits modules.
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

## 09 section 3's module tables, transcribed: name (the CONTRACTS section 11 name
## table), tier (I-III as the project's 1-3) and the credits baseline of 09
## section 3.1-3.8. `draw` and `slot` are asserted against the same table.
const MODULE_ROWS: Array[Dictionary] = [
	{"id": &"w_laser", "name": "Laser MkII", "slot": &"weapons", "draw": 1, "tier": 1, "cost": 900},
	{"id": &"w_cannon", "name": "Cannon MkI", "slot": &"weapons", "draw": 1, "tier": 1, "cost": 1200},
	{"id": &"w_rocket", "name": "Rocket Pod", "slot": &"weapons", "draw": 2, "tier": 2, "cost": 2400},
	{"id": &"w_mine", "name": "Mine Layer", "slot": &"weapons", "draw": 1, "tier": 2, "cost": 1800},
	{"id": &"w_plasma", "name": "Plasma Coil", "slot": &"weapons", "draw": 3, "tier": 3, "cost": 4800},
	{"id": &"w_railgun", "name": "Railgun", "slot": &"weapons", "draw": 3, "tier": 3, "cost": 5200},
	{"id": &"w_mining", "name": "Mining Laser", "slot": &"weapons", "draw": 1, "tier": 1, "cost": 600},
	{"id": &"s_light", "name": "Light Shield", "slot": &"shields", "draw": 2, "tier": 1, "cost": 1400},
	{"id": &"s_heavy", "name": "Heavy Shield", "slot": &"shields", "draw": 3, "tier": 2, "cost": 3200},
	{"id": &"s_ion", "name": "Ion Shield", "slot": &"shields", "draw": 3, "tier": 3, "cost": 5600},
	{"id": &"h_plate_light", "name": "Light Plate", "slot": &"armour", "draw": 0, "tier": 1, "cost": 1100},
	{"id": &"h_plate_heavy", "name": "Heavy Plate", "slot": &"armour", "draw": 0, "tier": 2, "cost": 2900},
	{"id": &"h_composite", "name": "Composite Plate", "slot": &"armour", "draw": 0, "tier": 3, "cost": 5800},
	{"id": &"c_target", "name": "Targeting Computer", "slot": &"computers", "draw": 1, "tier": 1, "cost": 1600},
	{"id": &"c_scanner", "name": "Deep Scanner", "slot": &"computers", "draw": 1, "tier": 1, "cost": 1500},
	{"id": &"c_twin", "name": "Twin Targeting", "slot": &"computers", "draw": 1, "tier": 2, "cost": 3400},
	{"id": &"c_ewar", "name": "EWAR Suite", "slot": &"computers", "draw": 1, "tier": 2, "cost": 3800},
	{"id": &"c_nexus", "name": "Nexus Computer", "slot": &"computers", "draw": 1, "tier": 3, "cost": 6400},
	{"id": &"b_afterburner", "name": "Afterburner", "slot": &"boosters", "draw": 2, "tier": 1, "cost": 1900},
	{"id": &"b_fold", "name": "Fold Drive", "slot": &"boosters", "draw": 2, "tier": 3, "cost": 6800},
	{"id": &"u_cargo", "name": "Cargo Expansion", "slot": &"utility", "draw": 0, "tier": 1, "cost": 1200},
	{"id": &"u_salvage", "name": "Salvage Tractor", "slot": &"utility", "draw": 0, "tier": 1, "cost": 1000},
	{"id": &"u_refine", "name": "Refinery Module", "slot": &"utility", "draw": 1, "tier": 2, "cost": 2600},
	{"id": &"u_drones", "name": "Repair Drone Bay", "slot": &"utility", "draw": 1, "tier": 2, "cost": 3000},
	{"id": &"u_tractor", "name": "Tractor Array", "slot": &"utility", "draw": 1, "tier": 2, "cost": 2200},
	{"id": &"u_holds", "name": "Cargo Holds", "slot": &"utility", "draw": 0, "tier": 3, "cost": 4500},
	{"id": &"e_std", "name": "Standard Drive", "slot": &"engine", "draw": 0, "tier": 1, "cost": 800},
	{"id": &"e_ion", "name": "Ion Drive", "slot": &"engine", "draw": 0, "tier": 2, "cost": 3200},
	{"id": &"e_vector", "name": "Vector Drive", "slot": &"engine", "draw": 0, "tier": 3, "cost": 6200},
	{"id": &"p_std", "name": "Standard Reactor", "slot": &"power", "draw": 0, "tier": 1, "cost": 900},
	{"id": &"p_mk2", "name": "Reactor Mk2", "slot": &"power", "draw": 0, "tier": 2, "cost": 3600},
	{"id": &"p_core", "name": "Reactor Core", "slot": &"power", "draw": 0, "tier": 3, "cost": 7000},
]

## 09 section 3's stat effects, verbatim (the rows CONTRACTS section 11 says the
## catalogue copies from `ShipFit.MODULES`). Every other id carries none.
const MODULE_EFFECTS: Dictionary = {
	&"s_light": {&"shield_add": 200.0, &"regen_add": 4.0},
	&"s_heavy": {&"shield_add": 400.0, &"regen_add": 5.0},
	&"s_ion": {&"shield_add": 350.0, &"regen_add": 9.0},
	&"h_plate_light": {&"hull_add": 250.0, &"speed_penalty": -0.05},
	&"h_plate_heavy": {&"hull_add": 600.0, &"speed_penalty": -0.12},
	&"h_composite": {&"hull_add": 1000.0, &"speed_penalty": -0.10, &"mass_add": 0.10},
	&"c_target": {&"damage_add": 0.15},
	&"c_scanner": {&"scanner_add": 0.25},
	&"c_twin": {&"damage_add": 0.15},
	&"c_nexus": {&"damage_add": 0.15, &"scanner_add": 0.25},
	&"b_afterburner": {&"boost_speed_mult": 1.6, &"duration": 3.0, &"cooldown": 8.0},
	&"b_fold": {&"blink_distance": 400.0, &"cooldown": 20.0},
	&"u_cargo": {&"cargo_add": 15},
	&"u_salvage": {&"tractor_range_mult": 2.0, &"tractor_speed_mult": 2.0},
	&"u_tractor": {&"tractor_streams_add": 1},
	&"u_holds": {&"cargo_add": 40},
	&"e_std": {&"speed_mult": 1.0},
	&"e_ion": {&"speed_mult": 1.15},
	&"e_vector": {&"speed_mult": 1.25, &"turn_mult": 1.20},
	&"p_std": {&"power_add": 0.0},
	&"p_mk2": {&"power_add": 2.0},
	&"p_core": {&"power_add": 4.0},
}

## The five base weapon families draw the weapon-icon set; every other id draws the
## module set (CONTRACTS section 11's icon rule).
const WEAPON_ICON_FAMILIES: Dictionary = {
	&"w_laser": "laser",
	&"w_cannon": "cannon",
	&"w_rocket": "rocket",
	&"w_mine": "mine",
	&"w_plasma": "plasma",
}

## 09 section 9's per-hull standard fits, transcribed in `HULL_IDS` order.
const STANDARD_FITS: Array[Dictionary] = [
	{
		&"engines": [&"e_std"],
		&"power": &"p_std",
		&"weapons": [&"w_laser", &"w_laser"],
		&"shields": [&"s_light"],
		&"armour": [&"h_plate_light"],
	},
	{
		&"engines": [&"e_std"],
		&"power": &"p_std",
		&"weapons": [&"w_laser"],
		&"shields": [&"s_light"],
		&"armour": [&"h_plate_light"],
	},
	{&"engines": [&"e_std", &"e_std"], &"power": &"p_std"},
	{&"engines": [&"e_std", &"e_std"], &"power": &"p_std"},
	{&"engines": [&"e_std"], &"power": &"p_std"},
	{&"engines": [&"e_std", &"e_std", &"e_std"], &"power": &"p_std"},
	{&"engines": [&"e_std", &"e_std"], &"power": &"p_std"},
	{&"engines": [&"e_std", &"e_std"], &"power": &"p_std"},
	{&"engines": [&"e_std", &"e_std", &"e_std"], &"power": &"p_std"},
]

const EPSILON := 0.000001


func suite_name() -> String:
	return "p2a_ship_grids"


## ---------------------------------------------------------------------------
## 08 section 3.2, parsed out of the document
## ---------------------------------------------------------------------------


func test_document_matrix_block_equals_slot_grids() -> void:
	var grids := _document_grids()
	assert_eq(grids.size(), HULL_IDS.size(), "the document's block is nine hulls")
	for hull_id: StringName in HULL_IDS:
		var ship_class := String(Fit.HULLS[hull_id][&"ship_class"])
		assert_true(grids.has(ship_class), "the block carries the %s row" % ship_class)
		if not grids.has(ship_class):
			continue
		var expected: Array = grids[ship_class][&"grid"]
		var actual := Fit.grid_rows(hull_id)
		assert_eq(actual.size(), expected.size(), "%s row count" % ship_class)
		for index: int in mini(actual.size(), expected.size()):
			assert_eq(
				String(actual[index]),
				String(expected[index]),
				"%s row %d is the document's row with the spaces removed" % [ship_class, index]
			)


func test_document_matrix_dimensions_match_grid_size() -> void:
	var grids := _document_grids()
	for hull_id: StringName in HULL_IDS:
		var ship_class := String(Fit.HULLS[hull_id][&"ship_class"])
		if not grids.has(ship_class):
			assert_true(false, "the block carries the %s row" % ship_class)
			continue
		var row: Dictionary = grids[ship_class]
		var size := Fit.grid_size(hull_id)
		assert_eq(
			size,
			Vector2i(int(row[&"cols"]), int(row[&"rows"])),
			"%s is the document's (cols x rows)" % ship_class
		)
		assert_eq(
			size,
			Vector2i(Fit.grid_rows(hull_id)[0].length(), Fit.grid_rows(hull_id).size()),
			"%s: grid_size reads its own rows" % ship_class
		)


func test_document_counts_table_matches_grid_counts_cell_by_cell() -> void:
	var table := _document_counts()
	assert_eq(table.size(), HULL_IDS.size(), "08 section 3's table is nine hulls")
	for hull_id: StringName in HULL_IDS:
		var ship_class := String(Fit.HULLS[hull_id][&"ship_class"])
		assert_true(table.has(ship_class), "the table carries the %s row" % ship_class)
		if not table.has(ship_class):
			continue
		var row: Dictionary = table[ship_class]
		var counts := Fit.grid_counts(hull_id)
		var total := 0
		var cells: Dictionary = row[&"cells"]
		for letter: Variant in cells.keys():
			var slot_key := StringName(Fit.SLOT_TOKEN_KEYS[String(letter)])
			assert_eq(
				int(counts[slot_key]),
				int(cells[letter]),
				"%s: %s is the document's %s column" % [ship_class, String(slot_key), String(letter)]
			)
			total += int(cells[letter])
		assert_eq(total, int(row[&"total"]), "%s: the row sums to its Total" % ship_class)


func test_capacities_sum_to_the_documented_totals() -> void:
	for index: int in HULL_IDS.size():
		var hull_id: StringName = HULL_IDS[index]
		var counts := Fit.grid_counts(hull_id)
		var sum := 0
		for key: StringName in Fit.FIT_SLOT_KEYS:
			assert_true(counts.has(key), "%s carries the %s key" % [hull_id, key])
			sum += int(counts[key])
			assert_eq(
				Fit.slot_capacity(hull_id, key),
				int(counts[key]),
				"%s: slot_capacity(%s) is the grid count" % [hull_id, key]
			)
		assert_eq(sum, HULL_TOTALS[index], "%s has the documented %d cells" % [hull_id, HULL_TOTALS[index]])
		var cells := Fit.grid_cells(hull_id)
		var size := Fit.grid_size(hull_id)
		assert_eq(cells.size(), size.x * size.y, "%s: one cell per matrix position" % hull_id)
		var non_gap := 0
		for cell: Dictionary in cells:
			if not bool(cell[&"gap"]):
				non_gap += 1
		assert_eq(non_gap, HULL_TOTALS[index], "%s: the gaps are not cells" % hull_id)


func test_hull_weapons_equals_the_grid_count() -> void:
	for hull_id: StringName in HULL_IDS:
		var hull: Dictionary = Fit.HULLS[hull_id]
		assert_eq(
			int(hull[&"weapons"]),
			int(Fit.grid_counts(hull_id)[&"weapons"]),
			"%s: HULLS[hull].weapons is the grid's W count (one value, two readers)" % hull_id
		)
		assert_eq(
			int(hull[&"weapons"]),
			Fit.slot_capacity(hull_id, &"weapons"),
			"%s: and so is slot_capacity" % hull_id
		)


## ---------------------------------------------------------------------------
## The pinned constants
## ---------------------------------------------------------------------------


func test_token_keys_cover_every_letter_used_and_nothing_else() -> void:
	var pinned: Dictionary = {
		"E": &"engines",
		"P": &"power",
		"W": &"weapons",
		"S": &"shields",
		"H": &"armour",
		"C": &"computers",
		"B": &"boosters",
		"U": &"utility",
	}
	assert_eq(Fit.SLOT_TOKEN_KEYS.size(), pinned.size(), "eight letters, one per slot type")
	for letter: String in pinned.keys():
		assert_eq(
			StringName(Fit.SLOT_TOKEN_KEYS.get(letter, &"")),
			StringName(pinned[letter]),
			"%s maps to %s" % [letter, pinned[letter]]
		)
	for hull_id: StringName in HULL_IDS:
		for row: Variant in Fit.grid_rows(hull_id):
			for col: int in String(row).length():
				var token := String(row).substr(col, 1)
				assert_true(
					token == "." or pinned.has(token),
					"%s carries only mapped letters and gaps, saw '%s'" % [hull_id, token]
				)


func test_fit_slot_keys_and_mandatory_keys_are_the_pinned_order() -> void:
	var expected: Array[StringName] = [
		&"engines",
		&"weapons",
		&"shields",
		&"armour",
		&"computers",
		&"boosters",
		&"utility",
		&"power",
	]
	assert_eq(Fit.FIT_SLOT_KEYS.size(), expected.size(), "eight fit slot keys")
	for index: int in expected.size():
		assert_eq(Fit.FIT_SLOT_KEYS[index], expected[index], "FIT_SLOT_KEYS[%d]" % index)
	assert_eq(Fit.MANDATORY_SLOT_KEYS.size(), 2, "two mandatory keys (09 section 4.1)")
	assert_eq(Fit.MANDATORY_SLOT_KEYS[0], &"engines", "engines are mandatory")
	assert_eq(Fit.MANDATORY_SLOT_KEYS[1], &"power", "power is mandatory")


func test_engine_mult_ceiling_and_mount_spread_are_the_pinned_values() -> void:
	assert_true(
		absf(float(Fit.ENGINE_MULT_CEILING) - 1.40) < EPSILON,
		"ENGINE_MULT_CEILING is 09 section 3.7's 1.40"
	)
	assert_eq(Fit.MOUNT_SPREAD, Vector2(0.34, 0.22), "MOUNT_SPREAD is 09 section 8's (0.34, 0.22)")


## ---------------------------------------------------------------------------
## Cells, indices and addressing
## ---------------------------------------------------------------------------


func test_grid_cells_are_row_major_with_gaps_included() -> void:
	for hull_id: StringName in HULL_IDS:
		var size := Fit.grid_size(hull_id)
		var cells := Fit.grid_cells(hull_id)
		var cursor := 0
		var row_index := 0
		for row: Variant in Fit.grid_rows(hull_id):
			var text := String(row)
			assert_eq(text.length(), size.x, "%s row %d is %d columns wide" % [hull_id, row_index, size.x])
			for col: int in text.length():
				var cell: Dictionary = cells[cursor]
				assert_eq(int(cell[&"row"]), row_index, "%s cell %d row" % [hull_id, cursor])
				assert_eq(int(cell[&"col"]), col, "%s cell %d col" % [hull_id, cursor])
				assert_eq(String(cell[&"token"]), text.substr(col, 1), "%s cell %d token" % [hull_id, cursor])
				assert_eq(
					bool(cell[&"gap"]),
					text.substr(col, 1) == ".",
					"%s cell %d gap flag" % [hull_id, cursor]
				)
				if bool(cell[&"gap"]):
					assert_eq(StringName(cell[&"type"]), &"", "%s cell %d has no type" % [hull_id, cursor])
					assert_eq(int(cell[&"index"]), -1, "%s cell %d has no index" % [hull_id, cursor])
				cursor += 1
			row_index += 1
		assert_eq(cursor, size.x * size.y, "%s: every matrix position is a cell" % hull_id)


func test_grid_cells_indices_are_contiguous_per_type() -> void:
	for hull_id: StringName in HULL_IDS:
		var expected: Dictionary = {}
		for key: StringName in Fit.FIT_SLOT_KEYS:
			expected[key] = 0
		for cell: Dictionary in Fit.grid_cells(hull_id):
			if bool(cell[&"gap"]):
				continue
			var key: StringName = cell[&"type"]
			assert_eq(
				int(cell[&"index"]),
				int(expected.get(key, 0)),
				"%s: %s cells are numbered row-major from 0" % [hull_id, key]
			)
			expected[key] = int(expected.get(key, 0)) + 1
		for key: StringName in Fit.FIT_SLOT_KEYS:
			assert_eq(
				int(expected[key]),
				Fit.slot_capacity(hull_id, key),
				"%s: %s indices reach the capacity" % [hull_id, key]
			)


func test_fitted_ids_keep_the_resolution_order() -> void:
	var fit: Dictionary = {
		&"engines": [&"e_std", &"e_ion"],
		&"power": &"p_std",
		&"weapons": [&"w_laser", &"w_mining"],
		&"shields": [&"s_light"],
		&"armour": [&"h_plate_light"],
		&"computers": [&"c_target"],
		&"boosters": [&"b_afterburner"],
		&"utility": [&"u_cargo"],
	}
	var expected: Array[StringName] = [
		&"w_laser",
		&"w_mining",
		&"s_light",
		&"h_plate_light",
		&"c_target",
		&"b_afterburner",
		&"u_cargo",
		&"e_std",
		&"e_ion",
		&"p_std",
	]
	var ids := Fit.fitted_ids(fit)
	assert_eq(ids.size(), expected.size(), "every fitted id is listed once")
	for index: int in mini(ids.size(), expected.size()):
		assert_eq(ids[index], expected[index], "fitted_ids[%d] keeps the pinned order" % index)


## ---------------------------------------------------------------------------
## Unknown and NPC hulls
## ---------------------------------------------------------------------------


func test_unknown_and_npc_hulls_return_the_empty_shapes() -> void:
	var ids: Array[StringName] = [&"ship_does_not_exist"]
	ids.append_array(NPC_HULLS)
	for hull_id: StringName in ids:
		assert_eq(Fit.grid_rows(hull_id), [], "%s has no rows" % hull_id)
		assert_eq(Fit.grid_cells(hull_id), [], "%s has no cells" % hull_id)
		assert_eq(Fit.grid_size(hull_id), Vector2i.ZERO, "%s has no size" % hull_id)
		assert_eq(Fit.slot_capacity(hull_id, &"weapons"), 0, "%s has no weapons" % hull_id)
		assert_eq(Fit.standard_fit(hull_id), {}, "%s has no standard fit" % hull_id)
		assert_eq(
			Fit.mount_offset(hull_id, &"weapons", 0),
			Vector2.ZERO,
			"%s has no mount anchors" % hull_id
		)
		var counts := Fit.grid_counts(hull_id)
		assert_eq(counts.size(), Fit.FIT_SLOT_KEYS.size(), "%s still answers all eight keys" % hull_id)
		for key: StringName in Fit.FIT_SLOT_KEYS:
			assert_eq(int(counts[key]), 0, "%s: %s is 0" % [hull_id, key])
		var legal := Fit.fit_legal(hull_id, Fit.STANDARD_FITS[&"ship_vanguard"])
		assert_false(bool(legal[&"legal"]), "%s fits nothing" % hull_id)
		assert_true(legal.has(&"overflow"), "%s answers the full legality shape" % hull_id)


## ---------------------------------------------------------------------------
## Standard fits and legality
## ---------------------------------------------------------------------------


func test_standard_fits_are_the_nine_documented_rows() -> void:
	assert_eq(Fit.STANDARD_FITS.size(), HULL_IDS.size(), "one standard fit per player hull")
	for index: int in HULL_IDS.size():
		var hull_id: StringName = HULL_IDS[index]
		assert_eq(Fit.standard_fit(hull_id), STANDARD_FITS[index], "%s is 09 section 9's row" % hull_id)
		assert_ne(Fit.standard_fit(hull_id), {}, "%s has a fit" % hull_id)


func test_every_standard_fit_is_legal_on_its_own_hull() -> void:
	for hull_id: StringName in HULL_IDS:
		var legal := Fit.fit_legal(hull_id, Fit.standard_fit(hull_id))
		assert_true(bool(legal[&"legal"]), "%s launches on its standard fit" % hull_id)
		assert_eq(legal[&"overflow"], {}, "%s has nothing overflowing" % hull_id)
		assert_eq(legal[&"missing"], [], "%s is missing nothing" % hull_id)
		assert_eq(legal[&"duplicates"], [], "%s repeats nothing" % hull_id)
		assert_true(bool(legal[&"power"][&"legal"]), "%s's standard fit fits its power budget" % hull_id)


func test_standard_fit_alias_stays_the_vanguard_row() -> void:
	assert_true(Fit.STANDARD_FIT.has(&"engines"), "the alias carries the array-shaped engines key")
	assert_false(Fit.STANDARD_FIT.has(&"engine"), "the legacy singular key is gone from the row")
	assert_eq(Fit.STANDARD_FIT, Fit.STANDARD_FITS[&"ship_vanguard"], "STANDARD_FIT is the Vanguard row")
	assert_eq(
		Fit.standard_fit(&"ship_vanguard"),
		Fit.STANDARD_FIT,
		"and standard_fit returns the same row"
	)


func test_missing_mandatory_cells_are_reported() -> void:
	var empty: Dictionary = {}
	var lancer := Fit.fit_legal(&"ship_fighter", empty)
	assert_false(bool(lancer[&"legal"]), "an empty fit cannot launch (09 section 4.1)")
	assert_true(lancer[&"missing"].has(&"engines"), "the empty engine cell is missing")
	assert_true(lancer[&"missing"].has(&"power"), "the empty power cell is missing")

	var two: Dictionary = {&"engines": [&"e_std"], &"power": &"p_std"}
	var courier := Fit.fit_legal(&"ship_trader", two)
	assert_false(bool(courier[&"legal"]), "a two-engine hull on one engine cannot launch")
	assert_eq(courier[&"missing"], [&"engines"], "the second engine cell is the missing one")
	assert_eq(courier[&"overflow"], {}, "and nothing overflows")
	assert_true(bool(courier[&"power"][&"legal"]), "the power arithmetic is untouched by the gap")

	var three: Dictionary = {&"engines": [&"e_std", &"e_std", &"e_std"], &"power": &"p_std"}
	assert_eq(
		Fit.fit_legal(&"ship_freighter", three)[&"missing"],
		[],
		"a three-engine hull's mandatory set is complete"
	)


func test_duplicate_engines_are_refused_but_the_reference_engine_may_repeat() -> void:
	var reference_fit: Dictionary = {&"engines": [&"e_std", &"e_std"], &"power": &"p_std"}
	var reference_legal := Fit.fit_legal(&"ship_trader", reference_fit)
	assert_true(bool(reference_legal[&"legal"]), "e_std + e_std is legal (09 section 3.7)")
	assert_eq(reference_legal[&"duplicates"], [], "the reference engine is the named exception")

	var duplicate: Dictionary = {&"engines": [&"e_vector", &"e_vector"], &"power": &"p_std"}
	var duplicate_legal := Fit.fit_legal(&"ship_trader", duplicate)
	assert_false(bool(duplicate_legal[&"legal"]), "e_vector + e_vector is refused")
	assert_eq(duplicate_legal[&"duplicates"], [&"engines"], "the refusal names the engines key")

	var mixed: Dictionary = {&"engines": [&"e_std", &"e_vector"], &"power": &"p_std"}
	var mixed_legal := Fit.fit_legal(&"ship_trader", mixed)
	assert_true(bool(mixed_legal[&"legal"]), "one of each engine is legal")
	assert_eq(mixed_legal[&"duplicates"], [], "and repeats nothing")

	var computers: Dictionary = {
		&"engines": [&"e_std"],
		&"power": &"p_std",
		&"computers": [&"c_target", &"c_target"],
	}
	var computers_legal := Fit.fit_legal(&"ship_patrol", computers)
	assert_false(bool(computers_legal[&"legal"]), "a repeated computer is refused (09 section 3.4)")
	assert_eq(computers_legal[&"duplicates"], [&"computers"], "the refusal names the computers key")

	var repeating: Dictionary = {
		&"engines": [&"e_std", &"e_std"],
		&"power": &"p_std",
		&"armour": [&"h_plate_heavy", &"h_plate_heavy"],
		&"shields": [&"s_light", &"s_light"],
	}
	var repeating_legal := Fit.fit_legal(&"ship_patrol", repeating)
	assert_true(bool(repeating_legal[&"legal"]), "armour and shields repeat by design (09 section 4.4)")
	assert_eq(repeating_legal[&"duplicates"], [], "a repeated plate is not a duplicate")


func test_power_overflow_is_reported_per_slot() -> void:
	var fit: Dictionary = {
		&"engines": [&"e_std", &"e_std"],
		&"power": &"p_std",
		&"weapons": [&"w_laser", &"w_laser", &"w_laser"],
	}
	var legal := Fit.fit_legal(&"ship_trader", fit)
	assert_false(bool(legal[&"legal"]), "a third weapon cannot fit a one-weapon hull")
	assert_eq(legal[&"overflow"], {&"weapons": 2}, "two weapons overflow the Trader's single W cell")

	var power: Dictionary = legal[&"power"]
	assert_eq(int(power[&"out"]), 8, "the Trader's power out is 08 section 2's 8 plus p_std's 0")
	assert_eq(int(power[&"draw"]), 3, "three lasers draw 3")
	assert_eq(int(power[&"spare"]), 5, "so five are spare")
	assert_true(bool(power[&"legal"]), "and the arithmetic still passes")
	assert_eq(
		Fit.power_budget(&"ship_trader", fit),
		power,
		"fit_legal's power block is power_budget's own arithmetic"
	)


## ---------------------------------------------------------------------------
## The engine set: summed deltas, ceiling, legacy key
## ---------------------------------------------------------------------------


func test_a_single_engine_resolves_to_the_pre_amendment_figure() -> void:
	for index: int in HULL_IDS.size():
		var hull_id: StringName = HULL_IDS[index]
		var base_speed := float(Fit.HANDLING[hull_id][&"max_speed"])
		var base_turn := float(Fit.HANDLING[hull_id][&"turn_rate"])
		var one: Dictionary = {&"engines": [&"e_std"], &"power": &"p_std"}
		var stats: ShipStats = Fit.resolve(hull_id, one)
		assert_true(stats != null, "%s resolves one engine" % hull_id)
		if stats == null:
			continue
		assert_true(
			absf(stats.max_speed - base_speed) < EPSILON,
			"%s: one e_std is exactly the base speed %.4f (measured %.4f)"
			% [hull_id, base_speed, stats.max_speed]
		)
		assert_true(
			absf(stats.turn_rate - base_turn) < EPSILON,
			"%s: one e_std is exactly the base turn rate" % hull_id
		)

	var vector_fit: Dictionary = {&"engines": [&"e_vector"], &"power": &"p_std"}
	var vector_stats: ShipStats = Fit.resolve(&"ship_vanguard", vector_fit)
	assert_true(
		absf(vector_stats.max_speed - 428.0 * 1.25) < EPSILON,
		"e_vector alone is 1.25x the base (09 section 3.7 consequence 2), measured %.4f"
		% vector_stats.max_speed
	)
	assert_true(
		absf(vector_stats.turn_rate - 1.5 * 1.20) < EPSILON,
		"e_vector alone carries its own 1.20 turn multiplier"
	)

	var ion_stats: ShipStats = Fit.resolve(
		&"ship_vanguard", {&"engines": [&"e_ion"], &"power": &"p_std"}
	)
	assert_true(
		absf(ion_stats.max_speed - 428.0 * 1.15) < EPSILON,
		"e_ion alone is 1.15x the base, measured %.4f" % ion_stats.max_speed
	)


func test_the_engine_set_sums_its_deltas_and_clamps_at_the_ceiling() -> void:
	var base := 428.0
	var three: Dictionary = {
		&"engines": [&"e_std", &"e_ion", &"e_vector"],
		&"power": &"p_std",
	}
	var three_stats: ShipStats = Fit.resolve(&"ship_vanguard", three)
	assert_true(
		absf(three_stats.max_speed - base * float(Fit.ENGINE_MULT_CEILING)) < EPSILON,
		"e_std + e_ion + e_vector resolves to 1.40 exactly, measured %.6f"
		% (three_stats.max_speed / base)
	)
	assert_eq(
		Fit.fit_legal(&"ship_freighter", three)[&"legal"],
		true,
		"and that set is legal on a three-engine hull"
	)

	var sum: Dictionary = {&"engines": [&"e_std", &"e_ion"], &"power": &"p_std"}
	var sum_stats: ShipStats = Fit.resolve(&"ship_vanguard", sum)
	assert_true(
		absf(sum_stats.max_speed - base * 1.15) < EPSILON,
		"e_std + e_ion sums to 1.15, not 1.15 x 1.0 (measured %.6f)"
		% (sum_stats.max_speed / base)
	)

	## 09 section 3.7 says the ceiling applies to speed only. Three vectors is an
	## illegal set, but resolve still shows the arithmetic: the speed clamps at 1.40
	## while the turn sum (1.60) rides past it.
	var vectors: Dictionary = {
		&"engines": [&"e_vector", &"e_vector", &"e_vector"],
		&"power": &"p_std",
	}
	var vector_stats: ShipStats = Fit.resolve(&"ship_freighter", vectors)
	assert_true(
		absf(vector_stats.max_speed - float(Fit.HANDLING[&"ship_freighter"][&"max_speed"]) * 1.40)
		< EPSILON,
		"a 1.75 sum clamps to 1.40"
	)
	assert_true(
		absf(vector_stats.turn_rate - float(Fit.HANDLING[&"ship_freighter"][&"turn_rate"]) * 1.60)
		< EPSILON,
		"the turn multiplier carries no ceiling and sums to 1.60"
	)
	assert_false(
		bool(Fit.fit_legal(&"ship_freighter", vectors)[&"legal"]),
		"while the fit validator refuses the repeated id"
	)


func test_legacy_singular_engine_key_resolves_identically() -> void:
	var legacy: Dictionary = {
		&"engine": &"e_std",
		&"power": &"p_std",
		&"weapons": [&"w_laser"],
		&"shields": [&"s_light"],
		&"armour": [&"h_plate_light"],
	}
	var modern: Dictionary = {
		&"engines": [&"e_std"],
		&"power": &"p_std",
		&"weapons": [&"w_laser"],
		&"shields": [&"s_light"],
		&"armour": [&"h_plate_light"],
	}
	assert_eq(Fit.fitted_ids(legacy), Fit.fitted_ids(modern), "the two spellings list the same ids")
	var legacy_stats: ShipStats = Fit.resolve(&"ship_vanguard", legacy)
	var modern_stats: ShipStats = Fit.resolve(&"ship_vanguard", modern)
	assert_true(legacy_stats != null and modern_stats != null, "both shapes resolve")
	assert_true(
		absf(legacy_stats.max_speed - modern_stats.max_speed) < EPSILON
		and absf(legacy_stats.turn_rate - modern_stats.turn_rate) < EPSILON
		and absf(legacy_stats.hull_max - modern_stats.hull_max) < EPSILON
		and absf(legacy_stats.shield_max - modern_stats.shield_max) < EPSILON
		and absf(legacy_stats.shield_regen - modern_stats.shield_regen) < EPSILON
		and absf(legacy_stats.coast_time - modern_stats.coast_time) < EPSILON,
		"the legacy singular engine key resolves to the same snapshot"
	)
	assert_eq(Fit.power_budget(&"ship_vanguard", legacy), Fit.power_budget(&"ship_vanguard", modern))

	## The legacy key also accepts an Array (rule 2 of CONTRACTS section 11).
	var legacy_array: Dictionary = legacy.duplicate(true)
	legacy_array.erase(&"engine")
	legacy_array[&"engine"] = [&"e_std"]
	assert_eq(
		Fit.fitted_ids(legacy_array),
		Fit.fitted_ids(modern),
		"a legacy `engine` array reads as the one-cell set"
	)
	assert_eq(
		Fit.power_budget(&"ship_vanguard", legacy_array),
		Fit.power_budget(&"ship_vanguard", modern),
		"and its budget matches"
	)

	## STANDARD_FIT itself resolves unchanged: the alias row still resolves to the
	## figures the pre-amendment literal gave.
	assert_eq(
		Fit.power_budget(&"ship_vanguard", legacy),
		Fit.power_budget(&"ship_vanguard", Fit.STANDARD_FIT),
		"STANDARD_FIT's budget is the legacy-shaped fit's own"
	)


func test_engines_key_wins_over_the_legacy_engine_key() -> void:
	var both: Dictionary = {
		&"engines": [&"e_ion"],
		&"engine": &"e_vector",
		&"power": &"p_std",
	}
	assert_eq(Fit.fitted_ids(both), [&"e_ion", &"p_std"], "engines wins when both keys are present")
	var stats: ShipStats = Fit.resolve(&"ship_vanguard", both)
	assert_true(
		absf(stats.max_speed - 428.0 * 1.15) < EPSILON,
		"and the resolved speed is the engines set's, measured %.4f" % stats.max_speed
	)

	var empty_set: Dictionary = {&"engines": [], &"engine": &"e_vector", &"power": &"p_std"}
	assert_eq(
		Fit.fitted_ids(empty_set),
		[&"p_std"],
		"an empty engines array still wins: the key's presence decides, not its length"
	)


## ---------------------------------------------------------------------------
## Mount geometry (09 section 8)
## ---------------------------------------------------------------------------


func test_mount_offset_is_the_documented_formula() -> void:
	for hull_id: StringName in HULL_IDS:
		var size := Fit.grid_size(hull_id)
		var spread: Vector2 = Fit.MOUNT_SPREAD
		for cell: Dictionary in Fit.grid_cells(hull_id):
			if bool(cell[&"gap"]):
				continue
			var key: StringName = cell[&"type"]
			var index := int(cell[&"index"])
			var expected := Vector2(
				(float(int(cell[&"col"])) + 0.5) / float(size.x) - 0.5,
				(float(int(cell[&"row"])) + 0.5) / float(size.y) - 0.5
			) * spread
			var actual := Fit.mount_offset(hull_id, key, index)
			assert_true(
				absf(actual.x - expected.x) < EPSILON and absf(actual.y - expected.y) < EPSILON,
				(
					"%s %s[%d] at (%d, %d) is the 09 section 8 formula, expected %s, got %s"
					% [hull_id, key, index, int(cell[&"col"]), int(cell[&"row"]), expected, actual]
				)
			)


func test_mount_offset_is_zero_where_there_is_no_cell() -> void:
	for hull_id: StringName in HULL_IDS:
		var counts := Fit.grid_counts(hull_id)
		for key: StringName in Fit.FIT_SLOT_KEYS:
			var capacity := int(counts[key])
			assert_eq(
				Fit.mount_offset(hull_id, key, capacity),
				Vector2.ZERO,
				"%s: %s[%d] is past the last cell" % [hull_id, key, capacity]
			)
		assert_eq(
			Fit.mount_offset(hull_id, &"nothing", 0),
			Vector2.ZERO,
			"%s has no such slot type" % hull_id
		)
		assert_eq(Fit.mount_offset(hull_id, &"engines", -1), Vector2.ZERO, "a negative index has no cell")
	## The Trader's one W cell is at row 0, col 1 of a 4 x 4 grid: the anchor is a
	## worked example of the formula, so a sign flip or a swapped axis shows up here.
	var expected := Vector2((1.0 + 0.5) / 4.0 - 0.5, (0.0 + 0.5) / 4.0 - 0.5) * Fit.MOUNT_SPREAD
	var actual := Fit.mount_offset(&"ship_trader", &"weapons", 0)
	assert_true(
		absf(actual.x - expected.x) < EPSILON and absf(actual.y - expected.y) < EPSILON,
		"the Trader's W cell anchors at %s, expected %s" % [actual, expected]
	)


## ---------------------------------------------------------------------------
## The module catalogue
## ---------------------------------------------------------------------------


func test_module_catalog_carries_the_pinned_rows() -> void:
	assert_eq(Catalog.MODULES.size(), MODULE_ROWS.size(), "32 rows (09 section 3)")
	for row: Dictionary in MODULE_ROWS:
		var id: StringName = row["id"]
		var published := Catalog.module(id)
		assert_false(published.is_empty(), "%s is in the catalogue" % id)
		assert_eq(String(published.get(&"name", "")), row["name"], "%s name" % id)
		assert_eq(StringName(published.get(&"slot", &"")), row["slot"], "%s slot" % id)
		assert_eq(int(published.get(&"draw", -1)), int(row["draw"]), "%s draw" % id)
		assert_eq(int(published.get(&"tier", -1)), int(row["tier"]), "%s tier" % id)
		assert_eq(int(published.get(&"cost", -1)), int(row["cost"]), "%s cost" % id)
		assert_eq(
			published.size(),
			7,
			"%s carries exactly name/slot/draw/tier/cost/icon/effects" % id
		)
		assert_true(published.get(&"effects") is Dictionary, "%s effects is a dictionary" % id)
		var expected_effects: Dictionary = MODULE_EFFECTS.get(id, {})
		assert_eq(published.get(&"effects"), expected_effects, "%s effects are 09 section 3's" % id)


func test_module_catalog_is_the_one_literal_ship_fit_aliases() -> void:
	assert_eq(
		Fit.MODULES.size(),
		Catalog.MODULES.size(),
		"ShipFit.MODULES and ModuleCatalog.MODULES are the same size"
	)
	for row: Dictionary in MODULE_ROWS:
		var id: StringName = row["id"]
		assert_true(Fit.MODULES.has(id), "ShipFit.MODULES still indexes %s" % id)
		assert_eq(Fit.MODULES[id][&"effects"], Catalog.module(id)[&"effects"], "%s effects agree" % id)
		assert_eq(Fit.MODULES[id][&"slot"], Catalog.module(id)[&"slot"], "%s slot agrees" % id)
	## The alias sees the keys only the catalogue carries, which is what proves the
	## two names read one dictionary rather than two literals that happen to match.
	assert_true(
		Fit.MODULES[&"w_laser"].has(&"name") and Fit.MODULES[&"w_laser"].has(&"icon"),
		"ShipFit.MODULES is the catalogue's own row (it carries name and icon)"
	)
	assert_eq(
		Catalog.module(&"w_laser")[&"cost"],
		900,
		"and the row's 09 section 3.1 cost is readable through it"
	)
	assert_eq(Catalog.module(&"not_a_module"), {}, "an unknown id has no row")
	assert_eq(Catalog.slot_of(&"not_a_module"), &"", "an unknown id has no slot")
	assert_eq(Catalog.slot_of(&"e_std"), &"engine", "slot_of reads the row's own slot")
	assert_eq(Catalog.slot_of(&"w_laser"), &"weapons", "a weapon's slot is `weapons`")
	assert_eq(Catalog.icon_path(&"not_a_module"), "", "an unknown id has no icon path")


func test_module_icon_rule_and_files_on_disk() -> void:
	for row: Dictionary in MODULE_ROWS:
		var id: StringName = row["id"]
		var expected := "res://assets/icons/module/icon_module_%s.svg" % id
		if WEAPON_ICON_FAMILIES.has(id):
			expected = "res://assets/icons/weapon/icon_weapon_%s.svg" % WEAPON_ICON_FAMILIES[id]
		assert_eq(Catalog.icon_path(id), expected, "%s follows the icon rule" % id)
		assert_eq(
			String(Catalog.module(id).get(&"icon", "")),
			expected,
			"%s's own icon field is the rule's path" % id
		)
		assert_true(FileAccess.file_exists(expected), "%s exists on disk" % expected)


## ---------------------------------------------------------------------------
## Document parsers: 08 section 3's block and its counts table
## ---------------------------------------------------------------------------


func _doc_lines() -> PackedStringArray:
	assert_true(
		FileAccess.file_exists(DOC_PATH),
		"08_ship_classes.md is reachable at %s" % DOC_PATH
	)
	return FileAccess.get_file_as_string(DOC_PATH).split("\n")


func _heading_index(lines: PackedStringArray, prefix: String) -> int:
	for index: int in lines.size():
		if String(lines[index]).begins_with(prefix):
			return index
	return -1


## 08 section 3.2's fenced block, read off the render: class name ->
## {cols, rows, grid}. One header line per hull (`Fighter  (4 x 3)  E1 P1 ...`)
## followed by that hull's grid rows; a row's cells are its characters, so the
## cosmetic spaces are removed here the same way `SLOT_GRIDS` removes them.
func _document_grids() -> Dictionary:
	var lines := _doc_lines()
	var start := _heading_index(lines, "### 3.2 ")
	assert_true(start >= 0, "08 section 3.2's heading is in the document")
	if start < 0:
		return {}
	var cursor := start
	while cursor < lines.size() and not String(lines[cursor]).strip_edges().begins_with("```"):
		cursor += 1
	cursor += 1
	var out: Dictionary = {}
	var current := ""
	while cursor < lines.size():
		var line := String(lines[cursor]).strip_edges()
		if line.begins_with("```"):
			break
		if not line.is_empty():
			if line.find("(") > 0 and line.find(" x ") > 0:
				current = line.substr(0, line.find("(")).strip_edges()
				var dims := line.substr(
					line.find("(") + 1, line.find(")") - line.find("(") - 1
				).split("x")
				out[current] = {
					&"cols": int(dims[0].strip_edges()),
					&"rows": int(dims[1].strip_edges()),
					&"grid": [],
				}
			elif not current.is_empty():
				var rows: Array = out[current][&"grid"]
				rows.append(line.replace(" ", ""))
				out[current][&"grid"] = rows
		cursor += 1
	return out


## 08 section 3's counts table, read off the render: class name ->
## {cells: {letter: int}, total: int}. The `△` marks on the amendment's moved rows
## are stripped, and the column letters are read from the table's own header.
func _document_counts() -> Dictionary:
	var lines := _doc_lines()
	var start := _heading_index(lines, "## 3. ")
	assert_true(start >= 0, "08 section 3's heading is in the document")
	if start < 0:
		return {}
	var header: PackedStringArray = PackedStringArray()
	var body: Array[PackedStringArray] = []
	for index: int in range(start, lines.size()):
		var line := String(lines[index]).strip_edges()
		if index > start and line.begins_with("#"):
			break
		if not line.begins_with("|"):
			continue
		var cells := line.split("|", false)
		if cells.size() != 12:
			continue
		if String(cells[0]).strip_edges() == "Class":
			header = cells
			continue
		if String(cells[0]).replace("-", "").strip_edges().is_empty():
			continue
		body.append(cells)
	assert_eq(header.size(), 12, "08 section 3's table has a 12-column header row")
	var out: Dictionary = {}
	for cells: PackedStringArray in body:
		var ship_class := String(cells[0]).strip_edges()
		var row: Dictionary = {}
		for column: int in range(3, 11):
			var letter := String(header[column]).strip_edges()
			assert_true(
				Fit.SLOT_TOKEN_KEYS.has(letter),
				"the table's column %d is a mapped letter, saw '%s'" % [column, letter]
			)
			row[letter] = int(String(cells[column]).trim_suffix("△").strip_edges())
		out[ship_class] = {
			&"cells": row,
			&"total": int(String(cells[11]).trim_suffix("△").strip_edges()),
		}
	return out
