class_name Auction
extends RefCounted
## The auction house: the rotating shelf, its restock clock, its prices and its
## sell side.
##
## Contract: docs/gameplay/10_ship_acquisition.md sections 2, 2.2, 2.3 and 2.4,
## docs/gameplay/15_module_affixes.md sections 1, 2, 5, 6, 7, 8 and 9,
## docs/design/STATION_HUB.md section 5.10 and docs/CONTRACTS.md section 15.
## Panel: `ui/station/auction_panel.gd`.
##
## The shelf is 10 section 2.1's: **6 hulls + 10 modules** at a time, restocked on
## the shared 20-minute station clock, one "hot slot" per restock at -20 %. The
## state lives in the profile's top-level `auction` key -- never a `market`
## sub-key, because `PlayerProfile._normalise_market` rebuilds that dictionary
## from `MARKET_KEYS` and would drop the shelf on load (CONTRACTS section 15).
##
## Module listings are **rolled instances**, not catalogue rows (15 section 8:
## "auction modules when the shelf is drawn at restock"), so the name and the
## price a row shows are the roll's own: that is what "hunting the good roll"
## means. The roll goes through `PlayerProfile.roll_listing`, which mints the
## next `mod_%04d` from the one per-profile counter and leaves the record on the
## shelf until it is bought; a restock discards the unbought listings and never
## rewinds the counter.
##
## The restock is **lazy**, exactly like the exchange's market (05 section 2,
## `game/exchange.gd:evaluate_market`): `evaluate_shelf` is called at pane entry
## and before a restock read, measures `WorldClock.bands_between(last, now)` and
## draws one shelf per elapsed band. There is no Timer anywhere -- 05 section 8's
## rule, restated for the same clock. `next_restock_seconds` is a **reading**,
## not a countdown: the clock has no remaining-time accessor and its own header
## forbids a per-consumer Timer (STATION_HUB section 5.10's S3 amendment).
##
## One pricing function family, the exchange's own rule (05 section 8): UI code
## reads `listing_rows` / `hull_rows` / `sell_rows` and never recomputes a price
## from a 09 cost and a rarity.
##
## Reads and writes are split the way `game/exchange.gd` splits them: the
## `evaluate_shelf` / `buy_*` / `sell_row` entry points may write, through
## `PlayerProfile.set_auction` / `buy_instance` / `sell_instance` / `buy_ship`
## only; every `*_rows` reader is pure. Credits are ints everywhere and every
## transaction is priced through `ModuleCatalog` (09 section 3's list x 15 section
## 1's rarity multiplier, 10 section 2.1's hot slot after, 15 section 6's 60 %).

## Preloaded by path on purpose: this file must not depend on the global class
## table, so a headless caller and the editor agree (the exchange's own reason).
const ModuleData := preload("res://game/module_catalog.gd")
const Catalog := preload("res://game/station_catalog.gd")
const FitData := preload("res://game/ship_fit.gd")
const Clock := preload("res://autoload/world_clock.gd")

## 10 section 2.1's shelf: six hulls and ten modules at a time.
const HULL_SLOTS := 6
const MODULE_SLOTS := 10

## 10 section 2.2's availability weights, keyed by 08 section 2's asset ids and
## read against `StationCatalog.SHIPS`' own order (the 2026-09-22 correction:
## "the shelf keys off 08 section 2's asset ids ... the class name is the shelf's
## display column only"). `1.0` is the two starter hulls' "always listed".
const HULL_CHANCE: Dictionary = {
	&"ship_fighter": 1.0,
	&"ship_vanguard": 1.0,
	&"ship_miner": 0.60,
	&"ship_trader": 0.60,
	&"ship_freighter": 0.60,
	&"ship_corvette": 0.45,
	&"ship_gunship": 0.45,
	&"ship_patrol": 0.30,
	&"ship_destroyer": 0.20,
}

## 10 section 2.1's module tier weights: "10 modules drawn from the 09 catalogue
## with tier weights I 50 % / II 35 % / III 15 %".
const TIER_WEIGHTS: Dictionary = {1: 50, 2: 35, 3: 15}
const TIER_ORDER: Array[int] = [1, 2, 3]

## 15 section 8's interim: every shelf carries one tagged `F LOT` exclusive while
## faction stations (12 section 5) do not exist. The flag is the whole lot's
## switch; its rarity split is 15 section 9.2's `faction_lot` row in
## `ModuleCatalog.SOURCE_ROLLS` (85 % Magic / 15 % Rare), and 15 section 5's
## Magic floor is clamped by `ModuleCatalog.roll_rarity` itself.
const AUCTION_FACTION_LOTS_INTERIM := true

## 10 section 2.1 / 15 section 1: the one hot slot's -20 %, applied after the
## rarity step and never stacked with anything.
const HOT_DISCOUNT_PERCENT := 20

## 15 section 4 / CONTRACTS section 20: 15 section 4's `of the Ledger` sells for 25 %
## more. The suffix id is the catalogue's own row key and the multiplier is a whole
## percent so the arithmetic stays integer-exact (every 09/15 cost is a multiple of
## 100 and the three rarity products are 60 / 96 / 156, all divisible by 4).
const SUFFIX_LEDGER: StringName = &"ledger"
const LEDGER_PERCENT := 125

## The two hulls 10 section 2.2 marks "always listed (the two starter hulls never leave
## the shelf)": the reconciliation's absolute floor.
const STARTER_HULLS: Array[StringName] = [&"ship_fighter", &"ship_vanguard"]

## 10 section 2.2's listing order: `StationCatalog.SHIPS`' own order, which the
## 2026-09-22 correction pins as the ladder's order.
const HULL_ORDER: Array[StringName] = [
	&"ship_fighter",
	&"ship_vanguard",
	&"ship_miner",
	&"ship_trader",
	&"ship_corvette",
	&"ship_freighter",
	&"ship_gunship",
	&"ship_patrol",
	&"ship_destroyer",
]

## CONTRACTS sections 12/13: the three shipped refusal reasons, unchanged.
const REASON_INSUFFICIENT: StringName = &"insufficient_credits"
const REASON_ALREADY_OWNED: StringName = &"already_owned"
const REASON_UNKNOWN: StringName = &"unknown_id"

## STATION_HUB section 5.10's rarity words and tints: Common is the theme's
## default label colour, Magic Steel Highlight, Rare Ember Glow. The token names
## are the theme's; the hexes below are only the fallback for a theme that lost
## them (the pin's own "fallback to the hexes above when a token is missing").
const RARITY_WORDS: Dictionary = {&"common": "COMMON", &"magic": "MAGIC", &"rare": "RARE"}
const RARITY_TOKENS: Dictionary = {
	&"common": &"rarity_common",
	&"magic": &"rarity_magic",
	&"rare": &"rarity_rare",
}
const RARITY_FALLBACK: Dictionary = {
	&"common": Color(0.7882353, 0.81960785, 0.8627451, 1.0),
	&"magic": Color(0.3372549, 0.36078432, 0.3882353, 1.0),
	&"rare": Color(0.9098039, 0.43921569, 0.22745098, 1.0),
}

## STATION_HUB section 5.10's row strings. Every one of them is the document's
## own wording; the meta is section 5.3's with the rarity appended.
const META_FORMAT := "SLOT %s · DRAW %d · %s"
const FACTION_LOT_TAG := "F LOT"
const HOT_CAPTION_FORMAT := "WAS %s CR"
const RESTOCK_FORMAT := "NEXT RESTOCK %d:%02d"
const OWNED_FORMAT := "OWNED ×%d"


## ---------------------------------------------------------------------------
## The rotation (10 sections 2.1 and 2.2; the exchange's lazy bands)
## ---------------------------------------------------------------------------


## Advances the shelf to `now` and returns the number of bands applied, exactly as
## `Exchange.evaluate_market` does for the market.
##
## A profile whose shelf has never been drawn (`last_band <= 0`) is stamped:
## `last_band = now` and one shelf is drawn. Otherwise `Clock.bands_between`
## counts the whole 20-minute bands elapsed since the last restock; each one draws
## a fresh shelf (10 section 2.1), the unbought listings of the shelf it replaces
## are discarded -- their ids are spent and the counter never rewinds (CONTRACTS
## section 15) -- and the stamp moves to `now`.
##
## A call with no whole band elapsed writes nothing at all, so the stamp keeps the
## shelf's real restock time and `next_restock_seconds` stays a true reading.
static func evaluate_shelf(profile: Node, now: int, rng: RandomNumberGenerator = null) -> int:
	if profile == null:
		return 0
	var state: Dictionary = profile.call(&"auction")
	var last := _integer(state, &"last_band", 0)
	if last <= 0:
		var fresh := draw_shelf(profile, rng)
		fresh["last_band"] = now
		profile.call(&"set_auction", fresh)
		return 0
	var bands := Clock.bands_between(last, now)
	if bands <= 0:
		return bands
	var drawn: Dictionary = state
	for _band: int in range(bands):
		drawn = draw_shelf(profile, rng)
	drawn["last_band"] = now
	profile.call(&"set_auction", drawn)
	return bands


## One fresh shelf in CONTRACTS section 15's shape, without touching the profile's
## stamp: `{last_band: 0, hulls: Array[String], modules: Dictionary, hot:
## StringName}`. The draw is the whole rotation in one place, so the pane, a probe
## and the suite all see the same shelf shape.
##
## The three draws, in this order (a seeded RNG's outcome is stable only while the
## order holds):
##   1. the six hulls, by 10 section 2.2's weights (`_draw_hulls`);
##   2. the ten module listings, the F lot first when 15 section 8's interim is on
##      and the rest by `draw_tier` + a uniform pick from that tier's rows;
##   3. the one hot slot, uniform over the sixteen listed ids.
static func draw_shelf(profile: Node, rng: RandomNumberGenerator = null) -> Dictionary:
	var stream := _stream(rng)
	var hulls := _draw_hulls(stream)
	var modules := _draw_listings(profile, stream)
	return {"last_band": 0, "hulls": hulls, "modules": modules, "hot": _draw_hot(hulls, modules, stream)}


## 10 section 2.1's one hot slot: a uniform pick over the six hull ids and the ten
## listing ids, `&""` for a shelf that lists nothing.
static func _draw_hot(hulls: Array, modules: Dictionary, rng: RandomNumberGenerator) -> StringName:
	var candidates: Array[StringName] = []
	for id: String in hulls:
		candidates.append(StringName(id))
	for key: Variant in modules.keys():
		candidates.append(StringName(str(key)))
	if candidates.is_empty():
		return &""
	return candidates[rng.randi_range(0, candidates.size() - 1)]


## The six listed hulls, in `HULL_ORDER` (the ladder's order).
##
## 10 section 2.2 gives each class a chance of appearing -- the two starter hulls
## always, then 60 / 45 / 30 / 20 % -- and 10 section 2.1 wants exactly six on the
## shelf. The two rules cannot both hold for every seed, so the reconciliation is
## stated here and nowhere else: every hull is rolled against its own chance, and the
## result is then filled up to six or trimmed to six **in the pin's own chance order**
## -- the highest-chance missing hull fills first, the lowest-chance listed hull is
## dropped first, ties keeping `HULL_ORDER`'s position. That is what keeps the pinned
## reading ("weighted so the ladder reads as progression") visible in what a player
## actually sees; reconciling by class rank instead inverts it, because `SHIPS` orders
## the 45 % Corvette above the 60 % Hauler.
##
## Measured over 2 000 seeded shelves: Fighter and Cutter 1.0000 each, and the rest
## strictly ordered by their own chance. The starters are an absolute floor.
static func _draw_hulls(rng: RandomNumberGenerator) -> Array[String]:
	var passed: Array[StringName] = []
	var missed: Array[StringName] = []
	for ship_id: StringName in HULL_ORDER:
		if rng.randf() < hull_chance(ship_id):
			passed.append(ship_id)
		else:
			missed.append(ship_id)
	_sort_by_chance_desc(missed)
	while passed.size() < HULL_SLOTS and not missed.is_empty():
		passed.append(missed.pop_front())
	var droppable: Array[StringName] = []
	for ship_id: StringName in passed:
		if not STARTER_HULLS.has(ship_id):
			droppable.append(ship_id)
	_sort_by_chance_desc(droppable)
	while passed.size() > HULL_SLOTS and not droppable.is_empty():
		passed.erase(droppable.pop_back())
	var ids: Array[String] = []
	for ship_id: StringName in HULL_ORDER:
		if passed.has(ship_id):
			ids.append(String(ship_id))
	return ids


## `ids` in the reconciliation's own order: the higher chance first, and
## `HULL_ORDER`'s position on a tie (the `SHIPS` order 10 section 2.2's correction
## pins, which is *not* chance-sorted). Insertion sort: the arrays are nine entries at
## most.
static func _sort_by_chance_desc(ids: Array[StringName]) -> void:
	for index in range(1, ids.size()):
		var key := ids[index]
		var cursor := index - 1
		while cursor >= 0 and _reconciles_before(key, ids[cursor]):
			ids[cursor + 1] = ids[cursor]
			cursor -= 1
		ids[cursor + 1] = key


## Whether `a` reconciles before `b` (10 section 2.2's own ordering).
static func _reconciles_before(a: StringName, b: StringName) -> bool:
	var left := hull_chance(a)
	var right := hull_chance(b)
	if not is_equal_approx(left, right):
		return left > right
	return HULL_ORDER.find(a) < HULL_ORDER.find(b)


## 10 section 2.2's chance for one hull: `1.0` for the two starter hulls and for
## any id the table does not name (an unknown hull is not the shelf's to hide).
static func hull_chance(ship_id: StringName) -> float:
	return float(HULL_CHANCE.get(ship_id, 1.0))


## The ten module listings, keyed by their minted instance id, each an ordinary
## instance record (`PlayerProfile.roll_listing`'s shape).
##
## The F lot takes the **first** slot while 15 section 8's interim is on: one of
## 15 section 5's three exclusives, uniformly picked, rolled from 15 section 9.2's
## `faction_lot` row so its rarity is Magic or Rare and never Common. The other
## nine come from `draw_tier` -- 10 section 2.1's "tier weights I 50 / II 35 /
## III 15" -- and a uniform pick from that tier's catalogue rows, so a shelf may
## list one base id twice with two different rolls, which is exactly what an
## instance is for.
static func _draw_listings(profile: Node, rng: RandomNumberGenerator) -> Dictionary:
	var listings: Dictionary = {}
	if profile == null:
		return listings
	if AUCTION_FACTION_LOTS_INTERIM:
		var exclusives := exclusive_ids()
		if not exclusives.is_empty():
			var pick: StringName = exclusives[rng.randi_range(0, exclusives.size() - 1)]
			_mint(profile, pick, ModuleData.SOURCE_FACTION_LOT, listings)
	for _slot: int in range(MODULE_SLOTS - listings.size()):
		var pool := tier_pool(draw_tier(rng))
		if pool.is_empty():
			continue
		var base: StringName = pool[rng.randi_range(0, pool.size() - 1)]
		_mint(profile, base, ModuleData.SOURCE_AUCTION, listings)
	return listings


## Roll one listing and file it under its minted id. An id the profile could not
## roll (an unknown base, a source the catalogue does not carry) is skipped, so a
## shelf always holds only records the catalogue can price.
static func _mint(
	profile: Node, base_id: StringName, source: StringName, listings: Dictionary
) -> void:
	var record: Dictionary = profile.call(&"roll_listing", base_id, source)
	if record.is_empty():
		return
	var id := String(record.get("instance_id", ""))
	if id == "":
		return
	listings[id] = record


## 10 section 2.1's tier draw, by `TIER_WEIGHTS`. The fractions come from the
## weights themselves, so the table is the only place the split is written.
static func draw_tier(rng: RandomNumberGenerator = null) -> int:
	var stream := _stream(rng)
	var total := 0
	for tier: int in TIER_ORDER:
		total += maxi(0, int(TIER_WEIGHTS.get(tier, 0)))
	if total <= 0:
		return TIER_ORDER[0]
	var roll := stream.randi_range(1, total)
	var accumulated := 0
	for tier: int in TIER_ORDER:
		accumulated += maxi(0, int(TIER_WEIGHTS.get(tier, 0)))
		if roll <= accumulated:
			return tier
	return TIER_ORDER[0]


## Every catalogue module row at `tier`, in `ModuleCatalog.MODULES`' order. The
## three 15 section 9.1 exclusives are excluded: they are the F lot's own three,
## never a tier-roll outcome (15 section 5: exclusives live at faction stations).
static func tier_pool(tier: int) -> Array[StringName]:
	var ids: Array[StringName] = []
	for id: StringName in ModuleData.MODULES:
		if ModuleData.EXCLUSIVES.has(id):
			continue
		if int(ModuleData.module(id).get(&"tier", 0)) == tier:
			ids.append(id)
	return ids


## 15 section 5's three exclusives, in the catalogue's own order.
static func exclusive_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id: StringName in ModuleData.MODULES:
		if ModuleData.EXCLUSIVES.has(id):
			ids.append(id)
	return ids


static var _shared: RandomNumberGenerator = null


## The RNG a draw reads: the caller's stream when one was handed in (the seeded
## tests' and the probes' route), else the **global** one (15 section 8: "rolls
## read the global RNG"; the profile's own rolls use it too).
static func _stream(rng: RandomNumberGenerator) -> RandomNumberGenerator:
	if rng != null:
		return rng
	if _shared == null:
		_shared = RandomNumberGenerator.new()
		_shared.randomize()
	return _shared


## ---------------------------------------------------------------------------
## The clock's reading (STATION_HUB section 5.10's S3 amendment)
## ---------------------------------------------------------------------------


## Seconds until the shelf's next restock, as a reading taken at the moment it is
## asked: the shelf's own stamp plus the clock's `BAND_SECONDS` band, less `now`.
## `BAND_SECONDS` for a shelf that has never been drawn (the first draw stamps
## `now`, so a brand-new account reads a full band) and `0` for a shelf whose band
## has already elapsed -- `evaluate_shelf` redraws that one before this is read.
##
## This is not a countdown: nothing ticks it, because the clock forbids a
## per-consumer Timer (05 section 8).
static func next_restock_seconds(profile: Node, now: int) -> int:
	if profile == null:
		return Clock.BAND_SECONDS
	var state: Dictionary = profile.call(&"auction")
	var last := _integer(state, &"last_band", 0)
	if last <= 0:
		return Clock.BAND_SECONDS
	return maxi(0, last + Clock.BAND_SECONDS - now)


## `NEXT RESTOCK <m:ss>` (STATION_HUB section 5.10's rotation footer). A whole
## band reads `20:00`; the format is `%d:%02d`, so the minute half is never padded
## and the seconds half always is.
static func restock_text(seconds: int) -> String:
	var safe := maxi(0, seconds)
	@warning_ignore("integer_division")
	return RESTOCK_FORMAT % [safe / 60, safe % 60]


## ---------------------------------------------------------------------------
## The shelf, read (one pricing function family, 05 section 8)
## ---------------------------------------------------------------------------


## The six listed hull ids, `HULL_ORDER`'s order (the draw's own order, so a shelf
## that was persisted reads back the way it was drawn).
static func hull_ids(profile: Node) -> Array[StringName]:
	var ids: Array[StringName] = []
	if profile == null:
		return ids
	for id: String in _names(profile.call(&"auction"), &"hulls"):
		if not Catalog.ship(StringName(id)).is_empty():
			ids.append(StringName(id))
	return ids


## The shelf's ten listing ids, drawn order (the F lot first), reading through
## CONTRACTS section 15's `auction.modules`.
static func listing_ids(profile: Node) -> Array[StringName]:
	var ids: Array[StringName] = []
	for entry: Dictionary in listing_rows(profile):
		ids.append(entry[&"id"])
	return ids


## The one discounted listing id, `&""` when the shelf carries none.
static func hot_id(profile: Node) -> StringName:
	if profile == null:
		return &""
	return StringName(str(_lookup(profile.call(&"auction"), &"hot")))


## One listing's canonical record, `{}` for an id the shelf does not list.
static func listing(profile: Node, id: StringName) -> Dictionary:
	if profile == null or id == &"":
		return {}
	var listings: Variant = _lookup(profile.call(&"auction"), &"modules")
	if not listings is Dictionary:
		return {}
	var raw: Variant = (listings as Dictionary).get(String(id), null)
	if not raw is Dictionary:
		return {}
	return (raw as Dictionary).duplicate(true)


## The MODULES section's rows, in the shelf's drawn order, each one the pinned
## shape STATION_HUB section 5.10 renders:
##
## `{id, base_id, rarity, name, slot, draw, meta, icon, tint, price, was, hot,
## faction_lot, owned}`
##
## `name` is 15 section 7's full rolled name, `meta` is section 5.3's own line
## with the rarity appended, `price` is the number the row charges (09 list x 15
## section 1's rarity multiplier, 10 section 2.1's hot slot after) and `was` the
## pre-discount price on the hot row only. `faction_lot` is 15 section 8's interim
## tag. Every number is `ModuleCatalog`'s.
static func listing_rows(profile: Node) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if profile == null:
		return rows
	var listings: Variant = _lookup(profile.call(&"auction"), &"modules")
	if not listings is Dictionary:
		return rows
	var hot := hot_id(profile)
	for key: Variant in (listings as Dictionary).keys():
		var raw: Variant = (listings as Dictionary)[key]
		if not raw is Dictionary:
			continue
		var id := StringName(str(key))
		var record: Dictionary = raw
		var base := StringName(str(record.get("base_id", "")))
		var rarity := StringName(str(record.get("rarity", "")))
		var row := ModuleData.module(base)
		var list := ModuleData.list_price(base, rarity)
		var discounted := id == hot
		rows.append({
			&"id": id,
			&"base_id": base,
			&"rarity": rarity,
			&"name": rolled_name(record),
			&"slot": String(row.get(&"slot", &"")),
			&"draw": int(row.get(&"draw", 0)),
			&"meta": meta_of(base, rarity),
			&"icon": ModuleData.icon_path(base),
			&"tint": rarity_token(rarity),
			&"price": hot_price(list) if discounted else list,
			&"was": list if discounted else 0,
			&"hot": discounted,
			&"faction_lot": ModuleData.EXCLUSIVES.has(base),
			&"owned": _held(profile, base),
		})
	return rows


## The HULLS section's rows, in `HULL_ORDER`'s order:
##
## `{id, name, ship_class, list, price, was, hot, preview, owned}`
##
## STATION_HUB section 5.10 sizes the row's icon slot at "48 px class icon" and
## records that **no class icon ships** -- `StationCatalog.SHIPS` carries
## `preview` only, and there is no `assets/icons/ship/` -- so the slot draws each
## hull's own `preview`, the way the shipyard's row does (section 5.2).
## `ship_class` is `ShipFit.HULLS`' own class column, the shelf's display value.
static func hull_rows(profile: Node) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if profile == null:
		return rows
	var hot := hot_id(profile)
	for ship_id: StringName in hull_ids(profile):
		var ship := Catalog.ship(ship_id)
		var list := int(ship.get(&"cost", 0))
		var discounted := ship_id == hot
		rows.append({
			&"id": ship_id,
			&"name": String(ship.get(&"name", "")),
			&"ship_class": String(_hull_row(ship_id).get(&"ship_class", "")),
			&"list": list,
			&"price": hot_price(list) if discounted else list,
			&"was": list if discounted else 0,
			&"hot": discounted,
			&"preview": String(ship.get(&"preview", "")),
			&"owned": _owns(profile, ship_id),
		})
	return rows


## The SELL MODULES sub-list: one row per instance of the bag, ordered by the base
## id's slot (`ShipFit.FIT_SLOT_KEYS`, section 5.3's own order) and then by
## catalogue order, creation order last.
##
## STATION_HUB section 5.10 borrows section 5.3's OWNED MODULES anatomy and prices
## a `SELL` at `base x rarity x 60 %` (15 section 6). A sell price is
## **per-instance** -- two Laser MkIIs of one base id at two rarities do not sell
## for the same money -- so the row that carries the `SELL` plate is the
## instance's row, and the base id is the ordering and the `OWNED x<n>` aggregate.
## Each row:
##
## `{id, base_id, rarity, name, slot, draw, meta, icon, tint, price, owned,
## owned_text}`
static func sell_rows(profile: Node) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if profile == null:
		return rows
	var bag: Dictionary = profile.call(&"modules")
	var grouped: Dictionary = {}
	for key: Variant in bag.keys():
		var raw: Variant = bag[key]
		if not raw is Dictionary:
			continue
		var record: Dictionary = raw
		if int(record.get("count", 0)) <= 0:
			continue
		var base := StringName(str(record.get("base_id", key)))
		if grouped.has(base):
			grouped[base].append(StringName(str(key)))
		else:
			grouped[base] = [StringName(str(key))]
	for base: StringName in _slot_order(grouped.keys()):
		var ids: Array = grouped[base]
		for id: StringName in ids:
			var record: Dictionary = profile.call(&"instance", id)
			if record.is_empty():
				continue
			rows.append(_sell_row(id, record, ids.size()))
	return rows


static func _sell_row(id: StringName, record: Dictionary, owned: int) -> Dictionary:
	var base := StringName(str(record.get("base_id", "")))
	var rarity := StringName(str(record.get("rarity", "")))
	var row := ModuleData.module(base)
	return {
		&"id": id,
		&"base_id": base,
		&"rarity": rarity,
		&"name": rolled_name(record),
		&"slot": String(row.get(&"slot", &"")),
		&"draw": int(row.get(&"draw", 0)),
		&"meta": meta_of(base, rarity),
		&"icon": ModuleData.icon_path(base),
		&"tint": rarity_token(rarity),
		&"price": sell_price(base, rarity, _rows(record.get("suffixes"))),
		&"owned": owned,
		&"owned_text": OWNED_FORMAT % owned,
	}


## Every base id the bag holds instances of, in the order the sell sub-list
## renders: `ShipFit.FIT_SLOT_KEYS`' slot order first, then `ModuleCatalog`'s
## catalogue order inside a slot (section 5.3's own rule).
static func _slot_order(bases: Array) -> Array[StringName]:
	var ordered: Array[StringName] = []
	for slot_key: StringName in FitData.FIT_SLOT_KEYS:
		for id: StringName in ModuleData.MODULES:
			if not bases.has(id):
				continue
			if ModuleData.fit_slot_of(id) == slot_key:
				ordered.append(id)
	return ordered


## ---------------------------------------------------------------------------
## Prices and names
## ---------------------------------------------------------------------------


## 10 section 2.1's hot slot: `HOT_DISCOUNT_PERCENT` off, applied to a price that
## already carries 15 section 1's rarity multiplier. Never stacked with anything.
static func hot_price(price: int) -> int:
	if price <= 0:
		return 0
	return price * (100 - HOT_DISCOUNT_PERCENT) / 100


## 15 section 6 / 10 sections 2.3 and 2.4: the sell side, rarity-aware. CONTRACTS
## section 20 adds 15 section 4's Ledger term (`of the Ledger`, sell value +25 %): a
## record whose own suffix list carries `ledger` sells for `base x rarity x 60 % x
## 1.25`, so a 900-cost Common is 540 -> 675. The term is one function, and every
## production site passes the record's **own** suffix list, so the pane's displayed
## price (`_sell_row`), the transaction's quote (`sell_row`) and the payout
## (`PlayerProfile.sell_instance`) can never disagree. `[]` (the shipped two-argument
## call) is byte-identical to pre-S7. (15 section 9.3's "no suffix term" line is
## superseded by CONTRACTS section 20.)
static func sell_price(base_id: StringName, rarity: StringName, suffixes: Array = []) -> int:
	var price := ModuleData.sell_price(base_id, rarity)
	if price <= 0 or not _carries_ledger(suffixes):
		return price
	return price * LEDGER_PERCENT / 100


## Whether a record's own suffix list carries 15 section 4's `ledger` row. The list is
## the record's (`["ledger"]` from the store, or `[{id, value}]` in a hand-built
## fixture), so both spellings are read the way `rolled_name` reads them.
static func _carries_ledger(suffixes: Variant) -> bool:
	if not suffixes is Array:
		return false
	for raw: Variant in suffixes as Array:
		if StringName(str(_row_id(raw))) == SUFFIX_LEDGER:
			return true
	return false


## The row's meta, `SLOT <TYPE> · DRAW <n> · <RARITY>`: section 5.3's own line with
## section 5.10's rarity column appended. The slot word is the catalogue's, upper
## cased the way the FITTING pane renders it.
static func meta_of(base_id: StringName, rarity: StringName) -> String:
	var row := ModuleData.module(base_id)
	var word: Variant = RARITY_WORDS.get(rarity, null)
	return META_FORMAT % [
		String(row.get(&"slot", &"")).to_upper(),
		int(row.get(&"draw", 0)),
		String(word) if word != null else String(rarity).to_upper(),
	]


## 15 section 7's naming grammar: `[Prefix1] [Prefix2] <Module Name> of <Suffix1>
## of <Suffix2>`. A Common carries no affix and shows its plain 09 name. The
## suffix rows already spell their own "of" (`of the Whale`), so each one is
## appended whole.
##
## This is the one shared name builder: FITTING's and the shipyard's rows read it
## rather than growing a second copy of the grammar (15 section 9.3 stores, names,
## prices and displays an affix -- 15 section 7 is where the name comes from).
static func rolled_name(record: Dictionary) -> String:
	var base := StringName(str(record.get("base_id", "")))
	var parts := PackedStringArray()
	for raw: Variant in _rows(record.get("prefixes")):
		var id := StringName(str(_row_id(raw)))
		var prefix: Variant = ModuleData.PREFIXES.get(id, null)
		if prefix is Dictionary:
			parts.append(String((prefix as Dictionary).get(&"name", String(id))))
	parts.append(String(ModuleData.module(base).get(&"name", String(base))))
	for raw: Variant in _rows(record.get("suffixes")):
		var id := StringName(str(_row_id(raw)))
		var suffix: Variant = ModuleData.SUFFIXES.get(id, null)
		if suffix is Dictionary:
			parts.append(String((suffix as Dictionary).get(&"name", "of " + String(id))))
		else:
			parts.append("of " + String(id))
	return " ".join(parts)


## The theme token one rarity's name cell is drawn with (STATION_HUB section
## 5.10's three `rarity_*` tokens).
static func rarity_token(rarity: StringName) -> StringName:
	return StringName(RARITY_TOKENS.get(rarity, &"rarity_common"))


## The hex a rarity falls back to when the theme carries no token.
static func rarity_fallback(rarity: StringName) -> Color:
	var colour: Variant = RARITY_FALLBACK.get(rarity, null)
	return colour if colour is Color else Color.WHITE


## ---------------------------------------------------------------------------
## The transactions (01 section 7 order: verify -> charge -> give -> log)
## ---------------------------------------------------------------------------


## Buy one listing off the shelf, at the price the row shows. The cost is read
## from the row itself (`listing_rows`), so the pane and the transaction cannot
## disagree about a hot slot.
##
## Returns the exchange's own result shape: `{ok, reason, kind, id, base_id, name,
## cost, price}`. A refusal writes no credits, moves no record and logs nothing.
static func buy_listing(profile: Node, id: StringName) -> Dictionary:
	var result := _blank(&"listing", id)
	var record := listing(profile, id)
	if record.is_empty():
		return _refuse(result, REASON_UNKNOWN)
	var row := _row_for(id, record, id == hot_id(profile))
	result[&"base_id"] = row[&"base_id"]
	result[&"name"] = row[&"name"]
	result[&"cost"] = int(row[&"price"])
	if not bool(profile.call(&"buy_instance", id, int(row[&"price"]))):
		return _refuse(result, REASON_INSUFFICIENT)
	result[&"ok"] = true
	result[&"price"] = int(row[&"price"])
	return result


## Buy one listed hull at 10 section 2.3's buyout: the list price, or the hot slot's
## -20 % when this hull carries it. `buy_ship` keeps the hull's bare-with-
## mandatory-set rule (10 section 2.3), so this adds only the shelf's arithmetic.
static func buy_hull(profile: Node, id: StringName) -> Dictionary:
	var result := _blank(&"hull", id)
	var ship := Catalog.ship(id)
	if ship.is_empty():
		return _refuse(result, REASON_UNKNOWN)
	result[&"name"] = String(ship.get(&"name", ""))
	var list := int(ship.get(&"cost", 0))
	var cost := hot_price(list) if id == hot_id(profile) else list
	result[&"cost"] = cost
	if not bool(profile.call(&"buy_ship", id, cost)):
		var reason := REASON_ALREADY_OWNED if _owns(profile, id) else REASON_INSUFFICIENT
		return _refuse(result, reason)
	result[&"ok"] = true
	result[&"price"] = cost
	return result


## Sell one instance out of the bag, at 15 section 6's `base x rarity x 60 %` (plus
## 15 section 4's Ledger term, CONTRACTS section 20). The price comes from the same
## function `sell_rows` prices the row with, so the row and the transaction agree, and
## the record's own suffix list is what both read.
static func sell_row(profile: Node, id: StringName) -> Dictionary:
	var result := _blank(&"instance", id)
	var record: Dictionary = profile.call(&"instance", id)
	if record.is_empty() or int(record.get("count", 0)) <= 0:
		return _refuse(result, REASON_UNKNOWN)
	var base := StringName(str(record.get("base_id", "")))
	var rarity := StringName(str(record.get("rarity", "")))
	var price := sell_price(base, rarity, _rows(record.get("suffixes")))
	if price <= 0:
		return _refuse(result, REASON_UNKNOWN)
	result[&"base_id"] = base
	result[&"name"] = rolled_name(record)
	result[&"cost"] = price
	if not bool(profile.call(&"sell_instance", id)):
		return _refuse(result, REASON_UNKNOWN)
	result[&"ok"] = true
	result[&"price"] = price
	return result


## ---------------------------------------------------------------------------
## Internals
## ---------------------------------------------------------------------------


## One listing row with its `owned` column filled: `listing_rows`' body, kept
## separate so `buy_listing` prices a hot row through the same arithmetic the pane
## renders.
static func _row_for(id: StringName, record: Dictionary, hot: bool) -> Dictionary:
	var base := StringName(str(record.get("base_id", "")))
	var rarity := StringName(str(record.get("rarity", "")))
	var list := ModuleData.list_price(base, rarity)
	return {
		&"id": id,
		&"base_id": base,
		&"name": rolled_name(record),
		&"price": hot_price(list) if hot else list,
		&"was": list if hot else 0,
		&"hot": hot,
	}


static func _blank(kind: StringName, id: StringName) -> Dictionary:
	return {
		&"ok": false,
		&"reason": &"",
		&"kind": kind,
		&"id": id,
		&"base_id": &"",
		&"name": "",
		&"cost": 0,
		&"price": 0,
	}


static func _refuse(result: Dictionary, reason: StringName) -> Dictionary:
	result[&"ok"] = false
	result[&"reason"] = reason
	return result


## The `hulls` array as plain strings, whatever spelling the store handed back.
static func _names(state: Dictionary, key: StringName) -> Array[String]:
	var names: Array[String] = []
	var raw: Variant = _lookup(state, key)
	if not raw is Array:
		return names
	for entry: Variant in (raw as Array):
		var text := String(entry)
		if text != "":
			names.append(text)
	return names


## `ShipFit.HULLS`' row for a hull, `{}` for a hull the game does not ship. The
## shelf's class column is this row's `ship_class` (10 section 2.2's correction:
## "the class name is the shelf's display column only").
static func _hull_row(ship_id: StringName) -> Dictionary:
	var row: Variant = FitData.HULLS.get(ship_id, null)
	return row if row is Dictionary else {}


## A base id's held count: the bag's instances of it (15 section 8's `count` 1),
## which is what `OWNED ×<n>` counts.
static func _held(profile: Node, base_id: StringName) -> int:
	if profile == null or base_id == &"":
		return 0
	return (profile.call(&"instances_of", base_id) as Array).size()


static func _owns(profile: Node, ship_id: StringName) -> bool:
	if profile == null:
		return false
	return bool(profile.call(&"owns_ship", ship_id))


static func _rows(raw: Variant) -> Array:
	if raw is Array:
		return raw
	return []


static func _row_id(raw: Variant) -> Variant:
	if raw is Dictionary:
		return (raw as Dictionary).get("id", "")
	return raw


## Reads a key in either string form: the persisted shelf uses String keys, an
## in-memory caller tends to use StringName (the exchange's own lookup).
static func _lookup(source: Dictionary, id: StringName) -> Variant:
	if source.has(id):
		return source[id]
	return source.get(String(id), null)


static func _integer(source: Dictionary, id: StringName, fallback: int) -> int:
	var value: Variant = _lookup(source, id)
	if value is int or value is float:
		return int(value)
	return fallback
