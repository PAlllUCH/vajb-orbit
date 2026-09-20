# Batch-2 playtest lane — brief (2026-09-18)

Independent of engine waves (file-disjoint) and can run **in parallel** with
any engine wave. Source: `docs/gameplay/19_testing_notes.md` (owner's
playtest notes, 2026-09-18; moved from the root 2026-09-20).

Items:

- **B2-1 — hover look.** Menu button hover state reads wrong on the shipping
  screen (owner report; verify against `MAIN_MENU_V2.md` §4 hover policy and
  the baked hover-plate art). Find the actual defect in the running game or a
  headless probe before changing anything.
- **B2-2 — blurry backdrops.** Sector/menu backdrops render soft (likely
  texture filter/mip or scale mismatch — check import settings in the
  shipped `@2x` cuts vs scene scale, `UI_SPEC` crispness rules).
- **B2-3 — minimap zoom inverted.** Minimap zoom direction is backwards
  (`ui/hud/minimap.gd` + HUD zoom buttons; the wheel-zoom camera may share
  the confusion — fix the HUD path only).

Worker: one worker, all three, sequential. File set (set `VAJB_WORKER_FILES`
accordingly after inspecting the defect — declare the final set in the report):
`vajb-orbit/ui/hud/**`, possibly `vajb-orbit/ui/screens/main_menu.gd`,
`vajb-orbit/assets` read-only. Same global rules as the engine waves
(AGENTS.md, no editor, bounded headless runs, test gate green before the
report, probes deleted). **Verification is visual, so do the live editor or
screenshot step with the owner** (godot-ai editor screenshot at ≥1152 px) —
a worker cannot approve its own hover look.

Report: `.agents/gen/batch2_report.md`. On closure, the three dispositions in
`docs/gameplay/19_testing_notes.md` get ticked and the file is absorbed into
an IMPLEMENTATION_PLAN amendment (per `docs/design/CLEANUP_PLAN.md`).
