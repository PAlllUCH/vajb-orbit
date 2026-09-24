# Agent Pipeline Notes

Reference detail moved out of `AGENTS.md` on 2026-09-24 so the operating
manual stays small enough to ride on every session. Nothing here is a law —
`AGENTS.md` and the owning spec hold the laws. This file holds the evidence,
the tool inventories and the executed-phase history those laws were derived
from. Read it when re-deriving a rule, auditing a pipeline, or working out why
one of them exists.

## Why this file exists (token budget)

Measured 2026-09-24 on Crush v0.96.0: a fresh session's first request cost
~69k tokens before any work. Composition:

| Component | Tokens |
|---|---|
| Crush floor (system prompt + built-in tools + env) | ~11.5k |
| godot-ai MCP (47 tools + instructions) | ~28.4k |
| Godot skill descriptions (109 injected) | ~17.3k |
| `AGENTS.md` (project context) | ~12.5k |
| assetmcp MCP (36 tools) | ~7.2k |

`AGENTS.md` is injected on every request of every session, including every
`crush run` worker, so its size is a recurring cost rather than a one-off.
Keep new material in the owning spec and link to it. The session-config guards
that keep the rest of the budget down are documented in `crushrc`'s header.

## godot-ai capability audit

Verified end-to-end 2026-09-17 against godot-ai 4.1.0 (46 tools). The tool
surface and the port pair survive in 4.2.2 (47 tools); per-tool schema sizes
were re-measured on 2026-09-24.

What it drives against the open editor: scene create/save, node
create/property/batch, materials+themes, script create/patch/attach with
parse-error diagnostics, animation clips+presets, camera/particle/CSG/UI
presets, signals, input map, autoloads, ProjectSettings, ClassDB
introspection, editor+game screenshots, runtime tree/UI/property reads,
`game_eval` in the running game, input injection (key/mouse/gamepad/action,
plus frame-timed sequences), plugin/editor/game logs with stack frames,
`test_run`, filesystem read/write/scan/search, run/stop, quit.

Round-trip verified at the time: cloud-free scene authoring, spawn →
screenshot a lit box, script rotation confirmed via `game_eval` (`ticks`
advancing, 59 FPS), and a runtime `push_error` surfaced with
`spinner.gd:12 @ _process`.

### Gaps worth remembering

1. All writes are refused while the game plays (`EDITOR_NOT_READY` /
   `EDITOR_PLAYING`) — stop first; reads and `game_*` ops still work.
2. Requires the editor running; headless is a dead end.
3. `batch_execute` takes *plugin* command names (`create_node`,
   `set_property`, `attach_script`), not MCP tool names; an unknown name
   aborts the batch and rolls back the earlier sub-commands.
4. `editor_reload_plugin` kills the session by design (the transport drops) —
   reload through the dock instead.
5. `monitors_get` returned empty with no game running.
6. A few op schemas differ from intuition (`noise_texture_create` uses
   `width`/`height` not `size`; `set_stylebox_flat` takes `border`/`corners`,
   no `border_width`) — errors echo the accepted param list, so they are
   self-correcting.
7. Its own script diagnostics are the reliable gate. Crush's `gdscript` LSP
   returned empty for a scratch `.gd` with a real parse error, so silence from
   `lsp_diagnostics` is not proof of correctness.
8. Window-mode and resolution changes are **inert in a `project_run` game**
   (the editor-embedded view owns the window): neither `SettingsManager`'s
   display-mode option nor a direct `Window.mode = MODE_FULLSCREEN` changed
   `window.mode` (stayed 0) or `window.size` (stayed 1152×648). Validate those
   two settings in a standalone run with no editor open.
9. `editor_screenshot` returns its image inline, has no output path, and
   downscales to `max_resolution` (default 640): a 1 px focus ring or hairline
   can vanish at 640/720 but is unmistakable at 1152. Reading the state flag
   through `game_eval` (e.g. `menu_button.gd._focused`) is the reliable check,
   not the pixel.
10. A domain excluded with `--exclude-domains` whose set differs from an
    already-running shared backend fails the connection rather than
    reconfiguring it — restart the editor's backend after changing the set.
    Crush-side `--disabled-tools` has no such coupling: it filters the tool
    list after the connection is up.

## Asset pipeline history

### Phase status (2026-09-22)

Every wave on the board was closed and review-verified at that point: the nine
coding waves (chrome, combat repair, weapon FX wiring, flight feel & beam
polish, slice 2.5 Feel, P2-A ship slot frames, rock cleave, P2-B1 weapon fit,
P2-B proper fitting panel) plus engine wave 1, slice 0 and slice 2, with the
universal gate reading `passed=437 failed=0`. Phase records: Phase C closed
(`docs/design/PHASE_C_STATUS.md`), Phase D menu + station landed, Phase F.1/F.2
icons shipped and closed (`docs/design/ICONS_SPEC.md` §9.7–§9.8,
`docs/design/UI_CHROME_ASSETS_SPEC.md` §10), P1 RPG economy code-complete, P2
(gameplay docs 08/09/10) landed through P2-A/P2-B1/P2-B proper. Root `.md`
files were folded into `docs/` so only `AGENTS.md` stays at the workspace root.

**2026-09-22 purge.** The executed-wave reports, briefs and evidence were
removed from `.agents/gen/` (recoverable from the system trash; the last git
tree carrying them is `3f5688b`). The historical record is
`.agents/gen/MASTER_REPORT.md` plus the newest session report.

### Phase F — RPG/economy art layer (2026-09-18)

Work order `docs/gameplay/16_art_design_brief.md`: P0 minerals/modules/slots,
P1 miner hull + sector backdrops + gate ring + anomaly FX + arena material +
hunter liveries, P2 station chrome review + faction insignia + contract/service
glyphs + cargo tint table. Driver `staging/phase_f/wave_f.py`, shipping step
`staging/phase_f/ship_batch.py`, review sheets from `build_p0_review.py`,
`build_review_scene.py` and `build_panel_sheets.py`. Delivery order: generate
2K → stage → **review sheet for owner approval** → ship (`ship_batch.py`, editor
reimport, `derive_icon_tints.gd`, `build_catalog.py`).

Two deviations are recorded in `assets/<family>/generation_log_phase_f.md`:
flat icon sheets pass `style-block.txt` as the **prompt preamble** rather than
via `--style-file` (the style block is appended, and its painted-metal/void/
ember wording deterministically beat ICONS_SPEC §5's flat framing sentence —
see ICONS_SPEC §8), and the mineral sheet ships as two 5×4 panels (ore, ingot)
rather than one sheet with two reads per cell.

### Phase G lane (2026-09-21)

Driver `staging/phase_g/wave_g.py` (one `RUNS` entry per render: style source,
aspect, alpha, cut mode, cell plan), keying `staging/phase_g/key_new.py`
(recraft over explicit paths, cache keyed by source md5 — the generator's own
slug is shared across runs because every prompt opens with the same style
block), shipping `staging/phase_g/ship_batch_g.py` (`review_only` runs are
refused; `--review --replace` ships them once the owner approves), review pages
`staging/phase_g/build_review.py`. Alien assets use
`vajb-orbit/assets/style-block-alien.txt` (STYLE_BIBLE §9.1, verbatim) as the
prompt preamble; human assets use `style-block.txt` the same way. `flare` never
returns native alpha on this project: cut `--post-only` after keying.

**A 2x2 sheet's fourth cell is often a second front, not a rear.** The model
repeats the front view in the bottom-right cell and never draws a rear —
measured by silhouette IoU against the front cut: `ship_miner_back` 0.91,
`ship_sibelon_back` 0.83, and the swarmer sheet's fourth cell before both were
repaired (a genuine front/rear pair of a boxy hull lands near 0.74–0.78, so
0.80 is the line). `refit_panels.py` reports any pair above that line instead
of shipping it; the cure is a dedicated `*_back_single` run with the hull seen
from directly behind, cut from its own render. `cells` in `wave_g.py` is the
authority on how many cells a sheet contributes — `cuts` is derived from it, so
a repaired sheet cannot plan its dropped view back in.

**Panel evidence.** Panel-level `recraft/remove-background` deleted the bottom
299 px of `ship_apex_sheet`'s bottom-right hull (ink height 933 px against a
keyed alpha height of 634 px), and a naive 2x2 grid cut truncated the two hulls
whose ink starts left of x = 1024 by 50-100 px. `staging/phase_g/panels.py`
finds every object (`--detect` prints the boxes, `--page` draws them) and groups
the ink into the four cells **by pixel mass inside a quadrant**, so each cell's
box covers its own object whole; `staging/phase_g/refit_panels.py` runs the rest
for a run id and **verifies the keyed alpha box against the ink box**,
restoring an engine flame the matte trimmed as one connected component when it
comes up short.

### Batch drivers and plans

Generator script `$KIE_GENERATE` (the `image-generator` skill's
`kie_generate.py`). Batch plans: `docs/design/GENERATION_PLAN.md` (Phase B,
executed), `docs/design/ASSET_EXPANSION_SPEC.md` (D, executed),
`docs/design/ASSET_EXPANSION_SPEC_E.md` (E, executed),
`docs/gameplay/16_art_design_brief.md` (F). Drivers:
`staging/phase_d/wave1.py`, `staging/phase_e/wave_e.py`,
`staging/phase_f/wave_f.py`, `staging/phase_g/wave_g.py`. A driver run is one
paid API call with alpha-keying, splitting, renaming, downscaling and log
writing done locally for free; output is staged outside `vajb-orbit/` while an
editor session holds the project open, then moved into
`vajb-orbit/assets/<family>/` and reimported.

### Keying (2026-09-20)

441 sprites carry alpha. The routes, the evidence and the two known failure
modes are in `asset-library/README.md` §"Keying is done". `key_assets.py
--recraft` keys through `recraft/remove-background` on kie.ai (1 credit each,
resumable per sprite, 20 submissions a minute through a sliding window, answers
cached under `_keying/recraft/`); `key_flat.py --check <name>…` is the
region-based Python key for flat icons where the paid matte inverts;
`center_check.py --report|--apply` centres every object on its canvas with a
per-file re-measure. Every original is in `_prekey_backup/` (md5-stamped
manifest) and `key_assets.py --undo` puts them back.

`staging/phase_d/reprocess.py`'s matte must never come back: it deleted
rendered artwork (measured: 51–76% of the area it keyed out was artwork, not
background).

## Icon work — Phase F.1/F.2 tool inventory

`staging/phase_f/`:

- `recut_quartet.py` — the quartet; `--fit contain` is the law, `--fit square`
  reproduces the pre-F.1 geometry byte for byte.
- `chrome_2x.py` — the `@2x` chrome cuts plus the check that proves each
  retained source.
- `apply_import_settings.py` — mipmaps on / lossless / 3D detection off for
  `_96`/`_192`/`@2x`.
- `rekey_halo.py` — luminance re-key of a white halo band.
- `build_f1_review.py` — quartet sheets, the 4K composite, the measured table;
  `--tag f2` keeps a later pass from overwriting the F.1 sheets.
- `stage0_reconcile.py`, `qc_f1.py` (fringe + cut measurements),
  `aspect_probe.py` / `legacy_probe.py` (evidence sheets for the geometry and
  the legacy panel mapping).
- `wave_f.py <f2_run>` (one paid run), `f2_backup.py` (snapshots every byte the
  batch overwrites into `_f2_backup/`), `reband_frame.py` (panel frame
  nine-slice at an exact 1/3 band), `thicken_master.py` (dilates a glyph master
  until its 16 px cut reaches a target stroke, refusing radii that close the
  glyph), `silhouette_clean.py` (recolours pale silhouette needles to their
  nearest hull colour), `plates_cut.py` (cuts both the logical and the `@2x`
  chrome plate out of one cell), `qc_f2.py` (the acceptance table for all of
  it).

Two hard-won import facts: give these tools **staged** paths (a bare
`ships/<file>.png` resolves to `assets/` and rewrites shipped art), and after
rewriting asset bytes the editor's filesystem cache may record the new mtimes
**without** importing — touch the sources and run `--headless --import`, then
audit that every `.ctex` md5 matches its source (`qc_f2.py` numbers,
ICONS_SPEC §9.8).

## Session DB recovery

The project session DB was malformed (`database disk image is malformed (11)`)
and got resurrected by bisync more than once. The canonical remedy is
`~/.local/share/crush/tools/restore-vajborbit-config.sh`, which re-copies
`crush.json`/`crushrc`, re-inserts the host-portability section, and deletes a
malformed `crush.db`. `crush.db.bak-20260917` is a **verified-good** 09-17
snapshot; `crush.db.salvage-20260921.json.gz` holds the readable rows.

## Linux tooling install (2026-09-21)

All under the user tooling prefix, nothing system-wide; every location mirrored
into `crushrc`: `uv`/`uvx` 0.12.17 (resolves `godot-ai` from PyPI), `rg` 15.2.0,
`godot-lsp-bridge` 1.3.0, and the `assetmcp` clone with a `uv`-built venv
(**pinned `mcp<2`** — `mcp>=2` breaks it). The engine and workspace variables
(`$GODOT_EDITOR`, `$GODOT_CONSOLE`, `$VAJB_WORKSPACE`, `$VAJB_PROJ`) are set
session-wide (`environment.d`, profile, bashrc) pointing at the 4.7.2-stable
binary and this workspace. Restart Crush after changing any of this — the
MCP/LSP clients and the `rg` lookup are resolved once at startup.
