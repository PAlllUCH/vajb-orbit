# D1 — Asset audit (Phase D/E art + audio reachability)

You are a **design/asset auditor** worker. Output is two files: `docs/design/ASSET_AUDIT.md` and `.agents/gen/d1_report.md`. You edit NOTHING else. Do not generate or download images. Do not modify any asset.

## Environment

- Workspace: `G:/Mój dysk/Projekty/Vajb Orbit` (this is your cwd). Godot project: `vajb-orbit/`.
- **A Godot editor is open on this project (PID 9048). Never run `--headless --editor`.** Do not open, save, or touch anything in the editor. Do not touch `project.godot` or `addons/`.
- Engine console binary for scripted runs: `C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe`
  Pattern: `..._console.exe --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://<scene> --quit-after 300`
  You almost certainly do not need to run Godot for this task.
- PNG inspection: use python.org python via `py -3.14` (Pillow 12 is installed):
  `py -3.14 -c "from PIL import Image; im=Image.open('path'); print(im.size, im.mode, im.getextrema())"`
  Do **not** use bare `python` (it resolves to Inkscape's interpreter with no CA roots).
- `.png.import` sidecars contain the imported dimensions; `.job.json` sidecars contain the generation prompt/model. Both are valid evidence.

## Context you must absorb first

Read, in this order:

1. `AGENTS.md` (workspace rules)
2. `docs/ASSETS.md` — the art/audio inventory summary, phase counts, the derived-tint note
3. `docs/design/ASSET_CATALOG.md` — generated per-file catalog: px, alpha mode, phase tag, purpose
4. `docs/design/ASSET_WIRING_HANDOFF.md` — what is bound today, what is "shipped but not bound", the consumption rules (FX/backdrops are RGB for additive blending; only `icons/tint/*` may be `modulate`d)
5. `docs/design/STYLE_BIBLE.md` — the art direction you are auditing against
6. `docs/design/UI_SPEC.md` and `docs/design/MAIN_MENU_SPEC.md` — what the UI is supposed to look like
7. `docs/design/ASSET_EXPANSION_SPEC.md` and `docs/design/ASSET_EXPANSION_SPEC_E.md` — the Phase D/E briefs the art was generated from

Known inventory (verify, do not trust): 317 shipped sprites (ships 74, icons 144 + 40 tints, env 56, ui 27, fx 16) + 95 audio files (music 6, sfx 62, ambience 16, ui 11). Only 39 sprites and 2 audio files are referenced by any `.tscn`/`.tres`/`.gd` today.

## What to produce

### 1. `docs/design/ASSET_AUDIT.md`

Sections, in this order:

**A. Verification of the inventory.** Per family: count on disk, count in the catalog, count referenced in code. Flag every disagreement with the exact path and evidence.

**B. Phase D/E audit table.** One row per shipped asset added in Phase D or E (use the phase tags in the catalog; if a tag is missing, say so). Columns:

| asset res:// path | px | alpha mode | intended use per docs | style-bible verdict | alpha-correct for that use | verdict | target screen |

- **style-bible verdict**: CONFORMS / DRIFTS / OFF-PALETTE, with the one-line reason.
- **verdict**: WIRE NOW / WIRE LATER / REJECT — WIRE NOW means it should be bound in this phase (menu v2 or station hub).
- Group rows by family so the table stays readable. If a family has more than 40 assets, table the ones that matter for the two upcoming screens in full and summarise the rest with counts plus a list of anomalies.

**C. Anomaly list.** Every concrete defect, each with the path and the evidence: RGB where RGBA is needed for a sprite use, missing 16/48 pair where the palette implies one, visual duplicates that waste a slot, off-palette colour, a file that contradicts its own documented purpose, a zero-byte or unreadable file, an unexpected extension.

**D. Audio reachability.** Table of the 93 unreachable audio files, grouped by bus directory. Then: the exact 8-12 files the menu v2 and the station hub should use first, with the reason for each (music bed for the menu, station room bed, ambience, ui cues, launch/docking cues).

**E. Art shortlist for the two upcoming screens (the deliverable that matters most).** Two tables, with EXACT `res://` paths, no invented names:

- `MENU_V2_SHORTLIST` — backdrop, chrome/panels, insignia, fx, grain, any decorative plate.
- `STATION_SHORTLIST` — hangar/station backdrop, panel frame + inventory slot art, the icons for ammo/ship/upgrade/launch modules, the ship sprites usable in a shipyard preview (side view, from `assets/ships/`), the credits/logout/map icons, any station ambience or cue audio.
  For each entry say the exact role it plays on that screen (e.g. "shipyard preview sprite for `ship_gunship_side.png`").

**F. Art gaps.** For every role on either screen that no shipped asset can fill, write a **ready-to-run image brief** (one paragraph each, no placeholders): subject, composition, palette with hex values from the style bible, lighting/mood, style description, aspect ratio and pixel size, and a negative list. These will be fed to kie.ai `gpt-image-2-5` at 2K, transparent for sprites, RGB on void black for FX. Say explicitly for each brief whether it must be transparent. If you find no gaps, say so and list the closest-match shipped asset per role instead.

**G. Recommendations.** Ordered, concrete: which assets to bind in this phase, which to reject, which to regenerate, and the two or three highest-value new images if the owner decides to generate more.

### 2. `.agents/gen/d1_report.md`

Method, files read, every command you ran with its output summary, counts, and the anomalies you found. State plainly what you could NOT verify. Measurements, not assertions.

## Rules

- Names: never invent an asset filename, a screen name, or a role name. Every path you write must exist on disk — verify each one with a filesystem listing before you write it.
- Evidence over opinion: every verdict row needs a reason traceable to a file you actually read or a command you actually ran.
- If the catalog and the filesystem disagree, the filesystem wins and you report the disagreement.
- Keep `ASSET_AUDIT.md` under 500 lines; compress families with a count plus the exceptions rather than padding rows.
- No em dashes in code or config; plain prose in docs is fine.
