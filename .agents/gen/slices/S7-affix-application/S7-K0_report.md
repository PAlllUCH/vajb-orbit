---
slice: S7
worker: S7-K0
model: opencode-go/deepseek-v4.1-flash
status: actionable
gate: not run (report-only pass; the WAVEBOARD's mid-C-wave reading is 668/6, all six in D7's held files — D7 is still moving, so the close-out must re-read the settled tree's count)
---

# S7-K0 report — docs drift and seam re-measurement

## Result

Every seam §20 names was re-measured against the tree at `HEAD` (+ D7's uncommitted
`ui/hud/hud.gd`, `docs/design/UI_SPEC.md`, D7's own brief/prompts — attributed, not
drift). The stored-affix convention, the `set_weapons` walk, the sell formula's real
call sites, the kill seam and the Embers predicate all hold as §20 reads them, with
three exceptions that must be dispositioned **before K1 runs**: (a) §20's
`{prefix_id: summed_magnitude}` summary shape cannot express the per-instance rule the
same section states, (b) the player's projectile damage lands in
`game/projectile.gd`, a file in no S7 worker set, and (c) the Ledger term as pinned
lands on a delegate that pays nobody, while the one existing test assertion it flips is
in `test_s3_instances.gd`. No file was written except this report; no probe, gate or
Godot run was made, so the live store was not touched.

## 1. The stored prefix sign/unit convention (ask 1) — holds

- `game/module_catalog.gd:127-211` — `PREFIXES` is the twelve-row table `{name, slot,
  stat, unit, band}`; every band is a **fraction**: `sturdy` `[0.10, 0.15, 0.20]`,
  `vigilant` `[0.15, 0.25, 0.35]`, `keen`/`rapid` `[0.08, 0.12, 0.16]`,
  `tempered` `[0.05, 0.08, 0.12]`, `wideband` `[0.15, 0.20, 0.25]`,
  `surefire` `[0.05, 0.08, 0.10]`.
- The three negative bands: `frugal` `[-0.15, -0.20, -0.25]` (`:161`), `lightened`
  `[-0.04, -0.06, -0.08]` (`:168`), `spry` `[-0.15, -0.20, -0.25]` (`:203`).
  `lightened`'s `unit` reads `"points"` while its value is the same fraction space as
  the armour row's own effect (`h_plate_light` `speed_penalty: -0.05`,
  `module_catalog.gd:373`) — the unit word is display, the arithmetic is fractional.
- `deep_hold` `[5.0, 8.0, 12.0]` and `overflowing` `[1.0, 1.0, 2.0]` are units
  (`:182, :210`).
- `prefix_value(prefix_id, tier)` (`:725-733`) reads the band column at the module's
  own tier and `roll_prefixes` (`:743-753`) stores `{"id": <String>, "value": <float>}`
  **verbatim**; `Auction.rolled_name:648-650` and the record path read the same ids.
- `autoload/player_profile.gd:2164-2211` — `_instance_record` keeps the six keys;
  `_affix_rows` (`:2181-2195`) keeps `value` as a float (a bare id becomes `0.0`) and
  `_affix_names` (`:2199-2211`) keeps one String per suffix id. Values are stored, never
  derived: `add_instance:605-613` writes what it is handed, `roll_instance:653-660`
  writes `roll_affixes`' output.
- Two notes for K1 (bucket 1, no pin change):
  1. A stored `0.0` (a bare-id entry — `tests/test_s3_instances.gd:96,123,527` fits
     `[{"id": "sturdy", "value": 0.15}]` and bare `["wideband"]` alike) must stay
     inert; the summary must not re-consult `prefix_value`, which is §20's own
     "never re-derived".
  2. The tree carries two contradicting statements about `String`/`StringName`
     dictionary keys — `player_profile.gd:866-868` says they are interchangeable, while
     `game/ship_fit.gd:_list_slot:1049-1059` reads both spellings. Records store
     **String** ids and `PREFIXES`/`SUFFIXES` are **StringName**-keyed, so K1 should take
     the shipped precedent and convert explicitly (`Auction.rolled_name:648-650`).
     `game/player_profile.gd:866-868` is the claim's home, so the file docs disagree.
     (K0 ran no Godot probe — report-only scope; K1's own suite can settle it in one
     assertion.)

## 2. Every player damage path to a sink (ask 2), and which need the product

| # | path | file:line | reaches `_deliver`? | needs `× damage_mult`? |
|---|---|---|---|---|
| 1 | beam frame (instant families) | `weapons.gd:_apply_beam:1219` → `_deliver:1258` → `weapons.gd:_deliver:1774` (its **only** caller) | yes | **yes** (§20 names it) |
| 2 | all projectiles — bolt, slug, rocket, mine | `weapons.gd:_spawn_shot:1177-1202` (damage at `:1190`) → `projectile.gd:_hit_body:773-791` (`_deliver:785`) and `projectile.gd:_detonate:838-849` (`_deliver:843`) → `projectile.gd:_deliver:885-903` | **no — second, independent delivery** | **yes, and it is in no worker set** → finding F2 |
| 3 | beam vs rock (chip) | `weapons.gd:1231-1241` `apply_work(amount * GUN_CHIP_RATE)`, before `_deliver` | no | yes, under the owner's "rocks included" tick |
| 4 | projectile vs rock (chip) | `projectile.gd:_hit_rock:756-758` `apply_work(damage * chip)` | no | yes, same reading |
| 5 | ram (body-body contact) | `player_ship.gd:_on_hull_body_entered:915-930` (`DAMAGE.ram` `:924` → peer's `apply_collision_damage:930`; `NpcShip.apply_collision_damage:343`, `Asteroid.apply_collision_damage:261`) | **no** | **undecided — no pin text names it** → finding F12b |
| 6 | mining laser | `mining_laser.gd:_apply_cycle:195-201` `apply_work(WORK_PER_UNIT)` (`Asteroid.WORK_PER_UNIT:56` = 1.0), one per `MINE_CYCLE` (`:34`) | no | **no** — this path carries no damage amount at all, so the tick's "mining TTK moves" can only mean paths 3/4 |

Notes: `w_mining` has no `FAMILIES` row (`weapons.gd:90-167`), so path 6 has no dps and
no barrel. `Damage.detonate` (`game/damage.gd`) has no production caller (tests only).
NPCs never spawn projectiles (`npc_ship.gd:894` "the fire flag has no consumer"), so
path 2 is player-origin in production today, but the class carries a `source`
(`projectile.gd:454,571`) and fixtures build shots with none.

## 3. Tests-that-move list (ask 3)

**No test fits a computer and asserts a delivered amount or a resolved stat.**
Measured: `tests/test_ship_grids.gd` is the only gate suite whose `resolve` fixtures
mention a computer, and only in `fitted_ids`-order (`:400-414`) and duplicate-refusal
(`:523-529`) rows. Every standard fit carries no computer (`ship_fit.gd:516-559` →
`damage_mult == 1.0`, set at `:596`), and the gate's scratch store has no instances at
all (`headless_runner.gd:_seed_scratch_store:54-65` → `reset_to_defaults` →
`_apply_defaults:1850-1872` clears `_modules`, `_fits`, `_auction`).

**Condition A (the flip list is empty only with this guard):** `_stats` must be read
null-tolerantly. Eight gate suites hand `Weapons.setup` a **null** stats argument or
never call it, then reach `_deliver`/`_apply_beam`:
`test_engine2_weapons.gd:84`, `test_flight_beam_g2.gd:371`, `test_s2_6_beam.gd:419`,
`test_weapon_fx_f1.gd:546`, `test_weapon_fx_f4.gd:354`, `test_s5_batteries_v2.gd:587`,
`test_s5_hardpoints.gd:223`, `test_combat_repair_c5.gd:356` (`_guns()` never sets up).
The shipped convention is the guard: `weapons.gd:1665,1677`. An unguarded read crashes
those suites (a failure, not a flip). `projectile.gd` fixtures likewise carry no
`source` (`test_engine2_fixes.gd:363-370`, `test_weapon_fx_f2.gd:456-464`).

**The exact-amount assertions that would flip if the guard or the "no computer" premise
broke** (all measured, all green today):

| assertion | seam | why it is safe |
|---|---|---|
| `test_engine2_fixes.gd:305-316` (120.0), `:319-330` (120.0), `:436-441` (50.0) | `weapons.gd:_deliver` | fixture stats = `STANDARD_FIT` → `damage_mult` 1.0 |
| `test_engine2_fixes.gd:336-358` (plasma dps, dps × 1.25) | `weapons.gd:_apply_beam` | same |
| `test_engine2_fixes.gd:361-383` (27.0), `:388-407` (180.0) | `projectile.gd:_deliver` | shot has no `source` |
| `test_engine2_fixes.gd:447-468` (chip = 3 units) | `weapons.gd:1233` rock branch | stats 1.0 |
| `test_combat_repair_c5.gd:202-225` (70.0, 87.5) | `weapons.gd:_apply_beam` | `_guns()` has null stats |
| `test_weapon_fx_f4.gd:124-125` (1.5), `:153` (98.5) | `weapons.gd:_deliver` | `_rig` passes null stats (`:354`) |
| `test_engine2_weapons.gd:600-615` (dps×delta, ×3) | `weapons.gd:_apply_beam` | null stats |
| `test_flight_beam_g2.gd:231` (30 × frame × 0.10) | `weapons.gd:1233` | null stats |
| `test_weapon_fx_f2.gd:169` (10.0) | `projectile.gd:_deliver` | no `source` |
| `test_engine2_damage.gd:288` (180.0 flat) | `Damage.detonate` (no production caller) | untouched by any S7 set |

**One assertion does flip, and only for Ledger** (bucket 2, disposition owed before
K3): `tests/test_s3_instances.gd:520-546`
(`test_sell_instance_pays_the_base_times_the_rarity_share`) mints
`LASER, &"rare", [{"id": "keen", "value": 0.16}], ["ledger"]` and asserts the payout is
exactly `ModuleData.sell_price(LASER, RARE)`. With the Ledger term the payout is
1.25 × that. This is the row §20's "no existing suite count moves" does not cover — the
count does not move, the assertion does.

## 4. `base × rarity × 60 %` call sites (ask 4)

The formula's one literal is `ModuleCatalog.sell_price` (`module_catalog.gd:642-643`,
`list_price × SELL_PERCENT / 100`, `SELL_PERCENT := 60` at `:85`). Callers:

| caller | file:line | role |
|---|---|---|
| `ModuleCatalog.sell_price` | `:642` | the literal (also a direct test surface) |
| `Auction._sell_row` | `:585` | the **pane's displayed** sell price (`sell_rows:543-568`) |
| `Auction.sell_row` | `:732` | the transaction's quoted price |
| `PlayerProfile.sell_instance` | `:723` | **the payout — where credits actually move (`:733`)** |
| `Auction.sell_price` | `:620-621` | a thin delegate; **no production caller** (only `test_s3_auction.gd:640`) |

So §20's "one optional parameter on `auction.gd`'s `sell_price` … `sell_row` passes the
record's own row" does not by itself change any price a player sees or is paid: the
displayed price is computed at `:585` and the paid price at
`autoload/player_profile.gd:723`, both straight through `ModuleData.sell_price`. The
brief's "both call sites" is measured as **three** production sites plus the delegate.
Integration: `07 §4`'s integer rule holds — per 100 CR the three products are 60 / 96 /
156, all divisible by 4, so `× 125 / 100` stays exact for every 09/15 cost (all
multiples of 100; 900-cost Common = 540 → 675).

## 5. `_on_npc_died` killer identity, and the Embers predicate (ask 5)

**Killer identity is not knowable (no new seam owed).** `NpcShip._die:377` emits
`died(global_position, _archetype)` — the signal's own signature is
`died(position, archetype)` (`npc_ship.gd:39`), and `take_damage:320-341` records only
`_last_damage_ctx`/`_attacked` (`:323-325`), never a source. `game.gd:_on_npc_died:2032`
receives only the position, archetype and victim. And a non-player death **does** reach
it: `NpcShip._on_body_entered:538-549` charges `take_damage` for any body-body contact
(rock or peer), so an NPC can die to a rock or to another NPC; heat still needs a
witness (`:2041-2043`) but standing and loot do not. So §20's fallback applies: Leeches
gates on the deaths the handler already credits (every `died` that reaches it). A
"player-only kill" reading would need attacker plumbing in `npc_ship.gd` — a file in no
S7 set.

**Embers' NPC predicate (bucket 1):** after the walk, `sink.is_in_group(&"npc_ship")`.
`weapons.gd:_sink_for:1806-1817` walks `SHIP_GROUPS` (`:348`) =
`[&"player_ship", &"npc_ship"]`; `projectile.gd:_sink_for:912-922` walks
`PLAYER_GROUP`/`NPC_GROUP` (`:57-58`). A rock is an `Asteroid` (`asteroid.gd:1`,
group `&"asteroid"` at `:228`) that answers no `take_damage`/`damage`, so it is returned
unchanged and is never in a ship group; the player's own hull is `&"player_ship"`. Both
`_deliver`s re-resolve the sink before use, so the predicate reads the same object the
damage lands on.

## 6. `set_weapons`' walk, and barrel ↔ cell (ask 6)

- `game.gd:_launch_weapons:502-510` skips `&""` and appends
  `WeaponScript.weapon_id(module)` — which is `&""` for a family-less module, so a
  `w_mining` cell stays a slot with no pack (its own doc `:499-501`). That is the walk
  `set_weapon_affixes` must mirror, and it is **cell** order (layout), not barrel order.
- `PlayerState.set_weapons:126-130` + `_resize_ammo:136-142` size `ammo`/`ammo_max` to
  that list; `setup:144-162` re-runs `_resize_ammo`, so `set_weapon_affixes` must land
  after `setup()` on the `_ready` handshake (`game.gd:319-343`: resolve `:321` →
  `set_weapons` `:326` → `setup` `:327` → `_seed_vitals` `:328` → `_seed_ammo` `:330/334`).
- **The two index spaces are both already named in the tree.** The cell→**barrel
  position** map is `game.gd:_weapon_barrel_positions:644-660` (a family-less or empty
  cell is `-1`); the cell→**`PlayerState.weapons` slot** map is
  `game.gd:_hull_slot_cells:1919-1944` (its `position`, incremented for every fitted
  non-empty cell, family-less included). `WeaponsComponent` barrels are
  `fitted_ids(fit)` order with family-less/foreign ids dropped by `set_fitted:498-505`
  (`player_ship.gd:582` hands it `ShipFit.fitted_ids(_launch_fit)`). The two coincide
  only while every fitted W cell fires — §16 rule 3 records the divergence, and
  `weapons.gd:508-518` documents it too. K2 therefore needs a barrel→slot map to read
  `weapon_affixes`; it is derivable from those two functions and lives entirely in K2's
  set (bucket 1), but §20's "report mismatch, never guess" is live.
- **`_launch_fit` cannot carry per-cell instance identity** (bucket 1):
  `game.gd:_profile_fit:456-480` maps every cell through `base_module_id:487-490`, so
  the per-cell affix walk must start from the profile's raw fit
  (`PlayerProfile.fit_for:877-886` / `resolved_fit:893-898`), not from `_launch_fit`.
- **Ammo is per family, not per cell** (§16 rule 5; `weapons.gd:2201-2208` resolves the
  family's index in the **const** `PlayerState.WEAPONS:35`, while the live packs are in
  fit order). This is LOW **L90**, with a live-profile repro; Frugal's per-cell bank
  sits on top of it: the bank is per barrel, the integer round leaves the family pack,
  and the gates (`_ammo_available:1866`, `dry_reason:757-766`) take no position. K2 must
  route around or fix L90's index resolution (bucket 1; L90 is not this wave's pin).
- `w_mining` can roll `[keen, rapid, frugal]` (`prefix_pool:690-699` keys off
  `fit_slot_of`, and the tool's slot is `weapons`), and it has no barrel, so its cell's
  affixes are inert. Report only.

## 7. §20's names against 17 §2 and §15/§16/§11 (ask 7)

- `game/affixes.gd` is **not** in `docs/gameplay/17_coder_handoff.md` §2's file map
  (`:24-43`), although §20 cites "(the wave's one new owner, 17 §2)". Doc drift, bucket 2.
- `docs/CONTRACTS.md` §2 (`:56-75`) says "Typed fields exactly" and has no
  `booster_cooldown_mult` (added by §20; `ship_stats.gd` is 45 lines and gains the
  field). §3 (`:76-89`) still pins `resolve(hull_id, fit)` two-argument, and §11 rule 2
  `:1059-1066` reads "`resolve(hull_id, fit)` accepts the old singular `engine` key".
  Both are stale against §20's optional third parameter — additive, so no caller breaks,
  but the text needs the cross-reference (bucket 2).
- §11's `player_state.gd` pin (`:1158-1165`) is additive-compatible: §20's
  `weapon_affixes`/`set_weapon_affixes`/`affix_flags`/`set_affix_flags`/`ammo_frac`
  collide with nothing; §15's `PlayerProfile` block (`:1462-1478`) has no
  `affix_summary`; §16 rule 5's "one pack per family" and §20's per-cell `ammo_frac` are
  not contradictory only if the report states which is the bank and which is the pack
  (finding F10). §20's supersession of §15's "no suffix term" is recorded in v0.15
  (`:2830-2845`) ✔.
- 15 §3's `Lightened` "−4/−6/−8 pp" vs the stored `-0.04/-0.06/-0.08` fraction and §20's
  `abs(Σ)`/clamp arithmetic: consistent (the same space as the armour row's
  `speed_penalty`), and §20 names its own reversal ✔.

## Findings and escalation buckets

Bucket 1 = inside the pin, the worker decides; bucket 2 = changes a pin/wording, a
`VAJB_WORKER_FILES` set or the tests-that-move list → orchestrator (developer session);
bucket 3 = taste or a supersession of an owner ruling → owner.

| ID | Finding | Bucket | Where |
|---|---|---|---|
| F1 | **§20's summary shape cannot express its own aggregation law.** `{prefix_id: summed_magnitude}` + a base-id-mapped `fit` loses which instance carries the prefix. Derived counter-example from shipped data: `s_light` (tier 1, `shield_add` 200, sturdy 0.10 → +20) beside `s_heavy` (tier 2, 400, sturdy 0.15 → +60) must add +80; a summed 0.25 against the 600 pool gives +150. Affects Sturdy, Vigilant (best), Wideband (best), Surefire (sum), Lightened, Tempered. Suffixes are unaffected (ship-level, once-per-perk). Disposition: carry per-instance rows (per instance id or per cell) in the summary, or let `resolve` take the raw fit — the resolver's own contract is "no nodes, no autoload" (`game/ship_fit.gd:11`), so the summary-side fix is the cheaper one. | **2** | `docs/CONTRACTS.md` §20 `:2081-2094`; `game/game.gd:_profile_fit:456-480`; `game/ship_fit.gd:917-1012` |
| F2 | **The projectile delivery is a second sink seam in a file no worker owns.** `projectile.gd:_deliver:885` is how every bolt/slug/rocket/mine lands (`_hit_body:785`, `_detonate:843`); `weapons.gd:_deliver:1774` is the beam's only. Without a set change, computers' +damage and Embers reach no projectile weapon. Options: add `game/projectile.gd` to K2's set, or apply the product at `weapons.gd:_spawn_shot` (where `_stats` lives) plus a projectile-side Embers hook; `projectile.gd` has no `_stats`/`_state` (only `_source:454`) and `PlayerShip._state:199` is private. | **2** | `game/projectile.gd:885`; `game/weapons.gd:1258,1774`; `SLICE.md` §Worker file sets |
| F3 | The multiplier must be null-tolerant, or 8 gate suites crash. `Weapons.setup` is handed `null` stats by `test_engine2_weapons.gd:84`, `test_flight_beam_g2.gd:371`, `test_s2_6_beam.gd:419`, `test_weapon_fx_f1.gd:546`, `test_weapon_fx_f4.gd:354`, `test_s5_batteries_v2.gd:587`, `test_s5_hardpoints.gd:223`, and `test_combat_repair_c5.gd:356` never sets up. Shipped convention: `weapons.gd:1665,1677`. | **1** | `game/weapons.gd:470-471` |
| F4 | **The tests-that-move list is not empty: one assertion flips for Ledger.** `test_s3_instances.gd:520-546` sells a Rare laser carrying `["ledger"]` and asserts the exact un-suffixed payout. Disposition it here (§20's own S6-`test_engine2_wiring` precedent): edit the fixture to `[]`, assert 1.25× and its own name, or keep `sell_instance` suffix-free and pay the term elsewhere. Everything else is safe under F3 and the no-computer fixtures (§3's table). | **2** | `vajb-orbit/tests/test_s3_instances.gd:527-546`; §20 `:2167-2173` |
| F5 | **The Ledger term as pinned pays nobody.** §20 pins only `Auction.sell_price`'s parameter; the displayed price is `Auction._sell_row:585` and the payout is `PlayerProfile.sell_instance:723` (credits at `:733`). `Auction.sell_price:620` has no production caller. The pin must name all three or say which one retires. | **2** | §20 `:2107-2109`; `game/auction.gd:585,732,620`; `autoload/player_profile.gd:723` |
| F6 | Killer identity is not knowable: `NpcShip._die:377` emits only position/archetype; `take_damage` records no source; and `NpcShip._on_body_entered:538-549` lets an NPC die with no player involved. Leeches gates on the handler's existing credit, §20's own fallback. | **1** | `game/npc_ship.gd:39,320-341,377,538-549`; `game/game.gd:2032-2049` |
| F7 | Embers' predicate is `sink.is_in_group(&"npc_ship")` **after** `_sink_for`; rocks (`Asteroid`, group `&"asteroid"`) are returned unchanged and excluded; the player's own hull is `&"player_ship"`. | **1** | `game/weapons.gd:348,1806-1817`; `game/projectile.gd:57-58,912-922`; `game/asteroid.gd:228` |
| F8 | Barrel↔cell: the affix arrays are cell-indexed while `WeaponsComponent` reads barrels; the two maps exist (`_weapon_barrel_positions:644-660`, `_hull_slot_cells:1919-1944`) but no barrel→slot map does. All in K2's set; §20's "report mismatch, never guess" applies. | **1** | `game/game.gd:502-510,644-660,1919-1944`; `game/weapons.gd:498-518`; `game/player_ship.gd:582` |
| F9 | `weapon_affixes` must be built from the profile's raw fit, not `_launch_fit`: `_profile_fit` maps every cell through `base_module_id`, so `_launch_fit` holds no instance ids. | **1** | `game/game.gd:456-490`; `autoload/player_profile.gd:877-898` |
| F10 | Frugal's per-cell bank sits on L90: `ammo_slot:2201-2208` indexes the const `PlayerState.WEAPONS:35`, not the fit-order `weapons` array, and the gates take no position. K2 must state which is the bank and which the pack, and route around or fix L90. | **1** (+L90) | `game/weapons.gd:757-766,1866,1877-1883,2201-2208`; `.agents/gen/_state/LOW_BACKLOG.md` L90 |
| F11 | The beam's per-family aggregation (`paid[weapon] = count`, `_fire_beam_battery:1073-1142`) loses the barrel identity Keen needs; a weighted sum is required, and `test_engine2_weapons.gd:600-615` pins the count reading for the affix-free case. | **1** | `game/weapons.gd:1068-1142,1227` |
| F12 | The two rock-chip sites (`weapons.gd:1233`, `projectile.gd:758`) bypass `_deliver`, so the owner's "rocks included" tick needs an explicit product there; the mining laser (`mining_laser.gd:199`) carries no damage amount at all. **F12b:** the **ram** (`player_ship.gd:924-930`) is a fourth player-origin sink with no pin text either way — a ruling is owed. | **1**, F12b **2/3** | `game/weapons.gd:1233`; `game/projectile.gd:758`; `game/mining_laser.gd:199`; `game/player_ship.gd:915-930` |
| F13 | Stale counts: "one call site in production" is measured **3** (`game/game.gd:434`, `game/repairs.gd:193`, `game/sector.gd:493`); "16 test call sites" is measured **36** in `tests/test_*.gd` (13 files) + 33 in `tests/probe_*.gd`. | **2** | §20 `:2092-2094`; `S7_BRIEF.md:41-43` |
| F14 | §20's "`weapons.gd` reads only `_state`, never the profile" is false as written: `_spend_item:1903` calls `_profile():2088` via `use_countermeasure:818-828`. The Embers intent is unaffected. | **2** | §20 `:2134`; `game/weapons.gd:1903,2088` |
| F15 | Stale field/signature/map text: §2 lacks `booster_cooldown_mult`; §3 and §11 rule 2 pin `resolve` two-argument; 17 §2's file map has no `game/affixes.gd` row while §20 cites it. | **2** | `docs/CONTRACTS.md:56-89,1059-1066`; `docs/gameplay/17_coder_handoff.md:24-43` |
| F16 | The stored convention holds (fractions; the three negative bands; String ids + float values). Two notes: a stored `0.0` must stay inert (no `prefix_value` re-read), and K1 should convert ids to StringName explicitly (the tree carries two contradicting statements about key interop). | **1** | `game/module_catalog.gd:127-211,725-753`; `autoload/player_profile.gd:2164-2211`; `game/auction.gd:648-650` |
| F17 | Environment, not drift: a Godot editor with the project open and a **game session playing** (`armory_panel.tscn`, `game_status.status=live`) was live during this pass — the L149 concurrent-writer caveat applies to the close-out's "live store md5 unchanged" claim. D7's uncommitted set at this pass: `ui/hud/hud.gd` (+54 insertions, `_build_cockpit` now at `:696` — the WAVEBOARD's `hud.gd:694` note is a snapshot of an earlier D7 edit), `ui/hud/hud.gd`'s pool-block retirement, `tests/test_engine2_hud.gd` (+a new pool-block row, D7's held §3.6 rows), `tests/test_d7_cockpit.gd`, five `assets/ui/*.png.import`, `docs/design/UI_SPEC.md`, its own brief/prompts/reports and new `staging/phase_g/*` scripts. Consequence for the close-out: D7 is **still adding rows**, so "674 + the three new suites" is only valid against a tree where D7 has stopped; re-read the gate count the settled tree prints. | **2** (harness note) | `.agents/gen/_state/WAVEBOARD.md:178-191`; `LOW_BACKLOG.md` L149; `git status`/`git diff --stat` at this pass |

## Deviations from SLICE.md / the brief

- The brief's "one call site in production, 16 in tests" (§20 repeats the 16) is
  measured 3 and 36 — F13.
- The brief's "`PlayerProfile.sell_instance` (§15's pin) is **the second** place the
  formula lives" is measured as a third (plus the delegate) — F5, with the payout, not
  the display, being the one that pays.
- "Tests that move: **none expected**" is measured as one Ledger assertion — F4.
- The brief's `_deliver` (singular) is measured as two independent `_deliver`
  implementations in two files — F2.
- The brief's "the mining laser" needs no `damage_mult` (no damage figure exists on that
  path); the tick's mining movement is the two gun-chip sites — F12.

Everything else the brief asserts was re-measured and holds: the `_resolve_stats`
bridge (`game.gd:425-434`, 3 production call sites and 69 test/probe call sites — F13),
the resolver chain
and its line numbers (`ship_fit.gd:573-615, 596, 917, 928, 967, 978, 982, 994, 1005,
1014`; `lock_range` at `:614`), `ShipStats.damage_mult` inert (only `ship_fit.gd:596,
978`, `ship_stats.gd:32`, and the two R1 probes reference it), `_sink_for`'s groups
(`weapons.gd:348`), `ammo` per family (`player_state.gd:84-100`, `weapons.gd:1866-1883,
2201`), the launch handshake (`game.gd:319-343`, `_launch_weapons:502-510`),
`_on_npc_died` (`game.gd:2032-2049`), `reveal_pois` (`sector.gd:335-338`) and the POI
fog read (`sector.gd:284`), the sell pair (`auction.gd:620,725`), Spry's consumer
(`player_ship.gd:1124`, catalogue `cooldown` 8.0 at `module_catalog.gd:445`), hunter
distance detection (`npc_brain.gd:421-427`), and no cargo-spill system anywhere.

## Evidence

Read-only measurement; no Godot run, no probe, no gate, no write outside this report.

```bash
git status --porcelain                  # D7's lane (see F17) + this report
grep -n "func _build_cockpit" vajb-orbit/ui/hud/hud.gd   # :696 at this pass
git diff --stat                         # D7's lane; hud.gd +54 insertions at the second read
sed -n '/^func _build_cockpit/,+4p' vajb-orbit/ui/hud/hud.gd   # the D7 break, :694 then :696
grep -rn "damage_mult" --include=*.gd vajb-orbit | grep -v addons/   # 2 setters, 0 readers
grep -rn "_deliver(" vajb-orbit/game/            # weapons.gd:1258,1774; projectile.gd:785,843,885
grep -rn "\.resolve(\|Fit\.resolve(" vajb-orbit/tests/test_*.gd | grep -v "##" | wc -l   # 36
grep -rn "\.resolve(" vajb-orbit/game/ vajb-orbit/ui/ | grep -v "##" | grep -v "func "    # 3 production
# same over tests/probe_*.gd                                                        # 33 probes
grep -rn "sell_price(" --include=*.gd vajb-orbit | grep -v addons/  # 5 sites (see §4)
grep -n "&\"computers\"" vajb-orbit/tests/test_*.gd                   # no damage-asserting suite
sed -n '520,546p' vajb-orbit/tests/test_s3_instances.gd               # the Ledger sale
grep -n "SHIP_GROUPS\|func _sink_for" vajb-orbit/game/weapons.gd     # :348, :1806
sed -n '1908-1944p' vajb-orbit/game/game.gd                           # cell -> weapons slot
sed -n '644-660p' vajb-orbit/game/game.gd                             # cell -> barrel position
```

## Files touched

- `.agents/gen/slices/S7-affix-application/S7-K0_report.md` — this report (only file written)

## Follow-ups

The orchestrator applies these to `docs/CONTRACTS.md` §20 + `S7_BRIEF.md` in the one
pre-K1 commit (K0's disposition pass); `docs/` writers are the orchestrator/R1, never
K0. LOW ids (**L158+** / next ticket **T-94**) are R1's to cut.

| Item | Kind | Where |
|---|---|---|
| F1 — decide the summary shape that can carry per-instance values (or let `resolve` take the raw fit); K1 cannot start without it | PIN | §20 `:2081-2094` |
| F2 — add `game/projectile.gd` to K2's `VAJB_WORKER_FILES` (or pin the spawn-time product + a projectile Embers hook) | PIN + FILE SET | `SLICE.md` §Worker file sets; §20 `:2144-2150,2134` |
| F4 — disposition the `test_s3_instances.gd:527-546` Ledger assertion | TESTS-THAT-MOVE | §20 `:2167-2173` |
| F5 — name the three sell sites (and that `PlayerProfile.sell_instance` is the payout) | PIN | §20 `:2107-2109` |
| F13/F14/F15 — stale counts, the `_profile()` sentence, §2/§3/§11 rule 2 text and the missing 17 §2 `affixes.gd` row | DOC | §20; `docs/CONTRACTS.md`; `docs/gameplay/17_coder_handoff.md` |
| F12b — does a ram count as "player-origin damage" for `damage_mult`? (no pin text either way) | PIN / OWNER TICK | `game/player_ship.gd:924-930` |
| F3, F6–F12, F16 — inside the pin; K1/K2/K3 decide and proceed (report the decision in their own reports) | CODE ROUTE | the files named per finding |
| F17 — attribute the 6 D7 rows and the live game session; re-check the live md5 claim after D7 closes | HARNESS | `WAVEBOARD.md:178-191`; L149 |
