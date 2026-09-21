# Wave P2-B1 — the weapon fit surface — prompts

Fenced blocks are the exact `crush run` commands. Host: Linux, workspace
`/home/kamil-paluszkiewicz/VajbOrbit`. Each runs as its own background shell job,
polled until its report exists. Order: **D0 → W1 → W2 → R1 → F1 (only if R1
leaves HIGH or MED)**. Snapshot + commit (`verify_wave.py snapshot --name
p2b1_start`) before the first dispatch. **This wave runs after item 4 (P2-A)**
— its workers consume P2-A's pinned APIs and read its reports.

## D0 — the docs (runs first, alone)

```bash
VAJB_WORKER_FILES="docs/" \
  crush run "Read .agents/gen/p2b1_weapon_fit_wave_task.md in full first - it is the law for this wave - then docs/gameplay/09_ship_slots_modules.md sections 1, 2, 3.1, 4, 7 and 9, docs/gameplay/10_ship_acquisition.md sections 2, 5 and 6, docs/gameplay/08_ship_classes.md section 3, docs/design/STATION_HUB.md sections 5.1, 7, 10 and 12, and docs/CONTRACTS.md sections 8 and 11. You are D0 and you own documentation only. Transcribe, never design: give docs/design/STATION_HUB.md section 5.1 the MODULES section and the FITTED WEAPONS strip verbatim from the brief's section 3 - the six weapon rows in 09 section 3.1's order with their frozen costs and draw meta, the status and action state machine, the refusal wordings, and the focus order; add the module icon paths to section 7's art map; give docs/gameplay/10_ship_acquisition.md section 6 and docs/gameplay/09_ship_slots_modules.md section 4.8 the dated interim note that OUTFITTING sells the six weapon modules until the AUCTION module exists and the surface retires into it then; and land docs/CONTRACTS.md section 12 verbatim from the brief plus a section 10 changelog line. Do not touch code, assets, the theme or project.godot, and do not invent a number: every figure you write comes from the brief, from 09 section 3.1 or from 08 section 3. Write your report to .agents/gen/p2b1_d0_report.md listing each file, the section you changed, and the exact line that carries each pinned item." \
  -m opencode-go/deepseek-v4.1-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## W1 — the purchase seam

```bash
VAJB_WORKER_FILES="vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/" \
  crush run "Read .agents/gen/p2b1_weapon_fit_wave_task.md in full first - it is the law - then docs/CONTRACTS.md sections 8, 11 and 12 (D0 lands section 12), docs/gameplay/09_ship_slots_modules.md sections 3.1 and 4, docs/gameplay/10_ship_acquisition.md section 6, docs/gameplay/17_coder_handoff.md section 5, and the P2-A reports in .agents/gen/p2a_*_report.md, which are the authority on the APIs you build beside. You are W1 and you own one seam: PlayerProfile.buy_module(module_id, cost) exactly as the brief's section 3 pins it - refuse unknown or insufficient through the existing purchase_failed reasons, otherwise verify, spend, add_module(module_id, 1), emit profile_changed(modules), and write exactly one economy-log line. Do not reshape any existing method or signal; the inventory helpers, fits and save v4 already ship. Add tests for the successful buy round-trip (credits, inventory count, signal, log line) and for the insufficient and unknown refusals. Do not touch assets, the theme, project.godot, addons or docs. Keep the gate green at its measured count and grow it. Write your report to .agents/gen/p2b1_w1_report.md with the round-trip numbers and the raw test output." \
  -m opencode-go/deepseek-v4.1-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## W2 — the OUTFITTING panel

```bash
VAJB_WORKER_FILES="vajb-orbit/ui/station/outfitting_panel.gd,vajb-orbit/ui/station/outfitting_panel.tscn,vajb-orbit/tests/" \
  crush run "Read .agents/gen/p2b1_weapon_fit_wave_task.md in full first - it is the law - then docs/CONTRACTS.md sections 8, 11 and 12 (D0 lands section 12), docs/design/STATION_HUB.md sections 5.1, 10 and 12, docs/gameplay/09_ship_slots_modules.md sections 1, 2, 4 and 9, and the W1 report .agents/gen/p2b1_w1_report.md. You are W2 and you own the panel. Build the MODULES section and the FITTED WEAPONS strip exactly as STATION_HUB section 5.1 now reads and the brief's section 3 pins: six weapon rows in 09 section 3.1's order with their module icons, the fitted strip showing one line per W cell of the active hull with REMOVE on fitted lines, and the state machine BUY, INSTALL into the first empty W cell, SWAP with the displaced module returning to inventory, and REMOVE back to the inventory. Every install and swap passes through ShipFit.fit_legal and a refusal renders in the panel's own footer strip with the exact wordings - the power overload as 09 section 2's over-by format and the full-cells line - and nothing auto-removes. The panel never mutates state directly: it writes only through the profile's APIs and refreshes on profile_changed fits and modules. Add a test per state change: the buy, install, swap and remove round-trip across the Vanguard's three W cells, the power-overload refusal, the full-cells refusal, the mandatory set untouched, and the refresh driven by the signals. Do not touch assets, the theme, project.godot, addons or docs, and do not invent a number. Keep the gate green and grow it. Write your report to .agents/gen/p2b1_w2_report.md with the round-trip and refusal measurements and the raw test output." \
  -m opencode-go/deepseek-v4.1-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## R1 — reviewer (mandatory)

```bash
VAJB_WORKER_FILES="vajb-orbit/tests/,vajb-orbit/tools/" \
  crush run "Read .agents/gen/p2b1_weapon_fit_wave_task.md in full first - it is the law - then docs/CONTRACTS.md sections 8, 11 and 12, docs/gameplay/09_ship_slots_modules.md sections 1, 2, 3.1, 4, 7 and 9, docs/design/STATION_HUB.md section 5.1, and the reports p2b1_d0_report.md, p2b1_w1_report.md and p2b1_w2_report.md in .agents/gen/. You are R1, the mandatory reviewer. Verify, never trust: re-run W2's probe byte-identically and re-measure the buy, install, swap and remove round-trip and every refusal yourself, including the exact power-overload wording against 09 section 2's own format. Check every row's cost and draw against 09 section 3.1's table, every state transition against the brief's section 3, and the profile writes against the transaction law. Grep the pinned signatures of CONTRACTS sections 8, 11 and 12 across every changed file, confirm no section 13 row and no weapon damage, cadence, range or energy value moved, and confirm the mandatory engine and reactor set cannot be touched from this surface. Tier every finding HIGH which blocks the wave, MED which gets one fixer pass, or LOW which rides to .agents/gen/LOW_BACKLOG.md, each with the exact reproducing command and its raw output. Report the gate count you measured yourself. Do not fix anything. Write your report to .agents/gen/p2b1_r1_report.md." \
  -m opencode-go/deepseek-v4.1-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```

## F1 — fixer (only if R1 leaves HIGH or MED)

```bash
VAJB_WORKER_FILES="<per-finding sets from the R1 report>" \
  crush run "Read .agents/gen/p2b1_r1_report.md in full - it is the authority on every finding - and .agents/gen/p2b1_weapon_fit_wave_task.md for the wave rules. You are F1 and you fix only the HIGH and MED findings assigned to you, one pass. Re-measure each finding before and after with the reviewer's own command, keep the gate green and grow its count, and add or update a test per fix. Do not touch assets, the theme, project.godot, addons or docs. Write your report to .agents/gen/p2b1_f1_report.md with the per-finding before and after evidence." \
  -m opencode-go/deepseek-v4.1-flash --cwd /home/kamil-paluszkiewicz/VajbOrbit
```
