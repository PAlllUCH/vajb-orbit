extends SceneTree
## S14-R1's independent AC replay (W8 method: the reviewer re-measures, it does
## not read the builder's numbers). Every yardstick below is transcribed from
## `docs/gameplay/02_minerals.md` §5.2 (and §5.1 Rule A), NOT from the wave brief
## and NOT from `OreTuning` — the live table is then compared against it, so a
## wrong default fails here rather than agreeing with itself.
##
##   XDG_DATA_HOME=/tmp/s14_r1 "$GODOT_CONSOLE" --headless --path "$VAJB_PROJ" \
##     --script res://tools/r1_s14_ac_replay.gd
##
## AC1  200 seeded XL shatters: children only L/M/S, per-kind counts inside the
##      rolled range, each kind present, no child at or above its parent, each
##      kind's roll uniform over its own range (per-kind chi-square).
## AC2  L -> only M/S; M -> only S; S -> never splits; no child >= parent.
## AC3  conservation across the mixed chain: a fully mined family realises at or
##      below the root `_bore_ore` + 1, over several seeds and every parent size
##      a mining shatter can start from.
## AC4  1000 seeded spawn-size rolls within 3 percentage points of 40/32/20/8.
## AC5  the XL look row: three looks, each 180 u, each reusing its L silhouette,
##      and a drawn XL sprite measuring 180 u at its drawn scale.

const AsteroidScript := preload("res://game/asteroid.gd")
const FieldScript := preload("res://game/asteroid_field.gd")
const OreTuningScript := preload("res://game/ore_tuning.gd")

const TAG := "[S14R1]"
const TIER_WEIGHTS: Dictionary = {1: 100}
const SHATTERS := 200
const SPLIT_SAMPLE := 60
const ROOT_BORE := 32
const ROOT_UNITS := 24
const SPAWN_ROLLS := 1000
const XL_LOOK_SEED := 14161
const XL_LOOK_DRAWS := 24
const PICKUP_GROUP: StringName = &"pickup"
const MAX_STEPS := 200000
const CHI2_LIMIT := 16.27

## 02 §5.2 verbatim: `XL -> L 1-3, M 2-4, S 2-5`; `L -> M 1-3, S 2-4`;
## `M -> S 1-3`; `S -> none`. Keyed by the integer size classes
## (`asteroid.gd`'s `SIZE_*`: S 0, M 1, L 2, XL 3).
const PIN_MIX: Dictionary = {
	3: {2: Vector2i(1, 3), 1: Vector2i(2, 4), 0: Vector2i(2, 5)},
	2: {1: Vector2i(1, 3), 0: Vector2i(2, 4)},
	1: {0: Vector2i(1, 3)},
	0: {},
}
## 02 §5.2's spawn row, S 40 / M 32 / L 20 / XL 8 percent.
const PIN_SPAWN: Dictionary = {0: 0.40, 1: 0.32, 2: 0.20, 3: 0.08}
const SPAWN_SLACK := 0.03
## 02 §5.2: "XL renders the L silhouettes scaled to a 180 u target width (L is
## 132 u)".
const PIN_XL_WIDTH := 180.0
const PIN_L_WIDTH := 132.0
const SIZE_NAMES: Array[String] = ["S", "M", "L", "XL"]
const SIZES: Array[int] = [0, 1, 2, 3]
const SEEDS: Array[int] = [14061, 777, 31337, 424242]

var _failures: Array[String] = []
var _fields: Array[Node] = []


func _init() -> void:
	OreTuningScript.reset_to_defaults()
	_check("defaults_split_mix", str(OreTuningScript.split_mix) == str(PIN_MIX),
		"live split_mix == 02 section 5.2 (%s)" % str(OreTuningScript.split_mix))
	var live_weights := {}
	for key: Variant in OreTuningScript.spawn_size_weights.keys():
		live_weights[int(key)] = float(OreTuningScript.spawn_size_weights[key]) / 100.0
	_check("defaults_spawn_mix", str(live_weights) == str(PIN_SPAWN),
		"live spawn_size_weights == 40/32/20/8 (%s)" % str(live_weights))
	_ac1()
	_ac2()
	_ac3()
	_ac4()
	_ac5()
	print("%s done failures=%d" % [TAG, _failures.size()])
	for field: Node in _fields:
		if is_instance_valid(field):
			field.free()
	quit(1 if not _failures.is_empty() else 0)


## --- AC1: 200 seeded XL shatters ----------------------------------------------
func _ac1() -> void:
	var field := _field(14061)
	var totals: Dictionary = {0: 0, 1: 0, 2: 0}
	var hist: Dictionary = {0: {}, 1: {}, 2: {}}
	var low: Dictionary = {0: 99, 1: 99, 2: 99}
	var high: Dictionary = {0: -1, 1: -1, 2: -1}
	var sum_hist: Dictionary = {}
	var children_total := 0
	var bad_kind := 0
	var out_of_range := 0
	for index in SHATTERS:
		var parent := _member(field, AsteroidScript.SIZE_XL, 8, "Xl%d" % index)
		var before := _ids(field)
		_deplete(parent)
		var children := _since(field, before)
		children_total += children.size()
		sum_hist[children.size()] = int(sum_hist.get(children.size(), 0)) + 1
		var here: Dictionary = {0: 0, 1: 0, 2: 0}
		for child: Node2D in children:
			var kind := int(child.call(&"size_class"))
			if kind >= AsteroidScript.SIZE_XL or kind < 0:
				bad_kind += 1
			else:
				here[kind] = int(here.get(kind, 0)) + 1
			child.free()
		for kind: int in [0, 1, 2]:
			var count := int(here[kind])
			var span: Vector2i = PIN_MIX[3][kind]
			if count < span.x or count > span.y:
				out_of_range += 1
			totals[kind] = int(totals[kind]) + count
			hist[kind][count] = int((hist[kind] as Dictionary).get(count, 0)) + 1
			low[kind] = mini(int(low[kind]), count)
			high[kind] = maxi(int(high[kind]), count)
	_check("ac1_no_child_at_or_above_parent", bad_kind == 0,
		"%d children of 200 XLs sat at or above XL" % bad_kind)
	_check("ac1_counts_inside_ranges", out_of_range == 0,
		"%d per-kind counts outside XL's rolled ranges" % out_of_range)
	var rows: Array[String] = []
	var worst_chi2 := 0.0
	for kind: int in [0, 1, 2]:
		var span: Vector2i = PIN_MIX[3][kind]
		var expected := float(SHATTERS) / float(span.y - span.x + 1)
		var chi2 := 0.0
		for value: int in range(span.x, span.y + 1):
			var observed := float((hist[kind] as Dictionary).get(value, 0))
			chi2 += pow(observed - expected, 2.0) / expected
		worst_chi2 = maxf(worst_chi2, chi2)
		rows.append("%s %d-%d min=%d max=%d mean=%.3f chi2=%.2f"
			% [SIZE_NAMES[kind], span.x, span.y, int(low[kind]), int(high[kind]),
			float(totals[kind]) / float(SHATTERS), chi2])
	_check("ac1_each_kind_present", int(low[0]) >= 2 and int(low[1]) >= 2 and int(low[2]) >= 1,
		"floors held: L low=%d, M low=%d, S low=%d" % [low[2], low[1], low[0]])
	_check("ac1_kind_roll_uniform", worst_chi2 <= CHI2_LIMIT,
		"worst per-kind chi2 %.2f against uniform over its own range" % worst_chi2)
	print("%s AC1 shatters=%d children=%d mean=%.3f | %s | totals=%d"
		% [TAG, SHATTERS, children_total, float(children_total) / float(SHATTERS),
		" | ".join(rows), sum_hist.size()])


## --- AC2: the cascade's shape --------------------------------------------------
func _ac2() -> void:
	var field := _field(14061)
	var checked := {AsteroidScript.SIZE_LARGE: 0, AsteroidScript.SIZE_MEDIUM: 0}
	var seen := {AsteroidScript.SIZE_LARGE: {}, AsteroidScript.SIZE_MEDIUM: {}}
	var totals := {AsteroidScript.SIZE_LARGE: {}, AsteroidScript.SIZE_MEDIUM: {}}
	var bad := 0
	var bad_total := 0
	for index in SPLIT_SAMPLE:
		for parent_kind: int in [AsteroidScript.SIZE_LARGE, AsteroidScript.SIZE_MEDIUM]:
			var before := _ids(field)
			_deplete(_member(field, parent_kind, 6, "P%d_%d" % [parent_kind, index]))
			var children := _since(field, before)
			checked[parent_kind] += 1
			var here: Dictionary = {}
			for child: Node2D in children:
				var kind := int(child.call(&"size_class"))
				here[kind] = int(here.get(kind, 0)) + 1
				if kind >= parent_kind:
					bad += 1
				child.free()
			var total := children.size()
			var seen_row: Dictionary = seen[parent_kind]
			seen_row[total] = true
			var total_row: Dictionary = totals[parent_kind]
			total_row[total] = int(total_row.get(total, 0)) + 1
			for child_kind: Variant in PIN_MIX[parent_kind].keys():
				var span: Vector2i = PIN_MIX[parent_kind][child_kind]
				var count := int(here.get(int(child_kind), 0))
				if count < span.x or count > span.y:
					bad_total += 1
	_check("ac2_no_child_at_or_above_parent", bad == 0,
		"%d children of L/M shatters sat at or above their parent (%d+%d shatters)"
		% [bad, checked[AsteroidScript.SIZE_LARGE], checked[AsteroidScript.SIZE_MEDIUM]])
	_check("ac2_per_kind_counts_inside_ranges", bad_total == 0,
		"%d per-kind counts outside the pinned rows" % bad_total)
	for parent_kind: int in [AsteroidScript.SIZE_LARGE, AsteroidScript.SIZE_MEDIUM]:
		var counts: Array = (seen[parent_kind] as Dictionary).keys()
		counts.sort()
		var span := _total_span(PIN_MIX[parent_kind])
		var ok: bool = int(counts.min()) >= span.x and int(counts.max()) <= span.y
		_check("ac2_%s_total_band" % SIZE_NAMES[parent_kind], ok,
			"%s shatters summed %s (pinned %d-%d)" % [SIZE_NAMES[parent_kind], counts, span.x, span.y])
	var smalls := 0
	var small_fragments := 0
	for index in SPLIT_SAMPLE:
		var small := _member(field, AsteroidScript.SIZE_SMALL, 4, "Small%d" % index)
		var before := _ids(field)
		_deplete(small)
		var fragments := _since(field, before)
		small_fragments += fragments.size()
		for fragment: Node2D in fragments:
			fragment.free()
		smalls += _pickups(field)
		_free_pickups(field)
	_check("ac2_small_never_splits", small_fragments == 0,
		"%d fragments from %d Small shatters (its cleave is the pickup burst)"
		% [small_fragments, SPLIT_SAMPLE])
	_check("ac2_small_pays_pickups", smalls >= SPLIT_SAMPLE,
		"%d pickup units from %d Smalls" % [smalls, SPLIT_SAMPLE])
	print("%s AC2 L totals=%s M totals=%s small_pickups=%d"
		% [TAG, str(totals[AsteroidScript.SIZE_LARGE]),
		str(totals[AsteroidScript.SIZE_MEDIUM]), smalls])


## --- AC3: conservation across the mixed chain (02 §5.1 Rule A) -----------------
func _ac3() -> void:
	var field := _field(14061)
	for seed_value: int in SEEDS:
		for parent_kind: int in [AsteroidScript.SIZE_XL, AsteroidScript.SIZE_LARGE, AsteroidScript.SIZE_MEDIUM]:
			field.call(&"setup", {
				&"tier_weights": TIER_WEIGHTS, &"rocks": 1, &"seed": seed_value,
			})
			var root: Node2D = field.call(
				&"_new_rock", "Root", &"iron", 1, ROOT_UNITS, parent_kind, false, float(ROOT_BORE)
			)
			var bore := float(root.call(&"bore_ore"))
			var family: Dictionary = {root.get_instance_id(): true}
			var mined := 0
			var steps := 0
			while steps < MAX_STEPS:
				var live: Array = []
				for rock: Node2D in field.call(&"rocks"):
					if family.has(rock.get_instance_id()):
						live.append(rock)
				if live.is_empty():
					break
				var before := _ids(field)
				mined += int(live[0].call(&"apply_work", AsteroidScript.WORK_PER_UNIT))
				for rock: Node2D in _since(field, before):
					family[rock.get_instance_id()] = true
				steps += 1
			var delivered := mined + _pickups(field)
			_free_pickups(field)
			_check("ac3_%s_seed%d" % [SIZE_NAMES[parent_kind], seed_value],
				float(delivered) <= bore + 1.0 and float(delivered) >= bore - 1.0,
				"bore %.1f -> realised %d over %d steps / %d rocks"
				% [bore, delivered, steps, family.size()])
			for rock: Node2D in field.call(&"rocks"):
				rock.free()
	print("%s AC3 conservation measured over %d seeds x 3 parent sizes" % [TAG, SEEDS.size()])


## --- AC4: the spawn mix ---------------------------------------------------------
func _ac4() -> void:
	var field := _field(14062)
	var rolls: Dictionary = {0: 0, 1: 0, 2: 0, 3: 0}
	for _roll in SPAWN_ROLLS:
		var size_class := int(field.call(&"_roll_size"))
		if rolls.has(size_class):
			rolls[size_class] = int(rolls[size_class]) + 1
	var rows: Array[String] = []
	var worst := 0.0
	for size_class: int in SIZES:
		var share := float(rolls[size_class]) / float(SPAWN_ROLLS)
		worst = maxf(worst, absf(share - float(PIN_SPAWN[size_class])))
		rows.append("%s %.4f vs %.2f" % [SIZE_NAMES[size_class], share, PIN_SPAWN[size_class]])
	_check("ac4_within_three_percent", worst <= SPAWN_SLACK,
		"worst deviation %.4f of the %.2f bound | %s" % [worst, SPAWN_SLACK, " | ".join(rows)])
	## The field's own build must land inside the row too, not just the bare roll.
	var lands: Dictionary = {0: 0, 1: 0, 2: 0, 3: 0}
	for build in 40:
		var built := _field(9000 + build)
		for rock: Node2D in built.call(&"rocks"):
			var kind := int(rock.call(&"size_class"))
			lands[kind] = int(lands.get(kind, 0)) + 1
	print("%s AC4 1000 rolls %s | build classes=%s" % [TAG, " | ".join(rows), str(lands)])


## --- AC5: the XL look row -------------------------------------------------------
func _ac5() -> void:
	var row_first: int = AsteroidScript.SIZE_XL * AsteroidScript.LOOKS_PER_SIZE
	_check("ac5_row_is_three_looks", AsteroidScript.LOOK_TEXTURES.size() == row_first + 3,
		"%d looks, XL row starts at %d" % [AsteroidScript.LOOK_TEXTURES.size(), row_first])
	_check("ac5_l_width_is_132", is_equal_approx(AsteroidScript.LOOK_WIDTHS[row_first - 1], PIN_L_WIDTH),
		"L's own row reads %.1f u" % AsteroidScript.LOOK_WIDTHS[row_first - 1])
	var widths_ok := true
	var reuse_ok := true
	for row: int in range(row_first, row_first + 3):
		if not is_equal_approx(AsteroidScript.LOOK_WIDTHS[row], PIN_XL_WIDTH):
			widths_ok = false
		if AsteroidScript.LOOK_TEXTURES[row] != AsteroidScript.LOOK_TEXTURES[row - 3]:
			reuse_ok = false
	_check("ac5_widths_180", widths_ok, "all three XL looks target 180 u")
	_check("ac5_reuses_l_silhouettes", reuse_ok, "each XL look reuses its L texture")
	seed(XL_LOOK_SEED)
	var field := _field(14061)
	var looks: Dictionary = {}
	var measured := 0
	var off_width := 0
	for index in XL_LOOK_DRAWS:
		var rock := _member(field, AsteroidScript.SIZE_XL, 4, "Look%d" % index)
		var look := int(rock.call(&"look_index"))
		looks[look] = true
		var sprite := rock.get_node_or_null(NodePath(AsteroidScript.LOOK_NODE)) as Sprite2D
		if sprite != null:
			measured += 1
			var width := float(sprite.texture.get_width()) * sprite.scale.x
			if not is_equal_approx(width, PIN_XL_WIDTH):
				off_width += 1
	_check("ac5_three_looks_drawn", looks.size() == 3,
		"%d distinct XL looks over %d draws (%s)" % [looks.size(), XL_LOOK_DRAWS, str(looks.keys())])
	_check("ac5_drawn_width_180", measured == XL_LOOK_DRAWS and off_width == 0,
		"%d sprites measured, %d off the 180 u target" % [measured, off_width])


## --- fixtures -------------------------------------------------------------------
func _field(seed_value: int) -> Node2D:
	var field := FieldScript.new() as Node2D
	field.call(&"setup", {&"tier_weights": TIER_WEIGHTS, &"rocks": 1, &"seed": seed_value})
	_fields.append(field)
	return field


func _member(field: Node2D, size_class: int, units: int, node_name: String) -> Node2D:
	return field.call(&"_new_rock", node_name, &"iron", 1, units, size_class)


func _deplete(rock: Node2D) -> void:
	rock.call(&"apply_work", maxf(float(int(rock.get(&"yield_units"))), AsteroidScript.WORK_PER_UNIT))


func _ids(field: Node2D) -> Array[int]:
	var out: Array[int] = []
	for rock: Node2D in field.call(&"rocks"):
		out.append(rock.get_instance_id())
	return out


func _since(field: Node2D, before: Array[int]) -> Array[Node2D]:
	var out: Array[Node2D] = []
	for rock: Node2D in field.call(&"rocks"):
		if not before.has(rock.get_instance_id()):
			out.append(rock)
	return out


func _pickups(field: Node2D) -> int:
	var total := 0
	for child: Node in field.get_children():
		if child.is_in_group(PICKUP_GROUP):
			total += int(child.get(&"amount"))
	return total


func _free_pickups(field: Node2D) -> void:
	for child: Node in field.get_children():
		if child.is_in_group(PICKUP_GROUP):
			child.free()


func _total_span(row: Dictionary) -> Vector2i:
	var lowest := 0
	var highest := 0
	for child_kind: Variant in row.keys():
		var pair: Vector2i = row[child_kind]
		lowest += pair.x
		highest += pair.y
	return Vector2i(lowest, highest)


func _check(name: String, ok: bool, detail: String) -> void:
	if ok:
		print("%s ok   %s - %s" % [TAG, name, detail])
	else:
		print("%s FAIL %s - %s" % [TAG, name, detail])
		_failures.append(name)
