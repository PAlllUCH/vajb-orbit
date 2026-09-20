class_name UIPaths
extends RefCounted
## Single source for every res:// path the UI layer needs.
## Contract: docs/design/IMPLEMENTATION_PLAN.md section 3.1.

const THEME := "res://ui/theme/vajb_theme.tres"
const GRAIN := "res://ui/theme/grain.tres"

const ROUTES: Dictionary = {
	&"boot": "res://ui/screens/boot.tscn",
	&"main_menu": "res://ui/screens/main_menu.tscn",
	&"loading": "res://ui/screens/loading.tscn",
	&"station": "res://ui/screens/station.tscn",
	&"game": "res://game/game.tscn",
	&"settings": "res://ui/screens/settings.tscn",
	&"dialog": "res://ui/dialogs/dialog.tscn",
	&"quit_confirm": "res://ui/dialogs/quit_confirm.tscn",
	&"hud": "res://ui/hud/hud.tscn",
}

const SETTINGS_FILE := "user://settings.cfg"
const INPUTS_FILE := "user://inputs.cfg"

const AUDIO_DIRS: Dictionary = {
	&"ui": "res://assets/audio/ui/",
	&"sfx": "res://assets/audio/sfx/",
	&"music": "res://assets/audio/music/",
	&"ambience": "res://assets/audio/ambience/",
}

const AUDIO_BUSES: Array[StringName] = [&"Master", &"Music", &"SFX", &"UI"]
const AUDIO_SUB_BUSES: Dictionary = {
	&"SFXWeapon": &"SFX",
	&"SFXImpact": &"SFX",
	&"SFXWorld": &"SFX",
}

static func route_exists(route: StringName) -> bool:
	return ROUTES.has(route) and ResourceLoader.exists(ROUTES[route])

static func route_path(route: StringName) -> String:
	return ROUTES.get(route, "")
