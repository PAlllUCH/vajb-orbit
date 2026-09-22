class_name StationCatalog
extends RefCounted
## Read-only station stock: ammo packs, ships, services.
## Data, not logic: no nodes, no autoload, no mutation API.
## Contract: docs/design/STATION_SPEC.md; the service rows are
## docs/gameplay/14_station_services.md section 1 and 18_engine_spec section 12
## item 8.
##
## The six pre-module `UPGRADES` rows (and the slot labels that went with them)
## retired in save v5 (09 section 4 item 13, docs/gameplay/10 section 5): their
## effects are modules in `ModuleCatalog`, an installed upgrade converts to one
## inventory module per `PlayerProfile.LEGACY_UPGRADE_MODULES`, and nothing reads
## a row from here any more.

const AMMO_PACKS: Array[Dictionary] = [
	{
		&"id": &"laser",
		&"name": "Laser Cells",
		&"rounds": 300,
		&"cost": 120,
		&"icon": "res://assets/icons/weapon/icon_ammo_laser_48.png",
		&"description": "Standard laser capacitors. Cheap, and the laser is thirsty.",
	},
	{
		&"id": &"cannon",
		&"name": "Cannon Shells",
		&"rounds": 300,
		&"cost": 180,
		&"icon": "res://assets/icons/weapon/icon_weapon_cannon_48.png",
		&"description": "Kinetic slugs for the autocannon. No guidance, no mercy.",
	},
	{
		&"id": &"rocket",
		&"name": "Rocket Pod",
		&"rounds": 60,
		&"cost": 240,
		&"icon": "res://assets/icons/weapon/icon_ammo_rocket_48.png",
		&"description": "Sixty warheads. Reserved for targets that are still moving.",
	},
	{
		&"id": &"mine",
		&"name": "Mine Rack",
		&"rounds": 40,
		&"cost": 200,
		&"icon": "res://assets/icons/weapon/icon_weapon_mine_48.png",
		&"description": "Proximity mines. Best deployed while running away.",
	},
	{
		&"id": &"plasma",
		&"name": "Plasma Cells",
		&"rounds": 50,
		&"cost": 320,
		&"icon": "res://assets/icons/weapon/icon_weapon_plasma_48.png",
		&"description": "Superheated cells. Hard on the barrel, harder on the hull.",
	},
]

## Nine player hulls, in 08 section 2's ladder order. Cost/hull/shield/cargo are
## that table's frozen values (STATION_SPEC section 5.2 for the four it lists);
## `hardpoints` is its Weapons column, which equals the hull's W-slot count
## (ShipFit.grid_counts -> `HULLS[hull].weapons`, 08 section 3).
const SHIPS: Array[Dictionary] = [
	{
		&"id": &"ship_fighter",
		&"name": "Lancer",
		&"cost": 9000,
		&"preview": "res://assets/ships/ship_fighter_side.png",
		&"hull": 700,
		&"shield": 400,
		&"cargo": 25,
		&"hardpoints": 2,
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
		&"hardpoints": 3,
		&"description": "General purpose hull. The yard stick every other ship is measured against.",
	},
	{
		&"id": &"ship_miner",
		&"name": "Delver",
		&"cost": 16000,
		&"preview": "res://assets/ships/ship_miner_side.png",
		&"hull": 1100,
		&"shield": 500,
		&"cargo": 55,
		&"hardpoints": 2,
		&"description": "Mining specialist. Slow, deep holds, and a hull that shrugs off rock.",
	},
	{
		&"id": &"ship_trader",
		&"name": "Courier",
		&"cost": 21000,
		&"preview": "res://assets/ships/ship_trader_side.png",
		&"hull": 950,
		&"shield": 550,
		&"cargo": 60,
		&"hardpoints": 1,
		&"description": "Trade hull. Better exchange rates and a hold built for volume.",
	},
	{
		&"id": &"ship_corvette",
		&"name": "Spearhead",
		&"cost": 27000,
		&"preview": "res://assets/ships/ship_corvette_side.png",
		&"hull": 1300,
		&"shield": 700,
		&"cargo": 35,
		&"hardpoints": 4,
		&"description": "Fast hunter. The quickest hull in the yard, and it pays for it in plate.",
	},
	{
		&"id": &"ship_freighter",
		&"name": "Mule",
		&"cost": 24000,
		&"preview": "res://assets/ships/ship_freighter_side.png",
		&"hull": 1600,
		&"shield": 500,
		&"cargo": 120,
		&"hardpoints": 1,
		&"description": "Bulk hauler. The biggest hold in the yard, and the least interest in a fight.",
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
		&"id": &"ship_patrol",
		&"name": "Warden",
		&"cost": 54000,
		&"preview": "res://assets/ships/ship_patrol_side.png",
		&"hull": 1800,
		&"shield": 800,
		&"cargo": 60,
		&"hardpoints": 4,
		&"description": "Line patrol. Two computers, four mounts, and the plate to hold a lane.",
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

## Station services (14 section 1, as amended 2026-09-20; owner ruling 2026-09-21):
## refuel and recharge are offered at **every** station, free and instant. The
## ruling retired the CR-per-fuel-point rate, so these rows carry no price at all —
## "free and instant, no CR charged" is the rate, and the service functions report
## it as a `fee` of 0. `availability` &"all" transcribes 14 section 1's amended
## table row; `free`/`instant` transcribe the same row's wording. No icon path:
## the asset tree is being re-laid into per-family folders, so a path here would be
## a fresh unresolvable reference, and the rows are read by `Repairs.refuel` /
## `Repairs.recharge` (the service owner) rather than by a panel.
const SERVICE_REFUEL: StringName = &"refuel"
const SERVICE_RECHARGE: StringName = &"recharge"

const SERVICES: Array[Dictionary] = [
	{
		&"id": SERVICE_REFUEL,
		&"name": "REFUEL",
		&"availability": &"all",
		&"free": true,
		&"instant": true,
		&"description": "Station tanks top the fuel reserve back up. Free, and it takes no time.",
	},
	{
		&"id": SERVICE_RECHARGE,
		&"name": "RECHARGE",
		&"availability": &"all",
		&"free": true,
		&"instant": true,
		&"description": "Capacitor refill. Energy recomputes at launch either way, so the station does it for free.",
	},
]


static func ammo_pack(id: StringName) -> Dictionary:
	return _find(AMMO_PACKS, id)


static func service(id: StringName) -> Dictionary:
	return _find(SERVICES, id)


static func ship(id: StringName) -> Dictionary:
	return _find(SHIPS, id)


static func ammo_ids() -> Array[StringName]:
	return _ids(AMMO_PACKS)


static func ship_ids() -> Array[StringName]:
	return _ids(SHIPS)


static func service_ids() -> Array[StringName]:
	return _ids(SERVICES)


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
