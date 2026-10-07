# D22-P1 — screen integrity review (2026-10-05)

Reviewer: **D22-P1** (`hyper/deepseek-v4.1-flash` @ xhigh). Review-only: no production
code, docs or tickets touched. Evidence: `vajb-orbit/tests/probe_d22_integrity*.gd`
(+ `.tscn`), left in the tree; each mounts its scene into a 1920x1080 themed host,
pumps 30 frames and measures. `PlayerProfile` is sandboxed to
`user://_d22_scratch/profile.cfg` (the gate idiom) so the owner's live account is never
read or written.

Commands (all bounded, none left running):

```
$GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/probe_d22_integrity.tscn --quit-after 1200
$GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/probe_d22_integrity_station.tscn --quit-after 1200
$GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/probe_d22_integrity_screens.tscn --quit-after 1200
```

Method per screen: mount clean (no script error on instantiate + a 30-frame pump); every
`unique_name_in_owner` child resolves through `%` (the root's own mark excepted); containment
is measured **clipping-aware** (a control's box intersected with every clipping ancestor, so
scroll overflow is not an escape); zero/NaN rects on visible controls; unstyled `Button`
`normal` styleboxes; same-parent `MOUSE_FILTER_STOP` sibling overlap >= 50 % of the smaller;
visible text collected per pane for the word spot-checks.

## Screen-by-screen

| screen | mount | containment | words / theme | defects |
|---|---|---|---|---|
| boot | OK (vis 4) | 0 | silent (by spec) | — |
| loading | OK (6) | 0 | `ENTERING SPACE` | — |
| main menu | OK (36) | 0 (Backdrop full-bleed) | `PLAY` / `OPTIONS` / `EXIT` / `VAJB ORBIT v0.3` | — |
| settings | OK (26) | 0 | GRAPHICS read-outs; tabs GRAPHICS/AUDIO/CONTROLS/INTERFACE | — |
| station shell (header/drawer/footer) | OK (150) | 0 | `TERMINAL`, station plate, `DOCKED · ALL SYSTEMS NOMINAL`, P29 hint line; drawer 7 entries + `LOG OUT` | — |
| OVERVIEW | OK (118) | 0 | 6 tiles + captions, flavour line, P29 hint, identity, services rows | F04 |
| ARMORY (FIT CELLS / BATTERY CONFIG) | OK (196) | 0 | both modes, tags, hints, CELL INFO, EQ tabs | F01 |
| REFINERY | OK (65) | 0 | `QUEUE 1` / `QUEUE ALL` / `CANCEL` / `LOAD` / `COLLECT ALL` / `SLOTS 2/5` / `UPGRADE (3,000 CR)` | — |
| EXCHANGE | OK (578) | 0 | `SELL` / `SELL ALL RAW` / `CANCEL` / `SELL UNITS` + `MAX`/`0` | F02, F04 |
| AUCTION | OK (497) | 0 | `NEXT RESTOCK 20:00`, LIST/BUY, filter tabs | — |
| SHIPYARD | OK (130) | 0 | `REPAIR` / `IN SERVICE`, `INSTALLED MODULES`, `NOMINAL` | F04 |
| LAUNCH | OK (64) | 0 | `REFUEL` / `RECHARGE` / `LAUNCH`, P29 hint | — |
| SERVICES | OK (6) | 0 | placeholder (PROPOSED) | F03 |
| map deck | OK (58) | 0 | `MAP FILTERS`, `ZOOM 100%`, hint | — |
| flight HUD | OK (86) | 0 (reticle F06) | readouts, B1–B5 lamps | F04, F06 |
| tooltip | OK | 0 | `INSPECT` hint, N47 15 px body | — |
| inspect sheet | OK | 0 | 6 rows, `ESC · CLOSE` | — |
| dialogs (dialog / quit_confirm) | OK (11/11) | 0 | `CONFIRM`/`CANCEL`; `Quit Vajb Orbit?` | — |
| components (menu_button / slot_button / rebind row) | OK | 0 (Glow F05) | — | F04, F05 |

Every screen: 0 script errors, 0 unresolved `%` refs, 0 NaN rects, 0 unstyled buttons,
0 interactive-sibling overlaps. Popups: the tooltip and the sheet open then close clean
(`is_open` false, `pending_count` 0); the station's ESC unwind is sheet → drawer in P19
order; the drawer opens and closes with no stuck overlay; the map deck toggles clean.

## Findings

- **D22-P1/F01 — MED** — ARMORY **FIT CELLS renders the BATTERY CONFIG descriptor as its
  subtitle**. `armory_panel.gd:1214` sets `_subtitle.text = SUBTITLE` (`"BATTERY RACKS AND
  AMMUNITION - %d RACKS - %d PACKS"`, `:98`) unconditionally in `_apply_style`, and the
  `%PaneSubtitle` label (`armory_panel.tscn:43`) is never hidden, so with the pane in FIT
  CELLS (`_mode = MODE_FIT`, `:929`) the header reads the battery wording. Measured: the
  settled ARMORY text dump carries `BATTERY RACKS AND AMMUNITION - 5 RACKS - 8 PACKS`
  beside the FIT CELLS hint. Fixer: give FIT CELLS its own subtitle, or hide the label in
  that mode.
- **D22-P1/F02 — LOW** — EXCHANGE footer hint drift. Shipped `THE STATION BUYS · IT DOES
  NOT SELL` (`exchange_panel.tscn:190`) vs `STATION_HUB.md:823,1782`'s pinned `IT NEVER
  SELLS IN V1`. The shipped wording is S28-B1's A6 dev-speak cure
  (`slices/S28-station-chrome/S28-B1_report.md:44`) that the doc never recorded → doc drift,
  not a screen fault.
- **D22-P1/F03 — LOW** — the SERVICES deck renders the `MODULE OFFLINE` placeholder
  (`station.gd:829-838`) instead of a CONTRACTS/INSURANCE/VAULTS strip. SERVICES is
  **PROPOSED** (`STATION_HUB.md:1782` §19.4, §15.1) and outside the six graded panes;
  OVERVIEW's services rows carry the readouts, and the deck is not reachable from the
  drawer. Owner call, not a defect.
- **D22-P1/F04 — LOW** — seven empty layout containers report zero-size visible rects:
  OVERVIEW `PaneActions` 0x56 (`overview_panel.tscn`), HUD `PromptBlock` 1896x0
  (`hud.tscn:452`), HUD `CreditsSpacer` 0x192, EXCHANGE `BoardRows/Slack` 804x0, SHIPYARD
  `StatsSpacer` 452x0 and `ShipList/Slack` 338x0, `settings_rebind_row` `Spacer` 0x32. Each
  is an empty spacer / reserved action cell that renders nothing; polish only.
- **D22-P1/F05 — LOW** — `menu_button`'s Glow underlay extends 6 px past its plate
  (`ui/components/menu_button.tscn`, measured -6,-6,362x82). The halo is the pinned look
  (`glow_underlay.gd`); informational.
- **D22-P1/F06 — INFO** — the HUD `TargetReticle` measures -24,-24,48x48 in the probe
  because `target_reticle.gd:76` reads `viewport.get_mouse_position()`, which is (0,0)
  headless; in play it follows the cursor. Not a defect.

## In-flight (S35) footnote

Wave S35 was editing `armory_panel.*` and `exchange_panel.*` throughout this pass (four
writes were observed between 20:19 and 20:32). The ARMORY and EXCHANGE rows above are the
**settled** re-measurement, taken only after the pair held byte-stable for two minutes and
verified stable across the probe run: armory `.gd` md5 `209385ac…` / `.tscn` `2a3a3658…`,
exchange `.gd` `126e87e1…` / `.tscn` `0884bfa1…`. The S35 exchange amendment landed (N49
2026-10-05: one `SELL UNITS` selector + `MAX`/`0` quick-set; the S33 duplicate selector is
gone). F01 is measured against the settled armory; if S35 writes again, the ARMORY row and
F01 must be re-measured.

## Verdict

**PASS** — no screen fails to mount, no control escapes the window (clipping-aware), no
content is hidden or empty, no NaN or unstyled control, and every popup, tooltip and drawer
opens and closes clean. One MED (F01) and five LOW/INFO items; none block.

Fixer list: **F01** (armory FIT CELLS subtitle), **F02** (sync the exchange hint doc),
**F03** (SERVICES PROPOSED — owner call), **F04**/**F05** (polish), **F06** (no action).
