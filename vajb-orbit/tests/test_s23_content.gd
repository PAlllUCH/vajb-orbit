extends McpTestSuite
## Suite s23_content: the dead-content wave (S23, brief acceptance A1-A7; A8's rows
## live in `test_s13_devmenu.gd`). One row per acceptance:
##   A1  the two exclusive families fire (proton cooldown-tier, flak spam cone)
##   A2  the three dead modules carry their effects end to end
##   A3  the seven stock fits (the four that fit landed, three staged on power)
##   A4  the sibelon seam released, the interceptor and turret-platform hull rows
##   A5  per-hull flight sprites, liveries, the damaged Vanguard
##   A6  the loot rows (countermeasure catalogue, the hunter table, cache tiers)
##   A7  the PROPOSED tick state the wave shipped
## Contract: S23_BRIEF.md sections 0 (V1-V5), 5, 6; docs/gameplay 08/09's 2026-09-27
## P3 blocks; 15 section 5; 06 section 3.1/7; 18 section 2.1 ruling 24.

const WeaponScript := preload("res://game/weapons.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const FitScript := preload("res://game/ship_fit.gd")
const ModuleScript := preload("res://game/module_catalog.gd")
const StationCatalogScript := preload("res://game/station_catalog.gd")
const RegistryScript := preload("res://game/npc_registry.gd")
const SectorRegistryScript := preload("res://game/sector_registry.gd")
const LootScript := preload("res://game/loot_tables.gd")
const Components := preload("res://game/component_catalog.gd")
const RefineryScript := preload("res://game/refinery.gd")
const MineralCatalogScript := preload("res://game/mineral_catalog.gd")
const NpcShipScript := preload("res://game/npc_ship.gd")
const PlayerShipScene := preload("res://game/player_ship.tscn")
const LaunchPanelScript := preload("res://ui/station/launch_panel.gd")

const PROFILE_SERVICE: StringName = &"PlayerProfile"

## Brief V5 / R-S23-1/2: the two families' pinned numbers.
const PROTON_COOLDOWN := 12.0
const PROTON_ALPHA := 220.0
const FLAK_INTERVAL := 0.55
const FLAK_VOLLEY := 22.0
const FLAK_PELLETS := 4
const FLAK_SPREAD_DEG := 12.0

const HULL_IDS: Array[StringName] = [
	&"ship_fighter", &"ship_vanguard", &"ship_miner", &"ship_trader",
	&"ship_corvette", &"ship_freighter", &"ship_gunship", &"ship_patrol",
	&"ship_destroyer",
]

var _state: PlayerState = null
var _guns: Node2D = null
var _staged: Array[Node] = []
var _profile_snapshot: Dictionary = {}


func suite_name() -> String:
	return "s23_content"


func setup() -> void:
	_guns = null
	_state = PlayerStateScript.new()
	_state.setup()


func teardown() -> void:
	if _guns != null and is_instance_valid(_guns):
		_guns.free()
	_guns = null
	for node: Node in _staged:
		if is_instance_valid(node):
			node.free()
	_staged.clear()
	_clear_shots()
	_restore_profile()
	_state = null


# --- A1: the two exclusive families ---------------------------------------------


## R-S23-1/2 read through V5: the proton is the cooldown tier at the rocket's 12 s
## with its own alpha, and the flak stays spam at 0.55 s with the cone's rows; both
## are 15 section 5 exclusives (Choir/Concord, Magic floor) and both are real
## modules a fit can carry.
func test_a1_the_exclusive_families_fire_per_the_p3_rows() -> void:
	var proton := WeaponScript.row_of(&"proton")
	var flak := WeaponScript.row_of(&"flak")
	assert_false(proton.is_empty(), "w_proton has a family row")
	assert_false(flak.is_empty(), "w_flak has a family row")
	assert_eq(float(proton[&"cooldown"]), PROTON_COOLDOWN, "the proton joins the cooldown tier at 12 s (V5)")
	assert_eq(WeaponScript.interval_of(&"proton"), PROTON_COOLDOWN, "and interval_of reads it")
	assert_eq(WeaponScript.shot_damage(&"proton"), PROTON_ALPHA, "the proton's alpha is 220")
	assert_eq(float(proton[&"speed"]), 750.0, "750 u/s")
	assert_eq(float(proton[&"turn_rate"]), 2.6, "homing turn 2.6 rad/s")
	assert_eq(float(proton[&"track_dps"]), 70.0, "tracking 70")
	assert_eq(float(proton[&"draw"]), 12.0, "draw 12")
	assert_true(bool(proton[&"homing"]), "the proton homes")
	assert_true(bool(proton[&"bypass_shield"]), "and bypasses shields")
	assert_eq(StringName(proton[&"module"]), &"w_proton", "the row is w_proton's")
	assert_eq(float(flak[&"interval"]), FLAK_INTERVAL, "the flak stays spam at 0.55 s (V5)")
	assert_eq(WeaponScript.shot_damage(&"flak"), FLAK_VOLLEY, "the volley is 22 damage")
	assert_eq(int(flak[&"pellets"]), FLAK_PELLETS, "four pellets")
	assert_eq(float(flak[&"spread_deg"]), FLAK_SPREAD_DEG, "at 12 degrees")
	assert_eq(float(flak[&"speed"]), 1100.0, "1 100 u/s")
	assert_eq(float(flak[&"track_dps"]), 140.0, "tracking 140")
	assert_eq(float(flak[&"draw"]), 8.0, "draw 8")
	assert_true(not bool(flak[&"bypass_shield"]), "no shield bypass")
	var bonus: Dictionary = flak[&"target_bonus"]
	assert_eq(float(bonus.get(&"swarmer", 1.0)), 2.0, "x2 vs the swarmer")
	assert_eq(float(WeaponScript.interval_of(&"flak")), FLAK_INTERVAL, "the spam cadence is the row's own")
	## 15 section 5, untouched: the exclusivity map and the Magic floor.
	assert_eq(StringName(ModuleScript.EXCLUSIVES.get(&"w_proton", &"")), &"choir", "the proton is Choir's")
	assert_eq(StringName(ModuleScript.EXCLUSIVES.get(&"w_flak", &"")), &"concord", "the flak is Concord's")
	assert_eq(ModuleScript.EXCLUSIVE_FLOOR, ModuleScript.RARITY_MAGIC, "the floor is Magic")
	assert_false(ModuleScript.module(&"w_proton").is_empty(), "w_proton is a real module row")
	assert_false(ModuleScript.module(&"w_flak").is_empty(), "w_flak is a real module row")
	## The landed V1 packs (the brief's 2026-10-01 amendment): the catalogue sells
	## both exclusive packs at their pinned rounds/cost and the profile's AMMO_MAX
	## carries their ceilings.
	var proton_pack := StationCatalogScript.ammo_pack(&"proton")
	assert_eq(int(proton_pack[&"rounds"]), 40, "the proton pack sells 40 rounds")
	assert_eq(int(proton_pack[&"cost"]), 400, "at 400 CR")
	var flak_pack := StationCatalogScript.ammo_pack(&"flak")
	assert_eq(int(flak_pack[&"rounds"]), 300, "the flak pack sells 300 rounds")
	assert_eq(int(flak_pack[&"cost"]), 260, "at 260 CR")
	var profile := _host()
	if profile == null:
		skip("no PlayerProfile autoload to read the AMMO_MAX ceilings from")
		return
	assert_eq(int(profile.call(&"ammo_max", &"proton")), 60, "the proton's AMMO_MAX ceiling is 60")
	assert_eq(int(profile.call(&"ammo_max", &"flak")), 300, "the flak's AMMO_MAX ceiling is 300")


## The flak cone: one release spawns the row's four pellets across the 12-degree
## fan, each carrying the volley's own share, and one round leaves the pack.
func test_a1_the_flak_cone_releases_four_pellets_per_round() -> void:
	var guns := _rig([&"w_flak"])
	if guns == null:
		return
	_state.set_weapons([&"flak"])
	_state.setup()
	_state.set_ammo(0, 10)
	_rig_refit([&"w_flak"])
	var shots_before := _shots().size()
	var frame := 1.0 / 60.0
	_guns.call(&"select_group", 1)
	_guns.call(&"set_firing", true)
	for _frame in 5:
		_guns.call(&"tick", frame)
	_guns.call(&"set_firing", false)
	var shots := _shots().size() - shots_before
	assert_eq(shots, FLAK_PELLETS, "one release spawned the four-pellet cone")
	if shots == FLAK_PELLETS:
		var total := 0.0
		var angles: Array[float] = []
		for shot: Node in _shots():
			total += float(shot.get(&"damage"))
			var velocity: Vector2 = shot.get(&"_velocity")
			if not velocity.is_zero_approx():
				angles.append(velocity.angle())
		assert_true(
			is_equal_approx(total, FLAK_VOLLEY),
			"the four pellets carry the 22-damage volley between them (%.3f)" % total
		)
		assert_eq(angles.size(), FLAK_PELLETS, "every pellet flew")
		if angles.size() == FLAK_PELLETS:
			angles.sort()
			var span := rad_to_deg(angles[angles.size() - 1] - angles[0])
			assert_true(
				absf(span - FLAK_SPREAD_DEG) < 0.01,
				"the fan spans the 12-degree cone (%.3f)" % span
			)
	assert_eq(_state.ammo[0], 9, "one round left the pack for the whole volley")


## The proton is a cooldown-tier barrel: one missile, then the 12 s wait, one round
## a shot - the S22.8 stream law with the new row.
func test_a1_the_proton_fires_one_missile_then_cools() -> void:
	var guns := _rig([&"w_proton"])
	if guns == null:
		return
	_state.set_weapons([&"proton"])
	_state.setup()
	_state.set_ammo(0, 5)
	_rig_refit([&"w_proton"])
	var fired: Array[StringName] = []
	_guns.connect(&"shot_fired", func(id: StringName) -> void: fired.append(StringName(id)))
	_guns.call(&"select_group", 1)
	var frame := 1.0 / 60.0
	_guns.call(&"set_firing", true)
	for _frame in 5:
		_guns.call(&"tick", frame)
	assert_eq(fired.size(), 1, "the pull released exactly one missile")
	assert_eq(_state.ammo[0], 4, "one round spent")
	for _frame in 700:
		_guns.call(&"tick", frame)
	assert_eq(fired.size(), 1, "a held trigger stays silent through the cooldown")
	for _frame in 30:
		_guns.call(&"tick", frame)
	assert_eq(fired.size(), 2, "the stream repeats one missile per 12 s")


# --- A2: the three dead modules --------------------------------------------------


## 09 section 3.4: c_ewar slows enemy targeting 25 % in scan, 35 % with c_nexus -
## the player's half exposes the factor, the NPC's half scales the engaged turn.
func test_a2_ewar_slows_enemy_targeting() -> void:
	var ship := _player_rig([&"c_ewar"])
	if ship == null:
		return
	assert_true(is_equal_approx(float(ship.call(&"ewar_slow")), 0.25), "c_ewar alone slows 25 percent")
	var nexus := _player_rig([&"c_ewar", &"c_nexus"])
	if nexus == null:
		return
	assert_true(is_equal_approx(float(nexus.call(&"ewar_slow")), 0.35), "c_nexus boosts the slow to 35 percent")
	var bare := _player_rig([])
	if bare == null:
		return
	assert_true(is_equal_approx(float(bare.call(&"ewar_slow")), 0.0), "no module, no slow")
	var npc := _npc_rig(&"pirate")
	if npc == null:
		return
	var waypoint := Vector2(0.0, 1000.0)
	npc.set(&"_targeting_slow", 0.0)
	var full := float(npc.call(&"_order_turn", waypoint))
	npc.set(&"_targeting_slow", 0.25)
	var slowed := float(npc.call(&"_order_turn", waypoint))
	assert_true(
		is_equal_approx(slowed, full * 0.75),
		"the engaged turn swings at 75 percent under the EWAR slow (%.4f vs %.4f)" % [slowed, full]
	)
	assert_true(is_equal_approx(float(npc.call(&"targeting_slow")), 0.25), "and the slow reads back off the hull")


## 09 section 3.6: u_refine halves the refinery fee for its ore, the 3:1 ratio
## unchanged - the fitted hull refines one conversion at 7 CR, not 15.
func test_a2_u_refine_halves_the_refinery_fee() -> void:
	var profile := _borrow_profile()
	if profile == null:
		skip("no PlayerProfile autoload to price the fee against")
		return
	assert_eq(RefineryScript.fee_for(1), 15, "the list fee is 15 CR a conversion")
	var fit := {&"engines": [&"e_std"], &"power": &"p_std", &"utility": [&"u_refine"]}
	profile.call(&"set_fit", &"ship_vanguard", fit)
	assert_true(
		is_equal_approx(float(RefineryScript.fee_multiplier(profile)), 0.5),
		"a hull fitted with u_refine refines at half fee"
	)
	assert_eq(RefineryScript.fee_for(1, RefineryScript.fee_multiplier(profile)), 7, "one discounted conversion is 7 whole credits")
	assert_eq(RefineryScript.ORE_PER_INGOT, 3, "the 3:1 ratio is untouched")
	var mineral: StringName = MineralCatalogScript.MINERALS[0][&"id"]
	var ore: StringName = MineralCatalogScript.ore_id(mineral)
	profile.call(&"add_cargo", ore, 6)
	var before := int(profile.call(&"credits"))
	var result: Dictionary = RefineryScript.refine(profile, mineral, 2)
	assert_true(bool(result[&"ok"]), "the batch refines")
	assert_eq(int(result[&"fee"]), 15, "two discounted conversions are 15 CR, not 30 (the batch's 7.5 x 2 floors whole)")
	assert_eq(int(profile.call(&"credits")), before - 15, "the discounted fee left the balance")
	assert_eq(int(profile.call(&"cargo_qty", MineralCatalogScript.ingot_id(mineral))), 2, "and the 3:1 ratio paid the ingots")
	## An unfitted hull (or a stub without the fit accessors) pays the list.
	assert_true(is_equal_approx(float(RefineryScript.fee_multiplier(null)), 1.0), "no profile, list fee")


## 09 section 3.6: u_drones regenerates 2 hull/s in space - the flight scene's own
## frame law, gated on the fitted module.
func test_a2_u_drones_regenerate_two_hull_a_second() -> void:
	var ship := _player_rig([&"u_drones"], true)
	if ship == null:
		return
	var state: PlayerState = ship.get(&"_state")
	state.set_hull(state.hull_max - 4.0)
	var before := float(state.hull)
	ship.call(&"_physics_process", 0.5)
	assert_true(
		is_equal_approx(float(state.hull) - before, 1.0),
		"half a second of drones restored 1 hull (%.3f)" % (float(state.hull) - before)
	)
	var bare := _player_rig([], true)
	if bare == null:
		return
	var bare_state: PlayerState = bare.get(&"_state")
	bare_state.set_hull(bare_state.hull_max - 4.0)
	var bare_before := float(bare_state.hull)
	bare.call(&"_physics_process", 0.5)
	assert_true(is_equal_approx(float(bare_state.hull), bare_before), "no module, no regen")


# --- A3: the seven stock fits ----------------------------------------------------


## R-S23-3 as landed: the four rows that fit their hull's grid and power budget
## carry their stock fit, the two starter hulls keep theirs (10 section 2), the
## three power-illegal rows are staged, and every hull still launches on its own
## standard fit.
func test_a3_the_stock_fits_land_where_the_hull_law_holds() -> void:
	var miner := {
		&"engines": [&"e_std", &"e_std"], &"power": &"p_std",
		&"weapons": [&"w_mining", &"w_laser"], &"shields": [&"s_light"],
		&"armour": [&"h_plate_light"], &"computers": [&"c_scanner"],
		&"utility": [&"u_tractor", &"u_refine", &"u_cargo"],
	}
	var trader := {
		&"engines": [&"e_std", &"e_std"], &"power": &"p_std",
		&"weapons": [&"w_laser"], &"shields": [&"s_light"],
		&"armour": [&"h_plate_light"], &"computers": [&"c_scanner", &"c_target"],
		&"utility": [&"u_cargo", &"u_cargo", &"u_cargo"],
	}
	var freighter := {
		&"engines": [&"e_std", &"e_std", &"e_std"], &"power": &"p_std",
		&"weapons": [&"w_laser"], &"shields": [&"s_light"],
		&"armour": [&"h_plate_heavy", &"h_plate_heavy"],
		&"utility": [&"u_cargo", &"u_cargo", &"u_cargo", &"u_cargo"],
	}
	var patrol := {
		&"engines": [&"e_std", &"e_std"], &"power": &"p_std",
		&"weapons": [&"w_laser", &"w_laser", &"w_cannon"],
		&"shields": [&"s_light", &"s_light"], &"armour": [&"h_plate_heavy"],
		&"computers": [&"c_target", &"c_scanner"], &"boosters": [&"b_afterburner"],
		&"utility": [&"u_cargo", &"u_cargo"],
	}
	var spearhead := {
		&"engines": [&"e_std"], &"power": &"p_core",
		&"weapons": [&"w_cannon", &"w_cannon", &"w_laser", &"w_rocket"],
		&"shields": [&"s_light", &"s_heavy"],
		&"computers": [&"c_target"], &"boosters": [&"b_afterburner"],
	}
	var gunship := {
		&"engines": [&"e_std", &"e_std"], &"power": &"p_core",
		&"weapons": [&"w_cannon", &"w_cannon", &"w_cannon", &"w_rocket"],
		&"shields": [&"s_heavy", &"s_heavy"], &"armour": [&"h_composite"],
		&"computers": [&"c_target"], &"utility": [&"u_cargo"],
	}
	var destroyer := {
		&"engines": [&"e_std", &"e_std", &"e_std"], &"power": &"p_core",
		&"weapons": [&"w_railgun", &"w_cannon", &"w_cannon", &"w_plasma"],
		&"shields": [&"s_ion", &"s_heavy"],
		&"armour": [&"h_composite", &"h_plate_heavy"],
		&"computers": [&"c_nexus", &"c_target"], &"boosters": [&"b_afterburner"],
	}
	assert_eq(FitScript.standard_fit(&"ship_miner"), miner, "the Delver carries its stock fit")
	assert_eq(FitScript.standard_fit(&"ship_trader"), trader, "the Courier carries its stock fit (the one shield its S cell holds)")
	assert_eq(FitScript.standard_fit(&"ship_freighter"), freighter, "the Mule carries its stock fit")
	assert_eq(FitScript.standard_fit(&"ship_patrol"), patrol, "the Warden carries its stock fit")
	assert_eq(FitScript.standard_fit(&"ship_corvette"), spearhead, "the Spearhead carries its stock fit on p_core (the developer amendment)")
	assert_eq(FitScript.standard_fit(&"ship_gunship"), gunship, "the Bulwark carries its stock fit on p_core")
	assert_eq(FitScript.standard_fit(&"ship_destroyer"), destroyer, "the Obliterator carries its stock fit on p_core")
	for hull_id: StringName in HULL_IDS:
		var legal := FitScript.fit_legal(hull_id, FitScript.standard_fit(hull_id))
		assert_true(bool(legal[&"legal"]), "%s launches on its own standard fit" % String(hull_id))
		assert_eq(legal[&"overflow"], {}, "%s overflows nothing" % String(hull_id))


# --- A4: the seams ---------------------------------------------------------------


## V2 + R-S23-4/5: the sibelon flies the corvette column with its own sprite and
## the corvette loot table, spawning as HOSTILE_FILL's third entry; the interceptor
## and turret platform are real hull rows; the station turret stays staged (tick C6
## is open).
func test_a4_the_seams_release_and_the_hull_rows_resolve() -> void:
	var sibelon := RegistryScript.archetype(&"sibelon")
	assert_false(sibelon.is_empty(), "the sibelon row exists")
	assert_eq(StringName(sibelon[RegistryScript.KEY_HULL_ID]), &"ship_corvette", "it flies the corvette column (V2)")
	assert_eq(StringName(sibelon[RegistryScript.KEY_SPRITE_BASE]), &"ship_sibelon", "in its own sprite")
	assert_eq(StringName(sibelon[RegistryScript.KEY_LOOT_KIND]), &"corvette", "rolling the corvette loot table")
	assert_eq(StringName(sibelon[RegistryScript.KEY_SPAWN]), RegistryScript.SPAWN_SECTOR, "spawning with the sector")
	assert_eq(StringName(sibelon[RegistryScript.KEY_SEAM]), RegistryScript.SEAM_NONE, "off the slice-3 seam")
	assert_eq(RegistryScript.HOSTILE_FILL.size(), 3, "the sibelon is HOSTILE_FILL's third entry")
	assert_eq(StringName(RegistryScript.HOSTILE_FILL[2]), &"sibelon", "and the entry is its own")
	var swarmer_stats := FitScript.resolve(&"ship_corvette", {})
	assert_true(swarmer_stats != null, "the corvette column resolves the sibelon's snapshot")
	var interceptor := FitScript.resolve(&"ship_interceptor", {})
	assert_true(interceptor != null, "ship_interceptor is a real hull row (R-S23-4)")
	if interceptor != null:
		assert_true(is_equal_approx(interceptor.hull_max, 650.0), "hull 650")
		assert_true(is_equal_approx(interceptor.shield_max, 350.0), "shield 350")
		assert_true(is_equal_approx(interceptor.max_speed, 585.0), "130 percent of the Fighter's 450")
	var turret := FitScript.resolve(&"ship_turret_platform", {})
	assert_true(turret != null, "ship_turret_platform is a real hull row (R-S23-5)")
	if turret != null:
		assert_true(is_equal_approx(turret.hull_max, 2000.0), "hull 2 000")
		assert_true(is_equal_approx(turret.shield_max, 800.0), "shield 800")
		assert_true(is_equal_approx(turret.max_speed, 0.0), "speed 0: a fixed emplacement")
	assert_true(
		ResourceLoader.exists("res://assets/ships/ship_interceptor_side.png")
		and ResourceLoader.exists("res://assets/ships/ship_turret_platform.png")
		and ResourceLoader.exists("res://assets/ships/ship_sibelon_side.png"),
		"and every new hull's art ships"
	)
	## The hunter's map names the interceptor as a hull the wing answers for, and the
	## class row it names now exists.
	assert_true(FitScript.HULLS.has(&"ship_interceptor"), "the hunter map's interceptor ref resolves")
	## Rule 5: the station turret is staged while tick C6 is open - the row stays
	## exactly as shipped (station-mounted, static, on-attack).
	var turret_row := RegistryScript.archetype(&"turret")
	assert_eq(StringName(turret_row[RegistryScript.KEY_SPAWN]), RegistryScript.SPAWN_STATION, "the turret stays station-mounted (STAGED, tick C6 open)")
	assert_true(bool(turret_row[RegistryScript.KEY_STATIC]), "and static")


# --- A5: per-hull identity -------------------------------------------------------


## L137 closed: each hull draws its own side view at its own V3 ladder scale with
## its own collider radius, and the FX anchors scale off the drawn hull's sprite.
func test_a5_each_hull_draws_its_own_sprite_and_radius() -> void:
	var ship := _player_rig([], false, &"ship_miner")
	if ship == null:
		return
	var sprite := ship.get_node_or_null(NodePath("Hull")) as Sprite2D
	assert_true(sprite != null, "the Hull sprite exists")
	if sprite != null:
		assert_true(
			String(sprite.texture.resource_path).ends_with("ship_miner_side.png"),
			"the Delver draws its own side view"
		)
		assert_true(
			is_equal_approx(sprite.scale.x, 0.06821),
			"at the V3 ladder's scale (62 u over 909 px)"
		)
	var shape := ship.get_node_or_null(NodePath("HullBody/Shape")) as CollisionShape2D
	assert_true(shape != null, "the hull body carries a shape")
	if shape != null:
		assert_true(
			is_equal_approx((shape.shape as CircleShape2D).radius, 31.0),
			"the collider is half the 62 u ladder length"
		)
	assert_true(
		is_equal_approx((ship.call(&"_hull_sprite_scale") as Vector2).x, 0.06821),
		"the FX anchors scale off the drawn hull's sprite"
	)
	## The Vanguard stays frozen at its shipped scale and radius.
	ship.call(&"set_hull_id", &"ship_vanguard")
	if sprite != null:
		assert_true(
			is_equal_approx(sprite.scale.x, 0.0663),
			"the Vanguard keeps its shipped 0.0663 scale"
		)
	if shape != null:
		assert_true(
			is_equal_approx((shape.shape as CircleShape2D).radius, 30.0),
			"and its shipped 30 u radius"
		)
	## The ladder itself: every row's radius is half its length.
	for hull_id: StringName in HULL_IDS:
		var row := FitScript.side_view(hull_id)
		assert_false(row.is_empty(), "%s carries a side-view row" % String(hull_id))
		assert_true(
			is_equal_approx(float(row[&"radius"]), float(row[&"length"]) * 0.5),
			"%s: radius = half the length" % String(hull_id)
		)


## The faction sheets dress the hunters and the pirates, and a hurt Vanguard shows
## its damaged side in LAUNCH (the same swap REPAIRS already ships).
func test_a5_the_liveries_and_the_damaged_vanguard_resolve() -> void:
	var pirate := RegistryScript.archetype(&"pirate")
	var path := RegistryScript.sprite_path(pirate, &"choir")
	assert_true(
		String(path).ends_with("ship_fighter_choir_side.png"),
		"a pirate in Choir space wears the Choir sheet (%s)" % path
	)
	path = RegistryScript.sprite_path(pirate, &"meridian")
	assert_true(
		String(path).ends_with("ship_fighter_meridian_side.png"),
		"and the Meridian sheet in Meridian space"
	)
	path = RegistryScript.sprite_path(pirate, &"")
	assert_true(
		String(path).ends_with("ship_fighter_side.png"),
		"nobody's space keeps the plain hull"
	)
	var hunter := RegistryScript.archetype(&"hunter")
	path = RegistryScript.sprite_path(hunter, &"concord")
	assert_true(
		String(path).ends_with("ship_fighter_concord_side.png"),
		"the hunter wears the space owner's sheet"
	)
	var damaged := LaunchPanelScript.damaged_preview(&"ship_vanguard")
	assert_true(
		String(damaged).ends_with("ship_vanguard_damaged_side.png"),
		"LAUNCH resolves the damaged Vanguard sheet (%s)" % damaged
	)
	assert_true(ResourceLoader.exists(damaged), "and the sheet ships")
	assert_true(
		LaunchPanelScript.damaged_preview(&"ship_fighter").is_empty(),
		"a hull without a damaged sheet keeps its catalogue render"
	)


# --- A6: the loot rows -----------------------------------------------------------


## The countermeasures are catalogued (uncatalogued_items is empty), the hunter
## rolls its own promoted table once, and the caches scale by the sector tier.
func test_a6_the_loot_rows_land() -> void:
	assert_eq(LootScript.uncatalogued_items(), [] as Array[StringName], "the tables roll only catalogued items")
	var chaff := Components.component(&"cm_chaff")
	var flare := Components.component(&"cm_flare")
	assert_false(chaff.is_empty(), "cm_chaff has a catalogue row")
	assert_false(flare.is_empty(), "cm_flare has a catalogue row")
	assert_eq(int(chaff[&"grade"]), 1, "both are Grade I (the fighter band they drop in)")
	assert_eq(int(chaff[&"value"]), 0, "and 06 section 3.1's re-checked haul prices them at 0 CR")
	assert_true(LootScript.has(&"hunter"), "the hunter kind is a table now")
	assert_eq(
		LootScript.HUNTER_LINES.size(),
		LootScript.FIGHTER_LINES.size() + LootScript.HUNTER_EXTRA.size(),
		"the promoted table is the fighter lines plus the extra"
	)
	## One roll, no double roll: the wiring's kind is the promoted table, and the
	## roll-time grade cap keeps a fighter-band hunter on comp_elec_1 only.
	var payload := LootScript.roll_band(&"hunter", 20060210)
	var elec_twos := 0
	for entry: Dictionary in payload:
		if StringName(entry[LootScript.KEY_ITEM]) == &"comp_elec_2":
			elec_twos += 1
	assert_eq(elec_twos, 0, "a band-1 roll pays no grade above its band")
	var saw_extra := false
	for seed_value in 40:
		for entry: Dictionary in LootScript.roll_band(&"hunter", 91000 + seed_value):
			if StringName(entry[LootScript.KEY_ITEM]) == &"comp_elec_1" and int(entry[LootScript.KEY_AMOUNT]) > 1:
				saw_extra = true
	assert_true(saw_extra, "the promoted extra's 1..2 line rolls beside the band's own")
	assert_eq(RegistryScript.archetype(&"hunter")[RegistryScript.KEY_LOOT_KIND], &"hunter", "the hunter row names the promoted table")
	## 06 section 7's cache scaling, with the registry's tier-mix ladder.
	assert_true(is_equal_approx(LootScript.cache_scale(1), 1.0), "T1 pays x1")
	assert_true(is_equal_approx(LootScript.cache_scale(2), 1.0), "T2 pays x1")
	assert_true(is_equal_approx(LootScript.cache_scale(3), 1.5), "T3 pays x1.5")
	assert_true(is_equal_approx(LootScript.cache_scale(4), 2.0), "T4 pays x2")
	assert_eq(SectorRegistryScript.sector_tier(&"sector_1"), 1, "S1's mix tops at grade 1")
	assert_eq(SectorRegistryScript.sector_tier(&"sector_3"), 2, "S3's at grade 2")
	assert_eq(SectorRegistryScript.sector_tier(&"sector_4"), 3, "S4's at grade 3")
	assert_eq(SectorRegistryScript.sector_tier(&"sector_6"), 4, "S6's at grade 4")
	assert_eq(SectorRegistryScript.sector_tier(&"sector_7"), 4, "S7's at grade 4")
	var scaled := LootScript.roll_band(&"corvette", 20060210, 2.0)
	for entry: Dictionary in scaled:
		if bool(entry[LootScript.KEY_CACHE]):
			assert_true(
				int(entry[LootScript.KEY_AMOUNT]) >= 240 and int(entry[LootScript.KEY_AMOUNT]) <= 500,
				"the cache range doubled with the tier (%d)" % int(entry[LootScript.KEY_AMOUNT])
			)


# --- A7: the tick state ----------------------------------------------------------


## The wave shipped the PROPOSED values (every tick open): the two families' rows,
## the fits that fit, the hull rows, the seam release - and the two staged pieces
## name their bucket-2 remedy.
func test_a7_the_proposed_values_ship_with_their_reversals() -> void:
	assert_eq(WeaponScript.interval_of(&"proton"), PROTON_COOLDOWN, "C1: the proton row as written, read through V5")
	assert_eq(WeaponScript.interval_of(&"flak"), FLAK_INTERVAL, "C2: the flak row as written")
	assert_true(FitScript.HULLS.has(&"ship_interceptor"), "C4: the interceptor row as written")
	assert_true(FitScript.HULLS.has(&"ship_turret_platform"), "C5: the turret platform row as written")
	assert_eq(RegistryScript.archetype(&"turret")[RegistryScript.KEY_SPAWN], RegistryScript.SPAWN_STATION, "C6 open: the station turret stays staged")
	assert_true(FitScript.standard_fit(&"ship_corvette").get(&"power", &"") == &"p_core", "C3: the three power-illegal rows carry the developer's p_core amendment")
	assert_true(ModuleScript.EXCLUSIVES.has(&"w_proton") and ModuleScript.EXCLUSIVES.has(&"w_flak"), "15 section 5 untouched")


# --- fixtures --------------------------------------------------------------------


func _rig(ids: Array, racks: Array = []) -> Node2D:
	var host := _host()
	if host == null:
		skip("no PlayerProfile autoload to host the rig")
		return null
	var holder := Node2D.new()
	holder.name = &"S23ContentRig"
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


## The rig's fit changed after `set_weapons` reseeded the slots, so the cells are
## written again in the state's own order.
func _rig_refit(ids: Array) -> void:
	if _guns == null:
		return
	var fit: Array[StringName] = []
	for id: Variant in ids:
		fit.append(StringName(id))
	_guns.call(&"set_fitted", fit)


func _player_rig(fit_ids: Array, physical := false, hull: StringName = &"ship_vanguard") -> Node2D:
	var host := _host()
	if host == null:
		skip("no PlayerProfile autoload to host the hull")
		return null
	var ship: Node2D = PlayerShipScene.instantiate()
	if ship == null:
		assert_true(false, "player_ship.tscn instantiates")
		return null
	host.add_child(ship)
	_staged.append(ship)
	var stats: ShipStats = FitScript.resolve(hull, {})
	var state := PlayerStateScript.new()
	state.setup()
	ship.call(&"set_hull_id", hull)
	var fit: Array[StringName] = []
	for id: Variant in fit_ids:
		fit.append(StringName(id))
	ship.call(&"setup", stats, state, fit)
	return ship


func _npc_rig(archetype: StringName) -> Node2D:
	var host := _host()
	if host == null:
		skip("no PlayerProfile autoload to host the hull")
		return null
	var stats: ShipStats = FitScript.resolve(&"ship_fighter", {})
	var npc: Node2D = NpcShipScript.new()
	host.add_child(npc)
	_staged.append(npc)
	npc.call(&"setup", archetype, stats, &"ship_fighter", {})
	return npc


func _host() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(NodePath(PROFILE_SERVICE))


## Borrows the autoload for the refinery probe, snapshotting the two fields the
## probe writes so teardown puts the account back.
func _borrow_profile() -> Node:
	var profile := _host()
	if profile == null:
		return null
	_profile_snapshot = {
		&"active": profile.get(&"_active_ship"),
		&"fits": (profile.get(&"_fits") as Dictionary).duplicate(true),
		&"cargo": (profile.get(&"_cargo") as Dictionary).duplicate(true),
		&"credits": profile.get(&"_credits"),
	}
	profile.set(&"_active_ship", &"ship_vanguard")
	return profile


func _restore_profile() -> void:
	if _profile_snapshot.is_empty():
		return
	var profile := _host()
	if profile != null:
		profile.set(&"_active_ship", _profile_snapshot[&"active"])
		profile.set(&"_fits", _profile_snapshot[&"fits"])
		profile.set(&"_cargo", _profile_snapshot[&"cargo"])
		profile.call(&"add_credits", int(_profile_snapshot[&"credits"]) - int(profile.call(&"credits")))
	_profile_snapshot = {}


func _shots() -> Array[Node]:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return []
	return tree.get_nodes_in_group(&"projectile")


func _clear_shots() -> void:
	for shot: Node in _shots():
		if is_instance_valid(shot):
			shot.free()
