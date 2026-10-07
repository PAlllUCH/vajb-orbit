---
slice: D18
reviewer: D18-R1
verdict: passed-with-followups
gate: "n/a (design only — no gate rows move)"
---

# D18-R1 review

Reviewed against D18_BRIEF.md §5 (verbatim extract), UI_SPEC §8/§9/§10-context,
§3.10 A5.1–A5.4, STATION_HUB §16/§17 — never against A1's own report claims
(each re-derived from the code and the docs).

## Acceptance list
- **A1 (map deck) — pass**, one MED: deck spec + wireframe sit on N1 (80 %,
  three toggle routes), N2 (25 %–400 %, 64 px steps), N3 (eight toggles,
  label + ON/OFF state, per-profile persistence), N6 (STATION/GATE exempt) —
  `UI_SPEC.md:960-981`, `d18_map_deck_wireframe.md`. Finding F3 (the
  toggle→blip-class mapping is unspecified) rides under A1.
- **A2 (navigation) — pass**, two MED: pin place/move/remove, the existing
  autopilot API (`player_ship.gd:419`, `:426`), stick-cancel (`:816`), the
  0.5 s hold jump and the `NO HYPERDRIVE INSTALLED` caption all land on N4's
  pinned semantics (`UI_SPEC.md:983-994`); N5's 1 s spool / 30 s cooldown
  match the pin and `10_ship_acquisition.md` R-S29-1 (12 000 CR, tier-3
  engine, draw 3 — read at `10_ship_acquisition.md:335`). Findings F1/F2
  (press-semantics ambiguities in §10/mockup, not pin drift).
- **A3 (merged ARMORY) — pass**: ship grid on FITTING's own numbers
  (`fitting_panel.gd:18-70,148-149` — verified), auction tab strip minus
  HULLS, every row draggable, drops filtered by slot, wrong-slot refusal =
  status line + 0.5 s caption flash, never colour alone (P9/P10), buy-and-fit
  one flow with the credits check first, hover through the one
  `inspect_requested` chain (`station.tscn:214`, `station.gd:150-151`).
  `STATION_HUB.md:1534-1567`, `d18_armory_wireframe.md`.
- **A4 (merged SHIPYARD) — pass**: labelled stat pairs + comparison block
  (`shipyard_panel.gd:74-86,203` — verified), the selected hull's installed
  modules (the owner's equipped-items ask, P12), damage table with `NOMINAL`
  and no MISSING/FEE body rows (`repairs_panel.gd:74-89` — verified), fee in
  the footer (`:50,52` — verified), `REPAIR` P1 primary, hover on the one
  chain. `STATION_HUB.md:1569-1591`, `d18_shipyard_wireframe.md`.
- **A5 (tick sheet + template) — pass**: N7–N14 (`UI_SPEC.md:1004-1013`) and
  P8–P14 (`STATION_HUB.md:1618-1626`) every row carries value + reversal; the
  series continue §9 at N7 and §16 at P8 without renumbering; the 09-series
  P8 collision is flagged in prose, not silently reused
  (`STATION_HUB.md:1530-1532`); P6 law text and the P7 template + six-entry
  rail (ARMORY, REFINERY, EXCHANGE, AUCTION, SHIPYARD, LAUNCH — six counted)
  are one spec block each.
- **A6 (handoff) — pass**: all four named rulings are implemented by the
  text, not just named — the A5 chrome law (both §10 and §17 headers bind
  A5.1–A5.4), the 2026-09-26 look-clean/anchors rulings (§17.1/§17.2 build
  only on containers and A5.4 rows), the 2026-09-27 shipped-chrome ruling
  (every element-law row cites an A5.4 row or theme idiom with an
  ASSET_CATALOG page cite — spot-checked :302/:307/:310-311/:394-401/:435-438/
  :443/:444, all accurate), D13 approach B (verified at
  `STATION_HUB.md:996-997`). Citation list per deliverable is complete.

## A1's two judgment calls
- **Tab strip minus HULLS — accepted (bucket 1, correctly disclosed).** A
  hull is not a module row and fits no module cell; the reversal (ship the
  tab disabled) is written at `STATION_HUB.md:1544-1546`. The surviving nine
  tabs match `auction_panel.gd:92-104` exactly.
- **PROPOSED values with reversals — accepted.** Filter column 240
  (`UI_SPEC.md:964`), pin mark 6 px (`:989-990`), drag threshold 8 px
  (`:970`, N14) — each carries its reversal, and all three are listed in the
  report's Deviations. No unpinned value is left for S29 to choose.

## Findings
| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| D18-A1/F1 | MED | `UI_SPEC.md:983-987` + `d18_map_deck_wireframe.md:54-64` | A short press **on the existing pin** triggers both pinned behaviours at once: §10's unqualified "press-down on the deck places or moves the pin" and "a short press on the pin removes it". The mockup's state table gives no hit-test precedence, so S29 could ship remove-then-replace or move-then-remove. Fix inside §10 (the wave's own text; §9 is untouched): a press that hit-tests the pin is a remove candidate, never a place/move. | fixer |
| D18-A1/F2 | MED | `d18_map_deck_wireframe.md:56` vs `UI_SPEC.md:970` | The mockup's "(pin follows while held)" contradicts N14's 8 px threshold: a held move past 8 px is by law a pan, yet the parenthetical makes it a pin move. §10 must state the pin is placed at press-down and does not follow (or follows only under 8 px). | fixer |
| D18-A1/F3 | MED | `UI_SPEC.md:974-981` vs `vajb-orbit/ui/hud/minimap.gd:141` | The filter column's eight toggles have no mapping onto the map's five shipped blip classes (`KIND_SELF/HOSTILE/FRIENDLY/SWARMER/GHOST`): STATIONS, GATES, ASTEROID FIELDS, POIS, CARGO & WRECKS and CONTRACTS name no class S29 can filter, and the N6 exemption is anchored only on KIND_FRIENDLY. §10 needs the toggle→class table (or the new blip classes named) before S29 codes the column. | fixer |
| D18-A1/F4 | LOW | `STATION_HUB.md:1557-1558` | The credits-refusal wording is cited at `auction_panel.gd:160`; the const `STATUS_REFUSED_CREDITS` sits at `:166` (`:160` is `INSPECT_TITLE_FORMAT`). | ticketed as **T-94**, not fixed here |
| D18-A1/F5 | LOW | `STATION_HUB.md:1571-1572` + `d18_shipyard_wireframe.md:44` | Hull-row meta cited at `shipyard_panel.gd:82-84`; `META_FORMAT` is `:104` and the `ACTIVE` badge `:100-101` (`:82-84` is inside `STAT_ROWS`). | ticketed as **T-95**, not fixed here |
| D18-A1/F6 | LOW | `d18_shipyard_wireframe.md:48` | The hover format is cited inside `shipyard_panel.gd:60-88`; `HOVER_FORMAT` is at `:113`. | ticketed as **T-96**, not fixed here |
| D18-A1/F7 | LOW | `UI_SPEC.md:975-976` | The "auction tab plate idiom" is cited at `auction_panel.gd:98-100`; those lines are `TABS` array rows — the plate idiom itself (base `Button` + `StationValue`, `TAB_INNER_MARGIN`) is described at `:105-110`. | ticketed as **T-97**, not fixed here |

## Verified scope + pins
- Pinned bodies untouched: the only deletions in both doc diffs are the
  generated index rows; §8/§9 (UI_SPEC) and §16 (STATION_HUB) text is
  unmodified; both section indexes regenerated (`UI_SPEC.md:28` row 10,
  `STATION_HUB.md` index row 17).
- File scope: only `docs/design/UI_SPEC.md`, `docs/design/STATION_HUB.md`,
  the three `staging/mockup/d18_*.md` and the slice folder carry D18's
  change. The modified `vajb-orbit/*` files belong to the parallel S28 wave
  (its `S28-B1_report.md` is present; D18_BRIEF.md:7 "runs beside S28");
  `staging/compare/` is pre-existing untracked, untouched. Nothing outside
  A1's file set moved by this wave.
- No new-render proposal anywhere; no new hue; every mockup row names shipped
  chrome. Mockups are `.md` wireframes (the D16-R1-precedented form).
- Composition: all layout is containers + `custom_minimum_size` + size flags
  (A5.2(i)); both code-drawn marks (pin diamond, bearing arrow) sit in their
  own child rects (A5.2(iii)).

## Verified fixes
(fixer pass pending — F1/F2/F3 go to one fixer pass; F4–F7 are ticketed.)

## Gate
n/a — design-only wave; `D18_BRIEF.md` §8: a gate row moving is a defect.
No gate was run and no row moved.
