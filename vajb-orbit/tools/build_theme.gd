extends SceneTree
## Generates res://ui/theme/vajb_theme.tres. Re-runnable and deterministic.
## Contract: docs/design/IMPLEMENTATION_PLAN.md section 3.2. This file is the only
## place in the project allowed to hold hex literals.

const PATHS := preload("res://ui/paths.gd")

const PLATE_PATH := "res://assets/ui/ui_button_plate_%s.png"
const SLOT_WEAPON_PATH := "res://assets/ui/ui_slot_weapon_%s.png"
const SLOT_CARGO_PATH := "res://assets/ui/ui_slot_cargo_%s.png"
const PANEL_FRAME_PATH := "res://assets/ui/ui_panel_frame.png"

const BUTTON_STATES: Array[StringName] = [&"normal", &"hover", &"pressed", &"disabled"]

const BASE_FONT_SIZE := 14
const RICH_TEXT_FONT_SIZE := 13
const TOOLTIP_FONT_SIZE := 13
const TAB_FONT_SIZE := 14

## The panel frame is a 96x96 source with a 32 px border band (UI_SPEC section 5.3).
## A StyleBoxTexture has no border_width, so the theme's 1 px border convention is
## carried as a 1 px expand margin and the frame's own painted border is not tinted.
## Measured 2026-09-21 on the shipped F.2 re-band (reband_frame.measure_band): the
## painted band is 31.8 px (edges 30/32/32/33), so a 32 px margin is what matches the
## art. At 8 the nine-patch stretches that band to 69 px vertically and 119 px
## horizontally across every framed panel; at 32 it draws 30/32, the F.2 acceptance
## row. The previous 8 px margin was measured on the pre-reband 13 px art.
## Evidence: docs/design/UI_CHROME_ASSETS_SPEC.md section 10, staging/phase_f/reband_report.json.
const PANEL_FRAME_MARGIN := 32.0
const FRAME_EXPAND_MARGIN := 1.0
const SCROLL_CONTENT_MARGIN := 5.0

## Typography (IMPLEMENTATION_PLAN section 9.8 item 2). Three OFL families ship in
## assets/fonts with their licence texts beside them: Oxanium (variable) as the display
## face pinned to wght 700, Rajdhani as the body face, Saira Stencil One as the flavour
## face. They are imported like any other resource, so this headless build loads them too.
const FONT_OXANIUM := "res://assets/fonts/Oxanium[wght].ttf"
const FONT_RAJDHANI_REGULAR := "res://assets/fonts/Rajdhani-Regular.ttf"
const FONT_RAJDHANI_MEDIUM := "res://assets/fonts/Rajdhani-Medium.ttf"
const FONT_RAJDHANI_SEMIBOLD := "res://assets/fonts/Rajdhani-SemiBold.ttf"
const FONT_SAIRA_STENCIL := "res://assets/fonts/SairaStencilOne-Regular.ttf"

const TITLE_WEIGHT := 700

## Which face each variation draws, keyed by the role names _load_fonts() returns.
## `body` is also Theme.default_font, so an unlisted type inherits Rajdhani-Regular.
const FONT_ROLES: Dictionary = {
	&"ScreenTitle": &"display",
	&"HeroTitle": &"display",
	&"StationPanelTitle": &"display",
	&"DialogTitle": &"display",
	&"HudReadout": &"display",
	&"MenuButtonPlate": &"display",
	&"StationValue": &"semibold",
	&"SectionHeader": &"medium",
	&"StationCaption": &"medium",
	&"Version": &"flavour",
	&"FlavourText": &"flavour",
}

const TOKENS: Dictionary = {
	&"void_base": "#07090d",
	&"void_panel": "#0b0f15",
	&"void_panel_raised": "#10151d",
	&"metal_dark": "#1b2028",
	&"metal_mid": "#2a313c",
	&"metal_light": "#3d4654",
	&"text_primary": "#c9d1dc",
	&"text_dim": "#6b7484",
	&"accent_danger": "#c8471f",
	&"accent_danger_bright": "#e8622a",
	&"menu_glow": "#e8703a",
	&"void_fade": "#07090d",
}

const TOKEN_ALPHA: Dictionary = {
	&"menu_glow": 0.60,
}

## RichTextLabel resolves each of these against default_font_size when it is
## unset, so all five must be pinned or bold text would not follow the body size.
const RICH_TEXT_FONT_ITEMS: Array[StringName] = [
	&"normal_font_size",
	&"bold_font_size",
	&"italics_font_size",
	&"bold_italics_font_size",
	&"mono_font_size",
]

const LABEL_VARIATIONS: Dictionary = {
	&"ScreenTitle": 22,
	&"SectionHeader": 16,
	&"HudReadout": 18,
	&"DialogTitle": 18,
	&"Version": 13,
	&"SlotNumber": 10,
	&"HeroTitle": 48,
	&"StationPanelTitle": 20,
	&"StationValue": 18,
	&"StationCaption": 13,
	&"FlavourText": 13,
}

const VARIATION_BASE: Dictionary = {
	&"ScreenTitle": &"Label",
	&"SectionHeader": &"Label",
	&"HudReadout": &"Label",
	&"DialogTitle": &"Label",
	&"Version": &"Label",
	&"SlotNumber": &"Label",
	&"HeroTitle": &"Label",
	&"StationPanelTitle": &"Label",
	&"StationValue": &"Label",
	&"StationCaption": &"Label",
	&"FlavourText": &"Label",
	&"MenuButton": &"Button",
	&"MenuButtonPlate": &"Button",
	&"StationButton": &"Button",
	&"HudHullBar": &"ProgressBar",
	&"HudShieldBar": &"ProgressBar",
	&"SlotButtonWeapon": &"TextureButton",
	&"SlotButtonCargo": &"TextureButton",
	&"PanelRaised": &"PanelContainer",
}

## A name that is also a built-in class name cannot be registered as a type variation
## (Theme.set_type_variation refuses it). Items registered under it are still used by
## nodes of that class, but not by a variation declared on another class.
const NATIVE_CLASS_NAMES: Array[StringName] = [&"MenuButton"]

## Every variation drawn from the four ui_button_plate_* textures, keyed by name with
## its font size. `MenuButton` is a built-in class, so a plain Button cannot declare it
## as its theme_type_variation; its items are kept so a native MenuButton node themes.
const PLATE_VARIATIONS: Dictionary = {
	&"MenuButton": 34,
	&"MenuButtonPlate": 34,
	&"StationButton": 22,
}

## Plate variations that draw no focus box at all (IMPLEMENTATION_PLAN section 9.8 item 1,
## Wave-1 W6-1 ruling): the main menu cues focus with the tick band and the emblem pulse,
## so its plates must not paint a rectangle when focused. The base `Button` and
## `StationButton` keep the 1 px box because the station rail and the dialogs have no other
## focus affordance. Godot draws `Button/focus` over the state plate from
## `Button::_notification(NOTIFICATION_DRAW)` while `has_focus(true)` holds, so an empty
## box is the only way to stop the rectangle being drawn.
const FOCUSLESS_PLATE_VARIATIONS: Array[StringName] = [&"MenuButtonPlate"]

## Focus item per type, printed by _report() so a build shows what each family draws.
const FOCUS_PROBE: Dictionary = {
	&"Button": &"focus",
	&"MenuButton": &"focus",
	&"MenuButtonPlate": &"focus",
	&"StationButton": &"focus",
	&"TabContainer": &"tab_focus",
}

## The display role must resolve to a FontVariation: the bare Oxanium FontFile is the
## variable font's default instance, which `fvar` declares as ExtraLight (wght 200).
const DISPLAY_ROLE: StringName = &"display"

var _boxes: Dictionary = {}


func _initialize() -> void:
	_run()
	quit()


func _run() -> void:
	var theme: Theme = _build()
	var theme_dir: String = PATHS.THEME.get_base_dir()
	if not DirAccess.dir_exists_absolute(theme_dir):
		var dir_error: int = DirAccess.make_dir_recursive_absolute(theme_dir)
		if dir_error != OK:
			printerr("build_theme: cannot create %s (error %d)" % [theme_dir, dir_error])
			return
	var save_error: int = ResourceSaver.save(theme, PATHS.THEME)
	if save_error != OK:
		printerr("build_theme: save failed for %s (error %d)" % [PATHS.THEME, save_error])
		return
	_report(theme)


func _build() -> Theme:
	_boxes = _make_boxes()
	var theme: Theme = Theme.new()
	theme.default_font_size = BASE_FONT_SIZE
	_register_tokens(theme)
	_register_fonts(theme)
	_register_boxes(theme)
	_register_wiring(theme)
	_register_palette(theme)
	_register_variations(theme)
	_register_chrome(theme)
	return theme


func _register_tokens(theme: Theme) -> void:
	for token: StringName in TOKENS:
		var color: Color = Color(TOKENS[token])
		if TOKEN_ALPHA.has(token):
			color.a = TOKEN_ALPHA[token]
		theme.set_color(token, &"Tokens", color)


func _register_fonts(theme: Theme) -> void:
	var fonts: Dictionary = _load_fonts()
	theme.default_font = fonts[&"body"]
	for variation: StringName in FONT_ROLES:
		var font: Font = fonts[FONT_ROLES[variation]]
		if FONT_ROLES[variation] == DISPLAY_ROLE:
			## W6-6 guard: a display variation that resolved to a bare FontFile would
			## render the hairline ExtraLight default instance, so the build refuses it
			## instead of shipping a face nobody asked for.
			assert(font is FontVariation, "build_theme: the display role for %s must be a FontVariation over the variable face, got %s" % [String(variation), _font_label(font)])
		theme.set_font(&"font", variation, font)


## Loads the four faces once, keyed by role. The display face is a FontVariation over the
## variable Oxanium pinned to wght 700; every other face ships as a single weight. A face
## that fails to load reports and falls back to the body face, so no variation ends up
## without a font.
func _load_fonts() -> Dictionary:
	var body: FontFile = _first_font(FONT_RAJDHANI_REGULAR, null)
	var display: FontVariation = FontVariation.new()
	display.base_font = _first_font(FONT_OXANIUM, body)
	display.variation_opentype = {&"wght": TITLE_WEIGHT}
	return {
		&"display": display,
		&"body": body,
		&"medium": _first_font(FONT_RAJDHANI_MEDIUM, body),
		&"semibold": _first_font(FONT_RAJDHANI_SEMIBOLD, body),
		&"flavour": _first_font(FONT_SAIRA_STENCIL, body),
	}


func _first_font(path: String, fallback: FontFile) -> FontFile:
	var font: FontFile = load(path) as FontFile
	if font != null:
		return font
	printerr("build_theme: missing font %s" % path)
	return fallback


func _register_boxes(theme: Theme) -> void:
	for name: StringName in _boxes:
		theme.set_stylebox(name, &"", _boxes[name])


func _register_wiring(theme: Theme) -> void:
	for type: StringName in [&"PanelContainer", &"Panel", &"PopupPanel", &"PopupMenu", &"TabContainer"]:
		theme.set_stylebox(&"panel", type, _boxes[&"panel"])
	theme.set_stylebox(&"hover", &"PopupMenu", _boxes[&"panel_raised"])
	for state: StringName in BUTTON_STATES:
		theme.set_stylebox(state, &"Button", _boxes[StringName("button_" + String(state))])
	theme.set_stylebox(&"focus", &"Button", _boxes[&"focus"])
	theme.set_stylebox(&"normal", &"LineEdit", _boxes[&"lineedit"])
	theme.set_stylebox(&"focus", &"LineEdit", _boxes[&"lineedit_focus"])
	theme.set_stylebox(&"slider", &"Slider", _boxes[&"slider_groove"])
	theme.set_stylebox(&"grabber_area", &"Slider", _boxes[&"slider_grabber"])
	theme.set_stylebox(&"grabber_area_highlight", &"Slider", _boxes[&"slider_grabber"])
	theme.set_stylebox(&"background", &"ProgressBar", _boxes[&"progress_bg"])
	theme.set_stylebox(&"fill", &"ProgressBar", _boxes[&"progress_fill"])
	theme.set_stylebox(&"panel", &"TooltipPanel", _boxes[&"tooltip_panel"])
	_register_tabs(theme)


func _register_tabs(theme: Theme) -> void:
	var selected: StyleBoxFlat = _flat(_c(&"void_panel_raised"), _c(&"metal_light"))
	var unselected: StyleBoxFlat = _flat(_c(&"metal_dark"), _c(&"metal_mid"))
	var hovered: StyleBoxFlat = _flat(_c(&"metal_mid"), _c(&"metal_light"))
	var disabled: StyleBoxFlat = _flat(_c(&"metal_dark"), _c(&"metal_dark"))
	for box: StyleBoxFlat in [selected, unselected, hovered, disabled]:
		box.content_margin_left = 16.0
		box.content_margin_right = 16.0
		box.content_margin_top = 6.0
		box.content_margin_bottom = 6.0
	theme.set_stylebox(&"tab_selected", &"TabContainer", selected)
	theme.set_stylebox(&"tab_unselected", &"TabContainer", unselected)
	theme.set_stylebox(&"tab_hovered", &"TabContainer", hovered)
	theme.set_stylebox(&"tab_disabled", &"TabContainer", disabled)
	theme.set_stylebox(&"tab_focus", &"TabContainer", _boxes[&"focus"])
	theme.set_stylebox(&"tabbar_background", &"TabContainer", _flat(_c(&"void_base"), _c(&"metal_mid")))


func _register_palette(theme: Theme) -> void:
	for type: StringName in [&"Label", &"Button", &"LineEdit", &"OptionButton", &"PopupMenu"]:
		theme.set_font_size(&"font_size", type, BASE_FONT_SIZE)
	for item: StringName in RICH_TEXT_FONT_ITEMS:
		theme.set_font_size(item, &"RichTextLabel", RICH_TEXT_FONT_SIZE)
	theme.set_font_size(&"font_size", &"TooltipLabel", TOOLTIP_FONT_SIZE)
	theme.set_font_size(&"font_size", &"TabContainer", TAB_FONT_SIZE)
	theme.set_font_size(&"font_size", &"TabBar", TAB_FONT_SIZE)
	theme.set_color(&"font_color", &"Label", _c(&"text_primary"))
	for state_color: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
		theme.set_color(state_color, &"Button", _c(&"text_primary"))
	theme.set_color(&"font_disabled_color", &"Button", _c(&"text_dim"))
	theme.set_color(&"font_color", &"LineEdit", _c(&"text_primary"))
	theme.set_color(&"font_placeholder_color", &"LineEdit", _c(&"text_dim"))
	theme.set_color(&"font_color", &"PopupMenu", _c(&"text_primary"))
	theme.set_color(&"font_hover_color", &"PopupMenu", _c(&"text_primary"))
	theme.set_color(&"font_disabled_color", &"PopupMenu", _c(&"text_dim"))
	theme.set_color(&"default_color", &"RichTextLabel", _c(&"text_primary"))
	theme.set_color(&"font_color", &"TooltipLabel", _c(&"text_primary"))
	for type: StringName in [&"TabContainer", &"TabBar"]:
		theme.set_color(&"font_color", type, _c(&"text_primary"))
		theme.set_color(&"font_unselected_color", type, _c(&"text_dim"))
		theme.set_color(&"font_hovered_color", type, _c(&"text_primary"))
		theme.set_color(&"font_disabled_color", type, _c(&"text_dim"))


func _register_variations(theme: Theme) -> void:
	for variation: StringName in VARIATION_BASE:
		if NATIVE_CLASS_NAMES.has(variation):
			continue
		theme.set_type_variation(variation, VARIATION_BASE[variation])
	for variation: StringName in LABEL_VARIATIONS:
		theme.set_font_size(&"font_size", variation, LABEL_VARIATIONS[variation])
	theme.set_color(&"font_color", &"ScreenTitle", _c(&"text_primary"))
	theme.set_color(&"font_color", &"SectionHeader", _c(&"text_dim"))
	theme.set_color(&"font_color", &"HudReadout", _c(&"text_primary"))
	theme.set_color(&"font_color", &"DialogTitle", _c(&"text_primary"))
	theme.set_color(&"font_color", &"Version", _c(&"text_dim"))
	theme.set_color(&"font_color", &"SlotNumber", _c(&"text_dim"))
	theme.set_color(&"font_color", &"HeroTitle", _c(&"text_primary"))
	theme.set_color(&"font_color", &"StationPanelTitle", _c(&"text_primary"))
	theme.set_color(&"font_color", &"StationValue", _c(&"text_primary"))
	theme.set_color(&"font_color", &"StationCaption", _c(&"text_dim"))
	theme.set_color(&"font_color", &"FlavourText", _c(&"text_dim"))
	_register_plate_variations(theme)
	theme.set_stylebox(&"background", &"HudHullBar", _boxes[&"progress_bg"])
	theme.set_stylebox(&"fill", &"HudHullBar", _flat(_c(&"accent_danger"), _c(&"accent_danger")))
	theme.set_stylebox(&"background", &"HudShieldBar", _boxes[&"progress_bg"])
	theme.set_stylebox(&"fill", &"HudShieldBar", _flat(_c(&"metal_light"), _c(&"metal_light")))
	_register_slot_variation(theme, &"SlotButtonWeapon", SLOT_WEAPON_PATH)
	_register_slot_variation(theme, &"SlotButtonCargo", SLOT_CARGO_PATH)


func _register_plate_variations(theme: Theme) -> void:
	var boxes: Dictionary = {}
	for state: StringName in BUTTON_STATES:
		boxes[state] = _plate(PLATE_PATH % String(state))
	boxes[&"hover_pressed"] = boxes[&"pressed"]
	boxes[&"focus"] = _focus_box()
	var no_focus: StyleBoxEmpty = StyleBoxEmpty.new()
	for variation: StringName in PLATE_VARIATIONS:
		for name: StringName in boxes:
			theme.set_stylebox(name, variation, boxes[name])
		if FOCUSLESS_PLATE_VARIATIONS.has(variation):
			theme.set_stylebox(&"focus", variation, no_focus)
		theme.set_font_size(&"font_size", variation, int(PLATE_VARIATIONS[variation]))
		for state_color: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
			theme.set_color(state_color, variation, _c(&"text_primary"))
		theme.set_color(&"font_disabled_color", variation, _c(&"text_dim"))


## Panel and list chrome beyond the frozen Phase C set (THEME_AUDIO_EXTENSION section 2).
## A PanelContainer asks for the item named `panel`, so the framed look needs the box under
## the variation type as well as the briefed PanelContainer/panel_raised registration.
func _register_chrome(theme: Theme) -> void:
	theme.set_stylebox(&"panel_raised", &"PanelContainer", _boxes[&"panel_frame"])
	theme.set_stylebox(&"panel", &"PanelRaised", _boxes[&"panel_frame"])
	_register_scroll_chrome(theme)
	_register_list_chrome(theme)


func _register_scroll_chrome(theme: Theme) -> void:
	theme.set_stylebox(&"panel", &"ScrollContainer", _boxes[&"panel"])
	theme.set_stylebox(&"scroll", &"VScrollBar", _scroll_box(_c(&"metal_mid"), _c(&"metal_mid")))
	theme.set_stylebox(&"grabber", &"VScrollBar", _scroll_box(_c(&"metal_light"), _c(&"metal_light")))
	theme.set_stylebox(&"grabber_highlight", &"VScrollBar", _scroll_box(_c(&"metal_light"), _c(&"accent_danger")))


func _register_list_chrome(theme: Theme) -> void:
	var hovered: StyleBoxFlat = _flat(_c(&"metal_mid"), _c(&"metal_mid"))
	var selected: StyleBoxFlat = _flat(_c(&"metal_mid"), _c(&"metal_light"))
	theme.set_stylebox(&"panel", &"ItemList", _boxes[&"panel"])
	theme.set_stylebox(&"hovered", &"ItemList", hovered)
	theme.set_stylebox(&"selected", &"ItemList", selected)
	theme.set_stylebox(&"cursor", &"ItemList", _boxes[&"focus"])
	theme.set_font_size(&"font_size", &"ItemList", BASE_FONT_SIZE)
	theme.set_color(&"font_color", &"ItemList", _c(&"text_primary"))
	theme.set_color(&"font_selected_color", &"ItemList", _c(&"text_primary"))
	theme.set_color(&"font_hovered_color", &"ItemList", _c(&"text_primary"))
	theme.set_color(&"font_disabled_color", &"ItemList", _c(&"text_dim"))
	theme.set_stylebox(&"panel", &"Tree", _boxes[&"panel"])
	theme.set_stylebox(&"title_button_normal", &"Tree", _bevel(_c(&"metal_dark")))
	theme.set_stylebox(&"title_button_hover", &"Tree", hovered)
	theme.set_stylebox(&"title_button_pressed", &"Tree", _flat(_c(&"void_panel_raised"), _c(&"metal_dark")))
	theme.set_stylebox(&"title_button_disabled", &"Tree", _flat(_c(&"metal_dark"), _c(&"metal_dark")))
	theme.set_stylebox(&"selected", &"Tree", selected)
	theme.set_stylebox(&"cursor", &"Tree", _boxes[&"focus"])
	theme.set_color(&"font_color", &"Tree", _c(&"text_primary"))
	theme.set_color(&"font_selected_color", &"Tree", _c(&"text_primary"))
	theme.set_color(&"font_disabled_color", &"Tree", _c(&"text_dim"))
	theme.set_color(&"title_button_color", &"Tree", _c(&"text_primary"))


func _register_slot_variation(theme: Theme, variation: StringName, path_template: String) -> void:
	for state: StringName in BUTTON_STATES:
		var texture: Texture2D = load(path_template % String(state))
		if texture == null:
			printerr("build_theme: missing texture %s" % (path_template % String(state)))
			continue
		var box: StyleBoxTexture = StyleBoxTexture.new()
		box.texture = texture
		theme.set_stylebox(state, variation, box)


func _make_boxes() -> Dictionary:
	var boxes: Dictionary = {}
	boxes[&"panel"] = _flat(_c(&"void_panel"), _c(&"metal_mid"))
	boxes[&"panel_raised"] = _bevel(_c(&"void_panel_raised"))
	boxes[&"button_normal"] = _bevel(_c(&"metal_dark"))
	boxes[&"button_hover"] = _flat(_c(&"metal_mid"), _c(&"metal_light"))
	boxes[&"button_pressed"] = _flat(_c(&"void_panel_raised"), _c(&"metal_dark"))
	boxes[&"button_disabled"] = _flat(_c(&"metal_dark"), _c(&"metal_dark"))
	boxes[&"progress_bg"] = _flat(_c(&"void_base"), _c(&"metal_mid"))
	boxes[&"progress_fill"] = _flat(_c(&"accent_danger"), _c(&"accent_danger"))
	boxes[&"focus"] = _focus_box()
	boxes[&"lineedit"] = _flat(_c(&"void_base"), _c(&"metal_mid"))
	boxes[&"lineedit_focus"] = _flat(_c(&"void_base"), _c(&"metal_light"))
	boxes[&"slider_groove"] = _groove_box()
	boxes[&"slider_grabber"] = _grabber_box()
	boxes[&"tooltip_panel"] = _tooltip_box()
	boxes[&"panel_frame"] = _panel_frame_box()
	return boxes


func _flat(background: Color, border: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = background
	box.draw_center = true
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(0)
	return box


func _bevel(background: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = _flat(background, _c(&"metal_light"))
	box.shadow_color = _c(&"metal_dark")
	box.shadow_size = 1
	box.shadow_offset = Vector2(1.0, 1.0)
	return box


## The retired focus rectangle, still drawn by the base Button family, the station plates,
## both list cursors and the tab bar. The main menu plates register an empty box instead
## (FOCUSLESS_PLATE_VARIATIONS).
func _focus_box() -> StyleBoxFlat:
	var box: StyleBoxFlat = _flat(_c(&"accent_danger_bright"), _c(&"accent_danger_bright"))
	box.draw_center = false
	return box


func _groove_box() -> StyleBoxFlat:
	var box: StyleBoxFlat = _flat(_c(&"metal_dark"), _c(&"metal_mid"))
	box.content_margin_top = 1.0
	box.content_margin_bottom = 1.0
	return box


func _grabber_box() -> StyleBoxFlat:
	var box: StyleBoxFlat = _flat(_c(&"metal_light"), _c(&"text_dim"))
	box.content_margin_left = 5.0
	box.content_margin_right = 5.0
	box.content_margin_top = 5.0
	box.content_margin_bottom = 5.0
	return box


func _tooltip_box() -> StyleBoxFlat:
	var background: Color = _c(&"void_panel")
	background.a = 0.9
	var box: StyleBoxFlat = _flat(background, _c(&"metal_mid"))
	box.content_margin_left = 8.0
	box.content_margin_right = 8.0
	box.content_margin_top = 4.0
	box.content_margin_bottom = 4.0
	return box


func _panel_frame_box() -> StyleBoxTexture:
	var box: StyleBoxTexture = _plate(PANEL_FRAME_PATH)
	box.texture_margin_left = PANEL_FRAME_MARGIN
	box.texture_margin_top = PANEL_FRAME_MARGIN
	box.texture_margin_right = PANEL_FRAME_MARGIN
	box.texture_margin_bottom = PANEL_FRAME_MARGIN
	box.expand_margin_left = FRAME_EXPAND_MARGIN
	box.expand_margin_top = FRAME_EXPAND_MARGIN
	box.expand_margin_right = FRAME_EXPAND_MARGIN
	box.expand_margin_bottom = FRAME_EXPAND_MARGIN
	return box


func _scroll_box(background: Color, border: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = _flat(background, border)
	box.content_margin_left = SCROLL_CONTENT_MARGIN
	box.content_margin_right = SCROLL_CONTENT_MARGIN
	return box


func _plate(path: String) -> StyleBoxTexture:
	var texture: Texture2D = load(path)
	if texture == null:
		printerr("build_theme: missing texture %s" % path)
		return StyleBoxTexture.new()
	var box: StyleBoxTexture = StyleBoxTexture.new()
	box.texture = texture
	return box


func _c(token: StringName) -> Color:
	var color: Color = Color(TOKENS[token])
	if TOKEN_ALPHA.has(token):
		color.a = TOKEN_ALPHA[token]
	return color


func _report(theme: Theme) -> void:
	print("[build_theme] saved %s" % PATHS.THEME)
	var token_names: PackedStringArray = theme.get_color_list(&"Tokens")
	print("[build_theme] Tokens colours: %d" % token_names.size())
	for token: StringName in token_names:
		print("  Tokens/%s = %s" % [String(token), theme.get_color(token, &"Tokens")])
	var stylebox_types: PackedStringArray = theme.get_stylebox_type_list()
	for type: StringName in stylebox_types:
		var names: PackedStringArray = theme.get_stylebox_list(type)
		var label: String = "<base>" if String(type).is_empty() else String(type)
		print("[build_theme] styleboxes %s: %d [%s]" % [label, names.size(), ", ".join(names)])
	print("[build_theme] stylebox types: %d" % stylebox_types.size())
	var variations: PackedStringArray = PackedStringArray(VARIATION_BASE.keys())
	print("[build_theme] variations: %d [%s]" % [variations.size(), ", ".join(variations)])
	for type: StringName in FOCUS_PROBE:
		var item: StringName = FOCUS_PROBE[type]
		print("[build_theme] focus %s/%s = %s" % [String(type), String(item), _box_label(theme.get_stylebox(item, type))])
	print("[build_theme] default_font = %s" % _font_label(theme.default_font))
	print("[build_theme] default_font_size = %d" % theme.default_font_size)
	for variation: StringName in FONT_ROLES:
		print("  font %s = %s @ %d" % [
			String(variation),
			_font_label(theme.get_font(&"font", variation)),
			theme.get_font_size(&"font_size", variation),
		])


func _font_label(font: Font) -> String:
	if font == null:
		return "<none>"
	if font.resource_path.is_empty():
		return "%s (embedded)" % font.get_class()
	return font.resource_path


func _box_label(box: StyleBox) -> String:
	if box == null:
		return "<none>"
	var flat: StyleBoxFlat = box as StyleBoxFlat
	if flat == null:
		return box.get_class()
	return "%s border=%d colour=%s draw_center=%s" % [
		box.get_class(),
		flat.border_width_top,
		flat.border_color,
		flat.draw_center,
	]
