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
## `tests/test_ship_grids.gd` asserts the two agree for all 35 ids so the table and
## the rule cannot drift. **Amended 2026-09-22 (S3):** the .svg masters of the
## 2026-09-22 unification are the shipped form, and 15 section 9.1's three
## exclusives draw an existing file instead of a line of their own, so `icon_path`
## answers them from `ICON_REUSE` first.
##
## S3 additions (2026-09-22, CONTRACTS section 15): 15 section 9.1's three
## exclusive rows (the two weapons and the vault utility), 15 section 1's rarity
## contract (`RARITY_*`, `RARITY_MULT_PERMILLE`) with the price helpers the AUCTION
## shelf prices by (`list_price`, `sell_price`, `hot_price`), and the roll tables of
## 15 section 2 (`SOURCE_ROLLS`), section 3 (`PREFIXES`) and section 4 (`SUFFIXES`)
## with the rolls over them (`roll_rarity`, `roll_affixes`). The rolls read the
## global RNG and are the **creation** step only: nothing here is applied to a
## flight stat (15 section 9.3).
##
## Not here: the ammo packs and weapon families (`PlayerState.WEAPONS`,
## `StationCatalog`), module instances and inventory (15 section 6,
## `PlayerProfile`), and every acquisition price flow (10 section 2). A row's `cost`
## is 09 section 3's credits baseline for the auction book, nothing more.

const MODULE_ICON_DIR := "res://assets/icons/module/"
const WEAPON_ICON_DIR := "res://assets/icons/weapon/"
const ICON_SUFFIX := ".svg"

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

## 15 section 9.1: the three faction exclusives draw an existing file rather than a
## master of their own, so the frozen `assets/` tree gains nothing. The railgun
## shares the two weapons' family silhouette (16 section 3) and `u_vault` takes the
## service vault glyph, the reuse precedent STATION_HUB section 7.1 records.
const ICON_REUSE: Dictionary = {
	&"w_proton": "res://assets/icons/module/icon_module_w_railgun.svg",
	&"w_flak": "res://assets/icons/module/icon_module_w_railgun.svg",
	&"u_vault": "res://assets/icons/service/icon_service_vault.svg",
}

## 09 section 1's slot-type keys and the catalogue's own spelling of the engine
## type: a row says `engine` (the spelling `ShipFit` resolves), the eight fitting
## keys say `engines`. `fit_slot_of` is the one bridge, so a prefix's family and a
## module's own slot are compared in one currency.
const SLOT_ALIASES: Dictionary = {&"engine": &"engines"}

## 15 section 1's rarity contract: the three ids a record's `rarity` carries, the
## order they escalate in (used by `affix_count` and the exclusives' floor), and the
## value each one multiplies a 09 list price by. Permille integers keep the price
## arithmetic exact: every 09 and 15 cost is a multiple of 100, so x1.0 / x1.6 /
## x2.6 and the 60 % sell-back need no rounding rule (CONTRACTS section 15).
const RARITY_COMMON := "common"
const RARITY_MAGIC := "magic"
const RARITY_RARE := "rare"
const RARITY_ORDER: Array[String] = [RARITY_COMMON, RARITY_MAGIC, RARITY_RARE]
const RARITY_MULT_PERMILLE: Dictionary = {
	"common": 1000,
	"magic": 1600,
	"rare": 2600,
}

## 15 section 6 / 10 section 2.3: the garage-sale share of the rarity price.
const SELL_PERCENT := 60
## 10 section 2.1: the one hot slot's discount, applied after the rarity step.
const HOT_DISCOUNT_PERCENT := 20

## 15 section 2's source tables, one row per place an instance can be created.
## `shipyard` is 100 % Common ("building is reliable, not lucky"); `derelict` has no
## Common at all. `faction_lot` is 15 section 9.2's proposed split for 15 section 8's
## interim F lot: section 2's own 30:5 auction ratio renormalised over the two
## rarities that are legal for an exclusive (30/35, 5/35).
const SOURCE_AUCTION: StringName = &"auction"
const SOURCE_SHIPYARD: StringName = &"shipyard"
const SOURCE_DROP: StringName = &"drop"
const SOURCE_ARENA: StringName = &"arena"
const SOURCE_DERELICT: StringName = &"derelict"
const SOURCE_CRAFTING: StringName = &"crafting"
const SOURCE_FACTION_LOT: StringName = &"faction_lot"
const SOURCE_ROLLS: Dictionary = {
	&"auction": {&"common": 65, &"magic": 30, &"rare": 5},
	&"shipyard": {&"common": 100, &"magic": 0, &"rare": 0},
	&"drop": {&"common": 70, &"magic": 25, &"rare": 5},
	&"arena": {&"common": 20, &"magic": 40, &"rare": 40},
	&"derelict": {&"common": 0, &"magic": 75, &"rare": 25},
	&"crafting": {&"common": 40, &"magic": 45, &"rare": 15},
	&"faction_lot": {&"common": 0, &"magic": 85, &"rare": 15},
}

## 15 section 5's three faction exclusives and the faction each one belongs to
## (12 section 1: the owner ids `SectorRegistry` already spells as `choir`,
## `concord` and `meridian`). Their floor is Magic (15 section 5: "Exclusives never
## spawn Common"), the one clamp `roll_rarity` applies.
const EXCLUSIVES: Dictionary = {
	&"w_proton": &"choir",
	&"w_flak": &"concord",
	&"u_vault": &"meridian",
}
const EXCLUSIVE_FLOOR := RARITY_MAGIC

## 15 section 3's twelve prefix rows, verbatim: the family each one may roll on
## (09 section 1's slot keys, in `fit_slot_of`'s spelling), the stat it bends, the
## unit its value is written in, and the band's three tier columns (T1/T2/T3:
## "T1 modules roll low, T3 roll high"). Nothing is applied anywhere in S3: the
## rows are rolled, stored, priced, named and displayed (15 section 9.3).
const PREFIXES: Dictionary = {
	&"sturdy": {
		&"name": "Sturdy",
		&"slot": &"shields",
		&"stat": &"shield_add",
		&"unit": &"percent",
		&"band": [0.10, 0.15, 0.20],
	},
	&"vigilant": {
		&"name": "Vigilant",
		&"slot": &"shields",
		&"stat": &"regen_add",
		&"unit": &"percent",
		&"band": [0.15, 0.25, 0.35],
	},
	&"keen": {
		&"name": "Keen",
		&"slot": &"weapons",
		&"stat": &"damage_add",
		&"unit": &"percent",
		&"band": [0.08, 0.12, 0.16],
	},
	&"rapid": {
		&"name": "Rapid",
		&"slot": &"weapons",
		&"stat": &"fire_rate_mult",
		&"unit": &"percent",
		&"band": [0.08, 0.12, 0.16],
	},
	&"frugal": {
		&"name": "Frugal",
		&"slot": &"weapons",
		&"stat": &"ammo_mult",
		&"unit": &"percent",
		&"band": [-0.15, -0.20, -0.25],
	},
	&"lightened": {
		&"name": "Lightened",
		&"slot": &"armour",
		&"stat": &"speed_penalty",
		&"unit": &"points",
		&"band": [-0.04, -0.06, -0.08],
	},
	&"tempered": {
		&"name": "Tempered",
		&"slot": &"engines",
		&"stat": &"speed_mult",
		&"unit": &"percent",
		&"band": [0.05, 0.08, 0.12],
	},
	&"overflowing": {
		&"name": "Overflowing",
		&"slot": &"power",
		&"stat": &"power_add",
		&"unit": &"units",
		&"band": [1.0, 1.0, 2.0],
	},
	&"wideband": {
		&"name": "Wideband",
		&"slot": &"computers",
		&"stat": &"scanner_add",
		&"unit": &"percent",
		&"band": [0.15, 0.20, 0.25],
	},
	&"surefire": {
		&"name": "Surefire",
		&"slot": &"computers",
		&"stat": &"damage_add",
		&"unit": &"percent",
		&"band": [0.05, 0.08, 0.10],
	},
	&"spry": {
		&"name": "Spry",
		&"slot": &"boosters",
		&"stat": &"cooldown_mult",
		&"unit": &"percent",
		&"band": [-0.15, -0.20, -0.25],
	},
	&"deep_hold": {
		&"name": "Deep-hold",
		&"slot": &"utility",
		&"stat": &"cargo_add",
		&"unit": &"units",
		&"band": [5.0, 8.0, 12.0],
	},
}

## 15 section 4's ten suffix rows, verbatim: the display spelling, the perk line the
## UI shows (15 section 9.3: named and displayed, applied by nothing in S3), and the
## faction a bound one rolls in (`&""` = rolls anywhere). Three are bound (`of the
## Choir`, `of the Concord`, `of the Ports`), so they only reach a pool whose
## faction is their own.
const SUFFIXES: Dictionary = {
	&"whale": {
		&"name": "of the Whale",
		&"perk": "+50 max hull structure",
		&"faction": &"",
	},
	&"embers": {
		&"name": "of Embers",
		&"perk": "10 % of damage dealt returns as shield",
		&"faction": &"",
	},
	&"ledger": {&"name": "of the Ledger", &"perk": "sell value +25 %", &"faction": &""},
	&"silence": {
		&"name": "of Silence",
		&"perk": "hunters take 2x time to detect you (13 section 3)",
		&"faction": &"",
	},
	&"cartograph": {
		&"name": "of the Cartograph",
		&"perk": "reveals sector POIs without scanning (11 section 3.3)",
		&"faction": &"",
	},
	&"leeches": {&"name": "of Leeches", &"perk": "kills restore 5 % hull", &"faction": &""},
	&"vault": {
		&"name": "of the Vault",
		&"perk": "cargo spill on death -50 % (insurance-adjacent)",
		&"faction": &"",
	},
	&"choir": {&"name": "of the Choir", &"perk": "+1 power output", &"faction": &"choir"},
	&"concord": {&"name": "of the Concord", &"perk": "+5 % armour effect", &"faction": &"concord"},
	&"ports": {&"name": "of the Ports", &"perk": "+10 % booster duration", &"faction": &"meridian"},
}

const MODULES: Dictionary = {
	&"w_laser": {
		&"name": "Laser MkII",
		&"slot": &"weapons",
		&"draw": 1,
		&"tier": 1,
		&"cost": 900,
		&"icon": "res://assets/icons/weapon/icon_weapon_laser.svg",
		&"effects": {},
	},
	&"w_cannon": {
		&"name": "Cannon MkI",
		&"slot": &"weapons",
		&"draw": 1,
		&"tier": 1,
		&"cost": 1200,
		&"icon": "res://assets/icons/weapon/icon_weapon_cannon.svg",
		&"effects": {},
	},
	&"w_rocket": {
		&"name": "Rocket Pod",
		&"slot": &"weapons",
		&"draw": 2,
		&"tier": 2,
		&"cost": 2400,
		&"icon": "res://assets/icons/weapon/icon_weapon_rocket.svg",
		&"effects": {},
	},
	&"w_mine": {
		&"name": "Mine Layer",
		&"slot": &"weapons",
		&"draw": 1,
		&"tier": 2,
		&"cost": 1800,
		&"icon": "res://assets/icons/weapon/icon_weapon_mine.svg",
		&"effects": {},
	},
	&"w_plasma": {
		&"name": "Plasma Coil",
		&"slot": &"weapons",
		&"draw": 3,
		&"tier": 3,
		&"cost": 4800,
		&"icon": "res://assets/icons/weapon/icon_weapon_plasma.svg",
		&"effects": {},
	},
	&"w_railgun": {
		&"name": "Railgun",
		&"slot": &"weapons",
		&"draw": 3,
		&"tier": 3,
		&"cost": 5200,
		&"icon": "res://assets/icons/module/icon_module_w_railgun.svg",
		&"effects": {},
	},
	&"w_mining": {
		&"name": "Mining Laser",
		&"slot": &"weapons",
		&"draw": 1,
		&"tier": 1,
		&"cost": 600,
		&"icon": "res://assets/icons/module/icon_module_w_mining.svg",
		&"effects": {},
	},
	## 15 section 9.1's two exclusive weapons: their family's tier-III top line
	## (`w_railgun`'s draw 3 / 5 200), no `effects` dict (no weapon row carries one),
	## and the railgun's own glyph. A fitted one fires nothing yet -- no `weapons.gd`
	## `FAMILIES` entry -- which is the status `u_refine`, `u_drones` and `c_ewar`
	## already ship with (15 section 9.1, owner tick).
	&"w_proton": {
		&"name": "Proton Missile Launcher",
		&"slot": &"weapons",
		&"draw": 3,
		&"tier": 3,
		&"cost": 5200,
		&"icon": "res://assets/icons/module/icon_module_w_railgun.svg",
		&"effects": {},
	},
	&"w_flak": {
		&"name": "Flak Battery",
		&"slot": &"weapons",
		&"draw": 3,
		&"tier": 3,
		&"cost": 5200,
		&"icon": "res://assets/icons/module/icon_module_w_railgun.svg",
		&"effects": {},
	},
	&"s_light": {
		&"name": "Light Shield",
		&"slot": &"shields",
		&"draw": 2,
		&"tier": 1,
		&"cost": 1400,
		&"icon": "res://assets/icons/module/icon_module_s_light.svg",
		&"effects": {&"shield_add": 200.0, &"regen_add": 4.0},
	},
	&"s_heavy": {
		&"name": "Heavy Shield",
		&"slot": &"shields",
		&"draw": 3,
		&"tier": 2,
		&"cost": 3200,
		&"icon": "res://assets/icons/module/icon_module_s_heavy.svg",
		&"effects": {&"shield_add": 400.0, &"regen_add": 5.0},
	},
	&"s_ion": {
		&"name": "Ion Shield",
		&"slot": &"shields",
		&"draw": 3,
		&"tier": 3,
		&"cost": 5600,
		&"icon": "res://assets/icons/module/icon_module_s_ion.svg",
		&"effects": {&"shield_add": 350.0, &"regen_add": 9.0},
	},
	&"h_plate_light": {
		&"name": "Light Plate",
		&"slot": &"armour",
		&"draw": 0,
		&"tier": 1,
		&"cost": 1100,
		&"icon": "res://assets/icons/module/icon_module_h_plate_light.svg",
		&"effects": {&"hull_add": 250.0, &"speed_penalty": -0.05},
	},
	&"h_plate_heavy": {
		&"name": "Heavy Plate",
		&"slot": &"armour",
		&"draw": 0,
		&"tier": 2,
		&"cost": 2900,
		&"icon": "res://assets/icons/module/icon_module_h_plate_heavy.svg",
		&"effects": {&"hull_add": 600.0, &"speed_penalty": -0.12},
	},
	&"h_composite": {
		&"name": "Composite Plate",
		&"slot": &"armour",
		&"draw": 0,
		&"tier": 3,
		&"cost": 5800,
		&"icon": "res://assets/icons/module/icon_module_h_composite.svg",
		&"effects": {&"hull_add": 1000.0, &"speed_penalty": -0.10, &"mass_add": 0.10},
	},
	&"c_target": {
		&"name": "Targeting Computer",
		&"slot": &"computers",
		&"draw": 1,
		&"tier": 1,
		&"cost": 1600,
		&"icon": "res://assets/icons/module/icon_module_c_target.svg",
		&"effects": {&"damage_add": 0.15},
	},
	&"c_scanner": {
		&"name": "Deep Scanner",
		&"slot": &"computers",
		&"draw": 1,
		&"tier": 1,
		&"cost": 1500,
		&"icon": "res://assets/icons/module/icon_module_c_scanner.svg",
		&"effects": {&"scanner_add": 0.25},
	},
	&"c_twin": {
		&"name": "Twin Targeting",
		&"slot": &"computers",
		&"draw": 1,
		&"tier": 2,
		&"cost": 3400,
		&"icon": "res://assets/icons/module/icon_module_c_twin.svg",
		&"effects": {&"damage_add": 0.15},
	},
	&"c_ewar": {
		&"name": "EWAR Suite",
		&"slot": &"computers",
		&"draw": 1,
		&"tier": 2,
		&"cost": 3800,
		&"icon": "res://assets/icons/module/icon_module_c_ewar.svg",
		&"effects": {},
	},
	&"c_nexus": {
		&"name": "Nexus Computer",
		&"slot": &"computers",
		&"draw": 1,
		&"tier": 3,
		&"cost": 6400,
		&"icon": "res://assets/icons/module/icon_module_c_nexus.svg",
		&"effects": {&"damage_add": 0.15, &"scanner_add": 0.25},
	},
	&"b_afterburner": {
		&"name": "Afterburner",
		&"slot": &"boosters",
		&"draw": 2,
		&"tier": 1,
		&"cost": 1900,
		&"icon": "res://assets/icons/module/icon_module_b_afterburner.svg",
		&"effects": {&"boost_speed_mult": 1.6, &"duration": 3.0, &"cooldown": 8.0},
	},
	&"b_fold": {
		&"name": "Fold Drive",
		&"slot": &"boosters",
		&"draw": 2,
		&"tier": 3,
		&"cost": 6800,
		&"icon": "res://assets/icons/module/icon_module_b_fold.svg",
		&"effects": {&"blink_distance": 400.0, &"cooldown": 20.0},
	},
	&"u_cargo": {
		&"name": "Cargo Expansion",
		&"slot": &"utility",
		&"draw": 0,
		&"tier": 1,
		&"cost": 1200,
		&"icon": "res://assets/icons/module/icon_module_u_cargo.svg",
		&"effects": {&"cargo_add": 15},
	},
	&"u_salvage": {
		&"name": "Salvage Tractor",
		&"slot": &"utility",
		&"draw": 0,
		&"tier": 1,
		&"cost": 1000,
		&"icon": "res://assets/icons/module/icon_module_u_salvage.svg",
		&"effects": {&"tractor_range_mult": 2.0, &"tractor_speed_mult": 2.0},
	},
	&"u_refine": {
		&"name": "Refinery Module",
		&"slot": &"utility",
		&"draw": 1,
		&"tier": 2,
		&"cost": 2600,
		&"icon": "res://assets/icons/module/icon_module_u_refine.svg",
		&"effects": {},
	},
	&"u_drones": {
		&"name": "Repair Drone Bay",
		&"slot": &"utility",
		&"draw": 1,
		&"tier": 2,
		&"cost": 3000,
		&"icon": "res://assets/icons/module/icon_module_u_drones.svg",
		&"effects": {},
	},
	&"u_tractor": {
		&"name": "Tractor Array",
		&"slot": &"utility",
		&"draw": 1,
		&"tier": 2,
		&"cost": 2200,
		&"icon": "res://assets/icons/module/icon_module_u_tractor.svg",
		&"effects": {&"tractor_streams_add": 1},
	},
	&"u_holds": {
		&"name": "Cargo Holds",
		&"slot": &"utility",
		&"draw": 0,
		&"tier": 3,
		&"cost": 4500,
		&"icon": "res://assets/icons/module/icon_module_u_holds.svg",
		&"effects": {&"cargo_add": 40},
	},
	## 15 section 9.1's exclusive utility: `u_holds`'s tier-III top line (draw 0 /
	## 4 500) with 14 section 4's own `vault_add` effect, and the service vault glyph.
	&"u_vault": {
		&"name": "Station Vault Access",
		&"slot": &"utility",
		&"draw": 0,
		&"tier": 3,
		&"cost": 4500,
		&"icon": "res://assets/icons/service/icon_service_vault.svg",
		&"effects": {&"vault_add": 20},
	},
	&"e_std": {
		&"name": "Standard Drive",
		&"slot": &"engine",
		&"draw": 0,
		&"tier": 1,
		&"cost": 800,
		&"icon": "res://assets/icons/module/icon_module_e_std.svg",
		&"effects": {&"speed_mult": 1.0},
	},
	&"e_ion": {
		&"name": "Ion Drive",
		&"slot": &"engine",
		&"draw": 0,
		&"tier": 2,
		&"cost": 3200,
		&"icon": "res://assets/icons/module/icon_module_e_ion.svg",
		&"effects": {&"speed_mult": 1.15},
	},
	&"e_vector": {
		&"name": "Vector Drive",
		&"slot": &"engine",
		&"draw": 0,
		&"tier": 3,
		&"cost": 6200,
		&"icon": "res://assets/icons/module/icon_module_e_vector.svg",
		&"effects": {&"speed_mult": 1.25, &"turn_mult": 1.20},
	},
	&"p_std": {
		&"name": "Standard Reactor",
		&"slot": &"power",
		&"draw": 0,
		&"tier": 1,
		&"cost": 900,
		&"icon": "res://assets/icons/module/icon_module_p_std.svg",
		&"effects": {&"power_add": 0.0},
	},
	&"p_mk2": {
		&"name": "Reactor Mk2",
		&"slot": &"power",
		&"draw": 0,
		&"tier": 2,
		&"cost": 3600,
		&"icon": "res://assets/icons/module/icon_module_p_mk2.svg",
		&"effects": {&"power_add": 2.0},
	},
	&"p_core": {
		&"name": "Reactor Core",
		&"slot": &"power",
		&"draw": 0,
		&"tier": 3,
		&"cost": 7000,
		&"icon": "res://assets/icons/module/icon_module_p_core.svg",
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
## not in the catalogue. The three exclusives come first: 15 section 9.1 gives them
## an existing file rather than a master of their own, so the rule cannot name them
## (`ICON_REUSE`).
static func icon_path(id: StringName) -> String:
	if ICON_REUSE.has(id):
		return ICON_REUSE[id]
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


## The same slot in the eight `ShipFit.FIT_SLOT_KEYS`' spelling: `engine` becomes
## `engines` (the catalogue row's own word for the type, 09 section 3.7), every
## other slot is already shared. `&""` for an unknown id.
static func fit_slot_of(id: StringName) -> StringName:
	var slot := slot_of(id)
	return StringName(SLOT_ALIASES.get(slot, slot))


## The rarity multiplier for a 09 list price (15 section 1), 1.0 for an unknown
## rarity so a caller's arithmetic degrades to the plain price rather than to zero.
static func rarity_mult(rarity: StringName) -> float:
	return float(RARITY_MULT_PERMILLE.get(String(rarity), 1000)) / 1000.0


## 09 section 3's list price with 15 section 1's rarity multiplier applied: the
## number the AUCTION shelf shows before 10 section 2.1's hot-slot discount.
## `0` for an id the catalogue does not ship, the one answer that cannot be
## mistaken for a price. Integer arithmetic on `RARITY_MULT_PERMILLE`: every 09 and
## 15 cost is a multiple of 100, so x1.6 and x2.6 are exact (CONTRACTS section 15).
static func list_price(base_id: StringName, rarity: StringName) -> int:
	var row := module(base_id)
	if row.is_empty():
		return 0
	var cost := int(row.get(&"cost", 0))
	if cost <= 0:
		return 0
	return cost * int(RARITY_MULT_PERMILLE.get(String(rarity), 1000)) / 1000


## 15 section 6 / 10 section 2.3's sell-back: `base x rarity x 60 %`, with no suffix
## term (`of the Ledger` is displayed, never applied -- 15 section 9.3). `0` for an
## id the catalogue does not ship, so the profile refuses a sale it cannot price.
static func sell_price(base_id: StringName, rarity: StringName) -> int:
	return list_price(base_id, rarity) * SELL_PERCENT / 100


## 10 section 2.1's one hot slot: the listed price less `HOT_DISCOUNT_PERCENT`,
## applied after the rarity step and never stacked with anything.
static func hot_price(price: int) -> int:
	if price <= 0:
		return 0
	return price * (100 - HOT_DISCOUNT_PERCENT) / 100


## 15 section 2's list of source ids, in the table's own row order (auction,
## shipyard, drop, arena, derelict, crafting) with 15 section 9.2's interim
## `faction_lot` last. A caller that iterates the roll sources walks this.
static func roll_sources() -> Array[StringName]:
	var sources: Array[StringName] = []
	for source: Variant in SOURCE_ROLLS:
		sources.append(StringName(str(source)))
	return sources


## One rarity id rolled from `source`'s 15 section 2 table, `""` for an unknown
## source. The roll reads the **global** RNG (15 section 8: "rolls read the global
## RNG, outcomes persist"; tests seed it first). 15 section 5's floor is applied
## last, so an exclusive can never come out Common whatever the source: its legal
## range is Magic..Rare, and 15 section 9.2's own `faction_lot` row is the split the
## F lot uses.
static func roll_rarity(source: StringName, base_id: StringName = &"") -> String:
	var table: Dictionary = SOURCE_ROLLS.get(source, {})
	if table.is_empty():
		return ""
	var rarity := _weighted_rarity(table)
	if EXCLUSIVES.has(base_id) and _rarity_index(rarity) < _rarity_index(EXCLUSIVE_FLOOR):
		return EXCLUSIVE_FLOOR
	return rarity


## 15 section 1's affix count for a rarity: Common 0, Magic 1, Rare 2. An unknown
## rarity counts as none.
static func affix_count(rarity: StringName) -> int:
	var index := _rarity_index(String(rarity))
	return index if index > 0 else 0


## The prefix ids a module may roll: 15 section 3's rows whose family is the
## module's own slot, so a shield never rolls "+cargo". In table order, which is
## the order the roll draws from.
static func prefix_pool(base_id: StringName) -> Array[String]:
	var slot := fit_slot_of(base_id)
	var ids: Array[String] = []
	if slot == &"":
		return ids
	for id: String in PREFIXES:
		var row: Dictionary = PREFIXES[id]
		if StringName(row.get(&"slot", &"")) == slot:
			ids.append(id)
	return ids


## The suffix ids a roll may draw from: 15 section 4's faction-free rows plus the
## bound row of the faction the roll happens in (`&""` = no faction, the ordinary
## case). An exclusive rolls in its own faction's space (15 section 5), so its pool
## carries that faction's suffix.
static func suffix_pool(faction: StringName = &"") -> Array[String]:
	var ids: Array[String] = []
	for id: String in SUFFIXES:
		var row: Dictionary = SUFFIXES[id]
		var bound := StringName(row.get(&"faction", &""))
		if bound == &"" or bound == faction:
			ids.append(id)
	return ids


## The faction a base id's exclusives' roll happens in (15 section 5), `&""` for
## every catalogue module that is not an exclusive.
static func exclusive_faction(base_id: StringName) -> StringName:
	return StringName(EXCLUSIVES.get(base_id, &""))


## One prefix's value at a tier: 15 section 3's band column for that tier (T1 low,
## T3 high). `0.0` for an unknown prefix; the band is clamped at its ends, so a tier
## outside 1..3 reads the nearest column rather than nothing.
static func prefix_value(prefix_id: StringName, tier: int) -> float:
	var row: Dictionary = PREFIXES.get(prefix_id, {})
	if row.is_empty():
		return 0.0
	var band: Array = row.get(&"band", [])
	if band.is_empty():
		return 0.0
	var index := clampi(tier - 1, 0, band.size() - 1)
	return float(band[index])


## The prefix ids to store on a new instance of `base_id` at `rarity`: one for a
## Magic, two distinct ones for a Rare, none for a Common, drawn from the module's
## own family pool. A family with fewer rows than the rarity asks for contributes
## all of them (15 section 3 gives armour, the engine, power, the boosters and
## utility one prefix row each, so a Rare plate carries Lightened alone) -- the
## count is `min(affixes, pool)`, and the roll never repeats a row (a Rare's two
## prefixes must be different properties).
static func roll_prefixes(base_id: StringName, rarity: StringName) -> Array:
	var wanted := affix_count(rarity)
	var tier := int(module(base_id).get(&"tier", 1))
	var pool := prefix_pool(base_id)
	var picked: Array = []
	while picked.size() < wanted and not pool.is_empty():
		var index := randi_range(0, pool.size() - 1)
		var id := pool[index]
		pool.remove_at(index)
		picked.append({"id": id, "value": prefix_value(id, tier)})
	return picked


## The suffix ids to store on a new instance of `base_id` at `rarity`: one for a
## Magic, two distinct ones for a Rare, none for a Common, drawn from the pool the
## base's own faction opens.
static func roll_suffixes(base_id: StringName, rarity: StringName) -> Array:
	var wanted := affix_count(rarity)
	var pool := suffix_pool(exclusive_faction(base_id))
	var picked: Array = []
	while picked.size() < wanted and not pool.is_empty():
		var index := randi_range(0, pool.size() - 1)
		picked.append(pool[index])
		pool.remove_at(index)
	return picked


## One instance's whole affix roll at an already-decided rarity: 15 section 3's
## prefixes, then 15 section 4's suffixes, in that RNG order (so a seeded test's
## outcome is stable). The shape is the record's own.
static func roll_affixes(base_id: StringName, rarity: StringName) -> Dictionary:
	return {
		"prefixes": roll_prefixes(base_id, rarity),
		"suffixes": roll_suffixes(base_id, rarity),
	}


## One rarity from a 15 section 2 weight row, by the global RNG. The keys are
## walked in `RARITY_ORDER`, so a table that leaves a column at 0 can never pick it.
static func _weighted_rarity(table: Dictionary) -> String:
	var total := 0
	for rarity: String in RARITY_ORDER:
		total += maxi(0, int(table.get(rarity, 0)))
	if total <= 0:
		return ""
	var roll := randi_range(1, total)
	var accumulated := 0
	for rarity: String in RARITY_ORDER:
		accumulated += maxi(0, int(table.get(rarity, 0)))
		if roll <= accumulated:
			return rarity
	return ""


## The rarity's place in `RARITY_ORDER`, 0 for Common and -1 for an unknown id.
static func _rarity_index(rarity: StringName) -> int:
	return RARITY_ORDER.find(String(rarity))
