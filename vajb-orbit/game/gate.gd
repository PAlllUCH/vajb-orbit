class_name Gate
extends Area2D
## A jump gate ring (11 §2.1/§5, CONTRACTS §19): one per spine link, near the sector's
## primary station, on the bearing of the destination's own map edge.
##
## `setup(dest_sector)` names the destination; `set_origin_sector` names the sector the
## ring stands in, because the fee's `distance` is the number of spine links between the
## two (11 §2.1's "150 CR base + 100 CR per sector of distance"). `fee_for` composes
## 11 §5's multipliers multiplicatively on that base, `jump` runs 17 §5's transaction law
## and starts a 2 s charge-up, and `jumped` is raised when the charge completes so the
## wiring (`game.gd`) can file the vitals and route the `loading` transition.
##
## The ring is an Area2D, but containment is measured geometrically (like the sector's
## dock zone, `sector.gd:dock_zone_contains`) so a headless probe and a test agree with
## the flight frame without a physics world; the collision circle is the physics-side
## twin for a later overlap pass.

const Registry := preload("res://game/sector_registry.gd")
const NpcRegistryScript := preload("res://game/npc_registry.gd")
const EconomyLogScript := preload("res://game/economy_log.gd")

const RingTexture := preload("res://assets/env/poi/env_jump_gate.png")

## `jump`'s return codes (CONTRACTS §19): 0 paid and charging, -1 refused at the Outlaw
## heat tier (13 §3), -2 the account cannot afford the fee. Both refusals write nothing.
const JUMP_OK := 0
const JUMP_REFUSED := -1
const JUMP_FUNDS := -2

## 11 §2.1: "Pay, 2 s charge-up FX, arrive at the destination sector's gate".
const CHARGE_SECONDS := 2.0

## No doc gives the ring's drawn size or its trigger radius. 2048 u art at 0.25 reads
## ~512 u across (11 §2.1's "visible from across the sector") and a 200 u trigger is the
## ring's own opening; both are this file's placement values and one edit reverses them.
const RING_SCALE := 0.25
const TRIGGER_RADIUS := 200.0

## 01 §7's log vocabulary, extended by the gate charge.
const EVENT_GATE := "GATE"

signal jumped(dest_sector: int)

var dest_sector: int = 0
var origin_sector: int = 0

var _charging := false
var _charge_elapsed := 0.0
var _ring: Sprite2D = null


func _ready() -> void:
	if _ring != null:
		return
	_ring = Sprite2D.new()
	_ring.name = "Ring"
	_ring.texture = RingTexture
	_ring.scale = Vector2(RING_SCALE, RING_SCALE)
	add_child(_ring)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = TRIGGER_RADIUS
	shape.shape = circle
	add_child(shape)


## The destination link this ring serves (11 §5: one ring per destination).
func setup(dest_sector_number: int) -> void:
	dest_sector = dest_sector_number


## The sector number this ring stands in, set by the sector that spawned it. The fee's
## distance is `|dest - origin|` along the §2.3 spine.
func set_origin_sector(sector_number: int) -> void:
	origin_sector = sector_number


## 11 §2.1's distance in spine links (adjacent = 1, two away = 2).
func distance_sectors() -> int:
	return Registry.distance(origin_sector, dest_sector)


## The destination's registry name, for the prompt line.
func destination_name() -> String:
	return String(Registry.sector(Registry.sector_id_for(dest_sector)).get(&"name", ""))


## 11 §5's fee, multiplicatively composed on 11 §2.1's base:
## `floor((150 + 100·d) × want × lawless)`, `want` 1.5 at the Wanted tier only (Outlaw
## is refused, never priced) and `lawless` 2.0 into sector 7. Worked rows: adjacent 250,
## two away 350, adjacent-to-7 at Wanted `floor(250 × 1.5 × 2) = 750`.
func fee_for(heat_tier: StringName) -> int:
	var base := (
		Registry.GATE_FEE_BASE + Registry.GATE_FEE_PER_SECTOR * distance_sectors()
	)
	var want := 1.5 if heat_tier == NpcRegistryScript.HEAT_WANTED else 1.0
	var lawless := 2.0 if dest_sector == Registry.LAWLESS_SECTOR else 1.0
	return int(floor(float(base) * want * lawless))


## 17 §5's transaction law, all-or-nothing: verify the heat tier, verify the funds,
## charge, log, then begin the 2 s charge-up. Returns 0 on success, -1 at the Outlaw
## tier and -2 when the account cannot afford the fee; both refusals leave the profile
## byte-identical (no `can_afford`/`spend` call, no log line).
func jump(profile, heat_tier: StringName) -> int:
	if _charging:
		## A second confirm inside the same charge-up is inert: the fee is already paid
		## and the transition is already on its way.
		return JUMP_OK
	if heat_tier == NpcRegistryScript.HEAT_OUTLAW:
		return JUMP_REFUSED
	if profile == null or not profile.has_method(&"can_afford"):
		return JUMP_FUNDS
	var fee := fee_for(heat_tier)
	if not bool(profile.call(&"can_afford", fee)):
		return JUMP_FUNDS
	if not bool(profile.call(&"spend", fee)):
		return JUMP_FUNDS
	EconomyLogScript.append(
		EVENT_GATE,
		Registry.sector_id_for(dest_sector),
		fee,
		-fee,
		int(profile.call(&"credits")),
	)
	_charging = true
	_charge_elapsed = 0.0
	return JUMP_OK


func is_charging() -> bool:
	return _charging


## 0..1 across the 2 s charge-up.
func charge_progress() -> float:
	return clampf(_charge_elapsed / CHARGE_SECONDS, 0.0, 1.0)


## One step of the charge-up clock. `_process` drives it in flight; a probe or a test
## calls it directly so it never depends on frame timing.
func advance_charge(delta: float) -> void:
	if not _charging:
		return
	_charge_elapsed += delta
	if _charge_elapsed < CHARGE_SECONDS:
		return
	_charging = false
	_charge_elapsed = CHARGE_SECONDS
	jumped.emit(dest_sector)


func cancel_jump() -> void:
	_charging = false
	_charge_elapsed = 0.0


## Geometric containment, the dock zone's own rule: a point is "in the ring" within
## TRIGGER_RADIUS of its centre.
func contains(world_position: Vector2) -> bool:
	return global_position.distance_to(world_position) <= TRIGGER_RADIUS


func _process(delta: float) -> void:
	advance_charge(delta)
