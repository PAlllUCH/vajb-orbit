# Vajb Orbit — CC0 Audio Research (weapons, mining, impacts, ambience, combat music)

Date: 2026-09-16 · Scope: fill the gaps left by the starter inventory (Kenney Sci-Fi Sounds,
Kenney Interface Sounds, Space Graveyard). **Nothing was downloaded**; every entry below is a
page-verified CC0 candidate with a direct download URL for a later batch.

## Summary

- **CC0 is available for every gap.** 21 verified candidates across the six missing categories.
  No CC-BY / GPL / unclear asset is needed to ship.
- **Strongest finds:** TAD's *Doomsday Laser Cannon* (heavy cannon), bart's *Space Ship Shield Sounds*,
  *Seamless Energy Emission Loop* (shield hum / mining beam loop), Kenney *Impact Sounds* (130 files),
  Joth's *7 Space Sounds* (contains an asteroid impact), and XCVG's *Fast fight / battle music (looped)*.
- **Weakest coverage is mining lasers.** A CC0-filtered search for "drill beam" returns zero SFX, and
  the only dedicated mining sample is one 215 KB OGG. Plan on layering that with
  *Seamless Energy Emission Loop* (beeam) plus an existing Kenney force-field loop.
- **Format caveat:** OpenGameArt often ships MP3 (Space Winds, 7 Space Sounds, floating sounds) or
  archives whose inner format is not stated on the page. Godot 4 imports MP3, but MP3 has no
  sample-accurate loop points, so convert looping MP3 candidates to OGG before use.
  WAV/OGG candidates should be imported as-is (WAV for short one-shots, OGG for loops).
- **Provenance:** every page below displays the OpenGameArt CC0 badge linking to
  `https://creativecommons.org/publicdomain/zero/1.0/`, or (Kenney page) `License: Creative Commons CC0`
  linking to the same deed. Candidate discovery used OpenGameArt's advanced search with the CC0 licence
  facet (`field_art_licenses_tid[]=4`) so the pool is CC0-tagged *and* each page was opened and read.

### Evidence method (repeatable)

```
https://opengameart.org/art-search-advanced?keys=<term>&field_art_type_tid%5B%5D=13&field_art_licenses_tid%5B%5D=4&sort_by=count&sort_order=DESC
# 13 = Sound Effect, 12 = Music, 4 = CC0 licence facet
```

Fit score: 5 = drop-in for a 2D top-down Dark Orbit-style shooter · 4 = good fit, light processing ·
3 = usable with pitch/tone work · 2 = weak fit · 1 = unusable.

## Candidates

### A. Weapons (rockets, heavy cannons)

| Name | Source URL | License / evidence | Contents | Formats | Fit | Direct download |
|---|---|---|---|---|---|---|
| 50 CC0 Sci-Fi SFX | https://opengameart.org/content/50-cc0-sci-fi-sfx | CC0 badge → creativecommons.org/publicdomain/zero/1.0/ (read 2026-09-16) | 50 SFX: 1 rocket, 2 shoot, 2 explosions, 1 retro explosion, 2 retro laser, 3 beeps, 6 retro beeps, 5 loops, 12 misc, 2 teleport, 9 terminal, 5 weird | ZIP (2.4 MB); inner formats not stated on page | 5 | https://opengameart.org/sites/default/files/sci-fi-sfx.zip |
| 25 CC0 bang / firework SFX | https://opengameart.org/content/25-cc0-bang-firework-sfx | CC0 badge, same deed link | 25 recorded bangs / firework / cannon / explosions; 1 loopable; a few pre-processed to sound sci-fi; short bangs usable as gunshots | ZIP (1.4 MB); inner formats not stated | 4 | https://opengameart.org/sites/default/files/25-CC0-bang-sfx.zip |
| Doomsday Laser Cannon Sound Effect | https://opengameart.org/content/doomsday-laser-cannon-sound-effect | CC0 badge, same deed link (author TAD) | 3 lengths of one heavy charge-and-fire cannon SFX: long, medium, short | WAV, individually listed (3.7 MB / 2.0 MB / 619 KB) | 5 | https://opengameart.org/sites/default/files/doomsday_laser_cannon_long.wav · https://opengameart.org/sites/default/files/doomsday_laser_cannon_midium_.wav · https://opengameart.org/sites/default/files/doomsday_laser_cannon_short.wav |
| 60 CC0 Sci-Fi SFX | https://opengameart.org/content/60-cc0-sci-fi-sfx | CC0 badge, same deed link (author rubberduck) | 22 sounds × 2-3 variations = 60 (beeps, laser, phaser, shoot, metal, terminal, warp, ambient tags) | ZIP (9.2 MB); inner formats not stated | 4 | https://opengameart.org/sites/default/files/60-sci-fi-sfx_0.zip |
| 63 Digital sound effects (Kenney) | https://opengameart.org/content/63-digital-sound-effects-lasers-phasers-space-etc | CC0 badge, same deed link | 63 SFX: 9 lasers, 15 phasers, 12 power-ups, 6 zaps, plus beeps/bonus | WAV (page states "WAV format made using KORG microKORG"), ZIP 1.1 MB | 4 | https://opengameart.org/sites/default/files/Digital_SFX_Set.zip |
| Rocket launch | https://opengameart.org/content/rocket-launch | CC0 badge, same deed link (author qubodup) | One rocket ignition/launch SFX (NASA-launch inspired) with 3-layer Audacity source | 7z archive (2.2 MB) containing WAV + .aup | 3 | https://opengameart.org/sites/default/files/launch.7z |

Notes
- *Doomsday* is the single best heavy-cannon asset found; it is a single hit, so variants come from
  pitch/volume/round-robin in Godot, not from the pack.
- *50 / 60 CC0 Sci-Fi SFX* and *63 Digital* overlap thematically with the Kenney Sci-Fi Sounds we already
  own; de-duplicate by ear before importing (Kenney's own older Digital SFX Set is worth checking for
  duplicate filenames against `raw/audio/sci-fi_sounds/Audio/`).
- A commenter on *60 CC0 Sci-Fi SFX* reported their unzip tool choking on the archive: verify integrity
  after download and re-fetch if needed.
- *Rocket launch* is a take-off/boost sound, not a projectile launch; use it for ship boost/jump, or
  reject if a 7z extractor is undesirable (see rejected/deferred list).

### B. Mining lasers

| Name | Source URL | License / evidence | Contents | Formats | Fit | Direct download |
|---|---|---|---|---|---|---|
| Mining sample | https://opengameart.org/content/mining-sample | CC0 badge, same deed link (author jordan4ibanez) | One mining/chipping sample (Minetest-era) | OGG, 214.7 KB | 4 | https://opengameart.org/sites/default/files/mining_1.ogg |
| Seamless Energy Emission Loop | https://opengameart.org/content/seamless-energy-emission-loop | CC0 badge, same deed link (author zeroisnotnull) | One seamless energy-ball / "moving shield" loop | OGG, 56.1 KB | 4 | https://opengameart.org/sites/default/files/movingshield_sound.ogg |

Notes
- Mining is the thinnest category in CC0: the CC0-filtered search for `drill beam` (Sound Effect) returns
  **0 results**, and `mining` (Sound Effect, CC0) returns exactly one asset, the sample above.
- Recommended build, all CC0 and all already in this report: mining beam = *Seamless Energy Emission Loop*
  (steady beam bed) layered with *Mining sample* (chip transients), pitched to taste per asteroid tier.
- *Seamless Energy Emission Loop* doubles as the shield-up / barrier hum, which is why it appears in two
  categories.

### C. Asteroid impacts

| Name | Source URL | License / evidence | Contents | Formats | Fit | Direct download |
|---|---|---|---|---|---|---|
| Kenney Impact Sounds | https://kenney.nl/assets/impact-sounds | Page header: `Files 130 · License Creative Commons CC0` → creativecommons.org/publicdomain/zero/1.0/ | 130 foley impacts (wood/metal-ish hits, released 2019) | ZIP of WAV (Kenney convention); ZIP name `kenney_impact-sounds.zip` | 5 | https://kenney.nl/media/pages/assets/impact-sounds/87b4ddecda-1677589768/kenney_impact-sounds.zip |
| 75 CC0 breaking / falling / hit sfx | https://opengameart.org/content/75-cc0-breaking-falling-hit-sfx | CC0 badge, same deed link (author rubberduck) | 75 SFX: breaking, falling, hits across wood / metal / glass / stone / rock, cracking, destruction | ZIP (1.6 MB); inner formats not stated | 4 | https://opengameart.org/sites/default/files/sfx_breaking_and_falling.zip |
| 7 Space Sounds | https://opengameart.org/content/7-space-sounds | CC0 badge, same deed link (author Joth) | One file with 7 sounds: menu scroll, menu quit, engine/thruster, access denied, **gentle asteroid impact**, warning, sonic missile detonation | MP3, 337.9 KB (single file, needs splitting) | 4 | https://opengameart.org/sites/default/files/7%20Space%20Sounds_1.mp3 |
| Space Sound Effects (messersm) | https://opengameart.org/content/space-sound-effects | CC0 badge, same deed link | 6 lasers, 6 explosions, 1 warpout, 1 notification/message, each with Bfxr spec for re-tuning | ZIP (134.8 KB); Bfxr output (typically WAV) | 3 | https://opengameart.org/sites/default/files/SpaceSFX1.zip |

Notes
- Asteroids in Vajb Orbit should read as rock-on-shield/hull: *Kenney Impact Sounds* plus *75 CC0 …*
  covers this, but both are natural/foley sources; pitch down 15-40 % and add a short synthetic
  sub-thump (Kenney Sci-Fi Sounds already has impacts) for the "void" character.
- *7 Space Sounds* is the only asset that literally names an asteroid impact; it is a single MP3, so it
  must be trimmed into individual cues first.
- *Space Sound Effects* is Bfxr/retro and will clash with the Kenney pack's timbre; keep it as a
  prototype placeholder rather than a shipping candidate.

### D. Shield hits

| Name | Source URL | License / evidence | Contents | Formats | Fit | Direct download |
|---|---|---|---|---|---|---|
| Space Ship Shield Sounds | https://opengameart.org/content/space-ship-shield-sounds | CC0 badge, same deed link (author bart) | A set of starship shield SFX, plus the FL Studio source project | ZIP (1.6 MB); inner formats not stated | 5 | https://opengameart.org/sites/default/files/space%20shield%20sounds.zip |
| Seamless Energy Emission Loop | https://opengameart.org/content/seamless-energy-emission-loop | CC0 badge, same deed link | Seamless energy loop (shield-up bed / energy ball) | OGG, 56.1 KB | 4 | https://opengameart.org/sites/default/files/movingshield_sound.ogg |
| 10 Impact/Shield Blocks | https://opengameart.org/content/10-impactshield-blocks | CC0 badge, same deed link (author StarNinjas) | 10 impact / shield-block / punch hits, recorded from cardboard | ZIP (128.5 KB); inner formats not stated | 3 | https://opengameart.org/sites/default/files/impact_-_starninjas.zip |

Notes
- *Space Ship Shield Sounds* is the best category fit found (space + ship + shield tags, community-proven
  in browser/space games). It ships the source project, so re-voicing per shield tier is possible.
- *10 Impact/Shield Blocks* is cardboard foley: it reads as "thud" rather than "energy". Use only for a
  low-tech/primitive shield, or as a layered body under a synthetic zap.
- The page for *10 Impact/Shield Blocks* carries an optional "credit appreciated" notice; CC0 makes that
  non-binding, and the manifest records provenance anyway.

### E. Ambient space ambience loops

| Name | Source URL | License / evidence | Contents | Formats | Fit | Direct download |
|---|---|---|---|---|---|---|
| Background space track (yd) | https://opengameart.org/content/background-space-track | CC0 badge, same deed link (author yd) | Dark ambient drone ("My Very Own Dead Ship"): background, space, loop, drone, mystery tags, plus LMMS source | ZIP (4.2 MB) containing OGG + LMMS project | 5 | https://opengameart.org/sites/default/files/projects.zip |
| Space Music: Out There (yd) | https://opengameart.org/content/space-music-out-there | CC0 badge, same deed link (author yd) | 4 minutes of loopable background space music (background, loop, ogg tags) | OGG, 3.9 MB | 4 | https://opengameart.org/sites/default/files/OutThere_0.ogg |
| Space Winds | https://opengameart.org/content/space-winds | CC0 badge, same deed link (author aquinn) | Space winds / lonely background noise bed for space games | MP3, 778.2 KB | 4 | https://opengameart.org/sites/default/files/space-wind_0.mp3 |
| Space ship floating sounds(2) | https://opengameart.org/content/space-ship-floating-sounds2 | CC0 badge, same deed link (author pauliuw) | 2 long starship "floating" ambience beds | MP3, 784.7 KB and 780.6 KB | 4 | https://opengameart.org/sites/default/files/space_ship_floating_sound_1.mp3 · https://opengameart.org/sites/default/files/space_ship_floating_sound.mp3 |
| Thruster | https://opengameart.org/content/thruster | CC0 badge, same deed link (author EZduzziteh) | One spaceship thruster loop (same author as a space-jam game) | OGG, 94.9 KB | 4 | https://opengameart.org/sites/default/files/space_ship_0.ogg |
| Rocket Engine | https://opengameart.org/content/rocket-engine | CC0 badge, same deed link (author theMinesAreShakin) | Loopable low-rumble rocket/spaceship engine | WAV, 1.2 MB | 4 | https://opengameart.org/sites/default/files/rocket_engine.001.wav |

Notes
- *Background space track* and *Space Music: Out There* are the two best full-length CC0 space beds and
  both come from the same author (yd), so they sit in one tonal family alongside the already-owned
  *Space Graveyard*. They work as: station/sector ambience (dead-ship drone), galaxy-map or hangar
  music (Out There).
- *Space Winds*, *floating sounds*, and *7 Space Sounds* ship as MP3. Convert to OGG for looping in
  Godot 4: MP3 loop points are not sample-accurate and will click or drift.
- Engine beds are partly redundant with Kenney Sci-Fi Sounds (engines/thrusters already owned); the
  value here is a *low rumble* layer for capital ships, which the Kenney set does not have.

### F. Light combat music

| Name | Source URL | License / evidence | Contents | Formats | Fit | Direct download |
|---|---|---|---|---|---|---|
| Fast fight / battle music (looped) | https://opengameart.org/content/fast-fight-battle-music-looped | CC0 badge, same deed link (loop edit by XCVG; original by Ville Nousiainen) | Looped battle/boss music, tagged loop, action, fast, fight, space; page notes the original "would suit a space game" | WAV, 4.4 MB | 5 | https://opengameart.org/sites/default/files/fight_looped.wav |
| Space Music: Out There (yd) | https://opengameart.org/content/space-music-out-there | CC0 badge, same deed link | 4-minute loopable ambient space track; usable as non-combat "light" combat bed if a mellow tone is wanted | OGG, 3.9 MB | 4 | https://opengameart.org/sites/default/files/OutThere_0.ogg |

Notes
- Only one genuine CC0 *combat* track was found that fits a space shooter; budget a second source or
  accept a single battle theme with variations (intro stinger + loop) for now.
- The looped edit page carries an optional credit request for Ville Nousiainen / XCVG. CC0 does not
  require it, and CC0-only policy means no credits file obligation, but recording it in the manifest is
  free goodwill.

## Recommendations

Priority order for the next (download) batch, one asset per gap to start:

1. **Heavy cannon:** TAD *Doomsday Laser Cannon* (short + medium for turret tiers, long for a doomsday
   charge-up). CC0, real WAV, best quality/effort ratio in the whole report.
2. **Rockets:** *50 CC0 Sci-Fi SFX* (rocket + shoot + loops) with *25 CC0 bang / firework SFX* as the
   detonation layer; both rubberduck packs are small and CC0.
3. **Shield hits:** bart *Space Ship Shield Sounds* for the hit set, *Seamless Energy Emission Loop* for
   the shield-up bed.
4. **Mining:** *Mining sample* + *Seamless Energy Emission Loop* layered. Accept that mining will be a
   synthesized composite rather than a single dedicated asset.
5. **Asteroid impacts:** *Kenney Impact Sounds* (130 files, same vendor as the sprites we already use, so
   tonal consistency is cheap) plus *75 CC0 breaking / falling / hit sfx* as the secondary layer.
6. **Ambience loops:** *Background space track* (yd) for sector ambience, *Space Winds* for open-space
   emptiness, *Rocket Engine* for capital-ship rumble.
7. **Combat music:** *Fast fight / battle music (looped)*.
8. Nice-to-have: *63 Digital sound effects (Kenney)* if we want phaser variants that Kenney Sci-Fi
   Sounds lacks.

Practical notes for that batch:
- Download into `asset-library/raw/audio/<pack_name>/`, then move files by hand (the extractor flattens
  `subfolder`; see `docs/ASSETS.md`).
- Convert every MP3-sourced candidate to OGG; keep WAV for one-shots.
- Godot import presets: short SFX as WAV/OGG one-shots, ambience/music with `loop = true` and
  `loop_offset = 0`; verify seamlessness on the two "seamless"/"loop" tagged assets.
- Rebuild `ASSET_MANIFEST.json` and `CREDITS.md` after import (`create_asset_manifest`,
  `generate_credits`) even though CC0 needs no attribution.

## Rejected

Verified and rejected:

| Asset | URL | Reason |
|---|---|---|
| Mining Drill | https://opengameart.org/content/mining-drill | Wrong type (a 3D `.blend` model, not audio) **and** wrong licence: page shows **CC-BY 3.0 + CC-BY-SA 3.0**, with "If you use this please credit me". Fails the strict-CC0 rule twice. |
| Lost in a bad place (horror ambience loop) | https://opengameart.org/content/lost-in-a-bad-place-horror-ambience-loop | Surfaced with `license_status: blocked_unclear_license` (no licence metadata readable by the search tool) and the theme is horror, not space combat. Not pursued: unclear licence + off-theme. |
| Cathedral in the forest (ambient loop) | https://opengameart.org/content/cathedral-in-the-forest-ambient-loop | Same: unclear licence metadata, fantasy/forest ambience, no space-shooter fit. |
| Ancient caverns (horror ambient loop) | https://opengameart.org/content/ancient-caverns-horror-ambient-loop | Same: unclear licence metadata, cavern/horror theme. |
| Space Echo | https://opengameart.org/content/space-echo | Same: unclear licence metadata; not verifiable as CC0 without deeper digging, and equivalent CC0 ambience already exists (yd tracks). |
| "rocket launcher" art-search results (Rocket Launcher, A better Rocket Launcher, Missile Launcher Tank, Low Poly RPG7, …) | https://opengameart.org/art-search-advanced?keys=rocket+launcher | Whole result page is 2D/3D models and sprites, no audio. Wrong asset type. |
| "cannon missile" CC0 Sound Effect search | (advanced search, CC0 facet, term `cannon missile`) | Returned **zero** results: no CC0 cannon/missile-specific SFX exists under those terms. Covered instead by *Doomsday*, *25 CC0 bang*, *50 CC0 Sci-Fi SFX*. |
| "drill beam" CC0 Sound Effect search | (advanced search, CC0 facet, term `drill beam`) | Returned **zero** results. Documented as a real gap; see Recommendations item 4 for the composite workaround. |

Not evaluated (deferred, not rejected) — licence unverified, so out of scope for this pass:
`/content/explosion-0`, `/content/chunky-explosion`, `/content/muffled-distant-explosion`,
`/content/synthesized-explosion`, `/content/space-ambient`, `/content/deep-space-flight`,
`/content/space-atmospere`, `/content/another-space-background-track`, `/content/space-music`,
`/content/t-t-free-cyberpunk-pack`, `/content/crimson-space-station-background-ambient-music-1`.
All appeared inside CC0-faceted searches, so they are plausible, but the strict rule is
"open the page and read the badge", and that was not done for them. Candidates above already cover
every gap, so these are only worth a look if a specific mood is still missing.
