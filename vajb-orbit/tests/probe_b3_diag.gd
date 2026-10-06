extends SceneTree


func _initialize() -> void:
	var slot: Texture2D = load("res://assets/ui/ui_slot_weapon_normal.png")
	print("slot path=", slot.resource_path, " size=", slot.get_size())
	var caps: Texture2D = load("res://assets/ui/ui_bar_caps.png")
	print("caps path=", caps.resource_path, " size=", caps.get_size())
	var img: Image = caps.get_image()
	if img != null:
		var top := -1
		var bottom := -1
		for y in img.get_height():
			var hit := false
			for x in img.get_width():
				if img.get_pixel(x, y).a > 0.02:
					hit = true
					break
			if not hit:
				continue
			if top < 0:
				top = y
			bottom = y
		print("caps ink px=", bottom - top + 1)
	var hud: PackedScene = load("res://ui/hud/hud.tscn")
	if hud != null:
		var root: Node = hud.instantiate()
		var found: Array[Node] = []
		_find(root, "HullCapLeft", found)
		for n in found:
			var tr := n as TextureRect
			if tr != null:
				var t: Texture2D = tr.texture
				print("HullCapLeft tex=", "null" if t == null else t.resource_path,
						" texsize=", Vector2.ZERO if t == null else t.get_size(),
						" rect=", tr.size, " cmin=", tr.custom_minimum_size)
		root.free()
	quit(0)


func _find(node: Node, wanted: String, out: Array[Node]) -> void:
	if String(node.name) == wanted:
		out.append(node)
	for child in node.get_children():
		_find(child, wanted, out)
