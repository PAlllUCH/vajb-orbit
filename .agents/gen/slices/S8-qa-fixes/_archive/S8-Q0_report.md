# S8-Q0 report — QA-finding reproduction and attribution on HEAD

Worker: S8-Q0. Tree: HEAD `8c91716` (game code = `1a1f57a` + `48779d5`, which added no
game/UI code). Method: real headless runs on **scratch stores** (`XDG_DATA_HOME=$(mktemp -d)`,
probes repoint `save_path`); the owner's `user://` was never written. Gate measured once:
`[SUMMARY] passed=753 failed=0`. Everything below is measured, nothing fixed. Probes (new,
`tests/`): `probe_s8_q0_launch.tscn`, `probe_s8_q0_ram.tscn`, `probe_s8_q0_exchange.tscn`,
`probe_s8_q0_armory.tscn` (+ `.gd` each); each self-quits and prints `[S8Q0*]` lines.

## Dispositions (orchestrator applies to §21 before Q1)

| id | verdict | break, at file:line | bucket |
|---|---|---|---|
| H1 gate/spend | **confirmed, real** | `game/weapons.gd:2391 ammo_slot` + `:2001-2006 _ammo_available` + `:2029-2033 _consume_ammo` index `PlayerState.WEAPONS` (`game/player_state.gd:35`, 5 families), not the launched `weapons`/`ammo` (`:178-185 _resize_ammo`). No longer a "seed path" break. | 1 (Q1 owns `weapons.gd`); the tests-that-move list grows → 2 |
| H1 briefing | **confirmed, real** | `ui/station/launch_panel.gd:609-615 _ammo_total` sums **all six** `AMMO_PACKS` and `:618-619 _weapon_count` returns the constant 6 — neither reads the launched fit | 1, but **`ui/station/launch_panel.gd` is missing from Q1's `VAJB_WORKER_FILES`** → file set grows (2) |
| H1 seed path | **not the break** | `_seed_ammo` (`game/game.gd:1877-1886`) draws per fitted cell and is correct; measured draws `[300, 300, 0]` (QA fit, default store) and `[0, 300, 0]` (cannon drained) | — |
| H2 cell payload | **not reproduced** | on the QA's own fit the pane agrees cell-for-cell: `W1 · B1 · Cannon MkI \| W2 · B1 · Railgun \| H1 · Light Plate \| S1 · Light Shield \| W3 · Mining Laser \| E1 \| P1`. No duplicated family, no armour in a W row | — |
| H2 rack ordinal | **confirmed, real** | `game/game.gd:2087 _rack_ordinal(batteries, index)` passes a **layout index** while `_launch_batteries` (`:770-792`) holds **barrel positions** from `_weapon_barrel_positions` (`:813`, family-less cells get `-1`). Measured: fit `[w_mining, w_laser]` → `W1 B1 Mining Laser, W2 B0 Laser MkII` (the firing cell unreachable); `[w_cannon, w_mining, w_laser]` → `W3 B0 Laser MkII` | 1 (Q1 owns `game.gd`) |
| H2 "same rack" | **confirmed, by design** | with an empty `_batteries` record (fresh/QA state) `player_profile.gd:1236-1241` puts **every fitted weapon in one trailing rack** → every W cell renders `B1` | 3 (reads as a duplicate; owner UX call) |
| H2 `W3 · Light Plate` | **not reproducible on HEAD** | only a fit whose `weapons` array already holds `h_plate_light` prints it (reproduced in a probe fixture); no HEAD writer can put one there (`fitting_panel.gd:1861 _row_target_cell`, `player_profile.gd:1330`, `armory_panel.gd:2227` all guard the slot). The row at that position on the QA's fit is `H1 · Light Plate` (`ship_status_screen.gd:860` walks `grid_cells` row-major) | close in the disposition table |
| M4 Repairs | **confirmed, real** | `ui/station/repairs_panel.gd:177-178` read the **station row** (`1000/600`) while `:179/181` read the raw vitals → measured `hull=1250 / 1000`, `shield=800 / 600`. `ShipFit.resolve` gives `1250/800` | 1 (Q1 owns `repairs_panel.gd`) |
| M4 footer | **not reproduced** | the status footer prints the resolved pair on HEAD: `HULL 1250 / 1250`, `SHLD 800 / 800` (game.gd `_apply_ship_maxima` feeds both from `ShipFit.resolve`; `set_pool`/`set_shield` clamp, so current > max is unreachable) — the QA's `SHIELD 800 / 600` is the Repairs pane's reading | note in the table |
| M1 | **confirmed, real** | 8 refusals **per fragment**; 16–40 per ram (2–5 medium fragments). Exact trace: `game/asteroid.gd:347 _build_look` ← `:232 setup` ← `asteroid_field.gd:255 _new_rock` ← `:365 _cleave` ← `:271 _on_rock_cracked` ← `asteroid.gd:309 _crack` ← `:248 apply_work` ← `:262 apply_collision_damage` ← `player_ship.gd:940`. Engine names them: `body_set_shape_disabled`, `body_set_shape_as_one_way_collision`. Fragments do spawn | 1 (Q2) |
| M2 | **confirmed, real** | `ui/station/exchange_panel.gd:554 _confirm_text` prints `String(_selected_id).to_upper()` (and `:656 _announce_sale` likewise); the hold row uses `_item_name` (`:920`). Measured strip `SELL 1 MINERAL_CHROMIUM — GROSS 25 · FEE 10 · YOU GET 15` beside hold row `CHROMIUM ORE` | 1 (Q2) |
| M3 | **confirmed, real** | `game/exchange.gd:276-296 sell()` re-evaluates and re-quotes at the live price; `exchange_panel.gd:613` passes no quote. Measured: preview paid **15** → press credited **+5** (6001→6006) after the demand re-roll | 1 (Q2) |
| O1/O2 | **ARMORY drag commits; FITTING has none** | `armory_panel.gd:1950 install_weapon` → `player_profile.gd:1316 fit_into_rack` → `set_battery_groups` (`:1252`, called `:1350`). Probe: `drag_inventory(w_laser)` → `can_drop` true → `drop` true → groups `[[0]]`, stored `{ship_vanguard: [[0]]}`; barrel move `[[0],[1]]` → `[[0,1]]`. FITTING declares zero handlers (`Script.get_script_method_list` = `[]`; `rg` = 0 hits) | genuine break: none. UX call = 3 (owner) |
| O3 | **measured, premise broken** | shipped masks: player `layer 2 / mask 1`, NPC `layer 2 / mask 1` → **contact never resolves** (probe: contact=false, 0 damage). With the player's mask including the hull layer: `collision_damage(mass_a=110, mass_b=80, dv=450)` = **93.7895**, delivered to the NPC shield `600 → 506.2` and to the player's own shield `800 → 706.2`; `damage_mult` 1.0; NPC pool 950/600 | attribution change → 2; factor → 3 (orchestrator/owner) |

## H1 detail (the exact break)

The launch seeds correctly: `_seed_ammo` walks `PlayerState.weapons` (the fit's cells) and
per family calls `PlayerProfile.load_ammo_from_hold` (`autoload/player_profile.gd:373`, drawing
the hold's `ammo_*` units). The **firing gate and the spend** then resolve the family through
`WeaponsScript.ammo_slot` (`weapons.gd:2391-2397`), which searches the constant
`PlayerState.WEAPONS` = `[laser, cannon, rocket, mine, plasma]` and indexes `_state.ammo` — an
array `set_weapons`/`_resize_ammo` sized to the **launched fit**. The two spaces coincide only
while the fit is a prefix in that exact order (the one-laser P2-A case), which is why P2-A read
`300 rounds` and the QA's fit did not.

Measured, QA fit `[w_cannon, w_railgun, w_mining]`:
- `state.weapons = [cannon, railgun, ""]`, `state.ammo = [0, 300, 0]`;
- cannon-only fit `[w_cannon, "", ""]`, its own pack **300** → `dry_reason = ammo`, 0 shots, 0
  projectiles (proved: correct ammo does **not** make it fire — `ammo_slot("cannon")` = 1 ≥
  `ammo.size()` = 1);
- QA fit, cannon 0 / railgun 300 → 4 shots spawn, 2 projectiles, and `ammo[1]` 300→296: the
  cannon barrel fires but **spends the railgun's pack**.

So the QA's `Cannon MkI 0/300` + no projectile is the gate reading the wrong slot, not a failed
seed; and the briefing's `1 941 … ACROSS 6 WEAPONS` is `launch_panel.gd:609-619` counting all six
packs and a fixed weapon count.

## Tests that move (amends §21's "Expected: none")

- `tests/test_engine2_hud.gd:142/144/150` pin `"1 240 m  IN RANGE"`, `"1 240 m  OUT OF RANGE"`,
  `"900 m"` — **must move** if the range copy changes `m` → `u` (`ui/hud/hud.gd:128
  DISTANCE_FORMAT := "%s m"`, consumed `:1390`).
- At risk from the H1 fix (expected to stay, `ammo_slot` re-pointed at the state's own
  `weapons`): `tests/test_s5_batteries_v2.gd:605,673`, `tests/test_s7_weapon_affixes.gd:404`
  (+`:386/:422-423` via helpers), `tests/probe_s4h4_stream.gd:45,76,91,96`,
  `tests/test_s5_ammo_cargo.gd:317` (seed `[300, 120]`). `tests/probe_c2_weapons.gd:201,745`
  print it (probe output only).
- If O3's factor lands **inside** `Impact.collision_damage` (the one owner): `tests/
  test_engine2_damage.gd:226` and `tests/test_s7_weapon_affixes.gd:526` re-derive it and would
  move. If it lands at the call site (`player_ship.gd:_on_hull_body_entered` / a new constant),
  they do not.
- No test pins `Cannon Mk1`, `Mk1`, `CONVERSIONS` (plural copy), `CONFIRM_FORMAT`, `YOU GET`,
  `MINERAL_CHROMIUM`, or the sale/confirm strings. `tests/test_p1_refinery.gd:192`
  (`test_stacks_lists_only_convertible_minerals`) is present and **must not move**.
- `tests/test_ship_grids.gd:58-59` pin the catalogue's own `Laser MkII`/`Cannon MkI`; no move.

## LOW re-check (QA section, each at file:line)

| item | verdict |
|---|---|
| `REFINERY ALL` reads as a heading | confirmed, `ui/station/refinery_panel.tscn:199`; docs-pinned (04 §5, STATION_HUB §12.3) → owner tick |
| stepper `1 CONVERSIONS` | confirmed, `ui/station/refinery_panel.gd:81 STATUS_READY "%d CONVERSIONS"`; singular is the proposed change → owner tick |
| Refinery hides sub-convertible stacks | confirmed by design; pinned by `tests/test_p1_refinery.gd:192` → owner tick |
| "three spellings" (`MK1`/`Mk1`/`MkI`) | **not reproduced in code**: zero `Mk1`/`MK1` in `ui/`. Fitting/HUD print the catalogue's `Cannon MkI` (`hud.gd:65`, `ModuleCatalog.module().name`); Armory does `to_upper()` → `CANNON MKI` (`armory_panel.gd:_module_name`). The QA's `Mk1` reads are the `MkI` glyph read as a digit |
| `860 m OUT OF RANGE` vs units | confirmed, `ui/hud/hud.gd:128` (+1389); moves `test_engine2_hud.gd:142/144/150` |
| Auction `NEXT RESTOCK 20:00` no unit | confirmed, `game/auction.gd:138 RESTOCK_FORMAT`; §21 says the literal stands → owner tick, no change |
| Auction thumbnails ~16 px near-black | designer lane 9–12; attributed, not measured |
| engine warnings | confirmed at HEAD: `game/module_catalog.gd:636/643/651 int/int`, `game/projectile.gd:1489` (`var scale`) and `:1759` (`var material`), `game/weapons.gd` `position` parameters at `:1885,1901,2014,2043,2066`. Note: `weapons.gd` carries **12** `position`-parameter functions on a `Node2D`, so the ledger may be larger than the QA's five |
| `tools/d7r1_probe.gd:397` parse error | **did not reproduce** — the file does not exist under `res://` and no file references it (archived out); confirmed |
| stale log `player_ship.gd:1378` too-many-arguments | **stale**: the call at `:1427` passes 5 args and `projectile.gd:1514` takes 5 |
| composition / vision LOWs | designer queue 9–12 (D11 live); attributed, never touched |

## O1/O2 readings for the owner's UX call (no recommendation)

Surfaces that can assign a weapon **group** today: the ARMORY pane only —
`install_weapon` → `fit_into_rack` (`:1350 set_battery_groups`), `move_barrel` → `move_rack_cell`
(`:1431`), `remove_barrel` → `clear_rack_cell` (`:1383`); `migrate_batteries` (`:1454`) derives
racks at load, and `set_batteries` (`:1199`) has no production caller. FITTING assigns modules to
cells (`fit_module_at`, `player_profile.gd:1013`) and a newly filled cell silently joins the
trailing unassigned rack (`:1236-1241`) — it never assigns a group. Keyboard `weapon_1..7`
selects a rack; it assigns nothing.

- Reading A (port): the drag exists and works, so the deliverable is a FITTING-side drag +
  drop-zones (Q2 already owns `fitting_panel.gd`).
- Reading B (point at ARMORY): a filled FITTING cell lands in a rack with no pane to re-order it,
  so the owner's "cant set weapon groups" is discoverability — a pointer/hint, no new drag code.
- Reading C (unify): one fitting surface (racks + cells) so a fit and its racks are composed in
  one place; largest scope, touches two panes.

## Owner notes

- **O3 attribution (2):** the attributed seam `player_ship.gd:922 _on_hull_body_entered` is
  unreachable player→NPC with the shipped collision masks (`game/player_ship.tscn:17` layer 2,
  default mask 1; `npc_ship.gd:209-210` layer 2, mask 1). The reduction factor therefore needs a
  ruled site and a re-attributed symptom (projectile/NPC-fire damage, or the physical push), and
  the masks are a separate, unmeasured decision.
- **File-set gap (2):** `ui/station/launch_panel.gd` is required by H1 and is in no worker's set.
- **The QA wrote the live `user://` profile** (its appendix item 5); the live file carries
  `fits.ship_vanguard.weapons = ["mod_0319","mod_0471","w_cannon"]` (three cannons) and
  `batteries = {}` — the fit Q0 measured is the brief's own (Standard Drive + Cannon MkI +
  Railgun + Mining Laser), not that stale file.
