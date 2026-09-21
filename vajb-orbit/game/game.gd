extends Node2D
## Flight scene: starfield, the player ship, the sector and the HUD wiring.
## Contract: docs/design/IMPLEMENTATION_PLAN.md sections 3.9, 3.10 and 4.6, with
## the section 9.9 engine-wave amendments: ENGINE_SPEC section 3 (hybrid flight,
## ESC cancels the order and the lock), section 7 (dock-zone prompt, safe warp),
## section 8 (sector population and blips) and section 9 (ShipFit owns the launch
## snapshot). It also owns the two cross-file seams the wave left open: the profile's
## cargo manifest is mirrored into PlayerState (`_sync_cargo`) and the mining reticle
## state is pushed from the shaft (`_push_reticle_state`). Retired by section 9.9:
## the MOCK_* constants, the mock shield/hull drain, the orbiting mock target and
## ESC docking.
## The HUD, the ship and the sector are preloaded by path (project convention, see
## _instantiate_hud): the scene must load while a parallel wave's file is still
## landing, and a headless caller and the editor agree on the same tables.

signal route_requested(route: StringName, params: Dictionary)

const Paths := preload("res://ui/paths.gd")
const PlayerStateScript := preload("res://game/player_state.gd")
const PlayerShipScene := preload("res://game/player_ship.tscn")
const PlayerShipScript := preload("res://game/player_ship.gd")
const SectorScript := preload("res://game/sector.gd")
const Registry := preload("res://game/sector_registry.gd")

const ROUTE_LOADING: StringName = &"loading"
const PARAM_DESTINATION: StringName = &"destination"
const PARAM_SECTOR: StringName = &"sector"
const DESTINATION_STATION: StringName = &"station"
const PROFILE_SERVICE: StringName = &"PlayerProfile"
## 01 section 7 / 02 section 7.5: the profile signal key that says the manifest moved.
const PROFILE_CARGO_KEY: StringName = &"cargo"

const HULL_ID_DEFAULT: StringName = &"ship_vanguard"
const SECTOR_ID_DEFAULT: StringName = &"sector_1"

const WEAPON_ACTIONS: Array[StringName] = [
	&"weapon_1",
	&"weapon_2",
	&"weapon_3",
	&"weapon_4",
	&"weapon_5",
]

const HUD_REFRESH_INTERVAL := 0.1
## IMPLEMENTATION_PLAN section 9.8 item 5: the interim sector label stays until
## the 11 section 1 roster is wired through the map screen (P2).
const SECTOR_NAME := "Helios Drift"
const MINIMAP_RADIUS_DEFAULT := 3200.0
const MINIMAP_RADIUS_STEP := 800.0
const MINIMAP_RADIUS_MIN := 800.0
const MINIMAP_RADIUS_MAX := 6400.0

## Section 9.8 item 4: mouse-wheel camera zoom, script-side so the input map stays
## untouched. Wheel up reads as zoom in, which is a larger Camera2D.zoom.
const CAMERA_ZOOM_STEP := 0.10
const CAMERA_ZOOM_MIN := 0.70
const CAMERA_ZOOM_MAX := 1.50
const CAMERA_ZOOM_SECONDS := 0.18

## The dock prompt (ENGINE_SPEC section 7) and the two input actions section 11
## adds. The actions are orchestrator-applied after this wave, so both are read
## behind `InputMap.has_action` guards.
const DOCK_PROMPT := "F · DOCK"
const INTERACT_ACTION: StringName = &"interact"
const WARP_ACTION: StringName = &"warp"
## ENGINE_SPEC section 13 `WARP_CHANNEL`.
const WARP_CHANNEL := 3.0

const HUD_METHODS: Array[StringName] = [
	&"bind",
	&"set_sector_name",
	&"set_minimap_scale",
	&"set_minimap_blips",
	&"set_target",
	&"set_target_info",
	&"clear_target",
	&"set_cargo_open",
]
const HUD_SIGNALS: Array[StringName] = [
	&"weapon_slot_selected",
	&"cargo_toggled",
	&"minimap_zoom_changed",
]

@onready var _camera: Camera2D = $Camera

var _state: PlayerStateScript
var _stats: ShipStats = null
var _ship: PlayerShipScript = null
var _sector: SectorScript = null
var _pending_spawn := Vector2.ZERO
var _sector_row_id: StringName = &""
var _sector_name := SECTOR_NAME
var _hud: Control = null
var _laser: Node = null
var _reticle_state: int = TargetReticle.State.PLAIN
var _weapon_index := 0
var _minimap_radius := MINIMAP_RADIUS_DEFAULT
var _cargo_open := false
var _camera_zoom := 1.0
var _camera_zoom_tween: Tween = null
var _hud_accumulator := 0.0
var _prompt := ""
var _warp_active := false
var _warp_elapsed := 0.0
var _warp_progress := -1.0


func _ready() -> void:
	_state = PlayerStateScript.new()
	_stats = _resolve_stats()
	_apply_ship_maxima()
	_state.setup()
	_seed_vitals()
	_hud = _instantiate_hud()
	_bind_hud()
	_connect_profile()
	_spawn_sector(_row_for(String(_sector_row_id)))
	_spawn_ship()
	_refresh_hud()


func _exit_tree() -> void:
	if _camera_zoom_tween != null and _camera_zoom_tween.is_valid():
		_camera_zoom_tween.kill()
	_disconnect_profile()


func _physics_process(delta: float) -> void:
	_update_weapon_input()
	_update_cargo_input()
	_update_cancel_input()
	_update_dock_prompt()
	_update_warp(delta)
	_push_reticle_state()
	_follow_ship()
	_hud_accumulator += delta
	if _hud_accumulator >= HUD_REFRESH_INTERVAL:
		_hud_accumulator = 0.0
		_refresh_hud()


## The loading bridge forwards the sector it is entering (loading.gd's `sector`
## key) after the scene is added, so a request for a different registry row
## re-populates here (11 section 1; a transition discards the left sector).
func on_route(params: Dictionary) -> void:
	var sector_key := String(params.get(PARAM_SECTOR, "")).strip_edges()
	if sector_key.is_empty():
		return
	var row := _row_for(sector_key)
	if not row.is_empty() and StringName(row[&"id"]) != _sector_row_id:
		_spawn_sector(row)
	_sector_name = String(row.get(&"name", sector_key))
	_push_sector_name()


## Section 9.8 item 4: the wheel zooms the flight camera. `_unhandled_input`, so a
## UI control that wants the wheel keeps it, and the input map is not touched.
func _unhandled_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button == null or not button.pressed:
		return
	if button.button_index == MOUSE_BUTTON_WHEEL_UP:
		_set_camera_zoom(_camera_zoom + CAMERA_ZOOM_STEP)
	elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_set_camera_zoom(_camera_zoom - CAMERA_ZOOM_STEP)


func _set_camera_zoom(target: float) -> void:
	_camera_zoom = clampf(target, CAMERA_ZOOM_MIN, CAMERA_ZOOM_MAX)
	if _camera_zoom_tween != null and _camera_zoom_tween.is_valid():
		_camera_zoom_tween.kill()
	_camera_zoom_tween = create_tween()
	_camera_zoom_tween.tween_property(
		_camera, "zoom", Vector2(_camera_zoom, _camera_zoom), CAMERA_ZOOM_SECONDS
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## ENGINE_SPEC section 9: the launch snapshot is the active hull plus the 09
## section 7 standard fit, resolved by ShipFit; PlayerState's maxima come from it,
## so armour, engines and computers are felt from the first module swap. P2's
## fitting UI supplies per-hull fits from the profile instead of the v1 default.
func _resolve_stats() -> ShipStats:
	var hull_id := HULL_ID_DEFAULT
	var profile := _profile()
	if profile != null:
		hull_id = StringName(profile.call(&"active_ship"))
	if not ShipFit.HULLS.has(hull_id):
		hull_id = HULL_ID_DEFAULT
	return ShipFit.resolve(hull_id, ShipFit.STANDARD_FIT)


## STATION_SPEC section 6 rule 5: the active hull owns the pool maxima. An unknown
## hull keeps PlayerState's defaults, which are the Cutter's. The reactor figures
## join in engine slice 0 (ENGINE_SPEC section 9): the snapshot is the one owner of
## `energy_max`/`energy_regen`/`fuel_max`, so a hull whose tank differs from the
## 100/200 base is felt from the first frame, and the station's refuel fills the
## same tank this seeds.
func _apply_ship_maxima() -> void:
	if _stats == null:
		return
	if _stats.hull_max > 0.0:
		_state.hull_max = _stats.hull_max
	if _stats.shield_max > 0.0:
		_state.shield_max = _stats.shield_max
	if _stats.cargo_max > 0:
		_state.cargo_max = _stats.cargo_max
	if _stats.energy_max > 0.0:
		_state.energy_max = _stats.energy_max
	if _stats.energy_regen > 0.0:
		_state.energy_regen = _stats.energy_regen
	if _stats.fuel_max > 0.0:
		_state.fuel_max = _stats.fuel_max


## Section 8: the sector populates on entry; W4's `populate` returns the player
## spawn point (300 u off the dock ring, ENGINE_SPEC section 13).
func _spawn_sector(row: Dictionary) -> void:
	if _sector == null:
		_sector = SectorScript.new()
		_sector.name = &"Sector"
		add_child(_sector)
	_sector_row_id = StringName(row.get(&"id", SECTOR_ID_DEFAULT))
	if _ship != null:
		_seat_ship(_sector.populate(row))
		return
	_pending_spawn = _sector.populate(row)


func _spawn_ship() -> void:
	_ship = PlayerShipScene.instantiate() as PlayerShipScript
	if _ship == null:
		push_warning("game: player_ship.tscn did not instantiate as a PlayerShip")
		return
	add_child(_ship)
	# The launched fit gates the W-slot mining laser (09 section 4.5): the v1
	# standard fit carries no `w_mining`, so a launch ship mounts no laser and `E`
	# mines nothing until the module is fitted.
	_ship.setup(_stats, _state, ShipFit.fitted_ids(ShipFit.STANDARD_FIT))
	_ship.damage_taken.connect(_on_ship_damage_taken)
	# The mount is part of `setup`, so the reference is resolved once here rather
	# than per frame: the reticle push reads the shaft's own range and target state
	# through it, and stays inert while the fit carries no laser.
	_laser = _ship.get_node_or_null(NodePath(PlayerShipScript.MINING_LASER_NODE))
	_seat_ship(_pending_spawn)


## Places the ship on the sector's spawn point and starts the follow camera there,
## so the first frame does not sweep in from the arena origin.
func _seat_ship(spawn: Vector2) -> void:
	if _ship == null:
		return
	_ship.global_position = spawn
	_camera.global_position = spawn
	_push_sector_name()


func _row_for(sector_key: String) -> Dictionary:
	if sector_key.is_empty():
		return Registry.sector(SECTOR_ID_DEFAULT)
	var by_id := Registry.sector(StringName(sector_key))
	if not by_id.is_empty():
		return by_id
	for row: Dictionary in Registry.SECTORS:
		if String(row.get(&"name", "")).nocasecmp_to(sector_key) == 0:
			return row
	return {}


## Section 3.1 / section 9.9: ESC cancels the fly-to order and the lock. Docking
## is the dock zone's `interact` prompt now, not a key.
func _update_cancel_input() -> void:
	if not Input.is_action_just_pressed(&"ui_cancel"):
		return
	if _ship != null:
		_ship.cancel_orders()
	if _hud != null:
		_hud.call(&"clear_target")


## Section 7: fly into the station's dock zone, read the prompt, press `interact`.
func _update_dock_prompt() -> void:
	var inside := _inside_dock_zone()
	_push_prompt(DOCK_PROMPT if inside else "")
	if not inside:
		return
	if InputMap.has_action(INTERACT_ACTION) and Input.is_action_just_pressed(INTERACT_ACTION):
		_request_dock()


## The dock zone is the sector's geometry (W4's `dock_zone_contains`); game.gd
## owns only the prompt and the route.
func _inside_dock_zone() -> bool:
	if _ship == null or _sector == null:
		return false
	if not _sector.has_method(&"dock_zone_contains"):
		return false
	return bool(_sector.call(&"dock_zone_contains", _ship.global_position))


## Section 7: docking files the damage report and routes through `loading` to the
## station. The connection guard keeps a standalone run (F6, a probe) inert
## instead of routing into nothing.
func _request_dock() -> void:
	if route_requested.get_connections().is_empty():
		return
	_file_damage_report()
	route_requested.emit(ROUTE_LOADING, {PARAM_DESTINATION: DESTINATION_STATION})


## Section 7: `warp` channels for WARP_CHANNEL seconds and lands docked. The gate
## is "no hostile engaged" (`_enemy_engaged`), no damage for 5 s (the ship's own
## query) and a station in the sector to land at.
func _update_warp(delta: float) -> void:
	if _warp_active:
		_warp_elapsed += delta
		if _warp_elapsed >= WARP_CHANNEL:
			_finish_warp()
			return
		_push_warp_channel(_warp_elapsed / WARP_CHANNEL)
		return
	if not _warp_ready():
		return
	if InputMap.has_action(WARP_ACTION) and Input.is_action_just_pressed(WARP_ACTION):
		_start_warp()


func _warp_ready() -> bool:
	if _ship == null or _sector == null:
		return false
	if _enemy_engaged():
		return false
	if not bool(_ship.call(&"warp_available")):
		return false
	return _sector.has_station()


## Section 5's aggro states do not exist yet (slice 2 ships the NPC brain), so
## nothing can be engaged. Slice 2 replaces the body with the "hostile in Alert or
## Engage, targeting the player" test of section 7.
func _enemy_engaged() -> bool:
	return false


func _start_warp() -> void:
	_warp_active = true
	_warp_elapsed = 0.0
	_push_warp_channel(0.0)


func _cancel_warp() -> void:
	if not _warp_active:
		return
	_warp_active = false
	_warp_elapsed = 0.0
	_push_warp_channel(0.0)


func _finish_warp() -> void:
	_cancel_warp()
	_request_dock()


## Section 7: the channel breaks on damage. The ship raises this from the hull and
## shield signals, so a hit fully absorbed by the shield breaks it too.
func _on_ship_damage_taken(_amount: float) -> void:
	_cancel_warp()


## The two section 9.9 HUD additions land with W5, so the calls are method-guarded
## and the pushed value is remembered (the HUD is addressed dynamically for the
## same cross-wave reason).
func _push_prompt(text: String) -> void:
	if text == _prompt:
		return
	_prompt = text
	if _hud != null and _hud.has_method(&"set_prompt"):
		_hud.call(&"set_prompt", text)


func _push_warp_channel(progress: float) -> void:
	if is_equal_approx(progress, _warp_progress):
		return
	_warp_progress = progress
	if _hud != null and _hud.has_method(&"set_warp_channel"):
		_hud.call(&"set_warp_channel", progress)


func _push_sector_name() -> void:
	if _hud == null:
		return
	_hud.call(&"set_sector_name", _sector_name)


## ENGINE_SPEC section 10 / IMPLEMENTATION_PLAN section 9.9: the mining reticle
## states, pushed every physics frame so the cursor reticle reads the trigger at
## input rate. `MINE_LASER_RANGE` (220 u) and the cycle live in `MiningLaser`, so
## `has_target()` already answers "the beam reaches the rock under the cursor" for
## the cursor's ray. Slice 1 ships the plain and mining states (section 14); slice 2
## replaces the reading with the targeting one (hostile, plus the selected weapon's
## range state). The value is mirrored so the HUD is only addressed on a change.
func _push_reticle_state() -> void:
	if _hud == null or not _hud.has_method(&"set_reticle_state"):
		return
	var state: int = TargetReticle.State.PLAIN
	if _laser != null and bool(_laser.call(&"is_active")):
		state = (
			TargetReticle.State.IN_RANGE
			if bool(_laser.call(&"has_target"))
			else TargetReticle.State.OUT_OF_RANGE
		)
	if state == _reticle_state:
		return
	_reticle_state = state
	_hud.call(&"set_reticle_state", state)


func _update_weapon_input() -> void:
	for slot in WEAPON_ACTIONS.size():
		if Input.is_action_just_pressed(WEAPON_ACTIONS[slot]):
			_select_weapon(slot)
	if Input.is_action_just_pressed(&"fire_primary"):
		_fire(_weapon_index)


func _update_cargo_input() -> void:
	if _hud == null or not Input.is_action_just_pressed(&"cargo_toggle"):
		return
	_hud.call(&"set_cargo_open", not _cargo_open)


func _follow_ship() -> void:
	if _ship == null:
		return
	_camera.global_position = _ship.global_position


## The profile is an autoload, so it is a child of /root; a bare ^"PlayerProfile"
## path would resolve against this node instead (STATION_SPEC section 1, see
## station.gd), so the lookup is anchored at the tree root and stays optional.
func _profile() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null(NodePath(PROFILE_SERVICE))


## The profile owns the cargo (17 section 5 rule 2) and the HUD reads PlayerState,
## so the manifest is mirrored across that one seam: on every cargo change (a
## pickup's collection, a sale, a refinery job) and on the 0.1 s HUD refresh.
func _connect_profile() -> void:
	var profile := _profile()
	if profile == null or not profile.has_signal(&"profile_changed"):
		return
	if not profile.is_connected(&"profile_changed", _on_profile_changed):
		profile.connect(&"profile_changed", _on_profile_changed)


func _disconnect_profile() -> void:
	var profile := _profile()
	if profile == null or not profile.has_signal(&"profile_changed"):
		return
	if profile.is_connected(&"profile_changed", _on_profile_changed):
		profile.disconnect(&"profile_changed", _on_profile_changed)


func _on_profile_changed(key: StringName) -> void:
	if key == PROFILE_CARGO_KEY:
		_sync_cargo()


## 02 section 1.2's hold fill, summed from the profile's manifest and handed to
## PlayerState, which is the only channel the HUD reads (section 3.9). Without this
## the cargo bar and the hold-full state stay at zero while the hold fills.
func _sync_cargo() -> void:
	if _state == null:
		return
	var profile := _profile()
	if profile == null:
		return
	var used := 0
	var items: Dictionary = profile.call(&"cargo_items")
	for quantity: Variant in items.values():
		used += int(quantity)
	if used == _state.cargo_used:
		return
	_state.set_cargo_used(used)


## 01 section 6: seed the live pools from the stored report, so a ship that was
## launched damaged comes back the way it left. No record means full pools.
## Fuel persists across the launch (ENGINE_SPEC section 12 item 13, section 4.4) and
## Energy does not — `setup` has already recomputed the buffer — so only a report
## that actually filed a tank moves this one: a pre-v3 record, or one a dock filed
## while the tank was never reported, leaves the launch-full tank alone instead of
## dropping the ship into Emergency Flight Mode with no fuel to fly on.
func _seed_vitals() -> void:
	var profile := _profile()
	if profile == null:
		return
	var stored: Variant = profile.call(&"vitals_of", profile.call(&"active_ship"))
	if not stored is Dictionary:
		return
	var record: Dictionary = stored
	if record.is_empty():
		return
	_state.set_hull(minf(float(record.get("hull", _state.hull_max)), _state.hull_max))
	_state.set_shield(minf(float(record.get("shield", _state.shield_max)), _state.shield_max))
	if record.has("fuel"):
		_state.set_fuel(minf(float(record["fuel"]), _state.fuel_max))


## 01 section 6 / ENGINE_SPEC section 12 item 13: the station's REPAIRS module reads
## the profile's vitals, so docking files the live state as this ship's damage report
## — hull and shield for the repair fee, the tank for the free refuel service, which
## is the same report and the same write.
func _file_damage_report() -> void:
	var profile := _profile()
	if profile == null:
		return
	profile.call(
		&"set_vitals",
		profile.call(&"active_ship"),
		int(_state.hull),
		int(_state.shield),
		int(round(_state.fuel)),
	)


func _refresh_hud() -> void:
	if _hud == null:
		return
	_sync_cargo()
	_push_pools()
	# String keys: the HUD minimap reads blip["pos"] / blip["kind"] (section 3.10).
	var blips: Array[Dictionary] = []
	if _ship != null:
		blips.append({"pos": _ship.global_position, "kind": &"self"})
	if _sector != null:
		blips.append_array(_sector.blips())
	_hud.call(&"set_minimap_blips", blips)


## ENGINE_SPEC section 10 / UI_SPEC section 3.1b: the Energy and Fuel bars and the
## Emergency Flight Mode banner. PlayerState is the single source (section 3.9), so
## the values are read from it here rather than mirrored in this scene; the calls are
## method-guarded and the HUD is addressed dynamically for the same cross-wave reason
## as the prompt strip and the warp bar (a HUD that predates slice 0 stays inert).
func _push_pools() -> void:
	if _hud == null or _state == null:
		return
	if _hud.has_method(&"set_pool"):
		_hud.call(&"set_pool", &"energy", _state.energy, _state.energy_max)
		_hud.call(&"set_pool", &"fuel", _state.fuel, _state.fuel_max)
	if _hud.has_method(&"set_emergency"):
		_hud.call(&"set_emergency", _state.emergency_mode)


func _select_weapon(slot: int) -> void:
	if slot < 0 or slot >= _state.ammo.size():
		return
	_weapon_index = slot
	_state.set_ammo(slot, _state.ammo[slot])


func _fire(slot: int) -> void:
	if slot < 0 or slot >= _state.ammo.size():
		return
	var remaining: int = _state.ammo[slot]
	if remaining <= 0:
		return
	_state.set_ammo(slot, remaining - 1)


func _bind_hud() -> void:
	if _hud == null:
		return
	_hud.call(&"bind", _state)
	_push_sector_name()
	_hud.call(&"set_minimap_scale", _minimap_radius)
	_hud.connect(&"weapon_slot_selected", _on_weapon_slot_selected)
	_hud.connect(&"cargo_toggled", _on_cargo_toggled)
	_hud.connect(&"minimap_zoom_changed", _on_minimap_zoom_changed)


func _instantiate_hud() -> Control:
	var hud_path := Paths.route_path(&"hud")
	if not ResourceLoader.exists(hud_path):
		push_warning("game: HUD scene %s is not available yet, running without a HUD" % hud_path)
		return null
	var packed := load(hud_path) as PackedScene
	if packed == null:
		push_warning("game: HUD scene %s did not load as a PackedScene, running without a HUD" % hud_path)
		return null
	var instance := packed.instantiate() as Control
	if instance == null or not _hud_api_ready(instance):
		push_warning("game: HUD instance from %s has no section 3.10 API, running without a HUD" % hud_path)
		if instance != null:
			instance.free()
		return null
	add_child(instance)
	# The game root is a Node2D, so Router.route() never hands the HUD the live theme.
	instance.theme = Router.live_theme()
	return instance


func _hud_api_ready(instance: Control) -> bool:
	for method in HUD_METHODS:
		if not instance.has_method(method):
			return false
	for hud_signal in HUD_SIGNALS:
		if not instance.has_signal(hud_signal):
			return false
	return true


func _on_weapon_slot_selected(slot: int) -> void:
	_select_weapon(slot)


func _on_cargo_toggled(open: bool) -> void:
	_cargo_open = open
	_refresh_hud()


func _on_minimap_zoom_changed(delta: int) -> void:
	_minimap_radius = clampf(
		_minimap_radius + float(delta) * MINIMAP_RADIUS_STEP,
		MINIMAP_RADIUS_MIN,
		MINIMAP_RADIUS_MAX,
	)
	_hud.call(&"set_minimap_scale", _minimap_radius)
