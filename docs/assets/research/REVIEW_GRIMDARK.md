# Grimdark Asset Research Review

Audit of the four grimdark research reports against the earlier CC0 reports.
Review date: 2026-09-16. Reviewer: asset research review pass (grimdark cycle).
Scope: `grimdark_ships.md`, `grimdark_ui_hud.md`, `grimdark_audio.md`, `grimdark_environment.md`,
cross-checked against `ships_weapons.md`, `ui_hud.md`, `audio.md`, `environment.md`.

Method: read all eight reports line by line; 41 page fetches across 35 distinct source pages to
re-read licence badges, file lists and served download hrefs myself (both raw text and raw HTML, so
the `href` behind a displayed filename could be compared with what each report printed). No asset was
downloaded, no report was edited, nothing was extracted.

## Verdict

**Pass with fixes.** All 12 spot-checked top-3 licence claims matched their source pages (0
mismatches). Every report has the four required sections. No report puts a page URL in a download
column and no `<hash>`-style placeholder exists anywhere in the four reports. Two high-severity
defects and six medium-severity defects should be fixed before any grimdark download batch is run:
one served-filename error that would 404, one licence-rule conflict on a dual-badge asset, a cluster
of host-less sibling URLs, one false author/provenance claim, and un-resolved ellipsis URLs.

| Severity | Count |
| --- | --- |
| High | 2 |
| Medium | 6 |
| Low | 10 |

## High severity

| # | Report:line | Issue |
| --- | --- | --- |
| H1 | `grimdark_environment.md:44` | **Broken download URL: the served filename is wrong, so the row 404s as written.** Row 6 states the starfield set's numbered variants as `https://opengameart.org/sites/default/files/Starfield-1.jpg … Starfield-7_0.jpg`. Read the page HTML: the actual hrefs are `Starfield-1.jpg … Starfield-7.jpg` — `Starfield-7.jpg` carries no `_0` suffix, so the printed name is a constructed URL that does not exist. (Contrast the same page, where some files really do carry suffixes: `Starfield-5_0.jpg`, `Background-1_3.jpg`, `Background-2_3.jpg`, `Background-5_0.jpg`.) Secondary defect in the same cell: the contents claim "7 `Starfield-*.jpg` + 3 `Background-*.jpg`" is wrong — the page lists four background files (`Background-1/-2/-5/-7.jpg`), 11 files total. |
| H2 | `grimdark_ui_hud.md:66` vs `grimdark_ships.md:193` | **Licence-rule conflict: a dual-badge asset is admitted as a candidate in one report and rejected in the other, with no cross-reference.** C10 (*Rust (semi seamless)*, pyranostudios) is carried in the UI candidate table with the evidence line "Badge shows **two** licences: `OGA-BY 4.0` and `CC0`" and the note "Dual-licensed: the CC0 option is what is being taken". `grimdark_ships.md:193` rejects the same page for exactly that reason ("Rejected for the same dual-badge reason"). `grimdark_ui_hud.md:4` sets the same constraint ("GPL, CC-BY, CC-BY-SA, OGA-BY and unclear entries are rejected even when visually strong"), so the report contradicts its own stated rule as well. The badge pair was re-read on `https://opengameart.org/content/rust-semi-seamless`: `License(s): OGA-BY 4.0` **and** `CC0` both render, notice "Credit optional" — both reports described the page accurately; only the ruling differs. |

## Medium severity

| # | Report:line | Issue |
| --- | --- | --- |
| M1 | `grimdark_ui_hud.md:32` | **A4 (Old Unused UI Stuff): 5 of 8 download paths are host-less.** The cell gives one full URL then `/div.png, /garg.png, … /res.png, /resgrey.png, /respanel.png` with no host. Verified against the page HTML — all eight live at `https://opengameart.org/sites/default/files/`, and the two served-name claims are correct (`panel.png` → `panel_0.png`, `thing.png` → `thing_0.png`). Only the URLs are unusable as written. |
| M2 | `grimdark_ui_hud.md:33` | **A5 (UI Button): 2 of 3 download paths are host-less.** `buttonStock1d_1.png` (disabled) and `buttonStock1h_0.png` (hover) are given as bare relative paths after one full URL. |
| M3 | `grimdark_environment.md:69` | **False author attribution used as a provenance argument.** Row 31 is titled "Asteroids/Debris Set (Snabisch)" and notes "Same author as row 1 (City Building Game Art), so the debris vocabulary matches the hero wreck". The page author is **The_Scientist___**; "Snabisch" is only a commenter on that page (and the same commenter appears on the Spacewreck page, which is likely how the mix-up happened). `grimdark_ships.md:111` names the same URL's author correctly, so the two reports disagree about the same asset. |
| M4 | `grimdark_audio.md:118-119` | **Ellipsis placeholders and an un-annotated served-name claim in the two bretbernhoft rows.** The Rumbling cell lists `rumbling17.wav · rumbling18.wav · rumbling19_0.wav … rumbling28.wav (same path pattern)`; the page displays `rumbling19.wav` (no `_0`), and files 20-28 are left as an ellipsis rather than URLs. The Droning cell does the same (`drone53.wav · … · drone71.wav (same path pattern for 54–70)`). Everything else in those cells (counts, 42.3-46.1 MB and 21.2-46.1 MB ranges) verified. Not recommended in the top three, but both rows are candidates. |
| M5 | `grimdark_ui_hud.md:45-47` (and `:50`) | **Supersedes a conclusion in `ui_hud.md:14` without saying so.** `ui_hud.md:14` states "Fonts: only the Kenney family and `Boxfont Vector` are CC0 TTFs found". The grimdark pass then lists B1 (*GGBotNet Fonts CC0 All-in-1*, 45 TTF/OTF/WOFF faces), B2 (*Blaec*), B3 (*Boxy Bold*, TTF) and B6 (*RETRO_SPACE*, contains a TTF) — verified on the pages. B1 is described as "the single best CC0 font source found in **either pass**" and is said to close the *numerals* gap only; the earlier report's "only … found" claim is never marked as superseded, so the two reports contradict each other on the font inventory. |
| M6 | `grimdark_ships.md:122-123`, `:86`; `grimdark_environment.md:39` | **Duplicate recommendations with no cross-reference to the report that already owns the asset.** *Kenney Simple Space* and *Kenney Planets* are grimdark-ships candidates (flat 5) but are `environment.md:23` and `environment.md:22` entries, the latter recommended as "Primary planet source"; the ships report cites `ships_weapons.md` and `environment.md` elsewhere for shared Kenney packs (lines 120-121) but not for these two. *Spacewreck* is recommended by **both** grimdark reports (`grimdark_ships.md:86` rec 3, `grimdark_environment.md:39` row 1 / rec 3) and neither refers to the other, even though `grimdark_environment.md:6` states its candidates are deliberately not repeated from `environment.md`. |

## Low severity

| # | Report:line | Issue |
| --- | --- | --- |
| L1 | all four (section headings) | **Section naming drift (requirement 4 is still met).** `grimdark_audio.md:63` is `## Candidates` split into `### A`-`### G` so there is no single candidate table (same shape as `audio.md:36`); rejected headings differ (`## Rejected candidates` in `grimdark_ships.md:185` and `grimdark_environment.md:92`, `## Rejected list` in `grimdark_ui_hud.md:109`, `## Rejected` in `grimdark_audio.md:222`); `grimdark_environment.md` puts `## Method` (8) before `## Summary` (22). Any scripted consumer expecting one uniform table per report will fail on `grimdark_audio.md`. |
| L2 | `grimdark_ui_hud.md:50` | B6 (*Font RETRO_SPACE*) lists the sheet as `(sheet: /RETRO_SPACE.png)` — bare relative path. |
| L3 | `grimdark_ui_hud.md:77` | D5 (*Medieval Game Button Pack*) lists the single button as `(single-button SVG: /Button.svg)` — bare relative path. |
| L4 | `grimdark_ui_hud.md:38` | A10 URL contains an unencoded `@` (`FREEUIASSETPACK_BY@CAMTATZ.zip`) and is one of 13 rows carrying the blanket caveat "*(displayed file name; re-check on the page)*" with no indication of which names were actually resolved. `grep` found no `<hash>`-style token in any of the four reports, so no placeholder defect exists. |
| L5 | `grimdark_environment.md:47`, `:76-77` | Row 9 gives `bkgd_0.png … bkgd_7.png` with an ellipsis for the middle six and no host on the last (page lists all eight, verified); the adjacent-finds block gives `dipy18.png` and `edited_ship_1_0.png … edited_ship_3_0.png` host-less (a base directory is named in the same cell for the latter). |
| L6 | `grimdark_environment.md:40` | Row 2 parenthesises the full set as bare names (`OGA-Background-1/2/3.png`, `Starfield-7.png`) next to three proper URLs. Acceptable as names, but they sit in a download column. |
| L7 | `audio.md:138` (unchanged) vs `grimdark_audio.md:154-164` | **Coverage claim superseded without acknowledgement.** `audio.md:138` says "Only one genuine CC0 *combat* track was found that fits a space shooter". Section F of the grimdark report lists six-plus dark-combat candidates. It cross-references the earlier pick (*Fast fight / battle music (looped)*, cited at `grimdark_audio.md:167`) but never notes that the "only one" finding no longer holds. |
| L8 | `grimdark_ships.md:118` vs `environment.md:34` | Same station asset (ChaosShark shipyard, identical direct URL) assessed one way as a recommendation ("exactly the 'grubby space dock' a grimdark sector needs", rec 8) and the other way as a style failure ("wrong art style: pixel art with hard shadows vs. Kenney flat vector", placeholder only). Neither cites the other; not a hard contradiction because `environment.md` did not reject it. |
| L9 | `grimdark_audio.md:164` | The *Hardwar* row's download cell is `(see section B)` plus a URL rather than the URL alone — a reader must jump sections for one file that appears twice in the same report. |
| L10 | `grimdark_environment.md:47` | Provenance note: the row-9 page carries only a CC0 badge but sits in a public collection literally named "cc-by-3 possible game kits and gfx". No licence defect (badge re-read as CC0, single badge), but worth a manifest note given the project's CC-BY caution. |

## Cross-report contradictions (summary)

| Asset | One report | Other report | Status |
| --- | --- | --- | --- |
| Rust (semi seamless) | `grimdark_ui_hud.md:66` — candidate, "CC0 option is what is being taken" | `grimdark_ships.md:193` — rejected, dual badge | **Unresolved**, see H2 |
| Asteroids/Debris Set | `grimdark_ships.md:111` — author The_Scientist___ | `grimdark_environment.md:69` — author "Snabisch", "same author as row 1" | **Unresolved**, see M3 |
| CC0 TTF fonts | `ui_hud.md:14` — "only the Kenney family and Boxfont Vector" | `grimdark_ui_hud.md:45-47`, `:50` — GGBotNet 45 faces, Blaec, Boxy Bold TTF, RETRO_SPACE TTF | **Unresolved**, see M5 |
| CC0 combat music | `audio.md:138` — "only one genuine CC0 combat track" | `grimdark_audio.md:154-164` — six-plus candidates | Not acknowledged, see L7 |
| Spacewreck | `grimdark_ships.md:86` rec 3 | `grimdark_environment.md:39` row 1 / rec 3 | Duplicate, no cross-reference, see M6 |
| Kenney Planets / Simple Space | `environment.md:22-23` (planets "Primary") | `grimdark_ships.md:122-123` | Duplicate, no cross-reference, see M6 |

No case was found of an asset **recommended** in a grimdark report and explicitly **rejected** in an
earlier report (or vice versa). Every earlier-report rejection list (`ships_weapons.md:133`,
`ui_hud.md:85`, `audio.md:173`, `environment.md:60`) was compared name-by-name against the grimdark
candidate and recommendation lists; the two genuine conflicts are grimdark-vs-grimdark (H2, M3) and
the two "found nothing/superseded" claims are grimdark-vs-earlier (M5, L7).

## Requirement checks

| Requirement | Result |
| --- | --- |
| 4. Summary + candidate table + recommendations + rejected list in every report | **Pass** for all four. `grimdark_ships.md` 14/81/125/185; `grimdark_ui_hud.md` 8/21/79/109; `grimdark_audio.md` 9/63/185/222 (sections A-G instead of one table, see L1); `grimdark_environment.md` 22/33/80/92. |
| 5. No downloaded files, no edits to the earlier reports | **Pass for the grimdark pass; one caveat about the workspace.** See the dedicated section below. |
| 3. Top-3 licence spot check | **Pass, 12 of 12 matched** (plus 6 extra pages checked, all CC0 as claimed). See the table below. |
| 2. Placeholder / broken-looking URLs verified against source pages | **Fail on 10 cells** (H1, M1, M2, M4, L2, L3, L5, L6, L4) — no `<hash>`-style placeholders exist, but one wrong served filename, one ellipsis-with-`_0` claim and two clusters of host-less sibling paths do. |
| 1. Cross-report contradictions | **2 blocking (H2, M3), 2 advisory (M5, L7), 2 duplicates (M6).** See above. |

### Top-3 spot checks (licence badge read directly from the source page)

| Report | Recommendation rank | Candidate | Claimed | Found on page | Match |
| --- | --- | --- | --- | --- | --- |
| grimdark_ships | rec 1 | Animated CC0 Ships v2.0 (ZaninDevelopers) | CC0 | `License(s): CC0`; files `damageddystopianship.png`, `dystopianship.png`, `fighterjet.png`, `zanindevs_v.2ships.zip` | Yes |
| grimdark_ships | rec 2 | Lite spaceship pack (Jarusca) | CC0 | `License(s): CC0`; "x2 races … 28x debris x3 effects"; single `lite_spaceship_pack.png` | Yes |
| grimdark_ships | rec 3 | Spacewreck (City Building Game Art) | CC0 | `License(s): CC0`; "Mangled and completely destroyed space structure"; zip 8.8 MB | Yes |
| grimdark_ui_hud | rec 1 / B1 | GGBotNet Fonts CC0 (All-in-1) | CC0 | `License(s): CC0`; "45 fonts"; `ggbotnet_fonts_cc0_2025_dec.zip` 22.3 MB | Yes |
| grimdark_ui_hud | rec 1 / B2 | Blaec Font | CC0 | `License(s): CC0`; 836 glyphs, 90 languages, two styles; `blaec_font_1_2.zip` 243.7 KB | Yes |
| grimdark_ui_hud | rec 1 / B3 | Boxy Bold - TrueType Font | CC0 | `License(s): CC0`; href `Boxy-Bold-Font_0.zip` (the report's URL and its trap note are both correct) | Yes |
| grimdark_audio | rec 1 | Horror Atmosphere (SubspaceAudio / Juhani Junkala) | CC0 | `License(s): CC0`; "loops seamlessly", "full duration is 5:23"; OGG 14.2 MB | Yes |
| grimdark_audio | rec 1 | Ambience Pack 1 — Sci Fi Horror (Joth) | CC0 | `License(s): CC0`; 5 tracks, 957 KB-1.2 MB each | Yes |
| grimdark_audio | rec 2 | Factory ambiance (yd) | CC0 | `License(s): CC0`; `Factory.ogg` 2.5 MB | Yes |
| grimdark_environment | rec 1 / row 3 | Horror Texture Pack (Screaming Brain Studios) | CC0 | `License(s): CC0`; "released under the CC0/Public Domain license"; 14/14/14/15/15/14/14 = 300 at 3 sizes | Yes |
| grimdark_environment | rec 2 / row 2 | Space Backgrounds 9 (Rawdanitsu) | CC0 | `License(s): CC0`; the three `-Tiled` files exist at the sizes quoted (3.3-10.4 MB) | Yes |
| grimdark_environment | rec 3 / row 1 | Spacewreck | CC0 | as above | Yes |

Extra pages read outside the top-three sample (all matched): `grimdark_audio` *30 CC0 SFX loops*
(CC0, 11 machine loops), `grimdark_environment` *Burnt Coal Ashes Tiling 1024* (CC0) and *Perfectly
Seamless Night Sky* (CC0, `Starbasesnow.png` 3.5 MB), `grimdark_ships` Kenney *Pattern Pack Extra*,
*Splat Pack* and *Light Masks* (all CC0 with live release hashes, see below).

### Verified correct (do not re-litigate)

- **No `<hash>` or `TODO`-style placeholder exists in any of the four grimdark reports** (regex sweep
  over all four files). This is the defect class that blocked the earlier cycle; it is absent here.
- **Three Kenney release hashes from `grimdark_ships.md` were resolved and matched byte for byte**
  against the live pages: `pattern-pack-extra/270736c7fd-1786626805` (`:98`),
  `splat-pack/1070534984-1677495350` (`:99`), `light-masks/6530e254f9-1775631687` (`:100`). The two
  reused hashes at `:120-121` were already verified in the earlier cycle.
- **`grimdark_ships.md` has no malformed download URL**: every one of its ~45 links is a concrete
  `https://…` file URL, and the sampled ones (Spacewreck zip, hex-tile albedo, `gunner.png`,
  `steel tile.svg`, Raider `.7z`, Ragnar zip) resolve to the displayed filenames.
- **The three "trap" filename claims in `grimdark_ui_hud.md:158` are each correct**: read from the
  page HTML, `BloodOverlay.png` → `BloodOverlay_0.png`, `alien_jar_hud.zip` → `alien_jar_hud_1.zip`,
  `panel.png`/`thing.png` → `panel_0.png`/`thing_0.png`, and `Boxy-Bold-Font.zip` →
  `Boxy-Bold-Font_0.zip`.
- **Rows whose self-doubt can be cleared** (the printed URL equals the page's filename and no suffix
  is involved): A6 `Ronnan-login-box.png` (`:34`), A7 `Ronnan-game-minimap.zip` (`:35`),
  A9 `UIpack_RPG.zip` (`:37`), C2 `deadCover.png` (`:58`), C9 `metal_04.jpg` (`:65`),
  C11 `high_voltage_1024.png` (`:67`), D2 `speedometer.png` (`:74`).
- **Sampled content claims confirmed**: Spacewreck zip 8.8 MB with a `Snabisch` comment on the page
  (source of the M3 mix-up); High Voltage sign 1024×1024, 1.1 MB; 2048 metal panel 1.2 MB; beren77
  1280×800, 454.3 KB; Rumbling sizes 42.3-46.1 MB; Droning 21.2-46.1 MB across drone53-drone71;
  Parallax Space Scene eight `bkgd_0…7.png` at 30 KB-1.6 MB; Rawdanitsu Space Backgrounds 9 file
  names and `-Tiled` variants.

## Downloads and edits check (requirement 5)

**No grimdark candidate was downloaded.** Every grimdark-only asset name family was searched across
`asset-library/` (`zanindevs`, `spacewreck`, `lite_spaceship`, `ggbotnet`, `blaec`, `miko`,
`scifitextures`, `horror`, `ambience`, `rumbling`, `droning`, `monster_roar`, `grunge`, `cooldown`,
`splat`, `light-masks`, `pattern-pack`, …): zero matches in the file tree and zero matches inside
`ASSET_MANIFEST.json`. The grimdark reports' own "Nothing was downloaded" statements hold for their
own candidate sets.

**No earlier report was edited during or after the grimdark pass.** File mtimes (UTC+local, same day):
`audio.md` 20:44, `environment.md` / `ships_weapons.md` / `ui_hud.md` 20:55, `REVIEW.md` 20:58, then
the grimdark files at 21:27-21:32. All four earlier reports predate the grimdark reports by 30+ minutes
and none were touched afterwards, which is consistent with their own fix-list cycle having closed at
20:58.

**Caveat the reviewer must record: the workspace is not download-free.** `asset-library/` holds a
completed download-and-extract batch dated 21:19-21:38 — `raw-sprites/` (12 loose zips/PNGs at 21:19
including `200starships.zip`, `kenney_spaceshooterextension.zip`, `pudman_ships_dg2a.png`),
`raw/audio/` (21:22), `raw/sprites/` + `raw/sprites/environment/` (21:31), `raw/ui/` (21:38), plus a
rebuilt `ASSET_MANIFEST.json` and `CREDITS.md` at 21:19. Every one of those files maps to an
**earlier** report's recommendation (`ships_weapons.md`, `audio.md`, `ui_hud.md`, `environment.md`),
not to a grimdark one, so the grimdark reports' claims are unaffected — but `raw/ui/` was still being
populated at 21:38, six minutes **after** `grimdark_ui_hud.md` was written at 21:32. Two consequences
worth noting for the next pass: (a) a batch worker was running concurrently with the grimdark
research, so "nothing was downloaded" can only be asserted per candidate set, not per workspace; and
(b) `raw-sprites/` shows the flattened-subfolder behaviour the grimdark reports warn about, while the
`raw/ui`, `raw/audio` and `raw/sprites` trees are properly nested.

## Fix list for the grimdark batch

1. Replace `Starfield-7_0.jpg` with `Starfield-7.jpg` at `grimdark_environment.md:44` and correct
   "3 `Background-*.jpg`" to four files (H1).
2. Decide the dual-badge policy once and apply it everywhere: either drop C10 from
   `grimdark_ui_hud.md:66` (matching `grimdark_ships.md:193` and the report's own line 4) or annotate
   both rows with the agreed exception rationale and a cross-reference (H2).
3. Prefix the host on the sibling filenames at `grimdark_ui_hud.md:32` (five) and `:33` (two), or
   mark them as names rather than URLs (M1, M2).
4. Correct the author of the *Asteroids/Debris Set* row at `grimdark_environment.md:69` to
   The_Scientist___ and delete the "same author as row 1" inference (M3).
5. Expand or drop the ellipsis URLs at `grimdark_audio.md:118-119`, and annotate `rumbling19_0.wav`
   as a served name against the page's displayed `rumbling19.wav` (M4).
6. Add a one-line note to `grimdark_ui_hud.md:45` recording that B1/B2/B3/B6 supersede
   `ui_hud.md:14`'s "only the Kenney family and Boxfont Vector are CC0 TTFs found" (M5).
7. Add cross-references for the four duplicated assets in M6 and for the ChaosShark station at
   `grimdark_ships.md:118` (L8).
8. Expand the remaining bare paths at `grimdark_ui_hud.md:50`, `:77` and `grimdark_environment.md:47`
   /`:76-77` (L2, L3, L5), and encode the `@` at `grimdark_ui_hud.md:38` (L4).

## Re-review 2026-09-16 cycle 2

**Verdict: PASS.** All 8 fix-list items are satisfied and no new contradiction was introduced, with one residual broken-URL defect and three cosmetic notes recorded below.

Method: file-level re-read of all four grimdark reports; a per-file table check (every table block has a uniform pipe count, and inline backtick / bold pairs balance on every line); and eight source pages re-read from their live HTML this cycle (Rawdanitsu *Starfields…*, *Asteroids/Debris Set*, *Rumbling Sound Effects*, *Droning Sound Effects*, *Old Unused UI Stuff*, *UI Button*, *Medieval Game Button Pack*, *FREE UI ASSET PACK 1*) so the served `href` behind each displayed name could be compared with what the reports now print. Nothing was downloaded; no file other than this review was touched.

| # | Fix item | Result |
| --- | --- | --- |
| 1 | H1 — wrong served filename / count at `grimdark_environment.md:44` | **Pass.** Row 6 prints `Starfield-7.jpg` with no `_0`, and "4 `Background-*.jpg` (11 files total)". Page re-read: `Starfield-7.jpg` serves as `Starfield-7.jpg`, `Starfield-5.jpg` is the one that carries `_0`, and the file list is 7 starfields + 4 backgrounds = 11. |
| 2 | H2 — dual-badge `Rust (semi seamless)` admitted in one report, rejected in the other | **Pass.** C10 is gone from the UI candidate table and now sits in the rejected list at `grimdark_ui_hud.md:136`, rejected on its own line-4 rule and cross-referenced to `grimdark_ships.md:193`, which is still that report's Rust row. No `C10` reference survives in the file. |
| 3 | M1/M2 — host-less sibling filenames at `grimdark_ui_hud.md:32` (five) and `:33` (two) | **Pass.** All eight A4 files and all three A5 files are full `https://opengameart.org/sites/default/files/` URLs and match the page hrefs exactly, including `panel_0.png` / `thing_0.png` and `buttonStock1d_1.png` / `buttonStock1h_0.png`. |
| 4 | M3 — false author at `grimdark_environment.md:69` | **Pass.** The row now reads The_Scientist___ and records that "Snabisch" is a commenter, not the author; the page's Author field confirms it and the `Snabisch` comment ("Excellent design") is on the page. The "same author as row 1" inference is deleted and the row now agrees with `grimdark_ships.md:111`. |
| 5 | M4 — ellipsis URLs and un-annotated served name at `grimdark_audio.md:118-119` | **Pass.** All 12 Rumbling and all 19 Droning URLs are listed; `rumbling19_0.wav` is annotated against the displayed `rumbling19.wav`. Both added "every file is served under its displayed name" claims hold (only rumbling19 differs), and the 42.3-46.1 MB / 21.2-46.1 MB ranges match the page file list. |
| 6 | M5 — supersession note for `ui_hud.md:14` | **Pass.** `grimdark_ui_hud.md:45` carries a supersession note naming B1/B2/B3/B6, and `ui_hud.md:14` still reads "only the Kenney family and `Boxfont Vector` are CC0 TTFs found", so the note points at a live claim rather than a stale one. |
| 7 | M6/L8 — cross-references for the duplicated assets and the ChaosShark station | **Pass.** Spacewreck is cross-referenced both ways (`grimdark_ships.md:86` ↔ `grimdark_environment.md:39`), Kenney `Simple Space` and `Planets` point back to `environment.md:23`/`:22` (whose "best sector-map bet" and "Primary planet source" wording they quote accurately), and `grimdark_ships.md:118` now cites `environment.md:34` for the shipyard. |
| 8 | L2/L3/L5/L4 — bare paths and the unencoded `@` | **Pass.** `:50` and `:77` are full URLs (`RETRO_SPACE.png` and `Button_0.svg` both equal their page hrefs); `grimdark_environment.md:47` lists all eight `bkgd_*.png` and `:76-77` gives `dipy1`-`dipy18` host-included; A10 is `FREEUIASSETPACK_BY%40CAMTATZ.zip`, which is byte-identical to the page's own href. |

### Residual findings (none are fix-list regressions)

- **R1 — broken served filename, same class as H1 (fix before the batch).** `grimdark_ui_hud.md:76` (D5) prints `https://opengameart.org/sites/default/files/Files.zip`, but the page's own href for the displayed `Files.zip` is `.../sites/default/files/Files_0.zip` (4.7 MB). The corrected `Button_0.svg` in the same cell is right, so the row now mixes a verified served name with an unverified sibling; only the cell's "*re-check on the page*" caveat covers it. Cycle 1 checked the button SVG but not this archive.
- **R2 — cosmetic.** Removing C10 leaves the UI candidate table numbered C1-C9 then C11. Nothing references C10 any more, but a consumer keyed on sequential ids will see a gap.
- **R3 — cosmetic.** In `grimdark_environment.md:44` the abbreviated starfields range ends with the final URL wrapped in backticks, so `Starfield-7.jpg` renders as inline code rather than a link; the range itself stays an explicit abbreviation ("numbered variants").
- **R4 — advisory, open since cycle 1 and outside the 8-item list:** L1 (section-name drift across the four reports), L6 (row 2 at `grimdark_environment.md:40` keeps bare set names in a download column), L7 (`audio.md:138` "only one genuine CC0 combat track" is still not marked superseded by section F), L9 (`Hardwar`'s `(see section B)` cell at `grimdark_audio.md:164`), L10 (row 9's `cc-by-3 possible game kits and gfx` collection name).
- **Markdown integrity:** no table block in the four reports has a non-uniform cell count, no line carries an unbalanced backtick or bold marker, and all four reports still contain summary + candidate table + recommendations + rejected list. The edits changed no other content: all 8 fix targets still sit on their original line numbers, so every line reference in the sections above remains valid.
