extends SceneTree
## S12-K1's evidence probe: delivered ore per second and per rock on the pinned
## S12 field (S12_BRIEF §4), for the three legs LASER / GUN3 / GUNMAX.
##
##   XDG_DATA_HOME=/tmp/s12_k1 "$GODOT_CONSOLE" --headless --path "$VAJB_PROJ" \
##     --script res://tests/probe_s12_rock_rate.gd
##
## One `[S12K1]` line per row, the last is `[S12K1] done failures=N` (exit 1 if any).
## Nothing awaits a frame and no scene is needed: a detached `AsteroidField` builds
## real `RigidBody2D` rocks without a physics world, and a crack's fragments are
## appended to the field's own `rocks()` list. Every number is read from its owner
## (the brief's §4 table); nothing is re-declared, so the probe measures the tree and
## cannot drift from it.
##
## Determinism, one measured fact beyond §4: `Asteroid._roll_look` rolls a rock's
## size class on the **global** RNG (`game/asteroid.gd:371-375`, and its own comment
## at `:207-211` says "a caller that needs a reproducible look calls `seed()` first").
## The field's own `rng` seeds the gameplay rolls; the look does not. So every field
## build is preceded by the global `seed(FIELD_SEED)` — without it two runs would roll
## different size classes and the cleave cascade would differ run to run.
##
## Legs (§4, verbatim):
##   LASER  - one `WORK_PER_UNIT` per `MINE_CYCLE`; delivers the `apply_work` returns,
##            one pickup per unit (`game/mining_laser.gd:195-202`).
##   GUN3   - one rack of three cannons (`GUN3_BARRELS`).
##   GUNMAX - the max W cells over `ShipFit.HULLS` (the firepower ceiling).
## A gun leg applies `shot_damage(w_cannon) * GUN_CHIP_RATE` per shot
## (`game/projectile.gd:769-773`), discards the chip returns, and delivers only the
## field's own pickup-group units (`game/asteroid_field.gd:400-420`). One shot's share
## of the wall clock is `interval_of / barrels`, i.e. `barrels / interval_of` shots/s.

const AsteroidScript := preload("res://game/asteroid.gd")
const FieldScript := preload("res://game/asteroid_field.gd")
const MineralCatalogScript := preload("res://game/mineral_catalog.gd")
const MiningLaserScript := preload("res://game/mining_laser.gd")
const WeaponsScript := preload("res://game/weapons.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")

const TAG := "[S12K1]"

## §4's pinned field: a T1 field at the field's own minimum rock count, so the
## cleave cascade is the only variable.
const FIELD_SEED := 12061
const FIELD_ROCKS := 6
const FIELD_CONFIG := {
	&"tier_weights": {1: 100},
	&"rocks": FIELD_ROCKS,
	&"seed": FIELD_SEED,
}
## §4 names the cannon by module id (`w_cannon`). `WeaponsScript.row_of` is keyed by
## **family** id, so the module id is resolved through the owner's own
## `WeaponsScript.weapon_id()` (game/weapons.gd:2437-2442) rather than re-declared.
const MODULE := &"w_cannon"
## §4's pinned GUN3 leg: one rack, three cannons. GUNMAX reads its barrel count off
## `ShipFit.HULLS` instead (never assumed).
const GUN3_BARRELS := 3
const VANGUARD := &"ship_vanguard"
## §4's bounds. Hitting either is a failure row, never a silent truncation.
const MAX_STEPS := 200000
const MAX_SECONDS := 100000.0

const LASER := "LASER"
const GUN3 := "GUN3"
const GUNMAX := "GUNMAX"

var _failures: Array[String] = []


func _init() -> void:
	print("%s probe=rock_rate field tier_weights=%s rocks=%d seed=%d"
		% [TAG, str(FIELD_CONFIG[&"tier_weights"]), FIELD_ROCKS, FIELD_SEED])
	_constants()
	var max_barrels: int = _max_hull_weapons()[&"weapons"]
	var laser := _measure(LASER, 1, true, false)
	var gun3 := _measure(GUN3, GUN3_BARRELS, true, false)
	var gunmax := _measure(GUNMAX, max_barrels, true, false)
	var legs: Array[Dictionary] = [laser, gun3, gunmax]
	for leg: Dictionary in legs:
		_leg_row(leg)
	_leg_identity(legs)
	_ratio_row(laser, gun3)
	_ratio_row(laser, gunmax)
	_hold_rows(laser, gun3, gunmax)
	_rock_rows(max_barrels)
	print("%s done failures=%d" % [TAG, _failures.size()])
	quit(1 if not _failures.is_empty() else 0)


## §4's constant table, every value read from its owner file. A number printed here
## that is not read from an owner would be AC4's failure mode.
func _constants() -> void:
	print("%s CONST GUN_CHIP_RATE=%.2f src=game/weapons.gd" % [TAG, WeaponsScript.GUN_CHIP_RATE])
	var family := _family()
	print("%s CONST module=%s WeaponsScript.weapon_id(module)=%s row_of(module)_empty=%s (the family table is keyed by family id)"
		% [TAG, String(MODULE), String(family), str(WeaponsScript.row_of(MODULE).is_empty())])
	var row: Dictionary = WeaponsScript.row_of(family)
	var burst_on := float(row.get(&"burst_on", 0.0))
	var burst_off := float(row.get(&"burst_off", 0.0))
	print("%s CONST shot_damage(%s)=%.1f interval_of(%s)=%.3f burst_on=%.3f burst_off=%.3f burst_sum=%.3f"
		% [TAG, family, WeaponsScript.shot_damage(family), family,
		WeaponsScript.interval_of(family), burst_on, burst_off, burst_on + burst_off])
	var hull_ceiling: Dictionary = _max_hull_weapons()
	print("%s CONST shots_per_second=barrels/interval_of(%s) GUN3(%d)=%.3f/s GUNMAX(%d)=%.3f/s"
		% [TAG, family, GUN3_BARRELS, _shots_per_second(GUN3_BARRELS),
		hull_ceiling[&"weapons"], _shots_per_second(hull_ceiling[&"weapons"])])
	print("%s CONST WORK_PER_UNIT=%.1f src=game/asteroid.gd" % [TAG, AsteroidScript.WORK_PER_UNIT])
	print("%s CONST MINE_CYCLE=%.3f src=game/mining_laser.gd" % [TAG, MiningLaserScript.MINE_CYCLE])
	print("%s CONST TIER_BASE_YIELD=%s YIELD_VARIANCE=%.1f..%.1f src=game/mineral_catalog.gd"
		% [TAG, str(MineralCatalogScript.TIER_BASE_YIELD),
		MineralCatalogScript.YIELD_VARIANCE_MIN, MineralCatalogScript.YIELD_VARIANCE_MAX])
	print("%s CONST FRAGMENT_SPLIT=%s PICKUP_BURST=%s src=game/asteroid.gd"
		% [TAG, str(AsteroidScript.FRAGMENT_SPLIT), str(AsteroidScript.PICKUP_BURST)])
	print("%s CONST ore_id(%s)=%s src=MineralCatalog.ore_id"
		% [TAG, String(&"iron"), String(MineralCatalogScript.ore_id(&"iron"))])
	print("%s CONST pickup_group=%s item_prop=item_id amount_prop=amount src=FieldScript.PICKUP_GROUP+Pickup"
		% [TAG, String(FieldScript.PICKUP_GROUP)])
	var cargo: Dictionary = _max_hull_cargo()
	print("%s CONST vanguard_cargo=%d max_cargo_over_HULLS=%d (%s) src=ShipFit.HULLS"
		% [TAG, int(ShipFitScript.HULLS[VANGUARD][&"cargo"]), cargo[&"cargo"], cargo[&"hull"]])
	print("%s CONST hull_max_weapons=%d (%s) WeaponsScript.GROUPS_MAX=%d agree=%s"
		% [TAG, hull_ceiling[&"weapons"], hull_ceiling[&"hull"], WeaponsScript.GROUPS_MAX,
		str(hull_ceiling[&"weapons"] == WeaponsScript.GROUPS_MAX)])
	print("%s CONST interval_of rocket=%.3f mine=%.3f (printed, never modelled)"
		% [TAG, WeaponsScript.interval_of(&"rocket"), WeaponsScript.interval_of(&"mine")])


## One whole-field leg: one rock at a time in `rocks()` order, re-reading `rocks()`
## after every call because a crack frees the rock and appends its fragments.
func _measure(leg: String, barrels: int, whole_field: bool, root_only: bool) -> Dictionary:
	var field := _fresh_field()
	var initial: Array[Node2D] = field.call(&"rocks")
	var result := _blank_result(leg, barrels)
	if initial.is_empty():
		result[&"bound"] = "EMPTY_FIELD"
		field.free()
		return result
	var root_id: int = initial[0].get_instance_id()
	result[&"fingerprint"] = _fingerprint(initial)
	result[&"root_yield"] = int(initial[0].get(&"yield_units"))
	## S13 (02 §5.1 Rule A): the rock's own original yield, the budget the family
	## must not exceed. Read from the rock, never re-derived here.
	result[&"root_bore"] = float(initial[0].call(&"bore_ore"))
	result[&"root_size"] = int(initial[0].call(&"size_class"))
	result[&"root_mineral"] = StringName(initial[0].get(&"mineral_id"))
	result[&"root_tier"] = int(initial[0].get(&"tier"))
	var family: Dictionary = {root_id: true}
	var spawned: Dictionary = {}
	var delivered := 0
	var elapsed := 0.0
	var steps := 0
	var bound := ""
	while true:
		var all: Array[Node2D] = field.call(&"rocks")
		var root_seen := false
		for rock: Node2D in all:
			spawned[rock.get_instance_id()] = true
			if rock.get_instance_id() == root_id:
				root_seen = true
		if root_only and not root_seen:
			break
		var live: Array[Node2D] = []
		for rock: Node2D in all:
			if whole_field or family.has(rock.get_instance_id()):
				live.append(rock)
		if live.is_empty():
			break
		if steps >= MAX_STEPS:
			bound = "MAX_STEPS"
			break
		if elapsed >= MAX_SECONDS:
			bound = "MAX_SECONDS"
			break
		var before := _id_set(all)
		var target: Node2D = live[0]
		if leg == LASER:
			delivered += int(target.call(&"apply_work", AsteroidScript.WORK_PER_UNIT))
		else:
			## S13 (01 §5.6): the chip is attributed to the gun route, so a shatter it
			## delivers is capped at `GUN_BURST_SHARE x _bore_ore`.
			target.call(&"apply_gun_work", _chip_work())
		steps += 1
		if not whole_field:
			for rock: Node2D in field.call(&"rocks") as Array[Node2D]:
				if not before.has(rock.get_instance_id()):
					family[rock.get_instance_id()] = true
		elapsed += _step_seconds(leg, barrels)
	## S13: the field's pickup children are the shatter delivery for every leg, on
	## top of the laser's extraction returns (a gun's chips never extract).
	delivered += _pickup_units(field)
	result[&"delivered"] = delivered
	result[&"seconds"] = elapsed
	result[&"steps"] = steps
	result[&"rocks"] = spawned.size()
	result[&"bound"] = bound
	result[&"pickups"] = _pickup_count(field)
	result[&"complete"] = bound == ""
	field.free()
	return result


func _leg_row(leg: Dictionary) -> void:
	var bound: String = leg[&"bound"]
	print("%s LEG %s barrels=%d delivered=%d seconds=%.3f units_per_s=%.6f units_per_rock=%.6f depletion_work_per_s=%.6f rocks_spawned=%d steps=%d pickups=%d bound=%s"
		% [TAG, leg[&"leg"], leg[&"barrels"], leg[&"delivered"], leg[&"seconds"],
		_rate(leg), _per_rock(leg), _work_per_second(leg), leg[&"rocks"],
		leg[&"steps"], leg[&"pickups"], bound if bound != "" else "none"])
	_check("leg_%s_complete" % leg[&"leg"], bool(leg[&"complete"]),
		"%s emptied the field in %d steps / %.3f s (bound %s)"
			% [leg[&"leg"], leg[&"steps"], leg[&"seconds"], bound if bound != "" else "none"])


## Each leg re-seeds the field, so the same six rocks must come back. A difference
## means the probe measured two different fields and every ratio is void.
func _leg_identity(legs: Array[Dictionary]) -> void:
	var first: String = legs[0][&"fingerprint"]
	var same := true
	for leg: Dictionary in legs:
		if leg[&"fingerprint"] != first:
			same = false
	print("%s SEED fingerprint=%s" % [TAG, first])
	_check("leg_same_seeded_field", same and first != "",
		"all %d legs start from the identical seeded field" % legs.size())


func _ratio_row(laser: Dictionary, gun: Dictionary) -> void:
	var rate := _ratio(_rate(laser), _rate(gun))
	var per_rock := _ratio(_per_rock(laser), _per_rock(gun))
	print("%s RATIO %s_vs_LASER rate=%.3fx per_rock=%.3fx (mining %.6f u/s / %.6f u per rock vs gunning %.6f u/s / %.6f u per rock)"
		% [TAG, gun[&"leg"], rate, per_rock, _rate(laser), _per_rock(laser),
		_rate(gun), _per_rock(gun)])


## The hold comparison: how long each leg's rate takes to fill the starting
## Vanguard and the largest hold over `ShipFit.HULLS`.
func _hold_rows(laser: Dictionary, gun3: Dictionary, gunmax: Dictionary) -> void:
	var vanguard: int = int(ShipFitScript.HULLS[VANGUARD][&"cargo"])
	var cargo: Dictionary = _max_hull_cargo()
	for leg: Dictionary in [laser, gun3, gunmax]:
		var rate := _rate(leg)
		print("%s HOLD fill_seconds %s vanguard=%d -> %.3f max_cargo=%d (%s) -> %.3f"
			% [TAG, leg[&"leg"], vanguard, _fill_seconds(vanguard, rate),
			cargo[&"cargo"], cargo[&"hull"], _fill_seconds(cargo[&"cargo"], rate)])


## The single-rock half of 01 §5.6's invariant 1: one seeded rock's own budget in
## (`_bore_ore`), its extractable half, and what each leg realises out of it.
## `LASER_OWN` is the rock body alone (its extractable, "mining realises 100 % of
## its extractable units"); the other rows resolve the whole cascade the rock
## becomes, because a gun delivers only through the capped Small-end burst.
func _rock_rows(max_barrels: int) -> void:
	var own := _measure(LASER, 1, false, true)
	var family_laser := _measure(LASER, 1, false, false)
	var family_gun3 := _measure(GUN3, GUN3_BARRELS, false, false)
	var family_gunmax := _measure(GUNMAX, max_barrels, false, false)
	var yield_in: int = own[&"root_yield"]
	var bore: float = own[&"root_bore"]
	print("%s ROCK seed=%d index=1 mineral=%s tier=%d size=%s extractable=%d bore=%.4f"
		% [TAG, FIELD_SEED, String(own[&"root_mineral"]), own[&"root_tier"],
		_size_name(own[&"root_size"]), yield_in, bore])
	for entry: Array in [
		["LASER_OWN", own], ["LASER_FAMILY", family_laser],
		["GUN3_FAMILY", family_gun3], ["GUNMAX_FAMILY", family_gunmax],
	]:
		var leg: Dictionary = entry[1]
		print("%s ROCK LEG %s units=%d seconds=%.3f shots=%d field_rocks_spawned=%d pickups=%d units_over_bore=%.3fx"
			% [TAG, entry[0], leg[&"delivered"], leg[&"seconds"], leg[&"steps"],
			leg[&"rocks"], leg[&"pickups"], _ratio(leg[&"delivered"], bore)])
	_check("rock_laser_realises_own_extractable",
		bool(own[&"complete"]) and own[&"delivered"] == yield_in,
		"the laser realises the rock's own extractable %d units in %.3f s"
			% [yield_in, own[&"seconds"]])
	_check("rock_family_conserved",
		float(family_laser[&"delivered"]) <= bore + 1.0,
		"a fully mined family realises %d <= its own bore %.4f + 1 (was 4.0x)"
			% [family_laser[&"delivered"], bore])
	_check("rock_gun_capped",
		float(family_gun3[&"delivered"]) <= 0.10 * bore + 1.0
			and float(family_gunmax[&"delivered"]) <= 0.10 * bore + 1.0,
		"a gun family realises %d/%d <= 0.10 x its %.4f bore + 1"
			% [family_gun3[&"delivered"], family_gunmax[&"delivered"], bore])


## ---------------------------------------------------------------------------
## Fixtures and helpers
## ---------------------------------------------------------------------------


## A freshly seeded pinned field. `seed(FIELD_SEED)` pins the global RNG the rock
## look rolls on (see the header); the field's own `rng` is seeded by `setup`.
func _fresh_field() -> Node2D:
	seed(FIELD_SEED)
	var field := FieldScript.new() as Node2D
	field.call(&"setup", FIELD_CONFIG)
	return field


## The cannon's family id, through the owner's own resolver (never re-declared).
func _family() -> StringName:
	return WeaponsScript.weapon_id(MODULE)


## §4: one shot's chip = `shot_damage(family) * GUN_CHIP_RATE`.
func _chip_work() -> float:
	return WeaponsScript.shot_damage(_family()) * WeaponsScript.GUN_CHIP_RATE


## §4's shots-per-second rule, pinned and printed: `barrels / interval_of`.
func _shots_per_second(barrels: int) -> float:
	var interval := WeaponsScript.interval_of(_family())
	if interval <= 0.0:
		return 0.0
	return float(barrels) / interval


func _step_seconds(leg: String, barrels: int) -> float:
	if leg == LASER:
		return MiningLaserScript.MINE_CYCLE
	return WeaponsScript.interval_of(_family()) / float(maxi(barrels, 1))


## The depletion rate a leg implies (work in, not ore out): the laser applies one
## `WORK_PER_UNIT` per extracted unit; a gun applies one chip per shot. The docs'
## "3 cannons = 13.5 ore-units/s of depletion" is this column for `GUN3`.
func _work_per_second(leg: Dictionary) -> float:
	if leg[&"leg"] == LASER:
		return _rate(leg) * AsteroidScript.WORK_PER_UNIT
	return _shots_per_second(leg[&"barrels"]) * _chip_work()


func _pickup_units(field: Node2D) -> int:
	var total := 0
	for child: Node in field.get_children():
		if child.is_in_group(FieldScript.PICKUP_GROUP):
			total += int(child.get(&"amount"))
	return total


func _pickup_count(field: Node2D) -> int:
	var total := 0
	for child: Node in field.get_children():
		if child.is_in_group(FieldScript.PICKUP_GROUP):
			total += 1
	return total


func _id_set(nodes: Array[Node2D]) -> Dictionary:
	var out: Dictionary = {}
	for node: Node2D in nodes:
		out[node.get_instance_id()] = true
	return out


func _fingerprint(nodes: Array[Node2D]) -> String:
	var parts: Array[String] = []
	for rock: Node2D in nodes:
		parts.append("%d/%s/%d/%s" % [
			int(rock.get(&"yield_units")), _size_name(int(rock.call(&"size_class"))),
			int(rock.get(&"tier")), String(rock.get(&"mineral_id")),
		])
	return ";".join(PackedStringArray(parts))


func _size_name(size_class: int) -> String:
	match size_class:
		AsteroidScript.SIZE_SMALL:
			return "SMALL"
		AsteroidScript.SIZE_MEDIUM:
			return "MEDIUM"
		AsteroidScript.SIZE_LARGE:
			return "LARGE"
	return "ANY"


func _max_hull_weapons() -> Dictionary:
	return _max_hull_column(&"weapons")


func _max_hull_cargo() -> Dictionary:
	return _max_hull_column(&"cargo")


func _max_hull_column(column: StringName) -> Dictionary:
	var best: Dictionary = {&"hull": &"", column: -1}
	for hull: StringName in ShipFitScript.HULLS.keys():
		var value := int(ShipFitScript.HULLS[hull].get(column, -1))
		if value > int(best.get(column, -1)):
			best = {&"hull": hull, column: value}
	return best


func _blank_result(leg: String, barrels: int) -> Dictionary:
	return {
		&"leg": leg, &"barrels": barrels, &"delivered": 0, &"seconds": 0.0,
		&"steps": 0, &"rocks": 0, &"pickups": 0, &"bound": "", &"complete": false,
		&"fingerprint": "", &"root_yield": 0, &"root_bore": 0.0, &"root_size": -1,
		&"root_mineral": &"", &"root_tier": 0,
	}


func _rate(leg: Dictionary) -> float:
	var seconds: float = leg[&"seconds"]
	if seconds <= 0.0:
		return 0.0
	return float(leg[&"delivered"]) / seconds


func _per_rock(leg: Dictionary) -> float:
	var rocks: int = leg[&"rocks"]
	if rocks <= 0:
		return 0.0
	return float(leg[&"delivered"]) / float(rocks)


func _ratio(numerator: float, denominator: float) -> float:
	if denominator <= 0.0:
		return -1.0
	return numerator / denominator


func _fill_seconds(cargo: int, rate: float) -> float:
	if rate <= 0.0:
		return -1.0
	return float(cargo) / rate


func _check(label: String, ok: bool, note: String) -> void:
	print("%s %s %s - %s" % [TAG, "ok  " if ok else "FAIL", label, note])
	if not ok:
		_failures.append(label)
