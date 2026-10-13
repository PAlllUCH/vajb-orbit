---
slice: S47
reviewer: S47-R0
role: reviewer
status: ready
tier: paid
---

# S47-R0 — review the launch sequence + its audio

**Dispatches only after S47-V0 lands.**

## Context (read in this order)
1. `.agents/gen/slices/S47-launch-sequence/S47-V0_BRIEF.md` — grade its seven
   acceptance items first (pass | drift | unanswered, with a cite).
2. `docs/design/STATION_HUB.md` §23.3 (P48) + §2 (the two-press law);
   `docs/design/AUDIO_SPEC.md` §8.7 (AUDIO-4/5), §4.1/§4.3/§4.5;
   `docs/design/UI_SPEC.md` §3.10 (A5.5), §12.2 (the stack law).
3. `.agents/gen/slices/S47-launch-sequence/S47-V0_report.md`.
4. The deliverables: `launch_panel.gd/.tscn`, `station.gd`,
   `tests/test_s47_launch_sequence.gd`.
5. The audio assets: `vajb-orbit/assets/audio/sfx/sfx_station_undock_01.ogg`
   and `sfx_station_spool_loop.ogg` (+ their `.import` loop flags) and the
   provenance rows in `vajb-orbit/assets/audio/generation_log_audio.md`.

## Task
Review: acceptance items, then the diff against the pins. Check specifically:
- The two-press law untouched; the sequence non-cancellable; ESC inert inside
  it; the 3 s disarm Timer intact.
- The beats' timing: 0.0 / 1.0 / 2.4 / 3.0; the route seam unchanged
  (`&"loading"` + the destination param); the ambience stop at the route.
- The bed is cue-scoped-stopped at the route (no leak); the fired pair plays
  exactly once, at t+2.4 (the old route-instant pair is gone).
- The overlay: Tokens-only, above panes / below drawer+sheet+dialog, fade
  ≤ 0.2 s, never reflows the pane, dies with the screen.
- T-174's box: flat Tokens box behind the briefing column, containers only.
- The audio assets' loop flags + the provenance log rows exist; the cue ids
  are the pinned names.
- No coordinates, no new hex; the gate count re-run matches
  (`python3 staging/gate.py --times 1`).
- `git diff --name-only` names only the brief's four files (the assets and
  their `.import`/log are the orchestrator's); anything else is HIGH
  regardless of quality.

## Output contract
- `.agents/gen/slices/S47-launch-sequence/S47-R0_review.md` (≤150 lines, from
  `_templates/REVIEW.md`).
- Do not fix anything. Review only.

## Paste block
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="" crush run "You are reviewer S47-R0. Read .agents/gen/slices/S47-launch-sequence/S47-R0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```
