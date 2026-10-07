# D17-P3 — in-game test review (S28 chrome fixes, live build)

Reviewer: D17-P3 · 2026-10-01 · godot-ai, run r47665660-19, project_run mode main.
Screenshots unavailable (reviewer model has no image input); every check was made
through get_ui_elements / game_eval state reads and logs_read. Route truncated by
an external cap — see Route log.

## Main menu (boot)

- [LOW] Boot lands on MainMenu with PLAY / OPTIONS / EXIT, version label "VAJB ORBIT v0.3" — menu is clean and hover/focus readout updates ("END THE SESSION" on EXIT). `node /MainMenu/SafeArea/Bands` · n/a
- [FIXED] Quit dialog copy is state-neutral: title "Quit Vajb Orbit?", body "Progress is saved.", buttons CANCEL / QUIT — no "unsaved progress will be lost" conditional, no leaked placeholder token. `node /root/Router/OverlayLayer/QuitConfirm/Content/TitleLabel,BodyLabel` · none needed
- [FIXED] Quit dialog opens with focus on CANCEL (safe default) and Space cancels it — loop cannot be quit by accident from the menu. `node .../QuitConfirm/.../ButtonRow/CancelButton` · none needed

## Settings (OPTIONS)

- [FIXED] Settings opens as a 4-tab overlay (GRAPHICS, AUDIO, CONTROLS, INTERFACE) with a BACK button in the header; GRAPHICS tab renders RESOLUTION / DISPLAY MODE / V-SYNC / RENDER SCALE / EFFECTS QUALITY rows with values ("1920 x 1080", "WINDOWED", "1.00x", "HIGH"). `node /root/Router/OverlayLayer/Settings/Panel/Margin/Layout` · none needed
- [FIXED] CONTROLS tab: Q and E are deconflicted in the base view — Q = TARGET NEXT, E = MINE; no other duplicate among W/S/A/D, Space, Ctrl, Shift, C, 1–5, F, H. `node .../CONTROLS/RebindScroll/RebindRows` · none needed
- [PARTLY] TURN LEFT / TURN RIGHT sit behind the "ADVANCED (STICK ACTIONS)" toggle at the CONTROLS tab footer — the toggle exists and is clickable, but I could not read the revealed rows before the route was cut (see Route log), so their bindings are unconfirmed. `node .../CONTROLS/AdvancedToggle` · re-run: toggle ADVANCED, dump RebindRows, confirm TURN LEFT/RIGHT appear with no Q/E collision
- [NOT OBSERVED] Worded conflict flag on a duplicate commit — the rebind→conflict-path was not exercised (route cut). `res://game/*` · next reviewer: commit Q onto STRAFE LEFT and read the footer/caption copy
- [NOT OBSERVED] One focus ring everywhere (no separate ember-box focus style) — no screenshots and no stylebox inspection were possible before the route was cut. `theme` · next reviewer: query `get_theme_stylebox("focus")` on a menu row, a settings row and a station row and diff them

## Station modules — NOT OBSERVED

- [NOT OBSERVED] EXCHANGE (HELD CR EACH VALUE headers, SELL ALL RAW disabled at zero raw, stepper default 1 with quantity on the button) — route cut before PLAY. · next reviewer: open EXCHANGE, read headers and stepper default
- [NOT OBSERVED] AUCTION shelf tag live count + restock; REFINERY inspector band clearing across module switches; the 7-tab sequence ×2; LAUNCH confirm strip copy and credits-box jitter on a balance change. · next reviewer: follow the route from PLAY
- [NOT OBSERVED] Undock → fly → fire → dock → reopen two modules. · next reviewer: same

## Parallel-builder notes (artifacts, not S28 faults — logged once)

- S29-B1 was coding in this tree during the pass, as briefed. Two tool-side events cost restarts but were not game faults: my own game_eval errors (a Node-not-found on a scene-relative path, then a parse error) each parked the game in a remote-debugger break — recovery is `project_manage stop` + relaunch. `godot-ai EVAL_*` · none needed
- Editor log during the pass shows only pre-existing script warnings (audio_manager.gd:983 shadowed "name", weapons.gd:687 shadowed "racks", auction.gd:642/658 integer division) — no S28-area errors. `res://autoload/audio_manager.gd:983`, `res://game/weapons.gd:687`, `res://game/auction.gd:642` · none needed

## Route log

1. project_run main → boot OK to MainMenu.
2. EXIT click → QuitConfirm read (state-neutral) → Space cancelled.
3. OPTIONS click → Settings overlay read → CONTROLS tab selected via current_tab.
4. CONTROLS rows dumped; Q/E verified deconflicted in base view.
5. ADVANCED toggle clicked; row re-dump blocked (game_eval list results serialized truncated — only the first child returned, so the revealed rows could not be read); then a compile error in one eval parked the game at a debugger break; one stop/relaunch was already spent earlier on the same class of issue. Route stopped here per the finish-now instruction.
6. Game stopped cleanly; no godot game process left running (only the godot-ai server, the LSP bridge and S29-B1's own workers remain).

## Verdict per S28 acceptance area

- Quit dialog copy state-neutral: **FIXED** (read live: "Quit Vajb Orbit?" / "Progress is saved.").
- CONTROLS tab Q/E deconfliction: **FIXED** (base view; Q=TARGET NEXT, E=MINE, no duplicates).
- TURN LEFT/RIGHT behind ADVANCED: **PARTLY** (toggle exists and is labelled correctly; revealed contents unconfirmed).
- Worded conflict flag on duplicate commit: **NOT FIXED** (not exercised this pass).
- One focus ring everywhere: **NOT FIXED** (not observable this pass — no image input; not inspected).
- EXCHANGE / AUCTION / REFINERY / tab-cycle / LAUNCH / flight areas: **NOT FIXED** (not reached; no evidence either way).
