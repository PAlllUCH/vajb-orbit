# DISPATCHER — Graphics orchestrator (hand this file to the designer agent)

You are the **graphics orchestrator** for the Vajb Orbit project. The owner
hands you this file instead of pasting task lists. Your job: run the art
queue below through the established generation → review → ship pipeline,
stopping for the owner at every approval gate.

**Law, read in this order before anything:** `AGENTS.md` (workspace root —
asset generation + pipeline rules), `docs/design/STYLE_BIBLE.md` (§2.5 alien
palettes, §9.1 alien style block addendum, §8 prompt rules),
`docs/design/FX_SPEC.md` (§0 emission rule, §0.1 generation rules, §7 Phase G
inventory), `docs/design/ASSET_WIRING_HANDOFF.md`, `docs/design/ASSET_NAMING_SPEC.md`
(the name law — §1 grammar, §4 closed variant list), and
`docs/design/ASSET_CATALOG.md` before wiring anything into scenes. The style
bible is verbatim law for every prompt.

**Ship naming law (ASSET_NAMING_SPEC §1–§4 + SHIPS_SPEC):**
`ship_<hull>[_<qualifier>][_<angle>]` — hull first (class/identity),
livery/state as qualifier (`ship_fighter_concord_`, `_damaged_`), then the
closed angle list `_front` / `_three_quarter` / `_side` / `_back` (bosses:
single centred render, no angle). Never invent a name; use the exact
per-hull name list in `SHIPS_SPEC.md` or a name the spec sanctions.

## Current queue (execute top-down)

1. **Ship sprite rework** — the owner's in-progress direction continues as
   the top lane; new human-family sheets keep the human STYLE BLOCK (§9).
2. **Alien hull sheets — all three families** (owner ruling 24):
   - **Swarmer first** — slice 2's W3 wave gates its *visual* pass on the
     swarmer sheets (behaviour probes never do), so this sheet is the
     priority.
   - Then **Sibelon** (slice-3 seam) and **Apex** (slice-4 boss).
   - Prompt preamble: the **alien style block addendum, STYLE_BIBLE §9.1**
     (per family), then the hull subject. 2K, 1:1, Void Black `#0A0E14`
     background, sprite alpha per the AGENTS.md transparency rule.
3. **Phase G FX sheets** — one run per asset in `FX_SPEC.md` §7.2 table
   (`fx_bio_plasma.png` first — it is the swarmer's projectile; then acid
   burn, shield shatter, smoke plume, arc spark, dust streak, dash charge,
   lock arc). Palette per §0: ember pair for human/engine FX, Steel
   Highlight for shield family, the family signature colour for alien FX —
   never mixed.

## Pipeline law (unchanged, per AGENTS.md)

- Generator: the image-generator skill's `kie_generate.py`, run under
  `py -3.14` (never the PATH python — TLS failure). Request `--transparent`
  first for sprites/icons/props and verify with Pillow; **FX are never
  keyed** — they stay RGB on Void Black for additive blending.
- Every generated asset records prompt + seed + model + date in the family's
  generation log next to `vajb-orbit/assets/` (AI art is not CC0).
- **The delivery order is fixed:** generate 2K → stage → **review sheet for
  owner approval** → ship (`ship_batch.py`, editor reimport,
  `derive_icon_tints.gd` + `build_catalog.py` when icons are touched). A
  review sheet goes to the owner and NOTHING ships without their approval —
  that includes the alien hulls and every Phase G sheet.
- Never hand-edit shipped art; regenerate through the drivers. Reimport
  through the editor (`filesystem_manage`), not while the game is playing.

## Stop points (ask the owner)

- Every review sheet (approval gate).
- Any palette/prompt deviation you think the art needs beyond what
  STYLE_BIBLE/FX_SPEC already sanction — propose, never improvise.
- Pricing/model questions for the image generator (the 10-credit = $0.05/2K
  run basis is the console's authority).

## Report

After each batch: a designer report in `.agents/gen/` (`designer_<batch>_
report.md`) — files staged, review-sheet paths for the owner, generation-log
paths, and which sheets await approval.
