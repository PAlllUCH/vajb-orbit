---
slice: D19
worker: D19-A1
model: "xiaomi/mimo-v2.6-pro"
status: actionable
gate: "1074/0 held (design-only wave; measured line under Evidence)"
---

# D19-A1 report

## Result
`UI_SPEC.md` §12 (drawer / tooltip / INSPECT sheet / shell bands / the A5.5
operational test + census / ticks N31–N41) and `STATION_HUB.md` §19 (OVERVIEW's
five blocks, the tile component, the one skeleton + per-pane conformance / ticks
P22–P30 / the completed supersession ledger / the staged art list) landed at
measurement level; three wireframes shipped; the census closes A5.5 over
`vajb-orbit/ui/` in 15 rows (6 cures). No code, no art, no gate movement.

## Acceptance list answers
- A1 — DONE — `UI_SPEC.md` §12.1 drawer (measured table on the 360 px rail width,
  P16's entry plates + `MODULES`/`SESSION` captions, scrim N26 + extent N40,
  N26's 0.18/0.12 s motion, focus N39, five close paths); §12.2 tooltip (§5.1
  grammar + N27's `INSPECT` hint line, 0.25 s delay, cursor +12/12, clamp N32);
  §12.3 sheet (rows 1–6 anatomy table, three triggers incl. the `station_inspect`
  keyboard route, size-to-content inside min 420 / max 720 + N32); §12.4 header
  and footer as §3.1 measured-grid tables.
- A2 — DONE — `STATION_HUB.md` §19.1 five blocks as grid rows (identity on §15.5/
  A5.4-1; 3×2 tiles min 300×140; active hull + repair summary with `REPAIR →` to
  SHIPYARD (P24's landing); three services rows (CONTRACTS · INSURANCE · VAULTS,
  readouts U6/U10/U16); one flavour line (P27)); §19.2 tile internals/focus/
  pressed; §19.3 the one skeleton measured once; §19.4 conformance rows for all
  seven panes (PaneHeader / split / cluster / footer + what moves into each split)
  plus the PROPOSED SERVICES row (P26).
- A3 — DONE — `staging/mockup/d19_shell_wireframe.md`,
  `d19_overview_wireframe.md`, `d19_popup_wireframe.md` (the D18 idiom: design-law
  line, ASCII with numbered callouts, element-law table).
- A4 — DONE — `UI_SPEC.md` §12.5: 15 rows covering every hover/focus/selection
  handler under `vajb-orbit/ui/`; `shipyard_panel.gd:703-733` (row 1) and the
  fitting twin `fitting_panel.gd:1469-1491` (row 2) both → DELETE → TOOLTIP (N30);
  each row carries file:line + its named cure; S30 cures from the table alone.
- A5 — DONE — `STATION_HUB.md` §19.6: 15 old→new rows (§18's three completed: P6
  retired, P7's rail half, §17.1/§17.2's hover lines) plus §2's rail wording, §3.1
  marked LIVE/re-homed, §4's node tree, §5.5/§5.10/§10 focus rows, §15.1's
  SERVICES entry (U1), §9's entry beat, §12's notes, `UI_SPEC` A4.4, and
  `station.tscn:273`'s `TAB RAIL` line; with a named not-superseded list.
- A6 — DONE — `STATION_HUB.md` §19.7: 9 staged sprites + one "no chrome wanted"
  row, each with prompt draft, `flare` model, price at 10 cr = $0.05/2K and the
  pipeline route; sheet plan 5 runs ≈ $0.25 with fallbacks; nothing generated.

## Deviations from SLICE.md
All new values are PROPOSED with reversal in place (N31–N41, P22–P30). The
judgments a reader must weigh (each reversible as written):
- P18's five-block stack does not fit: minima ≈ 776 vs the split's 633 at 16:9 —
  reported, pin unchanged; PROPOSED cure is P22's scroll (reversal: no scroll).
- P18's `REPAIR →` names an arrow glyph the theme font set does not guarantee
  (§5.8's measured finding) — kept as pinned; P30 draws the chevron as a mark.
- P18 cites "§15's W3 names" for the service labels; §15.6 assigns them to U2
  (W3 is the nine place names). Wording shipped as pinned, cite corrected in
  §19.1 row 4 — report only, no pin changed.
- N28's "row/cell INSPECT inline chip": 96×32 cannot seat in a 48/117 px cell, so
  cells route through the cluster chip (N37; reversal: one shared cluster chip).
- P2's "same vertical band the shared footer hint line tops" read as one shared
  foot band (hint left, cluster right) — P28; reversal names the two-row split.
- N24's reserved slot = the foot-band hint cell at 18 px (the pin demands a
  stated height); the reversal is N24's own.
- N31 adds a command clause + focused-row scroll exemption so the pinned auction
  tab idiom (`auction_panel.gd:403-408`) and the rebind auto-reveal stay legal;
  reversal is the strict reading.
- Census vocabulary gained RETROFIT (row 5) and a P21-adjacent class (row 7)
  beyond the brief's three cures; the named three cover every other row.
- A4/A5/A6 live as doc subsections (UI_SPEC §12.5/§12.6, STATION_HUB §19.5–§19.7)
  so D19-R1 (whose set carries the two docs and `vajb-orbit/ui/`, not
  `staging/mockup/`) can grade every acceptance row; only the wireframes sit in
  `staging/mockup/` (A3's own words).

## Evidence
- Gate, headless re-run after the doc edits: `[SUMMARY] passed=1074 failed=0`
  (`godot --headless … res://tests/headless_runner.tscn --quit-after 1200`;
  only the benign ObjectDB leak warnings follow).
- `python3 staging/docs_index.py` after adding §12/§19: only the two edited docs
  rewritten ("index written, 12 sections" / "19 sections"); every other indexed
  doc "already current".
- The census re-derives from two greps over `vajb-orbit/ui/` (handler defs +
  `.visible`/size/position/`add_child`/`move_child` mutations); every §12.5 cite
  is a handler body read at that line.
- `git status`: this wave's five files + `staging/compare/` (pre-existing) +
  `D19_prompts.md`, which is the orchestrator's own reasoning-effort fix
  (predates this worker; untouched here).

## Files touched
- `docs/design/UI_SPEC.md` — new §12 (drawer, tooltip, sheet, shell bands, A5.5
  test + census, ticks N31–N41) + regenerated index row.
- `docs/design/STATION_HUB.md` — new §19 (OVERVIEW, tile, skeleton + conformance,
  ticks P22–P30, supersession ledger, staged art list) + regenerated index row.
- `staging/mockup/d19_shell_wireframe.md` — header + drawer over a pane.
- `staging/mockup/d19_overview_wireframe.md` — the OVERVIEW pane.
- `staging/mockup/d19_popup_wireframe.md` — tooltip + INSPECT sheet.
- `.agents/gen/slices/D19-station-shell-v2/D19-A1_report.md` — this report.

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| P18's stack arithmetic (776 vs 633) needs an owner tick on P22 or a P18 amendment | owner tick owed (bucket 2 — touches a pin) | `STATION_HUB.md` §19.1 |
| Tick sweep N31–N41 + P22–P30 (S19 precedent: unticked PROPOSED implements at value) | owner tick owed | `UI_SPEC.md` §12.6, `STATION_HUB.md` §19.5 |
| The §19.7 art sheet awaits owner approval before any generation runs | staged budget gate | `STATION_HUB.md` §19.7 |
