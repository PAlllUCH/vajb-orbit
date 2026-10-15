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

Second incident, 2026-10-12 → 2026-10-15 (Linux host): a 4.3.0 server
process held 8000/9500 while the plugin was 4.2.2, so the editor could neither
adopt it nor bind its own port and showed no session for three days. After the
plugin was updated to 4.3.0 the *launch* path itself failed instead — the plugin
cannot own a `uvx`-launched server on Linux. Both the diagnosis and the working
arrangement (start the backend yourself, the plugin adopts it) are in the
section below.

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

## The plugin cannot own a `uvx`-launched server on Linux (measured 2026-10-15)

With plugin 4.2.2 or 4.3.0 the editor starts, loads the plugin, and then logs:

```
MCP | using uvx (godot-ai==<version>)
MCP | Probing the configured server endpoint.
MCP | server start blocked: The launched server process exited or changed identity
      before publishing capabilities. Identity capture: stage=launch
      category=identity_mismatch pid=<pid> creation_identity=linux:<ticks> attempt=1 elapsed_ms=0.
```

`session_manage` then reports `count: 0` while a server the plugin spawned keeps
listening on 8000/9500. **The plugin never retries.**

Cause: on Linux a process identity is `linux:<starttime>|<cmdline>`
(`utils/linux_proc.gd`), and the plugin verifies the pid it launched against that
identity before minting process authority (`utils/server_lifecycle.gd`,
`_owned_process_disposition` → `replaced`). The `uvx` shim rewrites its own argv
milliseconds after spawn (`…/bin/uvx …` → `…/bin/uv tool uvx …`), so the launch
fingerprint no longer matches the grant. The three tiers in
`client_configurator.gd::get_server_command` are the workaround space:
`dev_venv` (`python -m godot_ai`, stable argv) → `uvx` (broken here) →
`godot-ai` on `PATH` (stable argv). A project `.venv` is *not* picked up unless a
sibling `src/godot_ai/` exists, so the practical fix is the adopted server below.

**Fix — start the backend before the editor; the plugin adopts it** (this is the
plugin's own supported path, "a compatible external server is adopted for
transport"). The version must equal the plugin's, i.e. `crushrc`'s pin:

```bash
setsid nohup uvx --isolated --no-config --no-env-file --no-sources --no-build \
  --index-strategy first-index --keyring-provider disabled \
  --index https://pypi.org/simple --default-index https://pypi.org/simple \
  --find-links https://pypi.org/simple/godot-ai/ --link-mode copy \
  --from godot-ai==4.3.0 godot-ai --transport streamable-http \
  --port 8000 --ws-port 9500 >/tmp/godot-ai-backend.log 2>&1 &
```

Then launch the editor. Healthy log, in order:

```
MCP | Probing the configured server endpoint.
MCP | adopted external server
MCP | connected to server; authenticating
MCP | authenticated with server
```

and `session_manage(op="list")` → `count: 1` with `plugin_version` ==
`server_version` == the pin. The backend outlives the editor (it is not
plugin-owned), so an editor restart re-adopts it; if the backend dies, the
editor falls back to the broken `uvx` spawn and reports no session again.

A backend of a *different* version is refused, not adopted — that is what left
the 2026-10-12..15 editor dead: a 4.3.0 server held 8000/9500 while the plugin
was 4.2.2, so the plugin could neither adopt it nor bind its own port
(`godot_ai_server_startup.json`: `[Errno 98] HTTP port 8000 is already in use`).

## Diagnosis cheat-sheet

| Symptom | Meaning |
|---|---|
| `godot-ai` = connected, `session_manage` count 0 | MCP server alive, **editor closed** — or the plugin failed to own its launched server (see the section above); check the editor log for `server start blocked`. Ports 8000/9500 belong to the MCP server itself — they are not proof the editor runs. |
| Editor log: `category=identity_mismatch`, `stage=launch`, `elapsed_ms=0` | The `uvx` argv rewrite beat the plugin's identity capture. Start the backend yourself (section above) and relaunch the editor. |
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
