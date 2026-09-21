extends Node
## Single owner of dialog lifecycle: requests are queued and shown one at a time
## through Router.push_overlay. Contract: docs/design/IMPLEMENTATION_PLAN.md section 3.5.

signal dialog_confirmed(id: StringName)
signal dialog_cancelled(id: StringName)

const DIALOG_ROUTE: StringName = &"dialog"
const RETRY_SECONDS := 0.1

var _queue: Array[Dictionary] = []
var _active: StringName = &""
var _visible := false
var _retry_timer: Timer


func _ready() -> void:
	_retry_timer = Timer.new()
	_retry_timer.name = &"RetryDelay"
	_retry_timer.one_shot = true
	_retry_timer.wait_time = RETRY_SECONDS
	_retry_timer.timeout.connect(_show_next)
	add_child(_retry_timer)


func confirm(
	id: StringName,
	title: String,
	body: String,
	confirm_text := "CONFIRM",
	cancel_text := "CANCEL"
) -> void:
	_enqueue(id, title, body, confirm_text, cancel_text)


func message(id: StringName, title: String, body: String, confirm_text := "OK") -> void:
	_enqueue(id, title, body, confirm_text, "")


func is_open() -> bool:
	return _active != &""


## Called by dialog.tscn once the player resolves the active dialog.
func resolved(id: StringName, confirmed: bool) -> void:
	if id != _active:
		return
	_finish(id, confirmed)


func _enqueue(id: StringName, title: String, body: String, confirm_text: String, cancel_text: String) -> void:
	if id == _active or _is_queued(id):
		return
	_queue.append({
		&"id": id,
		&"title": title,
		&"body": body,
		&"confirm_text": confirm_text,
		&"cancel_text": cancel_text,
	})
	_show_next()


func _show_next() -> void:
	var router := _service(&"Router")
	if router == null:
		return
	if _active != &"":
		if _visible and int(router.call(&"overlay_depth")) == 0:
			_finish(_active, false)
		else:
			return
	if _queue.is_empty():
		return
	if bool(router.call(&"is_busy")):
		_retry_timer.start()
		return
	var request: Dictionary = _queue.pop_front()
	_active = StringName(request[&"id"])
	var depth := int(router.call(&"overlay_depth"))
	router.call(&"push_overlay", DIALOG_ROUTE, {
		"id": request[&"id"],
		"title": request[&"title"],
		"body": request[&"body"],
		"confirm_text": request[&"confirm_text"],
		"cancel_text": request[&"cancel_text"],
	})
	_visible = int(router.call(&"overlay_depth")) > depth


func _finish(id: StringName, confirmed: bool) -> void:
	_active = &""
	_visible = false
	var router := _service(&"Router")
	if router != null:
		router.call(&"pop_overlay")
	if confirmed:
		dialog_confirmed.emit(id)
	else:
		dialog_cancelled.emit(id)
	_show_next()


func _is_queued(id: StringName) -> bool:
	for request: Dictionary in _queue:
		if request[&"id"] == id:
			return true
	return false


func _service(service_name: StringName) -> Node:
	## Autoload names are not resolvable identifiers until the project patch lands
	## (project.godot is applied by the orchestrator), so services are looked up by name.
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null(NodePath(service_name))
