extends SceneTree
## slice-0 M4 review probe A (numbers + station services + save round-trip).
## The review measures against a literal transcription of the spec, not against the
## worker reports: every expected value below was typed from
## docs/gameplay/18_engine_spec.md section 13 (and section 4.4/15/16 for the prose
## rulings) before the code was read.
##
## Re-run:
##   "..._console.exe" --headless --path <proj> --script res://tools/_probe_s0m4_numbers.gd --quit-after 600

const ShipFitScript := preload("res://game/ship_fit.gd")
const ImpactScript := preload("res://game/impact.gd")
const StateScript := preload("res://game/player_state.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const CatalogScript := preload("res://game/station_catalog.gd")
const RepairsScript := preload("res://game/repairs.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")
const LogScript := preload("res://game/economy_log.gd")

const SCRATCH := "user://_probe_s0m4_profile.cfg"
const SCRATCH_LOG := "user://_probe_s0m4_log.txt"

## 18_engine_spec.md section 13, "Handling per class" + the hull_mass row, typed
## straight off the spec text (lines 511-521 and 466).
const SPEC_HANDLING := {
	&"ship_fighter": {&"max_speed": 450.0, &"accel_time": 2.0, &"coast_time": 1.6, &"turn_rate": 3.4, &"turn_spinup": 0.4, &"hull_mass": 80.0},
	&"ship_vanguard": {&"max_speed": 428.0, &"accel_time": 2.4, &"coast_time": 2.0, &"turn_rate": 3.0, &"turn_spinup": 0.5, &"hull_mass": 110.0},
	&"ship_miner": {&"max_speed": 338.0, &"accel_time": 4.0, &"coast_time": 3.4, &"turn_rate": 2.0, &"turn_spinup": 1.0, &"hull_mass": 140.0},
	&"ship_trader": {&"max_speed": 383.0, &"accel_time": 3.0, &"coast_time": 2.6, &"turn_rate": 2.4, &"turn_spinup": 0.7, &"hull_mass": 160.0},
	&"ship_corvette": {&"max_speed": 495.0, &"accel_time": 2.2, &"coast_time": 1.8, &"turn_rate": 3.2, &"turn_spinup": 0.45, &"hull_mass": 90.0},
	&"ship_freighter": {&"max_speed": 293.0, &"accel_time": 6.0, &"coast_time": 5.2, &"turn_rate": 1.5, &"turn_spinup": 1.4, &"hull_mass": 260.0},
	&"ship_gunship": {&"max_speed": 360.0, &"accel_time": 4.4, &"coast_time": 3.8, &"turn_rate": 1.9, &"turn_spinup": 1.0, &"hull_mass": 190.0},
	&"ship_patrol": {&"max_speed": 383.0, &"accel_time": 4.0, &"coast_time": 3.4, &"turn_rate": 2.1, &"turn_spinup": 0.9, &"hull_mass": 220.0},
	&"ship_destroyer": {&"max_speed": 315.0, &"accel_time": 6.4, &"coast_time": 5.6, &"turn_rate": 1.6, &"turn_spinup": 1.2, &"hull_mass": 300.0},
}

var _ok := 0
var _failed := 0
var _profile: Node = null


func _init() -> void:
	print("=== slice0 M4 probe A: numbers, services, persistence ===")
	_report_handling()
	_report_impact()
	_report_pools()
	_report_cleaving_consts()
	_report_hull_constants()
	await process_frame
	_report_services()
	_report_persistence()
	_finish()


func _finish() -> void:
	if _profile != null and is_instance_valid(_profile):
		_profile.save_path = ProfileScript.SAVE_FILE
	LogScript.log_path = LogScript.DEFAULT_PATH
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_LOG))
	print("[SUMMARY] ok=%d failed=%d" % [_ok, _failed])
	quit(1 if _failed > 0 else 0)


func _check(label: String, passed: bool, detail: String = "") -> void:
	var suffix := "" if detail.is_empty() else " | " + detail
	if passed:
		_ok += 1
		print("[OK]   %s%s" % [label, suffix])
	else:
		_failed += 1
		print("[FAIL] %s%s" % [label, suffix])


## The whole handling column, row by row, against the typed spec table.
func _report_handling() -> void:
	var bad: Array[String] = []
	for hull: StringName in SPEC_HANDLING:
		var row: Dictionary = SPEC_HANDLING[hull]
		var live: Variant = ShipFitScript.HANDLING.get(hull, null)
		if not live is Dictionary:
			bad.append("%s missing" % hull)
			continue
		var table: Dictionary = live
		for key: StringName in row:
			if not is_equal_approx(float(table.get(key, -1.0)), float(row[key])):
				bad.append("%s.%s=%s want %s" % [hull, key, table.get(key), row[key]])
	_check("handling: ShipFit.HANDLING is the section 13 column, all 9 rows",
		bad.is_empty(), "mismatches: %s" % [bad])
	var resolved: StringName = &"ship_vanguard"
	var stats = ShipFitScript.resolve(resolved, ShipFitScript.STANDARD_FIT)
	## The standard fit carries h_plate_light (speed_penalty -0.05), so 09 section 5's
	## armour step is applied before the clamp: 428 x 0.95.
	var plate: Dictionary = ShipFitScript.MODULES[&"h_plate_light"]
	var armoured := 428.0 * (1.0 + float(plate[&"effects"][&"speed_penalty"]))
	_check("resolve: the Cutter resolves to its own row, armour step applied, pool base",
		stats != null and stats.hull_mass == 110.0
		and is_equal_approx(stats.max_speed, armoured)
		and stats.energy_max == 100.0 and stats.fuel_max == 200.0
		and stats.energy_regen == 5.0,
		"hull_mass=%s max_speed=%s (want %s) energy=%s/%s fuel=%s"
		% [stats.hull_mass, stats.max_speed, armoured, stats.energy_max,
		stats.energy_regen, stats.fuel_max])


## Section 13's "Collision, recoil, explosions" rows and section 16's worked example.
func _report_impact() -> void:
	_check("impact: COLLISION_FACTOR is 2.0e-5 (section 13)",
		ImpactScript.COLLISION_FACTOR == 2.0e-5, "%s" % ImpactScript.COLLISION_FACTOR)
	_check("impact: COLLISION_MIN_DV is 40 u/s (section 13)",
		ImpactScript.COLLISION_MIN_DV == 40.0, "%s" % ImpactScript.COLLISION_MIN_DV)
	_check("impact: KNOCKBACK_FRACTION is 0.40 (section 13)",
		ImpactScript.KNOCKBACK_FRACTION == 0.40, "%s" % ImpactScript.KNOCKBACK_FRACTION)
	_check("impact: EXPLOSION_P0 is 4000 and the window 0.2 s (section 13)",
		ImpactScript.EXPLOSION_P0 == 4000.0 and ImpactScript.EXPLOSION_WINDOW == 0.2,
		"%s / %s" % [ImpactScript.EXPLOSION_P0, ImpactScript.EXPLOSION_WINDOW])
	var wall := ImpactScript.collision_damage(80.0, INF, 450.0)
	_check("impact: the section 16 worked example (80 t, 450 u/s, flat wall) is 162",
		is_equal_approx(wall, 162.0), "%s" % wall)
	var both := ImpactScript.collision_damage(80.0, 560.0, 450.0)
	var reduced := 0.5 * (80.0 * 560.0 / (80.0 + 560.0)) * 450.0 * 450.0 * 2.0e-5
	_check("impact: two bodies use the reduced-mass form and it is symmetric",
		is_equal_approx(both, reduced)
		and is_equal_approx(ImpactScript.collision_damage(560.0, 80.0, 450.0), reduced),
		"%s (reduced-mass %s)" % [both, reduced])
	_check("impact: below COLLISION_MIN_DV nothing is charged",
		ImpactScript.collision_damage(80.0, INF, 39.99) == 0.0)
	_check("impact: knockback is 0.40 of the projectile's remaining KE",
		is_equal_approx(ImpactScript.knockback(100.0, 2.0), 0.40 * 0.5 * 2.0 * 100.0 * 100.0),
		"%s" % ImpactScript.knockback(100.0, 2.0))
	_check("impact: recoil_impulse is projectile_mass x muzzle speed",
		is_equal_approx(ImpactScript.recoil_impulse(1.0, 1000.0), 1000.0))
	_check("impact: I(d) = P0 / (1 + d^2)",
		is_equal_approx(ImpactScript.explosion_impulse(0.0), 4000.0)
		and is_equal_approx(ImpactScript.explosion_impulse(10.0), 4000.0 / 101.0),
		"I(0)=%s I(10)=%s" % [ImpactScript.explosion_impulse(0.0),
		ImpactScript.explosion_impulse(10.0)])


## Section 4.4 / 13's reactor chain numbers on PlayerState.
func _report_pools() -> void:
	var state = StateScript.new()
	_check("pools: FUEL_PER_ENERGY is 0.10 (section 13)",
		StateScript.FUEL_PER_ENERGY == 0.10, "%s" % StateScript.FUEL_PER_ENERGY)
	_check("pools: the emergency reactor penalty is x0.7 (section 13)",
		StateScript.EMERGENCY_REGEN_MULT == 0.7, "%s" % StateScript.EMERGENCY_REGEN_MULT)
	_check("pools: FUEL_CELL_UNITS 40 with a 10 s cooldown (section 13)",
		StateScript.FUEL_CELL_UNITS == 40.0 and StateScript.FUEL_CELL_COOLDOWN == 10.0,
		"%s / %s" % [StateScript.FUEL_CELL_UNITS, StateScript.FUEL_CELL_COOLDOWN])
	_check("pools: the fallback bases are 100 / 200 / 5 per second (section 4.4/13)",
		StateScript.ENERGY_MAX_DEFAULT == 100.0 and StateScript.FUEL_MAX_DEFAULT == 200.0
		and StateScript.ENERGY_REGEN_DEFAULT == 5.0)
	state.setup()
	_check("pools: setup seeds both pools full", state.energy == 100.0 and state.fuel == 200.0,
		"energy=%s fuel=%s" % [state.energy, state.fuel])
	_check("pools: emergency_mode is fuel <= 0 and is read-only",
		state.emergency_mode == false, "mode=%s" % state.emergency_mode)
	state.set_fuel(0.0)
	_check("pools: a dry tank raises the mode", state.emergency_mode == true)
	_check("pools: a dry tank refuses a boost and a dash spend",
		state.try_spend_fuel(3.0) == false and state.try_spend_fuel(25.0) == false)


## Section 13's "Cleaving (ruling 17)" rows and section 6's prose.
func _report_cleaving_consts() -> void:
	_check("cleave: FRAGMENT_SPLIT is L -> 2-3 M, M -> 2 S (section 13)",
		AsteroidScript.FRAGMENT_SPLIT[AsteroidScript.SIZE_LARGE] == Vector2i(2, 3)
		and AsteroidScript.FRAGMENT_SPLIT[AsteroidScript.SIZE_MEDIUM] == Vector2i(2, 2)
		and AsteroidScript.FRAGMENT_SPLIT[AsteroidScript.SIZE_SMALL] == Vector2i(0, 0),
		"%s" % [AsteroidScript.FRAGMENT_SPLIT])
	_check("cleave: a Small bursts 1-2 pickups (section 13)",
		AsteroidScript.PICKUP_BURST == Vector2i(1, 2), "%s" % AsteroidScript.PICKUP_BURST)
	_check("cleave: ejection is x1.2 inside a +-15 deg cone (section 13)",
		AsteroidScript.FRAGMENT_EJECT_MULT == 1.2
		and AsteroidScript.FRAGMENT_EJECT_CONE_DEG == 15.0,
		"%s / %s" % [AsteroidScript.FRAGMENT_EJECT_MULT, AsteroidScript.FRAGMENT_EJECT_CONE_DEG])
	_check("cleave: the rock mass reference row is a section 13 class (miner 140 t x 4)",
		AsteroidScript.ROCK_MASS_MULT == 4.0
		and float(ShipFitScript.HANDLING[AsteroidScript.ROCK_MASS_REFERENCE][&"hull_mass"]) == 140.0,
		"%s x %s" % [AsteroidScript.ROCK_MASS_REFERENCE, AsteroidScript.ROCK_MASS_MULT])


## Section 13's global numbers the hull owns.
func _report_hull_constants() -> void:
	var ship := load("res://game/player_ship.gd") as GDScript
	_check("hull: BRAKE_MULT 1.8 and the 240 / 40 u arrive radii (section 13)",
		ship.BRAKE_MULT == 1.8 and ship.SLOW_DOWN_RADIUS == 240.0
		and ship.ARRIVE_RADIUS == 40.0,
		"%s / %s / %s" % [ship.BRAKE_MULT, ship.SLOW_DOWN_RADIUS, ship.ARRIVE_RADIUS])
	var scene := load("res://game/player_ship.tscn") as PackedScene
	var node := scene.instantiate()
	var body := node.get_node_or_null("HullBody") as RigidBody2D
	_check("scene: HullBody is a RigidBody2D with the pinned contact contract",
		body != null and body.contact_monitor == true
		and body.max_contacts_reported == 4 and body.can_sleep == false,
		"%s" % body)
	_check("scene: the hull body carries no gravity and replaces the damp modes",
		body.gravity_scale == 0.0 and body.linear_damp_mode == 1
		and body.angular_damp_mode == 1)
	node.free()


## 14 section 1 as amended + the owner ruling of 2026-09-21: free, instant, no rate.
func _report_services() -> void:
	var refuel: Dictionary = CatalogScript.service(CatalogScript.SERVICE_REFUEL)
	var recharge: Dictionary = CatalogScript.service(CatalogScript.SERVICE_RECHARGE)
	_check("catalog: the refuel and recharge rows exist and carry no price",
		not refuel.is_empty() and not recharge.is_empty()
		and not refuel.has(&"cost") and not recharge.has(&"cost"),
		"%s / %s" % [refuel.get(&"id"), recharge.get(&"id")])
	_check("catalog: both rows read free + instant at every station",
		refuel.get(&"free") == true and refuel.get(&"instant") == true
		and recharge.get(&"free") == true and recharge.get(&"instant") == true
		and refuel.get(&"availability") == &"all" and recharge.get(&"availability") == &"all")


func _report_persistence() -> void:
	_profile = get_root().get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		_check("persistence: the PlayerProfile autoload resolves", false, "missing")
		return
	_profile.save_path = SCRATCH
	LogScript.log_path = SCRATCH_LOG
	_profile.reset_to_defaults()
	_profile.set_vitals(&"ship_vanguard", 200, 300, 55)
	_profile.flush()
	var credits_before := int(_profile.call(&"credits"))
	var out: Dictionary = RepairsScript.refuel(_profile, &"ship_vanguard")
	var filed: Dictionary = _profile.call(&"vitals_of", &"ship_vanguard")
	_check("refuel: the Cutter's tank is filled to its fuel_max, fee 0",
		out.get(&"ok") == true and int(out.get(&"fee", -1)) == 0
		and int(out.get(&"fuel_max", 0)) == 200 and int(filed.get(&"fuel", -1)) == 200,
		"%s -> %s" % [out, filed])
	_check("refuel: no CR moved and the hull/shield were left alone",
		int(_profile.call(&"credits")) == credits_before
		and int(filed.get(&"hull", -1)) == 200 and int(filed.get(&"shield", -1)) == 300,
		"credits %s -> %s" % [credits_before, _profile.call(&"credits")])
	var again: Dictionary = RepairsScript.refuel(_profile, &"ship_vanguard")
	_check("refuel: a full tank is refused with the documented reason",
		again.get(&"ok") == false and again.get(&"reason") == &"fuel_full", "%s" % again)
	var re: Dictionary = RepairsScript.recharge(_profile, &"ship_vanguard")
	_check("recharge: free, and it reports the pool the launch seeds",
		re.get(&"ok") == true and int(re.get(&"fee", -1)) == 0
		and int(re.get(&"energy_max", 0)) == 100, "%s" % re)
	## The profile writes on a 0.5 s debounce, so the file only carries the refuel
	## after a flush (01 section 6 / 17 section 3 pattern).
	_profile.flush()
	var cfg := ConfigFile.new()
	var err := cfg.load(SCRATCH)
	var version := -1
	var stored: Dictionary = {}
	if err == OK:
		version = int(cfg.get_value(ProfileScript.SECTION, "save_version", -1))
		stored = cfg.get_value(ProfileScript.SECTION, "vitals", {})
	_check("save: the file writes version 3 with the tank in vitals (section 12 item 13)",
		version == 3 and int(stored.get("ship_vanguard", {}).get("fuel", -1)) == 200,
		"version=%s vitals=%s" % [version, stored])
	## A v2 fixture: vitals without a tank must read back as "never filed".
	var legacy := ConfigFile.new()
	legacy.set_value(ProfileScript.SECTION, "save_version", 2)
	legacy.set_value(ProfileScript.SECTION, "credits", 4321)
	legacy.set_value(ProfileScript.SECTION, "vitals", {"ship_vanguard": {"hull": 812, "shield": 300}})
	legacy.save(SCRATCH)
	_profile.reload()
	var migrated: Dictionary = _profile.call(&"vitals_of", &"ship_vanguard")
	_check("save: a v2 profile loads, keeps its credits and files no tank",
		int(_profile.call(&"credits")) == 4321 and int(migrated.get("hull", -1)) == 812
		and not migrated.has("fuel"),
		"credits=%s vitals=%s" % [_profile.call(&"credits"), migrated])
	var after: Dictionary = RepairsScript.refuel(_profile, &"ship_vanguard")
	var refueled: Dictionary = _profile.call(&"vitals_of", &"ship_vanguard")
	_check("save: refueling a migrated profile fills the tank without moving the hull",
		after.get(&"ok") == true and int(refueled.get("fuel", -1)) == 200
		and int(refueled.get("hull", -1)) == 812,
		"%s -> %s" % [after, refueled])
