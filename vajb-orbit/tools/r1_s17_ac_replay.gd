extends SceneTree
## S17-R1's independent AC replay (W8 method): measures the wave's claims through
## the shipped seam instead of trusting the builder's suite.
##
##   XDG_DATA_HOME=/tmp/s17r1 "$GODOT_CONSOLE" --headless --path "$VAJB_PROJ" \
##     --script res://tools/r1_s17_ac_replay.gd
##
## AC1 -- every gate of every registry row stands on its link's bearing ray at the
##        border inset, with the expected position re-derived here from the spine
##        order and the arena geometry (never from `_edge_reach`/`_gate_bearing`).
## AC2 -- no gate's 200 u trigger circle enters a corridor band's closed area; the
##        own link is exactly tangent; every gate is inside the arena.
## AC3 -- one beacon per gate at the byte-identical formula, inside the arena and
##        inside its link's band.
## AC4 -- count / names / destinations / origins unchanged across the seven rows.
## AC5 -- one `friendly` blip per gate at its new position.
## AC6 -- the constants and the two forbidden files' hashes.

const SectorScript := preload("res://game/sector.gd")
const Registry := preload("res://game/sector_registry.gd")

const TAG := "[S17R1]"
const SEED := 170925
const HALF := Vector2(5000.0, 5000.0)
const EDGE_MARGIN := 800.0
const INSET := 4200.0
const TRIGGER_RADIUS := 200.0
const CORRIDOR_DEPTH := 600.0
const BEACON_GATE_OFFSET := 300.0
const EPS := 0.001
const GATE_MD5 := "c13574f6af658c1fcd4728c34901caf3"
const REGISTRY_MD5 := "584d206c15c1ab7541e6bcebfb368101"

var _failures: Array[String] = []


func _init() -> void:
	_ac1()
	_ac2()
	_ac3()
	_ac4()
	_ac5()
	_ac6()
	_law_shape()
	print("%s done failures=%d" % [TAG, _failures.size()])
	quit(1 if not _failures.is_empty() else 0)


func _check(name: String, ok: bool, detail: String) -> void:
	if ok:
		print("%s ok   %s - %s" % [TAG, name, detail])
	else:
		print("%s FAIL %s - %s" % [TAG, name, detail])
		_failures.append(name)


## A populated, unparented sector: position is the arena centre, so a child's
## relative position is its global position.
func _populated(number: int) -> Node2D:
	var sector: Node2D = SectorScript.new() as Node2D
	sector.name = "S17R1Sector%d" % number
	sector.call(&"populate", Registry.sector(Registry.sector_id_for(number)), SEED)
	return sector


func _row(number: int) -> Dictionary:
	return Registry.sector(Registry.sector_id_for(number))


## The expected direction of a link, re-derived from 11 §2.3's linear spine: a
## lower-numbered neighbour is west, a higher-numbered one east. Never the bands.
func _spine_direction(number: int, dest: int) -> Vector2:
	return Vector2.LEFT if dest < number else Vector2.RIGHT


func _rect_distance(point: Vector2, rect: Rect2) -> float:
	var closest := Vector2(
		clampf(point.x, rect.position.x, rect.end.x),
		clampf(point.y, rect.position.y, rect.end.y)
	)
	return point.distance_to(closest)


func _band_for(row: Dictionary, dest: int) -> Rect2:
	for entry: Variant in row.get(&"corridors", []):
		if entry is Dictionary and int((entry as Dictionary).get(&"dest", 0)) == dest:
			return (entry as Dictionary).get(&"edge_rect", Rect2())
	return Rect2()


## ------------------------------------------------------------------------- AC1


func _ac1() -> void:
	var measured := 0
	var rows := 0
	for number in range(1, 8):
		var sector := _populated(number)
		var gates: Array = sector.call(&"gates")
		rows += 1
		for gate: Node2D in gates:
			var dest := int(gate.get(&"dest_sector"))
			var direction := _spine_direction(number, dest)
			var expected := direction * INSET
			var position: Vector2 = gate.position
			_check(
				"ac1_s%d_to_%d" % [number, dest],
				position.is_equal_approx(expected),
				"measured %s expected %s (re-derived from the spine + 10 000 u arena)"
				% [position, expected]
			)
			_check(
				"ac1_s%d_to_%d_on_ray" % [number, dest],
				absf(position.cross(direction)) <= EPS
				and absf(position.length() - INSET) <= EPS,
				"on the bearing ray, length %.4f u" % position.length()
			)
			measured += 1
		sector.free()
	_check("ac1_seven_rows", rows == 7, "seven registry rows populated")
	_check("ac1_gate_total", measured == 12, "12 gates measured (6 rows x 2 + 2 x 1)")
	_check(
		"ac1_inset_is_a_doc_number",
		is_equal_approx(HALF.x - EDGE_MARGIN, INSET),
		"5000 - 800 = %.1f u (11 §6)" % INSET
	)


## ------------------------------------------------------------------------- AC2


func _ac2() -> void:
	var minimum := INF
	var tangent_ok := true
	var inside_ok := true
	for number in range(1, 8):
		var row := _row(number)
		var sector := _populated(number)
		var corridors: Array = row.get(&"corridors", [])
		for gate: Node2D in sector.call(&"gates"):
			var position: Vector2 = gate.position
			var dest := int(gate.get(&"dest_sector"))
			if absf(position.x) >= HALF.x or absf(position.y) >= HALF.y:
				inside_ok = false
			for entry: Variant in corridors:
				var record: Dictionary = entry
				var distance := _rect_distance(position, record.get(&"edge_rect", Rect2()))
				minimum = minf(minimum, distance)
				if distance < TRIGGER_RADIUS - EPS:
					_check(
						"ac2_s%d_to_%d_band_%d" % [number, dest, int(record.get(&"dest", 0))],
						false,
						"trigger circle reaches %.2f u into the band" % distance
					)
				if int(record.get(&"dest", 0)) == dest and absf(distance - TRIGGER_RADIUS) > EPS:
					tangent_ok = false
		sector.free()
	_check(
		"ac2_min_clearance",
		minimum >= TRIGGER_RADIUS - EPS,
		"nearest gate-to-any-band distance %.4f u (>= %.0f, interiors disjoint)" % [
			minimum, TRIGGER_RADIUS
		]
	)
	_check("ac2_own_link_tangent", tangent_ok, "every gate exactly tangent to its own band")
	_check("ac2_inside_arena", inside_ok, "every gate |x|,|y| < 5000")
	_check(
		"ac2_tangency_is_the_law",
		is_equal_approx(CORRIDOR_DEPTH + TRIGGER_RADIUS, EDGE_MARGIN),
		"600 + 200 = 800 (11 §6)"
	)
	_check(
		"ac2_no_new_clearance",
		is_equal_approx(SectorScript.FIELD_EDGE_MARGIN, 800.0)
		and is_equal_approx(Registry.CORRIDOR_DEPTH, 600.0),
		"FIELD_EDGE_MARGIN 800 / CORRIDOR_DEPTH 600 stand"
	)


## ------------------------------------------------------------------------- AC3


func _ac3() -> void:
	var total_gates := 0
	var count_ok := true
	var formula_ok := true
	var inside_ok := true
	var in_band_ok := true
	for number in range(1, 8):
		var row := _row(number)
		var sector := _populated(number)
		var gates: Array = sector.call(&"gates")
		var beacons: Array = sector.call(&"beacons")
		var corridors: Array = row.get(&"corridors", [])
		total_gates += gates.size()
		if beacons.size() != gates.size() + corridors.size():
			count_ok = false
		for gate: Node2D in gates:
			var position: Vector2 = gate.position
			var expected := position + position.normalized() * BEACON_GATE_OFFSET
			var matches := 0
			for beacon: Node2D in beacons:
				if beacon.position.is_equal_approx(expected):
					matches += 1
			if matches != 1:
				formula_ok = false
			if absf(expected.x) >= HALF.x or absf(expected.y) >= HALF.y:
				inside_ok = false
			var band := _band_for(row, int(gate.get(&"dest_sector")))
			if band == Rect2() or not band.has_point(expected):
				in_band_ok = false
		sector.free()
	_check("ac3_gate_total", total_gates == 12, "12 gates across the rows")
	_check("ac3_one_beacon_per_gate", count_ok, "beacons == gates + corridors per row")
	_check(
		"ac3_byte_identical_formula",
		formula_ok,
		"each gate has exactly one beacon at position + position.normalized() * 300"
	)
	_check("ac3_beacons_inside_arena", inside_ok, "every gate beacon |x|,|y| < 5000")
	_check("ac3_beacons_in_their_band", in_band_ok, "every gate beacon inside its link's band")


## ------------------------------------------------------------------------- AC4


func _ac4() -> void:
	var ok := true
	var detail := ""
	for number in range(1, 8):
		var row := _row(number)
		var links: Array = (row.get(&"gate_links", []) as Array).duplicate()
		links.sort()
		var sector := _populated(number)
		var gates: Array = sector.call(&"gates")
		var dests: Array[int] = []
		for gate: Node2D in gates:
			dests.append(int(gate.get(&"dest_sector")))
			if String(gate.name) != "Gate%d" % int(gate.get(&"dest_sector")):
				ok = false
				detail = "s%d gate name %s" % [number, String(gate.name)]
			if int(gate.get(&"origin_sector")) != number:
				ok = false
				detail = "s%d gate->%d origin %d" % [
					number, int(gate.get(&"dest_sector")), int(gate.get(&"origin_sector"))
				]
		dests.sort()
		if gates.size() != links.size() or dests != links:
			ok = false
			detail = "s%d gates %s vs links %s" % [number, str(dests), str(links)]
		sector.free()
	_check("ac4_same_gates_all_seven_rows", ok, detail if detail != "" else "count/names/dests/origins hold")
	var root := ProjectSettings.globalize_path("res://..")
	var out: Array = []
	OS.execute("git", ["-C", root, "diff", "--name-only", "HEAD"], out, false)
	var changed := PackedStringArray(String(out[0] if out.size() > 0 else "").split("\n", false))
	var forbidden := false
	var moved_rows := 0
	for path: String in changed:
		if path.begins_with("vajb-orbit/tests/"):
			moved_rows += 1
			if not path.contains("test_s17_gate_edges.gd"):
				forbidden = true
		if path == "vajb-orbit/game/gate.gd" or path == "vajb-orbit/game/sector_registry.gd":
			forbidden = true
	_check(
		"ac4_no_unlisted_row_moved",
		not forbidden and moved_rows <= 1,
		"git diff HEAD: %d test path(s), no forbidden file (%s)" % [moved_rows, ", ".join(changed)]
	)


## ------------------------------------------------------------------------- AC5


func _ac5() -> void:
	var ok := true
	for number in range(1, 8):
		var sector := _populated(number)
		var gates: Array = sector.call(&"gates")
		var blips: Array = sector.call(&"blips")
		for gate: Node2D in gates:
			var position: Vector2 = gate.position
			var matches := 0
			for blip: Dictionary in blips:
				if StringName(blip.get("kind", &"")) == &"friendly" \
						and Vector2(blip.get("pos", Vector2.ZERO)).is_equal_approx(position):
					matches += 1
			if matches != 1:
				ok = false
		sector.free()
	_check("ac5_one_friendly_blip_per_gate", ok, "each gate has one friendly blip at its new position")


## ------------------------------------------------------------------------- AC6


func _ac6() -> void:
	var source := ""
	var file := FileAccess.open("res://game/sector.gd", FileAccess.READ)
	if file != null:
		source = file.get_as_text()
	_check(
		"ac6_gate_ring_radius_gone",
		not source.contains("GATE_RING_RADIUS") and not source.contains("900.0"),
		"GATE_RING_RADIUS, its comment and its 900.0 literal are gone from sector.gd"
	)
	_check(
		"ac6_constants_stand",
		is_equal_approx(SectorScript.FIELD_EDGE_MARGIN, 800.0)
		and is_equal_approx(SectorScript.BEACON_GATE_OFFSET, 300.0)
		and is_equal_approx(Registry.CORRIDOR_DEPTH, 600.0),
		"FIELD_EDGE_MARGIN 800 / BEACON_GATE_OFFSET 300 / CORRIDOR_DEPTH 600"
	)
	_check(
		"ac6_gate_md5", FileAccess.get_md5("res://game/gate.gd") == GATE_MD5,
		"gate.gd byte-identical"
	)
	_check(
		"ac6_registry_md5", FileAccess.get_md5("res://game/sector_registry.gd") == REGISTRY_MD5,
		"sector_registry.gd byte-identical"
	)


## ------------------------------------------------------------------ law shape


func _law_shape() -> void:
	var sector: Node2D = SectorScript.new() as Node2D
	var east: float = sector.call(&"_edge_reach", Vector2.RIGHT)
	var west: float = sector.call(&"_edge_reach", Vector2.LEFT)
	var north: float = sector.call(&"_edge_reach", Vector2.UP)
	var diagonal: float = sector.call(&"_edge_reach", Vector2(1.0, 1.0).normalized())
	var shallow: float = sector.call(&"_edge_reach", Vector2(0.8, 0.6))
	var zero: float = sector.call(&"_edge_reach", Vector2.ZERO)
	_check("law_east", is_equal_approx(east, INSET), "reach east %.4f u" % east)
	_check("law_west", is_equal_approx(west, INSET), "reach west %.4f u" % west)
	_check("law_north", is_equal_approx(north, INSET), "reach north %.4f u" % north)
	_check(
		"law_diagonal_corner",
		is_equal_approx(diagonal, INSET * sqrt(2.0)),
		"45 degrees reaches the corner: %.4f u" % diagonal
	)
	_check(
		"law_per_axis_minimum",
		is_equal_approx(Vector2(0.8, 0.6).normalized().x * shallow, INSET),
		"a shallow bearing lands exactly on the 4200 u axis (x = %.4f)" % (
			Vector2(0.8, 0.6).normalized().x * shallow
		)
	)
	_check("law_zero_guard", is_equal_approx(zero, 0.0), "a zero bearing answers 0.0, no division")
	sector.free()
