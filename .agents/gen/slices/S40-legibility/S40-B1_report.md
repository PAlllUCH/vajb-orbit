# S40-B1_report — the legibility pass

**Wave:** S40 · **Slice:** `slices/S40-legibility/` · **Baseline:** `s40_start`
(the pre-S40 tree at `ee2f96b`) · **Gate:** 1267/0 → **1275/0** ×2 hermetic ·
**Model:** executed in-session by the orchestrator on the owner's visibility-review
request (no worker dispatch; the change is ~30 lines of code plus a test, and a
dispatch round-trip would have cost more than the work). **This is the same
disclosed deviation S39 made** (see `S39-B1_report.md` §1).

## 1. What the owner asked (playtest #2 follow-up, verbatim)
> In armory the overview of installed modules is hardly readible, need a
> background. the icons in Overview are hardly readible on the background, same as
> texts. in general i think a review of visibility is needed and composition.
> maybe run game, take screenshots at full resolution (best quality) and check
> each pane?

## 2. The review (the deliverable the owner asked for)
`S40_REVIEW.md` + `tests/probe_s40_panes.gd`: ten decks rendered at 1920×1080
into a `SubViewport`, every visible text label measured for WCAG contrast against
the framebuffer inside its own ink rect. **607 labels; 241 (39.7 %) below AA;
47 (7.7 %) below 3.0:1; 235 of the 241 wear one token, `text_dim` `#6b7484`.**

## 3. The findings, their root causes and their fixes

| # | Ticket | Root cause (measured) | Fix | Where |
|---|---|---|---|---|
| 1 | T-171 | `SectionHeader`/`StationCaption`/`FlavourText` are wired to `text_dim` `#6b7484` (`build_theme.gd:357,365,367`) — 2.85–2.96:1 on the row/plate fills, 4.02–4.42:1 on the void seats | `text_caption` `#acb2ba` (+ `text_caption_void` `#969da5`); the three variations move onto it | `build_theme.gd`, `vajb_theme.tres` |
| 2 | T-172 | `armory_panel.tscn:119,145` — `GridBlock` + `CellInfoBlock` are bare `VBoxContainer`s inside `FitLeft`; the host's banded frame lets the backdrop through | `FitLeftBox` (`PanelContainer`, the flat Tokens box) + `FitLeftInset` + `FitLeftStack` | `armory_panel.tscn` |
| 3 | T-173 | the tile glyph (4 of 6) and the tile title/caption all read `#6b7484` on the opaque C1 slab (3.32–3.55:1) | the tinted glyph's modulate + the unhover + the chevron move to `text_caption` | `overview_panel.gd` |

## 4. Acceptance list, item by item
- **A1 (T-171)** — MET. `test_a1_the_caption_variations_carry_the_caption_token`;
  `test_a1_the_caption_ink_clears_aa_on_every_surface` (8 surface fills, all
  ≥ 4.5); `test_a1_the_pre_wave_ink_would_have_failed_those_surfaces` (the
  negative control); `test_a1_text_dim_keeps_the_disabled_jobs` (4 types).
- **A2 (T-172)** — MET. `test_a2_the_armory_left_column_has_an_opaque_surface_behind_it`
  (5 labels, each with an opaque flat roof carrying the 1 px border);
  `test_a2_the_left_column_keeps_its_sectors_and_names` (S32's P38 row still holds).
- **A3 (T-173)** — MET. `test_a3_the_tinted_tile_glyphs_wear_the_caption_ink`
  (6 glyphs; 4 caption, 2 white); `test_a3_the_tile_title_and_caption_clear_aa_on_the_slab`.
- **A4 (re-measured off the render)** — MET. **241/607 (39.7 %) → 34/610
  (5.6 %)**; below-3.0:1 **47 → 5**. Per deck: armory 32→0, armory/battery 24→0,
  refinery 40→0, exchange 18→0, launch 59→0, overview 58→0, auction 44→15,
  shipyard 67→25, services 49→13.
- **A5** — MET. Gate 1267 → **1275/0** ×2 hermetic; no shipped row re-pointed.

## 5. The 34 that remain (recorded, not fixed)
None is the caption token. 9 are the AUCTION family-tab labels (3.47:1, the
theme's `font_unselected_color`, `build_theme.gd:344`); 18 are the SHIPYARD
comparison rows (4.08:1, `text_dim` on `void_panel` = §1's own documented ≈4.0:1
floor); 3 are the SHIPYARD `NOMINAL` reads (P13 pins `text_dim`); 2 are the
SERVICES board note + roll countdown (`contracts_panel.gd:677,681`); 5 are the
SERVICES staged row (**T-176**, the row's own dim). Four of the five causes are
pinned idioms → the owner's ruling (brief §10 T2).

## 6. Files changed
`tools/build_theme.gd` (+9), `ui/theme/vajb_theme.tres` (+5/−3, uid lines
preserved), `ui/station/armory_panel.tscn` (+27/−11), `ui/station/overview_panel.gd`
(+5/−3), `tests/test_s40_legibility.gd` (new, 8 rows), `tests/probe_s40_panes.gd`
+ `.tscn` (new, the review tool), `docs/design/UI_SPEC.md` §16,
`.agents/gen/slices/S40-legibility/`, plus the state files.

## 7. Deviations and follow-ups
- **In-session execution** (no builder/reviewer/fixer dispatch) — disclosed, as in S39.
- **T-177 filed**: `tools/build_theme.gd` writes a **uid-less** `.tres` while the
  repo's file carries `uid://` lines on the theme and every ext_resource, so a
  plain regeneration produces a 23-line structural diff and drops the theme's
  uid. The wave edited the `.tres` in place (S37's precedent) to avoid it. The
  generator should adopt the existing uid or the repo should accept the drop —
  the owner's call.
- **T-174/T-175/T-176** stay open (brief §10 T2).
