# S24_prompts.md — dispatch lines (one per worker; run in the brief's order)

**Models (the owner's 2026-10-03 roster):** builders run
`hyper/deepseek-v4.1-flash` at `--reasoning-effort xhigh` (that route's top rung;
its ladder is low/high/xhigh, not max); the reviewer runs `hyper/glm-5.3-flash`
at `--reasoning-effort max`. `deepseek/deepseek-flash` is the same model on the
DeepSeek route if the Hyper quota throttles — say so before switching.

Run order **B1 → B2 → R1 → (F1 only on HIGH/MED)**. B1 and B2 are strictly
sequential (both hold `vajb-orbit/game/game.gd`). Launch each with
`run_in_background: true` and **wait on it** (`job_output`, `wait: true`); a
wedged worker (0 sockets, frozen I/O) is killed with python SIGKILL — wrapper
AND inner pid — then re-dispatched; re-check `git status` and the report file.

**Before the first dispatch** (the five-piece is committed):

```bash
cd "$VAJB_WORKSPACE" \
  && python3 staging/verify_wave.py snapshot --name s24_start \
  && git tag s24_start
```

## S24-B1 — the station entity, identity, the service matrix, the price law (A1+A2)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/station_registry.gd,vajb-orbit/game/station_registry.gd.uid,vajb-orbit/game/station_catalog.gd,vajb-orbit/game/repairs.gd,vajb-orbit/game/exchange.gd,vajb-orbit/game/game.gd,vajb-orbit/autoload/player_profile.gd,vajb-orbit/ui/screens/station.gd,vajb-orbit/ui/station/overview_panel.gd,vajb-orbit/ui/station/launch_panel.gd,vajb-orbit/ui/station/armory_panel.gd,vajb-orbit/ui/station/fitting_panel.gd,vajb-orbit/tests/test_s24_world.gd,.agents/gen/slices/S24-world-identity/S24-B1_report.md' \
     crush run "You are worker S24-B1 on the Vajb Orbit workspace, wave S24 world identity, builder 1 of 2. Read .agents/gen/slices/S24-world-identity/S24_BRIEF.md end to end, then SLICE.md - section 4's eight rules bind every line you write - then the 2026-10-08 blocks in docs/gameplay/14_station_services.md and docs/gameplay/12_factions.md, and STATION_HUB.md section 15.5 with its landing note. Task: land A1 and A2 exactly. A1: create game/station_registry.gd holding the nine rows of 14's 2026-10-08 block - id, sector, kind primary or outpost, faction, the W3 name and character verbatim, and the section 1 and section 8 service matrix, where the Concord primaries offer no arena, the Choir primaries offer no insurance, and the three outposts offer only section 8's contracts, bounty and vault tier one. Add the docked-station seam to autoload/player_profile.gd beside docked_faction - a transient docked_station accessor and setter, no save key, no save-version change - filed by game.gd's dock path next to the faction filing. The station screen's header plate already ships: fill StationName and StationLocation from the row's name and character instead of station.tscn's placeholder strings, and delete the dead has_method fallback in _docked_faction that names a method which exists nowhere. OVERVIEW block four's rows read the docked station's matrix - an unavailable service keeps its label at button_disabled plus the section 1 or section 8 reason caption, per UI_SPEC section 12.5's A5.5 test: a state change may mutate colour, modulate and draw only, never a box - and the vault read resolves the docked station's own record instead of summing every station. A2: the price law of 12's 2026-10-08 block, V1 and V2 and V6. One owner - the registry's price_factor and apply_price - called where a figure is read: the repair fee, the ammo pack cost, the hull list price, and the module list price in the armory and fitting panes. Order is fixed: the catalogue list, then one plus band delta minus tech discount, then the hot row's discount last. The band delta is plus 0.10 at Shunned, 0, minus 0.05 at Trusted, minus 0.10 at Champion. The tech discount is 0.15 for the station faction's own module families and 0 otherwise, added to the band, not multiplied, so a Champion of the Choir on a Choir family reads 0.75 of list. The Meridian commission reads 1.5 percent at a Meridian station and 2 percent elsewhere, keeping the 10 CR floor and the ammo exemption exactly as shipped. The exchange's own quotes take no band multiplier. shelf_bias returns 2.0 for the owner's own tech families and 1.0 otherwise. Docs and every autoload file except player_profile.gd are read-only. New suite tests/test_s24_world.gd with one row per probe above; the headless gate twice on fresh scratch XDG_DATA_HOME stores, both SUMMARY lines recorded. Write slices/S24-world-identity/S24-B1_report.md from the REPORT template, 120 lines maximum, answering A1 and A2 with cites and tabling every new value with its reversal and tick." \
     -m hyper/deepseek-v4.1-flash --reasoning-effort xhigh --cwd "$VAJB_WORKSPACE" \
  > /tmp/s24_b1.log 2>&1
```

## S24-B2 — the bands, the standing effects, the auction flavour, the nebula (A3–A5)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/sector_registry.gd,vajb-orbit/game/sector.gd,vajb-orbit/game/npc_registry.gd,vajb-orbit/game/auction.gd,vajb-orbit/game/game.gd,vajb-orbit/ui/station/auction_panel.gd,vajb-orbit/tests/test_s24_bands.gd,.agents/gen/slices/S24-world-identity/S24-B2_report.md' \
     crush run "You are worker S24-B2 on the Vajb Orbit workspace, wave S24 world identity, builder 2 of 2, running after builder 1 - re-read game/game.gd before you edit it, because B1 changed the dock path. Read .agents/gen/slices/S24-world-identity/S24_BRIEF.md end to end, then SLICE.md - section 4's eight rules bind every line - then the 2026-10-08 blocks in docs/gameplay/12_factions.md, docs/gameplay/13_heat_bounty.md and docs/gameplay/11_galactic_map.md, plus their 2026-09-27 P3 blocks. Task: land A3, A4 and A5 exactly. A3, the standing effects and the auction flavour, V3 to V7. contracts_visible reads standing above minus eleven. At Known and above the restock rolls one guaranteed hot row plus a 50 percent chance of a second hot row, both at the shipped hot price, the roll riding the restock's own seeded RNG. At Trusted the shelf's first rolled module slot is reserved: it comes off the docked sector's tier band instead of the ordinary one-two-three weights, and the shelf's size stays six hulls plus twenty modules - no extra row. The station owner's own tech families weight 2.0 in the rolled draw through the registry's shelf_bias. insurance_multiplier reads 0.8 at Champion and 1.0 elsewhere as a seam only. The minus 51 dock refusal and the clean-heat Outlaw's gate ticket both still hold. A4, the per-sector bands: each sector row carries hostile_band from R-S24-2 verbatim - sectors one and two pirate only, three and four pirate and swarmer, five and six swarmer, sibelon and pirate, seven pirate and swarmer - the row's order is the fill order, densities stay section 4's, hunters stay heat-driven map-wide, and the global HOSTILE_FILL stops being the band source. A5, the nebula: the sector row carries clouds, zero to two rolled on the sector's own seeded RNG with radius 900 and centres at least 1500 units from the arena centre, drawn by the cloud node itself in the Void Haze wash at 15 percent alpha, and while the ship is inside one the lock range, the POI scan range and the minimap radius all read 0.5 while the player's hull carries the 15 percent tint - the player's own zoom state is untouched, the factor is applied at the push to the HUD, so leaving the cloud restores the exact radius. Probe both directions: outside a cloud every one of the three reads the shipped value exactly. Docs are read-only. New suite tests/test_s24_bands.gd with one row per probe; the headless gate twice on fresh scratch XDG_DATA_HOME stores, both SUMMARY lines recorded. Write slices/S24-world-identity/S24-B2_report.md from the REPORT template, 120 lines maximum, answering A3 to A5 with cites and tabling every new value with its reversal and tick." \
     -m hyper/deepseek-v4.1-flash --reasoning-effort xhigh --cwd "$VAJB_WORKSPACE" \
  > /tmp/s24_b2.log 2>&1
```

## S24-R1 — mandatory review (after B1 and B2 report)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S24-world-identity/S24-R1_review.md' \
     crush run "You are worker S24-R1, the mandatory reviewer of wave S24 - brief .agents/gen/slices/S24-world-identity/S24_BRIEF.md. Diff findings against the brief's section 5 extract and the 2026-09-27 and 2026-10-08 blocks it cites, never against the builders' reports. Grade A1 to A6 first, re-measuring yourself on fresh scratch stores with a byte-identical replay. Check the nine registry rows against 14's section 1 and section 8 matrix - the Concord primaries' missing arena, the Choir primaries' missing insurance, the outposts' three - and that the header plate shows the row's name and character at three different stations. Check the price law in both directions: a Shunned buyer's repair fee and module list price at plus ten percent, a Champion's at minus ten, the additive stack reading 0.75 on a Choir family at a Choir station, the Meridian commission at 1.5 percent and 2 percent elsewhere, and the exchange's own quotes unchanged by standing. Check every band row, the hot pair's seeded roll, the reserved slot leaving the shelf at six plus twenty, shelf_bias, the insurance seam, the minus 51 dock refusal beside a clean-heat Outlaw's gate ticket, each sector's hostile band with section 4's densities intact, and the three cloud readings inside and outside a cloud. Look for the seams the builders leave unwired by measurement, never by trust - the profile seam the station screen reads, the registry accessors the auction and the panes call, and the cloud check in the game scene. An unlisted gate row that moved, a pinned value that moved, or a read site still calling the catalogue directly is HIGH. Update docs/CONTRACTS.md: a new section 24 pinning this wave's interface - the registry accessors, the profile seam, the two sector row keys, the price order - plus the section 9 measured block and the section 10 changelog entry, at the next free rows read at write time. Note in the review that section 9's newest block was S30's 1089 while the wave's baseline measured 1152, and correct the figure. Write slices/S24-world-identity/S24-R1_review.md from the REVIEW template, 150 lines maximum, findings S24-B1 or S24-B2 with F numbers, a tier and one evidence line each, and LOW rows at the next free ids read from .agents/gen/_state/LOW_BACKLOG.md at write time. Never fix code. Bounded probes only." \
     -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE" \
  > /tmp/s24_r1.log 2>&1
```

## S24-F1 — fixer (only if R1 leaves HIGH or MED)

```bash
cd "$VAJB_WORKSPACE" && source ~/.profile \
  && VAJB_SLIM=1 VAJB_WORKER_FILES='vajb-orbit/game/,vajb-orbit/ui/,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md,.agents/gen/slices/S24-world-identity/' \
     crush run "You are worker S24-F1, the fixer of wave S24 - brief .agents/gen/slices/S24-world-identity/S24_BRIEF.md, review .agents/gen/slices/S24-world-identity/S24-R1_review.md. Fix ONLY the HIGH and MED findings at their named file:line; adjust tests only where a fix changes what is proven. No LOW items, no refactors, no pinned value changed. Re-run the gate twice on fresh scratch stores and write slices/S24-world-identity/S24-F1_report.md with a finding-by-finding disposition and both gate lines." \
     -m hyper/deepseek-v4.1-flash --reasoning-effort xhigh --cwd "$VAJB_WORKSPACE" \
  > /tmp/s24_f1.log 2>&1
```

Never end the session while a worker is in flight; read each worker's report
file when its process exits (the logs are narration only).

## Handoff (paste at this item's turn)

```text
Read .agents/gen/dispatch_coder.md and execute queue item 30 only — S24 world identity. Brief: .agents/gen/slices/S24-world-identity/S24_BRIEF.md. Prompts: .agents/gen/slices/S24-world-identity/S24_prompts.md. Snapshot + commit before the first dispatch, run B1 → B2 → R1, and the fixer only if the review leaves HIGH or MED. Stop before item 31. Close out per the brief's close-out section (gate re-run, verify_wave.py verify --baseline s24_start, WAVEBOARD update, wave-boundary commit), then report back: the measured gate count, the builders' per-deliverable numbers, the reviewer's findings by tier, and the owner ticks.
```
