## D7 bounded probe: measure the ARMORY pane's own rects headlessly.
extends SceneTree

const SCENE := "res://ui/station/armory_panel.tscn"

func _rect(node: Node) -> Dictionary:
	var c := node as Control
	if c == null:
		return {}
	var r := c.get_global_rect()
	return {"path": String(c.get_path()), "class": c.get_class(),
			"size": [r.size.x, r.size.y], "pos": [r.position.x, r.position.y],
			"min": [c.get_combined_minimum_size().x, c.get_combined_minimum_size().y]}

func _walk(node: Node, depth: int, out: Array) -> void:
	var c := node as Control
	if c != null and depth <= 6:
		out.append(_rect(c))
	for child in node.get_children():
		_walk(child, depth + 1, out)

func _initialize() -> void:
	var packed := load(SCENE) as PackedScene
	if packed == null:
		print("PROBE_FAIL no scene")
		quit(1)
		return
	var pane: Control = packed.instantiate()
	root.add_child(pane)
	await process_frame
	await process_frame
	await process_frame
	var min_size := pane.get_combined_minimum_size()
	var out: Array = []
	_walk(pane, 0, out)
	print("PROBE_PANE_MIN ", JSON.stringify([min_size.x, min_size.y]))
	print("PROBE_PANE_SIZE ", JSON.stringify([pane.size.x, pane.size.y]))
	for entry: Dictionary in out:
		print("PROBE_NODE ", JSON.stringify(entry))
	quit(0)
