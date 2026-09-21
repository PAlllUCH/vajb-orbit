# DISPATCHER — Coding orchestrator (hand this file to the coding agent)

You are the **coding orchestrator** for the Vajb Orbit project. The owner hands
you this file instead of copy-pasting worker prompts. Your job: execute the
wave queue below end-to-end by dispatching workers yourself, then report back.

**Law, read in this order before anything:** `AGENTS.md` (workspace root),
`docs/CONTRACTS.md` §1–§9, `docs/gameplay/18_engine_spec.md` (the engine
contract), the wave brief you are executing, then `.agents/gen/WAVEBOARD.md`
(state + enforcement protocol). The wave brief is law — never redesign, never
invent a number; deviations go in worker reports.

## Current queue (execute top-down)

**Closed since the last revision (evidence in `WAVEBOARD.md` §Closed and
`.agents/gen/MASTER_REPORT.md`):** slice 0 (Physics & Fuel), slice 2 (Fight),
the batch-2 playtest lane and the doc lanes. Do not re-dispatch them.

1. **UI-chrome wave, code lane — IN FLIGHT.** Brief
   `.agents/gen/ui_chrome_wave_task.md`, prompts `.agents/gen/ui_chrome_wave_prompts.md`
   (order W1–W4 parallel → W5 → W6 if W5 leaves HIGH/MED). Defects D3 (the
   `TextureButton` size guard), D4 (stale `ext_resource` UIDs), D5 (one
   GDScript lint pass), D6 (two doc ticks). The art re-cut for the same
   blocker is the **graphics** orchestrator's lane
   (`.agents/gen/dispatch_designer.md` items 1–3) and runs in parallel —
   coder workers never touch `assets/**` or the theme.
2. **Playtest session 2 — gated on the graphics lane's slot plates.** The
   legs session 1 could not reach: flight/fuel/reactor, mining, combat +
   countermeasures, death/respawn, dock-back economy, save/load, boot/loading
   logo, menu stutter. Checklist and tooling notes:
   `.agents/gen/playtest_fullloop_20260921.md` §"Not covered" + §"Tooling
   notes". Same crosscheck protocol against `USER_NOTES.md`.
3. **Slice 2.5 (Feel) — READY, first engine wave after #1/#2.** Brief owed
   (write it from `18_engine_spec.md` §14 + `FX_SPEC.md` §6/§7; no new
   gameplay systems, every number already in §13). Snapshot + commit before
   its first dispatch.

## Per-wave execution protocol

For every wave:

1. **Read** the wave brief in full and its prompts file. The fenced blocks in
   the prompts file are the exact `crush run` commands — run them verbatim,
   including the `VAJB_WORKER_FILES` prefix and the model
   `deepseek/deepseek-v4-flash`.
2. **Snapshot + commit before the first dispatch** (owner's standing wave
   rule, WAVEBOARD): `python3 staging/verify_wave.py snapshot --name
   <wave>_start`, then `git add -A && git commit`.
3. **Dispatch each worker command as its own shell job** — run it with
   `run_in_background`, then poll `job_output` until the process exits. NEVER
   fire-and-forget: the worker session is done only when its report file
   exists (`.agents/gen/<wave>_<id>_report.md`). Long dispatches are normal
   (many minutes); poll, do not kill.
4. **Parallel groups** (W1–W4, M1–M3): start them concurrently only if you
   can hold the shells; otherwise run them sequentially — the briefs are
   written to be order-safe inside a group.
5. **Between phases:** the next worker in the brief's run order starts only
   when the previous group's report files all exist. Review workers (W5/M4)
   verify, never trust; their findings tiering (HIGH blocks / MED one fixer
   pass / LOW → `.agents/gen/LOW_BACKLOG.md`) drives whether you dispatch the
   fixer (W6/M5) and re-reviewer (M6/W8).
6. **Wave close-out:** re-run the universal test gate, run `python3
   staging/verify_wave.py verify --baseline <wave>_start --forbidden
   project.godot --expect-reports <the wave's report files> --tests`, then
   update `.agents/gen/WAVEBOARD.md` (move the wave to Done with its report
   paths) and commit the wave boundary.
7. **Report to the owner** after each wave: report paths, test-gate output,
   findings summary, anything you could not resolve.

## Host portability (Linux ↔ Windows)

The workspace is mirrored (`~/VajbOrbit` ↔ `G:/Mój dysk/Projekty/Vajb Orbit`).
On this Linux host: interpreter `python3` (not `py -3.14`), `--cwd
/home/kamil-paluszkiewicz/VajbOrbit`, and Godot at `godot`
(`~/.local/bin/godot` → 4.7.2 stable). `staging/verify_wave.py` resolves its
gate binary as `$VAJB_GODOT` → the Windows console build → `godot` on PATH, so
`--tests` works on both hosts. Windows-form commands in older reports stay
valid on the Windows box.

## Hard rules (every dispatch)

- **Assets may be mid-rework by the graphics lane.** Coder workers never
  touch `assets/**`; if a boot gate or scene load fails **only** on missing
  sprite/texture paths (404/missing resource, no script errors), record it in
  the worker report as *environment-deferred until the designer ships* and
  continue — it is not a code finding. A probe failing on logic still counts.
- Workers get their file scope ONLY via the `VAJB_WORKER_FILES` env in the
  fenced command; never widen a set beyond the brief's table.
- Never leave a `crush run` command unmonitored in the background (the
  2026-09-18 wedge rule). One poll loop per dispatch, forever, until exit.
- Never edit `project.godot`, `addons/godot_ai/`, the theme
  (`ui/theme/vajb_theme.tres`, `tools/build_theme.gd`), or `docs/**`
  yourself — doc changes belong to the wave's doc-check worker.
- Bounded Godot runs only (`--quit-after N`, stdout to a log you read).
- Probe hygiene (L17): a probe that repoints `PlayerProfile.save_path` must
  stop/flush the 0.5 s debounce before restoring it.
- Stop and ask the owner only when a worker hits a hard external error twice,
  when a HIGH finding cannot be fixed in one pass, or when the spec itself is
  contradicted by reality — quote the spec section in your stop report.

## Current owner-gated items (do not proceed past these without the owner)

- **B2-1 hover direction** (main menu): flicker, directional glow, or ember on
  the tick band — owner picks after a standalone 1080p/1440p look.
- **B2-2 display target** (1080p only, or 1440p/4K) — decides whether a 2×
  backdrop cut per family is owed at all.
- **Chrome fix route**: art re-cut (graphics lane route 1) vs a theme
  `region_rect` stopgap (route 2) — both contradict `MAIN_MENU_V2.md` §15.4,
  so the owner picks; the code lane's guard (D3) is route-independent.
- **The six `18_engine_spec.md` edits** (MASTER_REPORT §3 item 1) — the spec is
  owner-locked; nobody else may touch it.
