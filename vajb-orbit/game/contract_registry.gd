class_name ContractRegistry
extends RefCounted
## The contracts board (wave S25): 14_station_services.md section 2's five types as
## parameterized tables, the seeded 6-row board, the reward law, the standing gates, the
## escrow lifecycle and the escort plan. Data plus static functions, no nodes and no
## autoload: every call takes the profile as a `Node`, so a headless probe and the station
## shell read the same code.
##
## Contract: docs/gameplay/14_station_services.md section 2 (the reward shapes, the escrow,
## the 100 CR cancel fee, max 3 active, the standing gates) and section 6 (the escort loop)
## plus its 2026-09-27 P3 block (R-S25-1: 6 rows per board, Expedition staged, tick J1) and
## its 2026-10-08 S28 block (every flat reward scales x SC(t)/SC(1) by the **target**
## sector's tier, rounded to 100 CR); docs/gameplay/01_economy_core.md's 2026-10-08 block
## (the SC table, verbatim); docs/gameplay/12_factions.md section 3 (the demand biases) and
## section 4.1 (the bands) plus its 2026-10-08 S24 block (V3's `contracts_visible`).
##
## **The reward law, in one place.** A contract's `reward` is always a multiple of 100 CR:
##   * Hunt  = round100(HUNT_FLAT x SC(t)/SC(1))
##   * Escort = round100(ESCORT_FLAT x SC(t)/SC(1))
##   * Haul  = round100(round(HAUL_SPOT x spot) + round100(HAUL_FLAT x SC(t)/SC(1)))
##   * Gather = round100(round(GATHER_ORE x goods))
## where `t` is the **target** sector's tier (`SectorRegistry.sector_tier`), `spot`/`goods`
## is `Exchange.sale_quote`'s gross for the contract's own stack at the **target faction's**
## biased demand (12 section 3), and the SC table is 01's block verbatim - never re-derived.
## `pay()` is what the player is actually credited: the band's own +5 % at Known and above
## (12 section 4.1), which is a pay-band adjustment and not part of the board's price.
##
## **The gate is S24's seam** (`StationRegistry.contracts_visible`), read here and never
## redefined; **the exchange is read-only** (`sale_quote`, `baseline_of`).
##
## **The row shape** (14 section 9: "contracts are Resource-style dictionaries like
## everything else") - the same dictionary is a board row and an active record, with
## `escrow` empty until accept:
##   `id`, `type`, `faction`, `origin_station`, `origin_sector`, `sector`,
##   `target_station`, `item_id`, `quantity`, `count`, `convoy`, `tier`, `band`,
##   `reward`, `standing`, `objective`, `staged`, `escrow`, `accepted_at`.
##
## **Every live type has one production exit**, and all four go through `complete()`, so the
## escrow is consumed exactly once and the purse moves exactly once: Haul and Gather close at
## the dock (`deliver_at`, the station `delivery_station` names - a Haul's destination, the
## station a Gather was taken at), Hunt closes on the last credited kill (`credit_kill`, from
## the flight scene's own death handler), and Escort closes on the convoy's arrival at the
## gate (`escort_won`) or its death (`escort_lost`).

const Clock := preload("res://autoload/world_clock.gd")
const StationRegistryScript := preload("res://game/station_registry.gd")
const SectorRegistryScript := preload("res://game/sector_registry.gd")
const ExchangeScript := preload("res://game/exchange.gd")
const MineralCatalogScript := preload("res://game/mineral_catalog.gd")
const ComponentCatalogScript := preload("res://game/component_catalog.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const NpcRegistryScript := preload("res://game/npc_registry.gd")
const Log := preload("res://game/economy_log.gd")

## R-S25-1 (14's 2026-09-27 P3 block, tick J1): six rows visible per board, re-rolled on
## section 9's 20-minute clock. Reversal: a board-size edit.
const BOARD_SIZE := 6
## 14 section 2: "they occupy cargo or standing slots (max 3 active contracts)".
const MAX_ACTIVE := 3
## 14 section 2: "removable by cancelling for a 100 CR fee".
const CANCEL_FEE := 100
## 14's 2026-10-08 S28 block: "rounded to 100 CR".
const ROUND_UNIT := 100

## 01's 2026-10-08 block, verbatim: SC(t) for t1..t4. Never re-derived here.
const SC: Array[int] = [1100, 1500, 3000, 6000]

## 14 section 2's T1 reward shapes.
const HUNT_FLAT := 800
const ESCORT_FLAT := 1200
## M11's derived row (14's S28 block: "each sector's flat rewards scale"): 300/1 100 x SC(t)
## reads 300 / 400 / 800 / 1 600. Reversal: Haul's flat stays 300 at every tier.
const HAUL_FLAT := 300
const HAUL_SPOT := 1.25
const GATHER_ORE := 1.4

## 12 section 4.1's Known row: "contracts pay +5 %". The floor is the row's own band edge
## (`StationRegistry.KNOWN_FLOOR` is not shipped; the +11 edge is read from the band table's
## own word here).
const KNOWN_FLOOR := 11
const KNOWN_HOOK := 0.05

## 14 section 2's standing column, plus section 6's loss row.
const STANDING_HAUL := 2
const STANDING_HUNT := 1
const STANDING_GATHER := 2
const STANDING_ESCORT := 5
const STANDING_LOSS := -5
## 14 section 2's Expedition row ("arena payout, +3 standing"). Staged until S26.
const STANDING_EXPEDITION := 3

## 14 section 2's Example column, read as the parameterized quantities.
const HAUL_QUANTITY := 40
const GATHER_QUANTITY := 20
const HUNT_COUNT := 5
const ESCORT_CONVOYS := 1

## 14 section 6's convoy: "1 hauler-class AI hull + 1-2 fighter escorts", "50 % of hold
## filled with visible cargo pods". The hulls are 13 section 5's own convoy row
## (`NpcRegistry.CONVOY_HAULER` / `CONVOY_ESCORT`).
const ESCORT_POD_FRACTION := 0.5
const ESCORT_FIGHTERS := Vector2i(1, 2)
## The visible load: how many pod marks dress the escort hauler's hull. PROPOSED (no doc
## pins a mark count); reversal: one mark per pod.
const ESCORT_POD_MARKS := 4
const ESCORT_POD_TEXTURE := "res://assets/env/pickup/env_pickup_ore_pod.png"
## 14 section 6: "flies a fixed route to a target sector's gate". The route's three legs,
## in order - the ambush leg is 11 section 2.2's corridor midpoint.
const ESCORT_LEG_STATION: StringName = &"station"
const ESCORT_LEG_MIDPOINT: StringName = &"corridor_midpoint"
const ESCORT_LEG_GATE: StringName = &"gate"
const ESCORT_LEGS: Array[StringName] = [
	ESCORT_LEG_STATION, ESCORT_LEG_MIDPOINT, ESCORT_LEG_GATE
]
const ESCORT_AMBUSH_LEG := 1
## The ambush trigger radius: the corridor band's own depth (`SectorRegistry.CORRIDOR_DEPTH`),
## so "the corridor is where pirates ambush" is the band the convoy is inside.
const ESCORT_AMBUSH_RADIUS := SectorRegistryScript.CORRIDOR_DEPTH

const TYPE_HAUL: StringName = &"haul"
const TYPE_HUNT: StringName = &"hunt"
const TYPE_GATHER: StringName = &"gather"
const TYPE_ESCORT: StringName = &"escort"
const TYPE_EXPEDITION: StringName = &"expedition"

## 14 section 2's four shipping rows (R-S25-1): Expedition is the fifth type and ships as
## the seam row - it draws greyed with the `STAGED` chip and refuses accept until S26 flips
## `staged` off.
const LIVE_TYPES: Array[StringName] = [TYPE_HAUL, TYPE_HUNT, TYPE_GATHER, TYPE_ESCORT]

const LABEL_HAUL := "HAUL"
const LABEL_HUNT := "HUNT"
const LABEL_GATHER := "GATHER"
const LABEL_ESCORT := "ESCORT"
const LABEL_EXPEDITION := "EXPEDITION"

## STATION_HUB section 15.2's own icon rows (`icon_contract_<type>.svg`).
const ICON_DIR := "res://assets/icons/contract/"
const ICON_TEMPLATE := "icon_contract_%s.svg"

## STATION_HUB section 15.2's objective shapes, filled from the row's own numbers. Haul
## names the destination station's own row name (W3's nine names) because "to S%d outpost"
## cannot hold for a destination sector whose primary is not an outpost. Reversal: the
## literal `to S%d outpost` wording.
const OBJECTIVE_HAUL := "%d× %s to %s"
const OBJECTIVE_HUNT := "Destroy %d pirates in S%d"
const OBJECTIVE_GATHER := "%d× %s ore (raw)"
const OBJECTIVE_ESCORT := "Protect convoy %d to S%d gate"
const OBJECTIVE_EXPEDITION := "arena contract"

## 12 section 3's demand-bias categories. The biases are the doc's own floats, per
## category; the exchange's `DEMAND_MIN`/`DEMAND_MAX` clamp the reading.
const BIAS_INGOT_T12: StringName = &"ingot_t12"
const BIAS_INGOT_T34: StringName = &"ingot_t34"
const BIAS_ORE_T3: StringName = &"ore_t3"
const BIAS_ORE_T12: StringName = &"ore_t12"
const BIAS_T12: StringName = &"t12"
const BIAS_COMPONENT: StringName = &"component"
const BIAS_EXOTIC_COMPONENT: StringName = &"exotic_component"

const DEMAND_BIAS: Dictionary = {
	&"concord": {BIAS_INGOT_T12: 0.15, BIAS_COMPONENT: -0.10},
	&"meridian": {BIAS_COMPONENT: 0.20, BIAS_ORE_T3: 0.10},
	&"choir": {BIAS_INGOT_T34: 0.25, BIAS_EXOTIC_COMPONENT: 0.25, BIAS_T12: -0.15},
}

## The refusal vocabulary. `insufficient_cargo` and `insufficient_credits` are the
## spellings the exchange and the station shell already use.
const REASON_STAGED: StringName = &"staged"
const REASON_GATED: StringName = &"gated"
const REASON_FULL: StringName = &"max_active"
const REASON_INSUFFICIENT_CARGO: StringName = &"insufficient_cargo"
const REASON_INSUFFICIENT_CREDITS: StringName = &"insufficient_credits"
const REASON_UNKNOWN: StringName = &"unknown_contract"
const REASON_NOT_ACTIVE: StringName = &"not_active"

const EVENT_ACCEPT := "CONTRACT_ACCEPT"
const EVENT_CANCEL := "CONTRACT_CANCEL"
const EVENT_COMPLETE := "CONTRACT_COMPLETE"
const EVENT_FAILED := "CONTRACT_FAILED"


## ---------------------------------------------------------------------------
## The board
## ---------------------------------------------------------------------------


## V3's gate, read through S24's seam. Never redefined here.
static func visible(standing: int) -> bool:
	return StationRegistryScript.contracts_visible(standing)


## The band index one timestamp falls in (14 section 9's 20-minute clock).
static func band_index(timestamp: int = -1) -> int:
	var reading := timestamp if timestamp > 0 else Clock.now()
	@warning_ignore("integer_division")
	return reading / Clock.BAND_SECONDS


## The board one station offers a player at one standing: six rows (R-S25-1) - five rolled
## live rows plus the Expedition seam row, or four rolled rows plus the Champion's standing
## order (12 section 4.1) plus the seam. An empty station row and a gated standing both
## answer an empty board (STATION_HUB section 15.2's two U8 empty states).
static func board(
	station_row: Dictionary, standing: int, timestamp: int = -1
) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if station_row.is_empty() or not visible(standing):
		return rows
	var band := band_index(timestamp)
	var origin_station := StringName(station_row.get(&"id", &""))
	var origin_sector := int(station_row.get(&"sector", 0))
	var rng := _rng_for(origin_station, band)
	var rolled := BOARD_SIZE - 1
	if standing >= StationRegistryScript.CHAMPION_FLOOR:
		rolled -= 1
		rows.append(_standing_order(origin_station, origin_sector, band))
	var order := LIVE_TYPES.duplicate()
	_shuffle(order, rng)
	for index in rolled:
		rows.append(
			_roll(StringName(order[index % order.size()]), origin_station, origin_sector, band, index, rng)
		)
	rows.append(_expedition_row(origin_station, origin_sector, band))
	return rows


## The seeded stream one (station, band) owns: a fixed seed answers the same board, so a
## probe can re-derive it (rule 3: generation is seeded and probe-able).
static func _rng_for(station_id: StringName, band: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|%d" % [String(station_id), band])
	return rng


## One rolled row. The target sector is the docked one for Hunt and Gather ("in S2", the
## local belt) and a neighbouring sector with a station for Haul and Escort ("to S4"), so
## every objective is sector-appropriate and every faction tie is the destination's
## (14 section 2: "hauling to Meridian pays differently than to the Choir").
static func _roll(
	type: StringName, origin_station: StringName, origin_sector: int, band: int, index: int, rng: RandomNumberGenerator
) -> Dictionary:
	match type:
		TYPE_HAUL:
			return _haul_row(origin_station, origin_sector, band, index, rng)
		TYPE_HUNT:
			return _hunt_row(origin_station, origin_sector, band, index)
		TYPE_GATHER:
			return _gather_row(origin_station, origin_sector, band, index, rng)
		TYPE_ESCORT:
			return _escort_row(origin_station, origin_sector, band, index, rng)
	return {}


static func _haul_row(
	origin_station: StringName, origin_sector: int, band: int, index: int, rng: RandomNumberGenerator
) -> Dictionary:
	var destination := _destination_station(origin_sector, rng)
	var target_sector := int(destination.get(&"sector", origin_sector))
	var item_id := _ingot_for(target_sector, rng)
	var row := _base_row(TYPE_HAUL, origin_station, origin_sector, band, index, target_sector)
	row[&"faction"] = StringName(destination.get(&"faction", &""))
	row[&"target_station"] = StringName(destination.get(&"id", &""))
	row[&"item_id"] = item_id
	row[&"quantity"] = HAUL_QUANTITY
	row[&"standing"] = standing_for(TYPE_HAUL)
	row[&"objective"] = OBJECTIVE_HAUL % [
		HAUL_QUANTITY, String(item_id), String(destination.get(&"name", ""))
	]
	row[&"reward"] = reward(row)
	return row


static func _hunt_row(
	origin_station: StringName, origin_sector: int, band: int, index: int
) -> Dictionary:
	var row := _base_row(TYPE_HUNT, origin_station, origin_sector, band, index, origin_sector)
	row[&"faction"] = _sector_owner(origin_sector)
	row[&"count"] = HUNT_COUNT
	row[&"standing"] = standing_for(TYPE_HUNT)
	row[&"objective"] = OBJECTIVE_HUNT % [HUNT_COUNT, origin_sector]
	row[&"reward"] = reward(row)
	return row


static func _gather_row(
	origin_station: StringName, origin_sector: int, band: int, index: int, rng: RandomNumberGenerator
) -> Dictionary:
	var row := _base_row(TYPE_GATHER, origin_station, origin_sector, band, index, origin_sector)
	row[&"faction"] = _sector_owner(origin_sector)
	row[&"item_id"] = _ore_for(origin_sector, rng)
	row[&"quantity"] = GATHER_QUANTITY
	row[&"standing"] = standing_for(TYPE_GATHER)
	row[&"objective"] = OBJECTIVE_GATHER % [GATHER_QUANTITY, String(row[&"item_id"])]
	row[&"reward"] = reward(row)
	return row


static func _escort_row(
	origin_station: StringName, origin_sector: int, band: int, index: int, rng: RandomNumberGenerator
) -> Dictionary:
	var destination := _destination_station(origin_sector, rng)
	var target_sector := int(destination.get(&"sector", origin_sector))
	var row := _base_row(TYPE_ESCORT, origin_station, origin_sector, band, index, target_sector)
	row[&"faction"] = StringName(destination.get(&"faction", &""))
	row[&"target_station"] = StringName(destination.get(&"id", &""))
	## The convoy's own number: the board row's own ordinal (1..6). No doc pins a fleet
	## number. Reversal: a rolled 1-9.
	row[&"convoy"] = index + 1
	row[&"count"] = ESCORT_CONVOYS
	row[&"standing"] = standing_for(TYPE_ESCORT)
	row[&"objective"] = OBJECTIVE_ESCORT % [index + 1, target_sector]
	## The convoy's trade: 14 section 6's "50 % of hold filled with visible cargo pods", in
	## the destination's own trade good, so a loss drops exactly what the pirates took.
	row[&"item_id"] = _ingot_for(target_sector, rng)
	row[&"quantity"] = escort_pods()
	row[&"reward"] = reward(row)
	return row


## 12 section 4.1's Champion row: "one standing-order contract always available". It is a
## permanent delivery to a neighbour (no band, so it cannot expire) and it takes one of the
## board's six rows. Reversal: a seventh row appended.
static func _standing_order(origin_station: StringName, origin_sector: int, band: int) -> Dictionary:
	var rng := _rng_for(origin_station, 0)
	var destination := _destination_station(origin_sector, rng)
	var target_sector := int(destination.get(&"sector", origin_sector))
	var item_id := _ingot_for(target_sector, rng)
	var row := _base_row(TYPE_HAUL, origin_station, origin_sector, band, 0, target_sector)
	row[&"id"] = StringName("c_%s_standing" % String(origin_station))
	row[&"faction"] = StringName(destination.get(&"faction", &""))
	row[&"target_station"] = StringName(destination.get(&"id", &""))
	row[&"item_id"] = item_id
	row[&"quantity"] = HAUL_QUANTITY
	row[&"standing"] = standing_for(TYPE_HAUL)
	row[&"standing_order"] = true
	row[&"objective"] = OBJECTIVE_HAUL % [
		HAUL_QUANTITY, String(item_id), String(destination.get(&"name", ""))
	]
	row[&"reward"] = reward(row)
	return row


## R-S25-1's seam: the Expedition row exists, draws greyed with the `STAGED` chip and
## refuses accept until S26's arenas flip it live (tick J1).
static func _expedition_row(origin_station: StringName, origin_sector: int, band: int) -> Dictionary:
	var row := _base_row(TYPE_EXPEDITION, origin_station, origin_sector, band, BOARD_SIZE - 1, origin_sector)
	row[&"faction"] = _sector_owner(origin_sector)
	row[&"staged"] = true
	row[&"standing"] = standing_for(TYPE_EXPEDITION)
	row[&"objective"] = OBJECTIVE_EXPEDITION
	row[&"reward"] = 0
	return row


static func _base_row(
	type: StringName, origin_station: StringName, origin_sector: int, band: int, index: int, target_sector: int
) -> Dictionary:
	return {
		&"id": StringName("c_%s_%d_%d" % [String(origin_station), band, index]),
		&"type": type,
		&"faction": &"",
		&"origin_station": origin_station,
		&"origin_sector": origin_sector,
		&"sector": target_sector,
		&"target_station": &"",
		&"item_id": &"",
		&"quantity": 0,
		&"count": 0,
		&"convoy": 0,
		&"tier": sector_tier(target_sector),
		&"band": band,
		&"reward": 0,
		&"standing": 0,
		&"objective": "",
		&"staged": false,
		&"escrow": {},
		&"accepted_at": 0,
	}


## The label one type draws in the TYPE cell (STATION_HUB section 15.2).
static func label_for(type: StringName) -> String:
	match type:
		TYPE_HAUL:
			return LABEL_HAUL
		TYPE_HUNT:
			return LABEL_HUNT
		TYPE_GATHER:
			return LABEL_GATHER
		TYPE_ESCORT:
			return LABEL_ESCORT
		TYPE_EXPEDITION:
			return LABEL_EXPEDITION
	return String(type).to_upper()


## 14 section 2's standing column for one type (the one home of the five figures). Hunt's
## cell reads "+1 standing per kill extra", so its whole contract files one per kill
## (`STANDING_HUNT` x the `HUNT_COUNT` kills the objective names) - the completion door is the
## one standing channel, so a hunt abandoned before its last kill files none of it.
## Reversal: the flat `STANDING_HUNT` (the reading B1 shipped untabled).
static func standing_for(type: StringName) -> int:
	match type:
		TYPE_HAUL:
			return STANDING_HAUL
		TYPE_HUNT:
			return STANDING_HUNT * HUNT_COUNT
		TYPE_GATHER:
			return STANDING_GATHER
		TYPE_ESCORT:
			return STANDING_ESCORT
		TYPE_EXPEDITION:
			return STANDING_EXPEDITION
	return 0


## The shipped icon one type draws (`icon_contract_<type>.svg`).
static func icon_for(type: StringName) -> String:
	return ICON_DIR + ICON_TEMPLATE % String(type)


static func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var held: Variant = values[index]
		values[index] = values[other]
		values[other] = held


## 11 section 1's owner of one sector number, `unaligned` for an id the registry does not
## spell (S7 carries a row with `unaligned`).
static func _sector_owner(sector_number: int) -> StringName:
	var row := SectorRegistryScript.sector(SectorRegistryScript.sector_id_for(sector_number))
	return StringName(row.get(&"owner", SectorRegistryScript.UNALIGNED))


## 11 section 1.1's tier of one sector number, read off the sector row's own mix.
static func sector_tier(sector_number: int) -> int:
	return SectorRegistryScript.sector_tier(SectorRegistryScript.sector_id_for(sector_number))


## The destination of a Haul or an Escort: a neighbouring sector that carries a station
## row (S7 has none), preferring an outpost when the neighbour has one (14 section 8 gives
## outposts contracts) - else the sector's primary. A docked sector with no station-bearing
## neighbour (S7, unreachable by docking) answers its own primary.
static func _destination_station(origin_sector: int, rng: RandomNumberGenerator) -> Dictionary:
	var neighbours: Array = SectorRegistryScript.sector(
		SectorRegistryScript.sector_id_for(origin_sector)
	).get(&"neighbours", [])
	var candidates: Array[Dictionary] = []
	for entry: Variant in neighbours:
		var number := int(entry)
		var outpost := station_for_sector(number, StationRegistryScript.KIND_OUTPOST)
		if not outpost.is_empty():
			candidates.append(outpost)
			continue
		var primary := StationRegistryScript.primary_for(
			SectorRegistryScript.sector_id_for(number)
		)
		if not primary.is_empty():
			candidates.append(primary)
	if candidates.is_empty():
		return StationRegistryScript.primary_for(
			SectorRegistryScript.sector_id_for(origin_sector)
		)
	return candidates[rng.randi_range(0, candidates.size() - 1)]


## One sector's station row of a kind, empty when the sector carries none (14's
## 2026-10-08 table).
static func station_for_sector(sector_number: int, kind: StringName) -> Dictionary:
	for row: Dictionary in StationRegistryScript.stations():
		if int(row.get(&"sector", 0)) != sector_number:
			continue
		if StringName(row.get(&"kind", &"")) == kind:
			return row
	return {}


## An ingot of a tier the sector's own mix carries (11 section 1.1), so a delivery is
## always a good the destination trades. The roll is `MineralCatalog`'s own (`roll_tier` +
## `roll_mineral`), so the board draws from the same stream the belt does.
static func _ingot_for(sector_number: int, rng: RandomNumberGenerator) -> StringName:
	var entry := MineralCatalogScript.roll_mineral(
		MineralCatalogScript.roll_tier(sector_number, rng), rng
	)
	if entry.is_empty():
		return &""
	return MineralCatalogScript.ingot_id(StringName(entry.get(&"id", &"")))


## A raw ore of a tier the sector's own mix carries (Gather's "ore (raw)").
static func _ore_for(sector_number: int, rng: RandomNumberGenerator) -> StringName:
	var entry := MineralCatalogScript.roll_mineral(
		MineralCatalogScript.roll_tier(sector_number, rng), rng
	)
	if entry.is_empty():
		return &""
	return MineralCatalogScript.ore_id(StringName(entry.get(&"id", &"")))


## ---------------------------------------------------------------------------
## The reward law (14 section 2 + the S28 block)
## ---------------------------------------------------------------------------


## 14's S28 block: every flat reward scales x SC(t)/SC(1) by the target sector's tier and
## is rounded to 100 CR. Hunt 800 / 1 100 / 2 200 / 4 400, Escort 1 200 / 1 600 / 3 300 /
## 6 500 and Haul's derived 300 / 400 / 800 / 1 600 all come out of this one line.
static func scaled_flat(base: int, tier: int) -> int:
	var index := clampi(tier, 1, SC.size()) - 1
	return round_to_100(roundi(float(base) * float(SC[index]) / float(SC[0])))


## 14's S28 block's "rounded to 100 CR", the one rounding of the reward law.
static func round_to_100(value: int) -> int:
	return roundi(float(value) / float(ROUND_UNIT)) * ROUND_UNIT


## 12 section 3's bias category of one item id. The doc names a category by tier band:
## T1-T2 ingots, T3-T4 ingots, T3 ore, components and exotic components. A tier outside the
## named bands (a T4 ore) reads its own unbiased key.
static func category_of(item_id: StringName) -> StringName:
	if item_id == &"":
		return &""
	if MineralCatalogScript.is_ore(item_id):
		var ore_tier := int(MineralCatalogScript.entry_for_item(item_id).get(&"tier", 0))
		if ore_tier <= 2:
			return BIAS_ORE_T12
		return BIAS_ORE_T3 if ore_tier == 3 else &"ore_t4"
	if MineralCatalogScript.is_ingot(item_id):
		var ingot_tier := int(MineralCatalogScript.entry_for_item(item_id).get(&"tier", 0))
		return BIAS_INGOT_T12 if ingot_tier <= 2 else BIAS_INGOT_T34
	if ExchangeScript.is_component(item_id):
		var grade := int(ComponentCatalogScript.component(item_id).get(&"grade", 0))
		return BIAS_EXOTIC_COMPONENT if grade >= 3 else BIAS_COMPONENT
	return &""


## 12 section 3's demand bias of one faction on one item's category, 0.0 for an item or a
## faction the table does not name. The Choir's row reads "T1-T2" unqualified, so it covers
## both the ore and the ingot form.
static func demand_bias(faction: StringName, item_id: StringName) -> float:
	var row: Dictionary = DEMAND_BIAS.get(faction, {})
	if row.is_empty():
		return 0.0
	var category := category_of(item_id)
	if row.has(category):
		return float(row[category])
	if (
		(category == BIAS_ORE_T12 or category == BIAS_INGOT_T12)
		and row.has(BIAS_T12)
	):
		return float(row[BIAS_T12])
	return 0.0


## The demand the board quotes one item at, at the faction's own bias: 12 section 3's
## "per-sector *initial* demand" reading, clamped to the exchange's own band.
static func demand_for(faction: StringName, item_id: StringName) -> float:
	var raw := ExchangeScript.DEMAND_DEFAULT + demand_bias(faction, item_id)
	return clampf(raw, ExchangeScript.DEMAND_MIN, ExchangeScript.DEMAND_MAX)


## The goods half of a contract's reward: `Exchange.sale_quote`'s transaction gross for the
## contract's own stack at the target faction's biased demand (05 section 5's one quote).
static func goods_gross(contract: Dictionary) -> int:
	var item_id := StringName(contract.get(&"item_id", &""))
	var quantity := int(contract.get(&"quantity", 0))
	if item_id == &"" or quantity <= 0:
		return 0
	var baseline := ExchangeScript.baseline_of(item_id)
	if baseline <= 0:
		return 0
	var quote: Dictionary = ExchangeScript.sale_quote(
		baseline, demand_for(StringName(contract.get(&"faction", &"")), item_id), quantity
	)
	return int(quote.get(&"gross", 0))


## 14 section 2's reward shape at the **target** sector's tier, rounded to 100 CR.
static func reward(contract: Dictionary) -> int:
	var tier := int(contract.get(&"tier", 1))
	match StringName(contract.get(&"type", &"")):
		TYPE_HAUL:
			return round_to_100(
				roundi(HAUL_SPOT * float(goods_gross(contract))) + scaled_flat(HAUL_FLAT, tier)
			)
		TYPE_GATHER:
			return round_to_100(roundi(GATHER_ORE * float(goods_gross(contract))))
		TYPE_HUNT:
			return scaled_flat(HUNT_FLAT, tier)
		TYPE_ESCORT:
			return scaled_flat(ESCORT_FLAT, tier)
	return 0


## What the board actually credits: 12 section 4.1's "+5 % at Known and above", applied to
## the board's own price. Reversal: the hook unapplied (`pay` == `reward`).
static func pay(contract: Dictionary, standing: int) -> int:
	var base := reward(contract)
	if standing >= KNOWN_FLOOR:
		return roundi(float(base) * (1.0 + KNOWN_HOOK))
	return base


## ---------------------------------------------------------------------------
## The active list, the gates and the escrow (14 section 2)
## ---------------------------------------------------------------------------


static func active(profile: Node) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if profile == null or not profile.has_method(&"contracts"):
		return out
	for entry: Variant in (profile.call(&"contracts") as Array):
		if entry is Dictionary:
			out.append(entry)
	return out


static func active_count(profile: Node) -> int:
	return active(profile).size()


static func find(profile: Node, contract_id: StringName) -> Dictionary:
	for row: Dictionary in active(profile):
		if StringName(row.get(&"id", &"")) == contract_id:
			return row
	return {}


## The standing gate of the board, the max-3 rule and the escrow, in one door. Every
## refusal is a dictionary and no refusal writes anything (17 section 5's transaction law).
static func accept(
	profile: Node, station_row: Dictionary, standing: int, contract: Dictionary
) -> Dictionary:
	if profile == null or contract.is_empty():
		return {&"ok": false, &"reason": REASON_UNKNOWN, &"contract": {}}
	if bool(contract.get(&"staged", false)):
		return {&"ok": false, &"reason": REASON_STAGED, &"contract": contract}
	if station_row.is_empty() or not visible(standing):
		return {&"ok": false, &"reason": REASON_GATED, &"contract": contract}
	if active_count(profile) >= MAX_ACTIVE:
		return {&"ok": false, &"reason": REASON_FULL, &"contract": contract}
	var record: Dictionary = contract.duplicate(true)
	record[&"accepted_at"] = Clock.now()
	var escrow := _reserve(profile, record)
	if not bool(escrow.get(&"ok", false)):
		return {&"ok": false, &"reason": escrow.get(&"reason", REASON_UNKNOWN), &"contract": contract}
	record[&"escrow"] = escrow.get(&"escrow", {})
	var rows := active(profile)
	rows.append(record)
	profile.call(&"set_contracts", rows)
	Log.append(
		EVENT_ACCEPT,
		StringName(record.get(&"id", &"")),
		active_count(profile),
		0,
		int(profile.call(&"credits"))
	)
	return {&"ok": true, &"reason": &"", &"contract": record}


## The goods a contract locks at accept: quantity reserved from the manifest. Hunt and
## Escort carry no goods, so their escrow is empty and they always reserve.
static func _reserve(profile: Node, record: Dictionary) -> Dictionary:
	var item_id := StringName(record.get(&"item_id", &""))
	var quantity := int(record.get(&"quantity", 0))
	if StringName(record.get(&"type", &"")) == TYPE_ESCORT:
		return {&"ok": true, &"reason": &"", &"escrow": {}}
	if item_id == &"" or quantity <= 0:
		return {&"ok": true, &"reason": &"", &"escrow": {}}
	if int(profile.call(&"cargo_qty", item_id)) < quantity:
		return {&"ok": false, &"reason": REASON_INSUFFICIENT_CARGO, &"escrow": {}}
	profile.call(&"remove_cargo", item_id, quantity)
	return {&"ok": true, &"reason": &"", &"escrow": {String(item_id): quantity}}


## 14 section 2: cancelling returns the reserved goods "for a 100 CR fee". The fee is
## charged first and the goods unlock only when it lands, so no path unlocks for free.
## Reversal: the fee is charged as a debt (credits floor at 0).
static func cancel(profile: Node, contract_id: StringName) -> Dictionary:
	var record := find(profile, contract_id)
	if record.is_empty():
		return {&"ok": false, &"reason": REASON_UNKNOWN, &"fee": 0, &"returned": {}}
	if not bool(profile.call(&"spend", CANCEL_FEE)):
		return {&"ok": false, &"reason": REASON_INSUFFICIENT_CREDITS, &"fee": 0, &"returned": {}}
	var returned := _release(profile, record)
	_remove(profile, contract_id)
	Log.append(
		EVENT_CANCEL,
		contract_id,
		active_count(profile),
		-CANCEL_FEE,
		int(profile.call(&"credits"))
	)
	return {&"ok": true, &"reason": &"", &"fee": CANCEL_FEE, &"returned": returned}


## The escrow's own goods back into the manifest, exactly once (the record leaves the
## active list in the same call).
static func _release(profile: Node, record: Dictionary) -> Dictionary:
	var escrow: Dictionary = record.get(&"escrow", {})
	var returned := {}
	for key: Variant in escrow:
		var item_id := StringName(key)
		var quantity := int(escrow[key])
		if item_id == &"" or quantity <= 0:
			continue
		profile.call(&"add_cargo", item_id, quantity)
		returned[String(item_id)] = quantity
	return returned


static func _remove(profile: Node, contract_id: StringName) -> void:
	var rows: Array[Dictionary] = []
	for row: Dictionary in active(profile):
		if StringName(row.get(&"id", &"")) == contract_id:
			continue
		rows.append(row)
	profile.call(&"set_contracts", rows)


## The completion door: it takes the record out of the active list **before** it pays, so a
## second call on the same id pays nothing (the double-completion probe). The escrow's goods
## are consumed, never returned: they were delivered.
static func complete(profile: Node, contract_id: StringName) -> Dictionary:
	var record := find(profile, contract_id)
	if record.is_empty():
		return {&"ok": false, &"reason": REASON_NOT_ACTIVE, &"paid": 0, &"standing": 0}
	_remove(profile, contract_id)
	var faction := StringName(record.get(&"faction", &""))
	var standing := standing_of(profile, faction)
	var paid := pay(record, standing)
	if paid > 0:
		profile.call(&"add_credits", paid)
	var delta := int(record.get(&"standing", 0))
	file_standing(profile, faction, delta)
	Log.append(
		EVENT_COMPLETE,
		contract_id,
		active_count(profile),
		paid,
		int(profile.call(&"credits"))
	)
	return {&"ok": true, &"reason": &"", &"paid": paid, &"standing": delta}


## 14 section 2's delivery site of one contract: Haul's is its own destination ("40x
## ingot_titanium to S4 outpost"), Gather's is the station it was taken at ("20x
## mineral_cobalt ore (raw)" names no other place). Hunt and Escort answer nothing here -
## their own channels close them (the kill credit and the convoy's arrival at the gate).
static func delivery_station(contract: Dictionary) -> StringName:
	match StringName(contract.get(&"type", &"")):
		TYPE_HAUL:
			return StringName(contract.get(&"target_station", &""))
		TYPE_GATHER:
			return StringName(contract.get(&"origin_station", &""))
	return &""


## The delivery sweep one dock runs: every active contract whose own station this is closes
## through the one completion door, in board order, and a contract for another station is left
## alone. One result per delivered contract, so the caller can read the pay. A second sweep at
## the same station finds nothing (the records have left the list), so the goods are consumed
## exactly once and the purse moves exactly once.
static func deliver_at(profile: Node, station_id: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if profile == null or station_id == &"":
		return out
	for record: Dictionary in active(profile):
		if delivery_station(record) != station_id:
			continue
		out.append(complete(profile, StringName(record.get(&"id", &""))))
	return out


## 14 section 2's Hunt row: "Destroy 5 pirates in S2". One credited kill per pirate killed in
## the contract's own sector, taken off the record's own `count` (the row's requirement, read
## here as the pirates still to destroy); the kill that empties it closes the contract through
## the one completion door, so the payout lands once and the record leaves the list once. A
## hunt for another sector is left alone, and what counts as a pirate is the caller's reading
## of the victim (`game.gd:_on_npc_died`).
static func credit_kill(profile: Node, sector_number: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if profile == null:
		return out
	for record: Dictionary in active(profile):
		if StringName(record.get(&"type", &"")) != TYPE_HUNT:
			continue
		if int(record.get(&"sector", 0)) != sector_number:
			continue
		var id := StringName(record.get(&"id", &""))
		var left := int(record.get(&"count", 0)) - 1
		if left > 0:
			var rows := active(profile)
			for index in rows.size():
				if StringName(rows[index].get(&"id", &"")) == id:
					rows[index][&"count"] = left
					break
			profile.call(&"set_contracts", rows)
			out.append({&"ok": true, &"reason": &"", &"paid": 0, &"standing": 0, &"left": left})
			continue
		var done := complete(profile, id)
		done[&"left"] = 0
		out.append(done)
	return out


## 12 section 4: "complete a faction contract" moves the **contract's** faction's standing
## (not the sector owner's), so one function files every contract standing change.
static func file_standing(profile: Node, faction: StringName, delta: int) -> void:
	if profile == null or faction == &"" or delta == 0:
		return
	if not profile.has_method(&"standing") or not profile.has_method(&"set_standing"):
		return
	var table: Dictionary = profile.call(&"standing")
	var key := String(faction)
	table[key] = int(table.get(key, 0)) + delta
	profile.call(&"set_standing", table)


static func standing_of(profile: Node, faction: StringName) -> int:
	if profile == null or faction == &"" or not profile.has_method(&"standing_of"):
		return 0
	return int(profile.call(&"standing_of", faction))


## ---------------------------------------------------------------------------
## The escort loop (14 section 6)
## ---------------------------------------------------------------------------


## The convoy's own hauler hull (13 section 5's convoy row, 08 section 2's Hauler class).
static func escort_hauler() -> StringName:
	return NpcRegistryScript.CONVOY_HAULER


## The hauler's own class row: 14 section 6's "convoy hulls use the Hauler stats (08 section
## 2)". The hold is read off the resolved fit, never typed.
static func escort_hold() -> int:
	var stats := ShipFitScript.resolve(
		NpcRegistryScript.CONVOY_HAULER, ShipFitScript.STANDARD_FIT
	)
	return int(stats.cargo_max)


## 14 section 6's "50 % of hold filled with visible cargo pods".
static func escort_pods() -> int:
	return roundi(ESCORT_POD_FRACTION * float(escort_hold()))


## The convoy one escort contract spawns: 1 hauler + 1-2 fighters, the hauler's own hull,
## its hold's half as pods and the route's three legs. `fighters` is drawn from the
## contract's own seeded stream so a probe re-derives it.
static func escort_plan(contract: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|convoy" % String(contract.get(&"id", &"")))
	return {
		&"hauler": NpcRegistryScript.CONVOY_HAULER,
		&"fighter": NpcRegistryScript.CONVOY_ESCORT,
		&"fighters": rng.randi_range(ESCORT_FIGHTERS.x, ESCORT_FIGHTERS.y),
		&"pods": escort_pods(),
		&"pod_marks": ESCORT_POD_MARKS,
		&"legs": ESCORT_LEGS.duplicate(),
		&"ambush_leg": ESCORT_AMBUSH_LEG,
	}


## The speed the convoy flies at: the hauler's own class maximum ("at freighter speed",
## 14 section 6), read off the resolved stats.
static func escort_speed() -> float:
	var stats := ShipFitScript.resolve(
		NpcRegistryScript.CONVOY_HAULER, ShipFitScript.STANDARD_FIT
	)
	return float(stats.max_speed)


## 14 section 6's win row: "convoy hull survives to the gate -> payout at destination
## station". The payout is the escort's own reward plus its +5 standing, filed by the one
## completion door. The destination station is the record's `target_station`.
static func escort_won(profile: Node, contract_id: StringName) -> Dictionary:
	return complete(profile, contract_id)


## 14 section 6's loss row: "convoy destroyed -> no payout, -5 standing, and the pirates who
## did it keep the loot". The record leaves the active list, so a dead escort cannot
## resurrect; the loot the pirates keep is the convoy's own cargo, handed back to the caller
## to drop at the wreck.
static func escort_lost(profile: Node, contract_id: StringName) -> Dictionary:
	var record := find(profile, contract_id)
	if record.is_empty():
		return {&"ok": false, &"reason": REASON_NOT_ACTIVE, &"paid": 0, &"loot": {}}
	_remove(profile, contract_id)
	var faction := StringName(record.get(&"faction", &""))
	file_standing(profile, faction, STANDING_LOSS)
	var loot := {}
	var item_id := StringName(record.get(&"item_id", &""))
	var quantity := int(record.get(&"quantity", 0))
	if item_id != &"" and quantity > 0:
		loot[String(item_id)] = quantity
	Log.append(
		EVENT_FAILED, contract_id, active_count(profile), 0, int(profile.call(&"credits"))
	)
	return {&"ok": true, &"reason": &"", &"paid": 0, &"standing": STANDING_LOSS, &"loot": loot}
