---
slice: S25
worker: S25-F1
model: "hyper/deepseek-v4.1-flash (reasoning xhigh)"
status: actionable
gate: "1223/1 → 1226/0"
---

# S25-F1 report — the fixer

## Result
F1, F2 and F3 cured at their named sites; the two LOW rows left alone. The board's loop can
now be finished in play: a Haul delivers at its destination station and a Gather at the one it
was taken at, and a Hunt closes on the fifth credited pirate. Gate **1223/1 → 1226/0**, twice
on fresh scratch stores, exit 0; the PASS-set diff against B1's baseline store is purely
additive (24 `test_s25_contracts.gd` rows, zero other suite lines moved).

## Finding-by-finding disposition
| ID | Tier | Disposition |
|---|---|---|
| S25-B1/F1 | HIGH | **Cured** — three production exits wired, one new door each side of the seam; proven by two new gate rows that fail when either seam is removed. |
| S25-B1/F2 | HIGH | **Cured** — the row stocks the board's own rolled item instead of `ingot_iron`; band-independent by construction (the item is read off the same row the accept locks). |
| S25-B1/F3 | MED | **Cured** — Hunt's standing is now 14 §2's "+1 per kill" (5 over the five the objective names), tabled with its reversal. |
| S25-B1/F4 | LOW | **Untouched** — the U7 dim scope is T-156's, not this pass. |
| S25-B1/F5 | LOW | **Untouched** — the double-accept id collision is T-157's, not this pass. |

## F1 — the loop's missing exits
The reviewer's read stands: `complete()` had no production caller, so an accepted Haul/Gather
locked its goods forever and a Hunt's `count` could never move. Three doors now exist, and
every one of them goes through the same `complete()`, so the escrow is consumed once and the
purse moves once:

1. **Haul/Gather deliver at the dock.** `ContractRegistry.delivery_station`
   (`contract_registry.gd:755`) answers a Haul's own `target_station` and a Gather's
   `origin_station` (its objective, "20× mineral_cobalt ore (raw)", names no other place);
   `deliver_at` (`:769`) sweeps the active list at the station the route landed on. The
   production caller is the shell's own dock seam, `station.gd:344 on_route` →
   `_deliver_contracts()` (`:355`), beside `_normalise_market` — the same "at the dock" seam
   the market already uses — and the status strip reports the pay
   (`STATUS_DELIVERED`, `station.gd:202`).
2. **Hunt credits each kill.** `ContractRegistry.credit_kill` (`contract_registry.gd:786`)
   takes one off the record's own `count` for a pirate killed in the contract's own sector and
   closes it when the count empties. The production caller is the flight scene's kill seam,
   `game.gd:2611` in `_on_npc_died` → `_credit_hunt_kills` (`:2692`), which reads only the
   victim's archetype (`NpcRegistry.ARCHETYPE_PIRATE`, `npc_registry.gd:97`) and the sector.
3. **Escort** already had its exit (`escort_won` / `escort_lost`,
   `contract_registry.gd:884/892`, called from `game.gd:2955 _finish_escort` and
   `game.gd:2940 _on_escort_hauler_died`) and is untouched.

## F2 — the band-dependent A7 row
`test_a7_the_staged_row_the_escrow_and_the_cancel` stocked a fixed `ingot_iron` while the
accept locks the band-rolled Haul stack (R1's band 1492912: 40× `ingot_aluminium`). It now
mounts the panel first, reads the rolled row's own `item_id` and stocks that
(`test_s25_contracts.gd:1137`), so the escrow assertion cannot depend on the band — the same
read its sibling `test_a7_the_board_rows_and_accept` already made. The clock was **not**
pinned (the reviewer's second option): a pinned band would leave the row band-specific again.

## F3 — Hunt's standing
`standing_for(TYPE_HUNT)` (`contract_registry.gd:403`) now answers
`STANDING_HUNT * HUNT_COUNT` = **+5**, so the whole contract files 14 §2's "+1 standing per
kill extra" over the five the objective names, and the completion door stays the one standing
channel (a hunt abandoned before its last kill files none of it). Reversal: the flat
`STANDING_HUNT`, which is the reading B1 shipped untabled.

## Evidence
- Gate, twice, fresh stores (`XDG_DATA_HOME=$(mktemp -d)`, full runner, `--quit-after 2400`):
  `[SUMMARY] passed=1226 failed=0` (exit 0) — `/tmp/s25f1_gate1.log:1483`,
  `/tmp/s25f1_gate2.log:1483`; both PASS sets byte-identical (`diff` → none).
- Row-set proof: `diff` of the sorted `[PASS]` sets, B1's `/tmp/s25_baseline.log` vs
  `/tmp/s25f1_gate1.log` → 24 additions, all `test_s25_contracts.gd`, no other row moved.
  Arithmetic against R1's own run: 1223 + the one FAIL row now passing + 2 new rows = 1226.
- Negative control (both new rows are load-bearing): with `_deliver_contracts()` and
  `_credit_hunt_kills()` calls removed, the scoped run reads
  `[SUMMARY] passed=22 failed=2` — `test_a4_a_dock_delivers_the_escrowed_stack` fails on "the
  Gather closed at the station it was taken at" and `test_a4_a_hunt_closes_on_the_fifth_pirate`
  on "kill 1 takes one pirate off the row" (`/tmp/s25f1_neg.log`); both seams restored and the
  two runs above re-measured afterwards.
- New rows: `test_a4_a_dock_delivers_the_escrowed_stack`
  (`tests/test_s25_contracts.gd:568` — the board's own Haul and Gather, the dock at the
  accepting station and at the destination, the second dock paying nothing, the shell's status
  line) and `test_a4_a_hunt_closes_on_the_fifth_pirate` (`:636` — the board's own local Hunt,
  a swarmer crediting nothing, four kills moving `count` 5→1 with the purse unmoved, the fifth
  closing it for the tier-1 row plus the +1-per-kill standing).
- `test_a4_a_double_completion_pays_once` (`:531`) now also asserts the figure itself
  (`standing_for(TYPE_HUNT)` = `STANDING_HUNT * HUNT_COUNT` = 5), so F3 is pinned, not just
  restated.

## Files touched
- `game/contract_registry.gd` — `standing_for`'s Hunt row; new `delivery_station`, `deliver_at`
  and `credit_kill`; the header's "every live type has one production exit" note.
- `game/game.gd` — `_credit_hunt_kills` + its call in `_on_npc_died`, the
  `CONTRACT_DONE_PROMPT` const, and the ambush filter's literal → `ARCHETYPE_PIRATE`.
- `game/npc_registry.gd` — `ARCHETYPE_PIRATE` (the pirate id's one home; `game.gd` spelled the
  literal twice).
- `ui/screens/station.gd` — `on_route` → `_deliver_contracts`, `_docked_station_id`,
  `STATUS_DELIVERED`, the `ContractRegistry` preload.
- `tests/test_s25_contracts.gd` — F2's stocking fix, F3's figure, the two new rows,
  `_find_type` / `StubHull` / `_stub_hull` (the `test_s6_heat.gd` victim idiom).

## Readings and reversals (no pin moved)
| # | Reading | Why | Reversal |
|---|---|---|---|
| G1 | A Gather delivers at the station it was taken at | 14 §2's Gather objective names no destination, and the goods are escrowed at accept, so the accepting station is the only delivery site the pin leaves | deliver Gather at its sector's primary |
| G2 | Hunt's `count` is read as pirates still to destroy (5 → 0) | the row's own requirement, and the objective string is built at roll time, so nothing re-words it | an added `kills` progress key beside a fixed `count` |
| G3 | `CONTRACT_DONE_PROMPT` / `STATUS_DELIVERED` wording | no doc pins a contract-outcome or delivery line; the shapes follow the escort's arrival line and the panel's own `CONTRACT CANCELLED · %d CR FEE` | silent outcomes |
| G4 | The ambush filter's literal → `NpcRegistry.ARCHETYPE_PIRATE` (`game.gd:2896`) | one line, no behaviour change: the same predicate my new guard reads, so the two spellings cannot drift | the literal back |

## Owed (not mine to land)
| Item | Kind | Where |
|---|---|---|
| `docs/CONTRACTS.md:923-924` still reads "expected after the cure: **1224/0**"; the cure adds two gate rows, so the measured figure is **1226/0** — docs text is the developer's (bucket 2), left untouched | [DOC] | `docs/CONTRACTS.md` §9's S25 block |
| F4 / F5 unchanged | [CODE] | T-156 / T-157 |
