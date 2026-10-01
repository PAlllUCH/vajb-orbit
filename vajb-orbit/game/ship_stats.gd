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
##
## `hull_mass` (tonnes) and the two power pools join in engine slice 0
## (ENGINE_SPEC section 9: "Mass and the power pools enter with slice 0").
## `hull_mass` is the resolved mass the body and the collision formula
## (section 4.2 item 6) carry: the section 13 class column with the armour
## plating's own `mass_add` and, since S22.7 (section 3.2's mass law), its
## `1 + |speed penalty|` ponderous half, both resolved by `ShipFit` on top of
## the class value. `base_mass` is the class column itself, read before any
## module multiplication: the mass the flight forces derive from (the forces
## are the class's, the inertia is the fit's). `energy_max` /
## `energy_regen` / `fuel_max` are the reactor chain's pool figures (section 4.4):
## `PlayerState` reads its maxima from this snapshot, so a module swap is felt in
## the pools from the first frame.
##
## `engine_thrust` is section 3.2's derived thrust law, resolved once here:
## `base_mass x max_speed / accel_time` on the resolved rates, the figure the
## boost burn is proportional to (section 13's `BOOST_FUEL` row).

var max_speed: float = 0.0
var accel_time: float = 0.0
var coast_time: float = 0.0
var turn_rate: float = 0.0
var turn_spinup: float = 0.0
var hull_mass: float = 0.0
var base_mass: float = 0.0
var engine_thrust: float = 0.0

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

var energy_max: float = 0.0
var energy_regen: float = 0.0
var fuel_max: float = 0.0

var boosters: Array[StringName] = []

## Spry's aggregate (CONTRACTS section 20): `1 + sum(spry)` over the fitted booster
## instances, 1.0 when no fitted booster carries the prefix. Spry's stored band is
## negative, so a fitted one reads below 1.0 (0.85 for the -0.15 band), and
## `player_ship.gd` multiplies the catalogue cooldown by it.
var booster_cooldown_mult: float = 1.0
