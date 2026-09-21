class_name PlayerState
extends Resource
## The only gameplay to HUD channel. Contract: docs/design/IMPLEMENTATION_PLAN.md section 3.9.
##
## Engine slice 0 adds the reactor chain (ENGINE_SPEC section 4.4, rulings 10-14):
## the `energy` buffer and the consumable `fuel` reserve, their two signals (the
## hull/shield pair's mirror), the spending gates (`try_spend_energy` for slice 2's
## weapons, `try_spend_fuel` for boost and dash) and the Emergency Flight Mode
## (fuel 0: boost and dash lock out, thrust is ignored -- the hull reads
## `emergency_mode` -- and the reactor runs at `reactor_efficiency` 0.7). Fuel
## burns only while energy is *spent* (`FUEL_PER_ENERGY` toll), on boost and on a
## dash; coasting and idling burn nothing (ruling 11).
##
## The pools are seeded at launch from the `ShipStats` snapshot (ENGINE_SPEC
## section 9) and a `tick(delta)` drives the reactor refill and the fuel-cell
## cooldown; both are the ship's physics frame's business, so they are helpers
## here rather than a `_process` of their own.

signal hull_changed(current: float, maximum: float)
signal shield_changed(current: float, maximum: float)
signal weapon_changed(slot: int, weapon_id: StringName, ammo: int, ammo_max: int)
signal cargo_changed(used: int, maximum: int)
signal energy_changed(current: float, maximum: float)
signal fuel_changed(current: float, maximum: float)
signal died

const WEAPONS: Array[StringName] = [&"laser", &"cannon", &"rocket", &"mine", &"plasma"]
const AMMO_DEFAULT := 300

## ENGINE_SPEC section 13 "Energy & fuel (rulings 10-14)", verbatim, plus section
## 4.4's pool bases (100 / 200, 5 per second). `ShipFit` resolves the same bases
## into `ShipStats`; these are the fallback a `PlayerState` created without a
## snapshot (probes, a scene smoke test) still runs on.
const ENERGY_MAX_DEFAULT := 100.0
const FUEL_MAX_DEFAULT := 200.0
const ENERGY_REGEN_DEFAULT := 5.0

## Ruling 11's fuel toll: every 1 point of Energy spent burns this much Fuel.
const FUEL_PER_ENERGY := 0.10

## Ruling 14's emergency penalty: the reactor runs at this multiplier of
## `energy_regen` while `emergency_mode` holds.
const EMERGENCY_REGEN_MULT := 0.7

## Ruling 13's in-flight jerry can (section 4.4): one `fuel_cell` cargo item
## becomes this much tank fuel, once per cooldown.
const FUEL_CELL_ITEM: StringName = &"fuel_cell"
const FUEL_CELL_UNITS := 40.0
const FUEL_CELL_COOLDOWN := 10.0

## The cargo owner. `PlayerProfile` is the only mutator of cargo (17 section 5
## rule 2), so the fuel cell is spent through it, never on this resource.
const PROFILE_SERVICE: StringName = &"PlayerProfile"

var hull_max: float = 1000.0
var shield_max: float = 600.0
var cargo_max: int = 40
var hull: float
var shield: float
var ammo: Array[int]
var ammo_max: Array[int]
var cargo_used: int

## The two pools and their maxima. Maxima are the `ShipStats` snapshot's figures
## (section 9), so a hull/armour swap is felt in the pools from the first frame.
var energy_max: float = ENERGY_MAX_DEFAULT
var fuel_max: float = FUEL_MAX_DEFAULT
var energy_regen: float = ENERGY_REGEN_DEFAULT
var energy: float
var fuel: float

## Ruling 13's cooldown, driven by `tick`. Public and read-only in spirit: the
## HUD/input layer asks whether a cell is ready, it never sets this.
var fuel_cell_cooldown: float = 0.0

## The last `damage` call's context (section 4.2 item 5: the slice-2 pipeline
## carries `direction` here for slice 3's quadrants). Accepted and recorded now,
## no-op until the quadrants exist.
var _last_damage_ctx: Dictionary = {}


func setup() -> void:
	hull = hull_max
	shield = shield_max
	cargo_used = 0
	ammo = []
	ammo_max = []
	for slot in WEAPONS.size():
		ammo.append(AMMO_DEFAULT)
		ammo_max.append(AMMO_DEFAULT)
	hull_changed.emit(hull, hull_max)
	shield_changed.emit(shield, shield_max)
	cargo_changed.emit(cargo_used, cargo_max)
	for slot in WEAPONS.size():
		weapon_changed.emit(slot, WEAPONS[slot], ammo[slot], ammo_max[slot])
	## Section 4.4: the pools are seeded full at launch (the profile's persisted
	## fuel is applied by the docking/launch handshake, not here).
	energy = energy_max
	fuel = fuel_max
	fuel_cell_cooldown = 0.0
	energy_changed.emit(energy, energy_max)
	fuel_changed.emit(fuel, fuel_max)


func set_hull(value: float) -> void:
	var was_alive := hull > 0.0
	hull = clampf(value, 0.0, hull_max)
	hull_changed.emit(hull, hull_max)
	if was_alive and hull <= 0.0:
		died.emit()


## ENGINE_SPEC section 4.2 item 1 (amending IMPLEMENTATION_PLAN section 3.9): a live
## shield takes the hit with **no carry-over**, so an amount larger than the shield
## still leaves the hull untouched (section 4.1: "no hull damage while shield > 0").
## `bypass_shield` is section 4.1's kinetic/missile/deployable rule, which lands on
## the hull directly. Both pools keep their existing signals, so the HUD and the
## ship's damage-quiet gate see the same channel as before.
##
## `ctx` is section 4.2 item 5's combat context (`direction` from slice 2, routed
## by slice 3's quadrants). It is accepted and recorded on every hit and is a no-op
## until those quadrants exist, which is why the parameter is last and defaulted.
func damage(amount: float, bypass_shield: bool = false, ctx: Dictionary = {}) -> void:
	_last_damage_ctx = ctx
	if amount <= 0.0:
		return
	if not bypass_shield and shield > 0.0:
		set_shield(shield - amount)
		return
	set_hull(hull - amount)


func set_shield(value: float) -> void:
	shield = clampf(value, 0.0, shield_max)
	shield_changed.emit(shield, shield_max)


## Always emits weapon_changed for the slot, so re-setting the current value
## doubles as the "this slot is now active" announcement the HUD listens for.
func set_ammo(slot: int, value: int) -> void:
	if slot < 0 or slot >= ammo.size():
		return
	ammo[slot] = clampi(value, 0, ammo_max[slot])
	weapon_changed.emit(slot, WEAPONS[slot], ammo[slot], ammo_max[slot])


func set_cargo_used(used: int) -> void:
	cargo_used = clampi(used, 0, cargo_max)
	cargo_changed.emit(cargo_used, cargo_max)


## --- The reactor chain (ENGINE_SPEC section 4.4, rulings 10-14) --------------


## True while the tank is dry: section 4.4's Emergency Flight Mode. Boost and dash
## lock out (both spend Fuel through `try_spend_fuel`), the hull ignores thrust
## input (it reads this flag), turning stays on the reaction wheels and the reactor
## runs at `EMERGENCY_REGEN_MULT`. Burning a fuel cell ends the mode immediately,
## because the mode is exactly this condition on `fuel`.
var emergency_mode: bool:
	get:
		return fuel <= 0.0


## Section 4.4's reactor efficiency: 0.7 under Emergency Flight Mode, 1.0
## otherwise. The caller multiplies `energy_regen` by it (the penalty lands on the
## refill, never on the pool's ceiling).
func reactor_efficiency() -> float:
	return EMERGENCY_REGEN_MULT if emergency_mode else 1.0


## Whether a fuel cell may be burned right now: off cooldown, one `fuel_cell` in
## the hold, and the tank not already full (the conversion is clamped at the tank's
## ceiling, so a full tank would waste the cell -- see the M2 report's note).
func fuel_cell_ready() -> bool:
	if fuel_cell_cooldown > 0.0:
		return false
	if fuel >= fuel_max:
		return false
	var profile := _profile()
	if profile == null or not profile.has_method(&"cargo_qty"):
		return false
	return int(profile.call(&"cargo_qty", FUEL_CELL_ITEM)) > 0


## Ruling 13's in-flight refuel: one `fuel_cell` cargo item becomes
## `FUEL_CELL_UNITS` tank fuel (10 s cooldown). The cargo is spent through
## `PlayerProfile` -- the only mutator of cargo -- and only if the conversion can
## actually happen, so a refused call costs nothing.
func consume_fuel_cell() -> bool:
	if not fuel_cell_ready():
		return false
	var profile := _profile()
	if not bool(profile.call(&"remove_cargo", FUEL_CELL_ITEM, 1)):
		return false
	fuel_cell_cooldown = FUEL_CELL_COOLDOWN
	set_fuel(fuel + FUEL_CELL_UNITS)
	return true


## The spending gate slice 2's weapons draw through (section 4.4: laser 6 E/s,
## plasma 10 E/s, mining 5 E/s). Returns false when the pool is short, so a caller
## can hold fire or dry-click; a successful spend burns `FUEL_PER_ENERGY` Fuel per
## point of Energy through the reactor (ruling 11). `amount` 0 is a no-op success;
## a negative amount is refused.
func try_spend_energy(amount: float) -> bool:
	if amount < 0.0:
		return false
	if amount == 0.0:
		return true
	if amount > energy:
		return false
	set_energy(energy - amount)
	## The toll takes what the tank holds: an empty tank cannot make the reactor
	## refuse a shot (the hull is in emergency mode anyway) and the pool never goes
	## negative.
	if fuel > 0.0:
		set_fuel(fuel - amount * FUEL_PER_ENERGY)
	return true


## Boost and dash burn the tank directly (section 4.4: `BOOST_FUEL` 3/s while the
## afterburner runs, `DASH_FUEL` 25 per fold burst, both owned by the caller).
## False when the pool is short -- which is also the emergency-mode lockout, since
## emergency mode is `fuel <= 0`.
func try_spend_fuel(amount: float) -> bool:
	if amount < 0.0:
		return false
	if amount == 0.0:
		return true
	if amount > fuel:
		return false
	set_fuel(fuel - amount)
	return true


## One frame of the reactor chain, called by the hull: the refill (`energy_regen`
## at `reactor_efficiency`) and the fuel-cell cooldown. Section 4.4 is explicit
## that the refill is demand-driven -- "no idle draw, no free regen while nothing
## runs" -- so a full pool regenerates nothing, and the refill only ever runs on a
## pool that was spent into.
func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	if fuel_cell_cooldown > 0.0:
		fuel_cell_cooldown = maxf(fuel_cell_cooldown - delta, 0.0)
	if energy >= energy_max:
		return
	set_energy(energy + energy_regen * reactor_efficiency() * delta)


func set_energy(value: float) -> void:
	energy = clampf(value, 0.0, energy_max)
	energy_changed.emit(energy, energy_max)


func set_fuel(value: float) -> void:
	fuel = clampf(value, 0.0, fuel_max)
	fuel_changed.emit(fuel, fuel_max)


## The context of the most recent `damage` call (section 4.2 item 5). Slice 3's
## directional armour reads it; nothing routes on it yet.
func last_damage_ctx() -> Dictionary:
	return _last_damage_ctx.duplicate()


## Anchored at the tree root, like every other service lookup in `game/`: the
## profile is an autoload, so a bare name would resolve against this resource's
## (non-existent) node scope. A resource outside a tree (a probe, a unit test with
## no scene) resolves nothing and every fuel-cell call refuses cleanly.
func _profile() -> Node:
	var loop := Engine.get_main_loop()
	if not loop is SceneTree:
		return null
	var root := (loop as SceneTree).root
	if root == null:
		return null
	return root.get_node_or_null(NodePath(PROFILE_SERVICE))
