# S40_BRIEF — the legibility pass (owner playtest #2 follow-up)

**Wave:** S40 · **Lane:** code · **Gate baseline:** 1267/0 (S39's close).
**Slice folder:** `.agents/gen/slices/S40-legibility/`.
**Carries:** T-171/T-172/T-173 (filed and closed here); T-174/T-175/T-176 filed open.

## 1. The law to read, in order
1. `AGENTS.md` (agent rules, the UI composition ruling, the designer-lane format).
2. `docs/design/UI_SPEC.md` §1 (the contrast floor), §3.10 Amendment 3 (the ink
   floor and the CAP/CAP_VOID cure), Amendment 4 A4.3 (the armory palette),
   Amendment 5 A5.1–A5.4 (chrome by cut size; the per-surface table) — range-read.
3. `docs/design/STYLE_BIBLE.md` §"UI" (the palette's own contrast note).
4. `.agents/gen/_state/WAVEBOARD.md` §Queued.

## 2. The owner's request (verbatim, 2026-10-10)
> In armory the overview of installed modules is hardly readible, need a
> background. the icons in Overview are hardly readible on the background, same as
> texts. in general i think a review of visibility is needed and composition.
> maybe run game, take screenshots at full resolution (best quality) and check
> each pane?

## 3. What is already measured (with `file:line`)
- **The caption ink is one token.** `tools/build_theme.gd:357,365,367` wires
  `SectionHeader`, `StationCaption` and `FlavourText` to `text_dim` (`#6b7484`,
  `:81`). Rendered and sampled (`S40_REVIEW.md`): **241 of 607 text labels across
  the eight station decks are below WCAG AA 4.5:1, and 235 of the 241 wear that
  token** — 2.85–2.96:1 on the shipped row/plate fills `#2b2e31`–`#2d2f33`,
  4.02–4.42:1 on the void seats, worst 2.04:1.
- **The cure already exists, on one path.** `build_theme.gd:99` defines
  `armory_caption` `#acb2ba`; `armory_style.gd:38` documents it as *"Measured >=
  4.5:1 against the plate (HIGH-2's cure)"*. Measured on the same fills:
  6.15–6.77:1. The armory's `ROLE_CAPTION` labels clear AA; the labels that wear
  the shared theme variations do not.
- **The law already says so.** UI_SPEC §1 records `text_dim` on `void_base` ≈
  **4.0:1** ("large text / labels only, never body"); §3.10 Amendment 3 requires
  the light ramp for captions and names "`text_dim` captions (HIGH-2)" as the
  reversal.
- **The ARMORY's left column has no roof.** `armory_panel.tscn:119,145` —
  `GridBlock` (the SLOT LAYOUT grid) and `CellInfoBlock` are plain
  `VBoxContainer`s inside `FitLeft`; the deck backdrop is a child of the module
  host, so the host's banded `ui_panel_frame` shows the art through its centre.
  Measured: `SlotCaption` 2.79:1; the CELL INFO block draws across a bright brass
  cartridge in BG-1.
- **The OVERVIEW tiles do have a background.** The C1 `ui_tile_slab` canvas is
  opaque (`#1d1f21`–`#252628`); what fails is the ink on it — the title
  (`SectionHeader`) and caption (`StationCaption`) at 3.32–3.55:1, and the glyph
  of the four `tinted` tiles (`overview_panel.gd:241`, `_token(&"text_dim")`).
- **The precedent.** S37 already added a token for exactly this reason
  (`text_meta` `#9aa3b0`, `build_theme.gd:82-84`, "the row meta line's own token
  - `text_dim` read under WCAG AA on the dark row plates").

## 4. The pinned interface (verbatim)

The token pair (`tools/build_theme.gd` `TOKENS`):

```gdscript
	&"text_caption": "#acb2ba",
	&"text_caption_void": "#969da5",
```

The three variation wires (`_register_variations`):

```gdscript
	theme.set_color(&"font_color", &"SectionHeader", _c(&"text_caption"))
	theme.set_color(&"font_color", &"StationCaption", _c(&"text_caption"))
	theme.set_color(&"font_color", &"FlavourText", _c(&"text_caption"))
```

Rules that fix the ambiguity:
- `text_dim` **moves nowhere**: it stays the disabled ink (`font_disabled_color`
  on `Button`/`PopupMenu`/`TabBar`/`TabContainer`), the tooltip hint, and the
  deliberately-dim states. A builder may not repoint a *disabled* read.
- The `.tres` is edited **in place**, preserving its `uid://` lines: the
  generator writes a uid-less file (T-177).
- The armory's box is a plain `PanelContainer` (the theme's own flat `panel`
  stylebox = `void_panel` + 1 px `metal_mid`), wrapped in a `MarginContainer`
  (12/10) — containers and relative positioning only (A5.2(i)).
- The tinted tile glyph's modulate is `_token(&"text_caption")`; the two untinted
  tiles keep `Color.WHITE`.

## 5. Spec extract (UI_SPEC §1, §3.10 Amendment 3, verbatim)

> - Contrast floor: `text_primary` on `void_base` ≈ 11:1; `text_dim` on
>   `void_base` ≈ 4.0:1 (large text / labels only, never body).

> **Ink (T3/T6).** Floor **13 px everywhere** … Names print **BONE** (the
> style's `bone`); captions use the light ramp — **CAP (172,178,186)** on painted
> metal and **CAP_VOID (150,157,165)** on the host — measured ≥ 4.5:1. …
> Reversal: the 9–13 px override block (HIGH-1), `text_dim` captions (HIGH-2).

## 6. Acceptance list (from the spec extract)

1. **A1** — the caption variations carry `text_caption`, and `text_caption`
   clears AA 4.5:1 against every registered surface fill; `text_dim` keeps its
   disabled jobs. *(T-171)*
2. **A2** — every ARMORY FitCells left-column label has an opaque flat surface
   between it and the deck backdrop. *(T-172)*
3. **A3** — the four tinted OVERVIEW tile glyphs modulate the caption ink and the
   tile title/caption clear AA on the slab. *(T-173)*
4. **A4** — the measured below-AA share drops from 241/607 (39.7 %) to ≤ 40/610,
   and below-3.0:1 from 47 to ≤ 10.
5. **A5** — no shipped test row regresses; the gate's failure count stays 0.

## 7. Worker table

| ID | role | VAJB_WORKER_FILES | deliverable |
|---|---|---|---|
| S40-B1 | builder | `vajb-orbit/tools/build_theme.gd`, `vajb-orbit/ui/theme/vajb_theme.tres`, `vajb-orbit/ui/station/armory_panel.tscn`, `vajb-orbit/ui/station/overview_panel.gd`, `vajb-orbit/tests/test_s40_legibility.gd`, `vajb-orbit/tests/probe_s40_panes.gd`, `vajb-orbit/tests/probe_s40_panes.tscn` | the token pair + three wires, the armory box, the tile ink, the gate pin, the review probe |

## 8. Tests that move

- **`tests/test_s40_legibility.gd`** — NEW, 8 rows (A1 four, A2 two, A3 two).
  The gate's live count moves **1267 → 1275**.
- No shipped row is re-pointed: the tests that touch `text_dim` compare it
  against `_token(&"text_dim")` (a live read), and the token is unchanged.

## 9. Hard rules

- Never edit `docs/gameplay/18_engine_spec.md` (owner-locked) or
  `docs/archive/` (sealed).
- A builder who believes a number is wrong reports it and leaves it.
- The 34 labels that remain below AA are **recorded, not fixed**: four of their
  five causes are pinned idioms (see `S40_REVIEW.md` "After") and moving one is
  an owner ruling.

## 10. Owner tick list

- **T1** — ratify the `text_caption` tone `#acb2ba` (a shared-chrome tone change;
  PROPOSED in UI_SPEC §16.1 A1).
- **T2** — rule on the four remaining pinned-idiom sites (the AUCTION family-tab
  ink, the SHIPYARD `NOMINAL` reads, the SHIPYARD comparison rows' §1-floor read,
  the SERVICES board note) — one line each.
- **T3** — confirm the ARMORY's left column reads right in the live build.

## 11. Close-out

Gate ×2 hermetic; `verify_wave.py snapshot/verify`; `build_code_map.py`;
WAVEBOARD + TICKS + `MASTER_REPORT.md` §6; the wave-boundary commit.
