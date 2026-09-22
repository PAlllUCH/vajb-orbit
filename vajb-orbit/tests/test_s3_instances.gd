@tool
extends McpTestSuite
## Suite s3_instances: the save v6 module instance on `PlayerProfile` (15 sections 1-9,
## CONTRACTS section 15) - the six-key record, the creation-time roll with its seeded
## outcomes, the bag/fitted `count` round trip, and the base-id translation every fit
## judgement reads a fit through.
##
## The record is `{instance_id, base_id, rarity, prefixes[], suffixes[], count}`, keyed
## by its own minted id (`mod_%04d` from the one per-profile counter): `count` 1 means
## the bag, 0 means fitted, and a fitted record is **never erased** - that is how REMOVE
## and SWAP hand the *same* instance back (CONTRACTS section 15). A `count`-0 record is
## invisible to `instances_of`, to the `OWNED x<n>` aggregate and to `sell_instance`.
##
## A roll happens once, when the instance is created, and reads the **global** RNG (15
## section 8), so every roll test reseeds first and can then assert the outcome; the
## seeded outcomes pinned below are the ones this engine's RNG produces for `SEED`.
## Nothing here is applied to a flight stat: 15 section 9.3 stores, names, prices and
## displays an affix, and the affix-application wave is staged.
##
## Profiles are throwaway instances of the autoload script whose `save_path` is
## repointed at a scratch file before the first mutation (the `test_p1_profile.gd`
## harness): no instance enters the tree, so the debounced save Timer does not exist and
## every mutation writes through immediately, which is what makes the round trips exact.

const Profile := preload("res://autoload/player_profile.gd")
const ModuleData := preload("res://game/module_catalog.gd")
const FitData := preload("res://game/ship_fit.gd")

const PROFILE_PATH := "user://test_s3_instances.cfg"

## The seed the roll tests fix before every draw: `roll_rarity` and the two affix rolls
## read the global RNG, so seeding first is what makes an outcome repeatable - 15
## section 8's own instruction to the test that pins it.
const SEED := 20260922

## CONTRACTS section 15's six record keys, read off the profile's own constants.
const RECORD_KEYS: Array[String] = [
	Profile.KEY_INSTANCE_ID,
	Profile.KEY_BASE_ID,
	Profile.KEY_RARITY,
	Profile.KEY_PREFIXES,
	Profile.KEY_SUFFIXES,
	Profile.KEY_COUNT,
]

## The catalogue ids this suite rolls and fits. 09 section 3.1 / 3.2.
const LASER: StringName = &"w_laser"
const PLASMA: StringName = &"w_plasma"
const MINING: StringName = &"w_mining"
const LIGHT_SHIELD: StringName = &"s_light"
const ION: StringName = &"e_ion"
const STANDARD_ENGINE: StringName = &"e_std"
const STANDARD_REACTOR: StringName = &"p_std"
const TARGETING: StringName = &"c_target"
const COMPOSITE: StringName = &"h_composite"
const FOLD: StringName = &"b_fold"
## 15 section 9.1's two exclusives this suite rolls: one weapon and the utility.
const PROTON: StringName = &"w_proton"
const EXCLUSIVE_VAULT: StringName = &"u_vault"

## 08 section 3.2's two hulls: the Lancer (2 W cells, power out 6) is the over-budget
## case below, the Delver (2 E cells) the duplicate case.
const FIGHTER: StringName = &"ship_fighter"
const MINER: StringName = &"ship_miner"

var _profiles: Array[Node] = []


func suite_name() -> String:
	return "s3_instances"


func setup() -> void:
	_delete_file(PROFILE_PATH)


func teardown() -> void:
	for profile: Node in _profiles:
		if is_instance_valid(profile):
			profile.free()
	_profiles.clear()


func suite_teardown() -> void:
	_delete_file(PROFILE_PATH)


## ---------------------------------------------------------------------------
## The record, and the mint
## ---------------------------------------------------------------------------


func test_add_instance_mints_the_pinned_six_key_record() -> void:
	var profile = _fresh()
	var id: StringName = profile.add_instance(
		LIGHT_SHIELD, &"magic", [{"id": "sturdy", "value": 0.15}], ["whale"]
	)
	assert_eq(id, StringName(Profile.INSTANCE_ID_FORMAT % 1), "the first mint is mod_0001")
	var record: Dictionary = profile.instance(id)
	assert_eq(record.keys().size(), RECORD_KEYS.size(), "15 section 6's six keys and nothing else")
	for key: String in RECORD_KEYS:
		assert_true(record.has(key), "the record carries %s" % key)
	assert_eq(String(record[Profile.KEY_INSTANCE_ID]), String(id), "instance_id is the key")
	assert_eq(
		String(record[Profile.KEY_BASE_ID]), String(LIGHT_SHIELD), "base_id is the catalogue id"
	)
	assert_eq(String(record[Profile.KEY_RARITY]), "magic", "the rarity it was minted at")
	assert_true(
		_deep_eq(record[Profile.KEY_PREFIXES], [{"id": "sturdy", "value": 0.15}]),
		"prefixes keep the {id, value} rows: %s" % [record[Profile.KEY_PREFIXES]]
	)
	assert_true(_deep_eq(record[Profile.KEY_SUFFIXES], ["whale"]), "suffixes keep one id each")
	assert_eq(int(record[Profile.KEY_COUNT]), 1, "count 1 = in the bag")
	assert_eq(profile.instances_of(LIGHT_SHIELD), [id], "and it is the bag's one instance of it")

	## The two refusals write nothing at all, and spend no number: the next mint is 2.
	assert_eq(profile.add_instance(&"", &"common", [], []), &"", "a blank base id is refused")
	assert_eq(
		profile.add_instance(LIGHT_SHIELD, &"legendary", [], []),
		&"",
		"and so is a rarity outside 15 section 1's three"
	)
	var plain: StringName = profile.add_instance(TARGETING, &"rare", ["wideband"], ["leeches"])
	assert_eq(plain, StringName(Profile.INSTANCE_ID_FORMAT % 2), "a refusal spends no number")
	assert_true(
		_deep_eq(
			profile.instance(plain)[Profile.KEY_PREFIXES], [{"id": "wideband", "value": 0.0}]
		),
		"a bare prefix id is stored as a row with 0.0"
	)
	assert_eq(profile.instance(&"mod_0003"), {}, "and the counter never minted a third")
	assert_eq(profile.modules().size(), 2, "two instances, nothing else")


## ---------------------------------------------------------------------------
## The roll: 15 sections 2, 3, 4, 5 and 9.2
## ---------------------------------------------------------------------------


## Every source's row with every family shape: the rarity is legal for the source, the
## prefixes come from the module's own family at its tier's band value, the suffixes from
## the faction pool the base opens, and no row repeats.
func test_the_roll_reads_the_source_table_and_the_family_pools() -> void:
	var profile = _fresh()
	var families: Array[StringName] = [
		LASER, LIGHT_SHIELD, COMPOSITE, ION, STANDARD_REACTOR, FOLD
	]
	for source: StringName in ModuleData.roll_sources():
		for base: StringName in families:
			seed(SEED)
			var id: StringName = profile.roll_instance(base, source)
			var where := "%s from %s" % [base, source]
			assert_ne(id, &"", "%s rolled" % where)
			var record: Dictionary = profile.instance(id)
			var rarity := String(record[Profile.KEY_RARITY])
			assert_true(
				_legal_rarities(source).has(rarity),
				"%s: %s is one of the source row's" % [where, rarity]
			)
			_assert_affixes_are_legal(record, base, where)

	## 15 section 5's floor: an exclusive never spawns Common, whatever the source's own
	## row says -- the shipyard's row is 100 % Common and still leaves them Magic or Rare.
	for base: StringName in ModuleData.EXCLUSIVES:
		for source: StringName in ModuleData.roll_sources():
			seed(SEED)
			var id: StringName = profile.roll_instance(base, source)
			var where := "%s from %s" % [base, source]
			var record: Dictionary = profile.instance(id)
			assert_ne(
				String(record[Profile.KEY_RARITY]),
				ModuleData.RARITY_COMMON,
				"%s: an exclusive is never Common" % where
			)
			_assert_affixes_are_legal(record, base, where)

	## And the two refusals: an id the catalogue does not ship, and a source outside
	## 15 section 2's table, both roll nothing.
	assert_eq(profile.roll_instance(&"not_a_module", &"drop"), &"", "an unknown base id rolls nothing")
	assert_eq(profile.roll_instance(LASER, &"not_a_source"), &"", "an unknown source rolls nothing")
	assert_eq(
		profile.modules().size(),
		ModuleData.roll_sources().size() * (families.size() + ModuleData.EXCLUSIVES.size()),
		"every successful roll landed in the bag, and neither refusal did"
	)


## The seeded outcomes, measured and then pinned: five shapes, one per row that matters -
## an auction Common (§2's 65 %), a derelict Magic's prefix+suffix pair, the F lot's own
## `faction_lot` row (§9.2), an exclusive floored to Magic by a 100 % Common source with
## its faction's own suffix (§5), and an arena Magic. The numbers are §3's band columns.
func test_the_seeded_outcomes_are_pinned() -> void:
	var cases: Array[Dictionary] = [
		{
			&"base": LASER,
			&"source": ModuleData.SOURCE_AUCTION,
			&"rarity": "common",
			&"prefixes": [],
			&"suffixes": [],
		},
		{
			&"base": TARGETING,
			&"source": ModuleData.SOURCE_DERELICT,
			&"rarity": "magic",
			&"prefixes": [{"id": "surefire", "value": 0.05}],
			&"suffixes": ["leeches"],
		},
		{
			&"base": EXCLUSIVE_VAULT,
			&"source": ModuleData.SOURCE_FACTION_LOT,
			&"rarity": "magic",
			&"prefixes": [{"id": "deep_hold", "value": 12.0}],
			&"suffixes": ["leeches"],
		},
		{
			&"base": PROTON,
			&"source": ModuleData.SOURCE_SHIPYARD,
			&"rarity": "magic",
			&"prefixes": [{"id": "rapid", "value": 0.16}],
			&"suffixes": ["choir"],
		},
		{
			&"base": FOLD,
			&"source": ModuleData.SOURCE_ARENA,
			&"rarity": "magic",
			&"prefixes": [{"id": "spry", "value": -0.25}],
			&"suffixes": ["silence"],
		},
	]
	for entry: Dictionary in cases:
		var profile = _fresh()
		seed(SEED)
		var id: StringName = profile.roll_instance(entry[&"base"], entry[&"source"])
		var record: Dictionary = profile.instance(id)
		var where := "%s from %s" % [entry[&"base"], entry[&"source"]]
		assert_eq(String(record[Profile.KEY_RARITY]), entry[&"rarity"], "%s: rarity" % where)
		assert_true(
			_deep_eq(record[Profile.KEY_PREFIXES], entry[&"prefixes"]),
			"%s: prefixes, expected %s, got %s" % [where, entry[&"prefixes"], record[Profile.KEY_PREFIXES]]
		)
		assert_true(
			_deep_eq(record[Profile.KEY_SUFFIXES], entry[&"suffixes"]),
			"%s: suffixes, expected %s, got %s" % [where, entry[&"suffixes"], record[Profile.KEY_SUFFIXES]]
		)


## 15 section 6's "never re-roll": the outcome is a stored value. The same seed produces
## the same affixes on two separate mints, a second read answers the same record, and the
## file holds it verbatim.
func test_a_roll_is_seeded_and_never_re_rolled() -> void:
	var profile = _fresh()
	seed(SEED)
	var first_id: StringName = profile.roll_instance(TARGETING, ModuleData.SOURCE_DERELICT)
	seed(SEED)
	var second_id: StringName = profile.roll_instance(TARGETING, ModuleData.SOURCE_DERELICT)
	assert_ne(first_id, second_id, "two mints, two ids")
	var first: Dictionary = profile.instance(first_id)
	var second: Dictionary = profile.instance(second_id)
	for key: String in [Profile.KEY_RARITY, Profile.KEY_PREFIXES, Profile.KEY_SUFFIXES]:
		assert_true(
			_deep_eq(first[key], second[key]),
			"the same seed rolls the same %s: %s vs %s" % [key, first[key], second[key]]
		)
	assert_true(_deep_eq(profile.instance(first_id), first), "a second read is the same record")
	profile.save()
	var reloaded = _fresh()
	reloaded.reload()
	assert_true(_deep_eq(reloaded.instance(first_id), first), "and the file holds it verbatim")
	assert_eq(
		reloaded.instances_of(TARGETING),
		[first_id, second_id],
		"both instances survive, in creation order"
	)


## ---------------------------------------------------------------------------
## The count: 1 in the bag, 0 fitted, never erased
## ---------------------------------------------------------------------------


func test_the_bag_and_fitted_count_round_trip() -> void:
	var profile = _fresh()
	var id: StringName = profile.add_instance(
		LIGHT_SHIELD, &"magic", [{"id": "sturdy", "value": 0.15}], ["whale"]
	)
	assert_true(profile.take_instance(id), "1 -> 0: the instance goes to a fit")
	assert_eq(profile.module_count(id), 0, "a fitted instance's count is 0")
	assert_true(profile.instances_of(LIGHT_SHIELD).is_empty(), "and it is out of the bag")
	var fitted: Dictionary = profile.instance(id)
	assert_eq(String(fitted[Profile.KEY_RARITY]), "magic", "but the record survives with its affixes")
	assert_true(
		_deep_eq(fitted[Profile.KEY_PREFIXES], [{"id": "sturdy", "value": 0.15}]),
		"prefix rows and all"
	)
	assert_false(profile.take_instance(id), "an instance already out of the bag cannot be taken again")
	assert_false(profile.sell_instance(id), "and a count-0 record is invisible to a sale")
	assert_eq(profile.credits(), Profile.DEFAULT_CREDITS, "which pays nothing")

	assert_true(profile.restore_instance(id), "0 -> 1: REMOVE hands the same instance back")
	assert_eq(profile.module_count(id), 1, "back in the bag")
	assert_eq(profile.instances_of(LIGHT_SHIELD), [id], "the same id, never a fresh mint")
	assert_eq(String(profile.instance(id)[Profile.KEY_RARITY]), "magic", "carrying the same affixes")
	assert_false(
		profile.restore_instance(id), "an instance already in the bag cannot be restored twice"
	)
	assert_eq(profile.modules().size(), 1, "one record throughout: fitting neither duplicates nor erases it")

	profile.save()
	var reloaded = _fresh()
	reloaded.reload()
	assert_eq(reloaded.module_count(id), 1, "the count round trips")
	assert_true(
		_deep_eq(reloaded.instance(id)[Profile.KEY_PREFIXES], [{"id": "sturdy", "value": 0.15}]),
		"and so do the affixes"
	)


## L80's round trip through the two composed fitting transactions: REMOVE and SWAP hand
## back the instance that was taken, never a base-keyed copy of it.
func test_remove_and_swap_hand_back_the_same_instance() -> void:
	var profile = _fresh()
	var mining: StringName = profile.add_instance(
		MINING, &"magic", [{"id": "keen", "value": 0.08}], ["ledger"]
	)
	var laser: StringName = profile.add_instance(LASER, &"common", [], [])
	assert_true(
		profile.fit_module_at(FIGHTER, &"weapons", 0, mining), "the instance fits a W cell"
	)
	assert_eq(
		String(profile.fit_for(FIGHTER)[&"weapons"][0]),
		String(mining),
		"the cell holds the instance id, not its base"
	)
	assert_eq(profile.module_count(mining), 0, "and the instance is out of the bag")
	assert_true(profile.instances_of(MINING).is_empty(), "so instances_of does not offer it")

	## SWAP: the displaced instance comes back, and it is the same one.
	assert_true(profile.fit_module_at(FIGHTER, &"weapons", 0, laser), "a swap installs the second")
	assert_eq(
		String(profile.fit_for(FIGHTER)[&"weapons"][0]), String(laser), "the cell holds the new one"
	)
	assert_eq(profile.module_count(mining), 1, "the displaced instance is back in the bag")
	var back: Dictionary = profile.instance(mining)
	assert_eq(String(back[Profile.KEY_RARITY]), "magic", "with its own rarity")
	assert_true(
		_deep_eq(back[Profile.KEY_PREFIXES], [{"id": "keen", "value": 0.08}]), "and its own prefix"
	)
	assert_true(_deep_eq(back[Profile.KEY_SUFFIXES], ["ledger"]), "and its own suffix")
	assert_eq(profile.instances_of(MINING), [mining], "one instance of the base: the original")

	## REMOVE: the same instance again, and the cell empties.
	assert_true(profile.clear_fit_slot(FIGHTER, &"weapons", 0), "REMOVE empties the cell")
	assert_eq(String(profile.fit_for(FIGHTER)[&"weapons"][0]), "", "the cell is empty")
	assert_eq(profile.module_count(laser), 1, "and the removed instance is back")
	assert_eq(profile.instances_of(LASER), [laser], "as itself, not as a fresh mint")
	assert_eq(profile.modules().size(), 2, "two records throughout: no duplicate was ever minted")


## 15 section 6's "two Light Shields can differ": same base, different rolls, both in the
## bag at once, and a fit holds one while the other stays available.
func test_two_instances_of_one_base_stay_distinguishable() -> void:
	var profile = _fresh()
	var magic: StringName = profile.add_instance(
		LIGHT_SHIELD, &"magic", [{"id": "sturdy", "value": 0.10}], ["whale"]
	)
	var rare: StringName = profile.add_instance(
		LIGHT_SHIELD,
		&"rare",
		[{"id": "sturdy", "value": 0.20}, {"id": "vigilant", "value": 0.35}],
		["whale", "ledger"]
	)
	assert_ne(magic, rare, "two mints of one base are two ids")
	assert_eq(profile.base_module_id(magic), LIGHT_SHIELD, "both resolve to the same base")
	assert_eq(profile.base_module_id(rare), LIGHT_SHIELD, "which is the catalogue's own id")
	assert_eq(profile.instances_of(LIGHT_SHIELD), [magic, rare], "the bag lists both, in mint order")
	assert_eq(profile.module_count(magic), 1, "each is one")
	assert_eq(profile.module_count(rare), 1, "and so is the other")
	assert_ne(
		String(profile.instance(magic)[Profile.KEY_RARITY]),
		String(profile.instance(rare)[Profile.KEY_RARITY]),
		"and the two differ, which is what the fitting panel must show"
	)
	assert_true(
		_deep_eq(profile.instance(magic)[Profile.KEY_PREFIXES], [{"id": "sturdy", "value": 0.10}]),
		"the Magic carries one prefix"
	)
	assert_true(
		_deep_eq(
			profile.instance(rare)[Profile.KEY_PREFIXES],
			[{"id": "sturdy", "value": 0.20}, {"id": "vigilant", "value": 0.35}]
		),
		"the Rare carries two"
	)

	assert_true(profile.fit_module_at(FIGHTER, &"shields", 0, rare), "the Rare fits the S cell")
	assert_eq(profile.instances_of(LIGHT_SHIELD), [magic], "the other stays in the bag")
	assert_eq(profile.module_count(rare), 0, "the fitted one is out of it")

	profile.save()
	var reloaded = _fresh()
	reloaded.reload()
	assert_eq(reloaded.instances_of(LIGHT_SHIELD), [magic], "the bag survives the save")
	assert_eq(reloaded.module_count(rare), 0, "and so does the fitted count")
	assert_eq(String(reloaded.instance(rare)[Profile.KEY_RARITY]), "rare", "each keeps its own rarity")
	assert_true(
		_deep_eq(
			reloaded.instance(rare)[Profile.KEY_PREFIXES],
			[{"id": "sturdy", "value": 0.20}, {"id": "vigilant", "value": 0.35}]
		),
		"and the Rare's own two prefixes"
	)
	assert_true(
		_deep_eq(reloaded.instance(magic)[Profile.KEY_PREFIXES], [{"id": "sturdy", "value": 0.10}]),
		"and the Magic's one"
	)


## ---------------------------------------------------------------------------
## The base-id translation (CONTRACTS section 15, K0 H6)
## ---------------------------------------------------------------------------


## A fit cell stores an instance id while `ShipFit` reads base ids, so the composed
## transactions judge their candidate through `base_fit`. Without that translation
## `fit_legal` scores an instance as draw 0 and two instances of one duplicate-guarded
## module look like two different modules.
func test_a_fit_is_judged_on_base_ids_not_instance_ids() -> void:
	var profile = _fresh()
	var plasma_a: StringName = profile.add_instance(PLASMA, &"common", [], [])
	var plasma_b: StringName = profile.add_instance(PLASMA, &"common", [], [])
	var shield: StringName = profile.add_instance(LIGHT_SHIELD, &"common", [], [])
	var fitted: Dictionary = {
		&"engines": [STANDARD_ENGINE],
		&"power": STANDARD_REACTOR,
		&"weapons": [plasma_a, plasma_b],
		&"shields": [shield],
	}
	var translated: Dictionary = profile.base_fit(fitted)
	## `_deep_eq` and not `==`: the translation builds plain arrays while the literals
	## below are typed ones, and two Arrays of different typing never compare equal.
	assert_true(
		_deep_eq(translated[&"weapons"], [PLASMA, PLASMA]),
		"an instance id translates to its base id: %s" % [translated[&"weapons"]]
	)
	assert_true(
		_deep_eq(translated[&"shields"], [LIGHT_SHIELD]), "in every cell of every list type"
	)
	assert_eq(
		String(translated[&"power"]), String(STANDARD_REACTOR), "and a base id passes through"
	)

	## Two plasma lances plus a light shield are more than the Lancer's power out, so
	## the fit is judged on the catalogue rows its cells actually name.
	var budget := FitData.power_budget(FIGHTER, translated)
	assert_eq(
		int(budget[&"out"]),
		int(FitData.HULLS[FIGHTER][&"power_out"])
		+ int(ModuleData.module(STANDARD_REACTOR)[&"effects"].get(&"power_add", 0.0)),
		"the outlet is 08 section 2's own plus the reactor's"
	)
	assert_eq(
		int(budget[&"draw"]),
		2 * int(ModuleData.module(PLASMA)[&"draw"])
		+ int(ModuleData.module(LIGHT_SHIELD)[&"draw"]),
		"and the draw is each cell's catalogue row: %s" % [budget]
	)
	assert_false(bool(budget[&"legal"]), "which over-budgets the hull")

	## The composed install judges through the translation, so the over-budget cell is
	## refused and the transaction writes nothing.
	assert_true(
		profile.set_fit(FIGHTER, {&"engines": [STANDARD_ENGINE], &"power": STANDARD_REACTOR}),
		"a bare launch fit"
	)
	assert_true(profile.fit_module_at(FIGHTER, &"shields", 0, shield), "the shield fits")
	assert_true(profile.fit_module_at(FIGHTER, &"weapons", 0, plasma_a), "and the first lance")
	assert_false(
		profile.fit_module_at(FIGHTER, &"weapons", 1, plasma_b),
		"the second lance is over the budget and is refused"
	)
	assert_eq(String(profile.fit_for(FIGHTER)[&"weapons"][1]), "", "the refused cell stayed empty")
	assert_eq(profile.module_count(plasma_b), 1, "and the refused instance stayed in the bag")

	## The duplicate guard (09 section 4 item 4) reads base ids too: two `e_ion` instances
	## in the Delver's two engine cells are one duplicate.
	var ion_a: StringName = profile.add_instance(ION, &"common", [], [])
	var ion_b: StringName = profile.add_instance(ION, &"common", [], [])
	assert_true(
		profile.set_fit(
			MINER, {&"engines": [STANDARD_ENGINE, STANDARD_ENGINE], &"power": STANDARD_REACTOR}
		),
		"the Delver's delivered fit"
	)
	assert_true(profile.fit_module_at(MINER, &"engines", 0, ion_a), "one instance fits")
	assert_eq(
		String(profile.fit_for(MINER)[&"engines"][0]),
		String(ion_a),
		"and the cell holds the instance id"
	)
	assert_false(
		profile.fit_module_at(MINER, &"engines", 1, ion_b),
		"the second is a duplicate of the first"
	)
	assert_eq(profile.module_count(ion_b), 1, "and it stayed in the bag")
	## The same translation is what makes the duplicate guard honest. The untranslated
	## judgement is deliberately not measured here: `fit_legal` on ids the catalogue does
	## not know pushes a `ShipFit: unknown module id` warning per cell and the gate's
	## warning ledger is part of CONTRACTS section 9, so this suite reads the judgement the
	## transaction itself composes.
	var unguarded: Dictionary = {&"engines": [ion_a, ion_b], &"power": STANDARD_REACTOR}
	assert_eq(
		FitData.fit_legal(MINER, profile.base_fit(unguarded))[&"duplicates"],
		[&"engines"],
		"09 section 4 item 4 reads the two cells' base ids and sees one duplicate"
	)


## ---------------------------------------------------------------------------
## The sell side (15 sections 1 and 6)
## ---------------------------------------------------------------------------


func test_sell_instance_pays_the_base_times_the_rarity_share() -> void:
	var profile = _fresh()
	var common: StringName = profile.add_instance(LASER, &"common", [], [])
	var rare: StringName = profile.add_instance(
		LASER, &"rare", [{"id": "keen", "value": 0.16}], ["ledger"]
	)
	var start: int = profile.credits()
	assert_true(profile.sell_instance(rare), "a Rare instance sells")
	var rare_price := ModuleData.sell_price(LASER, ModuleData.RARITY_RARE)
	assert_eq(
		profile.credits(),
		start + rare_price,
		"for base x rarity x 60 %%, measured %d" % rare_price
	)
	assert_true(profile.instance(rare).is_empty(), "and the record is erased")
	assert_true(profile.sell_instance(common), "the Common sells too")
	assert_eq(
		profile.credits(),
		start + rare_price + ModuleData.sell_price(LASER, ModuleData.RARITY_COMMON),
		"at its own multiplier"
	)
	assert_false(profile.sell_instance(rare), "an id the bag no longer holds cannot be sold twice")
	assert_false(profile.sell_instance(&"mod_9999"), "nor can an id that never existed")
	assert_eq(profile.credits(), start + rare_price + ModuleData.sell_price(LASER, ModuleData.RARITY_COMMON), "and neither refusal paid")

	## A base-keyed entry (the pre-v6 shape, what `add_module` still writes) sells one
	## unit at a time, at 15 section 1's Common multiplier.
	profile.add_module(LASER, 3)
	var before: int = profile.credits()
	assert_true(profile.sell_instance(LASER), "a stacked entry sells one unit")
	assert_eq(profile.module_count(LASER), 2, "leaving two")
	assert_eq(
		profile.credits(),
		before + ModuleData.sell_price(LASER, ModuleData.RARITY_COMMON),
		"for the Common price"
	)
	assert_eq(
		String(profile.instance(LASER)[Profile.KEY_RARITY]),
		ModuleData.RARITY_COMMON,
		"a base-keyed entry reads Common"
	)


## ---------------------------------------------------------------------------
## Helpers
## ---------------------------------------------------------------------------


func _fresh():
	var profile := Profile.new()
	profile.save_path = PROFILE_PATH
	_profiles.append(profile)
	return profile


func _delete_file(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


## The rarities a source's row allows, in 15 section 1's order: the columns the table
## gives a non-zero weight, which is the set an outcome may fall in.
func _legal_rarities(source: StringName) -> Array[String]:
	var legal: Array[String] = []
	var table: Dictionary = ModuleData.SOURCE_ROLLS.get(source, {})
	for rarity: String in ModuleData.RARITY_ORDER:
		if int(table.get(rarity, 0)) > 0:
			legal.append(rarity)
	return legal


## 15 sections 1/3/4/5: a record's affix count is its rarity's, capped at the pool it
## draws from; every prefix is a row of the module's own family carrying its tier's band
## value; every suffix comes from the faction pool the base opens; and no row repeats.
func _assert_affixes_are_legal(record: Dictionary, base: StringName, where: String) -> void:
	var rarity := StringName(record[Profile.KEY_RARITY])
	var wanted := ModuleData.affix_count(rarity)
	var pool := ModuleData.prefix_pool(base)
	var suffixes := ModuleData.suffix_pool(ModuleData.exclusive_faction(base))
	var prefix_rows: Array = record[Profile.KEY_PREFIXES]
	var suffix_ids: Array = record[Profile.KEY_SUFFIXES]
	assert_eq(
		prefix_rows.size(),
		mini(wanted, pool.size()),
		"%s: %d prefix row(s) for %s out of %d" % [where, wanted, rarity, pool.size()]
	)
	assert_eq(
		suffix_ids.size(),
		mini(wanted, suffixes.size()),
		"%s: %d suffix(es) for %s out of %d" % [where, wanted, rarity, suffixes.size()]
	)
	var tier := int(ModuleData.module(base).get(&"tier", 1))
	var seen_prefixes: Array = []
	for raw: Variant in prefix_rows:
		var row: Dictionary = raw
		var prefix := String(row.get("id", ""))
		assert_true(pool.has(prefix), "%s: %s is in %s's family pool" % [where, prefix, base])
		assert_eq(
			float(row.get("value", 0.0)),
			ModuleData.prefix_value(StringName(prefix), tier),
			"%s: %s carries its tier-%d band value" % [where, prefix, tier]
		)
		assert_false(seen_prefixes.has(prefix), "%s: %s rolls once" % [where, prefix])
		seen_prefixes.append(prefix)
	var seen_suffixes: Array = []
	for raw: Variant in suffix_ids:
		var suffix := str(raw)
		assert_true(suffixes.has(suffix), "%s: %s is in the suffix pool" % [where, suffix])
		assert_false(seen_suffixes.has(suffix), "%s: %s rolls once" % [where, suffix])
		seen_suffixes.append(suffix)


## Structural equality: `==` on nested dictionaries is not dependable across a
## ConfigFile round trip, where key order is not preserved.
func _deep_eq(a: Variant, b: Variant) -> bool:
	if a is Dictionary and b is Dictionary:
		var left: Dictionary = a
		var right: Dictionary = b
		if left.size() != right.size():
			return false
		for key: Variant in left.keys():
			if not right.has(key):
				return false
			if not _deep_eq(left[key], right[key]):
				return false
		return true
	if a is Array and b is Array:
		var left_array: Array = a
		var right_array: Array = b
		if left_array.size() != right_array.size():
			return false
		for index: int in range(left_array.size()):
			if not _deep_eq(left_array[index], right_array[index]):
				return false
		return true
	if (a is float) or (b is float):
		return is_equal_approx(float(a), float(b))
	return a == b
