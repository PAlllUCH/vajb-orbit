extends Node
## D7-R1 independent geometry/behaviour probe (review evidence, not a fix).
##
## Reads the shipped surfaces through their own read-backs and prints one JSON line per
## measurement, prefixed `R1_`. Run:
##   godot --headless --path "$VAJB_PROJ" res://tools/d7r1_probe.tscn
## It writes and deletes `res://ui/hud/cockpit_style_user.tres` inside the same run to prove
## the drop-in override works end to end; the file must not survive the run.

const HudScene := preload("res://ui/hud/hud.tscn")
const HudTheme := preload("res://ui/theme/vajb_theme.tres")
const ClusterScript := preload("res://ui/hud/cockpit_cluster.gd")
const StyleScript := preload("res://ui/hud/cockpit_style.gd")
const ArmoryScene := preload("res://ui/station/armory_panel.tscn")
const ArmoryPanelScript := preload("res://ui/station/armory_panel.gd")
const ShipFit := preload("res://game/ship_fit.gd")

const STYLE_DROP := "res://ui/hud/cockpit_style_user.tres"
const ROWS: Array[StringName] = [&"spd", &"hull", &"shld", &"ammo"]

var _hud: Control = null


func _ready() -> void:
	_build_hud()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_cluster_surface()
	_readouts_and_stubs()
	_feeds()
	_retirements()
	_style_drop()
	await _armory()
	await _status()
	get_tree().quit()


func _build_hud() -> void:
	_hud = HudScene.instantiate() as Control
	_hud.theme = HudTheme
	add_child(_hud)


func _j(v: Variant) -> Variant:
	if v is Vector2:
		return [v.x, v.y]
	if v is Vector2i:
		return [v.x, v.y]
	if v is Rect2:
		return [v.position.x, v.position.y, v.size.x, v.size.y]
	if v is Color:
		return [v.r, v.g, v.b, v.a]
	if v is Array:
		var out: Array = []
		for item: Variant in v:
			out.append(_j(item))
		return out
	if v is Dictionary:
		var d: Dictionary = {}
		for k: Variant in v:
			d[String(k)] = _j(v[k])
		return d
	return v


func _p(tag: String, value: Variant) -> void:
	print("R1_%s %s" % [tag, JSON.stringify(_j(value))])


func _cluster() -> Control:
	return _hud.call(&"cockpit")


func _cluster_surface() -> void:
	var c: Control = _cluster()
	var s: Resource = c.call(&"style")
	_p("cluster_box", {
		"min": c.custom_minimum_size, "size": c.size, "pos": c.global_position,
		"parent": c.get_parent().name,
	})
	_p("style_defaults", {
		"box": s.box_size, "band": s.band,
		"bays": [s.bay_left, s.bay_middle, s.bay_right], "gutter": s.gutter,
		"interior": s.interior(), "left_bay": s.left_bay(), "middle_bay": s.middle_bay(),
		"right_bay": s.right_bay(), "cell": s.cell_size, "pitch": s.cell_pitch,
		"row_height": s.row_height, "row_pitch": s.row_pitch, "label_zone": s.label_zone,
		"label_font": s.label_font_size, "row_top": s.rows_top(), "row_x": s.row_x(),
		"row0": s.row_rect(0, 4), "row3": s.row_rect(3, 4), "rows_bottom": s.rows_bottom(4),
		"foot_well": s.foot_well(), "readout_well": s.readout_well(4),
		"dial_radius": s.dial_radius, "dial_rim": s.dial_rim,
		"dial_well_radius": s.dial_well_radius(), "dial_clearance": s.dial_clearance(),
		"dial_top": s.dial_top, "dial_bottom": s.dial_bottom,
		"lamp_count": s.lamp_count, "lamp_size": s.lamp_size, "lamp_gap": s.lamp_gap,
		"lamp_width": s.lamp_width(), "gauge_size": s.gauge_size,
		"gauge_centre": s.gauge_centre(), "gauge_well_radius": s.gauge_well_radius(),
	})
	_p("wells", c.call(&"wells"))
	var rows: Dictionary = {}
	for key: StringName in ROWS:
		var r: Control = c.call(&"row", key)
		var rects: Array[Rect2] = r.call(&"cell_rects")
		var overlaps := 0
		var outside := 0
		var row_box := Rect2(Vector2.ZERO, r.custom_minimum_size)
		for a: int in rects.size():
			var ra := rects[a]
			if not row_box.encloses(ra):
				outside += 1
			for b: int in rects.size():
				if b <= a:
					continue
				var rb := rects[b]
				if ra.intersects(rb, false):
					overlaps += 1
		var mods: Array = []
		var tinted := 0
		for cell: Variant in r.call(&"digit_cells"):
			mods.append((cell as TextureRect).modulate)
			if (cell as TextureRect).modulate != Color.WHITE:
				tinted += 1
		rows[String(key)] = {
			"label": r.call(&"label_text"), "min": r.custom_minimum_size,
			"rects": rects, "cells": r.call(&"cells"), "overlaps": overlaps,
			"outside": outside, "tinted": tinted, "mods": mods,
			"font": (r.call(&"label_node") as Label).get_theme_font_size(&"font_size"),
		}
	_p("rows", rows)
	_p("dials", {
		"fuel": _dial(&"fuel"), "enrg": _dial(&"enrg"),
	})
	_p("lamps", {
		"rects": c.call(&"lamp_band").call(&"lamp_rects"),
		"texts": _labels(c.call(&"lamp_band").call(&"lamp_labels")),
		"lit": c.call(&"lamp_band").call(&"lit_rack"),
	})
	_p("gauge_bay", {
		"pos": (c.call(&"gauge_bay") as Control).position,
		"size": (c.call(&"gauge_bay") as Control).size,
	})


func _dial(key: StringName) -> Dictionary:
	var d: Control = _cluster().call(&"value_dial", key)
	return {
		"pos": d.position, "min": d.custom_minimum_size,
		"label": (d.call(&"dial_label") as Label).text,
		"font": (d.call(&"dial_label") as Label).get_theme_font_size(&"font_size"),
		"percent": d.call(&"percent"), "lit_wedges": d.call(&"lit_wedges"),
	}


func _labels(nodes: Array) -> Array:
	var out: Array = []
	for node: Variant in nodes:
		out.append((node as Label).text)
	return out


func _readouts_and_stubs() -> void:
	var c: Control = _cluster()
	c.call(&"set_speedometer", 0.95, Vector2(1234.0, 50.0), Vector2(0.0, 1.0))
	c.call(&"set_hull", 200.0, 1000.0)
	c.call(&"set_shield", 240.0, 300.0)
	c.call(&"set_ammo", 42)
	c.call(&"set_pool", &"fuel", 12.0, 200.0)
	c.call(&"set_pool", &"energy", 40.0, 100.0)
	_p("readouts", c.call(&"readouts"))
	_p("pools", c.call(&"pool_readings"))
	_p("stubs", {
		"compass_null": c.call(&"compass") == null,
		"heading": c.call(&"compass_heading"),
		"hdg_in_readouts": (c.call(&"readouts") as Dictionary).has("hdg"),
	})
	var sp: Control = _hud.call(&"speedometer")
	sp.call(&"set_reading", 0.5, Vector2(1.0, 0.0), Vector2(0.0, 1.0))
	var before: Vector2 = sp.get(&"prograde")
	sp.call(&"set_reading", 0.5, Vector2(1.0, 0.0), Vector2(1.0, 0.0))
	_p("speedometer", {
		"present": sp != null, "min": sp.custom_minimum_size,
		"filled": sp.call(&"filled_segments"), "overdrive": sp.call(&"overdrive_segment"),
		"needle": sp.call(&"needle_colour"), "prograde": sp.get(&"prograde"),
		"heading_ignored": sp.get(&"prograde") == before, "has_heading_prop": sp.get(&"heading") != null,
	})
	_p("cells_pad", {
		"spd": _cluster().call(&"row", &"spd").call(&"cells"),
		"hull": _cluster().call(&"row", &"hull").call(&"cells"),
		"ammo_42": _cluster().call(&"row", &"ammo").call(&"cells"),
	})
	_cluster().call(&"set_ammo", 7)
	_p("cells_pad_7", _cluster().call(&"row", &"ammo").call(&"cells"))
	_p("danger", {
		"spd_framed": _cluster().call(&"row", &"spd").call(&"framed"),
		"hull_label": _cluster().call(&"row", &"hull").call(&"label_colour"),
		"hull_framed": _cluster().call(&"row", &"hull").call(&"framed"),
		"digits_untinted": _cluster().call(&"row", &"hull").call(&"digit_cells").size() > 0,
	})


func _feeds() -> void:
	var c: Control = _cluster()
	var band: Control = c.call(&"lamp_band")
	var lit: Array = []
	for rack: int in [1, 3, 5, 6, 7, 0]:
		c.call(&"set_active_rack", rack)
		lit.append([rack, band.call(&"lit_rack")])
	_p("lamp_feed", lit)
	_hud.call(&"select_battery", 2)
	_p("lamp_from_hud", {
		"lit": band.call(&"lit_rack"), "active_rack": c.call(&"active_rack"),
	})
	c.call(&"set_active_rack", 1)


func _retirements() -> void:
	var old: Array = _hud.call(&"retired_widgets")
	var pool: Array = _hud.call(&"retired_pool_blocks")
	_p("retired_old_column", {
		"count": old.size(),
		"names": _names(old),
		"visible": _visible(old),
		"in_tree": _in_tree(old),
	})
	_p("retired_pool_blocks", {
		"count": pool.size(), "names": _names(pool), "visible": _visible(pool),
	})
	var banner: Label = _hud.find_child("EmergencyBanner", true, false) as Label
	_p("banner", {
		"found": banner != null,
		"text": banner.text if banner != null else "",
		"visible_before": banner.visible if banner != null else null,
		"parent": banner.get_parent().name if banner != null else "",
	})
	_hud.call(&"set_emergency", true)
	_p("banner_lit", {
		"visible": banner.visible if banner != null else null,
		"colour": banner.get_theme_color(&"font_color") if banner != null else null,
	})
	_hud.call(&"set_emergency", false)
	var st: Control = _hud.call(&"status_screen")
	_p("hud_api", {
		"cockpit": c_ok(_hud.call(&"cockpit")),
		"compass_null": _hud.call(&"compass") == null,
		"compass_heading": _hud.call(&"compass_heading"),
		"readouts": _hud.call(&"readouts"),
		"status_screen": st != null,
	})


func _names(nodes: Array) -> Array:
	var out: Array = []
	for n: Variant in nodes:
		out.append((n as Node).name)
	return out


func _visible(nodes: Array) -> Array:
	var out: Array = []
	for n: Variant in nodes:
		out.append((n as CanvasItem).visible)
	return out


func _in_tree(nodes: Array) -> Array:
	var out: Array = []
	for n: Variant in nodes:
		out.append((n as CanvasItem).is_visible_in_tree())
	return out


func c_ok(v: Variant) -> bool:
	return v != null


func _style_drop() -> void:
	var s: Resource = StyleScript.new()
	s.box_size = Vector2(600.0, 300.0)
	s.bay_left = 150.0
	s.row_pitch = 60.0
	s.cell_size = Vector2(24.0, 40.0)
	s.cell_pitch = 26.0
	s.text_dim = Color(0.1, 0.9, 0.2)
	s.dial_top = Vector2(280.0, 90.0)
	var save_err: int = ResourceSaver.save(s, STYLE_DROP)
	var c: Control = ClusterScript.new()
	add_child(c)
	var got: Resource = c.call(&"style")
	var spd: Control = c.call(&"row", &"spd")
	_p("style_drop", {
		"save_err": save_err, "file_exists": FileAccess.file_exists(STYLE_DROP),
		"box": got.box_size, "min": c.custom_minimum_size, "bay_left": got.bay_left,
		"row_pitch": got.row_pitch, "cell": got.cell_size,
		"row0": got.row_rect(0, 4), "cell0": got.cell_rect(0),
		"text_dim": got.text_dim, "dial_top": got.dial_top,
		"label_colour": spd.call(&"label_colour"),
		"label_token": String(spd.call(&"label_token")),
		"dial_fuel_pos": (c.call(&"value_dial", &"fuel") as Control).position,
	})
	c.free()
	var rm_err: int = DirAccess.remove_absolute(ProjectSettings.globalize_path(STYLE_DROP))
	var c2: Control = ClusterScript.new()
	add_child(c2)
	_p("style_drop_reverted", {
		"rm_err": rm_err, "file_exists_after": FileAccess.file_exists(STYLE_DROP),
		"loader_exists_after": ResourceLoader.exists(STYLE_DROP),
		"loader_load_after": ResourceLoader.load(STYLE_DROP) != null,
		"box": (c2.call(&"style") as Resource).box_size, "min": c2.custom_minimum_size,
		"is_fresh_defaults": (c2.call(&"style") as Resource).box_size == Vector2(464.0, 256.0),
	})
	c2.free()


func _armory() -> void:
	var pane: Control = ArmoryScene.instantiate() as Control
	pane.theme = HudTheme
	add_child(pane)
	await get_tree().process_frame
	await get_tree().process_frame
	var st: Resource = pane.call(&"style")
	_p("armory", {
		"block": pane.call(&"block_size"), "wells": pane.call(&"well_rects"),
		"bays": pane.call(&"bay_rects"),
		"style_block": st.block_size(), "canvas": st.canvas, "art_scale": st.art_scale,
		"pinned_wells": st.pinned_wells(),
		"plate": (pane.get_node_or_null("%ConsolePlate") as TextureRect).texture.resource_path
			if pane.get_node_or_null("%ConsolePlate") != null else "",
		"plate_size": (pane.get_node_or_null("%ConsolePlate") as TextureRect).size
			if pane.get_node_or_null("%ConsolePlate") != null else null,
		"plate_tex": (pane.get_node_or_null("%ConsolePlate") as TextureRect).texture.get_size()
			if pane.get_node_or_null("%ConsolePlate") != null else null,
		"plate_stretch": (pane.get_node_or_null("%ConsolePlate") as TextureRect).stretch_mode
			if pane.get_node_or_null("%ConsolePlate") != null else null,
		"body_size": (pane.get_node_or_null("%ArmoryBody") as Control).size
			if pane.get_node_or_null("%ArmoryBody") != null else null,
	})
	var figures: Array = []
	for cycle: float in [0.0, 0.6, 0.73, 1.2]:
		figures.append([cycle, pane.call(&"_salvo_figure", cycle)])
	_p("salvo_figure", figures)
	var strip: Variant = ArmoryPanelScript.SalvoStrip.new()
	strip.configure(st, _seg_textures(st), st.texture(st.seg_path(st.seg_blank_cell)))
	strip.set_figure(int(pane.call(&"_salvo_figure", 0.73)))
	var as_seven: String = strip.figure_text()
	var cells_seven: Array = strip.cells()
	strip.set_figure(int(pane.call(&"_salvo_figure", 0.0)))
	var blank_text: String = strip.figure_text()
	strip.free()
	_p("salvo_strip", {
		"073_text": as_seven, "073_cells": cells_seven, "blank_text": blank_text,
		"cell_size": st.drawn_rect(st.salvo_cell_rect(0)),
	})
	_p("armory_racks", pane.call(&"rack_rows"))
	pane.free()


func _seg_textures(st: Resource) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	for digit: int in 10:
		out.append(st.texture(st.seg_path(str(digit))))
	return out


func _find_marker_node(root: Node) -> Node:
	for child: Node in root.get_children():
		if child.has_method(&"marker_colours"):
			return child
	return null


## The Control size-clamp the status screen's `_place_render_box` depends on: a Control's
## `size` setter clamps up to `custom_minimum_size`, so setting size before lowering the
## minimum leaves the old size in force. Measured on a plain Control, not asserted.
func _clamp_demo() -> Dictionary:
	var probe := Control.new()
	probe.custom_minimum_size = Vector2(320.0, 320.0)
	probe.size = Vector2(244.0, 132.420837402344)
	var after_size := probe.size
	probe.custom_minimum_size = Vector2(244.0, 132.420837402344)
	var after_min := probe.size
	probe.free()
	return {"size_set_to_244": after_size, "after_min_lowered": after_min}


func _status() -> void:
	var st: Control = _hud.call(&"status_screen")
	st.call(&"set_hull", &"ship_vanguard")
	await get_tree().process_frame
	await get_tree().process_frame
	var s: Resource = st.call(&"style")
	var render: TextureRect = st.call(&"hull_render")
	var box: Control = render.get_parent()
	_p("status_render_diag", {
		"path": st.call(&"hull_render_path"),
		"exists": ResourceLoader.exists(st.call(&"hull_render_path")),
		"texture_null": render.texture == null,
		"native": render.texture.get_size() if render.texture != null else null,
		"box_min": box.custom_minimum_size,
		"box_size": box.size,
		"box_pos": box.position,
		"render_size": render.size,
		"area": s.status_render_area(),
		"box_right": box.position.x + box.size.x,
		"well_left_right": s.status_well_left.end.x,
		"well_right_left": s.status_well_right.position.x,
		"marker0": (st.call(&"hardpoint_markers") as Array)[0] if (st.call(&"hardpoint_markers") as Array).size() > 0 else null,
		"clamp_demo": _clamp_demo(),
	})
	var refs: Array = st.call(&"cell_refs")
	var first: Dictionary = refs[0] if not refs.is_empty() else {}
	_p("status_surface", {
		"modal": st.call(&"modal_size"), "wells": st.call(&"wells"),
		"plate_path": (st.call(&"plate") as TextureRect).texture.resource_path,
		"plate_class": (st.call(&"plate") as TextureRect).get_class(),
		"frame_path": (st.call(&"frame") as NinePatchRect).texture.resource_path,
		"frame_visible": (st.call(&"frame") as NinePatchRect).visible,
		"title": (st.call(&"title_label") as Label).text,
		"title_pos": (st.call(&"title_label") as Label).position,
		"close_rect": (st.call(&"close_button") as TextureButton).get_rect(),
	})
	_p("status_style", {
		"box": s.status_box, "well_left": s.status_well_left, "well_right": s.status_well_right,
		"footer": s.status_footer, "cell": s.status_cell_size, "pitch": s.status_cell_pitch,
		"cell_5x3_first": s.status_cell_rect(0, 0, 5, 3), "cell_5x3_last": s.status_cell_rect(4, 2, 5, 3),
		"grid_rect_5x3": s.status_grid_rect(5, 3), "grid_inner": s.status_grid_inner(),
		"render_area": s.status_render_area(), "marker_radius": s.status_marker_radius,
		"bone": s.bone, "danger": s.accent_danger,
	})
	_p("status_grid", {
		"matrix": st.call(&"grid_matrix"), "refs": refs.size(),
		"first_ref": first, "caption_rows": (st.call(&"module_rows") as Array).size(),
		"ref_font": (first["label"] as Label).get_theme_font_size(&"font_size") if not first.is_empty() else null,
		"ref_variation": (first["label"] as Label).theme_type_variation if not first.is_empty() else "",
	})
	var markers: Array = st.call(&"hardpoint_markers")
	var kinds: Dictionary = {}
	for m: Variant in markers:
		var k: String = String((m as Dictionary).get(&"kind", &"?"))
		kinds[k] = int(kinds.get(k, 0)) + 1
	var marker_node: Node = _find_marker_node(st.call(&"hull_render").get_parent())
	_p("status_markers", {
		"count": markers.size(), "kinds": kinds,
		"colours": marker_node.call(&"marker_colours") if marker_node != null else null,
		"radius": marker_node.call(&"marker_radius") if marker_node != null else null,
		"width": marker_node.call(&"marker_width") if marker_node != null else null,
		"parent": (st.call(&"hull_render") as Control).get_parent().name,
		"node": marker_node.name if marker_node != null else "",
	})
	_p("status_render_box", {
		"size": (st.call(&"hull_render") as Control).size,
		"path": st.call(&"hull_render_path"),
	})
	_p("status_footer", st.call(&"footer_lines"))
	var profile: Node = get_node_or_null(^"/root/PlayerProfile")
	if profile != null:
		var fit: Variant = profile.call(&"resolved_fit", &"ship_vanguard")
		var base: Variant = profile.call(&"base_fit", fit)
		var legal: Dictionary = ShipFit.fit_legal(&"ship_vanguard", base)
		_p("status_footer_expected", legal[&"power"])
	_p("status_style_drop_api", {
		"has_set_style_file": st.has_method(&"set_style_file"),
		"has_set_style": st.has_method(&"set_style"),
	})
