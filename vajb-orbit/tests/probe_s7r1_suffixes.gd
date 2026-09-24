extends Node
## S7-R1 reviewer probe D: the suffix seams and the Ledger arithmetic, re-measured
## with the reviewer's own fixtures.
##
## Borrows the `PlayerProfile` autoload (save_path repointed at a scratch file and the
## economy log repointed before the first mutation, both handed back at the end), opens
## the shipped `game.tscn` for the Leeches and Cartograph seams, and re-derives the
## Ledger row off 09 section 3's cost. Read-only against the live account: every write
## lands in `user://probe_s7r1_suffixes.cfg`.
##
## Run: godot --headless --path vajb-orbit res://tests/probe_s7r1_suffixes.tscn --quit-after 600

const GameScript := preload("res://game/game.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const ModuleData := preload("res://game/module_catalog.gd")
const FitData := preload("res://game/ship_fit.gd")
const AffixesScript := preload("res://game/affixes.gd")
const AuctionScript := preload("res://game/auction.gd")
const NpcRegistryScript := preload("res://game/npc_registry.gd")
const Log := preload("res://game/economy_log.gd")

const GAME_SCENE := "res://game/game.tscn"
const SCRATCH_PROFILE := "user://probe_s7r1_suffixes.cfg"
const SCRATCH_LOG := "user://probe_s7r1_suffixes_log.txt"
const LASER: StringName = &"w_laser"
const KILL_POINT := Vector2(4800.0, -4800.0)
const SWARMER: StringName = &"swarmer"
const STAGED: Array[StringName] = [&"silence", &"vault", &"choir", &"concord", &"ports"]

var _fail := 0
var _profile: Node = null
var _previous_path := ""
var _previous_log := ""


class Victim extends Node2D:
	var archetype_id: StringName = &"swarmer"

	func row() -> Dictionary:
		return NpcRegistryScript.archetype(archetype_id)

	func heat_on_kill() -> int:
		return int(row().get(NpcRegistryScript.KEY_HEAT_ON_KILL, 0))

	func standing_on_kill() -> int:
		return int(row().get(NpcRegistryScript.KEY_STANDING_ON_KILL, 0))


func _ready() -> void:
	print("[S7R1-D] begin")
	_profile = get_tree().root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		print("[S7R1-D] BAD no PlayerProfile autoload")
		get_tree().quit(1)
		return
	_previous_path = String(_profile.get(&"save_path"))
	_previous_log = Log.log_path
	_delete(SCRATCH_PROFILE)
	_delete(SCRATCH_LOG)
	_profile.set(&"save_path", SCRATCH_PROFILE)
	Log.log_path = SCRATCH_LOG
	GameScript._transit_destination = &""

	_ledger()
	_staged_price()
	_leeches()
	_cartograph()
	_launch_alignment()

	GameScript._transit_destination = &""
	Log.log_path = _previous_log
	_profile.call(&"reset_to_defaults")
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	_delete(SCRATCH_PROFILE)
	_delete(SCRATCH_LOG)
	print("[S7R1-D] done failures=%d" % [_fail])
	get_tree().quit(0)


func _check(ok: bool, label: String, detail: String) -> void:
	if not ok:
		_fail += 1
	print("[S7R1-D] %s %s %s" % ["OK " if ok else "BAD", label, detail])


func _near(a: float, b: float) -> bool:
	return absf(a - b) <= 0.0001


func _delete(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


func _fresh() -> Node:
	var script := load("res://autoload/player_profile.gd") as GDScript
	var profile: Node = script.new()
	profile.save_path = SCRATCH_PROFILE + ".fresh"
	add_child(profile)
	return profile


## ---------------------------------------------------------------- Ledger


func _ledger() -> void:
	var profile := _fresh()
	var plain: StringName = profile.add_instance(LASER, ModuleData.RARITY_COMMON, [], [])
	var ledger: StringName = profile.add_instance(LASER, ModuleData.RARITY_COMMON, [], [&"ledger"])
	var cost := int(ModuleData.module(LASER)[&"cost"])
	var plain_price := ModuleData.sell_price(LASER, ModuleData.RARITY_COMMON)
	var ledger_price := AuctionScript.sell_price(LASER, ModuleData.RARITY_COMMON, [&"ledger"])
	print(
		"[S7R1-D] ledger cost=%d plain=%d ledger=%d one_function=%d"
		% [cost, plain_price, ledger_price, plain_price * AuctionScript.LEDGER_PERCENT / 100]
	)
	_check(cost == 900 and plain_price == 540, "09 section 3's 900-cost Common", "540")
	_check(ledger_price == 675, "900-cost Common + Ledger = 675", "%d" % [ledger_price])
	_check(plain_price * 125 % 100 == 0, "the term is an exact integer", "%d" % [plain_price * 125])

	# Every catalogue cost x rarity x ledger stays integral.
	var integral := true
	var worst := ""
	for base: StringName in ModuleData.MODULES.keys():
		for rarity: StringName in [&"common", &"magic", &"rare"]:
			var price := ModuleData.sell_price(base, rarity)
			var ledgered := AuctionScript.sell_price(base, rarity, [&"ledger"])
			if ledgered != price * 125 / 100 or price * 125 % 100 != 0:
				integral = false
				worst = "%s/%s %d -> %d" % [base, rarity, price, ledgered]
	print("[S7R1-D] ledger integral over every catalogue row: %s %s" % [str(integral), worst])
	_check(integral, "every 09/15 cost x ledger is integral", "MODULES x 3 rarities")

	# The pane's displayed row.
	var rows: Array[Dictionary] = AuctionScript.sell_rows(profile)
	var shown_plain := -1
	var shown_ledger := -1
	for row: Dictionary in rows:
		if StringName(str(row.get(&"id"))) == plain:
			shown_plain = int(row.get(&"price"))
		if StringName(str(row.get(&"id"))) == ledger:
			shown_ledger = int(row.get(&"price"))
	print("[S7R1-D] ledger displayed row plain=%d ledger=%d" % [shown_plain, shown_ledger])
	_check(shown_plain == 540 and shown_ledger == 675, "the displayed row carries the term", "%d / %d" % [shown_plain, shown_ledger])

	# The transaction's quote and the payout.
	var before: int = profile.credits()
	var quote: Dictionary = AuctionScript.sell_row(profile, ledger)
	print(
		"[S7R1-D] ledger quote ok=%s cost=%d price=%d credits_delta=%d"
		% [str(quote.get(&"ok")), int(quote.get(&"cost", -1)), int(quote.get(&"price", -1)), profile.credits() - before]
	)
	_check(int(quote.get(&"cost", -1)) == 675 and profile.credits() - before == 675, "the quote pays 675", "%d" % [profile.credits() - before])

	var direct: StringName = profile.add_instance(LASER, ModuleData.RARITY_COMMON, [], [&"ledger"])
	var payout_before: int = profile.credits()
	var sold := bool(profile.sell_instance(direct))
	print(
		"[S7R1-D] ledger payout sold=%s delta=%d" % [str(sold), profile.credits() - payout_before]
	)
	_check(sold and profile.credits() - payout_before == 675, "the payout is 675", "%d" % [profile.credits() - payout_before])

	# A two-argument call and an empty list are the pre-S7 number; other suffixes are not the term.
	var same := true
	for other: StringName in [&"whale", &"embers", &"leeches", &"cartograph", &"silence", &"vault", &"choir"]:
		if AuctionScript.sell_price(LASER, ModuleData.RARITY_COMMON, [other]) != plain_price:
			same = false
	_check(same, "only ledger carries the term", "whale/embers/leeches/cartograph/staged ignored")
	_check(
		AuctionScript.sell_price(LASER, ModuleData.RARITY_COMMON) == plain_price
		and AuctionScript.sell_price(LASER, ModuleData.RARITY_COMMON, []) == plain_price,
		"no argument and [] are the pre-S7 call",
		"%d" % [plain_price]
	)
	_check(
		AuctionScript.sell_price(LASER, ModuleData.RARITY_RARE, [&"ledger"])
		== AuctionScript.sell_price(LASER, ModuleData.RARITY_RARE, [{&"id": &"ledger", &"value": 0.0}]),
		"both stored spellings read the same",
		"%d" % [AuctionScript.sell_price(LASER, ModuleData.RARITY_RARE, [&"ledger"])]
	)
	var rare_plain := ModuleData.sell_price(LASER, ModuleData.RARITY_RARE)
	var rare_ledger := AuctionScript.sell_price(LASER, ModuleData.RARITY_RARE, [&"ledger"])
	print("[S7R1-D] ledger rare plain=%d ledger=%d" % [rare_plain, rare_ledger])
	_check(rare_ledger == rare_plain * 125 / 100, "the Rare row scales too", "%d" % [rare_ledger])
	# The once-per-perk rule: a record carrying the row twice is still one term.
	var doubled := AuctionScript.sell_price(
		LASER, ModuleData.RARITY_COMMON, [&"ledger", &"ledger"]
	)
	print("[S7R1-D] ledger doubled=%d (one term) squared=%d" % [doubled, plain_price * 125 / 100 * 125 / 100])
	_check(doubled == 675, "two ledger rows are one term", "%d" % [doubled])


func _staged_price() -> void:
	var profile := _fresh()
	var ship: StringName = profile.active_ship()
	var instance: StringName = profile.add_instance(LASER, ModuleData.RARITY_RARE, [], STAGED)
	var fitted := bool(profile.call(&"fit_module_at", ship, &"weapons", 0, instance))
	var summary: Dictionary = profile.call(&"affix_summary", ship)
	var fit: Dictionary = profile.call(&"base_fit", profile.call(&"resolved_fit", ship))
	var with_staged: ShipStats = FitData.resolve(ship, fit, summary)
	var without: ShipStats = FitData.resolve(ship, fit, {})
	var flags_ok := true
	for id: StringName in STAGED:
		if not AffixesScript.has_suffix(summary, id):
			flags_ok = false
	print(
		"[S7R1-D] staged fitted=%s flags=%s resolve_identical=%s price=%d plain=%d"
		% [
			str(fitted),
			str(flags_ok),
			str(_snapshot(with_staged) == _snapshot(without)),
			AuctionScript.sell_price(LASER, ModuleData.RARITY_RARE, STAGED),
			ModuleData.sell_price(LASER, ModuleData.RARITY_RARE),
		]
	)
	_check(fitted and flags_ok, "the five staged suffixes fit and flag", "silence/vault/choir/concord/ports")
	_check(_snapshot(with_staged) == _snapshot(without), "resolve is byte-identical with them", "no-op")
	_check(
		AuctionScript.sell_price(LASER, ModuleData.RARITY_RARE, STAGED)
		== ModuleData.sell_price(LASER, ModuleData.RARITY_RARE),
		"and they add no sell term",
		"%d" % [ModuleData.sell_price(LASER, ModuleData.RARITY_RARE)]
	)


## ---------------------------------------------------------------- Leeches


func _leeches() -> void:
	# The control first: no Leeches, a credited kill, no heal.
	var control := _open_game()
	if control == null:
		_check(false, "game.tscn opens", "null")
		return
	var control_state: PlayerState = control.get(&"_state")
	control_state.set_hull(control_state.hull_max - 200.0)
	var control_before := control_state.hull
	control.call(&"_on_npc_died", KILL_POINT, SWARMER, _victim())
	print(
		"[S7R1-D] leeches control hull_before=%.3f after=%.3f flag=%s"
		% [control_before, control_state.hull, str(AffixesScript.has_suffix(control.get(&"_launch_summary"), &"leeches"))]
	)
	_check(_near(control_state.hull, control_before), "no Leeches, no heal", "%.3f" % [control_state.hull])
	control.free()

	# The fitted case: a Leeches instance in the launch's W cell.
	var profile := _profile
	var ship: StringName = profile.active_ship()
	var id: StringName = profile.add_instance(LASER, ModuleData.RARITY_COMMON, [], [&"leeches"])
	var fitted := bool(profile.call(&"fit_module_at", ship, &"weapons", 0, id))
	var scene := _open_game()
	if scene == null:
		_check(false, "game.tscn opens (leeches)", "null")
		return
	var state: PlayerState = scene.get(&"_state")
	state.set_hull(state.hull_max - 200.0)
	var before := state.hull
	var kills_before := _kill_lines()
	scene.call(&"_on_npc_died", KILL_POINT, SWARMER, _victim())
	var kills_after := _kill_lines()
	var expected := minf(before + GameScript.LEECHES_FRACTION * state.hull_max, state.hull_max)
	print(
		"[S7R1-D] leeches fitted=%s flag=%s hull_before=%.3f after=%.3f expected=%.3f kills=%d->%d"
		% [
			str(fitted),
			str(AffixesScript.has_suffix(scene.get(&"_launch_summary"), &"leeches")),
			before,
			state.hull,
			expected,
			kills_before,
			kills_after,
		]
	)
	_check(fitted, "a Leeches instance fits the launch", "%s" % [id])
	_check(kills_after == kills_before + 1, "the handler credited the kill", "%d -> %d" % [kills_before, kills_after])
	_check(_near(state.hull, expected), "5 % of hull_max paid back", "%.3f" % [state.hull])
	scene.free()
	profile.call(&"clear_fit_slot", ship, &"weapons", 0)


## ---------------------------------------------------------------- Cartograph


func _cartograph() -> void:
	# The fogged control.
	var control := _open_game()
	if control == null:
		_check(false, "game.tscn opens (cartograph control)", "null")
		return
	var control_sector: Node = control.get(&"_sector")
	var control_fogged := _fogged(control_sector)
	var control_guaranteed := _guaranteed(control_sector)
	print(
		"[S7R1-D] cartograph control fogged=%d guaranteed=%d kinds=%s"
		% [control_fogged.size(), control_guaranteed.size(), _kinds(control_guaranteed)]
	)
	_check(
		control_guaranteed.size() >= 2 and control_fogged.size() > 0,
		"the control sector has fog to lift",
		"%d fogged" % [control_fogged.size()]
	)
	var manual_fogged := -1
	if control_sector != null:
		control_sector.call(&"reveal_pois")
		manual_fogged = _fogged(control_sector).size()
	print("[S7R1-D] cartograph one manual reveal_pois leaves fogged=%d" % [manual_fogged])
	control.free()

	var profile := _profile
	var ship: StringName = profile.active_ship()
	var id: StringName = profile.add_instance(
		LASER, ModuleData.RARITY_COMMON, [], [GameScript.FLAG_CARTOGRAPH]
	)
	var fitted := bool(profile.call(&"fit_module_at", ship, &"weapons", 0, id))
	var scene := _open_game()
	if scene == null:
		_check(false, "game.tscn opens (cartograph)", "null")
		return
	var sector: Node = scene.get(&"_sector")
	var fogged := _fogged(sector)
	var guaranteed := _guaranteed(sector)
	var revealed := true
	for poi: Node2D in guaranteed:
		if not bool(poi.call(&"is_revealed")):
			revealed = false
	print(
		"[S7R1-D] cartograph fitted=%s flag=%s fogged=%d guaranteed=%d all_revealed=%s manual_fogged=%d"
		% [
			str(fitted),
			str(AffixesScript.has_suffix(scene.get(&"_launch_summary"), GameScript.FLAG_CARTOGRAPH)),
			fogged.size(),
			guaranteed.size(),
			str(revealed),
			manual_fogged,
		]
	)
	_check(fitted, "a Cartograph instance fits the launch", "%s" % [id])
	_check(fogged.size() == 0, "entry lifts every POI's fog", "%d fogged" % [fogged.size()])
	_check(revealed and guaranteed.size() >= 2, "the derelict and anomaly are revealed", _kinds(guaranteed))
	_check(
		fogged.size() == manual_fogged,
		"the entry reads like one reveal_pois call",
		"entry=%d manual=%d" % [fogged.size(), manual_fogged]
	)
	scene.free()
	profile.call(&"clear_fit_slot", ship, &"weapons", 0)


## ---------------------------------------------------------------- launch alignment


## The launch walk's barrel-to-slot alignment (CONTRACTS section 20): a two-cell W fit
## whose **second** cell carries Keen must put the Keen dict on slot 1, and a family-less
## `w_mining` cell in front of it must not shift that mapping.
func _launch_alignment() -> void:
	var profile := _profile
	var ship: StringName = &"ship_fighter"
	var owned: Array[StringName] = [ship]
	profile.set(&"_owned_ships", owned)
	profile.set(&"_active_ship", ship)
	var mining: StringName = profile.add_instance(&"w_mining", ModuleData.RARITY_COMMON, [], [])
	profile.call(&"take_instance", mining)
	var laser: StringName = profile.add_instance(
		LASER, ModuleData.RARITY_COMMON, [{&"id": &"keen", &"value": 0.15}], []
	)
	profile.call(&"take_instance", laser)
	profile.call(&"set_fit", ship, {
		&"engines": [&"e_std"], &"power": &"p_std", &"weapons": [mining, laser],
	})
	var scene := _open_game()
	if scene == null:
		_check(false, "game.tscn opens (alignment)", "null")
		return
	var state: PlayerState = scene.get(&"_state")
	var weapons: Array = state.weapons
	var affixes: Array = state.weapon_affixes
	print("[S7R1-D] alignment launch_fit=%s state=%s" % [str(scene.get(&"_launch_fit")), str(state != null)])
	var row0: Dictionary = (affixes[0] as Dictionary) if affixes.size() > 0 else {}
	var row1: Dictionary = (affixes[1] as Dictionary) if affixes.size() > 1 else {}
	print(
		"[S7R1-D] alignment weapons=%s affixes=%s slots_for_barrels=%s"
		% [str(weapons), str(affixes), str(_barrel_slots(scene))]
	)
	_check(weapons.size() == 2 and String(weapons[0]) == "", "the mining cell is a family-less slot", str(weapons))
	_check(affixes.size() == 2, "one affix entry per weapon slot", "%d" % [affixes.size()])
	_check(row0.is_empty(), "the mining cell carries nothing", str(row0))
	_check(_near(float(row1.get(&"keen", 0.0)), 0.15), "cell 2's Keen rides slot 1", str(row1))
	_check(_barrel_slots(scene) == [1], "the only barrel reads slot 1", str(_barrel_slots(scene)))
	scene.free()

	# The mirror: Keen in cell 0 with a plain laser behind it.
	var keen0: StringName = profile.add_instance(
		LASER, ModuleData.RARITY_COMMON, [{&"id": &"keen", &"value": 0.16}], []
	)
	profile.call(&"take_instance", keen0)
	var plain1: StringName = profile.add_instance(LASER, ModuleData.RARITY_COMMON, [], [])
	profile.call(&"take_instance", plain1)
	profile.call(&"set_fit", ship, {
		&"engines": [&"e_std"], &"power": &"p_std", &"weapons": [keen0, plain1],
	})
	var mirror := _open_game()
	if mirror == null:
		_check(false, "game.tscn opens (alignment mirror)", "null")
		return
	var mirror_state: PlayerState = mirror.get(&"_state")
	var mirror_affixes: Array = mirror_state.weapon_affixes
	var mirror0: Dictionary = (mirror_affixes[0] as Dictionary) if mirror_affixes.size() > 0 else {}
	var mirror1: Dictionary = (mirror_affixes[1] as Dictionary) if mirror_affixes.size() > 1 else {}
	print(
		"[S7R1-D] alignment mirror weapons=%s affixes=%s slots=%s"
		% [str(mirror_state.weapons), str(mirror_affixes), str(_barrel_slots(mirror))]
	)
	_check(_near(float(mirror0.get(&"keen", 0.0)), 0.16), "cell 1's Keen rides slot 0", str(mirror0))
	_check(mirror1.is_empty(), "cell 2 stays empty", str(mirror1))
	_check(_barrel_slots(mirror) == [0, 1], "both barrels read their own slots", str(_barrel_slots(mirror)))
	mirror.free()

	# The launch's own snapshot: a c_target in the fighter's C cell resolves damage_mult
	# 1.15 and the mounted component reads it off the snapshot.
	var computer: StringName = profile.add_instance(&"c_target", ModuleData.RARITY_COMMON, [], [])
	profile.call(&"take_instance", computer)
	profile.call(&"set_fit", ship, {
		&"engines": [&"e_std"], &"power": &"p_std", &"weapons": [plain1], &"computers": [computer],
	})
	var armed := _open_game()
	if armed == null:
		_check(false, "game.tscn opens (computer)", "null")
		return
	var stats: ShipStats = armed.get(&"_stats")
	var guns: Node = armed.get(&"_guns")
	print(
		"[S7R1-D] launch computer damage_mult=%.6f component_scale=%.6f"
		% [stats.damage_mult, float(guns.call(&"_damage_scale"))]
	)
	_check(_near(stats.damage_mult, 1.15), "the launch resolves 1.15", "%.6f" % [stats.damage_mult])
	_check(_near(float(guns.call(&"_damage_scale")), 1.15), "the component reads the snapshot", "%.6f" % [float(guns.call(&"_damage_scale"))])
	armed.free()

	# Embers rides the launch's flags into the shot's configure dict.
	var ember: StringName = profile.add_instance(LASER, ModuleData.RARITY_COMMON, [], [&"embers"])
	profile.call(&"take_instance", ember)
	profile.call(&"set_fit", ship, {
		&"engines": [&"e_std"], &"power": &"p_std", &"weapons": [ember],
	})
	var embered := _open_game()
	if embered == null:
		_check(false, "game.tscn opens (embers)", "null")
		return
	var ember_guns: Node = embered.get(&"_guns")
	var flags: Array = embered.get(&"_state").affix_flags
	var shot: Node2D = ember_guns.call(
		&"_spawn_shot", &"laser", WeaponScriptRowOf(&"laser"), Vector2.RIGHT, 0
	) as Node2D
	print(
		"[S7R1-D] launch embers flags=%s shot_embers=%s shot_mult=%.6f"
		% [str(flags), str(shot.get(&"embers")), float(shot.get(&"damage_mult"))]
	)
	_check(flags.has(&"embers"), "the state carries the launch flag", str(flags))
	_check(bool(shot.get(&"embers")), "the shot carries it", str(shot.get(&"embers")))
	_check(_near(float(shot.get(&"damage_mult")), 1.0), "no computer, 1.0", "%.6f" % [float(shot.get(&"damage_mult"))])
	shot.free()
	embered.free()
	profile.call(&"clear_fit", ship)


## The weapon family's own row reader, so this probe does not need the component.
func WeaponScriptRowOf(weapon: StringName) -> Dictionary:
	var script := load("res://game/weapons.gd") as GDScript
	return script.row_of(weapon)


## The slot each barrel position resolves to, read through the component's own map.
func _barrel_slots(scene: Node2D) -> Array:
	var guns: Node = scene.get(&"_guns")
	if guns == null:
		return []
	var fitted: Array = guns.call(&"fitted")
	var out: Array = []
	for position: int in range(fitted.size()):
		out.append(int(guns.call(&"_slot_of_barrel", position)))
	return out


## ---------------------------------------------------------------- helpers


func _open_game() -> Node2D:
	var packed := load(GAME_SCENE) as PackedScene
	if packed == null:
		return null
	var scene := packed.instantiate() as Node2D
	if scene == null:
		return null
	add_child(scene)
	return scene


func _victim() -> Node2D:
	var hull := Victim.new()
	hull.archetype_id = SWARMER
	add_child(hull)
	return hull


func _fogged(sector: Node) -> Array[Node2D]:
	var out: Array[Node2D] = []
	if sector == null:
		return out
	for poi: Node2D in sector.call(&"pois"):
		if not bool(poi.call(&"is_revealed")):
			out.append(poi)
	return out


func _guaranteed(sector: Node) -> Array:
	var out: Array = []
	if sector == null:
		return out
	out.append_array(sector.call(&"derelicts"))
	out.append_array(sector.call(&"anomalies"))
	return out


func _kinds(pois: Array) -> String:
	var parts := PackedStringArray()
	for poi: Variant in pois:
		parts.append(str((poi as Node).get(&"kind")))
	return ",".join(parts)


func _kill_lines() -> int:
	var file := FileAccess.open(Log.log_path, FileAccess.READ)
	if file == null:
		return 0
	var count := 0
	var needle := ", %s, " % [String(GameScript.EVENT_KILL)]
	while not file.eof_reached():
		if file.get_line().contains(needle):
			count += 1
	file.close()
	return count


func _snapshot(stats: ShipStats) -> Dictionary:
	var out: Dictionary = {}
	for field: StringName in [
		&"max_speed", &"accel_time", &"coast_time", &"turn_rate", &"turn_spinup",
		&"hull_mass", &"hull_max", &"shield_max", &"shield_regen", &"damage_mult",
		&"lock_range", &"scan_range", &"cargo_max", &"energy_max", &"fuel_max",
		&"boosters", &"booster_cooldown_mult",
	]:
		out[String(field)] = stats.get(field)
	return out
