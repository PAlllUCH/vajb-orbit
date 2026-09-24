class_name PlayerShip
extends Node2D
## The player's hull: hybrid flight on a real physics body (ENGINE_SPEC section 3.1
## and ruling 8), mass-scaled inertia with the arrive-steering autopilot (section
## 3.2), the booster seam, the weapon and mining-laser mounts (the resolved fit's
## W-slot modules) and the rock collision body (section 6).
## Flight reads *only* the ShipStats snapshot ShipFit resolves (section 3.3): the
## per-class handling column and the booster activation numbers stay in ship_fit.gd,
## so no flight number is duplicated here. The constants that do live here are the
## section 13 values that belong to no class and to no module (brake multiplier,
## arrive-steering radii, the afterburner's and the dash's fuel burn) plus the
## section 7 warp quiet time.
## The manual stick is three inputs, and all three are the class's own rows turned
## into a command: `thrust_forward` / `thrust_backward` are the nose axis, the
## cursor is the nose bearing while `thrust_forward` is held (the autopilot's own
## arrive steering, owner ruling 2026-09-21), and `strafe_left` / `strafe_right`
## are the hull's sideways axis (the same ruling). The two strafe actions are
## derived from the class's `max_speed` and `accel_time` and invent no number; see
## `_command_velocity` and `_step_strafe`.
## This node also owns the reactor chain's hull half (section 4.4, rulings 11/14,
## pinned in CONTRACTS sections 4 and 8.1): its physics frame is the frame that ticks
## `PlayerState` (reactor refill and fuel-cell cooldown), it burns BOOST_FUEL through
## `try_spend_fuel` while the afterburner runs, it reads `emergency_mode` to lock
## thrust out, and it is where section 11's fuel-cell key spends a cell.
## Slice 2 adds three seams the pinned interfaces name and no other file may own: the
## damage sink (`take_damage` forwards into `PlayerState.damage`, so the pipeline and
## every weapon reach the player), the shield-regeneration frame step and the ram's
## item-5 context, both through `game/damage.gd`; and the weapon mount
## (`WeaponComponent`, the same pattern as the mining laser).
## Contract: ENGINE_SPEC sections 3, 4.2 (items 1-8, ruling 16's push physics), 4.3,
## 4.4, 6, 7, 9, 13; engine-wave-1 brief section W2; slice-0 brief pinned interface
## item 1; slice-2 brief pinned interfaces 1, 2, 4 and 5; flight-feel brief (owner
## rulings 2026-09-21, third round); CONTRACTS sections 4 and 8.1.

## Raised when the live pools lose points (hull or shield). The warp channel
## breaks on damage (ENGINE_SPEC section 7); game.gd listens to this instead of
## re-deriving "was that regen?" from the PlayerState signals. Collision damage rides
## the same channel (section 4.2 item 6).
signal damage_taken(amount: float)

const MINING_LASER_NODE: StringName = &"MiningLaser"
const MINING_LASER_SCENE := "res://game/mining_laser.tscn"

## Section 4.3's fitted weapons, mounted exactly as the mining laser is: a child node at
## the hull's origin, handed the launch snapshot and the fit. The node name is the one
## the wiring resolves (`game.gd` reads the same const), and the component is reached by
## path because a `class_name` only resolves after the editor has scanned the project.
##
## The component reads the trigger (`fire_primary`, held), the cursor, the ammo and the
## Energy gates itself, so the hull only mounts it; the mining laser's `E` stays the tool
## key and is untouched.
const WEAPONS_NODE: StringName = &"WeaponComponent"
const WEAPONS_SCRIPT := "res://game/weapons.gd"

## 09 section 3.1/4.5: a fit with no weapon module carries no weapon node at all, the
## same W-slot rule the mining laser follows (`w_mining` gates the tool). The v1 standard
## fit carries `w_laser`, so a launched ship mounts one group.
const WEAPONS: GDScript = preload("res://game/weapons.gd")

## 09 section 4.5 (the owner's mining-laser rule) and ENGINE_SPEC section 4.3/6:
## the mining laser is the `w_mining` tool that occupies a **W slot**, Tier I,
## draw 1. Buying the ability with a gun slot is the whole Delver/Fighter
## trade-off, so the module is the gate: a fit without it has spent no W slot and
## carries no laser and no trigger.
const MINING_MODULE: StringName = &"w_mining"

## S7 (CONTRACTS section 20): Embers' share of a delivered amount, healed into the
## shield by `heal_from_damage` when a player shot lands on an NPC hull. Spelled here
## as well as in `weapons.gd` because the pin routes the two deliveries differently -
## the beam heals off `PlayerState` directly, the projectile calls this hull's own
## method - so neither file reaches into the other's constant.
const EMBERS_FRACTION := 0.10

## ENGINE_SPEC section 6, "Rocks are solid: ships collide with them" + ruling 8.
## The scene's `HullBody` (a RigidBody2D at local zero) carries the ship's own physics
## layer and masks only the rock layer (Asteroid.COLLISION_LAYER), so rocks stop the
## hull and no unrelated body can; its CircleShape2D radius is the hull's half-length:
## the shipped sprite's 905 px at this scene's 0.0663 hull scale is 60.0 u long, the
## same art-derived basis asteroid.gd's LOOK_WIDTHS reads. A circle is
## rotation-invariant and the long axis dominates, so a side-on stop leaves ~17 u of
## gap to the sprite's edge. The body owns the live transform and the momentum; this
## node mirrors it (see `_sync_hull_transform`), so the sprite, the mining laser and
## the camera riding this node stay with the hull.
const HULL_BODY_NODE: StringName = &"HullBody"
const HULL_SHAPE_NODE: StringName = &"Shape"
## The artwork node. S5 (09 section 11) reads its own `scale` to turn the measured px
## anchors into hull-local units, so the map and the sprite cannot drift: re-scaling the
## art moves every anchor with it.
const HULL_SPRITE_NODE: StringName = &"Hull"

const THRUST_FORWARD: StringName = &"thrust_forward"
const THRUST_BACKWARD: StringName = &"thrust_backward"
const TURN_LEFT: StringName = &"turn_left"
const TURN_RIGHT: StringName = &"turn_right"

## The owner's A/D strafe (owner ruling 2026-09-21, third round). The two actions are in
## the project's input map (A and D) and `turn_left` / `turn_right` carry no key, but the
## turn actions keep their reader below: a pad axis or a re-bind in the Controls tab still
## answers, so nothing the owner already had stopped working.
const STRAFE_LEFT: StringName = &"strafe_left"
const STRAFE_RIGHT: StringName = &"strafe_right"

## S5 (09 section 11, CONTRACTS section 17): the four anchor rows `ShipFit.HARDPOINTS`
## carries, in the order the frame unions them. Thrust reads `rear`, brake/retro `front`,
## a sideways stick the side it points at -- so the union is one emitter list whose flags
## follow the stick, and a hull with a map never rebuilds its emitters on a mode change.
const THRUSTER_MODES: Array[StringName] = [&"rear", &"front", &"left", &"right"]

const BOOST_ACTION: StringName = &"boost"
const MINE_ACTION: StringName = &"mine"

## Section 11's in-flight refuel (ruling 13): one `fuel_cell` cargo item becomes
## FUEL_CELL_UNITS of tank fuel. The action's binding is the input map's business; the
## hull only reads it, guarded, so a build without the binding still flies.
const FUEL_CELL_ACTION: StringName = &"consume_fuel_cell"

## 09 section 3.5 boosters. `b_afterburner` is v1's only implemented booster;
## `b_fold` is expected in a fit (ShipFit carries it as data) and its 400 u blink
## is slice 4, so a fitted fold module is recognised and deliberately inert.
const BOOSTER_AFTERBURNER: StringName = &"b_afterburner"

## ENGINE_SPEC section 13: BRAKE_MULT (S-thrust versus coast) and the autopilot
## arrive-steering radii. These are global calibration, not a ShipStats field.
const BRAKE_MULT := 1.8
const SLOW_DOWN_RADIUS := 240.0
const ARRIVE_RADIUS := 40.0

## CONTRACTS section 14 (owner ruling 2026-09-22) -- the steering half. `_manual_desired_turn`
## answers a deflected turn action first, then the cursor, and the throttle no longer gates
## the cursor ("when ship is pause trying to turn around moves it way too much forward, a ship
## in space should somewhat be able to do neutral turn"). A turn input therefore commands
## torque and nothing else, so the hull turns where it stands even while it is parked.
## `false` restores the old gate -- the nose follows the cursor only while
## `thrust_forward` is held and the heading holds otherwise -- and that is this ruling's
## reversal, one condition. The cursor resting on the hull, which is where the camera's
## centre puts it, still holds the heading: that is `_aim_turn`'s own hull-radius deadzone,
## not the throttle.
const STEER_WITHOUT_THROTTLE := true
## The neutral turn's own bound, read by `tests/test_s2_6_flight.gd`: a full 360 degree cursor
## turn at zero throttle may translate the hull no further than this many units. A bound on
## the law, not a number the law reads.
const TURN_TRANSLATE_LEAK_MAX := 5.0

## The handling table's ruling multipliers (CONTRACTS section 14) are read from the file that
## owns them, so the lateral split derives from one copy of the numbers. Reached by path and
## not by global class name, for the reason the IMPACT preload's comment gives.
const SHIP_FIT := preload("res://game/ship_fit.gd")

## ENGINE_SPEC section 13 "Energy & fuel (rulings 10-14)": the afterburner burns
## BOOST_FUEL 3.0 per second while it runs and a fold/dash burst spends DASH_FUEL 25.
## Both are global calibration rows -- no class column and no module effect carries
## them -- so the hull that spends them is their single owner, exactly as it is for
## the brake multiplier and the arrive radii above (slice-0 review finding F3; the
## dash's own activation and displacement stay slice 4's booster work, CONTRACTS
## section 8.1). Both are spent through `PlayerState.try_spend_fuel`.
const BOOST_FUEL := 3.0
const DASH_FUEL := 25.0

## ENGINE_SPEC section 7: safe warp is available after 5 s without a hit.
const WARP_DAMAGE_QUIET := 5.0

## The push-physics arithmetic of section 4.2 items 6-8 (`impact.gd`), reached through
## a preload rather than through its global class name: a `class_name` only resolves
## once the editor has rescanned the project, which a headless worker cannot count on
## while the wave is still being written (game.gd reaches this very file the same way).
const IMPACT := preload("res://game/impact.gd")

## W2's damage pipeline (`game/damage.gd`), reached by path for the same reason: the pin
## lives in one file, so the hull's ram context and its shield-regen frame step are the
## pipeline's own arithmetic and not a private copy of it (slice-2 brief, pinned
## interfaces 1 and 4; W2 report section "What the wave still owes", items 2 and 4).
const DAMAGE := preload("res://game/damage.gd")

## The hit's feedback seam F1's `game/fx.gd` sits behind: the death blast, the low-hull
## plume and the shield's held bed are `projectile.gd`'s (the hit site's own table), so
## the player and an NPC hull read one copy of it.
const PROJECTILE := preload("res://game/projectile.gd")

## Mass used when the launch snapshot carries no `hull_mass`: the section 13 class
## column is M2's field on ShipStats, and the migration stands on its own until it is
## there (the hull flies either way, because the flight maths is mass-independent, see
## `_step_speed`; but collision damage and every impulse are charged per mass, so a
## missing field is announced in `setup` rather than flown at a wrong weight).
const UNRESOLVED_HULL_MASS := 1.0

## --- The owner's request (2026-09-21): "ship while traveling has to make sounds
## (thrusters depending on speed) and thrusters should create flame fx" ------------

## FX_SPEC section 1.3's anchor row: "the hull's engine cells when
## `ShipFit.mount_offset` is available, else one tail point behind the hull's centre".
## Both halves now ship (P2-A): `thruster_anchors` returns one point per engine cell
## and falls back to this tail point for a hull with no grid. The fraction is the one
## that row names; `_hull_radius()` is the hull's own art-derived half-length (the same
## figure the aim deadzone uses), so no new size is invented.
const TAIL_ANCHOR_FRACTION := 0.55

## FX_SPEC section 6 row 3 (proposed): the low-hull arcs' own cadence, one arc every
## 1.6-2.6 s, 0.2 s each (the sheet's four frames at 20 FPS). The seed is this hull's
## determinism seam - it makes an otherwise random cadence reproducible for a probe, and
## it is not a spec value; the reversal is to draw from the global generator instead.
const ARC_INTERVAL_MIN := 1.6
const ARC_INTERVAL_MAX := 2.6
const ARC_SEED := 20260921

var _stats: ShipStats = null
var _state: PlayerState = null
var _body: RigidBody2D = null
var _laser: Node = null
var _laser_active := false
var _guns: Node2D = null
var _fit_ids: Array[StringName] = []

## The launched hull's id, handed over by `game.gd` (additive seam, P2-A): the engine
## cells' mount anchors are hull-local geometry (`ShipFit.mount_offset`), and the
## snapshot carries no hull id of its own. `&""` before the launch and for a caller that
## never sets it, which is exactly the "no grid" case `thruster_anchors` falls back on.
var _hull_id: StringName = &""

## The frame's speed ratio, pushed by `game.gd` (the scene computes `|v| / v_max` once
## for its three readers - engine spec section 3.4's single input - so nothing here
## recomputes it). It is what the thruster trail's length, rate and alpha read.
var _speed_ratio := 0.0
## One emitter per engine-cell anchor, in anchor order (rebuilt every frame by the sync).
var _thruster_trails: Array[GPUParticles2D] = []
## The low-hull arcs' own clock, the interval currently drawn and how many have fired.
var _arc_clock := 0.0
var _arc_next := 0.0
var _arc_count := 0
var _arc_rng := RandomNumberGenerator.new()
## How many afterburner activations this hull has lit, so "one charge and one cue per
## activation" is measurable after the 0.2 s charge has freed itself.
var _boost_activations := 0

var _move_target := Vector2.ZERO
var _has_move_target := false

## The aim override (additive seam, the same pair `game/weapons.gd` carries): a probe aims
## deterministically by handing the hull a point, and a non-mouse aiming mode replaces the
## cursor. The cursor itself is read only while this is unset.
var _aim_override := Vector2.ZERO
var _has_aim_override := false

var _boost_remaining := 0.0
var _boost_cooldown := 0.0

var _damage_quiet := WARP_DAMAGE_QUIET
var _last_hull := 0.0
var _last_shield := 0.0
var _vitals_seeded := false

## The velocity the hull carried *into* the current physics step. Contact monitor
## events arrive after the solver has already spent the approach speed, so this is the
## pre-impact velocity `_on_hull_body_entered` charges damage from (section 4.2 item 6).
var _last_velocity := Vector2.ZERO

## The net central force and torque the flight law handed the body in the step being
## processed -- the same shape of observability seam as `boost_activations` and
## `arc_count`, and the only window a *suite* has on a step: the headless runner calls a
## test method synchronously and never awaits a frame, so the physics server never
## integrates a hull a suite builds. `applied_force()` / `applied_torque()` are read by
## `tests/test_s2_6_flight.gd` (AC6's neutral-turn displacement and the axis-damp split)
## and by `tests/probe_s2_6_flight.tscn`'s own integration check. Zeroed at the top of
## every step, so "no thrust was applied" is a reading and not an absence.
var _applied_force := Vector2.ZERO
var _applied_torque := 0.0


func _ready() -> void:
	add_to_group(&"player_ship")
	_arc_rng.seed = ARC_SEED
	_body = get_node_or_null(NodePath(HULL_BODY_NODE)) as RigidBody2D
	if _body != null:
		_body.body_entered.connect(_on_hull_body_entered)
	_sync_mining_laser()
	_sync_weapons()


## The launched hull's id (additive seam, P2-A, CONTRACTS section 11): `game.gd` sets
## it from the same hull it resolved the snapshot and the fit from, and the engine
## cells' mount anchors are read off it. Separate from `setup` so the pinned launch
## signature is untouched; a hull that never gets one keeps the single tail anchor.
func set_hull_id(hull_id: StringName) -> void:
	_hull_id = hull_id


## Launch handshake (pinned interface): the resolved snapshot plus the scene's
## live pools. Safe to call again on a hull swap; the old state is released and the
## rigid body is re-sized for the new hull.
##
## `fit_ids` is the launched fit's module ids (`ShipFit.fitted_ids`, additive
## beyond the pin, defaulting to an empty fit): the W-slot gate for the mining
## laser (09 section 4.5). A fit that carries no `w_mining` mounts no laser and `E`
## mines nothing until the module is fitted.
func setup(stats: ShipStats, state: PlayerState, fit_ids: Array[StringName] = []) -> void:
	_stats = stats
	_release_state()
	_state = state
	_fit_ids = fit_ids.duplicate()
	_apply_rigid_body()
	_sync_mining_laser()
	_sync_weapons()
	if _state == null:
		return
	_last_hull = _state.hull
	_last_shield = _state.shield
	_vitals_seeded = true
	_state.hull_changed.connect(_on_hull_changed)
	_state.shield_changed.connect(_on_shield_changed)
	## The death blast (F2) is hung off the state's own door, so a hull that dies from
	## any route - a shot, a ram, a warp-damage tick - draws it exactly once.
	_state.died.connect(_on_hull_death)


## Autopilot order (ENGINE_SPEC section 3.1). `pos` is a global position,
## normally the cursor's world point. Firing does not cancel an order; thrust or
## turn input does.
func set_move_target(pos: Vector2) -> void:
	_move_target = pos
	_has_move_target = true


func cancel_orders() -> void:
	_has_move_target = false


## The aim override (additive seam): while `thrust_forward` is held the nose chases this
## point instead of the cursor. A headless run has no cursor, and the same override exists
## on the weapon component so both halves of a probe aim at one point.
func set_aim_point(point: Vector2) -> void:
	_has_aim_override = true
	_aim_override = point


func clear_aim_point() -> void:
	_has_aim_override = false


## Safe-warp state query for game.gd's gate (ENGINE_SPEC section 7): the hull is
## alive and nothing has hit it for WARP_DAMAGE_QUIET. Whether a station exists
## in the sector and whether a hostile is engaged are the sector's and game.gd's
## halves of the same gate.
func warp_available() -> bool:
	if _stats == null or _state == null:
		return false
	if _state.hull <= 0.0:
		return false
	return _damage_quiet >= WARP_DAMAGE_QUIET


func has_booster(id: StringName) -> bool:
	return _stats != null and _stats.boosters.has(id)


## The live hold this hull flies with (ENGINE_SPEC section 9: PlayerState's maxima
## come from the launch snapshot). The pickup's hold-full gate reads it, so the gate
## and the HUD cargo bar agree on one capacity for every hull, including the five the
## station catalogue does not sell. Falls back to the snapshot before `setup` runs.
func cargo_max() -> int:
	if _state != null and _state.cargo_max > 0:
		return _state.cargo_max
	if _stats != null and _stats.cargo_max > 0:
		return _stats.cargo_max
	return 0


## The hull's live velocity vector, momentum and all (ruling 18's speed fantasy reads
## |v| / v_max off it, and slice 2's gunnery reads it for lead and for hit
## resolution). Empty until the scene's body exists.
func velocity() -> Vector2:
	if _body != null:
		return _body.linear_velocity
	return Vector2.ZERO


## The hull's rigid body (pinned seam, additive beyond the flight API): push-physics
## callers work on bodies, not on ships: `Impact.apply_shockwave` takes one, and
## slice 2's detonations walk hulls and rocks. Null before the scene is ready.
func impact_body() -> RigidBody2D:
	return _body


## --- The thrust feedback's own seams (FX_SPEC section 1.3, AUDIO_SPEC 4.5) ------


## The frame's ratio, handed over by `game.gd` once per frame. Engine spec section 3.4 has
## exactly one input and the scene already computes it for the dial and the screen-space
## stack, so nothing here recomputes `|v| / v_max`.
func set_speed_ratio(ratio: float) -> void:
	_speed_ratio = clampf(ratio, 0.0, 1.0)


func speed_ratio() -> float:
	return _speed_ratio


## The hull-local points the thruster flames come from (FX_SPEC section 1.3's anchor
## row). **S5 (09 section 11, CONTRACTS section 17): the seam resolves to
## `ShipFit.HARDPOINTS`** -- `mode` selects which row, `&"rear"` (thrust) by default,
## `&"front"` (brake / retro) and `&"left"` / `&"right"` (strafe) beside it. The map is
## measured in render px, so it is scaled into the hull's own units by the sprite's own
## scene scale (`_hull_sprite_scale`), the figure the art is drawn at; the anchors are
## then children of this node, exactly like the single tail point was.
##
## A hull **without** a map keeps the whole of the pre-S5 behaviour, unchanged: one
## anchor per engine cell from `ShipFit.mount_offset` (the 09 section 8 derivation), and
## the single tail point for a hull with no grid (an NPC) or a scene whose body carries
## no radius. That is section 11's named reversal.
##
## The grid's row axis is the hull's longitudinal one - 08 section 3.2 reads the matrix
## as the hull from above, "engines and the reactor sit in the tail" - so a cell's row
## fraction, recovered from `mount_offset`'s y by dividing `MOUNT_SPREAD.y` back out,
## places the nozzle along the tail direction at the same `TAIL_ANCHOR_FRACTION` of the
## art-derived radius the single-point anchor used, and the column fraction spreads the
## cells across the hull's width.
func thruster_anchors(mode: StringName = &"rear") -> Array[Vector2]:
	var anchors: Array[Vector2] = []
	var measured := ShipFit.thruster_points(_hull_id, mode)
	if not measured.is_empty():
		var scale := _hull_sprite_scale()
		for point: Vector2 in measured:
			anchors.append(point * scale)
		return anchors
	return _derived_anchors()


## The 09 section 8 fallback, one point per engine cell (and the single tail point for a
## hull with no grid): what every hull answered before section 11 gave the nine player
## hulls a measured map, kept verbatim so a hull without one does not change behaviour.
func _derived_anchors() -> Array[Vector2]:
	var anchors: Array[Vector2] = []
	var radius := _hull_radius()
	if radius <= 0.0:
		return anchors
	var engines := ShipFit.slot_capacity(_hull_id, &"engines")
	if engines <= 0:
		anchors.append(_tail_anchor(radius))
		return anchors
	for index in engines:
		anchors.append(_engine_anchor(index, radius))
	return anchors


## The scale the hull sprite is drawn at: the `Hull` node's own transform, so the
## measured px anchors land on the pixels the render put them on. No literal - a scene
## that re-scales its hull moves the anchors with it. `Vector2.ONE` for a scene without
## the sprite (nothing to scale against; the caller's anchors are then already local).
func _hull_sprite_scale() -> Vector2:
	var sprite := get_node_or_null(NodePath(HULL_SPRITE_NODE)) as Sprite2D
	if sprite == null:
		return Vector2.ONE
	return sprite.scale


## One engine cell's nozzle: the cell's own mount anchor, mapped into the hull's local
## frame as above. A cell `mount_offset` cannot place (it answers `Vector2.ZERO`) falls
## back to the tail point, so the anchor count stays one per engine cell either way.
func _engine_anchor(index: int, radius: float) -> Vector2:
	var offset := ShipFit.mount_offset(_hull_id, &"engines", index)
	if offset == Vector2.ZERO:
		return _tail_anchor(radius)
	var row_fraction := offset.y / ShipFit.MOUNT_SPREAD.y + 0.5
	return Vector2(-radius * TAIL_ANCHOR_FRACTION * row_fraction, offset.x * radius)


## The pre-P2-A anchor, kept for a hull whose frame has no grid: one tail point behind
## the hull's centre.
func _tail_anchor(radius: float) -> Vector2:
	return Vector2(-radius * TAIL_ANCHOR_FRACTION, 0.0)


## One W cell's measured mount in this hull's own units (S5, 09 section 11): `pos` in
## the hull's local frame and `facing` in radians relative to the hull's axis, or `{}`
## for a hull with no map or a cell past its measured mounts - the caller then fires from
## the pre-S5 muzzle, this node's origin.
##
## The conversion is this node's because it holds both halves: the map is in render px
## and the sprite's own scale is what maps those px onto the drawn hull.
func weapon_mount(index: int) -> Dictionary:
	var mount := ShipFit.weapon_mount(_hull_id, index)
	if mount.is_empty():
		return {}
	var pos: Variant = mount.get(&"pos", Vector2.ZERO)
	return {
		&"pos": (pos as Vector2) * _hull_sprite_scale(),
		&"facing": float(mount.get(&"facing", 0.0)),
	}


## The trail emitters in anchor order, one per engine cell (empty before the first frame
## the hull is set up, and for a hull whose anchors are unknown).
func thruster_trails() -> Array[GPUParticles2D]:
	return _thruster_trails


## The low-hull arcs' own counters, so "how many fired" is a reading rather than a count
## of nodes that have already freed themselves.
func arc_count() -> int:
	return _arc_count


func arc_interval() -> float:
	return _arc_next


## How many times the afterburner has lit on this hull. FX_SPEC section 7.1's dash charge
## and AUDIO_SPEC section 4.5's boost cue both fire on that one event.
func boost_activations() -> int:
	return _boost_activations


## The pinned damage sink (slice-2 brief, pinned interface item 4; W2's measured gap 1):
## `Damage.apply(target, ...)` and every weapon's delivery reach the ship node, which
## forwards into `PlayerState.damage`, so the wave-1 verified shield-first absorb with no
## carry-over is what gates the player's hull and `ctx` (section 4.2 item 5) rides every
## hit. A hull that has not launched has no pools and takes nothing.
func take_damage(amount: float, bypass_shield: bool = false, ctx: Dictionary = {}) -> void:
	if _state == null:
		return
	_state.damage(amount, bypass_shield, ctx)


## Whether the shield is still up, for section 4.1's shield rules (W1 report finding 3:
## `weapons.gd` reads a target's shields through `shield_up()`, a `shield` property or a
## `state` property, so this one-line reader is what lets plasma's +25 % hull bonus land
## on a real ship instead of never applying).
func shield_up() -> bool:
	return _state != null and _state.shield > 0.0


## Generic push (section 4.2 items 7/8): knockback from a hit and the edge of a blast
## both arrive as an impulse, so both land here and neither needs to know about the
## body. Instant, like every other impulse in the pipeline.
func apply_impulse(impulse: Vector2) -> void:
	if _body == null or impulse.is_zero_approx():
		return
	_body.apply_central_impulse(impulse)


## Section 4.2 item 7, the shooter's half: a shot pushes the hull back with
## `projectile_mass * muzzle_velocity` opposite the muzzle. Slice 2's weapons call
## this with the shot they just spawned (the barrel's direction is the projectile's
## own velocity), so the recoil seam exists before the first gun; the mining laser is
## a tool and fires nothing.
func apply_recoil(projectile_velocity: Vector2, projectile_mass: float) -> void:
	if _body == null or projectile_velocity.is_zero_approx():
		return
	var instant := IMPACT.recoil_impulse(projectile_mass, projectile_velocity.length())
	if instant <= 0.0:
		return
	_body.apply_central_impulse(-projectile_velocity.normalized() * instant)


## The hull's heading, in the physics body's own frame (the ship mirrors the body, so
## the node's rotation is only a copy). Steering reads it, the thrust axis is it.
func _heading() -> float:
	if _body != null:
		return _body.global_rotation
	return global_rotation


## The net central force the flight law applied in the step being processed, in newtons,
## accumulated across that step's axes ("forward" and "sideways" are two forces on one
## body). Observability only: nothing in the flight law reads it back.
func applied_force() -> Vector2:
	return _applied_force


## The net torque the flight law applied in the step being processed, the angular twin of
## `applied_force`.
func applied_torque() -> float:
	return _applied_torque


## The one place a central force reaches the body, so "how hard did the law push" is
## readable (see the recorder's own comment). Nothing about the force changes here: it is
## handed to the body exactly as before.
func _apply_force(force: Vector2) -> void:
	if _body == null:
		return
	_applied_force += force
	_body.apply_central_force(force)


## The torque twin of `_apply_force` (`_step_turn` is its only caller).
func _apply_torque(torque: float) -> void:
	if _body == null:
		return
	_applied_torque += torque
	_body.apply_torque(torque)


func _physics_process(delta: float) -> void:
	## The observability recorder's own frame boundary: everything below is this step's
	## force and torque, and a step that commands neither reaches the suite as exactly zero.
	_applied_force = Vector2.ZERO
	_applied_torque = 0.0
	_sync_hull_transform()
	_update_boosters(delta)
	_update_mining_laser()
	_step_reactor(delta)
	_update_fuel_cell()
	_damage_quiet += delta
	## Section 4.2 item 2: one frame of shield regeneration at the state's own rate, once
	## the hull has been quiet for `Damage.REGEN_QUIET` (the timer above is this hull's, so
	## the window keeps one owner). Nothing else in the shipped game spends the rate, so
	## without this call a shield never recovers in flight (W2 report, gap 4).
	DAMAGE.regen(_state, delta, _damage_quiet)
	if _stats == null or _body == null:
		return

	## The stick is sampled raw: it is what cancels an autopilot order (section 3.1)
	## and the reaction wheels keep answering it. Only the *thrust* is gated by ruling
	## 14's lockout, so a dry tank still turns and still drifts (see `_thrust_locked`).
	var stick := _manual_throttle()
	var strafe := _manual_strafe()
	var turn := _manual_turn()
	if _has_move_target and (
		not is_zero_approx(stick) or not is_zero_approx(strafe) or not is_zero_approx(turn)
	):
		cancel_orders()
	if _has_move_target and global_position.distance_to(_move_target) <= ARRIVE_RADIUS:
		cancel_orders()

	var throttle := 0.0 if _thrust_locked() else stick
	## The strafe is thrust, so ruling 14 locks it with the throttle: a dry tank strafes
	## nowhere. Its *turn* is not thrust, so the cursor steering below stays live.
	var lateral := 0.0 if _thrust_locked() else strafe
	var desired_turn := 0.0
	var desired_lateral := 0.0
	var desired_speed := 0.0
	var rate := _coast_rate()
	if _has_move_target:
		desired_turn = _order_turn()
		desired_speed = _order_speed()
		## The autopilot commands thrust too, so ruling 14 locks it with the stick: a
		## dry tank steers towards the order and coasts instead of accelerating.
		if _thrust_locked():
			desired_speed = 0.0
		if absf(desired_speed) > absf(_velocity_along_heading()):
			rate = _accel_rate()
	else:
		desired_turn = _manual_desired_turn(stick, turn)
		var command := _command_velocity(throttle, lateral)
		desired_speed = command.x
		desired_lateral = command.y
		if not is_zero_approx(throttle):
			rate = _accel_rate() * (BRAKE_MULT if throttle < 0.0 else 1.0)
	_step_turn(desired_turn, delta)
	_step_speed(desired_speed, rate, delta)
	_step_strafe(desired_lateral, delta)
	## The sideways damp's explicit half, on the axis no one commanded (CONTRACTS section
	## 14's `LATERAL_DAMP_MULT`): a commanded strafe already compensated the whole of the
	## sideways damp on its own axis, so this drag is what holds an uncommanded skid at
	## today's rate while the forward carry follows `COAST_TIME_MULT`.
	_step_lateral_drag(delta)
	## The owner's 2026-09-21 request ("ship while traveling has to make sounds ... and
	## thrusters should create flame fx"), the hull's half: one trail per anchor row the
	## hull's map carries and one held bed, both reading the ratio `game.gd` already
	## pushed and the stick the flight law above already resolved (S5: the raw throttle
	## and strafe hand the frame its mode), plus the low-hull arcs' clock.
	_update_thrust_feedback(not is_zero_approx(throttle), throttle, lateral)
	_update_damage_arcs(delta)
	_last_velocity = _body.linear_velocity


## LMB on empty space orders a fly-to (section 3.1). Slice 2 splits this into
## "click a hostile hull to lock it"; with no NPCs there is no hostile pick yet.
func _unhandled_input(event: InputEvent) -> void:
	if _stats == null:
		return
	var button := event as InputEventMouseButton
	if button == null or not button.pressed:
		return
	if button.button_index != MOUSE_BUTTON_LEFT:
		return
	set_move_target(get_global_mouse_position())


func _manual_throttle() -> float:
	if not InputMap.has_action(THRUST_FORWARD) or not InputMap.has_action(THRUST_BACKWARD):
		return 0.0
	return (
		Input.get_action_strength(THRUST_FORWARD) - Input.get_action_strength(THRUST_BACKWARD)
	)


## The hull's sideways stick (owner ruling 2026-09-21, third round): D is right, A is left,
## positive is towards the hull's own right hand, which is the sign `_strafe_axis` turns.
## Guarded like every other reader here, so a build whose input map predates the two
## actions still flies.
func _manual_strafe() -> float:
	if not InputMap.has_action(STRAFE_RIGHT) or not InputMap.has_action(STRAFE_LEFT):
		return 0.0
	return (
		Input.get_action_strength(STRAFE_RIGHT) - Input.get_action_strength(STRAFE_LEFT)
	)


## The yaw stick. The shipped input map binds no key to `turn_left` / `turn_right` (A and D
## strafe now), but the reader stays: a pad axis or a Controls-tab re-bind answers it, and
## it takes priority over the cursor steering while it is deflected.
func _manual_turn() -> float:
	if not InputMap.has_action(TURN_RIGHT) or not InputMap.has_action(TURN_LEFT):
		return 0.0
	return Input.get_action_strength(TURN_RIGHT) - Input.get_action_strength(TURN_LEFT)


## The manual branch's commanded turn, and the whole of the steering ruling (CONTRACTS
## section 14, owner 2026-09-22): a deflected turn action answers first, then the cursor --
## **with or without the throttle** (`STEER_WITHOUT_THROTTLE`), which is what lets a parked
## hull come about where it stands: a turn command applies torque only, so a full revolution
## at zero throttle leaves the hull where it was. `stick` is the raw throttle, not the locked
## one, so a dry tank holding W still turns (ruling 14 keeps the reaction wheels live).
func _manual_desired_turn(stick: float, turn: float) -> float:
	if not is_zero_approx(turn):
		return turn * _stats.turn_rate
	if STEER_WITHOUT_THROTTLE or stick > 0.0:
		return _aim_turn()
	return 0.0


## Ruling 14 / section 4.4: a dry tank is Emergency Flight Mode, which locks thrust
## out. The ship drifts on the momentum the body already has and coasts it down at its
## class coast rate, while the reaction wheels (`_manual_turn`) stay live. Read through
## the state, so a hull that has not launched yet never locks its own controls.
func _thrust_locked() -> bool:
	return _state != null and _state.emergency_mode


## The point the nose chases (see `_aim_turn`): the cursor's own world point, the same point
## an LMB order aims at. Falls back to the hull's position outside the tree, where there is no
## viewport to read a cursor from (the weapon component's own `_aim_point` makes the same
## fallback).
func _aim_point() -> Vector2:
	if _has_aim_override:
		return _aim_override
	if not is_inside_tree():
		return global_position
	return get_global_mouse_position()


## Arrive steering towards a point: the desired heading is the bearing to the point,
## expressed as a fraction of the class turn rate (one radian of error is full deflection).
## The turn model spins up to it, so heavy hulls arc and overshoot (section 3.2). One law
## serves both callers -- an LMB order's fly-to point and the cursor -- so there is no
## second steering model to keep in step.
func _turn_toward(point: Vector2) -> float:
	var bearing := (point - global_position).angle()
	var error := wrapf(bearing - _heading(), -PI, PI)
	return clampf(error, -1.0, 1.0) * _stats.turn_rate


## Arrive steering on the fly-to order (section 3.1).
func _order_turn() -> float:
	return _turn_toward(_move_target)


## The cursor turn (owner ruling 2026-09-21, third round; made throttle-independent by the
## 2026-09-22 ruling): the nose chases the cursor through the autopilot's own arrive
## steering, so the class's `turn_rate` and `turn_spinup` still govern how fast the nose may
## move, and a cursor closer than the hull's own radius has no bearing worth chasing -- the
## camera centres the hull, so that is exactly where the pointer rests at launch, and it is
## what still holds the heading when the pilot is not aiming. The deadzone is the
## art-derived hull radius rather than an invented constant.
func _aim_turn() -> float:
	var point := _aim_point()
	var radius := _hull_radius()
	if point.distance_squared_to(global_position) <= radius * radius:
		return 0.0
	return _turn_toward(point)


## Arrive steering: the desired speed falls from the class maximum to zero across
## SLOW_DOWN_RADIUS and reaches zero at ARRIVE_RADIUS, so the autopilot stops in
## the ring instead of coasting through it. A target behind the bow holds speed
## at zero while the ship comes about (no reverse thrust in autopilot).
func _order_speed() -> float:
	var to_target := _move_target - global_position
	var error := wrapf(to_target.angle() - _heading(), -PI, PI)
	if absf(error) > PI * 0.5:
		return 0.0
	var fraction := clampf((to_target.length() - ARRIVE_RADIUS) / SLOW_DOWN_RADIUS, 0.0, 1.0)
	return _max_speed() * fraction


## Angular inertia, on the body: the turn rate is asked to spin up to `desired_turn`
## at the class's own rate (turn_rate / turn_spinup, section 3.2) and the torque is
## that angular acceleration times the hull's inertia, so the same class number means
## the same spin-up on every hull however heavy it is. The body's angular damp is
## compensated for, so the spin-up is the class rate and not the class rate minus
## drag; `apply_torque` is a global torque and positive is clockwise, which is the
## same sign the turn actions and the old `_heading` integration used.
func _step_turn(desired_turn: float, delta: float) -> void:
	if _body == null or delta <= 0.0:
		return
	var spin_rate := _spin_rate()
	var omega := _body.angular_velocity
	var alpha := clampf((desired_turn - omega) / delta, -spin_rate, spin_rate)
	var torque := _angular_inertia() * (alpha + _angular_damp() * omega)
	if is_zero_approx(torque):
		return
	_apply_torque(torque)


## The manual command as one body-frame velocity (x = the nose, y = the hull's right side),
## and the whole of the strafe's derivation: the stick's own vector is capped at unit
## magnitude, then scaled by the class's own `max_speed` -- the section 13 column the class
## already flies by. Every axis is therefore commanded to that ceiling and no axis can
## exceed it: W+D is a 45 degree diagonal at the class maximum instead of a square-cornered
## sqrt(2) x maximum that would break section 3.4's `|v| / v_max` onset, and a single axis
## is passed through to the digit, because its magnitude is 1 to begin with. No new balance
## number exists between those rows and the strafe.
func _command_velocity(throttle: float, lateral: float) -> Vector2:
	var ceiling := _max_speed()
	var stick := Vector2(throttle, lateral)
	var magnitude := stick.length()
	if magnitude > 1.0:
		stick /= magnitude
	return stick * ceiling


## The hull's right-hand side: the nose turned 90 degrees. Godot 2D is y-down, so with the
## nose on +X this is +Y -- the side the pilot's right hand points at, and the sign
## `_manual_strafe` and the turn actions share.
func _strafe_axis() -> Vector2:
	return Vector2.RIGHT.rotated(_heading() + PI * 0.5)


## Lateral thrust (owner ruling 2026-09-21, third round: "while pressing A/D they should
## strafe to the side"): the same chase law `_step_speed` runs on the nose, turned 90
## degrees, at the class's own acceleration (`max_speed / accel_time`, `_accel_rate`) --
## the strafe's strength is those two section 13 rows and nothing else, so a light hull
## snaps sideways and a Hauler labours across. The sideways damp (`_lateral_damp`: the
## body's own plus the explicit lateral drag) is compensated for on this axis while a
## strafe is commanded, so the chase is the class rate rather than the class rate minus
## drag; released, the axis belongs to that same damp again and the sideways velocity
## settles at today's time constant, exactly as a hit's push does.
func _step_strafe(desired_lateral: float, delta: float) -> void:
	if _body == null or delta <= 0.0 or is_zero_approx(desired_lateral):
		return
	_thrust_axis(_strafe_axis(), desired_lateral, _accel_rate(), delta, _lateral_damp())


## One axis of thrust: the velocity along `axis` chases `desired_speed` at `rate`, and the
## damp that axis carries -- `_linear_damp()` along the nose, `_lateral_damp()` across it --
## is compensated for so the chase is the class rate rather than the class rate minus drag.
## `_step_speed` is this law on the nose and `_step_strafe` is it on the hull's side; the
## damp still owns every *other* axis (a hit's push, a released strafe's tail), which is the
## degree of freedom real physics adds.
func _thrust_axis(
	axis: Vector2, desired_speed: float, rate: float, delta: float, damp: float
) -> void:
	if _body == null or delta <= 0.0:
		return
	var along := _body.linear_velocity.dot(axis)
	var accel := clampf((desired_speed - along) / delta, -rate, rate)
	var force := _hull_mass() * (accel + damp * along)
	if is_zero_approx(force):
		return
	_apply_force(axis * force)


## The sideways drag the owner's "like ship slides in one side" is about (CONTRACTS section
## 14's `LATERAL_DAMP_MULT`): the body damps every axis at `1 / coast_time` -- the forward
## carry the same ruling doubles -- so the velocity *across* the nose is given this much
## extra drag to hold its total decay at today's rate. It is a real drag (mass x rate x the
## sideways velocity) applied on a real axis, not a counter-force that hides the velocity from
## the flight law, and it is exactly what a commanded strafe compensates along its own axis
## (see `_step_strafe`).
func _step_lateral_drag(delta: float) -> void:
	if _body == null or delta <= 0.0:
		return
	var extra := _lateral_extra_damp()
	if extra <= 0.0:
		return
	var velocity := _body.linear_velocity
	var nose := Vector2.RIGHT.rotated(_heading())
	var sideways := velocity - nose * velocity.dot(nose)
	if is_zero_approx(sideways.length_squared()):
		return
	_apply_force(-sideways * (_hull_mass() * extra))


## Linear motion, on the body's velocity (ruling 8: thrust is `mass x acceleration`,
## and the acceleration is the class's own). The velocity *along the heading* is asked
## to chase `desired_speed` at `rate` (the same move_toward the hybrid model always
## used, now expressed as the acceleration it implies), so throttle reaches max_speed
## over accel_time, S brakes at BRAKE_MULT times that, and the autopilot's arrive
## ramp obeys the same law.
func _step_speed(desired_speed: float, rate: float, delta: float) -> void:
	_thrust_axis(
		Vector2.RIGHT.rotated(_heading()), desired_speed, rate, delta, _linear_damp()
	)


## The body owns the hull's live transform and this node mirrors it: the sprite, the
## mining laser and the camera hang off this node, so the mirror is what keeps them
## with the hull. The body's local transform then returns to zero, which leaves its
## *global* transform exactly where the physics step put it: the same division of
## labour the hybrid model's body used (the ship owns the scene transform, the body
## owns the shape), now with a body that carries the momentum as well.
func _sync_hull_transform() -> void:
	if _body == null or not is_inside_tree():
		return
	global_position = _body.global_position
	global_rotation = _body.global_rotation
	_body.position = Vector2.ZERO
	_body.rotation = 0.0


## Ruling 15 / section 4.2 item 6: a body-body impact past COLLISION_MIN_DV deals
## kinetic damage to both sides out of the reduced-mass form. The closing speed is the
## one the hull carried *into* the step that resolved the contact (`_last_velocity`),
## measured along the line between the two centres; a peer that does not yield comes
## back as an infinite mass from `_peer_mass`, which is the flat-wall case of the
## section 16 worked example.
##
## The player's half lands on `PlayerState.damage`, so the shield absorbs it like any
## other hit (section 4.2 item 1) and `damage_taken` rides the same channel; the
## peer's half is offered to `apply_collision_damage` when the peer has one (M2's
## rocks take it; a wall or a station has no hull to charge).
func _on_hull_body_entered(other: Node) -> void:
	if _state == null or other == null:
		return
	## Section 4.2 item 5 through the pipeline rather than by hand: `Damage.ram` computes
	## the same `Impact.collision_damage` figure and records the item-5 context off the
	## contact's own geometry (the peer's bearing relative to this hull), so the player's
	## half of a ram is on the record from the first bump (W2 report, gap 2).
	var peer := other as Node2D
	var peer_position := peer.global_position if peer != null else global_position
	var damage := DAMAGE.ram(
		self, peer_position, _hull_mass(), _peer_mass(other), _closing_speed(other)
	)
	if damage <= 0.0:
		return
	if other.has_method(&"apply_collision_damage"):
		## S7 (CONTRACTS section 20, site 5): the peer's half is a player-origin damage
		## amount, so it takes the launch's `damage_mult` exactly once here. The player's
		## own half already landed on `PlayerState.damage` inside `DAMAGE.ram`.
		other.call(&"apply_collision_damage", damage * _damage_scale())


## The closing speed of a contact: the relative velocity project on the line between
## the two centres, floored at zero so a separating pair charges nothing. A peer with
## no usable offset (its centre on ours) falls back to the relative velocity's own
## direction, which is the head-on reading of the same number.
func _closing_speed(other: Node) -> float:
	var relative := _last_velocity - _peer_velocity(other)
	if relative.is_zero_approx():
		return 0.0
	var direction := relative.normalized()
	var other_node := other as Node2D
	if other_node != null:
		var offset := other_node.global_position - global_position
		if offset.length_squared() > 0.0001:
			direction = offset.normalized()
	return maxf(relative.dot(direction), 0.0)


## The hull's mass: section 13's per-class column, resolved into the snapshot by
## ShipFit. Read dynamically so the migration does not depend on M2's field landing
## first; a snapshot without it is announced once in `setup` (see
## UNRESOLVED_HULL_MASS) rather than flown at a silent, wrong weight.
func _hull_mass() -> float:
	if _stats == null:
		return UNRESOLVED_HULL_MASS
	var mass: Variant = _stats.get(&"hull_mass")
	if (mass is float or mass is int) and float(mass) > 0.0:
		return float(mass)
	return UNRESOLVED_HULL_MASS


## A peer that carries no simulated mass of its own (a wall, a station, anything that
## is not a rigid body) is immovable, which the reduced mass reads as an infinite
## mass.
func _peer_mass(other: Node) -> float:
	var rigid := other as RigidBody2D
	if rigid == null:
		return INF
	return rigid.mass


## The launch's damage multiplier (CONTRACTS section 20), read null-tolerantly: a hull
## before `setup` (a scene smoke test, a probe) has no snapshot and reads 1.0, and a
## snapshot without the field reads 1.0 too, so the ram path is byte-identical to
## pre-S7 when no computer is fitted.
func _damage_scale() -> float:
	if _stats == null:
		return 1.0
	var value: Variant = _stats.get(&"damage_mult")
	if value is float or value is int:
		return float(value)
	return 1.0


## Embers' projectile-side seam (CONTRACTS section 20): a shot the player fired that
## landed on an NPC hull heals this hull's shield by `PlayerState`'s own read of the
## delivered amount. The fraction is the weapons component's (its Embers flag names
## it), so this stays a dumb additive: the caller decides the amount, this clamps it
## at `shield_max`. A hull with no state (a probe's bare ship) is a no-op.
func heal_from_damage(dealt: float) -> void:
	if _state == null or dealt <= 0.0:
		return
	_state.set_shield(minf(_state.shield + EMBERS_FRACTION * dealt, _state.shield_max))


func _peer_velocity(other: Node) -> Vector2:
	var rigid := other as RigidBody2D
	if rigid != null:
		return rigid.linear_velocity
	return Vector2.ZERO


## The hull's radius, read off the scene's own collision shape (the art-derived
## half-length). Used only to size the body's inertia, once per launch.
func _hull_radius() -> float:
	if _body == null:
		return 0.0
	var shape := _body.get_node_or_null(NodePath(HULL_SHAPE_NODE)) as CollisionShape2D
	if shape == null or not (shape.shape is CircleShape2D):
		return 0.0
	return (shape.shape as CircleShape2D).radius


## The body's inertia is set rather than left automatic so the torque maths has one
## known number: `m * r^2 / 2` is the circle's own moment (Godot computes exactly this
## for a CircleShape2D), so the turn torque stays mass-scaled and no hull needs a
## number of its own. A scene without a hull circle leaves the body automatic.
func _angular_inertia() -> float:
	var radius := _hull_radius()
	if radius <= 0.0:
		return 0.0
	return 0.5 * _hull_mass() * radius * radius


## ENGINE_SPEC section 13's handling column, as the accelerations ruling 8 turns into
## forces. The engine arithmetic is the hybrid model's own (max_speed / accel_time,
## max_speed / coast_time, turn_rate / turn_spinup), so nothing is retuned: the
## section 3.2 times stay the shipped times.
func _accel_rate() -> float:
	if _stats.accel_time <= 0.0:
		return _stats.max_speed
	return _stats.max_speed / _stats.accel_time


func _coast_rate() -> float:
	if _stats.coast_time <= 0.0:
		return _stats.max_speed
	return _stats.max_speed / _stats.coast_time


func _spin_rate() -> float:
	if _stats.turn_spinup <= 0.0:
		return _stats.turn_rate
	return _stats.turn_rate / _stats.turn_spinup


## Coast decay, sized from coast_time: 1 / coast_time is the decay rate, so a hull
## with nothing commanded loses most of its speed over its class's coast_time (the
## hybrid model's linear ramp reached zero there; a real damper arrives with an
## exponential tail instead, and both envelopes are measured in the migration probe).
## The commanded coast (throttle released, autopilot ramping down) still reaches
## zero at coast_time, because that deceleration is the class's own coast rate and the
## damp is compensated for along the thrust axis (`_step_speed`).
##
## This is the **forward** decay: `coast_time` is the resolved row the ruling's
## `COAST_TIME_MULT` doubles, which is what gives the ship its carry back.
func _linear_damp() -> float:
	if _stats == null or _stats.coast_time <= 0.0:
		return 0.0
	return 1.0 / _stats.coast_time


## The sideways decay (CONTRACTS section 14's `LATERAL_DAMP_MULT`): today's damp, held where
## the combat wave's x 0.50 retune left it, whatever the forward column did. The resolved
## `coast_time` already carries `COAST_TIME_MULT`, so dividing it back out is what makes this
## "the amount of today's damp the ruling keeps" rather than a second handling table; the
## sideways axis is the one the body does *not* damp twice, so the difference between this
## and `_linear_damp()` is `_step_lateral_drag`'s explicit drag.
func _lateral_damp() -> float:
	if _stats == null or _stats.coast_time <= 0.0:
		return 0.0
	return SHIP_FIT.COAST_TIME_MULT * SHIP_FIT.LATERAL_DAMP_MULT / _stats.coast_time


## The extra sideways drag alone: the section the explicit lateral drag adds on top of the
## body's own damp. `LATERAL_DAMP_MULT` 0.0 leaves nothing, so the sideways decay rides the
## forward revert instead (the constant's own reversal).
func _lateral_extra_damp() -> float:
	return maxf(_lateral_damp() - _linear_damp(), 0.0)


## The same sizing for the angular axis, from turn_spinup: a spinning hull with
## nothing commanded loses its turn rate over its class's spin-up time.
func _angular_damp() -> float:
	if _stats == null or _stats.turn_spinup <= 0.0:
		return 0.0
	return 1.0 / _stats.turn_spinup


## Hand the launch snapshot's mass and the class's damp to the body. The scene carries
## only the physics *contract* (contact monitor, no sleep, no gravity, damp modes);
## every number here comes from the snapshot, so no class value lives in two places.
func _apply_rigid_body() -> void:
	if _body == null:
		return
	_body.mass = _hull_mass()
	_body.inertia = _angular_inertia()
	_body.linear_damp = _linear_damp()
	_body.angular_damp = _angular_damp()
	_last_velocity = _body.linear_velocity
	if _stats != null and _hull_mass() <= UNRESOLVED_HULL_MASS:
		push_warning(
			"PlayerShip: ShipStats carries no hull_mass for this hull; flying at the "
			+ "unit mass (collision damage and impulses are charged per mass)."
		)


func _max_speed() -> float:
	return _stats.max_speed * _boost_multiplier()


## The hull's speed along its own nose, which is the axis the thrust law works on.
func _velocity_along_heading() -> float:
	if _body == null:
		return 0.0
	return _body.linear_velocity.dot(Vector2.RIGHT.rotated(_heading()))


## Boosters (section 3.2, 09 section 3.5): the fitted ids arrive in ShipStats and
## their activation numbers are ShipFit's module data, so nothing is duplicated
## here. The fold-blink seam is `has_booster`: a fit carrying `b_fold` activates
## nothing in v1 (its movement lands with slice 4).
func _update_boosters(delta: float) -> void:
	if _boost_cooldown > 0.0:
		_boost_cooldown = maxf(_boost_cooldown - delta, 0.0)
	if _boost_remaining > 0.0:
		_boost_remaining = maxf(_boost_remaining - delta, 0.0)
		## Ruling 11 / section 13: the afterburner runs on the tank, BOOST_FUEL per
		## second through the spending gate. A tank that cannot pay for the frame ends
		## the burn at once, so a dry tank's afterburner dies the frame it runs dry
		## instead of burning on credit.
		if not _burn_boost_fuel(delta):
			_boost_remaining = 0.0
	if _boost_remaining > 0.0 or _boost_cooldown > 0.0:
		return
	if not has_booster(BOOSTER_AFTERBURNER):
		return
	if not InputMap.has_action(BOOST_ACTION) or not Input.is_action_pressed(BOOST_ACTION):
		return
	## The burn is charged *before* the afterburner lights: an empty tank refuses to arm
	## it (ruling 14 locks boost out) and the arm frame pays its own share, so a lit
	## afterburner has burned BOOST_FUEL for every frame it ran.
	if not _burn_boost_fuel(delta):
		return
	var effect := _booster_effect(BOOSTER_AFTERBURNER)
	_boost_remaining = float(effect.get(&"duration", 0.0))
	## S7 (CONTRACTS section 20): Spry shortens the afterburner's cooldown, the one
	## ship-stat affix this file applies - `ShipStats.booster_cooldown_mult` is the
	## fitted boosters' `1 + sum(spry)` (0.85 for the -0.15 band, so 8.0 s -> 6.8 s).
	## Null-tolerant like every other snapshot read, so a hull before `setup` keeps 1.0.
	_boost_cooldown = float(effect.get(&"cooldown", 0.0)) * _booster_cooldown_scale()
	## The activation, not the burn: FX_SPEC section 7.1's dash charge and AUDIO_SPEC
	## section 4.5's S12 cue both hang off this one event, and this is the only line that
	## lights a burner, so neither can fire twice in a burn.
	_on_booster_activated()


## The afterburner's burn (ruling 11, section 13's BOOST_FUEL 3.0/s) through
## `PlayerState.try_spend_fuel` -- the one gate boost and the dash share, so the tank
## itself is the authority on whether a booster may run. A hull with no reactor yet (a
## scene smoke test before `setup`) has no tank to bill and keeps the booster seam
## working, exactly as `_manual_throttle` tolerates a missing input action.
func _burn_boost_fuel(delta: float) -> bool:
	if _state == null:
		return true
	return _state.try_spend_fuel(BOOST_FUEL * delta)


func _boost_multiplier() -> float:
	if _boost_remaining <= 0.0:
		return 1.0
	return float(_booster_effect(BOOSTER_AFTERBURNER).get(&"boost_speed_mult", 1.0))


func _booster_effect(id: StringName) -> Dictionary:
	var module: Dictionary = ShipFit.MODULES.get(id, {})
	var effects: Variant = module.get(&"effects", {})
	if effects is Dictionary:
		return effects
	var empty: Dictionary = {}
	return empty


## Spry's ship-level multiplier (CONTRACTS section 20), `ShipStats
## .booster_cooldown_mult`: the fitted booster instances' `1 + sum(spry)`, read
## null-tolerantly so a hull before `setup` (a smoke test, a probe) keeps 1.0.
func _booster_cooldown_scale() -> float:
	if _stats == null:
		return 1.0
	var value: Variant = _stats.get(&"booster_cooldown_mult")
	if value is float or value is int:
		return float(value)
	return 1.0


## 09 section 4.5 / ENGINE_SPEC section 4.3: the W slot buys the tool, so the mount
## follows the resolved fit. A fit without `w_mining` carries no laser node at all
## (game.gd's reticle push and the trigger both read `_laser` being absent), and a
## later hull swap to a fit without the module releases the node again.
func _sync_mining_laser() -> void:
	if not _has_mining_module():
		_release_mining_laser()
		return
	_mount_mining_laser()
	_bind_laser()


func _has_mining_module() -> bool:
	return _fit_ids.has(MINING_MODULE)


func _release_mining_laser() -> void:
	if _laser == null:
		return
	_laser_active = false
	remove_child(_laser)
	_laser.queue_free()
	_laser = null


## The laser scene is W3's; it is mounted by guarded path, the same convention
## game.gd uses for the HUD, so this scene loads before W3's file lands.
func _mount_mining_laser() -> void:
	if _laser != null:
		return
	var existing := get_node_or_null(NodePath(MINING_LASER_NODE))
	if existing != null and not existing.is_queued_for_deletion():
		_laser = existing
		return
	if not ResourceLoader.exists(MINING_LASER_SCENE):
		return
	var packed := load(MINING_LASER_SCENE) as PackedScene
	if packed == null:
		return
	_laser = packed.instantiate()
	_laser.name = MINING_LASER_NODE
	add_child(_laser)


func _bind_laser() -> void:
	if _laser == null or _stats == null:
		return
	if _laser.has_method(&"bind"):
		_laser.call(&"bind", _stats)


## Section 4.3: the fitted weapons ride the same W-slot rule as the mining laser. A fit
## with no weapon module carries no weapon node, and a later hull swap to such a fit
## releases it again, so the trigger and the HUD's slots both read "no guns" the same way
## they read "no laser" today.
func _sync_weapons() -> void:
	if not _has_weapon_module():
		_release_weapons()
		return
	_mount_weapons()
	_bind_weapons()


## Whether the launched fit spends any slot on a weapon. `WeaponComponent.weapon_id`
## normalizes module ids (`w_laser` -> `laser`) and answers `&""` for anything the family
## table does not know, so an unknown id is not a gun.
func _has_weapon_module() -> bool:
	for id: StringName in _fit_ids:
		if WEAPONS.weapon_id(id) != &"":
			return true
	return false


func _release_weapons() -> void:
	if _guns == null:
		return
	remove_child(_guns)
	_guns.queue_free()
	_guns = null


## Mounted by guarded path, the same convention the mining laser and the HUD use, so this
## scene loads before W1's file lands in a headless run.
func _mount_weapons() -> void:
	if _guns != null:
		return
	var existing := get_node_or_null(NodePath(WEAPONS_NODE))
	if existing != null and not existing.is_queued_for_deletion():
		_guns = existing as Node2D
		return
	var script := load(WEAPONS_SCRIPT) as GDScript
	if script == null:
		return
	_guns = script.new() as Node2D
	if _guns == null:
		return
	_guns.name = WEAPONS_NODE
	add_child(_guns)


## The launch handshake (pinned interface item 2): the resolved snapshot, the live pools
## and the fit's module ids. The component keeps the whole list (six families, five
## groups) and clamps the selected group itself.
func _bind_weapons() -> void:
	if _guns == null or _stats == null or _state == null:
		return
	if _guns.has_method(&"setup"):
		_guns.call(&"setup", _stats, _state)
	if _guns.has_method(&"set_fitted"):
		_guns.call(&"set_fitted", _fit_ids)


## Hold `mine` (E) to fire the mining laser (ENGINE_SPEC section 4.3). The laser
## owns its range, cycle and targeting; the ship only holds the trigger. The W-slot
## gate is repeated here so a laser node authored into the scene cannot be fired by
## a fit that does not carry `w_mining`.
func _update_mining_laser() -> void:
	if not _has_mining_module() or _laser == null or not _laser.has_method(&"set_active"):
		return
	var active := InputMap.has_action(MINE_ACTION) and Input.is_action_pressed(MINE_ACTION)
	if active == _laser_active:
		return
	_laser_active = active
	_laser.call(&"set_active", active)


## Section 4.4, and the contract pinned in CONTRACTS sections 4 and 8.1: the hull's
## physics frame *is* the reactor's frame, so the refill (`energy_regen` at the
## reactor's efficiency) and the fuel-cell cooldown advance here, once per physics
## step, whatever the throttle is doing. Nothing else in the shipped game steps the
## reactor, so without this call the two pools never refill in flight.
func _step_reactor(delta: float) -> void:
	if _state == null:
		return
	_state.tick(delta)


## Section 11's `consume_fuel_cell` key is ruling 13's in-flight jerry can: one
## `fuel_cell` cargo item becomes FUEL_CELL_UNITS of tank fuel, off cooldown, and it is
## the only door out of Emergency Flight Mode in flight. Polled the way every other
## one-shot in the shipped game is (game.gd reads its actions with the same call) and
## guarded, so a hull on a build whose input map has not been patched behind it is
## still safe. A refused burn -- cooling down, no cell aboard, tank already full -- is
## a silent no-op: the fuel bar is the feedback.
func _update_fuel_cell() -> void:
	if _state == null:
		return
	if not InputMap.has_action(FUEL_CELL_ACTION):
		return
	if not Input.is_action_just_pressed(FUEL_CELL_ACTION):
		return
	_state.consume_fuel_cell()


func _release_state() -> void:
	if _state == null:
		return
	PROJECTILE.release_thruster(self)
	if _state.hull_changed.is_connected(_on_hull_changed):
		_state.hull_changed.disconnect(_on_hull_changed)
	if _state.shield_changed.is_connected(_on_shield_changed):
		_state.shield_changed.disconnect(_on_shield_changed)
	if _state.died.is_connected(_on_hull_death):
		_state.died.disconnect(_on_hull_death)


func _on_hull_changed(current: float, _maximum: float) -> void:
	_note_vitals(_last_hull, current)
	_last_hull = current
	_note_damage_state()


## ENGINE_SPEC section 7's death, the hull's own half: the blast is FX_SPEC section
## 1.4's explosion plus section 7.2's secondary, on the wreck's own position, and the
## shield's bed stops with the ship that was holding it. What the death means for the
## hold, the wreck and the respawn stays `game.gd`'s (`_on_ship_died`).
func _on_hull_death() -> void:
	PROJECTILE.spawn_hull_death(self, self)
	PROJECTILE.release_shield(self)
	## A wreck does not thrust: the bed goes out by its own cue and the emitters stop with
	## the hull they were parented to.
	PROJECTILE.release_thruster(self)
	PROJECTILE.clear_thruster_trails(self)
	_thruster_trails.clear()


## FX_SPEC sections 7.1/7.3, the damage state the HUD's own critical line marks
## (section 1.8's "hull fraction < 25 %"): below it the hull trails the plume, above it
## the plume comes off again.
func _note_damage_state() -> void:
	if _state == null or _state.hull_max <= 0.0:
		return
	if _state.hull / _state.hull_max < PROJECTILE.LOW_HULL_FRACTION:
		PROJECTILE.spawn_smoke_plume(self)
		return
	PROJECTILE.clear_smoke_plume(self)


## One frame of the owner's request: the thruster's flame (FX_SPEC section 1.3's
## amendment, one emitter per anchor) and the thruster's hum (AUDIO_SPEC section 4.5).
##
## The two share the section's own floor but not the same test: the trail is *active* while
## the thrust input is held or the ratio is at or above 0.15 (the flame reads whether the
## stick is down), while the bed's held state carries the 0.15/0.10 hysteresis and lives
## in the manager, which is why one call asks and the answer is the manager's.
##
## **S5 (09 section 11, CONTRACTS section 17): which anchor row fires follows the stick.**
## Thrust lights the rear row, a negative throttle (S = reverse + brake) the front row,
## a sideways stick the side it points at, and a coasting hull (no stick, ratio at or
## above the floor) the rear row -- the pre-S5 drift read. A hull with a measured map
## carries all four rows as one emitter list, so the emitters never move or rebuild when
## the mode changes; only their flags do. A hull without a map answers its derived rear
## row for every mode, which is the shipped behaviour unchanged.
##
## The two extra arguments default to the pre-S5 shape: `_update_thrust_feedback(true)`
## (a probe, a fixture) is "the stick is forward", and the derived rows answer it exactly
## as they always did.
func _update_thrust_feedback(thrusting: bool, throttle: float = 0.0, strafe: float = 0.0) -> void:
	var frame := thruster_frame(thrusting, throttle, strafe)
	var active := thrusting or _speed_ratio >= PROJECTILE.TRAIL_RATIO_MIN
	_thruster_trails = PROJECTILE.sync_thruster_trails(
		self, frame[&"anchors"], _speed_ratio, active, frame[&"flags"]
	)
	PROJECTILE.hold_thruster(self, _speed_ratio, thrusting)


## One frame's thruster picture (S5, 09 section 11): the anchors to draw and, in the same
## order, which of them fire. The union of the hull's own rows - rear, front, left, right
## for a mapped hull, the one derived rear row otherwise - so the emitter set is stable
## across a mode change; a hull with no map answers an empty flag list and the sync falls
## back to its single `active` argument.
##
## `throttle` is the raw stick, so its sign picks thrust from brake/retro; a caller that
## hands only `thrusting` (the probes) is read as a forward stick, which is what the bool
## has always meant.
func thruster_frame(thrusting: bool, throttle: float = 0.0, strafe: float = 0.0) -> Dictionary:
	var anchors: Array[Vector2] = []
	var flags: Array[bool] = []
	if not ShipFit.is_mapped(_hull_id):
		anchors = _derived_anchors()
		return {&"anchors": anchors, &"flags": flags}
	var retro := throttle < 0.0
	var forward := not retro and (throttle > 0.0 or thrusting)
	## The drift read is the pre-S5 flame: **no stick at all** (no throttle either way, no
	## strafe) while the hull is still above the ratio's own floor. A hull braking or
	## strafing has a stick down and lights its own row instead.
	var stick := forward or retro or not is_zero_approx(strafe)
	var drift := not stick and _speed_ratio >= PROJECTILE.TRAIL_RATIO_MIN
	for mode: StringName in THRUSTER_MODES:
		var firing := false
		match mode:
			&"rear":
				firing = forward or drift
			&"front":
				firing = retro
			&"left":
				firing = strafe < 0.0
			&"right":
				firing = strafe > 0.0
		for anchor: Vector2 in thruster_anchors(mode):
			anchors.append(anchor)
			flags.append(firing)
	return {&"anchors": anchors, &"flags": flags}


## FX_SPEC section 6 row 3 / section 7.1's "intermittent electrical arcs" while the hull is
## below the 25 % line: one `fx_arc_spark.png` burst every 1.6-2.6 s (the section's own
## proposed cadence), drawn at a point on the hull's own radius. The spawn is
## `Projectile.spawn_arc_spark` - the shipped FEEDBACK row and helper the railgun's own hit
## uses - so there is no second spawn path for the same sheet.
func _update_damage_arcs(delta: float) -> void:
	if _state == null or _state.hull_max <= 0.0:
		_arc_clock = 0.0
		return
	if _state.hull / _state.hull_max >= PROJECTILE.LOW_HULL_FRACTION:
		_arc_clock = 0.0
		return
	if _arc_next <= 0.0:
		_arc_next = _arc_rng.randf_range(ARC_INTERVAL_MIN, ARC_INTERVAL_MAX)
	_arc_clock += delta
	if _arc_clock < _arc_next:
		return
	_arc_clock = 0.0
	_arc_next = _arc_rng.randf_range(ARC_INTERVAL_MIN, ARC_INTERVAL_MAX)
	_arc_count += 1
	PROJECTILE.spawn_arc_spark(self, _arc_point())


## A point on the hull's own edge, at the hull's own art-derived radius - the same figure
## the aim deadzone and the body's inertia read, so the arcs land on the drawn hull rather
## than at an invented distance from it.
func _arc_point() -> Vector2:
	var radius := _hull_radius()
	return global_position + Vector2.RIGHT.rotated(_arc_rng.randf_range(0.0, TAU)) * radius


## The afterburner lighting, the one event FX_SPEC section 7.1 (dash charge) and
## AUDIO_SPEC section 4.5 (S12) both hang off. `b_fold`'s own dash is slice 4's, so only
## the afterburner is here and its charge waits with that movement.
func _on_booster_activated() -> void:
	_boost_activations += 1
	PROJECTILE.play_boost(self)
	var parent := get_parent()
	PROJECTILE.spawn_dash_charge(parent if parent != null else self, global_position)


func _on_shield_changed(current: float, _maximum: float) -> void:
	_note_vitals(_last_shield, current)
	_last_shield = current


## Regen raises a pool; only a decrease is damage (section 4.2's regen delay
## lands in slice 2, and the check keeps the warp channel from breaking on it).
func _note_vitals(previous: float, current: float) -> void:
	if not _vitals_seeded or current >= previous:
		return
	_damage_quiet = 0.0
	damage_taken.emit(previous - current)
