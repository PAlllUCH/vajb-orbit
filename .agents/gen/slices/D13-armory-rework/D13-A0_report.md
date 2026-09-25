---
slice: D13
worker: D13-A0
model: "design session (interactive, mimo-v2.6-pro)"
status: actionable
gate: "866/0 (this wave writes no code; gate run at close-out)"
---

# D13-A0 report — armory rework design

## Result
The ARMORY rework is designed and owner-ticked: **approach B (full-width
dashboard)**, a landscape console at the pinned 1392×610 host, resolution-proof
(proportional derivation + three canvas proofs). Mockups are byte-deterministic
(re-render md5-identical). All 12 audit findings + L208 are addressed or
deferred with a reason (table). No code, no docs; the ticked values ride this
report to the docs at the next boundary.

## Today, measured (2026-09-25 live capture, 1920×1080, fresh standard fit)
`_evidence/armory_live_2_1920x1080.png` (+ `_1100.jpg`), captured this session
via godot-ai (station scene, profile save redirected to a scratch file +
`reset_to_defaults`, W1 chip `grab_focus` → inspector published "W1 LASER
MKII"); crops re-checked against the D12-A0 audit:
- console plate 872 wide inside a 1392 host → **~520 px dead zone** right of the
  plate and the INVENTORY/AMMUNITION wells below the fold (0 of 6 pack cards
  visible; HIGH-4 confirmed). Root cause: a **portrait canvas (872×956) ruled
  for a landscape host (1392×610)**.
- fitted cells = unlabelled machined blocks: name alpha 0 + 11 px `✕` + a red
  mark (HIGH-5, B1 crop); captions 9–13 px on metal 1.9–2.8:1 (HIGH-1/2); drop
  cue clips mid-word in 3 of 4 bays (LOW-1); salvo drum nearly invisible with
  `SALVO s` ~59 px away (MED-4).
- stays: the rail (legible, ember selection), the painted console identity, the
  4+1 bay rhythm, the ember selection frame.

## Approaches (owner chose from rendered mockups)
- **A — two-column workbench + supply drawer** (runner-up, kept rendered):
  safest for the ink floors, uses the dead zone; ammo/shop one tab away.
- **B — full-width dashboard — CHOSEN (owner 2026-09-25):** 5 bays across the
  top, barrel inventory + ammunition wells side by side below; nothing hidden.
  Density risk resolved by 2×2 rack cells: full names at 13 px one line
  (RAILGUN = 58 px at 13 px DejaVu, the widest family word).
- **C — slim console + plain side wells:** rejected (mixed painted/plain
  regions muddle the §3.9 instrument language).

## Design of record (B), by section
1. **Host geometry:** pinned host rect (452,214)+1392×610 at base; console
   re-rules **landscape 1360×516** (P1).
2. **Layout:** bays band (5 bays × 2×2 cells) on top; wells band below =
   BARREL INVENTORY (6 rows, drag sources) left, AMMUNITION (6 pack cards)
   right. Every rect derives from the host rect proportionally (P6).
3. **Hierarchy:** battery map first, salvo per bay on its ledge, inventory
   second, pack cards third — the owner's always-visible set in one glance.
4. **Ink:** 13 px floor everywhere; names BONE on the recesses; captions on the
   light ramp ≥4.5:1 (CAP (172,178,186) on METAL ≈5.5:1; CAP_VOID
   (150,157,165) on the host ≈5.9:1); alpha-0 chip + `✕` die.
5. **States:** `READY` / `▲ OVER CAP` chip on the bay head (shape + label, never
   colour alone); `DROP HERE` at 13 px inside empty cells; the ember fit line
   is decorative (a name already marks fitted — not a sole state carrier).
6. **Transactions/data:** 5 racks × 4 cells, pack cards, salvo readouts,
   §13/§16 refusals, CONTRACTS §17 seams unchanged; a dropped datum = HIGH.

## Audit findings — addressed (A) / deferred (D)
| Finding | Route |
|---|---|
| HIGH-1 ink 9–13 px, 12 size overrides | A: 13 px floor; sizes in `Router.FONT_SIZE_ITEMS` at impl |
| HIGH-2 captions 1.9–2.8:1 | A: light-ramp captions ≥4.5:1 (P6) |
| HIGH-3 OVER CAP 1.8:1 inverted | A: chevron + label chip on the head (T7) |
| HIGH-4 wells below the fold | A: landscape console (P1) + wells band on-screen |
| HIGH-5 alpha-0 names + `✕` chip | A: names on the rack (T3) |
| MED-1 ammo rows outside the well | A: 2×3 pack-card grid (P2) |
| MED-2 rounds/units mixed | A: unit words on every number (P5) |
| MED-3 no description room | A: 2–3 inspector lines (P4) |
| MED-4 SALVO s 59 px away, alpha-0 line | A: digits + label adjacent; hidden line removed (T8) |
| LOW-1 drop cue clipped | A: `DROP HERE` in the cell (T4) |
| LOW-2 key hints honest | A: kept verbatim |
| LOW-3 duplicated captions | A: pane footer caption dies (T5) |
| L208 head above the plate ink | A: head row above the cells band |

## PROPOSED values (reversal each)
- **P1** console 872×956 → 1360×516 landscape (master re-render 2×).
  Reversal: UI_SPEC §3.10 Amendment 2 values.
- **P2** ammo well 136 tall → 2×3 pack-card grid. Reversal: the 136-tall well.
- **P3** bay cells 4-in-a-row → 2×2 rack. Reversal: the S15 pitch.
- **P4** inspector strip 2–3 body lines. Reversal: single 13 px line.
- **P5** pack wording `HELD 60 ROUNDS - HOLD 30 UNITS` (was `HELD 60/30`).
  Reversal: the old string.
- **P6** resolution law: every pane rect derives from the host rect at runtime
  (proportional, no pinned constants); 13 px virtual ink floor at every canvas.
  Proofs: `_b.png` 1920×1080, `_b_wide.png` 2580×1080 (21:9), `_b_tall.png`
  1920×1536 (5:4) — the canvas_items/expand stretch scales the base canvas
  down and expands it for wider/taller aspects; layout reflows, never clips.
  Reversal: pinned rects.

## Owner tick list (answered 2026-09-25)
T1 y — landscape console, **condition: all resolutions work** (P6 + proofs) ·
T2 **B** · T3 y · T4 y · T5 y · T6 y · T7 y · T8 y. Owner note: the layout
language may later be adopted across the game — **deferred, not this wave**.

## Mockups
`staging/mockup/armory_mockup_v2.py` (deterministic `random.seed(11)`; re-render
md5-verified identical) → `staging/mockup/out/`: `armory_mockup_v2_b.png/.jpg`
(chosen), `_b_wide.png`, `_b_tall.png` (proofs), `_a.png/.jpg` (runner-up),
`armory_mockup_v2_sheet.png` (owner sheet: mockups + ticks + PROPOSED).

## Deviations from the brief
- A0 ran **interactively in the owner's design session** (capture → analyze →
  brainstorm → mockups → ticks), not as a dispatched worker; the queue's A0
  dispatch is skipped/re-scoped. Reversal: dispatch A0 per `D13_prompts.md`.
- Capture route: godot-ai scene run + `game_eval` save (same state as brief
  §2: station scene, fresh profile, W1 in the inspector) →
  `_evidence/armory_live_2_*`; the earlier evidence is untouched.

## Evidence
- Capture chain: `project_run(mode="custom", scene=res://ui/screens/station.tscn)`,
  `game_eval` profile scratch redirect + `reset_to_defaults`, `grab_focus` on
  the first `BarrelName` → inspector "W1 LASER MKII", viewport image saved.
- Determinism: script run twice → `md5sum -c` identical for all mockups.
- Text floor: RAILGUN = 58 px at 13 px DejaVu; cell inner ≥112 px at base.
- Forbidden writes: none — `git status` shows `vajb-orbit/` and `docs/` clean
  at close-out.
