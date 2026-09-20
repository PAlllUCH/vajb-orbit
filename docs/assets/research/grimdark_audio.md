# Vajb Orbit — Grimdark Audio Research (dread drones, industrial machinery, sub-bass rumble, hull creaks, dark combat, horror stingers)

Date: 2026-09-16 · Scope: a grimdark audio direction for the 2D top-down space shooter — dark ambient /
dread drones, industrial machine loops, deep sub-bass rumbles, hull groans and creaks, ominous pads,
dark combat music, horror stingers for boss encounters and derelict stations. Complements
`docs/assets/research/audio.md` (weapons, mining, impacts, shields, ambience, light combat) —
**no candidate below appears in that report**. **Nothing was downloaded.**

## Summary

- **CC0 covers every grimdark category.** 41 verified candidates were found across OpenGameArt and
  itch.io. No CC-BY / CC-BY-SA / OGA-BY / GPL asset is needed to build the whole grimdark palette.
- **Strongest finds:**
  - *Ambience Pack 1 — Sci Fi Horror* (Joth): 5 loopable dark sci-fi ambience tracks built for horror
    interiors — the single best "derelict station" pack found.
  - *Horror Atmosphere* (Juhani Junkala / SubspaceAudio): one 5:23 seamless loop of melody-free dread,
    tagged ominous / tension / distress / space. The best "dread drone bed" found.
  - *Factory ambiance* + *EmptyCity* + *I swear I saw it* (yd): industrial-ruin and dead-city beds in the
    same tonal family as the *Space Graveyard* track the project already owns.
  - *30 CC0 SFX loops* (rubberduck): 11 machine loops + 3 alarms + 3 ambient loops in one 3.5 MB ZIP —
    the cheapest way to cover industrial machinery.
  - *Nihilex Free Audio Asset Collection* (itch.io): explicit in-writing CC0 covering dark ambient
    soundscapes and a seven-room "Underground Facility Ambient Pack" (SCP-derived) — the only large
    itch.io source that survived verification.
- **Rumble is abundant but heavy.** The two bretbernhoft packs (*Droning Sound Effects*, *Rumbling Sound
  Effects*) are the deepest sub-bass material found, but files are 21–46 MB WAV **each**; the lean
  alternative is gmason's *underwater or space engine rumble* (two rumble beds, 0.5 MB OGG each).
- **Hull groans/creaks have no dedicated space asset.** The workable build is *Tree Creaking*
  (pitched down, layered), *Metal Interactions*, *68 Workshop Sounds* and *Deep Bone Crack/Break*
  as the fracture layer. This is the thinnest category, same as mining was in the previous report.
- **Dark combat music is well covered** by nene's metal boss-battle pieces, vitalezzz's *Hunter-class
  Lifeform* and the *Eerie Space Music* pack — all listed, loop-ready or with opening+loop splits.
- **Stingers are a real gap on OpenGameArt:** a CC0-faceted search for the term `stinger` (Sound Effect)
  returns **zero** results. Covered instead by *Horror SFX*, *CC0 Deep Monster Roar* and
  *3 dark magic spells*, plus Phlegmlee's itch.io horror pack.
- **Format caveats:** several strong candidates ship **MP3-only** (*Ambience Pack 1*, Joth's own comment
  thread shows the OGG request went unanswered; *Underwater rumble* alternative, *Overshadow*,
  *Persistence*, *Downfall*, *Abandon Hope*, *Night of the Streets*) and **FLAC-only** (*The World Fell
  Silent* set, *Electronic device loop*, *Dark Shrine Loop* FLAC variant). Godot 4 imports MP3 but MP3
  has no sample-accurate loop points, and Godot does **not** import FLAC at all — convert both to
  OGG before use. WAV/OGG candidates import as-is.
- **Provenance:** every OpenGameArt page below was opened and read on 2026-09-16 and displays the CC0
  badge linking to `https://creativecommons.org/publicdomain/zero/1.0/`; where an author also wrote an
  explicit notice it is quoted. itch.io entries were used **only** because the page states CC0 in
  writing (body text or the itch.io `Asset license: Creative Commons Zero v1.0 Universal` field).

### Evidence method (repeatable)

```
https://opengameart.org/art-search-advanced?keys=<term>&field_art_type_tid%5B%5D=13&field_art_licenses_tid%5B%5D=4&sort_by=count&sort_order=DESC
# 13 = Sound Effect, 12 = Music, 4 = CC0 licence facet
```

Terms swept: dark ambient, horror, drone, industrial, rumble, dark, machine, metal, deep, creak,
tension, boss, stinger (zero hits). Every page surfaced by those sweeps was opened individually before
being accepted; pages whose badge was not read are listed under *Not evaluated* rather than rejected.

Fit score: 5 = drop-in for a grimdark 2D top-down Dark Orbit-style shooter · 4 = strong fit, light
processing · 3 = usable with pitch/tone work or after conversion · 2 = weak fit · 1 = unusable.

---

## Candidates

### A. Dark ambient, dread drones and ominous pads (music beds)

| Name | Source URL | License / evidence | Contents | Formats | Fit | Direct download | Notes |
|---|---|---|---|---|---|---|---|
| Ambience Pack 1 — Sci Fi Horror | https://opengameart.org/content/ambience-pack-1-sci-fi-horror | CC0 badge → creativecommons.org/publicdomain/zero/1.0/ (read 2026-09-16) | 5 loopable dark sci-fi ambience tracks, ~1:00 each: The Surreal Truth, Infestation in the Control Room, Final Captain's Log, The Depths of Hell, Cage of the Cryptid | MP3, 957 KB–1.2 MB per track | 5 | https://opengameart.org/sites/default/files/The%20Surreal%20Truth.mp3 · https://opengameart.org/sites/default/files/Infestation%20in%20the%20Control%20Room.mp3 · https://opengameart.org/sites/default/files/Final%20Captain%27s%20Log.mp3 · https://opengameart.org/sites/default/files/The%20Depths%20of%20Hell.mp3 · https://opengameart.org/sites/default/files/Cage%20of%20the%20Cryptid.mp3 | **MP3-only** — loop points not sample-accurate, convert to OGG. Tracks are named for exactly the situations this game needs (derelict log, infested control room, hell depths) |
| Horror Atmosphere | https://opengameart.org/content/horror-atmosphere | CC0 badge, same deed link (author SubspaceAudio / Juhani Junkala) | One sparse, melody-free dread bed: creepy atmospheres + background noises, 5:23, page states "loops seamlessly" | OGG, 14.2 MB | 5 | https://opengameart.org/sites/default/files/Juhani%20Junkala%20-%20Post%20Apocalyptic%20Wastelands%20%5BLoop%20Ready%5D.ogg | Tagged horror/scary/tension/distress/ominous/space. Already loop-ready; large but single-file. Best candidate for a sector-wide dread layer |
| Dark Ambiences | https://opengameart.org/content/dark-ambiences | CC0 badge, same deed link (author Ogrebane) | 5 darkish ambient sounds; page states ".wav format" | ZIP 3.1 MB, inner WAV | 4 | https://opengameart.org/sites/default/files/dark_ambiences.zip | Tagged dark/ambience/scary/spooky/Sci-Fi; community-used in horror games since 2011 |
| Ambient horror | https://opengameart.org/content/ambient-horror | CC0 badge, same deed link (author techiew). Notice: "Free for all to use for any purpose, but I'd love to know if you ever use this in your project" | One horror ambience recording (tags: monster, scream, choir, evil) | OGG 776 KB · WAV 4.3 MB | 4 | https://opengameart.org/sites/default/files/ambient_horror_0.ogg | WAV twin is handy if the OGG needs trimming/re-encoding; notice is a courtesy request, CC0 makes it non-binding |
| 4 Atmospheric ghostly loops | https://opengameart.org/content/4-atmospheric-ghostly-loops | CC0 badge, same deed link (author Independent.nu, submitted by qubodup) | 4 scary dark atmospheric loops (ghost/dark/horror/angst/atmosphere) | 7z 3.4 MB; inner format not stated | 4 | https://opengameart.org/sites/default/files/independent_nu_ljudbank-atmosphere_moody.7z | Requires a 7z extractor; the 3D-shooter-friendly loop family, good under engine hum |
| Dark Cavern Ambient | https://opengameart.org/content/dark-cavern-ambient | CC0 badge, same deed link (author Paul Wortmann) | 2 renders of one dark ambience: 001 fades in/out, 002 is a continuous loop | OGG, 1.7 MB each | 3 | https://opengameart.org/sites/default/files/dark_cavern_ambient_001.ogg · https://opengameart.org/sites/default/files/dark_cavern_ambient_002.ogg | Cave/dungeon intent, but "001 fade" is directly reusable for derelict-station reveal moments |
| Cold Silence | https://opengameart.org/content/cold-silence | CC0 badge, same deed link (author Eponasoft) | One dark ambient piece written for "a particularly dark part" of an unreleased game; page describes it as "rather unsettling to listen to" | OGG, 5.2 MB | 4 | https://opengameart.org/sites/default/files/cold_silence.ogg | In collection *Dark Sci-Fi*; fantasy-composed but tonally cold — good for a dead sector |
| Deep Humidity | https://opengameart.org/content/deep-humidity | CC0 badge, same deed link (author TinyWorlds) | Ambient track for exploring a cave or lost place; tagged horror/dark/deep/mine | OGG, 473 KB | 4 | https://opengameart.org/sites/default/files/deep-humidity.ogg | Cheap, short, no melody — loopable low-intrusion bed for station interiors |
| EmptyCity | https://opengameart.org/content/emptycity-background-music | CC0 badge, same deed link (author yd) | Dark loopable track for exploring a devastated city; tagged dark/ruins/horror/ghost/post-apocalyptic | OGG 2 MB (+ LMMS source ZIP 59.9 KB) | 5 | https://opengameart.org/sites/default/files/EmptyCity.ogg | LMMS source available (https://opengameart.org/sites/default/files/EmptyCity.zip) so stems can be re-mixed per sector |
| I swear I saw it — background track | https://opengameart.org/content/i-swear-i-saw-it-background-track | CC0 badge, same deed link (author yd) | ~3.5 min dark/mystery/space ambient loop; LMMS source attached | OGG, 4.2 MB | 5 | https://opengameart.org/sites/default/files/IswearIsawit_0.ogg | Already widely used in space shooters; same author family as *Space Graveyard* we own |
| Factory ambiance | https://opengameart.org/content/factory-ambiance | CC0 badge, same deed link (author yd) | Background bed for exploring an industrial complex; tagged dead, forgotten, alone, ruins, industrial, dark | OGG, 2.5 MB | 5 | https://opengameart.org/sites/default/files/Factory.ogg | Commenters compare it to Fallout 2's Vault Archives — exactly the grimdark register wanted |
| Dark Intro | https://opengameart.org/content/dark-intro | CC0 badge, same deed link (author Nikke) | One dark space/sci-fi intro with a drone-like opening; tagged boss, danger, deep, homeworld | OGG, 1.6 MB | 4 | https://opengameart.org/sites/default/files/Dark%20Intro_0.ogg | Works as cutscene/sector-entry sting into a boss, not as an endless bed |
| Station Drone 2 | https://opengameart.org/content/station-drone-2 | CC0 badge, same deed link. Notice: "Copyright/Attribution Notice: CC0" | Background drone with strange sound effects; MIDI + rendered OGG | OGG 1.5 MB · MID 8.4 KB | 4 | https://opengameart.org/sites/default/files/dronestation2_0.ogg | Name says it: station bed. MIDI means the texture can be re-voiced |
| Manaos Drones | https://opengameart.org/content/manaos-drones | CC0 badge, same deed link. Notice: "Copyright/Attribution Notice: CC0" | One public-domain drone effect (built from CC0 samples), originally for a worm planet | OGG, 662 KB | 4 | https://opengameart.org/sites/default/files/manaosdrone1_0.ogg | In the OGA *audio::music::space* collection; small, dark, easy to layer |
| Dissonance Anthem | https://opengameart.org/content/dissonance-anthem | CC0 badge, same deed link (author Some Weirdo) | 21 minutes of microtonal dissonant drone, 60 automated cycles of one dorian progression (never repeats exactly) | OGG, 56.6 MB | 4 | https://opengameart.org/sites/default/files/dissonance_anthem.ogg | Unique "wrong" texture — good for the deep-space / alien-artifact sector. Very large file; trim the first minutes |
| Overshadow | https://opengameart.org/content/overshadow | CC0 badge, same deed link (author cinameng) | One ambient drone, mysterious sci-fi atmosphere | MP3, 2.4 MB | 3 | https://opengameart.org/sites/default/files/overshadow_0.mp3 | MP3-only; superseded by the same author's *Abandon Hope* unless a specific tone is wanted |
| Abandon Hope | https://opengameart.org/content/abandon-hope | CC0 badge, same deed link. Notice: "Copyright/Attribution Notice: James Gargette" | 32-bar dystopian synth drone | MP3, 4.8 MB | 4 | https://opengameart.org/sites/default/files/abandon_hope_4.mp3 | Tagged dystopian/drone/synth; MP3 → convert for clean looping |
| Persistence | https://opengameart.org/content/persistence | CC0 badge, same deed link (author cinameng) | Space ambient drone texture, plus a short loop edit | MP3 5.1 MB · MP3 2.3 MB | 3 | https://opengameart.org/sites/default/files/persistence_0.mp3 · https://opengameart.org/sites/default/files/persistence-loopshort_1.mp3 | A commenter notes the master volume is very low (needs gain normalisation); MP3-only |
| Downfall | https://opengameart.org/content/downfall | CC0 badge, same deed link. Notice: "Vitalezzz - Downfall" | Slow electronic space drone | MP3 9.6 MB · WAV 63.5 MB · FLAC 43 MB | 4 | https://opengameart.org/sites/default/files/downfall_0.mp3 | Three formats offered; take the MP3 for size or the WAV if a lossless master is wanted. (FLAC will not import) |
| The World Fell Silent (+ Outpost, Dirty Rain) | https://opengameart.org/content/the-world-fell-silent | CC0 badge, same deed link. Notice: "CC0 / Public Domain. No Rights Reserved. Free to use however you like with no attribution required." | 3 post-apocalyptic tracks, each with a separate loop render: The World Fell Silent, Outpost, Dirty Rain | FLAC only, 8.1–21.6 MB per file | 4 | https://opengameart.org/sites/default/files/the_world_fell_silent.flac · https://opengameart.org/sites/default/files/the_world_fell_silent_loop.flac · https://opengameart.org/sites/default/files/outpost_loop.flac · https://opengameart.org/sites/default/files/dirty_rain_loop.flac | **FLAC → must convert** (Godot 4 has no FLAC importer). Loop renders already cut, which saves seam work |

Notes
- *Ambience Pack 1* and *Horror Atmosphere* are the two "set the whole sector" assets; everything else
  in this table is a layer or a variation.
- yd's tracks (*EmptyCity*, *I swear I saw it*, *Factory ambiance*) come with LMMS sources and sit in
  one tonal family with the *Space Graveyard* track already owned — use them as the ambient spine.

### B. Industrial machine loops and station machinery

| Name | Source URL | License / evidence | Contents | Formats | Fit | Direct download | Notes |
|---|---|---|---|---|---|---|---|
| 30 CC0 SFX loops | https://opengameart.org/content/30-cc0-sfx-loops | CC0 badge, same deed link (author rubberduck) | 30 seamless loops: 3 alarm, 3 ambient, **11 machine**, 3 noise, 2 water pump, 1 rain, 1 rolling, 1 hand saw, 1 boiling water, 1 flowing water, 3 weird; most up to 8 s long | ZIP 3.5 MB; inner format not stated | 5 | https://opengameart.org/sites/default/files/sfx_loops.zip | Best value-per-byte in the whole report — the 11 machine loops are literally the "industrial machine loop" brief |
| Steam boiler sound loop | https://opengameart.org/content/steam-boiler-sound-loop | CC0 badge, same deed link (author bart). Page note: "Attribution appreciated. :)" | One loopable generator/boiler bed, synthesized (Image-Line Ogun) for metal-type timbre | WAV, 3.9 MB | 4 | https://opengameart.org/sites/default/files/generator_loop.wav | Genuinely synthesized metal, unlike the foley packs; loops cleanly at 3.9 MB |
| Electronic device loop | https://opengameart.org/content/electronic-device-loop | CC0 badge, same deed link (author qubodup) | One loop of a workstation hard-disk hum, normalised | FLAC, 357 KB | 4 | https://opengameart.org/sites/default/files/qubodup-edev.flac | **FLAC → convert.** Reader feedback on the page says it was pitched down into a door sound; it is the quiet-room hum layer |
| Machine shutting down | https://opengameart.org/content/machine-shutting-down | CC0 badge, same deed link (author Cough-E). Notice: "Use however you want, even commercially. No credit needed" | One machine power-down / power-loss SFX | OGG, 127.7 KB | 4 | https://opengameart.org/sites/default/files/MachinePowerOff.ogg | Perfect for station blackout / system-failure events; tiny |
| SFX — Circuit breaker | https://opengameart.org/content/sfx-circuit-breaker | CC0 badge, same deed link (author CleytonKauffman) | Circuit breaker ON and OFF takes; page states "Format: WAV", tagged thriller/horror | ZIP 189 KB, inner WAV | 3 | https://opengameart.org/sites/default/files/Circuit%20Breaker.zip | Breaker throws for power routing / breach events |
| Mechanical Explosion | https://opengameart.org/content/mechanical-explosion | CC0 badge, same deed link. Notice: "Copyright/Attribution Notice: Spring Spring" | One explosion with clattering metal; page suggests it doubles as industrial percussion | WAV, 522 KB | 4 | https://opengameart.org/sites/default/files/mechanical_explosion.wav | Doubles as a percussion loop element for an industrial combat cue |
| KOHLE UND STAHL KEMISCHER KRIEGSPRODUKTION | https://opengameart.org/content/kohle-und-stahl-kemischer-kriegsproduktion | CC0 badge, same deed link (author Spring Spring) | Industrial/military music with voices and machine noises (an attempted Red Alert 1 homage) | OGG, 2.6 MB | 4 | https://opengameart.org/sites/default/files/KOHLE%20UND%20STAHL%20KEMISCHER%20KRIEGSPRODUKTION_0.ogg | Grimdark-industrial in the C&C sense; a commenter calls it a space-travel Amiga vibe, so it fits a dreadnought hangar |
| Hardwar | https://opengameart.org/content/hardwar | CC0 badge, same deed link. Notice: "Copyright/Attribution Notice: James Gargette" | Short industrial techno loop (lo-fi synth) | WAV 4.8 MB · MP3 719 KB | 3 | https://opengameart.org/sites/default/files/hardwar.wav | Lo-fi by design; good for a factory/forge bay rather than the main combat loop |

Notes
- *30 CC0 SFX loops* plus *Steam boiler* plus *Electronic device loop* is a complete three-layer
  machinery bed (rhythmic machines + boiler body + electrical hum) with no external processing.
- Everything here is short-loop material: import as looping OGG/WAV with `loop = true`.

### C. Deep sub-bass rumbles

| Name | Source URL | License / evidence | Contents | Formats | Fit | Direct download | Notes |
|---|---|---|---|---|---|---|---|
| Rumbling Sound Effects | https://opengameart.org/content/rumbling-sound-effects | CC0 badge, same deed link (author bretbernhoft). Page states: "All sounds in this pack are available in the public domain and can be used freely without attribution" | 12 deep rumbles described as earthquake / mechanical-vibration / atmospheric-disturbance beds | WAV, 42.3–46.1 MB **per file** | 4 | https://opengameart.org/sites/default/files/rumbling17.wav · https://opengameart.org/sites/default/files/rumbling18.wav · https://opengameart.org/sites/default/files/rumbling19_0.wav (page displays `rumbling19.wav`; served name carries the `_0` suffix) · https://opengameart.org/sites/default/files/rumbling20.wav · https://opengameart.org/sites/default/files/rumbling21.wav · https://opengameart.org/sites/default/files/rumbling22.wav · https://opengameart.org/sites/default/files/rumbling23.wav · https://opengameart.org/sites/default/files/rumbling24.wav · https://opengameart.org/sites/default/files/rumbling25.wav · https://opengameart.org/sites/default/files/rumbling26.wav · https://opengameart.org/sites/default/files/rumbling27.wav · https://opengameart.org/sites/default/files/rumbling28.wav (all 12 URLs listed; every other file is served under its displayed name) | Deepest sub-bass found, but ~500 MB for the set; download 2–3 files, not all 12. Convert/trim before import |
| Droning Sound Effects | https://opengameart.org/content/droning-sound-effects | CC0 badge, same deed link (author bretbernhoft). Page states: "All of the files in this pack are available in the public domain and can be freely used without attribution" | 19 custom drones (drone53–drone71): ambient soundscapes, **mechanical hums**, celestial/haunting/deep/anxious tones | WAV, 21.2–46.1 MB **per file** | 4 | https://opengameart.org/sites/default/files/drone53.wav · https://opengameart.org/sites/default/files/drone54.wav · https://opengameart.org/sites/default/files/drone55.wav · https://opengameart.org/sites/default/files/drone56.wav · https://opengameart.org/sites/default/files/drone57.wav · https://opengameart.org/sites/default/files/drone58.wav · https://opengameart.org/sites/default/files/drone59.wav · https://opengameart.org/sites/default/files/drone60.wav · https://opengameart.org/sites/default/files/drone61.wav · https://opengameart.org/sites/default/files/drone62.wav · https://opengameart.org/sites/default/files/drone63.wav · https://opengameart.org/sites/default/files/drone64.wav · https://opengameart.org/sites/default/files/drone65.wav · https://opengameart.org/sites/default/files/drone66.wav · https://opengameart.org/sites/default/files/drone67.wav · https://opengameart.org/sites/default/files/drone68.wav · https://opengameart.org/sites/default/files/drone69.wav · https://opengameart.org/sites/default/files/drone70.wav · https://opengameart.org/sites/default/files/drone71.wav (all 19 URLs listed; every file is served under its displayed name) | Overlaps *Rumbling*; pick either. Good capital-ship engine-room bed once trimmed |
| rumble fx | https://opengameart.org/content/rumble-fx | CC0 badge, same deed link (author cinameng) | One 19 s rumble with built-in fade in/out | WAV, 5.1 MB | 4 | https://opengameart.org/sites/default/files/rumble.wav | The cheap drop-in "something huge is near" cue; fades make it stinger-adjacent |
| underwater or space engine rumble | https://opengameart.org/content/underwater-or-space-engine-rumble | CC0 badge, same deed link (author gmason) | 2 beds, each in OGG + MP3: a space-engine rumble and a "deep rumble" (ocean recording low-passed at 200 Hz / 100 Hz) | OGG 511.9 KB & 553.8 KB · MP3 476.2 KB & 470 KB | 5 | https://opengameart.org/sites/default/files/underwater_or_space_engine_0.ogg · https://opengameart.org/sites/default/files/deep_rumble.ogg | Best effort/quality ratio of the rumble set: already space-named, tiny, OGG loop-ready |

Notes
- Sub-bass in this game should sit under the engine bed, not on its own; the gmason pair is enough for
  a first pass, with one bretbernhoft drone as the "derelict dreadnought" upgrade.

### D. Hull groans, creaks and metal stress

| Name | Source URL | License / evidence | Contents | Formats | Fit | Direct download | Notes |
|---|---|---|---|---|---|---|---|
| Tree Creaking | https://opengameart.org/content/tree-creaking | CC0 badge, same deed link (author AntumDeluge, from Department64). Page states: "Licensing: Creative Commons Zero (CC0)" | One clean creak, normalised to -6 dB max (mono, 44.1 kHz, OGG 96 kbps) | OGG 71.4 KB · FLAC 231.9 KB | 4 | https://opengameart.org/sites/default/files/tree_creak_0.ogg | The only dedicated creak found. Pitch down 20–40 % and layer under a metal hit and it reads as hull stress |
| Metal Interactions | https://opengameart.org/content/metal-interactions | CC0 badge, same deed link (author qubodup) | Heavy metal hits, clangs, punches, door/chest/button/switch handling, one electric element; tags include machine and dark | 7z 166.3 KB; inner format not stated | 4 | https://opengameart.org/sites/default/files/metal_interactions.7z | Community-proven (used in *Nikki and the Robots*); 166 KB for the whole set. Needs a 7z extractor |
| 68 Workshop Sounds | https://opengameart.org/content/68-workshop-sounds | CC0 badge, same deed link (author bart). Page note: "Credit appreciated. :)" | 68 recorded tool sounds: metal, wood, hammer, drill, wrench, clatter (Tascam DR-05, garage-recorded) | 7z 24.6 MB; inner format not stated | 3 | https://opengameart.org/sites/default/files/workshop.7z | Largest foley bank here; a commenter warns several files carry heavy background noise after amplification. Good for serviced-machinery layer, not for clean hull tones |
| Deep Bone Crack/Break SFX | https://opengameart.org/content/deep-bone-crackbreak-sfx | CC0 badge, same deed link (author Zane Little Music) | 10 deep visceral cracks with variation ("deep, visceral, poppy") | ZIP 2.6 MB; inner format not stated | 4 | https://opengameart.org/sites/default/files/deep_breaks.zip | Pitched down and low-passed these are the hull-fracture transients; in the OGA *Space Collection* already |

Notes
- Recommended build for a hull groan: *Tree Creaking* (body) + *Metal Interactions* (ring) +
  *Deep Bone Crack* (fracture), all pitched down, randomised in pitch ±10 %.
- A 100-file *100 CC0 metal and wood SFX* pack also exists in the same searches but was not opened, so
  it is not listed as a candidate.

### E. Horror stingers and boss accents

| Name | Source URL | License / evidence | Contents | Formats | Fit | Direct download | Notes |
|---|---|---|---|---|---|---|---|
| Horror SFX | https://opengameart.org/content/horror-sfx | CC0 badge, same deed link (author TinyWorlds) | 2 horror sounds (screams / dark stabs) | ZIP 6.3 MB; page states inner WAV | 4 | https://opengameart.org/sites/default/files/horror_sfx.zip | Only 2 files, but they are the genre's canonical sting; layer with a sub-thump for a boss telegraph |
| CC0 Deep Monster Roar | https://opengameart.org/content/cc0-deep-monster-roar | CC0 badge, same deed link (author trazzz123) | One deep giant-creature roar | WAV, 1.3 MB | 5 | https://opengameart.org/sites/default/files/monster_roar.wav | Made for a "giant sandworm" — reads immediately as a capital-ship/leviathan arrival stinger |
| 3 dark magic spells | https://opengameart.org/content/3-dark-magic-spells | CC0 badge, same deed link (author qubodup) | 3 synthesized dark/evil spell SFX (tags: dark, evil, demon, Sci-Fi) | 7z 823.6 KB; inner format not stated | 3 | https://opengameart.org/sites/default/files/dark_magic.7z | Fantasy-intent but purely synthetic — usable as an anomalous-energy stinger |

Notes
- A CC0-faceted OpenGameArt search for `stinger` (Sound Effect) returns **zero** results, so stingers
  must be assembled from these three plus pitched-down metal hits from section D.

### F. Dark combat music

| Name | Source URL | License / evidence | Contents | Formats | Fit | Direct download | Notes |
|---|---|---|---|---|---|---|---|
| Hunter-class Lifeform | https://opengameart.org/content/hunter-class-lifeform | CC0 badge, same deed link. Notice: "Copyright/Attribution Notice: Vitalezzz - Hunter-class Lifeform" | One loopable electronic sci-fi horror battle track | MP3 6 MB · WAV 39.4 MB · FLAC 14.6 MB | 5 | https://opengameart.org/sites/default/files/hunter-class_lifeform_1.mp3 | Best "grimdark combat" match found: electronic, loopable, alien-hunter theme. WAV available if a lossless loop is wanted |
| Boss Battle #9 [Metal] | https://opengameart.org/content/boss-battle-9-metal | CC0 badge, same deed link (author nene) | Opening part + looping part, plus MIDI | WAV 3 MB · WAV 7.5 MB · MID 17.5 KB | 4 | https://opengameart.org/sites/default/files/boss_battle_9_metal_opening.wav · https://opengameart.org/sites/default/files/boss_battle_9_metal_loop.wav | Already split into intro+loop — the exact structure Godot needs for a boss encounter. Used as a final-boss theme in at least one shipped itch.io game |
| Boss Battle #2 [Symphonic Metal] | https://opengameart.org/content/boss-battle-2-symphonic-metal | CC0 badge, same deed link (author nene) | Opening + looping parts in one ZIP; page warns the two filenames inside the archive are swapped | ZIP 11 MB (inner format not stated) | 4 | https://opengameart.org/sites/default/files/boss_battle_%232_metal_pack.zip | Symphonic-metal register is heavier than the Kenney/Kenney-era palette; audition before committing |
| Eerie Space Music | https://foozlecc.itch.io/eerie-space-music | itch.io page states: "License: (Creative Commons Zero, CC0) http://creativecommons.org/publicdomain/zero/1.0/" + `Asset license: Creative Commons Zero v1.0 Universal` | 2 eerie space songs with separated stems, one of them a faster beat intended for boss/action sequences | ZIP 449 MB; inner format not stated on page | 4 | https://foozlecc.itch.io/eerie-space-music/purchase (name your own price) | Commissioned by Foozle from Potriel; stems let a cue be re-assembled per boss phase |
| Night of the Streets [Horror/Suspense] | https://opengameart.org/content/night-of-the-streets-horrorsuspense | CC0 badge, same deed link (author nene). Page text: "I'm sorry for the poor quality. Both preview and file itself are MP3." | Horror/suspense orchestral cue written for "No more room in Hell"; MIDI also supplied | MP3 3.3 MB · MID 11 KB | 3 | https://opengameart.org/sites/default/files/Night%20of%20the%20Streets_0.mp3 | Author flags the quality himself; keep as a placeholder or re-render from the MIDI |
| Dark Shrine Loop | https://opengameart.org/content/dark-shrine-loop | CC0 badge, same deed link (author qubodup, remixing yd) | Slight remix of yd's "Shrine" as a dark loop | OGG 678.6 KB · MP3 905.7 KB · FLAC 3 MB (+ LMMS zip 13.2 KB) | 3 | https://opengameart.org/sites/default/files/qubodup-yd-DarkShrineLoop-OpenGameArt.ogg | Ritual/cult register rather than mechanical; usable for a prophet-cult faction or an anomaly tile |
| Hardwar | (see section B) | CC0 | Industrial techno loop | WAV/MP3 | 3 | https://opengameart.org/sites/default/files/hardwar.wav | Doubles as low-intensity combat/machinery music |

Notes
- Combine one of these with the existing *Fast fight / battle music (looped)* to get two combat tiers:
  fast/intense vs. slow/dreadnought.

### G. itch.io (page states CC0 in writing)

| Name | Source URL | License / evidence | Contents | Formats | Fit | Direct download | Notes |
|---|---|---|---|---|---|---|---|
| Free Audio Asset Collection (Nihilex) | https://nihil-existentia.itch.io/free-audio-asset-collection | Page states: "This is a pay-what-you-want, free collection of royalty free sounds. All of the sounds here fall under the CC0 license." and `Asset license: Creative Commons Zero v1.0 Universal` | 30+ assets in 7 downloads, including **Dark Ambient Soundscapes (6 tracks)**, **Underground Facility Ambient Pack (7 room ambiences: Armory, Cell, Hallway, Janitory, Lockers, Office, Research)**, Underground/Buried In The Noise (20 experimental-noise tracks), Lost In Misery (15), CHAOS (10 tracks), Piano Pack (10) | WAV, "mostly 48 kHz, 24-bit, stereo" (per page) | 5 | https://nihil-existentia.itch.io/free-audio-asset-collection/purchase (name your own price) | The facility pack was written for an SCP game — the closest thing found to "derelict station room tone". Zips are 242 MB (dark ambient) to 867 MB, so pull individual zips |
| Horror Sound Pack (Phlegmlee) | https://phlegmlee.itch.io/horror-sound-pack | `Asset license: Creative Commons Zero v1.0 Universal` (written on the page, links to itch.io's CC0 browse) | 5 loopable atmospheric/ominous songs + 11 SFX (jump scares, creepy footsteps, deep growling) | ZIP 86 MB; inner format not stated | 4 | https://phlegmlee.itch.io/horror-sound-pack (Download) | No CC0 sentence in the body text — the licence is the page's asset-licence field. Note that before shipping, and prefer the SFX over the songs (unspecified quality) |
| 13-Hour Ambient Soundscape Library for Games (reikidan) | https://reikidan.itch.io/13-hour-ambient-soundscape-library-for-games-cc0-royalty-free | Page states: "**License: CC0 (Public Domain).** You are free to use these tracks in any commercial or private project... No attribution, royalties, or licensing fees are required." | 14+ hours of non-directive ambient/atmospheric music in 14 "State" packages (Focus, Grounding, Cosmic…), page suggests psychological-horror/tension use | Archive.zip 949 MB; **format not stated** (the page's own format line is an unfilled placeholder) | 3 | https://reikidan.itch.io/13-hour-ambient-soundscape-library-for-games-cc0-royalty-free | Huge, meditation-oriented, generous with tags "relaxing"; treat as a long-form bed source, not a dread library. Verify format after download |

Notes
- itch.io results were admitted **only** where the page writes CC0. Sources surfaced by search but with
  CC-BY or "royalty free, no resale" terms (Crow Shade, Clement Panchout, LonePeakMusic, YourPalRob)
  were excluded without being treated as candidates.

---

## Recommendations

Priority order for a grimdark audit pass (still no downloads — this is the shortlist to audition):

1. **Sector dread bed:** *Horror Atmosphere* (single 5:23 seamless OGG) as the low layer, with
   *Ambience Pack 1 — Sci Fi Horror* cut into per-sector variations above it. Two assets cover the
   whole "derelict / hostile space" register.
2. **Inhabited-station ambience:** *Factory ambiance* + *EmptyCity* + *I swear I saw it* (all yd,
   all OGG, all with LMMS sources). Keeps the ambient voice consistent with *Space Graveyard*.
3. **Machinery:** *30 CC0 SFX loops* (11 machine loops) + *Steam boiler sound loop* +
   *Electronic device loop*, mixed as a three-layer bed. Add *Machine shutting down* and
   *Circuit breaker* as one-shot events for blackouts and power routing.
4. **Deep rumble:** *underwater or space engine rumble* (+ *deep rumble*) for the engine-room layer;
   upgrade to one *Rumbling Sound Effects* WAV only if a specific earthquake-grade hit is needed.
5. **Hull groans:** composite — *Tree Creaking* (pitched down) + *Metal Interactions* +
   *Deep Bone Crack/Break*. Budget pitch-randomisation (±10 %) and a low-pass at ~120 Hz to remove
   the "wood" character.
6. **Stingers:** *CC0 Deep Monster Roar* for boss arrivals, *Horror SFX* for scares, *rumble fx* for
   "something huge" pass-bys.
7. **Dark combat:** *Hunter-class Lifeform* as the main grimdark battle loop, *Boss Battle #9 [Metal]*
   (opening + loop) as the boss tier, *Eerie Space Music* stems if per-phase cues are wanted.
8. **Its own tier, optional:** *Dissonance Anthem* (21 min microtonal dread) for alien-artifact /
   anomaly zones, and *Nihilex* dark ambient + facility packs for room-level variation.

Practical notes for that pass:
- Convert **MP3-only** candidates to OGG before looping: Ambience Pack 1 (all 5), *underwater_engine
  .mp3* / *deep_rumble.mp3*, *Overshadow*, *Persistence*, *Abandon Hope*, *Downfall*, *Night of the
  Streets*, *Nihil* — MP3 loop points are not sample-accurate and will click or drift.
- Convert **FLAC** to WAV/OGG: *The World Fell Silent* set, *Electronic device loop*, and the FLAC
  variants of *Hunter-class Lifeform* / *Bleeding out* (if reconsidered). Godot 4 does not import FLAC.
- Budget disk: the bretbernhoft packs are 21–46 MB per WAV; *Nihilex* zips reach 867 MB. Pull the
  specific files, not the whole collections.
- Import presets: loops with `loop = true` / `loop_offset = 0`; one-shots (stingers, power-down,
  breaker) as non-looping. Verify seamlessness on the two assets that advertise it
  (*Horror Atmosphere*, *Ambience Pack 1*).
- Rebuild `ASSET_MANIFEST.json` and `CREDITS.md` after import even though CC0 requires no attribution.

## Rejected

| Asset | URL | Reason |
|---|---|---|
| The Maw | https://opengameart.org/content/the-maw | Page still shows a CC0 badge, but the file list has been replaced with: "File(s) currently unavalable due to potential licensing issues." Comments identify the foundation sample as Earthbound's "The Cave of the Past" (third-party IP). Withdrawn and legally tainted — unusable. |
| Bleeding out | https://opengameart.org/content/bleeding-out | Page carries **two** licence badges: OGA-BY 3.0 **and** CC0. Strict CC0-only rule rejects OGA-BY assets, so it is excluded even though the CC0 grant is arguably electable. (It would otherwise be a good dark ambient bed; keep it in mind only if the licence policy is ever relaxed.) |
| Sirens in Darkness | https://opengameart.org/content/sirens-in-darkness | CC0 is fine, but the tone is wrong: tagged uplifting / relax / magical / forest, "warm pads and piano", a commenter calls it "peaceful". Description also asks for credit. Not grimdark. |
| Drone2 | https://opengameart.org/content/drone2 | CC0 but the only file is `914142.mid` (3.5 KB) — no rendered audio. Would need a synthesizer pass; rejected for lack of a deliverable format. |
| `stinger` search (OpenGameArt, Sound Effect + CC0 facet) | https://opengameart.org/art-search-advanced?keys=stinger&field_art_type_tid%5B%5D=13&field_art_licenses_tid%5B%5D=4 | Returns **zero** results — there is no CC0 asset tagged as a "stinger". Documented as a real gap; worked around with the stingers in section E. |
| `creak` / `groan` Search for space-specific hull audio | (advanced searches, CC0 facet) | `creak` (Sound Effect, CC0) returns 4 results, only one of which is an actual creak (*Tree Creaking*); `groan` and other hull terms return no space-appropriate material. The category genuinely does not exist in CC0 — hence the composite build in Recommendations item 5. |

Not evaluated (deferred, not rejected) — these appeared in CC0-faceted sweeps but their pages were not
opened and their badges were not read in this pass, so they are out of scope by the strict rule:
`/content/at-the-end-of-hope`, `/content/the-9th-circle`, `/content/glutton`, `/content/its-here`,
`/content/searching`, `/content/unsolved-investigation`, `/content/ambient-soundscape`,
`/content/the-shop`, `/content/storm-siren`, `/content/creepy`, `/content/cerhern`,
`/content/haunting-chiptune-loop-void-estate`, `/content/bio-hazard-menustage`,
`/content/8-bit-infinite-darkness`, plus itch.io sources surfaced by search but
not opened (Kronbits *200 Free SFX*, Liminal Games *Free Horror SFX*, JHawk *Dungeon Music Pack*,
Stormyman *Goofy Sounds for Scary Monsters*) and Freesound CC0 items (CC0 filter exists, but downloads
require a free account and pages were not individually read).

Non-CC0 sources noted for completeness (excluded by policy, no pages opened): Pixabay (Pixabay Content
Licence, not CC0), Sonniss GDC bundles (royalty-free, not CC0), Soundimage.org (CC-BY), and itch.io
CC-BY sellers such as Crow Shade / Clement Panchout / LonePeakMusic.
