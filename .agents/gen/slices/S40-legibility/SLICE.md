slice: S40
phase: P3
lane: code            # code | design
status: done          # draft | active | review | done
gate_baseline: "1267/0"
---

# S40 — The legibility pass (owner playtest #2 follow-up)

## Goal
Answer the owner's follow-up to playtest #2: the ARMORY's installed-modules
overview has no background, the OVERVIEW tiles' icons and texts are unreadable on
their own background, and the owner asked for a review of visibility and
composition across every pane. Do the review, then cure what it finds.

## In scope
- **The review** — `S40_REVIEW.md`: every station deck rendered at 1920×1080 and
  every visible text label measured for WCAG contrast against the framebuffer
  behind its own ink rect (`tests/probe_s40_panes.gd`).
- **T-171** — the caption ink (`text_caption` / `text_caption_void`; the shared
  `SectionHeader` / `StationCaption` / `FlavourText` variations moved onto it).
- **T-172** — the ARMORY's FitCells left column gets a background (the flat
  Tokens box, A5.3/A5.4's inner-surface chrome).
- **T-173** — the OVERVIEW tiles' tinted glyphs and their title/caption ink.

## Out of scope
- **T-174/T-175/T-176** — the LAUNCH briefing column, the four header-caption
  surfaces, the SERVICES staged row. Each needs its own surface decision and
  three of the four touch a pinned idiom; recorded with cites and left for the
  owner's ruling.
- The AUCTION family-tab ink and the SHIPYARD `NOMINAL` reads (both pinned
  idioms; see `S40_REVIEW.md` "After").
- Any art, audio or catalogue work; no new assets.

## Acceptance criteria
- [x] AC1 — the caption variations carry `text_caption`, and `text_caption`
  clears WCAG AA 4.5:1 against every registered surface fill.
- [x] AC2 — `text_dim` keeps the disabled jobs (`Button` / `PopupMenu` /
  `TabBar` / `TabContainer` `font_disabled_color`).
- [x] AC3 — every ARMORY FitCells left-column label has an opaque flat surface
  between it and the deck backdrop.
- [x] AC4 — the four tinted OVERVIEW tile glyphs modulate the caption ink; the
  two untinted stay `Color.WHITE`; the tile title/caption clear AA on the slab.
- [x] AC5 — the measured below-AA share across the eight decks drops from
  241/607 (39.7 %) to 34/610 (5.6 %), and below-3.0:1 from 47 to 5.

## Files (the wave's file set)
- `tools/build_theme.gd` — the two tokens and the three variation wires.
- `ui/theme/vajb_theme.tres` — the same change applied in place (the uid lines
  preserved; the generator writes a uid-less file, see T-177).
- `ui/station/armory_panel.tscn` — `FitLeftBox` / `FitLeftInset` / `FitLeftStack`.
- `ui/station/overview_panel.gd` — the tinted glyph's modulate, the unhover, the chevron.
- `tests/test_s40_legibility.gd` — new (8 rows).
- `tests/probe_s40_panes.gd` + `.tscn` — new (the review tool, outside the gate).
- `docs/design/UI_SPEC.md` §16; `.agents/gen/slices/S40-legibility/`.

## Evidence
- `S40_REVIEW.md` — the measured review, before and after.
- `tests/test_s40_legibility.gd` — the gate pin.
- Rendered frames: `/tmp/vajb_review/` (probe output; not committed).

## Reversal
`git revert` the wave's commit: the two tokens and the three variation wires, the
armory column's box, the tinted glyph's modulate, and the new test.
