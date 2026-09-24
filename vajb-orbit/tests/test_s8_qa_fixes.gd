@tool
extends McpTestSuite
## Suite s8_qa_fixes: the S8 QA wave's physics + exchange + copy + bundle family
## (CONTRACTS section 21). Every reading is taken off the shipped scenes and the borrowed
## `PlayerProfile` autoload, so what is measured is the tree's own behaviour.
##
##  - **M1** (`asteroid.gd:_build_look` / `_install_shape`, `asteroid_field.gd:_cleave`) --
##    a rock built outside a physics query flush carries its collision shape at once, while
##    a fragment born inside a hull contact's flush takes it from the deferred queue: the
##    `Shape` node is absent from the cleave's own call and the body's radius is already
##    known, so the physics server is never asked to change shape state mid-flush (the QA
##    measured 16-24 refusals per ram; the Q0 ram probe re-measures the engine's own count).
##  - **M2** (`exchange_panel.gd:_confirm_text` / `_announce_sale`) -- the confirm strip and
##    the `SOLD` line print the hold rows' display name (`CHROMIUM ORE`), never the raw id.
##  - **M3** (`exchange.gd:sell`'s one optional `quoted_total`) -- the strip's preview locks
##    the sale: a demand re-roll between preview and press still credits exactly the shown
##    `YOU GET`, while the default `-1` path stays the live-price path byte-for-byte.
##  - **Copy** (`refinery_panel.gd:_conversions_text`) -- the stepper prints `1 CONVERSION`
##    at n=1 and keeps the plural elsewhere.
##  - **O1/O2** (`armory_panel.gd`) -- the ARMORY's drag commits a rack through the panel's
##    own three handlers; FITTING carries no drag code (Q0's reading, the owner's UX call).
##  - **Warning ledger** -- `weapons.gd`, `module_catalog.gd`, `projectile.gd` and
##    `player_state.gd` parse clean under `--check-only`.
##
## Profile hygiene (L17, T-93): the shipped autoload is borrowed, `save_path` is repointed at
## a scratch file before the first mutation, every field this suite writes is handed back in
## `suite_teardown` and the store is flushed while the scratch path is still in place, so the
## owner's `user://profile.cfg` is never written.

const PanelScene := preload("res://ui/station/exchange_panel.tscn")
const RefineryScene := preload("res://ui/station/refinery_panel.tscn")
const ArmoryScene := preload("res://ui/station/armory_panel.tscn")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const FittingScript := preload("res://ui/station/fitting_panel.gd")
const ExchangeScript := preload("res://game/exchange.gd")
const ModuleData := preload("res://game/module_catalog.gd")
const FieldScript := preload("res://game/asteroid_field.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const Clock := preload("res://autoload/world_clock.gd")

const SCRATCH_PROFILE := "user://test_s8_qa_fixes.cfg"
const PROFILE_SERVICE: StringName = &"PlayerProfile"
const HULL: StringName = &"ship_vanguard"
const ORE: StringName = &"mineral_chromium"
const MINERAL: StringName = &"chromium"
const IRON_ORE: StringName = &"mineral_iron"
const DROP_RACK_BODY := -1
const SHAPE_NODE: StringName = &"Shape"
const BASE_CREDITS := 10000
const LEDGER_FILES: Array[String] = [
	"res://game/weapons.gd",
	"res://game/module_catalog.gd",
	"res://game/projectile.gd",
	"res://game/player_state.gd",
]

var _profile: Node = null
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_fits: Dictionary = {}
var _previous_modules: Dictionary = {}
var _previous_batteries: Dictionary = {}
var _previous_cargo: Dictionary = {}
var _previous_credits := 0
var _previous_market: Dictionary = {}
var _previous_vitals: Dictionary = {}
var _host: Control = null
var _fields: Array[Node] = []


func suite_name() -> String:
	return "s8_qa_fixes"


func suite_setup(_ctx: Dictionary) -> void:
	_profile = _fixture_host()
	if _profile == null or not _profile.has_method(&"battery_groups"):
		fail_setup("the PlayerProfile autoload is the store this suite measures")
		return
	_previous_path = String(_profile.get(&"save_path"))
	_previous_ship = StringName(_profile.call(&"active_ship"))
	_previous_fits = _profile.call(&"fits")
	_previous_modules = _profile.call(&"modules")
	_previous_batteries = (_profile.get(&"_batteries") as Dictionary).duplicate(true)
	_previous_cargo = (_profile.get(&"_cargo") as Dictionary).duplicate(true)
	_previous_credits = int(_profile.call(&"credits"))
	_previous_market = (_profile.get(&"_market") as Dictionary).duplicate(true)
	_previous_vitals = (_profile.get(&"_vitals") as Dictionary).duplicate(true)
	_profile.set(&"save_path", SCRATCH_PROFILE)
	_remove(SCRATCH_PROFILE)


func suite_teardown() -> void:
	_free_host()
	_free_fields()
	if _profile == null:
		return
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_fits", _previous_fits)
	_profile.set(&"_modules", _previous_modules)
	_profile.set(&"_batteries", _previous_batteries)
	_profile.set(&"_cargo", _previous_cargo)
	_profile.set(&"_credits", _previous_credits)
	_profile.set(&"_market", _previous_market)
	_profile.set(&"_vitals", _previous_vitals)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	_remove(SCRATCH_PROFILE)
	_profile = null


func setup() -> void:
	_free_host()
	_free_fields()
	_install_state({}, BASE_CREDITS)


func teardown() -> void:
	_free_host()
	_free_fields()


# --------------------------------------------------------------------------------- M1


## CONTRACTS section 21 (M1): the fragment's shape state is taken outside the physics query
## flush. A rock built outside a flush installs its `Shape` at once; a cleave that runs inside
## a hull contact's flush hands every fragment its shape from the deferred queue instead, and
## the body's collision radius is known before the node lands, so the fragment collides from
## its first eligible step. The engine's own refusal count (the QA's 16-24 per ram) is
## re-measured by the Q0 ram probe; this pins the deferral that removes it.
func test_a_fragment_takes_its_shape_on_the_next_step() -> void:
	var field := _mount_field()
	var rock: RigidBody2D = field.call(
		&"_new_rock", "RockProbe", &"iron", 1, 3, AsteroidScript.SIZE_MEDIUM
	)
	var shape := rock.get_node_or_null(NodePath(SHAPE_NODE)) as CollisionShape2D
	assert_true(shape != null, "a rock built outside the flush carries its shape at once")
	assert_gt(float(rock.call(&"world_radius")), 0.0, "and its radius follows the sprite")
	rock.call(&"apply_work", 3.0)
	var fragments: Array[Node] = []
	for child: Node in field.get_children():
		if String(child.name).begins_with("Fragment"):
			fragments.append(child)
	assert_gt(fragments.size(), 0, "the depleted medium cleaved into fragments")
	for fragment: Node in fragments:
		assert_true(
			fragment.get_node_or_null(NodePath(SHAPE_NODE)) == null,
			"the fragment's shape is deferred out of the cleave's own call"
		)
		assert_gt(
			float(fragment.call(&"world_radius")),
			0.0,
			"the fragment's radius is known before its shape node lands"
		)
	var first: Node2D = fragments[0]
	var placed := float(first.call(&"world_radius"))
	first.call(&"_install_shape")
	var landed := first.get_node_or_null(NodePath(SHAPE_NODE)) as CollisionShape2D
	assert_true(landed != null, "the deferred installer puts the shape on the body")
	assert_true(landed.shape is CircleShape2D, "and it is the rock's circle")
	if landed.shape is CircleShape2D:
		assert_true(
			is_equal_approx((landed.shape as CircleShape2D).radius, placed),
			"whose radius is the figure the cleave placed the fragment by"
		)


# --------------------------------------------------------------------------------- M2


## CONTRACTS section 21 (M2) / 05 section 9: the confirm strip and the `SOLD` line resolve the
## hold rows' display name. The QA read `MINERAL_CHROMIUM` beside a hold row named
## `CHROMIUM ORE`; no raw id may reach player-facing sale copy.
func test_the_confirm_strip_and_sold_line_print_the_display_name() -> void:
	_install_state({String(ORE): 1}, BASE_CREDITS)
	var panel := _mount(PanelScene)
	panel.call(&"_select", ORE)
	assert_true(_strip(panel).contains("CHROMIUM ORE"), "the confirm strip names the ore (%s)" % _strip(panel))
	assert_false(
		_strip(panel).contains("MINERAL_CHROMIUM"),
		"the confirm strip carries no raw id (%s)" % _strip(panel)
	)
	panel.call(&"_on_sell_pressed")
	assert_true(_strip(panel).begins_with("SOLD"), "the sale announced (%s)" % _strip(panel))
	assert_true(_strip(panel).contains("CHROMIUM ORE"), "the SOLD line names the ore (%s)" % _strip(panel))
	assert_false(
		_strip(panel).contains("MINERAL_CHROMIUM"),
		"the SOLD line carries no raw id (%s)" % _strip(panel)
	)


# --------------------------------------------------------------------------------- M3


## CONTRACTS section 21 (M3) / 05 section 9: the strip captures the quote at preview and the
## press commits it. The test writes the market's demand to a lower figure between the two, so
## the live price has moved, and then presses SELL: the credited delta is exactly the `YOU GET`
## the strip showed.
func test_the_honored_quote_credits_the_shown_you_get() -> void:
	_install_state({String(ORE): 1}, 6001, 1.0, 1)
	var panel := _mount(PanelScene)
	panel.call(&"_select", ORE)
	var promised := int((panel.get(&"_quoted") as Dictionary).get(&"paid", -1))
	assert_gt(promised, 0, "the preview quoted a positive YOU GET")
	_profile.set(&"_market", _market(0.6, -1, Clock.now()))
	var live := ExchangeScript.quote(_profile, ORE, 1, Clock.now())
	assert_ne(int(live[&"paid"]), promised, "the re-roll moved the live price (the defect's premise)")
	var before := int(_profile.call(&"credits"))
	panel.call(&"_on_sell_pressed")
	assert_eq(
		int(_profile.call(&"credits")) - before,
		promised,
		"credits exactly the shown YOU GET, not the re-rolled live figure"
	)


## The default `-1` path is byte-identical: with no quote the sale pays the live quote's paid.
func test_the_default_sale_path_still_pays_the_live_price() -> void:
	_install_state({String(ORE): 2}, BASE_CREDITS, 1.0, 1)
	var now := Clock.now()
	var quoted: Dictionary = ExchangeScript.quote(_profile, ORE, 1, now)
	var before := int(_profile.call(&"credits"))
	var result: Dictionary = ExchangeScript.sell(_profile, ORE, 1, now)
	assert_eq(int(result[&"paid"]), int(quoted[&"paid"]), "no quote means the live quote's paid")
	assert_eq(
		int(_profile.call(&"credits")) - before,
		int(quoted[&"paid"]),
		"and that is exactly what is credited"
	)


## A quoted gross reproduces the preview's own gross / fee / paid through `commission_for`.
func test_a_quoted_gross_reproduces_the_preview_strip() -> void:
	_install_state({String(ORE): 2}, BASE_CREDITS, 1.0, 1)
	var now := Clock.now()
	var preview: Dictionary = ExchangeScript.quote(_profile, ORE, 2, now)
	_profile.set(&"_market", _market(0.5, -1, now))
	var result: Dictionary = ExchangeScript.sell(
		_profile, ORE, 2, now, null, int(preview[&"gross"])
	)
	assert_eq(int(result[&"gross"]), int(preview[&"gross"]), "the quoted gross commits")
	assert_eq(int(result[&"fee"]), int(preview[&"fee"]), "the fee follows it")
	assert_eq(int(result[&"paid"]), int(preview[&"paid"]), "and so does the YOU GET")


# --------------------------------------------------------------------------------- copy


## CONTRACTS section 21: the stepper's count reads `1 CONVERSION` at one conversion and keeps
## the plural elsewhere. The stack is armed through the panel's own row payload.
func test_the_stepper_prints_one_conversion_singular() -> void:
	_install_state({String(IRON_ORE): 3}, BASE_CREDITS)
	var panel := _mount(RefineryScene)
	var payload := _refinery_payload(panel, &"iron")
	assert_true(not payload.is_empty(), "the iron stack is listed")
	panel.call(&"_arm", payload, false)
	var stepper: Label = panel.get(&"_stepper_value")
	assert_eq(stepper.text, "1 CONVERSION", "one conversion is singular")
	assert_eq(String(panel.call(&"_conversions_text", 2)), "2 CONVERSIONS", "two keep the plural")
	assert_eq(String(panel.call(&"_conversions_text", 0)), "0 CONVERSIONS", "and zero keeps the shipped idle")


## The catalogue's `name` is the one player-facing spelling (CONTRACTS section 21): the panel
## family may case it, never respell it, so no `Mk1` ships anywhere in `ui/`.
func test_the_catalogue_name_is_the_one_spelling() -> void:
	var row: Dictionary = ModuleData.module(&"w_cannon")
	assert_eq(String(row.get(&"name", "")), "Cannon MkI", "the catalogue's own spelling")


# --------------------------------------------------------------------------------- O1/O2


## CONTRACTS section 21 (O1/O2): the ARMORY's drag commits a rack through the panel's own three
## handlers (`drag_inventory` / `can_drop` / `drop`), and a barrel move rewrites the rack. The
## finding is discoverability, so no FITTING-side drag code exists to build.
func test_the_armory_drag_commits_a_rack_through_the_handlers() -> void:
	_install_armory()
	var panel := _mount(ArmoryScene)
	assert_eq(_fitting_handlers(), "", "FITTING declares no drag handler (the owner's UX call)")
	var laser: Dictionary = panel.call(&"drag_inventory", &"w_laser")
	assert_true(
		bool(panel.call(&"can_drop", 0, DROP_RACK_BODY, laser)),
		"the inventory drag can land on rack B1"
	)
	assert_true(bool(panel.call(&"drop", 0, DROP_RACK_BODY, laser)), "and the drop commits it")
	assert_eq(_profile.call(&"battery_groups", HULL), [[0]], "B1 holds barrel 0")
	var cannon: Dictionary = panel.call(&"drag_inventory", &"w_cannon")
	assert_true(bool(panel.call(&"drop", 1, DROP_RACK_BODY, cannon)), "a second barrel lands on B2")
	panel.call(&"refresh_profile", &"batteries")
	var barrel: Dictionary = panel.call(&"drag_barrel", 1, 0)
	assert_true(
		bool(panel.call(&"drop", 0, DROP_RACK_BODY, barrel)),
		"the barrel-move drag commits"
	)
	assert_eq(_profile.call(&"battery_groups", HULL), [[0, 1]], "B1 now holds both barrels")


func _fitting_handlers() -> String:
	var script: Script = FittingScript
	var found: Array[String] = []
	for method: Dictionary in script.get_script_method_list():
		var name_text := String(method.get("name", ""))
		if name_text in ["_get_drag_data", "_can_drop_data", "_drop_data"]:
			found.append(name_text)
	return ", ".join(found)


# --------------------------------------------------------------------------------- ledger


## CONTRACTS section 21's warning ledger: the four files the wave owns parse clean under
## `--check-only`, asserted by running the engine against each one.
func test_the_four_warning_ledger_files_parse_clean() -> void:
	for path: String in LEDGER_FILES:
		var output: Array = []
		var code := OS.execute(
			OS.get_executable_path(),
			[
				"--headless",
				"--path",
				ProjectSettings.globalize_path("res://"),
				"--check-only",
				"--script",
				path,
			],
			output,
			true
		)
		assert_eq(code, 0, "%s parses clean under --check-only" % path)


# --------------------------------------------------------------------------------- fixtures


func _mount_field() -> Node2D:
	var field := FieldScript.new() as Node2D
	field.name = "S8Field"
	_fixture_host().add_child(field)
	_fields.append(field)
	return field


func _mount(scene: PackedScene) -> Control:
	if _host == null or not is_instance_valid(_host):
		_host = Control.new()
		_host.name = "S8QaFixesHost"
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


func _free_fields() -> void:
	for field: Node in _fields:
		if is_instance_valid(field):
			field.free()
	_fields.clear()


func _fixture_host() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var root := tree.root
	var host := root.get_node_or_null(NodePath(PROFILE_SERVICE))
	return host if host != null else root


func _strip(panel: Control) -> String:
	return String((panel.get(&"_confirm_strip") as Label).text)


func _refinery_payload(panel: Control, mineral_id: StringName) -> Dictionary:
	for payload: Variant in panel.get(&"_payloads"):
		if payload is Dictionary and StringName((payload as Dictionary).get(&"id", &"")) == mineral_id:
			return payload
	return {}


## A profile with one known cargo and market state: the panels read both at build.
func _install_state(
	cargo: Dictionary, credits: int, demand: float = 1.0, trend: int = 1
) -> void:
	_profile.set(&"_cargo", cargo)
	_profile.set(&"_credits", credits)
	_profile.set(&"_market", _market(demand, trend, Clock.now()))


func _market(demand: float, trend: int, stamp: int) -> Dictionary:
	return {
		"demand": {String(MINERAL): demand},
		"stock": {},
		"queue": {},
		"trend": {String(MINERAL): trend},
		"last_band": stamp,
	}


## The armory fixture Q0 reproduced the drag on: a bare Vanguard with two weapon instances.
func _install_armory() -> void:
	_profile.set(&"_active_ship", HULL)
	_profile.set(&"_fits", {})
	_profile.set(&"_batteries", {})
	_profile.call(&"set_fit", HULL, {
		&"engines": ["e_std"],
		&"power": "p_std",
		&"weapons": ["", "", ""],
		&"shields": [],
		&"armour": [],
	})
	_profile.call(&"set_modules", {
		"mod_0001": _record("mod_0001", "w_laser"),
		"mod_0002": _record("mod_0002", "w_cannon"),
		"e_std": _record("e_std", "e_std"),
	})


func _record(id: String, base: String) -> Dictionary:
	return {
		"base_id": base,
		"count": 1,
		"instance_id": id,
		"prefixes": [],
		"rarity": "common",
		"suffixes": [],
	}


func _remove(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())
