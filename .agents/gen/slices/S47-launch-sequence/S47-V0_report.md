---
slice: S47
worker: S47-V0
model: hyper/glm-5.3-flash
status: informational
gate: "1387/0 → 1395/0"
---

# S47-V0 report

## Result
The 3.0 s departure sequence (P48) ships in the station shell: press 2 opens a
full-rect Tokens-only overlay above the panes, plays the four beats (t+0.0 undock
cue + `UNDOCKING · <station name>` strip, t+1.0 spool bed, t+2.4 fired pair, t+3.0
cue-scoped bed stop + ambience stop + `route_requested(&"loading", {destination:
&"game"})`), and is not cancellable. T-174's briefing column sits in one flat
Tokens box. Gate 1387/0 → 1395/0 (`python3 staging/gate.py --times 1`, new suite
`test_s47_launch_sequence` = 8 rows).

## Acceptance list answers
1. Arm law untouched — `launch_panel.gd:867-912` unchanged in behaviour (`_arm`/`_fire`/
   `_clear_arm`, `ARM_SECONDS` 3.0, breaker cue `SFX_ARM`); pinned by the suite's
   `test_press_one_arms_and_esc_still_disarms` (armed ink, ARMED strip, running 3 s
   Timer, ESC disarms with `STATUS_DISARMED`).
2. Press 2 opens the overlay — `station.gd:_build_departure` (`:525-565`): full-rect
   Control (the LeaveConfirm seat: above the panes by draw order, below the
   drawer/sheet/dialog CanvasLayers 19/20, §12.2), chrome = `void_base` dim at
   `MODAL_DIM_ALPHA` + theme-panel strip; fade `SEQUENCE_FADE` 0.18 ≤ N29's 0.2;
   `MOUSE_FILTER_STOP` (no click-through); not a descendant of `ModuleHost` (A5.5 — the
   pane tree is untouched); ESC swallowed while running (`_handle_cancel` guard
   `:1841-1844`); not cancellable end-to-end (pinned by `test_the_sequence_is_not_cancellable`).
3. The beats — `station.gd:1791-1848`: t+0.0 `SEQUENCE_UNDOCK` + strip
   `UNDOCKING · %s` fed `_station_name.text` (the shell's own identity read, never
   re-derived); t+1.0 `play_loop(SEQUENCE_SPOOL)` at the API's `LOOP_FADE`; t+2.4
   `SFX_LAUNCH_BOOST`+`SFX_LAUNCH_JUMP`; t+3.0 route `&"loading"` +
   `{destination: &"game"}` via the unchanged `route_requested` seam. Pinned by
   `test_the_beats_play_the_pinned_cues_and_end_at_the_route` (beats walked through
   their own handlers; the schedule pinned by the timers' wait times 1.0/2.4/3.0,
   `test_the_beat_timers_are_the_screen_s_own`).
4. No bed leak — `stop_bed(SEQUENCE_SPOOL, 0.0)` (cue-scoped, immediate, before the
   route emission) at `station.gd:1826`; proven gone from `sounding_loops()`/`bed_voice()`
   after the route beat. The lease fallback stands as shipped: a screen that unmounts
   mid-sequence stops being re-asked, so `AudioManager`'s own 1.2 s lease
   (`audio_manager.gd:856-864`) puts the bed out.
5. Re-point — `_on_launch_requested` (`:1771-1779`) no longer plays the pair; the
   sequence owns it at t+2.4 (`_on_departure_pair`). Pinned by
   `test_the_fired_pair_no_longer_plays_at_the_route_instant` (commit instant plays the
   undock cue alone; the route instant appends nothing and the last handed cue stays
   the pair's jump).
6. T-174 — `launch_panel.tscn` wraps the column in `BriefRoof` (PanelContainer,
   min 560 kept) → `BriefInset` (MarginContainer 12/10/12/10, the T-172 inset) →
   `BriefBox`; the flat box is applied in code from the live theme
   (`launch_panel.gd:_roof_briefing_column`): `bay_bg` fill + 1 px `metal_mid`.
   Containers only; all ten labels unchanged (pinned by the two `test_t174_*` rows).
7. New suite `tests/test_s47_launch_sequence.gd` — 8 rows, all passing; beats proven
   via the beat handlers + the timer schedule + the shell's one-shot cue record
   (`_departure_cues`, `station.gd:1832-1838`) and the manager's own probe surface
   (`last_sfx`/`sounding_loops`/`bed_voice`/`cue_path`); no real-time wait anywhere.

## Deviations from SLICE.md
- **The spool bed is re-asked every frame while held** (`station.gd:_process`):
  t+1.0→t+3.0 outlasts the 1.2 s lease, so without a re-ask the bed would die at
  ~t+2.2 mid-sequence. This is the held-bed law's own model (§4.5: "a bed that is
  re-asked every frame it is held never expires"). Reversal: drop the re-ask and the
  bed sounds only ~1.2 s of its pinned 2.0 s window.
- **The route stop fades 0.0 s** (`stop_bed(..., 0.0)`): the acceptance reads "no bed
  leak into the loading scene", and the loading scene mounts the same frame the stop
  is issued; the API's default `LOOP_FADE` (0.15 s) would tail audibly into it.
  Reversal: `stop_bed(cue)` default (a 0.15 s tail into loading).
- **The overlay's seat is the shell's plain-Control precedent** (LeaveConfirm), not a
  new CanvasLayer constant: same stack relations, one fewer invented number.
  Reversal: a dedicated `DEPARTURE_LAYER` CanvasLayer between panes and 19.
- **Focus is released at sequence begin** (`gui_release_focus`): a focused LAUNCH
  button would otherwise re-arm on a second ui_accept mid-sequence (breaker cue +
  ARMED strip under the presentation). Reversal: leave focus live.
- **T-174's box fill reads `armory_bay_bg`**: the theme carries `bay_bg` under its
  `armory_` token prefix (`vajb_theme.tres:559`, `armory_style.gd:132`'s own mapping);
  T-172's shipped cure relied on the theme-default `void_panel` fill, but T-174's law
  pins `bay_bg`, so the box is applied in code. Reversal: the theme-default fill.
- **T-174's ten labels** are read as the briefing column's own: FLIGHT BRIEFING + the
  nine P2-A brief labels + the CARGO HOLD caption. T-174's historical finding list
  named DECK CONTROL (the right column's caption) in its place; the right column keeps
  §5.4's seat, its HullFrame already roofed by `PanelRaised`. Reversal: a second box
  over DECK CONTROL.
- Nothing outside the file set was touched: `audio_manager.gd` (the §4.5 API used
  as shipped), `loading.gd`, assets, docs, theme — all read-only here.

## Evidence
- Baseline gate: `[SUMMARY] passed=1387 failed=0` (`python3 staging/gate.py --times 1`,
  before any edit).
- Scoped suite: `[SUMMARY] passed=8 failed=0` (`$GODOT_CONSOLE --headless --path
  "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200 --
  --suite=test_s47_launch_sequence`), no SCRIPT ERROR lines.
- Full gate after: `[GATE] run 1: ok - [SUMMARY] passed=1395 failed=0`.
- Cue assets on the boundary (the orchestrator's prep, verified at start):
  `assets/audio/sfx/sfx_station_undock_01.ogg` (one-shot, no loop param) and
  `sfx_station_spool_loop.ogg` (`loop=true` in its `.import`); the suite also pins
  `AudioManager.cue_path(&"sfx_station_spool_loop")` == the pinned take path.
- The undock cue resolves through the manager's `_01` fallback
  (`audio_manager.gd:1015-1022`): cue `sfx_station_undock` → `sfx_station_undock_01.ogg`.

## Files touched
- `vajb-orbit/ui/screens/station.gd` — the departure sequence: overlay build, three
  beat timers, the four beats, the `_process` lease re-ask, the ESC stand-down, the
  fired pair re-point, the probe record.
- `vajb-orbit/ui/station/launch_panel.gd` — T-174's live-theme flat box; contract
  comments re-pointed at the sequence (P48).
- `vajb-orbit/ui/station/launch_panel.tscn` — the briefing column wrapped in
  `BriefRoof`/`BriefInset`; `BriefCaption` gains its unique name.
- `vajb-orbit/tests/test_s47_launch_sequence.gd` — the new suite (8 rows).

## Follow-ups
None owed. T-188 (the S-cue/wave-id collision) stays the docs side's follow-up per the
brief; no cue id was renumbered in code.

| Item | Kind | Where |
|---|---|---|
