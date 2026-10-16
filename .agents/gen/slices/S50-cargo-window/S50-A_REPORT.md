# S50-A — container out-of-bounds audit (report)

## Result
At HEAD (2d620ae) both new cargo surfaces escape their host panel in reachable
states: the armory's CARGO HOLD block (A19) and the launch manifest (A20) are flat
VBoxes with no scroll, clip or height bound, and their 76 px rows (A17-capped at 6,
plus band, headers and tail) inflate their stack's minimum far past the bounded
panel — the seed case, confirmed structurally. Beneath that, the armory left
column's fixed stack was already over-subscribed on every hull whose slot matrix
has 4+ rows. No ScrollContainer can be driven past its parent in these files (the
escapes go around them; the latent failure inside them is collapse-to-zero); no
fixed column set escapes at the base 1920×1080 shell — the container minimum chain
absorbs them into the column widths.

Graded at HEAD per the brief. The orchestrator's in-flight A21 re-work (uncommitted:
`Summary.build_window` scroll windows + `populate_window` in cargo_summary.gd,
re-hosted in armory/launch) removes the F01/F03 escape route; F02 survives it
(forward note). Where the working tree moved under this audit, every cite below was
re-pinned to the HEAD blob with `git show HEAD:`.

## Acceptance answers
1. Armory FitLeft column — yes, besides the cargo block. (a) The stack's own fixed
   minimum (slot grid rows × 48 px + CELL INFO + EQUIPPED caption, no cargo block)
   exceeds the bounded FitLeftBox on every hull with a 4+ row matrix
   (ship_fit.gd:80-91 — vanguard/miner/trader/corvette/patrol 4 rows, freighter/
   gunship 5, destroyer 6; derived stack minimum ≈ 376/428/480 px vs ≈ 356 px
   available) — the equipped caption and cell-info lines spill past the panel
   bottom (F02; derived, verify on screen). (b) Horizontally nothing escapes: the
   ammo row's 802 px fixed minimum propagates through BrowserScroll (horizontal
   scroll disabled ⇒ the scroll's minimum includes the child's) and the pane
   absorbs it — with F05's caveat about where that minimum is spent.
2. Launch BriefRoof column — the manifest is the only escape (F03). The briefing
   rows' value labels have no trim/autowrap but every string source is bounded
   (the seven sector row names, catalogue words, grouped digits), so their minimum
   widths stay inside the 560 px roof plus the pane's slack; no other overflow risk.
3. Station pane host — module panes do NOT clip. `clip_contents` appears nowhere in
   station.gd or the audited panes (only armory_panel.gd:2509's chip sets it on
   itself); ModuleHost is a PanelContainer (station.tscn:191-196), HostMargin a
   MarginContainer (:198-204), and the panes are EXPAND_FILL children of
   `_service_host` (station.gd:1314-1340). Overrunning content therefore draws
   straight over the shell's bands — which is exactly what F01/F03 do. The host's
   own layout is sound; the escapes are pane-internal.
4. HUD flight cargo block — the A17 cap is airtight. `_refresh_cargo_block`
   (hud.gd:1475-1498) shows `mini(entries, CARGO_BLOCK_ROWS)` rows plus at most one
   tail row; the rows are single-line HudReadout labels (no autowrap), so the
   block's height is bounded at header + 7 rows. At HEAD the shared builder read
   the same one-home consts (cargo_summary.gd:15, 238, 261 → hud.gd:204-205).
5. ScrollContainers — none can be driven past their parent. EquippedScroll
   (armory_panel.tscn:206-210) and BrowserScroll (:247-251) are EXPAND_FILL inside
   bounded container chains; EmptyScroll (:377-383) is min (0,22) inside the 92 px
   WellsRow; the overlay's CargoScroll is capped by `_fit()`
   (cargo_overlay.gd:658-665: `custom_minimum_size.y = viewport·0.8 − margins −
   inset` — the bounded-height precedent, intact). The reachable failure mode is
   the opposite one: a scroll collapses to ~0 height when its enclosing stack
   over-constrains (F01/F02 blast radius).
6. Fixed column sets — no reachable escape at the base shell. The ammo row's fixed
   set is 24+160+200+96+130+96 px + 6×12 separations + 24 inner margins = 802 px
   (armory_panel.gd:223,231,341,351 + the row build at 1697-1853); the minimum
   chain hands the right column exactly that, and the pane is ≈ 1452 px. Nearest
   hazards: the tab strip's aggregate minimum (F05) and any future host narrower
   than the 1920 base. The band-vs-row seating drift (F04) is a mis-seat, not an
   escape.

## Findings
F01 | vajb-orbit/ui/station/armory_panel.gd:3319-3323 (+3337) | HIGH | the A19 CARGO HOLD block is a bare caption+rows VBox appended to FitLeftStack; populate_rows' rows are 76 px, cap 6, plus band + category headers + tail ⇒ ≈ 630 px of new minimum height against a ≈ 356 px bounded panel — with any hold content on any hull the rows escape over FitFoot, over PaneFoot (the REMOVE / BUY & FIT plates) and past the pane onto the shell, and the over-constraint collapses EquippedScroll to ≈ 0 (the equipped list vanishes) | bound the block — a ScrollContainer owning the stack's leftover height (the overlay's `_fit()` route) — and free slack for it (F02); the in-flight A21 `build_window` is that fix's shape.
F02 | vajb-orbit/ui/station/armory_panel.tscn:130-134 (FitLeftStack, `size_flags_vertical = 0`) | MED | the left stack's fixed minimum (grid rows × 48 + captions, CELL INFO ≈ 92 px, EQUIPPED caption) already exceeds the bounded FitLeftBox on 4+ matrix-row hulls (derived 376-480 vs ≈ 356 px, hulls per ship_fit.gd:80-91) — at HEAD the equipped/cell-info chrome spills past the panel without any cargo block; after the in-flight A21 window the same over-subscription leaves the new cargo scroll ≈ 0-32 px tall even on the fighter, so the window is bounded but unreadable | give the stack a real budget: shrink or bound what rides above the window (cell-info, equipped) or scroll the stack itself; do not rely on slack only the fighter's 3-row grid leaves.
F03 | vajb-orbit/ui/station/launch_panel.tscn:84-87 (+ launch_panel.gd:577-583) | HIGH | the A20 manifest populates %CargoList, a bare VBox in BriefBox with no scroll/clip/bound; with hold content the rows (76 px, cap 6 + band + headers + tail ⇒ ≈ 610 px) plus the nine briefing rows push BriefBox's minimum ≈ 450 px past BriefRoof's height — the manifest and BriefNote escape over PaneFoot (the LAUNCH plate) and past the pane | the same bound as F01 (the in-flight A21 window does exactly this); keep the note after the window (the s47 briefing-order law).
F04 | vajb-orbit/ui/station/armory_panel.gd:4269-4290 | LOW | the AMMUNITION band's HELD/STATE/COST captions seat ≈ 120 px right of their columns: the band (icon gap + lead + [200, 96, 130], widths at 4261-4264) has no trailing cell for the 96 px BUY chip + 12 separation every ammo row ends with (1811-1824) — derived from the widths, visible in every ammo-tab state; the same drift bites the module rows' band on BUYABLE rows (4591-4594) | append an ACTION_INLINE.x-width trailing spacer cell to the band, or seat the band off the live row layout (A16's `_measure_title_col` route).
F05 | vajb-orbit/ui/station/armory_panel.gd:329-341 (+4228-4238) | LOW | the FamilyTabs strip's ten text-sized chips (~85-110 px each + 9×6 separations, derived ≈ 900-1100 px) carry no managed budget — their minimum propagates through MenuSector/FitRight and silently consumes FitLeft's slack; on any host narrower than the 1920 base, or one more tab, the strip is the first horizontal escape | pin a strip budget (wrap, scroll or a measured seat like the band cells).

## Open questions
- Post-A21 armory: with the window expand-filling the stack, F02's over-subscription
  gives the cargo scroll ≈ 0-32 px of height (derived) — bounded but unreadable.
  The stack needs a slack source; that is a pin-adjacent layout decision (bucket 2/3).
- F02's numbers are derived from constants plus estimated caption line heights
  (±10-15 %); the fighter sits ≈ 32 px under the bound in the derivation — confirm
  on screen before tiering it.
- Shell arithmetic (pane content ≈ 1452×824, left column ≈ 376/356 px) is derived
  from station.tscn/station.gd bands, not measured; it sets the overflow magnitude,
  not the findings' existence — F01/F03 hold under any plausible allocation.

## Evidence
- Read: the six brief files (working tree) + `git diff` vs 2d620ae for the five
  files the re-work touches; UI_SPEC §3.10 Amendment 5 (L643-716) and §20
  (L2030-2062) by range; every cite re-pinned to the HEAD blob via
  `git show HEAD:<path> | rg -n`.
- Decisive constants: hud.gd:204-205 (CARGO_BLOCK_ROWS 6, CARGO_MORE_FORMAT);
  armory_panel.gd:223/231/341/351 (200/76/32-chip/96-32 columns), 361-362
  (PLATE_SIZE 48, sep 4), 172 (equipped row 36); cargo_summary.gd:18-21, 370
  (76/40/130/150); ship_fit.gd:80-91 (matrices, max 5 cols × 6 rows); station.gd
  191-198 (bands) and 783 (drawer slide 362); station.tscn 191-204.
- Seed-case mechanics: MarginContainer forces FitLeftStack to the full content
  rect regardless of its shrink flag, so the stack's minimum includes the cargo
  block's; a VBox over its panel's rect does not clip, so the excess draws below
  it. The A17 cap bounds the row COUNT, not the stack height — 6×76 + band +
  headers + tail + caption is the ≈ 630 px that cannot fit.
