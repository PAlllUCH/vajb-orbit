@tool
extends McpTestSuite
## Suite s40_legibility: wave S40 - the owner's visibility review of the station decks
## (2026-10-10). One row per pinned acceptance (A1-A3):
##   A1 (T-171) the caption ink clears WCAG AA on every registered surface fill, and
##              `text_dim` keeps the disabled jobs it had;
##   A2 (T-172) the ARMORY's FitCells left column has an opaque flat surface between it
##              and the deck backdrop;
##   A3 (T-173) the OVERVIEW tiles' ink clears AA on the C1 slab.
##
## The measurements behind the pins are in `.agents/gen/slices/S40-legibility/S40_REVIEW.md`
## (607 labels rendered and sampled; 241 below AA before this wave, 33 after).
## The expected side is the only place a literal appears; every shipped number is read from
## its own owner (`build_theme.gd`'s generated theme, `ArmoryPanel`, `OverviewPanel`).

const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const ArmoryScene := preload("res://ui/station/armory_panel.tscn")
const OverviewScene := preload("res://ui/station/overview_panel.tscn")
const OverviewScript := preload("res://ui/station/overview_panel.gd")

const TOKENS_TYPE: StringName = &"Tokens"
const HOST_SIZE := Vector2(1920.0, 1080.0)
const VANGUARD: StringName = &"ship_vanguard"
## WCAG AA for small text. Every caption variation is 13-16 px, so the small-text floor is
## the one that applies.
const AA_SMALL := 4.5
## The variations the amendment moves onto the caption ink (A1).
const CAPTION_VARIATIONS: Array[StringName] = [&"SectionHeader", &"StationCaption", &"FlavourText"]
## Every surface fill a station caption can land on, read from the generated theme.
const SURFACE_TOKENS: Array[StringName] = [
	&"void_base", &"void_panel", &"void_panel_raised", &"metal_dark", &"metal_mid",
	&"armory_bay_bg", &"armory_item_bg", &"armory_chip_bg",
]
## The armory's left-column labels the owner called out, by unique name.
const LEFT_COLUMN_LABELS: Array[String] = [
	"SlotCaption", "CellInfoCaption", "CellInfoId", "CellInfoPower", "CellInfoFitted",
]

var _profile: Node = null
var _host: Control = null
var _armory: Control = null
var _overview: Control = null


func suite_name() -> String:
	return "s40_legibility"


func setup() -> void:
	_profile = (Engine.get_main_loop() as SceneTree).root.get_node_or_null(NodePath(&"PlayerProfile"))


func teardown() -> void:
	for node: Node in [_armory, _overview, _host]:
		if node != null and is_instance_valid(node):
			node.free()
	_armory = null
	_overview = null
	_host = null


## ---------------------------------------------------------------- 1. the caption ink (A1)

func test_a1_the_caption_variations_carry_the_caption_token() -> void:
	var caption := _token(&"text_caption")
	for variation: StringName in CAPTION_VARIATIONS:
		assert_eq(
			ThemeRes.get_color(&"font_color", variation), caption,
			"%s wears the caption ink, not text_dim" % String(variation)
		)


func test_a1_the_caption_ink_clears_aa_on_every_surface() -> void:
	var caption := _token(&"text_caption")
	for token: StringName in SURFACE_TOKENS:
		var fill := _token(token)
		var ratio := _ratio(caption, fill)
		assert_true(
			ratio >= AA_SMALL,
			"text_caption on %s measures %.2f:1 (needs %.1f)" % [String(token), ratio, AA_SMALL]
		)


func test_a1_the_pre_wave_ink_would_have_failed_those_surfaces() -> void:
	## The negative control: the tone the variations carried before this wave is under AA on
	## the shipped row/plate fills, which is what the review measured 235 times.
	var dim := _token(&"text_dim")
	var failures := 0
	for token: StringName in SURFACE_TOKENS:
		if _ratio(dim, _token(token)) < AA_SMALL:
			failures += 1
	assert_true(
		failures > 0,
		"text_dim fails AA on at least one surface fill (measured %d of %d)"
			% [failures, SURFACE_TOKENS.size()]
	)


func test_a1_text_dim_keeps_the_disabled_jobs() -> void:
	var dim := _token(&"text_dim")
	for type: StringName in [&"Button", &"PopupMenu", &"TabBar", &"TabContainer"]:
		assert_eq(
			ThemeRes.get_color(&"font_disabled_color", type), dim,
			"%s's disabled ink is still text_dim" % String(type)
		)


## ------------------------------------------------- 2. the armory's left column roof (A2)

func test_a2_the_armory_left_column_has_an_opaque_surface_behind_it() -> void:
	_mount_armory()
	if _armory == null:
		return
	for label_name: String in LEFT_COLUMN_LABELS:
		var label := _armory.get_node_or_null(NodePath("%" + label_name)) as Label
		assert_true(label != null, "%s exists" % label_name)
		if label == null:
			continue
		var roof := _roof(label, _armory)
		assert_true(
			roof != null,
			"%s has an opaque flat surface between it and the deck backdrop" % label_name
		)
		if roof == null:
			continue
		var box := roof.get_theme_stylebox(&"panel") as StyleBoxFlat
		assert_true(box != null, "%s's roof is a flat Tokens box" % label_name)
		if box == null:
			continue
		assert_true(
			box.bg_color.a >= 0.9 and box.border_width_left == 1,
			"%s's roof is opaque with the 1 px border (A5.3/A5.4)"
				% label_name
		)


func test_a2_the_left_column_keeps_its_sectors_and_names() -> void:
	_mount_armory()
	if _armory == null:
		return
	var left := _armory.get_node_or_null(NodePath("%FitLeft"))
	assert_true(left != null, "the FitLeft sector survives the wrap")
	if left == null:
		return
	assert_true(
		left.is_ancestor_of(_armory.get_node("%SlotLayoutGrid")),
		"the slot grid is still inside FitLeft (S32's P38 row)"
	)
	assert_true(
		left.is_ancestor_of(_armory.get_node("%CellInfoPower")),
		"and so is the cell-info block"
	)


## ------------------------------------------------------ 3. the overview tile ink (A3)

func test_a3_the_tinted_tile_glyphs_wear_the_caption_ink() -> void:
	_mount_overview()
	if _overview == null:
		return
	var glyphs: Array = _overview.get(&"_tile_glyphs")
	assert_eq(glyphs.size(), OverviewScript.TILES.size(), "one glyph per department tile")
	var caption := _token(&"text_caption")
	for index in mini(glyphs.size(), OverviewScript.TILES.size()):
		var glyph := glyphs[index] as TextureRect
		var tinted := bool(OverviewScript.TILES[index][&"tinted"])
		var expected := caption if tinted else Color.WHITE
		assert_eq(
			glyph.modulate, expected,
			"tile %d (%s) modulates the caption ink" % [index, String(OverviewScript.TILES[index][&"title"])]
		)


func test_a3_the_tile_title_and_caption_clear_aa_on_the_slab() -> void:
	_mount_overview()
	if _overview == null:
		return
	## The C1 slab's own interior, measured off the rendered frame in the review.
	var slab := Color("1d1f21")
	for variation: StringName in [&"SectionHeader", &"StationCaption"]:
		var ratio := _ratio(ThemeRes.get_color(&"font_color", variation), slab)
		assert_true(
			ratio >= AA_SMALL,
			"%s on the tile slab measures %.2f:1" % [String(variation), ratio]
		)


## ------------------------------------------------------------------------------ helpers

func _mount_armory() -> void:
	_host = _new_host()
	if _host == null:
		return
	_armory = ArmoryScene.instantiate() as Control
	_host.add_child(_armory)
	_armory.call(&"_lay")


func _mount_overview() -> void:
	_host = _new_host()
	if _host == null:
		return
	_overview = OverviewScene.instantiate() as Control
	_host.add_child(_overview)


func _new_host() -> Control:
	if _profile == null:
		assert_true(false, "no PlayerProfile autoload to stage the pane into")
		return null
	var host := Control.new()
	host.name = "S40LegibilityHost"
	host.theme = ThemeRes
	host.size = HOST_SIZE
	_profile.add_child(host)
	return host


## The nearest ancestor that can carry a painted surface and whose rect covers the ink.
## The deck backdrop is a child of the module host, so the host's own banded frame is not a
## roof - only a real surface class with an opaque flat fill counts (the review's rule).
func _roof(node: Control, stop: Node) -> Control:
	var walker := node.get_parent() as Node
	while walker != null and walker != stop:
		if walker is PanelContainer or walker is Panel or walker is Button \
				or walker is TextureRect or walker is ColorRect or walker is NinePatchRect:
			var control := walker as Control
			var area := control.get_global_rect().intersection(node.get_global_rect())
			if area.get_area() >= node.get_global_rect().get_area() * 0.9:
				for slot: StringName in [&"panel", &"normal", &"background"]:
					var box := control.get_theme_stylebox(slot)
					if box is StyleBoxFlat and (box as StyleBoxFlat).bg_color.a >= 0.9:
						return control
		walker = walker.get_parent()
	return null


func _token(name: StringName) -> Color:
	return ThemeRes.get_color(name, TOKENS_TYPE)


## WCAG contrast ratio on relative luminance.
func _ratio(a: Color, b: Color) -> float:
	var la := _relative(a)
	var lb := _relative(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _relative(colour: Color) -> float:
	return 0.2126 * _channel(colour.r) + 0.7152 * _channel(colour.g) + 0.0722 * _channel(colour.b)


func _channel(value: float) -> float:
	if value <= 0.03928:
		return value / 12.92
	return pow((value + 0.055) / 1.055, 2.4)
