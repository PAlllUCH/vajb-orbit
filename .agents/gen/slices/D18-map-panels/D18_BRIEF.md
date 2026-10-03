# D18 — Map deck & panel consolidation design (wave brief)

**Wave:** D18 (design lane, item 18 of `dispatch_designer.md`)
**Slice folder:** `.agents/gen/slices/D18-map-panels/`
**Owner go (2026-10-03):** the overhaul ruling — the map/navigation half and
the panel-merge half of `D16_UserInput.md` (verbatim in §2). **Design only:
no code, no docs/gameplay, no CONTRACTS.** Runs beside S28 (disjoint files)
and before S29 (its law).

## 1. The law to read, in order
1. `slices/D18-map-panels/SLICE.md` — scope, file sets.
2. `docs/design/UI_SPEC.md` **§8** (P1–P3 button/focus law) and **§9**
   (N1–N6 the map deck) — the pins, already landed dated 2026-10-03.
3. `docs/design/STATION_HUB.md` **§16** (P4–P7 panel consolidation) — the pin.
4. `docs/gameplay/10_ship_acquisition.md` 2026-10-03 block (the N5 module row).
5. `docs/design/UI_SPEC.md` §3.10 **A5.1–A5.4** (the composition/chrome law).
6. `docs/AGENT_PIPELINE_NOTES.md` only if a pipeline question arises.
7. The §5 extract below.

## 2. The owner's request (verbatim, `D16_UserInput.md`)
> "Flight: 1. The minimap needs to be expandable, and on when expanded there
> needs to be an option to PAN it and SCROLL it, with. also it needs a menu to
> show what in currect sector i want to show on minimap and an ABILITY FOR
> NAVIGATION, this means you pin on map where to go, or hold LPM and the ship
> uses hyper drive (if installed) to go there or something like that
> Station: 3. i want shipyard and repairs to be the same panel, in shipyard
> when i hover on an element i want to see a description in botton field. if a
> ship has equipped item it should show in shipyard as well. armory and
> fitting i want together as well, they serve the same purpose. the same
> mechanics. drag and drop engines, but we need an option to filter by slot
> (like in auction) overall an overhaul of these panel."

## 3. What is already measured (file:line)
| Fact | Site |
|---|---|
| the owner's ruling, verbatim | `D16_UserInput.md` (root, committed with this wave) |
| the map pins N1–N6, button/focus pins P1–P3 | `docs/design/UI_SPEC.md` §8/§9 |
| the panel pins P4–P7 | `docs/design/STATION_HUB.md` §16 |
| the hyperdrive content row (PROPOSED, tick N5) | `docs/gameplay/10_ship_acquisition.md` 2026-10-03 block |
| the compact minimap's today state | `ui/hud/minimap.gd` |
| the arrive-steering autopilot already exists; stick cancels | `game/player_ship.gd:419`, `:816` |
| no hyperdrive exists in the catalogue (measured) | grep 2026-10-03, zero hits |
| the inspector band nodes + the hover→describe signal system | `ui/screens/station.tscn:214`, `station.gd:150-151`, `tests/test_s11_inspector.gd:140-233` |
| the slot filter tab idiom to reuse | `ui/station/auction_panel.gd:82-100` |
| slot families | `game/module_catalog.gd` (`engine`, `weapon`, `shields`, `utility`) |
| the stale-band + layout defects this overhaul answers | `.agents/gen/slices/D17-playtest-pass/D17-P1_report.md`, `D17-P2_report.md`, `D17_synthesis.md` |
| the six shipped button sizes (P1's reversal) | `D17-P2_report.md` §Station chrome |

## 4. Pinned interface + rules
The §8/§9/§16 tick tables are law — verbatim in §5. Rules:
1. **Design only.** Deliverables = spec blocks + wireframe mockups + tick
   sheet detail; S29 implements and cites this report.
2. **The pins are fixed.** A worker who believes a pinned number is wrong
   reports it and leaves it (bucket 2). Mockups are wireframes (`.md`), the
   D16-R1-precedented form; a rendered plate pass is a later owner ask.
3. **Shipped chrome only** (owner 2026-09-27): every surface names its
   A5.4 row or theme idiom with its `ASSET_CATALOG.md` cite; no new art, no
   new hue (UI_SPEC §1).
4. **Every new presentation value carries its reversal + tick id** — a label
   wording is a value. New wordings continue the **N/P** rows already opened
   (N7…, P8…) — never renumber.

## 5. Spec extract (verbatim, cited)
`UI_SPEC.md` §9 (the map's operative rows):
> "**N4** | **The navigation pin.** A click (no drag) on the deck places/moves
> one destination pin (diamond mark + edge bearing arrow on the compact
> minimap, distance read under it); short press issues the **existing
> autopilot order** to the pin; stick input cancels; clicking the pin removes
> it. **Hold LMB ≥ 0.5 s = hyperdrive jump to the pin** (only with N5
> installed; otherwise the caption `NO HYPERDRIVE INSTALLED` under the pin)"

`STATION_HUB.md` §16 (the merge's operative rows):
> "**P4** | **ARMORY + FITTING fold into one ARMORY panel** … Right: the
> inventory browser — the auction's filter-tab strip over owned + buyable
> module rows (the auction row idiom), every row draggable. Cells accept
> drops **filtered by slot** … **Buy and fit are one flow** …"
> "**P5** | **SHIPYARD + REPAIRS fold into one SHIPYARD panel.** … the
> selected hull's **installed modules are shown** … the damage table with
> `NOMINAL` for intact systems …"
> "**P7** | … The rail folds 8 → **6 entries**: ARMORY, REFINERY, EXCHANGE,
> AUCTION, SHIPYARD, LAUNCH (FITTING into ARMORY, REPAIRS into SHIPYARD)"

`UI_SPEC.md` §8 (the chrome every panel obeys):
> "**P1** | `ActionPrimary` | **360×56** | `Pressables` plate | … **P3 — one
> focus language everywhere.** … §6's existing theme row: the 1 px
> `accent_danger_bright` focus ring …"

## 6. Acceptance list (numbered)
- **A1 (map deck):** the deck spec + wireframes — expansion (N1), pan + zoom +
  arrows (N2), the filter column with persistence (N3), deck chrome on A5.4
  pane rows, the compact minimap's additions (pin bearing arrow, N6 always-on
  blips).
- **A2 (navigation):** the pin interaction spec + wireframes — place/move/
  remove, the autopilot order (the existing API), stick-cancel, the hold-LMB
  hyperdrive jump with the `NO HYPERDRIVE INSTALLED` caption, the N5 module's
  UX (spool, cooldown read).
- **A3 (merged ARMORY):** the P4 panel spec + wireframe — ship grid left,
  browser right with the auction tab strip, drag-and-drop law per slot,
  wrong-slot refusal (status line + cell caption flash, never colour alone),
  buy-into-cell flow, hover-describe via the existing chain.
- **A4 (merged SHIPYARD):** the P5 panel spec + wireframe — labelled hull
  stat pairs, comparison block, the selected hull's installed modules, the
  repair block (`NOMINAL`, fee in the footer, `REPAIR` primary), hover-describe.
- **A5 (tick sheet + template):** the N/P presentation detail — every new
  wording with its tick id and reversal — plus the P6 inspector lifecycle law
  text and the P7 panel template as one spec block.
- **A6 (handoff):** the report names the owner rulings implemented (the
  2026-10-03 ruling, the A5 chrome law, D13 approach B, the 2026-09-26
  look-this-clean/anchors rulings) and maps each deliverable to S29's
  citation list.

## 7. Worker table
| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| D18-A1 | designer | `docs/design/, staging/mockup/, .agents/gen/slices/D18-map-panels/` | `D18-A1_report.md` + mockups + amendment detail |
| D18-R1 | design reviewer | `docs/design/, .agents/gen/slices/D18-map-panels/D18-R1_review.md` | `D18-R1_review.md` |

Models (owner, 2026-10-03): **A1 = `hyper/glm-5.3` @ high** (very demanding),
R1 = `hyper/glm-5.3-flash` @ high.

## 8. Run order + tests
**A1 → R1** (a fixer pass if the review leaves HIGH or MED). No gate rows
move — design only; a row moving is a defect.

## 9. Hard rules
- `docs/gameplay/*`, `docs/CONTRACTS.md`, `docs/archive/`, all code:
  untouchable. `docs/design/` writes are amendment blocks appended by heading
  only; refresh the generated section indexes.
- No AI art (owner 2026-09-27). Evidence cites on every row. Reports ≤120
  lines, reviews ≤150.

## 10. Staged / deferred
- The B2-1 hover-plate pick (owner); the flight-scale ship sprite and the
  hyperdrive arrival FX (art budget); L263's staged icon; S28's mechanical
  fixes; S29's implementation.

## 11. Owner tick list
The N/P rows of §8/§9/§16 as the worker details them (N7…/P8… wordings
included). Unticked rows implement at their PROPOSED value (the S19
precedent).

## 12. Close-out (the orchestrator)
`python3 staging/verify_wave.py verify --baseline d18_start` (design-only
diff surface), WAVEBOARD + `dispatch_designer.md` one-liners,
`MASTER_REPORT.md` §6 recap, wave-boundary commit; then S29's five-piece
lands citing this report.
