extends SceneTree
## Archived source of the W1 acceptance probe (the live copy lived at
## res://tools/_probe_w1_ship_fit.gd and was deleted with its .uid sidecar after
## the run; this file is the re-runnable record). Run it from the project root as
## res://tools/_probe_w1_ship_fit.gd:
##   "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path
##   "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit"
##   --script res://tools/_probe_w1_ship_fit.gd
## Exit code 0 = every check passed (89 checks); 1 = at least one failed.
## It prints every ShipStats field for ShipFit.STANDARD_FIT on the Vanguard and
## asserts the arithmetic derivable from 08 section 2 + 09 sections 3/5/7 +
## ENGINE_SPEC sections 4.2/13, plus the clamp, power-budget and error paths.

const Fit := preload("res://game/ship_fit.gd")
const Catalog := preload("res://game/station_catalog.gd")

const FIELDS: Array[String] = [
	"max_speed",
	"accel_time",
	"coast_time",
	"turn_rate",
	"turn_spinup",
	"hull_max",
	"shield_max",
	"shield_regen",
	"damage_mult",
	"lock_range",
	"scan_range",
	"tractor_range",
	"tractor_speed",
	"tractor_streams",
	"cargo_max",
	"boosters",
]

const ALL_HULLS: Array[StringName] = [
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

var _checks := 0
var _failures := 0


func _initialize() -> void:
	_run()
	print("=== checks %d, failures %d ===" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _run() -> void:
	print("=== W1 probe: ShipFit.resolve ===")
	print("STANDARD_FIT: %s" % str(Fit.STANDARD_FIT))

	print("--- 1. ship_vanguard + STANDARD_FIT ---")
	var standard = Fit.resolve(&"ship_vanguard", Fit.STANDARD_FIT)
	_dump("standard", standard)
	_near("standard max_speed", standard.max_speed, 428.0 * 0.95)
	_near("standard accel_time", standard.accel_time, 2.4 * 1.05)
	_near("standard coast_time", standard.coast_time, 2.0 * 1.05)
	_near("standard turn_spinup", standard.turn_spinup, 0.5 * 1.05)
	_near("standard turn_rate", standard.turn_rate, 3.0)
	_near("standard hull_max", standard.hull_max, 1000.0 + 250.0)
	_near("standard shield_max", standard.shield_max, 600.0 + 200.0)
	_near("standard shield_regen", standard.shield_regen, 2.0 + 4.0)
	_near("standard damage_mult", standard.damage_mult, 1.0)
	_near("standard scan_range", standard.scan_range, 900.0)
	_near("standard lock_range", standard.lock_range, standard.scan_range)
	_near("standard tractor_range", standard.tractor_range, 120.0)
	_near("standard tractor_speed", standard.tractor_speed, 90.0)
	_eq("standard tractor_streams", standard.tractor_streams, 1)
	_eq("standard cargo_max", standard.cargo_max, 40)
	_eq("standard boosters", standard.boosters, [])

	print("--- 2. two h_plate_light (compounded mass) ---")
	var twin := Fit.STANDARD_FIT.duplicate(true)
	twin[&"armour"] = [&"h_plate_light", &"h_plate_light"]
	var plated = Fit.resolve(&"ship_vanguard", twin)
	_dump("two plates", plated)
	_near("two plates hull_max", plated.hull_max, 1000.0 + 500.0)
	_near("two plates speed", plated.max_speed, 428.0 * 0.95 * 0.95)
	_near("two plates speed factor", plated.max_speed / 428.0, 0.9025)
	print("handling multiplier 1.05*1.05 = %.4f" % (1.05 * 1.05))
	_near("two plates handling factor", plated.accel_time / 2.4, 1.05 * 1.05)
	_near("two plates accel_time", plated.accel_time, 2.4 * 1.05 * 1.05)
	_near("two plates coast_time", plated.coast_time, 2.0 * 1.1025)
	_near("two plates turn_spinup", plated.turn_spinup, 0.5 * 1.1025)
	_near("two plates turn_rate", plated.turn_rate, 3.0)

	print("--- 3. every hull + STANDARD_FIT vs ENGINE_SPEC 13 ---")
	for hull_id: StringName in ALL_HULLS:
		var stats = Fit.resolve(hull_id, Fit.STANDARD_FIT)
		var base: float = float(Fit.HANDLING[hull_id][&"max_speed"])
		print(
			"%-16s base %6.1f -> %8.3f (x0.95)  accel %.3f  hull %.1f  cargo %d"
			% [hull_id, base, stats.max_speed, stats.accel_time, stats.hull_max, stats.cargo_max]
		)
		_near("%s speed" % hull_id, stats.max_speed, base * 0.95)
		_near("%s accel" % hull_id, stats.accel_time, float(Fit.HANDLING[hull_id][&"accel_time"]) * 1.05)

	print("--- 4. full synthetic fit (engine, computers, booster, utility) ---")
	var synthetic: Dictionary = {
		&"engine": &"e_vector",
		&"power": &"p_std",
		&"weapons": [&"w_laser"],
		&"shields": [&"s_light"],
		&"armour": [&"h_plate_heavy"],
		&"computers": [&"c_target", &"c_twin", &"c_scanner", &"c_nexus"],
		&"boosters": [&"b_afterburner"],
		&"utility": [&"u_cargo", &"u_holds", &"u_salvage", &"u_tractor"],
	}
	var loaded = Fit.resolve(&"ship_vanguard", synthetic)
	_dump("synthetic", loaded)
	_near("synthetic speed", loaded.max_speed, 428.0 * 0.88 * 1.25)
	_near("synthetic accel", loaded.accel_time, 2.4 * 1.12)
	_near("synthetic turn", loaded.turn_rate, 3.0 * 1.20)
	_near("synthetic hull", loaded.hull_max, 1000.0 + 600.0)
	_near("synthetic damage_mult", loaded.damage_mult, 1.0 + 0.15 * 3)
	_near("synthetic scan_range (best value)", loaded.scan_range, 900.0 * 1.25)
	_near("synthetic lock_range", loaded.lock_range, 1125.0)
	_eq("synthetic cargo", loaded.cargo_max, 40 + 15 + 40)
	_near("synthetic tractor_range", loaded.tractor_range, 240.0)
	_near("synthetic tractor_speed", loaded.tractor_speed, 180.0)
	_eq("synthetic tractor_streams", loaded.tractor_streams, 2)
	_eq("synthetic boosters", loaded.boosters, [&"b_afterburner"])
	_eq(
		"synthetic w_mining/w_railgun resolve",
		Fit.resolve(
			&"ship_miner", {&"engine": &"e_std", &"power": &"p_std", &"weapons": [&"w_mining", &"w_railgun"]}
		).cargo_max,
		55
	)
	_check_dict("power_budget standard", Fit.power_budget(&"ship_vanguard", Fit.STANDARD_FIT), 8, 3, true)
	_check_dict("power_budget synthetic", Fit.power_budget(&"ship_vanguard", synthetic), 8, 10, false)
	var upgraded := synthetic.duplicate(true)
	upgraded[&"power"] = &"p_core"
	_check_dict("power_budget p_core", Fit.power_budget(&"ship_vanguard", upgraded), 12, 10, true)

	print("--- 5. clamps (illegal by slot count; arithmetic only) ---")
	var heavy: Dictionary = {&"engine": &"e_std", &"power": &"p_std", &"armour": []}
	for i in 8:
		heavy[&"armour"].append(&"h_plate_heavy")
	var heavy_stats = Fit.resolve(&"ship_destroyer", heavy)
	print(
		"destroyer 8x h_plate_heavy: speed %.3f (raw %.3f, floor %.3f) accel %.4f"
		% [
			heavy_stats.max_speed,
			315.0 * pow(0.88, 8),
			315.0 * Fit.SPEED_FLOOR_RATIO,
			heavy_stats.accel_time,
		]
	)
	_near("speed floor", heavy_stats.max_speed, 315.0 * Fit.SPEED_FLOOR_RATIO)
	var megashield: Dictionary = {&"engine": &"e_std", &"power": &"p_std", &"shields": []}
	for i in 9:
		megashield[&"shields"].append(&"s_ion")
	var shield_stats = Fit.resolve(&"ship_vanguard", megashield)
	print(
		"vanguard 9x s_ion: shield %.1f (raw %.1f, ceiling %.1f) regen %.1f"
		% [shield_stats.shield_max, 600.0 + 9.0 * 350.0, 600.0 * 3.0, shield_stats.shield_regen]
	)
	_near("shield ceiling", shield_stats.shield_max, 1800.0)
	_near("regen best value", shield_stats.shield_regen, 2.0 + 9.0)

	print("--- 6. error paths ---")
	var bogus = Fit.resolve(&"ship_vanguard", {&"engine": &"e_std", &"power": &"p_std", &"weapons": [&"w_bogus"]})
	_eq("unknown module ignored", bogus.cargo_max, 40)
	_near("unknown module does not change hull", bogus.hull_max, 1000.0)
	var unknown = Fit.resolve(&"ship_nope", Fit.STANDARD_FIT)
	_eq("unknown hull -> null", unknown == null, true)

	print("--- 7. StationCatalog.SHIPS cross-check ---")
	for hull_id: StringName in ALL_HULLS:
		var row: Dictionary = Catalog.ship(hull_id)
		var stats = Fit.resolve(hull_id, {&"engine": &"e_std", &"power": &"p_std"})
		if row.is_empty():
			print("%-16s not in StationCatalog.SHIPS (hull file: %s)" % [hull_id, Fit.HULLS[hull_id][&"name"]])
			continue
		_eq("%s hull agrees" % hull_id, int(stats.hull_max), int(row[&"hull"]))
		_eq("%s shield agrees" % hull_id, int(stats.shield_max), int(row[&"shield"]))
		_eq("%s cargo agrees" % hull_id, stats.cargo_max, int(row[&"cargo"]))
		_eq("%s hardpoints agree" % hull_id, int(Fit.HULLS[hull_id][&"weapons"]), int(row[&"hardpoints"]))


func _dump(label: String, stats) -> void:
	print("[%s]" % label)
	for field: String in FIELDS:
		print("  %-16s %s" % [field, str(stats.get(field))])


func _near(label: String, actual: float, expected: float, tolerance := 0.0001) -> void:
	_checks += 1
	if absf(actual - expected) > tolerance:
		_failures += 1
		print("FAIL %s: %s != %s" % [label, str(actual), str(expected)])


func _eq(label: String, actual: Variant, expected: Variant) -> void:
	_checks += 1
	if str(actual) != str(expected):
		_failures += 1
		print("FAIL %s: %s != %s" % [label, str(actual), str(expected)])


func _check_dict(label: String, budget: Dictionary, out: int, draw: int, legal: bool) -> void:
	print("%s: %s" % [label, str(budget)])
	_eq("%s out" % label, budget[&"out"], out)
	_eq("%s draw" % label, budget[&"draw"], draw)
	_eq("%s spare" % label, budget[&"spare"], out - draw)
	_eq("%s legal" % label, budget[&"legal"], legal)
