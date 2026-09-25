extends SceneTree
## S12-K0's evidence probe: how much ore a seeded field holds and how much each
## depletion path realises from it. Contract: `docs/CONTRACTS.md` section 5 and
## the pinned measurement contract in `slices/S12-ore-budget/S12_BRIEF.md` section
## 4; every constant below is printed with the owner file it was read from, and
## none is re-declared.
##
##   XDG_DATA_HOME=/tmp/s12_k0 godot --headless --path vajb-orbit \
##     --script res://tests/probe_s12_field_budget.gd
##
## Six legs -- LASER / GUN3 / GUNMAX on a pinned T1 field, then the same three on
## a pinned T3 field. Each leg builds a freshly seeded `AsteroidField`, sums the
## original rocks' `yield_units`, then works **one rock at a time** in `rocks()`
## order until the field is empty: `rocks()` is re-read after every call because a
## crack frees the rock and appends its fragments to the field.
##
##   LASER  realises the sum of `apply_work`'s returns -- one pickup per returned
##          unit, mirrored from `game/mining_laser.gd:195-202`.
##   GUN*   discards a chip's returns (`game/projectile.gd:769-773`) and pays only
##          the Small-end burst, so it realises the sum of `amount` over the
##          field's own pickup-group children (`game/asteroid_field.gd:400-420`).
##
## Nothing is simulated: a detached field builds real `RigidBody2D` rocks without
## a physics world, no frame is awaited, and every seed is fixed, so two runs
## print byte-identical lines. One `[S12K0]` row per line; the last is
## `[S12K0] done failures=N` (exit 1 if any).

const AsteroidScript := preload("res://game/asteroid.gd")
const FieldScript := preload("res://game/asteroid_field.gd")
const MineralCatalogScript := preload("res://game/mineral_catalog.gd")
const MiningLaserScript := preload("res://game/mining_laser.gd")
const WeaponsScript := preload("res://game/weapons.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
## S13's live balance surface: the gun cap this probe checks reads here, never a
## re-declared 0.10.
const OreTuningScript := preload("res://game/ore_tuning.gd")

const TAG := "[S12K0]"
const GUN_ID := &"w_cannon"
const HULL_ID := &"ship_vanguard"

## Section 4's pinned field, verbatim.
const FIELD_SEED := 12061
const FIELD_ROCKS := 6
const FIELD_CONFIG := {
	&"tier_weights": {1: 100},
	&"rocks": FIELD_ROCKS,
	&"seed": FIELD_SEED,
}
const FIELD_CONFIG_T3 := {
	&"tier_weights": {3: 100},
	&"rocks": FIELD_ROCKS,
	&"seed": FIELD_SEED,
}

## Section 4's bounds: hitting either is a failure row, never a silent stop.
const MAX_STEPS := 200000
const MAX_SECONDS := 100000.0

var _failures: Array[String] = []


func _init() -> void:
	_constants()
	_legs("T1", FIELD_CONFIG)
	_legs("T3", FIELD_CONFIG_T3)
	print("%s done failures=%d" % [TAG, _failures.size()])
	quit(1 if not _failures.is_empty() else 0)


## ---------------------------------------------------------------------------
## Section 4's constant table, every value read from its owner.
## ---------------------------------------------------------------------------


func _constants() -> void:
	print("%s const GUN_CHIP_RATE=%.6f (WeaponsScript.GUN_CHIP_RATE)"
		% [TAG, WeaponsScript.GUN_CHIP_RATE])
	var cannon_row: Dictionary = WeaponsScript.row_of(_gun_id())
	print("%s const w_cannon module_id=%s family_id=%s shot_damage=%.6f interval_of=%.6f"
		% [TAG, str(GUN_ID), str(_gun_id()), WeaponsScript.shot_damage(_gun_id()),
		WeaponsScript.interval_of(_gun_id())]
		+ " burst_on=%.6f burst_off=%.6f"
		% [float(cannon_row.get(&"burst_on", 0.0)), float(cannon_row.get(&"burst_off", 0.0))])
	print("%s const id_gap raw_shot_damage(%s)=%.6f raw_interval_of(%s)=%.6f"
		% [TAG, str(GUN_ID), WeaponsScript.shot_damage(GUN_ID), str(GUN_ID),
		WeaponsScript.interval_of(GUN_ID)]
		+ " (module ids are not FAMILIES keys; weapons.gd:2437 weapon_id normalizes)")
	print("%s const WORK_PER_UNIT=%.6f (AsteroidScript.WORK_PER_UNIT)"
		% [TAG, AsteroidScript.WORK_PER_UNIT])
	print("%s const MINE_CYCLE=%.6f (MiningLaserScript.MINE_CYCLE)"
		% [TAG, MiningLaserScript.MINE_CYCLE])
	print("%s const TIER_BASE_YIELD=%s YIELD_VARIANCE_MIN=%.6f YIELD_VARIANCE_MAX=%.6f"
		% [TAG, str(MineralCatalogScript.TIER_BASE_YIELD),
		MineralCatalogScript.YIELD_VARIANCE_MIN, MineralCatalogScript.YIELD_VARIANCE_MAX])
	print("%s const retired_FRAGMENT_SPLIT=%s PICKUP_BURST=%s"
		% [TAG, str(AsteroidScript.FRAGMENT_SPLIT), str(AsteroidScript.PICKUP_BURST)])
	## S14 (02 §5.2): the split rule and the spawn mix the field reads today, so the
	## cascade rows below are read against the table that produced them.
	print("%s const split_mix=%s spawn_size_weights=%s src=game/ore_tuning.gd"
		% [TAG, str(OreTuningScript.split_mix), str(OreTuningScript.spawn_size_weights)])
	var probe_mineral := _first_tier1_mineral()
	print("%s const ore_id(%s)=%s (MineralCatalogScript.ore_id)"
		% [TAG, str(probe_mineral), str(MineralCatalogScript.ore_id(probe_mineral))])
	print("%s const pickup_group=%s pickup_item_field=item_id pickup_amount_field=amount"
		% [TAG, str(FieldScript.PICKUP_GROUP)])
	var vanguard: Dictionary = ShipFitScript.HULLS.get(HULL_ID, {})
	var max_cargo_hull := _hull_with_max(&"cargo")
	print("%s const hold %s cargo=%d max_cargo=%d (%s)"
		% [TAG, str(HULL_ID), int(vanguard.get(&"cargo", 0)),
		int(ShipFitScript.HULLS[max_cargo_hull][&"cargo"]), str(max_cargo_hull)])
	var max_weapons_hull := _hull_with_max(&"weapons")
	var max_weapons := int(ShipFitScript.HULLS[max_weapons_hull][&"weapons"])
	## S15 restates the agreement row for the hardcap (09 section 12): the ceiling is
	## `GROUPS_MAX * BATTERY_CELLS_MAX` (5 x 4 = 20), so the widest hull's 7 W cells fit
	## inside it instead of equalling it.
	print("%s const w_cells max=%d (%s) GROUPS_MAX=%d BATTERY_CELLS_MAX=%d ceiling=%d fits=%s"
		% [TAG, max_weapons, str(max_weapons_hull), WeaponsScript.GROUPS_MAX,
		WeaponsScript.BATTERY_CELLS_MAX,
		WeaponsScript.GROUPS_MAX * WeaponsScript.BATTERY_CELLS_MAX,
		str(max_weapons <= WeaponsScript.GROUPS_MAX * WeaponsScript.BATTERY_CELLS_MAX)])
	print("%s const untouched rocket interval_of(raw w_rocket)=%.6f interval_of(rocket)=%.6f"
		% [TAG, WeaponsScript.interval_of(&"w_rocket"),
		WeaponsScript.interval_of(WeaponsScript.weapon_id(&"w_rocket"))]
		+ " mine interval_of(raw w_mine)=%.6f interval_of(mine)=%.6f"
		% [WeaponsScript.interval_of(&"w_mine"),
		WeaponsScript.interval_of(WeaponsScript.weapon_id(&"w_mine"))])
	print("%s field T1 seed=%d rocks=%d tier_weights=%s"
		% [TAG, FIELD_SEED, FIELD_ROCKS, str(FIELD_CONFIG[&"tier_weights"])])
	print("%s field T3 seed=%d rocks=%d tier_weights=%s"
		% [TAG, FIELD_SEED, FIELD_ROCKS, str(FIELD_CONFIG_T3[&"tier_weights"])])


## ---------------------------------------------------------------------------
## The six legs.
## ---------------------------------------------------------------------------


func _legs(tier_label: String, config: Dictionary) -> void:
	var barrels_max := int(ShipFitScript.HULLS[_hull_with_max(&"weapons")][&"weapons"])
	_run_leg(tier_label, "LASER", 1, config)
	_run_leg(tier_label, "GUN3", 3, config)
	_run_leg(tier_label, "GUNMAX", barrels_max, config)


## One leg on a freshly seeded field. `barrels` same-family cannon release a whole
## volley once per `interval_of`, so one shot's share of the wall clock is
## `interval / barrels` -- i.e. `barrels / interval_of` shots per second.
func _run_leg(tier_label: String, leg: String, barrels: int, config: Dictionary) -> void:
	## The originals' look -- and so their cleaving size class -- rolls on the
	## **global** RNG (`asteroid.gd:207-211`, `:342-375`), while yield, tier and
	## mineral roll on the field's own seeded RNG. Pin the global stream before
	## every setup, as that comment says a caller needing a reproducible look must:
	## without it the six legs do not start from the same rocks and two runs do not
	## agree.
	seed(FIELD_SEED)
	var field: Node2D = FieldScript.new() as Node2D
	field.call(&"setup", config)
	## S13 (02 §5.1 Rule A): the field's budget is the sum of its rocks' own
	## original yields (`_bore_ore`), not the extractable `yield_units` it hands
	## extraction. `out_in` below is measured against that budget.
	var spawn_bore := 0
	for rock: Node2D in field.call(&"rocks"):
		spawn_bore += int(roundi(float(rock.call(&"bore_ore"))))
	var extracted := 0
	var delivered := 0
	var steps := 0
	var elapsed := 0.0
	var seen: Dictionary = {}
	var bounded := false
	while true:
		var live: Array[Node2D] = field.call(&"rocks")
		if live.is_empty():
			break
		if steps >= MAX_STEPS or elapsed >= MAX_SECONDS:
			bounded = true
			break
		var rock: Node2D = live[0]
		seen[rock.get_instance_id()] = true
		if leg == "LASER":
			var mined := int(rock.call(&"apply_work", AsteroidScript.WORK_PER_UNIT))
			extracted += mined
			delivered += mined
			elapsed += MiningLaserScript.MINE_CYCLE
		else:
			## S13 (01 §5.6): a gun's chip is attributed to the gun route, which caps
			## the shatter's payout at `GUN_BURST_SHARE x _bore_ore`.
			rock.call(&"apply_gun_work",
				WeaponsScript.shot_damage(_gun_id()) * WeaponsScript.GUN_CHIP_RATE)
			elapsed += WeaponsScript.interval_of(_gun_id()) / float(barrels)
		steps += 1
	## S13 (02 §5.1 Rule A): a gun's chips are discarded (they never extract); a
	## Small's shatter pays pickups. The field's pickup children are the delivery
	## either way, so they are summed for every leg, on top of the laser's returns.
	delivered += _burst_units(field)
	var spawned_seen := seen.size()
	var spawned_counter := int(field.get(&"_spawned"))
	var out_in := 0.0
	if spawn_bore > 0:
		out_in = float(delivered) / float(spawn_bore)
	var shots_per_second := 0.0
	if leg != "LASER":
		shots_per_second = float(barrels) / WeaponsScript.interval_of(_gun_id())
	print(("%s LEG tier=%s leg=%s barrels=%d spawn_bore=%d delivered=%d out_in=%.6f"
		+ " rocks_spawned=%d rocks_seen=%d steps=%d seconds=%.6f shots_per_second=%.6f")
		% [TAG, tier_label, leg, barrels, spawn_bore, delivered, out_in,
		spawned_counter, spawned_seen, steps, elapsed, shots_per_second])
	if bounded:
		print("%s FAIL leg=%s tier=%s bounded_at steps=%d seconds=%.6f"
			% [TAG, leg, tier_label, steps, elapsed])
		_failures.append("bounded_%s_%s" % [tier_label, leg])
	_check("%s_%s_spawn_nonzero" % [tier_label, leg], spawn_bore > 0,
		"spawn_bore=%d" % spawn_bore)
	_check("%s_%s_spawned_count" % [tier_label, leg], spawned_seen == spawned_counter,
		"children_seen=%d field._spawned=%d" % [spawned_seen, spawned_counter])
	if leg == "LASER":
		_check("%s_%s_one_unit_per_cycle" % [tier_label, leg], extracted <= steps,
			"extracted=%d across %d cycles (one unit of work never realises twice)"
			% [extracted, steps])
		_check("%s_%s_budget_conserved" % [tier_label, leg],
			delivered <= spawn_bore + 1,
			"delivered=%d <= its own spawn_bore=%d + 1" % [delivered, spawn_bore])
	else:
		_check("%s_%s_burst_paid" % [tier_label, leg], delivered > 0,
			"burst units=%d" % delivered)
		_check("%s_%s_gun_capped" % [tier_label, leg],
			delivered <= int(floor(OreTuningScript.gun_burst_share * float(spawn_bore))) + 1,
			"delivered=%d <= GUN_BURST_SHARE %.2f x spawn_bore=%d + 1"
			% [delivered, OreTuningScript.gun_burst_share, spawn_bore])
	field.free()


## The field's own pickup-group children, summed: a gun's only delivery.
func _burst_units(field: Node) -> int:
	var total := 0
	for child: Node in field.get_children():
		if child.is_in_group(FieldScript.PICKUP_GROUP):
			total += int(child.get(&"amount"))
	return total


## ---------------------------------------------------------------------------
## Fixtures.
## ---------------------------------------------------------------------------


## The cannon's family id: `weapons.gd`'s `row_of`/`shot_damage`/`interval_of` key the
## FAMILIES table by family (`cannon`), and the pinned module spelling `w_cannon`
## resolves through the owner's own `weapon_id` normalizer (`weapons.gd:2437`).
func _gun_id() -> StringName:
	return WeaponsScript.weapon_id(GUN_ID)


func _first_tier1_mineral() -> StringName:
	var rows: Array[Dictionary] = MineralCatalogScript.tier_minerals(1)
	if rows.is_empty():
		return &""
	return StringName(rows[0].get(&"id", &""))


func _hull_with_max(key: StringName) -> StringName:
	var best_id := &""
	var best := -1
	for id: Variant in ShipFitScript.HULLS.keys():
		var row: Dictionary = ShipFitScript.HULLS[id]
		var value := int(row.get(key, 0))
		if value > best:
			best = value
			best_id = StringName(id)
	return best_id


func _check(label: String, ok: bool, note: String) -> void:
	print("%s %s %s - %s" % [TAG, "ok  " if ok else "FAIL", label, note])
	if not ok:
		_failures.append(label)
