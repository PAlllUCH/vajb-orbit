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

1. **Slice 0 — Physics & Fuel** → brief `.agents/gen/slice0_task.md`, prompts
   `.agents/gen/slice0_prompts.md` (order M0 → M1–M3 parallel → M4 → M5 → M6).
2. **Slice 2 — Fight** → brief `.agents/gen/slice2_task.md`, prompts
   `.agents/gen/slice2_prompts.md` (order W0 → W1–W4 parallel → W5 → W6 → W7
   → W8). Dispatch only after slice 0 closes clean.
3. **Batch-2 playtest lane** → `.agents/gen/batch2_task.md` — run in parallel
   with #1 if you can hold two worker sessions; it is file-disjoint.

## Per-wave execution protocol

For every wave:

1. **Read** the wave brief in full and its prompts file. The fenced blocks in
   the prompts file are the exact `crush run` commands — run them verbatim,
   including the `VAJB_WORKER_FILES` prefix and the model
   `deepseek/deepseek-v4-flash`.
2. **Snapshot + commit before the first dispatch** (owner's standing wave
   rule, WAVEBOARD): `py -3.14 staging/verify_wave.py snapshot --name
   <wave>_start`, then `git add -A && git commit`.
3. **Dispatch each worker command as its own shell job** — run it with
   `run_in_background`, then poll `job_output` until the process exits. NEVER
   fire-and-forget: the worker session is done only when its report file
   exists (`.agents/gen/<wave>_<id>_report.md`). Long dispatches are normal
   (many minutes); poll, do not kill.
4. **Parallel groups** (M1–M3, W1–W4): start them concurrently only if you
   can hold the shells; otherwise run them sequentially — the briefs are
   written to be order-safe inside a group.
5. **Between phases:** the next worker in the brief's run order starts only
   when the previous group's report files all exist. Review workers (M4/W6)
   verify, never trust; their findings tiering (HIGH blocks / MED one fixer
   pass / LOW → `.agents/gen/LOW_BACKLOG.md`) drives whether you dispatch the
   fixer (M5/W7) and re-reviewer (M6/W8).
6. **Wave close-out:** re-run the universal test gate
   (`..._console.exe --headless --path "G:/Mój dysk/Projekty/Vajb
   Orbit/vajb-orbit" res://tests/headless_runner.tscn --quit-after 1200`),
   run `py -3.14 staging/verify_wave.py verify --baseline <wave>_start
   --expect-reports <the wave's report files>`, then update
   `.agents/gen/WAVEBOARD.md` (move the wave to Done with its report paths)
   and commit the wave boundary.
7. **Report to the owner** after each wave: report paths, test-gate output,
   findings summary, anything you could not resolve.

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
- Never edit `project.godot`, `addons/godot_ai/`, the theme, or `docs/**`
  yourself — doc changes belong to the wave's doc-check worker.
- Bounded Godot runs only (`--quit-after N`, stdout to a log you read).
- Stop and ask the owner only when a worker hits a hard external error twice,
  when a HIGH finding cannot be fixed in one pass, or when the spec itself is
  contradicted by reality — quote the spec section in your stop report.

## Current owner-gated items (do not proceed past these without the owner)

- Slice 0: the §13 **speed table v2 △ rows** (Cutter 700, Miner 380, Frigate
  450) need the owner's tick — until then the shipped §13 class columns are
  law and the migration derives forces from them (slice0_task.md § Open
  dependency).
