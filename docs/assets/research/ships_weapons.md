# Vajb Orbit — CC0 Ships & Weapons Research

Date: 2026-09-16 · Scope: free **CC0** 2D spaceship, turret and weapon/projectile sprite packs for a
2D top-down Dark Orbit clone (Godot 4.7.2, Forward+).
Style baseline: Kenney flat vector — *Space Shooter Remastered/Redux*, already owned at
`asset-library/raw/sprites/space_shooter_redux/` (5 player ships ×4 colours + damage states, 4 enemy
families, 3 laser colours ×16 variants, meteors, engine/fire/star FX).
Method: OpenGameArt advanced search with the CC0 licence facet (`field_art_licenses_tid[]=4`) and the
Kenney catalogue, then **every candidate page was opened and its licence badge/text read directly**.
Search metadata was never trusted. **Nothing was downloaded.**
Policy reference: `docs/ASSETS.md` (CC0-only; CC-BY needs an explicit exception and exact credit string).

## Summary

- **The need is fully coverable in CC0.** 30 verified CC0 candidates; no CC-BY, GPL or unclear-licence
  asset is required for ship tiers, factions, turrets or weapon variety.
- **Best find: *200+ CC0 Spaceship Sprites* (Wisedawn).** 211 ships in 4 styles, procedurally generated
  with Vesselforge *from Kenney's own spaceship parts* — so it is Kenney-style by construction and is
  the cheapest way to get ship upgrade tiers and faction variants without new art direction.
- ***Space Shooter Extension* (Kenney) is the single most valuable gap-filler.** It was explicitly
  authored as an add-on to Space Shooter Redux: missiles, rocket parts, new ship parts, satellites,
  meteors — the same palette, outlines and shading as the art we already ship. It should be the first
  download.
- **Two packs ship vector source, which matters more than sprite count.** *Alien Spaceship Sprite Pack*
  (pzUH: PNG + AI/EPS/CDR) and Kenney's original *Space Shooter art* (PNG + SVG + AI) can be recoloured
  per faction without redrawing, and exported at any resolution for a zooming top-down camera.
- **Modular ships are the other lever.** *2d space shooter assets* (pudman) has interchangeable
  wings/hulls plus coloured bullets, weapons and a jet-exhaust trail, and *Spaceship Construction Kit*
  (SpriteAttack) is SVG parts only — both let one sprite budget produce many visual tiers.
- **Turrets exist in CC0 and are not a gap.** *SciFi rotating wall turret* (128×128, separate rotating
  heads + cocos2d plist), the gun/rocket/laser icons in *Space icons with base, defensive guns…*, and
  Master484's ground/ceiling turret set in *Side Blaster GFX* cover stationary defences.
- **Real remaining gap: weapons in the Kenney flat-vector look at sprite scale.** CC0 weapon/projectile
  art outside Kenney is mostly pixel art (GrafxKid, ansimuz, Raider, surt) or Photoshop-only
  (Tatermand). Practical answer: Kenney's laser variants + Extension missiles + *Particle Pack* +
  *Crosshair Pack*, and treat the pixel packs only as silhouettes to trace.
- **Format caveats to plan around:** (a) several packs are ZIP/7z whose inner format the page does not
  state — verify after extraction; (b) the Tatermand packs are `.psd` only, so they are effectively
  unusable in this pipeline; (c) Kenney zip links are release-hashed and change, so archive the zip
  rather than the extracted folder.

### Evidence method (repeatable)

```
# CC0-faceted 2D-art search per term
https://opengameart.org/art-search-advanced?keys=<term>&field_art_type_tid%5B%5D=9&field_art_licenses_tid%5B%5D=4&sort_by=count&sort_order=DESC
# 9 = 2D Art, 4 = CC0 licence facet
```
Every row's licence was confirmed by reading the page's `License(s):` badge
(`https://opengameart.org/sites/default/files/license_images/cc0.png` → `creativecommons.org/publicdomain/zero/1.0/`)
or, for Kenney, the page header `License Creative Commons CC0`. Pages read 2026-09-16.

Fit score: 5 = drop-in for a top-down Dark Orbit clone, right licence, right flat-vector style, usable
formats · 4 = strong fit, light processing (recolour/rotate/slice) · 3 = usable with a style
compromise · 2 = license-clean but wrong style or scale · 1 = unusable.

## Candidate table

| Name | Source URL | License + evidence | What it contains | Formats | Fit | Direct download URL | Notes |
|---|---|---|---|---|---|---|---|
| Space Shooter Extension (Kenney) | https://opengameart.org/content/space-shooter-extension-250 · https://kenney.nl/assets/space-shooter-extension | CC0 — OGA page `License(s): CC0` badge; Kenney page header `Files 270 · License Creative Commons CC0` → creativecommons.org/publicdomain/zero/1.0/ | 270+ sprites: missiles, rocket parts, new ship parts, satellites, meteors — page states it "fits the Space Shooter Redux package" | PNG (separate), spritesheet(s), vector files, retina sizes | 5 | https://opengameart.org/sites/default/files/kenney_spaceShooterExtension.zip · https://kenney.nl/media/pages/assets/space-shooter-extension/d0bd70032c-1677693518/kenney_space-shooter-extension.zip | **First download.** Same vendor, palette and outline weight as the owned baseline, so zero style work. Covers the weapon/projectile-variety need in one shot. Kenney's hash-based link changes per release — archive the zip. Fit score is scoped to this report and not comparable across reports (`environment.md:41` records the same asset). |
| 200+ CC0 Spaceship Sprites (Wisedawn) | https://opengameart.org/content/200-cc0-spaceship-sprites | CC0 — page `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | 211 spaceships generated with Vesselforge, in 4 different styles; Vesselforge builds from Kenney's spaceship parts | PNG (zip) | 5 | https://opengameart.org/sites/default/files/200Starships.zip | Best source of **upgrade tiers / faction fleets**: 4 consistent style families × many hulls = tier progression without hand-authoring. Derived from Kenney CC0 parts, so provenance is clean. Credit requested but optional. |
| Alien Spaceship Sprite Pack (pzUH) | https://opengameart.org/content/alien-spaceship-sprite-pack | CC0 — page `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | Alien spaceships in various sizes, explicitly "useful for top-down space shooter projects" | PNG **and vector** (CorelDraw, Illustrator, EPS) in zip | 5 | https://opengameart.org/sites/default/files/Ship.zip | Vector source is the headline: recolour per faction and export at any scale for a zooming camera. Alien silhouettes read as a distinct faction next to Kenney's human ships. |
| 2d space shooter assets (pudman) | https://opengameart.org/content/2d-space-shooter-assets | CC0 — page `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | "All the wings and ships are full interchangeable", a variety of bullets in different colours, a few different weapons, a jet-exhaust trail, plus a modular space station | PNG (2 sheets: dg2a.png 446 KB, ft.png 170 KB) | 5 | https://opengameart.org/sites/default/files/dg2a.png · https://opengameart.org/sites/default/files/ft.png | Modular hulls/wings = many cheap ship tiers from one sheet; the coloured bullet set is exactly the projectile variety asked for. Two flat PNG sheets, so slice with `slice_sprite_sheet`. No enemies. |
| Space Shooter Remastered / Redux (Kenney) | https://kenney.nl/assets/space-shooter-remastered · https://opengameart.org/content/space-shooter-redux | CC0 — Kenney page header `License Creative Commons CC0`; OGA page `License(s): CC0` badge | 295+ sprites (2014 pack), four backgrounds, spritesheet, vector files, bonus 2 TTF fonts and 7 sound effects | PNG, spritesheet, vector, TTF | 5 | https://kenney.nl/media/pages/assets/space-shooter-remastered/2cbf3c45c8-1774771931/kenney_space-shooter-remastered.zip · https://opengameart.org/sites/default/files/SpaceShooterRedux.zip | Already owned — listed only as the style reference and because the OGA mirror is a stable fallback if a Kenney link rots. Note the Kenney slug is now `space-shooter-remastered`; `space-shooter-redux` returns 404. Fit score is scoped to this report and not comparable across reports (`environment.md:42` records the same asset). |
| Space Shooter art (Kenney, original 2012 pack) | https://opengameart.org/content/space-shooter-art | CC0 — page `License(s): CC0` badge; author is Kenney | Player ship, enemies, meteors, background, lasers — "everything" for a space shooter, **with source SVG and AI vector files** | PNG, **SVG**, **AI** | 4 | https://opengameart.org/sites/default/files/spaceArt.zip | Distinct sprite set from Remastered (not a duplicate), and the SVG/AI source is the cheapest route to faction recolours at any resolution. Small by modern standards. |
| Space Ship Sprite Sheet (Paul Wortmann) | https://opengameart.org/content/space-ship-sprite-sheet | CC0 — page `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | ~30 spaceships made in GIMP for a shooter, described as "simple ships progressing to more complex forms" | PNG in zip | 4 | https://opengameart.org/sites/default/files/ships_0.zip | The explicit simple→complex progression is a ready-made upgrade ladder. Some sprites have clipped baked shadows — check on a contact sheet before slicing. |
| 2D spaceship sprites with engines (morgan3d) | https://opengameart.org/content/2d-spaceship-sprites-with-engines | CC0 — page `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | 12 ships derived from surt's CC0 modular ships, grid-aligned, black outlines completed, alpha masks added, upsampled 4× (hq4x), plus **separate alpha-masked rocket-fire sprites per ship** | PNG | 4 | https://opengameart.org/sites/default/files/ships.png | Cleanest CC0 ship sheet found: uniform grid, transparent, with matching thruster FX per ship. Source is 8×8-grid pixel art, so it reads slightly chunkier than Kenney — test against the Redux ships first. |
| Sci-Fi Shoot 'em up object images (mieki256) | https://opengameart.org/content/sci-fi-shoot-em-up-object-images | CC0 — page `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | Object sprites at 64/48/32/96 px, boss sprites, and a separate effects pack | PNG + GIF in three zips | 4 | https://opengameart.org/sites/default/files/shmup_obj.zip · https://opengameart.org/sites/default/files/shmup_obj_boss.zip · https://opengameart.org/sites/default/files/shmup_effects.zip | Boss-sized sprites are rare in CC0 and useful for sector bosses. Style is soft-shaded vector-ish, not Kenney-flat — acceptable for alien/energy factions. |
| Space icons with base, defensive guns, ships & scenery (titmouse001) | https://opengameart.org/content/space-icons-with-base-defensive-guns-ships-scenery | CC0 — page `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | One icon sheet: defensive guns, rockets, lasers, booster, station, moon, asteroid, scenery blocks | PNG (single sheet, 17.3 KB) | 4 | https://opengameart.org/sites/default/files/SpaceBlocks_0.png | Cheapest turret/defence-gun source in CC0 (single small sheet, flat icon style). Also doubles as HUD/sector-map icons. Low resolution — fine for icons and small turrets, not for hero ships. |
| SciFi rotating wall turret (tebruno99) | https://opengameart.org/content/scifi-rotating-wall-turret | CC0 — page `License(s): CC0` badge; author explicitly re-licensed from CC-BY to public domain | A wall turret whose **heads rotate** over a static base, 128×128, 2 px spacing/margin, plus a cocos2d plist describing frames | PNG + plist in zip | 4 | https://opengameart.org/sites/default/files/WallTurret.zip | Purpose-built for stationary defences in a top-down shooter; the plist makes frame slicing mechanical. Single turret colour — recolour per faction/tech tier. |
| Side Blaster GFX (Master484) | https://opengameart.org/content/side-blaster-gfx-m484-games | CC0 — page `License(s): CC0` badge; author states "All graphics and sounds here are in the Public Domain. Attribution is not needed." | Complete horizontal shmup set across three themes: fighters, UFOs, robots, **ground and ceiling turrets**, laser walls, re-generating bubble walls, spinner drones, most animated, with alive/destroyed variants, 34 SFX, menu art and fonts | PNG (zip) + SFX + fonts | 4 | https://opengameart.org/sites/default/files/Side%20Blaster%20GFX.zip | Turret and enemy variety is excellent and the alive/destroyed pairs map directly to damage states. Art is side-view with baked shading, so it needs rotation and a brightness pass to sit with Kenney; treat as turret/drone/obstacle source, not hero ships. |
| Spaceship Construction Kit (SpriteAttack) | https://opengameart.org/content/spaceship-construction-kit | CC0 — page `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | Vector spaceship components for assembling fighters, authored in Inkscape (also Affinity/Illustrator compatible) | SVG (zip) | 4 | https://opengameart.org/sites/default/files/Spaceship_kit.zip | Pure-vector parts = infinite tier scaling and exact palette matching to Kenney. Side-on parts, so top-down use needs rotation/re-posing. Pairs with pudman's modular sheet for one kit-bash pipeline. |
| Simple SVG / Vector Spaceship (Bonsaiheldin) | https://opengameart.org/content/simple-svg-vector-spaceship | CC0 — page `License(s): CC0` badge; attribution notice says credit "not necessary but if you want: Bonsaiheldin | Link to this page" | One vector spaceship **plus a matching turret/cannon** drawn in Inkscape | SVG | 4 | https://opengameart.org/sites/default/files/spaceship_3.svg · https://opengameart.org/sites/default/files/turret_3.svg | Best *style* match to flat vector found (flat fills, clean outlines) and the ship+turret share one look. Only two files — a palette/shape reference rather than a fleet; good for the player's starter hull. |
| Crosshair Pack (Kenney) | https://kenney.nl/assets/crosshair-pack | CC0 — Kenney page header `Files 200 · Tile size 64 × 64 · License Creative Commons CC0` | 200 targeting reticles at 64×64, v1.1 added vector and glow variants | PNG + vector | 4 | https://kenney.nl/media/pages/assets/crosshair-pack/5ef74bd405-1785950072/kenney_crosshair-pack.zip | Same vendor and flat style; covers lock-on reticles, turret target markers and mining focus ring. Hash resolved from the page on 2026-09-16. Fit score is scoped to this report and not comparable across reports (`ui_hud.md:26` records the same asset). |
| Particle Pack (Kenney) | https://kenney.nl/assets/particle-pack | CC0 — Kenney page header `Files 80 · Tile size 512 × 512 · License Creative Commons CC0` | 80 particle/VFX textures (512×512) with shader/VFX tags | PNG | 3 | https://kenney.nl/media/pages/assets/particle-pack/f8fe0f8cb8-1677578741/kenney_particle-pack.zip | Secondary but cheap: laser glow, muzzle flash, engine trails, explosion smoke — the VFX layer around the weapons rather than weapons themselves. Large tiles; downscale on import. |
| Complete Spaceship Game art pack (sujit1717 / Unlucky Studio) | https://opengameart.org/content/complete-spaceship-game-art-pack | CC0 — page `License(s): CC0` badge; author: "You can use it anywhere you want. Credits are not required but much appreciated." | A full spaceship art pack with matching UI, released as a monthly royalty-free pack | PNG (zip) | 3 | https://opengameart.org/sites/default/files/Royalty%20Free%20Game%20Art%20-%20Spaceships%20from%20Unlucky%20Studio.zip | Style is cartoon-realistic with gradients and text on the sheet, not flat vector — will read as a different game next to Kenney. **Warning:** the author notes the OGA zip has missing sprites and links a corrected zip on unluckystudio.com; verify contents before committing. |
| Animated spaceships (Jull) | https://opengameart.org/content/animated-spaceships | CC0 — page `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | 8 spaceships at 32×32, 7 of them animated, made for a manic shooter | PNG in zip (Ships_1.zip) | 3 | https://opengameart.org/sites/default/files/Ships_1.zip | Real animation is rare in CC0 ships and worth having for banking/idle. 32×32 pixel art is small for a Dark Orbit-scale playfield, so treat as enemy-fighter tier only. |
| Space Shooter Assets (immersivegamer) | https://opengameart.org/content/space-shooter-assets | CC0 — page `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | An asteroid, a spaceship, a star animation (single strip and three-strip Unity particle variant), as individual files and a sheet | PNG in zip | 3 | https://opengameart.org/sites/default/files/Space_Attack_Images.zip | Small pack; the star-strip animation is genuinely handy for warp/teleport VFX. Only one ship, so no tier value. |
| Arcade Space Shooter Game Assets (GrafxKid) | https://opengameart.org/content/arcade-space-shooter-game-assets | CC0 — page `License(s): CC0` badge; attribution notice: "Credit me as GrafxKid" | Retro set: player ship, power-ups, shots, 3 enemy designs, UI graphics, tileable animated space background | PNG (single sheet) | 3 | https://opengameart.org/sites/default/files/arcade_space_shooter.png | Very complete gameplay coverage in one file, but 8-bit pixel style clashes with flat vector. Use as silhouette/design reference or for a deliberately retro faction. |
| Space-themed sprites / "Raider" assets (Vidmaster) | https://opengameart.org/content/space-themed-sprites | CC0 — page `License(s): CC0` badge; author: "release these sprites under public domain" | Various space ships, **turrets**, energy torpedoes, debris from the arcade game "Raider" | PNG in 7z | 3 | https://opengameart.org/sites/default/files/Raider%202D%20assets.7z | Turrets, torpedoes and debris in one CC0 drop. Pixel art, and the archive is `.7z` (needs a 7z extractor — `assetmcp` supports 7z). Style mismatch is the only reason it is not higher. |
| Warped Space Shooter (ansimuz) | https://opengameart.org/content/warped-space-shooter | CC0 — page `License(s): CC0` badge; attribution "by Ansimuz (optional)" | Player sprites, enemy sprites, asteroids, seamless looped backgrounds, music, SFX, plus a **Godot game template** | ZIP (pixel sprites, backgrounds) | 3 | https://opengameart.org/sites/default/files/space_shooter_files_0.zip | The Godot template is a free reference implementation and the backgrounds/asteroids are reusable. Ship art is pixel style, so not a fit for the flat-vector fleet. |
| Some top-down spaceships (Rawdanitsu) | https://opengameart.org/content/some-top-down-spaceships | CC0 — page `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | A small set of top-down ships, one with a "turning" animation; ships zip plus a Blender source file | ZIP + .blend | 3 | https://opengameart.org/sites/default/files/Ships.zip | Correct orientation, and the turning animation is useful. Comes from a 3D workflow, so shading is soft/rendered rather than flat — expect a style pass. |
| 2D Spaceship parts (wubitog) | https://opengameart.org/content/2d-spaceship-parts | CC0 — page `License(s): CC0` badge; "No attribution required." Author commissioned the art specifically for CC0 release | Wing and body parts for assembling ships (multiple bodies and wings as separate final PNGs) | PNG in zip | 3 | https://opengameart.org/sites/default/files/elance%20spaceship%20parts.zip | 371 KB of kit parts — useful for tier variety as a secondary to pudman's interchangeable set. Only a handful of pieces; style is closer to cel-shaded than Kenney flat. |
| 2d spaceship assets (danitorres567) | https://opengameart.org/content/2d-spaceship-assets | CC0 — page `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | One top-down spaceship, a meteorite, a background, planet Earth, an atmosphere layer, plus the layered PSD source | PNG, JPG, PSD | 3 | https://opengameart.org/sites/default/files/ship%202.png · https://opengameart.org/sites/default/files/methorite.png | Minimal ship value (one hull) but the atmosphere/planet layers are a bonus for sector-approach visuals. PSD source allows recolour. |
| Top-down Shooter (Kenney) | https://kenney.nl/assets/top-down-shooter | CC0 — Kenney page header `Files 580 · License Creative Commons CC0` → creativecommons.org/publicdomain/zero/1.0/ | 580 files of top-down 2D art (characters, weapons, props, tiles) | PNG | 2 | https://kenney.nl/media/pages/assets/top-down-shooter/230204340a-1677694684/kenney_top-down-shooter.zip | Correct vendor and style, and the loose weapon items could serve as pickups/HUD icons, but it is a ground-combat pack — no spaceships. Low priority. |
| Spaceship set 32x32px (Scrittl) | https://opengameart.org/content/spaceship-set-32x32px | CC0 — page `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | 5 top-down grey ships at 32×32 plus one 128×128 ship; archive has layered PDN and transparent PNGs | PNG, PDN | 2 | https://opengameart.org/sites/default/files/spaceshipset32x32.zip · https://opengameart.org/sites/default/files/enemy_4.png · https://opengameart.org/sites/default/files/player2.png | Grey-only pixel ships at small scale; the 128×128 hull is the only piece with Dark Orbit presence. Layered PDN is editable but Paint.NET-specific. |
| Modular Ships (surt) | https://opengameart.org/content/modular-ships | CC0 — page `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | Modular spaceship sprites on an 8×8 grid using Arne's 16-colour palette, built for shmups | PNG (single sheet) | 2 | https://opengameart.org/sites/default/files/modular_ships.png | The upstream source for morgan3d's cleaned-up sheet (row above). 8×8 pixels is too small; use the upsampled derivative instead. |
| CC0 Ships (surt + part2art.com) (wubitog) | https://opengameart.org/content/cc0-ships-surt-part2artcom | CC0 — page `License(s): CC0` badge; "No attribution required" | Orange surt modular parts, pieces reworked from part2art.com, top-down fighter and capital-ship sprites | PNG + ZIP | 2 | https://opengameart.org/sites/default/files/surtexample.zip | Provenance chain is worth noting (part2art.com parts re-released as CC0 by the uploader) but it is small pixel art. Revisit only if the morgan3d sheet proves insufficient. |
| Nimrod & Scrittl's Spaceships | https://opengameart.org/content/nimrod-scrittls-spaceships | CC0 — page `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | 32×32 ships, a 128×128 boss ship with glowing red/blue eye GIF animations, a combined PNG spritesheet, and a layered PSD | PNG, GIF, PSD | 2 | https://opengameart.org/sites/default/files/Nimrod%20%26%20Scrittl%20ships.png | The animated glowing boss is the only interesting piece and could seed a sector boss; the rest is "Game Boy style" pixel art that will not blend with Kenney. |
| Vertical Shmup Set 2 (Master484) | https://opengameart.org/content/vertical-shmup-set-2-m484-games | CC0 — page `License(s): CC0` badge; "These graphics are in the Public Domain. Attribution is not needed." | ~30×30 px complete vertical shmup set: bullets, explosions, objects, ground tiles for two levels; tanks split into turret + base parts with yellow damage-flash versions | PNG (single sheet, 45 KB) | 2 | https://opengameart.org/sites/default/files/M484VerticalShmupSet2.png | Mostly ground tiles and tanks, not spaceships — but the separate turret/base split and damage-flash convention are worth copying for our own turrets. Low direct value. |
| Pixel Shmup (Kenney) | https://kenney.nl/assets/pixel-shmup | CC0 — Kenney page header `Files 128 · Tile size 16 × 16 · License Creative Commons CC0` | 128 files, 16×16 pixel shmup art (ships and props) | PNG | 2 | https://kenney.nl/media/pages/assets/pixel-shmup/640246b9cc-1677495782/kenney_pixel-shmup.zip | Kenney provenance, but 16×16 pixel art is the opposite of the flat-vector baseline. Keep on the shelf. |
| Space Icons (arikel) | https://opengameart.org/content/space-icons | CC0 — page `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | Nine 128×128 PNG button icons for a space game, plus the Blender source | PNG, BLEND | 2 | https://opengameart.org/sites/default/files/topbuttons.zip | UI buttons rather than gameplay sprites. Overlaps the already-noted HUD/minimap gap, but the art is a Freelancer-style rendered look, not flat vector. Fit score is scoped to this report and not comparable across reports (`ui_hud.md:41` records the same asset). |

## Recommendations

Priority order for the next (download) batch. All CC0, no attribution owed.

1. **Space Shooter Extension (Kenney)** — https://opengameart.org/sites/default/files/kenney_spaceShooterExtension.zip.
   Highest value per megabyte in the whole report: same look as the owned fleet, and it fills the
   weapon/projectile/part gap immediately. Download this before anything else.
2. **200+ CC0 Spaceship Sprites (Wisedawn)** — https://opengameart.org/sites/default/files/200Starships.zip.
   This is the upgrade-tier and faction engine: 211 hulls in 4 consistent styles, Kenney-derived.
   Pull one style family as tier 1–3 player ships and a second as an enemy faction.
3. **2d space shooter assets (pudman)** — `dg2a.png` + `ft.png`. Modular wings/hulls plus the coloured
   bullet set gives per-tier silhouette variety and projectile colour coding with almost no new art.
4. **Alien Spaceship Sprite Pack (pzUH)** — https://opengameart.org/sites/default/files/Ship.zip.
   Vector-sourced alien faction; recolour freely and export at playfield resolution.
5. **Space Ship Sprite Sheet (Paul Wortmann)** — https://opengameart.org/sites/default/files/ships_0.zip.
   ~30 ships already ordered simple → complex; good candidate for a structured tier ladder.
6. **Turrets:** *SciFi rotating wall turret* (https://opengameart.org/sites/default/files/WallTurret.zip)
   plus the defensive-gun icons in *SpaceBlocks_0.png*. Add Master484's *Side Blaster GFX* only if
   animated turrets with alive/destroyed states are needed.
7. **Weapon FX layer:** Kenney *Particle Pack* (laser glow, muzzle flash, trails) and Kenney
   *Crosshair Pack* (lock-on reticles). Both CC0, both same vendor as the existing fleet.
8. **Only if the above leave gaps:** *Space Shooter art* (Kenney SVG/AI source for faction recolours),
   *2D spaceship sprites with engines* (morgan3d, for the per-ship thruster FX), *Sci-Fi Shoot 'em up
   object images* (mieki256, for boss-tier sprites).

Practical notes for that batch:

- Download into `asset-library/raw/sprites/<pack_name>/`, then move files by hand — `assetmcp` flattens
  the `subfolder` argument (see `docs/ASSETS.md`).
- Review each zip with `make_image_contact_sheet` before slicing; slice sheets with `slice_sprite_sheet`
  into `processed/sprites/`. Follow the existing naming (`ship_`, `enemy_`, `proj_`, `fx_`).
- Verify the real style fit against `raw/sprites/space_shooter_redux/` **before** committing to a pack —
  several candidates here are pixel art and will not blend.
- Two archives need non-standard handling: *Raider* is `.7z`, and *Complete Spaceship Game art pack* has
  a known incomplete OGA zip (corrected copy lives on unluckystudio.com).
- Rebuild `ASSET_MANIFEST.json` and `CREDITS.md` after import (`create_asset_manifest`,
  `generate_credits`) even though CC0 requires no attribution, then `audit_project_assets`.

## Rejected candidates

Verified and rejected:

| Asset | URL | Reason |
|---|---|---|
| Simple Shoot-'em-Up Sprites: Spaceship, Starscape, UFO (Gamedevtuts+ / Jacob Zinman-Jeanes) | https://opengameart.org/content/simple-shoot-em-up-sprites-spaceship-starscape-ufo-0 | **CC-BY 3.0** badge and an explicit attribution-required instruction ("We require attribution to Gamedevtuts+, and a link to this post… from anyone that redistributes"). Fails the CC0-only rule. |
| Nihil Ace spaceship building pack expansion (Buch) | https://opengameart.org/content/nihil-ace-spaceship-building-pack-expansion | **CC-BY 3.0** badge; "Credit me as Buch and link back to my OGA profile page." Attractive SVG content, but CC-BY needs an explicit exception, and row below means the whole family is contaminated. |
| Spaceship construction blocks (Buch) | https://opengameart.org/content/spaceship-construction-blocks | **CC-BY 3.0** badge with mandatory credit instruction. Checked specifically because the base pack is the vector kit people usually cite — it is not CC0. |
| Top-Down Sci-fi Shooter/Defense Pack (Tatermand) | https://opengameart.org/content/top-down-sci-fi-shooterdefense-pack | CC0, but the only file is an 11.9 MB **`.psd`** with layered soldier/character art — no exported PNG, and no spaceships. Wrong format and wrong subject. |
| 2D Shooter Effects (Alpha version) (Tatermand) | https://opengameart.org/content/2d-shooter-effects-alpha-version | CC0, but **`.psd` only** (no PNG export). Cannot be sliced or imported without a Photoshop pass; the author's own description calls the art "a little creepy". |
| Star Ships (canisferus) | https://opengameart.org/content/star-ships | CC0, but the pack is two large 3D-rendered images (8 MB and 7 MB, with baked backgrounds), not sprites. Unusable as gameplay art. |
| itch.io space/ship asset listings | https://itch.io/game-assets/free?q=spaceship | Search returned author profile pages with **no licence field**. Licences vary per page and several popular packs are CC-BY. Nothing individually verified, so nothing recommended — revisit only for a specific page that states CC0 in writing. |
| Openverse image search (space/ship queries) | https://openverse.org/search/image?q=spaceship | Returns photographs and illustrations, not game sprite packs; licence metadata is per-item and frequently CC-BY/CC-BY-SA. No usable candidate, and the `environment.md` pass already flagged the CC-BY-SA contamination risk there. |
| Kenney catalogue search for "space" via MCP | (assetmcp `search_kenney_assets`) | Not a licence rejection — the MCP crawler returns fuzzy matches from the first catalogue pages only (`Modular Space Kit`, `Space Station Kit`, both 3D), missing the 2D space packs entirely. Kenney pages were therefore fetched and read directly instead. |

Notes on candidates seen but **not evaluated** (out of scope for this pass, licences unread):
`/content/glitch-furniture-spaceship`, `/content/colorized-boss-sprites`, `/content/colorize-enemies`,
`/content/commander-sheet-93`, `/content/slime-monster-ship`, `/content/shmup-mockup`,
`/content/fish-spacehip-game-character`, `/content/graphical-factory-spaceship-humans`,
`/content/spacewreck`, `/content/lazer-zero`, `/content/2d-spaceship-11`, `/content/2d-spaceship-10`,
`/content/spaceship-spiked-fighter`, `/content/spaceship-medium-size`, `/content/purple-space-ship`,
`/content/space-ship-shooter-pixel-art-assets`, `/content/16-16-ship-collection`,
`/content/space-scifi-rpg-tiles-48x48`, `/content/32x32-maze-spritesheet`,
`/content/tower-defence-basic-towers`, `/content/turret-gun-bogie-rail`, `/content/cannon-tower`,
`/content/freeart-topdown-extras-tank`, `/content/some-8-bit-vertical-shooter-tiles-r2`.
All surfaced inside CC0-faceted searches so they are plausible, but the strict rule here is "open the
page and read the badge", which was not done for them. The candidates above already cover ships, tiers,
factions, turrets and weapons, so these are only worth a look if a specific silhouette is still missing.
