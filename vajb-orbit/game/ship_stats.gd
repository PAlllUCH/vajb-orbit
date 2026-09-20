class_name ShipStats
extends RefCounted
## Resolved flight/combat snapshot for one hull + fit.
## Flight reads *only* this snapshot (ENGINE_SPEC section 3.3) — no catalogue reads
## and no formula soup in movement code. Produced by `ShipFit.resolve` in the
## 09 section 5 resolution order; field list is the pinned interface of
## ENGINE_SPEC section 9 / the engine-wave-1 brief ("Pinned interfaces" item 1).
## Data, not logic: no nodes, no autoload, no mutation API.
## `boosters` holds the fitted booster module ids in fit order (slice 4 adds the
## fold blink); their activation numbers live in `ShipFit.MODULES`
## (`effects.boost_speed_mult` / `duration` / `cooldown` / `blink_distance`).

var max_speed: float = 0.0
var accel_time: float = 0.0
var coast_time: float = 0.0
var turn_rate: float = 0.0
var turn_spinup: float = 0.0

var hull_max: float = 0.0
var shield_max: float = 0.0
var shield_regen: float = 0.0
var damage_mult: float = 1.0

var lock_range: float = 0.0
var scan_range: float = 0.0
var tractor_range: float = 0.0
var tractor_speed: float = 0.0
var tractor_streams: int = 1
var cargo_max: int = 0

var boosters: Array[StringName] = []
