extends Node
## F1 probe (P2-B proper fixer pass): the one cell action R1's MED-1 cure does not move.
##
## With the profile composing its candidate from the launch's fit, an install on a hull the
## account holds no fit for succeeds. A REMOVE of one of that hull's *delivered* cells is the
## other half: `clear_fit_slot` still reads the cell's module out of the stored fit (only a
## module the account's own fit holds may go back to the inventory), so a bare hull's delivered
## shield cell answers `false` while the pane, reading the launch's fit, offers REMOVE. This
## probe measures that pair, so the residual is a number rather than a reading.
##
## Bounded by the caller: `--quit-after 600`. The pane is the shipped scene with the shipped
## theme and the shipped autoload, borrowed the way the suites borrow it - the fields the
## fixture writes are handed back and the store is flushed on a scratch path, so neither the
## owner's profile nor the real economy log is touched (probe hygiene L17).
##
## Run:  godot --headless --path vajb-orbit res://tests/probe_f1_residual.tscn --quit-after 600

const PanelScene := preload("res://ui/station/fitting_panel.tscn")
const ThemeRes := preload("res://ui/theme/vajb_theme.tres")
const SCRATCH := "user://probe_f1_residual.cfg"
const HULL: StringName = &"ship_fighter"

var _profile: Node = null
var _previous_path := ""
var _previous_ship: StringName = &""
var _previous_fits: Dictionary = {}
var _previous_owned: Array = []
var _previous_modules: Dictionary = {}


func _ready() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	_profile = tree.root.get_node_or_null(NodePath(&"PlayerProfile"))
	if _profile == null:
		print("[F1-RESIDUAL] no PlayerProfile autoload")
		tree.quit(1)
		return
	_borrow()
	var host := Control.new()
	host.name = "ResidualHost"
	host.theme = ThemeRes
	host.size = Vector2(1920, 1080)
	## The runner's root is busy adding the probe scene itself, so the fixture host rides the
	## profile autoload, which entered the tree first (the suites' own reason).
	_profile.add_child(host)
	var panel: Control = PanelScene.instantiate()
	panel.name = "FittingPane"
	host.add_child(panel)
	print("[F1-RESIDUAL] launch fit shields=%s | stored fit shields=%s" % [
		str(_profile.call(&"resolved_fit", HULL)[&"shields"]),
		str(_profile.call(&"fit_for", HULL)[&"shields"]),
	])
	panel.call(&"select_cell", &"shields", 0)
	var offered: bool = panel.call(&"can_remove")
	var answered: bool = panel.call(&"remove_selected")
	print("[F1-RESIDUAL] the pane offers REMOVE=%s, answers=%s, footer=%s" % [
		str(offered),
		str(answered),
		str(panel.call(&"footer_text")),
	])
	print("[F1-RESIDUAL] the profile's own clear_fit_slot answers=%s" % str(
		_profile.call(&"clear_fit_slot", HULL, &"shields", 0)
	))
	host.free()
	_restore()
	print("[F1-RESIDUAL] done")
	tree.quit(0)


## The suites' own borrow: the fixture's fields are written on the shipped autoload and handed
## back afterwards, with the store flushed while the scratch path is still in place.
func _borrow() -> void:
	_previous_path = String(_profile.get(&"save_path"))
	_previous_ship = StringName(_profile.call(&"active_ship"))
	_previous_fits = _profile.call(&"fits")
	_previous_owned = _profile.call(&"owned_ships")
	_previous_modules = _profile.call(&"modules")
	_profile.set(&"save_path", SCRATCH)
	var owned: Array[StringName] = [HULL]
	_profile.set(&"_active_ship", HULL)
	_profile.set(&"_owned_ships", owned)
	_profile.set(&"_fits", {})
	_profile.set(&"_modules", {})


func _restore() -> void:
	_profile.set(&"_active_ship", _previous_ship)
	_profile.set(&"_fits", _previous_fits)
	_profile.set(&"_owned_ships", _previous_owned)
	_profile.set(&"_modules", _previous_modules)
	_profile.call(&"flush")
	_profile.set(&"save_path", _previous_path)
	var directory := DirAccess.open(SCRATCH.get_base_dir())
	if directory != null:
		directory.remove(SCRATCH.get_file())
