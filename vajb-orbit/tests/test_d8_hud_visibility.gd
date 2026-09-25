@tool
extends McpTestSuite
## Suite d8_hud_visibility: wave D8 item 10's top-left acceptance, measured on the
## shipped `hud.tscn` at the project's own 1920 x 1080 viewport.
##
## The QA row this suite answers: "HUD state is bottom-left only ... TopLeft/Blocks
## still holds HullBlock/ShieldBlock/EnergyBlock/FuelBlock but all are hidden
## (hull_vis=false, Blocks size 0x0) ... The top-left quadrant is empty while
## hull/shield state is the thing a player needs mid-fight."
##
## - row 1: the top-left quadrant stays empty of cockpit state - the section 3.1
##   crest blocks and section 3.1b's pool blocks are not visible in the tree at
##   runtime (owner 2026-09-25, D8-H4 no-duplication ruling);
## - row 2: the hidden blocks are still fed, so no state item lost its update path -
##   their values equal the cluster's readings in the same call and track every
##   later feed, not just the first one;
## - row 3: no state item disappears - every surviving readout resolves on its own
##   update path, and the D7-retired ammo/cargo widgets and section 3.1b's pool
##   blocks stay off the flight HUD exactly as the owner's rulings left them.
##
## Nothing is awaited: the headless runner calls every test synchronously, so the
## column's layout pass is forced in `setup` the way the s10 armory rows settle it.

const HudScene := preload("res://ui/hud/hud.tscn")
const HudTheme := preload("res://ui/theme/vajb_theme.tres")

## The project's own viewport (project.godot `display/window/size/*`), the frame
## the QA measured at; `test_ui_slot_layout`'s own fallback rule.
const VIEWPORT_WIDTH_SETTING := "display/window/size/viewport_width"
const VIEWPORT_HEIGHT_SETTING := "display/window/size/viewport_height"
const FALLBACK_VIEWPORT := Vector2(1920.0, 1080.0)

## `hud.gd::set_pool`'s two kinds and the cluster's two dial keys
## (`cockpit_cluster.gd` DIAL_ENRG / DIAL_FUEL): the same two feeds, read one
## seam apart.
const ENERGY: StringName = &"energy"
const FUEL: StringName = &"fuel"
const DIAL_ENRG := "enrg"
const DIAL_FUEL := "fuel"

const BLOCKS_COLUMN := "CanvasLayer/TopLeft/Blocks"
const HULL_BLOCK := "CanvasLayer/TopLeft/Blocks/HullBlock"
const SHIELD_BLOCK := "CanvasLayer/TopLeft/Blocks/ShieldBlock"
## D8-H4: the two section 3.1b pool blocks live in the same column; the top-left
## quadrant must stay empty of every cockpit state readout, not just HULL/SHLD.
const ENERGY_BLOCK := "CanvasLayer/TopLeft/Blocks/EnergyBlock"
const FUEL_BLOCK := "CanvasLayer/TopLeft/Blocks/FuelBlock"

## D8-H2's minimap rows: the bezel unit the legend sits inside, the map view whose
## centre must stay clear, the footer that keeps the zoom glyphs, and the 1080p
## glyph floor (brief rule 3) the QA row binds: "two small glyphs at its
## bottom-right are unreadable at 1080p".
const MINIMAP_PANEL := "CanvasLayer/BottomRight/MinimapPanel"
const MINIMAP_BEZEL := "CanvasLayer/BottomRight/MinimapPanel/MinimapBox/Bezel"
const MINIMAP_VIEW := "CanvasLayer/BottomRight/MinimapPanel/MinimapBox/Bezel/MinimapView"
const MINIMAP_FOOTER := "CanvasLayer/BottomRight/MinimapPanel/MinimapBox/MinimapFooter"
const GLYPH_FLOOR_PX := 12.0

var _hud: Control = null


func suite_name() -> String:
	return "d8_hud_visibility"


func setup() -> void:
	_hud = HudScene.instantiate() as Control
	if _hud == null:
		fail_setup("hud.tscn did not instantiate")
		return
	_hud.theme = HudTheme
	_fixture_host().add_child(_hud)
	_settle_layout()


func teardown() -> void:
	if _hud != null and is_instance_valid(_hud):
		_hud.free()
	_hud = null


## The runner calls every test from inside its own `_ready`, so `root.add_child`
## would fail ("Parent node is busy setting up children"); the profile autoload
## entered the tree first and hosts the fixture the way the D6/D7 suites use it.
func _fixture_host() -> Node:
	var root := (Engine.get_main_loop() as SceneTree).root
	var host := root.get_node_or_null(NodePath(&"PlayerProfile"))
	return host if host != null else root


func viewport_size() -> Vector2:
	return Vector2(
		float(ProjectSettings.get_setting(VIEWPORT_WIDTH_SETTING, FALLBACK_VIEWPORT.x)),
		float(ProjectSettings.get_setting(VIEWPORT_HEIGHT_SETTING, FALLBACK_VIEWPORT.y))
	)


## The pane's own layout pass, as the frame after the build makes it (the s10
## armory rows' settle idiom): every container in the top-left column sorts its
## children to their minimum size, so rects read the way the game shows them.
func _settle_layout() -> void:
	var top_left := _hud.get_node_or_null(NodePath("CanvasLayer/TopLeft"))
	if top_left != null:
		_sort_containers(top_left)


func _sort_containers(node: Node) -> void:
	if node is Container:
		(node as Container).notification(Container.NOTIFICATION_SORT_CHILDREN)
	for child: Node in node.get_children():
		_sort_containers(child)


func _block(path: String) -> Control:
	return _hud.get_node_or_null(NodePath(path)) as Control


func _pair_current(label: Label) -> int:
	if label == null:
		return -1
	return int(String(label.text).split("/")[0])


## ---------------------------------------------------------------------------
## Row 1 - the top-left quadrant stays empty of cockpit state (D8-H4)
## ---------------------------------------------------------------------------


func test_the_top_left_state_blocks_are_not_visible_at_runtime() -> void:
	## Owner 2026-09-25 (D8-H4): hide shield and hull top-left - the cockpit
	## cluster's HULL/SHLD rows already carry them, so the HUD may not repeat the
	## cluster's SPD/HULL/SHLD/AMMO or FUEL/ENRG readouts. Hidden, not deleted:
	## the scene keeps every node and the frozen section 7 API stays callable.
	assert_true(_block(BLOCKS_COLUMN) != null, "TopLeft/Blocks ships")
	for path: String in [HULL_BLOCK, SHIELD_BLOCK, ENERGY_BLOCK, FUEL_BLOCK]:
		var block := _block(path)
		assert_true(block != null, "%s ships" % path.get_file())
		if block == null:
			continue
		assert_false(
			block.is_visible_in_tree(),
			"%s is hidden at runtime (no top-left duplicate of the cluster)" % block.name
		)
	## The two crest rows are on the HUD's own retirement read-back, so this row
	## cannot drift from what `_retire_old_column` actually hides.
	var retired: Array = _hud.call(&"retired_widgets")
	assert_true(
		retired.has(_block(HULL_BLOCK)) and retired.has(_block(SHIELD_BLOCK)),
		"HullBlock/ShieldBlock are on the retired list the HUD drives"
	)


## ---------------------------------------------------------------------------
## Row 2 - the block values match the cluster's for the same frame
## ---------------------------------------------------------------------------


func test_the_block_values_match_the_cluster_for_the_same_frame() -> void:
	var hull_value := _block(HULL_BLOCK + "/HullHeader/HullValue") as Label
	var hull_bar := _block(HULL_BLOCK + "/HullBarRow/HullBar") as ProgressBar
	var shield_value := _block(SHIELD_BLOCK + "/ShieldHeader/ShieldValue") as Label
	assert_true(hull_value != null and shield_value != null, "both blocks carry their value row")
	if hull_value == null or shield_value == null:
		return
	## One feed call writes the block and the cluster together: the same frame by
	## construction (`_on_hull_changed` writes `_refresh_hull` and `set_hull`).
	_hud.call(&"_on_hull_changed", 640.0, 1000.0)
	_hud.call(&"_on_shield_changed", 120.0, 300.0)
	assert_eq(hull_value.text, "640/1000", "the hull block writes its pair")
	assert_eq(shield_value.text, "120/300", "the shield block writes its pair")
	var readings: Dictionary = _hud.call(&"readouts")
	assert_eq(
		_pair_current(hull_value), int(readings["hull"]),
		"the hull block's value equals the cluster's HULL row in the same frame"
	)
	assert_eq(
		_pair_current(shield_value), int(readings["shield"]),
		"the shield block's value equals the cluster's SHLD row in the same frame"
	)
	assert_eq(int(readings["hull"]), 640, "the cluster read 640 from the same call")
	assert_eq(int(readings["shield"]), 120, "and 120 from the same call")
	if hull_bar != null:
		assert_eq(float(hull_bar.value), 640.0, "the hull bar holds the same current")
		assert_eq(float(hull_bar.max_value), 1000.0, "and the same maximum")
	## The sync is every frame, not the first one: a later feed moves both together.
	_hud.call(&"_on_hull_changed", 250.0, 1000.0)
	assert_eq(hull_value.text, "250/1000", "the block follows the next feed")
	assert_eq(
		_pair_current(hull_value), int(_hud.call(&"readouts")["hull"]),
		"and still equals the cluster's row in that frame"
	)
	## The pool pair books from the same call into the cluster's FUEL/ENRG dials
	## (section 3.1b: the dials are the pool readouts, the bars stay retired).
	_hud.call(&"set_pool", ENERGY, 40.0, 100.0)
	_hud.call(&"set_pool", FUEL, 12.0, 200.0)
	var pools: Dictionary = (_hud.call(&"cockpit") as Control).call(&"pool_readings")
	assert_eq(float(pools[DIAL_ENRG]["value"]), 40.0, "the ENRG dial reads the energy feed")
	assert_eq(float(pools[DIAL_FUEL]["value"]), 12.0, "the FUEL dial reads the tank feed")


## ---------------------------------------------------------------------------
## Row 3 - no state item disappears from the HUD
## ---------------------------------------------------------------------------


func test_no_state_item_disappears_from_the_hud() -> void:
	## The cluster keeps every row it carried: SPD/HULL/SHLD/AMMO from their feeds.
	_hud.call(&"set_speedometer", 0.5, Vector2(842.0, 0.0), Vector2.RIGHT)
	_hud.call(&"_on_hull_changed", 640.0, 1000.0)
	_hud.call(&"_on_shield_changed", 120.0, 300.0)
	_hud.call(&"_on_weapon_changed", 1, &"rocket", 24, 60)
	var readings: Dictionary = _hud.call(&"readouts")
	assert_eq(int(readings["spd"]), 842, "SPD still resolves")
	assert_eq(int(readings["hull"]), 640, "HULL still resolves")
	assert_eq(int(readings["shield"]), 120, "SHLD still resolves")
	assert_eq(int(readings["ammo"]), 24, "AMMO still resolves")
	_hud.call(&"set_pool", ENERGY, 40.0, 100.0)
	_hud.call(&"set_pool", FUEL, 12.0, 200.0)
	assert_eq(float(_hud.get(&"_pool_current")[ENERGY]), 40.0, "the pool feed still books")
	assert_eq(
		int((_hud.call(&"cockpit") as Control).call(&"pool_readings")[DIAL_FUEL]["percent"]), 6,
		"and the FUEL dial reads it"
	)
	## The top-right window keeps its own write.
	_hud.call(&"set_target_info", {
		&"name": "Lancer", &"hull": 1.0, &"shield": 0.5, &"distance_m": 1240.0,
		&"threat": "HOSTILE", &"in_range": true, &"has_range": true,
	})
	assert_eq(
		(_hud.get(&"_target_name_label") as Label).text, "Lancer",
		"the target window keeps its name row"
	)
	assert_eq(
		(_hud.get(&"_target_threat_label") as Label).text, "HOSTILE",
		"and its threat row"
	)
	## The prompt strip, the warp bar, the sector row, the credits row and the
	## Emergency Flight banner each keep their own update path.
	_hud.call(&"set_prompt", "DOCK")
	assert_eq((_hud.get(&"_prompt_label") as Label).text, "DOCK", "the prompt still writes")
	_hud.call(&"set_warp_channel", 0.5)
	assert_eq((_hud.get(&"_warp_value") as Label).text, "50%", "the warp channel still writes")
	_hud.call(&"set_sector_name", "KOVANT")
	assert_eq((_hud.get(&"_sector_label") as Label).text, "KOVANT", "the sector still writes")
	_hud.call(&"_refresh_credits")
	assert_true(
		not (_hud.get(&"_credits_value") as Label).text.is_empty(),
		"the credits row still resolves"
	)
	_hud.call(&"set_emergency", true)
	var banner := _hud.get(&"_emergency_banner") as Label
	assert_eq(banner.text, "EMERGENCY FLIGHT", "the banner's copy is untouched")
	assert_true(banner.visible, "and it shows over the column")
	_hud.call(&"set_emergency", false)
	## The retirement the owner's rulings kept: the ammo panel and the cargo block
	## (D7 section 3.7 - their state reads in the cluster's AMMO row and the status
	## screen) and section 3.1b's two pool blocks (the FUEL/ENRG dials).
	for widget: Control in _hud.call(&"retired_widgets"):
		assert_false(widget.is_visible_in_tree(), "%s stays off the flight HUD" % widget.name)
	for block: Control in _hud.call(&"retired_pool_blocks"):
		assert_false(block.is_visible_in_tree(), "%s stays on the cluster dials" % block.name)


## ---------------------------------------------------------------------------
## Row 4 - the minimap legend names exactly the drawn blip kinds (D8-H2)
## ---------------------------------------------------------------------------
## The QA row: "Minimap shows blips and a corridor circle with no legend; two
## small glyphs at its bottom-right are unreadable at 1080p." Rows 4-6 measure
## the legend against `minimap.gd`'s own draw kinds and the 12 px cap-height
## floor at the project's 1920 x 1080.


func test_the_minimap_legend_names_every_draw_kind_and_nothing_else() -> void:
	var legend := _hud.call(&"minimap_legend") as Control
	assert_true(legend != null, "the minimap legend ships")
	if legend == null:
		return
	var kinds := Minimap.draw_kinds()
	assert_eq(
		legend.get_child_count(), kinds.size(),
		"one legend row per drawn kind - %d rows for %d kinds"
		% [legend.get_child_count(), kinds.size()]
	)
	for kind: StringName in kinds:
		var row := legend.get_node_or_null(NodePath("LegendRow_%s" % String(kind))) as Control
		assert_true(row != null, "the legend names the %s kind" % String(kind))
		if row == null:
			continue
		var label := row.get_node_or_null(NodePath("LegendLabel_%s" % String(kind))) as Label
		assert_true(label != null, "%s carries its name label" % String(kind))
		if label != null:
			assert_eq(label.text, String(kind).to_upper(), "%s's label names the kind" % String(kind))
		var mark := row.get_node_or_null(NodePath("LegendMark_%s" % String(kind))) as Control
		assert_true(mark != null, "%s carries its map marker" % String(kind))
		if mark != null:
			assert_eq(
				StringName(mark.get(&"kind")), kind,
				"the marker draws %s's own map shape" % String(kind)
			)
	## The placement the brief binds: inside the minimap bezel's chrome and clear of
	## both centres - on the row between the map frame and the footer, so the map and
	## the self blip stay fully visible and the zoom glyphs keep their bottom-right.
	_settle_minimap()
	var panel := _block(MINIMAP_PANEL)
	var bezel := _block(MINIMAP_BEZEL)
	var map := _block(MINIMAP_VIEW)
	var footer := _block(MINIMAP_FOOTER)
	assert_true(
		panel != null and bezel != null and map != null and footer != null,
		"the minimap bezel, map view and footer ship"
	)
	if panel != null and bezel != null and map != null and footer != null:
		assert_true(
			panel.get_global_rect().encloses(legend.get_global_rect()),
			"the legend sits inside the minimap bezel - measured %s in %s"
			% [legend.get_global_rect(), panel.get_global_rect()]
		)
		assert_true(
			legend.get_global_rect().position.y >= bezel.get_global_rect().end.y - 0.5
			and legend.get_global_rect().end.y <= footer.get_global_rect().position.y + 0.5,
			"on the chrome row below the map frame and above the footer - measured %s"
			% legend.get_global_rect()
		)
		var map_centre: Vector2 = map.get_global_rect().get_center()
		assert_true(
			not legend.get_global_rect().has_point(map_centre),
			"and never over the map's centre at %s" % map_centre
		)


## ---------------------------------------------------------------------------
## Row 5 - every legend glyph and label clears the 12 px cap-height floor
## ---------------------------------------------------------------------------


func test_the_legend_glyphs_and_labels_clear_the_12_px_floor() -> void:
	assert_eq(viewport_size(), FALLBACK_VIEWPORT, "measured at the project's 1920 x 1080")
	var legend := _hud.call(&"minimap_legend") as Control
	assert_true(legend != null, "the minimap legend ships")
	if legend == null:
		return
	for kind: StringName in Minimap.draw_kinds():
		var row := legend.get_node_or_null(NodePath("LegendRow_%s" % String(kind))) as Control
		if row == null:
			continue
		var mark := row.get_node_or_null(NodePath("LegendMark_%s" % String(kind))) as Control
		var label := row.get_node_or_null(NodePath("LegendLabel_%s" % String(kind))) as Label
		if mark != null:
			var ink: Rect2 = mark.call(&"mark_rect")
			assert_true(
				ink.size.y >= GLYPH_FLOOR_PX,
				"the %s legend glyph draws %0.1f px of ink (floor %d px)"
				% [String(kind), ink.size.y, int(GLYPH_FLOOR_PX)]
			)
		if label != null:
			var cap := _cap_height_px(label)
			assert_true(
				cap >= GLYPH_FLOOR_PX,
				"the %s legend label measures %0.2f px cap height (floor %d px)"
				% [String(kind), cap, int(GLYPH_FLOOR_PX)]
			)


## ---------------------------------------------------------------------------
## Row 6 - both zoom glyphs measure at least 12 px at 1080p
## ---------------------------------------------------------------------------


func test_both_zoom_glyphs_measure_at_least_12_px_at_1080p() -> void:
	var marks: Array[Control] = _hud.call(&"zoom_marks")
	assert_eq(marks.size(), 2, "the minimap's two zoom glyphs ship")
	for mark: Control in marks:
		var glyph: String = String(mark.get_parent().name)
		var rects: Array[Rect2] = mark.call(&"zoom_mark_rects")
		assert_false(rects.is_empty(), "%s draws its mark" % glyph)
		assert_true(
			_ink_height(rects) >= GLYPH_FLOOR_PX,
			"the %s glyph measures %0.1f px of ink height (floor %d px)"
			% [glyph, _ink_height(rects), int(GLYPH_FLOOR_PX)]
		)
		for rect: Rect2 in rects:
			assert_true(
				rect.size.y >= GLYPH_FLOOR_PX,
				"%s's mark bar measures %0.1f px thick (floor %d px)"
				% [glyph, rect.size.y, int(GLYPH_FLOOR_PX)]
			)


## ---------------------------------------------------------------------------
## D8-H2 measurement helpers
## ---------------------------------------------------------------------------


## The drawn ink height of a glyph mark's rects (its bars' union): what the QA
## measures on screen as the glyph's pixels.
func _ink_height(rects: Array[Rect2]) -> float:
	if rects.is_empty():
		return 0.0
	var top := rects[0].position.y
	var bottom := rects[0].end.y
	for rect: Rect2 in rects:
		top = minf(top, rect.position.y)
		bottom = maxf(bottom, rect.end.y)
	return bottom - top


## Cap height at the label's own resolved font and size - the QA's own pixel
## measure - computed from the font's own typographic tables (OS/2 `sCapHeight`
## over the head table's units-per-em; Oxanium: 690/1000) scaled by the resolved
## font size: 18 px `HudReadout` -> 12.42 px, and the rendered capital ink
## measures 13 px at that size. The tables are read from the font's own bytes, so
## the number is the font's and holds at any resolution or `ui_scale`.
func _cap_height_px(label: Label) -> float:
	var font := label.get_theme_font(&"font")
	var fsize := float(label.get_theme_font_size(&"font_size"))
	var file := font as FontFile
	if file == null and font is FontVariation:
		file = (font as FontVariation).base_font as FontFile
	if file == null:
		return 0.0
	var bytes := file.data
	if bytes.is_empty():
		return 0.0
	var units_per_em := 0
	var cap_units := 0
	for index: int in range(_be16(bytes, 4)):
		var record := 12 + 16 * index
		var tag := bytes.slice(record, record + 4).get_string_from_ascii()
		var table := _be32(bytes, record + 8)
		if tag == "head":
			units_per_em = _be16(bytes, table + 18)
		elif tag == "OS/2" and _be16(bytes, table) >= 2:
			cap_units = _be16(bytes, table + 88)
	if units_per_em <= 0 or cap_units <= 0:
		return 0.0
	return fsize * float(cap_units) / float(units_per_em)


func _be16(bytes: PackedByteArray, offset: int) -> int:
	return (int(bytes[offset]) << 8) | int(bytes[offset + 1])


func _be32(bytes: PackedByteArray, offset: int) -> int:
	return (
		(int(bytes[offset]) << 24)
		| (int(bytes[offset + 1]) << 16)
		| (int(bytes[offset + 2]) << 8)
		| int(bytes[offset + 3])
	)


## The minimap pane's own layout pass (H1's `_settle_layout` idiom), so the bezel
## and legend rects read the way the game shows them at 1920 x 1080.
func _settle_minimap() -> void:
	var bottom_right := _hud.get_node_or_null(NodePath("CanvasLayer/BottomRight"))
	if bottom_right != null:
		_sort_containers(bottom_right)


## ---------------------------------------------------------------------------
## Row 7 - the 12 px cap-height floor over every HUD Label and TextureRect (D8-H3)
## ---------------------------------------------------------------------------
## The QA row this sweep generalises: "two small glyphs at its bottom-right are
## unreadable at 1080p". The table drives the walk: every Label and every
## textured TextureRect in the HUD tree resolves exactly one table row (first
## match wins), so no text/glyph row can exist without a floor decision here.
## Labels measure cap height (`_cap_height_px`, row 5's own measure); TextureRects
## measure their drawn ink height (the `tools/d8_glyph_audit.gd` glyph definition,
## scaled to the drawn height). The rule-5 cockpit's labels resolve to floor 0:
## the brief pins the cockpit as-is (SLICE "Out of scope"; its rack ordinals are
## S15's), attributed in D8-H3_report.md and never fixed here.

const CockpitStyleScript := preload("res://ui/hud/cockpit_style.gd")

const FONT_FLOOR_TABLE: Array[Dictionary] = [
	{
		&"match": "CockpitCluster", &"kind": "label", &"floor": 0.0,
		&"note": "rule-5 cockpit (SLICE out of scope; attributed, never fixed)",
	},
	{&"match": "*", &"kind": "label", &"floor": GLYPH_FLOOR_PX, &"note": "the 12 px cap floor"},
	{&"match": "*", &"kind": "texture", &"floor": GLYPH_FLOOR_PX, &"note": "the 12 px ink floor"},
]


func test_every_hud_label_and_texture_clears_the_12_px_floor() -> void:
	assert_eq(viewport_size(), FALLBACK_VIEWPORT, "measured at the project's 1920 x 1080")
	_sort_containers(_hud)
	var counted: Array[int] = [0]
	_measure_floor_rows(_hud, counted)
	assert_true(
		counted[0] >= 60,
		"the sweep measured %d HUD text/glyph rows (the census walks them all)" % counted[0]
	)
	## The W refs (`ShipStatusScreen`'s dynamic `SlotNumber` labels) build only once a
	## hull launches, so their floor is guarded at the source constant the screen
	## applies; a plain probe measures exactly what a ref resolves.
	var style: Resource = CockpitStyleScript.new()
	var probe := Label.new()
	probe.name = "RefFloorProbe"
	probe.theme_type_variation = &"SlotNumber"
	probe.add_theme_font_size_override(&"font_size", int(style.status_ref_font_size))
	_hud.add_child(probe)
	assert_true(
		_cap_height_px(probe) >= GLYPH_FLOOR_PX,
		"the W refs' source size measures %0.2f px cap (floor %d px)"
		% [_cap_height_px(probe), int(GLYPH_FLOOR_PX)]
	)
	probe.free()


func _measure_floor_rows(node: Node, counted: Array[int]) -> void:
	for child: Node in node.get_children():
		if child is Label:
			var entry := _floor_entry(child, "label")
			var cap := _cap_height_px(child as Label)
			assert_true(
				cap >= float(entry[&"floor"]),
				"%s measures %0.2f px cap (floor %0.1f px) - %s"
				% [String(child.name), cap, float(entry[&"floor"]), String(entry[&"note"])]
			)
			counted[0] += 1
		elif child is TextureRect:
			var rect := child as TextureRect
			if rect.texture != null:
				var entry := _floor_entry(child, "texture")
				var ink := _texture_ink_px(rect)
				assert_true(
					ink >= float(entry[&"floor"]),
					"%s draws %0.1f px of ink (floor %0.1f px) - %s"
					% [String(child.name), ink, float(entry[&"floor"]), String(entry[&"note"])]
				)
				counted[0] += 1
		_measure_floor_rows(child, counted)


func _floor_entry(node: Node, kind: String) -> Dictionary:
	for entry: Dictionary in FONT_FLOOR_TABLE:
		if String(entry[&"kind"]) != kind:
			continue
		if String(entry[&"match"]) == "*" or _has_ancestor_named(node, String(entry[&"match"])):
			return entry
	return {&"match": "*", &"kind": kind, &"floor": GLYPH_FLOOR_PX, &"note": "default"}


func _has_ancestor_named(node: Node, wanted: String) -> bool:
	var cursor: Node = node
	while cursor != null and cursor != _hud:
		if String(cursor.name) == wanted:
			return true
		cursor = cursor.get_parent()
	return false


## The drawn ink height of a TextureRect's glyph: the non-transparent pixel bbox of its
## texture scaled to the drawn height - `tools/d8_glyph_audit.gd`'s `ink` column, the
## definition the wave's offender tables measure glyphs by.
func _texture_ink_px(rect: TextureRect) -> float:
	var texture: Texture2D = rect.texture
	if texture == null:
		return -1.0
	var image: Image = texture.get_image()
	var tex_size: Vector2 = texture.get_size()
	if image == null or image.is_empty() or tex_size.y <= 0.0:
		return -1.0
	var drawn := rect.size.y if rect.size.y > 0.5 else rect.custom_minimum_size.y
	if drawn <= 0.5:
		drawn = tex_size.y
	var top := -1
	var bottom := -1
	for y: int in image.get_height():
		var hit := false
		for x: int in image.get_width():
			if image.get_pixel(x, y).a > 0.02:
				hit = true
				break
		if not hit:
			continue
		if top < 0:
			top = y
		bottom = y
	if top < 0:
		return 0.0
	return float(bottom - top + 1) * (drawn / tex_size.y)
