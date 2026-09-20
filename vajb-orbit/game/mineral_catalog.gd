class_name MineralCatalog
extends RefCounted
## Read-only catalogue of the 20 minerals and their ore/ingot item ids.
## Data, not logic: no nodes, no autoload, no mutation API.
## Values and representation: docs/gameplay/02_minerals.md (§1 item ids, §2 the
## catalogue, §3 keys, §5 generation). 02 §6's v1 icon fallback is retired
## (ICONS_SPEC §8.1: "Retire the 02 §6 fallback"): every `icon_ore` points at the
## dedicated `icon_mineral_<id>_48.png` and every `icon_ingot` at
## `icon_ingot_<id>_48.png`. `TIER_TINTS` (ICONS_SPEC §8.6) stays as the fallback
## for a mineral whose dedicated glyph is ever absent; it is no longer applied to
## a dedicated glyph (those are per-mineral art, drawn untinted).
## Sector tier mixes: docs/gameplay/11_galactic_map.md §1.1, which supersedes
## 02 §5's abstract sector ranges.
## Asteroid spawning and the mining flow are P3; this file owns the data tables
## and the generation rolls only. `is_ore` / `is_ingot` read the item id form,
## so a bare mineral id is neither.

const ORE_ID_PREFIX := "mineral_"
const INGOT_ID_PREFIX := "ingot_"

const MINERALS: Array[Dictionary] = [
	{
		&"id": &"iron",
		&"name": "Iron",
		&"tier": 1,
		&"ore_value": 18,
		&"ingot_value": 65,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "The everything metal: structural plate and cheap gun barrels.",
		&"icon_ore": "res://assets/icons/icon_mineral_iron_48.png",
		&"icon_ingot": "res://assets/icons/icon_ingot_iron_48.png",
	},
	{
		&"id": &"copper",
		&"name": "Copper",
		&"tier": 1,
		&"ore_value": 22,
		&"ingot_value": 80,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "Wiring, coils, and the cheapest capacitors a yard will fit.",
		&"icon_ore": "res://assets/icons/icon_mineral_copper_48.png",
		&"icon_ingot": "res://assets/icons/icon_ingot_copper_48.png",
	},
	{
		&"id": &"chromium",
		&"name": "Chromium",
		&"tier": 1,
		&"ore_value": 25,
		&"ingot_value": 90,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "Plating alloy and armour weave, sold by the tonne.",
		&"icon_ore": "res://assets/icons/icon_mineral_chromium_48.png",
		&"icon_ingot": "res://assets/icons/icon_ingot_chromium_48.png",
	},
	{
		&"id": &"silicon",
		&"name": "Silicon",
		&"tier": 1,
		&"ore_value": 28,
		&"ingot_value": 100,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "Wafers and lenses; every component chain starts at this rock.",
		&"icon_ore": "res://assets/icons/icon_mineral_silicon_48.png",
		&"icon_ingot": "res://assets/icons/icon_ingot_silicon_48.png",
	},
	{
		&"id": &"aluminium",
		&"name": "Aluminium",
		&"tier": 1,
		&"ore_value": 20,
		&"ingot_value": 72,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "Light frames and engine cowlings for hulls built cheap and lost cheap.",
		&"icon_ore": "res://assets/icons/icon_mineral_aluminium_48.png",
		&"icon_ingot": "res://assets/icons/icon_ingot_aluminium_48.png",
	},
	{
		&"id": &"titanium",
		&"name": "Titanium",
		&"tier": 2,
		&"ore_value": 45,
		&"ingot_value": 162,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "The backbone of any hull worth calling a warship.",
		&"icon_ore": "res://assets/icons/icon_mineral_titanium_48.png",
		&"icon_ingot": "res://assets/icons/icon_ingot_titanium_48.png",
	},
	{
		&"id": &"nickel",
		&"name": "Nickel",
		&"tier": 2,
		&"ore_value": 50,
		&"ingot_value": 180,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "Superalloys and heat exchangers that shrug off their own exhaust.",
		&"icon_ore": "res://assets/icons/icon_mineral_nickel_48.png",
		&"icon_ingot": "res://assets/icons/icon_ingot_nickel_48.png",
	},
	{
		&"id": &"cobalt",
		&"name": "Cobalt",
		&"tier": 2,
		&"ore_value": 55,
		&"ingot_value": 200,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "Magnetics and shield emitter cores; the hum inside every barrier.",
		&"icon_ore": "res://assets/icons/icon_mineral_cobalt_48.png",
		&"icon_ingot": "res://assets/icons/icon_ingot_cobalt_48.png",
	},
	{
		&"id": &"tungsten",
		&"name": "Tungsten",
		&"tier": 2,
		&"ore_value": 65,
		&"ingot_value": 235,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "Mass drivers and penetrators; it keeps its shape where the rest runs.",
		&"icon_ore": "res://assets/icons/icon_mineral_tungsten_48.png",
		&"icon_ingot": "res://assets/icons/icon_ingot_tungsten_48.png",
	},
	{
		&"id": &"silver",
		&"name": "Silver",
		&"tier": 2,
		&"ore_value": 70,
		&"ingot_value": 252,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "Conductors and coatings, prettier than it is scarce.",
		&"icon_ore": "res://assets/icons/icon_mineral_silver_48.png",
		&"icon_ingot": "res://assets/icons/icon_ingot_silver_48.png",
	},
	{
		&"id": &"gold",
		&"name": "Gold",
		&"tier": 3,
		&"ore_value": 110,
		&"ingot_value": 395,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "Circuitry plating. Worth mining, never worth wearing.",
		&"icon_ore": "res://assets/icons/icon_mineral_gold_48.png",
		&"icon_ingot": "res://assets/icons/icon_ingot_gold_48.png",
	},
	{
		&"id": &"platinum",
		&"name": "Platinum",
		&"tier": 3,
		&"ore_value": 130,
		&"ingot_value": 470,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "Catalysts and fuel cell membranes; the quiet cost of a working reactor.",
		&"icon_ore": "res://assets/icons/icon_mineral_platinum_48.png",
		&"icon_ingot": "res://assets/icons/icon_ingot_platinum_48.png",
	},
	{
		&"id": &"neodymium",
		&"name": "Neodymium",
		&"tier": 3,
		&"ore_value": 150,
		&"ingot_value": 540,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "The magnet king: drive coils and railgun rails.",
		&"icon_ore": "res://assets/icons/icon_mineral_neodymium_48.png",
		&"icon_ingot": "res://assets/icons/icon_ingot_neodymium_48.png",
	},
	{
		&"id": &"iridium",
		&"name": "Iridium",
		&"tier": 3,
		&"ore_value": 170,
		&"ingot_value": 610,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "Near indestructible contact points for guns that must not fail.",
		&"icon_ore": "res://assets/icons/icon_mineral_iridium_48.png",
		&"icon_ingot": "res://assets/icons/icon_ingot_iridium_48.png",
	},
	{
		&"id": &"osmium",
		&"name": "Osmium",
		&"tier": 3,
		&"ore_value": 190,
		&"ingot_value": 685,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "Densest of the stable metals; counterweights and penetrator tips.",
		&"icon_ore": "res://assets/icons/icon_mineral_osmium_48.png",
		&"icon_ingot": "res://assets/icons/icon_ingot_osmium_48.png",
	},
	{
		&"id": &"palladium",
		&"name": "Palladium",
		&"tier": 4,
		&"ore_value": 300,
		&"ingot_value": 1080,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "Exotic catalysts, half way to the strange stuff past the rim.",
		&"icon_ore": "res://assets/icons/icon_mineral_palladium_48.png",
		&"icon_ingot": "res://assets/icons/icon_ingot_palladium_48.png",
	},
	{
		&"id": &"cerulite",
		&"name": "Cerulite",
		&"tier": 4,
		&"ore_value": 350,
		&"ingot_value": 1260,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "Blue veined crystal ore; feedstock for shield lattices.",
		&"icon_ore": "res://assets/icons/icon_mineral_cerulite_48.png",
		&"icon_ingot": "res://assets/icons/icon_ingot_cerulite_48.png",
	},
	{
		&"id": &"emberite",
		&"name": "Emberite",
		&"tier": 4,
		&"ore_value": 400,
		&"ingot_value": 1440,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "Warm to the touch, and reactor cores run on that heat.",
		&"icon_ore": "res://assets/icons/icon_mineral_emberite_48.png",
		&"icon_ingot": "res://assets/icons/icon_ingot_emberite_48.png",
	},
	{
		&"id": &"voidglass",
		&"name": "Voidglass",
		&"tier": 4,
		&"ore_value": 480,
		&"ingot_value": 1730,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "Shards of something older than the colonies; sensor optics buy it and stranger trades ask.",
		&"icon_ore": "res://assets/icons/icon_mineral_voidglass_48.png",
		&"icon_ingot": "res://assets/icons/icon_ingot_voidglass_48.png",
	},
	{
		&"id": &"krilium",
		&"name": "Krillum",
		&"tier": 4,
		&"ore_value": 600,
		&"ingot_value": 2160,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "The apex ore: a trade name, not a chemistry, and no two refineries agree what is in it.",
		&"icon_ore": "res://assets/icons/icon_mineral_krilium_48.png",
		&"icon_ingot": "res://assets/icons/icon_ingot_krilium_48.png",
	},
]

const TIER_TINTS: Dictionary = {
	1: Color("#565C63"),
	2: Color("#8D939B"),
	3: Color("#8A6A50"),
	4: Color("#6E5B4A"),
}

const SECTOR_TIER_MIX: Dictionary = {
	1: {1: 100},
	2: {1: 55, 2: 45},
	3: {1: 20, 2: 80},
	4: {2: 60, 3: 40},
	5: {2: 35, 3: 65},
	6: {3: 55, 4: 45},
	7: {3: 40, 4: 60},
}

const TIER_BASE_YIELD: Dictionary = {
	1: 6,
	2: 5,
	3: 4,
	4: 3,
}

const YIELD_VARIANCE_MIN := 0.5
const YIELD_VARIANCE_MAX := 1.5


static func mineral(id: StringName) -> Dictionary:
	return _find(MINERALS, id)


static func mineral_ids() -> Array[StringName]:
	return _ids(MINERALS)


static func tier_minerals(tier: int) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for entry: Dictionary in MINERALS:
		if int(entry.get(&"tier", 0)) == tier:
			rows.append(entry)
	return rows


static func ore_id(mineral_id: StringName) -> StringName:
	if mineral(mineral_id).is_empty():
		return &""
	return StringName(ORE_ID_PREFIX + String(mineral_id))


static func ingot_id(mineral_id: StringName) -> StringName:
	if mineral(mineral_id).is_empty():
		return &""
	return StringName(INGOT_ID_PREFIX + String(mineral_id))


static func mineral_id_of_item(item_id: StringName) -> StringName:
	if item_id == &"":
		return &""
	var text: String = String(item_id)
	for prefix: String in [ORE_ID_PREFIX, INGOT_ID_PREFIX]:
		if text.begins_with(prefix):
			var stripped: StringName = StringName(text.substr(prefix.length()))
			if mineral(stripped).is_empty():
				return &""
			return stripped
	if mineral(item_id).is_empty():
		return &""
	return item_id


static func entry_for_item(item_id: StringName) -> Dictionary:
	return mineral(mineral_id_of_item(item_id))


static func is_ore(item_id: StringName) -> bool:
	return _is_item_form(item_id, ORE_ID_PREFIX)


static func is_ingot(item_id: StringName) -> bool:
	return _is_item_form(item_id, INGOT_ID_PREFIX)


static func sector_mix(sector: int) -> Dictionary:
	if not SECTOR_TIER_MIX.has(sector):
		return {}
	return SECTOR_TIER_MIX[sector]


static func roll_tier(sector: int, rng: RandomNumberGenerator) -> int:
	var mix: Dictionary = sector_mix(sector)
	if mix.is_empty():
		return 0
	var total: int = 0
	for weight: int in mix.values():
		total += weight
	var roll: int = rng.randi_range(1, total)
	var accumulated: int = 0
	for tier: int in [1, 2, 3, 4]:
		if not mix.has(tier):
			continue
		accumulated += int(mix[tier])
		if roll <= accumulated:
			return tier
	return 0


static func roll_mineral(tier: int, rng: RandomNumberGenerator) -> Dictionary:
	var rows: Array[Dictionary] = tier_minerals(tier)
	if rows.is_empty():
		return {}
	return rows[rng.randi_range(0, rows.size() - 1)]


static func roll_yield(tier: int, rng: RandomNumberGenerator) -> int:
	var base: int = int(TIER_BASE_YIELD.get(tier, 0))
	return maxi(1, roundi(base * rng.randf_range(YIELD_VARIANCE_MIN, YIELD_VARIANCE_MAX)))


static func _is_item_form(item_id: StringName, prefix: String) -> bool:
	var text: String = String(item_id)
	if not text.begins_with(prefix):
		return false
	return not mineral(StringName(text.substr(prefix.length()))).is_empty()


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
