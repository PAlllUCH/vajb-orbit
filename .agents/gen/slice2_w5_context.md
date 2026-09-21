# Slice 2, W5 — orchestrator context for this pass (2026-09-21)

Read this before you start, alongside `.agents/gen/slice2_task.md` (the brief) and
the prompt you were dispatched with. It carries the state the four parallel
workers left behind and the rulings that govern your pass.

## 1. What has already landed

| Worker | Files | Evidence |
|---|---|---|
| W1 | `game/weapons.gd` (35 272 B), `game/projectile.gd` (23 243 B), `tests/test_engine2_weapons.gd` (29 tests) | `.agents/gen/slice2_w1_report.md`, probe 95/95 |
| W2 | `game/damage.gd` (new), `game/player_state.gd` (+21 lines) | `.agents/gen/slice2_w2_report.md`, probe 16/16 |
| W3 | `game/npc_registry.gd`, `game/npc_brain.gd`, `game/npc_ship.gd`, `tests/test_engine2_npc.gd` (28 tests) | `.agents/gen/slice2_w3_report.md`, probe 22/22 |
| W4 | `game/loot_tables.gd`, `tests/test_engine2_loot.gd` (13 tests) | `.agents/gen/slice2_w4_report.md` |
| W0/W0b | the slice-2 record in `IMPLEMENTATION_PLAN.md` §9.9; the per-sector NPC band transcribed into `13_heat_bounty.md` §4 | `.agents/gen/slice2_w0_report.md`, `slice2_w0b_report.md` |

**The universal gate is GREEN right now: 168 tests, zero failures, exit 0.**
Measure the total yourself, keep it green, and add your slice-2 wiring tests as
`res://tests/test_engine2_*.gd` (the headless runner discovers them; there is no
registration file).

## 2. The five wiring items W2 measured but could not close — yours

They live in files W2 did not own, so no worker has closed them yet:

1. the player hull has no `take_damage`, so nothing routes an incoming hit into
   `PlayerState.damage`;
2. the ram path passes no context, so the damage call carries no `direction`,
   `impulse` or `family`;
3. nothing seeds `shield_regen` from the launch snapshot;
4. nothing calls `Damage.regen`, so shields never recover in the shipped game;
5. W1 duplicated the delivery seam privately inside `weapons.gd` and
   `projectile.gd` instead of sharing one.

Close all five inside your file set, one measurement each. If the right fix is a
shared seam extracted from W1's files rather than a duplication, say so in your
report as a MED for the reviewer instead of editing files outside your set.

## 3. What W3 shipped to mount

- `npc_registry.gd` — nine archetype rows (the six of §5 plus ruling 24's
  swarmer/sibelon/apex), the §13 per-sector band, doc 13 §3 heat tiers,
  swap-ready sprite paths, seam rows that never spawn.
- `npc_brain.gd` — one state set (IDLE→PATROL/SCAN→ALERT→ENGAGE→FLEE→
  RETURN/DESPAWN), injected line-of-sight with rocks blocking, leash 2 500,
  `AGGRO_COOLDOWN` 5.0. It produces intent only; it applies no forces.
- `npc_ship.gd` — a `RigidBody2D` hull flying on the same physics law as the
  player, `take_damage` mirroring the `Damage` sink, a `died` signal, and
  `engaged_with()` for the warp gate.

Spawn the sector's ships from the registry rows on entry, push hostile (pirates,
swarmers) and neutral (traders) blips, and drive `PlayerShip`'s warp gate from
the real engagement state through W3's query.

## 4. Spec gaps W3 reported instead of inventing — do the same

The human/alien split of the §13 band is not written down (W3 used a stated
fill-order rule and reports it); the patrol count is a proposal; the alien hulls
have no ship-class row in doc 08; the station turret has neither a class row nor
a damage figure; NPC armament is unspecified, so the `fire` intent ships unarmed;
there is no stand-off range and no turret scan radius. Implement what the spec
states, leave the rest as reported seams, and list every gap you worked around.
**Do not invent a number to close one.**

## 5. Two lanes touching files near yours

- **batch-2 already changed `ui/hud/hud.gd`**: the two minimap zoom constants are
  renamed `ZOOM_DELTA_IN` / `ZOOM_DELTA_OUT` and the two `pressed` bindings were
  swapped so `+` zooms in (measured 3200→2400). Keep that change; if you
  restructure around it, say so in your report.
- **The graphics lane's chrome regression is NOT yours.** Measured evidence and
  both fix routes are in `.agents/gen/ui_chrome_regression.md`: the button plates
  are whole sheet cells so the theme stretches a mostly transparent canvas, the
  menu wordmark crop is now empty, the bezel nine-patch band draws 3 px instead
  of 16. The theme is a forbidden file, the assets belong to the graphics lane,
  and the owner holds the routing decision. Do not restyle anything to
  compensate, and do not touch the theme or the plates.

## 6. Standing rulings

- `consume_fuel_cell` is bound to **R**; `cargo_toggle` keeps C.
- Refuel and recharge are free; no CR rate may exist anywhere.
- The `assets/` tree is mid-re-layout by the graphics lane: a failure that is
  only a missing or moved asset path is **environment-deferred**, not a finding.
  Your boot gates must exit 0; if one fails only on an asset path, record it and
  continue.
- No invented numbers. A missing spec value is reported, never guessed.
