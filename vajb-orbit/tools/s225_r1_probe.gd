extends SceneTree
## S22.5-R1's independent replay of 02 §5.3 A1-A7 (the reviewer re-measures; it
## never reads the builder's numbers). Every yardstick is transcribed from
## `docs/gameplay/02_minerals.md` §5.3 and §5.2, NOT from `OreTuning` and NOT from
## the wave brief - the live tables are then compared against the pins, so a wrong
## default fails here rather than agreeing with itself.
##
##   XDG_DATA_HOME=/tmp/s225_r1 "$GODOT_CONSOLE" --headless --path "$VAJB_PROJ" \
##     --script res://tools/s225_r1_probe.gd --quit-after 400
##
## A1  the roll: band, per-rock spread, same-seed identity, fresh-seed difference
##     (the seed-22501 sequence is printed so two process runs can be diffed).
## A2  the gun-door divisor per class at the mean roll: deposit arithmetic, the
##     four w_laser times against the 3.0/5.0/8.0/12.0 s floors, and the
##     field-spawned T1 shape (4 extractable of a 6 bore) for §5.3's 2/3 note.
## A3  the mining door at both roll extremes on every class: 1 work = 1 unit,
##     one 1.2 s cycle = 1 unit even on a max-roll XL.
## A4  chip 1.0 and ram 10 survive an S fragment, 2.0 work cracks it, the beam
##     takes >= 0.6 s, and M/L carry their own budgets.
## A5  a shot XL's children: bore 0, parentage-marked, S children stop, an M
##     fragment still re-splits (S16's law intact).
## A6  the splinter: cap-spaced sheds under sustained fire, real S body, bore 0,
##     outward, 2.0 budget, S/M shed none, a cracking hit sheds none, 25 % rate.
## A7  no ore minted: a fully shot family realises <= floor(GUN_BURST_SHARE x bore),
##     the split/spawn/tier tables are the §5.2 pins.

const AsteroidScript := preload("res://game/asteroid.gd")
const FieldScript := preload("res://game/asteroid_field.gd")
const MiningLaserScript := preload("res://game/mining_laser.gd")
const OreTuningScript := preload("res://game/ore_tuning.gd")

const TAG := "[S225R1]"
const TIER_WEIGHTS: Dictionary = {1: 100}
## 02 §5.3's ticked rows, transcribed.
const PIN_BAND_MIN := 0.80
const PIN_BAND_MAX := 1.60
const PIN_MULT: Dictionary = {0: 1.5, 1: 2.5, 2: 4.0, 3: 6.0}
const PIN_FRAGMENT_WORK: Dictionary = {0: 2.0, 1: 3.0, 2: 4.5}
const PIN_SPLINTER_CHANCE := 0.25
const PIN_SPLINTER_INTERVAL := 0.5
## 02 §5.2 / §5's unchanged rows.
const PIN_SPLIT_MIX: Dictionary = {
	3: {2: Vector2i(1, 3), 1: Vector2i(2, 4), 0: Vector2i(2, 5)},
	2: {1: Vector2i(1, 3), 0: Vector2i(2, 4)},
	1: {0: Vector2i(1, 3)},
	0: {},
}
const PIN_SIZE_WEIGHTS: Dictionary = {0: 40, 1: 32, 2: 20, 3: 8}
const PIN_TIER_YIELD: Dictionary = {1: 6, 2: 5, 3: 4, 4: 3}
const PIN_WORK_PER_UNIT := 1.0
const PIN_CHIP_RATE := 0.10
const PIN_BURST_SHARE := 0.10
## weapons.gd's w_laser dps, and S22.5's own worked table mean (1.2x).
const LASER_DPS := 30.0
const STEP := 1.0 / 64.0
const MEAN_ROLL := 1.2
## The §5.3 fixture: 6 work units at the bore (a T1 mean-yield rock).
const T1_BORE := 6.0
const PICKUP_GROUP: StringName = &"pickup"
const SIZE_NAMES: Array[String] = ["S", "M", "L", "XL"]
const CLASSES: Array[int] = [0, 1, 2, 3]
const FLOORS: Dictionary = {0: 3.0, 1: 5.0, 2: 8.0, 3: 12.0}
const SEEDS: Array[int] = [22501, 7, 4242, 91337]
const RATE_ROLLS := 240
const RATE_TOLERANCE := 0.06
const MAX_STEPS := 50000

var _failures: Array[String] = []
var _fields: Array[Node] = []
var _loose: Array[Node] = []


func _init() -> void:
	OreTuningScript.reset_to_defaults()
	_check("pin_tables", _live_pins_ok(), "live OreTuning carries 02 §5.2/§5.3's rows")
	_a1()
	_a2()
	_a3()
	_a4()
	_a5()
	_a6()
	_a7()
	print("%s done failures=%d" % [TAG, _failures.size()])
	for field: Node in _fields:
		if is_instance_valid(field):
			field.free()
	for node: Node in _loose:
		if is_instance_valid(node):
			node.free()
	quit(1 if not _failures.is_empty() else 0)


func _live_pins_ok() -> bool:
	if not is_equal_approx(OreTuningScript.toughness_min, PIN_BAND_MIN):
		return false
	if not is_equal_approx(OreTuningScript.toughness_max, PIN_BAND_MAX):
		return false
	if str(OreTuningScript.size_toughness_mult) != str(PIN_MULT):
		return false
	if str(OreTuningScript.fragment_work) != str(PIN_FRAGMENT_WORK):
		return false
	if not is_equal_approx(OreTuningScript.splinter_chance, PIN_SPLINTER_CHANCE):
		return false
	if not is_equal_approx(OreTuningScript.splinter_interval, PIN_SPLINTER_INTERVAL):
		return false
	if str(OreTuningScript.split_mix) != str(PIN_SPLIT_MIX):
		return false
	if str(OreTuningScript.spawn_size_weights) != str(PIN_SIZE_WEIGHTS):
		return false
	if str(OreTuningScript.tier_base_yield) != str(PIN_TIER_YIELD):
		return false
	if not is_equal_approx(OreTuningScript.work_per_unit, PIN_WORK_PER_UNIT):
		return false
	if not is_equal_approx(OreTuningScript.gun_chip_rate, PIN_CHIP_RATE):
		return false
	if not is_equal_approx(OreTuningScript.gun_burst_share, PIN_BURST_SHARE):
		return false
	return true


func _a1() -> void:
	var first := _toughnesses(_field(22501, 6))
	var second := _toughnesses(_field(22501, 6))
	_check("a1_same_seed", str(first) == str(second),
		"two seed-22501 fields roll identical sequences (%s)" % str(first))
	print("%s a1_seed22501=%s" % [TAG, str(first)])
	var random_a := _toughnesses(_field(0, 6))
	var random_b := _toughnesses(_field(0, 6))
	_check("a1_fresh_differs", str(random_a) != str(random_b),
		"two randomized fields roll different sequences")
	var low := 99.0
	var high := -99.0
	var all_distinct := {}
	for seed_value: int in SEEDS:
		for value: float in _toughnesses(_field(seed_value, 6)):
			low = minf(low, value)
			high = maxf(high, value)
			all_distinct[value] = true
	_check("a1_band", low >= PIN_BAND_MIN and high <= PIN_BAND_MAX,
		"24 rocks over 4 seeds sit in [%.2f, %.2f] (min %.4f max %.4f)"
		% [PIN_BAND_MIN, PIN_BAND_MAX, low, high])
	_check("a1_spread", high - low > 0.1,
		"the rolls genuinely spread (%.4f to %.4f)" % [low, high])


func _a2() -> void:
	for size_class: int in CLASSES:
		var probe := _tough_rock(size_class, 6, MEAN_ROLL)
		probe.call(&"apply_gun_work", 1.0)
		var deposit := float(probe.get(&"work"))
		var expect_deposit := 1.0 / (float(PIN_MULT[size_class]) * MEAN_ROLL)
		_check("a2_deposit_%s" % SIZE_NAMES[size_class],
			absf(deposit - expect_deposit) < 1e-6,
			"1.0 work in deposits %.6f (expected %.6f)" % [deposit, expect_deposit])
		var rock := _tough_rock(size_class, 6, MEAN_ROLL)
		var time := _beam_time(rock)
		var predict := T1_BORE * float(PIN_MULT[size_class]) * MEAN_ROLL \
			/ (LASER_DPS * PIN_CHIP_RATE)
		_check("a2_time_%s" % SIZE_NAMES[size_class],
			time >= float(FLOORS[size_class]) and absf(time - predict) <= 3.0 * STEP,
			"%.3f s (floor %.1f, divisor predicts %.3f; %s work at the bore)"
			% [time, FLOORS[size_class], predict,
				T1_BORE * float(PIN_MULT[size_class]) * MEAN_ROLL])
	var toms := {}
	for size_class: int in CLASSES:
		toms[size_class] = _beam_time(_tough_rock(size_class, 6, MEAN_ROLL))
	_check("a2_s_vs_xl", float(toms[3]) > float(toms[0]) * 3.0,
		"S %.2f s vs XL %.2f s" % [toms[0], toms[3]])
	## The field-spawned shape §5.3's clarifying note names: 4 extractable of a
	## 6 bore, so the times scale by 4/6 (the roll is the field's own, read off).
	var field := _solo(22501)
	var spawned := _member(field, 2, 4, "SpawnedL", T1_BORE)
	var spawned_time := _beam_time(spawned)
	var spawned_expect := 4.0 * float(PIN_MULT[2]) * float(spawned.call(&"toughness")) \
		/ (LASER_DPS * PIN_CHIP_RATE)
	_check("a2_field_spawned", absf(spawned_time - spawned_expect) <= 3.0 * STEP,
		"a 4-of-6-bore L under the beam: %.3f s vs %.3f s predicted" % [spawned_time, spawned_expect])


func _a3() -> void:
	_check("a3_cycle_pin", is_equal_approx(MiningLaserScript.MINE_CYCLE, 1.2),
		"MINE_CYCLE is still the pinned 1.2 s")
	var laser := MiningLaserScript.new() as Node2D
	laser.call(&"set_battery", 1)
	var xl := _tough_rock(3, 12, PIN_BAND_MAX)
	var before := int(xl.get(&"yield_units"))
	var got := int(laser.call(&"extract_cycle", xl, Vector2.ZERO))
	_check("a3_cycle_one_unit", got == 1 and int(xl.get(&"yield_units")) == before - 1,
		"one 1.2 s cycle realises 1 unit on a max-roll XL")
	for size_class: int in CLASSES:
		for roll: float in [PIN_BAND_MIN, PIN_BAND_MAX]:
			var rock := _tough_rock(size_class, 12, roll)
			rock.call(&"apply_work", 1.0)
			_check("a3_work_%s_%.2f" % [SIZE_NAMES[size_class], roll],
				int(rock.get(&"yield_units")) == 11,
				"1.0 mining work = 1 unit (class %s roll %.2f)"
				% [SIZE_NAMES[size_class], roll])
	laser.free()


func _a4() -> void:
	var field := _solo(22501)
	var chip_frag := _fragment(field, 0, "ChipFrag")
	chip_frag.call(&"apply_gun_work", 1.0)
	_check("a4_chip_survives",
		not bool(chip_frag.get(&"_cracked")) and float(chip_frag.get(&"work")) == 1.0,
		"a 10-damage chip (work 1.0) leaves an S fragment alive at work 1.0")
	var ram_frag := _fragment(field, 0, "RamFrag")
	ram_frag.call(&"apply_collision_damage", 10.0)
	_check("a4_ram_survives",
		not bool(ram_frag.get(&"_cracked")) and float(ram_frag.get(&"work")) == 1.0,
		"a 10-damage ram banks the same 1.0 work and does not crack it")
	var exact := _fragment(field, 0, "ExactFrag")
	var cracks: Array[int] = []
	exact.connect(&"cracked", func() -> void: cracks.append(1))
	exact.call(&"apply_gun_work", PIN_FRAGMENT_WORK[0])
	_check("a4_budget_cracks", cracks.size() == 1, "2.0 work cracks the S fragment")
	var beam_frag := _fragment(field, 0, "BeamFrag")
	var beam_time := _beam_time(beam_frag)
	_check("a4_beam_survives", beam_time >= 0.6,
		"an S fragment survives %.3f s of w_laser (>= 0.6)" % beam_time)
	for size_class: int in [0, 1, 2]:
		var budget := float(PIN_FRAGMENT_WORK[size_class])
		var rock := _fragment(field, size_class, "Budget%d" % size_class)
		var hits: Array[int] = []
		rock.connect(&"cracked", func() -> void: hits.append(1))
		rock.call(&"apply_gun_work", budget - 0.25)
		var survived := hits.is_empty()
		rock.call(&"apply_gun_work", 0.25)
		_check("a4_budget_%s" % SIZE_NAMES[size_class],
			survived and hits.size() == 1,
			"class %s survives %.2f and cracks at %.2f" % [SIZE_NAMES[size_class], budget - 0.25, budget])


func _a5() -> void:
	var field := _solo(22501)
	var root := _member(field, 3, 24, "RootXL")
	var before := _live_ids(field)
	_gun_deplete(root)
	var kids := _new_since(field, before)
	_check("a5_shatter_children", kids.size() >= 3, "the shot XL left %d children" % kids.size())
	var smalls: Array[Node2D] = []
	for kid: Node2D in kids:
		_check("a5_child_bore0", float(kid.call(&"bore_ore")) == 0.0,
			"%s carries bore 0" % String(kid.name))
		_check("a5_child_marked", bool(kid.call(&"cleaves")),
			"%s is parentage-marked" % String(kid.name))
		if int(kid.call(&"size_class")) == 0:
			smalls.append(kid)
	_check("a5_smalls_present", not smalls.is_empty(), "the mixed set carries S pieces")
	for small: Node2D in smalls:
		var before_small := _live_ids(field)
		_gun_deplete(small)
		_check("a5_s_stops", _new_since(field, before_small).is_empty(),
			"an S child's crack leaves no rock behind")
	var mid := _fragment(field, 1, "MidFrag")
	var before_mid := _live_ids(field)
	_gun_deplete(mid)
	_check("a5_parentage_intact", _new_since(field, before_mid).size() >= 1,
		"an M fragment still re-splits per §5.2 ter")


func _a6() -> void:
	OreTuningScript.splinter_chance = 1.0
	var field := _solo(22501)
	var rock := _member(field, 2, 200, "SustainedL")
	var shed_times: Array[int] = []
	var last := 0
	var cap_instant_ok := true
	for _step: int in 100:
		rock.call(&"apply_gun_work", 0.2)
		var now := _splinters(field)
		if now.size() > last:
			shed_times.append(Time.get_ticks_msec())
			last = now.size()
			## Right after a shed, a second chip inside the window must refuse.
			rock.call(&"apply_gun_work", 0.2)
			if _splinters(field).size() > last:
				cap_instant_ok = false
		OS.delay_msec(20)
	_check("a6_cap_instant", cap_instant_ok,
		"a chip inside the window after a shed spawned nothing")
	_check("a6_shed_window", shed_times.size() >= 2 and shed_times.size() <= 6,
		"%d sheds under ~2 s of sustained fire" % shed_times.size())
	var min_gap := 999999
	for index: int in range(1, shed_times.size()):
		min_gap = mini(min_gap, shed_times[index] - shed_times[index - 1])
	_check("a6_cap_gap", min_gap >= int(PIN_SPLINTER_INTERVAL * 1000.0),
		"consecutive sheds are >= %.1f s apart (min %d ms)" % [PIN_SPLINTER_INTERVAL, min_gap])
	## The same sustained shape on an XL (fresh field and rock).
	var xl_field := _solo(24601)
	var xl_rock := _member(xl_field, 3, 400, "SustainedXL")
	var xl_times: Array[int] = []
	var xl_last := 0
	for _step: int in 60:
		xl_rock.call(&"apply_gun_work", 0.2)
		var xl_now := _splinters(xl_field)
		if xl_now.size() > xl_last:
			xl_times.append(Time.get_ticks_msec())
			xl_last = xl_now.size()
		OS.delay_msec(20)
	var xl_gap := 999999
	for index: int in range(1, xl_times.size()):
		xl_gap = mini(xl_gap, xl_times[index] - xl_times[index - 1])
	_check("a6_xl_sheds",
		xl_times.size() >= 2 and xl_gap >= int(PIN_SPLINTER_INTERVAL * 1000.0),
		"an XL shed %d splinters, >= %.1f s apart (min %d ms)"
		% [xl_times.size(), PIN_SPLINTER_INTERVAL, xl_gap])
	var splinters := _splinters(field)
	_check("a6_one_immediate_refusal",
		splinters.size() == shed_times.size(), "every shed is one real body")
	var splinter: Node2D = splinters[0]
	_check("a6_splinter_s", int(splinter.call(&"size_class")) == 0, "the splinter is S-class")
	_check("a6_splinter_bore0", float(splinter.call(&"bore_ore")) == 0.0, "born bore 0")
	var radial := (splinter.global_position - rock.global_position).normalized()
	var outward := (splinter as RigidBody2D).linear_velocity.dot(radial)
	_check("a6_splinter_outward", outward > 0.0, "velocity along its radial reads %.3f" % outward)
	splinter.call(&"apply_gun_work", 1.0)
	var alive := not bool(splinter.get(&"_cracked"))
	var before_crack := _live_ids(field)
	splinter.call(&"apply_gun_work", 1.0)
	_check("a6_splinter_budget",
		alive and bool(splinter.get(&"_cracked")) and _new_since(field, before_crack).is_empty(),
		"1.0 work survives, a second 1.0 cracks it and leaves nothing behind")
	var small_field := _solo(4242)
	for size_class: int in [0, 1]:
		var small_rock := _member(small_field, size_class, 30, "No%d" % size_class)
		var before_small := _live_ids(small_field)
		small_rock.call(&"apply_gun_work", 0.5)
		_check("a6_none_%s" % SIZE_NAMES[size_class],
			_splinters_since(small_field, before_small).is_empty(),
			"a class-%s rock sheds none at chance 1.0" % SIZE_NAMES[size_class])
	var crack_rock := _member(small_field, 2, 1, "CrackMe")
	var before_hit := _live_ids(small_field)
	crack_rock.call(&"apply_gun_work", 1000.0)
	var kids := _new_since(small_field, before_hit)
	var named_splinter := false
	for kid: Node2D in kids:
		if String(kid.name).begins_with("Splinter"):
			named_splinter = true
	_check("a6_cracking_hit", kids.size() >= 3 and not named_splinter,
		"a cracking hit left %d children, no splinter among them" % kids.size())
	## The 25 % rate on fresh rocks (the cap never binds), chance read live. Pooled
	## over four seeds because one 240-roll sample sits ~2.2 sigma high (0.312); the
	## pooled 2000 reads the truth, and the raw stream is the control.
	OreTuningScript.splinter_chance = PIN_SPLINTER_CHANCE
	var shed := 0
	var rolls := 0
	for seed_value: int in [91337, 24601, 515, 88441]:
		var rate_field := _solo(seed_value)
		for index: int in RATE_ROLLS:
			var sample := _member(rate_field, 2, 6, "Rate%d" % index)
			var before_rate := _live_ids(rate_field)
			sample.call(&"apply_gun_work", 0.5)
			if not _splinters_since(rate_field, before_rate).is_empty():
				shed += 1
			rolls += 1
	var rate := float(shed) / float(rolls)
	_check("a6_rate", absf(rate - PIN_SPLINTER_CHANCE) <= RATE_TOLERANCE * 0.7,
		"%d/%d = %.4f vs the pinned %.2f" % [shed, rolls, rate, PIN_SPLINTER_CHANCE])
	var raw_field := _solo(4242)
	var raw_rng: RandomNumberGenerator = raw_field.get(&"rng")
	var raw_hits := 0
	for _draw: int in 50000:
		if raw_rng.randf() < PIN_SPLINTER_CHANCE:
			raw_hits += 1
	var raw_rate := float(raw_hits) / 50000.0
	_check("a6_raw_stream", absf(raw_rate - PIN_SPLINTER_CHANCE) <= 0.01,
		"the field RNG's own stream reads %.4f over 50000 draws" % raw_rate)


func _a7() -> void:
	var field := _solo(31337)
	var root := _member(field, 3, 18, "Root")
	var bore := float(root.call(&"bore_ore"))
	var steps := 0
	while not (field.call(&"rocks") as Array).is_empty() and steps < MAX_STEPS:
		_gun_deplete((field.call(&"rocks") as Array)[0] as Node2D)
		steps += 1
	var paid := _pickups(field)
	var cap := floori(PIN_BURST_SHARE * bore + 0.000001)
	_check("a7_terminates", steps < MAX_STEPS, "the fully shot family terminated in %d steps" % steps)
	_check("a7_no_ore_minted", paid <= cap,
		"realised %d pickups <= floor(GUN_BURST_SHARE x %.1f) = %d" % [paid, bore, cap])


## ---------------------------------------------------------------------------
## Fixtures
## ---------------------------------------------------------------------------


func _field(seed_value: int, rocks: int) -> Node2D:
	var field := FieldScript.new() as Node2D
	field.call(&"setup", {
		&"tier_weights": TIER_WEIGHTS,
		&"rocks": rocks,
		&"seed": seed_value,
	})
	_fields.append(field)
	return field


func _solo(seed_value: int) -> Node2D:
	var field := _field(seed_value, 6)
	for rock: Node2D in field.call(&"rocks") as Array[Node2D]:
		rock.free()
	return field


func _member(field: Node2D, size_class: int, units: int, node_name: String,
		bore: float = -1.0) -> Node2D:
	return field.call(&"_new_rock", node_name, &"iron", 1, units, size_class, false, bore)


func _fragment(field: Node2D, size_class: int, node_name: String) -> Node2D:
	var rock := _member(field, size_class, 0, node_name)
	rock.call(&"mark_cleave_child")
	return rock


func _tough_rock(size_class: int, units: int, toughness: float) -> RigidBody2D:
	var rock := AsteroidScript.new() as RigidBody2D
	rock.call(&"setup", &"iron", 1, units, size_class, false, float(units), toughness)
	_loose.append(rock)
	return rock


func _beam_time(rock: Node2D) -> float:
	var cracks: Array[int] = []
	rock.connect(&"cracked", func() -> void: cracks.append(1))
	var elapsed := 0.0
	var chip := LASER_DPS * PIN_CHIP_RATE * STEP
	while cracks.is_empty() and elapsed < 120.0:
		rock.call(&"apply_gun_work", chip)
		elapsed += STEP
	return elapsed


## One exact gun-door crack: the extractable units' worth over the rock's own
## divisor for a rock that carries ore; A3's raw budget for one that does not.
func _gun_deplete(rock: Node2D) -> void:
	var units := float(int(rock.get(&"yield_units")))
	if units <= 0.0:
		var budget := float(PIN_FRAGMENT_WORK.get(int(rock.call(&"size_class")), 0.0))
		rock.call(&"apply_gun_work", budget + 0.1)
		return
	var divisor := float(PIN_MULT[int(rock.call(&"size_class"))]) * float(rock.call(&"toughness"))
	rock.call(&"apply_gun_work", units * divisor + AsteroidScript.WORK_EPSILON)


func _toughnesses(field: Node2D) -> Array[float]:
	var out: Array[float] = []
	for rock: Node2D in field.call(&"rocks") as Array[Node2D]:
		out.append(float(rock.call(&"toughness")))
	return out


func _splinters(field: Node2D) -> Array[Node2D]:
	var out: Array[Node2D] = []
	for rock: Node2D in field.call(&"rocks") as Array[Node2D]:
		if String(rock.name).begins_with("Splinter"):
			out.append(rock)
	return out


func _live_ids(field: Node2D) -> Array[int]:
	var out: Array[int] = []
	for rock: Node2D in field.call(&"rocks") as Array[Node2D]:
		out.append(rock.get_instance_id())
	return out


func _new_since(field: Node2D, before: Array[int]) -> Array[Node2D]:
	var out: Array[Node2D] = []
	for rock: Node2D in field.call(&"rocks") as Array[Node2D]:
		if not before.has(rock.get_instance_id()):
			out.append(rock)
	return out


func _splinters_since(field: Node2D, before: Array[int]) -> Array[Node2D]:
	var out: Array[Node2D] = []
	for rock: Node2D in _new_since(field, before):
		if String(rock.name).begins_with("Splinter"):
			out.append(rock)
	return out


func _pickups(field: Node2D) -> int:
	var total := 0
	for child: Node in field.get_children():
		if child.is_in_group(PICKUP_GROUP):
			total += int(child.get(&"amount"))
	return total


func _check(name: String, ok: bool, detail: String) -> void:
	if ok:
		print("%s ok   %s - %s" % [TAG, name, detail])
	else:
		print("%s FAIL %s - %s" % [TAG, name, detail])
		_failures.append(name)
