extends "res://game/player_state.gd"
## The M6 re-review's witness state: a real `PlayerState` that counts the hull's
## fuel-cell calls instead of performing the conversion.
##
## Why a witness: `PlayerState.consume_fuel_cell` spends a `fuel_cell` through the
## `PlayerProfile` autoload, which owns the live economy record (`user://profile.cfg`).
## M4's review leaked one `fuel` key into that file (its D3) and M5 avoided it the same
## way. Counting the call proves the half that was missing -- that a *real* R key event
## reaches `PlayerState.consume_fuel_cell` through the hull -- without touching the
## record. The conversion itself (40 fuel, 10 s cooldown, one cell out of the hold) is
## covered by `tests/test_engine2_pools.gd` inside the universal gate and by M2's pools
## probe, both re-run green by this review.

## One per call the hull makes. A held key (once per frame would be a bug) and a second
## press are both visible here.
var consume_calls := 0


func consume_fuel_cell() -> bool:
	consume_calls += 1
	return true
