# Vajb Orbit — Agent Operating Manual

Dark Orbit clone in Godot 4.7.2. **The game is 2D** — sprites and `Control`
UI; every 3D node in the tree comes from the vendored editor plugin, not from
this game. Project code lives in `vajb-orbit/`; this file plus
`crush.json`/`crushrc` live at the workspace root.

**Host-neutral paths.** This workspace runs on Windows and Linux, so no document
here carries absolute host paths. Everything host-specific resolves from
environment variables set per host in `crushrc` (plus `environment.d` on Linux):
`$VAJB_WORKSPACE` (workspace root — also what `--cwd` gets), `$VAJB_PROJ`
(`$VAJB_WORKSPACE/vajb-orbit`), `$GODOT_EDITOR` / `$GODOT_CONSOLE` (engine
binaries), `$CRUSH_TOOLS` (crush tooling: `assetmcp`, `godot-lsp-bridge`,
`mcp-legacy-shim.py`), `$KIE_GENERATE` (the `image-generator` skill's
`kie_generate.py`). If a command below shows a bare variable, the real path
lives only in `crushrc`. No secrets belong in any project document.

**Keep this file small.** It rides on every request of every session, including
every `crush run` worker. The measured cost and the guards that hold it down are
in `crushrc`'s header; the evidence and tool inventories that used to live here
are in `docs/AGENT_PIPELINE_NOTES.md`. New detail belongs in the owning spec.

## Source of Truth

- `vajb-orbit/project.godot` — engine config. Do not hand-edit except documented
  keys (`editor_plugins`).
- `docs/` — design and spec documents. Spec before code.
- `docs/design/ASSET_CATALOG.md` — index of every shipped file in
  `vajb-orbit/assets/` (path, size, alpha, purpose, Phase B/D/E, audio facts).
  Check it before wiring art or audio into scenes.
- `asset-library/` — **where every generated asset lives.** Search here first
  for any art; `vajb-orbit/assets/` holds only what a feature has actually
  pulled in. `raw/` is the untouched renders, `cut/` is one centred, named file
  per asset, `_review/` is the contact sheets. How to rebuild any of it, and
  what each generated file records, is in `asset-library/README.md`.
- This file — agent rules and commands. Read before any work.

## Where to look

| Need | Read |
|---|---|
| Live state, queued work, next dispatch, closure history | `.agents/gen/_state/WAVEBOARD.md` — **read first when resuming**; live state only, recaps live in `MASTER_REPORT.md` §6 |
| Open LOW findings and tickets (`T-###`) | `.agents/gen/_state/LOW_BACKLOG.md` |
| Engine contract (§2/§2.1 owner decisions, §13 calibration, §14 build slices) | `docs/gameplay/18_engine_spec.md` — owner-locked |
| Pinned interfaces every worker brief references | `docs/CONTRACTS.md` — review waves own updating it |
| Palette/style, UI/theming tokens, screen inventory + flow | `docs/design/STYLE_BIBLE.md`, `UI_SPEC.md`, `MENU_FLOW.md` |
| Screen contracts | `docs/design/MAIN_MENU_V2.md` (menu + boot/loading; `MAIN_MENU_SPEC.md` is superseded), `STATION_HUB.md`, `STATION_SPEC.md`, `THEME_AUDIO_EXTENSION.md` |
| Prompt + wiring source per asset family | `docs/design/SHIPS_SPEC.md`, `ICONS_SPEC.md`, `ENVIRONMENT_SPEC.md`, `FX_SPEC.md`, `UI_CHROME_ASSETS_SPEC.md`, `AUDIO_SPEC.md`, `ASSET_NAMING_SPEC.md` |
| Integration contract for art and audio | `docs/design/ASSET_WIRING_HANDOFF.md` |
| Executed asset plans (authoritative for model/price/split rules) | `docs/design/GENERATION_PLAN.md` (B), `ASSET_EXPANSION_SPEC.md` (D), `ASSET_EXPANSION_SPEC_E.md` (E), `docs/gameplay/16_art_design_brief.md` (F) |
| The coding contract Phase C/D/P1 coded against | `docs/design/IMPLEMENTATION_PLAN.md` (§9 carries the Phase D and P1 amendments), `PROJECT_SETTINGS_PATCH.md`, `PHASE_C_STATUS.md` |
| RPG/economy layer | `docs/gameplay/` docs 01–17, `19_testing_notes.md`, `17_coder_handoff.md` (build plan) |
| Asset provenance, pipeline evidence, godot-ai gap list | `docs/AGENT_PIPELINE_NOTES.md` |
| Historical record | `.agents/gen/MASTER_REPORT.md` plus the newest session report |

**Agent tooling (workspace):** `staging/verify_wave.py` (`snapshot` before /
`verify --baseline <tag>` after a wave; baselines in
`.agents/gen/_state/_wave_state/`), hooks `.crush/hooks/protect_archive.py`
(seals the archive) and `.crush/hooks/enforce_worker_files.py` (per-worker file
set via `VAJB_WORKER_FILES`), and the universal test gate:

```bash
$GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200
# -> [SUMMARY] passed=437 failed=0   (the live count is whatever the gate
#    prints; zero failures is the law)
```

The repo (`github.com/PAlllUCH/vajb-orbit`) is text-only — binary assets are
gitignored; commit at every wave boundary.

## Context hygiene

Context is re-sent on every request, so what a session reads once it pays for on
every later turn. These four rules are the difference between a 60k session and
a 300k one:

- **Read long docs by range, never whole.** `docs/CONTRACTS.md` is ~3,200 lines
  and ~80k tokens in full, ~2-3k for the one § your task needs; its top carries
  a generated index of every section and its line range. Locate with
  `rg -n '^## §' docs/CONTRACTS.md`, then `view --offset … --limit …`. Same for
  `docs/gameplay/18_engine_spec.md` and any spec over ~500 lines.
- **Cap what you write.** Worker reports ≤120 lines, reviews ≤150, one evidence
  line per finding. Cite `file:line`; never paste source, transcripts or full
  gate logs — the reader re-derives from the code, and every pasted line is
  re-sent to them on every request.
- **One session per wave phase.** A long-lived session pays for its whole
  history on each turn, so a wave in three sessions (builder → reviewer → fixer)
  costs less than the same work in one, even paying the startup three times.
- **Screenshots and probes are the biggest single results.** Iterate at
  `max_resolution` 640 and raise it only to verify a hairline or flag; check a
  state flag with `game_eval` rather than a pixel; never re-request a view you
  already have.

`staging/verify_wave.py`, the gate and the reviewer's re-measurement are the
exceptions that justify reading a whole file: they read what they measure.

## Engine binaries

| Use | Binary |
|-----|--------|
| Editor (UI, LSP, MCP server) | `$GODOT_EDITOR` |
| Headless / scripted runs | `$GODOT_CONSOLE` |

Values are host-specific and live in `crushrc` (Windows: the 4.7.2 stable pair
under the local tool dir; Linux: `godot` on `PATH`). Always pass
`--path "$VAJB_PROJ"` (the path contains spaces on the Windows host).

- Config validation / reimport: `$GODOT_CONSOLE --headless --editor --path "$VAJB_PROJ" --quit`
- Run game headless: `$GODOT_CONSOLE --headless --path "$VAJB_PROJ"`
- Run a script: `$GODOT_CONSOLE --headless --path "$VAJB_PROJ" --script res://<script>.gd`

### Release exports

`vajb-orbit/export_presets.cfg` carries the two desktop presets (`Linux`,
`Windows Desktop`: 64-bit, single-file, release templates) and excludes
`addons/`, `tests/` and `tools/`, so a build handed to testers never carries
the MCP plugin, the gate or the audit scripts. Export both, smoke-test the
runnable one, then zip:

```bash
$GODOT_CONSOLE --headless --path "$VAJB_PROJ" --export-release "Linux" "$VAJB_WORKSPACE/builds/linux/vajb-orbit.x86_64"
$GODOT_CONSOLE --headless --path "$VAJB_PROJ" --export-release "Windows Desktop" "$VAJB_WORKSPACE/builds/windows/vajb-orbit.exe"
```

`builds/` is gitignored and stays out of the Drive mirror; shareable zips go to
a dated folder beside the mirror. Export templates are the 4.7.2-stable set
(`~/.local/share/godot/export_templates/4.7.2.stable/`). A release is not done
until the Linux binary boots on Vulkan and exits clean (`--quit-after 400`,
only the benign ObjectDB-leak warning) — the Windows binary cannot be run on
the Linux host, so it is verified structurally (same embedded pack size).

### Editor / LSP / godot-ai runbook

The full, verified recovery procedure (detached launch command, LSP warm-up,
diagnosis cheat-sheet, godot-ai behaviour notes) lives in the
`vajb-orbit-environment` skill — that file is the detailed version; this
section must not duplicate it and drift. Summary: launch the editor
**detached** so it survives Crush restarts (a child of Crush's background shell
is killed when Crush restarts — this killed the editor once); boot takes ~30 s
before the editor's LSP listens; the lazy gdscript LSP needs any `.gd`
operation to start. `godot-ai` reporting *connected* proves only that the MCP
server runs — `session_manage(op='list')` with `count: 0` means the editor is
not running.

## GDScript LSP

`godot-lsp-bridge` (v1.3.0, on `PATH` via `crushrc`) is configured in
`crush.json`. It requires **the Godot editor to be open with the project** —
the language server runs on TCP 6005–6014 (auto-discovered by the bridge).
Diagnostics, go-to-definition, and completions do not work headless.

## MCP servers

- **godot-ai** — drives the live editor. Requires the editor open with the
  plugin (`addons/godot_ai/`, enabled via `editor_plugins` in
  `project.godot`). **`crushrc`'s pin must match the plugin's version** (both
  4.2.2 as of 2026-09-24); a mismatched attach client fails its capability
  check. The plugin's dock writes/verifies client config; if connection fails,
  open the Godot AI dock in the editor and re-run "Configure". Port pair: HTTP
  8000, WS 9500. The full capability audit, the round-trip evidence and all ten
  gaps worth remembering are in `docs/AGENT_PIPELINE_NOTES.md`; the four that
  change how you work:
  - Writes are refused while the game plays (`EDITOR_NOT_READY` /
    `EDITOR_PLAYING`) — stop first; reads and `game_*` ops still work.
  - `batch_execute` takes *plugin* command names (`create_node`,
    `set_property`, `attach_script`), not MCP tool names; an unknown name
    aborts the batch and rolls back the earlier sub-commands.
  - `editor_screenshot` returns its image inline and downscales to
    `max_resolution` (default 640) — a hairline can vanish at 640 but is
    unmistakable at 1152. Verify a flag with `game_eval`, not the pixel.
  - Window-mode and resolution changes are inert in a `project_run` game;
    validate those settings in a standalone run with no editor open.
- **assetmcp** (local clone at `$CRUSH_TOOLS/assetmcp`) — asset search, license
  check, download, auto-extract, pointed at `asset-library/`. Art is
  AI-generated (kie.ai), not sourced, so its role is audio sourcing and license
  validation. Its venv pins `mcp<2` — re-running plain `pip install -U mcp`
  breaks it (FastMCP rename).

## Skills

`crushrc` references the shared Godot skill library in place (single source of
truth, no copy); the two directory roots are host-specific and live there.

- `<crush-main>/additional-skills/godot` → `godot-master` (routing index),
  `godot-best-practices`, `godot-development`, `godot-ui`
- `<crush-main>/additional-skills/godot/godot-master` → the 96 domain subskills

For any Godot task: start from `godot-master` keyword routing
(`skills_index.json` → reference file under
`godot-master/godot-master/references/`), and follow the Layer Cake rule:
signals travel UP, calls travel DOWN.

**Only the skills listed in `crushrc`'s `VAJB_KEEP_SKILLS` are injected.** The
other ~75 subskills stay on disk and are still read by path through the routing
index, so a missing description costs a lookup, not a capability; adding a name
to that list brings one back into context.

`skills/` at the workspace root holds the project-local skill
(`vajb-orbit-environment`) covering the editor/LSP/MCP runbook — don't duplicate
it here if it drifts; the skill is the detailed version.

## Host portability (Linux ↔ Windows)

The workspace is mirrored between a Windows box (workspace on the user's cloud
drive, tooling under the local crush dir, interpreter `py -3.14`) and Linux
(different workspace and tooling roots, interpreter `python3`).
**`$VAJB_WORKSPACE` and `$CRUSH_TOOLS` name both roots — no document hardcodes
either host's layout.** **`crushrc` is the live source for everything
host-specific** — skills, both MCP servers, the LSP, the PreToolUse hooks and
the token-budget guards; `crush.json` keeps only host-neutral parts (`lsp`,
`options.skills_paths`) plus the original Windows values renamed to
`_windows_mcp_legacy` / `_windows_hooks_legacy`.

**`mcp add` / `hook add` append, they never replace.** `mcp remove` and
`hook remove` in `crushrc` do not cancel entries that `crush.json` contributes —
the definitions merge. Symptom: the MCP server's args arrive **twice** (the
command becomes garbage and the process dies instantly as `client is closing:
EOF`), and every matching tool call runs two hooks (one per definition). Never
define the same server or hook in both files; if a Windows Crush predates
`crushrc` support, restore the `_windows_*_legacy` blocks instead.

**The `server/discover` shim is still required.** Crush ≥ the SEP-2575 protocol
revision probes `server/discover` on every MCP connection. `godot-ai 4.2.2`
answers it with `-32601` (measured 2026-09-24) and `assetmcp` needs `mcp<2` (its
`mcp.server.fastmcp` import was renamed in 2.x); either way the handshake dies
with `client is closing: EOF`. `tools/mcp-legacy-shim.py` answers the probe with
a legacy-only version list, which makes the go-sdk client fall back to the
legacy `initialize` handshake (`mcp/client.go`: "if there is no overlap, fall
back to initialize"). Both servers run through it. Drop the shim only after a
probe shows a server answering that method itself. Set `MCP_SHIM_LOG=<path>` to
trace shim traffic.

`crushrc` runs in Crush's embedded shell, not bash: its `printf` mangles a
format string beginning with `--`, which is why the godot-ai tool list is
written out as literal flags instead of a loop. Validate any change with
`bash -n crushrc` **and** by sourcing it against stub builtins before trusting
it.

Tooling installs, the session-DB recovery remedy
(`restore-vajborbit-config.sh`, the verified-good 09-17 snapshot) and the
version facts: restart Crush after changing any of them — the MCP/LSP clients
and the `rg` lookup are resolved once at startup. See
`docs/AGENT_PIPELINE_NOTES.md`.

## Asset generation (kie.ai)

Run the generator under the python.org interpreter, **not** the PATH `python`
(on Windows that is Inkscape's bundled 3.12, which ships no CA roots, so every
call dies with `CERTIFICATE_VERIFY_FAILED` — nothing is billed; on Linux the
interpreter is `python3`). Price basis: **10 credits = $0.05 per 2K run**
(kie.ai console, user-verified) — the script's printed estimate is stale and
`usage-ledger.jsonl` over-reports spend 3x; the console is the authority.

- Transparency: request `--transparent` first, then verify with Pillow (RGBA
  with more than 10 % of pixels at alpha 0). Fall back to `--strip-bg local` for
  sprites/icons/props; **never** key FX, which stay RGB on void black for
  additive blending — **except the four the owner scoped on 2026-09-21**
  (`fx_smoke_plume`, `fx_acid_burn`, `fx_dust_streak`,
  `fx_hull_critical_vignette`), which draw with MIX and must carry alpha; the
  carve-out, the routes and the evidence are `docs/design/FX_SPEC.md` §0.1's
  amendment.
- `flare` answers `--transparent` with an opaque near-black render (the style
  block names a void background and wins), so `cut/` ships RGB with the
  background in it and keying is a later pass — for FX, a later pass only for
  the four names above. Before shipping *any* keyed FX, run
  `staging/cut/qc_fx_alpha.py` (box containment, enclosed transparency,
  inverted matte) and `staging/cut/verify_fx_alpha.py` (deepseek-chat vision,
  majority of three reads): the matte is the tool that ate the UI slot plates.
- `recraft/remove-background` is a rescue tool, not a default (softer matte plus
  a call per asset). Its endpoint rejects the skill's `image_url` list with
  `image is required`; the accepted field is `image` as a string.
- Batch driver: `staging/phase_d/wave1.py <run-id> ...` — one paid API call per
  run, with alpha-keying, splitting, renaming, downscaling and log writing done
  locally for free.

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
  wave's numbers are recorded in the WAVEBOARD and `MASTER_REPORT.md`. The
  wave's recap (gate history, deliverables, the gates it raised) is appended to
  `MASTER_REPORT.md` §6 and only its one-line outcome stays in the WAVEBOARD —
  that file is read at the start of every orchestrator session and must stay
  live-only.

## Rules

- Update docs first, then code, then tests — never the reverse.
- Host commands: where a pipeline example says `py -3.14`, that is the Windows
  python.org interpreter; on Linux the same scripts run under `python3`.
  `$GODOT_*`/`$VAJB_*` variables resolve per host from `crushrc`.
- **Assets live in `asset-library/`, not in the project.** Generated art flows one
  way: `raw/` → `cut/` → `vajb-orbit/assets/<family>/` only when a feature needs
  it. Never bulk-restore the project's art. **`raw/`, `cut/` and `_dropped/` are
  archived to `asset-library/_archive/*.zip` and are not loose** — every one of the
  488 shippable cuts is already in the project, so run
  `py -3.14 staging/cut/archive.py --restore cut` (or `raw`) before any step that
  reads that tree, and `--make`/`--prune` to re-archive. `_prekey_backup/` and
  `_keying/` stay loose (the keying pass's reversal store and its paid answer
  cache). The four rebuild steps, in order:
  `py -3.14 staging/cut/build_plan.py` → re-derive `_sheets.json` from the
  manifests; `py -3.14 staging/cut/deepseek_layout.py` → ask a vision model for
  each sheet's arrangement; `py -3.14 staging/cut/cut_sheets.py` → cut every sheet
  (`--check` reports only, `--only <text>` narrows it);
  `py -3.14 staging/cut/build_review.py` → refresh the contact sheets. A sheet's
  *arrangement* is read from the render, because the prompts contradict each other
  on it and a wrong guess mis-names every icon on the sheet; the *cell count and
  the names* come from the recovered Phase D/E/F specs, so the names cannot drift
  from the set the game knows. Objects are found by masking the ink, never by
  cutting on a divider. `_originals_manifest.json` holds every run's exact prompt
  and job id. Panel evidence and the two measured failure modes:
  `docs/AGENT_PIPELINE_NOTES.md`.
- **To find out what an asset is, read `asset-library/INDEX.md` or
  `asset-library/_library.json`.** Every file has a record: a description read off
  the picture itself by `py -3.14 staging/cut/tag_vision.py`, plus subject, kind,
  pixels, bytes, alpha share, md5, the sheet and panel it was cut from, the job and
  prompt that rendered that sheet, the docs and code that name it, and a
  `name_issue` when the file name cannot be trusted. **The description is the truth
  and the file name is a hint**: nine renders ignored their brief and show a
  spaceship where the name says "tileable layer" or "glow orb", all listed under
  `name_issue: content-mismatch`. Read `role` before using a file — `sprite`
  ships, `plate` is a whole-frame layer used as-is, `sheet` is provenance and never
  ships. Regenerate with `py -3.14 staging/cut/build_library.py`; never hand-edit.
  Naming law: `docs/design/ASSET_NAMING_SPEC.md`. The rename chain is
  `find_matches.py` → `build_naming_digest.py` → `naming_assignments.py` →
  `apply_names.py` (reversible through `_rename_map.json`) → `validate_names.py`,
  whose `--library` mode proves every name the specs and the code require is
  present: run it after any asset change. `pull.py` is the only thing that copies
  `cut/` into the project.
- **Keying is done and it is scripted, cached and reversible.** 441 sprites carry
  alpha; the routes, the evidence and the two known failure modes are in
  `asset-library/README.md` §"Keying is done". `key_assets.py --recraft` keys
  through `recraft/remove-background` on kie.ai (1 credit each, resumable per
  sprite, 20 submissions a minute, answers cached under `_keying/recraft/`);
  `key_flat.py --check <name>…` is the region-based Python key for flat icons where
  the paid matte inverts; `center_check.py --report|--apply` centres every object on
  its canvas. Every original is in `_prekey_backup/` (md5-stamped manifest) and
  `key_assets.py --undo` puts them back. Never re-key by hand-editing a PNG.
- Worker dispatches (`crush run`) must never leave a command in the background:
  the shell auto-backgrounds anything past ~60 s and the worker then waits on the
  job forever (three workers wedged this way on 2026-09-18). Bound every Godot run
  with `--quit-after`, make probes self-quit with a watchdog, and have workers
  redirect probe stdout to a log they read instead of waiting on the process.
  **Dispatch workers with `VAJB_SLIM=1`** (see `crushrc`) so each one does not pay
  for two MCP servers and 75 skill descriptions it cannot use; the gate and the
  editor bridge stay available to the orchestrator and reviewer sessions.
- Asset regeneration is scripted, never hand-edited: art review sheets and the
  catalog via `py -3.14 staging/phase_d/build_review.py` and `build_catalog.py`;
  Phase F sheets via `staging/phase_f/build_p0_review.py`,
  `build_review_scene.py`, `build_panel_sheets.py`; audio via
  `staging/audio/build_audio.py`, then `set_loop_flags.py`, then a
  `filesystem_manage reimport` in the editor (editor writes are refused while the
  game plays — stop it first). Wiring contract:
  `docs/design/ASSET_WIRING_HANDOFF.md`.
- Icon work is scripted the same way (`staging/phase_f/`: `recut_quartet.py`,
  `chrome_2x.py`, `apply_import_settings.py`, `rekey_halo.py`,
  `build_f1_review.py`, `qc_f1.py`, `qc_f2.py`). After any icon change:
  `tools/derive_icon_tints.gd` (headless `--script`), then the import-settings
  pass, a reimport, then `build_catalog.py`. Reimport through `filesystem_manage`
  when the editor is open; a headless `--editor --quit` reimport needs the editor
  closed first. Full inventory and the two hard-won import facts:
  `docs/AGENT_PIPELINE_NOTES.md`.
- Never edit `addons/godot_ai/` (vendored plugin); update it by replacing the
  folder from a new release zip and re-running the dock's Configure. Bump
  `crushrc`'s pin to the same version in the same change.
- AI-generated art (kie.ai) is **not** CC0 — record the generator's usage terms
  before shipping and keep a generation log (prompt/seed/model/date) next to
  generated assets under `vajb-orbit/assets/`.
- Audio (`vajb-orbit/assets/audio/`) is **CC0 1.0** sourced through `assetmcp`;
  keep new audio CC0-only (no CC-BY/OGA-BY) and let the manifest carry provenance
  instead of a credits screen.
- `docs/archive/` is **sealed**: no agent reads, writes, moves or lists anything
  inside it without the owner's explicit permission for that pass. Enforced by the
  PreToolUse hook `.crush/hooks/protect_archive.py`, which inspects only the paths
  and commands a call reaches — naming the directory in a document is fine. The
  owner grants a pass by launching the session with `VAJB_ARCHIVE_OK=1`; reference
  archived files by name only when the owner asked.
