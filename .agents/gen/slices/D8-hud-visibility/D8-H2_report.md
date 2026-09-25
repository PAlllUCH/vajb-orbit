# D8-H2 report — the minimap legend and its two zoom glyphs (wave D8 item 10)

**Files:** `ui/hud/minimap.gd`, `ui/hud/hud.gd`, `tests/test_d8_hud_visibility.gd` | **Gate:** `[SUMMARY] passed=857 failed=1`

## Legend kind table (exactly what `minimap.gd` draws — `draw_kinds()`, minimap.gd:140)

| kind | label | map shape (`_draw_blip` minimap.gd:182) | token (`_color_for` minimap.gd:214) | glyph ink | label cap |
|---|---|---|---|---|---|
| self | SELF | dot (r 3, `draw_circle`) | text_primary | 16.0 px | 12.42 px |
| hostile | HOSTILE | dot (`draw_circle`) | accent_danger | 12.0 px | 12.42 px |
| friendly | FRIENDLY | diamond (`draw_colored_polygon`) | text_primary | 16.0 px | 12.42 px |
| swarmer | SWARMER | dot (`draw_circle`) | accent_danger | 12.0 px | 12.42 px |
| ghost | GHOST | dimmed dot (alpha 0.5 flicker mean) | text_dim | 12.0 px | 12.42 px |

Glyph ink = `LegendMark.mark_rect()` (hud.gd:2116) height; label cap = Oxanium OS/2 sCapHeight 690/1000 x 18 px `HudReadout` (rendered 'H' ink 13 px at 18 px) — a theme variation `Router.FONT_SIZE_ITEMS` scales, no per-node size. Row 4 proves the legend's row set == `draw_kinds()`: one row per kind, nothing else.

## Zoom glyphs — before/after pixel measurements (ink height at 1920x1080)

| glyph | before (QA build, 28 px buttons) | after (code marks, 36 px buttons) |
|---|---|---|
| ZoomMinus | 3.5 px — knocked-out bar, 12 px of the 96 px `icon_zoom_minus.svg` cut | 12.0 px — 30x12 bar (`ZoomMark`, hud.gd:2174) |
| ZoomPlus | 13.4 px — knocked-out cross, 46 px of the 96 px `icon_zoom_plus.svg` cut | 30.0 px — 30x12 + 12x30 cross |

Before = the mark ink the QA could not read (B1's rendered read 3.4/13.3 px); after = `zoom_mark_rects()` ink, asserted by row 6 against the 12 px floor. The marks draw white so the buttons' hover modulate still tints them. hud.tscn state (magnifier cuts retired, buttons 28 -> 36 px) is the in-tree prototype's — outside `VAJB_WORKER_FILES`, attributed, not edited.

## Placement (bucket 1 — inside a pinned acceptance)

The legend sits inside the minimap bezel's chrome on the row between the map frame and the footer (hud.gd:1114, `box.move_child(..., 1)`). An in-frame overlay is geometrically impossible at this floor: five >= 12 px-cap rows measure >= 95 x 119 px against the 200 px frame's 84 px top-left quadrant, and would cover the self blip and the rose at the map's centre (brief rule 2 keeps centres clear). Row 4 asserts: inside the panel, below the frame, above the footer, never over the map's centre.

## Gate (own XDG_DATA_HOME scratch store, bounded)

`XDG_DATA_HOME=<scratch> $GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200` -> `[SUMMARY] passed=857 failed=1`

## Findings (bucket 2 — outside `VAJB_WORKER_FILES`, left in place)

- The 1 failure is the known stale pin `test_d7_cockpit.gd:391` (`retired_widgets()` 5 -> 3 under the wave's un-hidden crest blocks): H1's bucket-2 finding for the fixer/developer session.
- Tests appended only: row 4 (legend names each draw kind + placement), row 5 (legend glyph + label floor), row 6 (both zoom glyphs >= 12 px); no existing row moved (rows 1-3 pre-grepped clean before the append).
