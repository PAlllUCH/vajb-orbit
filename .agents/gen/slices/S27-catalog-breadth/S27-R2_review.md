---
slice: S27
reviewer: S27-R2     # post-fix (second) review, on the final tree
verdict: clean       # clean | blocked (HIGH remains) | passed-with-followups
gate: "1299/0 (R1) → 1300/0 ×2 (F1, reported) → 1300/0 (R2, fresh scratch store)"
---

# S27-R2 review — independent pass on the final tree (post-F1)

Scope: R1's two MEDs must be genuinely cured, A1–A7 re-graded on the final tree,
regressions hunted in the three files the fixer touched (`module_catalog.gd`,
`game.gd`, `npc_ship.gd`). Law graded against: the brief's §5 extract (the
2026-09-27 P3 blocks + 15 §1/§3/§4 + 10 §3 + 01's L2 bands), never a report.
My probes: `tests/probe_r2_s27.gd` (data lane, seed 20261010) and
`tests/probe_r2_s27_flight.tscn` (live flight) — run on a fresh scratch store.

## R1's MED cures — verified, not weakened

- **S27-B1/F1 (prefix dedupe) — cured.** `roll_prefixes`
  (`module_catalog.gd:1066-1082`) drops every remaining pool row whose `stat`
  equals the just-picked row's, one pool-walk per pick. My own probe: 9 weapon
  bases × 3 000 Rare rolls (27 000, seed 20261010) — **0 same-stat pairs**,
  count always 2 (the 4 distinct weapon properties allow it); 12 distinct stat
  pairs observed, so the dedupe is active, not vacuous. Single-row families
  (engines/power/boosters/utility) still yield exactly 1 for a Rare over 400
  rolls each, and a Magic still yields exactly 1 prefix/1 suffix — the count
  law `min(affixes, pool)` and the Magic path both survived the fix.
- **S27-B2/F2 (Pyre gate) — cured, proven in live flight.**
  `npc_ship.gd:370-388`: `_pre_hit_hull_fraction = hull_fraction()` sits after
  the no-hit early returns and **before** shield absorption/`set_hull`, default
  `1.0` (`npc_ship.gd:151`); accessor at `:1133`. Live probe (real `game.tscn`
  instance, real `NpcShip` hulls, victim wired to `game._on_npc_died` — no
  stub): a full-hull one-shot records pre-hit **1.0** and the neighbor hull
  stays 950/950 (**no ring**); a chip-to-10 % finish records **0.10** before the
  lethal blow and the ring charges the neighbor **exactly 50**; without the
  perk the same finish pays nothing. `despawn()` frees deferred
  (`npc_ship.gd:439-451`), so the handler reads a live victim. Both verdicts
  `failed=0`.

## Acceptance list (re-measured on the final tree)

- A1 — pass — my 5 000-roll mixed probe (8 bases + all 15 variants ×
  common/magic/rare): 0 family leaks, 0 band misses, 0 count violations; suffix
  pools respected incl. faction bounds. Note: armour's pool is now TWO rows
  (`lightened`+`layered`, distinct stats), so a Rare armour correctly rolls 2
  prefixes per §1/§3 — B1's "armour's single row yields one" wording is stale,
  the behavior is the law's.
- A2 — pass — all three consumers live (`affixes.gd:126-148`) and firing at
  their seams (`weapons.gd:2261-2265`, `game.gd:1836`, `game.gd:2690/2701`);
  my live-flight probe confirms Pyre both ways; Echoes and Long Watch rows in
  `test_s27_catalog.gd:557-593` assert real deltas that can fail (checked for
  the silent-abort class — none: reads use `get`/typed members, no bare
  awaits; `_open_game()==null` early-returns are the project's suite guard
  convention, and the same scene loads green in the same run).
- A3 — pass — all 15 variants re-derived exactly: `clamp(round(base_cost ×
  SC(t)/SC(bt)), SC(t), 2×SC(t))` (0 misses), headline ×1.15 exact (0 misses),
  each in `sale_pool` one tier up (0 misses).
- A4 — pass — my 20k EV probe: interceptor 16.6 / turret 69.2 / sibelon 92.0 /
  boss 1547.6 CR, empty 23.7/23.7/19.3/0.0 % — matches R1's within sampling
  noise; `TABLES` carries the 4 kinds, `patrol`/`apex`/`""` still table-less.
- A5 — pass — module shape rule re-derived mechanically for all 48 buildable
  ids (0 deviations); 9 hull recipes re-derived live at 47.7–59.0 % of the 10
  §3.1 list (confirming T-178, already ticketed — doc drift, not code); queue
  semantics exercised on a scratch profile: commit at queue (hold+credits),
  one-at-a-time refused, not-ready before flight, ready after one
  `note_flight`, `collect` grants the hull and clears, cancel refused after
  completion with no refund leak; scrap = 50 % floor per material. Store
  persisted under `shipyard` (`player_profile.gd:1919-1943`).
- A6 — pass — `tier_pool(4)` = the 6 tier-4 variants, priced 9 000–12 000
  (inside 01's L2 band 6 000–12 000); a tier-4 sector's `_reserved_tier`
  returns 4 (`auction.gd:423-427`, probe over the sector registry). T-153
  stays closed.
- A7 — pass — the §8 moved set is exactly six rows: engine2_loot's no-table
  list, s6_poi_loot's skip + `TABLES.size()` 6→10, s3_instances' four seeded
  outcomes, and both S19 seals. I re-derived each pin against §5's extract
  (patrol/apex/"" table-less per 18 §5; the 10 = 5 slice-2 + hunter + 4 A4;
  the four re-derived suffix outcomes still pin exact seeded results, nothing
  weakened); every other suite row is green. K1–K3 tabled with reversals in
  both reports.

## S19 seals — checked against the live files

`sha256sum` on the final tree matches all four pins in
`test_s19_quadrants.gd:94-137`: `npc_ship.gd` `754a261f…` ✓,
`weapons.gd` `8c9f0707…` ✓, `npc_brain.gd` `cd867f9f…` ✓, `damage.gd`
`5cabf3d9…` ✓. Both S27 re-pins carry disclosure comments naming their worker.

## Findings

| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| S27-R2/F1 | LOW | `game.gd:_detonate_pyre_ring` | Emergent cascade, unruled: a ring **kill** is itself a below-quarter kill, so in a dense spawn one Pyre kill can chain-detonate rings from each new victim's position (terminates — victims are excluded and dead hulls don't refire — but N kills can pay N×50 across the swarm). Follows 15 §4's literal text; only the interaction density is unruled. → ticketed **T-179** | owner (tick with K2's reversal list) |

No HIGH, no MED. Rejected reads, for the record: `layered`'s `hull_add` is a
live aggregated stat (same stat the armour bases carry), so "stored but
unread" (B1 Deviation 6, echoed by R1) overstates the staging — only
`farflung`'s `range_mult` has no reader today; harmless, no row moved. The
suite's `_open_game()==null` guards are pre-existing convention, and the same
run proves the scene loads. R1's F3 band numbers re-confirmed (47.7–59.0 % vs
R1's 47.7–59.1 % — rounding only); T-178 stands.

## Verified fixes

- S27-B1/F1 — fixed, verified by my 27k-roll seeded probe + the suite's 5k row.
- S27-B2/F2 — fixed, verified by my live-flight probe (real scene, real
  NpcShips): one-shot silent, below-quarter finish fires 50.

## Gate

`[SUMMARY] passed=1300 failed=0` (R2, fresh scratch `XDG_DATA_HOME`,
`--quit-after 2400`) — matches F1's two hermetic runs. Growth chain 1275 →
1291/4 → 1298/1 → 1299/0 → 1300/0; +25 rows all in `test_s27_catalog.gd`,
moved rows exactly §8's six. No new `SCRIPT ERROR` in the captured log; exit
noise is the pre-existing leaked-RID lines.

## CONTRACTS

No edit owed: §20's S27 block and §9's S27 block state the post-fix reading
(`roll_prefixes` dedupes by `stat`, count `min(affixes, pool)`, the Pyre gate
reading `pre_hit_hull_fraction()` before the blow) and every claim re-verified
true on the final tree; v0.57 already records F1's cure. Next free ticket
**T-179** (filed this review); LOW_BACKLOG updated.
