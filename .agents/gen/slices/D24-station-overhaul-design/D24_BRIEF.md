# D24_BRIEF — the station-overhaul design round (P4 opener)

**Kind:** design (docs only — no code, no scenes, no theme, no assets).
**Tier:** very demanding (`hyper/glm-5.3` @ high, per the dispatch roster).
**Law:** this brief; a number you cannot derive from a standing law is written
**PROPOSED** with its reversal, never chosen silently. The owner's words are
verbatim; you implement them, you do not re-interpret them into something else.

## 1. The law to read, in order

1. `docs/design/STATION_HUB.md` **§22** — the owner rulings and asks, each with
   its measured current state. Your whole task is §22's "design pending D24"
   line: you turn it into numbers in the owning sections.
2. `STATION_HUB.md` §3 (composition), §19.1 (the P-number skeleton), §5.7,
   §15.1, §17 (the panel template), §21 (the refinery queue panel).
3. `docs/design/UI_SPEC.md` §3.10 **Amendment 5** (A5.1–A5.5: containers and
   relative positioning, never coordinates — the standing owner ruling), §16
   (the ink law; A1 is ratified), §1 (the ≈4.0:1 floor).
4. `docs/gameplay/07_crafting.md` (65 lines — the agreed direction you must
   spec for real; §5 lists its own musts), `04_refinery.md`, `03_components.md`.
5. `docs/design/AUDIO_SPEC.md` §3 (the S-table row law: cue id, primary take,
   source, duration, bus, pool, the seam that plays it).
6. `AGENTS.md` §"Designer lane" and §"Rules" — hard rules, the SVG glyph law.
7. `.agents/gen/phases/P4-station-overhaul/PHASE.md` — the verbatim source list.

## 2. The owner's request (verbatim, 2026-10-12)

The nine items are quoted verbatim in `PHASE.md` §"Owner requirements" and
`STATION_HUB.md` §22 — read them there; this brief does not re-quote them.
The one ruling that shapes everything else: **the OVERVIEW deck becomes one
3×3 grid of nine module buttons** (ARMORY, REFINERY, EXCHANGE, AUCTION,
SHIPYARD, LAUNCH, CONTRACTS, INSURANCE, VAULTS), which closes the S41 fold
tradeoff and retires the P25 service rows into the grid.

## 3. What is already measured (cite these, do not re-derive)

- The overview tiles: `overview_panel.gd` `TILES` (3×2, `TILE_MIN` 300×140,
  3 columns, separation 16); the four tinted SVG glyphs modulate
  `text_caption`, the two raster ones (ARMORY `icon_equip_module.png`,
  LAUNCH `icon_map_route.png`) modulate `Color.WHITE` (`:251`) — **T-184**.
- The pane's measured width ~756 px (S41: the pane at 214..970): a 300 px
  3-column tile row cannot seat — the grid's tile minimum must be re-derived.
- The dialog sink exists:
  ```gdscript
  # autoload/dialog_manager.gd (Router.push_overlay, IMPLEMENTATION_PLAN §3.5)
  func confirm(id: StringName, title: String, body: String,
          confirm_text := "CONFIRM", cancel_text := "CANCEL") -> void
  func message(id: StringName, title: String, body: String,
          confirm_text := "OK") -> void
  # signals: dialog_confirmed(id), dialog_cancelled(id)
  ```
- Flight already has the HUD `CargoBlock` (S39/T-170) and `cargo_toggle` is
  bound to C; the station shows the hold only via the exchange's hold list and
  the armory's `HOLD %d/%d` subtitle.
- Undock: `launch_requested()` → route `&"loading"` (`launch_panel.gd:48,859`);
  no departure beat, no launch cue in the S-table.
- Refinery today: `QUEUE`/`LOAD`/`COLLECT ALL` 360×56 foot band (§5.7, T-181
  closed), job list right, SLOTS readout in the header band (P42).
- Exchange today: per-row INSPECT chip + a 56 px SELL plate (`exchange_panel.gd:39,51`).
- Shipyard today: builds are materials+labour by law (`game/shipyard.gd`,
  10 §3.1/§3.2) but the view presents CR (`BUILD_HULL_FORMAT`,
  `shipyard_panel.gd:146`).
- The armory today: SLOT LAYOUT grid (`GridBlock`), CELL INFO, five racks.
- The approved cures that ride your touched sections: **T-174** (LAUNCH
  briefing column: flat Tokens box), **T-175** (four header-caption surfaces),
  **T-176** (the staged row's dim factor).

## 4. The pinned interface you design against

- Every layout number follows **A5** (containers, anchors,
  `custom_minimum_size`, size flags; chrome by cut size or the flat Tokens
  box; no `_draw` over content). Every ink follows **§16** (A1 ratified;
  `text_dim` keeps only its disabled jobs; no new hex without a measured
  ratio).
- The tile idiom is P23's (Button-as-container, glyph + title + caption,
  `ui_tile_slab`); the row idiom P25's; the foot band §8 P1's 360×56; the
  chip row 32 px / `StationValue`.
- Crafting must satisfy `07_crafting.md` §5's own musts (costs derived from
  01/03 tables, no invented prices — the S28 value-ladder law).
- Any new audio row follows AUDIO_SPEC §3's row shape and the CC0 sourcing
  law; the sequence must respect P29's two-press undock law.
- Any icon remaster follows the standing SVG glyph law (viewBox 0 0 96 96,
  flat shapes, ≤ 2 tones).

## 5. Acceptance list (answer each, with the amendment that owns it)

1. **A1 — the OVERVIEW grid.** §19/§5 amendment: the 3×3 grid of nine buttons
   (the exact set, P25 rows retired), the re-derived tile minimum/separation
   for the ~756 px pane, the hull block's new seat, and T-184's cure (glyph
   modulate `text_caption`, or an SVG remaster under the glyph law — pick one,
   PROPOSED, with the reversal).
2. **A2 — the buy-confirmation law.** UI_SPEC amendment: the door list (hull
   buy, module buy, ammo, insurance, vault rent, shipyard queue — every CR /
   materials spend), the DialogManager route (`confirm` vs `message`), and the
   wording pattern ("Are you sure you want to buy X for Y credits" +
   OK/CANCEL), with one worked example per door.
3. **A3 — the Cargo overlay.** One law for station and flight: the C key, the
   overlay's surface (§18 popup sinks), the contents rows (ammo rounds, ore,
   ingots, components, fuel cells) and their read-only seams.
4. **A4 — the launch sequence.** The beats (P29 two-press stands), where the
   sequence plays, and AUDIO_SPEC §3's new cue rows (ids, takes, source,
   durations, buses, pools, the seams that fire them).
5. **A5 — the armory equipped list.** §5/§20 amendment: one row per fitted
   module/weapon — slot cell, name, one stat line — and where it sits beside
   the SLOT LAYOUT grid.
6. **A6 — refinery LOAD ALL + machine read.** §5.7/§21 amendment: the LOAD ALL
   door (beside QUEUE/LOAD/COLLECT ALL), the machine-state idiom
   (available/running/done, never colour alone), and the button layout
   rework the owner asked for.
7. **A7 — the CRAFT tab.** `07_crafting.md` specced for real (recipe rows,
   costs from 01/03, the S28 value ladder, reversal per number) + the tab's
   surface in the refinery pane (§5.7/§21).
8. **A8 — exchange bulk sell.** The selection model (checkboxes or
   select-all + SELL ALL — pick one, PROPOSED), the wording, the totals read,
   and how it composes with the per-row SELL plate.
9. **A9 — the shipyard build rework.** §5.x amendment: the house style
   (refinery/auction idiom), the category separation, the materials bill
   shown as materials (ore/components rows, not CR), the confirm door (A2),
   and what happens to `BUILD_HULL_FORMAT`'s CR figures.
10. **A10 — the approved cures folded.** T-174/T-175/T-176's one-line cures
    land inside the sections you amend (they are owner-approved; cite the
    tickets).
11. **A11 — the tick list.** Every new value in one table, PROPOSED, each with
    its reversal, ready for the owner's tick sheet.

## 6. Worker table

| ID | Role | VAJB_WORKER_FILES | Deliverable |
|---|---|---|---|
| D24-A1 | designer | `docs/design/STATION_HUB.md, docs/design/UI_SPEC.md, docs/design/AUDIO_SPEC.md, docs/gameplay/04_refinery.md, docs/gameplay/07_crafting.md, docs/gameplay/03_components.md, docs/gameplay/10_ship_acquisition.md` | the amendments + `D24-A1_report.md` |
| D24-R1 | reviewer | same set (read-own; a one-line doc slip may be cured in review, disclosed) | `D24-R1_review.md` |

## 7. Run order

`verify_wave.py snapshot --name d24_start` + commit → **D24-A1** → **D24-R1**
(mandatory) → fixer only if R1 leaves HIGH/MED → close-out.

## 8. Tests that move

**None.** A docs-only wave: the gate re-runs **1330/0 ×2 byte-identical** at
close-out as the no-regression proof (`staging/gate.py --times 2`), and
`staging/docs_index.py` re-runs because section indexes shift. No CONTRACTS
edit (review waves own it; nothing here pins a code interface).

## 9. Hard rules

- No code, scene, theme or asset file changes — docs only.
- The owner-locked `18_engine_spec.md` is never edited.
- No invented prices: crafting and build costs derive from 01/02/03 (the S28
  value-ladder law); anything else is PROPOSED with its reversal.
- The escalation ladder applies: anything that would supersede an owner
  ruling (A5, §16 A1, P29, the T-181/T-182 closures) is reported, not
  changed.
- Reports ≤120 lines; cite `file:line`; never paste source.

## 10. Staged / deferred

- The implementation waves (S42+) are staged until this design closes; their
  shape follows the file-collision split this design implies.
- B2-1/B2-2 and T-179 stay the owner's (postponed / direction picks).

## 11. Owner tick list

A11's table IS the tick list — present it to the owner at close-out; unticked
rows implement at their PROPOSED value (the S19 precedent).

## 12. Close-out

1. `python3 staging/gate.py --times 2` → 1330/0 byte-identical.
2. `python3 staging/docs_index.py` (shifted indexes).
3. `verify_wave.py verify --baseline d24_start --expect-reports
   .agents/gen/slices/D24-station-overhaul-design/D24-A1_report.md`.
4. WAVEBOARD + TICKS refresh; the P4 queue gains the first implementation
   wave re-cut from your amendments.
5. Wave-boundary commit.
