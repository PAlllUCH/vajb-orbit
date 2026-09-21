@tool
extends McpTestSuite
## Suite p2a_ship_roster: `StationCatalog.SHIPS` carries all nine player hulls in
## 08 section 2's ladder order, with that table's frozen cost/hull/shield/cargo,
## the hull's own side render as its preview, and `hardpoints` equal to the
## hull's W-slot count (`FitData.HULLS[id].weapons`, the same value 08 section 3's
## grid derives). Pure data: no scene instancing, no editor API, no MCP.

const Catalog := preload("res://game/station_catalog.gd")
const FitData := preload("res://game/ship_fit.gd")

## 08 section 2 verbatim, in its ladder order: id, display name and the frozen
## cost / hull / shield / cargo columns plus the Weapons column (the △ rows as
## amended 2026-09-21).
const LADDER: Array[Dictionary] = [
	{
		"id": &"ship_fighter",
		"name": "Lancer",
		"cost": 9000,
		"hull": 700,
		"shield": 400,
		"cargo": 25,
		"weapons": 2,
	},
	{
		"id": &"ship_vanguard",
		"name": "Vanguard",
		"cost": 18000,
		"hull": 1000,
		"shield": 600,
		"cargo": 40,
		"weapons": 3,
	},
	{
		"id": &"ship_miner",
		"name": "Delver",
		"cost": 16000,
		"hull": 1100,
		"shield": 500,
		"cargo": 55,
		"weapons": 2,
	},
	{
		"id": &"ship_trader",
		"name": "Courier",
		"cost": 21000,
		"hull": 950,
		"shield": 550,
		"cargo": 60,
		"weapons": 1,
	},
	{
		"id": &"ship_corvette",
		"name": "Spearhead",
		"cost": 27000,
		"hull": 1300,
		"shield": 700,
		"cargo": 35,
		"weapons": 4,
	},
	{
		"id": &"ship_freighter",
		"name": "Mule",
		"cost": 24000,
		"hull": 1600,
		"shield": 500,
		"cargo": 120,
		"weapons": 1,
	},
	{
		"id": &"ship_gunship",
		"name": "Bulwark",
		"cost": 36000,
		"hull": 1400,
		"shield": 650,
		"cargo": 50,
		"weapons": 5,
	},
	{
		"id": &"ship_patrol",
		"name": "Warden",
		"cost": 54000,
		"hull": 1800,
		"shield": 800,
		"cargo": 60,
		"weapons": 4,
	},
	{
		"id": &"ship_destroyer",
		"name": "Obliterator",
		"cost": 72000,
		"hull": 2200,
		"shield": 900,
		"cargo": 80,
		"weapons": 7,
	},
]


func suite_name() -> String:
	return "p2a_ship_roster"


func test_roster_is_the_nine_hull_ladder() -> void:
	assert_eq(Catalog.SHIPS.size(), LADDER.size(), "the roster is all nine player hulls")
	assert_eq(Catalog.ship_ids().size(), LADDER.size(), "one id per hull, no duplicates")
	for index: int in LADDER.size():
		var expected: Dictionary = LADDER[index]
		var row: Dictionary = Catalog.SHIPS[index]
		assert_eq(
			row.get(&"id", &""),
			expected["id"],
			"ladder position %d is %s" % [index, String(expected["id"])]
		)
		assert_eq(
			row.get(&"name", ""),
			expected["name"],
			"%s keeps its 08 section 2 name" % String(expected["id"])
		)


func test_frozen_cost_hull_shield_cargo() -> void:
	for expected: Dictionary in LADDER:
		var ship_id: StringName = expected["id"]
		var row: Dictionary = Catalog.ship(ship_id)
		assert_eq(int(row.get(&"cost", 0)), int(expected["cost"]), "%s cost" % String(ship_id))
		assert_eq(int(row.get(&"hull", 0)), int(expected["hull"]), "%s hull" % String(ship_id))
		assert_eq(int(row.get(&"shield", 0)), int(expected["shield"]), "%s shield" % String(ship_id))
		assert_eq(int(row.get(&"cargo", 0)), int(expected["cargo"]), "%s cargo" % String(ship_id))


func test_previews_are_the_hull_side_renders_on_disk() -> void:
	for expected: Dictionary in LADDER:
		var ship_id: StringName = expected["id"]
		var stem := String(ship_id).trim_prefix("ship_")
		var wanted := "res://assets/ships/ship_%s_side.png" % stem
		var row: Dictionary = Catalog.ship(ship_id)
		var preview := String(row.get(&"preview", ""))
		assert_eq(preview, wanted, "%s preview is its own side render" % String(ship_id))
		assert_true(ResourceLoader.exists(preview), "%s is imported" % preview)
		assert_true(FileAccess.file_exists(preview), "%s is on disk" % preview)


func test_hardpoints_match_the_hull_grid_count() -> void:
	for expected: Dictionary in LADDER:
		var ship_id: StringName = expected["id"]
		var row: Dictionary = Catalog.ship(ship_id)
		var hull: Dictionary = FitData.HULLS.get(ship_id, {})
		assert_false(hull.is_empty(), "%s is a ShipFit hull" % String(ship_id))
		assert_eq(
			int(row.get(&"hardpoints", 0)),
			int(expected["weapons"]),
			"%s hardpoints are 08 section 2's Weapons column" % String(ship_id)
		)
		assert_eq(
			int(row.get(&"hardpoints", 0)),
			int(hull.get(&"weapons", 0)),
			"%s hardpoints equal the hull's grid weapons count" % String(ship_id)
		)
