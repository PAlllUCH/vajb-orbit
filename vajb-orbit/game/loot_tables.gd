class_name LootTables
extends RefCounted
## The kill-drop tables of `docs/gameplay/06_loot_drops.md`, as data plus one roll.
## Contract: 06 §2 (the per-line procedure), §3 (the four hull tables and their
## 2026-09-20 countermeasure amendment), §5 (credit caches), §6 (the two balance
## checks); `docs/gameplay/18_engine_spec.md` §4.6 (ruling 22: `cm_chaff` 0.15 and
## `cm_flare` 0.15 enter the fighter table) and §6 ("loot from kills uses 06 tables;
## credit caches pay on pickup and log per 01 §7"); brief pinned interface 8.
##
## Pure data + API: no scene tree, no `PlayerProfile`, no `economy_log`. A roll
## returns pickup payloads whose three keys are exactly `Pickup.setup`'s arguments
## (CONTRACTS §5); spawning the pickups and paying them off is the wiring's job.
##
## Odds are 06 §2.3's: rolled per line, independently, never normalised ("two lines
## can both pay, and empty kills happen"), so a table's chance column sums to more
## than 1.0 and an empty payload is a legal result.
##
## kind          06 table                              band  rolled for
## &"fighter"     06 §3.1 Fighter (Grade I)               1    fighter-band hulls, e.g. 13 §3's fighter-band hunters
## &"swarmer"     06 §3.1 weights (18 §5 ruling 24)       1    the alien swarmer archetype
## &"freighter"   06 §3.2 Freighter (Grade I)             1    traders / convoys (18 §5)
## &"corvette"    06 §3.3 Corvette (Grade II)             2    corvette-band hulls
## &"maw"         06 §3.4 Maw dreadnought (Grade III)     3    the Maw (slice-4 seam)
##
## The kind is the 06 table's hull-band name, not the 18 §5 archetype name: a hull
## reaches a table by its band ("Hunters drop loot like pirates of their band", 13
## §3), and the boss archetype's death pays through 14 §5, not through 06. An
## unknown kind is refused loudly (see `has`) rather than guessed into a table, and
## an 18 §5 archetype with no 06 table (hunter wings, the boss) has to be mapped by
## its band by the caller.

const ComponentCatalogScript := preload("res://game/component_catalog.gd")

## 06 §5: "Caches bypass cargo entirely: they are money, not goods" and, on
## collection, "calls `PlayerProfile.add_credits(amount)` directly". 06 names the
## cache's look (the salvage glyph) but no item id, and the id `Pickup.setup` takes
## is the key 01 §7's log line reads, so a cache line carries the credit key itself.
const CREDIT_ITEM: StringName = &"credits"

## 06 §4 / CONTRACTS §19: "A destroyed hull leaves a wreck site ... holding its
## uncollected pickups for 90 s (`WRECK_PICKUP_LIFETIME`), after which pickups
## despawn." The wreck site's own clock, owned here because 06 §4 names the constant
## in the same table family as the rolls (the site reads it through `LootTables`).
const WRECK_PICKUP_LIFETIME := 90.0

## A roll result's keys: exactly the pinned `Pickup.setup(item_id, amount,
## is_credit_cache)` arguments, in that order. One dictionary is one pickup (06
## §2.3's implementer's choice: a line's units ship as a single stack, which
## `setup`'s quantity carries), and a cache is always its own entry (06 §2.4).
const KEY_ITEM: StringName = &"item_id"
const KEY_AMOUNT: StringName = &"amount"
const KEY_CACHE: StringName = &"is_credit_cache"

## 06 §3.1's fighter table, whole. Lines 1-4 are the catalogue components; lines 5-6
## are the 2026-09-20 amendment's countermeasures (06 §3.1, 18 §4.6), which carry
## the 03 §3 names' shape but have no 03 row yet (see `uncatalogued_items`).
##
## 18 §5 (ruling 24) gives the alien `swarmer` pirate-like behaviour, and slice 2's
## brief extends that to its loot ("the swarmer table reuses the same weights"), so
## `&"swarmer"` points at this same array: one owner, so the two tables cannot drift.
const FIGHTER_LINES: Array[Dictionary] = [
	{&"item": &"comp_scrap_1", &"chance": 0.55, &"min": 1, &"max": 2},
	{&"item": &"comp_weap_1", &"chance": 0.30, &"min": 1, &"max": 1},
	{&"item": &"comp_pow_1", &"chance": 0.35, &"min": 1, &"max": 2},
	{&"item": &"comp_elec_1", &"chance": 0.20, &"min": 1, &"max": 1},
	{&"item": &"cm_chaff", &"chance": 0.15, &"min": 1, &"max": 1},
	{&"item": &"cm_flare", &"chance": 0.15, &"min": 1, &"max": 1},
]

## 06 §3.2's freighter table (Grade I, cargo-flavoured), cache line last.
const FREIGHTER_LINES: Array[Dictionary] = [
	{&"item": &"comp_scrap_1", &"chance": 0.60, &"min": 2, &"max": 3},
	{&"item": &"comp_mech_1", &"chance": 0.35, &"min": 1, &"max": 1},
	{&"item": &"comp_ore_1", &"chance": 0.30, &"min": 1, &"max": 2},
	{&"item": CREDIT_ITEM, &"chance": 0.15, &"min": 40, &"max": 80},
]

## 06 §3.3's corvette table (Grade II), cache line last.
const CORVETTE_LINES: Array[Dictionary] = [
	{&"item": &"comp_scrap_2", &"chance": 0.50, &"min": 1, &"max": 2},
	{&"item": &"comp_weap_2", &"chance": 0.30, &"min": 1, &"max": 1},
	{&"item": &"comp_mech_2", &"chance": 0.25, &"min": 1, &"max": 1},
	{&"item": &"comp_elec_2", &"chance": 0.20, &"min": 1, &"max": 1},
	{&"item": CREDIT_ITEM, &"chance": 0.10, &"min": 120, &"max": 250},
]

## 06 §3.4's Maw dreadnought table (Grade III, the only Grade III source), cache
## line last. Lines 1 and 6 stand at chance 1.00, so "line 1 + line 6 always pay".
const MAW_LINES: Array[Dictionary] = [
	{&"item": &"comp_scrap_3", &"chance": 1.00, &"min": 3, &"max": 5},
	{&"item": &"comp_mech_3", &"chance": 0.75, &"min": 1, &"max": 2},
	{&"item": &"comp_weap_3", &"chance": 0.60, &"min": 1, &"max": 1},
	{&"item": &"comp_elec_3", &"chance": 0.40, &"min": 1, &"max": 1},
	{&"item": &"comp_ore_3", &"chance": 0.25, &"min": 1, &"max": 1},
	{&"item": CREDIT_ITEM, &"chance": 1.00, &"min": 800, &"max": 1200},
]

## The four 06 §3 tables, each with the hull band its §3 heading states (06 §1.4:
## "a hull's table can only contain component grades at or below its own band") and
## its lines in the doc's order. Every cache line is last, as 06 §2.4 requires
## ("credit caches roll last") and as the doc's own tables already place it.
const TABLES: Dictionary = {
	&"fighter": {&"band": 1, &"lines": FIGHTER_LINES},
	&"swarmer": {&"band": 1, &"lines": FIGHTER_LINES},
	&"freighter": {&"band": 1, &"lines": FREIGHTER_LINES},
	&"corvette": {&"band": 2, &"lines": CORVETTE_LINES},
	&"maw": {&"band": 3, &"lines": MAW_LINES},
}

## 06 §8's amendment (13 §3's "`comp_elec`-weighted table", owner tick 8): the
## electronics a hunter drops **in addition to** its band table. The rows are the
## doc's, in its order, and the same independent-per-line procedure as §2 applies.
## The grade cap of §1.4 is applied at roll time by `roll_hunter_extra` (`_grade_of`
## reads each row's grade off the 03 catalogue rather than restating it), so a
## fighter-band hunter rolls `comp_elec_1` only and a corvette-band one adds
## `comp_elec_2`. Reversal: delete this table and the `roll_hunter_extra` call.
const HUNTER_EXTRA: Array[Dictionary] = [
	{&"item": &"comp_elec_1", &"chance": 0.50, &"min": 1, &"max": 2},
	{&"item": &"comp_elec_2", &"chance": 0.25, &"min": 1, &"max": 1},
	{&"item": &"comp_elec_3", &"chance": 0.10, &"min": 1, &"max": 1},
]


## Whether this file carries a table for `kind`. The wiring should gate on this
## instead of guessing a kind: `roll` refuses an unknown one rather than dropping
## silently, because a missing table is a wrong call, not an unlucky kill.
static func has(kind: StringName) -> bool:
	return TABLES.has(kind)


## One 06 §2 roll of `kind`'s table: per line, in table order, `chance` then
## `randi_range(min, max)` units, each paying line one pickup payload (06 §2.1-§2.4).
##
## `tier` is the rolling hull's band (06 §3's headings: fighter and freighter Grade I,
## corvette Grade II, the Maw Grade III) - the axis 06 §7's deferred sector-cache
## scaling (×1 T1-T2, ×1.5 T3, ×2 T4) would eventually read. 06 §7 marks that scaling
## "documented, not built in v1", so v1 rolls the table verbatim at every tier; a
## tier below 1 is not a band (the docs' bands are 1-based) and is warned about, but
## it can never cost a hull its loot, so it does not change the payload either.
##
## `random_seed` 0 randomizes (the in-game call); a non-zero seed makes a roll
## reproducible for probes and tests, the same contract `Sector.populate` carries.
static func roll(kind: StringName, tier: int, random_seed: int = 0) -> Array[Dictionary]:
	if not has(kind):
		push_error(
			"LootTables.roll: no table for kind %s (have: %s)"
			% [kind, ", ".join(_kind_names())]
		)
		return []
	if tier < 1:
		push_warning("LootTables.roll: tier %d is not a band; rolling %s unchanged" % [tier, kind])
	var rng := RandomNumberGenerator.new()
	if random_seed == 0:
		rng.randomize()
	else:
		rng.seed = random_seed
	var payload: Array[Dictionary] = []
	for line: Dictionary in _lines(kind):
		if rng.randf() >= float(line[&"chance"]):
			continue
		var item: StringName = line[&"item"]
		payload.append({
			KEY_ITEM: item,
			KEY_AMOUNT: rng.randi_range(int(line[&"min"]), int(line[&"max"])),
			KEY_CACHE: item == CREDIT_ITEM,
		})
	return payload


## 06 §8 / CONTRACTS §19's kill roll: the band table the victim's kind names, rolled
## through the shipped `roll` with the table's own band as `tier` (06 §3's headings).
## A thin delegate on purpose - the shipped shape (one entry per line, `amount =
## randi_range`, caches last and distinct) stays byte-identical, and the `swarmer`
## kind keeps reusing the fighter weights (18 §5 ruling 24). An unknown kind is
## refused loudly, exactly as `roll` refuses it.
static func roll_band(kind: StringName, random_seed: int = 0) -> Array[Dictionary]:
	if not has(kind):
		push_error(
			"LootTables.roll_band: no table for kind %s (have: %s)"
			% [kind, ", ".join(_kind_names())]
		)
		return []
	return roll(kind, int((TABLES[kind] as Dictionary)[&"band"]), random_seed)


## 06 §8's hunter extra roll, in addition to the victim's band table: `HUNTER_EXTRA`'s
## rows, one chance roll per line in table order, and a row whose 03 grade exceeds
## `band` is skipped (06 §1.4's cap, applied here rather than at load because the one
## table serves all three bands). `random_seed` follows `roll`'s contract: 0 randomizes,
## a non-zero seed makes the roll reproducible. A band below 1 is not a band and is
## warned about, but it caps every row out rather than paying a grade above it.
static func roll_hunter_extra(band: int, random_seed: int = 0) -> Array[Dictionary]:
	if band < 1:
		push_warning("LootTables.roll_hunter_extra: band %d is not a band; nothing rolls" % band)
	var rng := RandomNumberGenerator.new()
	if random_seed == 0:
		rng.randomize()
	else:
		rng.seed = random_seed
	var payload: Array[Dictionary] = []
	for line: Dictionary in HUNTER_EXTRA:
		var item: StringName = line[&"item"]
		if _grade_of(item) > band:
			continue
		if rng.randf() >= float(line[&"chance"]):
			continue
		payload.append({
			KEY_ITEM: item,
			KEY_AMOUNT: rng.randi_range(int(line[&"min"]), int(line[&"max"])),
			KEY_CACHE: item == CREDIT_ITEM,
		})
	return payload


## The `HUNTER_EXTRA` rows a band may not pay, one line per offending (item, band)
## pair, so an empty array is the cap holding for that band. `band` 3 is the whole
## table (06 §8's rows are grades 1-3), `band` 1 leaves `comp_elec_2`/`_3` out.
static func hunter_extra_violations(band: int) -> Array[String]:
	var violations: Array[String] = []
	for line: Dictionary in HUNTER_EXTRA:
		var item: StringName = line[&"item"]
		var grade := _grade_of(item)
		if grade > band:
			violations.append("%s is grade %d above band %d" % [item, grade, band])
	return violations


## 06 §6 check 2: "no table references a component grade above its hull band; this is
## assertable directly against the 03 catalogue at load time." One line per offending
## (table, item) pair, so an empty array is the check passing.
static func cap_violations() -> Array[String]:
	var violations: Array[String] = []
	for kind: StringName in TABLES:
		var band := int((TABLES[kind] as Dictionary)[&"band"])
		for line: Dictionary in _lines(kind):
			var item: StringName = line[&"item"]
			var grade := _grade_of(item)
			if grade > band:
				violations.append(
					"%s: %s is grade %d above the table's band %d" % [kind, item, grade, band]
				)
	return violations


## The table items the 03 §3 catalogue carries no row for, sorted by name and
## unique. The grade cap of 06 §1.4 cannot be proved for one of these, so it is
## reported rather than assumed (brief ruling four: a missing spec value is
## reported, not guessed). Sorted as strings: a `StringName` sort orders by name
## identity, not by text, so two callers would otherwise disagree.
static func uncatalogued_items() -> Array[StringName]:
	var names: Array[String] = []
	for kind: StringName in TABLES:
		for line: Dictionary in _lines(kind):
			var item: StringName = line[&"item"]
			if item == CREDIT_ITEM or _grade_of(item) > 0:
				continue
			var name := str(item)
			if not names.has(name):
				names.append(name)
	names.sort()
	var missing: Array[StringName] = []
	for name: String in names:
		missing.append(StringName(name))
	return missing


## 03 §3's grade for a catalogue item, 0 for an id the catalogue does not carry.
static func _grade_of(item: StringName) -> int:
	var entry: Dictionary = ComponentCatalogScript.component(item)
	if entry.is_empty():
		return 0
	return int(entry.get(&"grade", 0))


## A table's lines, handed back as a typed array so the callers' loops stay typed.
## `assign` converts the dictionary's stored array once instead of casting it.
static func _lines(kind: StringName) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	lines.assign((TABLES[kind] as Dictionary)[&"lines"])
	return lines


static func _kind_names() -> Array[String]:
	var names: Array[String] = []
	for kind: StringName in TABLES:
		names.append(str(kind))
	names.sort()
	return names
