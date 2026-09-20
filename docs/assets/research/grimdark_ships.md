# Vajb Orbit — Grimdark Ships, Wrecks, Heavy Weapons & Grime Textures (CC0 Scout)

Date: 2026-09-16 · Scope: free **CC0**-only art for a possible grimdark turn of the 2D top-down Dark Orbit
clone (Godot 4.7.2, Forward+). Subjects hunted: weathered/damaged ship hulls, rust and battle-damage
textures, dark gothic ships, wrecked hulks, debris fields, heavy brutal weapons.

Style baseline: Kenney flat vector, already owned at `asset-library/raw/sprites/space_shooter_redux/`
(5 player ships ×4 colours + damage states, 4 enemy families, 3 laser colours ×16 variants, meteors,
engine/fire/star FX — see `docs/ASSETS.md`).

**Every candidate page was opened and its licence badge read directly; search metadata was never trusted.
Nothing was downloaded.** Pages read 2026-09-16.

## Summary

- **A full grimdark reskin is buildable in CC0, but not from one pack.** No single CC0 pack ships a
  coherent "dark gothic space fleet". The workable recipe is three layers: (1) keep Kenney hulls and
  *darken + desaturate + re-tint* them, (2) bolt on CC0 grime (rust panels, decals, splats, scans) as
  overlays, (3) buy dread with dedicated **wreck and debris sprites** (Spacewreck, Lite spaceship pack,
  Raider debris, Kenney meteors) plus **large capital/gun silhouettes** (Space Defense Cannon, Ragnar
  Incident, Eeun's Shipyard).
- **Best single find for the grimdark axis: *Animated CC0 Ships v2.0* (ZaninDevelopers).** It is the only
  pack found that ships an **animated damaged/dystopian ship** alongside its intact version, plus a
  military fighter, explicitly tagged `damaged` / `apocalypse` / `retro`. 2026 release, CC0 badge, no
  attribution required.
- **Best hulk: *Spacewreck* (CityBuildingGameArt).** A 2048×2110 "mangled and completely destroyed space
  structure with spinning boulders", PNG + Blender source + boulder sprite frames. It is a rendered 3D
  asset, not flat vector, so it reads as set dressing rather than a fleet member, but it is the strongest
  wreck hero image found in CC0.
- **Debris fields are a solved problem.** *Lite spaceship pack* alone contains **28 debris sprites** plus
  gaps-free coverage of capitals, cruisers, fighters, three turret tiers, projectiles, shields and effects
  in a single 12.8 KB PNG; *Asteroids/Debris Set* adds 9 asteroids + 9 junk sprites; Raider's 2D set adds
  more debris and torpedoes.
- **Heavy brutal weapons: covered twice over.** *Gun Construction Kit* (SVG, ~120 parts incl. grenade and
  rocket launchers) and *2D Guns* (PNG + spritesheet + **SVG source**) are both flat-vector and can be
  redrawn as ship-mounted ordnance at any scale; *Eradication Wars Weapon Sprite Pack* and *Futuristic
  Guns, Weapons and Items* supply ~50 pixel-art guns each with muzzle flashes and projectiles.
- **Rust and battle-damage textures are abundant and genuinely good**, and this is where CC0 is strongest:
  *Gritty Lowres Scifi Wall and Floor Textures* (64×64 hand-drawn/photobashed **ship walls**, 23 KB),
  *scrached and rusted metal panel* (corrugated panel, diffuse ×6 + bump/normal/spec), *Hull Plating Normal
  Maps* (bolt-plate normal maps + diffuse + window), *Free Decals 02: Sci-Fi* (painted panel decals),
  *Yughues Free PBR Metal Plates* (36 plates + normal maps), *Metal rust pattern*, *Metal rust crate*,
  *4096 Scifi Hex Tiles PBR*, plus Kenney's *Pattern Pack Extra* (80 seamless 256×256 patterns) for
  procedural greeble.
- **"Dark gothic ship" specifically does not exist in CC0.** Searches on `gothic`, `dark`, `dreadnought`,
  `hulk` returned fantasy platformer art (GothicVania), ground vehicles and one `Mech`. Gothic space
  architecture has to be synthesised: Kenney hull + gothic-influenced silhouette edits + dark plating
  texture. This is a real, documented gap, not a search failure.
- **Two content traps found.** (a) AI-assisted uploads: *12 Pixel asteroids and space junks* and its
  siblings are **download-disabled** with the note "File(s) currently unavailable due to potential
  licensing issues" — unusable and rejected. (b) **Dual-licence pages**: Space Debris, Rust (semi
  seamless), Crates of the Future and Top-Down Spaceships Detailed each carry CC0 *plus* CC-BY / GPL /
  CC-BY-SA / OGA-BY badges. Under this task's strict rule (reject CC-BY, CC-BY-SA, OGA-BY, GPL, anything
  unclear) they are rejected, even though CC0 is technically selectable.
- **itch.io yielded nothing usable and Openverse yielded nothing at all.** itch.io search results are
  author profile pages with no licence field (`"license": "See asset page"`); Openverse returned
  `{"result_count":0}` for CC0-filtered spaceship/rust queries. Both are documented in the rejects.

### Method (repeatable)

```
# OpenGameArt, CC0 facet (4 = CC0 licence, 9 = 2D Art, 14 = Textures)
https://opengameart.org/art-search-advanced?keys=<term>&field_art_type_tid%5B%5D=9&field_art_licenses_tid%5B%5D=4&sort_by=count&sort_order=DESC&items_per_page=72
# Terms run: spaceship, damaged, wreck, debris, battleship, hulk, dreadnought, turret, cannon, gun,
#            warship, hull, metal plate, space station, gothic, dark, rust, sci-fi, battle damage
```

Kenney pages were opened directly (the MCP crawler only sees page 1 of the catalogue and misses the 2D
space packs). Licence for each row below was confirmed by reading the page's `License(s):` badge
(`.../license_images/cc0.png` → `creativecommons.org/publicdomain/zero/1.0/`) or, for Kenney, the page
header line `Files <n>× License Creative Commons CC0`. A page that carries a non-CC0 badge *in addition to*
CC0 is rejected, not scored.

**Scoring (scoped to this report; not comparable across reports).**
- **Flat fit (1-5):** how well the asset survives being darkened into the existing Kenney flat-vector
  baseline. 5 = drop-in after a palette pass · 3 = usable after recolour/outline work · 1 = wrong medium
  (photo/3D render/pixel), cannot blend.
- **Grim (1-5):** standalone grimdark quality, judged from the page's own description, tags and preview
  framing (no downloads were taken to inspect pixels). 5 = already reads as grimdark · 1 = cheerful.

## Candidate table

| Name | Source URL | License + evidence (verbatim) | Contents | Formats | Flat | Grim | Direct download URL | Notes |
|---|---|---|---|---|---|---|---|---|
| Animated CC0 Ships v2.0 (ZaninDevelopers) | https://opengameart.org/content/animated-cc0-ships-v20 | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/; notice: "Credit is not necessary. All I ask of you is to provide a link to your project in the comments if you use this in your game. But again, not necessary." | 3 animated ships as spritesheets: "an animated damaged dystopian ship, an animated dystopian ship in good condition, and finally the new asset: an animated futuristic military fighter jet"; tags include `damaged`, `apocalypse`, `military`, `retro` | PNG spritesheets (individual files + zip) | 2 | 5 | https://opengameart.org/sites/default/files/zanindevs_v.2ships.zip · https://opengameart.org/sites/default/files/damageddystopianship.png | **Top pick for grimdark.** The damaged↔intact pair is exactly the damage-state convention a Dark Orbit clone needs, and it is animated. Pixel art, so it needs a deliberate pixel faction or a redraw to sit with Kenney — do not mix on the same ship tier as Redux hulls. |
| Spacewreck (City Building Game Art) | https://opengameart.org/content/spacewreck | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/; notice: "Credit "CityBuildingKit.com" or "www.CityBuildingKit.com", this is not mandatory." | "Mangled and completely destroyed space structure with spinning boulders"; "Large 2048x2110 PNG image", "**.Blend** Blender 3D source included", "Spinning boulders sprite images" | PNG (2048×2110) + sprite frames + .blend, in zip | 2 | 5 | https://opengameart.org/sites/default/files/Space_DestroyedStructure_sprites%20and%20source.zip | **Best hulk/wreck hero asset.** Huge, already destroyed, and the boulder frames animate into a debris field. Rendered look with baked lighting, so tint it toward the palette rather than expecting a flat match. **Duplicate asset:** the same page is `grimdark_environment.md:39` (rec 3 there) — shared deliberately, this report owns the wreck-hero/fleet use, that report the backdrop far-layer use. |
| Lite spaceship pack (Jarusca) | https://opengameart.org/content/lite-spaceship-pack | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | "x2 races, x2 capitals, x4 cruisers, x4 fighters, x3 big turrets, x3 medium turrets, x3 small turrets, x12 projectiles, x4 shields, **28x debris**, x3 effects" | PNG (single sheet `lite_spaceship_pack.png`, 12.8 KB) | 3 | 5 | https://opengameart.org/sites/default/files/lite_spaceship_pack.png | **Highest value-per-byte in the report.** 28 debris sprites plus a complete faction/turret/projectile set from one tiny sheet. Small file size implies small sprites — check dimensions on a contact sheet before committing to a zoomed camera. |
| SpaceShips Sprites — Ragnar Incident (Commander / Bazlik) | https://opengameart.org/content/spaceships-sprites-ragnar-incident | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/; notice: "free by Bazlik_Commander" | Spaceship sprite set incl. animated fleet previews (GIF previews `evacfleet_2.gif`, `evacfleet_3.gif`), asymmetric dark hulls, background-capable images | PNG + GIF in zip | 3 | 4 | https://opengameart.org/sites/default/files/ragnar_pack_by_bazlik.zip | Asymmetric, heavy-looking hulls; a commenter notes some images "can be used for background" (good for a burnt-out sector backdrop). Page warns "Alpha is black, so use proper editor" — import with alpha handling in mind. |
| Free Decals 02: Sci-Fi (Yughues) | https://opengameart.org/content/free-decals-02-sci-fi | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | Painted sci-fi metal panel decals; tags `decal`, `Sci-Fi`, `metal`, `raw`, `painted`, `brushed`, `panel`, `grid`, colours blue/green/yellow/red/gold/black | 7z archive | 1 | 4 | https://opengameart.org/sites/default/files/Sci-Fi%20decals%2002.7z | The cheapest route to "this hull has been in service for 40 years": multiply these panel/grime decals over flat Kenney hulls. Large archive (36.8 MB); needs a 7z extractor (`assetmcp` handles `.7z`). |
| Gritty Lowres Scifi Wall and Floor Textures (CptDrunkBear) | https://opengameart.org/content/gritty-lowres-scifi-wall-and-floor-textures | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | "all textures are 64x64, either hand-drawn or photobashed from cc0 textures … Most of them are spaceship walls, but there is also a floor and ceiling texture": `wall_ship_0..7`, `wall_desert_0..2`, `floor_ship`, `floor_desert`, `ceiling` | PNG, zip (23.3 KB) | 3 | 5 | https://opengameart.org/sites/default/files/scifitextures.zip | **Best small-scale hull plating source**: 64×64, explicitly authored as *spaceship* walls, already beaten up. Tile it under flat hulls as a texture pass, or use directly for station interiors. |
| scrached and rusted metal panel (Luke.RUSTLTD) | https://opengameart.org/content/scrached-and-rusted-metal-panel | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | "A corrugated metal panel with rust and scratches. Included: bump, normal, specular, and 6 diffuse textures each a different color. orange, blue, green, red, white, and tan." | PNG maps in zip (9.5 MB) | 1 | 5 | https://opengameart.org/sites/default/files/metal_panel.zip | Six colourways of the same weathered panel means per-faction plating from one purchase. Filter-Forge generated, photoreal, so use as overlay/backdrop, not as sprite art. |
| Hull Plating Normal Maps (hansonry) | https://opengameart.org/content/hull-plating-normal-maps | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | "I created a 6 Bolt and 4 Bolt varients of Hull Plating for a space ship or water ship. The normal maps are tileable." Files: `platingnormal2/3.png`, `randomplatingdiffuse/normal.png`, `windowdiffuse/normal.png`, `hullplating.blend` | PNG (individual) + .blend | 1 | 4 | https://opengameart.org/sites/default/files/platingnormal2.png · https://opengameart.org/sites/default/files/platingnormal3.png · https://opengameart.org/sites/default/files/randomplatingdiffuse.png | Tileable bolt-plate normal maps plus a matching window set: the fastest way to make flat hulls read as riveted armour, and there is a diffuse to colour-sample from. |
| Scratched Metal Crate (Luke.RUSTLTD) | https://opengameart.org/content/scratched-metal-crate | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | "A scratched and rusted metal crate/box" at "512x512 textures": Diffuse, Bump, Normal, AO, plus "a rendered out version for anyone who wants to use it as a 2D asset" | PNG maps in zip (5.2 MB) | 1 | 4 | https://opengameart.org/sites/default/files/metalbox.zip | Cargo/loot crate art plus a ready-rendered 2D version for pickups and station clutter. Pair with the panel above for one grime family. |
| Yughues Free PBR Metal Plates (Yughues) | https://opengameart.org/content/yughues-free-pbr-metal-plates | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | "**36 Metal plates**(1 diffuse+metalness for 36 normal maps) for free… It goes from basic shape plates, to slightly sci-fi, to victorian style." | 7z archive (13.4 MB) | 1 | 4 | https://opengameart.org/sites/default/files/Yughues%20Free%20Metal%20Plates.7z | The "victorian" end of the pack is the closest thing CC0 has to a **gothic** plating motif — useful for a cathedral-hull faction. Diffuse is neutral so metal colour is chosen in-engine. |
| Metal rust pattern (OwlishMedia) | https://opengameart.org/content/metal-rust-pattern | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | "Includes 4k textures and a SBSAR Substance file which can be used in Substance Painter, Unreal Engine and Unity. It has sliders for rust." Maps: basecolor, normal, roughness, metallic, height, AO | PNG (4K) + `.sbsar`, two zips | 1 | 4 | https://opengameart.org/sites/default/files/RustyMetalPattern.zip · https://opengameart.org/sites/default/files/RustyMetalSBSAR.zip | Full PBR rust set for free. Caveats straight from the page: a commenter reports "The texture tiles horribly because of the dirt which gives an obviously visible pattern", author replies the seed can be changed in the SBSAR. 120 MB; prefer the SBSAR zip if Substance is available. |
| 4096 Scifi Hex Tiles PBR Texture (txturs) | https://opengameart.org/content/4096-scifi-hex-tiles-pbr-texture | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | "High resolution 4096 x 4096 ready-to-use PBR texture. Contains the following maps: Albedo, Displacement, Glossiness, Normal, Specular" | JPG maps (individual downloads) | 1 | 4 | https://opengameart.org/sites/default/files/Scifi_Hex_Wall_Albedo.jpg | Hex-panel hull texture at 4K; the individual-file download style means 6 separate fetches. Good for a "hex-armoured dreadnought" plating motif. |
| Steel Plate Tiles (rfc1394) | https://opengameart.org/content/steel-plate-tiles | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | "A set of two types of rectangular steel plate, one has 4 rivets, the other is rivetless." | **SVG** (94.6 KB) | 5 | 3 | https://opengameart.org/sites/default/files/steeltile.svg | Vector riveted plate: recolour to gunmetal, tile, and it matches the flat-vector baseline exactly. Cheapest way to give Redux hulls an armoured skirt. |
| Kenney Pattern Pack Extra | https://kenney.nl/assets/pattern-pack-extra | Page header: "Tile size 256 × 256 Files 80× License Creative Commons CC0" | 80 seamless patterns/textures at 256×256, tagged `pattern`, `texture`, `seamless`, `vfx` | PNG | 5 | 3 | https://kenney.nl/media/pages/assets/pattern-pack-extra/270736c7fd-1786626805/kenney_pattern-pack-extra.zip | Same vendor as the baseline, so pattern weight matches by construction. Use as multiply-overlay greeble so flat hulls do not read as empty. Kenney zip links are release-hashed; archive the zip. |
| Kenney Splat Pack | https://kenney.nl/assets/splat-pack | Page header: "Files 30× License Creative Commons CC0" | 30 splat textures (2D VFX) | PNG | 5 | 4 | https://kenney.nl/media/pages/assets/splat-pack/1070534984-1677495350/kenney_splat-pack.zip | Scorch/grime/impact decals in the baseline's own visual language: the single most on-style way to make a Kenney hull look damaged. |
| Kenney Light Masks | https://kenney.nl/assets/light-masks | Page header: "Files 150× License Creative Commons CC0" | 150 light cookie/shader masks, tagged `light`, `shader`, `vfx`, `cookie` | PNG | 5 | 4 | https://kenney.nl/media/pages/assets/light-masks/6530e254f9-1775631687/kenney_light-masks-1.0.zip | Grimdark is mostly lighting: these masks let a dark scene be lit by slivers, strips and hazard lamps without new art. Released 2026. |
| Space Defense Cannon (City Building Game Art) | https://opengameart.org/content/space-defense-cannon | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/; notice: "Credit "CityBuildingKit.com" or "www.CityBuildingKit.com", this is not mandatory." | "Blow stuff up with this huge cannon. And by huge, we mean huuuuuge." Bigger than 1706×1757 px; ".Blend Blender 3D source included"; "Separated cannon gun sprite images"; "Multiple angles for 360 rotation"; "Spinning rocket animation sprite images" | PNG sprite sets + .blend, in zip (56.9 MB) | 2 | 5 | https://opengameart.org/sites/default/files/Space_DefenseCannon_spites%20and%20source.zip | **The "heavy brutal weapon" of the report**: a 360°-rotation turret with muzzle and spinning-rocket frames, i.e. a full station defence weapon, not an icon. Large download; scale down on import. |
| Gun Construction Kit (SpriteAttack) | https://opengameart.org/content/gun-construction-kit | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | "a set of simplified guns rifles … in a combined and exploded version… The explosion splits the guns and rifles into their parts to allow you to assemble your own… There are some **120 bits and piece to combine**"; update added "3 grenade launchers and 2 rocket launchers with their respective parts" | **SVG** (show + explode) + zip | 5 | 3 | https://opengameart.org/sites/default/files/gunsconstructionkit.zip · https://opengameart.org/sites/default/files/FreeArt_GunConstructionKit_v03_explode.svg | Modular vector ordnance: build turret barrels, missile racks and HUD weapon icons at any resolution in the flat-vector look. Silhouettes are small-arms-derived, so heavy ship guns need re-proportioning. |
| 2D Guns (Kay Lousberg) | https://opengameart.org/content/2d-guns | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/; notice: "Free for personal and commercial use, no attribution required." | "6 Weapontypes: Pistol, Revolver, Shotgun, Sniper, SMG, Assault Rifle + accessories like bullets, magazines, grenades and an ammo box"; exported as separate PNGs, a spritesheet **and** "vector source file (.svg)" | PNG + spritesheet + **SVG** | 5 | 3 | https://opengameart.org/sites/default/files/guns_gameassets.zip | Vector source makes this the cheapest way to author a consistent weapon-icon family for HUD/equipment screens; bullets/magazines double as projectile and pickup art. |
| Eradication Wars Weapon Sprite Pack (Reactorcore) | https://opengameart.org/content/eradication-wars-weapon-sprite-pack | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | "over 50 handmade pixel art sprites of various cool futuristic weapons… Includes: big versions of guns, tiny versions of guns, tiny muzzle flashes, tiny projectiles"; tags `energy`, `Ballistic`, `blaster`, `armory`, `war` | PNG (transparent) in zip | 2 | 4 | https://opengameart.org/sites/default/files/eradication_wars_weapon_sprite_pack_v1.1.zip | Handmade pixel arsenal with matching muzzle flashes and projectiles: a ready-made weapon tier ladder for a grimdark faction. "Opaque pixel art PNG with transparent background" per page. |
| Futuristic Guns, Weapons and Items (knekko) | https://opengameart.org/content/futuristic-guns-weapons-and-items | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/; notice: "Released into public domain. Attribution not required, but appreciated." | Pixel pistols, shotguns, machine guns, "funky futuristic guns", melee, armour; sized to a 32×32 grid; 9 sheets (`pistols.png`, `shotguns.png`, `machine_guns.png`, `military.png`, `sniper.png`, `neonpunk.png`, `armor.png`, `melee.png`, `misc.png`); page lists the CC0 sources it remixes | PNG sheets (individual files) | 2 | 3 | https://opengameart.org/sites/default/files/neonpunk.png · https://opengameart.org/sites/default/files/military.png | Cyberpunk-leaning; the `neonpunk` and `military` sheets are the grimdark-relevant ones. 32×32 grid is small for a Dark Orbit playfield, so treat as icon/enemy-weapon tier. |
| Assets Free Laser Bullets Pack 2020 (Wenrexa) | https://opengameart.org/content/assets-free-laser-bullets-pack-2020 | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/; page text: "[You can use all assets for your projects on a **free** and **commercial** basis.]" | "Count: 66 files", 32-bit PNG with transparency, laser bolts/beams in many colours; page recommends FX overlay modes (Color dodge, Lighten, Vivid Light) | PNG in zip | 4 | 3 | https://opengameart.org/sites/default/files/sprites_-_lasers_bullets_1_66v2.5.zip | Glow-based projectiles read as "light" and survive a dark palette; the additive-overlay advice is directly usable with Godot canvas blend modes. |
| Free Metal-Texture-Creation-Set 01 (rubberduck) | https://opengameart.org/content/free-metal-texture-creation-set-01 | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | "This is the first metal texture creation set it has some examples"; tags `metal`, `Sci-Fi`, `spaceship`, `futuristic`, `gimp`; 4 example renders included | Texture set + examples in zip (16.2 MB) | 1 | 3 | https://opengameart.org/sites/default/files/set1.zip | A build kit rather than finished art (sets 01-10 exist). Use if a hull needs a specific wear pattern that the panel/crate packs do not provide. |
| Urban Decay Textures 3 (bart) | https://opengameart.org/content/urban-decay-textures-3 | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/; page: "Shot these myself. High-res JPGs. RAW images available by request" | 15 high-res photographic decay textures (tags `rust`, `Post-Apocalyptic`, `decay`, `cracks`) | JPG in zip (28.2 MB) | 1 | 3 | https://opengameart.org/sites/default/files/decay3.zip | Photographic grunge for overlays and menu/backdrop treatment. Surface-subject (urban stone/brick) rather than metal, so most useful desaturated at low opacity. Sets 1 and 2 are sibling packs (not individually verified here). |
| Space-themed sprites (Vidmaster, from *Raider*) | https://opengameart.org/content/space-themed-sprites | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/; "We, the Raider development team, do hereby release these sprites under public domain but it would still be nice if you would drop a PM here on OGA" | "various space ships, turrets and other space-game themed sprites such as energy torpedos or debris" | PNG in `.7z` (1.3 MB) | 3 | 4 | https://opengameart.org/sites/default/files/Raider%202D%20assets.7z | Dark arcade space art with **debris, turrets and torpedoes** in one archive. Already recorded in `ships_weapons.md:81`; flagged again here for the wreckage/debris angle. `.7z` needs the right extractor. |
| Ship / Destroyed Ship (Kutejnikov) | https://opengameart.org/content/ship-destroyed-ship | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | "Very simplified pixel ship" drawn as a ship **and its destroyed version**; tags `destroyed`, `Wreckage`, `wreck`, `spritesheet` | PNG (26.7 KB) | 2 | 3 | https://opengameart.org/sites/default/files/ship_11.png | Tiny (one artist, one hull) but it is a purpose-built intact/destroyed pair; the cheapest possible proof of the damage-state pipeline before investing in a full faction. |
| Asteroids/Debris Set (The_Scientist___) | https://opengameart.org/content/asteroidsdebris-set | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/; "I don't have any copyright restrictions on this stuff, so feel free to use them however you wish. Credit is appreciated but not necessary." | "9 Asteroid Sprites (3 large, 3 medium, and 3 small)" and "9 Debris Sprites (3 large, 3 medium, and 3 small)" | PNG in zip (12.9 KB) | 3 | 4 | https://opengameart.org/sites/default/files/Objects.zip | Tidy three-tier debris field kit from a shmup called *Ten Lightyears*; the size tiers map directly onto a mineable-junk + collision-damage system. Pixel art (Piskel). |
| Space ship with turrets (gfx0) | https://opengameart.org/content/space-ship-with-turrets | `License(s): CC0` badge; page: "CC0 public domain, use as you please :)"; "…it is included with layers in the zip file" | One painted spaceship with turrets, Krita file with layers for editing; author notes "the art work is crappy" | PNG + `.kra` in zip (4.6 MB) | 2 | 4 | https://opengameart.org/sites/default/files/spaceship_final.zip | Layered source means it can be re-skinned to the grimdark palette rather than merely recoloured. Single ship, so value is the layered-source workflow, not the fleet. |
| SpaceShip Sprites — Eeun's Shipyard (Eeun, submitted by EMR) | https://opengameart.org/content/eeuns-shipyard-spaceship-graphics | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | "it contains 28 ships, each rendered at at a bird's eye almost-top-down angle"; each ship also has "a larger (usually 100x100) render, a side-render, and a head-on render" named icon/scan/head; separate mask image for alpha | PNG in zip (1.1 MB) | 2 | 4 | https://opengameart.org/sites/default/files/EEUN.zip | 28 battered late-90s rendered hulls "from intimidating to wimsical" with consistent icons for UI — good bulk for enemy fleets. Page warns the render angle is not fully consistent between ships, and that the artist's separate Dalek is "potentially copyright infringing" (that file is **not** in this archive; do not pursue it). |
| Black Spaceship (matepore) | https://opengameart.org/content/black-spaceship | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/; notice: "No need to give me credit, but it is appreciated" | "Just a random spaceship I made"; tags `black`, `topdown` | PNG in zip (10.5 KB) | 3 | 3 | https://opengameart.org/sites/default/files/spaceship_1.zip | Single black top-down hull: a free palette/contrast reference for how a darkened Redux ship reads against a starfield. Low volume, near-zero cost. |
| Gunship (Tim_Supermonkey) | https://opengameart.org/content/gunship | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/; "Attribution Instructions: Attribute Tim_Supermonkey at OpenGameArt.org." | One gunship/gunner sprite, tagged `gunship`, `gunner`, `spaceship` | PNG (179.8 KB) | 3 | 4 | https://opengameart.org/sites/default/files/gunner.png | Single heavy-looking hull. **Note the friction:** the badge is CC0 while the attribution line reads mandatory; CC0 governs (no attribution required), but if you use it, credit the author anyway to remove the argument. |
| Flat Spaceship with parts (zisongbr / FFMStudios) | https://opengameart.org/content/flat-spaceship-with-parts | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/; notice: "FFMStudios, Fernando Ferreira" | "Flat design Spaceship with separate Parts and .AI file :)"; also single-part and exploded PNGs | PNG + **Illustrator (.ai)** in zip (874.7 KB) | 5 | 2 | https://opengameart.org/sites/default/files/Spaceship_flat.zip · https://opengameart.org/sites/default/files/Spaceship_all.png | Cheerful flat vector, therefore **the cleanest test case for the "darken the baseline" hypothesis**: open the .AI, swap fills for gunmetal/blood palette, and see whether the flat-vector direction can carry grimdark at all. If it cannot, the whole "base = Kenney, recoloured" plan is weak. |
| space shooter collection (donnie9171) | https://opengameart.org/content/space-shooter-collection | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | 15 small PNGs: cannon, cannon icon, machine, machine icon, space ship, asteroids 1-6, background, icons 1-3 | PNG (individual files, 137 B - 875 B) | 3 | 2 | https://opengameart.org/sites/default/files/cannon_3.png · https://opengameart.org/sites/default/files/space%20ship_0.png | Very small sprites and files; included for completeness and for the cannon/asteroid silhouettes only. Not a style or quality play. |
| Sci FI Top Down Shipyard Space Station (ChaosShark) | https://opengameart.org/content/sci-fi-top-down-shipyard-space-station | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/ | "Space Station for a top down space game" from the abandoned project Aether Core | PNG (19.8 KB) | 2 | 4 | https://opengameart.org/sites/default/files/Shipyard%20Exterior.png | Industrial shipyard exterior for a dark station hub: exactly the "grubby space dock" a grimdark sector needs. A sibling top-down centrifuge station exists (not read here) if more station mass is wanted. **Cross-reference:** the same shipyard URL is `environment.md:34`, which rates it a style failure ("pixel art with hard shadows vs. Kenney flat vector") and holds it as a placeholder only — it is not rejected there, so this row's recommendation stands on the top-down silhouette, but expect a recolour pass. |
| Sci-fi RTS (Kenney) | https://opengameart.org/content/sci-fi-rts-120-sprites | `License(s): CC0` badge → creativecommons.org/publicdomain/zero/1.0/; notice: "Credit "Kenney.nl" or "www.kenney.nl", this is not mandatory." | "structures, vehicles, environmental objects, units and tiles"; "Separate PNG files (127x)", "Spritesheet(s) / Tilesheet(s)", "Vector file(s)", "Additional retina sizes" | PNG + spritesheets + **vector** + retina | 5 | 2 | https://opengameart.org/sites/default/files/kenney_rtssci-fi.zip | Same vendor and outline weight as the owned baseline, with vector source for clean recolours. Commenters note units are static and naming is opaque (`scifiUnit_37`), and it is land RTS art, so value is structural (tanks, walls, silos) rather than fleet. |
| Space Shooter Extension (Kenney) | https://kenney.nl/assets/space-shooter-extension | Page header: "Files 270× License Creative Commons CC0" | 270 files: missiles, rockets, new ship parts, satellites, meteors for the Space Shooter family | PNG (+ retina, vector per OGA mirror) | 5 | 3 | https://kenney.nl/media/pages/assets/space-shooter-extension/d0bd70032c-1677693518/kenney_space-shooter-extension.zip | The ordnance layer of the baseline: new missiles and hull parts are the raw material for "brutal weapon" upgrades without leaving the style. Already recommended in `ships_weapons.md:61`; this licence line was re-read on the Kenney page for this report. Hash-based link changes per release. |
| Space Shooter Remastered (Kenney) | https://kenney.nl/assets/space-shooter-remastered | Page header: "Files 295× License Creative Commons CC0" | 295 files, the owned baseline (ships ×4 colours with damage states, 4 enemy families, lasers, meteors, backgrounds, TTF fonts, SFX) | PNG + vector + TTF | 5 | 2 | https://kenney.nl/media/pages/assets/space-shooter-remastered/2cbf3c45c8-1774771931/kenney_space-shooter-remastered.zip | Listed as the reference target: the grimdark test is whether these hulls survive a darkened palette. Note the slug is now `space-shooter-remastered` (`space-shooter-redux` 404s). |
| Simple Space (Kenney) | https://kenney.nl/assets/simple-space | Page header: "Files 48× License Creative Commons CC0" | 48 files of simple 2D space art (map/space iconography) | PNG | 5 | 2 | https://kenney.nl/media/pages/assets/simple-space/b9b0968a6b-1677578143/kenney_simple-space.zip | Flat space iconography for sector maps and nav UI, which a grimdark HUD needs as much as ships do. Released 2021. **Duplicate asset:** already carried as `environment.md:23` ("best sector-map bet") — listed here only because the grimdark sector map needs the same icon set. |
| Planets (Kenney) | https://kenney.nl/assets/planets | Page header: "Files 50× License Creative Commons CC0" | 50 planet/space-body sprites | PNG | 5 | 2 | https://kenney.nl/media/pages/assets/planets/512b578338-1677495391/kenney_planets.zip | Backdrop material; a dark sector map needs dead worlds. Low priority for the grimdark axis specifically. **Duplicate asset:** already carried as `environment.md:22`, where it is the recommended **Primary planet source** — cross-reference that row rather than treating this as a second find. |

## Recommendations

Priority order for the next (download) batch. All CC0, no attribution owed.

1. **Animated CC0 Ships v2.0 (ZaninDevelopers)** —
   https://opengameart.org/sites/default/files/zanindevs_v.2ships.zip.
   The only intact/damaged animated pair found. Take it before anything else and decide the artistic
   question it forces: does the project accept a pixel-art presence, or is this a reference for the damage
   convention only?
2. **Lite spaceship pack (Jarusca)** — https://opengameart.org/sites/default/files/lite_spaceship_pack.png.
   28 debris sprites, three turret tiers, projectiles, shields and effects in 12.8 KB: the single most
   efficient way to populate a debris field and arm a faction. Slice it and inspect real sizes first.
3. **Spacewreck (CityBuildingGameArt)** —
   https://opengameart.org/sites/default/files/Space_DestroyedStructure_sprites%20and%20source.zip.
   The hulk hero asset, with animated boulders for a live debris field.
4. **Grime layer (four small downloads, all overlay-ready):**
   *Gritty Lowres Scifi Wall and Floor Textures* (https://opengameart.org/sites/default/files/scifitextures.zip),
   *Free Decals 02: Sci-Fi* (https://opengameart.org/sites/default/files/Sci-Fi%20decals%2002.7z),
   *scrached and rusted metal panel* (https://opengameart.org/sites/default/files/metal_panel.zip),
   *Scratched Metal Crate* (https://opengameart.org/sites/default/files/metalbox.zip).
   Together these cover hull plating, panel decals and cargo wear at every scale.
5. **Kenney Splat Pack + Light Masks + Pattern Pack Extra** — same vendor as the baseline, therefore the
   on-style way to add damage, darkness and greeble. These three are what make a "darkened Kenney" build
   look deliberate rather than merely dim.
6. **Steel Plate Tiles (SVG) + Hull Plating Normal Maps** — vector riveted plate and tileable bolt-plate
   normals; the armoured-hull pass that stops flat hulls reading as paper.
7. **Heavy weapons:** *Space Defense Cannon* (full 360° turret with spin animation,
   https://opengameart.org/sites/default/files/Space_DefenseCannon_spites%20and%20source.zip) first, then
   the two vector kits — *Gun Construction Kit*
   (https://opengameart.org/sites/default/files/gunsconstructionkit.zip) and *2D Guns*
   (https://opengameart.org/sites/default/files/guns_gameassets.zip) — and only then the pixel arsenals
   (*Eradication Wars*, *Futuristic Guns*) if a pixel faction is accepted.
8. **Wreck and debris depth:** *Asteroids/Debris Set* (https://opengameart.org/sites/default/files/Objects.zip),
   *Space-themed sprites* / Raider (https://opengameart.org/sites/default/files/Raider%202D%20assets.7z),
   *Ship / Destroyed Ship* (https://opengameart.org/sites/default/files/ship_11.png),
   *Shipyard Space Station* (https://opengameart.org/sites/default/files/Shipyard%20Exterior.png).
9. **Do this before spending anything else: a darkening test.** Take one owned Redux hull, apply Kenney
   Splat Pack damage, a Gritty Lowres plating pass and a gunmetal palette, and put it beside the flat-vector
   *Flat Spaceship with parts* hull (https://opengameart.org/sites/default/files/Spaceship_flat.zip, with
   `.ai` source). Only if that test convinces should the darker direction be specified, because everything
   else in this report assumes it.

Practical notes for that batch:

- Download into `asset-library/raw/sprites/<pack_name>/`, then move files by hand — `assetmcp` flattens the
  `subfolder` argument into a single sanitised folder at the library root (see `docs/ASSETS.md`).
- Keep the naming conventions: `ship_`, `enemy_`, `proj_`, `fx_`, `bg_`, `ui_`; sliced frames as
  `<name>_f00.png`.
- Three archives need non-standard handling: *Free Decals 02*, *Raider 2D assets* and *Yughues Free PBR
  Metal Plates* are `.7z`; *Metal rust pattern* has a 120 MB variant and a 16.8 KB SBSAR-only variant.
- Two packs ship vector/layered source (*Steel Plate Tiles*, *2D Guns*, *Gun Construction Kit*,
  *Flat Spaceship with parts*) — prefer editing the vector and exporting fresh PNGs over recolouring
  rasters, since the flat-vector baseline is vector-authored.
- Photoreal PBR sets (*metal panel*, *metal plates*, *hex tiles*, *rust pattern*) are for overlays and
  station/backdrop use only; they will not blend as sprite art at the playfield scale.
- Rebuild `ASSET_MANIFEST.json` and `CREDITS.md` after import (`create_asset_manifest`,
  `generate_credits`) even though CC0 requires no attribution, then `audit_project_assets`.
- Nothing here was downloaded for this report. No preview images were saved; style scores were judged from
  the pages' own text, tags and preview framing.

## Rejected candidates

Verified and rejected.

| Asset | URL | Reason |
|---|---|---|
| Meowx Shipyard: large number of spaceship sprites (Meowx, submitted by EMR) | https://opengameart.org/content/meowx-shipyard-large-number-of-spaceship-sprites | **CC-BY-SA 3.0** badge only ("Include a link back to the author's website"). ~74 dark rendered ships that would have suited the brief, but share-alike contaminates the project. |
| Space Debris (takeshi) | https://opengameart.org/content/space-debris | Carries **CC-BY 4.0 *and* CC0** badges side by side. CC0 is technically selectable, but the strict rule for this pass is "no non-CC0 badge on the page", so rejected. (Content was also weak: jam-era household/robot props, not ships.) |
| Rust (semi seamless) (pyranostudios) | https://opengameart.org/content/rust-semi-seamless | **OGA-BY 4.0 *and* CC0** badges. Rejected for the same dual-badge reason. Author's own notice concedes the texture has "a mediocre job on the seamlessness". |
| Crates of the Future (H-Hour) | https://opengameart.org/content/crates-of-the-future | **GPL 2.0 *and* CC0** badges (uploader later announced a public-domain relicence in the description, but the GPL badge remains on the page). Rejected under the strict rule. |
| Top-Down Spaceships Detailed (umairazfar) | https://opengameart.org/content/top-down-spaceships-detailed | Eight badges at once: CC-BY 4.0, CC-BY 3.0, CC-BY-SA 4.0, CC-BY-SA 3.0, GPL 3.0, GPL 2.0, OGA-BY 3.0 and CC0. Licence set is unusable as provenance. |
| 12 Pixel asteroids and space junks (Rocks7) | https://opengameart.org/content/12-pixel-asteroids-and-space-junks | **AI-assisted**: "This pack was created using Nano Banana 2 (Gemini 3.1 Flash Image)"; OGA policy leaves AI assets "download-disabled", and the page confirms "File(s) currently unavailable due to potential licensing issues." Unusable and provenance-unclear. Sibling packs by the same author (*36 High Quality Pixel Spaceships…*, *10 High Quality Pixel Spaceships*) sit in the same AI-disabled family. |
| Science Fiction Texture Decals (Biohazard19842) | https://opengameart.org/content/science-fiction-texture-decals | CC0 badge, notice "Free to use, no restrictions" — but the only file is a **22 MB `.psd`**, so it cannot enter the pipeline without a Photoshop pass. Same failure mode as the Tatermand packs in `ships_weapons.md:142`. |
| Big Space Gun: Free pixel-art graphics (BlackMoon Design) | https://opengameart.org/content/big-space-gun-free-pixel-art-graphics-for-your-game-0 | Page body states "It's released under **WTFPL** licence" while the OGA badge shows CC0, i.e. the licence is not unambiguous. Comments also report the archive is "a single mega-layered PHOTOSHOP file, and I can't open it". Rejected on both counts. |
| Dark war Pack (sujit1717) | https://opengameart.org/content/dark-war-pack | CC0, but the contents are "1 X Fighter plane sprite, 1 X Helicopter sprite, 1 X Missile sprite, 2 X Tank sprites, 4 X Soldier sprites, 2 X Static guns sprite, 1 X Complete GUI Pack, 1 X Airport tile" — modern ground warfare, no spaceships. Wrong subject. |
| War Pack (2dGameCreation) | https://opengameart.org/content/war-pack | CC0, but "3 planes, 1 helicopter, 3 Trucks and 2 cars" with fly/missile/cannon animations: WWII-era aircraft, not space. Wrong subject. |
| 16x16 dark tech base tileset (devurandom) | https://opengameart.org/content/16x16-dark-tech-base-tileset | CC0 and genuinely dark, but it is a PICO-8 side-scroller platform tileset (16×16, plus an 8×8 original). Wrong genre and scale for a top-down space game. |
| GothicVania — Church Pack (ansimuz) | https://opengameart.org/content/gothicvania-church-pack | CC0 and thematically "gothic", but it is Castlevania-style side-view platformer art (16×16 tiles, monk character, angel/ghoul/skeleton enemies). Nothing space-faring. The gothic *look* may be worth mining for silhouette motifs, but the art itself is out of scope. |
| Edgy sprites with a dark (gothic?) theme (FreakyFeet) | https://opengameart.org/content/edgy-sprites-with-a-dark-gothic-theme-0 | CC0, one 574 KB spritesheet, but the page describes contents only as "Art used in a game I made during my 1GAW (1 game a week) challenge" — no evidence of ships or weapons, and a single unlabelled sheet. Not verifiable as relevant. |
| Shipyard v0.4 customizable spaceships (greyoxide) | https://opengameart.org/content/shipyard-v0-4-customizable-spaceships | CC0, but **3D Art**: a single 7.8 MB `.blend` of hull sections, components, greebles. `docs/ASSETS.md` scopes the project to 2D only, no 3D models planned. |
| Space-themed turrets/devices/cruiser (Vidmaster) | https://opengameart.org/content/space-themed-turretsdevicescruiser | CC0, but **3D Art**: "All models are untextured since texturing was not necessary", `RaiderModels.7z` 13.2 MB. The 2D derivative of this pack is included as a candidate instead. |
| Terrian Space ships Set (Xavier4321) | https://opengameart.org/content/terrian-space-ships-set | CC0, but 6 of 7 files are `.blend` (4.9-8.8 MB each); the only 2D file is `LargeBlueShip.png`. Wrong format for a 2D pipeline. |
| itch.io free game-asset search (spaceship / grimdark / CC0 queries) | https://itch.io/game-assets/free?q=spaceship · https://itch.io/game-assets/free?q=cc0+spaceship | Results are author profile pages with `license: "See asset page"` — no licence stated in the listing. A broad sweep of 36 candidate packs returned only two with any CC0 signal in the title/description, and neither is a spaceship pack ("Retro Lines" platformer tiles; a CC music bundle). Per the brief, itch.io is used **only** when a page states CC0 in writing, and no such spaceship page surfaced, so itch was skipped entirely. |
| Openverse CC0 image search (spaceship / rust / metal queries) | https://api.openverse.org/v1/images/?q=spaceship+damaged&license=cc0 | API returned `{"result_count":0,...,"results":[]}` for CC0-filtered spaceship and rust queries; the browser search surfaced photographs and illustrations rather than game sprites. `ships_weapons.md:146` records the same finding, including CC-BY-SA contamination risk. No usable candidate. |

Seen but **not evaluated** (surfaced by the CC0-faceted searches; the "open the page and read the badge"
rule was not applied to them, so no licence claim is made):
`/content/space-ships-3-0`, `/content/2d-spaceships-1`, `/content/spaceship-boss-set`,
`/content/spaceship-executor-class`, `/content/spaceship-crashed`, `/content/16bit-pixel-art-spaceships`,
`/content/a-few-black-and-white-spaceshipsparts`, `/content/48px-spaceship`,
`/content/generic-pixel-spaceship-spritesheet`, `/content/space-escape-sprites`,
`/content/spaceship-set`, `/content/spaceship-black-and-purple`, `/content/space-blastro-player-ship`,
`/content/pixel-space-ship`, `/content/foxwing-starfighter`, `/content/2d-space-ships`,
`/content/some-2d-space-ships`, `/content/enemy-space-shuttle`, `/content/10-spaceships`,
`/content/lazer-zero`, `/content/space-ship-fighter-jet`, `/content/edited-space-shooter-redux-ship`,
`/content/grungy-lights-texture-pack`, `/content/science-fiction-texture-decals` (rejected above),
`/content/orbital-satellite-ion-cannon`, `/content/high-tech-combat-vehicle-heavy-battle-tank`,
`/content/tower-defence-basic-towers`, `/content/pixvoxel-*`, `/content/turrets-for-ten-floors-down`,
`/content/turret-gun-bogie-rail`, `/content/cannon-tower`, `/content/small-turret-deploying-animation`,
`/content/50-2k-metal-textures`, `/content/40-free-metal-textures-from-mtc-sets`,
`/content/free-metal-texture-creation-set-08`, `/content/details-for-metal-texture-creation-sets`,
`/content/rusty-metal-poles-texture-pack`, `/content/pbr-rusted-steel-hotspot-texture`,
`/content/urban-decay-textures-1`, `/content/urban-decay-textures-2`, `/content/huge-texture-resource-pack-part-2`,
`/content/sci-fi-top-down-centrifuge-space-station`, `/content/space-cargo-hauler`, `/content/space-port`,
`/content/misc-dark-fantasy-scenery-sprites`, `/content/gothic-window-tileset`,
`/content/16x16-8-bit-rpg-character-set`, `/content/dark-ruins-tilesets-isometric`, `/content/horror-tile-set`,
`/content/12-pixel-asteroids-and-space-junks` (rejected above), `/content/36-high-quality-pixel-spaceships-asteroids-space-junks-and-more`,
`/content/purple-and-green-eva-unit-1-inspired-shmup-space-ship` (name suggests third-party IP; approach with
caution if ever revisited).

The candidates above already cover hulls, damage states, wrecks, debris, turrets, heavy weapons and every
grime layer a grimdark reskin needs, so these are only worth a look if a specific silhouette is still
missing after the darkening test in recommendation 9.
