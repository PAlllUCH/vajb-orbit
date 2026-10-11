@tool
extends McpTestSuite
## Suite s41_shell: wave S41 (the composition pass, D23-R1) - the theme and the shell half.
## One row per finding this worker owns, plus T-177's no-op proof:
##   T-177 the generated theme keeps its `uid://` lines, and a regeneration is a no-op;
##   F7    a disabled plate keeps a visible edge (and the disabled ink is untouched);
##   F9    the scrollbar's grabber and track read at 1080p, with a 48 px grabber floor;
##   F12   the SERVICES deck prints P29's hint once (the pane's own `%PaneHint`);
##   F15   the SERVICES segments wear the chip row's height, ink and C3 chrome (S41-B5, the
##         half S41-B4 could not reach: the strip is built in `station.gd`);
##   F16   the hover tooltip never lands on the 163 px pane header band.
##
## S41-B5 also carries D23-R1 A3's tidy: the confirm dialog's title wears the theme's own
## dialog-title size token instead of an inline `font_size` override.
##
## The expected side is the only place a literal appears; every shipped number is read from
## its own owner (the generated theme, the shipped scenes, `build_theme.gd`'s constants).

const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const StationScene := preload("res://ui/screens/station.tscn")
const StationScript := preload("res://ui/screens/station.gd")
const TooltipScene := preload("res://ui/components/tooltip.tscn")

const THEME_PATH := "res://ui/theme/vajb_theme.tres"
const GENERATOR_PATH := "res://tools/build_theme.gd"
const TOKENS_TYPE: StringName = &"Tokens"
const PROFILE_SERVICE: StringName = &"PlayerProfile"
const PROFILE_PATH := "user://test_s41_shell.cfg"
const SHIP: StringName = &"ship_vanguard"
const HOST := Vector2(1920.0, 1080.0)

## F12: P29's one hint line, the words that must have a single source on the deck.
const HINT_TEXT := "ONE SERVICE AT A TIME · ESC BACK"
## F16: the pane header band's bottom (UI_SPEC section 19.3) and the tooltip's own offset.
const HEADER_BAND_BOTTOM := 163.0
const CURSOR_OFFSET := Vector2(12.0, 12.0)
## F15's expected side: the chip row's own values - the AUCTION family tab strip's height
## (`auction_panel.gd`'s `TAB_MIN_HEIGHT`), its C3 chrome class and its ink size (the
## `StationValue` variation `TAB_LABEL_VARIATION` names).
const CHIP_HEIGHT := 32.0
const CHIP_CLASS := "C3"
const CHIP_INK_SIZE := 18
## The theme's own dialog-title size token, D23-R1 A3's tidy target.
const DIALOG_TITLE_VARIATION: StringName = &"DialogTitle"
## F9: the grabber's pinned floor. A `StyleBoxFlat`'s minimum size is its content margins
## (the 1 px border is not counted), so 48 px is 24 + 24.
const GRABBER_MIN_HEIGHT := 48.0
## F7: every plate a disabled state draws, by theme type ("" is the base type) and item.
const DISABLED_BOXES: Array[Dictionary] = [
	{&"type": &"", &"item": &"button_disabled"},
	{&"type": &"TabContainer", &"item": &"tab_disabled"},
	{&"type": &"Tree", &"item": &"title_button_disabled"},
]

var _profile: Node = null
var _host: Control = null
var _screen: Control = null
var _tooltip: Control = null
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_owned: Array = []
var _previous_fits: Dictionary = {}
var _previous_modules: Dictionary = {}
var _previous_credits := 0


func suite_name() -> String:
	return "s41_shell"


func suite_setup(_ctx: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		skip_suite("a SceneTree is needed to mount the shell")
		return
	var service := tree.root.get_node_or_null(NodePath(PROFILE_SERVICE))
	if service == null:
		skip_suite("no PlayerProfile autoload to borrow")
		return
	## Borrowed the way `test_s30_shell.gd` borrows it: the scratch path is in place before
	## the first mutation and handed back in `suite_teardown`.
	_profile = service
	_previous_path = String(_profile.get(&"save_path"))
	_previous_ship = StringName(_profile.get(&"_active_ship"))
	_previous_owned = (_profile.get(&"_owned_ships") as Array).duplicate(true)
	_previous_fits = (_profile.get(&"_fits") as Dictionary).duplicate(true)
	_previous_modules = (_profile.get(&"_modules") as Dictionary).duplicate(true)
	_previous_credits = int(_profile.call(&"credits"))
	_profile.set(&"save_path", PROFILE_PATH)
	_profile.set(&"_active_ship", SHIP)
	_profile.set(&"_owned_ships", [SHIP] as Array[StringName])
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})
	_profile.set(&"_credits", 50000)


func suite_teardown() -> void:
	_drop_mounts()
	if _profile == null:
		return
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_owned_ships", _previous_owned)
	_profile.set(&"_fits", _previous_fits)
	_profile.set(&"_modules", _previous_modules)
	_profile.set(&"_credits", _previous_credits)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	var absolute := ProjectSettings.globalize_path(PROFILE_PATH)
	if FileAccess.file_exists(absolute):
		DirAccess.remove_absolute(absolute)
	_profile = null


func teardown() -> void:
	_drop_mounts()


func _drop_mounts() -> void:
	for node: Node in [_screen, _tooltip, _host]:
		if node != null and is_instance_valid(node) and not node.is_queued_for_deletion():
			var parent := node.get_parent()
			if parent != null:
				parent.remove_child(node)
			node.free()
	_screen = null
	_tooltip = null
	_host = null


## ------------------------------------------------------------ T-177: the uid lines


## Every `uid="uid://…"` the theme's own header and its 18 `ext_resource` lines carry is
## still there, and each ext_resource uid still names the asset it sits beside: the authority
## is the asset's own `.import` (an imported texture or face) or its `.uid` sidecar (a
## script). A generator run that wrote a fresh `Theme.new()` strips all 19 lines, so this row
## is red the moment T-177 regresses.
func test_t177_the_generated_theme_keeps_its_uid_lines() -> void:
	var text := _file_text(THEME_PATH)
	assert_true(not text.is_empty(), "the committed theme is readable")
	var header := _header_uid(text)
	assert_true(header.begins_with("uid://"), "the theme's own uid line survives (T-177)")
	var lines := _ext_resource_lines(text)
	assert_eq(lines.size(), 18, "the theme's ext_resource count is unchanged")
	var checked := 0
	for line: String in lines:
		var path := _attr(line, "path")
		var declared := _attr(line, "uid")
		assert_true(declared.begins_with("uid://"), "%s keeps its uid (T-177)" % path)
		if not declared.begins_with("uid://"):
			continue
		var authority := _asset_uid(path)
		assert_eq(declared, authority, "%s's uid is the asset's own (T-177)" % path)
		checked += 1
	assert_eq(checked, 18, "every ext_resource uid was cross-checked")


## The negative control: the damage T-177 reported - a plain `Theme.new()` save - is exactly
## what the two rows above detect. A stripped copy of the committed file loses all 19 uid
## lines, so the checks that read them are not passing by accident.
func test_t177_the_strip_this_wave_prevents_is_detectable() -> void:
	var stripped := _strip_uids(_file_text(THEME_PATH))
	assert_true(not stripped.is_empty(), "the committed theme is readable")
	assert_eq(_header_uid(stripped), "", "a uid-less header is what the header check reads")
	var surviving := 0
	for line: String in _ext_resource_lines(stripped):
		if _attr(line, "uid").begins_with("uid://"):
			surviving += 1
	assert_eq(surviving, 0, "and a uid-less ext_resource is what the asset check reads")


## The acceptance T-177 was filed with: running the generator against the committed file is a
## no-op diff when no token changed. The generator runs as a child process (0.7 s measured)
## and the file is handed back unchanged if the run moved it, so a failing row never leaves a
## stripped theme behind.
func test_t177_a_generator_run_is_a_no_op_when_no_token_changed() -> void:
	var before := _file_text(THEME_PATH)
	assert_true(not before.is_empty(), "the committed theme is readable")
	## The precondition: a file with no uid line to preserve would make this row pass on a
	## stripped theme, which is the damage it exists to catch.
	assert_true(
		before.contains("uid=\""), "the committed file carries uid lines to preserve (T-177)"
	)
	var output: Array = []
	var args := PackedStringArray([
		"--headless",
		"--path", ProjectSettings.globalize_path("res://"),
		"--script", GENERATOR_PATH,
	])
	var code := OS.execute(OS.get_executable_path(), args, output, true)
	var after := _file_text(THEME_PATH)
	var message := "the generator is a no-op when no token changed"
	if after != before:
		message += " (first differing line %d)" % _first_diff_line(before, after)
		var out := FileAccess.open(THEME_PATH, FileAccess.WRITE)
		if out != null:
			out.store_string(before)
			out.close()
	assert_eq(code, 0, "the generator exits clean")
	assert_true(after == before, message)


## ------------------------------------------------------- F7: the disabled plate edge


func test_f7_a_disabled_plate_keeps_a_visible_edge() -> void:
	for spec: Dictionary in DISABLED_BOXES:
		var type := StringName(spec[&"type"])
		var item := StringName(spec[&"item"])
		var label := "%s/%s" % [String(type), String(item)]
		var box := ThemeRes.get_stylebox(item, type) as StyleBoxFlat
		assert_true(box != null, "%s is a flat plate" % label)
		if box == null:
			continue
		assert_true(
			_same(box.border_color, &"metal_mid"),
			"%s keeps a visible metal_mid edge (F7), got %s"
				% [label, box.border_color.to_html(false)]
		)
		assert_true(
			_same(box.bg_color, &"metal_dark"),
			"%s stays the disabled fill, got %s" % [label, box.bg_color.to_html(false)]
		)
		assert_true(
			box.border_width_left == 1 and box.border_width_top == 1
				and box.border_width_right == 1 and box.border_width_bottom == 1,
			"%s's edge is the theme's 1 px (F7)" % label
		)


## The negative control for F7: the tone the edge was before this wave was the plate's own
## fill, which is what made a disabled control read as absent.
func test_f7_the_edge_is_not_the_fill_it_used_to_be() -> void:
	var box := ThemeRes.get_stylebox(&"button_disabled", &"") as StyleBoxFlat
	assert_true(box != null, "the base disabled plate ships")
	if box == null:
		return
	assert_ne(box.border_color, box.bg_color, "the disabled plate's edge is not its fill (F7)")


## S40's A1 territory, untouched: the disabled ink is still `text_dim`.
func test_f7_the_disabled_ink_is_untouched() -> void:
	for type: StringName in [&"Button", &"TabContainer", &"Tree"]:
		var ink := ThemeRes.get_color(&"font_disabled_color", type)
		assert_true(
			ink.is_equal_approx(_token(&"text_dim")),
			"%s's disabled ink is still text_dim (S40 A1), got %s"
				% [String(type), ink.to_html(false)]
		)


## ------------------------------------------------ F9: the scrollbar's grabber + track


func test_f9_the_grabber_and_the_track_read_at_1080p() -> void:
	var grabber := ThemeRes.get_stylebox(&"grabber", &"VScrollBar") as StyleBoxFlat
	var track := ThemeRes.get_stylebox(&"scroll", &"VScrollBar") as StyleBoxFlat
	var highlight := ThemeRes.get_stylebox(&"grabber_highlight", &"VScrollBar") as StyleBoxFlat
	assert_true(grabber != null and track != null and highlight != null, "the scroll chrome ships")
	if grabber == null or track == null or highlight == null:
		return
	assert_true(
		_same(grabber.bg_color, &"text_meta"),
		"the grabber wears text_meta (F9), got %s" % grabber.bg_color.to_html(false)
	)
	assert_true(
		_same(highlight.bg_color, &"text_meta"),
		"and so does its highlight (F9), got %s" % highlight.bg_color.to_html(false)
	)
	assert_true(
		_same(highlight.border_color, &"accent_danger"),
		"the highlight keeps its ember (F9)"
	)
	assert_true(_same(track.bg_color, &"metal_mid"), "the track stays metal_mid (F9)")
	assert_true(
		_same(track.border_color, &"metal_dark"),
		"the track gains a metal_dark edge (F9), got %s" % track.border_color.to_html(false)
	)
	assert_true(
		track.border_width_left == 1 and track.border_width_top == 1
			and track.border_width_right == 1 and track.border_width_bottom == 1,
		"and the edge is the theme's 1 px (F9)"
	)


## The negative control: `metal_light` is the tone the grabber wore, one step off the track's
## own fill, which is why no grabber read on the full-res crops.
func test_f9_the_grabber_left_the_track_tone() -> void:
	var grabber := ThemeRes.get_stylebox(&"grabber", &"VScrollBar") as StyleBoxFlat
	assert_true(grabber != null, "the grabber ships")
	if grabber == null:
		return
	assert_false(
		_same(grabber.bg_color, &"metal_light"),
		"the grabber is no longer metal_light (F9), got %s" % grabber.bg_color.to_html(false)
	)


## The 48 px floor is carried as the grabber stylebox's own minimum height, which is what a
## `VScrollBar` sizes its grabber from, and the engine agrees on a mounted bar.
func test_f9_the_grabber_answers_the_48_px_floor() -> void:
	var grabber := ThemeRes.get_stylebox(&"grabber", &"VScrollBar") as StyleBoxFlat
	assert_true(grabber != null, "the grabber ships")
	if grabber == null:
		return
	assert_eq(grabber.get_minimum_size().y, GRABBER_MIN_HEIGHT, "the grabber's floor is 48 px (F9)")
	var host := _new_host("S41ScrollHost")
	var bar := VScrollBar.new()
	bar.name = "S41Bar"
	host.add_child(bar)
	assert_true(
		bar.get_combined_minimum_size().y >= GRABBER_MIN_HEIGHT,
		"a mounted VScrollBar answers the floor (%.1f)" % bar.get_combined_minimum_size().y
	)


## ------------------------------------------ F12: the SERVICES deck's one hint source


func test_f12_the_services_deck_prints_its_hint_once() -> void:
	var screen := _mount_station()
	if screen == null:
		return
	screen.call(&"_select_module", StationScript.SERVICES, true)
	var services := screen.get(&"_services") as Control
	assert_true(services != null, "the SERVICES deck is built")
	if services == null:
		return
	assert_true(
		services.get_node_or_null(NodePath("PaneFoot/PaneHint")) == null,
		"the shell's own hint node retired (F12)"
	)
	var visible_hints := 0
	for label: Label in _labels(services):
		if label.is_visible_in_tree() and label.text == HINT_TEXT:
			visible_hints += 1
	assert_eq(visible_hints, 1, "the words render once on the deck (F12)")


## ------------------------------- F15: the SERVICES segments wear the chip row's plate


## D23 F15 (the services half): the deck's three segments wear the chip row's own height, ink
## and C3 chrome, so the two switch families - this strip and the SHIPYARD's four mode plates -
## read as one. The strip keeps its own count and its own semantics: service is not filter and
## not mode. Reversal: the shipped 56 px plate with the base `Button` ink and no chip chrome.
func test_f15_the_services_segments_wear_the_chip_row() -> void:
	var screen := _mount_station()
	if screen == null:
		return
	screen.call(&"_select_module", StationScript.SERVICES, true)
	var services := screen.get(&"_services") as Control
	assert_true(services != null, "the SERVICES deck is built")
	if services == null:
		return
	var strip := services.get_node_or_null(NodePath("ServiceStrip")) as Control
	assert_true(strip != null, "the deck's segment strip is built")
	if strip == null:
		return
	assert_eq(
		strip.get_child_count(),
		StationScript.SERVICES_STRIP.size(),
		"the strip keeps one segment per service (F15)"
	)
	for child: Node in strip.get_children():
		var segment := child as Button
		assert_true(segment != null, "a strip child is a segment button")
		if segment == null:
			continue
		assert_eq(
			segment.custom_minimum_size.y,
			CHIP_HEIGHT,
			"%s wears the chip row's height (F15)" % segment.name
		)
		assert_eq(
			String(segment.get_meta(&"chrome_class", "")),
			CHIP_CLASS,
			"%s wears the C3 chip (F15)" % segment.name
		)
		assert_eq(
			segment.get_theme_font_size(&"font_size"),
			CHIP_INK_SIZE,
			"%s wears the chip row's ink (F15)" % segment.name
		)


## -------------------------- D23-R1 A3's tidy: the dialog title's size token


## The confirm dialog's title sets no inline `font_size`: it wears the theme's own dialog-title
## token, the size `ui/dialogs/dialog.tscn` already renders with, so the two dialog titles
## cannot drift apart. Reversal: the inline `font_size 18` override.
func test_the_confirm_dialog_title_wears_the_theme_size_token() -> void:
	var screen := _mount_station()
	if screen == null:
		return
	var dialog := screen.get(&"_confirm") as Control
	assert_true(dialog != null, "the confirm dialog is built")
	if dialog == null:
		return
	var title := dialog.find_child("Title", true, false) as Label
	assert_true(title != null, "the dialog's title label is built")
	if title == null:
		return
	assert_eq(
		title.theme_type_variation,
		DIALOG_TITLE_VARIATION,
		"the title wears the theme's own dialog-title variation"
	)
	assert_false(
		title.has_theme_font_size_override(&"font_size"),
		"and sets no inline font size (D23-R1 A3)"
	)
	assert_eq(
		title.get_theme_font_size(&"font_size"),
		ThemeRes.get_font_size(&"font_size", DIALOG_TITLE_VARIATION),
		"the title's ink is the theme's own size token"
	)


## ------------------------------------------------- F16: the tooltip and the header band

## A payload tall enough that the viewport clamp flips the box above its cursor, which is the
## placement whose top used to land on the pane header band.
func test_f16_the_tooltip_clears_the_header_band() -> void:
	var tooltip := _mount_tooltip()
	if tooltip == null:
		return
	var cursor := Vector2(400.0, 600.0)
	tooltip.call(&"show_for", "LASER CELLS", _long_body(), false, cursor, HOST)
	var box := tooltip.size
	## The precondition that makes this row load-bearing: at this cursor a box this tall
	## overflows the viewport bottom, so the clamp flips it above the cursor and into the band
	## (and stays inside the viewport, so the final clamp cannot mask the guard).
	assert_true(
		box.y > 460.0 and box.y < HOST.y - 16.0,
		"the payload makes a box the clamp would flip into the band (box=%.1f)" % box.y
	)
	assert_true(
		tooltip.position.y >= HEADER_BAND_BOTTOM,
		"the tooltip's top sits below the 163 px header band (y=%.1f)" % tooltip.position.y
	)
	assert_true(
		tooltip.position.y + box.y <= HOST.y - 8.0 + 0.5,
		"and the guard does not push it off the viewport (%.1f)" % (tooltip.position.y + box.y)
	)


## The no-over-fire control: an ordinary placement stays exactly below-right of the cursor.
func test_f16_an_ordinary_placement_is_untouched() -> void:
	var tooltip := _mount_tooltip()
	if tooltip == null:
		return
	var cursor := Vector2(400.0, 300.0)
	tooltip.call(&"show_for", "LASER CELLS", "Standard laser capacitors.", false, cursor, HOST)
	assert_eq(
		tooltip.position, cursor + CURSOR_OFFSET,
		"an ordinary hover is still cursor + (12, 12) (N27)"
	)


## ---------------------------------------------------------------------------- helpers


func _mount_station() -> Control:
	var host := _new_host("S41ShellHost")
	if host == null:
		return null
	_screen = StationScene.instantiate() as Control
	host.add_child(_screen)
	return _screen


func _mount_tooltip() -> Control:
	var host := _new_host("S41TooltipHost")
	if host == null:
		return null
	_tooltip = TooltipScene.instantiate() as Control
	host.add_child(_tooltip)
	return _tooltip


func _new_host(host_name: String) -> Control:
	if _profile == null:
		assert_true(false, "no PlayerProfile autoload to stage into")
		return null
	var host := Control.new()
	host.name = host_name
	host.theme = ThemeRes
	host.size = HOST
	_profile.add_child(host)
	_host = host
	return host


## F16's payload: 30 short lines, which at the tooltip's 15 px face and 360 px cap is a box
## tall enough for the clamp to reach the header band from a mid-screen cursor.
func _long_body() -> String:
	var lines := PackedStringArray()
	for index in 30:
		lines.append("Salvage lot %d, station load." % index)
	return "\n".join(lines)


func _labels(root: Node) -> Array[Label]:
	var found: Array[Label] = []
	for node: Node in root.get_children():
		if node is Label:
			found.append(node as Label)
		found.append_array(_labels(node))
	return found


func _file_text(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func _header_uid(text: String) -> String:
	for line: String in text.split("\n"):
		if line.begins_with("[gd_resource"):
			return _attr(line, "uid")
	return ""


func _ext_resource_lines(text: String) -> Array[String]:
	var found: Array[String] = []
	for line: String in text.split("\n"):
		if line.begins_with("[ext_resource"):
			found.append(line)
	return found


## The uid an asset's own sidecar declares: `.import` for an imported texture or face,
## `.uid` for a script. Empty when neither exists (then the row's own check reports it).
func _asset_uid(path: String) -> String:
	for suffix: String in [".import", ".uid"]:
		var text := _file_text(path + suffix)
		if text.is_empty():
			continue
		for line: String in text.split("\n"):
			var stripped := line.strip_edges()
			if stripped.begins_with("uid="):
				return stripped.substr(4).strip_edges().trim_prefix("\"").trim_suffix("\"")
	return ""


func _attr(line: String, name: String) -> String:
	var marker := name + "=\""
	var start := line.find(marker)
	if start == -1:
		return ""
	start += marker.length()
	var end := line.find("\"", start)
	if end == -1:
		return ""
	return line.substr(start, end - start)


func _first_diff_line(before: String, after: String) -> int:
	var left := before.split("\n")
	var right := after.split("\n")
	for index in mini(left.size(), right.size()):
		if left[index] != right[index]:
			return index + 1
	return mini(left.size(), right.size()) + 1


## Drops every ` uid="…"` attribute, which is what a plain `Theme.new()` save writes.
func _strip_uids(text: String) -> String:
	var out := PackedStringArray()
	for line: String in text.split("\n"):
		var start := line.find(" uid=\"")
		if start != -1:
			var end := line.find("\"", start + 6)
			if end != -1:
				line = line.substr(0, start) + line.substr(end + 1)
		out.append(line)
	return "\n".join(out)


func _token(name: StringName) -> Color:
	return ThemeRes.get_color(name, TOKENS_TYPE)


## Colour comparison that survives the `.tres` text round trip: the generated file stores
## each channel as a printed 32-bit float, so an exact `==` against a freshly built colour is
## a coin flip. A real token difference is orders of magnitude above this epsilon.
func _same(colour: Color, token: StringName) -> bool:
	return colour.is_equal_approx(_token(token))
