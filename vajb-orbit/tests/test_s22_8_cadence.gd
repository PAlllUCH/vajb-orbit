extends McpTestSuite
## Suite s22_8_cadence: the weapons-cadence split (owner 2026-10-01, 18 §4.1's
## amendment block). The spam tier - laser, plasma, cannon - holds fire exactly as
## shipped; the heavy tier - railgun 15 s, rocket 12 s, mine 10 s - fires one shot,
## then its barrel cools. The cooldown *is* the barrel's cadence (`interval_of`
## reads it), so the battery cycle, the held-trigger stream and the `Rapid` affix
## keep their shapes, and the HUD counts the selected rack down while its cells dim.

const WeaponScript := preload("res://game/weapons.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const HudScene := preload("res://ui/hud/hud.tscn")
const HudTheme := preload("res://ui/theme/vajb_theme.tres")

const PROFILE_SERVICE: StringName = &"PlayerProfile"

## The three cooldown values the amendment pins, and the railgun's derived spike.
const RAILGUN_COOLDOWN := 15.0
const ROCKET_COOLDOWN := 12.0
const MINE_COOLDOWN := 10.0
const RAILGUN_ALPHA := 450.0

var _guns: Node2D = null
var _state: PlayerState = null
var _staged: Array[Node] = []
var _hud: Control = null


func suite_name() -> String:
	return "s22_8_cadence"


func setup() -> void:
	_guns = null
	_state = PlayerStateScript.new()
	_state.setup()


func teardown() -> void:
	if _hud != null and is_instance_valid(_hud):
		_hud.queue_free()
	_hud = null
	if _guns != null and is_instance_valid(_guns):
		_guns.free()
	_guns = null
	for node: Node in _staged:
		if is_instance_valid(node):
			node.free()
	_staged.clear()
	_clear_shots()
	_state = null


# --- AC1/AC2/AC4: the table law -------------------------------------------------


## The split lives in the rows: the spam tier states no cooldown, the heavy tier
## states the amendment's three values, and the railgun's slug is the derived alpha.
func test_the_split_law_lives_in_the_family_table() -> void:
	for id: StringName in [&"laser", &"plasma", &"cannon"]:
		assert_false(
			WeaponScript.row_of(id).has(&"cooldown"),
			"%s is the spam tier: no cooldown row" % id
		)
	assert_eq(
		float(WeaponScript.row_of(&"railgun")[&"cooldown"]),
		RAILGUN_COOLDOWN,
		"the railgun cools 15 s"
	)
	assert_eq(
		float(WeaponScript.row_of(&"rocket")[&"cooldown"]),
		ROCKET_COOLDOWN,
		"the rocket cools 12 s"
	)
	assert_eq(
		float(WeaponScript.row_of(&"mine")[&"cooldown"]),
		MINE_COOLDOWN,
		"the mine cools 10 s"
	)
	assert_eq(WeaponScript.shot_damage(&"railgun"), RAILGUN_ALPHA, "the slug is the spike alpha")
	assert_eq(WeaponScript.shot_damage(&"rocket"), 180.0, "the rocket keeps its alpha")
	assert_eq(WeaponScript.shot_damage(&"mine"), 180.0, "the mine keeps its alpha")


## The spam tier's own cadence is byte-identical: beams have no shot cadence and the
## cannon's burst cycle sums to 0.6, with its per-shot damage unchanged.
func test_the_spam_tier_is_untouched() -> void:
	assert_eq(WeaponScript.interval_of(&"laser"), 0.0, "the laser has no shot cadence")
	assert_eq(WeaponScript.interval_of(&"plasma"), 0.0, "nor has the plasma")
	assert_eq(WeaponScript.interval_of(&"cannon"), 0.6, "the cannon's burst cycle stands")
	assert_eq(WeaponScript.shot_damage(&"cannon"), 27.0, "45 DPS x 0.6 s unchanged")


# --- AC2/AC3: the cooldown is the cadence ---------------------------------------


## One pull, one slug, then the barrel waits its 15 s: the held trigger repeats one
## shot per cooldown (the stream law intact) and nothing between.
func test_a_cooldown_barrel_fires_once_then_waits() -> void:
	var guns := _rig([&"w_railgun"])
	if guns == null:
		return
	var slot := WeaponScript.ammo_slot(&"railgun")
	_state.set_ammo(slot, 30)
	var shots: Array[StringName] = []
	guns.connect(&"shot_fired", func(id: StringName) -> void: shots.append(StringName(id)))
	guns.call(&"select_group", 1)
	var frame := 1.0 / 60.0
	guns.call(&"set_firing", true)
	for _frame in 5:
		guns.call(&"tick", frame)
	assert_eq(shots.size(), 1, "the pull released exactly one slug")
	assert_true(
		float(guns.call(&"rack_cooldown", 1)) > RAILGUN_COOLDOWN - 5.0 * frame
			and float(guns.call(&"rack_cooldown", 1)) <= RAILGUN_COOLDOWN,
		"the barrel reads its cooldown, minus only the frames since the release (%.3f)"
		% float(guns.call(&"rack_cooldown", 1))
	)
	for _frame in 890:
		guns.call(&"tick", frame)
	assert_eq(shots.size(), 1, "a held trigger stays silent for the whole cooldown")
	for _frame in 70:
		guns.call(&"tick", frame)
	assert_eq(shots.size(), 2, "the stream repeats one shot per cooldown")
	assert_eq(_state.ammo[slot], 28, "two slugs spent two rounds of the shared pack")


## The battery gate is the heavy member's cooldown: a laser+railgun rack cycles at
## 15 s, which is the rotation law the split asks for.
func test_the_battery_cycle_reads_the_cooldown() -> void:
	var guns := _rig([&"w_laser", &"w_railgun"], [[0, 1]])
	if guns == null:
		return
	assert_eq(guns.call(&"racks"), [[0, 1]], "the composed rack holds both barrels")
	assert_eq(
		guns.call(&"battery_cycle"),
		WeaponScript.interval_of(&"railgun"),
		"the gate is max(members' cadence), now the cooldown"
	)
	assert_true(
		is_equal_approx(float(guns.call(&"battery_cycle")), RAILGUN_COOLDOWN),
		"and the number is the amendment's 15 s"
	)


## The mine keeps its edge law under the cooldown: one drop per pull, and a second
## pull inside the cooldown drops nothing until the 10 s have run.
func test_the_mine_keeps_its_edge_under_the_cooldown() -> void:
	var guns := _rig([&"w_mine"])
	if guns == null:
		return
	var slot := WeaponScript.ammo_slot(&"mine")
	_state.set_ammo(slot, 30)
	var shots: Array[StringName] = []
	guns.connect(&"shot_fired", func(id: StringName) -> void: shots.append(StringName(id)))
	guns.call(&"select_group", 1)
	var frame := 1.0 / 60.0
	guns.call(&"set_firing", true)
	for _frame in 5:
		guns.call(&"tick", frame)
	guns.call(&"set_firing", false)
	guns.call(&"tick", frame)
	assert_eq(shots.size(), 1, "the first pull dropped one mine")
	guns.call(&"set_firing", true)
	for _frame in 5:
		guns.call(&"tick", frame)
	guns.call(&"set_firing", false)
	guns.call(&"tick", frame)
	assert_eq(shots.size(), 1, "an immediate second pull drops nothing (edge + cooldown)")
	for _frame in int((MINE_COOLDOWN + 0.2) / frame):
		guns.call(&"tick", frame)
	guns.call(&"set_firing", true)
	for _frame in 5:
		guns.call(&"tick", frame)
	guns.call(&"set_firing", false)
	guns.call(&"tick", frame)
	assert_eq(shots.size(), 2, "a pull after the cooldown drops again")


# --- AC6: the affix law ----------------------------------------------------------


## `Rapid` divides the barrel's release interval, and the cooldown *is* that
## interval, so a Rapid railgun cools 15 / 1.15.
func test_rapid_divides_the_cooldown() -> void:
	_state.set_weapons([&"railgun"])
	_state.setup()
	var guns := _rig([&"w_railgun"])
	if guns == null:
		return
	assert_true(
		is_equal_approx(float(guns.call(&"_barrel_interval", 0)), RAILGUN_COOLDOWN),
		"no affix: the barrel's cadence is the cooldown"
	)
	_set_affixes([{&"rapid": 0.15}])
	assert_true(
		is_equal_approx(float(guns.call(&"_barrel_interval", 0)), RAILGUN_COOLDOWN / 1.15),
		"Rapid divides the cooldown (%.4f)" % float(guns.call(&"_barrel_interval", 0))
	)


# --- AC7: the HUD readout --------------------------------------------------------


## The selected rack's remaining seconds join the ammo readout and the cooling
## battery's cells dim; when the barrel is ready the readout is plain again and the
## cell is back to full alpha.
func test_the_hud_counts_the_cooldown_down_and_dims_the_battery() -> void:
	var host := _fixture_host()
	if host == null:
		skip("no PlayerProfile autoload to host the HUD")
		return
	var guns := _rig([&"w_railgun"])
	if guns == null:
		return
	var slot := WeaponScript.ammo_slot(&"railgun")
	_state.set_ammo(slot, 30)
	_hud = HudScene.instantiate() as Control
	if _hud == null:
		assert_true(false, "hud.tscn did not instantiate")
		return
	_hud.theme = HudTheme
	host.add_child(_hud)
	_hud.call(
		&"set_hull_slots",
		&"ship_vanguard",
		[
			{
				&"slot": &"weapons",
				&"index": 0,
				&"module": &"w_railgun",
				&"icon": "",
				&"fitted": true,
				&"selectable": true,
				&"battery": 1,
				&"position": 0,
			},
		]
	)
	_hud.call(&"bind_weapons", guns)
	_hud.call(&"select_battery", 1)
	var label := _hud.get_node(NodePath("%AmmoLabel")) as Label
	if label == null:
		assert_true(false, "the HUD's ammo label is missing")
		return
	var plain := String(label.text)
	var frame := 1.0 / 60.0
	guns.call(&"select_group", 1)
	guns.call(&"set_firing", true)
	for _frame in 5:
		guns.call(&"tick", frame)
	guns.call(&"set_firing", false)
	guns.call(&"tick", frame)
	_hud.call(&"_refresh_cooldown_state")
	assert_true(
		label.text.begins_with(plain),
		"the readout keeps its plain half (%s)" % label.text
	)
	assert_true(label.text.contains("COOLING"), "and counts the cooling barrel down")
	var slots: Array = _hud.get(&"_weapon_slots")
	assert_true(slots.size() >= 1, "the grid was rebuilt from the pushed cell")
	var cell: TextureButton = slots[0]
	assert_true(cell.modulate.a < 1.0, "the cooling battery's cell is dimmed")
	for _frame in int((RAILGUN_COOLDOWN + 0.2) / frame):
		guns.call(&"tick", frame)
	_hud.call(&"_refresh_cooldown_state")
	assert_false(label.text.contains("COOLING"), "a ready barrel reads plain again")
	assert_true(
		is_equal_approx(cell.modulate.a, 1.0),
		"and the cell is back to full alpha"
	)


## A spam-tier selection changes nothing: no cooling rack, no suffix, full cells.
func test_the_hud_stays_plain_on_the_spam_tier() -> void:
	var host := _fixture_host()
	if host == null:
		skip("no PlayerProfile autoload to host the HUD")
		return
	var guns := _rig([&"w_cannon"])
	if guns == null:
		return
	_state.set_ammo(WeaponScript.ammo_slot(&"cannon"), 30)
	_hud = HudScene.instantiate() as Control
	if _hud == null:
		assert_true(false, "hud.tscn did not instantiate")
		return
	_hud.theme = HudTheme
	host.add_child(_hud)
	_hud.call(
		&"set_hull_slots",
		&"ship_vanguard",
		[
			{
				&"slot": &"weapons",
				&"index": 0,
				&"module": &"w_cannon",
				&"icon": "",
				&"fitted": true,
				&"selectable": true,
				&"battery": 1,
				&"position": 0,
			},
		]
	)
	_hud.call(&"bind_weapons", guns)
	_hud.call(&"select_battery", 1)
	var label := _hud.get_node(NodePath("%AmmoLabel")) as Label
	if label == null:
		assert_true(false, "the HUD's ammo label is missing")
		return
	var plain := String(label.text)
	var frame := 1.0 / 60.0
	guns.call(&"select_group", 1)
	guns.call(&"set_firing", true)
	for _frame in 5:
		guns.call(&"tick", frame)
	guns.call(&"set_firing", false)
	guns.call(&"tick", frame)
	_hud.call(&"_refresh_cooldown_state")
	assert_eq(label.text, plain, "a spam barrel never grows the suffix")


# --- the rig ---------------------------------------------------------------------


func _rig(ids: Array, racks: Array = []) -> Node2D:
	var host := _fixture_host()
	if host == null:
		skip("no PlayerProfile autoload to host the rig")
		return null
	var holder := Node2D.new()
	holder.name = &"S22_8CadenceRig"
	host.add_child(holder)
	_guns = WeaponScript.new() as Node2D
	holder.add_child(_guns)
	_guns.call(&"setup", null, _state)
	var fit: Array[StringName] = []
	for id: Variant in ids:
		fit.append(StringName(id))
	_guns.call(&"set_fitted", fit)
	if not racks.is_empty():
		_guns.call(&"set_batteries", racks)
	_staged.append(holder)
	return _guns


func _set_affixes(cells: Array) -> void:
	var per: Array[Dictionary] = []
	for cell: Variant in cells:
		per.append((cell as Dictionary) if cell is Dictionary else {})
	_state.set_weapon_affixes(per)


func _fixture_host() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(NodePath(PROFILE_SERVICE))


func _shots() -> Array[Node]:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return []
	return tree.get_nodes_in_group(&"projectile")


func _clear_shots() -> void:
	for shot: Node in _shots():
		if is_instance_valid(shot):
			shot.free()
