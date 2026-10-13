---
slice: S47
worker: S47-V0
role: coder
status: ready
tier: paid
---

# S47-V0 — the launch sequence (P48) + its audio (AUDIO-4/5) + T-174's briefing box

**Status moves `draft → ready` when the orchestrator has landed the two cue
assets and re-verified the anchors** (the assets' provenance and loop flags are
the orchestrator's own prep, recorded here at dispatch).

## Context (read in this order, by range)
1. `docs/design/STATION_HUB.md` §23.3 (lines ~2133–2137, verbatim below) and
   §2 (the two-press law — P29's preamble re-states it), §12.2/§12.4 (the
   stacking law and the route seam).
2. `docs/design/AUDIO_SPEC.md` §8.7 (lines ~488–507, verbatim below), §4.1
   (the anti-flam + pool caps), §4.3 (buses), §4.5 (the held-bed law), §3's
   S-table row shape (S27/S28 live in §8.7's table).
3. `vajb-orbit/ui/station/launch_panel.gd` (946 lines — read whole): `_fire`
   (`:889-896`), `_on_launch_pressed` (`:869`), the arm timer, the briefing
   column (T-174's ten labels — grep `FLIGHT BRIEFING`), `destination_route`.
4. `vajb-orbit/ui/screens/station.gd` — `_on_launch_requested` (`:1678-1684`,
   the fired pair + the ambience stop + the route — the seam you re-point),
   `SFX_LAUNCH_BOOST`/`SFX_LAUNCH_JUMP` (`:58-59`), the confirm/drawer overlay
   layers (`:215-222`).
5. `vajb-orbit/autoload/audio_manager.gd` — `play_sfx` (`:310`),
   `play_loop`/`stop_loop`/`stop_bed` (`:460-534`), the bed lease law
   (`:186-215`), `play_ambience`/`stop_ambience` (`:338-358`).
6. `vajb-orbit/ui/screens/loading.gd`/`.tscn` — the route you hand to (read
   only; the route id `&"loading"` is unchanged).

## Spec extract (the pinned law, verbatim)

**STATION_HUB §23.3 P48** — "the LAUNCH control's **two-press law stands
untouched** (§2: press 1 arms — colour, pulse, `ARMED · PRESS LAUNCH AGAIN
WITHIN 3 s TO UNDOCK`, the 3 s disarm `Timer`, breaker cue §11; press 2
fires). On press 2 a **departure sequence** plays **in-scene before the
loading route**, as a full-rect presentation overlay (Tokens only; it never
reflows the pane — A5.5): **t+0.0 s** the dock-clamp cue **S27**
`sfx_station_undock` (AUDIO_SPEC §8.7) + strip `UNDOCKING · <station name>`;
**t+1.0 s** the spool bed **S28** `sfx_station_spool_loop` (§8.7) fades in
under; **t+2.4 s** the existing fired pair `sfx_ship_boost_01` +
`sfx_ship_jump_01` re-points from the route instant to the sequence's tail
(§11's LAUNCH-fired row); **t+3.0 s** route `&"loading"`
(`launch_panel.gd:48,859` unchanged — the sequence's exit, not a new route).
**Total 3.0 s, PROPOSED.** The sequence is **not cancellable** (the second
press is the commit — §2's own reading; P19's ESC steps live before it). The
overlay's own fade envelope obeys N29 (≤ 0.2 s)."

**AUDIO_SPEC §8.7 AUDIO-4** — "S27 — Undock (dock clamp release): cue
`sfx_station_undock`, primary take `sfx_station_undock_01.ogg`, **[P]**
mechanical clunk + sub-thump layered from the owned Kenney Sci-Fi / Impact
takes (§3's S4 layer recipe at 1:1), **≤ 1.0 s**, `SFX` bus (SFXWorld send,
§4.3), **world pool cap 2** — §4.1's cap list gains `world 2` …, anti-flam
§4.1 as shipped; **seam: the launch sequence's t+0.0 s**."

**AUDIO-5** — "S28 — Undock spool bed: cue `sfx_station_spool_loop`, take
`sfx_station_spool_loop.ogg`, **[P]** from the owned Kenney engine beds (§3's
S16 candidates), **2.0 s**, `SFX` bus (SFXWorld), held-bed law §4.5 (lease,
cue-scoped stop) — starts at the sequence's **t+1.0 s**, **stops at the route**
(t+3.0 s)."

**§8.7's re-point note** — "the fired pair `sfx_ship_boost_01` +
`sfx_ship_jump_01` (§11's "LAUNCH fired" row) moves from the route instant to
the sequence's t+2.4 s tail."

**T-174 (rider, owner-approved cure)** — the LAUNCH briefing column
(`FLIGHT BRIEFING` and its ten labels, §5.4) sits inside **one flat Tokens
box** (`bay_bg` + 1 px `metal_mid`), containers and relative sizing only.

## Measured facts (cite, do not re-derive)
- Today's press 2: `_fire()` emits `launch_requested` (`launch_panel.gd:889-896`);
  the shell's `_on_launch_requested` plays the fired pair, stops the ambience,
  routes (`station.gd:1678-1684`). The re-point: the pair moves into the
  sequence's t+2.4; the route instant fires nothing itself (the ambience stop
  and the route stay at t+3.0).
- The station name for the strip: the shell's own identity read
  (`station.gd`'s `_apply_identity` region — the one source of truth the
  OVERVIEW's `set_identity` shares). Pass it into the sequence; never re-derive.
- The bed seam: `AudioManager.play_loop`/`stop_loop`/`stop_bed` are the §4.5
  held-bed law's API (`audio_manager.gd:460-534`); the spool bed is
  cue-scoped (lease, cue-scoped stop) — start at t+1.0 with the API's fade,
  stop at t+3.0 (the route instant, before the loading scene mounts).
- The two cue files land on this boundary (the orchestrator's prep, provenance
  in `vajb-orbit/assets/audio/generation_log_audio.md`): `sfx_station_undock_01.ogg`
  (≤ 1.0 s one-shot) and `sfx_station_spool_loop.ogg` (2.0 s, loop import
  flags set). Verify with `ls vajb-orbit/assets/audio/sfx/` at your start.
- The overlay's seat: a full-rect presentation overlay inside the station
  screen above the panes, below the drawer/sheet/dialog overlays (§12.2's
  stack law — the shell's own layering at `station.gd:215-222`); Tokens-only
  chrome; it never reflows the pane (A5.5). It dies at the route (the screen
  unmounts anyway) and is not cancellable (ESC does nothing once armed into
  the sequence — P19's ESC steps live only before press 2).
- N29: the overlay's own fade ≤ 0.2 s (enter/exit).
- T-188 (the S-cue/wave-id collision) is a docs follow-up — do not renumber
  anything in code; the cue ids are the pinned `sfx_station_undock` /
  `sfx_station_spool_loop`.
- Gate baseline **1387/0** (2026-10-13, post-S46; the dispatch line repeats it).
- **Orchestrator prep record (2026-10-13):** the two cue assets landed and imported —
  `sfx/sfx_station_undock_01.ogg` (0.571 s, one-shot) and `sfx/sfx_station_spool_loop.ogg`
  (2.0 s, loop import flag `true`, seam 0.1 dB), both CC0 Kenney derivations by
  `staging/audio/premix_s47.py` → `build_audio.py --only` (provenance in
  `assets/audio/generation_log_audio.md`'s 2026-10-13 amendment;
  `docs/design/ASSET_CATALOG.md` regenerated). Loading is via the shipped
  `AudioManager` streams — no import work is yours.

## Task
Build the 3.0 s departure sequence (the overlay, the four beats, the
non-cancellable law, the route exit unchanged), re-point the fired pair,
wire the two new cues through the shipped audio APIs, and cure T-174's
briefing box. Add the suite `tests/test_s47_launch_sequence.gd`.

## Acceptance list
1. Press 1's arm law is untouched (colour, pulse, ARMED strip text, the 3 s
   disarm Timer, the breaker cue); ESC during the armed window disarms (P19's
   steps live before press 2).
2. Press 2 opens the departure overlay: full-rect, Tokens-only chrome, above
   the panes and below the drawer/sheet/dialog overlays, fade ≤ 0.2 s, the
   pane's layout never reflows; the sequence is not cancellable (no ESC step,
   no click-through).
3. The beats: t+0.0 `sfx_station_undock` + the strip `UNDOCKING · <station
   name>`; t+1.0 `sfx_station_spool_loop` fades in (the held-bed API,
   cue-scoped); t+2.4 the fired pair `sfx_ship_boost_01` + `sfx_ship_jump_01`;
   t+3.0 route `&"loading"` with `{destination: &"game"}` — the pre-existing
   route seam unchanged, the ambience stop riding the route instant as today.
4. The spool bed is stopped at the route (cue-scoped stop — no bed leak into
   the loading scene); a bed the route preempts is stopped by its own lease
   fallback (§4.5).
5. The fired pair no longer plays at the route instant (`_on_launch_requested`
   no longer plays it; the sequence owns it at t+2.4).
6. T-174: the briefing column sits inside one flat Tokens box (`bay_bg` +
   1 px `metal_mid`), containers and relative sizing only, the ten labels
   unchanged.
7. New suite `tests/test_s47_launch_sequence.gd` pins items 1–6 (the beats may
   be proven with a manual `AudioStreamPlayer`-free time read: the strip text
   at the beats, the route at t+3.0, the pair's play calls recorded through a
   probe seam); the report answers every item with a cite.

## Hard constraints
- File set: `vajb-orbit/ui/station/launch_panel.gd`,
  `vajb-orbit/ui/station/launch_panel.tscn`, `vajb-orbit/ui/screens/station.gd`,
  `vajb-orbit/tests/test_s47_launch_sequence.gd`. Do not touch
  `autoload/audio_manager.gd` (its §4.5 API is pinned — if the cue-scoped bed
  cannot stop in time, report it and stop), `ui/screens/loading.gd`, the audio
  assets (the orchestrator owns them), docs, the theme.
- No new hex; no new tokens; A5.1–A5.5 composition (the overlay is containers
  + anchors; no `_draw` over content).
- Shell edits forbidden; every Godot run bounded (`--quit-after`); probes
  self-quit; never leave a command in the background. The sequence's own
  timers die with the screen — no global timer.
- Gate: `python3 staging/gate.py --times 1` for your own check; record
  before/after `[SUMMARY]`.

## Output contract
- Report: `.agents/gen/slices/S47-launch-sequence/S47-V0_report.md` (≤120
  lines, from `_templates/REPORT.md`).
- Deliverable: the four files above.

## Paste block
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="vajb-orbit/ui/station/launch_panel.gd,vajb-orbit/ui/station/launch_panel.tscn,vajb-orbit/ui/screens/station.gd,vajb-orbit/tests/test_s47_launch_sequence.gd" crush run "You are worker S47-V0. Read .agents/gen/slices/S47-launch-sequence/S47-V0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```
