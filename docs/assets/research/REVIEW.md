# Asset Research Review

Audit of the four CC0 asset research reports in `docs/assets/research/`.
Review date: 2026-09-16. Reviewer: asset research review pass.
Scope: `ships_weapons.md`, `ui_hud.md`, `audio.md`, `environment.md`.

Method: read all four reports line by line; fetched and read the source page for
every top-3 recommended candidate in each report (12 pages) and read the licence
badge/label myself; opened 11 further source pages to resolve ambiguous, generic
or malformed download URLs. No asset was downloaded. No report was edited.

## Verdict

**Pass with fixes.** All 12 spot-checked licence claims matched the source pages
(0 mismatches). Every report has the four required sections. No report puts a
page URL in a download column. One high-severity defect (an unresolved `<hash>`
placeholder on a recommended asset) and one cluster of malformed bare-filename
URLs must be fixed before the download batch is run.

| Severity | Count |
| --- | --- |
| High | 2 |
| Medium | 7 |
| Low | 5 |

## High severity

| # | Report:line | Issue |
| --- | --- | --- |
| H1 | `ships_weapons.md:75` | **Unresolved download placeholder on a recommended asset.** The Crosshair Pack download URL is the literal string `https://kenney.nl/media/pages/assets/crosshair-pack/<hash>/kenney_crosshair-pack.zip (resolve current hash on the page)`. `<hash>` is a placeholder, not a concrete file URL, so the row is not actionable as written. It is also inconsistent with `ui_hud.md:26`, which already records this exact asset with the resolved hash. Resolved and verified in this review against `https://kenney.nl/assets/crosshair-pack`: `https://kenney.nl/media/pages/assets/crosshair-pack/5ef74bd405-1785950072/kenney_crosshair-pack.zip`. |
| H2 | `environment.md:33` | **All four download URLs in the cell are bare filenames with no host**, so none is usable: `Parallax100.png · Parallax80.png · Parallax60.png · BackdropBlackLittleSparkTransparent.png`. Verified against `https://opengameart.org/content/space-parallax-background`; real forms are all under `https://opengameart.org/sites/default/files/`. Secondary defect in the same row: the Contents cell claims "2 star-spark backdrops (black and transparent)" but the download cell lists only one; `BackdropBlackLittleSparkBlack.png` is missing. Impact is bounded because this pack is not in the report's recommendations. |

## Medium severity

| # | Report:line | Issue |
| --- | --- | --- |
| M1 | `environment.md:24` | **Broken fallback URL: the 512 tier is missing the `_0` suffix.** Report gives `.../sbs_-_seamless_space_backgrounds_-_small_512x512.zip`; the page's actual href is `.../sbs_-_seamless_space_backgrounds_-_small_512x512_0.zip` (7.9 MB). The 1024 URL in the same cell is correct (`..._large_1024x1024_0.zip`, 26 MB) and is the one Recommendations item 3 names, so only the fallback is broken. |
| M2 | `environment.md:58` | **Incorrect size claim.** "the larger SBS tiers are 70-90 MB" contradicts the source page, which lists 26 MB (1024 zip) and 7.9 MB (512 zip). Off by roughly 3x. |
| M3 | `ships_weapons.md:75` vs `ui_hud.md:26` | **Same asset recommended by two reports, only one actionable.** Kenney Crosshair Pack appears as a download candidate in both, with the same fit score (4). `ships_weapons.md` has the placeholder URL (see H1), `ui_hud.md` has the resolved one. Neither report cross-references the other, so a batch built from `ships_weapons.md` alone would stall on this row. |
| M4 | `environment.md:27` | **3 of 4 download URLs are bare filenames.** Only `Background-1.png` carries the host; `Background-2.png · Background-3.png · Background-4.png` do not. Verified against `https://opengameart.org/content/space-backgrounds-3`; all four live under `https://opengameart.org/sites/default/files/`. |
| M5 | `environment.md:32` | **4 of 5 download URLs are bare filenames.** `azure-sky.jpg · red-sky.jpg · rusted-sky.jpg · yellow-sky.jpg` lack the host; only `violet.png` is written in full. Verified against `https://opengameart.org/content/spacy-cloudnebula-backgrounds`; all five live under `https://opengameart.org/sites/default/files/`. |
| M6 | `ui_hud.md:38` | **Flare HUD lists ten "sibling files" as bare filenames.** The cell gives one concrete URL (`bar_hp.png`) then ten names with no host (`bar_enemy.png`, `bar_mp.png`, `bar_hp_mp.png`, `Frame.png`, `Frames.png`, `Blue.png`, `Gold.png`, `Red.png`, `button_1%28frame%29.png`, `Disable.png`). Reconstructable from the Contents cell but not directly usable. |
| M7 | `ui_hud.md:40` | **Radar parts lists two bare filenames.** `radar_01_0.png` is a full URL; `radar_sweep_0.png` and `radar_sweepbk_0.png` are names only. Same class as M6. |

## Low severity

| # | Report:line | Issue |
| --- | --- | --- |
| L1 | all four | **Section naming drift (requirement 4 is still met).** All four have summary, candidate table, recommendations and rejected list, but nothing is uniform: `audio.md:36` uses `## Candidates` and splits the table into six subsections (`### A` to `### F`) so there is no single candidate table; `audio.md:173` is `## Rejected`; `ui_hud.md:85` is `## Rejected list`; `ships_weapons.md:133` and `environment.md:60` are `## Rejected candidates`. Any scripted consumer expecting one table per report will fail on `audio.md`. |
| L2 | `ships_weapons.md:105` | Recommendation 3 names `dg2a.png` and `ft.png` with no URL. The full URLs do exist in the same report at line 64, so this is a copy-paste inconvenience rather than a missing fact. |
| L3 | `ships_weapons.md:146` vs `environment.md:44` | **Openverse scored as both a dead end and a source of candidates.** `ships_weapons.md` concludes "No usable candidate" from Openverse image search; `environment.md` lists an Openverse-indexed CC0 NASA/Hubble photograph as a usable (fit 2) sector backdrop. Both are defensible within their own scope (sprites vs photographs) but neither report acknowledges the other's opposite conclusion. |
| L4 | `audio.md:151` | Recommendation 2 says "both rubberduck packs are small and CC0". Verified for `50 CC0 Sci-Fi SFX` (author rubberduck). The author of `25 CC0 bang / firework SFX` is not stated anywhere in the report and was not verified in this review. |
| L5 | `audio.md:44` | Filename `doomsday_laser_cannon_midium_.wav` reads like a typo. Verified in this review against the source page: the author's file really is named that, so the report transcribed it faithfully and no change is needed. Recorded only so a future reader does not "fix" it into a 404. |

## Cross-report contradictions

Beyond the URL defects above, the same assets are scored differently in different
reports with no cross-reference, so the fit numbers are not comparable across
files. These are judgement calls, not errors, but they should be reconciled or
scoped explicitly.

| Asset | `ships_weapons.md` | `environment.md` / `ui_hud.md` | Note |
| --- | --- | --- | --- |
| Kenney Crosshair Pack | line 75, fit 4, placeholder URL | `ui_hud.md:26`, fit 4, resolved URL | Duplicate recommendation; see M3. |
| Kenney Space Shooter Extension | line 61, fit 5, "First download" | `environment.md:41`, fit 3, "Not environment art" | `environment.md` lists a ships/weapons pack in an environment candidate table, inflating that table's count without adding an environment candidate. Not a rejection, so not a hard contradiction. |
| Kenney Space Shooter Remastered | line 65, fit 5 ("already owned") | `environment.md:42`, fit 2 | Same asset, fit 5 vs fit 2. Defensible per scope (fleet vs environment) but unexplained. |
| Space icons (arikel) | line 93, fit 2, "not flat vector", "UI buttons rather than gameplay sprites" | `ui_hud.md:41`, fit 3 | Duplicate coverage across the ships and UI reports with divergent scores. `ships_weapons.md:93` notes the overlap with the HUD gap and lists it anyway. |

## Requirement checks

| Requirement | Result |
| --- | --- |
| 4. Summary + candidate table + recommendations + rejected list in every report | **Pass** for all four. Naming is inconsistent, see L1. |
| 5. Every direct download URL is a concrete file URL, not a page URL | **Pass on page-URL contamination** (checked with a regex over the download column for `/content/`, `/assets/`, `/search`, `itch.io`, `openverse` in the post-fit cell: zero matches). **Fail on concreteness** for the cells in H1, H2, M4, M5, M6, M7, which are placeholders or host-less filenames rather than page URLs. |
| 3. Top-3 licence spot check | **Pass, 12 of 12 matched.** See table below. |

### Top-3 spot checks (licence badge read directly from the source page)

| Report | Candidate | Claimed | Found on page | Match |
| --- | --- | --- | --- | --- |
| ships_weapons | Space Shooter Extension (Kenney) | CC0 | `License(s): CC0` badge + Kenney header `License Creative Commons CC0` | Yes |
| ships_weapons | 200+ CC0 Spaceship Sprites (Wisedawn) | CC0 | `License(s): CC0`; "211 public domain licensed spaceships"; credit not mandatory | Yes |
| ships_weapons | 2d space shooter assets (pudman) | CC0 | `License(s): CC0` | Yes |
| ui_hud | UI Pack - Sci-Fi (Kenney) | CC0 | `License Creative Commons CC0`, `Files 130×`, 2.0 remade | Yes |
| ui_hud | Assets: UI Minimalism SciFi (Wenrexa) | CC0 | `License(s): CC0`; "33 UI Elements"; "COMMERCIAL and FREE projects" | Yes |
| ui_hud | Progress / health / mana bar svg (arkalain) | CC0 | `License(s): CC0`; "Attribution is not necessary" | Yes |
| audio | Doomsday Laser Cannon (TAD) | CC0 | `License(s): CC0`; three WAVs at the sizes quoted | Yes |
| audio | 50 CC0 Sci-Fi SFX (rubberduck) | CC0 | `License(s): CC0`; the 12-category breakdown sums to 50 | Yes |
| audio | Space Ship Shield Sounds (bart) | CC0 | `License(s): CC0`; FL Studio source included | Yes |
| environment | Planets (Kenney) | CC0 | `License Creative Commons CC0`, `Files 50×`, 2022 | Yes |
| environment | Simple Space (Kenney) | CC0 | `License Creative Commons CC0`, `Files 48×`, 2021 | Yes |
| environment | Seamless Space Backgrounds (SBS) | CC0 | `License(s): CC0`; 8+8+8+8 at 512 and 1024 | Yes |

## Verified correct (no action needed)

Recorded so these are not re-litigated in a later pass.

- **Kenney release hashes quoted in the reports are all current.** `space-shooter-remastered/2cbf3c45c8-1774771931` (`ships_weapons.md:65`, `environment.md:42`), `space-shooter-extension/d0bd70032c-1677693518` (`ships_weapons.md:61`, `environment.md:41`), `ui-pack-sci-fi/b67c2acd31-1724181109` (`ui_hud.md:24`), `planets/512b578338-1677495391` (`environment.md:22`), `simple-space/b9b0968a6b-1677578143` (`environment.md:23`) and `crosshair-pack/5ef74bd405-1785950072` (`ui_hud.md:26`) each match the live page byte for byte.
- **`ships_weapons.md:65` slug claim is correct.** `https://kenney.nl/assets/space-shooter-redux` returns HTTP 404, as the report states.
- **Suspicious-looking generic filenames are all real.** `projects.zip` (`audio.md:113`), `Ship.zip` (`ships_weapons.md:63`, `:107`) and `ships_0.zip` (`ships_weapons.md:67`, `:109`) each match the authored file on the source page. Do not "clean up" these names.
- Report claims about page contents spot-checked and confirmed: Kenney UI Pack - Sci-Fi file count 130 and "Completely remade 2.0"; Kenney Crosshair Pack `Files 200`, `Tile size 64 × 64`, "1.1 Added vector and glow effect"; SBS "Named in the Tiling/Seamless Textures collection"; Rawdanitsu "8.5k+ downloads on one file" (8555 on `Background-1.png`); Paul Wortmann "clipped baked shadows" (confirmed by a page commenter); arkalain layer split (background, 3 blue fills, frame, marker).

## Fix list for the download batch

1. Replace the `<hash>` placeholder at `ships_weapons.md:75` with `5ef74bd405-1785950072`, or drop the row and point at `ui_hud.md:26` (M3).
2. Prefix hosts on `environment.md:33` (all four), `:27` (three), `:32` (four); add the missing `BackdropBlackLittleSparkBlack.png`.
3. Add the `_0` suffix to the 512 URL at `environment.md:24` and correct the 70-90 MB claim at `:58`.
4. Expand the bare sibling filenames at `ui_hud.md:38` and `:40`, or mark them as names rather than URLs.
5. Add a one-line cross-reference note to the four assets in the cross-report table so the fit scores are not read as comparable across reports.

## Re-review 2026-09-16 cycle 2

Re-check of the five fix-list items against the edited `ships_weapons.md`,
`ui_hud.md` and `environment.md`. Nothing was downloaded and no report was
edited. Method: read the three reports in full, resolved every added
cross-reference against its target line, and re-validated the pipe count of
every table row in all four reports with a script (each table's delimiter row
used as its column baseline).

**Result: pass.** All five fix-list items are satisfied, no edited row lost its
column count, and every added cross-reference resolves to the intended line.

| Fix item | Result | Evidence |
| --- | --- | --- |
| 1. Resolve the `<hash>` placeholder at `ships_weapons.md:75` (or drop the row and point at `ui_hud.md:26`) | Pass | Row kept and now carries the concrete `https://kenney.nl/media/pages/assets/crosshair-pack/5ef74bd405-1785950072/kenney_crosshair-pack.zip`, byte-identical to `ui_hud.md:26`; annotated "Hash resolved from the page on 2026-09-16". H1 closed. |
| 2. Prefix hosts on `environment.md:33` (all four), `:27` (three), `:32` (four) and add the missing `BackdropBlackLittleSparkBlack.png` | Pass | `:33` now lists five URLs, all under `https://opengameart.org/sites/default/files/`, including the added `BackdropBlackLittleSparkBlack.png`, so the Contents claim of two star-spark backdrops finally matches the download cell; `:27` is 4/4 and `:32` is 5/5 prefixed. H2, M4 and M5 closed. |
| 3. Add the `_0` suffix to the 512 URL at `environment.md:24` and correct the 70-90 MB claim at `:58` | Pass | `:24` 512 tier now reads `…sbs_-_seamless_space_backgrounds_-_small_512x512_0.zip`; `:58` states 26 MB (1024 zip) and 7.9 MB (512 zip), matching the source page. M1 and M2 closed. |
| 4. Expand the bare sibling filenames at `ui_hud.md:38` and `:40`, or mark them as names rather than URLs | Pass | `:38` gives all eleven Flare HUD files as full URLs (including the percent-encoded `button_1%28frame%29.png`); `:40` gives both radar sweep files as full URLs. Chose expansion, so no row needed a "names, not URLs" caveat. M6 and M7 closed. |
| 5. Cross-reference the four shared assets in the cross-report table | Pass | Both sides of all four are annotated: Crosshair Pack (`ships_weapons.md:75` ↔ `ui_hud.md:26`), Space Shooter Extension (`:61` ↔ `environment.md:41`), Space Shooter Remastered (`:65` ↔ `environment.md:42`), Space icons / arikel (`:93` ↔ `ui_hud.md:41`). Each note states the fit score is scoped to its own report and each quoted line number resolves to the intended row. M3 closed. |

### Residual observations (no fix-list item, no action requested)

- **`ships_weapons.md:74` is the only malformed row left**, and it is not one the fix list covered: the Bonsaiheldin attribution quote contains an unescaped `|` ("Bonsaiheldin | Link to this page"), giving the row 10 pipes against its table's 9, so it renders with one extra cell. Not a regression from this cycle, but worth escaping before the batch.
- **`environment.md:58` has a wording slip:** "take the medium/small tier unless 512 px planets are genuinely needed" now quotes correct sizes, but "planets" inside a *Seamless Space Backgrounds* bullet should read tiles; the 512 px tier there is background art. Cosmetic, the size claim itself is fixed.
- **L3 is unchanged:** `ships_weapons.md:146` still rejects Openverse image search while `environment.md:44` still uses an Openverse-indexed CC0 photograph. It was a low-severity judgement call rather than a fix-list item, and no new text contradicts it.
- **L1 is unchanged:** section naming still drifts (`## Candidates` plus six `###` subsections in `audio.md`, `## Rejected` vs `## Rejected list` vs `## Rejected candidates`), which requirement 4 still tolerates.
- Several download cells are now long single lines (`ui_hud.md:38`, `ships_weapons.md:75`). That is valid markdown and unavoidable for a one-row-per-asset table; only a plain-text diff readability cost.
