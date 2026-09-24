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
## S6's POI and loot tables (CONTRACTS §19): the kill roll and the wreck site the
## kill leaves, reached by path like every other cross-file table here.
const PoiScript := preload("res://game/poi.gd")
const LootTablesScript := preload("res://game/loot_tables.gd")
## 13 §7's witness range is **derived** from the tree's only scan range, so the two can
## never drift: `WITNESS_RANGE` below is `ShipFit.BASE_SCAN_RANGE` and this preload is the
## only reason it is reachable from here.
const ShipFitScript := preload("res://game/ship_fit.gd")
## The screen-space speed fantasy and the hull-critical vignette (FX_SPEC section 5,
## section 6 row 1): one node owns the blur, the camera's applied zoom, the dust and the
## vignette, and this scene pushes it the single input it reads.
const SpeedFantasyScript := preload("res://game/speed_fantasy.gd")
const SPEED_FANTASY_NODE: StringName = &"SpeedFantasy"

const ROUTE_LOADING: StringName = &"loading"
const PARAM_DESTINATION: StringName = &"destination"
const PARAM_SECTOR: StringName = &"sector"
const DESTINATION_STATION: StringName = &"station"
const DESTINATION_GAME: StringName = &"game"
const PROFILE_SERVICE: StringName = &"PlayerProfile"
## 01 section 7 / 02 section 7.5: the profile signal key that says the manifest moved.
const PROFILE_CARGO_KEY: StringName = &"cargo"

const HULL_ID_DEFAULT: StringName = &"ship_vanguard"
const SECTOR_ID_DEFAULT: StringName = &"sector_1"

## Section 4.3's group keys, **seven** since S5 (09 section 11, CONTRACTS section 17):
## `weapon_1..7` and `GROUPS_MAX` grow together, because a composed battery rack is
## addressed by the same ordinal the ARMORY pane's racks `B1..B7` render. The
## `weapon_6`/`weapon_7` rows of `project.godot` are orchestrator-applied, so the
## readers stay behind `InputMap.has_action` guards.
const WEAPON_ACTIONS: Array[StringName] = [
	&"weapon_1",
	&"weapon_2",
	&"weapon_3",
	&"weapon_4",
	&"weapon_5",
	&"weapon_6",
	&"weapon_7",
]

const HUD_REFRESH_INTERVAL := 0.1
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
## 11 §5's gate prompt lines, verbatim (CONTRACTS §19). The em dash is the pin's own
## copy; it is written as a `\u2014` escape so the source file stays plain ASCII.
const GATE_PROMPT_FORMAT := "JUMP TO %s \u2014 %d CR"
const GATE_REFUSED_PROMPT := "GATE REFUSED \u2014 OUTLAW"
const INTERACT_ACTION: StringName = &"interact"
const WARP_ACTION: StringName = &"warp"
## ENGINE_SPEC section 13 `WARP_CHANNEL`.
const WARP_CHANNEL := 3.0

## 11 §5's scanner readout (`SCANNING nn %`, 4 Hz) and 06 §5's cache feed
## (`+120 CR SALVAGE`), both riding the frozen `set_prompt` seam (CONTRACTS §19: no
## `ui/hud/**` writes). The feed lingers `SALVAGE_FEED_SECONDS`; the scan readout is
## repainted at `SCAN_PROMPT_HZ` so a 5 s channel is ~20 distinct lines.
const SCAN_PROMPT_FORMAT := "SCANNING %d %%"
const SCAN_PROMPT_PREFIX := "SCANNING"
const SCAN_PROMPT_HZ := 4.0
const SALVAGE_FEED_FORMAT := "+%d CR SALVAGE"
const SALVAGE_FEED_SECONDS := 2.0

## 13 §3's hunter archetype: the one row that drops `LootTables.HUNTER_EXTRA` in
## addition to its band table (06 §8). The id has one home - `NpcRegistry.ARCHETYPE_HUNTER`,
## the row the heat tier's wing spawns - so this scene and the registry cannot drift.
const HUNTER_ARCHETYPE: StringName = NpcRegistryScript.ARCHETYPE_HUNTER

## 13 §5/§7's witness rule. `WITNESS_RANGE` is **derived**, not proposed: it is the tree's
## only scan range (`ShipFit.BASE_SCAN_RANGE`, `game/ship_fit.gd`), and the +5 is 13 §2's
## own "witness survives (any crime) +5 extra" row. Heat is clamped to 13 §2's 0-100 on
## every gain.
const WITNESS_RANGE := ShipFitScript.BASE_SCAN_RANGE
const WITNESS_EXTRA := 5
const HEAT_MAX := 100

## 13 §7's decay: "-1 per minute of play", accrued by this scene's own float play-time
## accumulator (no Timer node, 17 §4's one-timer rule; `WorldClock` stays the station-band
## clock). The accumulator is scene-scoped, so a transition restarts it (reported).
const HEAT_DECAY_SECONDS := 60.0

## 13 §3's Outlaw perma-tail: a wing respawns this long after the previous one dies.
const HUNTER_RESPAWN_SECONDS := 60.0
## Where a wing is placed when it spawns: a ring around the player, inside the wing's own
## 900 u aggro radius so the tail is immediate. **Proposed** - no doc gives the placement
## (13 §3 says only that the wing spawns on entry); reversal: the sector's own field anchor
## (`sector.gd:_add_npc`'s default), which is one line less.
const HUNTER_SPAWN_RADIUS := 600.0

## 12 §4.1's Outlaw standing band: at or below this floor a faction denies docking. The
## **dock** refusal reads this axis; the **gate** refusal reads the heat tier (13 §3).
const STANDING_OUTLAW := -51
## The dock refusal's readout, mirroring 11 §5's pinned gate line's own words. 11 §5 pins
## no dock copy, so this is the panel-facing reading of 12 §4.1's "denied docking"
## (reported, not invented: reversal is deleting this constant and its rung).
const DOCK_REFUSED_PROMPT := "DOCK REFUSED \u2014 OUTLAW"

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

## 11 §2.3 / CONTRACTS §19: a sector transition routes through `loading`, which reloads
## this scene, so `_ready` runs a second time - and the launch's ammo auto-load
## (`_seed_ammo`, which draws cargo units out of the hold) must not run on that second
## boot, or the magazine would refill from the hold mid-flight and the hold would shrink
## across the crossing. The outgoing scene names the destination here before it routes;
## `_ready` reads it and seeds the packs from the filed store instead. A static because
## the instance that wrote it is gone by the time the new one boots.
static var _transit_destination: StringName = &""

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
## 11 §1 / K0 F15: the sector label is the registry row's own name, set on spawn and on
## transition (`_spawn_sector`); the stale "Helios Drift" interim is gone.
var _sector_name := ""
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

## S6's scan channel and cache feed (11 §3.1/§5, 06 §5): the derelict the channel is
## running on (null when none), the readout's own 4 Hz accumulator, and the salvage
## feed's text and remaining seconds. One prompt line, one owner (`_update_dock_prompt`).
var _scan_poi: Node = null
var _scan_prompt_accumulator := 0.0
var _feed_text := ""
var _feed_remaining := 0.0

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

## 13 §7's heat clock: seconds of play since the last decay tick. A float on this scene's
## own tick, not a Timer (17 §4); `WorldClock` is untouched and keeps its five consumers.
var _heat_play_time := 0.0
## 13 §3's hunter bookkeeping, all of it per sector entry (`_spawn_sector` re-arms it):
## whether a Wanted/Outlaw wing has already been spawned for this entry, and the countdown
## to the perma-tail respawn after the wing dies. The faction is never stored - it is the
## space owner, read fresh each frame, which is what keeps a wing in that faction's space
## only.
var _hunter_wave_spawned := false
var _hunter_respawn := 0.0


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
	if _transit_destination.is_empty():
		_seed_ammo()
	else:
		## A sector crossing, not a launch: the packs come back from the store the
		## outgoing scene just filed, with no hold draw (`_seed_ammo_from_store`).
		_seed_ammo_from_store()
		_transit_destination = &""
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
	_update_travel(delta)
	_update_pois(delta)
	_decay_heat(delta)
	_update_hunters(delta)
	_tick_prompt_timers(delta)
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
	## The transition flag has done its work in `_ready`; a same-scene `on_route` (a probe
	## or a test) must not leave it armed for the next real launch.
	_transit_destination = &""


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
		## S6: the POIs the sector spawns are bound the same way, so a derelict's own
		## `scanned` reward can raise the cache feed without the sector knowing the HUD.
		_sector.connect(&"poi_spawned", _on_poi_spawned)
		add_child(_sector)
	_sector_row_id = StringName(row.get(&"id", SECTOR_ID_DEFAULT))
	## 11 §1 / K0 F15: the label is the row's own name, so a launch and a transition
	## both read the sector the player is actually in.
	_sector_name = String(row.get(&"name", _sector_name))
	_cancel_lock()
	## 13 §3's wing is per sector entry: a Wanted wing has not spawned yet in this space
	## and no tail is counting down, whatever the last sector left behind.
	_hunter_wave_spawned = false
	_hunter_respawn = 0.0
	if _ship != null:
		_seat_ship(_sector.populate(row))
		_bind_travel_seams()
		return
	_pending_spawn = _sector.populate(row)
	_bind_travel_seams()


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
		## S5 (09 section 11, CONTRACTS section 17): the launch hands the component the
		## composed racks its `weapon_1..7` keys address, resolved from the profile's
		## persisted cell refs into the component's own barrel positions.
		if _guns.has_method(&"set_batteries"):
			_guns.call(&"set_batteries", _launch_batteries())
	_seat_ship(_pending_spawn)


## The launched fit's batteries in the mounted component's own index space: the
## profile's rack record for the launched hull (`PlayerProfile.battery_groups`, cell
## refs into the hull's W cells) with every cell translated to the **barrel position**
## `ShipFit.fitted_ids` gives that cell, plus one trailing rack for a barrel the record
## does not mention - so a rack the ARMORY pane composed fires the barrels it holds and
## nothing is left unfireable. `[]` for a hull with no racks, which leaves the
## component on its own per-family grouping (S4's).
##
## The translation is `game.gd`'s because it is the only place that holds both spaces:
## §16 rule 3's divergence means a W-cell index and a barrel position differ as soon as
## a cell holds a family-less module (`w_mining`), so the positions are derived from
## `fitted_ids`' own walk of the fit rather than guessed from the cell index.
func _launch_batteries() -> Array:
	var profile := _profile()
	if profile == null or not profile.has_method(&"battery_groups"):
		return []
	var groups: Array = profile.call(&"battery_groups", _launch_hull)
	if groups.is_empty():
		return []
	var positions: Array = _weapon_barrel_positions()
	var racks: Array = []
	for stored: Variant in groups:
		if not stored is Array:
			continue
		var rack: Array = []
		for raw_cell: Variant in (stored as Array):
			var cell := int(raw_cell)
			if cell < 0 or cell >= positions.size():
				continue
			var position := int(positions[cell])
			if position < 0 or rack.has(position):
				continue
			rack.append(position)
		racks.append(rack)
	return racks


## The barrel position `ShipFit.fitted_ids` gives each W cell of the launched fit:
## one entry per **layout index** of the hull's W cells, `-1` for a cell that holds
## nothing or holds a family-less module (the component drops `w_mining` from its
## barrel list, which is the divergence §16 rule 3 records). The walk is
## `fitted_ids`' own - weapons first, in cell order - so the two can never drift.
func _weapon_barrel_positions() -> Array:
	var fitted: Array = _launch_fit.get(&"weapons", [])
	var positions: Array = []
	var position := 0
	for cell: Dictionary in ShipFit.grid_cells(_launch_hull):
		if StringName(cell[&"type"]) != &"weapons":
			continue
		var index := int(cell[&"index"])
		var module := &""
		if index >= 0 and index < fitted.size():
			module = StringName(str(fitted[index]))
		while positions.size() <= index:
			positions.append(-1)
		if module != &"" and WeaponsScript.weapon_id(module) != &"":
			positions[index] = position
			position += 1
	return positions


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
##
## The prompt line's one owner (K0 1.4 constraint 2 / CONTRACTS §19): `_update_dock_prompt`
## writes the line every frame, so every later claimant joins this ladder here rather
## than calling `set_prompt` itself. The order is the pin's: the gate outranks the
## scanner's channel, which outranks the salvage feed, which outranks the dock.
func _update_dock_prompt() -> void:
	var gate := _gate_under_ship()
	if gate != null:
		_push_gate_prompt(gate)
		return
	var scan := _scan_prompt_text()
	if not scan.is_empty():
		_push_prompt(scan)
		return
	if not _feed_text.is_empty():
		_push_prompt(_feed_text)
		return
	var inside := _inside_dock_zone()
	## 12 §4.1's Outlaw band denies docking in faction space (13 §5). The refusal is the
	## prompt's, not the route's: the line says why and `interact` never reaches
	## `_request_dock`, so nothing is filed and nothing is written.
	if inside and _dock_refused():
		_push_prompt(DOCK_REFUSED_PROMPT)
		return
	_push_prompt(DOCK_PROMPT if inside else "")
	if not inside:
		return
	if InputMap.has_action(INTERACT_ACTION) and Input.is_action_just_pressed(INTERACT_ACTION):
		_request_dock()


## 12 §4.1's second refusal axis, read from its own doc: the docked station's faction
## denies docking at or below its Outlaw standing floor (-51). The **gate** refusal reads
## the heat tier instead (13 §3) - two axes, each from its own doc, and neither writes
## anything.
func _dock_refused() -> bool:
	var profile := _profile()
	if profile == null or not profile.has_method(&"standing_of"):
		return false
	var faction := _sector_owner()
	if faction == NpcRegistryScript.UNALIGNED or faction == &"":
		return false
	return int(profile.call(&"standing_of", faction)) <= STANDING_OUTLAW


## 11 §5's gate readout: `GATE_REFUSED_PROMPT` at the Outlaw heat tier (13 §3), otherwise
## the jump line (`GATE_PROMPT_FORMAT`, the destination's name and fee). `interact`
## confirms through `Gate.jump` (17 §5's law; a refusal writes nothing), and the ring's
## own charge-up raises `jumped` when it completes.
func _push_gate_prompt(gate: Node) -> void:
	var tier := _player_heat_tier()
	if tier == NpcRegistryScript.HEAT_OUTLAW:
		_push_prompt(GATE_REFUSED_PROMPT)
	else:
		_push_prompt(
			GATE_PROMPT_FORMAT % [
				String(gate.call(&"destination_name")), int(gate.call(&"fee_for", tier))
			]
		)
	if bool(gate.call(&"is_charging")):
		return
	if InputMap.has_action(INTERACT_ACTION) and Input.is_action_just_pressed(INTERACT_ACTION):
		_request_gate_jump(gate)


## The ring under the ship, or null. The gate is the sector's geometry (its own
## `contains`); this scene owns only the prompt and the jump.
func _gate_under_ship() -> Node:
	if _ship == null or _sector == null:
		return null
	if not _sector.has_method(&"gates"):
		return null
	for gate: Node in _sector.call(&"gates"):
		if gate != null and bool(gate.call(&"contains", _ship.global_position)):
			return gate
	return null


func _request_gate_jump(gate: Node) -> void:
	var profile := _profile()
	if profile == null:
		return
	gate.call(&"jump", profile, _player_heat_tier())


## The player's heat tier in the current space, read through the profile (13 §1's only
## heat owner) under the space owner's key - the same key `_apply_heat` writes.
func _player_heat_tier() -> StringName:
	var profile := _profile()
	if profile == null:
		return NpcRegistryScript.HEAT_CLEAN
	var heat: Dictionary = profile.call(&"heat")
	return NpcRegistryScript.heat_tier(int(heat.get(String(_sector_owner()), 0)))


## 11 §2.2/§5: the corridors accrue their 15 s presence hold off the ship's own position
## every physics frame. The corridor owns the rule; this scene owns the ship reference.
func _update_travel(delta: float) -> void:
	if _ship == null or _sector == null:
		return
	if not _sector.has_method(&"corridors"):
		return
	for corridor: Node in _sector.call(&"corridors"):
		if corridor != null:
			corridor.call(&"update_presence", delta, _ship.global_position)


## Binds the sector's travel geometry to this scene's two transition triggers: a gate's
## completed charge-up and a corridor's completed hold both mean "cross into the
## destination sector".
func _bind_travel_seams() -> void:
	if _sector == null:
		return
	for gate: Node in _sector.call(&"gates"):
		if gate != null and not gate.is_connected(&"jumped", _on_gate_jumped):
			gate.connect(&"jumped", _on_gate_jumped)
	for corridor: Node in _sector.call(&"corridors"):
		if corridor != null and not corridor.is_connected(&"crossed", _on_corridor_crossed):
			corridor.connect(&"crossed", _on_corridor_crossed)


## 11 §2.3 / CONTRACTS §19: the transition goes through the `loading` route and files the
## vitals **first**, because `Router.route` reloads this scene and the new one seeds
## hull/shield/fuel from the filed record only - an unfiled crossing would silently reset
## the pools to the last docked state. Fields and pickups reset because the scene is
## rebuilt; the hold and heat live on `PlayerProfile` and are untouched.
func _transition_to_sector(dest_number: int) -> void:
	var row := Registry.sector(Registry.sector_id_for(dest_number))
	if row.is_empty():
		push_warning("game: no registry row for sector %d; the crossing is inert" % dest_number)
		return
	_request_sector_route(row)


func _request_sector_route(row: Dictionary) -> void:
	if route_requested.get_connections().is_empty():
		return
	_transit_destination = StringName(row.get(&"id", &""))
	_file_damage_report()
	route_requested.emit(
		ROUTE_LOADING,
		{PARAM_DESTINATION: DESTINATION_GAME, PARAM_SECTOR: StringName(row[&"id"])}
	)


func _on_gate_jumped(dest_sector: int) -> void:
	_transition_to_sector(dest_sector)


func _on_corridor_crossed(dest_sector: int) -> void:
	_transition_to_sector(dest_sector)


## S6's POIs, driven every physics frame (11 §3.2/§5): an anomaly inside its 200 u
## radius fires its one-roll event, an active rift drains shields at `RIFT_DRAIN`/s
## through the ship's own damage sink, and the nearest unspent derelict gets the scan
## channel. The sector owns the POIs; this scene owns the ship reference and the
## prompt line.
func _update_pois(delta: float) -> void:
	if _ship == null or _sector == null or not _sector.has_method(&"pois"):
		return
	for poi: Node in _sector.call(&"pois"):
		if poi == null or not is_instance_valid(poi):
			continue
		var poi_kind := StringName(poi.get(&"kind"))
		if poi_kind == PoiScript.KIND_ANOMALY:
			if not bool(poi.call(&"is_consumed")) and bool(poi.call(&"in_trigger_radius", _ship)):
				poi.call(&"trigger", _ship)
			var drain := float(poi.call(&"update_presence", delta, _ship))
			if drain > 0.0:
				_ship.call(&"take_damage", drain)
	_update_scan(delta)


## 11 §3.1's 5 s interruptible channel on the nearest derelict in scan range, and
## 11 §3.3's beacon reveal on the nearest beacon (a beacon answers at once, so it has
## no channel and never holds `_scan_poi`). The channel resets when the ship leaves
## range (the POI's own `scan` reports it), and `_on_ship_damage_taken` forwards a
## hull hit to the same `interrupt`.
func _update_scan(delta: float) -> void:
	var nearest := _nearest_scannable()
	if nearest != null and bool(nearest.call(&"in_scan_range", _ship)):
		var code := int(nearest.call(&"scan", _ship))
		if code == PoiScript.SCAN_OK and bool(nearest.call(&"is_channelling")):
			nearest.call(&"advance_scan", delta)
			_scan_poi = nearest
			return
		if _scan_poi != null and _scan_poi != nearest:
			_scan_poi = null
		return
	if _scan_poi != null:
		if is_instance_valid(_scan_poi):
			## Out of range: the POI's own call cancels the channel and reports it.
			_scan_poi.call(&"scan", _ship)
		_scan_poi = null


## The closest POI the scanner reaches: an unspent derelict or a beacon (11 §3.1/
## §3.3), or null.
func _nearest_scannable() -> Node:
	if _sector == null or _ship == null or not _sector.has_method(&"pois"):
		return null
	var nearest: Node = null
	var nearest_distance := INF
	for poi: Node in _sector.call(&"pois"):
		if poi == null or not is_instance_valid(poi):
			continue
		var poi_kind := StringName(poi.get(&"kind"))
		if poi_kind == PoiScript.KIND_DERELICT and bool(poi.call(&"is_consumed")):
			continue
		if poi_kind != PoiScript.KIND_DERELICT and poi_kind != PoiScript.KIND_BEACON:
			continue
		var distance := _ship.global_position.distance_to((poi as Node2D).global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = poi
	return nearest


## Binds a POI's own reward signals (S6, 11 §3.1/06 §5): the derelict's data core pays
## credits through the profile, and a wreck site's credit cache reports its collection,
## so both feed lines ride the one prompt seam.
func _on_poi_spawned(poi: Node2D) -> void:
	if poi == null:
		return
	if poi.has_signal(&"scanned") and not poi.is_connected(&"scanned", _on_poi_scanned):
		poi.connect(&"scanned", _on_poi_scanned)
	if poi.has_signal(&"cache_collected") and not poi.is_connected(
		&"cache_collected", _on_poi_cache_collected
	):
		poi.connect(&"cache_collected", _on_poi_cache_collected)


func _on_poi_scanned(_reward: StringName, credits: int) -> void:
	if credits > 0:
		_push_cache_feed(credits)


func _on_poi_cache_collected(amount: int) -> void:
	if amount > 0:
		_push_cache_feed(amount)


## 06 §5's one-line feed (`+120 CR SALVAGE`), on the frozen prompt seam. A new feed
## replaces the previous one and restarts its own window.
func _push_cache_feed(amount: int) -> void:
	_feed_text = SALVAGE_FEED_FORMAT % amount
	_feed_remaining = SALVAGE_FEED_SECONDS


## The feed's window, and the scan readout's 4 Hz repaint (11 §5). Both are the
## prompt ladder's own state; nothing here writes a HUD widget.
func _tick_prompt_timers(delta: float) -> void:
	if _feed_remaining > 0.0:
		_feed_remaining = maxf(_feed_remaining - delta, 0.0)
		if _feed_remaining <= 0.0:
			_feed_text = ""
	_scan_prompt_accumulator += delta


## The scan readout for the current channel, or "" when no channel is running. The
## 4 Hz gate is the accumulator `_tick_prompt_timers` advances.
func _scan_prompt_text() -> String:
	if _scan_poi == null or not is_instance_valid(_scan_poi):
		return ""
	if not bool(_scan_poi.call(&"is_channelling")):
		return ""
	if _scan_prompt_accumulator < 1.0 / SCAN_PROMPT_HZ:
		return _prompt if _prompt.begins_with(SCAN_PROMPT_PREFIX) else ""
	_scan_prompt_accumulator = 0.0
	var percent := int(round(float(_scan_poi.call(&"channel_progress")) * 100.0))
	return SCAN_PROMPT_FORMAT % percent


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
##
## 12 §4.1 / 13 §5: a faction whose standing is Outlaw denies docking. The refusal is
## checked **before** `_file_damage_report`, so it writes nothing at all - no vitals, no
## route, no `docked_faction` - and the profile is byte-identical after it. On a real dock
## the docked faction is filed for the station's LAUNCH pane (13 §7's bounty row).
func _request_dock() -> void:
	if _dock_refused():
		return
	if route_requested.get_connections().is_empty():
		return
	_file_damage_report()
	_file_docked_faction()
	route_requested.emit(ROUTE_LOADING, {PARAM_DESTINATION: DESTINATION_STATION})


## 13 §7's bounty row is the docked station's faction's, so the docking route names that
## faction on the profile before it leaves. Transient (not a save key); a profile without
## the setter leaves the row hidden rather than guessing a faction.
func _file_docked_faction() -> void:
	var profile := _profile()
	if profile == null or not profile.has_method(&"set_docked_faction"):
		return
	profile.call(&"set_docked_faction", _sector_owner())


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
## shield signals, so a hit fully absorbed by the shield breaks it too. S6 extends the
## same break to the derelict scan channel (11 §3.1: "interruptible").
func _on_ship_damage_taken(_amount: float) -> void:
	_cancel_warp()
	if _scan_poi != null and is_instance_valid(_scan_poi):
		_scan_poi.call(&"interrupt")


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
		## `weapon_6`/`weapon_7` join `project.godot` at the wave's close-out (CONTRACTS
		## section 1), so the two new keys are read behind the same `InputMap.has_action`
		## guard the countermeasures and the dock prompt use: an action the map does not
		## carry yet must not push an engine error every frame of flight.
		if not InputMap.has_action(WEAPON_ACTIONS[slot]):
			continue
		if Input.is_action_just_pressed(WEAPON_ACTIONS[slot]):
			_select_weapon(slot + 1)


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
## The write rides `PlayerProfile.set_ammo` (the dock report's absolute writer; `buy_ammo`
## could only ever add). Since S5 (10 section 6.1) that store is the **magazine the launch
## loaded from the hold**, not a purchase target: `buy_ammo` delivers cargo units, the
## launch draws them through `load_ammo_from_hold`, and this filing takes the fired rounds
## off what the load left, so the next launch tops up from whatever the hold still carries.
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


## The other half of the same pattern, and since S5 it is a **cargo** load (10 section 6.1,
## CONTRACTS section 17): each fitted weapon's pack auto-fills from the hold's `ammo_*` units
## of its family up to `ammo_max`, once per launch, and the drawn units leave the hold. The
## slots are the launched fit's own (`weapons`), so a hull that mounts two lasers loads the
## one `laser` pack **once** and seeds both slots from it, and a hull that mounts none loads
## nothing. The load is a profile write (`load_ammo_from_hold` tops the pack up and returns
## what it holds), so each slot is seeded from the pack's own post-load figure and
## `_ammo_seed` still records what the flight started with. Nothing here runs in flight: a
## pack that empties during a sortie stays empty until the next launch.
func _seed_ammo() -> void:
	var profile := _profile()
	if profile == null or _state == null:
		return
	_ammo_seed.clear()
	var loaded: Dictionary = {}
	for slot in _state.weapons.size():
		var weapon_id: StringName = _state.weapons[slot]
		_state.set_ammo(slot, _auto_load_ammo(profile, weapon_id, loaded))
		_ammo_seed.append(_state.ammo[slot])


## The sector crossing's pack seed (11 §2.3 / CONTRACTS §19): the packs the outgoing
## scene just filed, with **no** hold draw. The launch's auto-load is once per launch and
## a crossing is not a launch, so the hold is not spent a second time; the seeded packs
## then become this leg's dock-filing baseline, exactly as `_seed_ammo`'s do.
func _seed_ammo_from_store() -> void:
	var profile := _profile()
	if profile == null or _state == null:
		return
	_ammo_seed.clear()
	for slot in _state.weapons.size():
		var weapon_id: StringName = _state.weapons[slot]
		_state.set_ammo(slot, int(profile.call(&"ammo_of", weapon_id)))
		_ammo_seed.append(_state.ammo[slot])


## One family's auto-load, answered from `loaded` after the first cell that asks for it so a
## twin-weapon fit draws the hold exactly once. A profile without the cargo auto-load (a
## stub, or an older store) keeps the pre-S5 read of its own pack.
func _auto_load_ammo(profile: Node, weapon_id: StringName, loaded: Dictionary) -> int:
	if loaded.has(weapon_id):
		return int(loaded[weapon_id])
	var rounds := 0
	if profile.has_method(&"load_ammo_from_hold"):
		rounds = int(profile.call(&"load_ammo_from_hold", weapon_id))
	else:
		rounds = int(profile.call(&"ammo_of", weapon_id))
	loaded[weapon_id] = rounds
	return rounds


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


## Section 4.3 / 09 section 11: a **rack ordinal** (1-based, `weapon_1..7`) selects
## the battery the mounted component fires. Both callers hand one in - the input map's
## `weapon_N` key as `N` and the HUD's W-slot button as the ordinal of the rack its
## cell belongs to (`ui/hud/hud.gd`) - because a composed rack may hold several kinds
## and one rack need not sit at its own cell's index. A fit with no guns carries no
## node and the selection stays a `PlayerState` reading, exactly as it was in slice 1.
func _select_weapon(battery: int) -> void:
	if battery < 1 or battery > WeaponsScript.GROUPS_MAX:
		return
	_weapon_index = battery - 1
	if _guns != null and _guns.has_method(&"select_group"):
		_guns.call(&"select_group", battery)
	if _hud != null and _hud.has_method(&"select_battery"):
		_hud.call(&"select_battery", battery)


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
## for an empty cell - and `battery` is the **1-based rack ordinal** the cell fires
## from, `0` for a cell that belongs to no rack (09 section 11 / CONTRACTS section 17:
## the HUD's W-slot buttons address battery ordinals, not cell indices, because a
## composed rack may hold several cells and several kinds). `selectable` follows from
## the battery: a cell with no rack, or one whose ordinal the input map cannot reach
## (`GROUPS_MAX`), displays without a key. The cells come from `ShipFit.grid_cells`,
## so the HUD's grid is the hull's own matrix and no second layout table exists.
##
## `position` is the **barrel slot** the cell's own ammo lives at - its index in
## `PlayerState.weapons`/`ammo`, which is the array the HUD's readout reads
## (`_hull_slot_cells` and `_launch_weapons` count the same cells in the same order, so
## the two can never drift). It is what makes a **mixed** rack's readout follow the
## barrel it names rather than the family that happens to sit at the ordinal's index
## (`ui/hud/hud.gd`, the S5 review's R1-MED-1). It equals `_weapon_barrel_positions()`'
## entry for the cell whenever every fitted cell carries a firing family - which is
## every standard fit and every auction fit - and differs only where 09 section 11 /
## CONTRACTS section 16 rule 3's divergence bites (a family-less `w_mining` cell, which
## `WeaponsComponent.set_fitted` drops from its own barrel list but `_launch_weapons`
## keeps as a slot with no pack). `-1` for a cell the fit leaves empty.
func _hull_slot_cells() -> Array:
	var cells: Array = []
	var fitted: Array = _launch_fit.get(&"weapons", [])
	var batteries: Array = _launch_batteries()
	var position := 0
	for cell: Dictionary in ShipFit.grid_cells(_launch_hull):
		if StringName(cell[&"type"]) != &"weapons":
			continue
		var index := int(cell[&"index"])
		var module := &""
		if index >= 0 and index < fitted.size():
			module = StringName(str(fitted[index]))
		var battery := _rack_ordinal(batteries, index)
		cells.append({
			&"slot": &"weapons",
			&"index": index,
			&"module": module,
			&"icon": ModuleCatalogScript.icon_path(module) if module != &"" else "",
			&"fitted": module != &"",
			&"battery": battery,
			&"position": position if module != &"" else -1,
			&"selectable": battery >= 1 and battery <= WeaponsScript.GROUPS_MAX,
		})
		if module != &"":
			position += 1
	return cells


## The 1-based ordinal of the rack holding one W cell, 0 for a cell no rack claims:
## the `battery` field of `_hull_slot_cells`, read by the HUD's slot buttons.
static func _rack_ordinal(batteries: Array, cell: int) -> int:
	for position in batteries.size():
		var rack: Array = batteries[position]
		if rack.has(cell):
			return position + 1
	return 0


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
## S6 (06 §8 / CONTRACTS §19) adds the kill's loot here, the one real seam: the victim's
## own row names its 06 table (`KEY_LOOT_KIND`), `LootTables.roll_band` rolls it and a
## hunter adds `roll_hunter_extra`, and the payload becomes the wreck site 06 §4 leaves
## at the kill point (`WRECK_PICKUP_LIFETIME` 90 s). K3 adds 13 §5's witness gate: a
## **crime** (a positive `heat_on_kill`) scores only with a witness in range, and scores
## `WITNESS_EXTRA` more for it; the pirate reduction (13 §2's -3) is not a crime, needs no
## witness and is never surcharged.
func _on_npc_died(_position: Vector2, archetype: StringName, ship: Node2D) -> void:
	if _lock_target == ship:
		_cancel_lock()
	var profile := _profile()
	if profile == null:
		push_warning("game: an NPC died with no profile service; heat and standing not filed")
		return
	var heat := int(ship.call(&"heat_on_kill"))
	var standing := int(ship.call(&"standing_on_kill"))
	if heat > 0:
		if _witnessed(_position, ship):
			_apply_heat(profile, heat + WITNESS_EXTRA)
	elif heat < 0:
		_apply_heat(profile, heat)
	if standing != 0:
		_apply_standing(profile, standing)
	EconomyLogScript.append(EVENT_KILL, archetype, 1, 0, int(profile.call(&"credits")))
	_spawn_kill_loot(_position, archetype, ship)


## 06 §8's kill roll and wreck site: the victim's 06 band table plus, for a hunter,
## 06 §8's `comp_elec` extra, held by a wreck site at the kill point for
## `LootTables.WRECK_PICKUP_LIFETIME`. A hull whose row names no table (the boss, the
## parked `sibelon`) leaves no site - 06 §3 has no table for it, and a site with
## nothing in it is not 06 §4's wreck.
func _spawn_kill_loot(kill_position: Vector2, archetype: StringName, ship: Node2D) -> void:
	if _sector == null or ship == null:
		return
	if not ship.has_method(&"row"):
		return
	var row: Dictionary = ship.call(&"row")
	var kind := StringName(row.get(NpcRegistryScript.KEY_LOOT_KIND, &""))
	if kind == &"" or not LootTablesScript.has(kind):
		return
	var band := int((LootTablesScript.TABLES[kind] as Dictionary)[&"band"])
	var payload: Array[Dictionary] = LootTablesScript.roll_band(kind)
	if archetype == HUNTER_ARCHETYPE:
		payload.append_array(LootTablesScript.roll_hunter_extra(band))
	var site: Node2D = PoiScript.new() as Node2D
	site.name = &"WreckSite"
	_sector.call(&"add_wreck_site", site)
	site.global_position = kill_position
	site.call(&"setup", PoiScript.KIND_WRECK, {&"payload": payload})


## 13 §4's per-kill heat, filed through the profile (the only heat owner, 13 §1) under the
## space owner's key - the key `NpcShip._read_heat_tier` reads it back with, so a patrol's
## scan of the player and the player's own crime score can never disagree.
##
## 13 §2's bound is applied here, on the way in: every gain and every reduction lands
## clamped to 0-100 per faction, so no kill can push a heat past the band 13 §3's tiers
## are written against.
func _apply_heat(profile: Node, delta: int) -> void:
	var heat: Dictionary = profile.call(&"heat")
	var key := String(_sector_owner())
	var current := int(heat.get(key, 0))
	var updated := clampi(current + delta, 0, HEAT_MAX)
	## A no-op writes nothing: a pirate killed at a zero heat (or at the floor) leaves no
	## zero-heat key behind, so a reduction cannot make the record grow.
	if updated == current:
		return
	heat[key] = updated
	profile.call(&"set_heat", heat)


func _apply_standing(profile: Node, delta: int) -> void:
	var standing: Dictionary = profile.call(&"standing")
	var key := String(_sector_owner())
	standing[key] = int(standing.get(key, 0)) + delta
	profile.call(&"set_standing", standing)


## --- Doc 13's heat, witnesses, hunters and the bounty (wave S6, CONTRACTS §19) ------


## 13 §7's decay: -1 per minute of **play time**, for every faction at once ("anywhere"),
## floored at 0. The clock is this scene's own float accumulator in seconds, advanced from
## `_physics_process` - no Timer node anywhere (17 §4's one-timer rule), and `WorldClock`
## stays the station-band clock with its five consumers. A whole minute is banked at a
## time, so a long frame cannot lose a minute and a 59.9 s frame cannot grant one.
func _decay_heat(delta: float) -> void:
	_heat_play_time += delta
	if _heat_play_time < HEAT_DECAY_SECONDS:
		return
	var minutes := int(floor(_heat_play_time / HEAT_DECAY_SECONDS))
	_heat_play_time -= float(minutes) * HEAT_DECAY_SECONDS
	var profile := _profile()
	if profile == null:
		return
	var heat: Dictionary = profile.call(&"heat")
	if heat.is_empty():
		return
	var cooled := heat.duplicate(true)
	for faction: Variant in heat:
		cooled[faction] = maxi(0, int(heat[faction]) - minutes)
	if cooled == heat:
		return
	profile.call(&"set_heat", cooled)


## 13 §5/§7's witness rule: a crime's heat lands only when a neutral hull, a patrol or the
## sector's station sits inside `WITNESS_RANGE` (900 u, derived from `ShipFit.BASE_SCAN_RANGE`)
## of the kill with an unblocked line to it. "Solo kills in dead space are free."
##
## The hulls are read from the `npc_ship` group - the same source `_enemy_engaged` uses, and
## the one a hull joins in its own `_ready`, so a hull spawned by the sector population, by
## a hunter wing or by a probe is seen alike.
##
## `victim` is excluded: `NpcShip._die` raises `died` **before** it leaves the tree (so every
## listener runs on a live node), which means a dead neutral hull is still in the group, still
## at the kill point, and would otherwise witness its own murder - a trader or a patrol would
## always be a crime however empty the space around it. The station is not excluded: it never
## dies.
func _witnessed(at: Vector2, victim: Node = null) -> bool:
	if _station_witnesses(at):
		return true
	if not is_inside_tree():
		return false
	for node: Node in get_tree().get_nodes_in_group(NpcRegistryScript.GROUP):
		if node == victim:
			continue
		var hull := node as Node2D
		if hull == null or not is_instance_valid(hull):
			continue
		if not _is_witness_hull(hull):
			continue
		if hull.global_position.distance_to(at) > WITNESS_RANGE:
			continue
		if _witness_visible(hull, at):
			return true
	return false


## 13 §5's "a neutral/patrol ship": a convoy hull (the row's own neutral blip class) or a
## patrol (the row whose hostility is the law's `faction_rules`). A pirate, a swarmer and a
## hunter witness nothing - the first two are the crime, the third is already chasing you.
func _is_witness_hull(hull: Node2D) -> bool:
	if hull.has_method(&"blip_kind"):
		if StringName(hull.call(&"blip_kind")) == NpcRegistryScript.BLIP_NEUTRAL:
			return true
	if hull.has_method(&"hostility"):
		return StringName(hull.call(&"hostility")) \
			== NpcRegistryScript.HOSTILITY_FACTION_RULES
	if not hull.has_method(&"row"):
		return false
	var row: Dictionary = hull.call(&"row")
	return StringName(row.get(NpcRegistryScript.KEY_HOSTILITY, &"")) \
		== NpcRegistryScript.HOSTILITY_FACTION_RULES


## The line from the kill to one witness: the hull's own `NpcShip._line_of_sight` when it
## has one (13 §7: "LOS is the NPC brain's own rock-blocking check"), otherwise this
## scene's own rock-layer ray - the same mask, so the two answers cannot disagree.
func _witness_visible(hull: Node2D, at: Vector2) -> bool:
	if hull.has_method(&"_line_of_sight"):
		return bool(hull.call(&"_line_of_sight", at, hull.global_position))
	return _rock_line_clear(at, hull.global_position)


## 13 §5's station half ("a neutral/patrol ship **or station turret**"): the station's own
## position stands in for the turret bolted to it, and the line is the same rock ray. A
## sector without a station, or a kill past the range, is unwitnessed by this half.
func _station_witnesses(at: Vector2) -> bool:
	if _sector == null or not _sector.has_method(&"has_station"):
		return false
	if not bool(_sector.call(&"has_station")):
		return false
	var station: Vector2 = _sector.call(&"station_position")
	if at.distance_to(station) > WITNESS_RANGE:
		return false
	return _rock_line_clear(at, station)


## The brain's rock-blocking ray, cast from the one node that is in the tree whatever
## spawned the hull or the station: `NpcShip._line_of_sight`'s mask
## (`Asteroid.COLLISION_LAYER`), read off its owner rather than restated.
func _rock_line_clear(from: Vector2, to: Vector2) -> bool:
	if not is_inside_tree():
		return true
	var world := get_world_2d()
	if world == null:
		return true
	var query := PhysicsRayQueryParameters2D.create(from, to, AsteroidScript.COLLISION_LAYER)
	return world.direct_space_state.intersect_ray(query).is_empty()


## 13 §3's hunter wing, per faction and per sector entry: a **Wanted** heat tier spawns one
## wing of 2-3 hunters on entry, and an **Outlaw** one keeps a tail alive - a fresh wing
## `HUNTER_RESPAWN_SECONDS` (60 s) after the previous one dies. Both are the space owner's
## business only, so a Concord outlaw is hunted in Concord space and Meridian still sells
## missiles (13 §3's political chessboard): the faction is read off the sector each frame,
## never stored.
##
## The 60 s countdown is this scene's own accumulator (no Timer, 17 §4) and only runs while
## the wing is dead, so a live tail is never doubled.
func _update_hunters(delta: float) -> void:
	if _sector == null or _ship == null or not is_inside_tree():
		return
	var faction := _sector_owner()
	if faction == NpcRegistryScript.UNALIGNED or faction == &"":
		return
	var tier := _player_heat_tier()
	if tier != NpcRegistryScript.HEAT_WANTED and tier != NpcRegistryScript.HEAT_OUTLAW:
		_hunter_respawn = 0.0
		return
	if _live_hunters() > 0:
		_hunter_respawn = 0.0
		return
	if not _hunter_wave_spawned:
		_hunter_wave_spawned = true
		_spawn_hunter_wave()
		return
	if tier != NpcRegistryScript.HEAT_OUTLAW:
		return
	_hunter_respawn += delta
	if _hunter_respawn < HUNTER_RESPAWN_SECONDS:
		return
	_hunter_respawn = 0.0
	_spawn_hunter_wave()


## One wing: `NpcRegistry.hunter_spawn` resolves the archetype's own row for this space and
## the player's active hull (13 §7's hull map), and the sector's own `_add_npc` spawns each
## hull, so the wing is a real sector NPC - in `npcs()`, in the blip feed, wired to the kill
## seam (and so to 06 §8's band table plus `HUNTER_EXTRA`) and counted by `_live_hunters`.
##
## The wing is then homed on the player (`HUNTER_SPAWN_RADIUS` out, one bearing each), which
## is what makes it a **tail** rather than a patrol of some asteroid field: the brain's
## 2 500 u leash is measured from its home, so a tail that is meant to follow must be homed
## where it appeared.
func _spawn_hunter_wave() -> void:
	var spawn := NpcRegistryScript.hunter_spawn(_sector_row_id, _launch_hull)
	if spawn.is_empty():
		push_warning("game: no hunter spawn row for %s; the wing is inert" % _sector_row_id)
		return
	if not _sector.has_method(&"_add_npc"):
		return
	var count := 0
	var band := Vector2i(
		int(spawn.get(NpcRegistryScript.KEY_MIN, 0)),
		int(spawn.get(NpcRegistryScript.KEY_MAX, 0))
	)
	if band.y > band.x:
		count = randi_range(band.x, band.y)
	else:
		count = band.x
	for index in count:
		_sector.call(&"_add_npc", spawn)
		_home_last_hunter(index, count)


## Where one wing member is placed: a ring `HUNTER_SPAWN_RADIUS` around the player, spread
## evenly so the wing arrives as a wing. The hull's **body** is the mover (`NpcShip` takes
## its transform from the body each frame, `_sync_hull_transform`), so both are set and the
## node reads right immediately for a caller that never advances a frame.
func _home_last_hunter(index: int, count: int) -> void:
	var npcs: Array = _sector.call(&"npcs")
	if npcs.is_empty():
		return
	var hull := npcs[npcs.size() - 1] as Node2D
	if hull == null or not is_instance_valid(hull):
		return
	var bearing := TAU * float(index) / float(maxi(count, 1))
	var place: Vector2 = _ship.global_position + Vector2(HUNTER_SPAWN_RADIUS, 0.0).rotated(bearing)
	hull.global_position = place
	if hull.has_method(&"impact_body"):
		var body := hull.call(&"impact_body") as RigidBody2D
		if body != null:
			body.global_position = place
	if hull.has_method(&"set_home"):
		hull.call(&"set_home", place)


## The live wing: every hull in this sector whose archetype is 13 §3's hunter row. Counted
## off the sector's own `npcs()` so a hull that died (or despawned) stops counting and the
## 60 s respawn can start.
func _live_hunters() -> int:
	if _sector == null or not _sector.has_method(&"npcs"):
		return 0
	var count := 0
	for hull: Node2D in _sector.call(&"npcs"):
		if hull == null or not is_instance_valid(hull):
			continue
		if not hull.has_method(&"archetype"):
			continue
		if StringName(hull.call(&"archetype")) == HUNTER_ARCHETYPE:
			count += 1
	return count


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
