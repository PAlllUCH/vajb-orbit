@tool
extends McpTestSuite
## Suite s25_contracts: wave S25's contracts board - 14_station_services.md section 2 and
## section 6 plus its 2026-09-27 P3 block (R-S25-1) and its 2026-10-08 S28 block (the payout
## scaling), 12_factions.md section 3/4.1 plus its 2026-10-08 S24 block (V3's gate), and
## docs/design/STATION_HUB.md section 15.2 (the deck law, U3-U8).
##
## One row per pinned acceptance (A1-A8). The board's own numbers are computed from the
## shipped tables (`MineralCatalog`, `SectorRegistry.sector_tier`, `Exchange.sale_quote`) and
## the law's figures appear only as the expected side of a comparison.

const RegistryScript := preload("res://game/contract_registry.gd")
const StationRegistryScript := preload("res://game/station_registry.gd")
const SectorRegistryScript := preload("res://game/sector_registry.gd")
const ExchangeScript := preload("res://game/exchange.gd")
const MineralCatalogScript := preload("res://game/mineral_catalog.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const ProfileScript := preload("res://autoload/player_profile.gd")
const StationScene := preload("res://ui/screens/station.tscn")
const LaunchScript := preload("res://ui/station/launch_panel.gd")
const ContractsPanelScript := preload("res://ui/station/contracts_panel.gd")
const RefineryScript := preload("res://game/refinery.gd")
const NpcRegistryScript := preload("res://game/npc_registry.gd")
## The flight scene's wreck ledger is a **static** (its window survives a scene rebuild),
## so a suite that drops loot must hand it back the way it found it.
const GameScript := preload("res://game/game.gd")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const GAME_SCENE := "res://game/game.tscn"

const PROFILE_SERVICE: StringName = &"PlayerProfile"
const PROFILE_PATH := "user://test_s25_contracts.cfg"
const HOST := Vector2(1920.0, 1080.0)
const NOW := 4000000
const STATION: StringName = &"s3_primary"
const STATION_SECTOR := 3

## 12 section 4.1's bands, at a value inside each.
const SHUNNED := -20
const OUTLAW := -80
const NEUTRAL := 0
const KNOWN := 20
const CHAMPION := 80

## 14's S28 block, verbatim: the two tabled columns, per sector tier 1-4.
const HUNT_TABLE: Array[int] = [800, 1100, 2200, 4400]
const ESCORT_TABLE: Array[int] = [1200, 1600, 3300, 6500]
## M11's derived Haul flat column (14's S28 block, reversal: 300 at every tier).
const HAUL_FLAT_TABLE: Array[int] = [300, 400, 800, 1600]

## STATION_HUB section 15.2's U3-U8 wordings, verbatim.
const NOTE_U3 := (
	"THE BOARD PAYS OVER THE EXCHANGE'S BUY PRICE — GOODS LOCK INTO ESCROW AT ACCEPT · "
	+ "CANCEL FEE 100 CR"
)
const HEADER_TYPE := "TYPE"
const HEADER_OBJECTIVE := "OBJECTIVE"
const HEADER_REWARD := "REWARD"
const HEADER_FACTION := "FACTION"
const EMPTY_NO_JOBS := "NO OPEN JOBS — NEW JOBS ROLL ON THE 20-MINUTE CLOCK"
const EMPTY_GATED := "REDEMPTION MUST PRECEDE EMPLOYMENT"
const CHIP_MAX := "MAX 3 ACTIVE"
const CHIP_STAGED := "STAGED"
const CAPTION_STAGED := "arenas arrive with S26"
const CANCEL_LABEL := "CANCEL · 100 CR FEE"
const CONFIRM_BODY := "CANCEL THIS CONTRACT? — 100 CR FEE · THE RESERVED GOODS UNLOCK."
const ESCROW_HEADER := "ESCROW — RESERVED FROM YOUR HOLD"

var _profile: ProfileScript = null
var _station: Control = null
var _scenes: Array[Node] = []
var _previous: Dictionary = {}


func suite_name() -> String:
	return "s25_contracts"


func suite_setup(_ctx: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		skip_suite("a SceneTree is needed to mount the station")
		return
	var service := tree.root.get_node_or_null(NodePath(PROFILE_SERVICE))
	if service == null:
		skip_suite("no PlayerProfile autoload to borrow")
		return
	_profile = service
	_previous = {
		&"save_path": String(_profile.get(&"save_path")),
		&"credits": int(_profile.call(&"credits")),
		&"cargo": (_profile.get(&"_cargo") as Dictionary).duplicate(true),
		&"contracts": (_profile.call(&"contracts") as Array).duplicate(true),
		&"standing": (_profile.call(&"standing") as Dictionary).duplicate(true),
		&"docked_station": StringName(_profile.call(&"docked_station")),
	}
	_profile.set(&"save_path", PROFILE_PATH)
	_delete_file(PROFILE_PATH)
	_wipe()


func suite_teardown() -> void:
	_free_station()
	for scene: Node in _scenes:
		if is_instance_valid(scene):
			scene.free()
	_scenes.clear()
	if _profile == null:
		return
	for key: StringName in _previous:
		var value: Variant = _previous[key]
		match key:
			&"save_path":
				_profile.call(&"flush")
				_profile.set(&"save_path", String(value))
			&"credits":
				_profile.set(&"_credits", int(value))
			&"cargo":
				_profile.set(&"_cargo", value)
			&"contracts":
				_profile.call(&"set_contracts", value)
			&"standing":
				_profile.call(&"set_standing", value)
			&"docked_station":
				_profile.call(&"set_docked_station", value)
	_profile.call(&"flush")
	_profile.set(&"save_path", String(_previous[&"save_path"]))
	_delete_file(PROFILE_PATH)
	_previous = {}
	_profile = null


func setup() -> void:
	_free_station()
	_wipe()


## A clean account: no contracts, no standing, no cargo, a full purse.
func _wipe() -> void:
	if _profile == null:
		return
	_profile.call(&"set_contracts", [])
	_profile.call(&"set_standing", {})
	_profile.call(&"set_docked_station", &"")
	_profile.set(&"_cargo", {})
	_profile.set(&"_credits", 50000)


func _free_station() -> void:
	if _station != null and is_instance_valid(_station):
		_station.get_parent().free()
	_station = null


func _delete_file(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(absolute):
		DirAccess.remove_absolute(absolute)


## A themed host inside the profile autoload (the runner calls every test from inside its
## own `_ready`, when `/root` is still busy), carrying the shipped station scene.
func _mount() -> Control:
	var host := Control.new()
	host.name = "S25Host"
	host.theme = ThemeRes
	host.size = HOST
	_profile.add_child(host)
	var screen := StationScene.instantiate() as Control
	host.add_child(screen)
	_station = screen
	return screen


func _station_row() -> Dictionary:
	return StationRegistryScript.station(STATION)


## A synthetic contract of one type, for the reward law's own arithmetic. Its reward and
## standing come from the registry's own doors, so a fixture cannot disagree with the law.
func _make(
	type: StringName,
	tier: int,
	faction: StringName = &"concord",
	item_id: StringName = &"",
	quantity: int = 0
) -> Dictionary:
	var row := {
		&"id": &"probe_%s_%d" % [String(type), tier],
		&"type": type,
		&"faction": faction,
		&"item_id": item_id,
		&"quantity": quantity,
		&"tier": tier,
		&"reward": 0,
		&"standing": RegistryScript.standing_for(type),
		&"escrow": {},
		&"staged": false,
	}
	row[&"reward"] = RegistryScript.reward(row)
	return row


## --------------------------------------------------------------- A1: the board


## A1: six rows (R-S25-1), seeded (a fixed seed answers the same board), rolling on the
## 20-minute clock, the four live types present, every row faction-tied to its target
## sector's owner and its objective sector-appropriate, and the Expedition seam row staged.
func test_a1_the_board_is_six_seeded_rows_on_the_clock() -> void:
	var row := _station_row()
	var board := RegistryScript.board(row, NEUTRAL, NOW)
	assert_eq(board.size(), RegistryScript.BOARD_SIZE, "six rows per board (R-S25-1)")
	assert_eq(board.size(), 6, "and six is the pinned number")
	var again := RegistryScript.board(row, NEUTRAL, NOW)
	assert_eq(_ids(again), _ids(board), "the same band answers the same board (seeded)")
	var next := RegistryScript.board(row, NEUTRAL, NOW + RegistryScript.Clock.BAND_SECONDS)
	assert_ne(_ids(next), _ids(board), "the next 20-minute band re-rolls it")
	assert_eq(
		RegistryScript.band_index(NOW), RegistryScript.band_index(NOW + 600),
		"a reading inside the band is the same band"
	)
	var types: Array[StringName] = []
	for entry: Dictionary in board:
		types.append(StringName(entry.get(&"type", &"")))
	for live: StringName in RegistryScript.LIVE_TYPES:
		assert_true(types.has(live), "%s is live on the board" % String(live))
	var staged := 0
	for entry: Dictionary in board:
		var target := int(entry.get(&"sector", 0))
		assert_eq(
			StringName(entry.get(&"faction", &"")),
			SectorRegistryScript.sector(
				SectorRegistryScript.sector_id_for(target)
			).get(&"owner", &""),
			"%s is tied to S%d's owner" % [String(entry.get(&"type", &"")), target]
		)
		if StringName(entry.get(&"type", &"")) == RegistryScript.TYPE_EXPEDITION:
			staged += 1
			assert_true(bool(entry.get(&"staged", false)), "the Expedition row is staged (U7)")
			continue
		assert_false(bool(entry.get(&"staged", false)), "a live row is not staged")
	assert_eq(staged, 1, "exactly one Expedition seam row (R-S25-1)")
	assert_eq(
		RegistryScript.board(StationRegistryScript.station(&"s7_primary"), NEUTRAL, NOW).size(),
		0,
		"a sector with no station row answers no board"
	)


## A1: the objectives are sector-appropriate - Hunt and Gather are local work (the docked
## sector), Haul and Escort route to a neighbouring sector that carries a station.
func test_a1_the_objectives_are_sector_appropriate() -> void:
	var board := RegistryScript.board(_station_row(), NEUTRAL, NOW)
	var neighbours: Array = SectorRegistryScript.sector(
		SectorRegistryScript.sector_id_for(STATION_SECTOR)
	).get(&"neighbours", [])
	var seen := {}
	for entry: Dictionary in board:
		var type := StringName(entry.get(&"type", &""))
		var target := int(entry.get(&"sector", 0))
		var objective := String(entry.get(&"objective", ""))
		match type:
			RegistryScript.TYPE_HUNT:
				seen[type] = true
				assert_eq(target, STATION_SECTOR, "Hunt stays in the docked sector")
				assert_eq(objective, "Destroy 5 pirates in S3", "Hunt's section 2 shape")
			RegistryScript.TYPE_GATHER:
				seen[type] = true
				assert_eq(target, STATION_SECTOR, "Gather works the local belt")
				assert_true(objective.ends_with(" ore (raw)"), "Gather's section 2 shape")
				assert_true(
					MineralCatalogScript.is_ore(StringName(entry.get(&"item_id", &""))),
					"Gather's item is a raw ore"
				)
			RegistryScript.TYPE_HAUL:
				seen[type] = true
				assert_true(neighbours.has(target), "Haul routes to a neighbouring sector")
				assert_true(
					MineralCatalogScript.is_ingot(StringName(entry.get(&"item_id", &""))),
					"Haul carries an ingot"
				)
				assert_eq(
					int(entry.get(&"quantity", 0)), RegistryScript.HAUL_QUANTITY,
					"Haul's quantity is section 2's own 40"
				)
				assert_true(
					objective.contains(String(entry.get(&"item_id", &""))),
					"the objective names the good"
				)
			RegistryScript.TYPE_ESCORT:
				seen[type] = true
				assert_true(neighbours.has(target), "Escort routes to a neighbouring sector")
				assert_eq(
					objective, "Protect convoy %d to S%d gate" % [int(entry.get(&"convoy", 0)), target],
					"Escort's section 2 shape"
				)
	assert_eq(seen.size(), 4, "the four live types all rolled")
	assert_eq(board.size() - 1, 5, "five live rows plus the Expedition seam (R-S25-1)")


## ------------------------------------------------------------- A2: the reward law


## A2: Hunt and Escort pay the S28 table at the target sector's tier (800 / 1 100 / 2 200 /
## 4 400 and 1 200 / 1 600 / 3 300 / 6 500), and Haul's derived flat column reads
## 300 / 400 / 800 / 1 600.
func test_a2_hunt_and_escort_pay_the_s28_table() -> void:
	for index in HUNT_TABLE.size():
		var tier := index + 1
		assert_eq(
			RegistryScript.reward(_make(RegistryScript.TYPE_HUNT, tier)), HUNT_TABLE[index],
			"Hunt at tier %d pays %d" % [tier, HUNT_TABLE[index]]
		)
		assert_eq(
			RegistryScript.reward(_make(RegistryScript.TYPE_ESCORT, tier)), ESCORT_TABLE[index],
			"Escort at tier %d pays %d" % [tier, ESCORT_TABLE[index]]
		)
		assert_eq(
			RegistryScript.scaled_flat(RegistryScript.HAUL_FLAT, tier), HAUL_FLAT_TABLE[index],
			"Haul's flat at tier %d reads %d" % [tier, HAUL_FLAT_TABLE[index]]
		)


## A2: Haul pays spot x1.25 plus its flat and Gather pays x1.4 ore value, both read through
## the exchange's one transaction quote, and every reward is a multiple of 100 CR.
func test_a2_haul_and_gather_read_the_exchange_and_round_to_100() -> void:
	var item: StringName = &"ingot_iron"
	var haul := _make(RegistryScript.TYPE_HAUL, 2, &"concord", item, RegistryScript.HAUL_QUANTITY)
	var demand := RegistryScript.demand_for(&"concord", item)
	var gross := int(
		ExchangeScript.sale_quote(
			ExchangeScript.baseline_of(item), demand, RegistryScript.HAUL_QUANTITY
		)[&"gross"]
	)
	assert_eq(RegistryScript.goods_gross(haul), gross, "the spot is the exchange's own quote")
	assert_eq(
		RegistryScript.reward(haul),
		RegistryScript.round_to_100(
			roundi(RegistryScript.HAUL_SPOT * float(gross))
			+ RegistryScript.scaled_flat(RegistryScript.HAUL_FLAT, 2)
		),
		"Haul = spot x1.25 + the tier's flat"
	)
	var gather := _make(
		RegistryScript.TYPE_GATHER, 2, &"concord", &"mineral_iron", RegistryScript.GATHER_QUANTITY
	)
	var ore_demand := RegistryScript.demand_for(&"concord", &"mineral_iron")
	var ore_gross := int(
		ExchangeScript.sale_quote(
			ExchangeScript.baseline_of(&"mineral_iron"), ore_demand, RegistryScript.GATHER_QUANTITY
		)[&"gross"]
	)
	assert_eq(
		RegistryScript.reward(gather),
		RegistryScript.round_to_100(roundi(RegistryScript.GATHER_ORE * float(ore_gross))),
		"Gather = the ore's value x1.4"
	)
	for sector in [1, 2, 3, 4, 5, 6]:
		for entry: Dictionary in RegistryScript.board(
			StationRegistryScript.primary_for(SectorRegistryScript.sector_id_for(sector)),
			NEUTRAL,
			NOW
		):
			if bool(entry.get(&"staged", false)):
				continue
			assert_eq(
				int(entry.get(&"reward", 0)) % RegistryScript.ROUND_UNIT, 0,
				"%s's reward is a multiple of 100 CR" % String(entry.get(&"type", &""))
			)
	assert_eq(
		RegistryScript.reward(_make(RegistryScript.TYPE_HUNT, 4)) % 100, 0,
		"the top tier's Hunt is a round figure too"
	)


## A2: 12 section 3's demand bias is applied (the same contract pays differently at two
## factions), and 12 section 4.1's Known hook adds its 5 % to the pay.
func test_a2_the_demand_bias_and_the_known_hook() -> void:
	assert_eq(RegistryScript.demand_bias(&"concord", &"ingot_iron"), 0.15, "Concord, T1-T2 ingots")
	assert_eq(RegistryScript.demand_bias(&"choir", &"ingot_iron"), -0.15, "the Choir, T1-T2")
	assert_eq(RegistryScript.demand_bias(&"choir", &"ingot_gold"), 0.25, "the Choir, T3-T4 ingots")
	assert_eq(RegistryScript.demand_bias(&"meridian", &"mineral_gold"), 0.10, "Meridian, T3 ore")
	assert_eq(RegistryScript.demand_bias(&"meridian", &"comp_scrap_1"), 0.20, "Meridian, components")
	assert_eq(RegistryScript.demand_bias(&"concord", &"comp_scrap_1"), -0.10, "Concord, components")
	assert_eq(RegistryScript.demand_bias(&"choir", &"comp_weap_3"), 0.25, "the Choir, exotic")
	assert_eq(RegistryScript.demand_bias(&"choir", &"mineral_iron"), -0.15, "and T1-T2 ore")
	assert_eq(
		RegistryScript.demand_bias(&"concord", &"mineral_cobalt"), 0.0,
		"a band the faction's row does not name stays unbiased"
	)
	var at_meridian := _make(
		RegistryScript.TYPE_HAUL, 3, &"meridian", &"ingot_gold", RegistryScript.HAUL_QUANTITY
	)
	var at_choir := _make(
		RegistryScript.TYPE_HAUL, 3, &"choir", &"ingot_gold", RegistryScript.HAUL_QUANTITY
	)
	assert_gt(
		RegistryScript.reward(at_choir), RegistryScript.reward(at_meridian),
		"hauling to the Choir pays differently than to Meridian (12 section 3)"
	)
	var hunt := _make(RegistryScript.TYPE_HUNT, 1)
	assert_eq(RegistryScript.pay(hunt, NEUTRAL), 800, "Neutral pays the board's price")
	assert_eq(RegistryScript.pay(hunt, KNOWN), 840, "Known pays +5 % (12 section 4.1)")
	assert_eq(RegistryScript.pay(hunt, CHAMPION), 840, "and so does Champion")
	assert_eq(RegistryScript.reward(hunt), 800, "the board's own price is unmoved")


## ------------------------------------------------------------ A3: the standing gates


## A3: Shunned and Outlaw see no board at all (V3's predicate), Champion sees the
## standing-order row, and the max-3 rule refuses the fourth accept.
func test_a3_the_gates_and_the_standing_order() -> void:
	assert_false(StationRegistryScript.contracts_visible(SHUNNED), "Shunned sees no contracts")
	assert_false(StationRegistryScript.contracts_visible(OUTLAW), "Outlaw sees no contracts")
	assert_true(StationRegistryScript.contracts_visible(NEUTRAL), "Neutral does")
	assert_eq(
		RegistryScript.board(_station_row(), SHUNNED, NOW).size(), 0, "a Shunned board is empty"
	)
	assert_eq(
		RegistryScript.board(_station_row(), OUTLAW, NOW).size(), 0, "an Outlaw board is empty"
	)
	var champion := RegistryScript.board(_station_row(), CHAMPION, NOW)
	assert_eq(champion.size(), 6, "the Champion's board is still six rows")
	var orders := 0
	for entry: Dictionary in champion:
		if bool(entry.get(&"standing_order", false)):
			orders += 1
			assert_eq(
				int(entry.get(&"reward", 0)) % RegistryScript.ROUND_UNIT, 0,
				"the standing order pays a round figure"
			)
	assert_eq(orders, 1, "one standing-order contract always available (12 section 4.1)")
	assert_eq(
		_ids(RegistryScript.board(_station_row(), CHAMPION, NOW)), _ids(champion),
		"and it is there every band"
	)
	var board := RegistryScript.board(_station_row(), NEUTRAL, NOW)
	var accepted := 0
	for index in 4:
		var row := _make(RegistryScript.TYPE_HUNT, 1)
		row[&"id"] = &"gate_%d" % index
		var result := RegistryScript.accept(_profile, _station_row(), NEUTRAL, row)
		if accepted < RegistryScript.MAX_ACTIVE:
			assert_true(bool(result[&"ok"]), "accept %d lands" % (accepted + 1))
			accepted += 1
		else:
			assert_false(bool(result[&"ok"]), "the fourth accept is refused")
			assert_eq(
				result[&"reason"], RegistryScript.REASON_FULL, "with the max-3 reason"
			)
	assert_eq(
		RegistryScript.active_count(_profile), RegistryScript.MAX_ACTIVE,
		"three active contracts at most (14 section 2)"
	)
	assert_eq(RegistryScript.MAX_ACTIVE, 3, "and three is the pinned number")
	assert_eq(
		RegistryScript.accept(_profile, _station_row(), NEUTRAL, board[0])[&"reason"],
		RegistryScript.REASON_FULL, "a fourth accept is refused at the door"
	)


## A3: the Expedition seam refuses accept until S26 flips it live.
func test_a3_the_expedition_seam_refuses() -> void:
	var board := RegistryScript.board(_station_row(), NEUTRAL, NOW)
	var staged := {}
	for entry: Dictionary in board:
		if bool(entry.get(&"staged", false)):
			staged = entry
	assert_false(staged.is_empty(), "the seam row is on the board")
	assert_eq(
		RegistryScript.accept(_profile, _station_row(), NEUTRAL, staged)[&"reason"],
		RegistryScript.REASON_STAGED, "and it refuses accept (R-S25-1's seam)"
	)
	assert_eq(
		RegistryScript.active_count(_profile), 0, "a refusal writes nothing"
	)


## ------------------------------------------------------------- A4: the escrow


## A4: accept reserves the goods off the manifest, cancel returns them for exactly 100 CR,
## and a double completion pays once.
func test_a4_accept_reserves_and_cancel_returns_for_100() -> void:
	var item: StringName = &"ingot_iron"
	var quantity := RegistryScript.HAUL_QUANTITY
	_profile.call(&"add_cargo", item, quantity)
	assert_eq(int(_profile.call(&"cargo_qty", item)), quantity, "the hold carries the stack")
	var haul := _make(RegistryScript.TYPE_HAUL, 2, &"concord", item, quantity)
	haul[&"id"] = &"c1"
	var result := RegistryScript.accept(_profile, _station_row(), NEUTRAL, haul)
	assert_true(bool(result[&"ok"]), "the accept lands")
	assert_eq(
		int(_profile.call(&"cargo_qty", item)), 0, "the goods leave the manifest at accept"
	)
	assert_eq(
		int((result[&"contract"] as Dictionary).get(&"escrow", {}).get(String(item), 0)),
		quantity,
		"and the record carries the reservation"
	)
	assert_eq(RegistryScript.active_count(_profile), 1, "one active contract")
	var before := int(_profile.call(&"credits"))
	var cancelled := RegistryScript.cancel(_profile, &"c1")
	assert_true(bool(cancelled[&"ok"]), "the cancel lands")
	assert_eq(int(cancelled[&"fee"]), RegistryScript.CANCEL_FEE, "the fee is section 2's")
	assert_eq(RegistryScript.CANCEL_FEE, 100, "exactly 100 CR")
	assert_eq(
		int(_profile.call(&"credits")), before - 100, "and it is charged exactly once"
	)
	assert_eq(
		int(_profile.call(&"cargo_qty", item)), quantity, "the reserved goods unlock"
	)
	assert_eq(RegistryScript.active_count(_profile), 0, "and the contract is gone")


## A4: a contract whose goods the hold does not carry is refused and writes nothing.
func test_a4_a_missing_stack_is_refused() -> void:
	var haul := _make(
		RegistryScript.TYPE_HAUL, 2, &"concord", &"ingot_iron", RegistryScript.HAUL_QUANTITY
	)
	var result := RegistryScript.accept(_profile, _station_row(), NEUTRAL, haul)
	assert_false(bool(result[&"ok"]), "an unbacked Haul is refused")
	assert_eq(
		result[&"reason"], RegistryScript.REASON_INSUFFICIENT_CARGO, "with the cargo reason"
	)
	assert_eq(RegistryScript.active_count(_profile), 0, "and nothing is written")


## A4: the completion door pays once - a second completion of the same id pays nothing.
func test_a4_a_double_completion_pays_once() -> void:
	var hunt := _make(RegistryScript.TYPE_HUNT, 1)
	hunt[&"id"] = &"c2"
	assert_true(
		bool(RegistryScript.accept(_profile, _station_row(), NEUTRAL, hunt)[&"ok"]),
		"the accept lands"
	)
	var before := int(_profile.call(&"credits"))
	var first := RegistryScript.complete(_profile, &"c2")
	assert_true(bool(first[&"ok"]), "the delivery pays")
	assert_eq(int(first[&"paid"]), 800, "the tier-1 Hunt row")
	assert_eq(int(_profile.call(&"credits")), before + 800, "and the purse moves once")
	assert_eq(
		int(_profile.call(&"standing_of", &"concord")),
		RegistryScript.standing_for(RegistryScript.TYPE_HUNT),
		"plus the row's standing"
	)
	assert_eq(
		RegistryScript.standing_for(RegistryScript.TYPE_HUNT),
		RegistryScript.STANDING_HUNT * RegistryScript.HUNT_COUNT,
		"14 section 2: Hunt pays +1 standing per kill, so its whole row files one per kill"
	)
	assert_eq(
		RegistryScript.standing_for(RegistryScript.TYPE_HUNT), 5,
		"which is the pin's own figure for the five the objective names"
	)
	var second := RegistryScript.complete(_profile, &"c2")
	assert_false(bool(second[&"ok"]), "the second completion is refused")
	assert_eq(int(second[&"paid"]), 0, "and pays nothing")
	assert_eq(int(_profile.call(&"credits")), before + 800, "the purse is unmoved")
	assert_eq(RegistryScript.active_count(_profile), 0, "the escrow is consumed once")


## A4 (F1): the dock is the board's goods half's production exit. A Haul closes at its own
## destination station and a Gather at the station it was taken at, both through the shell's
## own routed-to seam (`station.gd:on_route` -> `ContractRegistry.deliver_at`), both paying
## once and consuming the escrow rather than returning it.
func test_a4_a_dock_delivers_the_escrowed_stack() -> void:
	_profile.call(&"set_docked_station", STATION)
	var board := RegistryScript.board(_station_row(), NEUTRAL, NOW)
	var haul := _find_type(board, RegistryScript.TYPE_HAUL)
	var gather := _find_type(board, RegistryScript.TYPE_GATHER)
	assert_false(haul.is_empty(), "the board rolls a Haul")
	assert_false(gather.is_empty(), "the board rolls a Gather")
	var haul_item := StringName(haul.get(&"item_id", &""))
	var gather_item := StringName(gather.get(&"item_id", &""))
	_profile.call(&"add_cargo", haul_item, int(haul.get(&"quantity", 0)))
	_profile.call(&"add_cargo", gather_item, int(gather.get(&"quantity", 0)))
	assert_true(
		bool(RegistryScript.accept(_profile, _station_row(), NEUTRAL, haul)[&"ok"]),
		"the Haul is taken"
	)
	assert_true(
		bool(RegistryScript.accept(_profile, _station_row(), NEUTRAL, gather)[&"ok"]),
		"the Gather is taken"
	)
	assert_eq(RegistryScript.active_count(_profile), 2, "two contracts are active")
	var purse := int(_profile.call(&"credits"))
	## Docked at the accepting station: the Gather's own delivery site, and not the Haul's.
	var screen := _mount()
	screen.call(&"on_route", {})
	assert_true(
		RegistryScript.find(_profile, StringName(gather.get(&"id", &""))).is_empty(),
		"the Gather closed at the station it was taken at"
	)
	assert_eq(
		RegistryScript.active_count(_profile), 1, "and the Haul, bound elsewhere, is untouched"
	)
	assert_eq(
		int(_profile.call(&"credits")),
		purse + RegistryScript.reward(gather),
		"the Gather paid its own reward, once"
	)
	assert_eq(
		int(_profile.call(&"cargo_qty", gather_item)), 0,
		"and its escrow was consumed, not returned"
	)
	assert_eq(
		(screen.get_node("%StatusLabel") as Label).text,
		"CONTRACT DELIVERED · %d CR" % RegistryScript.reward(gather),
		"and the shell's own status strip reports the delivery"
	)
	## Docked at the Haul's own destination: the second exit, and the only one it answers to.
	_free_station()
	_profile.call(&"set_docked_station", StringName(haul.get(&"target_station", &"")))
	var destination := _mount()
	destination.call(&"on_route", {})
	assert_eq(RegistryScript.active_count(_profile), 0, "the Haul closed at its destination")
	assert_eq(
		int(_profile.call(&"credits")),
		purse + RegistryScript.reward(gather) + RegistryScript.reward(haul),
		"and paid its own reward"
	)
	assert_eq(int(_profile.call(&"cargo_qty", haul_item)), 0, "its escrow consumed too")
	destination.call(&"on_route", {})
	assert_eq(
		int(_profile.call(&"credits")),
		purse + RegistryScript.reward(gather) + RegistryScript.reward(haul),
		"a second dock at the same place pays nothing again"
	)


## A4 (F1): the Hunt row's own exit - the flight scene's kill seam credits one pirate per kill
## in the contract's own sector, and the fifth closes it for the row's pay and its standing.
## A hull that is not a pirate credits nothing (14 section 2's row says pirates).
func test_a4_a_hunt_closes_on_the_fifth_pirate() -> void:
	var game := _open_game()
	if game == null:
		skip("the flight scene is not loadable headless")
		return
	var sector := StringName(game.get(&"_sector_row_id"))
	var here := SectorRegistryScript.sector_number(sector)
	var row := StationRegistryScript.primary_for(sector)
	if row.is_empty():
		skip("the scene's sector carries no station row")
		return
	## The board's own local Hunt row, so the faction the completion files on and the key the
	## kill's own standing files on are the row's own tie (test_a1's "tied to S%d's owner").
	var hunt := _find_type(RegistryScript.board(row, NEUTRAL, NOW), RegistryScript.TYPE_HUNT)
	assert_false(hunt.is_empty(), "the board rolls a Hunt")
	hunt[&"id"] = &"runtime_hunt"
	assert_eq(int(hunt.get(&"sector", 0)), here, "the hunt's own sector is the scene's")
	assert_eq(int(hunt.get(&"count", 0)), RegistryScript.HUNT_COUNT, "for the five it names")
	assert_true(
		bool(RegistryScript.accept(_profile, row, NEUTRAL, hunt)[&"ok"]), "the hunt is taken"
	)
	var ledger: Array = GameScript._wreck_drops.duplicate(true)
	var purse := int(_profile.call(&"credits"))
	var victim := _stub_hull(&"pirate")
	var kill_standing := int(
		NpcRegistryScript.archetype(&"pirate").get(NpcRegistryScript.KEY_STANDING_ON_KILL, 0)
	)
	game.call(&"_on_npc_died", Vector2.ZERO, &"swarmer", _stub_hull(&"swarmer"))
	assert_eq(
		int(RegistryScript.find(_profile, &"runtime_hunt").get(&"count", 0)),
		RegistryScript.HUNT_COUNT,
		"a swarmer is not a pirate and credits nothing"
	)
	for index in RegistryScript.HUNT_COUNT - 1:
		game.call(&"_on_npc_died", Vector2.ZERO, &"pirate", victim)
		assert_eq(
			int(RegistryScript.find(_profile, &"runtime_hunt").get(&"count", 0)),
			RegistryScript.HUNT_COUNT - index - 1,
			"kill %d takes one pirate off the row" % (index + 1)
		)
		assert_eq(int(_profile.call(&"credits")), purse, "and pays nothing before the last")
	var faction := StringName(hunt.get(&"faction", &""))
	var standing_before := int(_profile.call(&"standing_of", faction))
	game.call(&"_on_npc_died", Vector2.ZERO, &"pirate", victim)
	assert_eq(RegistryScript.active_count(_profile), 0, "the fifth kill closes the contract")
	assert_eq(
		int(_profile.call(&"credits")), purse + HUNT_TABLE[0], "and pays the tier-1 row, once"
	)
	assert_eq(
		int(_profile.call(&"standing_of", faction)) - standing_before,
		RegistryScript.standing_for(RegistryScript.TYPE_HUNT) + kill_standing,
		"14 section 2's +1 standing per kill, beside the kill's own standing"
	)
	## The kill seam's own wreck ledger is a static; hand it back the way it was found.
	GameScript._wreck_drops.clear()
	GameScript._wreck_drops.append_array(ledger)


## ------------------------------------------------------------- A5: the escort loop


## A5: the convoy is 14 section 6's own - a Hauler-statted hull, 1-2 fighters, 50 % of the
## hold as visible cargo pods, the three-leg route and the corridor-midpoint ambush.
func test_a5_the_convoy_is_section_6s() -> void:
	var plan := RegistryScript.escort_plan(_make(RegistryScript.TYPE_ESCORT, 2))
	assert_eq(plan[&"hauler"], RegistryScript.escort_hauler(), "the hauler is the convoy hull")
	assert_true(int(plan[&"fighters"]) >= 1 and int(plan[&"fighters"]) <= 2, "1-2 fighters")
	assert_eq(
		int(plan[&"pods"]), roundi(0.5 * float(RegistryScript.escort_hold())),
		"50 % of the hold is filled with pods"
	)
	assert_gt(int(plan[&"pods"]), 0, "and the hold is not empty")
	assert_eq(plan[&"legs"], RegistryScript.ESCORT_LEGS, "the fixed route's three legs")
	assert_eq(
		plan[&"legs"][int(plan[&"ambush_leg"])], RegistryScript.ESCORT_LEG_MIDPOINT,
		"the ambush fires at the corridor midpoint (11 section 2.2)"
	)
	assert_eq(
		RegistryScript.ESCORT_AMBUSH_RADIUS, SectorRegistryScript.CORRIDOR_DEPTH,
		"the ambush radius is the corridor band's own depth"
	)
	assert_gt(RegistryScript.escort_speed(), 0.0, "the convoy flies at freighter speed")
	assert_eq(
		RegistryScript.escort_speed(),
		float(
			ShipFitScript.resolve(
				RegistryScript.escort_hauler(), ShipFitScript.STANDARD_FIT
			).max_speed
		),
		"read off the Hauler's own 08 section 2 row"
	)


## A5: the win pays at the destination and files +5; the loss pays nothing, files -5 and
## leaves the convoy's own cargo to the pirates.
func test_a5_win_pays_at_the_destination_and_loss_costs_standing() -> void:
	var escort := _make(RegistryScript.TYPE_ESCORT, 3)
	escort[&"id"] = &"c3"
	escort[&"target_station"] = &"s4_primary"
	escort[&"item_id"] = &"ingot_gold"
	escort[&"quantity"] = RegistryScript.escort_pods()
	assert_true(
		bool(RegistryScript.accept(_profile, _station_row(), NEUTRAL, escort)[&"ok"]),
		"an escort is accepted with no goods reserved"
	)
	assert_eq(
		RegistryScript.find(_profile, &"c3").get(&"target_station", &""), &"s4_primary",
		"the destination station is the payout site"
	)
	var before := int(_profile.call(&"credits"))
	var won := RegistryScript.escort_won(_profile, &"c3")
	assert_true(bool(won[&"ok"]), "the convoy reached the gate")
	assert_eq(int(won[&"paid"]), ESCORT_TABLE[2], "and pays the tier-3 Escort row")
	assert_eq(int(_profile.call(&"credits")), before + ESCORT_TABLE[2], "into the purse")
	assert_eq(
		int(_profile.call(&"standing_of", &"concord")), RegistryScript.STANDING_ESCORT,
		"plus the escort's +5 standing"
	)
	assert_eq(RegistryScript.active_count(_profile), 0, "the contract closes")

	var doomed := _make(RegistryScript.TYPE_ESCORT, 3)
	doomed[&"id"] = &"c4"
	doomed[&"item_id"] = &"ingot_gold"
	doomed[&"quantity"] = RegistryScript.escort_pods()
	assert_true(
		bool(RegistryScript.accept(_profile, _station_row(), NEUTRAL, doomed)[&"ok"]),
		"a second escort is accepted"
	)
	var standing := int(_profile.call(&"standing_of", &"concord"))
	var purse := int(_profile.call(&"credits"))
	var lost := RegistryScript.escort_lost(_profile, &"c4")
	assert_true(bool(lost[&"ok"]), "the convoy was destroyed")
	assert_eq(int(lost[&"paid"]), 0, "no payout")
	assert_eq(int(_profile.call(&"credits")), purse, "and no credits move")
	assert_eq(
		int(_profile.call(&"standing_of", &"concord")), standing + RegistryScript.STANDING_LOSS,
		"-5 standing on loss"
	)
	assert_eq(RegistryScript.STANDING_LOSS, -5, "which is the pin's own number")
	assert_eq(
		int((lost[&"loot"] as Dictionary).get(String(doomed[&"item_id"]), 0)),
		RegistryScript.escort_pods(),
		"and the pirates keep the convoy's loot"
	)
	assert_eq(RegistryScript.active_count(_profile), 0, "the dead escort is gone")


## ------------------------------------------------------------ A6: persistence


## A6: an active contract survives a dock/launch cycle and a restart, and a dead escort
## cannot resurrect.
func test_a6_active_contracts_survive_a_restart() -> void:
	var hunt := _make(RegistryScript.TYPE_HUNT, 1)
	hunt[&"id"] = &"c5"
	assert_true(
		bool(RegistryScript.accept(_profile, _station_row(), NEUTRAL, hunt)[&"ok"]),
		"the accept lands"
	)
	## The dock/launch cycle is a route change, not a profile write: the active list is
	## read off the profile, so it is still there after the station screen and the flight
	## scene have both come and gone.
	var screen := _mount()
	assert_eq(RegistryScript.active_count(_profile), 1, "docked, the contract is active")
	screen.queue_free()
	_free_station()
	assert_eq(RegistryScript.active_count(_profile), 1, "and it survives the undock")
	_profile.call(&"flush")
	var reopened := ProfileScript.new()
	reopened.save_path = PROFILE_PATH
	_profile.add_child(reopened)
	_scenes.append(reopened)
	var rows := RegistryScript.active(reopened)
	assert_eq(rows.size(), 1, "a fresh instance reads the active contract back")
	assert_eq(StringName(rows[0].get(&"id", &"")), &"c5", "the same record")
	assert_eq(int(rows[0].get(&"reward", 0)), 800, "with its own price")
	var doomed := _make(RegistryScript.TYPE_ESCORT, 1)
	doomed[&"id"] = &"c6"
	assert_true(
		bool(RegistryScript.accept(_profile, _station_row(), NEUTRAL, doomed)[&"ok"]),
		"an escort is accepted"
	)
	RegistryScript.escort_lost(_profile, &"c6")
	_profile.call(&"flush")
	_profile.call(&"reload")
	assert_true(
		RegistryScript.find(_profile, &"c6").is_empty(),
		"a dead escort cannot resurrect from the save"
	)
	assert_eq(
		StringName(RegistryScript.active(_profile)[0].get(&"id", &"")), &"c5",
		"and the live contract is the only one left"
	)


func _ids(board: Array[Dictionary]) -> Array:
	var out: Array = []
	for entry: Dictionary in board:
		out.append(String(entry.get(&"id", &"")))
	return out


## The first row of one type on a board, or an empty dictionary (the panel-reading
## `_find_board`'s own board-array twin).
func _find_type(board: Array[Dictionary], type: StringName) -> Dictionary:
	for entry: Dictionary in board:
		if StringName(entry.get(&"type", &"")) == type:
			return entry
	return {}


## A victim stand-in for the kill seam: exactly the three answers `game.gd:_on_npc_died`
## reads off a real `NpcShip`, every one of them read off the registry row the archetype names
## - the idiom `test_s6_heat.gd` ships.
class StubHull extends Node2D:
	var archetype_id: StringName = &"pirate"

	func row() -> Dictionary:
		return NpcRegistryScript.archetype(archetype_id)

	func heat_on_kill() -> int:
		return int(row().get(NpcRegistryScript.KEY_HEAT_ON_KILL, 0))

	func standing_on_kill() -> int:
		return int(row().get(NpcRegistryScript.KEY_STANDING_ON_KILL, 0))


func _stub_hull(archetype: StringName) -> Node2D:
	var hull := StubHull.new()
	hull.name = "Stub%s" % String(archetype).capitalize()
	hull.archetype_id = archetype
	_profile.add_child(hull)
	_scenes.append(hull)
	return hull


## A5: the runtime half in the shipped flight scene - the convoy spawns at the accepting
## station with its pods and fighters, flies the station -> corridor midpoint -> gate route,
## and the hauler reaching the gate pays the contract at the destination.
func test_a5_the_convoy_spawns_and_reaches_the_gate() -> void:
	var game := _open_game()
	if game == null:
		skip("the flight scene is not loadable headless")
		return
	var sector := StringName(game.get(&"_sector_row_id"))
	var origin := SectorRegistryScript.sector_number(sector)
	var row := StationRegistryScript.primary_for(sector)
	if row.is_empty():
		skip("the scene's sector carries no station row")
		return
	var target := origin + 1 if origin < 7 else origin - 1
	var escort := _make(RegistryScript.TYPE_ESCORT, origin)
	escort[&"id"] = &"runtime_escort"
	escort[&"origin_sector"] = origin
	escort[&"origin_station"] = StringName(row.get(&"id", &""))
	escort[&"faction"] = StringName(row.get(&"faction", &""))
	escort[&"item_id"] = &"ingot_iron"
	escort[&"quantity"] = RegistryScript.escort_pods()
	escort[&"sector"] = target
	escort[&"target_station"] = StringName(
		StationRegistryScript.primary_for(
			SectorRegistryScript.sector_id_for(target)
		).get(&"id", &"")
	)
	escort[&"reward"] = RegistryScript.reward(escort)
	assert_true(
		bool(RegistryScript.accept(_profile, row, NEUTRAL, escort)[&"ok"]), "the escort is taken"
	)
	game.call(&"_restore_escorts")
	var live: Dictionary = game.get(&"_escorts")
	assert_eq(live.size(), 1, "one live escort")
	var state: Dictionary = live.values()[0]
	var hauler: Node2D = state[&"hauler"]
	assert_true(hauler != null and is_instance_valid(hauler), "the hauler spawned")
	var members: Array = state[&"members"]
	var fighters := members.size() - 1
	assert_true(fighters >= 1 and fighters <= 2, "1-2 fighter escorts flew with it")
	var pods := 0
	for child: Node in hauler.get_children():
		if String(child.name).begins_with("CargoPod"):
			pods += 1
	assert_eq(pods, RegistryScript.ESCORT_POD_MARKS, "the hauler wears its visible cargo pods")
	var station: Vector2 = game.get(&"_sector").call(&"station_position")
	var route: Array = state[&"route"]
	assert_eq(route.size(), RegistryScript.ESCORT_LEGS.size(), "the route has its three legs")
	assert_true(
		(route[0] as Vector2).distance_to(station) < 1.0,
		"and it starts at the accepting station (14 section 6)"
	)
	var gate: Node = state[&"gate"]
	assert_true(gate != null and is_instance_valid(gate), "the target sector's gate resolved")
	assert_true(
		(route[2] as Vector2).distance_to(gate.global_position) < 1.0, "and it ends at that gate"
	)
	assert_false(bool(state[&"ambush"]), "the ambush has not fired yet")
	## The hauler crosses the corridor midpoint: the ambush fires once (11 section 2.2).
	var midpoint: Vector2 = route[RegistryScript.ESCORT_AMBUSH_LEG]
	hauler.global_position = midpoint
	game.call(&"_update_escorts", 0.0)
	assert_true(
		bool((game.get(&"_escorts") as Dictionary).values()[0][&"ambush"]), "the ambush fired"
	)
	var pirates := 0
	for hull: Node in game.get(&"_sector").call(&"npcs"):
		if hull != null and String(hull.name).begins_with("NpcPirate"):
			pirates += 1
	assert_gt(pirates, 0, "the ambushers are the sector's own pirate hulls")
	## The hauler reaches the gate ring: the contract pays at the destination.
	var before := int(_profile.call(&"credits"))
	hauler.global_position = gate.global_position
	game.call(&"_update_escorts", 0.0)
	assert_eq(RegistryScript.active_count(_profile), 0, "the arrival closes the contract")
	assert_gt(int(_profile.call(&"credits")), before, "and pays at the destination station")
	assert_eq((game.get(&"_escorts") as Dictionary).size(), 0, "the convoy stands down")


## A5: the loss row in the flight scene - the hauler's death pays nothing, costs 5 standing
## and drops the convoy's own cargo for the pirates (and the player) to fight over.
func test_a5_the_hauler_death_drops_the_loot() -> void:
	var game := _open_game()
	if game == null:
		skip("the flight scene is not loadable headless")
		return
	var sector := StringName(game.get(&"_sector_row_id"))
	var origin := SectorRegistryScript.sector_number(sector)
	var row := StationRegistryScript.primary_for(sector)
	if row.is_empty():
		skip("the scene's sector carries no station row")
		return
	var escort := _make(RegistryScript.TYPE_ESCORT, 1)
	escort[&"id"] = &"runtime_loss"
	escort[&"origin_sector"] = origin
	escort[&"faction"] = StringName(row.get(&"faction", &""))
	escort[&"item_id"] = &"ingot_iron"
	escort[&"quantity"] = RegistryScript.escort_pods()
	assert_true(
		bool(RegistryScript.accept(_profile, row, NEUTRAL, escort)[&"ok"]), "the escort is taken"
	)
	game.call(&"_restore_escorts")
	var state: Dictionary = (game.get(&"_escorts") as Dictionary).values()[0]
	var hauler: Node2D = state[&"hauler"]
	var purse := int(_profile.call(&"credits"))
	var ledger: Array = GameScript._wreck_drops.duplicate(true)
	var drops_before := GameScript._wreck_drops.size()
	hauler.emit_signal(&"died", hauler.global_position, &"trader")
	assert_eq(
		GameScript._wreck_drops.size(), drops_before + 1,
		"the convoy's cargo drops at the wreck (the pirates keep the loot)"
	)
	var dropped: Dictionary = GameScript._wreck_drops[GameScript._wreck_drops.size() - 1]
	assert_eq(StringName(dropped.get(&"item", &"")), &"ingot_iron", "the convoy's own good")
	assert_eq(int(dropped.get(&"amount", 0)), RegistryScript.escort_pods(), "and all of it")
	## Hand the static ledger back (the next suite's own wreck assertions read it).
	GameScript._wreck_drops.clear()
	GameScript._wreck_drops.append_array(ledger)
	assert_eq(RegistryScript.active_count(_profile), 0, "the dead escort leaves the list")
	assert_eq(int(_profile.call(&"credits")), purse, "no payout on a loss")
	assert_eq(
		int(_profile.call(&"standing_of", StringName(row.get(&"faction", &"")))),
		RegistryScript.STANDING_LOSS, "-5 standing, filed on the contract's faction"
	)
	assert_eq((game.get(&"_escorts") as Dictionary).size(), 0, "and the convoy is gone")


func _open_game() -> Node2D:
	var packed := load(GAME_SCENE) as PackedScene
	if packed == null:
		return null
	var scene := packed.instantiate() as Node2D
	if scene == null:
		return null
	_profile.add_child(scene)
	_scenes.append(scene)
	return scene


## --------------------------------------------------------- A7: the deck and the panel


## A7 (T-138): the SERVICES deck holds the CONTRACTS panel in place of the retired
## `MODULE OFFLINE` placeholder, and the panel carries STATION_HUB section 15.2's U3 header
## strip and its verbatim note.
func test_a7_the_services_deck_holds_the_contracts_panel() -> void:
	_profile.call(&"set_docked_station", STATION)
	var screen := _mount()
	var deck: Control = screen.call(&"pane_for", 7) as Control
	assert_true(deck != null, "the SERVICES deck exists")
	assert_false(deck.is_in_group(&"station_placeholder"), "and it is not the placeholder (T-138)")
	var panel: Control = screen.call(&"service_panel", &"contracts") as Control
	assert_true(panel != null, "the CONTRACTS panel is mounted in the deck")
	assert_false(panel.is_in_group(&"station_placeholder"), "and it is a real panel")
	assert_eq(String(panel.call(&"header_note")), NOTE_U3, "U3's note verbatim")
	assert_eq(
		panel.call(&"column_headers"), [HEADER_TYPE, HEADER_OBJECTIVE, HEADER_REWARD, HEADER_FACTION],
		"U3's four column headers"
	)
	assert_eq(String(panel.call(&"cancel_label")), CANCEL_LABEL, "U4's cancel wording")
	assert_eq(String(panel.call(&"confirm_body_text")), CONFIRM_BODY, "U4's confirm body verbatim")


## T-160 (the owner's playtest, 2026-10-09): the shell's service host hands each mounted
## pane the deck's own height. A VBoxContainer child that does not expand answers its
## minimum, and the CONTRACTS panel's minimum is its header, its note and its foot - so
## the board's scroll collapsed to its own 2 px minimum and drew **no row at all** on the
## real screen, while every data-level read (the board, the empty text, the countdown)
## still answered correctly. A pane does not size itself (A5.1); the flag is the host's.
func test_a7_the_services_host_expands_every_pane() -> void:
	_profile.call(&"set_docked_station", STATION)
	var screen := _mount()
	var deck: Control = screen.call(&"pane_for", 7) as Control
	assert_true(deck != null, "the SERVICES deck exists")
	var host := deck.get_node_or_null(NodePath("ServiceHost")) as Control
	assert_true(host != null, "and it carries its own service host")
	assert_eq(host.get_child_count(), 3, "one pane per service in the strip")
	for child: Node in host.get_children():
		var pane := child as Control
		assert_true(pane != null, "a service pane is a Control")
		assert_true(
			bool(pane.size_flags_vertical & Control.SIZE_EXPAND),
			"%s fills the deck's height (T-160)" % pane.name
		)
	var panel: Control = screen.call(&"service_panel", &"contracts") as Control
	assert_true(panel != null, "the CONTRACTS panel is mounted")
	assert_true(
		bool(panel.size_flags_vertical & Control.SIZE_EXPAND),
		"and the CONTRACTS pane is one of the panes that expand"
	)
	var board := panel.get_node_or_null(NodePath("Body/BoardHalf/BoardScroll")) as Control
	assert_true(board != null, "the board's own scroll is in the panel")
	assert_true(
		bool(board.size_flags_vertical & Control.SIZE_EXPAND),
		"the scroll is what takes the height the pane was given"
	)


## A7: the board row anatomy - the type glyph and name, the objective verbatim, the reward
## right-aligned and the faction glyph - and the ACCEPT pressable that takes the contract.
func test_a7_the_board_rows_and_accept() -> void:
	_profile.call(&"set_docked_station", STATION)
	var screen := _mount()
	var panel: Control = screen.call(&"service_panel", &"contracts") as Control
	var rows: Array = panel.call(&"board_rows")
	## The board's own items, so the escrow's reservation can land (a Haul and a Gather
	## row both lock goods at accept).
	for entry: Dictionary in rows:
		if StringName(entry.get(&"type", &"")) == RegistryScript.TYPE_EXPEDITION:
			continue
		_profile.call(
			&"add_cargo", StringName(entry.get(&"item_id", &"")), int(entry.get(&"quantity", 0))
		)
	assert_eq(rows.size(), RegistryScript.BOARD_SIZE, "the panel draws the six-row board")
	var accepts: Array = panel.call(&"accept_buttons")
	assert_gt(accepts.size(), 0, "the open rows carry an ACCEPT")
	var board: Control = panel.get_node("%BoardList") as Control
	assert_eq(board.get_child_count(), rows.size(), "one row node per board row")
	for child: Node in board.get_children():
		var row := child as Button
		assert_true(row != null, "a board row is a Button")
		assert_true(row.get_node_or_null("RowInner") != null, "with the section 3.1 RowInner")
		var inner: Control = row.get_node("RowInner")
		assert_true(inner.get_node_or_null("RowBox") != null, "and its own column box")
	var first: Button = accepts[0]
	first.emit_signal(&"pressed")
	assert_eq(
		RegistryScript.active_count(_profile), 1, "the ACCEPT takes the contract"
	)
	assert_eq(
		panel.call(&"active_rows").size(), 1, "and the active column draws it"
	)


## A7: U6 - the `ACTIVE CONTRACTS %d/3` counter, the `MAX 3 ACTIVE` chip at 3/3 and every
## ACCEPT disabled there.
func test_a7_the_max_three_counter_and_chip() -> void:
	_profile.call(&"set_docked_station", STATION)
	var screen := _mount()
	var panel: Control = screen.call(&"service_panel", &"contracts") as Control
	assert_eq(
		String(panel.call(&"counter_text")), "ACTIVE CONTRACTS 0/3", "U6's counter wording"
	)
	assert_false(bool(panel.call(&"chip_shown")), "no chip below the cap")
	for index in RegistryScript.MAX_ACTIVE:
		var contract := _make(RegistryScript.TYPE_HUNT, 1)
		contract[&"id"] = &"panel_%d" % index
		assert_true(
			bool(RegistryScript.accept(_profile, _station_row(), NEUTRAL, contract)[&"ok"]),
			"accept %d" % (index + 1)
		)
	panel.call(&"refresh_profile", &"contracts")
	assert_eq(
		String(panel.call(&"counter_text")), "ACTIVE CONTRACTS 3/3", "the counter reads the cap"
	)
	assert_true(bool(panel.call(&"chip_shown")), "U6's chip is up at 3/3")
	assert_eq(String(panel.call(&"chip_text")), CHIP_MAX, "with its own wording")
	var accepts: Array = panel.call(&"accept_buttons")
	assert_eq(accepts.size(), 0, "no open row carries a live ACCEPT at 3/3")
	var board: Control = panel.get_node("%BoardList") as Control
	var disabled := 0
	for child: Node in board.get_children():
		var row := child as Button
		if row == null:
			continue
		for node: Node in row.get_node("RowInner").get_node("RowBox").get_children():
			if node is Button and (node as Button).text == CHIP_MAX:
				assert_true((node as Button).disabled, "the ACCEPT carries the chip and is disabled")
				disabled += 1
	assert_gt(disabled, 0, "at least one open row shows the chip")


## A7: U7's staged Expedition row, U5's escrow readout and U4's cancel path end to end.
func test_a7_the_staged_row_the_escrow_and_the_cancel() -> void:
	_profile.call(&"set_docked_station", STATION)
	var screen := _mount()
	var panel: Control = screen.call(&"service_panel", &"contracts") as Control
	var board: Control = panel.get_node("%BoardList") as Control
	var staged_rows := 0
	for child: Node in board.get_children():
		var row := child as Button
		if row == null:
			continue
		var box := row.get_node("RowInner").get_node("RowBox")
		var caption := box.get_node_or_null("StagedCaption") as Label
		if caption == null:
			continue
		staged_rows += 1
		assert_eq(caption.text, CAPTION_STAGED, "U7's caption verbatim")
		assert_true(row.disabled, "the Expedition row is greyed whole")
		for node: Node in box.get_children():
			if node is Button:
				assert_eq((node as Button).text, CHIP_STAGED, "and carries the STAGED chip")
	assert_eq(staged_rows, 1, "one staged Expedition row")
	var haul := _find_board(panel, RegistryScript.TYPE_HAUL)
	assert_false(haul.is_empty(), "a Haul row rolled")
	## The band's own roll decides the good, so the stack that backs the accept is the **row's
	## own** item (the sibling `test_a7_the_board_rows_and_accept` stocks every row's own the
	## same way); a fixed item made this row pass or fail by band.
	var item := StringName(haul.get(&"item_id", &""))
	_profile.call(&"add_cargo", item, RegistryScript.HAUL_QUANTITY)
	assert_true(bool(panel.call(&"accept", haul[&"id"])[&"ok"]), "the panel accepts it")
	assert_eq(int(_profile.call(&"cargo_qty", item)), 0, "the goods lock into escrow")
	var lines: Array = panel.call(&"escrow_readout")
	assert_eq(String(lines[0]), ESCROW_HEADER, "U5's escrow header verbatim")
	assert_eq(
		String(lines[1]), "%d× %s · RESERVED" % [RegistryScript.HAUL_QUANTITY, String(item)],
		"and the reserved stack line"
	)
	var cancel: Button = panel.call(&"cancel_button", haul[&"id"])
	assert_true(cancel != null, "the active card carries the cancel affordance")
	assert_eq(cancel.text, CANCEL_LABEL, "U4's wording at the decision point")
	var before := int(_profile.call(&"credits"))
	panel.call(&"confirm_action", &"cancel_contract", haul[&"id"])
	assert_eq(int(_profile.call(&"credits")), before - 100, "the confirm charges the 100 CR fee")
	assert_eq(
		int(_profile.call(&"cargo_qty", item)), RegistryScript.HAUL_QUANTITY,
		"and the reserved goods unlock"
	)
	assert_eq(RegistryScript.active_count(_profile), 0, "the contract is gone")


## A7: U8's two empty states, verbatim - the gated board and a board with nothing to roll.
func test_a7_the_two_empty_states() -> void:
	_profile.call(&"set_docked_station", STATION)
	_profile.call(&"set_standing", {"concord": 0, "meridian": SHUNNED, "choir": 0})
	var screen := _mount()
	var panel: Control = screen.call(&"service_panel", &"contracts") as Control
	assert_eq(
		String(panel.call(&"empty_state_text")), EMPTY_GATED,
		"a Shunned board shows 14 section 2's own line"
	)
	assert_eq(EMPTY_GATED, "REDEMPTION MUST PRECEDE EMPLOYMENT", "verbatim")
	## S38's H1: an empty filed id is the cold start and now answers the starting place, so
	## "no place at all" is spelled by a sector with no station row (S7's own sentinel).
	_profile.call(&"set_docked_station", &"sector_7")
	panel.call(&"refresh_profile", &"contracts")
	assert_eq(
		String(panel.call(&"empty_state_text")), EMPTY_NO_JOBS, "an empty board shows the other"
	)
	assert_eq(EMPTY_NO_JOBS, "NO OPEN JOBS — NEW JOBS ROLL ON THE 20-MINUTE CLOCK", "verbatim")


func _find_board(panel: Control, type: StringName) -> Dictionary:
	for entry: Dictionary in panel.call(&"board_rows"):
		if StringName(entry.get(&"type", &"")) == type:
			return entry
	return {}


## -------------------------------------------------------------------- A8: the riders


## A8 (T-152): the LAUNCH briefing names the docked sector's own row, not the mockup-era
## `HELIOS DRIFT` a sector the map does not carry.
func test_a8_the_launch_line_names_the_docked_sector() -> void:
	_profile.call(&"set_docked_station", STATION)
	var screen := _mount()
	var launch: Control = screen.call(&"pane_for", 5) as Control
	assert_true(launch != null, "the LAUNCH pane is mounted")
	var line := String(launch.call(&"destination_line"))
	assert_eq(line, "OPEN SPACE · MERIDIAN SPAN", "S3's own name (11 section 1)")
	assert_false(line.contains("HELIOS"), "and the mockup-era name is gone")
	_profile.call(&"set_docked_station", &"s1_primary")
	assert_eq(
		String(launch.call(&"destination_line")), "OPEN SPACE · HALCYON REACH",
		"another dock answers its own sector"
	)
	## S38's H1: an empty filed id is the cold start and now answers the starting place
	## (Halcyon), not "no place"; the leg's outcome is unchanged (HALCYON REACH carries
	## no HELIOS).
	_profile.call(&"set_docked_station", &"")
	assert_false(
		String(launch.call(&"destination_line")).contains("HELIOS"),
		"an empty filed id is the cold start and still names no dead sector"
	)


## A8 (T-154): the refinery's `resource_seconds` doc example is the live derivation again
## (comment-only: the formula and its answers are unmoved).
func test_a8_the_refinery_example_is_live() -> void:
	assert_eq(RefineryScript.resource_seconds(&"iron"), 10, "Iron's 65 CR ingot floors at 10 s")
	assert_eq(RefineryScript.resource_seconds(&"gold"), 26, "Gold's 259 reads 26 s")
	var file := FileAccess.open("res://game/refinery.gd", FileAccess.READ)
	assert_true(file != null, "the script is readable")
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	assert_false(text.contains("Gold's 395"), "the stale figure is gone from the comment")
	assert_true(text.contains("Gold's 259 reads 26 s"), "and the live derivation is stated")
