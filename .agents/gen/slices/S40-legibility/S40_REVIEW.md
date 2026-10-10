# S40 legibility review — the station decks, measured off the render

**Wave:** S40 (owner playtest #2 follow-up, 2026-10-10).
**Trigger (owner, verbatim):** *"In armory the overview of installed modules is
hardly readible, need a background. the icons in Overview are hardly readible on
the background, same as texts. in general i think a review of visibility is
needed and composition. maybe run game, take screenshots at full resolution
(best quality) and check each pane?"*

This is the review the owner asked for. Every number below is read off a
rendered 1920×1080 framebuffer, not inferred from data.

## How it was measured

`tests/probe_s40_panes.gd` (not part of the gate) boots `ui/screens/station.tscn`
into a 1920×1080 `SubViewport` over a seeded `PlayerProfile`, walks all eight
decks plus the ARMORY's two modes, and for **every visible text label**:

- resolves the label's own ink colour — its theme `font_color` (walked through
  `theme_type_variation`) multiplied by the ancestor `modulate` chain, so a
  dimmed subtree reads as dimmed;
- samples the rendered framebuffer inside the label's own **ink rect** (the
  glyph box measured from the font, not the whole control rect — a wide
  left-aligned control is not judged by the empty space beside its ink);
- reports the WCAG contrast ratio `(L1+0.05)/(L2+0.05)` on relative luminance,
  the background's own `p20`/`p60` spread (a picture-backed label swings, a
  panel-backed one does not), and whether any opaque flat surface sits between
  the label and the pane root.

It also saves one PNG per deck to `/tmp/vajb_review/`.

**Run:**
`~/.local/bin/godot --path vajb-orbit res://tests/probe_s40_panes.tscn --quit-after 3000`

## Finding 1 — the caption ink is one token, and it fails AA 235 times

| Reading | Value |
|---|---|
| Text labels audited | **607** |
| Below WCAG AA 4.5:1 | **241 (39.7 %)** |
| Below 3.0:1 (unreadable) | **47 (7.7 %)** |
| Of the 241, using the single token `text_dim` `#6b7484` | **235** |

Below-AA share by deck: SHIPYARD **67 %**, LAUNCH **59 %**, OVERVIEW **58 %**,
AUCTION **44 %**, REFINERY **40 %**, ARMORY **32 %**, SERVICES **49 %**,
EXCHANGE **18 %**.

Measured contrast for `#6b7484`:

- on the shipped row/plate fills `#2b2e31`–`#2d2f33`: **2.85–2.96:1**
- on the void/panel-dark seats `#0b0f15`–`#0a0a0a`: **4.02–4.42:1**
- worst single reading: **2.04:1** (REFINERY's `MINERAL` header over the BG-2 art)

The armory already carries the cure and already applies it on one path:
`tools/build_theme.gd:99` defines `armory_caption` `#acb2ba` and
`armory_style.gd:38` documents it as *"Measured >= 4.5:1 against the plate
(HIGH-2's cure)"*. Measured on the same fills, `#acb2ba` reads **6.15–6.77:1**
(5.13:1 on the brightest seat `#2e3334`). The armory's `ROLE_CAPTION` labels
(`Legal`, `HeaderLead`, `HeaderCost`, `HeaderState`, `CellInfoLegal`) all clear
AA; the labels that wear the shared theme variations `SectionHeader` and
`StationCaption` read `#6b7484` and all fail.

`tools/build_theme.gd:357,365,367` is where those two variations are wired to
`text_dim`. UI_SPEC §1 already records the consequence (`text_dim` on
`void_base` ≈ **4.0:1**, "large text / labels only, never body"), and §3
Amendment 3 already requires the light ramp for captions, naming "`text_dim`
captions (HIGH-2)" as the reversal. The cure is therefore already ruled; it was
applied to the armory's own palette and never generalised to the shared
variations.

**This one token is 97 % of the defect.**

## Finding 2 — the ARMORY's FitCells left column floats on BG-1 (owner item 1)

`armory_panel.tscn:119,145` — `GridBlock` (the SLOT LAYOUT grid and its
`SectionHeader` caption) and `CellInfoBlock` (the CELL INFO block) are plain
`VBoxContainer`s inside `FitLeft`. Nothing opaque sits between them and the BG-1
deck backdrop; the host's own `ui_panel_frame` is a **banded** cut whose centre
the backdrop shows through, so it is not a backing.

| Label | Contrast | Background |
|---|---|---|
| `SlotCaption` "SLOT LAYOUT · 11 CELLS · 1 ENGINES" | **2.79:1** | `#2b3138`, spread 0.023 |
| `PaneSubtitle` "FIT CELLS AND EQUIPMENT - 11 CELLS" | 3.38:1 | `#202225`, spread 0.029 |
| `CellInfoCaption` "CELL INFO" | 4.16:1 | `#0a0c0e`, spread 0.024 |
| `CellInfoId` "W1 · WEAPONS CELL" | 4.33:1 | `#030507` |
| `CellInfoPower` "POWER DRAW 1 · PWR 5 / 8" | 4.36:1 | `#020406` |
| `CellInfoFitted` "FITTED — CANNON MKI" | 4.29:1 | `#050707` |

The rendered frame shows why the median understates it: the CELL INFO block is
drawn straight across a **bright brass cartridge** in BG-1, so the glyphs are cut
by the art's own edges. See `/tmp/vajb_review/cellinfo_zoom.png`.

The cure is the one A5.3/A5.4 already pins for the armory's inner surfaces: the
flat Tokens box (`bay_bg`/`item_bg` + 1 px `metal_mid` border, `build_theme.gd`
`_flat()`), which is what the bays, well halves, pack cards and inventory rows
already wear.

## Finding 3 — the OVERVIEW tiles' ink is the same failing token (owner item 2)

`overview_panel.gd:210-256` — the six department tiles wear the C1 `ui_tile_slab`
canvas, which **is** opaque: its interior measures `#1d1f21`–`#252628`. The tile
therefore has a background. What fails is the ink on it:

| Element | Source | Contrast |
|---|---|---|
| tile title (`ARMORY`, `REFINERY`, …) | `theme_type_variation = &"SectionHeader"` → `text_dim` | **3.32–3.34:1** |
| tile caption (`BUY, FIT AND SWAP MODULES`, …) | `StationCaption` → `text_dim` | **3.51–3.55:1** |
| tile glyph, 4 of 6 tiles | `overview_panel.gd:241`, `_token(&"text_dim")` for every `tinted` tile | same tone |

The two untinted tiles (ARMORY, LAUNCH) modulate their glyph `Color.WHITE` and
read fine; the four tinted ones do not.

## Finding 4 — other captions that float on a deck backdrop (recorded, not fixed here)

Same mechanism as Finding 2, on surfaces this wave does not touch:

- **LAUNCH** (`launch_panel`): the whole briefing column — `FLIGHT BRIEFING`,
  `DESTINATION`, `HULL LIMIT`, `SHIELD LIMIT`, `ENGINES`, `HARDPOINTS`,
  `SLOT CELLS`, `CARGO`, `AMMUNITION`, `DECK CONTROL` — reads 4.04–4.28:1 over
  BG-4, ten labels, none roofed.
- **REFINERY**: the `MINERAL` / `ORE` / `STATE` / `JOB` / `TIME` / `CONVERSION`
  / `FEE` / `ORE IN` / `INGOTS OUT` headers read 2.04–4.42:1 over BG-2.
- **EXCHANGE**: `YOUR HOLD` 2.68:1 and the pane footer 3.44:1 over BG-3.
- **AUCTION**: the shelf `Title` line 2.37:1 and the `MODULE` band header over
  BG-3.
- **SHIPYARD**: the pane subtitle 3.83:1 and the `PORT`/`STBD` labels over BG-4.

## Finding 5 — the deliberately-dim staged rows are past invisible

SERVICES' staged EXPEDITION row reads **1.61–1.62:1** (`#2c3444` on `#050a0f`) —
`text_dim` multiplied by the staged row's own dim. Deliberate dimming, but at
1.6:1 the row is gone rather than greyed.

## What this wave fixes

1. **Finding 1** — a `text_caption` / `text_caption_void` token pair, with
   `SectionHeader`, `StationCaption` and `FlavourText` moved onto it. This alone
   lifts 235 of the 241 below-AA labels.
2. **Finding 2** — the ARMORY's FitCells left column gets the flat Tokens box.
3. **Finding 3** — the tinted tile glyphs move onto the caption tone.
4. **Finding 4 / 5** — recorded as tickets **T-174/T-175/T-176**; each is a
   different surface with its own composition decision and none is in this
   wave's file set.

## After (re-measured off the render, same probe)

| Deck | below AA before | after |
|---|---|---|
| ARMORY (fit) | 32 % | **0 %** |
| ARMORY (battery) | 24 % | **0 %** |
| REFINERY | 40 % | **0 %** |
| EXCHANGE | 18 % | **0 %** |
| LAUNCH | 59 % | **0 %** |
| OVERVIEW | 58 % | **0 %** |
| AUCTION | 44 % | 15 % |
| SHIPYARD | 67 % | 25 % |
| SERVICES | 49 % | 13 % |
| **All eight decks + both modes** | **241 of 607 (39.7 %)** | **34 of 610 (5.6 %)** |
| below 3.0:1 | 47 | **5** |

The 34 that remain, by cause (none is the caption token):

| Count | Reading | Cause |
|---|---|---|
| 9 | 3.47:1 | the AUCTION family-tab labels — the theme's `font_unselected_color` (`build_theme.gd:344`), the documented "TabBar colour language" (`auction_panel.gd:111`) |
| 18 | 4.08:1 | the SHIPYARD comparison rows — `text_dim` on `void_panel`, i.e. exactly §1's own documented ≈4.0:1 floor for labels |
| 3 | 3.33–3.70:1 | the SHIPYARD `NOMINAL` reads — P13 pins "`NOMINAL` in `text_dim` for intact systems" |
| 2 | 4.22–4.24:1 | the SERVICES board note + roll countdown — `contracts_panel.gd:677,681` `text_dim` overrides |
| 5 | 2.48–3.09:1 | the SERVICES staged EXPEDITION row — T-176 (the row's own dim) |

Each of the first four is a **pinned idiom**, so moving it is an owner ruling,
not a builder's call (the escalation ladder's bucket 2). They are recorded with
their cites and their one-line cures, and await the owner's word.

## Gate pin

`tests/test_s40_legibility.gd` — a headless, deterministic contrast table over
the generated theme (every caption variation against every registered surface
fill ≥ 4.5:1), plus the structural rows for Findings 2 and 3. It needs no
framebuffer, so it runs inside the universal gate.
