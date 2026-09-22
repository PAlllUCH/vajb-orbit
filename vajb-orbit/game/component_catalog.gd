class_name ComponentCatalog
extends RefCounted
## Read-only catalogue of the 18 loot/crafting components.
## Data, not logic: no nodes, no autoload, no mutation API.
## Values and representation: docs/gameplay/03_components.md (§3 the catalogue,
## §4 keys, §4.1 family icons and grade tints). Grade tints reuse the hexes
## sanctioned by docs/design/ICONS_SPEC.md §8.6; the ember accent is never used.

const COMPONENTS: Array[Dictionary] = [
	{
		&"id": &"comp_scrap_1",
		&"name": "Torn Plating",
		&"family": &"salvage",
		&"grade": 1,
		&"value": 12,
		&"units": 1,
		&"description": "Ripped hull plate, still wearing someone else's paint.",
		&"icon": "res://assets/icons/cargo/icon_cargo_salvage.svg",
	},
	{
		&"id": &"comp_scrap_2",
		&"name": "Wreck Alloy",
		&"family": &"salvage",
		&"grade": 2,
		&"value": 30,
		&"units": 1,
		&"description": "Cut from a hull that stopped working, and good enough to weld into yours.",
		&"icon": "res://assets/icons/cargo/icon_cargo_salvage.svg",
	},
	{
		&"id": &"comp_scrap_3",
		&"name": "Dreadnought Slag",
		&"family": &"salvage",
		&"grade": 3,
		&"value": 75,
		&"units": 1,
		&"description": "Slag off a capital's spine; nothing lighter survives the job it does.",
		&"icon": "res://assets/icons/cargo/icon_cargo_salvage.svg",
	},
	{
		&"id": &"comp_mech_1",
		&"name": "Drive Coupling",
		&"family": &"mech",
		&"grade": 1,
		&"value": 18,
		&"units": 1,
		&"description": "A drive coupling that outlived its ship; engine refits are built on them.",
		&"icon": "res://assets/icons/cargo/icon_cargo_crate.svg",
	},
	{
		&"id": &"comp_mech_2",
		&"name": "Generator Block",
		&"family": &"mech",
		&"grade": 2,
		&"value": 45,
		&"units": 1,
		&"description": "A generator block gutted from a wreck; reactors and shield generators start here.",
		&"icon": "res://assets/icons/cargo/icon_cargo_crate.svg",
	},
	{
		&"id": &"comp_mech_3",
		&"name": "Titan Drive Core",
		&"family": &"mech",
		&"grade": 3,
		&"value": 110,
		&"units": 1,
		&"description": "The core of a capital drive. Heavy, hot, and worth the losses it took.",
		&"icon": "res://assets/icons/cargo/icon_cargo_crate.svg",
	},
	{
		&"id": &"comp_elec_1",
		&"name": "Circuit Stack",
		&"family": &"elec",
		&"grade": 1,
		&"value": 20,
		&"units": 1,
		&"description": "Boards pried out of a dead cockpit; targeting computers run on them.",
		&"icon": "res://assets/icons/cargo/icon_cargo_data_core.svg",
	},
	{
		&"id": &"comp_elec_2",
		&"name": "Logic Array",
		&"family": &"elec",
		&"grade": 2,
		&"value": 50,
		&"units": 1,
		&"description": "A logic array that still answers power. Scanners and guidance systems want it.",
		&"icon": "res://assets/icons/cargo/icon_cargo_data_core.svg",
	},
	{
		&"id": &"comp_elec_3",
		&"name": "Neural Core",
		&"family": &"elec",
		&"grade": 3,
		&"value": 120,
		&"units": 1,
		&"description": "A neural core with a dead pilot's fire control still loaded.",
		&"icon": "res://assets/icons/cargo/icon_cargo_data_core.svg",
	},
	{
		&"id": &"comp_weap_1",
		&"name": "Barrel Assembly",
		&"family": &"weap",
		&"grade": 1,
		&"value": 22,
		&"units": 1,
		&"description": "A barrel assembly, straight enough to shoot again.",
		&"icon": "res://assets/icons/cargo/icon_cargo_container.svg",
	},
	{
		&"id": &"comp_weap_2",
		&"name": "Emitter Housing",
		&"family": &"weap",
		&"grade": 2,
		&"value": 55,
		&"units": 1,
		&"description": "Emitter housing with the lens intact; lasers and plasma are built around it.",
		&"icon": "res://assets/icons/cargo/icon_cargo_container.svg",
	},
	{
		&"id": &"comp_weap_3",
		&"name": "Maw Cannon Chamber",
		&"family": &"weap",
		&"grade": 3,
		&"value": 130,
		&"units": 1,
		&"description": "A firing chamber out of the Maw's own guns. It was not sold willingly.",
		&"icon": "res://assets/icons/cargo/icon_cargo_container.svg",
	},
	{
		&"id": &"comp_pow_1",
		&"name": "Fuel Cell",
		&"family": &"pow",
		&"grade": 1,
		&"value": 15,
		&"units": 1,
		&"description": "A fuel cell with a charge left in it; capacitors and boost systems take it.",
		&"icon": "res://assets/icons/cargo/icon_cargo_fuel_cell.svg",
	},
	{
		&"id": &"comp_pow_2",
		&"name": "Capacitor Bank",
		&"family": &"pow",
		&"grade": 2,
		&"value": 40,
		&"units": 1,
		&"description": "A capacitor bank that still holds a bite; shield capacitors feed on it.",
		&"icon": "res://assets/icons/cargo/icon_cargo_fuel_cell.svg",
	},
	{
		&"id": &"comp_pow_3",
		&"name": "Ember Cell",
		&"family": &"pow",
		&"grade": 3,
		&"value": 100,
		&"units": 1,
		&"description": "An ember cell, warm through the crate, for systems that should not exist.",
		&"icon": "res://assets/icons/cargo/icon_cargo_fuel_cell.svg",
	},
	{
		&"id": &"comp_ore_1",
		&"name": "Purged Ore",
		&"family": &"ore_grade",
		&"grade": 1,
		&"value": 25,
		&"units": 1,
		&"description": "Ore burned clean down to the useful part; a low tier crafting catalyst.",
		&"icon": "res://assets/icons/cargo/icon_cargo_ore.svg",
	},
	{
		&"id": &"comp_ore_2",
		&"name": "Lattice Seed",
		&"family": &"ore_grade",
		&"grade": 2,
		&"value": 60,
		&"units": 1,
		&"description": "A lattice seed grown for shield work, and sold to whoever is still buying.",
		&"icon": "res://assets/icons/cargo/icon_cargo_ore.svg",
	},
	{
		&"id": &"comp_ore_3",
		&"name": "Voidshard",
		&"family": &"ore_grade",
		&"grade": 3,
		&"value": 140,
		&"units": 1,
		&"description": "A voidshard. It does not throw light back the way it should, and exotic work needs it.",
		&"icon": "res://assets/icons/cargo/icon_cargo_ore.svg",
	},
]

const GRADE_TINTS: Dictionary = {
	1: Color("#565C63"),
	2: Color("#8D939B"),
	3: Color("#8A6A50"),
}


static func component(id: StringName) -> Dictionary:
	return _find(COMPONENTS, id)


static func component_ids() -> Array[StringName]:
	return _ids(COMPONENTS)


static func family_components(family: StringName) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for entry: Dictionary in COMPONENTS:
		if entry.get(&"family", &"") == family:
			rows.append(entry)
	return rows


static func grade_components(grade: int) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for entry: Dictionary in COMPONENTS:
		if int(entry.get(&"grade", 0)) == grade:
			rows.append(entry)
	return rows


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
