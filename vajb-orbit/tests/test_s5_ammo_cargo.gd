@tool
extends McpTestSuite
## Suite s5_ammo_cargo: ammunition as a cargo item (wave S5, AC4).
##
## The law is 10 section 6.1's 2026-09-23 amendment and CONTRACTS section 17, read with the
## J0 owner rulings the brief carries (the railgun's own pack, the `ammo_*` prefix mapping,
## the rows staying in ARMORY, the fuel-cell delist being already the tree's state).
##
##  - **AC4a** -- the six cargo items `ammo_laser` `ammo_cannon` `ammo_rocket` `ammo_mine`
##    `ammo_plasma` `ammo_railgun`, counted in units of `ROUNDS_PER_CARGO_UNIT` (10) rounds;
##    a purchase delivers `rounds / 10` **units to the hold** and writes no pack, and a
##    refused purchase writes nothing at all.
##  - **AC4b** -- the launch auto-load: each fitted weapon's pack fills from the hold's
##    units of its family up to its `ammo_max`, **once per family per launch** (a Lancer's
##    twin lasers draw one laser pack), the drawn units leave the hold, and nothing in
##    flight draws a round out of cargo (a pack that empties in flight stays empty).
##  - **AC4c** -- EXCHANGE buys a unit at 60 % of its per-unit list (laser 2, cannon 4,
##    rocket 24, mine 30, plasma 38, railgun 14 CR), the sale moves cargo and credits and no
##    market state, and the hold surface draws the ammo rows beside the minerals.
##  - **AC4d** -- no sale surface carries a `fuel_cell` row (measured: none does), while an
##    existing stack still burns on `R`; the countermeasure packs are staged out, measured
##    as the six families and nothing more.
##
## The profile is the shipped autoload, borrowed the way `test_p2a_launch_fit.gd` and
## `test_s4_batteries.gd` borrow it: `save_path` is repointed at a scratch file before the
## first mutation, every field this suite can write is seeded, handed back in
## `suite_teardown` and flushed while the scratch path is still in place, so the owner's
## `user://profile.cfg` is never written (probe hygiene L17, the S3 incident's cure, T-93).
## The flight scene and the exchange pane are the shipped ones, so what is measured is the
## tree's own behaviour rather than a re-implementation of it.

const GameScene := preload("res://game/game.tscn")
const PanelScene := preload("res://ui/station/exchange_panel.tscn")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const Catalog := preload("res://game/station_catalog.gd")
const ExchangeScript := preload("res://game/exchange.gd")
const ModuleData := preload("res://game/module_catalog.gd")
const MineralData := preload("res://game/mineral_catalog.gd")
const ComponentData := preload("res://game/component_catalog.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const ProfileData := preload("res://autoload/player_profile.gd")
const Clock := preload("res://autoload/world_clock.gd")

const SCRATCH_PROFILE := "user://test_s5_ammo_cargo.cfg"
const PROFILE_SERVICE: StringName = &"PlayerProfile"

const VANGUARD: StringName = &"ship_vanguard"
const LANCER: StringName = &"ship_fighter"
const ENGINE: StringName = &"e_std"
const REACTOR: StringName = &"p_std"

const START_CREDITS := 10000

## CONTRACTS section 17's own worked numbers: the six families, the per-unit list each one's
## pack derives (`roundi(10 * cost / rounds)`) and the sale price the station pays
## (`roundi(0.6 * list)`). The pin states all twelve figures; they are quoted here so the
## suite measures the tree against the pin rather than against itself.
const AMMO_UNITS: Dictionary = {
	&"laser": {&"list": 4, &"sale": 2},
	&"cannon": {&"list": 6, &"sale": 4},
	&"rocket": {&"list": 40, &"sale": 24},
	&"mine": {&"list": 50, &"sale": 30},
	&"plasma": {&"list": 64, &"sale": 38},
	&"railgun": {&"list": 24, &"sale": 14},
}

var _profile: Node = null
var _scene: Node2D = null
var _host: Control = null
var _panel: Control = null
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_credits := 0
var _previous_cargo: Dictionary = {}
var _previous_ammo: Dictionary = {}
var _previous_fits: Dictionary = {}
var _previous_owned: Array = []
var _previous_modules: Dictionary = {}
var _previous_market: Dictionary = {}


func suite_name() -> String:
	return "s5_ammo_cargo"


func suite_setup(_ctx: Dictionary) -> void:
	_profile = _fixture_host()
	if _profile == null:
		fail_setup("the PlayerProfile autoload is the cargo owner this suite measures")
		return
	_previous_path = String(_profile.get(&"save_path"))
	_previous_ship = StringName(_profile.call(&"active_ship"))
	_previous_credits = int(_profile.call(&"credits"))
	_previous_cargo = (_profile.get(&"_cargo") as Dictionary).duplicate(true)
	_previous_ammo = (_profile.get(&"_ammo") as Dictionary).duplicate(true)
	_previous_fits = _profile.call(&"fits")
	_previous_owned = _profile.call(&"owned_ships")
	_previous_modules = _profile.call(&"modules")
	_previous_market = (_profile.get(&"_market") as Dictionary).duplicate(true)
	_profile.set(&"save_path", SCRATCH_PROFILE)
	_delete_file(SCRATCH_PROFILE)


func suite_teardown() -> void:
	_free_scene()
	_free_host()
	if _profile == null:
		return
	## Hand every borrowed field back, flush on the scratch path and only then restore the
	## real one, so no dirty flag and no running timer carries a test's account home. The
	## market is handed back too: mounting the pane evaluates it, and a mutating reading must
	## not leak into the next suite.
	_profile.set(&"_credits", _previous_credits)
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_cargo", _previous_cargo)
	_profile.set(&"_ammo", _previous_ammo)
	_profile.set(&"_fits", _previous_fits)
	_profile.set(&"_owned_ships", _previous_owned)
	_profile.set(&"_modules", _previous_modules)
	_profile.set(&"_market", _previous_market)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	_delete_file(SCRATCH_PROFILE)
	_profile = null


func setup() -> void:
	_free_scene()
	_free_host()
	_seed_account()


func teardown() -> void:
	_free_scene()


## The fixture account every test starts from: the Vanguard active and owned, no fit, no
## modules, an empty hold, the shipped 10 000 CR, and the packs at `DEFAULT_AMMO` -- written
## through the private fields the other profile suites hand back, so no purchase is charged
## and no signal fires before the scene is instantiated.
func _seed_account() -> void:
	var owned: Array[StringName] = [VANGUARD]
	var packs: Dictionary = {}
	for family: StringName in Catalog.ammo_ids():
		packs[family] = ProfileData.DEFAULT_AMMO
	_profile.set(&"_credits", START_CREDITS)
	_profile.set(&"_active_ship", VANGUARD)
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_cargo", {})
	_profile.set(&"_ammo", packs)


# --------------------------------------------------------------- AC4a: the six cargo items


## CONTRACTS section 17 / 10 section 6.1: one cargo item per family, counted in
## `ROUNDS_PER_CARGO_UNIT` rounds, with the `ammo_` prefix the one mapping. The six ids are
## the pinned namespace, and the pack set is exactly six -- which is also the "countermeasure
## packs are staged out" reading: nothing flare- or chaff-shaped ships as a seventh pack.
func test_the_six_ammo_items_are_a_ten_round_cargo_unit() -> void:
	assert_eq(Catalog.ROUNDS_PER_CARGO_UNIT, 10, "the pinned granularity")
	assert_eq(Catalog.AMMO_PREFIX, "ammo_", "and the pinned cargo namespace")
	var expected: Array[StringName] = [
		&"ammo_laser",
		&"ammo_cannon",
		&"ammo_rocket",
		&"ammo_mine",
		&"ammo_plasma",
		&"ammo_railgun",
	]
	assert_eq(Catalog.ammo_item_ids(), expected, "the six pinned cargo ids, in pack order")
	assert_eq(Catalog.ammo_ids().size(), 6, "six families, no seventh pack")
	for item_id: StringName in expected:
		assert_true(ExchangeScript.is_ammo(item_id), "%s is an ammo cargo id" % String(item_id))
		assert_true(ExchangeScript.is_sellable(item_id), "and the exchange buys it")
		var family: StringName = Catalog.ammo_family(item_id)
		assert_ne(family, &"", "%s resolves to a family" % String(item_id))
		assert_eq(Catalog.ammo_item_id(family), item_id, "and back to the same cargo id")
		assert_false(
			String(family).contains("flare") or String(family).contains("chaff"),
			"%s is not a countermeasure pack" % String(item_id)
		)
	var laser: Dictionary = Catalog.ammo_pack(&"laser")
	assert_eq(int(laser.get(&"rounds", 0)), 300, "the laser pack's rounds")
	assert_eq(Catalog.ammo_pack_units(&"laser"), 30, "which is 30 cargo units")
	assert_eq(Catalog.ammo_unit_cost(&"ammo_laser"), 4, "and a 4 CR per-unit list")
	## Ids the mapping refuses: a bare family, an unknown cargo id, and the fuel cell's
	## un-prefixed id (10 section 6.1's carve-out).
	assert_eq(Catalog.ammo_family(&"laser"), &"", "a bare family is not a cargo id")
	assert_eq(Catalog.ammo_family(&"ammo_bogus"), &"", "nor is an unknown one")
	assert_eq(Catalog.ammo_family(&"fuel_cell"), &"", "and the fuel cell is not an ammo item")
	assert_eq(Catalog.ammo_item_id(&""), &"", "the empty family derives no id")


## The J0 owner ruling (2026-09-23): the railgun ships its own pack -- rounds 150, cost 360,
## profile `ammo_max` 150 -- with the module's own glyph, and it shares neither the cannon's
## rounds nor its family.
func test_the_railgun_pack_carries_its_own_numbers() -> void:
	var pack := Catalog.ammo_pack(&"railgun")
	assert_false(pack.is_empty(), "the railgun pack ships")
	assert_eq(int(pack.get(&"rounds", 0)), 150, "rounds 150")
	assert_eq(int(pack.get(&"cost", 0)), 360, "cost 360 (twice the cannon's)")
	assert_eq(
		int(_profile.call(&"ammo_max", &"railgun")), 150, "and a 150-round profile ceiling"
	)
	assert_eq(int(Catalog.ammo_pack(&"cannon").get(&"rounds", 0)), 300, "the cannon keeps 300")
	assert_eq(int(_profile.call(&"ammo_max", &"cannon")), 300, "and its 300 ceiling")
	assert_eq(
		String(pack.get(&"icon", "")),
		"res://assets/icons/module/icon_module_w_railgun.svg",
		"the module's own glyph, as pinned"
	)
	assert_eq(Catalog.ammo_pack_units(&"railgun"), 15, "150 rounds is 15 cargo units")
	assert_eq(Catalog.ammo_unit_cost(&"ammo_railgun"), 24, "a 24 CR per-unit list")


## CONTRACTS section 17: "the ammo rows deliver to cargo (units = rounds / 10)". One buy per
## family: the hold gains the pack's own units, the credits pay the pack's own price, and the
## pack store is not touched at all -- ammo is bought into the hold, never into a magazine.
func test_buying_ammo_delivers_cargo_units_not_packs() -> void:
	for family: StringName in Catalog.ammo_ids():
		var pack := Catalog.ammo_pack(family)
		var rounds := int(pack.get(&"rounds", 0))
		var cost := int(pack.get(&"cost", 0))
		var units := rounds / Catalog.ROUNDS_PER_CARGO_UNIT
		var before_credits := int(_profile.call(&"credits"))
		var before_pack := int(_profile.call(&"ammo_of", family))
		assert_eq(before_pack, ProfileData.DEFAULT_AMMO, "%s starts at the default" % family)
		assert_true(
			bool(_profile.call(&"buy_ammo", family, rounds, cost)), "%s buys" % String(family)
		)
		assert_eq(
			int(_profile.call(&"credits")),
			before_credits - cost,
			"%s charged the catalogue's own price" % String(family)
		)
		assert_eq(
			int(_profile.call(&"ammo_units", family)),
			units,
			"%s delivered %d cargo units" % [String(family), units]
		)
		assert_eq(
			int(_profile.call(&"cargo_qty", Catalog.ammo_item_id(family))),
			units,
			"%s's hold is keyed by the ammo_* cargo id" % String(family)
		)
		assert_eq(
			int(_profile.call(&"ammo_of", family)),
			before_pack,
			"%s's pack store did not move" % String(family)
		)
	## Two buys stack, and a second family is untouched by the first.
	assert_true(bool(_profile.call(&"buy_ammo", &"laser", 300, 120)), "a second laser pack")
	assert_eq(int(_profile.call(&"ammo_units", &"laser")), 60, "the two packs' units add up")
	assert_eq(int(_profile.call(&"ammo_units", &"cannon")), 30, "the cannon holds its own")
	## Rounding: the unit is indivisible, so a 5-round buy is a whole unit -- the loop's
	## four mine units become five -- and a zero-round buy is not a purchase at all.
	assert_true(bool(_profile.call(&"buy_ammo", &"mine", 5, 25)), "a 5-round (half unit) buy")
	assert_eq(
		int(_profile.call(&"ammo_units", &"mine")),
		5,
		"which adds one whole unit to the pack's four"
	)
	assert_false(bool(_profile.call(&"buy_ammo", &"mine", 0, 25)), "a zero-round buy is no buy")


## 17 section 5's transaction law: an unaffordable buy and an id outside the six write
## nothing (no credits, no cargo, no pack) and answer false.
func test_a_refused_purchase_writes_nothing() -> void:
	assert_true(bool(_profile.call(&"spend", int(_profile.call(&"credits")))), "drain the balance")
	var cargo_before: Dictionary = _profile.call(&"cargo_items")
	assert_false(bool(_profile.call(&"buy_ammo", &"laser", 300, 120)), "no credits, no ammo")
	assert_eq(int(_profile.call(&"credits")), 0, "nothing was charged")
	assert_eq(_profile.call(&"cargo_items"), cargo_before, "and nothing was delivered")
	assert_eq(int(_profile.call(&"ammo_units", &"laser")), 0, "the hold is still empty")
	## An id outside the six families is refused before anything is charged, and no seventh
	## pack or cargo id appears.
	_profile.call(&"add_credits", START_CREDITS)
	assert_eq(int(_profile.call(&"credits")), START_CREDITS, "refill the balance")
	assert_false(bool(_profile.call(&"buy_ammo", &"lance", 300, 120)), "an unknown family")
	assert_false(bool(_profile.call(&"buy_ammo", &"fuel_cell", 300, 120)), "and the fuel cell")
	assert_eq(int(_profile.call(&"credits")), START_CREDITS, "neither charged a credit")
	assert_eq(int(_profile.call(&"ammo_of", &"lance")), 0, "no seventh pack appeared")
	assert_eq(int(_profile.call(&"ammo_units", &"lance")), 0, "nor a cargo id for one")
	assert_eq(int(_profile.call(&"cargo_qty", &"ammo_lance")), 0, "nor a prefixed stranger")
	assert_eq(
		StringName(_profile.call(&"ammo_item_id", &"lance")),
		&"",
		"an unknown family has no cargo id"
	)


# ------------------------------------------------------------- AC4b: the launch auto-load


## CONTRACTS section 17 / 10 section 6.1: at launch each fitted weapon's pack auto-fills from
## the hold's units of its family **up to** its `ammo_max`, and the drawn units leave the
## hold. Measured on the shipped flight scene: a Vanguard fit of one laser and one cannon, a
## laser pack at 100 rounds with 30 units held, a cannon pack at 0 with 12 held. The laser
## needs 200 rounds (20 units) and draws all 20; the cannon needs 300 (30 units) and takes
## the 12 it can -- so the cannon's units are gone, the laser keeps 10, and both slots read
## the pack the draw produced.
func test_the_launch_auto_load_draws_the_hold_up_to_the_ceiling() -> void:
	_profile.set(&"_ammo", {&"laser": 100, &"cannon": 0})
	_profile.set(&"_cargo", {&"ammo_laser": 30, &"ammo_cannon": 12})
	var scene := _launch(VANGUARD, _two_gun_fit())
	var state: Variant = scene.get(&"_state")
	var expected_weapons: Array[StringName] = [&"laser", &"cannon"]
	assert_eq(state.weapons, expected_weapons, "the fit's two families, in W-cell order")
	assert_eq(
		state.ammo,
		[300, 120] as Array[int],
		"the laser filled to its 300 ceiling, the cannon took the 12 units on hand"
	)
	assert_eq(scene.get(&"_ammo_seed"), [300, 120] as Array[int], "and the seed records it")
	assert_eq(int(_profile.call(&"ammo_of", &"laser")), 300, "the laser pack is the load")
	assert_eq(int(_profile.call(&"ammo_of", &"cannon")), 120, "and the cannon's is its draw")
	assert_eq(int(_profile.call(&"ammo_units", &"laser")), 10, "20 of the 30 laser units left")
	assert_eq(int(_profile.call(&"cargo_qty", &"ammo_cannon")), 0, "every cannon unit left")
	assert_eq(
		int(_profile.call(&"cargo_qty", &"ammo_laser")) * Catalog.ROUNDS_PER_CARGO_UNIT,
		100,
		"the units left behind are the 100 rounds the cannon draw did not need"
	)
	## A family the fit does not mount is not drawn from, even when the hold carries it.
	assert_eq(int(_profile.call(&"cargo_qty", &"ammo_rocket")), 0, "no rocket units were held")
	## Finding 7's other half: the units **take cargo slots**. One unit is one slot, read off
	## the launch's own hold mirror (game.gd's `_sync_cargo` sums every cargo value), and the
	## ten laser units left in the hold are ten slots of the Vanguard's forty.
	assert_eq(int(state.cargo_used), 10, "the ten units left in the hold occupy ten slots")


## The once-per-family rule, measured on the case that tells it apart: a Lancer mounts two
## lasers and the hold carries exactly one pack (30 units). The draw happens **once** and
## both slots read the one pack, so both read 300; a per-slot draw would leave the second
## slot empty, because the hold has nothing left for it.
func test_a_twin_weapon_fit_draws_its_family_once() -> void:
	_profile.set(&"_ammo", {&"laser": 0})
	_profile.set(&"_cargo", {&"ammo_laser": 30})
	var scene := _launch(LANCER, _twin_laser_fit())
	var state: Variant = scene.get(&"_state")
	assert_eq(
		state.weapons, [&"laser", &"laser"] as Array[StringName], "two cells, one family"
	)
	assert_eq(state.ammo, [300, 300] as Array[int], "both slots read the one 300-round pack")
	assert_eq(int(_profile.call(&"ammo_units", &"laser")), 0, "and the hold paid exactly once")


## The ceiling is the **family's** `ammo_max`, and the auto-load never lowers a pack that is
## already at or above it: the shipped 300-round default sits above the rocket's 100, so a
## full hold still draws nothing for it -- "up to `ammo_max`" is a ceiling on the fill, not a
## clamp on the magazine. Under the ceiling the last indivisible unit may overshoot by up to
## `ROUNDS_PER_CARGO_UNIT - 1` rounds, and the pack is clamped there.
func test_the_ceiling_is_the_family_max_and_the_last_unit_may_overshoot() -> void:
	_profile.set(&"_ammo", {&"cannon": 295})
	_profile.set(&"_cargo", {&"ammo_cannon": 1})
	var scene := _launch(VANGUARD, _one_gun_fit(&"w_cannon"))
	var state: Variant = scene.get(&"_state")
	assert_eq(int(state.ammo[0]), 300, "the 5-round shortfall took a whole 10-round unit")
	assert_eq(int(_profile.call(&"cargo_qty", &"ammo_cannon")), 0, "and the unit left the hold")
	## Above the ceiling: nothing is drawn and nothing is lowered.
	_seed_account()
	_profile.set(&"_ammo", {&"rocket": ProfileData.DEFAULT_AMMO})
	_profile.set(&"_cargo", {&"ammo_rocket": 10})
	var above := _launch(VANGUARD, _one_gun_fit(&"w_rocket"))
	var above_state: Variant = above.get(&"_state")
	assert_eq(
		int(above_state.ammo[0]),
		ProfileData.DEFAULT_AMMO,
		"a pack above its 100-round ceiling keeps every round it had"
	)
	assert_eq(int(_profile.call(&"cargo_qty", &"ammo_rocket")), 10, "and the hold is untouched")
	## Below the ceiling the same family does draw, and stops at it.
	_seed_account()
	_profile.set(&"_ammo", {&"rocket": 90})
	_profile.set(&"_cargo", {&"ammo_rocket": 10})
	var under := _launch(VANGUARD, _one_gun_fit(&"w_rocket"))
	var under_state: Variant = under.get(&"_state")
	assert_eq(int(under_state.ammo[0]), 100, "a 10-round shortfall takes exactly one unit")
	assert_eq(int(_profile.call(&"cargo_qty", &"ammo_rocket")), 9, "and leaves the rest")


## "Never in flight" (the brief's rule, 10 section 6.1): the auto-load is the launch's, and
## firing moves no cargo. The live pack empties, the dock's report files the delta into the
## pack store as it always did, and the hold does not move -- so a pack that empties in
## flight stays empty until the next launch, and the next launch is what draws again.
func test_the_auto_load_happens_at_launch_only_never_in_flight() -> void:
	_profile.set(&"_ammo", {&"laser": 0})
	_profile.set(&"_cargo", {&"ammo_laser": 30})
	var scene := _launch(VANGUARD, _one_gun_fit(&"w_laser"))
	var state: Variant = scene.get(&"_state")
	assert_eq(int(state.ammo[0]), 300, "the launch loaded the pack")
	assert_eq(int(_profile.call(&"ammo_units", &"laser")), 0, "from the hold")
	state.set_ammo(0, 0)
	scene.call(&"_file_ammo_report")
	assert_eq(int(_profile.call(&"ammo_units", &"laser")), 0, "firing draws nothing from it")
	assert_eq(int(_profile.call(&"ammo_of", &"laser")), 0, "and the store files the empty pack")
	## The next launch, with nothing in the hold, keeps it empty: no cargo teleport.
	var again := _launch(VANGUARD, _one_gun_fit(&"w_laser"))
	var again_state: Variant = again.get(&"_state")
	assert_eq(int(again_state.ammo[0]), 0, "an empty hold launches an empty pack")
	assert_eq(int(_profile.call(&"cargo_qty", &"ammo_laser")), 0, "and nothing appeared in it")
	## With units in the hold, that same launch refills it.
	_profile.set(&"_ammo", {&"laser": 0})
	_profile.set(&"_cargo", {&"ammo_laser": 3})
	var refilled := _launch(VANGUARD, _one_gun_fit(&"w_laser"))
	var refilled_state: Variant = refilled.get(&"_state")
	assert_eq(int(refilled_state.ammo[0]), 30, "three units are 30 rounds")
	assert_eq(int(_profile.call(&"cargo_qty", &"ammo_laser")), 0, "and they left the hold")


# ---------------------------------------------------------------- AC4c: the exchange sale


## CONTRACTS section 17: EXCHANGE buys a cargo unit at 60 % of its per-unit list. The twelve
## pinned figures are quoted in `AMMO_UNITS`; the tree's reads must equal them.
func test_the_exchange_prices_a_unit_at_sixty_percent_of_its_list() -> void:
	for family: StringName in AMMO_UNITS:
		var item_id: StringName = Catalog.ammo_item_id(family)
		var figures: Dictionary = AMMO_UNITS[family]
		var list_unit := int(figures[&"list"])
		var sale := int(figures[&"sale"])
		assert_eq(
			Catalog.ammo_unit_cost(item_id), list_unit, "%s's per-unit list" % String(item_id)
		)
		assert_eq(
			ExchangeScript.ammo_list_unit(item_id),
			list_unit,
			"%s reads the list" % String(item_id)
		)
		assert_eq(
			ExchangeScript.ammo_unit_price(item_id), sale, "%s's 60 %% sale" % String(item_id)
		)
		assert_eq(
			ExchangeScript.baseline_of(item_id),
			list_unit,
			"%s's baseline is the list" % String(item_id)
		)
		assert_eq(
			ExchangeScript.exchange_price(item_id, 1.0),
			sale,
			"%s's unit price ignores demand" % String(item_id)
		)
		assert_eq(
			ExchangeScript.exchange_price(item_id, 1.6), sale, "and reads the same at any demand"
		)
	assert_eq(ExchangeScript.AMMO_SELL_PERCENT, 0.6, "the pinned share")
	assert_eq(ExchangeScript.ammo_unit_price(&"ammo_bogus"), 0, "an unknown id prices to 0")


## A sale through the shipped transaction: the hold pays whole cargo units, the credits
## receive `gross - fee` at the exchange's own commission (05 section 5), and the third book
## moves **no** market state -- there is no demand to cool and no quota to queue against.
func test_an_ammo_sale_moves_cargo_and_credits_and_no_market_state() -> void:
	_profile.set(&"_cargo", {&"ammo_laser": 30})
	_profile.set(&"_credits", START_CREDITS)
	var now := Clock.now()
	ExchangeScript.evaluate_market(_profile, now)
	var market_before: Dictionary = _profile.call(&"market")
	var result: Dictionary = ExchangeScript.sell(_profile, &"ammo_laser", 30, now)
	assert_true(bool(result[&"ok"]), "the sale goes through")
	assert_eq(StringName(result[&"kind"]), ExchangeScript.KIND_AMMO, "the third book's word")
	assert_eq(int(result[&"sellable"]), 30, "all 30 units are taken")
	assert_eq(int(result[&"unit"]), 2, "at the pinned 2 CR unit")
	assert_eq(int(result[&"gross"]), 60, "gross 30 x 2")
	assert_eq(int(result[&"fee"]), 10, "the 10 CR commission floor")
	assert_eq(int(result[&"paid"]), 50, "so the account is paid 50")
	assert_eq(int(result[&"queued"]), 0, "nothing is queued: the station always takes ammo")
	assert_eq(int(_profile.call(&"cargo_qty", &"ammo_laser")), 0, "the units left the hold")
	assert_eq(
		int(_profile.call(&"credits")) - START_CREDITS, 50, "and exactly the paid figure arrived"
	)
	assert_eq(_profile.call(&"market"), market_before, "the market state is byte-identical")
	## A quantity the hold cannot cover is refused and moves nothing.
	_profile.set(&"_cargo", {&"ammo_laser": 30})
	var before := int(_profile.call(&"credits"))
	var refused: Dictionary = ExchangeScript.sell(_profile, &"ammo_laser", 31, now)
	assert_false(bool(refused[&"ok"]), "31 units against 30 held")
	assert_eq(StringName(refused[&"reason"]), &"insufficient_cargo", "is insufficient cargo")
	assert_eq(int(_profile.call(&"cargo_qty", &"ammo_laser")), 30, "the hold stayed whole")
	assert_eq(int(_profile.call(&"credits")), before, "and no credits moved")
	var unknown: Dictionary = ExchangeScript.sell(_profile, &"ammo_bogus", 1, now)
	assert_false(bool(unknown[&"ok"]), "an id outside the six is not a sale")
	assert_eq(StringName(unknown[&"reason"]), &"unknown_item", "unknown_item")


## 05 section 6: SELL ALL RAW pays out raw ore and surplus components, and the ammunition
## cargo units are neither -- the shortcut must not dump a magazine's worth of rounds by
## accident (the button's own label is the reading).
func test_sell_all_raw_never_dumps_ammunition() -> void:
	_profile.set(&"_cargo", {&"mineral_iron": 6, &"ammo_laser": 30, &"comp_scrap_1": 2})
	_profile.set(&"_credits", START_CREDITS)
	ExchangeScript.evaluate_market(_profile, Clock.now())
	var result: Dictionary = ExchangeScript.sell_all(_profile, Clock.now())
	assert_true(bool(result[&"ok"]), "the raw stacks sell without a refusal")
	assert_eq(int(_profile.call(&"cargo_qty", &"mineral_iron")), 0, "the ore went")
	assert_eq(int(_profile.call(&"cargo_qty", &"comp_scrap_1")), 0, "and the salvage went")
	assert_eq(
		int(_profile.call(&"cargo_qty", &"ammo_laser")), 30, "the ammunition stayed in the hold"
	)


## STATION_HUB section 5.8 / CONTRACTS section 17: the ammo units are sold on the EXCHANGE
## hold surface, drawn beside the minerals and components. Mounted from the shipped scene, so
## the list order, the row's title, its meta word and its three cells are the pane's own.
func test_the_exchange_hold_surface_lists_ammo_units_beside_the_minerals() -> void:
	_profile.set(
		&"_cargo", {&"mineral_iron": 5, &"comp_scrap_1": 2, &"ammo_laser": 30, &"ammo_railgun": 4}
	)
	var panel := _mount_panel()
	var ids: Array[StringName] = panel.get(&"_hold_ids")
	assert_eq(
		ids,
		[&"mineral_iron", &"comp_scrap_1", &"ammo_laser", &"ammo_railgun"] as Array[StringName],
		"minerals, then components, then the ammo units in pack order"
	)
	var laser := _hold_row(panel, &"ammo_laser")
	assert_eq(
		_hold_cell(laser, "TitleBox/Title"), "LASER CELLS", "the pack's own name, upper-cased"
	)
	assert_eq(_hold_cell(laser, "TitleBox/Meta"), "AMMO", "and its own meta word")
	assert_eq(_hold_cell(laser, "Qty/Value"), "30", "30 cargo units")
	assert_eq(_hold_cell(laser, "Unit/Value"), "2", "at the pinned 2 CR unit")
	assert_eq(_hold_cell(laser, "Total/Value"), "50", "and the 50 CR the sale pays")
	var railgun := _hold_row(panel, &"ammo_railgun")
	assert_eq(_hold_cell(railgun, "TitleBox/Title"), "RAILGUN SLUGS", "the railgun row")
	assert_eq(_hold_cell(railgun, "Qty/Value"), "4", "4 units")
	assert_eq(_hold_cell(railgun, "Unit/Value"), "14", "at 14 CR")
	assert_eq(_hold_cell(railgun, "Total/Value"), "46", "for 46 CR (56 less the 10 CR fee)")
	## A family the hold does not carry is not drawn, exactly as an unheld mineral is not.
	assert_true(
		_hold_row_or_null(panel, &"ammo_cannon") == null, "an unheld family draws no row"
	)


# ------------------------------------------------------------- AC4d: the fuel-cell delist


## 10 section 6.1: fuel cells are delisted from every sale surface. J0 measured that no
## surface carries one today, so this suite asserts that state rather than changing it: the
## id is nowhere in the catalogues the sale surfaces read, and the exchange refuses to price
## it.
func test_no_sale_surface_carries_a_fuel_cell_row() -> void:
	var fuel_cell: StringName = PlayerStateScript.FUEL_CELL_ITEM
	assert_eq(fuel_cell, &"fuel_cell", "the un-prefixed id the R key spends")
	assert_false(Catalog.ammo_ids().has(fuel_cell), "no ammunition pack row is a fuel cell")
	assert_false(Catalog.ship_ids().has(fuel_cell), "no shipyard row is one either")
	assert_false(ModuleData.MODULES.has(fuel_cell), "nor a module row")
	assert_false(MineralData.mineral_ids().has(fuel_cell), "nor a mineral")
	assert_false(MineralData.is_ore(fuel_cell) or MineralData.is_ingot(fuel_cell), "nor an item")
	assert_true(
		ComponentData.component(fuel_cell).is_empty(),
		"nor a component: the only 'Fuel Cell' in the tree is comp_pow_1, a different id"
	)
	assert_eq(
		String(ComponentData.component(&"comp_pow_1").get(&"name", "")),
		"Fuel Cell",
		"whose display name is the one the J0 pass measured"
	)
	assert_false(ExchangeScript.is_sellable(fuel_cell), "the exchange does not buy one")
	assert_eq(ExchangeScript.exchange_price(fuel_cell, 1.0), 0, "and prices it 0")
	assert_eq(ExchangeScript.baseline_of(fuel_cell), 0, "with no baseline")


## 10 section 6.1's carve-out, the other half: "existing stacks keep working on R". A
## `fuel_cell` already in the hold still burns through the shipped in-flight path.
func test_an_existing_fuel_cell_stack_still_burns_on_r() -> void:
	var state: Variant = PlayerStateScript.new()
	state.fuel_max = 200.0
	state.set_fuel(100.0)
	_profile.call(&"add_cargo", PlayerStateScript.FUEL_CELL_ITEM, 2)
	assert_eq(
		int(_profile.call(&"cargo_qty", PlayerStateScript.FUEL_CELL_ITEM)), 2, "two cells held"
	)
	assert_true(bool(state.call(&"fuel_cell_ready")), "one is ready to burn")
	assert_true(bool(state.call(&"consume_fuel_cell")), "the cell burns")
	assert_eq(
		int(_profile.call(&"cargo_qty", PlayerStateScript.FUEL_CELL_ITEM)), 1, "one cell left"
	)
	assert_eq(
		float(state.get(&"fuel")),
		100.0 + PlayerStateScript.FUEL_CELL_UNITS,
		"and the tank took the cell's own units"
	)


# --------------------------------------------------------------------------- fixtures


## The Vanguard's two-cell gun fit, both cells filled, so a launch has two families to seed.
func _two_gun_fit() -> Dictionary:
	return {
		&"engines": [ENGINE],
		&"power": REACTOR,
		&"weapons": ["w_laser", "w_cannon"],
	}


## The Lancer's own two-cell shape: both cells one family, the once-per-family case.
func _twin_laser_fit() -> Dictionary:
	return {
		&"engines": [ENGINE],
		&"power": REACTOR,
		&"weapons": ["w_laser", "w_laser"],
	}


## One Vanguard W cell fitted with `module_id` and the rest empty.
func _one_gun_fit(module_id: StringName) -> Dictionary:
	return {
		&"engines": [ENGINE],
		&"power": REACTOR,
		&"weapons": [String(module_id)],
	}


## Launch one hull on one stored fit: the test writes the profile (the launch's own source),
## then instantiates the shipped flight scene, so the auto-load measured is the scene's own.
func _launch(hull_id: StringName, fit: Dictionary) -> Node2D:
	_free_scene()
	_profile.set(&"_active_ship", hull_id)
	_profile.call(&"set_fit", hull_id, fit)
	_scene = GameScene.instantiate() as Node2D
	_fixture_host().add_child(_scene)
	return _scene


func _free_scene() -> void:
	if _scene != null and is_instance_valid(_scene):
		_scene.free()
	_scene = null


## Mount the shipped exchange pane on the fixture host with the shipped theme, the way the
## station shell does: the pane's own `_ready` builds the hold and the board.
func _mount_panel() -> Control:
	if _host == null or not is_instance_valid(_host):
		_host = Control.new()
		_host.name = "AmmoHost"
		_host.theme = ThemeRes
		_host.size = Vector2(1920.0, 1080.0)
		_fixture_host().add_child(_host)
	_panel = PanelScene.instantiate() as Control
	_host.add_child(_panel)
	return _panel


func _free_host() -> void:
	if _panel != null and is_instance_valid(_panel):
		_panel.free()
	_panel = null
	if _host != null and is_instance_valid(_host):
		_host.free()
	_host = null


## The hold row for one cargo id, or null when the pane drew none: the pane names its row
## `Hold<ItemIdPascalCase>` and seats it in the scene-unique `HoldRows` box.
func _hold_row_or_null(panel: Control, item_id: StringName) -> Node:
	var rows := panel.get_node_or_null(NodePath("%HoldRows"))
	if rows == null:
		return null
	return rows.get_node_or_null(NodePath("Hold%s" % String(item_id).to_pascal_case()))


func _hold_row(panel: Control, item_id: StringName) -> Node:
	var row := _hold_row_or_null(panel, item_id)
	assert_true(row != null, "the %s row is drawn" % String(item_id))
	return row


## The row's inner cell text: `TitleBox/Title`, `TitleBox/Meta`, `Qty/Value`, `Unit/Value` or
## `Total/Value`, all inside the row's own `RowInner/RowBox`.
func _hold_cell(row: Node, path: String) -> String:
	var label := row.get_node_or_null(NodePath("RowInner/RowBox/%s" % path)) as Label
	assert_true(label != null, "the row carries %s" % path)
	return "" if label == null else label.text


## Where a fixture may enter the tree: the runner calls every test from inside its own
## `_ready`, when the root viewport is still busy adding the runner scene, so
## `root.add_child(...)` fails there. The profile autoload took children all through the run,
## and `game.gd` resolves the profile from the tree root (`test_p2a_launch_fit.gd`'s reason).
func _fixture_host() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(NodePath(PROFILE_SERVICE))


func _delete_file(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())
