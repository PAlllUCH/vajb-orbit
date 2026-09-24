# S6-K0_report — docs drift check (travel wave S6)

**Worker:** S6-K0 (`VAJB_WORKER_FILES="docs/,vajb-orbit/tests/,vajb-orbit/tools/"`)
**Wave:** S6 Travel (engine slice 3 + RPG P3), brief `.agents/gen/slices/S6-travel/S6_BRIEF.md`, pin `docs/CONTRACTS.md` §19.
**Date:** 2026-09-24. **Tree:** working tree with D6 in flight (`ui/hud/cockpit_cluster.gd`, `tests/test_d6_cluster.gd` modified — read as D6 churn, **not** reported as drift).
**Rule applied:** nothing edited, no number invented; every finding carries `file:line` and an escalation bucket (AGENTS.md escalation ladder: 1 = inside a pinned acceptance, implementer decides; 2 = would change a pin / a docs text / a `VAJB_WORKER_FILES` set / the tests-that-move list; 3 = taste or supersedes an existing owner ruling).

---

## 1. The three confirmations the prompt asked for

### 1.1 Station turret entity (13 §7 tick 7) — **no instantiated entity; the brief's grep claim is false as worded**

- Nothing spawns a turret. `NpcRegistry.spawns_for()` (`game/npc_registry.gd:615-626`) returns only rows whose `KEY_SPAWN` is `SPAWN_SECTOR`; the turret row is `SPAWN_STATION` (`game/npc_registry.gd:343`) and `SPAWN_STATION` has no consumer anywhere in `game/`, `ui/` or `tests/`. `sector.gd:_spawn_npcs` (`game/sector.gd:336-343`) therefore never builds one.
- **But a turret archetype does exist, with behaviour support:** `game/npc_registry.gd:315-348` (`KEY_ID: &"turret"`, `ship_turret_platform`, `KEY_STATIC: true`, `KEY_HOSTILITY: HOSTILITY_ON_ATTACK`, `KEY_HEAT_ON_KILL: 25`), and the brain/hull handle it (`game/npc_brain.gd:282` "a station turret has nowhere to patrol", `:336` "static: never thrusts and never turns", `game/npc_ship.gd:12`, `:134`, `:298`, `:454`).
- So "no station turret **entity**" is true only in the instantiated-node sense. The brief line 45 and the K0 prompt ("grep 2026-09-24") say no entity exists *in `game/`* — a grep of `game/` finds `turret` in `npc_registry.gd`, `npc_ship.gd` and `npc_brain.gd`. **The measured claim needs rewording** (bucket 2).
- The staging decision itself still holds: no entity is spawned, so the +25/aggro staging stands.
- **Additional seam gap:** 13 §7 tick 7's staged line says "the +25 lands on attacking a station". There is **no station damage sink** to attack: the station is a bare `Sprite2D` plus a `DockZone` `Area2D` (`game/sector.gd:404-424`), with no body, no hull, no `take_damage`. "Attacking a station" has no seam in the tree (bucket 2/3 — the staged half is not implementable as written).

### 1.2 The kill seam — **`game/projectile.gd:742 _shot_down` is NOT the kill seam**

- `projectile.gd:_shot_down` runs only when the resolver hit another *projectile* (`game/projectile.gd:730-731`, guard `_is_destructible_shot` at `:743`). It is "a weapon hit on a rocket" (`:740-741`): it calls the rocket's `fizzle()` and blasts it. No hull dies there.
- The real kill seam is `NpcShip.died` → `game.gd:_on_npc_died`:
  - `game/npc_ship.gd:29/39` ("the death flow beyond the signal — **loot roll**, heat, the wreck — is done in wiring"), `:374-384` (`_die()` → `died.emit(global_position, _archetype)`).
  - Bound in `game/game.gd:1603-1607` (`_on_npc_spawned` connects `died` to `_on_npc_died.bind(ship)`).
  - The handler already files heat and standing and one `KILL` log line: `game/game.gd:1618-1631`; `_apply_heat` `:1637-1641`; `_apply_standing` `:1644-1648`.
- **Consequence for §19's "kill path calls `LootTables.roll`":** the loot roll lands in `game.gd:_on_npc_died` (and/or the wreck site spawned from it), not in `projectile.gd`. `game.gd:1614-1616` already says exactly this ("the loot roll's payouts … are §7's and slice 4's", and the witness rule "does not ship"). K2's prompt tells it "the kill path in game.gd (K1's `_on_kill` seam)" — see 1.3. Bucket 2 (brief/prompt measured line).
- Side finding: `_on_npc_died` currently files heat **unconditionally** (`:1627-1628`); the pin's witness rule replaces that behaviour. No existing test exercises `_on_npc_died`/`_apply_heat` (grep of `tests/` finds only `heat_on_kill`/`heat_tier` assertions), so the witness gate itself does not move an existing count (bucket 1 to implement).

### 1.3 §19 seam hooks named in the brief/run-order — **`_on_kill`, `_transition`, `_poi_table` do not exist in §19 or anywhere**

- The brief's run order (lines 147-149) and K1's prompt say K1 "exposes the seams (`_on_kill`, `_transition`, `_poi_table` hooks named in §19)". Grep of `docs/` and `vajb-orbit/` finds **no** `_on_kill`, `_transition` or `_poi_table` (only unrelated `_last_reconnect_transition_log_msec` in `addons/`). §19 (`docs/CONTRACTS.md:1808-1876`) names no hook; it says only "the kill path calls `LootTables.roll`" and "sector transitions go through the `loading` screen route".
- The seams that actually exist: `game.gd:_on_npc_died` (`:1618`), `game.gd:on_route` (`:287-295`, already reads `PARAM_SECTOR`), `game.gd:_spawn_sector` (`:445-458`), `sector.gd:populate` (`:106-159`). Bucket 2 (the brief attributes names to §19 that are not there; K1/R1 would inherit them).

### 1.4 The transition surface the `loading` route expects — **exists and is param-forwarding; two constraints**

- Shape in use today: `route_requested.emit(&"loading", {destination: &"game"|&"station"})` — `game/game.gd:60-63`, `:614`, `:1783`; `ui/screens/station.gd:443`; `ui/screens/main_menu.gd:204`.
- `loading.gd` forwards **all** params and every route unchanged: `ui/screens/loading.gd:49-54` (`on_route` stores `_params`), `:17-18` (`DESTINATION_KEY`/`SECTOR_KEY`), `:64-68` (label reads `sector`), `:80-83` (`route_requested.emit(_destination, _params)`); `ui/paths.gd:9-19` (routes `loading`, `station`, `game`).
- `game.gd` already consumes it: `PARAM_SECTOR := &"sector"` (`game/game.gd:62`), `on_route` (`:287-295`) re-populates when the row id differs and sets `_sector_name` from the row. **So the expected gate/corridor call is `route_requested.emit(&"loading", {&"destination": &"game", &"sector": <id|name>})`** (`_row_for` accepts both, `game.gd:563-572`).
- **Constraint 1 — the route reloads the scene, so "persist" needs a filing call.** `Router.route()` always runs `get_tree().change_scene_to_packed(packed)` (`autoload/router.gd:97`), so a sector transition frees and rebuilds `game.tscn`. The new scene seeds hull/shield/fuel from the **filed** record only (`game.gd:_seed_vitals` `:1248-1262`), which is written on dock (`_file_damage_report` `:1269-1280`, called from `_request_dock` `:610-614`). A gate jump that does not file first silently resets hull/shield/fuel (and, via `_file_ammo_report`, the fired rounds) to the last docked state. AC4's "hold/hull/heat byte-equal across the crossing" is only achievable with a filing call on the transition path; §19 does not name one. Bucket 1 route, bucket 2 for AC4/pin wording.
- **Constraint 2 — `_update_dock_prompt` owns the prompt line every frame.** `game.gd:273` calls it each physics frame and it writes `DOCK_PROMPT` or `""` unconditionally (`game.gd:588-590`); `_push_prompt` dedupes only by value (`:698-703`). §19's rule that the gate prompt / scan readout / cache feed "ride the frozen `set_prompt` seam" (§7, `docs/CONTRACTS.md:389`) is therefore not implementable without routing all four claimants through one priority owner in `game.gd`. Bucket 1 (route), but the pin's blanket claim is currently false.

---

## 2. Findings — pin vs the tree

Buckets per the escalation ladder. `[B2]` = escalate to the developer/designer session; `[B3]` = owner via designer; `[B1]` = implementer decides.

### F1 `[B2]` — the fee worked row `562` contradicts the pin's own formula (the correct value is `750`)

- Pin formula: `floor((150 + 100·d) × want × lawless)`, `want 1.5` at Wanted only, `lawless 2.0` into sector 7 (`docs/CONTRACTS.md:1828-1829`; `docs/gameplay/11_galactic_map.md:161-166`).
- Brief line 111-112 and **K1's prompt** (`S6_prompts.md:35`) hand the worker: "adjacent 250, two away 350, adjacent-to-7 at Wanted **562** (floor of 250×1.5×2)". `250 × 1.5 × 2 = 750`. `562 = floor(250 × 2.25)`, which is exactly §19/11 §5's **reversal** value ("additive stacking, base × 2.25 max", `11_galactic_map.md:166`).
- K1 and R1 are both told to reproduce/verify 562 (`S6_prompts.md:35`, `:53`); AC1 only requires 250/350 (`SLICE.md` AC1). The additive row is quoted as the multiplicative build. Bucket 2 — it is a balance number in the brief/prompts, and only the developer may restate the pin.

### F2 `[B2]` — `game/loot_tables.gd` is not a new file, and the pinned `roll(band)` signature contradicts the shipped one

- §19 (`CONTRACTS.md:1848-1852`) says "new file … `roll(band: StringName) -> Array[Dictionary]`". The file exists: `game/loot_tables.gd` (211 lines, `class_name LootTables extends RefCounted`, `:1`), shipped by slice 2 with `static TABLES` (`:96-102`) and `static func roll(kind: StringName, tier: int, random_seed: int = 0)` (`:124`).
- The 3-arg form is pinned by tests: `tests/test_engine2_loot.gd:133,222-223,323,435-438` call `roll(kind, tier, seed)`; `tests/test_engine2_npc.gd:20` preloads it. A literal 1-arg `roll(band)` breaks them — which the brief's "tests that move: None of the existing counts move" (`S6_BRIEF.md:161-167`) does not admit.
- Also note `TABLES` already carries a fifth kind, `&"swarmer"` (`:98`; pinned by `tests/test_engine2_loot.gd:216-224`), not only "fighter/freighter/corvette/Maw". Bucket 2 (pin wording + tests-that-move list).

### F3 `[B2]` — "one pickup per unit" (06 §8) breaks two shipped `test_engine2_loot.gd` assertions

- Pin: "one pickup per unit (06 §8's made choice); caches last, one distinct pickup" (`CONTRACTS.md:1851-1852`, `06_loot_drops.md:161-163`); K2's prompt repeats it (`S6_prompts.md:41`).
- Shipped implementation is the opposite choice: one payload entry per **line/stack**, amount = `randi_range(min,max)` (`game/loot_tables.gd:40-46`, `:138-148`).
- Two existing assertions depend on that shape and would fail under per-unit:
  1. `tests/test_engine2_loot.gd:249-272` asserts `payload.size()` (summed as `lines_paid`, `:138`) ≈ the table's chance-column sum within 0.05 (`:267`). Per-unit makes `payload.size()` a unit count, not a line count.
  2. `tests/test_engine2_loot.gd:368-389` asserts every entry's `amount ∈ [min,max]` (`:385-389`). A per-unit entry carries amount 1, which is below `min` for e.g. freighter `comp_scrap_1` 2-3 (`06_loot_drops.md:73`).
- Expected-value sums stay equal (units add the same), so `:289-305` survives; the two above do not. Bucket 2 — the brief's tests-that-move list is wrong, and the fixer/reviewer baseline depends on it.

### F4 `[B2]` — `ShipStats.BASE_SCAN_RANGE` is the wrong owner: the constant lives on `ShipFit`

- §19 (`CONTRACTS.md:1865-1866`), 13 §7 (`13_heat_bounty.md:105-107`) and K3's prompt all cite `ShipStats.BASE_SCAN_RANGE`. The tree has `const BASE_SCAN_RANGE := 900.0` in `game/ship_fit.gd:40` (and `stats.scan_range = BASE_SCAN_RANGE` at `:597`); `game/ship_stats.gd:35` holds only the per-instance `var scan_range`. The brief's own measured line 38 gets it right (`ship_fit.gd:40`). Bucket 2.

### F5 `[B2]` — the decay clock the pin depends on does not exist

- Pin: "Decay (§2): −1/minute of **play time**, accrued on the existing play clock (no new Timer — 17 §4's one-timer rule)" (`13_heat_bounty.md:109-110`; `CONTRACTS.md` says nothing about a clock). 
- The only clock is `autoload/world_clock.gd`, whose `now()` is **wall-clock Unix seconds** and whose band is 1200 s (`:18`), with a single `bands_between` helper (`:33-39`); there is no minute-grain API and no play-time accumulator anywhere (`grep` of `player_profile.gd`/`player_state.gd` for playty/minutes/elapsed finds nothing). 17 §4 also lists the clock's consumers as station systems only (`17_coder_handoff.md:128-134`).
- So "the existing play clock" names nothing; K3 must either add a play-time accumulator (a seam the pin does not define) or restate the pin. Bucket 2/3 (a missing number + a clock the docs claim exists).

### F6 `[B2, flag B3]` — "Outlaw" is two different rules: heat tier (13 §3) vs standing band (12 §4.1)

- 13 §3's row: `Outlaw | 80–100 | … denied docking (12 §4.1); gates refuse you (11 §2.3)` (`13_heat_bounty.md:46`). 13 §7 says "dock refusal (Outlaw, 12 §4.1's rule)" and "Outlaws never see it (they cannot dock)" (`:126`, `:116`), and §19 rules "Outlaw dock/gate refusals charge nothing" (`CONTRACTS.md:1874-1875`).
- 12 §4.1's Outlaw is a **standing** band: `−100…−51 | Outlaw | denied docking in faction space` (`docs/gameplay/12_factions.md:70`) — a different axis from heat 80–100.
- Consequence: K3 cannot tell whether the dock refusal reads `PlayerProfile.heat()[faction]` or `PlayerProfile.standing()[faction]`. Also, `12_factions.md` is in **no** worker's read list (brief lines 3-11; K3's prompt), so the delegated rule is unreachable by the implementer. Bucket 2; the flag is B3 because it decides which owner ruling governs docking.

### F7 `[B2]` — the hunter row is parked on slice 4 and has no aggro radius; this wave must flip it

- The archetype row: `game/npc_registry.gd:349-380` — `KEY_SPAWN: SPAWN_SEAM`, `KEY_SEAM: SEAM_SLICE_4` (`:371-372`), `KEY_AGGRO_RADIUS: 0.0` (`:360`) with the comment "slice 4 sets one with the wing's tuning" (`:358-359`), `KEY_MEMBERS: [ship_fighter ×2–3]` (`:377-379`).
- The brief resolves the *slice* contradiction docs-first (engine §14 slice 4 → this wave, `S6_BRIEF.md:23-26`, `CONTRACTS.md:1811-1813`), but the tree row still says slice 4, and **no doc supplies a hunter aggro/scan radius** (13 §7:117-125 gives only size, respawn, hull map, fit).
- Constraint: `KEY_TIER` is bound to the 06 table band by `tests/test_engine2_npc.gd:142-158`, so the tick-6 hull map (`13_heat_bounty.md:117-125`) must be encoded in `KEY_MEMBERS`, not by changing `KEY_TIER`. And the map's gunship branch (`ship_gunship`) is a hull the registry must name.
- Missing number ⇒ Bucket 2 (report, never invent).

### F8 `[B2]` — `sibelon` is a pre-existing "slice 3 anomaly entity" the pin drops

- `game/npc_registry.gd:408-434`: `sibelon`, comment "Ruling 24: the `sibelon` (anomaly entity, slice 3)", `KEY_SEAM: SEAM_SLICE_3` (`:430`); engine spec §5 repeats it (`18_engine_spec.md:263`).
- §19's POI set is `ore_bloom` / `grave_cache` / `void_rift` only (`CONTRACTS.md:1843-1846`, `11_galactic_map.md:117-127`); `sibelon` is mentioned nowhere in the pin, the brief or the K2 prompt. Either the pin supersedes ruling 24 (and should say so) or slice 3 owed a `sibelon` entity. Bucket 2/3.

### F9 `[B2]` — `game/heat.gd` is in K3's worker file set but in no pin and has no interface

- `S6_BRIEF.md:141` and `S6_prompts.md:47` give K3 `vajb-orbit/game/heat.gd`; the file does not exist and **§19 never mentions it** (heat logic is pinned onto `PlayerProfile.pay_bounty` at `CONTRACTS.md:1859-1861` and the existing `heat_tier`/`heat_on_kill`/`heat()` plumbing). 17 §2's file map does not list it either (`17_coder_handoff.md:24-41`).
- K3's prompt describes no contents for it, so its API/ownership is undefined — the implementer would invent an interface. Bucket 2 (the `VAJB_WORKER_FILES` set / a missing pin).

### F10 `[B2]` — the bounty surface lives in a file no worker owns

- 13 §7 tick 5 pins the surface as "a `PAY BOUNTY (n CR)` row in LAUNCH beside the REFUEL/RECHARGE rows" (`13_heat_bounty.md:113-116`). That surface is `ui/station/launch_panel.gd` (service buttons at `:325-326`, `_run_service` at `:368-376`) plus a `StationCatalog.SERVICES` row (`game/station_catalog.gd:197-211`, whose rows carry no `price` field per `CONTRACTS.md:466-468`).
- Neither file is in any S6 worker's set (K1/K2/K3/F1 all list `game/**`, `player_profile.gd`, `tests/`; only `ui/hud/**` is frozen by the hard rules, `S6_BRIEF.md:179-181`). If the surface is required, the file set is short; if it is deferred, the pin/AC6 should say so. Bucket 2.

### F11 `[B2]` — `poi.scan(player) -> int` return codes are undefined (and the data-core credit amount is unpinned)

- `CONTRACTS.md:1840-1842` pins `scan(player) -> int` with no meaning for the `int` (contrast `jump`'s documented `0/-1/-2` at `:1830-1831`); `hold_progress()` and `trigger()` are defined. A worker must guess the codes. Bucket 2 (route-adjacent, but the pin's silence is the issue).
- Derelict roll is "0.35 data core (03 `comp_elec` + **credits**)" (`CONTRACTS.md:1841-1842`, `11_galactic_map.md:112-113`) — the credit amount appears in no doc. Bucket 2/3 (a number the wave may not invent).

### F12 `[B2]` — 06 §4's wreck-site "distinct blip" has no kind in the frozen §7 set

- `06_loot_drops.md:112-113`: the wreck site is "visible on the minimap as a **distinct** blip". §7's frozen kind set is `hostile` / `neutral` / `friendly` (+ `self`, `swarmer`, `ghost`) (`CONTRACTS.md:376-379`, `:430-441`), and this wave may not write `ui/hud/**` (`S6_BRIEF.md:105-109`). §19's mapping (`11_galactic_map.md:183-187`) does not list wreck sites at all.
- The wreck site can only be an existing kind (at best `neutral`, indistinguishable from a derelict) or rider on D6. Bucket 2 (pin/docs) with a B1 route note.

### F13 `[B2]` — the heat bound 0–100 is unimplemented and the pin does not mention it

- 13 §2: "One heat value per faction: **0–100**" (`13_heat_bounty.md:19`). `game.gd:_apply_heat` adds without any ceiling (`:1637-1641`), and `NpcRegistry.heat_tier` has no upper clamp (`:561-566`). This wave rewrites the gain path (witness gating) and its test suite is told to prove exact values (`SLICE.md` AC5) — the bound question becomes live but neither §19 nor the brief states it. Bucket 2.

### F14 `[B2]` — 18_engine_spec §4.5/§15 put armour quadrants in slice 3; the brief defers them to slice 4

- Owner-locked spec: "Directional armor & malfunctions (**ruling 23 — slice 3 scope**) … slice 3 turns it on" (`18_engine_spec.md:216-226`) and the test checklist "the `ctx` parameter is accepted everywhere and no-op **until slice 3 turns quadrants on**" (`:611`).
- The brief says the opposite: "`test_engine2_pools.gd:254`'s 'context recorded for slice 3' row holds (the `ctx` routing turns on with quadrants in **slice 4**, not here)" (`S6_BRIEF.md:166-167`). §19 records a supersession for **hunters** only (`CONTRACTS.md:1811-1813`), never for quadrants.
- Either slice 3 is now re-scoped (the pin must record it) or this wave owes §4.5. Bucket 2 (a pin; the file is owner-locked so no worker may edit it) — flagged B3 since it touches a standing owner ruling.

### F15 `[B2]` — `SECTOR_NAME := "Helios Drift"` is a stale label the transitions expose

- `game/game.gd:89` hardcodes "Helios Drift" (comment: interim until the 11 §1 roster is wired). The registry's sector 1 is **Halcyon Reach** (`game/sector_registry.gd:60-61`; `11_galactic_map.md:19`). `_spawn_sector` sets the row id but not `_sector_name` (`game.gd:453`), and `on_route` only sets the name when a `sector` param arrives (`:294-295`), so a normal launch from the station keeps the stale label (`_sector_name` initialised at `:188`, pushed at `:560`/`:714-717`). Sector transitions now make the name load-bearing. Bucket 2 (docs/tree label).

### F16 `[B2]` — duplicate changelog version `v0.11`

- `docs/CONTRACTS.md:2464` ("the travel wave S6 — landed docs-first") and `:2473` ("the S5 playtest-fix review — S5-R1") both claim **v0.11** for 2026-09-24. Review waves own CONTRACTS; the S6 entry needs renumbering before R1's §10 pass. Bucket 2.

### F17 `[B2]` — 17 §2's file map is stale against the tree (independent of §19)

- 17 §2 names three files that do not exist: `game/faction_registry.gd`, `game/contract_registry.gd`, `game/shipyard.gd` (`17_coder_handoff.md:31-35`; `ls game/` has `auction.gd`/`exchange.gd`/`refinery.gd` but no shipyard/faction/contract registry). It also describes `game/sector_registry.gd` as owning "neighbours, gates" (`:31`) that the tree does not carry yet (`game/sector_registry.gd:9-12` says they are deliberately absent).
- But §19's own names resolve: `sector_registry.gd`, `loot_tables.gd`, `player_profile.gd`, `game.gd`, `sector.gd` all exist; `gate.gd`/`corridor.gd`/`poi.gd` are engine §14's names (`18_engine_spec.md:588-591`) and are correctly absent. The map simply does not list this wave's three new files, nor `heat.gd`. Bucket 2 (docs).

### F18 `[B2]` — 17 §2's world_clock "5 consumers" count is at risk if decay rides it

- `17_coder_handoff.md:36` fixes the consumer count at five ("05 bands, 10 rotation, 14 contracts/arena, 11 respawn"), and `:128-134`'s one-timer rule is scoped to station systems. If K3 implements decay on `WorldClock` (F5), the count and the rule's scope both move. Bucket 2.

### F19 `[B1, note]` — pickups are parented to the game scene, not the Sector, so "pickups reset" is a scene-reload side effect

- §19/11 §2.3 say a transition resets "fields/pickups" (`CONTRACTS.md:1866-1867`, `11_galactic_map.md:86-87`; AC4).
- Fields are the Sector's children and are cleared by `Sector.populate`/`_clear` (`game/sector.gd:106-107`, `:430-440`). Pickups are **not**: mining pickups are added to the shaft's parent (`game/mining_laser.gd:227`), death drops to the game scene (`game/game.gd:1759-1764`), and the wreck-site pickups K2 adds will be parented similarly. They are only cleared because `Router.route` reloads the whole scene (`autoload/router.gd:97`).
- This makes AC4's "pickups reset" pass by accident on the reload path but says nothing about an in-scene transition, and it interacts with F11/1.4-constraint-2. Bucket 1 (route) with the pin's phrasing noted.

### F20 `[B2, note]` — 06 §4's `WRECK_PICKUP_LIFETIME 90 s` vs `Pickup.LIFETIME 60 s`

- `06_loot_drops.md:113-114`; `game/pickup.gd:31` (`LIFETIME := 60.0`), pinned by `CONTRACTS.md:346-352` and consumed at `CONTRACTS.md:721`. §19 names `WRECK_PICKUP_LIFETIME` as a constant with no home (`CONTRACTS.md:1864`), and `game/pickup.gd` is in no worker's set.
- It **is** implementable without touching `pickup.gd`, via the existing age-bias precedent: `game.gd:1764` (`pickup.set(&"_age", PickupScript.LIFETIME - DROP_WINDOW)`). So this is a note, not a blocker — but the constant's home and the 90 s vs 60 s relationship should be stated. Bucket 2.

### F21 `[B2, note]` — engine §14 slice 4's "hunters" note is superseded by the pin; §14's slice-3 line omits loot and heat

- `18_engine_spec.md:588-591` (slice 3 = gates/corridors/POIs/scanner/transitions) vs `:593` (slice 4 = "hunters (13 §3 Wanted wings)"). §19 records the hunter supersession (`CONTRACTS.md:1811-1813`) but not that loot (06) and heat enforcement (13) are additions to §14's slice-3 deliverable line. Owner-locked file, so this is a note for the owner-gated spec pass (B2).

---

## 3. §19 names vs 17 §2's file map (the explicit check)

| §19 name | 17 §2? | Tree | Verdict |
|---|---|---|---|
| `game/sector_registry.gd` | yes (`:31`) | exists, rows lack `neighbours`/`gate_links`/`corridors` (`game/sector_registry.gd:58-115`) | additive, OK |
| `game/gate.gd` | **no** | absent | engine §14's name (`18_engine_spec.md:589`); not in 17 §2 |
| `game/corridor.gd` | **no** | absent | same |
| `game/poi.gd` | **no** | absent | same |
| `game/loot_tables.gd` | yes (`:34`) | **exists** (slice 2) | F2: pin calls it new; `roll` signature differs |
| `game/sector.gd` | **no** | exists | 17 §2 never listed the sector/scene scripts |
| `autoload/player_profile.gd` | no (implied §3) | exists | OK |
| `game/game.gd` | **no** | exists | 17 §2 never listed the scene scripts |
| `game/heat.gd` (worker set only) | **no** | absent | F9: no pin, no interface |
| `NpcShip.heat_on_kill()` | n/a | `game/npc_ship.gd:832` | OK |
| `NpcRegistry.heat_tier()` | n/a | `game/npc_registry.gd:561` | OK |
| `PlayerProfile.heat()/set_heat()` | n/a | `autoload/player_profile.gd:1563-1572` | OK |
| `PlayerProfile.add_credits()` | n/a | `autoload/player_profile.gd:263` | OK |
| `ShipStats.BASE_SCAN_RANGE` | n/a | `ShipFit.BASE_SCAN_RANGE` `game/ship_fit.gd:40` | F4 |
| `game/projectile.gd:_shot_down` | n/a | exists, wrong seam | F(1.2) |
| `WRECK_PICKUP_LIFETIME` | n/a | absent | F20 (home unnamed) |
| `WITNESS_RANGE` | n/a | absent | new const, home unnamed (beside F7) |

---

## 4. What is *not* drift (checked so the wave does not re-argue it)

- `test_engine2_npc.gd:185-196` (heat tiers at 20/50/80), `:389,393` (heat_on_kill −3/+15) hold; the pin keeps `heat_tier`/`heat_on_kill` as-is.
- `test_p1_profile.gd:109,144,194-210` (heat key round-trip) hold.
- `test_engine2_pools.gd:249-259` (the `ctx` row) holds as coded — see F14 for the doc side.
- 01 §5.2's travel row **is** amended 0–250 → 0–500 (`01_economy_core.md:108`); the brief's "already landed" claim holds.
- CONTRACTS §19's derived constants match their sources: `CORRIDOR_DEPTH 600.0`/reversal 400 (`11_galactic_map.md:167-169`), `DERELICT_SCAN_RANGE 300.0`/`void_rift drain 12.0` (`:174-182`), `GATE_FEE_BASE 150`/`GATE_FEE_PER_SECTOR 100` (`:65-66`), `ANOMALY_WEIGHTS_RIFT_DOUBLED [sector_6]` (`:125-126`), `WITNESS_RANGE` = 900 from `ShipFit.BASE_SCAN_RANGE` (`13_heat_bounty.md:105-107`, `game/ship_fit.gd:40`).
- Trader flee at Suspect+ and patrol scan-on-sight already exist as row data + brain states (`game/npc_registry.gd:267-268`, `:293`; `game/npc_brain.gd:410-417`, `:480-483`) — no new seam needed there.
- D6's in-flight files (`ui/hud/cockpit_cluster.gd`, `tests/test_d6_cluster.gd`) are parallel work, not S6 drift.

## 5. Out of scope / LOW observations

- **L-a** `11_galactic_map.md:34-40` (ruling 25) and `18_engine_spec.md:337` put 0–2 nebula gas clouds per sector "as a registry row", and this is the wave that extends the sector registry — but §19 adds no nebula row and no doc assigns nebulae to a slice. Flagging only; not a §19 contradiction.
- **L-b** `autoload/player_profile.gd:76` is `SAVE_VERSION := 7`, while `17_coder_handoff.md:100-106` still writes the migration list as v5→v6 with a parenthetical note; S6 adds no persisted key, so this does not touch the wave.
- **L-c** `11_galactic_map.md:61-64` ("every inhabited sector has a gate structure … arrive at the destination sector's gate") vs sector 7 having no station and no gate row, and `_seat_ship` placing the player on the sector spawn point (`game/sector.gd:151`, `game/game.gd:555-560`). No doc gives an arrival-point rule for a gate-to-sector-7 jump; the current route seats at the spawn point. Bucket 1 route, worth a brief line.

---

## 6. Verification log (how each claim was checked)

- `grep -rn "turret|Turret" vajb-orbit/{game,autoload,ui}`; `grep -n "SPAWN_STATION|SPAWN_SEAM" game/ tests/`; `grep -rn "spawns_for" game/` → turret row never spawned.
- `sed -n '700,790p' game/projectile.gd`; `sed -n '360,405p' game/npc_ship.gd`; `grep -n "died|_on_npc_died" game/` → kill seam.
- `grep -rn "_on_kill|_transition|_poi_table" docs vajb-orbit` → no such hooks.
- `sed -n '60,110p' autoload/router.gd`; `cat ui/screens/loading.gd`; `grep -n "PARAM_SECTOR|on_route" game/game.gd`; `sed -n '9,20p' ui/paths.gd` → transition surface.
- `sed -n '40,150p' game/loot_tables.gd`; `grep -n "func test_|lines_paid|amount inside" tests/test_engine2_loot.gd` → F2/F3.
- `grep -rn "BASE_SCAN_RANGE" game/`; `grep -rn "play_time|minute|elapsed" autoload game`; `cat autoload/world_clock.gd` → F4/F5.
- `sed -n '17,132p' docs/gameplay/13_heat_bounty.md`; `grep -n "Outlaw | denied docking" docs/gameplay/12_factions.md` → F6.
- `sed -n '315,380p' game/npc_registry.gd`; `sed -n '408,434p' game/npc_registry.gd`; `sed -n '142,158p' tests/test_engine2_npc.gd` → F7/F8.
- `sed -n '588,595p' docs/gameplay/18_engine_spec.md`; `sed -n '216,226p' docs/gameplay/18_engine_spec.md`; `sed -n '605,612p' docs/gameplay/18_engine_spec.md` → F14.
- `cat .agents/gen/slices/S6-travel/{SLICE.md,S6_prompts.md,S6_BRIEF.md}`; `grep -n "v0.11|S6" docs/CONTRACTS.md` → F1/F9/F10/F16.

**Suggested owner/developer actions before the first dispatch:** restate the fee worked row and K1/R1 prompt (F1); correct the seam names and the measured lines (1.2/1.3); rule on `roll()`'s signature + the per-unit shape and move the affected test rows onto the tests-that-move list (F2/F3); pin the decay clock and the hunter radius and the dock-refusal axis (F5/F6/F7); add or drop `heat.gd` and name the bounty surface's owner (F9/F10); renumber the changelog entry (F16).
