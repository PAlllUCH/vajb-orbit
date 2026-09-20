# Vajb Orbit — Engine Spec (flight, combat, mining, NPCs, sectors)

**Status:** design locked by the owner 2026-09-18; ready to slice into coder waves.
**Location note:** the owner asked for the coder-facing copy at the workspace root
(next to `TESTING_NOTES.md`); fold this into `docs/gameplay/` as doc 18 when the
engine phase closes.
**How to use:** coders read §1–§2, then their slice in §14, numbers in §13,
amendments in §12. Docs 01–17 stay the source of truth for every number they
already own; this spec only adds what the engine needs. `TESTING_NOTES.md`
(batch-2 fixes) is a separate, independent work list.

---

## 1. The engine in one breath

Launch → fly (hybrid controls, mass-scaled inertia) → mine rocks, fight or
avoid NPCs, collect pickups → dock at a station, or safe-warp home when
nothing is engaged. Death docks you (14 §3). Everything the station loop
does with ore, components and credits gains its source here.

## 2. Decisions locked this session (owner rulings)

| # | Decision |
|---|----------|
| 1 | **Controls: hybrid.** WASD always available; clicking empty space sets a fly-to order that any manual input cancels. Mass-scaled inertia — "the heavier the ship the more noticeable". |
| 2 | **Weapons: families × cursor aim.** All guns fire toward the cursor; the lock only marks (HUD, rocket homing). Energy = instant, shields-first. Kinetics = travelling bolts, bypass shields. Rockets = homing, destructible, flight time. Mines = dropped. |
| 3 | **Exit: hardcore + safe warp.** While an enemy is engaged there is no escape button — fly to a station or gate. Safe warp only when no enemy is engaged: a few-second channel with an animation, landing docked at the current sector's station; no station in the sector → no warp. |
| 4 | **Sectors: same size, different identities.** One arena size for all; they differ by backdrop/palette, owning faction, resource tier mix (11 §1.1), enemy mix and density, hazards. |
| 5 | **NPCs: six archetypes** on one shared brain (pirate, patrol, trader/convoy, hunter wing, station turret, boss). |
| 6 | **Mining: laser primary, guns secondary.** Regular weapons can also break rocks, at 10 % efficiency vs the mining laser. |
| 7 | **Death: cargo drops.** Cargo spawns as pickups at the wreck with a 5-minute recovery window; hull/fit follow 14 §3 insurance. |

## 3. Flight

### 3.1 Control scheme (hybrid)

- **W/S** throttle (S = reverse thrust, which doubles as the active brake),
  **A/D** turn.
- **LMB on empty space** = fly-to order (autopilot). **LMB on a hostile hull**
  = lock it. **Q** (`target_next`) cycles locks. **ESC** cancels the order and
  the lock (this retires the current ESC-docks-anywhere placeholder).
- **Firing does not cancel** a fly-to order; any thrust/turn input does.
- **`interact` (F)** answers world prompts: dock at a station, confirm a gate
  jump.
- Camera: smooth follow + mouse-wheel zoom 0.70–1.50 (already shipped).

### 3.2 Inertia model (mass-scaled — the owner's core flight wish)

- **Linear inertia.** Velocity chases `throttle × max_speed` with the class's
  `accel_time`; with no input, speed decays over `coast_time` (heavy classes
  glide noticeably, light ones settle fast). S-thrust brakes at
  `BRAKE_MULT ×` the acceleration rate, so stopping hard costs attention.
- **Angular inertia.** Turn rate spins up over `turn_spinup` and damps down
  the same way — heavy hulls arc into turns and overshoot, light hulls snap.
- **The autopilot obeys the same physics.** Arrive steering: desired speed
  scales down with distance (slow-down radius), thrust and brake use the same
  accel/coast model. No teleporting, no second movement system.
- **Boosters** (B slot, 09 §3.5): afterburner via the existing `boost` action
  (+60 % speed 3 s, 8 s cooldown); fold blink (400 u, 20 s cooldown) with a
  charge FX.
- **Mass sources.** Hull class (handling table, §13) + armour plating, which
  multiplies handling times by `1 + |its speed penalty|` on top of its 09 §3.3
  speed cost (plating = slow *and* ponderous). Engines buy it back: `e_ion`
  ×1.15 speed, `e_vector` ×1.25 speed / ×1.20 turn.

### 3.3 Stats source

Flight reads **only** the `ShipStats` resolved by `ShipFit` (§9). No catalogue
reads, no formula soup in movement code.

## 4. Combat

### 4.1 Weapon families (amends 09 §3.1: it gains `family` + `shield rule`)

| Module | Family | Aim | Travel | Shield rule | Notes |
|--------|--------|-----|--------|-------------|-------|
| `w_laser` | energy | cursor | instant | shields first; no hull damage while shield > 0 | 30 DPS |
| `w_plasma` | energy | cursor | instant | shields first | 70 DPS; +25 % to hull once shields are down ("melts armour") |
| `w_cannon` | kinetic | cursor | bolt 1000 u/s | **bypasses shields** → hull | 45 DPS, burst cycle (0.35 s on / 0.25 s off) |
| `w_railgun` | kinetic | cursor | slug 1400 u/s | bypasses shields → hull | 60 DPS; 09's "ignores 50 % armour" line is **retired** (armour is hull points, there is nothing to ignore — see §12) |
| `w_rocket` | missile | lock + cursor launch | homing, 2.2 rad/s turn, 900 u/s | bypasses shields → hull | 180 alpha per rocket, 1.2 s interval; **destructible in flight** (any weapon hit kills it) |
| `w_mine` | deployable | drop | static | bypasses shields → hull | arms after 2 s; proximity trigger 60 u |
| `w_mining` | tool | cursor | beam | rocks only | see §6 |

- Energy shots resolve instantly at the cursor's ray point (circle hit test),
  capped at the weapon's range.
- Kinetics travel and fizzle at max range; leading the target is the skill.
- Rockets require a lock to home; without a lock they dumb-fire at the cursor.
- **Lock is marking only** — no damage bonus, no auto-aim. Lock range = the
  scanner's range (§9), which gives `c_scanner` a combat job.

### 4.2 Damage pipeline

1. `damage(amount, bypass_shield)` extends `PlayerState.damage` (§12
   amendment): if not bypass and `shield > 0`, the shield absorbs up to its
   current value with **no carry-over**; otherwise hull takes it.
2. Shield regen: base **2/s**, S modules add per 09 §3.2 (`s_light` +4,
   `s_heavy` +5, `s_ion` +9); regen resumes after **4 s** without incoming
   damage.
3. Hull ≤ 0 → death flow (§7).
4. Feedback: shield flare vs hull sparks distinguish the family that hit you;
   hit markers on the reticle; no floating numbers in v1.

### 4.3 Ammo

- Per-weapon packs stay profile-owned (`profile_changed &"ammo"`); `PlayerState`
  seeds at launch and **files the shot deltas back on dock** (same pattern as
  vitals, 01 §6). Railgun shares the cannon pack in v1 (09 §3.1 note).
- `weapon_1..5` selects a group; **Space** (`fire_primary`) fires it; `E`
  (`mine`) fires the mining laser whenever it is fitted, convenience only.
- Mining laser spends no ammo. Empty pack = dry-fire feedback, no shot.

## 5. NPCs — six archetypes, one brain

One `NpcBrain` state set for all hulls: **Idle → Patrol/Scan → Alert (LOS
check, rocks block) → Engage (hold preferred range, strafe) → Flee → Return/
Despawn**. Leash radius to the spawn POI; aggro clears when the player leaves
the radius for `AGGRO_COOLDOWN` (which enables the safe warp).

| Archetype | Faction | Behaviour | On death |
|-----------|---------|-----------|----------|
| Pirate | none | guards asteroid fields/wrecks; engages anything in radius; flees below 30 % hull | 06 tables; killing = −3 heat, +1 standing in the local faction's space (13 §4) |
| Patrol | sector owner | ignores Clean players; scans Suspect+ (20+) on sight; attacks Outlaws (80+) and defends faction ships | no loot; killing = +25 heat, witness rule (13 §2/§5) |
| Trader / convoy | none | flies fixed route; flees from Suspect+; convoy = 1 hauler + 1–2 fighter escorts | 06 freighter table + visible cargo pods; killing = +15 heat if witnessed |
| Hunter wing | faction | spawns on Wanted (50+) at the player's next sector entry; 2–3 hulls tuned to the player's fit value (13 §6); Outlaw = perma-tail, respawn 60 s | 06 band + `comp_elec`-weighted extras (13 §3) |
| Station turret | station owner | static, high damage; meanest at Choir stations; aggro on attack | +25 heat; turret aggro until scan range clears |
| Boss | arena | scripted, physical location, contract-gated (14 §5); P4/slice 4 | 14 §5 payouts |

- **Spawn model (v1):** the sector populates on entry from `sector_registry`
  densities; local respawn happens on the 20-minute clock. No off-screen
  simulation, no roaming drifter management.
- Traders flee on the `flee` state, pirates on the hull threshold — both make
  "letting a witness live" a real decision (13 §5).

## 6. Mining

- **Mining laser** (`w_mining`, W slot, 09 §4.5): cursor-aimed beam, range
  220 u. Each `MINE_CYCLE` (1.2 s) on a rock converts 1 ore unit → spawns a
  **floating pickup** of that rock's mineral (02 §7).
- **Guns on rocks:** any weapon applies work at **10 %** of its DPS-equivalent
  rate toward the same unit thresholds — legal, wasteful, sometimes faster on
  a rich rock; no heat, no standing effects (rocks are not ships).
- **Rocks are solid:** ships collide with them, they block shots and beams
  (cover, §5) and take chip work from any hit.
- **Asteroids:** mineral + yield roll per 02 §5; yield 0 → crack + despawn;
  field respawn 20 min + the ×0.7 diminishing window (02 §8).
- **Pickups:** tractor range/speed base values in §13; `u_salvage` doubles
  range and speed, `u_tractor` adds +1 pickup stream; uncollected pickups
  despawn after 60 s (02 §7).
- **Hold full:** further pickups drift, no auto-sell, no jettison (02 §7);
  HUD shows the full state.
- **Cargo identity:** per-mineral via `PlayerProfile.add_cargo` (02 §7.5).
  Loot from kills uses 06 tables; credit caches pay on pickup and log per
  01 §7.

## 7. Exit, death, travel

- **Docking:** fly into the station's dock zone → prompt `F` → loading
  screen → station (files the damage report, 01 §6; seeds vitals on next
  launch — unchanged).
- **Gates:** enter the ring → confirm prompt with the fee (11 §2.1) → 2 s
  charge FX → loading → destination gate.
- **Corridors:** hold course inside the marked zone for 15 s → transition
  (11 §2.2). Pirates ambush here more often (spawn bias).
- **Safe warp:** available only when **no hostile is engaged** — no hostile
  in Alert/Engage targeting the player **and** no damage taken in the last
  5 s. Channel `WARP_CHANNEL` = 3 s with a charge FX; breaks on damage or new
  aggro. Completion → docked at the current sector's station. No station in
  the sector → the action reports unavailable (S7 stays hardcore).
- **Death:** hull 0 → explosion → the wreck spawns with cargo pickups (5-min
  recovery window; see §2.7), then the 14 §3 flow: respawn docked at the last
  station visited, insurance decides what comes back, mercy clause once per
  profile, heat persists.

## 8. Sectors and spawns

- **One arena size** for all sectors (§13 `SECTOR_SIZE`), same layout budget:
  fields, wrecks, anomalies, beacons, gates, station(s) near centre. Sectors
  are differentiated by **backdrop/palette, owner, tier mix (11 §1.1),
  enemy mix/density, hazards** — never by size.
- **On entry, spawn:** 4–8 asteroid fields (6–12 rocks each), 1–3 wreck fields
  (3–6 hulks + 1 scannable derelict), 1–2 anomalies, nav beacons (1/corridor +
  1/gate), 1 primary station + 0–1 outpost, pirates per 13 §4 density,
  patrols in faction space, 1 convoy per inhabited sector, the sector's gates
  and corridors.
- **Respawn:** POIs and fields re-roll on the single 20-minute `WorldClock`
  (17 §4); derelicts and anomalies are one-shot per cycle (11 §3.1/§3.2).
- **Minimap:** blip classes grow to friendly (stations, gates, beacons) /
  neutral (derelicts, convoys, scanned anomalies) / hostile (pirates,
  hunters); soft fog per 11 §3.3 — nothing hidden that matters, unexplored
  sectors show only stations and gates.

## 9. Upgrades interface — `ShipFit` / `ShipStats`

- `game/ship_fit.gd` (`class_name ShipFit`, planned in 17 §2) lands **with
  slice 1 in reduced form**: `resolve(hull_id, fit) -> ShipStats` implementing
  the 09 §5 resolution order. v1 fit = the 09 §7 standard fit; P2 later adds
  the fitting UI and full catalogue — the interface does not change.
- `ShipStats` fields: `max_speed`, `accel_time`, `coast_time`, `turn_rate`,
  `turn_spinup`, `hull_max`, `shield_max`, `shield_regen`, `damage_mult`,
  `lock_range`, `scan_range`, `tractor_range`, `tractor_speed`,
  `tractor_streams`, `cargo_max`, `boosters` (ids).
- `game.gd`/`player_ship.gd` apply the snapshot at launch: `PlayerState`
  maxima come from it, so armour/engines/computers are felt from the first
  module swap — the whole point of the upgrade layer.

## 10. HUD / UX additions (amendments to IMPLEMENTATION_PLAN §3.10)

- `set_prompt(text)` — dock/gate/interact prompt strip.
- `set_warp_channel(progress)` — warp bar (empty hides).
- Blip kinds: add `&"friendly"`; POI subkinds as data on the blip dict.
- Target window: range state (in/out per selected weapon) added to the
  `set_target_info` payload.
- Reticle: cursor reticle with in-range/out-of-range/hostile states; small
  hit markers (no floating damage numbers in v1).

## 11. Input map amendments (IMPLEMENTATION_PLAN §3.7)

- Add: **`interact` = F** (dock/gate prompts), **`warp` = H** (safe warp).
- `ui_cancel` (ESC) leaves the input map as is but its in-game meaning
  changes to *cancel order + lock*; ESC docking is retired by decision #3.
- Everything else stays: thrust/turn/fire/boost/mine/cargo/weapon_1..5/Q.

## 12. Amendments to existing docs (docs-first, apply before code)

1. `08_ship_classes.md` §2: hull table gains a **handling column** (§13 table
   is the source; 08 references it).
2. `09_ship_slots_modules.md` §3.1: weapon table gains **family + shield
   rule** (per §4.1 here); the railgun's "ignores 50 % armour" is retired
   (§4.1 note).
3. `09_ship_slots_modules.md` §3.2: base shield regen 2/s named here so the
   no-module case works.
4. `IMPLEMENTATION_PLAN.md`: new §9.9 (engine wave) recording decisions 1–7,
   the §3.7/§3.9/§3.10 amendments above, and the retirement of the ESC-dock
   placeholder + `MOCK_*` constants.
5. `game/player_state.gd`: `damage(amount, bypass_shield := false)` per §4.2
   (HUD signals unchanged).
6. `11_galactic_map.md` §1: note the one-arena-size rule (decision #4); the
   per-sector tier table stays authoritative.

`TESTING_NOTES.md` batch-2 fixes are independent of all of the above and can
land before or in parallel.

## 13. Calibration table (initial values — playtest-tunable, single source)

**World**

| Value | Initial |
|-------|---------|
| `SECTOR_SIZE` | 10 000 × 10 000 u; station near centre; player spawns 300 u off the dock ring |
| Speed scale | `max_speed = hull % (08 §2) × 450 u/s` |
| Camera zoom | 0.70–1.50 (shipped) |
| Minimap radius | 800–6 400, step 800 (shipped) |
| Autopilot | slow-down radius 240 u, arrive radius 40 u |
| Pickup lifetime | 60 s; tractor 120 u range, 90 u/s pull |
| `MINE_CYCLE` | 1.2 s per ore unit; mining laser range 220 u; gun work rate 10 % |

**Handling per class** (08 classes; plating multiplies times by
`1 + |speed penalty|`; engines per §3.2)

| Class | Max speed (u/s) | Accel time (s) | Coast time (s) | Turn rate (rad/s) | Turn spin-up (s) |
|-------|------:|------:|------:|------:|------:|
| Fighter | 450 | 2.0 | 1.6 | 3.4 | 0.4 |
| Cutter | 428 | 2.4 | 2.0 | 3.0 | 0.5 |
| Miner | 338 | 4.0 | 3.4 | 2.0 | 1.0 |
| Trader | 383 | 3.0 | 2.6 | 2.4 | 0.7 |
| Corvette | 495 | 2.2 | 1.8 | 3.2 | 0.45 |
| Hauler | 293 | 6.0 | 5.2 | 1.5 | 1.4 |
| Gunship | 360 | 4.4 | 3.8 | 1.9 | 1.0 |
| Frigate | 383 | 4.0 | 3.4 | 2.1 | 0.9 |
| Destroyer | 315 | 6.4 | 5.6 | 1.6 | 1.2 |

`BRAKE_MULT` = 1.8 (S-thrust vs coast).

**Combat**

| Value | Initial |
|-------|---------|
| Weapon ranges (u) | laser 500 · plasma 450 · cannon 600 · railgun 800 · rocket 900 (lock range 900) |
| Rocket | 180 alpha, 1.2 s interval, 2.2 rad/s homing, 900 u/s, one hit kills it |
| Mine | arm 2 s, trigger 60 u |
| Shield regen | base 2/s + module values; resumes 4 s after last hit |
| Aggro radii | pirate 900 · patrol scan 1 000 · turret 750 · flee at 30 % hull · leash 2 500 |
| `AGGRO_COOLDOWN` | 5 s (aggro clears; warp becomes available) |
| `WARP_CHANNEL` | 3 s |

**NPC counts per sector** (13 §4 density shape): S1 0–1 · S2 1–2 · S3 2–3 ·
S4 3–4 · S5 3–5 · S6 4–6 · S7 6–8, patrols only in owned space, one convoy
per inhabited sector.

## 14. Build slices (each is a shippable coder wave)

**Slice 1 — Fly and mine.** Deliverable: fly a sector with rocks, mine, collect,
dock, warp; HUD/UX pass. New files (one owner each):
`game/ship_stats.gd`, `game/ship_fit.gd` (reduced form, 09 §7 fit),
`game/player_ship.gd` (hybrid input, inertia, autopilot, boosters; extracts
movement from `game.gd`), `game/asteroid.gd`, `game/asteroid_field.gd`,
`game/mining_laser.gd`, `game/pickup.gd`, `game/sector_registry.gd` (7 rows,
11 §1), `game/sector.gd` (spawn set on entry + clock respawns). `game.gd`
keeps routing/HUD wiring and delegates. Retires: `MOCK_*` constants, ESC
docking. HUD: reticle, prompt strip, warp bar, blip kinds.

**Slice 2 — Fight.** Deliverable: pirates/patrols/traders live, weapons fire,
damage, loot, death. New files: `game/weapons.gd` (families/firing/ammo),
`game/projectile.gd` (bolt/missile/mine), `game/damage.gd` (pipeline),
`game/npc_registry.gd`, `game/npc_ship.gd`, `game/npc_brain.gd`,
`game/loot_tables.gd` (06). PlayerState + HUD amendments per §12/§10.

**Slice 3 — Travel.** Deliverable: gates, corridors, POIs, scanner, sector
transitions via `loading`. New files: `game/gate.gd`, `game/corridor.gd`,
`game/poi.gd` (derelict/anomaly/beacon), scanner reveal logic in
`sector.gd`.

**Slice 4 — Integration.** Deliverable: hunters (13 §3 Wanted wings), bosses/
arena hooks (14 §5), full `ShipFit` consumption once P2's fitting UI lands,
affix effects (15) flowing into `ShipStats`.

Per-slice verification follows `IMPLEMENTATION_PLAN.md` §6 (headless editor
import, boot check, probe-script pattern), and the theme/asset rules of
AGENTS.md stay in force (editor writes refused while the game plays).

## 15. Test checklist (headless-assertable)

- **ShipFit:** the 09 §7 standard fit resolves to exactly the arithmetic
  implied by 08 §2 + 09 §3/§7 (hull, shield, speed, turn, regen); plating and
  engine multipliers apply in the 09 §5 order.
- **Flight:** autopilot arrives within `ARRIVE_RADIUS` and cancels on manual
  input; brake shortens stopping distance vs coast; per-class times reproduce
  §13 within tolerance.
- **Damage:** energy is fully absorbed by a live shield (no carry-over);
  kinetic damage ignores shields; regen delay is respected.
- **Mining:** N cycles on a rock spawn N ore pickups; gun work accumulates at
  10 %; cracks at yield 0; hold-full leaves pickups drifting.
- **NPC brain:** aggro → engage → flee transitions at the §13 thresholds;
  leash/despawn; LOS blocked by a rock fixture.
- **Warp:** blocked while engaged, breaks on damage mid-channel, lands docked;
  unavailable with no station in sector.
- **Loot:** expected values per 06 §6 (±5 %), credit caches log to
  `economy_log` (01 §7).
- **No mock residue:** `MOCK_*` constants gone; ESC no longer docks.

## 16. Open items

- Bosses/arena contracts (14 §5) and hunters are slice-4 hooks; their tuning
  waits for the P2 fit economy to exist.
- The railgun wording retirement (§4.1) and the new base shield-regen number
  (§4.2) are engine-spec additions — flag to the owner if either should be
  re-tuned instead.
- Crafting (07) untouched by the engine.
