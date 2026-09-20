class_name SectorRegistry
extends RefCounted
## Read-only sector registry: 11 §1's seven sectors with 11 §1.1's tier mixes,
## owner factions, backdrop ids and spawn densities.
## Data, not logic: no nodes, no autoload, no mutation API.
## Contract: docs/gameplay/11_galactic_map.md §1/§1.1/§3, ENGINE_SPEC.md §2
## decision 4, §8 and §13. Brief: .agents/gen/engine_wave1_task.md item 8.
##
## Row keys are exactly the six pinned by the brief: `id`, `name`, `owner`,
## `tier_weights`, `backdrop_id`, `densities`. 11 §4 also names `neighbours`
## and `gate links`; both are gate-slice data (slice 3) and are deliberately
## absent until a consumer needs them.
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
			&"backdrop_id": "res://assets/env/env_sector_1_bg.png",
			&"densities": _densities(0, 1, 1, 0, 1),
		},
		{
			&"id": &"sector_2",
			&"name": "Iron Marches",
			&"owner": &"concord",
			&"tier_weights": MineralCatalogScript.SECTOR_TIER_MIX[2],
			&"backdrop_id": "res://assets/env/env_sector_2_bg.png",
			&"densities": _densities(1, 2, 1, 1, 1),
		},
		{
			&"id": &"sector_3",
			&"name": "Meridian Span",
			&"owner": &"meridian",
			&"tier_weights": MineralCatalogScript.SECTOR_TIER_MIX[3],
			&"backdrop_id": "res://assets/env/env_sector_3_bg.png",
			&"densities": _densities(2, 3, 1, 0, 1),
		},
		{
			&"id": &"sector_4",
			&"name": "Ashveil Expanse",
			&"owner": &"meridian",
			&"tier_weights": MineralCatalogScript.SECTOR_TIER_MIX[4],
			&"backdrop_id": "res://assets/env/env_sector_4_bg.png",
			&"densities": _densities(3, 4, 1, 1, 1),
		},
		{
			&"id": &"sector_5",
			&"name": "Cinder Verge",
			&"owner": &"choir",
			&"tier_weights": MineralCatalogScript.SECTOR_TIER_MIX[5],
			&"backdrop_id": "res://assets/env/env_sector_5_bg.png",
			&"densities": _densities(3, 5, 1, 1, 1),
		},
		{
			&"id": &"sector_6",
			&"name": "The Hollows",
			&"owner": &"choir",
			&"tier_weights": MineralCatalogScript.SECTOR_TIER_MIX[6],
			&"backdrop_id": "res://assets/env/env_sector_6_bg.png",
			&"densities": _densities(4, 6, 1, 0, 1),
		},
		{
			&"id": &"sector_7",
			&"name": "Maw Belt",
			&"owner": UNALIGNED,
			&"tier_weights": MineralCatalogScript.SECTOR_TIER_MIX[7],
			&"backdrop_id": "res://assets/env/env_sector_7_bg.png",
			&"densities": _densities(6, 8, 0, 0, 0),
		},
	]


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
