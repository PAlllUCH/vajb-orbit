class_name Corridor
extends Area2D
## A border corridor (11 §2.2/§5, CONTRACTS §19): a map-edge band marked by nav buoys
## where holding course for 15 s transitions to the neighbouring sector. One per spine
## neighbour, so a sector has one or two.
##
## `setup(dest_sector, edge)` takes the destination and the band the corridor occupies
## in the sector's own centred arena coordinates. `update_presence(delta, position)`
## accrues the hold while the ship is inside and resets it to 0 on exit; **hull damage
## does not interrupt it** (11 §5 tick 2 as built: "holding course" reads as presence,
## not calm), and this file has no damage input at all, so the only writer of the hold
## is presence. `hold_progress()` is the 0..1 fraction, and `crossed` is raised once at
## 15 s so the wiring can file the vitals and route the transition.
##
## Containment is geometric (the dock zone's own rule, `sector.gd:dock_zone_contains`),
## so a headless probe and a test agree with the flight frame without a physics world.

const HOLD_SECONDS := 15.0

signal crossed(dest_sector: int)

var dest_sector: int = 0
var edge: Rect2 = Rect2()

var _hold_elapsed := 0.0
var _holding := false
var _crossed := false


## The destination link and the band this corridor occupies (11 §5).
func setup(dest_sector_number: int, band: Rect2) -> void:
	dest_sector = dest_sector_number
	edge = band


## The 15 s presence hold, 0..1.
func hold_progress() -> float:
	return clampf(_hold_elapsed / HOLD_SECONDS, 0.0, 1.0)


func is_holding() -> bool:
	return _holding


## One presence step: inside accrues, outside resets to 0 (11 §5's rule). The signal
## fires once, on the step that reaches 15 s.
func update_presence(delta: float, world_position: Vector2) -> void:
	if not contains(world_position):
		_hold_elapsed = 0.0
		_holding = false
		return
	_holding = true
	if _crossed:
		return
	_hold_elapsed += delta
	if _hold_elapsed < HOLD_SECONDS:
		return
	_hold_elapsed = HOLD_SECONDS
	_crossed = true
	crossed.emit(dest_sector)


## Back to an unheld corridor, for a probe or a reversal.
func reset_hold() -> void:
	_hold_elapsed = 0.0
	_holding = false
	_crossed = false


func contains(world_position: Vector2) -> bool:
	return edge.has_point(world_position)
