---
slice: S47
reviewer: S47-R0
verdict: passed-with-followups
gate: "1395/0 → 1395/0"
---

# S47-R0 review

## Acceptance list
1 — pass — the diff touches only `_fire`'s comment plus the T-174 box; `ARM_SECONDS` 3.0
    (`launch_panel.gd:65`), `_arm`/`_clear_arm`, the breaker cue and `STATUS_ARMED` are
    as shipped; `test_press_one_arms_and_esc_still_disarms` pins armed ink, `ARM_TEXT % 3`,
    the running 3 s Timer and the ESC disarm (`STATUS_DISARMED`).
2 — pass — `_build_departure` (`station.gd:525-565`): full-rect Control child of the
    screen added after `_build_panels()` (above the panes), below the 19/20 CanvasLayers
    (`station.gd:228-235`), `MOUSE_FILTER_STOP`, fade `SEQUENCE_FADE` 0.18 ≤ N29's 0.2,
    not a descendant of `%ModuleHost`; not cancellable via the `_handle_cancel` guard
    (`station.gd:1997-2000`); pinned by suite rows 2 and 6.
3 — pass — t+0.0 `SEQUENCE_UNDOCK` + `UNDOCKING · <name>` from the shell's own
    `_station_name.text` (`station.gd:1791-1816`); t+1.0 `play_loop` at the API's fade
    (`:1819-1822`); t+2.4 the pair (`:1824-1827`); t+3.0 `stop_bed` + `stop_ambience` +
    `route_requested(&"loading", {destination: &"game"})` (`:1826-1829`, pre-image of
    `_on_launch_requested` confirms the seam verbatim). Timers 1.0/2.4/3.0 pinned by
    `test_the_beat_timers_are_the_screen_s_own`; the beats by the cue record + `last_sfx`.
4 — pass — `stop_bed(SEQUENCE_SPOOL, 0.0)` is cue-scoped and precedes the emit
    (`station.gd:1826`); `sounding_loops()`/`bed_voice()` read empty after the route
    beat (suite row 3's tail). The lease fallback stands as shipped
    (`audio_manager.gd:856-864`); the per-frame re-ask is §4.5's own model — `play_loop`
    refreshes `_loop_asked` without restarting (`audio_manager.gd:464-467`).
5 — pass — `_on_launch_requested` (`:1771-1779`) no longer plays the pair (the pre-image
    played boost + jump + ambience stop + route; now it guards and begins the sequence);
    `test_the_fired_pair_no_longer_plays_at_the_route_instant` pins the commit playing
    the undock cue alone and the route instant appending nothing.
6 — pass — `BriefRoof`(PanelContainer, min 560) → `BriefInset`(12/10/12/10) → `BriefBox`
    (`launch_panel.tscn:52-70`); the flat box applied in code from the live theme:
    `armory_bay_bg` fill + 1 px `metal_mid` (`launch_panel.gd:305-320`) — the theme
    carries `bay_bg` under its `armory_` prefix (`vajb_theme.tres:559`;
    `armory_style.gd`'s `TOKEN_PREFIX`), re-inked by `_apply_tokens` (`:220,:231`);
    the tscn diff is reparenting only, so the labels are unchanged; pinned by the two
    `test_t174_*` rows.
7 — pass — `test_s47_launch_sequence.gd` ships 8 rows covering items 1–6 (item 3 twice:
    beats + timer schedule), walks the beats through their own handlers with no
    real-time wait, and the full gate carries it: 1387 → 1395 (+8).

## The review brief's specific checks
- Two-press law untouched, sequence non-cancellable, ESC inert inside it, 3 s disarm
  Timer intact — all verified (items 1, 2 above).
- Beats 0.0/1.0/2.4/3.0 ✓; route seam unchanged (`&"loading"` + destination param,
  pre-image diff) ✓; ambience stop rides the route instant exactly as before ✓.
- Bed cue-scoped-stopped at the route, no leak ✓; the pair plays exactly once at t+2.4;
  the old route-instant pair is gone (pre-image `git show HEAD` checked) ✓.
- Overlay: Tokens-only (the shell's `void_base` modal dim at `MODAL_DIM_ALPHA` +
  `StationPanelTitle` strip on the shell's own plate precedent), above panes / below
  drawer+sheet+dialog, fade 0.18, no pane reflow (sibling of the pane tree), dies with
  the screen (timers and overlay are screen children, pinned) ✓.
- Loop flags: `sfx_station_undock_01.ogg.import` `loop=false`, `sfx_station_spool_loop.ogg.import`
  `loop=true` ✓; provenance rows exist (`generation_log_audio.md:83-84`, the 2026-10-13
  amendment `:157-167`) ✓; cue ids are the pinned `sfx_station_undock` /
  `sfx_station_spool_loop` (`station.gd:62-63`), the undock resolving through the
  manager's `_01` fallback (`audio_manager.gd:1013-1021`) ✓.
- No coordinates, no new hex: the diff greps clean of hex literals and `position`/`offset_*`.
- `git diff --name-only` = the brief's three modified files; the test ships untracked-new
  and the V0 report is the output contract's own artifact — nothing foreign.
- Gate re-run: `[SUMMARY] passed=1395 failed=0` — matches the 1395/0 baseline exactly.

## Findings
| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| F1 | MED | `audio_manager.gd:60-71` | AUDIO-4's `world 2` pool cap (and the anti-flam gate riding the same pool path) has no implementation home: `sfx_station_undock` plays through plain `play_sfx` — unclassed (`_pool_class_of` → `&""`, cap 0 → open, `audio_manager.gd:960-967`) and ungated — because the V0 brief locked `audio_manager.gd`, and the worker's deviations section does not report the gap. Exposure today is nil (the seam fires once per commit and a second intent is guarded), but the pinned cap clause is silently unmet. | orchestrator → ticket: add `world 2` to `POOL_CAPS`/`POOL_CLASS_BY_PREFIX` in its own slice, or the owner reverses the clause; no fixer inside S47's file set can cure it |
| F2 | LOW | `launch_panel.tscn:111-116` | T-174's historical finding list counted DECK CONTROL among its ten labels; the shipped cure roofs §5.4's briefing column (FLIGHT BRIEFING + nine rows + CARGO HOLD) and leaves DECK CONTROL on its bare §5.4 seat above `HullFrame`. The worker reported the reading with a reversal and §5.4 (STATION_HUB:358-373) supports it — the LOW_BACKLOG's T-174 row text is what now disagrees. | docs: a one-line note on the T-174 backlog row (the cure follows §5.4's column), ticketed, not fixed here |

## Deviations verified (bucket 1, reported by the worker, no finding)
- Spool bed re-asked every frame while held — the held-bed law's own model (§4.5:
  a re-asked bed never expires), and `play_loop`'s re-ask path only refreshes the lease.
- Route stop at fade 0.0 s — cue-scoped and immediate so no tail crosses into loading;
  the acceptance's "no bed leak" is what it implements.
- Overlay seat = the shell's LeaveConfirm precedent (plain full-rect Control,
  `station.tscn:237`), no new CanvasLayer constant — same stack relations.
- Focus released at sequence begin — no second `ui_accept` can re-arm under the overlay.
- `armory_bay_bg` token read — the pinned `bay_bg` value's registered name; verified in
  the theme and the palette prefix.
- Ten-labels reading — §5.4's column; see F2.

## Verified fixes
None owed — review only. F1 cannot be fixed inside S47's file set (the manager is
locked); it moves to a ticket with the orchestrator. F2 is a docs-side note.

**Developer fixer amendment (2026-10-13, the close-out pass):** both findings cured
by the orchestrator's developer hand — no new dispatch, the file sets were the
constraint the cure works around.
- **F1 (MED) cured** at its named site: `audio_manager.gd`'s `POOL_CAPS` gains
  `&"world": 2` and `POOL_CLASS_BY_PREFIX` gains the world prefixes
  (`sfx_station_`, `sfx_stinger_` — §4.1's amended "one-shots that are neither
  weapon, impact, mining nor UI"); a `CUE_POOLS` row for `sfx_station_undock`
  (one take, tier mode, no ranges) puts the cue on the gated route, and
  `station.gd`'s `_play_departure_cue` now calls `AudioManager.play_pool` (a
  pool-less cue falls back to the plain call there, so the fired pair plays as
  it did). The other world-class callers (S19/S20/S21–S24) keep their plain
  `play_sfx` calls — the pin's seam is the undock; re-routing them is a separate
  pass and is not owed by AUDIO-4. Pinned by a ninth suite row
  (`test_the_undock_cue_rides_the_world_pool_cap`: cap 2, the class mapping,
  the pair stays unclassed, the pool row and its take). Reversal: drop the
  `world` entries and the row; the cue reverts to the ungated plain call.
- **F2 (LOW) cured** as the review's own fix-owner cell names: the one-line
  label-reading note is on T-174's row in `LOW_BACKLOG.md` (closed in S47 there),
  so the backlog text and the shipped cure no longer disagree.

## Gate
- Baseline (dispatch line): `[SUMMARY] passed=1395 failed=0`.
- Re-run for this review: `python3 staging/gate.py --times 1` → `[GATE] run 1: ok -
  [SUMMARY] passed=1395 failed=0` — byte-identical count, no SCRIPT ERROR lines.
- Negative control: none beyond the gate — the review changed nothing.
