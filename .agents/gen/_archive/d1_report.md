# D1 report - asset audit (Phase D/E art and audio reachability)

**Worker:** D1 design/asset auditor. **Date:** 2026-09-18. **Deliverable:** `docs/design/ASSET_AUDIT.md`
(495 lines, under the 500 line cap).

**Files written:** `docs/design/ASSET_AUDIT.md` and this report. Nothing else was created, edited or deleted.
No asset, scene, script, theme, `.import` sidecar or `project.godot` was touched. No image or audio was
generated or downloaded. The Godot editor was not launched, contacted or used: the audit is pure filesystem
and document analysis plus two libraries (Pillow, NumPy, soundfile) run under `py -3.14`.

## 1. Method

1. Read the required context documents, then every asset family on disk.
2. Parsed `docs/design/ASSET_CATALOG.md` mechanically into rows (family, file, px, alpha, phase, purpose) and
   compared it against a filesystem listing, then against decoded image metadata (Pillow) and decoded audio
   metadata (`soundfile`).
3. Extracted every `res://assets/...` string from every `.gd`, `.tscn` and `.tres` in the project and
   separated concrete file references from directory constants and path templates.
4. Measured every sprite for alpha mode, palette conformance (nearest of the 16 `STYLE_BIBLE` hexes), mean
   luminance, ember-hue pixel count and matte fringe; measured every audio file for duration, channels, sample
   rate, peak and RMS.
5. Verified the cue-resolution contract by re-implementing `AudioManager._load_cue()` in Python and testing
   every cue name the handoff documents.
6. Re-derived the reachability of all 95 audio files from the actual call sites in the codebase.
7. Wrote the audit, then re-parsed the finished file and checked every `res://` path in it against disk
   (142 tokens, 0 missing) and the line count (495).

## 2. Files read

- Workspace rules and inventory: `AGENTS.md`, `docs/ASSETS.md`.
- Generated index: `docs/design/ASSET_CATALOG.md` (all 486 lines, i.e. all 419 data rows).
- Wiring contract: `docs/design/ASSET_WIRING_HANDOFF.md` (all 208 lines).
- Style: `docs/design/STYLE_BIBLE.md` (all 152 lines).
- UI: `docs/design/UI_SPEC.md` (all 300 lines), `docs/design/UI_CHROME_ASSETS_SPEC.md` (all 139 lines),
  `docs/design/MAIN_MENU_SPEC.md` (all 100 lines).
- Phase briefs: `docs/design/ASSET_EXPANSION_SPEC.md` (all 310 lines),
  `docs/design/ASSET_EXPANSION_SPEC_E.md` (all 193 lines).
- Audio design: `docs/design/AUDIO_SPEC.md` (sections 1-4).
- FX design: `docs/design/FX_SPEC.md` (all 133 lines).
- Phase D screen scope: `docs/design/IMPLEMENTATION_PLAN.md` sections 7-9.
- Code: `autoload/audio_manager.gd`, `ui/paths.gd`, `ui/screens/main_menu.gd`, `ui/screens/main_menu.tscn`,
  `ui/hud/hud.tscn`, `ui/theme/vajb_theme.tres`, `tools/build_theme.gd` (relevant regions), plus a full
  recursive scan of all 13 `.gd`, 11 `.tscn` and 2 `.tres` files for asset references.
- Every asset file in `vajb-orbit/assets/{ships,icons,env,ui,fx,audio}/` was opened and measured; 210
  `job.json` manifests were parsed for model and prompt text.

## 3. Commands run, with output summary

All Python ran under `py -3.14` from the workspace root or `vajb-orbit/`. No Godot binary was executed.

| # | Command (purpose) | Output summary |
|---|---|---|
| 1 | Line counts of 14 design docs | catalog 486, UI_SPEC 300, MAIN_MENU_SPEC 100, expansion D 310, expansion E 193, handoff 208, AUDIO_SPEC 410, ICONS_SPEC 87, FX_SPEC 133, ENVIRONMENT_SPEC 127, SHIPS_SPEC 134, UI_CHROME 139, MENU_FLOW 417, IMPLEMENTATION_PLAN 346 |
| 2 | Count `.png`/`.ogg` under `assets/` per family, list top-level entries | ships 123 png, icons 241, env 115, ui 81, fx 38, audio 95 ogg; plus `style-block.txt`. The excess over the catalog is 105 `20260917-*` run folders |
| 3 | Recursive directory dump of each family | confirmed top-level shipped files, `generation_log*.md`, `job.json`, `.import` sidecars, `icons/tint/` (40 png + 40 `.import`, 80 entries), 105 run folders |
| 4 | Survey project file types and directories | 22 `.gd`, 11 `.tscn`, 2 `.tres`, 710 `.import`, 598 `.png`, 315 `.json`, 95 `.ogg`; dirs `.godot`, `addons`, `assets`, `autoload`, `game`, `tools`, `ui` |
| 5 | Extract all `res://assets/` strings from `.gd`/`.tscn`/`.tres` with the referencing file | 47 distinct matches: 39 file references, 4 directory constants/files patterns, 4 path templates. Zero dangling references |
| 6 | Parse the catalog (419 rows) and diff against the filesystem per family | 0 disagreements in either direction for ships 74, icons 144, env 56, ui 27, fx 16, audio 95 |
| 7 | Pillow pass: decoded size and alpha characterisation over all 317 sprites | 0 pixel-size mismatches; modes 288 RGBA + 29 RGB; alpha buckets: 122 fully cut out, 151 partially, 15 with an alpha channel but no transparent pixel, 29 with no alpha channel |
| 8 | Pillow pass: ink coverage, edge-contact and near-duplicate detection | 0 near-empty icons; `icon_cargo_data_core_16.png` is the only glyph with ink 0.98; 0 byte-identical files among 357 pngs (SHA-256) |
| 9 | Audio metadata and level pass with `soundfile` over all 95 oggs | 0 duration or channel mismatches against the catalog (0.06 s tolerance); no silent files; 6 files peak above 1.0; 19 above 0.891; sample rates 44100 (71), 48000 (20), 96000 (4) |
| 10 | `.import` sidecar scan for `loop=true` | exactly 25 loop files (5 music, 11 ambience, 9 sfx); 0 missing sidecars; the 5 `amb_space_misc_*` are one-shots, contradicting handoff section 1.4 |
| 11 | `job.json` scan (model, prompt keywords, palette hexes, forbidden words) | 210 manifests: 182 flare text-to-image, 23 flare i2i, 5 sunburst; 0 unnegated forbidden words in 210 prompts (the 466 "saturated" hits are all "desaturated"); 0 non-palette hex codes in 210 prompts |
| 12 | Palette conformance per sprite (nearest of the 16 hexes, threshold 90) | Family mean off-palette fraction: ships 0.006, icons 0.022, env 0.003, ui 0.001, fx 0.117. The 3 highest are the Phase B glyph masters `panel_weapons.png` 0.823, `panel_glyphs.png` 0.782, `panel_cargo.png` 0.726, all pure-white-background masters; every FX offender is a deeper ember shade in the same hue band |
| 13 | Hue-band scan for a second accent (green/cyan/yellow/purple/magenta, saturation > 0.30) | 6 of 317 sprites above 0.2 percent, the highest 2.3 percent (the same 3 white masters); the other three are 0.2-0.5 percent, grain-level. No second accent anywhere |
| 14 | White-fringe metric on 265 sprites with a usable outer alpha band | 13 files at ratio 0.88-1.00 with outer-band luminance 212-252 against interior 38-76; 6 files at 0.30-0.61 (the 4 button plates and 2 icons); 10 at 0.10-0.30; 171 below 0.02 |
| 15 | Raw scanline dumps across silhouette edges (`env_outpost_mining`, `env_base_mining`, `env_planet_moon`, `ui_insignia_mic`, `ship_drone_swarm_side`, `ship_gunship_side`) | confirmed the fringe in raw pixels: white ramps such as `(243,244,244,9)`, `(241,242,242,63)`, versus clean dark ramps `(3,9,14,0)`, `(12,12,16,0)` on the unflagged files |
| 16 | Subject-bbox occupancy for all 74 ships and for the bases/outposts | ships 86-100 percent of frame width, mean 0.969, versus the style bible's 60 percent (files are trimmed); subject areas: outpost mining 2.19 M, repair 2.55 M, defense 1.78 M, relay 1.14 M versus base shipyard 2.07 M, trade 2.63 M, defense 2.85 M, mining 3.29 M |
| 17 | Per-cell ink statistics on the 5 multi-frame FX sheets | `fx_explosion` 2x3 cells 0.307 / 0.370 / 0.192 / 0.051 / 0.055 / 0.0015 (5 frames plus the spec'd empty cell); the other four sheets are 1x4 strips with ink confined to the vertical middle half |
| 18 | Ember-pixel centroid of `env_menu_bg.png` | centroid at anchored (0.792, 0.618) over 772 ember pixels, matching the wired `%EmberPulse` anchor (0.791, 0.618) in `ui/screens/main_menu.tscn` |
| 19 | Nine-patch frame width profiling (`ui_panel_frame.png`, `ui_minimap_bezel.png`) | panel frame band 7 px (profile: `47,53,59` at y=0 through `9,10,11` at y=7); the theme and the Phase D plan both use 32. Bezel band 15 px against the HUD's 16 px margins (correct) |
| 20 | Grep for `PanelRaised`, `panel_raised`, `patch_margin`, `panel_frame`, `StyleBoxTexture` | `PANEL_FRAME_MARGIN := 32.0` at `tools/build_theme.gd:23`; `vajb_theme.tres` `texture_margin_* = 32`; no scene uses `PanelRaised` yet, so the mismatch is latent |
| 21 | Grep for `play_sfx`, `play_ui`, `AudioManager.` call sites | 5 matches: 2 calls (`main_menu.gd:80`, `main_menu.gd:84`, both `play_ui`), 2 definitions, 1 comment. `play_sfx()` has no caller |
| 22 | Re-implemented cue resolution and tested the 31 documented cue names | 31 of 31 resolve (11 to an exact file, 20 to a `_01` fallback), so unreachability is a code gap, not a naming gap |
| 23 | Verified the finished audit: path existence and line count | 142 `res://` tokens, 0 missing; 495 lines; 0 em dashes |
| 24 | mtime scan of everything under the workspace root | revealed that parallel workers were writing `docs/design/STATION_SPEC.md`, `docs/design/THEME_AUDIO_EXTENSION.md`, `vajb-orbit/game/station_catalog.gd`, `vajb-orbit/autoload/player_profile.gd`, `vajb-orbit/autoload/audio_manager.gd`, `vajb-orbit/ui/paths.gd`, `vajb-orbit/tools/build_theme.gd`, `vajb-orbit/ui/theme/vajb_theme.tres` and `project.godot` during the audit, so every claim that depends on those files was re-verified before the audit was finalised |
| 25 | Re-grep `AudioManager\.[A-Za-z_]+` across all scripts | still 2 call sites, both `play_ui` in `main_menu.gd`; `audio_manager.gd` has grown to 251 lines and now exposes `play_music`, `stop_music`, `play_ambience`, `stop_ambience`, and `Paths.AUDIO_DIRS` now has an `ambience` entry. Reachability is therefore still 2 of 95, but for the narrower reason that nothing calls the new functions |
| 26 | Re-check `PANEL_FRAME_MARGIN` and the theme's `texture_margin_*` | unchanged at 32.0 on the 96x96 texture whose measured frame band is 7 px, so anomaly C1 stands and is now on the critical path for the station theme |
| 27 | Path check plus colour comparison on `game/station_catalog.gd` | all 15 `res://assets/` paths it binds exist on disk; the `AMMO_PACKS` list mixes painted Phase D icons (mean RGB 51-55, brightest pixels above 200) with three Phase B flat glyphs (mean RGB 40,44,47, brightest pixel 56-65), recorded as anomaly C16 |
| 28 | Final re-verification of the finished audit | 143 `res://` tokens, 0 missing; 467 lines |

## 4. Counts

- **Sprites:** 317 on disk = 74 ships + 144 icons + 56 env + 27 ui + 16 fx, matching the catalog exactly.
  Phase split 109 B / 141 D / 67 E. Plus 40 derived tints under `icons/tint/` (not in the 317).
- **Audio:** 95 = 6 music + 62 sfx + 16 ambience + 11 ui, matching the catalog exactly.
- **References from code:** 39 sprites (ships 1, icons 17 through `icons/tint/`, env 5, ui 15, fx 1) and 2
  reachable audio files, so 278 of 317 sprites and 93 of 95 audio files are unbound.
- **Phase D/E coverage in the audit:** all 208 files (ships 53 tabled 17 / summarised 36; env 40 tabled;
  ui 7 tabled; fx 7 tabled; icons 101 tabled 11 / summarised 90).
- **Provenance:** 210 `job.json` manifests; 229 of 317 sprites resolve one (208 t2i, 21 i2i); 88 do not
  (mostly Phase B). 5 assets were made with the undocumented `sunburst` fallback.

## 5. Anomalies found

Full detail and evidence in `docs/design/ASSET_AUDIT.md` section C. Summary:

1. `ui_panel_frame.png` has a 7 px frame band while `build_theme.gd` and the theme use 32 px margins (latent
   defect, lands on the station hub's `PanelRaised`).
2. `icon_cargo_data_core_16.png` is illegible at 16 px (ink 0.98, silhouette touching all four edges).
3. White matte fringe on 13 sprites (4 insignia, 4 drone-swarm views, 5 env POIs), with raw pixel evidence;
   contradicts the "0 fringe pixels per file" claim in expansion spec E section 11.2 for the two outposts.
4. `env_body_ice_moon.png` is 67 percent brighter than the ship family mean, against the one-value-step rule.
5. The environment family is not darker than ships at all (55.4 versus 54.3 mean luminance).
6. Outposts are not clearly smaller than bases by subject footprint (2 of 4 exceed the smallest base).
7. 6 audio files decode above full scale, worst `sfx_ship_boost_01.ogg` at 1.464; 19 exceed -1 dBFS.
8. `sfx_mining_chip_04.ogg` is 20.901 s inside a pool of 0.46-0.49 s chip transients.
9. `sfx_weapon_laser_04.ogg` is 1.244 s inside a pool of 0.064-0.092 s laser one-shots.
10. `ASSET_WIRING_HANDOFF.md` section 1.4 overstates the ambience loop set (11 of 16, not 16).
11. Phase D deleted its panel masters while Phase E kept them: two provenance conventions in one library.
12. FX frame layout under-documented: `fx_explosion.png` is 2x3 (5 frames plus an empty cell), the other four
    sheets are 1x4 with the ink in the middle half only.
13. All ships are trimmed to the subject, so no framing margin survives; scaling to a fixed box would erase
    the hull-class size hierarchy.
14. 15 UI files are catalogued `rgba` but contain no fully transparent pixel.
15. Cleared suspicions: no duplicate files, no zero-byte or unreadable files, no unexpected extensions, and
    `env_bg_body_plate.png` is not a re-render of `env_stars_layer3.png`.

## 6. What I could NOT verify, and why

- **The two screen specs.** `docs/design/MAIN_MENU_V2.md` and `docs/design/STATION_HUB.md` do not exist, so
  menu v2 and station hub role assignments were derived from `MAIN_MENU_SPEC.md`,
  `IMPLEMENTATION_PLAN.md` section 9 and the style bible background rules. A v2 or hub layout that changes
  those roles could add a role this audit did not see.
- **The station catalogue's content quality.** `docs/design/STATION_SPEC.md` and
  `vajb-orbit/game/station_catalog.gd` appeared during the audit (written by the parallel D2 worker), which
  closed the hull-matching blind spot: all 15 asset paths the catalogue binds exist on disk and its 4 ship
  previews map to real side views (2 Phase B, 2 Phase D). What remains unaudited is the catalogue's pricing,
  naming and balance, which is not an art question.
- **Visual judgement.** Style verdicts are measured proxies (palette distance, luminance, ember-hue pixel
  counts, silhouette alpha), not eyes on the art. I did not render or thumbnail any asset.
- **16 px icon legibility by eye.** Assessed numerically only (ink coverage and frame-edge contact).
- **Loop-seam quality.** The handoff's seam measurements were not independently re-verified; I only confirmed
  the loop flags in the `.import` sidecars.
- **Whether the local matte's soft alpha is intentional at the 13 flagged edges.** I measured the fringe; I
  did not re-run the matte pipeline to test a fix.
- **The Godot editor's view of the library.** No editor, MCP call or import was performed, so "imports
  cleanly" is taken from the existing documents and from the presence and content of the `.import` sidecars,
  not from the live editor.
- **Stability of a moving target.** Several project files were edited by parallel workers while this audit ran
  (commands 24-27). Every claim that depends on one of them was re-verified at the end, but a reader should
  treat the audited state as the tree as of the end of this session, not a frozen commit.
