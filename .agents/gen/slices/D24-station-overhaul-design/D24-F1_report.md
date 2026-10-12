---
slice: D24
worker: D24-F1
model: "mimo-v2.6-pro (session)"
status: informational
gate: "1330/0 ×2 byte-identical (staging/gate.py, post-cure)"
---

# D24-F1 report — the fixer pass (the four MED findings)

## Result

F1, F3, F4 and F5 cured at their named sites (docs only — no code, scene,
theme or asset file; no other change). Every touched value stays PROPOSED
with its reversal; no cure invents a number, each re-reads standing law
(T-178's live band, 01's SC(t)/L2, N48/N49 + §5.8, §2.3's layer-20 sink).
Line counts in the two indexed specs are kept identical, so
`staging/docs_index.py`'s section ranges stay exact without a re-run.

## Cures

**F1 — the %-of-list band miscount (`docs/gameplay/07_crafting.md:100-102`).**
The band read now measures against the standing live band **47.7–59.1 %**
(T-178) **only**; the sketch band 55–70 % is named as §3's own arithmetic,
not the check. Count corrected to **two rows inside** (REACTOR 51.1 %,
SHIELD 57.4 %) and two outside — RAIL REFIT 45.4 % below (flagged in-row
with its lever) and **DEEP SCANNER 67.9 % outside above**, now flagged on
that axis (in-row `⚠ over the 59.1 % ceiling`, mirroring RAIL REFIT's flag).
Cite: `docs/gameplay/07_crafting.md:101-105` (the read), `:99` (the flag).

**F3 — the exotic-deviation flags mispriced (`docs/gameplay/07_crafting.md:97-99`).**
Each row is now priced against its own labelled tier multiple per
`docs/gameplay/01_economy_core.md:311` (SC(t): 1 100/1 500/3 000/6 000) and
`:325-331` (L2, module ≈ 1–2 × SC(t)):
- SHIELD LATTICE — labelled tier **IV**, so 8 500 = **1.42 × SC(4)**, inside
  L2's 1–2 × band; the false 2.83 × SC(3) deviation claim is gone (`:97`).
- RAIL REFIT and DEEP SCANNER carry **no tier label** on their outputs
  (`computer, unique` / `computer`), so **no SC(t) multiple is derivable** —
  both rows say exactly that instead of pricing an arbitrary SC(3) multiple
  (`:98-99`).
All three values stay PROPOSED with the table's §3-sketch reversal.

**F4 — P53's foot cluster vs the pinned seats (`docs/design/STATION_HUB.md:2162`).**
Cured by **keeping the pinned seats** (the first offered option — superseding
N48/N49 would put owner-note-4 pins in escalation bucket 2/3, brief §9):
`SELL` / `SELL ALL RAW` / `CANCEL` keep the N48/N49 trade-column stack inside
`TradeBox` at §5.8's sizes (`SELL` 88 px, secondaries 56 px), and
**`SELL MARKED`** joins that stack at 56 px (§5.8's secondary size) directly
beneath `SELL`. The horizontal four-plate foot cluster is dropped pre-land;
P53's reversal cell names the dropped draft and the standing pins. No
§23.11 ledger row is owed — nothing is superseded. Cite:
`docs/design/STATION_HUB.md:2162` (law + reversal cells), vs
`docs/design/UI_SPEC.md:1415-1416` (N48/N49) and
`docs/design/STATION_HUB.md:829` (§5.8's 88 px `SELL`).

**F5 — the Cargo overlay's flight seat (`docs/design/UI_SPEC.md:1926,1933-1934`).**
The seat is now chosen, so "one law, both planes" holds: C (`cargo_toggle`)
pops the **same read-only overlay in both planes** (the owner's "same in
space"); in flight it seats **over the flight HUD on the layer-20 overlay
`CanvasLayer`** (§2.3's dialog layer, above the HUD's layer 10), topmost,
`ui_cancel` closing it as the one topmost step before the map-deck step
(P19's idiom; flight's own topmost-first poll, `game.gd:1040-1056`). Flight's
HUD `CargoBlock` (S39/T-170) stands as the always-on summary. A7 carries the
both-planes route and a reversal covering both halves (`:1933`); A8 names
one surface, both planes (`:1934`); the §18 preamble claims the flight seat
(`:1926-1927`).

## Deviations from the brief

- F4: picked "keep the pinned seats" over supersession. Reversal if the
  owner prefers the drafted foot cluster: re-lay the four 360×56 plates and
  add the §23.11 row superseding N48/N49's seats and §5.8's 88 px `SELL`,
  with that row named in P53's reversal.

## Evidence

- `python3 staging/gate.py --times 2` → `[SUMMARY] passed=1330 failed=0`,
  two runs byte-identical (docs-only no-regression proof, brief §8).
- Arithmetic re-checked against the standing tables: 4 876/8 500 = 57.4 %,
  3 578/7 000 = 51.1 % (both inside 47.7–59.1 %); 3 630/8 000 = 45.4 %
  (below); 7 740/11 400 = 67.9 % (above 59.1 %); 8 500/6 000 = 1.42 × SC(4).

## Files touched

- `docs/gameplay/07_crafting.md` — F1 (the band read) + F3 (rows 97-99's tier multiples)
- `docs/design/STATION_HUB.md` — F4 (P53's law + reversal cells)
- `docs/design/UI_SPEC.md` — F5 (§18 preamble, A7, A8)

## Follow-ups

None owed here. F2 was cured in review (disclosed); F6–F10 ticket at the
close-out ticketing pass per `D24-R1_review.md`.
