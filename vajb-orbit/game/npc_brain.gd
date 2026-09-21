class_name NpcBrain
extends RefCounted
## One brain for every NPC hull (ENGINE_SPEC section 5): the state set
## **Idle -> Patrol/Scan -> Alert (LOS check, rocks block) -> Engage (hold preferred
## range, strafe) -> Flee -> Return/Despawn**, driven by the archetype table of
## `npc_registry.gd` rather than by per-archetype code.
##
## The brain decides, the hull flies: `tick` reads a context the hull fills from its own
## frame (position, heading, hull fraction, the spawn POI, the player's heat tier, the
## live contacts) and returns an *intent* (state, a waypoint, a speed fraction, a fire
## flag). `NpcShip` then steers to the waypoint with the same physics law and the same
## `ShipStats` snapshot the player's hull uses - spec decision 1, "no separate NPC
## physics" - so this file owns no force, no torque and no speed.
##
## **The line-of-sight check is injected**, not built here: `set_line_of_sight` takes a
## `Callable(from, to) -> bool` and `NpcShip` installs the shipping physics ray (the rock
## layer, section 5's "rocks block"). With no callable the check is clear, which is what
## lets the state machine be walked on synthetic positions with no physics world at all.
##
## **Numbers.** Section 13 owns the rails: `AGGRO_COOLDOWN` 5 s and the leash 2 500 u are
## constants here, every aggro/scan radius is a `npc_registry` row and the flee
## thresholds are row data too (pirate below 30 % hull, trader on Suspect+). The brain
## states none of them twice.
##
## **What this file deliberately does not do.** It fires nothing: `fire` is an intent for
## a hull that carries a weapon, and no doc gives an NPC hull a weapon family, a damage
## figure or a turret's "high damage" number, so slice 2 ships the intent and the report
## raises the gap (brief ruling four: a missing spec value is reported, not guessed).
##
## Contract: docs/gameplay/18_engine_spec.md sections 5, 7, 8 and 13; docs/gameplay/13
## sections 2-5; the slice-2 brief's pinned interface item 6.

## The one state set (pinned interface item 6), in the order section 5 names it.
enum State { IDLE, PATROL, SCAN, ALERT, ENGAGE, FLEE, RETURN, DESPAWN }

const STATE_NAMES: Array[StringName] = [
	&"idle",
	&"patrol",
	&"scan",
	&"alert",
	&"engage",
	&"flee",
	&"return",
	&"despawn",
]

## Section 13: "Aggro radii ... leash 2 500" and "`AGGRO_COOLDOWN` 5 s (aggro clears;
## warp becomes available)". The cooldown is section 5's "aggro clears when the player
## leaves the radius for AGGRO_COOLDOWN", which is the same 5 s row.
const AGGRO_COOLDOWN := 5.0
const LEASH_RADIUS := 2500.0

## The patrol walk's leg step: the brain holds station on its own POI by walking the
## compass around it, a quarter turn per leg. It is a shape, not a spec number - no doc
## states a patrol radius, so the leg itself reuses the row's own aggro radius
## (`_patrol_leg_radius`), which is where the "guards asteroid fields" stand-off lives.
const PATROL_LEG_TURN := PI * 0.5

const NpcRegistryScript := preload("res://game/npc_registry.gd")

## The context keys the hull fills (`tick`) and the intent keys it reads back. Named once
## so neither side spells a string.
const CTX_POS: StringName = &"pos"
const CTX_HULL_FRACTION: StringName = &"hull_fraction"
const CTX_HOME: StringName = &"home"
const CTX_HEAT_TIER: StringName = &"heat_tier"
const CTX_CONTACTS: StringName = &"contacts"
const CTX_ATTACKED: StringName = &"attacked"

const INTENT_STATE: StringName = &"state"
const INTENT_WAYPOINT: StringName = &"waypoint"
const INTENT_SPEED: StringName = &"speed"
const INTENT_FIRE: StringName = &"fire"
const INTENT_TARGET_POS: StringName = &"target_pos"
const INTENT_LOS: StringName = &"los"
const INTENT_DESPAWN: StringName = &"despawn"

## One full-throttle cruise and a stopped hull, the only two speeds an intent carries:
## the hull's own arrive steering ramps a leg down as it closes on it (the section 13
## autopilot radii), so no fraction between them is invented here.
const CRUISE := 1.0
const HOLD := 0.0

var _archetype: StringName = &""
var _row: Dictionary = {}
var _home := Vector2.ZERO
var _has_home := false
var _route: Array[Vector2] = []
var _route_index := 0
var _leg_bearing := 0.0
var _strafe := 1.0
var _los: Callable = Callable()

var _state := State.IDLE
var _target: Node2D = null
var _has_target := false
var _target_pos := Vector2.ZERO
var _aggro_lost := 0.0


## Launch handshake: the archetype id and its registry row (pinned interface item 6 -
## the archetype table drives the differences). `home` is the spawn POI the leash is
## measured from (section 5).
func setup(archetype: StringName, row: Dictionary, home := Vector2.ZERO) -> void:
	_archetype = archetype
	_row = row.duplicate(true)
	set_home(home)
	_state = State.IDLE
	_target = null
	_has_target = false
	_target_pos = Vector2.ZERO
	_aggro_lost = 0.0
	_route.clear()
	_route_index = 0
	_leg_bearing = 0.0
	_strafe = 1.0


## The injected LOS check: `Callable(from: Vector2, to: Vector2) -> bool`, true when
## nothing blocks the line. `NpcShip` installs the rock-layer ray; a probe that walks the
## states on synthetic positions leaves it unset (clear) or installs its own verdict.
func set_line_of_sight(check: Callable) -> void:
	_los = check


func set_home(pos: Vector2) -> void:
	_home = pos
	_has_home = true
	_leg_bearing = 0.0


## A fixed route for the PATROL state (doc 11 section 3's convoy, "flies fixed route").
## Without one a hull patrols around its own POI.
func set_route(points: Array[Vector2]) -> void:
	_route = points.duplicate()
	_route_index = 0


func state() -> int:
	return _state


func state_name() -> StringName:
	return STATE_NAMES[_state]


## True while this brain holds an aggro: section 5's Alert or Engage. This is the state
## section 7's safe-warp gate asks about ("no hostile in Alert/Engage targeting the
## player"), and the grace that keeps it true for AGGRO_COOLDOWN after the contact has
## left the radius is why the gate stays shut through that window.
func is_engaged() -> bool:
	return _state == State.ALERT or _state == State.ENGAGE


func archetype() -> StringName:
	return _archetype


func row() -> Dictionary:
	return _row


## The live target the aggro is held on, or null. This is what `NpcShip.engaged_with`
## reports for the safe-warp gate (section 7: "hostile in Alert/Engage targeting the
## player").
func target() -> Node2D:
	return _target if _target != null and is_instance_valid(_target) else null


func target_position() -> Vector2:
	return _target_pos


## The radius a hostile contact is acquired at (section 13's per-archetype row).
func aggro_radius() -> float:
	return float(_row.get(NpcRegistryScript.KEY_AGGRO_RADIUS, 0.0))


## The radius an aggro is released at: a turret holds on "until scan range clears"
## (section 5) and section 13 states no turret scan radius, so a row with no scan radius
## releases at its own aggro radius rather than at an invented figure.
func release_radius() -> float:
	var scan := float(_row.get(NpcRegistryScript.KEY_SCAN_RADIUS, 0.0))
	return scan if scan > 0.0 else aggro_radius()


func scan_radius() -> float:
	return float(_row.get(NpcRegistryScript.KEY_SCAN_RADIUS, 0.0))


func is_static() -> bool:
	return bool(_row.get(NpcRegistryScript.KEY_STATIC, false))


## The external recycle (section 5's "Return/Despawn" and its spawn model: the sector
## populates on entry and re-rolls on the 20-minute clock). A despawn is not a kill: the
## hull frees itself without the death flow.
func request_despawn() -> void:
	_state = State.DESPAWN


## One frame of the brain. See the file doc for the context and intent keys.
func tick(delta: float, ctx: Dictionary) -> Dictionary:
	var pos := _vector(ctx.get(CTX_POS, _home))
	var hull_fraction := float(ctx.get(CTX_HULL_FRACTION, 1.0))
	var heat_tier := StringName(ctx.get(CTX_HEAT_TIER, NpcRegistryScript.HEAT_CLEAN))
	var attacked := bool(ctx.get(CTX_ATTACKED, false))
	var contacts := _contacts(ctx)

	var threat := _nearest(pos, contacts, heat_tier, attacked, true)
	var suspect := _nearest(pos, contacts, heat_tier, attacked, false)
	var in_aggro := not threat.is_empty() and pos.distance_to(_contact_pos(threat)) <= aggro_radius()
	var in_scan := (
		not suspect.is_empty()
		and scan_radius() > 0.0
		and pos.distance_to(_contact_pos(suspect)) <= scan_radius()
	)
	if in_aggro:
		_aggro_lost = 0.0
	else:
		_aggro_lost += delta

	_step_state(pos, hull_fraction, heat_tier, in_aggro, in_scan, threat, suspect)
	return _intent(pos, threat, suspect)


## Section 5's transitions, in the order they must be read: a flight outranks everything,
## the leash ends a chase that has run past the hull's POI, and an aggro is held for
## `AGGRO_COOLDOWN` after its contact leaves the radius.
func _step_state(
	pos: Vector2,
	hull_fraction: float,
	heat_tier: StringName,
	in_aggro: bool,
	in_scan: bool,
	threat: Dictionary,
	suspect: Dictionary
) -> void:
	if _state == State.DESPAWN:
		return
	var fleeing := _must_flee(hull_fraction, heat_tier)
	var leash_broken := _has_home and pos.distance_to(_home) > LEASH_RADIUS
	if _state == State.FLEE:
		## The flight's own exits: the reason is gone (a hull that recovered, a tier that
		## cooled) or the hull has run past its leash and is on its way home.
		if not fleeing or leash_broken:
			_set_state(State.RETURN)
		return
	if fleeing:
		_set_state(State.FLEE)
		return
	if leash_broken:
		_set_state(State.RETURN)
		return
	if in_aggro:
		_hold(threat)
		_set_state(State.ENGAGE if _los_clear(pos, _contact_pos(threat)) else State.ALERT)
		return
	if _state == State.ALERT or _state == State.ENGAGE:
		## Section 5's grace: the hull keeps its aggro - and so the safe warp stays shut -
		## until the contact has been out of its radius for the whole AGGRO_COOLDOWN.
		if _aggro_lost < AGGRO_COOLDOWN and _has_target:
			return
		_drop_target()
		_set_state(State.RETURN)
		return
	if in_scan:
		### A scan is section 5's "scans Suspect+ on sight": the patrol holds station at
		### its scan radius and watches, without opening fire (it attacks Outlaws, and an
		### Outlaw contact is a threat, handled above).
		_hold(suspect)
		_set_state(State.SCAN)
		return
	if _state == State.SCAN:
		_set_state(State.PATROL)
		return
	if _state == State.RETURN:
		if not _has_home or pos.distance_to(_home) <= PlayerShip.ARRIVE_RADIUS:
			_set_state(State.IDLE)
		return
	if is_static():
		## A station turret has nowhere to patrol: with nothing to shoot at it waits on
		## its mount (section 5's "static"), and its aggro ends back here.
		_set_state(State.IDLE)
		return
	_set_state(State.PATROL)


## The intent for the state the transitions landed on: where to steer, how fast, whether
## to fire, and whether the hull has been told to recycle itself.
func _intent(pos: Vector2, threat: Dictionary, suspect: Dictionary) -> Dictionary:
	var waypoint := pos
	var speed := HOLD
	var fire := false
	var los := false
	var threat_pos := _contact_pos(threat) if not threat.is_empty() else _target_pos
	match _state:
		State.PATROL:
			waypoint = _patrol_waypoint(pos)
			speed = CRUISE
		State.SCAN:
			## Hold the scan ring: stand off at scan range on our own side of the contact,
			## so the hull comes about and watches rather than closing to knife range.
			waypoint = _standoff(pos, _contact_pos(suspect), scan_radius())
			speed = CRUISE
		State.ALERT:
			## Section 5's alert is the beat before the engage: close on the contact.
			waypoint = _standoff(pos, threat_pos, aggro_radius())
			speed = CRUISE
		State.ENGAGE:
			## "Hold preferred range, strafe": orbit the contact on the stand-off ring and
			## walk the ring's side when the hull arrives, so the fight is a circle and not
			## a collision. No doc states a per-archetype stand-off range, so the row's own
			## aggro radius is the ring (reported, not guessed).
			var ring := _orbit(pos, threat_pos, aggro_radius())
			waypoint = ring
			speed = CRUISE
			los = _los_clear(pos, threat_pos)
			fire = los and not threat.is_empty()
			if pos.distance_to(ring) <= PlayerShip.ARRIVE_RADIUS:
				_strafe = -_strafe
		State.FLEE:
			## Run: section 5's pirate runs from a hull threshold, the convoy from the
			## player's tier. The sprint aims a leash-length away from the contact, and the
			## leash itself brings a hull that has run too far home.
			var away := _away(pos, threat_pos)
			waypoint = pos + away * LEASH_RADIUS
			speed = CRUISE
		State.RETURN:
			waypoint = _home
			speed = CRUISE
		State.DESPAWN:
			waypoint = pos
			speed = HOLD
	if is_static():
		## Section 5's turret is static: it never thrusts and never turns, whatever the
		## state wants, so the hull's own physics keeps it bolted where it was spawned.
		waypoint = pos
		speed = HOLD
	if _state == State.DESPAWN:
		_drop_target()
	var intent := {
		INTENT_STATE: state_name(),
		INTENT_WAYPOINT: waypoint,
		INTENT_SPEED: speed,
		INTENT_FIRE: fire,
		INTENT_TARGET_POS: threat_pos,
		INTENT_LOS: los,
		INTENT_DESPAWN: _state == State.DESPAWN,
	}
	return intent


## A patrol leg: the fixed route's current point when the hull has one, else a point on
## the compass around its own POI, advanced a quarter turn every time the hull arrives.
## Having no hull, the brain cannot measure arrival itself, so the caller's own position
## and the section 13 arrive radius decide the advance.
func _patrol_waypoint(pos: Vector2) -> Vector2:
	if not _route.is_empty():
		var point := _route[_route_index % _route.size()]
		if pos.distance_to(point) <= PlayerShip.ARRIVE_RADIUS:
			_route_index = (_route_index + 1) % _route.size()
		return point
	var radius := _patrol_leg_radius()
	var leg := _home + Vector2.RIGHT.rotated(_leg_bearing) * radius
	if pos.distance_to(leg) <= PlayerShip.ARRIVE_RADIUS:
		_leg_bearing += PATROL_LEG_TURN
		leg = _home + Vector2.RIGHT.rotated(_leg_bearing) * radius
	return leg if _has_home else pos


## The patrol leg's radius: the row's own aggro radius, so a hull that "guards asteroid
## fields" walks the ring it defends and no new radius is invented.
func _patrol_leg_radius() -> float:
	return aggro_radius()


## The point on the near side of `other` at `range` from it: closing to the contact ends
## there rather than at the contact's centre.
func _standoff(pos: Vector2, other: Vector2, range_: float) -> Vector2:
	var offset := pos - other
	if offset.is_zero_approx():
		return other
	if range_ <= 0.0:
		return other
	return other + offset.normalized() * range_


## The orbit point of the engage: the stand-off ring, stepped sideways so the hull walks
## around the contact instead of parking in front of it.
func _orbit(pos: Vector2, other: Vector2, range_: float) -> Vector2:
	var offset := pos - other
	if offset.is_zero_approx():
		return other
	if range_ <= 0.0:
		return other
	return other + offset.normalized().rotated(PATROL_LEG_TURN * _strafe) * range_


func _away(pos: Vector2, other: Vector2) -> Vector2:
	var offset := pos - other
	if offset.is_zero_approx():
		return Vector2.RIGHT.rotated(_leg_bearing)
	return offset.normalized()


## Section 5's flee rows, as the row's own data: "flees below 30 % hull" (the pirates,
## and ruling 24's pirates-like swarmers) and "flees from Suspect+" (the neutral convoy,
## which doc 13 section 5 makes sector-wide while the tier is active).
func _must_flee(hull_fraction: float, heat_tier: StringName) -> bool:
	var hull_floor := float(_row.get(NpcRegistryScript.KEY_FLEE_HULL, 0.0))
	if hull_floor > 0.0 and hull_fraction < hull_floor:
		return true
	var tier_floor := StringName(_row.get(NpcRegistryScript.KEY_FLEE_TIER, &""))
	if tier_floor == &"":
		return false
	return NpcRegistryScript.tier_at_least(heat_tier, tier_floor)


## The nearest contact this row treats as hostile, or an empty dictionary. `radius` is
## the row's aggro radius; a contact further out than that is not acquired (which is what
## "engages anything in radius" means) and the held target's own distance is checked by
## the caller's grace timer.
func _nearest(
	pos: Vector2, contacts: Array[Dictionary], heat_tier: StringName, attacked: bool, hostile: bool
) -> Dictionary:
	var radius := aggro_radius() if hostile else scan_radius()
	if radius <= 0.0:
		return {}
	var best := {}
	var best_distance := INF
	for contact: Dictionary in contacts:
		if hostile:
			if not NpcRegistryScript.is_hostile(_row, contact, heat_tier, attacked):
				continue
		elif not _is_scan_contact(contact, heat_tier, attacked):
			continue
		var distance := pos.distance_to(_contact_pos(contact))
		if distance <= radius and distance < best_distance:
			best = contact
			best_distance = distance
	return best


## Section 5's patrol scan: the player at Suspect+ but not yet an Outlaw (an Outlaw is a
## threat and the engage path owns it).
func _is_scan_contact(contact: Dictionary, heat_tier: StringName, attacked: bool) -> bool:
	if not bool(contact.get(&"is_player", false)):
		return false
	var floor := StringName(_row.get(NpcRegistryScript.KEY_SCAN_TIER, &""))
	if floor == &"":
		return false
	if NpcRegistryScript.is_hostile(_row, contact, heat_tier, attacked):
		return false
	return NpcRegistryScript.tier_at_least(heat_tier, floor)


## Remember the contact an aggro is held on, so the grace timer and `engaged_with` keep
## answering for a target that has just left the radius (section 5's AGGRO_COOLDOWN).
func _hold(contact: Dictionary) -> void:
	if contact.is_empty():
		return
	_target_pos = _contact_pos(contact)
	_has_target = true
	var node: Variant = contact.get(&"node", null)
	if node is Node2D:
		_target = node as Node2D


func _drop_target() -> void:
	_target = null
	_has_target = false
	_aggro_lost = 0.0


func _set_state(next: int) -> void:
	_state = next


func _los_clear(from: Vector2, to: Vector2) -> bool:
	if not _los.is_valid():
		return true
	return bool(_los.call(from, to))


func _contact_pos(contact: Dictionary) -> Vector2:
	if contact.is_empty():
		return _target_pos
	return _vector(contact.get(CTX_POS, _target_pos))


## The hull's contact records as a typed array: the hull publishes them, the brain never
## reaches into the tree for them (its only world access is the injected LOS callable).
func _contacts(ctx: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var raw: Variant = ctx.get(CTX_CONTACTS, [])
	if not raw is Array:
		return out
	out.assign(raw)
	return out


## A Vector2 out of a context entry: a caller may hand a dictionary's own Vector2 or a
## two-number array, and a malformed entry reads as the fallback rather than crashing a
## frame.
func _vector(value: Variant) -> Vector2:
	if value is Vector2:
		return value as Vector2
	if value is Vector2i:
		return Vector2(value as Vector2i)
	if value is Array and (value as Array).size() == 2:
		var pair: Array = value
		return Vector2(float(pair[0]), float(pair[1]))
	return Vector2.ZERO
