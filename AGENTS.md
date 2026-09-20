# Vajb Orbit — Agent Operating Manual

Dark Orbit clone in Godot 4.7.2 (Forward+, D3D12, Jolt physics). Project code lives in `vajb-orbit/`; this file plus `crush.json` live at the workspace root.

## Source of Truth

- `vajb-orbit/project.godot` — engine config. Do not hand-edit except documented keys (`editor_plugins`).
- `docs/` — design and spec documents (create as features are specced; spec before code). Full map below.
- `docs/design/ASSET_CATALOG.md` — index of every shipped file in `vajb-orbit/assets/` (path, size, alpha, purpose, Phase B/D/E, audio facts). Check it before wiring art or audio into scenes.
- This file — agent rules and commands. Read before any work.

## Documentation Map

**Phase status (2026-09-18):** Phase C closed (`docs/design/PHASE_C_STATUS.md` — code-complete, re-reviewed clean). Phase D menu + station implementation landed (M1, S1, S2; reports in `.agents/gen/`; live S2 verification and the Wave-4 review remain outstanding per `CODING_REPORT.md` §7). **Phase P1 of the RPG layer (gameplay docs 01–05) is code-complete**: catalogues, exchange, refinery, repairs, the one world clock, save v2 migration, the REFINERY/EXCHANGE/REPAIRS station panels and a 53-test headless suite — evidence and open items in `.agents/gen/p1_report.md`; owner sign-off on the `STATION_HUB.md` P1 amendments is pending. P2 (08/09/10) is next. The mockups `ui/screens/_mockup_main_menu.tscn` and `_mockup_station.tscn` are deleted when their verification close-out lands (IMPLEMENTATION_PLAN §9.6). **Phase F.1 + F.2 (icon resolution + integrity) are shipped and closed**: the icon quartet `_{16,48,96,192}` is cut contain-fit for all 139 families, the tint set is 556, the four outline glyphs carry the heavy 16 px band, and the F.2 batch closed every F.1 open item (frame band = nine-slice margin, clean drone-swarm edges, ice-moon value) plus the last four chrome `@2x` cuts. Both records, with every measured number and the reversal paths, are in `docs/design/ICONS_SPEC.md` §9.7–§9.8 and `docs/design/UI_CHROME_ASSETS_SPEC.md` §10.

`docs/design/`, by role:

| Group | Files | Role |
|---|---|---|
| Visual + flow law | `STYLE_BIBLE.md`, `UI_SPEC.md`, `MENU_FLOW.md` | Single sources: palette/style, UI/theming tokens, screen inventory + flow |
| Screen specs | `MAIN_MENU_SPEC.md` (boot/loading; menu layout superseded by v2), `MAIN_MENU_V2.md`, `STATION_HUB.md`, `STATION_SPEC.md`, `THEME_AUDIO_EXTENSION.md` | Contracts for shipping screens and the D3 theme/audio extension |
| Asset specs | `SHIPS_SPEC.md`, `ICONS_SPEC.md`, `ENVIRONMENT_SPEC.md`, `FX_SPEC.md`, `UI_CHROME_ASSETS_SPEC.md`, `AUDIO_SPEC.md` | Prompt + wiring source per asset family |
| Asset pipeline records | `GENERATION_PLAN.md` (Phase B), `ASSET_EXPANSION_SPEC.md` (D), `ASSET_EXPANSION_SPEC_E.md` (E), `ASSET_CATALOG.md` (generated), `ASSET_AUDIT.md` (D1 reachability audit), `ASSET_WIRING_HANDOFF.md` (integration contract) | Executed plans stay authoritative for model/price/split rules; catalog is regenerated, never hand-edited |
| Phase C records | `IMPLEMENTATION_PLAN.md` (frozen interface contract, now with Phase D and P1 amendments in §9), `PROJECT_SETTINGS_PATCH.md` (applied), `PHASE_C_STATUS.md` (closed) | The coding contract every worker codes against |

`docs/gameplay/` — the RPG/economy layer: docs 01–17, with `17_coder_handoff.md` as its build plan. P1 (01–05, economy core) shipped; evidence and open items in `.agents/gen/p1_report.md`.

`docs/assets/research/` — 10 CC0 research + review reports (2026-09-16), the provenance archive for the audio pass; AUDIO_SPEC cites them. `asset-library/` — the CC0 audio packs downloaded via `assetmcp` plus `ASSET_MANIFEST.json`/`CREDITS.md`. `staging/` — re-runnable asset pipeline scripts (`phase_d/`, `phase_e/`, `phase_f/`, `audio/`); `_fringe_backup/` and `_preview/` are deliberate records, keep them. `.agents/gen/` — worker briefs and reports; `*_report.md` files are the on-disk evidence chain cited by the docs above (review reports, `d1`–`d6`), `headless_sweep.log` is Phase C's headless-run evidence, `previews/` holds the owner-approved screen renders. Executed task briefs are deleted after their phase closes.

**Phase F (2026-09-18) — RPG/economy art layer.** Work order `docs/gameplay/16_art_design_brief.md` (P0 minerals/modules/slots, P1 miner hull + sector backdrops + gate ring + anomaly FX + arena material + hunter liveries, P2 station chrome review + faction insignia + contract/service glyphs + cargo tint table). Driver `staging/phase_f/wave_f.py`, shipping step `staging/phase_f/ship_batch.py`, review sheets from `build_p0_review.py`, `build_review_scene.py` and `build_panel_sheets.py`. The delivery order is generate 2K → stage → **review sheet for owner approval** → ship: `ship_batch.py`, editor reimport, `derive_icon_tints.gd`, `build_catalog.py`. Two deviations are recorded in `assets/<family>/generation_log_phase_f.md`: flat icon sheets pass `style-block.txt` as the **prompt preamble** rather than via `--style-file` (the style block is appended, and its painted-metal/void/ember wording deterministically beat ICONS_SPEC §5's flat framing sentence — see ICONS_SPEC §8), and the mineral sheet ships as two 5×4 panels (ore, ingot) rather than one sheet with two reads per cell.

## Engine Binaries

| Use | Binary |
|-----|--------|
| Editor (UI, LSP, MCP server) | `C:\Godot_4_7_2\Godot_v4.7.2-stable_win64.exe` |
| Headless / scripted runs | `C:\Godot_4_7_2\Godot_v4.7.2-stable_win64_console.exe` |

Always pass `--path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit"` (path contains spaces).

- Config validation / reimport: `..._console.exe --headless --editor --path <proj> --quit`
- Run game headless (once a main scene exists): `..._console.exe --headless --path <proj>`
- Run a script: `..._console.exe --headless --path <proj> --script res://<script>.gd`

### Launching the editor (runbook — verified 2026-09-16)

Launch it **detached** so it survives Crush restarts (a child of Crush's background shell is killed when Crush restarts — this killed the editor once):

```powershell
powershell -Command "Start-Process -FilePath 'C:\Godot_4_7_2\Godot_v4.7.2-stable_win64.exe' -WorkingDirectory 'G:\Mój dysk\Projekty\Vajb Orbit\vajb-orbit' -ArgumentList '--editor'"
```

No `--path` needed: Godot picks up `project.godot` from the working directory. Pitfalls that produced a silently dead editor:

- `Start-Process -ArgumentList '--path','G:/Mój dysk/...'` — PowerShell joins args **unquoted**, the space breaks `--path`, Godot exits instantly.
- `cmd /c start ...` from this shell — swallowed by clink, nothing launches.

Boot takes ~30 s before the editor's LSP starts listening. Verify with:

```powershell
powershell -Command "Test-NetConnection 127.0.0.1 -Port 6005 -InformationLevel Quiet"   # editor LSP
```

### If godot-ai/LSP appear dead

- `godot-ai` reports **connected** as soon as the MCP server runs — it owns ports 8000/9500 itself. "Connected" proves nothing; the real check is `session_manage(op='list')` → `count: 0` means **the editor is not running**.
- LSP failure signature: bridge retries `127.0.0.1:6005` with `os error 10061` for 300 s, then init times out.
- Fix: launch the editor detached (command above), wait for port 6005, then warm the LSP by touching any `.gd` file and calling LSP diagnostics (Crush starts the LSP lazily; with zero `.gd` files in the project it stays `not_started`). Confirm `godot-lsp-bridge doctor` passes.
- Editor runs two LSP listeners (6005 + 6006, same PID); the bridge auto-picks the lowest port. Harmless.
- The legacy `godot` MCP in the **global** `crush.json` is intentionally `disabled: true` (superseded by godot-ai, and its `GODOT_PATH` is broken). Leave it off. Verified 2026-09-17: `@coding-solo/godot-mcp` v0.1.1 (MIT, MCP SDK 0.6.0, ~13 tools) with `GODOT_PATH` = `C:\Users\Kamil\Downloads\Godot_v4.7.1-stable_win64.exe\...` — that directory does not exist (Downloads holds only v4.7.2). It is a CLI/headless driver that spawns Godot and writes `.tscn` text, so it can neither see nor drive the open editor; no reason to revive it.

## GDScript LSP

`godot-lsp-bridge` (v1.3.0, `C:\Users\Kamil\AppData\Local\Programs\godot-lsp-bridge\bin\`) is configured in `crush.json`. It requires **the Godot editor to be open with the project** — the language server runs on TCP 6005–6014 (auto-discovered by the bridge). Diagnostics, go-to-definition, and completions do not work headless.

## MCP Servers (crush.json)

- **godot-ai** (v4.1.0): drives the live editor. Requires the editor open with the plugin (`addons/godot_ai/`, enabled via `editor_plugins` in `project.godot`). The plugin's dock writes/verifies client config; if connection fails, open the Godot AI dock in the editor and re-run "Configure". Port pair: HTTP 8000, WS 9500.
  **Capability audit (verified end-to-end 2026-09-17, 46 tools).** Drives a full authoring loop against the open editor: scene create/save, node create/property/batch, materials+themes, script create/patch/attach with parse-error diagnostics, animation clips+presets, camera/particle/CSG/UI presets, signals, input map, autoloads, ProjectSettings, ClassDB introspection, editor+game screenshots, runtime tree/UI/property reads, `game_eval` in the running game, input injection (key/mouse/gamepad/action/frame-timed sequences), plugin/editor/game logs with stack frames, `test_run`, filesystem read/write/scan/search, run/stop, quit. Round-trip verified: cloud-free scene authoring, spawn → screenshot a lit 3D box, script rotation confirmed via `game_eval` (`ticks` advancing, 59 FPS), runtime `push_error` surfaced with `spinner.gd:12 @ _process`.
  **Gaps to plan around.** (1) All writes are refused while the game plays (`EDITOR_NOT_READY`/`EDITOR_PLAYING`) — stop first; reads and `game_*` ops still work. (2) Requires the editor running — headless is a dead end. (3) `batch_execute` takes *plugin* command names (`create_node`, `set_property`, `attach_script`), not MCP tool names; an unknown name aborts the batch and rolls back the earlier sub-commands. (4) `editor_reload_plugin` kills the session — reconnect and re-list sessions. (5) `monitors_get` returned empty with no game running. (6) `tilemap_manage`/`gridmap_manage` exist but are untested here (no TileSet/MeshLibrary in the project). (7) A few op schemas differ from intuition (`noise_texture_create` uses `width`/`height` not `size`; `set_stylebox_flat` takes `border`/`corners`, no `border_width`) — errors echo the accepted param list, so they are self-correcting. (8) Its own script diagnostics are the reliable gate; Crush's `gdscript` LSP returned empty for a scratch `.gd` with a real parse error, so do not treat `lsp_diagnostics` silence as proof of correctness. (9) Window-mode and resolution changes are **inert in a `project_run` game** (the editor-embedded view owns the window): neither `SettingsManager`'s display-mode option nor a direct `Window.mode = MODE_FULLSCREEN` changed `window.mode` (stayed 0) or `window.size` (stayed 1152×648). Validate those two settings in a standalone run with no editor open. (10) `editor_screenshot` returns its image inline and has no output path, and it downscales to `max_resolution` (default 640) — a 1 px focus ring or hairline can vanish at 640/720 but is unmistakable at 1152. `game_eval` reading the state flag (`menu_button.gd._focused`) is the reliable check, not the pixel.
- **assetmcp** (local clone at `C:\Users\Kamil\AppData\Local\crush\tools\assetmcp`): asset search + license check + download + auto-extract. **Enabled** and pointing at `asset-library/` at the workspace root, which now holds the 25 CC0 audio packs (downloaded 2026-09-17 for the audio pass) plus `ASSET_MANIFEST.json` and `CREDITS.md`. Art is AI-generated (kie.ai), not sourced, so assetmcp's remaining role is audio sourcing and license validation; re-use it the same way if more CC0 assets are ever sourced. Venv pins `mcp<2` — re-running plain `pip install -U mcp` breaks it (FastMCP rename).

## Skills

`crush.json` references the shared Godot skill library in place (single source of truth, no copy):

1. `G:/Mój dysk/Projekty/crush-main/additional-skills/godot` → `godot-master` (routing index), `godot-best-practices`, `godot-development`, `godot-ui`
2. `G:/Mój dysk/Projekty/crush-main/additional-skills/godot/godot-master` → the 96 domain subskills (two paths needed because Crush scans one level per entry)

For any Godot task: start from `godot-master` keyword routing (`skills_index.json` → reference file under `godot-master/godot-master/references/`), and follow the Layer Cake rule: signals travel UP, calls travel DOWN.

Additionally, `skills/` at the workspace root holds a project-local skill (`vajb-orbit-environment`) covering the editor/LSP/MCP runbook above — don't duplicate it here if it drifts; the skill is the detailed version.

## Asset Generation (kie.ai)

- Generator script: `C:/Users/Kamil/AppData/Local/crush/skills/image-generator/scripts/kie_generate.py`. Batch plans: `docs/design/GENERATION_PLAN.md` (Phase B, executed), `docs/design/ASSET_EXPANSION_SPEC.md` (Phase D, executed), `docs/design/ASSET_EXPANSION_SPEC_E.md` (Phase E, executed) and `docs/gameplay/16_art_design_brief.md` (Phase F). Batch drivers: `staging/phase_d/wave1.py`, `staging/phase_e/wave_e.py`, `staging/phase_f/wave_f.py`.
- **Run it under the python.org interpreter, not the PATH `python`.** The PATH `python` is Inkscape's bundled 3.12 (`C:\Program Files\Inkscape\bin\python.exe`) and ships no CA roots, so every call dies with `CERTIFICATE_VERIFY_FAILED ... unable to get local issuer certificate` (nothing is billed). Use `py -3.14` (python.org 3.14, verifies TLS, ships Pillow 12), or run Inkscape's python with `SSL_CERT_FILE` pointed at a `cacert.pem`.
- Price basis: **10 credits = $0.05 per 2K run** (kie.ai console, user-verified). The script's printed estimate (30 credits, "$0.15") is a stale hint and `usage-ledger.jsonl` therefore over-reports spend 3x; the console is the authority.
- Transparency: request `--transparent` first, then verify with Pillow (RGBA with more than 10 % of pixels at alpha 0). Fall back to `--strip-bg local` for sprites/icons/props; **never** key FX, which stay RGB on void black for additive blending.
- `flare` answers `--transparent` with an opaque near-black render on this project (the style block names a void background and wins), so sprite alpha is derived locally by `staging/phase_d/reprocess.py`; FX are never keyed.
- `recraft/remove-background` is a rescue tool, not a default (its matte is softer and costs a call per asset). Its endpoint rejects the skill's `image_url` list with `image is required`; the accepted field is `image` as a string.
- Batch driver: `staging/phase_d/wave1.py <run-id> ...` — one paid API call per run, with alpha-keying, splitting, renaming, downscaling and log writing done locally for free. Output is staged outside `vajb-orbit/` while an editor session holds the project open, then moved into `vajb-orbit/assets/<family>/` and reimported.

## Rules

- Update docs first, then code, then tests — never the reverse.
- Worker dispatches (`crush run`) must never leave a command in the background: the shell auto-backgrounds anything past ~60 s and the worker then waits on the job forever (three workers wedged this way on 2026-09-18: W4, W6, W7). Bound every Godot run with `--quit-after`, make probes self-quit with a watchdog, and have workers redirect probe stdout to a log they read instead of waiting on the process.
- Asset regeneration is scripted, never hand-edited: art review sheets and the catalog via `py -3.14 staging/phase_d/build_review.py` and `build_catalog.py`; Phase F sheets via `py -3.14 staging/phase_f/build_p0_review.py`, `build_review_scene.py`, `build_panel_sheets.py`; audio via `py -3.14 staging/audio/build_audio.py`, then `set_loop_flags.py`, then a `filesystem_manage reimport` in the editor (editor writes are refused while the game plays — stop it first). Wiring contract for both families: `docs/design/ASSET_WIRING_HANDOFF.md`.
- Phase F.1/F.2 icon work is scripted the same way: `staging/phase_f/recut_quartet.py` (the quartet; `--fit contain` is the law, `--fit square` reproduces the pre-F.1 geometry byte for byte), `chrome_2x.py` (the `@2x` chrome cuts plus the check that proves each retained source), `apply_import_settings.py` (mipmaps on / lossless / 3D detection off for `_96`/`_192`/`@2x`), `rekey_halo.py` (luminance re-key of a white halo band), `build_f1_review.py` (quartet sheets, the 4K composite, the measured table; `--tag f2` keeps a later pass from overwriting the F.1 sheets), `stage0_reconcile.py`, `qc_f1.py` (fringe + cut measurements), `aspect_probe.py`/`legacy_probe.py` (the evidence sheets for the geometry and the legacy panel mapping). After any icon change: `tools/derive_icon_tints.gd` (headless `--script`), then the import-settings pass, a reimport, then `build_catalog.py`. Reimport through `filesystem_manage` when the editor is open; a headless `--editor --quit` reimport needs the editor closed first (a second editor instance writes the same import cache).
- Phase F.2 batch tools (`staging/phase_f/`): `wave_f.py <f2_run>` submits one paid run, `f2_backup.py` snapshots every byte the batch overwrites into `_f2_backup/`, `reband_frame.py` rebuilds the panel frame nine-slice at an exact 1/3 band, `thicken_master.py` dilates a glyph master until its 16 px cut reaches a target stroke (refusing radii that close the glyph), `silhouette_clean.py` recolours pale silhouette needles to their nearest hull colour, `plates_cut.py` cuts both the logical and the `@2x` chrome plate out of one cell, `qc_f2.py` prints the acceptance table for all of it. Two hard-won import facts: give these tools **staged** paths (a bare `ships/<file>.png` resolves to `assets/` and rewrites shipped art), and after rewriting asset bytes the editor's filesystem cache may record the new mtimes **without** importing — touch the sources and run `--headless --import`, then audit that every `.ctex` md5 matches its source (`qc_f2.py` numbers, ICONS_SPEC §9.8).
- Never edit `addons/godot_ai/` (vendored plugin); update it by replacing the folder from a new release zip and re-running the dock's Configure.
- AI-generated art (kie.ai) is **not** CC0 — record the generator's usage terms before shipping and keep a generation log (prompt/seed/model/date) next to generated assets under `vajb-orbit/assets/`.
- Audio (`vajb-orbit/assets/audio/`) is **CC0 1.0** sourced through `assetmcp`; keep new audio CC0-only (no CC-BY/OGA-BY) and let the manifest carry provenance instead of a credits screen.
- `docs/archive/` is **sealed**: no agent reads, writes, moves or lists anything inside it without the owner's explicit permission for that pass. Enforced by the PreToolUse hook `.crush/hooks/protect_archive.py` (registered in `crush.json`); the owner grants a pass by launching the session with `VAJB_ARCHIVE_OK=1`. Reference archived files by name only when the owner asked.
