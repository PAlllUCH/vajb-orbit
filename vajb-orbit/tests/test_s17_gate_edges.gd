@tool
extends McpTestSuite
## Suite s17_gate_edges: S17's gate placement at the sector border (11 §6, the
## owner's 2026-09-25 go — same gates, spawn placement only).
##
##   AC1 — every gate in every registry sector stands on its link's bearing ray from
##         the arena centre at the border inset (800 u); the cardinal spine puts all
##         of them at ±4200 u on the link axis. The expectation is re-derived here
##         from the arena geometry and the registry's own corridor bands, never by
##         calling `sector.gd`'s `_edge_reach`.
##   AC2 — no gate's 200 u `TRIGGER_RADIUS` circle enters a corridor band's interior
##         (the own link is exactly tangent: 600 + 200 = 800) and every gate is
##         inside the arena.
##   AC3 — one beacon per gate at the byte-identical formula
##         (`gate.position + gate.position.normalized() * 300`), inside the arena and
##         inside the link's own corridor band.
##   AC4 — per sector the gate count equals `gate_links` size and every name and
##         destination is the unchanged spine set.
##   AC5 — the minimap feed carries one `friendly` blip per gate at its new position.
##   AC6 — `GATE_RING_RADIUS` is gone from `sector.gd`, `FIELD_EDGE_MARGIN` 800 and
##         `BEACON_GATE_OFFSET` 300 stand, and `gate.gd` / `sector_registry.gd` are
##         byte-identical (pinned MD5).
##
## A gate rolls no RNG, so the fixed seed only keeps `populate` deterministic; the
## placement is asserted against geometry, not against the shipped helper. The
## HALF/EDGE_MARGIN/EDGE_INSET constants below are a deliberate second copy of the
## pin — an anti-drift yardstick that reads 11 §6 and not the shipped field.

const SectorScript := preload("res://game/sector.gd")
const Registry := preload("res://game/sector_registry.gd")

const SEED := 170925

## 11 §6 / 18_engine_spec §13: a 10 000 u arena and the fields' 800 u border
## clearance, so the border inset is 5000 - 800 = 4200 on each axis.
const HALF := Vector2(5000.0, 5000.0)
const EDGE_MARGIN := 800.0
const EDGE_INSET := 4200.0
const CORRIDOR_DEPTH := 600.0
const TRIGGER_RADIUS := 200.0
const BEACON_GATE_OFFSET := 300.0
const EPS := 0.001

const SPINE: Array[int] = [1, 2, 3, 4, 5, 6, 7]

## The two forbidden files (S17_BRIEF §2 rule 2), pinned as the pre-wave hashes so
## any byte of drift in either fails here.
const GATE_MD5 := "c13574f6af658c1fcd4728c34901caf3"
## S23 re-pin (disclosed in `S23-B1_report.md`): A6's sector tier (06 section 7's
## cache scaling) reads the tier mix through `sector_tier`, the wave's one edit
## to this file; the pin is the finished tree's reading, the S21/S22 procedure.
const REGISTRY_MD5 := "124dd68b6ffb65f7d905752f56e27ca8"

var _sectors: Array[Node2D] = []


func suite_name() -> String:
	return "s17_gate_edges"


func teardown() -> void:
	for sector: Node2D in _sectors:
		if is_instance_valid(sector):
			sector.free()
	_sectors.clear()


## ---------------------------------------------------------------------------
## AC1 — placement on the link bearing at the border inset
## ---------------------------------------------------------------------------


func test_ac1_every_gate_stands_on_its_links_bearing_at_the_border_inset() -> void:
	var checked := 0
	var measured_report: Array[String] = []
	for number: int in SPINE:
		var row := _row(number)
		var sector := _populated(number)
		var gates: Array = sector.call(&"gates")
		assert_gt(gates.size(), 0, "sector %d has a gate link" % number)
		for gate: Node2D in gates:
			var dest := int(gate.get(&"dest_sector"))
			var bearing := _bearing(row, dest)
			var expected := bearing * _reach(bearing)
			var measured: Vector2 = gate.position
			assert_true(measured.is_equal_approx(expected),
				"sector %d gate->%d at %s, expected the border inset %s"
				% [number, dest, measured, expected])
			## On the bearing ray (no lateral drift) and exactly the inset out.
			var cross := measured.cross(bearing)
			assert_true(absf(cross) <= EPS,
				"sector %d gate->%d lies on the bearing ray (cross %.4f)" % [number, dest, cross])
			assert_true(absf(measured.length() - EDGE_INSET) <= EPS,
				"sector %d gate->%d is the 800 u border inset (%.2f u)"
				% [number, dest, measured.length()])
			measured_report.append("s%d->%d %s" % [number, dest, measured])
			checked += 1
	print("[S17] AC1 gates=%d (%.1f u inset): %s"
		% [checked, EDGE_INSET, ", ".join(measured_report)])
	assert_eq(checked, _gate_link_total(), "every registry gate was measured")


func test_ac1_the_cardinal_spine_puts_every_gate_on_its_axis_at_4200() -> void:
	for number: int in SPINE:
		var sector := _populated(number)
		var gates: Array = sector.call(&"gates")
		for gate: Node2D in gates:
			var measured: Vector2 = gate.position
			var on_axis := absf(absf(measured.x) - EDGE_INSET) <= EPS and absf(measured.y) <= EPS
			assert_true(on_axis,
				"sector %d gate->%d is ±4200 on the link axis (got %s)"
				% [number, int(gate.get(&"dest_sector")), measured])


## ---------------------------------------------------------------------------
## AC2 — clearance from the corridor bands and from the arena edge
## ---------------------------------------------------------------------------


func test_ac2_no_gate_trigger_circle_enters_a_corridor_band_interior() -> void:
	var tangent_report: Array[String] = []
	var minimum := 999999.0
	for number: int in SPINE:
		var row := _row(number)
		var sector := _populated(number)
		var corridors: Array = row.get(&"corridors", [])
		var gates: Array = sector.call(&"gates")
		for gate: Node2D in gates:
			var position: Vector2 = gate.position
			var dest := int(gate.get(&"dest_sector"))
			for entry: Variant in corridors:
				var record: Dictionary = entry
				var band: Rect2 = record.get(&"edge_rect", Rect2())
				var distance := _rect_distance(position, band)
				minimum = minf(minimum, distance)
				assert_true(distance >= TRIGGER_RADIUS - EPS,
					"sector %d gate->%d keeps its 200 u circle out of band %d (%.2f u)"
					% [number, dest, int(record.get(&"dest", 0)), distance])
				if int(record.get(&"dest", 0)) == dest:
					assert_true(absf(distance - TRIGGER_RADIUS) <= EPS,
						"sector %d gate->%d is tangent to its own band (%.2f u)"
						% [number, dest, distance])
					tangent_report.append("s%d->%d %.2f" % [number, dest, distance])
	print("[S17] AC2 own-band tangency (target %.0f): %s | min gate-to-band %.2f u"
		% [TRIGGER_RADIUS, ", ".join(tangent_report), minimum])


func test_ac2_every_gate_sits_inside_the_arena() -> void:
	for number: int in SPINE:
		var sector := _populated(number)
		var gates: Array = sector.call(&"gates")
		for gate: Node2D in gates:
			var position: Vector2 = gate.position
			assert_true(absf(position.x) < HALF.x and absf(position.y) < HALF.y,
				"sector %d gate->%d is inside the arena (%s)"
				% [number, int(gate.get(&"dest_sector")), position])


## ---------------------------------------------------------------------------
## AC3 — the beacon follows the gate
## ---------------------------------------------------------------------------


func test_ac3_one_beacon_per_gate_at_the_pinned_formula() -> void:
	var beacon_report: Array[String] = []
	for number: int in SPINE:
		var row := _row(number)
		var sector := _populated(number)
		var gates: Array = sector.call(&"gates")
		var beacons: Array = sector.call(&"beacons")
		var corridors: Array = row.get(&"corridors", [])
		assert_eq(beacons.size(), gates.size() + corridors.size(),
			"sector %d has one beacon per corridor plus one per gate (11 §3)" % number)
		beacon_report.append("s%d %d+%d" % [number, gates.size(), corridors.size()])
		for gate: Node2D in gates:
			var position: Vector2 = gate.position
			var expected := position + position.normalized() * BEACON_GATE_OFFSET
			var matches := 0
			for beacon: Node2D in beacons:
				if beacon.position.is_equal_approx(expected):
					matches += 1
			assert_eq(matches, 1, "sector %d gate->%d has exactly one beacon at %s"
				% [number, int(gate.get(&"dest_sector")), expected])
	print("[S17] AC3 beacon counts (gates+corridors): %s" % ", ".join(beacon_report))


func test_ac3_a_gate_beacon_lands_inside_its_links_corridor_band() -> void:
	for number: int in SPINE:
		var row := _row(number)
		var sector := _populated(number)
		var gates: Array = sector.call(&"gates")
		for gate: Node2D in gates:
			var dest := int(gate.get(&"dest_sector"))
			var position: Vector2 = gate.position
			var beacon := position + position.normalized() * BEACON_GATE_OFFSET
			assert_true(absf(beacon.x) < HALF.x and absf(beacon.y) < HALF.y,
				"sector %d gate->%d beacon is inside the arena (%s)" % [number, dest, beacon])
			var band := _band_for(row, dest)
			assert_true(band.has_point(beacon),
				"sector %d gate->%d beacon is inside its link's corridor band (%s)"
				% [number, dest, beacon])


## ---------------------------------------------------------------------------
## AC4 — same gates
## ---------------------------------------------------------------------------


func test_ac4_gate_count_matches_gate_links_across_the_seven_rows() -> void:
	for number: int in SPINE:
		var links: Array = _row(number).get(&"gate_links", [])
		var sector := _populated(number)
		var gates: Array = sector.call(&"gates")
		assert_eq(gates.size(), links.size(), "sector %d has one gate per gate_link" % number)
		var dests: Array[int] = []
		for gate: Node2D in gates:
			dests.append(int(gate.get(&"dest_sector")))
		dests.sort()
		var expected: Array = links.duplicate()
		expected.sort()
		assert_eq(dests, expected, "sector %d gate destinations are its gate_links" % number)


func test_ac4_gate_names_and_destinations_are_unchanged() -> void:
	for number: int in SPINE:
		var sector := _populated(number)
		var gates: Array = sector.call(&"gates")
		for gate: Node2D in gates:
			var dest := int(gate.get(&"dest_sector"))
			assert_eq(String(gate.name), "Gate%d" % dest, "the gate is named for its link")
			assert_eq(int(gate.get(&"origin_sector")), number,
				"and knows the sector it stands in")


## ---------------------------------------------------------------------------
## AC5 — the minimap blip feed
## ---------------------------------------------------------------------------


func test_ac5_every_gate_blips_friendly_at_its_new_position() -> void:
	for number: int in SPINE:
		var sector := _populated(number)
		var gates: Array = sector.call(&"gates")
		var blips: Array = sector.call(&"blips")
		for gate: Node2D in gates:
			var position: Vector2 = gate.position
			var matches := 0
			for blip: Dictionary in blips:
				if StringName(blip.get("kind", &"")) != &"friendly":
					continue
				var blip_position: Vector2 = blip.get("pos", Vector2.ZERO)
				if blip_position.is_equal_approx(position):
					matches += 1
			assert_eq(matches, 1, "sector %d gate->%d has one friendly blip at %s"
				% [number, int(gate.get(&"dest_sector")), position])


## ---------------------------------------------------------------------------
## AC6 — the summary pins
## ---------------------------------------------------------------------------


func test_ac6_gate_ring_radius_is_retired_and_the_inset_constants_stand() -> void:
	var source := _source_text("res://game/sector.gd")
	assert_false(source.contains("GATE_RING_RADIUS"),
		"the retired const and its comment are gone from sector.gd")
	assert_true(source.contains("_edge_reach"), "the placement uses the derived edge reach")
	assert_eq(SectorScript.FIELD_EDGE_MARGIN, 800.0, "FIELD_EDGE_MARGIN is unchanged")
	assert_eq(SectorScript.BEACON_GATE_OFFSET, 300.0, "BEACON_GATE_OFFSET is unchanged")
	assert_eq(Registry.CORRIDOR_DEPTH, CORRIDOR_DEPTH, "CORRIDOR_DEPTH is unchanged")


func test_ac6_the_two_forbidden_files_are_byte_identical() -> void:
	assert_eq(FileAccess.get_md5("res://game/gate.gd"), GATE_MD5, "gate.gd is byte-identical")
	assert_eq(FileAccess.get_md5("res://game/sector_registry.gd"), REGISTRY_MD5,
		"sector_registry.gd is byte-identical")


## ---------------------------------------------------------------------------
## Fixtures and derived expectations
## ---------------------------------------------------------------------------


## A populated sector, unparented: the sector builds its own contents with
## `add_child` and reads no tree, so position is the arena centre and every child's
## relative position is its global position.
func _populated(number: int) -> Node2D:
	var sector: Node2D = SectorScript.new()
	sector.name = "S17Sector%d" % number
	_sectors.append(sector)
	sector.call(&"populate", _row(number), SEED)
	return sector


func _row(number: int) -> Dictionary:
	return Registry.sector(Registry.sector_id_for(number))


## The map-edge band a destination's corridor occupies, read off the registry row.
func _band_for(row: Dictionary, dest: int) -> Rect2:
	for entry: Variant in row.get(&"corridors", []):
		if not entry is Dictionary:
			continue
		var record: Dictionary = entry
		if int(record.get(&"dest", 0)) == dest:
			return record.get(&"edge_rect", Rect2())
	return Rect2()


## The link's bearing, re-derived from the registry band's centre (the same source
## `_gate_bearing` reads), east fallback for an unlisted destination.
func _bearing(row: Dictionary, dest: int) -> Vector2:
	var band := _band_for(row, dest)
	var centre := band.get_center()
	if centre.length() > 0.0:
		return centre.normalized()
	return Vector2.RIGHT


## The border reach along `bearing`, re-derived from the arena geometry: per axis the
## inset half-extent over the component's magnitude, the shorter of the two.
func _reach(bearing: Vector2) -> float:
	var limit := HALF - Vector2(EDGE_MARGIN, EDGE_MARGIN)
	var reach := -1.0
	if absf(bearing.x) > 0.0:
		reach = limit.x / absf(bearing.x)
	if absf(bearing.y) > 0.0:
		var candidate := limit.y / absf(bearing.y)
		reach = candidate if reach < 0.0 else minf(reach, candidate)
	return reach


## The shortest distance from a point to a rectangle's closed area; a gate is clear of
## the band's interior while this stays at or above its trigger radius.
func _rect_distance(point: Vector2, rect: Rect2) -> float:
	var closest := Vector2(
		clampf(point.x, rect.position.x, rect.end.x),
		clampf(point.y, rect.position.y, rect.end.y)
	)
	return point.distance_to(closest)


func _gate_link_total() -> int:
	var total := 0
	for number: int in SPINE:
		total += (_row(number).get(&"gate_links", []) as Array).size()
	return total


func _source_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()
