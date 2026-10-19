@tool
extends McpTestSuite
const Support := preload("res://tests/support.gd")
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
const PanelScript := preload("res://ui/station/exchange_panel.gd")
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
var _previous_ammo_rem: Dictionary = {}
var _previous_fits: Dictionary = {}
var _previous_owned: Array = []
var _previous_modules: Dictionary = {}
var _previous_market: Dictionary = {}


func suite_name() -> String:
	return "s5_ammo_cargo"


func suite_setup(_ctx: Dictionary) -> void:
	_profile = Support.profile()
	if _profile == null:
		fail_setup("the PlayerProfile autoload is the cargo owner this suite measures")
		return
	_previous_path = String(_profile.get(&"save_path"))
	_previous_ship = StringName(_profile.call(&"active_ship"))
	_previous_credits = int(_profile.call(&"credits"))
	_previous_cargo = (_profile.get(&"_cargo") as Dictionary).duplicate(true)
	_previous_ammo = (_profile.get(&"_ammo") as Dictionary).duplicate(true)
	_previous_ammo_rem = (_profile.get(&"_ammo_rem") as Dictionary).duplicate(true)
	_previous_fits = _profile.call(&"fits")
	_previous_owned = _profile.call(&"owned_ships")
	_previous_modules = _profile.call(&"modules")
	_previous_market = (_profile.get(&"_market") as Dictionary).duplicate(true)
	_profile.set(&"save_path", SCRATCH_PROFILE)
	Support.delete_file(SCRATCH_PROFILE)


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
	_profile.set(&"_ammo_rem", _previous_ammo_rem)
	_profile.set(&"_fits", _previous_fits)
	_profile.set(&"_owned_ships", _previous_owned)
	_profile.set(&"_modules", _previous_modules)
	_profile.set(&"_market", _previous_market)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	Support.delete_file(SCRATCH_PROFILE)
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
	## R-S21-2's opened-unit remainder is part of the pack store's state: a fixture that
	## writes its own packs writes its own remainder, or a previous test's half unit would
	## ride into this one's draw.
	_profile.set(&"_ammo_rem", {})


# --------------------------------------------------------------- AC4a: the six cargo items


## CONTRACTS section 17 / 10 section 6.1: one cargo item per family, counted in
## `ROUNDS_PER_CARGO_UNIT` rounds, with the `ammo_` prefix the one mapping. The eight ids
## are the pinned namespace since S23's V1 (the two exclusive families' packs), and the
## countermeasure reading stands: nothing flare- or chaff-shaped ships as a pack.
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
		&"ammo_proton",
		&"ammo_flak",
	]
	assert_eq(Catalog.ammo_item_ids(), expected, "the eight pinned cargo ids, in pack order")
	assert_eq(Catalog.ammo_ids().size(), 8, "eight families, still no countermeasure pack")
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
## clamp on the magazine. Under the ceiling the shortfall is drawn **in rounds** (R-S21-2):
## the last unit's unused rounds are banked as the family's remainder (<= 9) instead of
## being burned with the unit, so the 5-round shortfall below loads 5 rounds, spends one
## unit and keeps 5.
func test_the_ceiling_is_the_family_max_and_the_last_unit_may_overshoot() -> void:
	_profile.set(&"_ammo", {&"cannon": 295})
	_profile.set(&"_cargo", {&"ammo_cannon": 1})
	var scene := _launch(VANGUARD, _one_gun_fit(&"w_cannon"))
	var state: Variant = scene.get(&"_state")
	assert_eq(int(state.ammo[0]), 300, "the 5-round shortfall took a whole 10-round unit")
	assert_eq(int(_profile.call(&"cargo_qty", &"ammo_cannon")), 0, "and the unit left the hold")
	assert_eq(
		int(_profile.call(&"ammo_remainder", &"cannon")),
		5,
		"whose 5 unused rounds are banked, not burned (R-S21-2)"
	)
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
## receive `gross - fee` at the exchange's own commission for ammunition (R-S21-1: no 10 CR
## floor, `roundi(0.02 x gross)`), and the third book moves **no** market state -- there is
## no demand to cool and no quota to queue against.
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
	assert_eq(int(result[&"fee"]), 1, "R-S21-1: roundi(0.02 x 60), no 10 CR floor")
	assert_eq(int(result[&"paid"]), 59, "so the account is paid 59")
	assert_eq(int(result[&"queued"]), 0, "nothing is queued: the station always takes ammo")
	assert_eq(int(_profile.call(&"cargo_qty", &"ammo_laser")), 0, "the units left the hold")
	assert_eq(
		int(_profile.call(&"credits")) - START_CREDITS, 59, "and exactly the paid figure arrived"
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
	assert_eq(_hold_cell(laser, "Total/Value"), "59", "and the 59 CR the sale pays (R-S21-1)")
	var railgun := _hold_row(panel, &"ammo_railgun")
	assert_eq(_hold_cell(railgun, "TitleBox/Title"), "RAILGUN SLUGS", "the railgun row")
	assert_eq(_hold_cell(railgun, "Qty/Value"), "4", "4 units")
	assert_eq(_hold_cell(railgun, "Unit/Value"), "14", "at 14 CR")
	assert_eq(_hold_cell(railgun, "Total/Value"), "55", "for 55 CR (56 less the 1 CR fee)")
	## A family the hold does not carry is not drawn, exactly as an unheld mineral is not.
	assert_true(
		_hold_row_or_null(panel, &"ammo_cannon") == null, "an unheld family draws no row"
	)


## S28's chrome law on the surviving EXCHANGE pane (S28_BRIEF A10, A11, A12, A16): the
## SELL ALL RAW precondition, the one-unit stepper default with the quantity on the
## primary, the holdings header band, and the P1/P2 action cluster.
func test_the_sale_column_ships_the_s28_chrome_law() -> void:
	## A10 at zero raw: an ingot-only hold lists rows but the bulk action is dead (D17-P2).
	_profile.set(&"_cargo", {&"ingot_iron": 5})
	var panel := _mount_panel()
	assert_true(_hold_row_or_null(panel, &"ingot_iron") != null, "the ingot stack lists")
	assert_true(
		(panel.get(&"_sell_all") as Button).disabled,
		"SELL ALL RAW disables when no raw stack matches (A10)"
	)
	assert_eq(
		String((panel.get(&"_sell_value") as Label).text), "0 UNITS",
		"the one SELL UNITS selector reads zero (N49-amended)"
	)
	_free_host()
	## A11: a raw stack of five arms the stepper at ONE unit and the primary carries it.
	_profile.set(&"_cargo", {&"mineral_iron": 5})
	panel = _mount_panel()
	assert_false(
		(panel.get(&"_sell_all") as Button).disabled, "with a raw stack SELL ALL RAW wakes"
	)
	panel.call(&"_select", &"mineral_iron")
	## N48: the commit button is always worded SELL; the count rides the SELL UNITS selector.
	assert_eq(String((panel.get(&"_sell") as Button).text), "SELL", "the commit button reads SELL")
	assert_eq(
		String((panel.get(&"_sell_value") as Label).text), "1 UNIT",
		"and the SELL UNITS selector arms at one unit (A11 with A5 grammar)"
	)
	assert_eq(int(panel.get(&"_sell_units")), 1, "a stray click can never dump the stack")
	## N42 (supersedes S28-A12): the hold list wears one column-header band, inside its
	## scroll above the rows, captioned with the row stacks' own words UNITS / CR EACH / CR NET.
	var header := panel.get_node_or_null(
		NodePath("ExchangeBody/HoldBox/HoldScroll/HoldRows/HoldHeader/HoldHeaderRow")
	) as HBoxContainer
	assert_true(header != null, "the hold column-header band ships (N42)")
	if header != null:
		var words: Array[String] = []
		for cell: Node in header.get_children():
			if cell is Label:
				words.append((cell as Label).text)
		assert_true(
			words.has("UNITS") and words.has("CR EACH") and words.has("CR NET"),
			"UNITS, CR EACH and CR NET title the three columns (N42)"
		)
	## A16: the action cluster is one P2 row at the foot, plates at the P1 token, primary rightmost.
	## S30 (UI_SPEC section 19.3): the cluster now rides the pane's shared `PaneFoot` band.
	var row := panel.get_node_or_null(^"PaneFoot/ActionsRow") as HBoxContainer
	assert_true(row != null, "the P2 cluster row ships")
	if row != null:
		var sell := panel.get(&"_sell") as Button
		var cancel := panel.get(&"_cancel") as Button
		var sell_all := panel.get(&"_sell_all") as Button
		assert_eq(sell.get_parent(), row, "SELL sits in the cluster")
		assert_eq(cancel.get_parent(), row, "CANCEL sits in the cluster")
		assert_eq(sell_all.get_parent(), row, "SELL ALL RAW sits in the cluster")
		assert_eq(sell.custom_minimum_size, Vector2(360.0, 56.0), "the P1 plate")
		assert_eq(row.get_theme_constant("separation"), 16, "the P2 gutter")
		assert_eq(sell.get_index(), row.get_child_count() - 1, "the primary is rightmost")


## N42 (D20 note 1, UI_SPEC section 13.1): both lists render one shared row plate and wear a
## column-header band. The per-row caption stacks are gone and the board carries one band per
## book (minerals, components).
func test_n42_the_lists_share_one_row_plate_and_wear_their_bands() -> void:
	_profile.set(&"_cargo", {&"mineral_iron": 5})
	var panel := _mount_panel()
	var hold := _hold_row(panel, &"mineral_iron")
	assert_true(
		hold.get_node_or_null(NodePath("RowInner/RowBox/TitleBox/Title")) != null,
		"the hold row renders the shared plate (icon, title, value columns)"
	)
	for cell_name: String in ["Qty", "Unit", "Total"]:
		assert_true(
			hold.get_node_or_null(NodePath("RowInner/RowBox/%s/Value" % cell_name)) != null,
			"the %s cell keeps its Value child" % cell_name
		)
		assert_true(
			hold.get_node_or_null(NodePath("RowInner/RowBox/%s/Caption" % cell_name)) == null,
			"the %s per-row caption stack is deleted (N42)" % cell_name
		)
	var hold_band := panel.get_node_or_null(
		NodePath("ExchangeBody/HoldBox/HoldScroll/HoldRows/HoldHeader/HoldHeaderRow")
	) as HBoxContainer
	assert_true(hold_band != null, "the hold band ships (N42)")
	var board_rows := panel.get_node_or_null(NodePath("%BoardRows"))
	var mineral_band := board_rows.get_node_or_null(^"MineralHeader/MineralHeaderRow") as HBoxContainer
	assert_true(mineral_band != null, "the board's mineral band ships (N42)")
	var mineral_words := _band_words(mineral_band)
	assert_true(
		mineral_words.has("CR EACH") and mineral_words.has("INDEX") and mineral_words.has("BAND"),
		"the mineral band carries CR EACH / INDEX / BAND (N42)"
	)
	var component_band := board_rows.get_node_or_null(
		^"ComponentHeader/ComponentHeaderRow"
	) as HBoxContainer
	assert_true(component_band != null, "and its component band (two column sets)")
	var component_words := _band_words(component_band)
	assert_true(
		component_words.has("QUOTA") and component_words.has("KIND") and component_words.has("GRADE"),
		"the component band carries QUOTA / KIND / GRADE (N42)"
	)
	_free_host()


## A band's own caption words, in order.
func _band_words(band: HBoxContainer) -> Array[String]:
	var out: Array[String] = []
	if band == null:
		return out
	for cell: Node in band.get_children():
		if cell is Label:
			out.append((cell as Label).text)
	return out


## N43 (UI_SPEC section 13.1): the hold title column never renders below 180 px, the hold
## list is an N37 cluster (no per-row INSPECT chip), and the trade column's single INSPECT
## ActionInline stays dimmed until a row holds focus/selection.
func test_n43_the_hold_cluster_and_the_title_room() -> void:
	assert_eq(int(PanelScript.COL_QTY), 60, "the qty column rebalances to 60 (N43)")
	assert_eq(int(PanelScript.COL_UNIT), 64, "the unit column to 64 (N43)")
	assert_eq(int(PanelScript.COL_TOTAL), 80, "the total column to 80 (N43)")
	var margin: Vector2i = PanelScript.ROW_INNER_MARGIN
	var room := int(
		PanelScript.HOLD_CONTENT_WIDTH - 2.0 * margin.x - PanelScript.COL_ICON
		- 4.0 * PanelScript.COLUMN_SEPARATION - (PanelScript.COL_QTY + PanelScript.COL_UNIT + PanelScript.COL_TOTAL)
	)
	assert_true(room >= 180, "the hold title keeps %d px, >= 180 (N43)" % room)
	_profile.set(&"_cargo", {&"mineral_iron": 5})
	var panel := _mount_panel()
	var row := _hold_row(panel, &"mineral_iron")
	assert_true(
		row.get_node_or_null(NodePath("RowInner/RowBox/InspectChip")) == null,
		"the hold row carries no per-row INSPECT chip (N43)"
	)
	## N37 rev (owner 2026-10-07): the trade column's cluster chip is retired - the station's
	## one INSPECT toggle routes the row press to the sheet.
	assert_true(
		panel.get(&"_inspect_cluster") == null,
		"the trade column's cluster chip is retired (N37 rev)"
	)
	_free_host()


## N44 (UI_SPEC section 13.1): both lists' scroll viewports begin on one y - each list's box
## is caption -> scroll with its band as the scroll's first child, so both identically-built
## captions top the scrolls at the same y and the outer boxes stay even.
func test_n44_the_lists_start_on_one_y() -> void:
	_profile.set(&"_cargo", {&"mineral_iron": 5})
	var panel := _mount_panel()
	var hold_box := panel.get_node_or_null(^"ExchangeBody/HoldBox") as VBoxContainer
	var board_box := panel.get_node_or_null(^"ExchangeBody/MarketBoard") as VBoxContainer
	assert_true(hold_box != null and board_box != null, "both list boxes ship")
	if hold_box != null and board_box != null:
		assert_eq(hold_box.get_child_count(), 2, "the hold box is caption -> scroll (N44)")
		assert_eq(board_box.get_child_count(), 2, "the board box is caption -> scroll (N44)")
		assert_true(hold_box.get_child(0) is Label, "the hold caption leads")
		assert_eq((hold_box.get_child(1) as Node).name, "HoldScroll", "then the scroll")
		assert_true(board_box.get_child(0) is Label, "the board caption leads")
		assert_eq((board_box.get_child(1) as Node).name, "BoardScroll", "then the scroll")
	var hold_rows := panel.get_node_or_null(^"ExchangeBody/HoldBox/HoldScroll/HoldRows")
	var board_rows := panel.get_node_or_null(^"ExchangeBody/MarketBoard/BoardScroll/BoardRows")
	assert_eq((hold_rows.get_child(0) as Node).name, "HoldHeader", "the hold band tops its scroll")
	assert_eq(
		(board_rows.get_child(0) as Node).name, "MineralHeader", "the board band tops its scroll"
	)
	_free_host()


# ------------------------------------------------ N48/N49: the exchange sell cluster (S33)


## N48 (UI_SPEC section 14.1): the trade column's commit button is always worded `SELL` - the
## armed quantity wording retires; the count lives in the `SELL UNITS` selector.
func test_n48_the_commit_button_reads_sell_in_every_state() -> void:
	_profile.set(&"_cargo", {&"mineral_iron": 5})
	var panel := _mount_panel()
	var sell := panel.get(&"_sell") as Button
	assert_eq(sell.text, "SELL", "with nothing armed the commit button reads SELL (N48)")
	assert_true(sell.disabled, "and is disabled")
	panel.call(&"_select", &"mineral_iron")
	assert_eq(sell.text, "SELL", "armed, it still reads SELL (N48)")
	assert_false(sell.disabled, "and wakes")
	panel.call(&"_set_sell_units", 3)
	assert_eq(sell.text, "SELL", "at three units it still reads SELL")
	assert_true(
		String((panel.get(&"_confirm_strip") as Label).text).contains("SELL 3"),
		"and the confirm strip keeps its counted wording (N48)"
	)
	panel.call(&"_clear_selection")
	assert_eq(sell.text, "SELL", "cleared, it still reads SELL")
	_free_host()


## N49-amended (S35): the trade column carries ONE quantity control - the `SELL UNITS`
## selector (min 0, max the selected row's units) with its `MAX` / `0` quick-set chips. The
## S33 duplicate unit-number selector dies. Stack top-down: SellUnitsRow -> InspectCluster ->
## PaneFoot.
func test_n49_the_sell_units_selector_bounds_and_the_stack_order() -> void:
	_profile.set(&"_cargo", {&"mineral_iron": 5})
	var panel := _mount_panel()
	var minus := panel.get(&"_sell_minus") as Button
	var plus := panel.get(&"_sell_plus") as Button
	var value := panel.get(&"_sell_value") as Label
	assert_true(minus.disabled and plus.disabled, "no selection disables the SELL UNITS stepper (N49)")
	assert_eq(value.text, "0 UNITS", "and it reads zero")
	assert_true(
		value.get_theme_color(&"font_color").is_equal_approx(
			panel.call(&"_token", &"text_dim") as Color
		),
		"dimmed with no selection (N49)"
	)
	panel.call(&"_select", &"mineral_iron")
	assert_false(minus.disabled and plus.disabled, "a selection wakes the stepper")
	assert_eq(value.text, "1 UNIT", "arming at one unit")
	panel.call(&"_set_sell_units", -5)
	assert_eq(int(panel.get(&"_sell_units")), 0, "the floor is zero units (min 0, N49-amended)")
	panel.call(&"_set_sell_units", 99)
	assert_eq(int(panel.get(&"_sell_units")), 5, "the ceiling is the row's own units")
	## The S33 duplicate unit-number selector is gone entirely.
	assert_true(
		panel.get_node_or_null(^"ExchangeBody/TradeBox/StepperRow") == null,
		"the duplicate unit-number selector (StepperRow) dies (N49-amended)"
	)
	## N37 rev (owner 2026-10-07): the trade column's cluster chip is retired; the pane foot's
	## SELL / SELL ALL RAW cluster still sits below the trade column.
	assert_true(
		panel.get(&"_inspect_cluster") == null,
		"the INSPECT cluster is retired (N37 rev)"
	)
	assert_true(
		(panel.get_node(^"ExchangeBody") as Control).get_index()
			< (panel.get_node(^"PaneFoot") as Control).get_index(),
		"and the SELL / SELL ALL RAW cluster in the pane foot below the trade column"
	)
	_free_host()


## N49-amended (S35): the `MAX` chip fills the row's units and the `0` chip empties the
## selector; SELL is disabled at zero.
func test_n49_the_max_and_zero_quick_buttons() -> void:
	_profile.set(&"_cargo", {&"mineral_iron": 5})
	var panel := _mount_panel()
	var max_button := panel.get(&"_sell_max") as Button
	var zero_button := panel.get(&"_sell_zero") as Button
	var sell := panel.get(&"_sell") as Button
	assert_true(max_button != null and zero_button != null, "both quick-set chips ship")
	assert_eq(max_button.text, "MAX", "the fill chip reads MAX")
	assert_eq(zero_button.text, "0", "the empty chip reads 0")
	assert_true(
		(max_button.get_parent() == panel.get(&"_sell_units_row")),
		"and both sit beside the SELL UNITS stepper (N49-amended)"
	)
	assert_true(max_button.disabled and zero_button.disabled, "disabled with no selection")
	panel.call(&"_select", &"mineral_iron")
	panel.call(&"_on_sell_zero_pressed")
	assert_eq(int(panel.get(&"_sell_units")), 0, "0 empties the selector")
	assert_eq(String((panel.get(&"_sell_value") as Label).text), "0 UNITS", "the read follows")
	assert_true(sell.disabled, "and SELL is disabled at zero (N49-amended)")
	panel.call(&"_on_sell_max_pressed")
	assert_eq(int(panel.get(&"_sell_units")), 5, "MAX fills the row's units")
	assert_eq(String((panel.get(&"_sell_value") as Label).text), "5 UNITS", "the read follows")
	assert_false(sell.disabled, "and SELL wakes at a positive count")
	_free_host()


## N49-amended (S35): no second units-number selector exists anywhere in the exchange - the
## grep half (no `StepperRow` / `StepValue` / `_step_value` in the pane source or scene) and
## the scene half (no `%StepValue` / `%StepMinus` / `%StepPlus` node).
func test_n49_no_second_units_selector() -> void:
	var source := FileAccess.get_file_as_string("res://ui/station/exchange_panel.gd")
	var scene := FileAccess.get_file_as_string("res://ui/station/exchange_panel.tscn")
	for word: String in ["StepperRow", "StepValue", "StepMinus", "StepPlus", "_step_value", "_set_step"]:
		assert_true(
			source.find(word) == -1,
			"the pane's script carries no '%s' (N49-amended)" % word
		)
	for word: String in ["StepperRow", "StepValue", "StepMinus", "StepPlus"]:
		assert_true(
			scene.find(word) == -1,
			"the pane's scene carries no '%s' node (N49-amended)" % word
		)
	_profile.set(&"_cargo", {&"mineral_iron": 5})
	var panel := _mount_panel()
	for node_name: String in ["%StepValue", "%StepMinus", "%StepPlus", "%StepperRow"]:
		assert_true(
			panel.get_node_or_null(NodePath(node_name)) == null,
			"%s is gone (N49-amended)" % node_name
		)
	assert_true(panel.get(&"_sell_max") != null, "the MAX chip is the surviving control")
	_free_host()


## N49: a SELL press moves exactly the `SELL UNITS` value of the selected row.
func test_n49_a_sell_press_moves_exactly_the_selector_value() -> void:
	_profile.set(&"_cargo", {&"mineral_iron": 5})
	var panel := _mount_panel()
	panel.call(&"_select", &"mineral_iron")
	panel.call(&"_set_sell_units", 3)
	var before := int(_profile.call(&"cargo_qty", &"mineral_iron"))
	panel.call(&"_on_sell_pressed")
	var after := int(_profile.call(&"cargo_qty", &"mineral_iron"))
	assert_eq(before - after, 3, "a SELL press moves exactly the SELL UNITS value (N49)")
	_free_host()


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
	Support.profile().add_child(_scene)
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
		Support.profile().add_child(_host)
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
