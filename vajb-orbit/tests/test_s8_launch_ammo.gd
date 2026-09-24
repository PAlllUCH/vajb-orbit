@tool
extends McpTestSuite
## Suite s8_launch_ammo: the S8 QA wave's accounting family (CONTRACTS section 21, H1 / H2 / M4
## and the range copy). Every reading is taken off the shipped scenes and the borrowed
## `PlayerProfile` autoload, so what is measured is the tree's own behaviour.
##
##  - **H1** (`weapons.gd:_launch_ammo_slot`, `launch_panel.gd:_ammo_total`/`_weapon_count`) --
##    one launch on the QA's fit shape, and the strip the player reads at the station, the
##    flight `PlayerState.weapons`/`ammo`, the launch's `_ammo_seed`, the HUD's pushed cells
##    and the store's `ammo_*` packs are five readings of one seed. A **stocked family fires
##    its own slot**: the cannon-only fit the shipped const order read dry (`ammo_slot(cannon)`
##    = 1 against a one-slot fit) now spawns projectiles, and a dry cannon never spends the
##    railgun's pack.
##  - **H2** (`game.gd:_hull_slot_cells`) -- the Ship Status pane and the FITTING pane agree
##    cell-for-cell on three fits including a hole-y one, and the rack ordinal a status W row
##    prints is the cell's own **barrel position** (`W1 · B1 · Mining Laser` was the defect).
##  - **M4** (`repairs_panel.gd:_pool_maxima`) -- both panes print `ShipFit.resolve`'s
##    hull_max/shield_max, so a plated hull reads `1250 / 1250` and never the station hull
##    row's `1000`, and no pane prints a current above its max.
##  - the target panel's distance line carries the engine's own `u` unit.
##
## Profile hygiene (L17, T-93): the shipped autoload is borrowed, `save_path` is repointed at
## a scratch file before the first mutation, every field this suite writes is handed back in
## `suite_teardown` and the store is flushed while the scratch path is still in place, so the
## owner's `user://profile.cfg` is never written.

const GameScene := preload("res://game/game.tscn")
const LaunchScene := preload("res://ui/station/launch_panel.tscn")
const LaunchScript := preload("res://ui/station/launch_panel.gd")
const RepairsScene := preload("res://ui/station/repairs_panel.tscn")
const FittingScene := preload("res://ui/station/fitting_panel.tscn")
const HudScene := preload("res://ui/hud/hud.tscn")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const FitData := preload("res://game/ship_fit.gd")
const Catalog := preload("res://game/station_catalog.gd")
const ModuleData := preload("res://game/module_catalog.gd")
const WeaponsScript := preload("res://game/weapons.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const ProfileData := preload("res://autoload/player_profile.gd")

const SCRATCH_PROFILE := "user://test_s8_launch_ammo.cfg"
const PROFILE_SERVICE: StringName = &"PlayerProfile"

const HULL: StringName = &"ship_vanguard"
const ENGINE: StringName = &"e_std"
const REACTOR: StringName = &"p_std"
const LIGHT_SHIELD: StringName = &"s_light"
const LIGHT_PLATE: StringName = &"h_plate_light"
const CANNON: StringName = &"w_cannon"
const RAILGUN: StringName = &"w_railgun"
const MINING: StringName = &"w_mining"
const LASER: StringName = &"w_laser"
const WEAPON_SLOT: StringName = &"weapons"

const START_CREDITS := 10000
## The QA's own fit shape (Standard Drive + Cannon MkI + Railgun + Mining Laser, with the
## Light Shield and Light Plate their `1250 / 800` rations need), and the vitals their
## playtest filed: full at the resolved maxima.
const QA_FIT: Dictionary = {
	&"engines": ["e_std"],
	&"power": "p_std",
	&"weapons": ["w_cannon", "w_railgun", "w_mining"],
	&"shields": ["s_light"],
	&"armour": ["h_plate_light"],
}
## The resolved maxima the QA fit answers, quoted from CONTRACTS section 21 so the suite
## measures the panes against the pin rather than against `ShipFit` alone.
const QA_HULL_MAX := 1250
const QA_SHIELD_MAX := 800
## The hole-y shapes H2 is measured on: a family-less module in W1, and the QA species with a
## non-weapon at W3.
const TOOL_FIRST_FIT: Dictionary = {
	&"engines": ["e_std"],
	&"power": "p_std",
	&"weapons": ["w_mining", "w_laser", ""],
	&"shields": ["s_light"],
	&"armour": ["h_plate_light"],
}
const TOOL_MIDDLE_FIT: Dictionary = {
	&"engines": ["e_std"],
	&"power": "p_std",
	&"weapons": ["w_cannon", "w_mining", "w_laser"],
	&"shields": ["s_light"],
	&"armour": ["h_plate_light"],
}
## The Vanguard's bare fit: no shield module and no plate, so `ShipFit.resolve` answers the
## station row's own 1000 / 600 and a heavier filed reading has somewhere to clamp to.
const BARE_FIT: Dictionary = {
	&"engines": ["e_std"],
	&"power": "p_std",
	&"weapons": ["w_laser"],
}

var _profile: Node = null
var _scene: Node2D = null
var _host: Control = null
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_credits := 0
var _previous_cargo: Dictionary = {}
var _previous_ammo: Dictionary = {}
var _previous_fits: Dictionary = {}
var _previous_owned: Array = []
var _previous_modules: Dictionary = {}
var _previous_vitals: Dictionary = {}
var _previous_batteries: Dictionary = {}
var _fired: Array[StringName] = []


func suite_name() -> String:
	return "s8_launch_ammo"


func suite_setup(_ctx: Dictionary) -> void:
	_profile = _fixture_host()
	if _profile == null or not _profile.has_method(&"ammo_of"):
		fail_setup("the PlayerProfile autoload is the store this suite measures")
		return
	_previous_path = String(_profile.get(&"save_path"))
	_previous_ship = StringName(_profile.call(&"active_ship"))
	_previous_credits = int(_profile.call(&"credits"))
	_previous_cargo = (_profile.get(&"_cargo") as Dictionary).duplicate(true)
	_previous_ammo = (_profile.get(&"_ammo") as Dictionary).duplicate(true)
	_previous_fits = _profile.call(&"fits")
	_previous_owned = _profile.call(&"owned_ships")
	_previous_modules = _profile.call(&"modules")
	_previous_vitals = (_profile.get(&"_vitals") as Dictionary).duplicate(true)
	_previous_batteries = (_profile.get(&"_batteries") as Dictionary).duplicate(true)
	_profile.set(&"save_path", SCRATCH_PROFILE)
	_delete_file(SCRATCH_PROFILE)


func suite_teardown() -> void:
	_free_scene()
	_free_host()
	if _profile == null:
		return
	_profile.set(&"_credits", _previous_credits)
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_cargo", _previous_cargo)
	_profile.set(&"_ammo", _previous_ammo)
	_profile.set(&"_fits", _previous_fits)
	_profile.set(&"_owned_ships", _previous_owned)
	_profile.set(&"_modules", _previous_modules)
	_profile.set(&"_vitals", _previous_vitals)
	_profile.set(&"_batteries", _previous_batteries)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	_delete_file(SCRATCH_PROFILE)
	_profile = null


func setup() -> void:
	_free_scene()
	_free_host()


func teardown() -> void:
	_free_scene()
	_free_host()


# --------------------------------------------------------------------------------- H1


## CONTRACTS section 21 (H1): one launch on the QA's own fit shape, and the strip the player
## reads at the station agrees with the flight slots, the launch's seed, the HUD's pushed cells
## and the store's packs. Four families of the six are absent from the fit and are read zero:
## the defect was a strip that summed all six `Catalog.AMMO_PACKS`.
func test_one_launch_agrees_with_the_strip_the_slots_and_the_packs() -> void:
	_install(QA_FIT)
	var panel := _mount(LaunchScene)
	var text := _brief_value(panel, &"ammo")
	var fitted := _fitted_families()
	var total := _store_total(fitted)
	assert_eq(fitted, [&"cannon", &"railgun", &""] as Array[StringName], "the QA fit's families")
	assert_eq(
		text,
		LaunchScript.AMMO_FORMAT % [panel.call(&"_format_int", total), fitted.size()],
		"the strip reads the launched fit's own packs and cells (currently %s)" % text
	)
	assert_ne(
		text,
		LaunchScript.AMMO_FORMAT % [
			panel.call(&"_format_int", _store_total(_all_families())), _all_families().size()
		],
		"not the six-pack sum the QA read as a briefing"
	)

	_launch()
	var state: Variant = _scene.get(&"_state")
	assert_eq(state.weapons, fitted, "the flight cells are the fit's own, family-less slot included")
	assert_eq(state.ammo, [300, 300, 0] as Array[int], "seeded per cell from the store")
	assert_eq(_scene.get(&"_ammo_seed"), state.ammo, "the flight seed records the same three")
	var slot_sum := 0
	for value: int in state.ammo:
		slot_sum += value
	assert_eq(slot_sum, total, "the strip's total is exactly the launch's slots")
	for slot in state.weapons.size():
		var family: StringName = state.weapons[slot]
		if family == &"":
			continue
		assert_eq(
			int(state.ammo[slot]),
			int(_profile.call(&"ammo_of", family)),
			"slot %d reads its own family's pack" % slot
		)
	assert_eq(
		_profile.call(&"ammo_of", &"laser"),
		ProfileData.DEFAULT_AMMO,
		"a family the fit does not carry keeps its store"
	)

	## The HUD's pushed cells are the strip's cell list: one entry per fitted W cell, the
	## module and the `PlayerState.ammo` index the HUD reads its rack from.
	var cells: Array = _scene.call(&"_hull_slot_cells")
	assert_eq(cells.size(), 3, "three W cells on the Vanguard")
	var expected_modules: Array[StringName] = [CANNON, RAILGUN, MINING]
	for index: int in cells.size():
		var cell: Dictionary = cells[index]
		assert_eq(cell[&"module"], expected_modules[index], "cell %d is the fit's own module" % index)
		assert_eq(int(cell[&"position"]), index, "cell %d's ammo slot" % index)
		assert_eq(bool(cell[&"fitted"]), true, "cell %d is fitted" % index)
	## And the HUD's own rack readout reads that slot: the ammo row is
	## `_state.ammo[barrel position]` for the selected rack's first cell (`hud.gd:_set_barrel`),
	## which is the QA's `Cannon MkI 0/300` line.
	var hud: Node = _scene.get(&"_hud")
	hud.call(&"select_battery", 1)
	assert_eq(int(hud.get(&"_ammo")), int(state.ammo[0]), "the HUD row reads the cannon's slot")
	var ammo_label: Label = hud.get(&"_ammo_label")
	var tail := "%d/%d" % [int(state.ammo[0]), int(state.ammo_max[0])]
	assert_true(
		String(ammo_label.text).ends_with(tail),
		"and prints it (%s)" % String(ammo_label.text)
	)
	print("[s8-ammo] H1 strip=`%s` slots=%s seed=%s" % [text, str(state.ammo), str(state.ammo.size())])


## A cannon-only fit whose pack is stocked fires: the slot the shipped const order could not
## address (`ammo_slot("cannon")` = 1 against a one-slot fit, which made the QA's `Cannon MkI
## 0/300` read as a seed defect when it was the gate).
func test_a_stocked_family_fires_its_own_slot() -> void:
	_install(_one_gun_fit(CANNON, ""))
	_launch()
	var state: Variant = _scene.get(&"_state")
	assert_eq(state.weapons, [&"cannon"] as Array[StringName], "one fitted cannon")
	assert_eq(state.ammo, [ProfileData.DEFAULT_AMMO] as Array[int], "seeded from its own pack")
	var fired := _pull(90)
	assert_false(fired.is_empty(), "the stocked cannon fires")
	assert_eq(_unique(fired), [&"cannon"] as Array[StringName], "and it is the cannon barrel")
	var tree := _fixture_host().get_tree()
	var projectiles: int = tree.get_nodes_in_group(ProjectileScript.PROJECTILE_GROUP).size()
	assert_true(projectiles >= 1, "a projectile node reached the sector (%d)" % projectiles)
	assert_eq(
		int(state.ammo[0]),
		ProfileData.DEFAULT_AMMO - fired.size(),
		"each release spends one round of its own pack"
	)
	print(
		"[s8-ammo] H1 cannon-only: shots=%d projectiles=%d ammo=%d"
		% [fired.size(), projectiles, int(state.ammo[0])]
	)


## The dry half: a barrel whose own pack is empty is dry for itself and never spends another
## family's pack (the QA fit's cannon, drained, made the *cannon* fire the railgun's rounds).
func test_a_dry_family_never_spends_another_familys_pack() -> void:
	_install(QA_FIT)
	var packs: Dictionary = _profile.get(&"_ammo")
	packs[&"cannon"] = 0
	_profile.set(&"_ammo", packs)
	_launch()
	var state: Variant = _scene.get(&"_state")
	assert_eq(state.ammo, [0, 300, 0] as Array[int], "the cannon's pack is dry, the railgun's is not")
	var guns: Node2D = _scene.get(&"_guns")
	assert_eq(String(guns.call(&"dry_reason")), "ammo", "the selected barrel reads why it is dry")
	var fired := _pull(90)
	assert_false(fired.has(&"cannon"), "the dry cannon never fires")
	assert_eq(
		_unique(fired),
		[&"railgun"] as Array[StringName],
		"the railgun barrel is the one that does"
	)
	assert_eq(int(state.ammo[0]), 0, "the dry cannon spends nothing")
	assert_eq(
		int(state.ammo[1]),
		ProfileData.DEFAULT_AMMO - fired.size(),
		"and the railgun pays its own pack, one round a release"
	)
	print("[s8-ammo] H1 mixed: shots=%d ammo=%s" % [fired.size(), str(state.ammo)])


## The played-account shape: a fit stored as **instance** ids (the QA's own file) reaches the
## strip and the flight slots through the same base-id bridge the launch uses.
func test_an_instance_fit_reads_the_same_strip_and_slots() -> void:
	_install(QA_FIT)
	_profile.set(&"_modules", {
		"mod_0007": {"base_id": "w_cannon", "count": 1},
		"mod_0008": {"base_id": "w_railgun", "count": 1},
		"mod_0009": {"base_id": "w_mining", "count": 1},
	})
	_profile.call(&"set_fit", HULL, {
		&"engines": ["e_std"],
		&"power": "p_std",
		&"weapons": ["mod_0007", "mod_0008", "mod_0009"],
	})
	var panel := _mount(LaunchScene)
	assert_eq(
		_store_total(_fitted_families()),
		_store_total([&"cannon", &"railgun", &""] as Array[StringName]),
		"the instance fit resolves to the same families"
	)
	assert_eq(
		_brief_value(panel, &"ammo"),
		LaunchScript.AMMO_FORMAT % [
			panel.call(&"_format_int", ProfileData.DEFAULT_AMMO * 2), 3
		],
		"the strip reads the resolved fit's two stocked packs across three cells"
	)
	_launch()
	assert_eq(
		_scene.get(&"_state").weapons,
		[&"cannon", &"railgun", &""] as Array[StringName],
		"and the flight slots carry the base families"
	)
	assert_eq(_scene.get(&"_state").ammo, [300, 300, 0] as Array[int], "seeded per cell")


# --------------------------------------------------------------------------------- H2


## CONTRACTS section 21 (H2): one cell, one family, one display. The Ship Status pane's rows
## and the FITTING pane's own cell reading agree cell-for-cell on three fits - the QA's, and
## two hole-y ones - and the W rows carry the fit's families once each, never a battery's first
## member repeated and never an armour module.
func test_the_status_pane_and_fitting_agree_cell_for_cell() -> void:
	for fit: Dictionary in [QA_FIT, TOOL_FIRST_FIT, TOOL_MIDDLE_FIT]:
		var case_name := str(fit[&"weapons"])
		_install(fit)
		_launch()
		var panel := _mount(FittingScene)
		var rows := _status_rows()
		var fit_weapons := _fit_weapon_cells()
		var seen: Array[String] = []
		for row: Dictionary in rows:
			var base := StringName(str(row[&"base"]))
			var text := String(row[&"text"])
			if StringName(str(row[&"token"])) != &"W":
				continue
			seen.append(text)
			assert_eq(
				StringName(str(row[&"base"])),
				fit_weapons[int(row[&"index"])],
				"%s: W%d is the fit's own cell" % [case_name, int(row[&"index"]) + 1]
			)
			assert_eq(
				text,
				_status_row_text(row),
				"%s: W%d's row is the pane's own format" % [case_name, int(row[&"index"]) + 1]
			)
			assert_eq(
				ModuleData.fit_slot_of(base),
				WEAPON_SLOT,
				"%s: W%d carries a weapon, never an armour row (%s)" % [case_name, int(row[&"index"]) + 1, text]
			)
		var fitted := 0
		for module: StringName in fit_weapons:
			if module != &"":
				fitted += 1
		assert_eq(seen.size(), fitted, "%s: one W row per fitted cell" % case_name)
		for index: int in fit_weapons.size():
			var module: StringName = fit_weapons[index]
			var has_cell := bool(panel.call(&"select_cell", WEAPON_SLOT, index))
			assert_true(has_cell, "%s: FITTING has W%d" % [case_name, index + 1])
			assert_eq(
				StringName(str(panel.call(&"selected_cell").get(&"index", -1))),
				StringName(str(index)),
				"%s: FITTING selects W%d" % [case_name, index + 1]
			)
			var action := StringName(str(panel.call(&"module_action", LASER if module == &"" else module)))
			var expected := "FIT" if module == &"" else "SWAP"
			assert_eq(
				action,
				StringName(expected),
				"%s: FITTING reads W%d as %s" % [case_name, index + 1, expected]
			)
		print("[s8-ammo] H2 %s rows=%s" % [case_name, " | ".join(seen)])


## The rack ordinal is a **barrel position** (CONTRACTS section 21, H2): a family-less module
## claims no rack and never wears another cell's ordinal, and the ordinal a status row prints is
## the one the fired component's own `racks()` holds. `W1 · B1 · Mining Laser` beside a
## rack-less `W2 · B0 · Laser MkII` was the defect's face.
func test_the_rack_ordinal_lives_in_the_barrel_position_space() -> void:
	var cases: Array[Dictionary] = [
		{&"fit": QA_FIT, &"batteries": {String(HULL): [[0], [1], [2]]}, &"expected": [1, 2, 0]},
		{&"fit": TOOL_FIRST_FIT, &"batteries": {}, &"expected": [0, 1]},
		{&"fit": QA_FIT, &"batteries": {}, &"expected": [1, 1, 0]},
	]
	for case: Dictionary in cases:
		_install(case[&"fit"] as Dictionary)
		_profile.set(&"_batteries", case[&"batteries"] as Dictionary)
		_launch()
		var guns: Node2D = _scene.get(&"_guns")
		var racks: Array = guns.call(&"racks")
		var cells: Array = _scene.call(&"_hull_slot_cells")
		var ordinals: Array[int] = []
		for cell: Dictionary in cells:
			if not bool(cell[&"fitted"]):
				continue
			var ordinal := int(cell[&"battery"])
			ordinals.append(ordinal)
			var barrel := _barrel_position_of(int(cell[&"index"]))
			if barrel < 0:
				assert_eq(ordinal, 0, "%s: a family-less cell claims no rack" % str(cells.size()))
			else:
				assert_eq(
					ordinal,
					_rack_of_barrel(racks, barrel),
					"a fitted cell's ordinal is the component's own rack"
				)
			assert_eq(
				bool(cell[&"selectable"]),
				ordinal >= 1 and ordinal <= WeaponsScript.GROUPS_MAX,
				"selectability follows the ordinal"
			)
		assert_eq(ordinals, case[&"expected"] as Array[int], "the cells' ordinals")
		print("[s8-ammo] H2 racks=%s ordinals=%s" % [str(racks), str(ordinals)])


# --------------------------------------------------------------------------------- M4


## CONTRACTS section 21 (M4): both panes print `ShipFit.resolve`'s pair. The station hull row
## (1000 / 600) is the defect the QA read as `1250 / 1000`, and a current can never print above
## its own denominator.
func test_both_denominators_are_the_resolved_maxima() -> void:
	_install(QA_FIT)
	_launch()
	var state: Variant = _scene.get(&"_state")
	assert_eq(state.hull_max, float(QA_HULL_MAX), "the flight pool is the resolved hull_max")
	assert_eq(state.shield_max, float(QA_SHIELD_MAX), "and the resolved shield_max")
	var ship: Dictionary = Catalog.ship(HULL)
	assert_ne(int(ship.get(&"hull", 0)), QA_HULL_MAX, "the station row's base is the other figure")

	var status: Variant = (_scene.get(&"_hud") as Node).get(&"_status")
	var footer: Dictionary = status.call(&"footer_lines")
	assert_eq(
		String(footer[&"hull"]),
		"HULL %d / %d" % [QA_HULL_MAX, QA_HULL_MAX],
		"the status footer's hull denominator is resolve's"
	)
	assert_eq(
		String(footer[&"shield"]),
		"SHLD %d / %d" % [QA_SHIELD_MAX, QA_SHIELD_MAX],
		"and its shield denominator"
	)

	_free_scene()
	_install(QA_FIT)
	var panel := _mount(RepairsScene)
	var repaired_hull := _report_value(panel, &"hull")
	assert_eq(repaired_hull, "%d / %d" % [QA_HULL_MAX, QA_HULL_MAX], "Repairs' hull row")
	assert_eq(
		_report_value(panel, &"shield"),
		"%d / %d" % [QA_SHIELD_MAX, QA_SHIELD_MAX],
		"and shield row"
	)
	assert_eq(_report_value(panel, &"missing"), "0 HULL · 0 SHIELD", "nothing is missing at full")

	## The damaged reading: a filed 1000 hull prints against the resolved 1250, which is the
	## reading the base denominator could not produce (it would print 1000 / 1000).
	_free_host()
	_profile.call(&"set_vitals", HULL, 1000, 700)
	var damaged := _mount(RepairsScene)
	assert_eq(_report_value(damaged, &"hull"), "1000 / %d" % QA_HULL_MAX, "a damaged plated hull")
	assert_eq(_report_value(damaged, &"shield"), "700 / %d" % QA_SHIELD_MAX, "and its shield")
	assert_eq(_report_value(damaged, &"missing"), "250 HULL · 100 SHIELD", "the resolved shortfall")

	## And no pane prints a current above its max: a stale filed reading from a heavier fit is
	## read at the resolved ceiling.
	_free_host()
	_profile.call(&"set_vitals", HULL, QA_HULL_MAX, QA_SHIELD_MAX)
	_profile.call(&"set_fit", HULL, BARE_FIT)
	var heavier := _mount(RepairsScene)
	assert_eq(_report_value(heavier, &"hull"), "1000 / 1000", "a current never prints past its max")
	assert_eq(_report_value(heavier, &"shield"), "600 / 600", "on either row")
	print("[s8-ammo] M4 footer=%s repairs=%s" % [str(footer[&"hull"]), repaired_hull])


# ------------------------------------------------------------------------- the copy


## CONTRACTS section 21's copy law: the target panel's distance line states the engine's own
## unit. The QA read `860 m OUT OF RANGE`; docs and mining say `u`.
func test_the_target_distance_reads_units() -> void:
	var hud := _mount(HudScene)
	hud.call(&"set_target_info", {"name": "Swarmer", "distance_m": 860.0, "in_range": false})
	var label: Label = hud.get(&"_target_distance_label")
	assert_eq(String(label.text), "860 u  OUT OF RANGE", "the QA's own reading, in units")
	hud.call(&"set_target_info", {"name": "Swarmer", "distance_m": 860.0, "in_range": true})
	assert_eq(String(label.text), "860 u  IN RANGE", "and with the range state")
	assert_false(String(label.text).contains(" m"), "no metre anywhere in the line")


# --------------------------------------------------------------------------- fixtures


## The fixture account: the Vanguard active and owned, the packs shipped (one family per
## `Catalog.ammo_ids`, each at `DEFAULT_AMMO`), an empty hold, no racks, and the QA's filed
## vitals. Written through the same fields every profile suite hands back.
func _install(fit: Dictionary) -> void:
	var packs: Dictionary = {}
	for family: StringName in Catalog.ammo_ids():
		packs[family] = ProfileData.DEFAULT_AMMO
	var owned: Array[StringName] = [HULL]
	_profile.set(&"_credits", START_CREDITS)
	_profile.set(&"_active_ship", HULL)
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_cargo", {})
	_profile.set(&"_batteries", {})
	_profile.set(&"_ammo", packs)
	_profile.set(&"_vitals", {
		String(HULL): {"hull": QA_HULL_MAX, "shield": QA_SHIELD_MAX, "fuel": 110},
	})
	_profile.call(&"set_fit", HULL, fit)


func _one_gun_fit(module_id: StringName, _unused := "") -> Dictionary:
	return {
		&"engines": ["e_std"],
		&"power": "p_std",
		&"weapons": [String(module_id)],
		&"shields": ["s_light"],
		&"armour": ["h_plate_light"],
	}


## Launch the shipped flight scene on the installed fit and bind the firing readout.
func _launch() -> Node2D:
	_free_scene()
	_scene = GameScene.instantiate() as Node2D
	_fixture_host().add_child(_scene)
	var guns: Node2D = _scene.get(&"_guns")
	var ship: Node2D = _scene.get_node_or_null(NodePath("PlayerShip"))
	if guns != null and ship != null:
		guns.call(&"set_aim_point", ship.global_position + Vector2(0.0, 300.0))
		if not guns.shot_fired.is_connected(_on_shot):
			guns.shot_fired.connect(_on_shot)
	return _scene


## One trigger pull, driven the way the component's own frame drives it: `tick` is what the
## scene's `_physics_process` calls, so a synchronous test reaches the same release path
## without waiting on a frame it cannot await.
func _pull(frames: int) -> Array[StringName]:
	_fired = []
	var guns: Node2D = _scene.get(&"_guns") if _scene != null else null
	if guns == null:
		return _fired
	guns.call(&"set_firing", true)
	for _frame in frames:
		guns.call(&"tick", 1.0 / 60.0)
	guns.call(&"set_firing", false)
	guns.call(&"tick", 1.0 / 60.0)
	return _fired.duplicate()


func _on_shot(family: StringName) -> void:
	_fired.append(family)


func _free_scene() -> void:
	if _scene != null and is_instance_valid(_scene):
		_scene.free()
	_scene = null
	_fired = []


## The panes and HUDs hang off the profile autoload, the way `test_engine2_hud` hangs its HUD:
## it entered the tree before the runner's own scene, so a fixture added there is safe.
func _mount(scene: PackedScene) -> Control:
	if _host == null or not is_instance_valid(_host):
		_host = Control.new()
		_host.name = "S8AmmoHost"
		_host.theme = ThemeRes
		_host.size = Vector2(1920.0, 1080.0)
		_fixture_host().add_child(_host)
	var node := scene.instantiate() as Control
	_host.add_child(node)
	return node


func _free_host() -> void:
	if _host != null and is_instance_valid(_host):
		_host.free()
	_host = null


func _fixture_host() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var root := tree.root
	var host := root.get_node_or_null(NodePath(PROFILE_SERVICE))
	return host if host != null else root


func _brief_value(panel: Control, key: StringName) -> String:
	var values: Dictionary = panel.get(&"_brief_values")
	var label: Label = values.get(key)
	assert_true(label != null, "the briefing carries %s" % key)
	return "" if label == null else String(label.text)


func _report_value(panel: Control, key: StringName) -> String:
	var values: Dictionary = panel.get(&"_values")
	var label: Label = values.get(key)
	assert_true(label != null, "the report carries %s" % key)
	return "" if label == null else String(label.text)


func _status_rows() -> Array:
	var hud: Variant = _scene.get(&"_hud")
	assert_true(hud != null, "the launched scene holds a HUD")
	if hud == null:
		return []
	var status: Variant = hud.get(&"_status")
	assert_true(status != null, "the HUD holds the ship status screen")
	if status == null:
		return []
	return status.call(&"module_rows") as Array


## One status row's own text, rebuilt from the pane's two pinned formats so a row is measured
## against the document's shape rather than against itself.
func _status_row_text(row: Dictionary) -> String:
	var ref := "%s%d" % [String(row[&"token"]), int(row[&"index"]) + 1]
	var rack := int(row[&"rack"])
	if rack >= 1:
		return "%s · B%d · %s" % [ref, rack, String(row[&"name"])]
	return "%s · %s" % [ref, String(row[&"name"])]


## The launched fit's W cells as families, in cell order, family-less cells included - the
## same walk `game.gd:_launch_weapons` makes.
func _fitted_families() -> Array[StringName]:
	var families: Array[StringName] = []
	for entry: Variant in (_profile.call(&"resolved_fit", HULL) as Dictionary).get(WEAPON_SLOT, []):
		families.append(_family_of(StringName(str(entry))))
	return families


## One module entry's firing family: its base catalogue id through `Weapons.weapon_id`, the
## bridge the launch takes (`w_mining` -> `""`, the family-less slot).
func _family_of(module: StringName) -> StringName:
	if module == &"":
		return &""
	var base := StringName(str(_profile.call(&"base_module_id", module)))
	return WeaponsScript.weapon_id(base)


## The fit's W cells as **base** modules, one per cell, the empty ones included: the cell list
## the status pane's rows and the FITTING pane's grid both address.
func _fit_weapon_cells() -> Array[StringName]:
	var cells: Array[StringName] = []
	for entry: Variant in (_profile.call(&"resolved_fit", HULL) as Dictionary).get(WEAPON_SLOT, []):
		var module := StringName(str(entry))
		if module == &"":
			cells.append(&"")
			continue
		cells.append(StringName(str(_profile.call(&"base_module_id", module))))
	return cells


## One cell's index in the **barrel** space: family-bearing W cells count, family-less and
## empty cells answer -1 (CONTRACTS section 16 rule 3's divergence, which `_launch_batteries`
## and `_weapon_barrel_positions` both walk).
func _barrel_position_of(index: int) -> int:
	var barrel := 0
	for cell_index: int in _fit_weapon_cells().size():
		if cell_index == index:
			return barrel if WeaponsScript.weapon_id(_fit_weapon_cells()[cell_index]) != &"" else -1
		if WeaponsScript.weapon_id(_fit_weapon_cells()[cell_index]) != &"":
			barrel += 1
	return -1


static func _rack_of_barrel(racks: Array, barrel: int) -> int:
	for position: int in racks.size():
		if (racks[position] as Array).has(barrel):
			return position + 1
	return 0


static func _unique(values: Array[StringName]) -> Array[StringName]:
	var seen: Array[StringName] = []
	for value: StringName in values:
		if not seen.has(value):
			seen.append(value)
	return seen


## The scratch file's own removal: `ConfigFile` leaves it behind, and the next suite must not
## load a predecessor's account (`test_s5_ammo_cargo`'s own helper).
func _delete_file(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


func _all_families() -> Array[StringName]:
	var families: Array[StringName] = []
	for pack: Dictionary in Catalog.AMMO_PACKS:
		families.append(StringName(pack[&"id"]))
	return families


func _store_total(families: Array[StringName]) -> int:
	var total := 0
	for family: StringName in families:
		total += int(_profile.call(&"ammo_of", family))
	return total
