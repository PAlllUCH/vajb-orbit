class_name MineralCatalog
extends RefCounted
## Read-only catalogue of the 20 minerals and their ore/ingot item ids.
## Data, not logic: no nodes, no autoload, no mutation API.
## Values and representation: docs/gameplay/02_minerals.md (§1 item ids, §2 the
## catalogue, §3 keys, §5 generation). The two value cells are 02's 2026-10-08
## block (S28, tick M8): tier-mean ore = 22.6 × 2.0^(t−1), the five minerals of a
## tier at ×{0.80, 0.88, 0.97, 1.11, 1.24} of that mean, `ingot = round(ore × 3.6)`
## for T2–T4. T1's ten cells are byte-unchanged (its historical rounding stands).
## Reversal: 02 §2's superseded table. 02 §6's v1 icon fallback is retired
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

## S13's live balance surface (S13_BRIEF §2 rule 1): the ticked tables stay declared
## above, and `roll_yield` reads the live values so the F1 overlay can retune the
## tier curve without a reload. `ore_tuning.gd` preloads nothing, so no cycle.
const OreTuningScript := preload("res://game/ore_tuning.gd")
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
		&"icon_ore": "res://assets/icons/mineral/icon_mineral_iron.svg",
		&"icon_ingot": "res://assets/icons/ingot/icon_ingot_iron.svg",
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
		&"icon_ore": "res://assets/icons/mineral/icon_mineral_copper.svg",
		&"icon_ingot": "res://assets/icons/ingot/icon_ingot_copper.svg",
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
		&"icon_ore": "res://assets/icons/mineral/icon_mineral_chromium.svg",
		&"icon_ingot": "res://assets/icons/ingot/icon_ingot_chromium.svg",
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
		&"icon_ore": "res://assets/icons/mineral/icon_mineral_silicon.svg",
		&"icon_ingot": "res://assets/icons/ingot/icon_ingot_silicon.svg",
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
		&"icon_ore": "res://assets/icons/mineral/icon_mineral_aluminium.svg",
		&"icon_ingot": "res://assets/icons/ingot/icon_ingot_aluminium.svg",
	},
	{
		&"id": &"titanium",
		&"name": "Titanium",
		&"tier": 2,
		&"ore_value": 36,
		&"ingot_value": 130,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "The backbone of any hull worth calling a warship.",
		&"icon_ore": "res://assets/icons/mineral/icon_mineral_titanium.svg",
		&"icon_ingot": "res://assets/icons/ingot/icon_ingot_titanium.svg",
	},
	{
		&"id": &"nickel",
		&"name": "Nickel",
		&"tier": 2,
		&"ore_value": 40,
		&"ingot_value": 144,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "Superalloys and heat exchangers that shrug off their own exhaust.",
		&"icon_ore": "res://assets/icons/mineral/icon_mineral_nickel.svg",
		&"icon_ingot": "res://assets/icons/ingot/icon_ingot_nickel.svg",
	},
	{
		&"id": &"cobalt",
		&"name": "Cobalt",
		&"tier": 2,
		&"ore_value": 44,
		&"ingot_value": 158,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "Magnetics and shield emitter cores; the hum inside every barrier.",
		&"icon_ore": "res://assets/icons/mineral/icon_mineral_cobalt.svg",
		&"icon_ingot": "res://assets/icons/ingot/icon_ingot_cobalt.svg",
	},
	{
		&"id": &"tungsten",
		&"name": "Tungsten",
		&"tier": 2,
		&"ore_value": 50,
		&"ingot_value": 180,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "Mass drivers and penetrators; it keeps its shape where the rest runs.",
		&"icon_ore": "res://assets/icons/mineral/icon_mineral_tungsten.svg",
		&"icon_ingot": "res://assets/icons/ingot/icon_ingot_tungsten.svg",
	},
	{
		&"id": &"silver",
		&"name": "Silver",
		&"tier": 2,
		&"ore_value": 56,
		&"ingot_value": 202,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "Conductors and coatings, prettier than it is scarce.",
		&"icon_ore": "res://assets/icons/mineral/icon_mineral_silver.svg",
		&"icon_ingot": "res://assets/icons/ingot/icon_ingot_silver.svg",
	},
	{
		&"id": &"gold",
		&"name": "Gold",
		&"tier": 3,
		&"ore_value": 72,
		&"ingot_value": 259,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "Circuitry plating. Worth mining, never worth wearing.",
		&"icon_ore": "res://assets/icons/mineral/icon_mineral_gold.svg",
		&"icon_ingot": "res://assets/icons/ingot/icon_ingot_gold.svg",
	},
	{
		&"id": &"platinum",
		&"name": "Platinum",
		&"tier": 3,
		&"ore_value": 80,
		&"ingot_value": 288,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "Catalysts and fuel cell membranes; the quiet cost of a working reactor.",
		&"icon_ore": "res://assets/icons/mineral/icon_mineral_platinum.svg",
		&"icon_ingot": "res://assets/icons/ingot/icon_ingot_platinum.svg",
	},
	{
		&"id": &"neodymium",
		&"name": "Neodymium",
		&"tier": 3,
		&"ore_value": 88,
		&"ingot_value": 317,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "The magnet king: drive coils and railgun rails.",
		&"icon_ore": "res://assets/icons/mineral/icon_mineral_neodymium.svg",
		&"icon_ingot": "res://assets/icons/ingot/icon_ingot_neodymium.svg",
	},
	{
		&"id": &"iridium",
		&"name": "Iridium",
		&"tier": 3,
		&"ore_value": 100,
		&"ingot_value": 360,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "Near indestructible contact points for guns that must not fail.",
		&"icon_ore": "res://assets/icons/mineral/icon_mineral_iridium.svg",
		&"icon_ingot": "res://assets/icons/ingot/icon_ingot_iridium.svg",
	},
	{
		&"id": &"osmium",
		&"name": "Osmium",
		&"tier": 3,
		&"ore_value": 112,
		&"ingot_value": 403,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "Densest of the stable metals; counterweights and penetrator tips.",
		&"icon_ore": "res://assets/icons/mineral/icon_mineral_osmium.svg",
		&"icon_ingot": "res://assets/icons/ingot/icon_ingot_osmium.svg",
	},
	{
		&"id": &"palladium",
		&"name": "Palladium",
		&"tier": 4,
		&"ore_value": 145,
		&"ingot_value": 522,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "Exotic catalysts, half way to the strange stuff past the rim.",
		&"icon_ore": "res://assets/icons/mineral/icon_mineral_palladium.svg",
		&"icon_ingot": "res://assets/icons/ingot/icon_ingot_palladium.svg",
	},
	{
		&"id": &"cerulite",
		&"name": "Cerulite",
		&"tier": 4,
		&"ore_value": 159,
		&"ingot_value": 572,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "Blue veined crystal ore; feedstock for shield lattices.",
		&"icon_ore": "res://assets/icons/mineral/icon_mineral_cerulite.svg",
		&"icon_ingot": "res://assets/icons/ingot/icon_ingot_cerulite.svg",
	},
	{
		&"id": &"emberite",
		&"name": "Emberite",
		&"tier": 4,
		&"ore_value": 175,
		&"ingot_value": 630,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "Warm to the touch, and reactor cores run on that heat.",
		&"icon_ore": "res://assets/icons/mineral/icon_mineral_emberite.svg",
		&"icon_ingot": "res://assets/icons/ingot/icon_ingot_emberite.svg",
	},
	{
		&"id": &"voidglass",
		&"name": "Voidglass",
		&"tier": 4,
		&"ore_value": 201,
		&"ingot_value": 724,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "Shards of something older than the colonies; sensor optics buy it and stranger trades ask.",
		&"icon_ore": "res://assets/icons/mineral/icon_mineral_voidglass.svg",
		&"icon_ingot": "res://assets/icons/ingot/icon_ingot_voidglass.svg",
	},
	{
		&"id": &"krilium",
		&"name": "Krillum",
		&"tier": 4,
		&"ore_value": 224,
		&"ingot_value": 806,
		&"ore_units": 1,
		&"ingot_units": 1,
		&"description": "The apex ore: a trade name, not a chemistry, and no two refineries agree what is in it.",
		&"icon_ore": "res://assets/icons/mineral/icon_mineral_krilium.svg",
		&"icon_ingot": "res://assets/icons/ingot/icon_ingot_krilium.svg",
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
	var table: Dictionary = OreTuningScript.tier_base_yield
	var base: int = int(table.get(tier, 0))
	return maxi(1, roundi(base * rng.randf_range(
		OreTuningScript.yield_variance_min, OreTuningScript.yield_variance_max
	)))


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
