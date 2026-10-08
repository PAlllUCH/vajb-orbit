---
slice: S25
reviewer: S25-R1
verdict: blocked
gate: "1202/0 → 1223/1 (R1's own runs, twice, fresh scratch stores)"
---

# S25-R1 review

Graded against the brief §5 extract (14 §2 + §6 + the P3 block + the S28 block +
12 §3/§4.1 + STATION_HUB §15.2), never against B1's report.

## Acceptance list

- A1 — pass — R1 probe, live band 1492912: six rows (hunt, haul, gather, escort,
  hunt, expedition), the one live-type repeat is D1's tabled reading; ties are the
  target sector's owner, hunt/gather local and haul/escort to station-bearing
  neighbours (`test_a1_*` both rows).
- A2 — pass — `test_a2_hunt_and_escort_pay_the_s28_table` asserts 800/1 100/
  2 200/4 400, 1 200/1 600/3 300/6 500 and Haul's 300/400/800/1 600 + spot×1.25;
  Gather ×1.4; round-to-100 swept over all six station sectors' boards
  (`test_s25_contracts.gd:357-368`); 12 §3's floats asserted per faction; Known's
  +5 % asserted at 20 and at 80 — the "Known and above" reading follows V4's
  owner-ratified extension of the same band row (12's S24 block).
- A3 — pass — `contracts_visible(−20/−80)` false → the U8 gated state; Champion 80
  answers exactly one `standing_order` row on a still-six-row board; the fourth
  accept refuses `max_active`; U6's counter + chip verified as rendered.
- A4 — drift — the registry's lifecycle is proven (accept reserves off the
  manifest; cancel = exactly 100 CR + release; double completion pays once: first
  `paid=800`, second `ok=false paid=0`, purse unmoved) — but **delivery is
  unreachable in play**: F1 (HIGH).
- A5 — pass — in the shipped scene: convoy spawns at the accepting station
  (hauler + 1–2 fighters + 4 pod marks), route station → corridor midpoint →
  gate, the ambush fires on the midpoint, arrival closes the contract and pays;
  the hauler's death pays nothing, files −5 and drops the convoy's cargo. D5
  (credits move at the gate ring; the pin's words are "payout at destination
  station") and D13 (trigger radius = `CORRIDOR_DEPTH`) are tabled PROPOSED with
  reversals + ticks.
- A6 — pass — the active list is the profile's own `contracts` key
  (`player_profile.gd:1914/2195/2801`, the brief's pinned seam); it survives the
  dock/launch mount/unmount and a fresh-instance read-back, and a dead escort
  never resurrects from the save (`test_a6`).
- A7 — pass — the SERVICES deck replaces the placeholder (`service_panel(
  &"contracts")` is a real panel, not in `station_placeholder`; the deck build is
  `station.gd:1060`, the old placeholder line is gone from the diff); U3 headers +
  note, U4 cancel + confirm body, U5 escrow readout, U6 counter/chip, U7 staged
  row and both U8 states are verbatim (`test_a7_*`, five rows). One chrome detail
  LOW: F4.
- A8 — pass — `launch_panel.gd:281 destination_line()` reads the docked station's
  own sector name, no `HELIOS` anywhere (git diff is rider-scoped, 30 lines);
  `refinery.gd:130`'s example corrected comment-only (git diff: one comment line,
  `resource_seconds` unmoved, 259/10 → 26 s).

Deviations D1–D16 all carry reversal + tick and were checked as shipped; none
hides a law breach. The moved-row diff: B1's baseline PASS set vs R1's gate 1 —
1202 → 1223 rows, **zero non-s25 lines differ**, so the brief §8 list holds
(1224 = 1202 + the 22 s25 rows, one of them failing).

## Findings

| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| S25-B1/F1 | HIGH | `game/contract_registry.gd:718` + `game/game.gd` / `ui/screens/station.gd` | `ContractRegistry.complete()` has no production caller (rg over `vajb-orbit/`: tests only) — a haul/gather contract locks its goods at accept and can never be delivered (the only exit is the 100 CR cancel), and a hunt has no kill-credit hook into its `count`; the board's loop cannot be finished by a player. | S25-F1 |
| S25-B1/F2 | HIGH | `tests/test_s25_contracts.gd:938` | The gate reads **1223/1 twice** on fresh scratch stores: `test_a7_the_staged_row_the_escrow_and_the_cancel` stocks only `ingot_iron` while the accept demand is the band-rolled Haul stack (R1 probe, band 1492912: 40× `ingot_aluminium`) — B1's 1224/0 was a band whose roll matched; stock the rolled row's own item (as the sibling A7 test does) or pin the clock. | S25-F1 |
| S25-B1/F3 | MED | `game/contract_registry.gd:396,728` | Hunt's standing files a flat `+1` on completion, but 14 §2's row reads "+1 standing per kill extra" (5 kills ⇒ +5, or the kill channel's own +1 each with no completion bonus) — the shipped flat third value is untabled (D1–D16 silent). | S25-F1 |
| S25-B1/F4 | LOW | `ui/station/contracts_panel.gd:234-236` | U7 dims only the staged row's type label; the pin greys the whole row at `text_dim`, the type icon included (`_make_icon` sets no modulate). | → T-156 |
| S25-B1/F5 | LOW | `ui/station/contracts_panel.gd:343` | An accepted row stays on the seeded board, so the same job can be accepted twice within one band and two active records share one id (the cancel map then keeps only the last card's button). | → T-157 |

## Verified fixes

(none — first pass)

## Gate

`[SUMMARY] passed=1223 failed=1` — twice, fresh stores `/tmp/s25r1_gate1`,
`/tmp/s25r1_gate2`; the one FAIL row both times is F2's. Baseline
`[SUMMARY] passed=1202 failed=0` (B1's `/tmp/s25_baseline.log`). Negative control:
none needed — the failing row is the wave's own suite, and the PASS-set diff
above shows no other suite moved.

## Riders

T-138 (the deck placeholder), T-152 (the launch line) and T-154 (the refinery
comment) verified closed; their LOW_BACKLOG dispositions carry the evidence.
