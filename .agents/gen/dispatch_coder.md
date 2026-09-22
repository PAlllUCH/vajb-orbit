# DISPATCHER — Coding orchestrator (hand this file to the coding agent)

You are the **coding orchestrator** for the Vajb Orbit project. The owner hands
you this file instead of copy-pasting worker prompts. Your job: execute the
wave queue below end-to-end by dispatching workers yourself, then report back.

**Law, read in this order before anything:** `AGENTS.md` (workspace root),
`docs/CONTRACTS.md` §1–§9, `docs/gameplay/18_engine_spec.md` (the engine
contract), the wave brief you are executing, then `.agents/gen/WAVEBOARD.md`
(state + enforcement protocol). The wave brief is law — never redesign, never
invent a number; deviations go in worker reports.

**How the owner hands you work (standing format, AGENTS.md §"Designer lane"):**
this file plus one short paragraph naming the queue item, the brief, the prompts,
the run order, the stop condition and the report-back contents — nothing else.
Each wave's brief and prompts live in `.agents/gen/<wave>_wave_task.md` and
`<wave>_wave_prompts.md`; a wave is finished only when its brief's close-out
section has run (gate re-run, `verify_wave.py verify --baseline <tag>`,
WAVEBOARD updated, wave-boundary commit) and you have reported the measured gate
count, the builders' numbers, the reviewer's findings by tier and the owner
ticks.

## Current queue (execute top-down)

**Items 4, 5 and 6 are DONE (2026-09-21/22, gate closed at 389) — see `WAVEBOARD.md`
§Closed. Nothing below dispatches: the next brief is P2-B proper, and only after the
owner has read P2-B1's report (the owner's stop condition). The owner's seven new
2026-09-22 requests are recorded in `WAVEBOARD.md` §Queued, unbriefed.**

**Closed since the last revision (evidence in `WAVEBOARD.md` §Closed and
`.agents/gen/MASTER_REPORT.md`):** slice 0 (Physics & Fuel), slice 2 (Fight),
the batch-2 playtest lane and the doc lanes. Do not re-dispatch them.

1. **UI-chrome wave, code lane — CLOSED 2026-09-21** (reports
   `.agents/gen/ui_chrome_w{1..6}_report.md`, gate 219 → 226, its art half
   shipped and reimported and the theme's frame margin matched to the art).
   Superseded below. Its brief
   `.agents/gen/ui_chrome_wave_task.md`, prompts `.agents/gen/ui_chrome_wave_prompts.md`
   (order W1–W4 parallel → W5 → W6 if W5 leaves HIGH/MED). Defects D3 (the
   `TextureButton` size guard), D4 (stale `ext_resource` UIDs), D5 (one
   GDScript lint pass), D6 (two doc ticks). The art re-cut for the same
   blocker is the **graphics** orchestrator's lane
   (`.agents/gen/dispatch_designer.md` items 1–3) and runs in parallel —
   coder workers never touch `assets/**` or the theme.
2. **Playtest session 2 — its art gate has shipped (the slot plates and the
   chrome are live); it is now blocked only by not being run.** The
   legs session 1 could not reach: flight/fuel/reactor, mining, combat +
   countermeasures, death/respawn, dock-back economy, save/load, boot/loading
   logo, menu stutter. Checklist and tooling notes:
   `.agents/gen/playtest_fullloop_20260921.md` §"Not covered" + §"Tooling
   notes". Same crosscheck protocol against `USER_NOTES.md`.
3. **Slice 2.5 (Feel) — READY, RUNS NEXT, before item 4.** Brief
   `.agents/gen/slice2_5_feel_wave_task.md`, prompts
   `.agents/gen/slice2_5_feel_wave_prompts.md` (order S1 → S2 → S3 if the review
   leaves HIGH/MED). It is the owner's thruster request plus what slice 2.5
   still owes after the weapon-FX wave shipped the damage half: motion blur,
   camera pull-back, dust, the hull-critical vignette, low-hull arcs, the
   thruster trail behind a `thruster_anchors()` seam, the S16 thruster bed with
   its speed curve and the boost cue — nine deliverables, all presentation, no
   gameplay number. The FX lane's own worker takes it (its `fx.gd`, the
   `audio_manager` loop beds and the `FEEDBACK` table are the warm context).
   Gate **277** before it. Snapshot + commit before the first dispatch.
4. **Wave P2-A — ship slot frames (QUEUED 2026-09-21, the owner's per-class
   slot/layout request).** Brief `.agents/gen/p2a_slot_frames_wave_task.md`,
   prompts `.agents/gen/p2a_slot_frames_wave_prompts.md` (order D0 → W1 · W2 ·
   W3 parallel → W4 · W5 parallel → R1 → F1). It makes every class's own slot
   count and layout real: the nine grid matrices, the engine **set** (1–3 cells
   by mass band, summed not multiplied), the profile's per-hull fits at save
   v4, the nine-hull catalogue, the launch path resolving the active hull's own
   fit, and the station/HUD layout displays. **The gameplay docs are already
   amended and are the law**: `08_ship_classes.md` §3/§3.1/§3.2/§3.3,
   `09_ship_slots_modules.md` §1/§2/§3.7/§4/§5/§7/§8/§9, `10_ship_acquisition.md`
   §2.3. The owner's tick list (brief §8) is **resolved 2026-09-21 — all six
   kept as designed** and does not block the wave; the one follow-up is the
   7-W capital's `weapon_6`/`weapon_7` input-map extension (an owner
   `project.godot` pass). A reversal stays a doc edit plus the one constant it
   names.
   Run it **after item 3** (slice 2.5 owns `game/game.gd`, `game/player_ship.gd`,
   `game/projectile.gd` and the camera, which this wave's W4/W5 also touch —
   they may not run at once), and in parallel with nothing that owns
   `game/ship_fit.gd`, `autoload/player_profile.gd`, `ui/hud/hud.gd` or the two
   station panels. Its follow-up **P2-B (the fitting panel)** is briefed after
   this wave's review.
5. **Wave Rock cleave — asteroid destruction effects (QUEUED 2026-09-21, the
   owner's ruling).** Brief `.agents/gen/rock_cleave_wave_task.md`, prompts
   `.agents/gen/rock_cleave_wave_prompts.md` (order A1 → A2 → A3 if the review
   leaves HIGH/MED). Depletion explodes: one rock-scaled `fx_explosion` read plus
   a break cue, and a **random 2–5** fragments per cleaving tier in **uniformly
   random** directions at the shipped ×1.2 speed — the deterministic (2,3)/(2,2)
   split and the ±15° cone retire. Small keeps its 1–2 pickup burst; ruling 17's
   yield-0 path keeps despawning bare but plays the break read. `18_engine_spec.md`
   §6 is owner-locked, so its dated amendment is the owner's tick. Gate **311**
   before it. Parallel-safe with item 4 (disjoint file sets), after item 3.
6. **Wave P2-B1 — the weapon fit surface (QUEUED 2026-09-21, the owner's
   weapons-gating request).** Brief `.agents/gen/p2b1_weapon_fit_wave_task.md`,
   prompts `.agents/gen/p2b1_weapon_fit_wave_prompts.md` (order D0 → W1 → W2 →
   R1 → F1). Only fitted weapons are usable — the door: OUTFITTING sells the six
   weapon modules of 09 §3.1 into the profile's inventory (10 §5's interim
   pattern, retired when the AUCTION lands), and the panel installs / swaps /
   removes them into the active hull's W cells through `ShipFit.fit_legal` with
   the over-by refusal shown; the mandatory engine/reactor set is untouchable
   from this surface; the flight side changes nothing (P2-A's W4 already mounts
   only fitted weapons). **Runs after item 4** — it consumes P2-A's APIs and
   reads its reports. Its successor **P2-B proper** (per-slot fitting, the power
   meter, affixes, the legacy-UPGRADES flag day) is briefed after this wave's
   review.
7. **Wave P2-B proper — the fitting panel (QUEUED 2026-09-22, owner order "lets
   start with p2-b").** Brief `.agents/gen/p2b_proper_wave_task.md`, prompts
   `.agents/gen/p2b_proper_wave_prompts.md` (order D0 → W1 → W2 → W3 → R1 → F1).
   The scope the owner ticked on 2026-09-22: the **FITTING** pane takes the
   UPGRADES rail entry and installs / swaps / removes modules **cell by cell**
   across all eight slot types through `fit_module_at` / `clear_fit_slot` with
   the power meter showing the candidate's budget before commit; the six legacy
   `UPGRADES` rows **retire** (save v5 migrates each installed upgrade to its
   09-lineage successor module); the owner's four station requests ride along
   (shipyard hover info, the owned-modules inventory, the shipyard's own
   slot-grid recipe in FITTING, REFUEL/RECHARGE in LAUNCH). **Affixes (doc 15)
   are the NEXT wave, not this one** — the owner's tick. Runs after item 6 (it
   consumes P2-B1's panel and P2-A's `ShipFit`/profile pins) and after the P2-B1
   close-out is committed.

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
