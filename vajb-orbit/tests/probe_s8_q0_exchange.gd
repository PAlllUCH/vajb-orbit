extends Node
## S8-Q0 evidence probe (part 3): M2 and M3 - the Exchange confirm strip's name and the
## honored quote - measured on the shipped panel with the shipped `Exchange` functions.
##
## It gives the borrowed profile one chromium-ore stack, opens the shipped Exchange pane,
## selects the stack, and prints the strip's own text (name and quote) beside the hold row's
## name. Then it re-rolls the chromium demand between the preview and the press, presses SELL,
## and prints the credited delta beside what the strip promised.
##
## Run:  godot --headless --path vajb-orbit res://tests/probe_s8_q0_exchange.tscn --quit-after 1200
## Signal: the [S8Q0X] lines; the last line is `[S8Q0X] done`.

const PanelScene := preload("res://ui/station/exchange_panel.tscn")
const ExchangeScript := preload("res://game/exchange.gd")
const MineralScript := preload("res://game/mineral_catalog.gd")
const Clock := preload("res://autoload/world_clock.gd")

const SCRATCH_PROFILE := "user://probe_s8_q0_exchange.cfg"
const TAG := "[S8Q0X]"
const ORE: StringName = &"mineral_chromium"
const MINERAL: StringName = &"chromium"

var _profile: Node = null
var _previous_path := ""
var _previous_cargo: Dictionary = {}
var _previous_credits := 0
var _previous_market: Dictionary = {}


func _ready() -> void:
	_profile = get_tree().root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		print("%s FAIL no PlayerProfile autoload" % TAG)
		get_tree().quit(1)
		return
	_borrow()
	_profile.set(&"_cargo", {String(ORE): 1})
	_profile.call(&"add_credits", 6001 - int(_profile.call(&"credits")))
	_profile.set(&"_market", {
		"demand": {String(MINERAL): 1.0},
		"stock": {},
		"queue": {},
		"trend": {String(MINERAL): 1},
		"last_band": Clock.now(),
	})
	print("%s baseline(%s)=%d" % [TAG, ORE, ExchangeScript.baseline_of(ORE)])
	var panel := PanelScene.instantiate() as Control
	add_child(panel)
	panel.call(&"_select", ORE)
	await get_tree().process_frame
	var strip: Label = panel.get(&"_confirm_strip")
	print("%s hold row name  = %s" % [TAG, _hold_title(panel, ORE)])
	print("%s confirm strip  = %s" % [TAG, strip.text])
	var preview := ExchangeScript.quote(_profile, ORE, 1, Clock.now())
	print(
		"%s preview quote  = unit=%d gross=%d fee=%d paid=%d demand=%.2f"
		% [
			TAG,
			int(preview[&"unit"]),
			int(preview[&"gross"]),
			int(preview[&"fee"]),
			int(preview[&"paid"]),
			float(preview[&"demand"]),
		]
	)
	## M3: the market moves between the preview and the press. The demand is written
	## directly and `last_band` refreshed, so this is the market's own state change and not
	## a band drift the probe waited on.
	var credits_before := int(_profile.call(&"credits"))
	_profile.set(&"_market", {
		"demand": {String(MINERAL): 0.6},
		"stock": {},
		"queue": {},
		"trend": {String(MINERAL): -1},
		"last_band": Clock.now(),
	})
	panel.call(&"_on_sell_pressed")
	var credits_after := int(_profile.call(&"credits"))
	var after := ExchangeScript.quote(_profile, ORE, 1, Clock.now())
	print(
		"%s press quote    = unit=%d gross=%d fee=%d paid=%d demand=%.2f"
		% [
			TAG,
			int(after[&"unit"]),
			int(after[&"gross"]),
			int(after[&"fee"]),
			int(after[&"paid"]),
			float(after[&"demand"]),
		]
	)
	print(
		"%s credits %d -> %d credited=%d (strip promised paid=%d)"
		% [TAG, credits_before, credits_after, credits_after - credits_before, int(preview[&"paid"])]
	)
	print("%s strip after    = %s" % [TAG, strip.text])
	remove_child(panel)
	panel.free()
	_hand_back()
	print("%s done" % TAG)
	get_tree().quit(0)


## The hold row's own title for one item, read off the pane's hold payloads (the name the
## player sees in the list) rather than recomputed here.
func _hold_title(panel: Control, item_id: StringName) -> String:
	for payload: Variant in panel.get(&"_hold_payloads"):
		if payload is Dictionary and StringName((payload as Dictionary).get(&"id", &"")) == item_id:
			return String((payload as Dictionary).get(&"name", ""))
	return "?"


func _borrow() -> void:
	_previous_path = String(_profile.get(&"save_path"))
	_previous_cargo = (_profile.get(&"_cargo") as Dictionary).duplicate(true)
	_previous_credits = int(_profile.call(&"credits"))
	_previous_market = (_profile.get(&"_market") as Dictionary).duplicate(true)
	_profile.set(&"save_path", SCRATCH_PROFILE)
	_remove(SCRATCH_PROFILE)


func _hand_back() -> void:
	_profile.set(&"_cargo", _previous_cargo)
	_profile.call(&"add_credits", _previous_credits - int(_profile.call(&"credits")))
	_profile.set(&"_market", _previous_market)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	_remove(SCRATCH_PROFILE)
	print("%s scratch removed=%s" % [TAG, str(not FileAccess.file_exists(SCRATCH_PROFILE))])


func _remove(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())
