class_name StationPanel
extends VBoxContainer
## The shared helper suite every station panel inherits (CODE_AUDIT 2026-10-19,
## P0 item 1). The panel-specific surface stays in the panel: its `_ready`, its
## `_apply_tokens`, its signals and its row builders. This base owns only the
## helpers that were copied verbatim into ten or more panes:
##
##   - the token read (`_token`), the integer grouping (`_format_int`)
##   - the tween lifecycle (`_make_tween`, `_exit_tree`, `_pulse`)
##   - the profile lookup (`_profile`) and the two profile bridges
##     (`_active_hull`, `_base_id`, `_vitals`)
##   - the list/plate/chip builders (`_clear_list`, `_plate_texture`,
##     `_strip_chip_box`) and the slot glyph (`_slot_glyph`)
##
## The armory keeps its own `_token` override because its style object answers
## first; everything else in the suite is the one implementation. Reversal: copy
## the helper back into the pane it is needed by (the pre-2026-10-19 shape).

const UiTokensScript := preload("res://ui/components/ui_tokens.gd")
const PANEL_PROFILE_SERVICE: StringName = &"PlayerProfile"
const PanelProfileScript := preload("res://autoload/player_profile.gd")
const ShipSlotsScript := preload("res://ui/components/ship_slots.gd")

const PANEL_PULSE_MIN_ALPHA := 0.35
const PANEL_PULSE_DOWN_SECONDS := 0.12
const PANEL_PULSE_UP_SECONDS := 0.16

var _tweens: Array[Tween] = []


func _exit_tree() -> void:
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()


## The live theme's colour for one token, white when the theme does not carry it
## (the pre-existing fallback every panel used).
func _token(token: StringName) -> Color:
	return UiTokensScript.colour(self, token)


## The house integer grouping: `1 234 567`, negative values keep their sign.
func _format_int(value: int) -> String:
	return UiTokensScript.format_int(value)


## A pane-owned tween: invalid tweens are pruned before a new one is appended, so
## the list stays bounded across a long station session.
func _make_tween() -> Tween:
	for index in range(_tweens.size() - 1, -1, -1):
		if not _tweens[index].is_valid():
			_tweens.remove_at(index)
	var tween := create_tween()
	_tweens.append(tween)
	return tween


## The attention pulse every pane uses on a changed control.
func _pulse(node: CanvasItem) -> void:
	if node == null:
		return
	var tween := _make_tween()
	tween.tween_property(node, "modulate:a", PANEL_PULSE_MIN_ALPHA, PANEL_PULSE_DOWN_SECONDS).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "modulate:a", 1.0, PANEL_PULSE_UP_SECONDS).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "modulate:a", PANEL_PULSE_MIN_ALPHA, PANEL_PULSE_DOWN_SECONDS).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "modulate:a", 1.0, PANEL_PULSE_UP_SECONDS).set_trans(Tween.TRANS_SINE)


## The profile autoload, anchored at the tree root: STATION_HUB section 12.4 names
## a bare `^"PlayerProfile"` path, which would resolve against this node instead.
func _profile() -> PanelProfileScript:
	if not is_inside_tree():
		return null
	var service := get_tree().root.get_node_or_null(NodePath(PANEL_PROFILE_SERVICE))
	if service == null:
		return null
	var profile: PanelProfileScript = service
	return profile


func _active_hull(profile: PanelProfileScript) -> StringName:
	if profile == null:
		return &""
	return StringName(profile.call(&"active_ship"))


func _base_id(profile: PanelProfileScript, entry: StringName) -> StringName:
	if profile == null or entry == &"":
		return entry
	return StringName(profile.call(&"base_module_id", entry))


func _vitals(profile: PanelProfileScript, ship_id: StringName) -> Dictionary:
	if profile == null or ship_id == &"":
		return {}
	var raw: Variant = profile.call(&"vitals_of", ship_id)
	return raw if raw is Dictionary else {}


## Clear a container without leaving queued children behind (the three service
## panes' own rebuild rule).
func _clear_list(list: Node) -> void:
	for child: Node in list.get_children():
		list.remove_child(child)
		child.queue_free()


## The texture a res:// path names, or null when the path is empty/missing.
## The three service panes carried this body verbatim before 2026-10-19.
func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


## The texture a theme stylebox carries, or null when the theme does not carry it.
func _plate_texture(variation: StringName, state: StringName) -> Texture2D:
	if not has_theme_stylebox(state, variation):
		return null
	var box := get_theme_stylebox(state, variation)
	if box is StyleBoxTexture:
		return (box as StyleBoxTexture).texture
	return null


## The flat chip plate the refinery and shipyard strips share (one border, one
## bg, 8/3 content margins).
func _strip_chip_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = _token(&"armory_chip_bg")
	box.border_color = _token(&"metal_mid")
	box.set_border_width_all(1)
	box.set_corner_radius_all(0)
	box.content_margin_left = 8.0
	box.content_margin_top = 3.0
	box.content_margin_right = 8.0
	box.content_margin_bottom = 3.0
	return box


## 09 section 1's slot glyph through the one slot table.
func _slot_glyph(slot_key: StringName) -> Texture2D:
	return ShipSlotsScript.glyph(slot_key)
