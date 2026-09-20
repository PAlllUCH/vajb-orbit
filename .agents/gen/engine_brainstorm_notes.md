# Engine brainstorm — decision log (working notes, not a spec)

Status: closed 2026-09-18 — all forks settled, owner approved the remaining
defaults, and the spec is `ENGINE_SPEC.md` at the workspace root (location
requested by the owner for coder hand-off). This file is the decision trail;
the spec is the contract. Fold into `docs/gameplay/` as doc 18 when the engine
phase closes.

## Grounding

- Engine consumes: 08/09 (hulls, slots, module numbers), 02/06 (mining, loot),
  11/13 (sectors, NPCs, heat), 14 §3 (death/insurance), 01 §6 (vitals on dock).
- Frozen contracts: `PlayerState` channel, HUD API (extend via amendment), input
  map (§3.7 — the engine spec amends it), cargo manifest, `PlayerProfile`.

## Decisions

1. **Control scheme: hybrid.** Direct steer (W/S throttle, A/D turn) always
   available; clicking empty space sets a fly-to order; any manual input
   cancels it. Owner emphasis: real-spaceship inertia, mass-scaled — the
   heavier the hull, the more noticeable.
   - Model: linear inertia (thrust vs drag → coast/overshoot) + angular
     inertia (turns spin up and carry → wide arcs). Mass per hull class
     (amendment to 08 §2), armour plates add mass on top of their speed
     penalty (09 §3.3 synergy), engines buy it back.
   - The click-to-fly autopilot runs the same physics (inertial turn-in,
     brake on arrival) so auto and manual feel like one ship, not two.
   - One per-class handling table in the spec; playtest-tunable, no per-ship
     code.

2. **Weapon model: families × cursor-aim.** Owner decision (2026-09-18).
   - Families: **energy** (laser/blaster/plasma) = instant hit, shields-first
     (cannot touch hull until shield is down); **kinetics** (bolters/cannon/
     railgun) = travelling shots, bypass shields, bite hull; **missiles**
     (rocket) = lock-launch, finite-turn homing, flight time, destructible in
     flight; **mines** = dropped area denial.
   - **All guns fire toward the cursor** (twin-stick); the lock only marks
     (HUD target window, missile homing). Range is per weapon; shots fizzle
     at max range.
   - Consequence: instant shots are dodged by moving off the cursor, so
     mass-inertia makes heavy hulls easier to hit; kinetics trade bypass for
     lead time. (The earlier "energy = tracking with limits" reading is
     superseded.)

3. **Exit rule: fly out only in combat; safe warp home.** Owner decision.
   - Flying to a station (dock) or a gate is the only way out while an enemy
     is engaged — hardcore, no combat escape button.
   - Safe warp: allowed only when no enemy is engaged; a few seconds of
     channel with an animation (breaks if an enemy engages); lands docked at
     the **current sector's station**; no station in the sector → no warp
     (S7 Maw stays hardcore). Gates/corridors keep cross-sector travel.

## Approved defaults

4. Sectors: same arena size, differentiated by backdrop/owner/tier mix/enemy
   mix. 5. Six NPC archetypes on one brain. 6. Guns can break rocks at 10 %
   efficiency. 7. Death drops cargo with a 5-minute recovery window. All
   remaining defaults approved ("everything else looks good").

## Ideas bank (candidate spec content, unapproved)

- `ShipStats` snapshot resolved at launch (09 §5 order) → flight/combat read it.
- Range bands per weapon family; scanner = lock range; rocks block lock (LOS).
- Six NPC archetypes on one brain; hunters tune to fit value (13 §6).
- One reusable sector scene + `sector_registry` spawn tables; 20-min respawns.
- Build slices: 1) sector+flight+mining 2) combat+pirates+loot+death
  3) travel+POIs 4) fit integration+hunters.
