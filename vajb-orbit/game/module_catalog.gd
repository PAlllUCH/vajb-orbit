class_name ModuleCatalog
extends RefCounted
## The one module catalogue: `id -> {name, slot, draw, tier, cost, icon, effects}`.
## Data, not logic: no nodes, no autoload, no mutation API. The house pattern is
## `MineralCatalog` (02 section 3): one const table plus read-only accessors.
##
## Sources, one each: 09 section 3.1-3.8 (the module ids), 09 sections 3.1-3.8's own
## tables (name, tier, cost -- tier as the project's `int` 1-3, the way
## `MineralCatalog` carries 02 section 2's I-III), 09 section 4 item 7 (`w_mining`'s
## Tier I / draw 1 / 600 CR), and `ShipFit.MODULES` for `slot` / `draw` / `effects`,
## copied **verbatim** (`ShipFit.MODULES` is now the alias reading this table, so
## exactly one literal exists).
##
## Icon rule (CONTRACTS section 11): every id draws
## `res://assets/icons/module/icon_module_<id>_48.png` except the five base weapon
## families, which draw `res://assets/icons/weapon/icon_weapon_<family>_48.png`.
## The rule lives in `icon_path`; each row's `icon` is that same path, and
## `tests/test_ship_grids.gd` asserts the two agree for all 32 ids so the table and
## the rule cannot drift.
##
## Not here: the ammo packs and weapon families (`PlayerState.WEAPONS`,
## `StationCatalog`), module instances and inventory (15 section 6,
## `PlayerProfile`), and every acquisition price flow (10 section 2). A row's `cost`
## is 09 section 3's credits baseline for the auction book, nothing more.

const MODULE_ICON_DIR := "res://assets/icons/module/"
const WEAPON_ICON_DIR := "res://assets/icons/weapon/"
const ICON_SUFFIX := "_48.png"

## The five base weapon families and the weapon-icon stem each one draws. The
## railgun and the mining laser are not here: they have their own module glyphs.
## (`ui/hud/hud.gd:45` names the same five in the same order.)
const WEAPON_ICON_FAMILIES: Dictionary = {
	&"w_laser": "laser",
	&"w_cannon": "cannon",
	&"w_rocket": "rocket",
	&"w_mine": "mine",
	&"w_plasma": "plasma",
}

const MODULES: Dictionary = {
	&"w_laser": {
		&"name": "Laser MkII",
		&"slot": &"weapons",
		&"draw": 1,
		&"tier": 1,
		&"cost": 900,
		&"icon": "res://assets/icons/weapon/icon_weapon_laser_48.png",
		&"effects": {},
	},
	&"w_cannon": {
		&"name": "Cannon MkI",
		&"slot": &"weapons",
		&"draw": 1,
		&"tier": 1,
		&"cost": 1200,
		&"icon": "res://assets/icons/weapon/icon_weapon_cannon_48.png",
		&"effects": {},
	},
	&"w_rocket": {
		&"name": "Rocket Pod",
		&"slot": &"weapons",
		&"draw": 2,
		&"tier": 2,
		&"cost": 2400,
		&"icon": "res://assets/icons/weapon/icon_weapon_rocket_48.png",
		&"effects": {},
	},
	&"w_mine": {
		&"name": "Mine Layer",
		&"slot": &"weapons",
		&"draw": 1,
		&"tier": 2,
		&"cost": 1800,
		&"icon": "res://assets/icons/weapon/icon_weapon_mine_48.png",
		&"effects": {},
	},
	&"w_plasma": {
		&"name": "Plasma Coil",
		&"slot": &"weapons",
		&"draw": 3,
		&"tier": 3,
		&"cost": 4800,
		&"icon": "res://assets/icons/weapon/icon_weapon_plasma_48.png",
		&"effects": {},
	},
	&"w_railgun": {
		&"name": "Railgun",
		&"slot": &"weapons",
		&"draw": 3,
		&"tier": 3,
		&"cost": 5200,
		&"icon": "res://assets/icons/module/icon_module_w_railgun_48.png",
		&"effects": {},
	},
	&"w_mining": {
		&"name": "Mining Laser",
		&"slot": &"weapons",
		&"draw": 1,
		&"tier": 1,
		&"cost": 600,
		&"icon": "res://assets/icons/module/icon_module_w_mining_48.png",
		&"effects": {},
	},
	&"s_light": {
		&"name": "Light Shield",
		&"slot": &"shields",
		&"draw": 2,
		&"tier": 1,
		&"cost": 1400,
		&"icon": "res://assets/icons/module/icon_module_s_light_48.png",
		&"effects": {&"shield_add": 200.0, &"regen_add": 4.0},
	},
	&"s_heavy": {
		&"name": "Heavy Shield",
		&"slot": &"shields",
		&"draw": 3,
		&"tier": 2,
		&"cost": 3200,
		&"icon": "res://assets/icons/module/icon_module_s_heavy_48.png",
		&"effects": {&"shield_add": 400.0, &"regen_add": 5.0},
	},
	&"s_ion": {
		&"name": "Ion Shield",
		&"slot": &"shields",
		&"draw": 3,
		&"tier": 3,
		&"cost": 5600,
		&"icon": "res://assets/icons/module/icon_module_s_ion_48.png",
		&"effects": {&"shield_add": 350.0, &"regen_add": 9.0},
	},
	&"h_plate_light": {
		&"name": "Light Plate",
		&"slot": &"armour",
		&"draw": 0,
		&"tier": 1,
		&"cost": 1100,
		&"icon": "res://assets/icons/module/icon_module_h_plate_light_48.png",
		&"effects": {&"hull_add": 250.0, &"speed_penalty": -0.05},
	},
	&"h_plate_heavy": {
		&"name": "Heavy Plate",
		&"slot": &"armour",
		&"draw": 0,
		&"tier": 2,
		&"cost": 2900,
		&"icon": "res://assets/icons/module/icon_module_h_plate_heavy_48.png",
		&"effects": {&"hull_add": 600.0, &"speed_penalty": -0.12},
	},
	&"h_composite": {
		&"name": "Composite Plate",
		&"slot": &"armour",
		&"draw": 0,
		&"tier": 3,
		&"cost": 5800,
		&"icon": "res://assets/icons/module/icon_module_h_composite_48.png",
		&"effects": {&"hull_add": 1000.0, &"speed_penalty": -0.10, &"mass_add": 0.10},
	},
	&"c_target": {
		&"name": "Targeting Computer",
		&"slot": &"computers",
		&"draw": 1,
		&"tier": 1,
		&"cost": 1600,
		&"icon": "res://assets/icons/module/icon_module_c_target_48.png",
		&"effects": {&"damage_add": 0.15},
	},
	&"c_scanner": {
		&"name": "Deep Scanner",
		&"slot": &"computers",
		&"draw": 1,
		&"tier": 1,
		&"cost": 1500,
		&"icon": "res://assets/icons/module/icon_module_c_scanner_48.png",
		&"effects": {&"scanner_add": 0.25},
	},
	&"c_twin": {
		&"name": "Twin Targeting",
		&"slot": &"computers",
		&"draw": 1,
		&"tier": 2,
		&"cost": 3400,
		&"icon": "res://assets/icons/module/icon_module_c_twin_48.png",
		&"effects": {&"damage_add": 0.15},
	},
	&"c_ewar": {
		&"name": "EWAR Suite",
		&"slot": &"computers",
		&"draw": 1,
		&"tier": 2,
		&"cost": 3800,
		&"icon": "res://assets/icons/module/icon_module_c_ewar_48.png",
		&"effects": {},
	},
	&"c_nexus": {
		&"name": "Nexus Computer",
		&"slot": &"computers",
		&"draw": 1,
		&"tier": 3,
		&"cost": 6400,
		&"icon": "res://assets/icons/module/icon_module_c_nexus_48.png",
		&"effects": {&"damage_add": 0.15, &"scanner_add": 0.25},
	},
	&"b_afterburner": {
		&"name": "Afterburner",
		&"slot": &"boosters",
		&"draw": 2,
		&"tier": 1,
		&"cost": 1900,
		&"icon": "res://assets/icons/module/icon_module_b_afterburner_48.png",
		&"effects": {&"boost_speed_mult": 1.6, &"duration": 3.0, &"cooldown": 8.0},
	},
	&"b_fold": {
		&"name": "Fold Drive",
		&"slot": &"boosters",
		&"draw": 2,
		&"tier": 3,
		&"cost": 6800,
		&"icon": "res://assets/icons/module/icon_module_b_fold_48.png",
		&"effects": {&"blink_distance": 400.0, &"cooldown": 20.0},
	},
	&"u_cargo": {
		&"name": "Cargo Expansion",
		&"slot": &"utility",
		&"draw": 0,
		&"tier": 1,
		&"cost": 1200,
		&"icon": "res://assets/icons/module/icon_module_u_cargo_48.png",
		&"effects": {&"cargo_add": 15},
	},
	&"u_salvage": {
		&"name": "Salvage Tractor",
		&"slot": &"utility",
		&"draw": 0,
		&"tier": 1,
		&"cost": 1000,
		&"icon": "res://assets/icons/module/icon_module_u_salvage_48.png",
		&"effects": {&"tractor_range_mult": 2.0, &"tractor_speed_mult": 2.0},
	},
	&"u_refine": {
		&"name": "Refinery Module",
		&"slot": &"utility",
		&"draw": 1,
		&"tier": 2,
		&"cost": 2600,
		&"icon": "res://assets/icons/module/icon_module_u_refine_48.png",
		&"effects": {},
	},
	&"u_drones": {
		&"name": "Repair Drone Bay",
		&"slot": &"utility",
		&"draw": 1,
		&"tier": 2,
		&"cost": 3000,
		&"icon": "res://assets/icons/module/icon_module_u_drones_48.png",
		&"effects": {},
	},
	&"u_tractor": {
		&"name": "Tractor Array",
		&"slot": &"utility",
		&"draw": 1,
		&"tier": 2,
		&"cost": 2200,
		&"icon": "res://assets/icons/module/icon_module_u_tractor_48.png",
		&"effects": {&"tractor_streams_add": 1},
	},
	&"u_holds": {
		&"name": "Cargo Holds",
		&"slot": &"utility",
		&"draw": 0,
		&"tier": 3,
		&"cost": 4500,
		&"icon": "res://assets/icons/module/icon_module_u_holds_48.png",
		&"effects": {&"cargo_add": 40},
	},
	&"e_std": {
		&"name": "Standard Drive",
		&"slot": &"engine",
		&"draw": 0,
		&"tier": 1,
		&"cost": 800,
		&"icon": "res://assets/icons/module/icon_module_e_std_48.png",
		&"effects": {&"speed_mult": 1.0},
	},
	&"e_ion": {
		&"name": "Ion Drive",
		&"slot": &"engine",
		&"draw": 0,
		&"tier": 2,
		&"cost": 3200,
		&"icon": "res://assets/icons/module/icon_module_e_ion_48.png",
		&"effects": {&"speed_mult": 1.15},
	},
	&"e_vector": {
		&"name": "Vector Drive",
		&"slot": &"engine",
		&"draw": 0,
		&"tier": 3,
		&"cost": 6200,
		&"icon": "res://assets/icons/module/icon_module_e_vector_48.png",
		&"effects": {&"speed_mult": 1.25, &"turn_mult": 1.20},
	},
	&"p_std": {
		&"name": "Standard Reactor",
		&"slot": &"power",
		&"draw": 0,
		&"tier": 1,
		&"cost": 900,
		&"icon": "res://assets/icons/module/icon_module_p_std_48.png",
		&"effects": {&"power_add": 0.0},
	},
	&"p_mk2": {
		&"name": "Reactor Mk2",
		&"slot": &"power",
		&"draw": 0,
		&"tier": 2,
		&"cost": 3600,
		&"icon": "res://assets/icons/module/icon_module_p_mk2_48.png",
		&"effects": {&"power_add": 2.0},
	},
	&"p_core": {
		&"name": "Reactor Core",
		&"slot": &"power",
		&"draw": 0,
		&"tier": 3,
		&"cost": 7000,
		&"icon": "res://assets/icons/module/icon_module_p_core_48.png",
		&"effects": {&"power_add": 4.0},
	},
}


## One module row, or `{}` for an unknown id. The returned dictionary is the
## catalogue's own read-only row: read it, never write to it.
static func module(id: StringName) -> Dictionary:
	var row: Variant = MODULES.get(id, {})
	if row is Dictionary:
		return row
	return {}


## The id's 48 px icon path (CONTRACTS section 11's rule), or `""` when the id is
## not in the catalogue.
static func icon_path(id: StringName) -> String:
	if WEAPON_ICON_FAMILIES.has(id):
		return "%sicon_weapon_%s%s" % [WEAPON_ICON_DIR, WEAPON_ICON_FAMILIES[id], ICON_SUFFIX]
	if not MODULES.has(id):
		return ""
	return "%sicon_module_%s%s" % [MODULE_ICON_DIR, id, ICON_SUFFIX]


## The 09 section 1 slot-type name a module fits in (`&"weapons"`, `&"engine"`,
## ...), or `&""` for an unknown id.
static func slot_of(id: StringName) -> StringName:
	var row := module(id)
	if row.is_empty():
		return &""
	return StringName(row.get(&"slot", &""))
