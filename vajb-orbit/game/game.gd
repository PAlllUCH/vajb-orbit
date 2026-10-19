extends "res://game/game_base.gd"
## The second half of the flight scene (CODE_AUDIT 2026-10-19 P2): the entry hooks and
## the population/combat systems - NPCs, escorts, arenas, heat and hunters, and the
## death/wreck flow. The declarations and the launch/HUD/travel core are in
## `game_base.gd`; the scene still attaches this script.
##
## Reversal: concatenate this body under the base and restore the single `game.gd`.

func _ready() -> void:
	## S28's A7: the developer overlay is a debug-build tool; a release never mounts it.
	if OS.is_debug_build():
		add_child(DevTuningMenuScene.instantiate())
	_state = PlayerStateScript.new()
	_stats = _resolve_stats()
	_apply_ship_maxima()
	## The launched fit's weapon list, before `setup` sizes the ammo arrays from it
	## (CONTRACTS section 11): the live slots are the hull's own W cells, not the five
	## fixed families a fitless `PlayerState` still defaults to.
	_state.set_weapons(_launch_weapons())
	_state.setup()
	## The launch's affix handshake (CONTRACTS section 20), after `setup` has sized the
	## slot arrays: one `{keen, rapid, frugal}` magnitude dict per weapon slot - the
	## same walk `set_weapons` just took - and the fitted instances' suffix flags. The
	## per-barrel prefixes ride the slot array; the flags ride the state so the
	## delivery seams (Embers) and the wave's own suffix seams (K3's Leeches) read one
	## list.
	_state.set_weapon_affixes(_launch_weapon_affixes())
	_state.set_affix_flags(_launch_affix_flags())
	_seed_vitals()
	if _transit_destination.is_empty():
		_seed_ammo()
		## S26 (14 section 3, M14): the premium is charged at launch - a crossing is not
		## a launch, so it is not charged again.
		_charge_insurance()
		## S27 (10 section 3.3): a launch is the one in-space session a shipyard build
		## waits on ("ready when you return from your next flight"). A crossing is not a
		## launch, so it does not advance the counter either.
		ShipyardScript.note_flight(_profile())
	else:
		## A sector crossing, not a launch: the packs come back from the store the
		## outgoing scene just filed, with no hold draw (`_seed_ammo_from_store`).
		_seed_ammo_from_store()
		_transit_destination = &""
	_hud = _instantiate_hud()
	_bind_hud()
	_build_cargo_overlay()
	_connect_profile()
	_state.died.connect(_on_ship_died)
	_spawn_sector(_row_for(String(_sector_row_id)))
	_spawn_ship()
	_bind_speed_fantasy()
	_refresh_hud()


func _exit_tree() -> void:
	if _camera_zoom_tween != null and _camera_zoom_tween.is_valid():
		_camera_zoom_tween.kill()
	## L154: a scene that leaves with a crossing flag it did *not* arm is leaving for a
	## route that will never boot a game scene, so the flag is stale - drop it, or the next
	## launch seeds its ammo from the store instead of drawing the hold. A flag this scene
	## armed is the real crossing's and stays: the successor game scene's `_ready` consumes
	## it (the Router frees that scene before the next one is added, so this is the only
	## window the flag may survive in).
	if not _crossing_routed:
		_clear_transit_flag()
	_clear_drop_faces()
	_disconnect_profile()


func _physics_process(delta: float) -> void:
	if _dead:
		## Section 7's death flow replaces the ship; until the loading route lands the
		## wreck is inert (`PlayerShip.die` holds the state and its monitor).
		return
	_update_weapon_input()
	_update_countermeasure_input()
	_update_target_input()
	_update_lock(delta)
	_update_cargo_input()
	_update_cancel_input()
	_update_hyperdrive(delta)
	_update_travel(delta)
	_update_pois(delta)
	_update_clouds()
	_decay_heat(delta)
	_update_hunters(delta)
	_update_escorts(delta)
	_update_arena(delta)
	_update_maw(delta)
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
	_clear_transit_flag()


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
	_sector_row_id = StringName(row.get(&"id", Registry.DEFAULT_SECTOR_ID))
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
	else:
		_pending_spawn = _sector.populate(row)
		_bind_travel_seams()
	_reveal_pois_for_cartograph()
	## §2 dec. 7 / L23: the wreck's uncollected drops belong to the sector, so the entry
	## that knows which sector this scene is now in is the one that re-materialises them.
	_materialise_wreck_drops()
	## S25 (14 section 6): an escort contract accepted at this sector's station has its
	## convoy waiting on the pad, so the entry that knows the sector is the one that puts it
	## back - a dock/launch cycle therefore re-spawns it at the accepting station.
	_restore_escorts()
	## S26 (14 section 5): the arena is a physical place, so the entry that knows the
	## sector is the one that builds its lit ring (S3's Boneyard, S6's The Pyre).
	_build_arena_zone()
	_arena_boss = null
	_maw_node = null
	_maw_respawn = 0.0



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
	## S26 (14 section 5): a boss death is the one the arena cares about. The Maw's roam
	## clock re-arms here; an arena boss latches its death for the player's own hit to
	## confirm (`_on_player_hit`), so a drone's or an escort's kill credits nobody.
	if archetype == NpcRegistryScript.ARCHETYPE_MAW:
		_maw_node = null
		_maw_respawn = float(ClockScript.BAND_SECONDS)
	elif NpcRegistryScript.is_boss(archetype):
		_pending_boss_death = ship
		_pending_boss_archetype = archetype
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
	## S25 (14 section 2): the Hunt row's own channel - "Destroy 5 pirates in S2". The kill
	## credits the active hunts for this sector through the registry's door, and the fifth
	## closes the contract at the destination pay.
	_credit_hunt_kills(profile, archetype)
	## 15 section 4's Leeches (CONTRACTS section 20): the kill pays 5 % of the hull's
	## maximum back. It sits inside this handler's credited path - a death that reaches
	## here has already filed heat, standing and loot - because K0's F6 measured that
	## killer identity is not knowable (`NpcShip._die` emits position and archetype
	## only, `take_damage` records no source, and a rock or a peer can kill a hull), so
	## the pin's fallback applies: the handler itself is the gate.
	if AffixesScript.has_suffix(_launch_summary, FLAG_LEECHES):
		_heal_leeches()
	## S27 (15 section 4, `of the Pyre`, CONTRACTS section 20): the kill's ring. The
	## victim's hull share **before** the killing blow gates it (S27-F1: the post-blow
	## reading is always 0.0), and a positive `pyre_ring_damage` charges every NPC hull
	## inside `PYRE_RING_RADIUS` once.
	_detonate_pyre_ring(_position, ship)


## S27 (15 section 4, `of the Pyre`): the 50-damage ring a below-quarter-hull kill
## detonates. `Affixes.pyre_ring_damage` is the gate and the amount (0.0 for a launch
## with no Pyre, or a victim at or above the quarter line); a positive figure sweeps
## `PYRE_RING_RADIUS` around `at` and hands every NPC hull inside it one `take_damage`,
## the victim excluded. The share read is the victim's **pre-blow** hull fraction
## (`NpcShip.pre_hit_hull_fraction`), so a full-hull one-shot reads 1.0 and pays nothing.
## A victim that answers no `pre_hit_hull_fraction` (a bare stub) reads 0.0, which is
## below the quarter line.
func _detonate_pyre_ring(at: Vector2, victim: Node2D) -> void:
	var share := 0.0
	if victim != null and is_instance_valid(victim) and victim.has_method(&"pre_hit_hull_fraction"):
		share = float(victim.call(&"pre_hit_hull_fraction"))
	var damage := AffixesScript.pyre_ring_damage(_launch_summary, share)
	if damage <= 0.0:
		return
	for node: Node in get_tree().get_nodes_in_group(&"npc_ship"):
		var hull := node as Node2D
		if hull == null or not is_instance_valid(hull) or hull == victim:
			continue
		if hull.global_position.distance_to(at) > PYRE_RING_RADIUS:
			continue
		if hull.has_method(&"take_damage"):
			hull.call(&"take_damage", damage)


## 15 section 4's Leeches payout (CONTRACTS section 20): 5 % of the hull's own maximum
## back into the hull pool, clamped there. `set_hull` is the pool's own writer, so the
## `hull_changed` signal (and the HUD bar reading it) follows the perk. A scene with no
## state yet (a bare instance, a probe) is a no-op.
func _heal_leeches() -> void:
	if _state == null or _state.hull_max <= 0.0:
		return
	_state.set_hull(minf(_state.hull + LEECHES_FRACTION * _state.hull_max, _state.hull_max))


## 06 §8's kill roll and wreck site: the victim's 06 band table - since S23 (A6) the
## hunter's own promoted table, and every cache line scaled by 06 §7's sector-tier
## factor - held by a wreck site at the kill point for
## `LootTables.WRECK_PICKUP_LIFETIME`. A hull whose row names no table (the boss)
## leaves no site - 06 §3 has no table for it, and a site with
## nothing in it is not 06 §4's wreck.
func _spawn_kill_loot(kill_position: Vector2, _archetype: StringName, ship: Node2D) -> void:
	if _sector == null or ship == null:
		return
	if not ship.has_method(&"row"):
		return
	var row: Dictionary = ship.call(&"row")
	var kind := StringName(row.get(NpcRegistryScript.KEY_LOOT_KIND, &""))
	if kind == &"" or not LootTablesScript.has(kind):
		return
	## S23 A6: the hunter rolls its own promoted table (`hunter` = the fighter band's
	## lines with 06 §8's extra), so the band rolls exactly once - the old
	## `roll_band` + `roll_hunter_extra` double roll is gone - and every cache line
	## scales by 06 §7's sector-tier factor (`SectorRegistry.sector_tier`). The Maw's
	## own band is the one exception: 14 §5 / 06 §3.4 pin it flat (the 1 025 CR floor),
	## which `LootTables.cache_scale_for` owns.
	var scale := LootTablesScript.cache_scale_for(kind, Registry.sector_tier(_sector_row_id))
	var payload: Array[Dictionary] = LootTablesScript.roll_band(kind, 0, scale)
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


## S25 (14 section 2): the Hunt row, seen from the kill seam - "Destroy 5 pirates in S2".
## Only a pirate counts (the sector's swarmer and sibelon rows are not the row's own word) and
## only in the contract's own sector, so a hunt taken at a station is finished in that
## station's space. The credit itself is the registry's door; this scene answers what died.
func _credit_hunt_kills(profile: Node, archetype: StringName) -> void:
	if archetype != NpcRegistryScript.ARCHETYPE_PIRATE:
		return
	for result: Dictionary in ContractRegistryScript.credit_kill(
		profile, Registry.sector_number(_sector_row_id)
	):
		var paid := int(result.get(&"paid", 0))
		if paid > 0:
			_push_prompt(CONTRACT_DONE_PROMPT % paid)


## --- S25: the escort loop (14 section 6) --------------------------------------------


## One convoy per active escort contract accepted at this sector's station: "spawn point:
## the accepting station" (14 section 6). Read off the profile's active list, so the
## contract survives the dock/launch cycle and the convoy is rebuilt from it, while a
## contract that left the list (a loss, a cancel) is never re-spawned.
func _restore_escorts() -> void:
	_clear_escorts()
	if _sector == null or not _sector.has_station():
		return
	var profile := _profile()
	if profile == null:
		return
	var here := Registry.sector_number(_sector_row_id)
	for record: Dictionary in ContractRegistryScript.active(profile):
		if StringName(record.get(&"type", &"")) != ContractRegistryScript.TYPE_ESCORT:
			continue
		if int(record.get(&"origin_sector", 0)) != here:
			continue
		_spawn_escort_convoy(record)


## The convoy's own ships leave the tree - a crossing, a launch or a fresh population
## rebuilds them from the active list, so the old ones must not keep flying the old route.
func _clear_escorts() -> void:
	for key: String in _escorts.keys():
		_dismiss_convoy(_escorts[key], null)
	_escorts.clear()


## The convoy itself: "1 hauler-class AI hull + 1-2 fighter escorts" (14 section 6), the
## hauler carrying the plan's own pod count as visible cargo pods, all of them flying the
## fixed route to the target sector's gate at the hauler's own freighter speed.
func _spawn_escort_convoy(record: Dictionary) -> void:
	var spawns := NpcRegistryScript.convoy_spawns(_sector_row_id)
	if spawns.is_empty():
		return
	var plan := ContractRegistryScript.escort_plan(record)
	var station: Vector2 = _sector.call(&"station_position")
	var route := _escort_route(int(record.get(&"sector", 0)), station)
	var members: Array[Node2D] = []
	var hauler: Node2D = null
	for spawn: Dictionary in spawns:
		var role := NpcRegistryScript.convoy_role(spawn)
		if role == &"hauler":
			hauler = _make_convoy_hull(spawn, station, route)
			if hauler != null:
				members.append(hauler)
				_dress_convoy_pods(hauler, int(plan.get(&"pod_marks", 0)))
			continue
		for _index in int(plan.get(&"fighters", 0)):
			var fighter := _make_convoy_hull(spawn, station, route)
			if fighter != null:
				members.append(fighter)
	if hauler == null:
		return
	hauler.connect(&"died", _on_escort_hauler_died.bind(StringName(record.get(&"id", &"")), hauler))
	_escorts[String(record.get(&"id", &""))] = {
		&"record": record,
		&"hauler": hauler,
		&"members": members,
		&"route": route,
		&"gate": _escort_gate(int(record.get(&"sector", 0))),
		&"ambush": false,
		&"target": int(record.get(&"sector", 0)),
	}


## One convoy hull: the row's own archetype, hull, sprite and faction, homed at the
## accepting station and flying the contract's route (the PATROL state's fixed route).
func _make_convoy_hull(spawn: Dictionary, station: Vector2, route: Array[Vector2]) -> Node2D:
	var archetype := StringName(spawn.get(NpcRegistryScript.KEY_ARCHETYPE, &""))
	var hull_id := StringName(spawn.get(NpcRegistryScript.KEY_HULL_ID, &""))
	var ship: Node2D = NpcShipScript.new() as Node2D
	if ship == null:
		return null
	ship.name = "Convoy%s" % String(hull_id).to_pascal_case()
	add_child(ship)
	ship.global_position = station
	ship.call(
		&"setup",
		archetype,
		ShipFitScript.resolve(hull_id, ShipFitScript.STANDARD_FIT),
		hull_id,
		{
			NpcShipScript.OPT_HOME: station,
			NpcShipScript.OPT_ROUTE: route,
			NpcShipScript.OPT_SPACE_OWNER: StringName(
				spawn.get(NpcRegistryScript.KEY_FACTION_ID, &"")
			),
			NpcShipScript.OPT_SPRITE_PATH: String(
				spawn.get(NpcRegistryScript.KEY_SPRITE_PATH, "")
			),
		}
	)
	return ship


## 14 section 6's "50 % of hold filled with visible cargo pods": the plan's own pod marks,
## in the shipped pickup pod's own art, laid along the hauler's hold line. They are the
## convoy's visible load - the number the contract carries is the same hold, and a loss
## drops it (the pirates keep the loot).
func _dress_convoy_pods(hauler: Node2D, marks: int) -> void:
	if marks <= 0:
		return
	var texture := load(ContractRegistryScript.ESCORT_POD_TEXTURE) as Texture2D
	if texture == null:
		return
	for index in marks:
		var pod := Sprite2D.new()
		pod.name = "CargoPod%d" % (index + 1)
		pod.texture = texture
		pod.scale = Vector2.ONE * POD_MARK_SCALE
		pod.position = Vector2(
			(float(index) - float(marks - 1) * 0.5) * POD_MARK_SPACING, POD_MARK_OFFSET
		)
		pod.z_index = -1
		hauler.add_child(pod)


## The route's world points, in `ContractRegistry.ESCORT_LEGS` order: the accepting station,
## the corridor midpoint toward the target (11 section 2.2's ambush site) and that gate.
func _escort_route(target_sector: int, station: Vector2) -> Array[Vector2]:
	var route: Array[Vector2] = [station]
	var midpoint := station
	if _sector != null:
		for corridor: Node in _sector.call(&"corridors"):
			if corridor == null or not is_instance_valid(corridor):
				continue
			if int(corridor.get(&"dest_sector")) != target_sector:
				continue
			var band: Rect2 = corridor.get(&"edge")
			midpoint = corridor.to_global(band.get_center())
			break
	var gate := _escort_gate(target_sector)
	if midpoint == station and gate != null:
		midpoint = gate.global_position
	route.append(midpoint)
	route.append(gate.global_position if gate != null else midpoint)
	return route


## The ring the convoy has to reach: the corridor's own gate to the target sector (14
## section 6's "target sector's gate").
func _escort_gate(target_sector: int) -> Node:
	if _sector == null:
		return null
	for gate: Node in _sector.call(&"gates"):
		if gate == null or not is_instance_valid(gate):
			continue
		if int(gate.get(&"dest_sector")) == target_sector:
			return gate
	return null


## One escort step: the corridor-midpoint ambush fires once per convoy (11 section 2.2),
## and the hauler reaching the target's gate ring pays the contract at the destination.
func _update_escorts(_delta: float) -> void:
	if _escorts.is_empty():
		return
	var arrived: Array[String] = []
	for key: String in _escorts.keys():
		var state: Dictionary = _escorts[key]
		var hauler: Node2D = state.get(&"hauler")
		if hauler == null or not is_instance_valid(hauler):
			continue
		var route: Array = state.get(&"route", [])
		if route.size() < ContractRegistryScript.ESCORT_LEGS.size():
			continue
		var midpoint: Vector2 = route[ContractRegistryScript.ESCORT_AMBUSH_LEG]
		if not bool(state.get(&"ambush", false)):
			if hauler.global_position.distance_to(midpoint) <= ContractRegistryScript.ESCORT_AMBUSH_RADIUS:
				state[&"ambush"] = true
				_spawn_escort_ambush(midpoint)
		var gate: Node = state.get(&"gate")
		if gate != null and is_instance_valid(gate):
			if bool(gate.call(&"contains", hauler.global_position)):
				arrived.append(key)
	for key: String in arrived:
		_finish_escort(key)


## 14 section 6's "pirates ambush at the corridor midpoint": the sector's own pirate band
## (`spawns_for`'s pirate row), one wing, re-homed on the ambush point through the same
## `_add_npc` seam the hunter wing uses - so the ambushers are the sector's own hulls, with
## its own blips, loot and respawn bookkeeping.
func _spawn_escort_ambush(at: Vector2) -> void:
	if _sector == null or not _sector.has_method(&"_add_npc"):
		return
	for spawn: Dictionary in NpcRegistryScript.spawns_for(_sector_row_id):
		if (
			StringName(spawn.get(NpcRegistryScript.KEY_ARCHETYPE, &""))
			!= NpcRegistryScript.ARCHETYPE_PIRATE
		):
			continue
		var count := _rng_band(spawn)
		for index in count:
			_sector.call(&"_add_npc", spawn)
			_home_ambusher(index, count, at)
		return


## Where one ambusher is placed: the corridor midpoint, spread on a small ring so the wing
## arrives as a wing. The hull's body is the mover, so both are set (the hunter wing's own
## idiom) and the node reads right for a caller that never advances a frame.
func _home_ambusher(index: int, count: int, at: Vector2) -> void:
	var npcs: Array = _sector.call(&"npcs")
	if npcs.is_empty():
		return
	var hull := npcs[npcs.size() - 1] as Node2D
	if hull == null or not is_instance_valid(hull):
		return
	var bearing := TAU * float(index) / float(maxi(count, 1))
	var place := at + Vector2(AMBUSH_SPAWN_RADIUS, 0.0).rotated(bearing)
	hull.global_position = place
	if hull.has_method(&"impact_body"):
		var body := hull.call(&"impact_body") as RigidBody2D
		if body != null:
			body.global_position = place
	if hull.has_method(&"set_home"):
		hull.call(&"set_home", place)


## The band's own count for one spawn row, rolled on the scene's own stream.
func _rng_band(spawn: Dictionary) -> int:
	var low := int(spawn.get(NpcRegistryScript.KEY_MIN, 0))
	var high := int(spawn.get(NpcRegistryScript.KEY_MAX, low))
	if high < low:
		high = low
	if high <= 0:
		return 0
	return randi_range(maxi(low, 1), high)


## The hauler's own `died`: 14 section 6's loss row (no payout, -5 standing, the pirates
## keep the loot) and the convoy's own ships stand down.
func _on_escort_hauler_died(position: Vector2, _archetype: StringName, contract_id: StringName, hauler: Node2D) -> void:
	var key := String(contract_id)
	var state: Dictionary = _escorts.get(key, {})
	var profile := _profile()
	if profile != null:
		var result := ContractRegistryScript.escort_lost(profile, contract_id)
		for raw_id: Variant in (result.get(&"loot", {}) as Dictionary).keys():
			_spawn_drop(StringName(raw_id), int(result[&"loot"][raw_id]), position)
		_push_prompt("CONVOY LOST · %d STANDING" % ContractRegistryScript.STANDING_LOSS)
	_dismiss_convoy(state, hauler)
	_escorts.erase(key)


## The convoy reached its gate: 14 section 6's win row pays the contract at the destination
## station, and the ships stand down.
func _finish_escort(key: String) -> void:
	var state: Dictionary = _escorts.get(key, {})
	var profile := _profile()
	if profile != null:
		var record: Dictionary = state.get(&"record", {})
		var result := ContractRegistryScript.escort_won(profile, StringName(key))
		if bool(result.get(&"ok", false)):
			var destination := StringName(record.get(&"target_station", &""))
			_push_prompt(
				"CONVOY ARRIVED · %s · %d CR"
				% [
					String(StationRegistryScript.station(destination).get(&"name", destination)),
					int(result.get(&"paid", 0)),
				]
			)
	_dismiss_convoy(state, null)
	_escorts.erase(key)


## The convoy's ships leave the tree (14 section 6's one convoy, one route).
func _dismiss_convoy(state: Dictionary, except: Node2D) -> void:
	for member: Node2D in state.get(&"members", []):
		if member == null or not is_instance_valid(member) or member == except:
			continue
		member.call(&"despawn")


## --- S26: the arenas and their bosses (14 section 5) --------------------------------


## The zone the current sector carries, `{}` for a sector with no arena.
func _arena_zone() -> Dictionary:
	return NpcRegistryScript.arena_zone(Registry.sector_number(_sector_row_id))


## 14 section 5: the arena is a physical place - a marked, barricaded ring of nav pylons,
## visible from any distance. Built from the shipped arena props (`env_arena_nav_pylon` /
## `env_arena_barricade`) as a child of the sector, so it rides the sector's own transform;
## no art is generated and entering it without an active run does nothing but mark it.
func _build_arena_zone() -> void:
	if _arena_zone_node != null and is_instance_valid(_arena_zone_node):
		_arena_zone_node.free()
	_arena_zone_node = null
	var zone := _arena_zone()
	if zone.is_empty() or _sector == null:
		return
	var ring := Node2D.new()
	ring.name = &"ArenaZone"
	_sector.add_child(ring)
	ring.global_position = _sector.to_global(zone.get(&"centre", Vector2.ZERO))
	var radius := NpcRegistryScript.ARENA_ZONE_RADIUS
	var pylon_count := NpcRegistryScript.ARENA_ZONE_PYLONS
	for index in pylon_count:
		var bearing := TAU * float(index) / float(maxi(pylon_count, 1))
		var pylon := _make_arena_mark(
			NpcRegistryScript.PYLON_TEXTURE, NpcRegistryScript.PYLON_DRAW_SIZE
		)
		if pylon != null:
			ring.add_child(pylon)
			pylon.position = Vector2(radius, 0.0).rotated(bearing)
	var barricade_count := NpcRegistryScript.ARENA_ZONE_BARRICADES
	for index in barricade_count:
		var bearing := TAU * (float(index) + 0.5) / float(maxi(barricade_count, 1))
		var barricade := _make_arena_mark(
			NpcRegistryScript.BARRICADE_TEXTURE, NpcRegistryScript.BARRICADE_DRAW_SIZE
		)
		if barricade != null:
			ring.add_child(barricade)
			barricade.position = Vector2(radius, 0.0).rotated(bearing)
			barricade.rotation = bearing + PI * 0.5
	_arena_zone_node = ring


## One shipped arena prop as a scaled sprite mark. A missing texture draws nothing rather
## than erroring (the `sprite_path` tolerance).
func _make_arena_mark(texture_path: String, size: float) -> Sprite2D:
	var texture := load(texture_path) as Texture2D
	if texture == null:
		return null
	var sprite := Sprite2D.new()
	sprite.texture = texture
	var texture_size := texture.get_size()
	if texture_size.x > 0.0:
		var factor := size / texture_size.x
		sprite.scale = Vector2(factor, factor)
	return sprite


## 14 section 5's arena run, seen from the flight side: while a run is open for this
## sector's boss (the active Expedition contract inside its 60 s window), entering the ring
## spawns the boss; a run outside its window, or a sector with no arena, does nothing.
func _update_arena(_delta: float) -> void:
	if _arena_boss != null and is_instance_valid(_arena_boss):
		return
	var zone := _arena_zone()
	if zone.is_empty() or _ship == null or _sector == null:
		return
	var contract := _open_arena_contract()
	if contract.is_empty():
		return
	var centre: Vector2 = _sector.to_global(zone.get(&"centre", Vector2.ZERO))
	if _ship.global_position.distance_to(centre) > NpcRegistryScript.ARENA_ZONE_ENTRY_RADIUS:
		return
	_spawn_arena_boss(StringName(contract.get(&"boss", &"")), centre)


## The one active Expedition contract whose 60 s window is still open and whose boss is
## this sector's arena boss, `{}` otherwise.
func _open_arena_contract() -> Dictionary:
	var profile := _profile()
	if profile == null or not profile.has_method(&"contracts"):
		return {}
	var boss := NpcRegistryScript.arena_boss(Registry.sector_number(_sector_row_id))
	if boss == &"":
		return {}
	var now := ClockScript.now()
	for record: Dictionary in (profile.call(&"contracts") as Array):
		if not ContractRegistryScript.is_expedition(record):
			continue
		if ContractRegistryScript.arena_boss_of(record) != boss:
			continue
		if ContractRegistryScript.arena_entry_open(record, now):
			return record
	return {}


## One arena boss: the R-S26-1 vitals (`NpcRegistry.boss_stats`) on its own render, homed
## at the ring centre. Its death flows through the same `_on_npc_died` seam every hull
## uses, so heat, loot and the kill credit need no second path.
func _spawn_arena_boss(boss_id: StringName, centre: Vector2) -> void:
	if _sector == null or boss_id == &"":
		return
	var stats := NpcRegistryScript.boss_stats(boss_id)
	if stats == null:
		return
	var ship: Node2D = NpcShipScript.new() as Node2D
	if ship == null:
		return
	ship.name = "ArenaBoss%s" % String(boss_id).to_pascal_case()
	_sector.add_child(ship)
	ship.global_position = centre
	ship.call(
		&"setup",
		boss_id,
		stats,
		boss_id,
		{
			NpcShipScript.OPT_HOME: centre,
			NpcShipScript.OPT_SPACE_OWNER: NpcRegistryScript.space_owner(_sector_row_id),
			NpcShipScript.OPT_SPRITE_PATH: NpcRegistryScript.boss_sprite(boss_id),
		}
	)
	if ship.has_signal(&"died") and not ship.is_connected(&"died", _on_npc_died):
		ship.connect(&"died", _on_npc_died.bind(ship))
	_arena_boss = ship


## The Maw's roam (14 section 5, E2 PROPOSED): it spawns in S7 and re-spawns on the
## 20-minute clock after it dies.
func _update_maw(delta: float) -> void:
	if Registry.sector_number(_sector_row_id) != NpcRegistryScript.MAW_ROAM_SECTOR:
		return
	if _maw_node != null and is_instance_valid(_maw_node):
		return
	if _maw_respawn > 0.0:
		_maw_respawn -= delta
		if _maw_respawn > 0.0:
			return
	_spawn_maw()


func _spawn_maw() -> void:
	if _sector == null:
		return
	var stats := NpcRegistryScript.boss_stats(NpcRegistryScript.ARCHETYPE_MAW)
	if stats == null:
		return
	var ship: Node2D = NpcShipScript.new() as Node2D
	if ship == null:
		return
	ship.name = "Maw"
	var place := NpcRegistryScript.maw_spawn_point()
	_sector.add_child(ship)
	ship.global_position = place
	ship.call(
		&"setup",
		NpcRegistryScript.ARCHETYPE_MAW,
		stats,
		NpcRegistryScript.ARCHETYPE_MAW,
		{
			NpcShipScript.OPT_HOME: place,
			NpcShipScript.OPT_SPACE_OWNER: NpcRegistryScript.space_owner(_sector_row_id),
			NpcShipScript.OPT_SPRITE_PATH: NpcRegistryScript.boss_sprite(
				NpcRegistryScript.ARCHETYPE_MAW
			),
		}
	)
	if ship.has_signal(&"died") and not ship.is_connected(&"died", _on_npc_died):
		ship.connect(&"died", _on_npc_died.bind(ship))
	_maw_node = ship


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


## Section 7's death flow, in §7's own order: hull 0 → the wreck's explosion (the blast's
## face and the shockwave §13's `EXPLOSION_P0` is labelled for), the hold dropped at the
## wreck with its recovery window, then a respawn docked. 14 §3's insurance, the mercy
## clause and the hull replacement are slice 4 and are reported, not guessed.
##
## The hull's own half is `PlayerShip.die` (L24's real death state: no input, no force or
## torque, a contact monitor that charges nothing) and it runs **first**, because the blast
## hangs off the death and §7 puts the explosion before the wreck; this scene's own gate -
## the `player_ship` group - follows in `_switch_ship_off`.
##
## Nothing is filed to the profile's vitals here on purpose: a 0-hull record would be the
## next launch's starting state, and the ship that comes back is 14 §3's business.
func _on_ship_died() -> void:
	if _dead:
		return
	_dead = true
	_cancel_lock()
	## L152: a charge-up that outlived the hull would cross the sector from a wreck.
	_cancel_gate_charge()
	_switch_ship_off()
	if _hud != null:
		_hud.call(&"clear_target")
		_hud.call(&"set_prompt", "")
		_hud.call(&"set_warp_channel", 0.0)
		_hud.call(&"set_speedometer", 0.0, Vector2.ZERO, Vector2.ZERO)
	_explode_wreck()
	_drop_cargo_at_wreck()
	_respawn_docked()


## The wiring's own half of the death: the wreck leaves the `player_ship` group, because a
## wreck is not a hull anything tractors to - without that, the hold's pickups (spawned on
## the wreck) would be pulled straight back aboard by the dead ship and an uncollected death
## would cost nothing - and the weapon component stops ticking. The hull's own inertness is
## `PlayerShip.die`'s (L24: a state on the hull, not this function's switch-off).
func _switch_ship_off() -> void:
	if _ship != null:
		_ship.call(&"die")
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
## §5 rule 2) as one pickup per stack, one `economy_log` line each, and the window is
## `DROP_WINDOW` carried on the pickup's own lifetime argument *and* filed in the sector
## ledger, so the respawn route's scene rebuild re-materialises the drop instead of ending
## the window with the scene that drew it (L23; `_wreck_drops`).
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
## cargo pickup. The entry is the window's record - an absolute `DROP_WINDOW` ahead on the
## WorldClock, so a scene that comes later can hand the pickup the seconds it has left -
## and the pickup is its visible face, carrying the same figure through `Pickup.setup`'s
## lifetime argument.
func _spawn_drop(item_id: StringName, amount: int, wreck: Vector2) -> void:
	var entry := {
		&"sector": String(_sector_row_id),
		&"position": wreck,
		&"item": item_id,
		&"amount": amount,
		&"expires": ClockScript.now() + int(DROP_WINDOW),
		&"face": null,
	}
	_wreck_drops.append(entry)
	entry[&"face"] = _materialise_drop(entry, DROP_WINDOW)


## Every wreck drop this sector still has inside its window, as live pickups. The window
## is the ledger's (an absolute stamp), so a scene that boots mid-window - after the
## respawn route, after a crossing - hands each entry the seconds it has left through the
## same `Pickup.setup` lifetime seam a fresh drop uses, and an entry past its stamp is
## dropped for good. Called from `_spawn_sector`, the one place that knows which sector
## this scene is in (a crossing re-spawns the sector inside the same scene, so the faces
## of the sector being left come down first).
func _materialise_wreck_drops() -> void:
	_clear_drop_faces()
	var now := ClockScript.now()
	var sector := String(_sector_row_id)
	for i in range(_wreck_drops.size() - 1, -1, -1):
		var entry: Dictionary = _wreck_drops[i]
		var expires := int(entry.get(&"expires", 0))
		if expires <= now:
			_wreck_drops.remove_at(i)
			continue
		if String(entry.get(&"sector", "")) != sector:
			continue
		entry[&"face"] = _materialise_drop(entry, float(expires - now))


## One ledger entry's face: the pickup itself, positioned at the wreck and carrying the
## seconds `window` says are left. The same `Pickup.collected` signal a *fresh* drop is
## wired to, so a stack taken aboard leaves the ledger the moment it is taken.
func _materialise_drop(entry: Dictionary, window: float) -> Node2D:
	var pickup: Node2D = PickupScript.new() as Node2D
	add_child(pickup)
	pickup.global_position = entry[&"position"]
	pickup.call(&"setup", entry[&"item"], int(entry[&"amount"]), false, window)
	pickup.connect(&"collected", _on_wreck_drop_collected.bind(pickup))
	_drop_faces.append(pickup)
	return pickup


## The ledger's other door: a collected stack is gone, so its entry goes with it. The face
## is the entry's own, compared by identity (Objects compare by instance).
func _on_wreck_drop_collected(_item_id: StringName, _amount: int, face: Node2D) -> void:
	for i in range(_wreck_drops.size() - 1, -1, -1):
		if _wreck_drops[i].get(&"face") == face:
			_wreck_drops.remove_at(i)
			return


## Takes this scene's drop faces down without touching the ledger: a sector change destroys
## the pickups the old sector was drawn with, and the entries outlive them by design.
func _clear_drop_faces() -> void:
	for face: Node2D in _drop_faces:
		if is_instance_valid(face):
			face.free()
	_drop_faces.clear()
	for entry: Dictionary in _wreck_drops:
		entry[&"face"] = null


## 14 §3's first clause, the only one this slice can honour: "on death you respawn docked
## at the last station visited". In a session the last station visited *is* the one being
## orbited (the player launched from it), so the respawn is the same dock route the dock
## prompt and the safe warp use. A sector with no station (S7) has nowhere to respawn and
## says so; the insurance payout, the mercy clause and the replacement hull are slice 4.
func _respawn_docked() -> void:
	## S26 (14 section 5): a death is a return-to-station, so any open arena run closes
	## here (win or lose), and 14 section 3's payout flow runs (the hull+fit credit and the
	## replacement hull; the mercy clause is the profile's own).
	_settle_arena_runs()
	_apply_insurance_payout()
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
	## L154: this route lands the station, never a game scene, so a crossing flag that never
	## found its successor must not survive it (`_clear_transit_flag`, `_request_dock`'s own
	## reason).
	_clear_transit_flag()
	route_requested.emit(ROUTE_LOADING, {PARAM_DESTINATION: DESTINATION_STATION})


## S26 (14 section 3, M14): the launch's insurance charge. The policy is the profile's
## own toggle; a launch whose purse cannot pay the premium simply flies uninsured (the
## launch is not refused), so this never blocks.
func _charge_insurance() -> void:
	var profile := _profile()
	if profile == null or not profile.has_method(&"insurance_charge"):
		return
	profile.call(&"insurance_charge")


## S26 (14 section 3): the death's payout flow, run at the respawn. The profile owns the
## arithmetic (the hull+fit credit, the replacement hull, the mercy clause); this scene
## only reports the credit.
func _apply_insurance_payout() -> void:
	var profile := _profile()
	if profile == null or not profile.has_method(&"insurance_payout"):
		return
	var result: Dictionary = profile.call(&"insurance_payout")
	var credited := int(result.get(&"credited", 0))
	if credited > 0:
		_push_prompt("INSURANCE PAYOUT · %d CR" % credited)
