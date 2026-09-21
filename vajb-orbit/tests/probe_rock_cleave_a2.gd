extends Node2D
## A2 review probe - the rock-cleave wave re-measured from scratch.
##
## The reviewer's instrument: it does not read A1's probe, it re-derives every number
## the brief's section 1 table pins, with a **different seed** (`424242`, not A1's
## `20260921`) and a **different parent heading and speed** (137 u/s at -1.1 rad, not
## 120 at 0.7), so a match is a match of the shipped code rather than of one seeded
## sequence.
##
##   CONST  - the two cleaving rows, the pickup row, the ejection pair, as shipped;
##   COUNT  - 300 cleaves per cleaving tier: bounds, the four values' histogram and a
##            chi-square against uniform (a constant row or a narrowed one cannot pass);
##   DIR    - 150 cleaves: deviation from the parent heading, the mean resultant length
##            and an 8-sector histogram (uniform over the circle), the widest within-
##            cleave pair, and the share of fragments the retired +-15 deg cone could
##            have produced;
##   SPEED  - |eject| / |parent velocity| per fragment, against section 13's 1.2;
##   FX     - Large / Medium / Small breaks: one sprite per break, on the rock's centre,
##            scaled `clamp(1.2 x diameter, 96, 224)`, five frames, loop false, alpha
##            blend and an `animation_finished` free (FX_SPEC section 1.4 / 7.3);
##   CUE    - the pool row, every take's file, the round-robin and the played cue;
##   BARE   - a yield-0 rock: no fragments, but the FX and the cue still fire;
##   BURST  - a Small: 1-2 pickups carrying the rock's own ore id, and the FX/cue;
##   INHERIT- a cleave's fragments: parent mineral, parent tier, one tier down, and a
##            re-rolled yield inside 02 section 5's band;
##   INVARIANT - the mining rates, the mass/damping/layer terms and section 13's
##            collision/recoil/explosion rows, read off their owners;
##   RESPAWN - 02 section 8's bookkeeping: the stamp, the depletion guard, the five-
##            minute window and the x0.7 band on a respawned field.
##
## Run:  godot --headless --path vajb-orbit res://tests/probe_rock_cleave_a2.tscn --quit-after 900
## Signal: the `[A2]` lines; the last is `[A2] done`.

const FieldScript := preload("res://game/asteroid_field.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const ImpactScript := preload("res://game/impact.gd")
const FxScript := preload("res://game/fx.gd")
const AudioScript := preload("res://autoload/audio_manager.gd")
const MineralScript := preload("res://game/mineral_catalog.gd")
const LaserScript := preload("res://game/mining_laser.gd")
const WeaponsScript := preload("res://game/weapons.gd")
const Clock := preload("res://autoload/world_clock.gd")

const TAG := "[A2]"
const AUDIO_SERVICE: StringName = &"AudioManager"
const PICKUP_SCRIPT := "res://game/pickup.gd"
const EXPLOSION_NAME := "explosion"
const TIER_WEIGHTS: Dictionary = {1: 100}
const FIELD_SEED := 424242
const LOOK_SEED := 20260922
const FIELD_OFFSET := Vector2(37.0, -19.0)
const UNIT_TIER := 1
const UNIT_MINERAL: StringName = &"iron"
const COUNT_CLEAVES := 300
const DIR_CLEAVES := 150
const SECTORS := 8
const PARENT_SPEED := 137.0
const PARENT_HEADING := -1.1
const BURST_SMALLS := 40
const INHERIT_CLEAVES := 30
const BLAST_NEAR := 20.0
const BLAST_FAR := 200.0
const BLAST_FRAMES := 20
const CUE_LINE: StringName = &"sfx_impact_rock"

var _field: Node2D = null
var _audio: Node = null
var _rock_index := 0
var _failures: Array[String] = []
var _fx_source := Vector2.ZERO


func _ready() -> void:
	_audio = get_tree().root.get_node_or_null(NodePath(AUDIO_SERVICE))
	_fx_source = ProjectileScript.feedback_row(&"explosion").get(&"source", Vector2.ZERO)
	_field = FieldScript.new() as Node2D
	_field.name = &"A2Field"
	add_child(_field)
	## A non-zero field offset, so "the FX sits on the rock's centre" is measured in
	## global space rather than being an accident of a field at the origin.
	_field.position = FIELD_OFFSET
	_field.call(&"setup", {
		&"tier_weights": TIER_WEIGHTS,
		&"rocks": 6,
		&"seed": FIELD_SEED,
	})
	print("%s boot audio=%s rocks=%d source=%s pickup_leaf=%s" % [
		TAG,
		_audio != null,
		int(_field.call(&"rock_count")),
		_fx_source,
		_pickup_leaf_ok(),
	])
	_constants()
	_count_distribution()
	_direction_and_speed()
	_fx_sizes()
	_cue_row()
	_yield_zero()
	_small_burst()
	_inheritance()
	_invariants()
	await _blast()
	_respawn_bookkeeping()
	_teardown()
	print("%s done failures=%d" % [TAG, _failures.size()])
	get_tree().quit(1 if _failures.size() > 0 else 0)


## --- fixtures -----------------------------------------------------------------


func _member(size_class: int, units: int, at: Vector2 = Vector2.ZERO) -> Node2D:
	_rock_index += 1
	var rock: Node2D = _field.call(
		&"_new_rock", "A2Rock%d" % _rock_index, UNIT_MINERAL, UNIT_TIER, units, size_class
	)
	rock.position = at
	return rock


## Crack a rock through its own arithmetic, with `WORK_PER_UNIT` as the floor so a
## 0-unit rock gets the positive work that cracks it.
func _deplete(rock: Node2D) -> void:
	rock.call(
		&"apply_work",
		maxf(float(int(rock.get(&"yield_units"))), AsteroidScript.WORK_PER_UNIT)
	)


func _live_ids(field: Node2D = null) -> Array[int]:
	var target: Node2D = field if field != null else _field
	var out: Array[int] = []
	for rock: Node2D in target.call(&"rocks") as Array[Node2D]:
		out.append(rock.get_instance_id())
	return out


func _fragments_since(before: Array[int], field: Node2D = null) -> Array[Node2D]:
	var target: Node2D = field if field != null else _field
	var out: Array[Node2D] = []
	for rock: Node2D in target.call(&"rocks") as Array[Node2D]:
		if not before.has(rock.get_instance_id()):
			out.append(rock)
	return out


## A cleave that hands back only the fragments it made, dropped again so the field
## never grows past one cleave (300 cleaves would otherwise pile 1 500 bodies into a
## single frame).
func _cleave_once(size_class: int, at: Vector2, heading: Vector2 = Vector2.ZERO) -> Array[Node2D]:
	var parent := _member(size_class, 4, at)
	if heading != Vector2.ZERO:
		(parent as RigidBody2D).linear_velocity = heading
	var before := _live_ids()
	_deplete(parent)
	return _fragments_since(before)


func _free_rocks(list: Array[Node2D]) -> void:
	for rock: Node2D in list:
		if is_instance_valid(rock):
			rock.free()


func _scene() -> Node:
	var scene := get_tree().current_scene
	return scene if scene != null else self


func _explosions() -> Array[Node]:
	var out: Array[Node] = []
	for node: Node in _scene().find_children("*", "AnimatedSprite2D", true, false):
		if String(node.name).begins_with(EXPLOSION_NAME):
			out.append(node)
	return out


func _pickups() -> Array[Node]:
	var out: Array[Node] = []
	for node: Node in _scene().find_children("*", "Node2D", true, false):
		var script := node.get_script() as Script
		if script != null and script.resource_path == PICKUP_SCRIPT:
			out.append(node)
	return out


func _free_fx() -> void:
	for sprite: Node in _explosions():
		if is_instance_valid(sprite):
			sprite.free()


func _free_pickups() -> void:
	for pickup: Node in _pickups():
		if is_instance_valid(pickup):
			pickup.free()


func _pickup_leaf_ok() -> bool:
	var leaf := load(PICKUP_SCRIPT) as GDScript
	return leaf != null and leaf.can_instantiate()


func _cue() -> String:
	return String(_audio.call(&"last_sfx")) if _audio != null else ""


func _check(label: String, ok: bool, note: String) -> void:
	if not ok:
		_failures.append(label)
	print("%s %s %s - %s" % [TAG, "ok  " if ok else "FAIL", label, note])


## --- CONST: the rows as shipped ------------------------------------------------


func _constants() -> void:
	var split: Dictionary = AsteroidScript.FRAGMENT_SPLIT
	print("%s CONST split=%s pickup=%s mult=%.4f cone=%.4f"
		% [
			TAG,
			split,
			AsteroidScript.PICKUP_BURST,
			AsteroidScript.FRAGMENT_EJECT_MULT,
			AsteroidScript.FRAGMENT_EJECT_CONE_DEG,
		])
	_check(
		"const_large_row",
		(split.get(AsteroidScript.SIZE_LARGE, Vector2i.ZERO) as Vector2i) == Vector2i(2, 5),
		"Large -> uniform 2-5 (was (2,3))"
	)
	_check(
		"const_medium_row",
		(split.get(AsteroidScript.SIZE_MEDIUM, Vector2i.ZERO) as Vector2i) == Vector2i(2, 5),
		"Medium -> uniform 2-5 (was (2,2))"
	)
	_check(
		"const_small_row",
		(split.get(AsteroidScript.SIZE_SMALL, Vector2i.ZERO) as Vector2i) == Vector2i(0, 0),
		"Small -> no rock fragments"
	)
	_check(
		"const_pickup_and_speed",
		AsteroidScript.PICKUP_BURST == Vector2i(1, 2)
			and is_equal_approx(AsteroidScript.FRAGMENT_EJECT_MULT, 1.2),
		"small bursts 1-2 pickups and ejection stays x1.2"
	)
	_check(
		"const_cone_is_full_circle",
		is_equal_approx(AsteroidScript.FRAGMENT_EJECT_CONE_DEG, 360.0),
		"the +-15 deg cone is retired (360.0 = the whole circle)"
	)


## --- COUNT: 300 cleaves per tier ------------------------------------------------


func _count_distribution() -> void:
	for size_class: int in [AsteroidScript.SIZE_LARGE, AsteroidScript.SIZE_MEDIUM]:
		var label := "Large" if size_class == AsteroidScript.SIZE_LARGE else "Medium"
		var histogram: Dictionary = {}
		var landed: Dictionary = {}
		var lowest := 99
		var highest := -1
		for index in COUNT_CLEAVES:
			var fragments := _cleave_once(size_class, Vector2(900.0, float(index % 40) * 4.0))
			var count := fragments.size()
			histogram[count] = int(histogram.get(count, 0)) + 1
			lowest = mini(lowest, count)
			highest = maxi(highest, count)
			for fragment: Node2D in fragments:
				landed[int(fragment.call(&"size_class"))] = true
			_free_rocks(fragments)
			_free_fx()
		var expected := float(COUNT_CLEAVES) / 4.0
		var chi2 := 0.0
		var shares: Array[String] = []
		for value: int in [2, 3, 4, 5]:
			var observed := float(histogram.get(value, 0))
			chi2 += pow(observed - expected, 2.0) / expected
			shares.append("%d:%d" % [value, int(observed)])
		print("%s COUNT %s n=%d min=%d max=%d hist={%s} chi2=%.2f landed=%s"
			% [TAG, label, COUNT_CLEAVES, lowest, highest, ", ".join(shares), chi2, landed.keys()])
		_check(
			"count_%s_bounds" % label,
			lowest >= 2 and highest <= 5,
			"every one of %d %s cleaves rolled inside 2-5" % [COUNT_CLEAVES, label]
		)
		_check(
			"count_%s_all_values" % label,
			histogram.has(2) and histogram.has(3) and histogram.has(4) and histogram.has(5),
			"all four counts 2,3,4,5 came up"
		)
		_check(
			"count_%s_uniform" % label,
			chi2 <= 16.27,
			"chi-square %.2f against uniform over 4 counts (95%% critical 7.81, 99.9%% 16.27)" % chi2
		)
		_check(
			"count_%s_size" % label,
			landed.size() == 1 and landed.has(size_class - 1),
			"a %s's fragments are one tier down (%s)" % [label, landed.keys()]
		)


## --- DIR + SPEED: the full circle ------------------------------------------------


func _direction_and_speed() -> void:
	var heading := Vector2(PARENT_SPEED, 0.0).rotated(PARENT_HEADING)
	var deviations: Array[float] = []
	var ratios: Array[float] = []
	var sector_counts: Array[int] = []
	for index in SECTORS:
		sector_counts.append(0)
	var widest := 0.0
	var widest_at := -1
	var inside_cone := 0
	for index in DIR_CLEAVES:
		var fragments := _cleave_once(
			AsteroidScript.SIZE_LARGE, Vector2(-1600.0, float(index % 40) * 4.0), heading
		)
		var local: Array[float] = []
		for fragment: Node2D in fragments:
			var ejected: Vector2 = (fragment as RigidBody2D).linear_velocity
			var deviation := rad_to_deg(heading.angle_to(ejected))
			deviations.append(deviation)
			ratios.append(ejected.length() / heading.length())
			local.append(rad_to_deg(ejected.angle()))
			if absf(deviation) < 15.0:
				inside_cone += 1
			var sector := int(floor(fposmod(ejected.angle(), TAU) / (TAU / float(SECTORS))))
			sector_counts[clampi(sector, 0, SECTORS - 1)] += 1
		for a: float in local:
			for b: float in local:
				var gap := absf(wrapf(a - b, -180.0, 180.0))
				if gap > widest:
					widest = gap
					widest_at = index
		_free_rocks(fragments)
		_free_fx()
	var n := deviations.size()
	var sum_cos := 0.0
	var sum_sin := 0.0
	for value: float in deviations:
		var radians := deg_to_rad(value)
		sum_cos += cos(radians)
		sum_sin += sin(radians)
	var resultant := sqrt(sum_cos * sum_cos + sum_sin * sum_sin) / maxf(float(n), 1.0)
	var expected := float(n) / float(SECTORS)
	var chi2 := 0.0
	for count: int in sector_counts:
		chi2 += pow(float(count) - expected, 2.0) / expected
	print("%s DIR n=%d resultant=%.4f chi2_%dsector=%.2f sectors=%s widest_pair=%.3f (cleave %d) inside_15=%.1f%% min=%.3f max=%.3f"
		% [
			TAG,
			n,
			resultant,
			SECTORS,
			chi2,
			sector_counts,
			widest,
			widest_at,
			100.0 * float(inside_cone) / maxf(float(n), 1.0),
			deviations.min(),
			deviations.max(),
		])
	_check(
		"dir_full_circle",
		deviations.max() > 170.0 and deviations.min() < -170.0,
		"fragments land on both far sides of the parent heading (%.1f / %.1f deg): a +-15 deg cone cannot"
			% [deviations.min(), deviations.max()]
	)
	_check(
		"dir_uniform_resultant",
		resultant < 0.15,
		"mean resultant length %.4f over %d fragments (0 = uniform; a cone reads near 1)" % [resultant, n]
	)
	_check(
		"dir_uniform_sectors",
		chi2 <= 16.27,
		"%d-sector chi-square %.2f (95%% critical 14.07, 99.9%% 24.32) over counts %s"
			% [SECTORS, chi2, sector_counts]
	)
	_check(
		"dir_pair_spread",
		widest > 90.0,
		"the widest within-cleave pair is %.1f deg (cleave %d)" % [widest, widest_at]
	)
	print("%s SPEED n=%d min=%.6f max=%.6f parent_speed=%.3f"
		% [TAG, ratios.size(), ratios.min(), ratios.max(), heading.length()])
	_check(
		"speed_is_x1_2",
		is_equal_approx(ratios.min(), 1.2) and is_equal_approx(ratios.max(), 1.2),
		"every one of %d fragments ejects at the parent's velocity x 1.2" % ratios.size()
	)


## --- FX: the break's explosion ---------------------------------------------------


func _fx_sizes() -> void:
	for row: Array in [
		["Large", AsteroidScript.SIZE_LARGE, 132.0],
		["Medium", AsteroidScript.SIZE_MEDIUM, 84.0],
		["Small", AsteroidScript.SIZE_SMALL, 48.0],
	]:
		var label: String = row[0]
		var size_class: int = row[1]
		var centre := Vector2(-400.0 + float(size_class) * 60.0, 260.0)
		var rock := _member(size_class, 4, centre)
		var diameter := 2.0 * float(rock.call(&"world_radius"))
		var rock_local: Vector2 = rock.position
		var global_centre: Vector2 = rock.global_position
		var before := _explosions().size()
		_deplete(rock)
		var after := _explosions()
		var sprite := after[after.size() - 1] as AnimatedSprite2D if after.size() > before else null
		var world_target := clampf(diameter * 1.2, 96.0, 224.0)
		var scale_factor := world_target / maxf(_fx_source.x, _fx_source.y)
		print("%s FX %s rock_local=%s rock_global=%s sprite_local=%s sprite_global=%s diameter=%.4f world=%.4f scale=%.6f frames=%d fps=%.1f loop=%s mix=%s freed_on_finish=%s z=%d"
			% [
				TAG,
				label,
				str(rock_local),
				str(global_centre),
				str(sprite.position) if sprite != null else "-",
				str(sprite.global_position) if sprite != null else "-",
				diameter,
				world_target,
				sprite.scale.x if sprite != null else -1.0,
				sprite.sprite_frames.get_frame_count(FxScript.ANIMATION) if sprite != null else -1,
				sprite.sprite_frames.get_animation_speed(FxScript.ANIMATION) if sprite != null else -1.0,
				sprite.sprite_frames.get_animation_loop(FxScript.ANIMATION) if sprite != null else "-",
				(sprite.material as CanvasItemMaterial).blend_mode if sprite != null else -1,
				sprite.animation_finished.get_connections().size() if sprite != null else -1,
				sprite.z_index if sprite != null else -99,
			])
		_check(
			"fx_%s_count" % label,
			after.size() == before + 1,
			"one explosion sprite for one %s break (%d -> %d)" % [label, before, after.size()]
		)
		_check(
			"fx_%s_centre" % label,
			sprite != null and sprite.global_position.distance_to(global_centre) < 0.001,
			"the sequence sits on the rock's own global centre %s (field offset %s)"
				% [global_centre, FIELD_OFFSET]
		)
		_check(
			"fx_%s_world" % label,
			sprite != null and is_equal_approx(sprite.scale.x, scale_factor),
			"scaled to clamp(1.2 x %.1f u, 96, 224) = %.2f u (scale %.6f)"
				% [diameter, world_target, scale_factor]
		)
		_check(
			"fx_%s_wiring" % label,
			sprite != null
				and sprite.sprite_frames.get_frame_count(FxScript.ANIMATION) == 5
				and not sprite.sprite_frames.get_animation_loop(FxScript.ANIMATION)
				and (sprite.material as CanvasItemMaterial).blend_mode == CanvasItemMaterial.BLEND_MODE_MIX
				and sprite.animation_finished.get_connections().size() >= 1,
			"FX_SPEC 1.4/7.3: 5 frames, loop false, alpha blend, freed on animation_finished"
		)
	_free_fx()


## --- CUE: the rock cue's pool row -----------------------------------------------


func _cue_row() -> void:
	var row: Dictionary = AudioScript.CUE_POOLS.get(CUE_LINE, {})
	var takes: Array = row.get(&"takes", [])
	var paths: Array[String] = []
	if _audio != null:
		for index in takes.size():
			var plan: Dictionary = _audio.call(&"play_pool", CUE_LINE, index)
			paths.append(String(plan.get(&"path", "-none-")))
	print("%s CUE row takes=%s mode=%s pitch=%s volume=%s files=%s"
		% [
			TAG,
			takes,
			row.get(&"mode", "-"),
			row.get(&"pitch", "-"),
			row.get(&"volume_db", "-"),
			paths,
		])
	_check(
		"cue_row_shape",
		takes.size() == 4
			and StringName(row.get(&"mode", &"")) == AudioScript.POOL_ROUND_ROBIN
			and is_equal_approx(float(row.get(&"pitch", -1.0)), 0.0)
			and row.get(&"volume_db", []) == [0.0, 0.0],
		"four takes, round-robin, pitch 0.0, volume_db [0.0, 0.0]"
	)
	_check(
		"cue_takes_resolve",
		paths.size() == 4 and not paths.has("-none-") and not paths.has(""),
		"every one of the four take files loads (%s)" % [paths]
	)
	_check(
		"cue_has_pool",
		_audio != null and bool(_audio.call(&"has_pool", CUE_LINE)),
		"AudioManager.has_pool(%s) is true" % CUE_LINE
	)
	var rock := _member(AsteroidScript.SIZE_LARGE, 4, Vector2(700.0, 320.0))
	if _audio != null:
		_audio.call(&"play_sfx", &"sfx_impact_hull")
	var seed_cue := _cue()
	_deplete(rock)
	var played := _cue()
	print("%s CUE break played=%s (seeded %s) in_row=%s"
		% [TAG, played, seed_cue, takes.has(StringName(played))])
	_check(
		"cue_break_plays_a_take",
		takes.has(StringName(played)) and played != seed_cue,
		"the break played %s, a take of the row" % played
	)
	var cycle: Array[String] = [played]
	if _audio != null:
		for _index in 5:
			_audio.call(&"play_pool", CUE_LINE)
			cycle.append(_cue())
	print("%s CUE round_robin=%s" % [TAG, cycle])
	_check(
		"cue_round_robin_advances",
		cycle[0] != cycle[1] and cycle[1] != cycle[2] and cycle[2] != cycle[3] and cycle[3] != cycle[4],
		"consecutive reads never repeat the previous take"
	)
	_free_fx()


## --- BARE: a yield-0 rock --------------------------------------------------------


func _yield_zero() -> void:
	var bare := _member(AsteroidScript.SIZE_LARGE, 0, Vector2(-900.0, -200.0))
	var before := _live_ids()
	var fx_before := _explosions().size()
	if _audio != null:
		_audio.call(&"play_sfx", &"sfx_impact_hull")
	var cue_before := _cue()
	_deplete(bare)
	var fragments := _fragments_since(before)
	var cue_after := _cue()
	print("%s BARE cleaves=%s fragments=%d fx=%d->%d cue=%s (seeded %s) live=%d->%d"
		% [
			TAG,
			bare.call(&"cleaves"),
			fragments.size(),
			fx_before,
			_explosions().size(),
			cue_after,
			cue_before,
			before.size(),
			_live_ids().size(),
		])
	_check(
		"bare_no_fragments_but_zero_yield",
		bare.call(&"cleaves") == false and fragments.size() == 0
			and _live_ids().size() == before.size() - 1,
		"ruling 17: a yield-0 rock cracks, leaves no fragment and despawns"
	)
	_check(
		"bare_still_reads_the_break",
		_explosions().size() == fx_before + 1
			and StringName(cue_after) != StringName(cue_before)
			and AudioScript.CUE_POOLS[CUE_LINE][&"takes"].has(StringName(cue_after)),
		"but it still explodes and still plays the rock cue"
	)
	_free_fx()


## --- BURST: a Small's pickups ----------------------------------------------------


func _small_burst() -> void:
	var counts: Array[int] = []
	var items: Dictionary = {}
	var fragment_counts: Array[int] = []
	var ore_id := MineralScript.ore_id(UNIT_MINERAL)
	for index in BURST_SMALLS:
		var small := _member(AsteroidScript.SIZE_SMALL, 4, Vector2(-300.0 + float(index) * 6.0, -400.0))
		var live_before := _live_ids()
		var pickups_before := _pickups().size()
		var fx_before := _explosions().size()
		_deplete(small)
		counts.append(_pickups().size() - pickups_before)
		fragment_counts.append(_fragments_since(live_before).size())
		for pickup: Node in _pickups():
			items[StringName(pickup.get(&"item_id"))] = true
		if _explosions().size() != fx_before + 1:
			_failures.append("small_%d_no_fx" % index)
		_free_pickups()
		_free_fx()
	print("%s BURST n=%d counts=%s min=%d max=%d ore_id=%s items=%s small_fragments=%s"
		% [
			TAG,
			BURST_SMALLS,
			counts,
			counts.min(),
			counts.max(),
			ore_id,
			items.keys(),
			fragment_counts.max(),
		])
	_check(
		"burst_bounds",
		counts.min() >= 1 and counts.max() <= 2,
		"%d Small breaks burst 1-2 pickups (min %d, max %d)" % [BURST_SMALLS, counts.min(), counts.max()]
	)
	_check(
		"burst_is_the_rocks_own_ore",
		items.size() == 1 and items.has(ore_id),
		"every pickup carries the rock's mineral (%s)" % items.keys()
	)
	_check(
		"burst_no_rock_fragments",
		fragment_counts.max() == 0,
		"a Small spawns no rock fragments (there is no tier below it)"
	)


## --- INHERITANCE: what a fragment carries ---------------------------------------


func _inheritance() -> void:
	var parent_mineral := UNIT_MINERAL
	var parent_tier := UNIT_TIER
	var minerals: Dictionary = {}
	var tiers: Dictionary = {}
	var classes: Dictionary = {}
	var yields: Array[int] = []
	var made := 0
	for index in INHERIT_CLEAVES:
		var parent := _member(AsteroidScript.SIZE_MEDIUM, 4, Vector2(1200.0, -300.0 + float(index) * 8.0))
		parent_mineral = StringName(parent.get(&"mineral_id"))
		parent_tier = int(parent.get(&"tier"))
		var before := _live_ids()
		_deplete(parent)
		var fragments := _fragments_since(before)
		made += fragments.size()
		for fragment: Node2D in fragments:
			minerals[StringName(fragment.get(&"mineral_id"))] = true
			tiers[int(fragment.get(&"tier"))] = true
			classes[int(fragment.call(&"size_class"))] = true
			yields.append(int(fragment.get(&"yield_units")))
		_free_rocks(fragments)
	var lo: int = maxi(1, roundi(float(MineralScript.TIER_BASE_YIELD[parent_tier]) * MineralScript.YIELD_VARIANCE_MIN))
	var hi: int = maxi(1, roundi(float(MineralScript.TIER_BASE_YIELD[parent_tier]) * MineralScript.YIELD_VARIANCE_MAX))
	print("%s INHERIT cleaves=%d n=%d parent=(%s,%d) minerals=%s tiers=%s classes=%s yields=%s band=%d-%d"
		% [
			TAG,
			INHERIT_CLEAVES,
			made,
			parent_mineral,
			parent_tier,
			minerals.keys(),
			tiers.keys(),
			classes.keys(),
			yields,
			lo,
			hi,
		])
	_check(
		"inherit_mineral_and_tier",
		minerals.size() == 1 and minerals.has(parent_mineral) and tiers.size() == 1 and tiers.has(parent_tier),
		"02 section 5: every fragment carries the parent's mineral and tier"
	)
	_check(
		"inherit_size_class",
		classes.size() == 1 and classes.has(AsteroidScript.SIZE_SMALL),
		"a Medium's fragments are Small"
	)
	_check(
		"inherit_yield_rerolled",
		yields.size() == made and made > 0 and yields.min() >= lo and yields.max() <= hi,
		"the yield is re-rolled inside the tier's band %d-%d (%s)" % [lo, hi, yields]
	)
	_free_fx()


## --- INVARIANT: mining rates, mass, layer, section 13's collision rows ------------


func _invariants() -> void:
	var rock := _member(AsteroidScript.SIZE_MEDIUM, 4, Vector2(42.0, 42.0))
	var body := rock as RigidBody2D
	rock.call(&"apply_collision_damage", 5.0)
	var chip_half := float(rock.get(&"work"))
	var units_half := int(rock.get(&"yield_units"))
	rock.call(&"apply_collision_damage", 5.0)
	var chip_full := float(rock.get(&"work"))
	var units := units_half - int(rock.get(&"yield_units"))
	print("%s INVARIANT work_per_unit=%.4f epsilon=%.6f mine_cycle=%.4f range=%.4f chip_rate=%.4f"
		% [
			TAG,
			AsteroidScript.WORK_PER_UNIT,
			AsteroidScript.WORK_EPSILON,
			LaserScript.MINE_CYCLE,
			LaserScript.MINE_LASER_RANGE,
			WeaponsScript.GUN_CHIP_RATE,
		])
	print("%s INVARIANT mass=%.4f ref=%s damp=%.4f damp_mode=%d gravity=%.2f sleep=%s layer=%d mask=%d group=%s chip(5.0)->work %.4f units=%d chip(5.0 more)->work %.4f units=%d"
		% [
			TAG,
			body.mass,
			AsteroidScript.ROCK_MASS_REFERENCE,
			body.linear_damp,
			body.linear_damp_mode,
			body.gravity_scale,
			body.can_sleep,
			body.collision_layer,
			body.collision_mask,
			AsteroidScript.ROCK_GROUP,
			chip_half,
			units_half,
			chip_full,
			units,
		])
	print("%s INVARIANT collision_factor=%s min_dv=%.2f knockback=%.4f p0=%.2f window=%.4f min_shockwave=%.4f max_bodies=%d"
		% [
			TAG,
			ImpactScript.COLLISION_FACTOR,
			ImpactScript.COLLISION_MIN_DV,
			ImpactScript.KNOCKBACK_FRACTION,
			ImpactScript.EXPLOSION_P0,
			ImpactScript.EXPLOSION_WINDOW,
			ProjectileScript.MIN_SHOCKWAVE_IMPULSE,
			ProjectileScript.MAX_SHOCKWAVE_BODIES,
		])
	_check(
		"invariant_mining_rates",
		is_equal_approx(AsteroidScript.WORK_PER_UNIT, 1.0)
			and is_equal_approx(AsteroidScript.WORK_EPSILON, 0.0001)
			and is_equal_approx(LaserScript.MINE_CYCLE, 1.2)
			and is_equal_approx(LaserScript.MINE_LASER_RANGE, 220.0)
			and is_equal_approx(WeaponsScript.GUN_CHIP_RATE, 0.10),
		"WORK_PER_UNIT 1.0, epsilon 1e-4, MINE_CYCLE 1.2 s, range 220 u, gun chip 10 percent"
	)
	_check(
		"invariant_body",
		is_equal_approx(body.mass, 560.0)
			and is_equal_approx(body.linear_damp, 3.71)
			and body.linear_damp_mode == RigidBody2D.DAMP_MODE_REPLACE
			and is_equal_approx(body.gravity_scale, 0.0)
			and body.can_sleep == false
			and body.collision_layer == 1
			and body.collision_mask == 2,
		"ruling 8 intact: mass 4 x ship_miner, damp 3.71 REPLACE, no gravity, layer 1 / mask 2"
	)
	_check(
		"invariant_gun_chip",
		is_equal_approx(chip_half, 0.5) and units_half == 4 and is_equal_approx(chip_full, 0.0)
			and units == 1,
		"5.0 of gun work lands as 0.5 rock work (the 10 percent chip); a second 5.0 completes the 1.0 unit"
	)
	_check(
		"invariant_collision_rows",
		is_equal_approx(ImpactScript.COLLISION_FACTOR, 2.0e-5)
			and is_equal_approx(ImpactScript.COLLISION_MIN_DV, 40.0)
			and is_equal_approx(ImpactScript.KNOCKBACK_FRACTION, 0.40)
			and is_equal_approx(ImpactScript.EXPLOSION_P0, 4000.0)
			and is_equal_approx(ImpactScript.EXPLOSION_WINDOW, 0.2)
			and is_equal_approx(ProjectileScript.MIN_SHOCKWAVE_IMPULSE, 1.0)
			and ProjectileScript.MAX_SHOCKWAVE_BODIES == 32,
		"section 13 collision/recoil/explosion rows unchanged (P0 4000, window 0.2, floor 1.0)"
	)
	rock.free()


## --- RESPAWN: 02 section 8's bookkeeping ----------------------------------------


func _respawn_bookkeeping() -> void:
	var field := FieldScript.new() as Node2D
	field.name = &"A2RespawnField"
	add_child(field)
	## A rock's *look* (and so whether a respawned rock cleaves at all) rolls on the
	## global RNG, not the field's seeded one, so pin it here: otherwise the number of
	## cleaves varies run to run and the shared `rng` stream drifts with it.
	seed(LOOK_SEED)
	field.call(&"setup", {&"tier_weights": TIER_WEIGHTS, &"rocks": 6, &"seed": FIELD_SEED + 1})
	var virgin_depleted := bool(field.call(&"is_depleted"))
	var virgin_window := bool(field.call(&"diminishing_active"))
	field.call(&"_clear_rocks")
	for index in 6:
		field.call(&"_new_rock", "Bare%d" % index, UNIT_MINERAL, UNIT_TIER, 0, AsteroidScript.SIZE_SMALL)
	var live_before := int(field.call(&"rock_count"))
	var respawn_too_early := bool(field.call(&"respawn", 1000))
	for rock: Node2D in (field.call(&"rocks") as Array[Node2D]).duplicate():
		_deplete(rock)
	var depleted := bool(field.call(&"is_depleted"))
	var stamp := int(field.get(&"last_depleted_time"))
	var respawned := bool(field.call(&"respawn", 1000))
	var new_count := int(field.call(&"rock_count"))
	var respawn_stamp := int(field.get(&"last_respawn_time"))
	var inside := bool(field.call(&"diminishing_active", 1000 + 299))
	var outside := bool(field.call(&"diminishing_active", 1000 + 300))
	var fake_now_yields: Array[int] = []
	for rock: Node2D in field.call(&"rocks") as Array[Node2D]:
		fake_now_yields.append(int(rock.get(&"yield_units")))
	# Second pass on the real clock: the x0.7 window is evaluated against
	# `Clock.now()` (not the `now` argument), so a respawn with no argument is the
	# production path and is the one that must show the diminished band.
	for rock: Node2D in (field.call(&"rocks") as Array[Node2D]).duplicate():
		var before := _live_ids(field)
		_deplete(rock)
		_free_rocks(_fragments_since(before, field))
	var respawned_now := bool(field.call(&"respawn"))
	var real_stamp := int(field.get(&"last_respawn_time"))
	var now_yields: Array[int] = []
	for rock: Node2D in field.call(&"rocks") as Array[Node2D]:
		now_yields.append(int(rock.get(&"yield_units")))
	print("%s RESPAWN virgin_depleted=%s virgin_window=%s live=%d respawn_before_depleted=%s depleted=%s stamped=%s respawned=%s count=%d respawn_stamp=%d window@299=%s window@300=%s fake_now_yields=%s"
		% [
			TAG,
			virgin_depleted,
			virgin_window,
			live_before,
			respawn_too_early,
			depleted,
			stamp > 0,
			respawned,
			new_count,
			respawn_stamp,
			inside,
			outside,
			fake_now_yields,
		])
	print("%s RESPAWN realnow respawned=%s stamp_positive=%s age=%d yields=%s"
		% [TAG, respawned_now, real_stamp > 0, Clock.now() - real_stamp, now_yields])
	print("%s RESPAWN constants window=%d mult=%.2f rocks_band=%d-%d"
		% [
			TAG,
			FieldScript.DIMINISHING_WINDOW_SECONDS,
			FieldScript.DIMINISHING_YIELD_MULT,
			FieldScript.FIELD_ROCKS_MIN,
			FieldScript.FIELD_ROCKS_MAX,
		])
	_check(
		"respawn_window_constants",
		FieldScript.DIMINISHING_WINDOW_SECONDS == 300
			and is_equal_approx(FieldScript.DIMINISHING_YIELD_MULT, 0.7)
			and FieldScript.FIELD_ROCKS_MIN == 6
			and FieldScript.FIELD_ROCKS_MAX == 12,
		"02 section 8: 300 s window, x0.7, 6-12 rocks per field"
	)
	_check(
		"respawn_guard_and_stamp",
		virgin_depleted == false
			and virgin_window == false
			and live_before == 6
			and respawn_too_early == false
			and depleted == true
			and stamp > 0
			and respawned == true
			and new_count == 6
			and respawn_stamp == 1000
			and respawned_now == true
			and real_stamp > 1000,
		"no respawn while rocks live; a full depletion stamps last_depleted_time; respawn re-rolls 6"
	)
	_check(
		"respawn_diminishing_window",
		inside == true and outside == false,
		"the x0.7 window is open at +299 s and closed at +300 s"
	)
	_check(
		"respawn_diminished_yields",
		now_yields.size() == 6 and now_yields.max() <= 6,
		"a field respawned inside the window rolls T1 yields <= 6 (the unmodified band tops at 9): %s"
			% [now_yields]
	)
	field.free()


## --- BLAST: the shockwave the break owes its neighbours --------------------------
##
## The brief's change 3 says "reuses the existing shockwave helper on nearby bodies;
## no new constant" - so the push must be visible inside the curve's own reach and
## absent past it. `I(d) = P0 / (1 + d^2) >= MIN_SHOCKWAVE_IMPULSE` holds to
## d = sqrt(4000 / 1 - 1) = 63.24 u; 20 u is inside it and 200 u is far outside.
func _blast() -> void:
	var floor_distance := sqrt(maxf(ImpactScript.EXPLOSION_P0 / ProjectileScript.MIN_SHOCKWAVE_IMPULSE - 1.0, 0.0))
	var centre := Vector2(3000.0, 0.0)
	var dying := _member(AsteroidScript.SIZE_LARGE, 4, centre)
	var near := _member(AsteroidScript.SIZE_MEDIUM, 4, centre + Vector2(BLAST_NEAR, 0.0)) as RigidBody2D
	var far := _member(AsteroidScript.SIZE_MEDIUM, 4, centre + Vector2(BLAST_FAR, 0.0)) as RigidBody2D
	var near_before := near.linear_velocity
	var far_before := far.linear_velocity
	_deplete(dying)
	for _frame in BLAST_FRAMES:
		await get_tree().physics_frame
	var near_after := near.linear_velocity
	var far_after := far.linear_velocity
	print("%s BLAST reach=%.4f near_offset=%.1f near %.6f -> %.6f (dx=%.6f) far_offset=%.1f far %.6f -> %.6f impulse(near)=%.4f impulse(far)=%.4f"
		% [
			TAG,
			floor_distance,
			BLAST_NEAR,
			near_before.length(),
			near_after.length(),
			near_after.x - near_before.x,
			BLAST_FAR,
			far_before.length(),
			far_after.length(),
			ImpactScript.explosion_impulse(BLAST_NEAR),
			ImpactScript.explosion_impulse(BLAST_FAR),
		])
	_check(
		"blast_reach_is_the_curve",
		is_equal_approx(floor_distance, sqrt(3999.0)) and floor_distance > BLAST_NEAR and floor_distance < BLAST_FAR,
		"the push's own reach is sqrt(P0 / MIN - 1) = %.4f u - no radius constant exists" % floor_distance
	)
	_check(
		"blast_pushes_inside_reach",
		near_after.x > near_before.x and near_after.length() > 0.0,
		"a rock %.0f u away gains outward velocity from the break" % BLAST_NEAR
	)
	_check(
		"blast_spares_past_reach",
		far_after.is_zero_approx() and ImpactScript.explosion_impulse(BLAST_FAR) < ProjectileScript.MIN_SHOCKWAVE_IMPULSE,
		"a rock %.0f u away is not moved (impulse %.4f below the %.1f floor)"
			% [BLAST_FAR, ImpactScript.explosion_impulse(BLAST_FAR), ProjectileScript.MIN_SHOCKWAVE_IMPULSE]
	)
	_free_fx()


func _teardown() -> void:
	_free_pickups()
	_free_fx()
	if _field != null and is_instance_valid(_field):
		_field.free()
	_field = null
