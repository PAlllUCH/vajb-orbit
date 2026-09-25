---
slice: S18
worker: S18-B1
role: coder
status: ready
tier: paid
---

# S18-B1 — rebuild the ARMORY pane as D13's approach B

## Context (worker reads in this order)
1. `slices/S18-armory-rework/SLICE.md` — scope + your file-set row.
2. `slices/D13-armory-rework/D13-A0_report.md` — **the design law**: the chosen
   approach B by section, the PROPOSED values P1–P6 (each with its reversal),
   and the owner's tick answers. Nothing here is invented downstream.
3. `staging/mockup/armory_mockup_v2.py` — the owner-approved look and the
   geometry reference (its `derive()` is P6's law: every rect derived from the
   host rect, proportional). The mockup PNGs in `staging/mockup/out/` show the
   target; `_b_wide/_b_tall` show the required reflow.
4. `docs/design/UI_SPEC.md` §3.9 (instrument language) + §3.10 + Amendment 2
   (the pin you are superseding with P1); `docs/design/STATION_HUB.md` §5.11 +
   amendments; `docs/design/STYLE_BIBLE.md` §3 (ember) + the contrast/size
   floors.
5. `docs/gameplay/09_ship_slots_modules.md` §11 (batteries v2) + §12 (5×4
   hardcap) + §13/§16 (transactions: refusals write nothing); `docs/CONTRACTS.md`
   §17 (panel seams) + §16 rule 9 (no preloading the pane's siblings).
6. `vajb-orbit/ui/station/armory_panel.gd` (today's build) and
   `armory_style.gd` (the one style surface).

## The task
Rebuild the ARMORY presentation as D13's design of record:
- **Console:** landscape **1360×516** at the pinned (452,214)+1392×610 host
  (P1). The portrait `ui_armory_console` master is superseded: render the new
  master **scripted** (`staging/mockup/render_console_master.py`, deterministic,
  the mockup's brushed/bevel/bolt language at 2× = 2720×1072) and import it;
  the rack/row plates retire — bays, cells, ledges, rows and chips are
  code-drawn treatments (the mockup's construction).
- **Layout (B):** bays band = 5 bays (B1..B5), each 2×2 cells (P3) with the
  full barrel name at 13 px on the recess + `DROP HERE` on empty cells; per-bay
  salvo ledge (seven-seg digits + `SALVO s` adjacent, T8). Wells band = barrel
  inventory (6 rows, drag sources) left, ammunition pack cards (P2 grid) right.
- **Ink/hierarchy (T3/T6):** 13 px floor everywhere (sizes registered in
  `Router.FONT_SIZE_ITEMS` — kills HIGH-1's 12 escaping overrides); names BONE,
  captions on the light ramp ≥4.5:1 (the report's CAP/CAP_VOID tones).
- **States (T7):** `READY`/`▲ OVER CAP` chip on the bay head (shape + label);
  never colour alone.
- **Data (P5):** pack wording carries unit words (`HELD 60 ROUNDS`,
  `HOLD 30 UNITS`); every datum of `09 §12`/CONTRACTS §17 survives — a dropped
  datum is HIGH.
- **Inspector (P4/T5):** 2–3 body lines via the existing `inspect_requested`
  seam; the pane footer caption dies (LOW-3).
- **Resolution law (P6/T1 condition):** no absolute pane rects — derive from
  the host rect (anchors/containers), and verify at ≥3 window sizes in a
  **standalone** run (godot-ai cannot change resolution: AGENTS.md gap; also
  backlog row L222): 1280×720, 2560×1080, 1280×1024 against the three proofs.
- **Docs:** the ticked values land as dated amendment blocks (UI_SPEC §3.10,
  STATION_HUB §5.11) with the reversal path per block (the D13 wave's deferred
  boundary work; `18_engine_spec.md` stays owner-locked).

## Pinned interfaces (do not change; the suites and the shell read them)
- Panel contract (`station.gd:12-32`): `signal launch_requested()` (not yours),
  `func refresh_profile(key)`, `func focus_primary()`, `func disarm() -> bool`,
  `signal inspect_requested(title, body, danger)` (`station.gd:323-324`
  connects it).
- `set_selected_rack(rack)` / `selected_rack()` semantics (ember frame =
  presentation only, writes nothing).
- The drag seams (`drag_barrel`, `drag_inventory`, `can_drop`, `drop`) and the
  §13/§16 transaction behaviour (refusals write nothing).
- CONTRACTS §17 seams (batteries = W-cell index lists) and 09 §12's 5×4
  hardcap with silent refusals.

## Tests that move (and why)
`test_s15_armory_layout.gd` pins the superseded S15 ink-fit law —
`INK = Rect2(7,49,180,84)`, `INK_ROWS = (49,132)`, `SLOT_PITCH = 34.5`, master
194×182 (`test_s15_armory_layout.gd:38-44`) — for the 4-in-a-row rack plate
that P3 replaces with 2×2 code-drawn cells. Re-derive those numbers from the
new geometry and re-pin; state every moved number in your report. Also expect
touch-points (structure/naming assertions) in `test_p2b1_outfitting_panel.gd`,
`test_s10_armory_input.gd`, `test_d7_armory.gd`, `test_s15_battery_cap.gd`,
`test_s11_describe.gd`, `test_s11_inspector.gd` — update them to the new node
names without weakening what they assert. New suite `test_s18_armory_rework.gd`
gates the D13 floors (13 px ink, ≥4.5:1 captions, P5 wording, P6 derivation).
**Gate law: 877/0 at start; add rows, never lose one.**

## Hard rules
- The brief is law: a number you cannot derive from it or the pinned docs is
  **PROPOSED with its reversal** in your report — never invented silently.
- No paid calls; the console master is scripted and deterministic (the R1
  re-render check needs byte-identical output).
- Never edit `docs/gameplay/18_engine_spec.md`; never touch other panes'
  files; never re-key art by hand.
- Every Godot run is bounded (`--quit-after`); no command left in the
  background (three workers wedged otherwise).

## Owner tick list (2026-09-25, the acceptance)
T1 y — **all resolutions must work** (P6 + standalone verification) ·
**T2 = B** · T3 y · T4 y · T5 y · T6 y · T7 y · T8 y. Layout-language adoption
across the game is deferred — out of scope.

## Output contract
`Slices/S18-armory-rework/S18-B1_report.md` (REPORT template ≤120 lines):
what now works (measured), every moved test number with its new value, the
PROPOSED values you added (if any) with reversals, the three-resolution
verification evidence, gate line. Close-out per SLICE.md + the WAVEBOARD law
(gate ×2 hermetic, `verify_wave.py verify`, WAVEBOARD/dispatch one-liners,
MASTER_REPORT §6 recap, wave-boundary commit).
