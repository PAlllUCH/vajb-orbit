extends Node2D
## Rock cleave probe (wave `rock_cleave`, A1, 2026-09-21).
##
## It measures the owner's asteroid ruling on the shipped code - "asteroids breaking
## effects (they should somehow explode, random fragments from 2 to 5 moving in random
## directions)" - with one seeded field, so every number below is reproducible:
##
##   SPLIT  - the two cleaving rows and the ejection constants as the code carries them;
##   COUNT  - the fragment count of N Large and N Medium cleaves: every roll printed, the
##            bounds read off the list (2-5 on both tiers), the distinct values seen (so a
##            constant that quietly narrowed back to one number shows up) and the tier each
##            fragment landed in;
##   DIR    - every fragment's ejection heading as a deviation from the parent's own
##            velocity, plus each cleave's widest pair: the proof that the retired +-15 deg
##            cone is gone is a deviation past 90 deg (a cone cannot produce one) and two
##            fragments of one cleave more than 90 deg apart;
##   SPEED  - |eject| / |parent velocity| per fragment, against section 13's 1.2;
##   FX     - the row the break drew, where the sprite landed (the rock's centre) and the
##            world size it was scaled to (`1.2 x the rock's collision diameter`, clamped
##            96-224) for a Large, and the floor's own case for a Small;
##   CUE    - the cue the break played (`AudioManager.last_sfx()`) and the four-take pool
##            row it resolved through, played repeatedly so the round-robin is visible;
##   BARE   - a yield-0 rock: it cracks, spawns no fragment, still draws the explosion and
##            still plays the cue (the break is the rock's death, not an ore event);
##   BURST  - a Small's 1-2 pickups, counted by script path, with the pickup leaf's own
##            compile state beside it;
##   BLAST  - one neighbour rock inside the impulse curve's own floor, its velocity before
##            and after the break (Impact.apply_shockwave, no new constant).
##
## Run:  godot --headless --path vajb-orbit res://tests/probe_rock_cleave.tscn --quit-after 900
## Signal: the `[RC]` lines; the last is `[RC] done`.

const FieldScript := preload("res://game/asteroid_field.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const AudioScript := preload("res://autoload/audio_manager.gd")
const ImpactScript := preload("res://game/impact.gd")
const FxScript := preload("res://game/fx.gd")

const TAG := "[RC]"
const AUDIO_SERVICE: StringName = &"AudioManager"
const PICKUP_SCRIPT := "res://game/pickup.gd"
const EXPLOSION_NAME := "explosion"
const TIER_WEIGHTS: Dictionary = {1: 100}
const FIELD_SEED := 20260921
const FIELD_ROCKS := 6
const UNIT_TIER := 1
const PARENT_SPEED := 120.0
const PARENT_HEADING := 0.7
const N_CLEAVES := 8
const N_SMALLS := 6
const CUE_LINE = &"sfx_impact_rock"
const BLAST_NEIGHBOUR_OFFSET := 20.0
const BLAST_FRAMES := 20

var _field: Node2D = null
var _audio: Node = null
var _rock_index := 0
var _failures: Array[String] = []
var _fx_source := Vector2.ZERO


func _ready() -> void:
	_audio = get_tree().root.get_node_or_null(NodePath(AUDIO_SERVICE))
	_field = FieldScript.new() as Node2D
	_field.name = &"RockCleaveField"
	add_child(_field)
	_field.call(&"setup", {
		&"tier_weights": TIER_WEIGHTS,
		&"rocks": FIELD_ROCKS,
		&"seed": FIELD_SEED,
	})
	var leaf := load(PICKUP_SCRIPT) as GDScript
	print("%s boot audio=%s pickup_leaf=%s rocks=%d"
		% [
			TAG,
			_audio != null,
			leaf != null and leaf.can_instantiate(),
			int(_field.call(&"rock_count")),
		])
	_constants()
	_counts(AsteroidScript.SIZE_LARGE)
	_counts(AsteroidScript.SIZE_MEDIUM)
	_directions_and_speed()
	_fx_and_cue()
	_yield_zero()
	_pickup_burst()
	await _blast()
	_teardown()
	print("%s done failures=%d" % [TAG, _failures.size()])
	get_tree().quit(1 if _failures.size() > 0 else 0)


## --- Setup helpers ----------------------------------------------------------


## A field member of a chosen size class and unit count: the suite's own door
## (`_new_rock`), because a field's roll is uniform over the nine looks.
func _member(size_class: int, units: int, at: Vector2 = Vector2.ZERO) -> Node2D:
	_rock_index += 1
	var rock: Node2D = _field.call(
		&"_new_rock", "Probe%d" % _rock_index, &"iron", UNIT_TIER, units, size_class
	)
	rock.position = at
	return rock


## Deplete through the rock's own arithmetic, with `WORK_PER_UNIT` as the floor so a
## 0-unit rock is handed the positive work that cracks it.
func _deplete(rock: Node2D) -> void:
	rock.call(
		&"apply_work",
		maxf(float(int(rock.get(&"yield_units"))), AsteroidScript.WORK_PER_UNIT)
	)


func _live_ids() -> Array[int]:
	var out: Array[int] = []
	for rock: Node2D in _field.call(&"rocks") as Array[Node2D]:
		out.append(rock.get_instance_id())
	return out


func _fragments_since(before: Array[int]) -> Array[Node2D]:
	var out: Array[Node2D] = []
	for rock: Node2D in _field.call(&"rocks") as Array[Node2D]:
		if not before.has(rock.get_instance_id()):
			out.append(rock)
	return out


func _scene() -> Node:
	var scene := get_tree().current_scene
	return scene if scene != null else self


## Every explosion sprite under the scene, matched by class plus the name prefix: a
## second sibling handed the same name is renamed by the engine (its unique-name
## suffix), so an exact-name match would only ever find one of them.
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


func _cue() -> String:
	return String(_audio.call(&"last_sfx")) if _audio != null else ""


func _check(label: String, ok: bool, note: String) -> void:
	if not ok:
		_failures.append(label)
	print("%s %s %s - %s" % [TAG, "ok  " if ok else "FAIL", label, note])


## --- SPLIT: the constants as shipped ---------------------------------------


func _constants() -> void:
	print("%s SPLIT L=%s M=%s S=%s pickup=%s eject_mult=%.2f cone=%.1f"
		% [
			TAG,
			AsteroidScript.FRAGMENT_SPLIT[AsteroidScript.SIZE_LARGE],
			AsteroidScript.FRAGMENT_SPLIT[AsteroidScript.SIZE_MEDIUM],
			AsteroidScript.FRAGMENT_SPLIT[AsteroidScript.SIZE_SMALL],
			AsteroidScript.PICKUP_BURST,
			AsteroidScript.FRAGMENT_EJECT_MULT,
			AsteroidScript.FRAGMENT_EJECT_CONE_DEG,
		])
	_check(
		"split_rows",
		AsteroidScript.FRAGMENT_SPLIT[AsteroidScript.SIZE_LARGE] == Vector2i(2, 5)
			and AsteroidScript.FRAGMENT_SPLIT[AsteroidScript.SIZE_MEDIUM] == Vector2i(2, 5)
			and AsteroidScript.FRAGMENT_SPLIT[AsteroidScript.SIZE_SMALL] == Vector2i(0, 0),
		"both cleaving tiers 2-5, a Small still fragments into nothing"
	)
	_check(
		"eject_constants",
		is_equal_approx(AsteroidScript.FRAGMENT_EJECT_MULT, 1.2)
			and is_equal_approx(AsteroidScript.FRAGMENT_EJECT_CONE_DEG, 360.0),
		"x1.2 speed, full-circle direction"
	)


## --- COUNT: the rolls, both tiers ------------------------------------------


func _counts(size_class: int) -> void:
	var label := "Large" if size_class == AsteroidScript.SIZE_LARGE else "Medium"
	var counts: Array[int] = []
	var sizes: Dictionary = {}
	for index in N_CLEAVES:
		var parent := _member(size_class, 4, Vector2(400.0 + float(index) * 8.0, 0.0))
		var before := _live_ids()
		_deplete(parent)
		var fragments := _fragments_since(before)
		counts.append(fragments.size())
		for fragment: Node2D in fragments:
			sizes[int(fragment.call(&"size_class"))] = true
	var lowest: int = counts.min()
	var highest: int = counts.max()
	print("%s COUNT %s rolls=%s min=%d max=%d tiers_landed_in=%d landed=%s"
		% [TAG, label, counts, lowest, highest, sizes.size(), sizes.keys()])
	_check(
		"count_%s_bounds" % label,
		lowest >= 2 and highest <= 5,
		"every %s cleave rolled inside 2-5" % label
	)
	_check(
		"count_%s_variety" % label,
		lowest < highest,
		"the count varies roll to roll (seen %d..%d over %d cleaves)" % [lowest, highest, N_CLEAVES]
	)
	_check(
		"count_%s_size" % label,
		sizes.size() == 1 and sizes.has(size_class - 1),
		"a %s's fragments are one tier down" % label
	)


## --- DIR + SPEED: the full circle, and the 1.2 ------------------------------
##
## Since CONTRACTS 14 the deployed velocity is section 5's shape **plus** the field's
## `FRAGMENT_OUTWARD_KICK` along the fragment's placement radial, so the SPEED row reads the
## shape back out of it (the raw ratio is printed beside it); the DIR rows stay on the
## deployed vector, which is what a player sees.


func _directions_and_speed() -> void:
	var deviations: Array[float] = []
	var speeds: Array[float] = []
	var shapes: Array[float] = []
	var widest := 0.0
	var widest_cleave := -1
	var first_pair := ""
	for index in N_CLEAVES:
		var parent := _member(AsteroidScript.SIZE_LARGE, 4, Vector2(600.0, float(index) * 8.0))
		var origin: Vector2 = (parent as Node2D).global_position
		var heading := Vector2(PARENT_SPEED, 0.0).rotated(PARENT_HEADING)
		(parent as RigidBody2D).linear_velocity = heading
		var before := _live_ids()
		_deplete(parent)
		var fragments := _fragments_since(before)
		var headings: Array[float] = []
		for fragment: Node2D in fragments:
			var ejected: Vector2 = (fragment as RigidBody2D).linear_velocity
			deviations.append(rad_to_deg(heading.angle_to(ejected)))
			headings.append(rad_to_deg(ejected.angle()))
			speeds.append(ejected.length() / heading.length())
			shapes.append(_shape_half(fragment, origin).length() / heading.length())
		var local := 0.0
		for a: float in headings:
			for b: float in headings:
				local = maxf(local, absf(wrapf(a - b, -180.0, 180.0)))
		if local > widest:
			widest = local
			widest_cleave = index
			first_pair = "cleave %d: %s" % [index, headings]
	print("%s DIR deviations_deg=%s" % [TAG, _round_all(deviations)])
	print("%s DIR widest_pair=%.3f deg (%s) past_15=%d of %d past_90=%d"
		% [
			TAG,
			widest,
			first_pair,
			_count_beyond(deviations, 15.0),
			deviations.size(),
			_count_beyond(deviations, 90.0),
		])
	print("%s SPEED ratio_min=%.4f ratio_max=%.4f fragments=%d"
		% [TAG, speeds.min(), speeds.max(), speeds.size()])
	print("%s SPEED shape_ratio_min=%.9f shape_ratio_max=%.9f (the kick taken back out)"
		% [TAG, shapes.min(), shapes.max()])
	_check(
		"direction_full_circle",
		deviations.max() > 90.0,
		"a fragment lands more than 90 deg off the parent's heading: the +-15 deg cone cannot produce one"
	)
	_check(
		"direction_pair_spread",
		widest > 90.0,
		"two fragments of one cleave landed %.1f deg apart (cleave %d)" % [widest, widest_cleave]
	)
	_check(
		"eject_speed",
		is_equal_approx(shapes.min(), 1.2) and is_equal_approx(shapes.max(), 1.2),
		"every fragment still inherits the parent's velocity x 1.2 (the shape; the deployed"
		+ " ratio above also carries the 150 u/s radial kick)"
	)


## Section 5's shape recovered from a fragment: the field's kick rides the fragment's own
## placement radial, and taking that vector out leaves the rolled inherit itself.
func _shape_half(fragment: Node2D, origin: Vector2) -> Vector2:
	var radial := (fragment.global_position - origin).normalized()
	return (fragment as RigidBody2D).linear_velocity - radial * FieldScript.FRAGMENT_OUTWARD_KICK


func _count_beyond(values: Array[float], limit: float) -> int:
	var count := 0
	for value: float in values:
		if absf(value) > limit:
			count += 1
	return count


func _round_all(values: Array[float]) -> Array[float]:
	var out: Array[float] = []
	for value: float in values:
		out.append(snappedf(value, 0.001))
	return out


## The names of the live explosion sprites, so the engine's own renaming is visible in
## the evidence rather than inferred.
func _explosion_names() -> Array[String]:
	var out: Array[String] = []
	for node: Node in _explosions():
		out.append(String(node.name))
	return out


## --- FX + CUE: the break's read ---------------------------------------------


func _fx_and_cue() -> void:
	var row: Dictionary = ProjectileScript.feedback_row(&"explosion")
	_fx_source = row.get(&"source", Vector2.ZERO)
	var centre := Vector2(240.0, -80.0)
	var parent := _member(AsteroidScript.SIZE_LARGE, 4, centre)
	var diameter := 2.0 * float(parent.call(&"world_radius"))
	var before := _explosions().size()
	var cue_before := _cue()
	_deplete(parent)
	var spawned := _explosions()
	var sprite := spawned[spawned.size() - 1] as AnimatedSprite2D if spawned.size() > before else null
	var expected := clampf(diameter * 1.2, 96.0, 224.0)
	print("%s FX large radius=%.4f diameter=%.4f expected_world=%.4f sprite=%s at=%s scale=%.6f row=(world %s, source %s), sprite_frames=%d alive_names=%s"
		% [
			TAG,
			diameter * 0.5,
			diameter,
			expected,
			sprite != null,
			str(sprite.position) if sprite != null else "-",
			sprite.scale.x if sprite != null else -1.0,
			row.get(&"world", 0.0),
			_fx_source,
			sprite.sprite_frames.get_frame_count(FxScript.ANIMATION) if sprite != null else -1,
			_explosion_names(),
		])
	_check("fx_spawn", spawned.size() == before + 1,
		"one explosion sprite per break (%d -> %d)" % [before, spawned.size()])
	_check("fx_centre", sprite != null and sprite.position.distance_to(centre) < 0.001,
		"the sequence sits on the rock's centre %s" % centre)
	_check(
		"fx_scale",
		sprite != null and is_equal_approx(sprite.scale.x, expected / maxf(_fx_source.x, _fx_source.y)),
		"scaled to %.2f world units (row source %s)" % [expected, _fx_source]
	)
	var takes: Array = AudioScript.CUE_POOLS[CUE_LINE][&"takes"]
	var cue := _cue()
	print("%s CUE played=%s (before %s) pool_takes=%s mode=%s in_pool=%s row_pitch=%s volume=%s"
		% [
			TAG,
			cue,
			cue_before,
			takes,
			AudioScript.CUE_POOLS[CUE_LINE][&"mode"],
			takes.has(StringName(cue)),
			AudioScript.CUE_POOLS[CUE_LINE][&"pitch"],
			AudioScript.CUE_POOLS[CUE_LINE][&"volume_db"],
		])
	_check(
		"cue_pool_row",
		takes.size() == 4
			and StringName(AudioScript.CUE_POOLS[CUE_LINE][&"mode"]) == &"round_robin",
		"L53's four takes are a round-robin row"
	)
	_check("cue_plays", takes.has(StringName(cue)), "the break played a take from that row")
	var rotated: Array[String] = [cue]
	if _audio != null:
		for _index in 4:
			_audio.call(&"play_pool", CUE_LINE)
			rotated.append(_cue())
	print("%s CUE round_robin=%s" % [TAG, rotated])
	_check(
		"cue_rotates",
		rotated[0] != rotated[1] and rotated[1] != rotated[2] and rotated[3] != rotated[4],
		"consecutive reads of the row do not repeat the previous take"
	)
	_small_scale()


## The floor's own case: a Small's 1.2 x read is under the row's 96 u, so its break
## takes the clamp rather than drawing a spark.
func _small_scale() -> void:
	var centre := Vector2(-180.0, 120.0)
	var parent := _member(AsteroidScript.SIZE_SMALL, 4, centre)
	var diameter := 2.0 * float(parent.call(&"world_radius"))
	var before := _explosions().size()
	_deplete(parent)
	var spawned := _explosions()
	var sprite := spawned[spawned.size() - 1] as AnimatedSprite2D if spawned.size() > before else null
	var expected := clampf(diameter * 1.2, 96.0, 224.0)
	print("%s FX small diameter=%.4f raw_1.2x=%.4f expected_world=%.4f scale=%.6f"
		% [TAG, diameter, diameter * 1.2, expected, sprite.scale.x if sprite != null else -1.0])
	_check(
		"fx_scale_floor",
		sprite != null and diameter * 1.2 < 96.0
			and is_equal_approx(sprite.scale.x, 96.0 / maxf(_fx_source.x, _fx_source.y)),
		"a Small's break takes the row's own 96 u floor (its raw 1.2x read is %.2f u)" % (diameter * 1.2)
	)


## --- BARE: a yield-0 rock ---------------------------------------------------


func _yield_zero() -> void:
	var bare := _member(AsteroidScript.SIZE_LARGE, 0, Vector2(-320.0, -60.0))
	var before := _live_ids()
	var fx_before := _explosions().size()
	var cue_before := _cue()
	_deplete(bare)
	var fragments := _fragments_since(before)
	print("%s BARE cleaves=%s fragments=%d fx=%d->%d cue=%s (was %s) live=%d->%d"
		% [
			TAG,
			bare.call(&"cleaves"),
			fragments.size(),
			fx_before,
			_explosions().size(),
			_cue(),
			cue_before,
			before.size(),
			_live_ids().size(),
		])
	_check("bare_no_fragments", fragments.size() == 0, "a yield-0 rock cleaves into nothing")
	_check(
		"bare_break_read",
		_explosions().size() == fx_before + 1 and _cue() != cue_before,
		"but it still explodes and still plays the break cue"
	)


## --- BURST: a Small's pickups ------------------------------------------------


func _pickup_burst() -> void:
	var counts: Array[int] = []
	for index in N_SMALLS:
		var small := _member(
			AsteroidScript.SIZE_SMALL, 4, Vector2(-500.0 + float(index) * 10.0, 240.0)
		)
		var before := _pickups().size()
		_deplete(small)
		counts.append(_pickups().size() - before)
	print("%s BURST pickups_per_small=%s" % [TAG, counts])
	_check(
		"pickup_burst",
		counts.min() >= 1 and counts.max() <= 2,
		"a Small bursts 1-2 pickups of its mineral"
	)


## The probe's own fixtures go before the quit, so a clean run ends without the engine's
## leak report (the field takes its fragments and pickups with it).
func _teardown() -> void:
	for pickup: Node in _pickups():
		if is_instance_valid(pickup):
			pickup.free()
	for sprite: Node in _explosions():
		if is_instance_valid(sprite):
			sprite.free()
	if _field != null and is_instance_valid(_field):
		_field.free()
	_field = null


## --- BLAST: the shockwave the break owes its neighbour ------------------------


func _blast() -> void:
	var centre := Vector2(900.0, 0.0)
	var dying := _member(AsteroidScript.SIZE_LARGE, 4, centre)
	var neighbour := _member(
		AsteroidScript.SIZE_MEDIUM, 4, centre + Vector2(BLAST_NEIGHBOUR_OFFSET, 0.0)
	)
	var body := neighbour as RigidBody2D
	var before := body.linear_velocity
	_deplete(dying)
	for _frame in BLAST_FRAMES:
		await get_tree().physics_frame
	var after := body.linear_velocity
	print("%s BLAST offset=%.1f curve=%.4f window=%s velocity %.6f -> %.6f dv_x=%.6f"
		% [
			TAG,
			BLAST_NEIGHBOUR_OFFSET,
			ImpactScript.explosion_impulse(BLAST_NEIGHBOUR_OFFSET),
			ImpactScript.EXPLOSION_WINDOW,
			before.length(),
			after.length(),
			after.x - before.x,
		])
	_check(
		"blast_shoves_neighbour",
		after.x > before.x and after.x > 0.0,
		"the neighbour %.0f u away was pushed outward by the break" % BLAST_NEIGHBOUR_OFFSET
	)
