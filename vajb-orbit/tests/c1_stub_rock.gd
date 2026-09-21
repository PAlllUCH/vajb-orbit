extends "res://game/asteroid.gd"
## C1 probe stub (combat/collision-repair wave, 2026-09-21): the rock's half of a ram.
##
## Shipping `Asteroid` implements no `apply_collision_damage`, so the peer's half that
## `PlayerShip._on_hull_body_entered` offers (`player_ship.gd:478-479`) has nowhere to
## land. This stub is that receiver and nothing else: it records that the offer arrived
## and the amount it carried, which is what lets the probe separate "the rock has no
## sink" from "the contact never happened" and from "the amount was below the floor".
##
## It is probe furniture and never ships: it adds no constant, overrides no shipped
## method and changes no physics number. Instantiate it instead of `asteroid.gd` and
## everything else about the rock (mass, damp, layer, mask, shape, cleave) is the
## shipping class's own.
##
## Contract: `player_ship.gd:478-479` (the offer) and `docs/CONTRACTS.md` section 4
## ("offer the peer's half to `apply_collision_damage(amount)` when the peer has it").

## How many times the ship offered this rock its half of the contact.
var sink_hits := 0

## The total damage so offered, in the pipeline's own units.
var sink_total := 0.0


func apply_collision_damage(amount: float) -> void:
	sink_hits += 1
	sink_total += amount
