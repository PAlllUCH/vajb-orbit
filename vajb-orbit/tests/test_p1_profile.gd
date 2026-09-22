@tool
extends McpTestSuite
## Suite p1_profile: save v2 (docs/gameplay/17_coder_handoff.md sections 3 and 6).
##
## Covers the fresh-instance defaults, the v1 -> v2 migration read, a full
## save/reload round trip for every persisted key, copy isolation, the signal
## contract, the pre-existing API and the P2-B1 module purchase
## (`buy_module`, CONTRACTS section 12).
##
## Save v5 (P2-B proper, CONTRACTS section 13) retires the pre-module `upgrades`
## key, so nothing here reads or writes it any more: the v1 fixture below carries
## none, the defaults no longer name it, and the migration itself - and the flag
## day's write - has its own suite, `test_p2b_retirement.gd`.
##
## Save v6 (S3, CONTRACTS section 15) turns `modules` into the `instance_id ->
## record` dictionary of 15 section 6/8's instances, so the round trip below writes
## one canonical six-key record; the migration has its own suite,
## `test_s3_migration.gd`.
##
## Profiles are throwaway instances of the autoload script whose save_path is
## repointed at a scratch file before the first mutation; `user://profile.cfg`
## is never touched. Note that these instances are never added to the tree, so
## the debounced save Timer does not exist and every mutation writes through
## immediately, which is what makes the round-trip assertions exact.

const Profile := preload("res://autoload/player_profile.gd")
const Log := preload("res://game/economy_log.gd")
const Clock := preload("res://autoload/world_clock.gd")
const Exch := preload("res://game/exchange.gd")
const ModuleData := preload("res://game/module_catalog.gd")

const PROFILE_PATH := "user://test_p1_profile.cfg"
const LOG_PATH := "user://test_p1_log.txt"
const SECTION := "profile"
const NOW := 1000000

var _profiles: Array[Node] = []
var _signals: Array[StringName] = []
var _failures: Array[Dictionary] = []


func suite_name() -> String:
	return "p1_profile"


func setup() -> void:
	_delete_file(PROFILE_PATH)
	_reset_log()
	_signals.clear()
	_failures.clear()


func teardown() -> void:
	for profile: Node in _profiles:
		if is_instance_valid(profile):
			profile.free()
	_profiles.clear()
	_signals.clear()
	_failures.clear()


func suite_teardown() -> void:
	_delete_file(PROFILE_PATH)
	_delete_file(LOG_PATH)
	Log.log_path = Log.DEFAULT_PATH
	Clock.clear_override()


## ---------------------------------------------------------------------------
## Defaults and migration
## ---------------------------------------------------------------------------


func test_fresh_defaults_without_a_file() -> void:
	_delete_file(PROFILE_PATH)
	var profile = _fresh()
	## The compile-time field defaults of an uninitialised instance are not the contract:
	## the first-run branch of `_load_profile()` (`ERR_FILE_NOT_FOUND` -> `_apply_defaults`)
	## is, so the file is looked for first.
	profile.reload()
	assert_eq(profile.credits(), 10000)
	assert_false(
		FileAccess.file_exists(PROFILE_PATH), "a fresh instance writes nothing until it mutates"
	)
	## STATION_SPEC section 2.8.
	var ships: Array[StringName] = profile.owned_ships()
	assert_eq(ships.size(), 1, "one ship owned by default")
	assert_eq(ships[0], &"ship_vanguard", "owned ships default to [ship_vanguard]")
	assert_eq(profile.active_ship(), &"ship_vanguard", "active ship default")
	assert_true(profile.cargo_items().is_empty(), "cargo defaults to empty")
	assert_eq(Profile.AMMO_MAX.size(), 5, "the five weapons of section 2.8")
	for weapon: StringName in Profile.AMMO_MAX:
		assert_eq(profile.ammo_of(weapon), 300, "%s ammo default" % String(weapon))
	## The P1 keys.
	var market: Dictionary = profile.market()
	for key: String in Profile.MARKET_KEYS:
		assert_has_key(market, key, "market is missing its %s bucket" % key)
		assert_true(market[key] is Dictionary, "market.%s must be a dictionary" % key)
	assert_eq(int(market["last_band"]), 0)
	assert_true(profile.vitals_of(&"ship_vanguard").is_empty(), "vitals start empty")
	assert_true(profile.modules().is_empty())
	assert_true(profile.fits().is_empty())
	assert_true(profile.heat().is_empty())
	assert_true(profile.standing().is_empty())
	assert_true(profile.contracts().is_empty())
	assert_true(profile.vaults().is_empty())
	assert_false(profile.insured())
	assert_false(profile.mercy_used())


func test_v1_profile_migrates_to_defaults() -> void:
	var fixture := ConfigFile.new()
	fixture.set_value(SECTION, "save_version", 1)
	fixture.set_value(SECTION, "credits", 1234)
	fixture.set_value(SECTION, "owned_ships", ["ship_fighter", "ship_vanguard"])
	fixture.set_value(SECTION, "active_ship", "ship_fighter")
	fixture.set_value(SECTION, "cargo", {"mineral_iron": 7})
	fixture.set_value(SECTION, "ammo", {"laser": 120})
	assert_eq(fixture.save(PROFILE_PATH), OK, "fixture written")

	var profile = _fresh()
	profile.reload()

	# Old values preserved.
	assert_eq(profile.credits(), 1234)
	var ships = profile.owned_ships()
	assert_eq(ships.size(), 2)
	assert_true(ships.has(&"ship_fighter"))
	assert_true(ships.has(&"ship_vanguard"))
	assert_eq(profile.active_ship(), &"ship_fighter")
	assert_eq(profile.cargo_qty(&"mineral_iron"), 7)
	assert_eq(profile.ammo_of(&"laser"), 120)
	assert_eq(profile.ammo_of(&"cannon"), 300, "weapons the v1 file never wrote keep the default")

	# Every new key is at its default.
	assert_true(profile.modules().is_empty(), "modules default")
	assert_true(profile.fits().is_empty(), "fits default")
	assert_true(profile.heat().is_empty(), "heat default")
	assert_true(profile.standing().is_empty(), "standing default")
	assert_true(profile.contracts().is_empty(), "contracts default")
	assert_true(profile.vaults().is_empty(), "vaults default")
	assert_false(profile.insured(), "insured default")
	assert_false(profile.mercy_used(), "mercy_used default")
	assert_true(profile.vitals_of(&"ship_vanguard").is_empty(), "vitals default")
	var market: Dictionary = profile.market()
	for key: String in Profile.MARKET_KEYS:
		assert_true(market[key] is Dictionary, "market.%s default" % key)
		assert_true((market[key] as Dictionary).is_empty(), "market.%s default" % key)
	assert_eq(int(market["last_band"]), 0)

	# The migration read never rewrites the file. A file that *does* carry the key
	# save v5 retired is the one exception, and `test_p2b_retirement.gd` measures
	# that one; this fixture has nothing to migrate.
	var on_disk := ConfigFile.new()
	assert_eq(on_disk.load(PROFILE_PATH), OK)
	assert_eq(int(on_disk.get_value(SECTION, "save_version", 0)), 1, "still a v1 file on disk")


func test_v2_round_trip_for_every_key() -> void:
	var first = _fresh()
	## Save v6's instance record (15 section 6/8, CONTRACTS section 15): the six keys
	## `{instance_id, base_id, rarity, prefixes[], suffixes[], count}`, the affixes in
	## the shape a record stores them (`{id, value}` per prefix, one id per suffix),
	## and `count` 3 -- the stacked stock a v5 file migrates into three instances.
	first.set_modules(
		{
			"mod_0001":
			{
				"instance_id": "mod_0001",
				"base_id": "s_light",
				"rarity": "rare",
				"prefixes": [{"id": "sturdy", "value": 0.2}, {"id": "vigilant", "value": 0.35}],
				"suffixes": ["whale", "ledger"],
				"count": 3,
			},
		}
	)
	first.set_fits({"ship_vanguard": {"module": "mod_0001", "extra": ""}})
	first.set_market(
		{
			"demand": {"iron": 1.25},
			"stock": {"comp_scrap_1": 33},
			"queue": {"comp_scrap_1": 7},
			"trend": {"iron": 1},
			"last_band": 5000,
		}
	)
	first.set_heat({"faction_red": 12, "faction_blue": -3})
	first.set_standing({"faction_red": 25})
	first.set_contracts([{"id": "c1", "tier": 2}, {"id": "c2", "tier": 3}])
	first.set_vaults({"station_alpha": {"tier": 2, "contents": {"mineral_iron": 5}}})
	first.set_insured(true)
	first.set_mercy_used(true)
	first.set_vitals(&"ship_vanguard", 812, 455)
	first.set_vitals(&"ship_fighter", 700, 400)
	first.save()

	var second = _fresh()
	second.reload()

	assert_true(_deep_eq(second.modules(), first.modules()), "modules round trip")
	assert_true(_deep_eq(second.fits(), first.fits()), "fits round trip")
	assert_true(_deep_eq(second.market(), first.market()), "market round trip")
	assert_true(_deep_eq(second.heat(), first.heat()), "heat round trip")
	assert_true(_deep_eq(second.standing(), first.standing()), "standing round trip")
	assert_true(_deep_eq(second.contracts(), first.contracts()), "contracts round trip")
	assert_true(_deep_eq(second.vaults(), first.vaults()), "vaults round trip")
	assert_eq(second.insured(), true)
	assert_eq(second.mercy_used(), true)
	assert_true(
		_deep_eq(second.vitals_of(&"ship_vanguard"), {"hull": 812, "shield": 455}),
		"vitals round trip"
	)
	assert_true(
		_deep_eq(second.vitals_of(&"ship_fighter"), {"hull": 700, "shield": 400}),
		"vitals round trip, second hull"
	)
	assert_eq(second.credits(), 10000, "untouched credits survive the round trip")
	assert_eq(Exch.demand_of(second, &"mineral_iron"), 1.25, "the market is live after reload")

	var on_disk := ConfigFile.new()
	assert_eq(on_disk.load(PROFILE_PATH), OK)
	assert_eq(
		int(on_disk.get_value(SECTION, "save_version", 0)),
		6,
		"writes always persist save v6 (S3, CONTRACTS section 15)"
	)


## ---------------------------------------------------------------------------
## Copy isolation and signals
## ---------------------------------------------------------------------------


func test_getter_copies_cannot_mutate_state() -> void:
	var profile = _fresh()
	profile.set_modules({"mod_0001": {"count": 1}})
	var modules: Dictionary = profile.modules()
	modules["mod_0002"] = {"count": 9}
	var inner: Dictionary = modules["mod_0001"]
	inner["count"] = 99
	assert_true(profile.modules().has("mod_0001"))
	assert_false(profile.modules().has("mod_0002"), "a returned copy cannot add keys")
	var stored: Dictionary = profile.modules()["mod_0001"]
	assert_eq(int(stored["count"]), 1, "nested copies are deep")

	profile.set_market({"demand": {"iron": 1.25}})
	var market: Dictionary = profile.market()
	var demand: Dictionary = market["demand"]
	demand["iron"] = 9.0
	assert_eq(Exch.demand_of(profile, &"mineral_iron"), 1.25, "market copy is deep")

	profile.add_cargo(&"mineral_iron", 4)
	var cargo: Dictionary = profile.cargo_items()
	cargo["mineral_iron"] = 999
	assert_eq(profile.cargo_qty(&"mineral_iron"), 4, "cargo copy is deep")

	profile.set_vitals(&"ship_vanguard", 500, 300)
	var vitals: Dictionary = profile.vitals_of(&"ship_vanguard")
	vitals["hull"] = 1
	var stored_vitals: Dictionary = profile.vitals_of(&"ship_vanguard")
	assert_eq(int(stored_vitals["hull"]), 500, "vitals copy is deep")

	var ships = profile.owned_ships()
	ships.append(&"ship_destroyer")
	assert_false(profile.owns_ship(&"ship_destroyer"), "owned ships copy is deep")


func test_equal_sets_are_silent() -> void:
	var profile = _fresh()
	profile.set_modules({"mod_0001": {"count": 1}})
	profile.set_insured(true)
	profile.set_vitals(&"ship_vanguard", 500, 300)
	profile.set_market({"demand": {"iron": 1.25}, "last_band": 42})
	_watch(profile)

	profile.set_modules({"mod_0001": {"count": 1}})
	profile.set_insured(true)
	profile.set_vitals(&"ship_vanguard", 500, 300)
	profile.set_market({"demand": {"iron": 1.25}, "last_band": 42})
	profile.set_fits({})
	profile.set_contracts([])
	profile.set_heat({})

	assert_true(_signals.is_empty(), "an idempotent set writes nothing: %s" % str(_signals))


func test_signal_keys_for_emitting_setters() -> void:
	var profile = _fresh()
	_watch(profile)

	profile.set_modules({"mod_0001": {"count": 1}})
	assert_eq(_signals.size(), 1, "set_modules emits once")
	assert_eq(_signals[0], &"modules")

	_signals.clear()
	profile.set_fits({"ship_vanguard": {"module": "mod_0001"}})
	assert_eq(_signals.size(), 1, "set_fits emits once")
	assert_eq(_signals[0], &"fits")

	_signals.clear()
	profile.set_standing({"faction_red": 25})
	assert_eq(_signals.size(), 1, "set_standing emits once")
	assert_eq(_signals[0], &"standing")


func test_silent_setters_emit_nothing() -> void:
	var profile = _fresh()
	_watch(profile)
	profile.set_market({"demand": {"iron": 1.25}})
	profile.set_heat({"faction_red": 1})
	profile.set_contracts([{"id": "c1"}])
	profile.set_vaults({"station_alpha": {"tier": 1}})
	profile.set_insured(true)
	profile.set_mercy_used(true)
	profile.set_vitals(&"ship_vanguard", 10, 20)
	assert_true(_signals.is_empty(), "silent setters stay silent: %s" % str(_signals))
	# ... but they do mutate.
	assert_eq(Exch.demand_of(profile, &"mineral_iron"), 1.25)
	assert_true(profile.insured())
	assert_true(profile.mercy_used())
	var vitals: Dictionary = profile.vitals_of(&"ship_vanguard")
	assert_eq(int(vitals["hull"]), 10)


## ---------------------------------------------------------------------------
## Existing API
## ---------------------------------------------------------------------------


func test_existing_api_emits_its_keys() -> void:
	var profile = _fresh()
	_watch(profile)

	profile.add_credits(50)
	assert_eq(_signals.size(), 1, "add_credits emits once")
	assert_eq(_signals[0], &"credits")
	assert_eq(profile.credits(), 10050)

	_signals.clear()
	assert_true(profile.spend(10))
	assert_eq(_signals.size(), 1, "spend emits once")
	assert_eq(_signals[0], &"credits")
	assert_eq(profile.credits(), 10040)

	_signals.clear()
	profile.add_cargo(&"mineral_iron", 3)
	assert_eq(_signals.size(), 1, "add_cargo emits once")
	assert_eq(_signals[0], &"cargo")

	_signals.clear()
	assert_true(profile.remove_cargo(&"mineral_iron", 3))
	assert_eq(_signals.size(), 1, "remove_cargo emits once")
	assert_eq(_signals[0], &"cargo")
	assert_eq(profile.cargo_qty(&"mineral_iron"), 0)


func test_spend_over_balance_refuses() -> void:
	var profile = _fresh()
	_watch(profile)
	assert_false(profile.spend(999999), "spend refuses more than the balance")
	assert_eq(profile.credits(), 10000, "the balance is untouched")
	assert_true(_signals.is_empty(), "a refused spend emits nothing")
	assert_false(profile.remove_cargo(&"mineral_iron", 1), "removing cargo you do not hold fails")
	assert_true(_signals.is_empty(), "a refused cargo removal emits nothing")


## ---------------------------------------------------------------------------
## P2-B1 module purchase (CONTRACTS section 12)
## ---------------------------------------------------------------------------


func test_buy_module_round_trips() -> void:
	var profile = _fresh()
	_watch(profile)
	_watch_purchases(profile)
	## The price under test is the catalogue's own 09 section 3.1 row; the profile
	## charges what the caller passes.
	var cost := int(ModuleData.module(&"w_cannon")[&"cost"])
	assert_eq(cost, 1200, "09 section 3.1's w_cannon price")
	assert_eq(profile.module_count(&"w_cannon"), 0, "nothing owned yet")

	assert_true(profile.buy_module(&"w_cannon", cost))
	assert_eq(profile.credits(), 10000 - cost, "exactly the price is spent")
	assert_eq(profile.module_count(&"w_cannon"), 1, "one module in the inventory")
	assert_true(_failures.is_empty(), "a successful buy refuses nothing")
	assert_eq(_signals.size(), 2, "the charge and the inventory both moved: %s" % str(_signals))
	assert_eq(_signals[0], &"credits")
	assert_eq(_signals[1], &"modules")

	var lines := _log_lines()
	assert_eq(lines.size(), 1, "exactly one economy-log line")
	var fields := lines[0].split(", ")
	assert_eq(fields.size(), 6, "the log's six fields")
	assert_eq(fields[1], Profile.EVENT_BUY_MODULE)
	assert_eq(fields[2], "w_cannon")
	assert_eq(fields[3], "1", "one module")
	assert_eq(fields[4], "-1200")
	assert_eq(fields[5], "8800", "the balance after the purchase")

	## A second purchase writes exactly one line of its own and stacks the count.
	assert_true(profile.buy_module(&"w_cannon", cost))
	assert_eq(profile.module_count(&"w_cannon"), 2, "the count stacks")
	assert_eq(profile.credits(), 10000 - 2 * cost)
	assert_eq(_log_lines().size(), 2, "one line per purchase, never two")

	## The purchase survives a reload: inventory and balance both round-trip.
	profile.reload()
	assert_eq(profile.credits(), 10000 - 2 * cost, "credits round-trip")
	assert_eq(profile.module_count(&"w_cannon"), 2, "the inventory round-trips")


func test_buy_module_refuses_unknown_and_insufficient() -> void:
	var profile = _fresh()
	_watch(profile)
	_watch_purchases(profile)

	## An id the catalogue does not ship is never sold.
	assert_false(profile.buy_module(&"w_do_not_exist", 100))
	assert_eq(_failures.size(), 1, "one refusal")
	assert_eq(_failures[0][&"reason"], Profile.REASON_UNKNOWN)
	assert_eq(_failures[0][&"id"], &"w_do_not_exist")
	assert_eq(profile.module_count(&"w_do_not_exist"), 0, "no inventory write")
	assert_eq(profile.credits(), 10000, "no charge")
	assert_true(_signals.is_empty(), "a refused buy emits nothing: %s" % str(_signals))
	assert_eq(_log_lines().size(), 0, "a refused buy logs nothing")

	## A negative price is not a price, exactly as buy_ship refuses one.
	_failures.clear()
	assert_false(profile.buy_module(&"w_cannon", -1))
	assert_eq(_failures.size(), 1, "one refusal")
	assert_eq(_failures[0][&"reason"], Profile.REASON_UNKNOWN)
	assert_eq(_failures[0][&"id"], &"w_cannon")
	assert_eq(profile.credits(), 10000, "no charge")
	assert_true(_signals.is_empty(), "a refused buy emits nothing: %s" % str(_signals))

	## A real module the balance cannot cover: the railgun is 5 200 CR and the
	## balance is spent down to 500.
	var railgun := int(ModuleData.module(&"w_railgun")[&"cost"])
	assert_eq(railgun, 5200, "09 section 3.1's w_railgun price")
	_failures.clear()
	assert_true(profile.spend(9500))
	_signals.clear()
	assert_eq(profile.credits(), 500)
	assert_false(profile.buy_module(&"w_railgun", railgun))
	assert_eq(_failures.size(), 1, "one refusal")
	assert_eq(_failures[0][&"reason"], Profile.REASON_INSUFFICIENT)
	assert_eq(_failures[0][&"id"], &"w_railgun")
	assert_eq(profile.credits(), 500, "the short balance is untouched")
	assert_eq(profile.module_count(&"w_railgun"), 0, "nothing is given")
	assert_true(_signals.is_empty(), "a refused buy emits nothing: %s" % str(_signals))
	assert_eq(_log_lines().size(), 0, "a refused buy logs nothing")


## ---------------------------------------------------------------------------
## Helpers
## ---------------------------------------------------------------------------


func _fresh():
	var profile := Profile.new()
	profile.save_path = PROFILE_PATH
	_profiles.append(profile)
	return profile


func _watch(profile: Node) -> void:
	_signals.clear()
	profile.profile_changed.connect(_on_profile_changed)


func _on_profile_changed(key: StringName) -> void:
	_signals.append(key)


## Capture the refusal vocabulary (`purchase_failed`) of the transaction
## functions, one entry per refusal: `{reason, id}`.
func _watch_purchases(profile: Node) -> void:
	_failures.clear()
	profile.purchase_failed.connect(_on_purchase_failed)


func _on_purchase_failed(reason: StringName, id: StringName) -> void:
	_failures.append({"reason": reason, "id": id})


## The lines of the scratch economy log, blank ones dropped.
func _log_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	var file := FileAccess.open(LOG_PATH, FileAccess.READ)
	if file == null:
		return lines
	var text := file.get_as_text()
	file.close()
	for line: String in text.split("\n"):
		if not line.strip_edges().is_empty():
			lines.append(line)
	return lines


func _delete_file(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


func _reset_log() -> void:
	Log.log_path = LOG_PATH
	var file := FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if file != null:
		file.close()


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
