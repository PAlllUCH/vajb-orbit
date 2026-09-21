# Wave UI-chrome (code lane) — prompts

The fenced blocks are the exact `crush run` commands. Host: Linux, workspace
`/home/kamil-paluszkiewicz/VajbOrbit` (the Windows workspace root is the same tree at
`G:/Mój dysk/Projekty/Vajb Orbit`; `--cwd` takes the host's path). Model:
`deepseek/deepseek-v4-flash`, per `dispatch_coder.md`. Every command carries its
`VAJB_WORKER_FILES` prefix and is run as its own background shell job, polled until the
report file exists.

Run order: **W1 · W2 · W3 · W4 in parallel**, then **W5**, then **W6 only if W5 leaves
HIGH or MED findings**.

## W1 — D3 TextureButton size guard

```bash
VAJB_WORKER_FILES="vajb-orbit/ui/components/,vajb-orbit/ui/station/shipyard_panel.gd,vajb-orbit/ui/station/launch_panel.gd,vajb-orbit/ui/hud/hud.gd,vajb-orbit/tests/" \
  crush run "Read .agents/gen/ui_chrome_wave_task.md in full first - it is the law for this wave - then .agents/gen/playtest_fullloop_20260921.md section Defects for the measured numbers. You are W1 and you own defect D3 only: every slot plate is a TextureButton whose minimum size is driven by the texture native size, because no site sets ignore_texture_size. Set ignore_texture_size true at every plate site - ui/components/slot_button.tscn, ui/components/slot_button.gd configure, ui/station/shipyard_panel.gd _make_plate, ui/station/launch_panel.gd _make_plate, and the HUD slot instances in ui/hud/hud.gd - keeping the documented cell sizes 48 for weapon and 40 for cargo, and keeping the existing custom_minimum_size behaviour for callers. Then add a headless suite under vajb-orbit/tests/ that proves the layout no longer depends on the art size: with the current art in place, ui_slot_weapon is 880 by 876 and ui_slot_cargo is 873 by 864 on disk, the shipyard panel must measure inside a 1920 wide viewport - today it is 6184 by 1224 with the ship list at x minus 2393 - and the launch panel likewise - today 4781 wide with LaunchButton at x 3178 - and the hardpoint strip must report 7 cells of 48 px and the cargo strip 5 cells of 40 px. Measure the panel size directly in the test, not by eye. Report before and after numbers, the test names, and the gate count. Do not touch assets, the theme, tools/build_theme.gd, project.godot, addons, or docs. Run the gate headless with a bounded quit and write the result into your report. Write your report to .agents/gen/ui_chrome_w1_report.md." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## W2 — D4 stale ext_resource UIDs

```bash
VAJB_WORKER_FILES="vajb-orbit/game/game.tscn,vajb-orbit/game/player_ship.tscn,vajb-orbit/game/pickup.gd,vajb-orbit/game/sector.gd,vajb-orbit/game/sector_registry.gd,vajb-orbit/ui/screens/loading.tscn,vajb-orbit/ui/screens/main_menu.tscn,vajb-orbit/tests/" \
  crush run "Read .agents/gen/ui_chrome_wave_task.md in full first - it is the law for this wave. You are W2 and you own defect D4 only: two scenes carry stale ext_resource UIDs left by the asset re-layout, so the engine warns on every load and falls back to the text path. Measured: game/player_ship.tscn line 4 carries uid cmi25sgdnd7ga for ship_vanguard_side.png whose .import says c7myl1rn82g5b, and game/game.tscn lines 4 to 6 carry uids o68c15elst7g, c4l2b7bxc00k4 and bipbl3vgvqekw for env/tile/env_stars_layer1 to 3.png whose .import files say fv4vfbadcprt, b4nhnjtgrej5n and di3dmpv64ldaa. Fix each UID so it matches the asset import file, or drop the UID field and let the path resolve, whichever the engine writer prefers. Then re-check the L16 literal list in this wave brief - game/pickup.gd, game/sector.gd, game/sector_registry.gd, ui/screens/loading.tscn, ui/screens/main_menu.tscn - and confirm every literal still resolves; report any that do not, as an environment item, without editing assets. Prove it with a bounded headless run that loads both scenes and prints no stale UID warning, and paste the raw output in your report. Do not touch assets, the theme, project.godot, addons, or docs. Write your report to .agents/gen/ui_chrome_w2_report.md." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## W3 — D5 GDScript warning lint pass

```bash
VAJB_WORKER_FILES="vajb-orbit/autoload/,vajb-orbit/ui/screen.gd,vajb-orbit/ui/screens/station.gd,vajb-orbit/ui/station/refinery_panel.gd,vajb-orbit/game/exchange.gd,vajb-orbit/tests/" \
  crush run "Read .agents/gen/ui_chrome_wave_task.md in full first - it is the law for this wave. You are W3 and you own defect D5 only: one lint pass over the GDScript warnings the playtest session recorded. The exact list is INT_AS_ENUM_WITHOUT_CAST in autoload/settings_manager.gd lines 391, 400 and 405; SHADOWED_VARIABLE or SHADOWED_VARIABLE_BASE_CLASS in autoload/router.gd, autoload/audio_manager.gd, autoload/dialog_manager.gd, autoload/player_profile.gd and ui/screens/station.gd lines 348 and 407; UNUSED_SIGNAL in ui/screen.gd lines 7 to 9; an unused parameter in ui/station/refinery_panel.gd line 533; and SHADOWED_GLOBAL_IDENTIFIER in game/exchange.gd line 45 where the constant MineralCatalog shadows the global class. Fix each one without changing behaviour: for an unused signal, keep the signal and document the intended consumer rather than deleting a pinned interface, and check docs/CONTRACTS.md before touching any signature. Verify by re-reading the same line numbers and by a clean parse of every touched file, and keep the universal gate green with the same test count. Report each warning, its fix and the verification per item. Do not touch assets, the theme, project.godot, addons, or docs. Write your report to .agents/gen/ui_chrome_w3_report.md." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## W4 — D6 doc ticks

```bash
VAJB_WORKER_FILES="docs/gameplay/19_testing_notes.md,docs/CONTRACTS.md" \
  crush run "Read .agents/gen/ui_chrome_wave_task.md in full first - it is the law for this wave. You are W4 and you own defect D6 only, a docs pass with two edits and nothing else. First: docs/gameplay/19_testing_notes.md B2-3 still closes with the sentence about a tiny coder task plus a line in IMPLEMENTATION_PLAN section 9.8 follow-up, but the fix landed on 2026-09-21 and section 9.8 item 6 records it with the measured bindings; correct that stale sentence so it points at the landed evidence. Second: docs/CONTRACTS.md section 9 expected-count line still says passed equals 217 while the gate measured on this host on 2026-09-21 is passed equals 219 failed equals 0 with 16 suites listed; update that line to the measured number and date, and do not renumber anything else. Touch no other file, no code, no asset, no theme. Write your report to .agents/gen/ui_chrome_w4_report.md with the before and after text of both edits." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## W5 — reviewer (mandatory)

```bash
VAJB_WORKER_FILES="vajb-orbit/tests/,vajb-orbit/tools/" \
  crush run "Read .agents/gen/ui_chrome_wave_task.md in full first - it is the law for this wave - then the four reports ui_chrome_w1_report.md, ui_chrome_w2_report.md, ui_chrome_w3_report.md and ui_chrome_w4_report.md in .agents/gen/. You are W5, the mandatory reviewer. Verify, never trust. Re-run W1 layout probe byte-identically - same script, same art, same measurement - and re-measure every number the four workers reported: the shipyard panel size, the launch panel size, the hardpoint and cargo strip extents, the UID match for every ext_resource in game/game.tscn and game/player_ship.tscn against its .import file, the absence of each named warning at its named line, and the two doc edits. Grep the pinned signatures across every changed file and diff your findings against docs/CONTRACTS.md, not against the brief, to catch interface drift. Then tier every finding HIGH which blocks the wave, MED which gets one fixer pass, or LOW which rides to .agents/gen/LOW_BACKLOG.md, and state for each one the exact command that reproduces it and its raw output. Report the test gate count you measured yourself. Do not fix anything yourself. Write your report to .agents/gen/ui_chrome_w5_report.md." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## W6 — fixer (only if W5 leaves HIGH or MED findings)

```bash
VAJB_WORKER_FILES="<per-finding sets from the W5 report>" \
  crush run "Read .agents/gen/ui_chrome_w5_report.md in full - it is the authority on every finding - and .agents/gen/ui_chrome_wave_task.md for the wave rules. You are W6 and you fix only the HIGH and MED findings assigned to you, one pass. Re-measure each finding before and after your fix with the same command the reviewer used, and prove the fix by measurement rather than by reading your own diff. Keep the universal gate green and grow the test count if you add a test. Do not touch assets, the theme, tools/build_theme.gd, project.godot, addons, or docs. Write your report to .agents/gen/ui_chrome_w6_report.md with the per-finding before and after evidence." \
  -m deepseek/deepseek-v4-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```
