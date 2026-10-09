class_name StationRegistry
extends RefCounted
## Read-only station registry: 14_station_services.md's nine docking places as rows (the
## shape `game/sector_registry.gd` uses), each carrying its section 1/8 service matrix and
## the 12_factions.md price law. Data, not logic: no nodes, no autoload, no mutation API.
##
## Contract: docs/gameplay/14_station_services.md section 1/8 + its 2026-09-27 P3 block
## (R-S24-1, the nine names, tick W3) + its 2026-10-08 block (the rows, the docked-station
## seam, the plate landing) + its 2026-10-08 S38 block (H1: the cold-start place, read
## only); docs/gameplay/12_factions.md section 4.1/5 + its 2026-10-08
## block (V1 the band multiplier, V2 the additive stack, V6 the shelf bias). Contract:
## docs/CONTRACTS.md section 24.
##
## **The cold start (H1).** An empty filed id means "no run has filed a place" and nothing
## else: `docked_station`/`docked_station_id` answer `starting_station()` =
## `primary_for(SectorRegistry.DEFAULT_SECTOR_ID)`. A sector with no station files its own
## sector id at the dock (`game.gd:_file_docked_station`), so S7 keeps the no-place
## fallback; a null profile, an unparseable id and a station-less starting sector are
## unchanged.
##
## **Row keys.** `id`, `name`, `character` (the W3 pair verbatim, lowercase as the doc
## writes it), `sector` (1-7), `kind` (`primary`/`outpost`), `faction` (the four owner ids
## `SectorRegistry` already spells) and `services`. S7 carries no row: 11 section 1 gives
## it no station ("no law, no patrol").
##
## **The service matrix** transcribes section 1's table as booleans per service id, plus
## `vault_tiers` (section 8 caps an outpost's rentable tier at 1; section 4's range is
## tiers 1-3, so a primary carries all three). `refuel`/`recharge` are true at every row
## because section 1's own row reads "every station; free and instant, no CR charged"
## (the owner rulings of 2026-09-20/21), and section 8's three do not revoke it.
##
## **The price law (V1/V2/V6).** `price_factor` is the one owner: the catalogue's own list
## number goes in, `1 + band_delta - tech_discount` comes out, and `apply_price` is the
## reader every price site calls. The order is fixed - the catalogue list, then the band
## and the tech step, then (at the auction alone) the hot row's -20 % last, which
## `ModuleCatalog.hot_price` keeps as its own never-stacked discount. The **exchange**
## takes no band multiplier (V1: it is a market, not a shop); its commission reads
## `commission_rate` below, the only station-aware number in `game/exchange.gd`.
##
## Owner ids: `concord`, `meridian`, `choir` - `SectorRegistry`'s own spelling, so the
## station's faction and the sector's owner are one currency.

const ModuleCatalogScript := preload("res://game/module_catalog.gd")

## 12 section 5's per-faction technology families (`15 section 2`'s slot families). The
## three weapon families are named at family granularity because that is how section 5
## names them (`w_plasma`, `w_proton`); every other entry is a catalogue slot key in
## `family_of`'s spelling. Reversal: one row edit per family.
const TECH_FAMILIES: Dictionary = {
	&"concord": [&"armour", &"engines"],
	&"meridian": [&"computers", &"boosters", &"storage"],
	&"choir": [&"shields", &"plasma", &"proton"],
}

## The catalogue's slot spelling -> the family word 12 section 5 uses. `ModuleCatalog`
## writes an engine's slot as `engine` (`ShipFit`'s eight keys say `engines`) and the
## storage line's as `utility`; section 5 names the first "engines" and the second
## "storage". Reversal: one row edit.
const FAMILY_ALIASES: Dictionary = {&"engine": &"engines", &"utility": &"storage"}

const SLOT_WEAPONS: StringName = &"weapons"
const WEAPON_PREFIX := "w_"

## 12 section 5's faction discount, and V2's arithmetic: added to the band delta, never
## multiplied, so a Champion of the Choir on a Choir family reads 0.75 x list.
const TECH_DISCOUNT := 0.15

## 12 section 4.1's band deltas (V1): Shunned +10 %, Neutral/Known 0, Trusted -5 %,
## Champion -10 %. Outlaw is unreachable at a station (the dock refusal), so the Shunned
## ceiling is the only lower floor the multiplier needs.
const BAND_SHUNNED := 0.10
const BAND_TRUSTED := -0.05
const BAND_CHAMPION := -0.10
const SHUNNED_CEILING := -11
const TRUSTED_FLOOR := 41
const CHAMPION_FLOOR := 71

## V3: `contracts_visible` - Shunned and Outlaw see no contracts (12 section 4.1).
const CONTRACTS_FLOOR := -11

## V7: the insurance seam - 0.8 at Champion, 1.0 elsewhere (12 section 4.1).
const INSURANCE_CHAMPION := 0.8
const INSURANCE_DEFAULT := 1.0

## V6: the shelf-bias hook - the owner's own tech families weigh twice in the rolled
## module draw, everything else once.
const SHELF_BIAS_OWN := 2.0
const SHELF_BIAS_OTHER := 1.0

const KIND_PRIMARY: StringName = &"primary"
const KIND_OUTPOST: StringName = &"outpost"

## The seven service ids the matrix keys on: section 1's six rows (its refuel/recharge row
## is two services, exactly as `StationCatalog.SERVICES` spells them) plus the arena.
const SERVICE_CONTRACTS: StringName = &"contracts"
const SERVICE_REFUEL: StringName = &"refuel"
const SERVICE_RECHARGE: StringName = &"recharge"
const SERVICE_INSURANCE: StringName = &"insurance"
const SERVICE_VAULTS: StringName = &"vaults"
const SERVICE_ARENA: StringName = &"arena"
const SERVICE_BOUNTY: StringName = &"bounty"

## The two U2 reason captions (STATION_HUB section 15.6, 14 verbatim): the Choir sells no
## insurance and an outpost sends you to a capital. Nothing else is invented; a service a
## row simply does not carry answers with an empty caption.
const REASON_NO_INSURANCE := "the Choir does not believe in accidents"
const REASON_FLY_TO_CAPITAL := "fly to a capital"

## The nine places, in 14's 2026-10-08 table order.
const STATIONS: Array[Dictionary] = [
	{
		&"id": &"s1_primary",
		&"name": "Halcyon Anchorage",
		&"character": "forge-grey bastion, the full menu",
		&"sector": 1,
		&"kind": KIND_PRIMARY,
		&"faction": &"concord",
		&"services": {
			SERVICE_CONTRACTS: true,
			SERVICE_REFUEL: true,
			SERVICE_RECHARGE: true,
			SERVICE_INSURANCE: true,
			SERVICE_VAULTS: true,
			SERVICE_ARENA: false,
			SERVICE_BOUNTY: true,
		},
		&"vault_tiers": 3,
	},
	{
		&"id": &"s2_primary",
		&"name": "Ironworks Depot",
		&"character": "mill-town market floor",
		&"sector": 2,
		&"kind": KIND_PRIMARY,
		&"faction": &"concord",
		&"services": {
			SERVICE_CONTRACTS: true,
			SERVICE_REFUEL: true,
			SERVICE_RECHARGE: true,
			SERVICE_INSURANCE: true,
			SERVICE_VAULTS: true,
			SERVICE_ARENA: false,
			SERVICE_BOUNTY: true,
		},
		&"vault_tiers": 3,
	},
	{
		&"id": &"s2_outpost",
		&"name": "Marchgate Post",
		&"character": "a dock and a vending wall",
		&"sector": 2,
		&"kind": KIND_OUTPOST,
		&"faction": &"concord",
		&"services": {
			SERVICE_CONTRACTS: true,
			SERVICE_REFUEL: true,
			SERVICE_RECHARGE: true,
			SERVICE_INSURANCE: false,
			SERVICE_VAULTS: true,
			SERVICE_ARENA: false,
			SERVICE_BOUNTY: true,
		},
		&"vault_tiers": 1,
	},
	{
		&"id": &"s3_primary",
		&"name": "Spanport Meridian",
		&"character": "the merchant's harbour, best contract rates",
		&"sector": 3,
		&"kind": KIND_PRIMARY,
		&"faction": &"meridian",
		&"services": {
			SERVICE_CONTRACTS: true,
			SERVICE_REFUEL: true,
			SERVICE_RECHARGE: true,
			SERVICE_INSURANCE: true,
			SERVICE_VAULTS: true,
			SERVICE_ARENA: true,
			SERVICE_BOUNTY: true,
		},
		&"vault_tiers": 3,
	},
	{
		&"id": &"s4_primary",
		&"name": "Ashveil Exchange",
		&"character": "free-port chaos, component prices",
		&"sector": 4,
		&"kind": KIND_PRIMARY,
		&"faction": &"meridian",
		&"services": {
			SERVICE_CONTRACTS: true,
			SERVICE_REFUEL: true,
			SERVICE_RECHARGE: true,
			SERVICE_INSURANCE: true,
			SERVICE_VAULTS: true,
			SERVICE_ARENA: true,
			SERVICE_BOUNTY: true,
		},
		&"vault_tiers": 3,
	},
	{
		&"id": &"s4_outpost",
		&"name": "Rimward Depot",
		&"character": "caravan stop",
		&"sector": 4,
		&"kind": KIND_OUTPOST,
		&"faction": &"meridian",
		&"services": {
			SERVICE_CONTRACTS: true,
			SERVICE_REFUEL: true,
			SERVICE_RECHARGE: true,
			SERVICE_INSURANCE: false,
			SERVICE_VAULTS: true,
			SERVICE_ARENA: false,
			SERVICE_BOUNTY: true,
		},
		&"vault_tiers": 1,
	},
	{
		&"id": &"s5_primary",
		&"name": "Cinder Gate",
		&"character": "incense and plasma scorch",
		&"sector": 5,
		&"kind": KIND_PRIMARY,
		&"faction": &"choir",
		&"services": {
			SERVICE_CONTRACTS: true,
			SERVICE_REFUEL: true,
			SERVICE_RECHARGE: true,
			SERVICE_INSURANCE: false,
			SERVICE_VAULTS: true,
			SERVICE_ARENA: true,
			SERVICE_BOUNTY: true,
		},
		&"vault_tiers": 3,
	},
	{
		&"id": &"s5_shrine",
		&"name": "The First Ember",
		&"character": "the Choir's smallest rite",
		&"sector": 5,
		&"kind": KIND_OUTPOST,
		&"faction": &"choir",
		&"services": {
			SERVICE_CONTRACTS: true,
			SERVICE_REFUEL: true,
			SERVICE_RECHARGE: true,
			SERVICE_INSURANCE: false,
			SERVICE_VAULTS: true,
			SERVICE_ARENA: false,
			SERVICE_BOUNTY: true,
		},
		&"vault_tiers": 1,
	},
	{
		&"id": &"s6_primary",
		&"name": "Emberlight",
		&"character": "cathedral dark, meanest turrets",
		&"sector": 6,
		&"kind": KIND_PRIMARY,
		&"faction": &"choir",
		&"services": {
			SERVICE_CONTRACTS: true,
			SERVICE_REFUEL: true,
			SERVICE_RECHARGE: true,
			SERVICE_INSURANCE: false,
			SERVICE_VAULTS: true,
			SERVICE_ARENA: true,
			SERVICE_BOUNTY: true,
		},
		&"vault_tiers": 3,
	},
]


## One station row by id, or an empty dictionary for an unknown id.
static func station(station_id: StringName) -> Dictionary:
	for row: Dictionary in STATIONS:
		if StringName(row.get(&"id", &"")) == station_id:
			return row
	return {}


## Every row, in 14's table order (the shape `SectorRegistry.SECTORS` exposes).
static func stations() -> Array[Dictionary]:
	return STATIONS.duplicate(true)


## The cold-start place (14's 2026-10-08 S38 block, H1): the starting sector's primary row,
## `{}` when that sector has no primary (a station-less sector answers no place, the
## readers' existing fallback). Read-only: no screen writes the profile for it.
static func starting_station() -> Dictionary:
	return primary_for(SectorRegistry.DEFAULT_SECTOR_ID)


## The row id the profile is docked at, or `&""` when it is not docked and when the
## profile predates the seam. An **empty** filed id is the cold start - no run has filed a
## place - and answers the starting row's id (H1); a null profile and a station-less
## starting sector still answer `&""`.
static func docked_station_id(profile: Node) -> StringName:
	if profile == null or not profile.has_method(&"docked_station"):
		return &""
	var filed := StringName(profile.call(&"docked_station"))
	if filed == &"":
		return StringName(starting_station().get(&"id", &""))
	return filed


## The place the account is docked at: the profile's own row when the seam names one, the
## **starting** row for an empty filed id (H1's cold start), else the **sector's primary**
## row (an id this wave does not ship still resolves to its sector's capital), else an
## empty dictionary. A null profile, an unparseable id and a station-less sector are normal
## paths, never errors - the shell keeps the scene's placeholder strings for an empty row.
static func docked_station(profile: Node) -> Dictionary:
	var id := docked_station_id(profile)
	if id == &"":
		return {}
	var row := station(id)
	if not row.is_empty():
		return row
	return primary_for(sector_id_for(_sector_number(id)))


## The sector's primary row (the only kind that spawns a station node today, 14's
## 2026-10-08 block), or an empty dictionary for a sector with no station (S7) and for an
## id the sector registry does not spell.
static func primary_for(sector_id: StringName) -> Dictionary:
	var number := _sector_number(sector_id)
	if number <= 0:
		return {}
	for row: Dictionary in STATIONS:
		if int(row.get(&"sector", 0)) != number:
			continue
		if StringName(row.get(&"kind", &"")) == KIND_PRIMARY:
			return row
	return {}


## The id one sector number names (`3` -> `&"sector_3"`), `SectorRegistry`'s own spelling.
static func sector_id_for(number: int) -> StringName:
	return StringName("sector_%d" % number)


## True when the row's matrix carries the service.
static func offers(station_row: Dictionary, service: StringName) -> bool:
	var matrix: Variant = station_row.get(&"services", {})
	if not matrix is Dictionary:
		return false
	return bool((matrix as Dictionary).get(service, false))


## The U2 reason caption for a service the row does not carry, `""` when it carries it or
## when 14 states no reason. Only the two verbatim captions of STATION_HUB section 15.6
## ship: an outpost's missing service sends you to a capital (section 8) and the Choir's
## missing insurance is section 1's own line.
static func service_reason(station_row: Dictionary, service: StringName) -> String:
	if station_row.is_empty() or offers(station_row, service):
		return ""
	if StringName(station_row.get(&"kind", &"")) == KIND_OUTPOST:
		return REASON_FLY_TO_CAPITAL
	if (
		service == SERVICE_INSURANCE
		and StringName(station_row.get(&"faction", &"")) == &"choir"
	):
		return REASON_NO_INSURANCE
	return ""


## The catalogue slot or weapon family one base id belongs to (`&"w_proton"` -> `&"proton"`,
## `&"h_composite"` -> `&"armour"`, `&"u_vault"` -> `&"storage"`), `&""` for an id the
## catalogue does not ship.
static func family_of(base_id: StringName) -> StringName:
	var slot := ModuleCatalogScript.slot_of(base_id)
	if slot == &"":
		return &""
	if slot == SLOT_WEAPONS:
		var text := String(base_id)
		if not text.begins_with(WEAPON_PREFIX):
			return SLOT_WEAPONS
		return StringName(text.substr(WEAPON_PREFIX.length()))
	return StringName(FAMILY_ALIASES.get(slot, slot))


## 12 section 5's own families for one owner id, empty for an id outside the three.
static func tech_families(faction: StringName) -> Array:
	var families: Variant = TECH_FAMILIES.get(faction, [])
	return families if families is Array else []


## True when the station's owner counts the id's family as its own technology - the one
## predicate the discount (V2) and the shelf bias (V6) both read.
static func owns_family(station_row: Dictionary, base_id: StringName) -> bool:
	var family := family_of(base_id)
	if family == &"":
		return false
	var faction := StringName(station_row.get(&"faction", &""))
	return tech_families(faction).has(family)


## 12 section 4.1's band delta for one standing: +0.10 Shunned, 0 Neutral and Known,
## -0.05 Trusted, -0.10 Champion.
static func band_delta(standing: int) -> float:
	if standing >= CHAMPION_FLOOR:
		return BAND_CHAMPION
	if standing >= TRUSTED_FLOOR:
		return BAND_TRUSTED
	if standing <= SHUNNED_CEILING:
		return BAND_SHUNNED
	return 0.0


## V1+V2: the one price multiplier of the wave - `1 + band_delta - tech_discount`. The
## band reads `standing`; the tech step reads the station's own families and applies to
## modules alone (an empty `base_id` is a hull, a pack or a service, so it takes the band
## only). An empty station row is "not at a station": the factor is 1.0, never a band.
static func price_factor(
	station_row: Dictionary, standing: int, base_id: StringName = &""
) -> float:
	if station_row.is_empty():
		return 1.0
	var discount := TECH_DISCOUNT if owns_family(station_row, base_id) else 0.0
	return 1.0 + band_delta(standing) - discount


## The one reader every price site calls: the catalogue's own list number in, the station's
## price out. A non-positive input is returned unchanged (the catalogues' "no price"
## answer, which no factor may turn into a price).
static func apply_price(
	price: int, station_row: Dictionary, standing: int, base_id: StringName = &""
) -> int:
	if price <= 0:
		return price
	return roundi(float(price) * price_factor(station_row, standing, base_id))


## V3: the contracts gate - Shunned and Outlaw see no contracts, Neutral and above do.
## S25 owns the board that reads it.
static func contracts_visible(standing: int) -> bool:
	return standing > CONTRACTS_FLOOR


## V7: the insurance seam - 0.8 at Champion, 1.0 elsewhere. 14 section 3's premium table
## and its consumer are S26's; S24 ships the readable value.
static func insurance_multiplier(standing: int) -> float:
	if standing >= CHAMPION_FLOOR:
		return INSURANCE_CHAMPION
	return INSURANCE_DEFAULT


## V6: the shelf-bias hook - 2.0 for the owner's own tech families, 1.0 otherwise.
static func shelf_bias(station_row: Dictionary, base_id: StringName) -> float:
	return SHELF_BIAS_OWN if owns_family(station_row, base_id) else SHELF_BIAS_OTHER


## The sector number an id names: the station ids' own `s3_primary` spelling and the sector
## registry's `sector_3` both resolve, `0` for anything else. The rule is
## `SectorRegistry.sector_number`'s; it is spelled here so this registry loads without a
## sector-registry reference.
static func _sector_number(id: StringName) -> int:
	var text := String(id)
	if text.begins_with("sector_"):
		text = text.substr("sector_".length())
	elif text.begins_with("s"):
		text = text.substr(1)
	var digits := ""
	for index in text.length():
		if not text[index].is_valid_int():
			break
		digits += text[index]
	return int(digits) if digits.is_valid_int() else 0
