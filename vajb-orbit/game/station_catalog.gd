class_name StationCatalog
extends RefCounted
## Read-only station stock: ammo packs, ships, upgrades.
## Data, not logic: no nodes, no autoload, no mutation API.
## Contract: docs/design/STATION_SPEC.md.

const UPGRADE_SLOTS: Array[StringName] = [
	&"generator",
	&"shield",
	&"engine",
	&"module",
	&"extra",
	&"drone",
]

const AMMO_PACKS: Array[Dictionary] = [
	{
		&"id": &"laser",
		&"name": "Laser Cells",
		&"rounds": 300,
		&"cost": 120,
		&"icon": "res://assets/icons/icon_ammo_laser_48.png",
		&"description": "Standard laser capacitors. Cheap, and the laser is thirsty.",
	},
	{
		&"id": &"cannon",
		&"name": "Cannon Shells",
		&"rounds": 300,
		&"cost": 180,
		&"icon": "res://assets/icons/icon_weapon_cannon_48.png",
		&"description": "Kinetic slugs for the autocannon. No guidance, no mercy.",
	},
	{
		&"id": &"rocket",
		&"name": "Rocket Pod",
		&"rounds": 60,
		&"cost": 240,
		&"icon": "res://assets/icons/icon_ammo_rocket_48.png",
		&"description": "Sixty warheads. Reserved for targets that are still moving.",
	},
	{
		&"id": &"mine",
		&"name": "Mine Rack",
		&"rounds": 40,
		&"cost": 200,
		&"icon": "res://assets/icons/icon_weapon_mine_48.png",
		&"description": "Proximity mines. Best deployed while running away.",
	},
	{
		&"id": &"plasma",
		&"name": "Plasma Cells",
		&"rounds": 50,
		&"cost": 320,
		&"icon": "res://assets/icons/icon_weapon_plasma_48.png",
		&"description": "Superheated cells. Hard on the barrel, harder on the hull.",
	},
]

const SHIPS: Array[Dictionary] = [
	{
		&"id": &"ship_fighter",
		&"name": "Lancer",
		&"cost": 9000,
		&"preview": "res://assets/ships/ship_fighter_side.png",
		&"hull": 700,
		&"shield": 400,
		&"cargo": 25,
		&"hardpoints": 3,
		&"description": "Light interceptor. Fast, thin plated, cheap to lose.",
	},
	{
		&"id": &"ship_vanguard",
		&"name": "Vanguard",
		&"cost": 18000,
		&"preview": "res://assets/ships/ship_vanguard_side.png",
		&"hull": 1000,
		&"shield": 600,
		&"cargo": 40,
		&"hardpoints": 4,
		&"description": "General purpose hull. The yard stick every other ship is measured against.",
	},
	{
		&"id": &"ship_gunship",
		&"name": "Bulwark",
		&"cost": 36000,
		&"preview": "res://assets/ships/ship_gunship_side.png",
		&"hull": 1400,
		&"shield": 650,
		&"cargo": 50,
		&"hardpoints": 5,
		&"description": "Heavy gunship. Trading manoeuvrability for gun decks and plate.",
	},
	{
		&"id": &"ship_destroyer",
		&"name": "Obliterator",
		&"cost": 72000,
		&"preview": "res://assets/ships/ship_destroyer_side.png",
		&"hull": 2200,
		&"shield": 900,
		&"cargo": 80,
		&"hardpoints": 7,
		&"description": "Line destroyer. Seven hardpoints and a hull built to take a beating.",
	},
]

const UPGRADES: Array[Dictionary] = [
	{
		&"id": &"upgrade_generator",
		&"name": "Reactor Mk2",
		&"cost": 4200,
		&"icon": "res://assets/icons/icon_equip_generator_48.png",
		&"slot": &"generator",
		&"effect": {"shield_regen": 0.30, "energy_regen": 0.20},
		&"description": "Bigger reactor. Faster shield and capacitor recovery.",
	},
	{
		&"id": &"upgrade_shield",
		&"name": "Shield Amplifier",
		&"cost": 5200,
		&"icon": "res://assets/icons/icon_equip_shield_gen_48.png",
		&"slot": &"shield",
		&"effect": {"shield_max": 0.20},
		&"description": "Amplified emitter geometry. Twenty percent more shield.",
	},
	{
		&"id": &"upgrade_engine",
		&"name": "Ion Drive",
		&"cost": 3800,
		&"icon": "res://assets/icons/icon_equip_engine_48.png",
		&"slot": &"engine",
		&"effect": {"speed": 0.15},
		&"description": "Ion thruster refit. Fifteen percent more top speed.",
	},
	{
		&"id": &"upgrade_module",
		&"name": "Deep Scanner",
		&"cost": 4600,
		&"icon": "res://assets/icons/icon_equip_module_48.png",
		&"slot": &"module",
		&"effect": {"scanner_range": 0.25},
		&"description": "Long range sensor array. Finds contacts before they find you.",
	},
	{
		&"id": &"upgrade_extra",
		&"name": "Cargo Expansion",
		&"cost": 3000,
		&"icon": "res://assets/icons/icon_equip_extra_48.png",
		&"slot": &"extra",
		&"effect": {"cargo_max": 0.25},
		&"description": "Collapsible hold extension. Twenty five percent more cargo space.",
	},
	{
		&"id": &"upgrade_drone",
		&"name": "Repair Drone Bay",
		&"cost": 6800,
		&"icon": "res://assets/icons/icon_equip_drone_48.png",
		&"slot": &"drone",
		&"effect": {"hull_repair_rate": 0.50},
		&"description": "Autonomous repair drones. The hull mends itself while you fight.",
	},
]


static func ammo_pack(id: StringName) -> Dictionary:
	return _find(AMMO_PACKS, id)


static func ship(id: StringName) -> Dictionary:
	return _find(SHIPS, id)


static func upgrade(id: StringName) -> Dictionary:
	return _find(UPGRADES, id)


static func ammo_ids() -> Array[StringName]:
	return _ids(AMMO_PACKS)


static func ship_ids() -> Array[StringName]:
	return _ids(SHIPS)


static func upgrade_ids() -> Array[StringName]:
	return _ids(UPGRADES)


static func _find(entries: Array[Dictionary], id: StringName) -> Dictionary:
	for entry: Dictionary in entries:
		if entry.get(&"id", &"") == id:
			return entry
	return {}


static func _ids(entries: Array[Dictionary]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for entry: Dictionary in entries:
		var id: StringName = entry.get(&"id", &"")
		if id != &"":
			ids.append(id)
	return ids
