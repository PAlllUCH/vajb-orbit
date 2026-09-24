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
##
## S5 (2026-09-23, 10 section 6.1 / CONTRACTS section 17): ammunition is a **cargo
## item** now, counted in units of `ROUNDS_PER_CARGO_UNIT` rounds, and a pack row is
## what one unit's purchase and one unit's sale price are derived from. The cargo id
## is the family with `AMMO_PREFIX` in front (`laser` -> `ammo_laser`); `ammo_item_id`
## and `ammo_family` are the one mapping, and reversing it is this constant plus the
## two helpers. The railgun joined as the sixth pack at its own J0-ratified numbers
## (owner 2026-09-23) rather than borrowing the cannon's family.

## 10 section 6.1 / CONTRACTS section 17: how many rounds one cargo unit carries.
## Reversal: 1 (the pre-S5 one-unit-per-round reading).
const ROUNDS_PER_CARGO_UNIT := 10

## The cargo namespace of the ammo families (CONTRACTS section 17: "the `ammo_*`
## cargo id maps to its family by prefix"). Reversal: one constant.
const AMMO_PREFIX := "ammo_"

const AMMO_PACKS: Array[Dictionary] = [
	{
		&"id": &"laser",
		&"name": "Laser Cells",
		&"rounds": 300,
		&"cost": 120,
		&"icon": "res://assets/icons/weapon/icon_ammo_laser.png",
		&"description": "Standard laser capacitors. Cheap, and the laser is thirsty.",
	},
	{
		&"id": &"cannon",
		&"name": "Cannon Shells",
		&"rounds": 300,
		&"cost": 180,
		&"icon": "res://assets/icons/weapon/icon_weapon_cannon.svg",
		&"description": "Kinetic slugs for the autocannon. No guidance, no mercy.",
	},
	{
		&"id": &"rocket",
		&"name": "Rocket Pod",
		&"rounds": 60,
		&"cost": 240,
		&"icon": "res://assets/icons/weapon/icon_ammo_rocket.png",
		&"description": "Sixty warheads. Reserved for targets that are still moving.",
	},
	{
		&"id": &"mine",
		&"name": "Mine Rack",
		&"rounds": 40,
		&"cost": 200,
		&"icon": "res://assets/icons/weapon/icon_weapon_mine.svg",
		&"description": "Proximity mines. Best deployed while running away.",
	},
	{
		&"id": &"plasma",
		&"name": "Plasma Cells",
		&"rounds": 50,
		&"cost": 320,
		&"icon": "res://assets/icons/weapon/icon_weapon_plasma.svg",
		&"description": "Superheated cells. Hard on the barrel, harder on the hull.",
	},
	{
		&"id": &"railgun",
		&"name": "Railgun Slugs",
		&"rounds": 150,
		&"cost": 360,
		&"icon": "res://assets/icons/module/icon_module_w_railgun.svg",
		&"description": "Sabot slugs cut for the rail's own bore; the cannon's shells will not seat.",
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
## 14 section 7's bounty payment window and 13 section 2's fine math, wired by wave S6
## (CONTRACTS section 19). 14 section 1's amended table gives it to all three capitals
## (and 14 section 8 to every outpost), so its availability is `all`; what is conditional
## is the **row**, not the station - 14 section 7 shows it at "any faction station with
## heat > 0", which is `ui/station/launch_panel.gd`'s reading of the docked faction's heat.
const SERVICE_BOUNTY: StringName = &"bounty"

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
	{
		&"id": SERVICE_BOUNTY,
		&"name": "PAY BOUNTY",
		&"availability": &"all",
		&"free": false,
		&"instant": true,
		&"description": "Settle the station faction's fine: heat x 25 CR clears the record. One confirm, no haggling.",
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


## The cargo id of one ammo family (`&"laser"` -> `&"ammo_laser"`). An unknown family
## still derives its own id, exactly as the prefix rule reads, and `ammo_family` is the
## guard that resolves one back to a pack.
static func ammo_item_id(family: StringName) -> StringName:
	if family == &"":
		return &""
	return StringName(AMMO_PREFIX + String(family))


## The family behind one cargo id (`&"ammo_laser"` -> `&"laser"`), or `&""` for an id
## outside the six packs. The pack lookup is the guard, so a typo cannot become a
## seventh family.
static func ammo_family(item_id: StringName) -> StringName:
	var text := String(item_id)
	if not text.begins_with(AMMO_PREFIX):
		return &""
	var family := StringName(text.substr(AMMO_PREFIX.length()))
	if ammo_pack(family).is_empty():
		return &""
	return family


## The six cargo ids, in pack order.
static func ammo_item_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for family: StringName in ammo_ids():
		ids.append(ammo_item_id(family))
	return ids


## How many cargo units one whole pack of `family` fills (rounds / ROUNDS_PER_CARGO_UNIT),
## rounded up because a unit is indivisible. 0 for an unknown family.
static func ammo_pack_units(family: StringName) -> int:
	var pack := ammo_pack(family)
	if pack.is_empty():
		return 0
	return ceili(float(pack.get(&"rounds", 0)) / float(ROUNDS_PER_CARGO_UNIT))


## The list price of one cargo unit of `item_id`, in credits, rounded: the unit's own
## share of the pack's price (`roundi(ROUNDS_PER_CARGO_UNIT * cost / rounds)`). 0 for an
## id outside the six packs. EXCHANGE sells a unit at its own share of this
## (`Exchange.ammo_unit_price`, AMMO_SELL_PERCENT of it).
static func ammo_unit_cost(item_id: StringName) -> int:
	var pack := ammo_pack(ammo_family(item_id))
	var rounds := int(pack.get(&"rounds", 0))
	if rounds <= 0:
		return 0
	return roundi(float(ROUNDS_PER_CARGO_UNIT) * float(pack.get(&"cost", 0)) / float(rounds))


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
