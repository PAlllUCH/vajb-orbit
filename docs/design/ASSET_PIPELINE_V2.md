# ASSET_PIPELINE_V2 — from raw renders to cut sprites

Status: **implemented** (cut stage). Supersedes the alpha handling in `staging/phase_d/reprocess.py`
and the repaired `_cuts/` set it was built to rescue.

## 1. Why this exists

The v1 pipeline rendered every sheet on a void-black background (the API's `transparent` option
was ignored because the project style block names a void background), then derived alpha locally
by keying every pixel within a colour distance of 16 of the estimated background.

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
blotches straight through every ship, prop and icon.

Two consequences set the shape of everything below. The raw renders are intact and good — this
was our post-processing, not the generator. And a matte is much easier to build from a sprite
that is already isolated, centred and named than from a 2048px sheet that still holds twenty of
them, so cut first and key later.

## 2. The pipeline

Assets live in `asset-library/`. Nothing generated lands inside the Godot project, and nothing
is restored to the project in bulk.

```
raw/                        untouched 2048px renders, one per generation run  (immutable)
 │  build_plan.py           grid + ordered names from the recovered Phase D/E/F specs
 ▼                          and the exact prompts
_sheets.json                the panel plan, with plate flags and provenance
 │  deepseek_layout.py      a vision model reads each render's arrangement
 ▼
_layout_deepseek.json       which way round the cells lie, and where a cut could pass
 │  cut_sheets.py           segment, name, centre, size
 ▼
cut/                        one file per asset: ship_bomber_front.png, icon_mineral_iron.png …
 │  build_review.py         contact sheets into _review/
 ▼
_review/cutmap_<family>.jpg  the sheet with its cut lines drawn, and its sprites
```

Run in that order; each step is idempotent and `--check`/`--only` narrow it. Every step
writes down why it decided what it decided, in the JSON it produces.

`asset-library/` sits outside the Godot project, so raw and intermediate art is never imported,
never ships in an export and never inflates `.godot/`.

## 3. The cut stage

**Count and names come from provenance, arrangement comes from the render.** How many panels a
sheet holds and what each is called comes from the Phase D/E/F `RUNS` tables recovered from git
history plus the exact prompt recorded in `_originals_manifest.json`; that is the same data the
original pass used to name the shipped files, so names cannot drift from the set the game knows.
The *arrangement* is contested: one prompt asks for "2x3 grid (three columns, two rows)" and the
next for "2x3 grid (two columns, three rows)", and some renders ignore the request outright. A
wrong guess here mis-names every icon on the sheet, so a vision model reads it off the image and
its answer is adopted only when it holds the same number of cells as the plan — no panel can
lose its name, and every disagreement is printed.

**Objects are found, never cut on a divider.** A divider placed a few pixels off slices an
object in half and leaves both halves looking plausible; the first build of this stage did
exactly that to `p2_contracts`. So the cutter masks the ink, dilates to bridge the gaps inside
one shape, drops the film grain, and gathers every piece whose centre falls in a cell. A pylon
and its beacon, a gate's two arcs and a glyph drawn in strokes all come back as one sprite.

**Every sprite of a sheet is one size, and the object is centred.** The `icons` family
additionally shares a single 512px square canvas with each icon scaled to one share of it, so a
5x4 panel becomes 20 files of one size and one visual weight. Other families keep their own
scale and are only centred, on a canvas the size of the largest object on that sheet — a ship
must not change size as it turns through its four views, and an S asteroid must stay smaller
than an L one.

**Plates pass through.** Sheets that are whole-frame layers rather than objects — backdrops,
tiling layers, menu and loading screens, full-frame vignettes, shipped `panel_*` assets — are
copied untouched. `_sheets.json` records which, and why.

**No alpha yet.** `cut/` is RGB with the background still in it. Keying operates on an isolated,
centred sprite, which is the whole point of doing it second.

## 4. What was thrown away

- The whole repaired `_cuts/` set, and `staging/_prune_backup/`, and the v1 keyed sheets except
  the seven the owner kept (now in `raw/` as `<name>__keyed.png`, marked with the keyed suffix so
  they cannot be mistaken for a pristine render or picked up by the cutter).
- `staging/assetpipe/` (the smooth-distance matte and the repair tool) wrote into that deleted
  set and is superseded by `staging/cut/`. Its measurement of the v1 damage stands as evidence
  in §1.
- Every timestamped generation folder inside `vajb-orbit/assets/`; each sheet it held is
  md5-verified in `asset-library/raw/`. `asset-library/_deleted_manifest.json` is the audit
  record. `vajb-orbit/assets/fx/` was kept: FX are RGB on void for additive blending, never
  keyed, so never damaged.

## 5. Acceptance

1. `cut/` holds one file per named panel of every non-plate sheet, and `_cuts_manifest.json`
   accounts for each one. **Met** — 510 sprites from 163 sheets, 30 of which are plates, and
   every one of the 540 files is listed in the manifest with nothing listed that is absent.
2. No sprite is a fragment of an object: each named panel that has artwork on its sheet gets a
   sprite, and `_cuts_manifest.json` lists any named panel with no artwork. **Met** — 0 named
   panels without artwork across all 163 sheets.
3. Names carry their family prefix. **Met** for every shipped name; the sheets that never
   shipped are `<prefix>_sheet_<cols>x<rows>_<stamp>__pNN`. Four files keep the game's own
   unprefixed name because the docs wire them by it: `logo_vajb_orbit` and the three
   `panel_*` atlases, whose cells are additionally cut as their 20 ICONS_SPEC §7 icons.
4. Every sprite of a sheet is one size and its object is centred. **Met** — checked over every
   sheet, and all 268 icon-family sprites are exactly 512×512.
5. The contact sheets in `_review/` show each cut line on its sheet. **Met.**
6. The headless test gate passes: `tests/headless_runner.tscn` → `[SUMMARY] passed=53 failed=0`.
   **Open** — the sets a test preloads have to be pulled into the project first.
7. `ASSET_CATALOG.md` regenerates and matches the pulled file set. **Open** — same reason.

## 6. Known open items

- **Keying is the next stage and is not written.** `cut/` is RGB on the rendered background.
  The plan is to key from an isolated sprite, where the background is the frame and the object
  is centred in it, rather than from a sheet that still holds twenty objects.
- **The project is art-less by design.** `vajb-orbit/assets/{ships,env,ui,icons}` hold nothing
  until a feature pulls what it needs, so scenes referencing those textures render blank and any
  test that preloads a missing resource will fail.
- The icon quartets (`*_16/48/96/192`), the tint set and the chrome `@2x` cuts are not
  regenerated. Their tools live in `staging/phase_f/` and are intact; they need the icon parents
  in the project first, then a reimport.
- `staging/cut/deepseek_layout.py` costs one vision call per multi-panel sheet (73 sheets,
  ~2k tokens each, 245k tokens in total) and skips sheets already answered, so a re-run only
  pays for what is missing. **`deepseek-flash` is the model on that key which actually reads an
  image**: `deepseek-v4-pro` returns the same prompt-token count with and without an attachment,
  i.e. it drops them. It reasons at length first, so the prompt asks for the JSON on the first
  line and the budget is 12k tokens; before that, answers came back empty with only reasoning.
- 18 sheets still report artwork crossing a cell line. That is informational: a cell line is a
  nominal division, an object bigger than its cell is cropped whole anyway, and the report only
  flags it so a mis-drawn sheet cannot pass unnoticed.
