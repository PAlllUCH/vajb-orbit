extends Node
## W5 reviewer probe: the `push_overlay` emit seam and the Router's public signature.
##
## W3's report records a near-miss: renaming the parameter `route` -> `route_name` in
## `Router.push_overlay` briefly left two reads of the retired name, which a clean parse
## accepts because a bare function name is a legal *Callable* expression. This probe
## measures the live emitted value's type (must be StringName, never Callable), the value
## a connected consumer receives, the route's type inside the overlay stack entry, the
## hazard itself (a bare function name in this class really is a Callable), and the full
## public signature of the Router's four entry points from `get_method_list()`.
##
## Run:  godot --headless --path vajb-orbit res://tests/probe_w5_overlay.tscn --quit-after 300
## Signal: the [W5-OVERLAY] lines; the last line is [W5-OVERLAY] done.

const OVERLAY_ROUTE: StringName = &"dialog"

var _emitted: Array = []
var _emitted_screen: Array = []


func _ready() -> void:
	await get_tree().process_frame
	var router := get_node_or_null(NodePath(&"/root/Router"))
	if router == null:
		print("[W5-OVERLAY] FAIL no Router autoload")
		get_tree().quit(1)
		return

	_signature(router, &"screen_changed")
	_signature(router, &"overlay_pushed")
	_signature(router, &"overlay_popped")
	_method(router, &"route")
	_method(router, &"push_overlay")
	_method(router, &"pop_overlay")
	_method(router, &"current_route")

	## The hazard W3 hit: `route` is also a method name, and a bare method name in this
	## class is a Callable, so `"%s" % route` / `emit(route)` would have been accepted.
	var method_callable: Variant = router.get(&"route")
	print("[W5-OVERLAY] bare `route` in Router resolves to type=%s (%s), is_callable=%s" % [
		type_string(typeof(method_callable)),
		method_callable,
		method_callable is Callable,
	])

	router.overlay_pushed.connect(_on_overlay_pushed)
	router.screen_changed.connect(_on_screen_changed)

	print("[W5-OVERLAY] route_exists(%s)=%s" % [
		OVERLAY_ROUTE,
		UIPaths.route_exists(OVERLAY_ROUTE),
	])

	## The dialog_manager call shape: `router.call(&"push_overlay", DIALOG_ROUTE, {...})`.
	router.call(&"push_overlay", OVERLAY_ROUTE, {})
	await get_tree().process_frame

	print("[W5-OVERLAY] overlay_pushed received %d signal(s): %s" % [_emitted.size(), _emitted])
	for value: Variant in _emitted:
		print("[W5-OVERLAY]   arg type=%s (%s) is_stringname=%s is_callable=%s equals_route=%s" % [
			type_string(typeof(value)),
			value,
			typeof(value) == TYPE_STRING_NAME,
			value is Callable,
			value == OVERLAY_ROUTE,
		])
	var depth: int = int(router.call(&"overlay_depth"))
	print("[W5-OVERLAY] overlay_depth=%d" % depth)
	var stack: Array = router.get(&"_overlays")
	if not stack.is_empty():
		var entry: Dictionary = stack[stack.size() - 1]
		var stored: Variant = entry[&"route"]
		print("[W5-OVERLAY] stack entry route type=%s (%s) is_stringname=%s" % [
			type_string(typeof(stored)),
			stored,
			typeof(stored) == TYPE_STRING_NAME,
		])
		var found: Node = router.call(&"_find_overlay", OVERLAY_ROUTE)
		print("[W5-OVERLAY] _find_overlay(%s) found=%s (dedupe read works)" % [
			OVERLAY_ROUTE,
			found != null,
		])

	router.call(&"pop_overlay")
	await get_tree().process_frame
	print("[W5-OVERLAY] after pop depth=%d" % int(router.call(&"overlay_depth")))

	print("[W5-OVERLAY] done")
	get_tree().quit(0)


func _on_overlay_pushed(route: Variant) -> void:
	_emitted.append(route)


func _on_screen_changed(route: Variant) -> void:
	_emitted_screen.append(route)


## Print a signal's declared argument list, as the engine sees it.
func _signature(node: Node, signal_name: StringName) -> void:
	for entry: Dictionary in node.get_signal_list():
		if entry.get("name", "") != signal_name:
			continue
		var args: Array = entry.get("args", [])
		var parts: Array[String] = []
		for arg: Dictionary in args:
			parts.append("%s:%s" % [
				arg.get("name", "?"),
				type_string(int(arg.get("type", 0))),
			])
		print("[W5-OVERLAY] signal %s(%s)" % [signal_name, ", ".join(parts)])
		return
	print("[W5-OVERLAY] signal %s MISSING" % signal_name)


## Print a method's parameter names, types and defaults, as the engine sees them.
func _method(node: Node, method_name: StringName) -> void:
	for entry: Dictionary in node.get_method_list():
		if entry.get("name", "") != method_name:
			continue
		var args: Array = entry.get("args", [])
		var defaults: Array = entry.get("default_args", [])
		var parts: Array[String] = []
		for index: int in args.size():
			var arg: Dictionary = args[index]
			var text := "%s:%s" % [arg.get("name", "?"), type_string(int(arg.get("type", 0)))]
			if index >= args.size() - defaults.size():
				text += " = %s" % [defaults[index - (args.size() - defaults.size())]]
			parts.append(text)
		print("[W5-OVERLAY] method %s(%s)" % [method_name, ", ".join(parts)])
		return
	print("[W5-OVERLAY] method %s MISSING" % method_name)
