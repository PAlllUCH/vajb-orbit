# ASSET_PIPELINE_V2 — generation, alpha and shipping

Status: **implemented**. Supersedes the alpha handling in `staging/phase_d/reprocess.py`.

## 1. Why this exists

The v1 pipeline rendered every sheet on a void-black background (the API's `transparent`
option was ignored because the project style block names a void background), then derived
alpha locally by keying every pixel within a colour distance of 16 of the estimated
background.

Measured against the untouched raw renders, that matte deleted **rendered artwork**:

| sheet | area keyed out | of which was artwork, not background |
|---|---|---|
| `ship_bomber` | 32,944 px | 70% |
| `ship_corvette` | 50,458 px | 62% |
| `env_asteroid` | 125,684 px | 51% |
| icon sheets | 60k–694k px | 29–76% |

The deleted pixels are not flat void: they sit at neutral grey (17, 18, 20) with real surface
texture (laplacian std 3.1–8.6), while the true background is blue-tinted (6, 10, 17) and flat
(std 1.8). A hull's own shadowed plating falls inside the threshold, so the matte punched
blotches straight through every ship, prop and icon; over a bright backdrop the sprites read
as stencils.

The raw renders are intact and good. This was our post-processing, not the generator.

## 2. The pipeline rule

Assets live in `asset-library/`. Nothing generated lands inside the Godot project, and
nothing is restored to the project in bulk.

```
generate  ─►  asset-library/<family>/<key>__raw.png      untouched API render  (immutable)
          ─►  asset-library/_cuts/<family>/<sprite>.png  repaired consumer sprites
          ─►  review sheet for owner approval
          ─►  vajb-orbit/assets/<family>/<sprite>.png    pulled on demand, + .job.json
          ─►  reimport + rebuild catalog
```

Pulling is explicit and per-feature:

```
py -3.14 staging/assetpipe/pull.py --status
py -3.14 staging/assetpipe/pull.py ships --pattern "ship_bomber_*"
py -3.14 staging/assetpipe/pull.py ui --all
```

`asset-library/` sits outside the Godot project, so raw and intermediate art is never
imported, never ships in an export and never inflates `.godot/`.

## 3. The alpha repair

Two findings shaped the implementation.

**The damage is alpha-only.** The v1 matte only ever wrote the alpha channel
(`img.convert("RGBA"); putalpha(alpha)`), so the RGB under every transparent pixel still
holds the full render. Measured on the damaged sprites, their border rings are clean
background (median distance 1–2 counts) and their enclosed transparent regions carry
textured artwork. So the repair rebuilds alpha from each sprite's own pixels and **moves no
cut boundary** — no grid inference, no re-split, no chance of a sprite ending up under the
wrong name.

**Threshold 8, not 16.** The distance map is smoothed (σ 1.5) before thresholding, which
drops background noise to roughly 1 count, so the threshold can sit close to the noise floor
while the object edge — an order of magnitude stronger — survives. Swept across five sheets,
threshold 16 leaves 15,953 px of damage on the bomber, 45,049 on the asteroid sheet and
35,807 on the station; **at 8 it is zero on all five**, and the jump gate's 817k-px aperture
still reads as legitimate at every threshold.

`staging/assetpipe/matte.py` per sprite:

1. **Background** — the *dominant* colour among the sprite's transparent pixels, not the
   median and not a border ring. Damage can cover more of the transparent area than the
   background does, but artwork spreads over hundreds of colours while the background is one
   flat colour plus speckle, so the most populated colour bucket is the background even when
   it is a minority of the area. A border ring is unusable here: a button plate fills its
   frame and a narrow hull touches the edge, so the ring is content. The estimate is
   validated (it must sit closer to the bulk of the transparent pixels than to the opaque
   ones) and the sprite is skipped rather than guessed at if it fails.
2. **Candidate mask** — per-pixel max-channel distance above the threshold.
3. **Seal and fill** — morphological closing, then `binary_fill_holes`, which establishes
   "inside the object". Closing first is what v1 lacked: a 1 px channel from a shadowed panel
   to the outside lets `fill_holes` miss the region entirely.
4. **Restore** — pixels inside the silhouette but outside the mask were deleted by the
   distance test alone. If their raw colour is further than `VOID_TOL` from the background
   they were artwork and are restored. This is what keeps a genuine aperture open without a
   per-asset allow list.
5. **Edge** — a 0.8 px Gaussian on the final mask, unchanged from v1 so nothing that F.1/F.2
   approved for edge quality regresses. Interior pixels are forced fully opaque, because
   solid art is never legitimately semi-transparent.

### QC

`alpha_metrics` reports, per sprite, the enclosed transparent area and how much of it is
damage. Damage is decided by the **texture** of the raw pixels (laplacian std; background
~1.8, hull shadow 3.0–4.8, lit hull 14.6), deliberately not by colour distance — the mask is
built from colour distance, so a colour test would simply agree with itself. A review list of
residuals is printed and recorded; every remaining item was inspected and is designed
transparency (flat stencils with white keylines and cut-outs, the logo's counters, the moon's
craters) or edge speckle on props, not damage.

## 4. What was rebuilt

Deleted, with `asset-library/_deleted_manifest.json` as the audit record and a copy of every
PNG in `staging/_prune_backup/`:

- 106 timestamped generation folders inside `vajb-orbit/assets/` (658 MB) — every sheet they
  held was already md5-verified in `asset-library/`.
- 889 keyed sprites plus their `.import` and `.job.json` sidecars, and the 556-file
  `icons/tint/` set.

Kept: `fx/` (RGB on void for additive blending, never keyed, so never damaged), `audio/`,
`fonts/`.

Rebuilt: **281 sprites repaired, 33 passed through** (never keyed, or nothing transparent to
repair). 1131 files are derived sets whose transparent RGB was overwritten and are regenerated
from their repaired parent rather than repaired: quartets via `staging/phase_f/recut_quartet.py`,
tints via `vajb-orbit/tools/derive_icon_tints.gd`, chrome `@2x` via
`staging/phase_f/chrome_2x.py`, then `apply_import_settings.py`, a reimport and
`staging/phase_d/build_catalog.py`.

## 5. Acceptance

1. `staging/assetpipe/repair.py` reports zero sprites needing review, and its residual list is
   empty or inspected-clean. **Met** — 0 review, 26 inspected-clean residuals.
2. No sprite gains an opaque rim where the raw had background: the jump gate ring and every
   single-object sheet still show clean transparency. **Met** — 817k-px aperture preserved.
3. `vajb-orbit/assets/` contains no timestamped folder and no `.import` for anything not
   pulled in. **Met.**
4. Every pulled sprite carries a `.job.json` naming its run, model, prompt and raw sheet. **Met.**
5. The headless test gate passes: `tests/headless_runner.tscn` -> `[SUMMARY] passed=53 failed=0`.
   **Open** — see §6.
6. `ASSET_CATALOG.md` regenerates and matches the pulled file set. **Open** — needs the parent
   sprites pulled back and the icon chain re-run first.

## 6. Known open items

- **The project is currently art-less by design.** `ships/`, `env/`, `ui/` and `icons/` hold
  nothing until a feature pulls what it needs, so scenes referencing those textures render
  blank and any test that preloads a missing resource will fail. Pull the set a test needs
  before running it.
- The 1131 derived icon files (quartets, tints, `@2x`) are not regenerated yet; that chain
  needs the icon parents pulled back into the project first, then an editor reimport.
- The residual QC list is a review aid, not a pass/fail gate; it has no automated threshold.
