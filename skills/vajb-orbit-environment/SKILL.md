---
name: vajb-orbit-environment
description: Vajb Orbit workspace runbook for the Godot editor, godot-ai MCP, and gdscript LSP lifecycle. Use when launching/connecting the Godot editor, when godot-ai reports no active session or the gdscript LSP fails/times out, when running the game or scripts headless, or when diagnosing why Godot tooling looks dead in this project.
---

# Vajb Orbit — Environment Runbook

Project: Dark Orbit clone, Godot 4.7.2 (Forward+, D3D12, Jolt physics).
Code in `vajb-orbit/`; workspace root has `AGENTS.md` (ops manual) and `crush.json`.

**Host neutrality:** this runbook is host-neutral — the engine binaries and
workspace root come from `$env:GODOT_EDITOR`, `$env:GODOT_CONSOLE` and
`$env:VAJB_PROJ`, set per host in `crushrc` (Windows and Linux differ). No
absolute paths or secrets belong in project documents.

## What happened (incident log — 2026-09-16)

1. First session: `godot-ai` MCP showed "connected" and `gdscript` LSP timed out — root cause: **no Godot editor process existed at all**. The MCP server had merely started. Launching the editor fixed both instantly.
2. That first editor was launched as a child of Crush's background shell. When **Crush restarted (~19:17), the editor died with it**, and godot-ai/LSP went dark again until relaunched.
3. Two relaunch attempts failed silently before the working one was found:
   - `Start-Process -ArgumentList '--path','<workspace>'` → PowerShell joins args unquoted; the space breaks `--path`; Godot exits immediately with no error surfaced.
   - `cmd /c start ...` from this shell → swallowed by clink, nothing launches.
4. Working method (verified): `Start-Process` with **`-WorkingDirectory`** on the project and only `--editor` as arg (no `--path`), which detaches the process so Crush restarts don't kill it.

## Exact recovery procedure

1. Launch editor detached:
   ```powershell
   powershell -Command "Start-Process -FilePath $env:GODOT_EDITOR -WorkingDirectory $env:VAJB_PROJ -ArgumentList '--editor'"
   ```
2. Wait ~30 s (editor boots, then starts its LSP), verify:
   ```powershell
   powershell -Command "Test-NetConnection 127.0.0.1 -Port 6005 -InformationLevel Quiet"
   ```
   Expected: `True`.
3. Confirm godot-ai sees it: `session_manage(op="list")` → `count: 1`, session `vajb-orbit@...`.
4. Warm the gdscript LSP: it is lazy — create/edit any `.gd` in the project and run LSP diagnostics once, then check status is `ready`. With zero `.gd` files it stays `not_started`.
5. Optional cross-check: `godot-lsp-bridge doctor` (on `PATH` via `crushrc`) must pass both checks when the editor is open.

## Diagnosis cheat-sheet

| Symptom | Meaning |
|---|---|
| `godot-ai` = connected, `session_manage` count 0 | MCP server alive, **editor closed**. Ports 8000/9500 belong to the MCP server itself — they are not proof the editor runs. |
| LSP log: `os error 10061` on 127.0.0.1:6005, 300 s timeout | Editor's language server not listening → editor closed (or still booting; wait and retest). |
| `gdscript = not_started` in crush_info | LSP is lazy; trigger it with any `.gd` operation. Not an error by itself. |
| Skills show 0/109 loaded | Normal — skills load on demand when a task matches. |
| Bridge log: multiple Godot LSP instances [6005, 6006] | Normal: one editor exposes two listeners; bridge picks the lowest port. |

## Other fixed facts

- Engine binaries: `$env:GODOT_EDITOR` (editor) / `$env:GODOT_CONSOLE` (headless) — values host-specific, set in `crushrc`. Pass `--path` (spaces on the Windows host) or use the `-WorkingDirectory` trick above.
- Headless validation: `..._console.exe --headless --editor --path <proj> --quit` (exit 0 = healthy; plugin disabled headless by design).
- Legacy global `godot` MCP is intentionally disabled (superseded by godot-ai; its `GODOT_PATH` is broken — verified 2026-09-17, that v4.7.1 folder does not exist). It is a CLI/headless driver: it cannot see the open editor. Leave off.
- `assetmcp` is enabled in `crush.json` and its library (`asset-library/` at the workspace root) holds the 25 CC0 audio packs downloaded in the 2026-09-17 audio pass, plus `ASSET_MANIFEST.json` and `CREDITS.md`. It is the audio-sourcing + license-validation path; art is AI-generated instead. Its venv pins `mcp<2` — re-enable only with that pin intact.

## godot-ai behaviour worth knowing (verified 2026-09-17)

- **Writes are refused while the game plays** (`EDITOR_NOT_READY` / `EDITOR_PLAYING`). Reads, `filesystem_manage`, `test_run` and `game_*` ops still work; call `project_manage(op="stop")` before scene edits. If the cache is stale after a user-side stop, call `editor_state` once to resync.
- `batch_execute` items use **plugin** command names (`create_node`, `set_property`, `attach_script`), not MCP tool names. An unknown name aborts the whole batch and rolls back the earlier sub-commands (safe by default).
- Prefer godot-ai's own script diagnostics (`script_create` / `script_patch` return them) over Crush's `gdscript` LSP: a scratch `.gd` with a genuine parse error produced **no** `lsp_diagnostics` output, while the Godot-side capture reported both parse-error lines with line numbers.
- Runtime debugging loop that works: `project_run` → `logs_read(source="game", include_details=true)` for `push_error` with stack frames → `game_eval` for live state → `editor_screenshot(source="game")` to eyeball the frame → `project_manage(op="stop")`.
- `editor_manage(op="quit")` exits the editor cleanly (window closes, port 6005 drops). Discard in-memory scene edits with `scene_open(force_reload=true)` before deleting scratch files, or the quit may prompt to save.
- `assetmcp` stays enabled (see above); do not plan art sourcing around it, and keep the `mcp<2` venv pin. Re-populating the library is only needed if new CC0 assets are sourced.
- Editor plugin `addons/godot_ai/` is vendored — never hand-edit; replace from release zip + re-run dock "Configure".
