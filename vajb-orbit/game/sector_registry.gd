class_name SectorRegistry
extends RefCounted
## Read-only sector registry: 11 §1's seven sectors with 11 §1.1's tier mixes,
## owner factions, backdrop ids and spawn densities.
## Data, not logic: no nodes, no autoload, no mutation API.
## Contract: docs/gameplay/11_galactic_map.md §1/§1.1/§3, ENGINE_SPEC.md §2
## decision 4, §8 and §13. Contract: docs/CONTRACTS.md §6.
##
## Row keys are the six pinned by the brief - `id`, `name`, `owner`,
## `tier_weights`, `backdrop_id`, `densities` - plus the three S6 travel keys the
## CONTRACTS §19 pin adds: `neighbours`, `gate_links` and `corridors`. 11 §4's
## "neighbours, gate links" are the 1-2-3-4-5-6-7 spine of 11 §2.3, filled below
## by `_spine_neighbours`/`_corridors_for` so the seven rows cannot drift apart.
##
## Owner ids (`concord`, `meridian`, `choir`, `unaligned`) are the short forms
## 12 §3 uses for the factions' economy rows. No spelling existed in code before
## this file; 12 §4/17 §2 name `game/faction_registry.gd` as the future owner,
## which should adopt these four.
##
## `tier_weights` references `MineralCatalog.SECTOR_TIER_MIX`, the existing copy
## of 11 §1.1, so the table has one home. `backdrop_id` points at the shipped
## per-sector backdrop recorded in docs/design/ASSET_CATALOG.md (all seven
## shipped, Phase F); this slice has no backdrop wiring item in ENGINE_SPEC §14,
## so the sector leaves the game scene's starfield layers in place (see
## game/sector.gd).

const MineralCatalogScript := preload("res://game/mineral_catalog.gd")

## The one arena size (ENGINE_SPEC §2 decision 4, §8, §13): every sector is
## 10 000 × 10 000 u. Sectors differ by backdrop, owner, tier mix, enemy mix and
## hazards, never by size.
const SECTOR_SIZE := Vector2(10000.0, 10000.0)

const UNALIGNED: StringName = &"unaligned"

## 11 §3's population targets, identical in every sector (the per-sector
## differences are the pirate band, stations, outposts and convoys below):
## 4-8 fields, 6-12 rocks each (ENGINE_SPEC §8), 1-3 wreck fields of 3-6 hulks
## plus one scannable derelict each (11 §3.1), 1-2 anomalies (11 §3.2).
const FIELDS_MIN := 4
const FIELDS_MAX := 8
const ROCKS_MIN := 6
const ROCKS_MAX := 12
const WRECKS_MIN := 1
const WRECKS_MAX := 3
const HULKS_MIN := 3
const HULKS_MAX := 6
const DERELICTS_PER_WRECK_FIELD := 1
const ANOMALIES_MIN := 1
const ANOMALIES_MAX := 2

## 11 §2.1's gate fee (CONTRACTS §19): 150 CR base + 100 CR per sector of distance
## along the §2.3 spine. Adjacent = 250, two away = 350. Both are the doc's own
## numbers; the fee is composed in `game/gate.gd` (11 §5's multipliers).
const GATE_FEE_BASE := 150
const GATE_FEE_PER_SECTOR := 100

## 11 §2.2/§5's map-edge corridor band: 600 u inward from an arena edge (proposed,
## reversal 400.0). The spine runs west→east, so a lower-numbered neighbour sits on
## the west band and a higher-numbered one on the east band.
const CORRIDOR_DEPTH := 600.0

## 11 §5's POI numbers, owned here because this table is the only home the pin gives
## them and `game/poi.gd` reads them (300.0 proposed, reversal the fit's `scan_range`;
## 12.0 proposed, reversal 6.0). The Hollows (sector 6) roll `void_rift` at 2× weight
## (11 §3.2).
const DERELICT_SCAN_RANGE := 300.0
const RIFT_DRAIN := 12.0
const ANOMALY_WEIGHTS_RIFT_DOUBLED: Array[StringName] = [&"sector_6"]

## The spine's last sector: 11 §1/§2.1's only lawless one, where a gate charges ×2.
const LAWLESS_SECTOR := 7
const SPINE_FIRST := 1
const SPINE_LAST := 7

static var SECTORS: Array[Dictionary] = []


## Fills SECTORS once, at class load. A static initializer (not a const literal)
## because `tier_weights` must read the 11 §1.1 table out of `MineralCatalog`
## rather than duplicate its numbers here.
static func _static_init() -> void:
	SECTORS = [
		{
			&"id": &"sector_1",
			&"name": "Halcyon Reach",
			&"owner": &"concord",
			&"tier_weights": MineralCatalogScript.SECTOR_TIER_MIX[1],
			&"backdrop_id": "res://assets/env/backdrop/env_sector_1_bg.png",
			&"densities": _densities(0, 1, 1, 0, 1),
		},
		{
			&"id": &"sector_2",
			&"name": "Iron Marches",
			&"owner": &"concord",
			&"tier_weights": MineralCatalogScript.SECTOR_TIER_MIX[2],
			&"backdrop_id": "res://assets/env/backdrop/env_sector_2_bg.png",
			&"densities": _densities(1, 2, 1, 1, 1),
		},
		{
			&"id": &"sector_3",
			&"name": "Meridian Span",
			&"owner": &"meridian",
			&"tier_weights": MineralCatalogScript.SECTOR_TIER_MIX[3],
			&"backdrop_id": "res://assets/env/backdrop/env_sector_3_bg.png",
			&"densities": _densities(2, 3, 1, 0, 1),
		},
		{
			&"id": &"sector_4",
			&"name": "Ashveil Expanse",
			&"owner": &"meridian",
			&"tier_weights": MineralCatalogScript.SECTOR_TIER_MIX[4],
			&"backdrop_id": "res://assets/env/backdrop/env_sector_4_bg.png",
			&"densities": _densities(3, 4, 1, 1, 1),
		},
		{
			&"id": &"sector_5",
			&"name": "Cinder Verge",
			&"owner": &"choir",
			&"tier_weights": MineralCatalogScript.SECTOR_TIER_MIX[5],
			&"backdrop_id": "res://assets/env/backdrop/env_sector_5_bg.png",
			&"densities": _densities(3, 5, 1, 1, 1),
		},
		{
			&"id": &"sector_6",
			&"name": "The Hollows",
			&"owner": &"choir",
			&"tier_weights": MineralCatalogScript.SECTOR_TIER_MIX[6],
			&"backdrop_id": "res://assets/env/backdrop/env_sector_6_bg.png",
			&"densities": _densities(4, 6, 1, 0, 1),
		},
		{
			&"id": &"sector_7",
			&"name": "Maw Belt",
			&"owner": UNALIGNED,
			&"tier_weights": MineralCatalogScript.SECTOR_TIER_MIX[7],
			&"backdrop_id": "res://assets/env/backdrop/env_sector_7_bg.png",
			&"densities": _densities(6, 8, 0, 0, 0),
		},
	]
	## The §2.3 spine, appended after the row literals so each row stays a readable
	## data block: neighbours and gate_links are the same adjacent set (one ring per
	## link), and every corridor carries the map edge its destination sits on.
	for index in SECTORS.size():
		var number := index + 1
		SECTORS[index][&"neighbours"] = _spine_neighbours(number)
		SECTORS[index][&"gate_links"] = _spine_neighbours(number)
		SECTORS[index][&"corridors"] = _corridors_for(number)


## 11 §2.3's spine neighbours of one sector number: 1↔2↔3↔4↔5↔6↔7, one spine and no
## shortcuts, so sector 1 and 7 each have one and every middle sector two.
static func _spine_neighbours(number: int) -> Array[int]:
	var out: Array[int] = []
	if number > SPINE_FIRST:
		out.append(number - 1)
	if number < SPINE_LAST:
		out.append(number + 1)
	return out


## One corridor per spine neighbour: `{dest, edge_rect}`, the `edge_rect` being the
## CORRIDOR_DEPTH-deep band inward from the map edge the destination sits beyond.
static func _corridors_for(number: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for dest: int in _spine_neighbours(number):
		var west := dest < number
		out.append({&"dest": dest, &"edge_rect": edge_band(-1 if west else 1)})
	return out


## The map-edge band a corridor occupies, in the sector node's own centred arena
## coordinates (the arena centre is the origin): `direction` negative is the west
## edge, positive the east. 10 000 u arena, so the band spans
## `[-5000, -5000 + CORRIDOR_DEPTH]` (west) or `[5000 - CORRIDOR_DEPTH, 5000]` (east).
static func edge_band(direction: int) -> Rect2:
	var half := SECTOR_SIZE * 0.5
	if direction < 0:
		return Rect2(
			Vector2(-half.x, -half.y), Vector2(CORRIDOR_DEPTH, SECTOR_SIZE.y)
		)
	return Rect2(
		Vector2(half.x - CORRIDOR_DEPTH, -half.y), Vector2(CORRIDOR_DEPTH, SECTOR_SIZE.y)
	)


## One sector number from its id (`&"sector_3"` → 3), or 0 for anything else.
static func sector_number(sector_id: StringName) -> int:
	var digits := String(sector_id).trim_prefix("sector_")
	return int(digits) if digits.is_valid_int() else 0


## The id one sector number names (`3` → `&"sector_3"`).
static func sector_id_for(number: int) -> StringName:
	return StringName("sector_%d" % number)


## 11 §2.1's "distance" along the §2.3 spine: the number of links between two
## sectors, so adjacent = 1 and two away = 2.
static func distance(from_number: int, to_number: int) -> int:
	return absi(to_number - from_number)


## One sector row by id, or an empty dictionary for an unknown id.
static func sector(sector_id: StringName) -> Dictionary:
	for row: Dictionary in SECTORS:
		if StringName(row.get(&"id", &"")) == sector_id:
			return row
	return {}


static func sector_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for row: Dictionary in SECTORS:
		ids.append(StringName(row.get(&"id", &"")))
	return ids


## The §8 population targets, with only the four per-sector numbers passed in.
## `pirates` is ENGINE_SPEC §13's per-sector band (S1 0-1, S2 1-2, S3 2-3,
## S4 3-4, S5 3-5, S6 4-6, S7 6-8); `stations` is 0 only where ENGINE_SPEC §7
## makes the sector hardcore (no station, so safe warp reports unavailable);
## `outposts` follows 14 §8 (S2 outpost, S4 outpost, S5 shrine); `convoys` is
## 11 §3's one active convoy per inhabited sector, so 0 in unaligned space.
static func _densities(
	pirates_min: int, pirates_max: int, stations: int, outposts: int, convoys: int
) -> Dictionary:
	return {
		&"pirate_min": pirates_min,
		&"pirate_max": pirates_max,
		&"stations": stations,
		&"outposts": outposts,
		&"convoys": convoys,
		&"fields_min": FIELDS_MIN,
		&"fields_max": FIELDS_MAX,
		&"rocks_min": ROCKS_MIN,
		&"rocks_max": ROCKS_MAX,
		&"wrecks_min": WRECKS_MIN,
		&"wrecks_max": WRECKS_MAX,
		&"hulks_min": HULKS_MIN,
		&"hulks_max": HULKS_MAX,
		&"derelicts_per_wreck_field": DERELICTS_PER_WRECK_FIELD,
		&"anomalies_min": ANOMALIES_MIN,
		&"anomalies_max": ANOMALIES_MAX,
	}
