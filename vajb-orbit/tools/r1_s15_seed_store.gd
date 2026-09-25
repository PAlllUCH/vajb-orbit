extends SceneTree
## S15-R1's AC3 store seeder: writes a pre-S15 v7 `user://profile.cfg` carrying a
## seven-group battery record and a full 7-cell capital fit, so the gate can be run
## against a store the S15 clamp must survive byte-identically.
##
##   XDG_DATA_HOME=<scratch> "$GODOT_CONSOLE" --headless --path "$VAJB_PROJ" \
##     --script res://tools/r1_s15_seed_store.gd

const FitData := preload("res://game/ship_fit.gd")

const CAPITAL: StringName = &"ship_destroyer"
const WEAPON_SLOT: StringName = &"weapons"
const SAVE_PATH := "user://profile.cfg"


func _init() -> void:
	var config := ConfigFile.new()
	config.set_value(&"profile", &"save_version", 7)
	config.set_value(&"profile", &"credits", 4321)
	config.set_value(&"profile", &"owned_ships", [String(CAPITAL)])
	config.set_value(&"profile", &"active_ship", String(CAPITAL))
	config.set_value(&"profile", &"modules", {})
	var fit: Dictionary = FitData.standard_fit(CAPITAL)
	var weapons: Array = []
	for index in 7:
		weapons.append("w_laser" if index % 2 == 0 else "w_cannon")
	fit[WEAPON_SLOT] = weapons
	config.set_value(&"profile", &"fits", {String(CAPITAL): fit})
	config.set_value(
		&"profile", &"batteries", {String(CAPITAL): [[0], [1], [2], [3], [4], [5], [6]]}
	)
	var err := config.save(SAVE_PATH)
	print("[S15R1] seeded %s err=%d" % [SAVE_PATH, err])
	quit(0 if err == OK else 1)
