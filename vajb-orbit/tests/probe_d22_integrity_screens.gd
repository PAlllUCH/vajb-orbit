extends Node
## D22-P1 integrity probe, part 3 (evidence): every non-station screen, the flight
## HUD (incl. the map deck) and the component set. Clipping-aware containment,
## zero/NaN rects, unstyled-button detection, interactive-sibling overlap, and a
## visible-text dump for the word checks. Sandboxes PlayerProfile (the gate idiom).
##
##   godot --headless --path vajb-orbit res://tests/probe_d22_integrity_screens.tscn --quit-after 1200
##
## Prints [D22C] lines only.

const THEME_PATH := "res://ui/theme/vajb_theme.tres"
const W := 1920.0
const H := 1080.0
const SCRATCH_DIR := "user://_d22_scratch"
const SCRATCH_PROFILE := "user://_d22_scratch/profile.cfg"

const SCENES: Array[String] = [
	"res://ui/screens/boot.tscn",
	"res://ui/screens/loading.tscn",
	"res://ui/screens/main_menu.tscn",
	"res://ui/screens/settings.tscn",
	"res://ui/hud/hud.tscn",
	"res://ui/dialogs/dialog.tscn",
	"res://ui/dialogs/quit_confirm.tscn",
	"res://ui/components/menu_button.tscn",
	"res://ui/components/slot_button.tscn",
	"res://ui/components/tooltip.tscn",
	"res://ui/components/inspect_sheet.tscn",
	"res://ui/screens/settings_rebind_row.tscn",
]

var _theme: Theme = null
var _host: Control = null


func _ready() -> void:
	await get_tree().process_frame
	_sandbox()
	_theme = load(THEME_PATH) as Theme
	_host = Control.new()
	_host.name = "Host"
	_host.theme = _theme
	_host.size = Vector2(W, H)
	_host.position = Vector2.ZERO
	add_child(_host)
	for path: String in SCENES:
		await _mount_report(path)
	await _hud_map_deck()
	get_tree().quit(0)


func _sandbox() -> void:
	DirAccess.make_dir_recursive_absolute(SCRATCH_DIR)
	var profile := get_tree().root.get_node_or_null(NodePath("PlayerProfile"))
	if profile != null:
		profile.set(&"save_path", SCRATCH_PROFILE)
		profile.call(&"reset_to_defaults")
		profile.call(&"flush")


func _mount_report(path: String) -> void:
	var packed := load(path) as PackedScene
	if packed == null:
		print("[D22C] %s MOUNT=FAIL" % path)
		return
	var inst := packed.instantiate() as Control
	_host.add_child(inst)
	await _frames(30)
	var m := _measure(inst)
	var unstyled := _unstyled_buttons(inst)
	var overlaps := _overlaps(inst)
	var texts := _visible_texts(inst)
	var missing := _missing_unique(inst, path)
	print("[D22C] %s MOUNT=OK vis=%d zero=%d nan=%d out=%d unstyled=%d overlap=%d uniq_missing=%d"
		% [path.get_file(), m[&"vis"], m[&"zero"].size(), m[&"nan"].size(),
		m[&"out"].size(), unstyled.size(), overlaps.size(), missing.size()])
	for t: String in missing:
		print("[D22C]   %s UNIQ-MISSING %%%s" % [path.get_file(), t])
	for t: String in m[&"nan"]:
		print("[D22C]   %s NAN %s" % [path.get_file(), t])
	for t: String in m[&"zero"]:
		print("[D22C]   %s ZERO %s" % [path.get_file(), t])
	for t: String in m[&"out"]:
		print("[D22C]   %s OUT %s" % [path.get_file(), t])
	for t: String in unstyled:
		print("[D22C]   %s UNSTYLED %s" % [path.get_file(), t])
	for t: String in overlaps:
		print("[D22C]   %s OVERLAP %s" % [path.get_file(), t])
	print("[D22C]   %s TEXTS=%s" % [path.get_file(), str(texts)])
	inst.queue_free()
	await _frames(2)


func _hud_map_deck() -> void:
	var packed := load("res://ui/hud/hud.tscn") as PackedScene
	var hud := packed.instantiate() as Control
	_host.add_child(hud)
	await _frames(20)
	hud.call(&"toggle_map_deck")
	await _frames(20)
	var deck := hud.call(&"map_deck") as Control
	print("[D22C] MAPDECK open=%s" % str(hud.call(&"map_deck_open")))
	if deck != null:
		var m := _measure(deck)
		var texts := _visible_texts(deck)
		print("[D22C] MAPDECK rect=%s vis=%d zero=%d nan=%d out=%d"
			% [str(deck.get_global_rect()), m[&"vis"], m[&"zero"].size(),
			m[&"nan"].size(), m[&"out"].size()])
		for t: String in m[&"out"]:
			print("[D22C]   MAPDECK OUT %s" % t)
		print("[D22C]   MAPDECK TEXTS=%s" % str(texts))
	hud.call(&"toggle_map_deck")
	await _frames(20)
	print("[D22C] MAPDECK close_open=%s" % str(hud.call(&"map_deck_open")))
	hud.queue_free()
	await _frames(2)


func _measure(root_node: Node) -> Dictionary:
	var vis := 0
	var zero: Array[String] = []
	var nan: Array[String] = []
	var out: Array[String] = []
	for c: Node in _all_controls(root_node):
		var ctl := c as Control
		if not ctl.is_visible_in_tree():
			continue
		vis += 1
		var r := ctl.get_global_rect()
		var tag := "%s %s" % [String(ctl.get_path()).replace("/Host/", "/"), str(r)]
		if is_nan(r.position.x) or is_nan(r.position.y) or is_nan(r.size.x) or is_nan(r.size.y):
			nan.append(tag)
			continue
		if r.size.x <= 0.0 or r.size.y <= 0.0:
			zero.append(tag)
			continue
		var eff := _effective_rect(ctl)
		if eff.size.x <= 0.0 or eff.size.y <= 0.0:
			continue
		if eff.position.x < -1.0 or eff.position.y < -1.0 \
				or eff.end.x > W + 1.0 or eff.end.y > H + 1.0:
			out.append(tag)
	return {&"vis": vis, &"zero": zero, &"nan": nan, &"out": out}


func _effective_rect(ctl: Control) -> Rect2:
	var r := ctl.get_global_rect()
	var p := ctl.get_parent()
	while p != null:
		var pc := p as Control
		if pc != null and pc.clip_contents:
			r = r.intersection(pc.get_global_rect())
		p = p.get_parent()
	return r


func _unstyled_buttons(root_node: Node) -> Array[String]:
	var out: Array[String] = []
	for c: Node in _all_controls(root_node):
		var btn := c as Button
		if btn == null or not btn.is_visible_in_tree():
			continue
		if btn is CheckButton or btn is OptionButton:
			continue
		if not btn.has_theme_stylebox(&"normal"):
			out.append("%s (no normal stylebox)" % String(btn.get_path()))
			continue
		var sb := btn.get_theme_stylebox(&"normal")
		if sb == null or sb is StyleBoxEmpty:
			out.append("%s (empty normal stylebox)" % String(btn.get_path()))
	return out


func _overlaps(root_node: Node) -> Array[String]:
	var out: Array[String] = []
	var parents: Dictionary = {}
	for c: Node in _all_controls(root_node):
		var ctl := c as Control
		if ctl == null or not ctl.is_visible_in_tree():
			continue
		if ctl.mouse_filter != Control.MOUSE_FILTER_STOP:
			continue
		if ctl.size.x <= 0.0 or ctl.size.y <= 0.0:
			continue
		var p := ctl.get_parent()
		if p == null:
			continue
		if not parents.has(p):
			parents[p] = []
		parents[p].append(ctl)
	for p: Node in parents:
		var list: Array = parents[p]
		for i in list.size():
			for j in range(i + 1, list.size()):
				var a: Control = list[i]
				var b: Control = list[j]
				var inter := a.get_global_rect().intersection(b.get_global_rect())
				if inter.size.x <= 4.0 or inter.size.y <= 4.0:
					continue
				var smaller := minf(a.size.x * a.size.y, b.size.x * b.size.y)
				if smaller <= 0.0:
					continue
				if inter.size.x * inter.size.y / smaller >= 0.5:
					out.append("%s <-> %s %s" % [String(a.get_path()), String(b.get_path()),
						str(inter)])
	return out


func _missing_unique(inst: Node, path: String) -> Array[String]:
	var out: Array[String] = []
	var text := FileAccess.get_file_as_string(path)
	var lines := text.split("\n")
	var pending := ""
	for line: String in lines:
		var trimmed := line.strip_edges()
		if trimmed.begins_with("[node name=\""):
			var start := trimmed.find("\"") + 1
			var end := trimmed.find("\"", start)
			pending = trimmed.substr(start, end - start)
		elif trimmed.begins_with("unique_name_in_owner = true") and not pending.is_empty():
			if pending != String(inst.name) and inst.get_node_or_null(NodePath("%" + pending)) == null:
				out.append(pending)
			pending = ""
	return out


func _visible_texts(root_node: Node) -> Array[String]:
	var out: Array[String] = []
	for c: Node in _all_controls(root_node):
		var ctl := c as Control
		if not ctl.is_visible_in_tree():
			continue
		if ctl is Label or ctl is Button or ctl is RichTextLabel:
			var t := String(ctl.get(&"text"))
			if not t.is_empty():
				out.append(t)
	return out


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _all_controls(root_node: Node) -> Array[Node]:
	var out: Array[Node] = []
	var stack: Array[Node] = [root_node]
	while stack.size() > 0:
		var n: Node = stack.pop_back()
		if n is Control:
			out.append(n)
		for ch: Node in n.get_children():
			stack.append(ch)
	return out
