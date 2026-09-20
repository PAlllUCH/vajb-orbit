# Phase F - generation log

Model: `gpt-image-2-5-flare-text-to-image` (`flare`; `flare-i2i` for reference edits), 2K.
Work order: `docs/gameplay/16_art_design_brief.md`. Style law: `docs/design/STYLE_BIBLE.md`, `docs/design/ICONS_SPEC.md` (section 1 + section 8 amendment), `docs/design/SHIPS_SPEC.md` (section 1 framing constant, sections 3.7-3.9).
Style block: `vajb-orbit/assets/style-block.txt` verbatim via `--style-file` on every run.
Price basis: 10 credits = $0.05 per 2K run (kie.ai console, user-verified); the script's printed 30-credit estimate is the stale hint and the `usage-ledger.jsonl` total over-reports 3x.
Alpha: `--transparent` native first, local matte fallback (`staging/phase_d/reprocess.py`). FX stay RGB on void black for additive blending and are never alpha-keyed (FX_SPEC 0.1).
AI-generated art is not CC0 (AGENTS.md).

---

## f1_panel_frame

- Date/time: 2026-09-18 12:33 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `8f1c2499ecb22accbe0bad9db27fa100` (elapsed 37.6s)
- Style block: `style-block.txt` verbatim via --style-file
- Reference: none (text-to-image)
- Alpha: local matte bg=#FEFEFE alpha0=36% dropped=0; run folder `20260918-123330` keeps `job.json`
- Final files: ui_panel_frame.png (+ 2 size cuts)
- Status: success

Full SUBJECT text:

> ui_panel_frame: a single square painted gunmetal metal panel frame, top-down orthographic, grimdark painted sci-fi. The painted border band is EXACTLY ONE THIRD of the square's total width on all four sides, that is 32 px thick at a final texture size of 96 px and 64 px thick at 192 px, so the recessed interior opening is the central third square. The band is uniform and straight so the left edge band is identical top to bottom, the top edge band identical left to right, and the frame stretches cleanly when tiled over a larger panel. Border face is panel steel #2A2E35 with a 1 px steel highlight #565C63 inner edge catch against the interior and an iron black #232629 outer edge giving a shallow bevelled read, no deep 3D bevel. Recessed interior fill is panel black #15181D with a very subtle inner shadow just inside the frame edge. Corners bevelled with chamfered 45 degree corner cuts, never rounded, never arcs. Each corner carries a riveted corner detail of two or three small rivet heads with pitted metal speckle and a steel highlight catch set into a slightly denser corner plate, and those rivets stay entirely inside the corner squares and never bleed into the straight edge bands. Subtle film grain at reduced opacity, faint hull grime toward the frame, at most a few faint scratches, no rust streaks, no oil stains, no gloss, no chrome, no text, no labels, no grid lines, no glow. The square frame is centred on a plain solid pure white background with clean pure white margins all around it for background removal.

---

## f2_panel_frame

- Date/time: 2026-09-18 13:30 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `9f67a39b5f978a6f45655aa560b0cf9f` (elapsed 27.3s)
- Style block: `style-block.txt` verbatim via --style-file
- Reference: none (text-to-image)
- Alpha: local matte bg=#FEFEFE alpha0=40% dropped=0; run folder `20260918-133002` keeps `job.json`
- Final files: ui_panel_frame-master.png
- Status: success

Full SUBJECT text:

> ui_panel_frame: a single square painted gunmetal metal panel frame, top-down orthographic, grimdark painted sci-fi. THE BORDER IS THE SUBJECT: the frame is an extremely heavy square ring whose painted band is EXACTLY ONE THIRD of the square's total width on all four sides, so the recessed interior opening is only the central third square - a small opening surrounded by a band as thick as a third of the whole image, 32 px thick at a final texture size of 96 px and 64 px thick at 192 px. The band is uniform and straight so the left edge band is identical top to bottom, the top edge band identical left to right, and the frame stretches cleanly when tiled over a larger panel. Border face is panel steel #2A2E35 with a 1 px steel highlight #565C63 inner edge catch against the interior and an iron black #232629 outer edge giving a shallow bevelled read, no deep 3D bevel. Recessed interior fill is panel black #15181D with a very subtle inner shadow just inside the frame edge. Corners bevelled with chamfered 45 degree corner cuts, never rounded, never arcs. Each corner carries a riveted corner detail of two or three small rivet heads with pitted metal speckle and a steel highlight catch set into a slightly denser corner plate; every rivet, plate and chamfer is small, no more than one sixth of the band's own width, so the whole corner detail sits deep inside the band and never touches or crosses the interior opening. Subtle film grain at reduced opacity, faint hull grime toward the frame, at most a few faint scratches, no rust streaks, no oil stains, no gloss, no chrome, no text, no labels, no grid lines, no glow. The square frame is centred on a plain solid pure white background with clean pure white margins all around it for background removal.

---

## f2_button_plates

- Date/time: 2026-09-18 13:31 local
- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, 1:1
- Job id: `fedb0cffdd53586ed8867a0936684f73` (elapsed 29.6s)
- Style block: `style-block.txt` verbatim via --style-file
- Reference: none (text-to-image)
- Alpha: local matte bg=#01080E alpha0=89% dropped=38, grid split; run folder `20260918-133142` keeps `job.json`
- Final files: ui_button_plate_normal.png, ui_button_plate_hover.png, ui_button_plate_pressed.png, ui_button_plate_disabled.png
- Status: success

Full SUBJECT text:

> 2x2 grid panel of four very wide thin horizontal gunmetal button plates, each plate exactly five times as wide as it is tall, long narrow painted metal plates centred in each square cell, drawn perfectly horizontal and perfectly straight, spanning about 80 percent of the cell width, with large plain solid pure white margins above and below every plate, top-left plate normal gunmetal with two small rivets at its two ends, top-right plate one step brighter with a faint burnt ember under-light baked along the lower bevel only, bottom-left plate darker and slightly inset with a shallow pressed bevel, bottom-right plate dimmed and desaturated with no glow, no text, no glyphs, no icons on any plate. Each plate has a clean crisp dark edge all the way around it: no white or pale halo, no white or pale fringe, no soft or feathered edge, no glow around the plate, no cast shadow and no drop shadow on the white background, no white highlight larger than a hairline, plain solid pure white background, 2K, 1:1

---


## f2 post-passes (C1 frame, chrome plates) - free, local, no API call

- Date/time: 2026-09-18 13:58 local
- `reband_frame.py` measured the regenerated master's painted band (304 px, the four edges
  within 6.9 %) and rebuilt the nine-slice as 3x3 tiles of exactly size/3:
  `ui_panel_frame.png` 96x96 with a 32 px band, `ui_panel_frame@2x.png` 192x192 with 64 px.
  A drawn nine-patch panel now measures a painted band of 30 of 32 px (was 12) and 59 of
  64 px (was 25), so the band equals the margin and `PANEL_FRAME_MARGIN` stays 32.
  Report: `reband_report.json`; preview `_preview/f2_frame_reband.png`.
- `plates_cut.py` cut the logical 280x56 and the 560x112 `@2x` for all four button plates out
  of the same F.2 cells (same-art diff <= 0.44 levels); the cell masters stay in staging as
  `ui_button_plate_*-master.png`. Report: `plates_report.json`.
- The shipped 1x plates are a new generation and read darker/flatter than the F.1 set, which
  was glossier than STYLE_BIBLE section 2 allows. Pre-F.2 bytes: `_f2_backup/`.
