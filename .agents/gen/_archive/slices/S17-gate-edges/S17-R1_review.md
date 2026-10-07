---
slice: S17
reviewer: S17-R1
verdict: passed-with-followups
gate: "866/0 → 877/0"
---

# S17-R1 review

Findings are diffed against `docs/gameplay/11_galactic_map.md` §6 (the pin) and
§2.1/§2.2/§5, never against the brief. Every AC was re-measured on the shipped
tree by an independent probe, `vajb-orbit/tools/r1_s17_ac_replay.gd` (50 rows,
`failures=0`), which re-derives its expected positions from 11 §2.3's spine
order and the 10 000 u arena geometry and never calls `_edge_reach` /
`_gate_bearing`.

## Findings
| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| F1 | LOW | `vajb-orbit/game/sector.gd:97` | `BEACON_GATE_OFFSET`'s comment still reads "this far outside the ring" — the ring placement is retired, so the phrase is stale (no code effect; brief §2 rule 3 kept the comment out of scope). | Next `sector.gd` owner |
| F2 | LOW | `staging/mockup/station_mockup.py:284,369` | The station mockup still labels the gate arrow "GATE 900 u (`_gate_bearing(dest)`, sector.gd:96,581)" — the value is retired and both line numbers moved (now `:584-585`). | Next mockup owner |
| F3 | LOW | `vajb-orbit/tests/test_s17_gate_edges.gd` | The wave's new suite ships with no `.uid` (same class as L205/L211/L214); the headless gate never writes one. | Wave close-out / editor scan |
| F4 | LOW | `vajb-orbit/tests/test_s17_gate_edges.gd:48-49,270-273` | The suite hard-pins the two forbidden files' pre-wave MD5s, so the next legitimate edit of `gate.gd` or `sector_registry.gd` trips `ac6` with a hash mismatch instead of a broken contract. Reversal: drop the two asserts (B1 reported this as its own deviation). | Next owner of either file |
| F5 | LOW | `vajb-orbit/tests/headless_runner.gd:87-94` | `--suite=` reads `OS.get_cmdline_user_args()`, so it only sees args **after `--`**; a flag placed before the separator is silently ignored and the whole gate runs. B1's report's "`--suite=` did not filter on this host" is a mis-invocation, not a defect. Extends L95. | Next runner owner |

No HIGH, no MED: no unlisted row changed, no forbidden file moved, and no AC
number is contradicted by the shipped code. A fixer pass is not required.

## ACs re-measured (independent of B1's suite)
- **AC1** — 12 gates over the seven registry rows, each exactly on its link's
  bearing ray at **4200.0 u** = 5000 − `FIELD_EDGE_MARGIN` 800; cardinal spine
  measured `s1→2 (4200,0) s2→1 (-4200,0) … s7→6 (-4200,0)`, re-derived from the
  spine order (a lower-numbered link is west, a higher-numbered one east).
- **AC2** — nearest gate-to-any-corridor-band distance **200.00 u** (≥ the 200 u
  `TRIGGER_RADIUS`, so every trigger circle's interior is disjoint from every
  band's), own link exactly **tangent** (600 + 200 = 800), every gate
  `|x| = 4200 < 5000`.
- **AC3** — beacon counts per row `s1 1+1, s2 2+2 … s7 1+1`; every gate has
  exactly one beacon at `position + position.normalized() * 300` → (±4500, 0),
  inside the arena and inside its link's corridor band (the band is
  x ∈ [4400, 5000] east / [−5000, −4400] west).
- **AC4** — per row `gates().size() == gate_links.size()`, names `Gate<dest>`,
  origins the sector, destination sets equal `gate_links`. `git diff --name-only
  HEAD` names `sector.gd` as the only project file moved.
- **AC5** — one `friendly` blip per gate at its new position; the wiring row
  `test_engine2_wiring.gd:211-221` derives its friendly count from the sector's own
  `gates()` + `beacons()` (`:215-218`) and is untouched.
- **AC6** — `sector.gd` carries no `GATE_RING_RADIUS` and no `900.0` literal;
  `FIELD_EDGE_MARGIN` 800.0, `BEACON_GATE_OFFSET` 300.0, `CORRIDOR_DEPTH` 600.0
  stand; `gate.gd` md5 `c13574f6af658c1fcd4728c34901caf3` and
  `sector_registry.gd` md5 `584d206c15c1ab7541e6bcebfb368101`, each identical to
  `git show HEAD:<path>`.
- **Law shape (beyond the ACs)** — `_edge_reach` = 4200.0 on all four cardinals,
  5939.6971 at 45° (the inset corner), an exact 4200-axis hit for a shallow
  `(0.8, 0.6)` bearing, and 0.0 for a zero bearing (the division guard).

## Placement change is minimal
`git diff` over `sector.gd` is three hunks: the retired const + its 3-line
comment, `_add_gate`'s position line, the new `_edge_reach`. `_gate_bearing` has
no caller but `:584`; `_edge_reach` is called only at `:585`; `_spawn_pois`'s
beacon block (`:608-612`), `gates()`, `blips()`, the minimap mapping (`:277-279`)
and `populate` are byte-identical to HEAD.

## Moved rows vs SLICE.md §3
No row moved. `git diff --name-only HEAD` lists zero `vajb-orbit/tests/` paths
and both new untracked test/tool files are the wave's own; the nine §3 candidate
rows were each re-read and are position-agnostic (`test_s6_travel.gd:301` is a
hand-placed `_gate(2,1)` fixture; `:398` and `test_s6_heat.gd:485` seat the ship
on `gate.global_position`).

## Gate
- Fresh scratch store A: `[SUMMARY] passed=877 failed=0`, exit 0.
- Fresh scratch store B: `[SUMMARY] passed=877 failed=0`, exit 0.
- Growth `866 → 877` = `test_s17_gate_edges.gd`'s 11 rows only: for all 75
  suites the `[PASS]` count equals the file's own `func test_` count and no test
  file differs from HEAD.
- Mandated `verify --baseline s17_start --forbidden … --tests --expect-reports …`:
  `"problems": []` on the final run (the only earlier problem was this review file
  not yet existing). Its `--forbidden` entries are exact-string, so `docs/` and the
  directories are inert (L206) — hand-checked: no `project.godot`, `ui/`,
  `addons/` or `autoload/` path in the diff. `modified` also names the two
  `.agents/gen/dispatch_*.md` queue files, whose diffs are queue text only (a
  `--reasoning-effort high → max` flag and a removed parked block), outside the
  wave's file set.
- The one `SCRIPT ERROR` in both runs is L61's pre-existing
  `test_weapon_fx_f4.gd` freed-instance line, unchanged.

## Contract updates written by this review
- `docs/CONTRACTS.md` §19 — the K1 "three placement values" disposition now reads
  the live values (900 u retired; ±4200 u border placement; `RING_SCALE` 0.25 and
  `TRIGGER_RADIUS` 200.0 u stand).
- §9 — the S17 expected-count paragraph above S16's (`877/0`, the independent
  re-measurement, the `--suite=` correction).
- §10 — `v0.29`, the S17 review entry.

## Observations (not findings)
- `staging/compare/` is untracked designer-lane scratch (D13), present before this
  wave; it is not a project file and `verify_wave.py` does not track it.
- `test_s6_travel.gd:301`'s fixture value `Vector2(900.0, 0.0)` and its
  `..._inside_the_ring` name now echo the retired radius; the row is on §3's list
  as a hand-placed fixture and needs no change.

## LOW rows appended
`L216` (F1), `L217` (F2), `L218` (F3), `L219` (F4), `L220` (F5) — ids read from
`.agents/gen/_state/LOW_BACKLOG.md` at write time (the highest was `L215`).
