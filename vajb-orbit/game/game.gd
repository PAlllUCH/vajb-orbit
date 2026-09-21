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
##
## Slice 2 (fight) adds the targeting and death wiring, all of it this scene's because
## every part of it spans two owners:
##   * the NPC hulls the sector spawns (§8) and their live blips;
##   * the timed lock channel of §4.1 (a click on a hostile inside `lock_range` starts
##     1.2 s of line of sight, rocks and hulls blocking) and its reticle ring;
##   * the target window's payload (§10: range state and threat) and the reticle reading
##     (in range / out of range / hostile);
##   * the two countermeasures' triggers (§4.6) and the hit marker (§4.2 item 4);
##   * the radial speedometer push (§10, UI_SPEC §3.6) and the chaff ghost blips (§4.6);
##   * the real safe-warp gate (§7) and the death flow (§7: cargo drops at the wreck,
##     respawn docked).
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
## The one module catalogue (W1, CONTRACTS section 11): reached by path like every
## other cross-file table here, because the HUD's slot cells carry a module's own icon
## path and the catalogue is the single owner of that rule.
const ModuleCatalogScript := preload("res://game/module_catalog.gd")

## Slice 2's cross-file reaches, by path (never by global class name: a `class_name`
## resolves only after the editor has scanned the project, and this scene must load in a
## headless run of a tree a parallel worker is still writing). Every one of them is a
## single-owner table read through its own API: the registry's rows and bands, the hull's
## published queries, the pipe's context arithmetic and the pickup's handshake.
const NpcRegistryScript := preload("res://game/npc_registry.gd")
const NpcShipScript := preload("res://game/npc_ship.gd")
const AsteroidScript := preload("res://game/asteroid.gd")
const DamageScript := preload("res://game/damage.gd")
const ImpactScript := preload("res://game/impact.gd")
const PickupScript := preload("res://game/pickup.gd")
const WeaponsScript := preload("res://game/weapons.gd")
const EconomyLogScript := preload("res://game/economy_log.gd")
## The screen-space speed fantasy and the hull-critical vignette (FX_SPEC section 5,
## section 6 row 1): one node owns the blur, the camera's applied zoom, the dust and the
## vignette, and this scene pushes it the single input it reads.
const SpeedFantasyScript := preload("res://game/speed_fantasy.gd")
const SPEED_FANTASY_NODE: StringName = &"SpeedFantasy"

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

## ENGINE_SPEC section 13, "Lock & countermeasures (rulings 21/22)": the lock channel's
## 1.2 s of uninterrupted line of sight, the passive radius the radar tags within, and
## the two countermeasure items the hold's stacks are spent by (section 4.6).
const LOCK_CHANNEL := 1.2
const PASSIVE_RADIUS := 1500.0
const CHAFF_ITEM: StringName = &"cm_chaff"
const FLARE_ITEM: StringName = &"cm_flare"

## Section 4.1: "rocks and hulls block it". The channel's ray therefore tests the rock
## layer and the hull layer - the same pair `weapons.gd` masks for its shots - read off
## their owners rather than restated (`Asteroid.COLLISION_LAYER`, `NpcShip.HULL_LAYER`).
const LOCK_LOS_MASK: int = AsteroidScript.COLLISION_LAYER | NpcShipScript.HULL_LAYER

## Section 11 names no key for either countermeasure (`interact`/`warp`/
## `consume_fuel_cell` are the three it adds), so the two triggers are read behind
## `InputMap.has_action` guards and these are the action names the orchestrator would
## bind. The mechanic ships either way: `WeaponComponent.use_countermeasure` is the seam
## a binding, a probe or a future panel reaches.
const COUNTERMEASURE_ACTIONS: Dictionary = {
	CHAFF_ITEM: &"countermeasure_chaff",
	FLARE_ITEM: &"countermeasure_flare",
}

## Section 11's `target_next` (Q in the shipped input map, section 3.1 "cycles locks").
const TARGET_NEXT_ACTION: StringName = &"target_next"

## Section 2.7 / decision 7: a death's cargo drops at the wreck with a 5-minute recovery
## window. `Pickup` owns a 60 s lifetime (section 13) and publishes no override, so the
## window is expressed through its own age clock; a `lifetime` argument on
## `Pickup.setup` is the clean fix (reported, slice 4).
const DROP_WINDOW := 300.0

## The group `PlayerShip` joins in `_ready` and both the pickups' tractor and the NPCs'
## early-warning checks resolve the player through (`Pickup.PLAYER_GROUP`,
## `NpcShip.PLAYER_GROUP`). The wreck leaves it on death (see `_switch_ship_off`).
const PLAYER_GROUP: StringName = &"player_ship"

## 01 section 7's log vocabulary, extended by the three events this scene adds: the packs
## filed on dock, the hold dropped at a wreck and the hull that was lost.
const EVENT_AMMO := "AMMO"
const EVENT_DROP := "DROP"
const EVENT_KILL := "KILL"

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
@onready var _speed_fantasy: SpeedFantasyScript = (
	get_node_or_null(NodePath(SPEED_FANTASY_NODE)) as SpeedFantasyScript
)

var _state: PlayerStateScript
var _stats: ShipStats = null
var _ship: PlayerShipScript = null

## The launch's own hull and fit (CONTRACTS section 11): `_resolve_stats` picks both
## once, and every reader of them - the snapshot, `PlayerState.set_weapons`, the
## ship's fit ids, the mount anchors and the HUD's slot cells - reads these, so a
## launch can never mix one hull's frame with another's fit.
var _launch_hull: StringName = HULL_ID_DEFAULT
var _launch_fit: Dictionary = {}
var _sector: SectorScript = null
var _pending_spawn := Vector2.ZERO
var _sector_row_id: StringName = &""
var _sector_name := SECTOR_NAME
var _hud: Control = null
var _laser: Node = null
var _guns: Node2D = null
var _reticle_state: int = TargetReticle.State.PLAIN
var _weapon_index := 0
var _minimap_radius := MINIMAP_RADIUS_DEFAULT
var _cargo_open := false
## The wheel's clamped target. `_camera_zoom_shown` is the same wheel value after the
## 0.18 s tween, and it is the one `speed_fantasy.gd` multiplies by the pull-back: this
## scene owns the target and the smoothing, the effects node owns the applied value, so
## neither ever writes the other's number and the pull-back never returns to the wheel.
var _camera_zoom := 1.0
var _camera_zoom_shown := 1.0
var _camera_zoom_tween: Tween = null
var _hud_accumulator := 0.0
var _prompt := ""
var _warp_active := false
var _warp_elapsed := 0.0
var _warp_progress := -1.0

## The marked signature (ENGINE_SPEC section 4.1): the hull a click is channelling at, or
## the one the lock landed on, or the one Q tagged from the passive radar. `_lock_elapsed`
## is the channel's clock, `_lock_channeling` says whether it is still running, and the
## landed lock itself stays the component's own answer (`WeaponComponent.lock_target`), so
## no second copy of it lives here.
var _lock_target: Node2D = null
var _lock_elapsed := 0.0
var _lock_channeling := false
var _lock_progress := -1.0
var _lock_progress_pushed := -2.0

## The target's pool total as it was the last time the window was pushed, so a drop is a
## confirmed hit (§4.2 item 4's marker). -1 means "no reading yet".
var _target_pools_seen := -1.0

## The packs as they were seeded at launch, **one entry per live weapon slot** in
## `PlayerState.weapons` order: the dock files the difference (section 4.3), so a store
## the launch could not load whole is never overwritten by a clamped live figure. Per
## slot rather than per family, because a fit may carry two of one family (a Lancer's
## two lasers): each slot files its own fired delta against the one pack the family
## owns, and the two deltas add up exactly as the packs' per-family rule requires.
var _ammo_seed: Array[int] = []

var _dead := false


func _ready() -> void:
	_state = PlayerStateScript.new()
	_stats = _resolve_stats()
	_apply_ship_maxima()
	## The launched fit's weapon list, before `setup` sizes the ammo arrays from it
	## (CONTRACTS section 11): the live slots are the hull's own W cells, not the five
	## fixed families a fitless `PlayerState` still defaults to.
	_state.set_weapons(_launch_weapons())
	_state.setup()
	_seed_vitals()
	_seed_ammo()
	_hud = _instantiate_hud()
	_bind_hud()
	_connect_profile()
	_state.died.connect(_on_ship_died)
	_spawn_sector(_row_for(String(_sector_row_id)))
	_spawn_ship()
	_bind_speed_fantasy()
	_refresh_hud()


func _exit_tree() -> void:
	if _camera_zoom_tween != null and _camera_zoom_tween.is_valid():
		_camera_zoom_tween.kill()
	_disconnect_profile()


func _physics_process(delta: float) -> void:
	if _dead:
		## Section 7's death flow replaces the ship; until the loading route lands the
		## wreck neither flies nor fires (the hull is switched off in `_on_ship_died`).
		return
	_update_weapon_input()
	_update_countermeasure_input()
	_update_target_input()
	_update_lock(delta)
	_update_cargo_input()
	_update_cancel_input()
	_update_dock_prompt()
	_update_warp(delta)
	_push_reticle_state()
	_push_speedometer()
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


## Section 9.8 item 4: the wheel zooms the flight camera, and section 3.1's LMB
## lock order rides the same handler (`_unhandled_input`, so a UI control that wants the
## click keeps it, and the input map is not touched).
##
## The target is clamped and the shown value is tweened to it, exactly as it was when the
## tween wrote `Camera2D.zoom` directly; what changed with the speed fantasy (2026-09-21)
## is only *who* writes the camera: `speed_fantasy.gd` applies
## `_camera_zoom_shown * pullback(ratio)`, so the pull-back stacks with the wheel instead
## of fighting it, and `Camera2D.zoom` has one writer.
func _set_camera_zoom(target: float) -> void:
	_camera_zoom = clampf(target, CAMERA_ZOOM_MIN, CAMERA_ZOOM_MAX)
	if _camera_zoom_tween != null and _camera_zoom_tween.is_valid():
		_camera_zoom_tween.kill()
	_camera_zoom_tween = create_tween()
	_camera_zoom_tween.tween_property(
		self, "_camera_zoom_shown", _camera_zoom, CAMERA_ZOOM_SECONDS
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## ENGINE_SPEC section 9: the launch snapshot is the active hull plus **that hull's
## own fit** - the profile's stored fit when the account holds one, 09 section 9's
## standard fit otherwise - resolved by ShipFit; PlayerState's maxima come from it,
## so armour, engines and computers are felt from the first module swap.
##
## Before this wave the launch resolved one global `ShipFit.STANDARD_FIT` (the
## Vanguard's row) for every hull, which is the measured root cause of a Lancer
## reporting five weapon families it does not mount (the owner's launch-fit gate).
## The flight scene only ever *reads* the profile: a hull with no fit launches on
## the standard fit and the fitting panel (P2-B) stays the one writer.
func _resolve_stats() -> ShipStats:
	var hull_id := HULL_ID_DEFAULT
	var profile := _profile()
	if profile != null:
		hull_id = StringName(profile.call(&"active_ship"))
	if not ShipFit.HULLS.has(hull_id):
		hull_id = HULL_ID_DEFAULT
	_launch_hull = hull_id
	_launch_fit = _launch_fit_for(hull_id, profile)
	return ShipFit.resolve(hull_id, _launch_fit)


## The fit this launch flies: the profile's own when it holds one, 09 section 9's
## `ShipFit.standard_fit(hull_id)` when the account has no fit for the hull (or holds
## only empty cells), and `{}` for a hull with no frame at all - which `_resolve_stats`
## has already replaced with the default hull. `standard_fit` returns `{}` only for a
## hull outside the nine player hulls, so the fallback is always a legal fit here.
func _launch_fit_for(hull_id: StringName, profile: Node) -> Dictionary:
	var stored := _profile_fit(hull_id, profile)
	if stored.is_empty():
		return ShipFit.standard_fit(hull_id)
	return stored


## One hull's stored fit in the shape `ShipFit.resolve` reads, or `{}` when the profile
## holds nothing usable for it. A fit stores a module *instance* id (15 section 6) and
## the resolver reads base ids, so every entry goes through
## `PlayerProfile.base_module_id`; `power` stays one id (CONTRACTS section 11 rule 1)
## and the seven list types keep the hull's padded array shape. `{}` comes back when
## the profile has no fit API, has no fit for the hull (a fresh account, an NPC id) or
## holds only empty cells - the three cases the standard fit is for.
func _profile_fit(hull_id: StringName, profile: Node) -> Dictionary:
	if profile == null or not profile.has_method(&"fit_for"):
		return {}
	var normalised: Dictionary = profile.call(&"fit_for", hull_id)
	if normalised.is_empty():
		return {}
	var fit: Dictionary = {}
	var holds_one := false
	for key: StringName in ShipFit.FIT_SLOT_KEYS:
		if key == &"power":
			var power := _base_module_id(StringName(str(normalised.get(key, ""))), profile)
			fit[key] = power
			holds_one = holds_one or power != &""
			continue
		var entries: Array[StringName] = []
		var raw: Variant = normalised.get(key, [])
		if raw is Array:
			for entry: Variant in raw:
				var base := _base_module_id(StringName(str(entry)), profile)
				entries.append(base)
				holds_one = holds_one or base != &""
		fit[key] = entries
	if not holds_one:
		return {}
	return fit


## The catalogue id behind one fit entry: an inventory instance id resolves through the
## profile, and a plain base id (every pre-v4 fixture, and every account that never
## bought a rolled module) comes back unchanged. A profile without the helper keeps the
## entry as it is rather than silently dropping a module from the fit.
func _base_module_id(entry: StringName, profile: Node) -> StringName:
	if entry == &"" or profile == null or not profile.has_method(&"base_module_id"):
		return entry
	return StringName(profile.call(&"base_module_id", entry))


## The launched fit's weapon ids mapped to families, one entry per **fitted** W cell in
## layout order (CONTRACTS section 11): the list `PlayerState` sizes its ammo to and
## the ids its `weapon_changed` announcements carry. The fit stores module ids
## (`w_laser`), while the ammo packs and the HUD's labels are keyed by family
## (`laser`), and `Weapons.weapon_id` is that one bridge. An unfitted cell
## contributes nothing, so a hull whose standard fit fills one of three W cells
## launches with one weapon slot and two empty cells; a fitted cell whose module has
## no firing family (`w_mining`, the tool that shares the W column) is a slot with no
## pack rather than a dropped cell, so the slot order still follows the fit.
func _launch_weapons() -> Array[StringName]:
	var ids: Array[StringName] = []
	var fitted: Array = _launch_fit.get(&"weapons", [])
	for entry: Variant in fitted:
		var module := StringName(str(entry))
		if module == &"":
			continue
		ids.append(WeaponsScript.weapon_id(module))
	return ids


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
	## Section 4.2 item 2: the shield's regeneration rate is the fit's own (base 2/s plus
	## the S module's `regen_add`, resolved by `ShipFit`), so a fitted shield recovers at
	## its real rate instead of `PlayerState`'s base default (W2 report, gap 3).
	if _stats.shield_regen > 0.0:
		_state.shield_regen = _stats.shield_regen


## Section 8: the sector populates on entry; W4's `populate` returns the player
## spawn point (300 u off the dock ring, ENGINE_SPEC section 13).
func _spawn_sector(row: Dictionary) -> void:
	if _sector == null:
		_sector = SectorScript.new()
		_sector.name = &"Sector"
		## Section 8's hulls are spawned *inside* `populate`, so the handler is bound
		## before the first population and stays bound across a transition.
		_sector.connect(&"npc_spawned", _on_npc_spawned)
		add_child(_sector)
	_sector_row_id = StringName(row.get(&"id", SECTOR_ID_DEFAULT))
	_cancel_lock()
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
	# The launched fit gates the W-slot mining laser (09 section 4.5): a fit that
	# carries no `w_mining` mounts no laser and `E` mines nothing until the module is
	# fitted. The fit is the active hull's own now, so a Lancer's two lasers and a
	# Delver's mining laser are the fit's own list rather than one global row.
	_ship.set_hull_id(_launch_hull)
	_ship.setup(_stats, _state, ShipFit.fitted_ids(_launch_fit))
	_ship.damage_taken.connect(_on_ship_damage_taken)
	# The mount is part of `setup`, so the reference is resolved once here rather
	# than per frame: the reticle push reads the shaft's own range and target state
	# through it, and stays inert while the fit carries no laser.
	_laser = _ship.get_node_or_null(NodePath(PlayerShipScript.MINING_LASER_NODE))
	# The weapons mount the same way (slice 2): the HUD's slots, the lock and the two
	# countermeasures all address the component, and it is absent on a fit that carries no
	# weapon module, exactly as the laser is absent without `w_mining`.
	_guns = _ship.get_node_or_null(NodePath(PlayerShipScript.WEAPONS_NODE))
	if _guns != null:
		_guns.connect(&"locks_broken", _on_locks_broken)
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
	_cancel_lock()
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
		## Section 7: the channel "breaks on damage or new aggro". Damage rides the ship's
		## own signal (`_on_ship_damage_taken`); new aggro is the gate above, re-read every
		## frame while the channel runs.
		if _enemy_engaged():
			_cancel_warp()
			return
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


## Section 7's "no hostile is engaged": a hostile signature (section 8's blip class, so
## pirates, swarmers and patrols count and a convoy does not) in Alert or Engage with the
## player as its target. `NpcShip.engaged_with` is the hull's own answer to exactly that
## question, so the gate reads the real brain state instead of guessing from a distance.
##
## The 5 s damage half of the gate is the ship's own query (`warp_available`,
## `WARP_DAMAGE_QUIET`) and is ANDed in `_warp_ready`.
func _enemy_engaged() -> bool:
	if _ship == null or not is_inside_tree():
		return false
	for node: Node in get_tree().get_nodes_in_group(NpcRegistryScript.GROUP):
		if node == null or not node.has_method(&"engaged_with"):
			continue
		if not _is_hostile(node):
			continue
		if bool(node.call(&"engaged_with", _ship)):
			return true
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


## ENGINE_SPEC section 10 / IMPLEMENTATION_PLAN section 9.9: the cursor reticle's
## reading, pushed every physics frame so it follows the cursor at input rate. Slice 2's
## order is targeting first, mining second: a hull under the cursor reads `HOSTILE` when
## section 8 calls it hostile and in/out of range otherwise (the selected weapon's range
## against the distance, section 10), and only with no hull under the cursor does the
## mining laser's own reading (`MINE_LASER_RANGE` 220 u and the cycle live in
## `MiningLaser`, so `has_target()` already answers "the beam reaches the rock under the
## cursor") still drive the box. The value is mirrored so the HUD is only addressed on a
## change.
func _push_reticle_state() -> void:
	if _hud == null or not _hud.has_method(&"set_reticle_state"):
		return
	var state := _reticle_state_for(_cursor_world_position())
	if state == _reticle_state:
		return
	_reticle_state = state
	_hud.call(&"set_reticle_state", state)


## The reticle reading for one world point, so a caller (the frame loop, a probe) can ask
## the question at a point of its own instead of only at the cursor.
func _reticle_state_for(world_point: Vector2) -> int:
	var hull := _pick_hull(world_point)
	if hull != null:
		if _is_hostile(hull):
			return TargetReticle.State.HOSTILE
		return (
			TargetReticle.State.IN_RANGE
			if _in_weapon_range(hull)
			else TargetReticle.State.OUT_OF_RANGE
		)
	if _laser != null and bool(_laser.call(&"is_active")):
		return (
			TargetReticle.State.IN_RANGE
			if bool(_laser.call(&"has_target"))
			else TargetReticle.State.OUT_OF_RANGE
		)
	return TargetReticle.State.PLAIN


## Section 4.3: `weapon_1..5` selects a group. The trigger itself is *not* read here any
## more: the mounted `WeaponComponent` samples `fire_primary` (held = fire the selected
## group) and owns the shot, its pack and its Energy draw, so the slice-1 placeholder that
## spent a round per key press is retired (it would double-spend against the real shot).
func _update_weapon_input() -> void:
	for slot in WEAPON_ACTIONS.size():
		if Input.is_action_just_pressed(WEAPON_ACTIONS[slot]):
			_select_weapon(slot)


## Section 4.6's two one-shot items. Section 11 binds no key for either, so both triggers
## are read behind `InputMap.has_action` guards and the mechanic ships through the seam
## (`WeaponComponent.use_countermeasure`), spend and all.
func _update_countermeasure_input() -> void:
	if _guns == null:
		return
	for item: StringName in COUNTERMEASURE_ACTIONS:
		var action: StringName = COUNTERMEASURE_ACTIONS[item]
		if not InputMap.has_action(action):
			continue
		if Input.is_action_just_pressed(action):
			_guns.call(&"use_countermeasure", item)


func _update_cargo_input() -> void:
	if _hud == null or not Input.is_action_just_pressed(&"cargo_toggle"):
		return
	_hud.call(&"set_cargo_open", not _cargo_open)


## --- Targeting: the lock channel and the target window (ENGINE_SPEC §4.1/§10) -----


## One hull under a world point, resolved from whatever body the point query returns (a
## hull's collider is its own `HullBody`, whose owner is the ship). Null when the point is
## empty space. Public in the sense that a probe or a future aiming mode may ask it; it
## reads nothing but the physics state.
func _pick_hull(world_point: Vector2) -> Node2D:
	if not is_inside_tree() or _ship == null:
		return null
	var space := get_world_2d().direct_space_state
	if space == null:
		return null
	var query := PhysicsPointQueryParameters2D.new()
	query.position = world_point
	query.collision_mask = NpcShipScript.HULL_LAYER
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var best: Node2D = null
	var best_distance := INF
	for hit: Dictionary in space.intersect_point(query, NpcShipScript.HULL_LAYER):
		var hull := _hull_of(hit.get("collider"))
		if hull == null:
			continue
		var distance := _ship.global_position.distance_to(hull.global_position)
		if distance < best_distance:
			best_distance = distance
			best = hull
	return best


## Section 4.1's "clicking a hostile inside lock range", so the pick is a hostile hull
## under the cursor and inside `ShipStats.lock_range` (the scanner's range, section 9,
## which is what gives `c_scanner` a combat job). Anything else - an empty point, a
## friendly hull, a hostile out of range - is not a lock order and falls through to the
## ship's own fly-to.
func _pick_lock_target(world_point: Vector2) -> Node2D:
	var hull := _pick_hull(world_point)
	if hull == null or not _is_hostile(hull):
		return null
	if _ship.global_position.distance_to(hull.global_position) > _lock_range():
		return null
	return hull


## The hull a collider belongs to: the collider itself when it is one (a future hull with
## a script), else its nearest ancestor in the NPC group.
func _hull_of(collider: Variant) -> Node2D:
	var node := collider as Node
	if node == null:
		return null
	var cursor: Node = node
	while cursor != null:
		if cursor.is_in_group(NpcRegistryScript.GROUP):
			return cursor as Node2D
		cursor = cursor.get_parent()
	return null


## Section 8's blip class for a hull, which is also what §7's warp gate and §4.1's lock
## order read: only a hostile signature is a lock target, so a convoy cannot be locked.
func _is_hostile(node: Node) -> bool:
	if node == null or not node.has_method(&"blip_kind"):
		return false
	return StringName(node.call(&"blip_kind")) == NpcRegistryScript.BLIP_HOSTILE


func _lock_range() -> float:
	return _stats.lock_range if _stats != null else 0.0


## The selected group's own range against the target's distance (§10's range state). A
## family with no range row (the mine is dropped, not aimed) has no envelope of its own,
## so it reads against the lock's range - the only range the weapon has.
func _in_weapon_range(target: Node2D) -> bool:
	if target == null or _ship == null:
		return false
	return _ship.global_position.distance_to(target.global_position) <= _weapon_range()


func _weapon_range() -> float:
	var reach := 0.0
	if _guns != null and _guns.has_method(&"selected_weapon"):
		reach = WeaponsScript.range_of(StringName(_guns.call(&"selected_weapon")))
	return reach if reach > 0.0 else _lock_range()


## Section 3.1: LMB on a hostile hull starts the channel instead of ordering a fly-to. The
## ship's own handler has already taken the click by the time this runs (it is a later
## child, and unhandled input walks the tree bottom-up), so a lock order cancels the
## order the same click placed - deferred, so the outcome does not depend on that order.
func _unhandled_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button == null or not button.pressed:
		return
	if button.button_index == MOUSE_BUTTON_LEFT:
		_on_left_click()
		return
	if button.button_index == MOUSE_BUTTON_WHEEL_UP:
		_set_camera_zoom(_camera_zoom + CAMERA_ZOOM_STEP)
	elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_set_camera_zoom(_camera_zoom - CAMERA_ZOOM_STEP)


func _on_left_click() -> void:
	if _dead:
		return
	var target := _pick_lock_target(_cursor_world_position())
	if target == null:
		return
	if _ship != null:
		_ship.call_deferred(&"cancel_orders")
	_start_lock(target)


## One frame of the lock channel (§4.1): 1.2 s of uninterrupted line of sight, restarted
## from zero by anything that breaks it, and the lock lands when the clock completes. A
## target that died, left the scanner's range or left the tree drops the lock entirely.
func _update_lock(delta: float) -> void:
	_prune_lock()
	if _lock_target == null or not _lock_channeling:
		return
	var target_position: Vector2 = _lock_target.global_position
	if not _in_lock_range(target_position) or not _lock_clear_line(target_position):
		_reset_lock_channel()
		return
	_lock_elapsed += delta
	_lock_progress = clampf(_lock_elapsed / LOCK_CHANNEL, 0.0, 1.0)
	_push_lock_progress()
	if _lock_elapsed >= LOCK_CHANNEL:
		_acquire_lock()


func _in_lock_range(target_position: Vector2) -> bool:
	return _ship != null and _ship.global_position.distance_to(target_position) <= _lock_range()


## "rocks and hulls block it": a ray from the hull to the target against the rock and hull
## layers, with both hulls' own bodies excluded (a hull does not block its own lock). An
## unobstructed ray is an empty hit.
func _lock_clear_line(target_position: Vector2) -> bool:
	if not is_inside_tree() or _ship == null:
		return false
	var space := get_world_2d().direct_space_state
	if space == null:
		return false
	var from: Vector2 = _ship.global_position
	var query := PhysicsRayQueryParameters2D.create(
		from, target_position, LOCK_LOS_MASK, _lock_exclusions()
	)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return space.intersect_ray(query).is_empty()


## Both hulls' collision bodies, so the ray tests the world between them and not the two
## endpoints: the ship's own body (a `HullBody` at its origin) and the target's.
func _lock_exclusions() -> Array[RID]:
	var out: Array[RID] = []
	for root: Node in [_ship, _lock_target]:
		if root == null:
			continue
		var stack: Array[Node] = [root]
		while not stack.is_empty():
			var node: Node = stack.pop_back()
			var body := node as CollisionObject2D
			if body != null and not body.is_queued_for_deletion():
				out.append(body.get_rid())
			for child: Node in node.get_children():
				stack.append(child)
	return out


## Section 4.1: the channel starts here, and section 4.6's chaff refuses it - "active locks
## break immediately and cannot re-acquire the real hull while ghosts live".
func _start_lock(target: Node2D) -> void:
	if _jamming():
		return
	_lock_target = target
	_lock_elapsed = 0.0
	_lock_channeling = true
	_lock_progress = 0.0
	if _guns != null and _guns.has_method(&"clear_lock_target"):
		_guns.call(&"clear_lock_target")
	_push_lock_progress()


## An interrupted channel restarts from zero ("uninterrupted line of sight"), but the mark
## stays: the player can re-acquire by holding the position, which is what the ring going
## dark under a rock is telling them.
func _reset_lock_channel() -> void:
	_lock_elapsed = 0.0
	_lock_progress = 0.0
	_push_lock_progress()


func _acquire_lock() -> void:
	_lock_channeling = false
	_lock_progress = 1.0
	_target_pools_seen = -1.0
	if _guns != null and _guns.has_method(&"set_lock_target"):
		_guns.call(&"set_lock_target", _lock_target)
	_push_lock_progress()


## ESC, a dead target, a broken lock and a sector transition all land here: the mark, the
## channel, the lock the seeker follows and the ring all clear together.
func _cancel_lock() -> void:
	_lock_target = null
	_lock_elapsed = 0.0
	_lock_channeling = false
	_lock_progress = -1.0
	_target_pools_seen = -1.0
	if _guns != null and _guns.has_method(&"clear_lock_target"):
		_guns.call(&"clear_lock_target")
	_push_lock_progress()


## §4.6: chaff breaks the lock the moment it fires; the component raises this and clears
## its own target, and the channel's owner does the same on its side.
func _on_locks_broken() -> void:
	_cancel_lock()


func _jamming() -> bool:
	return _guns != null and _guns.has_method(&"jamming") and bool(_guns.call(&"jamming"))


## A mark with no lock: Q cycles the passive radar's tags (§3.1's `target_next`, §4.1's
## "passive radar auto-tags signatures within `PASSIVE_RADIUS`"). A tag is a reading, not a
## lock - the ring and the seeker still need the channel.
func _update_target_input() -> void:
	if not InputMap.has_action(TARGET_NEXT_ACTION):
		return
	if not Input.is_action_just_pressed(TARGET_NEXT_ACTION):
		return
	_cycle_mark()


## Q's cycle: the nearest hostile signature that is not already the mark, wrapping back to
## the only contact when it is the only one. Nearest-first rather than list-order, so the
## cycle stays predictable while everything in the sector is moving.
func _cycle_mark() -> void:
	var signatures := _passive_signatures()
	if signatures.is_empty():
		_cancel_lock()
		return
	var nearest: Node2D = null
	var nearest_distance := INF
	for hull: Node2D in signatures:
		if hull == _lock_target:
			continue
		var distance: float = _ship.global_position.distance_to(hull.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = hull
	_mark(nearest if nearest != null else signatures[0])


## Every hostile signature inside `PASSIVE_RADIUS` (§4.1's passive radar).
func _passive_signatures() -> Array[Node2D]:
	var out: Array[Node2D] = []
	if _ship == null or not is_inside_tree():
		return out
	for node: Node in get_tree().get_nodes_in_group(NpcRegistryScript.GROUP):
		var hull := node as Node2D
		if hull == null or not _is_hostile(hull):
			continue
		if _ship.global_position.distance_to(hull.global_position) <= PASSIVE_RADIUS:
			out.append(hull)
	return out


func _mark(target: Node2D) -> void:
	_lock_target = target
	_lock_elapsed = 0.0
	_lock_channeling = false
	_lock_progress = -1.0
	_target_pools_seen = -1.0
	if _guns != null and _guns.has_method(&"clear_lock_target"):
		_guns.call(&"clear_lock_target")
	_push_lock_progress()


## A target that died, left the tree or left the scanner's range is no target (§4.1's lock
## is dropped when the contact is lost).
func _prune_lock() -> void:
	if _lock_target == null:
		return
	if not is_instance_valid(_lock_target):
		_cancel_lock()
		return
	if _lock_target.has_method(&"is_alive") and not bool(_lock_target.call(&"is_alive")):
		_cancel_lock()
		return
	if not _in_lock_range(_lock_target.global_position):
		_cancel_lock()


func _push_lock_progress() -> void:
	if _hud == null or not _hud.has_method(&"set_lock_progress"):
		return
	if is_equal_approx(_lock_progress, _lock_progress_pushed):
		return
	_lock_progress_pushed = _lock_progress
	_hud.call(&"set_lock_progress", _lock_progress)


## §10's target window: the marked hull's name (08 §2's own hull name where the hull has a
## row), its two pools as fractions, the distance, §10's range state and §8's threat class.
## The pushed reading is also where a confirmed hit is noticed (§4.2 item 4's marker): the
## marked target's pools only ever move down on a hit or up on regeneration, so a drop
## between two pushes is a hit that landed.
func _push_target() -> void:
	if _hud == null:
		return
	if _lock_target == null or not is_instance_valid(_lock_target):
		_hud.call(&"clear_target")
		_target_pools_seen = -1.0
		return
	var hull := _hull_read(_lock_target, &"hull")
	var shield := _hull_read(_lock_target, &"shield")
	var hull_max := maxf(_hull_read(_lock_target, &"hull_max"), 0.0)
	var shield_max := maxf(_hull_read(_lock_target, &"shield_max"), 0.0)
	var distance: float = _ship.global_position.distance_to(_lock_target.global_position)
	_hud.call(
		&"set_target",
		_screen_position_of(_lock_target.global_position),
		clampf(hull / hull_max, 0.0, 1.0) if hull_max > 0.0 else 0.0
	)
	_hud.call(
		&"set_target_info",
		{
			"name": _target_name(_lock_target),
			"hull": clampf(hull / hull_max, 0.0, 1.0) if hull_max > 0.0 else 0.0,
			"shield": clampf(shield / shield_max, 0.0, 1.0) if shield_max > 0.0 else 0.0,
			"distance_m": distance,
			"in_range": _in_weapon_range(_lock_target),
			"threat": _threat_reading(_lock_target),
		}
	)
	var pools := hull + shield
	if _target_pools_seen >= 0.0 and pools < _target_pools_seen - 0.0001:
		_hud.call(&"hit_marker")
	_target_pools_seen = pools


## 08 §2's hull name ("Lancer", "Vanguard", ...) for the hull the target flies, falling back
## to the archetype's own id where the hull has no class row (W3's D9: the turret platform).
func _target_name(target: Node2D) -> String:
	if target.has_method(&"hull_id"):
		var row: Dictionary = ShipFit.HULLS.get(StringName(target.call(&"hull_id")), {})
		var hull_name := String(row.get(&"name", ""))
		if not hull_name.is_empty():
			return hull_name
	if target.has_method(&"archetype"):
		return String(target.call(&"archetype")).to_upper()
	return ""


func _threat_reading(target: Node2D) -> StringName:
	if target.has_method(&"blip_kind"):
		return StringName(target.call(&"blip_kind"))
	return &""


func _hull_read(target: Node2D, method: StringName) -> float:
	if not target.has_method(method):
		return 0.0
	return float(target.call(method))


## Where a world point lands on screen, for the reticle's marked-target position
## (`set_target`): the viewport's canvas transform is the camera's own world-to-viewport
## mapping, so the reticle stays on the hull at every zoom.
func _screen_position_of(world_position: Vector2) -> Vector2:
	var viewport := get_viewport()
	if viewport == null:
		return world_position
	return viewport.get_canvas_transform() * world_position


func _cursor_world_position() -> Vector2:
	if _ship != null:
		return _ship.get_global_mouse_position()
	return get_global_mouse_position()


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
## is the same report and the same write. The packs are filed in the same breath
## (section 4.3), so one dock event settles everything the flight scene owns.
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
	_file_ammo_report()


## Section 4.3 / 01 section 6: the packs are profile-owned, `PlayerState` seeds them at
## launch and the *deltas* go back on dock. The seed is remembered in `_ammo_seed`, so a
## store the launch's own ceiling could not load whole is never overwritten by a clamped
## live figure - the filing only ever spends what was actually fired.
##
## `PlayerProfile` publishes no writer for a pack today (it owns `ammo_of`/`ammo_max`/
## `buy_ammo`, and `buy_ammo` only ever adds, while a fired delta is always a subtraction),
## so the write rides a guarded `set_ammo` and the missing method is reported as the one
## line this closes with; until then the seam is inert and the packs keep the behaviour
## they ship with today (reseeded to `AMMO_DEFAULT` at every launch).
func _file_ammo_report() -> void:
	var profile := _profile()
	if profile == null or _state == null:
		return
	if not profile.has_method(&"set_ammo"):
		return
	for slot in _state.weapons.size():
		if slot >= _ammo_seed.size():
			continue
		var weapon_id: StringName = _state.weapons[slot]
		var seeded := _ammo_seed[slot]
		var live: int = _state.ammo[slot]
		var fired := seeded - live
		if fired <= 0:
			continue
		var stored := int(profile.call(&"ammo_of", weapon_id))
		profile.call(&"set_ammo", weapon_id, maxi(stored - fired, 0))
		_ammo_seed[slot] = live
		EconomyLogScript.append(
			EVENT_AMMO, weapon_id, fired, 0, int(profile.call(&"credits"))
		)


## The other half of the same pattern: the launch loads each slot from the profile's own
## store (which owns the packs, section 4.3), clamped by `PlayerState`'s per-slot ceiling,
## and records what it loaded so the dock can tell a fired round from a ceiling. The slots
## are the launched fit's own (`weapons`), so a hull that mounts two lasers seeds both
## from the one `laser` pack and a hull that mounts none seeds nothing.
func _seed_ammo() -> void:
	var profile := _profile()
	if profile == null or _state == null:
		return
	_ammo_seed.clear()
	for slot in _state.weapons.size():
		var weapon_id: StringName = _state.weapons[slot]
		_state.set_ammo(slot, int(profile.call(&"ammo_of", weapon_id)))
		_ammo_seed.append(_state.ammo[slot])


func _refresh_hud() -> void:
	if _hud == null:
		return
	_sync_cargo()
	_push_pools()
	_push_target()
	# String keys: the HUD minimap reads blip["pos"] / blip["kind"] (section 3.10).
	var blips: Array[Dictionary] = []
	if _ship != null:
		blips.append({"pos": _ship.global_position, "kind": &"self"})
	if _sector != null:
		blips.append_array(_sector.blips())
	blips.append_array(_ghost_blips())
	_hud.call(&"set_minimap_blips", blips)


## Section 4.6 / UI_SPEC section 3.3: the chaff's ghost signatures ride the minimap as
## their own blip kind while the component keeps them alive (3.0 s), so the blip count and
## the window cannot disagree with the lock rule - both read the component's list. (The
## kind's 6 Hz alpha flicker is the minimap's draw and is reported: `ui/hud/minimap.gd` is
## outside this worker's file set.)
func _ghost_blips() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _guns == null or not _guns.has_method(&"ghosts"):
		return out
	for ghost: Variant in _guns.call(&"ghosts"):
		var node := ghost as Node2D
		if node == null or not is_instance_valid(node):
			continue
		out.append({"pos": node.global_position, "kind": &"ghost"})
	return out


## ENGINE_SPEC section 10 / UI_SPEC section 3.6: the radial speedometer. The ratio is the
## hull's live speed against its class maximum (`ShipStats.max_speed`, the same figure the
## flight law reads), the prograde leg is the actual velocity vector and the heading leg is
## the nose, so the dial needs no second opinion about either - the HUD takes the angles.
##
## That one ratio is engine spec section 3.4's single input, so it is computed here and
## nowhere else, and the three readers all take this frame's value: the screen-space stack
## (blur, pull-back, dust), the hull's own thruster driver (trail and bed) and the dial.
func _push_speedometer() -> void:
	if _ship == null or _stats == null:
		return
	var velocity: Vector2 = _ship.velocity()
	var maximum: float = _stats.max_speed
	var ratio := 0.0
	if maximum > 0.0:
		ratio = clampf(velocity.length() / maximum, 0.0, 1.0)
	_push_speed_fantasy(ratio, velocity)
	if _ship.has_method(&"set_speed_ratio"):
		_ship.call(&"set_speed_ratio", ratio)
	if _hud == null or not _hud.has_method(&"set_speedometer"):
		return
	_hud.call(&"set_speedometer", ratio, velocity, Vector2.RIGHT.rotated(_ship.global_rotation))


## The screen-space stack's own push: the wheel's shown value, the frame's ratio and the
## hull's fraction. FX_SPEC section 6: the damage states key off `PlayerState`'s pools, so
## the fraction comes from the same state the HUD's hull bar reads.
func _push_speed_fantasy(ratio: float, velocity: Vector2) -> void:
	if _speed_fantasy == null:
		return
	_speed_fantasy.set_wheel_zoom(_camera_zoom_shown)
	_speed_fantasy.set_ratio(ratio, velocity)
	_speed_fantasy.set_hull_fraction(_hull_fraction())


## The flight camera and the screen-space stack meet here: the dust emitter is parented to
## the camera (FX_SPEC section 5 row 3), and the camera's zoom has exactly one writer.
func _bind_speed_fantasy() -> void:
	if _speed_fantasy == null:
		return
	_speed_fantasy.bind_camera(_camera)


func _hull_fraction() -> float:
	if _state == null or _state.hull_max <= 0.0:
		return 1.0
	return clampf(_state.hull / _state.hull_max, 0.0, 1.0)


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


## Section 4.3: the HUD's slot (0-based, `weapon_1` first) addresses the same group on the
## mounted component (1-based, `GROUPS_MAX` 5). A fit with no guns carries no node and the
## selection stays a `PlayerState` reading, exactly as it was in slice 1.
func _select_weapon(slot: int) -> void:
	if slot < 0 or slot >= _state.ammo.size():
		return
	_weapon_index = slot
	_state.set_ammo(slot, _state.ammo[slot])
	if _guns != null and _guns.has_method(&"select_group"):
		_guns.call(&"select_group", slot + 1)


func _bind_hud() -> void:
	if _hud == null:
		return
	_hud.call(&"bind", _state)
	_push_sector_name()
	_push_hull_slots()
	_hud.call(&"set_minimap_scale", _minimap_radius)
	_hud.connect(&"weapon_slot_selected", _on_weapon_slot_selected)
	_hud.connect(&"cargo_toggled", _on_cargo_toggled)
	_hud.connect(&"minimap_zoom_changed", _on_minimap_zoom_changed)


## CONTRACTS section 11's `set_hull_slots`: the launched hull's W cells, pushed once per
## launch because the fit only changes in the station. Guarded like every other HUD push
## here, so a HUD that predates this wave stays inert rather than failing the launch.
func _push_hull_slots() -> void:
	if _hud == null or not _hud.has_method(&"set_hull_slots"):
		return
	_hud.call(&"set_hull_slots", _launch_hull, _hull_slot_cells())


## One entry per W cell of the launched hull, in the matrix's own layout order (09
## section 4 item 5's index): `module` is the fitted base id (`&""` for an unfitted
## cell), `icon` is the catalogue's own path for it - the HUD draws the `w` slot glyph
## for an empty cell - and `selectable` is false past the input map's five weapon
## groups, so a 7-W capital's last two cells display without a key (CONTRACTS section
## 11). The cells come from `ShipFit.grid_cells`, so the HUD's grid is the hull's own
## matrix and no second layout table exists.
func _hull_slot_cells() -> Array:
	var cells: Array = []
	var fitted: Array = _launch_fit.get(&"weapons", [])
	for cell: Dictionary in ShipFit.grid_cells(_launch_hull):
		if StringName(cell[&"type"]) != &"weapons":
			continue
		var index := int(cell[&"index"])
		var module := &""
		if index >= 0 and index < fitted.size():
			module = StringName(str(fitted[index]))
		cells.append({
			&"slot": &"weapons",
			&"index": index,
			&"module": module,
			&"icon": ModuleCatalogScript.icon_path(module) if module != &"" else "",
			&"fitted": module != &"",
			&"selectable": index < WeaponsScript.GROUPS_MAX,
		})
	return cells


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


## --- NPCs and death (ENGINE_SPEC §5/§7) -------------------------------------------


## Section 5's spawn model, seen from this side: the sector spawns the hulls and this scene
## binds what a hull's death means. `NpcShip._die` raises `died` with where and what and
## then leaves the tree deferred, so every listener runs on a live node. The victim is bound
## into the handler, because two hulls of one archetype (the band's own common case) make
## the archetype alone ambiguous.
func _on_npc_spawned(ship: Node2D) -> void:
	if ship == null or not ship.has_signal(&"died"):
		return
	if not ship.is_connected(&"died", _on_npc_died):
		ship.connect(&"died", _on_npc_died.bind(ship))


## Section 5's "on death" column and doc 13's heat/standing table: what ships now is the
## heat and the standing the kill is worth, read off the victim's own row and filed where
## doc 13 keeps them (the profile, the only heat owner), plus one `economy_log` line.
##
## What does not ship in this slice, and is reported rather than guessed: the loot roll's
## payouts (W4's tables roll, but the wreck's pickups are §7's and slice 4's), the witness
## rule (13 §2/§5 - a kill only counts when someone saw it) and the bounty payout window
## (14 §7).
func _on_npc_died(_position: Vector2, archetype: StringName, ship: Node2D) -> void:
	if _lock_target == ship:
		_cancel_lock()
	var profile := _profile()
	if profile == null:
		push_warning("game: an NPC died with no profile service; heat and standing not filed")
		return
	var heat := int(ship.call(&"heat_on_kill"))
	var standing := int(ship.call(&"standing_on_kill"))
	if heat != 0:
		_apply_heat(profile, heat)
	if standing != 0:
		_apply_standing(profile, standing)
	EconomyLogScript.append(EVENT_KILL, archetype, 1, 0, int(profile.call(&"credits")))


## 13 §4's per-kill heat, filed through the profile (the only heat owner, 13 §1) under the
## space owner's key - the key `NpcShip._read_heat_tier` reads it back with, so a patrol's
## scan of the player and the player's own crime score can never disagree.
func _apply_heat(profile: Node, delta: int) -> void:
	var heat: Dictionary = profile.call(&"heat")
	var key := String(_sector_owner())
	heat[key] = int(heat.get(key, 0)) + delta
	profile.call(&"set_heat", heat)


func _apply_standing(profile: Node, delta: int) -> void:
	var standing: Dictionary = profile.call(&"standing")
	var key := String(_sector_owner())
	standing[key] = int(standing.get(key, 0)) + delta
	profile.call(&"set_standing", standing)


func _sector_owner() -> StringName:
	if _sector == null or not is_inside_tree():
		return NpcRegistryScript.UNALIGNED
	return NpcRegistryScript.space_owner(_sector_row_id)


## Section 7's death flow, the minimal shape the brief pins: hull 0 → the wreck's
## explosion (the shockwave §13's `EXPLOSION_P0` is labelled for), the hold dropped at the
## wreck with its recovery window, then a respawn docked. 14 §3's insurance, the mercy
## clause and the hull replacement are slice 4 and are reported, not guessed.
##
## Nothing is filed to the profile's vitals here on purpose: a 0-hull record would be the
## next launch's starting state, and the ship that comes back is 14 §3's business.
func _on_ship_died() -> void:
	if _dead:
		return
	_dead = true
	_cancel_lock()
	_switch_ship_off()
	if _hud != null:
		_hud.call(&"clear_target")
		_hud.call(&"set_prompt", "")
		_hud.call(&"set_warp_channel", 0.0)
		_hud.call(&"set_speedometer", 0.0, Vector2.ZERO, Vector2.ZERO)
	_explode_wreck()
	_drop_cargo_at_wreck()
	_respawn_docked()


## The wreck stops flying and stops firing the frame it dies: the hull's own physics and
## unhandled input are switched off (its reactor ticks, its guns' trigger and the fly-to
## order all live there), and it leaves the `player_ship` group, because a wreck is not a
## hull anything tractors to - without that, the hold's pickups (spawned on the wreck) would
## be pulled straight back aboard by the dead ship and an uncollected death would cost
## nothing.
##
## This is the wiring's own gate: `PlayerShip` has no death state and this pass may not
## reshape its flight code (reported for slice 4).
func _switch_ship_off() -> void:
	if _ship != null:
		_ship.set_physics_process(false)
		_ship.set_process_unhandled_input(false)
		_ship.remove_from_group(PLAYER_GROUP)
	if _guns != null:
		_guns.set_physics_process(false)


## §4.2 item 8 / §13's `EXPLOSION_P0` row, whose own label is "(ship death)": the outward
## impulse `I(d) = P₀ / (1 + d²)` over `EXPLOSION_WINDOW`, sliced across the window's ticks,
## to every rigid body the sector holds (the curve is the range) plus the hull itself. The
## blast's *face* - the bloom, the debris - is FX and slice 2.5's (reported).
func _explode_wreck() -> void:
	if _ship == null:
		return
	var epicentre: Vector2 = _ship.global_position
	for body: Node in _bodies_near():
		ImpactScript.apply_shockwave(epicentre, body, ImpactScript.EXPLOSION_WINDOW)


## Every `RigidBody2D` in the sector plus the player's own body.
func _bodies_near() -> Array[Node]:
	var out: Array[Node] = []
	if _sector != null:
		var stack: Array[Node] = [_sector]
		while not stack.is_empty():
			var node: Node = stack.pop_back()
			var body := node as RigidBody2D
			if body != null and not body.is_queued_for_deletion():
				out.append(body)
			for child: Node in node.get_children():
				stack.append(child)
	if _ship != null:
		var hull_body: RigidBody2D = _ship.call(&"impact_body")
		if hull_body != null:
			out.append(hull_body)
	return out


## Decision 7 / §2.7: "cargo spawns as pickups at the wreck with a 5-minute recovery
## window". The hold goes over the side through the only cargo owner (`remove_cargo`, 17
## §5 rule 2) as one pickup per stack, one `economy_log` line each, and the window rides
## `Pickup`'s own age clock (see `DROP_WINDOW`).
##
## Reported: the recovery itself needs the wreck to outlive the transition to the station
## screen, which today's single-scene world cannot do (the flight scene is discarded on the
## respawn route), so a death costs the hold until slice 4 persists the wreck.
func _drop_cargo_at_wreck() -> void:
	var profile := _profile()
	if profile == null or _ship == null:
		return
	var wreck: Vector2 = _ship.global_position
	var items: Dictionary = profile.call(&"cargo_items")
	for raw_id: Variant in items.keys():
		var item_id := StringName(raw_id)
		var amount := int(items[raw_id])
		if amount <= 0:
			continue
		if not bool(profile.call(&"remove_cargo", item_id, amount)):
			continue
		_spawn_drop(item_id, amount, wreck)
		EconomyLogScript.append(
			EVENT_DROP, item_id, amount, 0, int(profile.call(&"credits"))
		)


## One dropped stack. Credits are not cargo (they are the wallet) so the drop is always a
## cargo pickup; the window is expressed as the pickup's starting age, because
## `Pickup.LIFETIME` is the only lifetime knob it has and it is a constant.
func _spawn_drop(item_id: StringName, amount: int, wreck: Vector2) -> void:
	var pickup: Node2D = PickupScript.new() as Node2D
	add_child(pickup)
	pickup.global_position = wreck
	pickup.call(&"setup", item_id, amount, false)
	pickup.set(&"_age", PickupScript.LIFETIME - DROP_WINDOW)


## 14 §3's first clause, the only one this slice can honour: "on death you respawn docked
## at the last station visited". In a session the last station visited *is* the one being
## orbited (the player launched from it), so the respawn is the same dock route the dock
## prompt and the safe warp use. A sector with no station (S7) has nowhere to respawn and
## says so; the insurance payout, the mercy clause and the replacement hull are slice 4.
func _respawn_docked() -> void:
	if _sector == null or not _sector.has_station():
		push_warning(
			"game: the hull was lost in a sector with no station; 14 section 3's respawn "
			+ "has no destination here (the sector record is slice 4's)."
		)
		return
	## A standalone run (a probe, a scene smoke test) has nothing listening, so the route
	## stays inert rather than emitting into nothing - the same guard docking uses.
	if route_requested.get_connections().is_empty():
		return
	route_requested.emit(ROUTE_LOADING, {PARAM_DESTINATION: DESTINATION_STATION})
