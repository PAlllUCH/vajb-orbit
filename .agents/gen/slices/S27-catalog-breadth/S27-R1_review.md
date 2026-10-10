---
slice: S27
reviewer: S27-R1
verdict: passed-with-followups
gate: "1275/0 (baseline) → 1291/4 (B1) → 1298/1 (B2, the §8-listed S19 seal) → 1299/0 ×2 (R1, fresh scratch stores)"
---

# S27-R1 review

## Acceptance list
- A1 — pass — the 7 rows (`module_catalog.gd:234-261,335-352`) roll under §1/§3/§4: my own 5k seeded probe (seed 424242, mixed bases × rarities) reads 0 band/family/suffix-count violations, Magic 1/1, Rare 2/2, suffix hit-table flat (echoes 471… whale 550); the re-cut seeded pins re-derive true for all four cases (probe `seed(20260922)`: magic/surefire+echoes, deep_hold+embers, rapid+echoes, spry+leeches) — nothing weakened (F1 below still stands on weapons).
- A2 — pass — every live suffix names a `consumer` (`module_catalog.gd:270-353`); the §20 seam consumes (`affixes.gd:126-148`) and B2's flight sites fire (verified below); the "displayed, never applied" note is gone (`module_catalog.gd:936-939`). F2 grades Pyre's flight gate.
- A3 — pass — 15 `<base>_mk2` rows (t2×6/t3×3/t4×6); I re-derived every price from the live table: `round(base_cost × SC(t)/SC(bt))` clamped into 1–2 × SC(t) reproduces all 15 exactly (worst cases clamped: c_nexus 12 800→12 000, b_fold 13 600→12 000); headline ×1.15 on every family; `sale_pool` carries them one tier up (`auction.gd:515-520`, pools t4 = 6 ids).
- A4 — pass — 06 §3-format tables for `interceptor/turret/sibelon/boss` (`loot_tables.gd:115-168`), grade-clean, caches last; my 20k EV probe: 16.5 / 68.4 / 91.2 / 1 545.7 CR, empty 24.1 / 24.1 / 19.5 / 0 %; `TABLES` 10 kinds, `patrol`/`apex`/`""` still table-less (`test_engine2_loot.gd:434-439`).
- A5 — pass — 10 §3.1 verbatim (9 hull recipes ↔ the SHIPS ladder, identical line for line); module recipes by the shape rule on live values (probe: s_light 2×25 + 12×18 = 266 + 280 labour = 546); queue commit/refund/one-at-a-time/one-session/persist (`shipyard.gd:241-299`, store persisted `player_profile.gd:1923-1943`); scrap 50 % floor-to-hold (`shipyard_panel.gd:1712-1721`); BUILD/QUEUE/SCRAP views are containers + tokens, no coordinate draws. F3 grades the band drift.
- A6 — pass — `tier_pool(4)` non-empty (6 variants, probe), `_reserved_tier` clamps to `MAX_MODULE_TIER` 4 (`auction.gd:423-427`), tier-4 prices in the L2 band 6 000–12 000; closes T-153.
- A7 — pass — every new value tabled with reversal + K1–K3 in both reports; the five moved rows are exactly §8's list, and I re-derived each pin against §5's extract, not against B1's values (A1 pins above; no-table list, TABLES 10, and the four rebuilt seeded cases all match the extract's law).

## Flight re-measurements (B2, in play)
- Echoes — `weapons.gd:_consume_ammo_at:2261-2265` counts each release and returns before the spend on every 5th — passage-to-payoff verified live in the gate (`test_a2_echoes_refunds_a_shot_in_flight`: 96→95 of 100 after 5 releases).
- Long Watch — `game.gd:_update_lock:1836` reads `lock_channel_seconds(_launch_summary, LOCK_CHANNEL)`; the in-flight row times 1.3 s channeling / 3.3 s land vs the plain 1.2 s.
- Pyre — `game.gd:_on_npc_died:2690` → `_detonate_pyre_ring:2699-2713` charges every `npc_ship` in `PYRE_RING_RADIUS`, victim excluded — but see F2: the below-quarter gate is vacuous in flight.
- `ShipyardScript.note_flight(_profile())` at `game.gd:511` on the launch branch only (a crossing is explicitly exempt, `game.gd:508-516`); one in-space session per launch, queue read-only of the counter.

## Findings
| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| S27-B1/F1 | MED | `module_catalog.gd:1064-1074` | A Rare weapon can roll two prefixes of the **same property** — the pool is a family pool (`w_*` = keen,rapid,frugal,dense,quickwarm,farflung) and the roll dedupes picked **ids**, not properties, while §3's extract is law: "the two prefixes of a Rare must be **different properties**". Probe: 282/2000 rare `w_laser` rolls carry a same-stat pair (first observed `dense`+`keen`, both `damage_add`). Fix: dedupe by `stat` inside `roll_prefixes` (one pool-walk) plus a suite row; no other family can pair today (`lightened` vs `layered` differ). | S27-F1 |
| S27-B2/F2 | MED | `game.gd:2699-2713` | The Pyre's below-quarter gate never gates in flight: `hull_fraction` reads the **victim at the killing blow**, i.e. 0.0 always, so `pyre_ring_damage` returns 50 on *every* kill — one proof it is vacuous (probe: any kill fires; the seam's threshold bounds only direct calls). B2 disclosed it (Deviation 4) and the wave's suite codifies it (`test_s27_catalog.gd:72-74`), but 15 §4's pinned line needs the pre-blow share; a one-line "hull fraction at last hit" store in `NpcShip._take_damage` answers it. `npc_ship.gd` is in no wave worker set — **bucket 2**: the developer session re-opens the set or rules 0.0 the shipped reading. | developer |
| S27-B2/F3 | LOW | `shipyard.gd` + 10 §3.1 | Post-S28 ore values moved the build economy below the doc's own band: my re-derivation reads the 9 hull builds at **47.7–59.1 %** of list (fighter 4 609/9 000, vanguard 8 934/18 000, destroyer 36 820/72 000), materials 15.2–19.3 % against §3.1's 20–30 % band — the pre-S28 worked example read 57 %. Behaviour-safe (building stays the saving), but the doc band is now false on the live ladder. 10 §4 names the lever (labour %, never list prices) — owner/developer pass. → ticketed **T-178** | — |

Rejected reads, for the record: `layered`/`farflung` stored-but-unread is the disclosed Overflowing precedent, not a defect; `Auction._shared` reuse and Prefixes of armour's single-source pool (Rare rolls one prefix) already hold by §20's law. The S19 seal re-pin sits in the tree (`test_s19_quadrants.gd:131`, `8c9f0707…` = live `weapons.gd`) despite B2's report saying "NOT applied" — the pin is §8-listed and gate-passes, provenance grey but harmless; noted, not graded.

## PYRE_RING_RADIUS 240.0 — RATIFIED
No doc reach; R1's probe keeps the ring melee-local (three NPC hulls at ring distance in the flight row) and the Maw arena reads ≳1 500 u — 240.0 seats the perk as a kill-bonus, not an area denial. Owner tick K2's list carries the reversal (delete constant + radius test).

## Gate
- Pre-wave baseline `s27_start` **1275/0** (B1's report; not re-measurable here — the tree is post-wave).
- R1: **1299/0**, twice on fresh scratch stores, byte-identical `[SUMMARY]`s. Chain: 1275 → 1291/4 (B1, the four §8 rows) → 1298/1 (B2, the §8-listed S19 seal red) → 1299/0 here, the seal re-pinned to the finished tree by the §8-listed S22 procedure. The only tree delta from B2's own read is that seal row, re-pinned and now passing.
- Exit noise, pre-existing and not S27's: the runner prints leaked-RID allocations at exit (the same 5 lines on every whole-suite run, the `test_s19_quadrants` control included), on top of §9's tolerated `data.tree` line. No new `SCRIPT ERROR` in the captured logs.
- R1's own probes live at `tests/probe_r1_s27.gd` (5k affix law + the four seeded pins re-derivation + 20k loot EV + hull/module recipe totals); keep for the next catalog wave's recap.

## Verified fixes
No fixer ran before this review — the findings stand as filed; after F1's fix, verify here with a stat-dedupe suite row and the 5k probe re-run.

## Backlog + CONTRACTS (this review's writes)
- **T-153** marked CLOSED (A6 above); **T-178** filed (F3); next free ticket **T-179**.
- CONTRACTS §20: the S27 block (the seven rows with their bands, the three flight seams with the ratified 240.0, the variant price law, T-153's closure, the shipyard's §3 contract, the four loot kinds); §9: the S27 measured block; §10: **v0.56**.
- The fixer (F1 only) reads this review's F1 row; F2 needs a developer session. LOW F3 rides T-178.
