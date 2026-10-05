extends Node
## D22-P1 integrity probe, part 2 (evidence): the station shell, every deck, the
## drawer and the popup pair. Mounts the real station.tscn, selects each deck in
## turn, measures containment / zero-NaN rects, and checks the spec-pinned words.
## Sandboxes PlayerProfile (the gate idiom) so the owner's live account is untouched.
##
##   godot --headless --path vajb-orbit res://tests/probe_d22_integrity_station.tscn --quit-after 1200
##
## Prints [D22S] lines only.

const THEME_PATH := "res://ui/theme/vajb_theme.tres"
const STATION := "res://ui/screens/station.tscn"
const W := 1920.0
const H := 1080.0
const SCRATCH_DIR := "user://_d22_scratch"
const SCRATCH_PROFILE := "user://_d22_scratch/profile.cfg"

const OVERVIEW := 6
const SERVICES := 7
const DECK_NAMES := {
	6: "OVERVIEW", 0: "ARMORY", 1: "REFINERY", 2: "EXCHANGE",
	3: "AUCTION", 4: "SHIPYARD", 5: "LAUNCH", 7: "SERVICES",
}
const DECK_ORDER: Array[int] = [6, 0, 1, 2, 3, 4, 5, 7]

var _theme: Theme = null
var _station: Control = null
var _host: Control = null
var _fails := 0


func _ready() -> void:
	await get_tree().process_frame
	_sandbox()
	_theme = load(THEME_PATH) as Theme
	await _mount_station()
	if _station == null:
		print("[D22S] STATION MOUNT=FAIL")
		get_tree().quit(1)
		return
	for deck: int in DECK_ORDER:
		await _deck_report(deck)
	await _drawer_report()
	await _popup_report()
	await _popup_lifecycle()
	print("[D22S] %s %d" % ["PASS" if _fails == 0 else "FAIL", _fails])
	get_tree().quit(0)


func _sandbox() -> void:
	DirAccess.make_dir_recursive_absolute(SCRATCH_DIR)
	var profile := get_tree().root.get_node_or_null(NodePath("PlayerProfile"))
	if profile != null:
		profile.set(&"save_path", SCRATCH_PROFILE)
		profile.call(&"reset_to_defaults")
		profile.call(&"flush")


func _mount_station() -> void:
	_host = Control.new()
	_host.name = "Host"
	_host.theme = _theme
	_host.size = Vector2(W, H)
	_host.position = Vector2.ZERO
	add_child(_host)
	var packed := load(STATION) as PackedScene
	_station = packed.instantiate() as Control
	_host.add_child(_station)
	await _frames(30)
	var missing := _missing_unique(_station, STATION)
	print("[D22S] mount root=%s vis=%d uniq_missing=%d"
		% [_station.get_class(), _visible_controls(_station).size(), missing.size()])
	for t: String in missing:
		print("[D22S]   UNIQ-MISSING %%%s" % t)


func _deck_report(deck: int) -> void:
	_station.call(&"_select_module", deck, true)
	await _frames(6)
	var pane := _station.call(&"_panel_for", deck) as CanvasItem
	if pane == null:
		print("[D22S] %s pane=NULL" % DECK_NAMES[deck])
		return
	var bad := _measure(pane)
	var texts := _visible_texts(pane)
	var scene_path := (pane as Node).scene_file_path
	var missing: Array[String] = []
	if not scene_path.is_empty():
		missing = _missing_unique(pane, scene_path)
	print("[D22S] %s pane_rect=%s vis=%d zero=%d nan=%d out=%d clipped=%d texts=%d uniq_missing=%d"
		% [DECK_NAMES[deck], str((pane as Control).get_global_rect()), bad[&"vis"],
		bad[&"zero"].size(), bad[&"nan"].size(), bad[&"out"].size(), bad[&"clipped"].size(),
		texts.size(), missing.size()])
	for t: String in missing:
		print("[D22S]   %s UNIQ-MISSING %%%s" % [DECK_NAMES[deck], t])
	for t: String in bad[&"nan"]:
		print("[D22S]   %s NAN %s" % [DECK_NAMES[deck], t])
	for t: String in bad[&"zero"]:
		print("[D22S]   %s ZERO %s" % [DECK_NAMES[deck], t])
	for t: String in bad[&"out"]:
		print("[D22S]   %s OUT %s" % [DECK_NAMES[deck], t])
	print("[D22S]   %s TEXTS=%s" % [DECK_NAMES[deck], str(texts)])
	_word_checks(deck, texts)


func _word_checks(deck: int, texts: Array[String]) -> void:
	var joined := "\n".join(texts)
	match deck:
		OVERVIEW:
			_expect(deck, texts, "ARMORY")
			_expect(deck, texts, "REFINERY")
			_expect(deck, texts, "SHIPYARD")
			_expect(deck, texts, "LAUNCH")
			_expect_sub(deck, joined, "THE DOCK CLAMPS ARE CHEAP. THE AMMUNITION IS NOT.")
			_expect_sub(deck, joined, "BUY, FIT AND SWAP MODULES")
			_expect_sub(deck, joined, "PICK A TILE TO CHANGE DECKS")
		0:
			_expect_sub(deck, joined, "FIT CELLS")
			_expect_sub(deck, joined, "BATTERY CONFIG")
		1:
			_expect_sub(deck, joined, "QUEUE ALL")
			_expect_sub(deck, joined, "CANCEL")
			_expect_sub(deck, joined, "COLLECT ALL")
			_expect_sub(deck, joined, "UPGRADE (3,000 CR)")
		2:
			_expect_sub(deck, joined, "SELL")
			_expect_sub(deck, joined, "SELL ALL RAW")
		3:
			_expect_sub(deck, joined, "RESTOCK")
		4:
			_expect_sub(deck, joined, "REPAIR")
		5:
			_expect_sub(deck, joined, "LAUNCH")
		7:
			_expect_sub(deck, joined, "CONTRACTS")
			_expect_sub(deck, joined, "INSURANCE")
			_expect_sub(deck, joined, "VAULTS")


func _expect(deck: int, texts: Array[String], word: String) -> void:
	if not texts.has(word):
		_fails += 1
		print("[D22S]   WORD-FAIL %s missing exact '%s'" % [DECK_NAMES[deck], word])


func _expect_sub(deck: int, joined: String, word: String) -> void:
	if joined.find(word) == -1:
		_fails += 1
		print("[D22S]   WORD-FAIL %s missing '%s'" % [DECK_NAMES[deck], word])


func _drawer_report() -> void:
	_station.call(&"_open_drawer")
	await _frames(20)
	var drawer := _station.get_node_or_null("DrawerLayer/TerminalDrawer") as Control
	if drawer == null:
		print("[D22S] DRAWER=NULL")
		return
	# force the slide home in case the tween is mid-flight in headless
	var slide := drawer.get_node_or_null("DrawerLayout/DrawerPage/DrawerBody/DrawerSlide") as Control
	if slide != null:
		slide.position.x = 0.0
	await _frames(2)
	var bad := _measure(drawer)
	var texts := _visible_texts(drawer)
	print("[D22S] DRAWER vis=%d zero=%d nan=%d out=%d texts=%s"
		% [bad[&"vis"], bad[&"zero"].size(), bad[&"nan"].size(), bad[&"out"].size(), str(texts)])
	for t: String in bad[&"out"]:
		print("[D22S]   DRAWER OUT %s" % t)
	_expect(-1, texts, "OVERVIEW")
	_expect(-1, texts, "ARMORY")
	_expect(-1, texts, "LAUNCH")
	_expect(-1, texts, "LOG OUT")
	_station.call(&"_close_drawer", true)
	await _frames(4)
	if drawer.visible:
		_fails += 1
		print("[D22S]   DRAWER-STUCK still visible after close")
	else:
		print("[D22S] DRAWER close=clean")


func _popup_report() -> void:
	# tooltip component
	var tscene := load("res://ui/components/tooltip.tscn") as PackedScene
	var tooltip := tscene.instantiate() as Control
	_host.add_child(tooltip)
	await _frames(4)
	tooltip.call(&"show_for", "IRON ORE", "A DENSE, DULL METAL.", false,
		Vector2(1900.0, 1070.0), Vector2(W, H))
	await _frames(4)
	var tb := _measure(tooltip)
	var rt := String(tooltip.call(&"rendered_text"))
	print("[D22S] TOOLTIP open=%s rect=%s zero=%d nan=%d out=%d has_INSPECT=%s"
		% [str(tooltip.call(&"is_open")), str(tooltip.get_global_rect()),
		tb[&"zero"].size(), tb[&"nan"].size(), tb[&"out"].size(),
		str(rt.find("INSPECT") != -1)])
	for t: String in tb[&"out"]:
		print("[D22S]   TOOLTIP OUT %s" % t)
	tooltip.call(&"hide_tooltip")
	await _frames(2)
	print("[D22S] TOOLTIP close_open=%s" % str(tooltip.call(&"is_open")))
	tooltip.queue_free()
	await _frames(2)
	# inspect sheet component
	var sscene := load("res://ui/components/inspect_sheet.tscn") as PackedScene
	var sheet := sscene.instantiate() as Control
	_host.add_child(sheet)
	await _frames(4)
	sheet.call(&"open", {
		&"name": "IRON ORE", &"family": "ore", &"price": 12,
		&"stats": ["HARDNESS 4", "VALUE 12 CR"],
	})
	await _frames(12)
	var sb := _measure(sheet)
	print("[D22S] SHEET open=%s rect=%s zero=%d nan=%d out=%d rows=%d"
		% [str(sheet.call(&"is_open")), str(sheet.get_global_rect()),
		sb[&"zero"].size(), sb[&"nan"].size(), sb[&"out"].size(),
		(sheet.call(&"row_texts") as PackedStringArray).size()])
	for t: String in sb[&"out"]:
		print("[D22S]   SHEET OUT %s" % t)
	sheet.call(&"close")
	await _frames(12)
	print("[D22S] SHEET close_open=%s pending=%d" % [
		str(sheet.call(&"is_open")), int(sheet.call(&"pending_count"))])
	sheet.queue_free()
	await _frames(2)


func _popup_lifecycle() -> void:
	var sheet: Node = _station.get(&"_sheet")
	var tip: Node = _station.get(&"_tooltip")
	_station.call(&"open_sheet", {&"name": "TEST", &"family": "ore", &"price": 1, &"stats": ["A 1"]})
	await _frames(12)
	print("[D22S] STATION-SHEET open=%s" % str(sheet.call(&"is_open")))
	_station.call(&"_handle_cancel")
	await _frames(12)
	print("[D22S] STATION-SHEET after_esc_open=%s" % str(sheet.call(&"is_open")))
	_station.set(&"_hover_title", "IRON ORE")
	_station.set(&"_hover_body", "A DENSE METAL.")
	_station.call(&"_show_hover_tooltip")
	await _frames(2)
	print("[D22S] STATION-TOOLTIP open=%s" % str(tip.call(&"is_open")))
	_station.call(&"_hide_tooltip")
	await _frames(2)
	print("[D22S] STATION-TOOLTIP close_open=%s" % str(tip.call(&"is_open")))
	# the drawer opens while the sheet is up: ESC must close the sheet first (P19 order)
	_station.call(&"_open_drawer")
	await _frames(16)
	_station.call(&"open_sheet", {&"name": "TEST2", &"family": "ore", &"price": 2, &"stats": ["B 2"]})
	await _frames(12)
	print("[D22S] STATION-SHEET+DRAWER sheet_open=%s drawer_open=%s"
		% [str(sheet.call(&"is_open")), str(_station.call(&"is_drawer_open"))])
	_station.call(&"_handle_cancel")
	await _frames(12)
	print("[D22S] STATION-SHEET+DRAWER after_esc sheet=%s drawer=%s"
		% [str(sheet.call(&"is_open")), str(_station.call(&"is_drawer_open"))])
	_station.call(&"_handle_cancel")
	await _frames(16)
	print("[D22S] STATION-SHEET+DRAWER second_esc drawer=%s"
		% str(_station.call(&"is_drawer_open")))


func _measure(root_node: Node) -> Dictionary:
	var vis := 0
	var zero: Array[String] = []
	var nan: Array[String] = []
	var out: Array[String] = []
	var clipped: Array[String] = []
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
		## Effective visible box: intersect with every clipping ancestor (a ScrollContainer
		## clips its content, so scroll overflow is not a window escape).
		var eff := _effective_rect(ctl)
		if eff.size.x <= 0.0 or eff.size.y <= 0.0:
			clipped.append(tag)
			continue
		if eff.position.x < -1.0 or eff.position.y < -1.0 \
				or eff.end.x > W + 1.0 or eff.end.y > H + 1.0:
			out.append(tag)
	return {&"vis": vis, &"zero": zero, &"nan": nan, &"out": out, &"clipped": clipped}


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
	var text := FileAccess.get_file_as_string(path)
	var pending := ""
	for line: String in text.split("\n"):
		var trimmed := line.strip_edges()
		if trimmed.begins_with("[node name=\""):
			var start := trimmed.find("\"") + 1
			var end := trimmed.find("\"", start)
			pending = trimmed.substr(start, end - start)
		elif trimmed.begins_with("unique_name_in_owner = true") and not pending.is_empty():
			## The scene root's own unique mark is not reachable through `%` from itself,
			## and is legal; only a child's missing mark is a defect.
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


func _visible_controls(root_node: Node) -> Array[Node]:
	var out: Array[Node] = []
	for c: Node in _all_controls(root_node):
		var ctl := c as Control
		if ctl != null and ctl.is_visible_in_tree():
			out.append(ctl)
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
