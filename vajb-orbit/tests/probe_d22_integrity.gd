extends Node
## D22-P1 integrity probe, part 1 (evidence for the screen-integrity review).
## Instantiates every routed screen headless and measures mount / containment /
## zero-NaN rects / visible control count. Sandboxes PlayerProfile first (the gate
## idiom) so the owner's live account is neither read nor written.
##
##   godot --headless --path vajb-orbit res://tests/probe_d22_integrity.tscn --quit-after 900
##
## Prints [D22] lines only.

const THEME_PATH := "res://ui/theme/vajb_theme.tres"
const W := 1920.0
const H := 1080.0
const SCRATCH_DIR := "user://_d22_scratch"
const SCRATCH_PROFILE := "user://_d22_scratch/profile.cfg"

const SCREENS: Array[String] = [
	"res://ui/screens/boot.tscn",
	"res://ui/screens/loading.tscn",
	"res://ui/screens/main_menu.tscn",
	"res://ui/screens/settings.tscn",
	"res://ui/screens/station.tscn",
	"res://ui/hud/hud.tscn",
	"res://ui/components/inspect_sheet.tscn",
	"res://ui/components/tooltip.tscn",
	"res://ui/dialogs/dialog.tscn",
	"res://ui/dialogs/quit_confirm.tscn",
]

var _theme: Theme = null


func _ready() -> void:
	await get_tree().process_frame
	_sandbox()
	_theme = load(THEME_PATH) as Theme
	print("[D22] viewport=%s" % str(get_viewport().get_visible_rect().size))
	for path: String in SCREENS:
		await _mount_report(path)
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
		print("[D22] %s MOUNT=FAIL (no PackedScene)" % path)
		return
	var host := Control.new()
	host.name = "Host"
	host.theme = _theme
	host.size = Vector2(W, H)
	host.position = Vector2.ZERO
	add_child(host)
	var inst := packed.instantiate()
	host.add_child(inst)
	await _frames(30)
	var controls := 0
	var zero: Array[String] = []
	var nan: Array[String] = []
	var outside: Array[String] = []
	for c: Node in _all_controls(inst):
		var ctl := c as Control
		if not ctl.is_visible_in_tree():
			continue
		controls += 1
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
		if eff.position.x < -1.0 or eff.position.y < -1.0 or eff.end.x > W + 1.0 or eff.end.y > H + 1.0:
			outside.append(tag)
	print("[D22] %s MOUNT=OK root=%s vis=%d zero=%d nan=%d outside=%d uniq_missing=%d"
		% [path, inst.get_class(), controls, zero.size(), nan.size(), outside.size(),
		_missing_unique(inst, path).size()])
	for t: String in nan:
		print("[D22]   NAN %s" % t)
	for t: String in zero:
		print("[D22]   ZERO %s" % t)
	for t: String in outside:
		print("[D22]   OUT %s" % t)
	host.queue_free()
	await _frames(2)


func _effective_rect(ctl: Control) -> Rect2:
	var r := ctl.get_global_rect()
	var p := ctl.get_parent()
	while p != null:
		var pc := p as Control
		if pc != null and pc.clip_contents:
			r = r.intersection(pc.get_global_rect())
		p = p.get_parent()
	return r


func _missing_unique(inst: Node, path: String) -> Array[String]:
	var out: Array[String] = []
	var pending := ""
	for line: String in FileAccess.get_file_as_string(path).split("\n"):
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
