@tool
extends McpTestSuite
## Suite s22_7_splash: the S22.7 fix round (owner 2026-10-01, 02 §5.5) -- the last
## hit sets the splash. The crack's impact factor scales BOTH halves of the split:
## each rolled kind's child count (`maxi(1, roundi(roll x impact))` -- a kind the
## table gives children never rolls to zero) and the child's whole ejection vector.
## A mining crack reads the flat 0.35; a gun crack reads the last hit's raw
## delivered damage (the recorded chip work divided back by `gun_chip_rate`) over
## the 50.0 reference, clamped 0.3-2.0. The baseline kick itself is 150 -> 50 (the
## owner's ÷3 on both band ends), so the anchors are:
##
## - a gently mined M sheds exactly one S -- which IS the core now (02 §5.6, fix
##   round 2): it stays at the parent's centre, speedless behind a resting rock;
## - the route decides: a heavy gun chip recorded on the rock does not splash a
##   mining finish;
## - the reference gun hit (chip 5.0, raw 50) reads impact 1.0 -- the S14 span 3-7
##   for a Large, unscaled;
## - the rocket's 72 raw reads 1.44 -- a Large leaves 4-10 children, faster;
## - a beam-grade chip reads the 0.3 floor -- a Large leaves exactly 1M+1S;
## - a railgun-class 200 raw reads the 2.0 ceiling -- a Large leaves 6-14, and the
##   wildest splash tops out at 130 u/s per weight unit, under the pre-fix maximum.
##
## The core layer (fix round 2) is exempt from every flyer band below: it takes the
## parent's centre on the shape's half alone, whatever the impact read, and each row
## pins that law on the `Core*` body instead.
##
## Nothing awaits a frame: detached fields, seeded rolls, the
## `test_engine2_cleaving.gd` idiom.

const AsteroidScript := preload("res://game/asteroid.gd")
const FieldScript := preload("res://game/asteroid_field.gd")
const OreTuningScript := preload("res://game/ore_tuning.gd")

const TIER_WEIGHTS: Dictionary = {1: 100}
const FIELD_SEED := 20261001
const SPLASH_SEEDS := 6
const SPEED_EPSILON := 0.01
## The member rock's own centre (the burst suite's idiom).
const ORIGIN := Vector2(240.0, -80.0)

var _field: Node2D = null


func suite_name() -> String:
	return "s22_7_splash"


func setup() -> void:
	_field = null


func teardown() -> void:
	if _field != null and is_instance_valid(_field):
		_field.free()
	_field = null


## ---------------------------------------------------------------------------
## The law's own numbers, pinned
## ---------------------------------------------------------------------------


func test_the_impact_law_and_the_door_record_are_pinned() -> void:
	assert_true(is_equal_approx(AsteroidScript.SPLIT_IMPACT_MINING, 0.35),
		"SPLIT_IMPACT_MINING 0.35 (the gentle mining end)")
	assert_true(is_equal_approx(AsteroidScript.SPLIT_IMPACT_REFERENCE, 50.0),
		"SPLIT_IMPACT_REFERENCE 50.0 raw damage (the neutral anchor)")
	assert_true(is_equal_approx(AsteroidScript.SPLIT_IMPACT_FLOOR, 0.3),
		"SPLIT_IMPACT_FLOOR 0.3 (a beam's per-frame slice lands here)")
	assert_true(is_equal_approx(AsteroidScript.SPLIT_IMPACT_CEIL, 2.0),
		"SPLIT_IMPACT_CEIL 2.0 (the wildest splash)")
	assert_true(is_equal_approx(FieldScript.FRAGMENT_OUTWARD_KICK, 50.0),
		"FRAGMENT_OUTWARD_KICK 50.0 (the ÷3 baseline)")
	## The door record: each door stamps its own raw amount, and a zero hit does
	## not clobber it.
	var rock := AsteroidScript.new() as RigidBody2D
	rock.call(&"setup", &"iron", 1, 12, AsteroidScript.SIZE_XL)
	rock.call(&"apply_work", 2.0)
	assert_true(is_equal_approx(float(rock.call(&"last_hit_force")), 2.0),
		"the mining door records its work cycle")
	rock.call(&"apply_gun_work", 7.2)
	assert_true(is_equal_approx(float(rock.call(&"last_hit_force")), 7.2),
		"the gun door records its chip work")
	rock.call(&"apply_work", 0.0)
	assert_true(is_equal_approx(float(rock.call(&"last_hit_force")), 7.2),
		"a zero hit does not clobber the record")
	rock.call(&"apply_collision_damage", 186.0)
	assert_true(is_equal_approx(float(rock.call(&"last_hit_force")), 18.6),
		"the collision ram rides the gun door at its chip rate")
	rock.free()


## ---------------------------------------------------------------------------
## The gentle end -- mining
## ---------------------------------------------------------------------------


func test_a_mining_shatter_is_the_gentle_end() -> void:
	for index in SPLASH_SEEDS:
		var field := _field_with(FIELD_SEED + index)
		var parent: Node2D = field.call(
			&"_new_rock", "Gentle%d" % index, &"iron", 1, 3, AsteroidScript.SIZE_MEDIUM
		)
		parent.position = ORIGIN
		(parent as RigidBody2D).linear_velocity = Vector2.ZERO
		var before := _live_ids()
		_deplete(parent)
		var fragments := _new_since(before)
		assert_eq(fragments.size(), 1,
			"a gently mined Medium sheds exactly one Small, got %d" % fragments.size())
		for fragment: Node2D in fragments:
			assert_eq(int(fragment.call(&"size_class")), AsteroidScript.SIZE_SMALL,
				"the gentle brood is an S")
			## The core layer (02 §5.6): the M's single S child IS the core -- it
			## stays at the parent's centre, speedless behind a resting rock.
			assert_true(
				(fragment as Node2D).global_position.is_equal_approx(ORIGIN)
					and (fragment as RigidBody2D).linear_velocity.length() < SPEED_EPSILON,
				"the gently mined M's S child is the core: at the centre, speedless"
			)
		field.free()
	## An XL still leaves one child per kind the table gives (S possibly two).
	var field := _field_with(FIELD_SEED + 50)
	var xl: Node2D = field.call(
		&"_new_rock", "GentleXL", &"iron", 1, 4, AsteroidScript.SIZE_XL
	)
	xl.position = ORIGIN
	(xl as RigidBody2D).linear_velocity = Vector2.ZERO
	var before := _live_ids()
	_deplete(xl)
	var brood := _new_since(before)
	assert_true(brood.size() >= 3 and brood.size() <= 4,
		"a gently mined XL leaves 3-4 children (one per kind, S possibly two), got %d"
			% brood.size())
	for fragment: Node2D in brood:
		if String(fragment.name).begins_with("Core"):
			assert_true(
				(fragment as Node2D).global_position.is_equal_approx(ORIGIN)
					and (fragment as RigidBody2D).linear_velocity.length() < SPEED_EPSILON,
				"the gentle XL's L core stays at the centre, speedless"
			)
			continue
		var w := _weight(fragment)
		var speed := (fragment as RigidBody2D).linear_velocity.length()
		var low: float = AsteroidScript.FRAGMENT_SPEED_JITTER.x * w \
			* FieldScript.FRAGMENT_OUTWARD_KICK * AsteroidScript.SPLIT_IMPACT_MINING
		var high: float = AsteroidScript.FRAGMENT_SPEED_JITTER.y * w \
			* FieldScript.FRAGMENT_OUTWARD_KICK * AsteroidScript.SPLIT_IMPACT_MINING
		assert_true(
			speed >= low - SPEED_EPSILON and speed <= high + SPEED_EPSILON,
			"the gentle splinter sits in the 0.35 band %.2f..%.2f u/s, got %.3f"
				% [low, high, speed]
		)
	field.free()


## The route decides, not the stale record: a heavy gun chip stamped on the rock
## (raw 100, the 2.0 ceiling if it cracked) does not splash a mining finish.
func test_the_route_decides_not_the_stale_record() -> void:
	for index in SPLASH_SEEDS:
		var field := _field_with(FIELD_SEED + 100 + index)
		var parent: Node2D = field.call(
			&"_new_rock", "Mixed%d" % index, &"iron", 1, 4, AsteroidScript.SIZE_LARGE
		)
		parent.position = ORIGIN
		(parent as RigidBody2D).linear_velocity = Vector2.ZERO
		var before := _live_ids()
		## The shed cap is suppressed for both calls: a non-cracking gun chip may
		## shed an A4 splinter, and that shed would join `rocks` and read as brood.
		var chance := OreTuningScript.splinter_chance
		OreTuningScript.splinter_chance = 0.0
		parent.call(&"apply_gun_work", 10.0)
		if is_instance_valid(parent) and not bool(parent.call(&"is_depleted")):
			parent.call(&"apply_work", 4.0)
		OreTuningScript.splinter_chance = chance
		var fragments := _new_since(before)
		assert_eq(fragments.size(), 2,
			"the mining finish sheds the gentle 1M+1S brood whatever the gun chip read, got %d"
				% fragments.size())
		for fragment: Node2D in fragments:
			if String(fragment.name).begins_with("Core"):
				continue
			var w := _weight(fragment)
			var speed := (fragment as RigidBody2D).linear_velocity.length()
			assert_true(
				speed <= AsteroidScript.FRAGMENT_SPEED_JITTER.y * w \
					* FieldScript.FRAGMENT_OUTWARD_KICK \
					* AsteroidScript.SPLIT_IMPACT_MINING + SPEED_EPSILON,
				"the mining finish's children leave slow (<= %.2f u/s for weight %.3f), got %.3f"
					% [
						AsteroidScript.FRAGMENT_SPEED_JITTER.y * w
						* FieldScript.FRAGMENT_OUTWARD_KICK
						* AsteroidScript.SPLIT_IMPACT_MINING,
						w, speed,
					]
			)
		field.free()


## ---------------------------------------------------------------------------
## The gun end -- the last hit scales both halves
## ---------------------------------------------------------------------------


func test_a_gun_shatter_scales_with_the_last_hit() -> void:
	## The anchors: (chip work, brood low, brood high, impact) for a Large. The
	## reference hit reads 1.0 and keeps the S14 span; the rocket's 72 raw reads
	## 1.44; a beam-grade chip reads the 0.3 floor; a railgun-class hit reads the
	## 2.0 ceiling.
	var anchors := [
		{"chip": 5.0, "low": 3, "high": 7, "impact": 1.0, "label": "reference"},
		{"chip": 7.2, "low": 4, "high": 10, "impact": 1.44, "label": "rocket"},
		{"chip": 1.0, "low": 2, "high": 2, "impact": 0.3, "label": "beam-floor"},
		{"chip": 20.0, "low": 6, "high": 14, "impact": 2.0, "label": "ceiling"},
	]
	for anchor: Dictionary in anchors:
		var counts: Array[int] = []
		var speeds: Array[float] = []
		var weights: Array[float] = []
		for index in SPLASH_SEEDS:
			var field := _field_with(FIELD_SEED + 200 + index)
			var parent: Node2D = field.call(
				&"_new_rock", "%s%d" % [anchor["label"], index],
				&"iron", 1, 4, AsteroidScript.SIZE_LARGE
			)
			parent.position = ORIGIN
			(parent as RigidBody2D).linear_velocity = Vector2.ZERO
			var before := _live_ids()
			_crack_with_chip(parent, float(anchor["chip"]))
			var fragments := _new_since(before)
			counts.append(fragments.size())
			for fragment: Node2D in fragments:
				if String(fragment.name).begins_with("Core"):
					## The core layer ignores the impact factor: at the parent's
					## centre, speedless behind a resting rock, whatever the hit read.
					assert_true(
						(fragment as Node2D).global_position.is_equal_approx(ORIGIN)
							and (fragment as RigidBody2D).linear_velocity.length() < SPEED_EPSILON,
						"the %s hit's core stays at the centre, speedless" % anchor["label"]
					)
					continue
				speeds.append((fragment as RigidBody2D).linear_velocity.length())
				weights.append(_weight(fragment))
			field.free()
		assert_true(counts.min() >= int(anchor["low"]) and counts.max() <= int(anchor["high"]),
			"the %s hit's Large brood sits in %d-%d, got %s"
				% [anchor["label"], anchor["low"], anchor["high"], str(counts)])
		for index: int in speeds.size():
			var low: float = AsteroidScript.FRAGMENT_SPEED_JITTER.x * weights[index] \
				* FieldScript.FRAGMENT_OUTWARD_KICK * float(anchor["impact"])
			var high: float = AsteroidScript.FRAGMENT_SPEED_JITTER.y * weights[index] \
				* FieldScript.FRAGMENT_OUTWARD_KICK * float(anchor["impact"])
			assert_true(
				speeds[index] >= low - SPEED_EPSILON and speeds[index] <= high + SPEED_EPSILON,
				"the %s hit's children sit in the %.2f band %.2f..%.2f u/s, got %.3f"
					% [anchor["label"], float(anchor["impact"]), low, high, speeds[index]]
			)
		print(
			"[S227F] %s hit (chip %.1f, impact %.2f): brood %d..%d, speeds %.1f..%.1f u/s"
			% [anchor["label"], float(anchor["chip"]), float(anchor["impact"]),
			counts.min(), counts.max(), speeds.min(), speeds.max()]
		)


## ---------------------------------------------------------------------------
## Helpers
## ---------------------------------------------------------------------------


func _field_with(seed_value: int, count: int = 6) -> Node2D:
	_field = FieldScript.new() as Node2D
	_field.call(&"setup", {
		&"tier_weights": TIER_WEIGHTS,
		&"rocks": count,
		&"seed": seed_value,
	})
	return _field


func _live_ids() -> Array[int]:
	var out: Array[int] = []
	for rock: Node2D in _field.call(&"rocks"):
		out.append(rock.get_instance_id())
	return out


func _new_since(before: Array[int]) -> Array[Node2D]:
	var out: Array[Node2D] = []
	for rock: Node2D in _field.call(&"rocks"):
		if not before.has(rock.get_instance_id()):
			out.append(rock)
	return out


## Deplete through the mining door (the gentle end).
func _deplete(rock: Node2D) -> void:
	rock.call(&"apply_work", maxf(float(int(rock.get(&"yield_units"))), 1.0))


## Crack through the gun door at an exact chip work, so `_split_impact` reads the
## anchor the caller chose. The A4 splinter sheds are suppressed for the loop (a
## shed joins `rocks` and would pollute the brood counts); the chance is restored
## before the helper returns.
func _crack_with_chip(rock: Node2D, chip: float) -> void:
	var chance := OreTuningScript.splinter_chance
	OreTuningScript.splinter_chance = 0.0
	for _attempt in 256:
		if not is_instance_valid(rock) or bool(rock.call(&"is_depleted")):
			break
		rock.call(&"apply_gun_work", chip)
	OreTuningScript.splinter_chance = chance


## The ejection row's mass weight, read off a body's own mass.
func _weight(fragment: Node2D) -> float:
	return pow(
		AsteroidScript.ROCK_MASS_M / (fragment as RigidBody2D).mass,
		AsteroidScript.FRAGMENT_MASS_SPEED_EXP
	)
