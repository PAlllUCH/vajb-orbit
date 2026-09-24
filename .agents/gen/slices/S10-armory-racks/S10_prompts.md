# S10_prompts — dispatch blocks (worker prompts live here; the owner never pastes them)

Model for every worker: `deepseek/deepseek-flash` (DeepSeek API direct, owner
ruling 2026-09-24; fallback `opencode-go/deepseek-v4.1-flash`) on high
reasoning. Run from the workspace root.
Reports: `slices/S10-armory-racks/<WorkerID>_report.md`, review `S10-R1_review.md`.
Gate/probe convention: `source ~/.profile && XDG_DATA_HOME=$(mktemp -d) godot
--headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200`
— **every probe/gate on a scratch store** (T-93 class), live store md5s checked
unchanged after. Bounded probes only, never a background process.

**Context discipline.** Read `docs/CONTRACTS.md` by section, never whole: its
top carries a generated index of every § and its line range (~2-3k tokens per
section). Reports cap at 120 lines, reviews at 150; cite `file:line`, never paste
source or gate logs.

**S10-A0 runs the interactive profile, not `VAJB_SLIM=1`** — its first method is
the live editor bridge (`godot-ai`, which the slim profile drops), the same
exception `AGENTS.md` documents for the asset worker that reimports through the
editor. Every later S10 worker runs slim.

## S10-A0 — the independent reproduction audit (measure only, fix nothing)

```bash
VAJB_WORKER_FILES="vajb-orbit/tests/,vajb-orbit/tools/" crush run "You are worker S10-A0, the independent reproduction audit of wave S10 (brief .agents/gen/slices/S10-armory-racks/S10_BRIEF.md — read it fully, then docs/design/STATION_HUB.md section 5.11 and 5.1, docs/gameplay/09_ship_slots_modules.md section 11, docs/CONTRACTS.md sections 17, 16, 21 and 9, and docs/design/UI_SPEC.md sections 3.9 and 3.10). The owner reports live: cannot select current gun battery in ARMORY, cannot drag equipped weapons to batteries, no preview of what ammo is used in battery, no battery stats, overall ARMORY does not seem to work. S8 passed this on a direct-handler probe (armory_panel.gd:1950 install_weapon, player_profile.gd:1316 fit_into_rack, set_battery_groups:1252, read [[0]] then [[0,1]]); that method bypasses the viewport drag routing and hit-testing, which is where the owner's failure must live. Task: reproduce the owner's symptoms through REAL input and report measured root causes at file:line — fix nothing. (1) Rack selection: click a bay, click a barrel chip, press keys 1 to 7 with the pane focused; report what changes in selected_rack() and the ember frame, and name the seam that would have to carry the input (today the only caller of set_selected_rack is armory_panel.gd:1583 _on_barrel_focused, connected at :1577, so an empty rack has no chip and no path). (2) Real drag: inject genuine InputEventMouseButton and InputEventMouseMotion through Input.parse_input_event so the Viewport's drag routing runs, from an inventory row onto an empty bay and a filled bay on at least two racks; report whether the drag starts, which Control receives the drop (Viewport.gui_get_hovered_control and gui_get_drag_data at the bay centre), and whether battery_groups() changes. (3) The per-battery readout: inventory the rack row's live Controls (text, visibility, rects) and say whether the owner's ammo preview and battery stats exist, are pinned and missing, or are not pinned anywhere (then it is an owner tick, not a build). (4) Reachability: confirm the station screen opens the pane and name every Control that swallows a click, with a mouse_filter audit of the drop zone and every ancestor and sibling, including D7's ConsoleWells chrome (armory_panel.gd:688). (5) A/B: run the same probe on a git worktree at the pre-restyle tree (12278d2^, before D7's close) and say whether D7's surface-only restyle broke the path or it was never wired. Prefer the live editor game through godot-ai (session_manage list, game_manage get_ui_elements to locate nodes, input_mouse and input_key to drive, game_eval to read state, editor_screenshot only at max_resolution 640 and only when a pixel is the only evidence) and use a headless real-input probe for the record. Deliver .agents/gen/slices/S10-armory-racks/S10-A0_report.md (120 lines max) with, per symptom, the verdict (reproduced / not reproduced / missing feature / regression), the exact Control and file:line seam, the bucket (1 implementer decides, 2 changes a pin or a file set, 3 owner call), the probe paths, and a closing section naming what the fix wave must touch. Hard rules: every probe on a scratch store (XDG_DATA_HOME from mktemp -d, and repoint save_path before any PlayerProfile boot), the live user:// profile is the owner's account so record its md5 pair before and after, every run bounded with --quit-after and self-quitting probes, never a background command, no game/ or ui/ writes, no fixes. Hard rules in the brief apply." -m deepseek/deepseek-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE"
```
