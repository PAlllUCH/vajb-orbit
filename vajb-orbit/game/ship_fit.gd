class_name ShipFit
extends RefCounted
## Hull + fit -> `ShipStats`, in the 09 section 5 resolution order.
## Sources, one each: 08 section 2 (hull base: structure, shield, cargo, hardpoints,
## power out), ENGINE_SPEC section 13 (per-class handling column, speed scale,
## tractor values), 09 section 3 (module effects and power draws), 09 section 7
## (`STANDARD_FIT`), ENGINE_SPEC section 4.2 / 09 section 3.2 (base shield regen),
## ENGINE_SPEC section 4.1 (lock range = the scanner's range).
## Reduced form (ENGINE_SPEC section 9): v1 resolves the 09 section 7 standard fit;
## the fitting UI and full catalogue are P2 — the `resolve` interface does not change.
## Data, not logic: no nodes, no autoload, no catalogue reads outside these tables.
##
## Interpretation the docs leave open (all reported in the W1 report):
## * Plating multiplies the handling *times* (accel, coast, turn spin-up) by
##   1 + |speed penalty| (ENGINE_SPEC section 3.2); `turn_rate` is a rate, so it
##   moves only with the engine's `turn_mult`.
## * Pools clamp at 3x their own hull base (09 section 5 step 4).
## * Regen is base + the best single shield module value ("best value", 09 section 5).
## * The booster-on-activation speed multiplier is not baked into the snapshot
##   (it depends on whether the booster is firing); `boosters` carries the ids.

const MAX_SPEED_SCALE := 450.0
const SPEED_FLOOR_RATIO := 0.4
const POOL_CEILING_MULT := 3.0
const BASE_SHIELD_REGEN := 2.0
const BASE_SCAN_RANGE := 900.0
const BASE_TRACTOR_RANGE := 120.0
const BASE_TRACTOR_SPEED := 90.0
const BASE_TRACTOR_STREAMS := 1

const SINGLE_SLOT_KEYS: Array[StringName] = [&"engine", &"power"]
const LIST_SLOT_KEYS: Array[StringName] = [
	&"weapons",
	&"shields",
	&"armour",
	&"computers",
	&"boosters",
	&"utility",
]

const HULLS: Dictionary = {
	&"ship_fighter": {
		&"name": "Lancer",
		&"ship_class": "Fighter",
		&"hull": 700.0,
		&"shield": 400.0,
		&"cargo": 25,
		&"weapons": 3,
		&"power_out": 6,
	},
	&"ship_vanguard": {
		&"name": "Vanguard",
		&"ship_class": "Cutter",
		&"hull": 1000.0,
		&"shield": 600.0,
		&"cargo": 40,
		&"weapons": 4,
		&"power_out": 8,
	},
	&"ship_miner": {
		&"name": "Delver",
		&"ship_class": "Miner",
		&"hull": 1100.0,
		&"shield": 500.0,
		&"cargo": 55,
		&"weapons": 2,
		&"power_out": 10,
	},
	&"ship_trader": {
		&"name": "Courier",
		&"ship_class": "Trader",
		&"hull": 950.0,
		&"shield": 550.0,
		&"cargo": 60,
		&"weapons": 1,
		&"power_out": 8,
	},
	&"ship_corvette": {
		&"name": "Spearhead",
		&"ship_class": "Corvette",
		&"hull": 1300.0,
		&"shield": 700.0,
		&"cargo": 35,
		&"weapons": 3,
		&"power_out": 9,
	},
	&"ship_freighter": {
		&"name": "Mule",
		&"ship_class": "Hauler",
		&"hull": 1600.0,
		&"shield": 500.0,
		&"cargo": 120,
		&"weapons": 1,
		&"power_out": 9,
	},
	&"ship_gunship": {
		&"name": "Bulwark",
		&"ship_class": "Gunship",
		&"hull": 1400.0,
		&"shield": 650.0,
		&"cargo": 50,
		&"weapons": 5,
		&"power_out": 11,
	},
	&"ship_patrol": {
		&"name": "Warden",
		&"ship_class": "Frigate",
		&"hull": 1800.0,
		&"shield": 800.0,
		&"cargo": 60,
		&"weapons": 4,
		&"power_out": 12,
	},
	&"ship_destroyer": {
		&"name": "Obliterator",
		&"ship_class": "Destroyer",
		&"hull": 2200.0,
		&"shield": 900.0,
		&"cargo": 80,
		&"weapons": 7,
		&"power_out": 15,
	},
}

## ENGINE_SPEC section 13 handling column; max speed is 08 section 2's base-speed
## percentage x `MAX_SPEED_SCALE`.
const HANDLING: Dictionary = {
	&"ship_fighter": {
		&"max_speed": 450.0,
		&"accel_time": 2.0,
		&"coast_time": 1.6,
		&"turn_rate": 3.4,
		&"turn_spinup": 0.4,
	},
	&"ship_vanguard": {
		&"max_speed": 428.0,
		&"accel_time": 2.4,
		&"coast_time": 2.0,
		&"turn_rate": 3.0,
		&"turn_spinup": 0.5,
	},
	&"ship_miner": {
		&"max_speed": 338.0,
		&"accel_time": 4.0,
		&"coast_time": 3.4,
		&"turn_rate": 2.0,
		&"turn_spinup": 1.0,
	},
	&"ship_trader": {
		&"max_speed": 383.0,
		&"accel_time": 3.0,
		&"coast_time": 2.6,
		&"turn_rate": 2.4,
		&"turn_spinup": 0.7,
	},
	&"ship_corvette": {
		&"max_speed": 495.0,
		&"accel_time": 2.2,
		&"coast_time": 1.8,
		&"turn_rate": 3.2,
		&"turn_spinup": 0.45,
	},
	&"ship_freighter": {
		&"max_speed": 293.0,
		&"accel_time": 6.0,
		&"coast_time": 5.2,
		&"turn_rate": 1.5,
		&"turn_spinup": 1.4,
	},
	&"ship_gunship": {
		&"max_speed": 360.0,
		&"accel_time": 4.4,
		&"coast_time": 3.8,
		&"turn_rate": 1.9,
		&"turn_spinup": 1.0,
	},
	&"ship_patrol": {
		&"max_speed": 383.0,
		&"accel_time": 4.0,
		&"coast_time": 3.4,
		&"turn_rate": 2.1,
		&"turn_spinup": 0.9,
	},
	&"ship_destroyer": {
		&"max_speed": 315.0,
		&"accel_time": 6.4,
		&"coast_time": 5.6,
		&"turn_rate": 1.6,
		&"turn_spinup": 1.2,
	},
}

## 09 section 3 module catalogue, restricted to what a `ShipStats` snapshot needs:
## slot type, power draw (09 section 2 rule: engines are free) and stat effects.
## Acquisition cost stays with 10 section 2 / the P2 fitting panel; weapon damage
## and families are slice 2's concern (ENGINE_SPEC section 4.1).
const MODULES: Dictionary = {
	&"w_laser": {
		&"slot": &"weapons",
		&"draw": 1,
		&"effects": {},
	},
	&"w_cannon": {
		&"slot": &"weapons",
		&"draw": 1,
		&"effects": {},
	},
	&"w_rocket": {
		&"slot": &"weapons",
		&"draw": 2,
		&"effects": {},
	},
	&"w_mine": {
		&"slot": &"weapons",
		&"draw": 1,
		&"effects": {},
	},
	&"w_plasma": {
		&"slot": &"weapons",
		&"draw": 3,
		&"effects": {},
	},
	&"w_railgun": {
		&"slot": &"weapons",
		&"draw": 3,
		&"effects": {},
	},
	&"w_mining": {
		&"slot": &"weapons",
		&"draw": 1,
		&"effects": {},
	},
	&"s_light": {
		&"slot": &"shields",
		&"draw": 2,
		&"effects": {&"shield_add": 200.0, &"regen_add": 4.0},
	},
	&"s_heavy": {
		&"slot": &"shields",
		&"draw": 3,
		&"effects": {&"shield_add": 400.0, &"regen_add": 5.0},
	},
	&"s_ion": {
		&"slot": &"shields",
		&"draw": 3,
		&"effects": {&"shield_add": 350.0, &"regen_add": 9.0},
	},
	&"h_plate_light": {
		&"slot": &"armour",
		&"draw": 0,
		&"effects": {&"hull_add": 250.0, &"speed_penalty": -0.05},
	},
	&"h_plate_heavy": {
		&"slot": &"armour",
		&"draw": 0,
		&"effects": {&"hull_add": 600.0, &"speed_penalty": -0.12},
	},
	&"h_composite": {
		&"slot": &"armour",
		&"draw": 0,
		&"effects": {&"hull_add": 1000.0, &"speed_penalty": -0.10, &"mass_add": 0.10},
	},
	&"c_target": {
		&"slot": &"computers",
		&"draw": 1,
		&"effects": {&"damage_add": 0.15},
	},
	&"c_scanner": {
		&"slot": &"computers",
		&"draw": 1,
		&"effects": {&"scanner_add": 0.25},
	},
	&"c_twin": {
		&"slot": &"computers",
		&"draw": 1,
		&"effects": {&"damage_add": 0.15},
	},
	&"c_ewar": {
		&"slot": &"computers",
		&"draw": 1,
		&"effects": {},
	},
	&"c_nexus": {
		&"slot": &"computers",
		&"draw": 1,
		&"effects": {&"damage_add": 0.15, &"scanner_add": 0.25},
	},
	&"b_afterburner": {
		&"slot": &"boosters",
		&"draw": 2,
		&"effects": {&"boost_speed_mult": 1.6, &"duration": 3.0, &"cooldown": 8.0},
	},
	&"b_fold": {
		&"slot": &"boosters",
		&"draw": 2,
		&"effects": {&"blink_distance": 400.0, &"cooldown": 20.0},
	},
	&"u_cargo": {
		&"slot": &"utility",
		&"draw": 0,
		&"effects": {&"cargo_add": 15},
	},
	&"u_salvage": {
		&"slot": &"utility",
		&"draw": 0,
		&"effects": {&"tractor_range_mult": 2.0, &"tractor_speed_mult": 2.0},
	},
	&"u_refine": {
		&"slot": &"utility",
		&"draw": 1,
		&"effects": {},
	},
	&"u_drones": {
		&"slot": &"utility",
		&"draw": 1,
		&"effects": {},
	},
	&"u_tractor": {
		&"slot": &"utility",
		&"draw": 1,
		&"effects": {&"tractor_streams_add": 1},
	},
	&"u_holds": {
		&"slot": &"utility",
		&"draw": 0,
		&"effects": {&"cargo_add": 40},
	},
	&"e_std": {
		&"slot": &"engine",
		&"draw": 0,
		&"effects": {&"speed_mult": 1.0},
	},
	&"e_ion": {
		&"slot": &"engine",
		&"draw": 0,
		&"effects": {&"speed_mult": 1.15},
	},
	&"e_vector": {
		&"slot": &"engine",
		&"draw": 0,
		&"effects": {&"speed_mult": 1.25, &"turn_mult": 1.20},
	},
	&"p_std": {
		&"slot": &"power",
		&"draw": 0,
		&"effects": {&"power_add": 0.0},
	},
	&"p_mk2": {
		&"slot": &"power",
		&"draw": 0,
		&"effects": {&"power_add": 2.0},
	},
	&"p_core": {
		&"slot": &"power",
		&"draw": 0,
		&"effects": {&"power_add": 4.0},
	},
}

## 09 section 7: the Vanguard's standard fit, included in its price and the only
## fit v1 launches with. Keys are the slot-type names of 09 section 1.
const STANDARD_FIT: Dictionary = {
	&"engine": &"e_std",
	&"power": &"p_std",
	&"weapons": [&"w_laser"],
	&"shields": [&"s_light"],
	&"armour": [&"h_plate_light"],
	&"computers": [],
	&"boosters": [],
	&"utility": [],
}


## Resolve `hull_id` + `fit` into the engine's stats snapshot (09 section 5 order).
## Unknown hulls push an error and return null; an unknown module id pushes a
## warning and is ignored, so a fit referencing a not-yet-implemented module
## still resolves the rest.
static func resolve(hull_id: StringName, fit: Dictionary) -> ShipStats:
	var hull: Dictionary = HULLS.get(hull_id, {})
	var handling: Dictionary = HANDLING.get(hull_id, {})
	if hull.is_empty() or handling.is_empty():
		push_error("ShipFit.resolve: unknown hull id '%s'" % hull_id)
		return null

	var stats := ShipStats.new()
	# 1. Hull base (08 section 2 + ENGINE_SPEC section 13 handling column).
	stats.hull_max = float(hull[&"hull"])
	stats.shield_max = float(hull[&"shield"])
	stats.cargo_max = int(hull[&"cargo"])
	stats.max_speed = float(handling[&"max_speed"])
	stats.accel_time = float(handling[&"accel_time"])
	stats.coast_time = float(handling[&"coast_time"])
	stats.turn_rate = float(handling[&"turn_rate"])
	stats.turn_spinup = float(handling[&"turn_spinup"])
	stats.shield_regen = BASE_SHIELD_REGEN
	stats.damage_mult = 1.0
	stats.scan_range = BASE_SCAN_RANGE
	stats.tractor_range = BASE_TRACTOR_RANGE
	stats.tractor_speed = BASE_TRACTOR_SPEED
	stats.tractor_streams = BASE_TRACTOR_STREAMS

	var ids := fitted_ids(fit)
	_warn_unknown(ids)
	_apply_flat(stats, ids)
	_apply_speed(stats, ids)
	_apply_computers(stats, ids)
	_apply_shields(stats, ids)
	_apply_utility(stats, ids)
	_apply_boosters(stats, ids)
	_clamp(stats, hull, handling)
	stats.lock_range = stats.scan_range
	return stats


## Module ids of a fit in resolution order: the list slots in `LIST_SLOT_KEYS`
## order, then the mandatory singles. Accepts StringName or String keys and
## StringName or String values, so a fit loaded from JSON resolves unchanged.
static func fitted_ids(fit: Dictionary) -> Array[StringName]:
	var ids: Array[StringName] = []
	for key: StringName in LIST_SLOT_KEYS:
		ids.append_array(_list_slot(fit, key))
	for key: StringName in SINGLE_SLOT_KEYS:
		var id := _single_slot(fit, key)
		if id != &"":
			ids.append(id)
	return ids


## 09 section 2 budget: sum of non-ENGINE draws against the hull's 08 section 2
## power out plus the fitted power module. The fitting panel (P2) owns the UI and
## the illegal-fit refusal; this is only the arithmetic it will call.
static func power_budget(hull_id: StringName, fit: Dictionary) -> Dictionary:
	var hull: Dictionary = HULLS.get(hull_id, {})
	if hull.is_empty():
		push_error("ShipFit.power_budget: unknown hull id '%s'" % hull_id)
		return {&"out": 0, &"draw": 0, &"spare": 0, &"legal": false}

	var out := int(hull[&"power_out"])
	var draw := 0
	var ids := fitted_ids(fit)
	_warn_unknown(ids)
	for id: StringName in ids:
		var row := _row(id)
		if row.is_empty():
			continue
		if row[&"slot"] == &"engine":
			continue
		draw += int(row[&"draw"])
		out += int(_effect(row, &"power_add", 0.0))
	return {&"out": out, &"draw": draw, &"spare": out - draw, &"legal": draw <= out}


static func _apply_flat(stats: ShipStats, ids: Array[StringName]) -> void:
	# 09 section 5 step 2: flat module effects (plates, shield pools, cargo units).
	for id: StringName in ids:
		var row := _row(id)
		if row.is_empty():
			continue
		stats.hull_max += _effect(row, &"hull_add", 0.0)
		stats.shield_max += _effect(row, &"shield_add", 0.0)
		stats.cargo_max += int(_effect(row, &"cargo_add", 0.0))


static func _apply_speed(stats: ShipStats, ids: Array[StringName]) -> void:
	# 09 section 5 step 3 order: armour, then engine. Plating pays twice — its
	# 09 section 3.3 speed cost and the handling-time multiplier of ENGINE_SPEC
	# section 3.2 ("slow *and* ponderous").
	for id: StringName in ids:
		var row := _row(id)
		if row.is_empty() or row[&"slot"] != &"armour":
			continue
		var penalty := _effect(row, &"speed_penalty", 0.0)
		stats.max_speed *= 1.0 + penalty
		var mass := 1.0 + absf(penalty)
		stats.accel_time *= mass
		stats.coast_time *= mass
		stats.turn_spinup *= mass
	for id: StringName in ids:
		var row := _row(id)
		if row.is_empty() or row[&"slot"] != &"engine":
			continue
		stats.max_speed *= _effect(row, &"speed_mult", 1.0)
		stats.turn_rate *= _effect(row, &"turn_mult", 1.0)


static func _apply_computers(stats: ShipStats, ids: Array[StringName]) -> void:
	# 09 section 3.4: damage computers stack additively, scanner range takes the
	# best single value.
	var damage_add := 0.0
	var scanner_add := 0.0
	for id: StringName in ids:
		var row := _row(id)
		if row.is_empty() or row[&"slot"] != &"computers":
			continue
		damage_add += _effect(row, &"damage_add", 0.0)
		scanner_add = maxf(scanner_add, _effect(row, &"scanner_add", 0.0))
	stats.damage_mult = 1.0 + damage_add
	stats.scan_range *= 1.0 + scanner_add


static func _apply_shields(stats: ShipStats, ids: Array[StringName]) -> void:
	# 09 section 3.2 + ENGINE_SPEC section 4.2: the 2/s base plus the best single
	# module value.
	var regen_add := 0.0
	for id: StringName in ids:
		var row := _row(id)
		if row.is_empty() or row[&"slot"] != &"shields":
			continue
		regen_add = maxf(regen_add, _effect(row, &"regen_add", 0.0))
	stats.shield_regen = BASE_SHIELD_REGEN + regen_add


static func _apply_utility(stats: ShipStats, ids: Array[StringName]) -> void:
	# 09 section 3.6 tractor gear (pickup behaviour is the pickup's own contract).
	for id: StringName in ids:
		var row := _row(id)
		if row.is_empty() or row[&"slot"] != &"utility":
			continue
		stats.tractor_range *= _effect(row, &"tractor_range_mult", 1.0)
		stats.tractor_speed *= _effect(row, &"tractor_speed_mult", 1.0)
		stats.tractor_streams += int(_effect(row, &"tractor_streams_add", 0.0))


static func _apply_boosters(stats: ShipStats, ids: Array[StringName]) -> void:
	# Ids only: the activation multiplier is not a static stat (see the file doc).
	for id: StringName in ids:
		var row := _row(id)
		if row.is_empty() or row[&"slot"] != &"boosters":
			continue
		stats.boosters.append(id)


static func _clamp(stats: ShipStats, hull: Dictionary, handling: Dictionary) -> void:
	# 09 section 5 step 4: speed never below 40 % of the hull's base, and no pool
	# above 3x its own base.
	stats.max_speed = maxf(
		stats.max_speed, float(handling[&"max_speed"]) * SPEED_FLOOR_RATIO
	)
	stats.hull_max = minf(stats.hull_max, float(hull[&"hull"]) * POOL_CEILING_MULT)
	stats.shield_max = minf(
		stats.shield_max, float(hull[&"shield"]) * POOL_CEILING_MULT
	)


static func _row(id: StringName) -> Dictionary:
	return MODULES.get(id, {})


## One warning per unknown id, not one per resolution pass.
static func _warn_unknown(ids: Array[StringName]) -> void:
	for id: StringName in ids:
		if not MODULES.has(id):
			push_warning("ShipFit: unknown module id '%s' (ignored)" % id)


static func _effect(row: Dictionary, key: StringName, fallback: float) -> float:
	var effects: Dictionary = row.get(&"effects", {})
	return float(effects.get(key, fallback))


static func _list_slot(fit: Dictionary, key: StringName) -> Array[StringName]:
	var ids: Array[StringName] = []
	var raw: Variant = fit.get(key, fit.get(String(key)))
	if raw is Array:
		for entry: Variant in raw as Array:
			var id := StringName(entry)
			if id != &"":
				ids.append(id)
	elif raw is StringName or raw is String:
		if String(raw) != "":
			ids.append(StringName(raw))
	return ids


static func _single_slot(fit: Dictionary, key: StringName) -> StringName:
	var raw: Variant = fit.get(key, fit.get(String(key)))
	if raw is StringName or raw is String:
		return StringName(raw)
	return &""
