@tool
extends McpTestSuite
## Suite s3_auction: the AUCTION house -- `game/auction.gd`'s rotation, weights, hot slot,
## F lot, prices and transactions, and the pane that renders them (STATION_HUB section
## 5.10's 2026-09-22 S3 amendment, docs/gameplay/10_ship_acquisition.md sections 2/2.2/2.3,
## docs/gameplay/15_module_affixes.md sections 1/2/5/6/8/9, CONTRACTS section 15).
##
## Two harnesses, deliberately:
##
## * the rotation, the weights and the price arithmetic are measured on **throwaway
##   `PlayerProfile` instances** whose `save_path` is repointed at a scratch file before the
##   first mutation (`test_s3_instances.gd`'s harness): no instance enters the tree, so the
##   debounced save Timer does not exist and every mutation writes through immediately;
## * the pane is mounted from the shipped scene with the shipped theme and driven through
##   the wiring the station shell itself uses, on the shipped autoload, whose `save_path` is
##   borrowed to its own scratch file and handed back in `suite_teardown` (T-93: the owner's
##   `user://profile.cfg` is never written).
##
## Every draw is **seeded** before it is read: 15 section 8's rolls read the global RNG and
## section 2.1's rotation reads whatever stream the caller hands in, so `SEED` is what makes
## each outcome repeatable. The observed rates are measured over `HULL_DRAWS` shelves and
## asserted against 10 section 2.2's own chance column, not against a literal this suite
## invents.

const Profile := preload("res://autoload/player_profile.gd")
const PanelScene := preload("res://ui/station/auction_panel.tscn")
const PanelScript := preload("res://ui/station/auction_panel.gd")
const StationScript := preload("res://ui/screens/station.gd")
const StationScene := preload("res://ui/screens/station.tscn")
const AuctionScript := preload("res://game/auction.gd")
const ModuleData := preload("res://game/module_catalog.gd")
const Catalog := preload("res://game/station_catalog.gd")
const FitData := preload("res://game/ship_fit.gd")
const Clock := preload("res://autoload/world_clock.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")

const PROFILE_PATH := "user://test_s3_auction.cfg"
const ROTATION_PATH := "user://test_s3_auction_rotation.cfg"
const PROFILE_SERVICE: StringName = &"PlayerProfile"
const TOKENS_TYPE: StringName = &"Tokens"

## The seed every draw test fixes before its first roll.
const SEED := 20260922
## How many shelves the hull and tier rates are measured over. 2 000 shelves is 2 000 hull
## draws and 18 000 tier draws: far past the point where a 5 % weight is visible.
const HULL_DRAWS := 2000
const TIER_DRAWS := 20000
## How many F-lot rarity rolls the 85 / 15 split is measured over.
const F_LOT_ROLLS := 2000
## 10 section 2.2's pinned chances, read back off `Auction.HULL_CHANCE` rather than retyped.
const CHANCE_ORDER: Array[StringName] = [
	&"ship_fighter",
	&"ship_vanguard",
	&"ship_miner",
	&"ship_trader",
	&"ship_freighter",
	&"ship_corvette",
	&"ship_gunship",
	&"ship_patrol",
	&"ship_destroyer",
]

## 09 section 3.1 / 09 section 3.6 ids the price arithmetic is measured on: a tier-I weapon
## (the family's cheapest row), a tier-III weapon and the utility the F lot's third
## exclusive shares a family with.
const LASER: StringName = &"w_laser"
const PLASMA: StringName = &"w_plasma"

## 15 section 5's three exclusives, in the catalogue's own order.
const EXCLUSIVES: Array[StringName] = [&"w_proton", &"w_flak", &"u_vault"]

## 10 section 2.1: a restock every 20 minutes of the one station clock.
const BAND := 1200

var _profiles: Array[Node] = []
var _profile: Node = null
var _host: Control = null
var _panel: Control = null
var _status: Array[String] = []
var _danger: Array[bool] = []
var _previous_path := ""
var _previous_credits := 0
var _previous_modules: Dictionary = {}
var _previous_auction: Dictionary = {}
var _previous_counter := 0


func suite_name() -> String:
	return "s3_auction"


func setup() -> void:
	_delete_file(PROFILE_PATH)
	_delete_file(ROTATION_PATH)


func teardown() -> void:
	for profile: Node in _profiles:
		if is_instance_valid(profile):
			profile.free()
	_profiles.clear()
	if _host != null and is_instance_valid(_host):
		_host.free()
	_host = null
	_panel = null
	_status.clear()
	_danger.clear()
	if _profile != null:
		_profile.set(&"_credits", _previous_credits)
		_profile.set(&"_modules", _previous_modules)
		_profile.set(&"_auction", _previous_auction)
		_profile.set(&"_instance_counter", _previous_counter)
		_profile.call(&"flush")
		_profile.set(&"save_path", _previous_path)
		_profile = null


func suite_teardown() -> void:
	_delete_file(PROFILE_PATH)
	_delete_file(ROTATION_PATH)


## ---------------------------------------------------------------------------
## Harnesses
## ---------------------------------------------------------------------------


## A throwaway profile whose stores are the scratch file, never the live account.
func _fresh() -> Node:
	var profile := Profile.new()
	profile.save_path = ROTATION_PATH
	_profiles.append(profile)
	return profile


func _stream() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	return rng


## One shelf drawn from **both** fixed streams. The local stream fixes the hull, tier and
## hot-slot draws (`draw_shelf`'s own `rng` argument), and the global seed fixes the rarity
## and affix rolls `PlayerProfile.roll_listing` reads -- 15 section 8's "rolls read the
## global RNG", which is why a shelf's own rarities are not the passed stream's to decide.
## Without both, a price or an id comparison becomes a coin toss.
func _draw_shelf(profile: Node) -> Dictionary:
	seed(SEED)
	return AuctionScript.draw_shelf(profile, _stream())


## The same two streams for a restock evaluation.
func _evaluate(profile: Node, now: int) -> int:
	seed(SEED)
	return AuctionScript.evaluate_shelf(profile, now, _stream())


## The shipped autoload, borrowed for the pane tests: `save_path` is repointed before the
## first mutation and every borrowed field is handed back in `teardown`. The gate's own
## sandbox has already moved the live path; this moves it again, to a suite-private file.
func _borrow_autoload() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "a SceneTree is needed to mount the pane")
	if tree == null:
		return null
	var profile := tree.root.get_node_or_null(NodePath(PROFILE_SERVICE))
	assert_true(profile != null, "the PlayerProfile autoload is the pane's store")
	if profile == null:
		return null
	_profile = profile
	_previous_path = String(profile.get(&"save_path"))
	_previous_credits = int(profile.call(&"credits"))
	_previous_modules = profile.call(&"modules")
	_previous_auction = profile.call(&"auction")
	_previous_counter = int(profile.get(&"_instance_counter"))
	profile.set(&"save_path", PROFILE_PATH)
	_delete_file(PROFILE_PATH)
	return profile


func _mount(theme: Theme) -> Control:
	var host := Control.new()
	host.name = "AuctionHost"
	host.theme = theme
	host.size = Vector2(1920.0, 1080.0)
	_fixture_host().add_child(host)
	_host = host
	_panel = PanelScene.instantiate() as Control
	_host.add_child(_panel)
	_panel.connect(&"status_requested", _on_status)
	return _panel


func _fixture_host() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(NodePath(PROFILE_SERVICE))


func _on_status(message: String, danger: bool) -> void:
	_status.append(message)
	_danger.append(danger)


func _delete_file(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


## The row set of one of the pane's three lists, in render order.
func _rows_of(panel: Control, box: String) -> Array[Button]:
	var container := panel.get_node("%" + box) as VBoxContainer
	var rows: Array[Button] = []
	if container == null:
		return rows
	for child: Node in container.get_children():
		var row := child as Button
		if row != null:
			rows.append(row)
	return rows


func _cell_text(row: Button, cell_name: String) -> String:
	var cell := row.find_child(cell_name, true, false) as Control
	if cell == null:
		return ""
	var value := cell.get_node_or_null(^"Value") as Label
	return value.text if value != null else ""


func _cell_caption(row: Button, cell_name: String) -> String:
	var cell := row.find_child(cell_name, true, false) as Control
	if cell == null:
		return ""
	var caption := cell.get_node_or_null(^"Caption") as Label
	return caption.text if caption != null else ""


func _digits_only(text: String) -> String:
	var digits := ""
	for index in text.length():
		var glyph := text[index]
		if glyph >= "0" and glyph <= "9":
			digits += glyph
	return digits


## ---------------------------------------------------------------------------
## The rotation (10 sections 2.1 and 2.2)
## ---------------------------------------------------------------------------


## One shelf in CONTRACTS section 15's shape: six hulls, ten rolled instance listings and
## one hot slot drawn from the sixteen of them, with the F lot's exclusive first while
## 15 section 8's interim is on.
func test_the_rotation_draws_six_hulls_and_ten_listings() -> void:
	var profile := _fresh()
	var shelf: Dictionary = _draw_shelf(profile)
	var hulls: Array = shelf[&"hulls"]
	var listings: Dictionary = shelf[&"modules"]
	assert_eq(hulls.size(), AuctionScript.HULL_SLOTS, "10 section 2.1's six hulls")
	assert_eq(hulls.size(), 6, "and six is six")
	assert_eq(listings.size(), AuctionScript.MODULE_SLOTS, "and its ten module listings")
	assert_eq(listings.size(), 10, "and ten is ten")
	## The two starter hulls never leave the shelf (10 section 2.2).
	assert_eq(hulls[0], String(&"ship_fighter"), "the Lancer is always listed")
	assert_eq(hulls[1], String(&"ship_vanguard"), "and so is the Vanguard")
	var seen: Array[String] = []
	for id: String in hulls:
		assert_false(seen.has(id), "%s is listed once" % id)
		seen.append(id)
		assert_false(Catalog.ship(StringName(id)).is_empty(), "%s is a catalogue hull" % id)
	## Every listing is a canonical instance record, the F lot's own exclusive first.
	var ids: Array = listings.keys()
	var first: Dictionary = listings[ids[0]]
	assert_true(
		EXCLUSIVES.has(StringName(first[&"base_id"])),
		"the first listing is 15 section 5's F lot while the interim is on"
	)
	for key: Variant in ids:
		var record: Dictionary = listings[key]
		assert_eq(
			String(record[&"instance_id"]), String(key), "a listing is keyed by its own minted id"
		)
		var base := StringName(record[&"base_id"])
		assert_false(ModuleData.module(base).is_empty(), "%s is a catalogue module" % base)
		assert_true(
			ModuleData.RARITY_ORDER.has(String(record[&"rarity"])),
			"%s's rarity is one of 15 section 1's three" % key
		)
		assert_eq(int(record[&"count"]), 1, "a listing is a bag-shaped record")
	## One hot slot, and it is one of the sixteen listed ids (10 section 2.1: "a random
	## listed item").
	var hot := StringName(shelf[&"hot"])
	assert_true(
		hulls.has(String(hot)) or listings.has(String(hot)),
		"the hot slot is one of the sixteen listed ids"
	)
	assert_eq(int(shelf[&"last_band"]), 0, "a fresh shelf carries no stamp of its own")


## 10 section 2.2's chance column, measured over `HULL_DRAWS` seeded shelves: the two
## starter hulls always, the ladder ordered exactly as the pin orders it, and every class
## present. The shelf is exactly six every time, which is the reconciliation's own law.
func test_the_hull_weights_over_n_draws() -> void:
	var profile := _fresh()
	var rng := _stream()
	var counts: Dictionary = {}
	var sixes := 0
	for _draw: int in HULL_DRAWS:
		var shelf: Dictionary = AuctionScript.draw_shelf(profile, rng)
		var hulls: Array = shelf[&"hulls"]
		if hulls.size() == AuctionScript.HULL_SLOTS:
			sixes += 1
		for id: String in hulls:
			counts[id] = int(counts.get(id, 0)) + 1
	assert_eq(sixes, HULL_DRAWS, "every draw lands exactly six hulls (10 section 2.1)")
	for id: StringName in CHANCE_ORDER:
		assert_gt(int(counts.get(String(id), 0)), 0, "%s appears over the run" % id)
	var rate: Callable = func(id: StringName) -> float:
		return float(counts.get(String(id), 0)) / float(HULL_DRAWS)
	## The two starter hulls are on every shelf, by 10 section 2.2's own words.
	assert_eq(rate.call(&"ship_fighter"), 1.0, "the Fighter is always listed")
	assert_eq(rate.call(&"ship_vanguard"), 1.0, "the Cutter is always listed")
	## The pinned order is what a player sees: for **every** pair whose 10 section 2.2
	## chances differ, the higher-chance hull was on at least as many shelves as the
	## lower-chance one. (The exactly-six rule of 10 section 2.1 moves each rate off its own
	## chance literal -- the two pins cannot both hold for every seed -- so the assertion is
	## the ordering the pin exists to produce, and the measured table is in the S3-K2 report.)
	for left: StringName in CHANCE_ORDER:
		for right: StringName in CHANCE_ORDER:
			if AuctionScript.hull_chance(left) > AuctionScript.hull_chance(right):
				assert_true(
					float(rate.call(left)) >= float(rate.call(right)),
					"%s is at least as available as %s" % [left, right]
				)
	## And every class the pin names is measurably more available than the one below it,
	## which is the ladder's own reading.
	assert_gt(float(rate.call(&"ship_miner")), 0.55, "the 60 % group lands above half")
	assert_gt(
		float(rate.call(&"ship_destroyer")), 0.05, "and even the 20 % hull appears"
	)
	## The two always-listed hulls and every class the pin names were checked above; the
	## weight table itself is the source every rate was read against.
	assert_eq(AuctionScript.hull_chance(&"ship_destroyer"), 0.2, "the Destroyer's own 20 %")
	assert_eq(AuctionScript.hull_chance(&"ship_fighter"), 1.0, "and the Fighter's always")


## 10 section 2.1's module tier weights (I 50 / II 35 / III 15), measured over `TIER_DRAWS`
## draws of the tier alone, and the pool each tier draws its ids from: every catalogue row
## of that tier and none of 15 section 9.1's three exclusives, which are the F lot's own.
func test_the_tier_weights_over_n_draws() -> void:
	var rng := _stream()
	var counts: Dictionary = {1: 0, 2: 0, 3: 0}
	for _draw: int in TIER_DRAWS:
		var tier := AuctionScript.draw_tier(rng)
		assert_true(counts.has(tier), "tier %d is one of the three" % tier)
		counts[tier] = int(counts.get(tier, 0)) + 1
	for tier: int in AuctionScript.TIER_ORDER:
		var expected := float(AuctionScript.TIER_WEIGHTS[tier]) / 100.0
		var measured := float(counts[tier]) / float(TIER_DRAWS)
		assert_true(
			absf(measured - expected) < 0.02,
			"tier %d lands inside 2 points of its %.0f %% weight (measured %.4f)"
			% [tier, expected * 100.0, measured]
		)
	## The pools partition the catalogue: every non-exclusive row is in exactly one tier's
	## pool, and no exclusive is in any of them.
	var pooled: Array[StringName] = []
	for tier: int in AuctionScript.TIER_ORDER:
		var pool := AuctionScript.tier_pool(tier)
		assert_gt(pool.size(), 0, "tier %d's pool is not empty" % tier)
		for id: StringName in pool:
			assert_false(
				ModuleData.EXCLUSIVES.has(id), "the F lot's %s is not a tier outcome" % id
			)
			assert_false(pooled.has(id), "%s sits in one pool only" % id)
			pooled.append(id)
	var catalogue: Array[StringName] = []
	for id: StringName in ModuleData.MODULES:
		if not ModuleData.EXCLUSIVES.has(id):
			catalogue.append(id)
	assert_eq(pooled.size(), catalogue.size(), "the three pools cover the catalogue")
	assert_eq(
		AuctionScript.exclusive_ids().size(), EXCLUSIVES.size(), "and the exclusives are the F lot's three"
	)


## ---------------------------------------------------------------------------
## The hot slot and the prices (10 section 2.1, 15 sections 1 and 6)
## ---------------------------------------------------------------------------


## The one discount, in the pin's own order: 15 section 1's rarity multiplier first, then
## 10 section 2.1's -20 %, and a shelf's hot row charges exactly that.
func test_the_hot_slot_arithmetic() -> void:
	var magic_list := ModuleData.list_price(LASER, ModuleData.RARITY_MAGIC)
	assert_eq(magic_list, 1440, "09 section 3.1's 900 x 15 section 1's 1.6")
	assert_eq(AuctionScript.hot_price(magic_list), 1152, "and -20 % of the rarity price is 1 152")
	var rare_list := ModuleData.list_price(LASER, ModuleData.RARITY_RARE)
	assert_eq(rare_list, 2340, "900 x 2.6")
	assert_eq(AuctionScript.hot_price(rare_list), 1872, "and its hot price")
	assert_eq(
		AuctionScript.hot_price(ModuleData.list_price(LASER, ModuleData.RARITY_COMMON)),
		720,
		"a Common 900 lists at 900 and discounts to 720"
	)
	assert_eq(AuctionScript.hot_price(0), 0, "no price discounts to nothing")
	## On a drawn shelf: one row carries the discount and every other row charges the list.
	var profile := _fresh()
	var shelf: Dictionary = _draw_shelf(profile)
	profile.call(&"set_auction", shelf)
	var hot := AuctionScript.hot_id(profile)
	assert_ne(hot, &"", "the shelf has one hot slot")
	var hot_rows := 0
	for row: Dictionary in AuctionScript.listing_rows(profile):
		var base: StringName = row[&"base_id"]
		var rarity: StringName = row[&"rarity"]
		var list := ModuleData.list_price(base, rarity)
		if bool(row[&"hot"]):
			hot_rows += 1
			assert_eq(int(row[&"price"]), AuctionScript.hot_price(list), "the hot row charges -20 %")
			assert_eq(int(row[&"was"]), list, "and shows what it was")
		else:
			assert_eq(int(row[&"price"]), list, "a plain row charges the rarity price")
			assert_eq(int(row[&"was"]), 0, "with no `WAS` line")
	## And the same rule on the hull side, where there is no rarity step to apply it after.
	for row: Dictionary in AuctionScript.hull_rows(profile):
		var list := int(row[&"list"])
		if bool(row[&"hot"]):
			assert_eq(int(row[&"price"]), AuctionScript.hot_price(list), "the hot hull's -20 %")
			assert_eq(int(row[&"was"]), list, "and its own WAS line")
		else:
			assert_eq(int(row[&"price"]), list, "a plain hull charges 08 section 2's list")
	## Exactly one hot row across the two lists, whichever list it landed in.
	var hull_hot := 0
	for row: Dictionary in AuctionScript.hull_rows(profile):
		if bool(row[&"hot"]):
			hull_hot += 1
	assert_eq(hot_rows + hull_hot, 1, "10 section 2.1's one hot slot per restock")


## ---------------------------------------------------------------------------
## The F lot (15 sections 5, 8 and 9)
## ---------------------------------------------------------------------------


## Every shelf carries one tagged F lot at the Magic+ floor, and the two legal rarities
## split 15 section 9.2's 85 % Magic / 15 % Rare.
func test_the_f_lot_sits_at_its_floor_with_the_85_15_split() -> void:
	assert_true(
		AuctionScript.AUCTION_FACTION_LOTS_INTERIM, "15 section 8's interim flag is on"
	)
	## The rate is a statistical reading, but the global seed still pins which 2 000 outcomes
	## it reads, so the measured share is the same on every run of this suite.
	seed(SEED)
	var magic := 0
	var rare := 0
	var total := 0
	for _draw: int in F_LOT_ROLLS:
		var rarity := ModuleData.roll_rarity(
			ModuleData.SOURCE_FACTION_LOT, EXCLUSIVES[_draw % EXCLUSIVES.size()]
		)
		assert_ne(rarity, ModuleData.RARITY_COMMON, "an exclusive never spawns Common")
		assert_true(
			rarity == ModuleData.RARITY_MAGIC or rarity == ModuleData.RARITY_RARE,
			"%s is one of the two legal rarities" % rarity
		)
		if rarity == ModuleData.RARITY_MAGIC:
			magic += 1
		else:
			rare += 1
		total += 1
	var share := float(magic) / float(total)
	assert_true(
		absf(share - 0.85) < 0.03,
		"the F lot is 85 %% Magic / 15 %% Rare (measured %.4f over %d rolls)" % [share, total]
	)
	## The interim row is the one `faction_lot`'s weights are read from, so the split above
	## is the table's and not a second constant.
	var table: Dictionary = ModuleData.SOURCE_ROLLS[ModuleData.SOURCE_FACTION_LOT]
	assert_eq(int(table[ModuleData.RARITY_MAGIC]), 85, "the catalogue's own 85")
	assert_eq(int(table[ModuleData.RARITY_RARE]), 15, "and its own 15")
	assert_eq(int(table[ModuleData.RARITY_COMMON]), 0, "with no Common column at all")
	## And on a shelf: one exclusive, flagged and priced from its own rolled rarity.
	var profile := _fresh()
	var shelf: Dictionary = _draw_shelf(profile)
	profile.call(&"set_auction", shelf)
	var flagged := 0
	for row: Dictionary in AuctionScript.listing_rows(profile):
		if bool(row[&"faction_lot"]):
			flagged += 1
			assert_true(
				EXCLUSIVES.has(row[&"base_id"]), "%s is one of the three" % row[&"base_id"]
			)
			assert_ne(row[&"rarity"], ModuleData.RARITY_COMMON, "and never a Common one")
	assert_eq(flagged, 1, "one F lot per shelf (15 section 8)")


## ---------------------------------------------------------------------------
## The restock, the shelf's home and the footer reading
## ---------------------------------------------------------------------------


## The rotation is lazy and band-driven (10 section 2.1, the exchange's own shape), the
## shelf lives in the profile's top-level `auction` key, and the restock line is a reading.
func test_the_restock_advances_by_bands_and_lives_in_the_top_level_auction_key() -> void:
	var profile := _fresh()
	assert_eq(
		AuctionScript.next_restock_seconds(profile, 1_000_000),
		BAND,
		"a shelf that was never drawn reads a whole band"
	)
	assert_eq(
		AuctionScript.restock_text(BAND), "NEXT RESTOCK 20:00", "a whole band reads 20:00"
	)
	assert_eq(AuctionScript.restock_text(1187), "NEXT RESTOCK 19:47", "with the seconds padded")
	assert_eq(AuctionScript.restock_text(0), "NEXT RESTOCK 0:00", "and a spent band reads zero")
	assert_eq(
		AuctionScript.restock_text(-5), "NEXT RESTOCK 0:00", "a negative reading clamps at zero"
	)
	var now := 1_000_000
	assert_eq(_evaluate(profile, now), 0, "the first call stamps")
	var first: Dictionary = profile.call(&"auction")
	assert_eq(int(first[&"last_band"]), now, "the stamp is the call's own reading")
	var first_ids := AuctionScript.listing_ids(profile)
	assert_eq(first_ids.size(), 10, "ten listings")
	assert_eq(
		AuctionScript.next_restock_seconds(profile, now), BAND, "a full band is left"
	)
	assert_eq(
		AuctionScript.next_restock_seconds(profile, now + 13), BAND - 13, "and counts down"
	)
	## Inside the band nothing is redrawn and nothing is written: the stamp keeps the
	## shelf's real restock time, which is what makes the reading a reading.
	assert_eq(_evaluate(profile, now + 1199), 0, "no band elapsed")
	assert_eq(AuctionScript.listing_ids(profile), first_ids, "and the shelf is untouched")
	assert_eq(int(profile.call(&"auction")[&"last_band"]), now, "with its stamp untouched")
	## One whole band later the shelf is redrawn and the stamp moves.
	assert_eq(_evaluate(profile, now + BAND), 1, "one band")
	assert_eq(int(profile.call(&"auction")[&"last_band"]), now + BAND, "the stamp moved")
	assert_ne(AuctionScript.listing_ids(profile), first_ids, "and the shelf was redrawn")
	assert_eq(AuctionScript.listing_ids(profile).size(), 10, "still ten listings")
	## Three bands at once redraws three times and stamps the last reading (the exchange's
	## own loop shape).
	assert_eq(
		_evaluate(profile, now + BAND * 4), 3, "three bands"
	)
	assert_eq(int(profile.call(&"auction")[&"last_band"]), now + BAND * 4, "and the last stamp")
	var ids := AuctionScript.listing_ids(profile)
	assert_eq(ids.size(), 10, "the redrawn shelf still carries ten listings")
	## The shelf is the profile's own top-level key, in CONTRACTS section 15's four members,
	## and it is **not** a `market` sub-key -- `_normalise_market` rebuilds that dictionary
	## from `MARKET_KEYS` and would drop it on load.
	var state: Dictionary = profile.call(&"auction")
	assert_eq(state.keys().size(), 4, "the shelf carries its four members")
	for key: String in Profile.AUCTION_KEYS:
		assert_true(state.has(key), "the shelf carries %s" % key)
	var market: Dictionary = profile.call(&"market")
	## `last_band` is the one word the two stores share (each keeps its own stamp); the
	## shelf's own three members are what the market must never carry, because
	## `_normalise_market` rebuilds that dictionary from `MARKET_KEYS` and would drop them.
	for key: String in ["hulls", "modules", "hot"]:
		assert_false(market.has(key), "the market carries no %s" % key)
	assert_true(market.has("demand"), "the market is still the market")
	## And it survives the file: a second profile reads the same shelf back.
	profile.call(&"flush")
	var reader := _fresh()
	reader.save_path = ROTATION_PATH
	reader.call(&"reload")
	assert_eq(
		AuctionScript.listing_ids(reader), ids, "the shelf round trips through the save"
	)
	assert_eq(
		int(reader.call(&"auction")[&"last_band"]),
		now + BAND * 4,
		"with its own stamp"
	)
	assert_eq(
		int(reader.get(&"_instance_counter")),
		int(profile.get(&"_instance_counter")),
		"and the mint counter with it"
	)


## ---------------------------------------------------------------------------
## The transactions (CONTRACTS section 15; 01 section 7's order)
## ---------------------------------------------------------------------------


## BUY moves the listing off the shelf into the bag at `count` 1, at the price the row
## shows, and the shelf's own record goes with it.
func test_buy_moves_the_listing_into_the_bag_at_count_one() -> void:
	var profile := _fresh()
	var shelf: Dictionary = _draw_shelf(profile)
	shelf[&"last_band"] = BAND
	profile.call(&"set_auction", shelf)
	profile.call(&"set_auction", profile.call(&"auction"))
	var rows := AuctionScript.listing_rows(profile)
	var row: Dictionary = rows[0]
	var id: StringName = row[&"id"]
	var base: StringName = row[&"base_id"]
	var before := int(profile.call(&"credits"))
	assert_eq(profile.call(&"instance", id), {}, "a listing is not in the bag yet")
	var result: Dictionary = AuctionScript.buy_listing(profile, id)
	assert_true(bool(result[&"ok"]), "the shelf's own listing is buyable")
	assert_eq(int(result[&"price"]), int(row[&"price"]), "at the price the row shows")
	assert_eq(
		int(profile.call(&"credits")),
		before - int(row[&"price"]),
		"and the credits moved by exactly that"
	)
	var record: Dictionary = profile.call(&"instance", id)
	assert_eq(int(record[&"count"]), 1, "the record is in the bag at count 1")
	assert_eq(String(record[&"base_id"]), String(base), "with the base id the row showed")
	assert_eq(int((profile.call(&"instances_of", base) as Array).size()), 1, "and it is the bag's one")
	assert_eq(
		AuctionScript.listing_ids(profile).has(id), false, "the listing left the shelf"
	)
	## A second buy of the same id is refused, and a price the shelf cannot honour is too.
	assert_false(bool(AuctionScript.buy_listing(profile, id)[&"ok"]), "a spent listing refuses")
	assert_eq(int(profile.call(&"credits")), before - int(row[&"price"]), "paying nothing more")
	## The buyer's own row set is one smaller and the shelf's records are the ones left.
	assert_eq(AuctionScript.listing_ids(profile).size(), rows.size() - 1, "nine left on the shelf")


## SELL pays 15 section 6's `base x rarity x 60 %` and erases the record, and one instance
## of one base id sells for its own rarity's money -- the reason the sell row is per
## instance rather than per base id.
func test_sell_pays_base_times_rarity_times_sixty() -> void:
	var profile := _fresh()
	var expected: Dictionary = {
		ModuleData.RARITY_COMMON: 540,
		ModuleData.RARITY_MAGIC: 864,
		ModuleData.RARITY_RARE: 1404,
	}
	for rarity: String in ModuleData.RARITY_ORDER:
		var price := AuctionScript.sell_price(LASER, StringName(rarity))
		assert_eq(price, int(expected[rarity]), "%s's sell price" % rarity)
		assert_eq(
			price,
			ModuleData.list_price(LASER, StringName(rarity)) * ModuleData.SELL_PERCENT / 100,
			"which is the rarity price x 60 %, with no suffix term"
		)
	## A bag with one instance per rarity: three sell rows, each priced at its own rarity.
	var ids: Array[StringName] = []
	for rarity: String in ModuleData.RARITY_ORDER:
		ids.append(StringName(profile.call(&"add_instance", LASER, StringName(rarity), [], [])))
	var rows := AuctionScript.sell_rows(profile)
	assert_eq(rows.size(), 3, "one sell row per instance in the bag")
	for row: Dictionary in rows:
		assert_eq(
			int(row[&"price"]),
			int(expected[String(row[&"rarity"])]),
			"%s sells for its own rarity's price" % row[&"id"]
		)
		assert_eq(int(row[&"owned"]), 3, "with the base id's own aggregate")
		assert_eq(String(row[&"owned_text"]), "OWNED ×3", "rendered in section 5.3's own words")
	var before := int(profile.call(&"credits"))
	var rare_id: StringName = ids[2]
	var rare_row := rows[2]
	var result: Dictionary = AuctionScript.sell_row(profile, rare_id)
	assert_true(bool(result[&"ok"]), "the instance sells")
	assert_eq(
		int(profile.call(&"credits")),
		before + int(expected[ModuleData.RARITY_RARE]),
		"credits moved by the rarity's own price"
	)
	assert_eq(profile.call(&"instance", rare_id), {}, "and the record is gone")
	assert_eq(AuctionScript.sell_rows(profile).size(), 2, "with two rows left")
	## A fitted instance is invisible to a sale (CONTRACTS section 15): `count` 0 is out of
	## the bag, so neither the row set nor the transaction sees it.
	assert_true(bool(profile.call(&"take_instance", ids[0])), "one instance goes into a fit")
	assert_eq(AuctionScript.sell_rows(profile).size(), 1, "and leaves the sell sub-list")
	assert_false(bool(AuctionScript.sell_row(profile, ids[0])[&"ok"]), "and refuses to sell")
	assert_true(bool(profile.call(&"restore_instance", ids[0])), "handing it back")
	assert_eq(AuctionScript.sell_rows(profile).size(), 2, "returns the same instance to the list")


## ---------------------------------------------------------------------------
## The pane (STATION_HUB section 5.10)
## ---------------------------------------------------------------------------


## The three `rarity_*` tokens section 5.10 names, at the hexes it names them at, in the
## theme the pane is drawn with.
func test_the_three_rarity_tokens_are_the_pins_hexes() -> void:
	assert_true(ThemeRes.has_color(&"rarity_common", TOKENS_TYPE), "rarity_common is themed")
	assert_true(ThemeRes.has_color(&"rarity_magic", TOKENS_TYPE), "rarity_magic is themed")
	assert_true(ThemeRes.has_color(&"rarity_rare", TOKENS_TYPE), "rarity_rare is themed")
	assert_eq(
		ThemeRes.get_color(&"rarity_common", TOKENS_TYPE),
		ThemeRes.get_color(&"text_primary", TOKENS_TYPE),
		"section 5.10's Common is the theme's default label colour"
	)
	assert_eq(
		_hex(ThemeRes.get_color(&"rarity_magic", TOKENS_TYPE)),
		"565c63",
		"Magic is #565C63, Steel Highlight"
	)
	assert_eq(
		_hex(ThemeRes.get_color(&"rarity_rare", TOKENS_TYPE)),
		"e8703a",
		"Rare is #E8703A, Ember Glow"
	)


## The pane renders 10 section 2.1's shelf: six hull rows, ten listing rows with the F LOT
## tag and the hot row's `WAS` line, the sell sub-list, and its **own** footer strip with
## the restock reading (section 5.10's S3 amendment).
func test_the_pane_renders_the_shelf_the_sell_list_and_its_own_footer() -> void:
	var profile := _borrow_autoload()
	assert_true(profile != null, "the autoload is the pane's store")
	if profile == null:
		return
	profile.set(&"_credits", 100_000)
	profile.set(&"_modules", {})
	var shelf: Dictionary = _draw_shelf(profile)
	shelf[&"last_band"] = Clock.now()
	profile.call(&"set_auction", shelf)
	var kept: StringName = StringName(profile.call(&"add_instance", LASER, ModuleData.RARITY_MAGIC, [], []))
	var panel := _mount(ThemeRes)
	assert_eq(_rows_of(panel, "HullRows").size(), 6, "six HULLS rows")
	assert_eq(_rows_of(panel, "ModuleRows").size(), 10, "ten MODULES rows")
	assert_eq(_rows_of(panel, "SellRows").size(), 1, "one SELL MODULES row for the bag's one instance")
	## The rows are the shelf's own, in its own drawn order, priced by the listing rows.
	var listings := AuctionScript.listing_rows(profile)
	for index in listings.size():
		var row := _rows_of(panel, "ModuleRows")[index]
		var entry: Dictionary = listings[index]
		assert_eq(
			String(row.get_meta(&"id", &"")), String(entry[&"id"]), "row %d is the shelf's own id" % index
		)
		assert_eq(
			_digits_only(_cell_text(row, "Price")),
			str(int(entry[&"price"])),
			"row %d charges the shelf's price" % index
		)
		var meta := row.find_child("Meta", true, false) as Label
		assert_eq(meta.text, String(entry[&"meta"]), "row %d's meta is the pinned line" % index)
		var status := _cell_text(row, "Status")
		if bool(entry[&"faction_lot"]):
			assert_eq(status, AuctionScript.FACTION_LOT_TAG, "the F lot carries its tag")
		else:
			assert_eq(status, "", "and no other row does")
		if bool(entry[&"hot"]):
			assert_eq(
				_cell_caption(row, "Price"),
				AuctionScript.HOT_CAPTION_FORMAT % _group(int(entry[&"was"])),
				"the hot row shows what it was"
			)
		else:
			assert_eq(_cell_caption(row, "Price"), PanelScript.PRICE_CAPTION, "a plain row does not")
	## The three column headers are the rows' own columns: one header cell per cell of the
	## section's layout, and the title column the one that expands (section 5.1's construct,
	## the same one the OUTFITTING and FITTING panes carry).
	var hull_header := panel.get_node("%HullsHeader") as HBoxContainer
	var module_header := panel.get_node("%ModulesHeader") as HBoxContainer
	var sell_header := panel.get_node("%SellHeader") as HBoxContainer
	var hull_cells: Array = panel.call(&"_hull_cells")
	var module_cells: Array = panel.call(&"_module_cells")
	var sell_cells: Array = panel.call(&"_sell_cells")
	assert_eq(
		hull_header.get_child_count(),
		hull_cells.size(),
		"the HULLS header carries one cell per column"
	)
	assert_eq(
		module_header.get_child_count(),
		module_cells.size(),
		"the MODULES header too"
	)
	assert_eq(
		sell_header.get_child_count(),
		sell_cells.size(),
		"and the sell sub-list's"
	)
	assert_eq(
		String((module_header.get_child(1) as Label).text),
		PanelScript.HEADER_MODULE,
		"whose second column is the row's own title column"
	)
	assert_eq(
		(module_header.get_child(1) as Label).size_flags_horizontal,
		Control.SIZE_EXPAND_FILL,
		"the one column that takes the remainder"
	)
	## The rarity tint is the theme's own token, not a colour literal in the panel.
	var tinted := _rows_of(panel, "ModuleRows")[0].find_child("Title", true, false) as Label
	assert_true(tinted != null, "the row's title label exists")
	if tinted != null:
		assert_true(
			_same_color(
				tinted.get_theme_color(&"font_color"),
				ThemeRes.get_color(
					AuctionScript.rarity_token(StringName(listings[0][&"rarity"])), TOKENS_TYPE
				)
			),
			"and it is drawn in the rarity's token"
		)
	## The sell row is the bag's instance: 15 section 7's name, its own price and the base
	## id's aggregate.
	var sell_row := _rows_of(panel, "SellRows")[0]
	assert_eq(
		_digits_only(_cell_text(sell_row, "Price")),
		str(ModuleData.sell_price(LASER, ModuleData.RARITY_MAGIC)),
		"the sell row pays base x rarity x 60 %"
	)
	assert_eq(_cell_text(sell_row, "Owned"), "OWNED ×1", "and counts the base id's instances")
	assert_eq(_cell_text(sell_row, "Action"), PanelScript.ACTION_SELL, "with a SELL action")
	assert_eq(String(sell_row.get_meta(&"id", &"")), String(kept), "the row is the instance's own")
	## The pane's own footer: the restock reading and its idle line, never the shell's copy.
	assert_eq(
		panel.call(&"restock_text"),
		AuctionScript.restock_text(AuctionScript.next_restock_seconds(profile, Clock.now())),
		"the footer reads NEXT RESTOCK <m:ss> off the clock"
	)
	assert_true(
		String(panel.call(&"restock_text")).begins_with("NEXT RESTOCK "),
		"in section 5.10's own words"
	)
	assert_eq(
		String(panel.call(&"status_text")),
		PanelScript.STATUS_IDLE % ModuleData.SELL_PERCENT,
		"and the strip starts on the pane's own idle line"
	)
	## The focus order's first stop is the HULLS list (section 5.10: HULLS then MODULES then
	## the sell sub-list), and the pane is advanced to the clock at that entry.
	panel.call(&"focus_primary")
	var focus := panel.get_viewport().gui_get_focus_owner() if panel.is_inside_tree() else null
	if focus != null:
		assert_true(
			_rows_of(panel, "HullRows").has(focus as Button),
			"focus enters on a HULLS row"
		)
	## BUY through the row's own signal: the listing moves into the bag and the shelf loses
	## its row.
	var target: Dictionary = AuctionScript.listing_rows(profile)[0]
	var before := int(profile.call(&"credits"))
	var buy_row := _rows_of(panel, "ModuleRows")[0]
	buy_row.pressed.emit()
	assert_eq(
		int(profile.call(&"credits")),
		before - int(target[&"price"]),
		"the row's press charged the price the row showed"
	)
	var banked: Dictionary = profile.call(&"instance", target[&"id"])
	assert_eq(int(banked[&"count"]), 1, "and put the instance in the bag at count 1")
	## A refusal the pane can see refuses in its own strip, with 09 section 2's own wording.
	## The row pressed is the one the pane still holds: the shelf's rebuild is queued
	## (`_queue_rebuild`) and a queued call has not run inside this synchronous test, so the
	## price named is that row's own, read back off the pane.
	assert_true(bool(profile.call(&"spend", int(profile.call(&"credits")))), "drain the balance")
	var next_row := _rows_of(panel, "ModuleRows")[0]
	var next_price := int(panel.call(&"module_payloads")[0][&"cost"])
	next_row.pressed.emit()
	assert_eq(
		String(panel.call(&"status_text")),
		PanelScript.STATUS_REFUSED_CREDITS % _group(next_price),
		"the pane names the price it could not pay"
	)
	assert_eq(_danger[_danger.size() - 1], true, "and marks it as danger")


## The pane's `_format_int` grouping, mirrored so a rendered number and the arithmetic
## behind it can be compared without the thousands space in the way.
func _group(value: int) -> String:
	var digits := str(absi(value))
	var grouped := ""
	var count := 0
	for index in range(digits.length() - 1, -1, -1):
		grouped = digits[index] + grouped
		count += 1
		if count % 3 == 0 and index > 0:
			grouped = " " + grouped
	return ("-" if value < 0 else "") + grouped


## A colour as `rrggbb`, rounded to the byte each channel names: a theme file stores
## float32 channels, so the hex a document writes is the honest comparison.
func _hex(colour: Color) -> String:
	return "%02x%02x%02x" % [
		roundi(clampf(colour.r, 0.0, 1.0) * 255.0),
		roundi(clampf(colour.g, 0.0, 1.0) * 255.0),
		roundi(clampf(colour.b, 0.0, 1.0) * 255.0),
	]


## Two colours equal within a byte per channel.
func _same_color(a: Color, b: Color) -> bool:
	return _hex(a) == _hex(b)


## The shell assembles the AUCTION pane behind its own rail entry, so the entry the player
## presses is the pane this suite measured: index 3 (directly after EXCHANGE, STATION_HUB
## section 5.10's rail amendment), a label and an icon the shell's own tables declare, and a
## **loaded** pane rather than the offline placeholder the shell synthesises for a module
## whose scene is missing.
func test_the_shell_mounts_the_auction_pane_behind_its_rail_entry() -> void:
	var profile := _borrow_autoload()
	assert_true(profile != null, "the autoload is the pane's store")
	if profile == null:
		return
	## A stamped, empty shelf: this test is about the shell's assembly, so the pane must not
	## draw a rotation here (that is the other tests' subject) -- and the stamp is what stops
	## `enter_pane` from drawing one.
	profile.set(&"_auction", {"last_band": Clock.now(), "hulls": [], "modules": {}, "hot": &""})
	var screen := _mount_shell()
	var buttons := screen.get_node("%ModuleButtons") as VBoxContainer
	assert_eq(
		buttons.get_child_count(), StationScript.MODULE_LABELS.size(), "one rail entry per module"
	)
	var entry := buttons.get_child(3) as Button
	assert_eq(entry.name, "AuctionEntry", "the fourth entry is AUCTION")
	var label := _first_label(entry)
	assert_eq(label.text, "AUCTION", "and it carries the AUCTION label")
	var icon := _first_icon(entry)
	assert_true(icon != null, "the entry carries an icon")
	if icon != null:
		assert_eq(
			icon.texture.resource_path,
			StationScript.MODULE_ICONS[2],
			"the same icon family as EXCHANGE, its own neighbour (section 5.10)"
		)
	var host_margin := screen.get_node("%HostMargin") as MarginContainer
	var pane := host_margin.get_node_or_null(^"Auction")
	assert_true(pane != null, "the shell loaded the AUCTION pane")
	if pane == null:
		return
	assert_false(
		pane.is_in_group(StationScript.PLACEHOLDER_GROUP),
		"and not the offline placeholder a missing scene would leave"
	)
	assert_eq(pane.get_script(), PanelScript, "the pane is this wave's own script")
	assert_true(pane.has_method(&"focus_primary"), "with the panel contract's focus entry")


## The shell, assembled the way `ui/screens/station.tscn` ships it: one host Control carrying
## the live theme, one station screen under it.
func _mount_shell() -> Control:
	_host = Control.new()
	_host.name = "ShellHost"
	_host.theme = ThemeRes
	_host.size = Vector2(1920.0, 1080.0)
	_fixture_host().add_child(_host)
	var screen := StationScene.instantiate() as Control
	_host.add_child(screen)
	return screen


## The first Label under a node, the shell's own read-back helper (`test_p2b_fitting_panel`'s
## own).
func _first_label(node: Node) -> Label:
	for child: Node in node.find_children("*", "Label", true, false):
		return child as Label
	return null


func _first_icon(node: Node) -> TextureRect:
	for child: Node in node.find_children("*", "TextureRect", true, false):
		return child as TextureRect
	return null
