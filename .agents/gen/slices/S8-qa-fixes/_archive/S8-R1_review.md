---
slice: S8
reviewer: S8-R1
verdict: passed-with-followups
gate: "753/0 → 770/0 (twice on fresh scratch stores; verify --baseline s8_start problems: [])"
---

# S8-R1 review — QA playtest fixes

Diffed against `docs/CONTRACTS.md` §21 (the wave's pin) plus §17/§15/§16/§9 and
`docs/gameplay/05_exchange.md` §9 — never against the brief. The audited input is the
independent playtest `.agents/gen/slices/S7-affix-application/S7_QA_playtest_review_2026-09-24.md`.
Every acceptance criterion was re-measured on the shipped tree by re-running the builders'
own probes/suites byte-identically (plus one reviewer probe for AC4's second half). **No
HIGH, no MED.** Tree: `0a97854` (`8c91716` baseline).

## Findings
| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| F1 | LOW | `game/repairs.gd:64-65,89-90,107-108` | The repair transaction still caps at the station base row (`1000/600`) while the panes print `ShipFit.resolve`'s pair, so a plated hull repaired at the station files `1000/600` and the pane beside it reads `hull=1000 / 1250`, `missing=250 HULL · 200 SHIELD`, `fee=0 CR`. Staged bucket 2 in §21; filed as `L168`. | next file-owning wave |
| F2 | LOW | `game/game.gd:_seed_ammo/_auto_load_ammo/_file_ammo_report` | A launched same-family battery seeds every cell from the one pack (twin `[300,300]`, triple `[300,300,300]`; R1 launch probe), the hold drawn once; not a store double-draw and P2-A's one-laser `300` pin holds, but the flight total exceeds the pack and each slot's spend writes back to it. §21 accepts the per-cell model; filed as `L169`. | owner/spec |
| F3 | LOW | `tests/test_s8_qa_fixes.gd:314-330` | The AC8 row asserts `--check-only --script` exit 0, which proves parse only: measured, `weapons.gd` still carries one warning and that command exits 0 (`--debug` prints it, exit still 0). A warning-count regression would slip the suite; AC8's proof is Q3's lint probe and this review's A/B. Filed as `L170`. | next file-owning wave |
| F4 | LOW | `game/weapons.gd:607` | `_compose_racks`'s `racks` local still shadows `racks()` — the file's one remaining warning, a different class from L163's `position` set, left under the no-unrelated-rename rule. Filed as `L171`. | next file-owning wave |

No finding is HIGH or MED, so no fixer pass is owed.

## AC re-measurement (W8 method)
- **AC1 H1 — passed.** `test_s8_launch_ammo` 8/8 and the Q0 launch probe re-run: QA fit `[w_cannon,w_railgun,w_mining]` → strip `600 ROUNDS ACROSS 3 WEAPONS`, flight slots/`_ammo_seed` `[300,300,0]`, the store's two stocked packs sum 600; real-frame fire: cannon-only stocked 2 shots/1 projectile/`300→298`, drained 0 shots/1 dry, QA fit with the cannon drained fires the **railgun** slot only (`ammo [0,298,0]`).
- **AC2 H2 — passed.** Cell-for-cell on the QA fit and two hole-y fits, one W row per fitted cell, no armour in a W row; ordinals in the barrel-position space (`[[0],[1],[2]]→[1,2,0]`, `{}`→`[1,1,0]` trailing rack, tool-first `[0,1]`).
- **AC3 M4 — passed.** Footer and Repairs both read `1250 / 1250`, `800 / 800` on the plated fit; damaged `1000 / 1250`, `700 / 800`, `missing 250 HULL · 100 SHIELD`; a stale heavier reading clamps to `1000 / 1000`, `600 / 600`.
- **AC4 M1 — passed.** Ram probe refusal count **0** (Q0 baseline 32), 2 fragments spawn; reviewer `probe_s8_r1_fragment_shape`: rock shape at radius 42.0, the fragment's `Shape` absent at the cleave's own call, then all 3 present, `disabled=false`, radius 24.0 = the placed `world_radius` on the next step.
- **AC5 M2 — passed.** Strip `SELL 1 CHROMIUM ORE — GROSS 25 · FEE 10 · YOU GET 15`, `SOLD · 1 CHROMIUM ORE · +15 CR`; no `MINERAL_CHROMIUM` anywhere in sale copy (`_reason_text` carries none either).
- **AC6 M3 — passed.** Preview `paid=15`; demand forced 1.0 → 0.6 between preview and press; credits 6001 → 6016 (credited 15 = the shown `YOU GET`); the default `-1` path still pays the live quote (suite rows).
- **AC7 copy — passed.** `Cannon MkI` the one spelling (zero `Mk1`/`MK1` in `ui/`/`game/`); `860 u OUT OF RANGE`; `1 CONVERSION` at one, plural at 0/2; `NEXT RESTOCK` (`auction.gd` untouched) and `REFINERY ALL` (`refinery_panel.tscn` untouched) byte-identical to `8c91716`; `CONFIRM_FORMAT`'s shape unchanged.
- **AC8 ledgers — passed as a floor.** A/B of the Q3 lint instrument on `8c91716` vs `0a97854`: `weapons.gd` 34 → 1, `module_catalog.gd` 3 → 0, `projectile.gd` 3 → 0; renames/annotations only, gate green.
- **AC9 gate — passed.** `770/0` twice on fresh `XDG_DATA_HOME` stores; `verify --baseline s8_start --forbidden project.godot 18_engine_spec.md 04_refinery.md --tests` → `problems: []`, both expected reports present; live `profile.cfg` `540117dc…` / `economy_log.txt` `77f4f61a…` byte-identical throughout.
- **AC10 O1/O2 — passed.** Armory drag commits through the three handlers (`[[0]]` → `[[0,1]]`), FITTING declares zero handlers; the UX call is dispositioned to the owner (§21), no code guessed.
- **AC11 O3 — passed as dispositioned.** Q0's premise is broken (shipped masks never resolve player→NPC contact; probe `contact=false`, `offer=93.7895` when widened); §21 writes no factor and S8 ships no O3 change.

## QA finding accounting (§21 — none silently dropped)
- **HIGH** H1 fixed (gate + spend + strip); H2 fixed (rack ordinal; the payload and `W3 · Light Plate` parts closed by Q0's measurements).
- **MED** M1 fixed (deferral, 0 refusals); M2 fixed; M3 fixed; M4 fixed (panes); M5/M6 staged → designer items 9–12.
- **LOW** `1 CONVERSIONS` fixed; `860 m` fixed; engine warnings fixed (`L163` closes); `REFINERY ALL`, `NEXT RESTOCK`, the refinery hide → owner ticks; the "three spellings", the d7r1 probe and the stale log → not reproduced / stale.
- **Composition/vision + tooling appendix** → designer items 9–12 / owner note; **O1–O6** as §21's table.

## Gate
- Baseline `753/0` (`8c91716`) → **`770/0`** twice on fresh scratch stores; `770 = 753 + 8 + 9`. The green run's only error lines are the pre-existing ones (`data.tree` null, `test_weapon_fx_f4.gd:178`'s freed `guns` = L61, the resources-at-exit warning).
- Negative control: the A/B worktree on `8c91716` reproduced the pre-wave counts (module_catalog 3, projectile 3, the 34-row `weapons.gd` block); the Q0 ram probe re-run reads 0 refusals.
- `verify_wave.py verify --baseline s8_start … --tests`: `problems: []`, no forbidden hit, no D11 file in S8's diff beyond the parallel lane's own attributed adds.

## Owner ticks (§21, unchanged)
O1/O2's UX call; O3's site + symptom + mask; the trailing-rack duplicate read; `REFINE ALL` vs the pinned `REFINERY ALL`; `1 CONVERSION`; the refinery hide; the live-profile restore (its fit is three cannons, `batteries = {}`); and the twin battery's 2× magazine (`L169`).
