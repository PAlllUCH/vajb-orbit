extends "res://game/player_state.gd"
## The M5 probe's witness state: a real `PlayerState` that counts the hull's fuel-cell
## calls instead of performing the conversion.
##
## Why a witness: the shipped `consume_fuel_cell` spends a `fuel_cell` through the
## `PlayerProfile` autoload, which owns the live economy record (`user://profile.cfg`).
## A probe must not burn the player's cargo (the M4 review leaked one `fuel` key into
## that file and had to repair it, L17/L18), and the conversion itself is already
## covered by `tests/test_engine2_pools.gd` and M2's pools probe. Counting the call
## proves the half that was missing -- that the hull's C-key caller reaches the state --
## without touching the record.

## One per call the hull makes, so a held key (once per frame would be a bug) and a
## second press are both visible in the count.
var consume_calls := 0


func consume_fuel_cell() -> bool:
	consume_calls += 1
	return true
