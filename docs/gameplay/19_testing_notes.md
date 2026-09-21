# Vajb Orbit — test notes (wave-1 review → batch 2)

Living notes from the live walkthrough. **Nothing here is fixed yet** — this is the batch-2
work list. Owner observations are verbatim-quoted where useful.

Date: 2026-09-18. Wave-1 fix trail: `.agents/gen/fix_wave1_*` (task, w1–w5 reports, review,
w7 fixes, review2). Wave-1 amendment: `docs/design/IMPLEMENTATION_PLAN.md` §9.8.

---

## Owner findings to fix in batch 2

### B2-1 — Menu hover look (design change, owner decides)
> "i dont like static square border as glow. if we make it somewhat special it can stay."

Current hover state on the verb plates = the 6 px ember glow halo (`menu_glow`, spec'd in
`MAIN_MENU_V2.md` §9 / `UI_SPEC.md` §2.2 amendment) plus the hover plate art's baked ember
rim — the two together read as a static square border. The focus ring is confirmed gone
(theme `MenuButtonPlate/focus = StyleBoxEmpty`, verified live).
**Direction for batch 2:** keep a hover affordance only if it is "somewhat special" (e.g.
animated ember flicker/breathing on the halo, directional glow, ember carried by the tick
band instead of a rectangle). Needs an owner pick before implementation; then a small
`MAIN_MENU_V2` amendment + coder task.

**Batch-2 verdict (2026-09-21): not fixed, not approved.** Not a button-code or colour
defect — the hover plate art ships as a whole sheet cell, so the theme stretches a mostly
transparent canvas and the plate renders as a thin bar; the look direction pick (flicker /
directional glow / tick-carried ember) is still the owner's. Evidence:
`.agents/gen/batch2_report.md` §3 B2-1 and `.agents/gen/ui_chrome_regression.md`.

### B2-2 — Station backgrounds still blurry
> "while on station the backgrounds are still blurry."

The blurred hangar backdrop is the intended art (scrim raised to 0.84 in wave 1 for text
contrast); the owner wants the background itself addressed, not just the scrim. Candidates
for batch 2 (needs direction + likely an art batch):
- new station backdrop art at document scale (kie.ai, cost approval required; generation
  logged per AGENTS.md);
- or a deliberately sharp foreground layer over the blurred backdrop;
- or replace the backdrop with a constructed hangar scene (plates/panels) instead of a photo.
Also still deferred from wave 1: the **credits frame** re-design ("maybe new one") and the
**flight-scale ship cut** (ship reads as a scribble at ~60 px).

**Batch-2 verdict (2026-09-21): not a filter or mip defect — source resolution.** Every
`@2x` cut was deleted by the redesign, so the backdrops upscale above 1080p; the display
target to design for is still the owner's call. Evidence: `.agents/gen/batch2_report.md`
§3 B2-2 and `.agents/gen/ui_chrome_regression.md`.

### B2-3 — Minimap zoom is inverted — FIXED (batch 2, measured)
> "minimap works in reverse + with -"

Current wiring: `ZoomPlus` emits `+1` → game.gd adds +800 to the world radius
(3200 → 4000) = the map shows **more** world, i.e. zooms **out**; `ZoomMinus` zooms in.
Owner expects `+` = zoom in. Batch-2 fix: invert the emitted deltas (or the step sign) so
`+` reduces the radius (zoom in) and `−` increases it (zoom out); keep the clamp 800–6400
and the step 800. Landed 2026-09-21, recorded in `IMPLEMENTATION_PLAN` §9.8 item 6
with the measured bindings (see the fix note below).

**Fixed 2026-09-21 (batch 2, measured).** `ui/hud/hud.gd`: the zoom deltas are renamed to
the direction they mean and the two `pressed` bindings are swapped, so `%ZoomPlus` emits
`-1` (world radius 3200 → 2400 = zoom in) and `%ZoomMinus` `+1` (3200 → 4000 = zoom out);
clamp 800–6400, step 800 and the wheel-zoom camera are untouched. Evidence:
`.agents/gen/batch2_report.md` §3 B2-3.

### B2-4 — PASSED in wave 1
> "docking to kelper works."

ESC → dock to Kepler-9 confirmed working in the live build (hint + route both verified).

---

## Still awaiting the owner's eye (not yet tested)

- **Station**: OUTFITTING `HELD / MAX` column alignment (reviewer measured ±0.00 across six
  states — needs a look), REFINERY three-button sizes (360×88 ×3), REPAIRS/LAUNCH frames
  showing the hull render (damaged variant when hurt).
- **Flight**: target interceptor sprite + top-right TARGET panel (name / hull / shield /
  distance), thrust inertia (coast ~3 s), mouse-wheel camera zoom 0.70–1.50.
- **Menu**: keyboard `Enter` activation of the focused verb — one injected Enter during
  testing did not register (input-injection may be at fault; verify by hand in batch 2).

## Known low-severity items (from the wave-1 reviews, not fixed)

- Wave-1 review findings (reported in the fix-wave-1 chain, now consolidated
  into `.agents/gen/MASTER_REPORT.md`): N-2/N-3 — the Oxanium display-role guard is a
  non-halting, export-stripped `assert` that accepts any `FontVariation`.
- N-5: the `"HOSTILE"` string has two owners (`game.gd` / `hud.gd`) — mock-era; P2 replaces
  the mock target with real ship data.
- INFO: `assets/ships/ship_vanguard_side.png` predates the display pass (shimmer context);
  canvas filter is now Linear Mipmap (set 2026-09-18 via the project-settings route), so
  mip sampling is live — confirm no side effects when downscaling at 720p.

## Context pointers

- Wave-1 evidence: the fix-wave-1 report chain was consolidated into
  `.agents/gen/MASTER_REPORT.md` (2026-09-21 cleanup).
- Contract amendments: `IMPLEMENTATION_PLAN.md` §9.8, `MAIN_MENU_V2.md` §16, `UI_SPEC.md`
  §2.1–§2.2, `STATION_HUB.md` §5.7.
- Fonts: `vajb-orbit/assets/fonts/` (OFL, provenance in its README).
