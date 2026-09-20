# Vajb Orbit — Assets

**Status 2026-09-17.** Two asset families ship, with different provenance:

| Family | Files | Source | Provenance |
|---|---|---|---|
| Art (`assets/{ships,icons,env,ui,fx}/`) | 317 | AI-generated via **kie.ai** (`flare` / `gpt-image-2-5-flare-text-to-image`) — Phase B (109) + Phase D (141) + Phase E (67) | `<file>.job.json` next to every sprite + per-family `generation_log*.md` |
| Audio (`assets/audio/`) | 95 | **CC0 1.0** sources (25 downloads, 14 packs) — `AUDIO_SPEC.md` | `asset-library/ASSET_MANIFEST.json` (checksums) + `assets/audio/generation_log_audio.md` |

**Per-file index:** `docs/design/ASSET_CATALOG.md` — path, size, alpha, purpose, phase tag, and for
audio the length, channel count, loop flag and source pack. Generated from the filesystem +
`staging/audio/audio_report.json`; never hand-edited.

**Integration contract:** `docs/design/ASSET_WIRING_HANDOFF.md` — which files are still unbound,
the audio cue names that resolve today, the loop-flag set, and the consumer rules (alpha modes,
rotation-view naming, tinting, additive FX). Read it before wiring anything into a scene.

**Sourcing pipeline:** `assetmcp` is configured in `crush.json` and was used for the audio pass
(license check + download + archive extraction + manifest). Art is still generated, not sourced.
The CC0 research archive survives at `docs/assets/research/` (10 reports with URLs + license
evidence).

- AI-generated art is **not** CC0/public domain — ownership and usage terms come from the
  generator's ToS. Keep the generation log (prompt, seed, model, date) next to outputs.
- Audio **is** CC0 1.0: no attribution is required and none is claimed; the manifest and generation
  log exist for traceability, not obligation.
- The research archive also carries the reusable `assetmcp` gotchas: `subfolder` flattening to
  sanitized dirs, per-file downloads instead of `download_page_assets`, contact-sheet tool
  non-recursion, and its manifest watcher overwriting external edits.

## Audio (CC0, sourced 2026-09-17)

Layout is **flat per bus** because `AudioManager._load_cue()` resolves
`res://assets/audio/<bus>/<cue>.ogg`, then `<cue>_01.ogg` (`AUDIO_SPEC.md` §8.1):

```
vajb-orbit/assets/audio/
├── music/      6   menu, exploration, dread, combat, boss opening + loop
├── sfx/       62   weapons, impacts, shield, mining, ship, station, stingers (+ variant pools)
├── ambience/  16   space beds and station room tones (no AudioManager route yet)
└── ui/        11   click, hover, scroll, confirm, denied (+ pools)
```

Pipeline — all re-runnable, all in `staging/audio/`:

| Script | What it does |
|---|---|
| `build_audio.py` | Sources → final OGG (bit-exact for OGG sources, q5/q6 encode for WAV/FLAC/MP3 with peak normalisation to −1 dBFS and silence trimming on one-shots), loop prep + seam QC, writes `audio_report.json` and `assets/audio/generation_log_audio.md` |
| `set_loop_flags.py` | Applies the 25 loop flags to the Godot `.import` sidecars (reimport afterwards) |
| `list_cues.py` | Prints which cue names resolve to which files, so the handoff cannot drift |

Known limits: three long beds still measure a loop seam above 3 dB and need an ear-level pass
(`AUDIO_SPEC.md` §8.3); *7 Space Sounds* yields 5 cues, not the 7 the page advertises; seams were
verified numerically, never by ear.

## Derived art (locally generated, no API)

**40 icon tints — `vajb-orbit/assets/icons/tint/` (2026-09-17, Phase C).** `tools/derive_icon_tints.gd` reads every `assets/icons/icon_*_{16,48}.png`, forces `RGB = white` while keeping the alpha channel byte-identical, and writes the same filename under `icons/tint/`. Consumers tint them with theme colours at runtime (`modulate` / `set_icon_token`): inactive `text_dim`, active `text_primary`, danger `accent_danger` (ICONS_SPEC §1). The script is re-runnable and deterministic; regenerate it after any new icon batch rather than hand-editing tints. These files are derived from the AI-generated originals, so the generator-ToS note above applies to them as well.

**4 insignia edge defringe, `vajb-orbit/assets/ui/ui_insignia_{neutral,mic,ven,mmo}.png` (2026-09-18, Phase D).** `staging/phase_d/defringe_edges.py` re-keys the anti-aliased boundary band (`0 < alpha < 250`) of sprites that were keyed from a light background: each band pixel's RGB is replaced by the RGB of its nearest fully opaque pixel, located with an EDT distance transform, so the replacement colour follows the local interior. These four insignia shipped with near-white band RGB (band mean luminance 168 of 255, 61 to 62 percent of band pixels above 175) against a dark interior (opaque mean luminance 38 to 51), which read as a white halo on dark panels; `cleanup_fringe.py` misses them because it only targets opaque near-white pixels next to outer transparency, and their boundary is a wide soft band instead. The alpha channel is untouched, as are the RGB bytes of pixels with `alpha == 0` and `alpha == 255`, and the pass is idempotent: a second `--apply` changes 0 pixels and rewrites nothing. Pre-change originals are kept in `staging/phase_d/_fringe_backup/` (written once, never overwritten). The four PNGs need a reimport in the editor before the change is visible in the engine.
