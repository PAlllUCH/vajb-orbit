# S50-A — container out-of-bounds audit (review, read-only)

You are worker S50-A, a code reviewer. This is a READ-ONLY audit: you write
nothing except your report file.

## Goal
Find every place in the station-plane UI where a container's content can
visually go out of bounds — children whose combined minimum sizes exceed the
container's available rect, lists with no scroll or clip that grow past their
panel, fixed columns summing past the surface width, ScrollContainers whose
height is unbounded (so the scroll never engages), and EXPAND misuse that
steals or starves space.

Seed case (the owner's report, already confirmed on screen): the armory's
`CargoRows` (built by `_build_cargo_preview`) and the launch manifest rows grow
past their host panel and cover the footer — a VBox appended to a stack with no
scroll and no height bound.

## Files to audit (read these; nothing else needs reading)
- `vajb-orbit/ui/station/armory_panel.gd` + `armory_panel.tscn` (FitLeft column, browser band, footer)
- `vajb-orbit/ui/station/launch_panel.gd` + `launch_panel.tscn` (BriefRoof column)
- `vajb-orbit/ui/station/cargo_summary.gd` (the shared row builder)
- `vajb-orbit/ui/dialogs/cargo_overlay.gd` + `.tscn` (the reference window; its `_fit()` is the bounded-height precedent)
- `vajb-orbit/ui/hud/hud.gd` (flight cargo block, A17's cap)
- `vajb-orbit/ui/screens/station.gd` (the pane host: do module panes clip their children?)

## The law to measure against
`docs/design/UI_SPEC.md` §3.10 Amendment 5 (A5.1–A5.3, containers not
coordinates) and §20. Read only the ranges you need; both files carry generated
section indexes at the top.

## Findings format (the only deliverable shape)
One line per finding:
`F## | file:line | HIGH|MED|LOW | <what can escape and when> | <suggested fix>`
Severity: HIGH = visible overlap/clipping of content or chrome in a reachable
state; MED = latent (a data size or hull that reaches it); LOW = style-law
drift without a reachable escape.

## Acceptance list (answer each, one line)
1. Armory FitLeft column: does anything other than the cargo block risk overflow, and at what hull/cell count?
2. Launch BriefRoof column: same question.
3. The station pane host: do module panes clip, or can any module's content escape the pane?
4. HUD flight cargo block: is the A17 cap airtight (rows + tail can never exceed the block)?
5. Any ScrollContainer in these files whose height can be driven past its parent?
6. Any fixed-width column set (sum of custom_minimum_size + separations) that can exceed its row's width?

## Report
Write `.agents/gen/slices/S50-cargo-window/S50-A_REPORT.md`, ≤120 lines:
Result (2-3 lines), Acceptance answers (numbered, cite file:line), Findings
(the F## lines), Open questions, Evidence (commands + decisive output only).
Note: the orchestrator is concurrently re-working the cargo surfaces; grade
what you see at HEAD (commit 2d620ae) — findings there are still graded.
