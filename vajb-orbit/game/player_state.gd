class_name PlayerState
extends Resource
## The only gameplay to HUD channel. Contract: docs/design/IMPLEMENTATION_PLAN.md section 3.9.

signal hull_changed(current: float, maximum: float)
signal shield_changed(current: float, maximum: float)
signal weapon_changed(slot: int, weapon_id: StringName, ammo: int, ammo_max: int)
signal cargo_changed(used: int, maximum: int)
signal died

const WEAPONS: Array[StringName] = [&"laser", &"cannon", &"rocket", &"mine", &"plasma"]
const AMMO_DEFAULT := 300

var hull_max: float = 1000.0
var shield_max: float = 600.0
var cargo_max: int = 40
var hull: float
var shield: float
var ammo: Array[int]
var ammo_max: Array[int]
var cargo_used: int


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
func damage(amount: float, bypass_shield: bool = false) -> void:
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
