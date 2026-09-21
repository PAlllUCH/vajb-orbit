# Wave P2-A — Ship slot frames — prompts

Fenced blocks are the exact `crush run` commands. Host: Linux, workspace
`/home/kamil-paluszkiewicz/VajbOrbit`. Model `deepseek/deepseek-v4-flash`, per
`dispatch_coder.md`. Each runs as its own background shell job, polled until its
report file exists. Order: **D0 → W1 · W2 · W3 (parallel) → W4 · W5 (parallel) →
R1 → F1 (only if R1 leaves HIGH or MED)**.

Before the first dispatch: `python3 staging/verify_wave.py snapshot --name
p2a_start`, then `git add -A && git commit`.

## D0 — the docs pin (runs first, alone)

```bash
VAJB_WORKER_FILES="docs/" \
  crush run "Read .agents/gen/p2a_slot_frames_wave_task.md in full first - it is the law for this wave - then docs/gameplay/08_ship_classes.md sections 2, 3, 3.1, 3.2, 3.3 and 6, docs/gameplay/09_ship_slots_modules.md sections 1, 2, 3.7, 4, 5, 7, 8 and 9, and docs/gameplay/10_ship_acquisition.md section 2.3, which are already amended and are the numbers. You are D0 and you own documentation only. Transcribe, never design: land docs/CONTRACTS.md section 11 verbatim from section 3 of the brief, including the ShipFit, ModuleCatalog, PlayerProfile, PlayerState, HUD and SlotButton code blocks and the numbered rules that follow them, plus a section 10 Changelog line recording v0.2 and this wave. Then amend docs/design/STATION_HUB.md section 5.2 so its hardpoint-strip row and its meta row describe the new layout grid (a GridContainer of one cell per matrix cell, columns equal to the matrix width, a gap drawn as an empty cell, 48 px plates carrying the slot glyph, caption SLOT LAYOUT with cell and engine counts) and its stat rows become HULL, SHIELD, CARGO, ENGINES, SLOT CELLS; amend section 5.4's brief-row table with the ENGINES, HARDPOINTS and SLOT CELLS rows; add docs/design/IMPLEMENTATION_PLAN.md section 9.10 recording this phase's amendments in the pattern of sections 9.7 and 9.9 (the new files, the pinned tests that move, the amendments to sections 3.9 and 3.10); and amend docs/gameplay/17_coder_handoff.md so section 2 lists game/module_catalog.gd as built and section 3's fits shape reads slot_type -> Array[module_instance_id] with the layout index rule. Do not touch code, assets, the theme or project.godot, and do not invent a number: every figure you write comes from the brief or from the gameplay docs. Write your report to .agents/gen/p2a_d0_report.md listing each file, the section you changed, and the exact line that carries each pinned interface item." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## W1 — the frame data and the module catalogue

```bash
VAJB_WORKER_FILES="vajb-orbit/game/ship_fit.gd,vajb-orbit/game/module_catalog.gd,vajb-orbit/tests/" \
  crush run "Read .agents/gen/p2a_slot_frames_wave_task.md in full first - it is the law - then docs/CONTRACTS.md section 11 (D0 lands it), docs/gameplay/08_ship_classes.md sections 3, 3.1, 3.2 and 3.3, and docs/gameplay/09_ship_slots_modules.md sections 1, 3.7, 4, 5, 7, 8 and 9. You are W1 and you own the frame data. Implement section 3 of the brief's ShipFit additions exactly as pinned - SLOT_GRIDS as the nine matrices of 08 section 3.2, SLOT_TOKEN_KEYS, FIT_SLOT_KEYS, MANDATORY_SLOT_KEYS, ENGINE_MULT_CEILING 1.40, MOUNT_SPREAD, grid_rows, grid_size, grid_cells, grid_counts, slot_capacity, fit_legal, standard_fit, STANDARD_FITS, mount_offset - keeping resolve, fitted_ids, power_budget, STANDARD_FIT, HULLS and HANDLING backwards compatible, including acceptance of the legacy singular engine key and the resolution order that keeps weapons first. Create game/module_catalog.gd with the 32 rows copied verbatim from ShipFit.MODULES plus the pinned name table and the icon rule, and keep ShipFit.MODULES as the alias the existing callers and tests index. Add tests/test_ship_grids.gd covering every assertion listed in the brief's W1 row. Do not touch assets, the theme, project.godot, addons or docs, and do not invent a number. Keep the gate green and grow its count. Write your report to .agents/gen/p2a_w1_report.md with the per-hull derived counts table, the engine-sum arithmetic before and after, and the raw output of your new suite." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## W2 — profile fits, addressing and save v4

```bash
VAJB_WORKER_FILES="vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/" \
  crush run "Read .agents/gen/p2a_slot_frames_wave_task.md in full first - it is the law - then docs/CONTRACTS.md section 11 (D0 lands it), docs/gameplay/09_ship_slots_modules.md sections 4.5 and 9, docs/gameplay/17_coder_handoff.md section 3, and docs/gameplay/15_module_affixes.md section 6. You are W2 and you own the profile's fit storage. Implement the pinned API - fit_for, set_fit, set_fit_slot, clear_fit, base_module_id, module_count, add_module, take_module - with the normalisation rule that a v1 to v3 single-string fit becomes a one-element array padded to the hull's capacity, writes always persisting the array shape, and the save version bumped to 4 with MIN_READABLE_VERSION staying 1 so v1 to v3 files load clean and silently default. Keep the existing signals, add no new key, and keep every existing public method and its behaviour. Update tests/test_p1_profile.gd's save-version assertion to 4 and add tests for the round trip, the v2 and v3 migrations, capacity padding on a three-engine hull, the index addressing rule, and base_module_id resolving an instance through the modules dict and passing a base id through unchanged. Do not touch assets, the theme, project.godot, addons or docs. Keep the gate green and grow its count. Write your report to .agents/gen/p2a_w2_report.md with the migration evidence, the persisted shapes before and after, and the raw output of your new tests." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## W3 — the nine-hull roster

```bash
VAJB_WORKER_FILES="vajb-orbit/game/station_catalog.gd,vajb-orbit/tests/" \
  crush run "Read .agents/gen/p2a_slot_frames_wave_task.md in full first - it is the law - then docs/gameplay/08_ship_classes.md sections 2, 3 and 4, and docs/design/STATION_SPEC.md section 5.2 for the frozen stat lineage. You are W3 and you own the hull roster. Grow StationCatalog.SHIPS from four rows to all nine player hulls in the ladder order of 08 section 2 - fighter, vanguard, miner, trader, corvette, freighter, gunship, patrol, destroyer - using the frozen cost, hull, shield and cargo values from that table, hardpoints equal to its weapons column (2, 3, 2, 1, 4, 1, 5, 4, 7), preview set to res://assets/ships/ship_<hull>_side.png for each, and a one-line description in the existing voice and length. Add a test asserting nine rows in ladder order, that every preview path exists on disk, and that each row's hardpoints equals ShipFit.HULLS[id].weapons. Change nothing else in the catalogue and do not invent a price. Do not touch assets, the theme, project.godot, addons or docs. Keep the gate green and grow its count. Write your report to .agents/gen/p2a_w3_report.md with the nine rows as implemented and the raw output of your test." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## W4 — flight wiring (the active hull's own fit)

```bash
VAJB_WORKER_FILES="vajb-orbit/game/game.gd,vajb-orbit/game/player_ship.gd,vajb-orbit/game/player_state.gd,vajb-orbit/tests/" \
  crush run "Read .agents/gen/p2a_slot_frames_wave_task.md in full first - it is the law - then docs/CONTRACTS.md section 11 (D0 lands it) and sections 3, 4 and 7, docs/gameplay/09_ship_slots_modules.md sections 5, 7 and 9, and the W1 and W2 reports in .agents/gen/ which are the authority on the API you call. You are W4 and you own the launch path. Make game.gd resolve the ACTIVE HULL'S OWN fit instead of the single global STANDARD_FIT: read the profile's normalised fit through the new profile API, map each entry to a base module id, resolve with ShipFit.resolve, and fall back to ShipFit.standard_fit(hull_id) when the profile holds none or the hull is unknown - never write the profile from the flight scene. Add PlayerState.set_weapons and make setup, set_ammo, _seed_ammo and _file_ammo_report read the launched fit's weapon ids while the WEAPONS constant stays as the five-family default a fitless PlayerState still runs on. Push the launched hull's W cells to the HUD through the pinned set_hull_slots call, built from ShipFit.grid_cells plus the fit plus ModuleCatalog, and guard it the way the other HUD pushes are guarded so a HUD without the method stays inert. Add tests for a two-weapon Lancer fit and a three-weapon Vanguard fit, for a three-engine hull resolving the summed engine set rather than a product, for ammo seeding per fitted family, and for the empty-fit fallback path. Do not touch assets, the theme, project.godot, addons or docs. Keep the gate green and grow its count. Write your report to .agents/gen/p2a_w4_report.md with the resolved numbers per hull you exercised and the raw probe output." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## W5 — the layout consumers (station and HUD)

```bash
VAJB_WORKER_FILES="vajb-orbit/ui/station/shipyard_panel.gd,vajb-orbit/ui/station/shipyard_panel.tscn,vajb-orbit/ui/station/launch_panel.gd,vajb-orbit/ui/components/slot_button.gd,vajb-orbit/ui/hud/hud.gd,vajb-orbit/tests/test_ui_slot_layout.gd" \
  crush run "Read .agents/gen/p2a_slot_frames_wave_task.md in full first - it is the law - then docs/CONTRACTS.md sections 7 and 11 (D0 lands section 11), docs/gameplay/08_ship_classes.md section 3.3, docs/gameplay/09_ship_slots_modules.md section 8, and the W1, W3 and W4 reports in .agents/gen/. You are W5 and you own the display side of the layout. In the shipyard panel turn the fixed seven-plate hardpoint strip into a GridContainer built per selection from ShipFit.grid_cells of the selected hull - one cell per matrix cell, columns equal to the matrix width, a gap drawn as an empty cell with no plate, a slot cell a disabled 48 px plate carrying that slot's glyph from assets/icons/slot/icon_slot_<type>_48.png - with the caption SLOT LAYOUT plus cell and engine counts, the stat rows HULL, SHIELD, CARGO, ENGINES, SLOT CELLS and the list meta hull plus slots. In the launch panel add the ENGINES and SLOT CELLS brief rows. Add SlotButton.configure_cell without changing configure. In the HUD implement set_hull_slots and hull_slots exactly as pinned: rebuild the weapon grid from the cells array with columns equal to the smaller of the cell count and five, an empty cell drawing the dim slot glyph, a fitted cell its module icon, and a cell at index five or above marked not selectable. Then rewrite the three pinned sections of tests/test_ui_slot_layout.gd so the strip, the panel minima and the HUD cell count are read from ShipFit for the selected or active hull rather than from the literals seven and five, while keeping every guard property: ignore_texture_size at every plate site, the 48 px weapon and 40 px cargo cells, and a 4096 px plate that cannot grow a panel or the grid. Do not touch assets, the theme, project.godot, addons or docs. Keep the gate green and grow its count. Write your report to .agents/gen/p2a_w5_report.md with the measured grid size, column count and cell count per hull, the panel minima, and the raw output of the rewritten suite." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## R1 — reviewer (mandatory)

```bash
VAJB_WORKER_FILES="vajb-orbit/tests/,vajb-orbit/tools/" \
  crush run "Read .agents/gen/p2a_slot_frames_wave_task.md in full first - it is the law - then docs/CONTRACTS.md sections 2, 3, 7, 9 and 11, and all five worker reports p2a_d0_report.md, p2a_w1_report.md, p2a_w2_report.md, p2a_w3_report.md, p2a_w4_report.md and p2a_w5_report.md in .agents/gen/. You are R1, the mandatory reviewer. Verify, never trust: parse 08 section 3.2's nine matrices yourself, independently of W1's code, and compare the derived counts with 08 section 3's table cell by cell; run the gate and report the count you measured; re-measure the shipyard grid cells and columns per hull, the HUD cell count per hull and the launch brief rows from the shipped scenes rather than from the reports; prove the engine sum and the 1.40 ceiling with your own probe and show that a single engine resolves to the same figure the pre-wave code produced; drive a v2 and a v3 profile fixture through the new loader and show no data loss and no warning; and grep every pinned signature of CONTRACTS sections 2, 3, 7 and 11 across all changed files. Check explicitly that no matrix was tidied, that no number moved outside 08 section 3's marked rows, that the legacy singular engine key still resolves, that NPC hulls still read empty shapes without a warning, and that assets, the theme, project.godot and docs are untouched by code workers. Tier every finding HIGH which blocks the wave, MED which gets one fixer pass, or LOW which rides to .agents/gen/LOW_BACKLOG.md, each with the exact reproducing command and its raw output. Do not fix anything. Write your report to .agents/gen/p2a_r1_report.md." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## F1 — fixer (only if R1 leaves HIGH or MED)

```bash
VAJB_WORKER_FILES="<per-finding sets from the R1 report>" \
  crush run "Read .agents/gen/p2a_r1_report.md in full - it is the authority on every finding - and .agents/gen/p2a_slot_frames_wave_task.md for the wave rules. You are F1 and you fix only the HIGH and MED findings assigned to you, one pass. Re-measure each finding before and after with the reviewer's own command, keep the gate green and grow its count, and add or update a test per fix. Do not touch assets, the theme, project.godot, addons or docs. Write your report to .agents/gen/p2a_f1_report.md with the per-finding before and after evidence." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```
