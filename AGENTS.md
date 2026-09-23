# Vajb Orbit — Agent Operating Manual

Dark Orbit clone in Godot 4.7.2 (Forward+, D3D12, Jolt physics). Project code lives in `vajb-orbit/`; this file plus `crush.json`/`crushrc` live at the workspace root.

**Host-neutral paths.** This workspace runs on Windows and Linux, so no document here carries absolute host paths. Everything host-specific resolves from environment variables set per host in `crushrc` (plus `environment.d` on Linux): `$VAJB_WORKSPACE` (workspace root — also what `--cwd` gets), `$VAJB_PROJ` (`$VAJB_WORKSPACE/vajb-orbit`), `$GODOT_EDITOR` / `$GODOT_CONSOLE` (engine binaries), `$CRUSH_TOOLS` (crush tooling: `assetmcp`, `godot-lsp-bridge`, `mcp-legacy-shim.py`), `$KIE_GENERATE` (the `image-generator` skill's `kie_generate.py`). If a command below shows a bare variable, the real path lives only in `crushrc`. No secrets belong in any project document.

## Source of Truth

- `vajb-orbit/project.godot` — engine config. Do not hand-edit except documented keys (`editor_plugins`).
- `docs/` — design and spec documents (create as features are specced; spec before code). Full map below.
- `docs/design/ASSET_CATALOG.md` — index of every shipped file in `vajb-orbit/assets/` (path, size, alpha, purpose, Phase B/D/E, audio facts). Check it before wiring art or audio into scenes.
- `asset-library/` — **where every generated asset lives.** Search here first for any art; `vajb-orbit/assets/` holds only what a feature has actually pulled in. `raw/` is the untouched renders, `cut/` is one centred, named file per asset, `_review/` is the contact sheets; the first two plus `_dropped/` are zipped into `_archive/` (see the rule below). How to rebuild any of it, and what each generated file records, is in `asset-library/README.md`.
- This file — agent rules and commands. Read before any work.

## Documentation Map

**Phase status (2026-09-22):** every wave on the board is closed and review-verified — the nine coding waves (chrome, combat repair, weapon FX wiring, flight feel & beam polish, slice 2.5 Feel, P2-A ship slot frames, rock cleave, P2-B1 weapon fit, P2-B proper fitting panel) plus engine wave 1, slice 0 and slice 2; the universal gate reads `passed=437 failed=0`. The next engine wave is the **module-affixes wave (gameplay doc 15)**, then the AUCTION (10 §2); the graphics designer lane runs in parallel. **Live state, dispatch flow, next actions and the closure history: `.agents/gen/_state/WAVEBOARD.md` — read it first when resuming.** Root `.md` files are folded into `docs/` — only `AGENTS.md` stays at the workspace root; the `PHYSICS_SPEC.md`/`GRAPHICS_IDEAS.md` drafts are absorbed and deleted. Phase records: Phase C closed (`docs/design/PHASE_C_STATUS.md`), Phase D menu + station landed, Phase F.1/F.2 icons shipped and closed (`docs/design/ICONS_SPEC.md` §9.7–§9.8, `docs/design/UI_CHROME_ASSETS_SPEC.md` §10), P1 RPG economy code-complete, P2 (gameplay docs 08/09/10) landed through P2-A/P2-B1/P2-B proper. **2026-09-22 purge:** the executed-wave reports, briefs and evidence were removed from `.agents/gen/` (recoverable from the system trash; the last git tree carrying them is `3f5688b`) — the historical record is `MASTER_REPORT.md` plus the newest session report; `.agents/gen/` follows the folder law (see §Slice / folder law) with only state in `_state/`, templates in `_templates/`, and the fresh `slices/`/`phases/` skeleton for the next dispatch.

`docs/design/`, by role:

| Group | Files | Role |
|---|---|---|
| Visual + flow law | `STYLE_BIBLE.md`, `UI_SPEC.md`, `MENU_FLOW.md` | Single sources: palette/style, UI/theming tokens, screen inventory + flow |
| Screen specs | `MAIN_MENU_V2.md` (menu + boot/loading — the Phase-A boot/loading spec is absorbed in §17; `MAIN_MENU_SPEC.md` is superseded, pending archive), `STATION_HUB.md`, `STATION_SPEC.md`, `THEME_AUDIO_EXTENSION.md` | Contracts for shipping screens and the D3 theme/audio extension |
| Asset specs | `SHIPS_SPEC.md`, `ICONS_SPEC.md`, `ENVIRONMENT_SPEC.md`, `FX_SPEC.md`, `UI_CHROME_ASSETS_SPEC.md`, `AUDIO_SPEC.md` | Prompt + wiring source per asset family |
| Asset pipeline records | `GENERATION_PLAN.md` (Phase B), `ASSET_EXPANSION_SPEC.md` (D), `ASSET_EXPANSION_SPEC_E.md` (E), `ASSET_CATALOG.md` (generated), `ASSET_AUDIT.md` (D1 reachability audit), `ASSET_WIRING_HANDOFF.md` (integration contract) | Executed plans stay authoritative for model/price/split rules; catalog is regenerated, never hand-edited |
| Phase C records | `IMPLEMENTATION_PLAN.md` (frozen interface contract, now with Phase D and P1 amendments in §9), `PROJECT_SETTINGS_PATCH.md` (applied), `PHASE_C_STATUS.md` (closed) | The coding contract every worker codes against |

Workspace root, agent-facing (**only `AGENTS.md` remains at the root** —
the other root `.md` files moved into `docs/` on 2026-09-20):

| File | Role |
|---|---|
| `docs/gameplay/18_engine_spec.md` | The engine contract (was root `ENGINE_SPEC.md`; §2 + §2.1 the 26 owner decisions, §13 calibration incl. speed table v2, §14 build slices 0/1/2/2.5/3/4, §12 doc amendments) |
| `docs/CONTRACTS.md` | The living pinned-interface contract — every worker brief references its sections; review waves own updating it |
| `.agents/gen/_state/WAVEBOARD.md` | One-file agent state: wave statuses, queued/parked work, the enforcement protocol. Read first when resuming |
| `.agents/gen/_state/LOW_BACKLOG.md` | Open LOW findings/tickets (`T-###`); read when reviewing or fixing |
| `docs/design/CLOSEOUT_PLAN.md` / `CLEANUP_PLAN.md` | The wave-1 closeout sequence and cleanup dispositions (moved 2026-09-20) |

**Agent tooling (workspace):** `staging/verify_wave.py` (`snapshot` before / `verify --baseline <tag>` after a wave; baselines in `.agents/gen/_state/_wave_state/`), hooks `.crush/hooks/protect_archive.py` (seals the archive) and `.crush/hooks/enforce_worker_files.py` (per-worker file set via `VAJB_WORKER_FILES`), and the universal test gate `$GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200` → `[SUMMARY] passed=437 failed=0` (the live count is whatever the gate prints; zero failures is the law). The repo (`github.com/PAlllUCH/vajb-orbit`) is text-only — binary assets are gitignored; commit at every wave boundary.

`docs/gameplay/` — the RPG/economy layer: docs 01–17 plus the engine spec
(`18_engine_spec.md`, moved from the root 2026-09-20) and
`19_testing_notes.md` (the batch-2 playtest list), with
`17_coder_handoff.md` as the RPG build plan. P1 (01–05, economy core)
shipped; the historical record is `MASTER_REPORT.md` in `.agents/gen/`.

`docs/assets/research/` — 10 CC0 research + review reports (2026-09-16), the provenance archive for the audio pass; AUDIO_SPEC cites them. `asset-library/` — the CC0 audio packs downloaded via `assetmcp` plus `ASSET_MANIFEST.json`/`CREDITS.md`. `staging/` — re-runnable asset pipeline scripts (`phase_d/`, `phase_e/`, `phase_f/`, `audio/`); `_fringe_backup/` and `_preview/` are deliberate records, keep them. `.agents/gen/` — all agent work product, organized by the folder law below: `slices/<SliceID>-<slug>/` (one folder per slice; every brief, report and review lives inside its slice folder), `phases/<P##>-<slug>/` (phase manifests), `_state/` (`WAVEBOARD.md`, `LOW_BACKLOG.md`, `_wave_state/` baselines), `_templates/` (the six templates — workers copy, never edit), and the two historical records (`MASTER_REPORT.md`, the newest session report). Executed waves are purged, not kept loose — the historical record lives in `MASTER_REPORT.md` and git history; superseded slice files move to the slice folder's `_archive/` at slice close.

**Phase F (2026-09-18) — RPG/economy art layer.** Work order `docs/gameplay/16_art_design_brief.md` (P0 minerals/modules/slots, P1 miner hull + sector backdrops + gate ring + anomaly FX + arena material + hunter liveries, P2 station chrome review + faction insignia + contract/service glyphs + cargo tint table). Driver `staging/phase_f/wave_f.py`, shipping step `staging/phase_f/ship_batch.py`, review sheets from `build_p0_review.py`, `build_review_scene.py` and `build_panel_sheets.py`. The delivery order is generate 2K → stage → **review sheet for owner approval** → ship: `ship_batch.py`, editor reimport, `derive_icon_tints.gd`, `build_catalog.py`. Two deviations are recorded in `assets/<family>/generation_log_phase_f.md`: flat icon sheets pass `style-block.txt` as the **prompt preamble** rather than via `--style-file` (the style block is appended, and its painted-metal/void/ember wording deterministically beat ICONS_SPEC §5's flat framing sentence — see ICONS_SPEC §8), and the mineral sheet ships as two 5×4 panels (ore, ingot) rather than one sheet with two reads per cell.

## Engine Binaries

| Use | Binary |
|-----|--------|
| Editor (UI, LSP, MCP server) | `$GODOT_EDITOR` |
| Headless / scripted runs | `$GODOT_CONSOLE` |

Values are host-specific and live in `crushrc` (Windows: the 4.7.2 stable pair under the local tool dir; Linux: `godot` on `PATH`). Always pass `--path "$VAJB_PROJ"` (the path contains spaces on the Windows host).

- Config validation / reimport: `$GODOT_CONSOLE --headless --editor --path "$VAJB_PROJ" --quit`
- Run game headless (once a main scene exists): `$GODOT_CONSOLE --headless --path "$VAJB_PROJ"`
- Run a script: `$GODOT_CONSOLE --headless --path "$VAJB_PROJ" --script res://<script>.gd`

### Release exports

`vajb-orbit/export_presets.cfg` carries the two desktop presets (`Linux`, `Windows Desktop`: 64-bit, single-file, release templates) and excludes `addons/`, `tests/` and `tools/`, so a build handed to testers never carries the MCP plugin, the gate or the audit scripts. Export both, smoke-test the runnable one, then zip:

```bash
$GODOT_CONSOLE --headless --path "$VAJB_PROJ" --export-release "Linux" "$VAJB_WORKSPACE/builds/linux/vajb-orbit.x86_64"
$GODOT_CONSOLE --headless --path "$VAJB_PROJ" --export-release "Windows Desktop" "$VAJB_WORKSPACE/builds/windows/vajb-orbit.exe"
```

`builds/` is gitignored and stays out of the Drive mirror; shareable zips go to a dated folder beside the mirror. Export templates are the 4.7.2-stable set (`~/.local/share/godot/export_templates/4.7.2.stable/`). A release is not done until the Linux binary boots on Vulkan and exits clean (`--quit-after 400`, only the benign ObjectDB-leak warning) — the Windows binary cannot be run on the Linux host, so it is verified structurally (same embedded pack size) instead.

### Editor / LSP / godot-ai runbook

The full, verified recovery procedure (detached launch command, LSP warm-up, diagnosis cheat-sheet, godot-ai behaviour notes) lives in the `vajb-orbit-environment` skill — that file is the detailed version; this section must not duplicate it and drift. Summary: launch the editor **detached** so it survives Crush restarts (a child of Crush's background shell is killed when Crush restarts — this killed the editor once); boot takes ~30 s before the editor's LSP listens; the lazy gdscript LSP needs any `.gd` operation to start. `godot-ai` reporting *connected* proves only that the MCP server runs — `session_manage(op='list')` with `count: 0` means the editor is not running.

## GDScript LSP

`godot-lsp-bridge` (v1.3.0, on `PATH` via `crushrc`) is configured in `crush.json`. It requires **the Godot editor to be open with the project** — the language server runs on TCP 6005–6014 (auto-discovered by the bridge). Diagnostics, go-to-definition, and completions do not work headless.

## MCP Servers (crush.json)

- **godot-ai** (v4.1.0): drives the live editor. Requires the editor open with the plugin (`addons/godot_ai/`, enabled via `editor_plugins` in `project.godot`). The plugin's dock writes/verifies client config; if connection fails, open the Godot AI dock in the editor and re-run "Configure". Port pair: HTTP 8000, WS 9500.
  **Capability audit (verified end-to-end 2026-09-17, 46 tools).** Drives a full authoring loop against the open editor: scene create/save, node create/property/batch, materials+themes, script create/patch/attach with parse-error diagnostics, animation clips+presets, camera/particle/CSG/UI presets, signals, input map, autoloads, ProjectSettings, ClassDB introspection, editor+game screenshots, runtime tree/UI/property reads, `game_eval` in the running game, input injection (key/mouse/gamepad/action/frame-timed sequences), plugin/editor/game logs with stack frames, `test_run`, filesystem read/write/scan/search, run/stop, quit. Round-trip verified: cloud-free scene authoring, spawn → screenshot a lit 3D box, script rotation confirmed via `game_eval` (`ticks` advancing, 59 FPS), runtime `push_error` surfaced with `spinner.gd:12 @ _process`.
  **Gaps to plan around.** (1) All writes are refused while the game plays (`EDITOR_NOT_READY`/`EDITOR_PLAYING`) — stop first; reads and `game_*` ops still work. (2) Requires the editor running — headless is a dead end. (3) `batch_execute` takes *plugin* command names (`create_node`, `set_property`, `attach_script`), not MCP tool names; an unknown name aborts the batch and rolls back the earlier sub-commands. (4) `editor_reload_plugin` kills the session — reconnect and re-list sessions. (5) `monitors_get` returned empty with no game running. (6) `tilemap_manage`/`gridmap_manage` exist but are untested here (no TileSet/MeshLibrary in the project). (7) A few op schemas differ from intuition (`noise_texture_create` uses `width`/`height` not `size`; `set_stylebox_flat` takes `border`/`corners`, no `border_width`) — errors echo the accepted param list, so they are self-correcting. (8) Its own script diagnostics are the reliable gate; Crush's `gdscript` LSP returned empty for a scratch `.gd` with a real parse error, so do not treat `lsp_diagnostics` silence as proof of correctness. (9) Window-mode and resolution changes are **inert in a `project_run` game** (the editor-embedded view owns the window): neither `SettingsManager`'s display-mode option nor a direct `Window.mode = MODE_FULLSCREEN` changed `window.mode` (stayed 0) or `window.size` (stayed 1152×648). Validate those two settings in a standalone run with no editor open. (10) `editor_screenshot` returns its image inline and has no output path, and it downscales to `max_resolution` (default 640) — a 1 px focus ring or hairline can vanish at 640/720 but is unmistakable at 1152. `game_eval` reading the state flag (`menu_button.gd._focused`) is the reliable check, not the pixel.
- **assetmcp** (local clone at `$CRUSH_TOOLS/assetmcp`): asset search + license check + download + auto-extract. **Enabled** and pointing at `asset-library/` at the workspace root, which now holds the 25 CC0 audio packs (downloaded 2026-09-17 for the audio pass) plus `ASSET_MANIFEST.json` and `CREDITS.md`. Art is AI-generated (kie.ai), not sourced, so assetmcp's remaining role is audio sourcing and license validation; re-use it the same way if more CC0 assets are ever sourced. Venv pins `mcp<2` — re-running plain `pip install -U mcp` breaks it (FastMCP rename).

## Skills

`crush.json`/`crushrc` reference the shared Godot skill library in place (single source of truth, no copy); the two directory roots are host-specific and live in `crushrc`:

1. `<crush-main>/additional-skills/godot` → `godot-master` (routing index), `godot-best-practices`, `godot-development`, `godot-ui`
2. `<crush-main>/additional-skills/godot/godot-master` → the 96 domain subskills (two paths needed because Crush scans one level per entry)

For any Godot task: start from `godot-master` keyword routing (`skills_index.json` → reference file under `godot-master/godot-master/references/`), and follow the Layer Cake rule: signals travel UP, calls travel DOWN.

Additionally, `skills/` at the workspace root holds a project-local skill (`vajb-orbit-environment`) covering the editor/LSP/MCP runbook above — don't duplicate it here if it drifts; the skill is the detailed version.

## Host portability (Linux ↔ Windows)

The workspace is mirrored between a Windows box (workspace on the user's cloud drive, tooling under the local crush dir, interpreter `py -3.14`) and Linux (different workspace and tooling roots, interpreter `python3`). **`$VAJB_WORKSPACE` and `$CRUSH_TOOLS` name both roots — no document hardcodes either host's layout.** **`crushrc` is the live source for everything host-specific** — skills, both MCP servers, the LSP, and the PreToolUse hooks; `crush.json` keeps only host-neutral parts (`lsp`, `options.skills_paths`) plus the original Windows values renamed to `_windows_mcp_legacy` / `_windows_hooks_legacy`.

**`mcp add` / `hook add` append, they never replace.** `mcp remove` and `hook remove` in `crushrc` do not cancel entries that `crush.json` contributes — the definitions merge. Symptom: the MCP server's 25 args arrive **twice** (argc 50, the command becomes garbage and the process dies instantly as `client is closing: EOF`), and every matching tool call runs two hooks (one per definition). Never define the same server or hook in both files; if a Windows Crush predates `crushrc` support, restore the `_windows_*_legacy` blocks instead.

**The `server/discover` shim.** Crush ≥ the SEP-2575 protocol revision probes `server/discover` on every MCP connection. `godot-ai 4.1.0` hard-pins `mcp==1.29.1` and `assetmcp` needs `mcp<2` (its `mcp.server.fastmcp` import was renamed in 2.x), so neither can answer the probe and the handshake dies with `client is closing: EOF`. `tools/mcp-legacy-shim.py` answers the probe with a legacy-only version list, which makes the go-sdk client fall back to the legacy `initialize` handshake (`mcp/client.go`: "if there is no overlap, fall back to initialize"). Both servers run through it. **Drop the shim once the servers ship mcp ≥ 2.0.** Set `MCP_SHIM_LOG=<path>` to trace all shim traffic.

Linux tooling installed 2026-09-21 (all under the user tooling prefix, nothing system-wide; every location mirrored into `crushrc`): `uv`/`uvx` 0.12.17 (resolves `godot-ai==4.1.0` from PyPI), `rg` 15.2.0, `godot-lsp-bridge` 1.3.0, `assetmcp` clone with a `uv`-built venv (**pinned `mcp<2`** — `mcp>=2` breaks it). The engine and workspace variables (`$GODOT_EDITOR`, `$GODOT_CONSOLE`, `$VAJB_WORKSPACE`, `$VAJB_PROJ`) are set session-wide (`environment.d`, profile, bashrc) pointing at the 4.7.2-stable binary and this workspace. Restart Crush after changing any of this — the MCP/LSP clients and the `rg` lookup are resolved once at startup.

The project session DB was malformed (`database disk image is malformed (11)`) and got resurrected by bisync more than once; the canonical remedy is `~/.local/share/crush/tools/restore-vajborbit-config.sh`, which re-copies `crush.json`/`crushrc`, re-inserts this section, and deletes a malformed `crush.db`. `crush.db.bak-20260917` is a **verified-good** 09-17 snapshot; `crush.db.salvage-20260921.json.gz` holds the readable rows.

## Asset Generation (kie.ai)

**Phase G lane (2026-09-21).** Driver `staging/phase_g/wave_g.py` (one `RUNS` entry per render: style source, aspect, alpha, cut mode, cell plan), keying `staging/phase_g/key_new.py` (recraft over explicit paths, cache keyed by source md5 — the generator's own slug is shared across runs because every prompt opens with the same style block), shipping `staging/phase_g/ship_batch_g.py` (`review_only` runs are refused; `--review --replace` ships them once the owner approves), review pages `staging/phase_g/build_review.py`. Alien assets use `vajb-orbit/assets/style-block-alien.txt` (STYLE_BIBLE §9.1, verbatim) as the prompt preamble; human assets use `style-block.txt` the same way. `flare` never returns native alpha on this project: cut `--post-only` after keying.

**A 2x2 sheet's fourth cell is often a second front, not a rear.** The model repeats the front view in the bottom-right cell and never draws a rear — measured by silhouette IoU against the front cut: `ship_miner_back` 0.91, `ship_sibelon_back` 0.83, and the swarmer sheet's fourth cell before both were repaired (a genuine front/rear pair of a boxy hull lands near 0.74–0.78, so 0.80 is the line). `refit_panels.py` now reports any pair above that line instead of shipping it; the cure is a dedicated `*_back_single` run with the hull seen from directly behind, cut from its own render. `cells` in `wave_g.py` is the authority on how many cells a sheet contributes — `cuts` is derived from it, so a repaired sheet cannot plan its dropped view back in.

**Panel order is law: render, find the objects, cut each one, key each one, trim.** A 2K panel is not one subject and its objects do not respect the quadrant midlines, so getting either wrong ships damaged art. Measured on the first pass: panel-level `recraft/remove-background` deleted the bottom 299 px of `ship_apex_sheet`'s bottom-right hull (ink height 933 px against a keyed alpha height of 634 px), and the 2x2 grid cut truncated the two hulls whose ink starts left of x = 1024 by 50-100 px. `staging/phase_g/panels.py` finds every object (its `--detect` prints the boxes and `--page` draws them) and groups the ink into the four cells **by pixel mass inside a quadrant**, so each cell's box covers its own object whole; `staging/phase_g/refit_panels.py` runs the rest for a run id and **verifies the keyed alpha box against the ink box**, restoring an engine flame the matte trimmed as one connected component when it comes up short. Never key a panel that holds more than one object.

- Generator script: `$KIE_GENERATE` (the `image-generator` skill's `kie_generate.py`; path set per host in `crushrc`). Batch plans: `docs/design/GENERATION_PLAN.md` (Phase B, executed), `docs/design/ASSET_EXPANSION_SPEC.md` (Phase D, executed), `docs/design/ASSET_EXPANSION_SPEC_E.md` (Phase E, executed) and `docs/gameplay/16_art_design_brief.md` (Phase F). Batch drivers: `staging/phase_d/wave1.py`, `staging/phase_e/wave_e.py`, `staging/phase_f/wave_f.py`.
- **Run it under the python.org interpreter, not the PATH `python`** (on the Windows host). The PATH `python` there is Inkscape's bundled 3.12 (`C:\Program Files\Inkscape\bin\python.exe`) and ships no CA roots, so every call dies with `CERTIFICATE_VERIFY_FAILED ... unable to get local issuer certificate` (nothing is billed). Use `py -3.14` (python.org 3.14, verifies TLS, ships Pillow 12), or run Inkscape's python with `SSL_CERT_FILE` pointed at a `cacert.pem`; on Linux the interpreter is `python3`.
- Price basis: **10 credits = $0.05 per 2K run** (kie.ai console, user-verified). The script's printed estimate (30 credits, "$0.15") is a stale hint and `usage-ledger.jsonl` therefore over-reports spend 3x; the console is the authority.
- Transparency: request `--transparent` first, then verify with Pillow (RGBA with more than 10 % of pixels at alpha 0). Fall back to `--strip-bg local` for sprites/icons/props; **never** key FX, which stay RGB on void black for additive blending — **except the four the owner scoped on 2026-09-21** (`fx_smoke_plume`, `fx_acid_burn`, `fx_dust_streak`, `fx_hull_critical_vignette`), which draw with MIX and must carry alpha; the carve-out, the routes and the evidence are `docs/design/FX_SPEC.md` §0.1's amendment.
- `flare` answers `--transparent` with an opaque near-black render on this project (the style block names a void background and wins), so every master comes back opaque on a void background. `cut/` therefore ships RGB with the background in it; keying is a later pass, and for FX it is a later pass only for the four §0.1 names — the rest are never keyed. Before shipping *any* keyed FX, run `staging/cut/qc_fx_alpha.py` (box containment, enclosed transparency, inverted matte) and `staging/cut/verify_fx_alpha.py` (deepseek-chat vision, majority of three reads): the matte is the tool that ate the UI slot plates.
- `recraft/remove-background` is a rescue tool, not a default (its matte is softer and costs a call per asset). Its endpoint rejects the skill's `image_url` list with `image is required`; the accepted field is `image` as a string.
- Batch driver: `staging/phase_d/wave1.py <run-id> ...` — one paid API call per run, with alpha-keying, splitting, renaming, downscaling and log writing done locally for free. Output is staged outside `vajb-orbit/` while an editor session holds the project open, then moved into `vajb-orbit/assets/<family>/` and reimported.

## Designer lane — the output format (standing rule, owner 2026-09-21)

When the owner asks for design or planning work (a feature, an overhaul, a
rework, a wave), the deliverable is always these five pieces, in this order. The
fifth is the only thing the owner pastes anywhere.

1. **Docs first.** Amend the owning docs (`docs/gameplay/*`, `docs/design/*`) with
   the actual numbers — a dated amendment block, every new value carrying its
   reversal path, and the owner's tick list marked. Nothing downstream may invent
   a number. `docs/gameplay/18_engine_spec.md` stays owner-locked.
2. **One wave brief** in the wave's slice folder (`slices/<SliceID>-<slug>/`,
   named `<WaveID>_BRIEF.md` under the folder law): the law to read in order,
   the owner's request verbatim, what is already measured (with `file:line`), the
   pinned interface as verbatim code blocks plus the rules that fix every
   ambiguity, a worker table (`ID | role | VAJB_WORKER_FILES | deliverable`), the
   run order, the tests that move, hard rules, staged/deferred items, the owner
   tick list, and the close-out steps.
3. **One prompts file** beside it (`<WaveID>_prompts.md`): the fenced `crush
   run` blocks, one per worker ID, each with its `VAJB_WORKER_FILES`, its model
   and its report path, plus the `verify_wave.py snapshot` + commit line that runs
   before the first dispatch.
4. **Queue it twice.** The wave becomes a numbered item in the orchestrator's
   queue file (created per wave as `.agents/gen/dispatch_<lane>.md` when the
   wave is planned) and a line in
   `.agents/gen/_state/WAVEBOARD.md` §Queued, stating its position and the file
   collisions that force that order.
5. **Hand off with the short prompt.** The owner gives the orchestrator the
   queue file plus this one paragraph and nothing else:

   ```text
   Read .agents/gen/dispatch_<lane>.md and execute queue item N only — <wave name>. Brief: <brief path>. Prompts: <prompts path>. Snapshot + commit before the first dispatch, run <builder> → <reviewer>, and the fixer only if the review leaves HIGH or MED. Stop before item N+1. Close out per the brief's close-out section (gate re-run, verify_wave.py verify --baseline <tag>, WAVEBOARD update, wave-boundary commit), then report back: the measured gate count, the builder's per-deliverable numbers, the reviewer's findings by tier, and the owner ticks.
   ```

Format rules: the owner never pastes worker prompts; the brief is law (a worker
who believes a number is wrong reports it and leaves it); every wave ends in a
mandatory review, and a fixer only if that review leaves HIGH or MED; a number
the planner cannot derive from an existing doc is written **proposed** with its
reversal, never left for a worker to choose; and every wave states which existing
test numbers move and why.

**Escalation ladder (owner question 2026-09-22, ratified the same day):** findings
are sorted in three buckets, and only two of them ever pause a wave. (1) Anything
**inside a pinned acceptance** — code route, refactor shape, test mechanics, helper
design — the worker decides and proceeds, no pause. (2) Anything that would change
**a pin** — a pinned number or wording, a `VAJB_WORKER_FILES` set, the
tests-that-moves list, or any `docs/` text — escalates to the developer/designer
session: implementers never edit the yardstick they are measured by, or the
reviewer's diff loses its baseline. (3) **Taste, or anything superseding an
existing owner ruling** — escalates to the owner through the designer. A pause is
correct exactly when the finding lands in (2) or (3); the report names the bucket.

## Slice / folder law (`.agents/gen/`)

Every slice, phase, brief, report and ticket has an ID and a folder; nothing new
is written loose in `.agents/gen/`. Full law and migration rules:
`.agents/gen/_templates/README.md`.

- **IDs:** phase `P##`, code slice `S<n>` (`S0`, `S2`, `S2.5`), design-lane slice
  `D<n>`, worker `<SliceID>-<letter><##>` (one fresh letter per slice, so parallel
  workers never collide — e.g. `S2.5-V0`), tickets `T-###` global (the `L1`–`L92`
  backlog rows are grandfathered as `T-1`–`T-92`; the next free ticket is
  `T-93`), review findings `<WorkerID>/F##`. IDs are stable — never renumbered,
  only retired.
- **Folders:** `slices/<SliceID>-<slug>/` (every brief, report and review inside
  its slice folder), `phases/<P##>-<slug>/PHASE.md` (manifests), `_state/`
  (`WAVEBOARD.md`, `LOW_BACKLOG.md`, `_wave_state/`), `_templates/`, plus the
  two historical records (`MASTER_REPORT.md`, the newest session report). The
  developer creates the slice folder + `SLICE.md`
  (from `_templates/SLICE.md`) **before** the first dispatch of that slice.
- **Templates:** `SLICE`, `BRIEF`, `REPORT`, `REVIEW`, `TICKET`, `PHASE` — workers
  copy them into the slice folder as `<WorkerID>_<kind>.md`; they never edit
  `_templates/`.
- **Brief loop:** the developer fills `<WorkerID>_BRIEF.md` (task, file set,
  output contract, tier) and hands the owner a 3-line summary; the owner
  reviews/edits the paste block and pastes it into the coder/designer session;
  the coder picks the per-task models within the pinned tier.
- **Archival, not deletion:** at slice close, briefs and superseded reports move
  to the slice folder's `_archive/`; executed-wave evidence is dropped once the
  wave's numbers are recorded in the WAVEBOARD and `MASTER_REPORT.md`.

## Rules

- Update docs first, then code, then tests — never the reverse.
- Host commands: where a pipeline example below says `py -3.14`, that is the Windows python.org interpreter; on Linux the same scripts run under `python3`. `$GODOT_*`/`$VAJB_*` variables resolve per host from `crushrc`.
- **Assets live in `asset-library/`, not in the project.** Generated art flows one way: `raw/` → `cut/` → `vajb-orbit/assets/<family>/` only when a feature needs it. Never bulk-restore the project's art. **`raw/`, `cut/` and `_dropped/` are archived (2026-09-21) to `asset-library/_archive/*.zip` and are not loose**: every one of the 488 shippable cuts is in the project, so run `py -3.14 staging/cut/archive.py --restore cut` (or `raw`) before any step below that reads that tree, and `--make`/`--prune` to re-archive. `_prekey_backup/` and `_keying/` stay loose (the keying pass's reversal store and its paid answer cache). The four steps, in order:
  `py -3.14 staging/cut/build_plan.py` → re-derive `_sheets.json` from the manifests;
  `py -3.14 staging/cut/deepseek_layout.py` → ask a vision model for each sheet's arrangement;
  `py -3.14 staging/cut/cut_sheets.py` → cut every sheet (`--check` reports only, `--only <text>` narrows it);
  `py -3.14 staging/cut/build_review.py` → refresh the contact sheets in `asset-library/_review/`.
  A sheet's *arrangement* (3 columns by 2 rows, or 2 by 3) is read from the render, because the prompts contradict each other on it and a wrong guess mis-names every icon on the sheet; the *cell count and the names* come from the recovered Phase D/E/F specs, so the names cannot drift from the set the game knows. Objects are found by masking the ink, never by cutting on a divider. `_originals_manifest.json` holds every run's exact prompt and job id. Do not reintroduce `staging/phase_d/reprocess.py`'s matte: it deleted rendered artwork (measured: 51–76% of the area it keyed out was artwork, not background).
- **To find out what an asset is, read `asset-library/INDEX.md` or `asset-library/_library.json`.** All 710 files have a record: a description read off the picture itself by `py -3.14 staging/cut/tag_vision.py`, plus subject, kind, pixels, bytes, alpha share, md5, the sheet and panel it was cut from, the job and prompt that rendered that sheet, the docs and code that name it, and a `name_issue` when the file name cannot be trusted. **The description is the truth and the file name is a hint**: nine renders ignored their brief and show a spaceship where the name says "tileable layer" or "glow orb", all listed under `name_issue: content-mismatch`. Read `role` before using a file — `sprite` ships, `plate` is a whole-frame layer used as-is, `sheet` is provenance and never ships. Regenerate with `py -3.14 staging/cut/build_library.py`; never hand-edit. Naming law: `docs/design/ASSET_NAMING_SPEC.md` (applied; the tree is `cut/<family>/…`). The rename chain is `find_matches.py` → `build_naming_digest.py` → `naming_assignments.py` → `apply_names.py` (reversible through `_rename_map.json`) → `validate_names.py`, whose `--library` mode proves every name the specs and the code require is present: run it after any asset change. `pull.py` is the only thing that copies `cut/` into the project.
- **Keying is done (2026-09-20) and it is scripted, cached and reversible.** 441 sprites carry alpha; the routes, the evidence and the two known failure modes are in `asset-library/README.md` §"Keying is done". `py -3.14 staging/cut/key_assets.py --recraft [names…] [--scope ships|local]` keys through `recraft/remove-background` on kie.ai (1 credit each, resumable per sprite, 20 submissions a minute through a sliding window, answers cached under `_keying/recraft/`); `key_flat.py --check <name>…` is the region-based Python key for flat icons where the paid matte inverts, and `center_check.py --report|--apply` centres every object on its canvas with a per-file re-measure. Every original is in `_prekey_backup/` (md5-stamped manifest) and `key_assets.py --undo` puts them back. Never re-key by hand-editing a PNG.
- Worker dispatches (`crush run`) must never leave a command in the background: the shell auto-backgrounds anything past ~60 s and the worker then waits on the job forever (three workers wedged this way on 2026-09-18: W4, W6, W7). Bound every Godot run with `--quit-after`, make probes self-quit with a watchdog, and have workers redirect probe stdout to a log they read instead of waiting on the process.
- Asset regeneration is scripted, never hand-edited: art review sheets and the catalog via `py -3.14 staging/phase_d/build_review.py` and `build_catalog.py`; Phase F sheets via `py -3.14 staging/phase_f/build_p0_review.py`, `build_review_scene.py`, `build_panel_sheets.py`; audio via `py -3.14 staging/audio/build_audio.py`, then `set_loop_flags.py`, then a `filesystem_manage reimport` in the editor (editor writes are refused while the game plays — stop it first). Wiring contract for both families: `docs/design/ASSET_WIRING_HANDOFF.md`.
- Phase F.1/F.2 icon work is scripted the same way: `staging/phase_f/recut_quartet.py` (the quartet; `--fit contain` is the law, `--fit square` reproduces the pre-F.1 geometry byte for byte), `chrome_2x.py` (the `@2x` chrome cuts plus the check that proves each retained source), `apply_import_settings.py` (mipmaps on / lossless / 3D detection off for `_96`/`_192`/`@2x`), `rekey_halo.py` (luminance re-key of a white halo band), `build_f1_review.py` (quartet sheets, the 4K composite, the measured table; `--tag f2` keeps a later pass from overwriting the F.1 sheets), `stage0_reconcile.py`, `qc_f1.py` (fringe + cut measurements), `aspect_probe.py`/`legacy_probe.py` (the evidence sheets for the geometry and the legacy panel mapping). After any icon change: `tools/derive_icon_tints.gd` (headless `--script`), then the import-settings pass, a reimport, then `build_catalog.py`. Reimport through `filesystem_manage` when the editor is open; a headless `--editor --quit` reimport needs the editor closed first (a second editor instance writes the same import cache).
- Phase F.2 batch tools (`staging/phase_f/`): `wave_f.py <f2_run>` submits one paid run, `f2_backup.py` snapshots every byte the batch overwrites into `_f2_backup/`, `reband_frame.py` rebuilds the panel frame nine-slice at an exact 1/3 band, `thicken_master.py` dilates a glyph master until its 16 px cut reaches a target stroke (refusing radii that close the glyph), `silhouette_clean.py` recolours pale silhouette needles to their nearest hull colour, `plates_cut.py` cuts both the logical and the `@2x` chrome plate out of one cell, `qc_f2.py` prints the acceptance table for all of it. Two hard-won import facts: give these tools **staged** paths (a bare `ships/<file>.png` resolves to `assets/` and rewrites shipped art), and after rewriting asset bytes the editor's filesystem cache may record the new mtimes **without** importing — touch the sources and run `--headless --import`, then audit that every `.ctex` md5 matches its source (`qc_f2.py` numbers, ICONS_SPEC §9.8).
- Never edit `addons/godot_ai/` (vendored plugin); update it by replacing the folder from a new release zip and re-running the dock's Configure.
- AI-generated art (kie.ai) is **not** CC0 — record the generator's usage terms before shipping and keep a generation log (prompt/seed/model/date) next to generated assets under `vajb-orbit/assets/`.
- Audio (`vajb-orbit/assets/audio/`) is **CC0 1.0** sourced through `assetmcp`; keep new audio CC0-only (no CC-BY/OGA-BY) and let the manifest carry provenance instead of a credits screen.
- `docs/archive/` is **sealed**: no agent reads, writes, moves or lists anything inside it without the owner's explicit permission for that pass. Enforced by the PreToolUse hook `.crush/hooks/protect_archive.py` (registered in `crush.json`); the owner grants a pass by launching the session with `VAJB_ARCHIVE_OK=1`. Reference archived files by name only when the owner asked.
