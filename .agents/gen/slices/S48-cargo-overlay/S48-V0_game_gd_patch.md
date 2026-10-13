# S48-V0 — the prepared game.gd flight wiring (blocked by the dispatch's file set)

This session's `VAJB_WORKER_FILES` names `vajb-orbit/game.gd`; the repo file is
`vajb-orbit/game/game.gd`, so the `enforce_worker_files` hook refused every edit
(bucket 2: the pinned file set itself is wrong — escalate, never self-fix). The
brief's Hard constraints DO name `vajb-orbit/game/game.gd`, so the flight half is
law; these are the exact hunks, written against `game.gd` as of 2026-10-13
(post-S47), for the fixer whose declared set carries the right path. Every hunk
was derived from the measured seams in the brief; none is tested here — the fixer
lands the suite's flight rows below with them.

## Hunk 1 — the preload and the seat constant (after `DevTuningMenuScene`, game.gd:48)

old:
```
const DevTuningMenuScene := preload("res://ui/dev/dev_tuning_menu.tscn")
```
new:
```
const DevTuningMenuScene := preload("res://ui/dev/dev_tuning_menu.tscn")
## UI_SPEC section 18 A7: the flight seat of the C-key cargo overlay - the same
## read-only surface the station shell opens, hosted on this scene's own
## dialog-layer CanvasLayer (section 2.3's layer 20, above the HUD's layer 10).
const CargoOverlayScene := preload("res://ui/dialogs/cargo_overlay.tscn")
## Section 2.3's dialog layer: the overlay's seat over the HUD's own layer 10.
const OVERLAY_LAYER := 20
```

## Hunk 2 — the seat vars (game.gd:388-389, beside `_cargo_open`)

old:
```
var _jump_read_cache := ""
var _cargo_open := false
```
new:
```
var _jump_read_cache := ""
var _cargo_open := false
## The cargo overlay's flight seat (UI_SPEC section 18 A7): the layer-20 host and
## the overlay it carries.
var _cargo_overlay_layer: CanvasLayer = null
var _cargo_overlay: Control = null
```

## Hunk 3 — build the seat in `_ready` (game.gd:517-519)

old:
```
	_hud = _instantiate_hud()
	_bind_hud()
	_connect_profile()
```
new:
```
	_hud = _instantiate_hud()
	_bind_hud()
	_build_cargo_overlay()
	_connect_profile()
```

## Hunk 4 — the poll, the one driver, and the sync (replaces game.gd:1697-1700)

old:
```
func _update_cargo_input() -> void:
	if _hud == null or not Input.is_action_just_pressed(&"cargo_toggle"):
		return
	_hud.call(&"set_cargo_open", not _cargo_open)
```
new:
```
func _update_cargo_input() -> void:
	if not Input.is_action_just_pressed(&"cargo_toggle"):
		return
	_set_cargo_open(not _cargo_open)


## UI_SPEC section 18 A7: C toggles the read-only overlay over the live HUD; nothing
## is paused and the game keeps running under it. The mirror stays in step through
## this one writer, and the HUD's frozen setter keeps latching its own flag (its
## panel stays hidden) and emitting `cargo_toggled` exactly as before.
func _set_cargo_open(open: bool) -> void:
	if open == _cargo_open:
		return
	_cargo_open = open
	_sync_cargo_overlay(open)
	if _hud != null and _hud.has_method(&"set_cargo_open"):
		_hud.call(&"set_cargo_open", open)


func _sync_cargo_overlay(open: bool) -> void:
	if _cargo_overlay == null or not is_instance_valid(_cargo_overlay):
		return
	if open == bool(_cargo_overlay.call(&"is_open")):
		return
	if open:
		_cargo_overlay.call(&"open")
	else:
		_cargo_overlay.call(&"close")
```

## Hunk 5 — the ESC ladder's topmost step (game.gd:1040-1043)

old:
```
func _update_cancel_input() -> void:
	if not Input.is_action_just_pressed(&"ui_cancel"):
		return
	var deck_open := false
```
new:
```
func _update_cancel_input() -> void:
	if not Input.is_action_just_pressed(&"ui_cancel"):
		return
	## UI_SPEC section 18 A7: the cargo overlay's close is the one topmost step
	## before the map-deck step (P19's idiom).
	if _cargo_open:
		_set_cargo_open(false)
		return
	var deck_open := false
```

## Hunk 6 — the host builder (after `_on_cargo_toggled`, game.gd:2515-2517)

old:
```
func _on_cargo_toggled(open: bool) -> void:
	_cargo_open = open
	_refresh_hud()
```
new:
```
func _on_cargo_toggled(open: bool) -> void:
	_cargo_open = open
	_refresh_hud()


## The overlay's host: a layer-20 CanvasLayer this scene owns (section 2.3's dialog
## layer), built once in `_ready` so the seat exists with or without a HUD.
func _build_cargo_overlay() -> void:
	_cargo_overlay_layer = CanvasLayer.new()
	_cargo_overlay_layer.name = "CargoOverlayLayer"
	_cargo_overlay_layer.layer = OVERLAY_LAYER
	add_child(_cargo_overlay_layer)
	_cargo_overlay = CargoOverlayScene.instantiate() as Control
	if _cargo_overlay == null:
		return
	_cargo_overlay.name = "CargoOverlay"
	_cargo_overlay.theme = Router.live_theme()
	_cargo_overlay_layer.add_child(_cargo_overlay)
```

## The suite rows the fixer adds (acceptance items 6 and 7)

Mount `res://game/game.tscn` once in `suite_setup` the way
`test_engine2_wiring.gd` does (fixture fit `w_laser`/`w_cannon` on the active
hull, packs staged, hold freed of ammo items), then, per row:

- the seat: `game.get(&"_cargo_overlay_layer").layer == 20` and above the HUD's
  own CanvasLayer (hud.tscn:35 `layer = 10`); the overlay is a child of the game
  scene's host, not of the HUD.
- the poll drives it: `Input.action_press(&"cargo_toggle")` →
  `game.call(&"_update_cargo_input")` → overlay `is_open`, `_cargo_open` true,
  the HUD's `_cargo_open` true, `_cargo_panel` still hidden, `%CargoBlock`
  visible; release; press again → closed, mirror false.
- ESC is the one topmost step before the map-deck step: with the overlay open,
  `Input.action_press(&"ui_cancel")` → `game.call(&"_update_cancel_input")` →
  overlay closed and `map_deck_open()` still false.
- nothing pauses: `get_tree().paused == false` with the overlay open.
- the rows: the fixture's hold (ore/ingots/components/fuel cells) and the packs
  (`LASER MKII · 120 ROUNDS`) read as the station rows do, from the same overlay.
