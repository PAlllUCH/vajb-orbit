# Wave P2-B proper — the fitting panel — prompts

Fenced blocks are the exact `crush run` commands. Host: Linux, workspace
`/home/kamil-paluszkiewicz/VajbOrbit`. Each runs as its own background shell job,
polled until its report exists (a `crush run` prints only assistant text — poll the
report file and the process tree, never the log's length). Order: **D0 → W1 → W2 →
W3 → R1 → F1 (only if R1 leaves HIGH or MED)**. W2 and W3 are disjoint and may run
in either order, never simultaneously. Snapshot + commit before the first dispatch:

```bash
python3 staging/verify_wave.py snapshot --name p2b_proper_start && \
  git add -A && git commit -m "Give the station a fitting panel to install modules cell by cell" || true
```

Model: `opencode-go/deepseek-v4.1-flash` (owner instruction, 2026-09-22).

## D0 — the docs (runs first, alone)

```bash
VAJB_WORKER_FILES="docs/" \
  crush run "Read .agents/gen/p2b_proper_wave_task.md in full first - it is the law for this wave - then docs/design/STATION_HUB.md sections 3, 5.1, 5.2, 5.3, 5.4, 7, 10 and 12, docs/gameplay/09_ship_slots_modules.md sections 1, 2, 3, 4, 7 and 8, docs/gameplay/10_ship_acquisition.md sections 2 and 6, docs/gameplay/15_module_affixes.md section 6, and docs/CONTRACTS.md sections 8, 11 and 12. You are D0 and you own documentation only. Transcribe, never design. Rewrite docs/design/STATION_HUB.md section 5.3 as FITTING verbatim from the brief's section 3.2 - the rail swap from UPGRADES with the retirement and its reversal recorded, the SLOT LAYOUT grid reusing the shipyard's own recipe with selectable cells, the OWNED MODULES rows, the FIT/SWAP/SELECT A CELL action states, the power meter's three forms, the three pinned refusal wordings, the hover line and the focus order - give section 5.4 the REFUEL and RECHARGE rows of the brief's section 3.3, give section 5.2 the hover line, and note in section 7.1's art map that the FITTING rail entry reuses the retired entry's icon. Give docs/gameplay/09_ship_slots_modules.md section 4 the per-slot fitting rules the brief's section 3 fixes (the composed install and remove, the mandatory cell never emptied, legality previewed through fit_legal and re-checked on commit), section 7 the note that the fitting surface is FITTING, and section 4.8's interim note the pointer. Give docs/gameplay/10_ship_acquisition.md section 6's interim note FITTING as the install surface beside OUTFITTING's shop. Give docs/gameplay/15_module_affixes.md section 6 a dated note that affixes are the next wave and this one's inventory aggregates by id. Land docs/CONTRACTS.md section 13 verbatim from the brief's section 3 - the profile pin with SAVE_VERSION 5, LEGACY_UPGRADE_MODULES, FIT_MANDATORY_KEYS, EVENT_FIT_MODULE, fit_module_at, clear_fit_slot, retire_legacy_upgrades, and the five rules - plus a section 10 changelog line (v0.5). Do not touch code, assets, the theme or project.godot, and do not invent a number: every figure you write comes from the brief, from 09's tables or from 12's. Write your report to .agents/gen/p2b_proper_d0_report.md listing each file, the section you changed, and the exact line that carries each pinned item." \
  -m opencode-go/deepseek-v4.1-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## W1 — the profile and the retirement

```bash
VAJB_WORKER_FILES="vajb-orbit/autoload/player_profile.gd,vajb-orbit/game/station_catalog.gd,vajb-orbit/tests/" \
  crush run "Read .agents/gen/p2b_proper_wave_task.md in full first - it is the law - then docs/CONTRACTS.md sections 8, 11, 12 and 13 (D0 lands section 13), docs/gameplay/09_ship_slots_modules.md sections 4 and 7, and docs/gameplay/10_ship_acquisition.md section 6. You are W1 and you own the profile's fitting transactions and the legacy retirement. Land the brief's section 3.1 exactly: SAVE_VERSION 5 with the load path calling retire_legacy_upgrades when the file's version is below 5, LEGACY_UPGRADE_MODULES with the six-row table, FIT_MANDATORY_KEYS, EVENT_FIT_MODULE, fit_module_at and clear_fit_slot with every guard the pin names and the displacement-before-take ordering, and retire the legacy surface completely - the six rows and upgrade(), upgrade_ids() in game/station_catalog.gd, and has_upgrade, installed_upgrades, install_upgrade and the upgrades record in the profile - with no dead branch left behind. Add tests: a v4 fixture with all six upgrades installed loads as six inventory modules and no upgrade records and a second migrate call returns 0; the composed install targets the cell it is given; a swap hands the displaced module back; a mandatory cell refuses with no write; an unowned module refuses; an over-budget candidate refuses before any write; the economy log carries one FIT_MODULE line per successful transaction. Do not reshape any other API or signal. Do not touch assets, the theme, project.godot, addons or docs. Keep the gate green at its measured count and grow it. Write your report to .agents/gen/p2b_proper_w1_report.md with the migration and transaction numbers and the raw test output." \
  -m opencode-go/deepseek-v4.1-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## W2 — the FITTING pane

```bash
VAJB_WORKER_FILES="vajb-orbit/ui/station/fitting_panel.gd,vajb-orbit/ui/station/fitting_panel.tscn,vajb-orbit/ui/station/upgrades_panel.gd,vajb-orbit/ui/station/upgrades_panel.tscn,vajb-orbit/ui/screens/station.gd,vajb-orbit/tests/" \
  crush run "Read .agents/gen/p2b_proper_wave_task.md in full first - it is the law - then docs/design/STATION_HUB.md sections 5.1, 5.2, 5.3 (D0 lands it), 10 and 12, docs/CONTRACTS.md sections 11, 12 and 13, docs/gameplay/09_ship_slots_modules.md sections 4, 7 and 8, and the W1 report .agents/gen/p2b_proper_w1_report.md. You are W2 and you own the pane. Build ui/station/fitting_panel.gd and .tscn exactly as STATION_HUB section 5.3 now reads: the SLOT LAYOUT grid of the active hull reusing shipyard_panel.gd's own plate recipe from ShipFit.grid_cells with selectable cells, the OWNED MODULES rows ordered by ShipFit.FIT_SLOT_KEYS then catalogue order with the SLOT and DRAW meta and OWNED x n, the FIT and SWAP and SELECT A CELL action states writing only through fit_module_at and clear_fit_slot, the power meter in its idle and candidate and over-budget forms, the three pinned refusal wordings in the footer strip, the hover and selection line, the empty state, and the focus order. Swap the rail: ui/screens/station.gd's Module.UPGRADES becomes Module.FITTING with the FITTING label and the retired entry's icon and position, and delete ui/station/upgrades_panel.gd and .tscn. The pane never mutates directly: it reads fit_for, module_count, modules and ShipFit, and requests the profile. Add tests: the grid renders the active hull's cells with gaps, a per-cell install lands on the cell it was given, the swap returns the displaced module, a mandatory cell refuses with the exact pinned wording, the meter's numbers equal fit_legal's power dictionary, and profile_changed drives the refresh. Do not touch assets, the theme, project.godot, addons or docs, and do not invent a number or a string. Keep the gate green and grow it. Write your report to .agents/gen/p2b_proper_w2_report.md with the per-state measurements and the raw test output." \
  -m opencode-go/deepseek-v4.1-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## W3 — the shipyard hover and the LAUNCH services

```bash
VAJB_WORKER_FILES="vajb-orbit/ui/station/shipyard_panel.gd,vajb-orbit/ui/station/launch_panel.gd,vajb-orbit/tests/" \
  crush run "Read .agents/gen/p2b_proper_wave_task.md in full first - it is the law - then docs/design/STATION_HUB.md sections 5.2, 5.4 (D0 lands them), 10 and 12, docs/gameplay/09_ship_slots_modules.md sections 4 and 7, and vajb-orbit/game/repairs.gd. You are W3 and you own the two smaller deliverables of the owner's four requests. First, give the shipyard's layout plates the hover line the brief's section 3.2 pins - hovering a cell shows its slot type, the selected hull's fitted module in that cell or EMPTY, and how many of it the account owns, reading fit_for and module_count - without changing the plates' size, glyph, separation or the caption. Second, give the LAUNCH pane the REFUEL and RECHARGE rows of the brief's section 3.3, calling Repairs.refuel and Repairs.recharge for the active hull and rendering the service's own result or refusal in the pane's status line, with no price and no credits moved. Add tests: the hover line's text for a fitted cell, an empty cell and a hull the account does not own; refuel success, recharge success, and the full-tank refusal rendered. Do not touch assets, the theme, project.godot, addons or docs, and do not invent a number or a string beyond the services' own. Keep the gate green and grow it. Write your report to .agents/gen/p2b_proper_w3_report.md with the hover and service measurements and the raw test output." \
  -m opencode-go/deepseek-v4.1-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## R1 — reviewer (mandatory)

```bash
VAJB_WORKER_FILES="vajb-orbit/tests/,vajb-orbit/tools/" \
  crush run "Read .agents/gen/p2b_proper_wave_task.md in full first - it is the law - then docs/CONTRACTS.md sections 8, 11, 12 and 13, docs/design/STATION_HUB.md sections 5.2, 5.3 and 5.4, docs/gameplay/09_ship_slots_modules.md sections 4 and 7, and the reports p2b_proper_d0_report.md, p2b_proper_w1_report.md, p2b_proper_w2_report.md and p2b_proper_w3_report.md in .agents/gen/. You are R1, the mandatory reviewer. Verify, never trust: build the v4 migration fixture yourself and re-measure the six-upgrade conversion and its idempotence; re-run W1's, W2's and W3's probes byte-identically; re-measure the per-cell install, the swap's displaced-module return, the mandatory refusal with its exact wording, the meter's arithmetic against ShipFit.fit_legal, the rail swap (FITTING present, UPGRADES gone from the rail, the catalogue and the panel), the shipyard hover line and both service calls including the full-tank refusal; confirm every string and number you can check against 09 and the pin; grep CONTRACTS sections 11, 12 and 13 across every changed file for drift and confirm no 09 or 08 value moved. Every Godot run must be bounded and every probe you write must carry its own hard iteration bound - a probe with an unbounded loop wedged this queue twice on 2026-09-22 (L82). Tier every finding HIGH which blocks the wave, MED which gets one fixer pass, or LOW which rides to .agents/gen/LOW_BACKLOG.md, each with the exact reproducing command and its raw output. Report the gate count you measured yourself. Do not fix anything. Write your report to .agents/gen/p2b_proper_r1_report.md." \
  -m opencode-go/deepseek-v4.1-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## F1 — fixer (only if R1 leaves HIGH or MED)

```bash
VAJB_WORKER_FILES="<per-finding sets from the R1 report>" \
  crush run "Read .agents/gen/p2b_proper_r1_report.md in full - it is the authority on every finding - and .agents/gen/p2b_proper_wave_task.md for the wave rules. You are F1 and you fix only the HIGH and MED findings assigned to you, one pass. Re-measure each finding before and after with the reviewer's own command, keep the gate green and grow its count, and add or update a test per fix. Do not touch assets, the theme, project.godot, addons or docs; do not fix any LOW. Every Godot run bounded, every probe with its own hard bound. Write your report to .agents/gen/p2b_proper_f1_report.md with the per-finding before and after evidence." \
  -m opencode-go/deepseek-v4.1-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```
