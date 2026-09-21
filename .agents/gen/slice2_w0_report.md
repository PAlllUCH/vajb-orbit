# Slice 2 — W0 doc-check report (2026-09-21)

Worker: W0 (doc pass, no code). Brief: `.agents/gen/slice2_task.md` W0 section +
Global rules, with the orchestrator addendum of 2026-09-21. Spec read in order:
`AGENTS.md`, `docs/CONTRACTS.md`, `docs/gameplay/18_engine_spec.md` §2.1/§4/§5/§7/§12/
§13/§14, then `docs/design/IMPLEMENTATION_PLAN.md` §9.9 and the companion docs.

No headless run was performed (doc-only pass, per brief); the test total was not
re-measured. No asset path was read or swept (addendum ruling two). Every file in
this pass was written with the `write`/`edit` tools, never through the shell.

## Files changed

| File | Bytes before | Bytes after | Change |
|---|---:|---:|---|
| `docs/design/IMPLEMENTATION_PLAN.md` | 47 607 | 49 163 | +1 556 |

Nothing else in the tree was touched by this pass (`git status` shows only the
orchestrator's own `.agents/gen/_dispatch/*` files besides this one edit).
Companion docs read but left byte-identical: `06_loot_drops.md` (6 486 B),
`08_ship_classes.md` (8 491 B), `09_ship_slots_modules.md` (13 562 B),
`11_galactic_map.md` (7 281 B), `13_heat_bounty.md` (4 461 B),
`14_station_services.md` (7 408 B).

## 1. Slice 2 in `IMPLEMENTATION_PLAN.md` §9.9 — appended

**Before:** §9.9 (the last section, now lines 412–443) recorded decisions 1–7, the
§3.7/§3.9/§3.10 amendments, the retirements, the wave-1 companion-doc bullet, the
slice-1 interface note, the slice-0 paragraph and the 2026-09-21 free-services
ruling. It had **no slice-2 line**, and its own intro (line 414) states the
2026-09-20 rulings extend the section with slice 0 and the amended slice 2 scope,
"transcribed by the slice-0/slice-2 doc-check workers".

**After:** a slice-2 paragraph and one companion-amendment bullet, inserted
between the slice-0 paragraph (line 436) and the 2026-09-21 owner ruling (now line
442), so the two 2026-09-20 build-slice records sit together and the newest ruling
stays last. Both are transcriptions, and **no number was added**:

- the paragraph is `18_engine_spec.md` §14 slice 2 (lines 570–581) verbatim in
  substance — deliverable, the seven new files, `PlayerState` + HUD amendments
  per §12/§10, and the five **2026-09-20 amendments** (power-draw hooks §4.4,
  first seeker §4.6, the `ctx` pipeline calling `impact.gd` §4.2 items 5–8,
  human pirates AND alien swarmers, `cm_chaff`/`cm_flare` in W4's tables, W5's
  pools bars + radial speedometer + lock ring + ghost blips §10). The only
  additions to that text are its attributions: "the six archetypes of §5 on one
  brain" (§2 decision 5, §5) and "ruling 24's alien `swarmer`" (§2.1) — both
  name-bearing pointers, no values;
- the bullet records the four companion-doc amendments of §12 items 7–10 and
  where each landed (09 §3.1 + §3.5, 14, 06 §3.1, 11 §1), including that the
  refuel/recharge rows are free and instant per the 2026-09-21 owner ruling.

## 2. Companion amendments verified against §12 items 7–10

Verification only — nothing in these docs was re-done or re-worded.

| §12 item | Required | Found | Status |
|---|---|---|---|
| 7a | `09` §3.1 weapon table gains a **power** column (energy draw rates, §4.4) | 09 §3.1 (lines 64–96): table keeps its fitting-budget `Draw` column; the 2026-09-20 amendment block states the rates as prose — "rates 6/10/5 E/s in the §13 table" | content present, column not added — see D2 |
| 7b | `09` §3.5 booster rows gain their fuel burns | 09 §3.5 lines 144–145: `b_afterburner` "burns BOOST_FUEL 3.0/s while active (2026-09-20)"; `b_fold` "burns DASH_FUEL 25/burst … (2026-09-20 rename)" | matches §13 (`BOOST_FUEL` 3.0/s, `DASH_FUEL` 25/burst) |
| 8 | `14_station_services.md` §2: refuel (CR per fuel point) + recharge rows | 14 §1's service-deck table line 20: "Refuel / recharge … (2026-09-20: every station; free and instant, no CR charged; owner ruling 2026-09-21)". §2 is the contracts board and has no refuel row | content present, section differs from the pointer, and the CR-rate half is correctly superseded — see D1 |
| 9 | `06_loot_drops.md`: `cm_chaff` + `cm_flare` enter the pirate tables | 06 §3.1 fighter table lines 50–51 (`cm_chaff` 0.15, `cm_flare` 0.15) + the 2026-09-20 amendment block lines 56–62 quoting §4.6 (3 ghosts / 3 s; 450 u lures; freighter/corvette/dreadnought untouched) | present; no change needed |
| 10 | `11_galactic_map.md` §1 hazard column: nebula gas cloud rows + the radar-degradation rule | 11 §1 lines 34–40: a nebula paragraph (0–2 per sector, registry row, STYLE_BIBLE §7.2 wash, passive tags refresh slowly, lock channel cannot complete while LOS crosses the cloud) | content present as a paragraph, not as a hazard column — see D3 |

Also confirmed, as the brief's item 2 asks: **09 §3.1 carries the `Family` and
`Shield rule` columns** wave-1 W0 added (header `| Module | Tier | Draw | Family |
Shield rule | Effect | Cost |`, rows for all six weapons plus the `tool` note for
`w_mining`), and the railgun's "ignores 50 % armour" line is retired in 09
§3.1 lines 85–87 per item 2. 08 §2 carries item 1's handling reference (§13 is
named as the single source of per-class handling and hull mass) and item 11's
speed-table-v2 reference with the pending owner tick — both already applied.

**Item 3 verdict:** for `06` the loot tables need **no doc changes**; nothing
slice-2 needs is missing from `08`, `09` or `06`. One slice-2 need is missing
from `13` (D4) and is reported, not applied — see the file-set note below.

## Discrepancies (reported only; the file was never re-done, per the brief)

- **D1 — LOW/MED, placement.** §12 item 8 points at `14_station_services.md` §2;
  the refuel/recharge rows landed in 14 **§1**'s service-deck table (line 20),
  and §2 is the contracts board. The content is right and the free-and-instant
  ruling is recorded in both 14 §1 and `IMPLEMENTATION_PLAN` §9.9 (line 438); the
  section pointer is what drifted. Not fixed: `14` is outside this pass's file
  set, and it is a pointer, not a missing transcription.
- **D2 — LOW.** §12 item 7 asks for a *power column*; 09 §3.1 instead carries the
  rates in its 2026-09-20 amendment block ("6/10/5 E/s"), which matches §13
  exactly (laser 6 · plasma 10 · mining 5 · kinetics 0). Not fixed: adding a
  column would restate §13's numbers in a second place, and the brief forbids
  redoing this amendment. W1's `weapons.gd` table takes the rates from §4.1/§13
  either way, so nothing in slice 2 depends on the column existing.
- **D3 — LOW.** §12 item 10 says "hazard column"; 11 §1's table has no hazard
  column and the nebula rule landed as a prose paragraph after 11 §1's
  one-arena-size note. Content and the §8 cross-reference are present. Not fixed:
  `11` is outside this pass's file set.
- **D4 — MED, doc gap a slice-2 worker will hit.** The per-sector NPC count band
  — "S1 0–1 · S2 1–2 · S3 2–3 · S4 3–4 · S5 3–5 · S6 4–6 · S7 6–8, patrols only in
  owned space, one convoy per inhabited sector" — exists **only** in
  `18_engine_spec.md` §13 (lines 537–539), which attributes it to the "13 §4
  density shape". `13_heat_bounty.md` §4 (lines 59–60) carries no counts, only
  "their density multiplies by tier band (S1 rare, S7 swarming)", and
  `11_galactic_map.md` §3 (line 103) points pirates back at "per 13 §4" — the
  pointer chain is circular, so a coder following it finds no numbers. The W3 pin
  (`slice2_task.md`, pinned interface 7) sends `NpcRegistry` to "the 13 §4 density
  shape", so the transcription into 13 §4 is what slice 2 wants: one bullet
  restating §13's seven bands plus the two qualifiers, cited to §13, adding no new
  number. **Not applied:** the dispatch file set for this pass is
  `docs/design/IMPLEMENTATION_PLAN.md` + `docs/gameplay/06, 08, 09` (the brief's
  item 3 names 08/09/06/13), so the edit is deferred to the orchestrator/W6 rather
  than made outside the set. No value was guessed.
- **D5 — LOW, spec vs shipped tree.** `18_engine_spec.md` §11 (line 386, "Add:
  … `consume_fuel_cell` = C") and §4.4 (line 212, "the `consume_fuel_cell` action
  (C, §11)") still bind the fuel-cell action to **C**, but the shipped input map
  binds `consume_fuel_cell` to **R** (`project.godot` keycode 82) and keeps
  `cargo_toggle` on **C** (keycode 67), per the 2026-09-21 owner ruling (addendum
  ruling three). Recorded only: 18 is the owner-locked spec and is outside this
  pass's file set; slice-2 workers should take the shipped binding, not §11's
  letter.
- **Observation (data, not a defect).** `06` §3.1's amendment is permissive about
  the swarmers ("**may** enter the swarmers' table (slice-2 W3) at the same
  weight"), so no swarmer table transcription is owed in 06 — that choice stays
  with W3/W4. The same amendment already declares 06's expected-haul figures stale
  and defers the re-check to the wave report; measured from the amended table for
  that report: line sum 0.55+0.30+0.35+0.20+0.15+0.15 = 1.70 raw lines, expected
  units ≈ 0.55·1.5 + 0.30 + 0.35·1.5 + 0.20 + 0.15 + 0.15 = **2.15 items**, and the
  independent-line empty-kill rate is 0.45·0.70·0.65·0.80·0.85·0.85 = **≈11.8 %**
  against the stated "≈ 17 %" (which is the four-line table's 16.4 %, so the
  amendment is what made it stale) and "≈ 1.1 items" (which matches neither the
  four-line table's 1.85 nor the six-line 2.15 — pre-existing drift). Not edited:
  the amendment explicitly hands the re-check to the wave report.

## Deviations

- None from the brief's items 1 and 2. Item 3's "add the missing transcription"
  clause was not exercised for `13` because the dispatch addendum restricts this
  pass to `06/08/09` + the plan; D4 carries the exact transcription text and its
  source so the orchestrator can place it with no research.
- `tools/` and `tests/` were not touched (no probe is needed for a doc pass), and
  no file outside the named set was written.
