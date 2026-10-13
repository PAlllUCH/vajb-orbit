# dispatch_coder.md — the code-lane queue of record

Purged and regenerated 2026-10-12 (D24 closed; live items only — the closed
items 31–38 and the superseded handoff live verbatim in
`_archive/dispatch_done_2026-10-12.md`, the earlier done rows in
`_archive/dispatch_coder_done_2026-10-07.md` and `_archive/dispatch_done_2026-10-08.md`,
the wave recaps in `MASTER_REPORT.md` §6). Execute **one item per order**, close
out per the brief's close-out section.

**Design law (P4):** every item below implements D24's landed amendments —
`docs/design/STATION_HUB.md` §23 (P44–P54 + the §23.10 tick table + the §23.11
supersession ledger), `UI_SPEC.md` §17/§18 (A4–A9), `AUDIO_SPEC.md` §8.7
(AUDIO-4/5), `04_refinery.md` §9 (R9–R12), `07_crafting.md` §6 (C1–C10),
`10_ship_acquisition.md` §3.5. A worker who believes a number is wrong reports
it and leaves it; every unticked value implements at its PROPOSED value (the
S19 precedent).

**File-collision law:** two waves never hold one file (nor the same `test_*`
prefix, nor one `staging/` driver). One live session per workspace (L82).
**Wave anatomy:** docs-first five-piece → `verify_wave.py snapshot` + commit
→ builders → mandatory review → fixer only on HIGH/MED → close-out (gate ×2
hermetic, `verify --baseline`, CONTRACTS §9/§10 sequenced with any parallel
lane, `build_code_map.py`, WAVEBOARD, wave-boundary commit).

**`build_code_map.py` in the close-out (adopted 2026-10-08, S24's close-out).** A
wave that adds or renames files leaves `docs/CODE_MAP.md` stale; S24's new
`game/station_registry.gd` plus its two suites proved it (22 changed map lines).
The step is law from this wave on; reversal: drop it from this paragraph, the
AGENTS.md handoff template and the slice briefs' close-out sections. **Provenance,
recorded so the guard stays honest:** S24-F1 added it out of scope, through bash,
undisclosed; the developer session re-authored it here with its rationale and its
reversal, so the law changed by a ruling and not by an implementer.

**Model roster (owner, 2026-10-03, shell-v2 round):** code runs
`hyper/deepseek-v4.1-flash`, heavy design runs `xiaomi/mimo-v2.6-pro`, review
runs `hyper/glm-5.3-flash` — every run at the provider's max reasoning effort
(mimo's enum caps at `high`, measured 2026-10-03). Nothing heavier without
asking the owner first. **Owner directive (2026-10-12): don't spawn on
`hyper/glm-5.3` — `xiaomi/mimo-v2.6-pro` @ high takes its slot** (D24's review
and fixer ran there); the directive as given names `glm-5.3`, so the flash-tier
reviewer stands until the owner widens it.

## Queue

| # | Wave | Item | What | Status |
|---|---|---|---|---|
| 46 | S42 | The OVERVIEW 3×3 grid rework | STATION_HUB §23.1 **P44–P47** + **T-184**: the deck becomes one 3×3 grid of nine module buttons (ARMORY, REFINERY, EXCHANGE, AUCTION, SHIPYARD, LAUNCH, CONTRACTS, INSURANCE, VAULTS; `TILE_MIN` (240, 120), separation 16, the 752/756 and 620/633 arithmetic), the P25 service rows retire, the hull block keeps block 3 of the four-block deck, flat Tokens tile chrome, and the two raster glyphs modulate `text_caption` (the SVG remaster stays staged). **T-189** rides: re-measure the grid seat before it lands. `test_s40_legibility.gd`'s tile rows are the developer's bucket-2 re-cut. Files: `ui/station/overview_panel.gd` (+ `ui/screens/station.gd` only if the four-block deck reaches the host). | **done 2026-10-12** — gate 1330 → **1341/0 ×2**, verify clean vs `s42_start`; T-184/T-187/T-189/T-162 closed; 3 LOW → T-191–T-193; the S41 chrome tokens re-present on TICKS |
| 47 | S43 | The armory equipped list + its buy doors | STATION_HUB §23.4 **P49**: one EQUIPPED row per fitted module/weapon (slot cell id + name + one 09 §3 stat line verbatim), grid order, seated under CELL INFO in FIT CELLS' left sector; row press selects that cell. UI_SPEC §17 **A4–A6**'s ammo and module-buy doors wired at their armory seats. Files: `ui/station/armory_panel.gd`/`.tscn`. | queued — brief pending (the brief loop) |
| 48 | S44 | Exchange bulk sell | STATION_HUB §23.7 **P53**: `CheckChip` 24×24 bulk set (state by frame + own-child-rect mark), `MARK ALL`/`CLEAR`, `SELL MARKED` at 56 px in the N48/N49 `TradeBox` stack under `SELL`, the marked read summed from `Exchange.quote`, the per-row 56 px SELL plate retires (INSPECT stands). T-175's two EXCHANGE surfaces (the `YOUR HOLD` band, the footer) and **T-190** (name the check mark's ink) ride. Files: `ui/station/exchange_panel.gd`/`.tscn` (+ `game/exchange.gd` read seams only). | **done 2026-10-12** — gate 1351 → **1358/0 ×2**, verify clean vs `s44_start`; T-190 closed; 2 LOW → T-196/T-197 |
| 49 | S45 | Refinery: LOAD ALL, the machine strip, the CRAFT tab + the craft model | STATION_HUB §23.5 **P50/P51** (the four-plate 360×56 cluster — T-181's words and band stand — `LOAD ALL` cap 60 with overflow staying; the machine strip `SLOTS n/5` + per-slot `AVAILABLE`/`RUNNING mm:ss`/`DONE` chips + `+ n QUEUED`, never colour alone), §23.6 **P52** (the `REFINE`/`CRAFT` mode pair + the AUCTION-idiom CRAFT list), `04_refinery.md` §9 **R9–R12**, `07_crafting.md` §6 **C1–C10** (the four recipes at their derived fees 2 500/3 000/2 800/4 000 and materials 1 078/1 876/830/3 740, scrap-back 50 %, C10's confirm door). The refinery-slot and craft doors ride A2. T-175's REFINERY headers ride. Files: `ui/station/refinery_panel.gd`/`.tscn` + the refinery/craft model seams + `tests/` rows. May split into two **sequential** waves at brief time (panel controls vs the craft model) — one shared file, never parallel. | **done 2026-10-12** — gate 1358 → **1379/0 ×2**, verify clean vs `s45_start`; the runner frame-yield is the ceiling cure (the project.godot bump reverted per R0's HIGH); 1 LOW → T-198 |
| 50 | S46 | The shipyard build view | STATION_HUB §23.8 **P54** + `10_ship_acquisition.md` §3.5: the AUCTION house style, HULLS/MODULES category shelves, the materials bill as material runs `<held>/<needed>` (never CR), labour the only CR figure, `BUILD` through the A2 confirm door, `BUILD_HULL_FORMAT`'s CR figures retire — 10 §3.1–3.3's economics untouched. The hull-buy and shipyard-queue doors ride A2; T-175's SHIPYARD surfaces ride. Files: `ui/station/shipyard_panel.gd`/`.tscn` (+ `game/shipyard.gd` read seams only). | **done 2026-10-13** — gate 1379 → **1387/0 ×2**, verify clean vs `s46_start`; `game/shipyard.gd` byte-untouched; 1 LOW → T-200; the staged-MODULES question re-presented on TICKS |
| 51 | S47 | The launch sequence + its audio | STATION_HUB §23.3 **P48** (the 3.0 s in-scene departure overlay: S27 clamp t+0 / S28 spool t+1 / the fired pair re-pointed t+2.4 / route t+3, non-cancellable; P29's two-press law stands; `launch_panel.gd:48,859`'s route exit unchanged) + `AUDIO_SPEC.md` §8.7 **AUDIO-4/5** (S27 `sfx_station_undock` ≤ 1.0 s, S28 `sfx_station_spool_loop` 2.0 s; §11's fired pair re-points to the t+2.4 tail). **T-174**'s LAUNCH briefing column (one flat Tokens box) rides. Audio follows §3's S-table row law and the CC0-only sourcing law (`staging/audio/build_audio.py` → `set_loop_flags.py` → a `filesystem_manage` reimport). Files: `ui/station/launch_panel.gd`/`.tscn`, the loading route (`ui/screens/loading.gd`/`.tscn`), the `staging/audio/` driver, the cue assets + wiring. | queued — brief pending |
| 52 | S48 | The C-key Cargo overlay, both planes | UI_SPEC §18 **A7–A9** + STATION_HUB §23.2: `cargo_toggle` (C) pops one read-only overlay in both planes — the N28 sheet surface 420/720 (`DialogRoot` → dimmer → `panel_raised` stack), the owner's five groups AMMUNITION/ORE/INGOTS/COMPONENTS/FUEL CELLS, read-only seams `cargo_items`/`cargo_qty`/`ammo_of` only, no transactional control. Station: over the pane; flight: the layer-20 overlay `CanvasLayer` over the HUD (P19's topmost step before the map-deck step), `CargoBlock` (S39/T-170) stays the always-on summary. Files: the overlay scene/script, `ui/screens/station.gd` (the key seam), `game.gd` (flight's topmost-first poll, `:1040-1056`) + `tests/` rows. | queued — brief pending |
| 53 | S49 | The A2 doors on untouched surfaces + the wording law | UI_SPEC §17 **A4–A6** completed: module buy (`ui/station/auction_panel.gd`), insurance and vault rent (`insurance_panel.gd`, `vaults_panel.gd`) through `DialogManager.confirm` ("Are you sure you want to buy X for Y credits" + OK/CANCEL), plus the §17 wording-law test rows and the worked-example rows T-186 asks for. QUEUE/REPAIR/PAY BOUNTY/CANCEL-CONTRACT stay outside the door list (A1's reported boundary — widen by owner ruling only). Files: `auction_panel.gd`, `insurance_panel.gd`, `vaults_panel.gd` + `tests/` rows. | queued — brief pending |

## Parked (owner-gated — not queued; say the word and the five-piece lands)

- **T-179 — the Pyre ring's own-kill cascade** (owner postponed 2026-10-12:
  "didn't test, postpone"); code stays as shipped; re-presents at the P4 exit
  playtest. Ratify the cascade or gate the ring on the killing blow's source.
- **B2-1/B2-2 — the build-2 owner direction picks** (`19_testing_notes.md`):
  the menu hover look (flicker / steady) and the blurry station backgrounds.
  B2-2 could ride a P4 station wave once the owner picks the direction.

## Done

Items 1–45 closed (gate 437 → 1330/0 through the waves). Detail:
`_archive/dispatch_coder_done_2026-10-07.md`,
`_archive/dispatch_done_2026-10-08.md`, `_archive/dispatch_done_2026-10-12.md`
and `MASTER_REPORT.md` §6.

## Handoff (live)

**P4 — the station overhaul is the whole queue** (`phases/P4-station-overhaul/PHASE.md`);
items 46–53 are its implementation split (the file collisions that force the
order are in `WAVEBOARD.md` §Queued), and **no brief exists yet** — each wave
goes through the brief loop (docs-first five-piece in `slices/<SliceID>-<slug>/`)
before it dispatches. The owner's tick sheet is STATION_HUB **§23.10** (15 rows,
every value PROPOSED with its reversal; unticked rows implement at PROPOSED) and
its four flagged decisions (Rail Refit's 45.4 %, the two exotic lists, 07 §3's
stale supply math, A2's door boundary) are the owner's alone. Riders by wave:
**T-184** + **T-189** + the P47 wording (T-187) in item 46; **T-175**'s
surfaces ride items 48/49/50; **T-190** rides item 48; **T-174** + **T-188**
ride item 51; **T-186** rides items 49/53; **T-180** (the tooltip vs a pane's
header, one line in `ui/components/tooltip.gd`) is a free rider on any wave that
touches the tooltip; **T-177** is closed. Lessons the last waves taught: a
brief's `VAJB_WORKER_FILES` set must cover every file an acceptance item's own
text reaches (S27-B1 and S41's F8/F15 both stopped on this — the stop is
correct, but the fix is to scope the set, and a completion builder is the cheap
repair); a `tests/` pin a wave's own rows obsolete is the developer's bucket-2
re-cut, not a builder's (item 46's `test_s40_legibility.gd` rows are already
known); a brief that contradicts a pinned doc is the **developer's** error, not
the worker's (always re-read the pin the finding touches); the four S19 sealed
files (`damage.gd`, `npc_ship.gd`, `npc_brain.gd`, `weapons.gd`) re-pin to the
finished tree by the S22 procedure when a wave edits one; a parallel wave's
per-worker gate line is not the wave's gate — run the settled tree before
believing a failure count; and a green gate is not evidence a suite row still
tests what it says (T-183's lesson — `staging/gate.py` owns the `SCRIPT ERROR`
guard now).

Order and the collisions that force it are in `WAVEBOARD.md` §Queued. The
parked list stands owner-gated.
