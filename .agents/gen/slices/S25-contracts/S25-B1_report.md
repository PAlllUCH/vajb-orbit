---
slice: S25
worker: S25-B1
model: "hyper/deepseek-v4.1-flash (reasoning xhigh)"
status: actionable
gate: "1202/0 → 1224/0"
---

# S25-B1 report — the contracts board (A1–A8)

## Result
The board ships end to end: `game/contract_registry.gd` rolls seeded 6-row boards on the
20-minute clock, pays the section 2 shapes at the target sector's tier per the S28 table,
gates on standing, escrows real goods, and runs the section 6 escort loop in the shipped
flight scene; `ui/station/contracts_panel.gd` fills the SERVICES deck in place of
`station.gd:940`'s placeholder (T-138). Gate: **1202/0 → 1224/0**, twice, on two fresh
scratch stores, identical counts; the 22 new rows are all `test_s25_contracts.gd`'s and no
baseline row moved or disappeared (`diff` of the two `[PASS]` sets is purely additive).

## Acceptance list answers
- **A1 — DONE** — `ContractRegistry.board()` (6 rows = 5 rolled live + the Expedition seam,
  one per live type, seeded by `hash(station|band)`, re-rolled on `BAND_SECONDS`), faction
  ties = the target sector's owner, Hunt/Gather local and Haul/Escort to a station-bearing
  neighbour, Expedition `staged` — `contract_registry.gd:201`; proven by
  `test_s25_contracts.gd:test_a1_the_board_is_six_seeded_rows_on_the_clock`, `…sector_appropriate`.
- **A2 — DONE** — `reward()`/`pay()`: Hunt 800/1 100/2 200/4 400, Escort 1 200/1 600/3 300/
  6 500, Haul's flat 300/400/800/1 600 + `sale_quote` spot ×1.25, Gather ×1.4, 12 §3's bias
  through `demand_for`, Known's +5 % in `pay()`, every reward `% 100 == 0` —
  `contract_registry.gd:504-600`; proven by the three `test_a2_*` rows (the round-to-100 rule
  is swept over all six station sectors' boards).
- **A3 — DONE** — the board is empty when `StationRegistry.contracts_visible(standing)` is
  false (S24's seam, read only), Champion gets one `standing_order` row, `MAX_ACTIVE` 3 with
  the U6 counter and chip — `contract_registry.gd:186,201,321`; `contracts_panel.gd:_refresh`;
  `test_a3_*`, `test_a7_the_max_three_counter_and_chip`.
- **A4 — DONE** — accept removes the stack into the record's `escrow`; cancel returns it and
  charges exactly 100 CR; `complete()` takes the record out of the list **before** it pays,
  so a second call pays 0 — `contract_registry.gd:629,677,722`; `test_a4_*`.
- **A5 — DONE** — the convoy spawns at the accepting station from the sector's own trader row
  (Hauler stats, 1–2 fighters, the plan's pods as visible marks), flies station → corridor
  midpoint → gate, ambushes once inside `CORRIDOR_DEPTH` of the midpoint, and pays at the
  destination / files −5 with the loot dropped on a loss — `game.gd:2686,2802,2866,2913`; `test_a5_*` (two of them
  mount `game.tscn` and drive the real nodes).
- **A6 — DONE** — the active list is the profile's own `contracts` key (save + read); the
  convoy is rebuilt from it on sector entry, so a dock/launch cycle re-spawns it and a
  contract that left the list never does — `contract_registry.gd:606`, `game.gd:2686`;
  `test_a6_active_contracts_survive_a_restart` (a fresh profile instance reads it back).
- **A7 — DONE** — the deck is real (`station.gd:1062`, the placeholder retired),
  the panel carries U3's headers + note, the row anatomy, ACCEPT, U6's counter/chip, U7's
  staged row, U5's escrow readout, U4's `CANCEL · 100 CR FEE` + the §5.2 confirm dialog, and
  both U8 empty states verbatim — `contracts_panel.gd`, `station.gd:469`;
  `test_a7_*` (five rows).
- **A8 — DONE** — `launch_panel.destination_line()` reads the docked station row's own sector
  name (`OPEN SPACE · MERIDIAN SPAN`, no `HELIOS` anywhere); `refinery.gd:130`'s example reads
  Gold's 259 → 26 s, comment only (`resource_seconds` unmoved) — `launch_panel.gd:61,281,293`;
  `test_a8_*`.

## Deviations from SLICE.md / the brief (every one reversible)
| # | Deviation | Why | Reversal | Tick |
|---|---|---|---|---|
| D1 | The board's 6 rows are **5 rolled + the Expedition seam row** (one live type repeats) | R-S25-1 says 6 visible rows *and* Expedition is a row; a 7th drawn row would break the size | 6 rolled live rows + a 7th staged row | J1 |
| D2 | Haul's objective names the **destination station's own name** (`40× ingot_titanium to Ashveil Exchange`) | §2's `to S4 outpost` cannot hold for a destination whose primary is not an outpost | the literal `to S%d outpost` | U21 (PROPOSED) |
| D3 | The convoy's fleet number is the board row's ordinal | no doc pins one | a rolled 1–9 | U21 |
| D4 | Cancel is **refused** when the purse cannot pay the 100 CR | 17 §5's all-or-nothing, and no doc grants a debt | the fee as a debt (credits floor 0) | U21 |
| D5 | The escort pays on the hauler's **arrival** at the gate; the destination station is the site the log names | "payout at destination station" would otherwise need a collection step the docs do not describe | held until the player docks at the destination | U21 |
| D6 | The reward cell renders `pay` (Known's +5 % applied), not the board's `reward` | A2's hook must be visible to the player who earns it | the board's `reward` | U21 |
| D7 | At 3/3 the `MAX 3 ACTIVE` chip sits on the column head **and** on every disabled ACCEPT | U6's own "every ACCEPT … carries the chip" | the head chip alone | U6 |
| D8 | The panel's own `PaneHeader` reads `CONTRACTS` (the deck's reads `SERVICES`) | §15.2 is the panel's law; §19.4's SERVICES row is the deck's | the deck's header only | U21 |
| D9 | Column widths 140/220/130 and the 420 right column | §15.2's own PROPOSED row | §3.1's 40/130/110/160 | U21 |
| D10 | The staged row's reward cell is empty | §2 prices Expedition as "arena payout" (S26's); a `0 CR` cell would lie | the cell reads `0 CR` | U7 |
| D11 | INSURANCE / VAULTS mount the host's own not-installed placeholder inside the strip | their panels are S26's; the strip and the U2 unavailable state still ship | hidden until S26 | U21 |
| D12 | New refusal/outcome status lines (`REFUSED · MAX 3 ACTIVE`, `REFUSED · %d× %s NEEDED`, `ACCEPTED · <objective>`, `CONTRACT CANCELLED · 100 CR FEE`) | no doc pins a contract refusal wording; the shapes follow `station.gd`'s own `REFUSED · …` copy and 09 §2's `<n> NEEDED` | silent refusals | U21 |
| D13 | `AMBUSH_SPAWN_RADIUS` 300, `POD_MARK_SCALE` 0.35, `POD_MARK_SPACING` 9 | placement/layout values no doc pins; the ambush radius itself is `SectorRegistry.CORRIDOR_DEPTH` | the ring to 0 and one mark per hold unit | U21 |
| D14 | The escort's pods are `round(0.5 × the Hauler's resolved hold)` hold units, drawn as 4 visible marks | §6's "50 % of hold filled with visible cargo pods"; 30 marks would overdraw an 88 u hull | one mark per hold unit | U21 |
| D15 | The contracted convoy is spawned by `game.gd` (route injected at `setup`), so it is **not in the sector's blip list** | `NpcShip` takes its route only through `setup`, and `sector.gd` is out of this wave's file set | spawn through `sector.gd:_add_npc` once it forwards `OPT_ROUTE` | U21 |
| D16 | Known's floor is spelled `ContractRegistry.KNOWN_FLOOR := 11` | `StationRegistry` ships no `KNOWN_FLOOR` (only the Shunned and Champion floors) | read a shared constant once S24 adds one | U21 |

M11's scaling, the SC table (01's block verbatim), 14 §2's reward shapes/escrow/100 CR/max 3,
12 §3's bias floats and 12 §4.1's +5 % are the pin, not deviations.

## Evidence
- Gate twice, fresh stores: `XDG_DATA_HOME=/tmp/s25_gate1 godot --headless --path "$VAJB_PROJ"
  res://tests/headless_runner.tscn --quit-after 2400` → `[SUMMARY] passed=1224 failed=0`;
  the same with `/tmp/s25_gate2` → identical line. Baseline on `/tmp/s25_baseline_store`
  → `passed=1202 failed=0`.
- Row-level proof: `diff` of the sorted `[PASS]` lines, baseline vs gate 2 → 22 additions,
  all `test_s25_contracts.gd`, no other row changed.
- A2's table: `test_a2_hunt_and_escort_pay_the_s28_table` asserts 800/1 100/2 200/4 400,
  1 200/1 600/3 300/6 500 and 300/400/800/1 600 straight off `reward()`/`scaled_flat()`.
- A4's once-only: `test_a4_a_double_completion_pays_once` — first call `paid=800`, purse
  +800; second call `ok=false`, `paid=0`, purse unmoved.
- A5's runtime: `test_a5_the_convoy_spawns_and_reaches_the_gate` mounts `game.tscn`, finds
  one hauler + 1–2 fighters, 4 `CargoPod*` children, `route[0]` == the station,
  `route[2]` == the gate, the ambush fires on the midpoint crossing and the arrival closes
  the contract with the purse up; `…the_hauler_death_drops_the_loot` proves no payout, −5
  standing and one ledger drop of `ingot_iron × escort_pods()`.
- A8's comment fix: `test_a8_the_refinery_example_is_live` reads `refinery.gd`'s text
  (`Gold's 395` gone, `Gold's 259 reads 26 s` present) and `resource_seconds(&"gold") == 26`.

## Files touched
- `game/contract_registry.gd` (new) — the board, the reward law, the gates, the escrow, the escort plan.
- `game/game.gd` — the escort runtime (spawn, route, ambush, win/loss, the loot drop) and its hooks.
- `game/npc_registry.gd` — `convoy_spawns()` / `convoy_role()`, so a contracted convoy is the sector's own row.
- `ui/station/contracts_panel.gd` + `.tscn` (new) — the §15.2 deck (U3–U8).
- `ui/screens/station.gd` — the SERVICES deck (strip, one panel at a time, U2 reasons), the §5.2 confirm dialog, `pane_for()`.
- `ui/station/launch_panel.gd` — T-152: the undock line names the docked sector.
- `game/refinery.gd` — T-154: the stale fee example corrected (comment only).
- `tests/test_s25_contracts.gd` (new) — 22 rows, A1–A8.

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| The contracted convoy has no minimap blip (D15) | [CODE] | `game/game.gd:_make_convoy_hull` + `game/sector.gd` |
| S26 flips `staged` off the Expedition row and gives it its arena payout | [CODE] | `game/contract_registry.gd:_expedition_row` |
| INSURANCE / VAULTS panels inside the SERVICES strip | [CODE] | `ui/screens/station.gd:_build_services` |
