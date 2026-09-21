extends SceneTree
## slice-0 M2 probe B: the rock as a heavy rigid body (ruling 8) and ruling 17's
## tiered cleaving (ENGINE_SPEC 6/13, 02 5).
##
## Archived copy. To re-run it, copy this file to `vajb-orbit/tools/` (the brief
## keeps `tools/` holding only `build_theme.gd` and `derive_icon_tints.gd`) and:
##
##   "..._console.exe" --headless --path <proj> --script res://tools/_probe_s0m2_rocks.gd --quit-after 900
##
## The probe builds a real field in a real scene tree, so the rocks are live
## RigidBody2D bodies and the physics frame can be stepped. Where a rule lives on a
## private helper (`_new_rock`), the probe calls it: it is the only door to a field
## member with a chosen size class or a 0-unit roll, and the alternative (a second
## spawn path in the shipping file) would be worse.

const AsteroidScript := preload("res://game/asteroid.gd")
const FieldScript := preload("res://game/asteroid_field.gd")
const ShipFitScript := preload("res://game/ship_fit.gd")
const MineralCatalogScript := preload("res://game/mineral_catalog.gd")

const TIER_WEIGHTS: Dictionary = {1: 100}
const FIELD_SEED_BASE := 4100
const ROCK_COUNT := 12
const RAM_SPEED := 409.0
const PROBE_SPEED := 120.0
const DECAY_FRAMES := 60
const PICKUP_GROUP: StringName = &"pickup"

var _ok := 0
var _failed := 0
var _blocked := 0
var _world: Node2D = null
var _field: Node2D = null


func _init() -> void:
	print("=== slice0 M2 probe B: rock body + cleaving ===")
	_world = Node2D.new()
	get_root().add_child(_world)
	_build_field()
	await physics_frame
	_report_body()
	await _report_drift()
	_report_cleaving()
	await _report_bare_rock()
	_report_work_arithmetic()
	print("[SUMMARY] ok=%d failed=%d blocked=%d" % [_ok, _failed, _blocked])
	quit(1 if _failed > 0 else 0)


## A field large enough that all three size classes are present (the look is a
## uniform roll over the nine silhouettes, so 12 rocks make it a certainty).
func _build_field() -> void:
	for attempt in 12:
		if _field != null and is_instance_valid(_field):
			_field.queue_free()
		_field = FieldScript.new() as Node2D
		_world.add_child(_field)
		_field.call(&"setup", {
			&"tier_weights": TIER_WEIGHTS,
			&"rocks": ROCK_COUNT,
			&"seed": FIELD_SEED_BASE + attempt,
		})
		if not _of_size(AsteroidScript.SIZE_SMALL).is_empty() \
			and not _of_size(AsteroidScript.SIZE_MEDIUM).is_empty() \
			and not _of_size(AsteroidScript.SIZE_LARGE).is_empty():
			return


func _rocks() -> Array[Node2D]:
	return _field.call(&"rocks") as Array[Node2D]


## Live rocks of one cleaving class, in field order.
func _of_size(size_class: int) -> Array[Node2D]:
	var out: Array[Node2D] = []
	for rock: Node2D in _rocks():
		if int(rock.call(&"size_class")) == size_class:
			out.append(rock)
	return out


func _report_body() -> void:
	var rock: Node2D = _rocks()[0]
	var body := rock as RigidBody2D
	_check("body a: the rock is a rigid body", body != null and rock is RigidBody2D,
		"%s" % rock.get_class())
	var reference: Dictionary = ShipFitScript.HANDLING[AsteroidScript.ROCK_MASS_REFERENCE]
	var want_mass := float(reference[&"hull_mass"]) * AsteroidScript.ROCK_MASS_MULT
	_check("body b: mass is ROCK_MASS_MULT x the class column (%s t)" % want_mass,
		is_equal_approx(body.mass, want_mass),
		"mass=%s t (reference %s, x%s)" % [body.mass, AsteroidScript.ROCK_MASS_REFERENCE,
		AsteroidScript.ROCK_MASS_MULT])
	_check("body c: gravity is off (rocks do not fall)", body.gravity_scale == 0.0)
	_check("body d: damping replaces the project default",
		is_equal_approx(body.linear_damp, AsteroidScript.LINEAR_DAMP)
		and body.linear_damp_mode == RigidBody2D.DAMP_MODE_REPLACE,
		"linear_damp=%s mode=%s (project default %s)" % [body.linear_damp,
		body.linear_damp_mode, ProjectSettings.get_setting("physics/2d/default_linear_damp")])
	_check("body e: it never sleeps, so a contact always answers (ruling 15)",
		body.can_sleep == false)
	_check("body f: the layer is the rock layer and it masks nothing",
		body.collision_layer == AsteroidScript.COLLISION_LAYER and body.collision_mask == 0,
		"layer=%s mask=%s" % [body.collision_layer, body.collision_mask])
	var classes := {}
	for r: Node2D in _rocks():
		classes[int(r.call(&"size_class"))] = int(classes.get(int(r.call(&"size_class")), 0)) + 1
	_check("body g: the three look rows are the three cleaving classes",
		classes.has(AsteroidScript.SIZE_SMALL) and classes.has(AsteroidScript.SIZE_MEDIUM)
		and classes.has(AsteroidScript.SIZE_LARGE),
		"field of %d: %s" % [_rocks().size(), classes])
	var radius := float(rock.call(&"world_radius"))
	_check("body h: the collision circle is sized from the sprite", radius > 0.0,
		"radius=%s u" % radius)


## "a free rock drifts at most about 10 u/s": the worst ram the calibration table
## can produce, handed to a free rock, must be under the ceiling within a second.
func _report_drift() -> void:
	var rock := _rocks()[0] as RigidBody2D
	rock.linear_velocity = Vector2(RAM_SPEED, 0.0)
	var start := rock.linear_velocity.length()
	var travelled := rock.global_position
	for _frame in DECAY_FRAMES:
		await physics_frame
	var settled := rock.linear_velocity.length()
	var moved := rock.global_position.distance_to(travelled)
	_check("drift: %s u/s decays under the %s u/s ceiling within 1 s" % [RAM_SPEED,
		AsteroidScript.DRIFT_SPEED_CEILING],
		settled <= AsteroidScript.DRIFT_SPEED_CEILING,
		"%s u/s -> %s u/s after %.2f s, having moved %s u" % [start, settled,
		float(DECAY_FRAMES) / 60.0, moved])


func _report_cleaving() -> void:
	## L -> 2-3 M, repeated over every Large the field rolled.
	var larges := _of_size(AsteroidScript.SIZE_LARGE)
	## The field rolls few Large rocks, so the sample is widened with field members
	## of the same class: the count is a roll and one crack proves nothing about it.
	for _extra in 7:
		larges.append(_field.call(&"_new_rock", "ProbeLarge", &"iron", 1, 5,
			AsteroidScript.SIZE_LARGE))
	var counts: Array[int] = []
	var shared_mineral := true
	var yield_ok := true
	var speed_ok := true
	var cone_max := 0.0
	for rock: Node2D in larges:
		var before := _live_ids()
		var parent_mineral := StringName(rock.get(&"mineral_id"))
		var parent_velocity := Vector2(PROBE_SPEED, 0.0).rotated(0.7)
		(rock as RigidBody2D).linear_velocity = parent_velocity
		_deplete(rock)
		var fragments := _new_since(before)
		counts.append(fragments.size())
		for fragment: Node2D in fragments:
			if int(fragment.call(&"size_class")) != AsteroidScript.SIZE_MEDIUM:
				counts.append(-1)
			if StringName(fragment.get(&"mineral_id")) != parent_mineral:
				shared_mineral = false
			if int(fragment.get(&"yield_units")) < 1:
				yield_ok = false
			var velocity := (fragment as RigidBody2D).linear_velocity
			if not is_equal_approx(velocity.length(), parent_velocity.length()
				* AsteroidScript.FRAGMENT_EJECT_MULT):
				speed_ok = false
			cone_max = maxf(cone_max, absf(rad_to_deg(parent_velocity.angle_to(velocity))))
	_check("cleave L a: a depleted Large spawns 2-3 Medium fragments",
		not counts.is_empty() and counts.min() >= 2 and counts.max() <= 3,
		"%d Large rocks -> fragment counts %s" % [larges.size(), counts])
	_check("cleave L b: fragments inherit the parent's mineral with a re-rolled yield",
		shared_mineral and yield_ok)
	_check("cleave L c: each fragment ejects at the parent's velocity x %s"
		% AsteroidScript.FRAGMENT_EJECT_MULT, speed_ok,
		"parent %s u/s -> fragments at x%s" % [PROBE_SPEED, AsteroidScript.FRAGMENT_EJECT_MULT])
	_check("cleave L d: the eject direction stays inside the +-15 deg cone",
		cone_max <= AsteroidScript.FRAGMENT_EJECT_CONE_DEG + 0.0001,
		"widest deviation %s deg" % cone_max)

	## Field membership: fragments are field rocks from birth.
	var fields_before := _live_ids()
	var medium := _of_size(AsteroidScript.SIZE_MEDIUM)[0]
	medium.linear_velocity = Vector2(PROBE_SPEED, 0.0)
	_deplete(medium)
	var smalls := _new_since(fields_before)
	_check("cleave M a: a depleted Medium spawns exactly 2 Small fragments",
		smalls.size() == 2 and int(smalls[0].call(&"size_class")) == AsteroidScript.SIZE_SMALL,
		"%d fragment(s), class %s" % [smalls.size(), smalls[0].call(&"size_class")])
	_check("cleave F a: fragments count toward the same field",
		_live_ids().size() == fields_before.size() - 1 + smalls.size()
		and _field.call(&"is_depleted") == false,
		"rock_count %d -> %d (%d fragment(s))" % [fields_before.size(), _live_ids().size(),
		smalls.size()])

	## S -> 1-2 pickups and no rock fragments.
	var small := _of_size(AsteroidScript.SIZE_SMALL)[0]
	var smalls_before := _live_ids()
	var pickups_before := _pickups()
	_deplete(small)
	await process_frame
	_check("cleave S a: a depleted Small spawns no rock fragments",
		_new_since(smalls_before).is_empty(),
		"%d new rock(s) of %d" % [_new_since(smalls_before).size(), _rocks().size()])
	var burst := _pickups() - pickups_before
	if burst == 0 and _pickup_leaf_broken():
		_block("cleave S b: a depleted Small bursts 1-2 pickups",
			"%s does not compile in this workspace (its own env_pickup_ore_pod path is stale), so a burst spawns nothing; see the report's blocker"
			% FieldScript.PICKUP_SCRIPT)
	else:
		_check("cleave S b: a depleted Small bursts 1-2 pickups",
			burst >= 1 and burst <= 2, "%d pickup(s) in the world" % burst)


## "A yield-0 rock still cracks and despawns without fragments."
func _report_bare_rock() -> void:
	var bares_before := _live_ids()
	var bare: Node2D = _field.call(&"_new_rock", "ProbeBare", &"iron", 1, 0,
		AsteroidScript.SIZE_LARGE)
	_check("bare a: a 0-unit rock reports that it does not cleave",
		bare.call(&"cleaves") == false and int(bare.get(&"yield_units")) == 0)
	var cracked := [0]
	bare.connect(&"cracked", func() -> void: cracked[0] += 1)
	_deplete(bare)
	await process_frame
	_check("bare b: it still cracks", cracked[0] == 1)
	var gained := _new_since(bares_before).size()
	_check("bare c: it despawns bare, with no fragments",
		_live_ids().size() == bares_before.size() and gained == 0
		and not is_instance_valid(bare),
		"rock_count %d -> %d (%d fragment(s)), freed=%s" % [bares_before.size(),
		_live_ids().size(), gained, not is_instance_valid(bare)])
	var yielded: Node2D = _field.call(&"_new_rock", "ProbeYield", &"iron", 1, 4,
		AsteroidScript.SIZE_LARGE)
	_check("bare d: a rock that rolled ore does cleave", yielded.call(&"cleaves") == true)
	_deplete(yielded)


## 02 7.1 / ENGINE_SPEC 6: the chip arithmetic is untouched by slice 0.
func _report_work_arithmetic() -> void:
	var rock: Node2D = _field.call(&"_new_rock", "ProbeWork", &"iron", 1, 6,
		AsteroidScript.SIZE_SMALL)
	_check("work a: a 6-unit rock starts at 6", int(rock.get(&"yield_units")) == 6)
	var mined := 0
	for _hit in 10:
		mined += int(rock.call(&"apply_work", 0.1))
	_check("work b: ten 0.1 hits mine exactly one ore unit (the 10 % chip rate)",
		mined == 1 and int(rock.get(&"yield_units")) == 5,
		"mined=%d left=%s" % [mined, rock.get(&"yield_units")])
	_check("work c: the fractional remainder is kept, not rounded away",
		absf(float(rock.get(&"work"))) < AsteroidScript.WORK_EPSILON,
		"work=%s" % rock.get(&"work"))
	var units := int(rock.call(&"apply_work", 0.0))
	_check("work d: zero work mines nothing", units == 0)
	_deplete(rock)


## Deplete a rock through its own arithmetic (`apply_work`), the way a mining
## laser's cycles or a slice-2 gun's chips would. `WORK_PER_UNIT` is the floor so a
## 0-unit rock is still handed the positive work that cracks it.
func _deplete(rock: Node2D) -> void:
	rock.call(&"apply_work", maxf(float(int(rock.get(&"yield_units"))),
		AsteroidScript.WORK_PER_UNIT))


## The field's live rocks, by instance id, so a diff survives the array's own
## bookkeeping (a cracked rock is erased at once, a queued-free one lingers a
## frame, and fragments are appended).
func _live_ids() -> Array[int]:
	var out: Array[int] = []
	for rock: Node2D in _rocks():
		out.append(rock.get_instance_id())
	return out


## The rocks the field has gained since an id list was taken.
func _new_since(before: Array[int]) -> Array[Node2D]:
	var out: Array[Node2D] = []
	for rock: Node2D in _rocks():
		if not before.has(rock.get_instance_id()):
			out.append(rock)
	return out


## Whether the pickup leaf is unloadable right now (the asset re-layout left its
## own path stale): a script that failed to compile still loads, but cannot
## be instantiated, and `new()` on it errors instead of returning null.
func _pickup_leaf_broken() -> bool:
	var leaf := load(FieldScript.PICKUP_SCRIPT) as GDScript
	return leaf == null or not leaf.can_instantiate()


func _pickups() -> int:
	var count := 0
	for node: Node in get_root().find_children("*", "", true, false):
		if node.is_in_group(PICKUP_GROUP):
			count += 1
	return count


func _block(label: String, detail: String) -> void:
	_blocked += 1
	print("[BLOCK] %s | %s" % [label, detail])


func _check(label: String, passed: bool, detail: String = "") -> void:
	var suffix := "" if detail.is_empty() else " | " + detail
	if passed:
		_ok += 1
		print("[OK]   %s%s" % [label, suffix])
	else:
		_failed += 1
		print("[FAIL] %s%s" % [label, suffix])
