extends SceneTree
## W6 review probe for engine slice 2 (fight). Independent re-measurement, written by
## the reviewer: every check encodes the ENGINE_SPEC section 13 / gameplay-doc figure it
## is testing, so a failure prints both the measured value and the spec row it misses.
##
## Run (bounded, stdout to a log):
##   "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path
##   "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --script res://tools/_probe_w6_slice2.gd
##   --quit-after 4000
##
## Sections:
##   A  the shipped constant tables against section 13 / docs 06 / 09 / 13
##   B  a real laser on a real hull (the wave's HIGH claim) + the range cap + DPS
##   C  projectile travel: bolt and slug speeds, rocket homing and destructibility, mine
##   D  the energy draw gate: a short pool dry-fires and deals nothing
##   E  shield-first absorb, the 4 s regen quiet window and the ctx round trip
##   F  the brain state walk, the alien swarmer, flee/leash/AGGRO_COOLDOWN
##   G  loot weight sums (06 section 3 + the 2026-09-20 countermeasure rows)
##   H  the sector NPC counts against the section 13 / doc 13 section 4 shape
##   I  the HUD's lock ring, radial speedometer, pools and target payload

const Registry := preload("res://game/sector_registry.gd")
const NpcRegistryScript := preload("res://game/npc_registry.gd")
const NpcShipScript := preload("res://game/npc_ship.gd")
const NpcBrainScript := preload("res://game/npc_brain.gd")
const WeaponsScript := preload("res://game/weapons.gd")
const LootScript := preload("res://game/loot_tables.gd")
const DamageScript := preload("res://game/damage.gd")
const ImpactScript := preload("res://game/impact.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const PlayerShipScript := preload("res://game/player_ship.gd")
const PlayerShipScene := preload("res://game/player_ship.tscn")
const ShipFitScript := preload("res://game/ship_fit.gd")
const AsteroidScript := preload("res://game/asteroid.gd")

## Loaded lazily: `hud.gd` reads the `SettingsManager` autoload, and an autoload's global
## identifier is only registered once the SceneTree is up, so a `preload` of the HUD at
## probe-parse time fails to compile the script (the CONTRACTS section 9 trap).
const HUD_SCENE_PATH := "res://ui/hud/hud.tscn"

const HULL: StringName = &"ship_vanguard"
const TICKS_PER_SECOND := 60

var _ok := 0
var _fail := 0
var _world: Node2D = null
var _physics_delta := 1.0 / 60.0


func _init() -> void:
	print("=== W6 slice-2 review probe ===")
	_world = Node2D.new()
	_world.name = &"W6ProbeWorld"
	get_root().add_child(_world)
	_section_a_constants()
	await _section_b_live_laser()
	await _section_c_projectiles()
	await _section_d_energy_gate()
	_section_e_absorb_regen_ctx()
	_section_f_brain()
	_section_g_loot()
	_section_h_sector_counts()
	await _section_i_hud()
	await _section_j_countermeasures()
	print("[SUMMARY] ok=%d failed=%d" % [_ok, _fail])
	quit(1 if _fail > 0 else 0)


func _init_physics_delta() -> void:
	_physics_delta = 1.0 / maxf(float(Engine.physics_ticks_per_second), 1.0)


func _check(label: String, passed: bool, detail: String = "") -> void:
	if passed:
		_ok += 1
		print("[PASS] %s | %s" % [label, detail])
	else:
		_fail += 1
		print("[FAIL] %s | %s" % [label, detail])


func _near(measured: float, expected: float, tol: float) -> bool:
	return absf(measured - expected) <= tol


func _ticks(count: int) -> void:
	for _i in count:
		await physics_frame


## --- A. The shipped tables against the spec rows -----------------------------------


func _section_a_constants() -> void:
	print("-- A. constant tables vs section 13 / docs 06, 09, 13 --")
	## Section 13 combat: ranges laser 500 / plasma 450 / cannon 600 / railgun 800 /
	## rocket 900 (lock 900); rocket 180 alpha, 1.2 s interval, 2.2 rad/s, 900 u/s;
	## mine arm 2 s, trigger 60 u.
	var ranges := {
		&"laser": 500.0, &"plasma": 450.0, &"cannon": 600.0,
		&"railgun": 800.0, &"rocket": 900.0,
	}
	for id: StringName in ranges:
		var got := WeaponsScript.range_of(id)
		_check("range %s" % id, _near(got, ranges[id], 0.01), "got %s want %s" % [got, ranges[id]])
	var dps := {&"laser": 30.0, &"plasma": 70.0, &"cannon": 45.0, &"railgun": 60.0}
	for id: StringName in dps:
		var got := WeaponsScript.dps_of(id)
		_check("dps %s" % id, _near(got, dps[id], 0.01), "got %s want %s" % [got, dps[id]])
	_check(
		"cannon bolt 1000 u/s",
		_near(float(WeaponsScript.row_of(&"cannon").get(&"speed", 0.0)), 1000.0, 0.01),
		"got %s" % WeaponsScript.row_of(&"cannon").get(&"speed", 0.0)
	)
	_check(
		"railgun slug 1400 u/s",
		_near(float(WeaponsScript.row_of(&"railgun").get(&"speed", 0.0)), 1400.0, 0.01),
		"got %s" % WeaponsScript.row_of(&"railgun").get(&"speed", 0.0)
	)
	_check(
		"cannon burst 0.35 on / 0.25 off",
		_near(float(WeaponsScript.row_of(&"cannon").get(&"burst_on", 0.0)), 0.35, 0.001)
			and _near(float(WeaponsScript.row_of(&"cannon").get(&"burst_off", 0.0)), 0.25, 0.001),
		"on=%s off=%s" % [
			WeaponsScript.row_of(&"cannon").get(&"burst_on", 0.0),
			WeaponsScript.row_of(&"cannon").get(&"burst_off", 0.0),
		]
	)
	_check(
		"rocket 180 alpha / 2.2 rad/s / 1.2 s interval",
		_near(float(WeaponsScript.row_of(&"rocket").get(&"alpha", 0.0)), 180.0, 0.01)
			and _near(float(WeaponsScript.row_of(&"rocket").get(&"turn_rate", 0.0)), 2.2, 0.001)
			and _near(float(WeaponsScript.row_of(&"rocket").get(&"interval", 0.0)), 1.2, 0.001),
		"alpha=%s turn=%s interval=%s" % [
			WeaponsScript.row_of(&"rocket").get(&"alpha", 0.0),
			WeaponsScript.row_of(&"rocket").get(&"turn_rate", 0.0),
			WeaponsScript.row_of(&"rocket").get(&"interval", 0.0),
		]
	)
	_check(
		"mine arm 2 s / trigger 60 u",
		_near(float(WeaponsScript.row_of(&"mine").get(&"arm", 0.0)), 2.0, 0.001)
			and _near(float(WeaponsScript.row_of(&"mine").get(&"trigger", 0.0)), 60.0, 0.001),
		"arm=%s trigger=%s" % [
			WeaponsScript.row_of(&"mine").get(&"arm", 0.0),
			WeaponsScript.row_of(&"mine").get(&"trigger", 0.0),
		]
	)
	## Section 13 "Weapon draw": laser 6 E/s, plasma 10 E/s, kinetics 0.
	var draws := {&"laser": 6.0, &"plasma": 10.0}
	for id: StringName in draws:
		var got := float(WeaponsScript.row_of(id).get(&"draw", 0.0))
		_check("draw %s" % id, _near(got, draws[id], 0.001), "got %s want %s" % [got, draws[id]])
	for id: StringName in [&"cannon", &"railgun", &"rocket", &"mine"]:
		var got := float(WeaponsScript.row_of(id).get(&"draw", 0.0))
		_check("kinetics spend no Energy (%s)" % id, _near(got, 0.0, 0.0001), "draw %s" % got)
	_check(
		"plasma hull bonus +25 %",
		_near(float(WeaponsScript.row_of(&"plasma").get(&"hull_bonus", 1.0)), 1.25, 0.0001),
		"got %s" % WeaponsScript.row_of(&"plasma").get(&"hull_bonus", 1.0)
	)
	_check(
		"shield rules: laser/plasma shields-first, kinetics/rocket/mine bypass",
		not bool(WeaponsScript.row_of(&"laser").get(&"bypass_shield", true))
			and not bool(WeaponsScript.row_of(&"plasma").get(&"bypass_shield", true))
			and bool(WeaponsScript.row_of(&"cannon").get(&"bypass_shield", false))
			and bool(WeaponsScript.row_of(&"railgun").get(&"bypass_shield", false))
			and bool(WeaponsScript.row_of(&"rocket").get(&"bypass_shield", false))
			and bool(WeaponsScript.row_of(&"mine").get(&"bypass_shield", false)),
		"laser=%s cannon=%s rocket=%s" % [
			WeaponsScript.row_of(&"laser").get(&"bypass_shield"),
			WeaponsScript.row_of(&"cannon").get(&"bypass_shield"),
			WeaponsScript.row_of(&"rocket").get(&"bypass_shield"),
		]
	)
	## Section 4.6 / section 13 "Lock & countermeasures".
	_check(
		"CHAFF_WINDOW 3.0 s / 3 ghosts",
		_near(WeaponsScript.CHAFF_WINDOW, 3.0, 0.001) and WeaponsScript.CHAFF_GHOSTS == 3,
		"window=%s ghosts=%s" % [WeaponsScript.CHAFF_WINDOW, WeaponsScript.CHAFF_GHOSTS]
	)
	_check(
		"FLARE_LURE 450 u",
		_near(WeaponsScript.FLARE_LURE, 450.0, 0.001),
		"got %s" % WeaponsScript.FLARE_LURE
	)
	## Section 4.2 item 2 / section 13 "Shield regen": resumes 4 s after the last hit.
	_check(
		"Damage.REGEN_QUIET 4.0 s",
		_near(DamageScript.REGEN_QUIET, 4.0, 0.001),
		"got %s" % DamageScript.REGEN_QUIET
	)
	## 09 section 3.2 / section 4.2 item 2: base 2/s, s_light +4, s_heavy +5, s_ion +9.
	var fit_shield := ShipFitScript.resolve(HULL, ShipFitScript.STANDARD_FIT)
	_check(
		"standard fit shield_regen = base 2 + s_light 4",
		_near(fit_shield.shield_regen, 6.0, 0.001),
		"resolved %s" % fit_shield.shield_regen
	)
	_check(
		"PlayerState base shield_regen 2/s",
		_near(PlayerStateScript.SHIELD_REGEN_DEFAULT, 2.0, 0.001),
		"got %s" % PlayerStateScript.SHIELD_REGEN_DEFAULT
	)
	## Section 13 "Aggro radii": pirate 900, patrol scan 1000, turret 750, leash 2500,
	## AGGRO_COOLDOWN 5 s, flee at 30 % hull.
	var pirate := NpcRegistryScript.archetype(&"pirate")
	var swarmer := NpcRegistryScript.archetype(&"swarmer")
	var patrol := NpcRegistryScript.archetype(&"patrol")
	var turret := NpcRegistryScript.archetype(&"turret")
	_check(
		"pirate aggro 900 / flee 0.30",
		_near(float(pirate[NpcRegistryScript.KEY_AGGRO_RADIUS]), 900.0, 0.01)
			and _near(float(pirate[NpcRegistryScript.KEY_FLEE_HULL]), 0.30, 0.0001),
		"aggro=%s flee=%s" % [
			pirate[NpcRegistryScript.KEY_AGGRO_RADIUS], pirate[NpcRegistryScript.KEY_FLEE_HULL],
		]
	)
	_check(
		"swarmer mirrors the pirate row (aggro 900 / flee 0.30 / hostile)",
		_near(float(swarmer[NpcRegistryScript.KEY_AGGRO_RADIUS]), 900.0, 0.01)
			and _near(float(swarmer[NpcRegistryScript.KEY_FLEE_HULL]), 0.30, 0.0001)
			and StringName(swarmer[NpcRegistryScript.KEY_HOSTILITY])
				== NpcRegistryScript.HOSTILITY_EVERYTHING,
		"aggro=%s hostility=%s" % [
			swarmer[NpcRegistryScript.KEY_AGGRO_RADIUS], swarmer[NpcRegistryScript.KEY_HOSTILITY],
		]
	)
	_check(
		"patrol scan 1000",
		_near(float(patrol[NpcRegistryScript.KEY_SCAN_RADIUS]), 1000.0, 0.01),
		"got %s" % patrol[NpcRegistryScript.KEY_SCAN_RADIUS]
	)
	_check(
		"turret aggro 750",
		_near(float(turret[NpcRegistryScript.KEY_AGGRO_RADIUS]), 750.0, 0.01),
		"got %s" % turret[NpcRegistryScript.KEY_AGGRO_RADIUS]
	)
	_check(
		"LEASH_RADIUS 2500 / AGGRO_COOLDOWN 5.0",
		_near(NpcBrainScript.LEASH_RADIUS, 2500.0, 0.01)
			and _near(NpcBrainScript.AGGRO_COOLDOWN, 5.0, 0.001),
		"leash=%s cooldown=%s" % [NpcBrainScript.LEASH_RADIUS, NpcBrainScript.AGGRO_COOLDOWN]
	)
	## Doc 13 section 2/4's heat gains.
	_check(
		"heat on kill: pirate -3 / trader +15 / patrol +25 / turret +25",
		int(pirate[NpcRegistryScript.KEY_HEAT_ON_KILL]) == -3
			and int(NpcRegistryScript.archetype(&"trader")[NpcRegistryScript.KEY_HEAT_ON_KILL]) == 15
			and int(patrol[NpcRegistryScript.KEY_HEAT_ON_KILL]) == 25
			and int(turret[NpcRegistryScript.KEY_HEAT_ON_KILL]) == 25,
		"pirate=%s trader=%s patrol=%s turret=%s" % [
			pirate[NpcRegistryScript.KEY_HEAT_ON_KILL],
			NpcRegistryScript.archetype(&"trader")[NpcRegistryScript.KEY_HEAT_ON_KILL],
			patrol[NpcRegistryScript.KEY_HEAT_ON_KILL],
			turret[NpcRegistryScript.KEY_HEAT_ON_KILL],
		]
	)
	## Doc 13 section 3's tier thresholds. The registry is their single owner.
	_check(
		"heat tiers clean 0 / suspect 20 / wanted 50 / outlaw 80",
		NpcRegistryScript.heat_tier(0) == &"clean"
			and NpcRegistryScript.heat_tier(20) == &"suspect"
			and NpcRegistryScript.heat_tier(49) == &"suspect"
			and NpcRegistryScript.heat_tier(50) == &"wanted"
			and NpcRegistryScript.heat_tier(79) == &"wanted"
			and NpcRegistryScript.heat_tier(80) == &"outlaw",
		"20=%s 50=%s 80=%s" % [
			NpcRegistryScript.heat_tier(20),
			NpcRegistryScript.heat_tier(50),
			NpcRegistryScript.heat_tier(80),
		]
	)
	## Section 4.2 items 6-8's constants (slice 0's owner, unchanged by this wave).
	_check(
		"Impact constants: 2.0e-5 / 40 / 0.40 / 4000 / 0.2",
		_near(ImpactScript.COLLISION_FACTOR, 2.0e-5, 1e-12)
			and _near(ImpactScript.COLLISION_MIN_DV, 40.0, 0.001)
			and _near(ImpactScript.KNOCKBACK_FRACTION, 0.40, 0.0001)
			and _near(ImpactScript.EXPLOSION_P0, 4000.0, 0.001)
			and _near(ImpactScript.EXPLOSION_WINDOW, 0.2, 0.0001),
		"factor=%s dv=%s frac=%s p0=%s window=%s" % [
			ImpactScript.COLLISION_FACTOR, ImpactScript.COLLISION_MIN_DV,
			ImpactScript.KNOCKBACK_FRACTION, ImpactScript.EXPLOSION_P0,
			ImpactScript.EXPLOSION_WINDOW,
		]
	)
	## Loot bands and the two countermeasure rows (06 section 3, section 4.6).
	var fighter := LootScript.TABLES[&"fighter"][&"lines"] as Array
	_check(
		"06 fighter table has 6 lines with cm_chaff/cm_flare at 0.15",
		fighter.size() == 6
			and StringName(fighter[4][&"item"]) == &"cm_chaff"
			and _near(float(fighter[4][&"chance"]), 0.15, 0.0001)
			and StringName(fighter[5][&"item"]) == &"cm_flare"
			and _near(float(fighter[5][&"chance"]), 0.15, 0.0001),
		"lines=%d last=%s/%s" % [fighter.size(), fighter[4][&"item"], fighter[5][&"item"]]
	)
	_check(
		"the other three 06 tables carry no countermeasure row",
		not _has_item(LootScript.FREIGHTER_LINES, &"cm_chaff")
			and not _has_item(LootScript.CORVETTE_LINES, &"cm_flare")
			and not _has_item(LootScript.MAW_LINES, &"cm_chaff"),
		"freighter/corvette/maw clean"
	)


func _has_item(lines: Array, item: StringName) -> bool:
	for line: Dictionary in lines:
		if StringName(line[&"item"]) == item:
			return true
	return false


## --- B. A real laser on a real hull, and the range cap -----------------------------


func _make_ship(at: Vector2) -> Array:
	var stats := ShipFitScript.resolve(HULL, ShipFitScript.STANDARD_FIT)
	var state := PlayerStateScript.new()
	state.hull_max = stats.hull_max
	state.shield_max = stats.shield_max
	state.cargo_max = stats.cargo_max
	state.energy_max = stats.energy_max
	state.energy_regen = stats.energy_regen
	state.fuel_max = stats.fuel_max
	state.shield_regen = stats.shield_regen
	state.setup()
	var ship := PlayerShipScene.instantiate() as PlayerShipScript
	_world.add_child(ship)
	ship.global_position = at
	ship.setup(stats, state, ShipFitScript.fitted_ids(ShipFitScript.STANDARD_FIT))
	return [ship, state, stats]


func _section_b_live_laser() -> void:
	print("-- B. a real laser on a real hull, and the range cap --")
	_init_physics_delta()
	var shooter_pair := _make_ship(Vector2.ZERO)
	var shooter: Node2D = shooter_pair[0]
	var shooter_state: PlayerStateScript = shooter_pair[1]
	var victim_pair := _make_ship(Vector2(300.0, 0.0))
	var victim: Node2D = victim_pair[0]
	var victim_state: PlayerStateScript = victim_pair[1]
	await _ticks(3)
	var guns: Node2D = shooter.get_node_or_null(NodePath(PlayerShipScript.WEAPONS_NODE))
	_check(
		"PlayerShip mounts the WeaponComponent for the standard fit",
		guns != null,
		"node %s" % [guns]
	)
	if guns == null:
		return
	_check(
		"weapon groups: the standard fit's w_laser selects as laser",
		guns.call(&"selected_weapon") == &"laser",
		"selected=%s fitted=%s" % [guns.call(&"selected_weapon"), guns.call(&"fitted")]
	)
	_check(
		"the victim's HullBody is the shot's collider (layer 2, shaped)",
		_hull_body_shape(victim) != null,
		"body=%s shape=%s" % [_hull_body(victim), _hull_body_shape(victim)]
	)
	_check(
		"the victim's HullBody answers no damage method (the delivery question)",
		not _answers_damage(_hull_body(victim)),
		"body methods: take_damage=%s damage=%s" % [
			_hull_body(victim).has_method(&"take_damage"),
			_hull_body(victim).has_method(&"damage"),
		]
	)
	## 1 s of held laser fire at 300 u (inside the 500 u range).
	var shield_before: float = victim_state.shield
	guns.call(&"set_aim_point", victim.global_position)
	guns.call(&"set_firing", true)
	await _ticks(TICKS_PER_SECOND)
	guns.call(&"set_firing", false)
	var shield_after: float = victim_state.shield
	print(
		"   [measure] 1 s laser at 300 u: victim shield %s -> %s, shooter energy %s -> %s"
		% [shield_before, shield_after, shooter_state.energy_max, shooter_state.energy]
	)
	_check(
		"the shooter spent Energy for the beam (section 4.4)",
		shooter_state.energy < shooter_state.energy_max - 1.0,
		"energy %s -> %s" % [shooter_state.energy_max, shooter_state.energy]
	)
	_check(
		"HIGH/delivery: a laser hit on a real hull charges its shield",
		shield_after < shield_before - 1.0,
		"shield %s -> %s (unchanged means the hit reached the hull's body, not the hull)"
		% [shield_before, shield_after]
	)
	## The control: the same charge through the hull node's own sink.
	var control_before: float = victim_state.shield
	DamageScript.apply(victim, 120.0, false, {})
	var control_after: float = victim_state.shield
	print("   [measure] Damage.apply(ship node, 120) -> shield %s" % control_after)
	_check(
		"control: Damage.apply reaches the ship node and moves the shield",
		control_after < control_before - 1.0,
		"shield %s -> %s" % [control_before, control_after]
	)
	## Section 4.1's range cap and section 6's 10 % chip rate, measured on the family of
	## target the shipped delivery *does* reach: a rock. `Asteroid.apply_work` converts
	## accumulated work into whole ore units, so the chip is measured as the rock's yield
	## that went in (a residual `work` always settles below 1.0), and the extraction
	## monopoly is measured as the pickup count (ruling 17: a chip depletes or cracks;
	## the mining laser keeps the extraction).
	var near_rock := _make_rock(Vector2(0.0, 300.0))
	var far_rock := _make_rock(Vector2(0.0, 620.0))
	await _ticks(3)
	print(
		"   [measure] rocks at %s (radius %s) and %s (radius %s)"
		% [
			near_rock.global_position, near_rock.call(&"world_radius"),
			far_rock.global_position, far_rock.call(&"world_radius"),
		]
	)
	_check(
		"the rock fixture carries a collision circle on the rock layer",
		float(near_rock.call(&"world_radius")) > 0.0 and _rock_shape(near_rock) != null,
		"radius %s shape %s" % [near_rock.call(&"world_radius"), _rock_shape(near_rock)]
	)
	print(
		"   [diag] shooter at %s, victim node at %s, victim body at %s, component at %s"
		% [
			shooter.global_position, victim.global_position,
			_hull_body(victim).global_position if _hull_body(victim) != null else "n/a",
			guns.global_position,
		]
	)
	var diag_query := PhysicsRayQueryParameters2D.create(
		guns.global_position, near_rock.global_position, 3, []
	)
	var diag_hit: Dictionary = _world.get_world_2d().direct_space_state.intersect_ray(diag_query)
	var diag_target: Dictionary = guns.call(
		&"_beam_target", guns.global_position, near_rock.global_position
	)
	print(
		"   [diag] the ray to the rock finds %s at %s; the component's own _beam_target finds %s"
		% [
			diag_hit.get(&"collider", null), diag_hit.get(&"position", Vector2.ZERO),
			diag_target.get(&"collider", null),
		]
	)
	var rock_yield_before: int = int(near_rock.get(&"yield_units"))
	var pickups_before := _pickup_count()
	guns.call(&"set_aim_point", near_rock.global_position)
	guns.call(&"set_firing", true)
	await _ticks(TICKS_PER_SECOND)
	guns.call(&"set_firing", false)
	var chipped: int = rock_yield_before - int(near_rock.get(&"yield_units"))
	print("   [measure] 1 s of laser on a rock at 300 u drained %s ore units" % chipped)
	_check(
		"guns chip a rock at the 10 % rate (30 dps x 10 % = 3 work/s, section 6 / ruling 17)",
		_near(float(chipped), 3.0, 0.6),
		"drained %s units (expected ~3)" % chipped
	)
	_check(
		"a gun chip extracts no ore (ruling 17: no pickup is spawned)",
		_pickup_count() == pickups_before,
		"pickups %s -> %s" % [pickups_before, _pickup_count()]
	)
	## The same second driven synchronously through the component's own tick, so the
	## trigger path and the frame path cannot disagree.
	var tick_before: int = int(near_rock.get(&"yield_units"))
	guns.call(&"set_firing", true)
	for _i in TICKS_PER_SECOND:
		guns.call(&"tick", 1.0 / 60.0)
	var ticked: int = tick_before - int(near_rock.get(&"yield_units"))
	print("   [measure] 60 synchronous ticks drained %s ore units" % ticked)
	_check(
		"the same chip measured through 60 synchronous ticks",
		_near(float(ticked), 3.0, 0.6),
		"drained %s units (expected ~3)" % ticked
	)
	guns.call(&"set_firing", false)
	## The range cap: the same beam aimed 620 u out (past the 500 u cap) reaches nothing.
	var far_before: int = int(far_rock.get(&"yield_units"))
	guns.call(&"set_aim_point", far_rock.global_position)
	guns.call(&"set_firing", true)
	await _ticks(TICKS_PER_SECOND)
	guns.call(&"set_firing", false)
	var far_drained: int = far_before - int(far_rock.get(&"yield_units"))
	_check(
		"range cap: the laser at 620 u reaches nothing (0 work)",
		far_drained == 0,
		"drained %s units" % far_drained
	)
	## The energy cadence (draw 6 E/s) against the reactor's 5 E/s refill: one second of
	## held fire must draw more than the refill returns.
	shooter_state.set_energy(shooter_state.energy_max)
	guns.call(&"set_aim_point", near_rock.global_position)
	guns.call(&"set_firing", true)
	await _ticks(TICKS_PER_SECOND)
	guns.call(&"set_firing", false)
	var drawn: float = shooter_state.energy_max - shooter_state.energy
	print("   [measure] laser draw over 1 s of fire = %s Energy (6/s draw, 5/s refill)" % drawn)
	_check(
		"the laser's 6 E/s draw nets about 1 Energy/s against the 5/s reactor refill",
		_near(drawn, 1.0, 0.4),
		"drawn %s" % drawn
	)
	for node: Node in [shooter, victim, near_rock, far_rock]:
		node.queue_free()
	await _ticks(2)


func _answers_damage(target: Object) -> bool:
	return target != null and (target.has_method(&"take_damage") or target.has_method(&"damage"))


func _rock_shape(rock: Node) -> Shape2D:
	var shape := rock.get_node_or_null(NodePath(AsteroidScript.SHAPE_NODE)) as CollisionShape2D
	return shape.shape if shape != null else null


func _make_rock(at: Vector2) -> Node2D:
	## Positioned before it enters the tree: a RigidBody2D adopts the node's transform on
	## entry, and a `global_position` write after that is overwritten by the body's own
	## state (W5's probing note, measured again here).
	var rock := AsteroidScript.new() as Node2D
	rock.global_position = at
	rock.call(&"setup", &"ore_iron", 1, 20, AsteroidScript.SIZE_LARGE)
	_world.add_child(rock)
	return rock


func _hull_body(ship: Node) -> Node:
	return ship.get_node_or_null(NodePath(PlayerShipScript.HULL_BODY_NODE))


## Every pickup in the tree, whatever a spawner parented it to. Counted by script path so
## the probe needs no global class registration under `--script`.
func _pickup_count() -> int:
	var count := 0
	for node: Node in get_root().find_children("*", "Node2D", true, false):
		var script := node.get_script() as Script
		if script != null and script.resource_path.ends_with("pickup.gd"):
			count += 1
	return count


func _hull_body_shape(ship: Node) -> Shape2D:
	var body := _hull_body(ship)
	if body == null:
		return null
	var shape := body.get_node_or_null(NodePath(PlayerShipScript.HULL_SHAPE_NODE)) as CollisionShape2D
	return shape.shape if shape != null else null


## --- C. Projectile travel, homing, destructibility, the mine ----------------------


func _section_c_projectiles() -> void:
	print("-- C. bolt/slug travel, rocket homing + destructibility, mine arm/trigger --")
	var pair := _make_ship(Vector2.ZERO)
	var shooter: Node2D = pair[0]
	var state: PlayerStateScript = pair[1]
	await _ticks(3)
	var guns: Node2D = shooter.get_node_or_null(NodePath(PlayerShipScript.WEAPONS_NODE))
	if guns == null:
		_check("projectile section needs the mounted component", false, "no WeaponComponent")
		return
	## A cannon bolt at 1000 u/s, straight from the shipped spawn path.
	var cannon_ids: Array[StringName] = [&"w_cannon"]
	guns.call(&"set_fitted", cannon_ids)
	guns.call(&"set_aim_point", shooter.global_position + Vector2(400.0, 0.0))
	var bolt := await _fire_once(guns, shooter)
	if bolt == null:
		_check("cannon spawns a bolt through the trigger", false, "no projectile in flight")
	else:
		var bolt_speed: float = (bolt.call(&"velocity") as Vector2).length()
		_check(
			"cannon bolt travels 1000 u/s",
			_near(bolt_speed, 1000.0, 1.0),
			"got %s" % bolt_speed
		)
		bolt.queue_free()
	await _ticks(2)
	## The railgun slug at 1400 u/s.
	var railgun_ids: Array[StringName] = [&"w_railgun"]
	guns.call(&"set_fitted", railgun_ids)
	var slug := await _fire_once(guns, shooter)
	if slug == null:
		_check("railgun spawns a slug through the trigger", false, "no projectile in flight")
	else:
		var slug_speed: float = (slug.call(&"velocity") as Vector2).length()
		_check(
			"railgun slug travels 1400 u/s",
			_near(slug_speed, 1400.0, 1.0),
			"got %s" % slug_speed
		)
		_check(
			"the slug bypasses shields (row rule)",
			bool(slug.call(&"bypasses_shield")),
			"bypass=%s" % slug.call(&"bypasses_shield")
		)
		slug.queue_free()
	await _ticks(2)
	## A locked rocket: 900 u/s and a 2.2 rad/s course change per second.
	var target_pair := _make_ship(Vector2(0.0, 300.0))
	var target: Node2D = target_pair[0]
	await _ticks(2)
	var rocket_ids: Array[StringName] = [&"w_rocket"]
	guns.call(&"set_fitted", rocket_ids)
	guns.call(&"set_lock_target", target)
	## Aim 90 degrees off the target so the turn is measurable on the first frame.
	guns.call(&"set_aim_point", shooter.global_position + Vector2(400.0, 0.0))
	var rocket := await _fire_once(guns, shooter)
	if rocket == null:
		_check("rocket spawns with a lock", false, "no projectile in flight")
	else:
		var heading_a: float = (rocket.call(&"velocity") as Vector2).angle()
		var rocket_speed: float = (rocket.call(&"velocity") as Vector2).length()
		await _ticks(1)
		if not is_instance_valid(rocket):
			_check(
				"rocket holds its 900 u/s flight for a frame",
				false,
				"the rocket did not survive a frame (speed %s)" % rocket_speed
			)
		else:
			var heading_b: float = (rocket.call(&"velocity") as Vector2).angle()
			var per_second: float = absf(heading_b - heading_a) / _physics_delta
			print(
				"   [measure] rocket speed %s u/s, course change %s rad/s over one frame"
				% [rocket_speed, per_second]
			)
			_check(
				"rocket flies at 900 u/s",
				_near(rocket_speed, 900.0, 1.0),
				"got %s" % rocket_speed
			)
			_check(
				"rocket homes at 2.2 rad/s toward the lock",
				_near(per_second, 2.2, 0.15),
				"got %s" % per_second
			)
			_check(
				"rocket flight is destructible (section 4.1)",
				bool(rocket.call(&"is_destructible")),
				"is_destructible=%s" % rocket.call(&"is_destructible")
			)
			rocket.queue_free()
	await _ticks(2)
	## The same delivery question for a travelling family: a cannon bolt on a real hull.
	## The bolt bypasses shields, so a landed bolt must move the target's HULL.
	var target_state: PlayerStateScript = target_pair[1]
	var hull_before: float = target_state.hull
	guns.call(&"set_fitted", cannon_ids)
	guns.call(&"set_aim_point", target.global_position)
	print(
		"   [diag] before the bolt: dry_reason=%s shot_timer=%s burst=%s cannon ammo=%s"
		% [
			guns.call(&"dry_reason"), guns.get(&"_shot_timer"), guns.get(&"_burst_phase"),
			target_state.ammo[1] if target_state.ammo.size() > 1 else "n/a",
		]
	)
	var at_hull := await _fire_once(guns, shooter)
	## A released shot is read off the weapon's own interval rather than off the probe's
	## projectile lookup: the freed shot of the previous family can still be in the
	## group's list for the frame, so the component's `_shot_timer` (set to the cannon's
	## 0.6 s at the moment of release) is the honest signal that the trigger fired.
	var released: bool = float(guns.get(&"_shot_timer")) > 0.0 or at_hull != null
	print(
		"   [diag] after the bolt attempt: shot_timer=%s, projectiles in the group=%s"
		% [guns.get(&"_shot_timer"), get_nodes_in_group(&"projectile").size()]
	)
	await _ticks(40)
	var hull_after: float = target_state.hull
	print(
		"   [measure] a cannon bolt at a hull 300 u away: released=%s, target hull %s -> %s (27 per bolt)"
		% [released, hull_before, hull_after]
	)
	_check(
		"a cannon bolt charges a real hull (bypass -> hull)",
		hull_after < hull_before - 1.0,
		"hull %s -> %s (unchanged means the bolt reached the hull's body, not the hull)"
		% [hull_before, hull_after]
	)
	await _ticks(2)
	## A mine: silent before 2 s, then it triggers on a hull inside 60 u. The blast
	## resolves its victim through the player/npc groups, so it lands on the ship node.
	var mine_victim_pair := _make_ship(Vector2(40.0, 0.0))
	var mine_victim: Node2D = mine_victim_pair[0]
	var mine_state: PlayerStateScript = mine_victim_pair[1]
	await _ticks(2)
	var mine_ids: Array[StringName] = [&"w_mine"]
	guns.call(&"set_fitted", mine_ids)
	guns.call(&"set_aim_point", shooter.global_position)
	var mine := await _fire_once(guns, shooter)
	if mine == null:
		_check("a mine is dropped on the trigger pull", false, "no mine in the world")
	else:
		## Section 4.1's mine row bypasses shields, so the blast is read on the victim's
		## HULL while the shield must not move at all.
		var mine_hull_before: float = mine_state.hull
		var mine_shield_before: float = mine_state.shield
		await _ticks(int(TICKS_PER_SECOND * 1.8))
		print(
			"   [diag] mine at %s armed=%s with a hull at %s (the trigger radius is 60 u)"
			% [
				mine.global_position if is_instance_valid(mine) else "freed",
				mine.get(&"_armed") if is_instance_valid(mine) else "n/a",
				mine_victim.global_position,
			]
		)
		_check(
			"the mine is silent before its 2 s arm with a hull at 40 u",
			_near(mine_state.hull, mine_hull_before, 0.001),
			"hull %s -> %s" % [mine_hull_before, mine_state.hull]
		)
		await _ticks(int(TICKS_PER_SECOND * 0.6))
		var after_blast: float = mine_state.hull
		print(
			"   [measure] mine blast on a hull at 40 u: hull %s -> %s (alpha 180), shield %s"
			% [mine_hull_before, after_blast, mine_state.shield]
		)
		_check(
			"the mine triggers after 2 s and charges the hull for its 180 alpha",
			_near(mine_hull_before - after_blast, 180.0, 1.0),
			"hull %s -> %s" % [mine_hull_before, after_blast]
		)
		_check(
			"the mine's bypass rule leaves the shield alone",
			_near(mine_state.shield, mine_shield_before, 0.001),
			"shield %s -> %s" % [mine_shield_before, mine_state.shield]
		)
	for node: Node in [shooter, target, mine_victim]:
		node.queue_free()
	await _ticks(2)


func _fire_once(guns: Node2D, shooter: Node2D) -> Node2D:
	guns.call(&"set_firing", false)
	## A released shot sets the row's own interval (the cannon's 0.6 s burst cycle, the
	## rocket's 1.2 s), and the component refuses the next pull until it elapses, so the
	## fixture waits the interval out instead of assuming a free barrel.
	var waited := 0
	while float(guns.get(&"_shot_timer")) > 0.0 and waited < 180:
		await physics_frame
		waited += 1
	await physics_frame
	guns.call(&"set_firing", true)
	for _i in 40:
		await physics_frame
		var shot := _first_shot()
		if shot != null:
			guns.call(&"set_firing", false)
			return shot
	guns.call(&"set_firing", false)
	return null


func _first_shot() -> Node2D:
	for node: Node in get_root().find_children("*", "Area2D", true, false):
		if node.is_in_group(&"projectile") and node is Node2D:
			return node as Node2D
	return null


## --- D. The energy draw gate ------------------------------------------------------


func _section_d_energy_gate() -> void:
	print("-- D. the energy gate: a short pool dry-fires, no shot --")
	_init_physics_delta()
	var pair := _make_ship(Vector2(0.0, 2000.0))
	var shooter: Node2D = pair[0]
	var state: PlayerStateScript = pair[1]
	await _ticks(3)
	var guns: Node2D = shooter.get_node_or_null(NodePath(PlayerShipScript.WEAPONS_NODE))
	if guns == null:
		return
	var victim_pair := _make_ship(Vector2(300.0, 2000.0))
	var victim: Node2D = victim_pair[0]
	var victim_state: PlayerStateScript = victim_pair[1]
	await _ticks(2)
	## An empty pool: the beam must not fire and must not damage anything. The reactor's
	## own refill would top a "dry" pool back up between frames, so the fixture pins the
	## refill to 0 and holds the pool empty for the whole pull (a real dry tank does not
	## refill: fuel replaces this energy only through `tick`, and slice 0's toll is what
	## spends it).
	state.energy_regen = 0.0
	state.set_energy(0.0)
	var before: float = victim_state.shield
	var dry := [0]
	guns.connect(&"dry_fired", func(_id: StringName) -> void: dry[0] += 1)
	var shots := [0]
	guns.connect(&"shot_fired", func(_id: StringName) -> void: shots[0] += 1)
	guns.call(&"set_aim_point", victim.global_position)
	guns.call(&"set_firing", true)
	await _ticks(30)
	guns.call(&"set_firing", false)
	_check(
		"dry pool: dry_fired is raised once for the pull",
		int(dry[0]) == 1,
		"dry_fired count %d" % int(dry[0])
	)
	_check(
		"dry pool: shot_fired is not raised",
		int(shots[0]) == 0,
		"shot_fired count %d" % int(shots[0])
	)
	_check(
		"dry pool: the target takes nothing",
		_near(victim_state.shield, before, 0.001),
		"shield %s -> %s" % [before, victim_state.shield]
	)
	_check(
		"dry_reason reads 'energy' with an empty pool",
		guns.call(&"dry_reason") == &"energy",
		"dry_reason=%s" % guns.call(&"dry_reason")
	)
	## A full pool: the same pull fires and spends.
	state.energy_regen = 5.0
	state.set_energy(state.energy_max)
	shots[0] = 0
	guns.call(&"set_firing", true)
	await _ticks(12)
	guns.call(&"set_firing", false)
	_check(
		"a full pool: shot_fired is raised for the beam hold",
		int(shots[0]) >= 1,
		"shot_fired count %d" % int(shots[0])
	)
	_check(
		"a full pool: Energy falls while the beam is up",
		state.energy < state.energy_max,
		"energy %s of %s" % [state.energy, state.energy_max]
	)
	## try_spend_energy (slice 0's gate) is what the draw runs through.
	_check(
		"try_spend_energy refuses a short pool and accepts a covered one",
		_spends_when_short(state),
		""
	)
	for node: Node in [shooter, victim]:
		node.queue_free()
	await _ticks(2)


func _spends_when_short(state: PlayerStateScript) -> bool:
	state.set_energy(0.5)
	var refused: bool = not state.try_spend_energy(6.0)
	state.set_energy(state.energy_max)
	var accepted: bool = state.try_spend_energy(6.0)
	return refused and accepted


## --- E. Absorb rule, regen window, ctx ----------------------------------------------


func _section_e_absorb_regen_ctx() -> void:
	print("-- E. shield-first absorb, the 4 s quiet window, the ctx round trip --")
	var state := PlayerStateScript.new()
	state.hull_max = 1000.0
	state.shield_max = 800.0
	state.setup()
	state.set_hull(1000.0)
	state.set_shield(800.0)
	state.damage(900.0, false, {})
	_check(
		"shield-first absorb with no carry-over: 900 into an 800 shield",
		_near(state.shield, 0.0, 0.001) and _near(state.hull, 1000.0, 0.001),
		"shield %s hull %s" % [state.shield, state.hull]
	)
	state.damage(250.0, true, {})
	_check(
		"a bypassing hit lands on the hull",
		_near(state.hull, 750.0, 0.001) and _near(state.shield, 0.0, 0.001),
		"shield %s hull %s" % [state.shield, state.hull]
	)
	## The regen window: nothing before REGEN_QUIET, the state's rate after it.
	state.set_shield(100.0)
	DamageScript.regen(state, 1.0, DamageScript.REGEN_QUIET - 0.001)
	_check(
		"regen stays off just inside the 4 s window",
		_near(state.shield, 100.0, 0.001),
		"shield %s" % state.shield
	)
	DamageScript.regen(state, 1.0, DamageScript.REGEN_QUIET)
	var gained: float = state.shield - 100.0
	_check(
		"regen resumes at REGEN_QUIET, at the state's own rate",
		_near(gained, state.shield_regen, 0.001),
		"gained %s at a rate of %s/s" % [gained, state.shield_regen]
	)
	## The fit's rate on a fitted shield (09 section 3.2).
	state.shield_regen = ShipFitScript.resolve(HULL, ShipFitScript.STANDARD_FIT).shield_regen
	state.set_shield(0.0)
	DamageScript.regen(state, 1.0, DamageScript.REGEN_QUIET)
	_check(
		"a fitted s_light regenerates at 6/s (base 2 + 4)",
		_near(state.shield, 6.0, 0.001),
		"shield %s" % state.shield
	)
	## The ctx round trip through PlayerState.damage.
	var ctx := DamageScript.context(Vector2.ZERO, 0.0, Vector2(10.0, 0.0), 1234.5, &"kinetic")
	state.damage(10.0, false, ctx)
	var recorded: Dictionary = state.last_damage_ctx()
	_check(
		"ctx round trip: direction/impulse/family recorded verbatim",
		_near(float(recorded.get(&"direction", 99.0)), 0.0, 0.0001)
			and _near(float(recorded.get(&"impulse", 0.0)), 1234.5, 0.001)
			and StringName(recorded.get(&"family", &"")) == &"kinetic",
		"recorded %s" % [recorded]
	)
	## Damage.bearing's four arcs, which slice 3 reads.
	_check(
		"bearing reads prow 0 / starboard +PI/2 / port -PI/2 / stern +/-PI",
		_near(DamageScript.bearing(Vector2.ZERO, 0.0, Vector2(10.0, 0.0)), 0.0, 0.0001)
			and _near(DamageScript.bearing(Vector2.ZERO, 0.0, Vector2(0.0, 10.0)), PI / 2.0, 0.0001)
			and _near(DamageScript.bearing(Vector2.ZERO, 0.0, Vector2(0.0, -10.0)), -PI / 2.0, 0.0001)
			and _near(absf(DamageScript.bearing(Vector2.ZERO, 0.0, Vector2(-10.0, 0.0))), PI, 0.0001),
		"prow=%s starboard=%s stern=%s" % [
			DamageScript.bearing(Vector2.ZERO, 0.0, Vector2(10.0, 0.0)),
			DamageScript.bearing(Vector2.ZERO, 0.0, Vector2(0.0, 10.0)),
			DamageScript.bearing(Vector2.ZERO, 0.0, Vector2(-10.0, 0.0)),
		]
	)


## --- F. The brain walk ------------------------------------------------------------


func _section_f_brain() -> void:
	print("-- F. the brain state walk, the swarmer, flee/leash/AGGRO_COOLDOWN --")
	var nearest_only := func(_a: Vector2, _b: Vector2) -> bool: return true
	var blocked := func(_a: Vector2, _b: Vector2) -> bool: return false
	var pirate_row := NpcRegistryScript.archetype(&"pirate")
	var brain: RefCounted = NpcBrainScript.new()
	brain.call(&"setup", &"pirate", pirate_row, Vector2.ZERO)
	brain.call(&"set_line_of_sight", nearest_only)
	var clear_ctx := {
		&"pos": Vector2(100.0, 0.0),
		&"hull_fraction": 1.0,
		&"heat_tier": &"clean",
		&"home": Vector2.ZERO,
		&"contacts": [{
			&"pos": Vector2(200.0, 0.0),
			&"is_player": true,
			&"archetype": &"player",
			&"hostility": &"none",
			&"node": null,
		}],
		&"attacked": false,
	}
	var idle: Dictionary = brain.call(&"tick", _physics_delta, {
		&"pos": Vector2(100.0, 0.0),
		&"hull_fraction": 1.0,
		&"heat_tier": &"clean",
		&"home": Vector2.ZERO,
		&"contacts": [],
		&"attacked": false,
	})
	_check(
		"no contact: the hull patrols",
		StringName(idle.get(&"state", &"")) == &"patrol",
		"state=%s" % idle.get(&"state", &"")
	)
	var engaged: Dictionary = brain.call(&"tick", _physics_delta, clear_ctx)
	_check(
		"a player inside the 900 u aggro radius: engage, fire, LOS clear",
		StringName(engaged.get(&"state", &"")) == &"engage"
			and bool(engaged.get(&"fire", false))
			and bool(engaged.get(&"los", false)),
		"state=%s fire=%s los=%s" % [
			engaged.get(&"state"), engaged.get(&"fire"), engaged.get(&"los")
		]
	)
	## A rock between them: ALERT, no fire (§13 / section 5 "rocks block").
	var blocked_brain: RefCounted = NpcBrainScript.new()
	blocked_brain.call(&"setup", &"pirate", pirate_row, Vector2.ZERO)
	blocked_brain.call(&"set_line_of_sight", blocked)
	var alert: Dictionary = blocked_brain.call(&"tick", _physics_delta, clear_ctx)
	_check(
		"a blocked LOS holds the hull in alert and it does not fire",
		StringName(alert.get(&"state", &"")) == &"alert" and not bool(alert.get(&"fire", true)),
		"state=%s fire=%s" % [alert.get(&"state"), alert.get(&"fire")]
	)
	## The pirate's 30 % hull flight (§13). `merged(other, true)` because Dictionary.merged
	## does not overwrite by default and the fixture must actually replace the key.
	var low := clear_ctx.merged({&"hull_fraction": 0.29}, true)
	var fleeing: Dictionary = brain.call(&"tick", 0.05, low)
	_check(
		"a pirate at 29 % hull flees",
		StringName(fleeing.get(&"state", &"")) == &"flee",
		"state=%s" % fleeing.get(&"state", &"")
	)
	var high := clear_ctx.merged({&"hull_fraction": 0.31}, true)
	brain.call(&"tick", 0.05, high)
	_check(
		"a pirate at 31 % hull does not flee",
		StringName(brain.call(&"state_name")) != &"flee",
		"state=%s" % brain.call(&"state_name")
	)
	## The AGGRO_COOLDOWN grace: with the hull still inside its leash but the contact
	## gone, the aggro (and so section 7's safe warp) holds for the whole window.
	var grace: RefCounted = NpcBrainScript.new()
	grace.call(&"setup", &"pirate", pirate_row, Vector2.ZERO)
	grace.call(&"set_line_of_sight", nearest_only)
	grace.call(&"tick", _physics_delta, clear_ctx)
	var engaged_at_start: bool = bool(grace.call(&"is_engaged"))
	var far := clear_ctx.duplicate(true)
	far[&"pos"] = Vector2(100.0, 0.0)
	far[&"contacts"] = []
	var held := 0.0
	var still_engaged := true
	while held < NpcBrainScript.AGGRO_COOLDOWN - 0.4:
		grace.call(&"tick", 0.1, far)
		held += 0.1
		if not bool(grace.call(&"is_engaged")):
			still_engaged = false
	_check(
		"the aggro holds for the whole AGGRO_COOLDOWN (the safe warp stays shut)",
		engaged_at_start and still_engaged and held >= NpcBrainScript.AGGRO_COOLDOWN - 0.5,
		"engaged at start=%s still engaged at %s s=%s" % [engaged_at_start, held, still_engaged]
	)
	while held < NpcBrainScript.AGGRO_COOLDOWN + 0.4:
		grace.call(&"tick", 0.1, far)
		held += 0.1
	_check(
		"the aggro clears after AGGRO_COOLDOWN",
		not bool(grace.call(&"is_engaged")),
		"engaged after %s s = %s" % [held, grace.call(&"is_engaged")]
	)
	## The leash: past 2500 u from the POI with a contact in radius, the hull returns.
	var leash: RefCounted = NpcBrainScript.new()
	leash.call(&"setup", &"pirate", pirate_row, Vector2.ZERO)
	leash.call(&"set_line_of_sight", nearest_only)
	var past := clear_ctx.duplicate(true)
	past[&"pos"] = Vector2(NpcBrainScript.LEASH_RADIUS + 400.0, 0.0)
	past[&"contacts"] = [{
		&"pos": Vector2(NpcBrainScript.LEASH_RADIUS + 700.0, 0.0),
		&"is_player": true,
		&"archetype": &"player",
		&"hostility": &"none",
		&"node": null,
	}]
	var leashed: Dictionary = leash.call(&"tick", _physics_delta, past)
	_check(
		"past the 2500 u leash: return, not chase",
		StringName(leashed.get(&"state", &"")) == &"return",
		"state=%s" % leashed.get(&"state", &"")
	)
	## The trader flees on Suspect+ (doc 13 section 5).
	var trader_brain: RefCounted = NpcBrainScript.new()
	trader_brain.call(&"setup", &"trader", NpcRegistryScript.archetype(&"trader"), Vector2.ZERO)
	var suspect := clear_ctx.merged({&"hull_fraction": 1.0, &"heat_tier": &"suspect"}, true)
	suspect[&"pos"] = Vector2(100.0, 0.0)
	var trader_state: Dictionary = trader_brain.call(&"tick", _physics_delta, suspect)
	_check(
		"a trader flees at Suspect+",
		StringName(trader_state.get(&"state", &"")) == &"flee",
		"state=%s" % trader_state.get(&"state", &"")
	)
	## Doc 13 section 2: a patrol ignores Clean and attacks Outlaws.
	var patrol_brain: RefCounted = NpcBrainScript.new()
	patrol_brain.call(&"setup", &"patrol", NpcRegistryScript.archetype(&"patrol"), Vector2.ZERO)
	patrol_brain.call(&"set_line_of_sight", nearest_only)
	var clean_ctx := clear_ctx.duplicate(true)
	clean_ctx[&"heat_tier"] = &"clean"
	var clean_state: Dictionary = patrol_brain.call(&"tick", _physics_delta, clean_ctx)
	_check(
		"a patrol ignores a Clean player (no engage, no scan)",
		StringName(clean_state.get(&"state", &"")) != &"engage"
			and StringName(clean_state.get(&"state", &"")) != &"scan",
		"state=%s" % clean_state.get(&"state", &"")
	)
	var suspect_ctx := clear_ctx.duplicate(true)
	suspect_ctx[&"heat_tier"] = &"suspect"
	var scan_state: Dictionary = patrol_brain.call(&"tick", _physics_delta, suspect_ctx)
	_check(
		"a patrol scans a Suspect player at 1000 u",
		StringName(scan_state.get(&"state", &"")) == &"scan",
		"state=%s" % scan_state.get(&"state", &"")
	)
	var outlaw_ctx := clear_ctx.duplicate(true)
	outlaw_ctx[&"heat_tier"] = &"outlaw"
	var outlaw_state: Dictionary = patrol_brain.call(&"tick", _physics_delta, outlaw_ctx)
	_check(
		"a patrol attacks an Outlaw",
		StringName(outlaw_state.get(&"state", &"")) == &"engage"
			and bool(outlaw_state.get(&"fire", false)),
		"state=%s fire=%s" % [outlaw_state.get(&"state"), outlaw_state.get(&"fire")]
	)
	## The swarmer is a live sector archetype on the same brain, on placeholder-safe art.
	var swarmer_brain: RefCounted = NpcBrainScript.new()
	swarmer_brain.call(&"setup", &"swarmer", NpcRegistryScript.archetype(&"swarmer"), Vector2.ZERO)
	swarmer_brain.call(&"set_line_of_sight", nearest_only)
	var swarmer_state: Dictionary = swarmer_brain.call(&"tick", _physics_delta, clear_ctx)
	_check(
		"the alien swarmer engages on the same brain",
		StringName(swarmer_state.get(&"state", &"")) == &"engage",
		"state=%s" % swarmer_state.get(&"state", &"")
	)


## --- G. Loot weights -------------------------------------------------------------


func _section_g_loot() -> void:
	print("-- G. loot weight sums and the countermeasure rows --")
	var tables := {&"fighter": 1.70, &"swarmer": 1.70, &"freighter": 1.40, &"corvette": 1.35, &"maw": 4.00}
	for kind: StringName in tables:
		var lines: Array = LootScript.TABLES[kind][&"lines"] as Array
		var sum := 0.0
		for line: Dictionary in lines:
			sum += float(line[&"chance"])
		_check(
			"%s chance sum = %s (the table's own total, not 1.0)" % [kind, tables[kind]],
			_near(sum, tables[kind], 0.0001),
			"sum %s" % sum
		)
	## doc 06 section 6 check 2 against the 03 catalogue; the two countermeasures are the
	## documented gap.
	var violations: Array[String] = LootScript.cap_violations()
	var missing: Array[StringName] = LootScript.uncatalogued_items()
	_check(
		"06 section 6 check 2: no table exceeds its band",
		violations.is_empty(),
		"violations %s" % [violations]
	)
	_check(
		"the only uncatalogued loot ids are the two countermeasures",
		missing.size() == 2 and missing.has(&"cm_chaff") and missing.has(&"cm_flare"),
		"uncatalogued %s" % [missing]
	)
	## Expected units per class (06 section 3's tables, independent arithmetic): a credit
	## cache is money, not goods (06 section 5), so only component lines count toward the
	## unit haul, while the CR column of the report counts the cache's own range.
	var units := {
		&"fighter": 0.55 * 1.5 + 0.30 + 0.35 * 1.5 + 0.20 + 0.15 + 0.15,
		&"freighter": 0.60 * 2.5 + 0.35 + 0.30 * 1.5,
		&"corvette": 0.50 * 1.5 + 0.30 + 0.25 + 0.20,
		&"maw": 1.0 * 4.0 + 0.75 * 1.5 + 0.60 + 0.40 + 0.25,
	}
	for kind: StringName in units:
		var total := 0.0
		for line: Dictionary in (LootScript.TABLES[kind][&"lines"] as Array):
			if StringName(line[&"item"]) == LootScript.CREDIT_ITEM:
				continue
			total += float(line[&"chance"]) * (float(line[&"min"]) + float(line[&"max"])) * 0.5
		_check(
			"%s expected units = %s" % [kind, units[kind]],
			_near(total, units[kind], 0.01),
			"got %s" % total
		)
	## A seeded roll is reproducible and never exceeds the tables' ranges.
	var a: Array[Dictionary] = LootScript.roll(&"fighter", 1, 20260921)
	var b: Array[Dictionary] = LootScript.roll(&"fighter", 1, 20260921)
	_check(
		"a seeded roll is reproducible and pays only 06 ids",
		a.size() == b.size() and _same_ids(a, b) and _ids_are_known(a),
		"%s vs %s" % [a, b]
	)


func _same_ids(a: Array[Dictionary], b: Array[Dictionary]) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if StringName(a[i][&"item_id"]) != StringName(b[i][&"item_id"]):
			return false
		if int(a[i][&"amount"]) != int(b[i][&"amount"]):
			return false
	return true


func _ids_are_known(payload: Array[Dictionary]) -> bool:
	var known := [&"comp_scrap_1", &"comp_weap_1", &"comp_pow_1", &"comp_elec_1", &"cm_chaff", &"cm_flare"]
	for entry: Dictionary in payload:
		if not known.has(StringName(entry[&"item_id"])):
			return false
	return true


## --- H. Sector counts ------------------------------------------------------------


func _section_h_sector_counts() -> void:
	print("-- H. sector NPC counts vs the section 13 / doc 13 section 4 shape --")
	var band := [
		Vector2i(0, 1), Vector2i(1, 2), Vector2i(2, 3), Vector2i(3, 4),
		Vector2i(3, 5), Vector2i(4, 6), Vector2i(6, 8),
	]
	for index in band.size():
		var sector_id := StringName("sector_%d" % (index + 1))
		var hostiles := Vector2i.ZERO
		for id: StringName in [&"pirate", &"swarmer"]:
			hostiles += NpcRegistryScript.density(id, sector_id)
		_check(
			"%s hostile band = %s" % [sector_id, band[index]],
			hostiles == band[index],
			"got %s" % hostiles
		)
	## Patrols only in owned space: S7 must have none in the shipped registry.
	## (SectorRegistry's owner column decides; the registry zeroes an unowned sector.)
	var patrols := {}
	for index in 7:
		var sector_id := StringName("sector_%d" % (index + 1))
		patrols[sector_id] = NpcRegistryScript.density(&"patrol", sector_id)
	print("   [measure] patrol density per sector: %s" % [patrols])
	_check(
		"the unowned sector spawns no patrol",
		_unaligned_sectors_have_no_patrols(patrols),
		"patrols %s" % [patrols]
	)
	## One convoy per inhabited sector (doc 11 section 3 / 18 section 13).
	var convoys := {}
	for index in 7:
		var sector_id := StringName("sector_%d" % (index + 1))
		convoys[sector_id] = NpcRegistryScript.density(&"trader", sector_id)
	print("   [measure] convoy density per sector: %s" % [convoys])
	_check(
		"each inhabited sector rolls exactly one convoy",
		_convoys_are_one(convoys),
		"convoys %s" % [convoys]
	)
	## No seam row reaches a sector's spawn list.
	var leaked: Array[String] = []
	for index in 7:
		var sector_id := StringName("sector_%d" % (index + 1))
		for spawn: Dictionary in NpcRegistryScript.spawns_for(sector_id):
			var archetype := StringName(spawn.get(NpcRegistryScript.KEY_ARCHETYPE, &""))
			if archetype == &"hunter" or archetype == &"boss" or archetype == &"turret":
				var pair := NpcRegistryScript.density(archetype, sector_id)
				if pair != Vector2i.ZERO:
					leaked.append("%s in %s" % [archetype, sector_id])
	_check(
		"no seam row (hunter/boss) or station row (turret) reaches a sector spawn list",
		leaked.is_empty(),
		"leaked %s" % [leaked]
	)
	## Doc 13 section 4's pointer now resolves to numbers (W0b's transcription).
	var doc := FileAccess.get_file_as_string("res://../docs/gameplay/13_heat_bounty.md")
	if doc.is_empty():
		doc = FileAccess.get_file_as_string("res://docs/gameplay/13_heat_bounty.md")
	print("   [measure] doc 13 section 4 transcription present: %s" % (doc.contains("S6 4–6")))


func _unaligned_sectors_have_no_patrols(patrols: Dictionary) -> bool:
	## `space_owner` returns the registry's `UNALIGNED` sentinel for a sector with no
	## owner (not an empty name), so the owner is read off the sector row itself.
	for row: Dictionary in Registry.SECTORS:
		var sector_id := StringName(row.get(&"id", &""))
		var owner := StringName(row.get(&"owner", &""))
		var density: Vector2i = patrols.get(sector_id, Vector2i.ZERO)
		if owner == &"unaligned" or owner == &"":
			if density != Vector2i.ZERO:
				print("      unowned %s has patrol %s" % [sector_id, density])
				return false
		else:
			if density != Vector2i(1, 1):
				print("      owned %s (%s) has patrol %s" % [sector_id, owner, density])
				return false
	return true


func _convoys_are_one(convoys: Dictionary) -> bool:
	for row: Dictionary in Registry.SECTORS:
		var sector_id := StringName(row.get(&"id", &""))
		var owner := StringName(row.get(&"owner", &""))
		var inhabited: bool = owner != &"unaligned" and owner != &""
		var density: Vector2i = convoys.get(sector_id, Vector2i.ZERO)
		if inhabited and density != Vector2i(1, 1):
			print("      inhabited %s has convoy %s" % [sector_id, density])
			return false
		if not inhabited and density != Vector2i.ZERO:
			print("      uninhabited %s has convoy %s" % [sector_id, density])
			return false
	return true


## --- I. HUD ----------------------------------------------------------------------


func _section_i_hud() -> void:
	print("-- I. the lock ring, the radial speedometer, the pools, the target payload --")
	await _ticks(2)
	var packed := load(HUD_SCENE_PATH) as PackedScene
	var hud := packed.instantiate() as Control if packed != null else null
	if hud == null:
		_check("hud.tscn instantiates", false, "null (script compile?)")
		return
	_world.add_child(hud)
	await _ticks(2)
	var state := PlayerStateScript.new()
	state.hull_max = 1000.0
	state.shield_max = 600.0
	state.setup()
	hud.call(&"bind", state)
	## UI_SPEC section 3.5's lock channel ring: "empty hides".
	hud.call(&"set_lock_progress", 0.417)
	await _ticks(1)
	_check(
		"set_lock_progress(0.417) reads back 0.417",
		_near(float(hud.call(&"lock_progress")), 0.417, 0.001),
		"got %s" % hud.call(&"lock_progress")
	)
	hud.call(&"set_lock_progress", 0.0)
	_check(
		"a zero lock progress hides the ring",
		_near(float(hud.call(&"lock_progress")), 0.0, 0.0001)
			and not (hud.call(&"lock_ring") as Control).visible,
		"progress %s visible %s" % [
			hud.call(&"lock_progress"), (hud.call(&"lock_ring") as Control).visible
		]
	)
	## UI_SPEC section 3.6's radial dial: 10 segments, ratio in, ratio out.
	hud.call(&"set_speedometer", 0.587, Vector2(1.0, 0.2).normalized(), Vector2(1.0, 0.0))
	await _ticks(1)
	_check(
		"set_speedometer's ratio reads back (0.587)",
		_near(float(hud.call(&"speedometer_ratio")), 0.587, 0.001),
		"got %s" % hud.call(&"speedometer_ratio")
	)
	var dial := hud.call(&"speedometer") as Control
	_check("the dial node exists with a 120 x 120 box", dial != null and dial.size.x >= 100.0,
		"size %s" % [dial.size if dial != null else Vector2.ZERO])
	## Section 10's pool bars (slice 0's seam, still live).
	hud.call(&"set_pool", &"energy", 64.0, 100.0)
	hud.call(&"set_pool", &"fuel", 20.0, 200.0)
	hud.call(&"set_pool", &"nonsense", 1.0, 2.0)
	_check("an unknown pool kind is ignored, not fatal", true, "no error raised")
	## Section 10: the target payload gains in_range + threat.
	hud.call(&"set_target", Vector2(400.0, 300.0), 0.75)
	hud.call(&"set_target_info", {
		&"name": "Lancer",
		&"hull": 700.0,
		&"shield": 400.0,
		&"distance_m": 1240.0,
		&"in_range": true,
		&"threat": &"HOSTILE",
	})
	await _ticks(1)
	var info: Dictionary = hud.call(&"target_info")
	_check(
		"set_target_info carries in_range and threat",
		bool(info.get(&"in_range", false)) and StringName(info.get(&"threat", &"")) == &"HOSTILE",
		"info %s" % [info]
	)
	## Section 4.2 item 4: a hit marker exists and is small (no floating numbers).
	hud.call(&"hit_marker")
	await _ticks(2)
	var marker := hud.call(&"hit_marker_node") as Control
	_check(
		"the hit marker exists and is a small reticle mark, not a damage number",
		marker != null and marker.size.x <= 64.0,
		"node %s size %s" % [marker, marker.size if marker != null else Vector2.ZERO]
	)
	hud.queue_free()
	await _ticks(2)


## --- J. Countermeasures (section 4.6) ---------------------------------------------


## The item spend is a guarded `PlayerProfile.remove_cargo`; this probe never mutates the
## owner's profile, so the *mechanic* is driven through the two seams
## `use_countermeasure` calls (`_deploy_chaff` / `_deploy_flare`) and the spend path is
## measured as its refusal, which must change nothing.
func _section_j_countermeasures() -> void:
	print("-- J. chaff ghosts and flare retargeting (section 4.6) --")
	var profile := get_root().get_node_or_null(NodePath(&"PlayerProfile"))
	print("   [diag] PlayerProfile present: %s" % (profile != null))
	var pair := _make_ship(Vector2(0.0, 5000.0))
	var shooter: Node2D = pair[0]
	await _ticks(3)
	var guns: Node2D = shooter.get_node_or_null(NodePath(PlayerShipScript.WEAPONS_NODE))
	if guns == null:
		_check("countermeasures need the mounted component", false, "no WeaponComponent")
		return
	## Nothing aboard: the spend is refused and the effect must not fire.
	if profile == null or int(profile.call(&"cargo_qty", &"cm_chaff")) == 0:
		var refused: bool = bool(guns.call(&"use_countermeasure", &"cm_chaff"))
		_check(
			"chaff without the item aboard is refused and fires nothing",
			not refused and (guns.call(&"ghosts") as Array).is_empty()
				and not bool(guns.call(&"jamming")),
			"returned %s, ghosts %s" % [refused, (guns.call(&"ghosts") as Array).size()]
		)
		_check(
			"an unknown item id is refused too",
			not bool(guns.call(&"use_countermeasure", &"cm_bogus")),
			"returned true"
		)
	else:
		print("   [diag] the profile already holds cm_chaff; the refusal path is skipped")
	## A live lock to break.
	var target_pair := _make_ship(Vector2(0.0, 5200.0))
	var target: Node2D = target_pair[0]
	await _ticks(2)
	guns.call(&"set_lock_target", target)
	var broken := [0]
	guns.connect(&"locks_broken", func() -> void: broken[0] += 1)
	guns.call(&"_deploy_chaff")
	await _ticks(1)
	var ghosts: Array = guns.call(&"ghosts")
	_check(
		"chaff deploys exactly 3 ghost signatures",
		ghosts.size() == 3,
		"ghosts %s" % ghosts.size()
	)
	var all_ghost := true
	for ghost: Node in ghosts:
		if not StringName(ghost.call(&"blip_kind")).is_empty():
			if StringName(ghost.call(&"blip_kind")) != &"ghost":
				all_ghost = false
	_check(
		"every ghost answers the UI_SPEC section 3.3 blip kind 'ghost'",
		all_ghost and ghosts.size() == 3,
		"kinds %s" % [
			(func() -> String:
				var out: Array[String] = []
				for ghost: Node in ghosts:
					out.append(String(ghost.call(&"blip_kind")))
				return str(out)).call()
		]
	)
	_check(
		"chaff breaks the active lock immediately",
		int(broken[0]) == 1 and guns.call(&"lock_target") == null,
		"locks_broken %s, lock target %s" % [int(broken[0]), guns.call(&"lock_target")]
	)
	_check(
		"jamming() is true while the ghosts live",
		bool(guns.call(&"jamming")),
		"jamming %s" % guns.call(&"jamming")
	)
	await _ticks(int(TICKS_PER_SECOND * 2.0))
	_check(
		"the ghosts are still live at 2.0 s",
		(guns.call(&"ghosts") as Array).size() == 3,
		"ghosts %s" % (guns.call(&"ghosts") as Array).size()
	)
	await _ticks(int(TICKS_PER_SECOND * 1.4))
	_check(
		"the ghosts are gone after the 3.0 s CHAFF_WINDOW and the jam has lifted",
		(guns.call(&"ghosts") as Array).is_empty() and not bool(guns.call(&"jamming")),
		"ghosts %s jamming %s" % [
			(guns.call(&"ghosts") as Array).size(), guns.call(&"jamming")
		]
	)
	## A flare: a homing rocket inside FLARE_LURE retargets to the decoy and detonates
	## on it (section 4.6).
	guns.call(&"clear_lock_target")
	var rocket_ids: Array[StringName] = [&"w_rocket"]
	guns.call(&"set_fitted", rocket_ids)
	guns.call(&"set_lock_target", target)
	guns.call(&"set_aim_point", shooter.global_position + Vector2(400.0, 0.0))
	var rocket := await _fire_once(guns, shooter)
	if rocket == null:
		_check("a rocket is in flight for the flare to lure", false, "no projectile")
	else:
		guns.call(&"_deploy_flare")
		await _ticks(2)
		var decoy: Variant = guns.call(&"flare")
		var lured: Variant = rocket.call(&"decoy") if is_instance_valid(rocket) else null
		_check(
			"a rocket inside FLARE_LURE retargets to the live flare",
			decoy != null and lured == decoy,
			"flare %s, the rocket's decoy %s" % [decoy, lured]
		)
		var detonated := [false]
		if is_instance_valid(rocket):
			rocket.connect(
				&"detonated",
				func(_pos: Vector2, _damage: float, _bypass: bool) -> void: detonated[0] = true
			)
		await _ticks(int(TICKS_PER_SECOND * 1.5))
		print(
			"   [measure] the lured rocket valid after 1.5 s: %s (it detonates on the decoy)"
			% is_instance_valid(rocket)
		)
		_check(
			"the lured rocket detonates on the decoy rather than the hull",
			not is_instance_valid(rocket) or bool(detonated[0]),
			"rocket alive %s, detonated %s" % [is_instance_valid(rocket), bool(detonated[0])]
		)
	## A rocket beyond the lure radius keeps its own target.
	guns.call(&"set_lock_target", target)
	var far_rocket := await _fire_once(guns, shooter)
	if far_rocket != null:
		guns.call(&"_deploy_flare")
		var own: Variant = far_rocket.call(&"lock_target") if is_instance_valid(far_rocket) else null
		await _ticks(1)
		var stale: Variant = far_rocket.call(&"decoy") if is_instance_valid(far_rocket) else null
		print(
			"   [measure] a rocket beyond the lure radius: lock target %s, decoy %s"
			% [own, stale]
		)
	for node: Node in [shooter, target]:
		node.queue_free()
	await _ticks(2)
