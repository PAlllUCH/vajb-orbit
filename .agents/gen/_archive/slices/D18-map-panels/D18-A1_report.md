---
slice: D18
worker: D18-A1
model: "hyper/glm-5.3 @ high"
status: actionable
gate: "n/a (design only — no gate rows move, per D18_BRIEF.md §8)"
---

# D18-A1 report

## Result
The map-deck/navigation and panel-merge halves of the owner's 2026-10-03
ruling are now design-of-record: UI_SPEC §10 (deck + pin detail, ticks
N7–N14), STATION_HUB §17 (merged-panel detail + P6/P7 law text + ticks
P8–P14), and three wireframe mockups in `staging/mockup/`. Design only —
no code, no docs/gameplay, no CONTRACTS touched.

## Acceptance list answers
1. **A1 map deck** — deck spec + wireframe landed: N1 toggle paths and 80 %
   pane (UI_SPEC.md:960-972), N2 pan/zoom/arrows with the 8 px drag threshold
   (N14, UI_SPEC.md:966-972), N3 filter column + per-profile persistence +
   N6 always-on blips (UI_SPEC.md:974-981), deck chrome on A5.4 rows
   (`staging/mockup/d18_map_deck_wireframe.md` element law), compact minimap
   additions (pin bearing arrow, distance read, EXPAND button — same file).
2. **A2 navigation** — pin place/move/remove + autopilot on the existing API
   (`player_ship.gd:419`, `:426`), stick-cancel (`:816`), hold-LMB 0.5 s jump
   with `NO HYPERDRIVE INSTALLED`, and N5's spool/cooldown/arrival reads
   (UI_SPEC.md:983-1004; mockup's pin-state and hyperdrive blocks).
3. **A3 merged ARMORY** — P4 detail + wireframe: ship grid left (FITTING's
   own numbers, `fitting_panel.gd:18-70,148-149`), browser right with the
   auction tab strip (`auction_panel.gd:93-104`), drop-filtered-by-slot law,
   wrong-slot refusal = status line + 0.5 s slot-caption flash (P9/P10),
   buy-into-cell one flow, hover via the existing `describe()` chain
   (STATION_HUB.md:1534-1567; `d18_armory_wireframe.md`).
4. **A4 merged SHIPYARD** — P5 detail + wireframe: labelled stat pairs +
   comparison (`shipyard_panel.gd:74-86,203`), installed modules under the
   comparison (P12), repair block with `NOMINAL` rows (P13), fee in the
   footer, `REPAIR` ActionPrimary, hover everywhere (STATION_HUB.md:1569-
   1591; `d18_shipyard_wireframe.md`).
5. **A5 tick sheet + template** — every new wording carries value, reversal
   and tick id: N7–N14 (UI_SPEC.md:1005-1014), P8–P14 (STATION_HUB.md:1616-
   1626); P6 inspector lifecycle law text (§17.3, :1593-1601) and P7
   one-panel template + six-entry rail (§17.4, :1603-1614) as one spec block
   each inside §17.
6. **A6 handoff** — owner rulings implemented: the 2026-10-03 overhaul
   ruling (D18_BRIEF.md §2 verbatim); the A5 chrome law + 2026-09-26
   "look this clean" and "anchors and relative positioning" rulings
   (UI_SPEC.md:619-631, applied verbatim in every element-law row); the
   2026-09-27 shipped-chrome-only ruling (every surface names its A5.4 row
   or theme idiom with an ASSET_CATALOG cite); D13 approach B where it
   carries over (STATION_HUB.md:996-997 — the merged panes' landscape
   split); the §8 P1–P3 button/focus law (2026-10-03 unification). S29's
   citation list per deliverable: A1/A2 → UI_SPEC §9+§10, the map mockup,
   `minimap.gd`, `hud.tscn:361-431`, `player_ship.gd:419/426/816`,
   `10_ship_acquisition.md` R-S29-1, 01 §7; A3 → STATION_HUB §16 P4 + §17.1
   + §17.5, the armory mockup, `fitting_panel.gd`, `auction_panel.gd:93-104,160`,
   `station.tscn:214`, `station.gd:150-151`, `test_s11_inspector.gd:140-233`;
   A4 → §16 P5 + §17.2, the shipyard mockup, `shipyard_panel.gd`,
   `shipyard_panel.tscn:74-115`, `repairs_panel.gd:50-89`; A5 → §17.3-§17.5
   + UI_SPEC §10's tick table; A6 → this report.

## Deviations from SLICE.md
- **Browser tab strip ships minus HULLS** (P4 says "the auction's filter-tab
  strip"; a hull is not a module row and fits no cell). Judgment call inside
  a pinned acceptance (bucket 1); reversal: ship the tab disabled
  (STATION_HUB.md:1544-1546).
- **Unpinned values written PROPOSED with reversal**, never left to S29:
  filter column width 240, pin mark `text_primary` 6 px, drag threshold
  8 px (N14). (UI_SPEC.md:962,989,1013)
- **Reported, not changed (bucket 2):** 09 §3.3's own S19 tick series runs
  P1–P8 — a doc-local series distinct from the §8/§16 presentation series,
  and already cited as such by `repairs_panel.gd:70`. The brief pins the
  presentation continuation at P8; I flagged the collision in
  STATION_HUB.md:1530-1532 rather than renumbering (never renumber).
- Arrival FX, flight-scale ship sprite, B2-1 hover plate: staged per the
  brief (§10) — arrival state is the read + blip re-centring only.

## Evidence
- `rg -n '^## ' docs/design/UI_SPEC.md` → §10 at L952 (the amendment
  landed by heading only, per D18_BRIEF.md §9).
- `rg -n '^## ' docs/design/STATION_HUB.md` → §17 at L1523.
- `python3 staging/docs_index.py` → both indexes regenerated; UI_SPEC index
  row `| 10. | … | L952–L1018`, STATION_HUB row `| 17. | … | L1523–L1631`.
- `git status --short` → only `docs/design/UI_SPEC.md`,
  `docs/design/STATION_HUB.md` modified and the three
  `staging/mockup/d18_*_wireframe.md` files added (+ pre-existing
  `staging/compare/`, untouched). No gate rows moved (design only).
- Chrome audit: every mockup element-law row names an A5.4 row or theme
  idiom with its cite — `ui_panel_frame` (ASSET_CATALOG.md:444),
  `ui_minimap_bezel.png` (:443), `ui_button_plate_*` (:435-438),
  `icon_slot_*.svg` (:394-401), `icon_zoom_plus/minus.svg` (:310-311),
  `icon_equip_module.png` (:302), `icon_hull.svg` (:307); no new art, no new
  hue.

## Files touched
- `docs/design/UI_SPEC.md` — §10 appended (map deck + navigation pin detail, N7–N14)
- `docs/design/STATION_HUB.md` — §17 appended (merged panels, P6/P7 law, P8–P14)
- `staging/mockup/d18_map_deck_wireframe.md` — A1+A2 wireframes
- `staging/mockup/d18_armory_wireframe.md` — A3 wireframe
- `staging/mockup/d18_shipyard_wireframe.md` — A4 wireframe

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| B2-1 hover-plate pick (owner-gated) blocks P3's hover half | owner ruling | UI_SPEC.md:920-921 |
| Hyperdrive arrival FX + flight-scale ship sprite staged on art budget | staged | D18_BRIEF.md §10 |
| 09-series P8 / presentation-series P8 namespace collision, owner may rename | owner note | STATION_HUB.md:1530-1532 |

## Fixer note (2026-10-03, wave D18 — D18-F1)
Cured the three MED findings of D18-R1 inside UI_SPEC §10 and the map-deck
wireframe only (§9 and STATION_HUB §16 untouched; F4–F7 ride T-94–T-97).
- **F1 (press-on-pin precedence):** `UI_SPEC.md:999-1005` — press-down hit-tests the pin first; a press that hits the pin is a remove candidate and never a place or move; place/move applies only to a press that misses it (wireframe `d18_map_deck_wireframe.md:70-75`).
- **F2 (pin follows while held):** `UI_SPEC.md:1006-1009` — the pin is placed at press-down and never follows the cursor; a held move past N14's 8 px threshold is a pan (N2) and leaves the pin where it was placed (wireframe :57-59, :76-77).
- **F3 (toggle→blip-class mapping):** `UI_SPEC.md:979-997` — mapping table in §10: HOSTILES rides shipped `KIND_HOSTILE`+`KIND_SWARMER` (N20), FRIENDLY rides shipped `KIND_FRIENDLY`; STATIONS/GATES/ASTEROID FIELDS/POIS/CARGO & WRECKS/CONTRACTS get new PROPOSED classes `KIND_STATION`/`KIND_GATE`/`KIND_ASTEROID_FIELD`/`KIND_POI`/`KIND_WRECK`/`KIND_CONTRACT` (N15–N18, N21–N22; shipped `KIND_GHOST` rides POIS, N19); N23: an unshipped class's toggle is inert (reversal: hidden until the class ships). N6 re-anchored on `KIND_STATION`/`KIND_GATE` — nothing is exempt until they ship; `KIND_SELF` is never filterable (wireframe N6 row :46).
- Index refreshed (`staging/docs_index.py`): UI_SPEC §10 `L952–L1049`; no gate rows touched (design only).
