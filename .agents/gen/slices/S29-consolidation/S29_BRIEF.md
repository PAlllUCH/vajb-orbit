# S29 — Panel consolidation + the map deck (wave brief)

**Wave:** S29 (coder lane, item 35 of `dispatch_coder.md`)
**Slice folder:** `.agents/gen/slices/S29-consolidation/`
**Owner go (2026-10-03):** the overhaul ruling (`D16_UserInput.md`) — this wave
implements D18's law. Runs after D18 + S28 (both closed 2026-10-03); the
phase's items 30–33 follow it.

## 1. The law to read, in order
1. `slices/S29-consolidation/SLICE.md` — scope, file sets, builder split.
2. `docs/design/UI_SPEC.md` **§9** (N1–N6) and **§10** (N7–N23, incl. the
   fixer's pin-precedence, pin-placement and toggle→blip-class laws).
3. `docs/design/STATION_HUB.md` **§16** (P4–P7) and **§17** (P8–P14 + the
   merged-panel detail, P6 lifecycle, P7 template).
4. `slices/D18-map-panels/D18-A1_report.md` (+ fixer note) and the three
   `staging/mockup/d18_*_wireframe.md` — the design of record.
5. `docs/gameplay/10_ship_acquisition.md` 2026-10-03 block — the hyperdrive
   content row.
6. `docs/design/UI_SPEC.md` §3.10 **A5.1–A5.4** — the composition law.
7. The §5 extract.

## 2. The owner's request (verbatim, `D16_UserInput.md`)
> "The minimap needs to be expandable … PAN it and SCROLL it … a menu to show
> what in currect sector i want to show on minimap and an ABILITY FOR
> NAVIGATION, this means you pin on map where to go, or hold LPM and the ship
> uses hyper drive (if installed) to go there or something like that …
> i want shipyard and repairs to be the same panel … if a ship has equipped
> item it should show in shipyard as well. armory and fitting i want together
> as well, they serve the same purpose. the same mechanics. drag and drop
> engines, but we need an option to filter by slot (like in auction) overall
> an overhaul of these panel."

## 3. What is already measured (file:line)
| Fact | Site |
|---|---|
| the map + panel law (N1–N23, P4–P14) | `UI_SPEC.md` §9/§10, `STATION_HUB.md` §16/§17 |
| the hyperdrive content row (12 000 CR, tier 3, draw 3, 30 s, 1 s) | `10_ship_acquisition.md` 2026-10-03 block |
| the compact minimap's five shipped kinds | `ui/hud/minimap.gd:141` area |
| the autopilot order API + stick-cancel | `game/player_ship.gd:419`, `:816` |
| the inspector signal chain + guards (S28's) | `ui/screens/station.gd:385,470-523` |
| the fitting grid's own numbers | `ui/station/fitting_panel.gd:18-70,148-149` |
| the auction tab strip idiom | `ui/station/auction_panel.gd:92-110` |
| shipyard comparison + hover formats | `ui/station/shipyard_panel.gd:60-115,203` |
| the repairs damage table | `ui/station/repairs_panel.gd:50-89` |
| the module catalogue + SOURCE_ROLLS | `game/module_catalog.gd`, `docs/gameplay/10_ship_acquisition.md` |
| the wireframes | `staging/mockup/d18_map_deck/armory/shipyard_wireframe.md` |
| S28's P1–P3 button tokens on the survivors | `UI_SPEC.md` §8 (the merged panels adopt them) |

## 4. Pinned interface + rules
The §9/§10/§16/§17 tables are law. Rules:
1. **The pins are fixed.** A number you cannot derive from the law or the
   wireframes is reported in the report, never invented, never edited into
   docs (bucket 2).
2. **A5 law**: containers + anchors, never coordinates; chrome by the
   per-surface table; shipped chrome only; no new art, no new hue.
3. **Builder split**: B1 owns the flight half (`ui/hud/`, `game/`, `tests/`),
   B2 owns the station half (`ui/screens/`, `ui/station/`, `tests/`) —
   **sequential** (B2 runs after B1 exits; both may touch `tests/`, never the
   same suite undisclosed).
4. Every moved test row is disclosed (the L264 lesson); zero gate failures ×2.

## 5. Spec extract (verbatim, cited)
`UI_SPEC.md` §10 (after the fixer):
> "a press that hit-tests the pin is a remove candidate, never a place or
> move … the pin is placed at press-down and never follows the cursor; a held
> move past N14's 8 px threshold is a pan … HOSTILES rides shipped
> `KIND_HOSTILE`+`KIND_SWARMER`; STATIONS/GATES/ASTEROID FIELDS/POIS/CARGO &
> WRECKS/CONTRACTS get new PROPOSED classes … N23: an unshipped class's
> toggle is inert"

`STATION_HUB.md` §16/§17:
> "**P4** ARMORY + FITTING fold into one ARMORY panel … every row draggable.
> Cells accept drops **filtered by slot** … **Buy and fit are one flow** …"
> "**P5** SHIPYARD + REPAIRS fold into one SHIPYARD panel … the selected
> hull's **installed modules are shown** … `NOMINAL` for intact systems …"
> "**P7** … The rail folds 8 → **6 entries**: ARMORY, REFINERY, EXCHANGE,
> AUCTION, SHIPYARD, LAUNCH"

`10_ship_acquisition.md` 2026-10-03 block:
> "R-S29-1 | new engine-family module `e_hyperdrive` | … tier 3, slot
> `engine`, cost 12 000 CR, draw 3; … one jump per 30 s cooldown, 1 s spool …
> rolls: the AUCTION `SOURCE_ROLLS` engine column + the ARMORY browser at
> tier 3"

## 6. Acceptance list (numbered)
- **A1 the map deck** (B1): N1 expansion (M key, corner button, ESC), N2
  pan/zoom/arrows, N3 filter column + per-profile persistence, the new blip
  classes (N15–N18, N21–N22; `KIND_GHOST`→POIs N19; HOSTILES N20), N23
  inert-toggle rule, N6 always-on station/gate (anchored on the new classes),
  deck chrome per A5.4.
- **A2 the navigation pin** (B1): place/move/remove with the fixer's
  precedence law, the autopilot order on the existing API, stick-cancel,
  hold-LMB ≥ 0.5 s jump, `NO HYPERDRIVE INSTALLED` caption, the N5 reads
  (spool, cooldown, arrival), the compact minimap's bearing arrow + distance.
- **A3 the hyperdrive module** (B1): the `e_hyperdrive` row exactly as
  R-S29-1 pins it, in the catalogue + the auction `SOURCE_ROLLS` engine
  column; the ARMORY browser listing is B2's surface.
- **A4 the merged ARMORY** (B2): P4 + §17.1/§17.5 — grid left, browser right
  with the tab strip minus HULLS, drag-and-drop filtered by slot, the
  wrong-slot refusal (status line + 0.5 s caption flash, never colour alone),
  buy-into-cell one flow, hover→describe through the existing chain.
- **A5 the merged SHIPYARD** (B2): P5 + §17.2 — labelled stat pairs,
  comparison block, the selected hull's installed modules, the `NOMINAL`
  repair block with the fee in the footer, `REPAIR` ActionPrimary,
  hover→describe.
- **A6 the shell** (B2): rail 8→6 per P7, the inspector fills (P6's S29
  half: SHIPYARD/LAUNCH summaries), the P7 one-panel template, and the P1–P3
  button/focus law on the merged panels.
- **A7 the D17 leftovers inside the merged panels** (B2): no "DROP HERE"
  ghosts on empty cells, fit confirm/refuse toasts, cell tooltips + the
  CANDIDATE rename, hull-comparison deltas, the REPAIRS dead band resolved,
  scroll affordances where rows overflow.
- **A8 the gate**: zero failures ×2 fresh scratch, full moved-row disclosure.

## 7. Worker table
| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| S29-B1 | coder (flight half) | `vajb-orbit/ui/hud/, vajb-orbit/game/, vajb-orbit/tests/, .agents/gen/slices/S29-consolidation/` | `S29-B1_report.md` + A1–A3 + gate |
| S29-B2 | coder (station half) | `vajb-orbit/ui/screens/, vajb-orbit/ui/station/, vajb-orbit/tests/, .agents/gen/slices/S29-consolidation/` | `S29-B2_report.md` + A4–A7 + gate |
| S29-R1 | reviewer | the union + review file | `S29-R1_review.md` (grades A1–A8) |
| S29-F1 | fixer (only if HIGH/MED) | the owning builder's set | cure note |

Models (owner, 2026-10-03): B1/B2 = `hyper/glm-5.3` @ high (very demanding);
R1 = `hyper/glm-5.3-flash` @ high; F1 per depth.

## 8. Run order + tests
**B1 → B2 → R1 → F1 (if HIGH/MED).** Gate law: zero failures ×2 fresh
scratch. **Suites expected to move** (disclose every row): `test_d7_armory`,
`test_s10_armory_input`, `test_s15` (reads `salvo_cells` dynamically — the
armory body moves), `test_s11_inspector` (the emitter set changes with the
merge), `test_s21_stability` (the rail/boot rows), `test_p1_repairs` +
`test_p2b_services` (the repairs surface moves into SHIPYARD),
`test_s3_auction` (the engine SOURCE_ROLLS column), the fitting/shipyard
suites that pin the merged subjects, plus the new `test_s29_*` rows.

## 9. Hard rules
- No doc edits; no new art; no coordinate layouts; reports ≤120 lines, review
  ≤150; evidence cites on every row.

## 10. Staged / deferred
- B2-1 hover-plate pick (owner); hyperdrive arrival FX + flight-scale sprite
  (art budget); T-94–T-99 (their owners).

## 11. Owner tick list
None new — every N/P row implements at its PROPOSED value where unticked
(the S19 precedent); the tick sheet travels with D18's report.

## 12. Close-out (the orchestrator)
Gate ×2 recorded, `python3 staging/verify_wave.py verify --baseline
s29_start`, WAVEBOARD + `dispatch_coder.md` one-liners, `MASTER_REPORT.md`
§6 recap, wave-boundary commit; `CONTRACTS.md` §9 gate figure + the §17/§22
seams by R1 (review waves own updating it).
